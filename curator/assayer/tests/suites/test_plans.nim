## Replicate planning of `plans.nim`: one run for each backend under each configuration, each with
##   cache of its own, and command built as testament builds it.

{.experimental: "strictFuncs".}

import std/[os, sequtils, sets, strutils, unittest]
import ../../src/assayer/[headers, plans]


const
  COMPILER = "/opt/nim/bin/nim"  ## Compiler every run of suite takes.
  COMPILER_SPACED = "/opt/my nim/bin/nim"  ## Compiler whose path shell must read quoted.
  NODE = "/usr/bin/node"  ## Node.js every JavaScript run of suite takes.
  ROOT = "/work"  ## Working directory every run of suite resolves against.
  FILE = "tests/test_k.nim"  ## Test file every run of suite plans, relative to `ROOT`.
  COUNT_MATRIX_MAX = 3  ## Configurations matrix holds at most, in law over every combination.


func headerWith(targets: set[Target], count: int): Header =
  ## Construct header of backends and of `count` configurations, `-d:k=0` onward.
  Header(command: "nim c $options $file", matrix: toSeq(0..<count).mapIt("-d:k=" & $it),
      targets: targets)


func setOf(subset: int): set[Target] =
  ## Read backends whose bit subset sets, in order of `Target`.
  for target in Target:
    if (subset and (1 shl ord(target))) != 0: result.incl target



