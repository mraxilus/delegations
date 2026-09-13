## Derive Lengyel's typed objects and hand-rolled operations of 3D rigid geometric algebra.
##   Reference every dense library operation is measured against: each object holds only
##   components its grade can carry, and each operation spells only terms that survive,
##   as optimal hand-written linear algebra does. Forms follow *Projective Geometric
##   Algebra Illuminated* and rigidgeometricalgebra.org; Terathon Math Library (MIT,
##   Eric Lengyel) was read to cross-check forms and counts, and nothing is copied from
##   it. Scalar is `float`, as library's, so both sides compute in same precision.
##
##   |---------|-------------------------------------------------|----------------------|
##   | Code    | Notation                                        | Library basis        |
##   |---------|-------------------------------------------------|----------------------|
##   | Point   | 𝐩 = pˣe₁ + pʸe₂ + pᶻe₃ + pʷe₄                    | E1 E2 E3 E4          |
##   | Line    | 𝐥 = lᵛ(e₄₁ e₄₂ e₄₃) + lᵐ(e₂₃ e₃₁ e₁₂)            | E41 E42 E43 E23 E31 E12 |
##   | Plane   | 𝐠 = gˣe₄₂₃ + gʸe₄₃₁ + gᶻe₄₁₂ + gʷe₃₂₁            | E423 E431 E412 E321  |
##   | Motor   | 𝐐 = Qᵛ + Qᵛʷ𝟙 + Qᵐ + Qᵐʷ𝟏                       | E41..E12, E1234, S   |
##   | Scalar  | s𝟏                                              | S                    |
##   | Antisc. | t𝟙                                              | E1234                |
##   |---------|-------------------------------------------------|----------------------|
##
##   Each operation's doc states multiply and add counts of its form, i.e. what optimal
##     code spends; suite `Inspector` reads those counts back from emitted C.
##   Motor transforms are derived, not transcribed: rotation by quaternion (Qᵛ, Qᵛʷ),
##     translation 𝐭 = 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ + Qᵛ × Qᵐ), which is what antisandwich
##     𝐐 ⟇ 𝐩 ⟇ 𝐐̰ spells for unit motor; suite `Chapter 3` holds them to library.
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
  Vec3* = object
    ## Define three components named as vector; direction, moment or normal.
    x*, y*, z*: float
  Point* = object
    ## Define point 𝐩 with homogeneous weight w; grade 1.
    x*, y*, z*, w*: float
  Line* = object
    ## Define line 𝐥 with direction v and moment m; grade 2.
    v*, m*: Vec3
  Plane* = object
    ## Define plane 𝐠 with normal (x y z) and position w; grade 3.
    x*, y*, z*, w*: float
  Motor* = object
    ## Define motor 𝐐 with weight (v, vw) and bulk (m, mw); even grades.
    v*, m*: Vec3
    vw*, mw*: float



#[ Vector Helpers ]#

func cross*(a, b: Vec3): Vec3 {.inline.} =
  ## Cross product, i.e. 𝐚 × 𝐛; 6 mul, 3 sub.
  Vec3(x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x)

func dot*(a, b: Vec3): float {.inline.} =
  ## Dot product, i.e. 𝐚 ∙ 𝐛; 3 mul, 2 add.
  a.x * b.x + a.y * b.y + a.z * b.z

func `+`*(a, b: Vec3): Vec3 {.inline.} =
  ## Sum of vectors; 3 add.
  Vec3(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)

func `-`*(a, b: Vec3): Vec3 {.inline.} =
  ## Difference of vectors; 3 sub.
  Vec3(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)

func `-`*(a: Vec3): Vec3 {.inline.} =
  ## Negated vector; 0 mul.
  Vec3(x: -a.x, y: -a.y, z: -a.z)

func `*`*(a: Vec3; s: float): Vec3 {.inline.} =
  ## Vector scaled; 3 mul.
  Vec3(x: a.x * s, y: a.y * s, z: a.z * s)

func rotate(x: Vec3; v: Vec3; vw: float): Vec3 {.inline.} =
  ## Rotate vector by unit quaternion (v, vw), i.e. x + 2(vw v × x + v × (v × x)).
  ##   18 mul, 12 add.
  let c = cross(v, x)
  x + (c * vw + cross(v, c)) * 2.0



#[ Exterior Products ]#

