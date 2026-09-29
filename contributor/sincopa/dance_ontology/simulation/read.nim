## What pose says about itself, still in body's own words.
##
##   Where held arm lies on its own body -- across front or behind
##     back, at chest or neck, pressing or merely carried there --
##     and where two connections cross in plan and which is higher.
##     Dance's words for these are put on outside simulation.
##   Read off poses alone.  Solver this once read from is gone; what
##     answers now is `rigid`, and it hands over same four points per
##     arm, so nothing here needed to know which answered.

{.experimental: "strictFuncs".}

import std/[math, options]

import ./[body, contact, hold, limb, rig, vector]


type
  Aspect* {.pure.} = enum ## Which face of its own body hand is carried to.
    Fore, ## Across front: past midline, on other arm's side.
    Aft   ## Behind back.

  Lying* = object ## Where one held arm lies on its own body.
    aspect*: Aspect
    band*: Band
    is_pressing*: bool   ## Forearm or hand on torso or neck.
    is_elbow_fore*: bool  ## Elbow in front of body: arm folded forward.

  Crossing* = object ## Where two connections cross in plan.
    at*: Vector
    along*: float ## How far along first connection, nought to six.
    across*: float ## Same along second, which says whether crossing sits
                   ## where it can slide off that one's end.
    over*: int ## Which connection is higher there, 0 or 1.
    sense*: int ## +1 where second crosses first left to right
                ## looking along it, else -1.

  Arms* = seq[array[2, ArmPose]] ## Every connection's two arms, as `walk.Moment`
                                 ## and `rigid.Pose` both hand them over.

  Tight* = object ## Joint nearest its edge across every held arm.
    room*: float ## `margin` of that joint: nought at edge, one ease in, negative past.
    dof*: Dof
    whose*: Hand


func armOf*(links: seq[Link]; i: int; who: Body): int =
  ## Which end of connection `i` is `who`'s.
  if links[i].ends[0].body == who: 0 else: 1


func lyingOn*(rig: Rig; band: Band; links: seq[Link]; stance: array[Body, Stance];
              arms: Arms; i: int; who: Body): Option[Lying] =
  ## Where `who`'s arm in connection `i` lies on `who`'s own body; none where
  ## it is out in front, or carried over crown.
  if band == Band.Crown:
    return none(Lying)
  let
    end_index = armOf(links, i, who)
    hand = links[i].ends[end_index]
    pose = arms[i][end_index]
    stance = stance[who]
    axes = axesOf(stance)
    grip = toBody(axes, pose.grip)
    elbow = toBody(axes, pose.elbow)
    own_side = side(hand.arm)
  var aspect: Aspect
  if grip.y < -0.01:
    aspect = Aspect.Aft
  elif grip.x * own_side < -0.01 and grip.y < halfDepth(rig, Part.Torso) + 4.0 * rig.limb:
    aspect = Aspect.Fore
  else:
    return none(Lying)
  some(Lying(
    aspect: aspect,
    band: band,
    is_pressing: isPressingBody(rig, stance, (pose.elbow, pose.wrist, pose.grip)),
    is_elbow_fore: elbow.y > 0.0,
  ))


func polyline*(arms: Arms; i: int): array[7, Vector] =
  ## One connection as seven points: shoulder to shoulder through grip.
  let
    arm_a = arms[i][0]
    arm_b = arms[i][1]
  [arm_a.shoulder, arm_a.elbow, arm_a.wrist, arm_a.grip, arm_b.wrist, arm_b.elbow, arm_b.shoulder]


const ON_LINE = 1e-9
  ## Metres within which point counts as lying on segment's line in plan: below
  ## anything pose carries, above float noise, so answer is same for two poses
  ## that differ by less than float carries.

func sideOf(a, b, p: Vector): int =
  ## Which side of line through `a` and `b` point `p` lies on in plan: one either
  ## way, nought within `ON_LINE`, nought for segment too short to have line.
  let
    delta_x = b.x - a.x
    delta_y = b.y - a.y
    run = sqrt(delta_x * delta_x + delta_y * delta_y)
  if run < 1e-18:
    return 0
  let offset = (delta_x * (p.y - a.y) - delta_y * (p.x - a.x)) / run
  if offset > ON_LINE: 1 elif offset < -ON_LINE: -1 else: 0

