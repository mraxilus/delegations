## Replicate lines of `reports.nim`: start, refusal, run, failure, log and count, as assayer prints
##   them, with color and without.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, times, unittest]
import ../../src/assayer/[headers, plans, reports, runs]


const
  ROOT = "/work"  ## Working directory each line of suite resolves against.
  FILE = "tests/test_k.nim"  ## Test file each run of suite names.
  PROGRAM = ROOT & "/nimcache/assayer/tests/test_k/c_2/test_k"  ## Program of run that failed.
  RERUN = "/opt/nim/bin/nim c -d:k=2 tests/test_k.nim"  ## Compile, as hand reruns it.
  COUNT_LINES_LONG = 25  ## Lines of output past what excerpt keeps.
  OUTPUT_COMPILE = """
Hint: used config file '/nim/config/nim.cfg' [Conf]
........................................
CC: stdlib_system.nim
/work/src/a.nim(3, 6) Hint: 'x' is declared but not used [XDeclaredButNotUsed]
/work/tests/test_k.nim(5, 14) Error: type mismatch
"""
    ## Compile output of hints, progress, then error.
  OUTPUT_SUITES = """

[Suite] Empty
  [OK] a
  [SKIPPED] later
[Suite] Ring
  [OK] k is small
    /work/tests/test_k.nim(10, 12): Check failed: k != 2
    k was 2
  [FAILED] k is not two
"""
    ## Program output of `std/unittest`, first suite passing whole.
  OUTPUT_TRACEBACK = """
/work/tests/test_k.nim(20) test_k
/nim/lib/system/fatal.nim(62) sysFatal
/nim/lib/std/assertions.nim(45, 14) failedAssertImpl
/nim/lib/system/fatal.nim(62, 5) Error: unhandled exception: boom [AssertionDefect]
"""
    ## Traceback whose frames below `ROOT` explain, and whose frames of standard library do not.


func milliseconds(count: int): Duration =
  ## Construct duration of count milliseconds.
  initDuration(milliseconds = count)


func runFailed(): Run =
  ## Construct run of second configuration of `FILE`, which compiles and runs its program.
  Run(file: FILE, target: Target.C, configuration: "-d:k=2", action: Action.Run,
      executable: PROGRAM, execution: @[PROGRAM], rerun: RERUN)


func linesNumbered(count: int): string =
  ## Write output of count lines, `line 1` onward.
  toSeq(1..count).mapIt("line " & $it).join("\n")



