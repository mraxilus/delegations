## Report suite that runs in page to backend that serves page (`tools/drive.nim`): each line,
##   then code page exits with, each as request of its own.
##
##   |-----------------|-------------------------------------------------------------------|
##   | Code            | Meaning                                                           |
##   |-----------------|-------------------------------------------------------------------|
##   | report          | send one line to backend                                          |
##   | reportEnd       | send code suite exits with, which ends run                        |
##   | readServed      | read file backend serves, as string                               |
##   | initReporter    | report each test of unittest, and each error page throws          |
##   | expectThat      | count failure of check of suite of promises, and report it        |
##   | countFailures   | tests that failed, and checks `expectThat` counted                |
##   |-----------------|-------------------------------------------------------------------|
##
##   Each request is synchronous, so backend reads lines in order page reports them, and page
##     reports end only after each line. Rejected: `fetch`, whose requests may land out of order.
##   Error page throws, or promise it rejects with no handler, reports and ends run with code 1, so
##     run that breaks fails at once rather than at ceiling of backend.

{.experimental: "strictFuncs".}

import std/[jsffi, unittest]


type ReporterPage = ref object of OutputFormatter  ## Define formatter reporting to backend.


var COUNT_FAILURES = 0  ## Tests of unittest that failed, and checks of suite of promises.


let SELF {.nodecl, importc: "self".}: JsObject  ## Global scope of page.


proc newRequest(): JsObject {.importjs: "new XMLHttpRequest()".}
  ## Make request to backend. Boundary of JS target: constructor of page.


proc send(path, body: string) =
  ## Send body to backend at path, and wait for its answer.
  let request = newRequest()
  request.open(cstring("POST"), cstring(path), false)
  request.send(cstring(body))


proc report*(line: string) = send("/log", line)
  ## Send one line to backend, which adds it to lines of run.

proc reportEnd*(code: int) = send("/done", $code)
  ## Send code suite exits with to backend, which ends run.


proc readServed*(path: string): string =
  ## Read file backend serves at path, as string of UTF-8.
  let request = newRequest()
  request.open(cstring("GET"), cstring(path), false)
  request.send()
  doAssert request.status.to(int) == 200, "Backend should serve `" & path & "`; got status " &
    $request.status.to(int) & "."
  $request.responseText.to(cstring)


method suiteStarted*(formatter: ReporterPage, suite_name: string) =
  ## Report opening of suite, as console of unittest spells it.
  report "[Suite] " & suite_name


method testEnded*(formatter: ReporterPage, result: TestResult) =
  ## Report outcome of one test, as console of unittest spells it, and count it where it failed:
  ##   unittest sets no exit code on JS backend with no node, so failures give code of run.
  report "  [" & $result.status & "] " & result.testName
  if result.status == TestStatus.FAILED: inc COUNT_FAILURES


method failureOccurred*(formatter: ReporterPage, checkpoints: seq[string], stack_trace: string) =
  ## Report each checkpoint of failed check, as console of unittest does.
  for checkpoint in checkpoints: report "    " & checkpoint


proc reportError(event: JsObject) =
  ## Report error page throws, or promise it rejects with no handler, and end run with code 1.
  let error = (if event.reason.isUndefined: event.message else: event.reason)
  report "Page should throw no error; got `" & $error.toString().to(cstring) & "`."
  reportEnd(1)


proc initReporter*() =
  ## Report each test of unittest to backend in place of console, and each error page throws.
  addOutputFormatter(ReporterPage())
  SELF.addEventListener(cstring("error"), reportError)
  SELF.addEventListener(cstring("unhandledrejection"), reportError)


proc expectThat*(is_held: bool, claim: string) =
  ## Count failure of one check of suite of promises, which unittest cannot await, and report it.
  if is_held: return
  inc COUNT_FAILURES
  report "    Check failed: " & claim


proc countFailures*(): int = COUNT_FAILURES
  ## Give tests of unittest that failed, and checks `expectThat` counted.
