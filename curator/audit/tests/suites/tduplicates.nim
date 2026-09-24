## Replicate CURATOR.md duty 10: rule written once, so no copy drifts.

import std/[sequtils, strutils, unittest]
import ../../src/duplicates


const LONG = "one two three four five six seven eight nine ten eleven twelve thirteen " &
  "fourteen fifteen sixteen seventeen eighteen nineteen twenty one two three four five"
  ## Paragraph of exactly `PARAGRAPH_WORDS` words.


suite "Duty 10":
  test "paragraphs are prose runs between blank lines, fences and tables and headings out":
    let doc = "# T\n\nfirst para\ncontinues\n\n| a |\n\n```\ncode\n```\n\nsecond\n"
    check doc.paragraphs.mapIt((it.text, it.line)) == @[("first para continues", 3), ("second", 12)]
    check paragraphs("").len == 0
    check paragraphs("  spaced   words  \n").mapIt(it.text) == @["spaced words"]  # collapsed

  test "long paragraph seen twice is finding at its later place, naming its first":
    let found = checkDuplicates([("a.md", LONG & "\n"), ("b.md", "intro\n\n" & LONG & "\n")])
    check found.len == 1
    check found[0].path == "b.md" and found[0].line == 3
    check "first at `a.md:1`" in found[0].message
    check found[0].message.endsWith("got `" & LONG[0 ..< 60] & "`.")
    check checkDuplicates([("a.md", LONG & "\n\n" & LONG & "\n")]).len == 1  # within one file

  test "short paragraph and reworded one pass":
    let short = LONG.split(' ')[0 ..< PARAGRAPH_WORDS - 1].join(" ")
    check checkDuplicates([("a.md", short & "\n"), ("b.md", short & "\n")]).len == 0
    check checkDuplicates([("a.md", LONG & "\n"), ("b.md", LONG & " more\n")]).len == 0
