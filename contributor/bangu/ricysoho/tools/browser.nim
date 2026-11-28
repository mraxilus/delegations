## pilno ro cipra pe le vi selgu'a ge'u zi'e poi fasnu ne'i lo tcidu be lo papri ku'o ta'i lo minde
##     po'u `drive`
##   .i zbasu le samtci .e le papri
##   .i fanva ro cipra pe `tests/browser/` ge'u .e le crepu fi `JavaScript`
##   .i ciska lo selci'a .e lo se cipra poi lo cipra cu tcidu ke'a
##   .i ro le selci'a .e ro le se cipra cu se kansa lo seldu'a be le jbezba
##   .i pilno ro cipra ne'i `headless Chromium` to `drive.nim` toi
##   .i tcidu le papri pe lo mivyselci'a ge'u .e le tropapri poi `koch drive` ciska ke'a ku'o sepi'o
##       le crepu gi'e ciska le se tcidu fi `written.json`
##
##   |------------|-------------------------------------------------------------------------------|
##   | lo fancu   | lo smuni                                                                      |
##   |------------|-------------------------------------------------------------------------------|
##   | `runDrive` | zbasu je pilno ro cipra .e le crepu ne'i `Chromium`                           |
##   |            | .i li 1 va'o lo nu fliba                                                     |
##   |------------|-------------------------------------------------------------------------------|
##
## ni'o le cipra pe lo mivyselci'a ge'u .e le cipra pe le papri cu rapfau ne'i pa papri poi lo javni
##     pe lo selvau be ke'a cu to'e curmi ro gunka
##   .i se ki'u bo lo cilta pe le papri cu basti le gunka pe le tcidu ta'i le samtci va'o lo nu le
##       papri cu to'e curmi lo gunka
##
## ni'o ro cipra pe le samtci cu fasnu ne'i pa papri pe vo'a ge'u zi'e noi cpacu le cipra po'o
##     sepi'o lo judri be le cipra
##   .i ro cipra cu vasru le cripu ta'i le samtci poi selbe'i
##   .i ki'u bo ro samtci poi `Nim` fanva ke'a punji ro fancu pe vo'a lo stuzi poi ro da ka'e pilno
##       ke'a
##   .i pa boi remoi samtci ne'i pa papri cu basti ro fancu pe le pamoi ge'u zi'e poi ke'a .e pa
##       fancu pe le remoi cu selcme pa cmene
##   .i le gunka pe le cipra pe lo mivyselci'a cu selkra le judri ta'i lo nu le gunka pe le samtci
##       cu selkra le judri be le samtci
##
## ni'o le cipra pe le papri cu fasnu ne'i pa papri poi selzba fi le calku
##   .i le cipra cu zvati le selci'a pe le papri gi'e basti le samtci pe le papri gi'e vasru ro
##       pagbu be le samtci
##   .i le gunka cu selkra pa `Blob` pe le selci'a pe le cipra ta'i le gunka pe le papri
##
## ni'o lo selfinselci'a pe le cipra pe lo mivyselci'a cu vasru pa valsi poi galfi lo pu valsi
##   .i pa datselci'a cu jorne lo jufra pe `Tatoeba`
##   .i le jbezba cu dunda le selci'a be fi `NIF` be'o pe ro selci'a ta'i lo nu `readTextParts`
##       dunda lo pagbu be lo selci'a poi mulseltcidu
##   .i le flalu pe `test_live.nim` cipra lo du'u lo mivyselci'a cu mintu le pagbu
##
## ni'o lo se cipra pe le cipra pe le papri cu du ro mupli pe le calku ge'u zi'e poi mulseltcidu
##     ku'o .e lo selci'a poi selbe'i ta'i lo porsi be lo valsi ku'o .e pa selci'a poi selci'a ta'i
##     lo nu ro pagbu cu sepli kei gi'e ca'o kalri ku'o .e pa nu galfi poi rinka lo nu pa ninytcidu
##     cu cfari
##   .i le jbezba cu ciska le pixra be ro se cipra sepi'o `drawn`
##   .i `drawn` pilno le selci'a be fi `NIF` be'o poi le jbetcidu be lo mivyselci'a cu dunda ke'a ca
##       lo nu cpacu le mitpau
##   .i va'o lo nu le tcidu cu sisti kei le selci'a cu mintu le selci'a be fi `NIF` be'o pe lo nu
##       tcidu le mulno se ciska to `live.nim`
##   .i lo flalu toi
##
## ni'o lo nu jmina ro se cipra cu pilno `drawnMerged` le ca selci'a be fi `NIF` be'o pe le se cipra
##   .i le rebla cu na se jmina ta'i lo nu le papri cu jmina
##
## ni'o ro selci'a .e ro se cipra .e ro pagbu .e ro pixra cu datnyvei gi'e vasru pa lerpoi
##   .i se ki'u bo no tarmi be lo datni cu zvati lo jbini be le sabji samtci .e le papri
##
## ni'o le crepu cu tcidu le papri pe lo mivyselci'a ge'u zi'e poi vasru no samtci
##   .i le papri cu mulseltcidu va'o lo nu no samtci cu zasti
##   .i ki'u bo lo nu zbasu cu punji lo jbexra be le pamoi mupli le papri
##
## ni'o ro lertai poi le papri cu cusku ke'a selkra pa `data:`
##   .i le crepu cu ciska lo stuzi pe ro lertai fi pa datnyvei pe le lertai
##   .i le datnyvei cu selcme lo snina'u gi'e zvati lo mlana be `written.json`
##   .i se ki'u bo `koch drive` tcidu lo stuzi poi lo viska cu cpacu ke'a to `font_stacks.nim` pe
##       `curator` toi
##   .i le tropapri cu cusku no lertai
##
## ni'o `Chromium` poi selpli cu du lo selcme be `LOJBAN_CHROMIUM`
##   .i va'o lo drata `Chromium` poi selpli cu du `headless shell` pe `Chrome for Testing` ge'u zi'e
##       noi `koch fetch-assets` cpacu ke'a lo sorcu pe `delegations` zi'e noi se kalri ne'i
##       `build/chromium/`

