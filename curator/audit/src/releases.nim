## Name each Nim pin that lags: behind pin of `curator/audit`, in lines that fail nothing, and
##   behind latest release of its series that nim-lang.org serves, in verb `releases`.
##   Each project keeps up with patch releases of its series, and nothing fails while pin lags
##     (GUIDE.md, Toolchain): bump is work of project holding pin (CURATOR.md, duty 8), so notice
##     tells delegate of lag and blocks no branch, as notice of lock that lags does (`lags.nim`).
##   Notice reads no network: release pin of each nimble file of project (`pinNim` of knoller),
##     against pin of `curator/audit`, which koch builds on and curators move first. Commit pin
##     is skipped, since no order holds between commit and release. `koch check` and `start`
##     hook print it below notice of lock that lags.
##   Verb asks nim-lang.org whether each later release exists, by HEAD request for tarball koch
##     fetches (`urlRelease` of knoller), so release reads as published once koch can serve it.
##     Search is pure over answer of each ask (`searchReleases`), so suites run it offline.
##     Series of pin `X.Y.Z`: each patch from `Z + 1` up, until two in row read missing, since
##       nim-lang.org leaves out at most one patch number between two releases of series: odd
##       one, which development builds carry.
##     Newer series: `X.(Y + 1).0`, `X.(Y + 2).0` and `(X + 1).0.0`, since odd minor number is
##       development series too. Each is note that waits on Architect, and never moves exit.
##     Pin itself is asked first: host that holds no tarball of it reads each later one as
##       missing too, so search would close issue for work it never did.
##     Platform of each ask is first that knoller fetches for, whichever machine asks, so answer
##       never varies with machine.
##   Exit 1 where pin of `curator/audit` lags latest release of its series, else 0; `nim.yml`
##     reads it weekly, and keeps one issue open while it is 1.
##   Search that cannot stand exits 2, as usage error does: job goes red and `watch.yml` reports
##     it, so issue of `nim.yml` names lag alone, and failure of one week never overwrites it.
##   Ask answering neither 200 nor 404 is such failure, as check lacking its tool reports finding
##     rather than skip (CURATOR.md, duty 8): read as missing, it would exit 0 for work never done.
##
##   Rejected: list of tags of `nim-lang/Nim`, which names release by its tag rather than by
##     tarball koch fetches, and reads second host.
##   Rejected: `cmp` of version text, which reads `2.4.10` below `2.4.2`.
##   Cost: run where nothing is newer asks six times: pin, two patches, three series.
##   Cost: release published at other address, or for other platform alone, reads as missing.
##   Cost: start hook reads checkout as it stands, so branch forked before curators moved pin
##     learns of lag at `koch check`, which judges merge with `origin/main`.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, sequtils, strutils]
import ../../knoller/src/knoller
import ./[findings, layout, toolchain, tree]


const
  ASKS_SERIES_MAX* = 50
    ## Patch numbers search asks after pin at most; longest series nim-lang.org serves, 1.6,
    ##   ends at `1.6.20`, so host answering published past bound answers for what it lacks.
  MISSES_SERIES = 2
    ## Patch numbers in row read missing that end series; series leaves out one at most.
  SECONDS_ASK = 30
    ## Seconds one ask waits at most; HEAD answers in under half second, so this marks host
    ##   that does not answer.
  STATUS_SERVED = "200"  ## Status nim-lang.org answers for tarball it serves.
  STATUS_ABSENT = "404"  ## Status nim-lang.org answers for tarball it holds none of.
  PLATFORM_ASK = PLATFORMS[0][2]  ## Tarball platform each ask names, first knoller fetches for.
  WHY_UNREAD = "nim-lang.org answered neither " & STATUS_SERVED & " nor " & STATUS_ABSENT &
    ", so search stops"
    ## Failure of ask answering neither way, which search cannot read past.
  WHY_UNSERVED = "nim-lang.org holds no tarball of pin itself, so it would read each later " &
    "release as missing"
    ## Failure of host that moved its tarballs, or never held pin.
  WHY_UNBOUNDED = "nim-lang.org reads each of " & $ASKS_SERIES_MAX & " patches after pin as " &
    "published, which no series holds, so it answers for what it lacks"
    ## Failure of host answering published for each address, as captive page does.


type
  Presence* {.pure.} = enum  ## Define what one ask of nim-lang.org says of release.
    Published  ## Host serves its tarball.
    Missing  ## Host answers that it holds none.
    Unread  ## Host answers neither way, or no answer arrives.

  Search* = object  ## Define what asks read of releases after pin.
    latest*: string  ## Latest release of series of pin; pin itself where none is later.
    newer*: seq[string]  ## First release of each newer series host serves, oldest first.
    failure*: string  ## Why search cannot stand, naming version asked; empty where it stands.

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


