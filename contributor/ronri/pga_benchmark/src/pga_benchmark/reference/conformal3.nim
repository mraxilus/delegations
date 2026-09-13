## Derive Lengyel's typed objects and hand-rolled operations of 3D conformal geometric algebra.
##   Reference every dense library operation is measured against under five dimensions:
##   round points, dipoles, circles and spheres hold only components their grade carries,
##   and each operation spells only surviving terms. Forms follow *Projective Geometric
##   Algebra Illuminated* and conformalgeometricalgebra.org; Terathon Math Library (MIT,
##   Eric Lengyel) was read to cross-check forms and counts, and nothing is copied from
##   it. Scalar is `float`, as library's.
##
##   |------------|----------------------------------------------|-------------------------|
##   | Code       | Notation                                     | Library basis           |
##   |------------|----------------------------------------------|-------------------------|
##   | RoundPoint | 𝐚 = x y z (e₁ e₂ e₃) + w e₄ + u e₅           | E1 E2 E3 E4 E5          |
##   | Dipole     | 𝐝 = dᵛ + dᵐ + dᵖ(e₁₅ e₂₅ e₃₅ e₄₅)            | E41.. E23.. E15.. E45   |
##   | Circle     | 𝐜 = cᵍ(e₄₂₃ e₄₃₁ e₄₁₂ e₃₂₁) + cᵛ + cᵐ        | E423.. E415.. E235..    |
##   | Sphere     | 𝐬 = u e₁₂₃₄ + x y z (e₄₂₃₅ e₄₃₁₅ e₄₁₂₅) + w e₃₂₁₅ | E1234 E4235.. E3215 |
##   | FlatPoint  | 𝐩 = x y z w (e₁₅ e₂₅ e₃₅ e₄₅)                | E15 E25 E35 E45         |
##   | FlatLine   | 𝐥 = lᵛ(e₄₁₅ e₄₂₅ e₄₃₅) + lᵐ(e₂₃₅ e₃₁₅ e₁₂₅)  | E415.. E235..           |
##   | FlatPlane  | 𝐠 = x y z w (e₄₂₃₅ e₄₃₁₅ e₄₁₂₅ e₃₂₁₅)        | E4235.. E3215           |
##   |------------|----------------------------------------------|-------------------------|
##
##   Unary maps (complements, duals, attitude, carrier, cocarrier) are signed slot
##     permutations; signs are library's, read off its own tables on basis elements and
##     held by suite `Chapter 2`. Where Terathon's `Cocarrier` of circle orders direction
##     and moment differently, library's table wins.
##   Norms and unitize carry no reference here: library defines them as square roots of
##     inner products, which are indefinite under conformal metric and yield NaN on real
##     objects; gap list records that from measured NaN share rather than from any form.
##   Cost: only round-object rows exist; flats are results of carriers, never operands.

{.experimental: "strictFuncs".}

import ./scalars

export scalars


type
  Vec3* = object
    ## Define three components named as vector; direction, moment or normal.
    x*, y*, z*: float
  RoundPoint* = object
    ## Define round point 𝐚 with position x y z, weight w and flat bulk u; grade 1.
    x*, y*, z*, w*, u*: float
  FlatPoint* = object
    ## Define flat point 𝐩 with position and weight; grade 2, contains e₅.
    x*, y*, z*, w*: float
  Dipole* = object
    ## Define dipole 𝐝 with carrier direction v, carrier moment m and flat part p; grade 2.
    v*, m*: Vec3
    p*: FlatPoint
  FlatPlane* = object
    ## Define flat plane 𝐠 with normal x y z and position w; grade 4, contains e₅.
    x*, y*, z*, w*: float
  CarrierPlane* = object
    ## Define carrier plane of circle, i.e. its grade-3 part without e₅.
    x*, y*, z*, w*: float
  Circle* = object
    ## Define circle 𝐜 with carrier plane g, flat direction v and flat moment m; grade 3.
    g*: CarrierPlane
    v*, m*: Vec3
  FlatLine* = object
    ## Define flat line 𝐥 with direction v and moment m; grade 3, contains e₅.
    v*, m*: Vec3
  Sphere* = object
    ## Define sphere 𝐬 with carrier weight u, flat normal x y z and position w; grade 4.
    u*, x*, y*, z*, w*: float



#[ Vector Helpers ]#

func dot*(a, b: Vec3): float {.inline.} =
  ## Dot product, i.e. 𝐚 ∙ 𝐛; 3 mul, 2 add.
  a.x * b.x + a.y * b.y + a.z * b.z

template zero3(): Vec3 =
  ## Spell zero vector by components; `Vec3()` costs zero fill and hook calls here.
  Vec3(x: 0.0, y: 0.0, z: 0.0)

