discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestOutputLevel:PRINT_FAILURES $options $file"
"""
## Run every suite under `suites/` as one program, so standard library and `std/unittest`
##   compile once rather than once per suite (STYLE.md §6).
##   Copy of `curator/audit/tests/test_suites.nim`, which records why stub takes this shape;
##     fix to one is finished only when other is checked (Article II.9).
##   Suite stays own module, imported rather than included, so private helpers of two suites
##     never clash, and each still runs alone: `nim r tests/suites/test_<module>.nim`.
##   Import list is read from directory at compile time, never written: suite added is run.
##   Abort define is left out, so every failing test reports in one run, not first alone.
##   Cost: compile error in one suite, or exception raised outside `test`, stops every suite.

{.warning[UnusedImport]: off.}  # suite runs for effect and exports nothing

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, macros, os, strutils]


macro importSuites(): untyped =
  ## Import each `suites/test_*.nim`, sorted, by absolute path; relative path resolves against
  ##   `macros.nim` rather than this file.
  let directory = currentSourcePath().parentDir / "suites"
  var names: seq[string]
  for kind, name in walkDir(directory, relative = true):
    if kind == pcFile and name.startsWith("test_") and name.endsWith(".nim"): names.add name
  names.sort
  result = newStmtList()
  for name in names: result.add nnkImportStmt.newTree(newLit(directory / name))


importSuites()
