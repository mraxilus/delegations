## Enforce that declaration carries doc (Article VI.1), and where it states its doc and its type
##   (VI.9, X.12; STYLE.md §5), and fix it (`koch fix`).
##   Missing doc: each declaration `declared.nim` reads takes doc, but parameter, generic
##     placeholder and local binding, which take none (VI.1). Names one line declares share one
##     doc, enum members it lists among them, so that line reports once. Name on line opening
##     inside bracket, as field of tuple type or parameter of routine type, is part of
##     expression, and takes none; routine declared there, as in `compiles(block: …)`, takes its
##     own. Doc counts where it trails declaration's line or last line of
##     its value or type, or opens line below either at deeper indent; routine's opens line below
##     signature. Value of binding runs on over each line of code below it at deeper indent, as
##     branch of `when`; line of enum members ends on itself, since `,` closing it opens next
##     member.
##   Fixer writes `## TODO: Document.` where doc position puts doc: joined to declaration's first
##     line where joined line fits and holds no comment, even where value runs on; else on next
##     line, one level in; routine's as first line of its body. Value or body opening string or
##     comment that spans lines takes doc where that closes, since doc on its first line would
##     stand inside string and change its value. So does value whose first line ends on `=` of
##     argument or `:` of field inside open bracket, after which Nim 2.2.12 parses no doc.
##   Doc holding other TODO holds design note (VIII.3), never text: fixer moves note above
##     declaration as `#` comment, and doc takes `## TODO: Document.`. Doc of several lines
##     opening with note stays for hand, since its outline may elaborate note or text.
##   Missing doc passes one-line borrow or forward stacked under group comment (VI.1), code
##     inside `quote do:`, whose generator carries docs through parameter, and doc on line above
##     at declaration's indent, which stands out of place rather than missing. Stack is run of
##     routines on one line each, at one indent, group comment right above it, `#` and never doc.
##   Forward declaration takes doc of its routine, since `nim doc` reads doc there and drops
##     doc of definition (read in `nim doc` of Nim 2.2.12); fixer leaves its move for hand.
##   Doc position: one-line doc of type, field, binding and enum member stands on declaration's
##     own line, two spaces before `##`, where joined line fits `LINE_MAX`; otherwise on next
##     line, one level in. Doc of two or more lines stays where it is.
##   Doc position reads declaration as line of code inside `type`, `const`, `let` or `var`
##     section, at any depth of object, enum or branch, or such keyword's own line holding one
##     declaration. Line that continues expression, opens block, ends in bracket left open, or
##     carries `#` comment is none, and routine's doc keeps its own position.
##   Default of parameter (X.12): type goes where literal default gives exactly that type:
##     `int` of integer literal, `float` of float literal, `bool` of `true` or `false`, `string`
##     of string literal, `char` of character literal; `T` of `default(T)`, and `Option[T]` of
##     `none(T)`. `float = 0`, `cfloat = 0.0`, `HalfTurns = 0` and named constant stay, since
##     there literal fixes another type, or none.
##   Default read in routine, routine type and lambda; template and macro stay, since their
##     parameter without type reads otherwise.
##   Checks and fixers share one reading (`writesDoc`, `movesDoc`, `defaults`), so each rule is
##     written once (Article II.1).
##
##   Cost: scanner, never parser (`tokens.nim`); declaration it cannot place surely stays.
##   Cost: doc opening line right below declaration's counts though value runs on past it, as
##     first line in `block:` or inside bracket, where `nim doc` reads none (`nim jsondoc` of
##     Nim 2.2.12).
##   Cost: routine on one line reads as forward where its body after `= ` is shorter than
##     `BODY_FORWARD_MAX`, so short helper standing under group comment passes too.
##   Cost: forward declaration reads by name alone: routine without body where any overload of
##     its name follows.
##   Cost: literal with suffix (`0'u8`) and raw string keep their type, though it is exact.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[declared, form, reports, tokens, views]


