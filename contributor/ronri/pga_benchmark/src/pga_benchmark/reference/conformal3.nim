## Derive Lengyel's typed objects and hand-rolled operations of 3D conformal geometric algebra.
##   Reference every dense library operation is measured against under five dimensions:
##   round points, dipoles, circles and spheres hold only components their grade carries,
##   and each operation spells only surviving terms. Forms follow *Projective Geometric
##   Algebra Illuminated* and conformalgeometricalgebra.org; Terathon Math Library (MIT,
##   Eric Lengyel) was read to cross-check forms and counts, and nothing is copied from
##   it. Scalar is `float`, as library's.
##
##   |------------|---------------------------------------------------|-------------------------|
##   | Code       | Notation                                          | Library basis           |
##   |------------|---------------------------------------------------|-------------------------|
##   | PointRound | 𝐚 = x y z (e₁ e₂ e₃) + w e₄ + u e₅                | E1 E2 E3 E4 E5          |
##   | Dipole     | 𝐝 = dᵛ + dᵐ + dᵖ(e₁₅ e₂₅ e₃₅ e₄₅)                 | E41.. E23.. E15.. E45   |
##   | Circle     | 𝐜 = cᵍ(e₄₂₃ e₄₃₁ e₄₁₂ e₃₂₁) + cᵛ + cᵐ             | E423.. E415.. E235..    |
##   | Sphere     | 𝐬 = u e₁₂₃₄ + x y z (e₄₂₃₅ e₄₃₁₅ e₄₁₂₅) + w e₃₂₁₅ | E1234 E4235.. E3215     |
##   | PointFlat  | 𝐩 = x y z w (e₁₅ e₂₅ e₃₅ e₄₅)                     | E15 E25 E35 E45         |
##   | LineFlat   | 𝐥 = lᵛ(e₄₁₅ e₄₂₅ e₄₃₅) + lᵐ(e₂₃₅ e₃₁₅ e₁₂₅)       | E415.. E235..           |
##   | PlaneFlat  | 𝐠 = x y z w (e₄₂₃₅ e₄₃₁₅ e₄₁₂₅ e₃₂₁₅)             | E4235.. E3215           |
##   |------------|---------------------------------------------------|-------------------------|
##
##   Unary maps (complements, duals, attitude, carrier, cocarrier) are signed coefficient
##     permutations; signs are library's, read off its own tables on basis elements and
##     held by suite `Chapter 2`. Where Terathon's `Cocarrier` of circle orders direction
##     and moment differently, library's table wins.
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
##   Norms and unitize carry no reference here: library defines them as square roots of
##     inner products, which are indefinite under conformal metric and yield NaN on real
##     objects; gap list records that from measured NaN share rather than from any form.
##   Cost: only round-object rows exist; flats are results of carriers, never operands.

{.experimental: "strictFuncs".}

import ./scalars

export scalars


type
  Vector3* = object  ## Define three components named as vector; direction, moment or normal.
    x*, y*, z*: float
  PointRound* = object
    ## Define round point 𝐚 with position x y z, weight w and flat bulk u; grade 1.
    x*, y*, z*, w*, u*: float
  PointFlat* = object  ## Define flat point 𝐩 with position and weight; grade 2, contains e₅.
    x*, y*, z*, w*: float
  Dipole* = object
    ## Define dipole 𝐝 with carrier direction v, carrier moment m and flat part p; grade 2.
    v*, m*: Vector3
    p*: PointFlat
  PlaneFlat* = object
    ## Define flat plane 𝐠 with normal x y z and position w; grade 4, contains e₅.
    x*, y*, z*, w*: float
  PlaneCarrier* = object  ## Define carrier plane of circle, i.e. its grade-3 part without e₅.
    x*, y*, z*, w*: float
  Circle* = object
    ## Define circle 𝐜 with carrier plane g, flat direction v and flat moment m; grade 3.
    g*: PlaneCarrier
    v*, m*: Vector3
  LineFlat* = object  ## Define flat line 𝐥 with direction v and moment m; grade 3, contains e₅.
    v*, m*: Vector3
  Sphere* = object
    ## Define sphere 𝐬 with carrier weight u, flat normal x y z and position w; grade 4.
    u*, x*, y*, z*, w*: float



#[ Exterior Products ]#

