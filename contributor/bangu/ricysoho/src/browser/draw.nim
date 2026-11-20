## ro pagbu be lo selci'a be fi `NIF` be'o pe lo mivyselci'a cu selxra pa pixra be fo `SVG`
##   .i pa linji cu cusku lo selvau be le selci'a
##   .i le papri pe le vi selgu'a cu jarco ro pixra .e le linji to `pages/live.html` toi
##   .i lo cipra cu cipra lo nu pixra ne'i le jbezba .e le selzba pe `JavaScript`
##
##   |---------------|---------------------------------------------------------------------------|
##   | lo fancu      | lo smuni                                                                  |
##   |---------------|---------------------------------------------------------------------------|
##   | `drawn`       | lo namcu .e lo linji .e lo pixra be ro pagbu be le ca selci'a .e le rebla |
##   | `drawnMerged` | lo namcu .e lo linji .e lo pixra be ro tricu poi ve jmina le ca selci'a  |
##   | `laidOut`     | punji lo tanxe .e lo karda vu'o pe pa pagbu ta'i lo nu `drawn` punji   |
##   |---------------|---------------------------------------------------------------------------|
##
## ni'o le vi datnyvei cu tcidu lo selci'a be fi `NIF` po'o sepi'o `nif_read.nim` ta'i lo nu ro
##     drata samtci cu tcidu
##   .i le papri cu ralte lo selci'a be fi `NIF` be'o poi lo tcidu be lo mivyselci'a cu dunda ke'a
##       ku'o gi'e pixra le selci'a
##   .i se ki'u bo le pixra cu jarco lo selvau be le se ciska po'o
##
## ni'o ro pagbu cu du lo jgena pe pa linji pe le selci'a be fi `NIF`
##   .i ro valsi pe le pagbu cu selxra pa karda
##   .i le karda cu zvati pa pinpoi bu'u le dzikoi be le pixra
##   .i ro karda cu ponse pa rajypau
##   .i le porsi be le karda cu mintu le porsi be le valsi pe le selci'a
##
## ni'o ro javni poi gapru le karda cu tanxe
##   .i le genja cu gapru ro datyta'e
##   .i lo pinpoi pe ro tanxe cu du lo ni le tanxe cu gapru le karda
##   .i se ki'u bo no valsi cu selvau re tanxe pe pa pinpoi
##   .i lo ni lo midju be le re tanxe cu darno cu na mleca lo ni pa rajypau cu ganra
##
## ni'o ro tanxe cu sinxa pa jgena pe le selci'a be fi `NIF`
##   .i pa jgena ka'e porsi lo javni
##   .i ro javni pe le porsi cu vasru pa javni po'o
##   .i le tanxe pe le porsi cu ciska lo cmene be le javni poi traji lo ka jibni lo valsi ku'o ta'i
##       le tcita pe le jgena
##   .i lo cmene cu se lidne le javni poi traji lo ka bartu ku'o .e lo namcu pe le javni ge'u .e lo
##       du'u le porsi cu vasru xo kau javni to `LUT_CHAIN_BY_ENDS` toi
##   .i ki'u bo le jgena cu jarco lo namcu pe le javni poi krasi le porsi
##
## ni'o lo javni poi vasru no valsi cu selxra no tanxe
##   .i ki'u bo no rajypau cu punji le javni
##
## ni'o ro srera jgena to `srera` toi cu tanxe gi'e cmima `err`
##   .i le tanxe cu ciska lo stuzi poi le gerna cu sisti bu'u ke'a ku'o .e le javni poi sisti bu'u
##       le stuzi
##   .i lo cmene be le tanxe cu liste ro genvla poi le gerna ka'e tcidu ke'a bu'u le stuzi to
##       `nitcu` toi
##   .i lo srejge poi vasru no valsi cu selxra pa karda pe vo'a bu'u lo stuzi pe vo'a
##
## ni'o ro pagbu poi no genvla cu vasru ke'a to `rivbi` toi cu karda gi'e cmima `off`
##   .i le karda cu ciska lo cmene be le pagbu be le genturfa'i be'o poi to'e curmi le selvau be le
##       karda
##
## ni'o ro jgena pe le rebla cu ca'o kalri
##   .i lo bavla'i cenba cu basti le jgena
##   .i se ki'u bo le pagbu pe le jgena cu cmima `open`
##
## ni'o ro valsi cu ciska `'` lo stuzi be `h` noi `NIF` ciska ke'a lo stuzi be `'`
##   .i lo selci'a poi zo zoi sitna ke'a na selga'i
##
## ni'o ro stuzi cu klani lo mulna'u `pixel`
##   .i ro namcu cu mulna'u
##   .i se ki'u bo le selzba pe `Nim` .e le selzba pe `JavaScript` ciska le mitselci'a
##   .i lo cipra .e lo minde po'u `drive` cipra di'u
##
## ni'o ro tricu poi lo nu jmina lo pagbu be le ca selci'a be fi `NIF` cu jarco ke'a selxra sepi'o
##     le se ciska po'o to `merge.nim` toi
##   .i le rebla cu na se jmina
##   .i ki'u bo lo bavla'i cenba cu basti le rebla
##
## ni'o va'o lo nu lo nu jmina cu jarco le tricu pe lo nu tcidu le mulselci'a kei le linji cu cusku
##     pa tricu
##   .i va'o lo drata le linji cu kancu lo tricu .e lo valsi .e lo srera .e lo valsi poi na se tcidu
##       ku'o ta'i lo nu `drawn` kancu
##   .i va'o lo nu le selci'a be fi `NIF` na se tcidu kei no pagbu cu selxra
##   .i le linji cu cusku lo namcu pe le jgena poi se to'e curmi ku'o .e lo krinu
##   .i li pa cu krasi lo nu kancu le jgena
##
## ni'o le papri cu dunda lo tarmi ro klesi be lo pagbu be le pixra
##   .i le pixra cu cusku no skari
##   .i jdima fa lo nu lo clapau cu selxra lo ganxra noi le papri cu muvgau ke'a

