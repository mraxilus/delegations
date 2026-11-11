## Draw NIF of live text as one SVG for each part, and line naming what it holds; page of
##   project shows both (`pages/live.html`), and suites hold drawing natively and under
##   JavaScript.
##
##   |-------------|----------------------------------------------------------------------|
##   | Code        | Meaning                                                              |
##   |-------------|----------------------------------------------------------------------|
##   | drawn       | SVG of each part of NIF so far and of its tail, with counts and line |
##   | drawnMerged | SVG of each tree parts of NIF so far merge to, with counts and line  |
##   | laidOut     | boxes and cards of one part, as `drawn` places them                  |
##   |-------------|----------------------------------------------------------------------|
##
##   Drawing reads NIF alone, through `nif_read.nim`, as any other program reads it: page holds
##     NIF live reader gives, and draws it, so drawing shows what NIF carries, and no more.
##   Part is node of one line of NIF. Its words stand in one row of cards at foot, one column
##     each, in order of text; each rule over them is box, with root at top. Row of box is its
##     height over cards, so two boxes of one row hold disjoint words, and their centres stand
##     one column apart at least.
##   Box stands for node of NIF: chain of rules, each holding next alone, names rule nearest
##     words, then outermost rule and count of chain (`LUT_CHAIN_BY_ENDS`), as node gives both
##     ends. Rule that holds no word draws no box, since no column places it.
##   Error node (`srera`) is box of class `err`: byte where grammar stops, and rule stopping
##     there; title of box names each terminal grammar reads there (`nitcu`). Error node that
##     holds no word is card of its own at its byte.
##   Unit no terminal holds (`rivbi`) is card of class `off`, naming stage refusing it.
##   Node of tail is still open: next change replaces it, so its part takes class `open`.
##   Each word writes `'` for `h`, which NIF writes for `'`; text `zoi` quotes stays as it is.
##   Positions are whole pixels, and every number is integer, so build of Nim and build of
##     JavaScript write same text, which suites and `drive` hold.
##   Merge draws each tree merge of parts of NIF so far gives, from that NIF alone (`merge.nim`):
##     tail stays out, since next change replaces it. Line names one tree where merge gives tree
##     of one pass, else trees, words, errors and words unread, as `drawn` counts them. NIF that
##     reads not draws no part, and line names node refused, counted from 1, and reason.
##   Classes of elements are styled by page; drawing names no colour.
##   Cost: long part makes wide drawing, which page scrolls.

{.experimental: "strictFuncs".}

import std/[options, strutils, tables, unicode]

import ../lojban_parser/[grammar, merge, nif_read]


type
  KindPlace* {.pure.} = enum  ## Define kind of place drawing gives.
    Rule  ## Box of rule, or of chain of rules.
    Error  ## Box of error node, or card of one that holds no word.
    Word  ## Card of terminal.
    Unread  ## Card of unit no terminal holds.

  Place* = object  ## Define box or card as drawing places it.
    kind*: KindPlace
    x*: int  ## Centre, in pixels.
    y*: int  ## Top, in pixels.
    height*: int  ## Rows over cards; zero for card.
    first*: int  ## Column of first card under place.
    last*: int  ## Column of last card under place.
    lines*: seq[string]  ## Lines place writes, top to bottom.
    title*: string  ## Text reader sees on pointing at place; empty where none.
    parent*: int  ## Index of place over this one; -1 for root.
    words*: int  ## Words card holds; zero for box.

  PartDrawn* = object  ## Define one part as drawn: its places, and size of its drawing.
    places*: seq[Place]  ## Cards first, in order of text, then boxes, children before parent.
    width*: int
    height*: int

  DrawingLive* = object  ## Define drawing of NIF so far: markup of each part, counts and line.
    html*: string  ## One `figure` of class `part` for each part, in order, tail last.
    status*: string  ## Line naming what parts hold.
    count_parts*: int
    count_words*: int  ## Words of terminals.
    count_errors*: int  ## Error nodes.
    count_unread*: int  ## Words of units no terminal holds.
    count_open*: int  ## Parts of tail, still open.
    is_refused*: bool = false  ## Merge refused NIF that reads not, so drawing holds none.


const
  COLUMN* = 144  ## Width of column of one card.
  WIDTH_PLACE* = 136  ## Width of box and card.
  HEIGHT_BOX* = 40  ## Height of box.
  HEIGHT_CARD = 58  ## Height of card.
  ROW* = 64  ## Step between rows of boxes.
  MARGIN = 10  ## Margin around drawing.
  LETTERS_MOST = 15  ## Characters card writes of its letters at most.
  LABEL_MOST = 17  ## Characters box writes of rule nearest words at most.
  CHAIN_MOST = 21  ## Characters box writes of outermost rule of chain at most.
  TAG_ERROR = "srera"  ## Tag of error node (`nif.nim`).
  TAG_EXPECTS = "nitcu"  ## Tag of terminals grammar reads where it stops (`nif.nim`).
  TAG_UNREAD = "rivbi"  ## Tag of unit no terminal holds (`nif.nim`).
  TAG_QUOTING = ["ZOI"]  ## Class of terminal whose third string is text it quotes.



