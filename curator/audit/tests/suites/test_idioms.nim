## Hold one-line idioms of source: each rule fires on its breach and stays quiet on its form;
##   each fixer clears its breach, changes nothing else, and changes nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../../knoller/src/knoller
import ../../src/[findings, idioms]


const HEAD_LINES = 4  ## Lines `module` puts before body: doc, blank, pragma, blank.


func module(body: string): string =
  ## Wrap body in smallest module passing pragma rule.
  "## Do one thing.\n\n" & STRICT_FUNCS & "\n\n" & body


func messages(path, source: string): seq[string] =
  ## Collect messages idioms check reports over source.
  checkIdioms(path, source).mapIt(it.message)


func fixed(source: string): Fix =
  ## Fix idioms of source, as `koch fix` does.
  fixIdioms("a.nim", source)


func isSettled(source: string): bool =
  ## Decide whether fixed source reports no idiom finding and fixes to itself again.
  let again = fixed(source)
  messages("a.nim", source).len == 0 and again.source == source and again.fixed.len == 0



suite "Idioms":
  test "module carries strictFuncs pragma before its imports":
    check messages("a.nim", module("import std/os\n")).len == 0
    check "got none" in messages("a.nim", "## Do.\n\nimport std/os\n")[0]
    let late = "## Do.\n\nimport std/os\n\n" & STRICT_FUNCS & "\n"
    check "got it after" in messages("a.nim", late)[0]


  test "bracket import is alphabetised, standard library first and local modules last":
    check messages("a.nim", module("import std/[os, strutils]\nimport ./[a, b {.all.}]\n")).len == 0
    check "got `strutils, os`" in messages("a.nim", module("import std/[strutils, os]\n"))[0]
    let local_first = module("import ./a\nimport std/os\n")
    check "got `std/os`" in messages("a.nim", local_first)[0]
    # Bracket spanning lines is read whole, as `koch.nim` writes its own.
    check "got `b, a`" in messages("a.nim", module("import ./[\n  b,\n  a,\n]\n"))[0]


  test "consecutive single bindings of one keyword share it, once per run":
    let run = module("proc f() =\n  let a = 1\n  let b = 2\n  let c = 3\n")
    check messages("a.nim", run) == @[
      "Consecutive single bindings share one keyword (X.5); got `let` twice.",
    ]  # one finding for run of three
    check messages("a.nim", module("proc f() =\n  let a = 1\n  var b = 2\n")).len == 0
    check messages("a.nim", module("proc f() =\n  let\n    a = 1\n    b = 2\n")).len == 0
    # String holding keyword is blanked first, so page template never reads as binding.
    check messages("a.nim", module("const PAGE = \"\"\"\nlet a = 1\nlet b = 2\n\"\"\"\n")).len == 0


  test "used pragma carries comment naming its consumer":
    check "got none" in messages("a.nim", module("func f() {.used.} = discard\n"))[0]
    check messages("a.nim", module("func f() {.used.} = discard  # Used in b.nim.\n")).len == 0
    check messages("a.nim", module("{.used.}\n")).len == 0  # module pragma, not symbol


  test "push stands only over foreign bindings":
    let ordinary = module("{.push inline.}\nfunc f() = discard\n{.pop.}\n")
    check "got `{.push inline.}`" in messages("a.nim", ordinary)[0]
    let foreign = module("{.push importc, header: \"<x.h>\".}\nproc f()\n{.pop.}\n")
    check messages("a.nim", foreign).len == 0


  test "return result never appears":
    let redundant = module("func f(): int =\n  return result\n")
    check "got `return result`" in messages("a.nim", redundant)[0]
    check messages("a.nim", module("func f(): int =\n  if true: return\n  result = 1\n")).len == 0


  test "suite importing std/random seeds it":
    let unseeded = module("import std/[random, unittest]\n\nlet x = rand(1)\n")
    check "got no seed" in messages("tests/suites/test_x.nim", unseeded)[0]
    let seeded = unseeded.replace("let x", "randomize(0)\nlet x")
    check messages("tests/suites/test_x.nim", seeded).len == 0
    check messages("tests/suites/test_x.nim", unseeded.replace("rand(1)", "initRand(7)")).len == 0
    check messages("src/x.nim", unseeded).len == 0  # outside `tests/`, rule is silent


  test "stub carries testament header without -r, batchable or joinable":
    let header = "discard \"\"\"\naction: run\ncmd: \"nim c $options $file\"\n\"\"\"\n"
    check messages("tests/test_x.nim", header & module("include \"suites.nim\"\n")).len == 0
    check "got none" in messages("tests/test_x.nim", module("include \"suites.nim\"\n"))[0]
    let with_run = header.replace("nim c ", "nim c -r ") & module("")
    check "got `-r`" in messages("tests/test_x.nim", with_run)[0]
    let batched = header.replace("action: run", "action: run\nbatchable: false") & module("")
    check "got `batchable`" in messages("tests/test_x.nim", batched)[0]
    check messages("tests/suites/test_x.nim", module("")).len == 0  # suite is not stub


  test "stub's `-r` is cut from `cmd`, and line of `batchable` or `joinable` goes":
    let
      header = "discard \"\"\"\naction: run\nbatchable: false\n" &
        "cmd: \"nim c -r --hints:off -run $options $file\"\njoinable: true\n\"\"\"\n"
      body = PROFILER_IMPORT & "\n\ninclude \"suites.nim\"\n"
      stub = header & module(body)
      fix = fixIdioms("tests/test_x.nim", stub)
    check checkIdioms("tests/test_x.nim", stub).mapIt(it.line) == @[3, 4, 5]  # line of each key
    check fix.source == "discard \"\"\"\naction: run\n" &
      "cmd: \"nim c --hints:off -run $options $file\"\n\"\"\"\n" & module(body)
    check fix.fixed.mapIt(it.line) == @[3, 4, 5]  # reports name lines as given
    check checkIdioms("tests/test_x.nim", fix.source).len == 0  # flag alone, so `-run` stays
    check fixIdioms("tests/test_x.nim", fix.source).fixed.len == 0  # second fix writes nothing
    check fixIdioms("tests/suites/test_x.nim", stub).source == stub  # suite is no stub
    let tail = "discard \"\"\"\ncmd: \"nim c $options $file -r\"\n\"\"\"\n" & module(body)
    check fixIdioms("tests/test_x.nim", tail).source ==
      "discard \"\"\"\ncmd: \"nim c $options $file\"\n\"\"\"\n" & module(body)  # before quote


  test "profiler import stands on one line, after pragmas of entry, umbrella and stub":
    let
      guard = "when compileOption(\"profiler\"):\n  import std/nimprof\n"
      two = module(guard & "\nimport std/os\n")
    check checkProfiler("a.nim", two).mapIt(it.line) == @[HEAD_LINES + 1]
    check fixed(two).source == module(PROFILER_IMPORT & "\n\nimport std/os\n")
    check checkProfiler("a.nim", fixed(two).source).len == 0
    let entry = module("import std/os\n\nwhen isMainModule:\n  echo 1\n")
    check checkProfiler("a.nim", entry)[0].message.endsWith("got none.")
    check fixed(entry).source ==
      module(PROFILER_IMPORT & "\n\nimport std/os\n\nwhen isMainModule:\n  echo 1\n")
    check fixed(entry).source.isSettled and checkProfiler("a.nim", fixed(entry).source).len == 0
    let library = module("import std/os\n")
    check checkProfiler("curator/probe/src/probe.nim", library).len == 1  # umbrella
    check checkProfiler("curator/probe/src/probe/ring.nim", library).len == 0  # module of it
    check checkProfiler("a.nim", library).len == 0  # neither entry nor umbrella
    let
      header = "discard \"\"\"\naction: run\n\"\"\"\n## Do.\n\n" &
        "{.warning[UnusedImport]: off.}\n\n" & STRICT_FUNCS & "\n"
      stub = fixIdioms("tests/test_x.nim", header & "include \"suites.nim\"\n")
    check stub.source == header & "\n" & PROFILER_IMPORT & "\n\ninclude \"suites.nim\"\n"
    check stub.fixed.mapIt(it.rule) == @[Rule.ProfilerImport]
    check fixIdioms("tests/test_x.nim", stub.source).fixed.len == 0  # second fix writes nothing


  test "test echo of unlabelled value is debug output; label or condition passes":
    let debug = module("test \"a\":\n  echo x\n")
    check "got `echo x`" in messages("tests/suites/test_x.nim", debug)[0]
    check messages("tests/suites/test_x.nim", module("test \"a\":\n  echo \"x: \", x\n")).len == 0
    let diagnostic = module("test \"a\":\n  if x > 1:\n    echo x\n")
    check messages("tests/suites/test_x.nim", diagnostic).len == 0
    check messages("src/x.nim", debug).len == 0  # program may print


  test "machine path is finding in any kind but Markdown":
    check checkMachinePaths("a.nim", "let p = \"/home/me/data\"\n")[0].line == 1
    check checkMachinePaths("a.yml", "run: cd /Users/me\n").len == 1
    check checkMachinePaths("a.nim", "let p = getEnv(\"HOME\")\n").len == 0


  test "tsconfig sets every flag to true, read as text":
    let all_set = """{
  // TypeScript admits comments, which std/json refuses.
  "compilerOptions": {"strict": true, "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true}
}"""
    check checkTsconfig("tsconfig.json", all_set).len == 0
    let one_off = all_set.replace("\"strict\": true", "\"strict\": false")
    check checkTsconfig("tsconfig.json", one_off).mapIt(it.message).anyIt("`strict`" in it)
    check checkTsconfig("tsconfig.json", "{}").len == TYPESCRIPT_FLAGS.len



