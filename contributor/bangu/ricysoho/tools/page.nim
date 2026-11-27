## zbasu le papri pe lo mivyselci'a le calku poi selra'e ne'i `git` ta'i lo minde po'u `page`
##   .i fanva ro datnyvei pe le vi selgu'a ge'u zi'e poi fasnu ta'i `JavaScript` ku'o fi
##       `JavaScript`
##
##   |----------------|---------------------------------------------------------------------------|
##   | lo fancu       | lo smuni                                                                  |
##   |----------------|---------------------------------------------------------------------------|
##   | `compileJs`    | fanva pa datnyvei fi `JavaScript` ta'i le samtci poi selbe'i |
##   | `fontFaces`    | lo stuzi pe ro lertai poi le calku cu vasru ke'a ku'o ta'i le sorcu  |
##   | `compiledPage` | le se fanva samtci pe le papri                                            |
##   | `builtPage`    | le papri poi selzba fi le calku .e le se dunda samtci gi'e datnyvei     |
##   | `writePage`    | zbasu ne'i `build/` gi'e ciska le judri .e le snina'u .e le ni barda  |
##   |----------------|---------------------------------------------------------------------------|
##
## ni'o le papri cu du le calku po'u `pages/live.html`
##   .i ro sinxa pe le calku cu se basti to `CONTRIBUTOR.md, Pages and assets` toi
##
## ni'o ro lertai poi le calku cu punji ke'a basti pa sinxa
##   .i `koch fetch-assets` sabji le lertai ba lo nu cipra lo du'u lo snina'u cu mintu le sorcu pe
##       `delegations` to `curator/audit/src/assets.nim` toi
##   .i le lertai cu selpu'i ne'i le papri ta'i pa `data:`
##   .i se ki'u bo le papri cu cusku no cmene be lo lertai poi lo viska ka'e claxu ke'a to
##       `Article X.8` toi
##
## ni'o le selci'a .e le linji .e le pixra .e le selci'a be fi `NIF` vu'o pe le pamoi mupli cu basti
##     lo sinxa ta'i lo nu le jbezba cu tcidu le mulmupli gi'e ciska lo pixra be le selci'a be fi
##     `NIF` to `src/browser/draw.nim` toi
##   .i se ki'u bo le papri cu mulseltcidu pu lo nu le samtci pe le papri cu cfari
##   .i le samtci po'u `src/browser/page.nim` poi le fanva poi selsto cu fanva ke'a fi `JavaScript`
##       selpu'i ne'i le selci'a pe le papri
##   .i se ki'u bo le gunka poi le samtci cu rinka lo nu ke'a cfari cu selkra pa `Blob` pe le
##       selci'a pe le samtci to `live_text.nim` toi
##
## ni'o le selzbapapri cu du pa clali'i ne'i `build/` noi `git` na jundi ke'a
##   .i le papri cu no roi selra'e `git`
##   .i jdima fa lo nu le papri cu vasru le mulno genturfa'i .e mu lertai
##   .i so'e lo stuzi pe le papri cu pagbu le genturfa'i .a le lertai

{.experimental: "strictFuncs".}

import std/[base64, os, osproc, strutils, tables]

import ../src/browser/draw
import ../src/ricysoho/[nif, prose]


