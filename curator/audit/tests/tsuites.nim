discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestOutputLevel:PRINT_FAILURES $options $file"
"""
## Run every suite under `suites/` as one program, so standard library and `std/unittest`
##   compile once rather than once per suite (STYLE.md §6).
##   Suite stays own module, imported rather than included, so private helpers of two suites
##     never clash, and each still runs alone: `nim r tests/suites/t<module>.nim`.
##   Import list is read from directory at compile time, never written: suite added is run.
##   Abort define is left out, so every failing test reports in one run, not first alone.
##
##   Rejected: one testament target per suite, i.e. thirty compiles of one standard library
##     (PROVENANCE.md, Figures); same targets run in parallel, which costs twice joined time on
##     four cores and interleaves output; testament's `joinable` megatest, which `pattern`
##     never reads.
##   Cost: compile error in one suite, or exception raised outside `test`, stops every suite.

{.warning[UnusedImport]: off.}  # suite runs for effect and exports nothing

import std/[algorithm, macros, os, strutils]


macro importSuites(): untyped =
  ## Import each `suites/t*.nim`, sorted, by absolute path; relative path resolves against
  ##   `macros.nim` rather than this file.
  let dir = currentSourcePath().parentDir / "suites"
  var names: seq[string]
  for kind, name in walkDir(dir, relative = true):
    if kind == pcFile and name.startsWith("t") and name.endsWith(".nim"): names.add name
  names.sort
  result = newStmtList()
  for name in names: result.add nnkImportStmt.newTree(newLit(dir / name))


importSuites()
