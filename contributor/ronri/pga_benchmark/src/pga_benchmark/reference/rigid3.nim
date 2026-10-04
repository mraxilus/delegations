## Derive Lengyel's typed objects and hand-rolled operations of 3D rigid geometric algebra.
##   Reference every dense library operation is measured against: each object holds only
##   components its grade can carry, and each operation spells only terms that survive,
##   as optimal hand-written linear algebra does. Forms follow *Projective Geometric
##   Algebra Illuminated* and rigidgeometricalgebra.org; Terathon Math Library (MIT,
##   Eric Lengyel) was read to cross-check forms and counts, and nothing is copied from
##   it. Scalar is `float`, as library's, so both sides compute in same precision.
##
##   |---------|-------------------------------------------------|-------------------------|
##   | Code    | Notation                                        | Library basis           |
##   |---------|-------------------------------------------------|-------------------------|
##   | Point   | 𝐩 = pˣe₁ + pʸe₂ + pᶻe₃ + pʷe₄                   | E1 E2 E3 E4             |
##   | Line    | 𝐥 = lᵛ(e₄₁ e₄₂ e₄₃) + lᵐ(e₂₃ e₃₁ e₁₂)           | E41 E42 E43 E23 E31 E12 |
##   | Plane   | 𝐠 = gˣe₄₂₃ + gʸe₄₃₁ + gᶻe₄₁₂ + gʷe₃₂₁           | E423 E431 E412 E321     |
##   | Motor   | 𝐐 = Qᵛ + Qᵛʷ𝟙 + Qᵐ + Qᵐʷ𝟏                       | E41..E12, E1234, S      |
##   | Scalar  | s𝟏                                              | S                       |
##   | Antisc. | t𝟙                                              | E1234                   |
##   |---------|-------------------------------------------------|-------------------------|
##
##   Each operation's doc states multiply and add counts of its form, i.e. what optimal
##     code spends; suite `Internal: Inspector` reads those counts back from emitted C.
##   No function calls another: under `--panics:off` each call to Nim function fills its
##     result and checks error flag after it, and hand code spends neither; vector helpers
##     are templates, and form two functions share is spelled in each. Suite `Internal: Inspector`
##     holds every reference function to no fill and no check.
##   Motor transforms are derived, not transcribed: rotation by quaternion (Qᵛ, Qᵛʷ),
##     translation 𝐭 = 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ + Qᵛ × Qᵐ), which is what antisandwich
##     𝐐 ⟇ 𝐩 ⟇ 𝐐̰ spells for unit motor; suite `Wiki: Motor` holds them to library.
##   Cost: transforms assume unitized motor obeying Qᵛ ∙ Qᵐ + Qᵛʷ Qᵐʷ = 0, as every
##     motor from composing rotations and translations does; arbitrary even element is
##     not motor and is not covered.
##   Cost: duals of points and planes carry library's sign, i.e. right complement of
##     metric image, which is opposite of Terathon's `BulkDual`; suite `Chapter 2` is
##     what settled it, on library's own equation 2.103.

{.experimental: "strictFuncs".}

import std/math

import ./scalars

export scalars


type
  Vector3* = object  ## Define three components named as vector; direction, moment or normal.
    x*, y*, z*: float
  Point* = object  ## Define point 𝐩 with homogeneous weight w; grade 1.
    x*, y*, z*, w*: float
  Line* = object  ## Define line 𝐥 with direction v and moment m; grade 2.
    v*, m*: Vector3
  Plane* = object  ## Define plane 𝐠 with normal (x y z) and position w; grade 3.
    x*, y*, z*, w*: float
  Motor* = object  ## Define motor 𝐐 with weight (v, vw) and bulk (m, mw); even grades.
    v*, m*: Vector3
    vw*, mw*: float



#[ Vector Helpers ]#

