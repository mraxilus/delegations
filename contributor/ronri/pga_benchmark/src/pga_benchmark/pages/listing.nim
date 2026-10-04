## Render proposal list: graph of undecided proposals, every proposal in table, and readings.
##   Architect decides each proposal on its own, and proposals build on others as graph without
##     cycles (`proposals.nim`). List page shows that graph for those still proposed, so reader
##     sees what one decision blocks before opening any page; frozen ones are decided, so graph
##     leaves them out and table alone keeps them.
##   Graph lays proposals in columns by depth, as longest path to one that builds on no proposed
##     one, and in rows by number within column. Arrow points from proposal to one it builds on,
##     as `builds_on` reads.
##   Each proposal is read in place: graph box and table row are labels of one checkbox per
##     proposal, and checked one shows whole proposal under table, as its own page renders it.
##     Interaction is CSS, as shell's is: one rule per proposal ties its labels to its checkbox,
##     and form's reset clears every one.
##
##   Cost: edge spanning more than one column passes through column between, and may cross node
##     there; five proposals hold none such.
##   Cost: page carries every proposal whole, so it weighs their bodies on top of its faces.

{.experimental: "strictFuncs".}

import std/[json, sequtils, strutils, tables]

import ../[markdown, proposals]
import ./[evaluation, proposal, shell]


const
  WIDTH_NODE = 264  ## Width of one node of graph, in px.
  HEIGHT_NODE = 72  ## Height of one node, in px: citation and two lines of title.
  GAP_COLUMN = 84  ## Gap between columns, in px, where arrows run.
  GAP_ROW = 20  ## Gap between rows, in px.
  MARGIN_GRAPH = 8  ## Margin around graph, in px.


func idPick*(proposal: Proposal): string =
  ## Name checkbox that selects proposal for reading, as `pick-cayley-derivation`.
  "pick-" & proposal.name


func htmlGraph*(proposals: openArray[Proposal]): string =
  ## Draw undecided proposals as graph: one box each, one arrow per base it builds on.
  ##   Box is label of proposal's checkbox; arrows are SVG beneath boxes.
  ##   Empty where none is undecided.
  let undecided = proposals.filterIt(not it.isFrozen)
  if undecided.len == 0: return ""
  var depths = newSeq[int](undecided.len)
  for _ in 0 ..< undecided.len:  # n passes settle any graph without cycles
    for index, proposal in undecided:
      for base in proposal.builds_on:
        for at, other in undecided:
          if other.name == base: depths[index] = max(depths[index], depths[at] + 1)
  var
    rows = newSeq[int](undecided.len)
    counts = newSeq[int](max(depths) + 1)
  for index, depth in depths:
    rows[index] = counts[depth]
    inc counts[depth]
  let
    width = 2 * MARGIN_GRAPH + counts.len * WIDTH_NODE + (counts.len - 1) * GAP_COLUMN
    height = 2 * MARGIN_GRAPH + max(counts) * HEIGHT_NODE + (max(counts) - 1) * GAP_ROW
    xs = depths.mapIt(MARGIN_GRAPH + it * (WIDTH_NODE + GAP_COLUMN))
    ys = rows.mapIt(MARGIN_GRAPH + it * (HEIGHT_NODE + GAP_ROW))
  result = "<div class=\"graph\" style=\"width: " & $width & "px; height: " & $height &
      "px\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" & $width & "\" height=\"" &
      $height & "\" viewBox=\"0 0 " & $width & " " & $height & "\" aria-hidden=\"true\"><defs>" &
      "<marker id=\"builds-on\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" " &
      "markerHeight=\"7\" orient=\"auto\"><path d=\"M0,0 L10,5 L0,10 z\"/></marker></defs>"
  for index, proposal in undecided:
    for base in proposal.builds_on:
      for at, other in undecided:
        if other.name != base: continue
        let
          (x_from, y_from) = (xs[index], ys[index] + HEIGHT_NODE div 2)
          (x_to, y_to) = (xs[at] + WIDTH_NODE + 2, ys[at] + HEIGHT_NODE div 2)
          bend = GAP_COLUMN div 2
        result.add "<path class=\"edge\" marker-end=\"url(#builds-on)\" d=\"M" & $x_from & "," &
            $y_from & " C" & $(x_from - bend) & "," & $y_from & " " & $(x_to + bend) & "," &
            $y_to & " " & $x_to & "," & $y_to & "\"/>"
  result.add "</svg>"
  for index, proposal in undecided:
    result.add "<label class=\"node\" for=\"" & idPick(proposal) & "\" title=\"" &
        escapeHtml(proposal.citation & ": " & proposal.title.replace("`", "")) &
        "\" style=\"left: " & $xs[index] & "px; top: " & $ys[index] & "px; width: " & $WIDTH_NODE &
        "px; height: " & $HEIGHT_NODE & "px\"><b>" & escapeHtml(proposal.citation) & "</b><span>" &
        renderInline(proposal.title) & "</span></label>"
  result.add "</div>"


