## Hold semantic pass to its contract: answer lines read as symbols, one block per command;
##   included file resolves through file including it; site resolves to symbol that
##   `nimsuggest` of toolchain reads there, and file that compiles nowhere is answered
##   unresolved. `nimsuggest` is real here: one beside compiler building this suite.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, tables, tempfiles, unittest]
import ../../src/knoller/[symbols, workers]


const
  LINE_ANSWER = "def\tskType\tsystem.float\tfloat\t/lib/system/basic_types.nim\t15\t2\t\"\"\t100"
    ## One answer line of `def`, as `nimsuggest --v3` prints it.
  OUTPUT = "!EOF!\n!EOF!\n" & LINE_ANSWER & "\n!EOF!\n!EOF!\n"
    ## Output of three commands in tester mode: empty answer, one answer, empty answer.
  USES_PIPE = 800
    ## Uses of one symbol, so answer of `dus` listing them passes 64 KiB, pipe's capacity.
  NAME_PIPE = 70_000  ## Length of name asked, so command asking it passes 64 KiB too.


type Checking = object  ## Define one check worker runs: text, and directory it checks in.
  text: string  ## Text compiler reads from stdin.
  directory: string  ## Absolute directory check runs in.


proc writeInto(root, path, content: string) =
  ## Write content at path under root, creating directories it needs.
  createDir((root / path).parentDir)
  writeFile(root / path, content)


proc cleaned(job: Checking): bool =
  ## Answer whether compiler building suite checks text clean, so worker runs check.
  checked(job.text, job.directory, getCurrentCompilerExe(), []).is_clean


