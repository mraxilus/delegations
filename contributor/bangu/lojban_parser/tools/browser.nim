## pilno ro cipra pe le vi se gunka poi fasnu ne'i lo tcidu be lo papri ku'o ta'i lo minde po'u
##   `drive`
##   .i zbasu le samtci .e le papri
##   .i fanva ro cipra pe `tests/browser/` .e le crepu fi la'o gy. JavaScript .gy.
##   .i ciska lo se ciska .e lo se cipra poi lo cipra cu tcidu ke'a
##   .i ro le se ciska .e ro le se cipra cu se kansa lo se dunda be le jbena zbasu
##   .i pilno ro cipra ne'i la'o gy. headless Chromium .gy. to `drive.nim` toi
##   .i tcidu le papri pe lo jmive se ciska .e le jitro papri poi `koch drive` cu ciska ke'a ku'o
##     sepi'o le crepu
##   .i le se tcidu cu se ciska fi `written.json`
##
##   |------------|-------------------------------------------------------------------------------|
##   | lo fancu   | lo smuni                                                                      |
##   |------------|-------------------------------------------------------------------------------|
##   | `runDrive` | zbasu je pilno ro cipra .e le crepu ne'i `Chromium`                           |
##   |            | .i li pa va'o lo nu fliba                                                     |
##   |------------|-------------------------------------------------------------------------------|
##
## ni'o le cipra pe lo jmive se ciska .e le cipra pe le papri cu rapli fasnu ne'i pa papri poi lo
##   javni pe lo se vasru be ke'a cu to'e curmi ro gunka
##   .i se ki'u bo lo cilta pe le papri cu basti le gunka pe le tcidu ta'i le samtci va'o lo nu le
##     papri cu to'e curmi lo gunka
##   .i ro cipra pe le samtci cu fasnu ne'i pa papri pe vo'a ge'u zi'e noi cpacu le cipra po'o
##     sepi'o lo judri be le cipra
##   .i ro cipra cu vasru le cripu ta'i le samtci poi se benji
##   .i ki'u bo ro samtci poi la'o gy. Nim .gy. cu fanva ke'a cu punji ro fancu pe vo'a lo stuzi poi
##     ro da ka'e pilno ke'a
##   .i pa remoi samtci ne'i pa papri cu basti ro fancu pe le pamoi ge'u zi'e poi ke'a .e pa fancu
##     pe le remoi cu se cmene pa cmene
##   .i le gunka pe le cipra pe lo jmive se ciska cu se krasi le judri ta'i lo nu le gunka pe le
##     samtci cu se krasi le judri be le samtci
##   .i le cipra pe le papri cu fasnu ne'i pa papri poi se zbasu fi le calku
##   .i le cipra cu zvati le se ciska pe le papri gi'e basti le samtci pe le papri
##   .i le cipra cu vasru ro pagbu be le samtci
##   .i le gunka cu se krasi pa `Blob` pe le se ciska pe le cipra ta'i le gunka pe le papri
##   .i lo se finti se ciska pe le cipra pe lo jmive se ciska cu vasru pa valsi poi galfi lo pu
##     valsi
##   .i pa drata se ciska cu jorne lo jufra pe la'o gy. Tatoeba .gy.
##   .i le jbena zbasu cu dunda le se ciska be fi la'o gy. NIF .gy. be'o pe ro se ciska ta'i lo nu
##     `readTextParts` cu dunda lo pagbu be lo se ciska poi mulno se tcidu
##   .i le flalu pe `test_live.nim` cu cipra lo du'u lo jmive se ciska cu mintu le pagbu
##   .i lo se cipra pe le cipra pe le papri cu du ro mupli pe le calku ge'u zi'e poi mulno se tcidu
##     ku'o .e lo se ciska poi se benji ta'i lo porsi be lo valsi ku'o .e pa se ciska poi se ciska
##     ta'i lo nu ro pagbu cu sepli kei gi'e ca'o kalri ku'o .e pa nu galfi poi rinka lo nu pa cnino
##     tcidu cu cfari
##   .i le jbena zbasu cu ciska le pixra be ro se cipra sepi'o `drawn`
##   .i `drawn` cu pilno le se ciska be fi la'o gy. NIF .gy. be'o poi le jbena tcidu be lo jmive se
##     ciska cu dunda ke'a ca lo nu cpacu le mintu pagbu
##   .i va'o lo nu le tcidu cu sisti kei le se ciska cu mintu le se ciska be fi la'o gy. NIF .gy.
##     be'o pe lo nu tcidu le mulno se ciska to `live.nim`
##   .i lo flalu toi
##   .i lo nu jmina ro se cipra cu pilno `drawnMerged` le ca se ciska be fi la'o gy. NIF .gy. be'o
##     pe le se cipra
##   .i le rebla cu na se jmina ta'i lo nu le papri cu jmina
##   .i ro se ciska .e ro se cipra .e ro pagbu .e ro pixra cu datnyvei gi'e vasru pa lerpoi
##   .i se ki'u bo no tarmi be lo datni cu zvati lo jbini be le sabji samtci .e le papri
##   .i le crepu cu tcidu le papri pe lo jmive se ciska poi vasru no samtci
##   .i le papri cu mulno se tcidu va'o lo nu no samtci cu zasti
##   .i ki'u bo lo nu zbasu cu punji lo jbena pixra be le pamoi mupli le papri
##   .i ro lerfu tarmi poi le papri cu cusku ke'a cu se krasi pa `data:`
##   .i le crepu cu ciska lo stuzi pe ro lerfu tarmi fi pa datnyvei pe le lerfu tarmi
##   .i lo sinxa namcu cu cmene le datnyvei
##   .i le datnyvei cu zvati lo mlana be `written.json`
##   .i se ki'u bo `koch drive` cu tcidu lo stuzi poi lo viska cu cpacu ke'a to `font_stacks.nim` pe
##     la'o gy. curator .gy. toi
##   .i le jitro papri cu cusku no lerfu tarmi
##   .i la'o gy. Chromium .gy. poi se pilno cu du lo se cmene be `LOJBAN_CHROMIUM`
##   .i va'o lo drata la'o gy. Chromium .gy. poi se pilno cu du `headless shell` pe la'o gy. Chrome
##     for Testing .gy. ge'u zi'e noi `koch fetch-assets` cu cpacu ke'a lo sorcu pe la'o gy.
##     delegations .gy. zi'e noi se kalri ne'i `build/chromium/`

