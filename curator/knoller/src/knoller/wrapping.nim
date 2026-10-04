## Enforce how Nim lists separate and wrap (Article X.3, STYLE.md §5), and fix it (`koch fix`).
##   Parameters: `,` between groups while every type appears once; where one group holds several
##     names of one type (`a, b: X`), `;` between every group, trailing one included. Holds on one
##     line and across several, in routine, routine type and lambda.
##   Tuple type: `,` between fields (STYLE.md §5); `tuple[a, b: int, c: X]` and `;` form parse
##     alike, so rewrite moves no reading; comment after field stays.
##   Signature: one fitting `LINE_MAX` stands on one line, and wrapped one that would fit is
##     joined. Otherwise parameters take one line of their own, indented one level, where that
##     line fits (X.3); else each group takes own line, with trailing separator. Either way
##     `)` opens closing line with return type and pragmas. One parameter alone on its line is
##     list written one item to line, so it takes separator.
##   Call: one fitting its line stays, and wrapped one that would fit is joined. Otherwise each
##     argument takes own line, indented one level, with trailing comma, and `)` opens line at
##     call's indent. Outermost call crossing `LINE_MAX` splits first; each line it leaves is
##     read again.
##   Operator break: line no call split fits, whose hand gave no line breaks, breaks after
##     binary operator at its own depth (STYLE.md §5). Lowest precedence breaks first, as lexer
##     reads it (`precedence.nim`), and each line takes latest such operator that fits. Break
##     adds no parentheses: Nim refuses line opening with binary operator, and after one parser
##     reads next line on (`optPar`), so tree stays. `in`, `notin`, `is`, `isnot`, `of` and `as`
##     never break, nor operator glued on either side. Line holding comment, `;`, block keyword
##     after its head, or `:` before code other than type of binding, stays.
##   Continuation: each line of expression past its statement line takes `CONTINUATION_STEP`
##     spaces more than that line, every such line alike (STYLE.md §5). Statement line is line
##     expression opens on, or, for chain opening on line after `=` of binding or assignment,
##     line of that `=`, so chain takes step too, first line included; other value there keeps
##     one level. Expression whose first piece opens its own line, after opening bracket or
##     comma, takes no step: every line takes that line's indent (`isOwnLine`), so bracket
##     and argument read flat. Call and signature keep their one level. Fixer re-indents hand's
##     lines too; run of lines whose bracket opens past its line, or holding comment line or
##     token spanning lines, stays. Operator break follows same rule.
##   Trailing separator: list written one item to line ends its last item with separator: call,
##     parameters, array, seq, set, table, tuple of several items, constructor, import bracket.
##   Checks and fixers share one reading (`separators`, `signatureRewrites`, `callRewrites`,
##     `continuationShifts`, `trailingInserts`), so each rule is written once (Article II.1).
##
##   Left as written, check silent: parameter group without type or default, where `;` ends
##     group; signature or call holding comment, long string spanning lines, or block (keyword
##     opening block, `;` list, `do`, `:` ending line, `:` after call outside condition);
##     signature whose group spans lines; signature fitting one line where body after `=` does
##     not, since moving body and wrapping are two answers; outermost bracket crossing
##     `LINE_MAX` that is no call, and argument fitting no line that holds no such call, where
##     hand wrapped neither and no operator break fits; line break inside call that follows
##     operand and precedes operand or operator, whose joining could move reading.
##   Bracket spanning lines that no call opens, i.e. hand-shaped array, seq, set or tuple, is
##     never reflowed: it moves with its argument, line breaks kept, re-indented. Argument
##     wrapped by hand that fits no line keeps its line breaks in same way.
##   Parenthesis of one item takes no trailing comma, since `(a,)` is tuple and `(a)` grouping.
##
##   Cost: scanner, never parser (`tokens.nim`); construct it cannot read surely stays as written.
##   Cost: fixer never writes line width check reports; rewrite that would, stays to hand.
##     Trailing separator and continuation fixers are wideners (`reports.nim`): off held line
##     each writes rewrite that widens line past `LINE_MAX`, and call layout wraps line after.
##   Cost: line broken at operator that later fits stays broken, as hand's break does; call
##     layout joins only calls.
##   Hand-shaped call arguments, such as matrix rows, take one argument to line unless fenced
##     (`fixes.nim`, X.1): fenced line reads as comment, so call holding it stays as written.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils, unicode]
import ./[form, precedence, reports, tokens, views]


type
  Scan = object
    ## Define source as wrapping rules read it: lines, tokens, brackets, line each token ends.
    source: string
    lines: seq[string]
    starts: seq[int]  ## Byte offset each line opens at.
    tokens: seq[Token]
    partners: seq[int]  ## Partner of each bracket; `-1` for every other token.
    lasts: seq[int]  ## Zero-based line each token closes on.

  Item = object
    ## Define one item of bracketed list: token span, comments left out, separator after it.
    first: int  ## Index of first token.
    last: int  ## Index of last token; closing bracket where item ends in one.
    separator: int  ## Index of `,` or `;` after item; `-1` where none follows.

  Flat = object
    ## Define tokens rendered on one line, with rune column each token opens and closes at.
    text: string
    opens: seq[int]  ## Rune column of each token's start, by index from first token.
    closes: seq[int]  ## Rune column after each token's end, by same index.

  Rewrite = object  ## Define lines to replace, lines replacing them, and rule rewrite holds.
    first: int  ## Zero-based first line replaced.
    last: int  ## Zero-based last line replaced.
    lines: seq[string]
    rule: Rule

  Laid = object  ## Define lines layout writes, and rule they hold: call split or operator break.
    lines: seq[string]
    rule: Rule

  Insert = object  ## Define separator to insert after list's last item.
    line: int  ## Zero-based line of item's last token.
    at: int  ## Byte offset after item's last token.
    separator: string

  Shift = object  ## Define continuation line to re-indent, and spaces it takes past its base.
    rewrite: Rewrite
    step: int  ## `CONTINUATION_STEP` past statement line, or none past line first piece opens.