{.experimental: "strictFuncs".}

import std/[base64, json, os, osproc, sequtils, strutils, tables, unicode]

import ../src/browser/[draw, lessons, samples_layers]
import ../src/ricysoho/[layers, live, nif, prose]
import ../tests/sample_tatoeba/sentences
import ./[drive, lists, meanings, page]


const
  PATH_BRIDGE* = "src" / "javascript" / "bridge.nim"
    ## le datnyvei poi jarco le genturfa'i `JavaScript`
  PATH_SCRIPT* = "build" / "ricysoho.js"
    ## le samtci poi lo minde po'u `javascript` zbasu ke'a le cripu
  ROOT_SERVED = "build"
    ## lo vasru poi le sabji samtci cu sabji ke'a
    ##   .i ro datnyvei ne'i le vasru cu se sabji sepi'o lo judri be vo'a
  DIRECTORY_DRIVE = ROOT_SERVED / "drive"  ## lo vasru be ro samtci .e ro selci'a pe lo cipra
  DIRECTORY_LIVE = DIRECTORY_DRIVE / "live"
    ## lo vasru be lo selci'a pe le cipra pe lo mivyselci'a ge'u ge'u .e le selci'a be fi `NIF` be'o
    ##     pe ro le selci'a
  DIRECTORY_LAYERS = DIRECTORY_DRIVE / "layers"
    ## lo vasru be lo se cipra pe le cipra pe le papri pe lo linji
  TEXTS_LAYERS = [
    "mi klama le",  # le gerna cu sisti bu'u le fanmo
    "mi klama le zarci .i do kla",  # pa valsi cu srera
    "mi klama le .i do cadzu",  # pa jufra cu lidne pa srera
    "mi klama\nle zarci",  # pa linji fanmo
    "coi \u{1F600} mi klama",  # pa lerfu poi zmadu `U+FFFF`
    "mi pu klama 10\u20AC",  # lo valsi poi pa jdini sinxa cu sinxa ke'a gi'e vasru no stuzi
    "mi BAcru .i la .alis. cu ba'o kla,ma",  # lo barda lerfu .e slaka bu
    "la .constructor. cu zdani",  # pa cmene poi du lo cmene be lo ckaji be ro dacti pe `JavaScript`
    "",
  ]
    ## lo selci'a poi le cipra pe le papri pe lo linji cu cipra ke'a ku'o jmina lo mupli pe le papri
  DIRECTORY_CASES = DIRECTORY_DRIVE / "page"  ## lo vasru be lo se cipra pe le cipra pe le papri
  MODE_REFUSED = "refused"
    ## lo tadji be lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka
  POLICY_REFUSED = ("Content-Security-Policy", "worker-src 'none'")
    ## lo sedli'i pe lo papri pe `MODE_REFUSED`
    ##   .i le sedli'i cu to'e curmi ro gunka ta'i lo nu lo javni pe lo papri cu ka'e to'e curmi ro
    ##       gunka
  SUITES = [("suite_script", ""), ("suite_live", ""), ("suite_live", MODE_REFUSED)]
    ## ro cipra pe `tests/browser/` fasnu ne'i pa papri pe le cipra gi'e ponse lo tadji poi le papri
    ##     cu dunda ke'a
    ##   .i le cipra pe lo mivyselci'a cu fasnu re roi gi'e pa roi fasnu ne'i lo papri poi to'e
    ##       curmi lo gunka
  PATH_COLLECTOR = "tools" / "drive" / "collector.nim"  ## le crepu be lo pixra pe le papri
  DIRECTORY_FONT_FACES = ROOT_SERVED / "font-faces"
    ## lo vasru poi `koch drive` tcidu ke'a
    ##   .i le vasru cu mintu `DIRECTORY_FONT_FACES` pe `font_stacks.nim` pe `curator`
  PATH_CONTROL = DIRECTORY_FONT_FACES / "control.html"
    ## le tropapri poi `koch drive` ciska ke'a pu lo nu `drive` fasnu
    ##   .i le tropapri cu na zasti bu'u lo bartu be `koch drive`
  PATH_WRITTEN = DIRECTORY_FONT_FACES / "written.json"
    ## lo se tcidu be le crepu be'o poi `koch drive` pilno ke'a
  PAGE_CONTROL = "control"  ## lo cmene poi `written.json` dunda ke'a le tropapri
  PAGE_LIVE = "live"  ## lo cmene poi `written.json` dunda ke'a le papri pe lo mivyselci'a
  PAGE_LAYERS = "layers"  ## lo cmene poi `written.json` dunda ke'a le papri pe lo linji
  DIRECTORY_FILES = "files"
    ## lo vasru poi zvati lo mlana be `written.json` gi'e vasru ro lertai poi le papri cu cusku ke'a
    ##   .i lo datnyvei pe ro lertai cu selcme lo snina'u pe lo stuzi pe le lertai
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"
    ## le jitro samtci pe `delegations` ge'u zi'e poi le vi samtci cu cpedu `Chromium` ke'a
  FILE_CHROMIUM = "chrome-headless-shell-linux64-153.0.8010.12.zip"
    ## `headless shell` pe `Chrome for Testing 153.0.8010.12` ta'i le cmene poi lo sorcu pe
    ##     `delegations` dunda ke'a
    ##   .i le cmene cu vasru lo farvi namcu to `ARCHIVES` pe `curator/audit/src/assets.nim` toi
  DIRECTORY_CHROMIUM = ROOT_SERVED / "chromium"
    ## lo vasru poi `Chromium` pe le sorcu cu se kalri ne'i ke'a
  PATH_CHROMIUM_UNPACKED = DIRECTORY_CHROMIUM / "chrome-headless-shell-linux64" /
    "chrome-headless-shell"
    ## le samtci pe `Chromium` ge'u zi'e noi zvati le vreji poi se kalri
  SENTENCES_LIVE = 12
    ## lo du'u xo kau jufra pe `Tatoeba` seljo'e fi pa selci'a pe le cipra pe lo mivyselci'a
    ##   .i le samtci cu tcidu ro valsi ta'i pa pagbu gi'e nitcu lo temci poi pilji li ji'i 37 le
    ##       temci pe le jbezba ku'o gi'e tcidu le selci'a re roi
  TEXTS_LIVE = [
    # zo si vimcu zo cadzu .e zo do .e zo .i
    "mi klama .i do cadzu si si si ko",  # `CLL 19.13`
    # zo li'u rinka lo nu lo jufra poi se lidne zo lu rapseltcidu
    "lu mi klama .i do cadzu li'u .i ko",  # `CLL 19.9`
    "zoi gy. café \u{1F600} .gy. cu melbi .i mi klama .i do cadzu si si si ko",
      # le selci'a be fi `NIF` cu vasru pa lerfu poi zmadu `U+FFFF` ku'o pu pa nu katna
      #   .i zo zoi sitna le lerfu to `CLL 19.10` toi
      #   .i `\u{1F600}` basti le lerfu ki'u lo nu no lertai poi le vi selgu'a cu benji ke'a pixra
      #       le lerfu to `Article X.8` toi
    "mi su do .i ko",  # zo su fanmo le selci'a poi lidne zo su to lo seljdi bu'u `#859` toi
    "lo'u mi su do le'u .i ko",  # ca lo nu zo le'u klama kei zo su se sitna to `CLL 19.9` toi
  ]
    ## lo selfinselci'a pe le cipra pe lo mivyselci'a
    ##   .i ro le selci'a cu vasru pa valsi poi galfi lo pu valsi
  SKELETON_PAGE = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>",
    "</title></head><body data-mode=\"", "\">", "</body></html>",
  )
    ## le selci'a be fi `HTML` be'o poi ro cipra cu fasnu ne'i ke'a
    ##   .i le krasi cu lidne le cmene noi lidne le tadji noi lidne le samtci noi lidne le fanmo
  SKELETON_HOSTED = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" " &
      "content=\"width=device-width, initial-scale=1\"></head><body data-mode=\"",
    "\">", "</body></html>",
  )
    ## le selci'a be fi `HTML` be'o poi lo sabji be le papri cu punji le papri ne'i ke'a ki'u lo nu
    ##     le papri poi se gubgau cu claxu lo ralselci'a pe vo'a
    ##   .i le krasi cu lidne le tadji noi lidne le papri noi lidne le fanmo
  STREAMED = [
    "mi klama le zarci .i do cadzu si si si ko .i lu mi klama li'u cu xamgu",
      # zo si vimcu lo valsi pe le pamoi jufra to `CLL 19.13` toi
      #   .i zo li'u fanmo le nu sitna to `CLL 19.9` toi
    # zo zoi sitna
    #   .i zo su to lo seljdi bu'u `#859` toi
    "zoi gy. café .gy. melbi .i mi su do .i ko",  # `CLL 19.10`
  ]
    ## lo selci'a poi le cipra pe le papri cu benji ke'a ta'i lo porsi be lo valsi gi'e ba sisti le
    ##     tcidu
  TYPED = "mi klama le zarci .i do cadzu .i ko"
    ## lo selci'a poi le cipra pe le papri cu ciska ke'a ta'i lo nu ro valsi cu sepli kei gi'e na
    ##     sisti le tcidu
    ##   .i le selci'a cu selfi'i
  EDITED = ["mi klama le zarci", "mi klama"]
    ## lo selci'a poi le cipra pe le papri cu ciska ke'a ta'i le porsi
    ##   .i le remoi se ciska cu ralte no pu selci'a
    ##   .i se ki'u bo le remoi se ciska cu rinka lo nu pa ninytcidu cu cfari