#[ Marks ]#

func escaped*(text: string): string =
  ## Escape text for element or attribute of SVG and HTML.
  text.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))


func clipped(text: string, count: int): string =
  ## Keep first `count` characters of text, last one ellipsis where text is longer.
  if text.runeLen <= count: text else: text.runeSubStr(0, count - 1) & "…"


func mark(x, y: int; text, class: string): string =
  ## Write one `text` element, centred at `x`.
  "<text class=\"" & class & "\" x=\"" & $x & "\" y=\"" & $y & "\" text-anchor=\"middle\">" &
      text.escaped & "</text>"


func rectangle(x, y, width, height: int; class: string): string =
  ## Write one `rect` element with rounded corners.
  "<rect class=\"" & class & "\" x=\"" & $x & "\" y=\"" & $y & "\" width=\"" & $width &
      "\" height=\"" & $height & "\" rx=\"6\"/>"


func elbow(x_from, y_from, x_to, y_to: int): string =
  ## Write edge from foot of box down to head of place under it: down into gap under box, across,
  ##   then down. Gap holds no box, and boxes of one row span disjoint columns, so across meets
  ##   no other edge; down stands at centre of place under it, one column at least from any other
  ##   box it passes, so it meets none.
  let turn = y_from + (ROW - HEIGHT_BOX) div 2
  if x_from == x_to:
    return "<line class=\"edge\" x1=\"" & $x_from & "\" y1=\"" & $y_from & "\" x2=\"" & $x_to &
        "\" y2=\"" & $y_to & "\"/>"
  "<polyline class=\"edge\" points=\"" & $x_from & "," & $y_from & " " & $x_from & "," &
      $turn & " " & $x_to & "," & $turn & " " & $x_to & "," & $y_to & "\"/>"



#[ Nodes ]#

func spoken(tag: string): string =
  ## Give name of rule as 21.1 writes it: `-` for each `_` of tag.
  tag.replace('_', '-')


func said(letters: string): string =
  ## Give word as lojban writes it: `'` for each `h` of NIF.
  letters.replace('h', '\'')


func isCompound(node: NodeNif): bool =
  ## Decide whether node is compound and no directive.
  node.kind == KindNif.Compound and not node.text.startsWith(".")


func isTerminal(node: NodeNif): bool =
  ## Decide whether node is terminal: compound whose children end in string literal.
  node.isCompound and node.text notin [TAG_ERROR, TAG_UNREAD] and node.children.len > 0 and
      node.children[^1].kind == KindNif.Literal


func words(node: NodeNif): seq[tuple[start, finish: int, letters: string]] =
  ## Read each word of terminal or unit no terminal holds: bytes, then letters.
  var k = 0
  while k < node.children.len and node.children[k].kind != KindNif.Number: inc k
  while k + 2 < node.children.len:
    result.add (node.children[k].number, node.children[k + 1].number, node.children[k + 2].text)
    k += 3


func spelling(node: NodeNif): string =
  ## Give letters of terminal or unit as text writes them, each word after space.
  let words = node.words
  var spelled: seq[string]
  for k in 0 ..< words.len:
    let is_quoted = node.text in TAG_QUOTING and k == 2 or node.text == TAG_UNREAD and
        node.children.len > 1 and node.children[1].kind == KindNif.Identifier
    spelled.add (if is_quoted: words[k].letters else: words[k].letters.said)
  spelled.join(" ")


func span(node: NodeNif): string =
  ## Give bytes node spans, as `0–2`.
  let words = node.words
  if words.len == 0: "" else: $words[0].start & "–" & $words[^1].finish


func labelRule(node: NodeNif): tuple[inner, outer: string] =
  ## Name rule nearest words, then outermost rule and count of chain, where node is chain.
  var numbers: seq[int]
  for child in node.children:
    if child.kind == KindNif.Number: numbers.add child.number
    else: break
  let inner = node.text.spoken & (if numbers.len > 0: " " & $numbers[^1] else: "")
  if numbers.len < 2: return (inner, "")
  let key = (numbers[0], numbers[1])
  if key notin LUT_CHAIN_BY_ENDS: return (inner, "… " & $numbers[0])
  let chain = LUT_CHAIN_BY_ENDS[key]
  (inner, "… " & chain[0].rule & " " & $chain[0].number & " (" & $chain.len & ")")


