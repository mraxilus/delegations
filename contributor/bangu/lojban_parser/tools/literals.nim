## ciska lo se ciska ta'i lo se sitna lerpoi pe la'o gy. Nim .gy. ge'u zi'e poi ka'e se vasru lo
##   linji pe le datnyvei ku'o tezu'e lo minde poi ciska lo datnyvei poi ponse lo klesi
##   .i `cll.nim` .e `tatoeba.nim` cu pilno le vi datnyvei
##   .i se ki'u bo ro le re minde cu fendi lo clani se ciska ta'i pa tadji to `II.9` toi
##   .i ne'i le se sitna lerpoi lo lerfu po'u `\` cu lidne ro lerfu po'u `\` ge'u .e ro lerfu po'u
##     `"`
##   .i ro drata lerfu cu stali ta'i le se ciska
##   .i lo lerfu pe la'o gy. UTF-8 .gy. cu stali ji'a
##   .i se ki'u bo lo datnyvei poi se punji cu se tcidu ta'i lo krasi
##   .i lo se ciska poi zmadu le linji pe vo'a lo ka clani cu se fendi fi lo se sitna lerpoi bu'u lo
##     kunti lerfu
##   .i `&` cu jorne le se sitna lerpoi
##   .i ro le se sitna lerpoi cu se krasi lo stuzi poi le linji poi le mekso cu cfari bu'u ke'a cu
##     se krasi ke'a to `STYLE.md 5` toi
##   .i lo kunti lerfu cu stali bu'u lo fanmo be ro pagbu
##   .i jdima fa lo nu le linji cu se kancu fo lo stuzi ca lo nu fendi kei gi'e se kancu fo lo lerfu
##     ca lo nu cipra lo du'u le linji cu mapti
##   .i se ki'u bo lo se ciska poi vasru lo lerfu poi na cmima la'o gy. ASCII .gy. cu se fendi pu lo
##     nu le nu fendi cu se nitcu

{.experimental: "strictFuncs".}

import std/strutils
from std/unicode import runeLen


const WIDTH* = 100  ## le jimte be lo lerfu stuzi pe pa linji pe lo datnyvei to `Article X.1` toi



#[ ni'o ni'o ni'o lo se sitna lerpoi ]#

func toLiteral*(text: string): string =
  ## ciska le se ciska ta'i pa se sitna lerpoi pe la'o gy. Nim .gy.
  ##   .i lo lerfu po'u `\` cu lidne ro lerfu po'u `\` ge'u .e ro lerfu po'u `"`
  "\"" & text.multiReplace(("\\", "\\\\"), ("\"", "\\\"")) & "\""


func isFit*(line: string): bool =
  ## jdice lo du'u le linji cu mapti `WIDTH`
  ##   .i le linji cu se kancu fo lo lerfu
  line.runeLen <= WIDTH


func toPieces(text: string, width: int): seq[string] =
  ## fendi le se ciska lo pagbu bu'u lo kunti lerfu
  ##   .i ro le pagbu cu mapti `width` ta'i lo se sitna lerpoi
  ##   .i lo kunti lerfu cu stali bu'u lo fanmo be le pagbu
  var piece: string
  for word in text.split(' '):
    let next = (if piece.len == 0: word else: piece & " " & word)
    if piece.len > 0 and next.toLiteral.len > width:
      result.add piece & " "
      piece = word
    else: piece = next
  result.add piece


func linesLiteral*(text: string, indent: int, closing: string): seq[string] =
  ## ciska le se ciska ta'i pa se sitna lerpoi bu'u `indent`
  ##   .i `closing` cu se lidne le se sitna lerpoi
  ##   .i va'o lo nu le linji cu zmadu `WIDTH` kei le se sitna lerpoi cu se fendi sepi'o `&`
  let line = repeat(' ', indent) & text.toLiteral & closing
  if line.isFit: return @[line]
  # lo kunti lerfu .e ` &` cu fanmo ro pagbu
  let pieces = text.toPieces(WIDTH - indent - max(3, closing.len))
  for i, piece in pieces:
    let tail = (if i < pieces.high: " &" else: closing)
    result.add repeat(' ', indent) & piece.toLiteral & tail
