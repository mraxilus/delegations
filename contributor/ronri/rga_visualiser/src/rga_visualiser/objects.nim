## Name what object is, and incidence questions visualiser asks, in algebra's own words.
##
## Module is specialised to 4D RGA, i.e. 3D Euclidean space.
##   Grade 1 is point, grade 2 is line, grade 3 is plane.
##   Grades 0 and 4 are scalar and antiscalar, carrying no geometry to draw.
## Multivector in, multivector or scalar out.
##   Nothing here names Euclidean quantity; lifting one in or reading one out is
##   `boundary.nim`'s job alone. See `euclid.nim` header for which side owns what.
## Every sign and argument order is pinned by suite case against classical closed form.
##   Classical form lives in test, algebra lives here.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[options, strformat]

import pga

# Fail early rather than emit meaningless picture from algebra of wrong dimension.
static:
  doAssert DIMENSIONS == 4 and IS_RIGID,
    &"Visualiser draws 3D Euclidean space, so it needs 4D rigid PGA, i.e. " &
      &"`--define:pga.dimensions=4 --define:pga.is_conformal=false`; got `{DIMENSIONS}` " &
      &"with conformal `{IS_CONFORMAL}`."



#[ Type Definitions ]#

type
  Kind* {.pure.} = enum ## Define geometry k-vector stands for in 4D RGA.
    Point, ## Grade 1.
    Line, ## Grade 2.
    Plane, ## Grade 3.



#[ Kind Classification ]#

func kindOf*(m: Multivector): Option[Kind] =
  ## Name geometry multivector stands for.
  ##   None for mixed grade, and for scalar and antiscalar, which draw nothing.
  let grade = m.grade
  if grade.isNone: return
  case int(grade.get)
  of 1: some(Kind.Point)
  of 2: some(Kind.Line)
  of 3: some(Kind.Plane)
  else: none[Kind]()


func isHorizon*(m: Multivector): bool = abs(( |∘ m)[Basis.scalarAnti]) <= TOLERANCE_ABS
  ## Report whether object lies wholly at horizon, i.e. whether its weight vanishes.


func isHorizonPlane*(m: Multivector): bool = kindOf(m) == some(Kind.Plane) and isHorizon(m)
  ## Report whether object is plane at horizon.
  ##   One shape drawn as sky dome (`mesh.addDome`), which frame assembly inserts before
  ##   anything else sharing translucent veil pass. See `visualiser.assembleMeshes`.



#[ Incidence Vocabulary ]#

func planeThrough*(point, direction: Multivector): Multivector =
  ## Build plane through `point` perpendicular to line along `direction`.
  ##   Unitized, so `depthAgainst` reads metric distance off it.
  ##   Weight expansion of point onto own line, i.e. `p ∧ (p ∧ d)☆`: plane containing `p`
  ##   whose normal is line's direction. Library's `expandWeight`, `𝐦 ∧ 𝐧☆` in catalogue.
  unitize(expandWeight(point, wedge(point, direction)))


func depthAgainst*(plane, point: Multivector): float =
  ## Measure signed distance of unit-weight point from unitized plane.
  ##   Positive on side plane's construction direction points toward, zero on it.
  ##   Meet of plane and point is volume they span, whose one coefficient is point's height
  ##   over plane: antigrades 1 and 3 close to 4, *scalar* handle, not `scalarAnti`.
  ##   Argument order is `plane ∨ point`; other order negates.
  ##     Suite pins point one unit along plane's direction at exactly +1.
  wedgeAnti(plane, point)[Basis.scalar]


func centroidFolded*(centroid: Multivector, place: Multivector): Multivector =
  ## Fold one more unit-weight point into running centroid.
  ##   Sum of unit-weight points is their centroid: sum of `n` unit points carries weight
  ##   `n` and total of coordinates; `boundary.position` divides by signed weight.
  ##   Running sum stays multivector rather than being read to place and lifted per fold,
  ##   so accumulated weight *is* count.
  ##     Caller starts from first point and folds rest in, allocating nothing, as
  ##     `camera.widened` does.
  add(centroid, place)


func distanceBetween*(p, q: Multivector): float =
  ## Measure distance between two unit-weight points.
  ##   Weight norm of joining line, i.e. `‖p ∧ q‖∘`, read from norm's `scalarAnti` handle.
  ##     For unitized points join's direction lives in weight, whose length is separation.
  normWeight(wedge(p, q))[Basis.scalarAnti]


func levelPlaneThrough*(point: Multivector): Multivector =
  ## Build horizontal plane through `point`, oriented so `depthAgainst` reads up as positive.
  ##   Level reader works at when camera pivots `point`.
  ##   Joined y-then-x: x∧y join reads point one unit above at -1, y∧x at +1, and height
  ##   is what every caller means. Unitized for `depthAgainst`'s contract.
  ##   Axes written as algebra's own weightless points, `e2` then `e1`, not lifted from
  ##   Euclidean directions: basis element is what world axis *is* here.
  unitize(point ∧ 1.0.e2 ∧ 1.0.e1)


func groundPlane*(): Multivector =
  ## Build ground, `z = 0`, oriented up-positive.
  ##   `levelPlaneThrough` at origin: one construction, two heights, so two spellings
  ##   cannot drift. Origin is unit-weight point with no bulk, `e4`.
  levelPlaneThrough(1.0.e4)
