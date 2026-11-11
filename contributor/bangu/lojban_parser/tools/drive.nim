## Drive page in headless Chromium from Nim, as backend of each check that runs in browser: serve
##   page and folder of build on port of loopback, start Chromium on page, and give each line page
##   reports, each file it posts, and code it exits with. No node runs it, and backend is Nim, as
##   Architect ruled on #859.
##
##   |---------|---------------------------------------------------------------------------|
##   | Code    | Meaning                                                                   |
##   |---------|---------------------------------------------------------------------------|
##   | runPage | serve page and folder, drive Chromium on page, give what page reports     |
##   |---------|---------------------------------------------------------------------------|
##
##   Page reports through requests of its own, each string of its own: `POST /log` adds line,
##     `POST /done` ends run with exit code, and `POST` of any other path posts file of that name.
##     So no format of data stands between page and backend (CONTRIBUTOR.md, Data).
##   Chromium is one `LOJBAN_CHROMIUM` names, full Chrome or its headless shell, else headless
##     shell store of repository serves by digest (`browser.nim`, #864); page runs in profile of
##     its own, which run removes.
##   Chromium leads group of its own, and run kills each process of group, then reaps each,
##     before it removes profile: processes of Chromium write profile after first one exits, as
##     full Chrome writes `TransportSecurity` (`test_drive.nim`). Kill, since profile goes, and
##     full Chrome may hang in shutdown `SIGTERM` asks. This process is subreaper (`prctl(2)`),
##     so each orphan of Chromium comes to it, and each wait here is on death, never on time.
##   Run that reports no end before `TIMEOUT_PAGE` fails, as page that hangs or throws before its
##     reporter loads: ceiling far above measured run, and far below hang.
##   Rejected: Playwright, whose API runs under node (ruling on #859), and protocol of DevTools,
##     which page that reports through requests does not need.
##   Cost: elsewhere than Linux, orphan of Chromium goes to init, so removal of profile may race
##     with it.

{.experimental: "strictFuncs".}

import std/[asyncdispatch, asynchttpserver, os, osproc, strutils, tables, times]
from std/posix import EINTR, Pid, SIGKILL, errno, kill, waitpid


type RunPage* = object  ## Define what page reported in one run.
  lines*: seq[string]  ## Each line page reported, in order.
  posted*: Table[string, string]  ## Each file page posted, by path it posted to.
  code*: int  ## Code page exited with; -1 where it reported no end before ceiling.
  is_done*: bool  ## Page reported its end.


const
  VARIABLE_CHROMIUM* = "LOJBAN_CHROMIUM"  ## Variable naming Chromium to drive.
  TIMEOUT_PAGE = initDuration(seconds = 300)
    ## Ceiling of one run; suites of browser run in about 20 s, and hang in none.
  ADDRESS_LOOPBACK = "127.0.0.1"  ## Address backend listens on, which no other machine reaches.
  BODY_MOST = 1 shl 26
    ## Bytes request of page holds at most: what collector posts holds each font face page ships.
  FLAGS_CHROMIUM = [
    "--headless", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage", "--no-first-run",
    "--no-default-browser-check", "--disable-extensions", "--mute-audio",
  ]
    ## Flags Chromium runs page under: no window, sandbox of no root, and nothing beyond page.
  TYPES_CONTENT = {
    ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
    ".json": "application/json", ".nif": "text/plain; charset=utf-8",
    ".text": "text/plain; charset=utf-8", ".woff2": "font/woff2", ".ttf": "font/ttf",
  }.toTable
    ## Type of content of each extension of file backend serves.


when defined(linux):
  let OPTION_SUBREAPER {.importc: "PR_SET_CHILD_SUBREAPER", header: "<sys/prctl.h>".}: cint
    ## Option of `prctl` that makes this process reaper of each orphan of its descendants.
  proc prctl(option: cint, value: culong): cint {.importc, header: "<sys/prctl.h>".}
    ## Set attribute of this process. Boundary of C target: glibc declares it variadic, and
    ##   `OPTION_SUBREAPER` reads one value alone, so call passes two arguments.



proc answerRequest(
  run: ref RunPage, request: Request, page, root: string, headers: seq[(string, string)]
) {.async.} =
  ## Answer one request of page: page at `/`, with its headers, file of folder by path, or report
  ##   of page.
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
  ## Answer each request of page as it comes, till page reports its end: accept waits on next
  ##   connection, so no wait of fixed time stands here (IX.12). Accept that waits when run
  ##   closes server fails, and ends serving, since page reported its end, or run passed ceiling.
  while not run.is_done:
    try:
      await server.acceptRequest(proc(request: Request) {.async.} =
        await run.answerRequest(request, page, root, headers))
    except OSError: return


proc endGroup(process: Process) =
  ## Kill each process of group Chromium leads, then reap each, so none writes profile after.
  ##   Reaping ends on `ECHILD`, once group holds no process; signal that interrupts it waits on.
  let group = Pid(-process.processID)
  discard kill(group, SIGKILL)
  discard process.waitForExit()
  var status: cint
  while waitpid(group, status, 0) > 0 or errno == EINTR: discard
  process.close()


proc runPage*(
  chromium, page, root: string, headers: openArray[(string, string)] = []
): RunPage =
  ## Serve page at `/`, with `headers`, and each file under folder `root` by its path, start
  ##   Chromium on page, and give what page reports once it reports its end, or once ceiling
  ##   passes.
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
      options = {poStdErrToStdOut, poDaemon},  # `poDaemon` starts group of its own on POSIX
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
