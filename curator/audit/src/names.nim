## Enforce declared names (Article III.5, V.1, V.3-V.6, V.9-V.12; GUIDE.md, Names).
##   Reads declarations alone: binding (`let`, `var`, `const`, `for`, `except … as`), routine,
##     type, field, parameter, enum member and placeholder in generic brackets. Name library
##     owns reaches code only at use site, which is never read, so library clause of V.9 holds
##     by construction. Foreign binding, i.e. routine carrying `importc`, `importcpp`,
##     `importjs` or `dynlib`, declares library's own name and is skipped for same reason; its
##     parameters are ours and are read.
##   Word is run between `_` and case changes; acronym is run of two or more capitals inside
##     camel or Pascal name. SCREAMING name is all capitals, so its acronyms cannot be told
##     from words and hold by reading.
##   Table `ABBREVIATIONS` gives each banned word its one replacement, as `english.nim` does
##     for prose; word outside table passes, and reading catches rest. `JARGON` is closed list
##     of V.6. Caller adds symbols glossaries list under `## Standards` as code spans, and
##     their `**Term**` names, through `glossaryExemptions`.
##   V.1, V.11, V.12: case follows kind. Type and enum member are Pascal, routine camel, local,
##     parameter and field snake, global SCREAMING, placeholder one capital. Pascal opens on
##     capital, camel and snake on none; Pascal and camel hold no `_`, snake no capital,
##     SCREAMING no lowercase. One letter fits by its own case: capital passes type, global and
##     placeholder, lowercase passes routine, local, parameter and field. Plain ASCII is no
##     notation, so capital local is finding (Architect's ruling).
##   III.5: source's notation is variable's name holding non-ASCII letter: binding, field or
##     parameter. It holds over case at any scope, so its case is unread; at module scope it
##     holds only for immutable global, so mutable global in notation is finding. Type,
##     routine, member and placeholder are no variable, and their case is read; mathematical
##     letters carry no case in `std/unicode`, so `letterCase` reads them by block. Operator is
##     backticked, so it is never read as name.
##   V.10: reach of binding is decided in `reachOf` alone. Global where every enclosing block
##     opens no scope (`when` chain, bare `let`, `var`, `const` or `type`); local under routine
##     or any other block; entry inside top-level `when isMainModule:` and outside routine.
##     Entry block holds no binding, so binding there is one finding, its case unjudged.
##     Global shares no word with type, compared without case and underscores, as Nim does.
##   V.12: parameter typed `typedesc` is parameter, so snake (Architect's ruling); one capital
##     is for placeholder in brackets after routine or type name, and after `concept`.
##   V.4: boolean binding, field or parameter opens `is`, `as`, `should`, `found` or `has`,
##     with word after it. `func` returning `bool` is predicate and opens `is`. `proc`
##     returning `bool` reports success of action (V.3), so it is unread (Architect's ruling);
##     `func` writing `var` parameter is action too, and is unread for same reason.
##   V.3: routine never opens with `get`, `compute` or `new`. V.5: name opening `lut` reads
##     `lut_<value>_by_<key>`.
##
##   V.6 has fixer (`koch fix`): `abbreviationRenames` reads each declaration coining
##     abbreviation and its full spelling, case kept, as check reads it, and rename planner of
##     `rewrites.nim` renames it at every use through semantic pass, or refuses with reason.
##   V.1 and V.11 have fixer: `renamesCase` reads each declaration whose case check reports, and
##     spells it in case of its kind word by word (`cased`), abbreviation spelled out too; same
##     planner renames it. Binding of entry block that moves takes case of local it becomes.
##     Fix refuses before planner where meaning would leave text: name foreign code reads by
##     spelling (`MARKS_FOREIGN` on its line, on its type, or `{.push.}` over it), member
##     without own string, whose `$` reads its name, name line declares twice, and new name
##     reading as new acronym. Parameter of foreign routine is renamed: call passes it by place.
##   V.10 has fixer: `fixBlockEntry` moves body of entry block into `proc main` above it, doc
##     `TODO: Document.` (VI.1), and leaves block calling `main()`; body keeps lines and indent.
##     `blockEntry` refuses block routine would read otherwise: guard beyond `isMainModule`,
##     which would compile body where guard fails; `{.global.}`, `{.threadvar.}` or foreign
##     pragma; statement or export marker module level holds alone, at any depth; `quit` with
##     value at block's own indent, whose code `quit main()` would carry; and `main` named
##     already.
##
##   Rejected: `proc main` inside block, which V.10 allows; STYLE.md §1 and every program of
##     tree put it at module level, and block then holds one call.
##   Rejected: placeholder rename (V.12), since initial of what it ranges over is choice.
##   Cost: field and type renamed change what `$`, `%` and `fieldPairs` print of them; member
##     is refused for that reason, since its `$` is commonly output. Reading holds rest.
##   Cost: value bound in moved block lives on stack, not in static storage; large array
##     there can overflow stack, which `nim check` never reads.
##
##   Cost: text scanner, never parser. Comments and strings are blanked first; multi-line
##     signature is joined to its closing parenthesis; object variant branch is read as fields
##     where it sits in `type` block; tuple type in brackets, and name `{.inject.}` makes, are
##     unread.
##   Cost: boolean is read only where declaration shows it: type `bool`, or value literal
##     `true` or `false`. Boolean from call or expression holds by reading.
##   Cost: `in` calls `contains` by spelling, so predicate of that name keeps host's name.
##   Cost: Pascal name of capitals alone, e.g. `ANTI`, reads as acronym and passes; V.9 and
##     reading hold it. Letter outside `std/unicode` case tables and mathematical block carries
##     no case, so it fits every casing.
##   Cost: word table is short list; `english.nim` pays same cost.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
from std/unicode import isLower, isUpper, Rune, runes
import ../../knoller/src/knoller
import ./[findings, glossary]


