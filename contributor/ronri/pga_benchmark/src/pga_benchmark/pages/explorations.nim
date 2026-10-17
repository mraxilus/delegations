## Render explorations: proposals and marginalia, one tab each, under one header.
##   Explorations is one of three views of library, beside library map and gap docket
##     (`home.nim`). Proposals argue future states of library, each on page of its own;
##     marginalia hold smaller changes tried at pin, and notes on library source. Both answer
##     what to change next, so they share one page, as Architect ruled on 2026-10-17.
##   Tabs are radio inputs that `:has()` rules read, as docket's algebra tabs are; proposals tab
##     is checked at rest.

{.experimental: "strictFuncs".}

import std/sequtils

import ../proposals
import ./shell


const TABS = [("proposals", "Proposals"), ("marginalia", "Marginalia")]
  ## Name and title of each tab, in order shown; first is checked at rest.


func bodyExplorations*(
  proposals: openArray[Proposal];
  count_changes, count_notes: int;
  listing, marginalia, pin: string;
): string =
  ## Render explorations body: header with counts, tabs, then proposals and marginalia.
  let undecided = proposals.countIt(not it.isFrozen)
  result = "<div class=\"page\"><header><h1>Explorations</h1><p class=\"meta\">" &
      $proposals.len & " proposals · " & $undecided & " undecided · " & $count_changes &
      " changes · " & $count_notes & " notes · pga " & code(pin[0..<min(7, pin.len)]) &
      "</p></header><nav class=\"tabs\" aria-label=\"Explorations\">"
  for index, (name, title) in TABS:
    result.add "<label><input type=\"radio\" name=\"view\" id=\"view-" & name & "\"" &
        (if index == 0: " checked" else: "") & "> " & title & "</label>"
  result.add "</nav><section class=\"view view-proposals\">" & listing &
      "</section><section class=\"view view-marginalia\">" & marginalia & "</section><style>"
  for (name, _) in TABS:
    result.add "body:has(#view-" & name & ":checked) .view:not(.view-" & name &
        ") { display: none; }"
  result.add "</style></div>"
