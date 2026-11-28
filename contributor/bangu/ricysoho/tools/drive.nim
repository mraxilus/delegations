## jitro lo papri ne'i `headless Chromium` sepi'o `Nim` ta'i le samtci pe ro cipra poi fasnu ne'i lo
##     tcidu be lo papri
##   .i sabji le papri .e lo vasru be lo selzba bu'u pa vorme pe `loopback`
##   .i rinka lo nu `Chromium` cfari bu'u le papri
##   .i jarco ro linji poi le papri cu cusku ke'a ku'o .e ro datnyvei poi le papri cu benji ke'a
##       ku'o .e le famna'u pe le papri
##
## ni'o `node` na jitro le samtci
##   .i le samtci cu selci'a fi `Nim`
##   .i `Architect` jdice di'u bu'u `#859`
##
##   |-----------|----------------------------------------------------------------------------|
##   | lo cmene  | lo smuni                                                                   |
##   |-----------|----------------------------------------------------------------------------|
##   | `runPage` | sabji le papri .e le vasru gi'e jitro `Chromium` bu'u le papri |
##   |           | .i jarco lo selsku be le papri                                           |
##   |-----------|----------------------------------------------------------------------------|
##
## ni'o le papri cu cusku sepi'o lo nu cpedu pe vo'a
##   .i ro le nu cpedu cu vasru pa lerpoi pe vo'a
##   .i `POST /log` jmina pa linji
##   .i `POST /done` sisti le nu cipra sepi'o le famna'u
##   .i `POST` fi ro datyjudri cu benji pa datnyvei poi selcme le judri
##   .i se ki'u bo no tarmi be lo datni cu zvati lo jbini be le papri .e le samtci pe `Nim` to
##       `CONTRIBUTOR.md, Data` toi
##
## ni'o `Chromium` poi selpli cu du lo tcidu be lo papri be'o poi `LOJBAN_CHROMIUM` cmene ke'a
##   .i le tcidu cu ka'e du `Chrome` noi mulno .a `headless shell` pe `Chrome`
##   .i va'o lo drata `Chromium` poi selpli cu du `headless shell` poi lo sorcu pe `delegations`
##       sabji ke'a sepi'o lo sinxa namcu to `browser.nim` toi
##   .i le papri cu fasnu ne'i pa vreji pe vo'a ge'u zi'e noi le nu cipra cu vimcu ke'a
##
## ni'o `Chromium` jatna pa girzu pe vo'a
##   .i le nu cipra cu catra ro pruce pe le girzu gi'e cpacu lo fanmo be ro le pruce ba lo nu catra
##       kei gi'e vimcu le vreji ba lo nu cpacu lo fanmo be ro le pruce
##   .i ki'u bo lo pruce pe `Chromium` ciska fi le vreji ba lo nu le pamoi pruce cu sisti kei mu'u
##       lo nu `Chrome` noi mulno cu ciska `TransportSecurity` to `test_drive.nim` toi
##   .i le nu cipra cu catra ki'u lo nu le vreji cu selvi'u kei .e lo nu `Chrome` noi mulno cu ka'e
##       stali ne'i lo nu sisti poi `SIGTERM` cpedu ke'a
##
## ni'o le vi pruce cu kurji ro pruce poi selkra le vi pruce ku'o ta'i `subreaper` to `prctl(2)` toi
##   .i se ki'u bo ro pruce pe `Chromium` ge'u zi'e poi lo rirni be ke'a cu morsi cu klama le vi
##       pruce
##   .i ro nu denpa vi cu nu denpa lo nu morsi
##   .i no nu denpa vi cu nu denpa lo temci
##
## ni'o lo nu cipra poi cusku no fanmo pu `TIMEOUT_PAGE` fliba mu'u lo papri poi no roi mulno gi'a
##     renro lo srera pu lo nu le cusku pe ke'a selcpa
##   .i `TIMEOUT_PAGE` tcemau lo temci be lo nu cipra poi selmre ku'o gi'e tceme'a lo temci be lo nu
##       no roi mulno
##
## ni'o se to'e cuxna fa `Playwright` noi `API` pe ke'a fasnu ne'i `node` to `Architect` jdice bu'u
##     `#859` toi ku'o .e lo tavjva pe `DevTools` ge'u zi'e noi lo papri poi cusku sepi'o lo nu
##     cpedu cu na nitcu ke'a
##
## ni'o jdima fa lo nu va'o lo nu `Linux` na selpli kei pa pruce pe `Chromium` ge'u zi'e poi lo
##     rirni be ke'a cu morsi cu klama `init`
##   .i se ki'u bo lo nu vimcu le vreji cu ka'e jivna le pruce

