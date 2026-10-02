## Replicate waits check: fixed wait in drive code reported, by kind and by place.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, kinds, waits]


const
  DIRECTORIES = ["contributor/ronri/viewer"]
  NIM_DRIVE = """
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
  TYPESCRIPT_DRIVE = """
// page.waitForTimeout(5) in comment is unread.
await page.waitForTimeout(300);
const sleep = (milliseconds: number) => new Promise((done) => setTimeout(done, milliseconds));
await sleep(50);
"""



suite "Internal":
  test "drive code is read under tests and tools of each project":
    check "contributor/ronri/viewer/tests/test_view.nim".isDriveCode(DIRECTORIES)
    check "contributor/ronri/viewer/tools/drive/main.ts".isDriveCode(DIRECTORIES)
    check not "contributor/ronri/viewer/src/view.nim".isDriveCode(DIRECTORIES)
    check not "contributor/ronri/viewer/design/shot.nim".isDriveCode(DIRECTORIES)
    check not "contributor/ronri/other/tests/test_view.nim".isDriveCode(DIRECTORIES)


  test "Nim fixed wait reported in every call form, as Nim compares names":
    let found = checkWaits("viewer/tests/test_view.nim", NIM_DRIVE, Kind.Nim)
    check found.mapIt(it.line) == @[4, 5, 6, 9]  # comment, string and `sleeper` unread
    check found.allIt("Article IX.12" in it.message)
    check found[2].message.contains("got `sleep_async`")
    check found[3].message.contains("clock.runFor")


  test "TypeScript fixed wait reported, and drive's own sleep helper left alone":
    let found = checkWaits("viewer/tools/drive/main.ts", TYPESCRIPT_DRIVE, Kind.TypeScript)
    check found.mapIt(it.line) == @[2]  # line 1 is comment; line 4 helper rides page's clock


  test "document is never read":
    check checkWaits("viewer/tests/README.md", "Never `waitForTimeout(5)`.", Kind.Markdown)
      .len == 0
