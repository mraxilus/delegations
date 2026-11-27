## Hold what tag page shows against `shown.nim`, native build: tiles are verdicts reader keeps,
##   never report read back, and status of served run follows exit of child.
##   Expected tiles and statuses are written here by hand, so suite checks reading rather than
##     repeating it; `tests/browser/suite_page.nim` holds same routines in page, in Chromium.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/unittest

import ../../app/shown


suite "Internal: What tag page shows":
  test "answer wrapped in words gives each gismu kept once, gloss holding backtick whole":
    let shown = toShownAnswer("The garden is big.", "Tags: {\"tags\": [" &
        "{\"gismu\": \"purdi\", \"gloss\": \"garden\"}, {\"gismu\": \"mi\", \"gloss\": \"me\"}, " &
        "{\"gismu\": \"purdi\", \"gloss\": \"again\"}, " &
        "{\"gismu\": \"barda\", \"gloss\": \"big `one`\"}]} Done.", "m")
    check shown.pairs == @[(gismu: "purdi", gloss: "garden"), (gismu: "barda", gloss: "big `one`")]
    check shown.status == "Kept 2 gismu."  # status counts tiles, never lines of report
    check not shown.is_fail
    check shown.pairs.toCommand == "tagger tag notes/text.md purdi barda"  # one word per tile


  test "answer keeping no gismu shows no tile, no command, and failure":
    for answer in ["", "no object", "{\"tags\": [{\"gismu\": \"samtc\", \"gloss\": \"x\"}]}"]:
      let shown = toShownAnswer("text", answer, "")
      check shown.pairs.len == 0  # reader keeps none
      check shown.is_fail
      check shown.pairs.toCommand == ""
      check shown.report.len > 0  # report names why


  test "served run shows each gismu child printed, status by its exit":
    check toShownServed("purdi\nbarda\n", "r", 0).status == "Kept 2 gismu."
    check toShownServed("purdi\nbarda\n", "r", 0).pairs ==
        @[(gismu: "purdi", gloss: ""), (gismu: "barda", gloss: "")]  # child prints no gloss
    check toShownServed("", "r", 1).status == "No gismu of the list was kept; report says why."
    check toShownServed("", "r", 2).status ==
        "Suggester refused to run, with exit 2; report says why."
    for code in [1, 2]: check toShownServed("", "r", code).is_fail
    check toShownServed("", "r", 0).is_fail  # exit 0 with no gismu is still no tile
    check toShownServed("x\n", "report whole", 0).report == "report whole"


  test "span of object runs from first `{` to last `}`, else answer whole":
    check spanObject("a {b} c {d} e") == "{b} c {d}"
    check spanObject("none") == "none"
    check spanObject("{ open") == "{"
