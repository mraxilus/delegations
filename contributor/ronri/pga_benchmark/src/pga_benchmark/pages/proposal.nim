## Render one proposal: summary card, five numbered sections, then code and evidence apart.
##   Proposal page is future state of library, argued in `proposal.md` and checked by its
##     evaluation. Every proposal renders through one shape, so next exploration reads as last
##     one did, and each fact stands in one place:
##
##     ```
##     header      title, status, pin and run; contents
##     card        what it is, is for and costs; what it needs and blocks; verdicts at pin
##     1 Problem   what pin does, and why it falls short
##     2 Idea      how proposal works
##     3 Alternatives   options weighed, and why each lost
##     4 Costs     what gets worse, and what it leaves out
##     5 Open decisions
##     appendix    Code: how it lands, then each file folded, each definition's body folded
##     appendix    Evidence: claims, gains and losses at pin per function, then notes
##     footer      other pages
##     ```
##
##   Page generates verdicts, measurements, dependencies and code, so argument restates none.
##     Section outside standard set follows them, and `drive` names it (`proposals.nim`).
##   Header cites number and status. Frozen proposal shows pin its last evaluation was taken at,
##     since library has moved past it.
##   Ids carry proposal's name, so list page holds every proposal and contents still lead home.
##
##   Figure paragraph embeds SVG it names, whole, so figure takes page's colours and faces; one
##     whose file is absent renders as its text, and `drive` names it.
##
##   Argument comes first, as Architect ordered on 2026-10-16: reader meets idea and its cost,
##     and appendix holds what checks it.

{.experimental: "strictFuncs".}

import std/[json, options, sequtils, strutils, tables]

import ../[changes, markdown, proposals]
import ./[evaluation, shell]


func citeLinked*(proposal: Proposal, urls: Table[string, string]): string =
  ## Cite proposal, linked to its page where published.
  let url = urls.getOrDefault(proposal.name)
  if url.len == 0: escapeHtml(proposal.citation)
  else: "<a href=\"" & escapeHtml(url) & "\">" & escapeHtml(proposal.citation) & "</a>"


