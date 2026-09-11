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
##   | types    | declare, then type-check page's scripts and harness against it         |
##   | web      | declare, compile bridge through JS backend, type-check and emit        |
##   |          | TypeScript, inline faces, fold everything into one self-contained page |
##   | drive    | fetch faces and browser, build page, drive it, report every check      |
##   | desktop  | fetch SDL3 and Dear ImGui, compile desktop front-end into `bin/`       |
##   | driven   | build desktop front-end, drive it through every scripted run, report   |
##   | assets   | fetch vendored faces page embeds, and verify each against its pin      |
##   | system   | print system packages build needs, one per line, for caller to install |
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
##   Cost: `web` needs node and npm alongside Nim; `assets` and `browser`, and `drive`
##     through both, need network on cold tree and none on warm one.
##   Cost: `assets` and `web` need `sha256sum`, for reason `digestOf` gives.
##   Cost: `desktop` needs system libraries `SYSTEM` names, and network on cold tree: it
##     fetches SDL3 and Dear ImGui itself, and refuses to build against wrong version of either.
##   Cost: `driven` needs display; it borrows Xvfb where environment names none.

{.experimental: "strictFuncs".}

import std/[os, osproc, strutils, tables]


const
  BUILD = "build"
    ## Directory every product lands in.
  BIN = "bin"
    ## Directory compiled binaries land in.
  BUILD_BROWSER = BUILD / "browser"
    ## Directory browser products land in.
  DIR_FONTS = BUILD / "fonts"
    ## Directory vendored faces land in; never committed (Article XI.3).
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"
    ## Repository's own driver, which `assets` asks for faces through.
    ##   Relative to this project rather than absolute: derived from where project sits in
    ##   repository, which is what CONTRIBUTOR.md allows and what naming one machine's layout
    ##   is not.
  PATH_FACES_FROM = DIR_FONTS / "store.list"
    ## Which store entry each face was copied from, written by `assets` and read by `web`.
    ##   Under `build/` because it is derived rather than declared, and because it holds paths
    ##   into one machine's own store.
  PATH_BRIDGE_NIM = "src" / "browser" / "bridge.nim"
    ## Bridge compiled through JS backend, and source `declare` reads.
  PATH_BRIDGE_JS = BUILD_BROWSER / "bridge.js"
    ## Compiled bridge, first script on page.
  PATH_DECLARATIONS = BUILD / "bridge.d.ts"
    ## Derived declarations of bridge's exports, read by type-checker alone.
    ##   Outside `outDir`, which TypeScript excludes from its own inputs by default.
  PATH_TSCONFIG = "tsconfig.json"
    ## Page's own type-checker configuration, targeting browser.
  PATH_TSCONFIG_DRIVE = "tsconfig.drive.json"
    ## Harness's own type-checker configuration, targeting node not browser.
  DRIVES = ["keys", "sky", "undo", "select", "drag"]
    ## Scripted runs entry point carries, each reporting checks of its own.
    ##   Help's runs are not here: one per tab, and tabs are read from binary rather than
    ##   listed again, so `help.HelpPath` stays their one home (Article I.4).
  PATH_DESKTOP_NIM = "src" / "desktop" / "main.nim"
    ## Desktop entry point `desktop` compiles.
  PATH_DESKTOP_BIN = BIN / "rga_visualiser"
    ## Desktop binary that verb writes; never committed, since `.gitignore` covers `bin/`.
  ENV_FONT = "RGA_FONT"
    ## Environment name overriding face front-end sets its interface in.
    ##   Declared by `src/desktop/main.nim`, which says what all four are for; named again
    ##   here rather than imported, since driver compiles no project code.
  PATH_FONT_ABSENT = "/nonexistent/no-such-face.ttf"
    ## Path no machine carries, so faceless run asks same question everywhere.
  DIR_IMGUI = "deps" / "imgui"
    ## Dear ImGui checkout desktop front-end compiles into itself; see `gui.PATH_IMGUI`.
  URL_IMGUI = "https://github.com/ocornut/imgui.git"
    ## Origin `imgui` clones from; PROVENANCE.md records it with licence.
  BRANCH_IMGUI = "docking"
    ## Branch carrying `COMMIT_IMGUI`; master lacks docking `gui` asks for.
  DIR_SDL3 = "deps" / "sdl3"
    ## SDL3 checkout `sdl3` builds, beside Dear ImGui's and never committed (Article XI.3).
  DIR_SDL3_BUILD = BUILD / "sdl3-build"
    ## Directory cmake configures SDL3 into.
  DIR_SDL3_PREFIX = BUILD / "sdl3"
    ## Prefix SDL3 installs into, so build needs no root and writes nothing outside tree.
  URL_SDL3 = "https://github.com/libsdl-org/SDL.git"
    ## Origin `sdl3` clones from; PROVENANCE.md records it with licence.
  VERSION_SDL3 = "3.2.30"
    ## Release SDL3 must report through `pkg-config`, zlib licence.
    ##   Names tag rather than version alone: `release-` & this is `release-3.2.30`, which
    ##   `git clone --branch` resolves. That series releases on even patch numbers alone, so
    ##   odd one names no tag and no bytes -- which is what 3.2.31 did, and what repository
    ##   issue 90 was.
    ##   Built from source rather than installed: Ubuntu 24.04 packages SDL2 alone, and
    ##   `apt-get install libsdl3-dev` fails on it outright. Distributions carrying package
    ##   exist, but build cannot depend on which one runs it.
    ##   Pinned exactly rather than as floor: this is what desktop front-end was compiled and
    ##   drawn against, and floor would claim reach across releases nothing here has tried.
  COMMIT_SDL3 = "f5e5f6588921eed3d7d048ce43d9eb1ff0da0ffc"
    ## Commit `release-3.2.30` resolved to when it was read, and what checkout must stand at.
    ##   Neither of two things beside it binds bytes: tag is mutable, and version is what SDL
    ##   says of itself, so tag moved upstream would fetch other sources and `pkg-config` would
    ##   answer `3.2.30` still. Commit cannot move, for reason `COMMIT_IMGUI` gives, and this
    ##   is what `checkSdl3` holds clone against (repository issue 126).
    ##   Tag stays beside it rather than giving way to it: `--depth 1 --branch` needs ref to
    ##   fetch, and one it fetches is this commit. Tag says where to look, commit says what
    ##   must arrive.
  COMMIT_IMGUI = "fd13a1e8923a0a7077b404fc36fd063b25a0c0b5"
    ## Commit that checkout must stand at, i.e. `v1.92.9b-docking-35-gfd13a1e`, MIT licence.
    ##   Pinned for reason `FACES` are: this is fetched at build time and compiled into
    ##   binary reader runs, so which commit it is has to be stated rather than taken.
    ##   Docking branch rather than master: `gui` asks for docking, which master lacks.
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
    "dom", "gl", "state", "download", "drawer", "keyboard", "view_section",
    "construct_section", "objects_section", "scene_file", "sizes", "diagnostics", "overlay",
    "pointer", "resize", "frame",
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
    "noto-serif-latin-600-normal.woff2",
  ]
    ## Faces page embeds. Names alone: what bytes each name is, and where they come from, is
    ##   `curator/audit/src/assets.nim`, and `koch assets` fetches and checks them.
    ##   **Choice is this project's; digest is repository's.** These six are what this page
    ##   draws -- three of Article X.8's families, plus maths and symbols no other target
    ##   asks for -- and that stays here because it differs per target. What left is version
    ##   and SHA-256, which two projects had written identically (repository issue 116).
    ##   Store keeps entries by digest, so face this project shares with another is one file
    ##   on disk rather than two, and pin that moves is different entry rather than stale one.
  FACES_DESKTOP = [
    "NotoSans-Regular.ttf",
    "NotoSans-Bold.ttf",
    "NotoSerif-SemiBold.ttf",
    "NotoSansMath-Regular.ttf",
    "NotoSansSymbols2-Regular.ttf",
    "CommitMonoV142-400Regular.otf",
  ]
    ## Faces desktop front-end loads, named same way and from same store.
    ##   Six for three roles page draws too: `NotoSans` regular and bold for interface and for
    ##   name labels, `NotoSerif` semibold for headings, `CommitMono` for notation and
    ##   figures, and two supplementary Noto faces merged into whichever carries notation.
    ##   Separate list rather than one: page embeds `woff2` and cannot read TrueType, binary
    ##   reads outlines and cannot read `woff2`, so what each front-end wants is not what
    ##   other does even where family is same.
  SYSTEM = [
    ("curl", "fetch faces asked of shared store, one level down through `koch assets`"),
    ("coreutils", "`base64` inlining those faces, and `sha256sum` store checks them with"),
    ("nodejs", "run type-checker `types` drives and harness `drive` runs"),
    ("git", "clone Dear ImGui and SDL3, and read commit `desktop` holds each of them at"),
    ("cmake", "build SDL3 from source, since no package of it exists on Ubuntu 24.04"),
    ("pkg-config", "read version of that SDL3, which `desktop` checks before compiling"),
    ("libx11-dev", "X11 headers SDL3 builds its video backend from; window is X11 one"),
    ("libxext-dev", "X extensions that backend also needs, and without which build refuses"),
    ("libgl-dev", "OpenGL headers and loader `src/desktop/opengl.nim` binds"),
    ("zlib1g-dev", "deflate and CRC PNG export in `src/desktop/image.nim` writes"),
    ("xvfb", "display headless `--drive-*` runs push real SDL events at"),
    ("libgl1-mesa-dri", "software GL those headless runs render through"),
  ]
    ## System packages build needs present before it runs, with what each is for
    ##   (CONTRIBUTOR.md, "System dependencies"). Nim packages are in nimble file and pinned
    ##   by `atlas.lock`; node packages in `package.json`, pinned by its lock. These have
    ##   neither.
    ##   No version is pinned and none is invented: package's version is whatever machine
    ##   carries, which is honest limit rather than omission. What *is* pinned is every byte
    ##   fetched at build time -- see `FACES`, `COMMIT_IMGUI` and `COMMIT_SDL3` -- which is
    ##   what keeps unpinned download out of merge process.
    ##   Dear ImGui and SDL3 are absent deliberately: neither arrives as package. Dear ImGui
    ##   is compiled from source into binary, and Ubuntu 24.04 carries no `libsdl3-dev` at all
    ##   -- only SDL2 -- so SDL3 is built and installed from source too. Both are pinned to
    ##   commit rather than to package manager; see `COMMIT_IMGUI` and `COMMIT_SDL3`.
  USAGE = "Usage: nim r tools/build.nim " &
    "<declare|types|web|drive|desktop|driven|assets|system|clean>\n"
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