template read3(v: Vec3): Vec3 =
  ## Spell copy of vector by components; whole-object copy costs `=dup` hook call here.
  Vec3(x: v.x, y: v.y, z: v.z)

template zeroFlatPoint(): FlatPoint =
  ## Spell zero flat point by components.
  FlatPoint(x: 0.0, y: 0.0, z: 0.0, w: 0.0)

template zeroCarrier(): CarrierPlane =
  ## Spell zero carrier plane by components.
  CarrierPlane(x: 0.0, y: 0.0, z: 0.0, w: 0.0)


func `-`*(a: Vec3): Vec3 {.inline.} =
  ## Negated vector; 0 mul.
  Vec3(x: -a.x, y: -a.y, z: -a.z)

func `*`*(a: Vec3; s: float): Vec3 {.inline.} =
  ## Vector scaled; 3 mul.
  Vec3(x: a.x * s, y: a.y * s, z: a.z * s)



#[ Exterior Products ]#

func wedge*(a, b: RoundPoint): Dipole {.inline.} =
  ## Join round points into dipole, i.e. 𝐚 ∧ 𝐛; 20 mul, 10 sub.
  Dipole(
    v: Vec3(x: a.w * b.x - a.x * b.w, y: a.w * b.y - a.y * b.w, z: a.w * b.z - a.z * b.w),
    m: Vec3(x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x),
    p: FlatPoint(
      x: a.x * b.u - a.u * b.x, y: a.y * b.u - a.u * b.y, z: a.z * b.u - a.u * b.z,
      w: a.w * b.u - a.u * b.w,
    ),
  )

func wedge*(d: Dipole; a: RoundPoint): Circle {.inline.} =
  ## Join dipole and round point into circle, i.e. 𝐝 ∧ 𝐚; 30 mul, 20 add.
  Circle(
    g: CarrierPlane(
      x: d.v.y * a.z - d.v.z * a.y + d.m.x * a.w,
      y: d.v.z * a.x - d.v.x * a.z + d.m.y * a.w,
      z: d.v.x * a.y - d.v.y * a.x + d.m.z * a.w,
      w: -d.m.x * a.x - d.m.y * a.y - d.m.z * a.z,
    ),
    v: Vec3(
      x: d.p.x * a.w - d.p.w * a.x + d.v.x * a.u,
      y: d.p.y * a.w - d.p.w * a.y + d.v.y * a.u,
      z: d.p.z * a.w - d.p.w * a.z + d.v.z * a.u,
    ),
    m: Vec3(
      x: d.p.z * a.y - d.p.y * a.z + d.m.x * a.u,
      y: d.p.x * a.z - d.p.z * a.x + d.m.y * a.u,
      z: d.p.y * a.x - d.p.x * a.y + d.m.z * a.u,
    ),
  )

func wedge*(a: RoundPoint; d: Dipole): Circle {.inline.} =
  ## Join round point and dipole, i.e. 𝐚 ∧ 𝐝 = 𝐝 ∧ 𝐚 since grades 1 and 2 commute.
  wedge(d, a)

func wedge*(c: Circle; a: RoundPoint): Sphere {.inline.} =
  ## Join circle and round point into sphere, i.e. 𝐜 ∧ 𝐚; 20 mul, 15 add.
  Sphere(
    u: -c.g.x * a.x - c.g.y * a.y - c.g.z * a.z - c.g.w * a.w,
    x: c.v.z * a.y - c.v.y * a.z - c.m.x * a.w + c.g.x * a.u,
    y: c.v.x * a.z - c.v.z * a.x - c.m.y * a.w + c.g.y * a.u,
    z: c.v.y * a.x - c.v.x * a.y - c.m.z * a.w + c.g.z * a.u,
    w: c.m.x * a.x + c.m.y * a.y + c.m.z * a.z + c.g.w * a.u,
  )

func wedge*(a: RoundPoint; c: Circle): Sphere {.inline.} =
  ## Join round point and circle, i.e. 𝐚 ∧ 𝐜 = −(𝐜 ∧ 𝐚); 20 mul, 15 add.
  Sphere(
    u: a.x * c.g.x + a.y * c.g.y + a.z * c.g.z + a.w * c.g.w,
    x: a.z * c.v.y - a.y * c.v.z + a.w * c.m.x - a.u * c.g.x,
    y: a.x * c.v.z - a.z * c.v.x + a.w * c.m.y - a.u * c.g.y,
    z: a.y * c.v.x - a.x * c.v.y + a.w * c.m.z - a.u * c.g.z,
    w: -a.x * c.m.x - a.y * c.m.y - a.z * c.m.z - a.u * c.g.w,
  )

