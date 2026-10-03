## Points and directions in space, and few things done with them.
##
##   Three numbers and no more.  Simulation's whole geometry is capsules against
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


type Vector* = tuple[x, y, z: float] ## Point or direction, in metres.


# Arithmetic of vectors, one operation to line.
func `+`*(a, b: Vector): Vector = (a.x + b.x, a.y + b.y, a.z + b.z)
func `-`*(a, b: Vector): Vector = (a.x - b.x, a.y - b.y, a.z - b.z)
func `-`*(a: Vector): Vector = (-a.x, -a.y, -a.z)
func `*`*(a: Vector; k: float): Vector = (a.x * k, a.y * k, a.z * k)
func dot*(a, b: Vector): float = a.x * b.x + a.y * b.y + a.z * b.z
func cross*(a, b: Vector): Vector =
  ## Multiply vectors across, i.e. `a × b`.
  (a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
func norm*(a: Vector): float = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
func distance*(a, b: Vector): float =
  ## Measure straight distance between two points.
  let
    delta_x = a.x - b.x
    delta_y = a.y - b.y
    delta_z = a.z - b.z
  sqrt(delta_x * delta_x + delta_y * delta_y + delta_z * delta_z)

func unit*(a: Vector): Vector =
  ## Scale to length one; zero vector stays zero rather than becoming NaN.
  let n = norm(a)
  if n < 1e-12: (0.0, 0.0, 0.0) else: (a.x / n, a.y / n, a.z / n)

func spunBy*(v, axis: Vector; c, s: float): Vector =
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

func spun*(v, axis: Vector; by: float): Vector =
  ## Turn `v` about unit `axis` by `by` radians.
  spunBy(v, axis, cos(by), sin(by))

func carried*(v, from_direction, to_direction: Vector): Vector =
  ## Move `v` by least rotation that takes unit `from_direction` to unit
  ## `to_direction`: swing of joint, with no twist in it.
  ##   Singular only where two are opposite, where "least" is not one
  ##     rotation; any axis across them is taken, and law keeps model
  ##     off that line.
  let
    axis = cross(from_direction, to_direction)
    s = norm(axis)
    c = dot(from_direction, to_direction)
  if s < 1e-9:
    if c > 0.0:
      return v
    var across = cross(from_direction, (1.0, 0.0, 0.0))
    if norm(across) < 1e-6:
      across = cross(from_direction, (0.0, 1.0, 0.0))
    return spun(v, unit(across), PI)
  # Angle is atan2(s, c); its cosine and sine are c and s over their
  # hypotenuse, which is one for unit directions and is divided out anyway.
  let hypotenuse = sqrt(s * s + c * c)
  spunBy(v, (axis.x / s, axis.y / s, axis.z / s), c / hypotenuse, s / hypotenuse)

func perpendicular*(a: Vector): Vector =
  ## Some unit direction at right angles to `a`, chosen same way each time.
  var b = cross(a, (0.0, 0.0, 1.0))
  if norm(b) < 1e-6:
    b = cross(a, (1.0, 0.0, 0.0))
  unit(b)

func angleBetween*(a, b: Vector): float =
  ## Unsigned angle between two unit vectors, safe at ends.
  arccos(clamp(dot(a, b), -1.0, 1.0))

func signedAngle*(a, b, about: Vector): float =
  ## Angle from `a` to `b` turning anticlockwise about unit `about`,
  ## both at right angles to it.
  arctan2(dot(cross(a, b), about), dot(a, b))


func closest*(a, b, c, d: Vector): tuple[t, u, gap: float] =
  ## Where two segments come nearest: fraction along each, and how far
  ## apart they are there.
  ##   Written out in scalars: this is arm-against-arm test.
  let
    first_x = b.x - a.x
    first_y = b.y - a.y
    first_z = b.z - a.z
    second_x = d.x - c.x
    second_y = d.y - c.y
    second_z = d.z - c.z
    offset_x = a.x - c.x
    offset_y = a.y - c.y
    offset_z = a.z - c.z
    first_squared = first_x * first_x + first_y * first_y + first_z * first_z
    first_dot_second = first_x * second_x + first_y * second_y + first_z * second_z
    second_squared = second_x * second_x + second_y * second_y + second_z * second_z
    first_dot_offset = first_x * offset_x + first_y * offset_y + first_z * offset_z
    second_dot_offset = second_x * offset_x + second_y * offset_y + second_z * offset_z
    denominator = first_squared * second_squared - first_dot_second * first_dot_second
  var s, t: float
  if denominator < 1e-12:
    s = 0.0
  else:
    s = clamp(
      (first_dot_second * second_dot_offset - second_squared * first_dot_offset) / denominator,
      0.0,
      1.0,
    )
  if second_squared < 1e-12:
    # Second is point, as palm is: nearest point of first is its foot, not its start.
    t = 0.0
    s = if first_squared < 1e-12: 0.0 else: clamp(-first_dot_offset / first_squared, 0.0, 1.0)
  else:
    t = (first_dot_second * s + second_dot_offset) / second_squared
  if t < 0.0:
    t = 0.0
    s = if first_squared < 1e-12: 0.0 else: clamp(-first_dot_offset / first_squared, 0.0, 1.0)
  elif t > 1.0:
    t = 1.0
    s = if first_squared < 1e-12: 0.0
        else: clamp((first_dot_second - first_dot_offset) / first_squared, 0.0, 1.0)
  let
    gap_x = a.x + first_x * s - (c.x + second_x * t)
    gap_y = a.y + first_y * s - (c.y + second_y * t)
    gap_z = a.z + first_z * s - (c.z + second_z * t)
  (s, t, sqrt(gap_x * gap_x + gap_y * gap_y + gap_z * gap_z))


func axisNear*(a, b: Vector; bottom, top: float): tuple[distance, near_x, near_y: float] =
  ## Least horizontal distance from part of segment `a`-`b` that lies
  ## between heights `bottom` and `top` to vertical axis through origin,
  ## and plan offset of nearest point; infinite if none of
  ## segment is between them.
  ##   This is whole of cylinder test: caller has already widened
  ##     height band by limb's radius, so caps are covered too.
  let delta_z = b.z - a.z
  var lower, upper: float
  if abs(delta_z) < 1e-12:
    if a.z < bottom or a.z > top:
      return (Inf, 0.0, 0.0)
    lower = 0.0
    upper = 1.0
  else:
    lower = (bottom - a.z) / delta_z
    upper = (top - a.z) / delta_z
    if lower > upper:
      swap lower, upper
    lower = max(lower, 0.0)
    upper = min(upper, 1.0)
    if lower > upper:
      return (Inf, 0.0, 0.0)
  let
    lower_x = a.x + (b.x - a.x) * lower
    lower_y = a.y + (b.y - a.y) * lower
    upper_x = a.x + (b.x - a.x) * upper
    upper_y = a.y + (b.y - a.y) * upper
    piece_x = upper_x - lower_x
    piece_y = upper_y - lower_y
    piece_squared = piece_x * piece_x + piece_y * piece_y
  var t = 0.0
  if piece_squared > 1e-16:
    t = clamp(-(lower_x * piece_x + lower_y * piece_y) / piece_squared, 0.0, 1.0)
  let
    near_x = lower_x + piece_x * t
    near_y = lower_y + piece_y * t
  (sqrt(near_x * near_x + near_y * near_y), near_x, near_y)

func axisGap*(a, b: Vector; centre_x, centre_y, bottom, top: float): float =
  ## `axisNear` about axis through (`centre_x`, `centre_y`), distance alone.
  axisNear(
    (a.x - centre_x, a.y - centre_y, a.z),
    (b.x - centre_x, b.y - centre_y, b.z),
    bottom,
    top,
  ).distance
