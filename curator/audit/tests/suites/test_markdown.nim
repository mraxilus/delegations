## Replicate Markdown shapes of `markdown.nim` header, and costs it states.
##   Layout, provenance and glossary all read documents through these three, so each is held
##   here directly, not only through those checks.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/markdown



suite "Markdown":
  test "table rows are stripped cells, and rule under header is dropped":
    let table = "| Field | Value |\n|-------|-------|\n| Agent | Claude Code |\n"
    check table.rowsTable == @[@["Field", "Value"], @["Agent", "Claude Code"]]
    check rowsTable("|:---|---:|\n") .len == 0  # alignment colons still name rule
    check rowsTable("no pipes here\n").len == 0
    check rowsTable("| ragged |\n") == @[@["ragged"]]  # single column is table


  test "line is table row only when pipes fence it":
    check rowsTable("Prose | with a pipe\n").len == 0  # neither end is pipe
    check rowsTable("| opened only\n").len == 0
    check rowsTable("closed only |\n").len == 0
    check rowsTable("||\n") == @[@[""]]  # empty cell, not rule: rule needs dashes


  test "cost stated in header holds: cell carrying pipe splits wrongly":
    # Recorded rather than fixed, since no governed table carries one; test pins behaviour
    #   so later parser change is decision rather than surprise.
    check rowsTable("| a `x|y` b |\n") == @[@["a `x", "y` b"]]


  test "headings are lines opening with hash, at any depth":
    let document = "# Title\n\ntext\n\n## Section\n### Deeper\nnot # a heading\n"
    check document.linesHeading == @["# Title", "## Section", "### Deeper"]
    check linesHeading("  # indented\n").len == 0  # opening means column one


  test "first non-blank line skips whitespace, and empty document names nothing":
    check firstNonBlank("\n\n   \n# Title\nmore\n") == "# Title"
    check firstNonBlank("# Title\n") == "# Title"
    check firstNonBlank("").len == 0
    check firstNonBlank("\n  \n\t\n").len == 0


  test "fenced code is blanked, fences included, and line count is kept":
    let document = "one\n```nim\n## not a heading\n```\n## Section\n"
    check document.fencedOut == "one\n\n\n\n## Section\n"  # example gone, lines kept
    check document.fencedOut.linesHeading == @["## Section"]  # composes with readers
    check fencedOut("a\r\n```\r\nb\r\n") == "a\r\n\r\n\r\n"  # open fence blanks to end; CRLF kept
    check fencedOut("  ```\n  x\n  ```\ny\n") == "\n\n\ny\n"  # indented fence
    check fencedOut("plain\n") == "plain\n"


  test "document cuts at each `##` line outside fence, and its parts give it back whole":
    # Stamp digests parts it keeps, so cut that lost or moved one byte would move every stamp.
    let
      document = "# Title\n\nOpening.\n\n## One\n\n```md\n## Quoted\n```\n\n### Deeper\n" &
        "## Two\r\nEnd.\r\n"
      parts = document.sections
    check parts.mapIt(it.heading) == @["", "## One", "## Two"]  # quoted heading opens none
    check parts.mapIt(it.text).join == document  # byte for byte, CRLF included
    check parts[0].text == "# Title\n\nOpening.\n\n"  # opening is its own part
    check "## Quoted" in parts[1].text and "### Deeper" in parts[1].text  # both stay inside
    check "## One\n".sections.mapIt(it.heading) == @["", "## One"]  # opening may be empty
    check "".sections.mapIt(it.text) == @[""]  # empty document is one empty part
    check "##Two\n#### Three\n".sections.len == 1  # `##` alone, then space, opens part