type
  ShapeWrite {.pure.} = enum  ## Define how fixer writes doc of declaration.
    Join  ## Doc joins declaration's first line.
    Below  ## Doc takes own line below line `at`, one level in.
    Note  ## Doc on line `at` holds design note: note moves above, and doc waits for text.
    Hand  ## Doc of several lines opens with design note, so fix leaves it for hand.
    Forward  ## Forward declaration with no doc, whose routine follows: move stays for hand.

  WriteDoc = object
    ## Define one doc to write: declaration with none in its place, or with note as its doc.
    line: int  ## Zero-based line of declaration.
    shape: ShapeWrite  ## How fixer writes doc, or why it leaves it for hand.
    at: int  ## Zero-based line doc is written on, or below.
    offset: int  ## Byte offset of `##` opening note on line `at`; `-1` for none.
    indent: int  ## Spaces before doc written on own line, or before note moved above.
    got: string  ## Value message echoes: declaration, e.g. `const SAMPLES`, or doc holding note.

  Shape {.pure.} = enum  ## Define move doc takes.
    Join  ## Next-line doc joins declaration's line.
    Split  ## Trailing doc widening line takes next line.
    Indent  ## Next-line doc that cannot join takes indent one level in.

  MoveDoc = object
    ## Define one doc to move: declaration line, shape, lines replacing declaration and doc.
    line: int  ## Zero-based line of declaration.
    shape: Shape  ## Move doc takes, which message names.
    last: int  ## Zero-based last line replaced: doc's line, or declaration's own.
    lines: seq[string]  ## Lines standing from `line` to `last` once doc moves.

  Default = object
    ## Define type to drop from parameter: byte span from name's end to `=`, and type read.
    line: int  ## Zero-based line of parameter.
    first: int  ## Byte offset after parameter's name.
    after: int  ## Byte offset of `=`.
    got: string  ## Parameter as written.


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
  DOC_EMPTY = "## TODO: Document."  ## Doc waiting for honest text (Article VI.1).
  MARKER_NOTE = "## TODO:"  ## Opening of doc holding design note in place of text (VIII.3).
  BODY_FORWARD_MAX = 40
    ## Longest body, in bytes, routine on one line holds and still reads as forward (VI.1).


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