const
  BLOCK_KEYWORDS = [
    "block", "case", "converter", "do", "for", "func", "if", "iterator", "macro", "method",
    "proc", "template", "try", "when", "while",
  ]
    ## Keywords opening block; call or list holding one is left as written.
  CONDITION_KEYWORDS = ["case", "elif", "except", "for", "if", "of", "when", "while"]
    ## Keywords whose `:` ends line after call they hold, so `:` opens no block argument.
  CONTINUING_KEYWORDS = [
    "and", "div", "in", "is", "isnot", "mod", "notin", "of", "or", "shl", "shr", "xor",
  ]
    ## Keyword operators line may end on, continuing expression on next line.
  TYPE_KEYWORDS = ["static", "tuple"]  ## Keywords whose `[` opens type, never constructor.
  INDENT_STEP = 2  ## Spaces one level of wrapping indents (Article X.1).
  CONTINUATION_STEP = 4
    ## Spaces line continuing expression after operator takes beyond line opening it (STYLE.md
    ##   §5), so continuation reads apart from block body one level in; none where first piece
    ##   opens its own line, since bracket or comma before it already sets it apart.
  UNBROKEN_KEYWORDS = ["as", "in", "is", "isnot", "notin", "of"]
    ## Keyword operators no break follows: membership, type test and conversion read as one.
  NAMING_KEYWORDS = ["const", "let", "var"]  ## Keywords whose name's `:` types binding.
  IGNORED_OPERATORS = [".", ":", "::", "="]
    ## Operator tokens ending line that continue no expression: field, type, assignment.
  PASSES_MAX = 16
    ## Passes call fixer takes at most; one rewrite can let call sharing its line be read.


func scan(source: string): Scan =
  ## Read source once for every wrapping rule.
  result = Scan(
    source: source,
    lines: source.split('\n'),
    starts: source.lineStarts,
    tokens: source.tokens,
  )
  result.partners = result.tokens.partners
  for t in result.tokens: result.lasts.add t.lastLine(source)


func spelling(s: Scan, k: int): string =
  ## Read text of token `k`.
  s.tokens[k].spelling(s.source)


func offset(s: Scan, k: int): int =
  ## Count bytes before token `k` on its line.
  s.tokens[k].first - s.starts[s.tokens[k].line]


func isLineFirst(s: Scan, k: int): bool =
  ## Decide whether token `k` opens its line, no token spanning lines ending there.
  k == 0 or s.lasts[k - 1] < s.tokens[k].line


func isLineLast(s: Scan, k: int): bool =
  ## Decide whether token `k` ends its line, comment after it aside.
  k == s.tokens.high or s.tokens[k + 1].line > s.lasts[k] or
    (s.tokens[k + 1].kind == TokenKind.Comment and s.isLineLast(k + 1))


func isMultiline(s: Scan, k: int): bool =
  ## Decide whether bracket `k` opens closes on later line.
  s.partners[k] > k and s.tokens[s.partners[k]].line > s.tokens[k].line


func items(s: Scan, o: int): seq[Item] =
  ## Read items of list bracket `o` opens, split at separators outside nested brackets.
  var
    k = o + 1
    item = Item(first: -1, last: -1, separator: -1)
  while k < s.partners[o]:
    case s.tokens[k].kind
    of TokenKind.Comma, TokenKind.Semicolon:
      item.separator = k
      if item.first >= 0: result.add item
      item = Item(first: -1, last: -1, separator: -1)
    of TokenKind.Comment: discard
    else:
      if item.first < 0: item.first = k
      if s.tokens[k].kind == TokenKind.Open and s.partners[k] > k: k = s.partners[k]
      item.last = k
    inc k
  if item.first >= 0: result.add item


func isHolding(s: Scan, item: Item, spellings: openArray[string]): bool =
  ## Decide whether item holds token of spellings outside its nested brackets.
  var k = item.first
  while k <= item.last:
    if s.spelling(k) in spellings: return true
    if s.tokens[k].kind == TokenKind.Open and s.partners[k] > k: k = s.partners[k]
    inc k


func applied(path, source: string; rewrites: openArray[Rewrite]): Fix =
  ## Replace lines of each rewrite, last first; each new line traces to line it replaced.
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for rewrite in rewrites.reversed:
    let
      span = rewrite.last - rewrite.first
      traced = toSeq(0 ..< rewrite.lines.len).mapIt(origin[rewrite.first + min(it, span)])
    lines = lines[0 ..< rewrite.first] & rewrite.lines & lines[rewrite.last + 1 .. ^1]
    origin = origin[0 ..< rewrite.first] & traced & origin[rewrite.last + 1 .. ^1]
  result.source = lines.join("\n")
  for rewrite in rewrites: result.fixed.add initReport(path, rewrite.first + 1, rewrite.rule)
  if origin != toSeq(1 .. origin.len): result.origin = origin



#[ Parameter Separators ]#

func groupsOf(s: Scan, items: openArray[Item]): seq[seq[Item]] =
  ## Group parameters sharing one type: names up to one typed or defaulted, or up to `;`.
  ##   Empty where any group lacks type and default, which no rule here reads.
  var group: seq[Item]
  for item in items:
    group.add item
    let is_typed = s.isHolding(item, [":", "="])
    if is_typed or (item.separator >= 0 and s.tokens[item.separator].kind == TokenKind.Semicolon):
      if not is_typed: return @[]
      result.add group
      group = @[]
  if group.len > 0: return @[]


func separatorOf(groups: openArray[seq[Item]]): string =
  ## Read separator groups take: `;` where one group holds several names, `,` otherwise.
  if groups.anyIt(it.len > 1): ";" else: ","


func separators(s: Scan): seq[int] =
  ## Find each separator between parameter groups, trailing one included, of wrong kind.
  for o in 0 ..< s.tokens.len:
    if s.tokens.signatureOf(s.partners, o, s.source) < 0 or s.partners[o] < o: continue
    let groups = s.groupsOf(s.items(o))
    if groups.len == 0: continue
    let wanted = groups.separatorOf
    for group in groups:
      let separator = group[^1].separator
      if separator >= 0 and s.spelling(separator) != wanted: result.add separator


func tupleSeparators(s: Scan): seq[int] =
  ## Find each `;` between fields of tuple type, which takes `,` (STYLE.md §5).
  for o in 1 ..< s.tokens.len:
    if s.spelling(o) != "[" or s.spelling(o - 1) != "tuple" or s.partners[o] < o: continue
    for item in s.items(o):
      if item.separator >= 0 and s.tokens[item.separator].kind == TokenKind.Semicolon:
        result.add item.separator


