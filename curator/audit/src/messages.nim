## Enforce how message ends: echoing value in backticks, ``"…; got `{value}`."`` (Article IV.4),
##   and fix it (`koch fix`).
##   Message is concatenation of literals and operands joined by `&`, one literal of which holds
##     `; got `. Literal is plain, long, raw (`r"…"`), or interpolated (`&"…"`, `fmt"…"`).
##     Tail runs from `got` to concatenation's end, across lines that `&` ends.
##   Value is interpolation `{…}` of interpolated literal, `{{` aside, or operand that is no
##     literal (`$count`, `name`). It stands in backticks where span that backticks of message
##     open holds it, as message renders, counted from `got`, where earlier spans closed: so
##     `` `{width}x{height}` `` and `` `git " & sub & "` `` hold. Every value of tail is held so.
##   Tail echoing no value ends on word (`got none.`, `got CRLF.`), and is no finding: message
##     then says what it got.
##   Fixer inserts backtick into literal on each side of bare value: around interpolation, at
##     end of literal before operand, and at start of literal after it. Test asserting old
##     text of message changes with it where it builds that text same way.
##   Checks and fixer share one reading (`tails`), so each rule is written once (Article II.1).
##
##   No fixer: operand ending concatenation, since no literal after it takes backtick; value
##     whose backtick would widen line past `LINE_MAX`. Each stays, finding and all.
##   Cost: scanner, never parser; format through `%` (`"$1" % [x]`) is unread.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unicode]
import ./[findings, form, tokens]


type
  Value = object  ## Define one value tail echoes: where it stands, backticks it lacks.
    line: int  ## Zero-based line value stands on.
    text: string  ## Value as written, e.g. `{manner}` or `$count`.
    inserts: seq[int]  ## Byte offsets where backtick goes; empty where none can.

  Piece = object  ## Define one operand of concatenation.
    first: int  ## Index of first token.
    last: int  ## Index of last token.
    literal: int  ## Index of Text token where operand is literal; `-1` for expression.
    is_interpolated: bool  ## Literal is `&"…"` or `fmt"…"`, whose `{…}` are values.


const
  MARKER = "; got "  ## Text message's tail follows.
  LONG_QUOTE = "\"\"\""  ## Delimiter of long literal.
  INTERPOLATORS = ["&", "fmt"]  ## Prefix glued before literal that makes `{…}` value.
  ENDING_KEYWORDS = [
    "and", "do", "elif", "else", "if", "in", "of", "or", "return", "then", "when", "while",
  ]
    ## Keywords ending expression operand of concatenation.
  BACKTICK = '`'  ## Mark value stands between.


func contentOf(t: Token, source: string): (int, int) =
  ## Read byte span of literal's content, quotes left out.
  if source.continuesWith(LONG_QUOTE, t.first): (t.first + 3, t.after - 3)
  else: (t.first + 1, t.after - 1)


func pieceAt(tokens: openArray[Token], partners: openArray[int], k: int, source: string): Piece =
  ## Read operand opening at token `k`: literal, prefixed literal, or expression running to
  ##   next `&` outside brackets, separator, closing bracket or line end `&` does not continue.
  let t = tokens[k]
  if t.kind == TokenKind.Text: return Piece(first: k, last: k, literal: k)
  let text = t.spelling(source)
  if k + 1 < tokens.len and tokens[k + 1].kind == TokenKind.Text and
      tokens[k + 1].first == t.after and t.kind in {TokenKind.Operator, TokenKind.Word}:
    return Piece(first: k, last: k + 1, literal: k + 1, is_interpolated: text in INTERPOLATORS)
  result = Piece(first: k, last: k, literal: -1)
  var j = k
  while j < tokens.len:
    let u = tokens[j]
    if u.kind == TokenKind.Open and partners[j] > j: j = partners[j]
    elif u.kind in {TokenKind.Comma, TokenKind.Semicolon, TokenKind.Close, TokenKind.Comment}:
      break
    elif u.kind == TokenKind.Operator and u.spelling(source) in ["&", ":", "="] and j > k:
      break
    elif u.kind == TokenKind.Word and u.spelling(source) in ENDING_KEYWORDS: break
    elif j > k and tokens[j - 1].lastLine(source) < u.line: break
    result.last = j
    inc j


