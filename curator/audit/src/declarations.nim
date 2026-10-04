## Enforce where declaration states its doc and its type (Article VI.9, X.12; STYLE.md §5), and
##   fix it (`koch fix`).
##   Doc of type, field, binding and enum member: one-line doc stands on declaration's own
##     line, two spaces before `##`, where joined line fits `LINE_MAX`; otherwise on next line,
##     one level in. Doc of two or more lines stays where it is.
##   Declaration is line of code inside `type`, `const`, `let` or `var` section, at any depth of
##     object, enum or branch, or such keyword's own line holding one declaration. Line that
##     continues expression, opens block, ends in bracket left open, or carries `#` comment is
##     none, and routine's doc keeps its own position.
##   Default of parameter (X.12): type goes where literal default gives exactly that type:
##     `int` of integer literal, `float` of float literal, `bool` of `true` or `false`, `string`
##     of string literal, `char` of character literal; `T` of `default(T)`, and `Option[T]` of
##     `none(T)`. `float = 0`, `cfloat = 0.0`, `HalfTurns = 0` and named constant stay, since
##     there literal fixes another type, or none.
##   Default read in routine, routine type and lambda; template and macro stay, since their
##     parameter without type reads otherwise.
##   Checks and fixers share one reading (`docMoves`, `defaults`), so each rule is written once
##     (Article II.1).
##
##   Cost: scanner, never parser (`tokens.nim`); declaration it cannot place surely stays.
##   Cost: literal with suffix (`0'u8`) and raw string keep their type, though it is exact.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ../../knoller/src/knoller
import ./form


type
  Shape {.pure.} = enum  ## Define move doc takes.
    Join  ## Next-line doc joins declaration's line.
    Split  ## Trailing doc widening line takes next line.
    Indent  ## Next-line doc that cannot join takes indent one level in.

  DocMove = object
    ## Define one doc to move: declaration line, shape, lines replacing declaration and doc.
    line: int  ## Zero-based line of declaration.
    shape: Shape
    last: int  ## Zero-based last line replaced: doc's line, or declaration's own.
    lines: seq[string]

  Default = object
    ## Define type to drop from parameter: byte span from name's end to `=`, and type read.
    line: int  ## Zero-based line of parameter.
    first: int  ## Byte offset after parameter's name.
    after: int  ## Byte offset of `=`.
    got: string  ## Parameter as written.


const
  SECTION_KEYWORDS = ["const", "let", "type", "var"]
    ## Keywords opening section whose lines declare.
  ROUTINE_KEYWORDS = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords declaring routine, whose doc keeps routine's own position.
  DEFAULTED_ROUTINES = ["converter", "func", "iterator", "method", "proc"]
    ## Keywords whose parameter without type takes type of its default.
  CONTINUING_KEYWORDS = [
    "and", "div", "in", "is", "isnot", "mod", "notin", "of", "or", "shl", "shr", "xor",
  ]
    ## Keyword operators line may end on, continuing expression on next line.
  INDENT_STEP = 2  ## Spaces one level indents (Article X.1).


func firstWord(code: string): string =
  ## Read leading identifier of code line.
  let s = code.strip
  var k = 0
  while k < s.len and s[k] in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}: inc k
  s[0 ..< k]


func isDoc(code, kept: string): bool =
  ## Decide whether line holds `##` doc alone, never block doc.
  let text = kept.strip
  code.strip.len == 0 and text.startsWith("##") and not text.startsWith("##[")


