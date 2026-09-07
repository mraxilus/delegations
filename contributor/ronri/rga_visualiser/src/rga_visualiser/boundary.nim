## Convert between algebra and picture, in one place where both languages are spoken.
##
## Everything lifting Euclidean quantity into multivector, or reading one back out, is here
## and nowhere else.
##   Reader asking where project leaves algebra opens one file.
##   Reader adding conversion has one place to put it.
## Quantities are read through library's own operators rather than out of coefficient
## table, so renderer exercises algebra it exists to show.
##
##   |-----------------|--------------|----------------------------------------------|
##   | Identifier      | Lengyel      | Meaning                                      |
##   |-----------------|--------------|----------------------------------------------|
##   | position        | 𝐩 ÷ pʷ       | Euclidean position of point.                 |
##   | positionSupport | sup(𝐦) = 𝐦∩  | Point of object nearest origin.              |
##   | positionAnchor  | derived      | Point to build drawing of object around.     |
##   | direction       | att(𝐦) = ⊖𝐦  | Unit direction line extends along.           |
##   | directionNormal | -𝐦☆          | Unit direction perpendicular to plane.       |
##   | directionHorizon| 𝐩 at pʷ = 0  | Unit direction point at horizon stands for.  |
##   | frame           | derived      | Orthonormal pair of directions inside plane. |
##   |-----------------|--------------|----------------------------------------------|
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[options, strformat]

import pga
import ./[euclid, objects]

# Re-export both languages: module reaching for crossing needs both by definition.
#   What boundary protects is other direction: `mesh` imports `euclid` alone.
export euclid, objects



#[ Multivector Conversion ]#

func toMultivector*(p: Position): Multivector =
  ## Convert Euclidean position to unit-weight grade-1 point.
  p.x.e1 + p.y.e2 + p.z.e3 + 1.0.e4


func toMultivector*(d: Direction): Multivector =
  ## Convert Euclidean direction to grade-1 point at horizon.
  ##   Weight is 0, so point stands for direction rather than place.
  d.x.e1 + d.y.e2 + d.z.e3



#[ Object Interrogation ]#

func position*(m: Multivector): Option[Position] =
  ## Read Euclidean position of point.
  ##   None where point lies at horizon, as direction has no place.
  ##   Divides by signed weight rather than weight norm, so antipodal points stay distinct.
  let weight = m[Basis.E4]
  if abs(weight) <= TOLERANCE_ABS: return
  some(Position(x: m[Basis.E1]/weight, y: m[Basis.E2]/weight, z: m[Basis.E3]/weight))


func positionSupport*(m: Multivector): Option[Position] =
  ## Read point of object nearest origin, i.e. orthogonal projection of origin onto object.
  ##   None where object passes through origin, as support then vanishes.
  position(∩ m)


func positionAnchor*(m: Multivector): Option[Position] =
  ## Choose point of object to build its drawing around.
  ##   Support point where object misses origin, origin itself where it does not.
  ##   None where object lies at horizon, as it then has no finite point at all.
  let support = positionSupport(m)
  if support.isSome: return support
  if m.isHorizon: return
  some(Position(x: 0, y: 0, z: 0))


func direction*(m: Multivector): Option[Direction] =
  ## Read unit direction line extends along.
  ##   None where line lies at horizon, as its attitude then vanishes.
  let attitude = ⊖ m
  normalize(Direction(x: attitude[Basis.E1], y: attitude[Basis.E2], z: attitude[Basis.E3]))


func directionHorizon*(m: Multivector): Option[Direction] =
  ## Read unit direction point at horizon stands for.
  ##   None where point has weight, as it then names place rather than direction.
  if not m.isHorizon: return
  normalize(Direction(x: m[Basis.E1], y: m[Basis.E2], z: m[Basis.E3]))


