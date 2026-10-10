## Run each test file under each configuration of its testament header, all in parallel; library
##   umbrella.
##   Testament runs configurations of one file one after another, and in parallel only across
##     category directories, under `testament all`; so project kept directory for each
##     configuration to run them at once. Assayer runs every configuration of every file at once,
##     each its own compile, with its own cache.
##   Header reads as testament reads it (`headers.nim`), command builds as testament builds it
##     (`plans.nim`), and verdict falls as testament gives it (`runs.nim`), so file passing here
##     passes there.
##   Compiler of each pin comes from toolchain of knoller (`compilers.nim`), which serves each pin
##     from PATH, cache or fetch; package imports knoller by relative path, as `curator/audit` does.
##   Command line, `assayer [--jobs:n] [--nim:path] file...`, lives in `command.nim`; umbrella
##     runs it as program and exports none of it, since library caller needs none.
##
##   Cost: import of sibling by path makes package one no install carries alone, and pins its
##     compiler to pin of knoller.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import ./assayer/[command, headers, plans, runs]

export headers, plans, runs


when isMainModule:
  quit main()