func wedge*(d, f: Dipole): Sphere {.inline.} =
  ## Join dipoles into sphere, i.e. 𝐝 ∧ 𝐟; 30 mul, 25 add.
  Sphere(
    u: -d.m.x * f.v.x - d.m.y * f.v.y - d.m.z * f.v.z -
      d.v.x * f.m.x - d.v.y * f.m.y - d.v.z * f.m.z,
    x: d.p.z * f.v.y - d.p.y * f.v.z + d.v.y * f.p.z - d.v.z * f.p.y +
      d.m.x * f.p.w + d.p.w * f.m.x,
    y: d.p.x * f.v.z - d.p.z * f.v.x + d.v.z * f.p.x - d.v.x * f.p.z +
      d.m.y * f.p.w + d.p.w * f.m.y,
    z: d.p.y * f.v.x - d.p.x * f.v.y + d.v.x * f.p.y - d.v.y * f.p.x +
      d.m.z * f.p.w + d.p.w * f.m.z,
    w: -d.m.x * f.p.x - d.m.y * f.p.y - d.m.z * f.p.z -
      d.p.x * f.m.x - d.p.y * f.m.y - d.p.z * f.m.z,
  )

func wedgeAnti*(s, t: Sphere): Circle {.inline.} =
  ## Meet spheres in circle, i.e. 𝐬 ∨ 𝐭; 20 mul, 10 sub.
  Circle(
    g: CarrierPlane(
      x: s.u * t.x - s.x * t.u, y: s.u * t.y - s.y * t.u, z: s.u * t.z - s.z * t.u,
      w: s.u * t.w - s.w * t.u,
    ),
    v: Vec3(x: s.z * t.y - s.y * t.z, y: s.x * t.z - s.z * t.x, z: s.y * t.x - s.x * t.y),
    m: Vec3(x: s.x * t.w - s.w * t.x, y: s.y * t.w - s.w * t.y, z: s.z * t.w - s.w * t.z),
  )

func wedgeAnti*(s: Sphere; c: Circle): Dipole {.inline.} =
  ## Meet sphere and circle in dipole, i.e. 𝐬 ∨ 𝐜; 30 mul, 20 add.
  Dipole(
    v: Vec3(
      x: s.y * c.g.z - s.z * c.g.y + s.u * c.v.x,
      y: s.z * c.g.x - s.x * c.g.z + s.u * c.v.y,
      z: s.x * c.g.y - s.y * c.g.x + s.u * c.v.z,
    ),
    m: Vec3(
      x: s.w * c.g.x - s.x * c.g.w + s.u * c.m.x,
      y: s.w * c.g.y - s.y * c.g.w + s.u * c.m.y,
      z: s.w * c.g.z - s.z * c.g.w + s.u * c.m.z,
    ),
    p: FlatPoint(
      x: s.z * c.m.y - s.y * c.m.z + s.w * c.v.x,
      y: s.x * c.m.z - s.z * c.m.x + s.w * c.v.y,
      z: s.y * c.m.x - s.x * c.m.y + s.w * c.v.z,
      w: -s.x * c.v.x - s.y * c.v.y - s.z * c.v.z,
    ),
  )

func wedgeAnti*(c: Circle; s: Sphere): Dipole {.inline.} =
  ## Meet circle and sphere, i.e. 𝐜 ∨ 𝐬 = 𝐬 ∨ 𝐜 since antigrades 1 and 2 commute.
  wedgeAnti(s, c)

func wedgeAnti*(c, o: Circle): RoundPoint {.inline.} =
  ## Meet circles in round point, i.e. 𝐜 ∨ 𝐨; 30 mul, 25 add.
  RoundPoint(
    x: c.g.z * o.m.y - c.g.y * o.m.z + c.m.y * o.g.z - c.m.z * o.g.y +
      c.g.w * o.v.x + c.v.x * o.g.w,
    y: c.g.x * o.m.z - c.g.z * o.m.x + c.m.z * o.g.x - c.m.x * o.g.z +
      c.g.w * o.v.y + c.v.y * o.g.w,
    z: c.g.y * o.m.x - c.g.x * o.m.y + c.m.x * o.g.y - c.m.y * o.g.x +
      c.g.w * o.v.z + c.v.z * o.g.w,
    w: -c.g.x * o.v.x - c.g.y * o.v.y - c.g.z * o.v.z -
      c.v.x * o.g.x - c.v.y * o.g.y - c.v.z * o.g.z,
    u: -c.m.x * o.v.x - c.m.y * o.v.y - c.m.z * o.v.z -
      c.v.x * o.m.x - c.v.y * o.m.y - c.v.z * o.m.z,
  )

