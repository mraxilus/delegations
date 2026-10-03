## What reference's cards ask of body simulation, held to being one question wherever one
## picture is drawn.

{.experimental: "strictFuncs".}

import std/[json, math, options, strformat, strutils, tables, unittest]

import ../../design/[asks, modelled, parts, rig_page, twins]
from ../../design/rig as recording import KEPT_RIG, rigStamp
import ../../simulation/[body, hold, limb, read, rig, vector, words]
from ../../simulation/plan import isMirrorSame
from ../../simulation/rigid import faceCapsule, Mark, restStance, trunkCapsules
from ../../simulation/walk import stands, STYLES, twinOf
import ../../src/dance_ontology/rotation
from ../../src/dance_ontology/draw/pose import relative
from ../../src/dance_ontology/draw/route import overArm
import ../../src/dance_ontology/frame


const
  ARRANGED = 1e-6  ## Degrees two arrangements may differ by: arithmetic alone.
  STRAIN_SAME = 1e-9  ## Strain two figures of one pose may differ by, in one recording: none.
  FACE_SLOP = 0.005  ## Metres arm may sit inside face: engine's own linear slop, which it never
                    ## resolves (`test_rigid.SLOP`).


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

func capsuleAt(frame: JsonNode, i: int): tuple[a, z: Vector] =
  ## Two ends of `i`th capsule of one recorded moment.
  ((frame[6 * i].getFloat, frame[6 * i + 1].getFloat, frame[6 * i + 2].getFloat),
   (frame[6 * i + 3].getFloat, frame[6 * i + 4].getFloat, frame[6 * i + 5].getFloat))

func faceGapOf(recording, frame: JsonNode): float =
  ## Nearest any arm of either dancer comes to either face at one recorded moment, past both
  ## radii: face placed off recording's own head and torso, as `rigid.faceCapsule` sets it.
  ##   Torso is two capsules side by side, left first (`rigid.trunkCapsules`), so they give
  ##     chest's right, and head is last capsule of trunk.
  let
    (tags, radii) = (recording["tag"], recording["radii"])
    face = faceCapsule(HUMAN)
    (head_low, head_high, _) = trunkCapsules(HUMAN)[^1]
    offset = face.a - (head_low + head_high) * 0.5
    upward: Vector = (0.0, 0.0, 1.0)
  var faces: seq[Vector]
  for who in Body:
    var trunk: seq[int]
    for i in 0..<tags.len:
      if tags[i][0].getInt == ord(who) and tags[i][2].getInt == ord(Mark.Trunk): trunk.add i
    let
      rightward = unit(capsuleAt(frame, trunk[1]).a - capsuleAt(frame, trunk[0]).a)
      forward = cross(upward, rightward)
      head = capsuleAt(frame, trunk[^1])
    faces.add (head.a + head.z) * 0.5 + rightward * offset.x + forward * offset.y +
              upward * offset.z
  result = Inf
  for i in 0..<tags.len:
    if tags[i][2].getInt notin [ord(Mark.Upper), ord(Mark.Fore), ord(Mark.Palm)]: continue
    let limb = capsuleAt(frame, i)
    for centre in faces:
      result = min(
        result,
        closest(limb.a, limb.z, centre, centre).gap - radii[i].getFloat - face.radius,
      )



