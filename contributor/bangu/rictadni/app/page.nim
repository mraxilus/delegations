## Run tag page, compiled to JavaScript: ask `sample` of Artifact runtime, or let form post to
##   `suggester --serve`, and show what `shown.nim` reads (II.9: page holds no script but this).
##   One source serves both front ends: prompt is `toPromptAlone`, and reader `readAnswer`, as
##     `suggester` builds and reads them.
##     Cost: page carries gismu list twice, in prompt and in reader; size read in PROVENANCE.md.
##   Without runtime, form posts natively, and served page holds run of child in hidden elements
##     `served`, `served-output` and attribute `data-code`; page shows that run.
##   Elsewhere page shows worked example that build put in `example-text` and `example-answer`,
##     read by same reader as live answer.
##   Each promise of runtime settles into object `{ok, value, error}`, so no exception of browser
##     crosses into Nim.
##
##   |-----------|------------------------------------------------------------------------------|
##   | Routine   | Effect                                                                       |
##   |-----------|------------------------------------------------------------------------------|
##   | `show`    | render tiles, command and report of what page shows, and status             |
##   | `suggest` | ask `sample` once for text in box, and show its answer                       |
##   | `copy`    | copy command of `tagger`, or select it where clipboard is refused            |
##   |-----------|------------------------------------------------------------------------------|

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[asyncjs, jsffi, strutils]

import ../src/rictadni/suggestions
import ./shown


let
  WINDOW {.nodecl, importc: "window".}: JsObject  ## Window of page.
  DOCUMENT {.nodecl, importc: "document".}: JsObject  ## Document of page.


proc settled(promise: JsObject): Future[JsObject] {.importjs:
    "#.then((v) => ({ok: true, value: v}), (e) => ({ok: false, error: e}))".}
  ## Settle promise into object that never rejects.
proc clipped(text: cstring): JsObject {.importjs:
    "(navigator.clipboard ? navigator.clipboard.writeText(#) : Promise.reject(null))".}
  ## Write text to clipboard; promise rejected where clipboard is absent.
proc called(function: JsObject, prompt: cstring, options: JsObject): JsObject {.importjs:
    "#(#, #)".}
  ## Call function of runtime with prompt and options.
proc toArray(iterable: JsObject): JsObject {.importjs: "Array.from(#)".}
  ## Copy iterable of browser into array.
proc isTruthy(value: JsObject): bool {.importjs: "(!!#)".}
  ## Test value is neither absent nor false.
proc toText(value: JsObject): string = (if value.isTruthy: $value.to(cstring) else: "")
  ## Read string of browser, empty where absent.


proc byId(id: string): JsObject = DOCUMENT.getElementById(cstring(id))
  ## Find element of page by id.



#[ Rendering ]#

proc setStatus(text: string, is_fail: bool) =
  ## Show status under button, as failure or not.
  byId("status").textContent = cstring(text)
  byId("status").className = cstring(if is_fail: "status fail" else: "status")


proc show(shown: Shown) =
  ## Render tiles of each pair, command of `tagger`, report and status.
  let tiles = byId("tiles")
  discard tiles.replaceChildren()
  for pair in shown.pairs:
    let
      item = DOCUMENT.createElement(cstring("li"))
      word = DOCUMENT.createElement(cstring("b"))
      note = DOCUMENT.createElement(cstring("span"))
    item.className = cstring("tile")
    word.textContent = cstring(pair.gismu)
    note.textContent = cstring(pair.gloss)
    discard item.append(word, note)
    discard tiles.append(item)
  byId("command").textContent = cstring(shown.pairs.toCommand)
  byId("report").textContent = cstring(shown.report)
  setStatus(shown.status, shown.is_fail)



#[ Actions ]#

proc suggest(event: JsObject) {.async.} =
  ## Ask `sample` once for text in box, then show what reader keeps of answer.
  ##   Without runtime, form posts to server of `suggester --serve` instead.
  if not WINDOW.claude.isTruthy: return
  discard event.preventDefault()
  let text = $byId("text").value.to(cstring)
  if text.strip.len == 0:
    setStatus(STATUS_BLANK, true)
    return
  let used =
    if WINDOW.claude.use.isTruthy: await WINDOW.claude.use(cstring("sample")).settled
    else: JsObject(nil)
  if used.isNil or not used.ok.to(bool) or not used.value.isTruthy:
    setStatus(STATUS_NO_RUNTIME, true)
    return
  byId("suggest").disabled = true
  setStatus(STATUS_ASKING, false)
  let
    options = newJsObject()
  options.model = cstring(MODEL_PAGE)
  options.modelTier = cstring(TIER_PAGE)
  options.effort = cstring($EFFORT_PAGE)
  let answered = await used.value.called(cstring(toPromptAlone(toPassage(text))), options).settled
  byId("suggest").disabled = false
  if answered.ok.to(bool):
    show(toShownAnswer(text, answered.value.text.toText, answered.value.modelApplied.toText))
    byId("example").hidden = true
    return
  let
    error = answered.error
    code = if error.isTruthy: error.code.toText else: ""
    message = if error.isTruthy and error.message.isTruthy: error.message.toText else: "none"
  case code
  of "not_granted": setStatus(STATUS_REFUSED, true)
  of "rate_limited": setStatus(STATUS_LIMITED, true)
  else: setStatus("Claude gave no answer: " & message, true)


proc copy() {.async.} =
  ## Copy command of `tagger`, or select it for keyboard where clipboard is refused.
  let copied = await clipped(byId("command").textContent.to(cstring)).settled
  if copied.ok.to(bool):
    byId("copied").textContent = cstring("Copied.")
    return
  let
    range = DOCUMENT.createRange()
    selection = WINDOW.getSelection()
  discard range.selectNodeContents(byId("command"))
  discard selection.removeAllRanges()
  discard selection.addRange(range)
  byId("copied").textContent = cstring("Selected. Copy it with your keyboard.")



#[ Load ]#

proc load() =
  ## Name models asked, then show run server put in page, else worked example; then wire form.
  for (id, text) in [("model-page", MODEL_PAGE), ("effort-page", $EFFORT_PAGE),
      ("model-cli", LUT_MODEL_BY_SERVICE[Service.Claude]), ("effort-cli", $EFFORT_DEFAULT)]:
    for element in DOCUMENT.querySelectorAll(cstring("." & id)).toArray.to(seq[JsObject]):
      element.textContent = cstring(text)
  let served = byId("served")
  if served.isTruthy:
    var code = 2  # Exit of run refused, where attribute reads as no number.
    try: code = parseInt(served.getAttribute(cstring("data-code")).toText)
    except ValueError: discard
    show(toShownServed(byId("served-output").textContent.toText, served.textContent.toText, code))
    byId("example").hidden = true
  else:
    let text = byId("example-text").textContent.toText
    byId("text").value = cstring(text)
    show(toShownAnswer(text, byId("example-answer").textContent.toText,
        LUT_MODEL_BY_SERVICE[Service.Claude]))
    if not WINDOW.claude.isTruthy: setStatus(STATUS_SERVER, false)
    else: setStatus(STATUS_RUNTIME, false)
  discard byId("form").addEventListener(cstring("submit"),
      proc(event: JsObject) = discard suggest(event))
  discard byId("copy").addEventListener(cstring("click"), proc(event: JsObject) = discard copy())


load()
