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


func changeHtml(
  p: Proposal, files: Table[string, string], baselines: Table[string, JsonNode], band: Band
): string =
  ## Render one change: title, chips, then why, edits and measurements on open.
  let summary = if p.change.why.len > 0: renderBlock(p.change.why[0], 2) else: ""
  result = "<details class=\"card\" id=\"change-" & escapeHtml(p.name) & "\"><summary><h3>" &
    renderInline(p.change.title) & "</h3><div class=\"chips\">" &
    verdictChips(p.trial, baselines, band) & "</div>" & summary & "</summary>"
  if p.change.why.len > 1: result.add renderBlocks(p.change.why[1 .. ^1], 2)
  result.add editsHtml(p.change, files)
  if not p.trial.isNil:
    result.add functionsTable(p.trial) & nanTable(p.trial) & timesTable(p.trial, baselines, band)
  result.add "</details>"


func noteHtml(note: Note, files: Table[string, string]): string =
  ## Render one note: title, status, file and line at pin, quoted lines, body.
  let at = note.lineAt(files)
  result = "<article class=\"card note\"><h3>" & renderInline(note.title) &
    "</h3><p class=\"meta\">" & code(note.path & ":" & $at)
  if note.status.len > 0: result.add " " & chip(note.status, "status")
  result.add "</p>" & renderFence(note.quote.splitLines, "nim", at) & renderBlocks(note.body, 2) &
    "</article>"


func marginaliaBody*(
  proposals: openArray[Proposal];
  notes: Notes;
  files: Table[string, string];
  baselines: Table[string, JsonNode];
  band: Band;
  pin, links: string;
): string =
  ## Render marginalia body: header, changes with trials and band, then notes under their lead.
  ##   Lead's own title is dropped, since section heading names notes already.
  result = "<div class=\"page\"><header><h1>PGA Marginalia</h1><p class=\"meta\">pga " &
    code(pin[0 ..< 7]) & " · every change tried at pin, every note located at pin" & links &
    "</p></header>"
  result.add "<section class=\"block\"><h2>Changes proposed</h2><p class=\"note\">" &
    bandText(band) & "</p>"
  for p in proposals: result.add changeHtml(p, files, baselines, band)
  result.add "</section><section class=\"block\"><h2>Notes in the margin</h2>"
  var lead = notes.lead
  if lead.len > 0 and lead[0].kind == BlockKind.Heading and lead[0].level == 1: lead.delete(0)
  if lead.len > 0: result.add "<div class=\"prose\">" & renderBlocks(lead, 2) & "</div>"
  for note in notes.items: result.add noteHtml(note, files)
  result.add "</section></div>"
