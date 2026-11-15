## jitro le papri pe lo jmive se ciska to `pages/live.html` toi ne'i la'o gy. JavaScript .gy.
##   .i le stuzi be lo nu ciska cu dunda lo jmive se ciska lo tcidu pe `parseLojbanLive`
##   .i le tcidu cu tcidu ne'i pa gunka va'o lo nu le papri cu dunda pa gunka
##   .i le papri cu galfi lo se ciska be fi la'o gy. NIF .gy. be'o poi le papri cu ralte ke'a sepi'o
##     ro cenba
##   .i ba bo le papri cu pixra le ca se ciska be fi la'o gy. NIF .gy. to `draw.nim` toi
##
##   |--------------|----------------------------------------------------------------------------|
##   | lo fancu     | lo smuni                                                                   |
##   |--------------|----------------------------------------------------------------------------|
##   | `typed`      | benji le cnino pagbu le mintu tcidu                                          |
##   |              | .i va'o lo drata pa cnino tcidu cu tcidu                                     |
##   | `readWhole`  | tcidu le se ciska sepi'o pa cnino tcidu gi'e sisti le tcidu ta'i lo mupli  |
##   | `streamed`   | pa cnino tcidu cu tcidu le se ciska                                        |
##   |              | .i ro pagbu cu valsi                                                       |
##   |              | .i sisti le tcidu                                                          |
##   | `mergeShown` | le linji .e lo pixra be ro ve jmina be lo mulno pagbu                      |
##   |              | .i lo srera cu stali                                                       |
##   |--------------|----------------------------------------------------------------------------|
##
## ni'o le samtci cu du le mulno genturfa'i ta'i lo nu le cripu cu jarco le genturfa'i
##   .i se ki'u bo lo nu tcidu cu fasnu ne'i lo gunka poi se krasi le se ciska pe le samtci
##   .i ne'i le gunka no papri cu zasti
##   .i no pagbu be le papri cu se jitro
##   .i le papri cu ralte le ca se ciska be fi la'o gy. NIF .gy. ta'i pa lerpoi pe la'o gy.
##     JavaScript .gy.
##   .i le papri cu katna le se ciska bu'u `at` pe le cenba gi'e jmina `text`
##   .i ba bo le papri cu pixra `tail` ta'i lo pagbu poi ca'o kalri
##   .i lo bavla'i cenba cu basti `tail` to `D1 c` pe `#859` toi
##   .i lo se ciska poi zenba bu'u lo fanmo be ke'a po'o cu se benji fi le mintu tcidu ta'i lo nu lo
##     jmive se ciska cu klama
##   .i va'o ro drata nu galfi kei pa cnino tcidu cu tcidu le mulno se ciska
##   .i ro mupli .e ro porsi be lo valsi .e le pamoi se ciska cu sisti lo tcidu pe vo'a
##   .i se ki'u bo ro pagbu pe ro le se ciska cu ganlo
##   .i lo se ciska poi lo prenu cu ciska ke'a cu ca'o kalri ta'i lo jmive se ciska
##   .i ro cenba cu se kansa lo namcu pe le tcidu poi dunda le cenba
##   .i lo cenba pe lo tcidu poi le papri cu ba'o vimcu ke'a cu rinka no nu pixra
##   .i lo nu pixra cu denpa lo bavla'i nu jarco
##   .i se ki'u bo su'o re cenba pe pa nu jarco cu se pixra pa roi
##   .i ro cenba pe pa nu jarco cu denpa le pa nu pixra
##   .i `typed` .e `readWhole` .e `streamed` cu jarco pa nupre poi mulno ca lo nu lo romoi cenba pe
##     le fancu cu se pixra
##   .i lo cipra pe le papri cu denpa le nupre to `tests/browser/suite_page.nim` toi
##   .i se ki'u bo no xusra cu denpa lo temci
##   .i lo nu zbasu cu punji lo jbena pixra be le pamoi se ciska le papri to lo minde po'u `page`
##     toi
##   .i se ki'u bo le papri cu mulno se tcidu pu lo nu le samtci cu cfari
##   .i lo denpa poi zvati lo jbini be lo valsi pe pa porsi be lo valsi cu du pa junla pe le papri
##   .i lo cipra pe le papri cu benji lo porsi be lo valsi ta'i no denpa
##   .i lo nu jmina cu jmina ro pagbu be le ca se ciska be fi la'o gy. NIF .gy. fo pa tricu pe lo nu
##     tcidu le mulno se ciska .a ro tricu pe ro porsi be lo pagbu poi sruri pa srera poi stali to
##     `drawnMerged` pe `draw.nim` toi
##   .i le rebla cu na se jmina
##   .i le papri cu pixra ro tricu poi cnita le pagbu
##   .i lo nu jmina cu fasnu ne'i lo cilta pe le papri
##   .i ki'u bo lo nu jmina cu tcidu lo se ciska be fi la'o gy. NIF .gy. be'o poi le papri cu ralte
##     ke'a
##   .i ro cenba cu mipri lo tricu poi se jmina zi'e noi ca na drani
##   .i lo cipra pe le papri cu jitro lo jitro tutci ta'i le papri to `wiredControls` toi gi'e danre
##     le jitro tutci
##   .i se ki'u bo le cipra cu cipra lo se gasnu be lo batke pe le papri