proc types() =
  ## Derive bridge's declarations, then type-check every script against them.
  ##   Whole of what checker reaches without browser: `declare` is Nim alone, and both
  ##   configurations check against derived `build/bridge.d.ts`, so export renamed without
  ##   re-deriving fails here rather than at run time (repository issue 47).
  ##   Two configurations rather than one: page's scripts target browser and harness targets
  ##   node, and neither's lib set admits other's.
  ##   `web` and `drive` both call this, so no step is written twice.
  declare()
  run("npx", ["tsc", "--project", PATH_TSCONFIG])
  run("npx", ["tsc", "--project", PATH_TSCONFIG_DRIVE])


proc system() =
  ## Print every system package this build needs, one per line and nothing else.
  ##   Prints rather than installs: which package manager serves them is machine's business
  ##   and varies by distribution, while list is this project's. Caller pipes it --
  ##   `nim r tools/build.nim system | xargs sudo apt-get install -y` -- so CI installs from
  ##   this declaration rather than from names written into workflow.
  ##   Reason each carries stays in `SYSTEM` above, where reader looks; keeping it out of this
  ##   output is what makes output machine-readable.
  for (package, _) in SYSTEM: echo package


proc facesFromStore(names: openArray[string]): seq[string] =
  ## Ask `koch assets` for each face named, and read back path it holds in shared store.
  ##   Repository's verb is `assets` and this project's own verb below is also `assets`; they
  ##   are different drivers, and one asks other. Store serves any file fetched at build time,
  ##   of which faces are only instances today.
  ##   Store is repository's (`curator/audit/src/assets.nim`), keyed by digest, and verb
  ##   fetches what is missing and refuses bytes no row declares -- so verifying here as well
  ##   would be checking answer against question it was derived from.
  ##   Paths come back one per line in order asked, and count is asserted rather than trusted:
  ##   verb prints nothing for face it could not serve, and silently short list would leave
  ##   copy below pairing wrong bytes with right name.
  ##   Compiler chatter is turned off rather than filtered, since paths are what is parsed.
  let (written, code) = execCmdEx(
    "nim r --hints:off --warnings:off " & quoteShell(PATH_KOCH) & " assets " &
      names.quoteShellCommand
  )
  if code != 0:
    raise newException(OSError,
      "`koch assets` would not serve every face; got exit `" & $code & "` --\n" & written)
  for line in written.strip.splitLines:
    let path = line.strip
    if path.len > 0 and fileExists(path): result.add path
  if result.len != names.len:
    raise newException(OSError,
      "`koch assets` named " & $result.len & " paths for " & $names.len & " faces asked for.")


