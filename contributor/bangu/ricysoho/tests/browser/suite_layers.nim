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
##   .i le cuxna cu muvdu gapru ja cnita ja'i le stuzi poi ri ca zvati
##   .i le ctuca cu skicu le valsi ja'i le liste gi'e skicu ro linji poi vasru le valsi

{.experimental: "strictFuncs".}

import std/[algorithm, asyncjs, jsffi, options, random, sequtils, strutils]

import ../../src/browser/[lessons, text_layers]
import ../../src/ricysoho/layers
import ./report


const
  DIRECTORY_CASES = "/drive/layers/"  ## lo vasru be lo se cipra poi le sabji samtci cu sabji ke'a
  COUNT_CASES_LEAST = 8  ## lo du'u le sabji samtci cu sabji su'o xo kau se cipra
  COUNT_SIGNS_LEAST = 3
    ## lo du'u le se cipra cu vasru su'o xo kau sinxa poi zvati no valsi to `D3 a` pe `#1101` toi
  MODE_REFUSED = "refused"
    ## lo tadji be lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka
  TYPED = "mi klama le zarci .i do"  ## le selci'a poi le cipra cu ciska ke'a ta'i pa lerfu
  PASTED = " cadzu"  ## le selci'a poi le cipra cu punji ke'a
  WAIT_MOST = 600  ## lo klani be lo nu le cipra cu denpa pa se tcidu ta'i pa pixra
  CLASS_GROUP = ["g-pred", "g-sumti", "g-num", "g-tag", "g-link", "g-free", "g-struct", "g-bad"]
    ## lo klesi pe `CSS` pe ro girzu be lo valsi to `text_layers.nim` toi
  SEED = 1055  ## lo tsiju be lo nu cenba poi selzba
  COUNT_EDITS = 60  ## lo klani be lo nu cenba poi selzba ku'o pe ro se cipra
  CREDIT = ["Meanings come from the word lists of Logical Language Group, Inc.",
      "Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA",
      "The lists are preliminary.",
      "The group is a source of more information on the lists and on Lojban."]
    ## lo pagbu be le selci'a pe le liste poi le javni pe le liste cu cpedu ke'a
    ##   .i le papri cu cusku le cmene .e le judri be le girzu
    ##   .i le papri cu cusku ji'a lo du'u le liste cu na mulno kei .e lo du'u le girzu cu krasi
    ##       lo zmadu datni
  LETTERS = ["a", " ", "'", ".", "\n", "mi", "😀"]
    ## lo pagbu be lo selci'a poi lo nu cenba cu punji ke'a
    ##   .i pa pagbu cu vasru pa lerfu poi zmadu `U+FFFF`
  REACH_MOST = 24.0
    ## lo du'u le cuxna cu zvati su'e xo kau `px` lo stuzi poi le cipra cu cpedu ke'a


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
proc pressed(editor: JsObject, key: cstring) {.importjs:
  "#.dispatchEvent(new KeyboardEvent('keydown', { key: #, bubbles: true, cancelable: true }))".}
  ## rinka pa nu danre pa batke
proc focused(node: JsObject) {.importjs: "#.focus()".}
  ## punji le cuxna ne'i le dacti
proc hovered(node: JsObject) {.importjs:
  "#.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }))".}
  ## rinka pa nu le korbi cu pencu le dacti
proc left(node: JsObject) {.importjs: "#.dispatchEvent(new MouseEvent('mouseleave'))".}
  ## rinka pa nu le korbi cu cliva le dacti
proc caretLeft(): float {.importjs:
  "(function() { var s = getSelection(); var r = document.createRange(); " &
  "r.setStart(s.focusNode, s.focusOffset); r.collapse(true); var b = r.getClientRects()[0]; " &
  "return b ? b.left : r.getBoundingClientRect().left; })()".}
  ## le stuzi pe le cuxna ne'i le papri ta'i lo mulna'u pe `px`
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


proc chosenKey(): string =
  ## le valsi .a le linji poi le ctuca cu skicu ke'a ta'i zoi gy. w3 .gy. .a zoi gy. b5 .gy.
  let head = DOCUMENT.querySelector("#lesson .head")
  if head.isNull: "" else: $head.getAttribute("data-chosen").to(cstring)


