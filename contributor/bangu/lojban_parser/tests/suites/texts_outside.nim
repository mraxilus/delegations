## Read outside texts suites hold parser to: lists `lojban-common` installs, each pinned by digest.
##   Outside text tests parser, pinned by digest and kept out of repository (#819, ruling `D3 a`).
##     Lujvo list gives meaning, never validity, so parser commits none of it; its words still
##     stand as domain of lujvo people wrote, where CLL speaks of every lujvo.
##   Reader gives `none` where file is absent or moved from its pin, so each test reading it
##     skips with reason (Article IX.9); `system` of `tools/build.nim` declares package, so CI
##     installs it.
##   `lujvo.txt` writes tanru in two notations: `word:part+part:gloss` in lojban, and
##     `word#keyword+keyword:gloss` in English keywords. Line is kept where word is lojban
##     letters alone; parts are kept in lojban notation alone, where each is letters, since
##     keywords name gismu by English, which parser does not hold.
##     Cost: line writing phrase for word, as `datkypi'u gairki'e`, stands in no domain.
##   `cmavo.txt` writes cmavo in columns 1 to 11, period of pause kept (3.3), and selma'o in
##     columns 12 to 20; `*` there marks compound, which reads as several cmavo.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils]

import ../../tools/lists


type
  LineLujvo* = object  ## Define one line of `lujvo.txt` whose word is lojban letters.
    word*: string  ## Lujvo as line spells it.
    parts*: seq[string]  ## Parts of tanru in lojban notation, in order; empty in English one.

  LineCmavo* = object  ## Define one line of `cmavo.txt`: cmavo, or compound of several.
    word*: string  ## Cmavo as line writes it, period of pause included.
    is_compound*: bool  ## Selma'o column marks several cmavo written as one word (4.2).


const LETTERS_LOJBAN = {'a' .. 'z', '\''}  ## Characters word of kept line holds.


func isLetters(text: string): bool =
  ## Test text is nonempty and holds lojban letters and apostrophe alone.
  text.len > 0 and text.allCharsInSet(LETTERS_LOJBAN)


func toLinesLujvo*(text: string): seq[LineLujvo] =
  ## Read every line of `lujvo.txt` whose word is lojban letters, in order of file.
  for line in text.splitLines:
    let
      fields = line.split(':')
      is_english = '#' in fields[0]
      word = fields[0].split('#', maxsplit = 1)[0]
    if not word.isLetters: continue
    var parts: seq[string]
    if not is_english and fields.len >= 2:
      parts = fields[1].split('+')
      if parts.len < 2 or not parts.allIt(it.isLetters): parts = @[]
    result.add LineLujvo(word: word, parts: parts)


proc readLinesLujvo*(): Option[seq[LineLujvo]] =
  ## Read installed `lujvo.txt`; `none` where absent, or where digest left `DIGEST_LUJVO`.
  if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "lujvo.txt"): return
  let source = readSource("lujvo.txt")
  if source.digest != DIGEST_LUJVO: return
  some(source.text.toLinesLujvo)


func toLinesCmavo*(text: string): seq[LineCmavo] =
  ## Read every line of `cmavo.txt` after its header, in order of file.
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    let selmaho = line[min(11, line.len) ..< min(20, line.len)]
    result.add LineCmavo(word: line[0 ..< min(11, line.len)].strip, is_compound: '*' in selmaho)


proc readLinesCmavo*(): Option[seq[LineCmavo]] =
  ## Read installed `cmavo.txt`; `none` where absent, or where digest left `DIGEST_CMAVO`.
  if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "cmavo.txt"): return
  let source = readSource("cmavo.txt")
  if source.digest != DIGEST_CMAVO: return
  some(source.text.toLinesCmavo)
