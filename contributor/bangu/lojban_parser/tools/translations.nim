## cpacu lo xe fanva be fi la lojban. gi'e tcidu lo ju'agri pe le xe fanva
##   .i lo cipra cu tcidu le xe fanva va'o lo nu le xe fanva cu zvati
##   .i `build.nim` pilno le vi datnyvei
##
## ni'o `Architect` jdice `D3 a` bu'u `#819`
##   .i ro xe fanva cu ponse lo stosni gi'e na selra'e `delegations`
##   .i ki'u bo no fanva cu cusku lo nu curmi
##
## ni'o `Architect` jdice `D5 c`
##   .i lo cipra cu tcidu `Alice` .e `Oz` va'o lo nu le stopapri cu zvati
##   .i le cipskami cu vasru no papri
##   .i se ki'u bo le cipskami cu na tcidu le re xe fanva
##
## ni'o lo minde cu cpacu ro papri sepi'o `curl` gi'e punji le papri fi `DIRECTORY_TRANSLATIONS`
##   .i `.gitignore` rinka lo nu no nu ralte cu vasru `DIRECTORY_TRANSLATIONS`
##   .i le minde cu karbi lo snina'u be ro papri le stosni
##   .i va'o lo nu pa papri cu frica le stosni kei le minde cu cusku lo cmene be le papri gi'e no
##       roi tcidu le papri
##
## ni'o le snina'u cu sinxa le papri ba lo nu ro jgena po'u `script` selvi'u ta'i lo nu `cll.nim`
##     vimcu le jgena
##   .i ki'u bo le sabji pe `Alice` ciska pa jgena po'u `script` zi'e poi frica ca ro nu cpedu
##   .i le selci'a pe le xe fanva no roi vasru lo jgena po'u `script`
##
## ni'o lo ju'agri cu du lo selci'a pe pa jgena po'u `p`
##   .i ro tcita cu selvi'u
##   .i ro sinxa pe `HTML` zi'e poi `&` krasi ke'a se basti lo lerfu poi le sinxa cu sinxa ke'a
##   .i ro porsi be lo kutle'u cu binxo pa kutle'u
##
## ni'o lo nu tcidu cu vimcu ro sinxa poi `CLL` na skicu ke'a
##   .i le sinxa cu du zoi gy. « » .gy. jo'u zoi gy. – — .gy. jo'u lo cukla grile'u jo'u zoi gy. :
##       .gy. jo'u lo tarle'u jo'u zoi gy. ? .gy. jo'u zoi gy. ! .gy. jo'u lo sitle'u jo'u lo sinxa
##       poi gapru pa karsna
##   .i lo sinxa poi gapru pa karsna cu du `accent` .a `breve`
##   .i lo brale'u cu stali
##   .i ki'u bo `CLL 3.9` skicu lo brale'u ta'i lo sinxa be lo nu basna
##
## ni'o jdima fa lo nu `accent` pe `Oz` sinxa lo nu basna
##   .i lo nu tcidu cu vimcu `accent`
##   .i se ki'u bo ro brivla cu se tcidu ta'i lo nu basna kei poi lo tarmi be le brivla cu dunda
##       ke'a
##   .i `CLL 3.9` skicu ro drata nu basna ta'i lo nu na ralju
##   .i ro le drata nu basna cu terdu'a no selci'asni
##
## ni'o le papri pe `Oz` selci'a ja'i `Windows-1252`
##   .i ku'i lo stedu be le papri cu cusku `UTF-8`
##   .i le tcidu cu galfi le papri
##
## ni'o jdima fa lo nu le vi datnyvei cu basti so'u sinxa poi vasru lo cmene
##   .i le so'u sinxa cu du le sinxa poi le papri cu pilno ke'a
##   .i lo datsni poi vasru lo cmene cu stali
##   .i le porsi be lo valsi cu to'e curmi lo lerfu po'u `&` pe le sinxa gi'e cusku le sinxa