{.experimental: "strictFuncs".}

import std/[base64, json, os, osproc, strutils, tables]

import ../src/browser/draw
import ../src/lojban_parser/[live, nif, prose]
import ../tests/sample_tatoeba/sentences
import ./[drive, page]


const
  PATH_BRIDGE* = "src" / "javascript" / "bridge.nim"
    ## le datnyvei poi jarco le genturfa'i la'o gy. JavaScript .gy.
  PATH_SCRIPT* = "build" / "lojban_parser.js"
    ## le samtci poi lo minde po'u `javascript` cu zbasu ke'a le cripu
  ROOT_SERVED = "build"
    ## lo vasru poi le sabji samtci cu sabji ke'a
    ##   .i ro datnyvei ne'i le vasru cu se sabji sepi'o lo judri be vo'a
  DIRECTORY_DRIVE = ROOT_SERVED / "drive"  ## lo vasru be ro samtci .e ro se ciska pe lo cipra
  DIRECTORY_LIVE = DIRECTORY_DRIVE / "live"
    ## lo vasru be lo se ciska pe le cipra pe lo jmive se ciska .e le se ciska be fi la'o gy. NIF
    ##   .gy. be'o pe ro le se ciska
  DIRECTORY_CASES = DIRECTORY_DRIVE / "page"  ## lo vasru be lo se cipra pe le cipra pe le papri
  MODE_REFUSED = "refused"
    ## lo tadji be lo papri poi lo javni pe lo se vasru be ke'a cu to'e curmi ro gunka
  POLICY_REFUSED = ("Content-Security-Policy", "worker-src 'none'")
    ## lo stedu linji pe lo papri pe `MODE_REFUSED`
    ##   .i le stedu linji cu to'e curmi ro gunka ta'i lo nu lo javni pe lo papri cu ka'e to'e curmi
    ##     ro gunka
  SUITES = [("suite_script", ""), ("suite_live", ""), ("suite_live", MODE_REFUSED)]
    ## ro cipra pe `tests/browser/` cu fasnu ne'i pa papri pe le cipra gi'e ponse lo tadji poi le
    ##   papri cu dunda ke'a
    ##   .i le cipra pe lo jmive se ciska cu fasnu re roi
    ##   .i pa roi le cipra cu fasnu ne'i lo papri poi to'e curmi lo gunka
  PATH_COLLECTOR = "tools" / "drive" / "collector.nim"  ## le crepu be lo pixra pe le papri
  DIRECTORY_FONT_FACES = ROOT_SERVED / "font-faces"
    ## lo vasru poi `koch drive` cu tcidu ke'a
    ##   .i le vasru cu mintu `DIRECTORY_FONT_FACES` pe `font_stacks.nim` pe la'o gy. curator .gy.
  PATH_CONTROL = DIRECTORY_FONT_FACES / "control.html"
    ## le jitro papri poi `koch drive` cu ciska ke'a pu lo nu `drive` cu fasnu
    ##   .i le jitro papri cu na zasti bu'u lo bartu be `koch drive`
  PATH_WRITTEN = DIRECTORY_FONT_FACES / "written.json"
    ## lo se tcidu be le crepu be'o poi `koch drive` cu pilno ke'a
  PAGE_CONTROL = "control"  ## lo cmene poi `written.json` cu dunda ke'a le jitro papri
  PAGE_LIVE = "live"  ## lo cmene poi `written.json` cu dunda ke'a le papri pe lo jmive se ciska
  DIRECTORY_FILES = "files"
    ## lo vasru poi zvati lo mlana be `written.json` gi'e vasru ro lerfu tarmi poi le papri cu cusku
    ##   ke'a
    ##   .i lo datnyvei pe ro lerfu tarmi cu se cmene lo sinxa namcu pe lo stuzi pe le lerfu tarmi
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"
    ## le jitro samtci pe la'o gy. delegations .gy. ge'u zi'e poi le vi samtci cu cpedu la'o gy.
    ##   Chromium .gy. ke'a
  FILE_CHROMIUM = "chrome-headless-shell-linux64-153.0.8010.12.zip"
    ## `headless shell` pe la'o gy. Chrome for Testing 153.0.8010.12 .gy. ta'i le cmene poi lo sorcu
    ##   pe la'o gy. delegations .gy. cu dunda ke'a
    ##   .i le cmene cu vasru lo farvi namcu to `ARCHIVES` pe `curator/audit/src/assets.nim` toi
  DIRECTORY_CHROMIUM = ROOT_SERVED / "chromium"
    ## lo vasru poi la'o gy. Chromium .gy. pe le sorcu cu se kalri ne'i ke'a
  PATH_CHROMIUM_UNPACKED = DIRECTORY_CHROMIUM / "chrome-headless-shell-linux64" /
    "chrome-headless-shell"
    ## le samtci pe la'o gy. Chromium .gy. ge'u zi'e noi zvati le vreji poi se kalri
  SENTENCES_LIVE = 12
    ## lo du'u xo kau jufra pe la'o gy. Tatoeba .gy. cu se jorne fi pa se ciska pe le cipra pe lo
    ##   jmive se ciska
    ##   .i le samtci cu tcidu ro valsi ta'i pa pagbu
    ##   .i le samtci cu nitcu lo temci poi pilji li ji'i cize le temci pe le jbena zbasu
    ##   .i le samtci cu tcidu le se ciska re roi
  TEXTS_LIVE = [
    # zo si cu vimcu zo cadzu .e zo do .e zo .i
    "mi klama .i do cadzu si si si ko",  # `CLL 19.13`
    # zo li'u cu rinka lo nu lo jufra poi se lidne zo lu cu rapli se tcidu
    "lu mi klama .i do cadzu li'u .i ko",  # `CLL 19.9`
    "zoi gy. café \u{1F600} .gy. cu melbi .i mi klama .i do cadzu si si si ko",
      # le se ciska be fi la'o gy. NIF .gy. cu vasru pa lerfu poi zmadu la'o gy. U+FFFF .gy. pu pa
      #   nu katna
      #   .i zo zoi cu sitna le lerfu to `CLL 19.10` toi
      #   .i `\u{1F600}` cu basti le lerfu ki'u lo nu no lerfu tarmi poi le vi se gunka cu benji
      #     ke'a cu pixra le lerfu to `Article X.8` toi
    "mi su do .i ko",  # zo su cu fanmo le se ciska poi lidne zo su to lo se jdice bu'u `#859` toi
    "lo'u mi su do le'u .i ko",  # ca lo nu zo le'u cu klama kei zo su cu se sitna to `CLL 19.9` toi
  ]
    ## lo se finti se ciska pe le cipra pe lo jmive se ciska
    ##   .i ro le se ciska cu vasru pa valsi poi galfi lo pu valsi
  SKELETON_PAGE = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>",
    "</title></head><body data-mode=\"", "\">", "</body></html>",
  )
    ## le se ciska be fi la'o gy. HTML .gy. be'o poi ro cipra cu fasnu ne'i ke'a
    ##   .i le krasi cu lidne le cmene
    ##   .i le cmene cu lidne le tadji
    ##   .i le tadji cu lidne le samtci
    ##   .i le samtci cu lidne le fanmo
  SKELETON_HOSTED = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" " &
      "content=\"width=device-width, initial-scale=1\"></head><body data-mode=\"",
    "\">", "</body></html>",
  )
    ## le se ciska be fi la'o gy. HTML .gy. be'o poi lo sabji be le papri cu punji le papri ne'i
    ##   ke'a ki'u lo nu le papri poi se gubgau cu claxu lo ralju se ciska pe vo'a
    ##   .i le krasi cu lidne le tadji
    ##   .i le tadji cu lidne le papri
    ##   .i le papri cu lidne le fanmo
  STREAMED = [
    "mi klama le zarci .i do cadzu si si si ko .i lu mi klama li'u cu xamgu",
      # zo si cu vimcu lo valsi pe le pamoi jufra to `CLL 19.13` toi
      #   .i zo li'u cu fanmo le nu sitna to `CLL 19.9` toi
    # zo zoi cu sitna
    #   .i zo su to lo se jdice bu'u `#859` toi
    "zoi gy. café .gy. melbi .i mi su do .i ko",  # `CLL 19.10`
  ]
    ## lo se ciska poi le cipra pe le papri cu benji ke'a ta'i lo porsi be lo valsi gi'e ba sisti le
    ##   tcidu
  TYPED = "mi klama le zarci .i do cadzu .i ko"
    ## lo se ciska poi le cipra pe le papri cu ciska ke'a ta'i lo nu ro valsi cu sepli kei gi'e na
    ##   sisti le tcidu
    ##   .i le se ciska cu se finti
  EDITED = ["mi klama le zarci", "mi klama"]
    ## lo se ciska poi le cipra pe le papri cu ciska ke'a ta'i le porsi
    ##   .i le remoi se ciska cu ralte no pu se ciska
    ##   .i se ki'u bo le remoi se ciska cu rinka lo nu pa cnino tcidu cu cfari