template cross*(a, b: Vector3): Vector3 =
  ## Multiply vectors through cross product, i.e. 𝐚 × 𝐛; 6 mul, 3 sub.
  (let u = a; let w = b;
    Vector3(x: u.y * w.z - u.z * w.y, y: u.z * w.x - u.x * w.z, z: u.x * w.y - u.y * w.x))

template dot*(a, b: Vector3): float =
  ## Multiply vectors through dot product, i.e. 𝐚 ∙ 𝐛; 3 mul, 2 add.
  (let u = a; let w = b; u.x * w.x + u.y * w.y + u.z * w.z)

template `+`*(a, b: Vector3): Vector3 =
  ## Add vectors; 3 add.
  (let u = a; let w = b; Vector3(x: u.x + w.x, y: u.y + w.y, z: u.z + w.z))

template `-`*(a, b: Vector3): Vector3 =
  ## Subtract vectors; 3 sub.
  (let u = a; let w = b; Vector3(x: u.x - w.x, y: u.y - w.y, z: u.z - w.z))

template `-`*(a: Vector3): Vector3 =
  ## Negate vector; 0 mul.
  (let u = a; Vector3(x: -u.x, y: -u.y, z: -u.z))

template `*`*(a: Vector3, s: float): Vector3 =
  ## Scale vector; 3 mul.
  (let u = a; let f = s; Vector3(x: u.x * f, y: u.y * f, z: u.z * f))

template zero3(): Vector3 =
  ## Spell zero vector by components.
  ##   Default constructor `Vector3()` zero-fills field through `nimZeroMem`; in bench, about
  ##     21 ns more on four line rows at rga4d (see PROVENANCE, Reference).
  Vector3(x: 0.0, y: 0.0, z: 0.0)

template read3(v: Vector3): Vector3 =
  ## Spell copy of vector by components.
  ##   Whole-object copy calls synthesised `=dup` hook; in bench, 1.6 ns more on two line rows
  ##     at rga4d (see PROVENANCE, Reference).
  Vector3(x: v.x, y: v.y, z: v.z)


template rotate(x, v: Vector3; vw: float): Vector3 =
  ## Rotate vector by unit quaternion (v, vw), i.e. x + 2(vw v × x + v × (v × x)).
  ##   18 mul, 12 add.
  (let u = x; let a = v; let s = vw; let c = cross(a, u); u + (c * s + cross(a, c)) * 2.0)



#[ Exterior Products ]#

func wedge*(p, q: Point): Line {.inline.} =
  ## Join points into line through both, i.e. 𝐩 ∧ 𝐪; 12 mul, 6 sub.
  Line(
    v: Vector3(x: p.w * q.x - p.x * q.w, y: p.w * q.y - p.y * q.w, z: p.w * q.z - p.z * q.w),
    m: Vector3(x: p.y * q.z - p.z * q.y, y: p.z * q.x - p.x * q.z, z: p.x * q.y - p.y * q.x),
  )

func wedge*(l: Line, p: Point): Plane {.inline.} =
  ## Join line and point into plane containing both, i.e. 𝐥 ∧ 𝐩; 12 mul, 8 add.
  Plane(
    x: l.v.y * p.z - l.v.z * p.y + l.m.x * p.w,
    y: l.v.z * p.x - l.v.x * p.z + l.m.y * p.w,
    z: l.v.x * p.y - l.v.y * p.x + l.m.z * p.w,
    w: -l.m.x * p.x - l.m.y * p.y - l.m.z * p.z,
  )

func wedge*(p: Point, l: Line): Plane {.inline.} =
  ## Join point and line, i.e. 𝐩 ∧ 𝐥 = 𝐥 ∧ 𝐩 since grades 1 and 2 commute; 12 mul, 8 add.
  Plane(
    x: p.z * l.v.y - p.y * l.v.z + p.w * l.m.x,
    y: p.x * l.v.z - p.z * l.v.x + p.w * l.m.y,
    z: p.y * l.v.x - p.x * l.v.y + p.w * l.m.z,
    w: -p.x * l.m.x - p.y * l.m.y - p.z * l.m.z,
  )

