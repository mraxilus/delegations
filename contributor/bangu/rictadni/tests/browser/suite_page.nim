## Drive built tag page in Chromium, in each mode `data-mode` of `body` names, and check what it
##   shows; `tools/page.nim drive` runs this script before script of page.
##
##   |-----------|------------------------------------------------------------------------------|
##   | Mode      | Page as run                                                                  |
##   |-----------|------------------------------------------------------------------------------|
##   | `runtime` | stub of `window.claude` gives fixed answer to `sample`; suite submits form   |
##   | `served`  | no runtime; suite adds run of child as `suggester --serve` adds it           |
##   | `server`  | no runtime, no run: page shows worked example and posts form natively        |
##   |-----------|------------------------------------------------------------------------------|
##
##   Answer of stub holds what reader must drop and keep: words around object, cmavo, repeat,
##     word of four letters and gloss holding backtick, which reading report back would miss.
##   Each wait ends on change of status, never on span of time; page that never answers ends at
##     `TIMEOUT_PAGE` of `tools/drive.nim`.

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, sequtils]

import ../../src/rictadni/suggestions
import ../../app/shown
import ./report


const
  MODE_RUNTIME = "runtime"  ## Mode with stub of runtime.
  MODE_SERVED = "served"  ## Mode with run of child of server.
  TEXT_ASKED = "The garden by the fence is big."  ## Text suite submits in mode `runtime`.
  ANSWER_STUB = "Here are the tags: {\"tags\": [" &
      "{\"gismu\": \"purdi\", \"gloss\": \"garden\"}, {\"gismu\": \"mi\", \"gloss\": \"me\"}, " &
      "{\"gismu\": \"purdi\", \"gloss\": \"garden again\"}, " &
      "{\"gismu\": \"samtc\", \"gloss\": \"four\"}, " &
      "{\"gismu\": \"barda\", \"gloss\": \"big `one`\"}]} Done."
    ## Answer stub gives: two gismu kept, three elements dropped, object wrapped in words.
  MODEL_STUB = "claude-opus-5-5"  ## Model stub names as applied.
  REPORT_SERVED = "Run refused: setting `RICTADNI_SERVICE` is unset."
    ## Report of run in mode `served`; page shows it as given.
  CODE_SERVED = 2  ## Exit of run in mode `served`: settings refused.


let
  WINDOW {.nodecl, importc: "window".}: JsObject  ## Window of page.
  DOCUMENT {.nodecl, importc: "document".}: JsObject  ## Document of page.


proc resolved(value: JsObject): JsObject {.importjs: "Promise.resolve(#)".}
  ## Give promise resolved with value.
proc statusChanged(status: JsObject, asking: cstring, observed: JsObject): Future[void] {.importjs:
    "new Promise((done) => new MutationObserver((_, observer) => { " &
    "if (#.textContent !== #) { observer.disconnect(); done(); } })" &
    ".observe(#, {childList: true, characterData: true, subtree: true}))".}
  ## Wait until status shows other text than asking; status and observed are one element.
proc toArray(iterable: JsObject): JsObject {.importjs: "Array.from(#)".}
  ## Copy iterable of browser into array.


var
  PROMPT_ASKED = ""  ## Prompt page gave `sample`.
  OPTIONS_ASKED: JsObject  ## Options page gave `sample`.


proc byId(id: string): JsObject = DOCUMENT.getElementById(cstring(id))
  ## Find element of page by id.

proc text(element: JsObject): string = $element.textContent.to(cstring)
  ## Read text of element.

proc tiles(): seq[(string, string)] =
  ## Read gismu and gloss of each tile page shows.
  for item in byId("tiles").children.toArray.to(seq[JsObject]):
    result.add (item.querySelector(cstring("b")).text, item.querySelector(cstring("span")).text)



#[ Setup ]#

proc stub() =
  ## Put stub of runtime on window: `use("sample")` gives function that keeps what page asks,
  ##   and answers `ANSWER_STUB`.
  let claude = newJsObject()
  claude.use = proc(name: cstring): JsObject =
    let sample = proc(prompt: cstring, options: JsObject): JsObject =
      PROMPT_ASKED = $prompt
      OPTIONS_ASKED = options
      let answered = newJsObject()
      answered.text = cstring(ANSWER_STUB)
      answered.modelApplied = cstring(MODEL_STUB)
      resolved(answered)
    resolved(sample.toJs)
  WINDOW.claude = claude


