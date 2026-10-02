## Hold `koch fix` to its contract: after fix, checks report none of what it fixed; second fix
##   writes nothing; any path outside branch scope refuses every write (CURATOR.md, duty 11).

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, fixes, form, idioms, kinds]
import ./fixtures


const
  CURATOR_BRANCH = "curator/rules"
    ## Curator root branch: every path but contributor code.
  CONTRIBUTOR_BRANCH = "contributor/ronri/alpha/work"
    ## Contributor branch confined to `ALPHA_DIRECTORY`.
  DIRTY = "## Do.\nimport ./[b, a]\nimport std/os \n\nlet x = 1 # One.\nlet y = 2\n\n\n"
    ## Nim source breaking every rule with fixer: import, bindings, pragma, gap, ending.


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
    let record = entry(ALPHA_DIRECTORY & "/README.md", "# Alpha \n")
    check fixEntries(CURATOR_BRANCH, [record]).written.len == 1  # record is curator's to write
    let confined = fixEntries(CONTRIBUTOR_BRANCH, [inside, outside])
    check confined.refused.mapIt(it.path) == @[inside.path]  # contributor confined too
    check fixEntries("claude/setup", [inside]).refused[0].path.len == 0  # branch outside grammar

  test "clean entries write nothing and meet no scope, wherever they lie":
    let
      clean = entry(ALPHA_DIRECTORY & "/src/a.nim", "## Do.\n\n" & STRICT_FUNCS & "\n")
      plan = fixEntries(CURATOR_BRANCH, [clean])
    check plan.written.len == 0 and plan.fixed.len == 0 and plan.refused.len == 0
    check fixEntries(CURATOR_BRANCH, [entry("a.bin", "x \n")]).written.len == 0  # kind unread
