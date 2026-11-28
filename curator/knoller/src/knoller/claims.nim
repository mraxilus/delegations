## Enforce form of each comment of Nim source (Article VI.10): claim opens with capital and closes
##   with period, and each path, literal and name stands in backticks; and fix both (`koch fix`).
##   Comments are those `comments` of `outlines.nim` reads, so doc, run of `#` lines and trailing
##     comment group as outline groups them.
##   Commented code holds no prose: `#` comment whose first line stands at even step, or reads as
##     code (`isCode`), and `#` line that reads as code (`linesCode`). Hand comments code with no
##     space after marker, and tool with one, so both read as code (#980, `D3 a` on commented
##     code); article check reads same lines (`articles.nim`). Nor does line without step
##     (`isStepless`), aligned column or deeper line that continues it hold prose. Two spaces
##     after closing mark, comma or
##     semicolon space prose, and align no column. Generated doc stands in string, so rule reads
##     none, as Architect ruled on rule 2 of #443.
##   Bare span takes backticks. Path is word with file extension (`EXTENSIONS_FILE`), as
##     `cayleys.nim`, or folder that slash closes, as `draw/`; backticks replace its double
##     quotes. Capitalised name with extension and no folder, as Node.js, names product. Literal
##     is range, typed literal or hex literal, as `E1..E4`, `1'e1` or `0xFF`; literals operators
##     part take one pair. Name is Nim type that is no English word, as `seq` (`TYPES_BARE`), or
##     identifier file declares in shape no English word takes: `_`, digit after letter, or inner
##     capital, so capitals alone take `_` or digit. Dotted name takes backticks where file
##     declares one of its parts.
##   Span stays bare where reader cannot tell it from word: lowercase word, as `sqrt`, capitalised
##     word, as `Basis`, enum member alone, and word with letter outside ASCII, i.e. formal
##     notation. Citation stays bare, i.e. Markdown file named in capitals alone, as STYLE.md §5,
##     since Architect ruled that charter citation takes no backticks; path with folder takes them.
##   Claim ends at last line of comment, before shallower line, line without step, or bullet; there
##     it closes with `.`, `?`, `!`, `:` or `…`, past closing bracket or quote. Before bullet, or
##     before line at step of item it continues, i.e. its sibling, it closes with `,` or `;` too.
##     Line running on to line of same depth or deeper is wrap, whose end rule reads not, so line
##     with no closing mark before capitalised line takes no report, as Architect ruled.
##   Claim starts at first line of paragraph and after claim end; there it opens with capital, and
##     leading tag, as `TODO:`, opens it so (VI.2). Lowercase line deeper than line above
##     continues its sentence, and is no claim (VI.2), as Architect ruled. Bullet opens as it
##     will, since one that ends sentence of line above may open in lowercase.
##   Label carries neither capital nor period (VI.10): trailing `#` comment, own-line `#` comment
##     of one line that opens with no capital or hangs under code it labels, and comment of one
##     line holding one word or opening with citation.
##   Fixer writes each backtick, period and capital. Claim ending on function word (`WORDS_CUT`),
##     on other mark or on `e.g.`, and lowercase line after sentence end, are cut: they stay for
##     hand, since fix would hide cut. Backticks and period that would widen line past `LINE_MAX`
##     stay for hand too; capital widens nothing, so it is written.
##   Where comments keep their own language, names alone are read (`checkBackticks`), since VI.10
##     lets that language set capitals and periods; caller decides (`chain.nim`).
##   Check and fixer share one reading (`prose`), so rule is written once (Article II.1).
##
##   Cost: name is read where file itself declares it, so name of other file stays bare.
##   Cost: two spaces between words, outside backticks and quotes and after no closing mark,
##     comma or semicolon, read as aligned column, so such sentence holds no prose.
##   Cost: `#` comment of code at odd step that reads as no code, as `# echo x`, reads as
##     prose; `#` line of prose that holds call glued to name reads as code, so it takes
##     no report.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unicode]
import ./[declared, form, outlines, reports, tokens]


