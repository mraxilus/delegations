## Render home: one card per view of library at pin, each with its headline figure.
##   Three views answer three questions. Library map: how complete library is. Gap docket: how far
##     each operation stands from what it could spend. Explorations: what to change next.
##   Each card is link to its view; view not yet published shows its card unlinked.

{.experimental: "strictFuncs".}

import ../markdown
import ./shell


type Card* = object  ## Define one view as home shows it.
  name*, title*, url*: string
    ## Page name, title, and published URL; empty URL where page is unpublished.
  figure*, measure*, text*: string  ## Headline figure, what it counts, and what view shows.


func bodyHome*(cards: openArray[Card], pin: string): string =
  ## Render home body: header, then one card per view.
  result = "<div class=\"page\"><header><h1>PGA benchmark</h1><p class=\"meta\">pga " &
      code(pin[0..<min(7, pin.len)]) & " · three views of the library at the pin" &
      "</p><p>The library is projective geometric algebra, after Lengyel's <i>Projective " &
      "Geometric Algebra Illuminated</i>. Each view reads committed files, and each file is " &
      "held to the library at the pin.</p></header><div class=\"tiles\">"
  for card in cards:
    let inner = "<h2>" & escapeHtml(card.title) & "</h2><p class=\"headline\"><b>" &
        escapeHtml(card.figure) & "</b> " & escapeHtml(card.measure) & "</p><p>" &
        escapeHtml(card.text) & "</p>"
    result.add(
      if card.url.len > 0:
        "<a class=\"tile\" href=\"" & escapeHtml(card.url) & "\">" & inner & "</a>"
      else:
        "<div class=\"tile\">" & inner & "</div>"
    )
  result.add "</div></div>"