{.experimental: "strictFuncs".}

import std/[options, strutils, tables, unicode]

import ../ricysoho/[grammar, merge, nif_read]


type
  KindPlace* {.pure.} = enum  ## lo klesi be lo selpu'i be le pixra
    Rule  ## lo tanxe be pa javni .a pa porsi be lo javni
    Error  ## lo tanxe be pa srejge be'o .a lo karda pe pa srejge poi vasru no valsi
    Word  ## lo karda pe pa genvla
    Unread  ## lo karda pe pa pagbu poi no genvla cu vasru ke'a

  Place* = object  ## lo tanxe .a lo karda vu'o poi le pixra cu punji ke'a
    kind*: KindPlace
    x*: int  ## lo midju poi selmre fo `pixel`
    y*: int  ## lo galkoi poi selmre fo `pixel`
    height*: int
      ## lo ni le selpu'i cu gapru le karda kei ta'i lo pinpoi
      ##   .i li no va'o lo nu le selpu'i cu karda
    first*: int  ## lo rajypau pe le pamoi karda poi cnita le selpu'i
    last*: int  ## lo rajypau pe le romoi karda poi cnita le selpu'i
    lines*: seq[string]
      ## lo linji poi le selpu'i cu ciska ke'a
      ##   .i lo galyli'i cu lidne lo dzili'i
    title*: string
      ## lo selci'a poi lo tcidu cu viska ke'a ca lo nu farsni le selpu'i
      ##   .i lo kunti lerpoi va'o lo nu no selci'a cu zasti
    parent*: int
      ## lo namcu pe le selpu'i poi gapru le vi selpu'i
      ##   .i li ni'u pa va'o le genja
    words*: int
      ## lo du'u le karda cu vasru xo kau valsi
      ##   .i li no va'o lo nu le selpu'i cu tanxe

  PartDrawn* = object  ## lo selpu'i pe pa pagbu poi selxra ku'o .e lo ni le pixra cu barda
    places*: seq[Place]
      ## ro karda cu lidne ro tanxe
      ##   .i le porsi be le karda cu mintu le porsi be le valsi pe le selci'a
      ##   .i lo panzi cu lidne lo rirni
    width*: int
    height*: int

  DrawingLive* = object
    ## lo pixra be le ca selci'a be fi `NIF`
    ##   .i le klesi cu vasru lo selci'a be fi `HTML` be'o pe ro pagbu ge'u .e lo namcu .e lo linji
    html*: string
      ## ro pagbu cu selxra pa `figure` poi cmima `part`
      ##   .i lo pixra cu selpoi ta'i le pagbu
      ##   .i lo pixra pe le rebla cu romoi
    status*: string  ## lo linji poi cusku lo selvau be le pagbu
    count_parts*: int
    count_words*: int  ## lo du'u lo genvla cu vasru xo kau valsi
    count_errors*: int  ## lo du'u le pixra cu vasru xo kau srejge
    count_unread*: int  ## lo du'u lo pagbu poi no genvla cu vasru ke'a vasru xo kau valsi
    count_open*: int  ## lo du'u le rebla cu vasru xo kau pagbu noi ca'o kalri
    is_refused*: bool = false
      ## lo nu jmina cu to'e curmi lo selci'a be fi `NIF` be'o poi na se tcidu
      ##   .i se ki'u bo le pixra cu vasru no pagbu