suite "Internal: What each card asks of simulation":
  var ask_by_key = initTable[string, StillAsk]()
  for ask in stillAsks(): ask_by_key[ask.key] = ask


  test "one picture is one question, whichever section draws it":
    ## Standard diagram's A16 is hand to hand wound half turn clockwise, which
    ## is chain's C05, and A17 is C03.  Asked with opposite signs, simulation stood A16 in
    ## C03's pose and A17 in C05's, mirror of what each card draws.
    ##   Crossed pair is chain's own: A09, left to left over right to right Face-to-face, is
    ##     D05, and A11, right over left, is D03.  Red with crossed pair's half turn asked one
    ##     way, or either way: A11 stood A09's crossing, measured 2026-10-02.
    for (frame, chain) in [("A16", "C05"), ("A17", "C03"), ("A09", "D05"), ("A11", "D03")]:
      checkpoint frame & " against " & chain
      let (frame_ask, chain_ask) = (ask_by_key[frame], ask_by_key[chain])
      check frame_ask.links == chain_ask.links
      check frame_ask.rest == chain_ask.rest
      check frame_ask.who == chain_ask.who
      check frame_ask.turns == chain_ask.turns
      check frame_ask.is_either_way == chain_ask.is_either_way


  test "page counts clockwise seen from above, and simulation anticlockwise":
    ## Chain's C05 is wound half turn clockwise, and simulation turns anticlockwise for
    ## positive turns, so C05 is asked negative.
    check ask_by_key["C05"].turns == -0.5
    check ask_by_key["C03"].turns == 0.5
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
  ## Laws read each still as page shows it, so twin card is read as still it mirrors
  ##   (`design/twins`).
  let recorded = block:
    var stills = initTable[string, JsonNode]()
    for still in stillsShown(parseFile(KEPT_RIG)): stills[still["key"].getStr] = still
    stills
  var ask_by_key = initTable[string, StillAsk]()
  for ask in stillAsks(): ask_by_key[ask.key] = ask


  test "every crossed still lays connection its card names over at lead's crossing":
    ## Card is named for lead's arm on top where lead's two arms cross (`route.overArm`):
    ##   crossing nearest lead along both connections.  Frame names its own (`Frame.over`).
    ##   Red with A11 asked A09's way about, measured 2026-10-02: left over right, where card
    ##     draws right over left.
    var named: seq[(string, Arm)]
    for i, target in FRAMES:
      if target.over.isSome:
        let key = &"A{i * 2 + 1:02}"
        if ask_by_key[key].turns != 0.0:
          named.add (key, (if target.over.get == Side.Left: Arm.Left else: Arm.Right))
    for (tag, arms) in [("C", HAND_TO_HAND), ("D", PAIRED)]:
      for i, wind in STEPS:
        if wind != 0.0: named.add (&"{tag}{i + 1:02}", armOf(overArm(wind)))
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


  test "every still stands easiest pose that held, and its search tried every pose short of ease":
    ## Carried walk tries every distance, and planner every style and way, and each keeps pose
    ##   nearest to ease that holds (`walk.standing`, `walk.plannedStill`).  Search
    ##   ends early only at pose at ease, which nothing betters.
    ##   Red with first plan that held kept, measured 2026-10-03: C06 stood follow's waist at its
    ##     end, strain 1.00, where other path of same style held at 0.19.
    var distances = 0
    for _ in stands(HUMAN): inc distances
    var checked = 0
    for key, still in recorded:
      if not still.hasKey("at"): continue
      let
        ask = ask_by_key[key]
        ways = (if ask.is_either_way: 2 else: 1)
        paths = (if isMirrorSame(ask.links): 2 else: 1)
        candidates = (if still["planned"].getBool: STYLES.len * paths * ways else: distances * ways)
        stood = still["strain"].getFloat
      var easiest = Inf
      for strain in still["tried"].getElems:
        if strain.kind != JNull: easiest = min(easiest, strain.getFloat)
      checkpoint &"`{key}` stood at strain `{stood}`; easiest pose tried held at `{easiest}`."
      check abs(stood - easiest) < STRAIN_SAME
      if stood > 0.0: check still["tried"].len == candidates
      inc checked
    check checked == stillAsks().len


  test "each reflected twin card names card that keeps answer to its mirror twin":
    ## Twin card keeps no still of its own (`design/rig`): it names first card that asks its
    ##   mirror twin unreflected (`walk.twinOf`), and page shows that still mirrored.  Where
    ##   no card asks it, twin card keeps that answer itself and names itself.
    ##   Mirror is its own undoing, figure for figure, on every still that holds.
    let kept = parseFile(KEPT_RIG)
    var marks, dofs: seq[string]
    for name in kept["marks"]: marks.add name.getStr
    for name in kept["dofs"]: dofs.add name.getStr
    func isAnswerTo(other, ask: StillAsk, links: seq[Link], turns: float): bool =
      ## Whether `other` asks question that answers twin `ask`, unreflected.
      not twinOf(other.links, other.turns, other.isRestAway).is_reflected and
        other.links == links and other.turns == turns and
        other.isRestAway == ask.isRestAway and other.head == ask.head and
        other.is_either_way == ask.is_either_way and other.who == ask.who
    var twins, keeping = 0
    for still in kept["stills"]:
      let
        ask = ask_by_key[still["key"].getStr]
        twin = twinOf(ask.links, ask.turns, ask.isRestAway)
      checkpoint ask.key
      check still.hasKey("mirror") == twin.is_reflected
      if still.hasKey("at") and still["at"].len > 0:
        let key = still["key"].getStr
        var plain = still.copy
        if plain.hasKey("mirror"): plain.delete("mirror")
        check mirrored(mirrored(still, key, marks, dofs), key, marks, dofs) == plain
      if not twin.is_reflected: continue
      inc twins
      var askers: seq[string]
      for other in stillAsks():
        if other.isAnswerTo(ask, twin.links, twin.turns): askers.add other.key
      if askers.len == 0:
        inc keeping
        check still["mirror"].getStr == ask.key
        check still.hasKey("turns")
      else:
        check still["mirror"].getStr == askers[0]
        check not still.hasKey("turns")
    checkpoint &"`{twins}` twin cards, `{keeping}` keep their own answer"
    check twins > 0


  test "each arm's girdle stands on its own side of its chest, in every still page shows":
    ## Page colours each arm by side it is named for (`rig_view.inkOf`), so arm named left
    ##   is to stand left.  Twin card's still is mirrored, so each arm is named as arm of
    ##   other side (`design/twins`); named as before, it would be drawn in other arm's colour.
    var (stills, girdles) = (0, 0)
    for key, still in recorded:
      if not still.hasKey("at") or still["at"].len == 0: continue
      inc stills
      let (tags, row, look) = (still["tag"], still["points"][0], still["faces"][0])
      for i in 0..<tags.len:
        if tags[i][2].getInt != ord(Mark.Girdle): continue
        let
          (who, side) = (tags[i][0].getInt, tags[i][1].getInt)
          (at_x, at_y) = (look[4 * who].getFloat, look[4 * who + 1].getFloat)
          (fore_x, fore_y) = (look[4 * who + 2].getFloat, look[4 * who + 3].getFloat)
          middle_x = (row[6 * i].getFloat + row[6 * i + 3].getFloat) / 2.0
          middle_y = (row[6 * i + 1].getFloat + row[6 * i + 4].getFloat) / 2.0
          rightward = (middle_x - at_x) * fore_y - (middle_y - at_y) * fore_x
        checkpoint &"`{key}` girdle of `{who}` `{side}` stands `{rightward:.3f}` rightward"
        check (rightward > 0.0) == (side == ord(Arm.Right))
        inc girdles
    check girdles == 4 * stills


  test "every arm keeps clear of every face, in every still and every moment of every sweep":
    ## Each dancer keeps each arm clear of every face, own and partner's (#375).  Each still
    ##   is read as page shows it, so twin card is read as still it mirrors.
    ##   Red with no face in planner or engine, measured 2026-10-03: 313 of 652 recorded moments
    ##     held arm inside face, 47 mm at deepest, nearly all dancer's own forearm across own face
    ##     with hand over crown.
    let kept = parseFile(KEPT_RIG)
    var
      moments = 0
      inside: seq[string]
      deepest = Inf
    for recording in stillsShown(kept) & kept["sweeps"].getElems:
      let name =
        if recording.hasKey("key"): recording["key"].getStr
        else: recording["hold"].getStr & " " & recording["band"].getStr
      for moment, frame in recording["points"].getElems:
        let gap = faceGapOf(recording, frame)
        inc moments
        deepest = min(deepest, gap)
        if gap < -FACE_SLOP: inside.add &"{name}@{moment}"
    checkpoint &"`{inside.len}` of `{moments}` moments hold arm inside face, deepest at " &
      &"`{deepest}` m: " & inside[0..<min(inside.len, 12)].join(" ")
    check moments >= stillAsks().len
    check inside.len == 0


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


  test "rig page folds in the recording without its stamp, each twin mirrored, nothing left out":
    ## Stamp changes with any change to physics, where page shows none.  Twin card is folded
    ##   in as still it names, mirrored (`design/twins`).
    let
      kept = parseFile(KEPT_RIG)
      page = folded(kept)
      shown = stillsShown(kept)
    check not page.hasKey("stamp")
    for field, value in kept.pairs:
      if field notin ["stamp", "stills"]: check page[field] == value
    check page["stills"].len == kept["stills"].len
    for i, still in kept["stills"].getElems:
      check page["stills"][i] == shown[i]
      if not still.hasKey("mirror"): check page["stills"][i] == still