{.experimental: "strictFuncs".}

import std/[encodings, options, os, osproc, strutils]
from std/unicode import `$`, Rune

import ./cll


type Translation* = object
  ## pa xe fanva poi lo cipra cu tcidu ke'a va'o lo nu lo stopapri be ke'a cu zvati
  name*: string
    ## lo cmene be le papri ne'i `DIRECTORY_TRANSLATIONS`
    ##   .i le cmene cu claxu lo fampau po'u `.html`
  title*: string  ## lo cmene be lo selfi'i be'o .e le fanva be le selfi'i
  url*: string  ## lo judri poi le papri cu selcpa fi ke'a
  digest*: string
    ## `SHA-256` pe le papri poi selcpa de'i `2026-11-06`
    ##   .i ro jgena po'u `script` selvi'u
  encoding*: string  ## le tadji be lo nu le stuzi pe le papri cu sinxa lo lerfu


const
  DIRECTORY_TRANSLATIONS* = "build/translations"
    ## lo datnyveiste poi zvati ne'i le vi selgu'a gi'e vasru le papri
  TRANSLATIONS* = [
    Translation(
      name: "alis",
      title: "Alice's Adventures in Wonderland, by xorxes",
      url: "https://alis.lojban.org/",
      digest: "7403e92551f5de7d96b5f8d2e5ebae34cafa8535bdf7cb9cdf9da2e6c2078687",
      encoding: "UTF-8",
    ),
    Translation(
      name: "oz",
      title: "The Wonderful Wizard of Oz, by selpa'i",
      url: "https://selpahi.de/oz.html",
      digest: "adfde23a848147ed1f7d56e7b33a3b3b65e3d88e00b1ab41759963c443847ea6",
      encoding: "CP1252",
    ),
  ]
    ## lo xe fanva be `Alice` .e `Oz` be'o poi `D5 c` cusku lo cmene be ke'a
  MARKS_DROPPED = [
    "«", "»", "—", "–", "\u0096", "\u0097", "-", "(", ")", ":", "*", "!", "?",
    "\"", "¬",
  ]
    ## lo sinxa poi `CLL` na skicu ke'a zi'e noi lo nu tcidu cu vimcu ke'a
    ##   .i le sinxa cu du zoi gy. « » .gy. jo'u zoi gy. – — .gy. jo'u lo datyjufsni
  VOWELS_MARKED = [
    ("à", "a"), ("á", "a"), ("è", "e"), ("é", "e"), ("ì", "i"),
    ("í", "i"), ("ò", "o"), ("ó", "o"), ("ù", "u"), ("ú", "u"),
    ("ŭ", "u"), ("ĭ", "i"), ("À", "A"), ("Á", "A"), ("È", "E"),
    ("É", "E"), ("Ì", "I"), ("Í", "I"), ("Ò", "O"), ("Ó", "O"),
    ("Ù", "U"), ("Ú", "U"), ("Ŭ", "U"), ("Ĭ", "I"),
  ]
    ## lo karsna poi se gapru `accent` .a `breve` ku'o jo'u lo karsna poi lo nu tcidu cu ralte ke'a
    ##   .i lo ka brale'u cu stali
  ENTITIES_NAMED = [
    ("nbsp", " "), ("amp", "&"), ("lt", "<"), ("gt", ">"), ("quot", "\""), ("apos", "'"),
    ("agrave", "à"),
  ]
    ## lo sinxa poi vasru lo cmene gi'e selpli le papri
    ##   .i ro le sinxa cu kansa lo selci'a poi le sinxa cu sinxa ke'a



#[ ni'o ni'o ni'o lo nu tcidu ]#