func wedge*(a, b: PointRound): Dipole {.inline.} =
  ## Join round points into dipole, i.e. 𝐚 ∧ 𝐛; 20 mul, 10 sub.
  let
    (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
    (bˣ, bʸ, bᶻ, bʷ, bᵘ) = (b.x, b.y, b.z, b.w, b.u)
  Dipole(
    v: Vector3(x: aʷ * bˣ - aˣ * bʷ, y: aʷ * bʸ - aʸ * bʷ, z: aʷ * bᶻ - aᶻ * bʷ),
    m: Vector3(x: aʸ * bᶻ - aᶻ * bʸ, y: aᶻ * bˣ - aˣ * bᶻ, z: aˣ * bʸ - aʸ * bˣ),
    p: PointFlat(
      x: aˣ * bᵘ - aᵘ * bˣ,
      y: aʸ * bᵘ - aᵘ * bʸ,
      z: aᶻ * bᵘ - aᵘ * bᶻ,
      w: aʷ * bᵘ - aᵘ * bʷ,
    ),
  )

func wedge*(d: Dipole, a: PointRound): Circle {.inline.} =
  ## Join dipole and round point into circle, i.e. 𝐝 ∧ 𝐚; 30 mul, 20 add.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
    (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  Circle(
    g: PlaneCarrier(
      x: dᵛʸ * aᶻ - dᵛᶻ * aʸ + dᵐˣ * aʷ,
      y: dᵛᶻ * aˣ - dᵛˣ * aᶻ + dᵐʸ * aʷ,
      z: dᵛˣ * aʸ - dᵛʸ * aˣ + dᵐᶻ * aʷ,
      w: -dᵐˣ * aˣ - dᵐʸ * aʸ - dᵐᶻ * aᶻ,
    ),
    v: Vector3(
      x: dᵖˣ * aʷ - dᵖʷ * aˣ + dᵛˣ * aᵘ,
      y: dᵖʸ * aʷ - dᵖʷ * aʸ + dᵛʸ * aᵘ,
      z: dᵖᶻ * aʷ - dᵖʷ * aᶻ + dᵛᶻ * aᵘ,
    ),
    m: Vector3(
      x: dᵖᶻ * aʸ - dᵖʸ * aᶻ + dᵐˣ * aᵘ,
      y: dᵖˣ * aᶻ - dᵖᶻ * aˣ + dᵐʸ * aᵘ,
      z: dᵖʸ * aˣ - dᵖˣ * aʸ + dᵐᶻ * aᵘ,
    ),
  )

func wedge*(a: PointRound, d: Dipole): Circle {.inline.} =
  ## Join round point and dipole, i.e. 𝐚 ∧ 𝐝 = 𝐝 ∧ 𝐚; 30 mul, 20 add.
  ##   Order swaps freely, since grades 1 and 2 commute.
  let
    (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Circle(
    g: PlaneCarrier(
      x: aᶻ * dᵛʸ - aʸ * dᵛᶻ + aʷ * dᵐˣ,
      y: aˣ * dᵛᶻ - aᶻ * dᵛˣ + aʷ * dᵐʸ,
      z: aʸ * dᵛˣ - aˣ * dᵛʸ + aʷ * dᵐᶻ,
      w: -aˣ * dᵐˣ - aʸ * dᵐʸ - aᶻ * dᵐᶻ,
    ),
    v: Vector3(
      x: aʷ * dᵖˣ - aˣ * dᵖʷ + aᵘ * dᵛˣ,
      y: aʷ * dᵖʸ - aʸ * dᵖʷ + aᵘ * dᵛʸ,
      z: aʷ * dᵖᶻ - aᶻ * dᵖʷ + aᵘ * dᵛᶻ,
    ),
    m: Vector3(
      x: aʸ * dᵖᶻ - aᶻ * dᵖʸ + aᵘ * dᵐˣ,
      y: aᶻ * dᵖˣ - aˣ * dᵖᶻ + aᵘ * dᵐʸ,
      z: aˣ * dᵖʸ - aʸ * dᵖˣ + aᵘ * dᵐᶻ,
    ),
  )

func wedge*(c: Circle, a: PointRound): Sphere {.inline.} =
  ## Join circle and round point into sphere, i.e. 𝐜 ∧ 𝐚; 20 mul, 15 add.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
    (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  Sphere(
    u: -cᵍˣ * aˣ - cᵍʸ * aʸ - cᵍᶻ * aᶻ - cᵍʷ * aʷ,
    x: cᵛᶻ * aʸ - cᵛʸ * aᶻ - cᵐˣ * aʷ + cᵍˣ * aᵘ,
    y: cᵛˣ * aᶻ - cᵛᶻ * aˣ - cᵐʸ * aʷ + cᵍʸ * aᵘ,
    z: cᵛʸ * aˣ - cᵛˣ * aʸ - cᵐᶻ * aʷ + cᵍᶻ * aᵘ,
    w: cᵐˣ * aˣ + cᵐʸ * aʸ + cᵐᶻ * aᶻ + cᵍʷ * aᵘ,
  )

func wedge*(a: PointRound, c: Circle): Sphere {.inline.} =
  ## Join round point and circle, i.e. 𝐚 ∧ 𝐜 = −(𝐜 ∧ 𝐚); 20 mul, 15 add.
  let
    (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Sphere(
    u: aˣ * cᵍˣ + aʸ * cᵍʸ + aᶻ * cᵍᶻ + aʷ * cᵍʷ,
    x: aᶻ * cᵛʸ - aʸ * cᵛᶻ + aʷ * cᵐˣ - aᵘ * cᵍˣ,
    y: aˣ * cᵛᶻ - aᶻ * cᵛˣ + aʷ * cᵐʸ - aᵘ * cᵍʸ,
    z: aʸ * cᵛˣ - aˣ * cᵛʸ + aʷ * cᵐᶻ - aᵘ * cᵍᶻ,
    w: -aˣ * cᵐˣ - aʸ * cᵐʸ - aᶻ * cᵐᶻ - aᵘ * cᵍʷ,
  )

func wedge*(d, f: Dipole): Sphere {.inline.} =
  ## Join dipoles into sphere, i.e. 𝐝 ∧ 𝐟; 30 mul, 25 add.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
    (fᵛˣ, fᵛʸ, fᵛᶻ) = (f.v.x, f.v.y, f.v.z)
    (fᵐˣ, fᵐʸ, fᵐᶻ) = (f.m.x, f.m.y, f.m.z)
    (fᵖˣ, fᵖʸ, fᵖᶻ, fᵖʷ) = (f.p.x, f.p.y, f.p.z, f.p.w)
  Sphere(
    u: -dᵐˣ * fᵛˣ - dᵐʸ * fᵛʸ - dᵐᶻ * fᵛᶻ -
        dᵛˣ * fᵐˣ - dᵛʸ * fᵐʸ - dᵛᶻ * fᵐᶻ,
    x: dᵖᶻ * fᵛʸ - dᵖʸ * fᵛᶻ + dᵛʸ * fᵖᶻ - dᵛᶻ * fᵖʸ +
        dᵐˣ * fᵖʷ + dᵖʷ * fᵐˣ,
    y: dᵖˣ * fᵛᶻ - dᵖᶻ * fᵛˣ + dᵛᶻ * fᵖˣ - dᵛˣ * fᵖᶻ +
        dᵐʸ * fᵖʷ + dᵖʷ * fᵐʸ,
    z: dᵖʸ * fᵛˣ - dᵖˣ * fᵛʸ + dᵛˣ * fᵖʸ - dᵛʸ * fᵖˣ +
        dᵐᶻ * fᵖʷ + dᵖʷ * fᵐᶻ,
    w: -dᵐˣ * fᵖˣ - dᵐʸ * fᵖʸ - dᵐᶻ * fᵖᶻ -
        dᵖˣ * fᵐˣ - dᵖʸ * fᵐʸ - dᵖᶻ * fᵐᶻ,
  )

func wedgeAnti*(s, t: Sphere): Circle {.inline.} =
  ## Meet spheres in circle, i.e. 𝐬 ∨ 𝐭; 20 mul, 10 sub.
  let
    (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
    (tᵘ, tˣ, tʸ, tᶻ, tʷ) = (t.u, t.x, t.y, t.z, t.w)
  Circle(
    g: PlaneCarrier(
      x: sᵘ * tˣ - sˣ * tᵘ,
      y: sᵘ * tʸ - sʸ * tᵘ,
      z: sᵘ * tᶻ - sᶻ * tᵘ,
      w: sᵘ * tʷ - sʷ * tᵘ,
    ),
    v: Vector3(x: sᶻ * tʸ - sʸ * tᶻ, y: sˣ * tᶻ - sᶻ * tˣ, z: sʸ * tˣ - sˣ * tʸ),
    m: Vector3(x: sˣ * tʷ - sʷ * tˣ, y: sʸ * tʷ - sʷ * tʸ, z: sᶻ * tʷ - sʷ * tᶻ),
  )

func wedgeAnti*(s: Sphere, c: Circle): Dipole {.inline.} =
  ## Meet sphere and circle in dipole, i.e. 𝐬 ∨ 𝐜; 30 mul, 20 add.
  let
    (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Dipole(
    v: Vector3(
      x: sʸ * cᵍᶻ - sᶻ * cᵍʸ + sᵘ * cᵛˣ,
      y: sᶻ * cᵍˣ - sˣ * cᵍᶻ + sᵘ * cᵛʸ,
      z: sˣ * cᵍʸ - sʸ * cᵍˣ + sᵘ * cᵛᶻ,
    ),
    m: Vector3(
      x: sʷ * cᵍˣ - sˣ * cᵍʷ + sᵘ * cᵐˣ,
      y: sʷ * cᵍʸ - sʸ * cᵍʷ + sᵘ * cᵐʸ,
      z: sʷ * cᵍᶻ - sᶻ * cᵍʷ + sᵘ * cᵐᶻ,
    ),
    p: PointFlat(
      x: sᶻ * cᵐʸ - sʸ * cᵐᶻ + sʷ * cᵛˣ,
      y: sˣ * cᵐᶻ - sᶻ * cᵐˣ + sʷ * cᵛʸ,
      z: sʸ * cᵐˣ - sˣ * cᵐʸ + sʷ * cᵛᶻ,
      w: -sˣ * cᵛˣ - sʸ * cᵛʸ - sᶻ * cᵛᶻ,
    ),
  )

func wedgeAnti*(c: Circle, s: Sphere): Dipole {.inline.} =
  ## Meet circle and sphere, i.e. 𝐜 ∨ 𝐬 = 𝐬 ∨ 𝐜; 30 mul, 20 add.
  ##   Order swaps freely, since antigrades 1 and 2 commute.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
    (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  Dipole(
    v: Vector3(
      x: cᵍᶻ * sʸ - cᵍʸ * sᶻ + cᵛˣ * sᵘ,
      y: cᵍˣ * sᶻ - cᵍᶻ * sˣ + cᵛʸ * sᵘ,
      z: cᵍʸ * sˣ - cᵍˣ * sʸ + cᵛᶻ * sᵘ,
    ),
    m: Vector3(
      x: cᵍˣ * sʷ - cᵍʷ * sˣ + cᵐˣ * sᵘ,
      y: cᵍʸ * sʷ - cᵍʷ * sʸ + cᵐʸ * sᵘ,
      z: cᵍᶻ * sʷ - cᵍʷ * sᶻ + cᵐᶻ * sᵘ,
    ),
    p: PointFlat(
      x: cᵐʸ * sᶻ - cᵐᶻ * sʸ + cᵛˣ * sʷ,
      y: cᵐᶻ * sˣ - cᵐˣ * sᶻ + cᵛʸ * sʷ,
      z: cᵐˣ * sʸ - cᵐʸ * sˣ + cᵛᶻ * sʷ,
      w: -cᵛˣ * sˣ - cᵛʸ * sʸ - cᵛᶻ * sᶻ,
    ),
  )

func wedgeAnti*(c, o: Circle): PointRound {.inline.} =
  ## Meet circles in round point, i.e. 𝐜 ∨ 𝐨; 30 mul, 25 add.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
    (oᵍˣ, oᵍʸ, oᵍᶻ, oᵍʷ) = (o.g.x, o.g.y, o.g.z, o.g.w)
    (oᵛˣ, oᵛʸ, oᵛᶻ) = (o.v.x, o.v.y, o.v.z)
    (oᵐˣ, oᵐʸ, oᵐᶻ) = (o.m.x, o.m.y, o.m.z)
  PointRound(
    x: cᵍᶻ * oᵐʸ - cᵍʸ * oᵐᶻ + cᵐʸ * oᵍᶻ - cᵐᶻ * oᵍʸ +
        cᵍʷ * oᵛˣ + cᵛˣ * oᵍʷ,
    y: cᵍˣ * oᵐᶻ - cᵍᶻ * oᵐˣ + cᵐᶻ * oᵍˣ - cᵐˣ * oᵍᶻ +
        cᵍʷ * oᵛʸ + cᵛʸ * oᵍʷ,
    z: cᵍʸ * oᵐˣ - cᵍˣ * oᵐʸ + cᵐˣ * oᵍʸ - cᵐʸ * oᵍˣ +
        cᵍʷ * oᵛᶻ + cᵛᶻ * oᵍʷ,
    w: -cᵍˣ * oᵛˣ - cᵍʸ * oᵛʸ - cᵍᶻ * oᵛᶻ -
        cᵛˣ * oᵍˣ - cᵛʸ * oᵍʸ - cᵛᶻ * oᵍᶻ,
    u: -cᵐˣ * oᵛˣ - cᵐʸ * oᵛʸ - cᵐᶻ * oᵛᶻ -
        cᵛˣ * oᵐˣ - cᵛʸ * oᵐʸ - cᵛᶻ * oᵐᶻ,
  )

func wedgeAnti*(s: Sphere, d: Dipole): PointRound {.inline.} =
  ## Meet sphere and dipole in round point, i.e. 𝐬 ∨ 𝐝; 20 mul, 15 add.
  let
    (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  PointRound(
    x: sʸ * dᵐᶻ - sᶻ * dᵐʸ + sᵘ * dᵖˣ - sʷ * dᵛˣ,
    y: sᶻ * dᵐˣ - sˣ * dᵐᶻ + sᵘ * dᵖʸ - sʷ * dᵛʸ,
    z: sˣ * dᵐʸ - sʸ * dᵐˣ + sᵘ * dᵖᶻ - sʷ * dᵛᶻ,
    w: sˣ * dᵛˣ + sʸ * dᵛʸ + sᶻ * dᵛᶻ + sᵘ * dᵖʷ,
    u: -sˣ * dᵖˣ - sʸ * dᵖʸ - sᶻ * dᵖᶻ - sʷ * dᵖʷ,
  )

func wedgeAnti*(d: Dipole, s: Sphere): PointRound {.inline.} =
  ## Meet dipole and sphere, i.e. 𝐝 ∨ 𝐬 = −(𝐬 ∨ 𝐝); 20 mul, 15 add.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
    (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  PointRound(
    x: dᵐʸ * sᶻ - dᵐᶻ * sʸ + dᵛˣ * sʷ - dᵖˣ * sᵘ,
    y: dᵐᶻ * sˣ - dᵐˣ * sᶻ + dᵛʸ * sʷ - dᵖʸ * sᵘ,
    z: dᵐˣ * sʸ - dᵐʸ * sˣ + dᵛᶻ * sʷ - dᵖᶻ * sᵘ,
    w: -dᵛˣ * sˣ - dᵛʸ * sʸ - dᵛᶻ * sᶻ - dᵖʷ * sᵘ,
    u: dᵖˣ * sˣ + dᵖʸ * sʸ + dᵖᶻ * sᶻ + dᵖʷ * sʷ,
  )



#[ Inner Products ]#

func dot*(a, b: PointRound): float {.inline.} =
  ## Multiply round points through inner product under conformal metric, i.e. 𝐚 ∙ 𝐛; 5 mul, 4 add.
  a.x * b.x + a.y * b.y + a.z * b.z - a.w * b.u - a.u * b.w

func dot*(d, f: Dipole): float {.inline.} =
  ## Multiply dipoles through inner product, i.e. 𝐝 ∙ 𝐟; 10 mul, 9 add.
  (d.v.x * f.p.x + d.v.y * f.p.y + d.v.z * f.p.z) +
    (d.m.x * f.m.x + d.m.y * f.m.y + d.m.z * f.m.z) +
    (d.p.x * f.v.x + d.p.y * f.v.y + d.p.z * f.v.z) - d.p.w * f.p.w

func dot*(c, o: Circle): float {.inline.} =
  ## Multiply circles through inner product, i.e. 𝐜 ∙ 𝐨; 10 mul, 9 add.
  c.g.w * o.g.w - (c.g.x * o.m.x + c.g.y * o.m.y + c.g.z * o.m.z) -
    (c.m.x * o.g.x + c.m.y * o.g.y + c.m.z * o.g.z) -
    (c.v.x * o.v.x + c.v.y * o.v.y + c.v.z * o.v.z)

func dot*(s, t: Sphere): float {.inline.} =
  ## Multiply spheres through inner product, i.e. 𝐬 ∙ 𝐭; 5 mul, 4 add.
  s.u * t.w + s.w * t.u - s.x * t.x - s.y * t.y - s.z * t.z

func dotAnti*(a, b: PointRound): Antiscalar {.inline.} =
  ## Multiply round points through inner antiproduct, i.e. 𝐚 ∘ 𝐛 = −(𝐚 ∙ 𝐛)𝟙 here; 5 mul, 4 add.
  Antiscalar(-(a.x * b.x + a.y * b.y + a.z * b.z - a.w * b.u - a.u * b.w))

func dotAnti*(d, f: Dipole): Antiscalar {.inline.} =
  ## Multiply dipoles through inner antiproduct, i.e. 𝐝 ∘ 𝐟; 10 mul, 9 add.
  Antiscalar(
    -(
      (d.v.x * f.p.x + d.v.y * f.p.y + d.v.z * f.p.z) +
      (d.m.x * f.m.x + d.m.y * f.m.y + d.m.z * f.m.z) +
      (d.p.x * f.v.x + d.p.y * f.v.y + d.p.z * f.v.z) - d.p.w * f.p.w
    ),
  )

func dotAnti*(c, o: Circle): Antiscalar {.inline.} =
  ## Multiply circles through inner antiproduct, i.e. 𝐜 ∘ 𝐨; 10 mul, 9 add.
  Antiscalar(
    -(
      c.g.w * o.g.w - (c.g.x * o.m.x + c.g.y * o.m.y + c.g.z * o.m.z) -
      (c.m.x * o.g.x + c.m.y * o.g.y + c.m.z * o.g.z) -
      (c.v.x * o.v.x + c.v.y * o.v.y + c.v.z * o.v.z)
    ),
  )

func dotAnti*(s, t: Sphere): Antiscalar {.inline.} =
  ## Multiply spheres through inner antiproduct, i.e. 𝐬 ∘ 𝐭; 5 mul, 4 add.
  Antiscalar(-(s.u * t.w + s.w * t.u - s.x * t.x - s.y * t.y - s.z * t.z))



#[ Complements ]#

func complementRight*(a: PointRound): Sphere {.inline.} =
  ## Get right complement 𝐚̅, same components read as sphere; 0 mul.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  Sphere(u: aᵘ, x: aˣ, y: aʸ, z: aᶻ, w: aʷ)

func complementLeft*(a: PointRound): Sphere {.inline.} =
  ## Get left complement 𝐚̲, equal to right one for grade 1 in five dimensions; 0 mul.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  Sphere(u: aᵘ, x: aˣ, y: aʸ, z: aᶻ, w: aʷ)

func complementRight*(s: Sphere): PointRound {.inline.} =
  ## Get right complement 𝐬̅, same components read as round point; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  PointRound(x: sˣ, y: sʸ, z: sᶻ, w: sʷ, u: sᵘ)

func complementLeft*(s: Sphere): PointRound {.inline.} =
  ## Get left complement 𝐬̲, equal to right one; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  PointRound(x: sˣ, y: sʸ, z: sᶻ, w: sʷ, u: sᵘ)

func complementRight*(d: Dipole): Circle {.inline.} =
  ## Get right complement 𝐝̅, negated with flat part becoming carrier plane; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Circle(
    g: PlaneCarrier(x: -dᵖˣ, y: -dᵖʸ, z: -dᵖᶻ, w: -dᵖʷ),
    v: Vector3(x: -dᵐˣ, y: -dᵐʸ, z: -dᵐᶻ),
    m: Vector3(x: -dᵛˣ, y: -dᵛʸ, z: -dᵛᶻ),
  )

func complementLeft*(d: Dipole): Circle {.inline.} =
  ## Get left complement 𝐝̲, equal to right one for grade 2; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Circle(
    g: PlaneCarrier(x: -dᵖˣ, y: -dᵖʸ, z: -dᵖᶻ, w: -dᵖʷ),
    v: Vector3(x: -dᵐˣ, y: -dᵐʸ, z: -dᵐᶻ),
    m: Vector3(x: -dᵛˣ, y: -dᵛʸ, z: -dᵛᶻ),
  )

func complementRight*(c: Circle): Dipole {.inline.} =
  ## Get right complement 𝐜̅, negated with carrier plane becoming flat part; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Dipole(
    v: Vector3(x: -cᵐˣ, y: -cᵐʸ, z: -cᵐᶻ),
    m: Vector3(x: -cᵛˣ, y: -cᵛʸ, z: -cᵛᶻ),
    p: PointFlat(x: -cᵍˣ, y: -cᵍʸ, z: -cᵍᶻ, w: -cᵍʷ),
  )

func complementLeft*(c: Circle): Dipole {.inline.} =
  ## Get left complement 𝐜̲, equal to right one for grade 3; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Dipole(
    v: Vector3(x: -cᵐˣ, y: -cᵐʸ, z: -cᵐᶻ),
    m: Vector3(x: -cᵛˣ, y: -cᵛʸ, z: -cᵛᶻ),
    p: PointFlat(x: -cᵍˣ, y: -cᵍʸ, z: -cᵍᶻ, w: -cᵍʷ),
  )



#[ Reverses ]#

func reverse*(a: PointRound): PointRound {.inline.} =
  ## Get reverse 𝐚̃, identity on grade 1; 0 mul.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  PointRound(x: aˣ, y: aʸ, z: aᶻ, w: aʷ, u: aᵘ)

func reverse*(d: Dipole): Dipole {.inline.} =
  ## Get reverse 𝐝̃, negation on grade 2; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Dipole(
    v: Vector3(x: -dᵛˣ, y: -dᵛʸ, z: -dᵛᶻ),
    m: Vector3(x: -dᵐˣ, y: -dᵐʸ, z: -dᵐᶻ),
    p: PointFlat(x: -dᵖˣ, y: -dᵖʸ, z: -dᵖᶻ, w: -dᵖʷ),
  )

func reverse*(c: Circle): Circle {.inline.} =
  ## Get reverse 𝐜̃, negation on grade 3; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Circle(
    g: PlaneCarrier(x: -cᵍˣ, y: -cᵍʸ, z: -cᵍᶻ, w: -cᵍʷ),
    v: Vector3(x: -cᵛˣ, y: -cᵛʸ, z: -cᵛᶻ),
    m: Vector3(x: -cᵐˣ, y: -cᵐʸ, z: -cᵐᶻ),
  )

func reverse*(s: Sphere): Sphere {.inline.} =
  ## Get reverse 𝐬̃, identity on grade 4; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  Sphere(u: sᵘ, x: sˣ, y: sʸ, z: sᶻ, w: sʷ)

func reverseAnti*(a: PointRound): PointRound {.inline.} =
  ## Get antireverse 𝐚̰, identity on antigrade 4; 0 mul.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  PointRound(x: aˣ, y: aʸ, z: aᶻ, w: aʷ, u: aᵘ)

func reverseAnti*(d: Dipole): Dipole {.inline.} =
  ## Get antireverse 𝐝̰, negation on antigrade 3; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Dipole(
    v: Vector3(x: -dᵛˣ, y: -dᵛʸ, z: -dᵛᶻ),
    m: Vector3(x: -dᵐˣ, y: -dᵐʸ, z: -dᵐᶻ),
    p: PointFlat(x: -dᵖˣ, y: -dᵖʸ, z: -dᵖᶻ, w: -dᵖʷ),
  )

func reverseAnti*(c: Circle): Circle {.inline.} =
  ## Get antireverse 𝐜̰, negation on antigrade 2; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Circle(
    g: PlaneCarrier(x: -cᵍˣ, y: -cᵍʸ, z: -cᵍᶻ, w: -cᵍʷ),
    v: Vector3(x: -cᵛˣ, y: -cᵛʸ, z: -cᵛᶻ),
    m: Vector3(x: -cᵐˣ, y: -cᵐʸ, z: -cᵐᶻ),
  )

func reverseAnti*(s: Sphere): Sphere {.inline.} =
  ## Get antireverse 𝐬̰, identity on antigrade 1; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  Sphere(u: sᵘ, x: sˣ, y: sʸ, z: sᶻ, w: sʷ)



#[ Duals ]#

func dualBulk*(a: PointRound): Sphere {.inline.} =
  ## Get dual 𝐚★; 0 mul.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  Sphere(u: -aʷ, x: aˣ, y: aʸ, z: aᶻ, w: -aᵘ)

func dualWeight*(a: PointRound): Sphere {.inline.} =
  ## Get antidual 𝐚☆; 0 mul.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  Sphere(u: aʷ, x: -aˣ, y: -aʸ, z: -aᶻ, w: aᵘ)

func dualBulk*(d: Dipole): Circle {.inline.} =
  ## Get dual 𝐝★; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Circle(
    g: PlaneCarrier(x: -dᵛˣ, y: -dᵛʸ, z: -dᵛᶻ, w: dᵖʷ),
    v: Vector3(x: -dᵐˣ, y: -dᵐʸ, z: -dᵐᶻ),
    m: Vector3(x: -dᵖˣ, y: -dᵖʸ, z: -dᵖᶻ),
  )

func dualWeight*(d: Dipole): Circle {.inline.} =
  ## Get antidual 𝐝☆; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Circle(
    g: PlaneCarrier(x: dᵛˣ, y: dᵛʸ, z: dᵛᶻ, w: -dᵖʷ),
    v: Vector3(x: dᵐˣ, y: dᵐʸ, z: dᵐᶻ),
    m: Vector3(x: dᵖˣ, y: dᵖʸ, z: dᵖᶻ),
  )

