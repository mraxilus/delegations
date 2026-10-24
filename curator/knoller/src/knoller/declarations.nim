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
##   Checks and fixers share one reading (`movesDoc`, `defaults`), so each rule is written once
##     (Article II.1).
##   Missing doc (VI.1): every declaration takes doc, as `declared.nim` reads it, but local
##     binding, parameter and placeholder, which take none (Architect's ruling on review page
##     of repository issue 443). Names sharing one line share one doc, so line reports once.
##     Name inside value or signature of declaration above it is part of it, and takes none:
##     field of tuple in brackets, or parameter of proc type.
##     Doc anywhere rule of position reads passes: on declaration's line, whole line just above
##     at its indent, or whole line below it or below its value, one level in; place is rule of
##     position's. `TODO: Document.` passes; doc awaiting text under other TODO is fixed, and
##     that TODO moves above declaration as `#` comment, so no design note is lost.
##   Declaration runs to line closing each bracket it opens and each string past its line;
##     binding's value runs on through each line below it, deeper than it; routine's signature
##     runs past line ending in `:` and takes pragma line below it, until line ending in `=`.
##   Fix writes `TODO: Document.` where STYLE.md §5 puts doc: routine's on first line of body,
##     at its indent; value of several lines takes it on line after its last, one level in, as
##     every such doc of repository stands; other doc on declaration's line where it fits, else
##     next line, one level in, or at indent of body that line opens. Fix writes comments
##     alone, so every token outside them stays as written.
##     Value opening body, as `block:` or lambda, takes doc on first line of body, since doc
##       last in body would stand where its value is; body opening below first line of value
##       takes doc above declaration, at its indent.
##   One-line borrow or forward in run under one group comment passes, as VI.1 excepts it, and
##     so does declaration inside `quote do:`, which is generated code.
##
##   Cost: scanner, never parser (`tokens.nim`); declaration it cannot place surely stays.
##   Cost: literal with suffix (`0'u8`) and raw string keep their type, though it is exact.
##   Cost: enum members listed on one line are left out; whether each takes line and doc of its
##     own is open question of record.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, tables]
import ./[declared, form, reports, tokens, views]


type
  Shape {.pure.} = enum  ## Define move doc takes.
    Join  ## Next-line doc joins declaration's line.
    Split  ## Trailing doc widening line takes next line.
    Indent  ## Next-line doc that cannot join takes indent one level in.

  MoveDoc = object
    ## Define one doc to move: declaration line, shape, lines replacing declaration and doc.
    line: int  ## Zero-based line of declaration.
    shape: Shape  ## Move doc takes.
    last: int  ## Zero-based last line replaced: doc's line, or declaration's own.
    lines: seq[string]  ## Lines replacing declaration and doc.

  Default = object
    ## Define type to drop from parameter: byte span from name's end to `=`, and type read.
    line: int  ## Zero-based line of parameter.
    first: int  ## Byte offset after parameter's name.
    after: int  ## Byte offset of `=`.
    got: string  ## Parameter as written.

  Missing = object
    ## Define one declaration line taking no doc, or whose doc awaits text under other TODO.
    line: int  ## Zero-based line of declaration.
    last: int  ## Zero-based last line of declaration: routine's signature, else its value.
    is_routine: bool  ## Routine, whose doc opens its body.
    opening: int
      ## Zero-based line of value that opens body below it, as `block:`; `-1` where none.
    got: string  ## Kind and names, as finding echoes them.
    is_commented: bool  ## Line carries `#` comment, so doc cannot join it.
    doc: int  ## Zero-based line of doc holding other TODO; `-1` where declaration holds none.
    column: int  ## Byte offset of `##` of that doc on its line.
    todo: string  ## Text of that TODO, which moves above declaration.

  Reading = object  ## Define views of source rule of missing doc reads, line by line.
    lines: seq[string]  ## Lines as written.
    code: seq[string]  ## Lines with comments and literals blanked.
    kept: seq[string]  ## Lines with literals alone blanked.
    reached: seq[int]
      ## Last line that token running past each line's end reaches, as string of several lines;
      ##   line itself where none.
    ends: seq[string]  ## Spelling of last token of each line but comment; empty where none.


