## Replicate pins that lag of `releases.nim`: notice against pin of `curator/audit`, and search of
##   later releases over what host says of each (GUIDE.md, Toolchain; CURATOR.md, duty 8).

{.experimental: "strictFuncs".}

import std/[os, sequtils, sets, strutils, unittest]
import ../../src/releases
import ./fixtures


const
  PATH_DRIVER = "curator/audit/audit.nimble"  ## Nimble file of driver, whose pin notice reads.
  PATH_KNOLLER = "curator/knoller/knoller.nimble"  ## Curator project pinned with driver.
  PATH_RICTADNI = "contributor/bangu/rictadni/rictadni.nimble"
    ## Contributor project, pinned to `2.4.0` on 2026-11-26.
  SERIES_SERVED = [
    ("1.6", @[0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]),
    ("2.0", @[0, 2, 4, 6, 8, 10, 12, 14, 16]),
    ("2.2", @[0, 2, 4, 6, 8, 10, 12, 14]),
    ("2.4", @[0, 2]),
  ]
    ## Patches of each series nim-lang.org served, read by HEAD of each `linux_x64` tarball
    ##   from patch 0 to 24, 2026-11-26; `1.6.1` is odd patch it serves.
  COUNT_SERVED = 31  ## Releases `SERIES_SERVED` holds, each read as pin once below.
  COUNT_SUBSETS = 8  ## Subsets of three newer series, each read once below.


func versionsServed(): seq[string] =
  ## Collect each release `SERIES_SERVED` holds, as dotted version.
  for (series, patches) in SERIES_SERVED:
    for patch in patches: result.add series & "." & $patch


proc hostServing(served: openArray[string]): proc(version: string): Presence =
  ## Construct ask of host serving each version of `served`, and holding none of any other.
  let held = served.toHashSet
  result = proc(version: string): Presence =
    if version in held: Presence.Published else: Presence.Missing


proc searchLogged(
  pin: string, served, unread: openArray[string]
): tuple[search: Search, asked: seq[string]] =
  ## Search after pin on host serving `served`, answering neither way for `unread`; return search
  ##   and each version asked, in order.
  var asked: seq[string]
  let (held, silent) = (served.toHashSet, unread.toHashSet)

  proc ask(version: string): Presence =
    ## Answer for host, and log version asked.
    asked.add version
    if version in silent: Presence.Unread
    elif version in held: Presence.Published
    else: Presence.Missing

  let search = searchReleases(pin, ask)
  (search, asked)