type  # TODO: Document.
  KindSpan {.pure.} = enum  ## Define what bare span is, which its message names.
    Path, Literal, Name

  Span = object  ## Define one bare span of text of line, which takes backticks.
    kind: KindSpan
    first: int  ## Byte offset in text, quote included.
    after: int  ## Byte offset after span, quote included.
    is_quoted: bool  ## Path in double quotes, whose quotes backticks replace.

  KindFault {.pure.} = enum  ## Define how claim breaks its form.
    Capital  ## Claim opens in lowercase; fix writes capital.
    Period  ## Claim ends with no closing mark; fix writes period.
    Cut  ## Claim ends on function word, other mark or `e.g.`; hand closes it.
    Lowercase  ## Line opens in lowercase after sentence end; hand mends it.

  Fault = object  ## Define one fault of claim, at its word.
    kind: KindFault
    at: int  ## Byte offset of word in text.
    word: string  ## Word message echoes.

  Prose = object  ## Define what one line of comment breaks.
    line: int  ## Zero-based line.
    start: int  ## Byte offset of text on line.
    text: string  ## Text after marker and step.
    spans: seq[Span]
    faults: seq[Fault]

  Names = object  ## Define names file declares, each sorted.
    alone: seq[string]  ## Names that take backticks alone: every kind but enum member.
    every: seq[string]  ## Every name, which dotted name reads.

  Word = object  ## Define one word of text, punctuation around it cut.
    first: int  ## Byte offset of word as cut.
    after: int  ## Byte offset after word as cut.
    spelling: string


const  # TODO: Document.
  EXTENSIONS_FILE = [
    "c", "cfg", "cpp", "css", "csv", "h", "html", "js", "json", "lock", "md", "mjs", "nim",
    "nimble", "nims", "png", "py", "sh", "svg", "toml", "ts", "txt", "wasm", "yaml", "yml",
  ]
    ## Extensions that make word path.
  TYPES_BARE = [
    "bool", "cdouble", "cfloat", "cint", "csize_t", "cstring", "float32", "float64", "int",
    "int16", "int32", "int64", "int8", "openArray", "seq", "typedesc", "uint", "uint16", "uint32",
    "uint64", "uint8", "varargs",
  ]
    ## Nim types that are no English word, so each is name alone; `range`, `float` and `string`
    ##   are words too.
  WORDS_CUT = [
    "a", "an", "and", "are", "as", "at", "be", "been", "but", "by", "for", "from", "if", "into",
    "is", "its", "nor", "of", "onto", "or", "so", "than", "the", "to", "was", "were", "when",
    "where", "which", "while", "whose", "with",
  ]
    ## Function words claim cannot end on, so claim ending on one is cut.
  ABBREVIATIONS_INLINE = ["e.g.", "i.e."]  ## Abbreviations whose period closes no sentence.
  ELLIPSES = ["...", "…"]  ## Fillers that literals operators part may hold between them.
  MARKS_CLOSING = {'!', '.', ':', '?'}  ## Characters closing claim (VIII.2 asks question as one).
  MARKS_LISTED = {',', ';'}  ## Characters closing bullet before bullet, as VIII writes it.
  MARKS_SENTENCE = {'!', '.', '?'}  ## Characters ending sentence, after which line is new claim.
  CHARS_CLOSER = {'"', '\'', ')', ']', '}'}  ## Characters past which closing mark stands.
  CHARS_LEADING = {'"', '\'', '(', '[', '{'}  ## Characters cut from start of word.
  CHARS_TRAILING = {'!', '"', '\'', ')', ',', '.', ':', ';', '?', ']', '}'}
    ## Characters cut from end of word.
  CHARS_PROSE = {'"', '\'', '(', ')', ',', ';', '[', ']', '`', '{', '}'}
    ## Characters of prose that no operator between literals holds.
  SENTENCES_FAULT: array[KindFault, string] = [
    "Claim of comment opens with capital",
    "Claim of comment closes with period",
    "Claim of comment ends cut short, so hand closes it",
    "Line of comment opens in lowercase after sentence end, so hand mends it",
  ]
    ## Sentence of message of each fault, which value follows.
  OPERATORS_CODE = [" != ", " &= ", " *= ", " += ", " -= ", " /= ", " = ", " == ", " =~ "]
    ## Operators between spaces that make `#` line code, where name or bracket stands before.
  CHARS_NAMING = {
    '!', '$', '%', '&', '*', '+', '-', '/', '<', '=', '>', '?', '@', '\\', '^', '|', '~'
  }
    ## Characters of operator name or export marker, so `(` or `[` glued after one opens call or
    ##   signature, as `<=(` and `toggle*(` do.