func htmlBlocks(
  nodes: openArray[Block]; directory: string; figures: Table[string, string]; level: int
): string =
  ## Render blocks of argument, each figure paragraph as SVG it names where page holds it.
  for node in nodes:
    let figure = node.figureOf(directory)
    if figure.isSome and figure.get.path in figures:
      result.add "<figure class=\"figure\"><div class=\"figure-art\">" &
          figures[figure.get.path] & "</div><figcaption>" & renderInline(figure.get.caption) &
          "</figcaption></figure>"
    else:
      result.add renderBlock(node, level)


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
      let defined = block:
        var names: seq[string]
        for define in claim{"defines"}.getElems: names.add code(define.getStr)
        if names.len == 0: "" else: ", with " & names.join(" and ")
      case claim{"kind"}.getStr
      of "suites": "library's own suites pass on changed library" & defined
      of "tables": $claim{"pairs"}.len & " tables equal pristine ones cell for cell at " & algebras
      of "program": code(claim{"path"}.getStr) & " compiles and runs clean at " & algebras & defined
      of "count": code(claim{"measurand"}.getStr) & " spends " & $claim{"value"}.getInt & " " &
          claim{"metric"}.getStr & " at " & claim{"algebra"}.getStr
      of "build":
        "compiling library alone costs at most ×" & claim{"at_most"}.getFloat.fixed &
            " of pristine " &
            (if claim{"metric"}.getStr == "seconds": "seconds" else: "peak memory") & " at " &
            claim{"algebra"}.getStr
      else: escapeHtml(claim{"kind"}.getStr)

    if evaluation.isNil: return "<p class=\"note\">No evaluation yet; claims are unchecked.</p>"
    result = "<ul class=\"claims\">"
    for claim in evaluation{"claims"}:
      let is_holding = claim{"passed"}.getBool
      var detail: seq[string]
      for line in claim{"detail"}.getElems: detail.add escapeHtml(line.getStr)
      result.add "<li>" &
          chip(if is_holding: "holds" else: "fails", if is_holding: "pass" else: "fail") & " " &
          textClaim(claim) &
          (if detail.len > 0: "<span class=\"detail\">" & detail.join("<br>") & "</span>"
            else: "") &
          "</li>"
    result.add "</ul>"

  let
    commit_shown =
      if proposal.isFrozen and not evaluation.isNil: evaluation{"taken", "pga"}.getStr else: pin
    standing =
      if proposal.isImplemented: "implemented in " & code(
        proposal.implemented_in[
          0..<min(7, proposal.implemented_in.len)],
      )
      elif proposal.isFrozen: "withdrawn"
      else: "proposed"
  let
    (title, section, part) = ("h" & $level, "h" & $(level + 1), "h" & $(level + 2))
    anchor = proposal.name & "-"  # Ids stay apart where list page holds every proposal.

  # Header: title, where proposal stands, then other pages.
  result = "<header><" & title & ">" & escapeHtml(proposal.citation) & ": " &
      renderInline(proposal.title) & "</" & title & "><p class=\"meta\">" & standing & " · pga " &
      code(commit_shown[0..<min(7, commit_shown.len)])
  if not evaluation.isNil:
    result.add " · tried " & escapeHtml(evaluation{"taken", "date"}.getStr) &
        measuredAt(evaluation{"taken"}) & ", " & escapeHtml(evaluation{"taken", "machine"}.getStr)
  result.add "</p>"

  # Split argument: summary above first section, then each section by its name.
  var
    lead = 0
    sections: seq[(string, seq[Block])]
  while lead < proposal.body.len and
      not (proposal.body[lead].kind == KindBlock.Heading and proposal.body[lead].level == 2):
    inc lead
  for node in proposal.body[lead .. ^1]:
    if node.kind == KindBlock.Heading and node.level == 2: sections.add (node.lines[0], @[])
    elif sections.len > 0: sections[^1][1].add node

  func blocksOf(sections: seq[(string, seq[Block])], name: string): seq[Block] =
    ## Get blocks of section of name; none where argument lacks it.
    for (heading, nodes) in sections:
      if heading == name: return nodes

  # Contents, numbered as sections are.
  const shown = [
    ("1", "Problem"), ("2", "Idea"), ("3", "Alternatives"), ("4", "Costs"),
    ("5", "Open decisions"), ("A", "Code"), ("B", "Evidence"),
  ]  ## Sections page shows, in order, each with its mark; appendix is lettered.
  result.add "<nav class=\"contents\">"
  for (mark, name) in shown:
    result.add "<a href=\"#" & anchor & name.toLowerAscii.replace(' ', '-') &
        "\"><span class=\"num\">" & mark & "</span> " & name & "</a>"
  result.add "</nav></header>"

  # Summary card: what it is, is for and costs, then what it needs and blocks, then verdicts.
  result.add "<section class=\"glance\"><dl class=\"summary\">"
  var rest: seq[Block]
  for node in proposal.body[0..<lead]:
    let text = node.lines.join(" ")
    var is_labelled = false
    if node.kind == KindBlock.Paragraph and text.startsWith("**"):
      let close = text.find(".**")
      if close > 2:
        result.add "<div><dt>" & escapeHtml(text[2..<close]) & "</dt><dd>" &
            renderInline(text[close+3 .. ^1].strip) & "</dd></div>"
        is_labelled = true
    if not is_labelled: rest.add node
  result.add "</dl>"
  if rest.len > 0:
    result.add "<div class=\"prose\">" & htmlBlocks(rest, proposal.directory, figures, level) &
        "</div>"
  result.add htmlDependencies(proposals, proposal, urls) &
      "<dl class=\"depends\"><div><dt>Tried at pin</dt><dd><div class=\"chips\">" &
      chipsVerdict(evaluation, baselines, spread) & "</div></dd></div></dl></section>"

  func opening(anchor, section, name, mark: string): string =
    ## Open section of name under its mark, with id contents link to; appendix opens apart.
    "<section class=\"block prose" & (if mark == "A": " appendix" else: "") & "\" id=\"" &
        anchor & name.toLowerAscii.replace(' ', '-') & "\"><" & section & "><span class=\"num\">" &
        mark & "</span> " & name & "</" & section & ">"

  for (mark, name) in shown:
    result.add opening(anchor, section, name, mark)
    case name
    of "Evidence":
      result.add "<" & part & ">Claims</" & part & ">" & htmlClaims(evaluation) & "<" & part &
          ">Gains and losses at pin</" & part & ">"
      let bases = dependenciesOf(proposals, proposal)[0]
      if bases.len > 0 and not evaluation.isNil:
        result.add "<p class=\"note\">Proposal is measured with " &
            bases.mapIt(citeLinked(it, urls)).join(", ") & " applied first, so its figures " &
            "hold their gains too.</p>"
      result.add htmlEvidence(evaluation, baselines, spread)
      let notes = sections.blocksOf(name)
      if notes.len > 0:
        result.add "<" & part & ">Notes</" & part & ">" &
            htmlBlocks(notes, proposal.directory, figures, level)
    of "Code":
      let landing = sections.blocksOf("Landing")
      if landing.len > 0:
        result.add "<" & part & ">How it lands</" & part & ">" &
            htmlBlocks(landing, proposal.directory, figures, level)
      if proposal.change.edits.len > 0:
        var based = files
        for base in dependenciesOf(proposals, proposal)[0]:
          discard applyChange(based, base.change, base.directory)  # Misfit is `drive`'s finding.
        result.add "<" & part & ">Files</" & part & ">" & htmlCode(proposal.change, based)
      else:
        result.add "<p class=\"note\">Proposal carries no change.</p>"
    else:
      result.add htmlBlocks(sections.blocksOf(name), proposal.directory, figures, level)
    result.add "</section>"

  # Section outside standard set stays on page, after it, and `drive` names it.
  for (heading, nodes) in sections:
    if heading notin SECTIONS_PROPOSAL:
      result.add "<section class=\"block prose\"><" & section & ">" & renderInline(heading) & "</" &
          section & ">" & htmlBlocks(nodes, proposal.directory, figures, level) & "</section>"

  # Other pages close page, apart from what proposal says.
  if links.len > 0:
    result.add "<footer class=\"pages\">" & (if links.startsWith(" · "): links[" · ".len .. ^1]
        else: links) & "</footer>"


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
