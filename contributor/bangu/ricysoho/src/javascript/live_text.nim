## tcidu lo mivyselci'a ne'i le samtci ca lo nu le selci'a cu klama to `#859` toi
##   .i `parseLojbanLive` jarco lo tcidu poi ponse `push` .e `finish` .e `nif`
##   .i ro le ci fancu cu jarco pa nupre
##   .i va'o lo nu le papri cu dunda pa gunka kei lo nu tcidu cu fasnu ne'i le gunka
##   .i se ki'u bo le papri cu denpa no roi
##   .i va'o lo drata le samtci cu tcidu pa jufra ca ro nu `event loop` carna to `Architect` jdice
##       di'u bu'u `#859` toi
##
##   |-------------------|-------------------------------------------------------------------------|
##   | lo cmene          | lo smuni                                                                |
##   |-------------------|-------------------------------------------------------------------------|
##   | `parseLojbanLive` | lo tcidu be lo mivyselci'a ne'i lo gunka poi le papri cu dunda ke'a  |
##   | `push`            | lo nupre be lo cenba poi le bavla'i spisa cu rinka ke'a ne'i `NIF`      |
##   | `finish`          | lo nupre be lo cenba pe lo fanmo noi jarco lo stapau be `NIF`      |
##   | `nif`             | lo nupre be `NIF` poi ca zvati                                          |
##   |                   | .i lo selbe'i cu lidne le rebla                                        |
##   | `isWorker`        | lo du'u lo nu tcidu cu fasnu ne'i lo gunka                              |
##   | `countRead`       | lo sumji be lo stuzi poi le paprycilta cu tcidu                        |
##   |                   | .i li no ne'i lo gunka                                                  |
##   | `countTurns`      | lo nu `event loop` carna kei poi tcidu ne'i lo cilta pe le papri     |
##   |-------------------|-------------------------------------------------------------------------|
##
## ni'o le cenba cu du `{at, start, text, tail}` ta'i lo nu `ChangeNif` pe `live.nim` jarco le cenba
##     to `D1 c` pe `#859` toi
##   .i le papri cu katna `NIF` poi le papri cu ralte ke'a ku'o bu'u `at`
##   .i ba bo le papri cu jmina `text`
##   .i se ki'u bo lo temci poi jdima lo porsi be lo valsi be'o pe so'i cacra cu ckini lo ni le
##       porsi cu clani kei ta'i lo linji
##   .i `nif` jarco `NIF` poi ca zvati ku'o pa roi ca lo nu le papri cu cpedu
##
## ni'o `at` kancu lo pagbu pe `UTF-16` ta'i lo nu lo lerpoi pe `JavaScript` kancu `NIF`
##   .i se ki'u bo `slice` katna bu'u `at`
##   .i `start` kancu lo stuzi be le selci'a ta'i `UTF-8`
##   .i ro valsi pe `NIF` go'i
##   .i se ki'u bo le cenba cu jorne le selci'a
##
## ni'o se to'e cuxna fa lo nu ro nupre cu vasru `NIF` poi ca zvati
##   .i ki'u bo ro spisa cu rinka lo nu `NIF` selfu'i ta'i lo mulno gi'e selbe'i fo le gunka
##   .i va'o lo nu ro valsi pe lo selci'a poi vasru lo seljonju'a pe `Tatoeba` spisa kei le se to'e
##       cuxna cu fukpi `363 MB`
##   .i ku'i lo cenba cu fukpi `1.8 MB`
##   .i va'o lo nu le selci'a cu clani bi roi kei le se to'e cuxna cu fukpi `24.0 GB`
##   .i ku'i lo cenba cu fukpi `15.5 MB` to `Architect` jdice di'u bu'u `#859` toi
##
## ni'o le gunka cu du le samtci gi'e selcme `NAME_WORKER` gi'e selkra lo judri poi le papri cu
##     cpacu le samtci ke'a
##   .i va'o lo nu le papri cu vasru le selci'a pe le samtci kei le gunka cu selkra le selci'a ta'i
##       `Blob`
##   .i lo paprycilta cu basti ro gunka poi fliba pu lo nu ke'a spuda fi lo du'u ke'a bredi
##   .i ba bo le cilta cu tcidu ro spisa poi pu selbe'i fi le gunka ku'o ta'i le porsi
##
## ni'o lo paprycilta cu tcidu ro jufra pe ro spisa ta'i lo porsi to `toSentences` toi
##   .i ca ro nu `event loop` carna kei pa jufra cu se tcidu
##   .i ca ro nu tcidu pa spisa le cilta cu jarco pa cenba to `combine` toi
##   .i ro nu carna cu du pa notci pe `MessageChannel`
##   .i no junla cu rinka lo nu le notci cu denpa
##   .i no junla be lo cipra cu ralte le notci
##
## ni'o se to'e cuxna fa lo nu tcidu ro spisa ca pa nu carna ne'i lo paprycilta
##   .i ki'u bo le papri cu denpa ca lo temci be lo nu tcidu le selci'a pe le spisa
##   .i le temci cu jibni lo pilji be li cize bei lo temci be lo nu le jbezba cu tcidu le se ciska
##       to lu le se zbasu pe `JavaScript` li'u pe `PROVENANCE.md` toi
##
## ni'o ro nu cpedu cu selspu ta'i le porsi be lo nu cpedu
##   .i le gunka cu spuda lo notci ta'i le porsi
##   .i lo paprycilta cu tcidu lo nu cpedu fi pa porsi
##
## ni'o le tcidu cu rapli ja'i lo namcu pe lo porsi
##   .i ki'u bo `items` fukpi va'o lo nu fanva fi `JavaScript`

