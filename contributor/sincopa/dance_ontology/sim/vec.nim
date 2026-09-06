## Points and directions in space, and few things done with them.
##
##   Three numbers and no more.  Sim's whole geometry is capsules against
##     cylinders and against each other, which needs distances, projections
##     and one rotation, and nothing here knows what body is.
##   Helpers solver runs in its loop are spelt out in scalars.  On
##     JavaScript backend tuple operation allocates, and contact tests
##     run some tens of thousands of times per frame; operators are kept for
##     paths that run once per pose.
##     Cost: two spellings of same arithmetic.  Accepted -- scalar ones
##       are three that run in loop, and each is few lines.

{.experimental: "strictFuncs".}

import std/math


type Vec* = tuple[x, y, z: float] ## Point or direction, in metres.


func `+`*(a, b: Vec): Vec = (a.x + b.x, a.y + b.y, a.z + b.z)
func `-`*(a, b: Vec): Vec = (a.x - b.x, a.y - b.y, a.z - b.z)
func `-`*(a: Vec): Vec = (-a.x, -a.y, -a.z)
func `*`*(a: Vec; k: float): Vec = (a.x * k, a.y * k, a.z * k)
func dot*(a, b: Vec): float = a.x * b.x + a.y * b.y + a.z * b.z
func cross*(a, b: Vec): Vec =
  (a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
func norm*(a: Vec): float = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
func dist*(a, b: Vec): float =
  let
    dx = a.x - b.x
    dy = a.y - b.y
    dz = a.z - b.z
  sqrt(dx * dx + dy * dy + dz * dz)

func unit*(a: Vec): Vec =
  ## Scale to length one; zero vector stays zero rather than becoming NaN.
  let n = norm(a)
  if n < 1e-12: (0.0, 0.0, 0.0) else: (a.x / n, a.y / n, a.z / n)

func spunBy*(v, axis: Vec; c, s: float): Vec =
  ## Turn `v` about unit `axis` by angle whose cosine and sine are
  ## `c` and `s`, anticlockwise looking down axis (Rodrigues).
  ##   Form solver's loop wants: swing is known by dot and
  ##     cross of two directions, which are that cosine and sine already, so
  ##     no angle need be taken and its cosine and sine found again.
  let
    k = cross(axis, v)
    d = dot(axis, v)
  (v.x * c + k.x * s + axis.x * d * (1.0 - c),
   v.y * c + k.y * s + axis.y * d * (1.0 - c),
   v.z * c + k.z * s + axis.z * d * (1.0 - c))

func spun*(v, axis: Vec; by: float): Vec =
  ## Turn `v` about unit `axis` by `by` radians.
  spunBy(v, axis, cos(by), sin(by))

func carried*(v, fromDir, toDir: Vec): Vec =
  ## Move `v` by least rotation that takes unit `fromDir` to unit
  ## `toDir`: swing of joint, with no twist in it.
  ##   Singular only where two are opposite, where "least" is not one
  ##     rotation; any axis across them is taken, and law keeps model
  ##     off that line.
  let
    axis = cross(fromDir, toDir)
    s = norm(axis)
    c = dot(fromDir, toDir)
  if s < 1e-9:
    if c > 0.0:
      return v
    var across = cross(fromDir, (1.0, 0.0, 0.0))
    if norm(across) < 1e-6:
      across = cross(fromDir, (0.0, 1.0, 0.0))
    return spun(v, unit(across), PI)
  # Angle is atan2(s, c); its cosine and sine are c and s over their
  # hypotenuse, which is one for unit directions and is divided out anyway.
  let r = sqrt(s * s + c * c)
  spunBy(v, (axis.x / s, axis.y / s, axis.z / s), c / r, s / r)

func perp*(a: Vec): Vec =
  ## Some unit direction at right angles to `a`, chosen same way each time.
  var b = cross(a, (0.0, 0.0, 1.0))
  if norm(b) < 1e-6:
    b = cross(a, (1.0, 0.0, 0.0))
  unit(b)

func angleBetween*(a, b: Vec): float =
  ## Unsigned angle between two unit vectors, safe at ends.
  arccos(clamp(dot(a, b), -1.0, 1.0))

func signedAngle*(a, b, about: Vec): float =
  ## Angle from `a` to `b` turning anticlockwise about unit `about`,
  ## both at right angles to it.
  arctan2(dot(cross(a, b), about), dot(a, b))


func closest*(a, b, c, d: Vec): tuple[t, u, gap: float] =
  ## Where two segments come nearest: fraction along each, and how far
  ## apart they are there.
  ##   Written out in scalars: this is arm-against-arm test.
  let
    ux = b.x - a.x
    uy = b.y - a.y
    uz = b.z - a.z
    vx = d.x - c.x
    vy = d.y - c.y
    vz = d.z - c.z
    wx = a.x - c.x
    wy = a.y - c.y
    wz = a.z - c.z
    aa = ux * ux + uy * uy + uz * uz
    bb = ux * vx + uy * vy + uz * vz
    cc = vx * vx + vy * vy + vz * vz
    dd = ux * wx + uy * wy + uz * wz
    ee = vx * wx + vy * wy + vz * wz
    den = aa * cc - bb * bb
  var s, t: float
  if den < 1e-12:
    s = 0.0
  else:
    s = clamp((bb * ee - cc * dd) / den, 0.0, 1.0)
  if cc < 1e-12:
    t = 0.0
  else:
    t = (bb * s + ee) / cc
  if t < 0.0:
    t = 0.0
    s = if aa < 1e-12: 0.0 else: clamp(-dd / aa, 0.0, 1.0)
  elif t > 1.0:
    t = 1.0
    s = if aa < 1e-12: 0.0 else: clamp((bb - dd) / aa, 0.0, 1.0)
  let
    px = a.x + ux * s - (c.x + vx * t)
    py = a.y + uy * s - (c.y + vy * t)
    pz = a.z + uz * s - (c.z + vz * t)
  (s, t, sqrt(px * px + py * py + pz * pz))


func axisNear*(a, b: Vec; z0, z1: float): tuple[d, nx, ny: float] =
  ## Least horizontal distance from part of segment `a`-`b` that lies
  ## between heights `z0` and `z1` to vertical axis through origin,
  ## and plan offset of nearest point; infinite if none of
  ## segment is between them.
  ##   This is whole of cylinder test: caller has already widened
  ##     height band by limb's radius, so caps are covered too.
  let dz = b.z - a.z
  var lo, hi: float
  if abs(dz) < 1e-12:
    if a.z < z0 or a.z > z1:
      return (Inf, 0.0, 0.0)
    lo = 0.0
    hi = 1.0
  else:
    lo = (z0 - a.z) / dz
    hi = (z1 - a.z) / dz
    if lo > hi:
      swap lo, hi
    lo = max(lo, 0.0)
    hi = min(hi, 1.0)
    if lo > hi:
      return (Inf, 0.0, 0.0)
  let
    px = a.x + (b.x - a.x) * lo
    py = a.y + (b.y - a.y) * lo
    qx = a.x + (b.x - a.x) * hi
    qy = a.y + (b.y - a.y) * hi
    ex = qx - px
    ey = qy - py
    ee = ex * ex + ey * ey
  var t = 0.0
  if ee > 1e-16:
    t = clamp(-(px * ex + py * ey) / ee, 0.0, 1.0)
  let
    nx = px + ex * t
    ny = py + ey * t
  (sqrt(nx * nx + ny * ny), nx, ny)

func axisGap*(a, b: Vec; cx, cy, z0, z1: float): float =
  ## `axisNear` about axis through (`cx`, `cy`), distance alone.
  axisNear((a.x - cx, a.y - cy, a.z), (b.x - cx, b.y - cy, b.z), z0, z1).d