proc writeTextsLive() =
  ## ciska ro selci'a pe le cipra pe lo mivyselci'a ge'u ge'u .e le selci'a be fi `NIF` be'o poi le
  ##     jbezba cu dunda ke'a le selci'a
  ##   .i ro le selci'a cu zvati pa drata datnyvei poi vasru pa lerpoi po'o
  removeDir(DIRECTORY_LIVE)
  createDir(DIRECTORY_LIVE)
  var sentences: seq[string]
  # va'o lo nu pilno lo katna kei ro jufra cu selfu'i
  for k in 0 ..< SENTENCES_LIVE: sentences.add SENTENCES_TATOEBA[k].text
  let texts = @TEXTS_LIVE & @[sentences.join(" .i ")]
  for k in 0 ..< texts.len:
    writeFile(DIRECTORY_LIVE / $k & ".text", texts[k])
    writeFile(DIRECTORY_LIVE / $k & ".nif", readTextParts(texts[k]).reading.toNifParts)
  writeFile(DIRECTORY_LIVE / "count.text", $texts.len)


func toPieces(text: string): seq[string] =
  ## katna le selci'a lo valsi
  ##   .i lo calyle'u cu lidne ro valsi
  ##   .i le papri cu katna ta'i di'u ca lo nu benji lo porsi be lo valsi
  var at = 0
  while at < text.len:
    var stop = at
    while stop < text.len and text[stop] in Whitespace: inc stop
    while stop < text.len and text[stop] notin Whitespace: inc stop
    result.add text[at ..< stop]
    at = stop


