## Test review page renders whole from model, and is written and read back.
##
##   Page is build product, never committed, so no staleness law exists: this suite drives
##     build that writes it (Article IX.6) and reads bytes back (IX.5).

{.experimental: "strictFuncs".}

import std/[options, os, strutils, unittest]

import ../../design/plain
import ../../src/dance_ontology
import ../../tools/review
import ../../tools/title


const OUT = "build/review"
  ## Where page and pictures land; ignored by git, created here.


func importsOf(source: string): seq[string] =
  ## Each `import` statement of source, with lines that continue it.
  var going = false
  for line in source.splitLines:
    if line.startsWith("import"):
      result.add line
      going = true
    elif going and line.startsWith(" "):
      result[^1].add line
    else:
      going = false


func suitesOf(stub: string): seq[string] =
  ## Suites stub imports as `./<dir>/[...]`, as paths under `tests/`.
  for statement in stub.importsOf:
    var at = statement.find("./")
    while at >= 0:
      let open = statement.find("/[", at)
      let shut = statement.find(']', at)
      if statement[at - 1] != '.' and open > at and shut > open and
          statement[at + 2 ..< open].allCharsInSet(IdentChars):
        for name in statement[open + 2 ..< shut].split(','):
          result.add "tests" / statement[at + 2 ..< open] / name.strip & ".nim"
      at = statement.find("./", at + 2)


suite "the review page":
  test "the page renders with every marker filled":
    let page = renderReview()
    check page.len > 0
    check "{{" notin page  # `renderReview` asserts it too; said here as law
    # Prose follows Simplified Technical English (Article VI.8), counted as `tmarks.nim`
    # counts it on every other page: sentence's words, and paragraph's sentences.
    for said in page.longSentences:
      checkpoint "sentence over " & $WORDS & " words: " & said
      fail()
    for said in page.longParagraphs:
      checkpoint "paragraph over " & $SENTENCES & " sentences, opening: " & said
      fail()
    # Review page is exploration, not page project stands behind, and title says so.
    check "<title>" & MOCKUP & " — " in page
    check "<title>" & WORK & " — " notin page

  test "the page counts the laws of every suite a stub runs":
    # Laws live in stubs and in suites stubs import, so count is taken from stubs
    # themselves, rather than from where page's count looks.
    var laws = 0
    for stub in walkFiles("tests/t*.nim"):
      for path in @[stub] & readFile(stub).suitesOf:
        for line in readFile(path).splitLines:
          if line.strip.startsWith("test \""):
            inc laws
    check laws > 0
    check $laws & " tests run over all " in renderReview()

  test "the page and every picture are written and read back":
    createDir(OUT)
    writeReview(OUT)
    check readFile(OUT / PAGE_NAME) == renderReview()  # bytes re-read (IX.5)
    for target in FRAMES:
      let path = OUT / FRAMES_DIR / (target.slug & ".svg")
      check fileExists(path)
      check readFile(path) == renderFrame(target)  # one picture per frame

  test "and there are no pictures of anything else":
    # `writeReview` clears directory first, so frame that is renamed cannot leave its
    # old picture behind under old name, naming frame model no longer has.
    writeFile(OUT / FRAMES_DIR / "stale.svg", "<svg/>")
    writeReview(OUT)
    var want: seq[string] = @[]
    for target in FRAMES:
      want.add target.slug & ".svg"
    var found: seq[string] = @[]
    for path in walkFiles(OUT / FRAMES_DIR / "*.svg"):
      found.add extractFilename(path)
    for name in found:
      check name in want
    check found.len == want.len

  test "the page shows every frame and every move":
    # Name is written in hands it names, so it is several elements and not one.  Read
    # past ink for words, and read gallery's own card rather than whole page: every
    # picture carries SVG `<title>` saying same words, which would answer this whether
    # frame were named on page or not.
    let page = renderReview().multiReplace(("</span>", ""))
    var named: seq[string] = @[]
    for chunk in page.split("<div class=\"name\">")[1 .. ^1]:
      var said = chunk[0 ..< chunk.find("</div>")]
      while said.contains("<span"):
        said = said[0 ..< said.find("<span")] & said[said.find('>',
          said.find("<span")) + 1 .. ^1]
      named.add said
    check named.len == FRAMES.len
    var cells = 0
    for source in FRAMES:
      check source.describe in named
      cells += moves(source).len
      for target in FRAMES:
        if compound(source, target).isSome:
          inc cells
    # Matrix carries one cell per move and one per compound.
    check page.count("<td class=\"on") == cells

  test "the pictures fix no colour of their own":
    # They are shown inside two pages that theme them and as standalone files that cannot
    # be themed, so every ink is custom property with fallback and no ink is written down
    # on its own.
    for target in FRAMES:
      let picture = renderFrame(target)
      check picture.count('#') == picture.count("var(--")
      check picture.count('#') > 0

  test "a frame's file name survives its description":
    check fromKey("--.").get.slug == "free"
    check fromKey("l-.").get.slug == "left-to-left"
    check fromKey("lrL").get.slug == "left-to-left-over-right-to-right"
    var slugs: seq[string] = @[]
    for target in FRAMES:
      check target.slug notin slugs
      slugs.add target.slug