proc writeTextsLive() =
  ## ciska ro se ciska pe le cipra pe lo jmive se ciska .e le se ciska be fi la'o gy. NIF .gy. be'o
  ##   poi le jbena zbasu cu dunda ke'a le se ciska
  ##   .i ro le se ciska cu zvati pa drata datnyvei poi vasru pa lerpoi po'o
  removeDir(DIRECTORY_LIVE)
  createDir(DIRECTORY_LIVE)
  var sentences: seq[string]
  # va'o lo nu pilno lo katna kei ro jufra cu se fukpi
  for k in 0 ..< SENTENCES_LIVE: sentences.add SENTENCES_TATOEBA[k].text
  let texts = @TEXTS_LIVE & @[sentences.join(" .i ")]
  for k in 0 ..< texts.len:
    writeFile(DIRECTORY_LIVE / $k & ".text", texts[k])
    writeFile(DIRECTORY_LIVE / $k & ".nif", readTextParts(texts[k]).reading.toNifParts)
  writeFile(DIRECTORY_LIVE / "count.text", $texts.len)


func toPieces(text: string): seq[string] =
  ## katna le se ciska lo valsi
  ##   .i lo canlu lerfu cu lidne ro valsi
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
  ##   .i ciska le pixra .e le linji vu'o poi le jbena zbasu cu dunda ke'a le ca se ciska be fi la'o
  ##     gy. NIF .gy. .e le rebla
  ##   .i ba bo ciska le pixra .e le linji vu'o pe le tricu poi le ca se ciska cu se jmina fo ke'a
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