func wedgeAnti*(s: Sphere; d: Dipole): RoundPoint {.inline.} =
  ## Meet sphere and dipole in round point, i.e. 𝐬 ∨ 𝐝; 20 mul, 15 add.
  RoundPoint(
    x: s.y * d.m.z - s.z * d.m.y + s.u * d.p.x - s.w * d.v.x,
    y: s.z * d.m.x - s.x * d.m.z + s.u * d.p.y - s.w * d.v.y,
    z: s.x * d.m.y - s.y * d.m.x + s.u * d.p.z - s.w * d.v.z,
    w: s.x * d.v.x + s.y * d.v.y + s.z * d.v.z + s.u * d.p.w,
    u: -s.x * d.p.x - s.y * d.p.y - s.z * d.p.z - s.w * d.p.w,
  )

func wedgeAnti*(d: Dipole; s: Sphere): RoundPoint {.inline.} =
  ## Meet dipole and sphere, i.e. 𝐝 ∨ 𝐬 = −(𝐬 ∨ 𝐝); 20 mul, 15 add.
  RoundPoint(
    x: d.m.y * s.z - d.m.z * s.y + d.v.x * s.w - d.p.x * s.u,
    y: d.m.z * s.x - d.m.x * s.z + d.v.y * s.w - d.p.y * s.u,
    z: d.m.x * s.y - d.m.y * s.x + d.v.z * s.w - d.p.z * s.u,
    w: -d.v.x * s.x - d.v.y * s.y - d.v.z * s.z - d.p.w * s.u,
    u: d.p.x * s.x + d.p.y * s.y + d.p.z * s.z + d.p.w * s.w,
  )



#[ Inner Products ]#

func dot*(a, b: RoundPoint): float {.inline.} =
  ## Inner product of round points under conformal metric, i.e. 𝐚 ∙ 𝐛; 5 mul, 4 add.
  a.x * b.x + a.y * b.y + a.z * b.z - a.w * b.u - a.u * b.w

func dot*(d, f: Dipole): float {.inline.} =
  ## Inner product of dipoles, i.e. 𝐝 ∙ 𝐟; 10 mul, 9 add.
  dot(d.v, Vec3(x: f.p.x, y: f.p.y, z: f.p.z)) + dot(d.m, f.m) +
    dot(Vec3(x: d.p.x, y: d.p.y, z: d.p.z), f.v) - d.p.w * f.p.w

func dot*(c, o: Circle): float {.inline.} =
  ## Inner product of circles, i.e. 𝐜 ∙ 𝐨; 10 mul, 9 add.
  c.g.w * o.g.w - dot(Vec3(x: c.g.x, y: c.g.y, z: c.g.z), o.m) -
    dot(c.m, Vec3(x: o.g.x, y: o.g.y, z: o.g.z)) - dot(c.v, o.v)

func dot*(s, t: Sphere): float {.inline.} =
  ## Inner product of spheres, i.e. 𝐬 ∙ 𝐭; 5 mul, 4 add.
  s.u * t.w + s.w * t.u - s.x * t.x - s.y * t.y - s.z * t.z

func dotAnti*(a, b: RoundPoint): Antiscalar {.inline.} =
  ## Inner antiproduct of round points, i.e. 𝐚 ∘ 𝐛 = −(𝐚 ∙ 𝐛)𝟙 here; 5 mul, 4 add.
  Antiscalar(-dot(a, b))

func dotAnti*(d, f: Dipole): Antiscalar {.inline.} =
  ## Inner antiproduct of dipoles, i.e. 𝐝 ∘ 𝐟; 10 mul, 9 add.
  Antiscalar(-dot(d, f))

func dotAnti*(c, o: Circle): Antiscalar {.inline.} =
  ## Inner antiproduct of circles, i.e. 𝐜 ∘ 𝐨; 10 mul, 9 add.
  Antiscalar(-dot(c, o))

func dotAnti*(s, t: Sphere): Antiscalar {.inline.} =
  ## Inner antiproduct of spheres, i.e. 𝐬 ∘ 𝐭; 5 mul, 4 add.
  Antiscalar(-dot(s, t))



#[ Complements, Reverses, Duals ]#

func complementRight*(a: RoundPoint): Sphere {.inline.} =
  ## Right complement 𝐚̅, same components read as sphere; 0 mul.
  Sphere(u: a.u, x: a.x, y: a.y, z: a.z, w: a.w)

func complementLeft*(a: RoundPoint): Sphere {.inline.} =
  ## Left complement 𝐚̲, equal to right one for grade 1 in five dimensions; 0 mul.
  complementRight(a)

func complementRight*(s: Sphere): RoundPoint {.inline.} =
  ## Right complement 𝐬̅, same components read as round point; 0 mul.
  RoundPoint(x: s.x, y: s.y, z: s.z, w: s.w, u: s.u)

func complementLeft*(s: Sphere): RoundPoint {.inline.} =
  ## Left complement 𝐬̲, equal to right one; 0 mul.
  complementRight(s)

