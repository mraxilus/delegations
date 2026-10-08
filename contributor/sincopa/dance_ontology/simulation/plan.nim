## Plan couple's arms through turn: at each moment, comfiest pose near last one that keeps
## hands joined, every capsule clear of every other, every joint inside its range, and
## joined hands inside their band.  Engine then springs every joint toward plan and judges.
##
##   Why plan at all: engine carries arms where weak pulls on hands leave them, and arms
##     caught on head or on each other stay caught.  Dancer chooses whole arm, and so does
##     plan: elbow, shoulder's roll, collarbone, waist and where to stand, each moment.
##   Plan is geometry alone, same capsules and ranges engine has (`rigid`), so engine
##     springing toward plan meets nothing plan did not already keep clear.
##   Continuity: each moment starts from last and may move no point of any arm further
##     than its style's leap, under arm's own thickness.  Engine, following, carries arms
##     between moments as solid capsules, so arm that would pass through arm is stopped
##     and judged there.

{.experimental: "strictFuncs".}

import std/[bitops, math]

import ./[body, hold, rig, vector]
from ./rigid {.all.} import ArmPlacing, ELBOW_END, ELBOWS_APART, faceCapsule, GIRDLE_RADIUS,
  GRIPS, handCapsules, Matrix, MATRIX_REST, ON_UPPER, times, transposed, trunkCapsules, turnAbout


const
  PER_ARM* = 9  ## Freedoms of one arm: two of collarbone, three of shoulder, elbow, three of wrist.
  SIZE* = 4 + 4 * PER_ARM + 4
    ## Apart, sideways (held nought), two waists, four arms, and how deep each arm's hand
    ## holds (`rigid.GRIPS`).
  PER_ARM_CAPSULES = 6  ## Capsules of one arm: girdle, upper, fore and three of hand.
  ARM_CAPSULES = 4 * PER_ARM_CAPSULES  ## Capsules of four arms, after trunks.

type
  Plan* = array[SIZE, float]  ## One pose of couple, as planner holds it.

  Capsule* = tuple[a, z: Vector, radius: float]

  Shape = object  ## One capsule's owner, as engine's filters read it.
    who: Body
    arm: int  ## Arm index nought to three, -1 for trunk, -2 for face.
    part: int  ## Nought girdle, one upper, two fore, three to five hand; -1 trunk or face.

  Style* = object  ## How couple go about turn: one setting among several planner tries.
    gather*: float  ## Newtons per metre, as weight, drawing two joined pairs to one point.
    leap*: float  ## Metres any point of arm may move between two moments.
    stay*: float  ## Weight holding each moment near last one.
    seed*: int  ## Which of fixed starting poses rest is sought from.
    margin*: float  ## Radians plan keeps inside every joint's end engine holds.
    room*: float  ## Metres plan keeps inside band judge holds hands to.
    clearance*: float  ## Metres plan keeps between capsules: engine's own slop under it.
    slack*: float  ## Weight on keeping well clear of arms and band's edges, beyond margins.

  Problem* = object  ## What one moment asks: hold, rest, band, style.
    style*: Style
    links*: seq[Link]
    is_away*: bool
    turner*: Body  ## Dancer whose facing carries wind: one at centre of turn.
    lower*, upper*: float  ## Band joined hands are held to, metres.
    shapes: seq[Shape]
    pairs: seq[(int, int)]
    crossing: seq[int]  ## Pairs of one dancer's upper arm and their other arm, by place.

const
  CROSS_ROOM = ON_UPPER + 0.005  ## Metres plan keeps upper arm from another arm, short of its
                                ## elbow's end: judge's own, and engine's slop under it.
  ELBOW_ROOM = ELBOWS_APART + 0.01  ## Metres plan keeps right elbow right of left: judge's own,
                                   ## and room under it.
  ROOMY = 0.04  ## Metres plan would sooner keep from arms and band's edges, where it can.
  FACE_WINDOW = 0.1  ## Of way up within which plan holds hands at torso band: twice judge's
                    ## `rigid.FACING`, so engine following plan has hands down when judged.

func armIndex*(who: Body, arm: Arm): int = 2 * ord(who) + ord(arm)
  ## Arm's place in plan: lead's left, lead's right, follow's left, follow's right.

func apply(a: Matrix, v: Vector): Vector =
  ## Turn vector by matrix, i.e. `a` `v`.
  (a[0][0] * v.x + a[0][1] * v.y + a[0][2] * v.z,
   a[1][0] * v.x + a[1][1] * v.y + a[1][2] * v.z,
   a[2][0] * v.x + a[2][1] * v.y + a[2][2] * v.z)

func column(a: Matrix, j: int): Vector = (a[0][j], a[1][j], a[2][j])
  ## Read column `j` of matrix: where turn carries axis `j`.

func aboutUp(angle: float): Matrix =
  ## Turn by `angle` about vertical axis, anticlockwise seen from above.
  [[cos(angle), -sin(angle), 0.0], [sin(angle), cos(angle), 0.0], [0.0, 0.0, 1.0]]

func aboutFore(angle: float): Matrix =
  ## Turn by `angle` about forward axis.
  [[cos(angle), 0.0, sin(angle)], [0.0, 1.0, 0.0], [-sin(angle), 0.0, cos(angle)]]

func aboutRight(angle: float): Matrix =
  ## Turn by `angle` about rightward axis.
  [[1.0, 0.0, 0.0], [0.0, cos(angle), -sin(angle)], [0.0, sin(angle), cos(angle)]]


func shoulderTurn*(plan: Plan, i: int): Matrix =
  ## Upper arm's turn from rest in frame of its girdle: what engine's ball reads.
  let base = 4 + PER_ARM * i
  times(
    transposed(MATRIX_REST),
    times(turnAbout([plan[base+2], plan[base+3], plan[base+4]]), MATRIX_REST),
  )

func wristTurn*(plan: Plan, i: int): Matrix =
  ## Hand's turn in frame of its forearm: what engine's wrist reads.
  let base = 4 + PER_ARM * i
  turnAbout([plan[base+6], plan[base+7], plan[base+8]])

func twistOf(turn: Matrix): float = arctan2(turn[1][0] - turn[0][1], turn[0][0] + turn[1][1])
  ## Engine's twist of ball's turn about its own z (`b3GetTwistAngle`).


type
  ArmPlaced* = object  ## One arm placed in world, and what its joints read.
    shoulder*, elbow*, wrist*, grip*: Vector
    carried*: Vector  ## Where hand is carried, which band is asked of (`limb.carriedOf`).
    palm*, fingers*: Vector  ## Unit out of palm, and unit along fingers.
    depth*: float  ## How far past wrist hand holds.
    capsules*: array[6, Capsule]
    twist*, bend*, cone*, extend*, protract*, elevate*: float
    turns: array[4, Matrix]  ## Girdle's, upper arm's, forearm's and hand's, in body's frame.
    joints: array[3, Vector]  ## Shoulder, elbow and wrist, in body's frame.

  Placed* = object  ## Whole couple placed.
    arms*: array[4, ArmPlaced]
    trunks*: array[Body, seq[Capsule]]
    faces*: array[Body, Capsule]  ## Sphere ahead of each head, which every arm keeps off.


func facingOf*(plan: Plan, who: Body, wind: float, is_away: bool, turner = Body.Two): float =
  ## Way chest faces: lead along y, follow back along it, turner turned by wind.
  ##   Turner turns on own spot and partner stays where they stand, as card draws it: lead
  ##     who turns quarter has follow at side, and follow who turns quarter is still ahead.
  ##   Wind is added second, in one order for both: swan's planned still holds or not on
  ##     last bit of this sum.  Added last, D01 and D07 stood no pose.
  let turned = (if who == turner: 2.0 * PI * wind else: 0.0)
  if who == Body.One: PI / 2.0 + turned + plan[2]
  else: -PI / 2.0 + turned + (if is_away: PI else: 0.0) + plan[3]

type Frame = tuple[origin, right, fore: Vector]  ## Where one body stands, and its right and fore.

