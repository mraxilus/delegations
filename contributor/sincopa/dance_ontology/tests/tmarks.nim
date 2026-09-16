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
import ../design/rig_page
import ../tools/title


const OUT = "build/design"
  ## Where pages land; ignored by git, created here.

const SMALL = ["a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into",
               "nor", "of", "on", "or", "over", "so", "the", "to", "up", "with", "yet"]
  ## Words title case leaves lowercase where they fall inside title.

func titleCased(title: string): bool =
  ## Whether title reads in title case: every word capitalised but small ones inside it.
  ##   Read off words rather than off whole, so hyphenated word passes on its first letter
  ##     as `Hand-to-Hand` does, and punctuation decides nothing.
  let words = title.split(' ')
  for i, word in words:
    let bare = word.strip(chars = {',', '.', ':', ';', '!', '?'})
    if bare.len == 0 or bare[0].isUpperAscii: continue
    if i > 0 and i < words.high and bare.toLowerAscii in SMALL: continue
    return false
  true

func titleOf(page: string): string =
  ## Page's own name, after work's name and its dash.
  let opens = page.find("<title>")
  doAssert opens >= 0, "Page carries no title."
  let shuts = page.find("</title>", opens)
  page[opens + "<title>".len ..< shuts].split(" \u2014 ")[^1]


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
      # Every published title reads in title case, so published set is one consistent
      # form.  Nothing checked it until viewer page shipped with sentence for title
      # while every page beside it was cased.
      check titleCased(titleOf(written))
      # Rule 26 ranks move's stages, and markup can only rank them through
      # `keyTimes`: without it browser spreads frames evenly, so turn, settle and
      # reset all read at one speed.  Every animated element carries its own
      # clock, on every page, or none of that ranking survives being written out.
      check written.count("<animate") == written.count("keyTimes=")

suite "every page this project publishes":
  test "viewer's title reads in title case, as every other does":
    ## Viewer is written by its own module rather than by workbench above, so its title is
    ## held here against same reading rather than left as only one nothing checks.
    check titleCased(TITLE)
