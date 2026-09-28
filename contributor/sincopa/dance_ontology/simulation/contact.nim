## Arms against bodies, and arms against arms.
##
##   Every link of arm is capsule: segment with limb's radius round
##     it.  Body is its rig's cylinders.  Test between them is exact on
##     cylinder's side and on its caps -- segment is clipped to
##     part's height band widened by limb's radius, and nearest
##     clipped piece comes to axis is compared with part's radius --
##     and over-cautious by at most one centimetre right at cap's rim.
##   Against its own body arm is allowed to press: clearance asked is
##     part's radius alone, so link's axis may touch skin.
##     Shoulder joint itself sits only three centimetres outside torso,
##     which is less than limb's radius, so nothing else lets arm hang.
##     Cost: arm can sink half its thickness into its own chest.  Accepted
##       -- flesh gives about that much, and alternative refuses standing.
##   Body's shape -- its axes and each part's section and height band --
##     is worked out once per stance and handed in, since solver tests
##     millions of links against it before stance moves.

{.experimental: "strictFuncs".}

import std/math

import ./[body, rig, vector]


type
  Touch* = object ## Nearest link comes to body, and to which part.
    part*: Part
    gap*: float ## Clearance in metres; negative is through skin.

  PartShape* = object ## One part's section and band, ready for test.
    hb*: float ## Half its breadth.
    q*: float  ## Depth over breadth.
    z0*, z1*: float ## Band, widened by limb's radius each way.

  BodyShape* = object ## One body as contact test sees it.
    axes*: Axes
    parts*: array[Part, PartShape]


func shapeOf*(rig: Rig; stance: Stance): BodyShape =
  ## Body's shape at stance.
  result.axes = axesOf(stance)
  for part in Part:
    result.parts[part] = PartShape(
      hb: halfBreadth(rig, part),
      q: rig.flat[part],
      z0: bottom(rig, part) - rig.limb,
      z1: rig.top[part] + rig.limb,
    )


func partGap*(axes: Axes; p: PartShape; a, b: Vec): float =
  ## Clearance of link `a`-`b` from one part of body whose axes these
  ## are, before any pad; infinite where link is not at its height.
  ##   Section is ellipse, so link is taken into body's own
  ##     terms and its depth scaled up until section is circle;
  ##     nearest approach is found there, and clearance read back along
  ##     radial line -- exact at front and at flank, and shade
  ##     approximate between.
  ##   Spelt out in scalars: this runs eighteen times for every arm laid;
  ##     and link wholly above or below band is answered before it is
  ##     taken into body's terms at all.
  if max(a.z, b.z) < p.z0 or min(a.z, b.z) > p.z1:
    return Inf
  let
    dax = a.x - axes.origin.x
    day = a.y - axes.origin.y
    dbx = b.x - axes.origin.x
    dby = b.y - axes.origin.y
    la: Vec = (dax * axes.right.x + day * axes.right.y,
               (dax * axes.fore.x + day * axes.fore.y) / p.q, a.z)
    lb: Vec = (dbx * axes.right.x + dby * axes.right.y,
               (dbx * axes.fore.x + dby * axes.fore.y) / p.q, b.z)
    near = axisNear(la, lb, p.z0, p.z1)
  if near.d == Inf:
    return Inf
  let k = if near.d < 1e-9: 1.0
          else: sqrt(near.nx * near.nx + p.q * p.q * near.ny * near.ny) / near.d
  (near.d - p.hb) * k

func partGap*(rig: Rig; axes: Axes; part: Part; a, b: Vec): float =
  ## Same, with part's shape worked out here.
  let shape = PartShape(
    hb: halfBreadth(rig, part),
    q: rig.flat[part],
    z0: bottom(rig, part) - rig.limb,
    z1: rig.top[part] + rig.limb,
  )
  partGap(axes, shape, a, b)


func bodyGap*(rig: Rig; shape: BodyShape; a, b: Vec; own: bool): Touch =
  ## Least clearance of link `a`-`b` from one body's three parts.
  result = Touch(part: Part.Torso, gap: Inf)
  let pad = if own: 0.0 else: rig.limb
  for part in Part:
    let d = partGap(shape.axes, shape.parts[part], a, b)
    if d < Inf:
      let gap = d - pad
      if gap < result.gap:
        result = Touch(part: part, gap: gap)

func bodyGap*(rig: Rig; stance: Stance; a, b: Vec; own: bool): Touch =
  ## Same, from stance.
  bodyGap(rig, shapeOf(rig, stance), a, b, own)


func armGap*(rig: Rig; a, b, c, d: Vec; meet: Vec; excuse: float): float =
  ## Clearance between two links of different arms; infinite where they
  ## come nearest within `excuse` of `meet`, which is how two arms holding
  ## one grip are let converge on it.
  let near = closest(a, b, c, d)
  if excuse > 0.0:
    let
      p = a + (b - a) * near.t
      q = c + (d - c) * near.u
    if distance(p, meet) < excuse and distance(q, meet) < excuse:
      return Inf
  near.gap - 2.0 * rig.limb


func pressing*(rig: Rig; stance: Stance; pose: tuple[e, w, g: Vec]): bool =
  ## Whether forearm or hand lies on its own torso or neck.
  ##   Upper arm always hangs against flank, so it is not asked;
  ##     what says arm is wound rather than merely led there is part
  ##     of it past elbow.
  const NEAR = 0.01
  let shape = shapeOf(rig, stance)
  for (a, b) in [(pose.e, pose.w), (pose.w, pose.g)]:
    for part in [Part.Torso, Part.Neck]:
      if partGap(shape.axes, shape.parts[part], a, b) < NEAR:
        return true
  false