func toEntitiesDecoded(text: string): string =
  ## galfi ro sinxa poi `ENTITIES_NAMED` vasru ke'a ku'o .e ro sinxa poi vasru lo namcu ku'o lo
  ##     lerfu poi le sinxa cu sinxa ke'a
  var at = 0
  while at < text.len:
    let closing = (if text[at] == '&': text.find(';', at) else: -1)
    if closing < 0 or closing - at > 10:
      result.add text[at]
      inc at
      continue
    let name = text[at+1..<closing]
    var decoded = none(string)
    if name.startsWith("#x"): decoded = some($Rune(parseHexInt(name[2 .. ^1])))
    elif name.startsWith("#"): decoded = some($Rune(parseInt(name[1 .. ^1])))
    else:
      for (entity, text_entity) in ENTITIES_NAMED:
        if entity == name: decoded = some(text_entity)
    if decoded.isNone:
      result.add text[at]
      inc at
      continue
    result.add decoded.get
    at = closing + 1


func toReading(text: string): string =
  ## vimcu ro sinxa poi `CLL` na skicu ke'a
  ##   .i ralte ro karsna poi lo sinxa po'u `accent` .a `breve` gapru ke'a
  ##   .i ro porsi be lo kutle'u cu binxo pa kutle'u
  var kept = text
  for mark in MARKS_DROPPED: kept = kept.replace(mark, " ")
  for (marked, vowel) in VOWELS_MARKED: kept = kept.replace(marked, vowel)
  kept.splitWhitespace.join(" ")


func paragraphs*(page: string): seq[string] =
  ## tcidu lo selci'a pe ro jgena po'u `p` zi'e pe le papri ta'i lo nu lo nu tcidu cu ralte le
  ##     selci'a
  ##   .i lo kunti ju'agri cu selvi'u
  let lower = page.toLowerAscii
  var at = 0
  while true:
    let opening = lower.find("<p", at)
    if opening < 0: break
    let after = opening + 2
    if after < lower.len and lower[after] notin {'>', ' ', '\t', '\n', '\r'}:
      at = after
      continue
    let
      start = lower.find('>', after) + 1
      closing = lower.find("</p>", start)
    if start <= 0 or closing < 0: break
    var
      text: string
      depth = 0
    for letter in page[start..<closing]:
      if letter == '<': inc depth
      elif letter == '>': depth = max(0, depth - 1)
      elif depth == 0: text.add letter
      if letter == '>': text.add ' '
    let reading = text.toEntitiesDecoded.toReading
    if reading.len > 0: result.add reading
    at = closing + 4


proc readDigest(path: string): string =
  ## zbasu lo snina'u be le papri poi zvati `path` ku'o sepi'o `sha256sum`
  ##   .i ro jgena po'u `script` selvi'u pu lo nu zbasu
  let (output, code) = execCmdEx("sha256sum", input = readFile(path).toPageXml)
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  output.splitWhitespace[0]


proc readTranslation*(translation: Translation, root: string): Option[seq[string]] =
  ## tcidu lo ju'agri pe le xe fanva poi cnita `root`
  ##   .i va'o lo nu le papri cu na zvati gi'a na mapti le stosni kei le fancu cu dunda `none`
  let path = root / DIRECTORY_TRANSLATIONS / translation.name & ".html"
  if not fileExists(path) or path.readDigest != translation.digest: return none(seq[string])
  let page =
    if translation.encoding == "UTF-8": readFile(path)
    else: convert(readFile(path), "UTF-8", translation.encoding)
  some(page.paragraphs)


proc fetchTranslation*(translation: Translation, root: string): string =
  ## cpacu le papri pe le xe fanva gi'e punji le papri fi `DIRECTORY_TRANSLATIONS` poi cnita `root`
  ##   .i dunda lo snina'u be le papri
  let path = root / DIRECTORY_TRANSLATIONS / translation.name & ".html"
  createDir(path.parentDir)
  let (output, code) = execCmdEx(
    "curl -sS -L --max-time 120 -o " & quoteShell(path) & " " & quoteShell(translation.url),
  )
  if code != 0: quit "Page could not be fetched; got `" & output.strip & "` for `" &
      translation.url & "`.", 1
  path.readDigest
