## Enforce how message echoes each value in backticks, ``"…; got `{value}`."`` (Article IV.4), and
##   that interpolated string takes each value in braces (STYLE.md §3); fix both (`koch fix`).
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
##   Operand ending concatenation has no literal after it, so fixer gives message fixed shape:
##     backtick at end of literal before it, and `& "`."` after it, so message ends on its
##     value. Shape needs value whose every operator binds tighter than `&`: one binding as
##     loose or looser (`"got " & a == b`) would take appended literal into another operand,
##     so it stays, finding and all.
##   Checks and fixer share one reading (`tails`), so each rule is written once (Article II.1).
##   Each value of message stands in backticks, wherever it stands, as Architect ruled on rule 6
##     of #443 (`checkEchoes`): message is argument of call that takes one (`CALLS_MESSAGE`), or
##     value of pragma (`PRAGMAS_MESSAGE`), where it holds literal. Value tail of message value
##     reads takes no second report; value opening its claim, words after it, stays for hand.
##   Interpolated string takes each value in braces, never by `&`, as Architect ruled on rule 21
##     of #443 (`checkInterpolations`): concatenation holding interpolated literal and joining
##     operand or literal to it by `&` reports, read by precedence (`segments`), split where
##     operator binds looser than `&`. Fixer joins it into one literal: prefix of first
##     interpolated literal kept, `$x` as `{x}`, text of plain literal with each brace doubled.
##   Wrap of literals whose joined line would not fit `LINE_MAX`, by runes alone, passes (X.1).
##     Value holding quote, brace, backslash, backtick, line break or colon outside brackets,
##     raw or long literal, escape kept literal reads otherwise, comment between operands, and
##     join that would not fit stay for hand, report and all. Chain runs fixer only where project
##     declares no `formatValue`, which interpolation calls in place of `$` (`chain.nim`).
##
##   Fixer is widener (`reports.nim`): off held line it writes backtick or shape that widens
##     line past `LINE_MAX`, and chain wraps line after; on held line, as in its two-argument
##     form, value whose backtick would widen narrow line stays, finding and all.
##   Cost: scanner, never parser; format through `%` (`"$1" % [x]`) is unread.
##   Cost: `formatValue` of dependency is unread, and wrap holding value that would not fit
##           stays whole, though join inside one of its lines would fit.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
from std/unicode import runeLen
import ./[declared, form, precedence, reports, tokens]


type
  Value = object  ## Define one value message echoes: where it stands, text it lacks.
    line: int  ## Zero-based line value stands on.
    first: int  ## Byte offset where value starts in source.
    text: string  ## Value as written, e.g. `{manner}` or `$count`.
    inserts: seq[(int, string)]  ## Byte offset and text of each insert; empty where none can.

  Piece = object  ## Define one operand of concatenation.
    first: int  ## Index of first token.
    last: int  ## Index of last token.
    literal: int  ## Index of Text token where operand is literal; `-1` for expression.
    is_interpolated: bool  ## Literal is `&"…"` or `fmt"…"`, whose `{…}` are values.

  KindRun {.pure.} = enum  ## Define what one operand of concatenation is to literal it joins into.
    Interpolated  ## Interpolated literal, `&"…"` or `fmt"…"`, whose text joins as written.
    Plain  ## Plain literal, whose text joins with each brace doubled.
    Value  ## Operand that is no literal, which joins in braces.
    Unread  ## Raw or other prefixed literal, which one literal cannot hold alike.

  Join = object  ## Define one concatenation joining operand or literal to interpolated literal.
    line: int  ## Zero-based line concatenation opens on.
    first: int  ## Byte offset where concatenation starts.
    after: int  ## Byte offset after its end.
    got: string  ## First operand joined to first interpolated literal, as written.
    text: string  ## One literal concatenation joins into; empty where it stays for hand.