func wedge*(p, q: Point): Line =
  ## Join points into line through both, i.e. 𝐩 ∧ 𝐪; 12 mul, 6 sub.
  Line(
    v: Vec3(x: p.w * q.x - p.x * q.w, y: p.w * q.y - p.y * q.w, z: p.w * q.z - p.z * q.w),
    m: Vec3(x: p.y * q.z - p.z * q.y, y: p.z * q.x - p.x * q.z, z: p.x * q.y - p.y * q.x),
  )

func wedge*(l: Line; p: Point): Plane =
  ## Join line and point into plane containing both, i.e. 𝐥 ∧ 𝐩; 12 mul, 8 add.
  Plane(
    x: l.v.y * p.z - l.v.z * p.y + l.m.x * p.w,
    y: l.v.z * p.x - l.v.x * p.z + l.m.y * p.w,
    z: l.v.x * p.y - l.v.y * p.x + l.m.z * p.w,
    w: -l.m.x * p.x - l.m.y * p.y - l.m.z * p.z,
  )

func wedge*(p: Point; l: Line): Plane {.inline.} =
  ## Join point and line, i.e. 𝐩 ∧ 𝐥 = 𝐥 ∧ 𝐩 since grades 1 and 2 commute; 12 mul, 8 add.
  wedge(l, p)

func wedgeAnti*(g, h: Plane): Line =
  ## Meet planes in line, i.e. 𝐠 ∨ 𝐡; 12 mul, 6 sub.
  Line(
    v: Vec3(x: g.z * h.y - g.y * h.z, y: g.x * h.z - g.z * h.x, z: g.y * h.x - g.x * h.y),
    m: Vec3(x: g.x * h.w - g.w * h.x, y: g.y * h.w - g.w * h.y, z: g.z * h.w - g.w * h.z),
  )

func wedgeAnti*(g: Plane; l: Line): Point =
  ## Meet plane and line in point, i.e. 𝐠 ∨ 𝐥; 12 mul, 8 add.
  Point(
    x: l.m.y * g.z - l.m.z * g.y + l.v.x * g.w,
    y: l.m.z * g.x - l.m.x * g.z + l.v.y * g.w,
    z: l.m.x * g.y - l.m.y * g.x + l.v.z * g.w,
    w: -l.v.x * g.x - l.v.y * g.y - l.v.z * g.z,
  )

func wedgeAnti*(l: Line; g: Plane): Point {.inline.} =
  ## Meet line and plane, i.e. 𝐥 ∨ 𝐠 = 𝐠 ∨ 𝐥 since antigrades 1 and 2 commute; 12 mul.
  wedgeAnti(g, l)

func wedgeAnti*(k, l: Line): float =
  ## Meet lines in scalar measuring their crossing, i.e. 𝐤 ∨ 𝐥; 6 mul, 5 add.
  -(dot(k.v, l.m)) - dot(k.m, l.v)

func wedgeAnti*(p: Point; g: Plane): float =
  ## Meet point and plane in scalar measuring incidence, i.e. 𝐩 ∨ 𝐠; 4 mul, 3 add.
  p.x * g.x + p.y * g.y + p.z * g.z + p.w * g.w



#[ Inner Products ]#

func dot*(a, b: Point): float {.inline.} =
  ## Inner product of points through bulks, i.e. 𝐚 ∙ 𝐛; 3 mul, 2 add.
  a.x * b.x + a.y * b.y + a.z * b.z

func dot*(k, l: Line): float {.inline.} =
  ## Inner product of lines through moments, i.e. 𝐤 ∙ 𝐥; 3 mul, 2 add.
  dot(k.m, l.m)

func dot*(g, h: Plane): float {.inline.} =
  ## Inner product of planes through positions, i.e. 𝐠 ∙ 𝐡; 1 mul.
  g.w * h.w

func dotAnti*(a, b: Point): Antiscalar {.inline.} =
  ## Inner antiproduct of points through weights, i.e. 𝐚 ∘ 𝐛; 1 mul.
  Antiscalar(a.w * b.w)

func dotAnti*(k, l: Line): Antiscalar {.inline.} =
  ## Inner antiproduct of lines through directions, i.e. 𝐤 ∘ 𝐥; 3 mul, 2 add.
  Antiscalar(dot(k.v, l.v))

func dotAnti*(g, h: Plane): Antiscalar {.inline.} =
  ## Inner antiproduct of planes through normals, i.e. 𝐠 ∘ 𝐡; 3 mul, 2 add.
  Antiscalar(g.x * h.x + g.y * h.y + g.z * h.z)



#[ Complements, Reverses, Duals ]#

