## Enforce spaces inside Nim expressions (Article X.9), and fix them (`koch fix`).
##   Spaces are list X.9 gives; every gap list names takes its count:
##   - binary operator and `=` take one space on each side; one ending its line takes one before;
##   - range operator (`..`, `..<`, `..^`) takes none, but one on each side where piece beside it
##     holds binary operator binding tighter (`i + 1 ..< n`), or where glued tokens would merge
##     (`1 .. ^1`, `0 .. -1`);
##   - power operator `^` takes none, since spaced it reads as operator on bits, but one on each
##     side where glued tokens would merge (`a ^ -b`); nothing but prefix operator binds tighter,
##     so its pieces never keep it apart;
##   - inside bracket `[…]` glued to operand before it (index, type or generic, which tokens
##     cannot tell apart), symbol binary operator takes none, range and its math among them, at
##     any depth: `prev[i-1]`, `digits[i+1..<n]`, `a[f(x, y+1)]`; word operator keeps one each
##     side, which tokeniser demands, and glued tokens that would merge keep one; array literal
##     standing alone is no such bracket, nor generic list routine or type declares after its
##     name, export marker or not (`func pick[I: A | B]`, `isDeclaredList`);
##   - prefix operator is glued to its operand, unless tokeniser demands one space (X.9);
##   - comma and semicolon take none before them and one after; colon of type, field or branch
##     likewise;
##   - bracket holds no space inside it, after opening or before closing;
##   - trailing comment takes two before its marker, which `form.nim` holds.
##   Reads tokens (`tokens.nim`), so string, character, comment and quoted name never trip it.
##     Gap between two tokens of one line is read; line break and indent are not.
##   Binary place: operator after operand (`isOperandEnd`), never first token of its line, since
##     compiler reads operator opening line as no binary one. Keyword operators (`and`, `div`,
##     `in`, …) count; `not` and `as` never stand binary.
##   Lexer reads whether space stands before operator and whether one stands after, never how
##     many; space before and none after reads prefix (`isUnary`), so `a -b` is call `a(-b)`.
##     Rule therefore rewrites only spacing whose reading cannot move: spaces on both sides or
##     on neither (`a+b`, `a  + b`), and operator ending its line, which lexer marks end and
##     never prefix. `a -b`, `a- b` and `a ⊖b` stay, and check reports none of them.
##   Range glued, as Architect ruled for X.9: `2..6`, `0..<n`. Piece beside range runs, at its
##     depth on its line, through operands, prefix operators and binary operators binding
##     tighter than range (`precedence.nim`: `..` binds at 6, `+` at 8, glyph at 8 or 9); looser
##     operator, delimiter, bracket around it or command head ends it (`isRangeApart`). Piece
##     holding tighter operator keeps spaces, since `i + 1..<n` reads as if range starts at 1;
##     bracket group is operand, so spaces inside it count not. Spacing moves no parse tree, as
##     compiler confirms, so rewrite moves no reading.
##   Merge guard (`isMerging`): range keeps one space each side where operator glued to both
##     neighbours lexes as other tokens, so `1 .. ^1` and `0 .. -1` stay; compound `1 ..^ 1`
##     glues to `1..^1`, one operator still. Range in prefix place (`a[.. 2]`) stays unread.
##   Prefix place: operator after anything but operand, which is where parser reads prefix
##     node; spaces after it go, unless operator and operand glued lex as other tokens
##     (`isMerging`). There exactly one space stays, so fix never splits or merges token
##     (Architect): operand opening with operator character, since `|∙ ⊖m` glued lexes one
##     operator `|∙⊖`, and `- -x` lexes `--`; and `-` before number, since `- 1` glued is
##     literal `-1`, which `-128'i8` shows differs.
##   Gap is never closed where tokens would merge: `(` before `.` (`(.` opens pragma), `[`
##     before `:` (`[:`), `.` before `)` (`.)`), and colon after operator (`*:`, `=:`).
##   `=` of definition, default, assignment or named argument: lexer reads `=` as no operator,
##     so any spacing of it moves nothing, and `=` glued to operator character lexes as other
##     operator (`=-`), which rule never reads.
##   Never read: `::`, `.` and dot-like operators (`.?`), glued as field access; operators of
##     `import`, `include`, `from` and `export`, whose `/` and `..` spell paths; export marker,
##     i.e. `*` glued after name that declaration places, before anything but operand. Name
##     opening its line, following declaration keyword, or following comma on line whose first
##     name is marked, is so placed; name inside expression is not, so `PI*(a + b)` multiplies.
##
##   Cost: name opening continuation line reads as declared, so `a*(b)` opening line stays.
##   Cost: asymmetric spacing stays, and reading holds it; its fix is choice of meaning.
##   Cost: spaces aligning columns of hand-shaped table go; fence keeps them (`fixes.nim`, X.1).
##   Cost: fix spaces token lexer read, never splits nor merges it, so `1 .. ^1` and `1..^1`
##     both stay; which one is hand's choice.
##   Cost: piece is read on range's line alone, so operator of piece on line before is unread.
##   Fixer is widener (`reports.nim`): off held line it writes spacing that widens line past
##     `LINE_MAX`, and chain wraps line after; on held line, as in its two-argument form,
##     spacing that would widen narrow line stays, finding and all.

