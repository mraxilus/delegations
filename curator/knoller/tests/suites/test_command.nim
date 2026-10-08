## Replicate command line of `command.nim` header: what `knoller [--check] [--nim:path] path...`
##   reads, writes, prints and exits with, driven through `outcomeOf` on text alone, and through
##   `outcomeProven` with parser stubbed (`stubs.nim`).
##   Compiler of each file (`batchesOf`) is driven over real files, with real parser where it is
##   cheap: `--nim` and `nim` on `PATH`. Prover of pin is stubbed, since serving pin may fetch;
##   `test_compilers.nim` holds real prover of pin.

{.experimental: "strictFuncs".}

import std/[importutils, options, os, osproc, sequtils, sets, strutils, tables, tempfiles, unittest]
import ../../src/knoller/[command, compilers, edits, proofs, reports, rewrites, rules, symbols]
from ../../src/knoller/command {.all.} import joined, Part
import ./stubs


const
  DIRTY = "let X = a+b # c\nproc f(a: int; b: string) = discard\n"
    ## Nim source breaking spacing, comment gap and separators, and lacking `strictFuncs`.
  CLEAN = "{.experimental: \"strictFuncs\".}\n\nlet X = a + b  # c\n"  ## Nim source fix leaves.
  README = currentSourcePath().parentDir.parentDir.parentDir / "README.md"
    ## Record listing every rule id output cites.
  SUITES =
      "{.experimental: \"strictFuncs\".}\n\nimport std/unittest\n" &
      "suite \"A\":\n  test \"a\":\n    check true\n  test \"b\":\n    check true\n"
    ## Suites of test file, each run of blank lines short.
  STUB = "discard \"\"\"\naction: run\ncmd: \"nim c -r $file\"\n\"\"\"\ninclude \"suites.nim\"\n"
    ## Testament stub whose `cmd` holds `-r`.
  UMBRELLA = "{.experimental: \"strictFuncs\".}\n\nimport ./p/a\n"
    ## Library umbrella lacking profiler import.
  GROUPED = "{.experimental: \"strictFuncs\".}\n\nlet S = @(x) + @(x[0])\n"
    ## Nim source holding group parser proves needless, and group it refuses.
  NIM = getCurrentCompilerExe()  ## Compiler building suite, 2.2.12, whose parser answers.
  COMMIT = "27763495bcfe265507ca98aedc1c7064bf1e0e4d"  ## Commit pin of `ronri` projects.
  UNSERVED = "Parser proved no removal, since no compiler serves pin; got `"
    ## Opening of warning of pin no compiler serves, as `proversPin` writes it.
  UNSETTLED =
    "File still changes after 3 rounds of fixers, so fix leaves it as written; got `3` rounds."
    ## Message of file fixers do not settle, as `chain.nim` writes it.


proc writeTree(root: string, files: openArray[(string, string)]) =
  ## Write each file under root, path then text, creating its directory.
  for (path, text) in files:
    createDir((root / path).parentDir)
    writeFile(root / path, text)


proc outcomeEvery(
  files: openArray[(string, string)],
  locked: openArray[string],
  is_check: bool,
  directory: string,
  prover: Prover,
): Outcome =
  ## Fix every file again each round of asking: reference that loop of `outcomeProven`, fixing
  ##   files that asked alone, is held equal to (Article IX.2).
  var
    proofs = Proofs()
    failure = ""
  result = outcomeOf(files, locked, is_check, directory, proofs)
  for ask in 1..ASKS_MAX:
    if result.asked.len == 0: break
    if failure.len > 0:
      for source in result.asked: proofs.answers[source] = @[]
    else: failure = proofs.answered(result.asked, prover)
    result = outcomeOf(files, locked, is_check, directory, proofs, failure)


func shown(path, directory, source: string): seq[string] =
  ## Print check of one file path names from directory, path read as `<path>`.
  let outcome = outcomeOf([(path, source)], [], is_check = true, directory)
  outcome.lines.mapIt(it.replace(path, "<path>"))