func checkSeparators*(path, source: string): seq[Report] =
  ## Report separator between parameter groups breaking STYLE.md §5, and `;` of tuple type.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  let s = source.scan
  for k in s.separators:
    result.add initReport(
      path,
      s.tokens[k].line + 1,
      Rule.ParameterSeparators,
      "Parameters take `;` between groups where one group shares its type, and `,` otherwise " &
        "(STYLE.md §5); got `" & s.spelling(k) & "`.",
    )
  for k in s.tupleSeparators:
    result.add initReport(
      path,
      s.tokens[k].line + 1,
      Rule.TupleSeparators,
      "Tuple type takes `,` between fields (STYLE.md §5); got `;`.",
    )


func fixSeparators*(path, source: string): Fix =
  ## Rewrite each separator check reports; `,` and `;` share width, so no line moves.
  let s = source.scan
  result.source = source
  for k in s.separators:
    result.source[s.tokens[k].first] = if s.spelling(k) == ",": ';' else: ','
    result.fixed.add initReport(path, s.tokens[k].line + 1, Rule.ParameterSeparators)
  for k in s.tupleSeparators:
    result.source[s.tokens[k].first] = ','
    result.fixed.add initReport(path, s.tokens[k].line + 1, Rule.TupleSeparators)



#[ Signature Wrapping ]#

func signatureRewrites(s: Scan): seq[Rewrite] =
  ## Lay out each routine signature as X.3 wraps it, one rewrite to each it changes.
  for o in 0 ..< s.tokens.len:
    let keyword = s.tokens.signatureOf(s.partners, o, s.source)
    if keyword < 0 or keyword == o - 1 or not s.isLineFirst(keyword): continue
    let c = s.partners[o]
    if c < o or s.tokens[keyword].line != s.tokens[o].line: continue
    let (first_line, last_line) = (s.tokens[keyword].line, s.tokens[c].line)

    # Read closing line through `=` and body after it; leave what spans lines or holds comment.
    var
      k = keyword
      is_unread = false
      equals = -1
    while k < s.tokens.len and s.tokens[k].line <= last_line:
      let t = s.tokens[k]
      if t.kind == TokenKind.Comment or s.lasts[k] > t.line: is_unread = true
      if k > c and t.kind == TokenKind.Open:
        if s.partners[k] < 0 or s.tokens[s.partners[k]].line != last_line: is_unread = true
        else: k = s.partners[k]
      elif k > c and equals < 0 and s.spelling(k) == "=": equals = k
      inc k
    let
      items = s.items(o)
      groups = s.groupsOf(items)
    if is_unread or groups.len == 0: continue
    if groups.anyIt(s.tokens[it[0].first].line != s.lasts[it[^1].last]): continue

    # Build each layout from head, groups and tail as written.
    let
      line = s.lines[first_line]
      closing = s.lines[last_line]
      head = line[0 ..< s.offset(o) + 1]
      tail = closing[s.offset(c) .. ^1]
      tail_signature = if equals < 0: tail else: closing[s.offset(c) .. s.offset(equals)]
      texts = groups.mapIt(s.source[s.tokens[it[0].first].first ..< s.tokens[it[^1].last].after])
      separator = groups.separatorOf
      joined = texts.join(separator & " ")
      margin = ' '.repeat(line.indentOf)
      inner = ' '.repeat(line.indentOf + INDENT_STEP)
      one = head & joined & tail
      parameters_line = @[head, inner & joined, margin & tail]
      group_lines = @[head] & texts.mapIt(inner & it & separator) & @[margin & tail]
    var canonical: seq[string]
    if not one.isWide: canonical = @[one]
    elif tail_signature != tail and not (head & joined & tail_signature).isWide: continue
    elif not parameters_line.anyIt(it.isWide):
      # One name on its line is list written one item to line, which takes separator (X.3).
      canonical = if items.len == 1: group_lines else: parameters_line
    elif not group_lines.anyIt(it.isWide): canonical = group_lines
    else: continue
    if canonical != s.lines[first_line .. last_line]:
      result.add Rewrite(
        first: first_line,
        last: last_line,
        lines: canonical,
        rule: Rule.SignatureWrapping,
      )


func checkSignatures*(path, source: string): seq[Report] =
  ## Report signature laid out against X.3 and STYLE.md §5.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for rewrite in source.scan.signatureRewrites:
    result.add initReport(
      path,
      rewrite.first + 1,
      Rule.SignatureWrapping,
      "Signature stays on one line where it fits, else wraps its parameters onto one line of " &
        "their own, else one group to line (X.3, STYLE.md §5); got `" &
        $(rewrite.last - rewrite.first + 1) & "` lines.",
    )


func fixSignatures*(path, source: string): Fix =
  ## Rewrite each signature check reports into its layout.
  applied(path, source, source.scan.signatureRewrites)



#[ Call Wrapping ]#

func isEligibleCall(s: Scan, o: int): bool =
  ## Decide whether `(` at `o` opens call wrapping reads: no comment, long string spanning lines
  ##   or block among arguments, and no block argument after it.
  if not s.tokens.isCallOpen(s.partners, o, s.source) or s.partners[o] < o: return false
  let c = s.partners[o]
  for k in o + 1 ..< c:
    let t = s.tokens[k]
    if t.kind in {TokenKind.Comment, TokenKind.Semicolon} or s.lasts[k] > t.line: return false
    if t.kind == TokenKind.Word and s.spelling(k) in BLOCK_KEYWORDS: return false
    if s.spelling(k) == ":" and s.isLineLast(k): return false
  if c == s.tokens.high or s.tokens[c + 1].line > s.lasts[c]: return true
  let after = s.spelling(c + 1)
  if after == "do": return false
  if after != ":" or not s.isLineLast(c + 1): return true

  # `:` ends condition of keyword opening line, or opens block argument of call.
  var first = o
  while not s.isLineFirst(first): dec first
  s.spelling(first) in CONDITION_KEYWORDS


