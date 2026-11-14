## ro pagbu be lo se ciska be fi la'o gy. NIF .gy. be'o pe lo jmive se ciska cu se pixra pa pixra
##   be fo la'o gy. SVG .gy. .i pa linji cu cusku lo se vasru be le se ciska .i le papri pe le vi
##   se gunka cu jarco ro pixra .e le linji to `pages/live.html` toi .i lo cipra cu cipra lo nu
##   pixra ne'i le jbena zbasu .e le se zbasu pe la'o gy. JavaScript .gy.
##
##   |---------------|---------------------------------------------------------------------------|
##   | lo fancu      | lo smuni                                                                  |
##   |---------------|---------------------------------------------------------------------------|
##   | `drawn`       | lo namcu .e lo linji .e lo pixra be ro pagbu be le ca se ciska .e le rebla |
##   | `drawnMerged` | lo namcu .e lo linji .e lo pixra be ro tricu poi ve jmina le ca se ciska  |
##   | `laidOut`     | punji lo tanxe .e lo karda vu'o pe pa pagbu ta'i lo nu `drawn` cu punji   |
##   |---------------|---------------------------------------------------------------------------|
##
##   le vi datnyvei cu tcidu lo se ciska be fi la'o gy. NIF .gy. po'o sepi'o `nif_read.nim` ta'i lo
##     nu ro drata samtci cu tcidu .i le papri cu ralte lo se ciska be fi la'o gy. NIF .gy. be'o
##     poi lo tcidu be lo jmive se ciska cu dunda ke'a ku'o gi'e pixra le se ciska .i se ki'u bo le
##     pixra cu jarco lo se vasru be le se ciska po'o
##   .i ro pagbu cu du lo jgena pe pa linji pe le se ciska be fi la'o gy. NIF .gy. .i ro valsi pe le
##     pagbu cu se pixra pa karda .i le karda cu zvati pa pinta porsi bu'u le dizlo korbi be le
##     pixra .i ro karda cu ponse pa sraji pagbu .i le porsi be le karda cu mintu le porsi be le
##     valsi pe le se ciska .i ro javni poi gapru le karda cu tanxe .i le genja cu gapru ro drata
##     tanxe .i lo pinta porsi pe ro tanxe cu du lo ni le tanxe cu gapru le karda .i se ki'u bo no
##     valsi cu se vasru re tanxe pe pa pinta porsi .i lo ni lo midju be le re tanxe cu darno kei
##     cu na mleca lo ni pa sraji pagbu cu ganra
##   .i ro tanxe cu sinxa pa jgena pe le se ciska be fi la'o gy. NIF .gy. .i pa jgena ka'e porsi lo
##     javni .i ro javni pe le porsi cu vasru pa javni po'o .i le tanxe pe le porsi cu ciska lo
##     cmene be le javni poi traji lo ka jibni lo valsi kei ku'o ta'i le tcita pe le jgena .i lo
##     cmene cu se lidne le javni poi traji lo ka bartu ku'o .e lo namcu pe le javni ge'u .e lo
##     du'u le porsi cu vasru xo kau javni to `LUT_CHAIN_BY_ENDS` toi .i ki'u bo le jgena cu jarco
##     lo namcu pe le javni poi krasi le porsi .i lo javni poi vasru no valsi cu se pixra no tanxe
##     .i ki'u bo no sraji pagbu cu punji le javni
##   .i ro srera jgena to `srera` toi cu tanxe gi'e cmima `err` .i le tanxe cu ciska lo stuzi poi
##     le gerna cu sisti bu'u ke'a ku'o .e le javni poi sisti bu'u le stuzi .i lo cmene be le tanxe
##     cu liste ro gerna valsi poi le gerna ka'e tcidu ke'a bu'u le stuzi to `nitcu` toi .i lo
##     srera jgena poi vasru no valsi cu se pixra pa karda pe vo'a bu'u lo stuzi pe vo'a
##   .i ro pagbu poi no gerna valsi cu vasru ke'a to `rivbi` toi cu karda gi'e cmima `off` .i le
##     karda cu ciska lo cmene be le pagbu be le genturfa'i be'o poi to'e curmi le se vasru be le
##     karda
##   .i ro jgena pe le rebla cu ca'o kalri .i lo bavla'i cenba cu basti le jgena .i se ki'u bo le
##     pagbu pe le jgena cu cmima `open`
##   .i ro valsi cu ciska `'` lo stuzi be `h` noi la'o gy. NIF .gy. cu ciska ke'a lo stuzi be `'` .i
##     lo se ciska poi zo zoi cu sitna ke'a cu na se galfi
##   .i ro stuzi cu klani lo mulno namcu la'o gy. pixel .gy. .i ro namcu cu mulno namcu .i se ki'u
##     bo le se zbasu pe la'o gy. Nim .gy. .e le se zbasu pe la'o gy. JavaScript .gy. cu ciska le
##     mintu se ciska .i lo cipra .e lo minde po'u `drive` cu cipra di'u
##   .i ro tricu poi lo nu jmina lo pagbu be le ca se ciska be fi la'o gy. NIF .gy. cu jarco ke'a cu
##     se pixra sepi'o le se ciska po'o to `merge.nim` toi .i le rebla cu na se jmina .i ki'u bo lo
##     bavla'i cenba cu basti le rebla .i va'o lo nu lo nu jmina cu jarco le tricu pe lo nu tcidu
##     le mulno se ciska kei le linji cu cusku pa tricu .i va'o lo drata le linji cu kancu lo tricu
##     .e lo valsi .e lo srera .e lo valsi poi na se tcidu ku'o ta'i lo nu `drawn` cu kancu .i va'o
##     lo nu le se ciska be fi la'o gy. NIF .gy. cu na se tcidu kei no pagbu cu se pixra .i le
##     linji cu cusku lo namcu pe le jgena poi se to'e curmi ku'o .e lo krinu .i li pa cu krasi lo
##     nu kancu le jgena
##   .i le papri cu dunda lo tarmi ro klesi be lo pagbu be le pixra .i le pixra cu cusku no skari
##   .i jdima fa lo nu lo clani pagbu cu se pixra lo ganra pixra noi le papri cu muvgau ke'a

