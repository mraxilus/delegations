## Report checks of suite page to server of `tools/drive.nim`, in place of console.
##   `POST /log` adds line, and `POST /done` ends run with exit code; each post is synchronous,
##     so end follows every line.
##   Error page throws, or promise it rejects and no routine handles, fails run at once.
##   Sibling: `ricysoho/tests/browser/report.nim`, whose logic this file takes, less formatter of
##     `unittest`, since no suite here runs `unittest`; each project drives its own pages, as D1 on
##     #1058 ruled (II.9). Fix to one is finished only when other is checked.

{.experimental: "strictFuncs".}

import std/jsffi


var COUNT_FAILURES = 0  ## Checks failed so far.


let SELF {.nodecl, importc: "self".}: JsObject  ## Global scope of page.


proc newRequest(): JsObject {.importjs: "new XMLHttpRequest()".}
  ## Make request; synchronous, so end posts after each line.


proc send(path, body: string) =
  ## Post body to server at path, and wait for its answer.
  let request = newRequest()
  request.open(cstring("POST"), cstring(path), false)
  request.send(cstring(body))


proc report*(line: string) = send("/log", line)
  ## Post one line of run.

proc reportEnd*(code: int) = send("/done", $code)
  ## Post end of run with exit code.


proc reportError(event: JsObject) =
  ## Report error page threw, or promise it rejected unhandled, then end run with exit 1.
  let error = (if event.reason.isUndefined: event.message else: event.reason)
  report "Page should throw no error; got `" & $error.toString().to(cstring) & "`."
  reportEnd(1)


proc initReporter*() =
  ## Report each error page throws, and each promise it rejects unhandled.
  SELF.addEventListener(cstring("error"), reportError)
  SELF.addEventListener(cstring("unhandledrejection"), reportError)


proc expectThat*(is_held: bool, claim: string) =
  ## Count and report check that fails.
  if is_held: return
  inc COUNT_FAILURES
  report "    Check failed: " & claim


proc countFailures*(): int = COUNT_FAILURES
  ## Give checks failed so far.
