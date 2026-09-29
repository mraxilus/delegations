## What reference's cards ask of body simulation, held to being one question wherever one
## picture is drawn.

{.experimental: "strictFuncs".}

import std/[json, math, options, strutils, tables, unittest]

import ../../design/[asks, modelled, parts, rig_page]
from ../../design/rig as recording import KEPT_RIG, rigStamp
import ../../simulation/[rig, words]
from ../../simulation/rigid import restStance
import ../../src/dance_ontology/rotation


suite "what each card asks of simulation":
  var ask_by_key = initTable[string, StillAsk]()
  for ask in stillAsks(): ask_by_key[ask.key] = ask

  test "one picture is one question, whichever section draws it":
    ## Standard diagram's A16 is hand to hand wound half turn clockwise, which
    ## is chain's C5, and A17 is C3.  Asked with opposite signs, simulation stood A16 in
    ## C3's pose and A17 in C5's, mirror of what each card draws.
    for (frame, chain) in [("A16", "C5"), ("A17", "C3")]:
      let (frame_ask, chain_ask) = (ask_by_key[frame], ask_by_key[chain])
      check frame_ask.links == chain_ask.links
      check frame_ask.rest == chain_ask.rest
      check frame_ask.head == chain_ask.head
      check frame_ask.turns == chain_ask.turns

  test "page counts clockwise seen from above, and simulation anticlockwise":
    ## Chain's C5 is wound half turn clockwise, and simulation turns anticlockwise for
    ## positive turns, so C5 is asked negative, and every single-hand card is
    ## asked against its manner's own sense.
    check ask_by_key["C5"].turns == -0.5
    check ask_by_key["C3"].turns == 0.5
    check wayOf(HalfTurns(1)) == Way.Clockwise
    for manner in Manner:
      let tag = MANNERS[manner].tag
      check ask_by_key["st_" & tag & "_0_1"].turns == -windSense(manner) * 0.25


suite "each hold rests at named facing":

  test "each chain rests where its connections run parallel, and alternates from there":
    ## Hand to hand runs parallel Face-to-face, and crossed pair Face-to-back (rule 31).
    ##   Chain steps by half turns, so facing is rest at whole turns and other
    ##     of two at halves.
    for (holds, rest, other) in [(HAND_TO_HAND, Facing.FaceToFace, Facing.FaceToBack),
                                 (PAIRED, Facing.FaceToBack, Facing.FaceToFace)]:
      check restOf(holds) == rest
      for wind in STEPS:
        let is_whole = abs(wind - round(wind)) < 1e-9
        check facingAt(holds, wind) == some(if is_whole: rest else: other)

  test "simulation is told each card's rest where it stands couple":
    ## Card names its rest from model (`parts.restOf`), and simulation is told only
    ##   `away`.  Stance simulation then stands couple in, read by simulation's own words, is
    ##   what card named.  Distance puts no one at other side of other.
    for ask in stillAsks():
      checkpoint ask.key
      check facingName(restStance(HUMAN, 1.0, ask.isRestAway)) == some(ask.rest.name)

  test "simulation is asked no rest it cannot stand":
    ## Simulation stands couple Face-to-face or follow turned half, and no other rest.
    for rest in Facing:
      if rest in {Facing.FaceToFace, Facing.FaceToBack}:
        discard isRestAway(rest)
      else:
        expect Defect: discard isRestAway(rest)


suite "each recording is of tree it is kept in":
  ## Verb whose stamp is unchanged records nothing again (`design/stamps`), so recording kept
  ##   with other stamp is of other physics, other questions or other verb.  Page would show it
  ##   as this tree's answer.

  test "answers the reference page tags carry the stamp the tree gives":
    check parseFile(KEPT_MODELLED)["stamp"].getStr == modelledStamp()

  test "recording the rig page plays carries the stamp the tree gives":
    check parseFile(KEPT_RIG)["stamp"].getStr == rigStamp()

  test "rig page folds in the recording without its stamp, and nothing else left out":
    ## Stamp changes with any change to physics, where page shows none.
    let
      text = readFile(KEPT_RIG).strip()
      folded = parseJson(text.unstamped)
    var kept = parseJson(text)
    kept.delete("stamp")
    check not folded.hasKey("stamp")
    check folded == kept
