## Hold reader of live text of script (`src/javascript/live_text.nim`) to native build, in headless
##   Chromium that verb `drive` starts (`tools/drive.nim`), on page that loads suite by its address,
##   as page of viewer loads script (rulings on #859). Suite holds bridge, as suite of script does,
##   since each script Nim compiles defines its procs as globals: second script on page replaces
##   procs of first that share names, so suite of its own beside script would read script broken.
##   Worker starts from suite, as from script, and suite runs where page holds document alone.
##   Each text backend serves reads word by word, in worker and on thread of page: changes, cut
##     back as string of JavaScript at `at` and added to, give at end NIF native build gives that
##     text (`readTextParts`), byte for byte, and `nif` gives NIF so far, as changes leave it.
##   Worker reads each text, and thread of page reads none of it: page never waits for reader.
##   Thread of page reads one sentence at each turn of event loop (`toSentences`), and page runs
##     task of its own between two sentences of one piece, since turn is message of channel, which
##     event loop takes in order of posting.
##   Offset of change counts units of UTF-16: text of `zoi` holding rune past U+FFFF, which two
##     units spell, reads to NIF native build gives, so `slice` cuts where change opens.
##   On page whose rule of content refuses each worker, reader that asks for worker gives way to
##     thread of page, which reads each text to NIF native build gives.
##   Suite of promises reports each test as unittest spells it (`report.nim`), since unittest
##     awaits none, then code of run.

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, strutils, unicode]

import ../../src/javascript/[bridge, live_text]
import ../../src/lojban_parser/[live, nif]
import ./report


const
  PATH_COUNT = "/drive/live/count.text"  ## Count of texts backend serves for suite.
  PIECE_MIDDLE = 7  ## Piece after which suite asks reader for NIF so far, in each text so long.
  COUNT_TEXTS_LEAST = 5  ## Texts backend serves, at least.
  TEXT_TURNS = "mi klama .i do cadzu .i ko sipna "
    ## Piece of three sentences, which thread of page reads in three turns; constructed.
  COUNT_TURNS = 3  ## Sentences of `TEXT_TURNS`, each its own turn.
  MODE_REFUSED = "refused"
    ## Mode of page whose rule of content refuses each worker, as attribute `data-mode` of body.


proc pushed(reader: JsObject, piece: cstring): Future[JsObject] {.importjs: "#.push(#)".}
  ## Give promise of change piece makes. Boundary of JS target: method of reader of script.
proc finished(reader: JsObject): Future[JsObject] {.importjs: "#.finish()".}
  ## Give promise of change end makes. Boundary of JS target: method of reader of script.
proc asked(reader: JsObject): Future[cstring] {.importjs: "#.nif()".}
  ## Give promise of NIF so far. Boundary of JS target: method of reader of script.
proc applied(held: cstring, at: int, text: cstring): cstring {.importjs: "(#.slice(0, #) + #)".}
  ## Cut NIF held back to offset in units of UTF-16, then add text, as page of viewer does.
proc typeOfGlobal(name: cstring): cstring {.importjs: "(typeof globalThis[#])".}
  ## Give type of global of page by its name. Boundary of JS target.
proc newChannel(): JsObject {.importjs: "new MessageChannel()".}
  ## Make channel of two ports, whose message is task of page. Boundary of JS target.


let DOCUMENT {.nodecl, importc: "document".}: JsObject  ## Document of page; none in worker.


type ReadingLive = object  ## Define outcome of reading text live in script.
  nif: string  ## NIF changes leave at end, cut back and added to as string of JavaScript.
  is_asked: bool  ## NIF so far, as reader gives it mid text, is NIF held and tail of change.
  turns: int  ## Turns thread of page takes for text, as `toSentences` cuts each piece.



proc piecesWords(text: string): seq[string] =
  ## Cut text before each word, each piece written word and space after it.
  var first = 0
  for k in 0 ..< text.len:
    if text[k] == ' ':
      result.add text[first .. k]
      first = k + 1
  if first < text.len: result.add text[first .. ^1]


proc readTexts(): seq[tuple[text, nif: string]] =
  ## Read each text backend serves, with NIF native build gives it.
  for k in 0 ..< readServed(PATH_COUNT).strip.parseInt:
    let path = "/drive/live/" & $k
    result.add (readServed(path & ".text"), readServed(path & ".nif"))