proc assets() =
  ## Copy every face both front-ends draw with out of shared store into `build/fonts`.
  ##   Faces are binary, which audit cannot read, so they are never committed and this verb
  ##   is how contributor gets them (CONTRIBUTOR.md, "Pages and assets").
  ##   Fetching and checking is `koch assets`, not this: digest belongs to repository now that
  ##   two projects draw same files, and this verb names which faces rather than what bytes
  ##   they are (repository issues 116 and 124).
  ##   Copied rather than read from store where they sit: desktop binary finds its faces beside
  ##   itself, and page's build reads them from one directory whether store is warm or cold.
  ##   Face already identical to its store entry is left alone, so verb stays idempotent and
  ##   second run copies nothing.
  createDir DIR_FONTS
  let names = @FACES & @FACES_DESKTOP
  let paths = facesFromStore(names)
  var manifest: seq[string]
  var copied = 0
  for i, face in names:
    let (source, destination) = (paths[i], DIR_FONTS / face)
    manifest.add face & " " & source
    if fileExists(destination) and sameFileContent(source, destination):
      echo "Kept ", face, ", already what the store holds"
      continue
    copyFile(source, destination)
    copied += 1
    echo "Copied ", face, " from store"
  writeFile(PATH_FACES_FROM, manifest.join("\n") & "\n")
  echo "Wrote ", DIR_FONTS, " (", names.len, " faces, ", copied, " copied)."


