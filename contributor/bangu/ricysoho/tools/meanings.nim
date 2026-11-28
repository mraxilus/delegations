## tcidu lo smuni be ro valsi pe le gimste .e le ma'oste vu'o pe `Logical Language Group` mu'i le
##     ctuca pe le papri pe lo linji
##   .i tcidu `gismu.txt` .e `cmavo.txt` ta'i `readSource` pe `lists.nim` gi'e karbi le snina'u le
##       stosni
##   .i le smuni cu glico ja'i `D6 b` pe `#1055`
##
##   | lo datnypau  | lo krasi    | lo stuzi    |
##   |--------------|-------------|-------------|
##   | `gloss`      | `gismu.txt` | `21 .. 40`  |
##   | `definition` | `gismu.txt` | `63 .. 158` |
##   | `gloss`      | `cmavo.txt` | `21 .. 61`  |
##   | `definition` | `cmavo.txt` | `63 .. 158` |
##
## ni'o va'o lo nu re liste cu vasru pa valsi kei le smuni pe `cmavo.txt` cu basti le smuni pe
##     `gismu.txt`
##   .i ki'u bo le ma'oste cu skicu ro cmavo

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]

import ./lists


type Meaning* = object  ## le smuni be pa valsi
  gloss*: string  ## le glico valsi poi sinxa le valsi
  definition*: string  ## le glico smuni be le valsi


const  # le stuzi be ro datnypau ne'i le re liste
  COLUMNS_GISMU* = [(2, 6), (21, 40), (63, 158)]
    ## le stuzi be le valsi .e le glico valsi .e le smuni ne'i `gismu.txt`
  COLUMNS_CMAVO* = [(1, 11), (21, 61), (63, 158)]
    ## le stuzi be le valsi .e le glico valsi .e le smuni ne'i `cmavo.txt`
  COLUMN_SELMAHO = (12, 20)
    ## le stuzi be le selma'o ne'i `cmavo.txt`
    ##   .i lo lerfu po'u zoi gy. * .gy. cu sinxa lo ma'orgunma .a lo jufpau



#[ ni'o ni'o ni'o lo nu tcidu ]#

func toMeanings*(gismu, cmavo: string): OrderedTable[string, Meaning] =
  ## tcidu ro smuni pe `gismu.txt` .e `cmavo.txt`
  ##   .i le sedli'i cu na se tcidu
  ##   .i le valsi cu vasru no lerfu po'u denpa bu
  ##   .i pa linji pe `cmavo.txt` poi skicu pa ma'orgunma .a pa jufpau cu na se tcidu
  ##   .i ki'u bo le genturfa'i cu tcidu ro cmavo pe le gunma to `toEntriesCmavo` toi
  for (text, columns) in [(gismu, COLUMNS_GISMU), (cmavo, COLUMNS_CMAVO)]:
    for line in text.splitLines[1 .. ^1]:
      let word = line.field(columns[0][0], columns[0][1]).replace(".", "")
      if word.len == 0: continue
      if columns == COLUMNS_CMAVO and '*' in line.field(COLUMN_SELMAHO[0], COLUMN_SELMAHO[1]):
        continue
      result[word] = Meaning(gloss: line.field(columns[1][0], columns[1][1]),
          definition: line.field(columns[2][0], columns[2][1]))


proc meaningsJson*(): string =
  ## dunda ro smuni ta'i `JSON` poi le papri cu tcidu ke'a
  ##   .i ro valsi cu sinxa pa liste be le glico valsi .e le smuni
  ##   .i fliba va'o lo nu pa liste poi selpu'i cu na mapti le stosni
  let
    gismu = readSource("gismu.txt")
    cmavo = readSource("cmavo.txt")
  for (name, source, pin) in [("gismu.txt", gismu, DIGEST_GISMU),
      ("cmavo.txt", cmavo, DIGEST_CMAVO)]:
    if source.digest != pin:
      raise newException(ValueError, "List should match its pin; got `" & name & "` at `" &
          source.digest & "`.")
  var node = newJObject()
  for word, meaning in toMeanings(gismu.text, cmavo.text):
    node[word] = %[meaning.gloss, meaning.definition]
  $node
