## What reference's cards ask of body sim, held to being one question wherever one
## picture is drawn.

{.experimental: "strictFuncs".}

import std/[tables, unittest]

import ../../design/[asks, parts]
import ../../src/dance_ontology/rotation


suite "what each card asks of sim":
  var byKey = initTable[string, StillAsk]()
  for a in stillAsks(): byKey[a.key] = a

  test "one picture is one question, whichever section draws it":
    ## Standard diagram's A16 is hand to hand wound half turn clockwise, which
    ## is chain's C5, and A17 is C3.  Asked with opposite signs, sim stood A16 in
    ## C3's pose and A17 in C5's, mirror of what each card draws.
    for (frame, chain) in [("A16", "C5"), ("A17", "C3")]:
      let (a, c) = (byKey[frame], byKey[chain])
      check a.links == c.links
      check a.away == c.away
      check a.head == c.head
      check a.turns == c.turns

  test "page counts clockwise seen from above, and sim anticlockwise":
    ## Chain's C5 is wound half turn clockwise, and sim turns anticlockwise for
    ## positive turns, so C5 is asked negative, and every single-hand card is
    ## asked against its manner's own sense.
    check byKey["C5"].turns == -0.5
    check byKey["C3"].turns == 0.5
    check wayOf(HalfTurns(1)) == Way.Clockwise
    for manner in Manner:
      let tag = MANNERS[manner].tag
      check byKey["st_" & tag & "_0_1"].turns == -windSense(manner) * 0.25