suite "Plans":
  test "each backend runs under each configuration, configuration by configuration":
    for subset in 1 ..< 1 shl (ord(Target.high) + 1):
      for count in 1..COUNT_MATRIX_MAX:
        let
          targets = subset.setOf
          runs = runsOf(FILE, headerWith(targets, count), COMPILER, NODE, ROOT)
        check runs.len == targets.card * count  # one run for each pair
        var k = 0
        for place in 0..<count:
          for target in targets:
            check runs[k].configuration == "-d:k=" & $place  # configuration outer
            check runs[k].target == target  # backend inner, in order of `Target`
            inc k


  test "no two runs of one file share cache, in every combination of backends and matrix":
    for subset in 1 ..< 1 shl (ord(Target.high) + 1):
      for count in 1..COUNT_MATRIX_MAX:
        let runs = runsOf(FILE, headerWith(subset.setOf, count), COMPILER, NODE, ROOT)
        check runs.mapIt(it.executable.parentDir).toHashSet.card == runs.len  # distinct
        for run in runs:
          check run.executable.startsWith(ROOT / DIRECTORY_RUNS / "tests/test_k/")  # its path


  test "command replaces leading `nim` and each name, options of run before configuration":
    let
      run = runsOf(FILE, headerWith({Target.C}, 1), COMPILER, NODE, ROOT)[0]
      directory = directoryOf(FILE, ROOT, Target.C, 0)
    check run.executable == directory / "test_k".addFileExt(ExeExt)  # inside its cache
    check run.command == COMPILER & " c --nimCache:" & directory & " --out:" & run.executable &
        " -d:k=0 " & FILE  # configuration speaks last
    check run.execution == @[run.executable]  # program alone
    check run.rerun == COMPILER & " c -d:k=0 " & FILE  # no cache or program of run, spaces joined
    check run.logOf == directory / FILE_LOG  # log beside program
    check run.refusal == ""  # run can start


  test "template names target, file, its directory and compiler, quoted for shell":
    let
      header = Header(command: "$nim $target $options $filedir $file", targets: {Target.C})
      run = runsOf("my tests/test_k.nim", header, COMPILER_SPACED, NODE, ROOT)[0]
    check run.command.startsWith(COMPILER_SPACED.quoteShell & " c ")  # `$nim`, then `$target`
    check run.command.endsWith(" " & ROOT / "my tests" & " " & "my tests/test_k.nim".quoteShell)
    check runsOf(FILE, Header(command: "nim c $file"), COMPILER_SPACED, NODE, ROOT)[0].command ==
        COMPILER_SPACED.quoteShell & " c " & FILE  # leading `nim` quoted too


  test "JavaScript run takes default option of testament and runs under Node.js":
    let run = runsOf(FILE, headerWith({Target.JavaScript}, 1), COMPILER, NODE, ROOT)[0]
    check run.command.startsWith(COMPILER & " c -d:nodejs --nimCache:")  # default option first
    check run.executable.endsWith("test_k.js")  # script, not program
    check run.execution == @[NODE, "--unhandled-rejections=strict", run.executable]  # as testament
    check runsOf(FILE, headerWith({Target.JavaScript}, 1), COMPILER, "", ROOT)[0].refusal ==
        "no Node.js on PATH for a JavaScript run"  # refused before compile


  test "backend configuration names moves run, last one winning, unknown one moving none":
    check targetIn("-d:a -b:js", Target.C) == Target.JavaScript  # short form
    check targetIn("--backend:cpp", Target.C) == Target.CPlusPlus  # long form
    check targetIn("--backend=js -b=c", Target.CPlusPlus) == Target.C  # last wins, `=` read
    check targetIn("-b:wasm", Target.C) == Target.C  # unknown moves none
    check targetIn("-d:backend:js", Target.C) == Target.C  # define is no backend
    let run = runsOf(FILE, Header(matrix: @["-b:js"]), COMPILER, NODE, ROOT)[0]
    check run.target == Target.JavaScript and run.execution[0] == NODE  # moved run executes so


  test "template naming what testament fills nothing for refuses, naming it":
    check nameUnfilled("nim c $options $file") == ""  # names testament fills
    check nameUnfilled("$nim ${target} $$HOME $filedir") == ""  # braces and escaped dollar
    check nameUnfilled("nim c $flags $file") == "$flags"  # first name nothing fills
    check nameUnfilled("nim c $1 $file") == "$1"  # no place by number
    check nameUnfilled("nim c ${opts") == "${opts"  # brace never closed
    check nameUnfilled("nim c $") == "$"  # lone dollar
    check refusalTemplate("nim c $flags $file") ==
        "header command names `$flags`, which testament does not fill"
    check refusalTemplate(COMMAND_DEFAULT) == ""  # default of testament fills
    let runs = runsOf(FILE, Header(command: "nim c $flags $file"), COMPILER, NODE, ROOT)
    check runs.len == 1 and runs[0].refusal == refusalTemplate("nim c $flags $file")


  test "rerun joins runs of spaces outside quotes, and keeps those inside":
    check spacesJoined("nim c  --hints:on   tests/a.nim ") == "nim c --hints:on tests/a.nim"
    check spacesJoined("nim c -d:m=\"a  b\"  x") == "nim c -d:m=\"a  b\" x"  # quoted kept
    check spacesJoined("nim c '-d:a  b'  x") == "nim c '-d:a  b' x"  # single quotes too


  test "directory of run reads as path of file, backend and place, counted from one":
    check directoryOf(FILE, ROOT, Target.C, 0) == ROOT / DIRECTORY_RUNS / "tests/test_k/c_1"
    check directoryOf(FILE, ROOT, Target.JavaScript, 2) ==
        ROOT / DIRECTORY_RUNS / "tests/test_k/js_3"  # third configuration
    let outside = directoryOf("/elsewhere/test_k.nim", ROOT, Target.C, 0)
    check outside.startsWith(ROOT / DIRECTORY_RUNS / "test_k_")  # name and hash, never `..`
    check outside.endsWith("/c_1") and ".." notin outside


  test "two paths naming one file share directory, and two files of one name part":
    check absoluteOf("tests/../tests/test_k.nim", ROOT) == ROOT / FILE  # normalized
    check absoluteOf(ROOT / FILE, "/elsewhere") == ROOT / FILE  # absolute stays
    check directoryOf("./" & FILE, ROOT, Target.C, 0) == directoryOf(FILE, ROOT, Target.C, 0)
    check directoryOf(FILE, ROOT, Target.C, 0) != directoryOf("other/test_k.nim", ROOT,
        Target.C, 0)  # same name, other directory
    check directoryOf(FILE, ROOT, Target.C, 0) != directoryOf(FILE, ROOT, Target.C, 1)  # place
