## Render one proposal: claims and their verdicts, argument, candidate, measurements.
##   Proposal page is future state of library, argued in `proposal.md` and checked by its
##     evaluation. Every proposal renders through this one shape, so next exploration reads as
##     last one did:
##     claims first, since they say whether proposal holds; then argument; then what it changes and
##     what that measured at pin.
##   Header cites number and status. Frozen proposal shows pin its last evaluation was taken at,
##     since library has moved past it, and edits whose quote is gone show file alone.
##   Beneath header, proposal states what adopting it needs first and what rejecting it blocks,
##     since Architect decides each proposal on its own (`proposals.nim`).
##
##   Figure paragraph embeds SVG it names, whole, so figure takes page's colours and faces; one
##     whose file is absent renders as its text, and `drive` names it.
##
##   Cost: every edit renders closed, with signatures it defines or sits in, since hundreds of
##     lines would bury claims; reader opens edit to read its code.

{.experimental: "strictFuncs".}

import std/[json, options, sequtils, strutils, tables]

import ../[markdown, proposals]
import ./[evaluation, shell]


func citeLinked*(proposal: Proposal, urls: Table[string, string]): string =
  ## Cite proposal, linked to its page where published.
  let url = urls.getOrDefault(proposal.name)
  if url.len == 0: escapeHtml(proposal.citation)
  else: "<a href=\"" & escapeHtml(url) & "\">" & escapeHtml(proposal.citation) & "</a>"


func htmlDependencies*(
  proposals: openArray[Proposal], proposal: Proposal, urls: Table[string, string]
): string =
  ## Render what adopting proposal needs first and what rejecting it blocks, each one cited.
  ##   One reached through another names that one, as `P01 Title (through P02)`.
  ##   Base library implements is named so, since it needs no decision.

  func named(cited: Proposal, through: seq[Proposal], urls: Table[string, string]): string =
    ## Cite one proposal with its title, then those it is reached through.
    result = citeLinked(cited, urls) & " " & renderInline(cited.title)
    if through.len > 0:
      result.add " (through " & through.mapIt(citeLinked(it, urls)).join(", ") & ")"

  func htmlItems(items: seq[string]): string =
    ## Render items one per line, or `none` where there are none.
    if items.len == 0: "<span class=\"none\">none</span>"
    else: "<span>" & items.join("</span><span>") & "</span>"

  var needs, blocks: seq[string]
  for base in proposals:
    if base.name in proposal.builds_on and base.isImplemented:
      needs.add named(base, @[], urls) & " (implemented)"
  for base in dependenciesOf(proposals, proposal)[0]:
    needs.add named(base, basesToward(proposals, proposal, base), urls)
  for dependent in dependentsOf(proposals, proposal):
    blocks.add named(dependent, basesToward(proposals, dependent, proposal), urls)
  "<dl class=\"depends\"><div><dt>Depends on</dt><dd>" & htmlItems(needs) &
      "</dd></div><div><dt>Blocks if rejected</dt><dd>" & htmlItems(blocks) & "</dd></div></dl>"