func dualBulk*(c: Circle): Dipole {.inline.} =
  ## Get dual 𝐜★; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Dipole(
    v: Vector3(x: cᵍˣ, y: cᵍʸ, z: cᵍᶻ),
    m: Vector3(x: cᵛˣ, y: cᵛʸ, z: cᵛᶻ),
    p: PointFlat(x: cᵐˣ, y: cᵐʸ, z: cᵐᶻ, w: -cᵍʷ),
  )

func dualWeight*(c: Circle): Dipole {.inline.} =
  ## Get antidual 𝐜☆; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Dipole(
    v: Vector3(x: -cᵍˣ, y: -cᵍʸ, z: -cᵍᶻ),
    m: Vector3(x: -cᵛˣ, y: -cᵛʸ, z: -cᵛᶻ),
    p: PointFlat(x: -cᵐˣ, y: -cᵐʸ, z: -cᵐᶻ, w: cᵍʷ),
  )

func dualBulk*(s: Sphere): PointRound {.inline.} =
  ## Get dual 𝐬★; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  PointRound(x: -sˣ, y: -sʸ, z: -sᶻ, w: sᵘ, u: sʷ)

func dualWeight*(s: Sphere): PointRound {.inline.} =
  ## Get antidual 𝐬☆; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  PointRound(x: sˣ, y: sʸ, z: sᶻ, w: -sᵘ, u: -sʷ)



