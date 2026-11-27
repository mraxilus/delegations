## le samtci pe le papri poi skari lo valsi gi'e pixra lo linji pe lo tricu ne'i le selci'a
##   .i le stuzi be lo nu ciska cu du le se ciska poi skari to `D2` pe `#1055` toi
##   .i ro nu cenba cu cenba le selci'a gi'e rinka lo nu le papri cu pixra le selci'a ca pa roi
##   .i pa gunka cu tcidu le selci'a ta'i `readTextMarked` gi'e gunma le tricu ta'i lo linji to
##       `layers.nim` toi
##   .i va'o lo nu le papri cu to'e curmi le gunka kei le papri cu tcidu ba lo nu le nu ciska cu
##       denpa
##
## ni'o ro lerfu pe le selci'a cu zvati pa stuzi pe le papri
##   .i `data-s` pe le stuzi cu sinxa le pamoi lerfu pe le stuzi
##   .i se ki'u bo ro stuzi pe le cuxna cu mapti pa stuzi pe le selci'a
##   .i ro stuzi pe le selci'a cu mapti pa stuzi pe le cuxna
##   .i lo cmene pe lo selma'o .e lo linji cu zvati lo bartu be le se ciska gi'e se ciska fi
##       `CSS` po'o
##   .i se ki'u bo lo samtci pe lo jbobatke cu tcidu le selci'a po'o
##
## ni'o pa nu samcu'a pa valsi .a pa linji cu cmene ro linji poi vasru ke'a
##   .i le cmene cu basti lo pagbu be le linji ta'i pa lerfu ca pa roi
##   .i ro nu muvdu cu fasnu ta'i pa temci po'o

{.experimental: "strictFuncs".}

import std/[jsffi, options, sugar, unicode]

import ../ricysoho/[grammar, layers, prose, stream]
import ./samples_layers


const
  NAME_WORKER = "ricyso'o layers"  ## le cmene be le gunka
  ROW = 7.0  ## lo ni gapru be pa pagbu be lo linji ca lo nu surla to `px` toi
  ROW_OPEN = 14.0  ## lo ni gapru be pa pagbu be lo linji ca lo nu pa cmene cu zvati ke'a
  SPEED = 0.25  ## lo ni sutra be pa korbi be lo linji to `px` ca ro `ms` toi
  EDGE_LEAST = 160.0  ## lo traji cmalu temci be lo nu muvdu pa korbi to `ms` toi
  EDGE_MOST = 420.0  ## lo traji barda temci be lo nu muvdu pa korbi to `ms` toi
  TIME_ROWS = 220.0  ## lo temci be lo nu muvdu lo pagbu be lo ni gapru to `ms` toi
  GAP = 3.0  ## lo ni jbini be pa cmene .e le linji poi lidne ke'a to `px` toi
  PAUSE = 250
    ## lo temci poi le papri cu denpa pu lo nu tcidu to `ms` toi
    ##   .i le papri cu denpa va'o lo nu le papri cu ponse no gunka
  CLASS_GROUP: array[Group, cstring] = ["g-pred", "g-sumti", "g-num", "g-tag", "g-link",
      "g-free", "g-struct", "g-bad"]
    ## lo klesi pe `CSS` pe ro girzu be lo valsi
  CLASS_MARK: array[Category, cstring] = ["thin", "dot", "", "", "", "half", "", "", "half", "",
      "half", "", "dash"]
    ## lo klesi pe `CSS` pe le tarmi be ro klesi be lo linji
  NAME_CATEGORY: array[Category, cstring] = ["bridi", "romoi", "sumti", "selbri", "tanru",
      "tanru pagbu", "poi", "nu", "be", "tcita sumti", "tcita", "namcu", "zmadu"]
    ## le cmene be ro klesi be lo linji be'o poi le papri cu ciska ke'a
  HUE_CATEGORY: array[Category, cstring] = ["var(--c-bridi)", "var(--c-bridi)",
      "var(--c-sumti)", "var(--c-pred)", "var(--c-pred)", "var(--c-pred)", "var(--c-link)",
      "var(--c-link)", "var(--c-link)", "var(--c-tag)", "var(--c-tag)", "var(--c-num)",
      "var(--muted)"]
    ## le skari be ro klesi be lo linji


type
  Word* = object  ## pa valsi pe lo se tcidu ge'u ta'i lo stuzi pe `UTF-16`
    s*: int  ## le stuzi pe le pamoi lerfu
    e*: int  ## le stuzi poi lidne le romoi lerfu
    group*: int  ## le girzu be le valsi to `Group` toi
    gloss*: cstring  ## le cmene be le selma'o
    text*: cstring  ## le lerfu pe le valsi

  BarView* = object  ## pa linji pe lo se tcidu
    category*: int
    first*: int
    last*: int
    parent*: int
    height*: int
    depth*: int
    rule*: cstring

  Model* = object  ## lo se tcidu pe pa selci'a
    text*: cstring
    words*: seq[Word]
    bars*: seq[BarView]
    rows*: int
    nodes*: int  ## lo klani be lo jgena pe le tricu poi na genvla
    sentences*: int  ## lo klani be lo bridi poi no linji cu vasru ke'a
    stop*: int
      ## lo stuzi poi le gerna cu sisti bu'u ke'a
      ##   .i li -1 va'o lo nu le gerna na sisti
    is_moved*: bool  ## le se tcidu cu muvdu ja'i pa cenba gi'e na se tcidu

  Fill = ref object  ## pa pagbu be pa linji poi zvati pa linji be lo selci'a
    el: JsObject
    host: JsObject
    bar: int
    line: int
    row: int
    left: float
    width: float
    cut: float
    target: float
    edge: float
    edge_target: float

  Label = ref object  ## pa cmene be pa linji
    el: JsObject
    key: string
    row: int
    line: int
    is_alive: bool

  Segment = ref object  ## pa nu muvdu pa korbi
    fills: seq[Fill]
    begin: seq[float]
    letters: seq[(JsObject, float)]
    origin: float
    source: float
    goal: float
    start: float
    length: float
    is_done: bool

  Key = object  ## pa valsi .a pa linji poi le prenu cu cuxna ke'a
    is_word: bool
    index: int

  View = ref object  ## le pixra pe pa se tcidu
    box: JsObject
    model: Model
    chains: seq[seq[int]]  ## ro linji poi vasru ro valsi
    kids: seq[seq[int]]
    fills: seq[Fill]
    labels: seq[Label]
    lines: seq[float]
    raf: int
    hovered: Option[Key]
    clicked: Option[Key]
    width: int
    observer: JsObject



#[ ni'o ni'o ni'o lo korbi be `JS` ]#

let
  DOCUMENT_PAGE {.nodecl, importc: "(typeof document === 'undefined' ? null : document)".}:
      JsObject
    ## `document` pe le papri
    ##   .i `null` ne'i le gunka
  SELF {.nodecl, importc: "self".}: JsObject  ## le gunka .a le papri

proc emptyObject(): JsObject {.importjs: "({})".}
  ## zbasu pa kunti dacti pe `JS`
proc byId(id: cstring): JsObject {.importjs: "document.getElementById(#)".}
  ## dunda le dacti poi `id` cmene ke'a
proc query(root: JsObject, selector: cstring): JsObject {.importjs: "#.querySelector(#)".}
  ## dunda le pamoi dacti poi mapti `selector`
proc queryAll(root: JsObject, selector: cstring): seq[JsObject]
    {.importjs: "Array.from(#.querySelectorAll(#))".}
  ## dunda ro dacti poi mapti `selector`
proc created(tag: cstring): JsObject {.importjs: "document.createElement(#)".}
  ## zbasu pa dacti pe `HTML`
proc texted(text: cstring): JsObject {.importjs: "document.createTextNode(#)".}
  ## zbasu pa dacti pe lo selci'a
proc append(parent, child: JsObject) {.importjs: "#.append(#)".}
  ## jmina `child` le fanmo be `parent`
proc prepend(parent, child: JsObject) {.importjs: "#.prepend(#)".}
  ## jmina `child` le krasi be `parent`
proc removed(node: JsObject) {.importjs: "#.remove()".}
  ## vimcu le dacti
proc emptied(node: JsObject) {.importjs: "#.replaceChildren()".}
  ## vimcu ro panzi be le dacti
proc replaced(node, child: JsObject) {.importjs: "#.replaceChildren(#)".}
  ## basti ro panzi be le dacti `child`
proc closest(node: JsObject, selector: cstring): JsObject {.importjs: "#.closest(#)".}
  ## dunda le dacti poi mapti `selector` gi'e vasru `node`
proc attribute(node: JsObject, name, value: cstring) {.importjs: "#.setAttribute(#, #)".}
  ## punji pa ckaji
