## Build tag page and drive it: `nim r tools/page.nim <page|drive>`, from project directory.
##
##   |---------|----------------------------------------------------------------------------|
##   | Command | Effect                                                                     |
##   |---------|----------------------------------------------------------------------------|
##   | page    | compile `app/page.nim` to JavaScript, inline it, each font face of store   |
##   |         | and worked example `alice` into `pages/tagger.html`, and write             |
##   |         | `build/page/tagger.html`                                                   |
##   | drive   | build page, run `tests/browser/suite_page.nim` in it in each mode, run     |
##   |         | collector on it and on control page of `koch drive` in Chromium, and write |
##   |         | `build/font-faces/written.json` for `koch drive`                           |
##   |---------|----------------------------------------------------------------------------|
##   Exit: 0 done, 1 build or drive failed, 2 usage error.
##
##   Runs as own program, so driver `tools/build.nim` imports no package (its header says why).
##   Siblings: `ricysoho/tools/page.nim` and `ricysoho/tools/browser.nim`, whose steps of build
##     and collection this file takes (II.9). Each project drives its own pages, as D1 on #1058
##     ruled; fix to one is finished only when other is checked.
##   Page ships each font face whole, as `data:` source, since store serves them and page loads
##     nothing else (Article X.8, CONTRIBUTOR.md, Pages and assets).
##     Cost: page holds about 3 MiB, nearly all font faces; ceiling of Artifact page is 16 MiB.
##   Script may never hold `</script`, since it would close element it stands in; build refuses.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[base64, json, os, osproc, strutils, tables]

import ../src/rictadni/suggestions
import ./[drive, examples]


const
  USAGE = "Usage: nim r tools/page.nim <page|drive>\n"  ## Text printed on usage error.
  ROOT_BUILT = "build"  ## Root of each file page build and drive write; git ignores it.
  PATH_SHELL = "pages" / "tagger.html"  ## Source of page, with tokens build fills.
  PATH_ENTRY = "app" / "page.nim"  ## Source of script of page.
  PATH_COLLECTOR = "tools" / "drive" / "collector.nim"  ## Source of collector drive runs in page.
  PATH_SUITE = "tests" / "browser" / "suite_page.nim"  ## Source of suite drive runs on page.
  MODES_SUITE = ["runtime", "served", "server"]  ## Each mode suite runs page in.
  DIRECTORY_PAGE = ROOT_BUILT / "page"  ## Directory of built page and its script.
  PATH_COMPILED = DIRECTORY_PAGE / "page.js"  ## Script of page, compiled.
  PATH_PAGE* = DIRECTORY_PAGE / "tagger.html"  ## Page as built, which `suggester serve` serves.
  DIRECTORY_DRIVE = ROOT_BUILT / "drive"  ## Directory drive serves files of, collector among them.
  DIRECTORY_FONT_FACES = ROOT_BUILT / "font-faces"  ## Directory `koch drive` reads.
  PATH_CONTROL = DIRECTORY_FONT_FACES / "control.html"  ## Control page `koch drive` writes.
  PATH_WRITTEN = DIRECTORY_FONT_FACES / "written.json"  ## What collector read, for `koch drive`.
  DIRECTORY_FILES = "files"  ## Directory of font files, under `DIRECTORY_FONT_FACES`.
  PAGE_CONTROL = "control"  ## Name `written.json` gives control page.
  PAGE_TAGGER = "tagger"  ## Name `written.json` gives tag page.
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"  ## Koch, which serves store.
  VARIABLE_CHROMIUM = "RICTADNI_CHROMIUM"  ## Variable that names Chromium to drive with.
  FILE_CHROMIUM = "chrome-headless-shell-linux64-153.0.8010.12.zip"  ## Chromium of store.
  DIRECTORY_CHROMIUM = ROOT_BUILT / "chromium"  ## Directory Chromium of store unpacks into.
  PATH_CHROMIUM_UNPACKED = DIRECTORY_CHROMIUM / "chrome-headless-shell-linux64" /
      "chrome-headless-shell"
    ## Binary of Chromium of store, once unpacked.
  TOKEN_EMBED = "@EMBED:"  ## Token of font face in shell: `@EMBED:<file>@`.
  TOKEN_SCRIPT = "@SCRIPT@"  ## Token of script in shell.
  TOKEN_EXAMPLE_TEXT = "@EXAMPLE_TEXT@"  ## Token of text of worked example in shell.
  TOKEN_EXAMPLE_ANSWER = "@EXAMPLE_ANSWER@"  ## Token of answer of worked example in shell.
  NAME_EXAMPLE = "alice"  ## Worked example page shows before any text is asked.
  SKELETON_HOSTED = (
    "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" " &
      "content=\"width=device-width, initial-scale=1\"></head><body>",
    "</body></html>",
  )
    ## Skeleton host of Artifact wraps page in; shell holds none, so drive wraps it alike.