func labelError(node: NodeNif): tuple[head, rule, expected: string] =
  ## Name byte where grammar stops, rule stopping there, and each terminal it reads there.
  var
    numbers: seq[int]
    rule = ""
    expected: seq[string]
  for child in node.children:
    case child.kind
    of KindNif.Number: numbers.add child.number
    of KindNif.Identifier: rule = child.text.spoken
    of KindNif.Compound:
      if child.text == TAG_EXPECTS:
        for terminal in child.children: expected.add terminal.text
    else: discard
  let
    byte_stop = (if numbers.len > 0: $numbers[0] else: "?")
    number_rule = (if numbers.len > 1: " " & $numbers[1] else: "")
  ("srera · byte " & byte_stop, "in " & rule & number_rule, expected.join(" "))



#[ Layout ]#

func columnX*(k: int): int =
  ## Give centre of column `k`.
  MARGIN + COLUMN * k + COLUMN div 2


func card(
  kind: KindPlace, cards: var seq[Place], lines: seq[string], title: string, count: int
): tuple[height, x, index: int, is_card: bool] =
  ## Place card in next column, and give it as place under its box.
  let column = cards.len
  cards.add Place(kind: kind, x: columnX(column), first: column, last: column, lines: lines,
      title: title, parent: -1, words: count)
  (0, columnX(column), column, true)


func placed(
  node: NodeNif, cards, boxes: var seq[Place]
): tuple[height, x, index: int, is_card: bool] =
  ## Place cards of node in order, then its box over them, centred over places under it; give
  ##   height of node over cards, centre and index of its place, or height -1 where node holds
  ##   no word. Box takes index in `boxes`, and card index in `cards`.
  if node.isTerminal or node.text == TAG_UNREAD:
    let
      is_unread = node.text == TAG_UNREAD
      letters = node.spelling
      stage =
        if not is_unread: node.text
        elif node.children.len > 1 and node.children[1].kind == KindNif.Identifier:
          node.children[0].text & " · " & node.children[1].text
        else: node.children[0].text
      title = (if letters.runeLen > LETTERS_MOST: letters else: "")
    return card(if is_unread: KindPlace.Unread else: KindPlace.Word, cards,
        @[letters.clipped(LETTERS_MOST), stage, node.span], title, node.words.len)
  var
    under: seq[tuple[height, x, index: int, is_card: bool]]
    height = -1
    sum = 0
  for k in 0 ..< node.children.len:
    template child: untyped = node.children[k]  # alias, which `let` would copy whole
    if not child.isCompound or child.text == TAG_EXPECTS: continue
    let kid = child.placed(cards, boxes)
    if kid.height < 0: continue
    under.add kid
    height = max(height, kid.height)
    sum += kid.x
  let is_error = node.text == TAG_ERROR
  if under.len == 0:
    if not is_error: return (-1, 0, -1, false)
    let label = node.labelError
    return card(KindPlace.Error, cards, @[label.head, label.rule], "needs " & label.expected, 0)
  var box = Place(kind: (if is_error: KindPlace.Error else: KindPlace.Rule),
      x: sum div under.len, height: height + 1, first: int.high, last: -1, parent: -1)
  if is_error:
    let label = node.labelError
    box.lines = @[label.head, label.rule]
    box.title = "needs " & label.expected
  else:
    let label = node.labelRule
    box.lines = (if label.outer.len > 0: @[label.inner, label.outer] else: @[label.inner])
  let index = boxes.len
  for kid in under:
    if kid.is_card:
      cards[kid.index].parent = index
      box.first = min(box.first, kid.index)
      box.last = max(box.last, kid.index)
    else:
      boxes[kid.index].parent = index
      box.first = min(box.first, boxes[kid.index].first)
      box.last = max(box.last, boxes[kid.index].last)
  boxes.add box
  (box.height, box.x, index, false)


func laidOut*(node: NodeNif): PartDrawn =
  ## Lay out one part: card of each word in its column at foot, then box of each node over
  ##   places under it, root at top; places give cards first, then boxes, children first.
  var cards, boxes: seq[Place]
  let root = node.placed(cards, boxes)
  if root.height < 0: return PartDrawn(width: 2 * MARGIN, height: 2 * MARGIN)
  let foot = MARGIN + root.height * ROW
  for k in 0 ..< cards.len: cards[k].y = foot
  for k in 0 ..< boxes.len:
    boxes[k].y = MARGIN + (root.height - boxes[k].height) * ROW
    if boxes[k].parent >= 0: boxes[k].parent += cards.len
  for k in 0 ..< cards.len:
    if cards[k].parent >= 0: cards[k].parent += cards.len
  PartDrawn(places: cards & boxes, width: 2 * MARGIN + COLUMN * max(cards.len, 1),
      height: foot + HEIGHT_CARD + MARGIN)



