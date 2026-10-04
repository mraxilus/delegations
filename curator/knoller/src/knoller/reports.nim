## Define report every fixer and check of knoller emits, and fix record every fixer returns.
##   Report names rule rewritten or broken, at path and line; finding of check carries its
##     message too, ending with echoed value (Article IV.4). Caller renders both:
##     `curator/audit` cites article of each rule, so `koch fix` prints `path:line: <rule>
##     fixed` as it always has.
##   Fixer that inserts or deletes lines records input line each output line came from, and
##     `chain` traces every later report through it. So each report names line of source as
##     given, whatever fixers ran before; fixer keeping its lines records nothing.
##
##   Cost: line `0` marks whole-file report, so `0` never means first line.

{.experimental: "strictFuncs".}

import std/sequtils
import ./rules

export rules


type
  Report* = object  ## Define one rewrite or finding, located at path and line.
    path*: string  ## Repository-relative path, `/` separated.
    line*: int  ## One-based line; `0` when report concerns whole file.
    rule*: Rule  ## Rule rewritten or broken.
    message*: string  ## Finding's statement, ending with echoed value; empty for rewrite.

  Fix* = object  ## Define source fixer returns, with one report per rewrite.
    source*: string  ## Text after fix; input itself where nothing broke rule.
    fixed*: seq[Report]  ## Path and line of input rewritten, with rule fixed.
    origin*: seq[int]  ## Input line of each output line, `0` where inserted; empty if none moved.

  Fixer* = proc (path, source: string): Fix {.nimcall, noSideEffect.}
    ## Define fixer of one rule: source in, fixed source and its reports out.


func initReport*(path: string, line: int, rule: Rule, message = ""): Report =
  ## Construct report: rewrite where message is empty, finding of check otherwise.
  Report(path: path, line: line, rule: rule, message: message)


func traced(fix: Fix, line: int): int =
  ## Read input line that output line of fix came from; `0` stays whole file or inserted line.
  if line == 0 or fix.origin.len == 0: line else: fix.origin[line - 1]


func chain*(fix, step: Fix): Fix =
  ## Chain fixer's step after fix: step's source, reports of both traced to fix's input.
  result.source = step.source
  result.fixed = fix.fixed
  for f in step.fixed:
    var traced_report = f
    traced_report.line = fix.traced(f.line)
    result.fixed.add traced_report
  result.origin =
    if step.origin.len == 0: fix.origin
    else: step.origin.mapIt(fix.traced(it))