proc writeCase(k: int, kind: string, pieces: seq[string], nif, tail: string) =
  ## ciska pa se cipra pe le cipra pe le papri
  ##   .i ciska le klesi .e ro pagbu
  ##   .i ciska le pixra .e le linji vu'o poi le jbezba cu dunda ke'a le ca selci'a be fi `NIF` be'o
  ##       .e le rebla
  ##   .i ba bo ciska le pixra .e le linji vu'o pe le tricu poi le ca selci'a cu se jmina fo ke'a
  let
    path = DIRECTORY_CASES / $k
    drawing = drawn(nif, tail)
    merged = nif.drawnMerged
  writeFile(path & ".kind", kind)
  for j in 0 ..< pieces.len: writeFile(path & "." & $j & ".piece", pieces[j])
  writeFile(path & ".count.text", $pieces.len)
  writeFile(path & ".html", drawing.html)
  writeFile(path & ".status", drawing.status)
  writeFile(path & ".merged.html", merged.html)
  writeFile(path & ".merged.status", merged.status)


func described(text: string): string =
  ## ciska ro valsi .e ro linji pe le se tcidu pe `text` ta'i lo linji
  ##   .i le stuzi pe ro valsi cu se kancu ta'i lo pagbu pe `UTF-16` to `suite_layers.nim` toi
  let reading = text.readTextMarked
  var
    units = newSeq[int](text.len + 1)
    (at, count) = (0, 0)
  while at < text.len:
    let size = text.runeLenAt(at)
    for k in 0 ..< size: units[at + k] = count
    count += (if int32(text.runeAt(at)) > 0xFFFF: 2 else: 1)
    at += size
  units[text.len] = count
  for occurrence in reading.occurrences:
    result.add "w " & $units[min(occurrence.start, text.len)] & " " &
        $units[min(occurrence.finish, text.len)] & " " & $ord(occurrence.reading.toGroup) & " " &
        occurrence.reading.toGloss & "\n"
  for bar in reading.toLayers.bars:
    result.add "b " & $ord(bar.category) & " " & $bar.first & " " & $bar.last & " " &
        $bar.parent & " " & $bar.height & "\n"