suite "Internal: Symbols":
  test "answer line reads as symbol; malformed one reads as none":
    let symbol = LINE_ANSWER.toSymbol.get
    check symbol.kind == "skType" and symbol.name == "system.float"
    check symbol.file == "/lib/system/basic_types.nim" and symbol.line == 15
    check symbol.column == 2
    check "def\tskType".toSymbol.isNone


  test "output splits into one block per command, mark to mark, empty answer kept":
    let blocks = OUTPUT.blocksAnswer
    check blocks.len == 3
    check blocks[0].len == 0 and blocks[1] == @[LINE_ANSWER] and blocks[2].len == 0
    check OUTPUT.replace("\n", "\r\n").blocksAnswer == blocks  # Windows ends lines in CRLF
    check "!EOF!\n".blocksAnswer.len == 0  # ready, and asked nothing
    check ("!EOF!\n" & LINE_ANSWER & "\n").blocksAnswer.len == 0  # answer cut short reads as none


  test "run reads commands and writes answers through sh on POSIX and through cmd on Windows":
    check lineRedirected("/t/nimsuggest", ["--v3", "/r/a b.nim"], "/tmp/c", "/tmp/a") ==
      "/t/nimsuggest --v3 '/r/a b.nim' < /tmp/c > /tmp/a"
    check lineRedirected(
      "\\nim\\bin\\nimsuggest.exe",
      ["--v3", "\\r\\a b.nim"],
      "\\T\\c",
      "\\T\\a",
      cmd = "\\Windows\\system32\\cmd.exe",
    ) == "\"\\Windows\\system32\\cmd.exe\" /d /v:off /s /c " &
      "\"\"\\nim\\bin\\nimsuggest.exe\" \"--v3\" \"\\r\\a b.nim\" " &
      "< \"\\T\\c\" > \"\\T\\a\"\""


  test "check reads text and writes output and errors to one file, through either shell":
    check lineRedirected("/t/nim", ["check", "-"], "/tmp/t", "/tmp/o", is_merged = true) ==
      "/t/nim check - < /tmp/t > /tmp/o 2>&1"
    check lineRedirected(
      "\\nim\\bin\\nim.exe",
      ["check", "-"],
      "\\T\\t",
      "\\T\\o",
      cmd = "\\Windows\\system32\\cmd.exe",
      is_merged = true,
    ) == "\"\\Windows\\system32\\cmd.exe\" /d /v:off /s /c " &
      "\"\"\\nim\\bin\\nim.exe\" \"check\" \"-\" < \"\\T\\t\" > \"\\T\\o\" 2>&1\""


  test "path reads with separator `/` on Windows, and `\\` stays name character on POSIX":
    check slashed("\\r\\tests\\a\\t1.nim", '\\') == "/r/tests/a/t1.nim"  # joined on Windows
    check slashed("/r/tests/a\\b.nim", '/') == "/r/tests/a\\b.nim"
    check slashed("/r/x.nim") == "/r/x.nim"


  test "included file resolves through file including it, followed to top":
    let files = @[
      ("tests/test_a.nim", "include \"suites.nim\"\n"),
      ("tests/suites.nim", "include more\n"),
      ("tests/more.nim", "let x = 1\n"),
      ("src/b.nim", "let y = 2\n"),
    ]
    check files.includer("tests/more.nim") == "tests/test_a.nim"
    check files.includer("src/b.nim") == "src/b.nim"


  test "site resolves to symbol through nimsuggest of toolchain; file that fails resolves none":
    let
      root = createTempDir("knoller_", "_symbols")
      files = @[
        ("fixture.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
        ("src/a.nim", "let\n  x = 3\n  y = x.float\n"),
        ("src/b.nim", "let z = undeclared\n"),
        ("src/c.nim", "include \"d.nim\"\n"),
        ("src/d.nim", "proc show() =\n  let w = 4\n  echo w\n\nshow()\n"),
      ]
    defer: removeDir(root)
    for (path, content) in files: writeInto(root, path, content)
    var answers = initTable[string, Answer]()
    for (path, sites) in [
      ("src/a.nim", @[(3, 8), (3, 6)]), ("src/b.nim", @[(1, 8)]), ("src/d.nim", @[(3, 7)])
    ]:
      let request = Request(
        query: Query(path: path, sites: sites),
        root: root,
        directory: root,
        includer: files.includer(path),
      )
      for answer in resolve([request]): answers[answer.path] = answer
    check answers.len == 3
    let a = answers["src/a.nim"]
    check a.reason.len == 0
    check a.symbols[(3, 8)].kind == "skType" and a.symbols[(3, 8)].name == "system.float"
    check a.symbols[(3, 6)].kind == "skLet" and a.symbols[(3, 6)].line == 2
    check answers["src/b.nim"].reason.contains("undeclared")  # no backend compiles it
    let d = answers["src/d.nim"]  # through its includer, `c.nim`
    check d.reason.len == 0 and d.symbols[(3, 7)].kind == "skLet"


  test "compile of file takes each define its request names, and none of its own":
    # Case held: pass compiled each file under directory `tests` with `-d:testing`, define stubs
    #   of one repository pass (#886). Domain: name declared under define alone, under `tests`
    #   and outside, with define named and without.
    let
      root = createTempDir("knoller_", "_symbols")
      source = "when defined(testing):\n  let x = 3\nlet y = x.float\n"
      cases = [
        ("tests/a.nim", newSeq[string](), false),  # none of its own under `tests`
        ("src/a.nim", newSeq[string](), false),
        ("tests/b.nim", @["-d:testing"], true),
        ("src/b.nim", @["-d:testing"], true),  # define request names, at any path
      ]
    defer: removeDir(root)
    writeInto(root, "fixture.nimble", "version = \"0.1.0\"\n")
    for (path, _, _) in cases: writeInto(root, path, source)
    var requests: seq[Request]
    for (path, defines, _) in cases:
      requests.add Request(
        query: Query(path: path, sites: @[(3, 10)]),
        root: root,
        directory: root,
        includer: path,
        defines: defines,
      )
    let answers = resolve(requests)
    for (path, _, is_resolved) in cases:
      check answers.anyIt(it.path == path and (it.reason.len == 0) == is_resolved)


  test "requests of one includer share one run, with options of first of them":
    # Includer compiles once for every file it includes, so options of one request stand for
    #   all, those of first (`resolve`). Domain: first names define, and second, after it, none.
    let
      root = createTempDir("knoller_", "_symbols")
      files = @[
        ("fixture.nimble", "version = \"0.1.0\"\n"),
        ("src/c.nim", "include \"d.nim\"\n"),
        ("src/d.nim", "when defined(testing):\n  let x = 3\nlet y = x.float\n"),
      ]
    defer: removeDir(root)
    for (path, content) in files: writeInto(root, path, content)
    let answers = resolve([
      Request(
        query: Query(path: "src/d.nim", sites: @[(3, 10)]),
        root: root,
        directory: root,
        includer: "src/c.nim",
        defines: @["-d:testing"],
      ),
      Request(query: Query(path: "src/c.nim"), root: root, directory: root, includer: "src/c.nim"),
    ])
    check answers.len == 2  # one run answers both
    check answers.anyIt(it.path == "src/d.nim" and it.reason.len == 0)  # define of first stands
    check answers.anyIt(it.path == "src/c.nim" and it.reason.len == 0)


  test "toolchain with no nimsuggest leaves each file unresolved, and says so":
    # Case as found: PATH held `nim` and no `nimsuggest`, and two conversions of
    #   `pga/multivectors.nim:75` of PGA library (`749fecf`) stayed unfixed with no warning,
    #   since empty output read as one clean answer.
    let
      root = createTempDir("knoller_", "_symbols")
      bare = createTempDir("knoller_", "_bin")  # toolchain directory holding no `nimsuggest`
      files = @[
        ("fixture.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
        ("src/a.nim", "let\n  x = 3\n  y = x.float\n"),
      ]
    defer: removeDir(root)
    defer: removeDir(bare)
    for (path, content) in files: writeInto(root, path, content)
    let answers = resolve([Request(
      query: Query(path: "src/a.nim", sites: @[(3, 8)]),
      root: root,
      directory: root,
      includer: "src/a.nim",
      bin: bare,
    )])
    check answers.len == 1 and answers[0].symbols.len == 0
    check answers[0].reason.contains("nimsuggest")  # warning names tool missing

    # Domain: output holding no answer reads as none, whatever header stands before it.
    check "".blocksAnswer.len == 0
    check "usage: sug|con|def\ntype 'quit' to quit\n".blocksAnswer.len == 0


  test "project path holding colon resolves, as Windows drive does":
    # Case found by survey of suites for Windows: each command names file unquoted, and
    #   `nimsuggest` reads file up to first `:`, so drive `C:` of every path there split each
    #   command. Directory name holds colon here, where POSIX allows it.
    let
      root = createTempDir("knoller_", when defined(windows): "_symbols" else: "_drive:c")
      files = @[
        ("fixture.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
        ("src/a.nim", "let\n  x = 3\n  y = x.float\n"),
      ]
    defer: removeDir(root)
    for (path, content) in files: writeInto(root, path, content)
    check ':' in root
    let answers = resolve([Request(
      query: Query(path: "src/a.nim", sites: @[(3, 8)]),
      root: root,
      directory: root,
      includer: "src/a.nim",
    )])
    check answers.len == 1 and answers[0].reason.len == 0
    check answers[0].symbols[(3, 8)].name == "system.float"


  test "run asked past pipe capacity both ways answers every command, neither side waiting":
    let
      root = createTempDir("knoller_", "_symbols")
      files = @[
        ("fixture.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
        ("src/c.nim", "include \"d.nim\"\n"),
        ("src/d.nim", "let w = 1\n" & "discard w\n".repeat(USES_PIPE)),
      ]
      name = 'n'.repeat(NAME_PIPE)
    defer: removeDir(root)
    for (path, content) in files: writeInto(root, path, content)
    let answers = resolve([Request(
      query: Query(path: "src/d.nim", sites: @[(2, 8)], names: @[name, "w"]),
      root: root,
      directory: root,
      includer: files.includer("src/d.nim"),
    )])
    check answers.len == 1 and answers[0].reason.len == 0
    check answers[0].symbols[(2, 8)].kind == "skLet" and answers[0].symbols[(2, 8)].line == 1
    check answers[0].globals[name].len == 0  # no symbol takes long name
    check answers[0].globals["w"].len == 1  # last block, after long command, so every answer read


  test "checks on several workers at once each end, with answer check alone gives":
    # Case held: `nim check` read its text through pipe, and child another worker started meanwhile
    #   kept copy of its write end, so compiler waited on end of text for ever (#1001). Domain:
    #   clean text and text holding error, on more jobs than workers.
    let directory = createTempDir("knoller_", "_checks")
    defer: removeDir(directory)
    let jobs = toSeq(1 .. 8).mapIt(Checking(
      text: if it mod 2 == 0: "let a = " & $it & "\n" else: "let a: int = \"x\"\n",
      directory: directory,
    ))
    check jobs.mapParallel(cleaned, workers = 4) == toSeq(1 .. 8).mapIt(it mod 2 == 0)


  test "compiler that does not start leaves check unclean, and says so":
    let directory = createTempDir("knoller_", "_checks")
    defer: removeDir(directory)
    let answer = checked("let a = 1\n", directory, directory / "nim-absent", [])
    check not answer.is_clean and answer.reason.startsWith("compiler did not run: ")