{.experimental: "strictFuncs".}

import std/[algorithm, sets, strutils, unicode]
import ./[form, precedence, reports, tokens, views]


type
  Placement {.pure.} = enum  ## Define which rule of X.9 gap falls under, which decides its spaces.
    Binary  ## Around binary operator: one space each side.
    Ending  ## Before binary operator ending its line, range among them: one.
    Range  ## Around range operator: none.
    RangeApart  ## Around range whose piece binds tighter, or whose glued tokens merge: one.
    Power  ## Around power operator `^`: none.
    PowerApart  ## Around power operator whose glued tokens merge: one.
    Selector  ## Around symbol operator inside bracket glued to operand: none.
    SelectorApart  ## Around such operator whose glued tokens merge: one.
    Prefix  ## After prefix operator: none.
    Apart  ## After prefix operator whose operand glued would merge with it: one.
    Equals  ## Around `=`: one space each side.
    Comma  ## Before comma none, after it one.
    Semicolon  ## Before semicolon none, after it one.
    Colon  ## Before colon none, after it one.
    Inner  ## Inside bracket: none.

  Edit = object  ## Define one gap of source to rewrite: byte span and spaces it takes.
    first: int  ## Byte offset gap opens at.
    after: int  ## Byte offset after gap.
    spaces: int  ## Spaces gap takes.

  Respacing = object  ## Define one breach of rule: line, gaps to rewrite, excerpt to echo.
    placement: Placement
    line: int  ## Zero-based line of breach.
    edits: seq[Edit]
    got: string  ## Breach with its neighbours, as written.


const
  KEYWORD_OPERATORS = [
    "and", "div", "in", "is", "isnot", "mod", "notin", "of", "or", "shl", "shr", "xor",
  ]
    ## Keywords lexer reads as binary operators (`isOperator`); `not` and `as` stand otherwise.
  RANGE_OPERATORS = ["..", "..<", "..^"]  ## Range operators, glued unless apart (X.9).
  POWER_OPERATOR = "^"  ## Power operator, glued unless tokens merge (X.9); never `^=` or `..^`.
  IGNORED_OPERATORS = ["::", ":", "."]
    ## Operator tokens of type, field and access, never spaced as operators.
  STATEMENT_KEYWORDS = ["export", "from", "import", "include"]
    ## Keywords opening statement whose operators spell module paths.
  DECLARATION_KEYWORDS = [
    "const", "converter", "func", "iterator", "let", "macro", "method", "proc", "template", "type",
    "using", "var",
  ]
    ## Keywords whose next name declares, so `*` glued after it marks export.
  GENERIC_HEADS = [
    "converter", "func", "iterator", "macro", "method", "proc", "template", "type",
  ]
    ## Keywords whose head declares generic list after its name: declaration, never selector.
  PLAIN_BRACKETS = ["(", "[", "{"]
    ## Brackets that glue to dot or colon after them into one token, or before them from dot.
  EXCERPT_RUNES = 12  ## Runes of each neighbour echoed beside breach.


