## Drive one page in headless Chromium, served from loopback, and gather what page posts back.
##   Serve page at `/` and files of one root beside it, start Chromium on page, then wait until
##     page posts its end, Chromium exits, or `TIMEOUT_PAGE` passes.
##   Page reports through requests alone: `POST /log` adds line, `POST /done` ends run with exit
##     code, and `POST` to any other path keeps body under that path. So no shape of data stands
##     between page and Nim beyond text (CONTRIBUTOR.md, Data).
##   Sibling: `ricysoho/tools/drive.nim`, whose logic this file takes; each project drives its own
##     pages, as D1 on #1058 ruled (II.9). Fix to one is finished only when other is checked.
##
##   Chromium runs in process group of its own, so end of run kills every process of group, then
##     waits for each, then deletes profile directory.
##     Chromium writes into profile after its first process exits, so profile goes only after
##       group ends; sibling records same trap.
##   On Linux this process is subreaper (`prctl(2)`), so Chromium process whose parent died comes
##     here, and its wait ends.
##     Cost: elsewhere, such process goes to `init`, and can race delete of profile.
##   `TIMEOUT_PAGE` bounds page that never posts its end; every other wait is wait for exit, and
##     no wait is span of time alone.
##   Rejected: Playwright, which runs in Node; D1 on #859 chose drive in Nim for this domain.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[asyncdispatch, asynchttpserver, os, osproc, strutils, tables, times]
from std/posix import EINTR, Pid, SIGKILL, errno, kill, waitpid


type
  RunPage* = object  ## Define what page posted during one run.
    lines*: seq[string]  ## Each line page logged, in order.
    posted*: Table[string, string]  ## Body page posted, by path.
    code*: int  ## Exit code page posted with its end; -1 where none came.
    is_done*: bool  ## Page posted its end.


const
  TIMEOUT_PAGE = initDuration(seconds = 300)
    ## Longest run of one page: far above page that loads, far below run that hangs for good.
  ADDRESS_LOOPBACK = "127.0.0.1"  ## Address server binds; no other machine reaches it.
  BYTES_BODY_MAX = 1 shl 26  ## Largest body page may post, i.e. 64 MiB.
  FLAGS_CHROMIUM = [
    "--headless", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage", "--no-first-run",
    "--no-default-browser-check", "--disable-extensions", "--mute-audio",
  ]
    ## Flags of every run: headless, and no part of browser that page does not need.
  LUT_TYPE_BY_EXTENSION = {
    ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
    ".json": "application/json", ".woff2": "font/woff2", ".ttf": "font/ttf",
  }.toTable
    ## Media type of each file served beside page.


when defined(linux):
  let OPTION_SUBREAPER {.importc: "PR_SET_CHILD_SUBREAPER", header: "<sys/prctl.h>".}: cint
    ## Option of `prctl` that makes this process subreaper.
  proc prctl(option: cint, value: culong): cint {.importc, header: "<sys/prctl.h>".}
    ## Set option of this process.



#[ Server ]#

proc answerRequest(
  run: ref RunPage, request: Request, page, root: string, headers: seq[(string, string)]
) {.async.} =
  ## Answer one request: keep what page posts, serve page at `/`, serve file of root elsewhere.
  let path = request.url.path

  # Keep post of page: line, end, or body under its path.
  if request.reqMethod == HttpPost:
    case path
    of "/log": run.lines.add request.body
    of "/done":
      run.code = (try: request.body.strip.parseInt except ValueError: 1)
      run.is_done = true
    else: run.posted[path] = request.body
    await request.respond(Http204, "")
    return

  # Serve page itself, with headers run asks for.
  if path == "/":
    let fields = newHttpHeaders({"Content-Type": LUT_TYPE_BY_EXTENSION[".html"]})
    for (name, value) in headers: fields[name] = value
    await request.respond(Http200, page, fields)
    return

  # Serve file of root, never above it.
  let file = root / path.strip(leading = true, trailing = false, chars = {'/'})
  if ".." in path or not file.fileExists:
    await request.respond(Http404, "")
    return
  let kind = LUT_TYPE_BY_EXTENSION.getOrDefault(file.splitFile.ext, "application/octet-stream")
  await request.respond(Http200, file.readFile, newHttpHeaders({"Content-Type": kind}))


proc serve(
  server: AsyncHttpServer, run: ref RunPage, page, root: string, headers: seq[(string, string)]
) {.async.} =
  ## Answer requests until page posts its end, or server closes.
  while not run.is_done:
    try:
      await server.acceptRequest(proc(request: Request) {.async.} =
        await run.answerRequest(request, page, root, headers))
    except OSError: return



#[ Chromium ]#

proc endGroup(process: Process) =
  ## Kill each process of group of Chromium, and wait for each to exit.
  let group = Pid(-process.processID)
  discard kill(group, SIGKILL)
  discard process.waitForExit()
  var status: cint
  while waitpid(group, status, 0) > 0 or errno == EINTR: discard
  process.close()


proc runPage*(
  chromium, page, root: string, headers: openArray[(string, string)] = []
): RunPage =
  ## Serve page, run Chromium on it until it posts its end, and give what it posted.
  ##   Root holds files page may fetch, and profile of Chromium for this run alone.
  let
    run = new RunPage
    server = newAsyncHttpServer(maxBody = BYTES_BODY_MAX)
    profile = root / "profile"
  run.code = -1

  # Adopt orphan of Chromium, so wait for group reaches it.
  when defined(linux):
    if prctl(OPTION_SUBREAPER, 1) != 0: raiseOSError(osLastError())

  # Bind server on any free port, and start Chromium in group of its own on fresh profile.
  server.listen(Port(0), ADDRESS_LOOPBACK)
  removeDir(profile)
  createDir(profile)
  let
    address = "http://" & ADDRESS_LOOPBACK & ":" & $int(server.getPort) & "/"
    process = startProcess(
      chromium, args = @FLAGS_CHROMIUM & @["--user-data-dir=" & profile, address],
      options = {poStdErrToStdOut, poDaemon},  # `poDaemon` gives process group of its own.
    )
    start = now()

  # Answer page until it ends, Chromium exits, or time runs out; then end group, then profile.
  asyncCheck server.serve(run, page, root, @headers)
  while not run.is_done and now() - start < TIMEOUT_PAGE and process.running: poll(20)
  process.endGroup()
  server.close()
  removeDir(profile)
  if not run.is_done:
    run.lines.add "Page should report its end before " & $TIMEOUT_PAGE & "; got none."
  run[]
