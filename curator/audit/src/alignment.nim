## Enforce alignment of plain-text tables in comments (Article I.4), by display width, and fix
##   it (`koch fix`).
##   Table is run of whole-line comments sharing one prefix (indent, marker, spaces), each row
##     opening and closing on `|`, at least one of them separator row of `-` and `:` alone, and
##     every row holding as many cells as it. Column takes width of first separator row's cell.
##   Cell aligns where its display width, trailing spaces included, equals its column's width.
##     Fixer keeps text and leading spaces of each cell, and pads or trims trailing spaces to
##     width; column widens only where cell's text does not fit, to text and one space, and its
##     separator cells widen with it.
##   Display width is width eye reads (I.4): combining mark and format character take none,
##     wide East Asian glyph and emoji take two, any other rune one (`WIDTHS`). Width guard
##     (X.1) counts runes instead, since it bounds what editor holds on one line, and line of
##     table stays within it: table whose row fix would widen past `LINE_MAX` stays to hand.
##   Checks and fixer share one reading (`alignments`), so each rule is written once (Article
##     II.1).
##
##   Cost: `WIDTHS` holds blocks of Unicode 15 East Asian Width `W` and `F`, and of categories
##     `Mn`, `Me` and `Cf`, that scripts of this tree and its neighbours use; mark of other
##     block, e.g. Indic vowel sign, counts one. Ambiguous width (`A`) counts one, as terminal
##     outside East Asian locale draws it.
##   Cost: cell holding `|`, even in backticks, splits; its table holds rows of other cell
##     counts and stays unread.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unicode]
import ../../knoller/src/knoller


type
  Row = object  ## Define one row of table: line, cells between pipes, whether it separates.
    line: int  ## Zero-based line.
    cells: seq[string]  ## Text between pipes, as written.
    is_separator: bool

  Alignment = object  ## Define table whose rows rule renders otherwise: prefix, rows, widths.
    prefix: string  ## Text before first `|`: indent, comment marker, spaces.
    rows: seq[Row]
    widths: seq[int]  ## Display width of each column, widened where text does not fit.
    shaped: seq[string]  ## Each row as rule renders it.


const
  WIDTHS = [
    (0x0300, 0x036F, 0), (0x0483, 0x0489, 0), (0x0591, 0x05BD, 0), (0x05BF, 0x05C7, 0),
    (0x0610, 0x061A, 0), (0x064B, 0x065F, 0), (0x0670, 0x0670, 0), (0x06D6, 0x06ED, 0),
    (0x1100, 0x115F, 2), (0x1AB0, 0x1AFF, 0), (0x1DC0, 0x1DFF, 0), (0x200B, 0x200F, 0),
    (0x202A, 0x202E, 0), (0x2060, 0x2064, 0), (0x20D0, 0x20FF, 0), (0x231A, 0x231B, 2),
    (0x2329, 0x232A, 2), (0x23E9, 0x23EC, 2), (0x23F0, 0x23F0, 2), (0x23F3, 0x23F3, 2),
    (0x25FD, 0x25FE, 2), (0x2614, 0x2615, 2), (0x2648, 0x2653, 2), (0x267F, 0x267F, 2),
    (0x2693, 0x2693, 2), (0x26A1, 0x26A1, 2), (0x26AA, 0x26AB, 2), (0x26BD, 0x26BE, 2),
    (0x26C4, 0x26C5, 2), (0x26CE, 0x26CE, 2), (0x26D4, 0x26D4, 2), (0x26EA, 0x26EA, 2),
    (0x26F2, 0x26F3, 2), (0x26F5, 0x26F5, 2), (0x26FA, 0x26FA, 2), (0x26FD, 0x26FD, 2),
    (0x2705, 0x2705, 2), (0x270A, 0x270B, 2), (0x2728, 0x2728, 2), (0x274C, 0x274C, 2),
    (0x274E, 0x274E, 2), (0x2753, 0x2755, 2), (0x2757, 0x2757, 2), (0x2795, 0x2797, 2),
    (0x27B0, 0x27B0, 2), (0x27BF, 0x27BF, 2), (0x2B1B, 0x2B1C, 2), (0x2B50, 0x2B50, 2),
    (0x2B55, 0x2B55, 2), (0x2E80, 0x303E, 2), (0x3041, 0x33FF, 2), (0x3400, 0x4DBF, 2),
    (0x4E00, 0x9FFF, 2), (0xA000, 0xA4CF, 2), (0xA960, 0xA97F, 2), (0xAC00, 0xD7A3, 2),
    (0xF900, 0xFAFF, 2), (0xFE00, 0xFE0F, 0), (0xFE10, 0xFE19, 2), (0xFE20, 0xFE2F, 0),
    (0xFE30, 0xFE6F, 2), (0xFEFF, 0xFEFF, 0), (0xFF00, 0xFF60, 2), (0xFFE0, 0xFFE6, 2),
    (0x16FE0, 0x16FE4, 2), (0x17000, 0x18CD5, 2), (0x1B000, 0x1B2FB, 2), (0x1F004, 0x1F004, 2),
    (0x1F0CF, 0x1F0CF, 2), (0x1F18E, 0x1F18E, 2), (0x1F191, 0x1F19A, 2), (0x1F200, 0x1F251, 2),
    (0x1F300, 0x1F64F, 2), (0x1F680, 0x1F6FF, 2), (0x1F7E0, 0x1F7EB, 2), (0x1F90C, 0x1F9FF, 2),
    (0x1FA70, 0x1FAFF, 2), (0x20000, 0x2FFFD, 2), (0x30000, 0x3FFFD, 2), (0xE0100, 0xE01EF, 0),
  ]
    ## Code point ranges whose display width is other than one, in order: combining mark and
    ##   format character none, wide East Asian glyph and emoji two (Unicode 15).


