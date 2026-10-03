## Hold edits to their contract: each applies to source as given, whatever order they come
##   in, and insertions at one offset open in rank order.

{.experimental: "strictFuncs".}

import std/[algorithm, unittest]
import ../../src/rewrites



suite "Internal: Rewrites":
  test "edits apply to source as given, in any order; insertions at one offset by rank":
    let
      source = "let v = x.float.int\n"
      edits = @[
        Edit(first: 8, after: 8, text: "float(", rank: -7),
        Edit(first: 9, after: 15, text: ")"),
        Edit(first: 8, after: 8, text: "int(", rank: -11),
        Edit(first: 15, after: 19, text: ")"),
      ]
    check source.applied(edits) == "let v = int(float(x))\n"  # outer opens first
    check source.applied(edits.reversed) == "let v = int(float(x))\n"  # order given is none
    check source.applied([Edit(first: 8, after: 9, text: "y")]) == "let v = y.float.int\n"
    check source.applied([]) == source