func wedgeAnti*(g, h: Plane): Line {.inline.} =
  ## Meet planes in line, i.e. 𝐠 ∨ 𝐡; 12 mul, 6 sub.
  Line(
    v: Vector3(x: g.z * h.y - g.y * h.z, y: g.x * h.z - g.z * h.x, z: g.y * h.x - g.x * h.y),
    m: Vector3(x: g.x * h.w - g.w * h.x, y: g.y * h.w - g.w * h.y, z: g.z * h.w - g.w * h.z),
  )

func wedgeAnti*(g: Plane, l: Line): Point {.inline.} =
  ## Meet plane and line in point, i.e. 𝐠 ∨ 𝐥; 12 mul, 8 add.
  Point(
    x: l.m.y * g.z - l.m.z * g.y + l.v.x * g.w,
    y: l.m.z * g.x - l.m.x * g.z + l.v.y * g.w,
    z: l.m.x * g.y - l.m.y * g.x + l.v.z * g.w,
    w: -l.v.x * g.x - l.v.y * g.y - l.v.z * g.z,
  )

func wedgeAnti*(l: Line, g: Plane): Point {.inline.} =
  ## Meet line and plane, i.e. 𝐥 ∨ 𝐠 = 𝐠 ∨ 𝐥 since antigrades 1 and 2 commute; 12 mul, 8 add.
  Point(
    x: g.z * l.m.y - g.y * l.m.z + g.w * l.v.x,
    y: g.x * l.m.z - g.z * l.m.x + g.w * l.v.y,
    z: g.y * l.m.x - g.x * l.m.y + g.w * l.v.z,
    w: -g.x * l.v.x - g.y * l.v.y - g.z * l.v.z,
  )

func wedgeAnti*(k, l: Line): float {.inline.} =
  ## Meet lines in scalar measuring their crossing, i.e. 𝐤 ∨ 𝐥; 6 mul, 5 add.
  -(dot(k.v, l.m)) - dot(k.m, l.v)

func wedgeAnti*(p: Point, g: Plane): float {.inline.} =
  ## Meet point and plane in scalar measuring incidence, i.e. 𝐩 ∨ 𝐠; 4 mul, 3 add.
  p.x * g.x + p.y * g.y + p.z * g.z + p.w * g.w



#[ Inner Products ]#

func dot*(a, b: Point): float {.inline.} =
  ## Multiply points through inner product of their bulks, i.e. 𝐚 ∙ 𝐛; 3 mul, 2 add.
  a.x * b.x + a.y * b.y + a.z * b.z

func dot*(k, l: Line): float {.inline.} =
  ## Multiply lines through inner product of their moments, i.e. 𝐤 ∙ 𝐥; 3 mul, 2 add.
  dot(k.m, l.m)

func dot*(g, h: Plane): float {.inline.} =
  ## Multiply planes through inner product of their positions, i.e. 𝐠 ∙ 𝐡; 1 mul.
  g.w * h.w

func dotAnti*(a, b: Point): Antiscalar {.inline.} =
  ## Multiply points through inner antiproduct of their weights, i.e. 𝐚 ∘ 𝐛; 1 mul.
  Antiscalar(a.w * b.w)

func dotAnti*(k, l: Line): Antiscalar {.inline.} =
  ## Multiply lines through inner antiproduct of their directions, i.e. 𝐤 ∘ 𝐥; 3 mul, 2 add.
  Antiscalar(dot(k.v, l.v))

func dotAnti*(g, h: Plane): Antiscalar {.inline.} =
  ## Multiply planes through inner antiproduct of their normals, i.e. 𝐠 ∘ 𝐡; 3 mul, 2 add.
  Antiscalar(g.x * h.x + g.y * h.y + g.z * h.z)



#[ Complements ]#

