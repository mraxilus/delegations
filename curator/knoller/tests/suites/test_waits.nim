## Replicate Article IX.12 as `waits.nim` reads it: fixed wait in drive code reported, as Nim
##   compares names in Nim source, and exactly in lines other syntax passes.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/[reports, waits]


const DRIVE_NIM = """
import std/[asyncdispatch, os]

proc settle(page: Page) {.async.} =
  sleep(50)
  os.sleep 10
  await sleep_async(20)
  # sleep(5) in comment is unread.
  echo "sleep(5) in string is unread"
  await page.waitForTimeout(300)
  let sleeper = 1
"""
  ## Nim drive calling each fixed wait in each call form, beside comment, string and name.



suite "Article IX":
  test "IX.12 Nim fixed wait reported in every call form, as Nim compares names":
    let found = checkWaits("viewer/tests/test_view.nim", DRIVE_NIM)
    check found.mapIt(it.line) == @[4, 5, 6, 9]  # comment, string and `sleeper` unread
    check found.allIt(it.rule == Rule.FixedWait)
    check found.mapIt(it.message) == @[
      "Fixed wait reads real clock; wait on condition, or advance clock check moves; got `sleep`.",
      "Fixed wait reads real clock; wait on condition, or advance clock check moves; got `sleep`.",
      "Fixed wait reads real clock; wait on condition, or advance clock check moves; got " &
      "`sleep_async`.",
      "Fixed wait reads real clock; wait on condition, or move page's clock with " &
      "`clock.runFor`; got `waitForTimeout`.",
    ]  # value echoed as written, replacement of name it compares to
    check checkWaits("a.nim", "let sléep = 1\nlet x = Sleep\n").len == 0  # other names


  test "IX.12 lines other syntax passes read Playwright's name alone, exactly":
    let found = checkWaits("main.ts", @[@["await", "page", "waitForTimeout"], @["sleep"]],
      is_nim = false)
    check found.mapIt((it.line, it.rule)) == @[(1, Rule.FixedWait)]  # drive's own `sleep` unread
    check checkWaits("main.ts", @[@["wait_for_timeout"]], is_nim = false).len == 0  # exact
    check checkWaits("a.nim", @[@["wait_for_timeout"]], is_nim = true).len == 1  # Nim compares
