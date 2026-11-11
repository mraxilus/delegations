## Hold drawing of live text (`src/browser/draw.nim`) natively: card of each word in order of
##   text, boxes of one row apart, each edge clear of each box, whole pixels, error node and part
##   still open as page shows them, and line of merge. Suite of page holds page to same drawing
##   under JavaScript (`tests/browser/suite_page.nim`).
##   Laws read every eighth text of corpora, as native build reads each whole, and NIF it gives.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, strutils, unittest]

import ../../src/browser/draw
import ../../src/lojban_parser/[live, nif, nif_read, prose]
import ./corpora


const
  STEP_CORPORA = 8  ## Laws read each text of corpora whose index this divides.
  COUNT_TEXTS_LEAST = 200  ## Texts laws read at least; 243 on adding suite.
  EXAMPLE_ERROR = (
    text: "mi klama le .i ko",  # `le` opens sumti that no word closes (CLL 6.2)
    head: "srera · byte 13",
    rule: "in sumti-6 97",
  )
    ## Text whose grammar stops at `.i`, byte 13, inside `sumti-6` 97, and what its box says.
  MODULE_REFUSED = HEADER & "(sumti_6 0 97 (LI 0 4 \"meho\") (number 310 812 (PA 5 7 \"vo\")))\n" &
    "(FOO 8 10 \"do\")\n"
    ## Module whose second node names no selma'o, so merge refuses it and names that node.


type ReadingDrawn = tuple[key: string, nif: string, parts: seq[NodeNif]]
  ## Define text of corpora as laws read it: key, NIF native build gives, and part of each line.


func readPool(): seq[ReadingDrawn] =
  ## Read every eighth text of corpora whole, with NIF of each and its parts.
  let texts = textsCorpora()
  for k in countup(0, texts.high, STEP_CORPORA):
    let nif = readTextParts(texts[k][1]).reading.toNifParts
    var parts: seq[NodeNif]
    for node in nif.readModule:
      if node.kind == KindNif.Compound and not node.text.startsWith("."): parts.add node
    result.add (texts[k][0], nif, parts)


func countLeaves(node: NodeNif, tag: string): tuple[nodes, words: int] =
  ## Count terminals, or units of `rivbi` where `tag` names it, under node, and words they hold.
  if node.kind != KindNif.Compound: return
  let is_leaf = node.children.len > 0 and node.children[^1].kind == KindNif.Literal
  if is_leaf:
    if (tag == "rivbi") == (node.text == "rivbi"):
      result.nodes = 1
      for child in node.children:
        if child.kind == KindNif.Literal: inc result.words
    return
  for child in node.children:
    let counts = child.countLeaves(tag)
    result.nodes += counts.nodes
    result.words += counts.words


type Rectangle = tuple[x, y, width, height: int]  ## Define box of SVG: corner, then size.


func attribute(element, name: string): string =
  ## Give value of attribute of element of SVG.
  let opening = element.find(" " & name & "=\"") + name.len + 3
  element[opening ..< element.find('"', opening)]


func number(element, name: string): int =
  ## Give value of attribute of element of SVG as integer.
  element.attribute(name).parseInt


func isEntered(box: Rectangle, a, b: (int, int)): bool =
  ## Decide whether segment of edge, across or down, passes inside box, edges of box apart.
  let
    (left, right) = (min(a[0], b[0]), max(a[0], b[0]))
    (top, bottom) = (min(a[1], b[1]), max(a[1], b[1]))
  left < box.x + box.width and right > box.x and top < box.y + box.height and bottom > box.y


let POOL = readPool()  ## Texts laws read, once.