{.experimental: "strictFuncs".}
{.used.}  # `bridge.nim` cpacu le vi datnyvei ki'u lo nu benji `parseLojbanLive` le samtci po'o

import std/[algorithm, asyncjs, jsffi, unicode]

import ../ricysoho/[live, nif]


type
  Asked = enum  ## lo selcpe be le papri bei le tcidu
    Push = "push", Finish = "finish", Nif = "nif"

  Ask = object  ## pa nu cpedu poi denpa lo nu selspu
    kind: Asked
    piece: string
      ## lo spisa be lo mivyselci'a poi `push` dunda ke'a
      ##   .i kunti va'o lo drata nu cpedu
    resolve: proc(response: JsObject)  ## dunda lo terspu be le nu cpedu le nupre pe le nu cpedu

  LinesNif = object
    ## lo fanmo be ro linji pe `NIF` poi selra'e
    ##   .i le fanmo cu se kancu ta'i lo stuzi .e lo pagbu pe `UTF-16`
    ##   .i lo nu kancu cu cfari bu'u le krasi be le minde
    bytes: seq[int]
    units: seq[int]

  ReaderScript = ref object
    ## lo tcidu poi le papri cu ralte ke'a
    ##   .i le tcidu cu du pa gunka .a pa tcidu poi zvati lo paprycilta
    worker: JsObject
      ## lo gunka poi tcidu lo mivyselci'a
      ##   .i kunti va'o lo nu lo paprycilta cu tcidu le selci'a
    is_ready: bool  ## lo du'u le gunka pu spuda fi lo du'u le gunka cu bredi
    sent: seq[Ask]  ## lo porsi be lo nu cpedu poi pu selbe'i fi le gunka gi'e na pu selspu
    asks: seq[Ask]  ## lo porsi be lo nu cpedu poi lo paprycilta cu na pu spuda ke'a
    is_finished: bool  ## lo du'u le papri pu cpedu lo fanmo be lo mivyselci'a
    reader: ReaderLive
      ## lo tcidu poi zvati lo paprycilta
      ##   .i tcidu no da va'o lo nu lo gunka cu tcidu
    lines: LinesNif
      ## lo linji pe `NIF` poi le tcidu poi zvati lo paprycilta cu ralte ke'a
    tail: string  ## le rebla pe le romoi cenba ne'i lo paprycilta
    sentences: seq[string]
      ## lo jufra pe le spisa poi ca se tcidu
      ##   .i ro nu carna cu tcidu pa le jufra
    changes: seq[ChangeNif]  ## lo cenba pe ro jufra pe le spisa poi ca se tcidu
    channel: JsObject
      ## lo tubnu
      ##   .i ro notci pe le tubnu cu du pa nu `event loop` carna
      ##   .i kunti pu lo pamoi nu carna
    is_turning: bool  ## lo du'u pa nu carna cu denpa ne'i `event loop`
    count_turns: int  ## lo nu `event loop` carna kei poi tcidu ne'i lo paprycilta


const NAME_WORKER = "ricyso'o live"
  ## lo cmene be lo gunka be lo mivyselci'a
  ##   .i ki'u le cmene le samtci cu djuno lo du'u le samtci cu sidju le papri lo nu tcidu kei gi'e
  ##       na sidju pa gunka poi le papri cu dunda lo selgu'a pe le papri ke'a


