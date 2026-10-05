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
##   screen, lattice line, axis, anything in horizon.
##   *How geometry becomes triangles* is not: plane's disc and line's ribbon are stand-ins
##   drawn for eye, carrying no geometric meaning, built with quickest arithmetic.
## `Position` and `Direction` stay separate types because they do not mix.
##   Difference of two positions is direction; position offset by direction is position.
##   Grade-1 multivector's weight coefficient decides which it holds, so confusing them
##   silently drops perspective divide; type makes that uncompilable.
##
## Shared by desktop (`main.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[math, options]

# Take one thing from algebra's directory, deliberately.
#   `algebra.nim` is metric and grade constants and names no multivector (asserted by
#   layout tool). Sharing tolerance beats second one that could drift.
import pga/algebra



#[ Type Definitions ]#

type
  Position* = object  ## Define Euclidean position, in world units.
    x*, y*, z*: float

  Direction* = object  ## Define Euclidean direction, in world units.
    x*, y*, z*: float

  FramePlane* = object  ## Define orthonormal pair of directions spanning plane.
    axis_first*, axis_second*: Direction
    normal*: Direction  ## Unit direction perpendicular to plane; same as `directionNormal(m)`.

  RingAngle* = tuple[cos_angle, sin_angle: float]
    ## Define one entry of fixed ring of angles: cosine and sine caller weights two arms by.
    ##   See `onCircleAt`.


# Forbid exact comparison, as every coordinate below is accumulated float.
func `==`*(p, q: Position): bool {.error:
  "Use approximate comparison, `=~`, or compare coordinates directly."
.}


func `==`*(d, e: Direction): bool {.error:
  "Use approximate comparison, `=~`, or compare coordinates directly."
.}



#[ Euclidean Arithmetic ]#

# Operators write `result` field by field, never as constructor.
#   JS backend `nimCopy`s constructor assigned to `result`; field writes are plain stores
#   (read in emitted JS). `framing.reachNearOf` subtracts once per object per frame.
#   `noinit`, as every path writes every field: C then skips zero fill, and emits stores
#   constructor did (read in emitted C).
#   Same float operations in same order, so results stay bit-identical.
#   Cost: three statements where one constructor named each field.
func `+`*(p: Position, d: Direction): Position {.noinit.} =
  ## Offset position by direction.
  result.x = p.x + d.x
  result.y = p.y + d.y
  result.z = p.z + d.z


func `-`*(p: Position, d: Direction): Position {.noinit.} =
  ## Offset position against direction.
  result.x = p.x - d.x
  result.y = p.y - d.y
  result.z = p.z - d.z


func `-`*(p, q: Position): Direction {.noinit.} =
  ## Subtract positions to obtain direction separating them.
  result.x = p.x - q.x
  result.y = p.y - q.y
  result.z = p.z - q.z


func `-`*(d: Direction): Direction {.noinit.} =
  ## Reverse direction.
  result.x = -d.x
  result.y = -d.y
  result.z = -d.z


func `+`*(d, e: Direction): Direction {.noinit.} =
  ## Add directions, e.g. to compose ray from steps along independent axes.
  result.x = d.x + e.x
  result.y = d.y + e.y
  result.z = d.z + e.z


func `*`*(scale: float, d: Direction): Direction {.noinit.} =
  ## Scale direction.
  result.x = scale * d.x
  result.y = scale * d.y
  result.z = scale * d.z


func toView*(place, origin: Position): Position {.noinit.} =
  ## Read world `place` about view origin `origin`, as every calculation of frame reads it.
  ##   Two doubles near each other subtract exactly, so place near eye keeps every bit.
  result.x = place.x - origin.x
  result.y = place.y - origin.y
  result.z = place.z - origin.z


func toWorld*(place, origin: Position): Position {.noinit.} =
  ## Read `place`, held about view origin `origin`, about world origin, as storage holds it.
  ##   Rounds to world's doubles: far out, remainder finer than their step is lost.
  result.x = origin.x + place.x
  result.y = origin.y + place.y
  result.z = origin.z + place.z


func rebased*(place: Position; origin_from, origin_to: Position): Position {.noinit.} =
  ## Read `place`, held about `origin_from`, about `origin_to` instead.
  ##   Origins' difference first: two near each other cancel exactly, so place keeps every
  ##   bit it had where both origins stand near it.
  result.x = (origin_from.x - origin_to.x) + place.x
  result.y = (origin_from.y - origin_to.y) + place.y
  result.z = (origin_from.z - origin_to.z) + place.z


func dot*(d, e: Direction): float = d.x * e.x + d.y * e.y + d.z * e.z
  ## Get inner product of directions.


func cross*(d, e: Direction): Direction =
  ## Get direction perpendicular to both, right-handed.
  ##   Picture's own across-vector, for ribbon line is drawn as.
  ##     Which way line runs is algebra's answer; how wide its quad is drawn is not.
  ##   `mesh.directionAcross` is its one caller.
  ##     Suite holds it equal to join it replaced, `directionNormal(tail ∧ head ∧ eye)`,
  ##     sign included.
  Direction(
    x: d.y * e.z - d.z * e.y,
    y: d.z * e.x - d.x * e.z,
    z: d.x * e.y - d.y * e.x,
  )


func norm*(d: Direction): float = sqrt(dot(d, d))
  ## Get magnitude of direction.


func normalize*(d: Direction, scale = 0.0): Option[Direction] =
  ## Scale direction to unit magnitude.
  ##   None where direction has no magnitude, as it names no direction at all.
  ##   Magnitude is judged against `scale`, size of what direction was read from: none
  ##   where it is no more than `TOLERANCE_ABS` of that.
  ##     Default zero refuses zero alone, as direction of any length names one.
  ##     Never against absolute tolerance: line metre long one unit out runs along
  ##     direction of length 7e-12.
  let magnitude = d.norm
  if magnitude <= TOLERANCE_ABS * scale: return
  some(Direction(x: d.x / magnitude, y: d.y / magnitude, z: d.z / magnitude))


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
  for i in 0..<N:
    let angle = (2.0 * PI * float(i)) / float(segments)
    result[i] = (cos_angle: cos(angle), sin_angle: sin(angle))


func onCircleAt*(
  centre: Position; arm_first, arm_second: Direction; cos_angle, sin_angle: float
): Position =
  ## Step round circle whose trigonometry caller already holds.
  ##   Centre, plus two radius-long arms weighted by given cosine and sine.
  ##   Trig-free core of `onCircle`, for callers walking fixed ring of angles (rim table,
  ##   shader's static corner buffer), paying each angle's trigonometry once.
  Position(
    x: centre.x + cos_angle * arm_first.x + sin_angle * arm_second.x,
    y: centre.y + cos_angle * arm_first.y + sin_angle * arm_second.y,
    z: centre.z + cos_angle * arm_first.z + sin_angle * arm_second.z,
  )


func onCircle*(centre: Position; arm_first, arm_second: Direction; angle: float): Position =
  ## Step round circle: centre, plus two radius-long arms weighted by angle.
  ##   Picture's own circle.
  ##     Disc is not geometric object; it is stand-in for plane, which is infinite, so its
  ##     rim and fan are stepped here rather than assembled as multivector sums.
  ##   Arms arrive already scaled; which plane they span is `boundary.frame`'s answer.
  ##   Held equal to multivector sum, point for point, by suite.
  onCircleAt(centre, arm_first, arm_second, cos(angle), sin(angle))
