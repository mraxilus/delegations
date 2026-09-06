## Write review page and frame pictures from model.
##
##   Page used to carry its own copy of frames and transitions, transcribed by hand from
##     audit.  Nothing kept that copy honest, which made it one part of work that could
##     quietly go wrong.
##   Now prose lives in `pages/review/review.html` with marker wherever number or picture
##     belongs, and everything marker stands for is derived here.
##     Prose was Nim string constant while repository read no markup kind; `Html` is
##       registered now, so page is committed file read at run time.
##       Cost: template path is relative to project directory, so renderer runs from there,
##         as testament and build driver both do.
##   Page and pictures are build products under `build/review/`, never committed:
##     repository reads only registered file kinds.  `tests/treview.nim` renders page,
##     writes it and reads it back, so model change that breaks page fails suite.
##     Cost of build product: nothing in tree shows page's history, and published copy is
##       not record either, since it can be deleted -- log is.  Page is republished from
##       build driver's `pages`.
##   Usage: `review <dir>` writes `<dir>/review.html` and `<dir>/frames/<slug>.svg`.

{.experimental: "strictFuncs".}

import std/[options, os, strutils]

import ../src/dance_ontology
import ./title


const
  TEMPLATE_PATH = "pages" / "review" / "review.html"
    ## Committed page holding prose and one marker per derived number or picture.
  PAGE_NAME* = "review.html"
    ## File page is written as, under output directory.
  FRAMES_DIR* = "frames"
    ## Directory under output holding one SVG per frame, for anything that is not HTML.
  DISAGREEMENTS = {
    FindingKind.EdgeAbsent,
    FindingKind.ReverseAbsent,
    FindingKind.EdgeCompound,
    FindingKind.HelperDiffers,
    FindingKind.EdgeUnsupported,
  } ## Name finding kinds that mean workbook and model differ.



#[ Counting ]#

func countMoves(): int =
  ## Count moves in whole ontology.
  for source in FRAMES:
    result += moves(source).len


func countDisagreements(): int =
  ## Count findings that say workbook and model differ.
  for finding in audit():
    if finding.kind in DISAGREEMENTS:
      inc result


func longestRoute(): int =
  ## Get most moves any frame is from any other.
  for source in FRAMES:
    for destination in FRAMES:
      result = max(result, route(source, destination).len)


func countNamedStates(): int =
  ## Count workbook states hand-to-hand model can check.
  for name in WORKBOOK_STATES:
    if not name.isDeferred:
      inc result


proc countLaws(): int =
  ## Count tests, by reading suite rather than remembering number.
  ##   Reads `tests/t*.nim` relative to project directory, where testament and `make`
  ##     run; run from elsewhere it counts nothing.
  var paths: seq[string] = @[]
  for path in walkFiles("tests/t*.nim"):
    paths.add path
  for path in paths:
    for line in readFile(path).splitLines:
      if line.strip().startsWith("test \""):
        inc result



#[ Fragments ]#

func escape(text: string): string =
  ## Escape text for placement in markup.
  ##   Looser than app's `esc`: nothing here writes user text into attribute, so quotes
  ##     pass through.
  text.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"))


func inked(said: string; escaping = true): string =
  ## Say name with each hand it names written in that dancer's own ink.
  ##   Page's drawings ink their words this way, and name in prose beside them is same
  ##     name; reader who has learnt two shades from map should not have to learn them
  ##     again from gallery.
  ##   Third renderer of one reading, after drawings' `labelled` and app's own: reading is
  ##     shared and markup is not, because `<tspan>` and `<span>` are not same element.
  ##   `escaping` is off for words already lifted out of page, which are markup-ready and
  ##     would be escaped second time.
  for run in named(said):
    let text = if escaping: escape(run.text) else: run.text
    if run.lead.isNone and run.follow.isNone:
      result.add text
      continue
    let ink = if run.lead.isSome: armColour(run.lead.get)
              else: followColour(run.follow.get)
    result.add "<span style=\"color: " & ink & "\">" & text & "</span>"


func statCard(number: int; caption: string; is_good = false): string =
  ## Draw one figure in strip at head of page.
  "<div class=\"stat" & (if is_good: " good" else: "") & "\"><b>" & $number &
    "</b><span>" & caption & "</span></div>"


