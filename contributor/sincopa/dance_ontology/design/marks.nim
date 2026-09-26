## Build workbench: parts, checks, pages, files.
##
##   Build refuses to write page whose claims fail: checks run between building page's
##     parts and writing it, and several figures are asserted during their own construction.
##     Cost of refusing whole build: one broken rule stops every page, not just its own.
##       Accepted -- workbench that publishes half-checked pages is worse than one that stops.
##   Pages are build products under `build/design/`, never committed: repository reads only
##     registered file kinds.  Each is published at fixed URL listed in `../README.md`;
##     republishing rebuilt files to those URLs is whole release step.
##     Every one is mock-up rather than page project stands behind, and its title says so.
##   `tests/suites/tmarks.nim` drives `buildPage` for every page, so every gate runs under
##     `nim r koch test` (Article IX.6).
##   Every page's parts are built once in process and kept (`made`).  Page's checks read
##     what page placed, and review page places both walked pages' figures again, so
##     full build routed single-hand turns three times and hand-to-hand turns three.
##     Routing is most of what build costs.

{.experimental: "strictFuncs".}

import std/[os, strformat, tables, unicode]

import ./[checks, frame_page, hands_page, parts, review_page, sign_page,
           turns_single_page]


proc checkFrameAndRules() =
  ## Check everything frame page claims: drawing, then ledger.
  checkFrame()
  checkRules()


var made: Table[string, Parts]
  ## Parts of every page built so far, by page, so none is routed twice.

proc once(name: string; build: proc (): Parts {.nimcall.}): Parts =
  ## Parts of page `name`, built on first asking and kept.
  if name notin made:
    made[name] = build()
  made[name]

proc singleParts(): Parts = once("turns-single.html", singleTurnParts)
  ## Single-hand turns page's parts, built once.

proc handParts(): Parts = once("turns-hands.html", handTurnParts)
  ## Hand-to-hand turns page's parts, built once.

proc reviewed(): Parts = reviewParts(singleParts(), handParts())
  ## Review page's parts, from walked pages' own.


const PAGES* = [
  (name: "frames.html",
   parts_of: proc (): Parts {.nimcall.} = once("frames.html", frameParts),
   check: proc (parts: Parts) {.nimcall.} = checkFrameAndRules(),
   render: proc (parts: Parts): string {.nimcall.} = frame_page.render(parts)),
  (name: "signs.html",
   parts_of: proc (): Parts {.nimcall.} = once("signs.html", signParts),
   check: proc (parts: Parts) {.nimcall.} = checkSign(),
   render: proc (parts: Parts): string {.nimcall.} = sign_page.render(parts)),
  (name: "turns-single.html",
   parts_of: proc (): Parts {.nimcall.} = singleParts(),
   check: proc (parts: Parts) {.nimcall.} = checkSingleTurns(parts),
   render: proc (parts: Parts): string {.nimcall.} =
     turns_single_page.render(parts)),
  (name: "turns-hands.html",
   parts_of: proc (): Parts {.nimcall.} = handParts(),
   check: proc (parts: Parts) {.nimcall.} = checkHandTurns(parts),
   render: proc (parts: Parts): string {.nimcall.} = hands_page.render(parts)),
  (name: "review.html",
   parts_of: proc (): Parts {.nimcall.} = once("review.html", reviewed),
   check: proc (parts: Parts) {.nimcall.} = checkReview(),
   render: proc (parts: Parts): string {.nimcall.} = review_page.render(parts)),
] ## Each page: its file, its figures, its checks, its layout.


proc buildPage*(i: int; out_dir: string) =
  ## Check page `i` of `PAGES`, then write it into `out_dir`.
  let page = PAGES[i]
  let built = page.parts_of()
  echo &"{page.name}: {built.len} pieces"
  page.check(built)
  let
    html = page.render(built)
    path = out_dir / page.name
  writeFile(path, html)
  echo &"  written {html.runeLen} characters to {path}"


proc buildPages*(out_dir: string) =
  ## Check and rebuild every page into `out_dir`.
  for i in 0 ..< PAGES.len:
    buildPage(i, out_dir)


when isMainModule:
  doAssert paramCount() == 1, "Usage: marks <dir>; got `" & $paramCount() & "` arguments."
  buildPages(paramStr(1))