{.experimental: "strictFuncs".}

import std/[options, strutils, tables, unicode]

import ../lojban_parser/[grammar, merge, nif_read]


type
  KindPlace* {.pure.} = enum  ## lo klesi be lo se punji be le pixra
    Rule  ## lo tanxe be pa javni .a pa porsi be lo javni
    Error  ## lo tanxe be pa srera jgena be'o .a lo karda pe pa srera jgena poi vasru no valsi
    Word  ## lo karda pe pa gerna valsi
    Unread  ## lo karda pe pa pagbu poi no gerna valsi cu vasru ke'a

  Place* = object  ## lo tanxe .a lo karda vu'o poi le pixra cu punji ke'a
    kind*: KindPlace
    x*: int  ## lo midju poi se merli fo la'o gy. pixel .gy.
    y*: int  ## lo galtu korbi poi se merli fo la'o gy. pixel .gy.
    height*: int
      ## lo ni le se punji cu gapru le karda kei ta'i lo pinta porsi .i li no va'o lo nu le se
      ##   punji cu karda
    first*: int  ## lo sraji pagbu pe le pamoi karda poi cnita le se punji
    last*: int  ## lo sraji pagbu pe le romoi karda poi cnita le se punji
    lines*: seq[string]
      ## lo linji poi le se punji cu ciska ke'a .i lo galtu linji cu lidne lo dizlo linji
    title*: string
      ## lo se ciska poi lo tcidu cu viska ke'a ca lo nu farsni le se punji .i lo kunti lerpoi va'o
      ##   lo nu no se ciska cu zasti
    parent*: int  ## lo namcu pe le se punji poi gapru le vi se punji .i li ni'u pa va'o le genja
    words*: int  ## lo du'u le karda cu vasru xo kau valsi .i li no va'o lo nu le se punji cu tanxe

  PartDrawn* = object  ## lo se punji pe pa pagbu poi se pixra ku'o .e lo ni le pixra cu barda
    places*: seq[Place]
      ## ro karda cu lidne ro tanxe .i le porsi be le karda cu mintu le porsi be le valsi pe le
      ##   se ciska .i lo panzi cu lidne lo rirni
    width*: int
    height*: int

  DrawingLive* = object
    ## lo pixra be le ca se ciska be fi la'o gy. NIF .gy. .i le klesi cu vasru lo se ciska be fi
    ##   la'o gy. HTML .gy. be'o pe ro pagbu ge'u .e lo namcu .e lo linji
    html*: string
      ## ro pagbu cu se pixra pa `figure` poi cmima `part` .i lo pixra cu se porsi ta'i le pagbu
      ##   .i lo pixra pe le rebla cu romoi
    status*: string  ## lo linji poi cusku lo se vasru be le pagbu
    count_parts*: int
    count_words*: int  ## lo du'u lo gerna valsi cu vasru xo kau valsi
    count_errors*: int  ## lo du'u le pixra cu vasru xo kau srera jgena
    count_unread*: int  ## lo du'u lo pagbu poi no gerna valsi cu vasru ke'a cu vasru xo kau valsi
    count_open*: int  ## lo du'u le rebla cu vasru xo kau pagbu noi ca'o kalri
    is_refused*: bool = false
      ## lo nu jmina cu to'e curmi lo se ciska be fi la'o gy. NIF .gy. be'o poi na se tcidu .i se
      ##   ki'u bo le pixra cu vasru no pagbu


