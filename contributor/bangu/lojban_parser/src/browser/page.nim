## Wire page of live text (`pages/live.html`) under JavaScript: field gives live text to reader
##   of `parseLojbanLive`, which reads in worker where page gives one, and page applies each
##   change to NIF it holds, then draws NIF so far (`draw.nim`).
##
##   |------------|-------------------------------------------------------------------------|
##   | Code       | Meaning                                                                 |
##   |------------|-------------------------------------------------------------------------|
##   | typed      | give field text it holds: end it gained to same reader, else to new one |
##   | readWhole  | read text with new reader, and end it, as sample does                   |
##   | streamed   | read text with new reader, one word at each piece, and end it           |
##   | mergeShown | draw each tree completed parts merge to, error in place, with its line  |
##   |------------|-------------------------------------------------------------------------|
##
##   Script is whole parser, as bridge exposes it, so worker it starts from its own text reads
##     there; in worker, no document stands, and nothing of page is wired.
##   Page holds NIF so far as string of JavaScript: cuts it back to `at` of change, adds `text`,
##     and draws `tail` as parts still open, which next change replaces (D1 c on #859).
##   Text that only gains at its end goes to same reader, as live text arrives; other edit
##     starts new reader with whole text. Sample, stream and first text end reader, so their
##     parts close; text typed stays open, as live text does.
##   Each answer of reader carries generation of reader it came from; answer of reader page
##     dropped draws nothing.
##   Drawing waits for next frame, so several changes of one frame draw once, and each awaits
##     that one drawing; `typed`, `readWhole` and `streamed` give promise that resolves once their
##     last change draws, which suite of page waits on (`tests/browser/suite_page.nim`), so no
##     check waits on time.
##   Page holds drawing of its first text already, which build draws natively (verb `page`), so
##     page reads complete before script runs.
##   Pause between words of stream is timer of page; suite of page streams with no pause.
##   Merge joins each part of NIF so far, tail left out, into tree of one pass, or into tree of
##     each run of parts around error that stays (`drawnMerged` of `draw.nim`), and draws them
##     under parts. It runs on thread of page, since it reads NIF page holds. Each change hides
##     trees merged, which no longer hold.
##   Suite of page wires controls as page does (`wiredControls`), and clicks them, so it holds
##     what button of page does.

{.experimental: "strictFuncs".}

import std/[asyncjs, dom, jsffi]

import ../javascript/[bridge, live_text]
import ../lojban_parser/nif
import ./draw


const
  LENGTH_MOST* = 2000
    ## Characters field holds at most; twin of `maxlength` of field (`pages/live.html`).
  PAUSE_STREAM = 140  ## Milliseconds between words of stream.


type StatePage = object  ## Define what page holds of live text it reads.
  reader: JsObject  ## Reader of live text; nil before first text.
  generation: int  ## Count of readers page started; answer of earlier reader draws nothing.
  sent: cstring  ## Text page gave reader so far.
  is_ended: bool  ## Reader took its end, so takes no piece more.
  nif: cstring  ## NIF so far, from directives on.
  tail: cstring  ## NIF of each part still open.
  at_last: int  ## Offset of last change in NIF, in units of UTF-16.
  is_waiting: bool  ## Drawing waits for next frame.


var
  STATE = StatePage(nif: cstring(HEADER), tail: "")  ## What page holds.
  DRAWING: Future[void]  ## Drawing that waits for next frame, which each change of frame awaits.


let DOCUMENT_PAGE {.nodecl, importc: "(typeof document === 'undefined' ? null : document)".}:
    JsObject
  ## Document of page; null in worker, where no page is wired.


proc pushLive(reader: JsObject, piece: cstring): Future[JsObject] {.importjs: "#.push(#)".}
  ## Give piece to reader of live text. Boundary of JS target: method of reader.
proc finishLive(reader: JsObject): Future[JsObject] {.importjs: "#.finish()".}
  ## End live text of reader. Boundary of JS target: method of reader.
proc isWorkerLive(reader: JsObject): bool {.importjs: "#.isWorker()".}
  ## Decide whether reader reads in worker. Boundary of JS target: method of reader.
proc cut(text: cstring, at: int): cstring {.importjs: "#.slice(0, #)".}
  ## Give text before unit `at` of UTF-16. Boundary of JS target: `slice` of string.
proc after(text: cstring, at: int): cstring {.importjs: "#.slice(#)".}
  ## Give text from unit `at` of UTF-16 on. Boundary of JS target: `slice` of string.
proc isOpening(text, opening: cstring): bool {.importjs: "#.startsWith(#)".}
  ## Decide whether text opens with `opening`. Boundary of JS target: `startsWith` of string.
proc lengthUnits(text: cstring): int {.importjs: "#.length".}
  ## Count units of UTF-16 of text. Boundary of JS target: `length` of string.
proc pieces(text: cstring): seq[cstring] {.importjs: "(#.match(/\\s*\\S+/g) || [])".}
  ## Split text into words, each with whitespace before it. Boundary of JS target: regex.