proc attributeOf(node: JsObject, name: cstring): cstring {.importjs: "#.getAttribute(#)".}
  ## dunda pa ckaji to `null` va'o lo nu le dacti cu ponse no ckaji toi
proc attributeInt(node: JsObject, name: cstring): int {.importjs: "(+#.getAttribute(#))".}
  ## dunda pa ckaji ta'i lo namcu
proc hasAttribute(node: JsObject, name: cstring): bool {.importjs: "#.hasAttribute(#)".}
  ## jdice lo du'u le dacti cu ponse le ckaji
proc toggled(node: JsObject, name: cstring, is_on: bool) {.importjs: "#.classList.toggle(#, #)".}
  ## punji ja vimcu pa klesi pe `CSS`
proc hasClass(node: JsObject, name: cstring): bool {.importjs: "#.classList.contains(#)".}
  ## jdice lo du'u le dacti cu ponse le klesi
proc styled(node: JsObject, name, value: cstring) {.importjs: "#.style.setProperty(#, #)".}
  ## punji pa ckaji pe `CSS`
proc unstyled(node: JsObject, name: cstring) {.importjs: "#.style.removeProperty(#)".}
  ## vimcu pa ckaji pe `CSS`
proc styleOf(node: JsObject, name: cstring): cstring
    {.importjs: "getComputedStyle(#).getPropertyValue(#)".}
  ## dunda pa ckaji pe `CSS` poi le papri cu pilno ke'a
proc rect(node: JsObject): JsObject {.importjs: "#.getBoundingClientRect()".}
  ## dunda le kurfa be le dacti
proc listened(node: JsObject, name: cstring, handler: proc(event: JsObject))
    {.importjs: "#.addEventListener(#, #)".}
  ## jmina pa fancu pe pa nu fasnu
proc prevented(event: JsObject) {.importjs: "#.preventDefault()".}
  ## rivbi lo nu le papri cu gunka le nu fasnu
proc now(): float {.importjs: "performance.now()".}
  ## dunda le ca temci to `ms` toi
proc framed(handler: proc()): int {.importjs: "requestAnimationFrame(#)".}
  ## gunka `handler` ca le bavla'i nu le papri cu pixra
proc unframed(id: int) {.importjs: "cancelAnimationFrame(#)".}
  ## rivbi pa nu gunka ca lo nu pixra
proc later(handler: proc(), milliseconds: int): int {.importjs: "setTimeout(#, #)".}
  ## gunka `handler` ba lo temci
proc unlater(id: int) {.importjs: "clearTimeout(#)".}
  ## rivbi pa nu gunka ba lo temci
proc isStill(): bool {.importjs:
  "!!(window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches)".}
  ## jdice lo du'u le prenu cu cpedu lo nu no da muvdu
proc selection(): JsObject {.importjs: "getSelection()".}
  ## dunda le cuxna pe le papri
proc range(): JsObject {.importjs: "document.createRange()".}
  ## zbasu pa kunti stuzi pe le papri
proc slice(text: cstring, a, b: int): cstring {.importjs: "#.slice(#, #)".}
  ## dunda le pagbu be le selci'a poi zvati `a` bi'o `b` noi pagbu pe `UTF-16`
proc lengthUnits(text: cstring): int {.importjs: "#.length".}
  ## kancu lo pagbu pe `UTF-16` ne'i le selci'a
proc unitAt(text: cstring, at: int): int {.importjs: "#.charCodeAt(#)".}
  ## dunda pa pagbu pe `UTF-16`
proc join(a, b: cstring): cstring {.importjs: "(# + #)".}
  ## jorne re selci'a
proc isSpace(text: cstring, at: int): bool {.importjs: "/\\s/.test(#.charAt(#))".}
  ## jdice lo du'u lo lerfu cu kunti
proc lines(text: cstring): seq[cstring] {.importjs: "#.split('\\n')".}
  ## katna le selci'a bu'u ro linji fanmo
proc lineEnds(text: cstring): cstring {.importjs: "#.replace(/\\r\\n?/g, '\\n')".}
  ## basti ro linji fanmo pe `CR` lo linji fanmo pe `LF`
proc data(event: JsObject): JsObject {.importjs: "#.data".}
  ## dunda le datni pe pa nu fasnu
proc plain(event: JsObject): cstring {.importjs:
  "(function(e) { " &
  "return (e.dataTransfer && e.dataTransfer.getData('text/plain')) || e.data || ''; })(#)".}
  ## dunda le selci'a pe pa nu punji



#[ ni'o ni'o ni'o lo nu tcidu ]#

func unitsByByte(text: string): seq[int] =
  ## le stuzi pe `UTF-16` pe ro stuzi pe `UTF-8` ne'i le selci'a
  result = newSeq[int](text.len + 1)
  var (at, units) = (0, 0)
  while at < text.len:
    let
      size = text.runeLenAt(at)
      rune = text.runeAt(at)
    for k in 0 ..< size: result[at + k] = units
    units += (if int32(rune) > 0xFFFF: 2 else: 1)
    at += size
  result[text.len] = units


func counted(node: Node): int =
  ## lo klani be lo jgena poi na genvla gi'e zvati `node`
  if node.is_terminal: return 0
  result = 1
  for child in node.children: result += child.counted


proc toModel*(text: cstring): Model =
  ## tcidu le selci'a ta'i `readTextMarked` gi'e gunma le tricu ta'i lo linji
  let
    source = $text
    reading = source.readTextMarked
    layers = reading.toLayers
    units = source.unitsByByte
  result = Model(text: text, rows: layers.rows, nodes: reading.tree.counted, stop: -1)
  for occurrence in reading.occurrences:
    result.words.add Word(s: units[min(occurrence.start, source.len)],
        e: units[min(occurrence.finish, source.len)], group: ord(occurrence.reading.toGroup),
        gloss: cstring(occurrence.reading.toGloss), text: cstring(occurrence.text))
  for bar in layers.bars:
    result.bars.add BarView(category: ord(bar.category), first: bar.first, last: bar.last,
        parent: bar.parent, height: bar.height, depth: bar.depth, rule: cstring(bar.rule))
    if bar.category == Category.Bridi and bar.parent < 0: inc result.sentences
  if reading.tree.stop.isSome:
    let at = reading.tree.stop.get.at
    result.stop = if at < reading.units.len and reading.units[at].words.len > 0:
        result.words[reading.units[at].words[0]].s else: text.lengthUnits



#[ ni'o ni'o ni'o le gunka ]#

proc answered(event: JsObject) =
  ## spuda pa nu cpedu poi vasru `id` .e `text`
  let
    model = toModel(event.data.text.to(cstring))
    answer = emptyObject()
  answer.id = event.data.id
  answer.model = model.toJs
  SELF.postMessage(answer)


proc isWorkerLayers(): bool =
  ## jdice lo du'u le samtci cu gunka ne'i le gunka pe le papri
  DOCUMENT_PAGE.isNull and SELF.name.to(cstring) == NAME_WORKER



#[ ni'o ni'o ni'o lo nu pixra ]#

func chained(model: Model): (seq[seq[int]], seq[seq[int]]) =
  ## ro linji poi vasru ro valsi ku'o .e ro panzi be ro linji
  var
    chains = newSeq[seq[int]](model.words.len)
    kids = newSeq[seq[int]](model.bars.len)
  for k, bar in model.bars:
    if bar.parent >= 0: kids[bar.parent].add k
    for word in bar.first .. min(bar.last, model.words.high): chains[word].add k
  (chains, kids)


func rowsAbove(row: int): cstring =
  ## le stuzi pe le pagbu `row` ta'i `CSS`
  ##   .i le stuzi cu sumji ro pagbu poi zvati le gapru
  var rows = ""
  for above in 0 ..< row: rows.add (if above > 0: " + " else: "") & "var(--h" & $above & ", 7px)"
  cstring(if rows.len == 0: "var(--gl, 17px)"
      else: "var(--gl, 17px) + (" & rows & ") * var(--bars, 1)")


proc spanned(tag, class_name: cstring, text: cstring = ""): JsObject =
  ## zbasu pa dacti poi ponse pa klesi .e pa selci'a
  result = created(tag)
  result.className = class_name
  if text.lengthUnits > 0: result.append texted(text)


proc drawn(): JsObject =
  ## zbasu lo stuzi be lo pixra poi zvati lo bartu be le se ciska
  result = spanned("span", "ann")
  result.contentEditable = cstring("false")
  result.attribute("aria-hidden", "true")


