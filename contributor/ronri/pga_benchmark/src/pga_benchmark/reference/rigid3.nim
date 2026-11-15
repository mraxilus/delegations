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
##     code spends; suite `Internal: Inspector` reads them back from emitted C.
##   No function calls another, and no form binds object: under `--panics:off` call of Nim
##     function fills its result and checks error flag after it, and Nim 2.4 zero-fills object
##     that `let` binds to result of template holding `let`; hand code spends neither.
##   Each form building object reads its operands into scalars, named as table above names
##     components, then writes its result from them alone. Result arrives by pointer, which gcc
##     must take as possible alias of operand; each read before first write lets gcc vectorise,
##     as hand code returning by value lets it. Suite `Internal: Inspector` holds every
##     reference function to no fill, no copy and no check.
##   Motor transforms are derived, not transcribed: each spells antisandwich 𝐐 ⟇ 𝐱 ⟇ 𝐐̰
##     exactly for every even element, as its expansion in exact arithmetic reads; rotation is
##     matrix R of quaternion (Qᵛ, Qᵛʷ), scaled by its squared norm s, and translation is
##     𝐭 = 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ + Qᵛ × Qᵐ). Suite `Wiki: Motor` holds them to library.
##   Transforms take motor as it is, never as unit: on unitized motors, form taking s as 1 erred
##     by as much as rounding, and Architect chose form most accurate to operation on 2026-10-28.
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



#[ Exterior Products ]#

