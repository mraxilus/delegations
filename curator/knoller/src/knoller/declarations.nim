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
##   Fixer writes `## TODO: Document.` where doc position puts doc and `nim doc` reads it:
##     joined to declaration's one line where joined line fits and holds no comment, else on
##     next line, one level in; routine's as first line of its body. Value or type over lines
##     takes it after `=` closing its first line, where it fits; else joined to its last line,
##     or on line below, one level in; `case` value on line below its last branch. Doc never
##     joins first line inside string or bracket opening there, nor stands below `=` closing it,
##     where Nim parses none. Value opening `block` takes it above, as `#` comment (below).
##   Doc holding other TODO holds design note (VIII.3), never text: fixer moves note above
##     declaration as `#` comment, and doc takes `## TODO: Document.`. Doc of several lines,
##     which lexer joins at any indent, opening with note stays for hand, since its outline may
##     elaborate note or text.
##   Missing doc passes one-line borrow or forward stacked under group comment (VI.1), code
##     inside `quote do:`, whose generator carries docs through parameter, and doc on line above
##     declaration that is no routine, at its indent, which stands out of place rather than
##     missing; doc that only blank lines and `#` comments stand above is module's, so declaration
##     below it takes its own. Stack is run of routines on one line each, at one indent, group
##     comment right above it, `#` and never doc.
##   Forward declaration takes doc of its routine, since `nim doc` reads doc there and drops doc
##     of definition (read in `nim doc` of Nim 2.2.12 and 2.4.0); fixer leaves its move for hand.
##   Doc position (VI.9): each doc stands where `nim doc` reads it, in one position for each
##     shape (STYLE.md §5). One-line doc of type, field, binding and enum member stands on
##     declaration's own line, two spaces before `##`, where joined line fits `LINE_MAX`;
##     otherwise on next line, one level in, as does next-line doc of several lines, or under
##     line holding `#` comment. Doc trailing line keeps lines below that continue it, which
##     lexer joins to it as one doc, value over lines among them.
##   Doc above type, field, global binding or enum member moves where missing doc writes it
##     (`target`), where blank line or `#` comment stands above it. Doc right below other code,
##     or that declaration holds as its own, stays: either may own it. Doc that only blank lines
##     and `#` comments stand above stays too, as doc of module, since `nim doc` reads it so
##     (#980: `D3 a` on file's start, `D1 a` on comments above; `nim jsondoc` of Nim 2.4.0). Doc
##     below code or other doc moves, though `nim doc` reads module's there too, since hand that
##     wrote it above declaration meant it for that one.
##   One-line doc inside value over lines, where `nim doc` reads none, moves after `=` ending
##     first line where it fits, else after close of value. Binding of any reach reads so, and so
##     doc missing doc counts on first line inside value moves.
##   Value of binding opening `block`, at any reach (D1 c of #1020): `block:` stays on its `=`
##     line, so body takes one indent, and doc stands on own lines above declaration, as `#`
##     comment, since `nim doc` reads none there and `##` above top-level declaration joins
##     module's (suite "Article VI.9"). Blank line stands above that doc, but where line
##     above opens body holding it, as `if` or section keyword, or file opens there (`blocks`).
##   Missing doc writes `# TODO: Document.` there for global such value; comment there counts as
##     its doc, and so does `##` doc that doc position moves there. Doc position moves doc after
##     `block:`, with lines lexer joins to it, or else first in body, there; it writes `#` for
##     `##` above, and adds blank line above. Doc inside or after `block:` with comment above it
##     too, and `block` opening below `=` of value, never of routine's head, as lambda's, whose
##     body needs dedent, wait for hand. `##` above that routine, module or other declaration
##     holds, or lexer joins to doc trailing code above, stays its owner's (`movesBlock`).
##   Routine's doc opens line after its signature, at indent of its body: doc on signature line,
##     after blank line or off that indent moves there. One-line doc under bare `type` joins
##     keyword line, as group doc of block.
##   Doc position reads declaration as line of code inside `type`, `const`, `let` or `var`
##     section, at any depth of object, enum or branch, or such keyword's own line holding one
##     declaration (`sections`), so value opening `block` too; line that continues expression,
##     or stands in body of value, as of `block`, declares nothing. Doc above and routine's doc
##     it reads from declarations missing doc reads (`movesPlaced`).
##   Default of parameter (X.12): type goes where literal default gives exactly that type:
##     `int` of integer literal, `float` of float literal, `bool` of `true` or `false`, `string`
##     of string literal, `char` of character literal; `T` of `default(T)`, and `Option[T]` of
##     `none(T)`. `float = 0`, `cfloat = 0.0`, `HalfTurns = 0` and named constant stay, since
##     there literal fixes another type, or none.
##   Default read in routine, routine type and lambda; template and macro stay, since their
##     parameter without type reads otherwise.
##   Checks and fixers share one reading (`placements`, `blocks`, `movesDoc`, `defaults`), so
##     each rule is written once (Article II.1): `placements` reads where doc of each declaration
##     stands and where `nim doc` reads it (`target`), `blocks` where doc of value opening `block`
##     stands, and missing doc writes from both (`writesDoc`).
##
##   Cost: scanner, never parser (`tokens.nim`); declaration it cannot place surely stays.
##   Cost: doc opening line right below declaration's counts though value runs on past it, as
##     first line inside bracket, where `nim doc` reads none (`nim jsondoc` of Nim 2.2.12 and
##     2.4.0).
##   Cost: doc trailing first line of value over brackets, or of signature, stays unread there.
##   Cost: `#` comment right above value opening `block`, at its indent, reads as its doc, though
##     it may remark on line above it.
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
    Above  ## Value opens `block`: doc takes own line above declaration, as `#` comment.

  WriteDoc = object
    ## Define one doc to write: declaration with none in its place, or with note as its doc.
    line: int  ## Zero-based line of declaration.
    shape: ShapeWrite  ## How fixer writes doc, or why it leaves it for hand.
    at: int  ## Zero-based line doc is written on, or below.
    offset: int  ## Byte offset of `##` opening note on line `at`; `-1` for none.
    indent: int  ## Spaces before doc written on own line, or before note moved above.
    is_clear: bool  ## Line above declaration is blank or opens its body, or none stands there.
    got: string  ## Value message echoes: declaration, e.g. `const SAMPLES`, or doc holding note.

  Placement = object
    ## Define where doc of declaration stands, and what decides where `nim doc` reads it, so
    ##   missing doc and doc position read one place.
    line: int  ## Zero-based line of declaration.
    kind: KindName
    last: int  ## Zero-based line its value, type or signature ends on.
    doc: int  ## Zero-based line of doc standing in place; `-1` for none.
    offset: int  ## Byte offset of `##` on line `doc`, where doc trails code; else its indent.
    is_trailing: bool  ## Doc in place trails code of its line.
    is_outlined: bool  ## Line below doc in place opens doc too, which lexer joins to it.
    is_stacked: bool  ## One-line borrow or forward standing under group comment (VI.1).
    is_above: bool
      ## Doc on line above, at declaration's indent, that neither block above nor module owns.
    is_forward: bool  ## Forward declaration with no body, whose routine follows.
    is_block: bool  ## Value of binding opens `block`, on declaration's line or on line below `=`.
    is_equals: bool  ## `=` closes first line outside bracket, with no string or comment past it.
    is_case: bool  ## Value is `case` expression, whose doc trailing last branch reads not.
    is_commented_first: bool  ## Comment trails code of declaration's line.
    is_commented_last: bool  ## Comment trails code of line value or type ends on.
    first: string  ## Text of declaration's line.
    closing: string  ## Text of line value or type ends on.
    indent_body: int  ## Spaces before doc written on own line: body's indent, else one level in.
    shown: string  ## Declaration as message echoes it, e.g. `const SAMPLES`.

  Shape {.pure.} = enum  ## Define move doc takes.
    Join  ## Next-line doc joins declaration's line.
    Split  ## Trailing doc widening line takes next line.
    Indent  ## Next-line doc that cannot join takes indent one level in.
    Above  ## Doc above declaration moves where missing doc writes it.
    Inside  ## One-line doc inside value joins `=` ending its first line.
    Close  ## One-line doc inside value moves after its close.
    BlockInside  ## Doc first in body of value opening `block` moves above it, as `#` comment.
    BlockAfter  ## Doc trailing `block:` moves above declaration, as `#` comment.
    BlockHash  ## `##` doc above value opening `block` takes `#`, since `nim doc` reads none there.
    BlockBlank  ## Doc above value opening `block` takes blank line above it.
    BlockTwice  ## Doc inside or after `block:` and comment above it, which hand joins.
    BlockBelow  ## `block` opens below `=`, so body needs dedent, which fix leaves for hand.
    Signature  ## Doc on routine's signature line takes line after it.
    Blank  ## Blank line between routine's signature and its doc goes.
    Body  ## Routine's doc takes indent of body.
    Group  ## One-line doc under bare `type` joins keyword line.

  MoveDoc = object
    ## Define one doc to move: declaration line, shape, lines replacing span that holds both.
    line: int  ## Zero-based line of declaration, which report names.
    shape: Shape  ## Move doc takes, which message names.
    first: int  ## Zero-based first line replaced: doc's line above, or declaration's own.
    last: int  ## Zero-based last line replaced.
    lines: seq[string]  ## Lines standing from `first` to `last` once doc moves; none for hand.
    origins: seq[int]  ## Zero-based line of source each of `lines` comes from; `-1` for none.
    got: string  ## Declaration message echoes, e.g. `const N`.
    indent: int  ## Indent of doc as found, which message echoes where indent is wrong.

  ValueBlock = object
    ## Define binding whose value opens `block`, and where its doc stands: own lines above its
    ##   declaration, as `#` comment, blank line above them (D1 c of #1020).
    line: int  ## Zero-based line of declaration.
    is_below: bool  ## `block` opens on line below `=`, so body takes two indents.
    above: int
      ## Zero-based first line of comment right above declaration, at its indent; `line` for none.
    is_clear: bool  ## Line above `above` is blank or opens body holding declaration, or is none.
    is_hashed: bool  ## Comment above holds `##` doc.
    inside: int
      ## Zero-based first line of `##` doc after `block:`, else first in its body; `-1` for none.
    ends: int  ## Zero-based last line of that doc, as lexer joins it.
    offset: int  ## Byte offset of `##` of doc trailing `block:`; `-1` where doc opens own line.
    shown: string  ## Declaration as message echoes it, e.g. `const LUT`.

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
  COMMENT_EMPTY = "# TODO: Document."
    ## Doc of value opening `block` waiting for text: `#` comment, since `nim doc` reads none above
    ##   its declaration (D1 c of #1020).
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


