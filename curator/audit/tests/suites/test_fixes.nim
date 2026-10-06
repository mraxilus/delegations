## Hold `koch fix` to its contract: after fix, checks report none of what it fixed; second fix
##   writes nothing; any path outside branch scope refuses every write (CURATOR.md, duty 11);
##   kind without style guide passes through unwritten, its findings kept for hand.
##   `LAYOUT`, `FENCED_ROWS` and `LOCK` are copied in knoller's `tests/suites/test_chain.nim`,
##     which drives same chain without `koch fix`; fix to one is finished only when other is
##     checked.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, tables, unittest]
import ../../../knoller/src/knoller
import ../../src/[findings, fixes, form, kinds, symbols, tree]
import ./fixtures


const
  CURATOR_BRANCH = "curator/rules"  ## Curator root branch: every path but contributor code.
  CONTRIBUTOR_BRANCH = "contributor/ronri/alpha/work"
    ## Contributor branch confined to `ALPHA_DIRECTORY`.
  DIRTY = "## Do.\nimport ./[b, a]\nimport std/os \n\nlet x = 1 # One.\nlet y = 2\n\n\n"
    ## Nim source breaking every rule with fixer: import, bindings, pragma, gap, ending.
  LAYOUT =
    "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\nimport std/strutils\n\n\n" &
    "#[ Section ]#\n\n" &
    "proc f(a: int; b: string): int {.noSideEffect, inline.} = a+b.len\n" &
    "proc g(\n    a: int\n) = discard\n" &
    "let x = foo(\n  1,\n  2\n)\necho x\n" &
    "let y = @[\n  first_item_named_at_length_so_list_crosses_column,\n" &
    "  second_item_named_at_length_so_list_crosses_column\n]\necho h(q=1)\nexport y, x\n"
    ## Nim source breaking each layout rule `checkFormatting` holds; static pass reads X.2 alone.
  FENCED_ROWS =
    "let m = matrix(\n  #!fix off\n  1,  0,\n\n  0,  1,\n  #!fix on\n)\n" &
    "let n = matrix(1+2)\n"
    ## Nim source whose hand-shaped rows fence keeps, and whose call after fence fix reaches.
  GROUPED = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet s = @(x) + @(x[0])\n"
    ## Nim source holding group parser proves needless, and group it refuses.
  LOCK =
    "{\n  \"items\": {},\n  \"nimbleFile\": {\n    \"filename\": \"alpha.nimble\",\n" &
    "    \"content\": []\n  }\n}\n"
    ## Atlas lock holding copy of nimble file `alpha.nimble`.
  ASKS_MAX = 8  ## Rounds of asking parser at most, as `fixes.nim` takes.


proc everyFix(
  branch: string,
  tree: Tree,
  entries: openArray[Entry],
  locked: openArray[string],
  context: Context,
  provers: ProverOf,
): tuple[fix: Fixed, failures: seq[string]] =
  ## Fix every entry again each round of asking: reference that loop of `provenFix`, fixing
  ##   entries that asked alone, is held equal to (Article IX.2).
  var known = context
  result.fix = fixEntries(branch, entries, locked, known)
  for ask in 1..ASKS_MAX:
    if result.fix.asked.len == 0: break
    for failure in known.answered(tree, result.fix.asked, provers):
      let line = Rule.NeedlessParentheses.id & ": " & failure
      if line notin result.failures: result.failures.add line
    result.fix = fixEntries(branch, entries, locked, known)



