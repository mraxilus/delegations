## What Reference's cards ask of body simulation, held to being one question wherever one
## picture is drawn.

{.experimental: "strictFuncs".}

import std/[algorithm, json, jsonutils, math, options, sequtils, sets, strformat, strutils, tables,
            unittest]

import ../../design/[asks, modelled, parts, rig_page, twins, watch]
from ../../design/rig as recording import KEPT_RIG, rigStamp
from ../../design/rig {.all.} import BANDS, PLACE, SHOWN
import ../../simulation/[body, hold, limb, read, rig, vector, words]
from ../../simulation/plan import isMirrorSame, STRIDE
from ../../simulation/readings import KEPT_READINGS, Readings
from ../../simulation/rigid import ELBOW_END, ELBOWS_APART, faceCapsule, Mark, ON_UPPER, OVER,
  restStance, SAG, trunkCapsules
from ../../simulation/rigid {.all.} import RAISE
from ../../simulation/walk import mirrored, MOST, stands, STEP, STYLES, twinAnswering
import ../../src/dance_ontology/rotation
from ../../src/dance_ontology/draw/pose import relative
from ../../src/dance_ontology/draw/route import overArm
import ../../src/dance_ontology/frame


const
  ARRANGED = 1e-6  ## Degrees two arrangements may differ by: arithmetic alone.
  STRAIN_SAME = 1e-9  ## Strain two figures of one pose may differ by, in one recording: none.
  NOSE = 0.12  ## Metres nose sits ahead of head's axis, by ANSUR II head length 0.20 / 0.19 m.
  FACE_HALF = 0.07  ## Metres from middle of face to cheek: half breadth across cheekbones, about
                    ## 0.14 m by ANSUR II.  Estimate and not tape.
  FACE_SLOP = 0.005  ## Metres arm may sit inside face: engine's own linear slop, which it never
                    ## resolves (`test_rigid.SLOP`).
  PLACE_RIG = 1.0 / 10.0^PLACE
    ## Rig's recording rounds every figure to this, metres and turns alike (`design/rig.PLACE`).
  LEAP_RIG = 2.0 * PI * STEP * (HUMAN.shoulder_out + span(HUMAN)) + 0.08
    ## Furthest any joint of joined hand's arm, or any join, may move between two moments of rig
    ##   sweep: bound each walk is held to (`test_rigid.LEAP`), 195 mm on true-size hand.
  FLOOR_AWAY_RIG = 106
    ## Least moments past face to face law on hands over crown reads from rig's sweeps over
    ##   crown: half of 213 read 2026-10-12, on recording of wall on step.  Fix may stop sweep
    ##   early or carry it further; reader that loses its way, by wrong rest or wrong keys, reads
    ##   nearly none.
  TURNS_PLANNED = [
    (card: "One hand, same name · above", positive: MOST),
    (card: "One hand, cross name · above", positive: MOST),
    (card: "Chain, cross name · above", positive: 1.5275),
    (card: "Chain, same name · above", positive: MOST),
    (card: "Chain, cross name · high", positive: 0.8438),
    (card: "Chain, same name · high", positive: 0.6500),
    (card: "Chain, cross name · low", positive: 0.8650),
    (card: "Chain, same name · low", positive: 0.7400),
  ]
    ## Turns plan carries each rig sweep from rest, at band of its hold, way that turns positive,
    ##   follow turning: furthest of every style toward all sweep asks (`walk.MOST`), own path
    ##   and its mirror's (`walk.pathsFor`), engine standing each moment (`walk.replayedWay`,
    ##   `rigid.gives`).  Rig keeps that way alone (`seen.shown`), so table floors no other.
    ##   Keyed by card and level as rig names its sweep, in order of `design/rig.SHOWN`, so
    ##     `floors` prints table row for row.
    ##   Measured by `nim r tools/build.nim floors`, which prints each row with style and start
    ##     of its path.  Rows above: 2026-10-12, on physics of `6ef96eaf`, same again
    ##     2026-10-20, and same again 2026-10-29, on physics of `fd756cfb`:
    ##     One hand, same name: style 0 to +2.5, from 1.169 m on 2026-10-29.
    ##     One hand, cross name: style 2 to +2.5, from 0.966 m on 2026-10-29.
    ##     Chain, cross name: style 13, from 0.957 m, to 1.5275.
    ##     Chain, same name: style 4, from 0.417 m.
    ##   Rows held high and low: 2026-10-29, on physics of `fd756cfb`, each to where no plan
    ##     carries turn further:
    ##     Chain, cross name, high: style 1, from 1.115 m.
    ##     Chain, same name, high: style 14, from 0.670 m.
    ##     Chain, cross name, low: style 11, from 1.105 m.
    ##     Chain, same name, low: style 3, from 0.389 m.
    ##   Edge holds cross-name chain near there, its upper arm riding plan's six degrees inside:
    ##     plan with edge's margin at 0 or 3 degrees, other margins kept, stands no path past
    ##     1.540 or 1.526, and plan with no edge term none past 1.4475, engine stopping each by
    ##     swing where upper arm passes edge's give.  Measured 2026-10-12 by probes outside tree.
  REASON_WHOLE = "lead's turn of same-name chain held above, from Face-to-back, to whole " &
      "turn: no plan inside shoulder's edge passes 0.71 of turn, and no wall tried carries walk " &
      "there but by chance"
    ## Why shoulder's edge refuses whole turn of same-name chain held above.
  REASON_HALF_MORE = "lead's turn of same-name chain held above, from Face-to-back, to turn " &
      "and half: plans that reach it lift follow's upper arms behind head, up to 90 degrees past " &
      "shoulder's edge, and none inside edge passes 0.71 of turn"
    ## Why shoulder's edge refuses turn and half of same-name chain held above.
  CARDS_REFUSED = [
    (key: "pw_la_4", reason: REASON_WHOLE),
    (key: "pw_fo_4", reason: REASON_WHOLE),
    (key: "pc_la", reason: REASON_HALF_MORE),
    (key: "pw_la_5", reason: REASON_HALF_MORE),
    (key: "pc_fo", reason: REASON_HALF_MORE),
    (key: "pw_fo_5", reason: REASON_HALF_MORE),
  ]
    ## Cards shoulder's edge refuses, each with its reason (Architect, issue 611, 2026-10-11,
    ##   D1): first wall tried for two at whole turn, then each card still failing named here.
    ##   `la` is lead's turn and `fo` follow's orbit, which asks same (`asks.turner`).
    ##   Measured 2026-10-11 and 2026-10-12 by probes outside tree (`PROVENANCE.md`, Planned
    ##     turn, and Open questions).


