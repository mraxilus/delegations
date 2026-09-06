## Build browser page of this project: `nim r tools/build.nim <command>`.
##   Repository drives tests through koch, which holds no verb for assembling page, so
##   project carries its own compiled driver (CONTRIBUTOR.md, "Directories inside your
##   project are yours"). Translation of retired `build_browser.sh`, step for step.
##   Rejected: shell script, which no checker reads; nimble task, which puts logic in
##   compiler's virtual machine; extending koch, since verbs of one project belong to that
##   project.
##
##   |----------|-----------------------------------------------------------------------|
##   | Command  | Effect                                                                |
##   |----------|-----------------------------------------------------------------------|
##   | declare  | derive `bridge.d.ts` from bridge's own `exportc` signatures            |
##   | web      | declare, compile bridge through JS backend, type-check and emit        |
##   |          | TypeScript, inline faces, fold everything into one self-contained page |
##   | assets   | fetch vendored faces page embeds                                       |
##   | clean    | remove `build`, `bin` and `nimcache`                                   |
##   |----------|-----------------------------------------------------------------------|
##   Everything lands under `build/`, which root `.gitignore` covers at any depth.
##   Exit: 0 done, 1 command failed, 2 usage error.
##
##   Page is one file, so it opens from `file://` or artefact host reaching no font host
##     and no script host. That is why faces are inlined and why scripts concatenate.
##   Scripts share one global scope rather than importing each other: TypeScript 7 removed
##     `outFile`, so compiler no longer bundles, and page cannot resolve ES imports without
##     server. Files therefore carry no top-level `import` or `export`, compiler checks them
##     as one program, and `SCRIPTS` below is order they concatenate in. `const` is not
##     hoisted, so that order is load-bearing.
##
##   Cost: driver runs from project directory, since every path here is relative to it.
##   Cost: `web` needs node and npm alongside Nim; `assets` needs network once.

{.experimental: "strictFuncs".}

import std/[os, osproc, strutils]


const
  BUILD = "build"
    ## Directory every product lands in.
  BUILD_BROWSER = BUILD / "browser"
    ## Directory browser products land in.
  DIR_FONTS = BUILD / "fonts"
    ## Directory vendored faces land in; never committed (Article XI.3).
  PATH_BRIDGE_NIM = "src" / "browser" / "bridge.nim"
    ## Bridge compiled through JS backend, and source `declare` reads.
  PATH_BRIDGE_JS = BUILD_BROWSER / "bridge.js"
    ## Compiled bridge, first script on page.
  PATH_DECLARATIONS = BUILD / "bridge.d.ts"
    ## Derived declarations of bridge's exports, read by type-checker alone.
    ##   Outside `outDir`, which TypeScript excludes from its own inputs by default.
  PATH_SHELL = "pages" / "shell.html"
    ## Committed markup, carrying `@EMBED:<face>@` and `@SCRIPT@` tokens.
  PATH_PAGE = BUILD / "rga_visualiser.html"
    ## Assembled page.
  TOKEN_SCRIPT = "@SCRIPT@"
    ## Token every script replaces, so committed shell stays whole document.
  TOKEN_EMBED = "@EMBED:"
    ## Opening of token one face replaces.
  MARKER_GATE = "// Not Nim because generated from Nim: declarations of bridge's exports,\n" &
    "//   derived so no second copy of signature can drift from it (Article II.9).\n"
    ## Header derived declarations carry, since `.ts` is gated kind.
  RECORDS = ["OperationResult", "DragResult", "FrameData"]
    ## Object types crossing boundary, whose fields page reads by name.
  SCRIPTS = [
    "dom", "gl", "state", "download", "drawer", "keyboard", "view_panel", "construct_panel",
    "objects_panel", "scene_file", "sizes", "diagnostics", "overlay", "pointer", "resize",
    "frame",
  ]
    ## Order scripts concatenate in, i.e. order they must run in.
    ##   Each names what it holds; `dom` first because every later script looks elements
    ##   up through it, `gl` next because every later script draws through it, and `frame`
    ##   last because it starts loop everything else has to be ready for.
  FACES = [
    "commit-mono-latin-400-normal.woff2",
    "noto-sans-latin-400-normal.woff2",
    "noto-sans-latin-600-normal.woff2",
    "noto-sans-math-math-400-normal.woff2",
    "noto-sans-symbols-2-symbols-400-normal.woff2",
    "noto-serif-latin-400-normal.woff2",
  ]
    ## Faces page embeds, all SIL Open Font License 1.1; origins in PROVENANCE.md.
  HOST_FACES = "https://cdn.jsdelivr.net/npm/@fontsource"
    ## Host `assets` fetches faces from.
  USAGE = "Usage: nim r tools/build.nim <declare|web|assets|clean>\n"
    ## Text printed on usage error.