func complementRight*(p: Point): Plane {.inline.} =
  ## Get right complement 𝐩̅, i.e. same components read as plane; 0 mul.
  Plane(x: p.x, y: p.y, z: p.z, w: p.w)

func complementLeft*(p: Point): Plane {.inline.} =
  ## Get left complement 𝐩̲, i.e. negated plane; 0 mul.
  Plane(x: -p.x, y: -p.y, z: -p.z, w: -p.w)

func complementRight*(l: Line): Line {.inline.} =
  ## Get right complement 𝐥̅, i.e. direction and moment swapped and negated; 0 mul.
  Line(v: -l.m, m: -l.v)

func complementLeft*(l: Line): Line {.inline.} =
  ## Get left complement 𝐥̲, equal to right one for lines; 0 mul.
  Line(v: -l.m, m: -l.v)

func complementRight*(g: Plane): Point {.inline.} =
  ## Get right complement 𝐠̅, i.e. negated point; 0 mul.
  Point(x: -g.x, y: -g.y, z: -g.z, w: -g.w)

func complementLeft*(g: Plane): Point {.inline.} =
  ## Get left complement 𝐠̲, i.e. same components read as point; 0 mul.
  Point(x: g.x, y: g.y, z: g.z, w: g.w)



#[ Reverses ]#

func reverse*(p: Point): Point {.inline.} =
  ## Get reverse 𝐩̃, identity on grade 1; 0 mul.
  p

func reverse*(l: Line): Line {.inline.} =
  ## Get reverse 𝐥̃, negation on grade 2; 0 mul.
  Line(v: -l.v, m: -l.m)

func reverse*(g: Plane): Plane {.inline.} =
  ## Get reverse 𝐠̃, negation on grade 3; 0 mul.
  Plane(x: -g.x, y: -g.y, z: -g.z, w: -g.w)

func reverseAnti*(p: Point): Point {.inline.} =
  ## Get antireverse 𝐩̰, negation on antigrade 3; 0 mul.
  Point(x: -p.x, y: -p.y, z: -p.z, w: -p.w)

func reverseAnti*(l: Line): Line {.inline.} =
  ## Get antireverse 𝐥̰, negation on antigrade 2; 0 mul.
  Line(v: -l.v, m: -l.m)

func reverseAnti*(g: Plane): Plane {.inline.} =
  ## Get antireverse 𝐠̰, identity on antigrade 1; 0 mul.
  g



#[ Duals ]#

func dualBulk*(p: Point): Plane {.inline.} =
  ## Get bulk dual 𝐩★, i.e. right complement of bulk; 0 mul.
  Plane(x: p.x, y: p.y, z: p.z, w: 0.0)

func dualBulk*(l: Line): Line {.inline.} =
  ## Get bulk dual 𝐥★; 0 mul.
  Line(v: -l.m, m: zero3)

func dualBulk*(g: Plane): Point {.inline.} =
  ## Get bulk dual 𝐠★; 0 mul.
  Point(x: 0.0, y: 0.0, z: 0.0, w: -g.w)

func dualWeight*(p: Point): Plane {.inline.} =
  ## Get weight dual 𝐩☆, i.e. right complement of weight; 0 mul.
  Plane(x: 0.0, y: 0.0, z: 0.0, w: p.w)

func dualWeight*(l: Line): Line {.inline.} =
  ## Get weight dual 𝐥☆; 0 mul.
  Line(v: zero3, m: -l.v)

func dualWeight*(g: Plane): Point {.inline.} =
  ## Get weight dual 𝐠☆; 0 mul.
  Point(x: -g.x, y: -g.y, z: -g.z, w: 0.0)



#[ Parts ]#

func bulk*(p: Point): Point {.inline.} =
  ## Extract bulk 𝐩∙, i.e. components without e₄; 0 mul.
  Point(x: p.x, y: p.y, z: p.z, w: 0.0)

