## jitro le papri pe lo jmive se ciska to `pages/live.html` toi ne'i `JavaScript`
##   .i le stuzi be lo nu ciska cu dunda lo mivyselci'a lo tcidu pe `parseLojbanLive`
##   .i le tcidu cu tcidu ne'i pa gunka va'o lo nu le papri cu dunda pa gunka
##   .i le papri cu galfi lo selci'a be fi `NIF` be'o poi le papri cu ralte ke'a sepi'o ro cenba
##   .i ba bo le papri cu pixra le ca selci'a be fi `NIF` to `draw.nim` toi
##
##   |--------------|----------------------------------------------------------------------------|
##   | lo fancu     | lo smuni                                                                   |
##   |--------------|----------------------------------------------------------------------------|
##   | `typed`      | benji le ninpau le mitytcidu                                          |
##   |              | .i va'o lo drata pa ninytcidu cu tcidu                                     |
##   | `readWhole`  | tcidu le selci'a sepi'o pa ninytcidu gi'e sisti le tcidu ta'i lo mupli  |
##   | `streamed`   | pa ninytcidu cu tcidu le selci'a                                        |
##   |              | .i ro pagbu cu valsi                                                       |
##   |              | .i sisti le tcidu                                                          |
##   | `mergeShown` | le linji .e lo pixra be ro ve jmina be lo mulno pagbu                      |
##   |              | .i lo srera cu stali                                                       |
##   |--------------|----------------------------------------------------------------------------|
##
## ni'o le samtci cu du le mulno genturfa'i ta'i lo nu le cripu cu jarco le genturfa'i
##   .i se ki'u bo lo nu tcidu cu fasnu ne'i lo gunka poi selkra le selci'a pe le samtci
##   .i ne'i le gunka no papri cu zasti
##   .i no pagbu be le papri cu seltro
##
## ni'o le papri cu ralte le ca selci'a be fi `NIF` ta'i pa lerpoi pe `JavaScript`
##   .i le papri cu katna le selci'a bu'u `at` pe le cenba gi'e jmina `text`
##   .i ba bo le papri cu pixra `tail` ta'i lo pagbu poi ca'o kalri
##   .i lo bavla'i cenba cu basti `tail` to `D1 c` pe `#859` toi
##
## ni'o lo selci'a poi zenba bu'u lo fanmo be ke'a po'o cu selbe'i fi le mitytcidu ta'i lo nu lo
##     mivyselci'a cu klama
##   .i va'o ro drata nu galfi kei pa ninytcidu cu tcidu le mulselci'a
##   .i ro mupli .e ro porsi be lo valsi .e le pamoi se ciska cu sisti lo tcidu pe vo'a
##   .i se ki'u bo ro pagbu pe ro le selci'a cu ganlo
##   .i lo selci'a poi lo prenu cu ciska ke'a cu ca'o kalri ta'i lo mivyselci'a
##
## ni'o ro cenba cu se kansa lo namcu pe le tcidu poi dunda le cenba
##   .i lo cenba pe lo tcidu poi le papri cu ba'o vimcu ke'a rinka no nu pixra
##
## ni'o lo nu pixra cu denpa lo bavla'i nu jarco
##   .i se ki'u bo su'o re cenba pe pa nu jarco cu selxra pa roi
##   .i ro cenba pe pa nu jarco cu denpa le pa nu pixra
##
## ni'o `typed` .e `readWhole` .e `streamed` jarco pa nupre poi mulno ca lo nu lo romoi cenba pe le
##     fancu cu selxra
##   .i lo cipra pe le papri cu denpa le nupre to `tests/browser/suite_page.nim` toi
##   .i se ki'u bo no xusra cu denpa lo temci
##
## ni'o lo nu zbasu cu punji lo jbexra be le pamoi se ciska le papri to lo minde po'u `page` toi
##   .i se ki'u bo le papri cu mulseltcidu pu lo nu le samtci cu cfari
##
## ni'o lo denpa poi zvati lo jbini be lo valsi pe pa porsi be lo valsi cu du pa junla pe le papri
##   .i lo cipra pe le papri cu benji lo porsi be lo valsi ta'i no denpa
##
## ni'o lo nu jmina cu jmina ro pagbu be le ca selci'a be fi `NIF` fo pa tricu pe lo nu tcidu le
##     mulselci'a .a ro tricu pe ro porsi be lo pagbu poi sruri pa srera poi stali to `drawnMerged`
##     pe `draw.nim` toi
##   .i le rebla cu na se jmina
##   .i le papri cu pixra ro tricu poi cnita le pagbu
##
## ni'o lo nu jmina cu fasnu ne'i lo cilta pe le papri
##   .i ki'u bo lo nu jmina cu tcidu lo selci'a be fi `NIF` be'o poi le papri cu ralte ke'a
##   .i ro cenba cu mipri lo tricu poi se jmina zi'e noi ca na drani
##
## ni'o lo cipra pe le papri cu jitro lo trotci ta'i le papri to `wiredControls` toi gi'e danre le
##     trotci
##   .i se ki'u bo le cipra cu cipra lo selgau be lo batke pe le papri

