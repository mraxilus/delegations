## Replicate notice of `releases.nim`: each release pin below pin of `curator/audit`, in lines
##   that fail nothing (GUIDE.md, Toolchain).

{.experimental: "strictFuncs".}

import std/[os, strutils, unittest]
import ../../src/releases
import ./fixtures


const
  PATH_DRIVER = "curator/audit/audit.nimble"  ## Nimble file of driver, whose pin notice reads.
  PATH_KNOLLER = "curator/knoller/knoller.nimble"  ## Curator project pinned with driver.
  PATH_RICTADNI = "contributor/bangu/rictadni/rictadni.nimble"
    ## Contributor project, pinned to `2.4.0` on 2026-11-26.



suite "Notice":
  test "each release pin below pin of driver takes one line, under heading naming guide":
    # Case: five contributor projects pin `2.4.0` while curators pin `2.4.2`, 2026-11-26.
    #   Domain: below by patch, below by minor with larger patch, equal, above by number but
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
