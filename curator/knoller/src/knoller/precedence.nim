## Enforce parentheses where reader may misread precedence of condition (Article X.4), and fix
##   what parser's own grouping settles (`koch fix`).
##   Condition mixing `and` with `or`: each run of operands `and` joins, between two `or` (or
##     `xor`), takes parentheses. Parser already groups it so, since `and` binds tighter than
##     `or`, so parentheses move no reading: `a and b or c` becomes `(a and b) or c`.
##   `not` over binary expression: check alone, no fixer. Nim reads `not a == b` as
##     `(not a) == b`, so which parentheses are right depends on intent, and reading holds it.
##     Operator binding looser than comparison (`and`, `or`) reads as reader expects, and is
##     no finding.
##   Expression is read on tokens (`tokens.nim`), at one bracket depth, between delimiters:
##     comma, semicolon, `:`, `=`, bracket, keyword opening statement or branch (`if`,
##     `return`, …), `in` of `for` head, operator binding looser than `or` (arrow, assignment,
##     `@`, `?`), and line break that ends statement. Command call (`check a and b or c`) holds
##     expression after its head: two operands apart by space, no operator between.
##   Operator precedence is lexer's (Nim manual, Operators): first character, keyword, and
##     `=` or arrow ending; only whether operator binds looser than `or`, as `or`, as `and`, or
##     tighter matters here, so every glyph operator reads tighter.
##   Checks and fixer share one reading (`mixtures`), so each rule is written once (Article
##     II.1). Elements of one depth (`elementsOf`) are exported, since message shape reads
##     operators of its value there (`messages.nim`).
##
##   Cost: scanner, never parser; command call nested inside operand (`a and f b or c`) reads
##     from its last head, so such expression may stay unreported.
##   Fixer is widener (`reports.nim`): off held lines it writes parentheses that widen line
##     past `LINE_MAX`, and chain wraps line after; on held line, as in its two-argument form,
##     parentheses that would widen narrow line stay to hand, finding and all.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unicode]
import ./[form, reports, tokens]


type
  ElementKind* {.pure.} = enum  ## Define what one element of expression is to its neighbours.
    Operand  ## Name, literal or bracket group, with call, index and field glued after it.
    Binary  ## Operator between two operands.
    Prefix  ## Operator before its operand.
    Delimiter  ## Token ending expression: separator, `:`, `=`, statement keyword.

  Element* = object  ## Define one element of expression: tokens it spans, kind, precedence.
    first*: int  ## Index of first token.
    last*: int  ## Index of last token; closing bracket where element ends in one.
    kind*: ElementKind
    precedence*: int  ## Precedence of operator; `-1` for any other kind.

  Mixture = object  ## Define runs of `and` that one expression mixing `and` with `or` holds.
    runs: seq[(int, int)]  ## First and last token of each run to parenthesise.
    got: string  ## Expression as written, cut to `EXCERPT_RUNES`.

  Negation = object  ## Define `not` whose operand binary operator follows.
    line: int  ## Zero-based line of `not`.
    got: string  ## `not`, operand and operator, as written.


const
  PRECEDENCE_OR = 3  ## Precedence of `or` and `xor` (Nim manual, Operators).
  PRECEDENCE_AND = 4  ## Precedence of `and`.
  PRECEDENCE_COMPARISON = 5  ## Precedence of `==`, `in`, `is` and `of`, tightest `not` misleads.
  LUT_PRECEDENCE_BY_KEYWORD = [
    ("or", 3), ("xor", 3), ("and", 4), ("in", 5), ("notin", 5), ("is", 5), ("isnot", 5),
    ("of", 5), ("as", 5), ("div", 9), ("mod", 9), ("shl", 9), ("shr", 9),
  ]
    ## Keywords lexer reads as binary operators, with their precedence.
  LUT_PRECEDENCE_BY_FIRST = [
    ('$', 10), ('^', 10), ('*', 9), ('%', 9), ('\\', 9), ('/', 9), ('~', 8), ('+', 8),
    ('-', 8), ('|', 8), ('&', 7), ('.', 6), ('=', 5), ('<', 5), ('>', 5), ('!', 5), ('@', 2),
    (':', 2), ('?', 2),
  ]
    ## Precedence of symbol operator by its first character (Nim manual, Operators).
  ARROWS = ["->", "~>", "=>"]  ## Endings of arrow-like operator, which binds loosest.
  COMPARING_FIRST = {'<', '>', '!', '=', '~', '?'}
    ## First characters whose operator ending with `=` compares rather than assigns.
  STATEMENT_KEYWORDS = [
    "asm", "bind", "block", "break", "case", "const", "continue", "converter", "defer",
    "discard", "do", "elif", "else", "except", "export", "finally", "for", "from", "func",
    "if", "import", "include", "iterator", "let", "macro", "method", "mixin", "proc", "raise",
    "return", "static", "template", "try", "type", "using", "var", "when", "while", "yield",
  ]
    ## Keywords opening statement, branch or expression, which bound expression around them.
  OPERAND_KEYWORDS = ["nil", "true", "false"]  ## Keywords and words standing as operands.
  EXCERPT_RUNES = 40  ## Runes of expression echoed in finding.


