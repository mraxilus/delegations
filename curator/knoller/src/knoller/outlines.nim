## Read each comment of Nim source as hanging outline (Article VI.2), and doc's summary (VI.1);
##   enforce both, and fix outline (`koch fix`).
##   Comment is doc as lexer joins it, i.e. `##` line and each next line opening with `##`, at
##     any column (`scanComment` of `compiler/lexer.nim`); run of own-line `#` lines at one
##     column; or trailing `#` comment alone. Block comment, fence marker and shebang (`#!`) are
##     none.
##   Step of line: spaces between its marker and its text. Sentence of line starts past its step,
##     and past each leading tag, i.e. capitalised word with colon and space, as `TODO:`, `Cost:`
##     or `Rejected:` (`tagged`), as Architect ruled on rule 3 of #443.
##   Parent of line: nearest line above it in its comment at smaller step. Nuance stands two spaces
##     past where sentence of parent starts (VI.2), so line below `# TODO: Implement …` stands two
##     spaces past `Implement`. Wrap of sentence stands so too, since ruling lets summary wrap two
##     spaces deeper.
##   Line holds no step where it is table row (`|`), diagram (`->`), or code between fences of
##     three backticks; blank line holds none. `#` comment whose first line stands at even step is
##     commented code, as `#func` is, so it holds no outline.
##   Doc holds one summary line (VI.1): in first paragraph, line at summary step after line that
##     closes sentence is second summary, which moves two spaces past summary's sentence; after
##     line that runs on, summary wraps at its own step, and stays for hand, since hand alone knows
##     where it ends. Paragraph after blank `##` line takes lines at summary step, as header of
##     module does.
##   Generated doc: string literal passed as argument `docs`, by name. Its first line is its
##     summary, which ends in period, or wraps two spaces deeper to line that does; else it stays
##     for hand, since fix of string changes its value.
##   Fixer sets each line two spaces past its parent's sentence, as parent stands once moved, so
##     lines below moved line move with it. Comment whose move would widen line past `LINE_MAX`
##     stays for hand, whole. Checks and fixer share one reading (`outline`), so rule is written
##     once (Article II.1), and `prose.nim` reads comments as `comments` gives them.
##
##   Cost: generated doc passed by place, not by name, is unread; so is its outline past summary.
##   Cost: line of table, diagram or code stays where its parent moves.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./[form, reports, tokens]


type
  KindComment* {.pure.} = enum  ## Define kind of comment, which decides how its outline reads.
    Doc  ## `##` doc, as lexer joins it.
    Plain  ## `#` comment: run of own-line lines at one column, or trailing comment alone.

  LineComment* = object  ## Define one line of comment, as outline reads it.
    line*: int  ## Zero-based line.
    marker*: int  ## Byte offset of comment's first `#` on its line.
    width*: int  ## Bytes of marker: one for `#`, two for `##`.
    step*: int  ## Spaces between marker and text.
    text*: string  ## Text after marker and its spaces.
    is_trailing*: bool  ## Comment trails code on its line.

  Comment* = object  ## Define one comment by its kind and lines.
    kind*: KindComment
    lines*: seq[LineComment]

  Outline = object  ## Define what outline of one comment reports, and step fix gives each line.
    found: seq[Report]  ## Finding of each line off its step, and of summary; path left empty.
    fixable: seq[bool]  ## Whether fix clears each finding.
    steps: seq[int]  ## Step each line of comment takes once fixed.


const
  MARKS_CLOSING* = {'.', '?', '!'}  ## Characters closing sentence (VIII.2 asks question as one).
  STEP_NUANCE = 2  ## Spaces nuance stands past sentence of its parent (VI.2).
  STEP_WRAP_GENERATED = 2  ## Spaces wrap of generated summary stands past it.


func tagged*(text: string): int =
  ## Count bytes of each leading tag of text with spaces after it: capitalised word, colon, space.
  var k = 0
  while k < text.len and text[k] in {'A' .. 'Z'}:
    var j = k + 1
    while j < text.len and text[j] in {'A' .. 'Z', 'a' .. 'z'}: inc j
    if j >= text.len or text[j] != ':': break
    var after = j + 1
    while after < text.len and text[after] == ' ': inc after
    if after == j + 1 or after >= text.len: break
    k = after
  k