{.experimental: "strictFuncs".}

import std/[asyncdispatch, asynchttpserver, os, osproc, strutils, tables, times]
from std/posix import EINTR, Pid, SIGKILL, errno, kill, waitpid


type RunPage* = object  ## lo selsku be lo papri ca pa nu cipra
  lines*: seq[string]  ## ro linji poi le papri cu cusku ke'a ku'o ta'i le porsi
  posted*: Table[string, string]
    ## ro datnyvei poi le papri cu benji ke'a fi lo judri ku'o ta'i le judri
  code*: int
    ## le famna'u pe le papri
    ##   .i le namcu cu du li ni'u 1 va'o lo nu le papri cu cusku no fanmo pu le rairtei
  is_done*: bool  ## le papri pu cusku lo fanmo be vo'a


const  # lo stodi pe le minde po'u `drive`
  VARIABLE_CHROMIUM* = "LOJBAN_CHROMIUM"
    ## lo datnyvau poi cmene `Chromium` poi seltro
  TIMEOUT_PAGE = initDuration(seconds = 300)
    ## le rairtei be pa nu cipra
    ##   .i lo cipra poi fasnu ne'i lo tcidu be lo papri cu fasnu ze'a lo temci poi jibni `20 s`
    ##   .i ro le cipra cu mulno
  ADDRESS_LOOPBACK = "127.0.0.1"
    ## le judri poi le samtci cu denpa lo nu cpedu bu'u ke'a ku'o zi'e noi no datskami cu ka'e klama
    ##     ke'a
  BODY_MOST = 1 shl 26
    ## le jimte be lo stuzi pe pa nu cpedu pe lo papri
    ##   .i lo selbe'i be le crepu cu vasru ro lertai poi le papri cu bevri ke'a
  FLAGS_CHROMIUM = [
    "--headless", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage", "--no-first-run",
    "--no-default-browser-check", "--disable-extensions", "--mute-audio",
  ]
    ## lo selcu'a poi `Chromium` jitro le papri va'o ke'a
    ##   .i no canko cu zasti
    ##   .i `sandbox` noi `root` na ka'e pilno ke'a na selpli
    ##   .i no da poi na du le papri cu selpli
  TYPES_CONTENT = {
    ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
    ".json": "application/json", ".nif": "text/plain; charset=utf-8",
    ".text": "text/plain; charset=utf-8", ".woff2": "font/woff2", ".ttf": "font/ttf",
  }.toTable
    ## lo klesi be lo selvau pe ro fanmo be lo cmene be lo datnyvei poi le samtci cu sabji ke'a


when defined(linux):
  let OPTION_SUBREAPER {.importc: "PR_SET_CHILD_SUBREAPER", header: "<sys/prctl.h>".}: cint
    ## lo selcu'a pe `prctl` ge'u zi'e poi rinka lo nu le vi pruce cu kurji ro pruce poi selkra le
    ##     vi pruce ku'o zi'e poi lo rirni be ke'a cu morsi
  proc prctl(option: cint, value: culong): cint {.importc, header: "<sys/prctl.h>".}
    ## galfi pa selkai be le vi pruce
    ##   .i le fancu cu korbi `Nim` `C`
    ##   .i `glibc` skicu le fancu fo zoi gy. variadic .gy.
    ##   .i `OPTION_SUBREAPER` tcidu pa namcu po'o
    ##   .i se ki'u bo le nu pilno le fancu cu benji re sumti



