## Hold `koch fix` to its contract: after fix, checks report none of what it fixed; second fix
##   writes nothing; any path outside branch scope refuses every write (CURATOR.md, duty 11);
##   kind without style guide passes through unwritten, its findings kept for hand.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unittest]
import ../../src/[findings, fixes, form, idioms, kinds]
import ./fixtures


const
  CURATOR_BRANCH = "curator/rules"
    ## Curator root branch: every path but contributor code.
  CONTRIBUTOR_BRANCH = "contributor/ronri/alpha/work"
    ## Contributor branch confined to `ALPHA_DIRECTORY`.
  DIRTY = "## Do.\nimport ./[b, a]\nimport std/os \n\nlet x = 1 # One.\nlet y = 2\n\n\n"
    ## Nim source breaking every rule with fixer: import, bindings, pragma, gap, ending.
  LAYOUT =
    "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\nimport std/strutils\n\n\n" &
    "#[ Section ]#\n\n" &
    "proc f(a: int; b: string): int {.noSideEffect, inline.} = a+b.len\n" &
    "proc g(\n    a: int\n) = discard\n" &
    "let x = foo(\n  1,\n  2,\n)\necho x\nlet y = @[\n  1,\n  2\n]\necho h(q=1)\nexport y, x\n"
    ## Nim source breaking each layout rule `checkFormatting` holds, and no wired check.


suite "Fixes":
  test "named path is file or directory git lists, each once; unknown name is finding":
    let tree = @[
      entry("curator/audit/src/a.nim", DIRTY),
      entry("curator/audit/src/b.nim", DIRTY),
      entry("koch.nim", DIRTY),
    ]
    let (entries, unknown) = tree.entriesNamed(
      ["curator/audit/", "curator/audit/src/a.nim", "./koch.nim"]
    )
    check entries.mapIt(it.path) == @[
      "curator/audit/src/a.nim", "curator/audit/src/b.nim", "koch.nim",
    ]  # directory, file inside it once, and `./` form
    check unknown.len == 0
    let typo = tree.entriesNamed(["curator/audi"]).unknown
    check typo.len == 1 and typo[0].message.endsWith("got `curator/audi`.")  # whole folder only

  test "after fix, form and idiom checks report nothing, and second fix writes nothing":
    let
      path = "curator/audit/src/a.nim"
      (written, fixed, refused) = fixEntries(CURATOR_BRANCH, [entry(path, DIRTY)])
    check refused.len == 0 and written.len == 1
    let source = written[0].content
    check checkForm(path, source, Kind.Nim.rule).len == 0  # form checks report none
    check checkComments(path, source).len == 0  # X.9 too, which static pass runs later
    check checkIdioms(path, source).len == 0  # idiom checks report none
    for rule in ["trailing whitespace", "file ending", "trailing comment", "bracket import",
                 "single bindings", "strictFuncs"]:
      check fixed.anyIt(it.message.startsWith(rule))  # each fixer reported
    check fixed.allIt(it.path == path and it.message.endsWith(" fixed"))
    check fixEntries(CURATOR_BRANCH, written).written.len == 0  # idempotent

  test "curator branch never writes contributor code; one path outside refuses every write":
    let
      inside = entry("curator/audit/src/a.nim", DIRTY)
      outside = entry(ALPHA_DIRECTORY & "/src/a.nim", DIRTY)
      both = fixEntries(CURATOR_BRANCH, [inside, outside])
    check both.written.len == 0 and both.fixed.len == 0  # nothing written, nothing fixed
    check both.refused.mapIt(it.path) == @[outside.path]  # outside path named
    check "Curator writes only" in both.refused[0].message  # `checkPropagation` reached
    check fixEntries(CURATOR_BRANCH, [inside]).written.len == 1  # inside alone writes
    let confined = fixEntries(CONTRIBUTOR_BRANCH, [inside, outside])
    check confined.refused.mapIt(it.path) == @[inside.path]  # contributor confined too
    check fixEntries("claude/setup", [inside]).refused[0].path.len == 0  # branch outside grammar

  test "clean entries write nothing and meet no scope, wherever they lie":
    let
      clean = entry(ALPHA_DIRECTORY & "/src/a.nim", "## Do.\n\n" & STRICT_FUNCS & "\n")
      plan = fixEntries(CURATOR_BRANCH, [clean])
    check plan.written.len == 0 and plan.fixed.len == 0 and plan.refused.len == 0
    check fixEntries(CURATOR_BRANCH, [entry("a.bin", "x \n")]).written.len == 0  # kind unread

  test "layout checks wait outside static pass, and fix clears every one in one run":
    let path = "curator/audit/src/a.nim"
    check checkForm(path, LAYOUT, Kind.Nim.rule).len == 0  # static pass reads none of them
    check checkIdioms(path, LAYOUT).len == 0
    let found = checkFormatting(path, LAYOUT, Kind.Nim)
    for rule in ["(X.2)", "(X.9)", "(STYLE.md §5)", "Signature", "Call", "trailing separator",
                 "share one bracket", "alphabetised", "Named argument"]:
      check found.anyIt(rule in it.message)  # each rule reported
    let (written, fixed, refused) = fixEntries(CURATOR_BRANCH, [entry(path, LAYOUT)])
    check refused.len == 0 and written.len == 1
    check checkFormatting(path, written[0].content, Kind.Nim).len == 0  # all cleared
    check checkForm(path, written[0].content, Kind.Nim.rule).len == 0  # nothing new
    check checkIdioms(path, written[0].content).len == 0
    check fixEntries(CURATOR_BRANCH, written).written.len == 0  # second run writes nothing
    check written[0].content == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/[os, strutils]\n" &
      "\n\n\n#[ Section ]#\n\n" &
      "proc f(a: int, b: string): int {.inline, noSideEffect.} = a + b.len\n" &
      "proc g(a: int) = discard\n" &
      "let x = foo(1, 2)\necho x\nlet y = @[\n  1,\n  2,\n]\necho h(q = 1)\nexport x, y\n"
    check fixed.allIt(it.line in 0 .. LAYOUT.count('\n'))  # each report names line as given

  test "layout checks read Nim syntax; import and list checks read `.nim` alone":
    let breach = "import std/os\nimport std/strutils\nlet a = b+c\n"
    check checkFormatting("a.nims", breach, Kind.NimScript).mapIt(it.message).allIt("X.9" in it)
    check checkFormatting("a.nim", breach, Kind.Nim).len == 2  # brackets too
    check checkFormatting("a.md", breach, Kind.Markdown).len == 0

  test "fix writes Nim kinds alone, the one language with guide; checks read every kind":
    let
      nim = entry("curator/audit/src/a.nim", DIRTY)
      script = entry("curator/audit/a.nimble", "version = \"0.1.0\" \n")
      others = [
        entry("curator/audit/README.md", "# Audit \n"),
        entry("curator/audit/tools/a.ts", "// Do. \n"),
        entry("curator/audit/a.json", "{} \n"),
        entry(".github/workflows/a.yml", "# Do. \n"),
        entry("curator/audit/nim.cfg", "# Do. \n"),
        entry("curator/audit/a.sh", "# Do. \n"),
      ]
      plan = fixEntries(CURATOR_BRANCH, @[nim, script] & @others)
    check plan.written.mapIt(it.path) == @[nim.path, script.path]  # Nim and nimble alone
    for other in others:
      let rule = other.kind.get.rule
      check not rule.has_guide  # no guide, so passes through unwritten
      check checkForm(other.path, other.content, rule).len > 0  # check reports it still