func complementRight*(p: Point): Plane {.inline.} =
  ## Right complement 𝐩̅, i.e. same components read as plane; 0 mul.
  Plane(x: p.x, y: p.y, z: p.z, w: p.w)

func complementLeft*(p: Point): Plane {.inline.} =
  ## Left complement 𝐩̲, i.e. negated plane; 0 mul.
  Plane(x: -p.x, y: -p.y, z: -p.z, w: -p.w)

func complementRight*(l: Line): Line {.inline.} =
  ## Right complement 𝐥̅, i.e. direction and moment swapped and negated; 0 mul.
  Line(v: -l.m, m: -l.v)

func complementLeft*(l: Line): Line {.inline.} =
  ## Left complement 𝐥̲, equal to right one for lines; 0 mul.
  Line(v: -l.m, m: -l.v)

func complementRight*(g: Plane): Point {.inline.} =
  ## Right complement 𝐠̅, i.e. negated point; 0 mul.
  Point(x: -g.x, y: -g.y, z: -g.z, w: -g.w)

func complementLeft*(g: Plane): Point {.inline.} =
  ## Left complement 𝐠̲, i.e. same components read as point; 0 mul.
  Point(x: g.x, y: g.y, z: g.z, w: g.w)

func reverse*(p: Point): Point {.inline.} =
  ## Reverse 𝐩̃, identity on grade 1; 0 mul.
  p

func reverse*(l: Line): Line {.inline.} =
  ## Reverse 𝐥̃, negation on grade 2; 0 mul.
  Line(v: -l.v, m: -l.m)

func reverse*(g: Plane): Plane {.inline.} =
  ## Reverse 𝐠̃, negation on grade 3; 0 mul.
  Plane(x: -g.x, y: -g.y, z: -g.z, w: -g.w)

func reverseAnti*(p: Point): Point {.inline.} =
  ## Antireverse 𝐩̰, negation on antigrade 3; 0 mul.
  Point(x: -p.x, y: -p.y, z: -p.z, w: -p.w)

func reverseAnti*(l: Line): Line {.inline.} =
  ## Antireverse 𝐥̰, negation on antigrade 2; 0 mul.
  Line(v: -l.v, m: -l.m)

func reverseAnti*(g: Plane): Plane {.inline.} =
  ## Antireverse 𝐠̰, identity on antigrade 1; 0 mul.
  g

func dualBulk*(p: Point): Plane {.inline.} =
  ## Bulk dual 𝐩★, i.e. right complement of bulk; 0 mul.
  Plane(x: p.x, y: p.y, z: p.z, w: 0.0)

func dualBulk*(l: Line): Line {.inline.} =
  ## Bulk dual 𝐥★; 0 mul.
  Line(v: -l.m, m: Vec3())

func dualBulk*(g: Plane): Point {.inline.} =
  ## Bulk dual 𝐠★; 0 mul.
  Point(x: 0.0, y: 0.0, z: 0.0, w: -g.w)

func dualWeight*(p: Point): Plane {.inline.} =
  ## Weight dual 𝐩☆, i.e. right complement of weight; 0 mul.
  Plane(x: 0.0, y: 0.0, z: 0.0, w: p.w)

func dualWeight*(l: Line): Line {.inline.} =
  ## Weight dual 𝐥☆; 0 mul.
  Line(v: Vec3(), m: -l.v)

func dualWeight*(g: Plane): Point {.inline.} =
  ## Weight dual 𝐠☆; 0 mul.
  Point(x: -g.x, y: -g.y, z: -g.z, w: 0.0)



#[ Bulk, Weight, Attitude ]#

func bulk*(p: Point): Point {.inline.} =
  ## Bulk 𝐩∙, i.e. components without e₄; 0 mul.
  Point(x: p.x, y: p.y, z: p.z, w: 0.0)

func weight*(p: Point): Point {.inline.} =
  ## Weight 𝐩∘, i.e. components with e₄; 0 mul.
  Point(x: 0.0, y: 0.0, z: 0.0, w: p.w)

func bulk*(l: Line): Line {.inline.} =
  ## Bulk 𝐥∙, i.e. moment; 0 mul.
  Line(v: Vec3(), m: l.m)

func weight*(l: Line): Line {.inline.} =
  ## Weight 𝐥∘, i.e. direction; 0 mul.
  Line(v: l.v, m: Vec3())

func bulk*(g: Plane): Plane {.inline.} =
  ## Bulk 𝐠∙, i.e. position; 0 mul.
  Plane(x: 0.0, y: 0.0, z: 0.0, w: g.w)