#[ Build ]#

proc compileJs(source, output: string): int =
  ## Compile Nim module to JavaScript in release mode; exit code of compiler.
  createDir(output.parentDir)
  let process = startProcess(
    getCurrentCompilerExe(),
    args = ["js", "--hints:off", "-d:release", "--out:" & output, source],
    options = {poParentStreams},
  )
  result = process.waitForExit
  process.close
  if result != 0: stderr.writeLine "Compile of `" & source & "` failed; got exit `" & $result & "`."


proc digestText(text: string): string =
  ## Read SHA-256 of text, as `sha256sum` prints it.
  let (output, code) = execCmdEx("sha256sum", input = text)
  if code != 0: raise newException(OSError, "Digest should be read; got `" & output & "`.")
  output.splitWhitespace[0]


func fontFacesAsked(shell: string): seq[string] =
  ## Read file of each font face shell asks for, once each, in order.
  var at = shell.find(TOKEN_EMBED)
  while at >= 0:
    let close = shell.find('@', at + TOKEN_EMBED.len)
    if close < 0: break
    let name = shell[at + TOKEN_EMBED.len ..< close]
    if name.len > 0 and '<' notin name and name notin result: result.add name
    at = shell.find(TOKEN_EMBED, close + 1)


func mediaType(name: string): string =
  ## Give media type of font file by its extension.
  if name.endsWith(".woff2"): "font/woff2" else: "font/ttf"


proc fontFaces(shell: string): Table[string, string] =
  ## Fetch each font face shell asks for from store, by `koch fetch-assets`; bytes by file.
  let
    names = shell.fontFacesAsked
    (output, code) = execCmdEx("nim r --hints:off --warnings:off " & quoteShell(PATH_KOCH) &
        " fetch-assets " & names.quoteShellCommand)
  if code != 0:
    raise newException(OSError, "`koch fetch-assets` should serve every font face; got exit `" &
        $code & "`: " & output.strip)
  var paths: seq[string]
  for line in output.strip.splitLines:
    if line.strip.len > 0 and fileExists(line.strip): paths.add line.strip
  if paths.len != names.len:
    raise newException(OSError, "`koch fetch-assets` should name one path for each of " &
        $names.len & " font faces; got " & $paths.len & ".")
  for k in 0 ..< names.len: result[names[k]] = readFile(paths[k])


proc builtPage(script: string): string =
  ## Fill shell: each font face as `data:` source, then script; refuse token left unfilled.
  if "</script" in script.toLowerAscii:
    raise newException(ValueError, "Script should never close its element; it would close " &
        "element it stands in.")
  let shell = readFile(PATH_SHELL)
  result = shell
  for name, bytes in shell.fontFaces:
    result = result.replace("url(" & TOKEN_EMBED & name & "@)",
        "url(data:" & mediaType(name) & ";base64," & encode(bytes) & ")")
  if "url(" & TOKEN_EMBED in result:
    raise newException(ValueError, "Shell should hold no font face build fills no more.")
  var example = EXAMPLES[0]
  for each in EXAMPLES:
    if each.name == NAME_EXAMPLE: example = each
  for (token, text) in [(TOKEN_SCRIPT, script), (TOKEN_EXAMPLE_TEXT, example.argument.escapeMarkup),
      (TOKEN_EXAMPLE_ANSWER, example.answer.escapeMarkup)]:
    if result.count(">" & token & "<") != 1 or result.count(token) != 2:
      raise newException(ValueError, "Shell should hold token `" & token & "` once in header " &
          "comment and once as content of its element.")
    result = result.replace(">" & token & "<", ">" & text & "<")