suite "Notice":
  test "each release pin below pin of driver takes one line, under heading naming guide":
    # Case: five contributor projects pin `2.4.0` while curators pin `2.4.2`, 2026-11-26.
    # Domain: below by patch, below by minor with larger patch, equal, above by number but
    #   below as text, above by minor.
    let lines = noticesPin([
      Pinned(path: PATH_DRIVER, pin: "2.4.2"),
      Pinned(path: PATH_KNOLLER, pin: "2.4.2"),
      Pinned(path: PATH_RICTADNI, pin: "2.4.0"),
      Pinned(path: "contributor/ronri/old/old.nimble", pin: "2.2.12"),
      Pinned(path: "contributor/ronri/ahead/ahead.nimble", pin: "2.4.10"),
      Pinned(path: "contributor/ronri/next/next.nimble", pin: "2.6.0"),
    ])
    check lines.len == 3  # heading, then each pin below driver's
    check lines[0].startsWith("Nim pins that lag `2.4.2`, pin of `curator/audit`;")
    check "fail nothing" in lines[0] and lines[0].endsWith("(GUIDE.md, Toolchain):")
    check lines[1 .. ^1] == @[
      "  " & PATH_RICTADNI & ": pins `2.4.0`.",
      "  contributor/ronri/old/old.nimble: pins `2.2.12`.",
    ]


  test "pins compare number by number, absent number as 0":
    # Domain: patch of two digits on each side, and version of two numbers against three.
    let driver = Pinned(path: PATH_DRIVER, pin: "2.4.10")
    check noticesPin([driver, Pinned(path: PATH_RICTADNI, pin: "2.4.9")]).len == 2  # 9 below 10
    check noticesPin([driver, Pinned(path: PATH_RICTADNI, pin: "2.4.10")]).len == 0
    check noticesPin([driver, Pinned(path: PATH_RICTADNI, pin: "2.4")]).len == 2
    let short = Pinned(path: PATH_DRIVER, pin: "2.4")
    check noticesPin([short, Pinned(path: PATH_RICTADNI, pin: "2.4.0")]).len == 0  # equal
    let huge = Pinned(path: PATH_RICTADNI, pin: "2.4.99999999999999999999")
    check noticesPin([driver, huge]).len == 0  # number past `int` reads highest, and raises none


  test "nothing below driver, or driver of no release pin, names nothing, heading included":
    check noticesPin([
      Pinned(path: PATH_DRIVER, pin: "2.4.2"), Pinned(path: PATH_RICTADNI, pin: "2.4.2")
    ]).len == 0
    check noticesPin([Pinned(path: PATH_RICTADNI, pin: "2.4.0")]).len == 0  # driver pins commit
    check noticesPin([]).len == 0


  test "pins read from nimble file named after its project, release pin alone":
    # Real git on throwaway repository. Domain: release pin, commit pin, range, no pin, nimble
    #   file of fixture nested in project, and second nimble file of project.
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto(PATH_DRIVER, "requires \"nim == 2.4.2\"\n")
    root.writeInto(PATH_RICTADNI, "requires \"nim == 2.4.0\"\n")
    root.writeInto(
      "contributor/bangu/ricysoho/ricysoho.nimble", "requires \"nim == " & COMMIT & "\"\n"
    )
    root.writeInto("curator/probe/probe.nimble", "requires \"nim >= 2.4.0\"\n")
    root.writeInto("curator/assayer/assayer.nimble", "requires \"knoller\"\n")
    root.writeInto("curator/audit/tests/fixtures/old/old.nimble", "requires \"nim == 2.2.0\"\n")
    root.writeInto("contributor/bangu/rictadni/other.nimble", "requires \"nim == 1.0.0\"\n")
    check readPins(root) == @[
      Pinned(path: PATH_RICTADNI, pin: "2.4.0"), Pinned(path: PATH_DRIVER, pin: "2.4.2")
    ]  # path order, as git lists them
    check noticesPin(readPins(root)).len == 2  # heading, and rictadni