proc columns(model: Model, chains: seq[seq[int]]): JsObject =
  ## pixra ro valsi ta'i pa stuzi be lo selci'a be'o .e lo cmene be le selma'o .e lo linji
  ##   .i ro lerfu pe le selci'a cu zvati pa stuzi pe le papri
  let
    box = spanned("div", "flow named anim")
    text = model.text
    cut = if model.stop >= 0: model.stop else: text.lengthUnits + 1
  proc between(s, e: int, col: JsObject) =
    var at = s
    for k, line in text.slice(s, e).lines:
      if k > 0:
        let mark = created("br")
        mark.attribute("data-s", cstring($(at - 1)))
        box.append mark
      let host = spanned("span", if at >= cut: cstring("tx raw") else: cstring("tx"), line)
      host.attribute("data-s", cstring($at))
      if k == 0 and not col.isNull: col.prepend host
      elif line.lengthUnits > 0:
        let
          tk = spanned("span", "tk")
          alone = spanned("span", "col")
        alone.append host
        tk.append alone
        box.append tk
      at += line.lengthUnits + 1
  between(0, if model.words.len > 0: model.words[0].s else: text.lengthUnits, nil)
  for i, word in model.words:
    var per: seq[int]
    for bar in chains[i]:
      while per.len <= model.bars[bar].height: per.add -1
      per[model.bars[bar].height] = bar
    var next: seq[int]
    if i + 1 < model.words.len:
      for bar in chains[i + 1]:
        while next.len <= model.bars[bar].height: next.add -1
        next[model.bars[bar].height] = bar
    let
      ann_word = drawn()
      ann_gap = drawn()
    # lo valsi poi le gerna cu sisti pu ke'a zi'e poi no linji cu vasru ke'a cu se tcidu no da
    let
      after = if word.s >= cut and chains[i].len == 0: cstring(" tail") else: cstring("")
      host = spanned("span", cstring("w ") & CLASS_GROUP[Group(word.group)] & after,
          text.slice(word.s, word.e))
    host.attribute("data-w", cstring($i))
    host.attribute("data-s", cstring($word.s))
    let tx = spanned("span", "tx")
    tx.append host
    let col_word = spanned("span", "col")
    col_word.append tx
    col_word.append ann_word
    let col_gap = spanned("span", "col")
    col_gap.append ann_gap
    let tk = spanned("span", "tk")
    tk.append col_word
    tk.append col_gap
    box.append tk
    between(word.e, if i + 1 < model.words.len: model.words[i + 1].s else: text.lengthUnits,
        col_gap)
    let gloss_word = spanned("span", "gl")
    gloss_word.attribute("data-gl", word.gloss)
    ann_word.append gloss_word
    let gloss_gap = spanned("span", "gl")
    gloss_gap.attribute("data-gl", " ")
    ann_gap.append gloss_gap
    let padding = cstring("calc(") & rowsAbove(per.len) & cstring(")")
    col_word.styled("--n", cstring($word.gloss.lengthUnits))
    col_word.styled("--pb", padding)
    col_gap.styled("--n", "1")
    col_gap.styled("--pb", padding)
    for row in 0 ..< per.len:
      let
        cell_word = spanned("span", "cell")
        cell_gap = spanned("span", "cell")
      for cell in [cell_word, cell_gap]:
        cell.attribute("data-r", cstring($row))
        cell.styled("--h", cstring("var(--h" & $row & ", 7px)"))
        cell.styled("top", cstring("calc(") & rowsAbove(row) & cstring(")"))
      let k = per[row]
      if k >= 0:
        let
          bar = model.bars[k]
          category = Category(bar.category)
        var marks = $CLASS_MARK[category]
        if bar.first == i: marks.add " s"
        if bar.last == i: marks.add " e"
        let piece = spanned("i", cstring(marks))
        piece.styled("--k", HUE_CATEGORY[category])
        piece.attribute("data-b", cstring($k))
        piece.attribute("data-n", NAME_CATEGORY[category])
        cell_word.append piece
        if bar.last > i and row < next.len and next[row] == k:
          let joint = spanned("i", CLASS_MARK[category])
          joint.styled("--k", HUE_CATEGORY[category])
          joint.attribute("data-b", cstring($k))
          cell_gap.append joint
      ann_word.append cell_word
      ann_gap.append cell_gap
  if text.lengthUnits == 0 or text.slice(text.lengthUnits - 1, text.lengthUnits) == "\n":
    box.append spanned("br", "ph")
  box



#[ ni'o ni'o ni'o lo nu cmene lo linji ]#

proc lineIndex(view: View, node: JsObject): int =
  ## le stuna'u pe le linji be lo selci'a poi `node` zvati ke'a
  let top = node.closest(".tk").rect.top.to(float)
  for k, line in view.lines:
    if abs(line - top) < 0.5: return k
  -1


proc countLines(view: View) =
  ## kancu ro linji be lo selci'a ta'i lo gapru
  view.lines.setLen 0
  for tk in view.box.queryAll(".tk"):
    let top = tk.rect.top.to(float)
    var is_known = false
    for line in view.lines:
      if abs(line - top) < 0.5: is_known = true
    if not is_known: view.lines.add top
  for a in 0 ..< view.lines.len:
    for b in a + 1 ..< view.lines.len:
      if view.lines[b] < view.lines[a]: swap(view.lines[a], view.lines[b])


proc built(view: View) =
  ## basti ro pagbu be pa linji poi zvati pa linji be lo selci'a pa tanxe poi ponse re mluni korbi
  if view.fills.len > 0: return
  var pieces: seq[(int, int, int, float, float, seq[JsObject])]
  for piece in view.box.queryAll(".cell i[data-b]"):
    let
      bar = piece.attributeInt("data-b")
      line = view.lineIndex(piece)
      r = piece.rect
    var found = -1
    for k, p in pieces:
      if p[0] == bar and p[1] == line: found = k
    if found < 0:
      pieces.add (bar, line, piece.parentNode.attributeInt("data-r"),
          r.left.to(float), r.right.to(float), @[piece])
    else:
      pieces[found][3] = min(pieces[found][3], r.left.to(float))
      pieces[found][4] = max(pieces[found][4], r.right.to(float))
      pieces[found][5].add piece
  for (bar, line, row, left, right, parts) in pieces:
    var host = parts[0]
    for part in parts:
      if part.rect.left.to(float) < host.rect.left.to(float): host = part
    let fill = spanned("span", "fill")
    fill.styled("right", cstring($(host.rect.right.to(float) - right) & "px"))
    host.prepend fill
    for part in parts: part.toggled("solo", true)
    view.fills.add Fill(el: fill, host: host, bar: bar, line: line, row: row, left: left,
        width: right - left)


func reach(view: View, key: Option[Key]): (seq[int], int, int) =
  ## ro linji poi le cuxna cu vasru ke'a ku'o .e le pamoi valsi .e le romoi valsi
  ##   .i pa valsi cu vasru ro linji poi vasru le valsi
  ##   .i pa linji cu vasru vo'a .e ro linji poi vo'a vasru ke'a
  if key.isNone: return (@[], 1, 0)
  let chosen = key.get
  if chosen.is_word: return (view.chains[chosen.index], chosen.index, chosen.index)
  var
    bars = @[chosen.index]
    k = 0
  while k < bars.len:
    for kid in view.kids[bars[k]]: bars.add kid
    inc k
  (bars, view.model.bars[chosen.index].first, view.model.bars[chosen.index].last)


proc highlighted(view: View, key: Option[Key]) =
  ## carmi ro linji .e ro valsi poi le cuxna cu vasru ke'a
  let (bars, first, last) = view.reach(key)
  for node in view.box.queryAll(".hl"): node.toggled("hl", false)
  view.box.toggled("dimmed", key.isSome)
  for bar in bars:
    for node in view.box.queryAll(cstring("[data-b=\"" & $bar & "\"]")): node.toggled("hl", true)
  for word in first .. last:
    for node in view.box.queryAll(cstring("[data-w=\"" & $word & "\"]")): node.toggled("hl", true)


func eased(t: float): float =
  ## le korbi be lo nu muvdu to `ease-in-out` pe le cimoi toi
  if t < 0.5: 4 * t * t * t else: 1 - (-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2) / 2


func clamped(x, least, most: float): float = min(most, max(least, x))
  ## le namcu poi zvati lo jbini be `least` .e `most`


proc isOpen(view: View, row: int): bool =
  ## jdice lo du'u pa cmene cu zvati le pagbu be lo ni gapru
  let cell = view.box.query(cstring(".cell[data-r=\"" & $row & "\"]"))
  not cell.isNull and cell.hasClass("open")


