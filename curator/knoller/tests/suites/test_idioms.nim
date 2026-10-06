## Hold idiom checks of knoller, those static pass of `curator/audit` reads, and idiom fixers
##   where fix leaves source as written, tracing their reports. Tests that also read check of
##   audit stay there, in `test_idioms.nim`.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[idioms, reports]


const HEAD_LINES = 4  ## Lines `module` puts before body: doc, blank, pragma, blank.


func module(body: string): string =
  ## Wrap body in smallest module passing pragma rule.
  "## Do one thing.\n\n" & STRICT_FUNCS & "\n\n" & body


func fixed(source: string): Fix =
  ## Fix idioms of source, as `koch fix` does.
  fixIdioms("a.nim", source)


func reported(path, source: string): seq[(Rule, string)] =
  ## Read rule and message of each idiom check reports over source.
  checkIdioms(path, source).mapIt (it.rule, it.message)



suite "Idioms":
  test "STYLE.md §2 used pragma carries comment naming its consumer":
    check reported("a.nim", module("func f() {.used.} = discard\n")) == @[
      (Rule.UsedConsumer, "`{.used.}` carries comment naming its consumer; got none."),
    ]
    check checkIdioms("a.nim", module("func f() {.used.} = discard\n"))[0].line == HEAD_LINES + 1
    check reported("a.nim", module("func f() {.used.} = discard  # Used in b.nim.\n")).len == 0
    check reported("a.nim", module("{.used.}\n")).len == 0  # module pragma, not symbol
    check reported("a.nim", module("let s = \"{.used.}\"\n")).len == 0  # string unread


  test "STYLE.md §2 push stands only over foreign bindings, which pop closes":
    let ordinary = module("{.push inline.}\nfunc f() = discard\n{.pop.}\n")
    check reported("a.nim", ordinary) == @[
      (
        Rule.PushForeign,
        "`{.push.}` stands only over foreign bindings, which `{.pop.}` closes; got " &
          "`{.push inline.}`.",
      ),
    ]
    let foreign = module("{.push importc, header: \"<x.h>\".}\nproc f()\n{.pop.}\n")
    check reported("a.nim", foreign).len == 0
    let below = module("{.push header: \"<x.h>\".}\nproc f() {.importc.}\n{.pop.}\n")
    check reported("a.nim", below).len == 0  # mark under push counts too


  test "STYLE.md §2 push over any foreign mark of one list passes, and name holding one does not":
    # Case held: marks stood three times, apart (`FOREIGN_MARKS` here matched as substrings of
    #   block, beside `declared.nim` and `curator/audit` names): `{.push importobjc.}` was
    #   finding, and routine named `importcount` passed push of `inline` (#557). Domain is each
    #   pragma of one list, and each name beside pragmas that holds one.
    for mark in ["dynlib", "exportc", "exportcpp", "extern", "header", "importc", "importcpp",
                 "importjs", "importobjc"]:
      check reported("a.nim", module("{.push " & mark & ".}\nproc f()\n{.pop.}\n")).len == 0
    let named = module("{.push inline.}\nproc importcount() = discard\n{.pop.}\n")
    check reported("a.nim", named).mapIt(it[0]) == @[Rule.PushForeign]  # name marks nothing


  test "STYLE.md §6 suite importing std/random seeds it":
    let unseeded = module("import std/[random, unittest]\n\nlet x = rand(1)\n")
    check reported("tests/suites/test_x.nim", unseeded) == @[
      (Rule.RandomSeed, "Suite seeds `std/random`, as `randomize(0)` does; got no seed."),
    ]
    check checkIdioms("tests/suites/test_x.nim", unseeded)[0].line == 0  # whole file
    check reported("tests/suites/test_x.nim", unseeded.replace("let x", "randomize(0)\nlet x"))
      .len == 0
    check reported("tests/suites/test_x.nim", unseeded.replace("rand(1)", "initRand(7)")).len == 0
    check reported("tests/suites/test_x.nim", module("import std/random\n")).len == 1  # alone
    check reported("src/x.nim", unseeded).len == 0  # outside `tests/`, rule is silent


  test "STYLE.md §6 stub carries testament header":
    let header = "discard \"\"\"\naction: run\ncmd: \"nim c $options $file\"\n\"\"\"\n"
    check reported("tests/test_x.nim", header & module("include \"suites.nim\"\n")).len == 0
    check reported("tests/test_x.nim", module("include \"suites.nim\"\n")) ==
      @[(Rule.StubHeader, "Test stub carries testament header; got none.")]
    check reported("tests/suites/test_x.nim", module("")).len == 0  # suite is not stub
    check reported("src/test_x.nim", module("")).len == 0  # outside `tests/`, no stub


  test "VIII.5 test echo of unlabelled value is debug output; label or condition passes":
    let debug = module("test \"a\":\n  echo x\n")
    check reported("tests/suites/test_x.nim", debug) == @[
      (
        Rule.DebugOutput,
        "Test leaves no debug output; label report, or print under failing condition; got " &
          "`echo x`.",
      ),
    ]
    check checkIdioms("tests/suites/test_x.nim", debug)[0].line == HEAD_LINES + 2
    check reported("tests/suites/test_x.nim", module("test \"a\":\n  echo \"x: \", x\n")).len == 0
    let diagnostic = module("test \"a\":\n  if x > 1:\n    echo x\n")
    check reported("tests/suites/test_x.nim", diagnostic).len == 0
    check reported("src/x.nim", debug).len == 0  # program may print


  test "idioms read each rule static pass reads, test rules in test file alone":
    let breach = "import std/[strutils, os]\nlet a = 1\nlet b = 2\nfunc f(): int =\n" &
      "  return result\n{.push inline.}\n{.pop.}\necho a\n"
    check checkIdioms("a.nim", breach).mapIt(it.rule) == @[
      Rule.StrictFuncs, Rule.BracketImport, Rule.SingleBindings, Rule.PushForeign,
      Rule.ReturnResult,
    ]  # order of static pass: fixers reach first five, then none
    check checkIdioms("tests/test_a.nim", breach).mapIt(it.rule) == @[
      Rule.StrictFuncs, Rule.BracketImport, Rule.SingleBindings, Rule.PushForeign,
      Rule.ReturnResult, Rule.StubHeader, Rule.DebugOutput,
    ]  # stub adds header and debug output