func isOpeningBlock(code: string): bool =
  ## Decide whether code line ends opening `block`, labelled or not.
  let s = code.strip
  if not s.endsWith(":"): return false
  let words = s[0 ..< ^1].splitWhitespace
  words.len > 1 and (words[^1] == "block" or words[^2] == "block")


func isBlockBelow(code: openArray[string], i: int): bool =
  ## Decide whether code line `i` ends on `=` and next line holding code opens `block` alone,
  ##   labelled or not, at deeper indent; never where `=` closes head of routine, as lambda's.
  let head = code[i].strip
  if not head.endsWith(" ="): return false
  var spoken = head[0 ..< ^1]  # Identifiers alone, each apart.
  for c in spoken.mitems:
    if c notin {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}: c = ' '
  if spoken.splitWhitespace.anyIt(it in KEYWORDS_ROUTINE): return false
  var k = i + 1
  while k < code.len and code[k].strip.len == 0: inc k
  if k >= code.len or code[k].indentWidth <= code[i].indentWidth: return false
  let words = code[k].splitWhitespace
  words == @["block:"] or (words.len == 2 and words[0] == "block" and words[1].endsWith(":"))


func section(code: openArray[string], i: int): string =
  ## Read keyword of section holding binding on line `i`, e.g. `const`; `binding` where none.
  if code[i].wordFirst in KEYWORDS_SECTION: return code[i].wordFirst
  for k in countdown(i - 1, 0):
    if code[k].strip.len == 0 or code[k].indentWidth >= code[i].indentWidth: continue
    let word = code[k].wordFirst
    return if word in KEYWORDS_SECTION: word else: "binding"
  "binding"