const
  MARKER = "; got "  ## Text message's tail follows.
  QUOTE_LONG = "\"\"\""  ## Delimiter of long literal.
  KEYWORDS_ENDING = [
    "and", "do", "elif", "else", "if", "in", "of", "or", "return", "then", "when", "while",
  ]
    ## Keywords ending expression operand of concatenation.
  BACKTICK = '`'  ## Mark value stands between.
  ENDING = " & \"`.\""  ## Literal shape appends after value ending concatenation.
  ENDING_ECHO = " & \"`\""
    ## Literal shape appends after value ending message, which takes form of its own (rule 6).
  CALLS_MESSAGE = [
    ("assert", 1), ("doAssert", 1), ("error", 0), ("newException", 1), ("quit", 0),
    ("raiseAssert", 0), ("warning", 0),
  ]
    ## Routine that takes message, and index of argument that holds it.
  PRAGMAS_MESSAGE = ["error", "fatal", "warning"]  ## Pragmas whose value is message.
  PRECEDENCE_CONCATENATION = 7
    ## Precedence of `&` (Nim manual, Operators), which each operator of shaped value exceeds.
  CHARS_UNREAD = {'"', '{', '}', '\\', '`', '\n'}
    ## Characters value cannot hold inside braces: each fails to compile there or reads otherwise.
  ESCAPES_NUMERIC = {'x', 'u', 'U'} + Digits
    ## Escape letters whose character may spell brace, which interpolation then reads as value.


func content(t: Token, source: string): (int, int) =
  ## Read byte span of literal's content, quotes left out.
  if source.continuesWith(QUOTE_LONG, t.first): (t.first + 3, t.after - 3)
  else: (t.first + 1, t.after - 1)


func pieceAt(tokens: openArray[Token], partners: openArray[int], k: int, source: string): Piece =
  ## Read operand opening at token `k`: literal, prefixed literal, or expression running to
  ##   next `&` outside brackets, separator, closing bracket or line end `&` does not continue.
  let t = tokens[k]
  if t.kind == KindToken.Text: return Piece(first: k, last: k, literal: k)
  if k + 1 < tokens.len and tokens[k + 1].kind == KindToken.Text and
      tokens[k + 1].first == t.after and t.kind in {KindToken.Operator, KindToken.Word}:
    return Piece(first: k, last: k + 1, literal: k + 1,
      is_interpolated: tokens.isInterpolated(k + 1, source))
  result = Piece(first: k, last: k - 1, literal: -1)  # Token that opens no operand gives none.
  var j = k
  while j < tokens.len:
    let u = tokens[j]
    # Line end comes first: bracket that opens next line opens next statement, never this one.
    if j > k and tokens[j - 1].lineLast(source) < u.line: break
    if u.kind == KindToken.Open and partners[j] > j: j = partners[j]
    elif u.kind in {KindToken.Comma, KindToken.Semicolon, KindToken.Close, KindToken.Comment}:
      break
    elif u.kind == KindToken.Operator and u.spelling(source) in ["&", ":", "="] and j > k:
      break
    elif u.kind == KindToken.Word and u.spelling(source) in KEYWORDS_ENDING: break
    result.last = j
    inc j


func chainOn(
  tokens: openArray[Token], partners: openArray[int], head: Piece, source: string
): seq[Piece] =
  ## Read concatenation from its first operand to its end: each `&` followed by operand.
  result.add head
  var
    at = head.last + 1
    last = head.last  # Last token of operand before next `&`.
  while at + 1 < tokens.len:
    while at < tokens.len and tokens[at].kind == KindToken.Comment: inc at
    if at + 1 >= tokens.len or tokens[at].spelling(source) != "&": break
    # Joining `&` stands on line its operand ends: Nim continues line binary operator ends,
    #   never one it opens, so `&` opening line opens next statement, as `&"…"`.
    if tokens[at].line != tokens[last].lineLast(source): break
    var next = at + 1  # Comment after `&` that ends line stands before operand on next line.
    while next < tokens.len and tokens[next].kind == KindToken.Comment: inc next
    if next >= tokens.len: break
    let piece = pieceAt(tokens, partners, next, source)
    if piece.last < piece.first: break
    result.add piece
    last = piece.last
    at = piece.last + 1


func chainFrom(
  tokens: openArray[Token], partners: openArray[int], k: int, source: string
): seq[Piece] =
  ## Read concatenation from literal token `k` to its end.
  var head = Piece(first: k, last: k, literal: k)
  if tokens.isInterpolated(k, source):
    head.first = k - 1
    head.is_interpolated = true
  chainOn(tokens, partners, head, source)


func isShapeable(
  piece: Piece, tokens: openArray[Token], partners: openArray[int], source: string
): bool =
  ## Decide whether value may end message in shape: each operator of it binds tighter than `&`,
  ##   so literal appended after it joins concatenation, never value.
  elements(tokens, partners, piece.first, piece.last, source).allIt(
    it.kind in {KindElement.Operand, KindElement.Prefix} or
        (it.kind == KindElement.Binary and it.precedence > PRECEDENCE_CONCATENATION)
  )


