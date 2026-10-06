## Hold semantic pass to its contract: answer lines read as symbols, one block per command;
##   included file resolves through file including it; site resolves to symbol that
##   `nimsuggest` of toolchain reads there, and file that compiles nowhere is answered
##   unresolved. `nimsuggest` is real here: one beside compiler building this suite.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, tables, tempfiles, unittest]
import ../../src/knoller/symbols


const
  LINE_ANSWER = "def\tskType\tsystem.float\tfloat\t/lib/system/basic_types.nim\t15\t2\t\"\"\t100"
    ## One answer line of `def`, as `nimsuggest --v3` prints it.
  OUTPUT = "usage: sug|con|def\ntype 'quit' to quit\n\n" & LINE_ANSWER & "\n\n\n"
    ## Output of three commands: empty answer, one answer, empty answer.


proc writeInto(root, path, content: string) =
  ## Write content at path under root, creating directories it needs.
  createDir((root / path).parentDir)
  writeFile(root / path, content)


suite "Internal: Symbols":
  test "answer line reads as symbol; malformed one reads as none":
    let symbol = LINE_ANSWER.symbolOf.get
    check symbol.kind == "skType" and symbol.name == "system.float"
    check symbol.file == "/lib/system/basic_types.nim" and symbol.line == 15
    check symbol.column == 2
    check "def\tskType".symbolOf.isNone


  test "output splits into one block per command, header dropped, empty answer kept":
    let blocks = OUTPUT.blocksOf
    check blocks.len == 3
    check blocks[0].len == 0 and blocks[1] == @[LINE_ANSWER] and blocks[2].len == 0


  test "included file resolves through file including it, followed to top":
    let files = @[
      ("tests/test_a.nim", "include \"suites.nim\"\n"),
      ("tests/suites.nim", "include more\n"),
      ("tests/more.nim", "let x = 1\n"),
      ("src/b.nim", "let y = 2\n"),
    ]
    check files.includerOf("tests/more.nim") == "tests/test_a.nim"
    check files.includerOf("src/b.nim") == "src/b.nim"


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
        includer: files.includerOf(path),
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
