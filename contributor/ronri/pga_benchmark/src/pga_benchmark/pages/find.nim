## Filter docket rows by search box; compiled to JavaScript and embedded in docket page.
##   Only DOM wiring lives here; rule is `search.isFound`, which suites run natively.
##   Runs once at load too, since browser may restore typed text.
##
##   Cost: JavaScript backend brings its runtime into page, 27 KiB under `-d:release`; source
##     stays Nim, so compiler checks script as it checks rest (Article II.9).

{.experimental: "strictFuncs".}

import std/dom

import ./search


proc filter(event: Event) =
  ## Hide each row whose words lack word typed, by class `unfound`.
  let typed = $InputElement(document.getElementById("find")).value
  for row in document.querySelectorAll("details.row"):
    if isFound($row.getAttribute("data-find"), typed): row.classList.remove("unfound")
    else: row.classList.add("unfound")


document.getElementById("find").addEventListener("input", filter)
filter(nil)
