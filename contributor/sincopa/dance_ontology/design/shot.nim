## Screenshot one marks page, light and dark, full length.
##
##   Animations only exist in browser, so any still build passing says
##     nothing about them; this is cheap half of checking they run (take
##     two shots one moment apart and diff them for expensive half).
##   Compiled to javascript and run under node, so workbench stays one
##     language:
##       nim js --hints:off -d:nodejs -o:build/design/shot.js design/shot.nim
##       node build/design/shot.js build/design/frames.html /tmp/frames
##     Cost of port: one page of foreign-function glue for thirty lines of
##       work.  Accepted -- one language in repo is worth one page.
##   Neither playwright nor chromium is named by path here: path names one
##     machine's layout, and browser version inside one pins in least
##     durable place there is (repository issue 62).  Both come from
##     environment, falling back to what `tools/build.nim system` declares,
##     and absent playwright stops naming that verb rather than as missing
##     file.

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi]


const
  PLAYWRIGHT = "playwright"
    ## Module node resolves for itself, where environment names none.
  ENV_PLAYWRIGHT = "DANCE_PLAYWRIGHT"
    ## Names playwright outright, for install node cannot resolve -- global
    ##   one, which is where package manager puts it.
  ENV_CHROMIUM = "DANCE_CHROMIUM"
    ## Names browser outright, for chromium other than playwright's own.
  ENV_BROWSERS = "PLAYWRIGHT_BROWSERS_PATH"
    ## Playwright's own store, which usually holds `chromium` beside its
    ##   numbered builds.  Where it does not, playwright resolves its own
    ##   from that same variable, so nothing here knows its layout.


proc require(module: cstring): JsObject {.importjs: "require(#)".}
  ## Load node module; compiler has no reason to know what is inside.

var process {.importjs: "process", nodecl.}: JsObject
  ## Node process, for its command line.

proc resolve(path: cstring): cstring {.importjs: "require('path').resolve(#)".}
  ## Make path absolute, as file url needs.

proc jsString(s: JsObject): cstring {.importjs: "String(#)".}
  ## Read javascript value as string it already is.

proc gotoUrl(page: JsObject; url: cstring): JsObject {.importjs: "#.goto(#)".}
  ## Navigate page; `goto` is reserved word that bridge would mangle.

proc envNamed(name: cstring): cstring {.importjs: "(process.env[#] || '')".}
  ## Read environment variable, empty where it is unset.

proc isThere(path: cstring): bool {.importjs: "require('fs').existsSync(#)".}
  ## Test whether path is there, so fallback is checked before it is used.

proc joined(base, name: cstring): cstring
    {.importjs: "require('path').join(#, #)".}
  ## Join path parts, as host spells them.

proc report(message: cstring) {.importjs: "console.error(#)".}
  ## Write finding where caller reads it.

proc stop(code: int) {.importjs: "process.exit(#)".}
  ## Leave with this exit code.


proc playwrightFrom(): cstring =
  ## Get where playwright is loaded from.
  let named = envNamed(ENV_PLAYWRIGHT)
  if named.len > 0: named else: cstring(PLAYWRIGHT)


proc chromiumFrom(): cstring =
  ## Get browser to drive, or nothing where playwright resolves its own.
  ##   Environment names one outright; failing that, playwright's own store
  ##     usually holds `chromium` beside its numbered builds.  Absent both,
  ##     playwright is left to find what it installed.
  let named = envNamed(ENV_CHROMIUM)
  if named.len > 0: return named
  let store = envNamed(ENV_BROWSERS)
  if store.len == 0: return cstring("")
  let beside = joined(store, cstring("chromium"))
  if isThere(beside): beside else: cstring("")


proc playwright(): JsObject =
  ## Load playwright, or stop naming what installs it.
  let at = playwrightFrom()
  try:
    result = require(at)
  except:
    report(cstring("Cannot load playwright from `" & $at & "`; install what " &
      "`nim r tools/build.nim system` names, or point `" & ENV_PLAYWRIGHT &
      "` at it."))
    stop(1)


proc shoot() {.async.} =
  ## Open page in each theme and write one full-length screenshot.
  let
    page_file = jsString(process.argv[2])
    prefix = jsString(process.argv[3])
    url = cstring("file://" & $resolve(page_file))
    chromium = playwright().chromium
    named = chromiumFrom()
    # Playwright refuses empty path, so option is left out rather than handed
    # in empty wherever nothing in environment names browser.
    browser = await (if named.len > 0:
        chromium.launch(JsObject{executablePath: named})
      else: chromium.launch()).to(Future[JsObject])
  for theme in ["light", "dark"]:
    let page = await browser.newPage(JsObject{
      viewport: JsObject{width: 1000, height: 900},
      colorScheme: cstring(theme),
    }).to(Future[JsObject])
    discard await gotoUrl(page, url).to(Future[JsObject])
    discard await page.waitForTimeout(300).to(Future[JsObject])
    discard await page.screenshot(JsObject{
      path: cstring($prefix & "-" & theme & ".png"),
      fullPage: true,
    }).to(Future[JsObject])
    discard await page.close().to(Future[JsObject])
  discard await browser.close().to(Future[JsObject])


discard shoot()