type
  NameKind* {.pure.} = enum  ## Define what declaration introduces name.
    Binding, Routine, Type, Field, Parameter, Member, Placeholder

  Reach* {.pure.} = enum  ## Define how far binding reaches, which fixes its case (V.1, V.10).
    Local  ## Inside routine or block opening scope; every name not binding.
    Global  ## At module level, under blocks opening no scope.
    Entry  ## Inside entry block, i.e. top-level `when isMainModule:`, outside routine.

  Casing* {.pure.} = enum  ## Define case one kind of name takes (V.1, V.11, V.12).
    Pascal, Camel, Snake, Screaming, Letter

  LetterCase {.pure.} = enum  ## Define case of one letter; digit and symbol carry none.
    None, Lower, Upper

  Declared* = object  ## Define one declared name with its place.
    name*: string
    line*: int
    kind*: NameKind
    reach*: Reach  ## Binding's reach; `Local` for every other kind.
    is_mutable*: bool  ## Binding by `var`, which notation never excuses (III.5).
    is_boolean*: bool  ## Shows `bool` by type or literal value, or `func` returns it (V.4).

  Opener = object  ## Define block enclosing line, by its opening line.
    indent: int
    head: string  ## First word of opening line.
    is_scope_free: bool  ## Block opens no scope: `when` chain, or bare section keyword.
    is_entry: bool  ## Top-level `when isMainModule:`, where module runs as program.
    substituted: seq[string]  ## Parameters of template, which its body names in place of argument.

  RenameCase* = object
    ## Define rename case of declaration's kind asks (V.1, V.11), or why fix leaves it to hand.
    line*: int  ## One-based line of declared name.
    column*: int  ## Zero-based byte column of declared name.
    name*: string  ## Name as declared.
    renamed*: string  ## Name in case of its kind, each coined abbreviation spelled out (V.6).
    rule*: string  ## Rule report names, e.g. `local constant case (V.1)`.
    refusal*: string  ## Why fix leaves rename to hand before semantic pass reads it; empty if none.
    is_local*: bool  ## Binding no other module can name: local, or binding of entry block.

  BlockEntry* = object
    ## Define entry block of module, bindings it holds, and why fix cannot move its body (V.10).
    head: int  ## Zero-based line of `when isMainModule:`; `-1` where none is read.
    first: int  ## Zero-based first line of body, leading blank lines left out.
    last: int  ## Zero-based last line of body; comment opening line below it stays below block.
    indent: int  ## Indent of body's first line of code.
    bindings*: seq[(int, string)]  ## One-based line and name of each binding block holds.
    refusal*: string  ## Why fix leaves block to hand; empty where body moves into `proc main`.


const
  ABBREVIATIONS* = [
    ("ctx", "context"), ("tmp", "temporary"), ("buf", "buffer"), ("cfg", "configuration"),
    ("dir", "directory"), ("args", "arguments"), ("err", "error"), ("dest", "destination"),
    ("avail", "available"), ("verts", "vertices"), ("attrib", "attribute"),
  ]
    ## Coined abbreviation and its one full word (V.6).
  JARGON* = ["lut", "min", "max", "src", "prev", "curr", "len"]
    ## Closed list of V.6, which Architect alone extends.
  VERBS_BANNED* = ["get", "compute", "new"]  ## First words routine never takes (V.3).
  BOOLEAN_PREFIXES* = ["is", "as", "should", "found", "has"]
    ## First words boolean takes: state, interpretation, policy, search outcome, possession (V.4).
  VARIABLE_KINDS = {NameKind.Binding, NameKind.Field, NameKind.Parameter}
    ## Kinds naming variable, which source's notation may name at any scope (III.5).
  HOST_PREDICATES = ["contains"]
    ## Predicates host calls by spelling: `in` and `notin` call `contains`.
  ROUTINE_KEYWORDS = ["proc", "func", "iterator", "template", "macro", "converter", "method"]
    ## Keywords opening routine declaration.
  BINDING_KEYWORDS = ["let", "var", "const"]  ## Keywords opening binding, single or section.
  SECTION_KEYWORDS = ["let", "var", "const", "type"]
    ## Keywords that, alone on line, open section and no scope.
  CHAIN_WORDS = ["when", "elif", "else"]  ## Words opening branch of `when` chain.
  CONCEPT_MODIFIERS = ["var", "ref", "ptr", "type"]  ## Words standing before concept placeholder.
  IDENT_CHARS = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}
    ## ASCII characters identifier is built from; raw string prefix is one of them.
  NAME_CHARS = IDENT_CHARS + {'\x80' .. '\xFF'}
    ## Bytes declared name is built from: Nim reads every non-ASCII byte as letter.
  FOREIGN_PRAGMAS = ["importc", "importcpp", "importjs", "dynlib"]
    ## Pragmas marking routine as binding of library's own name.
  CASE_RULES: array[Casing, string] = [
    "is `PascalCase`", "is `lowerCamelCase`", "is `snake_case`", "is `SCREAMING_SNAKE_CASE`",
    "is one capital letter",
  ]
    ## Predicate of each casing, as finding states it.
  MAIN_GUARD* = "when isMainModule:"  ## Block that makes module entry of program (STYLE.md §1).
  MARKS_FOREIGN = [
    "dynlib", "exportc", "exportcpp", "extern", "header", "importc", "importcpp", "importjs",
    "importobjc", "JsRoot",
  ]
    ## Words marking name foreign code reads by its spelling: pragma, or root of JavaScript object.
  PRAGMAS_MODULE = [
    "dynlib", "exportc", "exportcpp", "extern", "global", "header", "importc", "importcpp",
    "importjs", "importobjc", "threadvar",
  ]
    ## Pragmas binding name at module level alone, or across foreign boundary, never in routine.
  KEYWORDS_MODULE = ["converter", "export", "from", "import", "include", "method"]
    ## Keywords opening statement module level holds alone, or bringing what routine may not
    ##   hold, as `include` brings exported declarations.
  ROUTINE_ENTRY = "main"  ## Routine entry block calls (V.10).


