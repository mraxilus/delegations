discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Markdown shapes of `markdown.nim` header, and costs it states.
##   Layout, provenance and glossary all read documents through these three, and each was
##   covered only through those checks until this file.

import std/unittest
import ../src/markdown


suite "Markdown":
  test "table rows are stripped cells, and rule under header is dropped":
    let table = "| Field | Value |\n|-------|-------|\n| Agent | Claude Code |\n"
    check table.tableRows == @[@["Field", "Value"], @["Agent", "Claude Code"]]
    check tableRows("|:---|---:|\n") .len == 0  # alignment colons still name rule
    check tableRows("no pipes here\n").len == 0
    check tableRows("| ragged |\n") == @[@["ragged"]]  # single column is table

  test "line is table row only when pipes fence it":
    check tableRows("Prose | with a pipe\n").len == 0  # neither end is pipe
    check tableRows("| opened only\n").len == 0
    check tableRows("closed only |\n").len == 0
    check tableRows("||\n") == @[@[""]]  # empty cell, not rule: rule needs dashes

  test "cost stated in header holds: cell carrying pipe splits wrongly":
    # Recorded rather than fixed, since no governed table carries one; test pins behaviour
    #   so a future parser change is a decision rather than a surprise.
    check tableRows("| a `x|y` b |\n") == @[@["a `x", "y` b"]]

  test "headings are lines opening with hash, at any depth":
    let document = "# Title\n\ntext\n\n## Section\n### Deeper\nnot # a heading\n"
    check document.headingLines == @["# Title", "## Section", "### Deeper"]
    check headingLines("  # indented\n").len == 0  # opening means column one

  test "first non-blank line skips whitespace, and empty document names nothing":
    check firstNonBlank("\n\n   \n# Title\nmore\n") == "# Title"
    check firstNonBlank("# Title\n") == "# Title"
    check firstNonBlank("").len == 0
    check firstNonBlank("\n  \n\t\n").len == 0
