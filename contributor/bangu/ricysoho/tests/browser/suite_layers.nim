## cipra le papri poi skari lo valsi gi'e pixra lo linji ne'i `Chromium` to `text_layers.nim` toi
##   .i le sabji samtci cu dunda ro se cipra .e lo valsi .e lo linji poi le jbezba cu gunma ke'a
##       to `writeCasesLayers` pe `tools/browser.nim` toi
##   .i le papri cu pixra lo valsi .e lo linji poi mintu
##   .i le stuzi be lo nu ciska cu vasru le selci'a po'o
##   .i ro valsi cu skari ja'i le girzu be ke'a
##   .i ro linji cu zvati ro valsi pe vo'a
##   .i lo nu ciska cu stali le selci'a .e le cuxna
##   .i pa gunka .a le papri cu tcidu le selci'a
##   .i ro valsi .e ro linji cu drani ba ro nu cenba poi selzba
##   .i pa se tcidu pe pa pu selci'a cu na basti le se tcidu pe pa mupli
##   .i le papri cu tcidu le selci'a ba lo nu basti

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, options, random, strutils]

import ../../src/browser/text_layers
import ./report


const
  DIRECTORY_CASES = "/drive/layers/"  ## lo vasru be lo se cipra poi le sabji samtci cu sabji ke'a
  COUNT_CASES_LEAST = 8  ## lo du'u le sabji samtci cu sabji su'o xo kau se cipra
  MODE_REFUSED = "refused"
    ## lo tadji be lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka
  TYPED = "mi klama le zarci .i do"  ## le selci'a poi le cipra cu ciska ke'a ta'i pa lerfu
  PASTED = " cadzu"  ## le selci'a poi le cipra cu punji ke'a
  WAIT_MOST = 600  ## lo klani be lo nu le cipra cu denpa pa se tcidu ta'i pa pixra
  CLASS_GROUP = ["g-pred", "g-sumti", "g-num", "g-tag", "g-link", "g-free", "g-struct", "g-bad"]
    ## lo klesi pe `CSS` pe ro girzu be lo valsi to `text_layers.nim` toi
  SEED = 1055  ## lo tsiju be lo nu cenba poi selzba
  COUNT_EDITS = 60  ## lo klani be lo nu cenba poi selzba ku'o pe ro se cipra
  LETTERS = ["a", " ", "'", ".", "\n", "mi", "😀"]
    ## lo pagbu be lo selci'a poi lo nu cenba cu punji ke'a
    ##   .i pa pagbu cu vasru pa lerfu poi zmadu `U+FFFF`


let DOCUMENT {.nodecl, importc: "document".}: JsObject


proc queryAll(selector: cstring): seq[JsObject]
    {.importjs: "Array.from(document.querySelectorAll(#))".}
  ## dunda ro dacti poi mapti `selector`
proc nextFrame(): Future[void] {.importjs:
  "new Promise(function(resolve) { requestAnimationFrame(function() { resolve(); }); })".}
  ## dunda pa nupre be le bavla'i nu pixra
proc inputted(editor: JsObject, kind, text: cstring) {.importjs:
  "#.dispatchEvent(new InputEvent('beforeinput', " &
  "{ inputType: #, data: #, bubbles: true, cancelable: true }))".}
  ## rinka pa nu ciska ta'i lo nu fasnu poi lo jbobatke cu rinka ke'a
proc pasted(editor: JsObject, text: cstring) {.importjs:
  "(function(e, t) { var d = new DataTransfer(); d.setData('text/plain', t); " &
  "e.dispatchEvent(new InputEvent('beforeinput', { inputType: 'insertFromPaste', " &
  "dataTransfer: d, bubbles: true, cancelable: true })); })(#, #)".}
  ## rinka pa nu punji lo selci'a
proc fired(editor: JsObject, kind: cstring) {.importjs:
  "#.dispatchEvent(new CompositionEvent(#, { bubbles: true }))".}
  ## rinka pa nu cfari ja fanmo lo nu basti
proc focused(node: JsObject) {.importjs: "#.focus()".}
  ## punji le cuxna ne'i le dacti
