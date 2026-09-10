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
##   | assets   | fetch faces pages embed into build/fonts, each against its digest     |
##   | system   | print packages this build needs, one per line                         |
##   | verdicts | instrument run, not build: answers land in sim/verdicts.md            |
##   | shot     | screenshot helper, for node and Playwright                            |
##   | clean    | remove bin, build, nimcache, testresults and testament binaries       |
##   |----------|-----------------------------------------------------------------------|
##   Tool binaries land in `bin/`, pages under `build/`; root `.gitignore` covers both at
##     any depth. Exit: 0 done, 1 command failed, 2 usage error.
##
##   Cost: driver runs from project directory, since every path here is relative to it.
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
  HOST_FACES = "https://cdn.jsdelivr.net/npm/@fontsource"
    ## Host faces are fetched from.
  FACES = [
    ("noto-serif-latin-400-normal.woff2", "5.3.0",
      "4c0cbe3eec50d260754d681c17ee2af49a43d7fd93ce42877f665fcb1a889b87"),
    ("noto-serif-latin-600-normal.woff2", "5.3.0",
      "abf0abc765331d7a1bbe6eb3603cf86be1cf3d1edbcf911cc2d52f78998c02d9"),
    ("noto-serif-latin-400-italic.woff2", "5.3.0",
      "a7386f772de25b62a3a449fa5d9f3e09916b65cf6a6dfc52f5a103c276fee157"),
    ("noto-sans-latin-400-normal.woff2", "5.3.0",
      "09aee8065d25508f23a4c3d92cd777ac869c52d93fd868a88f025d888a7937d6"),
    ("noto-sans-latin-600-normal.woff2", "5.3.0",
      "79e274470d1c5a0118eb325e2ea6f2eb2a449336d7fde1a4f20a2f32fe1119ed"),
    ("commit-mono-latin-400-normal.woff2", "5.3.0",
      "86132abb57fc615f2ab900cde4cd9d5796e9791daf1f85d79fc933aa50b3b15c"),
    ("commit-mono-latin-700-normal.woff2", "5.3.0",
      "1b00600b728444492b0c4906cb85e0055b889ea32ea4fb29bf25cd90cd0365b4"),
  ]
    ## Faces every page embeds, each with package version fetched and digest of bytes
    ##   expected, all SIL Open Font License 1.1; origins in PROVENANCE.md.
    ##   Three families, by what they carry rather than by taste: Noto Serif sets titles,
    ##     Noto Sans sets body, Commit Mono sets code, data and figures (Article X.8).
    ##   Digest pins bytes, version pins fetch, and neither can drift from other: page
    ##     embeds these into artefact readers open, so wrong byte here is wrong byte
    ##     shipped, and unversioned path serves whatever host resolves that day.
    ##   Sibling of `FACES` in `contributor/ronri/rga_visualiser/tools/build.nim`, which
    ##     pins four of these seven at same version to same digest, and two more this
    ##     project never draws (Article II.9: each copy names its siblings).  Whether
    ##     repository wants one pinned list both select from is repository issue 116,
    ##     open; converting this table to selection is small change when it is answered.
  SYSTEM = [
    ("curl", "fetch faces `assets` pins; build shells out to it"),
    ("coreutils", "`sha256sum` verifying those pins, and `base64` inlining them"),
  ]
    ## System packages build needs present before it runs, with what each is for
    ##   (CONTRIBUTOR.md, "System dependencies").  No version is pinned and none is
    ##   invented: package's version is whatever machine carries.  What is pinned is
    ##   every byte fetched at build time, which is what `FACES` is for.
  USAGE = "Usage: nim r tools/build.nim <pages|assets|system|verdicts|shot|clean>\n"
    ## Text printed on usage error.


proc nim(args: openArray[string]) =
  ## Run compiler with args from project directory; raise on non-zero exit.
  let process = startProcess("nim", args = args, options = {poUsePath, poParentStreams})
  let code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, "nim failed; got exit `" & $code & "`.")

proc run(command: string, args: openArray[string]) =
  ## Run command with args from project directory; raise on non-zero exit.
  let process = startProcess(command, args = args, options = {poUsePath, poParentStreams})
  let code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, command & " failed; got exit `" & $code & "`.")

proc compileRun(args: openArray[string]) =
  ## Compile and run program with args, quietly, binary into `bin/`.
  nim(@["c", "-r"] & QUIET & @["--outdir:" & BIN] & @args)



proc digestOf(path: string): string =
  ## Read file's SHA-256, as `sha256sum` writes it.
  ##   Shelled out rather than hashed here: standard library carries no SHA-256, and
  ##     dependency for one digest costs more than one system package already declared.
  let (written, code) = execCmdEx("sha256sum " & quoteShell(path))
  if code != 0:
    raise newException(OSError, "sha256sum failed; got exit `" & $code & "`.")
  written.strip.split(' ')[0]


#[ Commands ]#

proc assets() =
  ## Fetch every face pages embed into `build/fonts`, verifying each against its pin.
  ##   Face already present with matching digest is left alone, so warm build fetches
  ##     nothing; face present with wrong digest is refetched, since only pin is truth.
  createDir(DIR_FONTS)
  var fetched = 0
  for (face, version, digest) in FACES:
    let path = DIR_FONTS / face
    if fileExists(path) and digestOf(path) == digest:
      continue
    let family = face.split('-')[0 .. ^4].join("-")
    run("curl", [
      "--fail", "--silent", "--show-error", "--location", "--output", path,
      HOST_FACES & "/" & family & "@" & version & "/files/" & face,
    ])
    let got = digestOf(path)
    if got != digest:
      removeFile(path)
      raise newException(OSError,
        "Face does not match its pin, so it is not used: `" & face & "`; wanted `" &
          digest & "`, got `" & got & "`.")
    inc fetched
  echo "Faces in ", DIR_FONTS, ": ", FACES.len, ", ", fetched,
    " fetched, every digest matched."


proc system() =
  ## Print system packages this build needs, one per line, and nothing else.
  ##   Runner installs what it prints, so reason must not reach output.
  for (package, _) in SYSTEM:
    echo package


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
    of "system": system()
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