func isClosing(text: string): bool =
  ## Decide whether text closes sentence.
  let stripped = text.strip(leading = false)
  stripped.len > 0 and stripped[^1] in MARKS_CLOSING


func comments*(source: string): seq[Comment] =
  ## Read each comment of source, in order, as outline reads it.
  let
    tokens = source.tokens
    starts = source.lineStarts
  var ended = -1  # Line last code token ends on.
  for t in tokens:
    if t.kind != KindToken.Comment:
      ended = t.lineLast(source)
      continue
    let text = t.spelling(source)
    if text.startsWith("#[") or text.startsWith("##[") or text.startsWith("#!"): continue
    let
      width = if text.startsWith("##"): 2 else: 1
      kind = if width == 2: KindComment.Doc else: KindComment.Plain
      rest = text[width .. ^1]
      step = rest.len - rest.strip(trailing = false, chars = {' '}).len
      line = LineComment(
        line: t.line,
        marker: t.first - starts[t.line],
        width: width,
        step: step,
        text: rest[step .. ^1].strip(leading = false),
        is_trailing: ended == t.line,
      )

    # Own-line line right below joins comment: any doc, or `#` line at its column.
    if result.len > 0 and not line.is_trailing:
      let
        previous = result[^1]
        last = previous.lines[^1]
      if last.line + 1 == t.line and previous.kind == kind and
          (kind == KindComment.Doc or (not last.is_trailing and last.marker == line.marker)):
        result[^1].lines.add line
        continue
    result.add Comment(kind: kind, lines: @[line])


func isStepless(lines: seq[LineComment]): seq[bool] =
  ## Decide of each line whether it holds no step: blank, table row, diagram, or code between
  ##   fences of three backticks, fences included.
  var is_fenced = false
  for l in lines:
    if l.text.startsWith("```"):
      result.add true
      is_fenced = not is_fenced
      continue
    result.add is_fenced or l.text.strip.len == 0 or l.text.startsWith("|") or "->" in l.text


func outline(c: Comment): Outline =
  ## Read each line of comment off its step, summary of doc that is not one line, and step each
  ##   line takes once fixed.
  let
    n = c.lines.len
    stepless = c.lines.isStepless
    stepped = toSeq(0 ..< n).filterIt(not stepless[it])
    marker = '#'.repeat(c.lines[0].width)
  result.steps = c.lines.mapIt(it.step)
  if stepped.len == 0: return
  if c.kind == KindComment.Plain and c.lines[stepped[0]].step mod 2 == 0: return  # commented code
  let summary = stepped[0]
  var
    is_first_paragraph = true
    is_run_on = false
    previous = -1  # Last line above that holds step.
  for i in 0 ..< n:
    if i > summary and c.lines[i].text.strip.len == 0: is_first_paragraph = false
    if stepless[i]: continue

    # Nuance stands two spaces past sentence of nearest line above it at smaller step.
    var parent = -1
    for j in countdown(i - 1, 0):
      if not stepless[j] and c.lines[j].step < c.lines[i].step:
        parent = j
        break
    if parent >= 0:
      let
        tag = c.lines[parent].text.tagged
        start = c.lines[parent].step + tag
      result.steps[i] = result.steps[parent] + tag + STEP_NUANCE
      if c.lines[i].step != start + STEP_NUANCE:
        result.found.add initReport(
          "",
          c.lines[i].line + 1,
          Rule.OutlineDoc,
          "Nuance indents two spaces past its parent's sentence; got `" & $c.lines[i].step &
            "` spaces after `" & marker & "`, parent's sentence at `" & $start & "`.",
        )
        result.fixable.add true

    # Line at summary step in first paragraph of doc: second summary, or summary run on.
    elif c.kind == KindComment.Doc and i > summary and is_first_paragraph:
      if c.lines[previous].text.isClosing:
        result.steps[i] = result.steps[summary] + c.lines[summary].text.tagged + STEP_NUANCE
        result.found.add initReport(
          "",
          c.lines[i].line + 1,
          Rule.SummaryDoc,
          "Doc holds one summary line, so next claim indents two spaces; got `" &
            c.lines[i].text & "`.",
        )
        result.fixable.add true
      elif not is_run_on:
        is_run_on = true
        result.found.add initReport(
          "",
          c.lines[summary].line + 1,
          Rule.SummaryDoc,
          "Summary line of doc ends its sentence, or wraps two spaces deeper; got `" &
            c.lines[summary].text & "`.",
        )
        result.fixable.add false
    previous = i