func weight*(g: Plane): Plane {.inline.} =
  ## Weight 𝐠∘, i.e. normal; 0 mul.
  Plane(x: g.x, y: g.y, z: g.z, w: 0.0)

func attitude*(p: Point): float {.inline.} =
  ## Attitude of point, i.e. 𝐩 ∨ 𝐞̅₄, its weight as scalar; 0 mul.
  p.w

func attitude*(l: Line): Point {.inline.} =
  ## Attitude of line, i.e. its direction as point at infinity; 0 mul.
  Point(x: l.v.x, y: l.v.y, z: l.v.z, w: 0.0)

func attitude*(g: Plane): Line {.inline.} =
  ## Attitude of plane, i.e. its normal as line at infinity; 0 mul.
  Line(v: Vec3(), m: Vec3(x: g.x, y: g.y, z: g.z))



#[ Norms, Unitize ]#

func normBulkSquared*(p: Point): float {.inline.} =
  ## Squared bulk norm 𝐩 ∙ 𝐩; 3 mul, 2 add.
  p.x * p.x + p.y * p.y + p.z * p.z

func normWeightSquared*(p: Point): float {.inline.} =
  ## Squared weight norm 𝐩 ∘ 𝐩; 1 mul.
  p.w * p.w

func normBulkSquared*(l: Line): float {.inline.} =
  ## Squared bulk norm 𝐥 ∙ 𝐥; 3 mul, 2 add.
  dot(l.m, l.m)

func normWeightSquared*(l: Line): float {.inline.} =
  ## Squared weight norm 𝐥 ∘ 𝐥; 3 mul, 2 add.
  dot(l.v, l.v)

func normBulkSquared*(g: Plane): float {.inline.} =
  ## Squared bulk norm 𝐠 ∙ 𝐠; 1 mul.
  g.w * g.w

func normWeightSquared*(g: Plane): float {.inline.} =
  ## Squared weight norm 𝐠 ∘ 𝐠; 3 mul, 2 add.
  g.x * g.x + g.y * g.y + g.z * g.z

func normBulk*(p: Point): float {.inline.} =
  ## Bulk norm ‖𝐩‖∙; 3 mul, 2 add, 1 sqrt.
  sqrt(p.normBulkSquared)

func normWeight*(p: Point): Antiscalar {.inline.} =
  ## Weight norm ‖𝐩‖∘, i.e. |w|; 1 abs.
  Antiscalar(abs(p.w))

func normBulk*(l: Line): float {.inline.} =
  ## Bulk norm ‖𝐥‖∙; 3 mul, 2 add, 1 sqrt.
  sqrt(l.normBulkSquared)

func normWeight*(l: Line): Antiscalar {.inline.} =
  ## Weight norm ‖𝐥‖∘; 3 mul, 2 add, 1 sqrt.
  Antiscalar(sqrt(l.normWeightSquared))

func normBulk*(g: Plane): float {.inline.} =
  ## Bulk norm ‖𝐠‖∙, i.e. |w|; 1 abs.
  abs(g.w)

func normWeight*(g: Plane): Antiscalar {.inline.} =
  ## Weight norm ‖𝐠‖∘; 3 mul, 2 add, 1 sqrt.
  Antiscalar(sqrt(g.normWeightSquared))

func unitize*(p: Point): Point =
  ## Unitize point so w = 1, i.e. 𝐩 / ‖𝐩‖∘; 1 div, 3 mul.
  ##   No-op where weight is zero, as library's unitize is.
  if p.w == 0.0: return p
  let n = 1.0 / p.w
  Point(x: p.x * n, y: p.y * n, z: p.z * n, w: 1.0)

func unitize*(l: Line): Line =
  ## Unitize line so direction has unit length, i.e. 𝐥 / ‖𝐥‖∘; 3 mul, 2 add, 1 rsqrt, 6 mul.
  ##   No-op where weight is zero.
  let s = l.normWeightSquared
  if s == 0.0: return l
  let n = 1.0 / sqrt(s)
  Line(v: l.v * n, m: l.m * n)

func unitize*(g: Plane): Plane =
  ## Unitize plane so normal has unit length, i.e. 𝐠 / ‖𝐠‖∘; 3 mul, 2 add, 1 rsqrt, 4 mul.
  ##   No-op where weight is zero.
  let s = g.normWeightSquared
  if s == 0.0: return g
  let n = 1.0 / sqrt(s)
  Plane(x: g.x * n, y: g.y * n, z: g.z * n, w: g.w * n)