func frameOf(plan: Plan, who: Body, wind: float, is_away: bool, turner: Body): Frame =
  ## Where body stands at this plan and wind, and which way its right and fore point.
  let
    facing = facingOf(plan, who, wind, is_away, turner)
    origin: Vector = (if who == Body.One: (0.0, 0.0, 0.0) else: (plan[1], plan[0], 0.0))
    right: Vector = (sin(facing), -cos(facing), 0.0)
    fore: Vector = (cos(facing), sin(facing), 0.0)
  (origin, right, fore)

func world(frame: Frame, p: Vector): Vector =
  ## Carry point from body's own frame into world.
  frame.origin + frame.right * p.x + frame.fore * p.y + (0.0, 0.0, p.z)

func toward(frame: Frame, v: Vector): Vector =
  ## Carry direction from body's own frame into world.
  frame.right * v.x + frame.fore * v.y + (0.0, 0.0, v.z)

func placeArm(
  rig: Rig, plan: Plan, i: int, frame: Frame, first = 0, held = default(ArmPlaced)
): ArmPlaced =
  ## One arm placed in world, its body standing in `frame`, and what its joints read.
  ##   Where `first` is above nought, turns and joints above that link are `held`'s: arm
  ##     placed from its girdle (nought), upper arm (one), forearm (two) or hand (three) on,
  ##     or from none (four) where body alone moved.  Each is reckoned by same steps from
  ##     same freedoms, so arm is same to last bit; every point is carried into world again.
  ##   Hand holds as deep as plan's grip freedom says (`GRIPS`), and its capsules reach as
  ##     far as that grip lets (`rig.handLong`).
  let
    neck = halfBreadth(rig, Part.Neck)
    base = 4 + PER_ARM * i
    handedness = side(Arm(i mod 2))
    root: Vector = (handedness * neck, 0.0, rig.top[Part.Torso])
  result = held
  if first <= 0:
    let reach: Vector = (
      handedness * (rig.shoulder_out - neck),
      0.0,
      rig.shoulder_up - rig.top[Part.Torso],
    )
    result.turns[0] = times(aboutUp(handedness * plan[base]), aboutFore(-handedness * plan[base+1]))
    result.joints[0] = root + apply(result.turns[0], reach)
    result.protract = plan[base]
    result.elevate = plan[base+1]
  if first <= 1:
    result.turns[1] = times(
      result.turns[0],
      times(turnAbout([plan[base+2], plan[base+3], plan[base+4]]), MATRIX_REST),
    )
    result.joints[1] = result.joints[0] + column(result.turns[1], 2) * rig.upper
    result.twist = twistOf(shoulderTurn(plan, i))
    result.extend = arcsin(clamp(-column(result.turns[1], 2).y, -1.0, 1.0))
  if first <= 2:
    result.turns[2] = times(result.turns[1], aboutRight(plan[base+5]))
    result.joints[2] = result.joints[1] + column(result.turns[2], 2) * rig.fore
    result.bend = plan[base+5]
  if first <= 3:
    result.turns[3] = times(result.turns[2], wristTurn(plan, i))
    result.cone = arccos(clamp(dot(column(result.turns[2], 2), column(result.turns[3], 2)),
                               -1.0, 1.0))
  let
    (shoulder, elbow, wrist) = (result.joints[0], result.joints[1], result.joints[2])
    (upper, forearm, hand) = (result.turns[1], result.turns[2], result.turns[3])
    depth = plan[GRIPS+i]
    grip = wrist + column(hand, 2) * depth
    direction = column(upper, 2)
  result.shoulder = frame.world(shoulder)
  result.elbow = frame.world(elbow)
  result.wrist = frame.world(wrist)
  result.grip = frame.world(grip)
  result.carried = frame.world(wrist + column(hand, 2) * rig.carry)
  # Palm faces in toward body at rest: link's negative x for right arm (`rigid.gripFrame`).
  result.palm = frame.toward(column(hand, 0) * -handedness)
  result.fingers = frame.toward(column(hand, 2))
  result.depth = depth
  result.capsules[0] = (frame.world(root), frame.world(shoulder), GIRDLE_RADIUS)
  result.capsules[1] = (frame.world(shoulder + direction * rig.limb),
                        frame.world(shoulder + direction * (rig.upper - rig.limb)), rig.limb)
  result.capsules[2] = (frame.world(elbow + column(forearm, 2) * rig.limb),
                        frame.world(elbow + column(forearm, 2) * (rig.fore - rig.limb)), rig.limb)
  for k, (a, z, radius) in handCapsules(rig, handLong(rig, depth)):
    result.capsules[3+k] = (frame.world(wrist + apply(hand, a)),
                              frame.world(wrist + apply(hand, z)), radius)

func place*(rig: Rig, plan: Plan, wind: float, is_away: bool, turner = Body.Two): Placed =
  ## Every capsule and joint reading of couple at this plan and wind.
  for who in Body:
    let frame = frameOf(plan, who, wind, is_away, turner)
    for (a, z, radius) in trunkCapsules(rig):
      result.trunks[who].add (frame.world(a), frame.world(z), radius)
    let face = faceCapsule(rig)
    result.faces[who] = (frame.world(face.a), frame.world(face.z), face.radius)
    for arm in Arm:
      let i = armIndex(who, arm)
      result.arms[i] = placeArm(rig, plan, i, frame)

func pairsOf*(problem: Problem): seq[(int, int)] = problem.pairs
  ## Every pair of capsules engine collides, by index into `capsulesOf`.

func capsulesOf*(placed: Placed): seq[Capsule] =
  ## Every capsule, trunks first, then each arm's girdle, upper, fore and three of hand, then
  ## each face.
  for who in Body:
    for capsule in placed.trunks[who]: result.add capsule
  for i in 0..3:
    for capsule in placed.arms[i].capsules: result.add capsule
  for who in Body: result.add placed.faces[who]


func problemOf*(rig: Rig, links: seq[Link], is_away: bool, turner = Body.Two): Problem =
  ## Hold, and every pair of capsules engine collides, by its own filters.
  result = Problem(links: links, is_away: is_away, turner: turner, lower: 0.0, upper: 3.0)
  for who in Body:
    for _ in trunkCapsules(rig):
      result.shapes.add Shape(who: who, arm: -1, part: -1)
  for i in 0..3:
    for part in 0..5:
      result.shapes.add Shape(who: (if i < 2: Body.One else: Body.Two), arm: i, part: part)
  for who in Body:
    result.shapes.add Shape(who: who, arm: -2, part: -1)
  var joined: seq[(int, int)]
  for link in links:
    let
      a = armIndex(link.ends[0].body, link.ends[0].arm)
      b = armIndex(link.ends[1].body, link.ends[1].arm)
    joined.add (a, b)
    joined.add (b, a)
  for i in 0..<result.shapes.len:
    for j in i + 1 ..< result.shapes.len:
      let (p, q) = (result.shapes[i], result.shapes[j])
      # Face meets every link of every arm, and partner's girdles: own girdles run from neck,
      # and share its group.
      if p.arm == -2 or q.arm == -2:
        let (face, other) = (if p.arm == -2: (p, q) else: (q, p))
        if other.arm >= 0 and (other.part >= 1 or other.who != face.who): result.pairs.add (i, j)
        continue
      # Own trunk and own girdles share one group.
      if p.who == q.who and (p.arm < 0 or p.part == 0) and (q.arm < 0 or q.part == 0):
        continue
      # One arm's own links never meet; girdle meets them but not upper arm it holds.
      if p.arm >= 0 and p.arm == q.arm:
        if p.part != 0 and q.part != 0: continue
        if (p.part == 0 and q.part == 1) or (p.part == 1 and q.part == 0): continue
      # Joined hands are one joint apart.
      if p.part >= 3 and q.part >= 3 and (p.arm, q.arm) in joined: continue
      # Dancer's own arms cross below elbow alone: upper arm keeps off their other arm.
      if p.arm >= 0 and q.arm >= 0 and p.arm != q.arm and p.who == q.who and
          ((p.part == 1 and q.part in 1..2) or (q.part == 1 and p.part in 1..2)):
        result.crossing.add result.pairs.len
      result.pairs.add (i, j)