func isFlattenable(s: Scan; a, b: int): bool =
  ## Decide whether tokens `a` to `b` may join on one line: every bracket spanning lines opens
  ##   call wrapping reads, and each line break follows bracket, comma or operator, or precedes
  ##   closing bracket, so joining moves no reading.
  for k in a .. b:
    let t = s.tokens[k]
    if t.kind == TokenKind.Comment or s.lasts[k] > t.line: return false
    if t.kind == TokenKind.Open and s.isMultiline(k) and not s.isEligibleCall(k): return false
    if k == a or t.line == s.lasts[k - 1]: continue
    let
      previous = s.tokens[k - 1]
      is_continued = previous.kind == TokenKind.Operator or
        (previous.kind == TokenKind.Word and s.spelling(k - 1) in CONTINUING_KEYWORDS)
    if t.kind == TokenKind.Close or previous.kind in {TokenKind.Open, TokenKind.Comma}: continue
    if not is_continued or t.kind == TokenKind.Operator: return false
  true


func flatten(s: Scan; a, b: int): Flat =
  ## Render tokens `a` to `b` on one line: gap inside line kept; line break dropped after
  ##   opening bracket and before closing one, space elsewhere; trailing comma dropped before
  ##   closing bracket on later line, which in range `isFlattenable` passes closes call.
  var
    runes = 0
    previous = -1
  for k in a .. b:
    let
      t = s.tokens[k]
      is_trailing = t.kind == TokenKind.Comma and k < b and
        s.tokens[k + 1].kind == TokenKind.Close and s.tokens[k + 1].line > t.line
    if is_trailing:
      result.opens.add runes
      result.closes.add runes
      continue
    if previous >= 0:
      let gap =
        if t.line == s.lasts[previous]: s.source[s.tokens[previous].after ..< t.first]
        elif s.tokens[previous].kind == TokenKind.Open or t.kind == TokenKind.Close: ""
        else: " "
      result.text.add gap
      runes += gap.runeLen
    result.opens.add runes
    result.text.add s.spelling(k)
    runes += s.spelling(k).runeLen
    result.closes.add runes
    previous = k


func kept(s: Scan; lead: string; a, b: int; trail: string): Option[seq[string]] =
  ## Keep line breaks hand gave tokens `a` to `b`, re-indented as their first line moves.
  ##   `none` where they span one line, or hold call spanning lines, which rule lays out.
  let (first_line, last_line) = (s.tokens[a].line, s.lasts[b])
  if first_line == last_line: return none(seq[string])
  for k in a .. b:
    let t = s.tokens[k]
    if t.kind == TokenKind.Comment or (t.kind == TokenKind.Text and s.lasts[k] > t.line):
      return none(seq[string])
    if t.kind == TokenKind.Open and s.isMultiline(k) and
        s.tokens.isCallOpen(s.partners, k, s.source):
      return none(seq[string])
    if k > a and t.line > s.lasts[k - 1] and t.kind == TokenKind.Operator:
      return none(seq[string])
  let shift = lead.len - s.lines[first_line].indentOf
  var shaped = @[lead & s.lines[first_line][s.offset(a) .. ^1]]
  for line in first_line + 1 .. last_line:
    let
      text = s.lines[line]
      stop = if line == last_line: s.tokens[b].after - s.starts[line] else: text.len
      indent = text.indentOf + shift
    if indent < 0: return none(seq[string])
    shaped.add ' '.repeat(indent) & text[text.indentOf ..< stop]
  shaped[^1].add trail
  some(shaped)


func isClosingRun(s: Scan; a, b: int): bool =
  ## Decide whether tokens `a` to `b` are closing brackets, separators and `:` alone.
  toSeq(a .. b).allIt(
    s.tokens[it].kind in {TokenKind.Close, TokenKind.Comma, TokenKind.Semicolon} or
      s.spelling(it) == ":",
  )


func isWholeCall(s: Scan; a, b: int): bool =
  ## Decide whether tokens `a` to `b` are one call with its callee chain, named where argument
  ##   or field names it (`name = f(…)`, `name: f(…)`): no other operator outside brackets but
  ##   `.`. Argument of other shape has no one split.
  var k = a
  while k <= b:
    let
      t = s.tokens[k]
      is_naming = k == a + 1 and s.spelling(k) in ["=", ":"] and s.tokens[a].kind == TokenKind.Word
    if t.kind == TokenKind.Operator and s.spelling(k) != "." and not is_naming: return false
    if t.kind == TokenKind.Word and s.spelling(k) in CONTINUING_KEYWORDS: return false
    if t.kind == TokenKind.Open and s.partners[k] > k: k = s.partners[k]
    inc k
  true


func isContinuing(s: Scan, k: int): bool =
  ## Decide whether token `k`, ending its line, is binary operator, so next line continues it.
  let text = s.spelling(k)
  if k == 0 or not s.tokens.isOperandEnd(k - 1, s.source): return false
  if s.tokens[k].kind == TokenKind.Word: text in CONTINUING_KEYWORDS
  else: s.tokens[k].kind == TokenKind.Operator and text notin IGNORED_OPERATORS


func continued(s: Scan, k: int): int =
  ## Read index of operator line-first token `k` continues, on line right above it, comment
  ##   after operator aside; `-1` where none, where `k` is comment, or where comment line
  ##   stands between.
  if k == 0 or not s.isLineFirst(k) or s.tokens[k].kind == TokenKind.Comment: return -1
  var j = k - 1
  if s.tokens[j].kind == TokenKind.Comment and j > 0 and s.tokens[j].line == s.lasts[j - 1] and
      s.lasts[j] == s.tokens[j].line:
    dec j
  if s.lasts[j] + 1 != s.tokens[k].line or not s.isContinuing(j): -1 else: j


