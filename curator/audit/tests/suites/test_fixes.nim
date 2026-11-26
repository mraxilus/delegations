## Hold `koch fix` to its contract: after fix, checks report none of what it fixed; second fix
##   writes nothing; any path outside branch scope refuses every write (CURATOR.md, duty 11);
##   kind without style guide passes through unwritten, its findings kept for hand.
##   `LAYOUT`, `ROWS_FENCED` and `LOCK` are copied in knoller's `tests/suites/test_chain.nim`,
##     which drives same chain without `koch fix`; fix to one is finished only when other is
##     checked.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, tables, unittest]
import ../../../knoller/src/knoller
import ../../src/[findings, fixes, form, glossary, kinds, symbols, tree]
import ./fixtures


const
  BRANCH_CURATOR = "curator/rules"  ## Curator root branch: every path but contributor code.
  BRANCH_CONTRIBUTOR = "contributor/ronri/alpha/work"
    ## Contributor branch confined to `DIRECTORY_ALPHA`.
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
  ROWS_FENCED =
    "let m = matrix(\n  #!fix off\n  1,  0,\n\n  0,  1,\n  #!fix on\n)\n" &
    "let n = matrix(1+2)\n"
    ## Nim source whose hand-shaped rows fence keeps, and whose call after fence fix reaches.
  GROUPED = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet s = @(x) + @(x[0])  ## Sequences.\n"
    ## Nim source holding group parser proves needless, and group it refuses.
  LOCK =
    "{\n  \"items\": {},\n  \"nimbleFile\": {\n    \"filename\": \"alpha.nimble\",\n" &
    "    \"content\": []\n  }\n}\n"
    ## Atlas lock holding copy of nimble file `alpha.nimble`.
  ASKS_MAX = 8  ## Rounds of asking parser at most, as `fixes.nim` takes.


