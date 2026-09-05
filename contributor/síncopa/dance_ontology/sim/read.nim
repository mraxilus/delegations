## What pose says about itself, still in body's own words.
##
##   Where held arm lies on its own body -- across front or behind
##     back, at chest or neck, pressing or merely carried there --
##     and where two connections cross in plan and which is higher.
##     Dance's words for these are put on outside sim.

{.experimental: "strictFuncs".}

import std/options

import ./[body, contact, limb, rig, solve, vec]


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
    over*: int ## Which connection is higher there, 0 or 1.
    sense*: int ## +1 where second crosses first left to right
                ## looking along it, else -1.


func armOf*(s: State; i: int; who: Body): int =
  ## Which end of connection `i` is `who`'s.
  if s.links[i].ends[0].body == who: 0 else: 1


func lyingOn*(s: State; v: Verdict; i: int; who: Body): Option[Lying] =
  ## Where `who`'s arm in connection `i` lies on `who`'s own body; none where
  ## it is out in front, or carried over crown.
  if s.band == Band.Crown:
    return none(Lying)
  let
    k = armOf(s, i, who)
    hand = s.links[i].ends[k]
    pose = v.fits[i].arms[k]
    st = s.stance[who]
    ax = axesOf(st)
    g = toBody(ax, pose.g)
    e = toBody(ax, pose.e)
    ownSide = side(hand.arm)
  var aspect: Aspect
  if g.y < -0.01:
    aspect = Aspect.Aft
  elif g.x * ownSide < -0.01 and g.y < halfDepth(s.rig, Part.Torso) + 4.0 * s.rig.limb:
    aspect = Aspect.Fore
  else:
    return none(Lying)
  some(Lying(aspect: aspect, band: s.band,
             pressing: pressing(s.rig, st, (pose.e, pose.w, pose.g)),
             elbowFore: e.y > 0.0))


func polyline(v: Verdict; i: int): array[7, Vec] =
  ## One connection as seven points: shoulder to shoulder through grip.
  let
    a = v.fits[i].arms[0]
    b = v.fits[i].arms[1]
  [a.s, a.e, a.w, a.g, b.w, b.e, b.s]


func crossings*(s: State; v: Verdict): seq[Crossing] =
  ## Where two connections cross in plan, and which is over at each.
  if s.links.len < 2:
    return
  let
    p = polyline(v, 0)
    q = polyline(v, 1)
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
                          along: i.float + t, over: (if zp >= zq: 0 else: 1),
                          sense: (if den > 0.0: 1 else: -1))


func writhe*(s: State; v: Verdict): int =
  ## Crossings summed with their signs: which is over, times which way
  ## it crosses.  Two arms passing through each other change it by two;
  ## crossing appearing or vanishing at arm's end changes it by one.
  for c in crossings(s, v):
    result += (if c.over == 0: 1 else: -1) * c.sense


func sameCrossings*(a: State; va: Verdict; b: State; vb: Verdict): bool =
  ## Whether one judged pose's arms can become other's without passing
  ## through each other, read off writhe.
  abs(writhe(a, va) - writhe(b, vb)) < 2

func sameCrossings*(a, b: State): bool =
  ## Same, states judged here.
  sameCrossings(a, evaluate(a), b, evaluate(b))