#[ Parts ]#

func bulk*(a: PointRound): PointRound {.inline.} =
  ## Extract round bulk 𝐚∙, components without e₄ and e₅; 0 mul.
  let (aˣ, aʸ, aᶻ) = (a.x, a.y, a.z)
  PointRound(x: aˣ, y: aʸ, z: aᶻ, w: 0.0, u: 0.0)

func weight*(a: PointRound): PointRound {.inline.} =
  ## Extract round weight 𝐚∘, components with e₄ and without e₅; 0 mul.
  let aʷ = a.w
  PointRound(x: 0.0, y: 0.0, z: 0.0, w: aʷ, u: 0.0)

func bulkFlat*(a: PointRound): PointRound {.inline.} =
  ## Extract flat bulk 𝐚■, components with e₅ and without e₄; 0 mul.
  let aᵘ = a.u
  PointRound(x: 0.0, y: 0.0, z: 0.0, w: 0.0, u: aᵘ)

func weightFlat*(a: PointRound): PointRound {.inline.} =
  ## Extract flat weight 𝐚□, components with both e₄ and e₅, none for round point; 0 mul.
  PointRound(x: 0.0, y: 0.0, z: 0.0, w: 0.0, u: 0.0)

func bulk*(d: Dipole): Dipole {.inline.} =
  ## Extract round bulk 𝐝∙, i.e. carrier moment; 0 mul.
  let (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
  Dipole(
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: dᵐˣ, y: dᵐʸ, z: dᵐᶻ),
    p: PointFlat(x: 0.0, y: 0.0, z: 0.0, w: 0.0),
  )

