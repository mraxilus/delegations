## Enforce how Nim parameters separate and signatures wrap (Article X.3, STYLE.md §5), and fix
##   it (`koch fix`).
##   Parameters: `,` between groups while every type appears once; where one group holds several
##     names of one type (`a, b: X`), `;` between every group, trailing one included. Holds on one
##     line and across several, in routine, routine type and lambda.
##   Signature: one fitting `LINE_MAX` stands on one line, and wrapped one that would fit is
##     joined. Where parameters fit no line of their own, each group takes own line, indented one
##     level, with trailing separator, and `)` opens closing line with return type and pragmas.
##     Where they fit one line of their own, both layouts stand, each indented one level.
##   Checks and fixers share one reading (`separators`, `signatureRewrites`), so each rule is
##     written once (Article II.1).
##
##   Contradiction, left to Architect: STYLE.md §5 wraps parameters onto one line of their own
##     first, and one to line only where that line fits not, yet its second example sets one
##     group to line where line of them fits in 91 columns; X.3 says signature "may" first wrap.
##     So where that line fits, fixer keeps layout author chose, re-indented, and leaves one-line
##     signature too wide there to hand; width check still reports it.
##   Left as written, check silent: parameter group without type or default, where `;` ends
##     group; signature holding comment or long string spanning lines; signature whose group
##     spans lines; signature fitting one line where body after `=` does not, since moving body
##     and wrapping are two answers.
##
##   Cost: scanner, never parser (`tokens.nim`); construct it cannot read surely stays as written.
##   Cost: fixer never writes line width check reports; rewrite that would, stays to hand.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[findings, form, names, tokens]


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

  Rewrite = object
    ## Define lines to replace, and lines replacing them.
    first: int  ## Zero-based first line replaced.
    last: int  ## Zero-based last line replaced.
    lines: seq[string]


const INDENT_STEP = 2
  ## Spaces one level of wrapping indents (Article X.1).


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


func holds(s: Scan, item: Item, spellings: openArray[string]): bool =
  ## Decide whether item holds token of spellings outside its nested brackets.
  var k = item.first
  while k <= item.last:
    if s.spelling(k) in spellings: return true
    if s.tokens[k].kind == TokenKind.Open and s.partners[k] > k: k = s.partners[k]
    inc k


func applied(path, source: string; rewrites: openArray[Rewrite]; rule: string): Fix =
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
  for rewrite in rewrites: result.fixed.add finding(path, rewrite.first + 1, rule & " fixed")
  if origin != toSeq(1 .. origin.len): result.origin = origin



#[ Parameter Separators ]#

func groupsOf(s: Scan, items: openArray[Item]): seq[seq[Item]] =
  ## Group parameters sharing one type: names up to one typed or defaulted, or up to `;`.
  ##   Empty where any group lacks type and default, which no rule here reads.
  var group: seq[Item]
  for item in items:
    group.add item
    let is_typed = s.holds(item, [":", "="])
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


func checkSeparators*(path, source: string): seq[Finding] =
  ## Report separator between parameter groups breaking STYLE.md §5.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  let s = source.scan
  for k in s.separators:
    result.add finding(
      path,
      s.tokens[k].line + 1,
      "Parameters take `;` between groups where one group shares its type, and `,` otherwise " &
        "(STYLE.md §5); got `" & s.spelling(k) & "`.",
    )


func fixSeparators*(path, source: string): Fix =
  ## Rewrite each separator check reports; `,` and `;` share width, so no line moves.
  let s = source.scan
  result.source = source
  for k in s.separators:
    result.source[s.tokens[k].first] = if s.spelling(k) == ",": ';' else: ','
    result.fixed.add finding(path, s.tokens[k].line + 1, "parameter separators (STYLE.md §5) fixed")



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
      # Both layouts stand here (STYLE.md §5 examples, X.3 "may"): keep author's, re-indented.
      let
        is_wrapped = s.isLineLast(o) and s.isLineFirst(c)
        is_parameters_line = is_wrapped and last_line == first_line + 2 and
          groups.allIt(s.tokens[it[0].first].line == first_line + 1)
        is_group_lines = is_wrapped and last_line == first_line + groups.len + 1 and
          toSeq(0 ..< groups.len).allIt(s.tokens[groups[it][0].first].line == first_line + 1 + it)
      # One group fits both shapes, which differ by trailing separator alone: one name on its
      #   line is list written one item to line, which takes it (X.3).
      if is_parameters_line and is_group_lines:
        let is_trailed = items[^1].separator >= 0 or items.len == 1
        canonical = if is_trailed: group_lines else: parameters_line
      elif is_parameters_line: canonical = parameters_line
      elif is_group_lines: canonical = group_lines
      else: continue
    elif not group_lines.anyIt(it.isWide): canonical = group_lines
    else: continue
    if canonical != s.lines[first_line .. last_line]:
      result.add Rewrite(first: first_line, last: last_line, lines: canonical)


func checkSignatures*(path, source: string): seq[Finding] =
  ## Report signature laid out against X.3 and STYLE.md §5.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for rewrite in source.scan.signatureRewrites:
    result.add finding(
      path,
      rewrite.first + 1,
      "Signature stays on one line where it fits, else wraps one group to line, indented one " &
        "level (X.3, STYLE.md §5); got `" & $(rewrite.last - rewrite.first + 1) & "` lines.",
    )


func fixSignatures*(path, source: string): Fix =
  ## Rewrite each signature check reports into its layout.
  applied(path, source, source.scan.signatureRewrites, "signature wrapping (X.3)")


func fixWrapping*(path, source: string): Fix =
  ## Rewrite separators, then signatures.
  ##   Separators come first, since layout joins groups with separator it reads.
  result.source = source
  for fixer in [fixSeparators, fixSignatures]:
    result = result.chain(fixer(path, result.source))