func isFound(sorted: openArray[string], word: string): bool =
  ## Decide whether sorted list holds word.
  sorted.binarySearch(word) >= 0


func isIdentifier(word: string): bool =
  ## Decide whether word is identifier: letter or `_`, then letters, digits and `_`.
  word.len > 0 and word[0] in Letters + {'_'} and word.allIt(it in IdentChars)


func isShaped(word: string): bool =
  ## Decide whether identifier takes shape no English word takes: `_`, digit after letter, or
  ##   inner capital.
  if '_' in word: return true
  for k in 0 ..< word.high:
    if word[k] in Letters and word[k + 1] in Digits: return true
    if word[k] in {'a' .. 'z'} and word[k + 1] in {'A' .. 'Z'}: return true


func isCitation(word: string): bool =
  ## Decide whether word cites document: Markdown file named in capitals alone, as `STYLE.md`.
  word.len > 3 and word.endsWith(".md") and word[0] in {'A' .. 'Z'} and
    word[0 ..< word.len - 3].allIt(it in {'A' .. 'Z', '0' .. '9', '_'})


func isPath(word: string): bool =
  ## Decide whether word is path: name and file extension, folders before it, and no scheme; or
  ##   folder that slash closes, as `draw/`. Capitalised name with extension and no folder, as
  ##   `Node.js`, names product, so it is none.
  if word.len < 2 or "://" in word or word.isCitation or
      not word.allIt(it in IdentChars + {'-', '.', '/'}):
    return false
  if word[^1] == '/': return word[0] in IdentChars
  let dot = word.rfind('.')
  if dot <= 0 or dot == word.high or word[dot - 1] in {'.', '/'}: return false
  if '/' notin word and word[0] in {'A' .. 'Z'} and word[1] in {'a' .. 'z'}: return false
  word[dot + 1 .. ^1].toLowerAscii in EXTENSIONS_FILE


func isAtom(part: string): bool =
  ## Decide whether part is end of range: identifier, number or character literal.
  part.len > 0 and part.allIt(it in IdentChars + {'\''})


func isLiteral(word: string): bool =
  ## Decide whether word is literal: range, typed literal, or hex literal.
  let dots = word.find("..")
  if dots > 0:
    var right = dots + 2
    if right < word.len and word[right] == '<': inc right
    return word[0 ..< dots].isAtom and right < word.len and word[right .. ^1].isAtom
  var k = 0
  if word.len > 2 and word[0] == '0' and word[1] in {'X', 'x'}:
    k = 2
    while k < word.len and word[k] in HexDigits + {'_'}: inc k
    if k == 2: return false
    if k == word.len: return true
  else:
    while k < word.len and word[k] in Digits + {'_'}: inc k
    if k == 0: return false
    if k < word.len and word[k] == '.':
      inc k
      while k < word.len and word[k] in Digits + {'_'}: inc k
  if k + 1 >= word.len or word[k] != '\'' or word[k + 1] notin Letters: return false
  word[k + 1 .. ^1] != "s" and word[k + 1 .. ^1].allIt(it in Letters + Digits)