func blanked(source: string, should_keep_comments: bool): string =
  ## Blank string and char literals, and comments unless kept, keeping every newline and length.
  ##   Nim forms: `#` to end of line, `#[ ]#` nesting, `"..."` with escapes, `"""..."""`,
  ##     raw `r"..."` with `""` escape, and `'c'`.
  result = newString(source.len)
  var
    i = 0
    depth = 0

  template blank(n: int) =
    for k in 0 ..< n:
      result[i] = (if source[i] == '\n': '\n' else: ' ')
      inc i

  template comment(n: int) =
    if should_keep_comments:
      for k in 0 ..< n:
        result[i] = source[i]
        inc i
    else: blank(n)

  while i < source.len:
    let c = source[i]
    if depth > 0:
      if c == ']' and i + 1 < source.len and source[i + 1] == '#':
        dec depth
        comment(2)
      elif c == '#' and i + 1 < source.len and source[i + 1] == '[':
        inc depth
        comment(2)
      else: comment(1)
      continue
    if c == '#':
      if i + 1 < source.len and source[i + 1] == '[':
        inc depth
        comment(2)
      else:
        while i < source.len and source[i] != '\n': comment(1)
      continue
    if c == '"':
      let is_raw = i > 0 and source[i - 1] in IDENT_CHARS
      if i + 2 < source.len and source[i + 1] == '"' and source[i + 2] == '"':
        blank(3)
        while i < source.len:
          if source[i] == '"' and i + 2 < source.len and source[i + 1] == '"' and
              source[i + 2] == '"':
            blank(3)
            break
          blank(1)
      else:
        blank(1)
        while i < source.len and source[i] != '\n':
          if source[i] == '\\' and not is_raw and i + 1 < source.len: blank(2)
          elif source[i] == '"':
            if is_raw and i + 1 < source.len and source[i + 1] == '"': blank(2)
            else:
              blank(1)
              break
          else: blank(1)
      continue
    if c == '\'' and i + 2 < source.len and (source[i + 2] == '\'' or source[i + 1] == '\\'):
      blank(1)
      while i < source.len and source[i] != '\'' and source[i] != '\n':
        if source[i] == '\\' and i + 1 < source.len: blank(2) else: blank(1)
      if i < source.len and source[i] == '\'': blank(1)
      continue
    result[i] = c
    inc i


func codeOnly*(source: string): string =
  ## Blank comments and string and char literals, keeping every newline and length.
  source.blanked(should_keep_comments = false)


func codeAndComments*(source: string): string =
  ## Blank string and char literals alone, so every `#` left opens, holds or closes comment.
  source.blanked(should_keep_comments = true)


func indentOf*(line: string): int =
  ## Count leading spaces.
  for c in line:
    if c != ' ': return
    inc result


func identifierAt(text: string, start: int): string =
  ## Read identifier opening at index, after optional spaces; empty where none.
  var i = start
  while i < text.len and text[i] == ' ': inc i
  var j = i
  while j < text.len and text[j] in NAME_CHARS: inc j
  text[i ..< j]


func nameOf(piece: string): string =
  ## Read declared name from `name`, `name*`, `name: T`, `name = v`, `name {.pragma.}`.
  piece.strip.identifierAt(0)


func splitTop(text: string, separators: set[char]): seq[string] =
  ## Split text at separators outside brackets, so `array[2, int]` stays one piece.
  var
    depth = 0
    piece = ""
  for c in text:
    if c in {'(', '[', '{'}: inc depth
    elif c in {')', ']', '}'}: dec depth
    if depth == 0 and c in separators:
      result.add piece
      piece = ""
    else: piece.add c
  result.add piece


func topIndex(text: string, mark: char, start = 0): int =
  ## Find first `mark` outside brackets from index on; `-1` where none.
  var depth = 0
  for k in start ..< text.len:
    let c = text[k]
    if c in {'(', '[', '{'}: inc depth
    elif c in {')', ']', '}'}: dec depth
    elif c == mark and depth == 0: return k
  -1


func closing(text: string, open: int): int =
  ## Find bracket closing one opened at index; `-1` where text ends first.
  var depth = 0
  for k in open ..< text.len:
    if text[k] in {'(', '[', '{'}: inc depth
    elif text[k] in {')', ']', '}'}:
      dec depth
      if depth == 0: return k
  -1


func bindingSide(text: string): string =
  ## Cut binding text at its first `=` outside brackets, so value never reads as name.
  let at = text.topIndex('=')
  if at < 0: text else: text[0 ..< at]


func isBooleanShown(text: string): bool =
  ## Decide whether declaration shows boolean: type `bool`, or value literal `true` or `false`.
  let
    at = text.topIndex('=')
    side = text.bindingSide
    colon = side.topIndex(':')
    value = if at < 0: "" else: text[at + 1 .. ^1].strip
  (colon >= 0 and side[colon + 1 .. ^1].strip == "bool") or value in ["true", "false"]


func bindingNames(text: string): seq[string] =
  ## Read names text binds: `a`, `a, b: T`, `(a, b) = v`, `a {.used.} = v`.
  for piece in text.bindingSide.strip(chars = {' ', '(', ')'}).splitTop({','}):
    let name = piece.strip(chars = {' ', '(', ')'}).nameOf
    if name.len > 0 and name != "_": result.add name


func parameterNames(signature: string): seq[(string, bool)] =
  ## Read parameters of text between parentheses, each with whether it shows boolean.
  ##   `x, y: T; z = false` gives `x`, `y` and `z`, which is boolean; group shares its type.
  let pieces = signature.splitTop({',', ';'})
  var group: seq[string]
  for k, piece in pieces:
    let name = piece.nameOf
    if name.len > 0 and name != "_" and name != "var": group.add name
    if ':' in piece or '=' in piece or k == pieces.high:
      let is_boolean = piece.isBooleanShown
      for member in group: result.add (member, is_boolean)
      group = @[]


func isWriting(signature: string): bool =
  ## Decide whether text between parentheses takes `var` parameter, which routine writes.
  for piece in signature.splitTop({',', ';'}):
    let at = piece.topIndex(':')
    if at >= 0 and piece[at + 1 .. ^1].identifierAt(0) == "var": return true
  false


func placeholderNames(text: string): seq[string] =
  ## Read placeholders of generic brackets or concept: `T`, `A, B: X`, `var C`, `N: static int`.
  for piece in text.splitTop({',', ';'}):
    var words = piece.strip.splitWhitespace
    while words.len > 1 and words[0] in CONCEPT_MODIFIERS: words.delete(0)
    if words.len == 0: continue
    let name = words.join(" ").nameOf
    if name.len > 0: result.add name


