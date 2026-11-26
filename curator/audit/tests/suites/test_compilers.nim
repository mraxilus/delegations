## Replicate finding of `compilers.nim` header: pin no compiler serves names cache koch tried.
##   Resolution itself is knoller's, and so is its suite (`curator/knoller`).

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[compilers, findings]



suite "Compilers":
  test "unresolved pin is finding naming where koch looked":
    let found = missing("curator/probe", "2.2.6", "/c/2.2.6/bin")
    check found.len == 1
    check found[0].path == "curator/probe"
    check "; got `2.2.6`; help: install it under `" in found[0].brief
    check found.anyIt(it.rule == "koch.missing-compiler")
    check "/c/2.2.6/bin" in found[0].brief  # names cache it tried