suite "Internal: Drawing of live text":
  test "Each word draws one card, in order of its bytes, and line counts each word":
    check POOL.len >= COUNT_TEXTS_LEAST
    for reading in POOL:
      let drawing = drawn(reading.nif, "")
      var words, unread: int
      for part in reading.parts:
        let
          drawn_part = part.laidOut
          terminals = part.countLeaves("")
          units = part.countLeaves("rivbi")
        words += terminals.words
        unread += units.words
        var
          count_cards = 0
          starts: seq[int]
        for place in drawn_part.places:
          if place.height != 0: continue
          inc count_cards
          if place.kind in {KindPlace.Word, KindPlace.Unread}:
            starts.add place.lines[2].split("–")[0].parseInt
        check starts == starts.sorted
        check count_cards >= terminals.nodes + units.nodes
      check drawing.count_words == words
      check drawing.count_unread == unread
      check drawing.count_parts == reading.parts.len

  test "Boxes of one row hold disjoint columns, a column apart, each over its own columns":
    for reading in POOL:
      for part in reading.parts:
        let drawn_part = part.laidOut
        var rows: seq[seq[Place]]
        for place in drawn_part.places:
          if place.height == 0: continue
          while rows.len <= place.height: rows.add @[]
          rows[place.height].add place
          check columnX(place.first) <= place.x and place.x <= columnX(place.last)
        for row in rows:
          let sorted = row.sortedByIt(it.first)
          for k in 1 ..< sorted.len:
            check sorted[k - 1].last < sorted[k].first
            check sorted[k].x - sorted[k - 1].x >= COLUMN

  test "Each edge passes clear of each box, and meets boxes at its two ends alone":
    for reading in POOL:
      for part in reading.parts:
        let svg = part.laidOut.svg("")
        var
          boxes: seq[Rectangle]
          edges: seq[seq[(int, int)]]
        for element in svg.split('<'):
          if element.startsWith("rect "):
            boxes.add (element.number("x"), element.number("y"), element.number("width"),
                element.number("height"))
          elif element.startsWith("line "):
            edges.add @[(element.number("x1"), element.number("y1")),
                (element.number("x2"), element.number("y2"))]
          elif element.startsWith("polyline "):
            var points: seq[(int, int)]
            for pair in element.attribute("points").splitWhitespace:
              let numbers = pair.split(',')
              points.add (numbers[0].parseInt, numbers[1].parseInt)
            edges.add points
        for edge in edges:
          for k in 1 ..< edge.len:
            for box in boxes: check not box.isEntered(edge[k - 1], edge[k])

  test "Each number of drawing is whole pixels, so native and JavaScript builds write it alike":
    for reading in POOL:
      let svg = drawn(reading.nif, "").html
      for attribute in ["x=\"", "y=\"", "width=\"", "height=\"", "points=\""]:
        var at = svg.find(attribute)
        while at >= 0:
          let
            opening = at + attribute.len
            value = svg[opening ..< svg.find('"', opening)]
          check value.allCharsInSet(Digits + {' ', ',', '-'})
          at = svg.find(attribute, opening)

  test "Error node draws box at byte grammar stops, naming its rule and what it needs":
    let
      nif = readTextParts(EXAMPLE_ERROR.text).reading.toNifParts
      drawing = drawn(nif, "")
    var root: NodeNif
    for node in nif.readModule:
      if node.kind == KindNif.Compound and not node.text.startsWith("."):
        root = node
        break
    let places = root.laidOut.places
    check places[^1].kind == KindPlace.Error
    check places[^1].lines == @[EXAMPLE_ERROR.head, EXAMPLE_ERROR.rule]
    check places[^1].title.startsWith("needs ")
    check drawing.count_errors == 1
    check "class=\"box err\"" in drawing.html

  test "Merge names one tree of one pass, else what trees hold, and refusal of NIF in red":
    let
      whole = drawnMerged(readTextParts("mi klama .i ko").reading.toNifParts)
      kept = drawnMerged(readTextParts(EXAMPLE_ERROR.text).reading.toNifParts)
      refused = drawnMerged(MODULE_REFUSED)
    check whole.status == "Merged · one tree · 4 words · as one pass reads the text"
    check not whole.is_refused and whole.count_parts == 1
    check kept.status == "Merged · 2 trees · 5 words · 1 error · 0 words unread"
    check not kept.is_refused and "class=\"box err\"" in kept.html
    check refused.is_refused and refused.html.len == 0  # NIF that reads not draws no part
    check refused.status.startsWith("Merge refused · part 2 · ")  # node counted from 1


  test "Part still open draws as open, and line counts it apart":
    var reader = initReaderLive()
    let change = reader.push("mi klama le zarci .i do ")
    check change.tail.len > 0
    let drawing = drawn(reader.toNif, change.tail)
    check drawing.count_open == 1
    check "<figure class=\"part open\">" in drawing.html
    check drawing.status.endsWith("1 part open")
