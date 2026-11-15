## Hold page of live text (`pages/live.html`) to native build, in headless Chromium that verb
##   `drive` starts (`tools/drive.nim`): page built from same shell, with this suite as its script
##   in place of `src/browser/page.nim`, which suite holds whole, since second script of Nim on
##   page would replace procs of first (`tools/browser.nim`).
##   Each case backend serves gives what page shows of it, against drawing native build gives:
##     sample read whole, as its button reads it; text streamed word by word, then ended; text
##     typed piece by piece, kept open; edit that keeps no text before it, which starts new
##     reader. Case and each piece is file of one string, so no format stands between them.
##   Merge of each case draws each tree native build merges its NIF so far to, with its line, as
##     `drawnMerged` gives both builds: one tree of one pass, or tree of each run around error
##     that stays; next change hides them, as stale. Suite wires controls as page does
##     (`wiredControls`), and clicks button Merge.
##   Drawing page shows and drawing native build writes compare as same browser serialises both,
##     so no quirk of serialiser stands between them.
##   Page whose rule of content refuses each worker reads on its own thread, shows same drawing,
##     and says so in line of mode.
##   Suite of promises reports each test as unittest spells it (`report.nim`), since unittest
##     awaits none, then code of run.

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, strutils]

import ../../src/browser/page
import ./report


const
  DIRECTORY_CASES = "/drive/page/"  ## Folder backend serves cases from.
  COUNT_CASES_LEAST = 9  ## Cases backend serves, at least.
  MODE_REFUSED = "refused"
    ## Mode of page whose rule of content refuses each worker, as attribute `data-mode` of body.
  MODE_WORKER = "A worker reads the text."  ## Line of mode where worker reads.
  MODE_PAGE = "This page reads the text, since it gives no worker."
    ## Line of mode where page refuses worker.
  KINDS = ["whole", "stream", "typed", "edit"]  ## Kind of each case backend serves.


type Case = object  ## Define case of page: how suite reads it, and what native build draws.
  kind: string  ## Member of `KINDS`.
  pieces: seq[string]  ## Text of case, piece by piece; whole text for `whole` and `stream`.
  html: string  ## Drawing native build gives.
  status: string  ## Line native build gives.
  merged_html: string  ## Drawing of tree native build merges NIF so far to.
  merged_status: string  ## Line of merge native build gives.


let DOCUMENT {.nodecl, importc: "document".}: JsObject  ## Document of page; none in worker.


proc serialised(html: cstring): cstring {.importjs:
  "(function(markup) { var held = document.createElement('template'); " &
  "held.innerHTML = markup; return held.innerHTML; })(#)".}
  ## Give markup as browser serialises it. Boundary of JS target: element `template`.


proc readCases(): seq[Case] =
  ## Read each case backend serves, with each piece of it.
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
  ## Read case as page reads it: by button, by stream with no pause, or typed piece by piece.
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
  ## Run each test of suite in order, and report each, then code of run.
  let is_refused = DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED
  report "[Suite] Internal: Page of live text" & (if is_refused: ", worker refused" else: "")
  let cases = readCases()
  var failures = countFailures()
  wiredControls()

  template ended(name: string) =
    ## Report test as unittest spells it: failed where check failed since last test.
    report "  [" & (if countFailures() > failures: "FAILED" else: "OK") & "] " & name
    failures = countFailures()

  expectThat cases.len >= COUNT_CASES_LEAST, "backend serves " & $COUNT_CASES_LEAST & " cases"
  var
    kinds: seq[string]
    merges: seq[tuple[html, status: string, is_hidden: bool]]  # what page shows, case by case
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
  expectThat kinds == @KINDS, "backend serves each kind of case"  # IX.3, guard keeps each kind
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
  expectThat count_whole > 0 and count_kept > 0, "cases merge whole, and keep error"  # IX.3
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
  await typed(cstring(text_typed & " .i"))  # same reader takes word more, as it stays open
  expectThat is_shown, "button shows tree merged"
  expectThat DOCUMENT.getElementById(cstring("merged")).hidden.to(bool),
    "change of same reader hides tree merged"
  ended "Change of same reader hides tree merged, which no longer holds"

  let mode = $DOCUMENT.getElementById(cstring("mode")).textContent.to(cstring)
  expectThat mode == (if is_refused: MODE_PAGE else: MODE_WORKER), "line of mode; got " & mode
  ended "Line of mode names worker, or thread of page where page refuses worker"

  reportEnd(if countFailures() > 0: 1 else: 0)


# Run suite in page; in worker, which starts from this script, answer page alone (`live_text.nim`).
if DOCUMENT.jsTypeOf != "undefined":
  initReporter()
  discard runSuite()