func complementRight*(d: Dipole): Circle {.inline.} =
  ## Right complement 𝐝̅, negated with flat part becoming carrier plane; 0 mul.
  Circle(g: CarrierPlane(x: -d.p.x, y: -d.p.y, z: -d.p.z, w: -d.p.w), v: -d.m, m: -d.v)

func complementLeft*(d: Dipole): Circle {.inline.} =
  ## Left complement 𝐝̲, equal to right one for grade 2; 0 mul.
  complementRight(d)

func complementRight*(c: Circle): Dipole {.inline.} =
  ## Right complement 𝐜̅, negated with carrier plane becoming flat part; 0 mul.
  Dipole(v: -c.m, m: -c.v, p: FlatPoint(x: -c.g.x, y: -c.g.y, z: -c.g.z, w: -c.g.w))

func complementLeft*(c: Circle): Dipole {.inline.} =
  ## Left complement 𝐜̲, equal to right one for grade 3; 0 mul.
  complementRight(c)

func reverse*(a: RoundPoint): RoundPoint {.inline.} =
  ## Reverse 𝐚̃, identity on grade 1; 0 mul.
  a

func reverse*(d: Dipole): Dipole {.inline.} =
  ## Reverse 𝐝̃, negation on grade 2; 0 mul.
  Dipole(v: -d.v, m: -d.m, p: FlatPoint(x: -d.p.x, y: -d.p.y, z: -d.p.z, w: -d.p.w))

func reverse*(c: Circle): Circle {.inline.} =
  ## Reverse 𝐜̃, negation on grade 3; 0 mul.
  Circle(g: CarrierPlane(x: -c.g.x, y: -c.g.y, z: -c.g.z, w: -c.g.w), v: -c.v, m: -c.m)

func reverse*(s: Sphere): Sphere {.inline.} =
  ## Reverse 𝐬̃, identity on grade 4; 0 mul.
  s

func reverseAnti*(a: RoundPoint): RoundPoint {.inline.} =
  ## Antireverse 𝐚̰, identity on antigrade 4; 0 mul.
  a

func reverseAnti*(d: Dipole): Dipole {.inline.} =
  ## Antireverse 𝐝̰, negation on antigrade 3; 0 mul.
  reverse(d)

func reverseAnti*(c: Circle): Circle {.inline.} =
  ## Antireverse 𝐜̰, negation on antigrade 2; 0 mul.
  reverse(c)

func reverseAnti*(s: Sphere): Sphere {.inline.} =
  ## Antireverse 𝐬̰, identity on antigrade 1; 0 mul.
  s

func dualBulk*(a: RoundPoint): Sphere {.inline.} =
  ## Dual 𝐚★; 0 mul.
  Sphere(u: -a.w, x: a.x, y: a.y, z: a.z, w: -a.u)

func dualWeight*(a: RoundPoint): Sphere {.inline.} =
  ## Antidual 𝐚☆; 0 mul.
  Sphere(u: a.w, x: -a.x, y: -a.y, z: -a.z, w: a.u)

func dualBulk*(d: Dipole): Circle {.inline.} =
  ## Dual 𝐝★; 0 mul.
  Circle(g: CarrierPlane(x: -d.v.x, y: -d.v.y, z: -d.v.z, w: d.p.w), v: -d.m,
    m: Vec3(x: -d.p.x, y: -d.p.y, z: -d.p.z))

func dualWeight*(d: Dipole): Circle {.inline.} =
  ## Antidual 𝐝☆; 0 mul.
  Circle(g: CarrierPlane(x: d.v.x, y: d.v.y, z: d.v.z, w: -d.p.w), v: read3(d.m),
    m: Vec3(x: d.p.x, y: d.p.y, z: d.p.z))

func dualBulk*(c: Circle): Dipole {.inline.} =
  ## Dual 𝐜★; 0 mul.
  Dipole(v: Vec3(x: c.g.x, y: c.g.y, z: c.g.z), m: read3(c.v),
    p: FlatPoint(x: c.m.x, y: c.m.y, z: c.m.z, w: -c.g.w))

func dualWeight*(c: Circle): Dipole {.inline.} =
  ## Antidual 𝐜☆; 0 mul.
  Dipole(v: Vec3(x: -c.g.x, y: -c.g.y, z: -c.g.z), m: -c.v,
    p: FlatPoint(x: -c.m.x, y: -c.m.y, z: -c.m.z, w: c.g.w))

func dualBulk*(s: Sphere): RoundPoint {.inline.} =
  ## Dual 𝐬★; 0 mul.
  RoundPoint(x: -s.x, y: -s.y, z: -s.z, w: s.u, u: s.w)

func dualWeight*(s: Sphere): RoundPoint {.inline.} =
  ## Antidual 𝐬☆; 0 mul.
  RoundPoint(x: s.x, y: s.y, z: s.z, w: -s.u, u: -s.w)



#[ Parts ]#

