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
##   Chromium is one `LOJBAN_CHROMIUM` names, else `chrome-headless-shell` of Chrome for Testing,
##     pinned by digest (`VERSION_CHROMIUM`); page runs in profile of its own, which run removes.
##   Run that reports no end before `TIMEOUT_PAGE` fails, as page that hangs or throws before its
##     reporter loads: ceiling far above measured run, and far below hang.
##   Rejected: Playwright, whose API runs under node (ruling on #859), and protocol of DevTools,
##     which page that reports through requests does not need.

{.experimental: "strictFuncs".}

import std/[asyncdispatch, asynchttpserver, os, osproc, strutils, tables, times]


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



proc answerRequest(run: ref RunPage, request: Request, page, root: string) {.async.} =
  ## Answer one request of page: page at `/`, file of folder by path, or report of page.
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
    await request.respond(Http200, page, newHttpHeaders({"Content-Type": TYPES_CONTENT[".html"]}))
    return
  let file = root / path.strip(leading = true, trailing = false, chars = {'/'})
  if ".." in path or not file.fileExists:
    await request.respond(Http404, "")
    return
  let kind = TYPES_CONTENT.getOrDefault(file.splitFile.ext, "application/octet-stream")
  await request.respond(Http200, file.readFile, newHttpHeaders({"Content-Type": kind}))


proc serve(server: AsyncHttpServer, run: ref RunPage, page, root: string) {.async.} =
  ## Answer each request of page as it comes, till page reports its end: accept waits on next
  ##   connection, so no wait of fixed time stands here (IX.12). Accept that waits when run
  ##   closes server fails, and ends serving, since page reported its end, or run passed ceiling.
  while not run.is_done:
    try:
      await server.acceptRequest(proc(request: Request) {.async.} =
        await run.answerRequest(request, page, root))
    except OSError: return


proc runPage*(chromium, page, root: string): RunPage =
  ## Serve page at `/` and each file under folder `root` by its path, start Chromium on page, and
  ##   give what page reports once it reports its end, or once ceiling passes.
  let
    run = new RunPage
    server = newAsyncHttpServer()
    profile = root / "profile"
  run.code = -1
  server.listen(Port(0), ADDRESS_LOOPBACK)
  removeDir(profile)
  createDir(profile)
  let
    address = "http://" & ADDRESS_LOOPBACK & ":" & $server.getPort.int & "/"
    process = startProcess(
      chromium, args = @FLAGS_CHROMIUM & @["--user-data-dir=" & profile, address],
      options = {poStdErrToStdOut},
    )
    start = now()
  asyncCheck server.serve(run, page, root)
  while not run.is_done and now() - start < TIMEOUT_PAGE and process.running: poll(20)
  process.terminate()
  discard process.waitForExit()
  process.close()
  server.close()
  removeDir(profile)
  if not run.is_done:
    run.lines.add "Page should report its end before " & $TIMEOUT_PAGE & "; got none."
  run[]