type Lifted = tuple[card: string, at: float, who: Body, arm: Arm, z: float]
  ## One joined hand at one recorded moment past face to face: card, turns from rest, whose
  ## hand, and height it is carried at (`limb.pointCarried`).


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

func apart(a, b: float): float =
  ## How far two bearings in degrees are apart, round either way.
  let d = floorMod(a - b, 360.0)
  min(d, 360.0 - d)

func toArmPose(still: JsonNode, who: Body, arm: Arm, join: Vector): ArmPose =
  ## One arm as recording keeps it, from engine's own capsules, holding at `join`: each
  ##   limb's capsule runs its radius in from both joints.
  ##   Sibling: `test_shoulder.armMomentsRig` reads elbow at forearm link's origin instead, as
  ##     judge does (`rigid.armPoseNow`).  Here it is upper arm's own end, as page draws it; two
  ##     differ by elbow's parting, up to 7.8 mm in `One hand, same name · above`.
  let
    tags = still["tag"].getElems
    points = still["points"][^1].getElems
    radii = still["radii"].getElems
  var capsules: array[1..2, tuple[a, z: Vector, radius: float]]
  for i, tag in tags:
    let part = tag[2].getInt
    if tag[0].getInt == ord(who) and tag[1].getInt == ord(arm) and part in 1..2:
      capsules[part] = ((points[6*i].getFloat, points[6*i+1].getFloat,
                         points[6*i+2].getFloat),
                        (points[6*i+3].getFloat, points[6*i+4].getFloat,
                         points[6*i+5].getFloat), radii[i].getFloat)
  let
    (upper, fore) = (capsules[1], capsules[2])
    upward = unit(upper.z - upper.a)
    forward = unit(fore.z - fore.a)
  result.shoulder = upper.a - upward * upper.radius
  result.elbow = upper.z + upward * upper.radius
  result.wrist = fore.z + forward * fore.radius
  result.join = join

func lineHand(still: JsonNode, who: Body, arm: Arm): tuple[a, z: Vector] =
  ## Hand's own line as recording keeps it: middle of its three capsules (`rigid.handCapsules`).
  let
    tags = still["tag"].getElems
    points = still["points"][^1].getElems
  var seen = 0
  for i, tag in tags:
    if tag[0].getInt == ord(who) and tag[1].getInt == ord(arm) and tag[2].getInt == ord(Mark.Palm):
      if seen == 1:
        return ((points[6*i].getFloat, points[6*i+1].getFloat, points[6*i+2].getFloat),
                (points[6*i+3].getFloat, points[6*i+4].getFloat, points[6*i+5].getFloat))
      inc seen
  raiseAssert "No hand of three capsules recorded for " & $who & " " & $arm & "."

func toArms(still: JsonNode, links: seq[Link]): Arms =
  ## Every connection's two arms, lead's first, as recording keeps them.
  ##   Join of each connection is found where it lies, on both its hands' lines: mirror twin
  ##     keeps its twin's joins in its twin's order (`twins.mirrored`), so order names no
  ##     connection.  Read by order, C06, which mirrors C02, laid its joins on other
  ##     connection and crossed nothing, where C02 crosses twice, measured 2026-10-08.
  let joins = still["joins"][^1].getElems
  for link in links:
    let
      a = lineHand(still, link.ends[0].body, link.ends[0].arm)
      b = lineHand(still, link.ends[1].body, link.ends[1].arm)
    var
      join: Vector
      nearest = Inf
    for j in 0 ..< joins.len div 3:
      let
        point: Vector = (joins[3*j].getFloat, joins[3*j+1].getFloat, joins[3*j+2].getFloat)
        off = closest(point, point, a.a, a.z).gap + closest(point, point, b.a, b.z).gap
      if off < nearest:
        (join, nearest) = (point, off)
    result.add [toArmPose(still, link.ends[0].body, link.ends[0].arm, join),
                toArmPose(still, link.ends[1].body, link.ends[1].arm, join)]

func capsuleAt(frame: JsonNode, i: int): tuple[a, z: Vector] =
  ## Two ends of `i`th capsule of one recorded moment.
  ((frame[6*i].getFloat, frame[6*i+1].getFloat, frame[6*i+2].getFloat),
   (frame[6*i+3].getFloat, frame[6*i+4].getFloat, frame[6*i+5].getFloat))

func gapFace(recording, frame: JsonNode): float =
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


func isCrossed(recording, frame: JsonNode): bool =
  ## Whether one dancer's own arms cross above elbow at one recorded moment, as `rigid.crossed`
  ## judges it: elbows out of order, or other arm on upper arm short of its elbow's end.
  ##   Each capsule of arm stops its radius short of both joints (`plan.placeArm`), and torso is
  ##     two capsules side by side, left first (`rigid.trunkCapsules`), so they give chest's right.
  let (tags, radii) = (recording["tag"], recording["radii"])
  var
    lines: seq[tuple[who, side, mark: int, a, z: Vector]]
    trunks: array[2, seq[int]]
  for i in 0..<tags.len:
    let
      (who, side, mark) = (tags[i][0].getInt, tags[i][1].getInt, tags[i][2].getInt)
      (a, z) = capsuleAt(frame, i)
    if mark == ord(Mark.Trunk): trunks[who].add i
    elif mark in [ord(Mark.Upper), ord(Mark.Fore)]:
      let along = unit(z - a) * radii[i].getFloat
      lines.add (who, side, mark, a - along, z + along)
  for who in 0..1:
    let rightward = unit(capsuleAt(frame, trunks[who][1]).a - capsuleAt(frame, trunks[who][0]).a)
    var elbows: array[2, Vector]
    for line in lines:
      if line.who == who and line.mark == ord(Mark.Upper): elbows[line.side] = line.z
    if dot(elbows[1] - elbows[0], rightward) < ELBOWS_APART: return true
  for upper in lines:
    if upper.mark != ord(Mark.Upper): continue
    for other in lines:
      if other.who != upper.who or other.side == upper.side: continue
      let met = closest(upper.a, upper.z, other.a, other.z)
      if met.gap - 2.0 * HUMAN.limb < ON_UPPER and
          (1.0 - met.t) * distance(upper.a, upper.z) > ELBOW_END:
        return true
  false