func meant(text: string, found: OrderedTable[string, Meaning]): string =
  ## ciska le smuni be ro valsi pe le se tcidu pe `text` ta'i pa linji
  ##   .i lo kunti linji cu sinxa lo valsi poi le liste cu vasru no smuni be ke'a
  ##   .i le valsi cu du le lerfu poi le genturfa'i cu tcidu ke'a to `Occurrence.text` toi
  for occurrence in text.readTextMarked.occurrences:
    if occurrence.text in found:
      result.add found[occurrence.text].gloss & " · " & found[occurrence.text].definition
    result.add "\n"


func kinded(text: string, found: OrderedTable[string, Meaning]): string =
  ## ciska le glico cmene .e le glico selci'a be ro linji pe le se tcidu pe `text` ta'i pa linji
  ##   .i lo tabmlu cu sepli le re datnypau
  ##   .i le selci'a cu du lo smuni pe le liste va'o lo nu le liste cu vasru ke'a to `D1 c` toi
  let
    reading = text.readTextMarked
    glosses = reading.occurrences.mapIt(it.reading.toGloss)
  for bar in reading.toLayers.bars:
    let lesson = LESSON_KIND[bar.category]
    var (english, shown) = (lesson.english, lesson.text)
    case lesson.basis
    of Basis.Name:
      if lesson.lojban in found:
        (english, shown) = (found[lesson.lojban].gloss, found[lesson.lojban].definition)
    of Basis.Marker:
      let word = reading.occurrences[glosses.marking(bar.category, bar.first, bar.last)].text
      shown = if word in found: shownMarker(word, found[word].gloss, found[word].definition)
          else: LESSON_NONE
    of Basis.Own: discard
    result.add english & "\t" & shown & "\n"