func docMoves(source: string): seq[DocMove] =
  ## Find each one-line doc of declaration standing where rule puts it not.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')
    tokens = source.tokens
  var
    firsts = newSeqWith(lines.len, -1)  # First token of each line opening there.
    lasts = newSeqWith(lines.len, -1)  # Last code token ending on each line.
    depths = newSeq[int](lines.len)  # Brackets open before line's first token.
    spanned = newSeq[bool](lines.len)  # Line inside or opening token spanning lines.
    depth = 0
  for k, t in tokens:
    let last = t.lastLine(source)
    if firsts[t.line] < 0 and (k == 0 or tokens[k - 1].lastLine(source) < t.line):
      firsts[t.line] = k
      depths[t.line] = depth
    if last > t.line:
      for line in t.line .. last: spanned[line] = true
    if t.kind != TokenKind.Comment: lasts[last] = k
    if t.kind == TokenKind.Open: inc depth
    elif t.kind == TokenKind.Close: depth = max(depth - 1, 0)

  for d in 0 ..< lines.len:
    let first = firsts[d]
    if first < 0 or code[d].strip.len == 0 or spanned[d] or depths[d] > 0 or lasts[d] < 0:
      continue
    let
      word = code[d].firstWord
      stripped = code[d].strip
      ending = tokens[lasts[d]]
      ending_text = ending.spelling(source)
    if word in ROUTINE_KEYWORDS or stripped in SECTION_KEYWORDS or stripped.startsWith("{"):
      continue
    if ending.kind in {TokenKind.Open, TokenKind.Comma, TokenKind.Operator} or
        ending_text in CONTINUING_KEYWORDS:
      continue
    if first > 0:
      var previous = first - 1
      while previous > 0 and tokens[previous].kind == TokenKind.Comment: dec previous
      let before = tokens[previous]
      if before.kind in {TokenKind.Open, TokenKind.Comma} or
          (before.kind == TokenKind.Operator and before.spelling(source) != ":") or
          before.spelling(source) in CONTINUING_KEYWORDS:
        continue

    # Declaration context: section keyword on line, or above it through enclosing lines.
    var
      is_declared = word in SECTION_KEYWORDS
      parent = d
    while not is_declared and code[parent].indentOf > 0:
      let indent = code[parent].indentOf
      dec parent
      while parent >= 0 and (code[parent].strip.len == 0 or code[parent].indentOf >= indent):
        dec parent
      if parent < 0 or code[parent].firstWord in ROUTINE_KEYWORDS: break
      is_declared = code[parent].firstWord in SECTION_KEYWORDS
    if not is_declared: continue

    # Count doc lines below at deeper indent; read trailing comment on declaration's line.
    let indent = lines[d].indentOf
    var below = d + 1
    while below < lines.len and isDoc(code[below], kept[below]) and
        lines[below].indentOf > indent:
      inc below
    let
      docs = below - d - 1
      marker = kept[d].find('#', code[d].strip(leading = false).len)
      inner = ' '.repeat(indent + INDENT_STEP)
    if marker < 0 and docs == 1:
      let
        doc = lines[d + 1].strip
        joined = lines[d] & ' '.repeat(COMMENT_GAP) & doc
      if not joined.isWide:
        result.add DocMove(line: d, shape: Shape.Join, last: d + 1, lines: @[joined])
      elif lines[d + 1].indentOf != indent + INDENT_STEP:
        let shaped = @[lines[d], inner & doc]
        result.add DocMove(line: d, shape: Shape.Indent, last: d + 1, lines: shaped)
    elif marker >= 0 and docs == 0 and kept[d][marker .. ^1].startsWith("##") and
        lines[d].isWide:
      let declared = lines[d][0 ..< marker].strip(leading = false)
      if declared.isWide: continue
      result.add DocMove(
        line: d,
        shape: Shape.Split,
        last: d,
        lines: @[declared, inner & lines[d][marker .. ^1]],
      )


func checkDocs*(path, source: string): seq[Report] =
  ## Report one-line doc of type, field, binding or enum member out of its position.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for move in source.docMoves:
    let message =
      case move.shape
      of Shape.Join:
        "One-line doc stands on its declaration's line where it fits (STYLE.md §5); got it on " &
          "next line."
      of Shape.Split:
        "Doc widening its line past `" & $LINE_MAX & "` takes next line (STYLE.md §5); got it " &
          "on declaration's line."
      of Shape.Indent: "Doc on next line stands one level in (STYLE.md §5); got indent `" &
        $source.split('\n')[move.line + 1].indentOf & "`."
    result.add initReport(path, move.line + 1, Rule.DocPosition, message)