func lifted(side: int): int =
  ## Point on line counts as on its positive side.  One rule for every tie, so
  ## vertex two segments share is counted for exactly one of them, and arm lying
  ## along other crosses it once where it leaves to far side and never inside
  ## overlap.  Simulation of simplicity, with tie set by `ON_LINE` rather than
  ## by whichever way last bit fell.
  if side == 0: 1 else: side

func crossings*(arms: Arms): seq[Crossing] =
  ## Where two connections cross in plan, and which is over at each.
  ##   Two segments cross where each has other's ends on opposite sides of its
  ##     line, sides read with ties lifted.  Read as parametric intersection
  ##     alone, crossing at vertex of both polylines was counted four times and
  ##     once under any jitter, and arm laid along other read nought, one or two.
  if arms.len < 2:
    return
  let
    first = polyline(arms, 0)
    second = polyline(arms, 1)
  for i in 0 ..< 6:
    for j in 0 ..< 6:
      let
        a = first[i]
        b = first[i + 1]
        c = second[j]
        d = second[j + 1]
      if lifted(sideOf(a, b, c)) == lifted(sideOf(a, b, d)):
        continue
      if lifted(sideOf(c, d, a)) == lifted(sideOf(c, d, b)):
        continue
      let denominator = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
      var t, u: float
      if abs(denominator) < 1e-18:
        # Sides differ only by tie: segments run along one another and one end
        # sits on other's line.  Crossing is that end.
        if sideOf(a, b, c) == 0: u = 0.0 else: u = 1.0
        let
          end_point = (if u == 0.0: c else: d)
          delta_x = b.x - a.x
          delta_y = b.y - a.y
          run = delta_x * delta_x + delta_y * delta_y
        t = (if run < 1e-18: 0.0
             else: clamp(
               ((end_point.x - a.x) * delta_x + (end_point.y - a.y) * delta_y) / run,
               0.0,
               1.0,
             ))
      else:
        t = clamp(((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denominator, 0.0, 1.0)
        u = clamp(((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denominator, 0.0, 1.0)
      let
        first_z = a.z + (b.z - a.z) * t
        second_z = c.z + (d.z - c.z) * u
      result.add Crossing(
        at: (a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, first_z),
        along: float(i) + t,
        across: float(j) + u,
        over: (if first_z >= second_z: 0 else: 1),
        sense: (if denominator > 0.0: 1 else: -1),
      )


func tightest*(rig: Rig; stance: array[Body, Stance]; links: seq[Link];
               arms: Arms): Tight =
  ## Which joint of which held arm is nearest its edge, and how near.
  ##   Read off pose by `joints`, so it says same thing whichever model posed it.
  ##   Twist's ends are mirrored for left arm, as `rigid.twistEnds` has them.
  result = Tight(room: Inf)
  for i in 0 ..< links.len:
    for k in 0 .. 1:
      let
        hand = links[i].ends[k]
        arm_joints = joints(stance[hand.body], hand.arm, arms[i][k])
        twist_range = rig.range[Dof.Twist]
        twist = (if hand.arm == Arm.Right: twist_range
                 else: Range(
                   lower: -twist_range.upper,
                   upper: -twist_range.lower,
                   ease_lower: twist_range.ease_upper,
                   ease_upper: twist_range.ease_lower,
                 ))
      for (dof, joint_range, value) in [(Dof.Extend, rig.range[Dof.Extend], arm_joints.extend),
                          (Dof.Across, rig.range[Dof.Across], arm_joints.across),
                          (Dof.Twist, twist, arm_joints.twist),
                          (Dof.Bend, rig.range[Dof.Bend], arm_joints.bend),
                          (Dof.Wrist, rig.range[Dof.Wrist], arm_joints.wrist)]:
        let joint_margin = margin(joint_range, value)
        if joint_margin < result.room:
          result = Tight(room: joint_margin, dof: dof, whose: hand)

func strain*(tight: Tight): float =
  ## How far into last stretch before edge tightest joint is: one is edge.
  clamp(1.0 - tight.room, 0.0, 1.0)
