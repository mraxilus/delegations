## Read Markdown shapes checks depend on: pipe-table rows and headings.
##   Deliberately tiny: no Markdown parser, only line forms governed documents use.
##
##   Cost: table cell holding `|` splits wrongly; no governed table carries one.
##   Cost: fenced code blocks are not skipped by readers below, so table inside fence counts
##     as table; reader that must not see example composes `fencedOut` first.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]


func isSeparatorRow(cells: seq[string]): bool =
  ## Decide whether row is `|---|---|` rule under header.
  cells.len > 0 and cells.allIt(it.len > 0 and it.allCharsInSet({'-', ':'}))


func tableRows*(markdown: string): seq[seq[string]] =
  ## Read every pipe-table row as stripped cells, separator rows dropped.
  for line in markdown.splitLines:
    let s = line.strip
    if not (s.startsWith("|") and s.endsWith("|")) or s.len < 2: continue
    let cells = s[1 ..< s.high].split('|').mapIt(it.strip)
    if cells.isSeparatorRow: continue
    result.add cells


func headingLines*(markdown: string): seq[string] =
  ## Collect ATX heading lines, i.e. lines opening with `#`.
  for line in markdown.splitLines:
    if line.startsWith("#"): result.add line


func firstNonBlank*(markdown: string): string =
  ## Read first line holding non-whitespace; empty when none.
  for line in markdown.splitLines:
    if line.strip.len > 0: return line
  ""


func fencedOut*(markdown: string): string =
  ## Blank every line of fenced code, fences included, keeping line count and endings.
  ##   Fence is line opening with three backticks after optional indent; next such line
  ##   closes it, and fence left open blanks to end of document.
  var is_inside = false
  for line in markdown.splitLines(keepEol = true):
    let is_fence = line.strip.startsWith("```")
    if is_fence: is_inside = not is_inside
    let body = line.strip(leading = false, chars = {'\r', '\n'})
    result.add(if is_fence or is_inside: line[body.len .. ^1] else: line)