func ease(value, lower, upper, ease_lower, ease_upper: float): float =
  ## Squared fraction into either ease band: comfort's cost.
  var cost = 0.0
  if ease_upper > 0.0: cost += max(0.0, value - (upper - ease_upper)) / ease_upper
  if ease_lower > 0.0: cost += max(0.0, (lower + ease_lower) - value) / ease_lower
  cost * cost

func twistEnds(rig: Rig, i: int): (float, float) =
  ## Rig states right arm's ends; left arm's are mirrored.
  let twist_range = rig.range[Dof.Twist]
  if i mod 2 == 1: (twist_range.lower, twist_range.upper)
  else: (-twist_range.upper, -twist_range.lower)

func easeOf(rig: Rig, a: ArmPlaced, i: int): array[6, float] =
  ## Arm `i`'s squared way into each joint's ease, in order `comfort` sums them.
  let
    twist_range = rig.range[Dof.Twist]
    bend_range = rig.range[Dof.Bend]
    wrist_range = rig.range[Dof.Wrist]
    extend_range = rig.range[Dof.Extend]
    (fore, up) = (rig.collar[Collar.Fore], rig.collar[Collar.Up])
    (lower, upper) = twistEnds(rig, i)
  [ease(a.twist, lower, upper, twist_range.ease_lower, twist_range.ease_upper),
   ease(a.bend, bend_range.lower, bend_range.upper, 0.0, bend_range.ease_upper),
   ease(a.cone, 0.0, wrist_range.upper, 0.0, wrist_range.ease_upper),
   ease(a.extend, -PI, extend_range.upper, 0.0, extend_range.ease_upper),
   ease(a.protract, fore.lower, fore.upper, fore.ease_lower, fore.ease_upper),
   ease(a.elevate, up.lower, up.upper, up.ease_lower, up.ease_upper)]

func easesOf(rig: Rig, placed: Placed): array[4, array[6, float]] =
  ## Each arm's squared way into each joint's ease.
  for i in 0..3: result[i] = easeOf(rig, placed.arms[i], i)

func waistsOf(rig: Rig, plan: Plan): array[2, float] =
  ## Each waist's squared way into its ease.
  for k in 0..1:
    result[k] = ease(plan[2+k], rig.waist.lower, rig.waist.upper, rig.waist.ease_lower,
                     rig.waist.ease_upper)

func comfortOf(eases: array[4, array[6, float]], waists: array[2, float]): float =
  ## Sum of every joint's ease, arm by arm, then waists.
  for terms in eases:
    for term in terms: result += term
  for term in waists: result += term

func comfort*(rig: Rig, placed: Placed, plan: Plan): float =
  ## Sum of every joint's squared way into its ease, as `rigid.strainOf` reads them.
  comfortOf(easesOf(rig, placed), waistsOf(rig, plan))

func gapOf(p, q: Capsule): float = closest(p.a, p.z, q.a, q.z).gap - p.radius - q.radius
  ## How far apart two capsules' skins are: negative where they overlap.

func marginOf(rig: Rig, problem: Problem, a: ArmPlaced, i: int): array[3, float] =
  ## Arm `i`'s twist, cone and extend past margin inside their ends, squared.
  let (lower, upper) = twistEnds(rig, i)
  [max(0.0, lower + problem.style.margin - a.twist)^2 +
     max(0.0, a.twist - upper + problem.style.margin)^2,
   max(0.0, a.cone - rig.range[Dof.Wrist].upper + problem.style.margin)^2,
   max(0.0, a.extend - rig.range[Dof.Extend].upper + problem.style.margin)^2]

func marginsOf(rig: Rig, problem: Problem, placed: Placed): array[4, array[3, float]] =
  ## Each arm's twist, cone and extend past margin inside their ends, squared.
  for i in 0..3: result[i] = marginOf(rig, problem, placed.arms[i], i)

func leapsOf(problem: Problem; now, then: Capsule): array[2, float] =
  ## How far each end of one capsule moved past leap since last moment, squared.
  [max(0.0, distance(now.a, then.a) - problem.style.leap)^2,
   max(0.0, distance(now.z, then.z) - problem.style.leap)^2]

type Gaps = object
  ## Each pair's gap, as `problem.pairs` lists them, and which of them may add to any sum.
  ##   Pair whose bit is clear is past every threshold, so no sum adds it: sums run over
  ##     set bits alone, in pairs' own order, and come out same to last bit.
  values: seq[float]
  near: seq[uint64]  ## Bit `k` of word `k div 64` set where pair `k` may add.

func mark(gaps: var Gaps, k: int, threshold: float) =
  ## Set or clear pair `k`'s bit by its gap.
  let bit = 1'u64 shl (k mod 64)
  if gaps.values[k] < threshold: gaps.near[k div 64] = gaps.near[k div 64] or bit
  else: gaps.near[k div 64] = gaps.near[k div 64] and not bit

iterator nearOnes(gaps: Gaps): float =
  ## Gap of every pair that may add to any sum, in pairs' order.
  for word_index, word in gaps.near:
    var bits = word
    while bits != 0:
      yield gaps.values[64*word_index+countTrailingZeroBits(bits)]
      bits = bits and (bits - 1)

func crampedOf(problem: Problem, arms: array[4, ArmPlaced], gaps: Gaps): float =
  ## Sum of cramped's terms: pairs nearer than `ROOMY`, then joined hands near band's edge.
  for gap in gaps.nearOnes:
    if gap < ROOMY: result += (ROOMY - gap)^2
  for link in problem.links:
    for hand in link.ends:
      let z = arms[armIndex(hand.body, hand.arm)].carried.z
      result += max(0.0, problem.lower + ROOMY - z)^2 + max(0.0, z - problem.upper + ROOMY)^2

func onUpper(problem: Problem, arms: array[4, ArmPlaced], k: int): float =
  ## Weight of pair `k` meeting upper arm: nought within `ELBOW_END` of its elbow, where arms
  ## cross just before elbow, to one arm's radius further up.
  let
    (i, j) = problem.pairs[k]
    (p, q) = (problem.shapes[i], problem.shapes[j])
    first = arms[p.arm].capsules[p.part]
    second = arms[q.arm].capsules[q.part]
    met = closest(first.a, first.z, second.a, second.z)
  for (shape, capsule, along) in [(p, first, met.t), (q, second, met.u)]:
    if shape.part == 1:
      # Capsule stops its radius short of elbow (`placeArm`).
      let before = (1.0 - along) * distance(capsule.a, capsule.z) + capsule.radius
      result = max(result, clamp((before - ELBOW_END) / capsule.radius, 0.0, 1.0))

func gripBroken*(rig: Rig; a, b: ArmPlaced; margin: float): float =
  ## Square by which two joined hands turn against each other past what their grip lets.
  ##   Grip lets palms tilt off facing within its cone, and fingers turn off opposed within
  ##     its twist, both by how deep it holds (`rig.gripFreedom`); `margin` is kept inside
  ##     each.  Measured as cosines, so cost is smooth where hands are square.
  let (cone, twist) = gripFreedom(rig, max(a.depth, b.depth))
  if cone < PI:
    result += max(0.0, cos(max(0.0, cone - margin)) + dot(a.palm, b.palm))^2
  if twist < PI:
    result += max(0.0, cos(max(0.0, twist - margin)) + dot(a.fingers, b.fingers))^2