const
  KEYWORDS_SECTION = ["const", "let", "type", "var"]
    ## Keywords opening section whose lines declare.
  KEYWORDS_ROUTINE = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords declaring routine, whose doc keeps routine's own position.
  ROUTINES_DEFAULTED = ["converter", "func", "iterator", "method", "proc"]
    ## Keywords whose parameter without type takes type of its default.
  KEYWORDS_CONTINUING = [
    "and", "div", "in", "is", "isnot", "mod", "notin", "of", "or", "shl", "shr", "xor",
  ]
    ## Keyword operators line may end on, continuing expression on next line.
  STEP_INDENT = 2  ## Spaces one level indents (Article X.1).
  TEXT_TODO = "TODO: Document."  ## Doc awaiting honest text (Article VI.1).
  KINDS_DOCUMENTED = {
    KindName.Binding, KindName.Field, KindName.Member, KindName.Routine, KindName.Type,
  }
    ## Kinds whose declaration takes doc; parameter and placeholder take none.


func wordFirst(code: string): string =
  ## Read leading identifier of code line.
  let s = code.strip
  var k = 0
  while k < s.len and s[k] in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}: inc k
  s[0 ..< k]


func isDoc(code, kept: string): bool =
  ## Decide whether line holds `##` doc alone, never block doc.
  let text = kept.strip
  code.strip.len == 0 and text.startsWith("##") and not text.startsWith("##[")


func movesDoc(source: string): seq[MoveDoc] =
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
    let last = t.lineLast(source)
    if firsts[t.line] < 0 and (k == 0 or tokens[k - 1].lineLast(source) < t.line):
      firsts[t.line] = k
      depths[t.line] = depth
    if last > t.line:
      for line in t.line .. last: spanned[line] = true
    if t.kind != KindToken.Comment: lasts[last] = k
    if t.kind == KindToken.Open: inc depth
    elif t.kind == KindToken.Close: depth = max(depth - 1, 0)

  for d in 0 ..< lines.len:
    let first = firsts[d]
    if first < 0 or code[d].strip.len == 0 or spanned[d] or depths[d] > 0 or lasts[d] < 0:
      continue
    let
      word = code[d].wordFirst
      stripped = code[d].strip
      ending = tokens[lasts[d]]
      text_ending = ending.spelling(source)
    if word in KEYWORDS_ROUTINE or stripped in KEYWORDS_SECTION or stripped.startsWith("{"):
      continue
    if ending.kind in {KindToken.Open, KindToken.Comma, KindToken.Operator} or
        text_ending in KEYWORDS_CONTINUING:
      continue
    if first > 0:
      var previous = first - 1
      while previous > 0 and tokens[previous].kind == KindToken.Comment: dec previous
      let before = tokens[previous]
      if before.kind in {KindToken.Open, KindToken.Comma} or
          (before.kind == KindToken.Operator and before.spelling(source) != ":") or
          before.spelling(source) in KEYWORDS_CONTINUING:
        continue

    # Declaration context: section keyword on line, or above it through enclosing lines.
    var
      is_declared = word in KEYWORDS_SECTION
      parent = d
    while not is_declared and code[parent].indentWidth > 0:
      let indent = code[parent].indentWidth
      dec parent
      while parent >= 0 and (code[parent].strip.len == 0 or code[parent].indentWidth >= indent):
        dec parent
      if parent < 0 or code[parent].wordFirst in KEYWORDS_ROUTINE: break
      is_declared = code[parent].wordFirst in KEYWORDS_SECTION
    if not is_declared: continue

    # Count doc lines below at deeper indent; read trailing comment on declaration's line.
    let indent = lines[d].indentWidth
    var below = d + 1
    while below < lines.len and isDoc(code[below], kept[below]) and
        lines[below].indentWidth > indent:
      inc below
    let
      docs = below - d - 1
      marker = kept[d].find('#', code[d].strip(leading = false).len)
      inner = ' '.repeat(indent + STEP_INDENT)
    if marker < 0 and docs == 1:
      let
        doc = lines[d + 1].strip
        joined = lines[d] & ' '.repeat(GAP_COMMENT) & doc
      if not joined.isWide:
        result.add MoveDoc(line: d, shape: Shape.Join, last: d + 1, lines: @[joined])
      elif lines[d + 1].indentWidth != indent + STEP_INDENT:
        let shaped = @[lines[d], inner & doc]
        result.add MoveDoc(line: d, shape: Shape.Indent, last: d + 1, lines: shaped)
    elif marker >= 0 and docs == 0 and kept[d][marker .. ^1].startsWith("##") and
        lines[d].isWide:
      let declared = lines[d][0 ..< marker].strip(leading = false)
      if declared.isWide: continue
      result.add MoveDoc(
        line: d,
        shape: Shape.Split,
        last: d,
        lines: @[declared, inner & lines[d][marker .. ^1]],
      )