#[ Drawing ]#

func svg*(part: PartDrawn, label: string): string =
  ## Write part as one SVG: edges, then boxes, then cards, each place with its title.
  var marks: seq[string]
  for k in 0 ..< part.places.len:
    template child: untyped = part.places[k]  # alias, which `let` would copy whole
    if child.parent < 0: continue
    template parent: untyped = part.places[child.parent]
    marks.add elbow(parent.x, parent.y + HEIGHT_BOX, child.x, child.y)
  for k in 0 ..< part.places.len:
    template at: untyped = part.places[k]
    let
      is_card = at.height == 0
      left = at.x - WIDTH_PLACE div 2
      class =
        case at.kind
        of KindPlace.Rule: "box"
        of KindPlace.Error: (if is_card: "card err" else: "box err")
        of KindPlace.Word: "card"
        of KindPlace.Unread: "card off"
    var group = "<g>"
    if at.title.len > 0: group.add "<title>" & at.title.escaped & "</title>"
    group.add rectangle(left, at.y, WIDTH_PLACE, (if is_card: HEIGHT_CARD else: HEIGHT_BOX), class)
    let error = (if at.kind == KindPlace.Error: " err" else: "")
    if is_card:
      for i in 0 ..< at.lines.len:
        let class_line = (if i == 0: "t b" & error else: "t m")
        group.add mark(at.x, at.y + 19 + 16 * i, at.lines[i], class_line)
    else:
      group.add mark(at.x, at.y + 17, at.lines[0].clipped(LABEL_MOST), "t b" & error)
      if at.lines.len > 1:
        group.add mark(at.x, at.y + 32, at.lines[1].clipped(CHAIN_MOST), "t m s")
    group.add "</g>"
    marks.add group
  "<svg width=\"" & $part.width & "\" height=\"" & $part.height & "\" viewBox=\"0 0 " &
      $part.width & " " & $part.height & "\" role=\"img\" aria-label=\"" & label.escaped &
      "\">" & marks.join("") & "</svg>"


func counted(count: int, one, many: string): string =
  ## Give count with noun it counts, one or many.
  $count & " " & (if count == 1: one else: many)


func readParts(module: string): seq[NodeNif] =
  ## Give each node of module that is no directive, in order.
  for node in module.readModule:
    if node.isCompound: result.add node


func drawn*(nif, tail: string): DrawingLive =
  ## Draw each part of NIF so far, then each part of tail, still open, as one `figure` each;
  ##   name what they hold in line of status.
  var parts, opened: seq[NodeNif]
  try:
    parts = nif.readParts
    opened = (VERSION & "\n" & tail).readParts
  except ValueError as error:
    result.status = "NIF unread · " & error.msg
    return
  for k in 0 ..< parts.len + opened.len:
    let
      is_open = k >= parts.len
      node = (if is_open: opened[k - parts.len] else: parts[k])
      part = node.laidOut
    for place in part.places:
      case place.kind
      of KindPlace.Word: result.count_words += place.words
      of KindPlace.Unread: result.count_unread += place.words
      of KindPlace.Error: inc result.count_errors
      of KindPlace.Rule: discard
    let label = "Part " & $(k + 1) & (if is_open: ", open" else: "") & ": " & node.text.spoken
    result.html.add "<figure class=\"part" & (if is_open: " open" else: "") & "\">" &
        part.svg(label) & "</figure>"
  result.count_parts = parts.len
  result.count_open = opened.len
  result.status = counted(parts.len, "part", "parts") & " · " &
      counted(result.count_words, "word", "words") & " · " &
      counted(result.count_errors, "error", "errors") & " · " &
      counted(result.count_unread, "word unread", "words unread") &
      (if opened.len > 0: " · " & counted(opened.len, "part open", "parts open") else: "")


func drawnMerged*(nif: string): DrawingLive =
  ## Merge each part of NIF so far (`merge.nim`), and draw each tree merge gives as one part;
  ##   line names one tree where merge gives tree of one pass, else what trees hold. Where NIF
  ##   reads not, draw none, and name node and reason in line.
  let merged = nif.mergeParts
  if not merged.is_merged:
    result.is_refused = true
    result.status = "Merge refused"
    if merged.part.isSome: result.status.add " · part " & $(merged.part.get + 1)
    result.status.add " · " & merged.reason
    return
  result = drawn(merged.nif, "")
  if merged.is_whole:
    result.status = "Merged · one tree · " & counted(result.count_words, "word", "words") &
        " · as one pass reads the text"
    return
  result.status = "Merged · " & counted(result.count_parts, "tree", "trees") & " · " &
      counted(result.count_words, "word", "words") & " · " &
      counted(result.count_errors, "error", "errors") & " · " &
      counted(result.count_unread, "word unread", "words unread")
