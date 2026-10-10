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
##   Output: each file refused as `path: refused: <message>`; then each run in plan order, as
##     `path <backend> `<configuration>`: passed`, or `failed: <message>`, with command and output
##     of step that failed under it, indented (`linesOf`); then count (`summaryOf`). Line of run
##     prints once every run before it is done, so order never varies.
##   Exit: 0 every run passed; 1 run failed or file refused; 2 usage error.
##   `assay` decides what run prints and returns, so suite drives it without command line; `main`
##     reads command line, checks paths, and prints.
##
##   Cost: compile and program run from working directory, so path in header resolves against it,
##     as under testament, which koch runs from directory of project.
##   Cost: first run on pin machine lacks fetches release, or builds commit, once (`compilers.nim`).

{.experimental: "strictFuncs".}

import std/[options, os, osproc, parseopt, sequtils, strutils]
import ../../../knoller/src/knoller/[compilers, pins]
import ./[headers, plans, runs]


const
  USAGE = """
Usage: assayer [--jobs:n] [--nim:path] file...

Run each test file under each configuration of its testament header, all in
parallel.

Options:
  --jobs:n    runs at once at most; default: one for each processor
  --nim:path  compiler of every run; default: compiler of pin of nearest
              nimble file above each file, else `nim` on PATH
"""
    ## Text printed on usage error.
  EXTENSION_NIMBLE = ".nimble"  ## Extension of nimble file, which names pin of its directory.
  INDENT = "  "  ## Indent of each line report prints under failed run.


type Options* = object  ## Define parsed command line.
  jobs*: int  ## Runs at once at most; zero: one for each processor.
  nim*: string  ## Compiler of every run; empty: compiler of pin of each file.
  paths*: seq[string]  ## Test files, in order given.


proc parseOptions*(arguments: openArray[string]): Option[Options] =
  ## Parse command line; `none` on unknown option, option lacking value, `--jobs` other than
  ##   positive whole number, or no file.
  var
    options = Options()
    parser = initOptParser(@arguments)
  for kind, key, value in parser.getopt():
    case kind
    of cmdArgument: options.paths.add key
    of cmdLongOption, cmdShortOption:
      if key == "nim" and value.len > 0: options.nim = value
      elif key == "jobs" and value.len > 0 and value.allCharsInSet(Digits):
        options.jobs =
          try: value.parseInt
          except ValueError: 0
        if options.jobs < 1: return none(Options)
      else: return none(Options)
    of cmdEnd: break
  if options.paths.len == 0: none(Options) else: some(options)


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
        nimbles.add entry
    if nimbles.len > 1:
      return ("", "Directory holds several nimble files, so no pin is trusted; got `" &
          directory & "`.")
    if nimbles.len == 1:
      let pin = readFile(nimbles[0]).pinNim
      if pin.isSome:
        let bin = toolchains.binFor(pin.get)
        if bin.isNone: return ("", "No compiler serves pin `" & pin.get & "`.")
        if bin.get.len > 0: return ((bin.get / NIM).addFileExt(ExeExt), "")
      break
    let parent = directory.parentDir
    if parent.len == 0 or parent == directory: break
    directory = parent
  let found = findExe(NIM)
  if found.len == 0: ("", "No `nim` on PATH.") else: (found, "")


proc nodeOnPath(): string =
  ## Read Node.js on PATH, as `nodejs`, else `node`, which testament seeks in that order; empty
  ##   where neither stands.
  result = findExe("nodejs")
  if result.len == 0: result = findExe("node")


func lineOf*(run: Run): string =
  ## Read how report names run: file and backend, then configuration in backticks where it has one.
  result = run.file & " " & $run.target
  if run.configuration.len > 0: result.add " `" & run.configuration & "`"


func linesOf*(run: Run, outcome: Outcome): seq[string] =
  ## Read lines report prints for run: verdict, then command and output of step that failed, each
  ##   indented.
  ##   Step that failed is program where it ran, since program runs only after clean compile.
  let failure = run.failureOf(outcome)
  if failure.len == 0: return @[run.lineOf & ": passed"]
  result.add run.lineOf & ": failed: " & failure
  let step = outcome.execution.get(outcome.compile)
  if step.command.len == 0: return
  result.add INDENT & "$ " & step.command
  if step.output.len == 0: return
  for line in step.output.strip(leading = false).splitLines: result.add INDENT & line


func summaryOf*(runs, failed, refused: int): string =
  ## Read last line of report: count of runs, passed and failed, then of files refused where any.
  result = $runs & (if runs == 1: " run: " else: " runs: ") & $(runs - failed) & " passed, " &
      $failed & " failed"
  if refused > 0:
    result.add "; " & $refused & (if refused == 1: " file" else: " files") & " refused"
  result.add "."


proc assay*(options: Options, write: proc(line: string)): int =
  ## Run each test file options name, from working directory, writing each line of report through
  ##   `write`; return exit code.
  var
    toolchains = initToolchains()
    runs: seq[Run]
    seen: seq[string]
    refused = 0
  let (root, node) = (getCurrentDir(), nodeOnPath())

  # Plan runs of each file once, refusing file whose header or compiler cannot serve.
  for path in options.paths:
    let absolute = path.absoluteOf(root)
    if absolute in seen: continue
    seen.add absolute
    let header = readFile(path).headerOf
    if header.refusal.len > 0:
      write path & ": refused: " & header.refusal
      inc refused
      continue
    let (compiler, refusal) = path.compilerOf(options.nim, toolchains)
    if refusal.len > 0:
      write path & ": refused: " & refusal
      inc refused
      continue
    runs.add runsOf(path, header, compiler, node, root)

  # Make every run, writing each in plan order, then count.
  let
    jobs = if options.jobs > 0: options.jobs else: max(1, countProcessors())
    outcomes = runs.runAll(jobs) do (place: int, outcome: Outcome):
      for line in linesOf(runs[place], outcome): write line
    failed = toSeq(0..<runs.len).countIt(runs[it].failureOf(outcomes[it]).len > 0)
  write summaryOf(runs.len, failed, refused)
  if failed > 0 or refused > 0: 1 else: 0


proc main*(): int =
  ## Run each test file command line names; print report; return exit code.
  let options = parseOptions(commandLineParams())
  if options.isNone:
    stderr.write USAGE
    return 2
  for path in options.get.paths:
    if fileExists(path): continue
    stderr.write "Path names no file; got `" & path & "`.\n"
    stderr.write USAGE
    return 2
  options.get.assay do (line: string):
    stdout.writeLine line
    stdout.flushFile