proc addServed() =
  ## Add run of child to main, as `suggester --serve` adds it.
  let
    report = DOCUMENT.createElement(cstring("pre"))
    output = DOCUMENT.createElement(cstring("pre"))
  report.id = cstring("served")
  report.hidden = true
  discard report.setAttribute(cstring("data-code"), cstring($CODE_SERVED))
  report.textContent = cstring(REPORT_SERVED)
  output.id = cstring("served-output")
  output.hidden = true
  discard DOCUMENT.querySelector(cstring("main")).append(report, output)



#[ Suite ]#

proc runSuite(mode: string) {.async.} =
  ## Check page in mode, then post end of run.
  report "[Suite] Tag page, mode " & mode
  var failures = countFailures()

  template ended(name: string) =
    ## Report test as failed where any check failed since last test.
    report "  [" & (if countFailures() > failures: "FAILED" else: "OK") & "] " & name
    failures = countFailures()

  case mode
  of MODE_RUNTIME:
    byId("text").value = cstring(TEXT_ASKED)
    let changed = statusChanged(byId("status"), cstring(STATUS_ASKING), byId("status"))
    discard byId("form").requestSubmit()
    await changed
    expectThat tiles() == @[("purdi", "garden"), ("barda", "big `one`")],
      "tiles are gismu reader kept, each once, gloss with backtick whole"
    expectThat byId("command").text == "tagger tag notes/text.md purdi barda",
      "command tags by each gismu kept"
    expectThat byId("status").text == "Kept 2 gismu.", "status counts tiles"
    expectThat byId("report").text == toShownAnswer(TEXT_ASKED, ANSWER_STUB, MODEL_STUB).report,
      "report is that of reader"
    expectThat byId("example").hidden.to(bool), "note of example hides"
    ended "Answer of `sample` shows each gismu reader keeps, with its gloss, and drops rest"
    expectThat PROMPT_ASKED == toPromptAlone(toPassage(TEXT_ASKED)), "prompt is that of CLI"
    expectThat $OPTIONS_ASKED.model.to(cstring) == MODEL_PAGE, "model named"
    expectThat $OPTIONS_ASKED.effort.to(cstring) == $EFFORT_PAGE, "effort named"
    expectThat $OPTIONS_ASKED.modelTier.to(cstring) == TIER_PAGE, "tier named"
    ended "Page asks `sample` once, with prompt of CLI, model, tier and effort it names"
  of MODE_SERVED:
    expectThat tiles().len == 0, "no tile, since child printed none"
    expectThat byId("command").text == "", "no command"
    expectThat byId("status").text == "Suggester refused to run, with exit 2; report says why.",
      "status names exit"
    expectThat byId("status").className.to(cstring) == "status fail", "status shows failure"
    expectThat byId("report").text == REPORT_SERVED, "report of child shown whole"
    expectThat byId("example").hidden.to(bool), "note of example hides"
    ended "Run of server that exits 2 shows its exit and report, and no gismu"
  else:
    let shown = toShownAnswer(byId("example-text").text, byId("example-answer").text,
        LUT_MODEL_BY_SERVICE[Service.Claude])
    expectThat shown.pairs.len > 0, "worked example keeps gismu"
    expectThat tiles() == shown.pairs.mapIt((it.gismu, it.gloss)), "tiles of worked example"
    expectThat $byId("text").value.to(cstring) == byId("example-text").text, "text in box"
    expectThat byId("status").text == STATUS_SERVER, "status names server"
    expectThat not byId("example").hidden.to(bool), "note of example shows"
    for (name, value) in [("model-page", MODEL_PAGE), ("effort-cli", $EFFORT_DEFAULT)]:
      expectThat DOCUMENT.querySelector(cstring("." & name)).text == value, name & " named"
    ended "Page without runtime shows worked example by same reader, and names models asked"
  reportEnd(if countFailures() > 0: 1 else: 0)


let MODE = $DOCUMENT.body.dataset.mode.to(cstring)  ## Mode of run, from `data-mode` of `body`.
initReporter()
if MODE == MODE_RUNTIME: stub()
if MODE == MODE_SERVED: addServed()
WINDOW.addEventListener(cstring("load"), proc(event: JsObject) = discard runSuite(MODE))
