## Hold semantic pass to its contract: answer lines read as symbols, one block per command;
##   included file resolves through file including it; site resolves to symbol pin's own
##   `nimsuggest` reads there, and file that compiles nowhere is answered unresolved.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, tables, tempfiles, unittest]
import ../../src/[symbols, toolchain]
import ./fixtures


const
  ANSWER = "def\tskType\tsystem.float\tfloat\t/lib/system/basic_types.nim\t15\t2\t\"\"\t100"
    ## One answer line of `def`, as `nimsuggest --v3` prints it.
  OUTPUT = "usage: sug|con|def\ntype 'quit' to quit\n\n" & ANSWER & "\n\n\n"
    ## Output of three commands: empty answer, one answer, empty answer.



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
      source = "let\n  x = 3\n  y = x.float\n"
      tree = @[
        entry("curator/fixture/fixture.nimble", nimble),
        entry("curator/fixture/src/a.nim", source),
        entry("curator/fixture/src/b.nim", "let z = undeclared\n"),
      ]
    defer: removeDir(root)
    for e in tree: writeInto(root, e.path, e.content)
    let answers = resolve(
      root,
      tree,
      [
        Query(path: "curator/fixture/src/a.nim", sites: @[(3, 8), (3, 6)], names: @["float"]),
        Query(path: "curator/fixture/src/b.nim", sites: @[(1, 8)]),
      ],
    )
    check answers.len == 2
    let a = answers[0]
    check a.reason.len == 0
    check a.symbols[(3, 8)].kind == "skType" and a.symbols[(3, 8)].name == "system.float"
    check a.symbols[(3, 6)].kind == "skLet" and a.symbols[(3, 6)].line == 2
    check a.globals["float"].len >= 1  # `system.float` among them
    check answers[1].reason.contains("undeclared")  # compiles on no backend
