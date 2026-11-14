## zbasu le papri pe lo jmive se ciska le calku poi se ralte ne'i la'o gy. git .gy. ta'i lo minde
##   po'u `page` .i fanva ro datnyvei pe le vi se gunka ge'u zi'e poi fasnu ta'i la'o gy. JavaScript
##   .gy. ku'o fi la'o gy. JavaScript .gy.
##
##   |----------------|---------------------------------------------------------------------------|
##   | lo fancu       | lo smuni                                                                  |
##   |----------------|---------------------------------------------------------------------------|
##   | `compileJs`    | fanva pa datnyvei fi la'o gy. JavaScript .gy. ta'i le samtci poi se benji |
##   | `fontFaces`    | lo stuzi pe ro lerfu tarmi poi le calku cu vasru ke'a ku'o ta'i le sorcu  |
##   | `compiledPage` | le se fanva samtci pe le papri                                            |
##   | `builtPage`    | le papri poi se zbasu fi le calku .e le se dunda samtci gi'e datnyvei     |
##   | `writePage`    | zbasu ne'i `build/` gi'e ciska le judri .e le sinxa namcu .e le ni barda  |
##   |----------------|---------------------------------------------------------------------------|
##
##   le papri cu du le calku po'u `pages/live.html` .i ro sinxa pe le calku cu se basti to la'o gy.
##     CONTRIBUTOR.md, Pages and assets .gy. toi
##     .i ro lerfu tarmi poi le calku cu punji ke'a cu basti pa sinxa .i `koch fetch-assets` cu
##       sabji le lerfu tarmi ba lo nu cipra lo du'u lo sinxa namcu cu mintu le sorcu pe la'o gy.
##       delegations .gy. to `curator/audit/src/assets.nim` toi .i le lerfu tarmi cu se punji ne'i
##       le papri ta'i pa `data:` .i se ki'u bo le papri cu cusku no cmene be lo lerfu tarmi poi lo
##       viska ka'e claxu ke'a to `Article X.8` toi
##     .i le se ciska .e le linji .e le pixra .e le se ciska be fi la'o gy. NIF .gy. vu'o pe le
##       pamoi mupli cu basti lo sinxa ta'i lo nu le jbena zbasu cu tcidu le mulno mupli gi'e ciska
##       lo pixra be le se ciska be fi la'o gy. NIF .gy. to `src/browser/draw.nim` toi .i se ki'u bo
##       le papri cu mulno se tcidu pu lo nu le samtci pe le papri cu cfari
##     .i le samtci po'u `src/browser/page.nim` poi le fanva poi se stodi cu fanva ke'a fi la'o gy.
##       JavaScript .gy. cu se punji ne'i le se ciska pe le papri .i se ki'u bo le gunka poi le
##       samtci cu rinka lo nu ke'a cfari cu se krasi pa `Blob` pe le se ciska pe le samtci to
##       `live_text.nim` toi
##   .i le se zbasu papri cu du pa clani linji ne'i `build/` noi la'o gy. git .gy. cu na jundi ke'a
##     .i le papri cu no roi se ralte la'o gy. git .gy.
##   .i jdima fa lo nu le papri cu vasru le mulno genturfa'i .e mu lerfu tarmi .i so'e lo stuzi pe
##     le papri cu pagbu le genturfa'i .a le lerfu tarmi

{.experimental: "strictFuncs".}

import std/[base64, os, osproc, strutils, tables]

import ../src/browser/draw
import ../src/lojban_parser/[nif, prose]


const
  PATH_SHELL* = "pages" / "live.html"  ## le calku poi le papri cu se zbasu ne'i ke'a
  PATH_ENTRY = "src" / "browser" / "page.nim"  ## le krasi datnyvei pe le samtci pe le papri
  PATH_COMPILED = "build" / "page" / "page.js"  ## le se fanva samtci pe le papri
  PATH_PAGE* = "build" / "lojban_parser.html"  ## le se zbasu papri
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"
    ## le jitro samtci pe la'o gy. delegations .gy. ge'u zi'e poi le vi samtci cu cpedu lo lerfu
    ##   tarmi ke'a
  TOKEN_EMBED = "@EMBED:"
    ## lo krasi be lo sinxa poi pa lerfu tarmi cu basti ke'a .i `@` cu fanmo le sinxa
  TOKENS = ["@SOURCE@", "@STATUS@", "@DIAGRAM@", "@NIF@", "@SCRIPT@"]
    ## lo sinxa pe le calku ge'u zi'e poi na sinxa lo lerfu tarmi .i ro sinxa cu se basti pa roi .i
    ##   le sinxa pe le samtci cu se basti ba ro drata
  ATTRIBUTE_SAMPLE = "data-sample=\""  ## lo krasi be lo ckaji poi vasru lo se ciska pe pa mupli



#[ lo pruce ]#