proc run(command: string, args: openArray[string]) =
  ## Run command with args from project directory; raise on non-zero exit.
  let process = startProcess(command, args = args, options = {poUsePath, poParentStreams})
  let code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, command & " failed; got exit `" & $code & "`.")



#[ Declarations ]#

func typeScriptOf(nim_type: string): string =
  ## Map Nim type at bridge boundary onto its TypeScript spelling.
  ##   `FlatBuffer` is opaque handle on JS `Float32Array`, never constructed in Nim; every
  ##   `seq` reaches JS as plain array, since JS backend boxes elements.
  case nim_type.strip
  of "cint", "cfloat", "float", "float32", "int": "number"
  of "bool": "boolean"
  of "cstring", "string": "string"
  of "FlatBuffer": "Float32Array"
  of "seq[cstring]", "seq[string]": "string[]"
  of "seq[cint]", "seq[int]", "seq[float]", "seq[float32]": "number[]"
  of "": "void"
  else: nim_type.strip


func signatureAt(lines: openArray[string], index: int): string =
  ## Join declaration ending at `index`, i.e. walk back to its `proc` or `func` keyword.
  ##   Signatures wrap across lines, so line carrying pragma is rarely whole declaration.
  var start = index
  while start >= 0 and
      not (lines[start].startsWith("proc ") or lines[start].startsWith("func ")):
    dec start
  if start < 0: return ""
  var parts: seq[string]
  for i in start .. index: parts.add lines[i].strip
  parts.join(" ").split("{.exportc")[0].strip


func declarationOf(signature: string): string =
  ## Render one TypeScript declaration from one Nim signature; empty where unparsable.
  let opened = signature.find('(')
  if opened < 0: return ""
  let name = signature[0 ..< opened].split(' ')[^1].strip
  let closed = signature.rfind(')')
  if closed < opened: return ""

  # Nim lets one group carry several types (`a, b: int, c: float`) and lets several names
  #   share one (`a, b: int`), so names accumulate until fragment states type, and that
  #   type covers every name waiting.
  var rendered, waiting: seq[string]
  for group in signature[opened + 1 ..< closed].split(';'):
    for fragment in group.split(','):
      let stated_at = fragment.find(':')
      if stated_at < 0:
        if fragment.strip.len > 0: waiting.add fragment.strip
        continue
      waiting.add fragment[0 ..< stated_at].strip
      # Default value belongs to declaration, never to type; parameter carrying one is
      #   optional on page, which is what `?` says.
      let stated = fragment[stated_at + 1 .. ^1]
      let defaulted = stated.find('=')
      let is_optional = defaulted >= 0
      let rendered_type =
        (if is_optional: stated[0 ..< defaulted] else: stated).typeScriptOf
      for name in waiting:
        rendered.add name & (if is_optional: "?: " else: ": ") & rendered_type
      waiting.setLen 0

  let tail = signature[closed + 1 .. ^1].strip
  let returned = if tail.startsWith(":"): tail[1 .. ^1].typeScriptOf else: "void"
  "declare function " & name & "(" & rendered.join(", ") & "): " & returned & ";"


func recordOf(lines: openArray[string], name: string): string =
  ## Render TypeScript interface from Nim object type of `name`; empty where absent.
  ##   Read from bridge rather than kept beside it, so record crossing boundary has one
  ##   home and no second copy can drift from it (Article I.4).
  var start = -1
  for i, line in lines:
    if line.startsWith("type " & name & " = object") or
        line.startsWith("type " & name & "* = object"):
      start = i
      break
  if start < 0: return ""

  var fields: seq[string]
  for i in start + 1 ..< lines.len:
    let line = lines[i]
    if line.len > 0 and line[0] notin {' ', '\t'}: break
    let bare = line.strip
    if bare.len == 0 or bare.startsWith("##"): continue
    let stated = bare.split("##")[0].strip
    let split_at = stated.find(':')
    if split_at < 0: continue
    let rendered_type = stated[split_at + 1 .. ^1].typeScriptOf
    for field in stated[0 ..< split_at].split(','):
      if field.strip.len == 0: continue
      fields.add "  " & field.strip & ": " & rendered_type & ";"
  if fields.len == 0: return ""
  "interface " & name & " {\n" & fields.join("\n") & "\n}\n"