func weight*(p: Point): Point {.inline.} =
  ## Extract weight 𝐩∘, i.e. components with e₄; 0 mul.
  Point(x: 0.0, y: 0.0, z: 0.0, w: p.w)

func bulk*(l: Line): Line {.inline.} =
  ## Extract bulk 𝐥∙, i.e. moment; 0 mul.
  Line(v: zero3, m: read3(l.m))

func weight*(l: Line): Line {.inline.} =
  ## Extract weight 𝐥∘, i.e. direction; 0 mul.
  Line(v: read3(l.v), m: zero3)

func bulk*(g: Plane): Plane {.inline.} =
  ## Extract bulk 𝐠∙, i.e. position; 0 mul.
  Plane(x: 0.0, y: 0.0, z: 0.0, w: g.w)

func weight*(g: Plane): Plane {.inline.} =
  ## Extract weight 𝐠∘, i.e. normal; 0 mul.
  Plane(x: g.x, y: g.y, z: g.z, w: 0.0)



#[ Attitudes ]#

func attitude*(p: Point): float {.inline.} =
  ## Get attitude of point, i.e. 𝐩 ∨ 𝐞̅₄, its weight as scalar; 0 mul.
  p.w

func attitude*(l: Line): Point {.inline.} =
  ## Get attitude of line, i.e. its direction as point at infinity; 0 mul.
  Point(x: l.v.x, y: l.v.y, z: l.v.z, w: 0.0)

func attitude*(g: Plane): Line {.inline.} =
  ## Get attitude of plane, i.e. its normal as line at infinity; 0 mul.
  Line(v: zero3, m: Vector3(x: g.x, y: g.y, z: g.z))



#[ Norms ]#

func normBulkSquared*(p: Point): float {.inline.} =
  ## Get squared bulk norm 𝐩 ∙ 𝐩; 3 mul, 2 add.
  p.x * p.x + p.y * p.y + p.z * p.z

func normWeightSquared*(p: Point): float {.inline.} =
  ## Get squared weight norm 𝐩 ∘ 𝐩; 1 mul.
  p.w * p.w

func normBulkSquared*(l: Line): float {.inline.} =
  ## Get squared bulk norm 𝐥 ∙ 𝐥; 3 mul, 2 add.
  dot(l.m, l.m)

func normWeightSquared*(l: Line): float {.inline.} =
  ## Get squared weight norm 𝐥 ∘ 𝐥; 3 mul, 2 add.
  dot(l.v, l.v)

func normBulkSquared*(g: Plane): float {.inline.} =
  ## Get squared bulk norm 𝐠 ∙ 𝐠; 1 mul.
  g.w * g.w

func normWeightSquared*(g: Plane): float {.inline.} =
  ## Get squared weight norm 𝐠 ∘ 𝐠; 3 mul, 2 add.
  g.x * g.x + g.y * g.y + g.z * g.z

func normBulk*(p: Point): float {.inline.} =
  ## Get bulk norm ‖𝐩‖∙; 3 mul, 2 add, 1 sqrt.
  sqrt(p.x * p.x + p.y * p.y + p.z * p.z)

func normWeight*(p: Point): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐩‖∘, i.e. |w|; 1 abs.
  Antiscalar(abs(p.w))

func normBulk*(l: Line): float {.inline.} =
  ## Get bulk norm ‖𝐥‖∙; 3 mul, 2 add, 1 sqrt.
  sqrt(dot(l.m, l.m))

func normWeight*(l: Line): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐥‖∘; 3 mul, 2 add, 1 sqrt.
  Antiscalar(sqrt(dot(l.v, l.v)))

func normBulk*(g: Plane): float {.inline.} =
  ## Get bulk norm ‖𝐠‖∙, i.e. |w|; 1 abs.
  abs(g.w)

func normWeight*(g: Plane): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐠‖∘; 3 mul, 2 add, 1 sqrt.
  Antiscalar(sqrt(g.x * g.x + g.y * g.y + g.z * g.z))



#[ Unitizations ]#