proc nextFrame(): Future[void] {.importjs:
  "new Promise(function(resolve) { requestAnimationFrame(function() { resolve(); }); })".}
  ## Give promise of next frame of page. Boundary of JS target: `requestAnimationFrame`.
proc paused(milliseconds: int): Future[void] {.importjs:
  "new Promise(function(resolve) { setTimeout(resolve, #); })".}
  ## Give promise of timer of page; stream alone waits on it. Boundary of JS target.



#[ Drawing ]#

proc mergeHidden() =
  ## Hide tree merged, since change makes it stale.
  document.getElementById("merged").setAttribute("hidden", "")


proc mergeShown() =
  ## Merge each part NIF so far holds, tail left out, and draw each tree it gives under parts;
  ##   where NIF reads not, line names node and reason.
  let drawing = drawnMerged($STATE.nif)
  document.getElementById("merged-parts").innerHTML = cstring(drawing.html)
  let line = document.getElementById("merged-status")
  line.textContent = cstring(drawing.status)
  line.className = cstring(if drawing.is_refused: "status err" else: "status")
  document.getElementById("merged").removeAttribute("hidden")


proc shown() =
  ## Draw NIF so far into page, with line of status, mode of reader, and NIF itself, change
  ##   marked and parts still open apart.
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
  ## Draw at next frame, then let next change ask for frame of its own.
  await nextFrame()
  STATE.is_waiting = false
  shown()


proc drawSoon(): Future[void] =
  ## Give promise of drawing at next frame: one for each change that comes in this frame, so
  ##   each caller waits for same drawing.
  if not STATE.is_waiting:
    STATE.is_waiting = true
    DRAWING = drawnAtFrame()
  DRAWING



#[ Reading ]#

proc started() =
  ## Start new reader, and drop NIF of reader before it.
  inc STATE.generation
  STATE.reader = parseLojbanLive(jsUndefined)
  STATE.sent = ""
  STATE.is_ended = false
  STATE.nif = cstring(HEADER)
  STATE.tail = ""
  STATE.at_last = cstring(HEADER).lengthUnits
  mergeHidden()


proc applied(change: JsObject, generation: int): bool =
  ## Apply change of reader to NIF page holds; false where reader is one page dropped.
  if generation != STATE.generation: return false
  let at = change.at.to(int)
  STATE.nif = STATE.nif.cut(at) & change.text.to(cstring)
  STATE.tail = change.tail.to(cstring)
  STATE.at_last = at
  mergeHidden()
  true


proc given(piece: cstring): Future[void] {.async.} =
  ## Give piece to reader, apply its change, and draw at next frame.
  let generation = STATE.generation
  STATE.sent = STATE.sent & piece
  let change = await STATE.reader.pushLive(piece)
  if change.applied(generation): await drawSoon()


proc ended(): Future[void] {.async.} =
  ## End live text of reader, apply change end gives, and draw at next frame.
  let generation = STATE.generation
  STATE.is_ended = true
  let change = await STATE.reader.finishLive
  if change.applied(generation): await drawSoon()


proc typed*(text: cstring): Future[void] {.async.} =
  ## Give text field holds: end it gained to same reader, else whole text to new reader.
  if STATE.reader.isNil or STATE.is_ended or not text.isOpening(STATE.sent):
    started()
    if text.lengthUnits > 0: await given(text)
    else: await drawSoon()
    return
  let piece = text.after(STATE.sent.lengthUnits)
  if piece.lengthUnits > 0: await given(piece)


proc readWhole*(text: cstring): Future[void] {.async.} =
  ## Read text with new reader, and end it, as sample and first text do.
  started()
  if text.lengthUnits > 0: discard given(text)
  await ended()


proc streamed*(text: cstring, pause: int): Future[void] {.async.} =
  ## Read text with new reader, one word at each piece, `pause` milliseconds apart, and end it;
  ##   edit that starts other reader stops stream.
  started()
  let generation = STATE.generation
  for piece in text.pieces:
    if generation != STATE.generation: return
    await given(piece)
    if pause > 0: await paused(pause)
  if generation == STATE.generation: await ended()



#[ Events ]#

proc field(): TextAreaElement =
  ## Give field of text.
  TextAreaElement(document.getElementById("source"))


proc chosen(sample: cstring): proc(event: Event) =
  ## Give handler that puts sample in field and reads it whole; parameter holds sample of each
  ##   button, where closure of loop would hold last one alone.
  result = proc(event: Event) =
    field().value = sample
    discard readWhole(sample)


proc wiredControls*() =
  ## Wire field, samples, stream and merge to what page does with each.
  field().addEventListener("input", proc(event: Event) = discard typed(field().value))
  for button in document.querySelectorAll("[data-sample]"):
    button.addEventListener("click", chosen(button.getAttribute("data-sample")))
  document.getElementById("stream").addEventListener("click", proc(event: Event) =
    discard streamed(field().value, PAUSE_STREAM))
  document.getElementById("merge").addEventListener("click", proc(event: Event) = mergeShown())


proc wired() =
  ## Wire controls, then read text page opens with, which build drew.
  wiredControls()
  discard readWhole(field().value)


if not DOCUMENT_PAGE.isNull and not defined(testing): wired()