proc readLive(reader: JsObject, text: string): Future[ReadingLive] {.async.} =
  ## Read text word by word with reader of script, and hold NIF its changes leave.
  var
    held = cstring(HEADER)
    reading = ReadingLive(is_asked: true)
  let pieces = text.piecesWords
  for k in 0 ..< pieces.len:
    let change = await reader.pushed(cstring(pieces[k]))
    held = held.applied(change.at.to(int), change.text.to(cstring))
    reading.turns += pieces[k].toSentences.len
    if k == PIECE_MIDDLE:
      let asked = $(await reader.asked)
      reading.is_asked = asked == $held & $change.tail.to(cstring)
      inc reading.turns  # ask for NIF so far takes turn of its own
  let change = await reader.finished
  held = held.applied(change.at.to(int), change.text.to(cstring))
  reading.nif = $held
  inc reading.turns  # end takes turn of its own
  reading.is_asked = reading.is_asked and $(await reader.asked) == reading.nif
  inc reading.turns
  result = reading



proc runSuite() {.async.} =
  ## Run each test of suite in order, and report each, then code of run. Page whose rule refuses
  ##   each worker runs test of that page alone.
  report "[Suite] Internal: Live text of script" &
    (if DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED: ", worker refused" else: "")
  let texts = readTexts()
  var failures = countFailures()

  template ended(name: string) =
    ## Report test as unittest spells it: failed where check failed since last test.
    report "  [" & (if countFailures() > failures: "FAILED" else: "OK") & "] " & name
    failures = countFailures()

  if DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED:
    for (text, native) in texts:
      let
        reader = parseLojbanLive(jsUndefined)  # asks for worker, which page refuses
        live = await reader.readLive(text)
      expectThat not reader.isWorker().to(bool), "thread of page reads: " & text  # gives way
      expectThat live.nif == native, "NIF native build gives: " & text  # `live.nim`, law
      expectThat live.is_asked, "NIF so far is NIF held and tail: " & text  # D1 c of #859
    ended "Worker page refuses gives way to thread of page, which reads each text to native NIF"
    reportEnd(if countFailures() > 0: 1 else: 0)
    return

  for name in ["parseLojban", "parseLojbanToNif", "parseLojbanLive"]:
    expectThat typeOfGlobal(cstring(name)) == "function", name & " is global of page"  # bridge
  ended "Script defines its three functions as globals of page that loads it"

  expectThat texts.len >= COUNT_TEXTS_LEAST, "backend serves " & $COUNT_TEXTS_LEAST & " texts"
  var is_wide = false  # some text holds rune past U+FFFF, which two units of UTF-16 spell
  for (text, native) in texts:
    for rune in text.runes: is_wide = is_wide or int32(rune) > 0xFFFF
    let
      reader = parseLojbanLive(jsUndefined)
      live = await reader.readLive(text)
    expectThat reader.isWorker().to(bool), "worker reads: " & text  # ruling on #859
    expectThat live.nif == native, "NIF native build gives: " & text  # `live.nim`, law
    expectThat live.is_asked, "NIF so far is NIF held and tail: " & text  # D1 c of #859
    expectThat reader.countRead().to(int) == 0, "page reads none: " & text  # ruling on #859
  ended "Worker reads each text to NIF native build gives, and thread of page reads none"

  for (text, native) in texts:
    let options = newJsObject()
    options.worker = false
    let
      reader = parseLojbanLive(options)
      live = await reader.readLive(text)
    expectThat not reader.isWorker().to(bool), "thread of page reads: " & text
    expectThat live.nif == native, "NIF native build gives: " & text  # `live.nim`, law
    expectThat live.is_asked, "NIF so far is NIF held and tail: " & text  # D1 c of #859
    expectThat reader.countTurns().to(int) == live.turns,  # `toSentences`, ruling on #859
      "turn for each sentence, end and ask: " & text
  ended "Thread of page reads each text, one sentence at each turn, to NIF native build gives"

  block:
    let options = newJsObject()
    options.worker = false
    let
      reader = parseLojbanLive(options)
      reading = reader.pushed(cstring(TEXT_TURNS))
      channel = newChannel()
    var is_run = false
    channel.port1.onmessage = proc(event: JsObject) = is_run = true
    channel.port2.postMessage(0)  # task of page, posted after first turn of reader
    discard await reading
    expectThat is_run, "task of page runs before piece of three sentences is read"  # ruling
    expectThat reader.countTurns().to(int) == COUNT_TURNS, "turn for each sentence"
  ended "Page runs task of its own between two sentences that thread of page reads"

  expectThat is_wide, "some text holds rune past U+FFFF"  # IX.3, guard keeps wide text
  ended "Offset of change counts units of UTF-16, so slice cuts NIF where change opens"

  reportEnd(if countFailures() > 0: 1 else: 0)


# Run suite in page; in worker, which starts from this script, answer page alone (`live_text.nim`).
if DOCUMENT.jsTypeOf != "undefined":
  initReporter()
  discard runSuite()