proc answerRequest(
  run: ref RunPage, request: Request, page, root: string, headers: seq[(string, string)]
) {.async.} =
  ## spuda pa nu cpedu pe le papri
  ##   .i dunda le papri bu'u `/` sepi'o `headers` gi'a dunda pa datnyvei pe le vasru sepi'o lo
  ##       judri gi'a ralte lo selsku be le papri
  let path = request.url.path
  if request.reqMethod == HttpPost:
    case path
    of "/log": run.lines.add request.body
    of "/done":
      run.code = (try: request.body.strip.parseInt except ValueError: 1)
      run.is_done = true
    else: run.posted[path] = request.body
    await request.respond(Http204, "")
    return
  if path == "/":
    let fields = newHttpHeaders({"Content-Type": TYPES_CONTENT[".html"]})
    for (name, value) in headers: fields[name] = value
    await request.respond(Http200, page, fields)
    return
  let file = root / path.strip(leading = true, trailing = false, chars = {'/'})
  if ".." in path or not file.fileExists:
    await request.respond(Http404, "")
    return
  let kind = TYPES_CONTENT.getOrDefault(file.splitFile.ext, "application/octet-stream")
  await request.respond(Http200, file.readFile, newHttpHeaders({"Content-Type": kind}))


proc serve(
  server: AsyncHttpServer, run: ref RunPage, page, root: string, headers: seq[(string, string)]
) {.async.} =
  ## spuda ro nu cpedu pe le papri ca lo nu le nu cpedu cu klama kei pu lo nu le papri cu cusku lo
  ##     fanmo be vo'a
  ##   .i `acceptRequest` denpa lo nu jorne poi bavla'i
  ##   .i se ki'u bo no nu denpa lo temci poi stodi cu zvati vi to `IX.12` toi
  ##   .i va'o lo nu le nu cipra cu sisti le sabji ca lo nu `acceptRequest` denpa kei kei
  ##       `acceptRequest` fliba gi'e sisti lo nu sabji kei ki'u lo nu le papri pu cusku lo fanmo be
  ##       vo'a kei .a lo nu le nu cipra cu pu zmadu le rairtei
  while not run.is_done:
    try:
      await server.acceptRequest(proc(request: Request) {.async.} =
        await run.answerRequest(request, page, root, headers))
    except OSError: return


proc endGroup(process: Process) =
  ## catra ro pruce pe le girzu poi `Chromium` jatna ke'a ku'o gi'e cpacu lo fanmo be ro le pruce ba
  ##     lo nu catra
  ##   .i se ki'u bo no pruce cu ciska fi le vreji ba lo nu cpacu lo fanmo
  ##   .i lo nu cpacu lo fanmo cu sisti va'o `ECHILD` noi fasnu ca lo nu le girzu cu vasru no pruce
  ##   .i va'o lo nu pa sinxa cu rinka lo nu le nu cpacu cu sisti kei le fancu cu rapyde'a
  let group = Pid(-process.processID)
  discard kill(group, SIGKILL)
  discard process.waitForExit()
  var status: cint
  while waitpid(group, status, 0) > 0 or errno == EINTR: discard
  process.close()


proc runPage*(
  chromium, page, root: string, headers: openArray[(string, string)] = []
): RunPage =
  ## sabji le papri bu'u `/` sepi'o `headers` gi'e sabji ro datnyvei poi zvati le vasru po'u `root`
  ##     ku'o bu'u lo judri be le datnyvei
  ##   .i rinka lo nu `Chromium` cfari bu'u le papri
  ##   .i jarco lo selsku be le papri ca lo nu le papri cu cusku lo fanmo be vo'a kei .a lo nu le
  ##       rairtei cu mulno
  let
    run = new RunPage
    server = newAsyncHttpServer(maxBody = BODY_MOST)
    profile = root / "profile"
  run.code = -1
  when defined(linux):
    if prctl(OPTION_SUBREAPER, 1) != 0: raiseOSError(osLastError())
  server.listen(Port(0), ADDRESS_LOOPBACK)
  removeDir(profile)
  createDir(profile)
  let
    address = "http://" & ADDRESS_LOOPBACK & ":" & $int(server.getPort) & "/"
    process = startProcess(
      chromium, args = @FLAGS_CHROMIUM & @["--user-data-dir=" & profile, address],
      # ne'i `POSIX` `poDaemon` rinka lo nu le pruce cu jatna pa girzu pe vo'a
      options = {poStdErrToStdOut, poDaemon},
    )
    start = now()
  asyncCheck server.serve(run, page, root, @headers)
  while not run.is_done and now() - start < TIMEOUT_PAGE and process.running: poll(20)
  process.endGroup()
  server.close()
  removeDir(profile)
  if not run.is_done:
    run.lines.add "Page should report its end before " & $TIMEOUT_PAGE & "; got none."
  run[]
