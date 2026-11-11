## Read live text in script as it arrives (#859): `parseLojbanLive` gives reader whose `push`,
##   `finish` and `nif` each give promise. Where page gives worker, reading runs there, so page
##   never waits; elsewhere script reads one sentence at each turn of event loop (rulings on
##   #859).
##
##   |-----------------|-------------------------------------------------------------------|
##   | Code            | Meaning                                                           |
##   |-----------------|-------------------------------------------------------------------|
##   | parseLojbanLive | reader of live text, in worker where page gives one               |
##   | push            | promise of change next piece makes to NIF                         |
##   | finish          | promise of change end makes, which gives rest of NIF              |
##   | nif             | promise of NIF so far: NIF that went out, then tail               |
##   | isWorker        | whether reading runs in worker                                    |
##   | countRead       | bytes read on thread of page, summed: none where worker reads     |
##   | countTurns      | turns of event loop that read on thread of page                   |
##   |-----------------|-------------------------------------------------------------------|
##
##   Change is `{at, start, text, tail}`, as `ChangeNif` of `live.nim` gives it (D1 c of #859):
##     page cuts NIF it holds back to `at`, then adds `text`, so stream of hours costs time linear
##     in its length. `nif` gives NIF so far once, where page asks for it.
##     `at` counts units of UTF-16, as string of JavaScript indexes NIF, so `slice` cuts there;
##       `start` counts bytes of text in UTF-8, as each word of NIF does, so change ties to it.
##     Rejected: NIF so far in each promise, which copies whole NIF out of worker for each piece.
##       Tatoeba joined, read word by word, copies 363 MB so, against 1.8 MB of changes, and
##       24.0 GB against 15.5 MB at eight times its length (ruling on #859).
##   Worker is script itself, named `NAME_WORKER`: at address page loaded it from, else its text
##     as Blob, where page holds it inline. Worker that fails before it answers that it loaded
##     gives way to thread of page, which reads each piece sent to it, in order.
##   Thread of page reads each piece sentence by sentence (`toSentences`), one at each turn of
##     event loop, and gives one change for piece (`combine`). Turn is message of
##     `MessageChannel`, which no timer delays and no clock of check holds.
##   Rejected: reading of piece in one turn on thread of page, which holds page as long as text of
##     piece takes, about 37 times as long as native build takes (PROVENANCE.md, JavaScript build).
##   Asks answer in order of asking: worker answers messages in order, and thread of page reads
##     asks from one queue.
##   Reader loops by index, since `items` copies on JavaScript backend.

{.experimental: "strictFuncs".}
{.used.}  # bridge imports module for `parseLojbanLive` it exports to script alone

import std/[algorithm, asyncjs, jsffi, unicode]

import ../lojban_parser/[live, nif]


type
  Asked = enum  ## Define what page asks of reader.
    Push = "push", Finish = "finish", Nif = "nif"

  Ask = object  ## Define one ask that waits for its answer.
    kind: Asked
    piece: string  ## Piece of live text `push` gives; empty for other ask.
    resolve: proc(response: JsObject)  ## Resolve promise of ask with its answer.

  LinesNif = object
    ## Define end of each line of NIF held, in bytes and in units of UTF-16, from directives on.
    bytes: seq[int]
    units: seq[int]

  ReaderScript = ref object  ## Define reader page holds: worker, else reader on thread of page.
    worker: JsObject  ## Worker reading live text; nil where thread of page reads it.
    is_ready: bool  ## Worker answered that it loaded.
    sent: seq[Ask]  ## Asks sent to worker, in order, not answered yet.
    asks: seq[Ask]  ## Asks thread of page has yet to answer, in order.
    is_finished: bool  ## Page asked for end of live text.
    reader: ReaderLive  ## Reader on thread of page; reads nothing where worker reads.
    lines: LinesNif  ## Lines of NIF reader on thread of page holds.
    tail: string  ## Tail of last change on thread of page.
    sentences: seq[string]  ## Sentences of piece read now, which turns read one by one.
    changes: seq[ChangeNif]  ## Change of each sentence of piece read now.
    channel: JsObject  ## Channel whose message is turn of event loop; nil till first turn.
    is_turning: bool  ## Turn waits in event loop.
    count_turns: int  ## Turns of event loop that read on thread of page.


const NAME_WORKER = "lojban_parser live"
  ## Name worker of live text takes, by which script knows it reads for page, and not for worker
  ##   page gave script for work of its own.


let
  DOCUMENT {.nodecl, importc: "document".}: JsObject  ## Document of page; none in worker.
  SELF {.nodecl, importc: "self".}: JsObject  ## Global scope of page or of worker.
    ## Boundary of JS target: `typeof` reads each, since bare name of undeclared global throws.
  SCRIPT_LOADED = (if DOCUMENT.jsTypeOf != "undefined": DOCUMENT.currentScript else: jsNull)
    ## Element of script page loaded, which gives its address or its text, read as script loads,
    ##   since page reads it null after; null in worker.


proc newWorker(address: cstring, options: JsObject): JsObject {.importjs: "new Worker(@)".}
  ## Start worker from script at address. Boundary of JS target: constructor of page.