func readType(text: string, line: int, names: var seq[Declared]): NameKind =
  ## Read type's name and placeholders, and enum's members on its line; give kind lines below
  ##   declare: `Member` under enum, `Field` under object or alias, `Placeholder` under concept.
  let name = text.identifierAt(0)
  if name.len == 0: return NameKind.Field
  names.add Declared(name: name, line: line, kind: NameKind.Type)
  var k = name.len
  if k < text.len and text[k] == '*': inc k
  if k < text.len and text[k] == '[' and text.closing(k) > k:
    for p in text[k + 1 ..< text.closing(k)].placeholderNames:
      names.add Declared(name: p, line: line, kind: NameKind.Placeholder)
  let
    at = text.topIndex('=')
    value = if at < 0: "" else: text[at + 1 .. ^1].strip
    head = value.identifierAt(0)
  if head == "enum":
    for m in value[head.len .. ^1].splitTop({','}):
      if m.nameOf.len > 0: names.add Declared(name: m.nameOf, line: line, kind: NameKind.Member)
    return NameKind.Member
  if head == "concept":
    for p in value[head.len .. ^1].placeholderNames:
      names.add Declared(name: p, line: line, kind: NameKind.Placeholder)
    return NameKind.Placeholder
  NameKind.Field


func isOpening(lines: openArray[string], i: int): bool =
  ## Decide whether next non-blank line sits deeper than line `i`, i.e. line opens block.
  var k = i + 1
  while k < lines.len and lines[k].strip.len == 0: inc k
  k < lines.len and lines[k].indentOf > lines[i].indentOf


func isSubstituted(openers: openArray[Opener], name: string): bool =
  ## Decide whether enclosing template substitutes name, so declaration there declares argument.
  openers.anyIt(name in it.substituted)


func reachOf(openers: openArray[Opener], is_scoped = false): Reach =
  ## Decide reach of binding under enclosing blocks, outermost first (V.1, V.10).
  ##   Routine makes local, entry block makes entry, and so does binding opening own scope
  ##     there (`for`, `except … as`). Global needs every enclosing block to open no scope.
  if openers.anyIt(it.head in ROUTINE_KEYWORDS): return Reach.Local
  if openers.anyIt(it.is_entry): return Reach.Entry
  if is_scoped or not openers.allIt(it.is_scope_free): return Reach.Local
  Reach.Global


func declarations*(source: string): seq[Declared] =
  ## Read every declared name of Nim source with its line, kind and reach.
  let lines = source.codeOnly.splitLines
  var
    openers: seq[Opener]
    section_indent = -1
    section_child = -1
    is_section_mutable = false
    type_indent = -1
    object_indent = -1
    enum_indent = -1
    i = 0
  while i < lines.len:
    let
      line = lines[i]
      s = line.strip
      indent = line.indentOf
      one = i + 1
    if s.len == 0:
      inc i
      continue

    # Close blocks line leaves; branch of `when` chain keeps chain's freedom from scope.
    var closed = Opener(indent: -1)
    while openers.len > 0 and openers[^1].indent >= indent:
      let top = openers.pop
      if top.indent == indent: closed = top
    if section_indent >= 0 and indent <= section_indent:
      section_indent = -1
      section_child = -1
    if type_indent >= 0 and indent <= type_indent: type_indent = -1
    if object_indent >= 0 and indent <= object_indent: object_indent = -1
    if enum_indent >= 0 and indent <= enum_indent: enum_indent = -1
    let
      word = s.identifierAt(0)
      rest = s[word.len .. ^1]
      is_chain = word in ["elif", "else"] and closed.indent == indent and
        closed.is_scope_free and closed.head in CHAIN_WORDS
      opener = Opener(
        indent: indent,
        head: word,
        is_scope_free: word == "when" or is_chain or (s == word and word in SECTION_KEYWORDS),
        is_entry: indent == 0 and word == "when" and "isMainModule" in s,
      )
      is_opening = lines.isOpening(i)
    var
      next = i + 1
      substituted: seq[string]

    block reading:
      if word in ROUTINE_KEYWORDS and rest.len > 0 and rest[0] == ' ':
        # Signature runs to matching parenthesis, across lines; pragmas follow it on same line.
        var
          text = s
          j = i
        while text.count('(') > text.count(')') and j + 1 < lines.len:
          inc j
          text.add lines[j]
        # Pragma block may open on its own line after balanced signature.
        if j + 1 < lines.len and lines[j + 1].strip.startsWith("{."):
          inc j
          text.add lines[j]
        next = j + 1

        # Walk name, placeholders, parameters, then return type; backticked name is operator.
        var k = word.len
        while k < text.len and text[k] == ' ': inc k
        var name = ""
        if k < text.len and text[k] == '`':
          let close = text.find('`', k + 1)
          k = (if close < 0: text.len else: close + 1)
        else:
          name = text.identifierAt(k)
          k += name.len
        if k < text.len and text[k] == '*': inc k
        if k < text.len and text[k] == '[' and text.closing(k) > k:
          for p in text[k + 1 ..< text.closing(k)].placeholderNames:
            result.add Declared(name: p, line: one, kind: NameKind.Placeholder)
          k = text.closing(k) + 1
        while k < text.len and text[k] == ' ': inc k
        var is_writing = false
        if k < text.len and text[k] == '(' and text.closing(k) > k:
          let signature = text[k + 1 ..< text.closing(k)]
          for (p, is_boolean) in signature.parameterNames:
            if word == "template": substituted.add p
            result.add Declared(
              name: p,
              line: one,
              kind: NameKind.Parameter,
              is_boolean: is_boolean,
            )
          is_writing = signature.isWriting
          k = text.closing(k) + 1

        # Predicate is `func` returning `bool` that writes no `var` parameter; else action.
        let
          tail = text[min(k, text.len) .. ^1].strip
          is_predicate = word == "func" and not is_writing and tail.startsWith(":") and
            tail.identifierAt(1) == "bool"
          is_foreign = FOREIGN_PRAGMAS.anyIt(it in text)
        if name.len > 0 and not is_foreign:
          result.add Declared(
            name: name,
            line: one,
            kind: NameKind.Routine,
            is_boolean: is_predicate,
          )
        break reading

      if word == "type" and rest.strip.len == 0:
        type_indent = indent
        break reading
      if word == "type" or (type_indent >= 0 and indent == type_indent + 2):
        if "=" in s:
          var read: seq[Declared]
          let below = (if word == "type": rest.strip else: s).readType(one, read)
          result.add read.filterIt(
            not (it.kind == NameKind.Type and openers.isSubstituted(it.name)),
          )
          if below == NameKind.Member: enum_indent = indent
          elif below == NameKind.Field: object_indent = indent
        break reading

      if enum_indent >= 0 and indent > enum_indent:
        for m in s.splitTop({','}):
          if m.nameOf.len > 0:
            result.add Declared(name: m.nameOf, line: one, kind: NameKind.Member)
        break reading

      if object_indent >= 0 and indent > object_indent:
        # Field side runs to its type; `case` names variant's discriminator.
        let text = if word == "case": rest else: s
        if word notin ["of", "else", "elif", "when"] and text.topIndex(':') > 0:
          for name in text[0 ..< text.topIndex(':')].splitTop({','}):
            if name.nameOf.len > 0:
              result.add Declared(
                name: name.nameOf,
                line: one,
                kind: NameKind.Field,
                is_boolean: text.isBooleanShown,
              )
        break reading

      if word in BINDING_KEYWORDS:
        if rest.strip.len == 0:
          section_indent = indent
          is_section_mutable = word == "var"
        else:
          for name in rest.bindingNames:
            if openers.isSubstituted(name): continue
            result.add Declared(
              name: name,
              line: one,
              kind: NameKind.Binding,
              reach: openers.reachOf,
              is_mutable: word == "var",
              is_boolean: rest.isBooleanShown,
            )
        break reading

      if section_indent >= 0 and indent > section_indent:
        # First line under keyword fixes child indent; deeper line continues value above it.
        if section_child < 0: section_child = indent
        if indent == section_child and (s.topIndex(':') > 0 or s.topIndex('=') > 0):
          for name in s.bindingNames:
            if openers.isSubstituted(name): continue
            result.add Declared(
              name: name,
              line: one,
              kind: NameKind.Binding,
              reach: openers.reachOf,
              is_mutable: is_section_mutable,
              is_boolean: s.isBooleanShown,
            )
        break reading

      if word == "for":
        let at = rest.find(" in ")
        if at > 0:
          for name in rest[0 ..< at].bindingNames:
            result.add Declared(
              name: name,
              line: one,
              kind: NameKind.Binding,
              reach: openers.reachOf(is_scoped = true),
            )
        break reading

      if word == "except":
        let at = rest.find(" as ")
        if at >= 0:
          let name = rest[at + 4 .. ^1].strip(chars = {' ', ':'}).nameOf
          if name.len > 0:
            result.add Declared(
              name: name,
              line: one,
              kind: NameKind.Binding,
              reach: openers.reachOf(is_scoped = true),
            )

    if is_opening:
      var held = opener
      held.substituted = substituted
      openers.add held
    i = next


