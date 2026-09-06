## Build workbench: parts, checks, pages, files.
##
##   Build refuses to write page whose claims fail: checks run between building page's
##     parts and writing it, and several figures are asserted during their own construction.
##     Cost of refusing whole build: one broken rule stops every page, not just its own.
##       Accepted -- workbench that publishes half-checked pages is worse than one that stops.
##   Pages are build products under `build/design/`, never committed: repository reads only
##     registered file kinds.  Each is published as Claude artifact at fixed URL, listed in
##     `README.md`; republishing rebuilt files to those URLs is whole release step.
##   `tests/tmarks.nim` drives `buildPage` for every page, so every gate runs under
##     `make check` (Article IX.6).

{.experimental: "strictFuncs".}

import std/[os, strformat, tables, unicode]

import ./[checks, frame_page, hands_page, parts, sign_page, turns_single_page]


proc checkFrameAndRules() =
  ## Check everything frame page claims: drawing, then ledger.
  checkFrame()
  checkRules()


const PAGES* = [
  (name: "frames.html",
   parts_of: proc (): Parts {.nimcall.} = frameParts(),
   check: proc () {.nimcall.} = checkFrameAndRules(),
   render: proc (parts: Parts): string {.nimcall.} = frame_page.render(parts)),
  (name: "signs.html",
   parts_of: proc (): Parts {.nimcall.} = signParts(),
   check: proc () {.nimcall.} = checkSign(),
   render: proc (parts: Parts): string {.nimcall.} = sign_page.render(parts)),
  (name: "turns-single.html",
   parts_of: proc (): Parts {.nimcall.} = singleTurnParts(),
   check: proc () {.nimcall.} = checkSingleTurns(),
   render: proc (parts: Parts): string {.nimcall.} =
     turns_single_page.render(parts)),
  (name: "turns-hands.html",
   parts_of: proc (): Parts {.nimcall.} = handTurnParts(),
   check: proc () {.nimcall.} = checkHandTurns(),
   render: proc (parts: Parts): string {.nimcall.} = hands_page.render(parts)),
] ## Each page: its file, its figures, its checks, its layout.


proc buildPage*(i: int; out_dir: string) =
  ## Check page `i` of `PAGES`, then write it into `out_dir`.
  let page = PAGES[i]
  let built = page.parts_of()
  echo &"{page.name}: {built.len} pieces"
  page.check()
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
