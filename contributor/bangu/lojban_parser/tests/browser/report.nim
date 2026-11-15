## cusku lo jalge be lo cipra poi fasnu ne'i lo papri ku'o fi le sabji samtci poi sabji le papri to
##     `tools/drive.nim` toi
##   .i cusku ro linji
##   .i ba bo cusku lo famna'u pe le papri
##   .i ro selsku cu selbe'i sepi'o pa nu cpedu pe vo'a
##
##   |-----------------|-------------------------------------------------------------------------|
##   | lo fancu        | lo smuni                                                                |
##   |-----------------|-------------------------------------------------------------------------|
##   | `report`        | benji pa linji le sabji samtci                                          |
##   | `reportEnd`     | benji lo famna'u pe le cipra                                        |
##   |                 | .i se ki'u bo le nu cipra cu sisti                                      |
##   | `readServed`    | tcidu lo datnyvei poi le sabji samtci cu sabji ke'a ku'o ta'i pa lerpoi |
##   | `initReporter`  | cusku ro cipra pe `unittest` .e ro rersre pe le papri  |
##   | `expectThat`    | kancu je cusku lo nu pa xusra pe lo cipra pe lo nupre cu fliba          |
##   | `countFailures` | lo cipra poi fliba ku'o .e lo xusra poi `expectThat` kancu ke'a      |
##   |-----------------|-------------------------------------------------------------------------|
##
## ni'o ro nu cpedu cu rinka lo nu le papri cu denpa lo nu le sabji samtci cu spuda
##   .i se ki'u bo le sabji samtci cu tcidu lo linji ta'i le porsi be lo nu le papri cu cusku
##   .i le papri cu cusku le fanmo ba lo nu cusku ro linji
##   .i no linji cu selsku ba le fanmo
##   .i se to'e cuxna fa `fetch` noi lo nu ke'a cpedu cu ka'e klama ta'i lo datpoi
##
## ni'o ro srera poi le papri cu renro ke'a .a ro nupre poi le papri cu to'e curmi ke'a zi'e noi no
##     fancu cu spuda ke'a selsku gi'e rinka lo nu le nu cipra cu sisti sepi'o lo famna'u poi du li
##     pa
##   .i se ki'u bo lo nu cipra poi spofu cu fliba ca lo nu spofu
##   .i le nu cipra cu na denpa lo rairtei pe le sabji samtci

{.experimental: "strictFuncs".}

import std/[jsffi, unittest]


type ReporterPage = ref object of OutputFormatter  ## lo taizba poi cusku fi le sabji samtci


var COUNT_FAILURES = 0
  ## lo cipra pe `unittest` ge'u .e lo xusra pe lo cipra pe lo nupre vu'o poi fliba


let SELF {.nodecl, importc: "self".}: JsObject
  ## lo stuzi pe le papri ge'u zi'e poi ro da ka'e pilno ke'a


proc newRequest(): JsObject {.importjs: "new XMLHttpRequest()".}
  ## zbasu lo nu cpedu fi le sabji samtci
  ##   .i korbi `JS` sepi'o pa zbafancu pe le papri


proc send(path, body: string) =
  ## benji `body` le sabji samtci bu'u `path` gi'e denpa lo nu le sabji samtci cu spuda
  let request = newRequest()
  request.open(cstring("POST"), cstring(path), false)
  request.send(cstring(body))


proc report*(line: string) = send("/log", line)
  ## benji pa linji le sabji samtci
  ##   .i le sabji samtci cu jmina le linji lo linji pe le nu cipra

proc reportEnd*(code: int) = send("/done", $code)
  ## benji lo famna'u pe le cipra le sabji samtci
  ##   .i le sabji samtci cu sisti le nu cipra


proc readServed*(path: string): string =
  ## tcidu lo datnyvei poi le sabji samtci cu sabji ke'a bu'u `path` ku'o ta'i pa lerpoi pe `UTF-8`
  let request = newRequest()
  request.open(cstring("GET"), cstring(path), false)
  request.send()
  doAssert request.status.to(int) == 200, "Backend should serve `" & path & "`; got status " &
    $request.status.to(int) & "."
  $request.responseText.to(cstring)


method suiteStarted*(formatter: ReporterPage, suite_name: string) =
  ## cusku lo krasi be le cipra ta'i lo nu `unittest` ciska fi `console`
  report "[Suite] " & suite_name


method testEnded*(formatter: ReporterPage, result: TestResult) =
  ## cusku lo jalge be pa cipra ta'i lo nu `unittest` ciska fi `console`
  ##   .i va'o lo nu le cipra cu fliba kei kancu le cipra
  ##   .i `unittest` jdice no famna'u ne'i `JS` va'o lo nu `node` na selpli
  ##   .i se ki'u bo lo nu fliba cu jdice lo famna'u pe le nu cipra
  report "  [" & $result.status & "] " & result.testName
  if result.status == TestStatus.FAILED: inc COUNT_FAILURES


method failureOccurred*(formatter: ReporterPage, checkpoints: seq[string], stack_trace: string) =
  ## cusku ro `checkpoint` pe lo xusra poi fliba ku'o ta'i lo nu `unittest` ciska fi `console`
  for checkpoint in checkpoints: report "    " & checkpoint


proc reportError(event: JsObject) =
  ## cusku lo srera poi le papri cu renro ke'a .a lo nupre poi le papri cu to'e curmi ke'a zi'e noi
  ##     no fancu cu spuda ke'a
  ##   .i ba bo sisti le nu cipra sepi'o lo famna'u poi du li pa
  let error = (if event.reason.isUndefined: event.message else: event.reason)
  report "Page should throw no error; got `" & $error.toString().to(cstring) & "`."
  reportEnd(1)


proc initReporter*() =
  ## cusku ro cipra pe `unittest` le sabji samtci noi basti `console`
  ##   .i cusku ji'a ro srera poi le papri cu renro ke'a
  addOutputFormatter(ReporterPage())
  SELF.addEventListener(cstring("error"), reportError)
  SELF.addEventListener(cstring("unhandledrejection"), reportError)


proc expectThat*(is_held: bool, claim: string) =
  ## kancu je cusku lo nu pa xusra pe lo cipra pe lo nupre cu fliba
  ##   .i `unittest` na ka'e denpa lo nupre
  if is_held: return
  inc COUNT_FAILURES
  report "    Check failed: " & claim


proc countFailures*(): int = COUNT_FAILURES
  ## dunda lo du'u xo kau cipra pe `unittest` fliba kei .e lo du'u `expectThat` kancu xo kau xusra