func unitize*(p: Point): Point {.inline.} =
  ## Unitize point so w = 1, i.e. 𝐩 / ‖𝐩‖∘; 1 div, 3 mul.
  ##   No-op where weight is zero, as library's unitize is.
  if p.w == 0.0: return p
  let n = 1.0 / p.w
  Point(x: p.x * n, y: p.y * n, z: p.z * n, w: 1.0)

func unitize*(l: Line): Line {.inline.} =
  ## Unitize line so direction has unit length, i.e. 𝐥 / ‖𝐥‖∘; 3 mul, 2 add, 1 rsqrt, 6 mul.
  ##   No-op where weight is zero.
  let s = dot(l.v, l.v)
  if s == 0.0: return l
  let n = 1.0 / sqrt(s)
  Line(v: l.v * n, m: l.m * n)

func unitize*(g: Plane): Plane {.inline.} =
  ## Unitize plane so normal has unit length, i.e. 𝐠 / ‖𝐠‖∘; 3 mul, 2 add, 1 rsqrt, 4 mul.
  ##   No-op where weight is zero.
  let s = g.x * g.x + g.y * g.y + g.z * g.z
  if s == 0.0: return g
  let n = 1.0 / sqrt(s)
  Plane(x: g.x * n, y: g.y * n, z: g.z * n, w: g.w * n)



#[ Supports ]#

func support*(l: Line): Point {.inline.} =
  ## Get support of line, i.e. point on it closest to origin; 9 mul, 5 add.
  Point(
    x: l.v.y * l.m.z - l.v.z * l.m.y,
    y: l.v.z * l.m.x - l.v.x * l.m.z,
    z: l.v.x * l.m.y - l.v.y * l.m.x,
    w: dot(l.v, l.v),
  )

func support*(g: Plane): Point {.inline.} =
  ## Get support of plane, i.e. point on it closest to origin; 6 mul, 2 add.
  Point(x: -g.x * g.w, y: -g.y * g.w, z: -g.z * g.w, w: g.x * g.x + g.y * g.y + g.z * g.z)

func supportAnti*(p: Point): Plane {.inline.} =
  ## Get antisupport of point, i.e. plane through it farthest from origin; 6 mul, 2 add.
  Plane(x: -p.x * p.w, y: -p.y * p.w, z: -p.z * p.w, w: p.x * p.x + p.y * p.y + p.z * p.z)

func supportAnti*(l: Line): Plane {.inline.} =
  ## Get antisupport of line, i.e. plane containing it farthest from origin; 9 mul, 5 add.
  Plane(
    x: l.v.z * l.m.y - l.v.y * l.m.z,
    y: l.v.x * l.m.z - l.v.z * l.m.x,
    z: l.v.y * l.m.x - l.v.x * l.m.y,
    w: dot(l.m, l.m),
  )



#[ Projections ]#

func projectOrthogonal*(p: Point, g: Plane): Point {.inline.} =
  ## Project point orthogonally onto plane, homogeneous, i.e. 𝐠 ∨ (𝐩 ∧ 𝐠☆); 12 mul, 8 add.
  ##   Result is (𝐠∘ ∙ 𝐠∘) 𝐩 − 𝐠∘ (𝐩 ∨ 𝐠) on position, weight scaled alike.
  let
    s = g.x * g.x + g.y * g.y + g.z * g.z
    d = p.x * g.x + p.y * g.y + p.z * g.z + p.w * g.w
  Point(x: p.x * s - g.x * d, y: p.y * s - g.y * d, z: p.z * s - g.z * d, w: p.w * s)

