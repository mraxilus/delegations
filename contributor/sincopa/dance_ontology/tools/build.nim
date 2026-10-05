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
##   |          | pictures, build five mark pages, fold recorded turns into whole-cloth |
##   |          | page, build rig viewer                                                |
##   | assets   | fetch faces pages embed from repository store into build/fonts        |
##   | fixtures | rewrite design/review-fixtures.json from page just built: run when    |
##   |          | Architect rules on cards, never to quiet check that says one moved    |
##   | confirmed| rewrite design/confirmed-fixtures.json from page just built: run when |
##   |          | Architect confirms stills, never to quiet check that says one moved   |
##   | modelled | rewrite design/modelled.json: which reference cards simulation        |
##   |          | reaches, stamped, and only where stamp changed                        |
##   | rig      | rewrite design/rig.json: sweeps rig viewer plays, and every still,    |
##   |          | stamped, and only where stamp changed                                 |
##   | record   | every recording below in one queue, slowest job first, each question  |
##   |          | asked once, each result kept as it comes, so run stopped part way     |
##   |          | goes on where it stopped                                              |
##   | turns    | rewrite design/turns.json: sweeps whole-cloth page plays              |
##   | verdicts | instrument run, not build: answers land in simulation/verdicts.md     |
##   | answers  | rewrite simulation/answers.json: where couple stand for rig's laws,   |
##   |          | stamped                                                               |
##   | shot     | screenshot helper, for node and Playwright                            |
##   | clean    | remove binaries, build, nimcache, testresults and testament binaries  |
##   |----------|-----------------------------------------------------------------------|
##   Tool binaries land in `binaries/`, and pages under `build/`; root `.gitignore` covers both
##     at any depth.
##   Exit: 0 done, 1 command failed, 2 usage error.
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

when compileOption("profiler"): import std/nimprof

import std/[os, osproc, strutils]

import ../design/[faces, review_page]


const
  BUILD = "build"  ## Directory every page, picture and script lands in.
  BINARIES = "binaries"  ## Directory tool binaries land in.
  DANGER = @["-d:danger", "--hints:off"]  ## Options of runs whose speed is point, i.e. sweeps.
  RELEASE = @["-d:release", "--hints:off"]  ## Options of browser scripts shipped with pages.
  QUIET = @["--hints:off"]  ## Options of runs whose output is their product.
  DIRECTORY_FONTS = BUILD / "fonts"
    ## Directory faces land in.  Never committed: fonts are unregistered kind, so
    ##   lock is committed and checkout is not, as Atlas does for packages.
  USAGE = "Usage: nim r tools/build.nim " &
      "<pages|assets|fixtures|confirmed|modelled|rig|record|turns|verdicts|answers|engine|shot|" &
      "system|clean>\n"
    ## Text printed on usage error.
  SYSTEM = [
    ("git", true, "clone engine's source at its pinned commit; `engine` shells out to it"),
    ("binutils", true, "archive engine's objects into one library; `engine` runs `ar`"),
    ("nodejs", false, "run `shot` helper, which is this project's Nim compiled to javascript"),
    ("chromium", false, "browser `shot` drives; helper takes its path from environment"),
  ]
    ## System packages this build needs present before it runs, with what each is for
    ##   (CONTRIBUTOR.md, "System dependencies"). Nim packages are in nimble file; this
    ##   project carries no node manifest, so these have no lock to pin them.
    ##   No version is pinned and none is invented: package's version is whatever machine
    ##   carries, which is honest limit rather than omission.
    ##   Playwright is deliberately absent, and is this declaration's one gap. It is node
    ##   package rather than system one, so no installer reading these names serves it, and
    ##   pinning it would mean `package.json` beside its lock -- which enrols project in
    ##   `koch check-types` and demands `types` verb, work Architect has asked not be built while
    ##   this half of project may go. `design/shot.nim` therefore takes it from environment
    ##   and stops naming this verb where it is absent, rather than failing as missing file.
    ##   Flag says whether runner installs it: it installs what `system` prints, and opens
    ##   nothing else.  `engine` needs first two and C compiler, which Nim brings already and
    ##   so is not named twice, and every suite builds engine.  Last two are `shot`'s, which
    ##   no run of runner opens: project carries no `drive` verb, so driven job skips it and
    ##   helper is one person runs by hand.  Naming them in `SYSTEM` anyway keeps one
    ##   spelling of what each needs (Article II.1), and `shot` prints them where it builds,
    ##   so person running it is told what to install while runner installs no browser it
    ##   never starts.  `pages`, `fixtures`, `confirmed`, `verdicts` and `clean` need Nim
    ##   alone.
  SOURCES = [
    ("box3d", "https://github.com/erincatto/box3d",
     "47d7f7cc7e091142c08d11dc7d2e493c5d34f536",
     "rigid body solver with contacts that slide; pose search this project had could " &
     "not wind chain past half turn without arms passing through each other",
     "MIT"),
  ]
    ## Source clones no package manager carries, each pinned by its commit, which is what
    ##   stands where checksum stands for fetched file (CONTRIBUTOR.md, "System
    ##   dependencies"). Never vendored: root `.gitignore` ignores `dependencies/`,
    ##   and `engine` clones there.
  DIRECTORY_DEPENDENCIES = "dependencies"
    ## Directory source clones land in. Never committed, as Atlas checkouts are not.
  ENGINE_LIBRARY = BINARIES / "libbox3d.a"
    ## Engine archived into one library, which `simulation/engine.nim` links.