func violationOf(
  rig: Rig,
  problem: Problem,
  arms: array[4, ArmPlaced],
  gaps: Gaps,
  margins: array[4, array[3, float]],
  leaps: openArray[array[2, float]],
): float =
  ## Sum of violation's terms: joined hands apart, out of band and turned past their grip,
  ## pairs nearer than clearance, joints past margin, then each arm capsule's leap.
  for link in problem.links:
    let
      a = arms[armIndex(link.ends[0].body, link.ends[0].arm)].grip
      b = arms[armIndex(link.ends[1].body, link.ends[1].arm)].grip
      apart = distance(a, b)
    result += apart * apart
    for hand in link.ends:
      let z = arms[armIndex(hand.body, hand.arm)].carried.z
      result += max(0.0, problem.lower - z)^2 + max(0.0, z - problem.upper)^2
    result += gripBroken(
      rig,
      arms[armIndex(link.ends[0].body, link.ends[0].arm)],
      arms[armIndex(link.ends[1].body, link.ends[1].arm)],
      problem.style.margin,
    )
  for gap in gaps.nearOnes:
    if gap < problem.style.clearance: result += (problem.style.clearance - gap)^2
  for k in problem.crossing:
    if gaps.values[k] < CROSS_ROOM:
      result += onUpper(problem, arms, k) * (CROSS_ROOM - gaps.values[k])^2
  for who in 0..1:
    let
      (left, right) = (arms[2*who], arms[2*who+1])
      across = right.capsules[0].a - left.capsules[0].a
      apart = dot(right.elbow - left.elbow, across) / sqrt(dot(across, across))
    result += max(0.0, ELBOW_ROOM - apart)^2
  for terms in margins:
    for term in terms: result += term
  for ends in leaps:
    for term in ends: result += term

func gapsOf(problem: Problem, capsules: seq[Capsule]): Gaps =
  ## Every pair's gap, each one free to add.
  result.near = newSeq[uint64]((problem.pairs.len + 63) div 64)
  for k, (i, j) in problem.pairs:
    result.values.add gapOf(capsules[i], capsules[j])
    result.mark(k, Inf)

func leapsOf(problem: Problem; capsules, before: seq[Capsule]; first_arm: int):
    seq[array[2, float]] =
  ## Each arm capsule's leap terms since last moment, or none where there is no last moment.
  if before.len > 0:
    # Arms only: trunks and faces are carried by turn itself.
    for k in first_arm ..< first_arm + ARM_CAPSULES:
      result.add leapsOf(problem, capsules[k], before[k])

func cramped*(rig: Rig, problem: Problem, placed: Placed): float =
  ## How near this pose sits to what it must keep, inside its margins: capsules nearer
  ## than `ROOMY` and joined hands nearer band's edge than `ROOMY` cost by square.
  crampedOf(problem, placed.arms, gapsOf(problem, capsulesOf(placed)))

func violation*(rig: Rig, problem: Problem, placed: Placed, before: seq[Capsule]): float =
  ## Sum of squares by which this pose breaks what plan must keep.
  let capsules = capsulesOf(placed)
  violationOf(rig, problem, placed.arms, gapsOf(problem, capsules),
              marginsOf(rig, problem, placed),
              leapsOf(problem, capsules, before, 2 * trunkCapsules(rig).len))


type Bounds = array[SIZE, (float, float)]

func boundsOf(rig: Rig, margin: float, links: seq[Link]): Bounds =
  ## Each freedom's ends: collarbones, waists and elbow at engine's own, sideways held nought.
  ##   Held hand holds anywhere from palm to fingertips; free hand is open, whole hand long,
  ##     as engine builds it (`rigid.build`).
  let near = touching(rig) + 0.10
  result[0] = (near, near + 1.0)
  result[1] = (0.0, 0.0)
  result[2] = (rig.waist.lower, rig.waist.upper)
  result[3] = (rig.waist.lower, rig.waist.upper)
  for i in 0..3:
    let
      base = 4 + PER_ARM * i
      (fore, up) = (rig.collar[Collar.Fore], rig.collar[Collar.Up])
    result[base] = (fore.lower, fore.upper)
    result[base+1] = (up.lower, up.upper)
    for k in [2, 3, 4, 6, 7, 8]: result[base+k] = (-7.0, 7.0)
    result[base+5] = (rig.range[Dof.Bend].lower, rig.range[Dof.Bend].upper - margin)
    result[GRIPS+i] = (rig.hand, rig.hand)
  for link in links:
    for hand in link.ends:
      result[GRIPS+armIndex(hand.body, hand.arm)] = (gripAtPalm(rig), gripAtTips(rig))

func clamped(plan: Plan, bounds: Bounds): Plan =
  ## Hold every freedom of plan inside its bounds.
  for k in 0..<SIZE: result[k] = clamp(plan[k], bounds[k][0], bounds[k][1])



#[ Reckoning ]#

const FAR_SLOP = 1e-6
  ## Metres by which two capsules' balls must clear every threshold before their gap is
  ## left unreckoned: rounding of bound and of gap are some 1e-15 metre, so pair left out
  ## is one whose term no sum would add.

type
  Ball = tuple[centre: Vector, reach: float]  ## Ball holding one capsule whole.

  Reckoning = object
    ## One pose's cost term by term, so step of one freedom re-reckons only what it moves.
    ##   Each term is reckoned by what plain cost reckons it with, and every sum runs in
    ##     plain cost's order, so cost is same to last bit (`tests/test_plan.nim`).
    ##   Gap whose balls keep it past every threshold reads `Inf`: no sum adds it.
    placed: Placed
    capsules: seq[Capsule]  ## As `capsulesOf` lists them.
    balls: seq[Ball]  ## Each capsule's ball.
    gaps: Gaps
    first_arm: int  ## Place of first arm capsule in `capsules`.
    first_face: int  ## Place of first face in `capsules`, after every arm's.
    trunk: seq[Capsule]  ## One trunk's capsules in body's own frame (`rigid.trunkCapsules`).
    face: Capsule  ## One face in body's own frame (`rigid.faceCapsule`).
    eases: array[4, array[6, float]]
    waists: array[2, float]
    margins: array[4, array[3, float]]
    leaps: seq[array[2, float]]  ## Each arm capsule's, or none with no last moment.

func ballOf(capsule: Capsule): Ball =
  ## Ball holding capsule whole: its middle, and half its length and its radius.
  ((capsule.a + capsule.z) * 0.5, distance(capsule.a, capsule.z) * 0.5 + capsule.radius)

func gapOf(r: Reckoning; i, j: int; threshold: float): float =
  ## Gap between capsules `i` and `j`, or `Inf` where their balls alone keep them
  ## `threshold` apart: segment lies inside its ball, so gap is never less than balls'.
  ##   Balls are compared squared, both sides positive, and slop covers rounding.
  let
    (p, q) = (r.balls[i], r.balls[j])
    reach = p.reach + q.reach + threshold + FAR_SLOP
    (x, y, z) = (p.centre.x - q.centre.x, p.centre.y - q.centre.y, p.centre.z - q.centre.z)
  if x * x + y * y + z * z >= reach * reach: return Inf
  gapOf(r.capsules[i], r.capsules[j])

func thresholdOf(problem: Problem): float =
  ## Gap beyond which pair adds to no sum: clearance, and `ROOMY` where cramped is weighed.
  if problem.style.slack > 0.0: max(max(problem.style.clearance, ROOMY), CROSS_ROOM)
  else: max(problem.style.clearance, CROSS_ROOM)

proc reckon(
  r: var Reckoning, rig: Rig, problem: Problem, plan: Plan, wind: float, before: seq[Capsule]
) =
  ## Every term of pose at `plan`.
  r.placed = place(rig, plan, wind, problem.is_away, problem.turner)
  r.capsules = capsulesOf(r.placed)
  r.first_arm = 2 * r.placed.trunks[Body.One].len
  r.first_face = r.first_arm + ARM_CAPSULES
  if r.trunk.len == 0:
    for capsule in trunkCapsules(rig): r.trunk.add capsule
    let face = faceCapsule(rig)
    r.face = (face.a, face.z, face.radius)
  r.balls.setLen(r.capsules.len)
  for k, capsule in r.capsules: r.balls[k] = ballOf(capsule)
  let threshold = thresholdOf(problem)
  r.gaps.values.setLen(problem.pairs.len)
  r.gaps.near.setLen((problem.pairs.len + 63) div 64)
  for k, (i, j) in problem.pairs:
    r.gaps.values[k] = r.gapOf(i, j, threshold)
    r.gaps.mark(k, threshold)
  r.eases = easesOf(rig, r.placed)
  r.waists = waistsOf(rig, plan)
  r.margins = marginsOf(rig, problem, r.placed)
  r.leaps = leapsOf(problem, r.capsules, before, r.first_arm)

