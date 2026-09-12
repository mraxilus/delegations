## Build every page, picture and script of this project: `nim r tools/build.nim <command>`.
##   Repository drives tests through koch, which holds no verb for this project's pages, so
##   project carries its own compiled driver, same pattern one level down (Article IX.6).
##   Translation of retired Makefile, recipe for recipe: same programs, same arguments, same
##   order. Rejected: make (retired with its recipe tabs), nimble tasks (compiler VM, second
##   runner), extending koch (verbs of one project do not belong to every project).
##
##   |----------|-----------------------------------------------------------------------|
##   | Command  | Effect                                                                |
##   |----------|-----------------------------------------------------------------------|
##   | pages    | fetch faces, write shells from Nim hosts, compile browser scripts,    |
##   |          | fold each into one self-contained file, render review page and frame  |
##   |          | pictures, build five mark pages, sweep turns natively, splice         |
##   |          | whole-cloth page                                                      |
##   | assets   | fetch faces pages embed from repository store into build/fonts        |
##   | pins     | rewrite design/review-pins.json from page just built: run when        |
##   |          | Architect rules on cards, never to quiet check that says one moved    |
##   | verdicts | instrument run, not build: answers land in sim/verdicts.md            |
##   | shot     | screenshot helper, for node and Playwright                            |
##   | clean    | remove bin, build, nimcache, testresults and testament binaries       |
##   |----------|-----------------------------------------------------------------------|
##   Tool binaries land in `bin/`, pages under `build/`; root `.gitignore` covers both at
##     any depth. Exit: 0 done, 1 command failed, 2 usage error.
##
##   Faces are fetched by repository's shared store rather than by this driver, since two
##     projects pinned four of same files byte for byte before it existed (repository issue
##     116).  Store holds digest and address; this project holds which faces it draws with,
##     in `design/faces.nim`.  So `assets` names files and koch answers with their paths.
##   Cost: driver runs from project directory, since every path here is relative to it.
##   Cost: `assets` shells out to koch, so it needs repository above project rather than
##     project alone; `rootOf` says how that is found and why.
##   Cost: `shot` needs node for its output to run; build itself needs only Nim.

{.experimental: "strictFuncs".}

import std/[os, osproc, strutils]

import ../design/faces
import ../design/review_page


const
  BUILD = "build"
    ## Directory every page, picture and script lands in.
  BIN = "bin"
    ## Directory tool binaries land in.
  DANGER = @["-d:danger", "--hints:off"]
    ## Options of runs whose speed is point, i.e. sweeps.
  RELEASE = @["-d:release", "--hints:off"]
    ## Options of browser scripts shipped with pages.
  QUIET = @["--hints:off"]
    ## Options of runs whose output is their product.
  DIR_FONTS = BUILD / "fonts"
    ## Directory faces land in.  Never committed: fonts are unregistered kind, so
    ##   lock is committed and checkout is not, as Atlas does for packages.
  USAGE = "Usage: nim r tools/build.nim " &
    "<pages|assets|pins|modelled|verdicts|engine|shot|system|clean>\n"
    ## Text printed on usage error.
  SYSTEM = [
    ("nodejs", "run `shot` helper, which is this project's Nim compiled to javascript"),
    ("chromium", "browser `shot` drives; helper takes its path from environment"),
    ("git", "clone engine's source at its pinned commit; `engine` shells out to it"),
    ("binutils", "archive engine's objects into one library; `engine` runs `ar`"),
  ]
    ## System packages this build needs present before it runs, with what each is for
    ##   (CONTRIBUTOR.md, "System dependencies"). Nim packages are in nimble file; this
    ##   project carries no node manifest, so these have no lock to pin them.
    ##   No version is pinned and none is invented: package's version is whatever machine
    ##   carries, which is honest limit rather than omission.
    ##   Playwright is deliberately absent, and is this declaration's one gap. It is node
    ##   package rather than system one, so no installer reading these names serves it, and
    ##   pinning it would mean `package.json` beside its lock -- which enrols project in
    ##   `koch types` and demands `types` verb, work Architect has asked not be built while
    ##   this half of project may go. `design/shot.nim` therefore takes it from environment
    ##   and stops naming this verb where it is absent, rather than failing as missing file.
    ##   Only `shot` needs first two; `engine` needs last two and C compiler, which Nim
    ##   brings already and so is not named twice. `pages`, `pins`, `verdicts` and `clean`
    ##   need Nim alone.
  SOURCES = [
    ("box3d", "https://github.com/erincatto/box3d",
     "47d7f7cc7e091142c08d11dc7d2e493c5d34f536",
     "rigid body solver with contacts that slide; pose search this project had could " &
       "not wind chain past half turn without arms passing through each other",
     "MIT"),
  ]
    ## Source clones no package manager carries, each pinned by its commit, which is what
    ##   stands where checksum stands for fetched file (CONTRIBUTOR.md, "System
    ##   dependencies"). Never vendored: `deps/` is ignored at repository root, and
    ##   `engine` clones there.
  DIR_DEPS = "deps"
    ## Directory source clones land in. Never committed, as Atlas checkouts are not.
  ENGINE_LIB = BIN / "libbox3d.a"
    ## Engine archived into one library, which `sim/engine.nim` links.


