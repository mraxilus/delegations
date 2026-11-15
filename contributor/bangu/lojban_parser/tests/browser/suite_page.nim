## cipra lo du'u le papri pe lo jmive se ciska to `pages/live.html` toi cu mintu le jbezba ne'i
##     `headless Chromium` noi lo minde po'u `drive` rinka lo nu ke'a cfari to `tools/drive.nim` toi
##   .i le papri cu selzba fi le mitcalku
##   .i le vi cipra cu du le samtci pe le papri gi'e basti `src/browser/page.nim` gi'e vasru ro
##       pagbu be `src/browser/page.nim`
##   .i ki'u bo va'o lo nu pa remoi samtci pe `Nim` zvati le papri kei le remoi samtci cu basti lo
##       fancu pe le pamoi to `tools/browser.nim` toi
##
## ni'o le cipra cu karbi lo selja'o be le papri be'o pe ro se cipra poi le sabji samtci cu sabji
##     ke'a ku'o le pixra poi le jbezba cu dunda ke'a
##   .i pa se cipra cu du pa mupli poi mulseltcidu ta'i le batke pe ke'a
##   .i pa se cipra cu du pa selci'a poi selbe'i ta'i lo nu ro valsi cu sepli kei gi'e ba selsti
##   .i pa se cipra cu du pa selci'a poi selci'a ta'i lo nu ro pagbu cu sepli kei gi'e ca'o kalri
##   .i pa se cipra cu du pa nu galfi poi ralte no pu selci'a zi'e noi rinka lo nu pa ninytcidu cu
##       cfari
##
## ni'o ro se cipra .e ro pagbu cu datnyvei gi'e vasru pa lerpoi
##   .i se ki'u bo no tarmi be lo datni cu zvati lo jbini be le sabji samtci .e le cipra
##
## ni'o lo pixra be lo nu jmina be ro se cipra cu jarco ro tricu poi le jbezba cu jmina le ca
##     selci'a be fi `NIF` be'o pe le se cipra fo ke'a ku'o .e le linji
##   .i ro le re selzba cu pilno `drawnMerged`
##   .i le selja'o cu du pa tricu pe lo nu tcidu le mulselci'a .a lo tricu pe ro porsi be lo pagbu
##       poi sruri pa srera poi stali
##   .i lo bavla'i cenba cu mipri le tricu ki'u lo nu le tricu cu na drani
##   .i le cipra cu jitro lo trotci ta'i le papri to `wiredControls` toi gi'e danre le batke po'u
##       `Merge`
##
## ni'o le pixra poi le papri cu jarco ke'a ku'o .e le pixra poi le jbezba cu ciska ke'a se karbi
##     ta'i lo nu le mitytcidu be lo papri cu ciska ro le re pixra
##   .i se ki'u bo no cizra be le ciska cu zvati lo jbini be le re pixra
##
## ni'o lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka cu tcidu ne'i lo cilta pe
##     vo'a gi'e jarco le mitxra
##   .i le linji pe le tadji cu cusku di'u
##
## ni'o le cipra pe lo nupre cu cusku ro cipra ta'i lo nu `unittest` ciska to `report.nim` toi
##   .i ki'u bo `unittest` denpa no nupre
##   .i ba bo le cipra cu cusku lo famna'u pe le nu cipra

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, strutils]

import ../../src/browser/page
import ./report


const
  DIRECTORY_CASES = "/drive/page/"  ## lo vasru be lo se cipra poi le sabji samtci cu sabji ke'a
  COUNT_CASES_LEAST = 9  ## lo du'u le sabji samtci cu sabji su'o xo kau se cipra
  MODE_REFUSED = "refused"
    ## lo tadji be lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka
    ##   .i `data-mode` pe `body` jarco le tadji
  MODE_WORKER = "A worker reads the text."  ## le linji pe le tadji va'o lo nu pa gunka cu tcidu
  MODE_PAGE = "This page reads the text, since it gives no worker."
    ## le linji pe le tadji va'o lo nu le papri cu to'e curmi lo gunka
  KINDS = ["whole", "stream", "typed", "edit"]
    ## lo klesi poi ro se cipra pe le sabji samtci cu cmima ke'a


type Case = object
  ## pa se cipra pe le papri
  ##   .i le tadji be lo nu tcidu le se cipra .e le pixra pe le jbezba
  kind: string  ## pa cmima be `KINDS`
  pieces: seq[string]
    ## lo selci'a pe le se cipra ta'i lo nu ro pagbu cu sepli
    ##   .i pa pagbu cu du le mulselci'a va'o lo nu le klesi cu du `whole` .a `stream`
  html: string  ## le pixra poi le jbezba cu dunda ke'a
  status: string  ## le linji poi le jbezba cu dunda ke'a
  merged_html: string  ## le pixra be le tricu poi le jbezba cu jmina le ca selci'a fo ke'a
  merged_status: string  ## le linji pe lo nu jmina ge'u zi'e poi le jbezba cu dunda ke'a


let DOCUMENT {.nodecl, importc: "document".}: JsObject
  ## `document` pe le papri
  ##   .i no da ne'i lo gunka


proc serialised(html: cstring): cstring {.importjs:
  "(function(markup) { var held = document.createElement('template'); " &
  "held.innerHTML = markup; return held.innerHTML; })(#)".}
  ## dunda le selci'a be fi `HTML` be'o poi lo tcidu be lo papri cu ciska ke'a
  ##   .i korbi `JS` sepi'o pa pagbu po'u `template`


