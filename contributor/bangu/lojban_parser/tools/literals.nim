## Render text as Nim string literals that fit lines of module, for verbs writing typed modules.
##   Shared by `cll.nim` and `tatoeba.nim`, so both verbs split long text one way (II.9).
##   Literal escapes backslash and quote alone; every other character, UTF-8 among, stays as
##     text holds it, so committed module reads as source.
##   Text too long for its line splits at spaces into literals joined by `&`, each at indent of
##     line expression opens on (STYLE.md section 5), space kept at end of each piece.
##   Cost: width counts bytes while splitting and characters when testing fit, so text holding
##     non-ASCII letter splits sooner than it needs.

{.experimental: "strictFuncs".}

import std/strutils
from std/unicode import runeLen


const WIDTH* = 100  ## Columns line of module may hold (Article X.1).



#[ Literals ]#

func toLiteral*(text: string): string =
  ## Render text as Nim string literal, backslash and quote escaped.
  "\"" & text.multiReplace(("\\", "\\\\"), ("\"", "\\\"")) & "\""


func isFit*(line: string): bool =
  ## Decide whether line fits `WIDTH`, counted in characters.
  line.runeLen <= WIDTH


func toPieces(text: string, width: int): seq[string] =
  ## Split text at spaces into pieces, each fitting `width` as literal, spaces kept at ends.
  var piece: string
  for word in text.split(' '):
    let next = (if piece.len == 0: word else: piece & " " & word)
    if piece.len > 0 and next.toLiteral.len > width:
      result.add piece & " "
      piece = word
    else: piece = next
  result.add piece


func linesLiteral*(text: string, indent: int, closing: string): seq[string] =
  ## Render text as literal at `indent`, then `closing`, split by `&` where line would pass
  ##   `WIDTH`.
  let line = repeat(' ', indent) & text.toLiteral & closing
  if line.isFit: return @[line]
  let pieces = text.toPieces(WIDTH - indent - max(3, closing.len))  # space and ` &` close piece
  for i, piece in pieces:
    let tail = (if i < pieces.high: " &" else: closing)
    result.add repeat(' ', indent) & piece.toLiteral & tail