{.experimental: "strictFuncs".}

import std/[asyncjs, dom, jsffi]

import ../javascript/[bridge, live_text]
import ../ricysoho/nif
import ./draw


const  # lo stodi pe le papri
  LENGTH_MOST* = 2000
    ## lo du'u le stuzi be lo nu ciska cu vasru su'e xo kau lerfu
    ##   .i le namcu cu mintu `maxlength` pe le stuzi to `pages/live.html` toi
  PAUSE_STREAM = 140
    ## lo temci poi selmre fo `ms` gi'e jbini lo valsi pe lo porsi be lo valsi


type StatePage = object  ## lo selra'e be le papri be'o pe le mivyseltcidu be le papri
  reader: JsObject  ## lo tcidu be lo jmive se ciska to `nil` pu le pamoi se ciska toi
  generation: int
    ## lo du'u le papri cu cfagau xo kau tcidu
    ##   .i lo cenba pe lo pu tcidu cu rinka no nu pixra
  sent: cstring  ## lo selci'a poi le papri ba'o dunda ke'a le tcidu
  is_ended: bool
    ## le tcidu cu ba'o cpacu lo fanmo pe vo'a
    ##   .i se ki'u bo le tcidu cu cpacu no datpau
  nif: cstring  ## le ca selci'a be fi `NIF` be'o noi selkra lo minde
  tail: cstring  ## lo selci'a be fi `NIF` be'o pe ro pagbu poi ca'o kalri
  at_last: int
    ## lo stuzi be le romoi cenba ne'i `NIF`
    ##   .i lo pagbu pe `UTF-16` se kancu
  is_waiting: bool  ## lo nu pixra cu denpa lo bavla'i nu jarco


var  # lo selra'e pe le papri
  STATE = StatePage(nif: cstring(HEADER), tail: "")  ## lo selra'e be le papri
  DRAWING: Future[void]
    ## lo nu pixra poi denpa lo bavla'i nu jarco
    ##   .i ro cenba pe le nu jarco cu denpa le nu pixra


let DOCUMENT_PAGE {.nodecl, importc: "(typeof document === 'undefined' ? null : document)".}:
    JsObject
  ## `document` pe le papri
  ##   .i `null` ne'i lo gunka noi no papri cu seltro bu'u ke'a


proc pushLive(reader: JsObject, piece: cstring): Future[JsObject] {.importjs: "#.push(#)".}
  ## dunda pa pagbu lo tcidu be lo mivyselci'a
  ##   .i korbi `JS` sepi'o lo fancu pe le tcidu
proc finishLive(reader: JsObject): Future[JsObject] {.importjs: "#.finish()".}
  ## sisti lo mivyselci'a pe le tcidu
  ##   .i korbi `JS` sepi'o lo fancu pe le tcidu
proc isWorkerLive(reader: JsObject): bool {.importjs: "#.isWorker()".}
  ## jdice lo du'u le tcidu cu tcidu ne'i pa gunka
  ##   .i korbi `JS` sepi'o lo fancu pe le tcidu
proc cut(text: cstring, at: int): cstring {.importjs: "#.slice(0, #)".}
  ## dunda lo selci'a poi lidne `at` noi pagbu pe `UTF-16`
  ##   .i korbi `JS` sepi'o `slice` pe lo lerpoi
proc after(text: cstring, at: int): cstring {.importjs: "#.slice(#)".}
  ## dunda lo selci'a poi selkra `at` noi pagbu pe `UTF-16`
  ##   .i korbi `JS` sepi'o `slice` pe lo lerpoi
proc isOpening(text, opening: cstring): bool {.importjs: "#.startsWith(#)".}
  ## jdice lo du'u le selci'a cu selkra `opening`
  ##   .i korbi `JS` sepi'o `startsWith` pe lo lerpoi
proc lengthUnits(text: cstring): int {.importjs: "#.length".}
  ## kancu lo pagbu pe `UTF-16` ne'i le selci'a
  ##   .i korbi `JS` sepi'o `length` pe lo lerpoi
