## Rig's tape and one arm's geometry, held to what they claim.
##
##   Two suites kept from `tlaws.nim` when solver it tested was retired: neither
##     ever asked solver anything.  Rig's suite holds tape's numbers to their
##     own arithmetic; arm's holds `placed` and `joints` to each other, forward
##     kinematics against reading, so what one sets other reads back.

{.experimental: "strictFuncs".}

import std/[math, random, unittest]

import ../../simulation/[body, contact, limb, rig, vector]
import ../fixtures


const
  APART = 0.40
  LEFT = Arm.Left
  RIGHT = Arm.Right
  SAMPLES_ELBOW = 200  ## Grips and hands elbow law draws, seeded.
  FLOOR_ELBOW = 125
    ## Least of those that arm reaches, so elbow's own checks run: 139 at seed 7, 2026-10-02.
  SAMPLES_CLIPPED = 300  ## Segments clipped law draws, seeded.
  FLOOR_CLIPPED = 200
    ## Least of those that meet torso band, so its wide error is read: 226 at seed 11, 2026-10-02.



suite "Internal: The rig":
  test "a body's rounds are the tape's, and the radii follow":
    for part in Part:
      let
        a = halfBreadth(HUMAN, part)
        b = halfDepth(HUMAN, part)
        h = ((a - b) / (a + b)) ^ 2
        round = PI * (a + b) * (1.0 + 3.0 * h / (10.0 + sqrt(4.0 - 3.0 * h)))
      check abs(round - HUMAN.round[part]) < 1e-3
    check halfBreadth(HUMAN, Part.Neck) =~ HUMAN.round[Part.Neck] / (2.0 * PI)
    check halfDepth(HUMAN, Part.Torso) < halfBreadth(HUMAN, Part.Torso)


  test "the span is the three links, and the bands are ordered":
    check span(HUMAN) =~ 0.64
    check HUMAN.band[Band.Torso].upper < HUMAN.band[Band.Neck].lower
    check HUMAN.band[Band.Neck].upper <= HUMAN.band[Band.Crown].lower
    check HUMAN.band[Band.Crown].lower >= HUMAN.top[Part.Head] + HUMAN.limb - 1e-9
    for part in Part:
      check rig.bottom(HUMAN, part) < HUMAN.top[part]


  test "the shoulder stands outside its own torso, and a hanging arm clears it":
    check HUMAN.shoulder_out > halfBreadth(HUMAN, Part.Torso)
    let stance = facing(HUMAN, APART)[Body.One]
    for arm in Arm:
      let shoulder_point = shoulder(HUMAN, stance, arm)
      check bodyGap(
        HUMAN,
        stance,
        shoulder_point,
        lifted(shoulder_point, -HUMAN.upper),
        is_own = true,
      ).gap >= 0.0


  test "two bodies cannot stand closer than their chests":
    check touching(HUMAN) =~ 2.0 * halfDepth(HUMAN, Part.Torso)


  test "a hand is a quarter turn off the way its body faces":
    let
      stance = facing(HUMAN, APART)
      left_shoulder_one = shoulder(HUMAN, stance[Body.One], LEFT)
      left_shoulder_two = shoulder(HUMAN, stance[Body.Two], LEFT)
    check left_shoulder_one.x =~ -HUMAN.shoulder_out and left_shoulder_one.y =~ 0.0
    check left_shoulder_two.x =~ HUMAN.shoulder_out and
      left_shoulder_two.y =~ APART
    check left_shoulder_one.z =~ HUMAN.shoulder_up



#[ One Arm ]#

