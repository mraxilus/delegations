## Replicate static check and search of advisories of `packages_node.nim` (CONTRIBUTOR.md,
##   TypeScript and Node; #1045).

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unittest]
import ../../src/[findings, packages_node]
import ./fixtures


const
  PATH_SCRIPT = "contributor/ronri/pga_visualiser/tools/drive/main.ts"  ## Script of project.
  PATH_MANIFEST = "contributor/ronri/pga_visualiser/package.json"  ## Manifest of same project.
  PATH_PAGE = "contributor/ronri/pga_visualiser/pages/shell.html"  ## Page of same project.
  DIRECTORY = "contributor/ronri/pga_benchmark"  ## Project whose lock suite asks of.
  PATH_LOCK = DIRECTORY & "/package-lock.json"  ## Lock of that project.
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
    "reimport('lodash');", "const said = 'it\\'s from \"lodash\"';",
  ]
    ## Lines that hold word of import beside quote, and name no module; line of `report` as found
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
  AUDIT_CLEAN = """{
  "auditReportVersion": 2,
  "vulnerabilities": {},
  "metadata": {
    "vulnerabilities": {
      "info": 0,
      "low": 0,
      "moderate": 0,
      "high": 0,
      "critical": 0,
      "total": 0
    },
    "dependencies": {
      "prod": 1,
      "dev": 26,
      "optional": 20,
      "peer": 0,
      "peerOptional": 0,
      "total": 26
    }
  }
}"""
    ## Answer of `npm audit --package-lock-only --json` over lock of `pga_benchmark`, npm
    ##   10.9.9, 2026-11-27.
  AUDIT_LODASH = """{
  "auditReportVersion": 2,
  "vulnerabilities": {
    "lodash": {
      "name": "lodash",
      "severity": "high",
      "isDirect": true,
      "via": [
        {
          "source": 1106913,
          "name": "lodash",
          "dependency": "lodash",
          "title": "Command Injection in lodash",
          "url": "https://github.com/advisories/GHSA-35jh-r3h4-6jhm",
          "severity": "high",
          "cwe": [
            "CWE-77",
            "CWE-94"
          ],
          "cvss": {
            "score": 7.2,
            "vectorString": "CVSS:3.1/AV:N/AC:L/PR:H/UI:N/S:U/C:H/I:H/A:H"
          },
          "range": "<4.17.21"
        },
        {
          "source": 1106920,
          "name": "lodash",
          "dependency": "lodash",
          "title": "Prototype Pollution in lodash",
          "url": "https://github.com/advisories/GHSA-p6mc-m468-83gw",
          "severity": "high",
          "cwe": [
            "CWE-770",
            "CWE-1321"
          ],
          "cvss": {
            "score": 7.4,
            "vectorString": "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:H/A:H"
          },
          "range": ">=3.7.0 <4.17.19"
        }
      ],
      "effects": [],
      "range": "<=4.17.23",
      "nodes": [
        "node_modules/lodash"
      ],
      "fixAvailable": {
        "name": "lodash",
        "version": "4.18.1",
        "isSemVerMajor": false
      }
    }
  },
  "metadata": {
    "vulnerabilities": {
      "info": 0,
      "low": 0,
      "moderate": 0,
      "high": 1,
      "critical": 0,
      "total": 1
    },
    "dependencies": {
      "prod": 1,
      "dev": 1,
      "optional": 0,
      "peer": 0,
      "peerOptional": 0,
      "total": 1
    }
  }
}"""
    ## Answer of same command over lock holding `lodash` `4.17.15`, npm 10.9.9, 2026-11-27,
    ##   trimmed from five advisories to first two.
  AUDIT_ERROR =
      "{\n  \"message\": \"request to http://127.0.0.1:9/-/npm/v1/security/audits/quick " &
      "failed, reason: connect ECONNREFUSED 127.0.0.1:9\",\n  \"error\": {\n    " &
      "\"summary\": \"\",\n    \"detail\": \"\"\n  }\n}\n"
    ## Answer of same command, with exit 1, where registry does not answer, npm 10.9.9,
    ##   2026-11-27.
  LOCK_LODASH = """{
  "packages": {
    "": {"devDependencies": {"lodash": "4.17.15"}},
    "node_modules/lodash": {"version": "4.17.15"}
  }
}
"""
    ## Fields of lock that reader reads, as npm 10.9.9 wrote them for that `lodash`.
  MANIFEST_LODASH = """{"devDependencies": {"lodash": "4.17.15"}}"""
    ## Manifest beside that lock.


func answering(answer: Answer): proc(argument: string): Answer =
  ## Construct ask giving one answer for each argument.
  result = proc(argument: string): Answer = answer