func isJoinable(line: string; is_commented: bool; doc: string): bool =
  ## Decide whether doc joins line: line holds no comment, and joined line fits.
  not is_commented and not (line.strip(leading = false) & ' '.repeat(GAP_COMMENT) & doc).isWide


func placements(source: string): seq[Placement] =
  ## Read where doc of each declaration that takes one stands, once for each line, and what
  ##   decides where `nim doc` reads it.
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

  # First line holding code or opening doc: doc whose run opens there is doc of module.
  var heading = lines.len
  for k in 0 ..< lines.len:
    if code[k].strip.len > 0 or opening[k]:
      heading = k
      break

  # Read each declaration that takes doc, once for each line.
  let found = source.declarations
  var seen: seq[int]  # Line of each declaration read, so names sharing line read once.
  for d in found:
    let i = d.line - 1
    if i < 0 or i >= lines.len or i in seen or quoted[i]: continue
    if d.kind in {KindName.Parameter, KindName.Placeholder}: continue
    if nested[i] and d.kind != KindName.Routine: continue
    if d.kind == KindName.Binding and d.reach != Reach.Global: continue
    seen.add i
    let
      (e, is_bodied) =
        case d.kind
        of KindName.Routine: endSignature(i)
        of KindName.Member: (endPast(i), true)
        of KindName.Binding: (endBinding(i), true)
        else: (endValue(i), true)
      (line_doc, offset) = docPlaced(i, e, d.kind)
      indent = lines[i].indentWidth

    # Read doc above at declaration's indent, which block opening above may own, and line below
    #   signature, whose indent routine's doc takes; doc under blank lines and `#` comments alone
    #   is module's, as `nim doc` reads it (#980: `D3 a` on file's start, `D1 a` on comments above).
    var top = i - 1
    while top >= 0 and opening[top] and lines[top].indentWidth == indent: dec top
    var below = e + 1
    while below < lines.len and lines[below].strip.len == 0: inc below
    let
      is_owned = heading > top or (lines[top].strip.len > 0 and lines[top].indentWidth < indent)
      outline = line_doc + 1
    result.add Placement(
      line: i,
      kind: d.kind,
      last: e,
      doc: line_doc,
      offset: offset,
      is_trailing: line_doc >= 0 and trailing[line_doc] >= 0,
      is_outlined: line_doc >= 0 and outline < lines.len and opening[outline],
      is_stacked: d.kind == KindName.Routine and isStacked(i),
      is_above: d.kind != KindName.Routine and i > 0 and opening[i-1] and
        lines[i-1].indentWidth == indent and not is_owned,
      is_forward: d.kind == KindName.Routine and not is_bodied and
        found.anyIt(it.kind == KindName.Routine and it.name == d.name and it.line > d.line),
      is_block: d.kind == KindName.Binding and (code[i].isOpeningBlock or code.isBlockBelow(i)),
      is_equals: endings[i] == "=" and not (i + 1 < lines.len and spanned[i+1]) and
        code[i].count({'(', '[', '{'}) <= code[i].count({')', ']', '}'}),
      is_case: " = case " in code[i],
      is_commented_first: commented[i],
      is_commented_last: commented[e],
      first: lines[i],
      closing: lines[e],
      indent_body:
        if d.kind == KindName.Routine and below < lines.len and lines[below].indentWidth > indent:
          lines[below].indentWidth
        else: indent + STEP_INDENT,
      shown:
        case d.kind
        of KindName.Routine: d.keyword & " " & d.name
        of KindName.Binding: code.section(i) & " " & d.name
        else: ($d.kind).toLowerAscii & " " & d.name,
    )


