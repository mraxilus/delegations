## Hold blank lines beside suites, tests and nested helpers (X.2, STYLE.md §1): each run of
##   other count is reported and fixed; fixture string, alias and side leaving owner are never
##   read; fix changes nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/blanks


const TEST_PATH = "curator/audit/tests/suites/test_a.nim"
  ## Path under `tests/`, where suite and test rules hold.


func fixed(source: string, path = TEST_PATH): string =
  ## Fix blank lines of source, as `koch fix` does.
  fixBlanks(path, source).source


func isSettled(source: string, path = TEST_PATH): bool =
  ## Decide whether source reports no blank-line finding and fixes to itself again.
  checkBlanks(path, source).len == 0 and fixBlanks(path, source).source == source and
    fixBlanks(path, source).fixed.len == 0



suite "Blanks":
  test "suite takes three blank lines before it, test two, first child none":
    let breach = "import std/unittest\n\nsuite \"A\":\n  test \"a\":\n    check true\n\n" &
      "  test \"b\":\n    check true\n\nsuite \"B\":\n\n  test \"c\":\n    check true\n"
    check checkBlanks(TEST_PATH, breach).mapIt(it.message.split(" (")[0]) == @[
      "Suite takes three blank lines before it", "Test takes two blank lines before it",
      "Suite takes three blank lines before it", "First child follows its opener at once",
    ]
    check breach.fixed == "import std/unittest\n\n\n\nsuite \"A\":\n  test \"a\":\n" &
      "    check true\n\n\n  test \"b\":\n    check true\n\n\n\nsuite \"B\":\n  test \"c\":\n" &
      "    check true\n"
    check breach.fixed.isSettled
    check checkBlanks("curator/audit/src/a.nim", breach).len == 0  # tests alone


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


  test "nested helper takes one blank line on each side, right after owner's doc too":
    let one_line = "proc f(): int =\n  ## Doc.\n  func g(x: int): int = x + 1\n  g(1)\n"
    check checkBlanks("a.nim", one_line).mapIt(it.line) == @[3, 3]
    check one_line.fixed("a.nim") ==
      "proc f(): int =\n  ## Doc.\n\n  func g(x: int): int = x + 1\n\n  g(1)\n"
    let body = "proc f() =\n  proc g() =\n    discard\n\n\n  g()\n\nproc h() = discard\n"
    check body.fixed("a.nim") ==
      "proc f() =\n\n  proc g() =\n    discard\n\n  g()\n\nproc h() = discard\n"
    let wrapped = "proc f() =\n  ## Doc.\n  proc g(\n    a: int,\n  ): int =\n    a\n" &
      "  discard g(1)\n"
    check wrapped.fixed("a.nim") == "proc f() =\n  ## Doc.\n\n  proc g(\n    a: int,\n" &
      "  ): int =\n    a\n\n  discard g(1)\n"
    for settled in [one_line.fixed("a.nim"), body.fixed("a.nim"), wrapped.fixed("a.nim")]:
      check settled.isSettled("a.nim")


  test "never read: side leaving owner, one-line template alias, routine outside routine":
    for kept in [
      "proc f() =\n  discard\n\n  proc g() =\n    discard\n\n\nproc h() = discard\n",
      "proc f() =\n  template m: untyped = x\n  m\n",
      "when true:\n  proc g() = discard\n  g()\n",
      "proc f() =\n  let g = proc () = discard\n",
    ]:
      check kept.isSettled("a.nim")
