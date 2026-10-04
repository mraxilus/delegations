## Replicate command line of `command.nim` header: what `knoller [--check] path...` reads,
##   writes, prints and exits with, driven through `outcomeOf` on text alone.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, unittest]
import ../../src/knoller/[chain, command, rules]


const
  DIRTY = "let x = a+b # c\nproc f(a: int; b: string) = discard\n"
    ## Nim source breaking spacing, comment gap and separators, and lacking `strictFuncs`.
  CLEAN = "{.experimental: \"strictFuncs\".}\n\nlet x = a + b  # c\n"  ## Nim source fix leaves.
  README = currentSourcePath().parentDir.parentDir.parentDir / "README.md"
    ## Record listing every rule id output cites.
  SUITES =
    "{.experimental: \"strictFuncs\".}\n\nimport std/unittest\nsuite \"A\":\n  test \"a\":\n" &
      "    check true\n  test \"b\":\n    check true\n"
    ## Suites of test file, each run of blank lines short.
  STUB = "discard \"\"\"\naction: run\ncmd: \"nim c -r $file\"\n\"\"\"\ninclude \"suites.nim\"\n"
    ## Testament stub whose `cmd` holds `-r`.
  UMBRELLA = "{.experimental: \"strictFuncs\".}\n\nimport ./p/a\n"
    ## Library umbrella lacking profiler import.


func shown(path, directory, source: string): seq[string] =
  ## Print check of one file path names from directory, path read as `<path>`.
  let outcome = outcomeOf([(path, source)], [], is_check = true, directory)
  outcome.lines.mapIt(it.replace(path, "<path>"))



suite "Command line":
  test "path is required, and option other than `--check` is usage error":
    check parseOptions(["a.nim"]).get.paths == @["a.nim"]  # path alone fixes
    check parseOptions(["--check", "a.nim", "src"]).get.is_check  # check, two paths
    check parseOptions([]).isNone  # no path
    check parseOptions(["--check"]).isNone  # option alone names no path
    check parseOptions(["--width=80", "a.nim"]).isNone  # no style option
    check parseOptions(["--check=no", "a.nim"]).isNone  # check takes no value


  test "dialect follows extension, and other file has none":
    check "a.nim".dialectOf == some(Dialect.Module)
    check "a.nims".dialectOf == some(Dialect.Script)
    check "a.nimble".dialectOf == some(Dialect.Package)
    check "a.md".dialectOf.isNone and "nim.cfg".dialectOf.isNone


  test "fix writes changed file alone, and prints each rewrite by rule id, then count":
    let outcome = outcomeOf([("a.nim", DIRTY), ("b.nim", CLEAN)], [], is_check = false)
    check outcome.written.len == 1 and outcome.written[0][0] == "a.nim"  # clean file unwritten
    check outcome.lines == @[
      "a.nim: strictfuncs fixed",  # whole file: path alone
      "a.nim:1: expression-spacing fixed",
      "a.nim:1: trailing-comment fixed",
      "a.nim:2: parameter-separators fixed",
      "4 fixed.",
    ]  # sorted by path, line, then rule id
    check outcome.code == 0  # nothing left
    let again = outcomeOf([outcome.written[0]], [], is_check = false)
    check again.written.len == 0 and again.lines == @["0 fixed."]  # second run writes nothing


  test "check writes nothing, reports each change due, and exits 1 where any":
    let outcome = outcomeOf([("a.nim", DIRTY)], [], is_check = true)
    check outcome.written.len == 0
    check outcome.lines[^1] == "4 to fix."
    check outcome.lines[0] == "a.nim: strictfuncs to fix"
    check outcome.code == 1
    check outcomeOf([("b.nim", CLEAN)], [], is_check = true).code == 0  # nothing due


  test "finding fix leaves prints by rule id with its message, and exits 1":
    let
      crossing = "let a = 1+2\nlet m = f(\n  #!fix off\n  1,  0,\n)\n#!fix on\n"
      outcome = outcomeOf([("a.nims", crossing)], [], is_check = false)
    check outcome.written.len == 0  # fence it cannot read leaves file as written
    check outcome.lines[0].startsWith("a.nims:2: fence left: Fence closes outside bracket")
    check outcome.lines[^1] == "0 fixed."
    check outcome.code == 1


  test "finding left prints at its line in file as given, as each rewrite does":
    let outcome = outcomeOf([("a.nim", "let a = 1\nlet b = not x == y\n")], [], is_check = true)
    check outcome.lines.len == 4
    check outcome.lines[0 .. 1] == @["a.nim: strictfuncs to fix", "a.nim:1: single-bindings to fix"]
    check outcome.lines[2].startsWith("a.nim:2: not-over-binary left: ")  # fix moves it to 5


  test "each fence prints as warning naming what breaks inside it, and changes no exit code":
    let
      fenced = "let a = 1\n#!fix off\nlet b = 1+2\n#!fix on\n"
      outcome = outcomeOf([("a.nims", fenced)], [], is_check = true)
    check outcome.lines == @[
      "a.nims:2: fence-held warning: Fence keeps its lines as written, and inside them " &
        "expression-spacing breaks once at line 3 (X.1); got lines `2` to `4`.",
      "0 to fix.",
    ]
    check outcome.code == 0  # break inside fence alone fails nothing
    let written = outcomeOf([("a.nims", fenced)], [], is_check = false)
    check written.written.len == 0 and written.code == 0  # nothing written


  test "path reads whole from directory it is named from, `.` and `..` resolved":
    check layoutOf("suites.nim", "/p/tests") == "/p/tests/suites.nim"
    check layoutOf("tests/suites.nim", "/p") == "/p/tests/suites.nim"
    check layoutOf("../tests/./a.nim", "/p/src") == "/p/tests/a.nim"
    check layoutOf("/q/a.nim", "/p") == "/q/a.nim"  # absolute path stays


  test "same file reports alike however path names it: test file, stub and umbrella":
    for (source, rule, inside, outside) in [
      (SUITES, "test-blank-lines", ("suites.nim", "/p/tests"), ("tests/suites.nim", "/p")),
      (STUB, "stub-keys", ("test_p.nim", "/p/tests"), ("p/tests/test_p.nim", "/")),
      (UMBRELLA, "profiler-import", ("p.nim", "/p/src"), ("../p/src/p.nim", "/p/tests")),
    ]:
      let lines = shown(inside[0], inside[1], source)
      check lines.anyIt(rule in it)  # rule reads path whole, from inside its directory too
      check lines == shown(outside[0], outside[1], source)


  test "directory names Nim files git lists under it, sorted; one naming none says why":
    check listingOf("src", "b.nim\0a.md\0a.nim\0", 0) == (@["src/a.nim", "src/b.nim"], "")
    let outside = listingOf("/q", "fatal: not a git repository\n", 128)
    check outside.files.len == 0
    check outside.refusal.startsWith("Directory lies outside git work tree")
    check outside.refusal.endsWith("got `/q`.")
    let bare = listingOf("docs", "a.md\0", 0)
    check bare.files.len == 0
    check bare.refusal.startsWith("Directory holds no Nim file that git lists")


  test "locked nimble file and file of no dialect are passed over":
    let outcome = outcomeOf(
      [("p/p.nimble", "version = \"0.1.0\" \n"), ("README.md", "x \n")],
      ["p/p.nimble"],
      is_check = false,
    )
    check outcome.written.len == 0 and outcome.lines == @["0 fixed."] and outcome.code == 0


  test "README lists every rule id output cites":
    let record = readFile(README)
    for rule in Rule: check ("`" & rule.id & "`") in record  # id named as code span