proc pathBars(): seq[int] =
  ## ro linji poi le ctuca cu jarco ke'a ne'i le pritu be le stedu ta'i le porsi
  for button in queryAll("#lesson .path button"):
    result.add parseInt($button.getAttribute("data-b").to(cstring))


proc partKeys(): seq[string] =
  ## ro pagbu poi le ctuca cu jarco ke'a ta'i zoi gy. w3 .gy. .a zoi gy. b5 .gy.
  for item in queryAll("#lesson ol li"):
    let bar = item.getAttribute("data-b")
    result.add(if bar.isNull: "w" & $item.getAttribute("data-p").to(cstring)
        else: "b" & $bar.to(cstring))


proc shownLesson(selector: cstring): string =
  ## le selci'a pe le pamoi dacti pe le ctuca poi mapti `selector`
  let node = DOCUMENT.querySelector(cstring("#lesson " & $selector))
  if node.isNull: "" else: $node.textContent.to(cstring)


proc shownLessons(selector: cstring): seq[string] =
  ## le selci'a pe ro dacti pe le ctuca poi mapti `selector` ta'i le porsi
  for node in queryAll(cstring("#lesson " & $selector)): result.add $node.textContent.to(cstring)


func parted(model: Model, bar: int): seq[string] =
  ## ro pagbu be pa linji ta'i le porsi pe le se ciska
  ##   .i pa pagbu cu du pa linji poi le linji cu vasru ke'a .a pa valsi poi no ri cu vasru
  var starts: seq[(int, string)]
  for k, kid in model.bars:
    if kid.parent == bar: starts.add (kid.first, "b" & $k)
  for word in model.bars[bar].first .. model.bars[bar].last:
    var is_held = false
    for kid in model.bars:
      if kid.parent == bar and kid.first <= word and word <= kid.last: is_held = true
    if not is_held: starts.add (word, "w" & $word)
  starts.sort(proc(a, b: (int, string)): int = cmp(a[0], b[0]))
  for (_, key) in starts: result.add key