#[ Supports ]#

func support*(l: Line): Point =
  ## Support of line, i.e. point on it closest to origin; 9 mul, 5 add.
  Point(
    x: l.v.y * l.m.z - l.v.z * l.m.y,
    y: l.v.z * l.m.x - l.v.x * l.m.z,
    z: l.v.x * l.m.y - l.v.y * l.m.x,
    w: dot(l.v, l.v),
  )

func support*(g: Plane): Point =
  ## Support of plane, i.e. point on it closest to origin; 6 mul, 2 add.
  Point(x: -g.x * g.w, y: -g.y * g.w, z: -g.z * g.w, w: g.x * g.x + g.y * g.y + g.z * g.z)

func supportAnti*(p: Point): Plane =
  ## Antisupport of point, i.e. plane through it farthest from origin; 6 mul, 2 add.
  Plane(x: -p.x * p.w, y: -p.y * p.w, z: -p.z * p.w, w: p.x * p.x + p.y * p.y + p.z * p.z)

func supportAnti*(l: Line): Plane =
  ## Antisupport of line, i.e. plane containing it farthest from origin; 9 mul, 5 add.
  Plane(
    x: l.v.z * l.m.y - l.v.y * l.m.z,
    y: l.v.x * l.m.z - l.v.z * l.m.x,
    z: l.v.y * l.m.x - l.v.x * l.m.y,
    w: dot(l.m, l.m),
  )



#[ Projections ]#

func projectOrthogonal*(p: Point; g: Plane): Point =
  ## Project point orthogonally onto plane, homogeneous, i.e. 𝐠 ∨ (𝐩 ∧ 𝐠☆); 12 mul, 8 add.
  ##   Result is (𝐠∘ ∙ 𝐠∘) 𝐩 − 𝐠∘ (𝐩 ∨ 𝐠) on position, weight scaled alike.
  let s = g.x * g.x + g.y * g.y + g.z * g.z
  let d = p.x * g.x + p.y * g.y + p.z * g.z + p.w * g.w
  Point(x: p.x * s - g.x * d, y: p.y * s - g.y * d, z: p.z * s - g.z * d, w: p.w * s)

func projectOrthogonal*(p: Point; l: Line): Point =
  ## Project point orthogonally onto line, homogeneous, i.e. 𝐥 ∨ (𝐩 ∧ 𝐥☆); 21 mul, 12 add.
  ##   Position is (𝐥∘ ∙ 𝐩) 𝐥ᵛ + w (𝐥ᵛ × 𝐥ᵐ), weight is w (𝐥ᵛ ∙ 𝐥ᵛ).
  let d = l.v.x * p.x + l.v.y * p.y + l.v.z * p.z
  let c = cross(l.v, l.m)
  Point(
    x: d * l.v.x + p.w * c.x,
    y: d * l.v.y + p.w * c.y,
    z: d * l.v.z + p.w * c.z,
    w: p.w * dot(l.v, l.v),
  )

func projectOrthogonal*(l: Line; g: Plane): Line =
  ## Project line orthogonally onto plane, homogeneous, i.e. 𝐠 ∨ (𝐥 ∧ 𝐠☆); 30 mul, 18 add.
  ##   Direction is (𝐠∘ ∙ 𝐠∘) 𝐥ᵛ − 𝐠∘ (𝐠∘ ∙ 𝐥ᵛ); moment is
  ##   𝐠∘ (𝐠∘ ∙ 𝐥ᵐ) − (𝐠∘ × 𝐥ᵛ) gʷ... derived, held to library by suite.
  let n = Vec3(x: g.x, y: g.y, z: g.z)
  let s = dot(n, n)
  let dv = dot(n, l.v)
  let dm = dot(n, l.m)
  let c = cross(n, l.v)
  Line(v: l.v * s - n * dv, m: n * dm - c * g.w)



#[ Motors ]#

