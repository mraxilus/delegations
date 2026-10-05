## Hold semantic pass to its contract: answer lines read as symbols, one block per command;
##   included file resolves through file including it; site resolves to symbol pin's own
##   `nimsuggest` reads there, and file that compiles nowhere is answered unresolved.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, tables, tempfiles, unittest]
import ../../../knoller/src/knoller
import ../../src/[symbols, toolchain]
import ./fixtures


const
  ANSWER = "def\tskType\tsystem.float\tfloat\t/lib/system/basic_types.nim\t15\t2\t\"\"\t100"
    ## One answer line of `def`, as `nimsuggest --v3` prints it.
  OUTPUT = "usage: sug|con|def\ntype 'quit' to quit\n\n" & ANSWER & "\n\n\n"
    ## Output of three commands: empty answer, one answer, empty answer.
  USES_PIPE = 800
    ## Uses of one symbol, so answer of `dus` listing them passes 64 KiB, pipe's capacity.
  NAME_PIPE = 70_000  ## Length of name asked, so command asking it passes 64 KiB too.



suite "Internal: Symbols":
  test "answer line reads as symbol; malformed one reads as none":
    let symbol = ANSWER.symbolOf.get
    check symbol.kind == "skType" and symbol.name == "system.float"
    check symbol.file == "/lib/system/basic_types.nim" and symbol.line == 15
    check symbol.column == 2
    check "def\tskType".symbolOf.isNone


  test "output splits into one block per command, header dropped, empty answer kept":
    let blocks = OUTPUT.blocksOf
    check blocks.len == 3
    check blocks[0].len == 0 and blocks[1] == @[ANSWER] and blocks[2].len == 0


  test "names compare as Nim compares them: first character exact, rest loose":
    check isSameName("ctxFoo", "ctx_foo") and isSameName("ctx", "cTX")
    check not isSameName("Ctx", "ctx")


  test "included file resolves through file including it, followed to top":
    let tree = @[
      entry("p/tests/test_a.nim", "include \"suites.nim\"\n"),
      entry("p/tests/suites.nim", "include more\n"),
      entry("p/tests/more.nim", "let x = 1\n"),
      entry("p/src/b.nim", "let y = 2\n"),
    ]
    check tree.includerOf("p/tests/more.nim") == "p/tests/test_a.nim"
    check tree.includerOf("p/src/b.nim") == "p/src/b.nim"


  test "site resolves to symbol through nimsuggest of pin; file that fails resolves none":
    let
      root = createTempDir("delegations_", "_symbols")
      pin = runningCompiler().version
      nimble = "version = \"0.1.0\"\nsrcDir = \"src\"\nrequires \"nim == " & pin & "\"\n"
      source = "let\n  x = 3\n  y = x.float\n\nfunc twice(n: int): int = n * 2\n\necho twice(x)\n"
      tree = @[
        entry("curator/fixture/fixture.nimble", nimble),
        entry("curator/fixture/src/a.nim", source),
        entry("curator/fixture/src/b.nim", "let z = undeclared\n"),
        entry("curator/fixture/src/c.nim", "include \"d.nim\"\n"),
        entry("curator/fixture/src/d.nim", "proc show() =\n  let w = 4\n  echo w\n\nshow()\n"),
      ]
    defer: removeDir(root)
    for e in tree: writeInto(root, e.path, e.content)
    var answers = initTable[string, symbols.Answer]()  # `ANSWER` is one name with `Answer`
    for answer in resolve(
      root,
      tree,
      [
        Query(
          path: "curator/fixture/src/a.nim",
          sites: @[(3, 8), (3, 6), (5, 5), (7, 5)],
          names: @["float"],
        ),
        Query(path: "curator/fixture/src/b.nim", sites: @[(1, 8)]),
        Query(path: "curator/fixture/src/d.nim", sites: @[(3, 7), (2, 6)]),
      ],
    ):
      answers[answer.path] = answer
    check answers.len == 3
    let a = answers["curator/fixture/src/a.nim"]
    check a.reason.len == 0
    check a.symbols[(3, 8)].kind == "skType" and a.symbols[(3, 8)].name == "system.float"
    check a.symbols[(3, 6)].kind == "skLet" and a.symbols[(3, 6)].line == 2
    check a.globals["float"].len >= 1  # `system.float` among them
    # Routine's own name is routine declared there, though pass answers its implicit result.
    let (declared, used) = (a.symbols[(5, 5)], a.symbols[(7, 5)])
    check used.kind == "skFunc" and used.line == 5 and used.column == 5
    check declared.line == used.line and declared.column == used.column
    check declared.file == used.file and declared.name == used.name
    check answers["curator/fixture/src/b.nim"].reason.contains("undeclared")  # no backend
    # Site of included file resolves through its includer, as one at its entry would.
    let d = answers["curator/fixture/src/d.nim"]
    check d.reason.len == 0
    check d.symbols[(3, 7)].kind == "skLet" and d.symbols[(3, 7)].line == 2
    check d.symbols[(3, 7)] == d.symbols[(2, 6)]  # use and declaration name one symbol


  test "run asked past pipe capacity both ways answers every command, neither side waiting":
    let
      root = createTempDir("delegations_", "_symbols")
      nimble = "version = \"0.1.0\"\nsrcDir = \"src\"\nrequires \"nim == " &
        runningCompiler().version & "\"\n"
      tree = @[
        entry("curator/fixture/fixture.nimble", nimble),
        entry("curator/fixture/src/c.nim", "include \"d.nim\"\n"),
        entry("curator/fixture/src/d.nim", "let w = 1\n" & "discard w\n".repeat(USES_PIPE)),
      ]
      name = 'n'.repeat(NAME_PIPE)
    defer: removeDir(root)
    for e in tree: writeInto(root, e.path, e.content)
    let answers =
      resolve(root, tree, [Query(path: tree[2].path, sites: @[(2, 8)], names: @[name, "w"])])
    check answers.len == 1 and answers[0].reason.len == 0
    check answers[0].symbols[(2, 8)].kind == "skLet" and answers[0].symbols[(2, 8)].line == 1
    check answers[0].globals[name].len == 0  # no symbol takes long name
    check answers[0].globals["w"].len == 1  # last block, after long command, so every answer read