func bindingOpened(s: Scan, k: int): int =
  ## Read line of statement whose `=` ending its line opens value at line-first token `k`:
  ##   binding of `const`, `let` or `var`, or assignment; `-1` where line before ends otherwise,
  ##   statement stands inside bracket, as named argument does, `=` stands inside one, or keyword
  ##   other than section's stands before it, as head of routine, lambda or `type` does.
  if k == 0 or not s.isLineFirst(k) or s.tokens[k].kind == TokenKind.Comment: return -1
  var j = k - 1
  if s.tokens[j].kind == TokenKind.Comment and j > 0 and s.tokens[j].line == s.lasts[j - 1] and
      s.lasts[j] == s.tokens[j].line:
    dec j
  if s.spelling(j) != "=" or s.lasts[j] + 1 != s.tokens[k].line: return -1

  # Read statement through `=`: no bracket open around it or left open, no keyword but leading
  #   section's.
  var
    first = j
    depth = 0
  while not s.isLineFirst(first): dec first
  for m in 0 ..< first:
    if s.tokens[m].kind == TokenKind.Open: inc depth
    elif s.tokens[m].kind == TokenKind.Close: depth = max(depth - 1, 0)
  if depth != 0: return -1
  for m in first ..< j:
    let t = s.tokens[m]
    if t.kind == TokenKind.Open: inc depth
    elif t.kind == TokenKind.Close: dec depth
    if t.isKeyword(s.source) and not (m == first and s.spelling(m) in NAMING_KEYWORDS):
      return -1
  if depth != 0: return -1

  # Entry of `type` section declares type, never value.
  let
    line = s.tokens[first].line
    indent = s.lines[line].indentOf
  var parent = first - 1
  while parent >= 0 and not (s.isLineFirst(parent) and
      s.tokens[parent].kind != TokenKind.Comment and
      s.lines[s.tokens[parent].line].indentOf < indent):
    dec parent
  if parent >= 0 and s.spelling(parent) == "type": -1 else: line


func isOwnLine(s: Scan; a, b: int): bool =
  ## Decide whether expression whose first line holds tokens `a` to `b` opens there with its
  ##   first piece: plain opening bracket or comma before `a`, comments aside, and among tokens
  ##   at their depth no delimiter (`=`, `:`, separator, keyword) and no command head, i.e. two
  ##   operands apart by space with no operator between.
  var j = a - 1
  while j >= 0 and s.tokens[j].kind == TokenKind.Comment: dec j
  if j < 0 or not (s.tokens[j].kind == TokenKind.Comma or s.spelling(j) in ["(", "[", "{"]):
    return false
  let elements = elementsOf(s.tokens, s.partners, a, b, s.source)
  for m, e in elements:
    if e.kind == ElementKind.Delimiter: return false
    if m == 0: continue
    let
      before = elements[m - 1]
      is_spaced = s.tokens[before.last].after < s.tokens[e.first].first
    if before.kind == ElementKind.Operand and is_spaced and
        e.kind in {ElementKind.Operand, ElementKind.Prefix}:
      return false
  true


func broken(s: Scan; lead: string; a, b: int; trail: string; indent: int): Option[seq[string]] =
  ## Break tokens `a` to `b`, which stand on one line, after binary operators of lowest
  ##   precedence at their depth, each line taking latest one that fits, between lead and
  ##   trail; `none` where line holds what operator break leaves, or piece fits no line.
  ##   Continuation lines take `CONTINUATION_STEP` beyond indent, or indent itself where line
  ##     continues expression already, opens value after `=`, or opens with first piece after
  ##     bracket or comma (`isOwnLine`), so every line of one expression past its statement
  ##     line aligns, as `continuationShifts` reads it.
  if s.tokens[a].line != s.lasts[b]: return none(seq[string])
  for k in a .. b:
    let t = s.tokens[k]
    if t.kind in {TokenKind.Comment, TokenKind.Semicolon}: return none(seq[string])
    if k > a and t.kind == TokenKind.Word and s.spelling(k) in BLOCK_KEYWORDS:
      return none(seq[string])

  # Read operators of one depth; `:` before code passes only as type of name it follows.
  let elements = elementsOf(s.tokens, s.partners, a, b, s.source)
  var breaks: seq[Element]
  for e in elements:
    let k = e.first
    if s.spelling(k) == ":" and k < b:
      let is_typing = s.tokens[k - 1].kind == TokenKind.Word and
          not s.tokens[k - 1].isKeyword(s.source) and
          (k - 1 == a or (k - 2 == a and s.spelling(a) in NAMING_KEYWORDS))
      if not is_typing: return none(seq[string])
    if e.kind != ElementKind.Binary or e.last >= b or s.spelling(k) in UNBROKEN_KEYWORDS: continue
    if s.tokens[k - 1].after == s.tokens[k].first or s.tokens[k].after == s.tokens[k + 1].first:
      continue
    breaks.add e
  if breaks.len == 0: return none(seq[string])
  let
    lowest = breaks.mapIt(it.precedence).min
    stops = breaks.filterIt(it.precedence == lowest).mapIt(it.first)
    is_continuing = s.continued(a) >= 0 or s.bindingOpened(a) >= 0 or
      (lead.strip.len == 0 and s.isOwnLine(a, b))
    margin = ' '.repeat(if is_continuing: indent else: indent + CONTINUATION_STEP)

  # Fill each line up to latest operator that fits; rest goes on next line.
  var
    lines: seq[string]
    start = a
    prefix = lead
  while true:
    let whole = prefix & s.source[s.tokens[start].first ..< s.tokens[b].after] & trail
    if not whole.isWide:
      lines.add whole
      return some(lines)
    var stop = -1
    for k in stops:
      if k < start: continue
      if (prefix & s.source[s.tokens[start].first ..< s.tokens[k].after]).isWide: break
      stop = k
    if stop < 0: return none(seq[string])
    lines.add prefix & s.source[s.tokens[start].first ..< s.tokens[stop].after]
    (start, prefix) = (stop + 1, margin)


func fallback(s: Scan; lead: string; a, b: int; trail: string; indent: int): Option[Laid] =
  ## Keep line breaks hand gave tokens `a` to `b`, else break their one line after operator.
  let hand = s.kept(lead, a, b, trail)
  if hand.isSome: return some(Laid(lines: hand.get, rule: Rule.CallWrapping))
  let operator = s.broken(lead, a, b, trail, indent)
  if operator.isNone: none(Laid)
  else: some(Laid(lines: operator.get, rule: Rule.OperatorWrapping))


func isTrailed(s: Scan, o: int): bool =
  ## Decide whether call `(` at `o` spans lines with comma after its last argument, on line
  ##   before its `)`: mark of split hand wants (X.3), so call keeps one argument to line.
  if not s.isMultiline(o) or not s.isEligibleCall(o): return false
  let items = s.items(o)
  items.len > 0 and items[^1].separator >= 0 and
    s.tokens[s.partners[o]].line > s.tokens[items[^1].separator].line