proc storePathsCopied(): Table[string, string] =
  ## Read which store entry each face in `build/fonts` was copied from.
  ##   Written by `assets` rather than derived here, so nothing in this project has to know
  ##   where store lives or what digest names its entries -- both are `assets.nim`'s.
  if not fileExists(PATH_FACES_FROM): return
  for line in readFile(PATH_FACES_FROM).strip.splitLines:
    let parts = line.strip.split(' ', 1)
    if parts.len == 2: result[parts[0]] = parts[1]


proc checkFace(face: string, copied: Table[string, string]) =
  ## Raise unless face on disk is still byte for byte what store served for it.
  ##   Second reading, at moment bytes are embedded rather than only when they were copied:
  ##   `assets` may have run long ago, and what this embeds is what every reader downloads.
  ##   Compared against store's own file rather than against digest written down here, which
  ##   is what adopting store means -- there is one declaration of these bytes and it is not
  ##   this file.
  let path = DIR_FONTS / face
  if face notin copied:
    raise newException(OSError,
      "Face `" & face & "` names no store entry; run `assets` first.")
  if not fileExists(copied[face]):
    raise newException(OSError,
      "Store no longer holds `" & copied[face] & "` for `" & face & "`; run `assets` again.")
  if not sameFileContent(path, copied[face]):
    raise newException(OSError,
      "Face `" & face & "` is not what the store served; compare `" & path & "` against `" &
        copied[face] & "`.")


proc browser() =
  ## Fetch Chromium Playwright pins, unless environment names browser outright.
  ##   Harness drives Playwright's own build by default, and `tools/drive/main.ts` says in
  ##   what order; nothing else on machine installs it, so this satisfies its own
  ##   precondition exactly as `assets` does for faces.
  ##   Pin is version rather than digest: `package-lock.json` fixes `@playwright/test` and
  ##   version fixes browser revision, but Playwright publishes no checksum for archive it
  ##   serves. So bytes arrive on TLS alone, as compiler tarballs do, and PROVENANCE.md
  ##   records that rather than implying pin stronger than one there is.
  ##   Skipped where `RGA_CHROMIUM` names one: harness reads that first, so second browser
  ##   would be fetched for nobody (Article VII.3). Wrong guess here costs fetch, never wrong
  ##   browser -- harness resolves, and this only provides.
  ##   Costs nothing warm: `playwright install` keeps build already at pinned revision.
  let named = getEnv("RGA_CHROMIUM")
  if named.len > 0:
    echo "Kept ", named, ", named by RGA_CHROMIUM"
    return
  run("npx", ["playwright", "install", "chromium"])