func isName(word: string, names: Names): bool =
  ## Decide whether word is name: Nim type of `TYPES_BARE`, identifier file declares in its
  ##   shape, or dotted name file declares part of, each part two letters or more.
  if word in TYPES_BARE: return true
  if '.' in word:
    let parts = word.split('.')
    return parts.allIt(it.len > 1 and it.isIdentifier) and parts.anyIt(names.every.isFound(it))
  word.isIdentifier and word.isShaped and names.alone.isFound(word)


func isOperator(word: string): bool =
  ## Decide whether word is operator between literals: runes that are no letter, digit or mark
  ##   of prose.
  if word.len == 0 or word in ELLIPSES: return false
  for r in word.runes:
    if r.isAlpha or r.isWhiteSpace: return false
    if int32(r) < 128 and char(int32(r)) in Digits + CHARS_PROSE: return false
  true


func names(source: string): Names =
  ## Read names source declares, enum members apart.
  for d in source.declarations:
    if d.kind != KindName.Member: result.alone.add d.name
    result.every.add d.name
  result.alone = result.alone.deduplicate.sorted
  result.every = result.every.deduplicate.sorted


func masks(text: string): (seq[bool], seq[Span]) =
  ## Mark each byte of text that no span reads, i.e. backtick span and quoted text; and read
  ##   each path in double quotes, as span its quotes hold.
  var
    masked = newSeq[bool](text.len)
    quoted: seq[Span]
    k = 0
  while k < text.len:
    if text[k] notin {'"', '`'}:
      inc k
      continue
    var close = text.find(text[k], k + 1)
    if close < 0: close = text.high
    elif text[k] == '"' and text[k + 1 ..< close].isPath:
      quoted.add Span(kind: KindSpan.Path, first: k, after: close + 1, is_quoted: true)
    for j in k .. close: masked[j] = true
    k = close + 1
  (masked, quoted)


func words(text: string, masked: seq[bool]): seq[Word] =
  ## Read each word of text outside masked bytes, punctuation around it cut.
  var k = 0
  while k < text.len:
    if masked[k] or text[k] in Whitespace:
      inc k
      continue
    var after = k
    while after < text.len and not masked[after] and text[after] notin Whitespace: inc after
    var
      first = k
      last = after
    while first < last and text[first] in CHARS_LEADING: inc first
    while last > first and text[last - 1] in CHARS_TRAILING and text[first ..< last] notin ELLIPSES:
      dec last
    if first < last: result.add Word(first: first, after: last, spelling: text[first ..< last])
    k = after


func spans(text: string, names: Names): seq[Span] =
  ## Read each bare span of text that takes backticks, in order.
  let
    (masked, quoted) = text.masks
    found = text.words(masked)
  result = quoted
  var k = 0
  while k < found.len:
    let spelling = found[k].spelling
    if spelling.isLiteral:

      # Join literals operators part, fillers between them included, into one span.
      var
        last = k
        j = k + 1
      while j + 1 < found.len and found[j].spelling.isOperator and
          (found[j + 1].spelling.isLiteral or found[j + 1].spelling in ELLIPSES):
        if found[j + 1].spelling.isLiteral: last = j + 1
        j += 2
      result.add Span(kind: KindSpan.Literal, first: found[k].first, after: found[last].after)
      k = last + 1
      continue
    if spelling.isPath:
      result.add Span(kind: KindSpan.Path, first: found[k].first, after: found[k].after)
    elif not spelling.isCitation and spelling.isName(names):
      result.add Span(kind: KindSpan.Name, first: found[k].first, after: found[k].after)
    inc k
  result = result.sortedByIt(it.first)