const
  COLUMN* = 144  ## lo ni lo rajypau pe pa karda cu ganra
  WIDTH_PLACE* = 136  ## lo ni lo tanxe .e lo karda cu ganra
  HEIGHT_BOX* = 40  ## lo ni lo tanxe cu rajycla
  HEIGHT_CARD = 58  ## lo ni lo karda cu rajycla
  ROW* = 64  ## lo ni re lampinpoi be lo tanxe cu darno
  MARGIN = 10  ## lo kutkoi poi sruri le pixra
  LETTERS_MOST = 15  ## lo du'u pa karda cu ciska su'e xo kau lerfu pe le valsi
  LABEL_MOST = 17
    ## lo du'u pa tanxe cu ciska su'e xo kau lerfu pe le javni poi traji lo ka jibni lo valsi
  CHAIN_MOST = 21
    ## lo du'u pa tanxe cu ciska su'e xo kau lerfu pe le javni poi traji lo ka bartu ne'i le porsi
  TAG_ERROR = "srera"  ## lo tcita be lo srera jgena to `nif.nim` toi
  TAG_EXPECTS = "nitcu"
    ## lo tcita be lo genvla poi le gerna ka'e tcidu ke'a ca lo nu sisti to `nif.nim` toi
  TAG_UNREAD = "rivbi"  ## lo tcita be lo pagbu poi no genvla cu vasru ke'a to `nif.nim` toi
  TAG_QUOTING = ["ZOI"]  ## lo klesi be lo genvla poi ke'a sitna le cimoi lerpoi pe vo'a



#[ ni'o ni'o ni'o lo sinxa ]#

func escaped*(text: string): string =
  ## galfi lo selci'a tezu'e lo nu le selci'a cu selpu'i ne'i pa pagbu .a pa ckaji vu'o pe `SVG` .e
  ##     `HTML`
  text.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))


func clipped(text: string, count: int): string =
  ## ralte le krasi be le selci'a be'o poi vasru lo lerfu poi se kancu fi `count`
  ##   .i va'o lo nu le selci'a cu clamau le krasi kei le romoi lerfu pe le krasi cu du `…`
  if text.runeLen <= count: text else: text.runeSubStr(0, count - 1) & "…"


func mark(x, y: int; text, class: string): string =
  ## ciska pa pagbu po'u `text` ge'u zi'e poi se midju `x`
  "<text class=\"" & class & "\" x=\"" & $x & "\" y=\"" & $y & "\" text-anchor=\"middle\">" &
      text.escaped & "</text>"


