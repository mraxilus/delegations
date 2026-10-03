## Enforce words of declared names (Article V.3, V.5, V.6, V.9, V.10; GUIDE.md, Names).
##   Reads declarations alone: binding (`let`, `var`, `const`, `for`), routine, type, field and
##     parameter. Name library owns reaches code only at use site, which is never read, so
##     library clause of V.9 holds by construction. Foreign binding, i.e. routine carrying
##     `importc`, `importcpp`, `importjs` or `dynlib`, declares library's own name and is
##     skipped for same reason; its parameters are ours and are read.
##   Word is run between `_` and case changes; acronym is run of two or more capitals inside
##     camel or Pascal name. SCREAMING name is all capitals, so its acronyms cannot be told
##     from words and hold by reading.
##   Table `ABBREVIATIONS` gives each banned word its one replacement, as `english.nim` does
##     for prose; word outside table passes, and reading catches rest. `JARGON` is closed list
##     of V.6. Caller adds symbols glossaries list under `## Standards` as code spans, and
##     their `**Term**` names, through `glossaryExemptions`.
##   V.3: routine never opens with `get`, `compute` or `new`. V.5: name opening `lut` reads
##     `lut_<value>_by_<key>`. V.10: module-level global shares no word with type, compared
##     without case and underscores, as Nim compares them.
##
##   V.6 has fixer (`koch fix`): `abbreviationRenames` reads each declaration coining
##     abbreviation and its full spelling, case kept, as check reads it, and rename planner of
##     `rewrites.nim` renames it at every use through semantic pass, or refuses with reason.
##
##   Cost: text scanner, never parser. Comments and strings are blanked first; multi-line
##     signature is joined to its closing parenthesis; enum member is unread (its case is V.1,
##     unheld here); object variant branch is read as fields where it sits in `type` block.
##   Cost: generic parameter in brackets is unread; V.12 holds by reading.
##   Cost: word table is short list; `english.nim` pays same cost.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[findings, glossary, tokens]


type
  NameKind* {.pure.} = enum  ## Define what declaration introduces name.
    Binding, Routine, Type, Field, Parameter

  Declared* = object  ## Define one declared name with its place.
    name*: string
    line*: int
    kind*: NameKind
    is_global*: bool  ## Binding at module level, i.e. no indent.


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
  ROUTINE_KEYWORDS = ["proc", "func", "iterator", "template", "macro", "converter", "method"]
    ## Keywords opening routine declaration.
  BINDING_KEYWORDS = ["let", "var", "const"]  ## Keywords opening binding, single or block.
  IDENT_CHARS = {'a'..'z', 'A'..'Z', '0'..'9', '_'}  ## Characters identifier is built from.
  FOREIGN_PRAGMAS = ["importc", "importcpp", "importjs", "dynlib"]
    ## Pragmas marking routine as binding of library's own name.


func blanked(source: string, should_keep_comments: bool): string =
  ## Blank string and char literals, and comments unless kept, keeping every newline and length.
  ##   Nim forms: `#` to end of line, `#[ ]#` nesting, `"..."` with escapes, `"""..."""`,
  ##     raw `r"..."` with `""` escape, and `'c'`.
  result = newString(source.len)
  var
    i = 0
    depth = 0

  template blank(n: int) =
    for k in 0..<n:
      result[i] = (if source[i] == '\n': '\n' else: ' ')
      inc i

  template comment(n: int) =
    if should_keep_comments:
      for k in 0..<n:
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
  while j < text.len and text[j] in IDENT_CHARS: inc j
  text[i..<j]


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


func parameterNames(signature: string): seq[string] =
  ## Read parameter names of text between parentheses: `x, y: T; z = 1` gives `x`, `y`, `z`.
  for p in signature.splitTop({',', ';'}):
    let name = p.nameOf
    if name.len > 0 and name != "_" and name != "var": result.add name


