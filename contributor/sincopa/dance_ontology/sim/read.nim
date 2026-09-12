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


func crossings*(arms: Arms): seq[Crossing] =
  ## Where two connections cross in plan, and which is over at each.
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
        den = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
      if abs(den) < 1e-12:
        continue
      let
        t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / den
        u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / den
      if t < 0.0 or t > 1.0 or u < 0.0 or u > 1.0:
        continue
      let
        zp = a.z + (b.z - a.z) * t
        zq = c.z + (d.z - c.z) * u
      result.add Crossing(at: (a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, zp),
                          along: i.float + t, across: j.float + u,
                          over: (if zp >= zq: 0 else: 1),
                          sense: (if den > 0.0: 1 else: -1))


func writhe*(arms: Arms): int =
  ## Crossings summed with their signs: which is over, times which way
  ## it crosses.  Two arms passing through each other change it by two;
  ## crossing appearing or vanishing at arm's end changes it by one.
  for c in crossings(arms):
    result += (if c.over == 0: 1 else: -1) * c.sense


const AT_END* = 0.25
  ## How near either connection's end crossing must sit to slide off it.
  ##   Quarter of link, which is shortest distance no crossing was seen to
  ##     travel in one moment: measured, crossing that stays put moves 0.045
  ##     along its connection in half of moments and 0.258 in nine tenths.

func slippable(cs: seq[Crossing]): bool =
  ## Whether any crossing sits where it can leave without arms meeting.
  for c in cs:
    if c.along < AT_END or c.along > 6.0 - AT_END or
       c.across < AT_END or c.across > 6.0 - AT_END:
      return true
  false

type Tight* = object ## Joint nearest its edge across every held arm.
  room*: float ## `margin` of that joint: nought at edge, one an ease in, negative past.
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

func sameCrossings*(a, b: Arms): bool =
  ## Whether one pose's arms can become other's without passing through
  ## each other.
  ##   Wind is what may not change. Crossings come and go in pairs where arms
  ##     pass over one another, which leaves writhe where it was, and singly
  ##     only where crossing slides off end of either connection. Lone
  ##     crossing leaving middle of both connections is arms through arms.
  ##   Read off both connections, not one: crossing sliding off second's end
  ##     sits mid-line along first, so `along` alone calls it middle.
  ##   Measured 2026-09-11, which is why this is not `< 2`: pair resting
  ##     pillion lead sheds one crossing between 0.68 and 0.70 of turn, at
  ##     1.53 along one connection and 4.24 along other, neither near end,
  ##     and mirrors it turning other way. That moves writhe by one, which
  ##     old test let through, and it is arms passing through each other.
  let apart = abs(writhe(a) - writhe(b))
  if apart == 0:
    return true
  if apart == 1:
    return slippable(crossings(a)) or slippable(crossings(b))
  false
