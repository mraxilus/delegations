## Hold fixed waits out of drive code (Article IX.12; CONTRIBUTOR.md, Tests are paramount).
##   Rule, its names and their replacements are knoller's (`waits.nim` there, `checkWaits`): Nim
##     source takes its check whole; source of every other kind is read here, line by line, and
##     identifiers its comments do not hold are passed to same check, so each kind reports in
##     same words, with article `findingOf` cites.
##   Reads `tests/` and `tools/` of every project, with no exemption: speed check samples count
##     of frames or calls and never sleeps (IX.12), so no check has reason to hold fixed wait.
##
##   Cost: string of kind other than Nim is read as code, so message naming `waitForTimeout`
##     reports itself.

{.experimental: "strictFuncs".}

import std/strutils
import ../../knoller/src/knoller
import ./[comments, findings, kinds]


const
  DIRECTORIES_DRIVE* = ["tests", "tools"]
    ## Project directories holding drive code, where fixed wait is read.
  NIM_KINDS = [Kind.Nim, Kind.NimScript, Kind.Nimble]
    ## Kinds Nim compiler reads, whose names compare as Nim compares them.
  IDENTIFIER_CHARS = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}
    ## Characters identifier of other kind is built from.


func isDriveCode*(path: string, directories: openArray[string]): bool =
  ## Decide whether path lies under `tests/` or `tools/` of one of directories.
  for directory in directories:
    for drive in DIRECTORIES_DRIVE:
      if path.startsWith(directory & "/" & drive & "/"): return true


func identifiers(line: string): seq[string] =
  ## Read every identifier of line, in order.
  var i = 0
  while i < line.len:
    if line[i] in IDENTIFIER_CHARS:
      let start = i
      while i < line.len and line[i] in IDENTIFIER_CHARS: inc i
      result.add line[start ..< i]
    else: inc i


func checkWaits*(path, source: string; kind: Kind): seq[Finding] =
  ## Report fixed wait in drive source, line by line, with its replacement.
  if kind.rule.syntax == Syntax.None: return
  if kind in NIM_KINDS: return checkWaits(path, source).findingsOf

  # Drop each identifier comment text of its line holds, once for each time it holds it.
  let lines = source.splitLines
  var commented = newSeq[seq[string]](lines.len)
  for c in source.comments(kind.rule.syntax):
    if c.line in 1 .. lines.len: commented[c.line - 1].add c.text.identifiers
  var read = newSeq[seq[string]](lines.len)
  for i, line in lines:
    for identifier in line.identifiers:
      let at = commented[i].find(identifier)
      if at >= 0: commented[i].delete(at)
      else: read[i].add identifier
  checkWaits(path, read, is_nim = false).findingsOf