suite "Command line":
  test "path is required, and option other than `--check` is usage error":
    check parseOptions(["a.nim"]).get.paths == @["a.nim"]  # path alone fixes
    check parseOptions(["--check", "a.nim", "src"]).get.is_check  # check, two paths
    check parseOptions([]).isNone  # no path
    check parseOptions(["--check"]).isNone  # option alone names no path
    check parseOptions(["--width=80", "a.nim"]).isNone  # no style option
    check parseOptions(["--check=no", "a.nim"]).isNone  # check takes no value
    check parseOptions(["a.nim"]).get.nim.len == 0  # none named: pin above each file decides
    check parseOptions(["--nim:/p/bin/nim", "a.nim"]).get.nim == "/p/bin/nim"
    check parseOptions(["--nim", "a.nim"]).isNone  # compiler option names compiler


  test "dialect follows extension, and other file has none":
    check "a.nim".dialectOf == some(Dialect.Module)
    check "a.nims".dialectOf == some(Dialect.Script)
    check "a.nimble".dialectOf == some(Dialect.Package)
    check "a.md".dialectOf.isNone and "nim.cfg".dialectOf.isNone


  test "fix writes changed file alone, and prints each rewrite by rule id, then count":
    let outcome = outcomeOf([("a.nim", DIRTY), ("b.nim", CLEAN)], [], is_check = false)
    check outcome.written.len == 1 and outcome.written[0][0] == "a.nim"  # clean file unwritten
    check outcome.lines == @[
      "a.nim: strictfuncs fixed",  # whole file: path alone
      "a.nim:1: expression-spacing fixed",
      "a.nim:1: trailing-comment fixed",
      "a.nim:2: parameter-separators fixed",
      "4 fixed.",
    ]  # sorted by path, line, then rule id
    check outcome.code == 0  # nothing left
    let again = outcomeOf([outcome.written[0]], [], is_check = false)
    check again.written.len == 0 and again.lines == @["0 fixed."]  # second run writes nothing


  test "check writes nothing, reports each change due, and exits 1 where any":
    let outcome = outcomeOf([("a.nim", DIRTY)], [], is_check = true)
    check outcome.written.len == 0
    check outcome.lines[^1] == "4 to fix."
    check outcome.lines[0] == "a.nim: strictfuncs to fix"
    check outcome.code == 1
    check outcomeOf([("b.nim", CLEAN)], [], is_check = true).code == 0  # nothing due


  test "finding fix leaves prints by rule id with its message, and exits 1":
    let
      crossing = "let A = 1+2\nvar M = f(\n  #!fix off\n  1,  0,\n)\n#!fix on\n"
      outcome = outcomeOf([("a.nims", crossing)], [], is_check = false)
    check outcome.written.len == 0  # fence it cannot read leaves file as written
    check outcome.lines[0].startsWith("a.nims:2: fence left: Fence closes outside bracket")
    check outcome.lines[^1] == "0 fixed."
    check outcome.code == 1


  test "file fixers do not settle prints by path alone with no rule, before findings, and exits 1":
    # Domain: unsettled file alone, and beside file that settles, under fix and `--check`. No
    #   source of suite leaves chain unsettled, so part stands for what `partOf` gives.
    privateAccess(Part)
    let
      alone = [Part(path: "b.nim", unsettled: UNSETTLED)]
      tab = initReport("b.nim", 2, Rule.Tab, "Line holds tab.")
      beside = [
        Part(path: "b.nim", unsettled: UNSETTLED, left: @[tab]),
        Part(path: "a.nim", fixed: @[initReport("a.nim", 1, Rule.SpacingExpression)]),
      ]
    for is_check in [false, true]:
      let outcome = if is_check: " to fix" else: " fixed"
      check alone.joined(is_check, []).lines ==
          @["b.nim: unsettled: " & UNSETTLED, "0" & outcome & "."]
      check alone.joined(is_check, []).code == 1  # unsettled file alone fails run
      check beside.joined(is_check, []).lines == @[
        "a.nim:1: expression-spacing" & outcome,
        "b.nim: unsettled: " & UNSETTLED,
        "b.nim:2: tab left: Line holds tab.",
        "1" & outcome & ".",
      ]  # after rewrites, before findings left
      check beside.joined(is_check, []).code == 1


  test "finding left prints at its line in file as given, as each rewrite does":
    let outcome = outcomeOf([("a.nim", "let A = 1\nlet B = not x == y\n")], [], is_check = true)
    check outcome.lines.len == 4
    check outcome.lines[0 .. 1] == @["a.nim: strictfuncs to fix", "a.nim:1: single-bindings to fix"]
    check outcome.lines[2].startsWith("a.nim:2: not-over-binary left: ")  # fix moves it to 5


  test "check exits 1 on each finding fixers leave, fence or none, and fence counts it":
    # Case held: `knoller --check` ran idiom checks of static pass on file holding fence alone
    #   (`chain.nim`, `heldOf` against `checkFormatting`), and checks of form, articles, entry
    #   block, names and waits never, so it exited 0 on each source below (#557); domain is each
    #   rule of knoller static pass of `curator/audit` reads that fixers can leave, as left.
    #   Rule fixers always clear (trailing whitespace, banners, `strictFuncs`, stub keys) is none.
    let module = "{.experimental: \"strictFuncs\".}\n\n"
    for (path, source, rule) in [
      ("a.nim", module & "const TEXT = \"" & "word ".repeat(24) & "\"\n", Rule.LineWidth),
      ("a.nim", module & "discard 1  # Tab\there.\n", Rule.Tab),  # tab outside string
      ("a.nim", module & "discard 1\r# Lone CR.\n", Rule.LineEnding),
      ("a.nims", "", Rule.FileEnding),  # empty file
      ("a.nim", module & "# The end.\n", Rule.ArticleInComment),  # capital article stays
      ("a.nim", module & "when isMainModule:\n  var count {.global.} = 0\n", Rule.BlockEntry),
      ("a.nim", module & "func f(): int =\n  return result\n", Rule.ReturnResult),
      ("a.nim", module & "proc getX() = discard\n", Rule.VerbAction),
      ("a.nim", module & "type Space = enum\n  base, Anti\n", Rule.CaseMember),
      ("a.nim", module & "{.push inline.}\nproc f() = discard\n{.pop.}\n", Rule.PushForeign),
      ("tests/test_a.nim", module & "include \"suites.nim\"\n", Rule.HeaderStub),
      ("tests/suites/test_a.nim", module & "echo x\n", Rule.OutputDebug),
      ("tests/suites/test_a.nim", module & "sleep(1)\n", Rule.WaitFixed),
      ("a.nim", module & "proc f(ctx: int) = discard\n", Rule.Abbreviation),
      ("a.nim", module & "proc f(quiet: bool) = discard\n", Rule.NameBoolean),
      ("a.nim", module & "const LUT_GRADE = 1\n", Rule.TableLookup),
      ("a.nim", module & "type basis_digits = int\n", Rule.CaseName),
      ("a.nim", module & "type Pair[Key, V] = object\n", Rule.LetterPlaceholder),
      ("a.nim", module & "var 𝐧 = 2\n", Rule.Notation),
      ("a.nim", module & "type Algebra = int\nconst ALGEBRA = 1\n", Rule.WordGlobal),
      ("a.nim", module & "func f() {.used.} = discard\n", Rule.ConsumerUsed),
      ("tests/suites/test_a.nim", module & "import std/random\n", Rule.SeedRandom),
      ("a.nim", module & "import ./[\n  b,  # Why.\n  a,\n]\n", Rule.ImportBracket),  # comment
      ("a.nim", module & "import ./a\n\nimport std/os\n", Rule.RankImport),  # blank line apart
      ("a.nim", module & "const A = 1\nconst B = \"\"\"\ntext\n\"\"\"\n", Rule.BindingsSingle),
    ]:
      let outcome = outcomeOf([(path, source)], [], is_check = true)
      check outcome.code == 1  # violation fails run
      check outcome.lines.anyIt(it.startsWith(path) and (" " & rule.id & " left: ") in it)
    let fenced = outcomeOf([("a.nims", "#!fix off\nlet a = 1 \n#!fix on\n")], [], is_check = true)
    check fenced.lines.anyIt("inside them trailing-whitespace breaks once at line 2" in it)
    check fenced.code == 1  # fence keeps line from fixer, never from finding


  test "check reads no glossary, so acronym in name of another repository passes":
    # Domain: acronym in camel and Pascal names, in each dialect, as library of `replications`
    #   spells them, beside use of `parseJson`. V.9 needs glossary, which belongs to repository
    #   (D2 of #572).
    let source =
        "import std/json\n\nfunc toJSON*(text: string): JsonNode = parseJson(text)\n" &
        "type GLContext* = object\n"
    for path in ["a.nim", "a.nims", "a.nimble"]:
      let
        given = if path.endsWith(".nim"): "{.experimental: \"strictFuncs\".}\n\n" & source
          else: source
        outcome = outcomeOf([(path, given)], [], is_check = true)
      check outcome.lines == @["0 to fix."] and outcome.code == 0


  test "each fence prints as warning naming what breaks inside it, and changes no exit code":
    let
      fenced = "let A = 1\n#!fix off\nlet B = 1+2\n#!fix on\n"
      outcome = outcomeOf([("a.nims", fenced)], [], is_check = true)
    check outcome.lines == @[
      "a.nims:2: fence-held warning: Fence keeps its lines as written, and inside them " &
        "expression-spacing breaks once at line 3; got lines `2` to `4`.",
      "0 to fix.",
    ]
    check outcome.code == 0  # break inside fence alone fails nothing
    let written = outcomeOf([("a.nims", fenced)], [], is_check = false)
    check written.written.len == 0 and written.code == 0  # nothing written


  test "path reads whole from directory it is named from, `.` and `..` resolved":
    check layoutOf("suites.nim", "/p/tests") == "/p/tests/suites.nim"
    check layoutOf("tests/suites.nim", "/p") == "/p/tests/suites.nim"
    check layoutOf("../tests/./a.nim", "/p/src") == "/p/tests/a.nim"
    check layoutOf("/q/a.nim", "/p") == "/q/a.nim"  # absolute path stays


  test "same file reports alike however path names it: test file, stub and umbrella":
    for (source, rule, inside, outside) in [
      (SUITES, "test-blank-lines", ("suites.nim", "/p/tests"), ("tests/suites.nim", "/p")),
      (STUB, "stub-keys", ("test_p.nim", "/p/tests"), ("p/tests/test_p.nim", "/")),
      (UMBRELLA, "profiler-import", ("p.nim", "/p/src"), ("../p/src/p.nim", "/p/tests")),
    ]:
      let lines = shown(inside[0], inside[1], source)
      check lines.anyIt(rule in it)  # rule reads path whole, from inside its directory too
      check lines == shown(outside[0], outside[1], source)


  test "directory names Nim files git lists under it, sorted; one naming none says why":
    check listingOf("src", "b.nim\0a.md\0a.nim\0", 0) == (@["src/a.nim", "src/b.nim"], "")
    let outside = listingOf("/q", "fatal: not a git repository\n", 128)
    check outside.files.len == 0
    check outside.refusal.startsWith("Directory lies outside git work tree")
    check outside.refusal.endsWith("got `/q`.")
    let bare = listingOf("docs", "a.md\0", 0)
    check bare.files.len == 0
    check bare.refusal.startsWith("Directory holds no Nim file that git lists")


  test "directory lists Nim files git writes on stdout alone, whatever it writes on stderr":
    # Case held: `listed` ran git through `execCmdEx`, which joins stderr to stdout, so text git
    #   wrote on stderr, as warning, stuck to first path (`command.nim`, #557); trace of git
    #   stands in for warning, since both reach stderr alone. Domain is any text on stderr, with
    #   exit code still deciding refusal.
    let
      root = createTempDir("knoller_", "_listed")
      outside = createTempDir("knoller_", "_outside")
    defer:
      removeDir(root)
      removeDir(outside)
    root.writeTree([("b.nim", "x\n"), ("a.nim", "x\n"), ("c.md", "x\n")])
    check execCmd("git -C " & root.quoteShell & " init -q") == 0
    check execCmd("git -C " & root.quoteShell & " add -A") == 0
    putEnv("GIT_TRACE", "1")
    defer: delEnv("GIT_TRACE")
    check root.listed == (@[root / "a.nim", root / "b.nim"], "")  # no trace glued to first
    check outside.listed.refusal.startsWith("Directory lies outside git work tree")


  test "checkout git converts to CRLF reads as LF, and fix writes CRLF back":
    # Git for Windows checks out CRLF by default (`core.autocrlf=true`), so every line of every
    #   file read as trailing whitespace there, and fix rewrote its line endings. Domain: each
    #   setting and attribute that decides whether commit turns CRLF back into LF.
    let records = [
      ("i/lf    w/crlf  attr/                 \ta.nim", "true\n", true),
      ("i/lf    w/crlf  attr/                 \ta.nim", "input", true),
      ("i/lf    w/crlf  attr/                 \ta.nim", "", false),  # commit keeps CRLF
      ("i/lf    w/crlf  attr/text=auto        \ta.nim", "", true),
      ("i/lf    w/crlf  attr/text eol=crlf    \ta.nim", "false", true),
      ("i/lf    w/crlf  attr/-text            \ta.nim", "true", false),  # binary
      ("i/crlf  w/crlf  attr/                 \ta.nim", "true", false),  # CRLF committed
      ("i/      w/crlf  attr/                 \ta.nim", "true", true),  # not added yet
      ("i/lf    w/mixed attr/                 \ta.nim", "true", true),
      ("i/lf    w/lf    attr/                 \ta.nim", "true", false),
    ]
    for (record, autocrlf, is_converted) in records:
      check record.isConverted(autocrlf) == is_converted
    check "a\r\nb\r\n".judged(true) == "a\nb\n" and "a\r\nb\r\n".judged(false) == "a\r\nb\r\n"
    check "a\nb\n".restored(true) == "a\r\nb\r\n" and "a\nb\n".restored(false) == "a\nb\n"

    # Real checkout: git converts file committed with LF, and keeps file committed with CRLF.
    let
      root = createTempDir("knoller_", "_eol")
      outside = createTempDir("knoller_", "_outside")
      git = "git -c user.name=T -c user.email=t@example.invalid -c commit.gpgsign=false -C " &
        root.quoteShell & " "
    defer:
      removeDir(root)
      removeDir(outside)
    root.writeTree([("a.nim", "let a = 1\n"), ("b.nim", "let b = 2\r\n")])
    outside.writeTree([("c.nim", "let c = 3\r\n")])
    check execCmd(git & "init -q") == 0
    check execCmd(git & "config core.autocrlf false") == 0
    check execCmd(git & "add -A") == 0
    check execCmd(git & "commit -q -m init") == 0
    check execCmd(git & "config core.autocrlf true") == 0
    removeFile(root / "a.nim")
    removeFile(root / "b.nim")
    check execCmd(git & "checkout -- .") == 0
    check readFile(root / "a.nim") == "let a = 1\r\n"  # checkout wrote CRLF
    let converted = convertedOf([root / "a.nim", root / "b.nim", outside / "c.nim"])
    check root / "a.nim" in converted
    check root / "b.nim" notin converted  # commit keeps its CRLF, so finding stays
    check outside / "c.nim" notin converted  # git knows nothing of it


  test "locked nimble file and file of no dialect are passed over":
    let outcome = outcomeOf(
      [("p/p.nimble", "version = \"0.1.0\" \n"), ("README.md", "x \n")],
      ["p/p.nimble"],
      is_check = false,
    )
    check outcome.written.len == 0 and outcome.lines == @["0 fixed."] and outcome.code == 0


  test "README lists every rule id output cites":
    let record = readFile(README)
    for rule in Rule: check ("`" & rule.id & "`") in record  # id named as code span


  test "conversion semantic pass settles is fixed first, and pass that resolves none warns":
    const source = "{.experimental: \"strictFuncs\".}\n\nfunc twice(x: int): float = x.float * 2\n"
    var answer = Answer(path: "a.nim")
    answer.symbols[(3, 30)] = Symbol(kind: "skType")
    answer.symbols[(3, 28)] = Symbol(kind: "skParam")
    let
      answers = {"a.nim": answer}.toTable
      fixed = outcomeOf([("a.nim", source)], [], is_check = false, answers = answers)
      due = outcomeOf([("a.nim", source)], [], is_check = true, answers = answers)
    check fixed.written == @[("a.nim", source.replace("x.float", "float(x)"))]
    check fixed.lines == @["a.nim:3: type-conversion fixed", "1 fixed."]
    check due.written.len == 0 and due.code == 1
    check due.lines == @["a.nim:3: type-conversion to fix", "1 to fix."]
    let unread = outcomeOf(
      [("a.nim", source)],
      [],
      is_check = true,
      answers = {"a.nim": Answer(path: "a.nim", reason: "no compiler serves pin 0.0.1")}.toTable,
    )
    check unread.lines == @[
      "a.nim: type-conversion warning: Semantic pass resolved no name, so each type " &
        "conversion stays as written; got `no compiler serves pin 0.0.1`.",
      "0 to fix.",
    ]
    check unread.code == 0  # warning changes no exit code


  test "file holding conversion candidate is resolved in its project, and none other is asked":
    let root = createTempDir("knoller_", "_answers")
    defer: removeDir(root)
    root.writeTree([
      ("p/p.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
      ("p/src/a.nim", "let\n  x = 3\n  y = x.float\n"),
      ("p/src/b.nim", "let z = 1\n"),
    ])
    check execCmd("git -C " & root.quoteShell & " init -q") == 0
    check execCmd("git -C " & root.quoteShell & " add -A") == 0
    var toolchains = initToolchains()
    let
      files = [("p/src/a.nim", readFile(root / "p/src/a.nim")),
               ("p/src/b.nim", readFile(root / "p/src/b.nim"))]
      answers = files.answersOf("", root, toolchains)
    check answers.len == 1  # `b.nim` holds no candidate
    check answers["p/src/a.nim"].reason.len == 0
    check answers["p/src/a.nim"].symbols[(3, 8)].kind == "skType"
    let outcome = outcomeOf(files, [], is_check = true, directory = root, answers = answers)
    check "p/src/a.nim:3: type-conversion to fix" in outcome.lines


  test "rename planned is written first, and rename refused warns where it is declared":
    const source = "{.experimental: \"strictFuncs\".}\n\nfunc twice(Count: int): int = Count * 2\n"
    let
      rename = Rename(
        path: "a.nim", line: 3, column: 11, name: "Count", renamed: "count", rule: Rule.CaseName
      )
      planned = Plan(
        rename: rename,
        edits: {"a.nim": @[Edit(first: 44, after: 49, text: "count"),
                           Edit(first: 63, after: 68, text: "count")]}.toTable,
        lines: @[("a.nim", 3), ("a.nim", 3)],
      )
      fixed = outcomeOf([("a.nim", source)], [], is_check = false, plans = [planned])
      refused = outcomeOf(
        [("a.nim", source)],
        [],
        is_check = true,
        plans = [Plan(rename: rename, refusal: "declaring file does not compile on its pin")],
      )
    check fixed.written == @[("a.nim", source.replace("Count", "count"))]
    check fixed.lines == @["a.nim:3: name-case fixed", "a.nim:3: name-case fixed", "2 fixed."]
    check refused.lines[^2] == "a.nim:3: name-case warning: Rename to `count` stays for hand, " &
      "since it is refused: declaring file does not compile on its pin; got `Count`."
    check refused.lines.anyIt(it.startsWith("a.nim:3: name-case left:"))  # check still reports
    check refused.code == 1


  test "rename reads project of declaring file, and writes only files named (D2 a of #558)":
    let root = createTempDir("knoller_", "_plans")
    defer: removeDir(root)
    root.writeTree([
      ("p/p.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
      ("p/src/a.nim", "func Count_up*(n: int): int = n + 1\n"),
      ("p/src/b.nim", "import ./a\necho Count_up(1)\n"),
    ])
    check execCmd("git -C " & root.quoteShell & " init -q") == 0
    check execCmd("git -C " & root.quoteShell & " add -A") == 0
    var toolchains = initToolchains()
    let
      a = ("p/src/a.nim", readFile(root / "p/src/a.nim"))
      b = ("p/src/b.nim", readFile(root / "p/src/b.nim"))
      alone = [a].plansOf([], "", root, toolchains)
      both = [a, b].plansOf([], "", root, toolchains)
    check alone.len == 1
    check alone[0].refusal == "it would write `src/b.nim`, which this run leaves alone"
    check both.len == 1 and both[0].refusal.len == 0
    let outcome = outcomeOf([a, b], [], is_check = false, directory = root, plans = both)
    check outcome.written.mapIt(it[0]) == @["p/src/a.nim", "p/src/b.nim"]
    check outcome.written.allIt("countUp" in it[1] and "Count_up" notin it[1])


  test "parentheses go where parser proves it, after one more run, and second run writes none":
    let unanswered = outcomeOf([("a.nim", GROUPED)], [], is_check = false)
    check unanswered.written.len == 0 and unanswered.asked == @[GROUPED]  # waits for parser
    let outcome = outcomeProven([("a.nim", GROUPED)], [], false, "/", proverStub)
    check outcome.written == @[("a.nim", GROUPED.replace("@(x) +", "@x +"))]
    check outcome.lines == @["a.nim:3: needless-parentheses fixed", "1 fixed."]
    check outcome.asked.len == 0 and outcome.code == 0
    let again = outcomeProven(outcome.written, [], false, "/", proverStub)
    check again.written.len == 0 and again.lines == @["0 fixed."]  # second run writes nothing


  test "where no compiler answers, nothing goes, one warning says why, and exit code holds":
    for prover in [proverFailing, proverCompiler("/nonexistent/nim")]:
      let outcome = outcomeProven([("a.nim", GROUPED), ("b.nim", CLEAN)], [], true, "/", prover)
      check outcome.written.len == 0 and outcome.code == 0  # nothing due, nothing left
      check outcome.lines.len == 2 and outcome.lines[^1] == "0 to fix."
      check outcome.lines[0].startsWith("needless-parentheses warning: ")  # one line, before count
    let dirty =
      outcomeProven([("a.nim", DIRTY & "let S = @(x) + 1\n")], [], true, "/", proverFailing)
    check dirty.code == 1 and dirty.lines[^1] == "4 to fix."  # other rules still due
    check dirty.lines[^2] == "needless-parentheses warning: Compiler ran no probe; got `x`."


  test "compiler `--nim` names proves every file, whatever pin nimble file above names":
    let root = createTempDir("knoller_", "_named")
    defer: removeDir(root)
    root.writeTree([("p/p.nimble", "requires \"nim == 0.0.1\"\n"), ("p/a.nim", GROUPED)])
    var pins: seq[string]
    let provers = proc (pin: string): Prover =
      pins.add pin
      proverFailure("Prover of pin ran; got `" & pin & "`.")
    let batches = batchesOf(["p/a.nim"], NIM, root, provers)
    check batches.mapIt(it.paths) == @[@["p/a.nim"]]
    let outcome = outcomeProven([("p/a.nim", GROUPED)], [], false, root, batches)
    check pins.len == 0  # pin is never resolved, so never fetched
    check outcome.written == @[("p/a.nim", GROUPED.replace("@(x) +", "@x +"))]  # real parser
    check outcome.lines == @["p/a.nim:3: needless-parentheses fixed", "1 fixed."]


  test "pin of nearest nimble file wins over `nim` on PATH, and each pin takes prover of its own":
    let root = createTempDir("knoller_", "_pins")
    defer: removeDir(root)
    let
      paths = ["p/src/a.nim", "q/b.nim", "p/src/deep/c.nim", "r/d.nim"]
      sources = ["a", "b", "c", "d"].mapIt(GROUPED.replace("@(x) + @(x[0])", "@(" & it & ") + 1"))
      nimbles = [
        ("p/p.nimble", "requires \"nim == 9.9.1\"\n"),
        ("q/q.nimble", "requires \"nim#" & COMMIT & "\"\n"),
      ]
    root.writeTree(@nimbles & zip(paths, sources))
    var asked: seq[(string, seq[string])]
    let provers = proc (pin: string): Prover =
      result = proc (sources: seq[string]): Proving =
        asked.add (pin, sources)
        proverStub(sources)
    let batches = batchesOf(paths, "", root, provers)
    check batches.mapIt(it.paths) ==
        @[@["p/src/a.nim", "p/src/deep/c.nim"], @["q/b.nim"], @["r/d.nim"]]  # nearest decides
    let outcome = outcomeProven(zip(paths, sources), [], true, root, batches)
    check asked.mapIt(it[0]) == @["9.9.1", COMMIT]  # one run for each pin, `nim#` read too
    check asked[0][1].allIt("@(a)" in it or "@(c)" in it)  # pin's own files alone
    check asked[1][1].allIt("@(b)" in it)
    check outcome.lines == @[
      "p/src/a.nim:3: needless-parentheses to fix",
      "p/src/deep/c.nim:3: needless-parentheses to fix",
      "q/b.nim:3: needless-parentheses to fix",
      "r/d.nim:3: needless-parentheses to fix",  # no nimble above: parser of `nim` on PATH
      "4 to fix.",
    ]


  test "pin no compiler serves warns once, naming pin, and removes nothing in its files":
    let root = createTempDir("knoller_", "_unserved")
    defer: removeDir(root)
    let
      paths = ["p/a.nim", "p/b.nim"]
      sources = [GROUPED, GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])")]
    root.writeTree(@[("p/p.nimble", "requires \"nim == 0.0.1\"\n")] & zip(paths, sources))
    let
      provers = proc (pin: string): Prover = proverFailure(UNSERVED & pin & "`.")
      outcome =
        outcomeProven(zip(paths, sources), [], true, root, batchesOf(paths, "", root, provers))
    check outcome.written.len == 0 and outcome.code == 0  # exit code holds
    check outcome.lines == @["needless-parentheses warning: " & UNSERVED & "0.0.1`.", "0 to fix."]


  test "directory holding two nimble files trusts no pin: one warning, and nothing goes":
    let root = createTempDir("knoller_", "_twice")
    defer: removeDir(root)
    let
      paths = ["p/a.nim", "p/sub/b.nim"]
      sources = [GROUPED, GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])")]
      nimbles = [
        ("p/a.nimble", "requires \"nim == 2.2.4\"\n"),
        ("p/b.nimble", "requires \"nim == 2.2.6\"\n"),
      ]
    root.writeTree(@nimbles & zip(paths, sources))
    var pins: seq[string]
    let provers = proc (pin: string): Prover =
      pins.add pin
      proverFailure("Prover of pin ran; got `" & pin & "`.")
    let outcome =
      outcomeProven(zip(paths, sources), [], true, root, batchesOf(paths, "", root, provers))
    check pins.len == 0  # neither pin is trusted, as nimble refuses such directory
    check outcome.written.len == 0 and outcome.code == 0
    check outcome.lines == @[
      "needless-parentheses warning: Parser proved no removal, since directory holds several " &
      "nimble files, so no pin is trusted; got `" & root / "p" & "`.",
      "0 to fix.",
    ]


  test "nimble file of no exact pin, and file with no nimble file above, take `nim` on PATH":
    let root = createTempDir("knoller_", "_path")
    defer: removeDir(root)
    let
      paths = ["p/a.nim", "r/b.nim"]
      sources = [GROUPED, GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])")]
    root.writeTree(@[("p/p.nimble", "requires \"nim >= 2.0\"\n")] & zip(paths, sources))
    var pins: seq[string]
    let provers = proc (pin: string): Prover =
      pins.add pin
      proverFailure("Prover of pin ran; got `" & pin & "`.")
    let batches = batchesOf(paths, "", root, provers)
    check batches.mapIt(it.paths) == @[@paths]  # one batch: `nim` on PATH
    let outcome = outcomeProven(zip(paths, sources), [], true, root, batches)
    check pins.len == 0  # range names no pin
    check outcome.lines == @[
      "p/a.nim:3: needless-parentheses to fix",
      "r/b.nim:3: needless-parentheses to fix",
      "2 to fix.",
    ]  # real parser proves `@(x)` and `@(y)`, and keeps `@(x[0])` and `@(y[0])`


  test "fix of files that asked alone gives same outcome as fix of every file, each round":
    # Several files, some asking parser over two rounds, one asking through its fence alone,
    #   and some asking nothing.
    let
      files = [
        ("a.nim", GROUPED),
        ("b.nim", CLEAN),
        ("c.nim", DIRTY),
        ("d.nims", "let a = 1\n#!fix off\nlet b = @(x) + 1\n#!fix on\n"),
        ("e.nim", GROUPED.replace("@(x) + @(x[0])", "@(y) + @(y[0])") & "let t = a+b\n"),
        ("p/p.nimble", "version = \"0.1.0\" \n"),
        ("README.md", "x \n"),
      ]
      asking = files.filterIt(outcomeOf([it], ["p/p.nimble"], is_check = true).asked.len > 0)
    check asking.mapIt(it[0]) == @["a.nim", "d.nims", "e.nim"]  # some files ask, some do not
    for is_check in [false, true]:
      var calls = 0
      let
        counted = proc (sources: seq[string]): Proving =
          inc calls
          proverStub(sources)
        failing_later = proc (): Prover =
          var count = 0
          result = proc (sources: seq[string]): Proving =
            inc count
            if count == 1: proverStub(sources) else: proverFailing(sources)
      let pairs: array[3, (Prover, Prover)] = [
        (counted, counted),
        (proverFailing, proverFailing),
        (failing_later(), failing_later()),
      ]
      for (fast, every) in pairs:
        let
          proven = outcomeProven(files, ["p/p.nimble"], is_check, "/", fast)
          reference = outcomeEvery(files, ["p/p.nimble"], is_check, "/", every)
        check proven.written == reference.written
        check proven.lines == reference.lines
        check proven.code == reference.code
        check proven.asked == reference.asked
      check calls >= 4  # askers asked again in second round, under both runs
