## ciska lo selci'a ta'i lo se sitna lerpoi pe `Nim` ge'u zi'e poi ka'e selvau lo linji pe le
##     datnyvei ku'o tezu'e lo minde poi ciska lo datnyvei poi ponse lo klesi
##   .i `cll.nim` .e `tatoeba.nim` pilno le vi datnyvei
##   .i se ki'u bo ro le re minde cu fendi lo claselci'a ta'i pa tadji to `II.9` toi
##
## ni'o ne'i le se sitna lerpoi lo lerfu po'u `\` lidne ro lerfu po'u `\` ge'u .e ro lerfu po'u `"`
##   .i ro datle'u .e lo lerfu pe `UTF-8` stali ta'i le selci'a
##   .i se ki'u bo lo datnyvei poi selpu'i cu se tcidu ta'i lo krasi
##
## ni'o lo selci'a poi zmadu le linji pe vo'a lo ka clani cu se fendi fi lo se sitna lerpoi bu'u lo
##     kutle'u
##   .i `&` jorne le se sitna lerpoi
##   .i ro le se sitna lerpoi cu selkra lo stuzi poi le linji poi le mekso cu cfari bu'u ke'a selkra
##       ke'a to `STYLE.md 5` toi
##   .i lo kutle'u cu stali bu'u lo fanmo be ro pagbu
##
## ni'o jdima fa lo nu le linji cu se kancu fo lo stuzi ca lo nu fendi kei gi'e se kancu fo lo lerfu
##     ca lo nu cipra lo du'u le linji cu mapti
##   .i se ki'u bo lo selci'a poi vasru lo lerfu poi na cmima `ASCII` se fendi pu lo nu le nu fendi
##       cu seltcu

{.experimental: "strictFuncs".}

import std/strutils
from std/unicode import runeLen


const WIDTH* = 100  ## le jimte be lo lerstu pe pa linji pe lo datnyvei to `Article X.1` toi



#[ ni'o ni'o ni'o lo se sitna lerpoi ]#

func toLiteral*(text: string): string =
  ## ciska le selci'a ta'i pa se sitna lerpoi pe `Nim`
  ##   .i lo lerfu po'u `\` lidne ro lerfu po'u `\` ge'u .e ro lerfu po'u `"`
  "\"" & text.multiReplace(("\\", "\\\\"), ("\"", "\\\"")) & "\""


func isFit*(line: string): bool =
  ## jdice lo du'u le linji cu mapti `WIDTH`
  ##   .i le linji cu se kancu fo lo lerfu
  line.runeLen <= WIDTH


func toPieces(text: string, width: int): seq[string] =
  ## fendi le selci'a lo pagbu bu'u lo kutle'u
  ##   .i ro le pagbu cu mapti `width` ta'i lo se sitna lerpoi
  ##   .i lo kutle'u cu stali bu'u lo fanmo be le pagbu
  var piece: string
  for word in text.split(' '):
    let next = (if piece.len == 0: word else: piece & " " & word)
    if piece.len > 0 and next.toLiteral.len > width:
      result.add piece & " "
      piece = word
    else: piece = next
  result.add piece


func linesLiteral*(text: string, indent: int, closing: string): seq[string] =
  ## ciska le selci'a ta'i pa se sitna lerpoi bu'u `indent`
  ##   .i `closing` se lidne le se sitna lerpoi
  ##   .i va'o lo nu le linji cu zmadu `WIDTH` kei le se sitna lerpoi cu se fendi sepi'o `&`
  let line = repeat(' ', indent) & text.toLiteral & closing
  if line.isFit: return @[line]
  # lo kutle'u .e ` &` fanmo ro pagbu
  let pieces = text.toPieces(WIDTH - indent - max(3, closing.len))
  for i, piece in pieces:
    let tail = (if i < pieces.high: " &" else: closing)
    result.add repeat(' ', indent) & piece.toLiteral & tail
