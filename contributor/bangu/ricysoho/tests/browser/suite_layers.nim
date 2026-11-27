## cipra le papri poi skari lo valsi gi'e pixra lo linji ne'i `Chromium` to `text_layers.nim` toi
##   .i le sabji samtci cu dunda ro se cipra .e lo valsi .e lo linji poi le jbezba cu gunma ke'a
##       to `writeCasesLayers` pe `tools/browser.nim` toi
##   .i le papri cu pixra lo valsi .e lo linji poi mintu
##   .i le stuzi be lo nu ciska cu vasru le selci'a po'o
##   .i ro valsi cu skari ja'i le girzu be ke'a
##   .i ro linji cu zvati ro valsi pe vo'a
##   .i lo nu ciska cu stali le selci'a .e le cuxna

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, options, strutils]

import ../../src/browser/text_layers
import ./report


const
  DIRECTORY_CASES = "/drive/layers/"  ## lo vasru be lo se cipra poi le sabji samtci cu sabji ke'a
  COUNT_CASES_LEAST = 8  ## lo du'u le sabji samtci cu sabji su'o xo kau se cipra
  MODE_REFUSED = "refused"
    ## lo tadji be lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka
  TYPED = "mi klama le zarci .i do"  ## le selci'a poi le cipra cu ciska ke'a ta'i pa lerfu
  WAIT_MOST = 400  ## lo klani be lo nu le cipra cu denpa pa se tcidu ta'i pa pixra
  CLASS_GROUP = ["g-pred", "g-sumti", "g-num", "g-tag", "g-link", "g-free", "g-struct", "g-bad"]
    ## lo klesi pe `CSS` pe ro girzu be lo valsi to `text_layers.nim` toi


let DOCUMENT {.nodecl, importc: "document".}: JsObject


proc queryAll(selector: cstring): seq[JsObject]
    {.importjs: "Array.from(document.querySelectorAll(#))".}
  ## dunda ro dacti poi mapti `selector`
proc nextFrame(): Future[void] {.importjs:
  "new Promise(function(resolve) { requestAnimationFrame(function() { resolve(); }); })".}
  ## dunda pa nupre be le bavla'i nu pixra
proc typedIn(editor: JsObject, text: cstring) {.importjs:
  "#.dispatchEvent(new InputEvent('beforeinput', " &
  "{ inputType: 'insertText', data: #, bubbles: true, cancelable: true }))".}
  ## rinka pa nu ciska pa lerfu ta'i lo nu fasnu poi lo jbobatke cu rinka ke'a
proc erased(editor: JsObject) {.importjs:
  "#.dispatchEvent(new InputEvent('beforeinput', " &
  "{ inputType: 'deleteContentBackward', bubbles: true, cancelable: true }))".}
  ## rinka pa nu vimcu pa lerfu poi lidne le cuxna
proc focused(node: JsObject) {.importjs: "#.focus()".}
  ## punji le cuxna ne'i le dacti


proc described(model: Model): string =
  ## ciska ro valsi .e ro linji pe le se tcidu ta'i lo linji poi le sabji samtci cu ciska ke'a
  for word in model.words:
    result.add "w " & $word.s & " " & $word.e & " " & $word.group & " " & $word.gloss & "\n"
  for bar in model.bars:
    result.add "b " & $bar.category & " " & $bar.first & " " & $bar.last & " " & $bar.parent &
        " " & $bar.height & "\n"


proc shownText(): string =
  ## le selci'a poi le stuzi be lo nu ciska cu jarco ke'a
  for host in queryAll("#editor [data-s]"):
    if host.tagName.to(cstring) == "BR": result.add "\n"
    else: result.add $host.textContent.to(cstring)


proc settled() {.async.} =
  ## denpa lo nu le papri cu pixra lo se tcidu pe le ca selci'a
  for k in 0 ..< WAIT_MOST:
    if not isAsking() and not current().is_moved: return
    await nextFrame()