proc named(view: View, key: Option[Key]) =
  ## cmene ro linji poi le cuxna cu vasru ke'a gi'e vimcu ro drata cmene
  ##   .i lo cmene poi vimcu cu pamoi muvdu
  ##   .i ba bo ro pagbu be lo ni gapru cu muvdu ta'i pa nu muvdu
  ##   .i ba bo lo cnino cmene cu muvdu
  view.countLines
  view.built
  let (bars, _, _) = view.reach(key)
  var rows_wanted: seq[int]
  for bar in bars: rows_wanted.add view.model.bars[bar].height
  var
    segments: seq[Segment]
    groups: seq[seq[Fill]]  ## ro pagbu be lo linji poi zvati pa pagbu be lo ni gapru .e pa linji
  for fill in view.fills:
    var found = -1
    for k, group in groups:
      if group[0].row == fill.row and group[0].line == fill.line: found = k
    if found < 0: groups.add @[fill] else: groups[found].add fill
  for label in view.labels: label.is_alive = false
  for list in groups.mitems:
    for a in 0 ..< list.len:
      for b in a + 1 ..< list.len:
        if list[b].left < list[a].left: swap(list[a], list[b])
    # lo cmene cu zvati lo pritu be lo cmene poi lidne ke'a
    var runs: seq[(float, float)]
    for fill in list:
      if fill.bar notin bars: continue
      if runs.len == 0 or runs[^1][1] <= fill.left: runs.add (fill.left, fill.left)
      let
        start = max(fill.left, runs[^1][1])
        key_label = $fill.bar & ":" & $fill.line
      var label: Label = nil
      for known in view.labels:
        if known.key == key_label: label = known
      if label.isNil:
        let
          name = spanned("b", "auto hov")
          letters = fill.host.attributeOf("data-n")
        for at in 0 ..< letters.lengthUnits:
          let letter = created("span")
          letter.attribute("data-c", letters.slice(at, at + 1))
          name.append letter
        fill.host.append name
        label = Label(el: name, key: key_label, row: fill.row, line: fill.line)
        view.labels.add label
      label.is_alive = true
      label.el.styled("left", cstring($(start - fill.left) & "px"))
      runs[^1][1] = label.el.rect.right.to(float) + GAP
    for fill in list:
      fill.target = 0
      fill.edge_target = 0
      for run in runs:
        if fill.left >= run[0] - 0.5 and fill.left < run[1]:
          fill.target = min(fill.width, run[1] - fill.left)
          fill.edge_target = run[1]
    # lo korbi poi ca zvati
    var regions: seq[(float, float)]
    for fill in list:
      if fill.cut <= 0.5: continue
      let reach_end = max(fill.left + fill.cut, fill.edge)
      if regions.len > 0 and fill.left < regions[^1][1] + 0.5:
        regions[^1][1] = max(regions[^1][1], reach_end)
      else: regions.add (fill.left, reach_end)
    for run in runs:
      var source = run[0]
      for region in regions:
        if abs(region[0] - run[0]) < 0.5: source = region[1]
      segments.add Segment(fills: list, origin: run[0], source: source, goal: run[1])
    for region in regions:
      var is_inside = false
      for run in runs:
        if region[0] >= run[0] - 0.5 and region[0] < run[1]: is_inside = true
      if not is_inside:
        segments.add Segment(fills: list, origin: region[0], source: region[1], goal: region[0])
  # le pamoi nu muvdu cu vimcu lo cmene
  #   .i ba bo lo pagbu be lo ni gapru cu muvdu
  #   .i ba bo lo cnino cmene cu muvdu
  let is_still = isStill()
  proc duration(segment: Segment): float =
    if is_still: 0.0
    else: clamped(abs(segment.goal - segment.source) / SPEED, EDGE_LEAST, EDGE_MOST)
  var moving: seq[Segment]
  for segment in segments:
    if abs(segment.goal - segment.source) > 0.5: moving.add segment
  var leave = 0.0
  for segment in moving:
    if segment.goal < segment.source: leave = max(leave, segment.duration)
  var rows_moving: seq[int]
  for row in 0 ..< view.model.rows:
    if (row in rows_wanted) != view.isOpen(row): rows_moving.add row
  let time_rows = if rows_moving.len > 0 and not is_still: TIME_ROWS else: 0.0
  for segment in moving:
    segment.length = segment.duration
    segment.start = if segment.goal < segment.source: 0.0 else: leave + time_rows
    let high = max(segment.source, segment.goal)
    var inside: seq[Fill]
    for fill in segment.fills:
      if fill.left >= segment.origin - 0.5 and fill.left < high: inside.add fill
    segment.fills = inside
    for fill in inside: segment.begin.add fill.cut
    for label in view.labels:
      if label.row != segment.fills[0].row or label.line != segment.fills[0].line: continue
      for letter in label.el.queryAll("span"):
        let right = letter.rect.right.to(float)
        if right > segment.origin and right <= high + 1: segment.letters.add (letter, right)
  # pa cmene poi stali bu'u lo stuzi poi no korbi cu muvdu ke'a cu mulno se viska
  for label in view.labels:
    if not label.is_alive: continue
    for letter in label.el.queryAll("span"):
      var is_moving = false
      for segment in moving:
        for (moved, _) in segment.letters:
          if moved == letter: is_moving = true
      if not is_moving: letter.styled("opacity", "1")
  var row_moves: seq[(int, float, float)]
  for row in rows_moving:
    let
      cells = view.box.queryAll(cstring(".cell[data-r=\"" & $row & "\"]"))
      source = cells[0].rect.height.to(float)
    for cell in cells: cell.toggled("open", row in rows_wanted)
    row_moves.add (row, source, if row in rows_wanted: ROW_OPEN else: ROW)
  proc rowSet(row: int, height: float) =
    view.box.styled(cstring("--h" & $row), cstring($height & "px"))
  for (row, source, _) in row_moves: rowSet(row, source)
  unframed(view.raf)
  let start = now()
  proc frame() =
    let at = now() - start
    var is_busy = false
    # ro nu muvdu cu ciska ca le temci pe vo'a po'o
    for segment in moving:
      if segment.is_done: continue
      is_busy = true
      if at < segment.start: continue
      let p = if segment.length > 0: clamped((at - segment.start) / segment.length, 0, 1) else: 1.0
      if p >= 1: segment.is_done = true
      let
        edge = segment.source + (segment.goal - segment.source) * p.eased
        is_growing = segment.goal > segment.source
      for k, fill in segment.fills:
        let here = clamped(edge - fill.left, 0, fill.width)
        fill.cut = if is_growing: min(fill.target, max(segment.begin[k], here))
          else: max(fill.target, min(segment.begin[k], here))
        fill.edge = edge
        fill.el.styled("left", cstring($fill.cut & "px"))
      for (letter, right) in segment.letters:
        letter.styled("opacity", cstring($clamped((edge - right) / GAP, 0, 1)))
    let p_rows = if time_rows > 0: clamped((at - leave) / time_rows, 0, 1)
      elif at >= leave: 1.0 else: 0.0
    if p_rows < 1: is_busy = true
    for (row, source, goal) in row_moves: rowSet(row, source + (goal - source) * p_rows.eased)
    if is_busy:
      view.raf = framed(frame)
      return
    for (row, _, goal) in row_moves:
      if goal == ROW: view.box.unstyled(cstring("--h" & $row)) else: rowSet(row, goal)
    for fill in view.fills:
      fill.cut = fill.target
      fill.edge = fill.edge_target
      fill.el.styled("left", cstring($fill.cut & "px"))
    var kept: seq[Label]
    for label in view.labels:
      if label.is_alive: kept.add label else: label.el.removed
    view.labels = kept
  view.raf = framed(frame)


func toKey(node: JsObject): Key =
  ## le valsi .a le linji poi `node` sinxa ke'a
  if node.hasAttribute("data-w"): Key(is_word: true, index: node.attributeInt("data-w"))
  else: Key(is_word: false, index: node.attributeInt("data-b"))


proc chosenNode(event: JsObject): JsObject =
  ## le valsi .a le linji poi le nu fasnu cu tarmi ke'a
  event.target.closest("[data-w],[data-b]")


proc closed(view: View) =
  ## vimcu ro cmene
  if view.clicked.isSome:
    view.clicked = none(Key)
    view.named(none(Key))
    view.highlighted(view.hovered)


proc reset(view: View) =
  ## vimcu ro cmene .e ro tanxe pe lo linji ca lo nu le ni ganra cu cenba
  unframed(view.raf)
  view.clicked = none(Key)
  for label in view.labels: label.el.removed
  view.labels.setLen 0
  for fill in view.fills: fill.el.removed
  view.fills.setLen 0
  for node in view.box.queryAll(".solo"): node.toggled("solo", false)
  for node in view.box.queryAll(".cell.open"): node.toggled("open", false)
  for row in 0 ..< view.model.rows: view.box.unstyled(cstring("--h" & $row))


