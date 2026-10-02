## Define finding record every check emits, plus its order and report form; and fix record
##   every fixer returns, which reports each rewrite in that same form.
##   One record shape keeps umbrella trivial: collect, sort, print, count.
##   Message convention (Article IV.4): end by echoing offending value in backticks.
##   Fix reports rewrite as finding whose message names rule alone, so `koch fix` prints
##     `path:line: <rule> fixed` through `render`, as check prints its own, and its dry run
##     prints `path:line: <rule> to fix` from same report.
##   Fixer that inserts or deletes lines records input line each output line came from, and
##     `chain` traces every later report through it. So each report names line of source as
##     given, whatever fixers ran before; fixer keeping its lines records nothing.
##
##   Cost: line `0` marks whole-file findings, so `0` never means first line.
##   Cost: empty path marks branch-level findings (scope, commits) with no file to open.
##   Propagation flag marks finding that rules change leaves for curator wherever it lands,
##     such as stale stamp in contributor record; `scope.isHeld` never holds it.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils]


type
  Finding* = object  ## Define one rule violation located at path and line.
    path*: string  ## Repository-relative path, `/` separated; empty for branch-level.
    line*: int  ## One-based line; `0` when finding concerns whole file.
    message*: string  ## Telegraphic statement, ending with echoed value where one exists.
    is_propagation*: bool  ## Curator's to fix wherever it lands: rules change carried out.

  Fix* = object  ## Define source fixer returns, with one report per rewrite.
    source*: string  ## Text after fix; input itself where nothing broke rule.
    fixed*: seq[Finding]  ## Path and line of input rewritten, message naming rule fixed.
    origin*: seq[int]  ## Input line of each output line, `0` where inserted; empty if none moved.

  Fixer* = proc (path, source: string): Fix {.nimcall, noSideEffect.}
    ## Define fixer of one rule: source in, fixed source and its reports out.


func finding*(path: string, line: int, message: string, is_propagation = false): Finding =
  ## Construct finding.
  Finding(path: path, line: line, message: message, is_propagation: is_propagation)


func traced(fix: Fix, line: int): int =
  ## Read input line that output line of fix came from; `0` stays whole file or inserted line.
  if line == 0 or fix.origin.len == 0: line else: fix.origin[line - 1]


func chain*(fix, step: Fix): Fix =
  ## Chain fixer's step after fix: step's source, reports of both traced to fix's input.
  result.source = step.source
  result.fixed = fix.fixed
  for f in step.fixed:
    var traced_finding = f
    traced_finding.line = fix.traced(f.line)
    result.fixed.add traced_finding
  result.origin =
    if step.origin.len == 0: fix.origin
    else: step.origin.mapIt(fix.traced(it))


func `<`*(a, b: Finding): bool =
  ## Order findings by path, then line, then message, so reports are stable.
  if a.path != b.path: return a.path < b.path
  if a.line != b.line: return a.line < b.line
  a.message < b.message


func render*(f: Finding): string =
  ## Render finding as `path:line: message`; line omitted when `0`, path when empty.
  if f.path.len == 0: return f.message
  let location = if f.line == 0: f.path else: f.path & ":" & $f.line
  location & ": " & f.message


proc report*(findings: seq[Finding]) =
  ## Print findings sorted, one per line, then count.
  for f in findings.sorted: echo f.render
  echo $findings.len & " finding(s)."
