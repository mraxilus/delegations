## What pose says about itself, still in body's own words.
##
##   Where held arm lies on its own body -- across front or behind
##     back, at chest or neck, pressing or merely carried there --
##     and where two connections cross in plan and which is higher.
##     Dance's words for these are put on outside sim.
##   Read off poses alone.  Solver this once read from is gone; what
##     answers now is `rigid`, and it hands over same four points per
##     arm, so nothing here needed to know which answered.

{.experimental: "strictFuncs".}

import std/[math, options]

import ./[body, contact, hold, limb, rig, vec]


type
  Aspect* {.pure.} = enum ## Which face of its own body hand is carried to.
    Fore, ## Across front: past midline, on other arm's side.
    Aft   ## Behind back.

  Lying* = object ## Where one held arm lies on its own body.
    aspect*: Aspect
    band*: Band
    pressing*: bool   ## Forearm or hand on torso or neck.
    elbowFore*: bool  ## Elbow in front of body: arm folded forward.

  Crossing* = object ## Where two connections cross in plan.
    at*: Vec
    along*: float ## How far along first connection, nought to six.
    across*: float ## Same along second, which says whether crossing sits
                   ## where it can slide off that one's end.
    over*: int ## Which connection is higher there, 0 or 1.
    sense*: int ## +1 where second crosses first left to right
                ## looking along it, else -1.

  Arms* = seq[array[2, ArmPose]] ## Every connection's two arms, as `walk.Moment`
                                 ## and `rigid.Pose` both hand them over.


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
    k = armOf(links, i, who)
    hand = links[i].ends[k]
    pose = arms[i][k]
    st = stance[who]
    ax = axesOf(st)
    g = toBody(ax, pose.g)
    e = toBody(ax, pose.e)
    ownSide = side(hand.arm)
  var aspect: Aspect
  if g.y < -0.01:
    aspect = Aspect.Aft
  elif g.x * ownSide < -0.01 and g.y < halfDepth(rig, Part.Torso) + 4.0 * rig.limb:
    aspect = Aspect.Fore
  else:
    return none(Lying)
  some(Lying(aspect: aspect, band: band,
             pressing: pressing(rig, st, (pose.e, pose.w, pose.g)),
             elbowFore: e.y > 0.0))


func polyline*(arms: Arms; i: int): array[7, Vec] =
  ## One connection as seven points: shoulder to shoulder through grip.
  let
    a = arms[i][0]
    b = arms[i][1]
  [a.s, a.e, a.w, a.g, b.w, b.e, b.s]


const ON_LINE = 1e-9
  ## Metres within which point counts as lying on segment's line in plan: below
  ## anything pose carries, above float noise, so answer is same for two poses
  ## that differ by less than float carries.

func sideOf(a, b, p: Vec): int =
  ## Which side of line through `a` and `b` point `p` lies on in plan: one either
  ## way, nought within `ON_LINE`, nought for segment too short to have line.
  let
    dx = b.x - a.x
    dy = b.y - a.y
    run = sqrt(dx * dx + dy * dy)
  if run < 1e-18:
    return 0
  let off = (dx * (p.y - a.y) - dy * (p.x - a.x)) / run
  if off > ON_LINE: 1 elif off < -ON_LINE: -1 else: 0

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
    p = polyline(arms, 0)
    q = polyline(arms, 1)
  for i in 0 ..< 6:
    for j in 0 ..< 6:
      let
        a = p[i]
        b = p[i + 1]
        c = q[j]
        d = q[j + 1]
      if lifted(sideOf(a, b, c)) == lifted(sideOf(a, b, d)):
        continue
      if lifted(sideOf(c, d, a)) == lifted(sideOf(c, d, b)):
        continue
      let den = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
      var t, u: float
      if abs(den) < 1e-18:
        # Sides differ only by tie: segments run along one another and one end
        # sits on other's line.  Crossing is that end.
        if sideOf(a, b, c) == 0: u = 0.0 else: u = 1.0
        let
          e = (if u == 0.0: c else: d)
          dx = b.x - a.x
          dy = b.y - a.y
          run = dx * dx + dy * dy
        t = (if run < 1e-18: 0.0
             else: clamp(((e.x - a.x) * dx + (e.y - a.y) * dy) / run, 0.0, 1.0))
      else:
        t = clamp(((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / den, 0.0, 1.0)
        u = clamp(((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / den, 0.0, 1.0)
      let
        zp = a.z + (b.z - a.z) * t
        zq = c.z + (d.z - c.z) * u
      result.add Crossing(at: (a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, zp),
                          along: i.float + t, across: j.float + u,
                          over: (if zp >= zq: 0 else: 1),
                          sense: (if den > 0.0: 1 else: -1))


type Tight* = object ## Joint nearest its edge across every held arm.
  room*: float ## `margin` of that joint: nought at edge, one ease in, negative past.
  dof*: Dof
  whose*: Hand

func tightest*(rig: Rig; stance: array[Body, Stance]; links: seq[Link];
               arms: Arms): Tight =
  ## Which joint of which held arm is nearest its edge, and how near.
  ##   Read off pose by `joints`, so it says same thing whichever model posed it.
  ##   Twist's ends are mirrored for left arm, as `rigid.twistEnds` has them.
  result = Tight(room: Inf)
  for i in 0 ..< links.len:
    for k in 0 .. 1:
      let
        h = links[i].ends[k]
        j = joints(stance[h.body], h.arm, arms[i][k])
        tw = rig.range[Dof.Twist]
        twist = (if h.arm == Arm.Right: tw
                 else: Range(lo: -tw.hi, hi: -tw.lo, easeLo: tw.easeHi, easeHi: tw.easeLo))
      for (dof, r, v) in [(Dof.Extend, rig.range[Dof.Extend], j.extend),
                          (Dof.Across, rig.range[Dof.Across], j.across),
                          (Dof.Twist, twist, j.twist),
                          (Dof.Bend, rig.range[Dof.Bend], j.bend),
                          (Dof.Wrist, rig.range[Dof.Wrist], j.wrist)]:
        let m = margin(r, v)
        if m < result.room:
          result = Tight(room: m, dof: dof, whose: h)

func strain*(t: Tight): float =
  ## How far into last stretch before edge tightest joint is: one is edge.
  clamp(1.0 - t.room, 0.0, 1.0)