proc slice(text: cstring, a, b: int): cstring {.importjs: "#.slice(#, #)".}
  ## le pagbu be le selci'a poi zvati `a` bi'o `b`


proc described(model: Model): string =
  ## ciska ro valsi .e ro linji pe le se tcidu ta'i lo linji poi le sabji samtci cu ciska ke'a
  for word in model.words:
    result.add "w " & $word.s & " " & $word.e & " " & $word.group & " " & $word.gloss & "\n"
  for bar in model.bars:
    result.add "b " & $bar.category & " " & $bar.first & " " & $bar.last & " " & $bar.parent &
        " " & $bar.height & "\n"


proc shownText(node: JsObject): string =
  ## ro selci'a .e ro linji fanmo ne'i `node` ta'i le porsi
  ##   .i lo selma'o .e lo linji cu se ciska fi `CSS` po'o gi'e na selci'a
  if node.nodeType.to(int) == 3: return $node.data.to(cstring)
  if node.nodeType.to(int) != 1: return ""
  if node.tagName.to(cstring) == "BR":
    return if node.classList.contains(cstring("ph")).to(bool): "" else: "\n"
  for kid in node.childNodes.to(seq[JsObject]): result.add kid.shownText


proc settled() {.async.} =
  ## denpa lo nu le papri cu pixra lo se tcidu pe le ca selci'a
  for k in 0 ..< WAIT_MOST:
    if not isAsking() and not current().is_moved: return
    await nextFrame()


proc isSound(model: Model): bool =
  ## jdice lo du'u ro valsi .e ro linji pe le se tcidu cu drani
  ##   .i ro valsi cu vasru su'o pa lerfu gi'e lidne le bavla'i valsi gi'e mintu le pagbu be le
  ##       selci'a
  ##   .i ro linji cu vasru su'o pa valsi
  ##   .i le mamta be ro linji cu lidne ri
  var after = 0
  for word in model.words:
    if word.s >= word.e or word.s < after or word.e > model.text.len: return false
    if word.text != model.text.slice(word.s, word.e): return false
    after = word.e
  for k, bar in model.bars:
    if bar.first > bar.last or bar.last >= model.words.len or bar.parent >= k: return false
  true


