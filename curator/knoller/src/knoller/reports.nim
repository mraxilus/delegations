## Define report every fixer and check of knoller emits, and fix record every fixer returns.
##   Report names rule rewritten or broken, at path and line; finding of check carries its
##     message too, ending with echoed value (Article IV.4). Caller renders both:
##     `curator/audit` cites article of each rule, so `koch fix` prints `path:line: <rule>
##     fixed` as it always has.
##   Fixer that inserts or deletes lines records input line each output line came from, and
##     `chain` traces every later report through it. So each report names line of source as
##     given, whatever fixers ran before; fixer keeping its lines records nothing.
##   Widener is fixer whose rewrite may widen its line past `LINE_MAX`: off held line it
##     rewrites freely, and wrapping that runs after it breaks line; on held line it keeps
##     width guard, i.e. refuses rewrite that makes narrow line wide. Held lines are sorted
##     `seq`, never set or table, so every reading of them runs in one order.
##
##   Cost: line `0` marks whole-file report, so `0` never means first line.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils]
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

  Held* = object  ## Define lines whose width guard holds: every line, or lines listed.
    is_every*: bool  ## Every line held, so widener writes no wide line, as fixer before it.
    lines*: seq[int]  ## One-based lines held, sorted, each once; read where not every.

  Fixer* = proc (path, source: string): Fix {.nimcall, noSideEffect.}
    ## Define fixer of one rule: source in, fixed source and its reports out.

  Widener* = proc (path, source: string; held: Held): Fix {.nimcall, noSideEffect.}
    ## Define fixer whose rewrite may widen line: free off held lines, width guard on them.

  Step* = object  ## Define one fixer of chain: guarded on every line, or widening off held lines.
    case is_widening*: bool
    of true: widener*: Widener
    of false: fixer*: Fixer


const EVERY* = Held(is_every: true)  ## Held of every line, as each widener's two-argument form.


func initReport*(path: string, line: int, rule: Rule, message = ""): Report =
  ## Construct report: rewrite where message is empty, finding of check otherwise.
  Report(path: path, line: line, rule: rule, message: message)


func guarded*(fixer: Fixer): Step =
  ## Construct step of fixer guarded on every line.
  Step(is_widening: false, fixer: fixer)


func widening*(widener: Widener): Step =
  ## Construct step of widener, which reads held lines.
  Step(is_widening: true, widener: widener)


func run*(step: Step; path, source: string; held: Held): Fix =
  ## Run step on source: widener reads held lines, guarded fixer reads none.
  if step.is_widening: step.widener(path, source, held) else: step.fixer(path, source)


func isHeld*(held: Held, line: int): bool =
  ## Decide whether one-based line keeps width guard.
  held.is_every or held.lines.binarySearch(line) >= 0


func traced*(fix: Fix, line: int): int =
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