proc fixEvery(
  branch: string,
  tree: Tree,
  entries: openArray[Entry],
  locked: openArray[string],
  context: Context,
  provers: ProversPin,
): tuple[fix: Fixed, failures: seq[Finding]] =
  ## Fix every entry again each round of asking: reference that loop of `fixProven`, fixing
  ##   entries that asked alone, is held equal to (Article IX.2).
  var known = context
  result.fix = fixEntries(branch, entries, locked, known)
  for ask in 1..ASKS_MAX:
    if result.fix.asked.len == 0: break
    for failure in known.answered(tree, result.fix.asked, provers):
      let warning = finding("", 0, failure, rule = Rule.ParenthesesNeedless.id)
      if warning notin result.failures: result.failures.add warning
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
    check typo.len == 1 and typo[0].brief.endsWith("got `curator/audi`")  # whole folder only


  test "after fix, form and idiom checks report nothing, and second fix writes nothing":
    let
      path = "curator/audit/src/a.nim"
      (written, fixed, refused, _, _, _) = fixEntries(BRANCH_CURATOR, [entry(path, DIRTY)])
    check refused.len == 0 and written.len == 1
    let source = written[0].content
    check checkForm(path, source, Kind.Nim.rule).len == 0  # form checks report none
    check checkComments(path, source).len == 0  # X.9 too, which static pass runs later
    check checkIdioms(path, source).len == 0  # idiom checks report none
    for rule in ["trailing whitespace", "file ending", "trailing comment", "bracket import",
                 "single bindings", "strictFuncs"]:
      check fixed.anyIt(it.brief.startsWith(rule))  # each fixer reported
    check fixed.allIt(it.path == path and it.brief.endsWith(")"))  # rule alone, cited
    check fixEntries(BRANCH_CURATOR, written).written.len == 0  # idempotent


  test "curator branch never writes contributor code; one path outside refuses every write":
    let
      inside = entry("curator/audit/src/a.nim", DIRTY)
      outside = entry(DIRECTORY_ALPHA & "/src/a.nim", DIRTY)
      both = fixEntries(BRANCH_CURATOR, [inside, outside])
    check both.written.len == 0 and both.fixed.len == 0  # nothing written, nothing fixed
    check both.refused.mapIt(it.path) == @[outside.path]  # outside path named
    check "curator writes only" in both.refused[0].brief  # `checkPropagation` reached
    check fixEntries(BRANCH_CURATOR, [inside]).written.len == 1  # inside alone writes
    let confined = fixEntries(BRANCH_CONTRIBUTOR, [inside, outside])
    check confined.refused.mapIt(it.path) == @[inside.path]  # contributor confined too
    check fixEntries("claude/setup", [inside]).refused[0].path.len == 0  # branch outside grammar


  test "clean entries write nothing and meet no scope, wherever they lie":
    let
      clean = entry(DIRECTORY_ALPHA & "/src/a.nim", "## Do.\n\n" & STRICT_FUNCS & "\n")
      plan = fixEntries(BRANCH_CURATOR, [clean])
    check plan.written.len == 0 and plan.fixed.len == 0 and plan.refused.len == 0
    check fixEntries(BRANCH_CURATOR, [entry("a.bin", "x \n")]).written.len == 0  # kind unread


  test "layout checks wait outside static pass, and fix clears every one in one run":
    let path = "curator/audit/src/a.nim"
    check checkForm(path, LAYOUT, Kind.Nim.rule).mapIt(it.brief) ==
      @["first-tier banner takes three blank lines before it (X.2); got `2`"]  # X.2 alone wired
    check checkIdioms(path, LAYOUT).len == 0
    let found = checkFormatting(path, LAYOUT, Kind.Nim).toFindings
    for rule in ["(X.2)", "(X.9)", "(STYLE.md §5)", "signature stays on one line",
                 "call stays on its line", "share one bracket",
                 "alphabetised", "`=` takes", "(VI.1)"]:
      check found.anyIt(rule in it.brief)  # each rule reported
    let (written, fixed, refused, _, _, _) = fixEntries(BRANCH_CURATOR, [entry(path, LAYOUT)])
    check refused.len == 0 and written.len == 1
    check checkFormatting(path, written[0].content, Kind.Nim).len == 0  # all cleared
    check checkForm(path, written[0].content, Kind.Nim.rule).len == 0  # nothing new
    check checkIdioms(path, written[0].content).len == 0
    check fixEntries(BRANCH_CURATOR, written).written.len == 0  # second run writes nothing
    check written[0].content == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/[os, strutils]\n" &
        "\n\n\n#[ Section ]#\n\n" &
        "proc f(a: int, b: string): int {.inline, noSideEffect.} = a + b.len\n" &
        "  ## TODO: Document.\n\nproc g(a: int) = discard\n  ## TODO: Document.\n\n" &
        "let x = foo(1, 2)  ## TODO: Document.\necho x\n" &
        "let y = @[\n  first_item_named_at_length_so_list_crosses_column,\n" &
        "  second_item_named_at_length_so_list_crosses_column\n]  ## TODO: Document.\n" &
        "echo h(q = 1)\nexport x, y\n"
    check fixed.allIt(it.line in 0 .. LAYOUT.count('\n'))  # each report names line as given


  test "layout checks read Nim syntax; import and list checks read `.nim` alone":
    let breach = "import std/os\nimport std/strutils\n\nlet a = b+c  ## Sum.\n"
      # blank line after imports, as X.2 asks
    check checkFormatting("a.nims", breach, Kind.NimScript).toFindings.allIt("X.9" in it.brief)
    check checkFormatting("a.nim", breach, Kind.Nim).len == 2  # brackets too
    check checkFormatting("a.md", breach, Kind.Markdown).len == 0


  test "range in X.9 form passes every fixer: none writes it, wrapping keeps it (X.9, X.3)":
    let
      path = "curator/audit/src/a.nim"
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      ranged = head & "for i in 0..<n: f(s[i .. ^1], t[1..^2], i + 1 ..< n)\n" &
        "const C = {'a'..'z'}  ## Letters.\ncase c\nof 'a'..'z': discard\nelse: discard\n"
      wide = head & "let x = foo(s[0..<n], t[1 .. ^1], " & "a".repeat(40) & ", " &
        "b".repeat(26) & ")\nf(\n  s[0..<n],\n  t[1 .. ^1]\n)\nproc h(" &
        "a".repeat(20) & ": range[0..9], " & "b".repeat(24) &
        ": array[0..<4, int], c: int): int = c\n"
    check fixEntries(BRANCH_CURATOR, [entry(path, ranged)]).written.len == 0  # in X.9 form
    let spaced = ranged.replace("0..<n", "0 ..< n").replace("1..^2", "1 ..^ 2")
      .replace("'a'..'z'", "'a' .. 'z'")
    check fixEntries(BRANCH_CURATOR, [entry(path, spaced)]).written[0].content == ranged
    let (written, fixed, _, _, _, _) = fixEntries(BRANCH_CURATOR, [entry(path, wide)])
    check written[0].content == head & "let x = foo(\n  s[0..<n],\n" &
        "  t[1 .. ^1],\n  " & "a".repeat(40) & ",\n  " & "b".repeat(26) & "\n" &
        ")  ## TODO: Document.\nf(s[0..<n], t[1 .. ^1])\nproc h(\n  " & "a".repeat(20) &
        ": range[0..9], " & "b".repeat(24) & ": array[0..<4, int], c: int\n): int = c\n" &
        "  ## TODO: Document.\n"
      # split, joined and wrapped, ranges kept, and each declaration takes doc
    check not fixed.anyIt(it.brief.startsWith("expression spacing"))  # no range respaced
    check fixEntries(BRANCH_CURATOR, written).written.len == 0  # second run writes nothing


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
      plan = fixEntries(BRANCH_CURATOR, @[nim, script] & @others)
    check plan.written.mapIt(it.path) == @[nim.path, script.path]  # Nim and nimble alone
    for other in others:
      let rule = other.kind.get.rule
      check not rule.has_guide  # no guide, so passes through unwritten
      check checkForm(other.path, other.content, rule).len > 0  # check reports it still
      check not plan.fixed.anyIt(it.path == other.path)  # and fix reports no rewrite of it
    let clean = entry("curator/audit/README.md", "# Text.\n")
    check fixEntries(BRANCH_CURATOR, @[clean]).fixed.len == 0  # clean Markdown passes unchanged


  test "fence keeps lines between its markers; fix and layout checks reach every other line":
    let
      path = "curator/audit/src/a.nim"
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & ROWS_FENCED
      unfenced = source.replace("  " & FENCE_OFF & "\n", "").replace("  " & FENCE_ON & "\n", "")
    check checkFormatting(path, unfenced, Kind.Nim).anyIt(
      it.line == 5 and it.rule == Rule.WrappingCall,
    )  # rows join unfenced
    # after fence alone, and blank line and doc each binding takes
    check checkFormatting(path, source, Kind.Nim).mapIt((it.line, it.rule)) == @[
      (12, Rule.LinesBlankDefinition), (12, Rule.SpacingExpression), (5, Rule.DocMissing),
      (12, Rule.DocMissing),
    ]
    let plan = fixEntries(BRANCH_CURATOR, [entry(path, source)])
    check plan.written[0].content == source.replace(
      "  #!fix on\n)\n", "  #!fix on\n)  ## TODO: Document.\n"
    ).replace("let n = matrix(1+2)\n", "\nlet n = matrix(1 + 2)  ## TODO: Document.\n")
      # rows kept, blank line inside them too
    check checkFormatting(path, plan.written[0].content, Kind.Nim).len == 0
    check fixEntries(BRANCH_CURATOR, plan.written).written.len == 0
    check plan.warned.mapIt(it.render) == @[
      path & ":6: Fence keeps its lines as written, and inside them expression-spacing breaks 2 " &
        "times from line 7 (X.1); got lines `6` to `10`.",
    ]  # what breaks inside fence, by rule
    check fixEntries(BRANCH_CURATOR, [entry(path, unfenced)]).warned.len == 0  # no fence, none


  test "fix warns of each debug output, and writes none of it (VIII.5)":
    let
      path = "curator/audit/src/a.nim"
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\nexpandMacros:\n  m()\n"
      plan = fixEntries(BRANCH_CURATOR, [entry(path, source)])
    check plan.warned.mapIt(it.render) == @[
      path & ":5: Code leaves no debug output, which nothing reads (VIII.5); got `expandMacros:`.",
    ]
    check plan.written.len == 0  # source stays as written
    check plan.left.len == 0  # warning, never finding


  test "fix keeps word of project keeping its own prose, and drops article elsewhere (VI.5)":
    # Case: `a` of lojban joins two names as `or`, so fix deleting it from comment of
    #   `lojban_parser` changes what comment says. Domain: comment and fence warning, in listed
    #   project and in project of same domain list leaves out, each on branch of its own.
    const
      branch_parser = DIRECTORY_PARSER & "/prose"
      branch_tagger = DIRECTORY_TAGGER & "/prose"
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      source = head & "# la .alis. a la .bob. cu klama \n"
      fenced = head & FENCE_OFF & "\n# la .alis. a la .bob. cu klama\n" & FENCE_ON & "\n"
    let
      parser = fixEntries(branch_parser, [entry(DIRECTORY_PARSER & "/src/a.nim", source)])
      tagger = fixEntries(branch_tagger, [entry(DIRECTORY_TAGGER & "/src/a.nim", source)])
    check parser.refused.len == 0 and tagger.refused.len == 0  # each inside its own scope
    check parser.written.mapIt(it.content) ==
      @[head & "# la .alis. a la .bob. cu klama\n"]  # word stays, whitespace goes
    check tagger.written.mapIt(it.content) == @[head & "# la .alis. la .bob. cu klama\n"]
    check parser.fixed.mapIt(it.brief) == @["trailing whitespace (VIII.5)"]  # other fixer runs
    check fixEntries(branch_parser, [entry(DIRECTORY_PARSER & "/src/a.nim", fenced)]).warned.mapIt(
      it.brief,
    ) == @[
      "fence keeps its lines as written, and nothing inside breaks a rule (X.1); got lines `5` " &
        "to `7`",
    ]  # fence counts no article there
    check fixEntries(branch_tagger, [entry(DIRECTORY_TAGGER & "/src/a.nim", fenced)]).warned.mapIt(
      it.brief,
    ) == @[
      "fence keeps its lines as written, and inside them article-in-comment breaks once at line " &
        "6 (X.1); got lines `5` to `7`",
    ]  # and counts it elsewhere


  test "fence warning counts fixed wait in `tests/` and `tools/` of project, as static pass reads":
    # Case held: knoller read each file under directory `tests` or `tools` as drive code, which
    #   is habit of this repository, so #886 moves it to koch, which names drive code of each
    #   file. Domain: `tests/` and `tools/` of project, its `src/`, and file at root.
    let fenced = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & FENCE_OFF & "\nsleep(1)\n" & FENCE_ON & "\n"
    for (path, is_drive) in [
      (DIRECTORY_AUDIT & "/tests/suites/test_a.nim", true),
      (DIRECTORY_AUDIT & "/tools/a.nim", true),
      (DIRECTORY_AUDIT & "/src/a.nim", false),
      ("tools/a.nim", false),  # root holds no project
    ]:
      let warned = fixEntries(BRANCH_CURATOR, [entry(path, fenced)]).warned
      check warned.len == 1  # one fence
      check warned.anyIt("fixed-wait breaks once at line 6" in it.brief) == is_drive


  test "fix reads stub, umbrella and suite of project below folder of its nimble file":
    # Koch names nimble file of project of each file it fixes, and knoller reads tests, stubs and
    #   umbrella below its folder (#886). Domain: stub, umbrella and suite of project, each fixed,
    #   and same text at root, which lies in no project and so stays.
    let
      stub = "discard \"\"\"\naction: run\ncmd: \"nim c -r $file\"\n\"\"\"\n## Do.\n\n" &
        STRICT_FUNCS & "\n\ninclude \"suites.nim\"\n"
      umbrella = "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\n"
      suites = "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/unittest\n\nsuite \"A\":\n" &
        "  test \"a\":\n    check true\n"
      cases = [
        ("curator/probe/tests/test_a.nim", stub, stub.replace(" -r ", " ")),  # `-r` cut
        (
          "curator/probe/src/probe.nim",
          umbrella,
          umbrella.replace("\n\nimport", "\n\n" & IMPORT_PROFILER & "\n\nimport"),
        ),  # profiler import added
        (
          "curator/probe/tests/suites/test_b.nim",
          suites,
          suites.replace("\n\nsuite", "\n\n\n\nsuite"),
        ),  # three blank lines before suite
        ("tests/test_a.nim", stub, stub),  # root holds no project, so no stub
        ("src/probe.nim", umbrella, umbrella),
        ("tests/suites/test_b.nim", suites, suites),
      ]
    for (path, source, fixed) in cases:
      let written = fixEntries(BRANCH_CURATOR, [entry(path, source)]).written.mapIt(it.content)
      check written == (if fixed == source: newSeq[string]() else: @[fixed])


  test "fence left open runs to end of file; marker inside string fences nothing":
    let
      path = "curator/audit/a.nims"
      tail = "let a = 1+2  ## Sum.\n" & FENCE_OFF & "\nlet b = 1+2\n"
    check fixEntries(BRANCH_CURATOR, [entry(path, tail)]).written[0].content ==
      "let a = 1 + 2  ## Sum.\n" & FENCE_OFF & "\nlet b = 1+2\n"  # fence keeps doc out too
    let quoted =
      "let s = \"\"\"\n" & FENCE_OFF & "\n\"\"\"  ## Text.\nlet b = 1+2  ## Sum.\n"
    check checkFormatting(path, quoted, Kind.NimScript).mapIt((it.line, it.rule)) == @[
      (4, Rule.LinesBlankDefinition), (4, Rule.SpacingExpression),
    ]  # each check reaches line after string


  test "fence crossing bracket leaves whole file as written, and is its one finding":
    let
      path = "curator/audit/a.nims"
      crossing = "let a = 1+2\nlet m = f(\n  " & FENCE_OFF & "\n  1,  0,\n)\n" & FENCE_ON & "\n"
      plan = fixEntries(BRANCH_CURATOR, [entry(path, crossing)])
    check plan.written.len == 0 and plan.left.mapIt(it.line) == @[2]
    check plan.warned.len == 0  # fence it cannot read is finding, and no warning
    check checkFormatting(path, crossing, Kind.NimScript).mapIt(it.line) == @[2]
    let literal = "let a = 1+2\n#!fix fenced\n"  # would be read back as fenced line
    check fixEntries(BRANCH_CURATOR, [entry(path, literal)]).left.mapIt(it.line) == @[2]


  test "file knoller's fixers do not settle warns by path alone, with no article":
    # Domain: fix that does not settle, and fix that does. No source of suite leaves chain
    #   unsettled, so fix stands for what `formatted` gives.
    const unsettled =
      "File still changes after 3 rounds of fixers, so fix leaves it as written; got `3` rounds."
    check warnUnsettled("a.nim", Fix(source: "a\n", unsettled: unsettled)).mapIt(it.render) ==
        @["a.nim: " & unsettled]  # `koch fix` prints it after `warning:`, as it is
    check warnUnsettled("a.nim", Fix(source: "a\n")).len == 0  # settled source warns of nothing


  test "fixer that would move fenced lines is skipped, and its finding stays for hand":
    let
      path = "curator/audit/src/a.nim"
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet a = 1  ## One.\nlet b = f(  ## Rows.\n  " &
        FENCE_OFF &
        "\n  1,  0,\n  " & FENCE_ON & "\n)\n"
    check fixEntries(BRANCH_CURATOR, [entry(path, source)]).written.len == 0  # would re-indent
    check checkIdioms(path, source).len == 1  # bindings finding left


  test "dead export of checker drops its `*` through tree context, where own module calls it":
    let
      path = "curator/audit/src/a.nim"
      module = "## Do.\n\n" & STRICT_FUNCS & "\n\nfunc f*(): int = 1\n  ## One.\n\n" &
        "let x = f()  ## Value.\n"
      tree = @[entry(path, module), entry("curator/audit/src/b.nim", "## Do.\n")]
      context = initContext(tree)
      plan = fixEntries(BRANCH_CURATOR, [tree[0]], context = context)
    check plan.written[0].content == module.replace("f*()", "f()")
    check plan.fixed.mapIt(it.line) == @[5]
    check fixEntries(BRANCH_CURATOR, [tree[0]]).written.len == 0  # no context: nothing known
    let again = @[plan.written[0], tree[1]]
    check fixEntries(BRANCH_CURATOR, [again[0]], context = initContext(again)).written.len == 0


  test "fix reads defaults of configurations over modules of project (X.11)":
    let
      constants = "## Do.\n\n" & STRICT_FUNCS & "\n\nconst\n" &
        "  IS_CONFORMAL* {.define: \"a.is_conformal\".} = false  ## Flat parts.\n" &
        "  IS_RIGID* = not IS_CONFORMAL  ## Round parts alone.\n"
      formal = "## Do.\n\n" & STRICT_FUNCS & "\n\ntype Formal*[T] = object  ## Hold parts.\n" &
        "  when IS_CONFORMAL:\n    flat*, round*: T\n  else:\n    round*: T\n"
      tree = @[
        entry("curator/audit/src/a.nim", constants), entry("curator/audit/src/b.nim", formal)
      ]
      written = fixEntries(BRANCH_CURATOR, [tree[1]], context = initContext(tree)).written
    check written.len == 1
    check "when IS_RIGID:" in written[0].content and "when IS_CONFORMAL:" notin written[0].content
    check fixEntries(BRANCH_CURATOR, [tree[1]], context = initContext(tree[1 .. 1])).written
      .allIt("when IS_CONFORMAL:" in it.content)  # project holds no constant, so no order


  test "fix reads constants other modules of project export (STYLE.md §3)":
    let
      constants = "## Do.\n\n" & STRICT_FUNCS & "\n\nconst COUNT* = 3  ## Parts.\n"
      branch = "## Do.\n\n" & STRICT_FUNCS & "\n\nimport ./a\n\n\nproc p*() =\n  ## Print.\n" &
        "  if COUNT > 2:\n    echo 1\n"
      tree = @[
        entry("curator/audit/src/a.nim", constants), entry("curator/audit/src/b.nim", branch)
      ]
      written = fixEntries(BRANCH_CURATOR, [tree[1]], context = initContext(tree)).written
    check written.len == 1
    check "  when COUNT > 2:" in written[0].content
    check fixEntries(BRANCH_CURATOR, [tree[1]], context = initContext(tree[1 .. 1])).written
      .allIt("  if COUNT > 2:" in it.content)  # project holds no constant, so branch is runtime


  test "landmark index takes alias its project or its library declares, through names of context":
    # Case held: `koch fix` passed no names of package, so `Grade(0)` at line 139 of
    #   `src/pga_visualiser/objects.nim` stayed bare, where alias of library of `pga_visualiser`
    #   names it and knoller writes `Grade.low` (rule 9 of #443, V.8). Domain: alias in other
    #   module of project, in library of project alone, in other project, and nowhere.
    let
      alias = "## Do.\n\n" & STRICT_FUNCS & "\n\n" &
          "template vector*[G: Grade | GradeAnti](t: typedesc[G]): G = G(1)\n  ## Alias grade.\n"
      bare = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet VECTOR = Grade(1)  ## Grade of vectors.\n"
      aliased = bare.replace("Grade(1)", "Grade.vector")
      tree = @[
        entry(DIRECTORY_AUDIT & "/src/a.nim", alias), entry(DIRECTORY_AUDIT & "/src/b.nim", bare)
      ]
      plan = fixEntries(BRANCH_CURATOR, [tree[1]], context = initContext(tree))
    check plan.written.mapIt(it.content) == @[aliased]  # V.8
    check plan.fixed.mapIt((it.line, it.brief)) == @[(5, "landmark alias (V.8)")]
    let again = @[tree[0]] & plan.written
    check fixEntries(BRANCH_CURATOR, plan.written, context = initContext(again)).written.len == 0
    let
      libraries = {DIRECTORY_AUDIT & "/audit.nimble": @[alias]}.toTable
      library = initContext(tree[1..1], libraries = libraries)
    check fixEntries(BRANCH_CURATOR, [tree[1]], context = library).written.mapIt(it.content) ==
        @[aliased]  # library of project alone names alias
    let other = @[entry("curator/beta/src/a.nim", alias), tree[1]]
    check fixEntries(BRANCH_CURATOR, [tree[1]], context = initContext(other)).written.len == 0
    let alone = initContext(tree[1..1])
    check fixEntries(BRANCH_CURATOR, [tree[1]], context = alone).written.len == 0  # no alias


  test "constructor call of form fewer calls take, and index of several aliases, stay for hand":
    # Case held: `koch fix` passed no names of package, so it never reported
    #   `initMatrixViewProjection(camera, …)` at line 860 of `tests/suites/test_camera.nim` of
    #   `pga_visualiser`, which knoller leaves for hand, since more calls take dot (rule 15 of #443,
    #   STYLE.md §5). Domain: call of form fewer calls take, call of form more take, index whose
    #   aliases are several (V.8), index inside fence, which its warning counts, and no names.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      declaring = entry(
        DIRECTORY_AUDIT & "/src/a.nim",
        head & "func initPoint*(x: int): int = x\n  ## Point.\n\n" &
        "template one*(t: typedesc[Grade]): Grade = Grade(1)\n  ## One.\n\n" &
        "template first*(t: typedesc[Grade]): Grade = Grade(1)\n  ## First.\n\n" &
        "template second*(t: typedesc[Grade]): Grade = Grade(2)\n  ## Second.\n",
      )
      calling = entry(
        DIRECTORY_AUDIT & "/src/b.nim",
        head & "let\n  NORTH* = X.initPoint  ## North.\n  SOUTH* = Y.initPoint  ## South.\n" &
        "  WEST* = initPoint(Z)  ## West.\n  FIRST* = Grade(1)  ## First.\n\n" & FENCE_OFF &
        "\nlet SECOND* = Grade(2)  ## Second.\n" & FENCE_ON & "\n",
      )
      tree = @[declaring, calling]
      plan = fixEntries(BRANCH_CURATOR, [calling], context = initContext(tree))
    check plan.written.len == 0  # no fix writes either
    check plan.left.mapIt((it.line, it.brief)) == @[
      (8, "routine takes one call form on plain first argument across package, where `2` calls " &
        "take dot (STYLE.md §5); got `initPoint(Z)`"),
      (9, "landmark index stands as one of its aliases, `Grade.one` or `Grade.first` (V.8); got " &
        "`Grade(1)`"),
    ]  # dotted calls take form more calls take, so report none
    check plan.warned.mapIt(it.brief) == @[
      "fence keeps its lines as written, and inside them landmark-alias breaks once at line 12 " &
      "(X.1); got lines `11` to `13`",
    ]  # names reach fence too
    let alone = fixEntries(BRANCH_CURATOR, [calling], context = initContext(tree[1..1]))
    check alone.left.len == 0  # project declares neither constructor nor alias
    check alone.warned.allIt("nothing inside breaks a rule" in it.brief)


  test "fenced call of constructor counts in warning of its fence, as fenced index does":
    # Case of review of record: case of fence held index alone, so fence that dropped call of
    #   constructor passed suite.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      declaring = entry(
        DIRECTORY_AUDIT & "/src/a.nim", head & "func initPoint*(x: int): int = x\n  ## Point.\n"
      )
      calling = entry(
        DIRECTORY_AUDIT & "/src/b.nim",
        head & "let\n  NORTH* = X.initPoint  ## North.\n  SOUTH* = Y.initPoint  ## South.\n\n" &
        FENCE_OFF & "\nlet WEST* = initPoint(Z)  ## West.\n" & FENCE_ON & "\n",
      )
      plan = fixEntries(BRANCH_CURATOR, [calling], context = initContext(@[declaring, calling]))
    check plan.left.len == 0
    check plan.warned.mapIt(it.brief) == @[
      "fence keeps its lines as written, and inside them conversion-prefix breaks once at line " &
      "10 (X.1); got lines `9` to `11`",
    ]  # call of form fewer calls take, fenced


  test "index alias edit leaves stays for hand, whatever its place beside written one":
    # Case of critic of wiring: kept report matched edit by line and rule alone, so where index
    #   of several aliases stood before written one, `koch fix` kept report of written index and
    #   dropped its own. Domain: index of several aliases before and after written one.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      declaring = entry(
        DIRECTORY_AUDIT & "/src/a.nim",
        head & "template vector*(t: typedesc[Grade]): Grade = Grade(1)\n  ## Vector.\n\n" &
        "template two*(t: typedesc[Grade]): Grade = Grade(2)\n  ## Two.\n\n" &
        "template pair*(t: typedesc[Grade]): Grade = Grade(2)\n  ## Pair.\n",
      )
    for order in ["[Grade(1), Grade(2)]", "[Grade(2), Grade(1)]"]:
      let
        given = head & "let PAIR* = " & order & "  ## Pair.\n"
        calling = entry(DIRECTORY_AUDIT & "/src/b.nim", given)
        plan = fixEntries(BRANCH_CURATOR, [calling], context = initContext(@[declaring, calling]))
      check plan.written.mapIt(it.content) == @[given.replace("Grade(1)", "Grade.vector")]
      check plan.left.mapIt((it.line, it.brief)) == @[(5, "landmark index stands as one of " &
        "its aliases, `Grade.two` or `Grade.pair` (V.8); got `Grade(2)`")]


  test "join of interpolated string stays split in project whose file declares `formatValue`":
    let
      path = "curator/audit/src/a.nim"
      module = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet m = &\"y is {y}, from \" & $x  ## Text.\n"
      format = "## Do.\n\n" & STRICT_FUNCS & "\n\nproc formatValue*(result: var string; " &
        "value: int; specifier: string) =\n  ## Write value.\n  result.add $value\n"
      tree = @[entry(path, module), entry("curator/audit/src/b.nim", format)]
    check fixEntries(BRANCH_CURATOR, [tree[0]], context = initContext(tree[0 .. 0])).written[0]
      .content == module.replace("from \" & $x", "from {x}\"")
    check fixEntries(BRANCH_CURATOR, [tree[0]], context = initContext(tree)).written.len == 0


  test "semantic pass settles conversion first; file compiling nowhere is left with its error":
    let
      path = "curator/audit/src/a.nim"
      module = "## Do.\n\n" & STRICT_FUNCS & "\n\nlet Y = x.float  ## Value.\n"
      queries = queriesSemantic(@[entry(path, module)], [entry(path, module)])
    check queries.len == 1 and queries[0].sites == @[(5, 10), (5, 8)]
    var answer = Answer(path: path)
    answer.symbols[(5, 10)] = Symbol(kind: "skType")
    answer.symbols[(5, 8)] = Symbol(kind: "skLet")
    let
      tree = @[entry(path, module)]
      plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, [answer]))
    check plan.written[0].content == module.replace("x.float", "float(x)")
    check plan.fixed.mapIt(it.brief) == @["type conversion (STYLE.md §5)"]
    check fixEntries(BRANCH_CURATOR, plan.written).written.len == 0  # second fix writes nothing
    let
      failed = Answer(path: path, reason: "undeclared identifier: 'x'")
      left = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, [failed]))
    check left.written.len == 0
    check left.left[0].brief.endsWith("got `undeclared identifier: 'x'`")


  test "private symbol sibling reaches takes its marker, and `{.all.}` reaching none goes, by uses":
    # Case held: `koch fix` passed no uses of private symbols, so it kept `{.all.}` of line 9 of
    #   `tests/suites/test_marker.nim` of `pga_visualiser`, which reaches none, where knoller drops
    #   it (rule 7 of #443, STYLE.md §5). Domain: symbol sibling reaches, whose trailing doc moves
    #   to next line, so later report names line as given; `{.all.}` reaching none, and one
    #   reaching symbol; line holding plain comment, left for hand; file pass resolved none, which
    #   warns; and no uses.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      module = entry(
        DIRECTORY_AUDIT & "/src/a.nim",
        head & "const LIMIT = 3  ## Limit.\n\nfunc other(x: int): int = x  # Plain.\n" &
        "  ## Same.\n\nlet SUM* = 1+2  ## Sum.\n",
      )
      reaching = entry(
        DIRECTORY_AUDIT & "/src/b.nim", head & "import ./a {.all.}\n\nlet COPY* = LIMIT  ## Copy.\n"
      )
      reaching_none = entry(DIRECTORY_AUDIT & "/src/c.nim", head & "import ./a {.all.}\n")
      unresolved = entry(DIRECTORY_AUDIT & "/src/d.nim", head & "import ./a {.all.}\n")
      tree = @[module, reaching, reaching_none, unresolved]
    var uses = initTable[string, Uses]()
    uses[module.path] = Uses()
    for site in [(5, 6), (7, 5)]:
      uses[module.path].privates[site] = UsePrivate(siblings: @["b.nim"])
    uses[reaching.path] = Uses()
    uses[reaching.path].imports[(5, 9)] = true
    uses[reaching_none.path] = Uses()
    uses[reaching_none.path].imports[(5, 9)] = false
    uses[unresolved.path] = Uses(reason: "nimsuggest answered nothing")
    let plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, uses = uses))
    check plan.written.mapIt((it.path, it.content)) == @[
      (
        module.path,
        head & "const LIMIT {.used.} = 3  # Used in `b.nim`.\n  ## Limit.\n\n" &
        "func other(x: int): int = x  # Plain.\n  ## Same.\n\nlet SUM* = 1 + 2  ## Sum.\n",
      ),
      (reaching_none.path, head & "import ./a\n"),
    ]  # STYLE.md §5
    check plan.fixed.mapIt((it.path, it.line, it.brief)) == @[
      (module.path, 5, "marker used (STYLE.md §5)"),
      (module.path, 10, "expression spacing (X.9)"),  # line as given, though doc moved below 5
      (reaching_none.path, 5, "marker used (STYLE.md §5)"),
    ]
    check plan.left.mapIt((it.path, it.line, it.brief)) == @[
      (module.path, 7, "private symbol sibling `b.nim` reaches carries `{.used.}` and comment " &
        "naming sibling (STYLE.md §5); got `func other`"),
    ]  # plain comment holds line
    check plan.warned.mapIt((it.path, it.line, it.brief)) == @[
      (unresolved.path, 0, "semantic pass resolved no use, so each private symbol and `{.all.}` " &
        "stays as written (STYLE.md §5); got `nimsuggest answered nothing`"),
    ]
    let again = plan.written & @[reaching, unresolved]
    check fixEntries(BRANCH_CURATOR, again, context = initContext(again, again)).written.len == 0
    check fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree)).written.mapIt(
      it.path,
    ) == @[module.path]  # no uses: spacing alone


  test "`proc` compiler proves pure becomes `func`, through pures of context; fenced one stays":
    # Case held: `koch fix` passed no pures, so it kept `proc pointCorners*()` at line 1390 of
    #   `src/pga_visualiser/mesh.nim`, which compiler checks as `func` and knoller writes so (rule
    #   11 of #443, STYLE.md §1). Domain: routine pures prove, fenced one, left for hand, file
    #   compiler proved nothing of, which warns, and no pures.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      proven = entry(
        DIRECTORY_AUDIT & "/src/a.nim",
        head & "proc twice*(x: int): int = x * 2\n  ## Double.\n\n" & FENCE_OFF &
        "\nproc thrice*(x: int): int = x * 3\n  ## Triple.\n" & FENCE_ON & "\n",
      )
      unproven = entry(
        DIRECTORY_AUDIT & "/src/b.nim", head & "proc half*(x: int): int = x div 2\n  ## Halve.\n"
      )
      tree = @[proven, unproven]
    var pures = initTable[string, Pures]()
    pures[proven.path] = Pures(sites: @[(5, 0), (9, 0)])
    pures[unproven.path] =
      Pures(reason: "source checks clean in no configuration: undeclared identifier: 'x'")
    let plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, pures = pures))
    check plan.written.mapIt((it.path, it.content)) == @[
      (proven.path, proven.content.replace("proc twice", "func twice")),
    ]  # STYLE.md §1
    check plan.fixed.mapIt((it.path, it.line, it.brief)) == @[
      (proven.path, 5, "func pure (STYLE.md §1)"),
    ]
    check plan.left.mapIt((it.path, it.line, it.brief)) == @[
      (proven.path, 9, "routine with no effect beyond its parameters is `func` (STYLE.md §1); " &
        "got `proc thrice`"),
    ]  # fence keeps `proc`, X.1
    check plan.warned.filterIt(it.path == unproven.path).mapIt(it.brief) == @[
      "compiler proved no routine pure, so each `proc` stays as written (STYLE.md §1); got " &
      "`source checks clean in no configuration: undeclared identifier: 'x'`",
    ]
    check fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree)).written.len == 0


  test "`func` taking `ref` or `ptr` becomes `proc`, through pures of context":
    # Ruling `D5 a` of #980: rule 11 writes `proc` for `func` whose parameter type points.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/json\n\n"
      pointing = entry(
        DIRECTORY_AUDIT & "/src/c.nim", head & "func size*(n: JsonNode): int = n.len\n  ## Count.\n"
      )
      tree = @[pointing]
    var pures = initTable[string, Pures]()
    pures[pointing.path] = Pures(pointing: @[(7, 0)])
    let plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, pures = pures))
    check plan.written.mapIt((it.path, it.content)) ==
      @[(pointing.path, pointing.content.replace("func size", "proc size"))]  # STYLE.md §1
    check plan.fixed.mapIt((it.path, it.line, it.brief)) ==
      @[(pointing.path, 7, "func pure (STYLE.md §1)")]


  test "facts of each project read from disk under root, as knoller's command line reads them":
    # Case held: `koch fix` read no uses, pures or library from disk, so rules 7, 9 and 11 of #443
    #   read nothing there, where knoller's command line reads each (`resolveMarkers`,
    #   `resolvePures`, `modulesLibrary`). Domain: private symbol sibling reaches through
    #   `{.all.}`, `proc` compiler proves pure, alias of library `nim.cfg` names, which no file of
    #   tree holds, and file at root, which lies in no project and asks none.
    let
      root = repoTemp()
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      nimble = "version = \"0.1.0\"\nrequires \"nim == " & compilerRunning().version & "\"\n"
      alias = head & "template vector*[G: Grade | GradeAnti](t: typedesc[G]): G = G(1)\n" &
          "  ## Alias grade.\n"
      tree = @[
        entry("curator/fixture/fixture.nimble", nimble),
        entry(
          "curator/fixture/src/a.nim",
          head & "func helper(x: int): int = x + 1\n  ## Add one.\n\n" &
          "proc twice*(x: int): int = x * 2\n  ## Double.\n",
        ),
        entry(
          "curator/fixture/src/b.nim",
          head & "import ./a {.all.}\n\nlet ONE* = helper(0)  ## One.\n",
        ),
        entry("curator/fixture/src/c.nim", head & "let VECTOR* = Grade(1)  ## Grade of vectors.\n"),
        entry("root.nim", head & "proc thrice*(x: int): int = x * 3\n  ## Triple.\n"),
      ]
    defer: removeDir(root)
    for e in tree: writeInto(root, e.path, e.content)
    writeInto(root, "curator/fixture/nim.cfg", "--path:\"dependencies/library\"\n")
    writeInto(root, "curator/fixture/dependencies/library/algebra.nim", alias)  # git lists none
    discard root.git("add " & tree.mapIt(it.path).join(" "))
    let (uses, pures, libraries) = readFacts(root, tree)
    check uses.getOrDefault(tree[1].path).privates.values.toSeq.mapIt(it.siblings) ==
        @[@["b.nim"]]  # `b.nim` reaches `helper`, which `a.nim` never uses
    check pures.getOrDefault(tree[1].path).sites == @[(8, 0)]
    check "root.nim" notin uses and "root.nim" notin pures  # root lies in no project
    check libraries == {"curator/fixture/fixture.nimble": @[alias]}.toTable
    let
      context = initContext(tree, tree, uses = uses, pures = pures, libraries = libraries)
      written = fixEntries(BRANCH_CURATOR, tree, context = context).written
    check written.mapIt(it.path) == @[tree[1].path, tree[3].path]
    check written.anyIt(
      "func helper(x: int): int {.used.} = x + 1  # Used in `b.nim`." in it.content,
    )  # rule 7
    check written.anyIt("func twice*(x: int): int = x * 2" in it.content)  # rule 11
    check written.anyIt(it.content == tree[3].content.replace("Grade(1)", "Grade.vector"))


  test "abbreviation renames at every use across files, or is refused whole where fix reaches not":
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      a = entry("curator/audit/src/a.nim", head & "let CTX* = 1  ## Count.\n")
      b = entry("curator/audit/src/b.nim", head & "import ./a\n\nlet Y = CTX  ## Value.\n")
      tree = @[a, b]
      queries = queriesSemantic(tree, tree)
    check queries.len == 2
    check queries[0].sites == @[(5, 4)] and queries[0].names == @["CONTEXT"]
    check queries[1].sites == @[(7, 8)]
    let declared =
      Symbol(kind: "skLet", name: "a.CTX", file: "/r/curator/audit/src/a.nim", line: 5, column: 4)
    var answers = @[Answer(path: a.path), Answer(path: b.path)]
    answers[0].symbols[(5, 4)] = declared
    answers[0].globals["CONTEXT"] = @[]
    answers[1].symbols[(7, 8)] = declared
    let plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, answers))
    check plan.written.len == 2
    check plan.written[0].content == head & "let CONTEXT* = 1  ## Count.\n"
    check plan.written[1].content == head & "import ./a\n\nlet Y = CONTEXT  ## Value.\n"
    check plan.fixed.filterIt(it.brief == "abbreviation (V.6)").len == 2
    let alone = fixEntries(BRANCH_CURATOR, [a], context = initContext(tree, [a], answers))
    check alone.written.len == 0  # rename would write `b.nim`, which fix leaves alone
    check "refused: it would write `" & b.path & "`, which this fix leaves alone" in
      alone.left[0].brief
    check alone.left[0].brief.endsWith("; got `CTX`")


  test "entry block moves into `proc main` through fix, or stays for hand with its reason":
    let
      path = "curator/audit/src/a.nim"
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & IMPORT_PROFILER & "\n\n"
      plan = fixEntries(
        BRANCH_CURATOR,
        [entry(path, head & "when isMainModule:\n  let count = 1\n  echo count\n")],
      )
    check plan.written.mapIt(it.content) == @[
      head & "\nproc main() =\n  ## TODO: Document.\n  let count = 1\n  echo count\n\n\n" &
        "when isMainModule:\n  main()\n",
    ]  # V.10, and X.2 before routine after imports
    check plan.fixed.mapIt((it.line, it.brief)) == @[
      (9, "entry block (V.10)"), (0, "definition blank lines (X.2)"),
    ]  # blank line before `proc main`, which fix inserts, so at line `0`
    check fixEntries(BRANCH_CURATOR, plan.written).written.len == 0  # second fix writes nothing
    let held = fixEntries(
      BRANCH_CURATOR,
      [entry(path, head & "\nwhen isMainModule:\n  var count {.global.} = 0\n")],
    )  # two blank lines after imports, as X.2 asks, so fix writes nothing
    check held.written.len == 0
    check held.left.mapIt((it.line, it.brief)) == @[
      (10, "entry block (V.10) stays for hand, since move into `proc main` is refused: " &
        "`{.global.}` binds at module level alone; got `count`"),
    ]  # V.10


  test "case renames at every use across files, and entry block moves into `proc main`, in one run":
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      a = entry(
        "curator/audit/src/a.nim",
        head & "proc Run_all*(): int = 1\n  ## Run.\nconst COUNT* = 2  ## Count.\n",
      )
      b = entry(
        "curator/audit/src/b.nim",
        head & IMPORT_PROFILER & "\n\nimport ./a\n\nwhen isMainModule:\n" &
          "  let COUNT = Run_all()\n  echo COUNT\n",
      )
      tree = @[a, b]
      queries = queriesSemantic(tree, tree)
    check queries.mapIt((it.path, it.sites, it.names)) == @[
      (a.path, @[(5, 5)], @["runAll"]),  # local `COUNT` of `b.nim` asks no other file
      (b.path, @[(11, 14), (11, 6), (12, 7)], @["count"]),
    ]
    let
      routine =
        Symbol(kind: "skProc", name: "a.Run_all", file: "/r/" & a.path, line: 5, column: 5)
      binding = Symbol(kind: "skLet", name: "b.COUNT", file: "/r/" & b.path, line: 11, column: 6)
    var answers = @[Answer(path: a.path), Answer(path: b.path)]
    answers[0].symbols[(5, 5)] = routine
    answers[0].globals["runAll"] = @[]
    answers[1].symbols[(11, 14)] = routine
    for site in [(11, 6), (12, 7)]: answers[1].symbols[site] = binding
    answers[1].globals["count"] = @[]
    let plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, answers))
    check plan.written.mapIt(it.content) == @[
      head & "proc runAll*(): int = 1\n  ## Run.\n\nconst COUNT* = 2  ## Count.\n",
      head & IMPORT_PROFILER & "\n\nimport ./a\n\n\nproc main() =\n  ## TODO: Document.\n" &
        "  let count = runAll()\n  echo count\n\n\nwhen isMainModule:\n  main()\n",
    ]  # V.1, V.10
    check plan.fixed.mapIt((it.path, it.line, it.brief)) == @[
      (a.path, 5, "name case (V.1)"),
      (a.path, 7, "definition blank lines (X.2)"),
      (b.path, 11, "name case (V.1)"),
      (b.path, 11, "name case (V.1)"),
      (b.path, 12, "name case (V.1)"),
      (b.path, 11, "entry block (V.10)"),
      (b.path, 0, "definition blank lines (X.2)"),
    ]  # each report at line of source as given, by rule knoller's check names
    check plan.left.len == 0
    let again = plan.written
    check again.mapIt(checkNames(it.path, it.content, []).len) == @[0, 0]  # V.1, V.10: none left
    check queriesSemantic(again, again).len == 0  # no rename left for second run to ask
    check fixEntries(BRANCH_CURATOR, again, context = initContext(again, again)).written.len == 0


  test "global breaking case and coining abbreviation takes one rename that settles both rules":
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      a = entry("curator/audit/src/a.nim", head & "let tmp_dir* = \"a\"  ## Directory.\n")
      b =
        entry("curator/audit/src/b.nim", head & "import ./a\n\nlet PATH_HOME = tmp_dir  ## Home.\n")
      tree = @[a, b]
    check queriesSemantic(tree, tree).mapIt((it.path, it.sites, it.names)) == @[
      (a.path, @[(5, 4)], @["TEMPORARY_DIRECTORY"]),
      (b.path, @[(7, 16)], newSeq[string]()),
    ]  # one rename asked, never V.6 spelling `temporary_directory` beside it
    let declared =
      Symbol(kind: "skLet", name: "a.tmp_dir", file: "/r/" & a.path, line: 5, column: 4)
    var answers = @[Answer(path: a.path), Answer(path: b.path)]
    answers[0].symbols[(5, 4)] = declared
    answers[0].globals["TEMPORARY_DIRECTORY"] = @[]
    answers[1].symbols[(7, 16)] = declared
    let plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree, answers))
    check plan.written.mapIt(it.content) == @[
      head & "let TEMPORARY_DIRECTORY* = \"a\"  ## Directory.\n",
      head & "import ./a\n\nlet PATH_HOME = TEMPORARY_DIRECTORY  ## Home.\n",
    ]  # V.1, V.6
    check plan.fixed.mapIt(it.brief) == @["name case (V.1)", "name case (V.1)"]  # one rename
    check plan.written.mapIt(checkNames(it.path, it.content, []).len) == @[0, 0]  # V.1, V.6


  test "glued `anti` renames at every use where words of project decide its cut, through context":
    # Case held: `koch fix` passed no names of package, so it planned no cut rename and left
    #   `ANTISCALAR` at line 238 of `tests/suites/test_regressions.nim` of `curator/knoller`, which
    #   knoller renames `SCALAR_ANTI` from words of its package (rule 8 of #443, V.2). Domain: word
    #   other module of project declares, word no module of project declares, and global breaking
    #   case too, whose one rename settles both rules.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      words = entry(
        DIRECTORY_AUDIT & "/src/a.nim",
        head & "func scalar*(): int = 1\n  ## One.\n\nfunc basis*(): int = 2\n  ## Two.\n",
      )
      glued = entry(
        DIRECTORY_AUDIT & "/src/b.nim",
        head & "const ANTISCALAR* = 2  ## Two.\n\nlet COUNT* = ANTISCALAR + 1  ## Three.\n",
      )
      cased = entry(DIRECTORY_AUDIT & "/src/c.nim", head & "let Antibasis* = 3  ## Odd.\n")
      tree = @[words, glued, cased]
    check queriesSemantic(tree, [glued, cased]).mapIt((it.path, it.sites, it.names)) == @[
      (glued.path, @[(5, 6), (7, 13)], @["SCALAR_ANTI"]),
      (cased.path, @[(5, 4)], @["BASIS_ANTI"]),
    ]  # one rename for both rules, never case rename `ANTIBASIS` beside it
    check queriesSemantic(tree[1..2], [glued, cased]).mapIt((it.path, it.names)) ==
        @[(cased.path, @["ANTIBASIS"])]  # no module declares either word, so case rename alone
    var answers = @[Answer(path: glued.path), Answer(path: cased.path)]
    for site in [(5, 6), (7, 13)]:
      answers[0].symbols[site] =
        Symbol(kind: "skConst", name: "b.ANTISCALAR", file: "/r/" & glued.path, line: 5, column: 6)
    answers[0].globals["SCALAR_ANTI"] = @[]
    answers[1].symbols[(5, 4)] =
      Symbol(kind: "skLet", name: "c.Antibasis", file: "/r/" & cased.path, line: 5, column: 4)
    answers[1].globals["BASIS_ANTI"] = @[]
    let
      context = initContext(tree, [glued, cased], answers)
      plan = fixEntries(BRANCH_CURATOR, [glued, cased], context = context)
    check plan.written.mapIt(it.content) == @[
      glued.content.replace("ANTISCALAR", "SCALAR_ANTI"),
      cased.content.replace("Antibasis", "BASIS_ANTI"),
    ]  # V.2, V.1
    check plan.fixed.mapIt((it.path, it.line, it.brief)) == @[
      (glued.path, 5, "name cut (V.2)"),
      (glued.path, 7, "name cut (V.2)"),
      (cased.path, 5, "name case (V.1)"),
    ]  # joined rename takes rule of case, as knoller names it


  test "cut rename keeps word that glossary of project lists, as case rename of audit keeps it":
    # Case of critic of wiring: no case held which words cut rename keeps, so cut taking jargon
    #   alone passed suite; glossary of project lists `tmp`, which V.6 spells out elsewhere.
    #   Domain: glossary of project, and none.
    let
      head = "## Do.\n\n" & STRICT_FUNCS & "\n\n"
      words = entry(DIRECTORY_AUDIT & "/src/a.nim", head & "func scalar*(): int = 1\n  ## One.\n")
      glued = entry(DIRECTORY_AUDIT & "/src/b.nim", head & "const ANTISCALAR_TMP* = 2  ## Two.\n")
      glossary = entry(DIRECTORY_AUDIT & "/" & GLOSSARY_ROOT,
        "# Glossary\n\n" & HEADING_STANDARDS & "\n\n- `tmp`: temporary.\n")
    check queriesSemantic(@[words, glued, glossary], [glued]).mapIt(it.names) ==
        @[@["SCALAR_ANTI_TMP"]]  # V.2, word glossary lists stays
    check queriesSemantic(@[words, glued], [glued]).mapIt(it.names) ==
        @[@["SCALAR_ANTI_TEMPORARY"]]  # V.2 and V.6 in one rename


  test "rename fix cannot prove stays for hand with its reason, and asks semantic pass nothing":
    let
      path = "curator/audit/src/a.nim"
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\ntype Def {.importc: \"b3Def\".} = object" &
        "  ## Body.\n" &
        "  enableSleep {.importc.}: bool  ## Whether body sleeps.\n"
      tree = @[entry(path, source)]
      plan = fixEntries(BRANCH_CURATOR, tree, context = initContext(tree, tree))
    check queriesSemantic(tree, tree).len == 0  # refused already, so nothing asked
    check plan.written.len == 0
    check plan.left.mapIt((it.line, it.brief)) == @[
      (6, "name case (V.1) stays for hand, since rename to `enable_sleep` is refused: " &
        "foreign code reads name through `importc`; got `enableSleep`"),
    ]  # V.1


  test "needless parentheses go where parser of project's pin proves it, one run for each pin":
    var pins: seq[string]
    let
      other = GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])")
      tree = treeGood().with(
        entry("curator/beta/beta.nimble", TEXT_NIMBLE.replace(PIN, COMMIT)),
        entry(DIRECTORY_AUDIT & "/src/a.nim", GROUPED),
        entry(DIRECTORY_AUDIT & "/src/b.nim", other),
        entry("curator/beta/src/a.nim", GROUPED),
      )
      entries = tree[^3 .. ^1]
      stub = proc (pin: string): Prover =
        pins.add pin
        result = proc (sources: seq[string]): Proving =
          Proving(answers: sources.mapIt(it.groupsCandidate.filterIt(it.got notin
            ["(x[0])", "(y[0])"]).mapIt(it.opening[0])))
    let unanswered = fixEntries(BRANCH_CURATOR, entries)
    check unanswered.written.len == 0  # nothing proven, nothing written
    check unanswered.asked.mapIt(it[0]) == entries.mapIt(it.path)  # each source asks
    let (fix, failures) = fixProven(BRANCH_CURATOR, tree, entries, [], initContext(tree), stub)
    check failures.len == 0
    check pins[0 .. 1] == @[PIN, COMMIT]  # first round: one run for each pin, project's own
    check fix.written.mapIt(it.content) == @[
      GROUPED.replace("@(x) +", "@x +"), other.replace("@(y) +", "@y +"),
      GROUPED.replace("@(x) +", "@x +"),
    ]  # group parser refuses stays
    check fix.fixed.filterIt("needless parentheses" in it.brief).len == 3
    check fix.asked.len == 0
    let again = fixProven(BRANCH_CURATOR, tree, fix.written, [], initContext(tree), stub)
    check again.fix.written.len == 0  # second fix writes nothing


  test "where no compiler serves pin, nothing goes, and one warning says why":
    let
      tree = treeGood().with(entry("tools/a.nim", GROUPED))
      broken = proc (pin: string): Prover =
        result = proc (sources: seq[string]): Proving =
          Proving(answers: newSeq[seq[int]](sources.len), failure: "Compiler failed; got `x`.")
    let (fix, failures) = fixProven(BRANCH_CURATOR, tree, [tree[^1]], [], initContext(tree), broken)
    check fix.written.len == 0 and fix.fixed.len == 0
    check failures.mapIt((it.rule, it.brief)) ==
      @[("needless-parentheses", "compiler failed; got `x`")]  # driver pin asked
    let unpinned = treeGood().without(DIRECTORY_AUDIT & "/audit.nimble").with(
      entry("koch2.nim", GROUPED),
    )
    let alone =
      fixProven(BRANCH_CURATOR, unpinned, [unpinned[^1]], [], initContext(unpinned), broken)
    check alone.fix.written.len == 0
    check alone.failures.mapIt(it.brief) ==
      @["parser proved no removal, since project pins no compiler; got `koch2.nim`"]


  test "nimble file whose copy `atlas.lock` holds is never written, and read by no layout check":
    let
      nimble =
        entry(DIRECTORY_ALPHA & "/alpha.nimble", "version = \"0.1.0\" \nlet a = 1+2  ## Sum.\n")
      tree = @[nimble, entry(DIRECTORY_ALPHA & "/atlas.lock", LOCK)]
    check tree.nimblesLocked == @[nimble.path]
    let plan = fixEntries(BRANCH_CONTRIBUTOR, [nimble], tree.nimblesLocked)
    check plan.written.len == 0 and plan.left.len == 1 and "atlas.lock" in plan.left[0].brief
    check checkFormatting(tree).len == 0  # silent on it
    check checkFormatting(@[nimble]).len == 1  # read where no lock holds its copy
    check fixEntries(BRANCH_CONTRIBUTOR, [nimble]).written.len == 1


  test "fix of entries that asked alone gives same fix as fix of every entry, each round":
    # Entries under two pins, some asking parser over two rounds, one asking through its fence
    #   alone, and some asking nothing.
    let
      other = GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])")
      fenced = "## Do.\n\n" & STRICT_FUNCS & "\n\n#!fix off\nlet b = @(x) + 1\n#!fix on\n"
      tree = treeGood().with(
        entry("curator/beta/beta.nimble", TEXT_NIMBLE.replace(PIN, COMMIT)),
        entry(DIRECTORY_AUDIT & "/src/a.nim", GROUPED),
        entry(DIRECTORY_AUDIT & "/src/b.nim", DIRTY),
        entry("curator/beta/src/c.nim", other & "let t = a+b\n"),
        entry("curator/beta/src/d.nim", fenced),
        entry("curator/beta/src/e.nim", "## Do.\n\n" & STRICT_FUNCS & "\n\nlet z = 1\n"),
        entry("curator/beta/README.md", "# Beta\n"),
      )
      entries = tree[^6 .. ^1]
      asking = entries.filterIt(fixEntries(BRANCH_CURATOR, [it]).asked.len > 0)
    check asking.mapIt(it.path) == @[
      DIRECTORY_AUDIT & "/src/a.nim", "curator/beta/src/c.nim", "curator/beta/src/d.nim",
    ]  # some entries ask, and some do not
    var calls = 0
    let
      stubbed = proc (sources: seq[string]): Proving =
        Proving(answers: sources.mapIt(
          it.groupsCandidate.filterIt(it.got notin ["(x[0])", "(y[0])"]).mapIt(it.opening[0]),
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
        proven = fixProven(BRANCH_CURATOR, tree, entries, [], initContext(tree), provers)
        reference = fixEvery(BRANCH_CURATOR, tree, entries, [], initContext(tree), provers)
      check proven.fix.written.mapIt((it.path, it.content)) ==
          reference.fix.written.mapIt((it.path, it.content))
      for (fast, every) in [
        (proven.fix.fixed, reference.fix.fixed),
        (proven.fix.refused, reference.fix.refused),
        (proven.fix.left, reference.fix.left),
        (proven.fix.warned, reference.fix.warned),
      ]:
        check fast.mapIt(it.render) == every.mapIt(it.render)
      check proven.fix.asked == reference.fix.asked
      check proven.failures == reference.failures
    check calls >= 4  # askers asked again in second round, under both loops