func chainFrom(
  tokens: openArray[Token], partners: openArray[int], k: int, source: string
): seq[Piece] =
  ## Read concatenation from literal token `k` to its end: each `&` followed by operand.
  result.add Piece(first: k, last: k, literal: k)
  if k > 0 and tokens[k - 1].after == tokens[k].first and
      tokens[k - 1].spelling(source) in INTERPOLATORS:
    result[0].first = k - 1
    result[0].is_interpolated = true
  var at = k + 1
  while at + 1 < tokens.len:
    while at < tokens.len and tokens[at].kind == TokenKind.Comment: inc at
    if at + 1 >= tokens.len or tokens[at].spelling(source) != "&": break
    let piece = pieceAt(tokens, partners, at + 1, source)
    if piece.last < piece.first: break
    result.add piece
    at = piece.last + 1


func valuesOf(chain: seq[Piece], tokens: openArray[Token], tail: int, source: string): seq[Value] =
  ## Read every bare value of chain past byte offset `tail`, with backticks it lacks.
  ##   Backticks of literals are counted from tail, where every span of message before `got`
  ##   has closed, interpolations aside; so value inside span another value or text opens
  ##   (`` `{w}x{h}` ``) is held already.
  var is_inside = false
  for p, piece in chain:
    if piece.literal < 0:
      if is_inside or tokens[piece.first].first < tail: continue
      var value = Value(
        line: tokens[piece.first].line,
        text: source[tokens[piece.first].first ..< tokens[piece.last].after],
      )
      let
        previous = if p > 0: chain[p - 1].literal else: -1
        next = if p + 1 < chain.len: chain[p + 1].literal else: -1
      if previous >= 0 and next >= 0:
        value.inserts.add tokens[previous].contentOf(source)[1]
        value.inserts.add tokens[next].contentOf(source)[0]
      result.add value  # Without literal on each side, no backtick has place.
      continue

    # Count backticks of literal; read each interpolation of it, `{{` aside.
    let (start, stop) = tokens[piece.literal].contentOf(source)
    var k = start
    while k < stop:
      let c = source[k]
      if c == BACKTICK and k >= tail: is_inside = not is_inside
      if c != '{' or not piece.is_interpolated:
        inc k
        continue
      if k + 1 < stop and source[k + 1] == '{':
        k += 2
        continue
      var
        depth = 0
        close = k
      while close < stop:
        if source[close] == '{': inc depth
        elif source[close] == '}':
          dec depth
          if depth == 0: break
        inc close
      if close >= stop: break
      if not is_inside and k >= tail:
        result.add Value(
          line: source[0 ..< k].count('\n'),
          text: source[k .. close],
          inserts: @[k, close + 1],
        )
      k = close + 1


func tails(source: string): seq[Value] =
  ## Find each bare value echoed in tail of message.
  let
    tokens = source.tokens
    partners = tokens.partners
  var seen: seq[int]
  for k, t in tokens:
    if t.kind != TokenKind.Text or k in seen: continue
    let at = source[t.first ..< t.after].rfind(MARKER)
    if at < 0: continue
    let chain = chainFrom(tokens, partners, k, source)
    for piece in chain:
      if piece.literal >= 0: seen.add piece.literal
    result.add valuesOf(chain, tokens, t.first + at + MARKER.len, source)


func checkMessages*(path, source: string): seq[Finding] =
  ## Report value message echoes after `got` without backticks around it (IV.4).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for value in source.tails:
    result.add finding(
      path,
      value.line + 1,
      "Message ends echoing value in backticks, as ``…; got `{value}`.`` (IV.4); got `" &
        value.text & "`.",
    )


func fixMessages*(path, source: string): Fix =
  ## Insert backticks each bare value lacks; value whose backtick would widen line it lands on
  ##   stays whole, with every other value of that line.
  var values = source.tails.filterIt(it.inserts.len > 0)
  result.source = source
  if values.len == 0: return
  let
    starts = source.lineStarts
    lines = source.split('\n')

  # Drop values touching line their backticks would widen, until none is left to drop.
  var shaped: seq[string]
  while true:
    shaped = lines
    var touched: seq[seq[int]]
    for value in values:
      touched.add value.inserts.mapIt(starts.upperBound(it) - 1)
    for (at, line) in zip(values.mapIt(it.inserts).concat, touched.concat).sortedByIt(-it[0]):
      shaped[line].insert($BACKTICK, at - starts[line])
    let widened = toSeq(0 ..< lines.len).filterIt(shaped[it].isWide and not lines[it].isWide)
    if widened.len == 0: break
    var kept: seq[Value]
    for k, value in values:
      if not touched[k].anyIt(it in widened): kept.add value
    values = kept
  result.source = shaped.join("\n")
  for value in values: result.fixed.add finding(path, value.line + 1, "message value (IV.4)")