proc observed(target: JsObject, handler: proc()): JsObject
    {.importjs:
  "(window.ResizeObserver ? (function(o) { o.observe(#); return o; " &
  "})(new ResizeObserver(#)) : null)".}
  ## jitro `handler` ca lo nu le ni ganra be `target` cu cenba
proc unobserved(observer: JsObject) {.importjs: "(function(o) { if (o) o.disconnect(); })(#)".}
  ## sisti lo nu jitro


proc viewed(host: JsObject, model: Model): View =
  ## pixra le se tcidu ne'i `host` gi'e jitro lo nu le prenu cu cuxna
  let
    (chains, kids) = model.chained
    view = View(box: columns(model, chains), model: model, chains: chains, kids: kids)
  host.replaced view.box
  view.box.listened("mouseover", proc(event: JsObject) =
    let node = event.chosenNode
    if node.isNull: return
    let key = some(node.toKey)
    if key != view.hovered:
      view.hovered = key
      view.highlighted(key))
  view.box.listened("mouseleave", proc(event: JsObject) =
    view.hovered = none(Key)
    view.highlighted(view.clicked))
  view.box.listened("click", proc(event: JsObject) =
    let node = event.chosenNode
    if node.isNull: return
    let key = some(node.toKey)
    view.clicked = if key == view.clicked: none(Key) else: key
    if not host.hasClass("no-bars"): view.named(view.clicked)
    view.highlighted(if view.hovered.isSome: view.hovered else: view.clicked))
  view.width = int(view.box.rect.width.to(float))
  view.observer = view.box.observed(proc() =
    let width = int(view.box.rect.width.to(float))
    if width != view.width:
      view.width = width
      view.reset)
  view



#[ ni'o ni'o ni'o le stuzi be lo nu ciska ]#

type
  Point = (JsObject, int)  ## pa stuzi pe le papri
  Edit = object  ## pa nu cenba le selci'a
    text: cstring
    a: int
    f: int

var
  EDITOR: JsObject  ## le stuzi be lo nu ciska
  CURRENT: Model  ## le se tcidu pe le selci'a poi ca zvati
  DRAWING: View  ## le pixra pe le se tcidu
  UNDO: seq[Edit]
  REDO: seq[Edit]
  LAST_TYPE: cstring = ""  ## le klesi be le romoi nu cenba
  LAST_AT = -1  ## le stuzi poi le romoi nu cenba cu fanmo bu'u ke'a
  LAST_TIME = 0.0
  IS_COMPOSING = false  ## lo nu basti cu ca'o fasnu
  COMPOSED: Option[(int, int)]  ## le cuxna ca lo nu le nu basti cu cfari
  GOAL_X = -1.0  ## le stuzi pe le korbi ca lo nu le cuxna cu muvdu gapru ja cnita
  ANSWERS = 0  ## lo klani be lo se tcidu poi le gunka cu dunda ke'a
  WORKER: JsObject  ## le gunka to `null` va'o lo nu le papri cu ponse no gunka toi
  IS_BUSY = false
  WANTED: cstring  ## le selci'a poi le papri cu cpedu lo nu tcidu ke'a
  IS_WANTED = false
  ASKED = 0
  TIMER = 0


proc hostsAll(): seq[JsObject] = EDITOR.queryAll("[data-s]")
  ## ro stuzi pe lo selci'a


proc size(host: JsObject): int =
  ## lo klani be lo lerfu pe pa stuzi
  if host.tagName.to(cstring) == "BR": 1 else: host.textContent.to(cstring).lengthUnits


proc opening(host: JsObject): int = host.attributeInt("data-s")
  ## le stuzi pe le pamoi lerfu pe pa stuzi


proc compared(node: JsObject, offset: int, host: JsObject): int {.importjs:
  "(function(n, o, h) { var r = document.createRange(); r.setStart(n, o); " &
  "return r.comparePoint(h, 0); })(#, #, #)".}
  ## jdice lo du'u `host` cu zvati ba pa stuzi pe le papri


proc toOffset*(node: JsObject, at: int): int =
  ## le stuzi pe le selci'a pe pa stuzi pe le papri
  let own = (if node.nodeType.to(int) == 3: node.parentElement else: node).closest("[data-s]")
  if not own.isNull and EDITOR.contains(own).to(bool):
    if node.nodeType.to(int) == 3: return own.opening + min(at, node.length.to(int))
    return if at == 0: own.opening else: own.opening + own.size
  for host in hostsAll():
    if compared(node, at, host) >= 0: return host.opening
  CURRENT.text.lengthUnits


proc textAt(host: JsObject, k: int): Point =
  ## pa stuzi pe le selci'a pe pa stuzi
  let text = host.firstChild
  if not text.isNull and text.nodeType.to(int) == 3: (text, min(k, text.length.to(int)))
  else: (host, 0)


proc childIndex(node: JsObject): int {.importjs:
  "(function(n) { return Array.prototype.indexOf.call(n.parentNode.childNodes, n); })(#)".}
  ## le stuna'u pe pa dacti ne'i le mamta


proc toPoint*(offset: int, is_early = false): Point =
  ## pa stuzi pe le papri poi le stuzi pe le selci'a cu sinxa ke'a
  ##   .i le cuxna cu stali le valsi poi ri ciska ke'a
  ##   .i va'o lo nu `is_early` cu jetnu kei le cuxna cu zvati le krasi be le bavla'i stuzi
  let hosts = hostsAll()
  var first: JsObject = nil
  for n, host in hosts:
    let s = host.opening
    if host.tagName.to(cstring) == "BR":
      if offset != s + 1: continue
      if n + 1 < hosts.len and hosts[n + 1].tagName.to(cstring) != "BR" and
          hosts[n + 1].opening == offset and hosts[n + 1].size > 0:
        return hosts[n + 1].textAt(0)
      return (host.parentNode, host.childIndex + 1)
    let length = host.size
    var is_next_start = false
    if is_early and offset == s + length:
      for later in hosts[n + 1 .. ^1]:
        if later.tagName.to(cstring) != "BR" and later.opening == offset: is_next_start = true
    if s < offset and offset <= s + length and not is_next_start: return host.textAt(offset - s)
    if s == offset and first.isNil: first = host
  if not first.isNil: return first.textAt(0)
  let flow = EDITOR.query(".flow")
  ((if flow.isNull: EDITOR else: flow), 0)


proc selectionOffsets*(): Option[(int, int, bool)] =
  ## le stuzi pe le selci'a pe le cuxna ge'u .e lo du'u le cuxna cu zvati le krasi be pa stuzi
  let sel = selection()
  if sel.rangeCount.to(int) == 0 or not EDITOR.contains(sel.anchorNode).to(bool) or
      not EDITOR.contains(sel.focusNode).to(bool): return none((int, int, bool))
  let
    a = toOffset(sel.anchorNode, sel.anchorOffset.to(int))
    f = toOffset(sel.focusNode, sel.focusOffset.to(int))
  some((a, f, sel.focusNode.nodeType.to(int) == 3 and sel.focusOffset.to(int) == 0))


proc selected*(a, f: int, is_early = false) =
  ## punji le cuxna fi lo stuzi pe le selci'a
  let
    (an, ao) = toPoint(a, is_early and a == f)
    (fn, fo) = if a == f: (an, ao) else: toPoint(f, is_early)
  selection().setBaseAndExtent(an, ao, fn, fo)



#[ ni'o ni'o ni'o lo nu muvdu le cuxna ]#

type Place = object  ## pa stuzi pe le cuxna
  offset: int
  node: JsObject
  at: int
  is_break: bool


proc places(): seq[Place] =
  ## ro stuzi poi le cuxna ka'e zvati ke'a ta'i le porsi
  ##   .i le krasi be lo bavla'i linji be lo selci'a cu du le stuzi poi lidne lo linji fanmo
  var all: seq[Place]
  for host in hostsAll():
    let s = host.opening
    if host.tagName.to(cstring) == "BR":
      all.add Place(offset: s + 1, node: host.parentNode, at: host.childIndex + 1, is_break: true)
      continue
    let text = host.firstChild
    if text.isNull or text.nodeType.to(int) != 3:
      all.add Place(offset: s, node: host, at: 0)
      continue
    for k in 0 .. text.length.to(int): all.add Place(offset: s + k, node: text, at: k)
  for n, place in all:
    if place.is_break and n + 1 < all.len and all[n + 1].offset == place.offset and
        not all[n + 1].is_break: continue
    result.add place
  if result.len == 0:
    let flow = EDITOR.query(".flow")
    result.add Place(offset: 0, node: if flow.isNull: EDITOR else: flow, at: 0)