proc compileJs*(source, output: string, defines: openArray[string] = []): int =
  ## fanva pa datnyvei fi la'o gy. JavaScript .gy. sepi'o `-d:release` ta'i le samtci poi se benji
  ##   gi'e dunda lo fanmo namcu pe le fanva .i le fanva cu du le fanva poi fanva le vi jitro samtci
  ##   .i le fanva cu no roi du lo drata fanva poi se cmene `nim` gi'e se vasru `PATH`
  createDir(output.parentDir)
  var arguments = @["js", "--hints:off", "-d:release", "--out:" & output]
  for define in defines: arguments.add "-d:" & define
  arguments.add source
  let process = startProcess(getCurrentCompilerExe(), args = arguments, options = {poParentStreams})
  result = process.waitForExit
  process.close
  if result != 0: stderr.writeLine "Compile of `" & source & "` failed; got exit `" & $result & "`."


proc digestText*(text: string): string =
  ## dunda lo sinxa namcu pe le se ciska ta'i la'o gy. SHA-256 .gy. sepi'o `sha256sum`
  let (output, code) = execCmdEx("sha256sum", input = text)
  if code != 0: raise newException(OSError, "Digest should be read; got `" & output & "`.")
  output.splitWhitespace[0]



#[ le calku ]#

func fontFacesAsked(shell: string): seq[string] =
  ## liste lo lerfu tarmi poi lo sinxa pe lo nu punji ne'i le calku cu cmene ke'a ku'o ta'i le porsi
  ##   be lo pamoi nu pilno
  var at = shell.find(TOKEN_EMBED)
  while at >= 0:
    let close = shell.find('@', at + TOKEN_EMBED.len)
    if close < 0: break
    let name = shell[at + TOKEN_EMBED.len ..< close]
    if name notin result: result.add name
    at = shell.find(TOKEN_EMBED, close + 1)


func samples*(shell: string): seq[string] =
  ## liste lo se ciska pe ro mupli poi le calku cu dunda ke'a ku'o ta'i le porsi .i lo sinxa pe la'o
  ##   gy. HTML .gy. ne'i le ckaji cu se galfi lo lerfu
  var at = shell.find(ATTRIBUTE_SAMPLE)
  while at >= 0:
    let
      opening = at + ATTRIBUTE_SAMPLE.len
      close = shell.find('"', opening)
    result.add shell[opening ..< close].multiReplace(
      ("&quot;", "\""), ("&lt;", "<"), ("&gt;", ">"), ("&amp;", "&"))
    at = shell.find(ATTRIBUTE_SAMPLE, close)


func mediaType(name: string): string =
  ## dunda `font/woff2` .a `font/ttf` ja'i le fanmo be le cmene be le datnyvei pe le lerfu tarmi
  if name.endsWith(".woff2"): "font/woff2" else: "font/ttf"


func drawnWhole*(text: string): DrawingLive =
  ## ciska lo pixra be le se ciska be fi la'o gy. NIF .gy. be'o poi le jbena zbasu cu dunda ke'a le
  ##   se ciska poi mulno se tcidu ku'o ta'i lo nu le papri cu ciska lo pixra ca lo nu le tcidu cu
  ##   sisti
  drawn(readTextParts(text).reading.toNifParts, "")



#[ lo nu zbasu ]#

proc fontFaces*(): Table[string, string] =
  ## cpedu ro lerfu tarmi poi le calku cu punji ke'a ku'o fi `koch fetch-assets` gi'e tcidu lo stuzi
  ##   pe ro le lerfu tarmi .i le cmene cu ckiku le stuzi .i le te kancu be lo judri cu se cipra .i
  ##   ki'u bo le minde cu ciska no da va'o lo nu le minde cu na ka'e sabji pa lerfu tarmi .i va'o
  ##   lo nu le liste cu claxu pa judri kei lo na drani stuzi cu ka'e se jorne lo drani cmene
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
  ## fanva le samtci pe le papri to `src/browser/page.nim` toi gi'e dunda le se ciska pe le samtci
  if compileJs(PATH_ENTRY, PATH_COMPILED) != 0:
    raise newException(OSError, "Script of page should compile; got `" & PATH_ENTRY & "`.")
  readFile(PATH_COMPILED)


proc builtPage*(script: string, faces: Table[string, string]): string =
  ## zbasu le papri le calku .i punji lo lerfu tarmi .e lo jbena pixra be le pamoi mupli .i ba bo
  ##   punji `script` .i `script` cu du le samtci pe le papri ge'u zi'e poi lo viska cu cpacu ke'a
  ##   ku'o .a le cipra pe le papri ge'u zi'e poi basti le samtci ku'o .a lo kunti lerpoi poi le
  ##   crepu cu pilno ke'a
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
  ## zbasu le papri ne'i `build/` gi'e ciska le judri .e le sinxa namcu .e lo ni le papri cu barda
  let page = builtPage(compiledPage(), fontFaces())
  writeFile(PATH_PAGE, page)
  echo PATH_PAGE
  echo "sha256 ", page.digestText, ", bytes ", page.len
