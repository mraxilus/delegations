## Remove parentheses that group what parser groups anyway (Article X.4), and fix them (`koch
##   fix`), in three kinds and these alone, as Architect chose:
##   - around prefix term standing as one side of binary operator: `(|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ 𝐦)`
##     becomes `|∙ ⊖(𝐦 ∧ 𝐧) + |∘ 𝐦`, since prefix operator binds tighter than any binary one;
##   - around one plain operand right after prefix operator: `■(𝐧)` becomes `■𝐧`;
##   - around one plain operand as one side of binary operator: `2'u^(DIMENSIONS)` becomes
##     `2'u^DIMENSIONS`.
##   Plain operand: name or literal, with any call, index or field glued after it. Prefix term:
##     symbol prefix operators, then one operand. Elements read as `precedence.nim` reads them
##     (`elementsOf`), on group's line, inside bracket around it.
##   Never removed: group around binary expression, whatever its precedence, so X.4 parentheses
##     around `and` stay; group with suffix glued after it (`.`, `[`, `(`, `{`), since `■𝐧.x`
##     reads `■(𝐧.x)`; group whose removal glues two tokens into one (`isMerging` of
##     `spacing.nim`), as `^(|𝐦)` and `-(1)`; tuple, call, signature and argument of command
##     form (`x.f (a, b)`), which hold separator or glue to callee; prefix term after command
##     head, since `check |∙ x` reads `|∙` as binary operator; group after prefix opening with
##     `@` around operand with call, index or field, since that prefix binds before them and
##     `@x[i]` reads `(@x)[i]`.
##   Group after power operator `^` reads glued, since spacing glues `^` (X.9), so `a ^ (-b)`
##     keeps exponent spacing wraps (`a^(-b)`), and both rules agree.
##   Rewrite moves no reading: parser keeps parentheses around one node as `nkPar` of it alone,
##     and prefix node binds its operand alone. Removal never widens line. Chain runs it before
##     spacing, which glues `|∘ (` as `|∘(` in same round.
##
##   Cost: scanner, never parser; group spanning lines or holding comment stays, and neighbour on
##     another line is not read.
##   Cost: keyword prefix operator (`not`) is not read; X.4 holds `not` apart, and `not(a)` glued
##     would lex as name.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils]
import ./[precedence, reports, spacing, tokens]


type Group = object  ## Define parentheses to remove: span of each bracket with its inner spaces.
  line: int  ## Zero-based line of group.
  opening: (int, int)  ## Byte span of `(` and spaces after it.
  closing: (int, int)  ## Byte span of spaces before `)` and `)`.
  got: string  ## Group as written.


const
  OPERAND_KEYWORDS = ["false", "nil", "true"]  ## Keywords standing as plain operands.
  PASSES_MAX = 4  ## Passes parentheses fixer takes at most; one pass settles every case read.