proc run(program: string; args: openArray[string]) =
  ## Run program with args from project directory; raise on non-zero exit.
  ##   Named rather than shelled through string, so no argument needs quoting and no
  ##     path with space in it can split.
  let process = startProcess(program, args = args, options = {poUsePath, poParentStreams})
  let code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, program & " failed; got exit `" & $code & "`.")

proc nim(args: openArray[string]) =
  ## Run compiler with args from project directory; raise on non-zero exit.
  run("nim", args)

proc compileRun(args: openArray[string]) =
  ## Compile and run program with args, quietly, binary into `bin/`.
  nim(@["c", "-r"] & QUIET & @["--outdir:" & BIN] & @args)



#[ Commands ]#

proc rootOf(): string =
  ## Read repository root, which is nearest directory above holding koch.
  ##   Walked rather than counted from project depth, so path holds if project moves.
  result = getCurrentDir()
  while not fileExists(result / "koch.nim"):
    let above = result.parentDir
    if above == result:
      raise newException(OSError,
        "No repository root above project, so shared store cannot be reached; got `" &
          getCurrentDir() & "`.")
    result = above


proc assets() =
  ## Fetch faces pages embed from repository's shared store into `build/fonts`.
  ##   Digests are curator's and choice is this project's (repository issue 116): store
  ##     says what bytes each face is, `design/faces.nim` says which faces are drawn with,
  ##     and neither writes what other holds.
  ##   Store keys entries by digest, so name is restored here: rest of build reads faces
  ##     by name, and page embedding one wants to say which it embedded.
  createDir(DIR_FONTS)
  var wanted: seq[string]
  for (file, _, _, _) in FACES:
    wanted.add file
  let (written, code) = execCmdEx(
    "nim r --hints:off koch assets " & wanted.join(" "), workingDir = rootOf())
  if code != 0:
    raise newException(OSError,
      "Shared store did not serve every face asked for; got:\n" & written)
  var paths: seq[string]
  for line in written.splitLines:
    if line.startsWith('/') and fileExists(line):
      paths.add line
  if paths.len != wanted.len:
    raise newException(OSError,
      "Store answered with `" & $paths.len & "` paths for `" & $wanted.len &
        "` faces asked for, so which is which cannot be told; got:\n" & written)
  for i, file in wanted:
    copyFile(paths[i], DIR_FONTS / file)
  echo "Faces in ", DIR_FONTS, ": ", wanted.len, ", every one from repository store."


proc engine() =
  ## Clone engine at its pinned commit and archive it into one library.
  ##   Built by C compiler and `ar` rather than by engine's own CMake: CMake would be
  ##     third build driver in one project, where registry admits no second, and nothing
  ##     in library's fifty files needs generating. Cost: build flags are this file's
  ##     rather than upstream's, and `-O2 -std=c17` is what upstream's release build sets.
  ##   Rebuilt only where library is absent, since fifty files cost twenty seconds.
  ##   Cloned whole rather than shallow at ref, which `rga_visualiser` must do for SDL3 and
  ##     keeps tag beside commit for: engine's history is 41 commits and 4.6 MB, so whole
  ##     clone costs nothing and reaches any commit without ref to fetch. Pin is therefore
  ##     commit alone, with no tag beside it, and that is measurement rather than taste.
  for (name, url, commit, _, _) in SOURCES:
    let into = DIR_DEPS / name
    if not dirExists(into):
      createDir(DIR_DEPS)
      run("git", ["clone", "--quiet", url, into])
      run("git", ["-C", into, "checkout", "--quiet", commit])
    let (written, code) = execCmdEx("git -C " & quoteShell(into) & " rev-parse HEAD")
    if code != 0:
      raise newException(OSError,
        "Cannot read commit of `" & into & "`; got exit `" & $code & "`.")
    let got = written.strip
    if got != commit:
      raise newException(OSError,
        "Clone of `" & name & "` stands at `" & got & "`, not pinned `" & commit & "`.")
  if fileExists(ENGINE_LIB):
    echo "Engine already archived: ", ENGINE_LIB
    return
  createDir(BIN)
  let src = DIR_DEPS / "box3d" / "src"
  var objects: seq[string]
  for path in walkFiles(src / "*.c"):
    let obj = BIN / path.extractFilename.changeFileExt("o")
    run("cc", ["-O2", "-std=c17", "-I" & DIR_DEPS / "box3d" / "include", "-I" & src,
               "-c", path, "-o", obj])
    objects.add obj
  if objects.len == 0:
    raise newException(OSError, "Engine's source holds no `.c` file; got `" & src & "`.")
  run("ar", @["rcs", ENGINE_LIB] & objects)
  for obj in objects:
    removeFile(obj)
  echo "Engine archived: ", ENGINE_LIB, ", from ", objects.len, " files."


