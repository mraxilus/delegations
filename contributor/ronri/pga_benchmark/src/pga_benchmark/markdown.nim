## Read Markdown files into blocks, and render blocks as HTML for pages.
##   Files this project keeps for pages (changes, notes, proposals) are Markdown, since audit reads
##   it and reader edits it; pages render them rather than restate them, so file stays only home.
##   Subset is what those files use: headings, paragraphs, bullet, numbered and task lists, pipe
##     tables, fenced code, and inline code, bold, italic and links. Anything else renders as
##     paragraph text, escaped, so unknown syntax degrades to words rather than to markup.
##   Fence closes on run of backticks at least as long as one that opened it, so quoted code
##     holding shorter run stays whole.
##
##   Cost: nested lists flatten to one level; files keep one level, and renderer says so
##     here rather than guessing indentation.
##   Cost: inline parse is left to right with no backtracking; unmatched marker renders as
##     itself.

{.experimental: "strictFuncs".}

import std/strutils


type
  BlockKind* {.pure.} = enum
    ## Define kinds of block file holds.
    Heading, Paragraph, Bullets, Numbers, Tasks, Table, Fence
  Block* = object
    ## Define one block of file, with line it opens on for findings.
    kind*: BlockKind
      ## What block is.
    level*: int
      ## Heading level, one to six; zero for other kinds.
    lines*: seq[string]
      ## Text lines: heading text, paragraph lines, list items, table rows, or fence body.
    language*: string
      ## Language fence names after its opening run, as `nim`; empty for other kinds.
    line*: int
      ## Line block opens on, counted from one.


const
  FENCE_MARK = '`'
    ## Character fence is run of.
  FENCE_MIN = 3
    ## Shortest run opening fence.
  TASK_OPEN = "[ ] "
    ## Marker of open task item.
  TASK_DONE = "[x] "
    ## Marker of done task item.



#[ Block Parsing ]#

func fenceOf(line: string): int =
  ## Count backticks opening line; zero when fewer than fence needs.
  for c in line:
    if c != FENCE_MARK: break
    inc result
  if result < FENCE_MIN: result = 0


func headingOf(line: string): int =
  ## Count `#` opening heading line; zero when line is no heading.
  for c in line:
    if c != '#': break
    inc result
  if result == 0 or result > 6 or line.len <= result or line[result] != ' ': result = 0


func isBullet(line: string): bool =
  ## Tell whether line opens bullet item.
  line.startsWith("- ") or line.startsWith("* ")


func numberedText(line: string): int =
  ## Read offset of text after `1. ` marker; zero when line opens no numbered item.
  var i = 0
  while i < line.len and line[i].isDigit: inc i
  if i > 0 and i + 1 < line.len and line[i] == '.' and line[i + 1] == ' ': i + 2 else: 0


func parseBlocks*(source: string): seq[Block] =
  ## Split file into blocks, in order.

  func isBlockStart(line: string): bool =
    ## Tell whether line opens block of its own, so ends paragraph before it.
    line.headingOf > 0 or line.fenceOf > 0 or line.isBullet or line.numberedText > 0 or
      line.startsWith("|")

  let lines = source.splitLines
  var i = 0
  while i < lines.len:
    let
      line = lines[i]
      stripped = line.strip
    if stripped.len == 0:
      inc i
      continue

    # Read fence whole, up to closing run of at least same length.
    let fence = line.fenceOf
    if fence > 0:
      var body: seq[string]
      let opening = i + 1
      inc i
      while i < lines.len and lines[i].strip(leading = false).fenceOf < fence:  # Close on run.
        body.add lines[i]
        inc i
      result.add Block(
        kind: BlockKind.Fence,
        lines: body,
        language: line[fence .. ^1].strip,
        line: opening,
      )
      inc i
      continue

    # Read heading as one line.
    let level = line.headingOf
    if level > 0:
      result.add Block(
        kind: BlockKind.Heading,
        level: level,
        lines: @[line[level + 1 .. ^1].strip],
        line: i + 1,
      )
      inc i
      continue

    # Read table rows while lines open with pipe.
    if line.startsWith("|"):
      var rows: seq[string]
      let opening = i + 1
      while i < lines.len and lines[i].startsWith("|"):
        rows.add lines[i]
        inc i
      result.add Block(kind: BlockKind.Table, lines: rows, line: opening)
      continue

    # Read list items, each with its indented continuation lines.
    if line.isBullet or line.numberedText > 0:
      let
        is_numbered = line.numberedText > 0
        opening = i + 1
      var
        items: seq[string]
        is_task = false
      while i < lines.len:
        let current = lines[i]
        if (is_numbered and current.numberedText > 0) or (not is_numbered and current.isBullet):
          let text = if is_numbered: current[current.numberedText .. ^1] else: current[2 .. ^1]
          if text.startsWith(TASK_OPEN) or text.startsWith(TASK_DONE): is_task = true
          items.add text
        elif current.startsWith("  ") and current.strip.len > 0 and items.len > 0:
          items[^1].add " " & current.strip
        else:
          break
        inc i
      let kind =
        if is_task: BlockKind.Tasks
        elif is_numbered: BlockKind.Numbers
        else: BlockKind.Bullets
      result.add Block(kind: kind, lines: items, line: opening)
      continue

    # Read paragraph up to blank line or block of its own.
    var text: seq[string]
    let opening = i + 1
    while i < lines.len and lines[i].strip.len > 0:
      if text.len > 0 and lines[i].isBlockStart: break
      text.add lines[i].strip
      inc i
    result.add Block(kind: BlockKind.Paragraph, lines: text, line: opening)



