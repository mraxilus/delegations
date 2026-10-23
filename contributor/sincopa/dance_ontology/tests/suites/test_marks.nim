## Drive mark workbench's build under testament: every gate, every page written and read back.

{.experimental: "strictFuncs".}

import std/[options, os, strformat, strutils, unittest]

import ../../design/[marks, parts, plain, rig_page]
import ../../tools/title
from ../../src/dance_ontology/rotation import facing, seenAfter


const OUT = "build/suites/design"
  ## Where pages land; ignored by git, created here.
  ##   Apart from `build/design`, where `pages` writes each page dressed in its font faces: page
  ##     written here carries none, and publishing reads that directory.

const SMALL = ["a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into",
               "nor", "of", "on", "or", "over", "so", "the", "to", "up", "with", "yet"]
  ## Words title case leaves lowercase where they fall inside title.

const ORIENTATIONS: array[Facing, tuple[lead_turn, follow_turn: float]] =
  block:
    var found: array[Facing, Option[tuple[lead, follow: int]]]
    for movers in 0..2:
      for lead in [0, 1, -1, 2]:
        for follow in [0, 1, -1, 2]:
          let named = facing(seenAfter([lead, follow]))
          if ord(lead != 0) + ord(follow != 0) == movers and found[named].isNone:
            found[named] = some((lead, follow))
    var each: array[Facing, tuple[lead_turn, follow_turn: float]]
    for named in Facing:
      doAssert found[named].isSome, &"No turn on the spot reaches `{named.name}`."
      each[named] = (90.0 * float(found[named].get.lead), 90.0 * float(found[named].get.follow))
    each
  ## Sixteen ways couple can face, each reached by fewest dancers turning on spot.
  ##   Derived from model's facings (`rotation.Facing`), not listed: quarter
  ##     turn is 90 degrees, clockwise, as drawing counts its bearings.
  ##   Domain of law that holds `parts.turnedFacing`, which Reference names facings by.

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

func titlePage(page: string): string =
  ## Page's own name, after work's name and space that follows it.
  let opens = page.find("<title>")
  doAssert opens >= 0, "Page carries no title."
  let
    shuts = page.find("</title>", opens)
    named = page[opens+"<title>".len..<shuts]
  doAssert named.startsWith(WORK & " "), "Title opens with no name of work; got `" & named & "`."
  named[(WORK & " ").len .. ^1]

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
  # Every page workbench writes is one project stands behind, so title is work's name, space,
  # then page's own name: no dash, and no mock-up form (Architect, 2026-10-21).
  # Asserted against constant, so title cannot drift while test still passes.
  check "<title>" & WORK & " " in written
  check "<title>" & WORK & " — " notin written
  check "<title>" & WORK & " Mockup" notin written
  # Every published title reads in title case, so published set is one consistent
  # form.  Nothing checked it until rig viewer shipped with sentence for title
  # while every page beside it was cased.
  check isTitleCased(titlePage(written))
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
  test "reference.html":
    holdPage("reference.html")


  test "every page the workbench writes has a law of its own":
    ## Laws above name their page by literal; they are read off this file and held to
    ##   `PAGES`, so page added there cannot go unbuilt here.
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



suite "Internal: The sixteen facings, drawn":
  # Glossary agrees sixteen facings, and model holds them (`rotation.Facing`).  Reference
  # names facings through `parts.turnedFacing`, so law holds it over all sixteen.
  test "each drawn facing reads back as the facing it is named for":
    for named, orientation in ORIENTATIONS:
      check turnedFacing(orientation.lead_turn, orientation.follow_turn) == some(named)



suite "Internal: The rests and the chains, named by model":
  ## Reference names each chain's rest through `parts.facingRest`, and law reads written page
  ##   back (Article IX.5).
  test "the Reference heads each section of a chain with the name of that chain":
    ## Cross-name chain stands in C and moves in F; same-name chain stands in D and moves in G.
    ##   Headings of C, D and G also name facing their chain rests at.
    ##   Red with G headed `Hand-to-hand chain`, name of cross-name hold, as audit of #698
    ##     found it.
    let page = readFile(OUT / "reference.html")
    check page.contains(
      "<h2>C &middot; The cross-name chain, " & facingRest(HAND_TO_HAND).name & " at rest</h2>",
    )
    check page.contains(
      "<h2>D &middot; The same-name chain, " & facingRest(PAIRED).name & " at rest</h2>",
    )
    check page.contains("<h2>F &middot; The cross-name chain, moving</h2>")
    check page.contains(
      "<h2>G &middot; The same-name chain, " & facingRest(PAIRED).name & ", moving</h2>",
    )


  test "the Reference names every card by its section's letter and two digits":
    ## Card is named A01 to G08, so no card reads as decision `D1` of sign-off (Architect,
    ##   2026-10-04).  Red with cards named A1 to G8, read 2026-10-04: 57 of 107 had one digit.
    let page = readFile(OUT / "reference.html")
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