proc runSuite() {.async.} =
  ## cipra le papri ne'i `Chromium`
  let is_refused = DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED
  report "[Suite] Internal: Page of text layers" & (if is_refused: ", worker refused" else: "")
  var failures = countFailures()

  template ended(name: string) =
    report "  [" & (if countFailures() > failures: "FAILED" else: "OK") & "] " & name
    failures = countFailures()

  wiredPage()
  if not is_refused: started(scriptText())
  let count = readServed(DIRECTORY_CASES & "count.text").strip.parseInt
  expectThat count >= COUNT_CASES_LEAST, "backend serves " & $COUNT_CASES_LEAST & " cases"
  for k in 0 ..< count:
    let
      text = readServed(DIRECTORY_CASES & $k & ".text")
      expected = readServed(DIRECTORY_CASES & $k & ".layers")
      model = cstring(text).toModel
    expectThat model.described == expected, "page folds as native build: " & text
    drawn(model, none((int, int, bool)))
    await nextFrame()
    expectThat shownText() == text, "box holds text alone: " & text
    for i, word in model.words:
      let
        node = DOCUMENT.querySelector(cstring("#editor [data-w=\"" & $i & "\"]"))
        is_classed = not node.isNull and
            node.classList.contains(cstring(CLASS_GROUP[word.group])).to(bool)
      expectThat is_classed, "word " & $i & " takes class of its group: " & text
    for b, bar in model.bars:
      for i in bar.first .. bar.last:
        let piece = DOCUMENT.querySelector(cstring("#editor .tk:has([data-w=\"" & $i &
            "\"]) [data-b=\"" & $b & "\"]"))
        expectThat not piece.isNull, "bar " & $b & " reaches word " & $i & ": " & text
  ended "Page folds each case as native build does, and draws each bar under each word of it"

  for k in 0 ..< count:
    let text = readServed(DIRECTORY_CASES & $k & ".text")
    drawn(cstring(text).toModel, none((int, int, bool)))
    let units = cstring(text).len
    for offset in 0 .. units:
      let (node, at) = toPoint(offset)
      expectThat toOffset(node, at) == offset, "offset " & $offset & " maps back: " & text
  ended "Each offset of text maps to place of page, and back to itself"

  let editor = DOCUMENT.getElementById("editor")
  drawn(cstring("").toModel, none((int, int, bool)))
  editor.focused
  selected(0, 0)
  var written = ""
  for letter in TYPED:
    editor.typedIn(cstring($letter))
    written.add letter
    expectThat shownText() == written, "box holds what was typed: " & written
    let chosen = selectionOffsets()
    expectThat chosen.isSome and chosen.get[0] == written.len and chosen.get[1] == written.len,
        "caret stands after what was typed: " & written
  await settled()
  expectThat $current().text == TYPED, "page reads text typed"
  expectThat not current().is_moved, "page draws its own reading of text typed"
  expectThat current().bars.len > 0, "text typed takes bars"
  editor.erased
  expectThat shownText() == TYPED[0 ..< ^1], "erase removes letter before caret"
  ended "Typing and erasing keep text and caret, and page reads what was typed"

  for (id, class_name) in [("show-gloss", "no-gloss"), ("show-bars", "no-bars")]:
    let toggle = DOCUMENT.getElementById(cstring(id))
    expectThat toggle.checked.to(bool), "switch is on at first: " & id
    discard toggle.click()
    expectThat editor.classList.contains(cstring(class_name)).to(bool), "switch off hides: " & id
    discard toggle.click()
    expectThat not editor.classList.contains(cstring(class_name)).to(bool), "switch on shows: " & id
  ended "Each switch is on at first, and hides its layer when off"
  reportEnd(if countFailures() > 0: 1 else: 0)


# le cipra cu fasnu ne'i le papri
#   .i le gunka noi selkra le vi samtci cu spuda le papri po'o to `text_layers.nim` toi
if DOCUMENT.jsTypeOf != "undefined":
  initReporter()
  discard runSuite()