func wedgeDotAnti*(a, b: Motor): Motor =
  ## Compose motors through geometric antiproduct, i.e. 𝐚 ⟇ 𝐛; 48 mul, 40 add.
  Motor(
    v: Vec3(
      x: a.vw * b.v.x + a.v.x * b.vw + a.v.y * b.v.z - a.v.z * b.v.y,
      y: a.vw * b.v.y + a.v.y * b.vw + a.v.z * b.v.x - a.v.x * b.v.z,
      z: a.vw * b.v.z + a.v.z * b.vw + a.v.x * b.v.y - a.v.y * b.v.x,
    ),
    vw: a.vw * b.vw - a.v.x * b.v.x - a.v.y * b.v.y - a.v.z * b.v.z,
    m: Vec3(
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
  ## Antireverse 𝐐̰, negating antigrade-2 parts v and m; 0 mul.
  Motor(v: -q.v, m: -q.m, vw: q.vw, mw: q.mw)

func reverse*(q: Motor): Motor {.inline.} =
  ## Reverse 𝐐̃, negating grade-2 parts v and m; 0 mul.
  Motor(v: -q.v, m: -q.m, vw: q.vw, mw: q.mw)

func normWeightSquared*(q: Motor): float {.inline.} =
  ## Squared weight norm 𝐐 ∘ 𝐐; 4 mul, 3 add.
  dot(q.v, q.v) + q.vw * q.vw

func normBulkSquared*(q: Motor): float {.inline.} =
  ## Squared bulk norm 𝐐 ∙ 𝐐; 4 mul, 3 add.
  dot(q.m, q.m) + q.mw * q.mw

func normWeight*(q: Motor): Antiscalar {.inline.} =
  ## Weight norm ‖𝐐‖∘; 4 mul, 3 add, 1 sqrt.
  Antiscalar(sqrt(q.normWeightSquared))

func normBulk*(q: Motor): float {.inline.} =
  ## Bulk norm ‖𝐐‖∙; 4 mul, 3 add, 1 sqrt.
  sqrt(q.normBulkSquared)

func unitize*(q: Motor): Motor =
  ## Unitize motor so weight norm is 𝟙; 4 mul, 3 add, 1 rsqrt, 8 mul.
  ##   No-op where weight is zero.
  let s = q.normWeightSquared
  if s == 0.0: return q
  let n = 1.0 / sqrt(s)
  Motor(v: q.v * n, m: q.m * n, vw: q.vw * n, mw: q.mw * n)

func translation*(q: Motor): Vec3 {.inline.} =
  ## Translation unit motor carries, i.e. 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ + Qᵛ × Qᵐ); 12 mul, 9 add.
  (q.m * q.vw - q.v * q.mw + cross(q.v, q.m)) * 2.0

func transform*(p: Point; q: Motor): Point =
  ## Move point by unit motor, i.e. 𝐐 ⟇ 𝐩 ⟇ 𝐐̰; 25 mul, 18 add.
  ##   Rotation and translation in one pass: `a` = Qᵛ × 𝐩 + Qᵐ w,
  ##   𝐩' = 𝐩 + 2(Qᵛ × `a` + `a` Qᵛʷ − Qᵛ Qᵐʷ w).
  let x = Vec3(x: p.x, y: p.y, z: p.z)
  let a = cross(q.v, x) + q.m * p.w
  let u = cross(q.v, a) + a * q.vw - q.v * (q.mw * p.w)
  Point(x: p.x + 2.0 * u.x, y: p.y + 2.0 * u.y, z: p.z + 2.0 * u.z, w: p.w)

func transform*(l: Line; q: Motor): Line =
  ## Move line by unit motor, i.e. 𝐐 ⟇ 𝐥 ⟇ 𝐐̰; 54 mul, 36 add.
  ##   Direction rotates; moment rotates and gains 𝐭 × direction.
  let v = rotate(l.v, q.v, q.vw)
  let m = rotate(l.m, q.v, q.vw)
  Line(v: v, m: m + cross(q.translation, v))

func transform*(g: Plane; q: Motor): Plane =
  ## Move plane by unit motor, i.e. 𝐐 ⟇ 𝐠 ⟇ 𝐐̰; 33 mul, 23 add.
  ##   Normal rotates; position loses normal ∙ 𝐭.
  let n = rotate(Vec3(x: g.x, y: g.y, z: g.z), q.v, q.vw)
  Plane(x: n.x, y: n.y, z: n.z, w: g.w - dot(n, q.translation))

func rotor*(axis: Vec3; angle: float): Motor =
  ## Construct rotation motor about unit axis through origin; 4 mul, 1 sin, 1 cos.
  let h = angle * 0.5
  Motor(v: axis * sin(h), m: Vec3(), vw: cos(h), mw: 0.0)

func translator*(t: Vec3): Motor {.inline.} =
  ## Construct translation motor by t, i.e. 𝟙 + (𝐭 / 2); 3 mul.
  Motor(v: Vec3(), m: t * 0.5, vw: 1.0, mw: 0.0)