proc dress() =
  ## Put faces into every page build wrote, once every writer has run.
  ##   Done here rather than in each writer so that suites which write page need
  ##     neither network nor fetched byte: page they write is evidence about markup,
  ##     and page shipped is what has to carry its faces (Article X.8).
  var dressed = 0
  for path in walkDirRec(BUILD):
    if not path.endsWith(".html"):
      continue
    writeFile(path, withFaces(readFile(path)))
    inc dressed
  echo "Faces put into ", dressed, " pages."


proc pages() =
  ## Write every page, picture and script under `build/`.
  ##   Faces first: every page embeds them, and check that wants verb run by hand
  ##     first is check runner will not run.
  assets()
  for dir in ["app", "review", "design"]: createDir(BUILD / dir)
  compileRun(["tools/pages.nim", BUILD])
  nim(@["js"] & RELEASE & @["-o:" & BUILD / "app" / "app.js", "app/app.nim"])
  compileRun(["tools/bundle.nim", BUILD / "app", "app"])
  compileRun(["tools/review.nim", BUILD / "review"])
  compileRun(["design/marks.nim", BUILD / "design"])
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BIN, "design/turns.nim"])
  nim(@["js"] & RELEASE & @[
    "-o:" & BUILD / "design" / "wholecloth_turns.js", "design/wholecloth_turns.nim",
  ])
  compileRun(["design/wholecloth.nim", BUILD / "design"])
  dress()


proc pins() =
  ## Write what every ruled card is drawn as now into `design/review-pins.json`.
  ##   Second step on purpose.  Verdict and pin are added together or not at
  ##     all: running this to quiet check that says ruled card moved would
  ##     hand approval to picture nobody approved.
  let page = BUILD / "design" / "review.html"
  if not fileExists(page):
    quit("No review page to read; run `pages` first.", 1)
  writeFile("design/review-pins.json", pinsIn(readFile(page)))
  echo "wrote design/review-pins.json"


proc modelled() =
  ## Rewrite `design/modelled.json`: which cards sim reaches.
  ##   Second step, as `pins` is, and for like reason: tag saying model agrees
  ##     is claim, and it is added deliberately rather than refreshed by build
  ##     into agreeing with whatever model happens to say today.
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BIN, "design/modelled.nim"])


proc verdicts() =
  ## Rewrite `sim/verdicts.md` from model; instrument run, not build.
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BIN, "sim/verdicts.nim"])


proc shot() =
  ## Build screenshot helper, for node and Playwright.
  createDir(BUILD / "design")
  nim(@["js"] & QUIET & @[
    "-d:nodejs", "-o:" & BUILD / "design" / "shot.js", "design/shot.nim",
  ])


proc system() =
  ## Print every system package this build needs, one per line and nothing else.
  ##   Prints rather than installs: which package manager serves them is machine's business
  ##   and varies by distribution, while list is this project's. Caller pipes it, so reason
  ##   each carries stays in `SYSTEM` above and out of this output, which is what makes
  ##   output machine-readable.
  for (package, _) in SYSTEM: echo package


proc clean() =
  ## Remove build products, caches and testament binaries.
  # `deps/` survives clean, as Atlas checkouts do: it is fetched source, not product.
  for dir in [BIN, BUILD, "nimcache", "testresults"]: removeDir(dir)
  for path in walkFiles("tests" / "*"):
    if not path.endsWith(".nim"): removeFile(path)



#[ Dispatch ]#

proc main(): int =
  ## Run command named by first argument; usage error exits 2.
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  try:
    case paramStr(1)
    of "pages": pages()
    of "assets": assets()
    of "pins": pins()
    of "modelled": modelled()
    of "verdicts": verdicts()
    of "engine": engine()
    of "shot": shot()
    of "system": system()
    of "clean": clean()
    else:
      stderr.write USAGE
      return 2
  except OSError as error:
    stderr.write error.msg & "\n"
    return 1
  0


when isMainModule:
  quit main()
