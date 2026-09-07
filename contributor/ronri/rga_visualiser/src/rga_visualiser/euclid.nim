## Hold Euclidean quantities, and arithmetic picture is built out of.
##
## Far side of algebra boundary.
##   Nothing here knows what multivector is, and nothing above may teach it.
##   `mesh`, which turns geometry into GPU primitives, imports this alone, so
##   `Multivector` is not type it can name.
##   Crossing happens in one place, `boundary.nim`; geometry that crosses is placed in
##   `objects.nim` and `tessellate.nim`.
## Two sides answer different questions.
##   *Where object stands* is algebra's: scene object, world-space camera, ray cast from
##   screen, lattice line, axis, anything at horizon.
##   *How geometry becomes triangles* is not: plane's disc and line's ribbon are stand-ins
##   drawn for eye, carrying no geometric meaning, built with quickest arithmetic.
## `Position` and `Direction` stay separate types because they do not mix.
##   Difference of two positions is direction; position offset by direction is position.
##   Grade-1 multivector's weight coefficient decides which it holds, so confusing them
##   silently drops perspective divide; type makes that uncompilable.
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[math, options]

# Take one thing from algebra's directory, deliberately.
#   `algebra.nim` is metric and grade constants and names no multivector (asserted by
#   layout tool). Sharing tolerance beats second one that could drift.
import pga/algebra



#[ Type Definitions ]#

type
  Position* = object ## Define Euclidean position, in world units.
    x*, y*, z*: float

  Direction* = object ## Define Euclidean direction, in world units.
    x*, y*, z*: float

  FramePlane* = object ## Define orthonormal pair of directions spanning plane.
    axis_first*, axis_second*: Direction
    normal*: Direction ## Unit direction perpendicular to plane; same as `directionNormal(m)`.


# Forbid exact comparison, as every coordinate below is accumulated float.
func `==`*(p, q: Position): bool {.error:
  "Use approximate comparison, `=~`, or compare coordinates directly."
.}


func `==`*(d, e: Direction): bool {.error:
  "Use approximate comparison, `=~`, or compare coordinates directly."
.}



#[ Euclidean Arithmetic ]#

func `+`*(p: Position, d: Direction): Position =
  ## Offset position by direction.
  Position(x: p.x + d.x, y: p.y + d.y, z: p.z + d.z)


func `-`*(p: Position, d: Direction): Position =
  ## Offset position against direction.
  Position(x: p.x - d.x, y: p.y - d.y, z: p.z - d.z)


func `-`*(p, q: Position): Direction =
  ## Subtract positions to obtain direction separating them.
  Direction(x: p.x - q.x, y: p.y - q.y, z: p.z - q.z)


func `-`*(d: Direction): Direction =
  ## Reverse direction.
  Direction(x: -d.x, y: -d.y, z: -d.z)


func `+`*(d, e: Direction): Direction =
  ## Add directions, e.g. to compose ray from steps along independent axes.
  Direction(x: d.x + e.x, y: d.y + e.y, z: d.z + e.z)


func `*`*(scale: float, d: Direction): Direction =
  ## Scale direction.
  Direction(x: scale * d.x, y: scale * d.y, z: scale * d.z)


func dot*(d, e: Direction): float = d.x*e.x + d.y*e.y + d.z*e.z
  ## Get inner product of directions.


func cross*(d, e: Direction): Direction =
  ## Get direction perpendicular to both, right-handed.
  ##   Picture's own across-vector, for ribbon line is drawn as.
  ##     Which way line runs is algebra's answer; how wide its quad is drawn is not.
  ##   `mesh.directionAcross` is its one caller.
  ##     Suite holds it equal to join it replaced, `directionNormal(tail ∧ head ∧ eye)`,
  ##     sign included.
  Direction(
    x: d.y*e.z - d.z*e.y,
    y: d.z*e.x - d.x*e.z,
    z: d.x*e.y - d.y*e.x,
  )


func norm*(d: Direction): float = sqrt(dot(d, d))
  ## Get magnitude of direction.


func normalize*(d: Direction): Option[Direction] =
  ## Scale direction to unit magnitude.
  ##   None where direction has no magnitude, as it names no direction at all.
  let magnitude = d.norm
  if magnitude <= TOLERANCE_ABS: return
  some(Direction(x: d.x/magnitude, y: d.y/magnitude, z: d.z/magnitude))


type RingAngle* = tuple[cos_angle, sin_angle: float]
  ## Define one entry of fixed ring of angles: cosine and sine caller weights two arms by.
  ##   See `onCircleAt`.


func unitRing*[N: static int](segments: int): array[N, RingAngle] =
  ## Resolve `N` entries of ring stepped `segments` ways round circle.
  ##   Entry `i` sits at angle `2*PI*i/segments`.
  ##   One generator for every fixed ring project walks.
  ##     Plane rim and horizon line's great circle (`mesh.UNIT_CIRCLE_RIM`, one entry past
  ##     wrap so closing segment lands on value `cos(2*PI)` takes), plane's marker loop,
  ##     horizon line's marker bands.
  ##     Third hand-rolled table would be third chance to disagree about what ring means.
  ##   Called at start-up rather than at compile time.
  ##     Compile-time `cos` need not agree with each backend's own in last bit, and suites
  ##     hold these points equal to multivector sums they replaced.
  for i in 0 ..< N:
    let angle = (2.0*PI*float(i))/float(segments)
    result[i] = (cos_angle: cos(angle), sin_angle: sin(angle))


func onCircleAt*(
  centre: Position; arm_first, arm_second: Direction; cos_angle, sin_angle: float
): Position =
  ## Step round circle whose trigonometry caller already holds.
  ##   Centre, plus two radius-long arms weighted by given cosine and sine.
  ##   Trig-free core of `onCircle`, for callers walking fixed ring of angles (rim table,
  ##   shader's static corner buffer), paying each angle's trigonometry once.
  Position(
    x: centre.x + cos_angle*arm_first.x + sin_angle*arm_second.x,
    y: centre.y + cos_angle*arm_first.y + sin_angle*arm_second.y,
    z: centre.z + cos_angle*arm_first.z + sin_angle*arm_second.z,
  )


func onCircle*(centre: Position; arm_first, arm_second: Direction; angle: float): Position =
  ## Step round circle: centre, plus two radius-long arms weighted by angle.
  ##   Picture's own circle.
  ##     Disc is not geometric object; it is stand-in for plane, which is infinite, so its
  ##     rim and fan are stepped here rather than assembled as multivector sums.
  ##   Arms arrive already scaled; which plane they span is `boundary.frame`'s answer.
  ##   Held equal to multivector sum, point for point, by suite.
  onCircleAt(centre, arm_first, arm_second, cos(angle), sin(angle))
