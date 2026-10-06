## Remove parentheses that group what parser groups anyway (Article X.4), and fix them (`koch
##   fix`): group goes only where parser of code's own compiler reads same tree without it.
##   Candidates are three kinds and these alone, as Architect chose:
##   - around prefix term standing as one side of binary operator: `(|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ 𝐦)`
##     becomes `|∙ ⊖(𝐦 ∧ 𝐧) + |∘ 𝐦`;
##   - around one plain operand right after prefix operator: `■(𝐧)` becomes `■𝐧`;
##   - around one plain operand as one side of binary operator: `2'u^(DIMENSIONS)` becomes
##     `2'u^DIMENSIONS`.
##   Plain operand: name or literal, with any call, index or field glued after it. Prefix term:
##     symbol prefix operators, then one operand. Elements read as `precedence.nim` reads them
##     (`elementsOf`), on group's line, inside bracket around it. Candidate set is pure reading
##     of text (`candidatesOf`).
##   Parser decides each candidate (`Proofs`, answered by `proofs.nim`): group goes where source
##     without it parses to same tree, each `nnkPar` of one child collapsed on both sides, alone
##     and with every other group removed. So `@(x[i])` stays, since sigil `@` binds `x` before
##     its index, and `a - (-b) -1` stays, since group is callee of command `(-b) -1`. Source no
##     answer holds removes nothing and asks (`Fix.asked`); unreadable source keeps every group.
##   Never candidate: group around binary expression, whatever its precedence, so X.4
##     parentheses around `and` stay; tuple, call, signature and argument of command form
##     (`x.f (a, b)`), which hold separator or glue to callee; group after power operator `^`
##     whose removal glues exponent into operator, since spacing keeps `^` tight (X.9) and
##     wraps that exponent again (`a^(-b)`), so both rules agree in one round.
##   Rewrite moves no reading, as parser proves. Removal never widens line. Chain runs it
##     before spacing, which glues `|∘ (` as `|∘(` in same round.
##
##   Cost: group spanning lines or holding comment is no candidate, and neighbour on another
##     line is not read; that only saves asking parser.
##   Cost: keyword prefix operator (`not`) is not read, since X.4 holds `not` apart.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, tables]
import ./[precedence, reports, spacing, tokens]


type Group* = object  ## Define parentheses to remove: span of each bracket with its inner spaces.
  line*: int  ## Zero-based line of group.
  opening*: (int, int)  ## Byte span of `(` and spaces after it.
  closing*: (int, int)  ## Byte span of spaces before `)` and `)`.
  got*: string  ## Group as written.


const KEYWORDS_OPERAND = ["false", "nil", "true"]  ## Keywords standing as plain operands.


