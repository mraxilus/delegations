## Enforce that each stage of routine or test opens with comment naming its purpose (Article VI.4),
##   and write placeholder where none stands (`koch fix`).
##   Body is lines below `=` that ends signature, deeper than head, of each routine kind; and
##     lines below `test "…":`, deeper than it. Routine nested in body is no stage of routine
##     holding it: its lines cut paragraph there, and its body reads as its own (STYLE.md §1).
##     Paragraph of routines on one line is helpers too, and comment right above helper is
##     helper's, so neither opens stage of routine holding it.
##   Paragraph is run of lines with text and no blank line between, at any depth of body, so
##     inside loop or branch too. Line inside string or comment spanning lines opens no
##     paragraph, and blank line there ends none. Code under `quote do:` is generator's, so it
##     opens none.
##   Narrow form, as Architect ruled on rule 4 of #443: paragraph that blank line opens takes stage
##     comment as its first line, where another stage of its routine opens with one, and where it
##     holds `LINES_CODE_MIN` lines of code or more. Stage comment is own-line `#` comment, TODO
##     among them, since text cannot read whether it names purpose; trailing comment is none, and
##     so is fence marker. First stage opens after routine's doc, so comment below doc opens it.
##   Fixer writes `PLACEHOLDER` above paragraph, at its indent, where line fits; check and fixer
##     share one reading (`stages`), so rule is written once (Article II.1).
##
##   Rejected: broad form, i.e. every paragraph blank line opens: 45 lines by count on #443.
##   Cost: scanner, never parser: routine reads from line opening with its keyword and name,
##     so lambda's body reads as lines of routine holding it, and test as `test "…":`.
##   Cost: line inside string spanning lines is no line of code, so long literal counts its
##     first line alone.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[form, reports, tokens, views]


type  # TODO: Document.
  Body = object  ## Define body of routine or test, by lines it spans.
    head: int  ## Zero-based line of routine's keyword, or of `test`.
    first: int  ## Zero-based first line below `=` or `:` opening body.
    last: int  ## Zero-based last line of body holding text.

  Stage = object  ## Define paragraph that takes stage comment and opens with none.
    line: int  ## Zero-based first line of paragraph.
    indent: int  ## Spaces before its first line, which placeholder takes.
    got: string  ## First line as message echoes it, trailing comment left out.


const  # TODO: Document.
  KEYWORDS_ROUTINE = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords declaring routine, whose body holds stages.
  PLACEHOLDER = "# TODO: Describe stage's purpose."
    ## Stage comment waiting for its text (VI.4), as `## TODO: Document.` waits for doc's.
  LINES_CODE_MIN = 3
    ## Lines of code paragraph holds at least to take stage comment (ruling on rule 4 of #443):
    ##   author of PGA library comments 43 of 50 such paragraphs where routine comments stage.