{.experimental: "strictFuncs".}

import std/[asyncjs, dom, jsffi]

import ../javascript/[bridge, live_text]
import ../lojban_parser/nif
import ./draw


const
  LENGTH_MOST* = 2000
    ## lo du'u le stuzi be lo nu ciska cu vasru su'e xo kau lerfu
    ##   .i le namcu cu mintu `maxlength` pe le stuzi to `pages/live.html` toi
  PAUSE_STREAM = 140
    ## lo temci poi se merli fo la'o gy. ms .gy. gi'e jbini lo valsi pe lo porsi be lo valsi


type StatePage = object  ## lo se ralte be le papri be'o pe le jmive se tcidu be le papri
  reader: JsObject  ## lo tcidu be lo jmive se ciska to `nil` pu le pamoi se ciska toi
  generation: int
    ## lo du'u le papri cu cfagau xo kau tcidu
    ##   .i lo cenba pe lo pu tcidu cu rinka no nu pixra
  sent: cstring  ## lo se ciska poi le papri ba'o dunda ke'a le tcidu
  is_ended: bool
    ## le tcidu cu ba'o cpacu lo fanmo pe vo'a
    ##   .i se ki'u bo le tcidu cu cpacu no drata pagbu
  nif: cstring  ## le ca se ciska be fi la'o gy. NIF .gy. be'o noi se krasi lo minde
  tail: cstring  ## lo se ciska be fi la'o gy. NIF .gy. be'o pe ro pagbu poi ca'o kalri
  at_last: int
    ## lo stuzi be le romoi cenba ne'i la'o gy. NIF .gy.
    ##   .i lo pagbu pe la'o gy. UTF-16 .gy. cu se kancu
  is_waiting: bool  ## lo nu pixra cu denpa lo bavla'i nu jarco


var
  STATE = StatePage(nif: cstring(HEADER), tail: "")  ## lo se ralte be le papri
  DRAWING: Future[void]
    ## lo nu pixra poi denpa lo bavla'i nu jarco
    ##   .i ro cenba pe le nu jarco cu denpa le nu pixra


let DOCUMENT_PAGE {.nodecl, importc: "(typeof document === 'undefined' ? null : document)".}:
    JsObject
  ## `document` pe le papri
  ##   .i `null` ne'i lo gunka noi no papri cu se jitro bu'u ke'a


proc pushLive(reader: JsObject, piece: cstring): Future[JsObject] {.importjs: "#.push(#)".}
  ## dunda pa pagbu lo tcidu be lo jmive se ciska
  ##   .i korbi la'o gy. JS .gy. sepi'o lo fancu pe le tcidu
proc finishLive(reader: JsObject): Future[JsObject] {.importjs: "#.finish()".}
  ## sisti lo jmive se ciska pe le tcidu
  ##   .i korbi la'o gy. JS .gy. sepi'o lo fancu pe le tcidu
proc isWorkerLive(reader: JsObject): bool {.importjs: "#.isWorker()".}
  ## jdice lo du'u le tcidu cu tcidu ne'i pa gunka
  ##   .i korbi la'o gy. JS .gy. sepi'o lo fancu pe le tcidu
