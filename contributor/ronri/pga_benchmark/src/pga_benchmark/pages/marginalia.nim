## Render marginalia: library read at pin, with changes proposed to it and notes in its margin.
##   Marginalia is second monitoring page. Changes are small edits, each tried at pin and shown
##     with what its trial measured; notes are open questions and observations, each quoting
##     lines of library it is about, located where those lines stand at pin.
##   Larger explorations are designs, with pages of their own; marginalia links them rather than
##     restating them.
##
##   Cost: change without trial renders with chip saying so; `drive` refuses that state before
##     page is published, so reader never meets it.

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]

import ../[changes, markdown, notes]
import ./[shell, trial]


type Proposal* = object
  ## Define one change as marginalia shows it: name, change, and its trial where run.
  name*: string
    ## File name under `changes/`, without extension.
  change*: Change
    ## Edits and why.
  trial*: JsonNode
    ## Trial document; nil where none was run.


func marginaliaBody*(
  proposals: openArray[Proposal];
  notes: Notes;
  files: Table[string, string];
  baselines: Table[string, JsonNode];
  spread: Spread;
  pin, links: string;
): string =
  ## Render marginalia body: header, changes with trials and spread, then notes under lead.
  ##   Lead's own title is dropped, since section heading names notes already.

  func changeHtml(proposal: Proposal): string =
    ## Render one change: title, chips, then why, edits and measurements on open.
    let
      change = proposal.change
      summary = if change.why.len > 0: renderBlock(change.why[0], 2) else: ""
    result = "<details class=\"card\" id=\"change-" & escapeHtml(proposal.name) &
      "\"><summary><h3>" & renderInline(change.title) & "</h3><div class=\"chips\">" &
      verdictChips(proposal.trial, baselines, spread) & "</div>" & summary & "</summary>"
    if change.why.len > 1: result.add renderBlocks(change.why[1 .. ^1], 2)
    result.add editsHtml(change, files)
    if not proposal.trial.isNil:
      result.add functionsTable(proposal.trial) & nanTable(proposal.trial) &
        timesTable(proposal.trial, baselines, spread)
    result.add "</details>"

  func noteHtml(note: Note): string =
    ## Render one note: title, status, file and line at pin, quoted lines, body.
    let at = note.lineAt(files)
    result = "<article class=\"card note\"><h3>" & renderInline(note.title) &
      "</h3><p class=\"meta\">" & code(note.path & ":" & $at)
    if note.status.len > 0: result.add " " & chip(note.status, "status")
    result.add "</p>" & renderFence(note.quote.splitLines, "nim", at) &
      renderBlocks(note.body, 2) & "</article>"

  result = "<div class=\"page\"><header><h1>PGA Marginalia</h1><p class=\"meta\">pga " &
    code(pin[0 ..< 7]) & " · every change tried at pin, every note located at pin" & links &
    "</p></header>"
  result.add "<section class=\"block\"><h2>Changes proposed</h2><p class=\"note\">" &
    spreadText(spread) & "</p>"
  for proposal in proposals: result.add changeHtml(proposal)
  result.add "</section><section class=\"block\"><h2>Notes in the margin</h2>"
  var lead = notes.lead
  if lead.len > 0 and lead[0].kind == BlockKind.Heading and lead[0].level == 1: lead.delete(0)
  if lead.len > 0: result.add "<div class=\"prose\">" & renderBlocks(lead, 2) & "</div>"
  for note in notes.items: result.add noteHtml(note)
  result.add "</section></div>"