func declarations*(source: string): seq[Declared] =
  ## Read every declared name of Nim source with its line and kind.
  let lines = source.codeOnly.splitLines
  var
    block_indent = -1
    type_indent = -1
    object_indent = -1
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
    if block_indent >= 0 and indent <= block_indent: block_indent = -1
    if type_indent >= 0 and indent <= type_indent: type_indent = -1
    if object_indent >= 0 and indent <= object_indent: object_indent = -1
    let
      word = s.identifierAt(0)
      rest = s[word.len .. ^1]
    if word in ROUTINE_KEYWORDS and rest.len > 0 and rest[0] == ' ':
      let name = rest.identifierAt(0)
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
      let is_foreign = FOREIGN_PRAGMAS.anyIt(it in text)
      if name.len > 0 and not is_foreign:
        result.add Declared(name: name, line: one, kind: NameKind.Routine)
      let open = text.find('(')
      if open >= 0:
        var
          depth = 0
          close = -1
        for k in open..<text.len:
          if text[k] == '(': inc depth
          elif text[k] == ')':
            dec depth
            if depth == 0:
              close = k
              break
        if close > open:
          for p in text[open + 1..<close].parameterNames:
            result.add Declared(name: p, line: one, kind: NameKind.Parameter)
      i = j + 1
      continue
    if word == "type":
      if rest.strip.len == 0: type_indent = indent
      else:
        let name = rest.identifierAt(0)
        if name.len > 0: result.add Declared(name: name, line: one, kind: NameKind.Type)
        object_indent = indent
      inc i
      continue
    if type_indent >= 0 and indent == type_indent + 2:
      let name = s.identifierAt(0)
      if "=" in s and name.len > 0:
        result.add Declared(name: name, line: one, kind: NameKind.Type)
        object_indent = indent
      inc i
      continue
    if object_indent >= 0 and indent > object_indent:
      let name = s.identifierAt(0)
      if ":" in s and name.len > 0 and name notin ["of", "case", "else", "elif", "when"]:
        result.add Declared(name: name, line: one, kind: NameKind.Field)
      inc i
      continue
    if word in BINDING_KEYWORDS:
      if rest.strip.len == 0: block_indent = indent
      else:
        for name in rest.strip(chars = {' ', '(', ')'}).splitTop({','}):
          let n = name.nameOf
          if n.len > 0 and n != "_":
            result.add Declared(name: n, line: one, kind: NameKind.Binding, is_global: indent == 0)
      inc i
      continue
    if block_indent >= 0 and indent > block_indent:
      let n = s.strip(chars = {'(', ')'}).nameOf
      if n.len > 0 and n != "_" and (":" in s or "=" in s):
        result.add Declared(
          name: n,
          line: one,
          kind: NameKind.Binding,
          is_global: block_indent == 0,
        )
      inc i
      continue
    if word == "for":
      let at = rest.find(" in ")
      if at > 0:
        for name in rest[0..<at].split(','):
          let n = name.nameOf
          if n.len > 0 and n != "_": result.add Declared(name: n, line: one, kind: NameKind.Binding)
    inc i


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
    let is_boundary = (c in {'A'..'Z'} and name[k - 1] in {'a'..'z', '0'..'9'}) or
      (c in {'a'..'z'} and k - first > 1 and name[k - 1] in {'A'..'Z'} and
        name[k - 2] in {'A'..'Z'})
    if not is_boundary: continue
    # Capital before lowercase starts new word: `JSONData` is JSON, Data.
    let cut = if c in {'a'..'z'}: k - 1 else: k
    result.add (first, cut)
    first = cut
  if first >= 0: result.add (first, name.len)


func words*(name: string): seq[string] =
  ## Split name at `_` and at case changes: `lut_grade`, `wedgeAnti`, `JSONData` give words.
  name.wordSpans.mapIt(name[it[0]..<it[1]])


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
    let full = name[first..<after].fullWordOf(lower_exempt)
    if full.len > 0: result = result[0..<first] & full & result[after .. ^1]


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


func isScreaming(name: string): bool =
  ## Decide whether name is SCREAMING_SNAKE_CASE, i.e. no lowercase letter.
  name.allCharsInSet({'A'..'Z', '0'..'9', '_'}) and name.anyIt(it in {'A'..'Z'})


func acronyms*(name: string): seq[string] =
  ## Read runs of two or more capitals, digits attached, inside camel or Pascal name.
  if name.isScreaming or '_' in name: return
  var run = ""
  let text = name & " "
  for k in 0..<text.len - 1:
    let
      c = text[k]
      opens_word = c in {'A'..'Z'} and text[k + 1] in {'a'..'z'}
    if (c in {'A'..'Z'} and not opens_word) or (run.len > 0 and c in {'0'..'9'}): run.add c
    else:
      if run.count({'A'..'Z'}) >= 2: result.add run
      run = ""
  if run.count({'A'..'Z'}) >= 2: result.add run


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
        for w in line[open + 1..<close].split({' ', ','}):
          if w.len > 0: result.add w
        i = close + 1
    if line.isTermLine: result.add line[2..<line.len - 3]


func exemptionsOf*(glossaries: openArray[(string, string)], path: string): seq[string] =
  ## Read words name in path may take beyond table: jargon of V.6, and what root glossary and
  ##   glossary of path's own project list (`glossaryExemptions`).
  result = JARGON.toSeq
  for (glossary, source) in glossaries:
    let directory = glossary[0..<glossary.len - ROOT_GLOSSARY.len]
    if glossary == ROOT_GLOSSARY or path.startsWith(directory):
      result.add source.glossaryExemptions


func checkNames*(path, source: string; exempt: openArray[string]): seq[Finding] =
  ## Report declared name that coins abbreviation, carries unlisted acronym, opens routine
  ##   with banned verb, misnames lookup table, or shares its word with type as global.
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
    if d.kind == NameKind.Binding and d.is_global and d.name.isScreaming and
        d.name.toLowerAscii.replace("_", "") in type_keys:
      result.add finding(
        path,
        d.line,
        "Global never shares its word with type (V.10); got `" & d.name & "`.",
      )
