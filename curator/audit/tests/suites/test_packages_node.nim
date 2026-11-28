## Replicate static check and search of advisories of `packages_node.nim` (CONTRIBUTOR.md,
##   TypeScript and Node; #1045).

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unittest]
import ../../src/[findings, packages_node]
import ./fixtures


const  # TODO: Document.
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
    "// import x from 'lodash';", "/**\n * import 'lodash';\n */", "/* require('lodash') */",
    "imported('lodash');", "fromage('lodash');", "const source = 'import';",
    "report('a corner of empty sky stands to start from', false, 'every corner hovers');",
    "draw(); // import x from 'lodash';", "const said = \"it reads from 'lodash'\";",
    "reimport('lodash');", "const said = 'it\\'s from \"lodash\"';",
    "$from('rxjs-like');", "this.#require('lodash');", "const v = from('lodash');",
    "go(); /* see import('lodash') */", "const t = `\nimport x from 'lodash'\n`;",
    "const m = loader.require('lodash');", "+x;", "-x;",
  ]
    ## Lines that hold word of import beside quote, and name no module; line of `report` as found
    ##   at line 223 of `chrome.ts` of `pga_visualiser`, 2026-11-27, where `from` inside string
    ##   read next quote as specifier; five before last as review of #1069 found them refused,
    ##   and last holds keyword after `.`.
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

  test "import in code after comment, regular expression or into template reads at its line":
    # Case: review of #1069; each form passed, since line opening `/*` or `*` was skipped whole,
    #   quote of regular expression opened string, and `${}` read as text of template.
    #   Domain: comment before import on its line and on line above, line opening `*` in code,
    #   regular expression holding quote, `${}` on one line, on line below, and holding braces;
    #   then operand across line, `/` in class, division before `/` in string, and string that
    #   line ends; then division after expression, and after variable named `from`, expression
    #   after block, and line that backslash continues in string, as second review of #1069 found
    #   mutants of each pass; then comment and tab before specifier, spread before `require`, and
    #   division after `++` and `--`, which that review found passing. Case with comment across
    #   line holds count of lines past it, and its `lodash` stays cost of module. Then form feed,
    #   vertical tab and space of no break before specifier, `+-` and `+++` before expression, and
    #   comment `/*/ */`, as third review found.
    for (text, line) in [
      ("/* note */ import x from 'lodash';", 1),
      ("/* a\n b */ import x from 'lodash';", 2),
      ("const a = b\n  * require('lodash');", 2),
      ("s.replace(/\"/g, ''); import x from 'lodash';", 1),
      ("const t = `${await import('lodash')}`;", 1),
      ("const t = `a\nb ${require('lodash')}`;", 2),
      ("const t = `${ f({a: 1}) + require('lodash') }`;", 1),
      ("const m = import(`lodash\n`);\nimport y from 'zod';", 3),
      ("s.split(/[/']/); import x from 'lodash';", 1),
      ("const r = a / 2, s = \"/\"; import x from 'lodash';", 1),
      ("const s = 'oops\nimport x from 'lodash';", 2),
      ("const r = /a/ / 2, s = \"/\"; import x from 'lodash';", 1),
      ("const half = from / 2, s = \"/\"; import x from 'lodash';", 1),
      ("if (a) { b(); } /\"/.test(s); import x from 'lodash';", 1),
      ("const s = 'a\\\nb';\nimport x from 'lodash';", 3),
      ("await import(/* c */ 'lodash');", 1),
      ("import x from\t'lodash';", 1),
      ("const a = {...require('lodash')};", 1),
      ("const a = i++ / n; import x from 'lodash'; const b = c / d;", 1),
      ("const a = i-- / n; import x from 'lodash'; const b = c / d;", 1),
      ("import x from /* a\n b */ 'lodash';\nimport y from 'zod';", 3),
      ("import x from\f'lodash';", 1),
      ("import x from\v'lodash';", 1),
      ("import x from\xC2\xA0'lodash';", 1),
      ("a+-/'/.source; import x from 'lodash';", 1),
      ("n = a+++/'/.source; import x from 'lodash';", 1),
      ("import x from /*/ */ 'lodash';", 1),
      ("import x from\xE2\x80\x83'lodash';", 1),
      ("import x from\xEF\xBB\xBF'lodash';", 1),
      ("import x from\xE2\x80\xAF'lodash';", 1),
      ("import x from\xE3\x80\x80'lodash';", 1),
    ]:
      let found = checkScript(PATH_SCRIPT, text)
      check found.len == 1 and found[0].line == line
    # Case: fifth review of #1069; mutant that dropped U+1680, U+2000 or U+205F passed. Domain:
    #   each space of JavaScript `WhiteSpace` outside ASCII, written out.
    for space in [
      "\xC2\xA0", "\xE1\x9A\x80", "\xE2\x80\x80", "\xE2\x80\x81", "\xE2\x80\x82",
      "\xE2\x80\x83", "\xE2\x80\x84", "\xE2\x80\x85", "\xE2\x80\x86", "\xE2\x80\x87",
      "\xE2\x80\x88", "\xE2\x80\x89", "\xE2\x80\x8A", "\xE2\x80\xAF", "\xE2\x81\x9F",
      "\xE3\x80\x80", "\xEF\xBB\xBF",
    ]:
      check checkScript(PATH_SCRIPT, "import x from" & space & "'lodash';").len == 1

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

  test "page script names its source in each form that HTML and SVG allow":
    # Case: review of #1069; forms two to eight gave no finding, and `data-src` and `scripting`
    #   each gave one. Domain: one line, two lines, no quotes, spaces round `=`, capitals, `href`
    #   and `xlink:href` of SVG, `>` inside quote, `/` after name of tag, and space, backslash,
    #   entity or line break in address, which browser reads; then attribute that only ends in
    #   `src`, and tag that only opens with `script`.
    for tag in [
      "<script src=\"https://cdn.example/a.js\"></script>",
      "<script\n  src=\"https://cdn.example/a.js\"></script>",
      "<script src=https://cdn.example/a.js></script>",
      "<script src = \"https://cdn.example/a.js\"></script>",
      "<SCRIPT SRC=\"https://cdn.example/a.js\"></SCRIPT>",
      "<script href=\"https://cdn.example/a.js\"/>",
      "<script xlink:href='//cdn.example/a.js'/>",
      "<script data-note=\"a>b\" src=\"https://cdn.example/a.js\"></script>",
      "<script/src=\"https://cdn.example/a.js\"></script>",
      "<script src=\" //cdn.example/a.js\"></script>",
      "<script src=\"\\\\cdn.example/a.js\"></script>",
      "<script src=\"/\\cdn.example/a.js\"></script>",
      "<script src=\"&#47;/cdn.example/a.js\"></script>",
      "<script src=\"/\n/cdn.example/a.js\"></script>",
      "<script src=\"&#x2F;&sol;cdn.example/a.js\"></script>",
    ]:
      let found = checkPage(PATH_PAGE, "\n" & tag)
      check found.len == 1 and found[0].line == 2
    for tag in [
      "<script data-src=\"https://cdn.example/a.js\" src=\"a.js\"></script>",
      "<scripting src=\"https://cdn.example/a.js\"></scripting>",
    ]:
      check checkPage(PATH_PAGE, tag).len == 0
    let below = checkPage(PATH_PAGE, "<!-- a\nb -->\n<script src=\"//cdn.example/a.js\">")
    check below.len == 1 and below[0].line == 3  # Comment keeps its line ends.

  test "page script that browser can load from other host is finding, comment and address alike":
    # Case: third review of #1069; blank of each HTML comment hid each script after `<!-->`,
    #   `<!--->`, `--!>`, `<!--` in attribute, script or title, and each form of address below
    #   gave no finding. Domain: each such comment, comment that browser closes as written, then
    #   control, entity with and without `;`, and scheme with no slashes in address.
    #   Script inside comment is finding too, since rule refuses where browser may load.
    let script = "<script src=\"https://cdn.example/a.js\"></script>"
    for page in [
      "<!--> " & script, "<!---> " & script, "<!-- a --!> " & script,
      "<img alt=\"<!--\">" & script, "<script>const s='<!--';</script>" & script,
      "<title><!--</title>" & script, "<!-- " & script & " -->",
    ]:
      check checkPage(PATH_PAGE, page).len == 1
    for address in [
      "/&#9;/cdn.example/a.js", "/&#10;/cdn.example/a.js", "/&#13;/cdn.example/a.js",
      "&#1;//cdn.example/a.js", "\x01//cdn.example/a.js", "\f//cdn.example/a.js",
      "/\t/cdn.example/a.js", "/\r/cdn.example/a.js", "&#47&#47cdn.example/a.js",
      "&#x2F&#x2Fwww.example/a.js", "&#X2F;/cdn.example/a.js", "https&colon;//cdn.example/a.js",
      "https:cdn.example/a.js", "https:/cdn.example/a.js",
      # Case: fourth review of #1069; named reference, leading zeros, and each mutant that passed.
      "/&Tab;/cdn.example/a.js", "/&NewLine;/cdn.example/a.js", "/&bsol;cdn.example/a.js",
      "&bsol;&bsol;cdn.example/a.js", "&#0000000047;&#0000000047;cdn.example/a.js",
      "&#x000000002F;/cdn.example/a.js", "https&#00000000058;//cdn.example/a.js",
      "&sol;&sol;cdn.example/a.js", "&#32;//cdn.example/a.js", "&#047;&#047;cdn.example/a.js",
      "&#99999999999999999999999;//cdn.example/a.js", "\xEF\xBC\x8F\xEF\xBC\x8Fcdn.example/a.js",
      # Rule refuses each reference in path, so these that browser leaves undecoded are refused too.
      "&#x0x2F;/cdn.example/a.js", "&#+47;/cdn.example/a.js", "&#4_7;/cdn.example/a.js",
    ]:
      let found = checkPage(PATH_PAGE, "\n<script src=\"" & address & "\"></script>")
      check found.len == 1 and found[0].line == 2 and found[0].message.allIt(it >= ' ')
    # Domain: plain path of project, with spaces at its ends, with query that names host or holds
    #   `&`, with fragment, with `~` or `%2F`, and empty address of page itself.
    for address in [
      "a.js", "/scripts/a.js", " a.js ", "\ta.js\n", "./a.js?from=https://x.example",
      "./a.js?v=1&x=2", "a.js#from=//x.example", "/~pages/a.js", "%2F%2Fcdn.example/a.js", "",
    ]:
      check checkPage(PATH_PAGE, "<script src=\"" & address & "\"></script>").len == 0

  test "base, entity and href under each prefix that can send script to other host are findings":
    # Case: fourth review of #1069; `<base>` sent each path of page to other host, and SVG named
    #   address through entity or `x:href`, and each gave no finding. Domain: each, then `<base>`
    #   of plain path, which passes.
    for page in [
      "<base href=\"https://cdn.example/\"><script src=\"a.js\"></script>",
      "<!DOCTYPE svg [<!ENTITY h \"https://cdn.example\">]><script href=\"&h;/a.js\"/>",
      "<script xmlns:x=\"http://www.w3.org/1999/xlink\" x:href=\"https://cdn.example/a.js\"/>",
      "<script xmlns:q=\"http://www.w3.org/1999/xlink\" q:href=\"https://cdn.example/a.js\"/>",
    ]:
      check checkPage(PATH_PAGE, page).len == (if "&h;" in page: 2 else: 1)
    for page in [
      "<base href=\"/pages/\"><script src=\"a.js\"></script>",
      "<base src=\"https://cdn.example/\"><script src=\"a.js\"></script>",
    ]:
      check checkPage(PATH_PAGE, page).len == 0
    # Case: mutant of #1069 that read no entity, none in capitals, or first alone, passed, since
    #   `&h;` in path was finding alone. Domain: entity in capitals, then in small letters, beside
    #   plain path, each at its line; then as fifth review found, entity before tab, and entity in
    #   small letters alone. Default of attribute can name address too, so it takes same rule.
    let found = checkPage(
      PATH_PAGE, "<svg>\n<!ENTITY h \"a.js\">\n<!entity g \"b.js\">\n<script href=\"a.js\"/>"
    )
    check found.mapIt(it.line) == @[2, 3] and found.allIt("entity" in it.message)
    for page in [
      "<!ENTITY\th \"a.js\"><script href=\"a.js\"/>", "<!entity h \"a.js\">",
      "<!ATTLIST script href CDATA \"https://cdn.example/a.js\"><script/>",
      "<!ATTLIST\tscript href CDATA \"https://cdn.example/a.js\"><script/>",
    ]:
      check checkPage(PATH_PAGE, page).len == 1

  test "tag reads as HTML reads it, under any prefix, and frame that holds document is finding":
    # Case: fifth review of #1069; quote in name or in bare value ended tag at `>` that browser
    #   reads inside later value, so each address after it passed. So did script under prefix
    #   other than none, and `srcdoc` of frame, which browser decodes and loads in origin of page.
    #   Domain: quote in name and in bare value, for script and base; quote after vertical tab,
    #   which HTML reads as no space, so its value is bare; `/` that ends name; then each prefix,
    #   and `srcdoc`.
    for page in [
      "<script a\"b x=\"> \" src=\"https://cdn.example/a.js\"></script>",
      "<script x=a'b y='> ' src=https://cdn.example/a.js></script>",
      "<base x=a\"b y=\"> \" href=\"https://cdn.example/\"><script src=\"a.js\"></script>",
      "<script x=\v\" y=\"> \" src=\"https://cdn.example/a.js\"></script>",
      "<script x=a\"=\" y=\">\" src=\"https://cdn.example/a.js\"></script>",
      "<script x/src=\"https://cdn.example/a.js\"></script>",
      "<s:script xmlns:s=\"http://www.w3.org/2000/svg\" href=\"https://cdn.example/a.js\"/>",
      "<SVG:SCRIPT HREF=\"https://cdn.example/a.js\"/>",
      "<x:base href=\"https://cdn.example/\"><script src=\"a.js\"></script>",
      "<iframe srcdoc=\"&lt;script src=https://cdn.example/a.js&gt;&lt;/script&gt;\"></iframe>",
      "<IFRAME SRCDOC='a'></IFRAME>",
      # Case: sixth review of #1069; mutant that passed each of these passed suite. Domain: no
      #   space after quoted value, other quote inside value, `<` before tag, and `xml:base`, which
      #   moves each path of SVG as `<base>` does; then style sheet of XML, which as XSLT can
      #   build script of other host, from page itself or from that host.
      "<script x=\"a\"src=\"https://cdn.example/a.js\"></script>",
      "<script x='\"==' src=\"https://cdn.example/a.js\"></script>",
      "<<script src=\"https://cdn.example/a.js\"></script>",
      "<svg xml:base=\"https://cdn.example/\"><script href=\"a.js\"/></svg>",
      "<?xml-stylesheet type=\"text/xsl\" href=\"#s\"?><svg><xsl:stylesheet id=\"s\">" &
        "<xsl:element name=\"script\"><xsl:attribute name=\"href\">https://cdn.example/a.js" &
        "</xsl:attribute></xsl:element></xsl:stylesheet></svg>",
      "<?xml-stylesheet type=\"text/xsl\" href=\"https://cdn.example/t.xsl\"?><svg/>",
      # Domain: `=` that opens name and takes quote into it, as HTML reads it; then name of two
      #   prefixes and quote that never closes, which browser drops, refused even so.
      "<script =\" src=\"https://cdn.example/a.js\"></script>",
      "<a:b:script src=\"https://cdn.example/a.js\"/>", "<script src=\"https://cdn.example/a.js",
    ]:
      check checkPage(PATH_PAGE, page).len == 1
    # Domain: each space of HTML, written out, before quoted value and after name of tag.
    for space in ["\t", "\n", "\f", "\r", " "]:
      for page in [
        "<script x=" & space & "\"> \" src=\"https://cdn.example/a.js\"></script>",
        "<script" & space & "src=\"https://cdn.example/a.js\"></script>",
      ]:
        check checkPage(PATH_PAGE, page).len == 1
    # Domain: comment of plain path, which takes same rule, `>` in quoted value, frame of path,
    #   tag whose name only ends with `script`, and vertical tab that opens name, as `\vsrc`, which
    #   browser reads as name, so `src` before it stays empty.
    for page in [
      "<!-- <script src=\"a.js\"></script> -->", "<script x=\"a>b\" src=\"a.js\"></script>",
      "<iframe src=\"a.html\"></iframe>", "<noscript src=\"https://cdn.example/a.js\">",
      "<script \vsrc=\"https://cdn.example/a.js\"></script>",
      "<script src \v=\"https://cdn.example/a.js\"></script>",
      # Case: sixth review of #1069; vertical tab after name of tag, which HTML reads as part of
      #   name, gave false refusal, and no case held bare plain path. Domain: each, quote after
      #   name of tag, which HTML reads as part of name too, plain `xml:base`, and `srcdoc` of tag
      #   other than frame, which browser ignores.
      "<script\v src=\"https://cdn.example/a.js\"></script>", "<script src=a.js></script>",
      "<script\"x src=\"https://cdn.example/a.js\"></script>",
      "<svg xml:base=\"/pages/\"><script href=\"a.js\"/></svg>", "<div srcdoc=\"a\"></div>",
    ]:
      check checkPage(PATH_PAGE, page).len == 0

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

  test "named project that carries no node lock is refused, and each other selection passes":
    # Case: review of #1069; `koch advisories contributor/bangu/rictadni` exited 0 as clean lock.
    #   Domain: named with lock, named with none, none named with locks, none named with none.
    check failureNamed("contributor/bangu/rictadni", []) ==
      "project carries no node manifest beside its lock; got `contributor/bangu/rictadni`."
    check failureNamed(DIRECTORY, [DIRECTORY]) == ""
    check failureNamed("", [DIRECTORY]) == ""
    check failureNamed("", []) == ""

  test "version lock holds is read from its packages, and absent or unreadable is none":
    check LOCK_LODASH.versionLocked("lodash") == some("4.17.15")
    check LOCK_LODASH.versionLocked("typescript").isNone
    check "not json".versionLocked("lodash").isNone
    check MANIFEST_FOUND.namesDev == @["@playwright/test", "@types/node", "typescript"]
    check "not json".namesDev.len == 0