func wordSpans(name: string): seq[(int, int)] =
  ## Read span of each word of name, split at `_` and at case changes.
  var first = -1  # Index current word opens at; `-1` between words.
  for k, c in name:
    if c == '_':
      if first >= 0: result.add (first, k)
      first = -1
      continue
    if first < 0:
      first = k
      continue
    let is_boundary = (c in {'A' .. 'Z'} and name[k - 1] in {'a' .. 'z', '0' .. '9'}) or
      (c in {'a' .. 'z'} and k - first > 1 and name[k - 1] in {'A' .. 'Z'} and
        name[k - 2] in {'A' .. 'Z'})
    if not is_boundary: continue
    # Capital before lowercase starts new word: `JSONData` is JSON, Data.
    let cut = if c in {'a' .. 'z'}: k - 1 else: k
    result.add (first, cut)
    first = cut
  if first >= 0: result.add (first, name.len)


func words*(name: string): seq[string] =
  ## Split name at `_` and at case changes: `lut_grade`, `wedgeAnti`, `JSONData` give words.
  name.wordSpans.mapIt(name[it[0] ..< it[1]])


func fullWordOf(word: string, lower_exempt: openArray[string]): string =
  ## Read full word `ABBREVIATIONS` gives coined abbreviation, in word's own case; empty where
  ##   word is none, or exempt.
  let lower = word.toLowerAscii
  if lower in lower_exempt or lower in JARGON: return
  for (short, full) in ABBREVIATIONS:
    if lower != short: continue
    if word == lower: return full
    if word == word.toUpperAscii: return full.toUpperAscii
    return full.capitalizeAscii


func respelled*(name: string, exempt: openArray[string]): string =
  ## Spell name with each coined abbreviation written out, case kept (V.6): `ctx_dir` gives
  ##   `context_directory`, `bufSize` gives `bufferSize`. Same name where it coins none.
  let lower_exempt = exempt.mapIt(it.toLowerAscii)
  result = name
  for (first, after) in name.wordSpans.reversed:
    let full = name[first ..< after].fullWordOf(lower_exempt)
    if full.len > 0: result = result[0 ..< first] & full & result[after .. ^1]


func abbreviationRenames*(
  source: string, exempt: openArray[string]
): seq[(int, int, string, string)] =
  ## Read one-based line, zero-based byte column, name and full spelling of each declared name
  ##   coining abbreviation (V.6), as `checkNames` reads them.
  let
    tokens = source.tokens
    starts = source.lineStarts
  for d in source.declarations:
    let renamed = d.name.respelled(exempt)
    if renamed == d.name: continue
    for t in tokens:
      if t.line == d.line - 1 and t.kind == TokenKind.Word and t.spelling(source) == d.name:
        result.add (d.line, t.first - starts[t.line], d.name, renamed)
        break


func letterCase(r: Rune): LetterCase =
  ## Read case of letter, mathematical alphanumerics by block, since `std/unicode` maps none.
  ##   Latin styles run 52 letters, 26 capitals first; Greek styles run 58, 25 capitals first,
  ##     then nabla, 25 small, partial differential and 6 small variants.
  let c = int(r)
  if c in 0x1D400 .. 0x1D6A3:
    return (if (c - 0x1D400) mod 52 < 26: LetterCase.Upper else: LetterCase.Lower)
  if c in 0x1D6A8 .. 0x1D7C9:
    let k = (c - 0x1D6A8) mod 58
    if k < 25: return LetterCase.Upper
    if k in [25, 51]: return LetterCase.None
    return LetterCase.Lower
  if r.isUpper: LetterCase.Upper
  elif r.isLower: LetterCase.Lower
  else: LetterCase.None


func isNotation*(name: string): bool =
  ## Decide whether name is source's notation, i.e. holds non-ASCII letter (III.5).
  name.anyIt(it >= '\x80')