func valuesBare(
  chain: seq[Piece];
  tokens: openArray[Token];
  partners: openArray[int];
  tail: int;
  source: string;
  ending = ENDING;
): seq[Value] =
  ## Read every bare value of chain past byte offset `tail`, with backticks or shape it lacks.
  ##   Backticks of literals are counted from tail, where every span of message before `got`
  ##   has closed, interpolations aside; so value inside span another value or text opens
  ##   (`` `{w}x{h}` ``) is held already.
  var is_inside = false
  for p, piece in chain:
    if piece.literal < 0:
      if is_inside or tokens[piece.first].first < tail: continue
      var value = Value(
        line: tokens[piece.first].line,
        first: tokens[piece.first].first,
        text: source[tokens[piece.first].first ..< tokens[piece.last].after],
      )
      let
        previous = if p > 0: chain[p - 1].literal else: -1
        next = if p + 1 < chain.len: chain[p + 1].literal else: -1
      if previous >= 0 and next >= 0:
        value.inserts.add (tokens[previous].content(source)[1], $BACKTICK)
        value.inserts.add (tokens[next].content(source)[0], $BACKTICK)
      elif previous >= 0 and p == chain.high and piece.isShapeable(tokens, partners, source):
        value.inserts.add (tokens[previous].content(source)[1], $BACKTICK)
        value.inserts.add (tokens[piece.last].after, ending)
      result.add value  # Without literal before it, no backtick has place.
      continue

    # Count backticks of literal; read each interpolation of it, `{{` aside.
    let (start, stop) = tokens[piece.literal].content(source)
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
          first: k,
          text: source[k .. close],
          inserts: @[(k, $BACKTICK), (close + 1, $BACKTICK)],
        )
      k = close + 1


func tails(source: string): seq[Value] =
  ## Find each bare value echoed in tail of message.
  let
    tokens = source.tokens
    partners = tokens.partners
  var seen: seq[int]
  for k, t in tokens:
    if t.kind != KindToken.Text or k in seen: continue
    let at = source[t.first ..< t.after].rfind(MARKER)
    if at < 0: continue
    let chain = chainFrom(tokens, partners, k, source)
    for piece in chain:
      if piece.literal >= 0: seen.add piece.literal
    result.add valuesBare(chain, tokens, partners, t.first + at + MARKER.len, source)


func checkMessages*(path, source: string): seq[Report] =
  ## Report value message echoes after `got` without backticks around it (IV.4).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for value in source.tails:
    result.add initReport(
      path,
      value.line + 1,
      Rule.ValueMessage,
      "Message ends echoing value in backticks, as ``…; got `{value}`.``; got `" &
        value.text & "`.",
    )


func inserted(path, source: string; found: seq[Value]; held: Held; rule: Rule): Fix =
  ## Insert backticks or shape each value lacks; value whose insert would widen held line it
  ##   lands on stays whole, with every other value of that line.
  var values = found.filterIt(it.inserts.len > 0)
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
      touched.add value.inserts.mapIt(starts.upperBound(it[0]) - 1)
    let inserts = zip(values.mapIt(it.inserts).concat, touched.concat)
    for (insert, line) in inserts.sortedByIt(-it[0][0]):
      shaped[line].insert(insert[1], insert[0] - starts[line])
    let widened = toSeq(0 ..< lines.len).filterIt(
      held.isHeld(it + 1) and shaped[it].isWide and not lines[it].isWide
    )
    if widened.len == 0: break
    var kept: seq[Value]
    for k, value in values:
      if not touched[k].anyIt(it in widened): kept.add value
    values = kept
  result.source = shaped.join("\n")
  for value in values: result.fixed.add initReport(path, value.line + 1, rule)


func fixMessages*(path, source: string; held: Held): Fix =
  ## Insert backticks or shape each bare value of tail lacks, where held line stays narrow.
  inserted(path, source, source.tails, held, Rule.ValueMessage)


func fixMessages*(path, source: string): Fix =
  ## Insert backticks or shape each bare value lacks, unless line they land on would be wide.
  fixMessages(path, source, EVERY)