func away(at: float, is_away: bool): float =
  ## How far couple are from face to face at `at` turns from rest, in turns, nought to half: hips'
  ## wind, as `rigid.awayFrom` reads it, half turn more where rest is Face-to-back.
  let turned = floorMod(at + (if is_away: 0.5 else: 0.0), 1.0)
  min(turned, 1.0 - turned)

func roundedUnder(place, line, along: float): float =
  ## Metres point carried `along` past first of two recorded points, on their line, may read
  ## under engine's own: each figure rounded to `place`, two points at least `line` apart.
  ##   First point's own rounding, and turn of line by both points' rounding across it.
  place / 2.0 + along * sqrt(3.0) * place / line

func heldMoments(recording: JsonNode): int =
  ## Moments one rig sweep holds: every moment it keeps but one it stops at, where walk gave
  ## (`seen.shownAsked`).  Planned sweep keeps no such moment: its last stands.
  recording["at"].len -
      (if recording["stopped"].getBool and not recording{"planned"}.getBool: 1 else: 0)

func palmMiddles(recording: JsonNode): array[Body, array[Arm, int]] =
  ## Capsule of each hand that `rig.carry` is read along: middle of its three
  ## (`rigid.handCapsules`).
  for who in Body:
    for arm in Arm:
      var seen = 0
      for i, tag in recording["tag"].getElems:
        if tag[0].getInt != ord(who) or tag[1].getInt != ord(arm) or
            tag[2].getInt != ord(Mark.Palm): continue
        if seen == 1: result[who][arm] = i
        inc seen

func heldRig(recording: JsonNode): seq[Hand] =
  ## Joined hands of one rig sweep: of each dancer, one whose hand's line passes nearest each
  ## join at rest, two to each join.
  let
    middle = palmMiddles(recording)
    joins = recording["joins"][0]
  for j in 0 ..< joins.len div 3:
    let join: Vector = (joins[3*j].getFloat, joins[3*j+1].getFloat, joins[3*j+2].getFloat)
    for who in Body:
      var (nearest, gap) = (Arm.Left, Inf)
      for arm in Arm:
        let
          line = capsuleAt(recording["points"][0], middle[who][arm])
          off = closest(join, join, line.a, line.z).gap
        if off < gap: (nearest, gap) = (arm, off)
      result.add (who, nearest)

func carriedRig(recording: JsonNode, m: int, hand: Hand): Vector =
  ## Where `hand` is carried at moment `m`: middle of its hand's capsules, run back its radius
  ## to wrist, then `rig.carry` along it, as `limb.pointCarried` reads it.
  let
    i = palmMiddles(recording)[hand.body][hand.arm]
    (a, z) = capsuleAt(recording["points"][m], i)
  a + unit(z - a) * (HUMAN.carry - recording["radii"][i].getFloat)

func liftedRig(recording: JsonNode): tuple[hands: seq[Lifted], moments: int] =
  ## Every joined hand of one rig sweep at every moment couple are `RAISE` or more from face to
  ## face, where it is carried (`carriedRig`).
  ##   Joined hand is one of each dancer whose line passes nearest each join at rest
  ##     (`heldRig`).  Rest is Face-to-back where two chests face one way at nought.
  ##   Moments read are those sweep holds (`heldMoments`): every rig sweep is planned, and keeps
  ##     no moment that gave (`seen.shownAsked`).
  let
    card = recording["hold"].getStr & " · " & recording["band"].getStr
    look = recording["faces"][0]
    is_away = look[2].getFloat * look[6].getFloat + look[3].getFloat * look[7].getFloat > 0.0
    held = heldRig(recording)
  for m in 0..<heldMoments(recording):
    let at = recording["at"][m].getFloat
    if away(at, is_away) < RAISE: continue
    inc result.moments
    for hand in held:
      result.hands.add (card, at, hand.body, hand.arm, carriedRig(recording, m, hand).z)

func jointsHeld(recording, frame: JsonNode, held: seq[Hand]): seq[Vector] =
  ## Shoulder, elbow and wrist of each joined hand's arm at one recorded moment: each arm
  ## capsule stops its radius short of both joints (`plan.placeArm`), as `isCrossed` reads it.
  let (tags, radii) = (recording["tag"], recording["radii"])
  for hand in held:
    for i in 0..<tags.len:
      let mark = tags[i][2].getInt
      if tags[i][0].getInt != ord(hand.body) or tags[i][1].getInt != ord(hand.arm) or
          mark notin [ord(Mark.Upper), ord(Mark.Fore)]: continue
      let
        (a, z) = capsuleAt(frame, i)
        along = unit(z - a) * radii[i].getFloat
      if mark == ord(Mark.Upper): result.add [a - along, z + along]
      else: result.add z + along

func leapsRig(recording: JsonNode): seq[tuple[at, leap: float]] =
  ## Furthest any joint of joined hand's arm, or any join, moves into each moment one rig
  ## sweep holds, from moment before (`jointsHeld`, `heldMoments`).
  let
    held = heldRig(recording)
    frames = recording["points"]
    joins = recording["joins"]
  for m in 1..<heldMoments(recording):
    let
      before = jointsHeld(recording, frames[m-1], held)
      now = jointsHeld(recording, frames[m], held)
    var leap = 0.0
    for k in 0..<now.len: leap = max(leap, distance(before[k], now[k]))
    for j in 0 ..< joins[m].len div 3:
      let
        join_before: Vector = (joins[m-1][3*j].getFloat, joins[m-1][3*j+1].getFloat,
                               joins[m-1][3*j+2].getFloat)
        join_now: Vector = (joins[m][3*j].getFloat, joins[m][3*j+1].getFloat,
                            joins[m][3*j+2].getFloat)
      leap = max(leap, distance(join_before, join_now))
    result.add (recording["at"][m].getFloat, leap)

func named(hand: Lifted): string =
  ## Name joined hand at one moment as pages name it: card, whose hand, turns, and height.
  let
    who = (if hand.who == Body.One: "lead" else: "follow")
    arm = (if hand.arm == Arm.Left: "left" else: "right")
  &"{hand.card} {who} {arm} {hand.at:+.2f}: {hand.z:.3f} m"


