## Read wording catalogue's keys and words from its source, as text.
##   Driver compiles no project code: type check runs it on koch's compiler, never on this
##   project's pin, and importing `wording.nim` compiled that module there (#385).
##   Suite holds both readings to compiled enum and table on pin, so key moved or row
##   reworded where reading cannot follow fails `test` rather than passing in silence.
##   Rejected: import of catalogue, which compiled project code on driver's compiler; split
##   of enum on lines alone, which stopped at first blank line inside it.
##   Pure, so suite reaches it on both backends.

{.experimental: "strictFuncs".}

import std/[strutils, tables]



#[ Catalogue Configuration ]#

const
  OPENING_KEYS = "type Wording* = enum"
    ## Line opening enum whose values are keys.
  OPENING_WORDS = "const LUT_TEXT_BY_WORDING"
    ## Line opening table whose rows are words.



#[ Reading ]#

func blockAfter(source, opening: string): seq[string] =
  ## Read lines after line opening with `opening`, up to first line at column zero.
  ##   Nim block ends there, and both blocks read here are followed by section banner or
  ##   closing bracket at column zero.
  let lines = source.splitLines
  var at = -1
  for i, line in lines:
    if line.startsWith(opening):
      at = i
      break
  if at < 0: raise newException(ValueError, "Source holds no `" & opening & "`.")
  for line in lines[at + 1 .. ^1]:
    if line.len > 0 and line[0] notin Whitespace: break
    result.add line


func keysOf*(source: string): seq[string] =
  ## Read keys of `Wording` in declared order, so index is ordinal.
  ##   Doc lines and blank lines carry none; values split on commas. Explicit ordinal is
  ##   refused, since index would then no longer be ordinal.
  for line in source.blockAfter(OPENING_KEYS):
    for field in line.split('#')[0].split(','):
      let key = field.strip
      if key.len == 0: continue
      if not key.validIdentifier:
        raise newException(ValueError, "Key is bare identifier; got `" & key & "`.")
      result.add key


func wordsOf*(source: string): Table[string, string] =
  ## Read words of every row of `LUT_TEXT_BY_WORDING`, keyed by name of its key.
  ##   Row is key, colon, then string literals joined by `&`, on one line or several.
  ##   Comment runs from `#` outside literal to end of line.
  ##   Escape is refused: catalogue writes none, and escape read wrongly would ship wrong
  ##   words to reader.
  let text = source.blockAfter(OPENING_WORDS).join("\n")
  var
    key = ""
    words = ""
    at = 0
  while at < text.len:
    case text[at]
    of '#':
      while at < text.len and text[at] != '\n': inc at
    of '"':
      inc at
      while at < text.len and text[at] != '"':
        if text[at] == '\\':
          raise newException(ValueError, "Row `" & key & "` holds escape, which read refuses.")
        words.add text[at]
        inc at
      inc at
    of IdentStartChars:
      var name = ""
      while at < text.len and text[at] in IdentChars:
        name.add text[at]
        inc at
      while at < text.len and text[at] == ' ': inc at
      if at >= text.len or text[at] != ':':
        raise newException(ValueError, "Row opens with key and colon; got `" & name & "`.")
      if key.len > 0: result[key] = words
      (key, words) = (name, "")
      inc at
    else:
      inc at
  if key.len > 0: result[key] = words