proc writePage(): int =
  ## Compile script, build page, write it, and print its path, digest and size.
  if compileJs(PATH_ENTRY, PATH_COMPILED) != 0: return 1
  let page = builtPage(readFile(PATH_COMPILED))
  writeFile(PATH_PAGE, page)
  echo PATH_PAGE
  echo "sha256 ", page.digestText, ", bytes ", page.len



#[ Drive ]#

proc findChromium(): string =
  ## Give Chromium that `VARIABLE_CHROMIUM` names, else unpack that of store; empty where neither.
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
    archive = output.strip.splitLines[^1]  # Path store gave archive at.
    (unpacked, code_unzip) = execCmdEx(
      "unzip -q " & quoteShell(archive) & " -d " & quoteShell(DIRECTORY_CHROMIUM))
  if code_unzip != 0:
    stderr.writeLine "Archive of Chromium should unpack; got exit `" & $code_unzip & "`: " &
      unpacked
    return ""
  PATH_CHROMIUM_UNPACKED


proc toFile(source: string): string =
  ## Write font file of `data:` source beside `written.json`, named by its digest; its name, or
  ##   empty where source inlines no font.
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
  ## Run collector on page in Chromium; what it posted, or `nil` where run failed.
  let
    script = "<script src=\"/collector.js\"></script>"
    run = chromium.runPage(page.replace("</body>", script & "</body>"), DIRECTORY_DRIVE)
  for line in run.lines: echo line
  if run.code != 0 or "/collected" notin run.posted: return nil
  run.posted["/collected"].parseJson


proc passesSuite(chromium, page: string): bool =
  ## Run suite on page in each mode, before script of page, and print what it logged; each passes.
  ##   Suite runs inside function of its own, since each program Nim compiles to JavaScript
  ##     declares same global names, and second program on page would replace those of first.
  result = true
  let
    at = page.rfind("<script>")
    suite = "<script>(function () {\n" & readFile(DIRECTORY_DRIVE / "suite_page.js") &
        "\n})();</script>"
  for mode in MODES_SUITE:
    let
      body = "<body data-mode=\"" & mode & "\">"
      hosted = SKELETON_HOSTED[0].replace("<body>", body) & page[0 ..< at] &
          suite & page[at .. ^1] & SKELETON_HOSTED[1]
      run = chromium.runPage(hosted, DIRECTORY_DRIVE)
    for line in run.lines: echo line
    if run.code != 0:
      stderr.writeLine "Suite of page should pass in mode `" & mode & "`; got exit `" & $run.code &
          "`."
      result = false


proc runDrive(): int =
  ## Build page, run its suite, collect it and control page of `koch drive`, and write
  ##   `written.json`. Exit 1 where build, suite, collector or control page fails.

  # Build page and collector.
  if writePage() != 0: return 1
  if compileJs(PATH_COLLECTOR, DIRECTORY_DRIVE / "collector.js") != 0: return 1
  if compileJs(PATH_SUITE, DIRECTORY_DRIVE / "suite_page.js") != 0: return 1
  let chromium = findChromium()
  if chromium.len == 0: return 1
  if not chromium.passesSuite(readFile(PATH_PAGE)): return 1
  removeDir(DIRECTORY_FONT_FACES / DIRECTORY_FILES)
  createDir(DIRECTORY_FONT_FACES / DIRECTORY_FILES)

  # Collect page as host wraps it, and write each font face it inlines beside `written.json`.
  var written = newJObject()
  let tagger = chromium.collected(SKELETON_HOSTED[0] & readFile(PATH_PAGE) & SKELETON_HOSTED[1])
  if tagger.isNil:
    stderr.writeLine "Collector should post what tag page draws."
    return 1
  var declared = newJArray()
  for rule in tagger["rules"]:
    let file = rule["source"].getStr.toFile
    if file.len == 0:
      stderr.writeLine "Font face of page should be inlined as `data:` source of font; got `" &
          rule["source"].getStr[0 ..< min(60, rule["source"].getStr.len)] & "`."
      return 1
    declared.add %*{"family": rule["family"], "weight": rule["weight"], "range": rule["range"],
        "file": file}
  written[PAGE_TAGGER] = %*{"runs": tagger["runs"], "declared": declared,
      "refused": tagger["refused"]}

  # Collect control page that `koch drive` writes, which must declare no font face.
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


proc main(): int =
  ## Dispatch command named as first argument.
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  case paramStr(1)
  of "page": writePage()
  of "drive": runDrive()
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