suite "Idiom fixes":
  test "return result whose place reads no one fix stays, finding and all":
    for left in [
      "func f(): int =\n  return result\n",  # only statement: body would go empty
      "func f(): int =\n  result = 1\n  return result  # Done.\n",  # comment would lose its line
      "func f(): int =\n  result = 1\n  # Hand back.\n  return result\n",  # comment names nothing
      "template t(): int =\n  result = 1\n  return result\n",  # template returns from its caller
    ]:
      check fixed(module(left)).source == module(left)


  test "report after deleted line names line of source as given":
    let body = "func f(): int =\n  result = 1\n  return result\n\nlet a = 1\nlet b = 2\n"
    check fixed(module(body)).fixed.mapIt(it.line) ==
      @[HEAD_LINES + 3, HEAD_LINES + 5]  # traced past deleted line


  test "import with except, as, other pragma, comment, or apart from block stays":
    for kept in [
      "import std/os except getEnv\nimport std/strutils\n",
      "import std/os as system_os\nimport std/strutils\n",
      "import ./a {.used.}\nimport ./b\n",
      "import std/os  # Why.\nimport std/strutils\n",
      "import std/os\n\nimport std/strutils\n",
      "from std/os import getEnv\nimport std/strutils\n",
      "import ./a\nimport ../b\n",
    ]:
      check checkImportBrackets("a.nim", module(kept)).len == 0
      check fixed(module(kept)).source == module(kept)


  test "pragma list holds bare pragmas first, then pragmas with argument":
    let pragmas = module("proc f() {.raises: [], header: \"a.h\", inline, borrow.}\n")
    check fixed(pragmas).source ==
      module("proc f() {.borrow, inline, header: \"a.h\", raises: [].}\n")
    check checkLists("a.nim", module("proc f() {.inline, header: \"a.h\".}\n")).len == 0


  test "list order may mean stays: statement, user pragma, except, list spanning lines":
    for kept in [
      "{.push raises: [], gcsafe.}\nproc f()\n{.pop.}\n",
      "proc f() {.async, gcsafe.}\n",
      "export pga except wedge, dot\n",
      "proc f() {.inline,\n  borrow.}\n",
    ]:
      check checkLists("a.nim", module(kept)).len == 0
      check fixed(module(kept)).source == module(kept)


  test "clean module passes through unchanged":
    let clean = module("import std/[os, strutils]\nimport ./[a, b]\n\nlet\n  c = 1\n  d = 2\n")
    check fixed(clean).source == clean and fixed(clean).fixed.len == 0