func isPlain(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether operand opening at token `k` is plain: name or literal, call, index or field
  ##   glued after it joining it as element.
  let t = tokens[k]
  case t.kind
  of KindToken.Quoted, KindToken.Number, KindToken.Text, KindToken.Character: true
  of KindToken.Word: not t.isKeyword(source) or t.spelling(source) in KEYWORDS_OPERAND
  else: false


func windowOf(tokens: openArray[Token], partners: openArray[int], o: int): (int, int) =
  ## Read first and last token around group `o` on its line, inside bracket around it; bracket
  ##   group of line is passed whole, and comment or bracket opening or closing elsewhere ends it.
  let line = tokens[o].line
  var first = o - 1
  while first >= 0 and tokens[first].line == line:
    let p = partners[first]
    if tokens[first].kind == KindToken.Close and p >= 0 and tokens[p].line == line:
      first = p - 1
    elif tokens[first].kind in {KindToken.Open, KindToken.Close, KindToken.Comment}: break
    else: dec first
  var last = partners[o] + 1
  while last < tokens.len and tokens[last].line == line:
    let p = partners[last]
    if tokens[last].kind == KindToken.Open and p > last and tokens[p].line == line:
      last = p + 1
    elif tokens[last].kind in {KindToken.Open, KindToken.Close, KindToken.Comment}: break
    else: inc last
  (first + 1, last - 1)


func candidatesOf*(source: string): seq[Group] =
  ## Find each group of one of three kinds header gives, in source order; parser decides which
  ##   go.
  let
    tokens = source.tokens
    partners = tokens.partners
  for o, t in tokens:
    let c = partners[o]
    if t.kind != KindToken.Open or t.spelling(source) != "(" or c < o + 2: continue
    if tokens[c].line != t.line or tokens[c].lineLast(source) != t.line: continue
    if toSeq(o + 1 ..< c).anyIt(tokens[it].kind == KindToken.Comment): continue

    # Group opens element of its own, so no callee glues to it; suffix may follow, parser reads.
    let
      (first, last) = tokens.windowOf(partners, o)
      elements = elementsOf(tokens, partners, first, last, source)
      at = elements.mapIt(it.first).find(o)
    if at < 0: continue
    let
      inner = elementsOf(tokens, partners, o + 1, c - 1, source)
      before = if at > 0: elements[at - 1].kind else: KindElement.Delimiter
      after = if at < elements.high: elements[at + 1].kind else: KindElement.Delimiter
      is_prefix_symbol = before == KindElement.Prefix and
        tokens[elements[at - 1].first].kind == KindToken.Operator
      is_side = before == KindElement.Binary or
        (after == KindElement.Binary and before != KindElement.Prefix)
      is_plain = inner.len == 1 and inner[0].kind == KindElement.Operand and
        tokens.isPlain(inner[0].first, source)
      is_term = inner.len >= 2 and inner[^1].kind == KindElement.Operand and
        inner[0 ..< ^1].allIt(
          it.kind == KindElement.Prefix and tokens[it.first].kind == KindToken.Operator,
        )
    if not ((is_term and is_side) or (is_plain and (is_prefix_symbol or is_side))): continue

    # Exponent of `^` glued into operator stays, since spacing glues `^` and wraps it (X.9).
    let is_power = before == KindElement.Binary and tokens[o - 1].spelling(source) == "^"
    if is_power and source.isMerging([tokens[o - 1], tokens[o + 1]]): continue
    result.add Group(
      line: t.line,
      opening: (t.first, tokens[o + 1].first),
      closing: (tokens[c - 1].after, tokens[c].after),
      got: source[t.first ..< tokens[c].after],
    )


func provenOf(source: string, proofs: Proofs): seq[Group] =
  ## Read each candidate of source parser proves; none where no answer holds.
  let answer = proofs.answers.getOrDefault(source)
  source.candidatesOf.filterIt(it.opening[0] in answer)


func questionsOf*(source: string, proofs: Proofs): seq[string] =
  ## Read what source asks parser: itself, where it holds candidate and no answer for it.
  if source notin proofs.answers and source.candidatesOf.len > 0: result.add source


func checkParentheses*(path, source: string; proofs: Proofs): seq[Report] =
  ## Report parentheses parser proves needless: around prefix term or plain operand beside
  ##   binary operator, or around plain operand after prefix operator (X.4). Group no proof
  ##   reaches is reported by none, so check never names group fix keeps.
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for group in source.provenOf(proofs):
    result.add initReport(
      path,
      group.line + 1,
      Rule.ParenthesesNeedless,
      "Parentheses grouping what parser groups anyway go: prefix term or plain operand beside " &
        "operator, as parser of code's compiler proves; got `" & group.got & "`.",
    )


func fixParentheses*(path, source: string; proofs: Proofs): Fix =
  ## Remove each group parser proves, spans last first, so earlier offsets hold; source holding
  ##   candidate and no answer writes nothing, and asks.
  result = Fix(source: source, asked: source.questionsOf(proofs))
  var spans: seq[(int, int)]
  for group in source.provenOf(proofs):
    spans.add @[group.opening, group.closing]
    result.fixed.add initReport(path, group.line + 1, Rule.ParenthesesNeedless)
  for (a, b) in spans.sortedByIt(-it[0]):
    result.source = result.source[0 ..< a] & result.source[b .. ^1]