func docsGenerated(source: string): seq[(int, seq[string])] =
  ## Read zero-based line and lines of text of each string literal passed as argument `docs`.
  let tokens = source.tokens
  for k in 0 ..< tokens.len - 2:
    if tokens[k].kind != KindToken.Word or tokens[k].spelling(source) != "docs": continue
    if tokens[k + 1].spelling(source) != "=": continue
    var before = k - 1
    while before >= 0 and tokens[before].kind == KindToken.Comment: dec before
    if before < 0 or
        not (tokens[before].kind == KindToken.Comma or tokens[before].spelling(source) == "("):
      continue
    var value = k + 2
    if tokens[value].kind != KindToken.Text and value + 1 < tokens.len and
        tokens.isInterpolated(value + 1, source):
      inc value
    if tokens[value].kind != KindToken.Text: continue
    let
      spelled = tokens[value].spelling(source)
      quote = if spelled.startsWith("\"\"\""): 3 else: 1
    if spelled.len < 2 * quote: continue
    result.add (tokens[value].line, spelled[quote ..< spelled.len - quote].split('\n'))


func outlines(source: string): tuple[found: seq[Report], fixable: seq[bool], lines: seq[string]] =
  ## Read every finding of outline and summary in source, whether fix clears each, and lines
  ##   fix writes: each comment moved where no line of it widens past `LINE_MAX`.
  result.lines = source.split('\n')
  for c in source.comments:
    let o = c.outline
    var
      moved: seq[(int, string)]
      is_wide = false
    for i, l in c.lines:
      if o.steps[i] == l.step: continue
      let
        given = result.lines[l.line]
        shaped = given[0 ..< l.marker + l.width] & ' '.repeat(o.steps[i]) &
          given[l.marker + l.width + l.step .. ^1]
      if shaped.isWide and not given.isWide: is_wide = true
      moved.add (l.line, shaped)
    for (line, shaped) in (if is_wide: @[] else: moved): result.lines[line] = shaped
    result.found.add o.found
    result.fixable.add o.fixable.mapIt(it and not is_wide)

  # Summary of generated doc ends in period, or wraps two spaces deeper to line that does.
  for (line, texts) in source.docsGenerated:
    var k = 0
    while not texts[k].isClosing and k + 1 < texts.len and
        texts[k + 1].len - texts[k + 1].strip(trailing = false).len == STEP_WRAP_GENERATED:
      inc k
    if texts[k].isClosing: continue
    result.found.add initReport(
      "",
      line + 1,
      Rule.SummaryDoc,
      "Summary line of generated doc ends in period; got `" & texts[0].strip & "`.",
    )
    result.fixable.add false


func checkOutlines*(path, source: string): seq[Report] =
  ## Report each nuance off its step (VI.2), and each summary of doc that is not one line whose
  ##   sentence ends in period (VI.1).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for report in source.outlines.found:
    var located = report
    located.path = path
    result.add located


func fixOutlines*(path, source: string): Fix =
  ## Move each line off its step, with lines below it, where no line widens past `LINE_MAX`;
  ##   lines keep their numbers.
  let (found, fixable, lines) = source.outlines
  result.source = lines.join("\n")
  for k, report in found:
    if fixable[k]: result.fixed.add initReport(path, report.line, report.rule)