proc declare() =
  ## Write derived declarations of every bridge export type-checker needs.
  ##   Read from bridge itself rather than kept beside it, so signature has one home and
  ##   stale copy cannot pass check (Article I.4).
  let lines = readFile(PATH_BRIDGE_NIM).splitLines
  var declarations: seq[string]
  for i, line in lines:
    if "{.exportc" notin line: continue
    let rendered = lines.signatureAt(i).declarationOf
    if rendered.len > 0: declarations.add rendered

  var records: seq[string]
  for name in RECORDS:
    let rendered = lines.recordOf(name)
    if rendered.len == 0:
      raise newException(OSError, "Bridge carries no record `" & name & "`.")
    records.add rendered

  createDir BUILD
  writeFile(
    PATH_DECLARATIONS,
    MARKER_GATE &
      "//   Regenerate with `nim r tools/build.nim declare`; never edit by hand.\n\n" &
      records.join("\n") & "\n" & declarations.join("\n") & "\n",
  )
  echo "Wrote ", PATH_DECLARATIONS, " (", declarations.len, " declarations)."



#[ Commands ]#

proc assets() =
  ## Fetch every face page embeds into `build/fonts`.
  ##   Faces are binary, which audit cannot read, so they are never committed and this verb
  ##   is how contributor gets them (CONTRIBUTOR.md, "Pages and assets").
  createDir DIR_FONTS
  for face in FACES:
    # Family is name less its last three parts, i.e. subset, weight and style.
    let family = face.rsplit('-', 3)[0]
    run("curl", ["-sSLf", "-o", DIR_FONTS / face, HOST_FACES & "/" & family & "/files/" & face])
    echo "Fetched ", face
  echo "Wrote ", DIR_FONTS, " (", FACES.len, " faces)."


proc web() =
  ## Assemble whole page: declarations, bridge, scripts, faces, markup.
  ##   Fails with reason rather than emitting broken page: absent face renders as box and
  ##   absent script as blank canvas, neither reporting itself.
  declare()
  createDir BUILD_BROWSER

  # Compile every shared module desktop runs, through JS backend.
  #   `-d:release` belongs to this artefact rather than to `nim.cfg`: suite's JS build keeps
  #   its checks and stack traces, page must not carry them.
  #   `-d:danger` rejected: buys tenth of frame by removing every bounds, range and field
  #   check from one build reader runs.
  run("nim", ["js", "--hints:off", "-d:release", "-o:" & PATH_BRIDGE_JS, PATH_BRIDGE_NIM])

  # Type-check and emit every script, under flags curator ratified (repository issue 27).
  run("npx", ["tsc", "--project", "tsconfig.json"])

  var scripts = readFile(PATH_BRIDGE_JS)
  for name in SCRIPTS:
    let path = BUILD_BROWSER / name & ".js"
    if not fileExists(path):
      raise newException(OSError, "Missing script `" & path & "`; type-check emitted none.")
    scripts.add "\n" & readFile(path)

  var page = readFile(PATH_SHELL)
  for face in FACES:
    let token = TOKEN_EMBED & face & "@"
    if token notin page: continue
    let path = DIR_FONTS / face
    if not fileExists(path):
      raise newException(OSError, "Missing face `" & path & "`; run `assets` first.")
    run("bash", ["-c", "base64 -w0 " & quoteShell(path) & " > " & quoteShell(path & ".b64")])
    page = page.replace(token, "data:font/woff2;base64," & readFile(path & ".b64").strip)

  if TOKEN_SCRIPT notin page:
    raise newException(OSError, "Shell carries no `" & TOKEN_SCRIPT & "`; nothing to fill.")
  page = page.replace(TOKEN_SCRIPT, "\n" & scripts & "\n")

  createDir BUILD
  writeFile(PATH_PAGE, page)
  echo "Wrote ", PATH_PAGE, " (", page.len, " bytes)."


proc clean() =
  ## Remove every product, leaving only what git holds.
  for dir in [BUILD, "bin", "nimcache"]:
    removeDir dir
    echo "Removed ", dir



#[ Entry Point ]#

when isMainModule:
  if paramCount() != 1:
    stderr.write USAGE
    quit 2
  try:
    case paramStr(1)
    of "declare": declare()
    of "web": web()
    of "assets": assets()
    of "clean": clean()
    else:
      stderr.write USAGE
      quit 2
  except CatchableError as e:
    stderr.write e.msg & "\n"
    quit 1