func wedge*(p, q: Point): Line {.inline.} =
  ## Join points into line through both, i.e. 𝐩 ∧ 𝐪; 12 mul, 6 sub.
  let
    (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
    (qˣ, qʸ, qᶻ, qʷ) = (q.x, q.y, q.z, q.w)
  Line(
    v: Vector3(x: pʷ * qˣ - pˣ * qʷ, y: pʷ * qʸ - pʸ * qʷ, z: pʷ * qᶻ - pᶻ * qʷ),
    m: Vector3(x: pʸ * qᶻ - pᶻ * qʸ, y: pᶻ * qˣ - pˣ * qᶻ, z: pˣ * qʸ - pʸ * qˣ),
  )

func wedge*(l: Line, p: Point): Plane {.inline.} =
  ## Join line and point into plane containing both, i.e. 𝐥 ∧ 𝐩; 12 mul, 8 add.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
    (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
  Plane(
    x: lᵛʸ * pᶻ - lᵛᶻ * pʸ + lᵐˣ * pʷ,
    y: lᵛᶻ * pˣ - lᵛˣ * pᶻ + lᵐʸ * pʷ,
    z: lᵛˣ * pʸ - lᵛʸ * pˣ + lᵐᶻ * pʷ,
    w: -lᵐˣ * pˣ - lᵐʸ * pʸ - lᵐᶻ * pᶻ,
  )

func wedge*(p: Point, l: Line): Plane {.inline.} =
  ## Join point and line, i.e. 𝐩 ∧ 𝐥 = 𝐥 ∧ 𝐩 since grades 1 and 2 commute; 12 mul, 8 add.
  let
    (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Plane(
    x: pᶻ * lᵛʸ - pʸ * lᵛᶻ + pʷ * lᵐˣ,
    y: pˣ * lᵛᶻ - pᶻ * lᵛˣ + pʷ * lᵐʸ,
    z: pʸ * lᵛˣ - pˣ * lᵛʸ + pʷ * lᵐᶻ,
    w: -pˣ * lᵐˣ - pʸ * lᵐʸ - pᶻ * lᵐᶻ,
  )

func wedgeAnti*(g, h: Plane): Line {.inline.} =
  ## Meet planes in line, i.e. 𝐠 ∨ 𝐡; 12 mul, 6 sub.
  let
    (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
    (hˣ, hʸ, hᶻ, hʷ) = (h.x, h.y, h.z, h.w)
  Line(
    v: Vector3(x: gᶻ * hʸ - gʸ * hᶻ, y: gˣ * hᶻ - gᶻ * hˣ, z: gʸ * hˣ - gˣ * hʸ),
    m: Vector3(x: gˣ * hʷ - gʷ * hˣ, y: gʸ * hʷ - gʷ * hʸ, z: gᶻ * hʷ - gʷ * hᶻ),
  )

func wedgeAnti*(g: Plane, l: Line): Point {.inline.} =
  ## Meet plane and line in point, i.e. 𝐠 ∨ 𝐥; 12 mul, 8 add.
  let
    (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Point(
    x: lᵐʸ * gᶻ - lᵐᶻ * gʸ + lᵛˣ * gʷ,
    y: lᵐᶻ * gˣ - lᵐˣ * gᶻ + lᵛʸ * gʷ,
    z: lᵐˣ * gʸ - lᵐʸ * gˣ + lᵛᶻ * gʷ,
    w: -lᵛˣ * gˣ - lᵛʸ * gʸ - lᵛᶻ * gᶻ,
  )

func wedgeAnti*(l: Line, g: Plane): Point {.inline.} =
  ## Meet line and plane, i.e. 𝐥 ∨ 𝐠 = 𝐠 ∨ 𝐥 since antigrades 1 and 2 commute; 12 mul, 8 add.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
    (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
  Point(
    x: gᶻ * lᵐʸ - gʸ * lᵐᶻ + gʷ * lᵛˣ,
    y: gˣ * lᵐᶻ - gᶻ * lᵐˣ + gʷ * lᵛʸ,
    z: gʸ * lᵐˣ - gˣ * lᵐʸ + gʷ * lᵛᶻ,
    w: -gˣ * lᵛˣ - gʸ * lᵛʸ - gᶻ * lᵛᶻ,
  )

func wedgeAnti*(k, l: Line): float {.inline.} =
  ## Meet lines in scalar measuring their crossing, i.e. 𝐤 ∨ 𝐥; 6 mul, 5 add.
  -(k.v.x * l.m.x + k.v.y * l.m.y + k.v.z * l.m.z) - (k.m.x * l.v.x + k.m.y * l.v.y + k.m.z * l.v.z)

func wedgeAnti*(p: Point, g: Plane): float {.inline.} =
  ## Meet point and plane in scalar measuring incidence, i.e. 𝐩 ∨ 𝐠; 4 mul, 3 add.
  p.x * g.x + p.y * g.y + p.z * g.z + p.w * g.w



#[ Inner Products ]#

func dot*(a, b: Point): float {.inline.} =
  ## Multiply points through inner product of their bulks, i.e. 𝐚 ∙ 𝐛; 3 mul, 2 add.
  a.x * b.x + a.y * b.y + a.z * b.z

func dot*(k, l: Line): float {.inline.} =
  ## Multiply lines through inner product of their moments, i.e. 𝐤 ∙ 𝐥; 3 mul, 2 add.
  k.m.x * l.m.x + k.m.y * l.m.y + k.m.z * l.m.z

func dot*(g, h: Plane): float {.inline.} =
  ## Multiply planes through inner product of their positions, i.e. 𝐠 ∙ 𝐡; 1 mul.
  g.w * h.w

func dotAnti*(a, b: Point): Antiscalar {.inline.} =
  ## Multiply points through inner antiproduct of their weights, i.e. 𝐚 ∘ 𝐛; 1 mul.
  Antiscalar(a.w * b.w)

func dotAnti*(k, l: Line): Antiscalar {.inline.} =
  ## Multiply lines through inner antiproduct of their directions, i.e. 𝐤 ∘ 𝐥; 3 mul, 2 add.
  Antiscalar(k.v.x * l.v.x + k.v.y * l.v.y + k.v.z * l.v.z)

func dotAnti*(g, h: Plane): Antiscalar {.inline.} =
  ## Multiply planes through inner antiproduct of their normals, i.e. 𝐠 ∘ 𝐡; 3 mul, 2 add.
  Antiscalar(g.x * h.x + g.y * h.y + g.z * h.z)



#[ Complements ]#

func complementRight*(p: Point): Plane {.inline.} =
  ## Get right complement 𝐩̅, i.e. same components read as plane; 0 mul.
  let (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
  Plane(x: pˣ, y: pʸ, z: pᶻ, w: pʷ)

func complementLeft*(p: Point): Plane {.inline.} =
  ## Get left complement 𝐩̲, i.e. negated plane; 0 mul.
  let (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
  Plane(x: -pˣ, y: -pʸ, z: -pᶻ, w: -pʷ)

func complementRight*(l: Line): Line {.inline.} =
  ## Get right complement 𝐥̅, i.e. direction and moment swapped and negated; 0 mul.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Line(v: Vector3(x: -lᵐˣ, y: -lᵐʸ, z: -lᵐᶻ), m: Vector3(x: -lᵛˣ, y: -lᵛʸ, z: -lᵛᶻ))

func complementLeft*(l: Line): Line {.inline.} =
  ## Get left complement 𝐥̲, equal to right one for lines; 0 mul.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Line(v: Vector3(x: -lᵐˣ, y: -lᵐʸ, z: -lᵐᶻ), m: Vector3(x: -lᵛˣ, y: -lᵛʸ, z: -lᵛᶻ))

func complementRight*(g: Plane): Point {.inline.} =
  ## Get right complement 𝐠̅, i.e. negated point; 0 mul.
  let (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
  Point(x: -gˣ, y: -gʸ, z: -gᶻ, w: -gʷ)

func complementLeft*(g: Plane): Point {.inline.} =
  ## Get left complement 𝐠̲, i.e. same components read as point; 0 mul.
  let (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
  Point(x: gˣ, y: gʸ, z: gᶻ, w: gʷ)



#[ Reverses ]#

func reverse*(p: Point): Point {.inline.} =
  ## Get reverse 𝐩̃, identity on grade 1; 0 mul.
  let (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
  Point(x: pˣ, y: pʸ, z: pᶻ, w: pʷ)

func reverse*(l: Line): Line {.inline.} =
  ## Get reverse 𝐥̃, negation on grade 2; 0 mul.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Line(v: Vector3(x: -lᵛˣ, y: -lᵛʸ, z: -lᵛᶻ), m: Vector3(x: -lᵐˣ, y: -lᵐʸ, z: -lᵐᶻ))

func reverse*(g: Plane): Plane {.inline.} =
  ## Get reverse 𝐠̃, negation on grade 3; 0 mul.
  let (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
  Plane(x: -gˣ, y: -gʸ, z: -gᶻ, w: -gʷ)

func reverseAnti*(p: Point): Point {.inline.} =
  ## Get antireverse 𝐩̰, negation on antigrade 3; 0 mul.
  let (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
  Point(x: -pˣ, y: -pʸ, z: -pᶻ, w: -pʷ)

func reverseAnti*(l: Line): Line {.inline.} =
  ## Get antireverse 𝐥̰, negation on antigrade 2; 0 mul.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Line(v: Vector3(x: -lᵛˣ, y: -lᵛʸ, z: -lᵛᶻ), m: Vector3(x: -lᵐˣ, y: -lᵐʸ, z: -lᵐᶻ))

func reverseAnti*(g: Plane): Plane {.inline.} =
  ## Get antireverse 𝐠̰, identity on antigrade 1; 0 mul.
  let (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
  Plane(x: gˣ, y: gʸ, z: gᶻ, w: gʷ)



#[ Duals ]#

func dualBulk*(p: Point): Plane {.inline.} =
  ## Get bulk dual 𝐩★, i.e. right complement of bulk; 0 mul.
  let (pˣ, pʸ, pᶻ) = (p.x, p.y, p.z)
  Plane(x: pˣ, y: pʸ, z: pᶻ, w: 0.0)

func dualBulk*(l: Line): Line {.inline.} =
  ## Get bulk dual 𝐥★; 0 mul.
  let (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Line(v: Vector3(x: -lᵐˣ, y: -lᵐʸ, z: -lᵐᶻ), m: Vector3(x: 0.0, y: 0.0, z: 0.0))

func dualBulk*(g: Plane): Point {.inline.} =
  ## Get bulk dual 𝐠★; 0 mul.
  let gʷ = g.w
  Point(x: 0.0, y: 0.0, z: 0.0, w: -gʷ)

func dualWeight*(p: Point): Plane {.inline.} =
  ## Get weight dual 𝐩☆, i.e. right complement of weight; 0 mul.
  let pʷ = p.w
  Plane(x: 0.0, y: 0.0, z: 0.0, w: pʷ)

func dualWeight*(l: Line): Line {.inline.} =
  ## Get weight dual 𝐥☆; 0 mul.
  let (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
  Line(v: Vector3(x: 0.0, y: 0.0, z: 0.0), m: Vector3(x: -lᵛˣ, y: -lᵛʸ, z: -lᵛᶻ))

func dualWeight*(g: Plane): Point {.inline.} =
  ## Get weight dual 𝐠☆; 0 mul.
  let (gˣ, gʸ, gᶻ) = (g.x, g.y, g.z)
  Point(x: -gˣ, y: -gʸ, z: -gᶻ, w: 0.0)



#[ Parts ]#

func bulk*(p: Point): Point {.inline.} =
  ## Extract bulk 𝐩∙, i.e. components without e₄; 0 mul.
  let (pˣ, pʸ, pᶻ) = (p.x, p.y, p.z)
  Point(x: pˣ, y: pʸ, z: pᶻ, w: 0.0)

func weight*(p: Point): Point {.inline.} =
  ## Extract weight 𝐩∘, i.e. components with e₄; 0 mul.
  let pʷ = p.w
  Point(x: 0.0, y: 0.0, z: 0.0, w: pʷ)

func bulk*(l: Line): Line {.inline.} =
  ## Extract bulk 𝐥∙, i.e. moment; 0 mul.
  let (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Line(v: Vector3(x: 0.0, y: 0.0, z: 0.0), m: Vector3(x: lᵐˣ, y: lᵐʸ, z: lᵐᶻ))

func weight*(l: Line): Line {.inline.} =
  ## Extract weight 𝐥∘, i.e. direction; 0 mul.
  let (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
  Line(v: Vector3(x: lᵛˣ, y: lᵛʸ, z: lᵛᶻ), m: Vector3(x: 0.0, y: 0.0, z: 0.0))

func bulk*(g: Plane): Plane {.inline.} =
  ## Extract bulk 𝐠∙, i.e. position; 0 mul.
  let gʷ = g.w
  Plane(x: 0.0, y: 0.0, z: 0.0, w: gʷ)

func weight*(g: Plane): Plane {.inline.} =
  ## Extract weight 𝐠∘, i.e. normal; 0 mul.
  let (gˣ, gʸ, gᶻ) = (g.x, g.y, g.z)
  Plane(x: gˣ, y: gʸ, z: gᶻ, w: 0.0)



#[ Attitudes ]#

func attitude*(p: Point): float {.inline.} =
  ## Get attitude of point, i.e. 𝐩 ∨ 𝐞̅₄, its weight as scalar; 0 mul.
  p.w

func attitude*(l: Line): Point {.inline.} =
  ## Get attitude of line, i.e. its direction as point at infinity; 0 mul.
  let (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
  Point(x: lᵛˣ, y: lᵛʸ, z: lᵛᶻ, w: 0.0)

func attitude*(g: Plane): Line {.inline.} =
  ## Get attitude of plane, i.e. its normal as line at infinity; 0 mul.
  let (gˣ, gʸ, gᶻ) = (g.x, g.y, g.z)
  Line(v: Vector3(x: 0.0, y: 0.0, z: 0.0), m: Vector3(x: gˣ, y: gʸ, z: gᶻ))



#[ Norms ]#

func normBulkSquared*(p: Point): float {.inline.} =
  ## Get squared bulk norm 𝐩 ∙ 𝐩; 3 mul, 2 add.
  p.x * p.x + p.y * p.y + p.z * p.z

func normWeightSquared*(p: Point): float {.inline.} =
  ## Get squared weight norm 𝐩 ∘ 𝐩; 1 mul.
  p.w * p.w

func normBulkSquared*(l: Line): float {.inline.} =
  ## Get squared bulk norm 𝐥 ∙ 𝐥; 3 mul, 2 add.
  l.m.x * l.m.x + l.m.y * l.m.y + l.m.z * l.m.z

func normWeightSquared*(l: Line): float {.inline.} =
  ## Get squared weight norm 𝐥 ∘ 𝐥; 3 mul, 2 add.
  l.v.x * l.v.x + l.v.y * l.v.y + l.v.z * l.v.z

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
  sqrt(l.m.x * l.m.x + l.m.y * l.m.y + l.m.z * l.m.z)

func normWeight*(l: Line): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐥‖∘; 3 mul, 2 add, 1 sqrt.
  Antiscalar(sqrt(l.v.x * l.v.x + l.v.y * l.v.y + l.v.z * l.v.z))

func normBulk*(g: Plane): float {.inline.} =
  ## Get bulk norm ‖𝐠‖∙, i.e. |w|; 1 abs.
  abs(g.w)

func normWeight*(g: Plane): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐠‖∘; 3 mul, 2 add, 1 sqrt.
  Antiscalar(sqrt(g.x * g.x + g.y * g.y + g.z * g.z))



#[ Unitizations ]#

func unitize*(p: Point): Point {.inline.} =
  ## Unitize point so |w| = 1, i.e. 𝐩 / ‖𝐩‖∘; 1 abs, 1 div, 4 mul.
  ##   Weight norm is size of w, so sign of w stays, as book's rule keeps it; Lengyel's code
  ##     divides by signed w instead, and Architect chose book's rule on 2026-10-10.
  ##   No-op where weight is zero, as library's unitize is.
  let
    (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
    n = if pʷ == 0.0: 1.0 else: 1.0 / abs(pʷ)
  Point(x: pˣ * n, y: pʸ * n, z: pᶻ * n, w: pʷ * n)

func unitize*(l: Line): Line {.inline.} =
  ## Unitize line so direction has unit length, i.e. 𝐥 / ‖𝐥‖∘; 3 mul, 2 add, 1 sqrt, 1 div, 6 mul.
  ##   No-op where weight is zero.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
    s = lᵛˣ * lᵛˣ + lᵛʸ * lᵛʸ + lᵛᶻ * lᵛᶻ
    n = if s == 0.0: 1.0 else: 1.0 / sqrt(s)
  Line(
    v: Vector3(x: lᵛˣ * n, y: lᵛʸ * n, z: lᵛᶻ * n),
    m: Vector3(x: lᵐˣ * n, y: lᵐʸ * n, z: lᵐᶻ * n),
  )

func unitize*(g: Plane): Plane {.inline.} =
  ## Unitize plane so normal has unit length, i.e. 𝐠 / ‖𝐠‖∘; 3 mul, 2 add, 1 sqrt, 1 div, 4 mul.
  ##   No-op where weight is zero.
  let
    (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
    s = gˣ * gˣ + gʸ * gʸ + gᶻ * gᶻ
    n = if s == 0.0: 1.0 else: 1.0 / sqrt(s)
  Plane(x: gˣ * n, y: gʸ * n, z: gᶻ * n, w: gʷ * n)



#[ Supports ]#

func support*(l: Line): Point {.inline.} =
  ## Get support of line, i.e. point on it closest to origin; 9 mul, 5 add.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Point(
    x: lᵛʸ * lᵐᶻ - lᵛᶻ * lᵐʸ,
    y: lᵛᶻ * lᵐˣ - lᵛˣ * lᵐᶻ,
    z: lᵛˣ * lᵐʸ - lᵛʸ * lᵐˣ,
    w: lᵛˣ * lᵛˣ + lᵛʸ * lᵛʸ + lᵛᶻ * lᵛᶻ,
  )

func support*(g: Plane): Point {.inline.} =
  ## Get support of plane, i.e. point on it closest to origin; 6 mul, 2 add.
  let (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
  Point(x: -gˣ * gʷ, y: -gʸ * gʷ, z: -gᶻ * gʷ, w: gˣ * gˣ + gʸ * gʸ + gᶻ * gᶻ)

func supportAnti*(p: Point): Plane {.inline.} =
  ## Get antisupport of point, i.e. plane through it farthest from origin; 6 mul, 2 add.
  let (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
  Plane(x: -pˣ * pʷ, y: -pʸ * pʷ, z: -pᶻ * pʷ, w: pˣ * pˣ + pʸ * pʸ + pᶻ * pᶻ)

func supportAnti*(l: Line): Plane {.inline.} =
  ## Get antisupport of line, i.e. plane containing it farthest from origin; 9 mul, 5 add.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
  Plane(
    x: lᵛᶻ * lᵐʸ - lᵛʸ * lᵐᶻ,
    y: lᵛˣ * lᵐᶻ - lᵛᶻ * lᵐˣ,
    z: lᵛʸ * lᵐˣ - lᵛˣ * lᵐʸ,
    w: lᵐˣ * lᵐˣ + lᵐʸ * lᵐʸ + lᵐᶻ * lᵐᶻ,
  )



#[ Projections ]#

func projectOrthogonal*(p: Point, g: Plane): Point {.inline.} =
  ## Project point orthogonally onto plane, homogeneous, i.e. 𝐠 ∨ (𝐩 ∧ 𝐠☆); 14 mul, 8 add.
  ##   Result is (𝐠∘ ∙ 𝐠∘) 𝐩 − 𝐠∘ (𝐩 ∨ 𝐠) on position, weight scaled alike.
  let
    (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
    (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
    s = gˣ * gˣ + gʸ * gʸ + gᶻ * gᶻ
    d = pˣ * gˣ + pʸ * gʸ + pᶻ * gᶻ + pʷ * gʷ
  Point(x: pˣ * s - gˣ * d, y: pʸ * s - gʸ * d, z: pᶻ * s - gᶻ * d, w: pʷ * s)

func projectOrthogonal*(p: Point, l: Line): Point {.inline.} =
  ## Project point orthogonally onto line, homogeneous, i.e. 𝐥 ∨ (𝐩 ∧ 𝐥☆); 19 mul, 10 add.
  ##   Position is (𝐥∘ ∙ 𝐩) 𝐥ᵛ + w (𝐥ᵛ × 𝐥ᵐ), weight is w (𝐥ᵛ ∙ 𝐥ᵛ).
  let
    (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
    d = lᵛˣ * pˣ + lᵛʸ * pʸ + lᵛᶻ * pᶻ
    cˣ = lᵛʸ * lᵐᶻ - lᵛᶻ * lᵐʸ
    cʸ = lᵛᶻ * lᵐˣ - lᵛˣ * lᵐᶻ
    cᶻ = lᵛˣ * lᵐʸ - lᵛʸ * lᵐˣ
  Point(
    x: d * lᵛˣ + pʷ * cˣ,
    y: d * lᵛʸ + pʷ * cʸ,
    z: d * lᵛᶻ + pʷ * cᶻ,
    w: pʷ * (lᵛˣ * lᵛˣ + lᵛʸ * lᵛʸ + lᵛᶻ * lᵛᶻ),
  )

func projectOrthogonal*(l: Line, g: Plane): Line {.inline.} =
  ## Project line orthogonally onto plane, homogeneous, i.e. 𝐠 ∨ (𝐥 ∧ 𝐠☆); 27 mul, 15 add.
  ##   Direction is (𝐠∘ ∙ 𝐠∘) 𝐥ᵛ − 𝐠∘ (𝐠∘ ∙ 𝐥ᵛ); moment is
  ##   𝐠∘ (𝐠∘ ∙ 𝐥ᵐ) − (𝐠∘ × 𝐥ᵛ) gʷ... derived, held to library by suite.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
    (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
    s = gˣ * gˣ + gʸ * gʸ + gᶻ * gᶻ
    dot_direction = gˣ * lᵛˣ + gʸ * lᵛʸ + gᶻ * lᵛᶻ
    dot_moment = gˣ * lᵐˣ + gʸ * lᵐʸ + gᶻ * lᵐᶻ
    cˣ = gʸ * lᵛᶻ - gᶻ * lᵛʸ
    cʸ = gᶻ * lᵛˣ - gˣ * lᵛᶻ
    cᶻ = gˣ * lᵛʸ - gʸ * lᵛˣ
  Line(
    v: Vector3(
      x: lᵛˣ * s - gˣ * dot_direction,
      y: lᵛʸ * s - gʸ * dot_direction,
      z: lᵛᶻ * s - gᶻ * dot_direction,
    ),
    m: Vector3(
      x: gˣ * dot_moment - cˣ * gʷ,
      y: gʸ * dot_moment - cʸ * gʷ,
      z: gᶻ * dot_moment - cᶻ * gʷ,
    ),
  )



#[ Motors ]#

func wedgeDotAnti*(a, b: Motor): Motor {.inline.} =
  ## Compose motors through geometric antiproduct, i.e. 𝐚 ⟇ 𝐛; 48 mul, 40 add.
  let
    (aᵛˣ, aᵛʸ, aᵛᶻ) = (a.v.x, a.v.y, a.v.z)
    (aᵐˣ, aᵐʸ, aᵐᶻ) = (a.m.x, a.m.y, a.m.z)
    (aᵛʷ, aᵐʷ) = (a.vw, a.mw)
    (bᵛˣ, bᵛʸ, bᵛᶻ) = (b.v.x, b.v.y, b.v.z)
    (bᵐˣ, bᵐʸ, bᵐᶻ) = (b.m.x, b.m.y, b.m.z)
    (bᵛʷ, bᵐʷ) = (b.vw, b.mw)
  Motor(
    v: Vector3(
      x: aᵛʷ * bᵛˣ + aᵛˣ * bᵛʷ + aᵛʸ * bᵛᶻ - aᵛᶻ * bᵛʸ,
      y: aᵛʷ * bᵛʸ + aᵛʸ * bᵛʷ + aᵛᶻ * bᵛˣ - aᵛˣ * bᵛᶻ,
      z: aᵛʷ * bᵛᶻ + aᵛᶻ * bᵛʷ + aᵛˣ * bᵛʸ - aᵛʸ * bᵛˣ,
    ),
    vw: aᵛʷ * bᵛʷ - aᵛˣ * bᵛˣ - aᵛʸ * bᵛʸ - aᵛᶻ * bᵛᶻ,
    m: Vector3(
      x: aᵐʷ * bᵛˣ + aᵐˣ * bᵛʷ + aᵐʸ * bᵛᶻ - aᵐᶻ * bᵛʸ +
          bᵐʷ * aᵛˣ + bᵐˣ * aᵛʷ - bᵐʸ * aᵛᶻ + bᵐᶻ * aᵛʸ,
      y: aᵐʷ * bᵛʸ - aᵐˣ * bᵛᶻ + aᵐʸ * bᵛʷ + aᵐᶻ * bᵛˣ +
          bᵐʷ * aᵛʸ + bᵐˣ * aᵛᶻ + bᵐʸ * aᵛʷ - bᵐᶻ * aᵛˣ,
      z: aᵐʷ * bᵛᶻ + aᵐˣ * bᵛʸ - aᵐʸ * bᵛˣ + aᵐᶻ * bᵛʷ +
          bᵐʷ * aᵛᶻ - bᵐˣ * aᵛʸ + bᵐʸ * aᵛˣ + bᵐᶻ * aᵛʷ,
    ),
    mw: aᵐʷ * bᵛʷ - aᵐˣ * bᵛˣ - aᵐʸ * bᵛʸ - aᵐᶻ * bᵛᶻ +
        bᵐʷ * aᵛʷ - bᵐˣ * aᵛˣ - bᵐʸ * aᵛʸ - bᵐᶻ * aᵛᶻ,
  )

func reverseAnti*(q: Motor): Motor {.inline.} =
  ## Get antireverse 𝐐̰, negating antigrade-2 parts v and m; 0 mul.
  let
    (qᵛˣ, qᵛʸ, qᵛᶻ) = (q.v.x, q.v.y, q.v.z)
    (qᵐˣ, qᵐʸ, qᵐᶻ) = (q.m.x, q.m.y, q.m.z)
    (qᵛʷ, qᵐʷ) = (q.vw, q.mw)
  Motor(
    v: Vector3(x: -qᵛˣ, y: -qᵛʸ, z: -qᵛᶻ),
    m: Vector3(x: -qᵐˣ, y: -qᵐʸ, z: -qᵐᶻ),
    vw: qᵛʷ,
    mw: qᵐʷ,
  )

func reverse*(q: Motor): Motor {.inline.} =
  ## Get reverse 𝐐̃, negating grade-2 parts v and m; 0 mul.
  let
    (qᵛˣ, qᵛʸ, qᵛᶻ) = (q.v.x, q.v.y, q.v.z)
    (qᵐˣ, qᵐʸ, qᵐᶻ) = (q.m.x, q.m.y, q.m.z)
    (qᵛʷ, qᵐʷ) = (q.vw, q.mw)
  Motor(
    v: Vector3(x: -qᵛˣ, y: -qᵛʸ, z: -qᵛᶻ),
    m: Vector3(x: -qᵐˣ, y: -qᵐʸ, z: -qᵐᶻ),
    vw: qᵛʷ,
    mw: qᵐʷ,
  )

func normWeightSquared*(q: Motor): float {.inline.} =
  ## Get squared weight norm 𝐐 ∘ 𝐐; 4 mul, 3 add.
  q.v.x * q.v.x + q.v.y * q.v.y + q.v.z * q.v.z + q.vw * q.vw

func normBulkSquared*(q: Motor): float {.inline.} =
  ## Get squared bulk norm 𝐐 ∙ 𝐐; 4 mul, 3 add.
  q.m.x * q.m.x + q.m.y * q.m.y + q.m.z * q.m.z + q.mw * q.mw

func normWeight*(q: Motor): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐐‖∘; 4 mul, 3 add, 1 sqrt.
  Antiscalar(sqrt(q.v.x * q.v.x + q.v.y * q.v.y + q.v.z * q.v.z + q.vw * q.vw))

func normBulk*(q: Motor): float {.inline.} =
  ## Get bulk norm ‖𝐐‖∙; 4 mul, 3 add, 1 sqrt.
  sqrt(q.m.x * q.m.x + q.m.y * q.m.y + q.m.z * q.m.z + q.mw * q.mw)

func unitize*(q: Motor): Motor {.inline.} =
  ## Unitize motor so weight norm is 𝟙; 4 mul, 3 add, 1 sqrt, 1 div, 8 mul.
  ##   No-op where weight is zero.
  let
    (qᵛˣ, qᵛʸ, qᵛᶻ) = (q.v.x, q.v.y, q.v.z)
    (qᵐˣ, qᵐʸ, qᵐᶻ) = (q.m.x, q.m.y, q.m.z)
    (qᵛʷ, qᵐʷ) = (q.vw, q.mw)
    s = qᵛˣ * qᵛˣ + qᵛʸ * qᵛʸ + qᵛᶻ * qᵛᶻ + qᵛʷ * qᵛʷ
    n = if s == 0.0: 1.0 else: 1.0 / sqrt(s)
  Motor(
    v: Vector3(x: qᵛˣ * n, y: qᵛʸ * n, z: qᵛᶻ * n),
    m: Vector3(x: qᵐˣ * n, y: qᵐʸ * n, z: qᵐᶻ * n),
    vw: qᵛʷ * n,
    mw: qᵐʷ * n,
  )

func translation*(q: Motor): Vector3 {.inline.} =
  ## Get translation unit motor carries, i.e. 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ + Qᵛ × Qᵐ); 12 mul, 13 add.
  ##   Doubles each component of (Qᵛ, Qᵛʷ) once, as d, so no product multiplies by 2.
  let
    (qᵛˣ, qᵛʸ, qᵛᶻ) = (q.v.x, q.v.y, q.v.z)
    (qᵐˣ, qᵐʸ, qᵐᶻ) = (q.m.x, q.m.y, q.m.z)
    (qᵛʷ, qᵐʷ) = (q.vw, q.mw)
    (dˣ, dʸ, dᶻ, dʷ) = (qᵛˣ + qᵛˣ, qᵛʸ + qᵛʸ, qᵛᶻ + qᵛᶻ, qᵛʷ + qᵛʷ)
  Vector3(
    x: dʷ * qᵐˣ - qᵐʷ * dˣ + (dʸ * qᵐᶻ - dᶻ * qᵐʸ),
    y: dʷ * qᵐʸ - qᵐʷ * dʸ + (dᶻ * qᵐˣ - dˣ * qᵐᶻ),
    z: dʷ * qᵐᶻ - qᵐʷ * dᶻ + (dˣ * qᵐʸ - dʸ * qᵐˣ),
  )

func transform*(p: Point, q: Motor): Point {.inline.} =
  ## Move point by motor, i.e. 𝐐 ⟇ 𝐩 ⟇ 𝐐̰; 35 mul, 40 add.
  ##   Exact for every motor: position R 𝐩 + pʷ 𝐭, weight s pʷ, with s = ‖Qᵛ‖² + (Qᵛʷ)² and
  ##     R = ((Qᵛʷ)² − ‖Qᵛ‖²) 𝐈 + 2 Qᵛ Qᵛᵀ + 2 Qᵛʷ [Qᵛ]×.
  ##   R is read off products sⁱʲ of (Qᵛ, Qᵛʷ), and those off diagonal through d = 2(Qᵛ, Qᵛʷ).
  let
    (pˣ, pʸ, pᶻ, pʷ) = (p.x, p.y, p.z, p.w)
    (qᵛˣ, qᵛʸ, qᵛᶻ) = (q.v.x, q.v.y, q.v.z)
    (qᵐˣ, qᵐʸ, qᵐᶻ) = (q.m.x, q.m.y, q.m.z)
    (qᵛʷ, qᵐʷ) = (q.vw, q.mw)
    (dˣ, dʸ, dᶻ, dʷ) = (qᵛˣ + qᵛˣ, qᵛʸ + qᵛʸ, qᵛᶻ + qᵛᶻ, qᵛʷ + qᵛʷ)
    (sˣˣ, sʸʸ, sᶻᶻ, sʷʷ) = (qᵛˣ * qᵛˣ, qᵛʸ * qᵛʸ, qᵛᶻ * qᵛᶻ, qᵛʷ * qᵛʷ)
    (sˣʸ, sˣᶻ, sʸᶻ) = (qᵛˣ * dʸ, qᵛˣ * dᶻ, qᵛʸ * dᶻ)
    (sʷˣ, sʷʸ, sʷᶻ) = (qᵛʷ * dˣ, qᵛʷ * dʸ, qᵛʷ * dᶻ)
    (rˣˣ, rˣʸ, rˣᶻ) = (sʷʷ + sˣˣ - sʸʸ - sᶻᶻ, sˣʸ - sʷᶻ, sˣᶻ + sʷʸ)
    (rʸˣ, rʸʸ, rʸᶻ) = (sˣʸ + sʷᶻ, sʷʷ - sˣˣ + sʸʸ - sᶻᶻ, sʸᶻ - sʷˣ)
    (rᶻˣ, rᶻʸ, rᶻᶻ) = (sˣᶻ - sʷʸ, sʸᶻ + sʷˣ, sʷʷ - sˣˣ - sʸʸ + sᶻᶻ)
    s = sˣˣ + sʸʸ + sᶻᶻ + sʷʷ
    tˣ = dʷ * qᵐˣ - qᵐʷ * dˣ + (dʸ * qᵐᶻ - dᶻ * qᵐʸ)
    tʸ = dʷ * qᵐʸ - qᵐʷ * dʸ + (dᶻ * qᵐˣ - dˣ * qᵐᶻ)
    tᶻ = dʷ * qᵐᶻ - qᵐʷ * dᶻ + (dˣ * qᵐʸ - dʸ * qᵐˣ)
  Point(
    x: rˣˣ * pˣ + rˣʸ * pʸ + rˣᶻ * pᶻ + pʷ * tˣ,
    y: rʸˣ * pˣ + rʸʸ * pʸ + rʸᶻ * pᶻ + pʷ * tʸ,
    z: rᶻˣ * pˣ + rᶻʸ * pʸ + rᶻᶻ * pᶻ + pʷ * tᶻ,
    w: s * pʷ,
  )

func transform*(l: Line, q: Motor): Line {.inline.} =
  ## Move line by motor, i.e. 𝐐 ⟇ 𝐥 ⟇ 𝐐̰; 52 mul, 54 add.
  ##   Exact for every motor: direction R lᵛ, moment R lᵐ + 2(Qᵐʷ 𝐤 + kʷ Qᵐ + Qᵐ × 𝐤), with R as
  ##     point's and quaternion k = lᵛ (Qᵛʷ, −Qᵛ), i.e. kʷ = lᵛ ∙ Qᵛ and 𝐤 = Qᵛʷ lᵛ + Qᵛ × lᵛ.
  let
    (lᵛˣ, lᵛʸ, lᵛᶻ) = (l.v.x, l.v.y, l.v.z)
    (lᵐˣ, lᵐʸ, lᵐᶻ) = (l.m.x, l.m.y, l.m.z)
    (qᵛˣ, qᵛʸ, qᵛᶻ) = (q.v.x, q.v.y, q.v.z)
    (qᵐˣ, qᵐʸ, qᵐᶻ) = (q.m.x, q.m.y, q.m.z)
    (qᵛʷ, qᵐʷ) = (q.vw, q.mw)
    (dˣ, dʸ, dᶻ, dʷ) = (qᵛˣ + qᵛˣ, qᵛʸ + qᵛʸ, qᵛᶻ + qᵛᶻ, qᵛʷ + qᵛʷ)
    (sˣˣ, sʸʸ, sᶻᶻ, sʷʷ) = (qᵛˣ * qᵛˣ, qᵛʸ * qᵛʸ, qᵛᶻ * qᵛᶻ, qᵛʷ * qᵛʷ)
    (sˣʸ, sˣᶻ, sʸᶻ) = (qᵛˣ * dʸ, qᵛˣ * dᶻ, qᵛʸ * dᶻ)
    (sʷˣ, sʷʸ, sʷᶻ) = (qᵛʷ * dˣ, qᵛʷ * dʸ, qᵛʷ * dᶻ)
    (rˣˣ, rˣʸ, rˣᶻ) = (sʷʷ + sˣˣ - sʸʸ - sᶻᶻ, sˣʸ - sʷᶻ, sˣᶻ + sʷʸ)
    (rʸˣ, rʸʸ, rʸᶻ) = (sˣʸ + sʷᶻ, sʷʷ - sˣˣ + sʸʸ - sᶻᶻ, sʸᶻ - sʷˣ)
    (rᶻˣ, rᶻʸ, rᶻᶻ) = (sˣᶻ - sʷʸ, sʸᶻ + sʷˣ, sʷʷ - sˣˣ - sʸʸ + sᶻᶻ)
    kʷ = lᵛˣ * qᵛˣ + lᵛʸ * qᵛʸ + lᵛᶻ * qᵛᶻ
    kˣ = qᵛʷ * lᵛˣ + (qᵛʸ * lᵛᶻ - qᵛᶻ * lᵛʸ)
    kʸ = qᵛʷ * lᵛʸ + (qᵛᶻ * lᵛˣ - qᵛˣ * lᵛᶻ)
    kᶻ = qᵛʷ * lᵛᶻ + (qᵛˣ * lᵛʸ - qᵛʸ * lᵛˣ)
    eˣ = qᵐʷ * kˣ + kʷ * qᵐˣ + (qᵐʸ * kᶻ - qᵐᶻ * kʸ)
    eʸ = qᵐʷ * kʸ + kʷ * qᵐʸ + (qᵐᶻ * kˣ - qᵐˣ * kᶻ)
    eᶻ = qᵐʷ * kᶻ + kʷ * qᵐᶻ + (qᵐˣ * kʸ - qᵐʸ * kˣ)
  Line(
    v: Vector3(
      x: rˣˣ * lᵛˣ + rˣʸ * lᵛʸ + rˣᶻ * lᵛᶻ,
      y: rʸˣ * lᵛˣ + rʸʸ * lᵛʸ + rʸᶻ * lᵛᶻ,
      z: rᶻˣ * lᵛˣ + rᶻʸ * lᵛʸ + rᶻᶻ * lᵛᶻ,
    ),
    m: Vector3(
      x: rˣˣ * lᵐˣ + rˣʸ * lᵐʸ + rˣᶻ * lᵐᶻ + (eˣ + eˣ),
      y: rʸˣ * lᵐˣ + rʸʸ * lᵐʸ + rʸᶻ * lᵐᶻ + (eʸ + eʸ),
      z: rᶻˣ * lᵐˣ + rᶻʸ * lᵐʸ + rᶻᶻ * lᵐᶻ + (eᶻ + eᶻ),
    ),
  )

func transform*(g: Plane, q: Motor): Plane {.inline.} =
  ## Move plane by motor, i.e. 𝐐 ⟇ 𝐠 ⟇ 𝐐̰; 35 mul, 40 add.
  ##   Exact for every motor: normal R 𝐠ˣʸᶻ, position s gʷ − 𝐠ˣʸᶻ ∙ 𝐭̃ against normal before
  ##     rotation, with R and s as point's and 𝐭̃ = 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ − Qᵛ × Qᵐ).
  let
    (gˣ, gʸ, gᶻ, gʷ) = (g.x, g.y, g.z, g.w)
    (qᵛˣ, qᵛʸ, qᵛᶻ) = (q.v.x, q.v.y, q.v.z)
    (qᵐˣ, qᵐʸ, qᵐᶻ) = (q.m.x, q.m.y, q.m.z)
    (qᵛʷ, qᵐʷ) = (q.vw, q.mw)
    (dˣ, dʸ, dᶻ, dʷ) = (qᵛˣ + qᵛˣ, qᵛʸ + qᵛʸ, qᵛᶻ + qᵛᶻ, qᵛʷ + qᵛʷ)
    (sˣˣ, sʸʸ, sᶻᶻ, sʷʷ) = (qᵛˣ * qᵛˣ, qᵛʸ * qᵛʸ, qᵛᶻ * qᵛᶻ, qᵛʷ * qᵛʷ)
    (sˣʸ, sˣᶻ, sʸᶻ) = (qᵛˣ * dʸ, qᵛˣ * dᶻ, qᵛʸ * dᶻ)
    (sʷˣ, sʷʸ, sʷᶻ) = (qᵛʷ * dˣ, qᵛʷ * dʸ, qᵛʷ * dᶻ)
    (rˣˣ, rˣʸ, rˣᶻ) = (sʷʷ + sˣˣ - sʸʸ - sᶻᶻ, sˣʸ - sʷᶻ, sˣᶻ + sʷʸ)
    (rʸˣ, rʸʸ, rʸᶻ) = (sˣʸ + sʷᶻ, sʷʷ - sˣˣ + sʸʸ - sᶻᶻ, sʸᶻ - sʷˣ)
    (rᶻˣ, rᶻʸ, rᶻᶻ) = (sˣᶻ - sʷʸ, sʸᶻ + sʷˣ, sʷʷ - sˣˣ - sʸʸ + sᶻᶻ)
    s = sˣˣ + sʸʸ + sᶻᶻ + sʷʷ
    tˣ = dʷ * qᵐˣ - qᵐʷ * dˣ - (dʸ * qᵐᶻ - dᶻ * qᵐʸ)
    tʸ = dʷ * qᵐʸ - qᵐʷ * dʸ - (dᶻ * qᵐˣ - dˣ * qᵐᶻ)
    tᶻ = dʷ * qᵐᶻ - qᵐʷ * dᶻ - (dˣ * qᵐʸ - dʸ * qᵐˣ)
  Plane(
    x: rˣˣ * gˣ + rˣʸ * gʸ + rˣᶻ * gᶻ,
    y: rʸˣ * gˣ + rʸʸ * gʸ + rʸᶻ * gᶻ,
    z: rᶻˣ * gˣ + rᶻʸ * gʸ + rᶻᶻ * gᶻ,
    w: s * gʷ - (gˣ * tˣ + gʸ * tʸ + gᶻ * tᶻ),
  )

func rotor*(axis: Vector3, angle: float): Motor {.inline.} =
  ## Construct rotation motor about unit axis through origin; 4 mul, 1 sin, 1 cos.
  let
    (axisˣ, axisʸ, axisᶻ) = (axis.x, axis.y, axis.z)
    h = angle * 0.5
    s = sin(h)
    c = cos(h)
  Motor(
    v: Vector3(x: axisˣ * s, y: axisʸ * s, z: axisᶻ * s),
    m: Vector3(x: 0.0, y: 0.0, z: 0.0),
    vw: c,
    mw: 0.0,
  )

func translator*(t: Vector3): Motor {.inline.} =
  ## Construct translation motor by t, i.e. 𝟙 + (𝐭 / 2); 3 mul.
  let (tˣ, tʸ, tᶻ) = (t.x, t.y, t.z)
  Motor(
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: tˣ * 0.5, y: tʸ * 0.5, z: tᶻ * 0.5),
    vw: 1.0,
    mw: 0.0,
  )