func checkDocs*(path, source: string): seq[Report] =
  ## Report one-line doc of type, field, binding or enum member out of its position.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for move in source.movesDoc:
    let message =
      case move.shape
      of Shape.Join:
        "One-line doc stands on its declaration's line where it fits; got it on next line."
      of Shape.Split:
        "Doc widening its line past `" & $LINE_MAX & "` takes next line; got it on " &
          "declaration's line."
      of Shape.Indent: "Doc on next line stands one level in; got indent `" &
        $source.split('\n')[move.line + 1].indentWidth & "`."
    result.add initReport(path, move.line + 1, Rule.PositionDoc, message)


func fixDocs*(path, source: string): Fix =
  ## Move each doc check reports, last first; each new line traces to line it replaced.
  let moves = source.movesDoc
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for move in moves.reversed:
    let traced = toSeq(0 ..< move.lines.len).mapIt(origin[min(move.line + it, move.last)])
    lines = lines[0 ..< move.line] & move.lines & lines[move.last + 1 .. ^1]
    origin = origin[0 ..< move.line] & traced & origin[move.last + 1 .. ^1]
  result.source = lines.join("\n")
  for move in moves: result.fixed.add initReport(path, move.line + 1, Rule.PositionDoc)
  if moves.len > 0: result.origin = origin


func keywordSection(code: seq[string], d: int): string =
  ## Read keyword of section binding at line `d` stands in: on its own line, else above it.
  if code[d].wordFirst in KEYWORDS_SECTION: return code[d].wordFirst
  var indent = code[d].indentWidth
  for k in countdown(d - 1, 0):
    if code[k].strip.len == 0 or code[k].indentWidth >= indent: continue
    if code[k].wordFirst in KEYWORDS_SECTION: return code[k].wordFirst
    indent = code[k].indentWidth
  ""


func linesQuoted(code: seq[string]): seq[bool] =
  ## Mark each line inside `quote do:` block, whose declarations are generated code.
  result = newSeq[bool](code.len)
  var indent = -1
  for d, line in code:
    let s = line.strip
    if s.len == 0 or (indent >= 0 and line.indentWidth > indent):
      result[d] = indent >= 0
      continue
    indent = if s.endsWith(" do:") and "quote" in s.wordsCode: line.indentWidth else: -1


func initReading(source: string): Reading =
  ## Construct views of source, each split into its lines.
  var starts = @[0]
  for k, c in source:
    if c == '\n': starts.add k + 1
  result = Reading(
    lines: source.split('\n'),
    code: source.codeOnly.split('\n'),
    kept: source.codeAndComments.split('\n'),
    reached: toSeq(0..<starts.len),
    ends: newSeq[string](starts.len),
  )
  for t in source.tokens:
    let last = starts.upperBound(t.after - 1) - 1
    for line in t.line..<last: result.reached[line] = max(result.reached[line], last)
    if t.kind == KindToken.Comment: continue
    for line in t.line..last: result.ends[line] = t.spelling(source)