suite "Fixes":
  test "named path is file or directory git lists, each once; unknown name is finding":
    let tree = @[
      entry("curator/audit/src/a.nim", DIRTY),
      entry("curator/audit/src/b.nim", DIRTY),
      entry("koch.nim", DIRTY),
    ]
    let (entries, unknown) = tree.entriesNamed(
      ["curator/audit/", "curator/audit/src/a.nim", "./koch.nim"],
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
      (written, fixed, refused, _, _, _) = fixEntries(CURATOR_BRANCH, [entry(path, DIRTY)])
    check refused.len == 0 and written.len == 1
    let source = written[0].content
    check checkForm(path, source, Kind.Nim.rule).len == 0  # form checks report none
    check checkComments(path, source).len == 0  # X.9 too, which static pass runs later
    check checkIdioms(path, source).len == 0  # idiom checks report none
    for rule in ["trailing whitespace", "file ending", "trailing comment", "bracket import",
                 "single bindings", "strictFuncs"]:
      check fixed.anyIt(it.message.startsWith(rule))  # each fixer reported
    check fixed.allIt(it.path == path and it.message.endsWith(")"))  # rule alone, cited
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
    check checkForm(path, LAYOUT, Kind.Nim.rule).mapIt(it.message) ==
      @["First-tier banner takes three blank lines before it (X.2); got `2`."]  # X.2 alone wired
    check checkIdioms(path, LAYOUT).len == 0
    let found = checkFormatting(path, LAYOUT, Kind.Nim).findingsOf
    for rule in ["(X.2)", "(X.9)", "(STYLE.md §5)", "Signature", "Call", "trailing separator",
                 "share one bracket", "alphabetised", "`=` takes"]:
      check found.anyIt(rule in it.message)  # each rule reported
    let (written, fixed, refused, _, _, _) = fixEntries(CURATOR_BRANCH, [entry(path, LAYOUT)])
    check refused.len == 0 and written.len == 1
    check checkFormatting(path, written[0].content, Kind.Nim).len == 0  # all cleared
    check checkForm(path, written[0].content, Kind.Nim.rule).len == 0  # nothing new
    check checkIdioms(path, written[0].content).len == 0
    check fixEntries(CURATOR_BRANCH, written).written.len == 0  # second run writes nothing
    check written[0].content == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/[os, strutils]\n" &
      "\n\n\n#[ Section ]#\n\n" &
      "proc f(a: int, b: string): int {.inline, noSideEffect.} = a + b.len\n" &
      "proc g(a: int) = discard\n" &
      "let x = foo(1, 2)\necho x\n" &
      "let y = @[\n  first_item_named_at_length_so_list_crosses_column,\n" &
      "  second_item_named_at_length_so_list_crosses_column,\n]\necho h(q = 1)\nexport x, y\n"
    check fixed.allIt(it.line in 0 .. LAYOUT.count('\n'))  # each report names line as given


  test "layout checks read Nim syntax; import and list checks read `.nim` alone":
    let breach = "import std/os\nimport std/strutils\nlet a = b+c\n"
    check checkFormatting("a.nims", breach, Kind.NimScript).findingsOf.allIt("X.9" in it.message)
    check checkFormatting("a.nim", breach, Kind.Nim).len == 2  # brackets too
    check checkFormatting("a.md", breach, Kind.Markdown).len == 0


  test "range in X.9 form passes every fixer: none writes it, wrapping keeps it (X.9, X.3)":
    let
      path = "curator/audit/src/a.nim"
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      ranged = head & "for i in 0..<n: f(s[i .. ^1], t[1..^2], i + 1 ..< n)\n" &
        "const C = {'a'..'z'}\ncase c\nof 'a'..'z': discard\nelse: discard\n"
      wide = head & "let x = foo(s[0..<n], t[1 .. ^1], " & "a".repeat(40) & ", " &
        "b".repeat(26) & ")\nf(\n  s[0..<n],\n  t[1 .. ^1]\n)\nproc h(" &
        "a".repeat(20) & ": range[0..9], " & "b".repeat(24) &
        ": array[0..<4, int], c: int): int = c\n"
    check fixEntries(CURATOR_BRANCH, [entry(path, ranged)]).written.len == 0  # in X.9 form
    let spaced = ranged.replace("0..<n", "0 ..< n").replace("1..^2", "1 ..^ 2")
      .replace("'a'..'z'", "'a' .. 'z'")
    check fixEntries(CURATOR_BRANCH, [entry(path, spaced)]).written[0].content == ranged
    let (written, fixed, _, _, _, _) = fixEntries(CURATOR_BRANCH, [entry(path, wide)])
    check written[0].content == head & "let x = foo(\n  s[0..<n],\n  t[1 .. ^1],\n  " &
      "a".repeat(40) & ",\n  " & "b".repeat(26) & ",\n)\nf(s[0..<n], t[1 .. ^1])\n" &
      "proc h(\n  " & "a".repeat(20) & ": range[0..9], " & "b".repeat(24) &
      ": array[0..<4, int], c: int\n): int = c\n"  # split, joined and wrapped, ranges kept
    check not fixed.anyIt(it.message.startsWith("expression spacing"))  # no range respaced
    check fixEntries(CURATOR_BRANCH, written).written.len == 0  # second run writes nothing


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


  test "fence keeps lines between its markers; fix and layout checks reach every other line":
    let
      path = "curator/audit/src/a.nim"
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & FENCED_ROWS
      unfenced = source.replace("  " & FENCE_OFF & "\n", "").replace("  " & FENCE_ON & "\n", "")
    check checkFormatting(path, unfenced, Kind.Nim).anyIt(it.line == 5)  # rows join unfenced
    check checkFormatting(path, source, Kind.Nim).mapIt(it.line) == @[12]  # after fence alone
    let plan = fixEntries(CURATOR_BRANCH, [entry(path, source)])
    check plan.written[0].content == source.replace("1+2", "1 + 2")  # rows kept, blank line too
    check checkFormatting(path, plan.written[0].content, Kind.Nim).len == 0
    check fixEntries(CURATOR_BRANCH, plan.written).written.len == 0
    check plan.held.len == 1 and plan.held[0].render == path & ":6: Fence keeps its lines as " &
      "written, and inside them expression-spacing breaks 2 times from line 7 (X.1); got lines " &
      "`6` to `10`."  # what breaks inside fence, by rule
    check fixEntries(CURATOR_BRANCH, [entry(path, unfenced)]).held.len == 0  # no fence, no warning


  test "fence left open runs to end of file; marker inside string fences nothing":
    let
      path = "curator/audit/a.nims"
      tail = "let a = 1+2\n" & FENCE_OFF & "\nlet b = 1+2\n"
    check fixEntries(CURATOR_BRANCH, [entry(path, tail)]).written[0].content ==
      "let a = 1 + 2\n" & FENCE_OFF & "\nlet b = 1+2\n"
    let quoted = "let s = \"\"\"\n" & FENCE_OFF & "\n\"\"\"\nlet b = 1+2\n"
    check checkFormatting(path, quoted, Kind.NimScript).mapIt(it.line) == @[4]


  test "fence crossing bracket leaves whole file as written, and is its one finding":
    let
      path = "curator/audit/a.nims"
      crossing = "let a = 1+2\nlet m = f(\n  " & FENCE_OFF & "\n  1,  0,\n)\n" & FENCE_ON & "\n"
      plan = fixEntries(CURATOR_BRANCH, [entry(path, crossing)])
    check plan.written.len == 0 and plan.left.mapIt(it.line) == @[2]
    check plan.held.len == 0  # fence it cannot read is finding, and no warning
    check checkFormatting(path, crossing, Kind.NimScript).mapIt(it.line) == @[2]
    let literal = "let a = 1+2\n#!fix fenced\n"  # would be read back as fenced line
    check fixEntries(CURATOR_BRANCH, [entry(path, literal)]).left.mapIt(it.line) == @[2]


  test "fixer that would move fenced lines is skipped, and its finding stays for hand":
    let
      path = "curator/audit/src/a.nim"
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet a = 1\nlet b = f(\n  " & FENCE_OFF &
        "\n  1,  0,\n  " & FENCE_ON & "\n)\n"
    check fixEntries(CURATOR_BRANCH, [entry(path, source)]).written.len == 0  # would re-indent
    check checkIdioms(path, source).len == 1  # bindings finding left


  test "dead export of checker drops its `*` through tree context, where own module calls it":
    let
      path = "curator/audit/src/a.nim"
      module = "## Do.\n\n" & STRICT_FUNCS & "\n\nfunc f*(): int = 1\n\nlet x = f()\n"
      tree = @[entry(path, module), entry("curator/audit/src/b.nim", "## Do.\n")]
      context = tree.contextOf
      plan = fixEntries(CURATOR_BRANCH, [tree[0]], context = context)
    check plan.written[0].content == module.replace("f*()", "f()")
    check plan.fixed.mapIt(it.line) == @[5]
    check fixEntries(CURATOR_BRANCH, [tree[0]]).written.len == 0  # no context: nothing known
    let again = @[plan.written[0], tree[1]]
    check fixEntries(CURATOR_BRANCH, [again[0]], context = again.contextOf).written.len == 0


  test "semantic pass settles conversion first; file compiling nowhere is left with its error":
    let
      path = "curator/audit/src/a.nim"
      module = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet Y = x.float\n"
      queries = semanticQueries(@[entry(path, module)], [entry(path, module)])
    check queries.len == 1 and queries[0].sites == @[(5, 10), (5, 8)]
    var answer = Answer(path: path)
    answer.symbols[(5, 10)] = Symbol(kind: "skType")
    answer.symbols[(5, 8)] = Symbol(kind: "skLet")
    let
      tree = @[entry(path, module)]
      plan = fixEntries(CURATOR_BRANCH, tree, context = tree.contextOf(tree, [answer]))
    check plan.written[0].content == module.replace("x.float", "float(x)")
    check plan.fixed.mapIt(it.message) == @["type conversion (STYLE.md §5)"]
    check fixEntries(CURATOR_BRANCH, plan.written).written.len == 0  # second fix writes nothing
    let
      failed = Answer(path: path, reason: "undeclared identifier: 'x'")
      left = fixEntries(CURATOR_BRANCH, tree, context = tree.contextOf(tree, [failed]))
    check left.written.len == 0
    check left.left[0].message.endsWith("got `undeclared identifier: 'x'`.")


  test "abbreviation renames at every use across files, or is refused whole where fix reaches not":
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      a = entry("curator/audit/src/a.nim", head & "let CTX* = 1\n")
      b = entry("curator/audit/src/b.nim", head & "import ./a\n\nlet Y = CTX\n")
      tree = @[a, b]
      queries = semanticQueries(tree, tree)
    check queries.len == 2
    check queries[0].sites == @[(5, 4)] and queries[0].names == @["CONTEXT"]
    check queries[1].sites == @[(7, 8)]
    let declared =
      Symbol(kind: "skLet", name: "a.CTX", file: "/r/curator/audit/src/a.nim", line: 5, column: 4)
    var answers = @[Answer(path: a.path), Answer(path: b.path)]
    answers[0].symbols[(5, 4)] = declared
    answers[0].globals["CONTEXT"] = @[]
    answers[1].symbols[(7, 8)] = declared
    let plan = fixEntries(CURATOR_BRANCH, tree, context = tree.contextOf(tree, answers))
    check plan.written.len == 2
    check plan.written[0].content == head & "let CONTEXT* = 1\n"
    check plan.written[1].content == head & "import ./a\n\nlet Y = CONTEXT\n"
    check plan.fixed.filterIt(it.message == "abbreviation (V.6)").len == 2
    let alone = fixEntries(CURATOR_BRANCH, [a], context = tree.contextOf([a], answers))
    check alone.written.len == 0  # rename would write `b.nim`, which fix leaves alone
    check "refused: it would write `" & b.path & "`, which this fix leaves alone" in
      alone.left[0].message
    check alone.left[0].message.endsWith("; got `CTX`.")


  test "entry block moves into `proc main` through fix, or stays for hand with its reason":
    let
      path = "curator/audit/src/a.nim"
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & PROFILER_IMPORT & "\n\n"
      plan = fixEntries(
        CURATOR_BRANCH,
        [entry(path, head & "when isMainModule:\n  let count = 1\n  echo count\n")],
      )
    check plan.written.mapIt(it.content) == @[
      head & "proc main() =\n  ## TODO: Document.\n  let count = 1\n  echo count\n\n\n" &
        "when isMainModule:\n  main()\n",
    ]  # V.10
    check plan.fixed.mapIt((it.line, it.message)) == @[(8, "entry block (V.10)")]
    check fixEntries(CURATOR_BRANCH, plan.written).written.len == 0  # second fix writes nothing
    let held = fixEntries(
      CURATOR_BRANCH,
      [entry(path, head & "when isMainModule:\n  var count {.global.} = 0\n")],
    )
    check held.written.len == 0
    check held.left.mapIt((it.line, it.message)) == @[
      (8, "Entry block (V.10) stays for hand, since move into `proc main` is refused: " &
        "`{.global.}` binds at module level alone; got `count`."),
    ]  # V.10


  test "case renames at every use across files, and entry block moves into `proc main`, in one run":
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      a = entry("curator/audit/src/a.nim", head & "proc Run_all*(): int = 1\nconst COUNT* = 2\n")
      b = entry(
        "curator/audit/src/b.nim",
        head & PROFILER_IMPORT & "\n\nimport ./a\n\nwhen isMainModule:\n" &
          "  let COUNT = Run_all()\n  echo COUNT\n",
      )
      tree = @[a, b]
      queries = semanticQueries(tree, tree)
    check queries.mapIt((it.path, it.sites, it.names)) == @[
      (a.path, @[(5, 5)], @["runAll"]),  # local `COUNT` of `b.nim` asks no other file
      (b.path, @[(10, 14), (10, 6), (11, 7)], @["count"]),
    ]
    let
      routine =
        Symbol(kind: "skProc", name: "a.Run_all", file: "/r/" & a.path, line: 5, column: 5)
      binding = Symbol(kind: "skLet", name: "b.COUNT", file: "/r/" & b.path, line: 10, column: 6)
    var answers = @[Answer(path: a.path), Answer(path: b.path)]
    answers[0].symbols[(5, 5)] = routine
    answers[0].globals["runAll"] = @[]
    answers[1].symbols[(10, 14)] = routine
    for site in [(10, 6), (11, 7)]: answers[1].symbols[site] = binding
    answers[1].globals["count"] = @[]
    let plan = fixEntries(CURATOR_BRANCH, tree, context = tree.contextOf(tree, answers))
    check plan.written.mapIt(it.content) == @[
      head & "proc runAll*(): int = 1\nconst COUNT* = 2\n",
      head & PROFILER_IMPORT & "\n\nimport ./a\n\nproc main() =\n  ## TODO: Document.\n" &
        "  let count = runAll()\n  echo count\n\n\nwhen isMainModule:\n  main()\n",
    ]  # V.1, V.10
    check plan.fixed.mapIt((it.path, it.line, it.message)) == @[
      (a.path, 5, "routine case (V.1)"),
      (b.path, 10, "routine case (V.1)"),
      (b.path, 10, "local constant case (V.1)"),
      (b.path, 11, "local constant case (V.1)"),
      (b.path, 10, "entry block (V.10)"),
    ]  # each report at line of source as given
    check plan.left.len == 0
    let again = plan.written
    check again.mapIt(checkNames(it.path, it.content, []).len) == @[0, 0]  # V.1, V.10: none left
    check semanticQueries(again, again).len == 0  # no rename left for second run to ask
    check fixEntries(CURATOR_BRANCH, again, context = again.contextOf(again)).written.len == 0


  test "global breaking case and coining abbreviation takes one rename that settles both rules":
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      a = entry("curator/audit/src/a.nim", head & "let tmp_dir* = \"a\"\n")
      b = entry("curator/audit/src/b.nim", head & "import ./a\n\nlet PATH_HOME = tmp_dir\n")
      tree = @[a, b]
    check semanticQueries(tree, tree).mapIt((it.path, it.sites, it.names)) == @[
      (a.path, @[(5, 4)], @["TEMPORARY_DIRECTORY"]),
      (b.path, @[(7, 16)], newSeq[string]()),
    ]  # one rename asked, never V.6 spelling `temporary_directory` beside it
    let declared =
      Symbol(kind: "skLet", name: "a.tmp_dir", file: "/r/" & a.path, line: 5, column: 4)
    var answers = @[Answer(path: a.path), Answer(path: b.path)]
    answers[0].symbols[(5, 4)] = declared
    answers[0].globals["TEMPORARY_DIRECTORY"] = @[]
    answers[1].symbols[(7, 16)] = declared
    let plan = fixEntries(CURATOR_BRANCH, tree, context = tree.contextOf(tree, answers))
    check plan.written.mapIt(it.content) == @[
      head & "let TEMPORARY_DIRECTORY* = \"a\"\n",
      head & "import ./a\n\nlet PATH_HOME = TEMPORARY_DIRECTORY\n",
    ]  # V.1, V.6
    check plan.fixed.mapIt(it.message) ==
      @["abbreviation (V.6) and global case (V.1)", "abbreviation (V.6) and global case (V.1)"]
    check plan.written.mapIt(checkNames(it.path, it.content, []).len) == @[0, 0]  # V.1, V.6


  test "rename fix cannot prove stays for hand with its reason, and asks semantic pass nothing":
    let
      path = "curator/audit/src/a.nim"
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\ntype Def {.importc: \"b3Def\".} = object\n" &
        "  enableSleep {.importc.}: bool\n"
      tree = @[entry(path, source)]
      plan = fixEntries(CURATOR_BRANCH, tree, context = tree.contextOf(tree))
    check semanticQueries(tree, tree).len == 0  # refused already, so nothing asked
    check plan.written.len == 0
    check plan.left.mapIt((it.line, it.message)) == @[
      (6, "Field case (V.1) stays for hand, since rename to `enable_sleep` is refused: " &
        "foreign code reads name through `importc`; got `enableSleep`."),
    ]  # V.1


  test "needless parentheses go where parser of project's pin proves it, one run for each pin":
    var pins: seq[string]
    let
      other = GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])")
      tree = goodTree().with(
        entry("curator/beta/beta.nimble", NIMBLE_TEXT.replace(PIN, COMMIT)),
        entry(AUDIT_DIRECTORY & "/src/a.nim", GROUPED),
        entry(AUDIT_DIRECTORY & "/src/b.nim", other),
        entry("curator/beta/src/a.nim", GROUPED),
      )
      entries = tree[^3 .. ^1]
      stub = proc (pin: string): Prover =
        pins.add pin
        result = proc (sources: seq[string]): Proving =
          Proving(answers: sources.mapIt(it.candidatesOf.filterIt(it.got notin
            ["(x[0])", "(y[0])"]).mapIt(it.opening[0])))
    let unanswered = fixEntries(CURATOR_BRANCH, entries)
    check unanswered.written.len == 0  # nothing proven, nothing written
    check unanswered.asked.mapIt(it[0]) == entries.mapIt(it.path)  # each source asks
    let (fix, failures) = provenFix(CURATOR_BRANCH, tree, entries, [], tree.contextOf, stub)
    check failures.len == 0
    check pins[0 .. 1] == @[PIN, COMMIT]  # first round: one run for each pin, project's own
    check fix.written.mapIt(it.content) == @[
      GROUPED.replace("@(x) +", "@x +"), other.replace("@(y) +", "@y +"),
      GROUPED.replace("@(x) +", "@x +"),
    ]  # group parser refuses stays
    check fix.fixed.filterIt("needless parentheses" in it.message).len == 3
    check fix.asked.len == 0
    let again = provenFix(CURATOR_BRANCH, tree, fix.written, [], tree.contextOf, stub)
    check again.fix.written.len == 0  # second fix writes nothing


  test "where no compiler serves pin, nothing goes, and one warning says why":
    let
      tree = goodTree().with(entry("tools/a.nim", GROUPED))
      broken = proc (pin: string): Prover =
        result = proc (sources: seq[string]): Proving =
          Proving(answers: newSeq[seq[int]](sources.len), failure: "Compiler failed; got `x`.")
    let (fix, failures) = provenFix(CURATOR_BRANCH, tree, [tree[^1]], [], tree.contextOf, broken)
    check fix.written.len == 0 and fix.fixed.len == 0
    check failures == @["needless-parentheses: Compiler failed; got `x`."]  # driver pin asked
    let unpinned = goodTree().without(AUDIT_DIRECTORY & "/audit.nimble").with(
      entry("koch2.nim", GROUPED),
    )
    let alone = provenFix(CURATOR_BRANCH, unpinned, [unpinned[^1]], [], unpinned.contextOf, broken)
    check alone.fix.written.len == 0
    check alone.failures == @[
      "needless-parentheses: Parser proved no removal, since project pins no compiler; got " &
        "`koch2.nim`.",
    ]


  test "nimble file whose copy `atlas.lock` holds is never written, and read by no layout check":
    let
      nimble = entry(ALPHA_DIRECTORY & "/alpha.nimble", "version = \"0.1.0\" \nlet a = 1+2\n")
      tree = @[nimble, entry(ALPHA_DIRECTORY & "/atlas.lock", LOCK)]
    check tree.lockedNimbles == @[nimble.path]
    let plan = fixEntries(CONTRIBUTOR_BRANCH, [nimble], tree.lockedNimbles)
    check plan.written.len == 0 and plan.left.len == 1 and "atlas.lock" in plan.left[0].message
    check checkFormatting(tree).len == 0  # silent on it
    check checkFormatting(@[nimble]).len == 1  # read where no lock holds its copy
    check fixEntries(CONTRIBUTOR_BRANCH, [nimble]).written.len == 1


  test "fix of entries that asked alone gives same fix as fix of every entry, each round":
    # Entries under two pins, some asking parser over two rounds, one asking through its fence
    #   alone, and some asking nothing.
    let
      other = GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])")
      fenced = "## Do.\n\n" & STRICT_FUNCS & "\n\n#!fix off\nlet b = @(x) + 1\n#!fix on\n"
      tree = goodTree().with(
        entry("curator/beta/beta.nimble", NIMBLE_TEXT.replace(PIN, COMMIT)),
        entry(AUDIT_DIRECTORY & "/src/a.nim", GROUPED),
        entry(AUDIT_DIRECTORY & "/src/b.nim", DIRTY),
        entry("curator/beta/src/c.nim", other & "let t = a+b\n"),
        entry("curator/beta/src/d.nim", fenced),
        entry("curator/beta/src/e.nim", "## Do.\n\n" & STRICT_FUNCS & "\n\nlet z = 1\n"),
        entry("curator/beta/README.md", "# Beta\n"),
      )
      entries = tree[^6 .. ^1]
      asking = entries.filterIt(fixEntries(CURATOR_BRANCH, [it]).asked.len > 0)
    check asking.mapIt(it.path) == @[
      AUDIT_DIRECTORY & "/src/a.nim", "curator/beta/src/c.nim", "curator/beta/src/d.nim",
    ]  # some entries ask, and some do not
    var calls = 0
    let
      stubbed = proc (sources: seq[string]): Proving =
        Proving(answers: sources.mapIt(
          it.candidatesOf.filterIt(it.got notin ["(x[0])", "(y[0])"]).mapIt(it.opening[0]),
        ))
      counted = proc (pin: string): Prover =
        result = proc (sources: seq[string]): Proving =
          inc calls
          stubbed(sources)
      broken = proc (pin: string): Prover =
        result = proc (sources: seq[string]): Proving =
          Proving(answers: newSeq[seq[int]](sources.len), failure: "Compiler failed; got `x`.")
      commit_broken = proc (pin: string): Prover =
        if pin == COMMIT: broken(pin) else: counted(pin)
    for provers in [counted, broken, commit_broken]:
      let
        proven = provenFix(CURATOR_BRANCH, tree, entries, [], tree.contextOf, provers)
        reference = everyFix(CURATOR_BRANCH, tree, entries, [], tree.contextOf, provers)
      check proven.fix.written.mapIt((it.path, it.content)) ==
          reference.fix.written.mapIt((it.path, it.content))
      for (fast, every) in [
        (proven.fix.fixed, reference.fix.fixed),
        (proven.fix.refused, reference.fix.refused),
        (proven.fix.left, reference.fix.left),
        (proven.fix.held, reference.fix.held),
      ]:
        check fast.mapIt(it.render) == every.mapIt(it.render)
      check proven.fix.asked == reference.fix.asked
      check proven.failures == reference.failures
    check calls >= 4  # askers asked again in second round, under both loops
