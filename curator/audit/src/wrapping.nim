## Enforce how Nim parameters separate (STYLE.md §5), and fix it (`koch fix`).
##   Parameters: `,` between groups while every type appears once; where one group holds several
##     names of one type (`a, b: X`), `;` between every group, trailing one included. Holds on one
##     line and across several, in routine, routine type and lambda.
##   Check and fixer share one reading (`separators`), so rule is written once (Article II.1).
##
##   Left as written, check silent: parameter group without type or default, where `;` ends
##     group, so no separator reads right.
##
##   Cost: scanner, never parser (`tokens.nim`); construct it cannot read surely stays as written.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./[findings, tokens]


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


func fixWrapping*(path, source: string): Fix =
  ## Rewrite separators of each parameter list.
  fixSeparators(path, source)