func stages(source: string): seq[Stage] =
  ## Find each paragraph that blank line opens, with no stage comment, in body of routine or test
  ##   that opens another stage with one, holding `LINES_CODE_MIN` lines of code or more.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')
    tokens = source.tokens
    partners = tokens.partners
  var
    inside = newSeq[bool](lines.len)  # Line after first of token spanning lines.
    quoted = newSeq[bool](lines.len)  # Line under `quote do:`, generated code.
    firsts = newSeqWith(lines.len, -1)  # Index of first token opening on each line.
  for k, t in tokens:
    for line in t.line + 1 .. t.lineLast(source): inside[line] = true
    if firsts[t.line] < 0 and (k == 0 or tokens[k - 1].lineLast(source) < t.line):
      firsts[t.line] = k
  for k, line in code:
    if not line.strip.endsWith("quote do:"): continue
    var below = k + 1
    while below < code.len and
        (code[below].strip.len == 0 or code[below].indentWidth > line.indentWidth):
      quoted[below] = true
      inc below

  func isText(k: int): bool =
    ## Decide whether line holds anything but whitespace.
    lines[k].strip.len > 0

  func isBlank(k: int): bool =
    ## Decide whether line is blank, and not inside string or comment spanning lines.
    not isText(k) and not inside[k]

  func isComment(k: int): bool =
    ## Decide whether line holds `#` comment alone, fence marker and doc aside.
    let text = kept[k].strip
    code[k].strip.len == 0 and not inside[k] and text.startsWith("#") and
      not text.startsWith("##") and not text.startsWith("#!")

  func isDoc(k: int): bool =
    ## Decide whether line holds `##` doc alone.
    code[k].strip.len == 0 and not inside[k] and kept[k].strip.startsWith("##")

  func opener(k: int): int =
    ## Read zero-based line `=` or `:` opening body of routine or test whose head token is `k`,
    ##   where body opens below it; `-1` where none: forward declaration, or body on that line.
    let head = tokens[k]
    if head.spelling(source) == "test":
      let
        name = k + 1
        colon = k + 2
      if colon >= tokens.len or tokens[name].kind != KindToken.Text or
          tokens[colon].spelling(source) != ":" or tokens[colon].line != head.line:
        return -1
      if colon + 1 < tokens.len and tokens[colon + 1].line == head.line and
          tokens[colon + 1].kind != KindToken.Comment:
        return -1
      return head.line
    var j = k + 1
    while j < tokens.len:
      let t = tokens[j]
      if t.kind == KindToken.Comment:
        inc j
        continue
      if t.line > head.line and firsts[t.line] == j and
          lines[t.line].indentWidth <= lines[head.line].indentWidth:
        return -1
      if t.kind == KindToken.Operator and t.spelling(source) == "=":
        var after = j + 1
        while after < tokens.len and tokens[after].kind == KindToken.Comment: inc after
        if after < tokens.len and tokens[after].line == t.lineLast(source): return -1
        return t.lineLast(source)
      j = if t.kind == KindToken.Open and partners[j] > j: partners[j] + 1 else: j + 1
    -1

  # Read body of each routine and test: lines below its opener, deeper than its head.
  var bodies: seq[Body]
  for line in 0 ..< lines.len:
    let k = firsts[line]
    if k < 0 or inside[line] or quoted[line]: continue
    let
      word = tokens[k].spelling(source)
      is_routine = word in KEYWORDS_ROUTINE and k + 1 < tokens.len and
        tokens[k + 1].line == line and tokens[k + 1].kind in {KindToken.Word, KindToken.Quoted}
    if not is_routine and word != "test": continue
    let open = opener(k)
    if open < 0: continue
    var
      last = open
      j = open + 1
    while j < lines.len:
      if isText(j) and not inside[j] and lines[j].indentWidth <= lines[line].indentWidth: break
      if isText(j): last = j
      inc j
    if last > open: bodies.add Body(head: line, first: open + 1, last: last)

  # Split each body into paragraphs, nested bodies left out; report paragraph that blank line
  #   opens, with no stage comment, in body whose other stage opens with one.
  for b in bodies:
    var excluded = newSeq[bool](b.last - b.first + 1)
    for n in bodies:
      if n.head < b.first or n.head > b.last: continue
      for line in n.head .. n.last: excluded[line - b.first] = true
    var
      found: seq[Stage]
      is_commented_any = false
      j = b.first
    while j <= b.last:
      if not isText(j) or inside[j] or quoted[j] or excluded[j - b.first]:
        inc j
        continue
      var first = j
      let is_opened = first > b.first and isBlank(first - 1)
      while j <= b.last and not isBlank(j) and not excluded[j - b.first]: inc j
      let last = j - 1
      if first == b.first:
        while first <= last and isDoc(first): inc first
        if first > last: continue
      let
        heads = toSeq(first .. last).filterIt(not isComment(it) and not isDoc(it))
        is_helper =
          if heads.len == 0: j <= b.last and excluded[j - b.first]
          else:
            heads.allIt(firsts[it] >= 0 and tokens[firsts[it]].spelling(source) in KEYWORDS_ROUTINE)
      if is_helper: continue  # helpers, and comment right above them, are no stage (STYLE.md §1)
      if isComment(first):
        is_commented_any = true
        continue
      let count = toSeq(first .. last).countIt(code[it].strip.len > 0)
      if not is_opened or count < LINES_CODE_MIN: continue
      let at = kept[first].find('#', code[first].strip(leading = false).len)
      found.add Stage(
        line: first,
        indent: lines[first].indentWidth,
        got: (if at >= 0: lines[first][0 ..< at] else: lines[first]).strip,
      )
    if is_commented_any: result.add found
  result = result.sortedByIt(it.line)


func checkStages*(path, source: string): seq[Report] =
  ## Report paragraph that blank line opens with no stage comment as its first line, where its
  ##   routine or test opens another stage with one, and it holds `LINES_CODE_MIN` lines of code
  ##   or more (VI.4).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for stage in source.stages:
    result.add initReport(
      path,
      stage.line + 1,
      Rule.CommentStage,
      "Paragraph opened by blank line takes stage comment; got `" & stage.got & "`.",
    )


func fixStages*(path, source: string): Fix =
  ## Write `PLACEHOLDER` above each paragraph check reports, at its indent, last first, where line
  ##   fits; each line written traces to none.
  let found = source.stages.filterIt(not (' '.repeat(it.indent) & PLACEHOLDER).isWide)
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for stage in found.reversed:
    lines.insert(' '.repeat(stage.indent) & PLACEHOLDER, stage.line)
    origin.insert(0, stage.line)
  result.source = lines.join("\n")
  for stage in found: result.fixed.add initReport(path, stage.line + 1, Rule.CommentStage)
  if found.len > 0: result.origin = origin