proc newBlobScript(text: cstring): JsObject {.importjs: "new Blob([#], {type: 'text/javascript'})".}
  ## Hold text of script as Blob, which worker loads by address. Boundary of JS target.
proc toAddress(blob: JsObject): cstring {.importjs: "URL.createObjectURL(#)".}
  ## Give address page serves Blob at. Boundary of JS target.
proc newChannel(): JsObject {.importjs: "new MessageChannel()".}
  ## Make channel of two ports, whose message is turn of event loop. Boundary of JS target.



#[ Lines ]#

func countUnits(text: string): int =
  ## Count units of UTF-16 text takes, as string of JavaScript indexes it: two for each rune past
  ##   U+FFFF, one for each other.
  for rune in text.runes: result += (if rune.int32 > 0xFFFF: 2 else: 1)


func add(lines: var LinesNif, text: string) =
  ## Add each line of NIF text holds, each ended by line end, as each node of NIF is.
  var first = 0
  for k in 0 ..< text.len:
    if text[k] != '\n': continue
    lines.bytes.add lines.bytes[^1] + k + 1 - first
    lines.units.add lines.units[^1] + text[first .. k].countUnits
    first = k + 1
  doAssert first == text.len, "NIF should end each line with line end; got `" & text & "`."


func initLinesNif(): LinesNif =
  ## Make lines of NIF that holds directives alone.
  result = LinesNif(bytes: @[0], units: @[0])
  result.add HEADER


func apply(lines: var LinesNif, change: ChangeNif): int =
  ## Cut lines back to offset of change, which opens line, add lines of its text, and give units of
  ##   UTF-16 NIF holds before offset.
  let k = lines.bytes.lowerBound(change.at)
  doAssert k < lines.bytes.len and lines.bytes[k] == change.at,
    "Change should cut NIF where line opens; got offset " & $change.at & "."
  lines.bytes.setLen(k + 1)
  lines.units.setLen(k + 1)
  result = lines.units[k]
  lines.add change.text


proc toObject(change: ChangeNif, units: int): JsObject =
  ## Mirror change as plain object, with offset of NIF in units of UTF-16.
  result = newJsObject()
  result.at = units
  result.start = change.start
  result.text = cstring(change.text)
  result.tail = cstring(change.tail)



#[ Worker ]#

var
  READER_WORKER = initReaderLive()  ## Reader in worker of live text; reads nothing on page.
  LINES_WORKER = initLinesNif()  ## Lines of NIF reader in worker holds.
  TAIL_WORKER: string  ## Tail of last change in worker.


proc answerPage(event: JsObject) =
  ## Answer one ask of page in worker: change of piece or of end, or NIF so far.
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
  ## Tell whether script runs as worker of live text that page started.
  DOCUMENT.jsTypeOf == "undefined" and SELF.jsTypeOf != "undefined" and
    SELF.name.jsTypeOf == "string" and $SELF.name.to(cstring) == NAME_WORKER



#[ Thread of page ]#

proc turn(reader: ReaderScript)


proc schedule(reader: ReaderScript) =
  ## Ask event loop for turn where thread of page has ask to answer, and no turn waits.
  if reader.is_turning or reader.asks.len == 0: return
  reader.is_turning = true
  if reader.channel.isNil:
    reader.channel = newChannel()
    reader.channel.port1.onmessage = proc(event: JsObject) = reader.turn()
  reader.channel.port2.postMessage(0)


proc turn(reader: ReaderScript) =
  ## Read on thread of page in one turn: one sentence of piece asked first, or end, or NIF so far;
  ##   answer ask once its piece is read, then ask for next turn.
  reader.is_turning = false
  inc reader.count_turns
  template ask: untyped = reader.asks[0]
    ## Alias ask answered now, which `let` would copy.
  var answer: JsObject
  case ask.kind
  of Push:
    if reader.changes.len == 0: reader.sentences = ask.piece.toSentences
    reader.changes.add reader.reader.push(reader.sentences[reader.changes.len])
    if reader.changes.len < reader.sentences.len:  # sentences left, each its own turn
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
  ## Give each ask sent to worker that failed before it loaded to thread of page, in order.
  reader.worker.terminate()
  reader.worker = nil
  reader.asks = reader.sent & reader.asks
  reader.sent.setLen(0)
  reader.schedule()


proc startWorker(reader: ReaderScript) =
  ## Start worker of live text from script page loaded, where page gives worker and script;
  ##   leave thread of page to read where it gives neither, or refuses worker.
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
    return  # page refuses worker, as rule of its content may
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
  ## Ask reader for change of piece or of end, or for NIF so far, as promise answered in order.
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
  ## Make reader of live text: in worker where page gives one, else on thread of page. Option
  ##   `worker: false` keeps reading on thread of page.
  ##   Boundary of JS target: `exportc` keeps name `parseLojbanLive` in script. Each piece arrives
  ##     as string of JavaScript, and `$` gives its UTF-8 bytes, which reader reads.
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


# Answer page as worker of live text, where page started script so; else define reader alone.
if isWorkerLive():
  SELF.onmessage = answerPage
  let ready = newJsObject()
  ready.ready = true
  SELF.postMessage(ready)
