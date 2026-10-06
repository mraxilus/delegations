## Replicate provenance guide's body shape and Article VIII.6: record describes what is.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/record
import ./fixtures


func messages(source: string): seq[string] =
  ## Read finding messages of record text.
  checkRecord("p/PROVENANCE.md", source).mapIt(it.message)


const BODY = "\n## Design\n\nWhat is.\n\n## Open questions\n\nNone.\n"
  ## Smallest body guide accepts: subsystem section, then open questions last.



suite "Article VIII":
  test "VIII.6 record in guide's shape passes":
    check messages(textProvenance("deadbeefdeadbeef") & BODY).len == 0
    check messages(textProvenance("deadbeefdeadbeef") & "\n## Design\n\nWhat is.\n").len == 0


  test "VIII.6 no section is headed by date":
    let
      dated = textProvenance("d") & "\n## Design\n\n## Re-audit, 2026-09-06\n\nDone.\n"
      found = checkRecord("p", dated)
    check found.len == 1 and found[0].line == 14  # line of heading named
    check found[0].message.endsWith("got `## Re-audit, 2026-09-06`.")
    check messages(textProvenance("d") & "\n## Design\n\nDone 2026-09-06.\n").len == 0  # prose
    check "x 2026-09-06 y".isDated and not "12026-09-06".isDated  # bounded by non-digit
    check not "2026-9-6".isDated and not "".isDated


  test "VIII.6 open questions is last section":
    let
      early = textProvenance("d") & "\n## Open questions\n\nOne.\n\n## Design\n\nWhat is.\n"
      found = checkRecord("p", early)
    check found.len == 1 and found[0].line == 12  # open questions' own line
    check found[0].message.endsWith("got section at line `16` after it.")
    check messages(textProvenance("d") & BODY & "\n### Deeper\n\nStill inside.\n").len == 0
    check messages(textProvenance("d") & "\n## OPEN QUESTIONS\n\n## Design\n").len == 1  # case


  test "VIII.6 no heading appears twice":
    let
      twice = textProvenance("d") & "\n## Design\n\n## Design\n"
      found = checkRecord("p", twice)
    check found.len == 1 and found[0].line == 14  # second occurrence named
    check found[0].message == "Heading appears twice; got `## Design`."
    let fenced = textProvenance("d") & "\n## Design\n\n```nim\n## Design\n```\n"
    check messages(fenced).len == 0  # heading inside fence is example


  test "VIII.6 heading is ATX, never underlined":
    let
      setext = textProvenance("d") & "\nDesign\n---\n\nWhat is.\n"
      found = checkRecord("p", setext)
    check found.len == 1 and found[0].line == 12
    check found[0].message.endsWith("write `## Design`.")
    let title = textProvenance("d") & "\nProvenance\n===\n\nWhat is.\n"
    check messages(title) ==
      @["Heading is underlined, which no reader here sees; write `# Provenance`."]
    check messages(textProvenance("d") & "\nText.\n\n---\n\nMore.\n").len == 0  # rule after blank
    check messages(textProvenance("d") & "\n| a | b |\n|---|---|\n").len == 0  # table rule


  test "VIII.6 record over ceiling asks for prune and Pruned row":
    # Spread body over sections short enough that section ceiling stays quiet.
    var body = ""
    for i in 0 ..< LINES_RECORD div LINES_SECTION + 1:
      body.add "\n## Design " & $i & "\n" & "line\n".repeat(LINES_SECTION - 1)
    let
      long = textProvenance("d") & body
      found = checkRecord("p", long)
    check found.len == 1
    check found[0].message.startsWith("Record over " & $LINES_RECORD & " lines; prune to log")
    check found[0].message.endsWith("got `" & $(long.count('\n')) & "`.")  # as wc -l counts
    check messages(textProvenance("d") & "line\n".repeat(LINES_SECTION - 10)).len == 0


  test "VIII.6 section over ceiling asks for prune or split":
    let
      wide = textProvenance("d") & "\n## Body sim\n" & "line\n".repeat(LINES_SECTION + 1)
      found = checkSections("p", wide)
    check found.len == 1
    check found[0].message ==
      "Section over " & $LINES_SECTION & " lines; prune to log or split it (provenance " &
        "guide); got `" & $(LINES_SECTION + 1) & "`."
    check found[0].line == wide.splitLines.find("## Body sim") + 1  # heading, not overflow
    # Same body, split in two, passes: ceiling is on section and not on record.
    let split = textProvenance("d") & "\n## One\n" & "line\n".repeat(LINES_SECTION - 1) &
      "\n## Two\n" & "line\n".repeat(LINES_SECTION - 1)
    check checkSections("p", split).len == 0
    let fenced = textProvenance("d") & "\n## Listing\n```\n" &
      "## Design\n".repeat(LINES_SECTION + 1) & "```\n"
    check checkSections("p", fenced).len == 1  # heading inside fence opens no section


  test "VIII.6 Pruned row names commit as hex":
    let with_row = textProvenance("d").replace("| Review |", "| Pruned | c723ede |\n| Review |")
    check messages(with_row & BODY).len == 0
    check with_row.prunedOf == "c723ede"
    check textProvenance("d").prunedOf.len == 0  # absent row
    check messages(with_row.replace("c723ede", "main") & BODY) ==
      @["`Pruned` must name commit as 7 to 40 hex digits; got `main`."]
    check "c723ede".isIdCommit and "c723ede1d0fd6f5e01b6b4d5c2ea8c1f9b2a3d4e".isIdCommit
    check not "c723ed".isIdCommit and not "C723EDE".isIdCommit  # short, upper


  test "count written as number in prose goes stale, and is finding":
    # Count goes stale by next commit and nothing reads it again (provenance guide).
    check checkCounts("p/PROVENANCE.md", "Suite holds 12 suites.\n").mapIt(it.message) ==
      @["Count is never number in prose; name command that counts (provenance guide); got " &
        "`12 suites`."]
    check checkCounts("p/PROVENANCE.md", "Run `koch test`; it lists suites.\n").len == 0
    check checkCounts("p/PROVENANCE.md", "Command prints `12 files`.\n").len == 0  # code span
    check checkCounts("p/PROVENANCE.md", "```text\n12 files\n```\n").len == 0  # fenced output
    check checkCounts("p/PROVENANCE.md", "Took 22.8 s for 4 cores.\n").len == 0  # not counted