const
  COLUMN* = 144  ## lo ni lo sraji pagbu pe pa karda cu ganra
  WIDTH_PLACE* = 136  ## lo ni lo tanxe .e lo karda cu ganra
  HEIGHT_BOX* = 40  ## lo ni lo tanxe cu sraji clani
  HEIGHT_CARD = 58  ## lo ni lo karda cu sraji clani
  ROW* = 64  ## lo ni re lamji pinta porsi be lo tanxe cu darno
  MARGIN = 10  ## lo kunti korbi poi sruri le pixra
  LETTERS_MOST = 15  ## lo du'u pa karda cu ciska su'e xo kau lerfu pe le valsi
  LABEL_MOST = 17
    ## lo du'u pa tanxe cu ciska su'e xo kau lerfu pe le javni poi traji lo ka jibni lo valsi
  CHAIN_MOST = 21
    ## lo du'u pa tanxe cu ciska su'e xo kau lerfu pe le javni poi traji lo ka bartu ne'i le porsi
  TAG_ERROR = "srera"  ## lo tcita be lo srera jgena to `nif.nim` toi
  TAG_EXPECTS = "nitcu"
    ## lo tcita be lo gerna valsi poi le gerna ka'e tcidu ke'a ca lo nu sisti to `nif.nim` toi
  TAG_UNREAD = "rivbi"  ## lo tcita be lo pagbu poi no gerna valsi cu vasru ke'a to `nif.nim` toi
  TAG_QUOTING = ["ZOI"]  ## lo klesi be lo gerna valsi poi ke'a sitna le cimoi lerpoi pe vo'a



#[ lo sinxa ]#

func escaped*(text: string): string =
  ## galfi lo se ciska tezu'e lo nu le se ciska cu se punji ne'i pa pagbu .a pa ckaji vu'o pe la'o
  ##   gy. SVG .gy. .e la'o gy. HTML .gy.
  text.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))


func clipped(text: string, count: int): string =
  ## ralte le krasi be le se ciska be'o poi vasru lo lerfu poi se kancu fi `count` .i va'o lo nu le
  ##   se ciska cu clani zmadu le krasi kei le romoi lerfu pe le krasi cu du `…`
  if text.runeLen <= count: text else: text.runeSubStr(0, count - 1) & "…"


func mark(x, y: int; text, class: string): string =
  ## ciska pa pagbu po'u `text` ge'u zi'e poi se midju `x`
  "<text class=\"" & class & "\" x=\"" & $x & "\" y=\"" & $y & "\" text-anchor=\"middle\">" &
      text.escaped & "</text>"


func rectangle(x, y, width, height: int; class: string): string =
  ## ciska pa pagbu po'u `rect` ge'u zi'e poi ponse lo cukla kojna
  "<rect class=\"" & class & "\" x=\"" & $x & "\" y=\"" & $y & "\" width=\"" & $width &
      "\" height=\"" & $height & "\" rx=\"6\"/>"