let
  DOCUMENT {.nodecl, importc: "document".}: JsObject
    ## `document` pe le papri
    ##   .i no da zasti ne'i lo gunka
  SELF {.nodecl, importc: "self".}: JsObject  ## le mulvanbi pe le papri .a pa gunka
    ## lo korbi be `JS`
    ##   .i `typeof` tcidu ro le re datni
    ##   .i ki'u bo lo sapcme be lo muldatni poi na selja'o cu rinka lo srera
  SCRIPT_LOADED = (if DOCUMENT.jsTypeOf != "undefined": DOCUMENT.currentScript else: jsNull)
    ## lo pagbu be le papri be'o poi vasru le samtci poi le papri cu cpacu ke'a
    ##   .i le pagbu cu jarco lo judri .a lo selci'a pe le samtci
    ##   .i le pagbu cu se tcidu ca lo nu le samtci cu selcpa
    ##   .i ki'u bo ba la'e di'u le papri cu tcidu le pagbu ta'i lo kunti
    ##   .i kunti ne'i lo gunka


proc newWorker(address: cstring, options: JsObject): JsObject {.importjs: "new Worker(@)".}
  ## zbasu lo gunka fi lo samtci poi zvati `address`
  ##   .i lo korbi be `JS`
  ##   .i lo zbafancu pe le papri
proc newBlobScript(text: cstring): JsObject {.importjs: "new Blob([#], {type: 'text/javascript'})".}
  ## ralte lo selci'a pe lo samtci ta'i `Blob`
  ##   .i lo gunka cu cpacu `Blob` sepi'o lo judri
  ##   .i lo korbi be `JS`
proc toAddress(blob: JsObject): cstring {.importjs: "URL.createObjectURL(#)".}
  ## jarco lo judri poi le papri cu dunda `Blob` bu'u ke'a
  ##   .i lo korbi be `JS`
proc newChannel(): JsObject {.importjs: "new MessageChannel()".}
  ## zbasu lo tubnu poi selpau re vorme
  ##   .i ro notci pe le tubnu cu du pa nu `event loop` carna
  ##   .i lo korbi be `JS`



#[ ni'o ni'o ni'o lo linji ]#

func countUnits(text: string): int =
  ## kancu lo pagbu poi le selci'a cu nitcu ke'a ne'i `UTF-16` ta'i lo nu lo lerpoi pe `JavaScript`
  ##     kancu le selci'a
  ##   .i ro lerfu poi zmadu `U+FFFF` nitcu re pagbu
  ##   .i ro datle'u cu nitcu pa pagbu
  for rune in text.runes: result += (if int32(rune) > 0xFFFF: 2 else: 1)


func add(lines: var LinesNif, text: string) =
  ## jmina ro linji pe `NIF` poi `text` vasru ke'a
  ##   .i lo lijyfa'o cu fanmo ro le linji
  ##   .i ro jgena pe `NIF` selfa'o lo lijyfa'o
  var first = 0
  for k in 0 ..< text.len:
    if text[k] != '\n': continue
    lines.bytes.add lines.bytes[^1] + k + 1 - first
    lines.units.add lines.units[^1] + text[first .. k].countUnits
    first = k + 1
  doAssert first == text.len, "NIF should end each line with line end; got `" & text & "`."


func initLinesNif(): LinesNif =
  ## zbasu lo linji pe `NIF` poi vasru le minde po'o
  result = LinesNif(bytes: @[0], units: @[0])
  result.add HEADER


func apply(lines: var LinesNif, change: ChangeNif): int =
  ## katna le linji bu'u le stuzi be le cenba be'o noi krasi pa linji
  ##   .i jmina lo linji pe lo selci'a pe le cenba
  ##   .i jarco lo ni `NIF` vasru lo pagbu pe `UTF-16` pu le stuzi
  let k = lines.bytes.lowerBound(change.at)
  doAssert k < lines.bytes.len and lines.bytes[k] == change.at,
    "Change should cut NIF where line opens; got offset " & $change.at & "."
  lines.bytes.setLen(k + 1)
  lines.units.setLen(k + 1)
  result = lines.units[k]
  lines.add change.text