proc renderStats(): string =
  ## Draw figures page opens with.
  "<div class=\"stats\">" &
    statCard(FRAMES.len, "frames the model derives") &
    statCard(countMoves(), "moves between them") &
    statCard(CELLS.len - countDeferredCells(), "cells checkable today") &
    statCard(countDisagreements(), "cells that disagree", is_good = true) &
    statCard(countDeferredCells(), "cells waiting on the body") &
    statCard(countLaws(), "laws under test") &
    "</div>"


func renderGallery(): string =
  ## Draw every frame, marking ones workbook has no row for.
  result = "<div class=\"gallery\">"
  for target in FRAMES:
    let absent = workbookName(target).isNone
    result.add "<div class=\"card" & (if absent: " absent" else: "") & "\">" &
      renderFrame(target) & "<div><div class=\"name\">" &
      inked(target.describe) & "</div><div class=\"meta\">" &
      $moves(target).len & " moves" &
      (if absent: " &middot; no row in the sheet" else: "") & "</div></div></div>"
  result.add "</div>"


func renderArms(): string =
  ## Say which ink is which arm, since both drawings are inked same way.
  result = "<div class=\"legend\">"
  for side in Side:
    result.add "<span class=\"swatch\"><i class=\"arm-" &
      ($side).toLowerAscii & "\"></i>the lead's " & leadName(side) &
      " arm</span>"
  result.add "</div>"


func renderLegend(): string =
  ## Say which letter in matrix stands for which move.
  for helper in Helper:
    if result.len > 0:
      result.add " &middot; "
    result.add "<b>" & HELPER_MARKS[helper] & "</b> " & helper.name
    if HELPER_SYNONYMS[helper].len > 0:
      result.add " (your <em class=\"term\">" &
        HELPER_SYNONYMS[helper].split(' ')[0] & "</em>)"
  for named in Compound:
    result.add " &middot; <b>" & COMPOUND_MARKS[named] & "</b> " &
      ($named).toLowerAscii & ", two moves"


func renderMatrix(): string =
  ## Draw whole transition relation, marking what workbook leaves blank.
  result = "<table class=\"matrix\"><thead><tr><th></th>"
  for target in FRAMES:
    result.add "<th>" & renderFrame(target) & "</th>"
  result.add "</tr></thead><tbody>"
  for source in FRAMES:
    result.add "<tr><th class=\"row\">" & inked(source.describe) & "</th>"
    for target in FRAMES:
      if source == target:
        result.add "<td class=\"self\"></td>"
        continue
      let
        helper = classify(source, target)
        named = compound(source, target)
      if helper.isNone and named.isNone:
        result.add "<td></td>"
        continue
      let known = cellText(
        workbookName(source).get(""), workbookName(target).get(""))
      result.add "<td class=\"on" & (if known.isSome: "" else: " new") &
        (if helper.isNone: " two" else: "") &
        "\" title=\"" & escape(source.describe) & " to " &
        escape(target.describe) & "\">" &
        (if helper.isSome: HELPER_MARKS[helper.get]
         else: COMPOUND_MARKS[named.get]) & "</td>"
    result.add "</tr>"
  result.add "</tbody></table>"


func renderPrimitives(): string =
  ## List primitives, what each changes, and workbook's other word.
  result = "<table class=\"plain\"><thead><tr><th>Primitive</th>" &
    "<th>What changes</th><th>Your words</th></tr></thead><tbody>"
  for helper in Helper:
    let synonym =
      if HELPER_SYNONYMS[helper].len == 0: "<span class=\"dim\">&mdash;</span>"
      else: "also <code>" & HELPER_SYNONYMS[helper].split(' ')[0] & "</code>, " &
        HELPER_SYNONYMS[helper].split(' ', 1)[1]
    result.add "<tr><td>" & helper.name & "</td><td>" & HELPER_CHANGES[helper] &
      "</td><td>" & synonym & "</td></tr>"
  result.add "</tbody></table>"


func renderCompounds(): string =
  ## List compounds, what each does, and why ontology names it.
  result = "<table class=\"plain\"><thead><tr><th>Compound</th>" &
    "<th>What changes</th><th>The two moves</th><th>Obstructed</th>" &
    "</tr></thead><tbody>"
  for named in Compound:
    result.add "<tr><td>" & ($named).toLowerAscii & "</td><td>" &
      COMPOUND_CHANGES[named] & "</td><td>" & COMPOUND_ORDERS[named] &
      "</td><td>" & (if COMPOUND_OBSTRUCTED[named]:
        "yes, by the other arm" else: "<span class=\"dim\">no</span>") &
      "</td></tr>"
  result.add "</tbody></table>"


