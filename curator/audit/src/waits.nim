## Hold fixed waits out of drive code (Article IX.12; CONTRIBUTOR.md, Tests are paramount).
##   Fixed wait reads real clock in every context, so it is only real-clock read text can tell
##     apart: `waitForTimeout` of Playwright, and `sleep` and `sleepAsync` of Nim. Timer such as
##     `setTimeout`, `performance.now` or `getMonoTime` is unread: inside page under Playwright's
##     clock same name is simulated read, so check over it would report every correctness drive.
##   Reads `tests/` and `tools/` of every project, with no exemption: speed check samples count
##     of frames or calls and never sleeps (IX.12), so no check has reason to hold fixed wait.
##   Each name carries its replacement, as `english.nim` does for prose.
##   Nim names compare as Nim compares them, first character exact and rest without case or
##     `_`, so `sleep_async` is `sleepAsync`. Nim source is read with comments and strings
##     blanked, so checker's own suite holds its fixtures as strings and reports nothing. Other
##     kinds drop hit that comment text of its line holds.
##
##   Cost: drive kept outside `tests/` and `tools/` is unseen, and so is window built from page
##     timer; both hold by reading.
##   Cost: string of kind other than Nim is read as code, so message naming `waitForTimeout`
##     reports itself.
##   Cost: `sleep` of TypeScript is drive's own helper, often on page's clock, so it is unread;
##     fixed wait of language other than Nim and Playwright holds by reading.

{.experimental: "strictFuncs".}

import std/strutils
import ./[comments, findings, kinds, names]


const
  DRIVE_DIRECTORIES* = ["tests", "tools"]
    ## Project directories holding drive code, where fixed wait is read.
  WAITS* = [
    ("waitForTimeout", "wait on condition, or move page's clock with `clock.runFor`"),
    ("sleep", "wait on condition, or advance clock check moves"),
    ("sleepAsync", "wait on condition, or advance clock check moves"),
  ]
    ## Fixed waits, each paired with what replaces it.
  NIM_WAITS = ["sleep", "sleepAsync"]
    ## Names read in Nim source alone.
  NIM_KINDS = [Kind.Nim, Kind.NimScript, Kind.Nimble]
    ## Kinds Nim compiler reads, whose names compare as Nim compares them.
  IDENTIFIER_CHARS = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}
    ## Characters identifier is built from.


func isDriveCode*(path: string, directories: openArray[string]): bool =
  ## Decide whether path lies under `tests/` or `tools/` of one of directories.
  for directory in directories:
    for drive in DRIVE_DIRECTORIES:
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


func replacementOf(identifier: string, is_nim: bool): string =
  ## Read replacement of fixed wait identifier names; empty when it names none.
  for (name, replacement) in WAITS:
    if is_nim and identifier.nimIdentNormalize == name.nimIdentNormalize: return replacement
    if not is_nim and name notin NIM_WAITS and identifier == name: return replacement


func checkWaits*(path, source: string; kind: Kind): seq[Finding] =
  ## Report fixed wait in drive source, line by line, with its replacement.
  if kind.rule.syntax == Syntax.None: return
  let
    is_nim = kind in NIM_KINDS
    lines = (if is_nim: source.codeOnly else: source).splitLines
  var commented = newSeq[seq[string]](lines.len)
  if not is_nim:
    for c in source.comments(kind.rule.syntax):
      if c.line in 1 .. lines.len: commented[c.line - 1].add c.text.identifiers
  for i, line in lines:
    for identifier in line.identifiers:
      let replacement = identifier.replacementOf(is_nim)
      if replacement.len == 0: continue
      let at = commented[i].find(identifier)
      if at >= 0:
        commented[i].delete(at)
        continue
      result.add finding(
        path,
        i + 1,
        "Fixed wait reads real clock; " & replacement & " (Article IX.12); got `" &
          identifier & "`.",
      )
