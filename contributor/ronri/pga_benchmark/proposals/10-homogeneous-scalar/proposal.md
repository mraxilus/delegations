# P10: Give homogeneous scalars a division, a root and an exponential

At pin, each norm takes a float root of one slot, and writes it into a whole multivector.
Unitization divides by that float, and does nothing where it is zero. The library has no division
by a multivector, no root and no exponential. The book treats the pair x𝟏 + y𝟙 as a dual number,
and on a dual number these functions are well defined. This proposal names the pair a homogeneous
scalar, `ScalarHomogeneous`. It gives the pair an inverse, a root and an exponential under each
product, and a division, as Lengyel's `DualNum` has.

This proposal builds on P04, `exact-kinds`, since `ScalarHomogeneous` is one of its kinds. The
Architect chose a rule read from the table on 2026-10-09, and a form under each product and the
name on 2026-10-10.

## What it is

- **Kind.** `ScalarHomogeneous` is `MultivectorOf[{Basis.scalar, Basis.scalarAnti}]`, two floats
  in each algebra. Its bulk x lies on 𝟏, and its weight y on 𝟙.
- **Name.** The pair stands for the value x/y, kept with its weight y, as a homogeneous point keeps
  a position with its weight. Lengyel's wiki calls it a magnitude. The library and the wiki also
  use that word for the size of a quantity, so this proposal does not. Nor does it name the pair
  dual. The pair is no dual number under the conformal metric, and the dual of a scalar is the
  antiscalar alone.
- **Products.** 𝟏 is the unit of the geometric product, and 𝟙 is the unit of the antiproduct. P04
  emits the antiproduct from the table of the library, and no geometric product.
- **Squares.** `SQUARE_WEIGHT` reads the 𝟏 term of 𝟙 ⟑ 𝟙, and `SQUARE_BULK` reads the 𝟙 term of
  𝟏 ⟇ 𝟏, each from the table of its product. The two are equal. Each is 0 under the rigid metric,
  so there the pair is a dual number. Each is −1 under the conformal metric, so there the pair is
  a complex number.
- **Functions.** `inverse`, `sqrt` and `exp` work under the geometric product, as Lengyel's
  `Inverse`, `Sqrt` and `Exp` do. A `when` on the square chooses the dual form or the complex
  form as the program compiles. `inverseAnti`, `sqrtAnti` and `expAnti` work under the
  antiproduct, as `AntiInverse`, `AntiSqrt` and `AntiExp` do. Each is the complement of its form
  under the geometric product, since the complement swaps 𝟏 and 𝟙. Division is under the
  antiproduct, as in Lengyel's `DualNum`.
- **Norms.** `normBulk` is the root of 𝐦 ∙ 𝐦 under the geometric product, and `normWeight` is the
  root of 𝐦 ∘ 𝐦 under the antiproduct, as the wiki takes them. `norm` adds the two, and
  `unitize` divides a multivector by its weight norm. Under the conformal metric, `normRadius` is
  the radius norm of the book. `pga.nim` lists that norm as `|⊘`, and at pin it takes a float
  root, which is NaN for an imaginary object.

## Why the square decides

The conformal metric has e4² = e5² = 0 and e4 · e5 = −1. Its determinant is −1, so 𝟙 ⟑ 𝟙 = −𝟏
and 𝟏 ⟇ 𝟏 = −𝟙. The book states the same fact as 𝔾 = −G, in Section 4.3. So one formula cannot
serve both metrics. Two roots of z = 4𝟙 + 4𝟏, each squared again with the antiproduct of the
library:

| Root | Squared at rga4d | Squared at cga5d |
|------|------------------|------------------|
| Dual form, 2𝟙 + 1𝟏 | 4𝟙 + 4𝟏 | 3𝟙 + 4𝟏 |
| Complex form, 2.197𝟙 + 0.910𝟏 | 4.828𝟙 + 4𝟏 | 4𝟙 + 4𝟏 |

Each form holds under its own metric alone. So `ScalarHomogeneous` reads the square from the
table, and each law below holds in all four algebras. The two forms agree on a pure weight above
zero. They differ where both parts are nonzero, or where the weight is negative. Under the
geometric product the same table holds, with 𝟏 and 𝟙 swapped.

## What it gains

- **The radius norm of the book.** Section 4.3 defines the radius norm as √(𝐮 ∘ 𝐮), in (4.45). It
  is real for a real object, and imaginary for an imaginary one. The prototype builds round points
  of radius r, with 2aʷaᵘ − |a|² = ±r² as Table 4.13 gives. `normRadius` returns r𝟙 where the point
  is real, and r𝟏, as i, where it is imaginary.
- **No NaN.** Under the conformal metric, 𝐦 ∘ 𝐦 is negative for about half of all multivectors.
  Of 256 seeded multivectors with each coefficient in [−1, 1], a float root of it, as `|⊘` takes,
  gives NaN for 114 at cga5d and 141 at cga4d. `normRadius` gives none, and its square equals
  𝐦 ∘ 𝐦 for each one.
- **Division by a homogeneous scalar.** A geometric norm over its weight norm is d𝟏 + 𝟙, where d
  is the distance, as the wiki unitizes the pair. `unitize` divides a multivector by its weight
  norm, and equals `^` of the library under the rigid metric.
- **Size.** A homogeneous scalar holds 16 bytes. Each norm of the library writes 128 bytes at rga4d
  and 256 at cga5d.

## Laws

`prototype.nim` holds each law on 256 seeded samples, at rga3d, rga4d, cga4d and cga5d. Each one
compares against a product of the library on a whole `Multivector`. So no law tests the emission
of P04 against itself.

- The complement of a homogeneous scalar equals that of the library.
- 𝟏 is the unit of ⟑, and z ⟑ z⁻¹ = 𝟏. 𝟙 is the unit of ⟇, and z ⟇ z⁻¹ = 𝟙.
- (y / z) ⟇ z = y.
- √z ⟑ √z = z and √z ⟇ √z = z, for each z with a root. Under the rigid metric the unit part of z
  is positive, and under the conformal one z is any.
- exp z equals its power series under each product, to 30 terms. exp(y + z) = exp y ⟑ exp z, and
  the same holds under ⟇.
- The bulk norm is never NaN, and its square under ⟑ is 𝐦 ∙ 𝐦.
- Under the rigid metric, the square of the weight norm under ⟇ is 𝐦 ∘ 𝐦. The bulk norm, the
  weight norm, the geometric norm and `unitize` equal those of the library.
- Under the conformal metric, the radius norm is never NaN, and its square is 𝐦 ∘ 𝐦. The radius
  norm of each round point is r𝟙 or r𝟏, as the point is real or imaginary.

A copy that takes the dual form under the conformal metric fails the law of the root at cga5d. So
the laws see the rule.

## What it leaves out

- **The four part norms of the library.** At pin each conformal norm of the library is the size of
  its own part, as Table 4.12 defines. The bulk and weight norms here take the root of the whole
  dot and antidot, as the wiki does. So the bulk norm, the weight norm, `norm` and `unitize` equal
  those of the library under the rigid metric alone.
- **Four functions.** Lengyel's `DualNum` also has an inverse root, a sine, a cosine and a tangent,
  each in both forms, and none is here.
- **One program.** The kinds of P04 live in its prototype alone, so `prototype.nim` imports that
  prototype. Its norms read the `Multivector` of the library, since P04 emits no squared norm.
- **No timing.** Each function spends a few operations on two floats, where a norm of the library
  spends a dense product.
