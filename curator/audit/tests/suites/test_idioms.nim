## Hold one-line idioms of source: each rule fires on its breach and stays quiet on its form.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/idioms


func module(body: string): string =
  ## Wrap body in smallest module passing pragma rule.
  "## Do one thing.\n\n" & STRICT_FUNCS & "\n\n" & body


func messages(path, source: string): seq[string] =
  ## Collect messages idioms check reports over source.
  checkIdioms(path, source).mapIt(it.message)


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
      "Consecutive single bindings share one keyword (X.5); got `let` twice."
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
