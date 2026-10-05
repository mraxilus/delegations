## Gather every text this build writes itself, and every codepoint those texts hold.
##
## One gathering for both front-ends, so face that covers one covers other.
##   Desktop's `--drive-faces` asks atlas of each role for these codepoints, and page's drive
##   asks `cmap` of each face it embeds for same ones (Article X.8).
##   Read from where each text is composed -- catalogue, help, notation, basis names, wheel
##   and units -- rather than listed here, so row added there is asked about untouched.
##   Names reader types are reader's own, and only printable ASCII among them is promised.
##
## Shared between desktop (`main.nim`) and browser (`bridge.nim`) render paths;
## see PROVENANCE.md's "Render paths".

{.experimental: "strictFuncs".}

import std/[algorithm, unicode]

import pga
import ./[format, help, interaction, scene, wording]



#[ Shown Text ]#

func textsShown*(): seq[string] =
  ## Gather every text build itself writes.
  ##   Units are written once each, with figures chosen only to reach every unit word.
  for key in Wording: result.add $wordingText(key)
  for path in HelpPath: result.add [titleOf(path), descriptionOf(path)]
  for entry in HELP_ENTRIES: result.add [entry.action, entry.outcome]
  for operation in Operation:
    result.add [
      notationSymbolic(operation), notationNamed(operation),
      notationSubstituted(operation, "a", "b"),
    ]
  for basis in Basis: result.add LUT_NAME_BY_BASIS[basis]
  for choice in DragChoice: result.add labelOf(choice)
  var
    units: array[64, char]
    cursor = 0
  appendDegrees(units, cursor, 1.0)
  appendSpeedLight(units, cursor, 2.0)
  appendRuler(units, cursor, 1.0)
  finishChars(units, cursor)
  result.add units.toText


func codepointsOf*(texts: openArray[string]): seq[int] =
  ## Gather every codepoint `texts` hold, with all of printable ASCII, sorted and once each.
  ##   Printable ASCII is in whatever texts hold, since reader names objects in it.
  for codepoint in 0x20..0x7E: result.add codepoint
  for text in texts:
    for rune in text.runes: result.add int(rune)
  result.sort
  var kept = 0
  for codepoint in result:
    if kept == 0 or result[kept-1] != codepoint:
      result[kept] = codepoint
      inc kept
  result.setLen kept


func codepointsShown*(): seq[int] =
  ## Gather every codepoint build itself writes, with all of printable ASCII.
  codepointsOf(textsShown())