func turnsHeldRig(kept: JsonNode): seq[tuple[card: string, held: float]] =
  ## Turns from rest of furthest moment each rig sweep holds, by its card and level.
  ##   Each sweep is its way that turns positive (`seen.shown`).
  for sweep in kept["sweeps"]:
    var held = 0.0
    if sweep.hasKey("at"):
      for m in 0..<heldMoments(sweep): held = max(held, abs(sweep["at"][m].getFloat))
    result.add (sweep["hold"].getStr & " · " & sweep["band"].getStr, held)

func floorPlanned(card: string): Option[float] =
  ## Turns plan carries rig's sweep `card`, at band of its hold, way that turns positive
  ##   (`TURNS_PLANNED`); none where table names no such card.
  for planned in TURNS_PLANNED:
    if planned.card == card: return some(planned.positive)



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
      check frame_ask.over == chain_ask.over


  test "page counts clockwise seen from above, and simulation anticlockwise":
    ## Chain's C05 is wound half turn clockwise, and simulation turns anticlockwise for
    ## positive turns, so C05 is asked negative.
    check ask_by_key["C05"].turns == -0.5
    check ask_by_key["C03"].turns == 0.5
    check wayTurn(HalfTurns(1)) == Way.Clockwise


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
          check apart(stood.axis, drawn.axis) < ARRANGED
          check apart(stood.facing, drawn.facing) < ARRANGED


  test "two cards of one cell stand one arrangement, turned by one dancer":
    ## Orbit lands where partner's axis turn lands (`parts.LUT_ROUND_BY_MANNER`), and page folds
    ##   both onto one cell.  So both turn one dancer, and hands go over one crown.
    ##   Red with orbit asked over walker's crown, measured 2026-10-02: every orbit's still
    ##     stood its other manner's pose, follow's orbit as follow's own turn.
    for single_index in 0..<SINGLES.len:
      for manner in Manner:
        for mate in Manner:
          for quarter in 0..<QUARTERS_ROUND:
            for other in 0..<QUARTERS_ROUND:
              if placeComparable(quarterPose(manner, quarter)) !=
                  placeComparable(quarterPose(mate, other)):
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
    ##   against connection, and hands go over their crown (`asks.turner`).
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
      check apart(stood.axis, drawn.axis) < ARRANGED
      check apart(stood.facing, drawn.facing) < ARRANGED
    check moves == SINGLES.len * 4 * QUARTERS_ROUND



suite "Internal: Each hold rests at named facing":
  test "each chain rests where its connections run parallel, and alternates from there":
    ## Hand to hand runs parallel Face-to-face, and crossed pair Face-to-back (rule 31).
    ##   Chain steps by half turns, so facing is rest at whole turns and other
    ##     of two at halves.
    for (holds, rest, other) in [(HAND_TO_HAND, Facing.FaceToFace, Facing.FaceToBack),
                                 (PAIRED, Facing.FaceToBack, Facing.FaceToFace)]:
      check facingRest(holds) == rest
      for wind in STEPS:
        let is_whole = abs(wind - round(wind)) < 1e-9
        check facingAt(holds, wind) == some(if is_whole: rest else: other)


  test "simulation is told each card's rest where it stands couple":
    ## Card names its rest from model (`parts.facingRest`), and simulation is told only
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



