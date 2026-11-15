## tcidu lo drata se ciska poi lo cipra cu cipra le genturfa'i sepi'o ke'a
##   .i le se ciska cu du lo liste poi `lojban-common` cu punji ke'a
##   .i ro le liste cu ponse lo stodi sinxa namcu
##   .i ja'i `D3 a` pe `#819` lo drata se ciska cu cipra le genturfa'i gi'e ponse lo stodi sinxa
##     namcu gi'e na zvati le vreji
##   .i le lujvo liste cu dunda lo smuni gi'e no roi jdice lo du'u xu kau lo valsi cu drani
##   .i se ki'u bo le genturfa'i cu ralte no pagbu be le liste
##   .i ku'i va'o lo nu la'o gy. CLL .gy. cu tavla fi ro lujvo kei lo valsi pe le liste cu stali
##     ta'i lo selcmi be lo lujvo poi lo prenu cu ciska ke'a
##   .i le tcidu cu dunda `none` va'o lo nu le datnyvei cu na zvati gi'a cenba lo sinxa namcu
##   .i se ki'u bo ro cipra poi tcidu le datnyvei cu na zukte gi'e cusku lo krinu to `Article IX.9`
##     toi
##   .i lo minde po'u `system` pe `tools/build.nim` cu cusku le bakfu
##   .i se ki'u bo la'o gy. CI .gy. cu punji le bakfu
##   .i `lujvo.txt` cu ciska lo tanru sepi'o re sinxa
##   .i `word:part+part:gloss` cu sinxa lo tanru sepi'o lo lojbo valsi
##   .i `word#keyword+keyword:gloss` cu sinxa lo tanru sepi'o lo glico ckiku valsi
##   .i le tcidu cu ralte lo linji va'o lo nu lo valsi pe le linji cu se gunma lo lojbo lerfu po'o
##   .i le tcidu cu ralte ji'a lo pagbu be le linji va'o lo nu le linji cu ciska su'o re pagbu kei
##     .e lo nu ro lojbo pagbu cu se gunma lo lojbo lerfu
##   .i le genturfa'i cu vasru no glico valsi
##   .i se ki'u bo le cipra cu kancu lo ckiku valsi pe le linji gi'e no roi tcidu le ckiku valsi
##   .i jdima fa lo nu lo linji poi ciska lo jufra pagbu ne'i lo stuzi be lo valsi mu'u lo'u
##     datkypi'u gairki'e le'u cu cmima no selcmi
##   .i `cmavo.txt` cu ciska lo cmavo ne'i le pamoi stuzi bi'o le papamoi stuzi gi'e ralte denpa bu
##     poi sinxa lo denpa to `CLL 3.3` toi
##   .i `cmavo.txt` cu ciska lo selma'o ne'i le paremoi stuzi bi'o le renomoi stuzi
##   .i `*` pe le stuzi cu sinxa lo gunma be lo cmavo
##   .i le gunma cu se tcidu ta'i su'o re cmavo

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils]

import ../../tools/lists


type
  LineLujvo* = object
    ## pa linji pe `lujvo.txt` zi'e poi lo valsi pe ke'a cu se gunma lo lojbo lerfu po'o
    word*: string  ## le lujvo ta'i le lerfu poi le linji cu ciska ke'a
    is_english*: bool  ## le linji cu ciska le tanru sepi'o lo glico ckiku valsi be lo gismu ba `#`
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


const LETTERS_LOJBAN = {'a' .. 'z', '\''}  ## lo lerfu pe lo valsi pe lo se ralte linji


func isLetters(text: string): bool =
  ## jdice lo du'u xu kau le se ciska cu na kunti gi'e se gunma lo lojbo lerfu .e `'` po'o
  text.len > 0 and text.allCharsInSet(LETTERS_LOJBAN)


func toLinesLujvo*(text: string): seq[LineLujvo] =
  ## tcidu ro linji pe `lujvo.txt` zi'e poi lo valsi pe ke'a cu se gunma lo lojbo lerfu po'o ku'o
  ##   ta'i le porsi pe le datnyvei
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
  ## tcidu `lujvo.txt` noi se punji
  ##   .i dunda `none` va'o lo nu le datnyvei cu na zvati kei .a lo nu lo sinxa namcu be le datnyvei
  ##     cu na du `DIGEST_LUJVO`
  if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "lujvo.txt"): return
  let source = readSource("lujvo.txt")
  if source.digest != DIGEST_LUJVO: return
  some(source.text.toLinesLujvo)


func toLinesCmavo*(text: string): seq[LineCmavo] =
  ## tcidu ro linji pe `cmavo.txt` zi'e poi se lidne le krasi linji ku'o ta'i le porsi pe le
  ##   datnyvei
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    let selmaho = line[min(11, line.len) ..< min(20, line.len)]
    result.add LineCmavo(
      word: line[0 ..< min(11, line.len)].strip,
      is_compound: '*' in selmaho,
      selmaho: selmaho.strip,
    )


proc readLinesCmavo*(): Option[seq[LineCmavo]] =
  ## tcidu `cmavo.txt` noi se punji
  ##   .i dunda `none` va'o lo nu le datnyvei cu na zvati kei .a lo nu lo sinxa namcu be le datnyvei
  ##     cu na du `DIGEST_CMAVO`
  if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "cmavo.txt"): return
  let source = readSource("cmavo.txt")
  if source.digest != DIGEST_CMAVO: return
  some(source.text.toLinesCmavo)
