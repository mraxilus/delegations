## Replicate static check of `packages_node.nim` (CONTRIBUTOR.md, TypeScript and Node; #1045).

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, packages_node]
import ./fixtures


const
  PATH_SCRIPT = "contributor/ronri/pga_visualiser/tools/drive/main.ts"  ## Script of project.
  PATH_MANIFEST = "contributor/ronri/pga_visualiser/package.json"  ## Manifest of same project.
  PATH_PAGE = "contributor/ronri/pga_visualiser/pages/shell.html"  ## Page of same project.
  SPECIFIERS_PASSING = [
    "./report", "../shared/clock", "/scripts/app.js", "node:fs", "node:path", "@playwright/test",
    "@playwright/test/reporter", "typescript", "@types/node",
  ]
    ## Path, built-in and listed package, each form of each.
  SPECIFIERS_REFUSED = [
    "lodash", "lodash/fp", "@scope/name", "@scope/name/sub", "fs", "https://esm.sh/lodash",
    "//cdn.example/x.js",
  ]
    ## Package off list, bare built-in, address on other host, each form of each.
  FORMS_IMPORT = [
    "import x from 'S';", "import 'S';", "import type { T } from \"S\";", "export * from 'S';",
    "} from 'S';", "const m = await import('S');", "const m = require(\"S\");",
    "const m = await import(`S`);", "import {a, b} from 'S'",
  ]
    ## Each statement naming module, with `S` standing for its specifier.
  LINES_NOT_IMPORT = [
    "const letters = Array.from('lodash');", "const from = 'lodash';",
    "// import x from 'lodash';", " * import 'lodash';", "/* require('lodash') */",
    "imported('lodash');", "fromage('lodash');", "const source = 'import';",
    "report('a corner of empty sky stands to start from', false, 'every corner hovers');",
    "draw(); // import x from 'lodash';", "const said = \"it reads from 'lodash'\";",
  ]
    ## Lines that hold word of import beside quote, and name no module; fourth from last as found
    ##   at line 223 of `chrome.ts` of `pga_visualiser`, 2026-11-27, where `from` inside string
    ##   read next quote as specifier.
  MANIFEST_FOUND = """{
  "private": true,
  "devDependencies": {
    "@playwright/test": "1.63.0",
    "@types/node": "22.20.2",
    "typescript": "7.0.2"
  }
}
"""
    ## Manifest of each of three node projects, 2026-11-27, `name` and `scripts` left out.




suite "Static check":
  test "each form of import reads its specifier, and finding follows list alone":
    # Domain: each form of statement against each specifier passing and refused, exhaustive.
    var count = 0
    for form in FORMS_IMPORT:
      for specifier in SPECIFIERS_PASSING:
        check form.replace("S", specifier).specifiersScript.mapIt(it.specifier) == @[specifier]
        check checkScript(PATH_SCRIPT, form.replace("S", specifier)).len == 0
        inc count
      for specifier in SPECIFIERS_REFUSED:
        let found = checkScript(PATH_SCRIPT, "\n" & form.replace("S", specifier))
        check found.len == 1
        check found[0].path == PATH_SCRIPT and found[0].line == 2
        check found[0].message.endsWith("got `" & specifier & "`.")
        inc count
    check count == FORMS_IMPORT.len * (SPECIFIERS_PASSING.len + SPECIFIERS_REFUSED.len)

  test "line that holds word of import beside quote names no module":
    # Domain: member call, binding, comment, word that holds keyword, keyword as text.
    for line in LINES_NOT_IMPORT:
      check line.specifiersScript.len == 0
      check checkScript(PATH_SCRIPT, line).len == 0

  test "bare built-in reads as package, and help names its form with prefix":
    let found = checkScript(PATH_SCRIPT, "import { readFileSync } from 'fs';")
    check found.len == 1 and found[0].help == "Node built-in takes form `node:fs`."

  test "two imports on one line each read":
    let found = checkScript(PATH_SCRIPT, "import a from 'left'; import b from 'right';")
    check found.mapIt(it.message.endsWith("`left`.") or it.message.endsWith("`right`.")) ==
      @[true, true]

  test "package names its scope with its name, and drops its path":
    # Domain: bare, bare with path, scoped, scoped with path, scope alone.
    for (specifier, name) in [
      ("lodash", "lodash"), ("lodash/fp", "lodash"), ("@scope/name", "@scope/name"),
      ("@scope/name/sub/deep", "@scope/name"), ("@scope", "@scope"),
    ]:
      check specifier.namePackage == name

  test "manifest of each node project passes as found":
    # Case: three node projects hold these dev dependencies alone, 2026-11-27.
    check checkManifest(PATH_MANIFEST, MANIFEST_FOUND).len == 0

  test "each runtime field refuses each package at its line, and dev field refuses off list":
    # Domain: each runtime field, then dev field with listed and unlisted name, at each line.
    for field in ["dependencies", "optionalDependencies", "peerDependencies"]:
      let
        text = "{\n  \"" & field & "\": {\n    \"typescript\": \"7.0.2\"\n  }\n}\n"
        found = checkManifest(PATH_MANIFEST, text)
      check found.len == 1
      check found[0].line == 3 and found[0].message.endsWith("in `" & field & "`.")
    let found = checkManifest(
      PATH_MANIFEST,
      "{\n  \"devDependencies\": {\n    \"typescript\": \"7.0.2\",\n    \"lodash\": \"4.17.15\"\n" &
        "  }\n}\n",
    )
    check found.len == 1 and found[0].line == 4 and found[0].message.endsWith("got `lodash`.")

  test "manifest that JSON cannot read is finding, and manifest with no fields passes":
    check checkManifest(PATH_MANIFEST, "{ not json").len == 1
    check checkManifest(PATH_MANIFEST, "{}").len == 0
    check checkManifest(PATH_MANIFEST, "[]").len == 0

  test "script of page that names other host is finding, and script of project passes":
    # Domain: relative, rooted, scheme, scheme-relative, no `src`, two tags on one line.
    check checkPage(PATH_PAGE, "<script src=\"app.js\"></script>").len == 0
    check checkPage(PATH_PAGE, "<script type=\"module\" src='/x.js'></script>").len == 0
    check checkPage(PATH_PAGE, "<script>let x = 1;</script>").len == 0
    let found = checkPage(
      PATH_PAGE,
      "\n<script src=\"https://cdn.example/a.js\"></script><script src='//cdn.example/b.js'>",
    )
    check found.mapIt(it.line) == @[2, 2]
    check found[1].message.endsWith("got `//cdn.example/b.js`.")

  test "tree routes manifest, script, page and SVG to their parts, and nothing else":
    let tree = treeGood().with(
      entry(PATH_MANIFEST, "{\"dependencies\": {\"lodash\": \"4.17.15\"}}"),
      entry(PATH_SCRIPT, "import x from 'lodash';\n"),
      entry(PATH_PAGE, "<script src=\"https://cdn.example/a.js\"></script>\n"),
      entry("contributor/ronri/pga_benchmark/pages/map.svg", "<script src='//cdn/a.js'/>\n"),
      entry("contributor/ronri/pga_benchmark/README.md", "import x from 'lodash';\n"),
    )
    check tree.checkPackagesNode.mapIt(it.path) == @[
      PATH_MANIFEST, PATH_SCRIPT, PATH_PAGE, "contributor/ronri/pga_benchmark/pages/map.svg"
    ]
    check treeGood().checkPackagesNode.len == 0