proc rectAt(node: JsObject, at: int): JsObject {.importjs:
  "(function(n, a) { var r = document.createRange(); r.setStart(n, a); r.collapse(true); " &
  "var b = r.getClientRects()[0]; if (b && b.height) return b; " &
  "var e = n.nodeType === 3 ? n.parentElement : (n.childNodes[a] || n.childNodes[a - 1] || n); " &
  "return e.nodeType === 1 ? e.getBoundingClientRect() : r.getBoundingClientRect(); " &
  "})(#, #)".}
  ## le kurfa be pa stuzi pe le papri


func before(text: cstring, at: int): int =
  ## le stuzi pe le lerfu poi lidne `at`
  let unit = text.unitAt(at - 1)
  max(0, at - (if at > 1 and unit >= 0xDC00 and unit <= 0xDFFF: 2 else: 1))


func after(text: cstring, at: int): int =
  ## le stuzi pe le lerfu poi selkra `at`
  let unit = text.unitAt(at + 1)
  min(text.lengthUnits, at + (if unit >= 0xDC00 and unit <= 0xDFFF: 2 else: 1))


func wordBack(text: cstring, at: int): int =
  ## le krasi be le valsi poi lidne `at`
  result = at
  while result > 0 and text.isSpace(result - 1): dec result
  while result > 0 and not text.isSpace(result - 1): dec result


func wordOn(text: cstring, at: int): int =
  ## le fanmo be le valsi poi selkra `at`
  result = at
  while result < text.lengthUnits and text.isSpace(result): inc result
  while result < text.lengthUnits and not text.isSpace(result): inc result


proc moved(event: JsObject): bool =
  ## muvdu le cuxna ja'i pa batke po'u `Arrow` .a `Home` .a `End`
  ##   .i le cuxna cu muvdu pa lerfu .a pa valsi .a pa linji .a le fanmo be pa linji
  let sel = selection()
  if sel.rangeCount.to(int) == 0 or not EDITOR.contains(sel.focusNode).to(bool): return false
  let chosen = selectionOffsets()
  if chosen.isNone: return false
  let
    (a, f, _) = chosen.get
    (low, high) = (min(a, f), max(a, f))
    text = CURRENT.text
    is_extending = event.shiftKey.to(bool)
    is_word = event.ctrlKey.to(bool) or event.altKey.to(bool)
    all = places()
  proc first(offset: int): Place =
    for place in all:
      if place.offset == offset: return place
    all[^1]
  proc last(offset: int): Place =
    for k in countdown(all.high, 0):
      if all[k].offset == offset: return all[k]
    all[0]
  proc rows(): (seq[(float, seq[(Place, float)])], int, float) =
    var items: seq[(Place, float, float)]
    for place in all:
      let r = rectAt(place.node, place.at)
      items.add (place, r.top.to(float), r.left.to(float))
    for a in 0 ..< items.len:
      for b in a + 1 ..< items.len:
        if items[b][1] < items[a][1]: swap(items[a], items[b])
    var lines: seq[(float, seq[(Place, float)])]
    for (place, top, left) in items:
      if lines.len > 0 and top - lines[^1][0] < 6: lines[^1][1].add (place, left)
      else: lines.add (top, @[(place, left)])
    let here = rectAt(sel.focusNode, sel.focusOffset.to(int))
    var (k, best) = (0, Inf)
    for n, line in lines:
      let d = abs(line[0] - here.top.to(float))
      if d < best: (k, best) = (n, d)
    (lines, k, here.left.to(float))
  var
    goal: Place
    is_vertical = false
  let name = event.key.to(cstring)
  if name == "ArrowRight":
    goal = if not is_extending and low != high: first(high)
      elif f >= text.lengthUnits: first(f)
      else: first(if is_word: text.wordOn(f) else: text.after(f))
  elif name == "ArrowLeft":
    goal = if not is_extending and low != high: last(low)
      elif f <= 0: last(0)
      else: last(if is_word: text.wordBack(f) else: text.before(f))
  elif name == "Home" or name == "End":
    if is_word: goal = if name == "Home": last(0) else: first(text.lengthUnits)
    else:
      let (lines, k, _) = rows()
      goal = lines[k][1][0][0]
      for (place, _) in lines[k][1]:
        if (name == "Home" and place.offset < goal.offset) or
            (name == "End" and place.offset > goal.offset): goal = place
  elif name == "ArrowUp" or name == "ArrowDown":
    is_vertical = true
    let (lines, k, x) = rows()
    if GOAL_X < 0: GOAL_X = x
    let n = k + (if name == "ArrowUp": -1 else: 1)
    if n < 0: goal = last(0)
    elif n >= lines.len: goal = first(text.lengthUnits)
    else:
      var best = Inf
      for (place, left) in lines[n][1]:
        if abs(left - GOAL_X) < best: (goal, best) = (place, abs(left - GOAL_X))
  else: return false
  if not is_vertical: GOAL_X = -1
  if is_extending: sel.setBaseAndExtent(sel.anchorNode, sel.anchorOffset, goal.node, goal.at)
  else: sel.setBaseAndExtent(goal.node, goal.at, goal.node, goal.at)
  true



#[ ni'o ni'o ni'o lo nu cenba le selci'a ]#

func diff*(source, goal: cstring): (int, int, cstring) =
  ## le traji cmalu nu cenba poi galfi `source` `goal`
  let n = min(source.lengthUnits, goal.lengthUnits)
  var low = 0
  while low < n and source.unitAt(low) == goal.unitAt(low): inc low
  var k = 0
  while k < n - low and source.unitAt(source.lengthUnits - 1 - k) ==
      goal.unitAt(goal.lengthUnits - 1 - k): inc k
  (low, source.lengthUnits - k, goal.slice(low, goal.lengthUnits - k))


func shifted*(model: Model, low, high: int, inserted: cstring, text: cstring): Model =
  ## le se tcidu poi muvdu ja'i pa nu cenba
  ##   .i lo valsi poi lidne le nu cenba cu stali
  ##   .i lo valsi poi selkra le nu cenba cu muvdu
  ##   .i pa valsi poi le nu cenba cu pencu le fanmo .a le krasi be ke'a cu banro
  ##   .i no valsi cu cfari ne'i lo valsi poi lidne ke'a
  ##   .i pa linji cu stali ro valsi poi stali
  let d = inserted.lengthUnits - (high - low)
  var is_solid = inserted.lengthUnits > 0
  for k in 0 ..< inserted.lengthUnits:
    if inserted.isSpace(k): is_solid = false
  result = Model(text: text, rows: model.rows, nodes: model.nodes, sentences: model.sentences,
      stop: (if model.stop < 0: -1 elif model.stop >= high: model.stop + d
        else: min(model.stop, low)),
      is_moved: true)
  var
    index = newSeq[int](model.words.len)
    after = 0
  for i, word in model.words:
    var
      s = if word.s >= high: word.s + d elif word.s < low: word.s else: low
      e = if word.e <= low: word.e elif word.e >= high: word.e + d else: low
    if is_solid and word.e == low: e = low + inserted.lengthUnits
    elif is_solid and word.s == high and not (i > 0 and model.words[i - 1].e == low): s = low
    s = max(s, after)
    if e <= s:
      index[i] = -1
      continue
    after = e
    index[i] = result.words.len
    result.words.add Word(s: s, e: e, group: word.group, gloss: word.gloss,
        text: text.slice(s, e))
  var kept = newSeq[int](model.bars.len)
  for k, bar in model.bars:
    kept[k] = -1
    var (first, last) = (-1, -1)
    for word in bar.first .. min(bar.last, model.words.high):
      if index[word] >= 0:
        if first < 0: first = index[word]
        last = index[word]
    if first < 0: continue
    var parent = bar.parent
    while parent >= 0 and kept[parent] < 0: parent = model.bars[parent].parent
    var moved = bar
    moved.first = first
    moved.last = last
    moved.parent = if parent >= 0: kept[parent] else: -1
    kept[k] = result.bars.len
    result.bars.add moved


proc status(model: Model) =
  ## ciska le linji poi cusku le se tcidu
  let shown = byId("status")
  var refused = 0
  for word in model.words:
    if Group(word.group) == Group.Refused: inc refused
  var line = $model.words.len & " valsi · " & $model.sentences & " bridi · " & $model.nodes &
      " jgena · " & $model.bars.len & " linji"
  if refused > 0: line = $refused & " valsi cu srera · " & line
  if model.stop >= 0:
    line = "le gerna cu sisti bu'u le " & $(model.stop + 1) & "moi lerfu · " & line
  shown.textContent = cstring(line)
  shown.toggled("bad", model.stop >= 0 or refused > 0)