suite "Internal: Simulation against Reference":
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
    ##   A16 and A17 draw C05 and C03, so they name what those name.  Red with A17 asked to
    ##     cross nothing, measured 2026-10-04: it stood 0.44 m apart, where C03 crosses at 0.36.
    var named: seq[(string, Arm)]
    for i, target in FRAMES:
      if target.over.isSome:
        let key = &"A{i * 2 + 1:02}"
        if ask_by_key[key].turns != 0.0:
          named.add (key, (if target.over.get == Side.Left: Arm.Left else: Arm.Right))
    for (tag, arms) in [("C", HAND_TO_HAND), ("D", PAIRED)]:
      for i, wind in STEPS:
        if wind != 0.0: named.add (&"{tag}{i + 1:02}", overArm(wind).toArm)
    let chains = named
    for (frame, chain) in [("A16", "C05"), ("A17", "C03")]:
      for (key, arm) in chains:
        if key == chain: named.add (frame, arm)
    check named.len == 16
    for (key, arm) in named:
      let
        ask = ask_by_key[key]
        found = crossings(toArms(recorded[key], ask.links))
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
    ##   mirror twin unreflected (`walk.twinAnswering`), and page shows that still mirrored.  Where
    ##   no card asks it, twin card keeps that answer itself and names itself.
    ##   Mirror is its own undoing, figure for figure, on every still that holds.
    let kept = parseFile(KEPT_RIG)
    var marks, dofs: seq[string]
    for name in kept["marks"]: marks.add name.getStr
    for name in kept["dofs"]: dofs.add name.getStr
    func isAnswerTo(other, ask: StillAsk; links: seq[Link]; turns: float): bool =
      ## Whether `other` asks question that answers twin `ask`, unreflected.
      not twinAnswering(other.links, other.turns, other.isRestAway).is_reflected and
          other.links == links and other.turns == turns and
          other.isRestAway == ask.isRestAway and other.head == ask.head and
          other.is_either_way == ask.is_either_way and other.who == ask.who and
          other.over == mirrored(ask.over)
    var twins, keeping = 0
    for still in kept["stills"]:
      let
        ask = ask_by_key[still["key"].getStr]
        twin = twinAnswering(ask.links, ask.turns, ask.isRestAway)
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


  test "every sweep and still names hand that gave, and none where nothing gave":
    ## Recording names hand each stop gave at, dancer and arm by ordinal, and `null` where
    ##   nothing gave: way that ran free, way no plan carries further, and still, which stands
    ##   where nothing gives (`seen.Shown`).  Twin card keeping no still of its own names no stop.
    ##   Domain: rig's sweeps and stills, and each way report reads (`readings.WayRead`).  Rig's
    ##     sweeps are planned and its stills stand, so no rig entry names hand; report's walks
    ##     stop, and name one.
    ##   Red with hand kept as plain value, measured 2026-10-24: 4 sweeps and 57 stills that
    ##     nothing stopped named lead's left hand.
    let kept = parseFile(KEPT_RIG)
    var (named, unnamed) = (0, 0)
    for entry in kept["sweeps"].getElems & kept["stills"].getElems:
      if not entry.hasKey("why"): continue
      let (hold, why, whose) = (entry["hold"].getStr, entry["why"].getStr, entry["whose"])
      checkpoint &"`{hold}` stopped by `{why}` names hand `{whose}`"
      if why == $Stop.None:
        check whose.kind == JNull
        inc unnamed
        continue
      inc named
      check whose.kind == JArray and whose.len == 2
      if whose.kind == JArray and whose.len == 2:
        check whose[0].getInt in 0..ord(Body.high)
        check whose[1].getInt in 0..ord(Arm.high)
    for key, sweep in parseFile(KEPT_READINGS).jsonTo(Readings).sweeps:
      for (way, reading) in [("negative", sweep.negative), ("positive", sweep.positive)]:
        checkpoint &"`{key}` {way} stopped by `{reading.why}` names hand `{reading.whose}`"
        if reading.why == Stop.None:
          check reading.whose.isNone
          inc unnamed
        else:
          check reading.whose.isSome
          inc named
    checkpoint &"`{named}` name a hand, `{unnamed}` name none"
    check named > 0
    check unnamed > 0


  test "each arm's girdle stands on its own side of its chest, in every still page shows":
    ## Page colours each arm by side it is named for (`rig_view.inkArm`), so arm named left
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
          (at_x, at_y) = (look[4*who].getFloat, look[4*who+1].getFloat)
          (fore_x, fore_y) = (look[4*who+2].getFloat, look[4*who+3].getFloat)
          middle_x = (row[6*i].getFloat + row[6*i+3].getFloat) / 2.0
          middle_y = (row[6*i+1].getFloat + row[6*i+4].getFloat) / 2.0
          rightward = (middle_x - at_x) * fore_y - (middle_y - at_y) * fore_x
        checkpoint &"`{key}` girdle of `{who}` `{side}` stands `{rightward:.3f}` rightward"
        check (rightward > 0.0) == (side == ord(Arm.Right))
        inc girdles
    check girdles == 4 * stills


  test "each still page shows lists its torso's left capsule first":
    ## Torso is two capsules side by side, left first (`rigid.trunkCapsules`), so laws read
    ##   chest's right off them.  Twin card's still is mirrored (`design/twins`).
    ##   Red with mirror that left torso's capsules in place, read 2026-10-04: every twin card
    ##     listed right one first, so face law put face behind head.
    var (stills, torsos) = (0, 0)
    for key, still in recorded:
      if not still.hasKey("at") or still["at"].len == 0: continue
      inc stills
      let (tags, row, look) = (still["tag"], still["points"][0], still["faces"][0])
      for who in 0..1:
        var trunk: seq[int]
        for i in 0..<tags.len:
          if tags[i][0].getInt == who and tags[i][2].getInt == ord(Mark.Trunk): trunk.add i
        let
          (left, right) = (capsuleAt(row, trunk[0]), capsuleAt(row, trunk[1]))
          (fore_x, fore_y) = (look[4*who+2].getFloat, look[4*who+3].getFloat)
          across = (right.a + right.z - left.a - left.z) * 0.5
          rightward = across.x * fore_y - across.y * fore_x
        checkpoint &"`{key}` torso of `{who}` lists left capsule `{rightward:.3f}` left of right"
        check rightward > 0.0
        inc torsos
    check torsos == 2 * stills


  test "face's sphere covers face alone, reaching nose and no wider than face":
    ## Architect, 2026-10-04: smaller face first, sphere covering face alone, so arm may pass
    ##   close to brow and cheek.  Red with sphere of head's own radius 5 cm ahead, which
    ##     reached 14 cm ahead of head's axis and 9 cm to either side.
    let
      face = faceCapsule(HUMAN)
      (head_low, head_high, _) = trunkCapsules(HUMAN)[^1]
      ahead = face.a.y - ((head_low + head_high) * 0.5).y
    checkpoint &"face reaches `{ahead + face.radius:.3f}` m ahead, `{face.radius:.3f}` m to side"
    check abs(ahead + face.radius - NOSE) <= FACE_SLOP
    check face.radius <= FACE_HALF


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
        let gap = gapFace(recording, frame)
        inc moments
        deepest = min(deepest, gap)
        if gap < -FACE_SLOP: inside.add &"{name}@{moment}"
    checkpoint &"`{inside.len}` of `{moments}` moments hold arm inside face, deepest at " &
        &"`{deepest}` m: " & inside[0..<min(inside.len, 12)].join(" ")
    check moments >= stillAsks().len
    check inside.len == 0


  test "joined hands stay over crown in every moment walk holds past face to face":
    ## Architect, issue 611, 2026-10-11: once couple are not face to face, hands stay above heads
    ##   in every moment of sweep, and not in stills alone (`test_rigid.nim`, still laws).  Read as
    ##   those read it: each joined hand carried no lower than crown band less `SAG`, once couple
    ##   are `RAISE` of turn or more from face to face, where `rigid.up` is whole.  Hips' wind says
    ##   so, as judge reads it, and chest, which waist turns off hips, does not.
    ##   Carried point is read (`limb.pointCarried`), and not join: ruling quotes band, 1.735 to
    ##     2.00 m, and join may sit under it while carried point is inside, as in stills.
    ##   Domain: every moment of rig's four sweeps over crown, way each turns positive
    ##     (`seen.shown`), at least `FLOOR_AWAY_RIG` of them.  Each is planned, and keeps no
    ##     moment that gave (`seen.shownAsked`, `heldMoments`).
    ##     Cost: rig sweeps way that turns positive alone, so no law reads hands of way that
    ##       turns negative, where lowest hand found sank.
    ##     Law reads hands of moments sweep holds, and not how far it turns: law below holds
    ##       that each way turns as far as plan carries it with hands lifted.
    ##   Architect, pull request 629, 2026-10-12, D2: joined hands must be above from quarter
    ##     turn away from face to face, as walk's judge reads it (`rigid.up` whole), and this law
    ##     keeps that reading.  Still holds band coming back from eighth too (`rigid.height`).
    ##   Rig rounds its figures, so hand may read under engine's own by its rounding
    ##     (`roundedUnder`): hand gripped palm deep, nearest its wrist, turns most.
    ##   Regression of issue 611, as found on 2026-10-11, each card kept and its quoted hand read
    ##     wherever its moment is still recorded:
    ##     L-r above at +1.42: follow's right hand at 1.405 m.  Rig sweeps same hold, read next.
    ##     `One hand, cross name · above` at +1.42: follow's right hand at 1.406 m.
    ##     `Chain, cross name · above` at +0.60: follow's left hand at 1.696 m.
    ##     L-l above at -0.40, follow's left hand at 1.363 m, R-r above at +0.40 its mirror, and
    ##       L-l.R-r above at -1.86, lead's right hand at 1.667 m: each lies on way rig does not
    ##       sweep, so law reads none of them.
    ##   Red before its fix, read 2026-10-12 on recording of wall with slope at 270 alone: 64 of
    ##     rig's 212 moments.
    let
      rig = parseFile(KEPT_RIG)
      floor_crown = HUMAN.band[Band.Crown].lower - SAG
      under_rig = roundedUnder(PLACE_RIG, gripAtPalm(HUMAN), HUMAN.carry - handThick(HUMAN) / 2.0)
      quoted = [
        (card: "One hand, cross name · above", at: 1.42, who: Body.Two, arm: Arm.Right),
        (card: "Chain, cross name · above", at: 0.60, who: Body.Two, arm: Arm.Left),
      ]
    var
      cards: HashSet[string]
      got_rig: tuple[hands: seq[Lifted], moments: int]
    for sweep in rig["sweeps"]:
      if sweep["band"].getStr != "above": continue
      cards.incl sweep["hold"].getStr & " · above"
      if not sweep.hasKey("at"): continue
      let got = liftedRig(sweep)
      got_rig.hands.add got.hands
      got_rig.moments += got.moments
    var
      under: seq[Lifted]
      moments_under: HashSet[(string, float)]
      by_card: CountTable[string]
    for hand in got_rig.hands:
      if hand.z >= floor_crown - under_rig: continue
      under.add hand
      if (hand.card, hand.at) notin moments_under: by_card.inc hand.card
      moments_under.incl (hand.card, hand.at)
    under.sort(proc (a, b: Lifted): int = cmp(a.z, b.z))
    by_card.sort
    var shown: seq[string]
    for card, count in by_card: shown.add &"{card} {count}"
    var worst: seq[string]
    for hand in under[0..<min(under.len, 12)]: worst.add hand.named
    checkpoint &"Moments past face to face read: `{got_rig.moments}` of rig's sweeps over crown; " &
        &"hands read under `{floor_crown:.3f}` m less `{under_rig * 1000.0:.2f}` mm of rounding."
    check got_rig.moments >= FLOOR_AWAY_RIG
    checkpoint &"`{moments_under.len}` of `{got_rig.moments}` moments hold joined hand under " &
        "crown band.\n    By card: " & shown.join(", ") & ".\n" &
        "    Lowest:\n      " & worst.join("\n      ")
    for (card, at, who, arm) in quoted:
      var (in_range, found) = (0, 0)
      for hand in got_rig.hands:
        if hand.card != card or abs(hand.at - at) > 1e-9: continue
        inc in_range
        if hand.who == who and hand.arm == arm: inc found
      checkpoint &"Quoted: `{card}`, {who} {arm} at {at:+.2f}: `{found}` of `{in_range}` " &
          "joined hands read there."
      check card in cards
      if in_range > 0: check found > 0
    check moments_under.len == 0


  test "every way rig sweeps turns as far as plan carries it":
    ## Architect, pull request 629, 2026-10-12, D1: where walk alone lets joined hands sink, plan
    ##   lifts them.  Issue 375, 2026-10-04, D5: recording keeps planned turn of each sweep, as
    ##   each still is planned.  Plan keeps joined hands inside band and every upper arm inside
    ##   shoulder's edge (`plan.bandAt`, `plan.marginsArm`), so turn it carries is floor of each
    ##   way (`TURNS_PLANNED`).
    ##   Way holds as far as its furthest moment, in turns from rest (`heldMoments`): planned way
    ##     keeps no moment that gave.
    ##   Domain: way of each of rig's eight sweeps that turns positive (`seen.shown`): four held
    ##     above, two held high and two held low.  Every hold read names its floor, and none is
    ##     left unread.
    ##     Cost: way that turns negative is held to no floor, since rig keeps none.
    ##   That plan's moments keep hands in band and arms inside edge is held where each moment
    ##     is read: joined hands over crown (law above), joined hands held low or high (law
    ##     below), and shoulder's edge (`test_shoulder.nim`).
    ##   Rig rounds turn of each moment, so way may read under its floor by half that.
    ##   Regression of pull request 629, as found on 2026-10-12 in recordings of `bc656d30`:
    ##     cross-name chain held above stops at 1.26 of turn either way, where follow's joined
    ##     hand leaves its band; same-name chain held above stops at +1.80, by lead's wrist, and
    ##     at -1.66, by arm through arm.  Rig there holds `Chain, cross name · above` to 1.24 and
    ##     `Chain, same name · above` to +1.78, and keeps no way that turns negative.
    let
      by_rig = turnsHeldRig(parseFile(KEPT_RIG))
      ways_rig = SHOWN.len
    var short, unfloored: seq[string]
    for (card, held) in by_rig:
      let floor = floorPlanned(card)
      if floor.isNone:
        unfloored.add card
        continue
      checkpoint &"`{card}`: holds to `{held:.4f}` of turn, plan carries `{floor.get:.4f}`."
      if held + PLACE_RIG / 2.0 < floor.get: short.add &"{card} {held:.4f}"
    checkpoint &"Ways read: `{by_rig.len}` of rig's sweeps.  Short of plan: " &
        &"`{short.join(\", \")}`.  With no floor: `{unfloored.join(\", \")}`."
    check by_rig.len == ways_rig
    check unfloored.len == 0
    check short.len == 0


  test "every rig sweep turns from rest one step at most between two moments":
    ## Each way keeps every moment from rest to where it ends, each one step on from last, walked
    ##   (`walk.STEP`) or planned (`plan.STRIDE`), or none where plan poses arms again at one turn.
    ##   Moment left out of way leaves step of two.
    ##   Law above reads how far each way turns, and laws of hands and edge read moments each way
    ##     keeps, so none of them sees way that leaves out moments it could not hold.
    ##   Domain: every moment of each rig sweep, way that turns positive, from its first moment,
    ##     which is rest (`seen.shown`).
    ##     Sweep that holds no rest keeps no moment; half of sweeps is floor read.
    ##   Rig rounds turn of each moment, so step may read long or back by that.
    ##   Gap found 2026-10-12 in review of `cd9ec9a8`: with moments 0.80 to 1.20 of turn taken out
    ##     of `Chain, cross name · above`, and of L-r.R-l above in `cd9ec9a8:design/turns.json`,
    ##     every law passed.  Rig keeps first alone.
    let
      step_most = max(STEP, STRIDE)
      sweeps_least = SHOWN.len div 2
    var
      gaps: seq[string]
      read = 0
    for sweep in parseFile(KEPT_RIG)["sweeps"]:
      if not sweep.hasKey("at"): continue
      let
        card = sweep["hold"].getStr & " · " & sweep["band"].getStr
        turns = sweep["at"].getElems.mapIt(it.getFloat)
      if turns.len == 0: continue
      inc read
      if abs(turns[0]) > PLACE_RIG / 2.0: gaps.add &"{card} rests at {abs(turns[0]):.4f}"
      for m in 1..<turns.len:
        let step = turns[m] - turns[m-1]
        if step < -PLACE_RIG or step > step_most + PLACE_RIG:
          gaps.add &"{card} {turns[m-1]:+.4f} to {turns[m]:+.4f}"
    checkpoint &"Rig sweeps read: `{read}`.  Gaps: `{gaps.join(\", \")}`."
    check read >= sweeps_least
    check gaps.len == 0


  test "every rig sweep moves no joint of joined hand's arm, nor its join, past leap":
    ## Architect, issue 375, 2026-10-08: eight sweeps of rig viewer look comfortable frame by
    ##   frame.  D5 there, 2026-10-04: each sweep is planned moment by moment, as still is.
    ##   Leap is bound each walk is held to (`LEAP_RIG`).  Read: shoulder, elbow and wrist of each
    ##     joined hand's arm, and each join (`leapsRig`), and not breadth of hand (issue 605).
    ##   Domain: every moment each rig sweep holds (`heldMoments`), way that turns positive.
    ##   Rig rounds every figure, so leap may read long by twice that.
    ##   Red with six sweeps carried, read 2026-10-25 on recording of `b1ff5d83`: 19 moments of
    ##     4 sweeps, 478 mm at most, `Chain, same name · high` at +0.02.
    var
      over: seq[string]
      (moments, worst) = (0, 0.0)
    for sweep in parseFile(KEPT_RIG)["sweeps"]:
      if not sweep.hasKey("at"): continue
      let card = sweep["hold"].getStr & " · " & sweep["band"].getStr
      for (at, leap) in leapsRig(sweep):
        inc moments
        worst = max(worst, leap)
        if leap > LEAP_RIG + 2.0 * PLACE_RIG:
          over.add &"{card} {at:+.2f}: {int(round(leap * 1000.0))} mm"
    checkpoint &"`{over.len}` of `{moments}` moments leap past " &
        &"`{int(round(LEAP_RIG * 1000.0))}` mm, worst `{int(round(worst * 1000.0))}` mm: " &
        over[0..<min(over.len, 12)].join(", ")
    check moments > 0
    check over.len == 0


  test "every rig sweep crosses dancer's own arms below elbow alone, in every moment":
    ## D5 on issue 375, 2026-10-04: every still and plan keeps elbow rule, and each sweep keeps it
    ##   once planned as still is.  Read as still law below reads it (`isCrossed`).
    ##   Domain: every moment each rig sweep holds (`heldMoments`), way that turns positive.
    ##   Red with six sweeps carried, read 2026-10-25 on recording of `b1ff5d83`: 4 moments of
    ##     `Chain, cross name · high`, +0.88 to +0.94.
    var
      crossed: seq[string]
      moments = 0
    for sweep in parseFile(KEPT_RIG)["sweeps"]:
      if not sweep.hasKey("at"): continue
      let card = sweep["hold"].getStr & " · " & sweep["band"].getStr
      for m in 0..<heldMoments(sweep):
        inc moments
        if isCrossed(sweep, sweep["points"][m]):
          crossed.add &"{card} {sweep[\"at\"][m].getFloat:+.2f}"
    checkpoint &"`{crossed.len}` of `{moments}` moments cross above elbow: " &
        crossed[0..<min(crossed.len, 12)].join(", ")
    check moments > 0
    check crossed.len == 0


  test "every rig sweep held low or high keeps joined hands in its band, in every moment":
    ## Plan holds each joined hand's carried point in band of hold (`plan.bandAt`), as judge reads
    ##   that point (`rigid.pointCarried`): under band by `SAG` stops hold (`rigid.handUnder`), and
    ##   plan lets hand over band by `OVER`, as facing over crown.
    ##   Domain: every moment each rig sweep held low or high holds (`heldMoments`), every joined
    ##     hand (`heldRig`), way that turns positive.
    ##   Rig rounds its figures, so hand may read off band by its rounding (`roundedUnder`).
    ##   Red with those sweeps carried, read 2026-10-25 on recording of `b1ff5d83`: 151 joined
    ##     hands off band, in each of four sweeps, carried from 0.878 to 1.597 m.
    let rounding = roundedUnder(PLACE_RIG, gripAtPalm(HUMAN), HUMAN.carry - handThick(HUMAN) / 2.0)
    var
      off: seq[string]
      (moments, sweeps) = (0, 0)
    for sweep in parseFile(KEPT_RIG)["sweeps"]:
      let named = sweep["band"].getStr
      if named == BANDS[ord(Band.Crown)] or not sweep.hasKey("at"): continue
      inc sweeps
      let
        card = sweep["hold"].getStr & " · " & named
        band = HUMAN.band[(if named == BANDS[ord(Band.Torso)]: Band.Torso else: Band.Neck)]
        held = heldRig(sweep)
      for m in 0..<heldMoments(sweep):
        inc moments
        for hand in held:
          let z = carriedRig(sweep, m, hand).z
          if z < band.lower - SAG - rounding or z > band.upper + OVER + rounding:
            off.add &"{card} {hand.body} {hand.arm} {sweep[\"at\"][m].getFloat:+.2f}: {z:.3f} m"
    checkpoint &"`{off.len}` joined hands off band in `{moments}` moments of `{sweeps}` sweeps: " &
        off[0..<min(off.len, 12)].join(", ")
    check sweeps == SHOWN.countIt(it.band != Band.Crown)
    check moments > 0
    check off.len == 0


  test "every still crosses arms below elbow alone, in every moment":
    ## Each dancer's own arms cross at hands or forearms, and never above elbow (Architect,
    ##   2026-10-04), as judge reads it (`rigid.crossed`).  Each still is read as page shows it.
    ##   Red with no rule, read 2026-10-04: at D02 and D06 follow's elbows swap, and follow's
    ##     upper arms lie on each other 9 cm before elbow.
    var
      crossed: seq[string]
      moments = 0
    for key, still in recorded:
      for frame in still["points"].getElems:
        inc moments
        if isCrossed(still, frame): crossed.add key
    checkpoint &"`{crossed.len}` of `{moments}` moments cross above elbow: " & crossed.join(" ")
    check moments > 0
    check crossed.len == 0


  test "simulation models every card Reference draws, but cards shoulder's edge refuses":
    ## Every position and movement Reference draws is one dancers take with ease, so card
    ##   simulation cannot reach is fault of simulation, never of card.
    ##   Red with arms carried by pulls on hands alone: 33 of 231 cards unmodelled, all four
    ##     swans and every whole chain among them, measured 2026-10-02.
    ##   Card shoulder's edge stops is refused (Architect, issue 611, 2026-10-11, D1): law names
    ##     each with its reason (`CARDS_REFUSED`), and Reference shows it not modelled.  Each
    ##     stays unmodelled, so change that models one fails here and lifts its refusal.
    let answers = parseFile(KEPT_MODELLED)["answers"]
    var unmodelled, modelled_refused: seq[string]
    for key, answer in answers.pairs:
      let is_refused = CARDS_REFUSED.anyIt(it.key == key)
      if is_refused and answer.getBool: modelled_refused.add key
      elif not is_refused and not answer.getBool: unmodelled.add key
    checkpoint "unmodelled: " & unmodelled.join(" ")
    checkpoint "refused by shoulder's edge, yet modelled: " & modelled_refused.join(" ")
    check answers.len == questions().len
    for refused in CARDS_REFUSED:
      checkpoint &"`{refused.key}` refused: {refused.reason}"
      check answers.hasKey(refused.key)
    check unmodelled.len == 0
    check modelled_refused.len == 0



