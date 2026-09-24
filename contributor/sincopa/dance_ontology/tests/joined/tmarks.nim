## Drive mark workbench's build under testament: every gate, every page written and read back.
##   Debug build on purpose: workbench's `doAssert` gates are check (Article IX.6).

import std/[os, strutils, unittest]

import ../../design/marks
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
