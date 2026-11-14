## jitro lo papri ne'i la'o gy. headless Chromium .gy. sepi'o la'o gy. Nim .gy. ta'i le samtci pe
##   ro cipra poi fasnu ne'i lo tcidu be lo papri .i sabji le papri .e lo vasru be lo se zbasu bu'u
##   pa vorme pe la'o gy. loopback .gy. .i rinka lo nu la'o gy. Chromium .gy. cu cfari bu'u le papri
##   .i jarco ro linji poi le papri cu cusku ke'a ku'o .e ro datnyvei poi le papri cu benji ke'a
##   ku'o .e le fanmo namcu pe le papri .i la'o gy. node .gy. na jitro le samtci .i le samtci cu se
##   ciska fi la'o gy. Nim .gy. .i la'o gy. Architect .gy. cu jdice di'u bu'u `#859`
##
##   |-----------|----------------------------------------------------------------------------|
##   | lo cmene  | lo smuni                                                                   |
##   |-----------|----------------------------------------------------------------------------|
##   | `runPage` | sabji le papri .e le vasru gi'e jitro la'o gy. Chromium .gy. bu'u le papri |
##   |           | .i jarco lo se cusku be le papri                                           |
##   |-----------|----------------------------------------------------------------------------|
##
##   le papri cu cusku sepi'o lo nu cpedu pe vo'a .i ro le nu cpedu cu vasru pa lerpoi pe vo'a
##     .i `POST /log` cu jmina pa linji .i `POST /done` cu sisti le nu cipra sepi'o le fanmo
##     namcu .i `POST` fi ro drata judri cu benji pa datnyvei poi se cmene le judri .i se ki'u bo
##     no tarmi be lo datni cu zvati lo jbini be le papri .e le samtci pe la'o gy. Nim .gy. to
##     `CONTRIBUTOR.md, Data` toi
##   .i la'o gy. Chromium .gy. poi se pilno cu du lo tcidu be lo papri be'o poi `LOJBAN_CHROMIUM`
##     cu cmene ke'a .i le tcidu cu ka'e du la'o gy. Chrome .gy. noi mulno .a `headless shell` pe
##     la'o gy. Chrome .gy. .i va'o lo drata la'o gy. Chromium .gy. poi se pilno cu du
##     `headless shell` poi lo sorcu pe la'o gy. delegations .gy. cu sabji ke'a sepi'o lo sinxa
##     namcu to `browser.nim` toi .i le papri cu fasnu ne'i pa vreji pe vo'a ge'u zi'e noi le nu
##     cipra cu vimcu ke'a
##   .i la'o gy. Chromium .gy. cu jatna pa girzu pe vo'a .i le nu cipra cu catra ro pruce pe le
##     girzu gi'e cpacu lo fanmo be ro le pruce ba lo nu catra .i le nu cipra cu vimcu le vreji ba
##     lo nu cpacu lo fanmo be ro le pruce .i ki'u bo lo pruce pe la'o gy. Chromium .gy. cu ciska
##     fi le vreji ba lo nu le pamoi pruce cu sisti kei mu'u lo nu la'o gy. Chrome .gy. noi mulno
##     cu ciska `TransportSecurity` to `test_drive.nim` toi .i le nu cipra cu catra ki'u lo nu le
##     vreji cu se vimcu kei .e lo nu la'o gy. Chrome .gy. noi mulno cu ka'e stali ne'i lo nu
##     sisti poi `SIGTERM` cu cpedu ke'a .i le vi pruce cu kurji ro pruce poi se krasi le vi pruce
##     ku'o ta'i la'o gy. subreaper .gy. to `prctl(2)` toi .i se ki'u bo ro pruce pe
##     la'o gy. Chromium .gy. ge'u zi'e poi lo rirni be ke'a cu morsi cu klama le vi pruce .i ro nu
##     denpa vi cu nu denpa lo nu morsi .i no nu denpa vi cu nu denpa lo temci
##   .i lo nu cipra poi cusku no fanmo pu `TIMEOUT_PAGE` cu fliba mu'u lo papri poi no roi mulno
##     gi'a renro lo srera pu lo nu le cusku pe ke'a cu se cpacu .i `TIMEOUT_PAGE` cu mutce zmadu
##     lo temci be lo nu cipra poi se merli gi'e mutce mleca lo temci be lo nu no roi mulno
##   .i se to'e cuxna fa la'o gy. Playwright .gy. noi la'o gy. API .gy. pe ke'a cu fasnu ne'i
##     la'o gy. node .gy. to la'o gy. Architect .gy. cu jdice bu'u `#859` toi ku'o .e lo tavla
##     javni pe la'o gy. DevTools .gy. ge'u zi'e noi lo papri poi cusku sepi'o lo nu cpedu cu na
##     nitcu ke'a
##   .i jdima fa lo nu va'o lo nu la'o gy. Linux .gy. na se pilno kei pa pruce pe
##     la'o gy. Chromium .gy. ge'u zi'e poi lo rirni be ke'a cu morsi cu klama la'o gy. init .gy.
##     .i se ki'u bo lo nu vimcu le vreji cu ka'e jivna le pruce

{.experimental: "strictFuncs".}

import std/[asyncdispatch, asynchttpserver, os, osproc, strutils, tables, times]
from std/posix import EINTR, Pid, SIGKILL, errno, kill, waitpid


type RunPage* = object  ## lo se cusku be lo papri ca pa nu cipra
  lines*: seq[string]  ## ro linji poi le papri cu cusku ke'a ku'o ta'i le porsi
  posted*: Table[string, string]
    ## ro datnyvei poi le papri cu benji ke'a fi lo judri ku'o ta'i le judri
  code*: int
    ## le fanmo namcu pe le papri .i le namcu cu du li ni'u pa va'o lo nu le papri cu cusku no
    ##   fanmo pu le traji temci
  is_done*: bool  ## le papri pu cusku lo fanmo be vo'a