proc writeCasesLayers() =
  ## ciska ro se cipra pe le cipra pe le papri pe lo linji
  ##   .i ciska le selci'a .e ro valsi .e ro linji poi le jbezba cu gunma ke'a
  ##   .i ciska ji'a le smuni be ro valsi .e le ctuca be ro linji ja'i le liste
  removeDir(DIRECTORY_LAYERS)
  createDir(DIRECTORY_LAYERS)
  let found = toMeanings(readSource("gismu.txt").text, readSource("cmavo.txt").text,
      readSource("lujvo.txt").text)
  var k = 0
  for text in SAMPLES.mapIt(it[1]) & @TEXTS_LAYERS:
    writeFile(DIRECTORY_LAYERS / $k & ".text", text)
    writeFile(DIRECTORY_LAYERS / $k & ".layers", text.described)
    writeFile(DIRECTORY_LAYERS / $k & ".meanings", text.meant(found))
    writeFile(DIRECTORY_LAYERS / $k & ".kinds", text.kinded(found))
    inc k
  writeFile(DIRECTORY_LAYERS / "count.text", $k)


proc writeCasesPage() =
  ## ciska ro se cipra pe le cipra pe le papri
  ##   .i ro mupli cu mulseltcidu
  ##   .i ro selci'a cu selbe'i ta'i lo porsi be lo valsi
  ##   .i pa selci'a cu selci'a
  ##   .i pa nu galfi
  ##   .i ro se cipra cu se kansa le pixra poi le jbezba cu dunda ke'a
  removeDir(DIRECTORY_CASES)
  createDir(DIRECTORY_CASES)
  var k = 0
  for sample in readFile(PATH_SHELL).samples:
    writeCase(k, "whole", @[sample], readTextParts(sample).reading.toNifParts, "")
    inc k
  for text in STREAMED:
    writeCase(k, "stream", @[text], readTextParts(text).reading.toNifParts, "")
    inc k
  block:
    var
      reader = initReaderLive()
      change: ChangeNif
    let pieces = TYPED.toPieces
    for piece in pieces: change = reader.push(piece)
    writeCase(k, "typed", pieces, reader.toNif, change.tail)
    inc k
  block:
    var reader = initReaderLive()
    let change = reader.push(EDITED[^1])
    writeCase(k, "edit", @EDITED, reader.toNif, change.tail)
    inc k
  writeFile(DIRECTORY_CASES / "count.text", $k)


proc findChromium(): string =
  ## dunda le samtci pe `Chromium`
  ##   .i le samtci cu du lo selcme be `VARIABLE_CHROMIUM`
  ##   .i va'o lo drata le samtci cu du lo se sabji be le sorcu be'o poi se kalri
  ##   .i lo kunti lerpoi va'o lo nu le re krasi cu dunda no samtci
  let named = getEnv(VARIABLE_CHROMIUM)
  if named.len > 0:
    if named.fileExists: return named
    stderr.writeLine "Chromium `" & VARIABLE_CHROMIUM & "` names should exist; got `" & named & "`."
    return ""
  let (output, code) = execCmdEx(
    "nim r --hints:off --warnings:off " & quoteShell(PATH_KOCH) & " fetch-assets " & FILE_CHROMIUM)
  if code != 0:
    stderr.writeLine "Chromium should come from `" & VARIABLE_CHROMIUM & "`, or from store of " &
      "repository, which `koch fetch-assets` serves as `" & FILE_CHROMIUM & "`; got exit `" &
      $code & "`: " & output.strip
    return ""
  removeDir(DIRECTORY_CHROMIUM)
  createDir(DIRECTORY_CHROMIUM)
  let
    archive = output.strip.splitLines[^1]  # lo judri poi le sorcu cu sabji le vreji bu'u ke'a
    (unpacked, code_unzip) = execCmdEx(
      "unzip -q " & quoteShell(archive) & " -d " & quoteShell(DIRECTORY_CHROMIUM))
  if code_unzip != 0:
    stderr.writeLine "Archive of Chromium should unpack; got exit `" & $code_unzip & "`: " &
      unpacked
    return ""
  PATH_CHROMIUM_UNPACKED


