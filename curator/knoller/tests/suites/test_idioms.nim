## Hold idiom fixers of knoller where fix leaves source as written, and trace their reports.
##   Tests that also read idioms check of `curator/audit` stay there, in `test_idioms.nim`.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/[idioms, reports]


const HEAD_LINES = 4  ## Lines `module` puts before body: doc, blank, pragma, blank.


func module(body: string): string =
  ## Wrap body in smallest module passing pragma rule.
  "## Do one thing.\n\n" & STRICT_FUNCS & "\n\n" & body


func fixed(source: string): Fix =
  ## Fix idioms of source, as `koch fix` does.
  fixIdioms("a.nim", source)



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