proc cut(text: cstring, at: int): cstring {.importjs: "#.slice(0, #)".}
  ## dunda lo se ciska poi lidne `at` noi pagbu pe la'o gy. UTF-16 .gy.
  ##   .i korbi la'o gy. JS .gy. sepi'o `slice` pe lo lerpoi
proc after(text: cstring, at: int): cstring {.importjs: "#.slice(#)".}
  ## dunda lo se ciska poi se krasi `at` noi pagbu pe la'o gy. UTF-16 .gy.
  ##   .i korbi la'o gy. JS .gy. sepi'o `slice` pe lo lerpoi
proc isOpening(text, opening: cstring): bool {.importjs: "#.startsWith(#)".}
  ## jdice lo du'u le se ciska cu se krasi `opening`
  ##   .i korbi la'o gy. JS .gy. sepi'o `startsWith` pe lo lerpoi
proc lengthUnits(text: cstring): int {.importjs: "#.length".}
  ## kancu lo pagbu pe la'o gy. UTF-16 .gy. ne'i le se ciska
  ##   .i korbi la'o gy. JS .gy. sepi'o `length` pe lo lerpoi
proc pieces(text: cstring): seq[cstring] {.importjs: "(#.match(/\\s*\\S+/g) || [])".}
  ## fendi le se ciska lo valsi
  ##   .i lo canlu lerfu cu lidne ro valsi
  ##   .i korbi la'o gy. JS .gy. sepi'o pa `regex`
proc nextFrame(): Future[void] {.importjs:
  "new Promise(function(resolve) { requestAnimationFrame(function() { resolve(); }); })".}
  ## dunda pa nupre be le bavla'i nu jarco be le papri
  ##   .i korbi la'o gy. JS .gy. sepi'o `requestAnimationFrame`
proc paused(milliseconds: int): Future[void] {.importjs:
  "new Promise(function(resolve) { setTimeout(resolve, #); })".}
  ## dunda pa nupre be lo junla pe le papri
  ##   .i lo porsi be lo valsi po'o cu denpa le nupre
  ##   .i korbi la'o gy. JS .gy.



#[ ni'o ni'o ni'o lo nu pixra ]#

proc mergeHidden() =
  ## mipri lo tricu poi se jmina
  ##   .i ki'u bo lo cenba cu rinka lo nu le tricu cu na drani
  document.getElementById("merged").setAttribute("hidden", "")


proc mergeShown() =
  ## jmina ro pagbu poi le ca se ciska be fi la'o gy. NIF .gy. cu vasru ke'a
  ##   .i le rebla cu na se jmina
  ##   .i ciska lo pixra be ro tricu poi le nu jmina cu jarco ke'a ku'o bu'u lo cnita be le pagbu
  ##   .i va'o lo nu le se ciska be fi la'o gy. NIF .gy. cu na se tcidu kei le linji cu cusku le
  ##     jgena .e le krinu
  let drawing = drawnMerged($STATE.nif)
  document.getElementById("merged-parts").innerHTML = cstring(drawing.html)
  let line = document.getElementById("merged-status")
  line.textContent = cstring(drawing.status)
  line.className = cstring(if drawing.is_refused: "status err" else: "status")
  document.getElementById("merged").removeAttribute("hidden")


proc shown() =
  ## ciska lo pixra be le ca se ciska be fi la'o gy. NIF .gy. be'o le papri
  ##   .i ciska ji'a le linji .e lo tadji be le tcidu .e le se ciska be fi la'o gy. NIF .gy.
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
    if STATE.reader.isNil: "The script has not read any text."
    elif STATE.reader.isWorkerLive: "A worker reads the text."
    else: "This page reads the text, since it gives no worker."
  document.getElementById("mode").textContent = cstring(mode)


proc drawnAtFrame(): Future[void] {.async.} =
  ## ciska lo pixra ca le bavla'i nu jarco
  ##   .i ba bo le bavla'i cenba cu ka'e cpedu lo nu jarco pe vo'a
  await nextFrame()
  STATE.is_waiting = false
  shown()


proc drawSoon(): Future[void] =
  ## dunda pa nupre be lo nu pixra ca le bavla'i nu jarco
  ##   .i ro cenba poi klama ca le ca nu jarco cu cpacu le mintu nupre
  ##   .i se ki'u bo ro pilno cu denpa le mintu nu pixra
  if not STATE.is_waiting:
    STATE.is_waiting = true
    DRAWING = drawnAtFrame()
  DRAWING