func bulk*(a: RoundPoint): RoundPoint {.inline.} =
  ## Round bulk 𝐚∙, components without e₄ and e₅; 0 mul.
  RoundPoint(x: a.x, y: a.y, z: a.z, w: 0.0, u: 0.0)

func weight*(a: RoundPoint): RoundPoint {.inline.} =
  ## Round weight 𝐚∘, components with e₄ and without e₅; 0 mul.
  RoundPoint(x: 0.0, y: 0.0, z: 0.0, w: a.w, u: 0.0)

func bulkFlat*(a: RoundPoint): RoundPoint {.inline.} =
  ## Flat bulk 𝐚■, components with e₅ and without e₄; 0 mul.
  RoundPoint(x: 0.0, y: 0.0, z: 0.0, w: 0.0, u: a.u)

func weightFlat*(a: RoundPoint): RoundPoint {.inline.} =
  ## Flat weight 𝐚□, components with both e₄ and e₅, none for round point; 0 mul.
  RoundPoint(x: 0.0, y: 0.0, z: 0.0, w: 0.0, u: 0.0)

func bulk*(d: Dipole): Dipole {.inline.} =
  ## Round bulk 𝐝∙, i.e. carrier moment; 0 mul.
  Dipole(v: zero3, m: read3(d.m), p: zeroFlatPoint)

func weight*(d: Dipole): Dipole {.inline.} =
  ## Round weight 𝐝∘, i.e. carrier direction; 0 mul.
  Dipole(v: read3(d.v), m: zero3, p: zeroFlatPoint)

func bulkFlat*(d: Dipole): Dipole {.inline.} =
  ## Flat bulk 𝐝■, i.e. flat position; 0 mul.
  Dipole(v: zero3, m: zero3, p: FlatPoint(x: d.p.x, y: d.p.y, z: d.p.z, w: 0.0))

func weightFlat*(d: Dipole): Dipole {.inline.} =
  ## Flat weight 𝐝□, i.e. flat weight; 0 mul.
  Dipole(v: zero3, m: zero3, p: FlatPoint(x: 0.0, y: 0.0, z: 0.0, w: d.p.w))

func bulk*(c: Circle): Circle {.inline.} =
  ## Round bulk 𝐜∙, i.e. carrier position; 0 mul.
  Circle(g: CarrierPlane(x: 0.0, y: 0.0, z: 0.0, w: c.g.w), v: zero3, m: zero3)

func weight*(c: Circle): Circle {.inline.} =
  ## Round weight 𝐜∘, i.e. carrier normal; 0 mul.
  Circle(g: CarrierPlane(x: c.g.x, y: c.g.y, z: c.g.z, w: 0.0), v: zero3, m: zero3)

func bulkFlat*(c: Circle): Circle {.inline.} =
  ## Flat bulk 𝐜■, i.e. flat moment; 0 mul.
  Circle(g: zeroCarrier, v: zero3, m: read3(c.m))

func weightFlat*(c: Circle): Circle {.inline.} =
  ## Flat weight 𝐜□, i.e. flat direction; 0 mul.
  Circle(g: zeroCarrier, v: read3(c.v), m: zero3)

func bulk*(s: Sphere): Sphere {.inline.} =
  ## Round bulk 𝐬∙, none for sphere; 0 mul.
  Sphere(u: 0.0, x: 0.0, y: 0.0, z: 0.0, w: 0.0)

func weight*(s: Sphere): Sphere {.inline.} =
  ## Round weight 𝐬∘, i.e. carrier weight; 0 mul.
  Sphere(u: s.u, x: 0.0, y: 0.0, z: 0.0, w: 0.0)

func bulkFlat*(s: Sphere): Sphere {.inline.} =
  ## Flat bulk 𝐬■, i.e. flat position; 0 mul.
  Sphere(u: 0.0, x: 0.0, y: 0.0, z: 0.0, w: s.w)

func weightFlat*(s: Sphere): Sphere {.inline.} =
  ## Flat weight 𝐬□, i.e. flat normal; 0 mul.
  Sphere(u: 0.0, x: s.x, y: s.y, z: s.z, w: 0.0)



#[ Attitude, Carriers ]#

func attitude*(a: RoundPoint): float {.inline.} =
  ## Attitude of round point, i.e. 𝐚 ∨ 𝐞̅₄, its weight as scalar; 0 mul.
  a.w

func attitude*(d: Dipole): RoundPoint {.inline.} =
  ## Attitude of dipole, i.e. its direction and flat weight as round point; 0 mul.
  RoundPoint(x: d.v.x, y: d.v.y, z: d.v.z, w: 0.0, u: d.p.w)

func attitude*(c: Circle): Dipole {.inline.} =
  ## Attitude of circle, i.e. carrier normal and flat direction as dipole; 0 mul.
  Dipole(v: zero3, m: Vec3(x: c.g.x, y: c.g.y, z: c.g.z),
    p: FlatPoint(x: c.v.x, y: c.v.y, z: c.v.z, w: 0.0))

