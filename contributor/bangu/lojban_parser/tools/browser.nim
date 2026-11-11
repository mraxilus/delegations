## Run each check of this project that runs in browser, as verb `drive`: build script and page,
##   compile each suite of `tests/browser/` and collector to JavaScript, write texts and cases
##   suites read with what native build gives each, run each suite in headless Chromium
##   (`drive.nim`), and read page of live text and control page `koch drive` writes with
##   collector, into `written.json`.
##
##   |-----------|---------------------------------------------------------------------------|
##   | Code      | Meaning                                                                   |
##   |-----------|---------------------------------------------------------------------------|
##   | runDrive  | build, then run each suite and collector in Chromium; exit 1 on failure   |
##   |-----------|---------------------------------------------------------------------------|
##
##   Live suite and suite of page run again on page whose rule of content refuses each worker, so
##     reader gives way to thread of page, as script does where page refuses worker.
##   Each suite of script runs on page of its own, which loads it alone, by its address: each holds
##     bridge, as shipped script does, since each script Nim compiles defines its procs as
##     globals, and second script on page replaces procs of first that share names. Worker of live
##     suite starts from that address, as worker of script starts from address of script.
##   Suite of page runs in page built from shell, inline in place of script of page, which suite
##     holds whole; worker starts from Blob of its text, as worker of page does.
##   Texts of live suite are constructed, each with word that reaches back, and sentences of
##     Tatoeba joined; NIF each gives is native build's, as `readTextParts` gives parts of text
##     read whole, which law of `test_live.nim` holds live text to.
##   Cases of suite of page are each sample of shell, read whole; texts streamed; text typed piece
##     by piece, kept open; and edit that starts new reader. Drawing native build gives each is
##     `drawn` of NIF native live reader gives same pieces, which is NIF of text read whole once
##     reader ends (`live.nim`, law).
##   Each text, case, piece and drawing is file of one string, so no format stands between backend
##     and page.
##   Collector reads page of live text with no script, which page reads complete without, as build
##     draws first sample natively; each font face page declares is bytes of its `data:` source,
##     written into file of its own named by digest, beside `written.json`, so `koch drive` reads
##     bytes viewer gets (`font_stacks.nim` of curator). Control page declares none.
##   Chromium is one `LOJBAN_CHROMIUM` names, else headless shell of Chrome for Testing that
##     `koch fetch-assets` serves from store of repository, unpacked under `build/chromium/`.

{.experimental: "strictFuncs".}

import std/[base64, json, os, osproc, strutils, tables]

import ../src/browser/draw
import ../src/lojban_parser/[live, nif, prose]
import ../tests/sample_tatoeba/sentences
import ./[drive, page]


