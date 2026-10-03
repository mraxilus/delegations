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
##     code spends. No function calls another, so none fills result or checks error flag;
##     suite `Internal: Inspector` holds every reference function to that.
##   Cost: transforms assume unit motor, i.e. Qᶻ² + Qʷ² = 1, as every motor composed of
##     rotations and translations is; weight of point passes through unchanged.

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
  Line(x: p.y * q.w - p.w * q.y, y: p.w * q.x - p.x * q.w, w: p.x * q.y - p.y * q.x)

func wedge*(p: Point, g: Line): Antiscalar {.inline.} =
  ## Join point and line in antiscalar measuring incidence, i.e. 𝐩 ∧ 𝐠; 3 mul, 2 add.
  Antiscalar(-(p.x * g.x) - p.y * g.y - p.w * g.w)

func wedge*(g: Line, p: Point): Antiscalar {.inline.} =
  ## Join line and point, i.e. 𝐠 ∧ 𝐩 = 𝐩 ∧ 𝐠 since grades 1 and 2 commute here; 3 mul, 2 add.
  Antiscalar(-(g.x * p.x) - g.y * p.y - g.w * p.w)

func wedgeAnti*(g, h: Line): Point {.inline.} =
  ## Meet lines in point, i.e. 𝐠 ∨ 𝐡; 6 mul, 3 sub.
  Point(x: g.w * h.y - g.y * h.w, y: g.x * h.w - g.w * h.x, w: g.y * h.x - g.x * h.y)

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
  Line(x: -p.x, y: -p.y, w: -p.w)

func complementLeft*(p: Point): Line {.inline.} =
  ## Get left complement 𝐩̲, equal to right one at grade 1 here; 0 mul.
  Line(x: -p.x, y: -p.y, w: -p.w)

func complementRight*(g: Line): Point {.inline.} =
  ## Get right complement 𝐠̅, i.e. components negated and read as point; 0 mul.
  Point(x: -g.x, y: -g.y, w: -g.w)

func complementLeft*(g: Line): Point {.inline.} =
  ## Get left complement 𝐠̲, equal to right one at grade 2 here; 0 mul.
  Point(x: -g.x, y: -g.y, w: -g.w)



#[ Reverses ]#

func reverse*(p: Point): Point {.inline.} =
  ## Get reverse 𝐩̃, i.e. point unchanged at grade 1; 0 mul.
  Point(x: p.x, y: p.y, w: p.w)

func reverse*(g: Line): Line {.inline.} =
  ## Get reverse 𝐠̃, i.e. line negated at grade 2; 0 mul.
  Line(x: -g.x, y: -g.y, w: -g.w)

func reverseAnti*(p: Point): Point {.inline.} =
  ## Get antireverse 𝐩̰, i.e. point negated at antigrade 2; 0 mul.
  Point(x: -p.x, y: -p.y, w: -p.w)

func reverseAnti*(g: Line): Line {.inline.} =
  ## Get antireverse 𝐠̰, i.e. line unchanged at antigrade 1; 0 mul.
  Line(x: g.x, y: g.y, w: g.w)



#[ Duals ]#

func dualBulk*(p: Point): Line {.inline.} =
  ## Get bulk dual 𝐩★, i.e. line through origin normal to position; 0 mul.
  Line(x: -p.x, y: -p.y, w: 0.0)

func dualWeight*(p: Point): Line {.inline.} =
  ## Get weight dual 𝐩☆, i.e. horizon scaled by weight; 0 mul.
  Line(x: 0.0, y: 0.0, w: -p.w)

func dualBulk*(g: Line): Point {.inline.} =
  ## Get bulk dual 𝐠★, i.e. origin scaled by position; 0 mul.
  Point(x: 0.0, y: 0.0, w: -g.w)

func dualWeight*(g: Line): Point {.inline.} =
  ## Get weight dual 𝐠☆, i.e. direction of normal at infinity; 0 mul.
  Point(x: -g.x, y: -g.y, w: 0.0)



#[ Bulks and Weights ]#

func bulk*(p: Point): Point {.inline.} =
  ## Get bulk 𝐩∙, i.e. position without weight; 0 mul.
  Point(x: p.x, y: p.y, w: 0.0)

func weight*(p: Point): Point {.inline.} =
  ## Get weight 𝐩∘, i.e. weight alone; 0 mul.
  Point(x: 0.0, y: 0.0, w: p.w)

func bulk*(g: Line): Line {.inline.} =
  ## Get bulk 𝐠∙, i.e. position alone; 0 mul.
  Line(x: 0.0, y: 0.0, w: g.w)

func weight*(g: Line): Line {.inline.} =
  ## Get weight 𝐠∘, i.e. normal alone; 0 mul.
  Line(x: g.x, y: g.y, w: 0.0)



#[ Attitudes ]#

func attitude*(p: Point): float {.inline.} =
  ## Get attitude of point, i.e. 𝐩 ∨ 𝐞̅₃, its weight as scalar; 0 mul.
  p.w

