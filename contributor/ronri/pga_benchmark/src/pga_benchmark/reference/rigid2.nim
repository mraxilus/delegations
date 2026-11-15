## Derive Lengyel's typed objects and hand-rolled operations of 2D rigid geometric algebra.
##   Reference every dense library operation is measured against at rga3d: each object holds
##   only components its grade can carry, and each operation spells only terms that survive,
##   as optimal hand-written linear algebra does. Scalar is `float`, as library's.
##
##   |---------|-----------------------------------|------------------|
##   | Code    | Notation                          | Library basis    |
##   |---------|-----------------------------------|------------------|
##   | Point   | 𝐩 = pˣe₁ + pʸe₂ + pʷe₃            | E1 E2 E3         |
##   | Line    | 𝐠 = gˣe₂₃ + gʸe₃₁ + gʷe₁₂         | E23 E31 E12      |
##   | Motor   | 𝐐 = Qˣe₁ + Qʸe₂ + Qᶻe₃ + Qʷ𝟙      | E1 E2 E3 E321    |
##   | Scalar  | s𝟏                                | S                |
##   | Antisc. | t𝟙                                | E321             |
##   |---------|-----------------------------------|------------------|
##
##   Forms are derived, not transcribed: each one expands its definition in Lengyel's
##     exterior algebra, with metric e₁² = e₂² = 1 and e₃² = 0, on objects' components alone.
##     Expansion that derived them reproduced every product, complement, dual, part and
##     attitude of library on each pair of basis elements before any form was read off.
##     Terathon Math Library (MIT, Eric Lengyel) was read to cross-check transforms; nothing
##     is copied from it.
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
##   Transforms spell antisandwich 𝐐 ⟇ 𝐱 ⟇ 𝐐̰ exactly for every motor, as its expansion in exact
##     arithmetic reads: rotation by cosine (Qʷ)² − (Qᶻ)² and sine 2QᶻQʷ, weight scaled by
##     s = (Qᶻ)² + (Qʷ)². Motor is taken as it is, never as unit: on unitized motors, form taking
##     s as 1 erred more, and Architect chose form most accurate to operation on 2026-10-28.

{.experimental: "strictFuncs".}

import std/math

import ./scalars

export scalars


type
  Point* = object  ## Define point 𝐩 with position x y and homogeneous weight w; grade 1.
    x*, y*, w*: float
  Line* = object  ## Define line 𝐠 with normal x y and position w; grade 2.
    x*, y*, w*: float
  Motor* = object  ## Define motor 𝐐 with bulk x y and weight z w; grades 1 and 3, i.e. antieven.
    x*, y*, z*, w*: float



#[ Exterior Products ]#

