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

import std/[os, osproc, strutils]


const
  BUILD = "build"
    ## Directory every product lands in.
  BIN = "bin"
    ## Directory compiled binaries land in.
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
    ##   `git clone --branch` resolves, at commit `f5e5f658`. That series releases on even patch
    ##   numbers alone, so odd one names no tag and no bytes -- which is what 3.2.31 did, and
    ##   what repository issue 90 was.
    ##   Built from source rather than installed: Ubuntu 24.04 packages SDL2 alone, and
    ##   `apt-get install libsdl3-dev` fails on it outright. Distributions carrying package
    ##   exist, but build cannot depend on which one runs it.
    ##   Pinned exactly rather than as floor: this is what desktop front-end was compiled and
    ##   drawn against, and floor would claim reach across releases nothing here has tried.
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
    ("commit-mono-latin-400-normal.woff2",
      "86132abb57fc615f2ab900cde4cd9d5796e9791daf1f85d79fc933aa50b3b15c"),
    ("noto-sans-latin-400-normal.woff2",
      "09aee8065d25508f23a4c3d92cd777ac869c52d93fd868a88f025d888a7937d6"),
    ("noto-sans-latin-600-normal.woff2",
      "79e274470d1c5a0118eb325e2ea6f2eb2a449336d7fde1a4f20a2f32fe1119ed"),
    ("noto-sans-math-math-400-normal.woff2",
      "90b9ddbed280e379e1af4601eb1d53eee8dd467b4c9174e5fd2d7347fe180d30"),
    ("noto-sans-symbols-2-symbols-400-normal.woff2",
      "9c07d511848c274b5430c75bf98d1f2582680ef5f967947bfbdd06b75ca177c2"),
    ("noto-serif-latin-400-normal.woff2",
      "4c0cbe3eec50d260754d681c17ee2af49a43d7fd93ce42877f665fcb1a889b87"),
  ]
    ## Faces page embeds, each with digest of bytes expected, all SIL Open Font License 1.1;
    ##   origins in PROVENANCE.md.
    ##   Digest is pin: host serves whatever it serves, and page embeds these bytes into
    ##   artefact readers open, so wrong byte here is wrong byte shipped. Repository pins
    ##   compilers to commits and packages to lock files; this is same pin for one fetch that
    ##   had none (repository issue 47).
  SYSTEM = [
    ("curl", "fetch faces `assets` pins; build shells out to it"),
    ("coreutils", "`sha256sum` verifying those pins and `base64` inlining them"),
    ("nodejs", "run type-checker `types` drives and harness `drive` runs"),
    ("git", "clone Dear ImGui and SDL3 at commit and tag `desktop` checks them at"),
    ("cmake", "build SDL3 from source, since no package of it exists on Ubuntu 24.04"),
    ("pkg-config", "read version of that SDL3, which `desktop` checks before compiling"),
    ("fonts-noto-core", "faces desktop front-end loads by path; Dear ImGui aborts on absent one"),
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
    ##   fetched at build time -- see `FACES` and `COMMIT_IMGUI` -- which is what keeps
    ##   unpinned download out of merge process.
    ##   Dear ImGui and SDL3 are absent deliberately: neither arrives as package. Dear ImGui
    ##   is compiled from source into binary, and Ubuntu 24.04 carries no `libsdl3-dev` at all
    ##   -- only SDL2 -- so SDL3 is built and installed from source too. Both are pinned by
    ##   version rather than by package manager; see `COMMIT_IMGUI` and `VERSION_SDL3`.
  HOST_FACES = "https://cdn.jsdelivr.net/npm/@fontsource"
    ## Host `assets` fetches faces from.
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


proc digestOf(path: string): string =
  ## Read file's SHA-256, as `sha256sum` writes it.
  ##   Shelled out rather than computed here, and deliberately: no digest of that strength is
  ##   in reach from Nim. Curator recorded all three routes as rejected on
  ##   `curator/audit/src/provenance.nim` -- `std/sha1` deprecated and warning on every build,
  ##   `checksums` package nimble install in CI for one hash, `std/hashes` unstable across
  ##   compiler versions. `assets` already shells out for `curl` and `web` for `base64`, so
  ##   this adds no dependency either lacked.
  ##   Deriving SHA-256 here rejected outright: crypto primitive is last thing to hand-roll,
  ##   and Article II.8 asks for dependency rather than copy.
  let (written, code) = execCmdEx("sha256sum " & quoteShell(path))
  if code != 0:
    raise newException(OSError, "Cannot read digest of `" & path & "`; got exit `" & $code & "`.")
  written.strip.split(' ')[0]


proc checkFace(face, wanted: string) =
  ## Raise unless face on disk carries digest pinned for it.
  let path = DIR_FONTS / face
  let got = path.digestOf
  if got != wanted:
    raise newException(OSError,
      "Face `" & face & "` is not what is pinned; wanted `" & wanted & "`, got `" & got & "`.")


proc assets() =
  ## Fetch every face page embeds into `build/fonts`, and verify each against its pin.
  ##   Faces are binary, which audit cannot read, so they are never committed and this verb
  ##   is how contributor gets them (CONTRIBUTOR.md, "Pages and assets").
  ##   Face already carrying its pinned digest is left alone: verb is then idempotent, second
  ##   run fetches nothing, and CI keeps faces between runs keyed on that same digest
  ##   (repository issue 47).
  ##   Every mismatch is reported together rather than first one raising: host republishing
  ##   family moves several at once, and one run should name all of them rather than one per
  ##   run.
  createDir DIR_FONTS
  var wrong: seq[string]
  for (face, digest) in FACES:
    if fileExists(DIR_FONTS / face) and (DIR_FONTS / face).digestOf == digest:
      echo "Kept ", face, ", digest already matches"
      continue
    # Family is name less its last three parts, i.e. subset, weight and style.
    let family = face.rsplit('-', 3)[0]
    run("curl", ["-sSLf", "-o", DIR_FONTS / face, HOST_FACES & "/" & family & "/files/" & face])
    let got = (DIR_FONTS / face).digestOf
    if got != digest:
      wrong.add face & ": wanted `" & digest & "`, got `" & got & "`"
    else:
      echo "Fetched ", face, ", digest matches"
  if wrong.len > 0:
    raise newException(OSError,
      "Host served bytes no face is pinned to; got " & $wrong.len & " -- " & wrong.join("; "))
  echo "Wrote ", DIR_FONTS, " (", FACES.len, " faces, every digest matched)."


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
  for (face, digest) in FACES:
    let token = TOKEN_EMBED & face & "@"
    if token notin page: continue
    let path = DIR_FONTS / face
    if not fileExists(path):
      raise newException(OSError, "Missing face `" & path & "`; run `assets` first.")
    # Verified again here, not only where fetched: `assets` may have run long ago, and what
    #   this embeds is what every reader downloads. Wrong byte stops build rather than ships.
    checkFace(face, digest)
    run("bash", ["-c", "base64 -w0 " & quoteShell(path) & " > " & quoteShell(path & ".b64")])
    page = page.replace(token, "data:font/woff2;base64," & readFile(path & ".b64").strip)

  if TOKEN_SCRIPT notin page:
    raise newException(OSError, "Shell carries no `" & TOKEN_SCRIPT & "`; nothing to fill.")
  page = page.replace(TOKEN_SCRIPT, "\n" & scripts & "\n")

  createDir BUILD
  writeFile(PATH_PAGE, page)
  echo "Wrote ", PATH_PAGE, " (", page.len, " bytes)."


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
  let (written, code) = execCmdEx("git -C " & quoteShell(DIR_IMGUI) & " rev-parse HEAD")
  if code != 0:
    raise newException(OSError,
      "Cannot read commit of `" & DIR_IMGUI & "`; got exit `" & $code & "`.")
  let got = written.strip
  if got != COMMIT_IMGUI:
    raise newException(OSError,
      "Dear ImGui is not at commit pinned for it; wanted `" & COMMIT_IMGUI & "`, got `" &
      got & "`.")


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
  ##   `--depth 1` is safe here where it is not for Dear ImGui: pin is tag, and tag is what
  ##   shallow clone fetches.
  ##   Costs nothing warm: already-built prefix reports pinned version and is left alone.
  let got = versionSdl3()
  if got == VERSION_SDL3:
    echo "Kept SDL3 ", VERSION_SDL3, ", already reported by pkg-config"
    return
  if not dirExists(DIR_SDL3):
    run("git", [
      "clone", "--depth", "1", "--branch", "release-" & VERSION_SDL3, URL_SDL3, DIR_SDL3,
    ])
  run("cmake", ["-S", DIR_SDL3, "-B", DIR_SDL3_BUILD, "-DCMAKE_BUILD_TYPE=Release"])
  run("cmake", ["--build", DIR_SDL3_BUILD, "-j", $countProcessors()])
  run("cmake", ["--install", DIR_SDL3_BUILD, "--prefix", getCurrentDir() / DIR_SDL3_PREFIX])
  echo "Built SDL3 ", VERSION_SDL3, " into ", DIR_SDL3_PREFIX


proc checkSdl3() =
  ## Raise unless SDL3 this build reaches reports version pinned for it.
  ##   Runs after `sdl3`, so it reads what that built or what machine already carried, and
  ##   refuses either where version misses -- wrong SDL3 is wrong binary, for reason
  ##   `checkImgui` gives about wrong commit.
  let got = versionSdl3()
  if got.len == 0:
    raise newException(OSError,
      "No SDL3 found by `pkg-config`, and `sdl3` did not build one; needs `cmake`, `git` and " &
      "network, all of which `system` declares.")
  if got != VERSION_SDL3:
    raise newException(OSError,
      "SDL3 is not version pinned for it; wanted `" & VERSION_SDL3 & "`, got `" & got & "`.")


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
  desktop()
  var failed: seq[string]
  for drive in DRIVES:
    echo "== --drive-", drive
    if not reported(["--hidden", "--drive-" & drive]): failed.add "drive-" & drive
  for tab in tabsHelp():
    echo "== --drive-help:", tab
    if not reported(["--hidden", "--drive-help:" & tab]): failed.add "drive-help:" & tab
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