func writesDoc(source: string): seq[WriteDoc] =
  ## Find each declaration with no doc in its place, and each doc holding design note.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
  var
    continues = newSeq[bool](lines.len)
      # Line whose statement runs on: string or comment spans past it, or last token is `,`, or
      #   operator closing on `=` or `&`.
    ended = newSeq[bool](lines.len)  # Line token of code ends on, closing `"""` among them.
    spanned = newSeq[bool](lines.len)  # Line token from line above runs into.
    commented = newSeq[bool](lines.len)  # Line comment trails code on, or block comment closes on.
    trailing = newSeqWith(lines.len, -1)  # Byte offset of `##` doc trailing code of each line.
    opening = newSeq[bool](lines.len)  # Line doc opens, line doc or block, with no code before.
    endings = newSeq[string](lines.len)  # Spelling of last token of code on each line.
    nested = newSeq[bool](lines.len)  # Line whose first token of code stands inside bracket.
    keywords = newSeqWith(lines.len, -1)  # First routine keyword token on each line.
    quoted = newSeq[bool](lines.len)  # Line inside `quote do:` body, generated code.

  func endPast(j: int): int =
    ## Read zero-based line string or comment spanning past line `j` closes on; `j` where none.
    result = j
    while result + 1 < lines.len and spanned[result+1]: inc result

  func endSignature(i: int): (int, bool) =
    ## Read zero-based line signature of routine on line `i` ends on, and whether body opens
    ##   there: line of `=` opening body, else line of its last token, as forward declaration's;
    ##   string body opens runs past it.
    var (j, last) = (keywords[i], keywords[i])
    if j < 0: return (i, true)
    while j < tokens.len:
      let t = tokens[j]
      if t.kind == KindToken.Comment:
        inc j
        continue
      if t.line > tokens[last].lineLast(source) and
          lines[t.line].indentWidth <= lines[i].indentWidth:
        break
      if t.kind == KindToken.Operator and t.spelling(source) == "=": return (endPast(t.line), true)
      last = if t.kind == KindToken.Open and partners[j] > j: partners[j] else: j
      j = last + 1
    (endPast(tokens[last].lineLast(source)), false)

  func endValue(i: int): int =
    ## Read zero-based line declaration on line `i` ends on, value or type: first line closing
    ##   its brackets whose statement runs on no further.
    var depth = 0
    for j in i..<code.len:
      for c in code[j]:
        if c in {'(', '[', '{'}: inc depth
        elif c in {')', ']', '}'}: dec depth
      if depth <= 0 and not continues[j]: return j
    i

  func endBinding(i: int): int =
    ## Read zero-based line value of binding on line `i` ends on: that of `endValue`, then each
    ##   line of code below it at deeper indent, as branch of `when` or body of `block`, which
    ##   Nim reads as part of value.
    result = endValue(i)
    let indent = lines[i].indentWidth
    var k = result + 1
    while k < code.len:
      if code[k].strip.len == 0:
        inc k
        continue
      if code[k].indentWidth <= indent: break
      result = endValue(k)
      k = result + 1

  func isDelegation(j: int): bool =
    ## Decide whether line `j` declares one-line borrow, or forward whose body after `= ` is short.
    let
      s = code[j].strip
      parts = s.split("= ")
    code[j].wordFirst in KEYWORDS_ROUTINE and ("{.borrow" in s or
        (not s.endsWith("=") and parts.len > 1 and parts[1].len < BODY_FORWARD_MAX))

  func isStacked(i: int): bool =
    ## Decide whether routine on line `i` is one-line delegation standing in run of such under
    ##   group comment at its indent, `#` and never doc (VI.1).
    if not isDelegation(i): return false
    let indent = lines[i].indentWidth
    var k = i - 1
    while k >= 0 and lines[k].indentWidth == indent and isDelegation(k): dec k
    k >= 0 and lines[k].indentWidth == indent and lines[k].strip.startsWith("#") and
        not lines[k].strip.startsWith("##")

  func section(i: int): string =
    ## Read keyword of section holding binding on line `i`, e.g. `const`; `binding` where none.
    if code[i].wordFirst in KEYWORDS_SECTION: return code[i].wordFirst
    for k in countdown(i - 1, 0):
      if code[k].strip.len == 0 or code[k].indentWidth >= code[i].indentWidth: continue
      let word = code[k].wordFirst
      return if word in KEYWORDS_SECTION: word else: "binding"
    "binding"

  func docPlaced(i, e: int; kind: KindName): (int, int) =
    ## Read line and byte offset of doc standing in place for declaration of `kind` on line `i`
    ##   whose value or signature ends on line `e`: trailing either line, or opening first line
    ##   below either at deeper indent, but below routine's signature alone; `(-1, -1)` where
    ##   none.
    for j in [i, e]:
      if trailing[j] >= 0: return (j, trailing[j])
    let top = if kind == KindName.Routine: e else: i
    for j in [top, e]:
      var below = j + 1
      while below < lines.len and lines[below].strip.len == 0: inc below
      if below < lines.len and opening[below] and
          lines[below].indentWidth > lines[i].indentWidth:
        return (below, lines[below].indentWidth)
    (-1, -1)

  # Mark lines statements run past or open inside brackets, docs trail or open, routine keywords,
  #   and generated code.
  var depth = 0  # Brackets open before token.
  for k, t in tokens:
    let last = t.lineLast(source)
    for line in t.line..<last:
      continues[line] = true
      spanned[line+1] = true
    if keywords[t.line] < 0 and t.spelling(source) in KEYWORDS_ROUTINE: keywords[t.line] = k
    if t.kind == KindToken.Comment:
      let is_doc = t.spelling(source).startsWith("##")
      if ended[t.line]:
        commented[t.line] = true
        if is_doc and trailing[t.line] < 0: trailing[t.line] = t.first - starts[t.line]
      elif is_doc and not spanned[t.line]: opening[t.line] = true
      if last > t.line: commented[last] = true
      continue
    if not ended[t.line] and depth > 0: nested[t.line] = true
    ended[last] = true
    let text = t.spelling(source)
    endings[last] = text
    if t.kind == KindToken.Open: inc depth
    elif t.kind == KindToken.Close: depth = max(depth - 1, 0)
    continues[last] = t.kind == KindToken.Comma or
        (t.kind == KindToken.Operator and (text.endsWith("=") or text.endsWith("&")))
  for k, line in code:
    if not line.strip.endsWith("quote do:"): continue
    var below = k + 1
    while below < code.len and
        (code[below].strip.len == 0 or code[below].indentWidth > line.indentWidth):
      quoted[below] = true
      inc below

  # Read each declaration that takes doc, once for each line.
  let found = source.declarations
  var seen: seq[int]  # Line of each declaration written, so names sharing line write once.
  for d in found:
    let i = d.line - 1
    if i < 0 or i >= lines.len or i in seen or quoted[i]: continue
    if d.kind in {KindName.Parameter, KindName.Placeholder}: continue
    if nested[i] and d.kind != KindName.Routine: continue
    if d.kind == KindName.Binding and d.reach != Reach.Global: continue
    let
      (e, is_bodied) =
        case d.kind
        of KindName.Routine: endSignature(i)
        of KindName.Member: (endPast(i), true)
        of KindName.Binding: (endBinding(i), true)
        else: (endValue(i), true)
      (line_doc, offset) = docPlaced(i, e, d.kind)
      indent = lines[i].indentWidth

    # Pass doc in place, unless it holds design note.
    if line_doc >= 0:
      let doc = lines[line_doc][offset .. ^1].strip
      if not doc.startsWith(MARKER_NOTE) or doc == DOC_EMPTY: continue
      let
        below = line_doc + 1
        is_outlined = below < lines.len and opening[below] and lines[below].indentWidth > indent
      seen.add i
      result.add WriteDoc(
        line: i,
        shape: if is_outlined: ShapeWrite.Hand else: ShapeWrite.Note,
        at: line_doc,
        offset: offset,
        indent: indent,
        got: doc,
      )
      continue

    # Pass borrow or forward under group comment, and doc above at declaration's indent unless
    #   block opening above owns it.
    if d.kind == KindName.Routine and isStacked(i): continue
    var top = i - 1
    while top >= 0 and opening[top] and lines[top].indentWidth == indent: dec top
    let is_owned = top >= 0 and lines[top].strip.len > 0 and lines[top].indentWidth < indent
    if d.kind != KindName.Routine and i > 0 and opening[i-1] and
        lines[i-1].indentWidth == indent and not is_owned:
      continue

    # Write doc where doc position puts it: below routine's signature, else joined where it fits;
    #   forward declaration's waits for doc its routine holds.
    seen.add i
    let
      shown =
        case d.kind
        of KindName.Routine: d.keyword & " " & d.name
        of KindName.Binding: section(i) & " " & d.name
        else: ($d.kind).toLowerAscii & " " & d.name
      # Line ends on `=` of argument or `:` of field inside open bracket, where doc parses not.
      is_entry_open = endings[i] in ["=", ":"] and
          code[i].count({'(', '[', '{'}) > code[i].count({')', ']', '}'})
      at =
        if d.kind == KindName.Routine or (i + 1 < lines.len and spanned[i+1]) or is_entry_open: e
        else: i  # value opening string, comment or entry over lines takes doc where it closes
      joined = lines[at].strip(leading = false) & ' '.repeat(GAP_COMMENT) & DOC_EMPTY
      is_forward = d.kind == KindName.Routine and not is_bodied and
          found.anyIt(it.kind == KindName.Routine and it.name == d.name and it.line > d.line)
      shape =
        if is_forward: ShapeWrite.Forward
        elif d.kind == KindName.Routine or commented[at] or joined.isWide: ShapeWrite.Below
        else: ShapeWrite.Join
    var below = e + 1  # First line of routine's body, whose indent its doc takes.
    while below < lines.len and lines[below].strip.len == 0: inc below
    let indent_body =
      if d.kind == KindName.Routine and below < lines.len and lines[below].indentWidth > indent:
        lines[below].indentWidth
      else: indent + STEP_INDENT
    result.add WriteDoc(
      line: i,
      shape: shape,
      at: at,
      offset: -1,
      indent: indent_body,
      got: shown,
    )


