## Drive every project's tests through testament (Article IX.6) and run tools in projects.
##   One verb per project: `testament pattern "tests/t*.nim"` in project directory, with
##   compiler named by absolute path so testament resolves it from any cwd. Output streams
##   through untouched; failure becomes finding at project's tests directory.
##   Rejected: per-project build file (make, config.nims), which repeats one line per
##     project and adds second toolchain or compiler-VM glue; koch holds verb once.
##
##   Each project carries `Target`, i.e. its directory and `bin` of toolchain serving its
##     pin. Tools come from that `bin`, never from PATH: two projects on two pins would
##     otherwise share one compiler silently, which is defect this replaced. Empty `bin`
##     names PATH, which is what CI installs per job.
##   Testament and Atlas come from same `bin` as compiler, since each Nim ships its own and
##     Atlas records compiler it ran under; mixing them reports environment mismatch.
##
##   Cost: projects run serially; parallelism waits until it costs minutes, unmeasured.
##   Cost: project in other language needs its own runner arm here (none exists yet).

{.experimental: "strictFuncs".}

import std/[os, osproc, strtabs]
import ./findings


const
  DRIVER_FILE* = "tools/build.nim"
    ## Build driver project carries, holding verbs koch has none of.
  TYPES_VERB* = "types"
    ## Verb type-checking project's own scripts, deriving what they read first, and
    ## stopping before anything needing browser. Named here and in CONTRIBUTOR.md.


type Target* = object
  ## Define one project to run, with toolchain serving its pin.
  dir*: string  ## Project directory, repository-relative.
  bin*: string  ## Directory holding compiler and its tools; empty names PATH.


func toolOf*(bin, tool: string): string =
  ## Read path tool would have inside toolchain; bare name when `bin` names PATH.
  if bin.len == 0: tool else: bin / tool


proc toolIn*(bin, tool: string): string =
  ## Read program to run for tool, falling back to PATH when toolchain carries none.
  ##   Source build carries whatever `koch tools` produced, and that set moves between
  ##   Nim versions; naming absent file would raise rather than report, and PATH tool
  ##   still works, announcing its own mismatch where one matters.
  let path = bin.toolOf(tool)
  if bin.len == 0 or fileExists(path): path else: tool


proc nimOf*(bin: string): string =
  ## Read compiler path testament must be told, absolute so any cwd resolves it.
  if bin.len == 0: findExe("nim") else: bin / "nim"


proc childEnv(bin: string): StringTableRef =
  ## Build environment putting toolchain first on PATH; `nil` inherits this process's own.
  ##   Naming tool by path is not enough: Atlas resolves `nim` through PATH, so toolchain's
  ##   own Atlas still reads whichever compiler PATH holds and reports environment mismatch
  ##   against lock (measured 2026-09-06, same Atlas warning appearing under one PATH and
  ##   silent under other).
  if bin.len == 0: return nil
  result = newStringTable(modeCaseSensitive)
  for key, value in envPairs(): result[key] = value
  result["PATH"] = bin & PathSep & getEnv("PATH")


proc runIn*(dir, program: string, args: openArray[string], bin = ""): int =
  ## Run program with args in directory, output streamed; return exit code.
  ##   Toolchain `bin` leads child's PATH, so tools it shells out to are its own.
  let process = startProcess(
    program, args = args, workingDir = dir, env = childEnv(bin),
    options = {poUsePath, poParentStreams},
  )
  result = process.waitForExit
  process.close


proc runTypes*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Type-check each project's own scripts, through build driver that project carries.
  ##   Verb is project's, never koch's: what type-checking needs differs per project, and
  ##   driver already derives its declarations first. koch names verb and nothing else.
  for target in targets:
    echo "== " & target.dir
    let code = runIn(
      root / target.dir,
      target.bin.nimOf,
      ["r", "--hints:off", DRIVER_FILE, TYPES_VERB],
      target.bin,
    )
    if code != 0:
      result.add finding(
        target.dir & "/" & DRIVER_FILE, 0,
        "Type check failed; got exit `" & $code & "`.",
      )


proc runTests*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Run testament over `tests/t*.nim` in each project, each on toolchain its pin names.
  for target in targets:
    echo "== " & target.dir
    let code = runIn(
      root / target.dir,
      target.bin.toolIn("testament"),
      ["--nim:" & target.bin.nimOf, "pattern", "tests/t*.nim"],
      target.bin,
    )
    if code != 0:
      result.add finding(
        target.dir & "/tests", 0, "Testament failed; got exit `" & $code & "`."
      )