const
  PATH_SHELL* = "pages" / "live.html"  ## le calku poi le papri cu selzba ne'i ke'a
  PATH_ENTRY = "src" / "browser" / "page.nim"  ## le krasi datnyvei pe le samtci pe le papri
  PATH_COMPILED = "build" / "page" / "page.js"  ## le se fanva samtci pe le papri
  PATH_PAGE* = "build" / "ricysoho.html"  ## le selzbapapri
  PATH_SHELL_LAYERS* = "pages" / "layers.html"
    ## le calku poi le papri pe lo linji be lo selci'a cu selzba ne'i ke'a
  PATH_ENTRY_LAYERS = "src" / "browser" / "text_layers.nim"
    ## le krasi datnyvei pe le samtci pe le papri pe lo linji
  PATH_COMPILED_LAYERS = "build" / "page" / "layers.js"
    ## le se fanva samtci pe le papri pe lo linji
  PATH_PAGE_LAYERS* = "build" / "layers.html"  ## le selzbapapri pe lo linji be lo selci'a
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"
    ## le jitro samtci pe `delegations` ge'u zi'e poi le vi samtci cu cpedu lo lertai ke'a
  TOKEN_EMBED = "@EMBED:"
    ## lo krasi be lo sinxa poi pa lertai cu basti ke'a
    ##   .i `@` fanmo le sinxa
  TOKENS = ["@SOURCE@", "@STATUS@", "@DIAGRAM@", "@NIF@", "@SCRIPT@"]
    ## lo sinxa pe le calku ge'u zi'e poi na sinxa lo lertai
    ##   .i ro sinxa cu se basti pa roi
    ##   .i le sinxa pe le samtci cu se basti ba ro drata
  ATTRIBUTE_SAMPLE = "data-sample=\""  ## lo krasi be lo ckaji poi vasru lo selci'a pe pa mupli



#[ ni'o ni'o ni'o lo pruce ]#

proc compileJs*(source, output: string, defines: openArray[string] = []): int =
  ## fanva pa datnyvei fi `JavaScript` sepi'o `-d:release` ta'i le samtci poi selbe'i gi'e dunda lo
  ##     famna'u pe le fanva
  ##   .i le fanva cu du le fanva poi fanva le vi jitro samtci
  ##   .i le fanva cu no roi du lo datfanva poi selcme `nim` gi'e selvau `PATH`
  createDir(output.parentDir)
  var arguments = @["js", "--hints:off", "-d:release", "--out:" & output]
  for define in defines: arguments.add "-d:" & define
  arguments.add source
  let process = startProcess(getCurrentCompilerExe(), args = arguments, options = {poParentStreams})
  result = process.waitForExit
  process.close
  if result != 0: stderr.writeLine "Compile of `" & source & "` failed; got exit `" & $result & "`."


proc digestText*(text: string): string =
  ## dunda lo snina'u pe le selci'a ta'i `SHA-256` sepi'o `sha256sum`
  let (output, code) = execCmdEx("sha256sum", input = text)
  if code != 0: raise newException(OSError, "Digest should be read; got `" & output & "`.")
  output.splitWhitespace[0]



#[ ni'o ni'o ni'o le calku ]#

func fontFacesAsked(shell: string): seq[string] =
  ## liste lo lertai poi lo sinxa pe lo nu punji ne'i le calku cu cmene ke'a ku'o ta'i le porsi be
  ##     lo pamoi nu pilno
  var at = shell.find(TOKEN_EMBED)
  while at >= 0:
    let close = shell.find('@', at + TOKEN_EMBED.len)
    if close < 0: break
    let name = shell[at + TOKEN_EMBED.len ..< close]
    if name notin result: result.add name
    at = shell.find(TOKEN_EMBED, close + 1)


func samples*(shell: string): seq[string] =
  ## liste lo selci'a pe ro mupli poi le calku cu dunda ke'a ku'o ta'i le porsi
  ##   .i lo sinxa pe `HTML` ne'i le ckaji cu selga'i lo lerfu
  var at = shell.find(ATTRIBUTE_SAMPLE)
  while at >= 0:
    let
      opening = at + ATTRIBUTE_SAMPLE.len
      close = shell.find('"', opening)
    result.add shell[opening ..< close].multiReplace(
      ("&quot;", "\""), ("&lt;", "<"), ("&gt;", ">"), ("&amp;", "&"))
    at = shell.find(ATTRIBUTE_SAMPLE, close)


func mediaType(name: string): string =
  ## dunda `font/woff2` .a `font/ttf` ja'i le fanmo be le cmene be le datnyvei pe le lertai
  if name.endsWith(".woff2"): "font/woff2" else: "font/ttf"