func htmlProposal*(
  proposal: Proposal;
  proposals: openArray[Proposal];
  evaluation: JsonNode;
  files: Table[string, string];
  figures: Table[string, string];
  baselines: Table[string, JsonNode];
  spread: Spread;
  urls: Table[string, string];
  pin, links: string;
  level = 1;
): string =
  ## Render proposal: header, claims, argument, edits and measurements, title at heading `level`.
  ##   Page renders it at level one; proposal list nests it at level two, so sections follow.
  ##   `figures` maps project-relative SVG path to its text.
  ##   `proposals` holds every proposal, so dependencies are named; `urls` maps name to page.

  func htmlClaims(evaluation: JsonNode): string =
    ## Render claims evaluation checked, each with its verdict and detail.

    func textClaim(claim: JsonNode): string =
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
      of "build":
        "compiling library alone costs at most ×" & claim{"at_most"}.getFloat.fixed &
            " of pristine " &
            (if claim{"metric"}.getStr == "seconds": "seconds" else: "peak memory") & " at " &
            claim{"algebra"}.getStr
      else: escapeHtml(claim{"kind"}.getStr)

    if evaluation.isNil: return "<p class=\"note\">No evaluation yet; claims are unchecked.</p>"
    result = "<div class=\"table\"><table><tr><th>Claim</th><th>Verdict</th><th>Detail</th></tr>"
    for claim in evaluation{"claims"}:
      let is_holding = claim{"passed"}.getBool
      var detail: seq[string]
      for line in claim{"detail"}.getElems: detail.add escapeHtml(line.getStr)
      result.add "<tr><td>" & textClaim(claim) & "</td><td>" &
          chip(if is_holding: "holds" else: "fails", if is_holding: "pass" else: "fail") &
          "</td><td>" & detail.join("<br>") & "</td></tr>"
    result.add "</table></div>"

  let
    commit_shown =
      if proposal.isFrozen and not evaluation.isNil: evaluation{"taken", "pga"}.getStr else: pin
    standing =
      if proposal.isImplemented: "implemented in " & code(
        proposal.implemented_in[
          0 ..< min(7, proposal.implemented_in.len)],
      )
      elif proposal.isFrozen: "withdrawn"
      else: "proposed"
  let (title, section) = ("h" & $level, "h" & $(level + 1))
  result = "<header><" & title & ">" & escapeHtml(proposal.citation) & ": " &
      renderInline(proposal.title) & "</" & title & "><p class=\"meta\">" &
      escapeHtml(proposal.citation) &
      " " & code(proposal.name) & " · " & standing & " · pga " &
      code(commit_shown[0 ..< min(7, commit_shown.len)])
  if not evaluation.isNil:
    result.add " · tried " & escapeHtml(evaluation{"taken", "date"}.getStr) & ", " &
        escapeHtml(evaluation{"taken", "machine"}.getStr)
  result.add links & "</p><div class=\"chips\">" &
      chipsVerdict(evaluation, baselines, spread) & "</div>" &
      htmlDependencies(proposals, proposal, urls) & "</header>"
  result.add "<section class=\"block\"><" & section & ">Claims</" & section & ">" &
      htmlClaims(evaluation) & "</section>"
  result.add "<section class=\"block prose\">"
  for node in proposal.body:
    let figure = node.figureOf(proposal.directory)
    if figure.isSome and figure.get.path in figures:
      result.add "<figure class=\"figure\"><div class=\"figure-art\">" &
          figures[figure.get.path] & "</div><figcaption>" & renderInline(figure.get.caption) &
          "</figcaption></figure>"
    else:
      result.add renderBlock(node, level)
  result.add "</section>"
  if proposal.change.edits.len > 0:
    result.add "<section class=\"block\"><" & section & ">What it changes</" & section & ">" &
        htmlEdits(proposal.change, files) & "</section>"
  if not evaluation.isNil:
    result.add "<section class=\"block\"><" & section & ">What it measured at pin</" & section &
        "><p class=\"note\">" & textSpread(spread) & "</p>" & tableFunctions(evaluation) &
        tableNan(evaluation) & tableTimes(evaluation, baselines, spread) & "</section>"


func bodyProposal*(
  proposal: Proposal;
  proposals: openArray[Proposal];
  evaluation: JsonNode;
  files: Table[string, string];
  figures: Table[string, string];
  baselines: Table[string, JsonNode];
  spread: Spread;
  urls: Table[string, string];
  pin, links: string;
): string =
  ## Render proposal page body: proposal alone, title at level one.
  "<div class=\"page\">" & htmlProposal(
    proposal,
    proposals,
    evaluation,
    files,
    figures,
    baselines,
    spread,
    urls,
    pin,
    links,
  ) & "</div>"
