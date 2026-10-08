## Hold blank lines beside suites, tests and nested helpers (X.2, STYLE.md §1): each run of
##   other count is reported and fixed; fixture string, alias and side leaving owner are never
##   read; fix changes nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[blanks, reports]


const PATH_TEST = "curator/audit/tests/suites/test_a.nim"
  ## Path under `tests/`, where suite and test rules hold.


func fixed(source: string, path = PATH_TEST): string =
  ## Fix blank lines of source, as `koch fix` does.
  fixBlanks(path, source).source


func isSettled(source: string, path = PATH_TEST): bool =
  ## Decide whether source reports no blank-line finding and fixes to itself again.
  checkBlanks(path, source).len == 0 and fixBlanks(path, source).source == source and
    fixBlanks(path, source).fixed.len == 0



suite "Blanks":
  test "suite takes three blank lines before it, test two, first child none":
    let breach = "import std/unittest\n\nsuite \"A\":\n  test \"a\":\n    check true\n\n" &
      "  test \"b\":\n    check true\n\nsuite \"B\":\n\n  test \"c\":\n    check true\n"
    check checkBlanks(PATH_TEST, breach).mapIt(it.message.split(";")[0]) == @[
      "Suite takes three blank lines before it", "Test takes two blank lines before it",
      "Suite takes three blank lines before it", "First child follows its opener at once",
    ]
    check breach.fixed == "import std/unittest\n\n\n\nsuite \"A\":\n  test \"a\":\n" &
      "    check true\n\n\n  test \"b\":\n    check true\n\n\n\nsuite \"B\":\n  test \"c\":\n" &
      "    check true\n"
    check breach.fixed.isSettled
    check checkBlanks("curator/audit/src/a.nim", breach).len == 0  # tests alone


  test "test file lies under `tests`; stub is its child `test_*`, or file of category with header":
    # Category is directory under `tests`, and its file `t*.nim` at any depth is stub where
    #   source opens with testament header, as testament reads it (#443); so each path reads
    #   beside source with header and without.
    let
      headed = "discard \"\"\"\naction: run\n\"\"\"\ninclude \"suites.nim\"\n"
      bare = "include \"suites.nim\"\n"
    for (path, is_file_test, is_stub_headed, is_stub_bare) in [
      ("tests/test_a.nim", true, true, true),  # header or not
      ("/p/tests/test_a.nim", true, true, true),  # absolute, as command line reads it
      ("tests/suites/test_a.nim", true, true, false),  # suite module, where no header opens it
      ("tests/rga3d/test_rga3d.nim", true, true, false),  # one level down, as PGA library keeps it
      ("tests/rga3d/deep/test_rga3d.nim", true, true, false),  # two levels down
      ("tests/rga3d/tall.nim", true, true, false),  # `t*`, as testament reads category
      ("tests/rga3d/rga3d.nim", true, false, false),  # name opens no `t`
      ("tests/rga3d/test_rga3d.nims", true, false, false),  # script
      ("tests/tall.nim", true, false, false),  # child of `tests` is stub as `test_*` alone
      ("tests/suites.nim", true, false, false),
      ("src/tests.nim", false, false, false),
      ("src/rga3d/test_rga3d.nim", false, false, false),
      ("tests", false, false, false),  # file named `tests`
      ("test_a.nim", false, false, false),
    ]:
      check path.isFileTest == is_file_test
      check path.isStub(headed) == is_stub_headed
      check path.isStub(bare) == is_stub_bare


  test "suite opening `when` body follows it at once; suite after banner takes banner's one":
    let breach = "x\n\n\n\n#[ Native ]#\n\n\nsuite \"A\":\n  test \"a\":\n    discard\n\n\n\n" &
      "when defined(js):\n\n  suite \"B\":\n    test \"b\":\n      discard\n"
    check breach.fixed == breach.replace("]#\n\n\nsuite", "]#\n\nsuite")
      .replace("(js):\n\n  suite", "(js):\n  suite")
    check breach.fixed.isSettled


  test "run goes above comment on line before; fixture string and doc never move":
    check "x\n# Why.\nsuite \"A\":\n  discard\n".fixed ==
      "x\n\n\n\n# Why.\nsuite \"A\":\n  discard\n"
    for kept in [
      "const F = \"\"\"\nsuite \"A\":\n\ntest \"b\":\n\"\"\"\n",
      "suite \"A\":\n  ## Doc.\n  test \"a\":\n    discard\n",
    ]:
      check kept.isSettled


  test "nested helper of several lines takes one blank line on each side, after owner's doc too":
    let body = "proc f() =\n  proc g() =\n    discard\n\n\n  g()\n\nproc h() = discard\n"
    check body.fixed("a.nim") ==
      "proc f() =\n\n  proc g() =\n    discard\n\n  g()\n\nproc h() = discard\n"
    let wrapped = "proc f() =\n  ## Doc.\n  proc g(\n    a: int,\n  ): int =\n    a\n" &
      "  discard g(1)\n"
    check wrapped.fixed("a.nim") == "proc f() =\n  ## Doc.\n\n  proc g(\n    a: int,\n" &
      "  ): int =\n    a\n\n  discard g(1)\n"
    for settled in [body.fixed("a.nim"), wrapped.fixed("a.nim")]:
      check settled.isSettled("a.nim")


  test "one-line routines stack after owner's head, its doc or each other; stage after takes one":
    let borrows = "# Borrow functions for performing basic operations on grades.\n" &
      "template borrowGradeOperations(T: typedesc) =\n  func `-`*(g, h: T): T {.borrow.}\n" &
      "  func `*`*(g, h: T): T {.borrow.}\n  func `+`*(g, h: T): T {.borrow.}\n" &
      "  func `<`*(g, h: T): bool {.borrow.}\n  func `≤`*(g, h: T): bool {.borrow.}\n" &
      "  func `≡`*(g, h: T): bool {.borrow.}\nborrowGradeOperations(Grade)\n"
    check borrows.isSettled("a.nim")  # template of PGA library, as hand writes it
    let one_line = "proc f(): int =\n  ## Doc.\n  func g(x: int): int = x + 1\n  g(1)\n"
    check checkBlanks("a.nim", one_line).mapIt(it.line) == @[3]  # stage after it alone
    check one_line.fixed("a.nim") ==
      "proc f(): int =\n  ## Doc.\n  func g(x: int): int = x + 1\n\n  g(1)\n"
    let spread = "proc f() =\n\n  func a(): int = 1\n\n  # Why.\n  func b(): int = 2\n" &
      "  discard a() + b()\n"
    check checkBlanks("a.nim", spread)[0].message.startsWith("One-line routine")
    check spread.fixed("a.nim") == "proc f() =\n  func a(): int = 1\n  # Why.\n" &
      "  func b(): int = 2\n\n  discard a() + b()\n"
    for settled in [
      one_line.fixed("a.nim"),
      spread.fixed("a.nim"),
      "proc f() =\n  func a(): int = 1\n\n  proc b() =\n    discard\n\n  b()\n",  # longer after
      "proc f() =\n\n  proc b() =\n    discard\n\n  func a(): int = 1\n\n  b()\n",  # longer before
      "proc f() =\n\n  func a(): int = 1\n    ## Doc.\n\n  a()\n",  # documented: one each side
    ]:
      check settled.isSettled("a.nim")


  test "never read: side leaving owner, one-line template alias, routine outside routine":
    for kept in [
      "proc f() =\n  discard\n\n  proc g() =\n    discard\n\n\nproc h() = discard\n",
      "proc f() =\n  template m: untyped = x\n  m\n",
      "when true:\n  proc g() = discard\n  g()\n",
      "proc f() =\n  let g = proc () = discard\n",
    ]:
      check kept.isSettled("a.nim")