suite "Internal: Each recording is of tree it is kept in":
  ## Verb whose stamp is unchanged records nothing again (`design/stamps`), so recording kept
  ##   with other stamp is of other physics, other questions or other verb.  Page would show it
  ##   as this tree's answer.
  test "answers the Reference's badges carry the stamp the tree gives":
    check parseFile(KEPT_MODELLED)["stamp"].getStr == modelledStamp()


  test "recording the rig viewer plays carries the stamp the tree gives":
    check parseFile(KEPT_RIG)["stamp"].getStr == rigStamp()


  test "rig viewer folds in the recording without its stamp, each twin mirrored, nothing left out":
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



suite "Internal: Stills C cards show, as they stand":
  ## Architect left C01 to C07 standing, unconfirmed (issue 611): every law holds their moments as
  ##   it holds any other, and this watch reports where one moved, judging none.
  test "each still a C card shows stands within a millimetre of its fixture, as page shows it":
    ## Move past `MOVE_WATCHED` fails, naming card, capsule, end and move, and verb that writes
    ##   fixture again; that verb runs by hand, in pull request that moves still, and never to
    ##   quiet this.  Twin card is read as page shows it, still it names mirrored
    ##   (`design/twins`), so card that comes to show other still moves too.  Card whose still
    ##   holds no pose, or comes to hold one, is named as moved.
    let
      kept = parseFile(KEPT_RIG)
      fixture = parseFile(KEPT_WATCHED)
      marks = kept["marks"].getElems
    var shown: Table[string, JsonNode]
    for still in stillsShown(kept): shown[still["key"].getStr] = still
    var
      moved: seq[string]
      (ends, capsules_held) = (0, 0)
    for card in WATCHED:
      check card in shown
      check fixture.hasKey(card)
      if card notin shown or not fixture.hasKey(card): continue
      let held = fixture[card].getElems
      capsules_held += held.len
      if not shown[card].hasKey("points"):
        if held.len > 0: moved.add &"{card} holds no pose, where fixture holds {held.len} capsules"
        continue
      let
        tags = shown[card]["tag"].getElems
        points = shown[card]["points"][0].getElems
      if tags.len != held.len:
        moved.add &"{card} holds {tags.len} capsules, where fixture holds {held.len}"
        continue
      for i in 0..<tags.len:
        var tag: seq[int]
        for figure in tags[i]: tag.add figure.getInt
        let was = @[held[i][0].getInt, held[i][1].getInt, held[i][2].getInt]
        if tag != was:
          moved.add &"{card} capsule {i} is {tag}, where fixture holds {was}"
          continue
        for (side, offset) in [("a", 0), ("z", 3)]:
          let
            now: Vector = (points[6*i+offset].getFloat, points[6*i+offset+1].getFloat,
                           points[6*i+offset+2].getFloat)
            was: Vector = (held[i][3+offset].getFloat, held[i][4+offset].getFloat,
                           held[i][5+offset].getFloat)
            move = distance(now, was)
          inc ends
          if move > MOVE_WATCHED:
            let
              who = (if tag[0] == ord(Body.One): "lead" else: "follow")
              arm = (if tag[1] == ord(Arm.Left): "left" else: "right")
            moved.add &"{card} capsule {i}, {who} {arm} {marks[tag[2]].getStr}, end {side} " &
                &"moved {move * 1000.0:.1f} mm"
    checkpoint &"`{moved.len}` changes, `{ends}` of `{2 * capsules_held}` ends compared, past " &
        &"`{MOVE_WATCHED * 1000.0}` mm; where change is meant, write fixture again with " &
        "`nim r tools/build.nim watched` in pull request that makes it:\n    " &
        moved.join("\n    ")
    check moved.len == 0
    check ends == 2 * capsules_held