func sections(source: string): seq[string] =
  ## Read keyword of section each line of code declares in, e.g. `const`, for line opening there,
  ##   outside brackets, that continues no expression; empty for other line, and for section
  ##   keyword alone on its line.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    tokens = source.tokens
  result = newSeq[string](lines.len)
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

    # Line continuing expression declares nothing, but value it opens may hold doc; section
    #   keyword opens statement, wherever token before it stands.
    let is_opening = text_ending == "=" or code[d].isOpeningBlock or ending.kind == KindToken.Open
    if not is_opening and (ending.kind in {KindToken.Open, KindToken.Comma, KindToken.Operator} or
        text_ending in KEYWORDS_CONTINUING):
      continue
    if first > 0 and word notin KEYWORDS_SECTION:
      var previous = first - 1
      while previous > 0 and tokens[previous].kind == KindToken.Comment: dec previous
      let before = tokens[previous]
      if before.kind in {KindToken.Open, KindToken.Comma} or
          (before.kind == KindToken.Operator and before.spelling(source) != ":") or
          before.spelling(source) in KEYWORDS_CONTINUING:
        continue

    # Declaration context: section keyword on line, or above it through enclosing lines; line
    #   inside body of value, as of `block`, declares in no section.
    var
      section = if word in KEYWORDS_SECTION: word else: ""
      parent = d
    while section.len == 0 and code[parent].indentWidth > 0:
      let indent_parent = code[parent].indentWidth
      dec parent
      while parent >= 0 and
          (code[parent].strip.len == 0 or code[parent].indentWidth >= indent_parent):
        dec parent
      if parent < 0 or code[parent].wordFirst in KEYWORDS_ROUTINE: break
      let above = code[parent].strip
      if above notin KEYWORDS_SECTION and (above.endsWith("=") or above.isOpeningBlock): break
      if code[parent].wordFirst in KEYWORDS_SECTION: section = code[parent].wordFirst
    result[d] = section


func ownership(source: string, found: seq[Placement]): tuple[owned: seq[bool], heading: int] =
  ## Read each line of `##` doc that declaration of `found` holds in place, or that routine holds,
  ##   operator among them, whose name no declaration reads; and first line holding code or
  ##   opening doc, so doc opening there is module's (#980: `D3 a` on file's start, `D1 a` on
  ##   comments above).
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')
  result.owned = newSeq[bool](lines.len)
  for p in found:
    if p.doc >= 0: result.owned[p.doc] = true
  for h in source.heads:
    var below = h.last  # Zero-based line after signature.
    while below < lines.len and lines[below].strip.len == 0: inc below
    if below < lines.len and isDoc(code[below], kept[below]): result.owned[below] = true
  result.heading = lines.len
  for k in 0 ..< lines.len:
    if code[k].strip.len > 0 or kept[k].strip.startsWith("##"):
      result.heading = k
      break


func commentAbove(
  lines, code, kept: seq[string]; owned: seq[bool]; heading, line: int
): tuple[top: int, is_hashed: bool] =
  ## Read zero-based first line of comment right above line `line`, at its indent, `line` where
  ##   none, and whether it holds `##` doc. Walk stops at `##` doc that code above, module (line
  ##   `heading`), routine or declaration (`owned`) holds, as lexer joins it.
  let indent = lines[line].indentWidth

  func isLineDoc(k: int): bool =
    ## Decide whether line `k` holds `##` doc alone.
    k >= 0 and k < lines.len and isDoc(code[k], kept[k])

  func isTrailingDoc(k: int): bool =
    ## Decide whether `##` doc trails code of line `k`.
    let at = kept[k].find('#', code[k].strip(leading = false).len)
    code[k].strip.len > 0 and at >= 0 and kept[k][at .. ^1].startsWith("##")

  result.top = line
  while result.top > 0:
    let
      k = result.top - 1
      text = kept[k].strip
    if code[k].strip.len > 0 or lines[k].indentWidth != indent or not text.startsWith("#") or
        text.startsWith("#[") or text.startsWith("#!"):
      break
    if not text.startsWith("##"):
      result.top = k
      continue
    var start = k  # First line of doc lexer joins line `k` into.
    while start > 0 and start.isLineDoc and (isLineDoc(start - 1) or isTrailingDoc(start - 1)):
      dec start
    if start == heading or owned[start] or
        toSeq(start .. k).anyIt(not it.isLineDoc or lines[it].indentWidth != indent):
      break
    result.is_hashed = true
    result.top = start