proc writeCasesPage() =
  ## ciska ro se cipra pe le cipra pe le papri
  ##   .i ro mupli cu mulno se tcidu
  ##   .i ro se ciska cu se benji ta'i lo porsi be lo valsi
  ##   .i pa se ciska cu se ciska
  ##   .i pa nu galfi
  ##   .i ro se cipra cu se kansa le pixra poi le jbena zbasu cu dunda ke'a
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
  ## dunda le samtci pe la'o gy. Chromium .gy.
  ##   .i le samtci cu du lo se cmene be `VARIABLE_CHROMIUM`
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
  ##   .i dunda li pa va'o lo nu le cipra cu fliba
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
  ## pilno le cipra pe le papri ne'i pa papri poi se zbasu sepi'o le cipra
  ##   .i le papri cu dunda pa tadji le cipra sepi'o pa ckaji pe `body`
  ##   .i ciska ro linji poi le cipra cu cusku ke'a
  ##   .i dunda li pa va'o lo nu le cipra cu fliba
  let
    headers = (if mode == MODE_REFUSED: @[POLICY_REFUSED] else: @[])
    hosted = SKELETON_HOSTED[0] & mode & SKELETON_HOSTED[1] & page & SKELETON_HOSTED[2]
    run = chromium.runPage(hosted, ROOT_SERVED, headers)
  for line in run.lines: echo line
  if run.code != 0:
    stderr.writeLine "Suite of page should pass in Chromium; got code `" & $run.code & "`."
    return 1


