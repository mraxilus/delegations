## Replicate command line of `command.nim`: options, compiler of each file, and report of real
##   runs through compiler that built suite.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, tempfiles, unittest]
import ../../src/assayer/[command, headers, plans, runs]
import ../../../knoller/src/knoller/compilers


const
  QUOTES = "\"\"\""  ## Triple quote closing header, and opening it after `discard `.
  PIN_FAKE = "9.9.9"  ## Pin compiler cached by suite serves, which no release names.
  SOURCE_MATRIX =
      "discard " & QUOTES & "\naction: run\ncmd: \"nim c --hints:off $options $file\"\n" &
      "matrix: \"-d:k=1; -d:k=2; -d:k=3\"\n" & QUOTES & "\n" &
      "const k {.intdefine.}: int = 0\ndoAssert k != 2, \"k is two\"\n"
    ## Test file of three configurations, second of which fails its assertion.
  SOURCE_REFUSED = "discard " & QUOTES & "\nexitcode: 1\n" & QUOTES & "\necho 1\n"
    ## Test file whose header gives key assayer does not read.


proc assayed(options: Options, directory: string): tuple[lines: seq[string], code: int] =
  ## Run `assay` from directory, collecting each line it writes; return lines and exit code.
  let previous = getCurrentDir()
  setCurrentDir(directory)
  defer: setCurrentDir(previous)
  var lines: seq[string]
  let code = options.assay do (line: string): lines.add line
  (lines, code)



suite "Command line":
  test "file is required, `--jobs` positive whole number, and other option usage error":
    check parseOptions(["a.nim"]).get.paths == @["a.nim"]  # file alone
    let options = parseOptions(["--nim:/x/nim", "--jobs:4", "a.nim", "b.nim"]).get
    check options.nim == "/x/nim" and options.jobs == 4  # both options
    check options.paths == @["a.nim", "b.nim"]  # files in order given
    check parseOptions([]).isNone  # no file
    check parseOptions(["--jobs:0", "a.nim"]).isNone  # not positive
    check parseOptions(["--jobs:x", "a.nim"]).isNone  # not number
    check parseOptions(["--jobs:99999999999999999999", "a.nim"]).isNone  # past `int`
    check parseOptions(["--nim", "a.nim"]).isNone  # option lacking value
    check parseOptions(["--check", "a.nim"]).isNone  # unknown option


  test "compiler is one named, else pin of nearest nimble file, else `nim` on PATH":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    createDir(directory / "tests")
    let file = directory / "tests" / "test_k.nim"
    var toolchains = initToolchains(directory / "cache", some(Compiler(version: NimVersion)))
    check compilerOf(file, "bin/nim", toolchains) ==
        ((getCurrentDir() / "bin/nim").addFileExt(ExeExt), "")  # named, made absolute
    check compilerOf(file, "", toolchains) == (findExe("nim"), "")  # no nimble file above
    writeFile(directory / "k.nimble", "requires \"nim == " & NimVersion & "\"\n")
    check compilerOf(file, "", toolchains) == (findExe("nim"), "")  # pin PATH serves
    writeFile(directory / "k.nimble", "requires \"nim >= 2.0.0\"\n")
    check compilerOf(file, "", toolchains) == (findExe("nim"), "")  # range names no pin
    writeFile(directory / "l.nimble", "requires \"nim == " & NimVersion & "\"\n")
    check compilerOf(file, "", toolchains) == ("", "Directory holds several nimble files, " &
        "so no pin is trusted; got `" & directory & "`.")  # nimble refuses such directory


  test "pin cache of knoller serves is compiler of file":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    let bin = binOf(directory / "cache", PIN_FAKE)
    createDir(bin)
    writeFile(bin / "nim", "#!/bin/sh\necho 'Nim Compiler Version " & PIN_FAKE & " [Linux]'\n")
    setFilePermissions(bin / "nim", {fpUserExec, fpUserRead, fpUserWrite})
    writeFile(directory / "k.nimble", "requires \"nim == " & PIN_FAKE & "\"\n")
    var toolchains = initToolchains(directory / "cache", some(Compiler(version: NimVersion)))
    check compilerOf(directory / "test_k.nim", "", toolchains) == (bin / "nim", "")  # cached


  test "report names file, backend and configuration, then failure with command and output":
    let
      passed = Run(file: "t.nim", target: Target.C)
      failed = Run(file: "t.nim", target: Target.JavaScript, configuration: "-d:x",
          action: Action.Run)
      program = Step(command: "node t.js", output: "line 1\nline 2\n", code: 1)
    check passed.lineOf == "t.nim c"  # no configuration
    check failed.lineOf == "t.nim js `-d:x`"  # configuration in backticks
    check passed.linesOf(Outcome(execution: some(Step()))) == @["t.nim c: passed"]
    check failed.linesOf(Outcome(execution: some(program))) == @[
      "t.nim js `-d:x`: failed: Program exits 1.",
      "  $ node t.js",
      "  line 1",
      "  line 2",
    ]  # step that failed, indented
    check Run(file: "t.nim", refusal: "No Node.js.").linesOf(Outcome()) ==
        @["t.nim c: failed: No Node.js."]  # nothing ran, so no command
    check summaryOf(1, 0, 0) == "1 run: 1 passed, 0 failed."  # singular
    check summaryOf(3, 1, 1) == "3 runs: 2 passed, 1 failed; 1 file refused."  # refused counted
    check summaryOf(0, 0, 2) == "0 runs: 0 passed, 0 failed; 2 files refused."  # plural


  test "real runs report in plan order, refused file first, each file once, exit 1 on failure":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    let (matrix, refused) = (directory / "test_k.nim", directory / "test_refused.nim")
    writeFile(matrix, SOURCE_MATRIX)
    writeFile(refused, SOURCE_REFUSED)
    let
      options = Options(
        jobs: 3,
        nim: getCurrentCompilerExe(),
        paths: @[refused, matrix, directory / "." / "test_k.nim"],
      )
      (lines, code) = options.assayed(directory)
    check lines[0] == refused & ": refused: Header gives key assayer does not read; got `exitcode`."
    check lines[1] == matrix & " c `-d:k=1`: passed"  # plan order
    check lines[2] == matrix & " c `-d:k=2`: failed: Program exits 1."  # its assertion
    check lines[3].startsWith("  $ " & directory / DIRECTORY_RUNS / "test_k_c_1_")  # program
    check lines.anyIt(it.startsWith("  ") and "k is two" in it)  # its output, indented
    check lines[^2] == matrix & " c `-d:k=3`: passed"  # last run, once
    check lines[^1] == "3 runs: 2 passed, 1 failed; 1 file refused."  # duplicate path ran once
    check code == 1  # failure and refusal


  test "real runs that all pass exit 0, each in cache of its own":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    let file = directory / "test_k.nim"
    writeFile(file, SOURCE_MATRIX.replace("-d:k=1; -d:k=2; -d:k=3", "-d:k=1; -d:k=3"))
    let (lines, code) = Options(nim: getCurrentCompilerExe(), paths: @[file]).assayed(directory)
    check lines == @[file & " c `-d:k=1`: passed", file & " c `-d:k=3`: passed",
        "2 runs: 2 passed, 0 failed."]  # every run passed
    check code == 0  # clean
    check dirExists(directoryOf(file, directory, Target.C, 0))  # cache of first
    check dirExists(directoryOf(file, directory, Target.C, 1))  # cache of second