func blocks(source: string; found: seq[Placement]; declaring: seq[string]): seq[ValueBlock] =
  ## Read each binding whose value opens `block`, at any reach: each of `found` that reads so,
  ##   and each line declaring in `const`, `let` or `var` section of `declaring`. Read where its
  ##   doc stands: comment right above it at its indent (`commentAbove`); `##` doc trailing
  ##   `block:` with lines lexer joins to it, else `##` doc first in its body.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')
  var (owned, heading) = source.ownership(found)

  func isLineDoc(k: int): bool =
    ## Decide whether line `k` holds `##` doc alone.
    k >= 0 and k < lines.len and isDoc(code[k], kept[k])

  func trailing(k: int): int =
    ## Read byte offset of `##` doc trailing code of line `k`; `-1` where none.
    let at = kept[k].find('#', code[k].strip(leading = false).len)
    if code[k].strip.len > 0 and at >= 0 and kept[k][at .. ^1].startsWith("##"): at else: -1

  # Read each binding opening `block`, once for each line: placement that names it, then line
  #   declaring in section, which reading of declarations may pass over.
  var candidates: seq[(int, string)]  # Line of declaration, and declaration message echoes.
  for p in found:
    if p.is_block: candidates.add (p.line, p.shown)
  for d, section in declaring:
    if section notin ["const", "let", "var"] or candidates.anyIt(it[0] == d) or
        not (code[d].isOpeningBlock or code.isBlockBelow(d)):
      continue
    let
      stripped = code[d].strip
      named = if stripped.wordFirst == section: stripped[section.len .. ^1] else: stripped
    candidates.add (d, section & " " & named.identifierAt(0))

  # Read doc trailing `block:` or first in body of each, which no comment above other takes.
  for (i, shown) in candidates.sortedByIt(it[0]):
    let is_below = code.isBlockBelow(i)
    var b = ValueBlock(
      line: i,
      is_below: is_below,
      above: i,
      inside: -1,
      ends: -1,
      offset: if is_below: -1 else: i.trailing,
      shown: shown,
    )
    var below = i + 1
    while below < lines.len and lines[below].strip.len == 0: inc below
    if b.offset >= 0: b.inside = i
    elif not is_below and below.isLineDoc and lines[below].indentWidth > lines[i].indentWidth:
      b.inside = below
      owned[below] = true
    if b.inside >= 0:
      b.ends = b.inside
      while isLineDoc(b.ends + 1): inc b.ends
    result.add b

  # Read comment right above each at its indent, and whether blank line, line opening its body, or
  #   none stands above it.
  for b in result.mitems:
    let indent = lines[b.line].indentWidth
    (b.above, b.is_hashed) = commentAbove(lines, code, kept, owned, heading, b.line)
    let
      top = b.above
      opener = if top > 0: code[top - 1].strip else: ""
    b.is_clear = top == 0 or lines[top - 1].strip.len == 0 or
      (opener.len > 0 and lines[top - 1].indentWidth < indent and
        (opener.endsWith(":") or opener.endsWith("=") or opener in KEYWORDS_SECTION))


func target(p: Placement, doc: string): (int, ShapeWrite) =
  ## Read line doc of placement takes, and how, where `nim doc` reads it: below routine's
  ##   signature; on declaration's one line, else below it; for value or type over lines, after
  ##   `=` closing first line, else at its close. Forward declaration's waits for doc its routine
  ##   holds; value opening `block` takes it above, where `nim doc` reads none. Doc text decides
  ##   whether joined line fits.
  let
    shape_first =
      if p.first.isJoinable(p.is_commented_first, doc): ShapeWrite.Join else: ShapeWrite.Below
    shape_last =
      if p.closing.isJoinable(p.is_commented_last, doc): ShapeWrite.Join else: ShapeWrite.Below
  if p.is_forward: (p.last, ShapeWrite.Forward)
  elif p.kind == KindName.Routine: (p.last, ShapeWrite.Below)
  elif p.is_block: (p.line, ShapeWrite.Above)  # above, as `#` (D1 c of #1020)
  elif p.last == p.line: (p.line, shape_first)
  elif p.is_equals and shape_first == ShapeWrite.Join: (p.line, ShapeWrite.Join)  # below `=` none
  elif p.is_case: (p.last, ShapeWrite.Below)  # doc trailing last branch reads not
  else: (p.last, shape_last)


func writesDoc(source: string): seq[WriteDoc] =
  ## Find each declaration with no doc in its place, and each doc holding design note.
  let
    lines = source.split('\n')
    found = source.placements
    valued = source.blocks(found, source.sections)
  for p in found:
    # Pass value opening `block` that holds comment above it, or doc that doc position moves there;
    #   any doc near value whose `block` opens below `=`, which hand moves.
    if p.is_block:
      let b = valued.filterIt(it.line == p.line)
      if b.len == 0 or b[0].above < p.line or b[0].inside >= 0 or (b[0].is_below and p.doc >= 0):
        continue
      result.add WriteDoc(
        line: p.line,
        shape: ShapeWrite.Above,
        at: p.line,
        offset: -1,
        indent: p.first.indentWidth,
        is_clear: b[0].is_clear,
        got: p.shown,
      )
      continue

    # Pass doc in place, unless it holds design note.
    if p.doc >= 0:
      let doc = lines[p.doc][p.offset .. ^1].strip
      if not doc.startsWith(MARKER_NOTE) or doc == DOC_EMPTY: continue
      result.add WriteDoc(
        line: p.line,
        shape: if p.is_outlined: ShapeWrite.Hand else: ShapeWrite.Note,
        at: p.doc,
        offset: p.offset,
        indent: p.first.indentWidth,
        got: doc,
      )
      continue

    # Pass borrow or forward under group comment, and doc above at declaration's indent unless
    #   block opening above, or module, owns it; write doc where `nim doc` reads it.
    if p.is_stacked or p.is_above: continue
    let (at, shape) = p.target(DOC_EMPTY)
    result.add WriteDoc(
      line: p.line,
      shape: shape,
      at: at,
      offset: -1,
      indent: p.indent_body,
      got: p.shown,
    )