func directionNormalHorizon*(m: Multivector): Option[Direction] =
  ## Read unit direction normal to pencil of directions horizon line stands for.
  ##   Line's weight lives in `E41`/`E42`/`E43`; `E23`/`E31`/`E12` survive at horizon and
  ##   carry same normal finite plane's attitude would leave there, unnormalized.
  ##     Confirmed component for component against `(⊖ plane)[E23], [E31], [E12]`.
  ##   None where line has weight, as it then runs along direction, not perpendicular to
  ##   pencil of them.
  if not m.isHorizon: return
  normalize(Direction(x: m[Basis.E23], y: m[Basis.E31], z: m[Basis.E12]))


func directionNormal*(m: Multivector): Option[Direction] =
  ## Read unit direction perpendicular to plane.
  ##   Antidual is negated so normal runs along plane's own weight gˣ, gʸ, gᶻ.
  ##   None where plane lies at horizon, as horizon has no normal in Euclidean space.
  let normal = -(☆m)
  normalize(Direction(x: normal[Basis.E1], y: normal[Basis.E2], z: normal[Basis.E3]))



#[ Plane Frame ]#

func spanPerpendicular*(anchor: Position, normal: Direction): Option[(Direction, Direction)] =
  ## Derive orthonormal pair of directions perpendicular to `normal`, through `anchor`.
  ##   Built as `frame` spans plane's own axes, so caller holding normal read some other
  ##   way still spans it algebraically, through joins and antiduals, not raw cross product.
  ##   Pair is arbitrary up to rotation about `normal`; only plane it spans is meaningful.
  ##     `anchor` only fixes where spanning joins are built through.
  ##   None only where library's antiduals fail to resolve, which no unit `normal` causes.

  # Pick world axis least aligned with normal, so joins below stay well conditioned.
  const AXES_WORLD = [
    Direction(x: 1, y: 0, z: 0),
    Direction(x: 0, y: 1, z: 0),
    Direction(x: 0, y: 0, z: 1),
  ]
  let alignments = [abs(normal.x), abs(normal.y), abs(normal.z)]
  var index_least = 0
  for i in 1 .. 2:
    if alignments[i] < alignments[index_least]: index_least = i
  let axis_world = AXES_WORLD[index_least]

  # Span plane through anchor holding both helper axis and normal.
  #   Its own normal is perpendicular to both, so it lies inside plane `normal` spans.
  let
    point_anchor = toMultivector(anchor)
    point_normal = toMultivector(normal)
    plane_first = point_anchor ∧ toMultivector(axis_world) ∧ point_normal
    axis_first = directionNormal(plane_first)
  if axis_first.isNone: return

  # Repeat against first axis, to obtain second axis perpendicular to it inside plane.
  let
    plane_second = point_anchor ∧ toMultivector(axis_first.get) ∧ point_normal
    axis_second = directionNormal(plane_second)
  if axis_second.isNone: return

  some((axis_first.get, axis_second.get))


func frame*(m: Multivector): Option[FramePlane] =
  ## Derive orthonormal pair of directions lying inside plane.
  ##   Pair is arbitrary up to rotation about normal; only plane it spans is meaningful.
  ##   None where plane lies at horizon, as it then spans no Euclidean directions.
  let
    normal = directionNormal(m)
    anchor = positionAnchor(m)
  if normal.isNone or anchor.isNone: return
  let axes = spanPerpendicular(anchor.get, normal.get)
  if axes.isNone: return
  let (axis_first, axis_second) = axes.get
  some(FramePlane(axis_first: axis_first, axis_second: axis_second, normal: normal.get))


func pointFrom*(m: Multivector): Position =
  ## Read point assembled through algebra back out as place.
  ##   Every caller builds `m` as unit-weight point plus weightless directions, so weight
  ##   is exactly one and read cannot refuse.
  ##   Asserted rather than defaulted: zero weight here means assembly upstream is wrong.
  let read = position(m)
  doAssert read.isSome, &"Assembled point must carry weight, its assembly is wrong; got `{m}`."
  read.get
