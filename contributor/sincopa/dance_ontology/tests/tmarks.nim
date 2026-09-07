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
import ../tools/title


const OUT = "build/design"
  ## Where pages land; ignored by git, created here.


suite "mark workbench":
  createDir(OUT)
  for i in 0 ..< PAGES.len:
    test PAGES[i].name:
      buildPage(i, OUT)
      let written = readFile(OUT / PAGES[i].name)
      check written.len > 0  # written and read back (IX.5)
      # Every page workbench writes is exploration, so every one carries mockup form and
      # none carries plain one: reader tells stood-behind page from mock-up before opening
      # either.  Asserted against constant, so title cannot drift while test still passes.
      check "<title>" & MOCKUP & " — " in written
      check "<title>" & WORK & " — " notin written
      # Rule 26 ranks move's stages, and markup can only rank them through
      # `keyTimes`: without it browser spreads frames evenly, so turn, settle and
      # reset all read at one speed.  Every animated element carries its own
      # clock, on every page, or none of that ranking survives being written out.
      check written.count("<animate") == written.count("keyTimes=")
