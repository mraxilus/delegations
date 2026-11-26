## Name each Nim release pin that lags pin of `curator/audit`, in lines that fail nothing.
##   Each project keeps up with patch releases of its series, and nothing fails while pin lags
##     (GUIDE.md, Toolchain): bump is work of project holding pin (CURATOR.md, duty 8), so notice
##     tells delegate of lag and blocks no branch, as notice of lock that lags does (`lags.nim`).
##   Notice reads no network: release pin of each nimble file of project (`pinNim` of knoller),
##     against pin of `curator/audit`, which koch builds on and curators move first. Commit pin
##     is skipped, since no order holds between commit and release. `koch check` and `start`
##     hook print it below notice of lock that lags.
##
##   Rejected: `cmp` of version text, which reads `2.4.10` below `2.4.2`.
##   Cost: start hook reads checkout as it stands, so branch forked before curators moved pin
##     learns of lag at `koch check`, which judges merge with `origin/main`.

{.experimental: "strictFuncs".}

import std/[options, os, strutils]
import ../../knoller/src/knoller
import ./[layout, toolchain, tree]


type
  Pinned* = object  ## Define release pin of one project, as its nimble file names it.
    path*: string  ## Nimble file, repository-relative.
    pin*: string  ## Release it pins, dotted.


func partsVersion(version: string): seq[int] =
  ## Read each number of dotted version, i.e. `2.4.10` as `@[2, 4, 10]`; number past `int`
  ##   reads as `int.high`, so pin of any length raises nothing in `koch check`.
  for part in version.split('.'):
    result.add(
      try: part.parseInt
      except ValueError: int.high
    )


func isBelow(version, other: string): bool =
  ## Decide whether version comes before other, number by number; absent number reads as 0.
  let (a, b) = (version.partsVersion, other.partsVersion)
  for i in 0 ..< max(a.len, b.len):
    let
      x = if i < a.len: a[i] else: 0
      y = if i < b.len: b[i] else: 0
    if x != y: return x < y
  false


func pinDriver(pins: openArray[Pinned]): Option[string] =
  ## Read release pin of `curator/audit` among pins; none where it pins no release.
  for pinned in pins:
    if pinned.path == DIRECTORY_DRIVER.pathNimble: return some(pinned.pin)
  none(string)


proc readPins*(root: string): seq[Pinned] =
  ## Read release pin of each nimble file of project in tree at root, in path order; commit pin
  ##   and absent pin name none.
  for path in root.listPaths:
    if path.nimbleProject != path: continue
    let pin = readFile(root / path).pinNim
    if pin.isSome and not pin.get.isCommit: result.add Pinned(path: path, pin: pin.get)


func noticesPin*(pins: openArray[Pinned]): seq[string] =
  ## Render heading, then one line for each release pin below pin of `curator/audit`; empty
  ##   where none lags, or where that project pins no release.
  let driver = pins.pinDriver
  if driver.isNone: return
  for pinned in pins:
    if pinned.pin.isBelow(driver.get):
      result.add "  " & pinned.path & ": pins `" & pinned.pin & "`."
  if result.len == 0: return
  result.insert(
    "Nim pins that lag `" & driver.get & "`, pin of `" & DIRECTORY_DRIVER & "`; they fail " &
      "nothing, and project moves its pin once its suites pass on new one (GUIDE.md, Toolchain):",
    0,
  )