func pathTokens*(tokens: openArray[Token], partners: openArray[int], source: string): HashSet[int] =
  ## Collect tokens of `import`, `include`, `from` and `export` statements: brackets, and lines
  ##   indented under statement's own, included.
  var indents: seq[int]
  for line in source.split('\n'): indents.add line.indentOf
  var k = 0
  while k < tokens.len:
    let
      t = tokens[k]
      is_opening = k == 0 or tokens[k - 1].line < t.line or tokens[k - 1].spelling(source) == ":"
    if not (is_opening and t.spelling(source) in STATEMENT_KEYWORDS):
      inc k
      continue
    var j = k
    while j < tokens.len and
        (tokens[j].line == t.line or indents[tokens[j].line] > indents[t.line]):
      result.incl j
      if tokens[j].kind == TokenKind.Open and partners[j] > j:
        for m in j .. partners[j]: result.incl m
        j = partners[j]
      inc j
    k = j


func isExportMarker(tokens: openArray[Token], k: int, lasts: openArray[int], source: string): bool =
  ## Decide whether `*` at `k` stands where export marker may: glued after name that opens its
  ##   line, follows declaration keyword, or follows comma after name so marked.
  ##   Name inside expression declares nothing, so `*` after it multiplies.
  if tokens[k].spelling(source) != "*" or k == 0: return false
  let name = tokens[k - 1]
  if name.kind notin {TokenKind.Word, TokenKind.Quoted} or name.after != tokens[k].first:
    return false
  if k == 1 or lasts[k - 2] < name.line: return true
  let before = tokens[k - 2].spelling(source)
  if before in DECLARATION_KEYWORDS: return true
  before == "," and k >= 3 and tokens.isExportMarker(k - 3, lasts, source)


func isMerging*(source: string, run: openArray[Token]): bool =
  ## Decide whether tokens of run glued lex as other tokens: one operator, as `|∙` and `⊖` lex
  ##   `|∙⊖`, or one literal, as `-` and `1` lex `-1`. Binary operator is read with both its
  ##   neighbours, so `i-1` stays three tokens.
  var spellings: seq[string]
  for t in run: spellings.add t.spelling(source)
  let glued = spellings.join
  var lexed: seq[string]
  for t in glued.tokens: lexed.add t.spelling(glued)
  lexed != spellings


func excerpt(source: string; before, after: Token): string =
  ## Echo what stands between two tokens, with few runes of each.
  let
    left = source[before.first ..< before.after].runeSubStr(-EXCERPT_RUNES)
    right = source[after.first ..< after.after].runeSubStr(0, EXCERPT_RUNES)
  left & source[before.after ..< after.first] & right


func around(source: string, tokens: openArray[Token], k: int, spaces: int): seq[Edit] =
  ## Build edits setting gap on each side of token `k` to spaces.
  @[
    Edit(first: tokens[k - 1].after, after: tokens[k].first, spaces: spaces),
    Edit(first: tokens[k].after, after: tokens[k + 1].first, spaces: spaces),
  ]


func gapRespacing(tokens: openArray[Token], k: int, source: string): Respacing =
  ## Read rule of list holding gap between tokens `k - 1` and `k`, where gap breaks it; edits
  ##   empty where no rule reads gap or gap holds it.
  let
    (a, b) = (tokens[k - 1], tokens[k])
    (left, right) = (a.spelling(source), b.spelling(source))
    gap = b.first - a.after
  var wanted = -1
  if a.kind == TokenKind.Open:
    let is_merging = (left in PLAIN_BRACKETS and right.startsWith(".")) or
      (left == "[" and right.startsWith(":"))
    if not is_merging: (wanted, result.placement) = (0, Placement.Inner)
  elif b.kind == TokenKind.Close:
    if not (left.endsWith(".") and right in [")", "]", "}"]):
      (wanted, result.placement) = (0, Placement.Inner)
  elif a.kind == TokenKind.Comma: (wanted, result.placement) = (1, Placement.Comma)
  elif b.kind == TokenKind.Comma: (wanted, result.placement) = (0, Placement.Comma)
  elif a.kind == TokenKind.Semicolon: (wanted, result.placement) = (1, Placement.Semicolon)
  elif b.kind == TokenKind.Semicolon: (wanted, result.placement) = (0, Placement.Semicolon)
  elif a.kind == TokenKind.Operator and left == ":":
    (wanted, result.placement) = (1, Placement.Colon)
  elif b.kind == TokenKind.Operator and right == ":" and a.kind != TokenKind.Operator:
    (wanted, result.placement) = (0, Placement.Colon)
  if wanted < 0 or gap == wanted: return
  result.line = b.line
  result.edits = @[Edit(first: a.after, after: b.first, spaces: wanted)]
  result.got = source.excerpt(a, b)


