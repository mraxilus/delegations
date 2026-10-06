## Replicate waits check as koch prints it: fixed wait in drive code reported, by kind and by
##   place, article where sentence ends. Nim cases of rule itself are held in
##   `curator/knoller/tests/suites/test_waits.nim`.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/[findings, kinds, waits]


const
  DIRECTORIES = ["contributor/ronri/viewer"]
  NIM_DRIVE = """
proc settle(page: Page) {.async.} =
  sleep(50)
  # sleep(5) in comment is unread.
  await page.waitForTimeout(300)
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


  test "Nim fixed wait reads as koch prints it, article where sentence ends":
    let found = checkWaits("viewer/tests/test_view.nim", NIM_DRIVE, Kind.Nim)
    check found.mapIt(it.line) == @[2, 4]  # comment unread
    check found.mapIt(it.message) == @[
      "Fixed wait reads real clock; wait on condition, or advance clock check moves (IX.12); " &
      "got `sleep`.",
      "Fixed wait reads real clock; wait on condition, or move page's clock with " &
      "`clock.runFor` (IX.12); got `waitForTimeout`.",
    ]
    check checkWaits("viewer/tests/a.nims", "sleep(1)\n", Kind.NimScript).len == 1  # every Nim


  test "TypeScript fixed wait reported, and drive's own sleep helper left alone":
    let found = checkWaits("viewer/tools/drive/main.ts", TYPESCRIPT_DRIVE, Kind.TypeScript)
    check found.mapIt(it.line) == @[2]  # line 1 is comment; line 4 helper rides page's clock
    check found[0].message == "Fixed wait reads real clock; wait on condition, or move page's " &
        "clock with `clock.runFor` (IX.12); got `waitForTimeout`."  # same words as Nim


  test "document is never read":
    check checkWaits("viewer/tests/README.md", "Never `waitForTimeout(5)`.", Kind.Markdown)
      .len == 0