proc runSuite(chromium, name, mode: string): int =
  ## pilno pa cipra ne'i pa papri pe le cipra
  ##   .i le papri cu dunda pa tadji le cipra sepi'o pa ckaji pe `body`
  ##   .i ciska ro linji poi le cipra cu cusku ke'a
  ##   .i dunda li 1 va'o lo nu le cipra cu fliba
  let
    script = "<script src=\"/drive/" & name & ".js\"></script>"
    headers = (if mode == MODE_REFUSED: @[POLICY_REFUSED] else: @[])
    run = chromium.runPage(SKELETON_PAGE[0] & name & SKELETON_PAGE[1] & mode &
      SKELETON_PAGE[2] & script & SKELETON_PAGE[3], ROOT_SERVED, headers)
  for line in run.lines: echo line
  if run.code != 0:
    stderr.writeLine "Suite `" & name & "` should pass in Chromium; got code `" & $run.code & "`."
    return 1


proc runSuitePage(chromium, page, mode: string): int =
  ## pilno le cipra pe le papri ne'i pa papri poi selzba sepi'o le cipra
  ##   .i le papri cu dunda pa tadji le cipra sepi'o pa ckaji pe `body`
  ##   .i ciska ro linji poi le cipra cu cusku ke'a
  ##   .i dunda li 1 va'o lo nu le cipra cu fliba
  let
    headers = (if mode == MODE_REFUSED: @[POLICY_REFUSED] else: @[])
    hosted = SKELETON_HOSTED[0] & mode & SKELETON_HOSTED[1] & page & SKELETON_HOSTED[2]
    run = chromium.runPage(hosted, ROOT_SERVED, headers)
  for line in run.lines: echo line
  if run.code != 0:
    stderr.writeLine "Suite of page should pass in Chromium; got code `" & $run.code & "`."
    return 1


proc toFile(source: string): string =
  ## ciska lo stuzi pe `source` fi pa datnyvei poi selcme lo snina'u pe le stuzi
  ##   .i le datnyvei cu zvati lo mlana be `written.json`
  ##   .i `source` krasi be pa lertai gi'e selkra `data:`
  ##   .i dunda lo judri be le datnyvei be'o poi selkra `written.json`
  ##   .i lo kunti lerpoi va'o lo nu `source` na krasi be pa lertai poi selpu'i ne'i le papri
  let
    opening = source.find("data:font/")
    marker = source.find(";base64,", opening)
  if opening < 0 or marker < 0: return ""
  let
    subtype = source[opening + "data:font/".len ..< marker]
    payload = source[marker + ";base64,".len ..< source.find({'"', '\'', ')'}, marker)]
    bytes = payload.decode
    file = DIRECTORY_FILES / bytes.digestText & "." & subtype
  writeFile(DIRECTORY_FONT_FACES / file, bytes)
  file


proc collected(chromium, page: string): JsonNode =
  ## tcidu le papri sepi'o le crepu gi'e dunda lo selbe'i be le crepu
  ##   .i `nil` va'o lo nu le nu cipra cu fliba
  let
    script = "<script src=\"/drive/collector.js\"></script>"
    run = chromium.runPage(page.replace("</body>", script & "</body>"), ROOT_SERVED)
  if run.code != 0 or "/collected" notin run.posted: return nil
  run.posted["/collected"].parseJson