suite "Internal: One arm, forward and back":
  let stance = facing(HUMAN, APART)[Body.One]


  test "the elbow keeps both lengths on every swivel":
    var
      random = initRand(7)
      reached = 0
    for _ in 0..<SAMPLES_ELBOW:
      let
        shoulder_point = shoulder(HUMAN, stance, LEFT)
        grip = shoulder_point + (
          random.rand(-0.5..0.5),
          random.rand(-0.5..0.5),
          random.rand(-0.5..0.3),
        )
        hand_direction = unit(
          (
            random.rand(-1.0..1.0),
            random.rand(-1.0..1.0),
            random.rand(-1.0..1.0),
          ),
        )
        chain = posed(HUMAN, shoulder_point, grip, hand_direction, random.rand(0.0..2.0 * PI))
      if chain.stretch <= HUMAN.upper + HUMAN.fore and
         chain.stretch >= abs(HUMAN.upper - HUMAN.fore):
        inc reached
        check distance(chain.pose.shoulder, chain.pose.elbow) =~ HUMAN.upper
        check distance(chain.pose.elbow, chain.pose.wrist) =~ HUMAN.fore
      check distance(chain.pose.wrist, chain.pose.grip) =~ HUMAN.hand
    check reached >= FLOOR_ELBOW


  test "the joints read back what they were set to":
    var worst = 0.0
    for arm in Arm:
      for azimuth in [-60.0, -20.0, 20.0, 60.0, 120.0]:
        for elevation in [-70.0, -30.0, 10.0, 50.0]:
          for twist in [-50.0, 0.0, 60.0]:
            for bend in [20.0, 70.0, 120.0]:
              for wrist in [0.0, 30.0]:
                let
                  upper_direction = unit(
                    (cos(elevation * PI / 180.0) * sin(azimuth * PI / 180.0),
                              cos(elevation * PI / 180.0) * cos(azimuth * PI / 180.0),
                              sin(elevation * PI / 180.0)),
                  )
                  pose = placed(
                    HUMAN,
                    stance,
                    arm,
                    upper_direction,
                    twist * PI / 180.0,
                    bend * PI / 180.0,
                    wrist * PI / 180.0,
                    0.7,
                  )
                  joint_angles = joints(stance, arm, pose)
                worst = max(worst, abs(joint_angles.twist - twist * PI / 180.0))
                worst = max(worst, abs(joint_angles.bend - bend * PI / 180.0))
                worst = max(worst, abs(joint_angles.wrist - wrist * PI / 180.0))
                worst = max(worst, abs(sin(joint_angles.elevation) - upper_direction.z))
                worst = max(worst, abs(-sin(joint_angles.extend) - upper_direction.y))
                worst = max(worst, abs(-sin(joint_angles.across) - upper_direction.x))
    check worst < 1e-6


  test "the twist reads the same across the arm pointing forward":
    for arm in Arm:
      let
        above = placed(HUMAN, stance, arm, unit((0.0, 1.0, 0.02)), 0.3, 1.2, 0.2, 0.0)
        below = placed(HUMAN, stance, arm, unit((0.0, 1.0, -0.02)), 0.3, 1.2, 0.2, 0.0)
        above_angles = joints(stance, arm, above)
        below_angles = joints(stance, arm, below)
      check abs(above_angles.twist - below_angles.twist) < 0.05


  test "the left arm is the right arm in a mirror":
    let
      upper_direction = unit((0.4, 0.6, -0.3))
      right_arm_angles = joints(
        stance,
        RIGHT,
        placed(HUMAN, stance, RIGHT, upper_direction, -0.5, 1.4, 0.4, 0.3),
      )
      left_arm_angles = joints(
        stance,
        LEFT,
        placed(HUMAN, stance, LEFT, upper_direction, -0.5, 1.4, 0.4, 0.3),
      )
    check right_arm_angles.twist =~ left_arm_angles.twist and
      right_arm_angles.across =~ left_arm_angles.across
    check right_arm_angles.extend =~ left_arm_angles.extend and
      right_arm_angles.bend =~ left_arm_angles.bend


  test "a range's margin is an ease in, nought at the edge, negative past it":
    let twist_range = HUMAN.range[Dof.Twist]
    check margin(twist_range, twist_range.upper) =~ 0.0
    check margin(twist_range, twist_range.upper - twist_range.ease_upper) =~ 1.0
    check margin(twist_range, twist_range.upper + 0.1) < 0.0
    check margin(twist_range, twist_range.lower) =~ 0.0
    let bend_range = HUMAN.range[Dof.Bend]
    check margin(bend_range, 0.0) > 1.0  # stop leant on costs nothing
    check margin(bend_range, -0.1) < 0.0  # past stop refuses



#[ Contacts ]#

suite "Internal: Nothing passes through anybody":
  ## Two laws kept from `tlaws.nim` that asked solver nothing: they hold
  ## `contact` and `vector` alone, which engine's own contact does not replace,
  ## since reader still asks them whether arm presses body.
  test "the clipped test agrees with a sampled truth, and errs only wide":
    var
      random = initRand(11)
      finite = 0
    for _ in 0..<SAMPLES_CLIPPED:
      let
        a: Vector = (random.rand(-0.5..0.5), random.rand(-0.5..0.5), random.rand(0.6..1.9))
        b: Vector = (random.rand(-0.5..0.5), random.rand(-0.5..0.5), random.rand(0.6..1.9))
        lower = 0.8
        upper = 1.36
        got = axisNear(a, b, lower, upper).distance
      var truth = Inf
      for i in 0..400:
        let p = a + (b - a) * (float(i) / 400.0)
        if p.z >= lower and p.z <= upper:
          truth = min(truth, sqrt(p.x * p.x + p.y * p.y))
      if truth == Inf:
        check got == Inf
      else:
        inc finite
        check got <= truth + 1e-9
        check got >= truth - 0.003
    check finite >= FLOOR_CLIPPED


  test "over the crown there is nothing to hit":
    let
      stance = facing(HUMAN, APART)[Body.Two]
      top = HUMAN.top[Part.Head] + HUMAN.limb + 0.001
    check bodyGap(HUMAN, stance, (0.0, 0.0, top), (0.0, 0.8, top), is_own = false).gap == Inf
