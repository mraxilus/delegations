## Build page of live text from committed shell, as verb `page`, and compile each module of
##   this project that runs as JavaScript.
##
##   |-----------|---------------------------------------------------------------------------|
##   | Code      | Meaning                                                                   |
##   |-------------|-------------------------------------------------------------------------|
##   | compileJs   | compile module to JavaScript, as script ships                           |
##   | fontFaces   | bytes of each font face shell embeds, as store serves them              |
##   | compiledPage | script of page, compiled                                               |
##   | builtPage   | page built from shell, with script given, as one file                   |
##   | writePage   | build page into `build/`, and print its path, digest and size           |
##   |-------------|-------------------------------------------------------------------------|
##
##   Page is shell `pages/live.html` with its tokens filled (CONTRIBUTOR.md, Pages and assets):
##     each font face it embeds, which `koch fetch-assets` serves after it checks digest against
##       store of repository (`curator/audit/src/assets.nim`), inlined as `data:` source, so page
##       names no font face viewer may lack (Article X.8);
##     text, line, drawing and NIF of first sample, as native build reads it whole and draws its
##       NIF (`src/browser/draw.nim`), so page reads complete before its script runs;
##     script, `src/browser/page.nim` compiled by JavaScript backend of pin, inline, so worker
##       it starts reads from Blob of its text (`live_text.nim`).
##   Built page is one long line under ignored `build/`, never committed.
##   Cost: page holds parser whole and five font faces, which make up most of its bytes.

{.experimental: "strictFuncs".}

import std/[base64, os, osproc, strutils, tables]

import ../src/browser/draw
import ../src/lojban_parser/[nif, prose]


const
  PATH_SHELL* = "pages" / "live.html"  ## Shell page is assembled in.
  PATH_ENTRY = "src" / "browser" / "page.nim"  ## Entry of script page runs.
  PATH_COMPILED = "build" / "page" / "page.js"  ## Script of page, compiled.
  PATH_PAGE* = "build" / "lojban_parser.html"  ## Page built.
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"  ## Driver of repository, asked for font faces.
  TOKEN_EMBED = "@EMBED:"  ## Opening of token one font face replaces, closed by `@`.
  TOKENS = ["@SOURCE@", "@STATUS@", "@DIAGRAM@", "@NIF@", "@SCRIPT@"]
    ## Tokens shell carries beyond font faces, each filled once; script last.
  ATTRIBUTE_SAMPLE = "data-sample=\""  ## Opening of attribute holding text of one sample.



#[ Processes ]#

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


proc digestText*(text: string): string =
  ## Give SHA-256 of text, by `sha256sum`.
  let (output, code) = execCmdEx("sha256sum", input = text)
  if code != 0: raise newException(OSError, "Digest should be read; got `" & output & "`.")
  output.splitWhitespace[0]



#[ Shell ]#

func fontFacesAsked(shell: string): seq[string] =
  ## List font faces embed tokens of shell name, in order of first use.
  var at = shell.find(TOKEN_EMBED)
  while at >= 0:
    let close = shell.find('@', at + TOKEN_EMBED.len)
    if close < 0: break
    let name = shell[at + TOKEN_EMBED.len ..< close]
    if name notin result: result.add name
    at = shell.find(TOKEN_EMBED, close + 1)


func samples*(shell: string): seq[string] =
  ## List text of each sample shell offers, in order, entities of attribute decoded.
  var at = shell.find(ATTRIBUTE_SAMPLE)
  while at >= 0:
    let
      opening = at + ATTRIBUTE_SAMPLE.len
      close = shell.find('"', opening)
    result.add shell[opening ..< close].multiReplace(
      ("&quot;", "\""), ("&lt;", "<"), ("&gt;", ">"), ("&amp;", "&"))
    at = shell.find(ATTRIBUTE_SAMPLE, close)


func mediaType(name: string): string =
  ## Give media type of font face by extension of its file.
  if name.endsWith(".woff2"): "font/woff2" else: "font/ttf"


func drawnWhole*(text: string): DrawingLive =
  ## Draw NIF native build gives text read whole, as page draws it once reader ends.
  drawn(readTextParts(text).reading.toNifParts, "")



#[ Build ]#

proc fontFaces*(): Table[string, string] =
  ## Ask `koch fetch-assets` for each font face shell embeds, and read bytes of each, by name.
  ##   Count of paths is held, since verb prints nothing for font face it could not serve, and
  ##   short list would pair wrong bytes with right name.
  let
    names = readFile(PATH_SHELL).fontFacesAsked
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


proc compiledPage*(): string =
  ## Compile script of page, `src/browser/page.nim`, and give its text.
  if compileJs(PATH_ENTRY, PATH_COMPILED) != 0:
    raise newException(OSError, "Script of page should compile; got `" & PATH_ENTRY & "`.")
  readFile(PATH_COMPILED)


proc builtPage*(script: string, faces: Table[string, string]): string =
  ## Build page from shell: font faces, first sample drawn natively, then script, which is
  ##   script of page as viewer gets it, suite of page in its place, or nothing for collector.
  if "</script" in script.toLowerAscii:
    raise newException(ValueError, "Script should never close its element; it would close " &
        "element it stands in.")
  let
    shell = readFile(PATH_SHELL)
    first = shell.samples[0]
    drawing = first.drawnWhole
  result = shell.multiReplace(
    ("@SOURCE@", first.escaped),
    ("@STATUS@", drawing.status.escaped),
    ("@DIAGRAM@", drawing.html),
    ("@NIF@", readTextParts(first).reading.toNifParts.escaped),
  )
  for name in shell.fontFacesAsked:
    result = result.replace(TOKEN_EMBED & name & "@",
        "data:" & mediaType(name) & ";base64," & encode(faces[name]))
  for token in TOKENS[0 .. ^2] & @[TOKEN_EMBED]:
    if token in result:
      raise newException(ValueError, "Shell should hold no token build fills no more; got `" &
          token & "`.")
  result = result.replace(TOKENS[^1], script)


proc writePage*(): int =
  ## Build page into `build/`, and print its path, digest and size.
  let page = builtPage(compiledPage(), fontFaces())
  writeFile(PATH_PAGE, page)
  echo PATH_PAGE
  echo "sha256 ", page.digestText, ", bytes ", page.len