func attitude*(s: Sphere): Circle {.inline.} =
  ## Attitude of sphere, i.e. carrier weight and flat normal as circle; 0 mul.
  Circle(g: CarrierPlane(x: 0.0, y: 0.0, z: 0.0, w: s.u), v: zero3,
    m: Vec3(x: s.x, y: s.y, z: s.z))

func carrier*(a: RoundPoint): FlatPoint {.inline.} =
  ## Carrier 𝐚 ∧ 𝐞₅, i.e. flat point at same position; 0 mul.
  FlatPoint(x: a.x, y: a.y, z: a.z, w: a.w)

func carrier*(d: Dipole): FlatLine {.inline.} =
  ## Carrier 𝐝 ∧ 𝐞₅, i.e. flat line through dipole; 0 mul.
  FlatLine(v: read3(d.v), m: read3(d.m))

func carrier*(c: Circle): FlatPlane {.inline.} =
  ## Carrier 𝐜 ∧ 𝐞₅, i.e. flat plane containing circle; 0 mul.
  FlatPlane(x: c.g.x, y: c.g.y, z: c.g.z, w: c.g.w)

func carrier*(s: Sphere): Antiscalar {.inline.} =
  ## Carrier 𝐬 ∧ 𝐞₅, i.e. whole space weighted by u; 0 mul.
  Antiscalar(s.u)

func carrierCo*(a: RoundPoint): Antiscalar {.inline.} =
  ## Cocarrier 𝐚☆ ∧ 𝐞₅, i.e. whole space weighted by w; 0 mul.
  Antiscalar(a.w)

func carrierCo*(d: Dipole): FlatPlane {.inline.} =
  ## Cocarrier 𝐝☆ ∧ 𝐞₅, i.e. flat plane normal to dipole through its center; 0 mul.
  FlatPlane(x: d.v.x, y: d.v.y, z: d.v.z, w: -d.p.w)

func carrierCo*(c: Circle): FlatLine {.inline.} =
  ## Cocarrier 𝐜☆ ∧ 𝐞₅, i.e. flat line through circle's center normal to it; 0 mul.
  FlatLine(v: Vec3(x: -c.g.x, y: -c.g.y, z: -c.g.z), m: -c.v)

func carrierCo*(s: Sphere): FlatPoint {.inline.} =
  ## Cocarrier 𝐬☆ ∧ 𝐞₅, i.e. flat point at sphere's center; 0 mul.
  FlatPoint(x: s.x, y: s.y, z: s.z, w: -s.u)



#[ Centers, Containers, Partners ]#

func center*(a: RoundPoint): RoundPoint {.inline.} =
  ## Center 𝐚⊞ ∨ 𝐚, i.e. same point scaled by its weight; 5 mul.
  RoundPoint(x: a.x * a.w, y: a.y * a.w, z: a.z * a.w, w: a.w * a.w, u: a.w * a.u)

func center*(d: Dipole): RoundPoint {.inline.} =
  ## Center of dipole as round point with its radius; 16 mul, 10 add.
  RoundPoint(
    x: d.v.y * d.m.z - d.v.z * d.m.y + d.v.x * d.p.w,
    y: d.v.z * d.m.x - d.v.x * d.m.z + d.v.y * d.p.w,
    z: d.v.x * d.m.y - d.v.y * d.m.x + d.v.z * d.p.w,
    w: dot(d.v, d.v),
    u: d.p.w * d.p.w - d.v.x * d.p.x - d.v.y * d.p.y - d.v.z * d.p.z,
  )

func center*(c: Circle): RoundPoint {.inline.} =
  ## Center of circle as round point with its radius; 18 mul, 12 add.
  RoundPoint(
    x: c.g.y * c.v.z - c.g.z * c.v.y - c.g.x * c.g.w,
    y: c.g.z * c.v.x - c.g.x * c.v.z - c.g.y * c.g.w,
    z: c.g.x * c.v.y - c.g.y * c.v.x - c.g.z * c.g.w,
    w: c.g.x * c.g.x + c.g.y * c.g.y + c.g.z * c.g.z,
    u: dot(c.v, c.v) + c.g.x * c.m.x + c.g.y * c.m.y + c.g.z * c.m.z,
  )

func center*(s: Sphere): RoundPoint {.inline.} =
  ## Center of sphere as round point with its radius; 8 mul, 3 add.
  RoundPoint(
    x: -s.x * s.u, y: -s.y * s.u, z: -s.z * s.u, w: s.u * s.u,
    u: s.x * s.x + s.y * s.y + s.z * s.z - s.w * s.u,
  )