func weight*(d: Dipole): Dipole {.inline.} =
  ## Extract round weight 𝐝∘, i.e. carrier direction; 0 mul.
  let (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
  Dipole(
    v: Vector3(x: dᵛˣ, y: dᵛʸ, z: dᵛᶻ),
    m: Vector3(x: 0.0, y: 0.0, z: 0.0),
    p: PointFlat(x: 0.0, y: 0.0, z: 0.0, w: 0.0),
  )

func bulkFlat*(d: Dipole): Dipole {.inline.} =
  ## Extract flat bulk 𝐝■, i.e. flat position; 0 mul.
  let (dᵖˣ, dᵖʸ, dᵖᶻ) = (d.p.x, d.p.y, d.p.z)
  Dipole(
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: 0.0, y: 0.0, z: 0.0),
    p: PointFlat(x: dᵖˣ, y: dᵖʸ, z: dᵖᶻ, w: 0.0),
  )

func weightFlat*(d: Dipole): Dipole {.inline.} =
  ## Extract flat weight 𝐝□, i.e. flat weight; 0 mul.
  let dᵖʷ = d.p.w
  Dipole(
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: 0.0, y: 0.0, z: 0.0),
    p: PointFlat(x: 0.0, y: 0.0, z: 0.0, w: dᵖʷ),
  )

