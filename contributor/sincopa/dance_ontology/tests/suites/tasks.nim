## What reference's cards ask of body sim, held to being one question wherever one
## picture is drawn.

{.experimental: "strictFuncs".}

import std/[math, options, tables, unittest]

import ../../design/[asks, parts]
import ../../sim/[rig, words]
from ../../sim/rigid import restStance
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
      check a.rest == c.rest
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


suite "each hold rests at named facing":

  test "each chain rests where its connections run parallel, and alternates from there":
    ## Hand to hand runs parallel Face-to-face, and crossed pair Face-to-back (rule 31).
    ##   Chain steps by half turns, so facing is rest at whole turns and other
    ##     of two at halves.
    for (holds, rest, other) in [(HAND_TO_HAND, Facing.FaceToFace, Facing.FaceToBack),
                                 (PAIRED, Facing.FaceToBack, Facing.FaceToFace)]:
      check restOf(holds) == rest
      for wind in STEPS:
        let whole = abs(wind - round(wind)) < 1e-9
        check facingAt(holds, wind) == some(if whole: rest else: other)

  test "sim is told each card's rest where it stands couple":
    ## Card names its rest from model (`parts.restOf`), and sim is told only
    ##   `away`.  Stance sim then stands couple in, read by sim's own words, is
    ##   what card named.  Distance puts no one at other side of other.
    for a in stillAsks():
      checkpoint a.key
      check facingName(restStance(HUMAN, 1.0, a.away)) == some(a.rest.name)

  test "sim is asked no rest it cannot stand":
    ## Sim stands couple Face-to-face or follow turned half, and no other rest.
    for rest in Facing:
      if rest in {Facing.FaceToFace, Facing.FaceToBack}:
        discard awayFor(rest)
      else:
        expect Defect: discard awayFor(rest)