proc drawn*(model: Model, keep: Option[(int, int, bool)]) =
  ## pixra le se tcidu gi'e punji le cuxna fi le stuzi poi pu zvati
  if IS_COMPOSING: return
  CURRENT = model
  if not DRAWING.isNil:
    unframed(DRAWING.raf)
    DRAWING.observer.unobserved
  DRAWING = EDITOR.viewed(model)
  EDITOR.toggled("empty", model.text.lengthUnits == 0)
  if not model.is_moved: model.status
  for button in DOCUMENT_PAGE.queryAll("[data-sample]"):
    button.attribute("aria-pressed", if button.attributeOf("data-sample") == model.text:
        cstring("true") else: cstring("false"))
  if keep.isSome and DOCUMENT_PAGE.activeElement == EDITOR:
    let (a, f, is_early) = keep.get
    selected(a, f, is_early)


proc asked(text: cstring)


proc changed(text: cstring, a: int, f = -1) =
  ## cenba le selci'a gi'e pixra lo se tcidu poi muvdu gi'e cpedu lo nu tcidu
  let (low, high, inserted) = diff(CURRENT.text, text)
  drawn(CURRENT.shifted(low, high, inserted, text), some((a, if f < 0: a else: f, false)))
  asked(text)


proc edited(low, high: int, inserted: cstring, kind: cstring, was: Option[(int, int, bool)]) =
  ## basti le pagbu be le selci'a `inserted`
  ##   .i lo lerfu poi se ciska ba lo lerfu cu se xruti kansa
  let
    old = CURRENT.text
    time = now()
  if low == high and inserted.lengthUnits == 0:
    drawn(CURRENT, some((low, low, false)))
    return
  var is_space = false
  for k in 0 ..< inserted.lengthUnits:
    if inserted.isSpace(k): is_space = true
  let is_joined = kind == "insertText" and LAST_TYPE == kind and LAST_AT == low and low == high and
      time - LAST_TIME < 1000 and not is_space
  if not is_joined:
    UNDO.add Edit(text: old, a: if was.isSome: was.get[0] else: low,
        f: if was.isSome: was.get[1] else: high)
  if UNDO.len > 200: UNDO.delete(0)
  REDO.setLen 0
  (LAST_TYPE, LAST_AT, LAST_TIME) = (kind, low + inserted.lengthUnits, time)
  changed(old.slice(0, low).join(inserted).join(old.slice(high, old.lengthUnits)),
      low + inserted.lengthUnits)


proc history(source: var seq[Edit], goal: var seq[Edit]) =
  ## xruti pa nu cenba gi'a rapli pa nu cenba
  if source.len == 0: return
  let
    edit = source.pop
    chosen = selectionOffsets()
    (a, f) = if chosen.isSome: (chosen.get[0], chosen.get[1])
      else: (CURRENT.text.lengthUnits, CURRENT.text.lengthUnits)
  goal.add Edit(text: CURRENT.text, a: a, f: f)
  (LAST_TYPE, LAST_AT, LAST_TIME) = (cstring(""), -1, 0.0)
  changed(edit.text, edit.a, edit.f)


proc toTarget(event: JsObject): Option[(int, int)] =
  ## le stuzi pe le selci'a poi le nu fasnu cu cmene ke'a
  let ranges = event.getTargetRanges().to(seq[JsObject])
  if ranges.len == 0 or not EDITOR.contains(ranges[0].startContainer).to(bool):
    return none((int, int))
  let
    a = toOffset(ranges[0].startContainer, ranges[0].startOffset.to(int))
    b = toOffset(ranges[0].endContainer, ranges[0].endOffset.to(int))
  some((min(a, b), max(a, b)))


proc readBack(): (cstring, int) =
  ## le selci'a poi le stuzi cu ca jarco ke'a ku'o .e le stuzi pe le cuxna ne'i ri
  ##   .i lo samtci pe lo jbobatke cu ka'e ciska bu'u le papri ca lo nu basti
  let
    sel = selection()
    focus = if sel.rangeCount.to(int) > 0: sel.focusNode else: nil
    at = sel.focusOffset.to(int)
  var
    text = ""
    caret = -1
  proc walk(node: JsObject) =
    if node.nodeType.to(int) == 3:
      if node == focus: caret = cstring(text).lengthUnits + min(at, node.length.to(int))
      text.add $node.data.to(cstring)
      return
    if node.nodeType.to(int) != 1 or node.hasClass("ann"): return
    if node.tagName.to(cstring) == "BR":
      if not node.hasClass("ph"): text.add "\n"
      return
    let kids = node.childNodes.to(seq[JsObject])
    for k, kid in kids:
      if node == focus and k == at: caret = cstring(text).lengthUnits
      walk(kid)
    if node == focus and at >= kids.len: caret = cstring(text).lengthUnits
  walk(EDITOR)
  let read = cstring(text)
  (read, if caret < 0: read.lengthUnits else: caret)


proc adopted(was: Option[(int, int, bool)]) =
  ## punji le selci'a poi le stuzi cu jarco ke'a
  let (text, caret) = readBack()
  if text == CURRENT.text:
    drawn(CURRENT, some((caret, caret, false)))
    return
  UNDO.add Edit(text: CURRENT.text, a: if was.isSome: was.get[0] else: caret,
      f: if was.isSome: was.get[1] else: caret)
  REDO.setLen 0
  (LAST_TYPE, LAST_AT, LAST_TIME) = (cstring(""), -1, 0.0)
  changed(text, caret)



#[ ni'o ni'o ni'o lo nu tcidu ne'i le gunka ]#

proc took(model: Model) =
  ## pixra lo se tcidu pe pa selci'a
  ##   .i pa se tcidu pe pa pu selci'a cu muvdu ja'i ro nu cenba poi ba fasnu
  if IS_COMPOSING: return
  var shown = model
  if model.text != CURRENT.text:
    let (low, high, inserted) = diff(model.text, CURRENT.text)
    shown = model.shifted(low, high, inserted, CURRENT.text)
    shown.is_moved = false
  drawn(shown, selectionOffsets())


proc sent() =
  ## dunda le selci'a poi cpedu lo nu tcidu le gunka
  IS_BUSY = true
  IS_WANTED = false
  inc ASKED
  let ask = emptyObject()
  ask.id = ASKED
  ask.text = WANTED
  WORKER.postMessage(ask)


proc asked(text: cstring) =
  ## cpedu lo nu tcidu le selci'a ne'i le gunka
  ##   .i va'o lo nu le papri cu ponse no gunka kei le papri cu tcidu ba lo nu le nu ciska cu denpa
  WANTED = text
  IS_WANTED = true
  if not WORKER.isNil:
    if not IS_BUSY: sent()
    return
  unlater(TIMER)
  TIMER = later(proc() =
    if not IS_WANTED: return
    IS_WANTED = false
    took(WANTED.toModel), PAUSE)


proc spawnedWorker(script: cstring, name: cstring): JsObject {.importjs:
  "(function(s, n) { try { return new Worker(URL.createObjectURL(new Blob([s], { " &
  "type: 'text/javascript' })), { name: n }); } catch (e) { return null; } })(#, #)".}
  ## zbasu pa gunka fi le samtci to `null` va'o lo nu le papri cu to'e curmi toi


proc started*(script: cstring) =
  ## zbasu le gunka
  ##   .i le gunka cu jarco le se tcidu pe ro selci'a poi le papri cu cpedu
  let worker = spawnedWorker(script, NAME_WORKER)
  if worker.isNull: return
  worker.onmessage = proc(event: JsObject) =
    if event.data.isNull or event.data.id.isUndefined: return
    inc ANSWERS
    IS_BUSY = false
    if IS_WANTED: sent()
    took(event.data.model.to(Model))
  worker.onerror = proc(event: JsObject) =
    worker.terminate()
    if WORKER == worker:
      WORKER = nil
      IS_BUSY = false
      asked(CURRENT.text)
  WORKER = worker
  if IS_WANTED: sent()



#[ ni'o ni'o ni'o lo nu jitro le stuzi ]#

proc settled() =
  ## muvdu le cuxna poi pa nu samcu'a cu punji ke'a lo bartu be le selci'a le stuzi be ri
  let sel = selection()
  if IS_COMPOSING or sel.rangeCount.to(int) == 0 or not sel.isCollapsed.to(bool) or
      not EDITOR.contains(sel.focusNode).to(bool): return
  let node = sel.focusNode
  if node.nodeType.to(int) == 3 and not node.parentElement.closest("[data-s]").isNull: return
  let (pn, po) = toPoint(toOffset(node, sel.focusOffset.to(int)))
  if pn != node or po != sel.focusOffset.to(int): sel.setBaseAndExtent(pn, po, pn, po)


