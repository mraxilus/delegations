discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate provenance guide's body shape and Article VIII.6: record describes what is.

import std/[sequtils, strutils, unittest]
import ../src/record
import ./fixtures


func messages(source: string): seq[string] =
  ## Read finding messages of record text.
  checkRecord("p/PROVENANCE.md", source).mapIt(it.message)


const BODY = "\n## Design\n\nWhat is.\n\n## Open questions\n\nNone.\n"
  ## Smallest body guide accepts: subsystem section, then open questions last.


suite "Article VIII":
  test "VIII.6 record in guide's shape passes":
    check messages(provenanceText("deadbeefdeadbeef") & BODY).len == 0
    check messages(provenanceText("deadbeefdeadbeef") & "\n## Design\n\nWhat is.\n").len == 0

  test "VIII.6 no section is headed by date":
    let dated = provenanceText("d") & "\n## Design\n\n## Re-audit, 2026-09-06\n\nDone.\n"
    let found = checkRecord("p", dated)
    check found.len == 1 and found[0].line == 14  # line of heading named
    check found[0].message.endsWith("got `## Re-audit, 2026-09-06`.")
    check messages(provenanceText("d") & "\n## Design\n\nDone 2026-09-06.\n").len == 0  # prose
    check "x 2026-09-06 y".hasIsoDate and not "12026-09-06".hasIsoDate  # bounded by non-digit
    check not "2026-9-6".hasIsoDate and not "".hasIsoDate

  test "VIII.6 open questions is last section":
    let early = provenanceText("d") & "\n## Open questions\n\nOne.\n\n## Design\n\nWhat is.\n"
    let found = checkRecord("p", early)
    check found.len == 1 and found[0].line == 12  # open questions' own line
    check found[0].message.endsWith("got section at line 16 after it.")
    check messages(provenanceText("d") & BODY & "\n### Deeper\n\nStill inside.\n").len == 0
    check messages(provenanceText("d") & "\n## OPEN QUESTIONS\n\n## Design\n").len == 1  # case

  test "VIII.6 no heading appears twice":
    let twice = provenanceText("d") & "\n## Design\n\n## Design\n"
    let found = checkRecord("p", twice)
    check found.len == 1 and found[0].line == 14  # second occurrence named
    check found[0].message == "Heading appears twice; got `## Design`."
    let fenced = provenanceText("d") & "\n## Design\n\n```nim\n## Design\n```\n"
    check messages(fenced).len == 0  # heading inside fence is example

  test "VIII.6 heading is ATX, never underlined":
    let setext = provenanceText("d") & "\nDesign\n---\n\nWhat is.\n"
    let found = checkRecord("p", setext)
    check found.len == 1 and found[0].line == 12
    check found[0].message.endsWith("write `## Design`.")
    check messages(provenanceText("d") & "\nText.\n\n---\n\nMore.\n").len == 0  # rule after blank
    check messages(provenanceText("d") & "\n| a | b |\n|---|---|\n").len == 0  # table rule

  test "VIII.6 record over ceiling asks for prune and Pruned row":
    let long = provenanceText("d") & "\n## Design\n" & "line\n".repeat(RECORD_LINES)
    let found = checkRecord("p", long)
    check found.len == 1
    check found[0].message.startsWith("Record over " & $RECORD_LINES & " lines; prune to log")
    check found[0].message.endsWith("got " & $(long.count('\n')) & ".")  # as wc -l counts
    check messages(provenanceText("d") & "line\n".repeat(RECORD_LINES - 10)).len == 0

  test "VIII.6 Pruned row names commit as hex":
    let with_row = provenanceText("d").replace(
      "| Review |", "| Pruned | c723ede |\n| Review |"
    )
    check messages(with_row & BODY).len == 0
    check with_row.prunedOf == "c723ede"
    check provenanceText("d").prunedOf.len == 0  # absent row
    check messages(with_row.replace("c723ede", "main") & BODY) ==
      @["`Pruned` must name commit as 7 to 40 hex digits; got `main`."]
    check "c723ede".isCommitId and "c723ede1d0fd6f5e01b6b4d5c2ea8c1f9b2a3d4e".isCommitId
    check not "c723ed".isCommitId and not "C723EDE".isCommitId  # short, upper