func fixDocs*(path, source: string): Fix =
  ## Move each doc check reports, last first; each new line traces to line it replaced.
  let moves = source.docMoves
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for move in moves.reversed:
    let traced = toSeq(0 ..< move.lines.len).mapIt(origin[min(move.line + it, move.last)])
    lines = lines[0 ..< move.line] & move.lines & lines[move.last + 1 .. ^1]
    origin = origin[0 ..< move.line] & traced & origin[move.last + 1 .. ^1]
  result.source = lines.join("\n")
  for move in moves: result.fixed.add initReport(path, move.line + 1, Rule.DocPosition)
  if moves.len > 0: result.origin = origin


func literalType(tokens: openArray[Token]; a, b: int; source: string): string =
  ## Read type literal default of tokens `a` to `b` gives exactly; empty where none, or not one.
  if a != b: return
  let
    t = tokens[a]
    text = t.spelling(source)
  case t.kind
  of TokenKind.Number:
    if '\'' in text: return
    let digits = text.strip(chars = {'-'})
    if digits.len > 1 and digits[0] == '0' and digits[1] in {'x', 'X', 'o', 'O', 'b', 'B'}:
      return "int"
    if '.' in text or 'e' in text or 'E' in text: "float" else: "int"
  of TokenKind.Text:
    if a > 0 and tokens[a - 1].after == t.first and tokens[a - 1].kind == TokenKind.Word: ""
    else: "string"
  of TokenKind.Character: "char"
  of TokenKind.Word:
    if text in ["true", "false"]: "bool" else: ""
  else: ""


func defaults(source: string): seq[Default] =
  ## Find each parameter whose literal default gives exactly type it states.
  let
    tokens = source.tokens
    partners = tokens.partners
  for o, t in tokens:
    let keyword = tokens.signatureOf(partners, o, source)
    if keyword < 0 or partners[o] < o: continue
    if tokens[keyword].spelling(source) notin DEFAULTED_ROUTINES: continue

    # Split parameters at separators outside nested brackets.
    var k = o + 1
    while k < partners[o]:
      let first = k
      var (colon, equals) = (-1, -1)
      while k < partners[o] and tokens[k].kind notin {TokenKind.Comma, TokenKind.Semicolon}:
        let text = tokens[k].spelling(source)
        if text == ":" and colon < 0: colon = k
        elif text == "=" and equals < 0: equals = k
        if tokens[k].kind == TokenKind.Open and partners[k] > k: k = partners[k]
        inc k
      let last = k - 1
      inc k
      if colon <= first or equals < colon + 2 or equals >= last: continue
      if (first .. last).toSeq.anyIt(tokens[it].kind == TokenKind.Comment): continue
      let
        declared = source[tokens[colon + 1].first ..< tokens[equals - 1].after]
        value = source[tokens[equals + 1].first ..< tokens[last].after]
        literal = literalType(tokens, equals + 1, last, source)
        callee = tokens[equals + 1].spelling(source)
        argument =
          if equals + 2 <= last and tokens[equals + 2].spelling(source) == "(" and
              partners[equals + 2] == last:
            source[tokens[equals + 3].first ..< tokens[last - 1].after]
          else: ""
        is_exact = (literal.len > 0 and declared == literal) or
          (callee == "default" and argument.len > 0 and declared == argument) or
          (callee == "none" and argument.len > 0 and declared == "Option[" & argument & "]")
      if not is_exact or value.len == 0: continue
      result.add Default(
        line: tokens[colon].line,
        first: tokens[colon - 1].after,
        after: tokens[equals].first,
        got: source[tokens[first].first ..< tokens[last].after],
      )


func checkDefaults*(path, source: string): seq[Report] =
  ## Report parameter stating type its literal default gives exactly (X.12).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for d in source.defaults:
    result.add initReport(
      path,
      d.line + 1,
      Rule.LiteralDefault,
      "Parameter states its type only where default does not fix it (X.12); got `" & d.got & "`.",
    )


func fixDefaults*(path, source: string): Fix =
  ## Drop type of each parameter check reports, last first, so earlier offsets hold.
  let found = source.defaults
  result.source = source
  for d in found.reversed:
    result.source = result.source[0 ..< d.first] & " " & result.source[d.after .. ^1]
  for d in found: result.fixed.add initReport(path, d.line + 1, Rule.LiteralDefault)
