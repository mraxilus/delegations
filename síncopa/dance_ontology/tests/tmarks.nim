discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Drive mark workbench's build under testament: every gate, every page written and read back.
##   Debug build on purpose: workbench's `doAssert` gates are check (Article IX.6).

import std/[os, strutils, unittest]

import ../design/marks


const OUT = "build/design"
  ## Where pages land; ignored by git, created here.


suite "mark workbench":
  createDir(OUT)
  for i in 0 ..< PAGES.len:
    test PAGES[i].name:
      buildPage(i, OUT)
      let written = readFile(OUT / PAGES[i].name)
      check written.len > 0  # written and read back (IX.5)
      check "<title>" in written  # page carries its head