proc web() =
  ## Assemble whole page: declarations, type-check, bridge, scripts, faces, markup.
  ##   Fails with reason rather than emitting broken page: absent face renders as box and
  ##   absent script as blank canvas, neither reporting itself.
  ##   `types` runs first, and emits every script this reads, under flags curator ratified
  ##   (repository issue 27).
  types()
  createDir BUILD_BROWSER

  # Compile every shared module desktop runs, through JS backend.
  #   `-d:release` belongs to this artefact rather than to `nim.cfg`: suite's JS build keeps
  #   its checks and stack traces, page must not carry them.
  #   `-d:danger` rejected: buys tenth of frame by removing every bounds, range and field
  #   check from one build reader runs.
  run("nim", ["js", "--hints:off", "-d:release", "-o:" & PATH_BRIDGE_JS, PATH_BRIDGE_NIM])

  var scripts = readFile(PATH_BRIDGE_JS)
  for name in SCRIPTS:
    let path = BUILD_BROWSER / name & ".js"
    if not fileExists(path):
      raise newException(OSError, "Missing script `" & path & "`; type-check emitted none.")
    scripts.add "\n" & readFile(path)

  var page = readFile(PATH_SHELL)
  let copied = storePathsCopied()
  for face in FACES:
    let token = TOKEN_EMBED & face & "@"
    if token notin page: continue
    let path = DIR_FONTS / face
    if not fileExists(path):
      raise newException(OSError, "Missing face `" & path & "`; run `assets` first.")
    # Read again here, not only where copied: `assets` may have run long ago, and what this
    #   embeds is what every reader downloads. Wrong byte stops build rather than ships.
    checkFace(face, copied)
    run("bash", ["-c", "base64 -w0 " & quoteShell(path) & " > " & quoteShell(path & ".b64")])
    page = page.replace(token, "data:font/woff2;base64," & readFile(path & ".b64").strip)

  if TOKEN_SCRIPT notin page:
    raise newException(OSError, "Shell carries no `" & TOKEN_SCRIPT & "`; nothing to fill.")
  page = page.replace(TOKEN_SCRIPT, "\n" & scripts & "\n")

  createDir BUILD
  writeFile(PATH_PAGE, page)
  echo "Wrote ", PATH_PAGE, " (", page.len, " bytes)."


proc checkCommit(dir, commit, what: string) =
  ## Raise unless checkout in directory stands at commit pinned for it.
  ##   Shared by both sources build fetches: each is compiled into binary reader runs, so
  ##   wrong commit is wrong binary, and one reading holds both rather than two that could
  ##   part (Article II.9).
  let (written, code) = execCmdEx("git -C " & quoteShell(dir) & " rev-parse HEAD")
  if code != 0:
    raise newException(OSError,
      "Cannot read commit of `" & dir & "`; got exit `" & $code & "`.")
  let got = written.strip
  if got != commit:
    raise newException(OSError,
      what & " is not at commit pinned for it; wanted `" & commit & "`, got `" & got & "`.")


proc imgui() =
  ## Clone Dear ImGui at pinned commit, unless checkout already stands somewhere.
  ##   Verb fetches what it compiles rather than asking caller to, for reason `drive` fetches
  ##   faces: check that first wants command run by hand is check runner will not run
  ##   (CONTRIBUTOR.md, "One command drives it").
  ##   Leaves existing checkout alone rather than resetting it: `checkImgui` reads what is
  ##   there next and refuses wrong commit by name, so contributor pointing this at their own
  ##   clone is told rather than overwritten.
  ##   `--filter=blob:none` rather than `--depth`: pinned commit is not branch head, and
  ##   shallow clone cannot reach it. Partial clone fetches blobs that checkout needs alone.
  if dirExists(DIR_IMGUI): return
  run("git", ["clone", "--filter=blob:none", "--branch", BRANCH_IMGUI, URL_IMGUI, DIR_IMGUI])
  run("git", ["-C", DIR_IMGUI, "checkout", "--detach", COMMIT_IMGUI])