func columnOf(source: string, at: int): int =
  ## Count bytes between start of line and offset.
  var k = at
  while k > 0 and source[k - 1] != '\n': dec k
  at - k


func isDeclaredList(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether `[` at `k` opens generic list that declaration names: after name, export
  ##   marker optional, that routine keyword or `type` heads on its line, or that opens entry
  ##   line of `type` section, i.e. nearest line above at smaller indent opens with `type`.
  var j = k - 1
  if j > 0 and tokens[j].spelling(source) == "*" and tokens[j - 1].after == tokens[j].first:
    dec j
  if tokens[j].kind notin {TokenKind.Word, TokenKind.Quoted}: return false
  if j > 0 and tokens[j - 1].lastLine(source) == tokens[j].line:
    return tokens[j - 1].spelling(source) in GENERIC_HEADS

  # Name opens its line: read keyword of nearest line above at smaller indent.
  let indent = source.columnOf(tokens[j].first)
  var m = j - 1
  while m >= 0:
    let is_first = m == 0 or tokens[m - 1].lastLine(source) < tokens[m].line
    if is_first and tokens[m].kind != TokenKind.Comment and
        source.columnOf(tokens[m].first) < indent:
      return tokens[m].spelling(source) == "type"
    dec m
  false


func isRangeApart(
  tokens: openArray[Token]; partners: openArray[int]; k: int; source: string
): bool =
  ## Decide whether piece on either side of range at `k` holds binary operator binding tighter
  ##   than range. Piece is read on range's line, at its depth: bracket group is operand, and
  ##   looser operator, delimiter, bracket around it or command head ends it.
  let line = tokens[k].line
  var first = k - 1
  while first >= 0 and tokens[first].line == line:
    let p = partners[first]
    if tokens[first].kind == TokenKind.Close and p >= 0 and tokens[p].line == line:
      first = p - 1
    elif tokens[first].kind in {TokenKind.Open, TokenKind.Close, TokenKind.Comment}: break
    else: dec first
  var last = k + 1
  while last < tokens.len and tokens[last].line == line:
    let p = partners[last]
    if tokens[last].kind == TokenKind.Open and p > last and tokens[p].line == line:
      last = p + 1
    elif tokens[last].kind in {TokenKind.Open, TokenKind.Close, TokenKind.Comment}: break
    else: inc last
  let elements = elementsOf(tokens, partners, first + 1, last - 1, source)
  var at = -1
  for m, e in elements:
    if e.first == k: at = m
  if at < 0 or elements[at].kind != ElementKind.Binary: return false

  # Walk out from range each way; first binary operator met inside piece decides.
  for direction in [-1, 1]:
    var m = at + direction
    while m >= 0 and m < elements.len:
      let
        e = elements[m]
        (outer, inner) = if direction < 0: (e, elements[m+1]) else: (elements[m-1], e)
        is_head = outer.kind == ElementKind.Operand and
          inner.kind in {ElementKind.Operand, ElementKind.Prefix} and
          tokens[outer.last].after < tokens[inner.first].first
      if is_head or e.kind == ElementKind.Delimiter: break
      if e.kind == ElementKind.Binary:
        if e.precedence > elements[at].precedence: return true
        break
      m += direction
  false


func respacings(source: string): seq[Respacing] =
  ## Find each gap breaking X.9 list whose rewrite moves no reading.
  let
    tokens = source.tokens
    partners = tokens.partners
    skipped = tokens.pathTokens(partners, source)
  var
    lasts = newSeq[int](tokens.len)
    selected = newSeq[bool](tokens.len)  # Inside bracket glued to operand before it.
  for k, t in tokens:
    lasts[k] = t.lastLine(source)
    let p = partners[k]
    if t.spelling(source) != "[" or k == 0 or p < k or tokens[k-1].after != t.first: continue
    if tokens.isOperandEnd(k - 1, source) and not tokens.isDeclaredList(k, source):
      for m in k + 1 ..< p: selected[m] = true
  for k, t in tokens:
    if k == 0 or lasts[k - 1] < t.line: continue
    if tokens[k - 1].kind == TokenKind.Comment or t.kind == TokenKind.Comment: continue

    # Comma, colon and bracket: gap before token, read wherever it stands.
    let gap = tokens.gapRespacing(k, source)
    if gap.edits.len > 0: result.add gap
    if k in skipped: continue
    let
      text = t.spelling(source)
      is_line_end = k == tokens.high or tokens[k + 1].line > lasts[k] or
        tokens[k + 1].kind == TokenKind.Comment
      before = tokens[k - 1]
      left = t.first - before.after
      is_keyword_operator = t.kind == TokenKind.Word and text in KEYWORD_OPERATORS
    if t.kind != TokenKind.Operator and not is_keyword_operator: continue
    var spacing = Respacing(line: t.line)

    # Space `=` one each side, wherever it stands; lexer reads no spacing of it.
    if text == "=":
      spacing.placement = Placement.Equals
      if is_line_end:
        if left == 1: continue
        spacing.edits = @[Edit(first: before.after, after: t.first, spaces: 1)]
        spacing.got = source.excerpt(before, t)
      else:
        let
          next = tokens[k + 1]
          right = next.first - t.after
        if left == 1 and right == 1: continue
        if before.kind == TokenKind.Open or next.kind in {TokenKind.Close, TokenKind.Comma}:
          continue
        spacing.edits = source.around(tokens, k, 1)
        spacing.got = source.excerpt(before, tokens[k + 1])
      result.add spacing
      continue
    if text in IGNORED_OPERATORS or (text.len > 1 and text[0] == '.' and text[1] != '.'):
      continue
    if not tokens.isOperandEnd(k - 1, source):
      # Glue prefix operator to its operand; one space stays where glued pair would merge.
      if is_keyword_operator or is_line_end or text in RANGE_OPERATORS: continue
      let next = tokens[k + 1]
      if next.first == t.after or next.isKeyword(source): continue
      let wanted = if source.isMerging([t, next]): 1 else: 0
      if next.first - t.after == wanted: continue
      spacing.placement = if wanted == 0: Placement.Prefix else: Placement.Apart
      spacing.edits = @[Edit(first: t.after, after: next.first, spaces: wanted)]
      var last = k + 1  # Echo through operand that operator run after gap opens.
      while tokens[last].kind == TokenKind.Operator and last < lasts.high and
          tokens[last + 1].line == lasts[last]:
        inc last
      spacing.got = source[t.first ..< tokens[last].after].runeSubStr(0, 2 * EXCERPT_RUNES)
      result.add spacing
      continue
    if tokens.isExportMarker(k, lasts, source):
      let is_operand_next = not is_line_end and tokens[k + 1].first == t.after and
        tokens[k + 1].kind in {TokenKind.Word, TokenKind.Number, TokenKind.Text,
                               TokenKind.Character, TokenKind.Quoted}
      if not is_operand_next: continue

    # Space binary operator one each side, and glue range unless it stands apart, and power unless
    #   glued tokens merge; one ending its line takes one before.
    let (is_range, is_power) = (text in RANGE_OPERATORS, text == POWER_OPERATOR)
    if is_line_end:
      if left == 1: continue
      spacing.placement = if is_range or is_power: Placement.Ending else: Placement.Binary
      spacing.edits = @[Edit(first: before.after, after: t.first, spaces: 1)]
      spacing.got = source.excerpt(before, t)
      result.add spacing
      continue
    let
      next = tokens[k + 1]
      right = next.first - t.after
    if (left == 0) != (right == 0): continue
    var wanted = 1
    spacing.placement = Placement.Binary
    if selected[k] and not is_keyword_operator:
      if source.isMerging([before, t, next]): spacing.placement = Placement.SelectorApart
      else: (wanted, spacing.placement) = (0, Placement.Selector)
    elif is_range:
      if source.isMerging([before, t, next]) or tokens.isRangeApart(partners, k, source):
        spacing.placement = Placement.RangeApart
      else: (wanted, spacing.placement) = (0, Placement.Range)
    elif is_power:
      if source.isMerging([before, t, next]): spacing.placement = Placement.PowerApart
      else: (wanted, spacing.placement) = (0, Placement.Power)
    if left == wanted and right == wanted: continue
    spacing.edits = source.around(tokens, k, wanted)
    spacing.got = source.excerpt(before, next)
    result.add spacing


func checkSpacing*(path, source: string): seq[Report] =
  ## Report gap inside expression spaced against X.9 where its rewrite moves no reading.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for spacing in source.respacings:
    let message =
      case spacing.placement
      of Placement.Binary: "Binary operator takes one space on each side (X.9)"
      of Placement.Ending: "Operator ending its line takes one space before it (X.9)"
      of Placement.Range: "Range operator takes no space (X.9)"
      of Placement.RangeApart:
        "Range operator takes one space on each side where piece beside it binds tighter, or " &
          "where glued tokens would merge (X.9)"
      of Placement.Power:
        "Power operator takes no space, since spaced it reads as operator on bits (X.9)"
      of Placement.PowerApart:
        "Power operator takes one space on each side where glued tokens would merge (X.9)"
      of Placement.Selector:
        "Symbol operator inside bracket glued to operand takes no space (X.9)"
      of Placement.SelectorApart:
        "Symbol operator inside bracket glued to operand keeps one space on each side where " &
          "glued tokens would merge (X.9)"
      of Placement.Prefix: "Prefix operator is glued to its operand (X.9)"
      of Placement.Apart:
        "Prefix operator takes one space before operand it would merge with (X.9)"
      of Placement.Equals: "`=` takes one space on each side (X.9)"
      of Placement.Comma: "Comma takes no space before it and one after (X.9)"
      of Placement.Semicolon: "Semicolon takes no space before it and one after (X.9)"
      of Placement.Colon: "Colon takes no space before it and one after (X.9)"
      of Placement.Inner: "Bracket holds no space inside it (X.9)"
    result.add initReport(
      path,
      spacing.line + 1,
      Rule.ExpressionSpacing,
      message & "; got `" & spacing.got & "`.",
    )


func fixSpacing*(path, source: string; held: Held): Fix =
  ## Rewrite each gap check reports, unless its held line would then be wide.
  ##   Gap two rules read is rewritten once; rules agree on every such gap.
  let
    spacings = source.respacings
    starts = source.lineStarts
  var
    lines = source.split('\n')
    k = 0
  while k < spacings.len:
    # Rewrite every gap of one line from its end, so earlier offsets hold.
    var
      j = k
      edits: seq[Edit]
    while j < spacings.len and spacings[j].line == spacings[k].line:
      edits.add spacings[j].edits
      inc j
    let
      line = spacings[k].line
      start = starts[line]
    var
      shaped = lines[line]
      done = -1
    for e in edits.sortedByIt(-it.first):
      if e.first == done: continue
      shaped = shaped[0 ..< e.first - start] & ' '.repeat(e.spaces) & shaped[e.after - start .. ^1]
      done = e.first
    if not held.isHeld(line + 1) or not shaped.isWide or lines[line].isWide:
      lines[line] = shaped
      for m in k ..< j: result.fixed.add initReport(path, line + 1, Rule.ExpressionSpacing)
    k = j
  result.source = lines.join("\n")


func fixSpacing*(path, source: string): Fix =
  ## Rewrite each gap check reports, unless its line would then be wide.
  fixSpacing(path, source, EVERY)
