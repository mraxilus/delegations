## tcidu lo datselci'a poi lo cipra cu cipra le genturfa'i sepi'o ke'a
##   .i le selci'a cu du lo liste poi `lojban-common` punji ke'a
##   .i ro le liste cu ponse lo stosnina'u
##   .i ja'i `D3 a` pe `#819` lo datselci'a cu cipra le genturfa'i gi'e ponse lo stosnina'u gi'e na
##       zvati le vreji
##
## ni'o le jvoste cu dunda lo smuni gi'e no roi jdice lo du'u xu kau lo valsi cu drani
##   .i se ki'u bo le genturfa'i cu ralte no pagbu be le liste
##   .i ku'i va'o lo nu `CLL` tavla fi ro lujvo kei lo valsi pe le liste cu stali ta'i lo selcmi be
##       lo lujvo poi lo prenu cu ciska ke'a
##
## ni'o le tcidu cu dunda `none` va'o lo nu le datnyvei cu na zvati gi'a cenba lo snina'u
##   .i se ki'u bo ro cipra poi tcidu le datnyvei cu na zukte gi'e cusku lo krinu to `Article IX.9`
##       toi
##   .i lo minde po'u `system` pe `tools/build.nim` cusku le bakfu
##   .i se ki'u bo `CI` punji le bakfu
##
## ni'o `lujvo.txt` ciska lo tanru sepi'o re sinxa
##   .i `word:part+part:gloss` sinxa lo tanru sepi'o lo jbovla
##   .i `word#keyword+keyword:gloss` sinxa lo tanru sepi'o lo glikikyvla
##
## ni'o le tcidu cu ralte lo linji va'o lo nu lo valsi pe le linji cu se gunma lo lojbo lerfu po'o
##     kei gi'e ralte lo pagbu be le linji va'o lo nu le linji cu ciska su'o re pagbu kei .e lo nu
##     ro jbopau cu se gunma lo jbole'u
##   .i le genturfa'i cu vasru no glivla
##   .i se ki'u bo le cipra cu kancu lo kikyvla pe le linji gi'e no roi tcidu le kikyvla
##   .i jdima fa lo nu lo linji poi ciska lo jufpau ne'i lo stuzi be lo valsi mu'u lo'u datkypi'u
##       gairki'e le'u cmima no selcmi
##
## ni'o `cmavo.txt` ciska lo cmavo ne'i le pamoi stuzi bi'o le 11moi stuzi gi'e ralte denpa bu poi
##     sinxa lo denpa to `CLL 3.3` toi
##   .i `cmavo.txt` ciska lo selma'o ne'i le 12moi stuzi bi'o le 20moi stuzi
##   .i `*` pe le stuzi cu sinxa lo gunma be lo cmavo be'o noi se tcidu ta'i su'o re cmavo

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils]

import ../../tools/lists


type  # lo klesi pe lo linji pe le liste
  LineLujvo* = object
    ## pa linji pe `lujvo.txt` zi'e poi lo valsi pe ke'a se gunma lo lojbo lerfu po'o
    word*: string  ## le lujvo ta'i le lerfu poi le linji cu ciska ke'a
    is_english*: bool  ## le linji cu ciska le tanru sepi'o lo glikikyvla be lo gismu ba `#`
    parts*: seq[string]
      ## ro pagbu be le tanru poi le linji cu ciska ke'a ku'o ta'i le porsi pe le linji
      ##   .i le liste cu kunti va'o lo nu le linji cu ciska su'e pa pagbu

  LineCmavo* = object
    ## pa linji pe `cmavo.txt`
    ##   .i le linji cu ciska pa cmavo .a pa gunma be su'o re cmavo
    word*: string
      ## le cmavo ta'i le lerfu poi le linji cu ciska ke'a
      ##   .i le lerfu cu ralte denpa bu
    is_compound*: bool  ## le selma'o stuzi cu sinxa su'o re cmavo .a su'o re valsi
    selmaho*: string
      ## le selma'o stuzi ta'i le lerfu poi le linji cu ciska ke'a
      ##   .i le lerfu cu ralte lo klesi be le selma'o be'o .e lo sinxa


const LETTERS_LOJBAN = {'a' .. 'z', '\''}  ## lo lerfu pe lo valsi pe lo selra'eli'i


func isLetters(text: string): bool =
  ## jdice lo du'u xu kau le selci'a cu na kunti gi'e se gunma lo jbole'u .e `'` po'o
  text.len > 0 and text.allCharsInSet(LETTERS_LOJBAN)


func toLinesLujvo*(text: string): seq[LineLujvo] =
  ## tcidu ro linji pe `lujvo.txt` zi'e poi lo valsi pe ke'a se gunma lo lojbo lerfu po'o ku'o ta'i
  ##     le porsi pe le datnyvei
  for line in text.splitLines:
    let
      fields = line.split(':')
      is_english = '#' in fields[0]
      word = fields[0].split('#', maxsplit = 1)[0]
    if not word.isLetters: continue
    let written =
      if is_english: fields[0].split('#', maxsplit = 1)[1]
      elif fields.len >= 2: fields[1]
      else: ""
    var parts = written.split('+')
    if parts.len < 2 or not parts.allIt(it.len > 0 and (is_english or it.isLetters)): parts = @[]
    result.add LineLujvo(word: word, is_english: is_english, parts: parts)


proc readLinesLujvo*(): Option[seq[LineLujvo]] =
  ## tcidu `lujvo.txt` noi selpu'i
  ##   .i dunda `none` va'o lo nu le datnyvei cu na zvati gi'a ponse lo snina'u poi na du
  ##       `DIGEST_LUJVO`
  if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "lujvo.txt"): return
  let source = readSource("lujvo.txt")
  if source.digest != DIGEST_LUJVO: return
  some(source.text.toLinesLujvo)


func toLinesCmavo*(text: string): seq[LineCmavo] =
  ## tcidu ro linji pe `cmavo.txt` zi'e poi se lidne le krali'i ku'o ta'i le porsi pe le datnyvei
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    let selmaho = line[min(11, line.len) ..< min(20, line.len)]
    result.add LineCmavo(
      word: line[0 ..< min(11, line.len)].strip,
      is_compound: '*' in selmaho,
      selmaho: selmaho.strip,
    )


proc readLinesCmavo*(): Option[seq[LineCmavo]] =
  ## tcidu `cmavo.txt` noi selpu'i
  ##   .i dunda `none` va'o lo nu le datnyvei cu na zvati gi'a ponse lo snina'u poi na du
  ##       `DIGEST_CMAVO`
  if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "cmavo.txt"): return
  let source = readSource("cmavo.txt")
  if source.digest != DIGEST_CMAVO: return
  some(source.text.toLinesCmavo)