func isHug(s: Scan, o: int): bool =
  ## Decide whether call `(` at `o` holds one argument, call spanning lines that hand hugs: its
  ##   head glued after `(`, its `)` glued before `)` of `o` on one line, as `f(g(` … `))`.
  let items = s.items(o)
  if items.len != 1 or items[0].separator >= 0: return false
  let
    (first, last) = (items[0].first, items[0].last)
    inner = s.partners[last]
  s.tokens[first].first == s.tokens[o].after and
    s.tokens[last].after == s.tokens[s.partners[o]].first and inner > first and
    s.isMultiline(inner) and s.isEligibleCall(inner) and s.isWholeCall(first, last)


func handLines(s: Scan; lead: string; a, b: int; trail: string): Option[seq[string]] =
  ## Keep line breaks hand gave call of tokens `a` to `b`, each line moved as indent of its first
  ##   moves; `none` where they span one line, hold comment or token spanning lines, hold bracket
  ##   spanning lines other than one call, or where line would cross `LINE_MAX`.
  let (first_line, last_line) = (s.tokens[a].line, s.lasts[b])
  if first_line == last_line: return none(seq[string])
  var spanning: seq[int]
  for k in a..b:
    let t = s.tokens[k]
    if t.kind == TokenKind.Comment or s.lasts[k] > t.line: return none(seq[string])
    if t.kind == TokenKind.Open and s.isMultiline(k): spanning.add k
  if spanning.len != 1 or not s.isEligibleCall(spanning[0]): return none(seq[string])
  let shift = lead.indentOf - s.lines[first_line].indentOf
  var shaped = @[lead & s.lines[first_line][s.offset(a)..^1]]
  for line in first_line + 1 .. last_line:
    let
      text = s.lines[line]
      stop = if line == last_line: s.tokens[b].after - s.starts[line] else: text.len
      indent = text.indentOf + shift
    if indent < 0: return none(seq[string])
    shaped.add ' '.repeat(indent) & text[text.indentOf ..< stop]
  shaped[^1].add trail
  if shaped.anyIt(it.isWide): none(seq[string]) else: some(shaped)


func layout(
  s: Scan; lead: string; a, b: int; trail: string; indent: int; is_argument: bool
): Option[Laid] =
  ## Lay out tokens `a` to `b` between lead and trail as X.3 wraps calls; `none` where rule
  ##   leaves them as written.
  ##   One line where they fit; else line breaks hand gave call stay, where each line fits and
  ##     only that call spans lines (`handLines`); else outermost call crossing `LINE_MAX` splits,
  ##     one argument to line, each laid out again; else wrapping hand gave stays, re-indented;
  ##     else line breaks after operator, which split that fits no line falls back on too.
  ##   Call spanning lines with comma after its last argument is never joined (`isTrailed`):
  ##     outermost call spanning lines splits instead, and call hand hugs around it keeps its hug
  ##     (`isHug`), so `x.add(Y(` … `))` keeps `))`.
  ##   Argument splits its crossing call only where that call is whole argument; expression
  ##     holding call has no one split, so its hand wrapping stays, or it breaks after
  ##     operator, or call is left.
  ##   Bracket spanning lines that no call opens is never joined: outermost call spanning lines
  ##     splits around it instead.
  var
    target = -1
    is_trailed = false
  for k in a..b:
    if s.tokens[k].kind == TokenKind.Open and s.isTrailed(k): is_trailed = true
  if s.isFlattenable(a, b) and not is_trailed:
    let
      flat = s.flatten(a, b)
      one = lead & flat.text & trail
      start = lead.runeLen
    if not one.isWide: return some(Laid(lines: @[one], rule: Rule.CallWrapping))
    let hand = s.handLines(lead, a, b, trail)
    if hand.isSome: return some(Laid(lines: hand.get, rule: Rule.CallWrapping))

    # Find outermost bracket crossing `LINE_MAX`, else last one before it ending line.
    var
      k = a
      last_open = -1
    while k <= b:
      let p = s.partners[k]
      if s.tokens[k].kind == TokenKind.Open and p > k and p <= b:
        if start + flat.opens[k - a] < LINE_MAX:
          last_open = k
          if start + flat.closes[p - a] > LINE_MAX:
            target = k
            break
        k = p
      inc k
    if target < 0 and last_open >= 0 and
        (s.partners[last_open] == b or s.isClosingRun(s.partners[last_open] + 1, b)):
      target = last_open
  else:
    var k = a
    while k <= b:
      if s.tokens[k].kind == TokenKind.Open and s.partners[k] > k and s.partners[k] <= b:
        if s.isMultiline(k):
          target = k
          break
        k = s.partners[k]
      inc k
  if target < 0 or not s.isEligibleCall(target) or not s.isFlattenable(a, target):
    return s.fallback(lead, a, b, trail, indent)
  if is_argument and not s.isWholeCall(a, b): return s.fallback(lead, a, b, trail, indent)

  # Split call: head through `(`, one argument to line, `)` opening closing line.
  block split:
    let
      c = s.partners[target]
      arguments = s.items(target)
      closer = ' '.repeat(indent) & ")"
    if arguments.len == 0: break split
    if c == b and s.isHug(target):
      let hug = s.layout(
        lead & s.flatten(a, target).text,
        arguments[0].first,
        arguments[0].last,
        ")" & trail,
        indent,
        is_argument = true,
      )
      if hug.isSome: return hug
    var lines = @[lead & s.flatten(a, target).text]
    for item in arguments:
      let argument = s.layout(
        ' '.repeat(indent + INDENT_STEP),
        item.first,
        item.last,
        ",",
        indent + INDENT_STEP,
        is_argument = true,
      )
      if argument.isNone: break split
      lines.add argument.get.lines
    if c == b: lines.add closer & trail
    else:
      if s.tokens[c + 1].line != s.tokens[c].line: break split
      let
        gap = s.source[s.tokens[c].after ..< s.tokens[c + 1].first]
        rest = s.layout(closer & gap, c + 1, b, trail, indent, is_argument)
      if rest.isNone: break split
      lines.add rest.get.lines
    if lines.anyIt(it.isWide): break split
    return some(Laid(lines: lines, rule: Rule.CallWrapping))

  # Break at operator where split fits no line.
  let operator = s.broken(lead, a, b, trail, indent)
  if operator.isSome: some(Laid(lines: operator.get, rule: Rule.OperatorWrapping))
  else: none(Laid)


