## Render one design exploration: claims and their verdicts, argument, candidate, measurements.
##   Design page is future state of library, argued in `design.md` and checked by its trial.
##     Every design renders through this one shape, so next exploration reads as last one did:
##     claims first, since they say whether design holds; then argument; then what it changes and
##     what that measured at pin.
##
##   Cost: whole-file replacement renders collapsed, since hundreds of lines would bury claims.

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]

import ../[designs, markdown]
import ./[shell, trial]


func claimText(claim: JsonNode): string =
  ## Render what one claim asserts, in words.
  let algebras = block:
    var names: seq[string]
    for a in claim{"algebras"}.getElems: names.add a.getStr
    names.join(", ")
  case claim{"kind"}.getStr
  of "suites": "library's own suites pass on changed library"
  of "tables": $claim{"pairs"}.len & " tables equal pristine ones cell for cell at " & algebras
  of "program": code(claim{"path"}.getStr) & " compiles and runs clean at " & algebras
  of "count": code(claim{"measurand"}.getStr) & " spends " & $claim{"value"}.getInt & " " &
    claim{"metric"}.getStr & " at " & claim{"algebra"}.getStr
  of "build": "compiling bench entry costs at most ×" & claim{"at_most"}.getFloat.fixed &
    " of pristine " & (if claim{"metric"}.getStr == "seconds": "seconds" else: "peak memory") &
    " at " & claim{"algebra"}.getStr
  else: escapeHtml(claim{"kind"}.getStr)


func claimsHtml(trial: JsonNode): string =
  ## Render claims trial checked, each with its verdict and detail.
  if trial.isNil: return "<p class=\"note\">No trial yet; claims are unchecked.</p>"
  result = "<div class=\"table\"><table><tr><th>Claim</th><th>Verdict</th><th>Detail</th></tr>"
  for claim in trial{"claims"}:
    let passed = claim{"passed"}.getBool
    var detail: seq[string]
    for d in claim{"detail"}.getElems: detail.add escapeHtml(d.getStr)
    result.add "<tr><td>" & claimText(claim) & "</td><td>" &
      chip(if passed: "holds" else: "fails", if passed: "pass" else: "fail") & "</td><td>" &
      detail.join("<br>") & "</td></tr>"
  result.add "</table></div>"


func designBody*(
  design: Design;
  trial: JsonNode;
  files: Table[string, string];
  baselines: Table[string, JsonNode];
  band: Band;
  pin, links: string;
): string =
  ## Render design page body.
  result = "<div class=\"page\"><header><h1>" & renderInline(design.title) &
    "</h1><p class=\"meta\">design " & code(design.name) & " · pga " & code(pin[0 ..< 7])
  if design.builds_on.len > 0: result.add " · builds on " & code(design.builds_on)
  if not trial.isNil:
    result.add " · tried " & escapeHtml(trial{"taken", "date"}.getStr) & ", " &
      escapeHtml(trial{"taken", "machine"}.getStr)
  result.add links & "</p><div class=\"chips\">" &
    verdictChips(trial, baselines, band) & "</div></header>"
  result.add "<section class=\"block\"><h2>Claims</h2>" & claimsHtml(trial) & "</section>"
  result.add "<section class=\"block prose\">" & renderBlocks(design.body, 1) & "</section>"
  if design.change.edits.len > 0:
    result.add "<section class=\"block\"><h2>What it changes</h2>" &
      editsHtml(design.change, files) & "</section>"
  if not trial.isNil:
    result.add "<section class=\"block\"><h2>What it measured at pin</h2><p class=\"note\">" &
      bandText(band) & "</p>" & functionsTable(trial) & nanTable(trial) &
      timesTable(trial, baselines, band) &
      "</section>"
  result.add "</div>"