func argument(
  tokens: openArray[Token]; partners: openArray[int]; k, index: int; source: string
): int =
  ## Read first token of argument `index` of call whose name is token `k`, in call form or in
  ##   command form, over lines that comma ends; `-1` where call takes no such argument.
  if k + 1 >= tokens.len: return -1
  let
    t = tokens[k]
    open = tokens[k + 1]
    is_call = open.kind == KindToken.Open and open.first == t.after and
      open.spelling(source) == "("
  if not is_call and (open.line != t.line or open.first == t.after or
      open.kind in {KindToken.Close, KindToken.Comma, KindToken.Semicolon, KindToken.Comment} or
      (open.kind == KindToken.Operator and open.spelling(source) notin ["&", "$"])):
    return -1
  let close = if is_call: partners[k + 1] else: tokens.len
  var
    j = if is_call: k + 2 else: k + 1
    count = 0
  if is_call and j >= close: return -1
  while j < close:
    if count == index: return j
    let u = tokens[j]
    if u.kind == KindToken.Open and partners[j] > j:
      j = partners[j] + 1
      continue
    if u.kind == KindToken.Comma: inc count
    elif not is_call and j > k + 1 and u.line > tokens[j - 1].lineLast(source) and
        tokens[j - 1].kind != KindToken.Comma and
        not (tokens[j - 1].kind == KindToken.Operator and tokens[j - 1].spelling(source) == "&"):
      return -1  # Statement of command form ends at line that comma or `&` does not end.
    inc j
  -1


func messages(tokens: openArray[Token], partners: openArray[int], source: string): seq[seq[Piece]] =
  ## Read concatenation of each message: argument of call that takes message (`CALLS_MESSAGE`),
  ##   or value of pragma (`PRAGMAS_MESSAGE`), where it holds literal.
  for k, t in tokens:
    if t.kind != KindToken.Word: continue
    let name = t.spelling(source)
    var first = -1
    for (call, index) in CALLS_MESSAGE:
      if name == call: first = argument(tokens, partners, k, index, source)
    if name in PRAGMAS_MESSAGE and k + 2 < tokens.len and tokens[k + 1].spelling(source) == ":":
      first = k + 2
    if first < 0: continue
    let head = pieceAt(tokens, partners, first, source)
    if head.last < head.first: continue
    let chain = chainOn(tokens, partners, head, source)
    if chain.anyIt(it.literal >= 0): result.add chain


func opening(
  chain: seq[Piece], tokens: openArray[Token], source: string
): tuple[line: int, value, rest: string] =
  ## Read value that opens claim of message, and text of its literal after it; empty value
  ##   where message opens with text, or holds no text after value.
  let head = chain[0]
  if head.literal < 0:
    if chain.len < 2 or chain[1].literal < 0: return
    let (start, stop) = tokens[chain[1].literal].content(source)
    result = (
      tokens[head.first].line,
      source[tokens[head.first].first ..< tokens[head.last].after],
      source[start ..< stop].strip(chars = Whitespace + {BACKTICK}),
    )
  elif head.is_interpolated:
    let (start, stop) = tokens[head.literal].content(source)
    var k = start
    while k < stop and source[k] in Whitespace + {BACKTICK}: inc k
    if k + 1 >= stop or source[k] != '{' or source[k + 1] == '{': return
    let close = source.find('}', k)
    if close < 0 or close >= stop: return
    result = (
      source[0 ..< k].count('\n'),
      source[k .. close],
      source[close + 1 ..< stop].strip(chars = Whitespace + {BACKTICK}),
    )
  if not result.rest.anyIt(it in Letters): result.value = ""


func echoes(source: string): tuple[bare: seq[Value], opened: seq[(int, string, string)]] =
  ## Read each bare value of message that tail of message value does not read, and each value
  ##   that opens claim of its message, with text after it.
  let
    tokens = source.tokens
    partners = tokens.partners
    tailed = source.tails.mapIt(it.first)
  for chain in messages(tokens, partners, source):
    let start = tokens[chain[0].first].first
    for value in valuesBare(chain, tokens, partners, start, source, ENDING_ECHO):
      if value.first notin tailed and value notin result.bare: result.bare.add value
    let (line, value, rest) = chain.opening(tokens, source)
    if value.len > 0 and (line, value, rest) notin result.opened:
      result.opened.add (line, value, rest)


