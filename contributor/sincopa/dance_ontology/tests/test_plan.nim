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

import ../simulation/[body, hold, limb, plan, rig, rigid, vector, walk]


const
  SAMPLES = 64 ## Seeded random poses each kinematic law is asked of.
  PLACED = 1e-4 ## Metres engine may stand point from plan's: engine holds single
                ## precision, and float's own error over one metre is under this.
  MIRRORED = 1e-9 ## Metres reflected point may sit from mirrored plan's: arithmetic alone.
  WINDS = [0.0, 0.3, -0.7, 1.25] ## Winds mirror law asks: facing, away, and past whole turn.
  HAND_TO_HAND = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
                   Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Cross-name two-hand hold, uncrossed Face-to-face: chain this suite turns.
  CROSS = 0.5 ## Turns from rest to its cross: shortest wind that lifts hands over crown
              ## and brings them down again facing.
  JOINED = 1e-3 ## Metres planned joined hands may sit apart: `plan.KEPT` is millimetre
                ## squared over whole violation, so one pair is never further.


func randomPlan(rig: Rig; generator: var Rand): Plan =
  ## Pose inside every range planner keeps, couple at arm's length or nearer.
  result[0] = generator.rand(0.5 .. 1.2)
  for k in 2 .. 3: result[k] = generator.rand(rig.waist.lower .. rig.waist.upper)
  for i in 0 .. 3:
    let base = 4 + PER_ARM * i
    result[base] = generator.rand(rig.collar[Collar.Fore].lower .. rig.collar[Collar.Fore].upper)
    result[base + 1] = generator.rand(rig.collar[Collar.Up].lower .. rig.collar[Collar.Up].upper)
    for k in 2 .. 4: result[base + k] = generator.rand(-1.5 .. 1.5)
    result[base + 5] = generator.rand(rig.range[Dof.Bend].lower .. rig.range[Dof.Bend].upper)
    for k in 6 .. 8: result[base + k] = generator.rand(-0.8 .. 0.8)

func pointsOf(placed: ArmPlaced): array[4, Vector] =
  [placed.shoulder, placed.elbow, placed.wrist, placed.grip]

func pointsOf(pose: ArmPose): array[4, Vector] =
  [pose.shoulder, pose.elbow, pose.wrist, pose.grip]

func reflected(point: Vector): Vector = (-point.x, point.y, point.z)
  ## Point seen in mirror across couple's line.


suite "planner and engine are one rig":

  test "engine stands every joint where plan places it, and reads plan back":
    ## Red with collarbone's lift read back with lead's sign on both sides: furthest point
    ## 164 mm off plan, measured 2026-10-02.
    var
      generator = initRand(31)
      worst = 0.0
    for sample in 0 ..< SAMPLES:
      let plan = randomPlan(HUMAN, generator)
      for is_away in [false, true]:
        var couple = build(HUMAN, restStance(HUMAN, plan[0], is_away), Band.Crown,
                           HAND_TO_HAND, Body.Two, is_away)
        let start = placings(HUMAN, plan, 0.0, is_away)
        couple.placeBodies(start.chests, start.arms)
        var read: Plan
        let vector = couple.poseVector
        for k in 0 ..< SIZE: read[k] = vector[k]
        let
          planned = place(HUMAN, plan, 0.0, is_away)
          again = place(HUMAN, read, 0.0, is_away)
        for who in Body:
          for arm in Arm:
            let
              i = armIndex(who, arm)
              stood = pointsOf(couple.armPoseOf(who, arm))
            for k in 0 .. 3:
              worst = max(worst, distance(stood[k], pointsOf(planned.arms[i])[k]))
              worst = max(worst, distance(pointsOf(again.arms[i])[k],
                                          pointsOf(planned.arms[i])[k]))
        couple.free()
    checkpoint "furthest point off plan: " & $worst
    check worst < PLACED

  test "mirror image of plan stands every point at its reflection":
    ## Planner answers wind one way from plan of other way seen in mirror (`walk.pathsFor`),
    ## so every point of mirrored plan wound other way is reflection of one point of plan,
    ## on other arm.
    ##   Red with sign of shoulder's second component kept in mirror: furthest point 1.21 m
    ##     off its reflection, measured 2026-10-02.
    var
      generator = initRand(37)
      worst = 0.0
    for sample in 0 ..< SAMPLES:
      var plan = randomPlan(HUMAN, generator)
      plan[1] = generator.rand(-0.1 .. 0.1)
      for is_away in [false, true]:
        for wind in WINDS:
          let
            placed = place(HUMAN, plan, wind, is_away)
            image = place(HUMAN, mirrored(plan), -wind, is_away)
          for i in 0 .. 3:
            for k in 0 .. 3:
              worst = max(worst, distance(reflected(pointsOf(placed.arms[i])[k]),
                                          pointsOf(image.arms[i xor 1])[k]))
    checkpoint "furthest reflected point: " & $worst
    check worst < MIRRORED


suite "planned turn":
  let path = planPath(HUMAN, HAND_TO_HAND, false, CROSS, STYLES[0])

  test "plan winds hand-to-hand from rest to its cross":
    check path.is_reached
    check abs(path.winds[^1] - CROSS) < 1e-9

  test "every moment keeps hands joined, capsules apart and no point leaping":
    ## Measured again from points rather than read off planner's own sum: planner that
    ## miscounted its violation would agree with itself.
    ##   Red with joined hands' distance left out of planner's violation, measured
    ##     2026-10-02: every moment past rest parted hands.
    var before: seq[plan.Capsule]
    for moment in 0 ..< path.plans.len:
      let
        placed = place(HUMAN, path.plans[moment], path.winds[moment], false)
        capsules = capsulesOf(placed)
      for link in HAND_TO_HAND:
        let (one, two) = (link.ends[0], link.ends[1])
        check distance(placed.arms[armIndex(one.body, one.arm)].grip,
                       placed.arms[armIndex(two.body, two.arm)].grip) < JOINED
      for (i, j) in pairsOf(path.problem):
        let
          (p, q) = (capsules[i], capsules[j])
          gap = closest(p.a, p.z, q.a, q.z).gap - p.radius - q.radius
        check gap > path.problem.style.clearance - JOINED
      if moment > 0:
        # Arms only, as planner holds them: trunks are carried by turn itself.
        for k in 2 * trunkCapsules(HUMAN).len ..< capsules.len:
          check distance(capsules[k].a, before[k].a) < path.problem.style.leap + JOINED
          check distance(capsules[k].z, before[k].z) < path.problem.style.leap + JOINED
      before = capsules

  test "engine sprung toward plan follows it to cross and stands there":
    ## Engine judges as it judges every walk (`rigid.gives`): nothing through anything,
    ## no joint past its end, hands not parted.
    ##   Red with shoulder aimed at plan's turn outside its rest frame: Reach at first moment.
    ##     Red with collarbone's lift read back with wrong sign: arm met arm at cross.  Both
    ##     measured 2026-10-02.
    let followed = followed(HUMAN, Band.Crown, HAND_TO_HAND, false, Body.Two, path,
                            should_stand = true)
    checkpoint "stopped by " & $followed.why & " at " & $followed.at
    check followed.is_holding
    check abs(followed.at - CROSS) < 1e-9
