## Replicate command line of `command.nim`: options, color, compiler of each file, and report of
##   real runs through compiler that built suite.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, tempfiles, unittest]
import ../../src/assayer/[command, headers, plans]
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
  WORDS_ENVIRONMENT = ["", "1"]  ## Values of `NO_COLOR` and `FORCE_COLOR` law enumerates.
  TERMS = ["xterm-256color", "dumb"]  ## Values of `TERM` law enumerates.


proc assayed(options: Options, directory: string): tuple[lines: seq[string], code: int] =
  ## Run `assay` from directory, collecting each line it writes; return lines and exit code.
  let previous = getCurrentDir()
  setCurrentDir(directory)
  defer: setCurrentDir(previous)
  var lines: seq[string]
  let code = options.assay(proc(line: string) = lines.add line)
  (lines, code)



suite "Command line":
  test "file is required, `--jobs` positive whole number, and each usage error says what":
    check parseOptions(["a.nim"]) == (Options(paths: @["a.nim"]), "")  # file alone
    let (options, failure) = parseOptions(["--nim:/x/nim", "--jobs:4", "a.nim", "b.nim"])
    check failure == "" and options.nim == "/x/nim" and options.jobs == 4  # both options
    check options.paths == @["a.nim", "b.nim"]  # files in order given
    check parseOptions([]).failure == "name at least one test file"
    check parseOptions(["--jobs:0", "a.nim"]).failure ==
        "`--jobs` takes a positive whole number, not `0`"
    check parseOptions(["--jobs:x", "a.nim"]).failure.endsWith("not `x`")  # not number
    check parseOptions(["--jobs:99999999999999999999", "a.nim"]).failure.startsWith("`--jobs`")
    check parseOptions(["--nim", "a.nim"]).failure == "`--nim` takes the path of a compiler"
    check parseOptions(["--check", "a.nim"]).failure == "unknown option `--check`"
    check parseOptions(["-x:1", "a.nim"]).failure == "unknown option `-x:1`"  # value kept


  test "help asks for usage alone, with or without file":
    check parseOptions(["--help"]) == (Options(is_help: true), "")  # no file needed
    check parseOptions(["-h", "a.nim"]).options.is_help  # short form


  test "color goes where stdout is terminal, unless `NO_COLOR`, or `FORCE_COLOR` asks for it":
    for no_color in WORDS_ENVIRONMENT:
      for force_color in WORDS_ENVIRONMENT:
        for term in TERMS:
          for is_terminal in [false, true]:
            let is_colored =
              if no_color.len > 0: false
              elif force_color.len > 0: true
              else: term != "dumb" and is_terminal
            check isColoredBy(no_color, force_color, term, is_terminal) == is_colored


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
    check compilerOf(file, "", toolchains) == ("", "`" & directory & "` holds `k.nimble` and " &
        "`l.nimble`, so no pin is trusted")  # nimble refuses such directory


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


  test "real runs report refusal, start, each run in plan order, failure, then count":
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
      log = directoryOf(matrix, directory, Target.C, 1) / FILE_LOG
    check lines[0] == "error: test_refused.nim: header key `exitcode` is not read; assayer " &
        "reads `action`, `cmd`, `matrix` and `targets`"  # refused file, path relative
    check lines[1] == "Starting 3 runs of 1 file, 3 at once"  # duplicate path runs once
    for (line, status, configuration) in [
      (lines[2], "PASS", "-d:k=1"),
      (lines[3], "FAIL", "-d:k=2"),
      (lines[4], "PASS", "-d:k=3"),
    ]:
      check line.startsWith(status & "  ")  # status first
      check line[6..<11].strip.endsWith("s")  # duration, right-aligned
      check line.endsWith("  test_k.nim  c  " & configuration)  # plan order
    check lines[5..6] == @["", "FAIL test_k.nim c -d:k=2: program exits 1"]  # block of failure
    check lines.anyIt(it.startsWith("    ") and "k is two" in it)  # excerpt, indented
    check "  rerun: nimcache/assayer/test_k/c_2/test_k" in lines  # program reruns as it ran
    check "  log: nimcache/assayer/test_k/c_2/output.log" in lines  # log, path relative
    check readFile(log).startsWith("$ ") and "k is two" in readFile(log)  # whole output on disk
    check lines[^2] == ""  # count stands apart
    check lines[^1].startsWith("3 runs in ") and lines[^1].endsWith(": 2 passed, 1 failed; " &
        "1 file refused")  # count closes report
    check code == 1  # failure and refusal


  test "real runs that all pass exit 0, each in cache of its own, and write no log":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    let file = directory / "test_k.nim"
    writeFile(file, SOURCE_MATRIX.replace("-d:k=1; -d:k=2; -d:k=3", "-d:k=1; -d:k=3"))
    let (lines, code) = Options(nim: getCurrentCompilerExe(), paths: @[file]).assayed(directory)
    check lines.len == 5 and lines[0].startsWith("Starting 2 runs of 1 file, ")  # no failure
    check lines[1].startsWith("PASS") and lines[2].startsWith("PASS")  # every run passed
    check lines[3] == "" and lines[4].endsWith(": 2 passed")  # count alone, no block
    check code == 0  # clean
    for place in 0..1:
      check dirExists(directoryOf(file, directory, Target.C, place))  # cache of each
      check not fileExists(directoryOf(file, directory, Target.C, place) / FILE_LOG)  # no log
