## Run each check of this project that runs in browser, as verb `drive`: build script, compile each
##   suite of `tests/browser/` and collector to JavaScript, write texts live suite reads with NIF
##   native build gives each, run each suite on page of its own in headless Chromium (`drive.nim`),
##   and read control page `koch drive` writes with collector, into `written.json`.
##
##   |-----------|---------------------------------------------------------------------------|
##   | Code      | Meaning                                                                   |
##   |-----------|---------------------------------------------------------------------------|
##   | compileJs | compile module to JavaScript, as script ships                             |
##   | runDrive  | build, then run each suite and collector in Chromium; exit 1 on failure   |
##   |-----------|---------------------------------------------------------------------------|
##
##   Live suite runs again on page whose rule of content refuses each worker, so reader gives way
##     to thread of page, as script does where page refuses worker.
##   Each suite runs on page of its own, which loads it alone, by its address: each holds bridge,
##     as shipped script does, since each script Nim compiles defines its procs as globals, and
##     second script on page replaces procs of first that share names. Worker of live suite
##     starts from that address, as worker of script starts from address of script.
##   Texts of live suite are constructed, each with word that reaches back, and sentences of
##     Tatoeba joined; NIF each gives is native build's, as `readTextParts` gives parts of text
##     read whole, which law of `test_live.nim` holds live text to.
##   Each text and its NIF is file of one string, so no format stands between backend and page.
##   Control page holds no font face, and no page of project ships one yet, so collector reads
##     rule of none; rule it reads is finding, since `written.json` names file of each.
##   Chromium is one `LOJBAN_CHROMIUM` names, else headless shell of Chrome for Testing that
##     `koch fetch-assets` serves from store of repository, unpacked under `build/chromium/`.

{.experimental: "strictFuncs".}

import std/[json, os, osproc, strutils, tables]

import ../src/lojban_parser/[nif, prose]
import ../tests/sample_tatoeba/sentences
import ./drive


const
  PATH_BRIDGE* = "src" / "javascript" / "bridge.nim"  ## Module exposing parser to JavaScript.
  PATH_SCRIPT* = "build" / "lojban_parser.js"  ## Script verb `javascript` writes from bridge.
  ROOT_SERVED = "build"  ## Folder backend serves, by path of each file under it.
  DIRECTORY_DRIVE = ROOT_SERVED / "drive"  ## Folder of each script and text of suites.
  DIRECTORY_LIVE = DIRECTORY_DRIVE / "live"  ## Folder of texts of live suite, with NIF of each.
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
    "zoi gy. café 😀 .gy. cu melbi .i mi klama .i do cadzu si si si ko",
      # NIF holds rune past U+FFFF before cut; `zoi` quotes it (19.10)
    "mi su do .i ko",  # `su` ends text before it (ruling on #859)
    "lo'u mi su do le'u .i ko",  # `le'u` quotes `su` once it comes (19.9)
  ]
    ## Constructed texts of live suite, each with word that reaches back.
  SKELETON_PAGE = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>",
    "</title></head><body data-mode=\"", "\">", "</body></html>",
  )
    ## Document each suite runs in: opening, then title, then mode, then script, then closing.



proc compileJs*(source, output: string, defines: openArray[string] = []): int =
  ## Compile module to JavaScript with `-d:release`, as script ships, and give exit of compiler.
  ##   Compiler is one that compiled this driver, never other `nim` that PATH holds.
  createDir(output.parentDir)
  var arguments = @["js", "--hints:off", "-d:release", "--out:" & output]
  for define in defines: arguments.add "-d:" & define
  arguments.add source
  let process = startProcess(getCurrentCompilerExe(), args = arguments, options = {poParentStreams})
  result = process.waitForExit
  process.close
  if result != 0: stderr.writeLine "Compile of `" & source & "` failed; got exit `" & $result & "`."


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


proc collectControl(chromium: string): int =
  ## Read control page `koch drive` wrote with collector, and write what it read into
  ##   `written.json`; give 1 where collector read rule of font face, which no page ships.
  if not PATH_CONTROL.fileExists:
    echo "No control page: `koch drive` writes it, so `written.json` stays unwritten."
    return 0
  let
    control = PATH_CONTROL.readFile
    script = "<script src=\"/drive/collector.js\"></script>"
    run = chromium.runPage(control.replace("</body>", script & "</body>"), ROOT_SERVED)
  if run.code != 0 or "/collected" notin run.posted:
    stderr.writeLine "Collector should post what control page draws; got code `" & $run.code & "`."
    return 1
  let collected = run.posted["/collected"].parseJson
  if collected["rules"].len > 0:
    stderr.writeLine "Control page should declare no font face, as no page of project ships one; " &
      "got " & $collected["rules"].len & "."
    return 1
  let written = %*{PAGE_CONTROL: {
    "runs": collected["runs"], "declared": newJArray(), "refused": collected["refused"],
  }}
  writeFile(PATH_WRITTEN, written.pretty & "\n")
  echo PATH_WRITTEN


proc runDrive*(): int =
  ## Build script, suites and collector, write texts of live suite, then run each suite and
  ##   collector in Chromium; give 1 where any build, suite or collector failed.
  if compileJs(PATH_BRIDGE, PATH_SCRIPT) != 0: return 1
  for (name, mode) in SUITES:
    if mode.len > 0: continue  # suite run in other mode compiles once
    if compileJs("tests" / "browser" / name & ".nim", DIRECTORY_DRIVE / name & ".js",
        ["testing"]) != 0:
      return 1
  if compileJs(PATH_COLLECTOR, DIRECTORY_DRIVE / "collector.js") != 0: return 1
  writeTextsLive()
  let chromium = findChromium()
  if chromium.len == 0: return 1
  for (name, mode) in SUITES: result = max(result, chromium.runSuite(name, mode))
  result = max(result, chromium.collectControl)