proc run(program: string, arguments: openArray[string]) =
  ## Run program with args from project directory; raise on non-zero exit.
  ##   Named rather than shelled through string, so no argument needs quoting and no
  ##     path with space in it can split.
  let
    process = startProcess(program, args = arguments, options = {poUsePath, poParentStreams})
    code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, program & " failed; got exit `" & $code & "`.")

proc nim(arguments: openArray[string]) =
  ## Run compiler with args from project directory; raise on non-zero exit.
  run("nim", arguments)

proc compileRun(arguments: openArray[string]) =
  ## Compile and run program with args, quietly, binary into `binaries/`.
  nim(@["c", "-r"] & QUIET & @["--outdir:" & BINARIES] & @arguments)



#[ Commands ]#

proc rootOf(): string =
  ## Read repository root, which is nearest directory above holding koch.
  ##   Walked rather than counted from project depth, so path holds if project moves.
  result = getCurrentDir()
  while not fileExists(result / "koch.nim"):
    let above = result.parentDir
    if above == result:
      raise newException(
        OSError,
        "No repository root above project, so shared store cannot be reached; got `" &
        getCurrentDir() & "`.",
      )
    result = above


proc assets() =
  ## Fetch faces pages embed from repository's shared store into `build/fonts`.
  ##   Digests are curator's and choice is this project's (repository issue 116): store
  ##     says what bytes each face is, `design/faces.nim` says which faces are drawn with,
  ##     and neither writes what other holds.
  ##   Store keys entries by digest, so name is restored here: rest of build reads faces
  ##     by name, and page embedding one wants to say which it embedded.
  createDir(DIRECTORY_FONTS)
  var wanted: seq[string]
  for (file, _, _, _) in FACES:
    wanted.add file
  let (written, code) = execCmdEx(
    "nim r --hints:off koch fetch-assets " & wanted.join(" "),
    workingDir = rootOf(),
  )
  if code != 0:
    raise newException(OSError, "Shared store did not serve every face asked for; got:\n" & written)
  var paths: seq[string]
  for line in written.splitLines:
    if line.startsWith('/') and fileExists(line):
      paths.add line
  if paths.len != wanted.len:
    raise newException(
      OSError,
      "Store answered with `" & $paths.len & "` paths for `" & $wanted.len &
      "` faces asked for, so which is which cannot be told; got:\n" & written,
    )
  for i, file in wanted:
    copyFile(paths[i], DIRECTORY_FONTS / file)
  echo "Faces in ", DIRECTORY_FONTS, ": ", wanted.len, ", every one from repository store."


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
    let into = DIRECTORY_DEPENDENCIES / name
    if not dirExists(into):
      createDir(DIRECTORY_DEPENDENCIES)
      run("git", ["clone", "--quiet", url, into])
      run("git", ["-C", into, "checkout", "--quiet", commit])
    let (written, code) = execCmdEx("git -C " & quoteShell(into) & " rev-parse HEAD")
    if code != 0:
      raise newException(OSError, "Cannot read commit of `" & into & "`; got exit `" & $code & "`.")
    let got = written.strip
    if got != commit:
      raise newException(
        OSError,
        "Clone of `" & name & "` stands at `" & got & "`, not pinned `" & commit & "`.",
      )
  if fileExists(ENGINE_LIBRARY):
    echo "Engine already archived: ", ENGINE_LIBRARY
    return
  createDir(BINARIES)
  let src = DIRECTORY_DEPENDENCIES / "box3d" / "src"
  var objects: seq[string]
  for path in walkFiles(src / "*.c"):
    let object_file = BINARIES / path.extractFilename.changeFileExt("o")
    run(
      "cc",
      ["-O2", "-std=c17", "-I" & DIRECTORY_DEPENDENCIES / "box3d" / "include", "-I" & src,
                 "-c", path, "-o", object_file],
    )
    objects.add object_file
  if objects.len == 0:
    raise newException(OSError, "Engine's source holds no `.c` file; got `" & src & "`.")
  run("ar", @["rcs", ENGINE_LIBRARY] & objects)
  for object_file in objects:
    removeFile(object_file)
  echo "Engine archived: ", ENGINE_LIBRARY, ", from ", objects.len, " files."


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