type Weighing = object
  ## What one stage of `solve` weighs every pose by, beyond pose itself.
  ##   Fields are open to `tests/test_plan.nim`, which weighs plain cost by them.
  problem*: Problem
  wind*: float
  before*: seq[Capsule]  ## Last moment's capsules, or none.
  last*, bias*: Plan
  weight*, holding*: float  ## On violation, and on staying near `last`.

func total(r: Reckoning, rig: Rig, weighing: Weighing, plan: Plan): float =
  ## Weigh pose: comfort, weighted violation, stay near last, bias, slack and gather.
  let problem = weighing.problem
  result = comfortOf(r.eases, r.waists) +
      weighing.weight * violationOf(rig, problem, r.placed.arms, r.gaps, r.margins, r.leaps)
  for k in 0..<SIZE:
    result += weighing.holding * (plan[k] - weighing.last[k])^2 + weighing.bias[k] * plan[k]
  if problem.style.slack > 0.0:
    result += problem.style.slack * crampedOf(problem, r.placed.arms, r.gaps)
  if problem.style.gather > 0.0 and problem.links.len == 2:
    let
      (one, two) = (problem.links[0].ends[0], problem.links[1].ends[0])
      first = r.placed.arms[armIndex(one.body, one.arm)].grip
      second = r.placed.arms[armIndex(two.body, two.arm)].grip
    result += problem.style.gather * distance(first, second)^2

func firstMoved(freedom: int): int =
  ## First link of its arm that arm freedom moves: collarbone moves girdle on, shoulder
  ## upper arm on, elbow forearm on, wrist and grip hand alone.
  if freedom >= GRIPS: 3 else: [0, 0, 1, 1, 1, 2, 3, 3, 3][(freedom-4) mod PER_ARM]

func armMoved(freedom: int): int =
  ## Arm that arm freedom belongs to: its own nine, or its hand's grip (`GRIPS`).
  if freedom >= GRIPS: freedom - GRIPS else: (freedom - 4) div PER_ARM

type Moving = object
  ## Pairs each step moves, listed once for every step of one solve.
  ##   Fields are open to `tests/test_plan.nim`, which steps each freedom by them.
  arms*: array[4, array[4, seq[int]]]  ## By arm, and first link its step moves.
  bodies*: array[Body, seq[int]]  ## By body whose frame moves.

func movedPairs(rig: Rig, problem: Problem): Moving =
  ## Pairs that each step moves: of arm `i` from link `f` on, and of every capsule of body.
  let
    trunk = trunkCapsules(rig).len
    first_arm = 2 * trunk
    first_face = first_arm + ARM_CAPSULES

  func isOf(k: int, who: Body): bool =
    ## Whether capsule `k` is one of body's own: its trunk, one of its two arms, or its face.
    k in ord(who) * trunk ..< (ord(who) + 1) * trunk or
        k in first_arm + 2 * PER_ARM_CAPSULES * ord(who) ..<
        first_arm + 2 * PER_ARM_CAPSULES * (ord(who) + 1) or k == first_face + ord(who)

  for k, (a, b) in problem.pairs:
    for i in 0..3:
      for f in 0..3:
        let moved = first_arm + PER_ARM_CAPSULES * i + f ..
            first_arm + PER_ARM_CAPSULES * (i + 1) - 1
        if a in moved or b in moved: result.arms[i][f].add k
    for who in Body:
      if a.isOf(who) or b.isOf(who): result.bodies[who].add k

type Held = object  ## What one arm's step re-reckoned away from, to put back.
  arm: ArmPlaced
  balls: array[PER_ARM_CAPSULES, Ball]
  ease: array[6, float]
  margin: array[3, float]
  leaps: array[PER_ARM_CAPSULES, array[2, float]]
  gaps: seq[float]  ## Gap of each moved pair, in order moved.
  near: seq[uint64]

proc stepArm(
  r: var Reckoning,
  held: var Held,
  rig: Rig,
  problem: Problem,
  plan: Plan,
  wind: float,
  freedom: int,
  moved: seq[int],
  before: seq[Capsule],
) =
  ## Re-reckon `r` for `plan`, which differs from pose it holds in one arm freedom alone,
  ## keeping in `held` what it held.
  ##   Every other arm, every trunk and each body's frame are untouched by arm freedom, so
  ##     each term reckoned again is reckoned from what plain cost reckons it from, and
  ##     every other term is as plain cost has it.
  let
    i = armMoved(freedom)
    first_arm = r.first_arm
    threshold = thresholdOf(problem)
  held.arm = r.placed.arms[i]
  held.ease = r.eases[i]
  held.margin = r.margins[i]
  r.placed.arms[i] = placeArm(
    rig,
    plan,
    i,
    frameOf(plan, Body(i div 2), wind, problem.is_away, problem.turner),
    firstMoved(freedom),
    held.arm,
  )
  for part in 0..<PER_ARM_CAPSULES:
    let k = first_arm + PER_ARM_CAPSULES * i + part
    held.balls[part] = r.balls[k]
    r.capsules[k] = r.placed.arms[i].capsules[part]
    r.balls[k] = ballOf(r.capsules[k])
    if r.leaps.len > 0:
      held.leaps[part] = r.leaps[k-first_arm]
      r.leaps[k-first_arm] = leapsOf(problem, r.capsules[k], before[k])
  held.near.setLen(r.gaps.near.len)
  for w in 0..<r.gaps.near.len: held.near[w] = r.gaps.near[w]
  held.gaps.setLen(moved.len)
  for n, k in moved:
    held.gaps[n] = r.gaps.values[k]
    let (a, b) = problem.pairs[k]
    r.gaps.values[k] = r.gapOf(a, b, threshold)
    r.gaps.mark(k, threshold)
  r.eases[i] = easeOf(rig, r.placed.arms[i], i)
  r.margins[i] = marginOf(rig, problem, r.placed.arms[i], i)

proc restore(r: var Reckoning, held: Held, freedom: int, moved: seq[int]) =
  ## Put back pose `stepArm` re-reckoned away from.
  let
    i = armMoved(freedom)
    first_arm = r.first_arm
  r.placed.arms[i] = held.arm
  for part in 0..<PER_ARM_CAPSULES:
    let k = first_arm + PER_ARM_CAPSULES * i + part
    r.capsules[k] = held.arm.capsules[part]
    r.balls[k] = held.balls[part]
    if r.leaps.len > 0: r.leaps[k-first_arm] = held.leaps[part]
  for n, k in moved: r.gaps.values[k] = held.gaps[n]
  for w in 0..<held.near.len: r.gaps.near[w] = held.near[w]
  r.eases[i] = held.ease
  r.margins[i] = held.margin


type HeldBody = object  ## What one body's step re-reckoned away from, to put back.
  arms: array[2, ArmPlaced]
  trunk: seq[Capsule]
  face: Capsule
  balls: seq[Ball]  ## Trunk's, then both arms', then face's.
  leaps: array[2*PER_ARM_CAPSULES, array[2, float]]
  waists: array[2, float]
  gaps: seq[float]  ## Gap of each moved pair, in order moved.
  near: seq[uint64]

func bodyMoving(freedom: int): Body =
  ## Body whose frame freedom moves: one's waist turns lead, apart and other waist follow.
  if freedom == 2: Body.One else: Body.Two

