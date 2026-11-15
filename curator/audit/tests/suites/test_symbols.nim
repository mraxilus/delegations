## Hold tree's ask of semantic pass to its contract: included file resolves through file of
##   tree including it; site resolves to symbol pin's own `nimsuggest` reads there, and file
##   that compiles nowhere is answered unresolved. Knoller's suite holds answer lines, blocks
##   and pipe capacity (`test_symbols.nim` there).

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, tables, tempfiles, unittest]
import ../../../knoller/src/knoller
import ../../src/symbols
import ./fixtures


suite "Internal: Symbols":
  test "included file resolves through file including it, followed to top":
    let tree = @[
      entry("p/tests/test_a.nim", "include \"suites.nim\"\n"),
      entry("p/tests/suites.nim", "include more\n"),
      entry("p/tests/more.nim", "let x = 1\n"),
      entry("p/src/b.nim", "let y = 2\n"),
    ]
    check tree.includer("p/tests/more.nim") == "p/tests/test_a.nim"
    check tree.includer("p/src/b.nim") == "p/src/b.nim"


  test "site resolves to symbol through nimsuggest of pin; file that fails resolves none":
    let
      root = createTempDir("delegations_", "_symbols")
      pin = compilerRunning().version
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
    var answers = initTable[string, Answer]()
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


  test "file under `tests/` of project compiles with `-d:testing`, as its stubs pass it":
    # Case held: knoller compiled each file under directory `tests` with `-d:testing`, define
    #   stubs of this repository pass (STYLE.md §6), so #886 moves it to koch, which names options
    #   of each file. Domain: name declared under define alone, under `tests/` of project, under
    #   its `src/`, and under directory `tests` outside it.
    let
      root = createTempDir("delegations_", "_defines")
      pin = compilerRunning().version
      nimble = "version = \"0.1.0\"\nrequires \"nim == " & pin & "\"\n"
      source = "when defined(testing):\n  let x = 3\nlet y = x.float\n"
      cases = [
        ("curator/fixture/tests/a.nim", true),  # stubs pass define, so `x` stands
        ("curator/fixture/tests/suites/b.nim", true),
        ("curator/fixture/src/a.nim", false),  # define reaches `tests/` of project alone
        ("curator/fixture/src/tests/c.nim", false),
      ]
    defer: removeDir(root)
    var tree = @[entry("curator/fixture/fixture.nimble", nimble)]
    for (path, _) in cases: tree.add entry(path, source)
    for e in tree: writeInto(root, e.path, e.content)
    var queries: seq[Query]
    for (path, _) in cases: queries.add Query(path: path, sites: @[(3, 10)])
    let answers = resolve(root, tree, queries)
    for (path, is_resolved) in cases:
      check answers.anyIt(it.path == path and (it.reason.len == 0) == is_resolved)
