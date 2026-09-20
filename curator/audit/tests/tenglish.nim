discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article VI.8: governed prose is Simplified Technical English.

import std/[sequtils, strutils, unittest]
import ../src/english


suite "Article VI.8":
  test "sentence ends at stop after letter or closing bracket":
    check isSentenceEnd("plainly.")
    check isSentenceEnd("(Article VI.5).")
    check isSentenceEnd("ready?")
    check isSentenceEnd("**now.**")
    check isSentenceEnd("**now**.")  # stop outside emphasis
    check isSentenceEnd("551.")  # figure closes sentence
    check not isSentenceEnd("2.2.12")  # version carries no stop
    check not isSentenceEnd("word")
    check not isSentenceEnd("VI.5")  # clause number inside sentence

  test "backticked span counts as one word, however it wraps":
    check "run `nim r koch ci` now".spansCollapsed == "run name now"
    check "run `nim r koch ci` now".spansCollapsed.splitWhitespace.len == 3
    check "Run `nim r\nkoch ci` now.".blocks[0].text == "Run name now."  # span over line end

  test "list item and run of plain lines are separate blocks":
    let document = "# H\n\nOne line.\nSame block.\n\n- First item.\n- Second item.\n"
    let found = document.blocks
    check found.len == 3
    check found[0].text == "One line. Same block."
    check found.mapIt(it.line) == @[3, 6, 7]
    check found[1].text == "First item."  # marker dropped
    check markerLen("1. Numbered.") == 3
    check "> One quoted line.\n> And second.".blocks[0].text == "One quoted line. And second."

  test "fenced code, table row, heading and front matter carry no prose":
    let document = "---\nname: Queued work\n---\n\n| a | b |\n\n```\nutilise this\n```\n"
    check document.blocks.len == 0

  test "long sentence, long paragraph and unapproved word are findings":
    let long_sentence = "word ".repeat(SENTENCE_WORDS + 1) & "end."
    var found = checkEnglish("GUIDE.md", long_sentence)
    check found.len == 1
    check found[0].message.startsWith("Sentence must hold at most")
    let long_paragraph = "Stop. ".repeat(PARAGRAPH_SENTENCES + 1)
    found = checkEnglish("GUIDE.md", long_paragraph)
    check found.len == 1
    check found[0].message.endsWith("got `" & $(PARAGRAPH_SENTENCES + 1) & "`.")
    found = checkEnglish("GUIDE.md", "Ensure it passes.")
    check found.len == 1
    check found[0].message == "Word is outside approved dictionary; write `make sure` " &
      "(ASD-STE100); got `ensure`."

  test "word matches whole, without case, and through punctuation":
    check checkEnglish("GUIDE.md", "Do this prior to that.").len == 1
    check checkEnglish("GUIDE.md", "Read it, e.g. twice.").len == 1
    check checkEnglish("GUIDE.md", "Via `main`, then.").len == 1
    check checkEnglish("GUIDE.md", "Nothing is viable here.").len == 0  # whole word only
    check checkEnglish("GUIDE.md", "Write `ensure` in code.").len == 0  # span is one name

  test "document outside governed list passes":
    let prose = "Ensure " & "word ".repeat(SENTENCE_WORDS + 1) & "end."
    check checkEnglish("contributor/ronri/rga_visualiser/PROVENANCE.md", prose).len == 0
    check checkEnglish("LICENSE.md", prose).len == 0