func runeWidth(r: Rune): int =
  ## Read display width of one rune.
  let code = int(r)
  for (first, last, width) in WIDTHS:
    if code < first: return 1
    if code <= last: return width
  1


func displayWidth*(text: string): int =
  ## Read width text takes as eye reads it: sum of each rune's display width.
  for r in text.runes: result += r.runeWidth


func padded(text: string, width: int): string =
  ## Pad text with spaces to display width.
  text & ' '.repeat(max(0, width - text.displayWidth))


func rowOf(line, kept: string): (string, seq[string]) =
  ## Read prefix and cells of comment line that is table row; empty prefix where it is none.
  let marker = kept.find('#')
  if marker < 0 or kept[0 ..< marker].strip.len > 0: return
  let open = line.find('|', marker)
  if open < 0 or line[marker ..< open].strip(chars = {'#', ' '}).len > 0: return
  let text = line.strip(leading = false)
  if text.len <= open + 1 or not text.endsWith("|"): return
  (line[0 ..< open], text[open + 1 ..< text.high].split('|'))


func isSeparator(cells: seq[string]): bool =
  ## Decide whether row separates: every cell `-` and `:` alone, with at least one `-`.
  cells.allIt(it.len > 0 and it.allCharsInSet({'-', ':'}) and '-' in it)


func shapedRow(row: Row, prefix: string, widths: seq[int]): string =
  ## Render row at column widths: separator cells as dashes, colons kept at their ends; other
  ##   cells keep text and leading spaces, padded to width.
  var cells: seq[string]
  for c, cell in row.cells:
    if row.is_separator:
      let
        head = if cell.startsWith(":"): ":" else: ""
        tail = if cell.len > 1 and cell.endsWith(":"): ":" else: ""
      cells.add head & '-'.repeat(widths[c] - head.len - tail.len) & tail
    else: cells.add cell.strip(leading = false).padded(widths[c])
  prefix & "|" & cells.join("|") & "|"


func alignments(source: string): seq[Alignment] =
  ## Find each comment table some row of which rule renders otherwise.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')
  var i = 0
  while i < lines.len:
    let (prefix, _) = if code[i].strip.len == 0: rowOf(lines[i], kept[i]) else: ("", @[])
    if prefix.len == 0:
      inc i
      continue

    # Gather run of rows sharing prefix.
    var table = Alignment(prefix: prefix)
    while i < lines.len and code[i].strip.len == 0:
      let (next_prefix, cells) = rowOf(lines[i], kept[i])
      if next_prefix != prefix: break
      table.rows.add Row(line: i, cells: cells, is_separator: cells.isSeparator)
      inc i
    let separators = table.rows.filterIt(it.is_separator)
    if separators.len == 0: continue
    let count = separators[0].cells.len
    if table.rows.anyIt(it.cells.len != count): continue

    # Widen column only where text, leading spaces kept, does not fit.
    table.widths = separators[0].cells.mapIt(it.len)
    for c in 0 ..< count:
      var needed = 0
      for row in table.rows:
        if row.is_separator: continue
        needed = max(needed, row.cells[c].strip(leading = false).displayWidth)
      if needed > table.widths[c]: table.widths[c] = needed + 1
    table.shaped = table.rows.mapIt(it.shapedRow(prefix, table.widths))
    if toSeq(0 ..< table.rows.len).anyIt(table.shaped[it] != lines[table.rows[it].line]):
      result.add table


func checkAlignment*(path, source: string): seq[Report] =
  ## Report table row in comment whose cells align otherwise than display width gives (I.4).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  let lines = source.split('\n')
  for table in source.alignments:
    for k, row in table.rows:
      if table.shaped[k] == lines[row.line]: continue
      var (got, wide, column) = (lines[row.line].strip, 0, 0)
      for c, cell in row.cells:
        if cell.displayWidth != table.widths[c]:
          (got, wide, column) = (cell.strip, cell.displayWidth, table.widths[c])
          break
      result.add initReport(
        path,
        row.line + 1,
        Rule.TableAlignment,
        "Table column aligns by display width, as eye reads it (I.4); cell " & $wide &
          " wide stands in column of " & $column & "; got `" & got & "`.",
      )


func fixAlignment*(path, source: string): Fix =
  ## Render each table check reports at its widths, unless any row would be wide.
  var lines = source.split('\n')
  for table in source.alignments:
    if table.shaped.anyIt(it.isWide): continue
    for k, row in table.rows:
      if table.shaped[k] == lines[row.line]: continue
      lines[row.line] = table.shaped[k]
      result.fixed.add initReport(path, row.line + 1, Rule.TableAlignment)
  result.source = lines.join("\n")