proc checkImgui() =
  ## Raise unless Dear ImGui checkout stands at commit pinned for it.
  ##   Refuses by name rather than compiling whatever is there, for reason `checkFace` gives:
  ##   these sources are compiled into binary reader runs, so wrong commit is wrong binary,
  ##   and C++ differing by one release fails far from here with no word of why.
  if not dirExists(DIR_IMGUI):
    raise newException(OSError,
      "Missing Dear ImGui at `" & DIR_IMGUI & "`; clone it with `git clone --branch docking" &
      " https://github.com/ocornut/imgui.git " & DIR_IMGUI & " && git -C " & DIR_IMGUI &
      " checkout " & COMMIT_IMGUI & "`.")
  checkCommit(DIR_IMGUI, COMMIT_IMGUI, "Dear ImGui")


proc versionSdl3(): string =
  ## Read version `pkg-config` reports for SDL3, workspace prefix first; empty where none.
  ##   `pkg-config` rather than header read: SDL3 installs its own `.pc`, and that is where
  ##   version it was built as is stated rather than inferred.
  ##   Prefix leads search path so build this drove wins over one machine happens to carry.
  ##   Machine already carrying pinned version is served by it, which is what keeps `sdl3`
  ##   from rebuilding what contributor installed.
  let path_config = getCurrentDir() / DIR_SDL3_PREFIX / "lib" / "pkgconfig"
  let (written, code) = execCmdEx(
    "PKG_CONFIG_PATH=" & quoteShell(path_config) & ":$PKG_CONFIG_PATH pkg-config --modversion sdl3"
  )
  if code != 0: "" else: written.strip


proc sdl3() =
  ## Build SDL3 at pinned tag into `build/`, unless machine already reports that version.
  ##   No package carries it (see `VERSION_SDL3`), so this is how machine gets one, and verb
  ##   fetching what it compiles is same rule `assets` follows for faces.
  ##   Installs into tree rather than over `/usr/local`: build needing root is build CI cannot
  ##   run unattended without granting it, and prefix under `build/` is removed by `clean`
  ##   like any other product. Cost is `-rpath` below, since loader would not find library
  ##   there otherwise.
  ##   `--depth 1` is safe here where it is not for Dear ImGui: commit pinned is one tag
  ##   names, which is exactly what shallow clone fetches, while Dear ImGui's sits behind
  ##   branch head where no shallow clone reaches it.
  ##   Costs nothing warm: already-built prefix reports pinned version and is left alone.
  let got = versionSdl3()
  if got == VERSION_SDL3:
    echo "Kept SDL3 ", VERSION_SDL3, ", already reported by pkg-config"
    return
  if not dirExists(DIR_SDL3):
    run("git", [
      "clone", "--depth", "1", "--branch", "release-" & VERSION_SDL3, URL_SDL3, DIR_SDL3,
    ])
  # Held before cmake rather than after: build is minutes, and sources this refuses are
  #   sources none of those minutes should be spent on.
  checkCommit(DIR_SDL3, COMMIT_SDL3, "SDL3")
  run("cmake", ["-S", DIR_SDL3, "-B", DIR_SDL3_BUILD, "-DCMAKE_BUILD_TYPE=Release"])
  run("cmake", ["--build", DIR_SDL3_BUILD, "-j", $countProcessors()])
  run("cmake", ["--install", DIR_SDL3_BUILD, "--prefix", getCurrentDir() / DIR_SDL3_PREFIX])
  echo "Built SDL3 ", VERSION_SDL3, " into ", DIR_SDL3_PREFIX