const
  PATH_BRIDGE* = "src" / "javascript" / "bridge.nim"  ## Module exposing parser to JavaScript.
  PATH_SCRIPT* = "build" / "lojban_parser.js"  ## Script verb `javascript` writes from bridge.
  ROOT_SERVED = "build"  ## Folder backend serves, by path of each file under it.
  DIRECTORY_DRIVE = ROOT_SERVED / "drive"  ## Folder of each script and text of suites.
  DIRECTORY_LIVE = DIRECTORY_DRIVE / "live"  ## Folder of texts of live suite, with NIF of each.
  DIRECTORY_CASES = DIRECTORY_DRIVE / "page"  ## Folder of cases of suite of page.
  MODE_REFUSED = "refused"  ## Mode of page whose rule of content refuses each worker.
  POLICY_REFUSED = ("Content-Security-Policy", "worker-src 'none'")
    ## Header of page of mode `MODE_REFUSED`, which refuses each worker, as rule of page may.
  SUITES = [("suite_script", ""), ("suite_live", ""), ("suite_live", MODE_REFUSED)]
    ## Suite of `tests/browser/`, each on page of its own, with mode page gives it: live suite runs
    ##   twice, once where page refuses worker.
  PATH_COLLECTOR = "tools" / "drive" / "collector.nim"  ## Collector of what page draws.
  DIRECTORY_FONT_FACES = ROOT_SERVED / "font-faces"
    ## Folder `koch drive` reads; twin of `DIRECTORY_FONT_FACES` of `font_stacks.nim` of curator.
  PATH_CONTROL = DIRECTORY_FONT_FACES / "control.html"
    ## Control page `koch drive` writes before `drive`; absent outside it.
  PATH_WRITTEN = DIRECTORY_FONT_FACES / "written.json"  ## What collector read, for `koch drive`.
  PAGE_CONTROL = "control"  ## Name `written.json` gives control page.
  PAGE_LIVE = "live"  ## Name `written.json` gives page of live text.
  DIRECTORY_FILES = "files"
    ## Folder beside `written.json` of each font face page declares, by digest of its bytes.
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"  ## Driver of repository, asked for Chromium.
  FILE_CHROMIUM = "chrome-headless-shell-linux64.zip"
    ## Headless shell of Chrome for Testing 153.0.8010.12, as store of repository names it (#864).
  DIRECTORY_CHROMIUM = ROOT_SERVED / "chromium"  ## Folder Chromium of store unpacks into.
  PATH_CHROMIUM_UNPACKED = DIRECTORY_CHROMIUM / "chrome-headless-shell-linux64" /
    "chrome-headless-shell"
    ## Program of Chromium, as archive unpacks it.
  SENTENCES_LIVE = 12
    ## Sentences of Tatoeba joined into one text of live suite; script reads each word as piece,
    ##   about 37 times as long as native build, twice.
  TEXTS_LIVE = [
    "mi klama .i do cadzu si si si ko",  # `si` erases `cadzu`, `do` and `.i` (19.13)
    "lu mi klama .i do cadzu li'u .i ko",  # `li'u` reads sentences after `lu` again (19.9)
    "zoi gy. café \u{1F600} .gy. cu melbi .i mi klama .i do cadzu si si si ko",
      # NIF holds rune past U+FFFF before cut; `zoi` quotes it (19.10); escape, since no font
      #   face project ships draws it (Article X.8)
    "mi su do .i ko",  # `su` ends text before it (ruling on #859)
    "lo'u mi su do le'u .i ko",  # `le'u` quotes `su` once it comes (19.9)
  ]
    ## Constructed texts of live suite, each with word that reaches back.
  SKELETON_PAGE = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>",
    "</title></head><body data-mode=\"", "\">", "</body></html>",
  )
    ## Document each suite runs in: opening, then title, then mode, then script, then closing.
  SKELETON_HOSTED = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" " &
      "content=\"width=device-width, initial-scale=1\"></head><body data-mode=\"",
    "\">", "</body></html>",
  )
    ## Document host wraps page in, as published page has none of its own: opening, mode, then
    ##   page, then closing.
  STREAMED = [
    "mi klama le zarci .i do cadzu si si si ko .i lu mi klama li'u cu xamgu",
      # `si` erases back into first sentence (19.13); `li'u` closes quotation (19.9)
    "zoi gy. café .gy. melbi .i mi su do .i ko",  # `zoi` quotes (19.10); `su` (ruling on #859)
  ]
    ## Texts suite of page streams word by word, then ends.
  TYPED = "mi klama le zarci .i do cadzu .i ko"
    ## Text suite of page types word by word, and keeps open; constructed.
  EDITED = ["mi klama le zarci", "mi klama"]
    ## Texts suite of page types in turn; second keeps no text before it, so starts new reader.



proc writeTextsLive() =
  ## Write each text of live suite, and NIF native build gives it, each file of one string.
  removeDir(DIRECTORY_LIVE)
  createDir(DIRECTORY_LIVE)
  var sentences: seq[string]
  for k in 0 ..< SENTENCES_LIVE: sentences.add SENTENCES_TATOEBA[k].text  # slice would copy each
  let texts = @TEXTS_LIVE & @[sentences.join(" .i ")]
  for k in 0 ..< texts.len:
    writeFile(DIRECTORY_LIVE / $k & ".text", texts[k])
    writeFile(DIRECTORY_LIVE / $k & ".nif", readTextParts(texts[k]).reading.toNifParts)
  writeFile(DIRECTORY_LIVE / "count.text", $texts.len)


func toPieces(text: string): seq[string] =
  ## Cut text into words, each with whitespace before it, as page streams it.
  var at = 0
  while at < text.len:
    var stop = at
    while stop < text.len and text[stop] in Whitespace: inc stop
    while stop < text.len and text[stop] notin Whitespace: inc stop
    result.add text[at ..< stop]
    at = stop


proc writeCase(k: int, kind: string, pieces: seq[string], drawing: DrawingLive) =
  ## Write one case of suite of page: kind, each piece, and drawing and line native build gives.
  let path = DIRECTORY_CASES / $k
  writeFile(path & ".kind", kind)
  for j in 0 ..< pieces.len: writeFile(path & "." & $j & ".piece", pieces[j])
  writeFile(path & ".count.text", $pieces.len)
  writeFile(path & ".html", drawing.html)
  writeFile(path & ".status", drawing.status)


