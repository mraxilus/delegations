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
##   |          | pictures, build four mark pages, sweep turns natively, splice         |
##   |          | whole-cloth page                                                      |
##   | assets   | fetch faces pages embed from repository store into build/fonts        |
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
  USAGE = "Usage: nim r tools/build.nim <pages|assets|verdicts|shot|clean>\n"
    ## Text printed on usage error.


proc nim(args: openArray[string]) =
  ## Run compiler with args from project directory; raise on non-zero exit.
  let process = startProcess("nim", args = args, options = {poUsePath, poParentStreams})
  let code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, "nim failed; got exit `" & $code & "`.")

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
  for dir in ["app", "sim", "review", "design"]: createDir(BUILD / dir)
  compileRun(["tools/pages.nim", BUILD])
  nim(@["js"] & RELEASE & @["-o:" & BUILD / "app" / "app.js", "app/app.nim"])
  nim(@["js"] & RELEASE & @["-o:" & BUILD / "sim" / "sim.js", "sim/page.nim"])
  compileRun(["tools/bundle.nim", BUILD / "app", "app"])
  compileRun(["tools/bundle.nim", BUILD / "sim", "sim"])
  compileRun(["tools/review.nim", BUILD / "review"])
  compileRun(["design/marks.nim", BUILD / "design"])
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BIN, "design/turns.nim"])
  nim(@["js"] & RELEASE & @[
    "-o:" & BUILD / "design" / "wholecloth_turns.js", "design/wholecloth_turns.nim",
  ])
  compileRun(["design/wholecloth.nim", BUILD / "design"])
  dress()


proc verdicts() =
  ## Rewrite `sim/verdicts.md` from model; instrument run, not build.
  nim(@["c", "-r"] & DANGER & @["--outdir:" & BIN, "sim/verdicts.nim"])


proc shot() =
  ## Build screenshot helper, for node and Playwright.
  createDir(BUILD / "design")
  nim(@["js"] & QUIET & @[
    "-d:nodejs", "-o:" & BUILD / "design" / "shot.js", "design/shot.nim",
  ])


proc clean() =
  ## Remove build products, caches and testament binaries.
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
    of "verdicts": verdicts()
    of "shot": shot()
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