proc turnsJs() =
  ## Fold recorded sweeps into script whole-cloth page reads.
  ##   Recording is `turns` verb's, as `modelled` and `rig` are theirs: eighteen
  ##     sweeps searching every distance couple may stand at cost more than
  ##     every `pages` run should pay.
  let data = "design" / "turns.json"
  if not fileExists(data):
    quit(
      "Whole-cloth page has no sweeps; run `nim r tools/build.nim turns`: got `" & data & "`.",
      1,
    )
  writeFile(BUILD / "design" / "turns.js", "var TURNS = " & readFile(data).strip() & ";\n")
  echo "wrote " & BUILD / "design" / "turns.js"

proc turns() =
  ## Rewrite `design/turns.json`: every hold turning, for whole-cloth page.
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BINARIES, "design/record.nim", "turns"])

proc pages() =
  ## Write every page, picture and script under `build/`.
  ##   Faces first: every page embeds them, and check that wants verb run by hand
  ##     first is check runner will not run.
  assets()
  for directory in ["app", "review", "design"]: createDir(BUILD / directory)
  compileRun(["tools/pages.nim", BUILD])
  nim(@["js"] & RELEASE & @["-o:" & BUILD / "app" / "app.js", "app/app.nim"])
  compileRun(["tools/bundle.nim", BUILD / "app", "app"])
  compileRun(["tools/review.nim", BUILD / "review"])
  compileRun(["design/marks.nim", BUILD / "design"])
  turnsJs()
  nim(
    @["js"] & RELEASE & @[
      "-o:" & BUILD / "design" / "wholecloth_turns.js", "design/wholecloth_turns.nim",
    ],
  )
  compileRun(["design/wholecloth.nim", BUILD / "design"])
  nim(
    @["js"] & RELEASE & @[
      "-o:" & BUILD / "design" / "rig_view.js", "design/rig_view.nim",
    ],
  )
  compileRun(["design/rig_page.nim", BUILD / "design"])
  dress()


proc fixtures() =
  ## Write what every ruled card is drawn as now into `design/review-fixtures.json`.
  ##   Second step on purpose.  Ruling and fixture are added together or not at
  ##     all: running this to quiet check that says ruled card moved would
  ##     hand approval to picture nobody approved.
  let page = BUILD / "design" / "review.html"
  if not fileExists(page):
    quit("No review page to read; run `pages` first.", 1)
  writeFile("design/review-fixtures.json", fixturesIn(readFile(page)))
  echo "wrote design/review-fixtures.json"


