## What reference's cards ask of body simulation, held to being one question wherever one
## picture is drawn.

{.experimental: "strictFuncs".}

import std/[json, math, options, strformat, strutils, tables, unittest]

import ../../design/[asks, modelled, parts, rig_page]
from ../../design/rig as recording import KEPT_RIG, rigStamp
import ../../simulation/[body, hold, limb, read, rig, vector, words]
from ../../simulation/rigid import restStance
import ../../src/dance_ontology/rotation
from ../../src/dance_ontology/draw/pose import relative
from ../../src/dance_ontology/draw/route import overArm
import ../../src/dance_ontology/frame


const ARRANGED = 1e-6  ## Degrees two arrangements may differ by: arithmetic alone.


func arranged(stance: array[Body, Stance]): tuple[axis, facing: float] =
  ## Where follow stands and how they face, both against lead, in degrees clockwise seen from
  ## above: what `pose.relative` reads off drawing, read off simulation's stance.
  ##   Simulation counts anticlockwise from its x and drawing clockwise from up page, which
  ##     is simulation's y.

  func page(radians: float): float = 90.0 - radians * 180.0 / PI

  let
    (one, two) = (stance[Body.One], stance[Body.Two])
    bearing = page(arctan2(two.centre.y - one.centre.y, two.centre.x - one.centre.x))
  (floorMod(bearing - page(one.facing), 360.0),
   floorMod(page(two.facing) - page(one.facing), 360.0))

func apartOf(a, b: float): float =
  ## How far two bearings in degrees are apart, round either way.
  let d = floorMod(a - b, 360.0)
  min(d, 360.0 - d)

func armOf(still: JsonNode, who: Body, arm: Arm): ArmPose =
  ## One arm as recording keeps it, from engine's own capsules: each limb's capsule runs
  ##   its radius in from both joints, and palm's sphere sits half hand past wrist.
  let
    tags = still["tag"].getElems
    points = still["points"][^1].getElems
    radii = still["radii"].getElems
  var capsules: array[1..3, tuple[a, z: Vector, radius: float]]
  for i, tag in tags:
    let part = tag[2].getInt
    if tag[0].getInt == ord(who) and tag[1].getInt == ord(arm) and part in 1..3:
      capsules[part] = ((points[6 * i].getFloat, points[6 * i + 1].getFloat,
                         points[6 * i + 2].getFloat),
                        (points[6 * i + 3].getFloat, points[6 * i + 4].getFloat,
                         points[6 * i + 5].getFloat), radii[i].getFloat)
  let
    (upper, fore, palm) = (capsules[1], capsules[2], capsules[3])
    upward = unit(upper.z - upper.a)
    forward = unit(fore.z - fore.a)
  result.shoulder = upper.a - upward * upper.radius
  result.elbow = upper.z + upward * upper.radius
  result.wrist = fore.z + forward * fore.radius
  result.grip = palm.a * 2.0 - result.wrist

func armsOf(still: JsonNode, links: seq[Link]): Arms =
  ## Every connection's two arms, lead's first, as recording keeps them.
  for link in links:
    result.add [armOf(still, link.ends[0].body, link.ends[0].arm),
                armOf(still, link.ends[1].body, link.ends[1].arm)]