#[ ni'o ni'o ni'o lo nu tcidu ]#

proc started() =
  ## cfagau pa cnino tcidu gi'e vimcu le se ciska be fi la'o gy. NIF .gy. be'o pe le pu tcidu
  inc STATE.generation
  STATE.reader = parseLojbanLive(jsUndefined)
  STATE.sent = ""
  STATE.is_ended = false
  STATE.nif = cstring(HEADER)
  STATE.tail = ""
  STATE.at_last = cstring(HEADER).lengthUnits
  mergeHidden()


proc applied(change: JsObject, generation: int): bool =
  ## galfi le se ciska be fi la'o gy. NIF .gy. be'o poi le papri cu ralte ke'a sepi'o le cenba pe le
  ##   tcidu
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
  ##   jarco
  let generation = STATE.generation
  STATE.sent = STATE.sent & piece
  let change = await STATE.reader.pushLive(piece)
  if change.applied(generation): await drawSoon()


proc ended(): Future[void] {.async.} =
  ## sisti lo jmive se ciska pe le tcidu gi'e pilno le cenba poi le fanmo cu dunda ke'a ku'o gi'e
  ##   ciska lo pixra ca le bavla'i nu jarco
  let generation = STATE.generation
  STATE.is_ended = true
  let change = await STATE.reader.finishLive
  if change.applied(generation): await drawSoon()


proc typed*(text: cstring): Future[void] {.async.} =
  ## dunda le se ciska poi le stuzi be lo nu ciska cu vasru ke'a
  ##   .i le cnino fanmo be le se ciska cu klama le mintu tcidu
  ##   .i va'o lo drata le mulno se ciska cu klama pa cnino tcidu
  if STATE.reader.isNil or STATE.is_ended or not text.isOpening(STATE.sent):
    started()
    if text.lengthUnits > 0: await given(text)
    else: await drawSoon()
    return
  let piece = text.after(STATE.sent.lengthUnits)
  if piece.lengthUnits > 0: await given(piece)


proc readWhole*(text: cstring): Future[void] {.async.} =
  ## tcidu le se ciska sepi'o pa cnino tcidu gi'e sisti le tcidu ta'i lo mupli .e le pamoi se ciska
  started()
  if text.lengthUnits > 0: discard given(text)
  await ended()


proc streamed*(text: cstring, pause: int): Future[void] {.async.} =
  ## tcidu le se ciska sepi'o pa cnino tcidu
  ##   .i ro pagbu cu valsi
  ##   .i lo temci poi jbini re lamji pagbu cu klani `pause` la'o gy. millisecond .gy.
  ##   .i ba bo sisti le tcidu
  ##   .i lo nu galfi poi rinka lo nu pa drata tcidu cu cfari cu rinka lo nu le porsi be lo valsi cu
  ##     sisti
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
  ## dunda pa fancu poi punji le mupli le stuzi be lo nu ciska gi'e tcidu le mulno mupli
  ##   .i `sample` cu vasru le mupli pe ro batke
  ##   .i lo fancu poi se zbasu ne'i le nu rapli cu ralte le romoi mupli po'o
  result = proc(event: Event) =
    field().value = sample
    discard readWhole(sample)


proc wiredControls*() =
  ## jitro le stuzi be lo nu ciska .e lo mupli .e le batke po'u la'o gy. Stream .gy. .e le batke
  ##   po'u la'o gy. Merge .gy. ta'i lo se gasnu be le papri
  field().addEventListener("input", proc(event: Event) = discard typed(field().value))
  for button in document.querySelectorAll("[data-sample]"):
    button.addEventListener("click", chosen(button.getAttribute("data-sample")))
  document.getElementById("stream").addEventListener("click", proc(event: Event) =
    discard streamed(field().value, PAUSE_STREAM))
  document.getElementById("merge").addEventListener("click", proc(event: Event) = mergeShown())


proc wired() =
  ## jitro lo jitro tutci
  ##   .i ba bo tcidu le se ciska poi le papri cu se krasi ke'a ku'o noi lo nu zbasu cu ba'o ciska
  ##     lo pixra be ke'a
  wiredControls()
  discard readWhole(field().value)


if not DOCUMENT_PAGE.isNull and not defined(testing): wired()
