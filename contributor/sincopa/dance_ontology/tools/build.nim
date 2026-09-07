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
##   | pages    | write shells from Nim hosts, compile browser scripts, fold each into  |
##   |          | one self-contained file, render review page and frame pictures, build |
##   |          | five mark pages, sweep turns natively, splice whole-cloth page        |
##   | pins     | rewrite design/review-pins.json from page just built: run when        |
##   |          | Architect rules on cards, never to quiet check that says one moved    |
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
  USAGE = "Usage: nim r tools/build.nim <pages|verdicts|shot|clean>\n"
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

proc pages() =
  ## Write every page, picture and script under `build/`.
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
    of "pins": pins()
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