proc checkSdl3() =
  ## Raise unless SDL3 this build reaches reports version pinned for it, and unless clone it
  ## was built from stands at commit pinned for it.
  ##   Runs after `sdl3`, so it reads what that built or what machine already carried, and
  ##   refuses either where version misses -- wrong SDL3 is wrong binary, for reason
  ##   `checkImgui` gives about wrong commit.
  ##   Commit is read here as well as in `sdl3`, so warm tree is held too: `sdl3` returns on
  ##   version alone where prefix already reports it, and clone it once built from is then
  ##   never looked at again.
  ##   Machine carrying its own SDL3 has no clone to read, and version is all there is of it.
  ##   That is limit of this check rather than case it waves through, and it says aloud which
  ##   of two it held.
  let got = versionSdl3()
  if got.len == 0:
    raise newException(OSError,
      "No SDL3 found by `pkg-config`, and `sdl3` did not build one; needs `cmake`, `git` and " &
      "network, all of which `system` declares.")
  if got != VERSION_SDL3:
    raise newException(OSError,
      "SDL3 is not version pinned for it; wanted `" & VERSION_SDL3 & "`, got `" & got & "`.")
  if not dirExists(DIR_SDL3):
    echo "Kept SDL3 ", VERSION_SDL3, " from machine; no clone here to read commit of"
    return
  checkCommit(DIR_SDL3, COMMIT_SDL3, "SDL3")


proc desktop() =
  ## Compile desktop front-end into `bin/`, through backend Dear ImGui needs.
  ##   `cpp` rather than `c`: shim over Dear ImGui is C++, for reason its own header gives.
  ##   Flags live here rather than in `.nim.cfg` beside entry point: this driver owns every
  ##   compiler invocation, so reader finds them where builds are run rather than in file
  ##   they must know to look for. Algebra and library path stay in `nim.cfg`, since every
  ##   target, test and front-end wants same two.
  ##   Library flags (`-lSDL3`, `-lGL`, `-lz`) stay in modules needing them, so test binary
  ##   importing one links without repeating anything here.
  ##   Where `sdl3` built into tree, header, library and run-time paths are added here rather
  ##   than in those modules: which prefix holds SDL3 is this build's answer and changes with
  ##   checkout, while `-lSDL3` is module's and does not.
  ##   `-rpath` is absolute and derived, never written down: loader takes no relative path it
  ##   can trust, and committing one machine's layout is what CONTRIBUTOR.md forbids. Binary is
  ##   build product beside prefix it names, so pair moves or is rebuilt together.
  ##   No `-d:release`, unlike `web`: this binary is driven and read rather than shipped, and
  ##   every check it carries is `--drive-*` run reporting through assertions release removes.
  sdl3()
  checkSdl3()
  imgui()
  checkImgui()
  createDir BIN
  var args = @["cpp", "--hints:off", "-o:" & PATH_DESKTOP_BIN]
  if dirExists(DIR_SDL3_PREFIX):
    let prefix = getCurrentDir() / DIR_SDL3_PREFIX
    args.add "--passC:-I" & prefix / "include"
    args.add "--passL:-L" & prefix / "lib"
    args.add "--passL:-Wl,-rpath," & prefix / "lib"
  args.add PATH_DESKTOP_NIM
  run("nim", args)
  echo "Wrote ", PATH_DESKTOP_BIN, "."


proc under(args: openArray[string]): (string, seq[string]) =
  ## Name command and arguments that run desktop binary, borrowing display where none is set.
  ##   Checks are headless by nature, and machine running them may have no screen at all.
  ##   `xvfb-run -a` picks free display number rather than colliding with one in use.
  if getEnv("DISPLAY").len > 0: (PATH_DESKTOP_BIN, @args)
  else: ("xvfb-run", @["-a", PATH_DESKTOP_BIN] & @args)


proc reported(args: openArray[string]): bool =
  ## Run desktop binary with args, streaming what it says; report whether it passed.
  ##   Does not raise on failure, unlike `run`: caller drives every scripted run and reports
  ##   all of them, and first failure must not hide rest.
  let (command, arguments) = under(args)
  let process = startProcess(command, args = arguments, options = {poUsePath, poParentStreams})
  let code = process.waitForExit
  process.close
  code == 0


proc tabsHelp(): seq[string] =
  ## Ask binary which help tabs it has, one per line.
  let (command, arguments) = under(["--help-tabs"])
  let (written, code) = execCmdEx(command & " " & arguments.quoteShellCommand)
  if code != 0:
    raise newException(OSError, "Cannot read help tabs; got exit `" & $code & "`.")
  for line in written.splitLines:
    if line.strip.len > 0: result.add line.strip


