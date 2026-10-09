discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
"""
## Hold planner to engine it plans for: one body in one place, mirror exact, turn keeping
## what it claims, and engine following that turn.
##
##   Planner is geometry alone (`simulation/plan`), and engine judges.  Plan placing any
##     body other than where engine stands it is plan of some other rig, so first law stands
##     couple from plan and reads every point back.
##   Mirror is how planner answers wind one way from plan of other way, so it is held to
##     reflection of every point, not to its own formulas.
##   Turn is held to what planner claims of every moment, measured here again from points:
##     hands together, capsules apart, no point leaping.  Then engine is asked to follow it.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, random, unittest]

import ../simulation/[body, hold, limb, plan {.all.}, rig, rigid, vector, walk]
import ./fixtures
from ../simulation/engine import nil


const
  SAMPLES = 64  ## Seeded random poses each kinematic law is asked of.
  PLACED = 1e-4  ## Metres engine may stand point from plan's: engine holds single
                ## precision, and float's own error over one metre is under this.
  MIRRORED = 1e-9  ## Metres reflected point may sit from mirrored plan's: arithmetic alone.
  WINDS = [0.0, 0.3, -0.7, 1.25]  ## Winds mirror law asks: facing, away, and past whole turn.
  HAND_TO_HAND = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
                   Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Cross-name two-hand hold, uncrossed Face-to-face: chain this suite turns.
  CROSS = 0.5  ## Turns from rest to its cross: shortest wind that lifts hands over crown
              ## and brings them down again facing.
  JOINED = 1e-3  ## Metres planned joined hands may sit apart: `plan.KEPT` is millimetre
                ## squared over whole violation, so one pair is never further.
  TIED = 1e-4  ## Metres engine may part tie of hands stood where plan joins them: tenth of
              ## millimetre, which single precision holds over one metre.


func randomPlan(rig: Rig, generator: var Rand): Plan =
  ## Pose inside every range planner keeps, couple at arm's length or nearer.
  result[0] = generator.rand(0.5..1.2)
  for k in 2..3: result[k] = generator.rand(rig.waist.lower..rig.waist.upper)
  for i in 0..3:
    let base = 4 + PER_ARM * i
    result[base] = generator.rand(rig.collar[Collar.Fore].lower..rig.collar[Collar.Fore].upper)
    result[base+1] = generator.rand(rig.collar[Collar.Up].lower..rig.collar[Collar.Up].upper)
    for k in 2..4: result[base+k] = generator.rand(-1.5..1.5)
    result[base+5] = generator.rand(rig.range[Dof.Bend].lower..rig.range[Dof.Bend].upper)
    for k in 6..8: result[base+k] = generator.rand(-0.8..0.8)
  for i in 0..3: result[DEPTHS+i] = generator.rand(gripAtPalm(rig)..gripAtTips(rig))

func pointsOf(placed: ArmPlaced): array[4, Vector] =
  ## Read four points of arm planner placed, shoulder to join.
  [placed.shoulder, placed.elbow, placed.wrist, placed.join]

func pointsOf(pose: ArmPose): array[4, Vector] =
  ## Read four points of posed arm, shoulder to join.
  [pose.shoulder, pose.elbow, pose.wrist, pose.join]

func reflected(point: Vector): Vector = (-point.x, point.y, point.z)
  ## Point seen in mirror across couple's line.

func asVector(vector: engine.Vector): Vector =
  ## Engine's vector as this project's, in same body's own terms.
  (float(vector.x), float(vector.y), float(vector.z))

proc plainCost(weighing: Weighing, plan: Plan): float =
  ## Cost of pose as planner weighed it before it kept any term: every term reckoned whole
  ## from points, every pair's gap measured.
  let
    problem = weighing.problem
    placed = place(HUMAN, plan, weighing.wind, problem.is_away, problem.turner)
  result = comfort(HUMAN, placed, plan) +
      weighing.weight * violation(HUMAN, problem, placed, weighing.before)
  for k in 0..<SIZE:
    result += weighing.holding * (plan[k] - weighing.last[k])^2 + weighing.bias[k] * plan[k]
  if problem.style.slack > 0.0: result += problem.style.slack * cramped(HUMAN, problem, placed)
  if problem.style.gather > 0.0 and problem.links.len == 2:
    let (one, two) = (problem.links[0].ends[0], problem.links[1].ends[0])
    result += problem.style.gather * distance(placed.arms[armIndex(one.body, one.arm)].join,
                                              placed.arms[armIndex(two.body, two.arm)].join)^2



suite "Internal: Planner and engine are one rig":
  test "gap to palm is read from nearest point of segment, wherever palm lies along it":
    ## Planner holds each palm as point with radius (`plan.place`), so every gap it keeps to
    ##   palm asks `vector.closest` of segment and point.  Read from segment's start, plan of
    ##   drawn D01 kept 5.8 cm between palm and forearm where palm sat 5.4 cm inside it, and
    ##   engine stood that palm 4.3 cm inside forearm, measured 2026-10-02.
    let point: Vector = (0.5, 0.2, 0.0)
    for (a, b) in [((0.0, 0.0, 0.0), (1.0, 0.0, 0.0)), ((1.0, 0.0, 0.0), (0.0, 0.0, 0.0))]:
      let
        near = closest(a, b, point, point)
        back = closest(point, point, a, b)
      check abs(near.gap - 0.2) < MIRRORED
      check abs(near.t - 0.5) < MIRRORED
      check abs(back.gap - 0.2) < MIRRORED


  test "joined hands turn against each other only as far as their grip lets":
    ## Palm to palm, grip locks; by fingertips, it turns freely (`rig.gripFreedom`).  So
    ##   palms turned off facing break plan held at handshake past its cone, and never held by
    ##   fingertips.  Fingers turned off opposed, likewise past its twist.
    ##   Two hands that hold at two depths turn as far as one held nearer fingertips lets,
    ##     and plan keeps its margin inside cone and twist alike.  Red with freedom set by
    ##     hand held nearer palm, measured 2026-10-09.
    const MARGIN = 6.0 * PI / 180.0
    let (cone, twist) = gripFreedom(HUMAN, gripAtPalm(HUMAN))
    for k in 0..SAMPLES:
      let angle = PI * float(k) / float(SAMPLES)
      var a, b: ArmPlaced
      a.palm = (1.0, 0.0, 0.0)
      a.fingers = (0.0, 0.0, 1.0)
      for (palm, fingers, limit) in [
        ((-cos(angle), sin(angle), 0.0), (0.0, 0.0, -1.0), cone),
        ((-1.0, 0.0, 0.0), (0.0, sin(angle), -cos(angle)), twist),
      ]:
        b.palm = palm
        b.fingers = fingers
        for (depth_a, depth_b, is_locked) in [
          (gripAtPalm(HUMAN), gripAtPalm(HUMAN), true),
          (gripAtTips(HUMAN), gripAtTips(HUMAN), false),
          (gripAtPalm(HUMAN), gripAtTips(HUMAN), false),
          (gripAtTips(HUMAN), gripAtPalm(HUMAN), false),
        ]:
          a.depth = depth_a
          b.depth = depth_b
          check (gripBroken(HUMAN, a, b, 0.0) > 0.0) == (is_locked and angle > limit + 1e-9)
          check (gripBroken(HUMAN, a, b, MARGIN) > 0.0) ==
              (is_locked and angle > limit - MARGIN + 1e-9)


  test "engine stands every joint where plan places it, and reads plan back":
    ## Red with collarbone's lift read back with lead's sign on both sides: furthest point
    ## 164 mm off plan, measured 2026-10-02.
    ##   Stood past rest too, turned by either dancer: plan that turns lead stands follow
    ##     where lead's turn leaves them, and engine must stand it there.  Red with engine's
    ##     bodies placed turning follow whatever plan turns: furthest point 1.25 m off plan,
    ##     measured 2026-10-02.
    var
      generator = initRand(31)
      worst = 0.0
    for sample in 0..<SAMPLES:
      let plan = randomPlan(HUMAN, generator)
      for is_away in [false, true]:
        let (wind, turner) = [(0.0, Body.Two), (0.3, Body.Two), (0.3, Body.One)][sample mod 3]
        var couple = build(
          HUMAN,
          turned(restStance(HUMAN, plan[0], is_away), turner, wind),
          Band.Crown,
          HAND_TO_HAND,
          turner,
          is_away,
        )
        let start = placings(HUMAN, plan, wind, is_away, turner)
        couple.placeBodies(start.chests, start.arms)
        var read: Plan
        let vector = couple.poseVector
        for k in 0..<SIZE: read[k] = vector[k]
        let
          planned = place(HUMAN, plan, wind, is_away, turner)
          again = place(HUMAN, read, wind, is_away, turner)
        for who in Body:
          for arm in Arm:
            let
              i = armIndex(who, arm)
              stood = pointsOf(couple.armPoseOf(who, arm))
            for k in 0..3:
              worst = max(worst, distance(stood[k], pointsOf(planned.arms[i])[k]))
              worst = max(worst, distance(pointsOf(again.arms[i])[k], pointsOf(planned.arms[i])[k]))
        couple.free()
    checkpoint "furthest point off plan: " & $worst
    check worst < PLACED


  test "plan curls each free hand toward its palm, where engine holds it":
    ## Architect, 2026-10-04: free hand hangs relaxed, half curled, as hand at rest does.
    ##   Its fingertip lies `rig.relaxed` from wrist and `rig.curled` off hand's own line,
    ##     toward palm; plan places each of its three capsules where engine holds them.
    ##   Free hand holds nothing, so its depth is whole hand, as `boundsOf` keeps it.
    ##   Red with curl turned across knuckles, 30 degrees off line still, measured 2026-10-09.
    let
      single = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)])]
      free_hands = [(Body.One, Arm.Right), (Body.Two, Arm.Left)]
    var
      generator = initRand(37)
      worst = 0.0
    for sample in 0..<SAMPLES:
      var plan = randomPlan(HUMAN, generator)
      for (who, arm) in free_hands: plan[DEPTHS+armIndex(who, arm)] = HUMAN.hand
      let
        placed = place(HUMAN, plan, 0.0, false)
        start = placings(HUMAN, plan, 0.0, false, Body.Two)
      var couple = build(HUMAN, restStance(HUMAN, plan[0]), Band.Crown, single, Body.Two)
      couple.placeBodies(start.chests, start.arms)
      for (who, arm) in free_hands:
        let
          hand = placed.arms[armIndex(who, arm)]
          finger = unit(hand.capsules[4].z - hand.capsules[4].a)
          tip = hand.capsules[4].z + finger * hand.capsules[4].radius
        check abs(distance(hand.wrist, tip) - HUMAN.relaxed) < 1e-9
        check abs(arccos(clamp(dot(finger, hand.fingers), -1.0, 1.0)) - HUMAN.curled) < 1e-9
        # Palm worked out here, from capsules across knuckles and hand's own line, and not
        # read off plan: palm faces link's negative x for right arm (`rigid.tieFrame`).
        let
          across = unit(hand.capsules[5].a - hand.capsules[3].a)
          palm = cross(across, hand.fingers) * -side(arm)
          toward = hand.fingers * cos(HUMAN.curled) + palm * sin(HUMAN.curled)
        check distance(finger, toward) < 1e-9
        var k = 0
        for shape in couple.shapes:
          if shape.mark == Mark.Palm and shape.who == who and shape.arm == arm:
            let ends = couple.endsOf(shape)
            worst = max(worst, distance(ends.a, hand.capsules[3+k].a))
            worst = max(worst, distance(ends.z, hand.capsules[3+k].z))
            inc k
        check k == 3
      couple.free()
    checkpoint "furthest end of free hand's capsule off plan: " & $worst
    check worst < PLACED


  test "engine shortens each held hand to its grip, as plan does":
    ## Hand that holds `depth` deep reaches `rig.handLong` past wrist: fingers past join curl
    ## round partner's hand.  Engine reshapes each held hand so (`rigid.curl`), and holds
    ## capsule that couple records of it.
    ##   Within two millimetres of plan, since engine leaves hand that close alone.  Red with
    ##     no hand reshaped: every hand stood whole hand long, measured 2026-10-09.
    const CURLED = 0.002 + 1e-6
    let single = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)])]
    var
      generator = initRand(41)
      worst = 0.0
    for sample in 0..<SAMPLES:
      let
        plan = randomPlan(HUMAN, generator)
        placed = place(HUMAN, plan, 0.0, false)
        start = placings(HUMAN, plan, 0.0, false, Body.Two)
      var couple = build(HUMAN, restStance(HUMAN, plan[0]), Band.Crown, single, Body.Two)
      couple.placeBodies(start.chests, start.arms)
      for hand in single[0].ends:
        let
          index = armIndex(hand.body, hand.arm)
          long = handLong(HUMAN, plan[DEPTHS+index])
        var k = 0
        for shape in couple.shapes:
          if shape.mark != Mark.Palm or shape.who != hand.body or shape.arm != hand.arm: continue
          let held = engine.capsuleOf(shape.id)
          check distance(asVector(held.center1), asVector(shape.a)) < 1e-6
          check distance(asVector(held.center2), asVector(shape.z)) < 1e-6
          worst = max(worst, abs(float(held.center2.z) + shape.radius - long))
          worst = max(worst, distance(couple.endsOf(shape).z, placed.arms[index].capsules[3+k].z))
          inc k
        check k == 3
      couple.free()
    checkpoint "furthest held hand from its grip's length: " & $worst
    check worst < CURLED


  test "mirror image of plan stands every point at its reflection":
    ## Planner answers wind one way from plan of other way seen in mirror (`walk.pathsFor`),
    ## so every point of mirrored plan wound other way is reflection of one point of plan,
    ## on other arm.
    ##   Red with sign of shoulder's second component kept in mirror: furthest point 1.21 m
    ##     off its reflection, measured 2026-10-02.
    var
      generator = initRand(37)
      worst = 0.0
    for sample in 0..<SAMPLES:
      var plan = randomPlan(HUMAN, generator)
      plan[1] = generator.rand(-0.1..0.1)
      for is_away in [false, true]:
        for wind in WINDS:
          let
            placed = place(HUMAN, plan, wind, is_away)
            image = place(HUMAN, mirrored(plan), -wind, is_away)
          for i in 0..3:
            for k in 0..3:
              worst = max(
                worst,
                distance(reflected(pointsOf(placed.arms[i])[k]), pointsOf(image.arms[i xor 1])[k]),
              )
    checkpoint "furthest reflected point: " & $worst
    check worst < MIRRORED


  test "plan keeps each face from every capsule engine's face meets":
    ## Engine's face meets every link of every arm and partner's girdles, and nothing of its own
    ## trunk and girdles, which share its group (`rigid.FACE_BIT`, `rigid.ownGroup`).  Plan
    ## keeping less stands engine against what plan never kept clear.
    ##   Red with partner's girdles left out of plan, found 2026-10-04 by reading both filters.
    let
      placed = place(HUMAN, default(Plan), 0.0, false)
      capsules = capsulesOf(placed)
      first_arm = 2 * trunkCapsules(HUMAN).len
      per_arm = placed.arms[0].capsules.len
      first_face = capsules.len - placed.faces.len
    for who in Body:
      let face = first_face + ord(who)
      var expected, paired: seq[int]
      for k in first_arm..<first_face:
        let
          i = (k - first_arm) div per_arm
          (owner, part) = ((if i < 2: Body.One else: Body.Two), (k - first_arm) mod per_arm)
        if part >= 1 or owner != who: expected.add k
      for (a, b) in pairsOf(problemOf(HUMAN, HAND_TO_HAND, false)):
        if a == face: paired.add b
        elif b == face: paired.add a
      check paired.len == expected.len
      for k in expected: check k in paired



suite "Internal: Planned turn":
  let path = planPath(HUMAN, HAND_TO_HAND, false, CROSS, STYLES[0])


  test "plan winds hand-to-hand from rest to its cross":
    check path.is_reached
    check path.winds[^1] =~ CROSS


  test "every moment keeps hands joined, capsules apart and no point leaping":
    ## Measured again from points rather than read off planner's own sum: planner that
    ## miscounted its violation would agree with itself.
    ##   Red with joined hands' distance left out of planner's violation, measured
    ##     2026-10-02: every moment past rest parted hands.
    var before: seq[plan.Capsule]
    for moment in 0..<path.plans.len:
      let
        placed = place(HUMAN, path.plans[moment], path.winds[moment], false)
        capsules = capsulesOf(placed)
      for link in HAND_TO_HAND:
        let (one, two) = (link.ends[0], link.ends[1])
        check distance(
          placed.arms[armIndex(one.body, one.arm)].join,
          placed.arms[armIndex(two.body, two.arm)].join,
        ) < JOINED
      for (i, j) in pairsOf(path.problem):
        let
          (p, q) = (capsules[i], capsules[j])
          gap = closest(p.a, p.z, q.a, q.z).gap - p.radius - q.radius
        check gap > path.problem.style.clearance - JOINED
      if moment > 0:
        # Arms only, as planner holds them: trunks and faces are carried by turn itself.
        for k in 2 * trunkCapsules(HUMAN).len ..< capsules.len - placed.faces.len:
          check distance(capsules[k].a, before[k].a) < path.problem.style.leap + JOINED
          check distance(capsules[k].z, before[k].z) < path.problem.style.leap + JOINED
      before = capsules


  test "engine sprung toward plan follows it to cross and stands there":
    ## Engine judges as it judges every walk (`rigid.gives`): nothing through anything,
    ## no joint past its end, hands not parted.
    ##   Red with shoulder aimed at plan's turn outside its rest frame: Reach at first moment.
    ##     Red with collarbone's lift read back with wrong sign: arm met arm at cross.  Both
    ##     measured 2026-10-02.
    let followed = followed(
      HUMAN,
      Band.Crown,
      HAND_TO_HAND,
      false,
      Body.Two,
      path,
      should_stand = true,
    )
    checkpoint "stopped by " & $followed.why & " at " & $followed.at
    check followed.is_holding
    check followed.at =~ CROSS


  test "engine holds each planned moment with every tie whole":
    ## Stood at each moment and sprung toward it for one moment of walk (`walk.BEATS`),
    ## engine parts no tie: what engine holds of grip, it measures as plan does.
    ##   Red with tie's twist limited by engine's own measure, twist about second palm after
    ##     swing, where plan reads angle between finger lines: with palms tilted far apart
    ##     the two part, and engine dragged joined hands up to 0.8 mm apart, at winds 0.12 to
    ##     0.26, measured 2026-10-09.
    var stance = restStance(HUMAN, path.plans[0][0], false)
    stance[Body.Two].centre.x = path.plans[0][1]
    var couple = build(HUMAN, stance, Band.Crown, HAND_TO_HAND, Body.Two, false)
    var most = 0.0
    for moment in 0..<path.plans.len:
      var here = restStance(HUMAN, path.plans[moment][0], false)
      here[Body.Two].centre.x = path.plans[moment][1]
      here = turned(here, path.problem.turner, path.winds[moment])
      let at = placings(HUMAN, path.plans[moment], path.winds[moment], false,
                        path.problem.turner)
      couple.standAt(here, at.chests, at.arms)
      couple.steer(path.plans[moment], STEER)
      couple.advance(BEATS)
      for i in 0..<HAND_TO_HAND.len: most = max(most, couple.poseOf(i).apart)
    couple.free()
    checkpoint "ties parted by " & $(most * 1000.0) & " mm at most"
    check most < TIED



suite "Internal: Planner's cost":
  test "cost of each freedom's step, from terms planner keeps, is plain cost to last bit":
    ## Planner weighs step of arm freedom from terms it keeps, re-reckoning only what arm
    ## moves, and leaves unreckoned pair whose balls keep it past every threshold
    ## (`plan.Reckoning`).  Held here to plain cost of each stepped pose, every term
    ## reckoned whole: equal to last bit, since recording made either way must be same.
    ##   Red with collarbone's step moving palm alone, with near pairs marked at half their
    ##     threshold, with mask or leaps not put back after step, with arm placed one link
    ##     too late, with waist's ease not reckoned in body's step, and with trunk's pairs
    ##     left out of body's step, measured 2026-10-04.
    var generator = initRand(20261004)
    const same_name = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)]),
                        Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])]
    for links in [HAND_TO_HAND, same_name, @[HAND_TO_HAND[0]]]:
      for is_away in [false, true]:
        for style in [STYLES[0], STYLES[13]]:
          var problem = problemOf(HUMAN, links, is_away)
          problem.style = style
          (problem.lower, problem.upper) = bandAt(HUMAN, 0.3, 1.0, is_away, style.room)
          let
            bounds = boundsOf(HUMAN, style.margin, links)
            moving = movedPairs(HUMAN, problem)
          for sample in 0 ..< SAMPLES div 8:
            let wind = generator.rand(-1.0..1.0)
            var weighing = Weighing(problem: problem, wind: wind,
                                    last: randomPlan(HUMAN, generator),
                                    weight: [1e3, 1e5, 1e7][sample mod 3],
                                    holding: style.stay)
            if sample mod 2 == 1:
              weighing.before = capsulesOf(place(HUMAN, randomPlan(HUMAN, generator), wind,
                                                 is_away))
            for k in 4..<SIZE: weighing.bias[k] = generator.rand(-0.05..0.05)
            let plan = randomPlan(HUMAN, generator)
            var
              here: Reckoning
              held: Held
              held_body: HeldBody
            check here.weigh(HUMAN, weighing, plan) == plainCost(weighing, plan)
            let costs = stepped(here, held, held_body, HUMAN, weighing, plan, bounds, moving)
            for k in 0..<SIZE:
              if bounds[k][0] == bounds[k][1]: continue
              var stepped_plan = plan
              stepped_plan[k] += 1e-7
              check costs[k] == plainCost(weighing, stepped_plan)
            check here.total(HUMAN, weighing, plan) == plainCost(weighing, plan)
            # Long step of each freedom carries pairs across every threshold, and back.
            for k in 0..<SIZE:
              if bounds[k][0] == bounds[k][1]: continue
              var far_plan = plan
              far_plan[k] += generator.rand(-0.6..0.6)
              if k < 4:
                let moved = moving.bodies[bodyMoving(k)]
                here.stepBody(held_body, HUMAN, problem, far_plan, wind, k, moved, weighing.before)
                check here.total(HUMAN, weighing, far_plan) == plainCost(weighing, far_plan)
                here.restoreBody(held_body, k, moved)
              else:
                let moved = moving.arms[armMoved(k)][firstMoved(k)]
                here.stepArm(held, HUMAN, problem, far_plan, wind, k, moved, weighing.before)
                check here.total(HUMAN, weighing, far_plan) == plainCost(weighing, far_plan)
                here.restore(held, k, moved)
              check here.total(HUMAN, weighing, plan) == plainCost(weighing, plan)
