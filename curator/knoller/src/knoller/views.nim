## Read Nim source as rules see it: code alone, or code and comments, with every length kept.
##   Blanking keeps each newline and byte offset, so line and column of view are line and column
##     of source, and rule reads view where string or comment would trip it.
##   Forms blanked: `#` to end of line, `#[ ]#` nesting, `"…"` with escapes, `"""…"""`, raw
##     `r"…"` with `""` escape, and `'c'`.
##
##   Cost: text scanner, never lexer; `tokens.nim` reads tokens where rule needs them.

{.experimental: "strictFuncs".}

import std/strutils


const
  IDENT_CHARS = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}
    ## ASCII characters identifier is built from; raw string prefix is one of them.
  NAME_CHARS* = IDENT_CHARS + {'\x80' .. '\xFF'}
    ## Bytes declared name is built from: Nim reads every non-ASCII byte as letter.


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


func identifierAt*(text: string, start: int): string =
  ## Read identifier opening at index, after optional spaces; empty where none.
  var i = start
  while i < text.len and text[i] == ' ': inc i
  var j = i
  while j < text.len and text[j] in NAME_CHARS: inc j
  text[i ..< j]


func identity*(name: string): string =
  ## Read name as Nim compares it: first character exact, rest without case and underscores.
  if name.len == 0: "" else: name[0] & name[1 .. ^1].replace("_", "").toLowerAscii


func pragmaWords*(code: string): seq[string] =
  ## Read every name inside each `{. .}` of code, values included, in order: `{.push importc,
  ##   header: H.}` gives `push`, `importc`, `header`, `H`; name outside them is never read.
  var at = 0
  while true:
    let open = code.find("{.", at)
    if open < 0: break
    let close = code.find(".}", open + 2)
    if close < 0: break
    var k = open + 2
    while k < close:
      let name = code.identifierAt(k)
      if name.len == 0: inc k
      else:
        result.add name
        k += name.len
    at = close + 2
