## Replicate Article VI.8: governed prose is Simplified Technical English.

{.experimental: "strictFuncs".}

import std/[sequtils, sets, strutils, unittest]
import ../../src/[domains, english, findings, layout]
import ./fixtures



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
    check "run `nim r koch check` now".spansCollapsed == "run name now"
    check "run `nim r koch check` now".spansCollapsed.splitWhitespace.len == 3
    check "Run `nim r\nkoch check` now.".blocks[0].text == "Run name now."  # span over line end


  test "list item and run of plain lines are separate blocks":
    let
      document = "# H\n\nOne line.\nSame block.\n\n- First item.\n- Second item.\n"
      found = document.blocks
    check found.len == 3
    check found[0].text == "One line. Same block."
    check found.mapIt(it.line) == @[3, 6, 7]
    check found[1].text == "First item."  # marker dropped
    check markerLen("1. Numbered.") == 3


  test "quotation is skipped whole":
    check "> One quoted line.\n> And second.".blocks.len == 0  # another author's words
    let cited = "> " & "word ".repeat(WORDS_SENTENCE + 1) & "end."
    check checkEnglish("GUIDE.md", cited).len == 0
    check checkEnglish("GUIDE.md", "> Ensure it passes.").len == 0
    check checkEnglish("GUIDE.md", "Ensure it passes.").len == 1  # same words, unquoted


  test "fenced code, table row, heading and front matter carry no prose":
    let document = "---\nname: Queued work\n---\n\n| a | b |\n\n```\nutilise this\n```\n"
    check document.blocks.len == 0


  test "long sentence, long paragraph and unapproved word are findings":
    let sentence_long = "word ".repeat(WORDS_SENTENCE + 1) & "end."
    var found = checkEnglish("GUIDE.md", sentence_long)
    check found.len == 1
    check found[0].brief.startsWith("sentence must hold at most")
    let paragraph_long = "Stop. ".repeat(SENTENCES_PARAGRAPH + 1)
    found = checkEnglish("GUIDE.md", paragraph_long)
    check found.len == 1
    check found[0].brief.endsWith(
      "got `" & $(SENTENCES_PARAGRAPH + 1) & "`; expect `at most " & $SENTENCES_PARAGRAPH &
        "`; help: split it",
    )
    check found[0].rule == "koch.paragraph-length"
    found = checkEnglish("GUIDE.md", "Ensure it passes.")
    check found.len == 1
    check found[0].brief ==
      "word is outside approved dictionary (ASD-STE100); got `ensure`; expect `make sure`"
    check found[0].rule == "koch.approved-word"


  test "word matches whole, without case, and through punctuation":
    check checkEnglish("GUIDE.md", "Do this prior to that.").len == 1
    check checkEnglish("GUIDE.md", "Read it, e.g. twice.").len == 1
    check checkEnglish("GUIDE.md", "Via `main`, then.").len == 1
    check checkEnglish("GUIDE.md", "Nothing is viable here.").len == 0  # whole word only
    check checkEnglish("GUIDE.md", "Write `ensure` in code.").len == 0  # span is one name


  test "governed set derives records and index READMEs from layout":
    check isGoverned("CONSTITUTION.md")  # root document, still data
    check isGoverned("COORDINATOR.md") and isGoverned(".github/ISSUE_TEMPLATE/brief.md")
    check isGoverned("curator/README.md")  # project root index
    check isGoverned("contributor/README.md")
    check isGoverned("contributor/abstand/README.md")  # registered domain index
    check isGoverned("curator/audit/PROVENANCE.md")  # record of project that exists
    check isGoverned("contributor/ronri/pga_visualiser/GLOSSARY.md")


  test "every root Markdown document but licence is governed, entry file among them":
    # Record holds that `PATHS_ENGLISH` lists each one, and root document it leaves out passes
    #   unread; entry file would, though each harness reads it first. Domain: `FILES_ROOT`.
    for path in FILES_ROOT:
      if path.endsWith(".md"): check path.isGoverned == (path != "LICENSE.md")
    check isGoverned("AGENTS.md")  # entry file


  test "project and domain added later are governed from their first line":
    check isGoverned("curator/newcomer/README.md")  # no such project today
    check isGoverned("curator/newcomer/PROVENANCE.md")
    check isGoverned("contributor/abstand/newcomer/GLOSSARY.md")
    check not isGoverned("contributor/nowhere/README.md")  # domain outside registry


  test "changed line inside prose block owns line that block opens on":
    let markdown = "# Title\n\nFirst line of paragraph\nsecond line.\n\n- item one\n- item two\n"
    check linesOpening(markdown, [4].toHashSet) == [3, 4].toHashSet  # paragraph opens on 3
    check linesOpening(markdown, [7].toHashSet) == [7].toHashSet  # list item stands alone
    check linesOpening(markdown, [2].toHashSet) == [2].toHashSet  # blank line opens nothing


  test "prose below project directory stays outside governed set":
    check not isGoverned("contributor/sincopa/dance_ontology/sim/README.md")  # nested, not yet
    check not isGoverned("curator/audit/tests/README.md")
    check not isGoverned("contributor/ronri/pga_benchmark/gaps.md")  # generated
    check not isGoverned("LICENSE.md")
    check not isGoverned("koch.nim")


  test "derived path is read, and not merely listed":
    let prose = "Ensure " & "word ".repeat(WORDS_SENTENCE + 1) & "end."
    check checkEnglish("curator/README.md", prose).len == 2  # word, then sentence
    check checkEnglish("contributor/abstand/newcomer/README.md", prose).len == 2
    check checkEnglish("contributor/sincopa/dance_ontology/sim/README.md", prose).len == 0


  test "record of project keeping its own prose is read by no rule of English":
    # Case: records of `lojban_parser` move to lojban, by ruling `D4 a` of #818; lojban closes no
    #   sentence with stop, so its paragraph reads as one sentence past `WORDS_SENTENCE`. Domain:
    #   each record of listed project, each of project list leaves out in same domain, its index.
    check findingsEnglish("x.md", PROSE_LOJBAN).mapIt(it.brief) == @[
      "sentence must hold at most 25 words (ASD-STE100); got " &
        "`mi klama le zarci .i do klama le ...`; help: split it",
    ]  # what check reads in lojban
    check findingsEnglish("x.md", PROSE_LOJBAN).anyIt(it.rule == "koch.sentence-length")
    for file in FILES_PROJECT:
      check not isGoverned(DIRECTORY_PARSER & "/" & file)  # listed project
      check checkEnglish(DIRECTORY_PARSER & "/" & file, PROSE_LOJBAN).len == 0
      let tagger = DIRECTORY_TAGGER & "/" & file
      check isGoverned(tagger) and checkEnglish(tagger, PROSE_LOJBAN).len == 1  # left out
    check isGoverned(CONTRIBUTOR & "/bangu/README.md")  # domain index stays English