#[ Inline Rendering ]#

func escapeHtml*(text: string): string =
  ## Escape text for HTML body and attribute alike.
  for c in text:
    case c
    of '&': result.add "&amp;"
    of '<': result.add "&lt;"
    of '>': result.add "&gt;"
    of '"': result.add "&quot;"
    of '\'': result.add "&#39;"
    else: result.add c


func renderInline*(text: string): string =
  ## Render inline markup: code, bold, italic and links; everything else escaped.
  var i = 0
  while i < text.len:
    let c = text[i]

    # Render code span verbatim, escaped, up to matching backtick run.
    if c == '`':
      var run = 0
      while i + run < text.len and text[i + run] == '`': inc run
      let close = text.find(repeat('`', run), i + run)
      if close > 0:
        result.add "<code>" & escapeHtml(text[i + run ..< close].strip) & "</code>"
        i = close + run
        continue
      result.add escapeHtml(text[i ..< i + run])
      i += run
      continue

    # Render bold between double stars.
    if c == '*' and i + 1 < text.len and text[i + 1] == '*':
      let close = text.find("**", i + 2)
      if close > i + 2:
        result.add "<strong>" & renderInline(text[i + 2 ..< close]) & "</strong>"
        i = close + 2
        continue

    # Render italic between single stars or underscores at word edges.
    if (c == '*' or c == '_') and i + 1 < text.len and text[i + 1] != ' ' and
        (i == 0 or text[i - 1] in {' ', '(', '['}):
      let close = text.find(c, i + 1)
      if close > i + 1 and (close + 1 == text.len or text[close + 1] notin Letters + Digits):
        result.add "<em>" & renderInline(text[i + 1 ..< close]) & "</em>"
        i = close + 1
        continue

    # Render link from bracketed text and parenthesised address.
    if c == '[':
      let close = text.find("](", i + 1)
      if close > i:
        let finish = text.find(')', close + 2)
        if finish > close:
          let address = text[close + 2 ..< finish]
          result.add "<a href=\"" & escapeHtml(address) & "\">" &
            renderInline(text[i + 1 ..< close]) & "</a>"
          i = finish + 1
          continue

    result.add escapeHtml($c)
    inc i



#[ Block Rendering ]#

func cellsOf(row: string): seq[string] =
  ## Split pipe table row into trimmed cells.
  var inner = row.strip
  if inner.startsWith("|"): inner = inner[1 .. ^1]
  if inner.endsWith("|"): inner = inner[0 ..< ^1]
  for cell in inner.split('|'): result.add cell.strip


func renderFence*(lines: seq[string], language: string, first = 0): string =
  ## Render fenced code, numbering lines from `first` where positive.
  result = "<pre class=\"code\" data-lang=\"" & escapeHtml(language) & "\"><code>"
  for i, line in lines:
    let number = if first > 0: "<span class=\"ln\">" & $(first + i) & "</span>" else: ""
    result.add "<span class=\"cl\">" & number & escapeHtml(line) & "</span>\n"
  result.add "</code></pre>"


func renderBlock*(node: Block, offset = 1): string =
  ## Render one block; `offset` lowers heading levels so file nests under page heading.

  func renderTable(rows: seq[string]): string =
    ## Render pipe table; first row is header when second divides.

    func isDivider(row: string): bool =
      ## Tell whether table row divides header from body: dashes and colons only.
      for cell in row.cellsOf:
        if cell.len == 0 or not cell.allCharsInSet({'-', ':', ' '}): return false
      true

    let has_header = rows.len > 1 and rows[1].isDivider
    result = "<div class=\"table\"><table>"
    for i, row in rows:
      if has_header and i == 1: continue
      let tag = if has_header and i == 0: "th" else: "td"
      result.add "<tr>"
      for cell in row.cellsOf:
        result.add "<" & tag & ">" & renderInline(cell) & "</" & tag & ">"
      result.add "</tr>"
    result.add "</table></div>"

  case node.kind
  of BlockKind.Heading:
    let tag = "h" & $min(node.level + offset, 6)
    "<" & tag & ">" & renderInline(node.lines[0]) & "</" & tag & ">"
  of BlockKind.Paragraph:
    "<p>" & renderInline(node.lines.join(" ")) & "</p>"
  of BlockKind.Bullets, BlockKind.Numbers:
    let tag = if node.kind == BlockKind.Numbers: "ol" else: "ul"
    var html = "<" & tag & ">"
    for item in node.lines: html.add "<li>" & renderInline(item) & "</li>"
    html & "</" & tag & ">"
  of BlockKind.Tasks:
    var html = "<ul class=\"tasks\">"
    for item in node.lines:
      let (mark, text) =
        if item.startsWith(TASK_DONE): ("done", item[TASK_DONE.len .. ^1])
        elif item.startsWith(TASK_OPEN): ("open", item[TASK_OPEN.len .. ^1])
        else: ("open", item)
      html.add "<li class=\"" & mark & "\">" & renderInline(text) & "</li>"
    html & "</ul>"
  of BlockKind.Table:
    renderTable(node.lines)
  of BlockKind.Fence:
    renderFence(node.lines, node.language)


func renderBlocks*(blocks: openArray[Block], offset = 1): string =
  ## Render blocks in order.
  for b in blocks: result.add renderBlock(b, offset)