proc toObject(change: ChangeNif, units: int): JsObject =
  ## fukpi le cenba ta'i lo sapydai
  ##   .i le stuzi pe `NIF` se kancu ta'i lo pagbu pe `UTF-16`
  result = newJsObject()
  result.at = units
  result.start = change.start
  result.text = cstring(change.text)
  result.tail = cstring(change.tail)



#[ ni'o ni'o ni'o lo gunka ]#

var
  READER_WORKER = initReaderLive()
    ## lo tcidu ne'i lo gunka be lo mivyselci'a
    ##   .i tcidu no da ne'i le papri
  LINES_WORKER = initLinesNif()
    ## lo linji pe `NIF` poi le tcidu ne'i le gunka cu ralte ke'a
  TAIL_WORKER: string  ## le rebla pe le romoi cenba ne'i le gunka


proc answerPage(event: JsObject) =
  ## spuda pa nu cpedu pe le papri ne'i le gunka
  ##   .i le terspu cu du lo cenba pe pa spisa ge'u .a lo cenba pe lo fanmo ge'u .a `NIF` poi ca
  ##       zvati
  let response = newJsObject()
  case $event.data.kind.to(cstring)
  of $Push, $Finish:
    let change =
      if $event.data.kind.to(cstring) == $Push: READER_WORKER.push($event.data.piece.to(cstring))
      else: READER_WORKER.finish
    TAIL_WORKER = change.tail
    response.answer = change.toObject(LINES_WORKER.apply(change))
  else: response.answer = cstring(READER_WORKER.toNif & TAIL_WORKER).toJs
  SELF.postMessage(response)


proc isWorkerLive(): bool =
  ## jdice lo du'u le samtci cu du lo gunka be lo mivyselci'a be'o poi le papri cu rinka lo nu ke'a
  ##     cfari
  DOCUMENT.jsTypeOf == "undefined" and SELF.jsTypeOf != "undefined" and
    SELF.name.jsTypeOf == "string" and $SELF.name.to(cstring) == NAME_WORKER



#[ ni'o ni'o ni'o lo cilta pe le papri ]#

proc turn(reader: ReaderScript)


proc schedule(reader: ReaderScript) =
  ## cpedu lo nu carna fi `event loop` va'o lo nu lo paprycilta cu ponse lo nu cpedu poi na pu
  ##     selspu kei .e lo nu no nu carna cu denpa
  if reader.is_turning or reader.asks.len == 0: return
  reader.is_turning = true
  if reader.channel.isNil:
    reader.channel = newChannel()
    reader.channel.port1.onmessage = proc(event: JsObject) = reader.turn()
  reader.channel.port2.postMessage(0)


proc turn(reader: ReaderScript) =
  ## tcidu ne'i lo paprycilta ca pa nu carna
  ##   .i tcidu pa jufra pe le pamoi se cpedu spisa gi'a tcidu lo fanmo gi'a jarco `NIF` poi ca
  ##       zvati
  ##   .i spuda le nu cpedu ca lo nu le spisa cu mulseltcidu
  ##   .i ba bo cpedu lo bavla'i nu carna
  reader.is_turning = false
  inc reader.count_turns
  template ask: untyped = reader.asks[0]
    ## lo datcme be lo nu cpedu poi ca selspu
    ##   .i `let` da'i fukpi le nu cpedu
  var answer: JsObject
  case ask.kind
  of Push:
    if reader.changes.len == 0: reader.sentences = ask.piece.toSentences
    reader.changes.add reader.reader.push(reader.sentences[reader.changes.len])
    # su'o jufra cu stali
    #   .i ro le jufra cu se tcidu ca pa nu carna pe vo'a
    if reader.changes.len < reader.sentences.len:
      reader.schedule()
      return
    let change = reader.changes.combine(reader.reader.toNif)
    reader.changes.setLen(0)
    reader.tail = change.tail
    answer = change.toObject(reader.lines.apply(change))
  of Finish:
    let change = reader.reader.finish
    reader.tail = change.tail
    answer = change.toObject(reader.lines.apply(change))
  of Nif: answer = cstring(reader.reader.toNif & reader.tail).toJs
  let resolve = ask.resolve
  reader.asks.delete(0)
  reader.schedule()
  resolve(answer)


proc giveWay(reader: ReaderScript) =
  ## dunda ro nu cpedu poi pu selbe'i fi lo gunka poi fliba pu lo nu bredi ku'o ku'o lo cilta pe le
  ##     papri ta'i le porsi
  reader.worker.terminate()
  reader.worker = nil
  reader.asks = reader.sent & reader.asks
  reader.sent.setLen(0)
  reader.schedule()