suite "Idiom fixes":
  test "return result inside branch, or with body after it, becomes bare return":
    let fix = fixed(module("func f(): int =\n  if true:\n    return result  # Early.\n  1\n"))
    check fix.source == module("func f(): int =\n  if true:\n    return  # Early.\n  1\n")
    check fix.fixed.mapIt(it.line) == @[HEAD_LINES + 3]  # line check names
    check fix.fixed[0].rule == Rule.ReturnResult  # rule named
    check fix.source.isSettled  # check reports none, and second fix changes nothing
    let followed = fixed(module("proc f(): int =\n  return result\n  echo 1\n"))
    check followed.source == module("proc f(): int =\n  return\n  echo 1\n")  # exit before more
    check followed.source.isSettled


  test "return result ending routine goes, with blank line opening its paragraph":
    let ending = fixed(module("func f(): int =\n  result = 1\n  return result\n"))
    check ending.source == module("func f(): int =\n  result = 1\n")  # line deleted
    check ending.fixed.mapIt(it.line) == @[HEAD_LINES + 3]
    check ending.source.isSettled
    let spaced = "func f(): int =\n  result = 1\n\n  return result\n\n\nfunc g() = discard\n"
    check fixed(module(spaced)).source ==
      module("func f(): int =\n  result = 1\n\n\nfunc g() = discard\n")  # two blanks stay between
    let wrapped = "func f(\n  a: int\n): int =\n  result = a\n  return result\n"
    check fixed(module(wrapped)).source ==
      module("func f(\n  a: int\n): int =\n  result = a\n")  # signature on lines of its own


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


  test "bracket items are sorted into slots they held, so layout stays":
    let one_line = fixed(module("import std/[strutils, os]\nimport ./[b {.all.}, a]\n"))
    check one_line.source == module("import std/[os, strutils]\nimport ./[a, b {.all.}]\n")
    check one_line.fixed.mapIt(it.line) == @[HEAD_LINES + 1, HEAD_LINES + 2]  # one per bracket
    check one_line.source.isSettled
    let each_line = fixed(module("import ./[\n  c,\n  a,\n  b,\n]\n"))
    check each_line.source == module("import ./[\n  a,\n  b,\n  c,\n]\n")  # one item per line
    check each_line.source.isSettled
    let flowed = fixed(module("import ./[\n  d, c,\n  b, a,\n]\n"))
    check flowed.source == module("import ./[\n  a, b,\n  c, d,\n]\n")  # two items per line
    check flowed.source.isSettled
    let commented = module("import ./[\n  b,  # Why.\n  a,\n]\n")
    check fixed(commented).source == commented  # comment belongs to item or slot: left to hand


  test "adjacent import lines are ordered by rank, and rank split by other lines stays":
    let fix = fixed(module("import ./a\nimport pkg/x\nimport std/os\n"))
    check fix.source == module("import std/os\nimport pkg/x\nimport ./a\n")
    check fix.fixed.mapIt(it.rule) == @[Rule.ImportRank, Rule.ImportRank]
    check fix.source.isSettled
    let apart = module("import ./a\n\nimport std/os\n")
    check fixed(apart).source == apart  # where it lands is choice: left to hand


  test "run of single bindings shares one keyword; comment, doc and continuation move with it":
    let consts = fixed(module("const A = 1  # One.\nconst B = 2\n  ## Doc of B.\n\nlet c = 3\n"))
    check consts.source ==
      module("const\n  A = 1  # One.\n  B = 2\n    ## Doc of B.\n\nlet c = 3\n")
    check consts.fixed.mapIt(it.line) == @[HEAD_LINES + 1]  # one report per run
    check consts.fixed[0].rule == Rule.SingleBindings
    check consts.source.isSettled
    let wrapped = fixed(module("proc f() =\n  let a = 1\n  let b = g(\n    2,\n  )\n  echo a\n"))
    check wrapped.source ==
      module("proc f() =\n  let\n    a = 1\n    b = g(\n      2,\n    )\n  echo a\n")
    check wrapped.source.isSettled
    let nested = fixed(module("let a = 1\nlet b = block:\n  let c = 2\n  let d = 3\n  c + d\n"))
    check nested.source == module(
      "let\n  a = 1\n  b = block:\n    let\n      c = 2\n      d = 3\n    c + d\n",
    )  # inner run first, then outer carries it
    check nested.source.isSettled
    let long_string = module("const A = 1\nconst B = \"\"\"\ntext\n\"\"\"\n")
    check fixed(long_string).source == long_string  # indent would change string: left to hand


  test "missing strictFuncs goes where X.6 puts directives":
    let
      strict = "\n" & STRICT_FUNCS & "\n\n"
      plain = fixed("## Do.\n\nimport std/os\n")
      profiled = PROFILER_IMPORT & "\n"
    check plain.source == "## Do.\n" & strict & "import std/os\n"  # after header docs
    check plain.fixed.mapIt(it.line) == @[0]  # whole file, as check names it
    check plain.source.isSettled
    check fixed("## Do.\n\n# Design note.\n\n" & profiled).source ==
      "## Do.\n\n# Design note.\n" & strict & profiled  # after notes, before instrumentation
    let stub = "discard \"\"\"\naction: run\n\"\"\"\n## Do.\n\nimport std/os\n"
    check fixed(stub).source ==
      "discard \"\"\"\naction: run\n\"\"\"\n## Do.\n" & strict & "import std/os\n"  # after header
    check fixed("## Do.\nimport std/os\n").source == "## Do.\n" & strict & "import std/os\n"
    check fixed("## Do.\n").source == "## Do.\n\n" & STRICT_FUNCS & "\n"  # no code yet
    let foreign = "{.push importc.}\nproc f()\n{.pop.}\n"
    check fixed("## Do.\n\n" & foreign).source == "## Do.\n" & strict & foreign  # push opens body


  test "strictFuncs after imports moves where X.6 puts directives, as check reads it":
    let
      late = "## Do.\n\nimport std/os\n\n" & STRICT_FUNCS & "\n\n\nlet a = 1\n"
      fix = fixed(late)
    check "got it after" in messages("a.nim", late)[0]
    check fix.source == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\n\n\nlet a = 1\n"
    check fix.fixed.mapIt(it.line) == @[5]  # line check names
    check fix.source.isSettled
    let glued = "## Do.\n\nimport std/os\n" & STRICT_FUNCS & "\nlet a = 1\n"
    check fixed(glued).source == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\nlet a = 1\n"
    let pushed =
      "## Do.\n\n{.push importc.}\nproc f()\n{.pop.}\nimport std/os\n" & STRICT_FUNCS & "\n"
    check fixed(pushed).source ==
      "## Do.\n\n" & STRICT_FUNCS & "\n\n{.push importc.}\nproc f()\n{.pop.}\nimport std/os\n"


  test "adjacent imports of one directory share one bracket; bracket of one module drops":
    let
      apart =
        module("import std/strutils\nimport std/[os, algorithm]\nimport ./b\nimport ./a {.all.}\n")
      fix = fixed(apart)
    check checkImportBrackets("a.nim", apart).mapIt(it.message) == @[
      "Imports of one directory share one bracket (X.5); got `std/` in `2` statements.",
      "Imports of one directory share one bracket (X.5); got `./` in `2` statements.",
    ]
    check fix.source == module("import std/[algorithm, os, strutils]\nimport ./[a {.all.}, b]\n")
    check fix.fixed.filterIt(it.rule == Rule.ImportBrackets).mapIt(it.line) ==
      @[HEAD_LINES + 1, HEAD_LINES + 3]  # one report to merge, at first statement
    check fix.source.isSettled
    check checkImportBrackets("a.nim", fix.source).len == 0
    check fixed(module("import std/[math]\n")).source == module("import std/math\n")
    check checkImportBrackets("a.nim", module("import std/[math]\n"))[0].message ==
      "Bracket of one module drops its bracket (STYLE.md §5); got `std/[math]`."


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


  test "pragma list of declaration, export list and names after `from … import` are alphabetised":
    let
      lists = module(
        "proc f() {.importc: \"f\", header: \"a.h\", bycopy.}\nexport b, a  # Why.\n" &
          "from std/os import walkDir, getEnv\n",
      )
      fix = fixed(lists)
    check checkLists("a.nim", lists).mapIt(it.message.split("; ")[1]) == @[
      "got `importc, header, bycopy`.", "got `b, a`.", "got `walkDir, getEnv`.",
    ]
    check fix.source == module("proc f() {.bycopy, header: \"a.h\", importc: \"f\".}\n" &
      "export a, b  # Why.\nfrom std/os import getEnv, walkDir\n")  # whole items, comment stays
    check fix.source.isSettled


  test "pragma list holds bare pragmas first, then pragmas with argument":
    let pragmas = module("proc f() {.raises: [], header: \"a.h\", inline, borrow.}\n")
    check fixed(pragmas).source ==
      module("proc f() {.borrow, inline, header: \"a.h\", raises: [].}\n")
    check checkLists("a.nim", module("proc f() {.inline, header: \"a.h\".}\n")).len == 0


  test "alphabetised is dictionary order: case and `_` ignored, tie to code point":
    check fixed(module("export isB, is_a, facing, Facing\n")).source ==
      module("export Facing, facing, is_a, isB\n")
    check fixed(module("export layout.Tree, layout.Entry\n")).source ==
      module("export layout.Entry, layout.Tree\n")
    check "got `b_c, ba`" in messages("a.nim", module("import ./[b_c, ba]\n"))[0]
    check fixed(module("import ./[b_c, ba]\n")).source == module("import ./[ba, b_c]\n")


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