proc readCases(): seq[Case] =
  ## tcidu ro se cipra poi le sabji samtci cu sabji ke'a ku'o .e ro pagbu be le se cipra
  let count = readServed(DIRECTORY_CASES & "count.text").strip.parseInt
  for k in 0 ..< count:
    let path = DIRECTORY_CASES & $k
    var item = Case(kind: readServed(path & ".kind"), html: readServed(path & ".html"),
        status: readServed(path & ".status"), merged_html: readServed(path & ".merged.html"),
        merged_status: readServed(path & ".merged.status"))
    for j in 0 ..< readServed(path & ".count.text").strip.parseInt:
      item.pieces.add readServed(path & "." & $j & ".piece")
    result.add item


proc readCase(item: Case) {.async.} =
  ## tcidu le se cipra ta'i le papri
  ##   .i lo batke .a lo porsi be lo valsi be'o poi vasru no denpa ku'o .a lo nu ciska ro pagbu cu
  ##       rinka lo nu tcidu
  case item.kind
  of "whole": await readWhole(cstring(item.pieces[0]))
  of "stream": await streamed(cstring(item.pieces[0]), 0)
  of "typed":
    var text = ""
    for piece in item.pieces:
      text.add piece
      await typed(cstring(text))
  of "edit":
    for piece in item.pieces: await typed(cstring(piece))
  else: discard


proc runSuite() {.async.} =
  ## pilno ro cipra pe le cipra ta'i le porsi gi'e cusku ro le cipra
  ##   .i ba bo cusku lo famna'u pe le nu cipra
  let is_refused = DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED
  report "[Suite] Internal: Page of live text" & (if is_refused: ", worker refused" else: "")
  let cases = readCases()
  var failures = countFailures()
  wiredControls()

  template ended(name: string) =
    ## cusku le cipra ta'i lo nu `unittest` ciska
    ##   .i le cipra cu fliba va'o lo nu pa xusra cu fliba ba le romoi cipra
    report "  [" & (if countFailures() > failures: "FAILED" else: "OK") & "] " & name
    failures = countFailures()

  expectThat cases.len >= COUNT_CASES_LEAST, "backend serves " & $COUNT_CASES_LEAST & " cases"
  var
    kinds: seq[string]
    # lo selja'o be le papri pe ro se cipra ta'i lo nu ro se cipra cu sepli
    merges: seq[tuple[html, status: string, is_hidden: bool]]
  for item in cases:
    if item.kind notin kinds: kinds.add item.kind
    await item.readCase
    let
      drawing = $DOCUMENT.getElementById(cstring("parts")).innerHTML.to(cstring)
      status = $DOCUMENT.getElementById(cstring("status")).textContent.to(cstring)
      claim = item.kind & " " & item.pieces.join("|")
      is_hidden = DOCUMENT.getElementById(cstring("merged")).hidden.to(bool)
    expectThat drawing == $serialised(cstring(item.html)), "page draws as native build: " & claim
    expectThat status == item.status, "line names what native build names: " & claim
    discard DOCUMENT.getElementById(cstring("merge")).click()
    merges.add (
      $DOCUMENT.getElementById(cstring("merged-parts")).innerHTML.to(cstring),
      $DOCUMENT.getElementById(cstring("merged-status")).textContent.to(cstring), is_hidden,
    )
  # lo bandu cu ralte ro klesi
  expectThat kinds == @KINDS, "backend serves each kind of case"  # `IX.3`
  ended "Page draws each case as native build draws its NIF: whole, streamed, typed and edited"

  var count_whole, count_kept = 0
  for k in 0 ..< cases.len:
    let claim = cases[k].kind & " " & cases[k].pieces.join("|")
    expectThat merges[k].html == $serialised(cstring(cases[k].merged_html)),
      "merge draws trees native build merges to: " & claim
    expectThat merges[k].status == cases[k].merged_status,
      "line of merge names what native build names: " & claim
    if cases[k].merged_status.startsWith("Merged · one tree"): inc count_whole
    elif cases[k].merged_status.startsWith("Merged · "): inc count_kept
  expectThat count_whole > 0 and count_kept > 0, "cases merge whole, and keep error"  # `IX.3`
  ended "Merge draws trees of completed parts as native build merges them, error in place"

  for k in 0 ..< cases.len:
    expectThat merges[k].is_hidden, "new reader hides tree merged before it: " & cases[k].kind
  ended "New reader hides tree merged before it, which no longer holds"

  var text_typed = ""
  for item in cases:
    if item.kind == "typed": text_typed = item.pieces.join("")
  await typed(cstring(text_typed))
  discard DOCUMENT.getElementById(cstring("merge")).click()
  let is_shown = not DOCUMENT.getElementById(cstring("merged")).hidden.to(bool)
  # le mitytcidu cu cpacu pa valsi ji'a
  #   .i ki'u bo le tcidu cu ca'o kalri
  await typed(cstring(text_typed & " .i"))
  expectThat is_shown, "button shows tree merged"
  expectThat DOCUMENT.getElementById(cstring("merged")).hidden.to(bool),
    "change of same reader hides tree merged"
  ended "Change of same reader hides tree merged, which no longer holds"

  let mode = $DOCUMENT.getElementById(cstring("mode")).textContent.to(cstring)
  expectThat mode == (if is_refused: MODE_PAGE else: MODE_WORKER), "line of mode; got " & mode
  ended "Line of mode names worker, or thread of page where page refuses worker"

  reportEnd(if countFailures() > 0: 1 else: 0)


# le cipra cu fasnu ne'i le papri
#   .i le gunka noi selkra le vi samtci cu spuda le papri po'o to `live_text.nim` toi
if DOCUMENT.jsTypeOf != "undefined":
  initReporter()
  discard runSuite()