func bulk*(c: Circle): Circle {.inline.} =
  ## Extract round bulk 𝐜∙, i.e. carrier position; 0 mul.
  let cᵍʷ = c.g.w
  Circle(
    g: PlaneCarrier(x: 0.0, y: 0.0, z: 0.0, w: cᵍʷ),
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: 0.0, y: 0.0, z: 0.0),
  )

func weight*(c: Circle): Circle {.inline.} =
  ## Extract round weight 𝐜∘, i.e. carrier normal; 0 mul.
  let (cᵍˣ, cᵍʸ, cᵍᶻ) = (c.g.x, c.g.y, c.g.z)
  Circle(
    g: PlaneCarrier(x: cᵍˣ, y: cᵍʸ, z: cᵍᶻ, w: 0.0),
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: 0.0, y: 0.0, z: 0.0),
  )

func bulkFlat*(c: Circle): Circle {.inline.} =
  ## Extract flat bulk 𝐜■, i.e. flat moment; 0 mul.
  let (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Circle(
    g: PlaneCarrier(x: 0.0, y: 0.0, z: 0.0, w: 0.0),
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: cᵐˣ, y: cᵐʸ, z: cᵐᶻ),
  )

func weightFlat*(c: Circle): Circle {.inline.} =
  ## Extract flat weight 𝐜□, i.e. flat direction; 0 mul.
  let (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
  Circle(
    g: PlaneCarrier(x: 0.0, y: 0.0, z: 0.0, w: 0.0),
    v: Vector3(x: cᵛˣ, y: cᵛʸ, z: cᵛᶻ),
    m: Vector3(x: 0.0, y: 0.0, z: 0.0),
  )

func bulk*(s: Sphere): Sphere {.inline.} =
  ## Extract round bulk 𝐬∙, none for sphere; 0 mul.
  Sphere(u: 0.0, x: 0.0, y: 0.0, z: 0.0, w: 0.0)

func weight*(s: Sphere): Sphere {.inline.} =
  ## Extract round weight 𝐬∘, i.e. carrier weight; 0 mul.
  let sᵘ = s.u
  Sphere(u: sᵘ, x: 0.0, y: 0.0, z: 0.0, w: 0.0)

func bulkFlat*(s: Sphere): Sphere {.inline.} =
  ## Extract flat bulk 𝐬■, i.e. flat position; 0 mul.
  let sʷ = s.w
  Sphere(u: 0.0, x: 0.0, y: 0.0, z: 0.0, w: sʷ)

func weightFlat*(s: Sphere): Sphere {.inline.} =
  ## Extract flat weight 𝐬□, i.e. flat normal; 0 mul.
  let (sˣ, sʸ, sᶻ) = (s.x, s.y, s.z)
  Sphere(u: 0.0, x: sˣ, y: sʸ, z: sᶻ, w: 0.0)



#[ Attitudes ]#

func attitude*(a: PointRound): float {.inline.} =
  ## Get attitude of round point, i.e. 𝐚 ∨ 𝐞̅₄, its weight as scalar; 0 mul.
  a.w

func attitude*(d: Dipole): PointRound {.inline.} =
  ## Get attitude of dipole, i.e. its direction and flat weight as round point; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    dᵖʷ = d.p.w
  PointRound(x: dᵛˣ, y: dᵛʸ, z: dᵛᶻ, w: 0.0, u: dᵖʷ)

func attitude*(c: Circle): Dipole {.inline.} =
  ## Get attitude of circle, i.e. carrier normal and flat direction as dipole; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ) = (c.g.x, c.g.y, c.g.z)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
  Dipole(
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: cᵍˣ, y: cᵍʸ, z: cᵍᶻ),
    p: PointFlat(x: cᵛˣ, y: cᵛʸ, z: cᵛᶻ, w: 0.0),
  )

func attitude*(s: Sphere): Circle {.inline.} =
  ## Get attitude of sphere, i.e. carrier weight and flat normal as circle; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ) = (s.u, s.x, s.y, s.z)
  Circle(
    g: PlaneCarrier(x: 0.0, y: 0.0, z: 0.0, w: sᵘ),
    v: Vector3(x: 0.0, y: 0.0, z: 0.0),
    m: Vector3(x: sˣ, y: sʸ, z: sᶻ),
  )



