## Read fence of Nim source (Article X.1), so fixers leave its lines as written.
##   Line `#!fix off` opens fence, line `#!fix on` closes it, each marker
##     alone on its line as comment; fence left open runs to end of file. Fixers never write
##     lines of fence, markers included, and layout checks report nothing there. Each fenced
##     line reads as whole-line comment `FENCED` at its own indent while fixers run, so call,
##     signature or list holding fence reads as holding comment, and stays as written.
##     Fixer whose rewrite would move, re-indent, split or merge fenced lines is skipped for
##     that file, and its finding stays for hand. Fence crossing bracket, or string or comment
##     spanning lines, leaves whole file as written, with finding naming line.
##
##   Rejected: fixer told of fence, i.e. each rewrite tested against fenced lines. Every fixer
##     would carry fence; masking holds it in one place, at cost of skipping fixer whole.
##   Cost: line reading exactly `FENCED` outside fence would be restored as fenced line, so

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./[reports, tokens, views]


const
  FENCE_OFF* = "#!fix off"  ## Marker line opening fence (Article X.1).
  FENCE_ON* = "#!fix on"  ## Marker line closing fence.
  FENCED = "#!fix fenced"
    ## Text each fenced line reads as while fixers run: whole-line comment, which no fixer writes.


type
  Fence* = object  ## Define lines fence leaves alone, and line where fence cannot be read, if any.
    lines*: seq[int]  ## Zero-based fenced lines, markers included, in order.
    fault*: int
      ## Zero-based line fence crosses bracket or token at, or reads `FENCED`; `-1` if none.


func fenceOf*(source: string): Fence =
  ## Read fenced lines of Nim source, and first line where fence cannot be read.
  ##   Marker is comment token opening its line, so marker inside string or block comment is none.
  result.fault = -1
  let
    tokens = source.tokens
    partners = tokens.partners
    lines = source.split('\n')
    count = if source.endsWith("\n"): lines.len - 1 else: lines.len
  var markers = newSeq[string](lines.len)
  for k, t in tokens:
    if t.kind != KindToken.Comment: continue
    if k == 0 or tokens[k - 1].lineLast(source) < t.line:
      markers[t.line] = t.spelling(source).strip
  var
    fences = newSeqWith(lines.len, -1)  # Fence each line lies in, by count; `-1` outside.
    opened = 0
    is_open = false
  for i in 0 ..< count:
    if markers[i] == FENCE_OFF and not is_open:
      is_open = true
      inc opened
    if is_open: fences[i] = opened
    if markers[i] == FENCE_ON: is_open = false
    if fences[i] >= 0: result.lines.add i
    if lines[i].strip == FENCED and result.fault < 0: result.fault = i
  if result.lines.len == 0: return

  # Bracket pair whose ends lie in two places, or token whose lines do, crosses fence.
  for k, t in tokens:
    let crossed =
      if partners[k] > k: fences[tokens[partners[k]].line] != fences[t.line]
      else: toSeq(t.line .. t.lineLast(source)).anyIt(fences[it] != fences[t.line])
    if crossed:
      result.fault = if result.fault < 0: t.line else: min(result.fault, t.line)
      return


func masked*(source: string, fence: Fence): string =
  ## Read each fenced line as `FENCED` at its own indent; blank line at none.
  var lines = source.split('\n')
  for i in fence.lines:
    lines[i] = (if lines[i].strip.len == 0: "" else: ' '.repeat(lines[i].indentOf)) & FENCED
  lines.join("\n")


func shapeFence*(source: string): seq[(int, bool)] =
  ## Read indent of each `FENCED` line, and whether one stands right above it.
  let lines = source.split('\n')
  for i, line in lines:
    if line.strip != FENCED: continue
    result.add (line.indentOf, i > 0 and lines[i - 1].strip == FENCED)


func restored*(fixed, source: string; fence: Fence): string =
  ## Write each fenced line back, in order, in place of `FENCED` line standing for it.
  let original = source.split('\n')
  var
    lines = fixed.split('\n')
    k = 0
  for line in lines.mitems:
    if line.strip != FENCED: continue
    line = original[fence.lines[k]]
    inc k
  lines.join("\n")


func runsOf*(fence: Fence): seq[Slice[int]] =
  ## Read each run of consecutive fenced lines, zero-based, markers included; fence left open
  ##   runs to end of file, and fences touching read as one run.
  for k, line in fence.lines:
    if k == 0 or fence.lines[k - 1] != line - 1: result.add line .. line
    else: result[^1].b = line


func faultOf*(path: string, fence: Fence): seq[Report] =
  ## Report fence fix cannot read, which leaves file as written.
  if fence.fault < 0: return
  result.add initReport(
    path,
    fence.fault + 1,
    Rule.Fence,
    "Fence closes outside bracket, string or comment it opens in, so fix leaves file as " &
      "written; got `" & FENCE_OFF & "` and `" & FENCE_ON & "` either side.",
  )
