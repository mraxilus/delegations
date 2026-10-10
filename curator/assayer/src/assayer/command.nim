## Run assayer from shell: `assayer [--jobs:n] [--nim:path] file...`, each test file under each
##   configuration of its testament header, all in parallel.
##   File is read whole from path as named; path naming no file is usage error. Same file named
##     twice, by any path, runs once, since two runs of one configuration would share cache.
##   Compiler of file is one `--nim` names; else one serving pin of nearest nimble file at or
##     above directory of file, from toolchain of knoller (`compilers.nim`); else `nim` on PATH,
##     which testament takes too (`compilerOf`). Pin nothing serves refuses file, and so does
##     directory holding several nimble files: no other compiler stands in silently (`GUIDE.md`,
##     Toolchain).
##   Runs go `--jobs` at once at most, by default one for each processor.
##   Output, all on stdout, in lines `reports.nim` writes: each refused file, line naming what
##     starts, each run in plan order, block of each failure, then count. Line of run prints once
##     every run before it is done, so order never varies. Log of each failed run lands on disk
##     once every run is done, so no file opens while thread starts or closes process (`runs.nim`).
##   Color goes where stdout is terminal other than `dumb`; `NO_COLOR` holding text turns it off,
##     and `FORCE_COLOR` holding text turns it on, in that order (`isColoredBy`; no-color.org,
##     force-color.org).
##   Usage error prints its reason, synopsis and pointer to `--help` on stderr, as `clap` prints
##     them; `--help` prints usage on stdout.
##   Exit: 0 every run passed; 1 run failed or file refused; 2 usage error.
##   `assay` decides what run prints and returns, so suite drives it without command line; `main`
##     reads command line, checks paths, and prints.
##
##   Cost: compile and program run from working directory, so path in header resolves against it,
##     as under testament, which koch runs from directory of project.
##   Cost: first run on pin machine lacks fetches release, or builds commit, once (`compilers.nim`).

{.experimental: "strictFuncs".}

import std/[algorithm, monotimes, options, os, osproc, parseopt, sequtils, strutils, terminal]
import ../../../knoller/src/knoller/[compilers, pins]
import ./[headers, plans, reports, runs]


const
  SYNOPSIS = "Usage: assayer [--jobs:n] [--nim:path] file..."  ## First line of usage.
  USAGE = SYNOPSIS & """


Run each test file under each configuration of its testament header, all in
parallel, and report each run.

Options:
  --jobs:n    runs at once at most; default: one for each processor
  --nim:path  compiler of every run; default: compiler of pin of nearest
              nimble file above each file, else `nim` on PATH
  --help      print this text

Exit code is 0 when every run passes, 1 when a run fails or a file is refused,
and 2 on a usage error.

Example:
  assayer tests/test_*.nim
"""
    ## Text `--help` prints.
  EXTENSION_NIMBLE = ".nimble"  ## Extension of nimble file, which names pin of its directory.


type Options* = object  ## Define parsed command line.
  jobs*: int  ## Runs at once at most; zero: one for each processor.
  nim*: string  ## Compiler of every run; empty: compiler of pin of each file.
  paths*: seq[string]  ## Test files, in order given.
  is_help*: bool  ## `--help` asks for usage alone.


proc parseOptions*(arguments: openArray[string]): tuple[options: Options, failure: string] =
  ## Parse command line; failure says what is wrong, empty where nothing is.
  var parser = initOptParser(@arguments)
  for kind, key, value in parser.getopt():
    case kind
    of cmdArgument: result.options.paths.add key
    of cmdLongOption, cmdShortOption:
      if key in ["help", "h"] and value.len == 0: result.options.is_help = true
      elif key == "nim" and value.len > 0: result.options.nim = value
      elif key == "nim": return (result.options, "`--nim` takes the path of a compiler")
      elif key == "jobs":
        result.options.jobs =
          try: value.parseInt
          except ValueError: 0
        if result.options.jobs < 1:
          return (result.options, "`--jobs` takes a positive whole number, not `" & value & "`")
      else:
        let spelled = (if kind == cmdLongOption: "--" else: "-") & key &
            (if value.len > 0: ":" & value else: "")
        return (result.options, "unknown option `" & spelled & "`")
    of cmdEnd: break
  if result.options.paths.len == 0 and not result.options.is_help:
    result.failure = "name at least one test file"


func isColoredBy*(no_color, force_color, term: string; is_terminal: bool): bool =
  ## Decide whether report takes color: not where `NO_COLOR` holds text, yes where `FORCE_COLOR`
  ##   does, else where stdout is terminal other than `dumb`.
  if no_color.len > 0: return false
  if force_color.len > 0: return true
  term != "dumb" and is_terminal


