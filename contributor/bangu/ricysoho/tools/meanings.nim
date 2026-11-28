## tcidu lo smuni be ro valsi pe le gimste .e le ma'oste .e le jvoste vu'o pe `Logical Language
##     Group` mu'i le ctuca pe le papri pe lo linji
##   .i tcidu `gismu.txt` .e `cmavo.txt` .e `lujvo.txt` ta'i `readSource` pe `lists.nim` gi'e karbi
##       le snina'u le stosni
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
##   .i le jvoste cu jmina lo smuni be ro valsi poi no drata liste cu vasru ke'a
##
## ni'o `lujvo.txt` ciska lo tanru sepi'o re sinxa
##   .i `word:part+part:gloss:places` sinxa lo tanru sepi'o lo jbovla
##   .i `word#keyword+keyword:gloss:places` sinxa lo tanru sepi'o lo glikikyvla
##   .i `:` poi zvati lo jbini be `[]` .a `()` cu fendi no datnypau
##   .i le glico valsi cu du le datnypau poi lidne le pagbu
##   .i ku'i lo datnypau poi vasru `+` cu ciska lo tanru gi'e na glico valsi
##   .i lo datnypau poi kunti gi'a cfari fi `$` cu na glico valsi
##   .i pa linji poi lo valsi pe ke'a na se gunma lo lojbo lerfu po'o cu na se tcidu
##   .i va'o lo nu re linji cu vasru pa valsi kei le pamoi linji cu se tcidu

{.experimental: "strictFuncs".}

import std/[json, options, strutils, tables]

import ./lists


type Meaning* = object  ## le smuni be pa valsi
  gloss*: string  ## le glico valsi poi sinxa le valsi
  definition*: string
    ## le glico smuni be le valsi
    ##   .i le datnypau cu kunti va'o lo lujvo
  parts*: string
    ## ro pagbu be le lujvo ta'i le selci'a pe `lujvo.txt`
    ##   .i le datnypau cu kunti va'o lo gismu .e lo cmavo
  is_english*: bool  ## le linji cu ciska le pagbu sepi'o lo glikikyvla be lo gismu ba `#`


const  # le stuzi be ro datnypau ne'i le re liste
  COLUMNS_GISMU* = [(2, 6), (21, 40), (63, 158)]
    ## le stuzi be le valsi .e le glico valsi .e le smuni ne'i `gismu.txt`
  COLUMNS_CMAVO* = [(1, 11), (21, 61), (63, 158)]
    ## le stuzi be le valsi .e le glico valsi .e le smuni ne'i `cmavo.txt`
  COLUMN_SELMAHO = (12, 20)
    ## le stuzi be le selma'o ne'i `cmavo.txt`
    ##   .i lo lerfu po'u zoi gy. * .gy. cu sinxa lo ma'orgunma .a lo jufpau
  LETTERS_LUJVO = {'a' .. 'z', '\''}  ## lo lerfu pe lo valsi pe `lujvo.txt`



#[ ni'o ni'o ni'o lo nu tcidu ]#

func fieldsLujvo*(line: string): seq[string] =
  ## ro datnypau pe pa linji pe `lujvo.txt`
  ##   .i `:` poi zvati lo jbini be `[]` .a `()` cu fendi no datnypau
  var depth = 0
  result = @[""]
  for c in line:
    if c in {'[', '('}: inc depth
    elif c in {']', ')'}: depth = max(depth - 1, 0)
    if c == ':' and depth == 0: result.add ""
    else: result[^1].add c


func toMeaningLujvo*(line: string): Option[(string, Meaning)] =
  ## le valsi .e le smuni be pa linji pe `lujvo.txt`
  ##   .i le glico valsi cu du le datnypau poi lidne le pagbu gi'e vasru no lerfu po'u `+`
  ##   .i no da va'o lo nu le valsi na se gunma lo lojbo lerfu po'o
  let
    fields = line.fieldsLujvo
    head = fields[0].split('#', maxsplit = 1)
    is_english = head.len == 2
  if head[0].len == 0 or not head[0].allCharsInSet(LETTERS_LUJVO): return none((string, Meaning))
  var at = if is_english: 1 else: 2
  while at < fields.len and '+' in fields[at]: inc at
  let gloss = if at < fields.len: fields[at].strip else: ""
  some((head[0], Meaning(gloss: if gloss.startsWith('$'): "" else: gloss,
      parts: if is_english: head[1] elif fields.len > 1: fields[1] else: "",
      is_english: is_english)))


func toMeanings*(gismu, cmavo, lujvo: string): OrderedTable[string, Meaning] =
  ## tcidu ro smuni pe `gismu.txt` .e `cmavo.txt` .e `lujvo.txt`
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
  for line in lujvo.splitLines:
    let found = line.toMeaningLujvo
    if found.isSome and found.get[0] notin result: result[found.get[0]] = found.get[1]


proc meaningsJson*(): string =
  ## dunda ro smuni ta'i `JSON` poi le papri cu tcidu ke'a
  ##   .i ro valsi cu sinxa pa liste be le glico valsi .e le smuni
  ##   .i ro lujvo cu sinxa pa liste be le glico valsi .e le smuni .e ro pagbu .e `is_english`
  ##   .i fliba va'o lo nu pa liste poi selpu'i cu na mapti le stosni
  let
    gismu = readSource("gismu.txt")
    cmavo = readSource("cmavo.txt")
    lujvo = readSource("lujvo.txt")
  for (name, source, pin) in [("gismu.txt", gismu, DIGEST_GISMU),
      ("cmavo.txt", cmavo, DIGEST_CMAVO), ("lujvo.txt", lujvo, DIGEST_LUJVO)]:
    if source.digest != pin:
      raise newException(ValueError, "List should match its pin; got `" & name & "` at `" &
          source.digest & "`.")
  var node = newJObject()
  for word, meaning in toMeanings(gismu.text, cmavo.text, lujvo.text):
    node[word] = if meaning.parts.len == 0: %[meaning.gloss, meaning.definition]
        else: %*[meaning.gloss, meaning.definition, meaning.parts, meaning.is_english]
  $node