func callRewrites(s: Scan): seq[Rewrite] =
  ## Lay out each region calls span: line call opens on to line it closes on, or one wide line.
  ##   Region rewritten is passed whole; region kept or left is read again from its next line,
  ##   so call inside hand-shaped list or inside call left as written is still read.
  var
    firsts = newSeqWith(s.lines.len, -1)
    line = 0
  for k in 0 ..< s.tokens.len:
    if s.isLineFirst(k) and firsts[s.tokens[k].line] < 0: firsts[s.tokens[k].line] = k
  while line < s.lines.len:
    let first = firsts[line]
    if first < 0:
      inc line
      continue

    # Region reaches last line every bracket and token opened inside it reaches.
    var
      last_line = line
      k = first
    while k < s.tokens.len and s.tokens[k].line <= last_line:
      last_line = max(last_line, s.lasts[k])
      if s.tokens[k].kind == TokenKind.Open and s.partners[k] > k:
        last_line = max(last_line, s.tokens[s.partners[k]].line)
      inc k
    if last_line == line and not s.lines[line].isWide:
      inc line
      continue
    let
      indent = s.lines[line].indentOf
      laid = s.layout(' '.repeat(indent), first, k - 1, "", indent, is_argument = false)
    if laid.isSome and laid.get.lines != s.lines[line .. last_line]:
      result.add Rewrite(first: line, last: last_line, lines: laid.get.lines, rule: laid.get.rule)
      line = last_line + 1
    else: inc line


func checkCalls*(path, source: string): seq[Report] =
  ## Report call laid out against X.3 and STYLE.md §5, and line no call split fits that breaks
  ##   after operator.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  let s = source.scan
  for rewrite in s.callRewrites:
    let message =
      if rewrite.rule == Rule.OperatorWrapping:
        "Line fitting nowhere breaks after its operator of lowest precedence (X.1, STYLE.md " &
            "§5); got `" & $s.lines[rewrite.first].runeLen & "` runes."
      else:
        "Call stays on its line where it fits, else takes one argument to line with trailing " &
            "comma (X.3, STYLE.md §5); got `" & $(rewrite.last - rewrite.first + 1) & "` lines."
    result.add initReport(path, rewrite.first + 1, rewrite.rule, message)


func fixCalls*(path, source: string): Fix =
  ## Rewrite each call check reports, and each operator break, pass after pass until none is
  ##   left.
  result.source = source
  for pass in 1 .. PASSES_MAX:
    let rewrites = result.source.scan.callRewrites
    if rewrites.len == 0: break
    result = result.chain(applied(path, result.source, rewrites))



#[ Continuation Indent ]#

func isOpening(s: Scan, k: int): bool =
  ## Decide whether line-first token `k` opens expression: code token before it, comments
  ##   aside, ends no line on operator.
  var j = k - 1
  while j >= 0 and s.tokens[j].kind == TokenKind.Comment: dec j
  j < 0 or s.lasts[j] == s.tokens[k].line or not s.isContinuing(j)


func continuationShifts(s: Scan, held: Held): seq[Shift] =
  ## Re-indent each line of expression past its statement line to `CONTINUATION_STEP` beyond
  ##   that line, all alike, one rewrite to each line; expression holding line whose indent
  ##   would widen held line is left whole, so lines of one expression never part.
  ##   Expression whose first piece opens statement line after bracket or comma (`isOwnLine`)
  ##     takes no step: every line takes indent of that line.
  ##   Statement line is line expression opens on, or line whose `=` ends it where value opens
  ##     on next line (`bindingOpened`) and goes on after operator: such chain takes one indent,
  ##     first line included. Value of other shape there, such as split call, `if` expression or
  ##     value of one line, keeps one level under its statement, and stays as written.
  ##   Run of continuations is read whole, where no token spans lines, each line but last ends
  ##     at depth first line opens at and closes no bracket opened before it, and last leaves
  ##     none open. Value is read where no token spans its lines and no comment line stands in it.
  var
    firsts = newSeqWith(s.lines.len, -1)  # Line-first token of each line.
    opened: seq[int]  # Brackets open after each token.
    depth = 0
  for k, t in s.tokens:
    if s.isLineFirst(k) and firsts[t.line] < 0: firsts[t.line] = k
    if t.kind == TokenKind.Open: inc depth
    elif t.kind == TokenKind.Close: depth = max(depth - 1, 0)
    opened.add depth
  for k, t in s.tokens:
    if firsts[t.line] != k or t.kind == TokenKind.Comment or not s.isOpening(k): continue

    # Walk lines while each next one continues; read run whole.
    var run = @[k]
    while t.line + run.len < s.lines.len:
      let next = firsts[t.line + run.len]
      if next < 0 or s.continued(next) < 0: break
      run.add next
    if run.len == 1: continue
    let
      statement = s.bindingOpened(k)
      floor = if k == 0: 0 else: opened[k - 1]
    var after = run[^1]
    while after < s.tokens.len and s.tokens[after].line == s.tokens[run[^1]].line: inc after
    var is_read = opened[after - 1] <= floor
    for j in k ..< after:
      if s.lasts[j] > s.tokens[j].line: is_read = false
      if j < run[^1] and opened[j] < floor: is_read = false
    for first in run[1 .. ^1]:
      if opened[first - 1] != floor: is_read = false
    if not is_read: continue

    # Plan indent of each line of run: past statement line, at line first piece opens, or past
    #   line `=` ends.
    var
      planned: seq[(int, int)]  # Line and its indent.
      step = CONTINUATION_STEP
    if statement < 0:
      if s.isOwnLine(k, s.continued(run[1])): step = 0
      let wanted = s.lines[t.line].indentOf + step
      for first in run[1 .. ^1]: planned.add (s.tokens[first].line, wanted)
    else:
      # Value runs down while code opens line at its own indent or deeper; chain must be all of it.
      let
        wanted = s.lines[statement].indentOf + CONTINUATION_STEP
        base = s.lines[t.line].indentOf
      var
        last = t.line
        line = t.line + 1
      while line < s.lines.len:
        let first = firsts[line]
        if first < 0:
          # Blank line passes; line inside token spanning lines leaves value unread.
          if s.lines[line].strip.len > 0:
            is_read = false
            break
          inc line
          continue
        if s.lines[line].indentOf < base: break
        if s.tokens[first].kind == TokenKind.Comment:
          # Comment ends value, unless code at its depth follows.
          var next = line
          while next < s.lines.len and
              (firsts[next] < 0 or s.tokens[firsts[next]].kind == TokenKind.Comment):
            inc next
          if next < s.lines.len and s.lines[next].indentOf >= base: is_read = false
          break
        last = line
        inc line
      var stop = k
      while stop < s.tokens.len and s.tokens[stop].line <= last:
        if s.lasts[stop] > s.tokens[stop].line: is_read = false
        inc stop
      if s.tokens[run[^1]].line != last: is_read = false
      if not is_read: continue
      for first in run: planned.add (s.tokens[first].line, wanted)

    # Set each line to its indent, or none where held line would widen.
    var shifts: seq[Shift]
    for (line, indent) in planned:
      let
        text = s.lines[line]
        shaped = ' '.repeat(indent) & text[text.indentOf .. ^1]
        rewrite = Rewrite(first: line, last: line, lines: @[shaped], rule: Rule.ContinuationIndent)
      if shaped == text: continue
      if held.isHeld(line + 1) and shaped.isWide and not text.isWide:
        shifts.setLen(0)
        break
      shifts.add Shift(rewrite: rewrite, step: step)
    result.add shifts