proc writeCasesPage() =
  ## Write each case of suite of page: each sample read whole, each text streamed, text typed and
  ##   edit, with drawing native build gives each.
  removeDir(DIRECTORY_CASES)
  createDir(DIRECTORY_CASES)
  var k = 0
  for sample in readFile(PATH_SHELL).samples:
    writeCase(k, "whole", @[sample], sample.drawnWhole)
    inc k
  for text in STREAMED:
    writeCase(k, "stream", @[text], text.drawnWhole)
    inc k
  block:
    var
      reader = initReaderLive()
      change: ChangeNif
    let pieces = TYPED.toPieces
    for piece in pieces: change = reader.push(piece)
    writeCase(k, "typed", pieces, drawn(reader.toNif, change.tail))
    inc k
  block:
    var reader = initReaderLive()
    let change = reader.push(EDITED[^1])
    writeCase(k, "edit", @EDITED, drawn(reader.toNif, change.tail))
    inc k
  writeFile(DIRECTORY_CASES / "count.text", $k)


proc findChromium(): string =
  ## Give program of Chromium: one variable names, else one store serves, unpacked; empty where
  ##   neither gives one.
  let named = getEnv(VARIABLE_CHROMIUM)
  if named.len > 0:
    if named.fileExists: return named
    stderr.writeLine "Chromium `" & VARIABLE_CHROMIUM & "` names should exist; got `" & named & "`."
    return ""
  let (output, code) = execCmdEx(
    "nim r --hints:off --warnings:off " & quoteShell(PATH_KOCH) & " fetch-assets " & FILE_CHROMIUM)
  if code != 0:
    stderr.writeLine "Chromium should come from `" & VARIABLE_CHROMIUM & "`, or from store of " &
      "repository, which `koch fetch-assets` serves as `" & FILE_CHROMIUM & "` (#864); got exit `" &
      $code & "`: " & output.strip
    return ""
  removeDir(DIRECTORY_CHROMIUM)
  createDir(DIRECTORY_CHROMIUM)
  let
    archive = output.strip.splitLines[^1]  # path store serves archive at
    (unpacked, code_unzip) = execCmdEx(
      "unzip -q " & quoteShell(archive) & " -d " & quoteShell(DIRECTORY_CHROMIUM))
  if code_unzip != 0:
    stderr.writeLine "Archive of Chromium should unpack; got exit `" & $code_unzip & "`: " &
      unpacked
    return ""
  PATH_CHROMIUM_UNPACKED


proc runSuite(chromium, name, mode: string): int =
  ## Run one suite on page of its own, in mode page gives it as attribute of body, print each line
  ##   it reports, and give 1 where it failed.
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
  ## Run suite of page in page built with it, in mode page gives it as attribute of body, print
  ##   each line it reports, and give 1 where it failed.
  let
    headers = (if mode == MODE_REFUSED: @[POLICY_REFUSED] else: @[])
    hosted = SKELETON_HOSTED[0] & mode & SKELETON_HOSTED[1] & page & SKELETON_HOSTED[2]
    run = chromium.runPage(hosted, ROOT_SERVED, headers)
  for line in run.lines: echo line
  if run.code != 0:
    stderr.writeLine "Suite of page should pass in Chromium; got code `" & $run.code & "`."
    return 1


proc toFile(source: string): string =
  ## Write bytes of `data:` source of font face into file named by their digest, beside
  ##   `written.json`, and give path relative to it; empty where source is no inlined font.
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
  ## Read page with collector, and give what it posts; nil where run failed.
  let
    script = "<script src=\"/drive/collector.js\"></script>"
    run = chromium.runPage(page.replace("</body>", script & "</body>"), ROOT_SERVED)
  if run.code != 0 or "/collected" notin run.posted: return nil
  run.posted["/collected"].parseJson


proc collectPages(chromium: string, faces: Table[string, string]): int =
  ## Read page of live text, and control page where `koch drive` wrote one, with collector, and
  ##   write what it read into `written.json`, each font face page declares as file of its own;
  ##   give 1 where collector failed, or control page declares font face.
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
  ## Build script, page, suites and collector, write texts and cases of suites, then run each
  ##   suite and collector in Chromium; give 1 where any build, suite or collector failed.
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