func isAligned(text: string): bool =
  ## Decide whether text holds aligned column: two spaces or more between words, outside
  ##   backticks and quotes, after no closing mark, comma or semicolon, which space prose.
  let (masked, _) = text.masks
  var k = 0
  while k < text.len:
    if text[k] != ' ' or masked[k]:
      inc k
      continue
    var after = k
    while after < text.len and text[after] == ' ' and not masked[after]: inc after
    let before = text[0 ..< k].strip(leading = false, chars = CHARS_CLOSER + {'`'})
    if after - k > 1 and before.len > 0 and after < text.len and
        before[^1] notin MARKS_CLOSING + MARKS_LISTED:
      return true
    k = after


func opening(text: string): int =
  ## Read byte offset where claim of text opens, past bullet marker; `0` where none stands.
  if text.startsWith("- ") or text.startsWith("* "): return 2
  var k = 0
  while k < text.len and text[k] in Digits: inc k
  if k > 0 and k + 1 < text.len and text[k] in {')', '.'} and text[k + 1] == ' ': return k + 2


func isBullet(text: string): bool =
  ## Decide whether text opens with bullet marker, as `- ` or `1. `.
  text.opening > 0


func body(text: string): string =
  ## Cut closing brackets and quotes from end of text, past which closing mark stands.
  text.strip(leading = false, chars = CHARS_CLOSER)


func isAbbreviated(text: string): bool =
  ## Decide whether text ends on abbreviation whose period closes no sentence.
  let lower = text.body.toLowerAscii
  ABBREVIATIONS_INLINE.anyIt(
    lower == it or lower.endsWith(" " & it) or lower.endsWith("(" & it)
  )


func isClosed(text: string, is_listed: bool): bool =
  ## Decide whether text closes claim: closing mark past brackets and quotes, or `,` or `;` before
  ##   bullet; abbreviation closes none.
  let body = text.body
  if body.len == 0 or text.isAbbreviated: return false
  body.endsWith("…") or body[^1] in MARKS_CLOSING or (is_listed and body[^1] in MARKS_LISTED)


func isSentenceEnd(text: string): bool =
  ## Decide whether text ends sentence, so line below it is new claim.
  let body = text.body
  body.len > 0 and body[^1] in MARKS_SENTENCE and not text.isAbbreviated


func wordFirst(text: string, at: int): string =
  ## Read word of text that opens at byte offset.
  var after = at
  while after < text.len and text[after] notin Whitespace: inc after
  text[at ..< after]


func wordLast(text: string): string =
  ## Read last word of text.
  text[text.rfind(' ') + 1 .. ^1]


func isCode(text: string): bool =
  ## Decide whether text of `#` comment reads as code, outside backticks and quotes: nested
  ##   marker, call or index glued to name, operator name, export marker or name in backticks,
  ##   assignment or comparison after name, line ending in `=`, or keyword opening line that ends
  ##   in `:`.
  if text.startsWith("#"): return true
  let (masked, _) = text.masks
  var plain = text
  for k, is_masked in masked:
    if is_masked: plain[k] = ' '
  plain = plain.strip(leading = false)
  if plain.len == 0: return false
  for k in 1 ..< plain.len:
    let is_glued = plain[k - 1] in IdentChars + CHARS_NAMING or text[k - 1] == '`'
    if plain[k] in {'(', '['} and is_glued: return true
  for operator in OPERATORS_CODE:
    var k = plain.find(operator)
    while k > 0:
      if plain[k - 1] in IdentChars + {')', ']'}: return true
      k = plain.find(operator, k + 1)
  plain.endsWith(" =") or (plain.wordFirst(0).isKeyword and plain.endsWith(":"))


func linesCode*(c: Comment): seq[bool] =
  ## Decide of each line of comment whether it holds commented code, which holds no prose: every
  ##   line of `#` comment whose first line stands at even step or reads as code (`isCode`), else
  ##   each `#` line that reads as code. Doc holds none.
  result = newSeq[bool](c.lines.len)
  if c.kind != KindComment.Plain: return
  let first = c.lines.mapIt(it.text.strip.len > 0).find(true)
  if first < 0: return
  if c.lines[first].step mod 2 == 0 or c.lines[first].text.isCode:
    return newSeqWith(c.lines.len, true)
  for i, l in c.lines: result[i] = l.text.isCode


