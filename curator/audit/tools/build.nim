## Run one verb of audit's own, from directory of project: `system` alone, which
##   `koch list-packages curator/audit` reads, so runner installs what suites need.
##   | Verb   | Does                                                                       |
##   |--------|----------------------------------------------------------------------------|
##   | system | print packages suites need, one per line: `protoc`, which                  |
##   |        | `test_claims_log` reads each line of log of claims back with               |
##   |--------|----------------------------------------------------------------------------|
##   Exit: 0 done, 2 usage error.
##
##   Driver imports nothing past standard library, since `koch list-packages` compiles and runs
##     it before any package is restored.
##   `protoc` is for suite alone: hook writes log of claims with no `protoc`, as Architect ruled
##     on #989 (comment 7053329096).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/os


const  # TODO: Document.
  USAGE = "Usage: nim r tools/build.nim system\n"  ## Text printed on usage error.
  SYSTEM = [
    ("protobuf-compiler", "`protoc`, which `test_claims_log` reads each line of log of claims " &
      "back with"),
  ]
    ## Packages suites need, each with reason (Article II.8); `system` prints names alone.


proc main(): int =
  ## Run verb that first argument names; usage error exits 2.
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  case paramStr(1)
  of "system":
    for (package, _) in SYSTEM: echo package
    0
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
