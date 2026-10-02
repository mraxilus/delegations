## Enforce spacing of operators in Nim source (Article X.9), and fix it (`koch fix`).
##   Binary operator, range operators `..`, `..<` and `..^` among them, takes one space on each
##     side; prefix operator is glued to its operand; `=` of named argument takes one space on
##     each side, as X.3 and V.4 spell `name = value`.
##   Reads tokens (`tokens.nim`), so string, character, comment and quoted name never trip it.
##   Binary place: operator after operand (`isOperandEnd`), never first token of its line, since
##     compiler reads operator opening line as no binary one. Keyword operators (`and`, `div`,
##     `in`, …) count; `not` and `as` never stand binary.
##   Lexer reads whether space stands before operator and whether one stands after, never how
##     many; space before and none after reads prefix (`isUnary`), so `a -b` is call `a(-b)`.
##     Rule therefore rewrites only spacing whose reading cannot move: spaces on both sides or
##     on neither (`a+b`, `a  + b`), and operator ending its line, which lexer marks end and
##     never prefix. `a -b` and `a- b` stay, and check reports neither.
##   Prefix place: operator after anything but operand; spaces after it go, unless `-` meets
##     number, since `- 1` glued is literal `-1`, which `-128'i8` shows differs.
##   `=` of named argument: lexer reads `=` as no operator, so any spacing of it moves nothing.
##     Architect's choice to make: X.3 example spells `symbols = "∧"` and V.4 `as_weight = true`,
##     and tree spells every named argument so, so rule holds that form.
##   Never read: `=` of definition, default or assignment, which X.9 leaves to its statement;
##     `:` and `::` of type and field; `.` and dot-like operators (`.?`), glued as field access;
##     operators of `import`, `include`, `from` and `export`, whose `/` and `..` spell paths;
##     `*` glued after name and before anything but operand, i.e. export marker.
##
##   Cost: `a*(b)` reads as `f*(x: int)` does, so glued `*` before bracket stays.
##   Cost: asymmetric spacing stays, and reading holds it; its fix is choice of meaning.
##   Cost: fixer never writes line width check reports: spacing that would widen line past
##     `LINE_MAX` stays, finding and all.

{.experimental: "strictFuncs".}

import std/[algorithm, sets, strutils, unicode]
import ./[findings, form, names, tokens]


type
  Placement {.pure.} = enum
    ## Define where operator stands, which decides its spacing.
    Binary  ## After operand: one space each side.
    Prefix  ## After anything else: glued to operand.
    Named  ## `=` of named argument: one space each side.

  Edit = object
    ## Define one gap of source to rewrite: byte span and spaces it takes.
    first: int  ## Byte offset gap opens at.
    after: int  ## Byte offset after gap.
    spaces: int  ## Spaces gap takes.

  Respacing = object
    ## Define one operator breaking rule: line, gaps to rewrite, excerpt to echo.
    placement: Placement
    line: int  ## Zero-based line of operator.
    edits: seq[Edit]
    got: string  ## Operator with its neighbours, as written.


const
  KEYWORD_OPERATORS = [
    "and", "div", "in", "is", "isnot", "mod", "notin", "of", "or", "shl", "shr", "xor",
  ]
    ## Keywords lexer reads as binary operators (`isOperator`); `not` and `as` stand otherwise.
  IGNORED_OPERATORS = ["::", ":", "."]
    ## Operator tokens of type, field and access, never spaced as operators.
  STATEMENT_KEYWORDS = ["export", "from", "import", "include"]
    ## Keywords opening statement whose operators spell module paths.
  EXCERPT_RUNES = 12
    ## Runes of each neighbour echoed beside operator.


func pathTokens(tokens: openArray[Token], partners: openArray[int], source: string): HashSet[int] =
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


func excerpt(source: string; before, after: Token): string =
  ## Echo what stands between two tokens, operator and its gaps, with few runes of each.
  let
    left = source[before.first ..< before.after].runeSubStr(-EXCERPT_RUNES)
    right = source[after.first ..< after.after].runeSubStr(0, EXCERPT_RUNES)
  left & source[before.after ..< after.first] & right


