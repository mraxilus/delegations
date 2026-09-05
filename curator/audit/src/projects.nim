## Drive every project's tests through testament (Article IX.6) and run tools in projects.
##   One verb per project: `testament pattern "tests/t*.nim"` in project directory, with
##   compiler named by absolute path so testament resolves it from any cwd. Output streams
##   through untouched; failure becomes finding at project's tests directory.
##   Rejected: per-project build file (make, config.nims), which repeats one line per
##     project and adds second toolchain or compiler-VM glue; koch holds verb once.
##
##   Cost: projects run serially; parallelism waits until it costs minutes, unmeasured.
##   Cost: project in other language needs its own runner arm here (none exists yet).

{.experimental: "strictFuncs".}

import std/[os, osproc]
import ./findings


proc runIn*(dir, program: string, args: openArray[string]): int =
  ## Run program with args in directory, output streamed; return exit code.
  let process = startProcess(
    program, args = args, workingDir = dir, options = {poUsePath, poParentStreams}
  )
  result = process.waitForExit
  process.close


proc runTests*(root: string, dirs: openArray[string]): seq[Finding] =
  ## Run testament over `tests/t*.nim` in each project directory, reporting failures.
  let nim = findExe("nim")
  for dir in dirs:
    echo "== " & dir
    let code = runIn(root / dir, "testament", ["--nim:" & nim, "pattern", "tests/t*.nim"])
    if code != 0:
      result.add finding(dir & "/tests", 0, "Testament failed; got exit `" & $code & "`.")
