## Read each name Nim source declares, with its kind and reach (Article V.1, V.10, V.11).
##   Reads declarations alone: binding (`let`, `var`, `const`, `for`, `except … as`), routine,
##     type, field, parameter, enum member and placeholder in generic brackets. Foreign binding,
##     i.e. routine whose pragmas hold word of `MARKS_FOREIGN`, as `importc` or `exportc`,
##     declares name foreign code reads by its spelling, so it is skipped; its parameters are ours
##     and are read.
##   Reach of binding is decided in `reachOf` alone. Global where every enclosing block opens no
##     scope (`when` chain, bare `let`, `var`, `const` or `type`); local under routine or any
##     other block; entry inside top-level `when isMainModule:` and outside routine.
##   Name template substitutes, i.e. its parameter, declares nothing of that name in its body.
##   Operator is backticked, so it is never read as name.
##
##   Cost: text scanner, never parser. Comments and strings are blanked first; multi-line
##     signature is joined to its closing parenthesis; object variant branch is read as fields
##     where it sits in `type` block; tuple type in brackets, and name `{.inject.}` makes, are
##     unread.
##   Cost: boolean is read only where declaration shows it: type `bool`, or value literal
##     `true` or `false`. Boolean from call or expression holds by reading.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./views


const
  ROUTINE_KEYWORDS = ["proc", "func", "iterator", "template", "macro", "converter", "method"]
    ## Keywords opening routine declaration.
  BINDING_KEYWORDS = ["let", "var", "const"]  ## Keywords opening binding, single or section.
  SECTION_KEYWORDS = ["let", "var", "const", "type"]
    ## Keywords that, alone on line, open section and no scope.
  CHAIN_WORDS = ["when", "elif", "else"]  ## Words opening branch of `when` chain.
  CONCEPT_MODIFIERS = ["var", "ref", "ptr", "type"]  ## Words standing before concept placeholder.
  MARKS_FOREIGN* = [
    "dynlib", "exportc", "exportcpp", "extern", "header", "importc", "importcpp", "importjs",
    "importobjc", "JsRoot",
  ]
    ## Words marking name foreign code reads by its spelling: pragma, or root of JavaScript object.
    ##   Read as words among pragmas (`pragmaWords`), never inside other name: routine they mark
    ##     declares no name of ours (`declarations`), `{.push.}` stands over bindings they mark
    ##     (`idioms.nim`), and `curator/audit` renames no name they mark, nor `entry.nim` moves it.


type
  NameKind* {.pure.} = enum  ## Define what declaration introduces name.
    Binding, Routine, Type, Field, Parameter, Member, Placeholder

  Reach* {.pure.} = enum  ## Define how far binding reaches, which fixes its case (V.1, V.10).
    Local  ## Inside routine or block opening scope; every name not binding.
    Global  ## At module level, under blocks opening no scope.
    Entry  ## Inside entry block, i.e. top-level `when isMainModule:`, outside routine.

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


func closing*(text: string, open: int): int =
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
          is_foreign = text.pragmaWords.anyIt(it in MARKS_FOREIGN)
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