proc collectPages(chromium: string, faces: Table[string, string]): int =
  ## tcidu le papri pe lo mivyselci'a sepi'o le crepu
  ##   .i va'o lo nu `koch drive` cu ba'o ciska pa tropapri kei tcidu ji'a le tropapri
  ##   .i ciska lo se tcidu be le crepu fi `written.json`
  ##   .i ro lertai poi le papri cu cusku ke'a selci'a fi pa datnyvei pe vo'a
  ##   .i dunda li 1 va'o lo nu le crepu cu fliba .a lo nu le tropapri cu cusku pa lertai
  removeDir(DIRECTORY_FONT_FACES / DIRECTORY_FILES)
  createDir(DIRECTORY_FONT_FACES / DIRECTORY_FILES)
  var written = newJObject()
  let live = chromium.collected(SKELETON_HOSTED[0] & SKELETON_HOSTED[1] & builtPage("", faces) &
      SKELETON_HOSTED[2])
  if live.isNil:
    stderr.writeLine "Collector should post what page of live text draws."
    return 1
  var declared = newJArray()
  for rule in live["rules"]:
    let file = rule["source"].getStr.toFile
    if file.len == 0:
      stderr.writeLine "Font face of page should be inlined as `data:` source of font; got `" &
          rule["source"].getStr[0 ..< min(60, rule["source"].getStr.len)] & "`."
      return 1
    declared.add %*{"family": rule["family"], "weight": rule["weight"], "range": rule["range"],
        "file": file}
  written[PAGE_LIVE] = %*{"runs": live["runs"], "declared": declared, "refused": live["refused"]}
  let layers = chromium.collected(SKELETON_HOSTED[0] & SKELETON_HOSTED[1] &
      builtLayers(compiledLayers(), faces) & SKELETON_HOSTED[2])
  if layers.isNil:
    stderr.writeLine "Collector should post what page of text layers draws."
    return 1
  var declared_layers = newJArray()
  for rule in layers["rules"]:
    let file = rule["source"].getStr.toFile
    if file.len == 0:
      stderr.writeLine "Font face of page should be inlined as `data:` source of font."
      return 1
    declared_layers.add %*{"family": rule["family"], "weight": rule["weight"],
        "range": rule["range"], "file": file}
  written[PAGE_LAYERS] = %*{"runs": layers["runs"], "declared": declared_layers,
      "refused": layers["refused"]}
  if PATH_CONTROL.fileExists:
    let control = chromium.collected(PATH_CONTROL.readFile)
    if control.isNil:
      stderr.writeLine "Collector should post what control page draws."
      return 1
    if control["rules"].len > 0:
      stderr.writeLine "Control page should declare no font face; got " & $control["rules"].len &
          "."
      return 1
    written[PAGE_CONTROL] = %*{"runs": control["runs"], "declared": newJArray(),
        "refused": control["refused"]}
  else: echo "No control page: `koch drive` writes it, so `written.json` holds page alone."
  writeFile(PATH_WRITTEN, written.pretty & "\n")
  echo PATH_WRITTEN


proc runDrive*(): int =
  ## zbasu le samtci .e le papri .e lo cipra .e le crepu
  ##   .i ciska lo selci'a .e lo se cipra pe lo cipra
  ##   .i ba bo pilno ro cipra .e le crepu ne'i `Chromium`
  ##   .i dunda li 1 va'o lo nu su'o nu zbasu .a su'o cipra .a le crepu cu fliba
  if compileJs(PATH_BRIDGE, PATH_SCRIPT) != 0: return 1
  let faces = fontFaces()
  writeFile(PATH_PAGE, builtPage(compiledPage(), faces))
  for name in ["suite_script", "suite_live", "suite_page", "suite_layers"]:
    if compileJs("tests" / "browser" / name & ".nim", DIRECTORY_DRIVE / name & ".js",
        ["testing"]) != 0:
      return 1
  if compileJs(PATH_COLLECTOR, DIRECTORY_DRIVE / "collector.js") != 0: return 1
  writeTextsLive()
  writeCasesPage()
  writeCasesLayers()
  let chromium = findChromium()
  if chromium.len == 0: return 1
  for (name, mode) in SUITES: result = max(result, chromium.runSuite(name, mode))
  let suite_page = builtPage(readFile(DIRECTORY_DRIVE / "suite_page.js"), faces)
  for mode in ["", MODE_REFUSED]: result = max(result, chromium.runSuitePage(suite_page, mode))
  let suite_layers = builtLayers(readFile(DIRECTORY_DRIVE / "suite_layers.js"), faces)
  for mode in ["", MODE_REFUSED]: result = max(result, chromium.runSuitePage(suite_layers, mode))
  result = max(result, chromium.collectPages(faces))