suite "Search":
  test "search reads latest patch of each series nim-lang.org served, from each pin of it":
    # Domain: each release of each series read 2026-11-26, as pin; newer series is next one
    #   served, and none after `2.4`.
    let served = versionsServed()
    var count = 0
    for (series, patches) in SERIES_SERVED:
      for patch in patches:
        let
          pin = series & "." & $patch
          (search, _) = searchLogged(pin, served, [])
          parts = pin.split('.').mapIt(it.parseInt)
          newer = [
            $parts[0] & "." & $(parts[1] + 1) & ".0",
            $parts[0] & "." & $(parts[1] + 2) & ".0",
            $(parts[0] + 1) & ".0.0",
          ].filterIt(it in served)
        check search.failure == ""
        check search.latest == series & "." & $patches[^1]
        check search.newer == newer
        inc count
    check count == COUNT_SERVED


  test "search asks pin, each patch until two in row read missing, then three newer series":
    # Case: curators pin `2.4.2`, on host as read 2026-11-26.
    let (search, asked) = searchLogged("2.4.2", versionsServed(), [])
    check asked == @["2.4.2", "2.4.3", "2.4.4", "2.5.0", "2.6.0", "3.0.0"]
    check search == Search(latest: "2.4.2")


  test "one patch missing between two keeps series, two end it, and patches compare by number":
    # Domain: gaps of one up to `2.4.10`, which text reads below `2.4.2`; gap of two.
    let tens = ["2.4.0", "2.4.2", "2.4.4", "2.4.6", "2.4.8", "2.4.10"]
    check searchLogged("2.4.2", tens, [])[0].latest == "2.4.10"
    check searchLogged("2.4.0", ["2.4.0", "2.4.2"], [])[0].latest == "2.4.2"  # gap of one
    let (gapped, asked) = searchLogged("2.4.0", ["2.4.0", "2.4.3"], [])
    check gapped.latest == "2.4.0"  # gap of two ends series
    check "2.4.3" notin asked


  test "each newer series host serves is note, oldest first, and moves latest of none":
    # Domain: each subset of `2.5.0`, `2.6.0` and `3.0.0`, exhaustive.
    let newer = ["2.5.0", "2.6.0", "3.0.0"]
    var count = 0
    for mask in 0 ..< COUNT_SUBSETS:
      let
        chosen = (0 .. 2).toSeq.filterIt((mask shr it and 1) == 1).mapIt(newer[it])
        (search, _) = searchLogged("2.4.2", @["2.4.2"] & chosen, [])
      check search == Search(latest: "2.4.2", newer: chosen)
      inc count
    check count == COUNT_SUBSETS


  test "host holding no tarball of pin itself leaves search unsound, and is asked nothing more":
    # Domain: host that moved its tarballs, which would read each later release as missing.
    let (search, asked) = searchLogged("2.4.2", ["2.4.4"], [])
    check asked == @["2.4.2"]
    check "pin itself" in search.failure and search.failure.endsWith("got `2.4.2`.")
    check search.latest == "2.4.2"


  test "ask answering neither way stops search at that version, wherever it falls":
    # Domain: pin, each patch, and each newer series.
    for (unread, asks) in [
      ("2.4.2", 1), ("2.4.3", 2), ("2.4.4", 3), ("2.5.0", 4), ("2.6.0", 5), ("3.0.0", 6)
    ]:
      let (search, asked) = searchLogged("2.4.2", ["2.4.2", "2.6.0"], [unread])
      check asked.len == asks and asked[^1] == unread  # nothing asked after it
      check search.failure.endsWith("got `" & unread & "`.")
      check search.newer.len == 0


  test "host answering published for every patch is caught at bound, and never asked forever":
    # Domain: captive page or proxy that answers 200 for each address.
    var count = 0

    proc ask(version: string): Presence =
      ## Answer published for each version, and count asks.
      inc count
      Presence.Published

    let search = searchReleases("2.4.2", ask)
    check count == 1 + ASKS_SERIES_MAX  # pin, then each patch up to bound
    check "answers for what it lacks" in search.failure


  test "host that never leaves out two patches in row is caught at bound too":
    # Domain: host answering published for every other patch, so series never ends.
    # Case: review of #1050; mutant reading bound as `misses == 0` passed where last patch missed.
    var served = @["2.4.2"]
    for patch in countup(3, 2 + ASKS_SERIES_MAX, 2): served.add "2.4." & $patch
    let search = searchReleases("2.4.2", hostServing(served))
    check "answers for what it lacks" in search.failure


  test "pin of other shape than `X.Y.Z` is failure, and asks nothing":
    for pin in ["2.4", "2.4.2.1", "", "2.4.x", COMMIT]:
      let (search, asked) = searchLogged(pin, ["2.4.2"], [])
      check asked.len == 0
      check search.failure.endsWith("got `" & pin & "`.")



suite "Ask":
  test "status 200 reads published, 404 missing, and every other answer unread":
    # Domain: statuses of tarball served, absent, moved, refused by proxy, failed, none; exits
    #   of curl that name failure before or after status.
    check presence(0, "200") == Presence.Published
    check presence(0, "200\n") == Presence.Published
    check presence(0, "404") == Presence.Missing
    for status in ["301", "302", "403", "500", "000", "", "200 404"]:
      check presence(0, status) == Presence.Unread
    check presence(6, "000") == Presence.Unread  # host not resolved
    check presence(28, "200") == Presence.Unread  # time out after status