func isPlain(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether operand opening at token `k` is plain: name or literal, call, index or field
  ##   glued after it joining it as element.
  let t = tokens[k]
  case t.kind
  of TokenKind.Quoted, TokenKind.Number, TokenKind.Text, TokenKind.Character: true
  of TokenKind.Word: not t.isKeyword(source) or t.spelling(source) in OPERAND_KEYWORDS
  else: false


func windowOf(tokens: openArray[Token], partners: openArray[int], o: int): (int, int) =
  ## Read first and last token around group `o` on its line, inside bracket around it; bracket
  ##   group of line is passed whole, and comment or bracket opening or closing elsewhere ends it.
  let line = tokens[o].line
  var first = o - 1
  while first >= 0 and tokens[first].line == line:
    let p = partners[first]
    if tokens[first].kind == TokenKind.Close and p >= 0 and tokens[p].line == line:
      first = p - 1
    elif tokens[first].kind in {TokenKind.Open, TokenKind.Close, TokenKind.Comment}: break
    else: dec first
  var last = partners[o] + 1
  while last < tokens.len and tokens[last].line == line:
    let p = partners[last]
    if tokens[last].kind == TokenKind.Open and p > last and tokens[p].line == line:
      last = p + 1
    elif tokens[last].kind in {TokenKind.Open, TokenKind.Close, TokenKind.Comment}: break
    else: inc last
  (first + 1, last - 1)


func groups(source: string): seq[Group] =
  ## Find each group of one of three kinds header gives, whose removal glues no tokens.
  let
    tokens = source.tokens
    partners = tokens.partners
  for o, t in tokens:
    let c = partners[o]
    if t.kind != TokenKind.Open or t.spelling(source) != "(" or c < o + 2: continue
    if tokens[c].line != t.line or tokens[c].lastLine(source) != t.line: continue
    if toSeq(o + 1 ..< c).anyIt(tokens[it].kind == TokenKind.Comment): continue

    # Group stands as element of its own, nothing glued after it: no call, no suffix.
    let
      (first, last) = tokens.windowOf(partners, o)
      elements = elementsOf(tokens, partners, first, last, source)
      at = elements.mapIt(it.first).find(o)
    if at < 0 or elements[at].last != c: continue
    let
      inner = elementsOf(tokens, partners, o + 1, c - 1, source)
      before = if at > 0: elements[at - 1].kind else: ElementKind.Delimiter
      after = if at < elements.high: elements[at + 1].kind else: ElementKind.Delimiter
      is_symbol_prefix = before == ElementKind.Prefix and
        tokens[elements[at - 1].first].kind == TokenKind.Operator
      is_sigil = is_symbol_prefix and tokens[elements[at - 1].first].spelling(source)[0] == '@'
      is_side = before == ElementKind.Binary or
        (after == ElementKind.Binary and before != ElementKind.Prefix)
      is_plain = inner.len == 1 and inner[0].kind == ElementKind.Operand and
        tokens.isPlain(inner[0].first, source)
      is_term = inner.len >= 2 and inner[^1].kind == ElementKind.Operand and
        inner[0 ..< ^1].allIt(
          it.kind == ElementKind.Prefix and tokens[it.first].kind == TokenKind.Operator,
        )
      is_term_side = is_term and is_side and before != ElementKind.Operand
    if not (is_term_side or (is_plain and (is_symbol_prefix or is_side))): continue
    # Prefix opening with `@` binds before call, index or field, so `@x[i]` reads `(@x)[i]`.
    if is_sigil and inner[0].last > inner[0].first: continue

    # Removal leaves gap before `(` and after `)`; where either is none, tokens must not merge.
    #   Power operator before group counts glued, since spacing glues it (X.9).
    let is_power = before == ElementKind.Binary and tokens[o - 1].spelling(source) == "^"
    if o > 0 and (tokens[o - 1].after == t.first or is_power) and
        tokens[o - 1].line == t.line and source.isMerging([tokens[o - 1], tokens[o + 1]]):
      continue
    if c < tokens.high and tokens[c + 1].first == tokens[c].after and
        source.isMerging([tokens[c - 1], tokens[c + 1]]):
      continue
    result.add Group(
      line: t.line,
      opening: (t.first, tokens[o + 1].first),
      closing: (tokens[c - 1].after, tokens[c].after),
      got: source[t.first ..< tokens[c].after],
    )


func checkParentheses*(path, source: string): seq[Report] =
  ## Report parentheses around prefix term or plain operand beside binary operator, or around
  ##   plain operand after prefix operator (X.4).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for group in source.groups:
    result.add initReport(
      path,
      group.line + 1,
      Rule.NeedlessParentheses,
      "Parentheses grouping what parser groups anyway go: prefix term or plain operand beside " &
        "operator (X.4); got `" & group.got & "`.",
    )


func fixParentheses*(path, source: string): Fix =
  ## Remove each group check reports, spans last first, so earlier offsets hold; pass after pass
  ##   until none is left.
  result.source = source
  for pass in 1 .. PASSES_MAX:
    let found = result.source.groups
    if found.len == 0: break
    var
      spans: seq[(int, int)]
      step = Fix(source: result.source)
    for group in found:
      spans.add @[group.opening, group.closing]
      step.fixed.add initReport(path, group.line + 1, Rule.NeedlessParentheses)
    for (a, b) in spans.sortedByIt(-it[0]):
      step.source = step.source[0 ..< a] & step.source[b .. ^1]
    result = result.chain(step)
