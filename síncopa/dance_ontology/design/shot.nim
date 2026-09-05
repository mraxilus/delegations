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
##   Chromium and playwright are pre-installed in remote environment at
##     paths below; elsewhere, point both constants at your own.

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi]


const
  PLAYWRIGHT = "/opt/node22/lib/node_modules/playwright"
  CHROMIUM = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"


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


proc shoot() {.async.} =
  ## Open page in each theme and write one full-length screenshot.
  let
    page_file = jsString(process.argv[2])
    prefix = jsString(process.argv[3])
    url = cstring("file://" & $resolve(page_file))
    chromium = require(PLAYWRIGHT).chromium
    browser = await chromium.launch(
      JsObject{executablePath: cstring(CHROMIUM)}).to(Future[JsObject])
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