func projectOrthogonal*(p: Point, l: Line): Point {.inline.} =
  ## Project point orthogonally onto line, homogeneous, i.e. 𝐥 ∨ (𝐩 ∧ 𝐥☆); 21 mul, 12 add.
  ##   Position is (𝐥∘ ∙ 𝐩) 𝐥ᵛ + w (𝐥ᵛ × 𝐥ᵐ), weight is w (𝐥ᵛ ∙ 𝐥ᵛ).
  let
    d = l.v.x * p.x + l.v.y * p.y + l.v.z * p.z
    c = cross(l.v, l.m)
  Point(
    x: d * l.v.x + p.w * c.x,
    y: d * l.v.y + p.w * c.y,
    z: d * l.v.z + p.w * c.z,
    w: p.w * dot(l.v, l.v),
  )

func projectOrthogonal*(l: Line, g: Plane): Line {.inline.} =
  ## Project line orthogonally onto plane, homogeneous, i.e. 𝐠 ∨ (𝐥 ∧ 𝐠☆); 30 mul, 18 add.
  ##   Direction is (𝐠∘ ∙ 𝐠∘) 𝐥ᵛ − 𝐠∘ (𝐠∘ ∙ 𝐥ᵛ); moment is
  ##   𝐠∘ (𝐠∘ ∙ 𝐥ᵐ) − (𝐠∘ × 𝐥ᵛ) gʷ... derived, held to library by suite.
  let
    n = Vector3(x: g.x, y: g.y, z: g.z)
    s = dot(n, n)
    dot_direction = dot(n, l.v)
    dot_moment = dot(n, l.m)
    c = cross(n, l.v)
  Line(v: l.v * s - n * dot_direction, m: n * dot_moment - c * g.w)



#[ Motors ]#

func wedgeDotAnti*(a, b: Motor): Motor {.inline.} =
  ## Compose motors through geometric antiproduct, i.e. 𝐚 ⟇ 𝐛; 48 mul, 40 add.
  Motor(
    v: Vector3(
      x: a.vw * b.v.x + a.v.x * b.vw + a.v.y * b.v.z - a.v.z * b.v.y,
      y: a.vw * b.v.y + a.v.y * b.vw + a.v.z * b.v.x - a.v.x * b.v.z,
      z: a.vw * b.v.z + a.v.z * b.vw + a.v.x * b.v.y - a.v.y * b.v.x,
    ),
    vw: a.vw * b.vw - a.v.x * b.v.x - a.v.y * b.v.y - a.v.z * b.v.z,
    m: Vector3(
      x: a.mw * b.v.x + a.m.x * b.vw + a.m.y * b.v.z - a.m.z * b.v.y +
          b.mw * a.v.x + b.m.x * a.vw - b.m.y * a.v.z + b.m.z * a.v.y,
      y: a.mw * b.v.y - a.m.x * b.v.z + a.m.y * b.vw + a.m.z * b.v.x +
          b.mw * a.v.y + b.m.x * a.v.z + b.m.y * a.vw - b.m.z * a.v.x,
      z: a.mw * b.v.z + a.m.x * b.v.y - a.m.y * b.v.x + a.m.z * b.vw +
          b.mw * a.v.z - b.m.x * a.v.y + b.m.y * a.v.x + b.m.z * a.vw,
    ),
    mw: a.mw * b.vw - a.m.x * b.v.x - a.m.y * b.v.y - a.m.z * b.v.z +
        b.mw * a.vw - b.m.x * a.v.x - b.m.y * a.v.y - b.m.z * a.v.z,
  )

func reverseAnti*(q: Motor): Motor {.inline.} =
  ## Get antireverse 𝐐̰, negating antigrade-2 parts v and m; 0 mul.
  Motor(v: -q.v, m: -q.m, vw: q.vw, mw: q.mw)

func reverse*(q: Motor): Motor {.inline.} =
  ## Get reverse 𝐐̃, negating grade-2 parts v and m; 0 mul.
  Motor(v: -q.v, m: -q.m, vw: q.vw, mw: q.mw)

func normWeightSquared*(q: Motor): float {.inline.} =
  ## Get squared weight norm 𝐐 ∘ 𝐐; 4 mul, 3 add.
  dot(q.v, q.v) + q.vw * q.vw