func precedenceOf(t: Token, source: string): int =
  ## Read precedence of operator token; `-1` where token is no binary operator.
  let text = t.spelling(source)
  if t.kind == TokenKind.Word:
    for (keyword, precedence) in LUT_PRECEDENCE_BY_KEYWORD:
      if text == keyword: return precedence
    return -1
  if t.kind != TokenKind.Operator: return -1
  if ARROWS.anyIt(text.endsWith(it)): return 0
  if text.len > 1 and text.endsWith("=") and text[0] notin COMPARING_FIRST: return 1
  for (first, precedence) in LUT_PRECEDENCE_BY_FIRST:
    if text[0] == first: return precedence
  9  # Glyph operator binds as tight as `*` or `+`, tighter than any comparison.


func isOperandToken(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether token `k` stands as operand: name, literal, quoted name, `nil`, or keyword
  ##   glued after `.`, which names field (`x.type`).
  let t = tokens[k]
  case t.kind
  of TokenKind.Quoted, TokenKind.Number, TokenKind.Text, TokenKind.Character: true
  of TokenKind.Word:
    let is_field = k > 0 and tokens[k - 1].spelling(source) == "." and
      tokens[k - 1].after == t.first
    t.spelling(source) in OPERAND_KEYWORDS or not t.isKeyword(source) or is_field
  else: false


func elementsOf*(
  tokens: openArray[Token]; partners: openArray[int]; first, last: int; source: string
): seq[Element] =
  ## Read tokens `first` to `last` of one bracket depth as elements; bracket group, and `.`
  ##   with name, glued after operand join it as call, index or field.
  var k = first
  while k <= last:
    let t = tokens[k]
    if t.kind == TokenKind.Comment:
      inc k
      continue
    var e = Element(first: k, last: k, kind: ElementKind.Delimiter, precedence: -1)
    let
      previous = if result.len > 0: result[^1] else: Element(kind: ElementKind.Delimiter)
      is_after_operand = previous.kind == ElementKind.Operand
    if t.kind == TokenKind.Open:
      e.last = if partners[k] > k and partners[k] <= last: partners[k] else: last
      let is_glued = is_after_operand and tokens[previous.last].after == t.first
      if t.spelling(source) notin ["(", "[", "{"]: e.kind = ElementKind.Delimiter
      elif is_glued:
        result[^1].last = e.last
        k = e.last + 1
        continue
      else: e.kind = ElementKind.Operand
    elif t.spelling(source) == "." and is_after_operand and k < last and
        tokens[previous.last].after == t.first and tokens[k + 1].first == t.after and
        tokens[k + 1].kind in {TokenKind.Word, TokenKind.Quoted}:
      # Field or method glued after operand joins it, as call and index do.
      result[^1].last = k + 1
      k += 2
      continue
    elif tokens.isOperandToken(k, source):
      e.kind = ElementKind.Operand
    elif t.kind == TokenKind.Word and t.spelling(source) == "not":
      e.kind = ElementKind.Prefix
    elif t.kind in {TokenKind.Operator, TokenKind.Word} and t.precedenceOf(source) >= 0:
      let
        text = t.spelling(source)
        is_spaced_before = k > 0 and tokens[k - 1].after < t.first
        is_glued_after = k < last and tokens[k + 1].first == t.after
        is_prefix = not is_after_operand or (is_spaced_before and is_glued_after and
          t.kind == TokenKind.Operator and text != ".")
      if text in [":", "="]: e.kind = ElementKind.Delimiter
      elif is_prefix and t.kind == TokenKind.Operator: e.kind = ElementKind.Prefix
      elif is_prefix: e.kind = ElementKind.Delimiter
      else:
        e.kind = ElementKind.Binary
        e.precedence = t.precedenceOf(source)
        if e.precedence < PRECEDENCE_OR: e.kind = ElementKind.Delimiter
    result.add e
    k = e.last + 1


func isStatementBreak(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether line break before token `k` ends statement: token before it neither
  ##   operator, keyword operator, separator nor opening bracket.
  if k == 0 or tokens[k - 1].lastLine(source) == tokens[k].line: return false
  var previous = k - 1
  while previous > 0 and tokens[previous].kind == TokenKind.Comment: dec previous
  let before = tokens[previous]
  if before.kind in {TokenKind.Operator, TokenKind.Comma, TokenKind.Open}: return false
  before.precedenceOf(source) < 0


func segmentsOf(
  tokens: openArray[Token]; partners: openArray[int]; first, last: int; source: string
): seq[seq[Element]] =
  ## Split one bracket depth into expressions between delimiters, nested depths included.
  let elements = elementsOf(tokens, partners, first, last, source)
  var
    segment: seq[Element]
    is_for_head = false
  for e in elements:
    let
      t = tokens[e.first]
      text = t.spelling(source)
      is_breaking = segment.len > 0 and first == 0 and tokens.isStatementBreak(e.first, source)
      is_keyword = t.kind == TokenKind.Word and text in STATEMENT_KEYWORDS
      is_branch = t.kind == TokenKind.Word and text == "of" and
        (e.first == 0 or tokens[e.first - 1].lastLine(source) < t.line)
      is_loop_in = is_for_head and t.kind == TokenKind.Word and text == "in"
    if text == "for": is_for_head = true
    if is_loop_in or text == ":": is_for_head = false
    if e.kind == ElementKind.Delimiter or is_keyword or is_branch or is_loop_in or is_breaking:
      if segment.len > 0: result.add segment
      segment = @[]
      if not (e.kind == ElementKind.Delimiter or is_keyword or is_branch or is_loop_in):
        segment.add e
    else: segment.add e
  if segment.len > 0: result.add segment

  # Read every bracket group of this depth, glued or not, as depths of their own.
  var k = first
  while k <= last:
    if tokens[k].kind == TokenKind.Open and partners[k] > k and partners[k] <= last:
      result.add segmentsOf(tokens, partners, k + 1, partners[k] - 1, source)
      k = partners[k]
    inc k


func commandTail(segment: seq[Element], tokens: openArray[Token]): seq[Element] =
  ## Read expression command call holds after its last head: element after two operands apart
  ##   by space with no operator between, or after operand and prefix operator spaced so.
  var start = 0
  for j in 1 ..< segment.len:
    let
      before = segment[j - 1]
      e = segment[j]
      is_spaced = tokens[before.last].after < tokens[e.first].first
    if before.kind == ElementKind.Operand and
        e.kind in {ElementKind.Operand, ElementKind.Prefix} and is_spaced:
      start = j
  segment[start .. ^1]


func excerpt(source: string; tokens: openArray[Token]; first, last: int): string =
  ## Echo tokens `first` to `last` as written, lines joined, cut to `EXCERPT_RUNES`.
  let text = strutils.splitWhitespace(source[tokens[first].first ..< tokens[last].after]).join(" ")
  if text.runeLen <= EXCERPT_RUNES: text else: text.runeSubStr(0, EXCERPT_RUNES) & "…"


func mixtures(source: string): seq[Mixture] =
  ## Find each expression mixing `and` with `or`, and runs of `and` in it to parenthesise.
  let
    tokens = source.tokens
    partners = tokens.partners
  if tokens.len == 0: return
  for segment in segmentsOf(tokens, partners, 0, tokens.high, source):
    let expression = segment.commandTail(tokens)
    if expression.len == 0: continue
    let
      is_or = expression.anyIt(it.kind == ElementKind.Binary and it.precedence == PRECEDENCE_OR)
      is_and = expression.anyIt(it.kind == ElementKind.Binary and it.precedence == PRECEDENCE_AND)
    if not (is_or and is_and): continue
    var
      mixture = Mixture(got: excerpt(source, tokens, expression[0].first, expression[^1].last))
      run_first = 0
      is_read = true  # Each run opens on operand and ends on one, or expression is unread.
    for j in 0 .. expression.len:
      let is_end = j == expression.len or
        (expression[j].kind == ElementKind.Binary and expression[j].precedence == PRECEDENCE_OR)
      if not is_end: continue
      let run = expression[run_first ..< j]
      run_first = j + 1
      if run.len == 0 or run[0].kind == ElementKind.Binary or run[^1].kind != ElementKind.Operand:
        is_read = false
        break
      if run.anyIt(it.kind == ElementKind.Binary and it.precedence == PRECEDENCE_AND):
        mixture.runs.add (run[0].first, run[^1].last)
    if is_read: result.add mixture


func checkMixtures*(path, source: string): seq[Report] =
  ## Report expression mixing `and` with `or` without parentheses around each `and` (X.4).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  let tokens = source.tokens
  for mixture in source.mixtures:
    result.add initReport(
      path,
      tokens[mixture.runs[0][0]].line + 1,
      Rule.AndWithOr,
      "Condition mixing `and` with `or` parenthesises each `and` (X.4); got `" & mixture.got & "`.",
    )


func fixMixtures*(path, source: string; held: Held): Fix =
  ## Parenthesise each run of `and` check reports, as parser groups it, unless held line would
  ##   be wide; expression whose parentheses cannot all fit stays whole.
  let tokens = source.tokens
  var inserts: seq[(int, string)]
  for mixture in source.mixtures:
    var planned: seq[(int, string)]
    for (first, last) in mixture.runs:
      planned.add (tokens[first].first, "(")
      planned.add (tokens[last].after, ")")
    var shaped = source
    for (at, text) in planned.sortedByIt(-it[0]): shaped.insert(text, at)
    let
      lines = tokens[mixture.runs[0][0]].line .. tokens[mixture.runs[^1][1]].lastLine(source)
      before = source.split('\n')
      after = shaped.split('\n')
    if lines.toSeq.anyIt(held.isHeld(it + 1) and after[it].isWide and not before[it].isWide):
      continue
    inserts.add planned
    result.fixed.add initReport(path, tokens[mixture.runs[0][0]].line + 1, Rule.AndWithOr)
  result.source = source
  for (at, text) in inserts.sortedByIt(-it[0]): result.source.insert(text, at)


func fixMixtures*(path, source: string): Fix =
  ## Parenthesise each run of `and` check reports, unless line would be wide.
  fixMixtures(path, source, EVERY)


func negations(source: string): seq[Negation] =
  ## Find each `not` whose operand binary operator binding as tight as comparison follows.
  let
    tokens = source.tokens
    partners = tokens.partners
  if tokens.len == 0: return
  for segment in segmentsOf(tokens, partners, 0, tokens.high, source):
    for j, e in segment:
      if e.kind != ElementKind.Prefix or tokens[e.first].spelling(source) != "not": continue
      var operand = j + 1
      while operand < segment.len and segment[operand].kind == ElementKind.Prefix: inc operand
      if operand + 1 >= segment.len or segment[operand].kind != ElementKind.Operand: continue
      let after = segment[operand + 1]
      if after.kind != ElementKind.Binary or after.precedence < PRECEDENCE_COMPARISON: continue
      if tokens[after.first].spelling(source) == ".": continue
      let stop = if operand + 2 < segment.len: segment[operand + 2].last else: after.last
      result.add Negation(line: tokens[e.first].line, got: excerpt(source, tokens, e.first, stop))


func checkNegations*(path, source: string): seq[Report] =
  ## Report `not` over binary expression without parentheses (X.4); reading holds fix.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for negation in source.negations:
    result.add initReport(
      path,
      negation.line + 1,
      Rule.NotOverBinary,
      "`not` over binary expression takes parentheses, since Nim reads `not a == b` as " &
        "`(not a) == b` (X.4); got `" & negation.got & "`.",
    )