suite "Verb":
  test "verb names latest release, and each pin below it, and finds nothing where driver holds it":
    # Case: pins of 2026-11-26, on host as read that day.
    let (lines, found, failure) = checkReleases(
      [
        Pinned(path: PATH_DRIVER, pin: "2.4.2"),
        Pinned(path: PATH_KNOLLER, pin: "2.4.2"),
        Pinned(path: PATH_RICTADNI, pin: "2.4.0"),
      ],
      hostServing(versionsServed()),
    )
    check found.len == 0 and failure == ""
    check lines == @[
      "Latest release of Nim 2.4 that nim-lang.org serves: `2.4.2`.",
      "Pins that lag it; each moves with its project, and fails nothing (GUIDE.md, Toolchain):",
      "  " & PATH_RICTADNI & ": pins `2.4.0`.",
    ]


  test "driver that lags latest release of its series is one finding, naming both":
    let (lines, found, failure) = checkReleases(
      [Pinned(path: PATH_DRIVER, pin: "2.4.2"), Pinned(path: PATH_RICTADNI, pin: "2.4.0")],
      hostServing(versionsServed() & "2.4.4"),
    )
    check found.len == 1 and failure == ""
    check found[0].path == PATH_DRIVER
    check "CURATOR.md, duty 8" in found[0].message
    check found[0].message.endsWith("got `2.4.2` against `2.4.4`.")
    check lines[0].endsWith("`2.4.4`.")
    check lines[2 .. ^1] == @[
      "  " & PATH_DRIVER & ": pins `2.4.2`.", "  " & PATH_RICTADNI & ": pins `2.4.0`."
    ]


  test "driver that lags its series beside newer series is still one finding":
    # Case: review of #1050; mutant reading lag only where no newer series opens survived suite.
    let (lines, found, failure) = checkReleases(
      [Pinned(path: PATH_DRIVER, pin: "2.4.2")],
      hostServing(versionsServed() & @["2.4.4", "2.6.0"]),
    )
    check found.len == 1 and failure == ""  # exit stays 1, so issue stays open
    check found[0].message.endsWith("got `2.4.2` against `2.4.4`.")
    check lines[^1].startsWith("Nim `2.6.0` opens newer series;")


  test "newer series alone is note, and finding of none":
    let (lines, found, failure) = checkReleases(
      [Pinned(path: PATH_DRIVER, pin: "2.4.2")],
      hostServing(versionsServed() & @["2.6.0", "3.0.0"]),
    )
    check found.len == 0 and failure == ""  # exit stays 0
    check lines.len == 3  # latest, then one note for each series; no pin lags
    check lines[1].startsWith("Nim `2.6.0` opens newer series;")
    check lines[2].startsWith("Nim `3.0.0` opens newer series;")
    check lines[1 .. ^1].allIt("waits on Architect" in it)


  test "search that cannot stand is failure rather than finding, so issue names lag alone":
    # Domain: host of no tarball at all, host answering neither way.
    let driver = [Pinned(path: PATH_DRIVER, pin: "2.4.2")]
    for ask in [
      hostServing([]),
      proc(version: string): Presence = Presence.Unread,
    ]:
      let (lines, found, failure) = checkReleases(driver, ask)
      check lines.len == 0 and found.len == 0
      check failure.endsWith("got `2.4.2`.")


  test "driver of no release pin is finding, and asks nothing":
    var count = 0

    proc ask(version: string): Presence =
      ## Count asks, and answer published.
      inc count
      Presence.Published

    let (lines, found, failure) = checkReleases([Pinned(path: PATH_RICTADNI, pin: "2.4.0")], ask)
    check lines.len == 0 and count == 0 and failure == ""
    check found.len == 1 and found[0].message.startsWith("Driver pins no release")