suite "Reports":
  test "duration reads in seconds to one decimal":
    check seconds(milliseconds(0)) == "0.0s"
    check seconds(milliseconds(1234)) == "1.2s"
    check seconds(milliseconds(99_940)) == "99.9s"
    check seconds(milliseconds(125_000)) == "125.0s"  # widens past its column


  test "path below working directory reads relative, and every other path stays":
    check relative("/work/tests/a.nim(3) x", ROOT) == "tests/a.nim(3) x"  # below root
    check relative("/workshop/a.nim", ROOT) == "/workshop/a.nim"  # name only shares letters
    check relative("/work/a and /work/b", "/work/") == "a and b"  # each place, separator closing
    check relative("/a/b", "/") == "/a/b"  # root of file system leaves text
    check shown("./tests/../tests/a.nim", ROOT) == "tests/a.nim"  # normalized
    check shown("/elsewhere/a.nim", ROOT) == "/elsewhere/a.nim"  # outside root


  test "run line opens with status, then aligned duration, file, backend and configuration":
    let
      short = Run(file: FILE, target: Target.C, configuration: "-d:k=1", action: Action.Compile)
      long = Run(file: "tests/test_long_name.nim", target: Target.JavaScript,
          action: Action.Compile, refusal: "no Node.js on PATH for a JavaScript run")
      widths = widthsOf([short, long], ROOT)
      passed = Outcome(compile: Step(duration: milliseconds(1500)))
    check widths == Widths(file: "tests/test_long_name.nim".len, target: 2)  # widest of each
    check lineRun(short, passed, widths, ROOT) ==
        "PASS   1.5s  tests/test_k.nim          c   -d:k=1"  # columns align
    check lineRun(long, Outcome(), widths, ROOT) ==
        "FAIL   0.0s  tests/test_long_name.nim  js"  # no configuration, no trailing space
    check lineRun(short, passed, widths, ROOT, as_color = true).startsWith(
        "\e[32mPASS\e[0m  \e[2m 1.5s\e[0m  ")  # status green, duration dim
    check lineRun(long, Outcome(), widths, ROOT, as_color = true).startsWith(
        "\e[1m\e[31mFAIL\e[0m")  # failure bold red


  test "start line counts runs, files and threads, singular where one":
    check lineStart(8, 1, 4) == "Starting 8 runs of 1 file, 4 at once"
    check lineStart(1, 2, 1) == "Starting 1 run of 2 files, 1 at once"


  test "refused file reads as error, path and reason, each path relative":
    check lineRefusal(FILE, "header key `exitcode` is not read", ROOT) ==
        "error: tests/test_k.nim: header key `exitcode` is not read"
    check lineRefusal("/work/a/test_y.nim", "`/work/a` holds `x.nimble` and `y.nimble`", ROOT) ==
        "error: a/test_y.nim: `a` holds `x.nimble` and `y.nimble`"  # reason relative too
    check lineRefusal(FILE, "x", ROOT, as_color = true).startsWith("\e[1m\e[31merror:\e[0m ")


  test "excerpt drops hints, progress, frames outside and passed tests, keeping what explains":
    check OUTPUT_COMPILE.excerptOf(ROOT) == (@["tests/test_k.nim(5, 14) Error: type mismatch"], 0)
    check OUTPUT_SUITES.excerptOf(ROOT) == (@[
      "[Suite] Ring",
      "    tests/test_k.nim(10, 12): Check failed: k != 2",
      "    k was 2",
      "  [FAILED] k is not two",
    ], 0)  # empty suite gone, shape kept
    check OUTPUT_TRACEBACK.excerptOf(ROOT) == (@[
      "tests/test_k.nim(20) test_k",
      "/nim/lib/system/fatal.nim(62, 5) Error: unhandled exception: boom [AssertionDefect]",
    ], 0)  # frame below root and error line stay


  test "excerpt joins blank lines, takes shared indent off, and keeps tail, counting cut":
    check "a\n\n\nb\n\n".excerptOf(ROOT) == (@["a", "", "b"], 0)  # one blank, none at end
    check "    a\n      b\n".excerptOf(ROOT) == (@["a", "  b"], 0)  # shape under one indent
    let (lines, cut) = linesNumbered(COUNT_LINES_LONG).excerptOf(ROOT)
    check cut == COUNT_LINES_LONG - LINES_EXCERPT_MAX  # lines above
    check lines == toSeq(cut + 1 .. COUNT_LINES_LONG).mapIt("line " & $it)  # tail


  test "failure block names run and reason, then excerpt, rerun and log":
    let
      run = runFailed()
      program = Step(command: PROGRAM, output: "boom\n", code: 1)
      compile = Step(command: "/opt/nim/bin/nim c --nimCache:x", output: OUTPUT_COMPILE, code: 1)
    check linesFailure(run, Outcome(execution: some(program)), ROOT) == @[
      "FAIL tests/test_k.nim c -d:k=2: program exits 1",
      "    boom",
      "  rerun: nimcache/assayer/tests/test_k/c_2/test_k",
      "  log: nimcache/assayer/tests/test_k/c_2/output.log",
    ]  # program reruns as it ran
    check linesFailure(run, Outcome(compile: compile), ROOT) == @[
      "FAIL tests/test_k.nim c -d:k=2: compile exits 1",
      "    tests/test_k.nim(5, 14) Error: type mismatch",
      "  rerun: " & RERUN,
      "  log: nimcache/assayer/tests/test_k/c_2/output.log",
    ]  # compile reruns without cache of run
    let long = Step(command: PROGRAM, output: linesNumbered(COUNT_LINES_LONG), code: 1)
    check linesFailure(run, Outcome(execution: some(long)), ROOT)[1] == "    … 5 lines above"
    check linesFailure(Run(file: FILE, target: Target.JavaScript, refusal: "no Node.js"),
        Outcome(), ROOT) == @["FAIL tests/test_k.nim js: no Node.js"]  # nothing ran


  test "log holds each command, whole output, exit code and time":
    let
      compile = Step(command: "nim c a", output: "ok", duration: milliseconds(1200))
      program = Step(command: "a", output: "boom\n", code: 1, duration: milliseconds(300))
    check textLog(Outcome(compile: compile, execution: some(program))) ==
        "$ nim c a\nok\n[exit 0 in 1.2s]\n$ a\nboom\n[exit 1 in 0.3s]\n"  # both steps
    check textLog(Outcome(compile: Step(command: "nim c a", failure: "no shell"))) ==
        "$ nim c a\n[cannot start: no shell]\n"  # step that never started


  test "count closes report: runs and time, passed, then failed and refused where any":
    check lineSummary(8, 0, 0, milliseconds(19_700)) == "8 runs in 19.7s: 8 passed"
    check lineSummary(1, 0, 0, milliseconds(500)) == "1 run in 0.5s: 1 passed"  # singular
    check lineSummary(3, 1, 1, milliseconds(2000)) ==
        "3 runs in 2.0s: 2 passed, 1 failed; 1 file refused"
    check lineSummary(0, 0, 2, milliseconds(0)) == "0 runs in 0.0s: 0 passed; 2 files refused"
    check lineSummary(1, 0, 0, milliseconds(500), as_color = true).startsWith("\e[1m\e[32m")
    check lineSummary(1, 1, 0, milliseconds(500), as_color = true).startsWith("\e[1m\e[31m")
