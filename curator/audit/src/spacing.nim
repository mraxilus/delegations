## Enforce spaces inside Nim expressions (Article X.9), and fix them (`koch fix`).
##   Spaces are list X.9 gives; every gap list names takes its count:
##   - binary operator and `=` take one space on each side; one ending its line takes one before;
##   - range operator (`..`, `..<`, `..^`) is binary operator, spaced alike;
##   - prefix operator is glued to its operand;
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
##   Range spaces as binary operator, so every binary operator reads alike (Architect, X.9).
##     Glued `1..^1` lexes one operator `..^`, so fix writes `1 ..^ 1`, which `system` defines
##     as `1 .. ^1`; there `^` is prefix, glued to operand. Range in prefix place (`a[.. 2]`)
##     stays unread.
##   Prefix place: operator after anything but operand, which is where parser reads prefix
##     node; spaces after it go, unless `-` meets number, since `- 1` glued is literal `-1`,
##     which `-128'i8` shows differs.
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
##   Cost: fix spaces token lexer read, never splits it, so `1..^1` becomes `1 ..^ 1`, not
##     `1 .. ^1` X.9 shows; split is hand's choice.
##   Cost: fixer never writes line width check reports: spacing that would widen line past
##     `LINE_MAX` stays, finding and all.

{.experimental: "strictFuncs".}

import std/[algorithm, sets, strutils, unicode]
import ../../knoller/src/knoller
import ./[findings, form, names]


type
  Placement {.pure.} = enum  ## Define which rule of X.9 gap falls under, which decides its spaces.
    Binary  ## Around binary operator: one space each side.
    Range  ## Around range operator: one space each side, as binary.
    Prefix  ## After prefix operator: none.
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
  RANGE_OPERATORS = ["..", "..<", "..^"]  ## Range operators, spaced as binary.
  IGNORED_OPERATORS = ["::", ":", "."]
    ## Operator tokens of type, field and access, never spaced as operators.
  STATEMENT_KEYWORDS = ["export", "from", "import", "include"]
    ## Keywords opening statement whose operators spell module paths.
  DECLARATION_KEYWORDS = [
    "const", "converter", "func", "iterator", "let", "macro", "method", "proc", "template", "type",
    "using", "var",
  ]
    ## Keywords whose next name declares, so `*` glued after it marks export.
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


func respacings(source: string): seq[Respacing] =
  ## Find each gap breaking X.9 list whose rewrite moves no reading.
  let
    tokens = source.tokens
    partners = tokens.partners
    skipped = tokens.pathTokens(partners, source)
  var lasts = newSeq[int](tokens.len)
  for k, t in tokens: lasts[k] = t.lastLine(source)
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
      # Glue prefix operator to its operand.
      if is_keyword_operator or is_line_end or text in RANGE_OPERATORS: continue
      let next = tokens[k + 1]
      if next.first == t.after or next.isKeyword(source): continue
      if text == "-" and next.kind == TokenKind.Number: continue
      spacing.placement = Placement.Prefix
      spacing.edits = @[Edit(first: t.after, after: next.first, spaces: 0)]
      spacing.got = source[t.first ..< next.after].runeSubStr(0, 2 * EXCERPT_RUNES)
      result.add spacing
      continue
    if tokens.isExportMarker(k, lasts, source):
      let is_operand_next = not is_line_end and tokens[k + 1].first == t.after and
        tokens[k + 1].kind in {TokenKind.Word, TokenKind.Number, TokenKind.Text,
                               TokenKind.Character, TokenKind.Quoted}
      if not is_operand_next: continue

    # Space binary operator, range among them, one each side; one ending its line, one before.
    spacing.placement = if text in RANGE_OPERATORS: Placement.Range else: Placement.Binary
    if is_line_end:
      if left == 1: continue
      spacing.edits = @[Edit(first: before.after, after: t.first, spaces: 1)]
      spacing.got = source.excerpt(before, t)
      result.add spacing
      continue
    let
      next = tokens[k + 1]
      right = next.first - t.after
    if (left == 0) != (right == 0) or (left == 1 and right == 1): continue
    spacing.edits = source.around(tokens, k, 1)
    spacing.got = source.excerpt(before, next)
    result.add spacing


func checkSpacing*(path, source: string): seq[Report] =
  ## Report gap inside expression spaced against X.9 where its rewrite moves no reading.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for spacing in source.respacings:
    let message =
      case spacing.placement
      of Placement.Binary: "Binary operator takes one space on each side (X.9)"
      of Placement.Range: "Range operator takes one space on each side (X.9)"
      of Placement.Prefix: "Prefix operator is glued to its operand (X.9)"
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


func fixSpacing*(path, source: string): Fix =
  ## Rewrite each gap check reports, unless its line would then be wide.
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
    if not shaped.isWide or lines[line].isWide:
      lines[line] = shaped
      for m in k ..< j: result.fixed.add initReport(path, line + 1, Rule.ExpressionSpacing)
    k = j
  result.source = lines.join("\n")