proc nameDrawn(bar: int): string =
  ## le cmene poi le linji cu ponse ke'a ne'i le se ciska
  $DOCUMENT.querySelector(cstring("#editor [data-b=\"" & $bar & "\"][data-n]")).getAttribute(
      "data-n").to(cstring)


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
  var texts, expectations, meanings, kinds: seq[string]
  for k in 0 ..< count:
    texts.add readServed(DIRECTORY_CASES & $k & ".text")
    expectations.add readServed(DIRECTORY_CASES & $k & ".layers")
    meanings.add readServed(DIRECTORY_CASES & $k & ".meanings")
    kinds.add readServed(DIRECTORY_CASES & $k & ".kinds")
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
      let moved = model.shifted(low, high, put, goal)
      expectThat moved.isSound, "edit keeps words and bars sound: " & $goal
      # pa valsi poi zvati lo bartu be le cenba cu stali le sinxa .e le valsi poi ke'a se tcidu
      #     ta'i ke'a
      let d = put.len - (high - low)
      for word in model.words:
        if word.sign_s < 0 or word.e <= word.s or not (word.e < low or word.s > high): continue
        let
          shift = if word.e < low: 0 else: d
          kept = moved.words.filterIt(it.s == word.s + shift and it.e == word.e + shift)
        expectThat kept.len == 1 and kept[0].sign_s == word.sign_s + shift and
            kept[0].sign_e == word.sign_e + shift and kept[0].spoken == word.spoken,
            "edit keeps sign and spoken word of each word it leaves: " & $goal
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

  # le cuxna cu muvdu gapru ja'i le stuzi poi ri ca zvati
  #   .i ri na muvdu ja'i lo stuzi poi ri pu zvati
  let long = DOCUMENT.querySelector("[data-sample]:nth-child(1)").getAttribute("data-sample")
  drawn(long.to(cstring).toModel, none((int, int, bool)))
  editor.focused
  selected(1, 1)
  editor.pressed("ArrowDown")
  await nextFrame()
  selected(8, 8)
  await nextFrame()
  let goal_left = caretLeft()
  editor.pressed("ArrowDown")
  await nextFrame()
  expectThat abs(caretLeft() - goal_left) <= REACH_MOST,
      "vertical move keeps place that caret took last: " & $caretLeft() & " for " & $goal_left
  ended "Caret moves up and down from place it took last, never from place before"

  # le ctuca cu skicu le valsi poi le korbi cu pencu ke'a
  let lesson = DOCUMENT.getElementById("lesson")
  drawn(cstring(texts[0]).toModel, none((int, int, bool)))
  await nextFrame()
  expectThat $lesson.textContent.to(cstring) == LESSON_START, "lesson opens with its call to point"
  for k, text in texts:
    let
      model = cstring(text).toModel
      found = meanings[k].split('\n')
    drawn(model, none((int, int, bool)))
    await nextFrame()
    for i, word in model.words:
      DOCUMENT.querySelector(cstring("#editor [data-w=\"" & $i & "\"]")).hovered
      let expected = found[i].split('\t')
      expectThat chosenKey() == "w" & $i, "lesson takes word under pointer: " & $word.text
      expectThat shownLesson(".head b") == expected[0] and shownLesson(".head .sel") == $word.gloss,
          "lesson names word, or digit or sign that stands for it, and its selma'o: " & $word.text
      expectThat shownLessons(".meaning") == expected[3 .. ^1],
          "word takes meaning native build gives it, for each word of its sign: " & $word.text
      expectThat shownLesson(".parts") ==
          (if expected[2].len > 0: LESSON_PARTS & " " & expected[2] else: ""),
          "lujvo takes parts that list gives it, and other word none: " & $word.text
      var holding: seq[int]
      for b, bar in model.bars:
        if bar.first <= i and i <= bar.last: holding.add b
      holding.sort(proc(a, b: int): int = cmp(model.bars[b].height, model.bars[a].height))
      expectThat pathBars() == holding,
          "path names each bar that holds word, largest first: " & $word.text
      for button in queryAll("#lesson .path button"):
        let bar = parseInt($button.getAttribute("data-b").to(cstring))
        expectThat $button.textContent.to(cstring) == bar.nameDrawn,
            "bar of path takes name it takes under text: " & $word.text
      expectThat partKeys().len == 0, "word lists no parts: " & $word.text
  ended "Lesson teaches word under pointer, its meaning and each bar that holds it as path"

  # lo sinxa poi zvati no valsi cu cuxna le pamoi valsi pe vo'a
  #   .i `Architect` jdice di'u bu'u `#1101` ta'i `D3 a`
  var signs_drawn = 0
  for k, text in texts:
    let model = cstring(text).toModel
    drawn(model, none((int, int, bool)))
    await nextFrame()
    for i, word in model.words:
      if word.sign_s < 0 or model.words.anyIt(it.s == word.sign_s and it.e == word.sign_e):
        continue
      var first = i  # le pamoi valsi pe le sinxa
      while first > 0 and model.words[first - 1].sign_s == word.sign_s and
          model.words[first - 1].sign_e == word.sign_e: dec first
      let node = DOCUMENT.querySelector(cstring("#editor .sign[data-w=\"" & $first & "\"]"))
      expectThat not node.isNull and
          $node.textContent.to(cstring) == $model.text.slice(word.sign_s, word.sign_e),
          "sign that lies in no word draws with its first word: " & text
      if node.isNull: continue
      node.hovered
      expectThat chosenKey() == "w" & $first, "pointer on sign teaches its first word: " & text
      if i == first: inc signs_drawn
  expectThat signs_drawn >= COUNT_SIGNS_LEAST,
      "cases hold " & $COUNT_SIGNS_LEAST & " signs that lie in no word"
  ended "Sign that lies in no word takes pointer, and teaches each word it stands for"

  for k, text in texts:
    let
      model = cstring(text).toModel
      taught = kinds[k].split('\n')
    drawn(model, none((int, int, bool)))
    await nextFrame()
    for b, bar in model.bars:
      DOCUMENT.querySelector(cstring("#editor .cell [data-b=\"" & $b & "\"]")).hovered
      let
        lesson_kind = LESSON_KIND[Category(bar.category)]
        expected = taught[b].split('\t')
      var
        above: seq[int]
        parent = bar.parent
      while parent >= 0:
        above.add parent
        parent = model.bars[parent].parent
      expectThat chosenKey() == "b" & $b, "lesson takes bar under pointer: " & text
      expectThat shownLesson(".head .kind") == lesson_kind.lojban and
          lesson_kind.lojban == b.nameDrawn, "bar takes Lojban name it takes under text: " & text
      expectThat shownLesson(".head .en") == expected[0] and shownLesson(".meaning") == expected[1],
          "bar takes English name and text native build gives it: " & text
      expectThat pathBars() == above.reversed, "path names each bar that holds bar: " & text
      expectThat shownLesson("q.words") ==
          $model.text.slice(model.words[bar.first].s, model.words[bar.last].e),
          "lesson quotes words of bar: " & text
      for button in queryAll("#lesson .path button"):
        let held = parseInt($button.getAttribute("data-b").to(cstring))
        expectThat $button.textContent.to(cstring) == held.nameDrawn,
            "bar of path takes name it takes under text: " & text
      expectThat partKeys() == model.parted(b), "lesson lists parts of bar in order: " & text
      for item in queryAll("#lesson ol li"):
        let part = item.getAttribute("data-b")
        if part.isNull:
          let
            w = parseInt($item.getAttribute("data-p").to(cstring))
            meaning = meanings[k].split('\n')[w]
          expectThat $item.querySelector(".en").textContent.to(cstring) == meaning.split('\t')[1],
              "word part takes gloss native build gives it: " & text
          expectThat $item.querySelector("b").textContent.to(cstring) == $model.words[w].text and
              $item.querySelector(".sel").textContent.to(cstring) == $model.words[w].gloss,
              "word part names word and its selma'o: " & text
        else:
          let p = parseInt($part.to(cstring))
          expectThat $item.querySelector(".kind").textContent.to(cstring) == p.nameDrawn and
              $item.querySelector(".en").textContent.to(cstring) == taught[p].split('\t')[0] and
              $item.querySelector(".what").textContent.to(cstring) == taught[p].split('\t')[1],
              "bar part takes names and text native build gives it: " & text
          expectThat $item.querySelector("q").textContent.to(cstring) ==
              $model.text.slice(model.words[model.bars[p].first].s,
              model.words[model.bars[p].last].e), "bar part quotes its words: " & text
  ended "Lesson teaches bar under pointer, its text, each bar that holds it, and each part of it"

  # pa nu samcu'a pa pagbu .a pa linji pe le pritu cu muvdu le ctuca
  let
    model = cstring(texts[0]).toModel
    deep = block:
      var found = -1
      for b, bar in model.bars:
        if found < 0 and bar.parent >= 0 and model.parted(b).len > 1: found = b
      found
  drawn(model, none((int, int, bool)))
  await nextFrame()
  expectThat deep >= 0, "first case holds bar with parent and parts"
  discard DOCUMENT.querySelector(cstring("#editor .cell [data-b=\"" & $deep & "\"]")).click()
  editor.firstElementChild.left
  let first_part = model.parted(deep)[0]
  discard DOCUMENT.querySelector("#lesson ol li").click()
  expectThat chosenKey() == first_part, "click on part moves lesson to it"
  DOCUMENT.querySelector("#editor [data-w=\"0\"]").hovered
  editor.firstElementChild.left
  expectThat chosenKey() == first_part, "part clicked stays once pointer leaves text"
  let outer = block:
    var found = -1
    for b in 0 ..< model.bars.len:
      if found < 0 and model.parted(b).anyIt(it[0] == 'b'): found = b
    found
  expectThat outer >= 0, "first case holds bar with bar among its parts"
  discard DOCUMENT.querySelector(cstring("#editor .cell [data-b=\"" & $outer & "\"]")).click()
  editor.firstElementChild.left
  let
    row = DOCUMENT.querySelector("#lesson ol li[data-b]")
    picked = "b" & $row.getAttribute("data-b").to(cstring)
  discard row.click()
  expectThat chosenKey() == picked, "click on bar part moves lesson to it"
  editor.firstElementChild.left
  expectThat chosenKey() == picked, "bar part clicked stays once pointer leaves text"
  expectThat not DOCUMENT.querySelector(cstring("#editor [data-b=\"" & picked[1 .. ^1] &
      "\"].hl")).isNull, "bar part clicked lights its bar under text"
  var root = deep
  while model.bars[root].parent >= 0: root = model.bars[root].parent
  discard DOCUMENT.querySelector(cstring("#lesson .path button[data-b=\"" & $root & "\"]")).click()
  expectThat chosenKey() == "b" & $root, "click on bar of path moves lesson to it"
  expectThat pathBars().len == 0, "bar that no bar holds takes no path"
  let inner = block:
    var found = -1
    for b, bar in model.bars:
      if found < 0 and bar.parent >= 0 and model.parted(b).anyIt(it[0] == 'b'): found = b
    found
  expectThat inner >= 0 and chosenKey() != "b" & $inner,
      "first case holds bar with parent and bar among its parts"
  discard DOCUMENT.querySelector(cstring("#editor .cell [data-b=\"" & $inner & "\"]")).click()
  editor.firstElementChild.left
  expectThat chosenKey() == "b" & $inner, "click on bar under text moves lesson to it"
  for selector in ["#lesson .head .kind", "#lesson .path button", "#lesson li .kind",
      "#lesson li q", "#lesson q.words"]:
    let found = queryAll(cstring(selector))
    expectThat found.len > 0 and found.allIt(not it.getAttribute("lang").isNull and
        $it.getAttribute("lang").to(cstring) == "jbo"),
        "Lojban of lesson takes its language: " & selector
  let keyed = DOCUMENT.querySelector("#lesson ol li")
  expectThat not keyed.isNull, "lesson of bar lists its parts"
  if not keyed.isNull:
    let pressed_key =
      if keyed.getAttribute("data-b").isNull: "w" & $keyed.getAttribute("data-p").to(cstring)
      else: "b" & $keyed.getAttribute("data-b").to(cstring)
    keyed.pressed("Enter")
    expectThat chosenKey() == pressed_key, "Enter on part moves lesson to it"
  let kept = chosenKey()
  discard DOCUMENT.querySelector("#lesson .meaning").click()
  expectThat chosenKey() == kept, "click inside lesson keeps it"
  ended "Click on part or on bar of path moves lesson to it"

  # le ctuca cu stali ba lo nu samcu'a
  drawn(cstring(texts[0]).toModel, none((int, int, bool)))
  await nextFrame()
  let chosen = DOCUMENT.querySelector("#editor [data-w=\"1\"]")
  chosen.hovered
  discard chosen.click()
  editor.firstElementChild.left
  expectThat chosenKey() == "w1", "lesson stays on word clicked once pointer leaves"
  discard chosen.click()
  editor.firstElementChild.left
  expectThat $lesson.textContent.to(cstring) == LESSON_START, "second click lets lesson go"
  let bar = DOCUMENT.querySelector("#editor .cell [data-b=\"0\"]")
  bar.hovered
  discard bar.click()
  editor.firstElementChild.left
  expectThat chosenKey() == "b0", "lesson stays on bar clicked once pointer leaves"
  discard bar.click()
  editor.firstElementChild.left
  expectThat $lesson.textContent.to(cstring) == LESSON_START, "second click on bar lets lesson go"
  ended "Click keeps lesson on its word or bar once pointer leaves, and second click lets it go"

  let credit = $DOCUMENT.querySelector(".lesson .credit").textContent.to(cstring)
  for part in CREDIT:
    expectThat part in credit.splitWhitespace.join(" "), "credit holds: " & part
  ended "Credit names group and its address, says lists are preliminary, and names group as source"

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