func elbow(x_from, y_from, x_to, y_to: int): string =
  ## ciska pa jorne linji poi se krasi lo dizlo korbi be pa tanxe gi'e se fanmo lo galtu korbi be
  ##   lo se punji poi cnita le tanxe .i le linji cu ni'a klama lo kunti poi cnita le tanxe .i ba bo
  ##   le linji cu pinta klama .i ba bo le linji cu ni'a klama .i le kunti cu vasru no tanxe .i no
  ##   sraji pagbu cu se vasru re tanxe pe pa pinta porsi .i se ki'u bo le pinta pagbu be le linji
  ##   cu pencu no drata jorne linji .i le romoi sraji pagbu be le linji cu zvati lo midju be le se
  ##   punji poi cnita le tanxe .i le sraji pagbu be le linji cu sepli ro drata tanxe poi le linji
  ##   cu klama lo mlana be ke'a ku'o su'o pa sraji pagbu .i se ki'u bo le sraji pagbu be le linji
  ##   cu pencu no tanxe
  let turn = y_from + (ROW - HEIGHT_BOX) div 2
  if x_from == x_to:
    return "<line class=\"edge\" x1=\"" & $x_from & "\" y1=\"" & $y_from & "\" x2=\"" & $x_to &
        "\" y2=\"" & $y_to & "\"/>"
  "<polyline class=\"edge\" points=\"" & $x_from & "," & $y_from & " " & $x_from & "," &
      $turn & " " & $x_to & "," & $turn & " " & $x_to & "," & $y_to & "\"/>"



#[ lo jgena ]#

func spoken(tag: string): string =
  ## dunda lo cmene be le javni be'o poi `CLL 21.1` cu ciska ke'a .i `-` cu basti ro `_` pe le
  ##   tcita
  tag.replace('_', '-')


func said(letters: string): string =
  ## dunda le valsi ta'i le se ciska be la lojban. .i `'` cu basti ro `h` pe la'o gy. NIF .gy.
  letters.replace('h', '\'')


func isCompound(node: NodeNif): bool =
  ## jdice lo du'u le jgena cu cmima `KindNif.Compound` gi'e na minde
  node.kind == KindNif.Compound and not node.text.startsWith(".")


func isTerminal(node: NodeNif): bool =
  ## jdice lo du'u le jgena cu gerna valsi .i lo gerna valsi cu cmima `KindNif.Compound` .i le
  ##   romoi panzi be lo gerna valsi cu lerpoi
  node.isCompound and node.text notin [TAG_ERROR, TAG_UNREAD] and node.children.len > 0 and
      node.children[^1].kind == KindNif.Literal


func words(node: NodeNif): seq[tuple[start, finish: int, letters: string]] =
  ## tcidu ro valsi pe pa gerna valsi .a pa pagbu poi no gerna valsi cu vasru ke'a .i lo stuzi cu
  ##   lidne lo lerfu ne'i ro valsi
  var k = 0
  while k < node.children.len and node.children[k].kind != KindNif.Number: inc k
  while k + 2 < node.children.len:
    result.add (node.children[k].number, node.children[k + 1].number, node.children[k + 2].text)
    k += 3


func spelling(node: NodeNif): string =
  ## dunda lo lerfu pe pa gerna valsi .a pa pagbu ta'i le se ciska .i lo canlu lerfu cu jbini lo
  ##   valsi
  let words = node.words
  var spelled: seq[string]
  for k in 0 ..< words.len:
    let is_quoted = node.text in TAG_QUOTING and k == 2 or node.text == TAG_UNREAD and
        node.children.len > 1 and node.children[1].kind == KindNif.Identifier
    spelled.add (if is_quoted: words[k].letters else: words[k].letters.said)
  spelled.join(" ")


func span(node: NodeNif): string =
  ## dunda lo stuzi poi le jgena cu kuspe ke'a mu'u `0–2`
  let words = node.words
  if words.len == 0: "" else: $words[0].start & "–" & $words[^1].finish


func labelRule(node: NodeNif): tuple[inner, outer: string] =
  ## cusku lo cmene be le javni poi traji lo ka jibni lo valsi .i va'o lo nu le jgena cu porsi lo
  ##   javni kei lo cmene cu se lidne le javni poi traji lo ka bartu ku'o .e lo du'u le porsi cu
  ##   vasru xo kau javni .i le jgena cu jarco lo namcu pe le javni poi krasi le porsi .i lo cmene
  ##   be le javni poi fanmo le porsi cu jarco lo namcu pe le javni
  let inner = node.text.spoken
  if node.children.len == 0 or node.children[0].kind != KindNif.Number: return (inner, "")
  let top = node.children[0].number
  if inner notin LUT_NUMBER_BY_RULE: return (inner, "… " & $top)
  let key = (top, LUT_NUMBER_BY_RULE[inner])
  if key notin LUT_CHAIN_BY_ENDS: return (inner, "… " & $top)
  let chain = LUT_CHAIN_BY_ENDS[key]
  (inner, "… " & chain[0].rule & " " & $chain[0].number & " (" & $chain.len & ")")