func checkDocsMissing*(path, source: string): seq[Report] =
  ## Report declaration with no doc in its place, and doc holding design note (VI.1).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  for write in source.writesDoc:
    let message =
      case write.shape
      of ShapeWrite.Join, ShapeWrite.Below, ShapeWrite.Above:
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
    of ShapeWrite.Above:
      lines.insert(' '.repeat(write.indent) & COMMENT_EMPTY, write.at)
      origin.insert(0, write.at)
      if not write.is_clear:
        lines.insert("", write.at)
        origin.insert(0, write.at)
    of ShapeWrite.Hand, ShapeWrite.Forward: discard
  result.source = lines.join("\n")
  for write in writes: result.fixed.add initReport(path, write.line + 1, Rule.DocMissing)
  if writes.len > 0: result.origin = origin


func movesLine(source: string; valued: seq[ValueBlock]; declaring: seq[string]): seq[MoveDoc] =
  ## Find each doc of type, field, binding or enum member out of its position, by line it hangs
  ##   from, which declares in section of `declaring`: one-line doc that joins its line or takes
  ##   indent one level in, trailing doc too wide, doc of several lines or under comment off that
  ##   indent, one-line doc inside value over lines; and one-line doc under bare `type`. Value
  ##   opening `block` of `valued` is `movesBlock`'s.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')
    tokens = source.tokens
    partners = tokens.partners
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

  func marker(k: int): int =
    ## Find byte offset of `#` trailing code of line `k`; `-1` where none.
    kept[k].find('#', code[k].strip(leading = false).len)

  func joined(k: int, doc: string): string =
    ## Join doc to line `k`, two spaces before its marker.
    lines[k].strip(leading = false) & ' '.repeat(GAP_COMMENT) & doc

  # Read each line of code opening there, outside brackets, with doc lines below it.
  for d in 0 ..< lines.len:
    let first = firsts[d]
    if first < 0 or code[d].strip.len == 0 or spanned[d] or depths[d] > 0 or lasts[d] < 0:
      continue
    let
      word = code[d].wordFirst
      stripped = code[d].strip
      ending = tokens[lasts[d]]
      text_ending = ending.spelling(source)
      indent = lines[d].indentWidth
      inner = ' '.repeat(indent + STEP_INDENT)
    var below = d + 1
    while below < lines.len and isDoc(code[below], kept[below]) and
        lines[below].indentWidth > indent:
      inc below
    let docs = below - d - 1  # Doc lines below at deeper indent.

    # Group doc of bare `type` joins keyword line, where it fits.
    if stripped == "type":
      if docs == 1 and marker(d) < 0 and not joined(d, lines[d + 1].strip).isWide:
        result.add MoveDoc(
          line: d,
          shape: Shape.Group,
          first: d,
          last: d + 1,
          lines: @[joined(d, lines[d + 1].strip)],
          origins: @[d],
        )
      continue
    let section = declaring[d]
    if section.len == 0 or valued.anyIt(it.line == d): continue
    let is_opening = text_ending == "=" or code[d].isOpeningBlock or ending.kind == KindToken.Open

    # One-line doc inside value over lines, which `nim doc` reads not: after `=` ending first
    #   line where it fits, else after close; `block` that opens no value of binding holds its
    #   own. Doc below doc trailing first line runs on from it, one doc as lexer joins it, so it
    #   stays.
    let
      at = marker(d)
      is_trailed = at >= 0 and kept[d][at .. ^1].startsWith("##")
    if is_opening:
      if docs != 1 or below >= lines.len or code[below].strip.len == 0 or
          lines[below].indentWidth <= indent:
        continue
      let
        doc = lines[d + 1].strip
        named = if word in KEYWORDS_SECTION: stripped[word.len .. ^1] else: stripped
        name = named.identifierAt(0)
        shown = section & " " & name
        is_balanced = code[d].count({'(', '[', '{'}) <= code[d].count({')', ']', '}'})
      if code[d].isOpeningBlock or is_trailed: continue
      if text_ending == "=" and is_balanced and marker(d) < 0 and not joined(d, doc).isWide:
        result.add MoveDoc(
          line: d,
          shape: Shape.Inside,
          first: d,
          last: d + 1,
          lines: @[joined(d, doc)],
          origins: @[d],
          got: shown,
        )
        continue

      # Close of value: partner of bracket ending its first line, else its last line deeper.
      var close = below
      if ending.kind == KindToken.Open and partners[lasts[d]] > lasts[d]:
        close = tokens[partners[lasts[d]]].line
      else:
        for k in below ..< lines.len:
          if lines[k].strip.len == 0: continue
          if lines[k].indentWidth <= indent: break
          close = k
      var move = MoveDoc(line: d, shape: Shape.Close, first: d + 1, last: close, got: shown)
      for k in below .. close:
        move.lines.add lines[k]
        move.origins.add k
      if marker(close) < 0 and not joined(close, doc).isWide:
        move.lines[^1] = joined(close, doc)
      else:
        move.lines.add inner & doc
        move.origins.add d + 1
      result.add move
      continue

    # Doc right below declaration's line: one line joins where it fits, else stands one level
    #   in, as does doc of several lines or under `#` comment; doc trailing line keeps lines
    #   below that continue it; trailing doc too wide splits.
    if at < 0 and docs == 1:
      let doc = lines[d + 1].strip
      if not (lines[d] & ' '.repeat(GAP_COMMENT) & doc).isWide:
        result.add MoveDoc(
          line: d,
          shape: Shape.Join,
          first: d,
          last: d + 1,
          lines: @[lines[d] & ' '.repeat(GAP_COMMENT) & doc],
          origins: @[d],
        )
      elif lines[d + 1].indentWidth != indent + STEP_INDENT:
        result.add MoveDoc(
          line: d,
          shape: Shape.Indent,
          first: d,
          last: d + 1,
          lines: @[lines[d], inner & doc],
          origins: @[d, d + 1],
          indent: lines[d + 1].indentWidth,
        )
    elif docs >= 1 and not is_trailed:
      if toSeq(d + 1 ..< below).allIt(lines[it].indentWidth == indent + STEP_INDENT): continue
      var move = MoveDoc(
        line: d,
        shape: Shape.Indent,
        first: d + 1,
        last: below - 1,
        indent: lines[d + 1].indentWidth,
      )
      for k in d + 1 ..< below:
        move.lines.add inner & lines[k].strip
        move.origins.add k
      result.add move
    elif is_trailed and docs == 0 and lines[d].isWide:
      let declared = lines[d][0 ..< at].strip(leading = false)
      if declared.isWide: continue
      result.add MoveDoc(
        line: d,
        shape: Shape.Split,
        first: d,
        last: d,
        lines: @[declared, inner & lines[d][at .. ^1]],
        origins: @[d, d],
      )


