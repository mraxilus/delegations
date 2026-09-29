## One arm: where its joints are for given hand, and what each joint reads.
##
##   Arm is three rigid links -- upper arm, forearm, hand -- on shoulder
##     that swings and twists, elbow that bends, and wrist that bends any
##     way.  Forearm's own rotation is left free: it turns palm, and
##     grip is one point.
##   Given shoulder and grip, pose has three freedoms: which way
##     hand points off wrist (two), and where elbow sits on
##     circle its two-link chain leaves it (one).  Everything else follows.  So
##     solver next door searches three numbers per arm, and every pose it
##     ever tries has its lengths right by construction.
##   Joints are read back off pose, in body's own terms, and
##     left arm is read in mirror so that one set of ranges serves both.
##     Shoulder's twist is read swing-and-twist: arm at rest hangs
##     down with elbow bending forward; at any other direction
##     resting plane is carried there by least rotation, and twist is
##     how far actual elbow plane is turned from it.  That reading is
##     continuous everywhere but vertical arm, which no hold reaches.
##     Cost: reading is convention, and anatomists have three.  Accepted
##       -- this one has its one singularity where no dancer's arm goes, and
##       ranges cited for it are ordinary clinical ones.

{.experimental: "strictFuncs".}

import std/math

import ./[body, rig, vector]


type
  ArmPose* = object ## Four points of one arm, in world.
    shoulder*, elbow*, wrist*, grip*: Vector ## Shoulder, elbow, wrist, grip.

  Joints* = object ## What each joint reads, radians, in body's own terms.
    extend*, across*, elevation*: float ## Upper arm: behind, across, up.
    twist*, bend*, wrist*: float

  Chain* = object ## What laying out arm to grip found.
    pose*: ArmPose
    stretch*: float ## Shoulder to wrist: over `upper + fore` is out of reach.

  Circle* = object ## Circle elbow can sit on for one grip and hand.
    ##   Everything `posed` works out that does not depend on swivel, kept
    ##     so seed can try every swivel round it for price of one.
    shoulder*, wrist*: Vector ## Shoulder and wrist.
    stretch*: float ## Shoulder to wrist.
    axis*: Vector ## Unit, shoulder towards wrist; zero where two coincide.
    along*, radius*: float ## Circle's centre along `axis`, and its radius.
    down*, side*: Vector ## Its basis: lowest point's direction, and across.

  Swing* = object ## Joints read before twist, and what twist needs.
    joints*: Joints ## Everything but `twist`, which is nought here.
    upper*, fore*: Vector ## Unit: upper arm and forearm, in body's mirrored terms.

const
  REST_DOWN = (0.0, 0.0, -1.0) ## Upper arm hanging: swing's rest.
  REST_PLANE = (1.0, 0.0, 0.0) ## Its elbow plane's normal at rest: bending
                               ## forward, with arm read as right arm.
  STRAIGHT = 5.0 * PI / 180.0  ## Under this bend elbow has no plane, so
                               ## no twist is read off it.


func shoulderLocal*(rig: Rig): Vector = (rig.shoulder_out, 0.0, rig.shoulder_up)
  ## Shoulder in body's mirrored terms: always right arm here.


func circleOf*(rig: Rig; shoulder_point, grip_point, hand_direction: Vector): Circle =
  ## Elbow's circle for arm from shoulder `shoulder_point` to grip `grip_point` with
  ## hand pointing along unit `hand_direction`.
  result.shoulder = shoulder_point
  result.wrist = grip_point - hand_direction * rig.hand
  result.stretch = distance(result.wrist, shoulder_point)
  if result.stretch < 1e-9:
    return
  let d = result.stretch
  result.axis = (result.wrist - shoulder_point) * (1.0 / d)
  result.along = clamp((rig.upper * rig.upper - rig.fore * rig.fore + d * d) / (2.0 * d),
                       -rig.upper, rig.upper)
  result.radius = sqrt(max(0.0, rig.upper * rig.upper - result.along * result.along))
  var down = REST_DOWN - result.axis * dot(REST_DOWN, result.axis)
  if norm(down) < 1e-6:
    down = perpendicular(result.axis)
  else:
    down = unit(down)
  result.down = down
  result.side = cross(result.axis, down)