func attitude*(g: Line): Point {.inline.} =
  ## Get attitude of line, i.e. its direction as point at infinity; 0 mul.
  Point(x: g.y, y: -g.x, w: 0.0)



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
  ## Unitize point so w = 1, i.e. 𝐩 / ‖𝐩‖∘; 1 div, 2 mul.
  ##   No-op where weight is zero, as library's unitize is.
  if p.w == 0.0: return p
  let n = 1.0 / p.w
  Point(x: p.x * n, y: p.y * n, w: 1.0)

func unitize*(g: Line): Line {.inline.} =
  ## Unitize line so normal has unit length, i.e. 𝐠 / ‖𝐠‖∘; 2 mul, 1 add, 1 rsqrt, 3 mul.
  ##   No-op where weight is zero.
  let s = g.x * g.x + g.y * g.y
  if s == 0.0: return g
  let n = 1.0 / sqrt(s)
  Line(x: g.x * n, y: g.y * n, w: g.w * n)



#[ Supports ]#

func support*(g: Line): Point {.inline.} =
  ## Get support of line, i.e. point on it closest to origin; 4 mul, 1 add.
  Point(x: -(g.w * g.x), y: -(g.w * g.y), w: g.x * g.x + g.y * g.y)

func supportAnti*(p: Point): Line {.inline.} =
  ## Get antisupport of point, i.e. line through it normal to its position; 4 mul, 1 add.
  Line(x: p.w * p.x, y: p.w * p.y, w: -(p.x * p.x) - p.y * p.y)



#[ Projections ]#

func projectOrthogonal*(p: Point, g: Line): Point {.inline.} =
  ## Project point orthogonally onto line, homogeneous, i.e. 𝐠 ∨ (𝐩 ∧ 𝐠☆); 10 mul, 4 add.
  ##   Offset along line is gʸpˣ − gˣpʸ, offset from origin is gʷpʷ.
  let
    d = g.y * p.x - g.x * p.y
    e = g.w * p.w
  Point(x: g.y * d - g.x * e, y: -(g.x * d) - g.y * e, w: p.w * (g.x * g.x + g.y * g.y))



#[ Motors ]#

func wedgeDotAnti*(a, b: Motor): Motor {.inline.} =
  ## Compose motors through geometric antiproduct, i.e. 𝐚 ⟇ 𝐛; 12 mul, 8 add.
  Motor(
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
    z: a.w * b.z + a.z * b.w,
    w: a.w * b.w - a.z * b.z,
  )

func reverseAnti*(q: Motor): Motor {.inline.} =
  ## Get antireverse 𝐐̰, i.e. inverse of unit motor; 0 mul.
  Motor(x: -q.x, y: -q.y, z: -q.z, w: q.w)

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
  ## Unitize motor so weight norm is 𝟙; 2 mul, 1 add, 1 rsqrt, 4 mul.
  ##   No-op where weight is zero.
  let s = q.z * q.z + q.w * q.w
  if s == 0.0: return q
  let n = 1.0 / sqrt(s)
  Motor(x: q.x * n, y: q.y * n, z: q.z * n, w: q.w * n)

func transform*(p: Point, q: Motor): Point {.inline.} =
  ## Move point by unit motor, i.e. 𝐐 ⟇ 𝐩 ⟇ 𝐐̰; 15 mul, 7 add.
  ##   Rotation by angle whose cosine is 1 − 2Qᶻ² and sine 2QᶻQʷ, then translation by
  ##   2(QˣQᶻ + QʸQʷ, QʸQᶻ − QˣQʷ) scaled by weight.
  let
    c = 1.0 - 2.0 * q.z * q.z
    s = 2.0 * q.z * q.w
    w = 2.0 * p.w
  Point(
    x: p.x * c - p.y * s + (q.x * q.z + q.y * q.w) * w,
    y: p.y * c + p.x * s + (q.y * q.z - q.x * q.w) * w,
    w: p.w,
  )

func transform*(g: Line, q: Motor): Line {.inline.} =
  ## Move line by unit motor, i.e. 𝐐 ⟇ 𝐠 ⟇ 𝐐̰; 15 mul, 7 add.
  ##   Normal rotates; position gains normal ∙ translation.
  let
    c = 1.0 - 2.0 * q.z * q.z
    s = 2.0 * q.z * q.w
  Line(
    x: g.x * c - g.y * s,
    y: g.y * c + g.x * s,
    w: g.w + ((q.x * q.z - q.y * q.w) * g.x + (q.y * q.z + q.x * q.w) * g.y) * 2.0,
  )

func rotor*(center: Point, angle: float): Motor {.inline.} =
  ## Construct rotation motor about unit point; 4 mul, 1 sin, 1 cos.
  let
    h = angle * 0.5
    s = sin(h)
  Motor(x: center.x * s, y: center.y * s, z: s, w: cos(h))

func translator*(x, y: float): Motor {.inline.} =
  ## Construct translation motor by (x, y), i.e. 𝟙 + (−y e₁ + x e₂) / 2; 2 mul.
  Motor(x: -(y * 0.5), y: x * 0.5, z: 0.0, w: 1.0)