proc stepBody(
  r: var Reckoning,
  held: var HeldBody,
  rig: Rig,
  problem: Problem,
  plan: Plan,
  wind: float,
  freedom: int,
  moved: seq[int],
  before: seq[Capsule],
) =
  ## Re-reckon `r` for `plan`, which differs from pose it holds in one freedom of where
  ## body stands or which way it faces, keeping in `held` what it held.
  ##   Body's capsules move together, its arms' joints read same, and other body stands
  ##     where it stood: every capsule of body is carried into world again, and pairs it is
  ##     in reckoned again.
  let
    who = bodyMoving(freedom)
    frame = frameOf(plan, who, wind, problem.is_away, problem.turner)
    trunk = r.trunk.len
    threshold = thresholdOf(problem)
  held.trunk.setLen(trunk)
  held.balls.setLen(trunk + 2 * PER_ARM_CAPSULES + 1)
  for t in 0..<trunk:
    let k = ord(who) * trunk + t
    held.trunk[t] = r.capsules[k]
    held.balls[t] = r.balls[k]
    r.capsules[k] = (frame.world(r.trunk[t].a), frame.world(r.trunk[t].z), r.trunk[t].radius)
    r.placed.trunks[who][t] = r.capsules[k]
    r.balls[k] = ballOf(r.capsules[k])
  let face = r.first_face + ord(who)
  held.face = r.capsules[face]
  held.balls[trunk+2*PER_ARM_CAPSULES] = r.balls[face]
  r.capsules[face] = (frame.world(r.face.a), frame.world(r.face.z), r.face.radius)
  r.placed.faces[who] = r.capsules[face]
  r.balls[face] = ballOf(r.capsules[face])
  for side in 0..1:
    let i = 2 * ord(who) + side
    held.arms[side] = r.placed.arms[i]
    r.placed.arms[i] = placeArm(rig, plan, i, frame, 4, held.arms[side])
    for part in 0..<PER_ARM_CAPSULES:
      let k = r.first_arm + PER_ARM_CAPSULES * i + part
      held.balls[trunk+PER_ARM_CAPSULES*side+part] = r.balls[k]
      r.capsules[k] = r.placed.arms[i].capsules[part]
      r.balls[k] = ballOf(r.capsules[k])
      if r.leaps.len > 0:
        held.leaps[PER_ARM_CAPSULES*side+part] = r.leaps[k-r.first_arm]
        r.leaps[k-r.first_arm] = leapsOf(problem, r.capsules[k], before[k])
  held.waists = r.waists
  r.waists = waistsOf(rig, plan)
  held.near.setLen(r.gaps.near.len)
  for w in 0..<r.gaps.near.len: held.near[w] = r.gaps.near[w]
  held.gaps.setLen(moved.len)
  for n, k in moved:
    held.gaps[n] = r.gaps.values[k]
    let (a, b) = problem.pairs[k]
    r.gaps.values[k] = r.gapOf(a, b, threshold)
    r.gaps.mark(k, threshold)

proc restoreBody(r: var Reckoning, held: HeldBody, freedom: int, moved: seq[int]) =
  ## Put back pose `stepBody` re-reckoned away from.
  let
    who = bodyMoving(freedom)
    trunk = r.trunk.len
  for t in 0..<trunk:
    let k = ord(who) * trunk + t
    r.capsules[k] = held.trunk[t]
    r.placed.trunks[who][t] = held.trunk[t]
    r.balls[k] = held.balls[t]
  let face = r.first_face + ord(who)
  r.capsules[face] = held.face
  r.placed.faces[who] = held.face
  r.balls[face] = held.balls[trunk+2*PER_ARM_CAPSULES]
  for side in 0..1:
    let i = 2 * ord(who) + side
    r.placed.arms[i] = held.arms[side]
    for part in 0..<PER_ARM_CAPSULES:
      let k = r.first_arm + PER_ARM_CAPSULES * i + part
      r.capsules[k] = held.arms[side].capsules[part]
      r.balls[k] = held.balls[trunk+PER_ARM_CAPSULES*side+part]
      if r.leaps.len > 0: r.leaps[k-r.first_arm] = held.leaps[PER_ARM_CAPSULES*side+part]
  r.waists = held.waists
  for n, k in moved: r.gaps.values[k] = held.gaps[n]
  for w in 0..<held.near.len: r.gaps.near[w] = held.near[w]


proc weigh(r: var Reckoning, rig: Rig, weighing: Weighing, plan: Plan): float =
  ## Cost of pose at `plan`, every term reckoned afresh into `r`.
  r.reckon(rig, weighing.problem, plan, weighing.wind, weighing.before)
  r.total(rig, weighing, plan)

proc stepped(
  here: var Reckoning,
  held: var Held,
  held_body: var HeldBody,
  rig: Rig,
  weighing: Weighing,
  plan: Plan,
  bounds: Bounds,
  moving: Moving,
): Plan =
  ## Cost of pose one forward step along each free freedom from `plan`, which `here` holds;
  ## nought for freedom held.  Each step re-reckons what it moves in `here`, and puts it
  ## back: arm freedom its arm from link it moves, body's freedom every capsule of body.
  for k in 0..<SIZE:
    if bounds[k][0] == bounds[k][1]: continue
    var z = plan
    z[k] += 1e-7
    if k < 4:
      let moved = moving.bodies[bodyMoving(k)]
      here.stepBody(held_body, rig, weighing.problem, z, weighing.wind, k, moved, weighing.before)
      result[k] = here.total(rig, weighing, z)
      here.restoreBody(held_body, k, moved)
      continue
    let moved = moving.arms[armMoved(k)][firstMoved(k)]
    here.stepArm(held, rig, weighing.problem, z, weighing.wind, k, moved, weighing.before)
    result[k] = here.total(rig, weighing, z)
    here.restore(held, k, moved)


type Solved* = object  ## One moment planned.
  plan*: Plan
  broken*: float  ## Violation left: nought kept everything.
  cost*: float  ## Comfort there.

