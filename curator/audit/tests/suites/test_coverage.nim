## Replicate coverage rules of `coverage.nim` header, i.e. Article X.8 over characters pages use.

{.experimental: "strictFuncs".}

import std/[sequtils, sets, strutils, unicode, unittest]
import ../../src/[assets, coverage, findings, layout]
import ./fixtures


const
  FACE = "@font-face { src: url(NotoSans-Regular.ttf); }"
    ## Page line naming one store face, Noto Sans, which maps no arrow.
  MATH = "@font-face { src: url(NotoSansMath-Regular.ttf); }"
    ## Page line naming Noto Sans Math, which maps arrows Noto Sans lacks.
  PAGE = ALPHA_DIRECTORY & "/pages/index.html"  ## Page fixture project carries.
  SAMPLES_FLOOR = 100
    ## Fewest range bounds law below must sample; guard skipping nearly all of them fails.


func rangesOf(file: string): seq[Slice[int]] =
  ## Read ranges store row of face spells, as slices.
  for (name, _, _, ranges) in ASSETS:
    if name == file: return ranges.toRanges


func codepointOf(f: Finding): int =
  ## Read codepoint finding names, from its `U+` notation.
  let at = f.message.find("`U+")
  f.message[at + 3..<f.message.find('`', at + 1)].parseHexInt


func codepointsReported(tree: Tree): seq[int] =
  ## Read codepoint each finding over fixture project names.
  tree.checkCoverage(ALPHA_DIRECTORY).mapIt(it.codepointOf)