func checkDocsMissing*(path, source: string): seq[Report] =
  ## Report declaration with no doc in its place, and doc holding design note (VI.1).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for write in source.writesDoc:
    let message =
      case write.shape
      of ShapeWrite.Join, ShapeWrite.Below:
        "Declaration takes doc comment; got `" & write.got & "`."
      of ShapeWrite.Note, ShapeWrite.Hand:
        "Doc holds `TODO: Document.` and nothing else; got `" & write.got & "`."
      of ShapeWrite.Forward:
        "Forward declaration takes doc of its routine, which `nim doc` reads there; got `" &
            write.got & "`."
    result.add initReport(path, write.line + 1, Rule.DocMissing, message)


func fixDocsMissing*(path, source: string): Fix =
  ## Write each doc check reports, last first, but those left for hand; each line written new
  ##   traces to none.
  let writes = source.writesDoc.filterIt(it.shape notin {ShapeWrite.Hand, ShapeWrite.Forward})
  var
    lines = source.split('\n')
    origin = toSeq(1..lines.len)
  for write in writes.sortedByIt(it.at).reversed:
    case write.shape
    of ShapeWrite.Join:
      lines[write.at] = lines[write.at].strip(leading = false) & ' '.repeat(GAP_COMMENT) &
          DOC_EMPTY
    of ShapeWrite.Below:
      lines.insert(' '.repeat(write.indent) & DOC_EMPTY, write.at + 1)
      origin.insert(0, write.at + 1)
    of ShapeWrite.Note:
      let note = lines[write.at][write.offset .. ^1].strip
      lines[write.at] = lines[write.at][0..<write.offset] & DOC_EMPTY
      lines.insert(' '.repeat(write.indent) & "# " & note[3 .. ^1], write.line)
      origin.insert(0, write.line)
    of ShapeWrite.Hand, ShapeWrite.Forward: discard
  result.source = lines.join("\n")
  for write in writes: result.fixed.add initReport(path, write.line + 1, Rule.DocMissing)
  if writes.len > 0: result.origin = origin


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