func latestServing(versions: openArray[(string, string)]): proc(argument: string): Answer =
  ## Construct ask of latest release, answering version of each name, and failure for others.
  let held = @versions
  result = proc(argument: string): Answer =
    for (name, version) in held:
      if name == argument: return (code: 0, output: version & "\n")
    (code: 1, output: "")


func lockNaming(versions: openArray[(string, string)]): string =
  ## Construct lock naming version of each dependency, as `packages` of npm holds it.
  let entries = versions.mapIt("\"node_modules/" & it[0] & "\": {\"version\": \"" & it[1] & "\"}")
  "{\"packages\": {" & entries.join(", ") & "}}"


func manifestNaming(names: openArray[string]): string =
  ## Construct manifest naming each dev dependency.
  let entries = names.mapIt("\"" & it & "\": \"1.0.0\"")
  "{\"devDependencies\": {" & entries.join(", ") & "}}"



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

  test "package named in two fields takes line of field that names it":
    # Domain: dev field names package first, then runtime field names it again below.
    let found = checkManifest(
      PATH_MANIFEST,
      "{\n  \"devDependencies\": {\n    \"lodash\": \"4.17.15\"\n  },\n" &
        "  \"dependencies\": {\n    \"lodash\": \"4.17.15\"\n  }\n}\n",
    )
    check found.mapIt(it.line) == @[6, 3]

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



