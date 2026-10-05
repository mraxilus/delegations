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
## Size is judged against object's own scale, never against absolute tolerance.
##   Library's `TOLERANCE_ABS` (1e-9) is absolute, and join of points metre apart one unit
##   out carries coefficients near 1e-12, under it.
##   Kind reads scale-free copy, and horizon weighs weight against bulk.
##   Cost: rounding of zero standing alone reads as object too; `isRoundingOf` judges it
##   against factors that made it, where caller holds them.
##
## Shared by desktop (`main.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import pga

# Fail early rather than emit meaningless picture from algebra of wrong dimension.
static:
  doAssert DIMENSIONS == 4 and IS_RIGID,
    &"Visualiser draws 3D Euclidean space, so it needs 4D rigid PGA, i.e. " &
    &"`--define:pga.dimensions=4 --define:pga.is_conformal=false`; got `{DIMENSIONS}` " &
    &"with conformal `{IS_CONFORMAL}`."



#[ Type Definitions ]#

type
  Kind* {.pure.} = enum  ## Define geometry k-vector stands for in 4D RGA.
    Point,  ## Grade 1.
    Line,  ## Grade 2.
    Plane,  ## Grade 3.



#[ Scale ]#

const TOLERANCE_ROUNDING* = 2.0.pow(float(2 * DIMENSIONS - 52))
  ## Bound rounding one product of two multivectors leaves, against its factors' scales.
  ##   Each coefficient sums `2^DIMENSIONS` terms, each at most factors' largest
  ##   coefficients multiplied, and each step of sum loses `ε` of it: `2^(2·DIMENSIONS)·ε`,
  ##   `ε` being `2^-52`, spacing of doubles at one.
  ##   Sits between rounding and metre: point met on line joins with it to 2e-16 of
  ##   factors, and points metre apart join, about either one, to 6.7e-12 of theirs.
  ##     Measured; see `PROVENANCE.md`, Classification at any scale.


func coefficientLargest*(m: Multivector): float =
  ## Read magnitude of largest coefficient, scale `m` carries whatever object it names.
  for b in Basis: result = max(result, abs(m[b]))


func scaleFree*(m: Multivector): Multivector =
  ## Scale `m` so its largest coefficient has magnitude one, naming same object.
  ##   Every object is homogeneous: positive multiple of it names it.
  ##   Zero where `m` is, and where its largest is subnormal, whose reciprocal overflows.
  let largest = m.coefficientLargest
  if largest.classify in {fcZero, fcSubnormal}: return
  (1.0 / largest) * m


func isRoundingOf*(m: Multivector, scale: float): bool =
  ## Report whether `m` is rounding of zero, for product whose factors' scales multiply to `scale`.
  ##   Scale of factor is its `coefficientLargest`.
  ##   For caller that built `m` on spot and holds what built it: only it knows `scale`.
  m.coefficientLargest <= TOLERANCE_ROUNDING * scale



#[ Kind Classification ]#

func kindOf*(m: Multivector): Option[Kind] =
  ## Name geometry multivector stands for.
  ##   None for mixed grade, and for zero, scalar and antiscalar, which draw nothing.
  ##   Grade is read off `scaleFree` copy, so library's tolerance stands relative to
  ##   largest coefficient: coefficient under billionth of it reads as zero, at any scale.
  ##     Never off `m` alone, whose coefficients library judges against absolute 1e-9.
  ##   Copy is skipped where weight `E4` stands at one or more, as every unit-weight
  ##   point's does, and library reads one grade off `m`.
  ##     Largest coefficient is then at least one, so copy's threshold stands at or above
  ##     library's: it keeps subset of what library keeps, largest among them, and reads
  ##     same grade.
  ##     Weight alone is read, not largest: search for largest cost as much as `grade` on
  ##     desktop's debug build, which classifies every object three times each frame.
  var grade = if abs(m[Basis.E4]) >= 1.0: m.grade else: none(Grade)
  if grade.isNone: grade = m.scaleFree.grade
  if grade.isNone: return
  case int(grade.get)
  of 1: some(Kind.Point)
  of 2: some(Kind.Line)
  of 3: some(Kind.Plane)
  else: none[Kind]()


func isHorizon*(m: Multivector): bool =
  ## Report whether object lies wholly in horizon, i.e. whether its weight vanishes.
  ##   Weight is judged against bulk, so object reads as horizon where it stands more
  ##   than billion units out, i.e. `‖𝐦‖∘ ≤ 1e-9 ‖𝐦‖∙`, whatever its own scale.
  ##     Zero reads as horizon: it has no weight.
  abs((|∘m)[Basis.scalarAnti]) <= TOLERANCE_ABS * abs((|∙m)[Basis.scalar])


func isHorizonPlane*(m: Multivector): bool = kindOf(m) == some(Kind.Plane) and isHorizon(m)
  ## Report whether object is horizon plane.
  ##   One shape drawn as sky dome (`mesh.addDome`), which frame assembly inserts before
  ##   anything else sharing translucent veil pass. See `main.assembleMeshes`.



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


func innerOf*(m, n: Multivector): float =
  ## Read scalar of inner product between bulks, `𝐦 ∙ 𝐧`.
  ##   For two weightless points, i.e. directions, their lengths times cosine of angle between
  ##   them: sign says which side of each other they stand, and unit pair reads cosine alone.
  (m ∙ n)[Basis.scalar]


func distanceBetween*(p, q: Multivector): float =
  ## Measure distance between two unit-weight points.
  ##   Weight norm of joining line, i.e. `‖p ∧ q‖∘`, read from norm's `scalarAnti` handle.
  ##     For unitized points join's direction lives in weight, whose length is separation.
  normWeight(wedge(p, q))[Basis.scalarAnti]


func levelPlaneThrough*(point: Multivector): Multivector =
  ## Build horizontal plane through `point`, oriented so `depthAgainst` reads up as positive.
  ##   Joined y-then-x: x∧y join reads point one unit above at -1, y∧x at +1, and height
  ##   is what every caller means. Unitized for `depthAgainst`'s contract.
  ##   Axes written as algebra's own weightless points, `e2` then `e1`, not lifted from
  ##   Euclidean directions: basis element is what world axis *is* here.
  unitize(point ∧ 1.0.e2 ∧ 1.0.e1)


func groundPlane*(): Multivector =
  ## Build plane `z = 0`, oriented up-positive.
  ##   `levelPlaneThrough` at origin: one construction, two heights, so two spellings
  ##   cannot drift. Origin is unit-weight point with no bulk, `e4`.
  levelPlaneThrough(1.0.e4)
