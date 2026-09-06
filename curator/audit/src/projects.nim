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

import std/[os, osproc]
import ./findings


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


proc runIn*(dir, program: string, args: openArray[string]): int =
  ## Run program with args in directory, output streamed; return exit code.
  let process = startProcess(
    program, args = args, workingDir = dir, options = {poUsePath, poParentStreams}
  )
  result = process.waitForExit
  process.close


proc runTests*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Run testament over `tests/t*.nim` in each project, each on toolchain its pin names.
  for target in targets:
    echo "== " & target.dir
    let code = runIn(
      root / target.dir,
      target.bin.toolIn("testament"),
      ["--nim:" & target.bin.nimOf, "pattern", "tests/t*.nim"],
    )
    if code != 0:
      result.add finding(
        target.dir & "/tests", 0, "Testament failed; got exit `" & $code & "`."
      )