func isClosable(text: string): bool =
  ## Decide whether period fixes claim end of text: last rune is letter, digit, closer or
  ##   backtick, and last word is no function word.
  if text.isAbbreviated or text.wordLast.toLowerAscii in WORDS_CUT: return false
  let last = text.runeAt(text.runeOffset(text.runeLen - 1))
  last.isAlpha or (int32(last) < 128 and char(int32(last)) in Digits + CHARS_CLOSER + {'`'})


func isLabel(c: Comment, lines: seq[string]): bool =
  ## Decide whether comment is label, which carries neither capital nor period: trailing `#`
  ##   comment, own-line `#` comment of one line that opens with no capital or stands deeper than
  ##   code right above it, which it labels, or comment of one line holding one word or opening
  ##   with citation.
  if c.lines.len != 1: return false
  let
    l = c.lines[0]
    above = if l.line > 0: lines[l.line - 1] else: ""
    is_under = above.strip.len > 0 and not above.strip.startsWith("#") and
      above.len - above.strip(trailing = false).len < l.marker
  if l.text.len == 0: return true
  if c.kind == KindComment.Plain and (l.is_trailing or l.text[0] notin {'A' .. 'Z'} or is_under):
    return true
  ' ' notin l.text or l.text.wordFirst(0).isCitation


func stepHead(c: Comment, stepless: seq[bool], i: int): int =
  ## Read step of item that line `i` continues: nearest line above it in its paragraph at smaller
  ##   step; `-1` where none stands.
  for j in countdown(i - 1, 0):
    if stepless[j]: return -1
    if c.lines[j].step < c.lines[i].step: return c.lines[j].step
  -1


func faults(c: Comment, stepless: seq[bool], spans: seq[seq[Span]]): seq[seq[Fault]] =
  ## Read fault of each line of comment: capital where claim starts, closing mark where it ends,
  ##   cut where it ends on function word or other mark, or where lowercase line follows sentence.
  result = newSeq[seq[Fault]](c.lines.len)
  for i, l in c.lines:
    if stepless[i]: continue
    let
      previous = if i > 0 and not stepless[i - 1]: i - 1 else: -1
      next = if i + 1 < c.lines.len and not stepless[i + 1]: i + 1 else: -1
      is_listed = next >= 0 and
        (c.lines[next].text.isBullet or c.lines[next].step == c.stepHead(stepless, i))
      is_start = previous < 0 or l.step < c.lines[previous].step
      is_end = next < 0 or c.lines[next].step < l.step or is_listed
      is_lower = not l.text.isBullet and l.text[0] in {'a' .. 'z'} and
        not spans[i].anyIt(it.first == 0)

    # Claim opens with capital; lowercase line after sentence end is cut.
    if is_lower and is_start:
      result[i].add Fault(kind: KindFault.Capital, at: 0, word: l.text.wordFirst(0))
    elif is_lower and c.lines[previous].text.isSentenceEnd:
      result[i].add Fault(kind: KindFault.Lowercase, at: 0, word: l.text.wordFirst(0))

    # Claim closes with closing mark; period fixes it where line is not cut short.
    if is_end and not l.text.isClosed(is_listed):
      let kind = if l.text.isClosable: KindFault.Period else: KindFault.Cut
      result[i].add Fault(kind: kind, at: l.text.len, word: l.text.wordLast)


