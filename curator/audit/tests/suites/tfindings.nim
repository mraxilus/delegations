discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate finding record of `findings.nim` header: its order, and how it renders.
##   Every check reports through these two, and nothing covered them until this file.

import std/[algorithm, unittest]
import ../src/findings


suite "Findings":
  test "render locates finding, dropping parts that locate nothing":
    check finding("a/b.nim", 3, "Broke.").render == "a/b.nim:3: Broke."
    check finding("a/b.nim", 0, "Broke.").render == "a/b.nim: Broke."  # whole file
    check finding("", 0, "Broke.").render == "Broke."  # branch-level, no file to open

  test "order is path, then line, then message, so reports are stable":
    let scattered = @[
      finding("b.nim", 1, "Second file."),
      finding("a.nim", 9, "Later line."),
      finding("a.nim", 2, "Zebra."),
      finding("a.nim", 2, "Apple."),
    ]
    let ordered = scattered.sorted
    check ordered[0] == finding("a.nim", 2, "Apple.")  # message breaks line tie
    check ordered[1] == finding("a.nim", 2, "Zebra.")
    check ordered[2] == finding("a.nim", 9, "Later line.")  # line breaks path tie
    check ordered[3] == finding("b.nim", 1, "Second file.")
    # Same input in another order sorts same way, which is what stable output means.
    check scattered.reversed.sorted == ordered

  test "whole-file finding sorts before first line of same file":
    # `0` marks whole file and is never line one, so it leads its own file's findings.
    let found = @[finding("a.nim", 1, "Line."), finding("a.nim", 0, "File.")].sorted
    check found[0].line == 0
