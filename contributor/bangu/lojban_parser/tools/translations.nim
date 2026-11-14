## cpacu lo xe fanva be fi la lojban. .i lo cipra cu tcidu le xe fanva va'o lo nu le xe fanva cu
##   zvati .i ro xe fanva cu ponse lo stodi sinxa gi'e na se ralte la'o gy. delegations .gy. .i ji'a
##   tcidu lo ju'agri pe le xe fanva .i `build.nim` cu pilno le vi datnyvei
##   .i la'o gy. Architect .gy. cu jdice `D3 a` bu'u `#819` .i ro xe fanva cu ponse lo stodi sinxa
##     gi'e na se ralte la'o gy. delegations .gy. .i ki'u bo no fanva cu cusku lo nu curmi .i la'o
##     gy. Architect .gy. cu jdice `D5 c` .i lo cipra cu tcidu la'o gy. Alice .gy. .e la'o gy. Oz
##     .gy. va'o lo nu le stodi papri cu zvati .i le cipra skami cu vasru no papri .i se ki'u bo le
##     cipra skami cu na tcidu le re xe fanva
##   .i lo minde cu cpacu ro papri sepi'o `curl` gi'e punji le papri fi `DIRECTORY_TRANSLATIONS` .i
##     `.gitignore` cu rinka lo nu no nu ralte cu vasru `DIRECTORY_TRANSLATIONS` .i le minde cu
##     karbi lo sinxa namcu be ro papri le stodi sinxa .i va'o lo nu pa papri cu frica le stodi
##     sinxa kei le minde cu cusku lo cmene be le papri gi'e no roi tcidu le papri
##     .i le sinxa namcu cu sinxa le papri ba lo nu ro jgena po'u `script` cu se vimcu ta'i lo nu
##       `cll.nim` cu vimcu le jgena .i ki'u bo le sabji pe la'o gy. Alice .gy. cu ciska pa jgena
##       po'u `script` zi'e poi frica ca ro nu cpedu .i le se ciska pe le xe fanva no roi vasru lo
##       jgena po'u `script`
##   .i lo ju'agri cu du lo se ciska pe pa jgena po'u `p` .i ro tcita cu se vimcu .i ro sinxa pe
##     la'o gy. HTML .gy. zi'e poi `&` cu krasi ke'a cu se basti lo lerfu poi le sinxa cu sinxa ke'a
##     .i ro porsi be lo kunti lerfu cu binxo pa kunti lerfu
##   .i lo nu tcidu cu vimcu ro sinxa poi la'o gy. CLL .gy. na skicu ke'a .i le sinxa cu du zoi gy.
##     « » .gy. jo'u zoi gy. – — .gy. jo'u lo cukla grile'u jo'u zoi gy. : .gy. jo'u lo tarci
##     lerfu .i ji'a le sinxa cu du zoi gy. ? .gy. jo'u zoi gy. ! .gy. jo'u lo sitna lerfu jo'u lo
##     sinxa poi gapru pa karsna .i lo sinxa poi gapru pa karsna cu du la'o gy. accent .gy. .a la'o
##     gy. breve .gy. .i lo barda lerfu cu stali .i ki'u bo `CLL 3.9` cu skicu lo barda lerfu ta'i
##     lo sinxa be lo nu basna
##     .i jdima fa lo nu la'o gy. accent .gy. pe la'o gy. Oz .gy. cu sinxa lo nu basna .i lo nu
##       tcidu cu vimcu la'o gy. accent .gy. .i se ki'u bo ro brivla cu se tcidu ta'i lo nu basna
##       kei poi lo tarmi be le brivla cu dunda ke'a .i `CLL 3.9` cu skicu ro drata nu basna ta'i lo
##       nu na ralju .i ro le drata nu basna cu te dunda no se ciska sinxa
##   .i le papri pe la'o gy. Oz .gy. cu se ciska ja'i la'o gy. Windows-1252 .gy. .i ku'i lo stedu be
##     le papri cu cusku la'o gy. UTF-8 .gy. .i le tcidu cu galfi le papri
##   .i jdima fa lo nu le vi datnyvei cu basti so'u sinxa poi vasru lo cmene .i le so'u sinxa cu du
##     le sinxa poi le papri cu pilno ke'a .i lo drata sinxa poi vasru lo cmene cu stali .i le porsi
##     be lo valsi cu to'e curmi lo lerfu po'u `&` pe le sinxa gi'e cusku le sinxa

{.experimental: "strictFuncs".}

import std/[encodings, options, os, osproc, strutils]
from std/unicode import `$`, Rune

import ./cll


type Translation* = object
  ## pa xe fanva poi lo cipra cu tcidu ke'a va'o lo nu lo stodi papri be ke'a cu zvati
  name*: string
    ## lo cmene be le papri ne'i `DIRECTORY_TRANSLATIONS` .i le cmene cu claxu lo fanmo pagbu po'u
    ##   `.html`
  title*: string  ## lo cmene be lo se finti be'o .e le fanva be le se finti
  url*: string  ## lo judri poi le papri cu se cpacu fi ke'a
  digest*: string
    ## la'o gy. SHA-256 .gy. pe le papri poi se cpacu de'i `2026-11-06` .i ro jgena po'u `script` cu
    ##   se vimcu
  encoding*: string  ## le tadji be lo nu le stuzi pe le papri cu sinxa lo lerfu