suite "Internal: What each card asks of simulation":
  var ask_by_key = initTable[string, StillAsk]()
  for ask in stillAsks(): ask_by_key[ask.key] = ask


  test "one picture is one question, whichever section draws it":
    ## Standard diagram's A16 is hand to hand wound half turn clockwise, which
    ## is chain's C5, and A17 is C3.  Asked with opposite signs, simulation stood A16 in
    ## C3's pose and A17 in C5's, mirror of what each card draws.
    ##   Crossed pair is chain's own: A9, left to left over right to right Face-to-face, is
    ##     D5, and A11, right over left, is D3.  Red with crossed pair's half turn asked one
    ##     way, or either way: A11 stood A9's crossing, measured 2026-10-02.
    for (frame, chain) in [("A16", "C5"), ("A17", "C3"), ("A9", "D5"), ("A11", "D3")]:
      checkpoint frame & " against " & chain
      let (frame_ask, chain_ask) = (ask_by_key[frame], ask_by_key[chain])
      check frame_ask.links == chain_ask.links
      check frame_ask.rest == chain_ask.rest
      check frame_ask.who == chain_ask.who
      check frame_ask.turns == chain_ask.turns
      check frame_ask.is_either_way == chain_ask.is_either_way


  test "page counts clockwise seen from above, and simulation anticlockwise":
    ## Chain's C5 is wound half turn clockwise, and simulation turns anticlockwise for
    ## positive turns, so C5 is asked negative.
    check ask_by_key["C5"].turns == -0.5
    check ask_by_key["C3"].turns == 0.5
    check wayOf(HalfTurns(1)) == Way.Clockwise


  test "every single-hand card stands where its cell draws follow, facing as drawn":
    ## Simulation turns one dancer on their own spot, and partner stays where they stand:
    ##   lead who turned quarter has follow at their side, and follow who turned is still
    ##   ahead.  So who turns is half of what card asks, and drawing says which half
    ##   (`parts.quarterPose`).
    ##   Red with every single-hand card wound by turning follow alone, measured 2026-10-02:
    ##     every lead's turn and every orbit of follow stood follow ahead of lead.
    for single_index, single in SINGLES:
      for manner in Manner:
        for quarter in 0..<QUARTERS_ROUND:
          let
            ask = ask_by_key[&"st_{MANNERS[manner].tag}_{single_index}_{quarter}"]
            stood = arranged(turned(restStance(HUMAN, 1.0, ask.isRestAway), ask.who, ask.turns))
            drawn = relative(quarterPose(manner, quarter))
          checkpoint ask.key & ": stood " & $stood & ", drawn " & $drawn
          check apartOf(stood.axis, drawn.axis) < ARRANGED
          check apartOf(stood.facing, drawn.facing) < ARRANGED


  test "two cards of one cell stand one arrangement, turned by one dancer":
    ## Orbit lands where partner's axis turn lands (`parts.FAMILY_OF`), and page folds
    ##   both onto one cell.  So both turn one dancer, and hands go over one crown.
    ##   Red with orbit asked over walker's crown, measured 2026-10-02: every orbit's still
    ##     stood its other manner's pose, follow's orbit as follow's own turn.
    for single_index in 0..<SINGLES.len:
      for manner in Manner:
        for mate in Manner:
          for quarter in 0..<QUARTERS_ROUND:
            for other in 0..<QUARTERS_ROUND:
              if placeOf(quarterPose(manner, quarter)) != placeOf(quarterPose(mate, other)):
                continue
              if quarter == 0: continue
              let
                one = ask_by_key[&"st_{MANNERS[manner].tag}_{single_index}_{quarter}"]
                two = ask_by_key[&"st_{MANNERS[mate].tag}_{single_index}_{other}"]
              checkpoint one.key & " against " & two.key
              check one.who == two.who
              check one.head == two.head


  test "every card carries joined hands over crown of dancer who turns":
    ## Connection goes round dancer whose facing turns against it, and over crown it goes
    ##   round over their head.  Orbit keeps walker facing centre, so centre dancer turns
    ##   against connection, and hands go over their crown (`asks.turnerOf`).
    ##   Red with orbit asked over walker's crown, and every still turned by follow alone,
    ##     measured 2026-10-02.
    for ask in stillAsks():
      checkpoint ask.key
      check ask.head == ask.who
    for question in questions():
      checkpoint question.key
      check question.head == question.who


  test "every single-hand move ends where its cell's walk ends":
    ## Page walks every manner's own dancer clockwise, one quarter per card
    ##   (`parts.singleTurnParts`), and move ends where next quarter draws couple.
    ##   Red with lead's own turn and lead's orbit turned by chain's sense, measured
    ##     2026-10-02: both went anticlockwise, and every quarter of them ended in mirror image
    ##     of its cell.
    var moves = 0
    for question in questions():
      if not question.key.startsWith("tr_"): continue
      let
        parts = question.key.split('_')
        manner = block:
          var found = Manner.low
          for candidate in Manner:
            if MANNERS[candidate].tag == parts[1]: found = candidate
          found
        stood = arranged(
          turned(restStance(HUMAN, 1.0, question.is_away), question.who, question.turns),
        )
        drawn = relative(quarterPose(manner, parseInt(parts[4])))
      inc moves
      checkpoint question.key & ": stood " & $stood & ", drawn " & $drawn
      check apartOf(stood.axis, drawn.axis) < ARRANGED
      check apartOf(stood.facing, drawn.facing) < ARRANGED
    check moves == SINGLES.len * 4 * QUARTERS_ROUND



suite "Internal: Each hold rests at named facing":
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



suite "Internal: Simulation against reference":
  let recorded = block:
    var stills = initTable[string, JsonNode]()
    for still in parseFile(KEPT_RIG)["stills"].getElems: stills[still["key"].getStr] = still
    stills
  var ask_by_key = initTable[string, StillAsk]()
  for ask in stillAsks(): ask_by_key[ask.key] = ask


  test "every crossed still lays connection its card names over at lead's crossing":
    ## Card is named for lead's arm on top where lead's two arms cross (`route.overArm`):
    ##   crossing nearest lead along both connections.  Frame names its own (`Frame.over`).
    ##   Red with A11 asked A9's way about, measured 2026-10-02: left over right, where card
    ##     draws right over left.
    var named: seq[(string, Arm)]
    for i, target in FRAMES:
      if target.over.isSome:
        let key = &"A{i * 2 + 1}"
        if ask_by_key[key].turns != 0.0:
          named.add (key, (if target.over.get == Side.Left: Arm.Left else: Arm.Right))
    for (tag, arms) in [("C", HAND_TO_HAND), ("D", PAIRED)]:
      for i, wind in STEPS:
        if wind != 0.0: named.add (tag & $(i + 1), armOf(overArm(wind)))
    check named.len == 14
    for (key, arm) in named:
      let
        ask = ask_by_key[key]
        found = crossings(armsOf(recorded[key], ask.links))
      checkpoint key & ": " & $found.len & " crossings"
      check found.len > 0
      if found.len == 0: continue
      var first = found[0]
      for crossing in found:
        if crossing.along + crossing.across < first.along + first.across: first = crossing
      check ask.links[first.over].ends[0].arm == arm


  test "simulation models every card reference draws":
    ## Every position and movement reference draws is one dancers take with ease, so card
    ##   simulation cannot reach is fault of simulation, never of card.
    ##   Red with arms carried by pulls on hands alone: 33 of 231 cards unmodelled, all four
    ##     swans and every whole chain among them, measured 2026-10-02.
    let answers = parseFile(KEPT_MODELLED)["answers"]
    var unmodelled: seq[string]
    for key, answer in answers.pairs:
      if not answer.getBool: unmodelled.add key
    checkpoint "unmodelled: " & unmodelled.join(" ")
    check answers.len == questions().len
    check unmodelled.len == 0



suite "Internal: Each recording is of tree it is kept in":
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