proc wiredEditor() =
  ## jitro ro nu cenba poi le prenu cu rinka ke'a
  EDITOR.listened("beforeinput", proc(event: JsObject) =
    let kind = event.inputType.to(cstring)
    if kind == "insertCompositionText" or (event.isComposing.to(bool) and
        kind != "insertFromComposition"): return
    event.prevented
    if kind == "historyUndo": UNDO.history(REDO); return
    if kind == "historyRedo": REDO.history(UNDO); return
    if kind == "insertFromComposition" or kind == "deleteCompositionText": return
    let chosen = selectionOffsets()
    if chosen.isNone: return
    let text = CURRENT.text
    var
      (low, high) = (min(chosen.get[0], chosen.get[1]), max(chosen.get[0], chosen.get[1]))
      inserted: cstring = ""
    if kind == "insertText":
      inserted = (if event.data.isNull: cstring("") else: event.data.to(cstring))
    elif kind in [cstring("insertReplacementText"), "insertFromDrop", "insertFromPaste",
        "insertFromYank"]:
      inserted = event.plain
      if kind != "insertFromPaste":
        let target = event.toTarget
        if target.isSome: (low, high) = target.get
    elif kind == "insertParagraph" or kind == "insertLineBreak": inserted = "\n"
    elif kind in [cstring("deleteContentBackward"), "deleteContentForward", "deleteWordBackward",
        "deleteWordForward"]:
      # pa jbobatke poi vimcu pa pagbu be le selci'a cu cmene le pagbu ne'i le nu fasnu
      let target = if low == high: event.toTarget else: none((int, int))
      if target.isSome and target.get[1] > target.get[0]: (low, high) = target.get
      elif low == high:
        if kind == "deleteContentBackward": low = text.before(low)
        elif kind == "deleteContentForward": high = text.after(high)
        elif kind == "deleteWordBackward": low = text.wordBack(low)
        else: high = text.wordOn(high)
    elif kind in [cstring("deleteSoftLineBackward"), "deleteHardLineBackward"]:
      if low == high:
        var s = low
        while s > 0 and text.slice(s - 1, s) != "\n": dec s
        low = if s == low: text.before(low) else: s
    elif kind in [cstring("deleteSoftLineForward"), "deleteHardLineForward"]:
      if low == high:
        var e = high
        while e < text.lengthUnits and text.slice(e, e + 1) != "\n": inc e
        high = if e == high: min(text.lengthUnits, high + 1) else: e
    elif kind notin [cstring("deleteByCut"), "deleteByDrag", "deleteContent"]: return
    edited(low, high, inserted.lineEnds, kind, chosen))
  EDITOR.listened("keydown", proc(event: JsObject) =
    let name = event.key.to(cstring)
    if not event.metaKey.to(bool) and name in [cstring("ArrowLeft"), "ArrowRight", "ArrowUp",
        "ArrowDown", "Home", "End"]:
      if moved(event): event.prevented
      return
    if not (event.ctrlKey.to(bool) or event.metaKey.to(bool)) or event.altKey.to(bool): return
    if name == "z" or name == "Z":
      event.prevented
      if event.shiftKey.to(bool): REDO.history(UNDO) else: UNDO.history(REDO)
    elif name == "y" or name == "Y":
      event.prevented
      REDO.history(UNDO))
  # le cfika cu cpacu le selci'a po'o
  proc copied(event: JsObject): Option[(int, int, bool)] =
    let chosen = selectionOffsets()
    if chosen.isNone or chosen.get[0] == chosen.get[1]: return none((int, int, bool))
    let (low, high) = (min(chosen.get[0], chosen.get[1]), max(chosen.get[0], chosen.get[1]))
    event.clipboardData.setData("text/plain", CURRENT.text.slice(low, high))
    event.prevented
    chosen
  EDITOR.listened("copy", proc(event: JsObject) = discard event.copied)
  EDITOR.listened("cut", proc(event: JsObject) =
    let chosen = event.copied
    if chosen.isSome:
      let (low, high) = (min(chosen.get[0], chosen.get[1]), max(chosen.get[0], chosen.get[1]))
      edited(low, high, "", "deleteByCut", chosen))
  EDITOR.listened("dragstart", proc(event: JsObject) = event.prevented)
  EDITOR.listened("compositionstart", proc(event: JsObject) =
    IS_COMPOSING = true
    let chosen = selectionOffsets()
    COMPOSED = (if chosen.isSome: some((chosen.get[0], chosen.get[1])) else: none((int, int))))
  EDITOR.listened("compositionend", proc(event: JsObject) =
    IS_COMPOSING = false
    let was = COMPOSED
    COMPOSED = none((int, int))
    adopted(if was.isSome: some((was.get[0], was.get[1], false)) else: none((int, int, bool))))
  EDITOR.listened("input", proc(event: JsObject) =
    if IS_COMPOSING or event.isComposing.to(bool): return
    if readBack()[0] != CURRENT.text: adopted(none((int, int, bool))))
  DOCUMENT_PAGE.listened("selectionchange", proc(event: JsObject) =
    if not IS_COMPOSING: settled())
  DOCUMENT_PAGE.listened("click", proc(event: JsObject) =
    if not DRAWING.isNil and not DRAWING.box.contains(event.target).to(bool): DRAWING.closed)
  DOCUMENT_PAGE.listened("keydown", proc(event: JsObject) =
    if event.key.to(cstring) == "Escape" and not DRAWING.isNil: DRAWING.closed)


proc wiredControls() =
  ## jitro lo mupli .e le re batke po'u `Show`
  let chips = byId("samples")
  for (name, text) in SAMPLES:
    let button = spanned("button", "chip-btn", cstring(name))
    button.attribute("type", "button")
    button.attribute("data-sample", cstring(text))
    chips.append button
  # ro fancu poi selzba ne'i pa nu rapli cu ralte pa cmima po'o to `capture` toi
  for button in DOCUMENT_PAGE.queryAll("[data-sample]"):
    let sample = button.attributeOf("data-sample")
    capture sample:
      button.listened("click", proc(event: JsObject) =
        if sample == CURRENT.text: return
        UNDO.add Edit(text: CURRENT.text, a: 0, f: 0)
        REDO.setLen 0
        IS_WANTED = false
        drawn(sample.toModel, none((int, int, bool))))
  for (id, class_name) in [(cstring("show-gloss"), cstring("no-gloss")),
      (cstring("show-bars"), cstring("no-bars"))]:
    let toggle = byId(id)
    capture class_name:
      toggle.listened("change", proc(event: JsObject) =
        EDITOR.toggled(class_name, not event.target.checked.to(bool))
        drawn(CURRENT, selectionOffsets()))


proc measured() {.importjs:
  "(function(e) { var p = document.createElement('span'); " &
  "p.style.cssText = 'position: absolute; visibility: hidden; white-space: pre; " &
  "font: 10.5px/13px var(--mono); letter-spacing: .02em'; " &
  "p.textContent = 'MMMMMMMMMMMMMMMMMMMM'; document.body.append(p); " &
  "e.style.setProperty('--gl-ch', p.getBoundingClientRect().width / 20 + 'px'); " &
  "p.remove(); })(document.getElementById('editor'))".}
  ## mapti le ni ganra be pa lerfu pe le cmene be lo selma'o


proc scriptText*(): cstring {.importjs:
  "(document.currentScript ? document.currentScript.text : '')".}
  ## le selci'a pe le samtci poi gunka


proc current*(): Model = CURRENT
  ## le se tcidu poi le papri cu ca pixra ke'a


proc answersTaken*(): int = ANSWERS
  ## lo klani be lo se tcidu poi le gunka cu dunda ke'a


proc isWorking*(): bool = not WORKER.isNil
  ## jdice lo du'u pa gunka cu tcidu le selci'a


proc isAsking*(): bool = IS_BUSY or IS_WANTED
  ## jdice lo du'u le papri cu denpa pa se tcidu


proc wiredPage*() =
  ## jitro le stuzi be lo nu ciska .e lo mupli .e le re batke gi'e pixra le pamoi mupli
  EDITOR = byId("editor")
  wiredEditor()
  wiredControls()
  measured()
  DOCUMENT_PAGE.fonts.ready.then(proc() = measured())
  drawn(cstring(SAMPLES[0][1]).toModel, none((int, int, bool)))


proc wired() =
  ## jitro le papri gi'e zbasu le gunka
  let script = scriptText()
  wiredPage()
  started(script)


if isWorkerLayers(): SELF.onmessage = answered
elif not DOCUMENT_PAGE.isNull and not defined(testing): wired()
