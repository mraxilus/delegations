# P10: Give magnitudes a division, a root and an exponential

At pin, each norm takes a float root of one slot, and writes it into a whole multivector.
Unitization divides by that float, and does nothing where it is zero. The library has no division
by a multivector, no root and no exponential. The book treats the pair x𝟏 + y𝟙 as a dual number,
and on a dual number these functions are well defined. This proposal names the pair `Magnitude`,
as Lengyel's wiki does, and gives it an inverse, a division, a root and an exponential.

This proposal builds on P04, `exact-kinds`, since `Magnitude` is one of its kinds. The Architect
chose the name, the antiproduct and a rule read from the table on 2026-10-09.

## What it is

- **Kind.** `Magnitude` is `MultivectorOf[{Basis.scalar, Basis.scalarAnti}]`, two floats in each
  algebra. Its bulk x lies on 𝟏, and its weight y on 𝟙.
- **Product.** The product is the antiproduct that P04 emits from the table of the library. 𝟙 is
  its unit in each algebra, so the weight is the real part.
- **Square of the bulk.** `SQUARE_BULK` reads the 𝟙 term of 𝟏 ⟇ 𝟏 from the antiproduct table. It
  is 0 under the rigid metric, so there the pair is a dual number. It is −1 under the conformal
  metric, so there the pair is a complex number, with 𝟏 as i.
- **Functions.** `inverse`, `/`, `sqrt` and `exp` follow from that square alone. A `when` on it
  chooses the dual form or the complex form as the program compiles.
- **Norms.** `normWeight` is the root of 𝐦 ∘ 𝐦 as a magnitude, as `|∘` takes it at pin. `norm`
  adds the bulk norm to it, and `unitize` divides a multivector by its weight norm. Under the
  conformal metric, `normRadius` is the radius norm of the book. `pga.nim` lists that norm as `|⊘`,
  and at pin its body stops the compiler.

## Why the square decides

The conformal metric has e4² = e5² = 0 and e4 · e5 = −1. Its determinant is −1, so 𝟙 ⟑ 𝟙 = −𝟏
and 𝟏 ⟇ 𝟏 = −𝟙. The book states the same fact as 𝔾 = −G, in Section 4.3. So one formula cannot
serve both metrics. Two roots of z = 4𝟙 + 4𝟏, each squared again with the antiproduct of the
library:

| Root | Squared at rga4d | Squared at cga5d |
|------|------------------|------------------|
| Dual form, 2𝟙 + 1𝟏 | 4𝟙 + 4𝟏 | 3𝟙 + 4𝟏 |
| Complex form, 2.197𝟙 + 0.910𝟏 | 4.828𝟙 + 4𝟏 | 4𝟙 + 4𝟏 |

Each form holds under its own metric alone. So `Magnitude` reads the square from the table, and
each law below holds in all four algebras. The two forms agree on a pure weight above zero. They
differ where both parts are nonzero, or where the weight is negative.

## What it gains

- **The radius norm of the book.** Section 4.3 defines the radius norm as √(𝐮 ∘ 𝐮), in (4.45). It
  is real for a real object, and imaginary for an imaginary one. The prototype builds round points
  of radius r, with 2aʷaᵘ − |a|² = ±r² as Table 4.13 gives. `normRadius` returns r𝟙 where the point
  is real, and r𝟏, as i, where it is imaginary.
- **No NaN.** Under the conformal metric, 𝐦 ∘ 𝐦 is negative for about half of all multivectors.
  Of 256 seeded multivectors with each coefficient in [−1, 1], a float root of it, as `|∘` takes,
  gives NaN for 130 at cga5d and 124 at cga4d. `normRadius` gives none, and its square equals
  𝐦 ∘ 𝐦 for each one.
- **Division by a magnitude.** A geometric norm over its weight norm is d𝟏 + 𝟙, where d is the
  distance, as the wiki unitizes a magnitude. `unitize` divides a multivector by its weight norm,
  and equals `^` of the library under the rigid metric.
- **Size.** A magnitude holds 16 bytes. Each norm of the library writes 128 bytes at rga4d and 256
  at cga5d.

## Laws

`prototype.nim` holds each law on 256 seeded samples, at rga3d, rga4d, cga4d and cga5d. Each one
compares against the antiproduct of the library on a whole `Multivector`. So no law tests the
emission of P04 against itself.

- 𝟙 is the unit, and z ⟇ z⁻¹ = 𝟙.
- (y / z) ⟇ z = y.
- √z ⟇ √z = z, for each z with a root: a positive weight under the rigid metric, and any z under
  the conformal one.
- exp z equals its power series under the antiproduct, to 30 terms, and exp(y + z) = exp y ⟇ exp z.
- Under the rigid metric, the square of the weight norm is 𝐦 ∘ 𝐦. The weight norm, the geometric
  norm and `unitize` equal those of the library.
- Under the conformal metric, the radius norm is never NaN, and its square is 𝐦 ∘ 𝐦. The radius
  norm of each round point is r𝟙 or r𝟏, as the point is real or imaginary.

A copy that takes the dual form under the conformal metric fails the law of the root at cga5d. So
the laws see the rule.

## What it leaves out

- **The bulk norm keeps its float root.** Under the rigid metric a pure bulk squares to zero under
  the antiproduct, so it has no root there. A root under the geometric product would serve it.
- **The conformal norms keep their definitions at pin.** There `|∘` takes the root of the whole
  antidot, which gives the value of the radius norm and not the round weight norm. The book
  defines four norms, each the size of its own part, in Table 4.12. A separate change moves the
  library to them. Until it does, `|∙` gives NaN for each real round object, since 𝐮 • 𝐮 = −r²,
  in (4.44). So `normWeight`, `norm` and `unitize` hold their laws under the rigid metric alone.
- **Four functions.** Lengyel's `DualNum` also has a sine, a cosine and a tangent, and none is
  here.
- **One program.** The kinds of P04 live in its prototype alone, so `prototype.nim` imports that
  prototype. Its norms read the `Multivector` of the library, since P04 emits no squared norm.
- **No timing.** Each function spends a few operations on two floats, where a norm of the library
  spends a dense product.

## Open decisions

- Choose whether the bulk norm takes a root under the geometric product, as Lengyel's `Sqrt` does,
  beside the root under the antiproduct that the weight norm takes.