func isContent(r: Reading, j: int): bool =
  ## Decide whether line `j` is content: code or literal, so neither blank nor comment alone.
  r.code[j].strip.len > 0 or (r.lines[j].strip.len > 0 and r.kept[j].strip.len == 0)


func lastDeclaration(r: Reading, d: int, kind: KindName): int =
  ## Find last line of declaration opening at `d`: line closing each bracket it opens and each
  ##   string running past its line. Routine's signature runs past line ending in `:`, whose
  ##   return type stands below, and takes pragma block standing on its own line below it;
  ##   line ending in `=` opens body, so signature ends there.
  ##   Binding's value runs on each line below it that is content, deeper than it.
  var depth = 0
  result = d
  while result + 1 < r.code.len:
    for c in r.code[result]:
      if c in {'(', '[', '{'}: inc depth
      elif c in {')', ']', '}'}: dec depth
    let below = result + 1
    var is_open = depth > 0 or r.reached[result] > result
    case kind
    of KindName.Routine:
      let is_continued = r.ends[result] == ":" or r.code[below].strip.startsWith("{.")
      is_open = is_open or (is_continued and r.ends[result] != "=")
    of KindName.Binding:
      is_open = is_open or
          (r.isContent(below) and r.lines[below].indentWidth > r.lines[d].indentWidth)
    else: discard
    if not is_open: return
    result = below


func lineOpening(r: Reading; d, last: int): int =
  ## Find line of value from `d` to `last` that opens body below it, outside brackets: line
  ##   ending in `:`, as `block:`, or in `=` after routine keyword, as lambda's; `-1` where none.
  var depth = 0
  for j in d..<last:
    for c in r.code[j]:
      if c in {'(', '[', '{'}: inc depth
      elif c in {')', ']', '}'}: dec depth
    let is_lambda = r.ends[j] == "=" and r.code[j].wordsCode.anyIt(it in KEYWORDS_ROUTINE)
    if depth <= 0 and (r.ends[j] == ":" or is_lambda): return j
  -1


func isOneLine(r: Reading, d: int): bool =
  ## Decide whether routine opening at `d` stands on its line alone, no body below it.
  if r.code[d].wordFirst notin KEYWORDS_ROUTINE or r.lastDeclaration(d, KindName.Routine) != d:
    return false
  var below = d + 1
  while below < r.code.len and r.code[below].strip.len == 0: inc below
  below >= r.code.len or r.code[below].indentWidth <= r.code[d].indentWidth


func isDelegationStacked(r: Reading, d: int): bool =
  ## Decide whether routine at `d` is one-line delegation in run under one group comment, as VI.1
  ##   excepts: run of one-line routines at one indent, whose first line follows `#` comment.
  if not r.isOneLine(d): return false
  var first = d
  while first > 0 and r.isOneLine(first - 1) and
      r.code[first-1].indentWidth == r.code[d].indentWidth:
    dec first
  if first == 0: return false
  let above = r.kept[first-1].strip
  r.code[first-1].strip.len == 0 and above.startsWith("#") and not above.startsWith("##") and
      not above.startsWith("#[") and r.kept[first-1].indentWidth == r.code[d].indentWidth


func marker(code, kept: seq[string]; d: int): int =
  ## Find byte offset of `#` comment trailing code of line `d`; `-1` where none.
  kept[d].find('#', code[d].strip(leading = false).len)


func lineDoc(lines, code, kept: seq[string]; d, last: int): int =
  ## Find line of doc of declaration opening at `d` and closing at `last`: trailing on either,
  ##   whole line just above at its indent, or whole line below either, one level in or deeper;
  ##   `-1` where none. Place among these is rule of position's (`movesDoc`).
  let indent = lines[d].indentWidth
  for line in [d, last]:
    let at = marker(code, kept, line)
    if at >= 0 and kept[line][at .. ^1].startsWith("##"): return line
  if d > 0 and isDoc(code[d-1], kept[d-1]) and lines[d-1].indentWidth == indent:
    return d - 1
  for line in [d + 1, last + 1]:
    if line < lines.len and isDoc(code[line], kept[line]) and lines[line].indentWidth > indent:
      return line
  -1


