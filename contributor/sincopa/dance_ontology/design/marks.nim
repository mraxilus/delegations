## Build Reference: parts, checks, page, file.
##
##   Build refuses to write page whose claims fail: checks run between building page's
##     parts and writing it, and several figures are asserted during their own construction.
##     Cost of refusing whole build: one broken rule stops page, not just card it is about.
##       Accepted -- workbench that publishes half-checked page is worse than one that stops.
##   Page is build product under `build/design/`, never committed: repository reads only
##     registered file kinds.  It is published at fixed URL listed in `../README.md`;
##     republishing rebuilt file to that URL is whole release step.
##     Project stands behind it, so its title is name of work, then page's own name.
##   `tests/suites/test_marks.nim` drives `buildPage` for every page, so every gate runs under
##     `nim r koch test` (Article IX.6).
##   Each chain's parts are built once in process and kept (`LUT_PARTS_BY_NAME`).
##     Reference places both chains, and their checks read them, so each chain is routed once.
##     Routing is most of what build costs.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[os, strformat, tables, unicode]

import ./[checks, parts, reference_page]


# Mutable: filled as parts build, one run long.
var LUT_PARTS_BY_NAME: Table[string, Parts]
  ## Parts built so far, by name, so none is routed twice.

proc once(name: string, build: proc (): Parts {.nimcall.}): Parts =
  ## Parts named `name`, built on first asking and kept.
  if name notin LUT_PARTS_BY_NAME:
    LUT_PARTS_BY_NAME[name] = build()
  LUT_PARTS_BY_NAME[name]

proc singleParts*(): Parts = once("single", singleTurnParts)
  ## Single-hand turns' parts, built once; `tests/suites/test_marks.nim` reads them too.

proc handParts(): Parts = once("hand", handTurnParts)
  ## Hand-to-hand chain's parts, built once.

proc reference(): Parts = referenceParts(singleParts(), handParts())
  ## Reference's parts, from both chains' own.


proc checkReference() =
  ## Check everything Reference places: drawing, ledger, both chains, then rulings.
  ##   Each chain's checks read that chain's own parts, never Reference's merged ones:
  ##     `checkHandTurns` walks every figure it is given, so merged parts would widen its law.
  checkFrame()
  checkRules()
  checkSingleTurns(singleParts())
  checkHandTurns(handParts())
  checkRulings()


const PAGES* = [
  (name: "reference.html",
   parts_of: proc (): Parts {.nimcall.} = once("reference.html", reference),
   check: proc (parts: Parts) {.nimcall.} = checkReference(),
   render: proc (parts: Parts): string {.nimcall.} = reference_page.render(parts)),
]  ## Each page: its file, its figures, its checks, its layout.


proc buildPage*(page_index: int, directory_out: string) =
  ## Check page `page_index` of `PAGES`, then write it into `directory_out`.
  let
    page = PAGES[page_index]
    built = page.parts_of()
  echo &"{page.name}: {built.len} pieces"
  page.check(built)
  let
    html = page.render(built)
    path = directory_out / page.name
  writeFile(path, html)
  echo &"  written {html.runeLen} characters to {path}"


proc buildPages*(directory_out: string) =
  ## Check and rebuild every page into `directory_out`.
  for i in 0..<PAGES.len:
    buildPage(i, directory_out)


when isMainModule:
  doAssert paramCount() == 1, "Usage: marks <dir>; got `" & $paramCount() & "` arguments."
  buildPages(paramStr(1))
