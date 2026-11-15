## Read Markdown shapes checks depend on: pipe-table rows, headings and `##` sections.
##   Deliberately tiny: no Markdown parser, only line forms governed documents use.
##   Section is document cut at each `## ` line outside fenced code (`sections`), since fence
##     may quote heading as example, as `GUIDE.md`, Glossary process, quotes `## Standards`.
##     Stamp, drift and checker's `section` read that one cut, so they never disagree on where
##     section ends, and parts joined give document back byte for byte.
##
##   Cost: table cell holding `|` splits wrongly; no governed table carries one.
##   Cost: fenced code blocks are not skipped by table and heading readers, so table inside
##     fence counts as table; reader that must not see example composes `fencedOut` first.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]


type Section* = object  ## Define one part of document, cut at `## ` line outside fenced code.
  heading*: string  ## Heading line, line end cut; empty for part before first heading.
  text*: string  ## Every line of part, heading included, line ends kept.


func isRowSeparator(cells: seq[string]): bool =
  ## Decide whether row is `|---|---|` rule under header.
  cells.len > 0 and cells.allIt(it.len > 0 and it.allCharsInSet({'-', ':'}))


func rowsTable*(markdown: string): seq[seq[string]] =
  ## Read every pipe-table row as stripped cells, separator rows dropped.
  for line in markdown.splitLines:
    let s = line.strip
    if not (s.startsWith("|") and s.endsWith("|")) or s.len < 2: continue
    let cells = s[1 ..< s.high].split('|').mapIt(it.strip)
    if cells.isRowSeparator: continue
    result.add cells


func linesHeading*(markdown: string): seq[string] =
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


func sections*(markdown: string): seq[Section] =
  ## Cut document at each `## ` line outside fenced code, part before first heading first, empty
  ##   where heading opens document.
  ##   Fence is read through `fencedOut`, which keeps line count, so line `i` of both is one line.
  result = @[Section()]
  let
    lines = markdown.splitLines(keepEol = true)
    shown = markdown.fencedOut.splitLines(keepEol = true)
  for i, line in lines:
    if shown[i].startsWith("## "):
      result.add Section(heading: line.strip(leading = false, chars = {'\r', '\n'}), text: line)
    else: result[^1].text.add line