proc pieces(text: cstring): seq[cstring] {.importjs: "(#.match(/\\s*\\S+/g) || [])".}
  ## fendi le selci'a lo valsi
  ##   .i lo calyle'u cu lidne ro valsi
  ##   .i korbi `JS` sepi'o pa `regex`
proc nextFrame(): Future[void] {.importjs:
  "new Promise(function(resolve) { requestAnimationFrame(function() { resolve(); }); })".}
  ## dunda pa nupre be le bavla'i nu jarco be le papri
  ##   .i korbi `JS` sepi'o `requestAnimationFrame`
proc paused(milliseconds: int): Future[void] {.importjs:
  "new Promise(function(resolve) { setTimeout(resolve, #); })".}
  ## dunda pa nupre be lo junla pe le papri
  ##   .i lo porsi be lo valsi po'o cu denpa le nupre
  ##   .i korbi `JS`



#[ ni'o ni'o ni'o lo nu pixra ]#

proc mergeHidden() =
  ## mipri lo tricu poi se jmina
  ##   .i ki'u bo lo cenba cu rinka lo nu le tricu cu na drani
  document.getElementById("merged").setAttribute("hidden", "")


proc mergeShown() =
  ## jmina ro pagbu poi le ca selci'a be fi `NIF` cu vasru ke'a
  ##   .i le rebla cu na se jmina
  ##   .i ciska lo pixra be ro tricu poi le nu jmina cu jarco ke'a ku'o bu'u lo cnita be le pagbu
  ##   .i va'o lo nu le selci'a be fi `NIF` na se tcidu kei le linji cu cusku le jgena .e le krinu
  let drawing = drawnMerged($STATE.nif)
  document.getElementById("merged-parts").innerHTML = cstring(drawing.html)
  let line = document.getElementById("merged-status")
  line.textContent = cstring(drawing.status)
  line.className = cstring(if drawing.is_refused: "status err" else: "status")
  document.getElementById("merged").removeAttribute("hidden")


proc shown() =
  ## ciska lo pixra be le ca selci'a be fi `NIF` be'o le papri gi'e ciska le linji .e lo tadji be le
  ##     tcidu .e le selci'a be fi `NIF`
  ##   .i le cenba cu se tcita
  ##   .i lo pagbu poi ca'o kalri cu sepli lo drata
  let drawing = drawn($STATE.nif, $STATE.tail)
  document.getElementById("parts").innerHTML = cstring(drawing.html)
  document.getElementById("status").textContent = cstring(drawing.status)
  let
    head = escaped($STATE.nif.cut(STATE.at_last))
    changed = escaped($STATE.nif.after(STATE.at_last))
    open = escaped($STATE.tail)
  document.getElementById("nif").innerHTML = cstring(head & "<mark>" & changed & "</mark>" &
      "<span class=\"open\">" & open & "</span>")
  let mode =
    if STATE.reader.isNil: "le samtci na pu tcidu da"
    elif STATE.reader.isWorkerLive: "pa gunka cu tcidu le selci'a"
    else: "le vi papri cu tcidu le selci'a ki'u lo nu le papri cu dunda no gunka"
  document.getElementById("mode").textContent = cstring(mode)


proc drawnAtFrame(): Future[void] {.async.} =
  ## ciska lo pixra ca le bavla'i nu jarco
  ##   .i ba bo le bavla'i cenba cu ka'e cpedu lo nu jarco pe vo'a
  await nextFrame()
  STATE.is_waiting = false
  shown()


proc drawSoon(): Future[void] =
  ## dunda pa nupre be lo nu pixra ca le bavla'i nu jarco
  ##   .i ro cenba poi klama ca le ca nu jarco cu cpacu le mitnu'e
  ##   .i se ki'u bo ro pilno cu denpa le mintu nu pixra
  if not STATE.is_waiting:
    STATE.is_waiting = true
    DRAWING = drawnAtFrame()
  DRAWING



#[ ni'o ni'o ni'o lo nu tcidu ]#

proc started() =
  ## cfagau pa ninytcidu gi'e vimcu le selci'a be fi `NIF` be'o pe le pu tcidu
  inc STATE.generation
  STATE.reader = parseLojbanLive(jsUndefined)
  STATE.sent = ""
  STATE.is_ended = false
  STATE.nif = cstring(HEADER)
  STATE.tail = ""
  STATE.at_last = cstring(HEADER).lengthUnits
  mergeHidden()