#[ Carriers ]#

func carrier*(a: PointRound): PointFlat {.inline.} =
  ## Get carrier 𝐚 ∧ 𝐞₅, i.e. flat point at same position; 0 mul.
  let (aˣ, aʸ, aᶻ, aʷ) = (a.x, a.y, a.z, a.w)
  PointFlat(x: aˣ, y: aʸ, z: aᶻ, w: aʷ)

func carrier*(d: Dipole): LineFlat {.inline.} =
  ## Get carrier 𝐝 ∧ 𝐞₅, i.e. flat line through dipole; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
  LineFlat(v: Vector3(x: dᵛˣ, y: dᵛʸ, z: dᵛᶻ), m: Vector3(x: dᵐˣ, y: dᵐʸ, z: dᵐᶻ))

func carrier*(c: Circle): PlaneFlat {.inline.} =
  ## Get carrier 𝐜 ∧ 𝐞₅, i.e. flat plane containing circle; 0 mul.
  let (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
  PlaneFlat(x: cᵍˣ, y: cᵍʸ, z: cᵍᶻ, w: cᵍʷ)

func carrier*(s: Sphere): Antiscalar {.inline.} =
  ## Get carrier 𝐬 ∧ 𝐞₅, i.e. whole space weighted by u; 0 mul.
  Antiscalar(s.u)

func carrierCo*(a: PointRound): Antiscalar {.inline.} =
  ## Get cocarrier 𝐚☆ ∧ 𝐞₅, i.e. whole space weighted by w; 0 mul.
  Antiscalar(a.w)

func carrierCo*(d: Dipole): PlaneFlat {.inline.} =
  ## Get cocarrier 𝐝☆ ∧ 𝐞₅, i.e. flat plane normal to dipole through its center; 0 mul.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    dᵖʷ = d.p.w
  PlaneFlat(x: dᵛˣ, y: dᵛʸ, z: dᵛᶻ, w: -dᵖʷ)

func carrierCo*(c: Circle): LineFlat {.inline.} =
  ## Get cocarrier 𝐜☆ ∧ 𝐞₅, i.e. flat line through circle's center normal to it; 0 mul.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ) = (c.g.x, c.g.y, c.g.z)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
  LineFlat(v: Vector3(x: -cᵍˣ, y: -cᵍʸ, z: -cᵍᶻ), m: Vector3(x: -cᵛˣ, y: -cᵛʸ, z: -cᵛᶻ))

func carrierCo*(s: Sphere): PointFlat {.inline.} =
  ## Get cocarrier 𝐬☆ ∧ 𝐞₅, i.e. flat point at sphere's center; 0 mul.
  let (sᵘ, sˣ, sʸ, sᶻ) = (s.u, s.x, s.y, s.z)
  PointFlat(x: sˣ, y: sʸ, z: sᶻ, w: -sᵘ)



#[ Centers ]#

func center*(a: PointRound): PointRound {.inline.} =
  ## Get center 𝐚⊞ ∨ 𝐚, i.e. same point scaled by its weight; 5 mul.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  PointRound(x: aˣ * aʷ, y: aʸ * aʷ, z: aᶻ * aʷ, w: aʷ * aʷ, u: aʷ * aᵘ)

func center*(d: Dipole): PointRound {.inline.} =
  ## Get center of dipole as round point with its radius; 16 mul, 11 add.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  PointRound(
    x: dᵛʸ * dᵐᶻ - dᵛᶻ * dᵐʸ + dᵛˣ * dᵖʷ,
    y: dᵛᶻ * dᵐˣ - dᵛˣ * dᵐᶻ + dᵛʸ * dᵖʷ,
    z: dᵛˣ * dᵐʸ - dᵛʸ * dᵐˣ + dᵛᶻ * dᵖʷ,
    w: dᵛˣ * dᵛˣ + dᵛʸ * dᵛʸ + dᵛᶻ * dᵛᶻ,
    u: dᵖʷ * dᵖʷ - dᵛˣ * dᵖˣ - dᵛʸ * dᵖʸ - dᵛᶻ * dᵖᶻ,
  )

func center*(c: Circle): PointRound {.inline.} =
  ## Get center of circle as round point with its radius; 18 mul, 13 add.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  PointRound(
    x: cᵍʸ * cᵛᶻ - cᵍᶻ * cᵛʸ - cᵍˣ * cᵍʷ,
    y: cᵍᶻ * cᵛˣ - cᵍˣ * cᵛᶻ - cᵍʸ * cᵍʷ,
    z: cᵍˣ * cᵛʸ - cᵍʸ * cᵛˣ - cᵍᶻ * cᵍʷ,
    w: cᵍˣ * cᵍˣ + cᵍʸ * cᵍʸ + cᵍᶻ * cᵍᶻ,
    u: (cᵛˣ * cᵛˣ + cᵛʸ * cᵛʸ + cᵛᶻ * cᵛᶻ) + cᵍˣ * cᵐˣ + cᵍʸ * cᵐʸ + cᵍᶻ * cᵐᶻ,
  )

func center*(s: Sphere): PointRound {.inline.} =
  ## Get center of sphere as round point with its radius; 8 mul, 3 add.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  PointRound(
    x: -sˣ * sᵘ,
    y: -sʸ * sᵘ,
    z: -sᶻ * sᵘ,
    w: sᵘ * sᵘ,
    u: sˣ * sˣ + sʸ * sʸ + sᶻ * sᶻ - sʷ * sᵘ,
  )



#[ Containers ]#