suite "Coverage":
  test "character no face project ships covers is reported, by file, line and codepoint":
    let
      tree = goodTree().with(entry(PAGE, "<style>" & FACE & "</style>\n<p>café</p>\n<p>⇄</p>\n"))
      found = tree.checkCoverage(ALPHA_DIRECTORY)
    check found.len == 1  # `é` is Noto Sans's, `⇄` is nobody's here (Article X.8)
    check found[0].path == PAGE
    check found[0].line == 3
    check found[0].message.endsWith("got `U+21C4` for `⇄`.")


  test "faces merge by codepoint range, so character any face of project covers passes":
    # X.8 merges faces where none covers everything; Noto Sans Math holds what Noto Sans lacks.
    let tree = goodTree().with(
      entry(PAGE, "<style>" & FACE & "</style>\n<p>⇄</p>\n"),
      entry(ALPHA_DIRECTORY & "/src/faces.nim", "const MATH = \"" & MATH & "\"\n"),
    )
    check tree.checkCoverage(ALPHA_DIRECTORY).len == 0  # merged by range (Article X.8)


  test "reference reads as character it names, entities such as `&uarr;` among them":
    let
      page = "<style>" & FACE & "</style>\n<p>&uarr;</p>\n<p>&#8644;</p>\n<p>&#x21c4;</p>\n" &
        "<p>&lang;</p>\n"
      found = goodTree().with(entry(PAGE, page)).checkCoverage(ALPHA_DIRECTORY)
    check found.mapIt(it.line) == @[2, 3, 4, 5]
    check found[0].message.endsWith("got `U+2191` for `&uarr;`.")  # named
    check found[1].message.endsWith("got `U+21C4` for `&#8644;`.")  # decimal
    check found[2].message.endsWith("got `U+21C4` for `&#x21c4;`.")  # hexadecimal
    check found[3].message.endsWith("got `U+27E8` for `&lang;`.")  # WHATWG 13.5, not `2329`


  test "reference naming ASCII, name outside table and number past Unicode read as nothing":
    # `&amp;` names ASCII, which check never reads; `&check;` came after HTML 4.01, and `&` in
    #   most code opens no reference, so name outside table is unread rather than reported.
    let page = "<style>" & FACE & "</style>\n<p>&amp; &lt; &#42; &check; &#x110000; &#; &#xzz;" &
      " &uarr</p>\n"
    check goodTree().with(entry(PAGE, page)).checkCoverage(ALPHA_DIRECTORY).len == 0


  test "C and C++ take address with `&`, so reference there is unread":
    let tree = goodTree().with(
      entry(PAGE, "<style>" & FACE & "</style>\n"),
      entry(ALPHA_DIRECTORY & "/src/shim.cpp", "auto mark = &harr;\n"),
      entry(ALPHA_DIRECTORY & "/src/page.nim", "const MARK = \"&harr;\"\n"),
    )
    let found = tree.checkCoverage(ALPHA_DIRECTORY)
    check found.len == 1  # Nim string writes markup; C++ takes address of `harr`
    check found[0].path.endsWith("page.nim")


  test "character comment alone holds is set aside, and one beside it is not":
    let
      source = "# ⇄ marks place.\nconst MARK = \"⇄\"  # ⇄ marks place.\n#[ ⇄ ]#\n"
      tree = goodTree().with(
        entry(PAGE, "<style>" & FACE & "</style>\n<!-- ⇄ marks place. -->\n"),
        entry(ALPHA_DIRECTORY & "/src/page.nim", source),
      )
      found = tree.checkCoverage(ALPHA_DIRECTORY)
    check found.len == 1  # comment never reaches page; string does
    check found[0].path.endsWith("page.nim")
    check found[0].line == 2


  test "tests and records are no page source, while other Markdown is":
    # Fixture holds character to prove its absence; record describes page. Markdown that is
    #   no record may be rendered into page, as `pga_benchmark` renders its proposals.
    let tree = goodTree().with(
      entry(PAGE, "<style>" & FACE & "</style>\n"),
      entry(ALPHA_DIRECTORY & "/tests/suites/test_marks.nim", "const MARK = \"⇄\"\n"),
      entry(ALPHA_DIRECTORY & "/design/README.md", "# Design\n\nPlace mark is ⇄.\n"),
      entry(ALPHA_DIRECTORY & "/proposals/marks.md", "# Marks\n\nPlace mark is ⇄.\n"),
    ).replaced(ALPHA_DIRECTORY & "/PROVENANCE.md", provenanceText("x") & "\nMark ⇄.\n")
    let found = tree.checkCoverage(ALPHA_DIRECTORY)
    check found.mapIt(it.path) == @[ALPHA_DIRECTORY & "/proposals/marks.md"]


  test "faces are store files page sources name, outside tests and records":
    let tree = goodTree().with(
      entry(PAGE, "<style>" & FACE & "</style>\n"),
      entry(ALPHA_DIRECTORY & "/src/faces.nim", "const MATH = \"" & MATH & "\"\n"),
      entry(ALPHA_DIRECTORY & "/tests/test_faces.nim", "const NOT = \"NotoSerif-Italic.ttf\"\n"),
    ).replaced(ALPHA_DIRECTORY & "/README.md", "# Alpha\n\nShips no `NotoSans-Bold.ttf`.\n")
    check tree.facesOf(ALPHA_DIRECTORY) == @["NotoSans-Regular.ttf", "NotoSansMath-Regular.ttf"]


  test "project naming no store face is skipped":
    # Nothing tells page shipping no face apart from tool printing non-ASCII text (header).
    let tree = goodTree().with(entry(PAGE, "<p>⇄</p>\n"))
    check tree.facesOf(ALPHA_DIRECTORY).len == 0
    check tree.charactersOf(ALPHA_DIRECTORY).len == 1  # read, then skipped for want of faces
    check tree.checkCoverage(ALPHA_DIRECTORY).len == 0


  test "one finding for each codepoint on line, however often line spells it":
    let page = "<style>" & FACE & "</style>\n<p>⇄ ⇄ &#8644; ↑</p>\n"
    check goodTree().with(entry(PAGE, page)).codepointsReported == @[0x21C4, 0x2191]


  test "character is reported exactly where no range of shipped faces holds it":
    # Law at every bound of Noto Sans's ranges, both sides: bound passes, its neighbour outside
    #   is reported unless another range holds it. Surrogates encode nothing, so they are no
    #   sample; ASCII is never read.
    let held = "NotoSans-Regular.ttf".rangesOf
    var samples, expected: seq[int]
    for bounds in held:
      for codepoint in [bounds.a - 1, bounds.a, bounds.b, bounds.b + 1]:
        if codepoint <= 0x7F or codepoint in 0xD800..0xDFFF or codepoint in samples: continue
        samples.add codepoint
        if not held.anyIt(codepoint in it): expected.add codepoint
    check samples.len >= SAMPLES_FLOOR  # guard kept most bounds
    check expected.len > 0  # some neighbour lies outside every range, so law runs both ways
    var page = "<style>" & FACE & "</style>\n"
    for codepoint in samples: page.add $Rune(codepoint) & "\n"
    let reported = goodTree().with(entry(PAGE, page)).codepointsReported
    check reported.toHashSet == expected.toHashSet  # reported iff no range holds it (Article X.8)
    check reported.len == expected.len  # one finding each, no more


  test "source passed before its comments are scanned reports as full reading does":
    # Check decides coverage over whole source first, comments included, and scans comments
    #   only where something is uncovered. Reference reads every character outside comments,
    #   then keeps what no face covers; both must agree.
    let tree = goodTree().with(
      entry(PAGE, "<style>" & FACE & "</style>\n<!-- ⇄ -->\n<p>é ⇄ &uarr;</p>\n"),
      entry(ALPHA_DIRECTORY & "/src/page.nim", "# ⇄ ↑\nconst A = \"é\"  # ⇄\nconst B = \"&uarr;\""),
      entry(ALPHA_DIRECTORY & "/src/plain.nim", "const C = \"é ü\"  # ⇄ in comment alone\n"),
    )
    let held = "NotoSans-Regular.ttf".rangesOf
    var expected: seq[(string, int, int)]
    for c in tree.charactersOf(ALPHA_DIRECTORY):
      let located = (c.path, c.line, c.codepoint)
      if not held.anyIt(c.codepoint in it) and located notin expected: expected.add located
    let found = tree.checkCoverage(ALPHA_DIRECTORY).mapIt((it.path, it.line, it.codepointOf))
    check found == expected  # optimised path against reference (Article IX.2)
    check found.len == 3  # page twice on its third line, `page.nim` once; `plain.nim` none


  test "entity table holds every name HTML 4.01 defined, once, as WHATWG maps it":
    check ENTITIES.len == 252  # 96 + 124 + 32 (HTML 4.01, sections 24.2-24.4)
    check ENTITIES.mapIt(it[0]).deduplicate.len == ENTITIES.len  # case kept: `Alpha` vs `alpha`
    check ("nbsp", 160) in ENTITIES  # HTML 4.01, 24.2
    check ("uarr", 8593) in ENTITIES  # HTML 4.01, 24.3
    check ("mdash", 8212) in ENTITIES  # HTML 4.01, 24.4
    check ("lang", 10216) in ENTITIES  # WHATWG 13.5; HTML 4.01 gave `9001`
    check ("rang", 10217) in ENTITIES  # WHATWG 13.5; HTML 4.01 gave `9002`