func isCased*(name: string, casing: Casing): bool =
  ## Decide whether name is written in casing; first letter and every letter decide it.
  var
    first = LetterCase.None
    count = 0
    has_upper = false
    has_lower = false
  for r in name.runes:
    let c = r.letterCase
    if count == 0: first = c
    inc count
    has_upper = has_upper or c == LetterCase.Upper
    has_lower = has_lower or c == LetterCase.Lower
  case casing
  of Casing.Pascal: first == LetterCase.Upper and '_' notin name
  of Casing.Camel: first != LetterCase.Upper and '_' notin name
  of Casing.Snake: not has_upper
  of Casing.Screaming: not has_lower
  of Casing.Letter: count == 1 and first == LetterCase.Upper


func casingOf*(d: Declared): Casing =
  ## Read casing declared name takes by its kind and reach (V.1, V.11, V.12).
  case d.kind
  of NameKind.Type, NameKind.Member: Casing.Pascal
  of NameKind.Routine: Casing.Camel
  of NameKind.Field, NameKind.Parameter: Casing.Snake
  of NameKind.Placeholder: Casing.Letter
  of NameKind.Binding: (if d.reach == Reach.Global: Casing.Screaming else: Casing.Snake)


func isMiscased(d: Declared): bool =
  ## Decide whether name breaks case of its kind, as `checkNames` reads it (V.1, V.11, V.12);
  ##   binding of entry block and variable in source's notation carry no case to read.
  if d.kind == NameKind.Binding and d.reach == Reach.Entry: return false
  if d.kind in VARIABLE_KINDS and d.name.isNotation: return false
  not d.name.isCased(d.casingOf)


func acronyms*(name: string): seq[string] =
  ## Read runs of two or more capitals, digits attached, inside camel or Pascal name.
  if name.isCased(Casing.Screaming) or '_' in name: return
  var run = ""
  let text = name & " "
  for k in 0 ..< text.len - 1:
    let
      c = text[k]
      opens_word = c in {'A' .. 'Z'} and text[k + 1] in {'a' .. 'z'}
    if (c in {'A' .. 'Z'} and not opens_word) or (run.len > 0 and c in {'0' .. '9'}): run.add c
    else:
      if run.count({'A' .. 'Z'}) >= 2: result.add run
      run = ""
  if run.count({'A' .. 'Z'}) >= 2: result.add run


func glossaryExemptions*(glossary: string): seq[string] =
  ## Collect code spans under `## Standards` and names of terms, as words name may take.
  var is_standards = false
  for line in glossary.splitLines:
    if line.startsWith("#"): is_standards = line == STANDARDS_HEADING
    if is_standards:
      var i = 0
      while true:
        let open = line.find('`', i)
        if open < 0: break
        let close = line.find('`', open + 1)
        if close < 0: break
        for w in line[open + 1 ..< close].split({' ', ','}):
          if w.len > 0: result.add w
        i = close + 1
    if line.isTermLine: result.add line[2 ..< line.len - 3]


func exemptionsOf*(glossaries: openArray[(string, string)], path: string): seq[string] =
  ## Read words name in path may take beyond table: jargon of V.6, and what root glossary and
  ##   glossary of path's own project list (`glossaryExemptions`).
  result = JARGON.toSeq
  for (glossary, source) in glossaries:
    let directory = glossary[0 ..< glossary.len - ROOT_GLOSSARY.len]
    if glossary == ROOT_GLOSSARY or path.startsWith(directory):
      result.add source.glossaryExemptions


func checkNames*(path, source: string; exempt: openArray[string]): seq[Finding] =
  ## Report declared name that coins abbreviation, carries unlisted acronym, opens routine
  ##   with banned verb, misnames lookup table or boolean, breaks case of its kind, binds in
  ##   entry block, or shares its word with type as global.
  let
    lower_exempt = exempt.mapIt(it.toLowerAscii)
    declared = source.declarations
  var type_keys: seq[string]
  for d in declared:
    if d.kind == NameKind.Type: type_keys.add d.name.toLowerAscii.replace("_", "")
  for d in declared:
    let parts = d.name.words
    for w in parts:
      let full = w.fullWordOf(lower_exempt).toLowerAscii
      if full.len == 0: continue
      result.add finding(
        path,
        d.line,
        "Name coins abbreviation; write `" & full & "` (V.6); got `" & d.name & "`.",
      )
    for a in d.name.acronyms:
      if a.toLowerAscii in lower_exempt: continue
      result.add finding(
        path,
        d.line,
        "Acronym stays only where glossary lists it (V.9); got `" & a & "` in `" & d.name & "`.",
      )
    if d.kind == NameKind.Routine and parts.len > 1 and parts[0] in VERBS_BANNED:
      result.add finding(
        path,
        d.line,
        "Action is imperative verb and property is bare noun (V.3); got `" & d.name & "`.",
      )
    if parts.len > 1 and parts[0].toLowerAscii == "lut" and d.name.toLowerAscii.count("_by_") != 1:
      result.add finding(
        path,
        d.line,
        "Lookup table reads `lut_<value>_by_<key>` (V.5); got `" & d.name & "`.",
      )

    # Boolean is proposition or mode; predicate `func` is `is…` (V.4).
    if d.is_boolean and d.kind == NameKind.Routine:
      if (parts.len < 2 or parts[0] != "is") and d.name notin HOST_PREDICATES:
        result.add finding(
          path,
          d.line,
          "Predicate `func` is `is…` in camel case (V.4); got `" & d.name & "`.",
        )
    elif d.is_boolean and (parts.len < 2 or parts[0].toLowerAscii notin BOOLEAN_PREFIXES):
      result.add finding(
        path,
        d.line,
        "Boolean opens `is_`, `as_`, `should_`, `found_` or `has_` (V.4); got `" & d.name & "`.",
      )

    # Case follows kind; entry binding is reported once, and notation excuses immutable global.
    if d.kind == NameKind.Binding and d.reach == Reach.Entry:
      result.add finding(
        path,
        d.line,
        "Entry block holds no binding; move code that binds into `proc main` " &
          "(V.10); got `" & d.name & "`.",
      )
      continue
    let
      casing = d.casingOf
      is_notation = d.kind in VARIABLE_KINDS and d.name.isNotation
    if is_notation and d.reach == Reach.Global and d.is_mutable:
      result.add finding(
        path,
        d.line,
        "Notation holds over case only for immutable global (III.5); got `" & d.name & "`.",
      )
    elif d.isMiscased:
      let
        rule = if d.kind == NameKind.Member: "V.11" elif casing == Casing.Letter: "V.12" else: "V.1"
        subject = if d.kind == NameKind.Binding: $d.reach else: $d.kind
      result.add finding(
        path,
        d.line,
        subject & " " & CASE_RULES[casing] & " (" & rule & "); got `" & d.name & "`.",
      )
    if d.kind == NameKind.Binding and d.reach == Reach.Global and
        d.name.isCased(Casing.Screaming) and d.name.toLowerAscii.replace("_", "") in type_keys:
      result.add finding(
        path,
        d.line,
        "Global never shares its word with type (V.10); got `" & d.name & "`.",
      )