func posedOn*(rig: Rig; circle: Circle; grip_point: Vector;
              cosine_swivel, sine_swivel: float): Chain =
  ## Lay arm with its elbow on circle at swivel whose cosine and
  ## sine these are.
  result.stretch = circle.stretch
  if circle.stretch < 1e-9:
    result.pose = ArmPose(
      shoulder: circle.shoulder,
      elbow: circle.shoulder + (0.0, 0.0, -rig.upper),
      wrist: circle.wrist,
      grip: grip_point,
    )
    return
  let elbow_point = circle.shoulder + circle.axis * circle.along +
    circle.down * (circle.radius * cosine_swivel) + circle.side * (circle.radius * sine_swivel)
  result.pose = ArmPose(
    shoulder: circle.shoulder,
    elbow: elbow_point,
    wrist: circle.wrist,
    grip: grip_point,
  )

func posed*(rig: Rig; shoulder_point, grip_point, hand_direction: Vector; swivel: float): Chain =
  ## Lay arm from shoulder `shoulder_point` to grip `grip_point` with hand pointing along
  ## unit `hand_direction` and elbow at `swivel` round its circle, nought being
  ## lowest elbow can hang.
  ##   Out of reach is not refused here: elbow goes as far as it can and
  ##     forearm is left too long, so that searcher minimising
  ##     overshoot has something smooth to descend.
  posedOn(
    rig,
    circleOf(rig, shoulder_point, grip_point, hand_direction),
    grip_point,
    cos(swivel),
    sin(swivel),
  )


func placed*(rig: Rig; stance: Stance; arm: Arm; upper_direction: Vector;
             twist, bend, wrist, roll: float): ArmPose =
  ## Build arm from its joints: upper arm along unit `upper_direction` in
  ## body's mirrored terms, twisted, bent at elbow, hand off
  ## forearm by `wrist` in direction `roll` turns it to.
  ##   Forward kinematics, for laws: what `joints` reads must be what
  ##     was set here.
  let
    plane = spun(carried(REST_PLANE, REST_DOWN, upper_direction), upper_direction, twist)
    fore_direction = upper_direction * cos(bend) + cross(plane, upper_direction) * sin(bend)
    tip_direction = spun(plane, fore_direction, roll)
    hand_direction = fore_direction * cos(wrist) + tip_direction * sin(wrist)
    shoulder_point = shoulderLocal(rig)
    elbow_point = shoulder_point + upper_direction * rig.upper
    wrist_point = elbow_point + fore_direction * rig.fore
    grip_point = wrist_point + hand_direction * rig.hand
    axes = axesOf(stance)
  if arm == Arm.Left:
    ArmPose(
      shoulder: toWorld(axes, mirrored(shoulder_point)),
      elbow: toWorld(axes, mirrored(elbow_point)),
      wrist: toWorld(axes, mirrored(wrist_point)),
      grip: toWorld(axes, mirrored(grip_point)),
    )
  else:
    ArmPose(
      shoulder: toWorld(axes, shoulder_point),
      elbow: toWorld(axes, elbow_point),
      wrist: toWorld(axes, wrist_point),
      grip: toWorld(axes, grip_point),
    )


func ownTerms*(axes: Axes; arm: Arm; point: Vector): Vector =
  ## World point in body's mirrored terms: right arm's, always.
  let body_point = toBody(axes, point)
  if arm == Arm.Left: mirrored(body_point) else: body_point

func swing*(axes: Axes; arm: Arm; pose: ArmPose): Swing =
  ## Read every joint but twist off pose, in body's own terms.
  ##   Twist is dear one to read, and one each seed asks for last,
  ##     so it is read apart.
  let
    shoulder_point = ownTerms(axes, arm, pose.shoulder)
    elbow_point = ownTerms(axes, arm, pose.elbow)
    wrist_point = ownTerms(axes, arm, pose.wrist)
    grip_point = ownTerms(axes, arm, pose.grip)
    upper_direction = unit(elbow_point - shoulder_point)
    fore_direction = unit(wrist_point - elbow_point)
    hand_direction = unit(grip_point - wrist_point)
  result.upper = upper_direction
  result.fore = fore_direction
  result.joints.extend = arcsin(clamp(-upper_direction.y, -1.0, 1.0))
  result.joints.across = arcsin(clamp(-upper_direction.x, -1.0, 1.0))
  result.joints.elevation = arcsin(clamp(upper_direction.z, -1.0, 1.0))
  result.joints.bend = angleBetween(upper_direction, fore_direction)
  result.joints.wrist = angleBetween(fore_direction, hand_direction)