func docsMissing(source: string): seq[Missing] =
  ## Find each declaration line taking no doc, or whose doc awaits text under other TODO (VI.1).
  ##   Kinds and places follow header; members sharing one line are left out, and so is name
  ##   inside value or signature of declaration above it, as field of tuple in brackets.
  let
    r = source.initReading
    quoted = r.code.linesQuoted
  var named: OrderedTable[int, seq[Declared]]
  for item in source.declarations:
    if item.kind notin KINDS_DOCUMENTED: continue
    if item.kind == KindName.Binding and item.reach != Reach.Global: continue
    named.mgetOrPut(item.line - 1, @[]).add item

  # Judge each line once, by kind of its first name, in order of lines.
  var covered = -1
  for d in named.keys.toSeq.sorted:
    let
      items = named[d]
      kind = items[0].kind
    if d >= r.lines.len or d <= covered or quoted[d]: continue
    if kind == KindName.Member and items.len > 1: continue
    if kind == KindName.Routine and r.isDelegationStacked(d): continue
    let
      last = r.lastDeclaration(d, kind)
      doc = lineDoc(r.lines, r.code, r.kept, d, last)
      at = marker(r.code, r.kept, d)
      word =
        case kind
        of KindName.Binding: r.code.keywordSection(d)
        of KindName.Routine: items[0].keyword
        of KindName.Type: "type"
        of KindName.Field: "field"
        else: "member"
    covered = last
    var missing = Missing(
      line: d,
      last: last,
      is_routine: kind == KindName.Routine,
      opening: if kind == KindName.Routine: -1 else: r.lineOpening(d, last),
      got: (word & " " & items.mapIt(it.name).join(", ")).strip,
      is_commented: at >= 0,
      doc: -1,
    )
    if doc < 0:
      result.add missing
      continue

    # Doc stands; it awaits text where its summary is TODO other than `TODO: Document.`.
    let
      column =
        if doc == d or doc == last: marker(r.code, r.kept, doc) else: r.kept[doc].find("##")
      text = r.kept[doc][column+2 .. ^1].strip
    if not text.startsWith("TODO") or text == TEXT_TODO: continue
    missing.doc = doc
    missing.column = column
    missing.todo = text
    result.add missing


func checkDocsMissing*(path, source: string): seq[Report] =
  ## Report declaration taking no doc, and doc awaiting text under other TODO (VI.1).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for m in source.docsMissing:
    let message =
      if m.doc >= 0: "Doc awaiting text reads `" & TEXT_TODO & "` alone; got `## " & m.todo & "`."
      else: "Declaration takes doc comment; got `" & m.got & "`."
    result.add initReport(path, m.line + 1, Rule.DocMissing, message)


