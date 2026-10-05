## Drive mark workbench's build under testament: every gate, every page written and read back.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, unittest]

import ../../design/[marks, parts, plain, rig_page]
import ../../tools/title


const OUT = "build/design"  ## Where pages land; ignored by git, created here.

const SMALL = ["a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into",
               "nor", "of", "on", "or", "over", "so", "the", "to", "up", "with", "yet"]
  ## Words title case leaves lowercase where they fall inside title.

func isTitleCased(title: string): bool =
  ## Whether title reads in title case: every word capitalised but small ones inside it.
  ##   Read off words rather than off whole, so hyphenated word passes on its first letter
  ##     as `Hand-to-Hand` does, and punctuation decides nothing.
  let words = title.split(' ')
  for i, word in words:
    let bare = word.strip(chars = {',', '.', ':', ';', '!', '?'})
    if bare.len == 0 or bare[0].isUpperAscii: continue
    if i > 0 and i < words.high and bare.toLowerAscii in SMALL: continue
    return false
  true

func titleOf(page: string): string =
  ## Page's own name, after work's name and its dash.
  let opens = page.find("<title>")
  doAssert opens >= 0, "Page carries no title."
  let shuts = page.find("</title>", opens)
  page[opens+"<title>".len..<shuts].split(" \u2014 ")[^1]

func pageIndex(name: string): int =
  ## Index of page `name` in `PAGES`, which builds it.
  for i in 0..<PAGES.len:
    if PAGES[i].name == name: return i
  raiseAssert "No page of workbench by that name; got `" & name & "`."

template holdPage(name: string) =
  ## Build page `name` of `PAGES`, write it, and hold what it wrote to every gate.
  ##   Template, not routine, so each `check` fails law that holds it.
  createDir(OUT)
  buildPage(pageIndex(name), OUT)
  let written = readFile(OUT / name)
  check written.len > 0  # written and read back (IX.5)
  # Every page workbench writes is exploration, so every one carries mockup form and
  # none carries plain one: reader tells stood-behind page from mock-up before opening
  # either.  Asserted against constant, so title cannot drift while test still passes.
  check "<title>" & MOCKUP & " — " in written
  check "<title>" & WORK & " — " notin written
  # Every published title reads in title case, so published set is one consistent
  # form.  Nothing checked it until viewer page shipped with sentence for title
  # while every page beside it was cased.
  check isTitleCased(titleOf(written))
  # Rule 26 ranks move's stages, and markup can only rank them through
  # `keyTimes`: without it browser spreads frames evenly, so turn, settle and
  # reset all read at one speed.  Every animated element carries its own
  # clock, on every page, or none of that ranking survives being written out.
  check written.count("<animate") == written.count("keyTimes=")
  # Prose on every page follows Simplified Technical English (Article VI.8), and two of
  # its rules can be counted: sentence's words and paragraph's sentences.  Read here
  # because page's prose is written by hand, so nothing else can hold it.  Failure names
  # sentence to split, since rule is about that sentence and not about page.
  for said in written.longSentences:
    checkpoint "sentence over " & $WORDS & " words: " & said
    fail()
  for said in written.longParagraphs:
    checkpoint "paragraph over " & $SENTENCES & " sentences, opening: " & said
    fail()



suite "Internal: Mark workbench":
  test "frames.html":
    holdPage("frames.html")


  test "signs.html":
    holdPage("signs.html")


  test "turns-single.html":
    holdPage("turns-single.html")


  test "turns-hands.html":
    holdPage("turns-hands.html")


  test "review.html":
    holdPage("review.html")


  test "every page the workbench writes has a law of its own":
    ## Each law above names its page by literal, so review page's count reads it
    ##   (`tools/review.nim`), where one law named at run time hid one law for each page.
    ##   Laws are read off this file, as that count reads them, and held to `PAGES`, so
    ##   page added there cannot go unbuilt here.
    var held: seq[string]
    for line in readFile(currentSourcePath()).splitLines:
      let opening = line.strip
      if opening.startsWith("holdPage(\"") and opening.endsWith("\")"):
        held.add opening["holdPage(\"".len..<opening.len-"\")".len]
    var pages: seq[string]
    for page in PAGES: pages.add page.name
    check held == pages



