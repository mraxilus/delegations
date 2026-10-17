## Render marginalia tab of explorations: changes tried on library at pin, and notes in its margin.
##   Changes are small edits, each tried at pin and shown with what its evaluation measured; notes
##     are open questions and observations, each quoting lines of library it is about, located
##     where those lines stand at pin.
##   Larger explorations are proposals, in tab beside this one and on pages of their own;
##     marginalia links them rather than restating them.
##
##   Cost: change without evaluation renders with chip saying so; `drive` refuses that state before
##     page is published, so reader never meets it.

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]

import ../[changes, markdown, notes]
import ./[evaluation, shell]


type ChangeEvaluated* = object
  ## Define one change as marginalia shows it: name, change, and its evaluation where run.
  name*: string  ## File name under `changes/`, without extension.
  change*: Change  ## Edits and why.
  evaluation*: JsonNode  ## Evaluation document; nil where none was run.


func htmlMarginalia*(
  changes_evaluated: openArray[ChangeEvaluated];
  notes: Notes;
  files: Table[string, string];
  baselines: Table[string, JsonNode];
  spread: Spread;
): string =
  ## Render marginalia tab: changes with evaluations and spread, then notes under lead.
  ##   Lead's own title is dropped, since section heading names notes already.

  func htmlChange(change_evaluated: ChangeEvaluated): string =
    ## Render one change: title, chips, then why, edits and measurements on open.
    let
      change = change_evaluated.change
      summary = if change.why.len > 0: renderBlock(change.why[0], 2) else: ""
    result = "<details class=\"card\" id=\"change-" & escapeHtml(change_evaluated.name) &
        "\"><summary><h3>" & renderInline(change.title) & "</h3><div class=\"chips\">" &
        chipsVerdict(change_evaluated.evaluation, baselines, spread) & "</div>" & summary &
        "</summary>"
    if change.why.len > 1: result.add renderBlocks(change.why[1 .. ^1], 2)
    result.add htmlEdits(change, files)
    if not change_evaluated.evaluation.isNil:
      let evaluation = change_evaluated.evaluation
      result.add tableFunctions(evaluation) & tableNan(evaluation) &
          tableTimes(evaluation, baselines, spread)
    result.add "</details>"

  func htmlNote(note: Note): string =
    ## Render one note: title, status, file and line at pin, quoted lines, body.
    let at = note.lineAt(files)
    result = "<article class=\"card note\"><h3>" & renderInline(note.title) &
        "</h3><p class=\"meta\">" & code(note.path & ":" & $at)
    if note.status.len > 0: result.add " " & chip(note.status, "status")
    result.add "</p>" & renderFence(note.quote.splitLines, "nim", at) &
        renderBlocks(note.body, 2) & "</article>"

  result = "<p class=\"lead\">Each change is a small edit to the library, tried at the pin. " &
      "Each note is a question or an observation, located where its lines stand at the pin." &
      "</p><section class=\"block\"><h2>Changes proposed</h2><p class=\"note\">" &
      textSpread(spread) & "</p>"
  for change_evaluated in changes_evaluated: result.add htmlChange(change_evaluated)
  result.add "</section><section class=\"block\"><h2>Notes in the margin</h2>"
  var lead = notes.lead
  if lead.len > 0 and lead[0].kind == KindBlock.Heading and lead[0].level == 1: lead.delete(0)
  if lead.len > 0: result.add "<div class=\"prose\">" & renderBlocks(lead, 2) & "</div>"
  for note in notes.items: result.add htmlNote(note)
  result.add "</section>"