proc confirmed() =
  ## Write which still every confirmed card stands for into `design/confirmed-fixtures.json`.
  ##   Second step, as `fixtures` is, and for like reason: confirmation and fixture are
  ##     added together, so build that says confirmed still moved is never quieted by
  ##     running this alone.
  let page = BUILD / "design" / "review.html"
  if not fileExists(page):
    quit("No review page to read; run `pages` first.", 1)
  writeFile("design/confirmed-fixtures.json", confirmedIn(readFile(page)))
  echo "wrote design/confirmed-fixtures.json"


proc modelled() =
  ## Rewrite `design/modelled.json`: which cards simulation reaches.
  ##   Second step, as `fixtures` is, and for like reason: badge saying model agrees
  ##     is claim, and it is added deliberately rather than refreshed by build
  ##     into agreeing with whatever model happens to say today.
  ##   Verb asks nothing again where its stamp is unchanged (`design/stamps`).
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BINARIES, "design/record.nim", "modelled"])


proc rig() =
  ## Rewrite `design/rig.json`: sweeps viewer page plays, and every still it lays
  ## beside reference.
  ##   Own verb, as `modelled` is, and for like reason: recording costs eight
  ##     stance searches over every distance couple may stand at, and every
  ##     `pages` run would pay for it.  Page folds in whatever was last recorded.
  ##   Verb records nothing again where its stamp is unchanged (`design/stamps`).
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BINARIES, "design/record.nim", "rig"])


proc record() =
  ## Rewrite every recording from one queue (`design/record`): answers, turns, report, rig
  ## and modelled.
  ##   One pool for all, slowest job first: four workers end near same time, where verbs one
  ##     after other leave cores idle.  One run asks each question once, and every job that
  ##     asks it again reads answer kept (`walk.keepAnswers`).  Each result is kept as it
  ##     comes, so run stopped part way asks only what is left.
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BINARIES, "design/record.nim"])


proc verdicts() =
  ## Rewrite `simulation/verdicts.md` from model; instrument run, not build.
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BINARIES, "design/record.nim", "verdicts"])


proc answers() =
  ## Rewrite `simulation/answers.json`: every search rig's laws read, and stamp of simulation that
  ## answered them.
  ##   Own verb, as `rig` is, and for like reason: searches cost minutes, and suite
  ##     that read them from here would otherwise pay for them on every run.  Run
  ##     whenever any `simulation/*.nim` changes, since law refuses answers whose stamp is
  ##     not that of tree.
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BINARIES, "design/record.nim", "answers"])


func helpers(): seq[string] =
  ## Packages only hand-run helper needs, which runner is never asked to install.
  for (package, is_installed, _) in SYSTEM:
    if not is_installed: result.add package


proc shot() =
  ## Build screenshot helper, for node and Playwright.
  ##   Says what helper needs before building it: these are packages runner never installs,
  ##   since it never opens them, so person running this is only reader told.
  echo "`shot` is run by hand and needs: ", helpers().join(", ")
  createDir(BUILD / "design")
  nim(
    @["js"] & QUIET & @[
      "-d:nodejs", "-o:" & BUILD / "design" / "shot.js", "design/shot.nim",
    ],
  )


proc system() =
  ## Print every system package runner must install before this build runs, one per line
  ## and nothing else.
  ##   Prints rather than installs: which package manager serves them is machine's business
  ##   and varies by distribution, while list is this project's. Caller pipes it, so reason
  ##   each carries stays in `SYSTEM` above and out of this output, which is what makes
  ##   output machine-readable.
  for (package, is_installed, _) in SYSTEM:
    if is_installed: echo package


proc clean() =
  ## Remove build products, caches and testament binaries.
  # `dependencies/` survives clean, as Atlas checkouts do: it is fetched source, not product.
  for directory in [BINARIES, BUILD, "nimcache", "testresults"]: removeDir(directory)
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
    of "fixtures": fixtures()
    of "confirmed": confirmed()
    of "modelled": modelled()
    of "rig": rig()
    of "record": record()
    of "turns": turns()
    of "verdicts": verdicts()
    of "answers": answers()
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