func checkEchoes*(path, source: string): seq[Report] =
  ## Report bare value of message, before `got` or with none, and value that opens its claim of
  ##   message, which stays for hand (IV.4).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  let (bare, opened) = source.echoes
  var found: seq[(int, int, string)]
  for value in bare:
    found.add (value.line, value.first,
      "Message echoes each value in backticks, so empty value stays visible; got `" &
        value.text & "`.")
  for (line, value, rest) in opened:
    found.add (line, int.high,
      "Message states its claim before its value, so hand rewords it; got `" & value &
        "` before `" & rest & "`.")
  for (line, _, message) in found.sortedByIt((it[0], it[1])):
    result.add initReport(path, line + 1, Rule.EchoMessage, message)


func fixEchoes*(path, source: string; held: Held): Fix =
  ## Insert backticks each bare value of message lacks, where held line stays narrow.
  inserted(path, source, source.echoes.bare, held, Rule.EchoMessage)


func fixEchoes*(path, source: string): Fix =
  ## Insert backticks each bare value of message lacks, unless line they land on would be wide.
  fixEchoes(path, source, EVERY)


func kindRun(run: seq[Element]; tokens: openArray[Token]; source: string): KindRun =
  ## Read what operand of concatenation is: interpolated or plain literal, value, or literal of
  ##   other prefix, which one literal cannot hold alike.
  let
    first = run[0].first
    last = run[^1].last
  if tokens[last].kind != KindToken.Text or last - first > 1: return KindRun.Value
  if last == first: return KindRun.Plain
  if tokens[first].after != tokens[last].first: return KindRun.Value
  if tokens.isInterpolated(last, source): KindRun.Interpolated else: KindRun.Unread


func isColonBare(text: string): bool =
  ## Decide whether text holds `:` outside brackets, which interpolation reads as its format.
  var depth = 0
  for c in text:
    case c
    of '(', '[', '{': inc depth
    of ')', ']', '}': dec depth
    of ':':
      if depth == 0: return true
    else: discard


func isEscapeNumeric(text: string): bool =
  ## Decide whether text holds escape by number, whose character may spell brace.
  for k in 0 ..< text.high:
    if text[k] == '\\' and text[k + 1] in ESCAPES_NUMERIC: return true


func joining(
  part: seq[Element]; tokens: openArray[Token]; partners: openArray[int]; source: string
): seq[Join] =
  ## Read concatenation one operand of looser operator spans, where it holds interpolated literal,
  ##   with literal it joins into; none where no `&` joins it, or other operator of `&`'s level.
  var runs = @[newSeq[Element]()]
  for e in part:
    if e.kind == KindElement.Binary and e.precedence == PRECEDENCE_CONCATENATION:
      if tokens[e.first].spelling(source) != "&": return
      runs.add newSeq[Element]()
    else: runs[^1].add e
  if runs.len < 2 or runs.anyIt(it.len == 0): return
  let
    kinds = runs.mapIt(it.kindRun(tokens, source))
    head = kinds.find(KindRun.Interpolated)
  if head < 0: return  # plain join stays `&`, which costs less than interpolation (D1)
  let
    first = runs[0][0].first
    last = runs[^1][^1].last
    prefix = tokens[runs[head][0].first].spelling(source)
  var
    content = ""
    got = ""
    is_read = toSeq(first .. last).allIt(tokens[it].kind != KindToken.Comment)

  # Join text of each operand, each value in braces, and read whether one literal holds it alike.
  for r, run in runs:
    let
      a = run[0].first
      b = run[^1].last
    if r != head and got.len == 0:
      got = source[tokens[a].first ..< tokens[b].after].splitLines.mapIt(it.strip).join(" ")
    case kinds[r]
    of KindRun.Interpolated, KindRun.Plain:
      let
        (start, stop) = tokens[b].content(source)
        text = source[start ..< stop]
        is_other = kinds[r] == KindRun.Plain or tokens[a].spelling(source) != prefix
      if source.continuesWith(QUOTE_LONG, tokens[b].first): is_read = false
      # `fmt"…"` is raw, `&"…"` reads escapes: text of other form reads otherwise in kept one.
      if is_other and (prefix != "&" or kinds[r] == KindRun.Interpolated) and
          ('\\' in text or '"' in text):
        is_read = false
      if kinds[r] == KindRun.Plain:
        if text.isEscapeNumeric: is_read = false
        content.add text.multiReplace(("{", "{{"), ("}", "}}"))
      else: content.add text
    of KindRun.Value:
      var (start, stop) = (tokens[a].first, tokens[b].after)
      # Braces turn value to text by `$` (`formatValue`), so `$x` reads `x`, and group its content.
      if run.len == 2 and run[0].kind == KindElement.Prefix and tokens[a].spelling(source) == "$":
        let operand = run[1].first
        start = tokens[operand].first
        if tokens[operand].kind == KindToken.Open and tokens[operand].spelling(source) == "(" and
            partners[operand] == b:
          (start, stop) = (tokens[operand].after, tokens[b].first)
      let text = source[start ..< stop].strip
      if text.anyIt(it in CHARS_UNREAD) or text.isColonBare: is_read = false
      content.add "{" & text & "}"
    of KindRun.Unread: is_read = false

  # Wrap of literals whose joined line would not fit passes (X.1).
  let
    starts = source.lineStarts
    line = tokens[first].line
    joined = prefix & "\"" & content & "\""
    ending = source.find('\n', tokens[last].after)
    rest = source[tokens[last].after ..< (if ending < 0: source.len else: ending)]
    is_fit = (source[starts[line] ..< tokens[first].first] & joined & rest).runeLen <= LINE_MAX
      # runes alone, since width check lets line of one long token stand
    is_wrap = tokens[last].lineLast(source) > line
  if is_wrap and not is_fit and kinds.allIt(it in {KindRun.Interpolated, KindRun.Plain}): return
  result.add Join(
    line: line,
    first: tokens[first].first,
    after: tokens[last].after,
    got: got,
    text: if is_read and is_fit: joined else: "",
  )