suite "Internal: Every page this project publishes":
  test "viewer's title reads in title case, as every other does":
    ## Viewer is written by its own module rather than by workbench above, so its title is
    ## held here against same reading rather than left as only one nothing checks.
    check isTitleCased(TITLE)


  test "committed markup says its prose plainly too":
    ## Whole-cloth mock-up is hand-authored file rather than page workbench renders, so its
    ## prose is held here.  Reference page's own markup is held by `test_review.nim`, beside
    ## build that fills it.
    let markup = readFile("mockups" / "wholecloth.html")
    check markup.prose.len > 0
    for said in markup.longSentences:
      checkpoint "sentence over " & $WORDS & " words: " & said
      fail()
    for said in markup.longParagraphs:
      checkpoint "paragraph over " & $SENTENCES & " sentences, opening: " & said
      fail()



suite "Internal: The sixteen facings, drawn":
  # Glossary agrees sixteen facings, and model holds them (`rotation.Facing`).  Pages draw
  # them from model, so every name below comes from model, never from page it checks.
  test "the frame page draws each facing once, under its own name":
    let page = readFile(OUT / "frames.html")
    for named in Facing:
      check page.count("<figcaption>" & named.name & "</figcaption>") == 1
      # Name capitalises lead's side alone, so no header that capitalises names one.
      check page.count("<th>" & named.name) == 0


  test "the frame page gives each side of the lead a row, in the glossary's order":
    # Name gives lead's side first, so row for each side reads down page as names do.
    let page = readFile(OUT / "frames.html")
    var at = page.find("<h3>At rest, no ring</h3>")
    check at >= 0
    if at >= 0:
      for side in ["Face", "Starboard", "Back", "Port"]:
        at = page.find("<div class=\"row\">", at)
        let shuts = page.find("</div>", at)
        var
          captions: seq[string]
          caption_at = page.find("<figcaption>", at)
        while caption_at >= 0 and caption_at < shuts:
          let start = caption_at + "<figcaption>".len
          captions.add page[start..<page.find("</figcaption>", start)]
          caption_at = page.find("<figcaption>", start)
        check captions.len == 4
        for caption in captions:
          check caption.startsWith(side & "-to-")
        at = shuts


  test "each drawn facing reads back as the facing it is named for":
    for named, orientation in ORIENTATIONS:
      check turnedFacing(orientation.lead_turn, orientation.follow_turn) == some(named)


  test "every quarter the single-hand page draws names its facing, in its own place":
    # Read within each manner's section, in order: manners share names, so name found
    # anywhere on page would stand in for one missing or swapped.
    let page = readFile(OUT / "turns-single.html")
    for manner in Manner:
      let opens = page.find("<h2>" & MANNERS[manner].title & "</h2>")
      check opens >= 0
      if opens < 0: continue
      let section = page[opens..<page.find("</section>", opens)]
      var want, got: seq[string]
      for _ in SINGLES:
        for quarter in 1..<QUARTERS_ROUND:
          let named = facingOf(quarterPose(manner, quarter))
          check named.isSome
          want.add (if named.isSome: named.get.name else: "")
      var at = section.find(" turn<br>")
      while at >= 0:
        let start = at + " turn<br>".len
        got.add section[start..<section.find("</figcaption>", start)]
        at = section.find(" turn<br>", start)
      check got == want



suite "Internal: The rests and the chains, named by model":
  ## Each page names chain's rest and facings through `parts.restOf` and
  ##   `parts.facingAt`, and law reads written page back (Article IX.5).
  test "the review page heads each chain with the facing it rests at":
    let page = readFile(OUT / "review.html")
    check page.contains(
      "<h2>C &middot; The cross-name chain, " & restOf(HAND_TO_HAND).name & " at rest</h2>",
    )
    check page.contains(
      "<h2>D &middot; The same-name chain, " & restOf(PAIRED).name & " at rest</h2>",
    )


  test "the review page names every card by its section's letter and two digits":
    ## Card is named A01 to G08, so no card reads as decision `D1` of sign-off (Architect,
    ##   2026-10-04).  Red with cards named A1 to G8, read 2026-10-04: 57 of 107 had one digit.
    let page = readFile(OUT / "review.html")
    var
      names: seq[string]
      at = page.find("<figcaption><code>")
    while at >= 0:
      let
        first = at + "<figcaption><code>".len
        last = page.find("</code>", first)
      names.add page[first..<last]
      at = page.find("<figcaption><code>", last)
    check names.len > 0
    for name in names:
      if not (name.len == 3 and name[0] in {'A'..'G'} and name[1..2].allCharsInSet(Digits)):
        checkpoint "card named `" & name & "`"
        fail()


  test "the hand-to-hand page names each facing its chain stands at":
    let page = readFile(OUT / "turns-hands.html")
    check page.contains(
      "<b>" & facingAt(HAND_TO_HAND, 1.0).get.name & "</b> at a whole number of turns",
    )
    check page.contains("<b>" & facingAt(HAND_TO_HAND, 0.5).get.name & "</b> at a half")
