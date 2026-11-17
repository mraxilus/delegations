## cipra le pixra be lo jmive se ciska to `src/browser/draw.nim` toi ne'i le jbezba
##   .i le cipra cu cipra lo du'u ro valsi cu selxra pa karda ta'i le porsi pe le selci'a
##   .i ro tanxe pe pa pinpoi cu sepli
##   .i ro jonli'i cu pencu no tanxe
##   .i ro stuzi cu klani lo mulna'u `pixel`
##   .i lo srejge .e lo pagbu poi ca'o kalri cu selxra ta'i le papri
##   .i ji'a le linji pe lo nu jmina
##
## ni'o le cipra pe le papri cu cipra lo du'u le papri cu jarco le mitxra ne'i `JavaScript` to
##     `tests/browser/suite_page.nim` toi
##   .i lo flalu cu tcidu ro bimoi se ciska pe lo selci'agri
##   .i le jbezba cu tcidu ro le selci'a ta'i lo nu tcidu le mulselci'a
##   .i lo flalu cu tcidu ji'a le selci'a be fi `NIF` be'o poi le jbezba cu dunda ke'a

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, strutils, unittest]

import ../../src/browser/draw
import ../../src/ricysoho/[live, nif, nif_read, prose]
import ./corpora


const
  STEP_CORPORA = 8  ## lo du'u lo flalu cu tcidu ro xo kau moi se ciska pe lo selci'agri
  COUNT_TEXTS_LEAST = 200
    ## lo du'u lo flalu cu tcidu su'o xo kau selci'a
    ##   .i lo flalu pu tcidu revoci selci'a ca lo nu le cipra cu se jmina
  EXAMPLE_ERROR = (
    # `CLL 6.2`
    text: "mi klama le .i ko",  # zo le krasi pa sumti poi no valsi cu fanmo ke'a
    head: "srera · byte 13",
    rule: "in sumti-6",
  )
    ## pa selci'a .e lo selsku be le tanxe pe le selci'a
    ##   .i le gerna cu sisti bu'u zo .i noi zvati lo stuzi pe li paci ku'o ne'i `sumti-6` noi du le
    ##       javni pe li soze
  MODULE_REFUSED = HEADER & "(sumti_6 0 (LI 0 4 \"meho\") (number 310 (PA 5 7 \"vo\")))\n" &
    "(FOO 8 10 \"do\")\n"
    ## lo selci'a be fi `NIF` be'o poi le tcita be le remoi jgena be ke'a cu cmene no selma'o
    ##   .i ki'u la'e di'u lo nu jmina cu to'e curmi le selci'a gi'e cusku le jgena


type ReadingDrawn = tuple[key: string, nif: string, parts: seq[NodeNif]]
  ## pa selci'a pe lo selci'agri ta'i lo nu lo flalu cu tcidu
  ##   .i le ckiku .e le selci'a be fi `NIF` be'o poi le jbezba cu dunda ke'a ku'o .e le pagbu pe ro
  ##       linji


func readPool(): seq[ReadingDrawn] =
  ## tcidu ro bimoi se ciska pe lo selci'agri ta'i lo nu tcidu le mulselci'a
  ##   .i ro le selci'a cu se kansa le selci'a be fi `NIF` be'o pe vo'a .e le pagbu pe vo'a
  let texts = textsCorpora()
  for k in countup(0, texts.high, STEP_CORPORA):
    let nif = readTextParts(texts[k][1]).reading.toNifParts
    var parts: seq[NodeNif]
    for node in nif.readModule:
      if node.kind == KindNif.Compound and not node.text.startsWith("."): parts.add node
    result.add (texts[k][0], nif, parts)


func countLeaves(node: NodeNif, tag: string): tuple[nodes, words: int] =
  ## va'o lo nu `tag` cmene `rivbi` kei kancu lo pagbu pe `rivbi` ge'u zi'e poi cnita le jgena
  ##   .i va'o lo datkancu lo genvla poi cnita le jgena
  ##   .i kancu ji'a lo valsi poi le se kancu cu vasru ke'a
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


type Rectangle = tuple[x, y, width, height: int]
  ## pa tanxe pe `SVG`
  ##   .i lo kojna cu lidne lo ni barda


func attribute(element, name: string): string =
  ## dunda lo selvau be pa ckaji pe pa pagbu pe `SVG`
  let opening = element.find(" " & name & "=\"") + name.len + 3
  element[opening ..< element.find('"', opening)]


func number(element, name: string): int =
  ## dunda lo selvau be pa ckaji pe pa pagbu pe `SVG` ta'i pa mulna'u
  element.attribute(name).parseInt


func isEntered(box: Rectangle, a, b: (int, int)): bool =
  ## jdice lo du'u pa pagbu be pa jonli'i be'o poi pinta ja sraji cu klama lo nenri be le tanxe
  ##   .i le korbi be le tanxe cu na pagbu le nenri
  let
    (left, right) = (min(a[0], b[0]), max(a[0], b[0]))
    (top, bottom) = (min(a[1], b[1]), max(a[1], b[1]))
  left < box.x + box.width and right > box.x and top < box.y + box.height and bottom > box.y


let POOL = readPool()
  ## lo selci'a poi lo flalu cu tcidu ke'a
  ##   .i le selci'a cu se tcidu pa roi



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

  test "Box names rule as its tag gives it, then outermost rule of chain, its number and count":
    var lines: seq[seq[string]]
    for node in readTextParts("mi klama").reading.toNifParts.readModule:
      if node.kind != KindNif.Compound or node.text.startsWith("."): continue
      for place in node.laidOut.places:
        if place.kind == KindPlace.Rule: lines.add place.lines
    check @["sumti-6", "… terms 80 (11)"] in lines  # le krasi be `draw.nim` to le cmene po'o toi
    check @["sentence", "… text 0 (9)"] in lines  # selkra `text` pe li no gi'e vasru so javni


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
    # lo selci'a be fi `NIF` be'o poi na se tcidu
    check refused.is_refused and refused.html.len == 0  # no pagbu cu selxra
    check refused.status.startsWith("Merge refused · part 2 · ")  # li pa cu krasi lo nu kancu


  test "Part still open draws as open, and line counts it apart":
    var reader = initReaderLive()
    let change = reader.push("mi klama le zarci .i do ")
    check change.tail.len > 0
    let drawing = drawn(reader.toNif, change.tail)
    check drawing.count_open == 1
    check "<figure class=\"part open\">" in drawing.html
    check drawing.status.endsWith("1 part open")