func bodyListing*(
  proposals: openArray[Proposal];
  evaluations: Table[string, JsonNode];
  files: Table[string, string];
  figures: Table[string, string];
  baselines: Table[string, JsonNode];
  spread: Spread;
  urls: Table[string, string];
  pin, links: string;
): string =
  ## Render list page body: header, graph, table, then every proposal behind its checkbox.

  func chipStanding(proposal: Proposal): string =
    ## Render where proposal stands as chip: proposed, implemented or withdrawn.
    if proposal.isImplemented: chip("implemented", "pass")
    elif proposal.isFrozen: chip("withdrawn", "")
    else: chip("proposed", "status")

  func chipClaims(evaluation: JsonNode): string =
    ## Render claims that hold over claims checked, as chip; failing where any fails.
    if evaluation.isNil: return chip("no evaluation", "fail")
    let
      claims = evaluation{"claims"}.getElems
      holding = claims.countIt(it{"passed"}.getBool)
    chip($holding & " of " & $claims.len & " hold", if holding == claims.len: "pass" else: "fail")

  func htmlCited(cited: seq[Proposal], urls: Table[string, string]): string =
    ## Cite proposals, each linked, or `none`.
    if cited.len == 0: "<span class=\"none\">none</span>"
    else: cited.mapIt(citeLinked(it, urls)).join(", ")

  let
    undecided = proposals.countIt(not it.isFrozen)
    graph = htmlGraph(proposals)
  result = "<div class=\"page\"><header><h1>Proposals</h1><p class=\"meta\">" &
      $proposals.len & " proposals · " & $undecided & " undecided · pga " &
      code(pin[0 ..< min(7, pin.len)]) & links & "</p><p>Each proposal is one future state of " &
      "the library, argued and measured at the pin. The Architect decides each one on its own. " &
      "A proposal needs each proposal that it depends on. A rejected proposal blocks each " &
      "proposal that depends on it.</p></header><form class=\"picks\">"
  result.add "<section class=\"block\"><h2>Undecided proposals</h2>"
  if graph.len == 0:
    result.add "<p class=\"note\">No proposal waits on a decision.</p>"
  else:
    result.add "<figure class=\"figure\"><div class=\"graph-art\">" & graph &
        "</div><figcaption>An arrow points from a proposal to one that it builds on. A " &
        "rejected proposal blocks each proposal whose arrows lead to it. Select a box to read " &
        "its proposal below.</figcaption></figure>"
  result.add "</section><section class=\"block\"><h2>Every proposal</h2><div class=\"table\">" &
      "<table class=\"proposals\"><tr><th>Read</th><th>Proposal</th><th>Standing</th>" &
      "<th>Claims</th><th>Depends on</th><th>Blocks if rejected</th></tr>"
  for proposal in proposals:
    let evaluation = evaluations.getOrDefault(proposal.name)
    result.add "<tr><td><label class=\"tick\" for=\"" & idPick(proposal) & "\" title=\"Read " &
        escapeHtml(proposal.citation) & " here\"></label></td><td>" & citeLinked(proposal, urls) &
        " " & renderInline(proposal.title) & "</td><td>" & chipStanding(proposal) & "</td><td>" &
        chipClaims(evaluation) & "</td><td>" &
        htmlCited(dependenciesOf(proposals, proposal)[0], urls) & "</td><td>" &
        htmlCited(dependentsOf(proposals, proposal), urls) & "</td></tr>"
  result.add "</table></div></section><section class=\"block readings\"><h2>Selected " &
      "proposals</h2><p class=\"note hint\">Select a proposal in the graph or the table to read " &
      "it here.</p><p><button class=\"clear\" type=\"reset\">Clear selection</button></p>"
  var rules: seq[string]
  for proposal in proposals:
    let
      id = idPick(proposal)
      url = urls.getOrDefault(proposal.name)
      page = if url.len > 0: " · <a href=\"" & escapeHtml(url) & "\">its own page</a>" else: ""
    result.add "<input class=\"pick\" type=\"checkbox\" id=\"" & id & "\"><article " &
      "class=\"reading\"><label class=\"close\" for=\"" & id & "\">Close " &
      escapeHtml(proposal.citation) & "</label>" & htmlProposal(
        proposal,
        proposals,
        evaluations.getOrDefault(proposal.name),
        files,
        figures,
        baselines,
        spread,
        urls,
        pin,
        page,
        level = 2,
      ) & "</article>"
    rules.add "body:has(#" & id & ":checked) [for=\"" & id & "\"]{--pick-on:1;" &
        "--pick-ring:var(--status);--pick-fill:var(--status-wash)}"
    rules.add "body:has(#" & id & ":focus-visible) [for=\"" & id & "\"]{outline:2px solid " &
        "var(--bound);outline-offset:2px}"
  result.add "</section></form><style>" & rules.join("") & "</style></div>"
