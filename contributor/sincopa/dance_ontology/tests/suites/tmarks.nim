## Drive mark workbench's build under testament: every gate, every page written and read back.

import std/[options, os, strutils, unittest]

import ../../design/marks
import ../../design/parts
import ../../design/plain
import ../../design/rig_page
import ../../tools/title


const OUT = "build/design"
  ## Where pages land; ignored by git, created here.

const SMALL = ["a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into",
               "nor", "of", "on", "or", "over", "so", "the", "to", "up", "with", "yet"]
  ## Words title case leaves lowercase where they fall inside title.

func titleCased(title: string): bool =
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
  page[opens + "<title>".len ..< shuts].split(" \u2014 ")[^1]


suite "mark workbench":
  createDir(OUT)
  for i in 0 ..< PAGES.len:
    test PAGES[i].name:
      buildPage(i, OUT)
      let written = readFile(OUT / PAGES[i].name)
      check written.len > 0  # written and read back (IX.5)
      # Every page workbench writes is exploration, so every one carries mockup form and
      # none carries plain one: reader tells stood-behind page from mock-up before opening
      # either.  Asserted against constant, so title cannot drift while test still passes.
      check "<title>" & MOCKUP & " — " in written
      check "<title>" & WORK & " — " notin written
      # Every published title reads in title case, so published set is one consistent
      # form.  Nothing checked it until viewer page shipped with sentence for title
      # while every page beside it was cased.
      check titleCased(titleOf(written))
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

suite "every page this project publishes":
  test "viewer's title reads in title case, as every other does":
    ## Viewer is written by its own module rather than by workbench above, so its title is
    ## held here against same reading rather than left as only one nothing checks.
    check titleCased(TITLE)

  test "committed markup says its prose plainly too":
    ## Whole-cloth mock-up is hand-authored file rather than page workbench renders, so its
    ## prose is held here.  Reference page's own markup is held by `treview.nim`, beside
    ## build that fills it.
    let markup = readFile("mockups" / "wholecloth.html")
    check markup.prose.len > 0
    for said in markup.longSentences:
      checkpoint "sentence over " & $WORDS & " words: " & said
      fail()
    for said in markup.longParagraphs:
      checkpoint "paragraph over " & $SENTENCES & " sentences, opening: " & said
      fail()


suite "the sixteen facings, drawn":
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
        var captions: seq[string]
        var c = page.find("<figcaption>", at)
        while c >= 0 and c < shuts:
          let start = c + "<figcaption>".len
          captions.add page[start ..< page.find("</figcaption>", start)]
          c = page.find("<figcaption>", start)
        check captions.len == 4
        for caption in captions:
          check caption.startsWith(side & "-to-")
        at = shuts

  test "each drawn facing reads back as the facing it is named for":
    for named, o in ORIENTATIONS:
      check turnedFacing(o.lead_turn, o.follow_turn) == some(named)

  test "every quarter the single-hand page draws names its facing, in its own place":
    # Read within each manner's section, in order: manners share names, so name found
    # anywhere on page would stand in for one missing or swapped.
    let page = readFile(OUT / "turns-single.html")
    for manner in Manner:
      let opens = page.find("<h2>" & MANNERS[manner].title & "</h2>")
      check opens >= 0
      if opens < 0: continue
      let section = page[opens ..< page.find("</section>", opens)]
      var want, got: seq[string]
      for _ in SINGLES:
        for quarter in 1 ..< QUARTERS_ROUND:
          let named = facingOf(quarterPose(manner, quarter))
          check named.isSome
          want.add (if named.isSome: named.get.name else: "")
      var at = section.find(" turn<br>")
      while at >= 0:
        let start = at + " turn<br>".len
        got.add section[start ..< section.find("</figcaption>", start)]
        at = section.find(" turn<br>", start)
      check got == want


suite "the rests and the chains, named by model":
  ## Each page names chain's rest and facings through `parts.restOf` and
  ##   `parts.facingAt`, and law reads written page back (Article IX.5).

  test "the review page heads each chain with the facing it rests at":
    let page = readFile(OUT / "review.html")
    check page.contains("<h2>C &middot; The cross-name chain, " &
                        restOf(HAND_TO_HAND).name & " at rest</h2>")
    check page.contains("<h2>D &middot; The same-name chain, " &
                        restOf(PAIRED).name & " at rest</h2>")

  test "the hand-to-hand page names each facing its chain stands at":
    let page = readFile(OUT / "turns-hands.html")
    check page.contains("<b>" & facingAt(HAND_TO_HAND, 1.0).get.name &
                        "</b> at a whole number of turns")
    check page.contains("<b>" & facingAt(HAND_TO_HAND, 0.5).get.name & "</b> at a half")
