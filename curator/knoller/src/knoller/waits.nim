## Hold fixed waits out of drive code (Article IX.12): `sleep` and `sleepAsync` of Nim, and
##   `waitForTimeout` of Playwright, each with what replaces it.
##   Fixed wait reads real clock in every context, so it is only real-clock read text can tell
##     apart. Timer such as `setTimeout`, `performance.now` or `getMonoTime` is unread: inside page
##     under Playwright's clock same name is simulated read, so check over it would report every
##     correctness drive.
##   Caller decides which file is drive code, and passes it alone: `curator/audit` reads `tests/`
##     and `tools/` of each project, and command line each file under directory `tests` or
##     `tools` (`reports.isDriveFile`).
##   Nim names compare as Nim compares them (`identity`), so `sleep_async` is `sleepAsync`, and
##     Playwright's name reads in Nim binding too. Nim source is read with comments and strings
##     blanked, so suite holding its fixtures as strings reports nothing.
##   Caller reading other syntax passes identifiers of each line, those its comments hold left
##     out, and only Playwright's name reads there, exactly: `sleep` of TypeScript is drive's own
##     helper, often on page's clock.
##   No fixer: what replaces fixed wait is condition or clock drive moves, which text does not hold.
##
##   Cost: drive kept outside directories caller names is unseen, and so is window built from page
##     timer; both hold by reading.

{.experimental: "strictFuncs".}

import std/strutils
import ./[reports, views]


const
  WAITS = [
    ("waitForTimeout", "wait on condition, or move page's clock with `clock.runFor`"),
    ("sleep", "wait on condition, or advance clock check moves"),
    ("sleepAsync", "wait on condition, or advance clock check moves"),
  ]
    ## Fixed waits, each paired with what replaces it.
  WAITS_NIM = ["sleep", "sleepAsync"]  ## Names read in Nim source alone.


func identifiers(line: string): seq[string] =
  ## Read every name of line of Nim code view, in order.
  var i = 0
  while i < line.len:
    let name = line.identifierAt(i)
    if name.len == 0: inc i
    else:
      result.add name
      i += name.len


func replacementOf(identifier: string, is_nim: bool): string =
  ## Read replacement of fixed wait identifier names; empty when it names none.
  for (name, replacement) in WAITS:
    if is_nim and identifier.identity == name.identity: return replacement
    if not is_nim and name notin WAITS_NIM and identifier == name: return replacement


func checkWaits*(path: string, lines: openArray[seq[string]], is_nim: bool): seq[Report] =
  ## Report fixed wait named by identifiers of each line, with its replacement; Nim's names read
  ##   where `is_nim`, as Nim compares them, else Playwright's alone, exactly.
  for i, line in lines:
    for identifier in line:
      let replacement = identifier.replacementOf(is_nim)
      if replacement.len == 0: continue
      result.add initReport(
        path,
        i + 1,
        Rule.FixedWait,
        "Fixed wait reads real clock; " & replacement & "; got `" & identifier & "`.",
      )


func checkWaits*(path, source: string): seq[Report] =
  ## Report fixed wait in Nim drive source, line by line, with its replacement.
  var lines: seq[seq[string]]
  for line in source.codeOnly.splitLines: lines.add line.identifiers
  checkWaits(path, lines, is_nim = true)