func rectangle(x, y, width, height: int; class: string): string =
  ## ciska pa pagbu po'u `rect` ge'u zi'e poi ponse lo cukyko'a
  "<rect class=\"" & class & "\" x=\"" & $x & "\" y=\"" & $y & "\" width=\"" & $width &
      "\" height=\"" & $height & "\" rx=\"6\"/>"


func elbow(x_from, y_from, x_to, y_to: int): string =
  ## ciska pa jonli'i poi selkra lo dzikoi be pa tanxe gi'e selfa'o lo galkoi be lo selpu'i poi
  ##     cnita le tanxe
  ##   .i le linji cu ni'a klama lo kunti poi cnita le tanxe
  ##   .i ba bo le linji cu pinkla
  ##   .i ba bo le linji cu ni'a klama
  ##
  ## ni'o le kunti cu vasru no tanxe
  ##   .i no rajypau cu selvau re tanxe pe pa pinpoi
  ##   .i se ki'u bo le pinpau be le linji cu pencu no datyjonli'i
  ##
  ## ni'o le romoi sraji pagbu be le linji cu zvati lo midju be le selpu'i poi cnita le tanxe
  ##   .i le rajypau be le linji cu sepli ro datyta'e poi le linji cu klama lo mlana be ke'a ku'o
  ##       su'o pa rajypau
  ##   .i se ki'u bo le rajypau be le linji cu pencu no tanxe
  let turn = y_from + (ROW - HEIGHT_BOX) div 2
  if x_from == x_to:
    return "<line class=\"edge\" x1=\"" & $x_from & "\" y1=\"" & $y_from & "\" x2=\"" & $x_to &
        "\" y2=\"" & $y_to & "\"/>"
  "<polyline class=\"edge\" points=\"" & $x_from & "," & $y_from & " " & $x_from & "," &
      $turn & " " & $x_to & "," & $turn & " " & $x_to & "," & $y_to & "\"/>"



#[ ni'o ni'o ni'o lo jgena ]#

func spoken(tag: string): string =
  ## dunda lo cmene be le javni be'o poi `CLL 21.1` ciska ke'a
  ##   .i `-` basti ro `_` pe le tcita
  tag.replace('_', '-')


func said(letters: string): string =
  ## dunda le valsi ta'i le selci'a be la lojban.
  ##   .i `'` basti ro `h` pe `NIF`
  letters.replace('h', '\'')


func counted(count: int): string =
  ## dunda le namcu ta'i lo cmavo pe `PA` mu'u lu paci li'u
  ##   .i le genturfa'i na tcidu lo namcu poi selci'a ta'i `0` bi'o `9`
  ##   .i se ki'u bo le linji cu cusku ro namcu ta'i lo cmavo pe `PA`
  const digits = ["no", "pa", "re", "ci", "vo", "mu", "xa", "ze", "bi", "so"]
  for digit in $count: result.add digits[ord(digit) - ord('0')]


func isCompound(node: NodeNif): bool =
  ## jdice lo du'u le jgena cu cmima `KindNif.Compound` gi'e na minde
  node.kind == KindNif.Compound and not node.text.startsWith(".")


func isTerminal(node: NodeNif): bool =
  ## jdice lo du'u le jgena cu genvla
  ##   .i lo genvla cu cmima `KindNif.Compound`
  ##   .i le romoi panzi be lo genvla cu lerpoi
  node.isCompound and node.text notin [TAG_ERROR, TAG_UNREAD] and node.children.len > 0 and
      node.children[^1].kind == KindNif.Literal


func words(node: NodeNif): seq[tuple[start, finish: int, letters: string]] =
  ## tcidu ro valsi pe pa genvla .a pa pagbu poi no genvla cu vasru ke'a
  ##   .i lo stuzi cu lidne lo lerfu ne'i ro valsi
  var k = 0
  while k < node.children.len and node.children[k].kind != KindNif.Number: inc k
  while k + 2 < node.children.len:
    result.add (node.children[k].number, node.children[k + 1].number, node.children[k + 2].text)
    k += 3