proc toFile(source: string): string =
  ## ciska lo stuzi pe `source` fi pa datnyvei poi se cmene lo sinxa namcu pe le stuzi
  ##   .i le datnyvei cu zvati lo mlana be `written.json`
  ##   .i `source` cu krasi be pa lerfu tarmi gi'e se krasi `data:`
  ##   .i dunda lo judri be le datnyvei poi se krasi `written.json`
  ##   .i lo kunti lerpoi va'o lo nu `source` cu na krasi be pa lerfu tarmi poi se punji ne'i le
  ##     papri
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
  ## tcidu le papri sepi'o le crepu gi'e dunda lo se benji be le crepu
  ##   .i `nil` va'o lo nu le nu cipra cu fliba
  let
    script = "<script src=\"/drive/collector.js\"></script>"
    run = chromium.runPage(page.replace("</body>", script & "</body>"), ROOT_SERVED)
  if run.code != 0 or "/collected" notin run.posted: return nil
  run.posted["/collected"].parseJson


proc collectPages(chromium: string, faces: Table[string, string]): int =
  ## tcidu le papri pe lo jmive se ciska sepi'o le crepu
  ##   .i va'o lo nu `koch drive` cu ba'o ciska pa jitro papri kei tcidu ji'a le jitro papri
  ##   .i ciska lo se tcidu be le crepu fi `written.json`
  ##   .i ro lerfu tarmi poi le papri cu cusku ke'a cu se ciska fi pa datnyvei pe vo'a
  ##   .i dunda li pa va'o lo nu le crepu cu fliba .a lo nu le jitro papri cu cusku pa lerfu tarmi
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
  ##   .i ciska lo se ciska .e lo se cipra pe lo cipra
  ##   .i ba bo pilno ro cipra .e le crepu ne'i la'o gy. Chromium .gy.
  ##   .i dunda li pa va'o lo nu su'o nu zbasu .a su'o cipra .a le crepu cu fliba
  if compileJs(PATH_BRIDGE, PATH_SCRIPT) != 0: return 1
  let faces = fontFaces()
  writeFile(PATH_PAGE, builtPage(compiledPage(), faces))
  for name in ["suite_script", "suite_live", "suite_page"]:
    if compileJs("tests" / "browser" / name & ".nim", DIRECTORY_DRIVE / name & ".js",
        ["testing"]) != 0:
      return 1
  if compileJs(PATH_COLLECTOR, DIRECTORY_DRIVE / "collector.js") != 0: return 1
  writeTextsLive()
  writeCasesPage()
  let chromium = findChromium()
  if chromium.len == 0: return 1
  for (name, mode) in SUITES: result = max(result, chromium.runSuite(name, mode))
  let suite_page = builtPage(readFile(DIRECTORY_DRIVE / "suite_page.js"), faces)
  for mode in ["", MODE_REFUSED]: result = max(result, chromium.runSuitePage(suite_page, mode))
  result = max(result, chromium.collectPages(faces))