func normBulkSquared*(q: Motor): float {.inline.} =
  ## Get squared bulk norm 𝐐 ∙ 𝐐; 4 mul, 3 add.
  dot(q.m, q.m) + q.mw * q.mw

func normWeight*(q: Motor): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐐‖∘; 4 mul, 3 add, 1 sqrt.
  Antiscalar(sqrt(dot(q.v, q.v) + q.vw * q.vw))

func normBulk*(q: Motor): float {.inline.} =
  ## Get bulk norm ‖𝐐‖∙; 4 mul, 3 add, 1 sqrt.
  sqrt(dot(q.m, q.m) + q.mw * q.mw)

func unitize*(q: Motor): Motor {.inline.} =
  ## Unitize motor so weight norm is 𝟙; 4 mul, 3 add, 1 rsqrt, 8 mul.
  ##   No-op where weight is zero.
  let s = dot(q.v, q.v) + q.vw * q.vw
  if s == 0.0: return q
  let n = 1.0 / sqrt(s)
  Motor(v: q.v * n, m: q.m * n, vw: q.vw * n, mw: q.mw * n)

func translation*(q: Motor): Vector3 {.inline.} =
  ## Get translation unit motor carries, i.e. 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ + Qᵛ × Qᵐ); 12 mul, 9 add.
  (q.m * q.vw - q.v * q.mw + cross(q.v, q.m)) * 2.0

func transform*(p: Point, q: Motor): Point {.inline.} =
  ## Move point by unit motor, i.e. 𝐐 ⟇ 𝐩 ⟇ 𝐐̰; 25 mul, 18 add.
  ##   Rotation and translation in one pass: `a` = Qᵛ × 𝐩 + Qᵐ w,
  ##   𝐩' = 𝐩 + 2(Qᵛ × `a` + `a` Qᵛʷ − Qᵛ Qᵐʷ w).
  let
    x = Vector3(x: p.x, y: p.y, z: p.z)
    a = cross(q.v, x) + q.m * p.w
    u = cross(q.v, a) + a * q.vw - q.v * (q.mw * p.w)
  Point(x: p.x + 2.0 * u.x, y: p.y + 2.0 * u.y, z: p.z + 2.0 * u.z, w: p.w)

func transform*(l: Line, q: Motor): Line {.inline.} =
  ## Move line by unit motor, i.e. 𝐐 ⟇ 𝐥 ⟇ 𝐐̰; 54 mul, 36 add.
  ##   Direction rotates; moment rotates and gains 𝐭 × direction.
  let
    v = rotate(l.v, q.v, q.vw)
    m = rotate(l.m, q.v, q.vw)
    t = (q.m * q.vw - q.v * q.mw + cross(q.v, q.m)) * 2.0
  Line(v: read3(v), m: m + cross(t, v))

func transform*(g: Plane, q: Motor): Plane {.inline.} =
  ## Move plane by unit motor, i.e. 𝐐 ⟇ 𝐠 ⟇ 𝐐̰; 33 mul, 23 add.
  ##   Normal rotates; position loses normal ∙ 𝐭.
  let
    n = rotate(Vector3(x: g.x, y: g.y, z: g.z), q.v, q.vw)
    t = (q.m * q.vw - q.v * q.mw + cross(q.v, q.m)) * 2.0
  Plane(x: n.x, y: n.y, z: n.z, w: g.w - dot(n, t))

func rotor*(axis: Vector3, angle: float): Motor {.inline.} =
  ## Construct rotation motor about unit axis through origin; 4 mul, 1 sin, 1 cos.
  let h = angle * 0.5
  Motor(v: axis * sin(h), m: zero3, vw: cos(h), mw: 0.0)

func translator*(t: Vector3): Motor {.inline.} =
  ## Construct translation motor by t, i.e. 𝟙 + (𝐭 / 2); 3 mul.
  Motor(v: zero3, m: t * 0.5, vw: 1.0, mw: 0.0)
