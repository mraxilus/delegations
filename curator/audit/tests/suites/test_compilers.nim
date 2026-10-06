## Replicate finding of `compilers.nim` header: pin no compiler serves names cache koch tried.
##   Resolution itself is knoller's, and so is its suite (`curator/knoller`).

{.experimental: "strictFuncs".}

import std/[strutils, unittest]
import ../../src/compilers



suite "Compilers":
  test "unresolved pin is finding naming where koch looked":
    let found = missing("curator/probe", "2.2.6", "/c/2.2.6/bin")
    check found.len == 1
    check found[0].path == "curator/probe"
    check found[0].message.endsWith("got `2.2.6`.")
    check "/c/2.2.6/bin" in found[0].message  # names cache it tried