proc startWorker(reader: ReaderScript) =
  ## zbasu lo gunka be lo mivyselci'a be'o fi le samtci poi le papri cu cpacu ke'a ku'o va'o lo nu
  ##     le papri cu dunda lo gunka .e lo samtci
  ##   .i va'o lo nu le papri cu dunda no le re dacti gi'a to'e curmi lo gunka kei curmi lo nu lo
  ##       paprycilta cu tcidu
  if SCRIPT_LOADED.isNull or SCRIPT_LOADED.isUndefined or SELF.Worker.jsTypeOf != "function":
    return
  let options = newJsObject()
  options.name = cstring(NAME_WORKER)
  try:
    let address =
      if $SCRIPT_LOADED.src.to(cstring) != "": SCRIPT_LOADED.src.to(cstring)
      else: SCRIPT_LOADED.text.to(cstring).newBlobScript.toAddress
    reader.worker = newWorker(address, options)
  except CatchableError, Defect:
    # le papri cu to'e curmi le gunka
    #   .i lo javni pe lo selvau be le papri cu ka'e rinka la'e di'u
    return
  reader.worker.onmessage = proc(event: JsObject) =
    if event.data.ready.to(bool):
      reader.is_ready = true
      return
    let resolve = reader.sent[0].resolve
    reader.sent.delete(0)
    resolve(event.data.answer)
  reader.worker.onerror = proc(event: JsObject) =
    if not reader.is_ready: reader.giveWay()


proc ask(reader: ReaderScript, kind: Asked, piece: string): Future[JsObject] =
  ## cpedu fi le tcidu fe lo cenba pe pa spisa ge'u .a lo cenba pe lo fanmo ge'u .a `NIF` poi ca
  ##     zvati
  ##   .i jarco lo nupre poi selspu ta'i le porsi be lo nu cpedu
  doAssert not (reader.is_finished and kind != Nif), "Live text should take no " & $kind &
    " after its end."
  reader.is_finished = reader.is_finished or kind == Finish
  newPromise(proc(resolve: proc(response: JsObject)) =
    let asked = Ask(kind: kind, piece: piece, resolve: resolve)
    if reader.worker.isNil:
      reader.asks.add asked
      reader.schedule()
      return
    reader.sent.add asked
    let message = newJsObject()
    message.kind = cstring($kind)
    message.piece = cstring(piece)
    reader.worker.postMessage(message))


proc parseLojbanLive*(options: JsObject): JsObject {.exportc.} =
  ## zbasu lo tcidu be lo mivyselci'a
  ##   .i le tcidu cu tcidu ne'i lo gunka va'o lo nu le papri cu dunda pa gunka
  ##   .i va'o lo drata le tcidu cu tcidu ne'i lo paprycilta
  ##   .i lo cuxna po'u `worker: false` ralte lo nu tcidu ne'i lo paprycilta
  ##
  ## ni'o lo korbi be `JS`
  ##   .i `exportc` ralte lo cmene po'u `parseLojbanLive` ne'i le samtci
  ##   .i ro spisa cu klama ta'i lo lerpoi pe `JavaScript`
  ##   .i `$` jarco lo stuzi pe le spisa ta'i `UTF-8`
  ##   .i le tcidu cu tcidu le stuzi
  let
    reader = ReaderScript(reader: initReaderLive(), lines: initLinesNif())
    is_worker = options.isUndefined or options.isNull or options.worker.isUndefined or
      options.worker.to(bool)
  if is_worker: reader.startWorker()
  result = newJsObject()
  result.push = proc(piece: cstring): Future[JsObject] = reader.ask(Push, $piece)
  result.finish = proc(): Future[JsObject] = reader.ask(Finish, "")
  result.nif = proc(): Future[JsObject] = reader.ask(Nif, "")
  result.isWorker = proc(): bool = not reader.worker.isNil
  result.countRead = proc(): int = reader.reader.countRead
  result.countTurns = proc(): int = reader.count_turns


# va'o lo nu le papri cu rinka lo nu le samtci cu cfari ta'i la'e di'u kei kei le samtci cu spuda le
#     papri ta'i lo gunka be lo mivyselci'a
#   .i va'o lo drata le datnyvei cu jarco le tcidu po'o
if isWorkerLive():
  SELF.onmessage = answerPage
  let ready = newJsObject()
  ready.ready = true
  SELF.postMessage(ready)