proc driven() =
  ## Drive desktop front-end through every scripted run, and report every check each runs.
  ##   Builds first, for reason `drive` does: checks against stale binary check build nobody
  ##   has.
  ##   Runs every scripted mode rather than one, since each drives different wiring and no
  ##   caller should have to know list. Help is driven once per tab binary reports.
  ##   Exit follows checks: non-zero where any failed, so one command is whole answer.
  ##   Every failure is reported before exit rather than first one raising: run takes seconds,
  ##   and knowing which three broke beats knowing that one did.
  ##   Fetches faces first, for reason `drive` does: front-end draws in faces this project
  ##   ships, and run against absent one checks nothing anybody would ship.
  assets()
  desktop()
  var failed: seq[string]
  for drive in DRIVES:
    echo "== --drive-", drive
    if not reported(["--hidden", "--drive-" & drive]): failed.add "drive-" & drive
  for tab in tabsHelp():
    echo "== --drive-help:", tab
    if not reported(["--hidden", "--drive-help:" & tab]): failed.add "drive-help:" & tab
  # Scene at capacity, driven once, since panel's own layout is what fills first.
  #   `--fill` tops scene up before first frame, so list is longest this build can hold and
  #   verdict about what fits under it has run to fire in. Keys drive is carrier: it asks
  #   nothing of list, so anything it reports about one is layout's doing rather than its.
  echo "== --drive-keys, with the scene filled to capacity"
  if not reported(["--hidden", "--fill", "--drive-keys"]): failed.add "drive-keys filled"

  # Machine carrying no face, driven once, since that is machine this had never been run on.
  #   `RGA_FONT` names path no machine has rather than one this machine happens to lack, so
  #   run asks same question everywhere. Interface face alone is hidden: it is one Dear ImGui
  #   asserted on, and other three are reached through same code.
  echo "== --drive-keys, with no face to load"
  putEnv(ENV_FONT, PATH_FONT_ABSENT)
  if not reported(["--hidden", "--drive-keys"]): failed.add "drive-keys without face"
  delEnv(ENV_FONT)
  if failed.len > 0:
    raise newException(OSError,
      "Driven runs failed; got " & $failed.len & " -- " & failed.join(", ") & ".")
  echo "\nEvery scripted run passed."


proc drive() =
  ## Drive assembled page through real events, and report every check it runs.
  ##   Builds page first: harness against stale page checks build nobody has, and `web`
  ##   runs `types`, which type-checks this harness too.
  ##   Exit follows harness: non-zero where any check failed, so one command is whole answer.
  ##   Fetches faces first, so verb satisfies its own precondition rather than assuming someone
  ##   ran `assets` by hand. Cold checkout is where that assumption showed: runner builds every
  ##   step and stops at embedding, which is one line to prevent (repository issue 47).
  ##   `web` keeps refusing absent face by name instead, since caller reaching for it directly
  ##   is asking to build page rather than to be given one.
  ##   Fetches browser for same reason it fetches faces: harness drives Playwright's own
  ##   pinned build by default, and nothing else on machine installs it.
  ##   Costs nothing warm: `assets` skips every face already carrying its pinned digest, and
  ##   `browser` skips build already at pinned revision.
  ##   Drives desktop front-end too, and no longer conditionally: both front-ends draw same
  ##   scene from same core, and check that runs on one machine alone is check nobody runs.
  ##   `driven` alone drives desktop by itself.
  ##   Skip is gone, and that is repository issue 91 ruled: `0 finding(s)` over 156 checks and
  ##   over 138 were two claims wearing one sentence, which rule that check gives same verdict
  ##   on same code forbids. Absent dependency now fails by name instead, and `desktop` fetches
  ##   every one this project can fetch, so failing means machine lacks what `system` declares.
  assets()
  web()
  browser()
  run("node", [BUILD / "drive" / "main.js"])
  driven()

proc clean() =
  ## Remove every product, leaving only what git holds.
  for dir in [BUILD, BIN, "nimcache"]:
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
    of "types": types()
    of "web": web()
    of "drive": drive()
    of "desktop": desktop()
    of "driven": driven()
    of "assets": assets()
    of "system": system()
    of "clean": clean()
    else:
      stderr.write USAGE
      quit 2
  except CatchableError as e:
    stderr.write e.msg & "\n"
    quit 1