func container*(a: RoundPoint): Sphere {.inline.} =
  ## Container 𝐚 ∧ (𝐚⊟)☆, i.e. smallest sphere holding round point; 8 mul, 3 add.
  Sphere(
    u: -a.w * a.w, x: a.x * a.w, y: a.y * a.w, z: a.z * a.w,
    w: a.w * a.u - a.x * a.x - a.y * a.y - a.z * a.z,
  )

func container*(d: Dipole): Sphere {.inline.} =
  ## Container of dipole, i.e. smallest sphere holding it; 18 mul, 12 add.
  Sphere(
    u: dot(d.v, d.v),
    x: d.v.z * d.m.y - d.v.y * d.m.z - d.v.x * d.p.w,
    y: d.v.x * d.m.z - d.v.z * d.m.x - d.v.y * d.p.w,
    z: d.v.y * d.m.x - d.v.x * d.m.y - d.v.z * d.p.w,
    w: dot(d.m, d.m) + d.v.x * d.p.x + d.v.y * d.p.y + d.v.z * d.p.z,
  )

func container*(c: Circle): Sphere {.inline.} =
  ## Container of circle, i.e. smallest sphere holding it; 16 mul, 10 add.
  Sphere(
    u: -c.g.x * c.g.x - c.g.y * c.g.y - c.g.z * c.g.z,
    x: c.g.y * c.v.z - c.g.z * c.v.y - c.g.w * c.g.x,
    y: c.g.z * c.v.x - c.g.x * c.v.z - c.g.w * c.g.y,
    z: c.g.x * c.v.y - c.g.y * c.v.x - c.g.w * c.g.z,
    w: c.g.x * c.m.x + c.g.y * c.m.y + c.g.z * c.m.z - c.g.w * c.g.w,
  )

func container*(s: Sphere): Sphere {.inline.} =
  ## Container of sphere, i.e. itself scaled by its weight; 5 mul.
  Sphere(u: s.u * s.u, x: s.x * s.u, y: s.y * s.u, z: s.z * s.u, w: s.w * s.u)

func partner*(a: RoundPoint): RoundPoint {.inline.} =
  ## Partner, i.e. same point with squared radius negated; 10 mul, 4 add.
  let w2 = a.w * a.w
  RoundPoint(
    x: a.x * w2, y: a.y * w2, z: a.z * w2, w: a.w * w2,
    u: (a.x * a.x + a.y * a.y + a.z * a.z - a.w * a.u) * a.w,
  )

func partner*(d: Dipole): Dipole {.inline.} =
  ## Partner of dipole; 30 mul, 17 add.
  let v2 = dot(d.v, d.v)
  let f = d.p.w * d.p.w - dot(d.m, d.m) - d.v.x * d.p.x - d.v.y * d.p.y - d.v.z * d.p.z
  Dipole(
    v: d.v * v2,
    m: d.m * v2,
    p: FlatPoint(
      x: (d.m.z * d.v.y - d.m.y * d.v.z) * d.p.w + d.v.x * f,
      y: (d.m.x * d.v.z - d.m.z * d.v.x) * d.p.w + d.v.y * f,
      z: (d.m.y * d.v.x - d.m.x * d.v.y) * d.p.w + d.v.z * f,
      w: d.p.w * v2,
    ),
  )

func partner*(c: Circle): Circle {.inline.} =
  ## Partner of circle; 30 mul, 17 add.
  ##   Symmetric with dipole's partner: f = gʷ² − 𝐯 ∙ 𝐯 − 𝐠 ∙ 𝐦; Terathon's header spells
  ##   its v-term with mixed signs, and library's own form is what suite holds this to.
  let g2 = c.g.x * c.g.x + c.g.y * c.g.y + c.g.z * c.g.z
  let f = c.g.w * c.g.w - dot(c.v, c.v) - c.g.x * c.m.x - c.g.y * c.m.y - c.g.z * c.m.z
  Circle(
    g: CarrierPlane(x: c.g.x * g2, y: c.g.y * g2, z: c.g.z * g2, w: c.g.w * g2),
    v: c.v * g2,
    m: Vec3(
      x: (c.v.y * c.g.z - c.v.z * c.g.y) * c.g.w + c.g.x * f,
      y: (c.v.z * c.g.x - c.v.x * c.g.z) * c.g.w + c.g.y * f,
      z: (c.v.x * c.g.y - c.v.y * c.g.x) * c.g.w + c.g.z * f,
    ),
  )

func partner*(s: Sphere): Sphere {.inline.} =
  ## Partner of sphere; 10 mul, 4 add.
  let u2 = s.u * s.u
  Sphere(
    u: s.u * u2, x: s.x * u2, y: s.y * u2, z: s.z * u2,
    w: (s.x * s.x + s.y * s.y + s.z * s.z - s.w * s.u) * s.u,
  )
