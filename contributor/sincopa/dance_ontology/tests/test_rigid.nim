discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
"""
## Hold rig built on engine to what tape and clinical tables say, and to geometry.
##
##   Every law here failed on tree before it passed on this one.  First caught rig laid
##     flat on floor: trunk's turn was built from project's three axes in project's
##     order, where engine's basis puts body's forward on its negative z, and both
##     dancers lay down with shoulders at ankle height.
##   Second law is why engine's readings may be trusted at all: engine reports wrist's
##     cone, and same angle is worked out from three drawn points.  They agree, so
##     every other law may ask engine rather than measure pose again.
##     Law itself was wrong first time it ran, and rig was right: `angleBetween` takes
##     units, and raw vectors gave it constant eighty-nine degrees whatever pose was.
##   Where couple stand is read from `simulation/answers.json` (`simulation/answers.nim`), not
##     searched for here.  Suite took 545 s under testament, and its twenty laws that search for
##     nothing took 22.8 s, each run alone, measured 2026-09-24 on four cores; answers
##     change only when simulation does.  Every pose and walk law holds is still stood or walked
##     live, at answered distance and with current code.  Answers are held to tree by their
##     stamp, and by walking them again (suite "Internal: Answers").

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[atomics, cpuinfo, math, os, random, strformat, strutils, tables, typedthreads,
          unittest]

import ../simulation/[answers, body, hold, limb, read, rig, rigid, vector, walk]
import ./fixtures


const
  APART = 1.10  ## One distance laws below that do not care where couple stand use.
    ## Was where that hold left joints freest standing still, back when that was
    ## how standing was chosen.  It is now only place to build couple at.
  FLOOR_STOPS = 4
    ## Least stopped walks law on stops reads, so it reads some: 10 on 2026-10-04, five
    ##   ways each kept and walked live.  Margin, not 10: recording moves which ways stop.
  GIVE_REST = 0.01  ## Metres shoulder may sit off tape at rest, girdle being on spring:
                   ## measured 6.3 mm, pushed by its own arm resting against torso.
  SLACK = 3.0 * PI / 180.0  ## Engine's limits are solved, not clamped, so joint may
                           ## stand this far past its end for one step and come back.
  TWINS_SWEPT = 1  ## Pairs of `SWEEPS` that are each other's mirror twin: shake, and left
                   ## to right as far.


type
  Went = object  ## One walk walked live, reduced to numbers laws read of it.
    is_holding: bool  ## Whether hold stood at rest there.
    is_stopped: bool
    at: float  ## Turns reached when something gave.
    why: Stop
    moments: int
    deepest: float  ## Deepest any link sits in any body, metres; below nought is inside.
    leap: float  ## Furthest any point of held arm moves between two moments.
    leap_at: float  ## Turn where it does.
    peak: float  ## Furthest first connection's arms extend, radians.
    at_end: int  ## Arm-moments of first connection at their swing's end.

  Go = tuple[is_sweep: bool, index: int, is_positive: bool, apart: float]
    ## One walk to walk live: way of sweep of `SWEEPS`, or walk of `WALKS` from one
    ## distance, from `apart`.  Plain numbers, so threads share nothing but this list.

  Seen = tuple[name: string, band: Band, links: seq[Link], went: Went]

  Posed = tuple[key: string, is_holding: bool, strain: Strain, depth: float, pair: string,
                     apart, parted: float]
    ## One still of corpus stood live once, and every measure two laws read of it.


proc rest(band = Band.Torso, apart = APART): Couple =
  ## Build couple at rest at `band`, `apart` metres apart, and settle it.
  result = build(HUMAN, facing(HUMAN, apart), band, SHAKE)
  result.settle()

# Mutable: answers are read on first law that wants them, then kept for rest.
var
  ANSWERS_GIVEN: Answers  ## Answers as kept, read on first law that wants them.
  IS_GIVEN_READ = false

proc answered(): Answers =
  ## Every search's answer as kept (`simulation/answers.json`), read once.
  if not IS_GIVEN_READ:
    ANSWERS_GIVEN = kept()
    IS_GIVEN_READ = true
  ANSWERS_GIVEN


proc live(key: string, is_positive: bool): Went
  ## Sweep of `SWEEPS` walked live one way, from distance its kept answer chose.

proc standOf(question: StillAsked): tuple[is_holding: bool, couple: Couple, links: seq[Link]] =
  ## Couple stood live for still, at distance and way about kept answer gives, and hold
  ## stood.
  ##   Simulation answers mirror twin as other twin reflected (`walk.twinOf`), so twin's
  ##     answer is stood as other twin, which shows same holds, strain and heights.  Twin
  ##     stood raw there may not hold: right to left at half, either way, stood 0.36 apart
  ##     wound minus half, does not hold and strains 1.01, where left to right wound plus
  ##     half is at ease, measured 2026-10-04.
  let
    where = answered().stillOf(question.key)
    twin = twinOf(question.links, question.turns, question.is_away)
    turns = (if twin.is_reflected: -where.turns else: where.turns)
    (is_holding, couple) = stood(HUMAN, Band.Crown, twin.links, turns, question.is_away,
                                 Body.Two, where.apart)
  (is_holding, couple, twin.links)

func asked(key: string): StillAsked =
  ## Still of `STILLS` by its key.
  for question in STILLS:
    if question.key == key: return question
  raiseAssert "No still asked by that key; got `" & key & "`."

func carried(walk: Walk): float =
  ## How far this walk went, counting one that never stopped as further than any
  ## that did.
  if not walk.found_rest: -Inf elif walk.is_stopped: walk.at else: Inf

func carried(walk: Way | Walked | Went): float =
  ## How far kept walk went, counted as live one is.
  if not walk.is_holding: -Inf elif walk.is_stopped: walk.at else: Inf



suite "Internal: Two dancers in rigid body engine":
  test "each dancer stands where tape puts them":
    ## Within `GIVE_REST`: shoulder girdle is on spring, and at rest it sits 6.3 mm
    ## off tape, pushed by its own arm resting against torso.  Tape is where
    ## shoulder hangs unloaded; centimetres would be shoulder placed wrong.
    let
      couple = rest()
      pose = couple.poseOf(0)
    for k in 0..1:
      let hand = couple.links[0].ends[k]
      check distance(
        pose.arms[k].shoulder,
        shoulder(HUMAN, couple.chestStance(hand.body), hand.arm),
      ) < GIVE_REST
    check abs(pose.arms[0].shoulder.z - HUMAN.shoulder_up) < GIVE_REST
    couple.free()


  test "shoulders yaw on hips no further than thorax turns, and rest square":
    ## Chest is what shoulders hang from.  With hold pulling it yields, sprung,
    ## and never past clinical thoracic rotation; with nothing pulling it sits
    ## square on hips.
    var couple = rest()
    for who in Body:
      let yaw = couple.chestStance(who).facing - couple.stance[who].facing
      check abs(yaw) <= 40.0 * PI / 180.0 + SLACK
    couple.turn(Body.Two, 0.5, 600)
    for who in Body:
      let yaw = couple.chestStance(who).facing - couple.stance[who].facing
      check abs(yaw) <= 40.0 * PI / 180.0 + SLACK
    couple.free()
    var free = build(HUMAN, facing(HUMAN, APART), Band.Torso, @[])
    free.settle()
    for who in Body:
      check abs(free.chestStance(who).facing - free.stance[who].facing) < 1e-3
    free.free()


  test "engine's own reading of wrist is angle its three points make":
    for apart in [0.6, 0.9, 1.1]:
      let
        couple = rest(apart = apart)
        pose = couple.poseOf(0)
      for k in 0..1:
        let
          arm = pose.arms[k]
          drawn = angleBetween(unit(arm.wrist - arm.elbow), unit(arm.grip - arm.wrist))
        check abs(pose.wrist[k] - drawn) < 0.01
      couple.free()


  test "hands that are joined stay joined":
    for band in Band:
      let
        couple = rest(band)
        pose = couple.poseOf(0)
      check pose.apart < PARTED
      check couple.stopOf(0) == Stop.None
      couple.free()


  test "no joint goes past what rig allows it, at rest or through quarter":
    ## Checked while hold stands.  Turn is forced on by quarters at 1.10 m, and
    ## by half turn hands have parted by twenty centimetres: what wrist does
    ## then is no pose model reports, and it was carried nine degrees past its
    ## cone there once shoulder girdle could give.  Rest and first quarter, with
    ## wrists at twenty and twist at fifty, are what this holds.
    var checked = 0
    for band in Band:
      var couple = rest(band)
      for quarter in 0..3:
        let pose = couple.poseOf(0)
        if pose.apart < PARTED:
          inc checked
          for k in 0..1:
            let (lower, upper) = twistEnds(HUMAN, couple.links[0].ends[k].arm)
            check pose.twist[k] >= lower - SLACK
            check pose.twist[k] <= upper + SLACK
            check pose.bend[k] >= HUMAN.range[Dof.Bend].lower - SLACK
            check pose.bend[k] <= HUMAN.range[Dof.Bend].upper + SLACK
            check pose.wrist[k] <= HUMAN.range[Dof.Wrist].upper + SLACK
        couple.turn(Body.Two, 0.25, 600)
      couple.free()
    check checked >= 2 * 3


  test "couple are never offered place inside each other":
    ## Only thing fixed about where couple stand.  Architect: stand for turn, hand
    ## height for turn, everything for turn, nothing fixed but preventing
    ## collisions.  So this is whole of what constrains standing, and if it does
    ## not hold nothing does.
    var count = 0
    for apart in stands(HUMAN):
      check apart >= touching(HUMAN) + CLEAR
      count += 1
    check count > 1


  test "no distance couple could stand at carries turn further than one they chose":
    ## Standing was chosen at rest before this: wherever joints were freest standing
    ## still.  Couple walked straight out of it -- measured, chain over crown stood
    ## at 0.96 and turned 0.22 where standing at 0.36 turns 1.12 -- because room to
    ## move standing still is not what turning spends.
    ##   Law is argument maximum itself, so search broken any way at all fails here:
    ##   best started at infinity, sign of step dropped, range stopping short, rest
    ##   that never held counted as carrying.
    ##   To one step since 2026-09-18: stop is decided at moment something gives,
    ##   and search counts distances carrying within one step as carrying as far,
    ##   nearest keeping tie (`chosen`).  Exact, this law would fail from noise
    ##   fix was for: one build carries one step more from one distance than
    ##   another build does, and neither is wrong.
    ##   Both sides are kept answers: search's choice, and walk from every distance
    ##     (`simulation/answers.nim`), each answered by simulation at stamp suite
    ##     "Internal: Answers" holds.
    let sweep = answered().sweepOf("shake at torso")
    for (chose, every) in [(sweep.negative, "shake at torso, negative"),
                           (sweep.positive, "shake at torso, positive")]:
      check chose.is_holding
      let got = answered().walksOf(every)
      check got.len > 1
      for walk in got:
        check walk.carried <= chose.carried + STEP + 1e-9


  test "turn couple are said to reach is turn some distance carries":
    ## `reaches` answers at first distance that carries turn rather than at best of
    ## them, which is same answer for less work only so long as it looks at every
    ## distance before saying no.
    ##   `Inf` is how `carried` says walk never stopped, which is hold standing
    ##   at rest there and turn running whole way.
    var found_any = false
    for walk in answered().walksOf("shake at torso, asked"):
      if walk.carried == Inf: found_any = true
    check found_any
    check answered().isReaching("shake asked")
    check not answered().isReaching("chain beyond")


  test "every walk that stops names what stopped it":
    ## Walk is marked stopped only where `stoppedBy` names stop (`walk.walked`), so page
    ## and report can say what ends each turn they show.
    ##   Every way of every sweep is read as kept and as walked again live, which laws
    ##     below walk anyway, so this walks nothing of its own.
    ##   Still that holds at no distance and in no plan is marked stopped and names no stop
    ##     (`seen.still`), and rig page says no pose holds there (`design/rig.nim`).  No
    ##     law stands such still: every card reference draws is modelled
    ##     (`suites/test_asks.nim`).
    var stops = 0
    let given = answered()
    for question in SWEEPS:
      let sweep = given.sweepOf(question.key)
      for (is_positive, kept) in [(true, sweep.positive), (false, sweep.negative)]:
        if not kept.is_holding: continue
        let went = live(question.key, is_positive)
        for (is_stopped, why) in [(kept.is_stopped, kept.why), (went.is_stopped, went.why)]:
          if not is_stopped: continue
          check why != Stop.None
          stops += 1
    check stops >= FLOOR_STOPS


  test "at rest every joint is free to move either way":
    ## `freedom` is what `roomAt` reads with, and it counts both ends of range.
    ## On `margin`, which counts stop with no ease as costing nothing to lean on,
    ## straight elbow reads perfectly comfortable and every moment page draws
    ## reports room it does not have.
    let sweep = answered().sweepOf("shake at torso")
    for way in [sweep.negative, sweep.positive]:
      let couple = rest(Band.Torso, way.apart)
      check roomAt(couple, couple.poseOf(0), 0) > 0.0
      couple.free()


  test "no arm swings past what rig allows while hold still stands":
    ## Engine holds elbow, wrist and twist.  Extension and adduction across body
    ## it was never given -- rig states them as two ranges of their own and engine
    ## offers one cone -- so nothing holds them but this reading.  Asking only once
    ## hands had parted meant nothing held them at all: follow could turn two whole
    ## turns and more with their arm wrapped away behind them, and sweep called it
    ## free.
    ##   `GIVE` is what arm resting against its end may sink by, and is claim in its
    ##   own right: torque holding arm back has to be stiff enough that pressed arm
    ##   stays within it.  Slackening this figure to make suite pass would be
    ##   weakening test; it is here because model now says arm may lean on its end,
    ##   and it still fails outright if that lean is not held.
    let sweep = swept(HUMAN, Band.Torso, SHAKE, most = 1.5, apart = APART)
    check sweep.found_rest
    for walk in [sweep.positive, sweep.negative]:
      for moment in walk.moments:
        for k in 0..1:
          let
            hand = SHAKE[0].ends[k]
            joint_angles = joints(moment.stance[hand.body], hand.arm, moment.arms[0][k])
          check margin(HUMAN.range[Dof.Extend], joint_angles.extend) >= -GIVE
          check margin(HUMAN.range[Dof.Across], joint_angles.across) >= -GIVE


  test "every capsule page draws is one engine was given":
    ## Page is debug view, so its honesty rests on this: list it draws from is
    ## list handed to engine, recorded as it was handed over rather than worked
    ## out again afterwards.  Two trunks of four capsules, four shoulders of
    ## one, and four arms of three, is what `build` makes.
    let couple = rest()
    check couple.shapes.len == 2 * 4 + 4 + 4 * 3
    var trunks, girdles, limbs = 0
    for shape in couple.shapes:
      check shape.radius > 0.0
      case shape.mark
      of Mark.Trunk: trunks += 1
      of Mark.Girdle: girdles += 1
      else: limbs += 1
    check trunks == 8
    check girdles == 4
    check limbs == 12
    couple.free()


  test "arm's three capsules run end to end":
    ## Drawing that lets links drift apart draws arm nobody has.  Far end of one
    ## link and near end of next are same joint, so they meet within what solver
    ## lets joint separate.
    let couple = rest()
    for who in Body:
      for arm in Arm:
        var run: seq[tuple[a, z: Vector]]
        for shape in couple.shapes:
          if shape.mark in {Mark.Upper, Mark.Fore, Mark.Palm} and shape.who == who and
             shape.arm == arm:
            run.add couple.endsOf(shape)
        check run.len == 3
        for i in 0..<run.len - 1:
          check distance(run[i].z, run[i + 1].a) < 2.0 * HUMAN.limb + 0.01
    couple.free()


  test "capsules move where couple move":
    ## Guards drawing frozen at rest: ends are asked of engine each moment, so
    ## turning one dancer has to move their arms and leave other's trunk alone.
    var couple = rest()
    let before = couple.endsOf(couple.shapes[0])
    var arms_before: seq[tuple[a, z: Vector]]
    for shape in couple.shapes:
      if shape.mark != Mark.Trunk and shape.who == Body.Two: arms_before.add couple.endsOf(shape)
    couple.turn(Body.Two, 0.25, 600)
    var arms_after: seq[tuple[a, z: Vector]]
    for shape in couple.shapes:
      if shape.mark != Mark.Trunk and shape.who == Body.Two: arms_after.add couple.endsOf(shape)
    var moved = 0.0
    for i in 0..<arms_before.len:
      moved = max(moved, distance(arms_before[i].a, arms_after[i].a))
    check moved > 0.05
    ## Other dancer's trunk may yaw on hips as hold pulls, and nothing else:
    ## each capsule end keeps its distance from hip axis and its height.  That
    ## still catches drawing frozen, and catches trunk carried off or tilted,
    ## which "stays put" also caught and yaw does not break.  To tenth of
    ## millimetre, not micron: waist is soft constraint, and chest under hold
    ## measured ten microns off hip axis (9.7e-6 m, 2026-09-12).
    let
      hip = axesOf(couple.stance[Body.One]).origin
      after = couple.endsOf(couple.shapes[0]).a
      radius_was = sqrt((before.a.x - hip.x) ^ 2 + (before.a.y - hip.y) ^ 2)
      radius_now = sqrt((after.x - hip.x) ^ 2 + (after.y - hip.y) ^ 2)
    check abs(radius_was - radius_now) < 1e-4
    check abs(before.a.z - after.z) < 1e-4
    couple.free()


  test "rig is same seen in mirror":
    ## Lead's left to follow's left, reflected, is lead's right to follow's right,
    ## and turning one way reflects to turning other.  Anything applied per arm in
    ## body's mirrored terms has to say whether it is vector or pseudovector:
    ## torque is pseudovector, and mirroring it as vector turned left arm's own
    ## correction into shove further out.
    ##   Where couple stand each way is search's answer, kept; how far each walk
    ##     goes from there, and what stops it, is walked live (`live`).
    ##   Simulation answers R-r as L-l reflected (`walk.twinOf`), so R-r is asked raw:
    ##     its search and its walks are engine's own, as they were before twins.
    let
      left_to_left = answered().sweepOf("left to left at torso")
      right_to_right = answered().sweepOf("right to right at torso")
      left_to_left_positive = live("left to left at torso", true)
      left_to_left_negative = live("left to left at torso", false)
      right_to_right_positive = live("right to right at torso", true)
      right_to_right_negative = live("right to right at torso", false)
    ## Standing distance is chosen per way, so it is compared per way, as every
    ## other figure here is.  `Swept.apart` is whichever way went furthest, and
    ## when both run free they tie and it takes positive way for both -- which
    ## mirror does not equate, since positive way of one is negative way of
    ## other.  Comparing it passed only while ways did not tie.
    ## Within one step of search grid, not exact.  Chest is dynamic and its yaw
    ## mirrors to two ten-thousandths of degree at rest and six thousandths at
    ## 0.60 metres, but at 0.40 it sits four centimetres from contact and
    ## engine's iteration order, which differs between mirror-image holds,
    ## is amplified there to six tenths of degree.  Two distances that carry
    ## equally far then tie one way for one hold and other way for its mirror.
    ## Turn reached and what stopped it are still held exact below, which is
    ## what caught torque mirrored as vector.
    ## Way that stood nowhere reads as not stopped at no turn, which matches its mirror
    ## by nothing, so every way must stand.
    for went in [left_to_left_positive, left_to_left_negative, right_to_right_positive,
                 right_to_right_negative]:
      check went.is_holding
    check abs(left_to_left.positive.apart - right_to_right.negative.apart) < SEEK + 1e-9
    check abs(left_to_left.negative.apart - right_to_right.positive.apart) < SEEK + 1e-9
    check left_to_left_positive.is_stopped == right_to_right_negative.is_stopped
    check left_to_left_negative.is_stopped == right_to_right_positive.is_stopped
    ## Turn reached within one step, not exact, since bodies became solid:
    ## contact is where stop is decided now, and engine's contact is not mirror
    ## symmetric to step -- mirror-image holds stop one step apart from same
    ## distance, 0.02, measured 2026-09-13.  What stopped them is still exact.
    check abs(left_to_left_positive.at - right_to_right_negative.at) < STEP + 1e-9
    check abs(left_to_left_negative.at - right_to_right_positive.at) < STEP + 1e-9
    check left_to_left_positive.why == right_to_right_negative.why
    check left_to_left_negative.why == right_to_right_positive.why


  test "kept sweep of mirror twin is its other twin's, ways swapped":
    ## Simulation answers hold whose lead's right comes first as its mirror twin reflected
    ## (`walk.twinOf`): way that turns positive is twin's that turns negative, and
    ## distance, turn reached and what stopped it are twin's own, to last bit.
    ##   Pair is one engine does not mirror exactly: in `design/turns.json` of `9bbf656`,
    ##     shake walked raw reaches 1.36 turns one way, where left to right reaches 1.34
    ##     other way.  So law fails where twin is answered raw, as it was before twins.
    var pairs = 0
    let given = answered()
    for question in SWEEPS:
      let twin = twinOf(question.links, 1.0, false)
      if question.is_raw or not twin.is_reflected: continue
      for other in SWEEPS:
        if other.band != question.band or other.most != question.most or
           other.links.len != twin.links.len: continue
        var is_same = true
        for k in 0..<other.links.len:
          is_same = is_same and other.links[k].ends == twin.links[k].ends
        if not is_same: continue
        inc pairs
        let (asked, mirror) = (given.sweepOf(question.key), given.sweepOf(other.key))
        for (way, image) in [(asked.positive, mirror.negative), (asked.negative, mirror.positive)]:
          check way.is_holding == image.is_holding
          check way.apart == image.apart
          check way.is_stopped == image.is_stopped
          check way.at == image.at
          check way.why == image.why
    check pairs == TWINS_SWEPT


  test "over crown nothing stops single hold turning":
    ## Architect, who dances it: above is level that blocks by twist alone, and
    ## floor's own table says no block either way for either single hold there.
    ## Arms are clear of both bodies and swing is nowhere near its ends, so this
    ## is what rig should say without being told.
    ##   Red before crown's own rule was put back: joined hands over crown go over
    ##   turning dancer's head, not between two bodies.  Pulled to midpoint, both
    ##   dancers reach across themselves, spend their adduction, and hold blocks at
    ##   0.28 of turn.
    ##   Whole turn, not turn and half: with bodies solid, cross-name hold winds
    ##   follow's shoulder to its end at 1.20 to 1.30 turning one way from every
    ##   distance, which is twist alone and past every card.  Turn and half was
    ##   free only with arm through head.  Architect's to say whether that wind
    ##   is real.
    ##   And no held arm is carried to its swing's end on way there.  Architect,
    ##   watching viewer at 0.68 of cross-name turn: "no-one would let their arm
    ##   wrap behind their head like this".  Her arm sat at forty five degrees
    ##   behind frontal plane, swing's end, for six arm-moments of that sweep and
    ##   in its ease for fifty five, where going over top costs nothing: engine's
    ##   limits are walls and nothing preferred middle of range.
    for key in ["left to left over crown", "left to right over crown"]:
      let (positive, negative) = (live(key, true), live(key, false))
      check positive.is_holding or negative.is_holding
      check not positive.is_stopped
      check not negative.is_stopped
      let
        peak = max(positive.peak, negative.peak)
        at_end = positive.at_end + negative.at_end
      echo &"    {key}: extension peaks {peak * 180.0 / PI:.1f} degrees, " &
        &"{at_end} arm-moments at swing's end"
      check at_end == 0



#[ Sweep Stances ]#

suite "Internal: Couple stand for sweep":
  ## Where couple stand for sweep is chosen from every distance walked, by what
  ## each carried and how its arms moved.  Both are chaotic: two walks differing
  ## in last bit answer differently, and same source built by another compiler
  ## differs in last bits.  Choice has to stand still under that.
  const
    ## Same-name single hold at torso, walked 0.8 of turn: distances carrying
    ## most and their largest leaps, measured 2026-09-18.  L-l turning follow's
    ## positive way and R-r follow's negative are one hold seen in mirror.  Nearer
    ## distances carry 0.46 at most, and 0.52 on carries 0.66.
    left_to_left_positive: seq[Carry] = @[(0.44, 0.72, 0.125), (0.46, 0.72, 0.171),
                           (0.48, 0.72, 0.126), (0.50, 0.68, 0.121)]
    right_to_right_negative: seq[Carry] = @[(0.44, 0.72, 0.135), (0.46, 0.72, 0.174),
                           (0.48, 0.72, 0.106), (0.50, 0.72, 0.121)]
    ## Same walks from same source, built into another binary: leaps differ by
    ## up to thirty five per cent, and at 0.50 L-l carries 0.68 either way.
    left_to_left_positive_else: seq[Carry] = @[(0.44, 0.72, 0.114), (0.46, 0.72, 0.169),
                                (0.48, 0.72, 0.133), (0.50, 0.68, 0.163)]
    right_to_right_negative_else: seq[Carry] = @[(0.44, 0.72, 0.116), (0.46, 0.72, 0.155),
                                (0.48, 0.72, 0.124), (0.50, 0.68, 0.159)]
    ## Same hold at neck, walked whole sweep: L-l carries 1.00 from 0.42 and
    ## 0.98 from 0.38, and R-r 0.98 from both -- one step, which is how exactly
    ## stop is decided.
    left_to_left_high: seq[Carry] = @[(0.36, 0.22, 0.045), (0.38, 0.98, 0.093),
                            (0.40, 0.96, 0.100), (0.42, 1.00, 0.099),
                            (0.44, 0.82, 0.114), (0.46, 0.96, 0.104)]
    right_to_right_high: seq[Carry] = @[(0.36, 0.22, 0.046), (0.38, 0.98, 0.099),
                            (0.40, 0.96, 0.097), (0.42, 0.98, 0.100),
                            (0.44, 0.82, 0.109), (0.46, 0.98, 0.104)]
    ## Same hold over crown, running free from first distance: chest to chest
    ## joined hands are pinned between torsos and pop up, 189 mm in one moment,
    ## and from 0.42 on arms move under 90 mm.
    left_to_left_above: seq[Carry] = @[(0.36, Inf, 0.189), (0.38, Inf, 0.155),
                             (0.40, Inf, 0.131), (0.42, Inf, 0.086),
                             (0.44, Inf, 0.077), (0.46, Inf, 0.084)]

  func standAt(walks: openArray[Carry]): float = walks[chosen(walks)].apart
    ## Read distance kept walks chose.


  test "stance chosen is same seen in mirror and built by another compiler":
    ## Red: five millimetres broke tie between 0.44 and 0.48 for R-r, leaps 135
    ## and 106, and held it for L-l, 125 and 126: stances two steps apart for
    ## one hold in mirror, and `rig is same seen in mirror` failed on this tree
    ## and not on last, nothing about rig having changed.
    for (walks_a, walks_b) in [
      (left_to_left_positive, right_to_right_negative),
      (left_to_left_positive, left_to_left_positive_else),
      (right_to_right_negative, right_to_right_negative_else),
      (left_to_left_positive_else, right_to_right_negative_else),
      (left_to_left_high, right_to_right_high),
    ]:
      check abs(standAt(walks_a) - standAt(walks_b)) < SEEK + 1e-9


  test "stance steps out from hands pinned between torsos":
    ## Kept from before: nearest distance that carries turn is chest to chest.
    check standAt(left_to_left_above) >= 0.40
    check left_to_left_above[chosen(left_to_left_above)].leap * 2.0 <= left_to_left_above[0].leap



#[ Arm Motion ]#

const
  LEAP = 2.0 * PI * STEP * (HUMAN.shoulder_out + reach(HUMAN)) + 0.08
    ## Furthest any point of arm may move between two moments: point carried at
    ## arm's reach from turning axis goes 113 mm in one fiftieth of turn, and
    ## arm moving on its own at one metre per second while couple turn at
    ## quarter turn per second adds eight centimetres, both at once and along
    ## one line.  Measured before: 245 to 891 mm, hands pinned between torsos
    ## popping up between heads, arms sliding off head's dome, and elbow of
    ## weightless arm wandering about line from shoulder to wrist.  After: 83
    ## and 161 mm, second being wrist dragged in last moment before swing gives.

func between(a, b, c, d: Vector): float =
  ## Least distance between two segments, worked out here so law borrows
  ## nothing from what it checks.
  let
    first = b - a
    second = d - c
    offset = a - c
    first_squared = dot(first, first)
    first_dot_second = dot(first, second)
    second_squared = dot(second, second)
    first_dot_offset = dot(first, offset)
    second_dot_offset = dot(second, offset)
    denominator = first_squared * second_squared - first_dot_second * first_dot_second
  var
    s = 0.0
    t = 0.0
  if denominator > 1e-12:
    s = clamp(
      (first_dot_second * second_dot_offset - second_squared * first_dot_offset) / denominator,
      0.0,
      1.0,
    )
  t = (first_dot_second * s + second_dot_offset) / max(second_squared, 1e-12)
  if t < 0.0:
    t = 0.0
    s = clamp(-first_dot_offset / max(first_squared, 1e-12), 0.0, 1.0)
  elif t > 1.0:
    t = 1.0
    s = clamp((first_dot_second - first_dot_offset) / max(first_squared, 1e-12), 0.0, 1.0)
  distance(a + first * s, c + second * t)

func linkCapsules(rig: Rig, pose: ArmPose): seq[tuple[p, q: Vector, radius: float]] =
  ## Arm's three links as engine holds them: capsule set in from each joint by
  ## its radius, and hand too short for that as ball at its middle.
  for (joint_a, joint_b, long) in [
    (pose.shoulder, pose.elbow, rig.upper),
    (pose.elbow, pose.wrist, rig.fore),
    (pose.wrist, pose.grip, rig.hand),
  ]:
    let direction = unit(joint_b - joint_a)
    if long > 2.0 * rig.limb:
      result.add (joint_a + direction * rig.limb, joint_b - direction * rig.limb, rig.limb)
    else:
      result.add ((joint_a + joint_b) * 0.5, (joint_a + joint_b) * 0.5, long / 2.0)

func deepestOf(walk: Walk, links: seq[Link]): float =
  ## Deepest any link of any held arm sits in any body, over every moment.
  ##   Read against trunk capsules where engine has them, with distance worked
  ##     out here and not engine's manifolds.  Arm hangs from its own girdle and
  ##     overlaps it by construction, so that one pair is left out.
  # One loop for each axis of data: moment, link, end, capsule, dancer, trunk capsule.
  # Split would hide its shape.
  for moment in walk.moments:
    for i in 0..<links.len:
      for k in 0..1:
        let hand = links[i].ends[k]
        for (link_a, link_b, link_radius) in linkCapsules(HUMAN, moment.arms[i][k]):
          for who in Body:
            for (trunk_a, trunk_b, trunk_radius) in moment.trunks[who]:
              result = min(
                result,
                between(link_a, link_b, trunk_a, trunk_b) - link_radius - trunk_radius,
              )
            for arm in Arm:
              if who == hand.body and arm == hand.arm: continue
              let (girdle_a, girdle_b, girdle_radius) = moment.girdles[who][arm]
              result = min(
                result,
                between(link_a, link_b, girdle_a, girdle_b) - link_radius - girdle_radius,
              )

func leapIn(walk: Walk, links: seq[Link]): tuple[most, at: float] =
  ## Furthest any point of any held arm moves between two moments, and where.
  ##   Worked out here rather than borrowed from `walk.leapOf`, so law does not
  ##     check simulation against itself.
  # One loop for each axis of data: moment, link, end, joint.
  # Split would hide its shape.
  for j in 1..<walk.moments.len:
    for i in 0..<links.len:
      for k in 0..1:
        let
          before = walk.moments[j - 1].arms[i][k]
          after = walk.moments[j].arms[i][k]
        for (joint_before, joint_after) in [
          (before.shoulder, after.shoulder),
          (before.elbow, after.elbow),
          (before.wrist, after.wrist),
          (before.grip, after.grip),
        ]:
          if distance(joint_before, joint_after) > result.most:
            result = (distance(joint_before, joint_after), walk.moments[j].at)

const SWING_END = HUMAN.range[Dof.Extend].upper - 5.0 * PI / 180.0
  ## Extension within five degrees of swing's end.

func extensionOf(walk: Walk, links: seq[Link]): tuple[peak: float, at_end: int] =
  ## Furthest first connection's two arms extend, and arm-moments at swing's end.
  result.peak = -Inf
  for moment in walk.moments:
    for k in 0..1:
      let
        hand = links[0].ends[k]
        joint_angles = joints(moment.stance[hand.body], hand.arm, moment.arms[0][k])
      result.peak = max(result.peak, joint_angles.extend)
      if joint_angles.extend > SWING_END: inc result.at_end

func wentOf(walk: Walk, links: seq[Link]): Went =
  ## Walk reduced to numbers laws read.
  let
    (most, at) = leapIn(walk, links)
    (peak, at_end) = extensionOf(walk, links)
  Went(
    is_holding: walk.found_rest,
    is_stopped: walk.is_stopped,
    at: walk.at,
    why: walk.why,
    moments: walk.moments.len,
    deepest: deepestOf(walk, links),
    leap: most,
    leap_at: at,
    peak: peak,
    at_end: at_end,
  )



#[ Parallel Live Walks ]#

# Mutable and global: thread takes one argument, so workers write into slots allotted here.
var
  GOES: seq[Go]  ## Every walk, set before any thread starts.
  GO_NEXT: Atomic[int]  ## Next walk not yet taken.
  WENTS: seq[Went]  ## Each walk's numbers, at its own index.
  WALKS_DRAWN: seq[tuple[index: int, kept: Walked]]  ## Walks drawn to walk again.

proc going(id: int) {.thread.} =
  ## Take walks until none is left.
  ##   Holds are constants, so each worker reads its own copy; each walk builds
  ##     its own world; only numbers come back.  List of strings and sequences
  ##     read by four threads is what `design/record.nim` records dying of.
  {.cast(gcsafe).}:
    while true:
      let i = GO_NEXT.fetchAdd(1)
      if i >= GOES.len: return
      let task = GOES[i]
      if task.is_sweep:
        let
          question = SWEEPS[task.index]
          step = (if task.is_positive: STEP else: -STEP)
          walk = (if question.is_raw: walkedOf(HUMAN, question.band, question.links, Body.Two,
                                               task.apart, question.most, step, false, Body.Two)
                  else: walked(HUMAN, question.band, question.links, Body.Two, task.apart,
                               question.most, step, false, Body.Two))
        WENTS[i] = wentOf(walk, question.links)
      else:
        let
          question = WALKS[task.index]
          walk = walked(
            HUMAN,
            question.band,
            question.links,
            Body.Two,
            task.apart,
            question.most,
            question.step,
            false,
            Body.Two,
          )
        WENTS[i] = wentOf(walk, question.links)

proc walkEveryWay() =
  ## Walk, on every core at once, every way of every sweep from its kept distance,
  ## and two walks of `WALKS` drawn by stamp from their kept distances.
  ##   Laws read nine of those fourteen ways between them, and law of answers reads
  ##     all fourteen; twelve walked one after another cost 14.5 s of one law's time,
  ##     measured 2026-09-24.  Way whose search found no distance is not walked.
  if GOES.len > 0: return
  let given = answered()
  for i, question in SWEEPS:
    let sweep = given.sweepOf(question.key)
    for (is_positive, way) in [(true, sweep.positive), (false, sweep.negative)]:
      if way.is_holding: GOES.add (true, i, is_positive, way.apart)
  var every: seq[tuple[index: int, kept: Walked]]
  for i, question in WALKS:
    for walk in given.walksOf(question.key): every.add (i, walk)
  var draw = initRand(fromHex[int](given.stamp[0..<12]))
  for _ in 0..1:
    let got = every[draw.rand(every.high)]
    WALKS_DRAWN.add got
    GOES.add (false, got.index, true, got.kept.apart)
  WENTS = newSeq[Went](GOES.len)
  GO_NEXT.store(0)
  let cores = max(1, countProcessors())
  var workers = newSeq[Thread[int]](cores)
  for worker in 0..<cores: createThread(workers[worker], going, worker)
  joinThreads(workers)

proc live(key: string, is_positive: bool): Went =
  ## Walk is simulation's own, on this build: only where couple stand comes from
  ##   answers.  `walked` builds its own world, so it walks exactly what search
  ##   walked from that distance.  Raw question is walked on engine as it is
  ##   (`walkedOf`), as its search was.
  ##   Way whose search found no distance to stand at is not walked, and reads
  ##   as hold that did not stand.
  walkEveryWay()
  for i, question in SWEEPS:
    if question.key == key:
      for k, task in GOES:
        if task.is_sweep and task.index == i and task.is_positive == is_positive: return WENTS[k]
      return Went(is_holding: false)
  raiseAssert "No sweep asked by that key; got `" & key & "`."

proc replayed(): seq[tuple[question: WalkAsked, kept: Walked, went: Went]] =
  ## Two walks of `WALKS` drawn by stamp, as kept and as walked again live.
  walkEveryWay()
  for k, task in GOES:
    if not task.is_sweep:
      result.add (WALKS[task.index], WALKS_DRAWN[result.len].kept, WENTS[k])


proc corpus(): seq[Seen] =
  ## Two single holds walked one way from where couple choose to stand, which
  ## is what pages draw: crown is where arm goes over head, torso is where arms
  ## lie against bodies.
  ##   Walked live from kept answer (`live`), once, and read by two laws.
  @[("L-l above", Band.Crown, LEFT_TO_LEFT, live("left to left over crown", true)),
    ("L-r low", Band.Torso, LEFT_TO_RIGHT, live("left to right at torso", true))]



suite "Internal: Arms move as arms do":
  ## Architect, watching viewer: bodies too rigid, arms crushed and passing
  ## through them, sharp moves between frames.  Measured before these laws:
  ## forearm 45 mm inside its own trunk with nothing said, and hand crossing
  ## 359 mm between first two moments.
  test "no arm sits inside any body in any moment":
    ## Read against trunk capsules where engine has them, with distance worked
    ## out here and not engine's manifolds, so engine is not asked to mark its
    ## own work (Article II.9).  Not reader's `bodyGap` either: it draws parts
    ## as cylinders with flat ends, and over torso's dome reads arm 37 mm inside
    ## body at rest where engine has it clear.  Own body counts as other does:
    ## engine collides own arm with own trunk.  Deeper than `THROUGH` is what
    ## model itself calls arm through body and stops at, so no recorded moment
    ## may be deeper; engine once reported no touch with upper arm 67 mm inside
    ## own head, which is what this is for.
    for (name, band, links, went) in corpus():
      check went.is_holding
      check went.moments > 5
      echo &"    {name}: deepest any link sits in any body {-went.deepest * 1000:.1f} mm"
      check went.deepest > -THROUGH - 1e-9


  test "every shoulder hangs from its own body":
    ## Architect, on viewer at 1.68 of same-name crown turn: bodies "too rigid",
    ## arms "get dislocated because of it".  Measured, no joint parts
    ## by more than four millimetres; what reads as dislocation is that shoulder
    ## joint sits at 0.18 out and 1.40 up, where torso's stadium is 0.166 wide
    ## and its dome has dropped below 1.24, so arm hangs from point nine
    ## centimetres outside body with nothing between.  Rig had no shoulder girdle,
    ## in mass or in motion.  Shoulder joint must lie inside some capsule of its
    ## own body that is not arm.
    var couple = build(HUMAN, facing(HUMAN, APART), Band.Torso, @[])
    couple.settle()
    for who in Body:
      for arm in Arm:
        let shoulder_point = couple.armPoseOf(who, arm).shoulder
        var gap = Inf
        for shape in couple.shapes:
          if shape.who != who or shape.mark in {Mark.Upper, Mark.Fore, Mark.Palm}: continue
          let ends = couple.endsOf(shape)
          gap = min(gap, between(shoulder_point, shoulder_point, ends.a, ends.z) - shape.radius)
        echo &"    {who} {arm}: shoulder joint {gap * 1000:.0f} mm outside own body"
        check gap <= 0.0
    couple.free()


  test "still asked past face to face has its joined hands in their band":
    ## Architect: face to face arms may be at any height, and once couple are no
    ## longer face to face hands must actually be above.  Still card was built at
    ## its facing and settled, and lift starts only after settling: over crown at
    ## half turn every joined hand hung at hip height, 0.87 m, so every still past
    ## face to face on reference was answered with hands nowhere near its band.
    var found_pose = false
    for apart in stands(HUMAN):
      let (is_holding, couple) = stood(HUMAN, Band.Crown, WOUND, 0.5, false, Body.Two, apart)
      if is_holding:
        found_pose = true
        for link in WOUND:
          for hand in link.ends:
            check couple.armPoseOf(hand.body, hand.arm).grip.z >= HUMAN.band[Band.Crown].lower - SAG
      couple.free()
      if found_pose: break
    check found_pose


  test "still at diamond is wound where open is not":
    ## Winding is path, not facing.  Couple built at whole turn stand as they do
    ## at none: diamond read as open and swan as cross, and every wound still on
    ## reference was answered by unwound pose.  Turned there, diamond's two
    ## connections cross twice in plan where open's run clear.
    ##   Wound there whether or not pose holds, and from `diamond`: what is
    ##   claimed here is path, not hold.  From `APART` whole turn ends with arm
    ##   through body and one crossing, measured 2026-09-18 with hands asked
    ##   down to mid torso facing; from 0.70 it comes round with nothing given.
    const diamond = 0.70
    proc crossed(turns: float): int =
      ## How many times two connections cross, wound there from `diamond`.
      var couple = build(HUMAN, restStance(HUMAN, diamond), Band.Crown, WOUND, Body.Two)
      couple.settle()
      var at = 0.0
      while abs(at) + 1e-9 < abs(turns):
        couple.turn(Body.Two, STEP, BEATS)
        at += STEP
      var arms: Arms
      for i in 0..<WOUND.len:
        arms.add couple.poseOf(i).arms
      result = crossings(arms).len
      couple.free()
    check crossed(0.0) == 0
    check crossed(1.0) >= 2


  test "no point of any arm leaps between two moments":
    for (name, band, links, went) in corpus():
      echo &"    {name}: furthest any point moves between moments {went.leap * 1000:.0f} mm, " &
        &"at {went.leap_at:.2f}"
      check went.leap < LEAP



#[ Stills At Ease ]#

const
  SLOP = 0.005  ## Engine's own linear slop, metres: overlap it never resolves.
  AT_EASE = 0.1  ## Strain no dancer feels: two degrees of twenty into ease that is
                ## assumed to begin there, under what its own start is known to.
  DEGREE = PI / 180.0  ## One degree.
  JOINED = 0.005  ## Metres joined hands may sit apart and still be joined: slop.
  PART = 0.002  ## Metres any joint of any arm may be pulled apart: dislocation past this.

proc overlapOf(couple: Couple): tuple[depth: float, pair: string] =
  ## Deepest any two capsules engine collides sit in each other, by geometry
  ## worked out here and not engine's manifolds, and which two.
  ##   Pairs engine never collides are left out: capsules of one body, one arm's
  ##     own links, girdle and upper arm it hangs from, trunk and girdles of one
  ##     dancer, and two joined palms.

  proc isSkipped(shape_a, shape_b: Shape): bool =
    ## Decide whether pair of shapes may overlap: one body, or one arm's own links.
    if shape_a.body == shape_b.body: return true
    if shape_a.who == shape_b.who:
      let limbs = {Mark.Upper, Mark.Fore, Mark.Palm}
      if shape_a.mark notin limbs and shape_b.mark notin limbs: return true
      if shape_a.arm == shape_b.arm and shape_a.mark in limbs and shape_b.mark in limbs: return true
      if shape_a.arm == shape_b.arm and
         {shape_a.mark, shape_b.mark} == {Mark.Girdle, Mark.Upper}: return true
    if shape_a.mark == Mark.Palm and shape_b.mark == Mark.Palm:
      for link in couple.links:
        let (first_hand, second_hand) = (link.ends[0], link.ends[1])
        if (first_hand == (shape_a.who, shape_a.arm) and
            second_hand == (shape_b.who, shape_b.arm)) or
           (second_hand == (shape_a.who, shape_a.arm) and
            first_hand == (shape_b.who, shape_b.arm)): return true
    false

  result = (0.0, "")
  for i in 0..<couple.shapes.len:
    for k in i + 1..<couple.shapes.len:
      let (shape_a, shape_b) = (couple.shapes[i], couple.shapes[k])
      if isSkipped(shape_a, shape_b): continue
      let
        ends_a = couple.endsOf(shape_a)
        ends_b = couple.endsOf(shape_b)
        depth = shape_a.radius + shape_b.radius - between(ends_a.a, ends_a.z, ends_b.a, ends_b.z)
      if depth > result.depth:
        result = (
          depth,
          &"{shape_a.who} {shape_a.arm} {shape_a.mark} against " &
            &"{shape_b.who} {shape_b.arm} {shape_b.mark}",
        )


# Mutable: corpus is stood on first law that wants it, then kept for rest.
var STILLS_POSED: seq[Posed]  ## Corpus of stills, stood once.

proc poses(): seq[Posed] =
  ## Every still of corpus stood live at its kept answer, once: strain for one
  ## law; overlap, joined hands and parted joints for other.
  ##   Two laws stood same eight poses each, 6.2 s apiece, measured 2026-09-24.
  if STILLS_POSED.len == 0:
    for question in STILLS[0..<CORPUS]:
      let (is_holding, couple, _) = standOf(question)
      var still: Posed = (question.key, is_holding, Strain(), 0.0, "", 0.0, 0.0)
      if is_holding:
        still.strain = couple.strainOf
        (still.depth, still.pair) = couple.overlapOf
        for i in 0..<question.links.len: still.apart = max(still.apart, couple.poseOf(i).apart)
        for who in Body:
          for arm in Arm: still.parted = max(still.parted, max(couple.partedAt(who, arm)))
      couple.free()
      STILLS_POSED.add still
  STILLS_POSED



suite "Internal: Every still stands at ease":
  ## Architect: every state is easily doable in reality without any strain,
  ## effort or forcing; no clipping, no dislocations, no cheating.  Read where
  ## couple stand for each still: nothing at any end past `AT_EASE`, nothing
  ## through anything, nothing pulled apart, hands joined.
  test "still couple stand for has nothing at its end":
    ## Strain is nought outside every ease band, one at some end.  Every arm,
    ## held or free, both waists, every collarbone: free arm shoved to its end
    ## by partner's trunk is strain couple feel, as much as held one's.
    ##   Where to stand is kept answer; pose there is stood live (`poses`).
    for still in poses():
      let where = answered().stillOf(still.key)
      check where.is_holding
      check still.is_holding
      echo &"    {still.key}: stood {where.apart:.2f}, strain {still.strain.most:.2f} " &
        &"at {still.strain.what} {still.strain.whose.body} {still.strain.whose.arm}"
      check still.strain.most <= AT_EASE


  test "free couple at rest hang their arms by their sides":
    ## Architect: with nothing held, arms are down by sides and look joined to
    ## nothing.  Every arm hangs near plumb, out by what its own flank pushes it,
    ## elbow near straight, untwisted, and no arm comes within its own thickness
    ## of other dancer's arms.  Before this, hanging arms were twisted forty degrees and
    ## swung forward twenty by fixed elbow moment, forearms pointing at partner,
    ## and free couple at rest stood with arms crossed between them.
    let (is_holding, couple) = stood(HUMAN, Band.Crown, FREE, 0.0, false, Body.Two, 0.36)
    check is_holding
    var nearest = Inf
    for who in Body:
      for arm in Arm:
        let
          (swings, twist_angle, bend_angle, wrist_angle) = couple.jointsOf(who, arm)
          pose = couple.armPoseOf(who, arm)
          hang = pose.grip - pose.shoulder
        echo &"    {who} {arm}: extend {swings.extend * 180.0 / PI:.1f}, across " &
          &"{swings.across * 180.0 / PI:.1f}, twist {twist_angle * 180.0 / PI:.1f}, bend " &
          &"{bend_angle * 180.0 / PI:.1f}, wrist {wrist_angle * 180.0 / PI:.1f}, hand " &
          &"{sqrt(hang.x * hang.x + hang.y * hang.y) * 1000:.0f} mm off plumb"
        check abs(swings.extend) <= 10.0 * DEGREE
        check abs(twist_angle) <= 15.0 * DEGREE
        check bend_angle <= 20.0 * DEGREE
        check wrist_angle <= 10.0 * DEGREE
        check sqrt(hang.x * hang.x + hang.y * hang.y) <= 0.2
    for shape_a in couple.shapes:
      for shape_b in couple.shapes:
        if shape_a.who == shape_b.who or shape_a.mark notin {Mark.Upper, Mark.Fore, Mark.Palm} or
           shape_b.mark notin {Mark.Upper, Mark.Fore, Mark.Palm}: continue
        let (ends_a, ends_b) = (couple.endsOf(shape_a), couple.endsOf(shape_b))
        nearest = min(
          nearest,
          between(ends_a.a, ends_a.z, ends_b.a, ends_b.z) - shape_a.radius - shape_b.radius,
        )
    echo &"    nearest two arms of different dancers come: {nearest * 1000:.0f} mm"
    check nearest >= 2.0 * HUMAN.limb
    couple.free()


  test "free couple wound half a turn hang their arms by their sides":
    ## Same, wound to A2: follow's arms come along with turn and hang again once
    ## it stops.  Before this, shoulder's spring at one hertz held hanging arm
    ## with two newton metres per radian, and follow's arms lagged slow half
    ## turn by twenty five and forty nine degrees, then crept back through
    ## settle to eighteen and thirty three, hand 413 mm off plumb -- flank's
    ## friction against spring nothing like weight of arm.
    for turns in [-0.5, 0.5]:
      let (is_holding, couple) = stood(HUMAN, Band.Crown, FREE, turns, false, Body.Two, 0.48)
      check is_holding
      for who in Body:
        for arm in Arm:
          let
            swings = couple.jointsOf(who, arm).swings
            pose = couple.armPoseOf(who, arm)
            hang = pose.grip - pose.shoulder
          echo &"    wound {turns:+.1f} {who} {arm}: extend {swings.extend * 180.0 / PI:.1f}, " &
            &"hand {sqrt(hang.x * hang.x + hang.y * hang.y) * 1000:.0f} mm off plumb"
          check abs(swings.extend) <= 10.0 * DEGREE
          check sqrt(hang.x * hang.x + hang.y * hang.y) <= 0.2
      couple.free()


  test "no capsule of any arm sits in any other, hands joined, no joint parted":
    ## Read against every capsule engine collides, with distance worked out here
    ## and not engine's manifolds, so engine is not asked to mark its own work.
    ## Deeper than slop is one thing in another; hands further apart than slop
    ## are not joined; joint pulled further than `PART` is dislocation.
    for still in poses():
      check answered().stillOf(still.key).is_holding
      check still.is_holding
      if not still.is_holding: continue
      echo &"    {still.key}: deepest {still.depth * 1000:.1f} mm ({still.pair}), hands " &
        &"{still.apart * 1000:.1f} mm apart, joints parted {still.parted * 1000:.1f} mm"
      check still.depth <= SLOP
      check still.apart <= JOINED
      check still.parted <= PART


  test "hands are above whenever couple are not face to face, from rest on":
    ## Architect: face to face arms may be at any height; once couple are no
    ## longer face to face hands must actually be above.  Hold that rests
    ## pillion is not face to face, so its hands are above at its rest, as its
    ## card draws them.  Keyed to hold's own rest instead, every same-name still
    ## was wound from hold at hip.
    let question = asked("same-name at rest")
    check answered().stillOf(question.key).is_holding
    let (holds, couple, _) = standOf(question)
    check holds
    for link in answers.CHAIN:
      for hand in link.ends:
        check couple.armPoseOf(hand.body, hand.arm).grip.z >= HUMAN.band[Band.Crown].lower - SAG
    couple.free()


  test "hands are up only while couple are not face to face, whole turns and all":
    ## Architect, on A9, wound half turn from pillion rest to face to face with
    ## hands still over heads: modelled but unnatural.  Relaxed position facing
    ## is hands at mid torso; pillion or back to back they have to be above;
    ## facing, arms naturally come down.  Whole turns fold away: couple wound
    ## whole turn face each other again and their hands are down again, which
    ## `risen` keyed to wind from rest never let them be -- and swan may be
    ## reached only so, one connection straightening out as arms come down.
    ##   Nought face to face, one from `RAISE` of turn away, whole turns and
    ##   all.  Going up hands rise over follow's head as they always did; coming
    ##   back they come forward off that crown first and then down: let down
    ##   straight from over crown to mid torso, they passed through head.
    var couple = build(HUMAN, restStance(HUMAN, 0.44), Band.Crown, WOUND, Body.Two)
    for wind in [0.0, 0.1, 0.2, 0.3, 0.5, 0.7, 0.9, 1.0, 1.5]:
      couple.stance = turned(restStance(HUMAN, 0.44), Body.Two, wind)
      check couple.wound =~ wind
      let away = min(wind mod 1.0, 1.0 - wind mod 1.0)
      check couple.up =~ min(1.0, away / 0.25)
      if away > 1e-6 and away < 0.5 - 1e-6: check couple.isLeavingCrown == (wind < 0.5)
      check couple.height >= couple.up
      if couple.isLeavingCrown: check couple.over == 1.0
    couple.free()
    var turned_away = build(
      HUMAN,
      restStance(HUMAN, 0.44, is_away = true),
      Band.Crown,
      answers.CHAIN,
      Body.Two,
      is_away = true,
    )
    check turned_away.wound == 0.0
    check turned_away.up == 1.0
    check turned_away.height == 1.0
    turned_away.free()


  test "facing couple rest their joined hands at mid torso":
    ## Same ruling, on couple as they stand: cross-name chain at its face to
    ## face rest, and same-name chain wound half turn from pillion rest to face
    ## to face (A9), hold with every joined hand in torso band.  Before, A9
    ## stood at 0.60 m with every hand over crown.
    for name in ["cross-name at +0.0", "same-name at half"]:
      let
        question = asked(name)
        where = answered().stillOf(name)
      check where.is_holding
      let (holds, couple, links) = standOf(question)
      check holds
      for link in links:
        for hand in link.ends:
          let z = couple.armPoseOf(hand.body, hand.arm).grip.z
          echo &"    {name}: {hand.body} {hand.arm} hand at {z:.2f} m, stood {where.apart:.2f}"
          check z >= HUMAN.band[Band.Torso].lower - SAG
          check z <= HUMAN.band[Band.Torso].upper + SAG
      couple.free()


  test "still that fixes no way about is wound whichever way sits easier":
    ## Card whose picture is same turned either way claims position, not path:
    ## couple take whichever way there sits easier, and answer is never worse
    ## than way asked alone.
    ##   Both searches' answers are kept; each pose is stood live there.
    let
      (is_asked_holding, asked_at, _) = standOf(asked("right to left at half"))
      (is_free_holding, free_at, _) = standOf(asked("right to left at half, either way"))
      (asked_way, free_way) = (answered().stillOf("right to left at half"),
                             answered().stillOf("right to left at half, either way"))
      (asked_strain, free_strain) = (asked_at.strainOf, free_at.strainOf)
    echo &"    right to left at half: asked way stood {asked_way.apart:.2f} strain " &
      &"{asked_strain.most:.2f}; either way stood {free_way.apart:.2f} at " &
      &"{free_way.turns:+.1f} strain {free_strain.most:.2f}"
    check is_asked_holding
    check is_free_holding
    check free_strain.most <= asked_strain.most
    check free_strain.most <= AT_EASE
    asked_at.free()
    free_at.free()


  test "same still from same distance answers same twice":
    ## Check gives same verdict on same code.  Winding is chaotic enough that
    ## distances differing in their last bit answer differently, so what is
    ## held is exact repetition: same distance, same numbers.
    for i in 0..1:
      var got: array[2, float]
      for run in 0..1:
        let (is_holding, couple) = stood(HUMAN, Band.Crown, WOUND, 1.0, false, Body.Two, 0.44)
        got[run] = (if is_holding: couple.strainOf.most else: -1.0)
        couple.free()
      check got[0] == got[1]



#[ Answers ]#

suite "Internal: Answers":
  ## Laws above read where couple stand from `simulation/answers.json`, and search for
  ## nothing.  These hold that file to tree: every question laws ask is answered
  ## there, by simulation as it is now.
  test "answers carry stamp of simulation that gave them":
    ## Stamp is digest of every `simulation/*.nim` and engine's pinned commit
    ## (`answers.stamp`).  Simulation changed and not answered again reads other stamp
    ## here, and fails until `nim r tools/build.nim answers` is run.
    check engineCommit(readFile(HERE / "tools" / "build.nim")).len == 40
    check answered().stamp == stamp()


  test "every question is answered, at distance couple may stand at":
    ## Kept distance off grid of `stands` would stand couple where search never
    ## looked, and walk from there would be no walk search made.
    var fars: seq[float]
    for far in stands(HUMAN): fars.add far
    let given = answered()
    check given.sweeps.len == SWEEPS.len
    check given.walks.len == WALKS.len
    check given.reaches.len == REACHES.len
    check given.stills.len == STILLS.len
    for question in SWEEPS:
      let sweep = given.sweepOf(question.key)
      for way in [sweep.negative, sweep.positive]:
        if way.is_holding: check way.apart in fars
    for question in WALKS:
      let got = given.walksOf(question.key)
      check got.len == fars.len
      for i in 0..<min(got.len, fars.len): check got[i].apart == fars[i]
    for question in REACHES: discard given.isReaching(question.key)
    for question in STILLS:
      let where = given.stillOf(question.key)
      if where.is_holding: check where.apart in fars


  test "kept answers are what simulation answers now":
    ## Walk from kept distance is search's own walk from there (`live`), so it
    ## has to hold, carry and stop as kept one did, number for number.  And two
    ## walks from single distances, drawn by stamp, are walked again.  Stamp
    ## says simulation has not changed; this says answers came from it.
    let given = answered()
    for question in SWEEPS:
      let sweep = given.sweepOf(question.key)
      for (is_positive, kept) in [(true, sweep.positive), (false, sweep.negative)]:
        if not kept.is_holding: continue
        let went = live(question.key, is_positive)
        check went.is_holding
        check went.is_stopped == kept.is_stopped
        check went.at == kept.at
        check went.why == kept.why
    for (question, kept, went) in replayed():
      echo &"    {question.key}, from {kept.apart:.2f}: kept {kept.carried:.2f}, " &
        &"walked {went.carried:.2f}"
      check went.is_holding == kept.is_holding
      check went.is_stopped == kept.is_stopped
      check went.at == kept.at