func movesPlaced(source: string, found: seq[Placement]): seq[MoveDoc] =
  ## Find each doc of declaration that missing doc reads out of place, by its placement in
  ##   `found`: doc above type, field, binding or enum member, which moves where missing doc writes
  ##   it, but above value opening `block`, which is `movesBlock`'s; routine's doc on its
  ##   signature line, after blank line, or off indent of its body.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')

  func isLineDoc(k: int): bool =
    ## Decide whether line `k` holds `##` doc alone.
    k >= 0 and k < lines.len and isDoc(code[k], kept[k])

  # Lines of doc each declaration holds in place, which no doc above takes again.
  var held: seq[int]
  for p in found:
    if p.doc < 0: continue
    held.add p.doc
    var k = p.doc + 1
    while isLineDoc(k):
      held.add k
      inc k

  # Read doc of each declaration from its placement, above it or below routine's signature.
  for p in found:
    let indent = p.first.indentWidth
    if p.kind != KindName.Routine:
      # Doc above, under blank line or comment, that no declaration holds.
      if p.is_block or not p.is_above or p.doc >= 0: continue
      var top = p.line - 1
      while isLineDoc(top) and lines[top].indentWidth == indent: dec top
      if top >= 0 and code[top].strip.len > 0: continue
      if toSeq(top + 1 ..< p.line).anyIt(it in held): continue
      let
        docs = toSeq(top + 1 ..< p.line).mapIt(lines[it].strip)
        (at, shape) = p.target(if docs.len == 1: docs[0] else: '#'.repeat(LINE_MAX))
      var move = MoveDoc(line: p.line, shape: Shape.Above, first: top + 1, last: at, got: p.shown)
      for k in p.line .. at:
        move.lines.add lines[k]
        move.origins.add k
      if shape == ShapeWrite.Join:
        move.lines[^1] = lines[at].strip(leading = false) & ' '.repeat(GAP_COMMENT) & docs[0]
      else:
        for k, doc in docs:
          move.lines.add ' '.repeat(p.indent_body) & doc
          move.origins.add top + 1 + k
      result.add move
      continue

    # Routine's doc opens line after signature, at indent of body: first code line below doc
    #   deeper than routine, else one level in.
    if p.doc < 0 or p.is_forward or p.is_stacked: continue
    if p.is_trailing and p.doc != p.last: continue
    var after = p.doc + 1
    while isLineDoc(after): inc after
    var body = after
    while body < lines.len and lines[body].strip.len == 0: inc body
    let
      indent_body =
        if body < lines.len and lines[body].indentWidth > indent: lines[body].indentWidth
        else: indent + STEP_INDENT
      inner = ' '.repeat(indent_body)
    if p.is_trailing:
      var move = MoveDoc(
        line: p.line,
        shape: Shape.Signature,
        first: p.doc,
        last: after - 1,
        lines: @[lines[p.doc][0 ..< p.offset].strip(leading = false)],
        origins: @[p.doc],
        got: p.shown,
      )
      move.lines.add inner & lines[p.doc][p.offset .. ^1].strip
      move.origins.add p.doc
      for k in p.doc + 1 ..< after:
        move.lines.add inner & lines[k].strip
        move.origins.add k
      result.add move
    elif p.doc > p.last + 1 or
        toSeq(p.doc ..< after).anyIt(lines[it].indentWidth != indent_body):
      var move = MoveDoc(
        line: p.line,
        shape: if p.doc > p.last + 1: Shape.Blank else: Shape.Body,
        first: p.last + 1,
        last: after - 1,
        got: p.shown,
        indent: lines[p.doc].indentWidth,
      )
      for k in p.doc ..< after:
        move.lines.add inner & lines[k].strip
        move.origins.add k
      result.add move


