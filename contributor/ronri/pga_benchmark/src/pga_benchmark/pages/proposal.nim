## Render one proposal: claims and their verdicts, argument, candidate, measurements.
##   Proposal page is future state of library, argued in `proposal.md` and checked by its
##     evaluation. Every proposal renders through this one shape, so next exploration reads as
##     last one did:
##     claims first, since they say whether proposal holds; then argument; then what it changes and
##     what that measured at pin.
##   Header cites number and status. Frozen proposal shows pin its last evaluation was taken at,
##     since library has moved past it, and edits whose quote is gone show file alone.
##
##   Cost: whole-file replacement renders collapsed, since hundreds of lines would bury claims.

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]

import ../[proposals, markdown]
import ./[shell, evaluation]


func proposalBody*(
  proposal: Proposal;
  evaluation: JsonNode;
  files: Table[string, string];
  baselines: Table[string, JsonNode];
  spread: Spread;
  pin, links: string;
): string =
  ## Render proposal page body.

  func claimsHtml(evaluation: JsonNode): string =
    ## Render claims evaluation checked, each with its verdict and detail.

    func claimText(claim: JsonNode): string =
      ## Render what one claim asserts, in words.
      let algebras = block:
        var names: seq[string]
        for name in claim{"algebras"}.getElems: names.add name.getStr
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

    if evaluation.isNil: return "<p class=\"note\">No evaluation yet; claims are unchecked.</p>"
    result = "<div class=\"table\"><table><tr><th>Claim</th><th>Verdict</th><th>Detail</th></tr>"
    for claim in evaluation{"claims"}:
      let is_holding = claim{"passed"}.getBool
      var detail: seq[string]
      for line in claim{"detail"}.getElems: detail.add escapeHtml(line.getStr)
      result.add "<tr><td>" & claimText(claim) & "</td><td>" &
        chip(if is_holding: "holds" else: "fails", if is_holding: "pass" else: "fail") &
        "</td><td>" & detail.join("<br>") & "</td></tr>"
    result.add "</table></div>"

  let
    pga_shown =
      if proposal.isFrozen and not evaluation.isNil: evaluation{"taken", "pga"}.getStr else: pin
    standing =
      if proposal.isImplemented: "implemented in " & code(proposal.implemented_in[
        0 ..< min(7, proposal.implemented_in.len)])
      elif proposal.isFrozen: "withdrawn"
      else: "proposed"
  result = "<div class=\"page\"><header><h1>" & escapeHtml(proposal.citation) & ": " &
    renderInline(proposal.title) & "</h1><p class=\"meta\">" & escapeHtml(proposal.citation) &
    " " & code(proposal.name) & " · " & standing & " · pga " &
    code(pga_shown[0 ..< min(7, pga_shown.len)])
  if proposal.builds_on.len > 0: result.add " · builds on " & code(proposal.builds_on)
  if not evaluation.isNil:
    result.add " · tried " & escapeHtml(evaluation{"taken", "date"}.getStr) & ", " &
      escapeHtml(evaluation{"taken", "machine"}.getStr)
  result.add links & "</p><div class=\"chips\">" &
    verdictChips(evaluation, baselines, spread) & "</div></header>"
  result.add "<section class=\"block\"><h2>Claims</h2>" & claimsHtml(evaluation) & "</section>"
  result.add "<section class=\"block prose\">" & renderBlocks(proposal.body, 1) & "</section>"
  if proposal.change.edits.len > 0:
    result.add "<section class=\"block\"><h2>What it changes</h2>" &
      editsHtml(proposal.change, files) & "</section>"
  if not evaluation.isNil:
    result.add "<section class=\"block\"><h2>What it measured at pin</h2><p class=\"note\">" &
      spreadText(spread) & "</p>" & functionsTable(evaluation) & nanTable(evaluation) &
      timesTable(evaluation, baselines, spread) &
      "</section>"
  result.add "</div>"