func container*(a: PointRound): Sphere {.inline.} =
  ## Get container 𝐚 ∧ (𝐚⊟)☆, i.e. smallest sphere holding round point; 8 mul, 3 add.
  let (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
  Sphere(
    u: -aʷ * aʷ,
    x: aˣ * aʷ,
    y: aʸ * aʷ,
    z: aᶻ * aʷ,
    w: aʷ * aᵘ - aˣ * aˣ - aʸ * aʸ - aᶻ * aᶻ,
  )

func container*(d: Dipole): Sphere {.inline.} =
  ## Get container of dipole, i.e. smallest sphere holding it; 18 mul, 13 add.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
  Sphere(
    u: dᵛˣ * dᵛˣ + dᵛʸ * dᵛʸ + dᵛᶻ * dᵛᶻ,
    x: dᵛᶻ * dᵐʸ - dᵛʸ * dᵐᶻ - dᵛˣ * dᵖʷ,
    y: dᵛˣ * dᵐᶻ - dᵛᶻ * dᵐˣ - dᵛʸ * dᵖʷ,
    z: dᵛʸ * dᵐˣ - dᵛˣ * dᵐʸ - dᵛᶻ * dᵖʷ,
    w: (dᵐˣ * dᵐˣ + dᵐʸ * dᵐʸ + dᵐᶻ * dᵐᶻ) + dᵛˣ * dᵖˣ + dᵛʸ * dᵖʸ + dᵛᶻ * dᵖᶻ,
  )

func container*(c: Circle): Sphere {.inline.} =
  ## Get container of circle, i.e. smallest sphere holding it; 16 mul, 11 add.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
  Sphere(
    u: -cᵍˣ * cᵍˣ - cᵍʸ * cᵍʸ - cᵍᶻ * cᵍᶻ,
    x: cᵍʸ * cᵛᶻ - cᵍᶻ * cᵛʸ - cᵍʷ * cᵍˣ,
    y: cᵍᶻ * cᵛˣ - cᵍˣ * cᵛᶻ - cᵍʷ * cᵍʸ,
    z: cᵍˣ * cᵛʸ - cᵍʸ * cᵛˣ - cᵍʷ * cᵍᶻ,
    w: cᵍˣ * cᵐˣ + cᵍʸ * cᵐʸ + cᵍᶻ * cᵐᶻ - cᵍʷ * cᵍʷ,
  )

func container*(s: Sphere): Sphere {.inline.} =
  ## Get container of sphere, i.e. itself scaled by its weight; 5 mul.
  let (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
  Sphere(u: sᵘ * sᵘ, x: sˣ * sᵘ, y: sʸ * sᵘ, z: sᶻ * sᵘ, w: sʷ * sᵘ)



#[ Partners ]#

func partner*(a: PointRound): PointRound {.inline.} =
  ## Get partner of round point, i.e. same point with squared radius negated; 10 mul, 3 add.
  let
    (aˣ, aʸ, aᶻ, aʷ, aᵘ) = (a.x, a.y, a.z, a.w, a.u)
    w2 = aʷ * aʷ
  PointRound(
    x: aˣ * w2,
    y: aʸ * w2,
    z: aᶻ * w2,
    w: aʷ * w2,
    u: (aˣ * aˣ + aʸ * aʸ + aᶻ * aᶻ - aʷ * aᵘ) * aʷ,
  )

func partner*(d: Dipole): Dipole {.inline.} =
  ## Get partner of dipole; 29 mul, 14 add.
  let
    (dᵛˣ, dᵛʸ, dᵛᶻ) = (d.v.x, d.v.y, d.v.z)
    (dᵐˣ, dᵐʸ, dᵐᶻ) = (d.m.x, d.m.y, d.m.z)
    (dᵖˣ, dᵖʸ, dᵖᶻ, dᵖʷ) = (d.p.x, d.p.y, d.p.z, d.p.w)
    v2 = dᵛˣ * dᵛˣ + dᵛʸ * dᵛʸ + dᵛᶻ * dᵛᶻ
    f = dᵖʷ * dᵖʷ - (dᵐˣ * dᵐˣ + dᵐʸ * dᵐʸ + dᵐᶻ * dᵐᶻ) - dᵛˣ * dᵖˣ - dᵛʸ * dᵖʸ - dᵛᶻ * dᵖᶻ
  Dipole(
    v: Vector3(x: dᵛˣ * v2, y: dᵛʸ * v2, z: dᵛᶻ * v2),
    m: Vector3(x: dᵐˣ * v2, y: dᵐʸ * v2, z: dᵐᶻ * v2),
    p: PointFlat(
      x: (dᵐᶻ * dᵛʸ - dᵐʸ * dᵛᶻ) * dᵖʷ + dᵛˣ * f,
      y: (dᵐˣ * dᵛᶻ - dᵐᶻ * dᵛˣ) * dᵖʷ + dᵛʸ * f,
      z: (dᵐʸ * dᵛˣ - dᵐˣ * dᵛʸ) * dᵖʷ + dᵛᶻ * f,
      w: dᵖʷ * v2,
    ),
  )

func partner*(c: Circle): Circle {.inline.} =
  ## Get partner of circle; 29 mul, 14 add.
  ##   Symmetric with dipole's partner: f = gʷ² − 𝐯 ∙ 𝐯 − 𝐠 ∙ 𝐦; Terathon's header spells
  ##   its v-term with mixed signs, and library's own form is what suite holds this to.
  let
    (cᵍˣ, cᵍʸ, cᵍᶻ, cᵍʷ) = (c.g.x, c.g.y, c.g.z, c.g.w)
    (cᵛˣ, cᵛʸ, cᵛᶻ) = (c.v.x, c.v.y, c.v.z)
    (cᵐˣ, cᵐʸ, cᵐᶻ) = (c.m.x, c.m.y, c.m.z)
    g2 = cᵍˣ * cᵍˣ + cᵍʸ * cᵍʸ + cᵍᶻ * cᵍᶻ
    f = cᵍʷ * cᵍʷ - (cᵛˣ * cᵛˣ + cᵛʸ * cᵛʸ + cᵛᶻ * cᵛᶻ) - cᵍˣ * cᵐˣ - cᵍʸ * cᵐʸ - cᵍᶻ * cᵐᶻ
  Circle(
    g: PlaneCarrier(x: cᵍˣ * g2, y: cᵍʸ * g2, z: cᵍᶻ * g2, w: cᵍʷ * g2),
    v: Vector3(x: cᵛˣ * g2, y: cᵛʸ * g2, z: cᵛᶻ * g2),
    m: Vector3(
      x: (cᵛʸ * cᵍᶻ - cᵛᶻ * cᵍʸ) * cᵍʷ + cᵍˣ * f,
      y: (cᵛᶻ * cᵍˣ - cᵛˣ * cᵍᶻ) * cᵍʷ + cᵍʸ * f,
      z: (cᵛˣ * cᵍʸ - cᵛʸ * cᵍˣ) * cᵍʷ + cᵍᶻ * f,
    ),
  )

func partner*(s: Sphere): Sphere {.inline.} =
  ## Get partner of sphere; 10 mul, 3 add.
  let
    (sᵘ, sˣ, sʸ, sᶻ, sʷ) = (s.u, s.x, s.y, s.z, s.w)
    u2 = sᵘ * sᵘ
  Sphere(
    u: sᵘ * u2,
    x: sˣ * u2,
    y: sʸ * u2,
    z: sᶻ * u2,
    w: (sˣ * sˣ + sʸ * sʸ + sᶻ * sᶻ - sʷ * sᵘ) * sᵘ,
  )