func prose(source: string, is_full: bool): seq[Prose] =
  ## Read each line of comment of source that breaks form: spans, and faults of claims where
  ##   `is_full`.
  let
    names = source.names
    lines = source.split('\n')
  for c in source.comments:
    if c.lines.allIt(it.text.strip.len == 0): continue
    let code = c.linesCode
    if code.allIt(it): continue
    var
      stepless = c.lines.isStepless
      is_aligned = false  # Line above is aligned column, or deeper line that continues one.
    for i, l in c.lines:
      is_aligned = l.text.isAligned or (is_aligned and l.step > c.lines[i - 1].step)
      if is_aligned or code[i]: stepless[i] = true
    let
      spans = c.lines.mapIt(it.text.spans(names))
      faults =
        if is_full and not c.isLabel(lines): c.faults(stepless, spans)
        else: newSeq[seq[Fault]](c.lines.len)
    for i, l in c.lines:
      let found = if stepless[i]: @[] else: spans[i]
      if found.len == 0 and faults[i].len == 0: continue
      result.add Prose(
        line: l.line,
        start: l.marker + l.width + l.step,
        text: l.text,
        spans: found,
        faults: faults[i],
      )


func message(text: string, span: Span): string =
  ## Write message of bare span.
  $span.kind & " in comment stands in backticks; got `" & text[span.first ..< span.after] & "`."


func message(fault: Fault): string =
  ## Write message of fault of claim.
  SENTENCES_FAULT[fault.kind] & "; got `" & fault.word & "`."


func reports(path: string, p: Prose): seq[Report] =
  ## Report each span and fault of line, in order of its byte offset.
  var found: seq[(int, string)]
  for span in p.spans: found.add (span.first, p.text.message(span))
  for fault in p.faults: found.add (fault.at, fault.message)
  for (_, message) in found.sortedByIt(it[0]):
    result.add initReport(path, p.line + 1, Rule.FormComment, message)


func shaped(p: Prose, is_wide: bool): (string, int) =
  ## Write text of line with each fix, and count them: capital, and backticks and period unless
  ##   `is_wide` holds them.
  var
    text = p.text
    count = 0
  if not is_wide:
    for fault in p.faults:
      if fault.kind == KindFault.Period:
        text.add '.'
        inc count
    for span in p.spans.reversed:
      if span.is_quoted:
        text[span.first] = '`'
        text[span.after - 1] = '`'
      else:
        text = text[0 ..< span.first] & '`' & text[span.first ..< span.after] & '`' &
          text[span.after .. ^1]
      inc count
  for fault in p.faults:
    if fault.kind == KindFault.Capital:
      text[fault.at] = text[fault.at].toUpperAscii
      inc count
  (text, count)


func fixed(path, source: string, is_full: bool): Fix =
  ## Write each fix of lines of source, line by line, where it widens no line past `LINE_MAX`.
  var lines = source.split('\n')
  for p in source.prose(is_full):
    let
      given = lines[p.line]
      tail = given[p.start + p.text.len .. ^1]
      is_wide = (given[0 ..< p.start] & p.shaped(false)[0] & tail).isWide and not given.isWide
      (text, count) = p.shaped(is_wide)
    lines[p.line] = given[0 ..< p.start] & text & tail
    for _ in 1 .. count: result.fixed.add initReport(path, p.line + 1, Rule.FormComment)
  result.source = lines.join("\n")


func checkClaims*(path, source: string): seq[Report] =
  ## Report claim of comment off its form, and path, literal or name of comment out of backticks.
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for p in source.prose(is_full = true): result.add reports(path, p)


func checkBackticks*(path, source: string): seq[Report] =
  ## Report path, literal or name of comment out of backticks alone, where comments keep their
  ##   own language.
  for p in source.prose(is_full = false): result.add reports(path, p)


func fixClaims*(path, source: string): Fix =
  ## Write capital, period and backticks check reports, where fix is not cut and widens no line.
  fixed(path, source, is_full = true)


func fixBackticks*(path, source: string): Fix =
  ## Write backticks check reports alone, where comments keep their own language.
  fixed(path, source, is_full = false)