proc applied(change: JsObject, generation: int): bool =
  ## galfi le selci'a be fi `NIF` be'o poi le papri cu ralte ke'a sepi'o le cenba pe le tcidu
  ##   .i `false` va'o lo nu le papri cu ba'o vimcu le tcidu
  if generation != STATE.generation: return false
  let at = change.at.to(int)
  STATE.nif = STATE.nif.cut(at) & change.text.to(cstring)
  STATE.tail = change.tail.to(cstring)
  STATE.at_last = at
  mergeHidden()
  true


proc given(piece: cstring): Future[void] {.async.} =
  ## dunda pa pagbu le tcidu gi'e pilno le cenba pe le pagbu gi'e ciska lo pixra ca le bavla'i nu
  ##     jarco
  let generation = STATE.generation
  STATE.sent = STATE.sent & piece
  let change = await STATE.reader.pushLive(piece)
  if change.applied(generation): await drawSoon()


proc ended(): Future[void] {.async.} =
  ## sisti lo mivyselci'a pe le tcidu gi'e pilno le cenba poi le fanmo cu dunda ke'a ku'o gi'e ciska
  ##     lo pixra ca le bavla'i nu jarco
  let generation = STATE.generation
  STATE.is_ended = true
  let change = await STATE.reader.finishLive
  if change.applied(generation): await drawSoon()


proc typed*(text: cstring): Future[void] {.async.} =
  ## dunda le selci'a poi le stuzi be lo nu ciska cu vasru ke'a
  ##   .i le ninfa'o be le selci'a cu klama le mitytcidu
  ##   .i va'o lo drata le mulselci'a cu klama pa ninytcidu
  if STATE.reader.isNil or STATE.is_ended or not text.isOpening(STATE.sent):
    started()
    if text.lengthUnits > 0: await given(text)
    else: await drawSoon()
    return
  let piece = text.after(STATE.sent.lengthUnits)
  if piece.lengthUnits > 0: await given(piece)


proc readWhole*(text: cstring): Future[void] {.async.} =
  ## tcidu le selci'a sepi'o pa ninytcidu gi'e sisti le tcidu ta'i lo mupli .e le pamoi se ciska
  started()
  if text.lengthUnits > 0: discard given(text)
  await ended()


proc streamed*(text: cstring, pause: int): Future[void] {.async.} =
  ## tcidu le selci'a sepi'o pa ninytcidu
  ##   .i ro pagbu cu valsi
  ##   .i lo temci poi jbini re lampau cu klani `pause` `millisecond`
  ##   .i ba bo sisti le tcidu
  ##   .i lo nu galfi poi rinka lo nu pa datytcidu cu cfari cu rinka lo nu le porsi be lo valsi cu
  ##       sisti
  started()
  let generation = STATE.generation
  for piece in text.pieces:
    if generation != STATE.generation: return
    await given(piece)
    if pause > 0: await paused(pause)
  if generation == STATE.generation: await ended()



#[ ni'o ni'o ni'o lo fasnu ]#

proc field(): TextAreaElement =
  ## dunda le stuzi be lo nu ciska
  TextAreaElement(document.getElementById("source"))


proc chosen(sample: cstring): proc(event: Event) =
  ## dunda pa fancu poi punji le mupli le stuzi be lo nu ciska gi'e tcidu le mulmupli
  ##   .i `sample` vasru le mupli pe ro batke
  ##   .i lo fancu poi selzba ne'i le nu rapli cu ralte le romoi mupli po'o
  result = proc(event: Event) =
    field().value = sample
    discard readWhole(sample)


proc wiredControls*() =
  ## jitro le stuzi be lo nu ciska .e lo mupli .e le batke po'u `Stream` .e le batke po'u `Merge`
  ##     ta'i lo selgau be le papri
  field().addEventListener("input", proc(event: Event) = discard typed(field().value))
  for button in document.querySelectorAll("[data-sample]"):
    button.addEventListener("click", chosen(button.getAttribute("data-sample")))
  document.getElementById("stream").addEventListener("click", proc(event: Event) =
    discard streamed(field().value, PAUSE_STREAM))
  document.getElementById("merge").addEventListener("click", proc(event: Event) = mergeShown())


proc wired() =
  ## jitro lo trotci
  ##   .i ba bo tcidu le selci'a poi le papri cu selkra ke'a ku'o noi lo nu zbasu cu ba'o ciska lo
  ##       pixra be ke'a
  wiredControls()
  discard readWhole(field().value)


if not DOCUMENT_PAGE.isNull and not defined(testing): wired()