func movesBlock(source: string, valued: seq[ValueBlock]): seq[MoveDoc] =
  ## Find each doc of value opening `block` of `valued` out of its position, own lines above its
  ##   declaration as `#` comment, blank line above them (D1 c of #1020): doc trailing `block:` or
  ##   first in body moves there, `##` above takes `#`, and comment above under other line takes
  ##   blank line. Doc inside with comment above too, and `block` below `=`, whose body needs
  ##   dedent, wait for hand.
  let lines = source.split('\n')
  for b in valued:
    if b.is_below:
      result.add MoveDoc(
        line: b.line,
        shape: Shape.BlockBelow,
        first: b.line,
        last: b.line,
        got: b.shown,
      )
      continue
    let
      margin = ' '.repeat(lines[b.line].indentWidth)
      first = if b.inside >= 0: b.line else: b.above
    var move = MoveDoc(line: b.line, first: first, last: b.line - 1, got: b.shown)
    if b.inside >= 0:
      move.shape = if b.offset >= 0: Shape.BlockAfter else: Shape.BlockInside
      move.last = b.ends
      if b.above < b.line:
        (move.shape, move.first) = (Shape.BlockTwice, b.above)
        result.add move
        continue
    elif b.above == b.line or (b.is_clear and not b.is_hashed): continue
    else: move.shape = if b.is_hashed: Shape.BlockHash else: Shape.BlockBlank

    # Blank line above where none stands, then doc, each `##` as `#`, then declaration's line.
    if not b.is_clear:
      move.lines.add ""
      move.origins.add -1
    let docs = if b.inside >= 0: toSeq(b.inside .. b.ends) else: toSeq(b.above ..< b.line)
    for k in docs:
      let text = if k == b.line: lines[k][b.offset .. ^1].strip else: lines[k].strip
      move.lines.add margin & (
        if text.startsWith("##"): "#" & text.strip(trailing = false, chars = {'#'}) else: text
      )
      move.origins.add k
    if b.inside >= 0:
      move.lines.add(
        if b.offset >= 0: lines[b.line][0 ..< b.offset].strip(leading = false) else: lines[b.line]
      )
      move.origins.add b.line
    result.add move


func movesDoc(source: string): seq[MoveDoc] =
  ## Find each doc out of its position (VI.9; STYLE.md §5), by line it hangs from, by its
  ##   placement, and for value opening `block`, in order of first line each replaces.
  let
    found = source.placements
    declaring = source.sections
    valued = source.blocks(found, declaring)
  (source.movesLine(valued, declaring) & source.movesPlaced(found) & source.movesBlock(valued)).
    sortedByIt((it.first, it.line))


func checkDocs*(path, source: string): seq[Report] =
  ## Report doc of type, field, binding, enum member, routine or `type` section out of its
  ##   position (VI.9; STYLE.md §5).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for move in source.movesDoc:
    let message =
      case move.shape
      of Shape.Join:
        "One-line doc stands on its declaration's line where it fits; got it on next line."
      of Shape.Split:
        "Doc widening its line past `" & $LINE_MAX & "` takes next line; got it on " &
          "declaration's line."
      of Shape.Indent: "Doc on next line stands one level in; got indent `" & $move.indent & "`."
      of Shape.Above:
        "Doc stands after its declaration, never above it; got it above `" & move.got & "`."
      of Shape.Inside:
        "Doc of value over lines stands after `=` ending its first line; got it below `" &
          move.got & "`."
      of Shape.Close:
        "Doc of value over brackets stands after its close; got it below `" & move.got & "`."
      of Shape.BlockInside:
        "Doc of value opening `block` stands above its declaration, as `#` comment; got it " &
          "inside block of `" & move.got & "`."
      of Shape.BlockAfter:
        "Doc of value opening `block` stands above its declaration, as `#` comment; got it " &
          "after `block:` of `" & move.got & "`."
      of Shape.BlockHash:
        "Doc above value opening `block` is `#` comment, since `nim doc` reads none there; got " &
          "`##` above `" & move.got & "`."
      of Shape.BlockBlank:
        "Doc above value opening `block` takes blank line above it; got no blank line above " &
          "doc of `" & move.got & "`."
      of Shape.BlockTwice:
        "Doc of value opening `block` stands above its declaration, as one `#` comment; got " &
          "comment above `" & move.got & "` and other doc of it, which hand joins."
      of Shape.BlockBelow:
        "Value opening `block` keeps `block:` on its `=` line, so body takes one indent; got " &
          "`block` below `=` of `" & move.got & "`, whose body hand dedents."
      of Shape.Signature:
        "Doc of routine stands on line after its signature; got it on signature line of `" &
          move.got & "`."
      of Shape.Blank:
        "Doc of routine stands on line right after its signature; got blank line above it in `" &
          move.got & "`."
      of Shape.Body:
        "Doc of routine stands at indent of its body; got indent `" & $move.indent & "` in `" &
          move.got & "`."
      of Shape.Group: "Group doc of `type` section stands on keyword line; got it on next line."
    result.add initReport(path, move.line + 1, Rule.PositionDoc, message)


func fixDocs*(path, source: string): Fix =
  ## Move each doc check reports, last first, but those left for hand and any whose lines one
  ##   moved before holds; each new line traces to line it came from.
  var
    moves: seq[MoveDoc]
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for move in source.movesDoc:
    if move.lines.len == 0: continue
    if moves.len > 0 and move.first <= moves[^1].last: continue
    moves.add move
  for move in moves.reversed:
    let traced = move.origins.mapIt(if it < 0: 0 else: origin[it])
    lines = lines[0 ..< move.first] & move.lines & lines[move.last + 1 .. ^1]
    origin = origin[0 ..< move.first] & traced & origin[move.last + 1 .. ^1]
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