proc runSuite() {.async.} =
  ## cipra le papri ne'i `Chromium`
  let is_refused = DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED
  report "[Suite] Internal: Page of text layers" & (if is_refused: ", worker refused" else: "")
  var failures = countFailures()

  template ended(name: string) =
    report "  [" & (if countFailures() > failures: "FAILED" else: "OK") & "] " & name
    failures = countFailures()

  wiredPage()
  started(scriptText())
  let
    editor = DOCUMENT.getElementById("editor")
    count = readServed(DIRECTORY_CASES & "count.text").strip.parseInt
  var texts, expectations: seq[string]
  for k in 0 ..< count:
    texts.add readServed(DIRECTORY_CASES & $k & ".text")
    expectations.add readServed(DIRECTORY_CASES & $k & ".layers")
  expectThat count >= COUNT_CASES_LEAST, "backend serves " & $COUNT_CASES_LEAST & " cases"
  for k, text in texts:
    let model = cstring(text).toModel
    expectThat model.described == expectations[k], "page folds as native build: " & text
    drawn(model, none((int, int, bool)))
    await nextFrame()
    expectThat editor.shownText == text, "box holds text alone: " & text
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

  for text in texts:
    drawn(cstring(text).toModel, none((int, int, bool)))
    for offset in 0 .. cstring(text).len:
      let (node, at) = toPoint(offset)
      expectThat toOffset(node, at) == offset, "offset " & $offset & " maps back: " & text
  ended "Each offset of text maps to place of page, and back to itself"

  var random_edits = initRand(SEED)
  for text in texts:
    let model = cstring(text).toModel
    for k in 0 ..< COUNT_EDITS:
      let
        source = cstring(text)
        a = random_edits.rand(source.len)
        b = a + random_edits.rand(source.len - a)
        inserted = cstring(random_edits.sample(LETTERS))
        goal = source.slice(0, a) & inserted & source.slice(b, source.len)
        (low, high, put) = diff(source, goal)
      expectThat source.slice(0, low) & put & source.slice(high, source.len) == goal,
          "diff rebuilds text it reaches: " & $goal
      expectThat model.shifted(low, high, put, goal).isSound,
          "edit keeps words and bars sound: " & $goal
  ended "Each edit keeps each word on its letters and each bar on its words"

  drawn(cstring("").toModel, none((int, int, bool)))
  editor.focused
  selected(0, 0)
  var written = ""
  for letter in TYPED:
    editor.inputted("insertText", cstring($letter))
    written.add letter
    expectThat editor.shownText == written, "box holds what was typed: " & written
    let chosen = selectionOffsets()
    expectThat chosen.isSome and chosen.get[0] == written.len and chosen.get[1] == written.len,
        "caret stands after what was typed: " & written
  await settled()
  expectThat $current().text == TYPED, "page reads text typed"
  expectThat not current().is_moved, "page draws its own reading of text typed"
  expectThat current().bars.len > 0, "text typed takes bars"
  if is_refused:
    expectThat not isWorking() and answersTaken() == 0, "page reads where it refuses worker"
  else:
    expectThat isWorking() and answersTaken() > 0, "worker reads what was typed"
  editor.inputted("deleteContentBackward", "")
  expectThat editor.shownText == TYPED[0 ..< ^1], "erase removes letter before caret"
  editor.pasted(PASTED)
  expectThat editor.shownText == TYPED[0 ..< ^1] & PASTED, "paste puts its text at caret"
  editor.inputted("historyUndo", "")
  expectThat editor.shownText == TYPED[0 ..< ^1], "undo takes paste away"
  editor.inputted("historyRedo", "")
  expectThat editor.shownText == TYPED[0 ..< ^1] & PASTED, "redo puts paste back"
  await settled()
  ended "Typing, erasing, paste, undo and redo keep text and caret, and page reads what was typed"

  # lo se tcidu pe lo pu selci'a poi klama ba lo mupli cu basti no da
  let
    sample = DOCUMENT.querySelector("[data-sample]:nth-child(2)")
    wanted = sample.getAttribute("data-sample").to(cstring)
  selected(current().text.len, current().text.len)
  editor.inputted("insertText", "a")
  discard sample.click()
  await settled()
  for _ in 0 ..< 30: await nextFrame()
  expectThat current().text == wanted, "sample stands after answer of text before it"
  expectThat not current().is_moved, "page draws its own reading of sample"
  expectThat current().described == expectations[1],
      "page draws reading of sample, not of text before"
  ended "Answer of text before a sample never stands in place of reading of sample"

  # lo se tcidu poi klama ca lo nu basti cu na se cirko
  selected(current().text.len, current().text.len)
  editor.inputted("insertText", " ")
  editor.fired("compositionstart")
  for _ in 0 ..< WAIT_MOST:
    if not isAsking(): break
    await nextFrame()
  editor.fired("compositionend")
  await settled()
  expectThat not current().is_moved, "page reads text after composition that changed nothing"
  ended "Answer that comes while input method composes is read once composition ends"

  for (id, class_name) in [("show-gloss", "no-gloss"), ("show-bars", "no-bars")]:
    let toggle = DOCUMENT.getElementById(cstring(id))
    expectThat toggle.checked.to(bool), "switch is on at first: " & id
    discard toggle.click()
    expectThat editor.classList.contains(cstring(class_name)).to(bool), "switch off hides: " & id
    discard toggle.click()
    expectThat not editor.classList.contains(cstring(class_name)).to(bool),
        "switch on shows: " & id
  ended "Each switch is on at first, and hides its layer when off"
  reportEnd(if countFailures() > 0: 1 else: 0)


# le cipra cu fasnu ne'i le papri
#   .i le gunka noi selkra le vi samtci cu spuda le papri po'o to `text_layers.nim` toi
if DOCUMENT.jsTypeOf != "undefined":
  initReporter()
  discard runSuite()