suite "Advisories":
  test "clean answer of lock as found names no advisory":
    # Case: lock of `pga_benchmark`, npm 10.9.9, 2026-11-27.
    let (advisories, failure) = readAudit((code: 0, output: AUDIT_CLEAN))
    check advisories.len == 0 and failure == ""

  test "audit keeps dev dependencies where environment of run leaves them out":
    # Case: review of #1069; `NODE_ENV=production`, or `omit=dev` in npmrc, read lock holding
    #   `lodash` `4.17.15` as clean, npm 10.9.9, 2026-11-27, since each listed tool is dev
    #   dependency; flag holds against each such setting.
    check "--include=dev" in COMMAND_AUDIT.split(' ')

  test "answer naming package reads severity, range, fix and each advisory":
    # Case: lock holding `lodash` `4.17.15`, npm 10.9.9, 2026-11-27.
    let (advisories, failure) = readAudit((code: 1, output: AUDIT_LODASH))
    check failure == "" and advisories.len == 1
    check advisories[0].name == "lodash" and advisories[0].severity == "high"
    check advisories[0].range == "<=4.17.23" and advisories[0].fix == "4.18.1"
    check advisories[0].notes == @[
      "Command Injection in lodash, https://github.com/advisories/GHSA-35jh-r3h4-6jhm",
      "Prototype Pollution in lodash, https://github.com/advisories/GHSA-p6mc-m468-83gw",
    ]

  test "answer that cannot stand is failure, never clean lock":
    # Domain: exit of failure, text, error object, no count, exit against count, count against
    #   packages; each would close issue for work never done if read as clean.
    let lodash_cleared = AUDIT_LODASH.replace("\"total\": 1", "\"total\": 0")
    for answer in [
      (code: 2, output: AUDIT_CLEAN), (code: 127, output: ""), (code: 0, output: "not json"),
      (code: 1, output: "{\"error\": {\"code\": \"ENOTFOUND\"}}"), (code: 0, output: "{}"),
      (code: 1, output: AUDIT_CLEAN), (code: 0, output: AUDIT_LODASH),
      (code: 1, output: lodash_cleared), (code: 0, output: "[]"),
    ]:
      let (advisories, failure) = readAudit(answer)
      check advisories.len == 0 and failure.len > 0

  test "answer whose packages are no object is failure, and never crash of koch":
    # Case: review of #1069; list of packages raised in `pairs`, and crash exits 1, which reads as
    #   advisory. Domain: list, text, number and null in place of object, beside count of 0.
    for value in ["[]", "\"none\"", "0", "null"]:
      let (advisories, failure) = readAudit((
        code: 0,
        output: "{\"vulnerabilities\": " & value & ", \"metadata\": {\"vulnerabilities\": " &
          "{\"total\": 0}}}",
      ))
      check advisories.len == 0 and failure == "npm audit gave no count of advisories"

  test "answer of error names it, though it holds no count either":
    # Case: registry that does not answer, npm 10.9.9, 2026-11-27.
    let (advisories, failure) = readAudit((code: 1, output: AUDIT_ERROR))
    check advisories.len == 0 and failure == "npm audit answered with error"

  test "fix that npm gives as flag reads as no fix, or as fix by npm audit fix":
    # Case: review of #1069; npm 10.9.9 gives `true` for `follow-redirects` `1.15.0` under `axios`
    #   `1.6.0`, which `npm audit fix` mends, and verb printed no fix. Domain: `false` and `true`.
    for (flag, said) in [("false", "no fix"), ("true", "fix by `npm audit fix`")]:
      let answer = AUDIT_LODASH.replace(
        "\"fixAvailable\": {\n        \"name\": \"lodash\",\n        \"version\": \"4.18.1\",\n" &
          "        \"isSemVerMajor\": false\n      }",
        "\"fixAvailable\": " & flag,
      )
      let (advisories, failure) = readAudit((code: 1, output: answer))
      check failure == "" and advisories[0].fix == ""
      let (lines, _, _) = checkAdvisories(
        [Locked(directory: DIRECTORY, manifest: MANIFEST_LODASH, lock: LOCK_LODASH)],
        answering((code: 1, output: answer)),
        latestServing([("lodash", "4.18.1")]),
      )
      check ("  `lodash`, high, `<=4.17.23`, " & said & ":") in lines

  test "advisory is one finding at lock, and lines name package, fix and each advisory":
    let (lines, found, failure) = checkAdvisories(
      [Locked(directory: DIRECTORY, manifest: MANIFEST_LODASH, lock: LOCK_LODASH)],
      answering((code: 1, output: AUDIT_LODASH)),
      latestServing([("lodash", "4.18.1")]),
    )
    check failure == "" and found.len == 1
    check found[0].path == PATH_LOCK and found[0].message.endsWith("got `lodash`.")
    check lines[1] == "  `lodash`, high, `<=4.17.23`, fix `4.18.1`:"
    check lines[^1] == "  `lodash`: locks `4.17.15` against `4.18.1`."

  test "dev dependency below latest release is line alone, and one at it or above is none":
    # Domain: below by patch, by minor with larger patch, equal, above, of two digits each side.
    for (locked, latest, is_behind) in [
      ("1.63.0", "1.65.1", true), ("1.9.9", "1.10.0", true), ("7.0.2", "7.0.2", false),
      ("7.1.0", "7.0.2", false), ("22.20.10", "22.20.9", false),
    ]:
      let (lines, found, failure) = checkAdvisories(
        [Locked(directory: DIRECTORY, manifest: manifestNaming(["typescript"]),
          lock: lockNaming([("typescript", locked)]))],
        answering((code: 0, output: AUDIT_CLEAN)),
        latestServing([("typescript", latest)]),
      )
      check failure == "" and found.len == 0
      check lines[0] == "Advisories that npm names in `" & PATH_LOCK & "`: none."
      check (lines.len == 3) == is_behind

  test "latest release npm cannot give, or lock lacking dev dependency, is failure":
    # Domain: exit of failure, exit of failure beside version, empty answer, list, and lock that
    #   names no version; second as review of #1069 found it untested.
    for (latest, lock) in [
      (latestServing([]), lockNaming([("typescript", "7.0.2")])),
      (answering((code: 1, output: "7.0.2\n")), lockNaming([("typescript", "7.0.2")])),
      (answering((code: 0, output: "")), lockNaming([("typescript", "7.0.2")])),
      (
        answering((code: 0, output: "[\n  \"7.0.1\",\n  \"7.0.2\"\n]")),
        lockNaming([("typescript", "7.0.2")]),
      ),
      (latestServing([("typescript", "7.0.2")]), lockNaming([])),
    ]:
      let (lines, found, failure) = checkAdvisories(
        [Locked(directory: DIRECTORY, manifest: manifestNaming(["typescript"]), lock: lock)],
        answering((code: 0, output: AUDIT_CLEAN)),
        latest,
      )
      check lines.len == 0 and found.len == 0 and failure.endsWith("got `" & PATH_LOCK & "`.")

  test "failure of later lock drops lines and findings of earlier one":
    # Domain: advisory in first lock, then answer that cannot stand in second; no half search.
    var asked = 0
    let (lines, found, failure) = checkAdvisories(
      [
        Locked(directory: DIRECTORY, manifest: MANIFEST_LODASH, lock: LOCK_LODASH),
        Locked(directory: "contributor/ronri/pga_visualiser", manifest: "{}", lock: "{}"),
      ],
      proc(argument: string): Answer =
        inc asked
        if asked == 1: (code: 1, output: AUDIT_LODASH) else: (code: 2, output: ""),
      latestServing([("lodash", "4.18.1")]),
    )
    check lines.len == 0 and found.len == 0
    check failure.endsWith("got `contributor/ronri/pga_visualiser/package-lock.json`.")

  test "version lock holds is read from its packages, and absent or unreadable is none":
    check LOCK_LODASH.versionLocked("lodash") == some("4.17.15")
    check LOCK_LODASH.versionLocked("typescript").isNone
    check "not json".versionLocked("lodash").isNone
    check MANIFEST_FOUND.namesDev == @["@playwright/test", "@types/node", "typescript"]
    check "not json".namesDev.len == 0