proc compilerOf*(path, nim: string; toolchains: var Toolchains): tuple[compiler, refusal: string] =
  ## Read compiler of test file at path: one `nim` names, else one serving pin of nearest nimble
  ##   file at or above its directory, else `nim` on PATH; refusal says why none serves.
  ##   Nimble file naming no exact pin takes `nim` on PATH, as knoller takes it.
  if nim.len > 0: return (nim.absolutePath.addFileExt(ExeExt), "")
  var directory = path.absolutePath.parentDir
  while true:
    var nimbles: seq[string]
    for kind, entry in walkDir(directory):
      let name = entry.extractFilename
      if kind in {pcFile, pcLinkToFile} and name.len > EXTENSION_NIMBLE.len and
          name.endsWith(EXTENSION_NIMBLE):
        nimbles.add name
    if nimbles.len > 1:
      let names = nimbles.sorted.mapIt("`" & it & "`")
      return ("", "`" & directory & "` holds " & names[0..^2].join(", ") & " and " & names[^1] &
          ", so no pin is trusted")
    if nimbles.len == 1:
      let pin = readFile(directory / nimbles[0]).pinNim
      if pin.isSome:
        let bin = toolchains.binFor(pin.get)
        if bin.isNone:
          return ("", "no compiler serves pin `" & pin.get & "` of `" & nimbles[0] & "`")
        if bin.get.len > 0: return ((bin.get / NIM).addFileExt(ExeExt), "")
      break
    let parent = directory.parentDir
    if parent.len == 0 or parent == directory: break
    directory = parent
  let found = findExe(NIM)
  if found.len == 0: ("", "no `nim` on PATH") else: (found, "")


proc nodeOnPath(): string =
  ## Read Node.js on PATH, as `nodejs`, else `node`, which testament seeks in that order; empty
  ##   where neither stands.
  result = findExe("nodejs")
  if result.len == 0: result = findExe("node")


proc assay*(options: Options, write: proc(line: string), as_color = false): int =
  ## Run each test file options name, from working directory, writing each line of report through
  ##   `write`; return exit code.
  let started = getMonoTime()
  var
    toolchains = initToolchains()
    runs: seq[Run]
    seen: seq[string]
    files = 0
    refused = 0
  let (root, node) = (getCurrentDir(), nodeOnPath())

  # Plan runs of each file once, refusing file whose header, template or compiler cannot serve.
  for path in options.paths:
    let absolute = path.absoluteOf(root)
    if absolute in seen: continue
    seen.add absolute
    let header = readFile(path).headerOf
    var (compiler, refusal) = ("", header.refusal)
    if refusal.len == 0: refusal = header.command.refusalTemplate
    if refusal.len == 0: (compiler, refusal) = path.compilerOf(options.nim, toolchains)
    if refusal.len > 0:
      write lineRefusal(path, refusal, root, as_color)
      inc refused
      continue
    inc files
    runs.add runsOf(path, header, compiler, node, root)

  # Make every run, writing line of each in plan order.
  let jobs = if options.jobs > 0: options.jobs else: max(1, countProcessors())
  if runs.len > 0: write lineStart(runs.len, files, countThreads(jobs, runs.len))
  let
    widths = runs.widthsOf(root)
    outcomes = runs.runAll(jobs) do (place: int, outcome: Outcome):
      write lineRun(runs[place], outcome, widths, root, as_color)

  # Write log of each failure now no thread runs, then its block, then count.
  var failed = 0
  for place, run in runs:
    if run.failureOf(outcomes[place]).len == 0: continue
    inc failed
    if run.refusal.len == 0:
      createDir(run.logOf.parentDir)
      writeFile(run.logOf, outcomes[place].textLog)
    write ""
    for line in linesFailure(run, outcomes[place], root, as_color): write line
  write ""
  write lineSummary(runs.len, failed, refused, getMonoTime() - started, as_color)
  if failed > 0 or refused > 0: 1 else: 0


proc main*(): int =
  ## Run each test file command line names; print report; return exit code.
  let (options, failure) = parseOptions(commandLineParams())
  if options.is_help:
    stdout.write USAGE
    return 0
  let
    missing = options.paths.filterIt(not fileExists(it))
    problem =
      if failure.len > 0: failure
      elif missing.len > 0: "no file at `" & missing[0] & "`"
      else: ""
  if problem.len > 0:
    stderr.write "error: " & problem & "\n\n" & SYNOPSIS & "\n\nFor more, try `--help`.\n"
    return 2
  let is_colored = isColoredBy(
    getEnv("NO_COLOR"),
    getEnv("FORCE_COLOR"),
    getEnv("TERM"),
    stdout.isatty,
  )
  options.assay(
    proc(line: string) =
      stdout.writeLine line
      stdout.flushFile,
    as_color = is_colored,
  )