func cased*(name: string, casing: Casing): string =
  ## Spell name in casing, word by word (V.1, V.11): `localValue` gives `local_value`,
  ##   `Construct_table` gives `constructTable`, `base` gives `Base`.
  ##   Camel and Pascal keep later letters of each word, so `parse_JSON` gives `parseJSON`,
  ##     unless name is capitals alone; `Letter` keeps name, since placeholder's initial is choice.
  let
    parts = name.words
    is_capitals = name.isCased(Casing.Screaming)
  case casing
  of Casing.Snake: result = parts.mapIt(it.toLowerAscii).join("_")
  of Casing.Screaming: result = parts.mapIt(it.toUpperAscii).join("_")
  of Casing.Letter: result = name
  of Casing.Camel, Casing.Pascal:
    for k, part in parts:
      let rest = if is_capitals: part[1 .. ^1].toLowerAscii else: part[1 .. ^1]
      if k == 0 and casing == Casing.Camel: result.add part.toLowerAscii
      else: result.add part[0].toUpperAscii & rest


func identity(name: string): string =
  ## Read name as Nim compares it: first character exact, rest without case and underscores.
  if name.len == 0: "" else: name[0] & name[1 .. ^1].replace("_", "").toLowerAscii


func wordsOf(line: string): seq[string] =
  ## Read identifiers of one line of code view.
  var word = ""
  for c in line & " ":
    if c in NAME_CHARS: word.add c
    elif word.len > 0:
      result.add word
      word = ""


func blockEntry*(source: string): BlockEntry =
  ## Read entry block of module, each binding it holds, and why fix cannot move its body into
  ##   `proc main` (V.10): more than one block, guard beyond `isMainModule`, pragma or statement
  ##   no routine holds, export marker, `quit` with value at block's own indent, or `main` taken.
  ##   Block binding nothing reads no refusal, since nothing moves.
  result.head = -1
  for d in source.declarations:
    if d.kind == NameKind.Binding and d.reach == Reach.Entry: result.bindings.add (d.line, d.name)
  if result.bindings.len == 0: return
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
  var heads: seq[int]
  for i, line in code:
    if line.indentOf == 0 and line.identifierAt(0) == "when" and "isMainModule" in line:
      heads.add i
  if heads.len != 1:
    result.refusal = "module holds `" & $heads.len & "` entry blocks"
    return
  result.head = heads[0]
  if code[result.head].strip != MAIN_GUARD:
    result.refusal = "`" & code[result.head].strip & "` guards more than `isMainModule`"
    return

  # Body runs to first line of code at indent 0; comment opening its line there stays below.
  var stop = result.head + 1
  while stop < code.len and (code[stop].strip.len == 0 or code[stop].indentOf > 0): inc stop
  result.first = result.head + 1
  while lines[result.first].strip.len == 0: inc result.first
  for t in tokens:
    if t.line <= result.head or t.line >= stop: continue
    if t.kind == TokenKind.Comment and t.first == starts[t.line]: continue
    result.last = max(result.last, t.lastLine(source))
  for i in result.first .. result.last:
    if code[i].strip.len == 0: continue
    result.indent = code[i].indentOf
    break

  # Refuse what routine cannot hold, or would read otherwise than block.
  for k, t in tokens:
    if t.line < result.first or t.line > result.last: continue
    if t.kind == TokenKind.Open and t.spelling(source) == "{." and partners[k] > k:
      for m in k + 1 ..< partners[k]:
        let word = tokens[m].spelling(source)
        if tokens[m].kind == TokenKind.Word and word in PRAGMAS_MODULE:
          result.refusal = "`{." & word & ".}` binds at module level alone"
          return
    let is_marker = t.kind == TokenKind.Operator and t.spelling(source) == "*" and k > 0 and
      tokens[k - 1].kind == TokenKind.Word and tokens[k - 1].after == t.first
    if is_marker:
      result.refusal = "export marker of `" & tokens[k - 1].spelling(source) &
        "` stands at module level alone"
      return
  for i in result.first .. result.last:
    if code[i].strip.len == 0: continue
    let
      word = code[i].identifierAt(0)
      rest = code[i].strip[word.len .. ^1].strip
    if word in KEYWORDS_MODULE:
      result.refusal = "`" & word & "` stands at module level alone"
      return
    if code[i].indentOf == result.indent and word == "quit" and rest notin ["", "()"]:
      result.refusal = "`quit` at block's own indent returns value, which `quit main()` would carry"
      return
  for t in tokens:
    if t.kind == TokenKind.Word and t.spelling(source).identity == ROUTINE_ENTRY:
      result.refusal = "`" & t.spelling(source) & "` stands in module already"
      return


func fixBlockEntry*(path, source: string): Fix =
  ## Move body of entry block into `proc main` above block, documented `TODO: Document.` (VI.1),
  ##   and leave block calling `main()` (V.10). Block whose move `blockEntry` refuses stays.
  ##   Body keeps its lines and indent, since block and routine indent body alike.
  let entry = source.blockEntry
  result.source = source
  if entry.bindings.len == 0 or entry.refusal.len > 0: return
  let
    lines = source.split('\n')
    margin = ' '.repeat(entry.indent)
  var shaped: seq[string]

  template keep(i: int) =
    shaped.add lines[i]
    result.origin.add i + 1

  template insert(line: string) =
    shaped.add line
    result.origin.add 0

  for i in 0 ..< entry.head: keep(i)
  insert "proc " & ROUTINE_ENTRY & "() ="
  insert margin & "## TODO: Document."
  for i in entry.first .. entry.last: keep(i)
  insert ""
  insert ""
  keep(entry.head)
  insert margin & ROUTINE_ENTRY & "()"
  for i in entry.last + 1 ..< lines.len: keep(i)
  result.source = shaped.join("\n")
  for (line, _) in entry.bindings: result.fixed.add finding(path, line, "entry block (V.10)")