const
  DIRECTORY_TRANSLATIONS* = "build/translations"
    ## lo datnyveiste poi zvati ne'i le vi se gunka gi'e vasru le papri
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
    ## lo xe fanva be la'o gy. Alice .gy. .e la'o gy. Oz .gy. be'o poi `D5 c` cu cusku lo cmene be
    ##   ke'a
  MARKS_DROPPED = [
    "«", "»", "—", "–", "\u0096", "\u0097", "-", "(", ")", ":", "*", "!", "?",
    "\"", "¬",
  ]
    ## lo sinxa poi la'o gy. CLL .gy. na skicu ke'a zi'e noi lo nu tcidu cu vimcu ke'a .i le sinxa
    ##   cu du zoi gy. « » .gy. jo'u zoi gy. – — .gy. jo'u lo drata jufra sinxa
  VOWELS_MARKED = [
    ("à", "a"), ("á", "a"), ("è", "e"), ("é", "e"), ("ì", "i"),
    ("í", "i"), ("ò", "o"), ("ó", "o"), ("ù", "u"), ("ú", "u"),
    ("ŭ", "u"), ("ĭ", "i"), ("À", "A"), ("Á", "A"), ("È", "E"),
    ("É", "E"), ("Ì", "I"), ("Í", "I"), ("Ò", "O"), ("Ó", "O"),
    ("Ù", "U"), ("Ú", "U"), ("Ŭ", "U"), ("Ĭ", "I"),
  ]
    ## lo karsna poi se gapru la'o gy. accent .gy. .a la'o gy. breve .gy. ku'o jo'u lo karsna poi lo
    ##   nu tcidu cu ralte ke'a .i lo ka barda lerfu cu stali
  ENTITIES_NAMED = [
    ("nbsp", " "), ("amp", "&"), ("lt", "<"), ("gt", ">"), ("quot", "\""), ("apos", "'"),
    ("agrave", "à"),
  ]
    ## lo sinxa poi vasru lo cmene gi'e se pilno le papri .i ro le sinxa cu kansa lo se ciska poi le
    ##   sinxa cu sinxa ke'a



#[ lo nu tcidu ]#

func toEntitiesDecoded(text: string): string =
  ## galfi ro sinxa poi `ENTITIES_NAMED` cu vasru ke'a ku'o .e ro sinxa poi vasru lo namcu ku'o lo
  ##   lerfu poi le sinxa cu sinxa ke'a
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
  ## vimcu ro sinxa poi la'o gy. CLL .gy. na skicu ke'a .i ralte ro karsna poi lo sinxa po'u la'o
  ##   gy. accent .gy. .a la'o gy. breve .gy. ge'u cu gapru ke'a .i ro porsi be lo kunti lerfu cu
  ##   binxo pa kunti lerfu
  var kept = text
  for mark in MARKS_DROPPED: kept = kept.replace(mark, " ")
  for (marked, vowel) in VOWELS_MARKED: kept = kept.replace(marked, vowel)
  kept.splitWhitespace.join(" ")


func paragraphs*(page: string): seq[string] =
  ## tcidu lo se ciska pe ro jgena po'u `p` zi'e pe le papri ta'i lo nu lo nu tcidu cu ralte le se
  ##   ciska .i lo kunti ju'agri cu se vimcu
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
  ## zbasu lo sinxa namcu be le papri poi zvati `path` ku'o sepi'o `sha256sum` .i ro jgena po'u
  ##   `script` cu se vimcu pu lo nu zbasu
  let (output, code) = execCmdEx("sha256sum", input = readFile(path).toPageXml)
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  output.splitWhitespace[0]


proc readTranslation*(translation: Translation, root: string): Option[seq[string]] =
  ## tcidu lo ju'agri pe le xe fanva poi cnita `root` .i va'o lo nu le papri cu na zvati gi'a na
  ##   mapti le stodi sinxa kei le fancu cu dunda `none`
  let path = root / DIRECTORY_TRANSLATIONS / translation.name & ".html"
  if not fileExists(path) or path.readDigest != translation.digest: return none(seq[string])
  let page =
    if translation.encoding == "UTF-8": readFile(path)
    else: convert(readFile(path), "UTF-8", translation.encoding)
  some(page.paragraphs)


proc fetchTranslation*(translation: Translation, root: string): string =
  ## cpacu le papri pe le xe fanva gi'e punji le papri fi `DIRECTORY_TRANSLATIONS` poi cnita `root`
  ##   .i ji'a dunda lo sinxa namcu be le papri
  let path = root / DIRECTORY_TRANSLATIONS / translation.name & ".html"
  createDir(path.parentDir)
  let (output, code) = execCmdEx(
    "curl -sS -L --max-time 120 -o " & quoteShell(path) & " " & quoteShell(translation.url),
  )
  if code != 0: quit "Page could not be fetched; got `" & output.strip & "` for `" &
      translation.url & "`.", 1
  path.readDigest