func joins(source: string): seq[Join] =
  ## Read each concatenation joining operand or literal to interpolated literal by `&`, in each
  ##   expression of each depth, split where operator binds looser than `&` (`precedence.nim`).
  let
    tokens = source.tokens
    partners = tokens.partners
  for segment in segments(tokens, partners, 0, tokens.high, source):
    var part: seq[Element]
    for e in segment.tailCommand(tokens):
      if e.kind == KindElement.Binary and e.precedence < PRECEDENCE_CONCATENATION:
        result.add part.joining(tokens, partners, source)
        part = @[]
      else: part.add e
    result.add part.joining(tokens, partners, source)


func isDeclaringFormatValue*(source: string): bool =
  ## Decide whether source declares routine `formatValue`, which interpolation calls in place of
  ##   `$`, so join of value into literal could print it otherwise in its project.
  source.declarations.anyIt(
    it.kind == KindName.Routine and it.name.nimIdentNormalize == "formatValue".nimIdentNormalize
  )


func checkInterpolations*(path, source: string): seq[Report] =
  ## Report concatenation joining value or literal to interpolated literal by `&` (STYLE.md §3).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for join in source.joins.sortedByIt(it.first):
    result.add initReport(
      path,
      join.line + 1,
      Rule.BracesInterpolation,
      "Interpolated string takes each value in braces, never by `&`; got `" & join.got & "`.",
    )


func fixInterpolations*(path, source: string): Fix =
  ## Join each concatenation into its one literal where it reads alike and joined line fits
  ##   `LINE_MAX`; join of wrap removes lines it spans, and `origin` traces each line left.
  result.source = source
  var joins = source.joins.filterIt(it.text.len > 0).sortedByIt(it.first)
  if joins.len == 0: return

  # Join all; drop join whose line two joins widen past `LINE_MAX`, until none is left to drop.
  var shaped: string
  while joins.len > 0:
    shaped = ""
    var
      at = 0
      lines: seq[int]
    for join in joins:
      shaped.add source[at ..< join.first]
      lines.add shaped.count('\n')
      shaped.add join.text
      at = join.after
    shaped.add source[at .. ^1]
    let wide = toSeq(0 ..< joins.len).filterIt(shaped.split('\n')[lines[it]].runeLen > LINE_MAX)
    if wide.len == 0: break
    joins = toSeq(0 ..< joins.len).filterIt(it notin wide).mapIt(joins[it])
  if joins.len == 0: return
  result.source = shaped

  # Trace each line left to its input line; each line join removes folds into line above it.
  var removed: seq[int]
  for join in joins:
    let line = source[0 ..< join.first].count('\n')
    for k in 1 .. source[join.first ..< join.after].count('\n'): removed.add line + k
    result.fixed.add initReport(path, join.line + 1, Rule.BracesInterpolation)
  if removed.len > 0:
    result.origin = toSeq(0 .. source.count('\n')).filterIt(it notin removed).mapIt(it + 1)