func twistOf*(arm_swing: Swing): float =
  ## Shoulder's twist, read off elbow's plane; nought where
  ## elbow is too straight to have one.
  if arm_swing.joints.bend > STRAIGHT:
    let
      rest = carried(REST_PLANE, REST_DOWN, arm_swing.upper)
      plane = unit(cross(arm_swing.upper, arm_swing.fore))
    signedAngle(rest, plane, arm_swing.upper)
  else:
    0.0

func joints*(axes: Axes; arm: Arm; pose: ArmPose): Joints =
  ## Read every joint off pose, in body's own terms, body's
  ## axes already worked out.
  let arm_swing = swing(axes, arm, pose)
  result = arm_swing.joints
  result.twist = twistOf(arm_swing)

func joints*(stance: Stance; arm: Arm; pose: ArmPose): Joints =
  ## Read every joint off pose, in body's own terms.
  joints(axesOf(stance), arm, pose)


func reading*(arm_joints: Joints; dof: Dof): float =
  ## One value of joints that range applies to.
  case dof
  of Dof.Extend: arm_joints.extend
  of Dof.Across: arm_joints.across
  of Dof.Twist: arm_joints.twist
  of Dof.Bend: arm_joints.bend
  of Dof.Wrist: arm_joints.wrist

func margins*(rig: Rig; arm_joints: Joints): array[Dof, float] =
  ## Each freedom's distance inside its range, in its ease.
  for dof in Dof:
    result[dof] = margin(rig.range[dof], reading(arm_joints, dof))

func strain*(rig: Rig; arm_joints: Joints): tuple[most: float, dof: Dof] =
  ## How far into last stretch before edge arm is: nought well
  ## inside, one at edge, more past it; and which joint that is.
  result = (0.0, Dof.Extend)
  var least = Inf
  for dof in Dof:
    let joint_margin = margin(rig.range[dof], reading(arm_joints, dof))
    if joint_margin < least:
      least = joint_margin
      result.dof = dof
  result.most = max(0.0, 1.0 - least)

func room*(rig: Rig; arm_joints: Joints): float =
  ## How far nearest joint is from *either* end of its range, in that
  ## end's ease: freedom arm has to move any way at all.
  ##   Unlike `margin`, stop with no ease counts as end here --
  ##     straight elbow cannot straighten further, however painless it is.
  ##     Wrist's range is cone, so its nought is its middle, not
  ##     end, and only cone's edge counts.
  result = Inf
  for dof in Dof:
    let
      joint_range = rig.range[dof]
      value = reading(arm_joints, dof)
      unit_lower = if joint_range.ease_lower > 0.0: joint_range.ease_lower
                   else: joint_range.ease_upper
      unit_upper = if joint_range.ease_upper > 0.0: joint_range.ease_upper
                   else: joint_range.ease_lower
    result = min(result, (joint_range.upper - value) / unit_upper)
    if dof != Dof.Wrist:
      result = min(result, (value - joint_range.lower) / unit_lower)

func comfort*(rig: Rig; arm_joints: Joints): float =
  ## Smooth cost of pose: how far every joint sits from its rest,
  ## squared and summed, with arm's lift counted too.
  ##   Minimised by solver among poses that hold, so that neighbouring
  ##     turns get neighbouring poses and hanging arm is preferred to
  ##     raised one where both would do.
  for dof in Dof:
    let from_neutral = eased(rig.range[dof], reading(arm_joints, dof))
    result += from_neutral * from_neutral
  let lift = (arm_joints.elevation + PI / 2.0) / PI
  result += lift * lift