func spelling(node: NodeNif): string =
  ## dunda lo lerfu pe pa genvla .a pa pagbu ta'i le selci'a
  ##   .i lo calyle'u cu jbini lo valsi
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
  ## cusku lo cmene be le javni poi traji lo ka jibni lo valsi
  ##   .i va'o lo nu le jgena cu porsi lo javni kei lo cmene cu se lidne le javni poi traji lo ka
  ##       bartu ku'o .e lo du'u le porsi cu vasru xo kau javni
  ##   .i le jgena cu jarco lo namcu pe le javni poi krasi le porsi
  ##   .i lo cmene be le javni poi fanmo le porsi cu jarco lo namcu pe le javni
  let inner = node.text.spoken
  if node.children.len == 0 or node.children[0].kind != KindNif.Number: return (inner, "")
  let top = node.children[0].number
  if inner notin LUT_NUMBER_BY_RULE: return (inner, "… " & $top)
  let key = (top, LUT_NUMBER_BY_RULE[inner])
  if key notin LUT_CHAIN_BY_ENDS: return (inner, "… " & $top)
  let chain = LUT_CHAIN_BY_ENDS[key]
  (inner, "… " & chain[0].rule & " " & $chain[0].number & " (" & $chain.len & ")")


func labelError(node: NodeNif): tuple[head, rule, expected: string] =
  ## cusku lo stuzi poi le gerna cu sisti bu'u ke'a ku'o .e le javni poi sisti bu'u le stuzi ku'o .e
  ##     ro genvla poi le gerna ka'e tcidu ke'a bu'u le stuzi
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
  let byte_stop = (if numbers.len > 0: "li " & numbers[0].counted else: "zo'e")
  ("srera · stuzi " & byte_stop, "ne'i " & rule, expected.join(" "))



#[ ni'o ni'o ni'o lo nu punji ]#

func columnX*(k: int): int =
  ## dunda lo midju be le rajypau pe `k`
  MARGIN + COLUMN * k + COLUMN div 2


func card(
  kind: KindPlace, cards: var seq[Place], lines: seq[string], title: string, count: int
): tuple[height, x, index: int, is_card: bool] =
  ## punji lo karda le bavla'i sraji pagbu gi'e dunda le karda ta'i lo selpu'i poi cnita le tanxe pe
  ##     le karda
  let column = cards.len
  cards.add Place(kind: kind, x: columnX(column), first: column, last: column, lines: lines,
      title: title, parent: -1, words: count)
  (0, columnX(column), column, true)


func placed(
  node: NodeNif, cards, boxes: var seq[Place]
): tuple[height, x, index: int, is_card: bool] =
  ## punji lo karda pe le jgena ta'i le porsi
  ##   .i ba bo punji le tanxe pe le jgena lo gapru be le karda
  ##   .i lo midju be le tanxe cu midju lo selpu'i poi cnita le tanxe
  ##   .i dunda lo ni le jgena cu gapru le karda kei .e lo midju .e lo namcu vu'o pe le selpu'i pe
  ##       le jgena
  ##   .i va'o lo nu le jgena cu vasru no valsi kei le ni gapru cu du li ni'u pa
  ##
  ## ni'o lo tanxe cu ponse lo namcu pe `boxes`
  ##   .i lo karda cu ponse lo namcu pe `cards`
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
    template child: untyped = node.children[k]  # lo drata cmene to `let` fukpi le mulno toi
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
    return card(KindPlace.Error, cards, @[label.head, label.rule], "nitcu " & label.expected, 0)
  var box = Place(kind: (if is_error: KindPlace.Error else: KindPlace.Rule),
      x: sum div under.len, height: height + 1, first: int.high, last: -1, parent: -1)
  if is_error:
    let label = node.labelError
    box.lines = @[label.head, label.rule]
    box.title = "nitcu " & label.expected
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
  ## punji ro selpu'i pe pa pagbu
  ##   .i ro valsi cu selxra pa karda ne'i lo rajypau pe vo'a bu'u le dzikoi
  ##   .i ba bo ro jgena cu selxra pa tanxe noi gapru le selpu'i pe lo panzi be le jgena
  ##   .i le genja cu gapru ro datselpu'i
  ##   .i ro karda cu lidne ro tanxe ne'i le liste be lo selpu'i
  ##   .i lo panzi cu lidne lo rirni
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