proc solve*(
  rig: Rig;
  problem: Problem;
  start, last: Plan;
  wind: float;
  before: seq[Capsule];
  stay = -1.0;
  iterations = 200;
  bias = default(Plan);
): Solved =
  ## Comfiest pose near `last`, by penalty on what must be kept, on growing weight.
  ##   Limited-memory quasi-Newton on numerical gradient, bounds by clamping.
  let
    bounds = boundsOf(rig, problem.style.margin, problem.links)
    holding = (if stay >= 0.0: stay else: problem.style.stay)
  var x = clamped(start, bounds)
  let moving = movedPairs(rig, problem)
  var
    here, there: Reckoning  ## Pose at `x`, and pose last weighed.
    held: Held
    held_body: HeldBody
  for stage in 0..2:
    let weighing = Weighing(problem: problem, wind: wind, before: before, last: last,
                            bias: bias, weight: [1e3, 1e5, 1e7][stage], holding: holding)
    proc cost(r: var Reckoning, y: Plan): float = r.weigh(rig, weighing, y)
      ## Weigh pose `y`, every term reckoned afresh into `r`.
    proc gradient(y: Plan, at: float): Plan =
      ## Read gradient of cost by forward difference, `at` being cost at `y`, which `here`
      ## holds.
      let costs = stepped(here, held, held_body, rig, weighing, y, bounds, moving)
      for k in 0..<SIZE:
        if bounds[k][0] == bounds[k][1]: continue
        result[k] = (costs[k] - at) / 1e-7
    const memory = 8
    var
      steps: seq[Plan]
      changes: seq[Plan]
      cost_x = cost(here, x)
      g = gradient(x, cost_x)
    for iteration in 0..<iterations:
      # Two-loop recursion for search direction: `curvature_pair` is sᵀy of one stored pair,
      # `projection_step` sᵀq, `projection_change` yᵀq and `square_change` yᵀy.
      var
        q = g
        alphas = newSeq[float](steps.len)
      for m in countdown(steps.len - 1, 0):
        var curvature_pair, projection_step = 0.0
        for k in 0..<SIZE:
          curvature_pair += steps[m][k] * changes[m][k]
          projection_step += steps[m][k] * q[k]
        alphas[m] = projection_step / curvature_pair
        for k in 0..<SIZE: q[k] -= alphas[m] * changes[m][k]
      if steps.len > 0:
        var curvature_pair, square_change = 0.0
        for k in 0..<SIZE:
          curvature_pair += steps[^1][k] * changes[^1][k]
          square_change += changes[^1][k] * changes[^1][k]
        for k in 0..<SIZE: q[k] *= curvature_pair / square_change
      for m in 0..<steps.len:
        var projection_change, curvature_pair = 0.0
        for k in 0..<SIZE:
          projection_change += changes[m][k] * q[k]
          curvature_pair += steps[m][k] * changes[m][k]
        let beta = projection_change / curvature_pair
        for k in 0..<SIZE: q[k] += steps[m][k] * (alphas[m] - beta)
      var slope = 0.0
      for k in 0..<SIZE: slope -= g[k] * q[k]
      if slope >= 0.0:
        # Not descent: forget history, fall back to steepest descent.
        steps.setLen 0
        changes.setLen 0
        q = g
        slope = 0.0
        for k in 0..<SIZE: slope -= g[k] * g[k]
      # Backtracking line search.
      var
        length = (if steps.len == 0: min(1.0, 0.1 / max(1e-12, sqrt(-slope))) else: 1.0)
        is_accepted = false
        y: Plan
        cost_y: float
      for tries in 0..<30:
        for k in 0..<SIZE: y[k] = x[k] - length * q[k]
        y = clamped(y, bounds)
        cost_y = cost(there, y)
        if cost_y <= cost_x + 1e-4 * length * slope:
          is_accepted = true
          break
        length *= 0.5
      if not is_accepted: break
      swap(here, there)
      let gradient_y = gradient(y, cost_y)
      var
        step, change: Plan
        curvature = 0.0
      for k in 0..<SIZE:
        step[k] = y[k] - x[k]
        change[k] = gradient_y[k] - g[k]
        curvature += step[k] * change[k]
      if curvature > 1e-12:
        steps.add step
        changes.add change
        if steps.len > memory:
          steps.delete 0
          changes.delete 0
      let improvement = cost_x - cost_y
      x = y
      cost_x = cost_y
      g = gradient_y
      if improvement < 1e-12 * max(1.0, abs(cost_x)): break
  result.plan = x
  let placed = place(rig, x, wind, problem.is_away, problem.turner)
  result.broken = violation(rig, problem, placed, before)
  result.cost = comfort(rig, placed, x)



#[ Path ]#

const
  KEPT* = 1e-6  ## Violation under which plan counts as keeping everything: millimetre squared.
  STRIDE* = 0.02  ## Turns between two moments of plan, as walk's own step.

type Path* = object  ## Planned turn: one pose per moment, and how far it got.
  winds*: seq[float]
  plans*: seq[Plan]
  is_reached*: bool
  problem*: Problem  ## What was planned, so moment can be planned again from engine's pose.
  direction*: float

func awayOf(wind: float, is_away: bool): float =
  ## How far couple are from face to face, turns, nought to half.
  let turned = floorMod(wind + (if is_away: 0.5 else: 0.0), 1.0)
  min(turned, 1.0 - turned)

func bandAt*(rig: Rig; wind, direction: float; is_away: bool; room: float):
    tuple[lower, upper: float] =
  ## Band plan holds joined hands to: judge's own where judge reads it, with margin, and
  ## continuous between, as carry lets hands down and lifts them.
  ##   Facing (`rigid.FACING` of way up): torso band and its slack.  Risen going up, from
  ##     quarter turn away: crown band less its sag.  Coming back, crown band to half way.
  let
    torso = rig.band[Band.Torso]
    crown = rig.band[Band.Crown]
    low_torso = torso.lower - 0.03 + room
    high_torso = torso.upper + 0.05 - room
    low_crown = crown.lower - 0.03 + room
    high_crown = crown.upper - room
    up = min(1.0, awayOf(wind, is_away) / 0.25)
    turned = floorMod(wind + (if is_away: 0.5 else: 0.0), 1.0)
    is_leaving = abs(wind) < 1e-9 or ((turned < 0.5) == (direction > 0.0))
  const window = FACE_WINDOW
  if up <= window: return (low_torso, high_torso)
  if is_leaving:
    (low_torso + (low_crown - low_torso) * clamp((up - window) / (1.0 - window), 0.0, 1.0),
     high_torso + (high_crown - high_torso) * clamp((up - window) / 0.2, 0.0, 1.0))
  else:
    (low_torso + (low_crown - low_torso) * clamp((up - window) / (0.5 - window), 0.0, 1.0),
     high_torso + (high_crown - high_torso) * clamp((up - window) / (0.5 - window), 0.0, 1.0))

func spread(x: float): float = x - floor(x)
  ## Fractional part: deterministic scatter for starts and nudges.

func hanging*(apart: float): Plan =
  ## Every arm hanging, elbow soft, couple `apart` metres axis to axis.
  result[0] = apart
  for i in 0..3: result[4+PER_ARM*i+5] = 30.0 * PI / 180.0

proc restOf*(rig: Rig, problem: var Problem, tries = 8): tuple[plan: Plan, broken: float] =
  ## Comfiest rest pose found from several starts: couple stand where rest sits easiest.
  ##   Starts are fixed, so plan is same on every build and every core.
  let (lower, upper) = bandAt(rig, 0.0, 1.0, problem.is_away, problem.style.room)
  problem.lower = lower
  problem.upper = upper
  result.broken = Inf
  var best = Inf
  for k in 0..<tries:
    var start = hanging(0.45 + 0.06 * float((k + problem.style.seed) mod tries))
    # Deterministic spread of starting arms, by golden ratio.
    for j in 4..<GRIPS:
      start[j] += 0.4 *
          (spread(float(j * (k + 1 + 17 * problem.style.seed)) * 0.6180339887) - 0.5) *
          float(min(k + problem.style.seed, 1))
    let solved = solve(rig, problem, start, start, 0.0, @[], stay = 0.0, iterations = 400)
    if solved.broken < KEPT and solved.cost < best:
      best = solved.cost
      result = (solved.plan, solved.broken)