func respacings(source: string): seq[Respacing] =
  ## Find each operator whose spacing breaks rule and whose rewrite moves no reading.
  let
    tokens = source.tokens
    partners = tokens.partners
    skipped = tokens.pathTokens(partners, source)
  var
    lasts = newSeq[int](tokens.len)
    enclosing = newSeq[int](tokens.len)
    opened: seq[int]
  for k, t in tokens:
    lasts[k] = t.lastLine(source)
    enclosing[k] = if opened.len > 0: opened[^1] else: -1
    if t.kind == TokenKind.Open: opened.add k
    elif t.kind == TokenKind.Close and opened.len > 0: discard opened.pop
  for k, t in tokens:
    if k == 0 or k in skipped or lasts[k - 1] < t.line: continue
    if tokens[k - 1].kind == TokenKind.Comment: continue
    let
      text = t.spelling(source)
      is_line_end = k == tokens.high or tokens[k + 1].line > lasts[k] or
        tokens[k + 1].kind == TokenKind.Comment
      before = tokens[k - 1]
      left = t.first - before.after
      is_keyword_operator = t.kind == TokenKind.Word and text in KEYWORD_OPERATORS
    if t.kind != TokenKind.Operator and not is_keyword_operator: continue
    var spacing = Respacing(line: t.line)

    # Name `=` of named argument: name opens argument of call.
    if text == "=":
      let o = enclosing[k]
      if is_line_end or k < 2 or o < 0 or before.kind != TokenKind.Word: continue
      if not tokens.isCallOpen(partners, o, source): continue
      if tokens[k - 2].kind != TokenKind.Comma and k - 2 != o: continue
      let right = tokens[k + 1].first - t.after
      if left == 1 and right == 1: continue
      spacing.placement = Placement.Named
      spacing.edits = @[
        Edit(first: before.after, after: t.first, spaces: 1),
        Edit(first: t.after, after: tokens[k + 1].first, spaces: 1),
      ]
      spacing.got = source.excerpt(before, tokens[k + 1])
      result.add spacing
      continue
    if text in IGNORED_OPERATORS or (text.len > 1 and text[0] == '.' and text[1] != '.'):
      continue

    # Space binary operator one each side, where both or neither side holds space.
    if tokens.isOperandEnd(k - 1, source):
      if text == "*" and left == 0 and before.kind in {TokenKind.Word, TokenKind.Quoted}:
        let is_operand_next = not is_line_end and tokens[k + 1].first == t.after and
          tokens[k + 1].kind in {TokenKind.Word, TokenKind.Number, TokenKind.Text,
                                 TokenKind.Character, TokenKind.Quoted}
        if not is_operand_next: continue
      spacing.placement = Placement.Binary
      if is_line_end:
        if left == 1: continue
        spacing.edits = @[Edit(first: before.after, after: t.first, spaces: 1)]
        spacing.got = source.excerpt(before, t)
      else:
        let right = tokens[k + 1].first - t.after
        if (left == 0) != (right == 0) or (left == 1 and right == 1): continue
        spacing.edits = @[
          Edit(first: before.after, after: t.first, spaces: 1),
          Edit(first: t.after, after: tokens[k + 1].first, spaces: 1),
        ]
        spacing.got = source.excerpt(before, tokens[k + 1])
      result.add spacing
      continue

    # Glue prefix operator to its operand.
    if is_keyword_operator or is_line_end: continue
    let next = tokens[k + 1]
    if next.first == t.after or next.isKeyword(source): continue
    if text == "-" and next.kind == TokenKind.Number: continue
    spacing.placement = Placement.Prefix
    spacing.edits = @[Edit(first: t.after, after: next.first, spaces: 0)]
    spacing.got = source[t.first ..< next.after].runeSubStr(0, 2 * EXCERPT_RUNES)
    result.add spacing


func checkSpacing*(path, source: string): seq[Finding] =
  ## Report operator spaced against X.9 where its rewrite moves no reading.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for spacing in source.respacings:
    let message =
      case spacing.placement
      of Placement.Binary: "Binary operator takes one space on each side (X.9)"
      of Placement.Prefix: "Prefix operator is glued to its operand (X.9)"
      of Placement.Named: "Named argument takes one space on each side of `=` (X.9, X.3)"
    result.add finding(path, spacing.line + 1, message & "; got `" & spacing.got & "`.")


func fixSpacing*(path, source: string): Fix =
  ## Rewrite spacing of each operator check reports, unless its line would then be wide.
  let
    spacings = source.respacings
    starts = source.lineStarts
  var
    lines = source.split('\n')
    k = 0
  while k < spacings.len:
    # Rewrite every gap of one line from its end, so earlier offsets hold.
    var j = k
    while j + 1 < spacings.len and spacings[j + 1].line == spacings[k].line: inc j
    let
      line = spacings[k].line
      start = starts[line]
    var shaped = lines[line]
    for m in countdown(j, k):
      for e in spacings[m].edits.reversed:
        shaped = shaped[0 ..< e.first - start] & ' '.repeat(e.spaces) &
          shaped[e.after - start .. ^1]
    if not shaped.isWide or lines[line].isWide:
      lines[line] = shaped
      for m in k .. j: result.fixed.add finding(path, line + 1, "operator spacing (X.9) fixed")
    k = j + 1
  result.source = lines.join("\n")