const
  VARIABLE_CHROMIUM* = "LOJBAN_CHROMIUM"
    ## lo datnyvau poi cmene la'o gy. Chromium .gy. poi se jitro
  TIMEOUT_PAGE = initDuration(seconds = 300)
    ## le traji temci be pa nu cipra .i lo cipra poi fasnu ne'i lo tcidu be lo papri cu fasnu
    ##   ze'a lo temci poi jibni `20 s` .i ro le cipra cu mulno
  ADDRESS_LOOPBACK = "127.0.0.1"
    ## le judri poi le samtci cu denpa lo nu cpedu bu'u ke'a ku'o zi'e noi no drata skami cu ka'e
    ##   klama ke'a
  BODY_MOST = 1 shl 26
    ## le jimte be lo stuzi pe pa nu cpedu pe lo papri .i lo se benji be le crepu cu vasru ro
    ##   lerfu tarmi poi le papri cu bevri ke'a
  FLAGS_CHROMIUM = [
    "--headless", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage", "--no-first-run",
    "--no-default-browser-check", "--disable-extensions", "--mute-audio",
  ]
    ## lo se cuxna poi la'o gy. Chromium .gy. cu jitro le papri va'o ke'a .i no canko cu zasti
    ##   .i la'o gy. sandbox .gy. noi la'o gy. root .gy. na ka'e pilno ke'a cu na se pilno .i no da
    ##   poi na du le papri cu se pilno
  TYPES_CONTENT = {
    ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
    ".json": "application/json", ".nif": "text/plain; charset=utf-8",
    ".text": "text/plain; charset=utf-8", ".woff2": "font/woff2", ".ttf": "font/ttf",
  }.toTable
    ## lo klesi be lo se vasru pe ro fanmo be lo cmene be lo datnyvei poi le samtci cu sabji ke'a


when defined(linux):
  let OPTION_SUBREAPER {.importc: "PR_SET_CHILD_SUBREAPER", header: "<sys/prctl.h>".}: cint
    ## lo se cuxna pe `prctl` ge'u zi'e poi rinka lo nu le vi pruce cu kurji ro pruce poi se krasi
    ##   le vi pruce ku'o zi'e poi lo rirni be ke'a cu morsi
  proc prctl(option: cint, value: culong): cint {.importc, header: "<sys/prctl.h>".}
    ## galfi pa se ckaji be le vi pruce .i le fancu cu korbi la'o gy. Nim .gy. la'o gy. C .gy.
    ##   .i la'o gy. glibc .gy. cu skicu le fancu fo zoi gy. variadic .gy. .i `OPTION_SUBREAPER` cu
    ##   tcidu pa namcu po'o .i se ki'u bo le nu pilno le fancu cu benji re sumti



proc answerRequest(
  run: ref RunPage, request: Request, page, root: string, headers: seq[(string, string)]
) {.async.} =
  ## spuda pa nu cpedu pe le papri .i dunda le papri bu'u `/` sepi'o `headers` gi'a dunda pa
  ##   datnyvei pe le vasru sepi'o lo judri gi'a ralte lo se cusku be le papri
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
  ## spuda ro nu cpedu pe le papri ca lo nu le nu cpedu cu klama kei pu lo nu le papri cu cusku
  ##   lo fanmo be vo'a .i `acceptRequest` cu denpa lo nu jorne poi bavla'i .i se ki'u bo no nu
  ##   denpa lo temci poi stodi cu zvati vi to `IX.12` toi .i va'o lo nu le nu cipra cu sisti le
  ##   sabji ca lo nu `acceptRequest` cu denpa kei `acceptRequest` cu fliba gi'e sisti lo nu sabji
  ##   kei ki'u lo nu le papri pu cusku lo fanmo be vo'a kei .a lo nu le nu cipra pu zmadu le traji
  ##   temci
  while not run.is_done:
    try:
      await server.acceptRequest(proc(request: Request) {.async.} =
        await run.answerRequest(request, page, root, headers))
    except OSError: return


proc endGroup(process: Process) =
  ## catra ro pruce pe le girzu poi la'o gy. Chromium .gy. cu jatna ke'a ku'o gi'e cpacu lo fanmo
  ##   be ro le pruce ba lo nu catra .i se ki'u bo no pruce cu ciska fi le vreji ba lo nu cpacu lo
  ##   fanmo .i lo nu cpacu lo fanmo cu sisti va'o `ECHILD` noi fasnu ca lo nu le girzu cu vasru no
  ##   pruce .i va'o lo nu pa sinxa cu rinka lo nu le nu cpacu cu sisti kei le fancu cu rapli denpa
  let group = Pid(-process.processID)
  discard kill(group, SIGKILL)
  discard process.waitForExit()
  var status: cint
  while waitpid(group, status, 0) > 0 or errno == EINTR: discard
  process.close()


proc runPage*(
  chromium, page, root: string, headers: openArray[(string, string)] = []
): RunPage =
  ## sabji le papri bu'u `/` sepi'o `headers` gi'e sabji ro datnyvei poi zvati le vasru po'u
  ##   `root` ku'o bu'u lo judri be le datnyvei .i rinka lo nu la'o gy. Chromium .gy. cu cfari bu'u
  ##   le papri .i jarco lo se cusku be le papri ca lo nu le papri cu cusku lo fanmo be vo'a kei .a
  ##   lo nu le traji temci cu mulno
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
      # ne'i la'o gy. POSIX .gy. `poDaemon` cu rinka lo nu le pruce cu jatna pa girzu pe vo'a
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