func drawnWhole*(text: string): DrawingLive =
  ## ciska lo pixra be le selci'a be fi `NIF` be'o poi le jbezba cu dunda ke'a le selci'a poi
  ##     mulseltcidu ku'o ta'i lo nu le papri cu ciska lo pixra ca lo nu le tcidu cu sisti
  drawn(readTextParts(text).reading.toNifParts, "")



#[ ni'o ni'o ni'o lo nu zbasu ]#

proc fontFaces*(): Table[string, string] =
  ## cpedu ro lertai poi le calku cu punji ke'a ku'o fi `koch fetch-assets` gi'e tcidu lo stuzi pe
  ##     ro le lertai
  ##   .i le cmene cu ckiku le stuzi
  ##   .i le te kancu be lo judri cu se cipra
  ##   .i ki'u bo le minde cu ciska no da va'o lo nu le minde cu na ka'e sabji pa lertai
  ##   .i va'o lo nu le liste cu claxu pa judri kei lo na drastu cu ka'e seljo'e lo dracme
  var names = readFile(PATH_SHELL).fontFacesAsked
  for name in readFile(PATH_SHELL_LAYERS).fontFacesAsked:
    if name notin names: names.add name
  let
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
  ## fanva le samtci pe le papri to `src/browser/page.nim` toi gi'e dunda le selci'a pe le samtci
  if compileJs(PATH_ENTRY, PATH_COMPILED) != 0:
    raise newException(OSError, "Script of page should compile; got `" & PATH_ENTRY & "`.")
  readFile(PATH_COMPILED)


proc builtPage*(script: string, faces: Table[string, string]): string =
  ## zbasu le papri le calku
  ##   .i punji lo lertai .e lo jbexra be le pamoi mupli
  ##   .i ba bo punji `script`
  ##   .i `script` du le samtci pe le papri ge'u zi'e poi lo viska cu cpacu ke'a ku'o .a le cipra pe
  ##       le papri ge'u zi'e poi basti le samtci ku'o .a lo kunti lerpoi poi le crepu cu pilno ke'a
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


proc compiledLayers*(): string =
  ## fanva le samtci pe le papri pe lo linji to `src/browser/text_layers.nim` toi gi'e dunda le
  ##     selci'a pe le samtci
  if compileJs(PATH_ENTRY_LAYERS, PATH_COMPILED_LAYERS) != 0:
    raise newException(OSError, "Script of page should compile; got `" & PATH_ENTRY_LAYERS & "`.")
  readFile(PATH_COMPILED_LAYERS)


proc builtLayers*(script: string, faces: Table[string, string]): string =
  ## zbasu le papri pe lo linji le calku
  ##   .i punji lo lertai gi'e ba bo punji `script`
  if "</script" in script.toLowerAscii:
    raise newException(ValueError, "Script should never close its element; it would close " &
        "element it stands in.")
  let shell = readFile(PATH_SHELL_LAYERS)
  result = shell
  for name in shell.fontFacesAsked:
    result = result.replace(TOKEN_EMBED & name & "@",
        "data:" & mediaType(name) & ";base64," & encode(faces[name]))
  if TOKEN_EMBED in result:
    raise newException(ValueError, "Shell should hold no token build fills no more; got `" &
        TOKEN_EMBED & "`.")
  result = result.replace(TOKENS[^1], script)


proc writePage*(): int =
  ## zbasu le papri ne'i `build/` gi'e ciska le judri .e le snina'u .e lo ni le papri cu barda
  let
    faces = fontFaces()
    page = builtPage(compiledPage(), faces)
  writeFile(PATH_PAGE, page)
  echo PATH_PAGE
  echo "sha256 ", page.digestText, ", bytes ", page.len
  let layers = builtLayers(compiledLayers(), faces)
  writeFile(PATH_PAGE_LAYERS, layers)
  echo PATH_PAGE_LAYERS
  echo "sha256 ", layers.digestText, ", bytes ", layers.len