func version(parts: openArray[int]): string =
  ## Render numbers as dotted version, i.e. `@[2, 4, 10]` as `2.4.10`.
  parts.mapIt($it).join(".")


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


func presence*(code: int, status: string): Presence =
  ## Read what one ask says of release, from exit of curl and status it printed.
  if code != 0: return Presence.Unread
  case status.strip
  of STATUS_SERVED: Presence.Published
  of STATUS_ABSENT: Presence.Missing
  else: Presence.Unread


proc askRelease*(version: string): Presence =
  ## Ask nim-lang.org by HEAD request whether it serves tarball of release koch would fetch.
  let command = "curl -sS -I -o /dev/null --max-time " & $SECONDS_ASK & " -w " &
    quoteShell("%{http_code}") & " " & quoteShell(urlRelease(version, PLATFORM_ASK))
  let (output, code) =
    try: execCmdEx(command)
    except OSError: ("", 1)
  presence(code, output)


func searchReleases*(
  pin: string, ask: proc(version: string): Presence
): Search {.effectsOf: ask.} =
  ## Read latest release of series of pin `X.Y.Z`, and first release of each newer series, from
  ##   what `ask` says of each version.
  ##   Failure names version whose answer leaves search unsound, and search then holds pin alone,
  ##     so no reading of half search stands.
  func fail(why, asked: string): Search =
    ## Construct search holding pin alone, and failure naming version asked.
    Search(latest: pin, failure: why & "; got `" & asked & "`.")

  if not pin.isVersion or pin.partsVersion.len != 3:
    return fail("Search reads pin as `X.Y.Z` alone", pin)
  let parts = pin.partsVersion
  result.latest = pin

  # Hold search to host that serves pin itself, since one that does not reads each as missing.
  case ask(pin)
  of Presence.Published: discard
  of Presence.Missing: return fail(WHY_UNSERVED, pin)
  of Presence.Unread: return fail(WHY_UNREAD, pin)

  # Walk patches of series until two in row read missing.
  var misses = 0
  for patch in parts[2] + 1 .. parts[2] + ASKS_SERIES_MAX:
    let asked = version([parts[0], parts[1], patch])
    case ask(asked)
    of Presence.Published:
      result.latest = asked
      misses = 0
    of Presence.Missing:
      inc misses
      if misses == MISSES_SERIES: break
    of Presence.Unread: return fail(WHY_UNREAD, asked)
  if misses < MISSES_SERIES: return fail(WHY_UNBOUNDED, pin)

  # Ask first release of each newer series.
  for asked in [
    version([parts[0], parts[1] + 1, 0]),
    version([parts[0], parts[1] + 2, 0]),
    version([parts[0] + 1, 0, 0]),
  ]:
    case ask(asked)
    of Presence.Published: result.newer.add asked
    of Presence.Missing: discard
    of Presence.Unread: return fail(WHY_UNREAD, asked)


func checkReleases*(
  pins: openArray[Pinned], ask: proc(version: string): Presence
): tuple[lines: seq[string], found: seq[Finding], failure: string] {.effectsOf: ask.} =
  ## Read latest release of series of pin of `curator/audit`, and each newer series, through
  ##   `ask`; return lines verb prints, finding where that pin lags its series, and failure of
  ##   search that cannot stand, which prints no line and finds nothing.
  let
    path_driver = DIRECTORY_DRIVER.pathNimble
    driver = pins.pinDriver
  if driver.isNone:
    result.found.add finding(
      path_driver, 0, "Driver pins no release, so no later one can be read; got none."
    )
    return
  let search = searchReleases(driver.get, ask)
  if search.failure.len > 0:
    result.failure = search.failure
    return

  # Name latest release of series, each pin below it, then each newer series.
  let series = driver.get.partsVersion[0 .. 1].version
  result.lines.add "Latest release of Nim " & series & " that nim-lang.org serves: `" &
    search.latest & "`."
  let lagging = pins.filterIt(it.pin.isBelow(search.latest))
  if lagging.len > 0:
    result.lines.add "Pins that lag it; each moves with its project, and fails nothing " &
      "(GUIDE.md, Toolchain):"
    for pinned in lagging: result.lines.add "  " & pinned.path & ": pins `" & pinned.pin & "`."
  for asked in search.newer:
    result.lines.add "Nim `" & asked & "` opens newer series; move to it waits on Architect " &
      "(GUIDE.md, Toolchain)."
  if driver.get.isBelow(search.latest):
    result.found.add finding(
      path_driver,
      0,
      "Pin of driver lags latest release of its series; move curator pins and `NIM_VERSION` " &
        "of each workflow together (CURATOR.md, duty 8); got `" & driver.get & "` against `" &
        search.latest & "`.",
    )