func checkContinuations*(path, source: string): seq[Report] =
  ## Report line of expression past its statement line at other indent than STYLE.md §5 gives,
  ##   one whose indent would widen it among them, so finding stays where fixer holds line.
  let s = source.scan
  for shift in s.continuationShifts(Held()):
    let
      line = shift.rewrite.first
      relative = s.lines[line].indentOf - shift.rewrite.lines[0].indentOf + shift.step
      message =
        if shift.step == 0:
          "Line of expression whose first piece opens its own line takes no spaces more than " &
              "that line (STYLE.md §5); got `" & $relative & "`."
        else:
          "Line of expression past its statement line takes " & $CONTINUATION_STEP & " spaces " &
              "more than that line (STYLE.md §5); got `" & $relative & "`."
    result.add initReport(path, line + 1, Rule.ContinuationIndent, message)


func fixContinuations(path, source: string; held: Held): Fix =
  ## Re-indent each line check reports, but held line its indent would widen.
  applied(path, source, source.scan.continuationShifts(held).mapIt(it.rewrite))



#[ Trailing Separators ]#

func isConstructorOpen(s: Scan, o: int): bool =
  ## Decide whether bracket `o` opens list of values: array, seq, set, table, tuple, import.
  ##   `[` or `{` glued after operand indexes or names type; `(` glued after one calls; `{.`,
  ##   `[.`, `(.` and `[:` open pragma or generic call.
  let text = s.spelling(o)
  if text notin ["(", "[", "{"]: return false
  if o > 0:
    let is_glued = s.tokens[o - 1].after == s.tokens[o].first
    if is_glued and s.tokens.isOperandEnd(o - 1, s.source): return false
    if s.spelling(o - 1) in TYPE_KEYWORDS: return false
  text != "(" or s.tokens.signatureOf(s.partners, o, s.source) < 0


func trailingInserts(s: Scan, held: Held): seq[Insert] =
  ## Find each list written one item to line whose last item lacks trailing separator; one
  ##   whose separator would widen held line is left.
  for o in 0 ..< s.tokens.len:
    if s.tokens[o].kind != TokenKind.Open or s.partners[o] < o: continue
    let c = s.partners[o]
    if not s.isLineLast(o) or not s.isLineFirst(c): continue
    let
      is_call = s.tokens.isCallOpen(s.partners, o, s.source)
      is_signature = s.tokens.signatureOf(s.partners, o, s.source) >= 0
      items = s.items(o)
    if not (is_call or is_signature or s.isConstructorOpen(o)): continue
    if items.len == 0 or items[^1].separator >= 0: continue
    if not items.allIt(s.isLineFirst(it.first)): continue
    if not items[0 ..< ^1].allIt(s.isLineLast(it.separator)): continue
    let last = items[^1]
    if toSeq(last.first .. last.last).anyIt(
      s.spelling(it) in BLOCK_KEYWORDS or (s.spelling(it) == ":" and s.isLineLast(it)),
    ):
      continue
    var separator = ","
    if is_signature:
      let groups = s.groupsOf(items)
      if groups.len == 0: continue
      separator = groups.separatorOf
    elif s.spelling(o) == "(" and not is_call and items.len == 1: continue
    let
      line = s.lasts[last.last]
      at = s.tokens[last.last].after
      text = s.lines[line]
      cut = at - s.starts[line]
    if held.isHeld(line + 1) and (text[0 ..< cut] & separator & text[cut .. ^1]).isWide and
        not text.isWide:
      continue
    result.add Insert(line: line, at: at, separator: separator)


func checkTrailing*(path, source: string): seq[Report] =
  ## Report list written one item to line without trailing separator (X.3).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for insert in source.scan.trailingInserts(EVERY):
    result.add initReport(
      path,
      insert.line + 1,
      Rule.TrailingSeparator,
      "List written one item to line takes trailing separator (X.3); got none, where `" &
        insert.separator & "` stands.",
    )


func fixTrailing*(path, source: string; held: Held): Fix =
  ## Insert each trailing separator check reports, or that widens line off held lines, last
  ##   first, so earlier offsets hold.
  result.source = source
  let inserts = source.scan.trailingInserts(held)
  for insert in inserts.reversed:
    result.source.insert(insert.separator, insert.at)
  for insert in inserts:
    result.fixed.add initReport(path, insert.line + 1, Rule.TrailingSeparator)


func fixTrailing*(path, source: string): Fix =
  ## Insert each trailing separator check reports, last first, so earlier offsets hold.
  fixTrailing(path, source, EVERY)


const WRAPPING_STEPS*: array[5, Step] = [
  guarded(fixSeparators),
  guarded(fixSignatures),
  guarded(fixCalls),
  widening(fixContinuations),
  widening(fixTrailing),
]
  ## Wrapping fixers in order they run. Separators come first, since layouts join groups with
  ##   separator they read; continuations come after calls, since hand's line breaks that call
  ##   layout keeps move with their argument, and same round sets their indent; trailing
  ##   separators come last, adding what neither layout wrote to list left as written.


func fixWrapping*(path, source: string): Fix =
  ## Rewrite separators, signatures, calls, continuations, then trailing separators, each line
  ##   held.
  result.source = source
  for step in WRAPPING_STEPS: result = result.chain(step.run(path, result.source, EVERY))