func fixDocsMissing*(path, source: string): Fix =
  ## Write `TODO: Document.` doc for each declaration check reports, last first; other TODO of
  ##   doc moves above declaration as `#` comment. Each new line traces to declaration's line.
  let found = source.docsMissing
  var
    lines = source.split('\n')
    origin = toSeq(1..lines.len)

  template insert(at: int, line: string, traced: int) =
    ## Insert line at `at`, tracing it to line `traced` of source.
    lines.insert(line, at)
    origin.insert(traced, at)

  func indentBelow(lines: seq[string]; at, indent: int): int =
    ## Count indent of doc line written at `at` for declaration at `indent`: that of first line
    ##   below with text, where deeper, so doc stands in body it opens; else one level in.
    var k = at
    while k < lines.len and lines[k].strip.len == 0: inc k
    if k < lines.len and lines[k].indentWidth > indent: lines[k].indentWidth
    else: indent + STEP_INDENT

  for m in found.reversed:
    let
      indent = lines[m.line].indentWidth
      joined = lines[m.line] & ' '.repeat(GAP_COMMENT) & "## " & TEXT_TODO
      traced = origin[m.line]
    if m.doc >= 0:
      lines[m.doc] = lines[m.doc][0..<m.column] & "## " & TEXT_TODO
      insert(min(m.line, m.doc), ' '.repeat(indent) & "# " & m.todo, traced)
    elif m.opening > m.line: insert(m.line, ' '.repeat(indent) & "## " & TEXT_TODO, traced)
    elif m.opening == m.line:
      let below = lines.indentBelow(m.line + 1, indent)
      insert(m.line + 1, ' '.repeat(below) & "## " & TEXT_TODO, traced)
    elif m.is_routine or m.last > m.line or m.is_commented or joined.isWide:
      let below = lines.indentBelow(m.last + 1, indent)
      insert(m.last + 1, ' '.repeat(below) & "## " & TEXT_TODO, traced)
    else: lines[m.line] = joined
  result.source = lines.join("\n")
  for m in found: result.fixed.add initReport(path, m.line + 1, Rule.DocMissing)
  if found.len > 0: result.origin = origin


func typeLiteral(tokens: openArray[Token]; a, b: int; source: string): string =
  ## Read type literal default of tokens `a` to `b` gives exactly; empty where none, or not one.
  if a != b: return
  let
    t = tokens[a]
    text = t.spelling(source)
  case t.kind
  of KindToken.Number:
    if '\'' in text: return
    let digits = text.strip(chars = {'-'})
    if digits.len > 1 and digits[0] == '0' and digits[1] in {'x', 'X', 'o', 'O', 'b', 'B'}:
      return "int"
    if '.' in text or 'e' in text or 'E' in text: "float" else: "int"
  of KindToken.Text:
    if a > 0 and tokens[a - 1].after == t.first and tokens[a - 1].kind == KindToken.Word: ""
    else: "string"
  of KindToken.Character: "char"
  of KindToken.Word:
    if text in ["true", "false"]: "bool" else: ""
  else: ""


func defaults(source: string): seq[Default] =
  ## Find each parameter whose literal default gives exactly type it states.
  let
    tokens = source.tokens
    partners = tokens.partners
  for o, t in tokens:
    let keyword = tokens.signature(partners, o, source)
    if keyword < 0 or partners[o] < o: continue
    if tokens[keyword].spelling(source) notin ROUTINES_DEFAULTED: continue

    # Split parameters at separators outside nested brackets.
    var k = o + 1
    while k < partners[o]:
      let first = k
      var (colon, equals) = (-1, -1)
      while k < partners[o] and tokens[k].kind notin {KindToken.Comma, KindToken.Semicolon}:
        let text = tokens[k].spelling(source)
        if text == ":" and colon < 0: colon = k
        elif text == "=" and equals < 0: equals = k
        if tokens[k].kind == KindToken.Open and partners[k] > k: k = partners[k]
        inc k
      let last = k - 1
      inc k
      if colon <= first or equals < colon + 2 or equals >= last: continue
      if (first .. last).toSeq.anyIt(tokens[it].kind == KindToken.Comment): continue
      let
        declared = source[tokens[colon + 1].first ..< tokens[equals - 1].after]
        value = source[tokens[equals + 1].first ..< tokens[last].after]
        literal = typeLiteral(tokens, equals + 1, last, source)
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
      Rule.DefaultLiteral,
      "Parameter states its type only where default does not fix it; got `" & d.got & "`.",
    )


func fixDefaults*(path, source: string): Fix =
  ## Drop type of each parameter check reports, last first, so earlier offsets hold.
  let found = source.defaults
  result.source = source
  for d in found.reversed:
    result.source = result.source[0 ..< d.first] & " " & result.source[d.after .. ^1]
  for d in found: result.fixed.add initReport(path, d.line + 1, Rule.DefaultLiteral)