func labelError(node: NodeNif): tuple[head, rule, expected: string] =
  ## cusku lo stuzi poi le gerna cu sisti bu'u ke'a ku'o .e le javni poi sisti bu'u le stuzi ku'o
  ##   .e ro gerna valsi poi le gerna ka'e tcidu ke'a bu'u le stuzi
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
  let byte_stop = (if numbers.len > 0: $numbers[0] else: "?")
  ("srera · byte " & byte_stop, "in " & rule, expected.join(" "))



#[ lo nu punji ]#

func columnX*(k: int): int =
  ## dunda lo midju be le sraji pagbu pe `k`
  MARGIN + COLUMN * k + COLUMN div 2


func card(
  kind: KindPlace, cards: var seq[Place], lines: seq[string], title: string, count: int
): tuple[height, x, index: int, is_card: bool] =
  ## punji lo karda le bavla'i sraji pagbu gi'e dunda le karda ta'i lo se punji poi cnita le tanxe
  ##   pe le karda
  let column = cards.len
  cards.add Place(kind: kind, x: columnX(column), first: column, last: column, lines: lines,
      title: title, parent: -1, words: count)
  (0, columnX(column), column, true)


func placed(
  node: NodeNif, cards, boxes: var seq[Place]
): tuple[height, x, index: int, is_card: bool] =
  ## punji lo karda pe le jgena ta'i le porsi .i ba bo punji le tanxe pe le jgena lo gapru be le
  ##   karda .i lo midju be le tanxe cu midju lo se punji poi cnita le tanxe .i dunda lo ni le jgena
  ##   cu gapru le karda kei .e lo midju .e lo namcu vu'o pe le se punji pe le jgena .i va'o lo nu
  ##   le jgena cu vasru no valsi kei le ni gapru cu du li ni'u pa .i lo tanxe cu ponse lo namcu pe
  ##   `boxes` .i lo karda cu ponse lo namcu pe `cards`
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
    template child: untyped = node.children[k]  # lo drata cmene .i `let` cu fukpi le mulno
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
  ## punji ro se punji pe pa pagbu .i ro valsi cu se pixra pa karda ne'i lo sraji pagbu pe vo'a
  ##   bu'u le dizlo korbi .i ba bo ro jgena cu se pixra pa tanxe noi gapru le se punji pe lo panzi
  ##   be le jgena .i le genja cu gapru ro drata se punji .i ro karda cu lidne ro tanxe ne'i le
  ##   liste be lo se punji .i lo panzi cu lidne lo rirni
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



#[ lo nu pixra ]#

func svg*(part: PartDrawn, label: string): string =
  ## ciska pa pixra be le pagbu bei fo la'o gy. SVG .gy. .i lo jorne linji cu lidne lo tanxe .i lo
  ##   tanxe cu lidne lo karda .i ro se punji cu ponse lo cmene be vo'a
  var marks: seq[string]
  for k in 0 ..< part.places.len:
    template child: untyped = part.places[k]  # lo drata cmene .i `let` cu fukpi le mulno
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
  ## dunda le namcu .e le valsi be le se kancu .i le valsi cu du `one` .a `many`
  $count & " " & (if count == 1: one else: many)


func readParts(module: string): seq[NodeNif] =
  ## dunda ro jgena poi na minde gi'e pagbu le se ciska be fi la'o gy. NIF .gy. ku'o ta'i le porsi
  for node in module.readModule:
    if node.isCompound: result.add node


func drawn*(nif, tail: string): DrawingLive =
  ## ciska lo pixra be ro pagbu be le ca se ciska be fi la'o gy. NIF .gy. .i ba bo ciska lo pixra be
  ##   ro pagbu be le rebla noi ca'o kalri .i ro pagbu cu se pixra pa `figure` .i le linji cu cusku
  ##   lo se vasru be le pagbu
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
  ## jmina ro pagbu be le ca se ciska be fi la'o gy. NIF .gy. to `merge.nim` toi .i ciska lo pixra
  ##   be ro tricu poi lo nu jmina cu jarco ke'a ku'o ta'i pa pagbu .i va'o lo nu lo nu jmina cu
  ##   jarco le tricu pe lo nu tcidu le mulno se ciska kei le linji cu cusku pa tricu .i va'o lo
  ##   drata le linji cu cusku lo se vasru be le tricu .i va'o lo nu le se ciska be fi la'o gy. NIF
  ##   .gy. cu na se tcidu kei ciska no pixra gi'e cusku le jgena .e le krinu ne'i le linji
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