func countCells(is_compound: bool): int =
  ## Count checkable cells that name compound, or that name primitive.
  for cell in CELLS:
    if cell.source.isDeferred or cell.destination.isDeferred:
      continue
    if (readCompound(readCell(cell.text)[0]).isSome) == is_compound:
      inc result


func renderAudit(): string =
  ## Show audit's own report, in words tool prints it in.
  var lines = ""
  for kind in FindingKind:
    for finding in audit():
      if finding.kind != kind:
        continue
      lines.add $kind & "\n  " & finding.subject & "\n    " & finding.detail & "\n"
  "<pre>" & escape(lines.strip(leading = false)) & "</pre>"



#[ Assembly ]#

func inkTerms(page: string): string =
  ## Ink hands in every term of art prose quotes.
  ##   Term marked up as one -- `Left to left`, `Left-to-right and Right-to-left` -- is
  ##     name, and name is written in hands it names wherever page writes it.  Left alone,
  ##     prose would call frame one thing and gallery two inches below it would call same
  ##     frame another.
  ##   Done to finished page rather than by hand in template, so term written later is
  ##     inked without anyone remembering to, and so prose stays prose to read and to edit.
  ##   Only inside mark: hand named in ordinary sentence is being talked about rather than
  ##     named, and sentence around it is doing that work already.
  ##   Terms with no hand in them -- `open`, `closed`, `wrap` -- come back from `named` as
  ##     one unmarked stretch and are handed back untouched.
  const
    opens = "<em class=\"term\">"
    shuts = "</em>"
  result = page
  var at = 0
  while true:
    let start = result.find(opens, at)
    if start < 0:
      break
    let
      inner = start + opens.len
      stop = result.find(shuts, inner)
    let said = inked(result[inner ..< stop], escaping = false)
    result = result[0 ..< inner] & said & result[stop .. ^1]
    at = inner + said.len + shuts.len


proc renderReview*(): string =
  ## Fill prose of review with what model says; every marker must be filled.
  let free_frame = fromKey("--.").get
  var page = readFile(TEMPLATE_PATH)
  let fills = {
    "title": MOCKUP & " — The Review Page",
    "stats": renderStats(),
    "gallery": renderGallery(),
    "matrix": renderMatrix(),
    "map": renderMap(none(Frame)),
    "arms": renderArms(),
    "primitives": renderPrimitives(),
    "compounds": renderCompounds(),
    "compound_count": $(ord(high(Compound)) + 1),
    "primitive_cells": $countCells(is_compound = false),
    "compound_cells": $countCells(is_compound = true),
    "audit": renderAudit(),
    "legend": renderLegend(),
    "frames": $FRAMES.len,
    "moves": $countMoves(),
    "cells": $CELLS.len,
    "checkable": $(CELLS.len - countDeferredCells()),
    "deferred": $countDeferredCells(),
    "named": $countNamedStates(),
    "free_moves": $(2 * moves(free_frame).len),
    "primitive_count": $(ord(high(Helper)) + 1),
    "laws": $countLaws(),
    "pairs": $(FRAMES.len * FRAMES.len),
    "diameter": $longestRoute(),
  }
  for (marker, value) in fills:
    page = page.replace("{{" & marker & "}}", value)
  let at = page.find("{{")
  doAssert at < 0,
    "Every marker in review prose should be filled; got `" &
      page[at ..< min(at + 24, page.len)] & "`."
  inkTerms(page)


proc writeReview*(out_dir: string) =
  ## Write page and one picture per frame under `out_dir`, clearing stale pictures first.
  ##   Cleared because frame renamed would otherwise leave its old picture behind under
  ##     old name, naming frame model no longer has.
  createDir(out_dir / FRAMES_DIR)
  for path in walkFiles(out_dir / FRAMES_DIR / "*.svg"):
    removeFile(path)
  writeFile(out_dir / PAGE_NAME, renderReview())
  for target in FRAMES:
    writeFile(out_dir / FRAMES_DIR / (target.slug & ".svg"), renderFrame(target))
  echo "wrote ", out_dir / PAGE_NAME, " and ", FRAMES.len, " pictures in ",
    out_dir / FRAMES_DIR


when isMainModule:
  doAssert paramCount() == 1, "Usage: review <dir>; got `" & $paramCount() & "` arguments."
  writeReview(paramStr(1))