func foreignMark(code: openArray[string], line: int, kind: NameKind): string =
  ## Read word marking name declared at zero-based line as one foreign code reads by spelling
  ##   (`MARKS_FOREIGN`): on its signature or line, on each line enclosing field or member, or on
  ##   `{.push.}` over it, which stands over foreign bindings alone (STYLE.md §2). Empty where
  ##   none; parameter crosses no boundary by name, since foreign call passes arguments by place.
  if kind == NameKind.Parameter: return
  var pushed = ""
  for i in 0 ..< line:
    let s = code[i].strip
    if s.startsWith("{.push"):
      let marks = s.wordsOf.filterIt(it in MARKS_FOREIGN)
      pushed = if marks.len > 0: marks[0] else: "push"
    elif s.startsWith("{.pop"): pushed = ""
  if pushed.len > 0: return pushed

  # Read declaring lines: signature runs to its closing parenthesis, pragma line after it.
  var
    read = @[line]
    text = code[line]
  while text.count('(') > text.count(')') and read[^1] + 1 < code.len:
    read.add read[^1] + 1
    text.add code[read[^1]]
  if kind == NameKind.Routine and read[^1] + 1 < code.len and
      code[read[^1] + 1].strip.startsWith("{."):
    read.add read[^1] + 1
  if kind in {NameKind.Field, NameKind.Member}:
    var indent = code[line].indentOf
    for i in countdown(line - 1, 0):
      if code[i].strip.len == 0 or code[i].indentOf >= indent: continue
      read.add i
      indent = code[i].indentOf
      if indent == 0: break
  for i in read:
    for word in code[i].wordsOf:
      if word in MARKS_FOREIGN: return word


func isMemberSpelled(
  tokens: openArray[Token], partners: openArray[int], k: int, source: string
): bool =
  ## Decide whether enum member at token `k` carries its own string, so `$` reads no name of it:
  ##   `A = "a"` or `A = (0, "a")`.
  if k + 2 >= tokens.len or tokens[k + 1].spelling(source) != "=": return false
  let value = tokens[k + 2]
  if value.kind == TokenKind.Text: return true
  if value.spelling(source) != "(" or partners[k + 2] < 0: return false
  toSeq(k + 3 ..< partners[k + 2]).anyIt(tokens[it].kind == TokenKind.Text)


func renamesCase*(source: string, exempt: openArray[string]): seq[RenameCase] =
  ## Read rename each declaration needs to take case of its kind, as `checkNames` reports case
  ##   (V.1, V.11), each coined abbreviation spelled out too (V.6). Binding of entry block that
  ##   fix moves into `proc main` takes case of local, as it reads there.
  ##   Rename fix leaves to hand carries refusal: name foreign code reads, member `$` reads, name
  ##     line declares twice, or new name that reads otherwise than rule asks.
  ##   Placeholder (V.12) has none: its letter is initial of what it ranges over, which is choice.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
    code = source.codeOnly.split('\n')
    entry = source.blockEntry
    declared = source.declarations
    lower_exempt = exempt.mapIt(it.toLowerAscii)
  for d in declared:
    var subject = d
    if d.kind == NameKind.Binding and d.reach == Reach.Entry:
      if entry.refusal.len > 0: continue
      subject.reach = Reach.Local
    let casing = subject.casingOf
    if casing == Casing.Letter or not subject.isMiscased: continue

    # Name rule: member, local constant, i.e. local in capitals, or kind as finding names it.
    let
      respelled = d.name.respelled(exempt)
      renamed = respelled.cased(casing)
      rule_case =
        if d.kind == NameKind.Member: "member case (V.11)"
        elif d.kind == NameKind.Binding and subject.reach == Reach.Local and
            d.name.isCased(Casing.Screaming):
          "local constant case (V.1)"
        elif d.kind == NameKind.Binding: ($subject.reach).toLowerAscii & " case (V.1)"
        else: ($d.kind).toLowerAscii & " case (V.1)"
    var rename = RenameCase(
      line: d.line,
      name: d.name,
      renamed: renamed,
      rule: if respelled == d.name: rule_case else: "abbreviation (V.6) and " & rule_case,
      is_local: d.kind == NameKind.Binding and subject.reach == Reach.Local,
    )

    # Find declared name's token from declaration's first line on, where multi-line signature
    #   places parameter below.
    var k = 0
    while k < tokens.len and (tokens[k].line < d.line - 1 or tokens[k].kind != TokenKind.Word or
        tokens[k].spelling(source) != d.name):
      inc k
    if k == tokens.len: continue
    rename.line = tokens[k].line + 1
    rename.column = tokens[k].first - starts[tokens[k].line]

    # Refuse rename that no planner can prove keeps meaning.
    let
      mark = code.foreignMark(tokens[k].line, d.kind)
      acronyms = renamed.acronyms.filterIt(
        it notin d.name.acronyms and it.toLowerAscii notin lower_exempt,
      )
    if declared.countIt(it.line == d.line and it.name == d.name) > 1:
      rename.refusal = "line declares `" & d.name & "` twice"
    elif d.name.isNotation: rename.refusal = "`" & d.name & "` holds letter outside ASCII"
    elif mark.len > 0: rename.refusal = "foreign code reads name through `" & mark & "`"
    elif d.kind == NameKind.Member and not tokens.isMemberSpelled(partners, k, source):
      rename.refusal = "`$` of member reads its name"
    elif not renamed.isCased(casing):
      rename.refusal = "`" & renamed & "` " & CASE_RULES[casing].replace("is ", "is no ")
    elif acronyms.len > 0:
      rename.refusal = "`" & renamed & "` reads `" & acronyms[0] & "` as acronym (V.9)"
    elif d.reach == Reach.Entry and renamed.identity == ROUTINE_ENTRY:
      rename.refusal = "`" & renamed & "` names routine of entry block (V.10)"
    result.add rename