func wedge*(p, q: Point): Line {.inline.} =
  ## Join points into line through both, i.e. 𝐩 ∧ 𝐪; 6 mul, 3 sub.
  let
    (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
    (qˣ, qʸ, qʷ) = (q.x, q.y, q.w)
  Line(x: pʸ * qʷ - pʷ * qʸ, y: pʷ * qˣ - pˣ * qʷ, w: pˣ * qʸ - pʸ * qˣ)

func wedge*(p: Point, g: Line): Antiscalar {.inline.} =
  ## Join point and line in antiscalar measuring incidence, i.e. 𝐩 ∧ 𝐠; 3 mul, 2 add.
  Antiscalar(-(p.x * g.x) - p.y * g.y - p.w * g.w)

func wedge*(g: Line, p: Point): Antiscalar {.inline.} =
  ## Join line and point, i.e. 𝐠 ∧ 𝐩 = 𝐩 ∧ 𝐠 since grades 1 and 2 commute here; 3 mul, 2 add.
  Antiscalar(-(g.x * p.x) - g.y * p.y - g.w * p.w)

func wedgeAnti*(g, h: Line): Point {.inline.} =
  ## Meet lines in point, i.e. 𝐠 ∨ 𝐡; 6 mul, 3 sub.
  let
    (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
    (hˣ, hʸ, hʷ) = (h.x, h.y, h.w)
  Point(x: gʷ * hʸ - gʸ * hʷ, y: gˣ * hʷ - gʷ * hˣ, w: gʸ * hˣ - gˣ * hʸ)

func wedgeAnti*(p: Point, g: Line): float {.inline.} =
  ## Meet point and line in scalar measuring incidence, i.e. 𝐩 ∨ 𝐠; 3 mul, 2 add.
  -(p.x * g.x) - p.y * g.y - p.w * g.w

func wedgeAnti*(g: Line, p: Point): float {.inline.} =
  ## Meet line and point, i.e. 𝐠 ∨ 𝐩 = 𝐩 ∨ 𝐠; 3 mul, 2 add.
  -(g.x * p.x) - g.y * p.y - g.w * p.w



#[ Inner Products ]#

func dot*(a, b: Point): float {.inline.} =
  ## Multiply points through inner product of their bulks, i.e. 𝐚 ∙ 𝐛; 2 mul, 1 add.
  a.x * b.x + a.y * b.y

func dot*(g, h: Line): float {.inline.} =
  ## Multiply lines through inner product of their positions, i.e. 𝐠 ∙ 𝐡; 1 mul.
  g.w * h.w

func dotAnti*(a, b: Point): Antiscalar {.inline.} =
  ## Multiply points through inner antiproduct of their weights, i.e. 𝐚 ∘ 𝐛; 1 mul.
  Antiscalar(a.w * b.w)

func dotAnti*(g, h: Line): Antiscalar {.inline.} =
  ## Multiply lines through inner antiproduct of their normals, i.e. 𝐠 ∘ 𝐡; 2 mul, 1 add.
  Antiscalar(g.x * h.x + g.y * h.y)



#[ Complements ]#

func complementRight*(p: Point): Line {.inline.} =
  ## Get right complement 𝐩̅, i.e. components negated and read as line; 0 mul.
  let (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
  Line(x: -pˣ, y: -pʸ, w: -pʷ)

func complementLeft*(p: Point): Line {.inline.} =
  ## Get left complement 𝐩̲, equal to right one at grade 1 here; 0 mul.
  let (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
  Line(x: -pˣ, y: -pʸ, w: -pʷ)

func complementRight*(g: Line): Point {.inline.} =
  ## Get right complement 𝐠̅, i.e. components negated and read as point; 0 mul.
  let (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
  Point(x: -gˣ, y: -gʸ, w: -gʷ)

func complementLeft*(g: Line): Point {.inline.} =
  ## Get left complement 𝐠̲, equal to right one at grade 2 here; 0 mul.
  let (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
  Point(x: -gˣ, y: -gʸ, w: -gʷ)



#[ Reverses ]#

func reverse*(p: Point): Point {.inline.} =
  ## Get reverse 𝐩̃, i.e. point unchanged at grade 1; 0 mul.
  let (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
  Point(x: pˣ, y: pʸ, w: pʷ)

func reverse*(g: Line): Line {.inline.} =
  ## Get reverse 𝐠̃, i.e. line negated at grade 2; 0 mul.
  let (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
  Line(x: -gˣ, y: -gʸ, w: -gʷ)

func reverseAnti*(p: Point): Point {.inline.} =
  ## Get antireverse 𝐩̰, i.e. point negated at antigrade 2; 0 mul.
  let (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
  Point(x: -pˣ, y: -pʸ, w: -pʷ)

func reverseAnti*(g: Line): Line {.inline.} =
  ## Get antireverse 𝐠̰, i.e. line unchanged at antigrade 1; 0 mul.
  let (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
  Line(x: gˣ, y: gʸ, w: gʷ)



#[ Duals ]#

func dualBulk*(p: Point): Line {.inline.} =
  ## Get bulk dual 𝐩★, i.e. line through origin normal to position; 0 mul.
  let (pˣ, pʸ) = (p.x, p.y)
  Line(x: -pˣ, y: -pʸ, w: 0.0)

func dualWeight*(p: Point): Line {.inline.} =
  ## Get weight dual 𝐩☆, i.e. horizon scaled by weight; 0 mul.
  let pʷ = p.w
  Line(x: 0.0, y: 0.0, w: -pʷ)

func dualBulk*(g: Line): Point {.inline.} =
  ## Get bulk dual 𝐠★, i.e. origin scaled by position; 0 mul.
  let gʷ = g.w
  Point(x: 0.0, y: 0.0, w: -gʷ)

func dualWeight*(g: Line): Point {.inline.} =
  ## Get weight dual 𝐠☆, i.e. direction of normal at infinity; 0 mul.
  let (gˣ, gʸ) = (g.x, g.y)
  Point(x: -gˣ, y: -gʸ, w: 0.0)



#[ Bulks and Weights ]#

func bulk*(p: Point): Point {.inline.} =
  ## Get bulk 𝐩∙, i.e. position without weight; 0 mul.
  let (pˣ, pʸ) = (p.x, p.y)
  Point(x: pˣ, y: pʸ, w: 0.0)

func weight*(p: Point): Point {.inline.} =
  ## Get weight 𝐩∘, i.e. weight alone; 0 mul.
  let pʷ = p.w
  Point(x: 0.0, y: 0.0, w: pʷ)

func bulk*(g: Line): Line {.inline.} =
  ## Get bulk 𝐠∙, i.e. position alone; 0 mul.
  let gʷ = g.w
  Line(x: 0.0, y: 0.0, w: gʷ)

func weight*(g: Line): Line {.inline.} =
  ## Get weight 𝐠∘, i.e. normal alone; 0 mul.
  let (gˣ, gʸ) = (g.x, g.y)
  Line(x: gˣ, y: gʸ, w: 0.0)



#[ Attitudes ]#

func attitude*(p: Point): float {.inline.} =
  ## Get attitude of point, i.e. 𝐩 ∨ 𝐞̅₃, its weight as scalar; 0 mul.
  p.w

func attitude*(g: Line): Point {.inline.} =
  ## Get attitude of line, i.e. its direction as point at infinity; 0 mul.
  let (gˣ, gʸ) = (g.x, g.y)
  Point(x: gʸ, y: -gˣ, w: 0.0)



#[ Norms ]#

func normBulkSquared*(p: Point): float {.inline.} =
  ## Get squared bulk norm ‖𝐩‖∙²; 2 mul, 1 add.
  p.x * p.x + p.y * p.y

func normWeightSquared*(p: Point): float {.inline.} =
  ## Get squared weight norm ‖𝐩‖∘²; 1 mul.
  p.w * p.w

func normBulkSquared*(g: Line): float {.inline.} =
  ## Get squared bulk norm ‖𝐠‖∙²; 1 mul.
  g.w * g.w

func normWeightSquared*(g: Line): float {.inline.} =
  ## Get squared weight norm ‖𝐠‖∘²; 2 mul, 1 add.
  g.x * g.x + g.y * g.y

func normBulk*(p: Point): float {.inline.} =
  ## Get bulk norm ‖𝐩‖∙; 2 mul, 1 add, 1 sqrt.
  sqrt(p.x * p.x + p.y * p.y)

func normWeight*(p: Point): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐩‖∘, i.e. |w|; 1 abs.
  Antiscalar(abs(p.w))

func normBulk*(g: Line): float {.inline.} =
  ## Get bulk norm ‖𝐠‖∙, i.e. |w|; 1 abs.
  abs(g.w)

func normWeight*(g: Line): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐠‖∘; 2 mul, 1 add, 1 sqrt.
  Antiscalar(sqrt(g.x * g.x + g.y * g.y))



#[ Unitizations ]#

func unitize*(p: Point): Point {.inline.} =
  ## Unitize point so |w| = 1, i.e. 𝐩 / ‖𝐩‖∘; 1 abs, 1 div, 3 mul.
  ##   Weight norm is size of w, so sign of w stays, as book's rule keeps it; Lengyel's code
  ##     divides by signed w instead, and Architect chose book's rule on 2026-10-10.
  ##   No-op where weight is zero, as library's unitize is: factor is then 1.
  let
    (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
    n = if pʷ == 0.0: 1.0 else: 1.0 / abs(pʷ)
  Point(x: pˣ * n, y: pʸ * n, w: pʷ * n)

func unitize*(g: Line): Line {.inline.} =
  ## Unitize line so normal has unit length, i.e. 𝐠 / ‖𝐠‖∘; 2 mul, 1 add, 1 sqrt, 1 div, 3 mul.
  ##   No-op where weight is zero: factor is then 1.
  let
    (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
    s = gˣ * gˣ + gʸ * gʸ
    n = if s == 0.0: 1.0 else: 1.0 / sqrt(s)
  Line(x: gˣ * n, y: gʸ * n, w: gʷ * n)



#[ Supports ]#

func support*(g: Line): Point {.inline.} =
  ## Get support of line, i.e. point on it closest to origin; 4 mul, 1 add.
  let (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
  Point(x: -(gʷ * gˣ), y: -(gʷ * gʸ), w: gˣ * gˣ + gʸ * gʸ)

func supportAnti*(p: Point): Line {.inline.} =
  ## Get antisupport of point, i.e. line through it normal to its position; 4 mul, 1 add.
  let (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
  Line(x: pʷ * pˣ, y: pʷ * pʸ, w: -(pˣ * pˣ) - pʸ * pʸ)



#[ Projections ]#

func projectOrthogonal*(p: Point, g: Line): Point {.inline.} =
  ## Project point orthogonally onto line, homogeneous, i.e. 𝐠 ∨ (𝐩 ∧ 𝐠☆); 10 mul, 4 add.
  ##   Offset along line is gʸpˣ − gˣpʸ, offset from origin is gʷpʷ.
  let
    (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
    (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
    d = gʸ * pˣ - gˣ * pʸ
    e = gʷ * pʷ
  Point(x: gʸ * d - gˣ * e, y: -(gˣ * d) - gʸ * e, w: pʷ * (gˣ * gˣ + gʸ * gʸ))



#[ Motors ]#

func wedgeDotAnti*(a, b: Motor): Motor {.inline.} =
  ## Compose motors through geometric antiproduct, i.e. 𝐚 ⟇ 𝐛; 12 mul, 8 add.
  let
    (aˣ, aʸ, aᶻ, aʷ) = (a.x, a.y, a.z, a.w)
    (bˣ, bʸ, bᶻ, bʷ) = (b.x, b.y, b.z, b.w)
  Motor(
    x: aʷ * bˣ + aˣ * bʷ + aʸ * bᶻ - aᶻ * bʸ,
    y: aʷ * bʸ - aˣ * bᶻ + aʸ * bʷ + aᶻ * bˣ,
    z: aʷ * bᶻ + aᶻ * bʷ,
    w: aʷ * bʷ - aᶻ * bᶻ,
  )

func reverseAnti*(q: Motor): Motor {.inline.} =
  ## Get antireverse 𝐐̰, i.e. inverse of unit motor; 0 mul.
  let (qˣ, qʸ, qᶻ, qʷ) = (q.x, q.y, q.z, q.w)
  Motor(x: -qˣ, y: -qʸ, z: -qᶻ, w: qʷ)

func normWeightSquared*(q: Motor): float {.inline.} =
  ## Get squared weight norm ‖𝐐‖∘²; 2 mul, 1 add.
  q.z * q.z + q.w * q.w

func normBulkSquared*(q: Motor): float {.inline.} =
  ## Get squared bulk norm ‖𝐐‖∙²; 2 mul, 1 add.
  q.x * q.x + q.y * q.y

func normWeight*(q: Motor): Antiscalar {.inline.} =
  ## Get weight norm ‖𝐐‖∘; 2 mul, 1 add, 1 sqrt.
  Antiscalar(sqrt(q.z * q.z + q.w * q.w))

func normBulk*(q: Motor): float {.inline.} =
  ## Get bulk norm ‖𝐐‖∙; 2 mul, 1 add, 1 sqrt.
  sqrt(q.x * q.x + q.y * q.y)

func unitize*(q: Motor): Motor {.inline.} =
  ## Unitize motor so weight norm is 𝟙; 2 mul, 1 add, 1 sqrt, 1 div, 4 mul.
  ##   No-op where weight is zero: factor is then 1.
  let
    (qˣ, qʸ, qᶻ, qʷ) = (q.x, q.y, q.z, q.w)
    s = qᶻ * qᶻ + qʷ * qʷ
    n = if s == 0.0: 1.0 else: 1.0 / sqrt(s)
  Motor(x: qˣ * n, y: qʸ * n, z: qᶻ * n, w: qʷ * n)

func transform*(p: Point, q: Motor): Point {.inline.} =
  ## Move point by motor, i.e. 𝐐 ⟇ 𝐩 ⟇ 𝐐̰; 14 mul, 10 add.
  ##   Rotation by cosine (Qʷ)² − (Qᶻ)² and sine 2QᶻQʷ, then translation by
  ##   2(QˣQᶻ + QʸQʷ, QʸQᶻ − QˣQʷ) scaled by weight; weight scaled by (Qᶻ)² + (Qʷ)².
  let
    (pˣ, pʸ, pʷ) = (p.x, p.y, p.w)
    (qˣ, qʸ, qᶻ, qʷ) = (q.x, q.y, q.z, q.w)
    (sᶻᶻ, sʷʷ) = (qᶻ * qᶻ, qʷ * qʷ)
    c = sʷʷ - sᶻᶻ
    s = (qᶻ + qᶻ) * qʷ
    w = pʷ + pʷ
  Point(
    x: pˣ * c - pʸ * s + (qˣ * qᶻ + qʸ * qʷ) * w,
    y: pʸ * c + pˣ * s + (qʸ * qᶻ - qˣ * qʷ) * w,
    w: (sᶻᶻ + sʷʷ) * pʷ,
  )

func transform*(g: Line, q: Motor): Line {.inline.} =
  ## Move line by motor, i.e. 𝐐 ⟇ 𝐠 ⟇ 𝐐̰; 14 mul, 10 add.
  ##   Normal rotates as point's position does; position, scaled by (Qᶻ)² + (Qʷ)², gains normal
  ##   ∙ translation.
  let
    (gˣ, gʸ, gʷ) = (g.x, g.y, g.w)
    (qˣ, qʸ, qᶻ, qʷ) = (q.x, q.y, q.z, q.w)
    (sᶻᶻ, sʷʷ) = (qᶻ * qᶻ, qʷ * qʷ)
    c = sʷʷ - sᶻᶻ
    s = (qᶻ + qᶻ) * qʷ
    t = (qˣ * qᶻ - qʸ * qʷ) * gˣ + (qʸ * qᶻ + qˣ * qʷ) * gʸ
  Line(x: gˣ * c - gʸ * s, y: gʸ * c + gˣ * s, w: (sᶻᶻ + sʷʷ) * gʷ + (t + t))

func rotor*(center: Point, angle: float): Motor {.inline.} =
  ## Construct rotation motor about unit point; 3 mul, 1 sin, 1 cos.
  let
    (centerˣ, centerʸ) = (center.x, center.y)
    h = angle * 0.5
    s = sin(h)
  Motor(x: centerˣ * s, y: centerʸ * s, z: s, w: cos(h))

func translator*(x, y: float): Motor {.inline.} =
  ## Construct translation motor by (x, y), i.e. 𝟙 + (−y e₁ + x e₂) / 2; 2 mul.
  Motor(x: -(y * 0.5), y: x * 0.5, z: 0.0, w: 1.0)