#[ ni'o ni'o ni'o lo nu pixra ]#

func svg*(part: PartDrawn, label: string): string =
  ## ciska pa pixra be le pagbu bei fo `SVG`
  ##   .i lo jonli'i cu lidne lo tanxe
  ##   .i lo tanxe cu lidne lo karda
  ##   .i ro selpu'i cu ponse lo cmene be vo'a
  var marks: seq[string]
  for k in 0 ..< part.places.len:
    template child: untyped = part.places[k]  # lo drata cmene to `let` fukpi le mulno toi
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


func readParts(module: string): seq[NodeNif] =
  ## dunda ro jgena poi na minde gi'e pagbu le selci'a be fi `NIF` ku'o ta'i le porsi
  for node in module.readModule:
    if node.isCompound: result.add node


func drawn*(nif, tail: string): DrawingLive =
  ## ciska lo pixra be ro pagbu be le ca selci'a be fi `NIF`
  ##   .i ba bo ciska lo pixra be ro pagbu be le rebla noi ca'o kalri
  ##   .i ro pagbu cu selxra pa `figure`
  ##   .i le linji cu cusku lo selvau be le pagbu
  var parts, opened: seq[NodeNif]
  try:
    parts = nif.readParts
    opened = (VERSION & "\n" & tail).readParts
  except ValueError as error:
    result.status = "NIF na se tcidu · " & error.msg
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
    let label = "le " & counted(k + 1) & "moi pagbu" & (if is_open: " · ca'o kalri" else: "") &
        ": " & node.text.spoken
    result.html.add "<figure class=\"part" & (if is_open: " open" else: "") & "\">" &
        part.svg(label) & "</figure>"
  result.count_parts = parts.len
  result.count_open = opened.len
  result.status = counted(parts.len) & " pagbu · " & counted(result.count_words) & " valsi · " &
      counted(result.count_errors) & " srera · " & counted(result.count_unread) &
      " valsi poi na se tcidu" &
      (if opened.len > 0: " · " & counted(opened.len) & " pagbu poi ca'o kalri" else: "")


func drawnMerged*(nif: string): DrawingLive =
  ## jmina ro pagbu be le ca selci'a be fi `NIF` to `merge.nim` toi
  ##   .i ciska lo pixra be ro tricu poi lo nu jmina cu jarco ke'a ku'o ta'i pa pagbu
  ##   .i va'o lo nu lo nu jmina cu jarco le tricu pe lo nu tcidu le mulselci'a kei le linji cu
  ##       cusku pa tricu
  ##   .i va'o lo drata le linji cu cusku lo selvau be le tricu
  ##   .i va'o lo nu le selci'a be fi `NIF` na se tcidu cu ciska no pixra gi'e cusku le jgena .e le
  ##       krinu ne'i le linji
  let merged = nif.mergeParts
  if not merged.is_merged:
    result.is_refused = true
    result.status = "le nu jmina cu se to'e curmi"
    if merged.part.isSome: result.status.add " · le " & counted(merged.part.get + 1) & "moi pagbu"
    result.status.add " · " & merged.reason
    return
  result = drawn(merged.nif, "")
  if merged.is_whole:
    result.status = "se jmina · pa tricu · " & counted(result.count_words) &
        " valsi · simsa lo nu tcidu le mulselci'a pa roi"
    return
  result.status = "se jmina · " & counted(result.count_parts) & " tricu · " &
      counted(result.count_words) & " valsi · " & counted(result.count_errors) & " srera · " &
      counted(result.count_unread) & " valsi poi na se tcidu"