proc planPath*(
  rig: Rig, links: seq[Link], is_away: bool, turns: float, style: Style, turner = Body.Two
): Path =
  ## Plan couple from rest to `turns` of wind, `turner` turning, moment by moment, as far as
  ## plan keeps everything.  Stuck, it backs off, nudges arms at standing wind and tries
  ## again.
  var problem = problemOf(rig, links, is_away, turner)
  problem.style = style
  let rest = restOf(rig, problem)
  if rest.broken >= KEPT: return
  let direction = (if turns >= 0.0: 1.0 else: -1.0)
  result.problem = problem
  result.direction = direction
  result.winds = @[0.0]
  result.plans = @[rest.plan]
  var
    stride = STRIDE
    failures = 0
    bias: Plan
    biased = 0
  while abs(result.winds[^1]) < abs(turns) - 1e-9:
    if biased > 0:
      dec biased
      if biased == 0: bias = default(Plan)
    let
      wind = result.winds[^1]
      last = result.plans[^1]
      target = wind + direction * min(stride, abs(turns) - abs(wind))
      (lower, upper) = bandAt(rig, target, direction, is_away, style.room)
    problem.lower = lower
    problem.upper = upper
    let
      before = capsulesOf(place(rig, last, wind, is_away, turner))
      solved = solve(rig, problem, last, last, target, before, bias = bias)
    if solved.broken < KEPT:
      result.winds.add target
      result.plans.add solved.plan
      stride = min(STRIDE, stride * 2.0)
      continue
    if stride > STRIDE / 16.0:
      stride /= 2.0
      continue
    inc failures
    if failures > 24: return
    # Every third time stuck, go back to last moment couple faced and rearrange arms there
    # at standing wind, many leaps, before going on: way down into facing decides way up.
    if failures mod 3 == 0:
      var facing_at = -1
      for k in countdown(result.winds.len - 1, 0):
        if min(1.0, awayOf(result.winds[k], is_away) / 0.25) <= FACE_WINDOW:
          facing_at = k
          break
      if facing_at > 0:
        result.winds.setLen(facing_at + 1)
        result.plans.setLen(facing_at + 1)
        let
          at = result.winds[^1]
          (lower_at, upper_at) = bandAt(rig, at, direction, is_away, style.room)
        problem.lower = lower_at
        problem.upper = upper_at
        for walk in 0..<12:
          var start = result.plans[^1]
          for j in 4..<GRIPS:
            start[j] += 0.3 * (spread(float(j * (walk + 5) + 31 * failures +
                                            17 * problem.style.seed) * 0.6180339887) - 0.5) * 2.0
          let
            here = capsulesOf(place(rig, result.plans[^1], at, is_away, turner))
            moved = solve(rig, problem, start, result.plans[^1], at, here, stay = 0.0)
          if moved.broken < KEPT:
            result.winds.add at
            result.plans.add moved.plan
        stride = STRIDE
        continue
    # Back off, and nudge arms at that wind within one leap.
    let back = min(result.winds.len - 1, 2 * failures)
    result.winds.setLen(result.winds.len - back)
    result.plans.setLen(result.plans.len - back)
    let
      at = result.winds[^1]
      (lower_at, upper_at) = bandAt(rig, at, direction, is_away, style.room)
    problem.lower = lower_at
    problem.upper = upper_at
    for nudge in 0..<4:
      var start = result.plans[^1]
      for j in 4..<GRIPS:
        start[j] += 0.1 * sqrt(float(failures)) *
            (spread(float(j * (nudge + 7 * failures)) * 0.7548776662) - 0.5) * 2.0
      let
        here = capsulesOf(place(rig, result.plans[^1], at, is_away, turner))
        nudged = solve(rig, problem, start, result.plans[^1], at, here, stay = 0.02)
      if nudged.broken < KEPT:
        result.winds.add at
        result.plans.add nudged.plan
    for j in 4..<GRIPS:
      bias[j] = 0.02 * float(failures) *
                (spread(float(j * (3 + 11 * failures + 13 * problem.style.seed)) *
                        0.5698402910) - 0.5) * 2.0
    biased = 15
    stride = STRIDE
  result.is_reached = true


proc corrected*(rig: Rig, path: Path, i: int, now: Plan): Plan =
  ## Moment `i` of path planned again from pose engine actually holds: nearest pose to
  ## plan's that keeps everything, one leap from where couple are, or plan's own where
  ## none is found.
  ##   Planned again from engine's own pose, so engine's drift from plan is answered at
  ##     each moment rather than carried to next.
  var problem = path.problem
  let
    wind = path.winds[i]
    (lower, upper) = bandAt(rig, wind, path.direction, problem.is_away, problem.style.room)
  problem.lower = lower
  problem.upper = upper
  let
    before = capsulesOf(place(rig, now, path.winds[max(0, i-1)], problem.is_away, problem.turner))
    solved = solve(rig, problem, now, path.plans[i], wind, before)
  if solved.broken < KEPT: solved.plan else: path.plans[i]



#[ Mirror ]#

func mirrored*(plan: Plan): Plan =
  ## Same pose seen in mirror across couple's line: each dancer's left arm is their right.
  ##   Reflection `M` flips body's right.  Collarbone's two angles are unchanged by it,
  ##     elbow too, and turn `R(v)` becomes `M R M = R(-M v)`, so shoulder's and wrist's
  ##     vectors keep x and change sign in y and z.  Waists turn other way.
  result[0] = plan[0]
  result[1] = -plan[1]
  result[2] = -plan[2]
  result[3] = -plan[3]
  for i in 0..3:
    let
      from_base = 4 + PER_ARM * i
      to_base = 4 + PER_ARM * (i xor 1)
    result[to_base] = plan[from_base]
    result[to_base+1] = plan[from_base+1]
    result[to_base+2] = plan[from_base+2]
    result[to_base+3] = -plan[from_base+3]
    result[to_base+4] = -plan[from_base+4]
    result[to_base+5] = plan[from_base+5]
    result[to_base+6] = plan[from_base+6]
    result[to_base+7] = -plan[from_base+7]
    result[to_base+8] = -plan[from_base+8]
    result[GRIPS+(i xor 1)] = plan[GRIPS+i]

func mirrored*(link: Link): Link =
  ## One connection seen in mirror: each hand on other arm.
  for k in 0..1:
    result.ends[k] = (link.ends[k].body,
                      (if link.ends[k].arm == Arm.Left: Arm.Right else: Arm.Left))

func isMirrorSame*(links: seq[Link]): bool =
  ## Whether hold seen in mirror is same hold: true of both two-hand holds, not single ones.
  for link in links:
    let image = mirrored(link)
    var is_found = false
    for other in links:
      if (other.ends[0] == image.ends[0] and other.ends[1] == image.ends[1]) or
          (other.ends[0] == image.ends[1] and other.ends[1] == image.ends[0]):
        is_found = true
    if not is_found: return false
  true

func mirrored*(path: Path): Path =
  ## Planned turn seen in mirror: same couple winding other way.
  result = path
  result.direction = -path.direction
  for i in 0..<path.winds.len:
    result.winds[i] = -path.winds[i]
    result.plans[i] = mirrored(path.plans[i])


func placings*(rig: Rig, plan: Plan, wind: float, is_away: bool, turner = Body.Two):
    tuple[chests: array[Body, Stance], arms: array[4, ArmPlacing]] =
  ## Where every body of couple stands at this plan, as engine places bodies: what
  ## `rigid.placeBodies` is handed so couple start where plan starts.
  let neck = halfBreadth(rig, Part.Neck)
  const trunk_axes: Matrix = [[1.0, 0.0, 0.0], [0.0, 0.0, -1.0], [0.0, 1.0, 0.0]]
    ## Trunk's and girdle's own axes in body's terms: right, up, back (`rigid.standing`).
  for who in Body:
    let
      facing = facingOf(plan, who, wind, is_away, turner)
      origin: Vector = (if who == Body.One: (0.0, 0.0, 0.0) else: (plan[1], plan[0], 0.0))
      right: Vector = (sin(facing), -cos(facing), 0.0)
      fore: Vector = (cos(facing), sin(facing), 0.0)
      world: Matrix = [[right.x, fore.x, 0.0], [right.y, fore.y, 0.0], [0.0, 0.0, 1.0]]
    result.chests[who] = Stance(centre: (origin.x, origin.y), facing: facing)
    func toWorld(p: Vector): Vector = origin + right * p.x + fore * p.y + (0.0, 0.0, p.z)
      ## Carry point from body's own frame into world.
    for arm in Arm:
      let
        i = armIndex(who, arm)
        base = 4 + PER_ARM * i
        handedness = side(arm)
        root: Vector = (handedness * neck, 0.0, rig.top[Part.Torso])
        reach: Vector = (
          handedness * (rig.shoulder_out - neck),
          0.0,
          rig.shoulder_up - rig.top[Part.Torso],
        )
        collar = aboutUp(handedness * plan[base])
        girdle = times(collar, aboutFore(-handedness * plan[base+1]))
        shoulder = root + apply(girdle, reach)
        upper = times(
          girdle,
          times(turnAbout([plan[base+2], plan[base+3], plan[base+4]]), MATRIX_REST),
        )
        elbow = shoulder + column(upper, 2) * rig.upper
        forearm = times(upper, aboutRight(plan[base+5]))
        wrist = elbow + column(forearm, 2) * rig.fore
        hand = times(forearm, wristTurn(plan, i))
      result.arms[i] = ArmPlacing(
        root: root.toWorld,
        shoulder: shoulder.toWorld,
        elbow: elbow.toWorld,
        wrist: wrist.toWorld,
        collar: times(world, times(collar, trunk_axes)),
        girdle: times(world, times(girdle, trunk_axes)),
        upper: times(world, upper),
        fore: times(world, forearm),
        palm: times(world, hand),
        depth: plan[GRIPS+i],
      )
