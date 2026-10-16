# P10: Give homogeneous scalars a division, a root and an exponential

**What it is.** A new module, `pga/scalars.nim`, treats x𝟏 + y𝟙 as one value, the homogeneous
scalar `ScalarHomogeneous`. It gives that value an inverse, a root and an exponential under each
product, and a division.

**What it is for.** The rigid norms return a homogeneous scalar in place of a whole multivector,
and keep a distance with its weight. At cga4d and cga5d the radius norm of an imaginary object is
an imaginary radius, where pin gives NaN.

**What it costs.** Four norm aliases stop forwarding to their operators, so a caller that adds a
norm to a multivector takes `.toMultivector`. At cga3d and cga6d the radius norm of an imaginary
object stays NaN, as at pin.

## Problem

At pin, the norms `normBulk`, `normWeight`, `norm` and `normRadius` forward to the operators `|∙`,
`|∘`, `|` and `|⊘`. Each takes a float root of one slot, and writes it into a whole multivector,
of 128 bytes at rga4d and 256 at cga5d. Section 4.3 of the book defines the radius norm as
√(𝐮 ∘ 𝐮), in (4.45). It is real for a real object, and imaginary for an imaginary one. Under the
conformal metric, 𝐦 ∘ 𝐦 is negative for about half of all multivectors, and there the float root
of `|⊘` gives NaN.

## Idea

- **Basis-set type.** `ScalarHomogeneous` is the basis-set type of P04 on 𝟏 and 𝟙, so it holds
  two floats, 16 bytes, in each algebra. Its bulk x lies on 𝟏, and its weight y on 𝟙. It stands
  for the value x/y, kept with its weight y, as a homogeneous point keeps a position with its
  weight.
- **Products.** 𝟏 is the unit of the geometric product, and 𝟙 is the unit of the antiproduct. P04
  emits the antiproduct from the table of the library, and no geometric product.
- **Squares.** `SQUARE_WEIGHT` reads the 𝟏 term of 𝟙 ⟑ 𝟙 from the table of the geometric
  product. `SQUARE_BULK` reads the 𝟙 term of 𝟏 ⟇ 𝟏 from the table of the antiproduct. The two
  are equal, and the Architect ruled on 2026-10-09 that the rule reads them from the table.
- **Functions.** `inverse`, `sqrt` and `exp` work under the geometric product, as Lengyel's
  `Inverse`, `Sqrt` and `Exp` do. A `when` on the square chooses the dual, the complex or the
  split-complex form as the program compiles. `inverseAnti`, `sqrtAnti` and `expAnti` work under
  the antiproduct, as `AntiInverse`, `AntiSqrt` and `AntiExp` do. Each is the complement of its
  form under the geometric product, since the complement swaps 𝟏 and 𝟙. Division is under the
  antiproduct, as in Lengyel's `DualNum`. Each function takes one form under each product, as
  the Architect ruled on 2026-10-10.
- **Norms.** Under the rigid metric, `normBulk` is the root of 𝐦 ∙ 𝐦 under the geometric product.
  `normWeight` is the root of 𝐦 ∘ 𝐦 under the antiproduct, as the wiki takes both. `norm` adds
  the two. A division by the weight norm unitizes a multivector. It turns a geometric norm into
  d𝟏 + 𝟙, where d is the distance, as the wiki unitizes the pair. Under the conformal metric,
  `normRadius` is the radius norm of the book.

The sign of 𝟙 ⟑ 𝟙 is the determinant of the metric on vectors, times (−1)^(n(n − 1)/2) for the
reverse of n vectors. The rigid metric is degenerate, so there the square is 0, and the pair is a
dual number. The conformal metric has two null vectors whose dot is −1, so its determinant is −1.
The reverse gives +1 at cga4d and cga5d, and −1 at cga3d and cga6d. So 𝟙 ⟑ 𝟙 = −𝟏 at cga4d and
cga5d, where the pair is a complex number. It is +𝟏 at cga3d and cga6d, where the pair is a
split-complex number.

So one formula cannot serve every metric. The table squares two roots of z = 4𝟙 + 4𝟏 again, with
the antiproduct of the library.

| Root | Squared at rga4d | Squared at cga5d |
|------|------------------|------------------|
| Dual form, 2𝟙 + 1𝟏 | 4𝟙 + 4𝟏 | 3𝟙 + 4𝟏 |
| Complex form, 2.197𝟙 + 0.910𝟏 | 4.828𝟙 + 4𝟏 | 4𝟙 + 4𝟏 |

Each form holds under its own metric alone. At cga3d and cga6d the split-complex form holds alone
in the same way. The forms agree on a pure weight above zero. They differ where both parts are
nonzero, or where the weight is negative. Under the geometric product the same table holds, with
𝟏 and 𝟙 swapped.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Dual form under every metric | Its root squares back wrong under the conformal metric |
| `unitize` by the weight norm | Spends a whole ⟇, and gives NaN where the weight norm is zero |
| `sqrtAnti` in a conformal `unitize` | Is 0 at zero radius, and lies on 𝟏 where 𝐮 ∘ 𝐮 is negative |

`unitize` keeps `^m`, which leaves a multivector of zero weight norm as it is. Under the conformal
metric, a division by a root on 𝟏 does not scale the element.

### Names

The pair takes the name `ScalarHomogeneous`, as the Architect ruled on 2026-10-10.

- Lengyel's wiki calls the pair a magnitude. The library and the wiki also use that word for the
  size of a quantity, so this proposal does not.
- Nor does it name the pair dual. The pair is no dual number under the conformal metric, and the
  dual of a scalar is the antiscalar alone.

## Costs

- **Four aliases.** `normBulk`, `normWeight` and `norm` under the rigid metric, and `normRadius`
  under the conformal metric, return `ScalarHomogeneous`. They stop forwarding to their
  operators, which keep `Multivector`, as every other function does. A caller that reads a norm by
  a static basis still compiles, since `ScalarHomogeneous` reads 𝟏 and 𝟙 that way. A caller that
  adds the norm to a `Multivector`, or passes it as one, takes `.toMultivector`. No function or
  test of the library calls the four norms. The catalogue of this project lists them only as
  aliases, so no expression changes.
- **Split-complex root.** At cga3d and cga6d the pair is split-complex, and a negative square has
  no root. So there the radius norm of an imaginary object stays NaN, as at pin.
- **Division of a multivector.** It is a whole ⟇ of the library. By the static baseline at pin,
  that ⟇ spends 192 multiplies at rga4d and 1 024 at cga5d, where `^∘` spends 24 and 40.
- **Conformal part norms.** At pin each conformal norm of the library is the size of its own part,
  as Table 4.12 defines. The change `conformal-norms` fills the center norm, `normCenter`, in the
  same way, and keeps `Multivector` as its return. This proposal keeps `Multivector` too, for the
  four part norms and `normCenter`. In the conformal algebras, only `normRadius` returns
  `ScalarHomogeneous`.
- **Bulk and weight norms under the conformal metric.** The bulk and weight norms here take the
  root of the whole dot and antidot, as the wiki does. Under the conformal metric those roots are
  no norm of the book. So `normBulk`, `normWeight` and `norm` stand under the rigid metric alone,
  as `normBulk` and `normWeight` do at pin. In the conformal algebras, `norm` stays that of pin.
- **Conformal unitization.** P11, `unitize-general`, sets the rule of unitization under the
  conformal metric. It divides a round object by its round weight norm, and any other element by
  √|𝐮 ∘ 𝐮| of that element. So a division by the weight norm here unitizes under the rigid metric
  alone.
- **Four functions.** Lengyel's `DualNum` also has an inverse root, a sine, a cosine and a
  tangent, each in both forms, and none is here.
- **Squared norms.** The norms read the dot and the antidot of the library on a whole
  `Multivector`, since P04 emits no squared norm. Each squared norm would be a unary 2D table.

## Open decisions

None.

## Landing

- **Order.** `ScalarHomogeneous` is a basis-set type of P04, and `pga/scalars.nim` imports
  `pga/basis_sets.nim`, which P04 adds.
- **Imports of `pga.nim`.** P04 adds `basis_sets` to the import and export lines of `pga.nim`, and
  this proposal adds `scalars`. The changes `doc-comments` and `doc-comments-2` quote those lines
  too, so whichever lands later quotes them again.
- **Change `doc-comments`.** It also edits the doc of `normRadius`, which this proposal replaces.
  The second of the two to land quotes the first.
- **P06, `float-width`.** If P06 lands first, each `float` of this proposal becomes `Coefficient`,
  as in the basis-set types of P04.
- **P09, P11 and change `conformal-norms`.** Each edits other lines, so either order holds. P11
  edits `normalizeWeight` and `unitize` of `pga.nim`, and `|∘`, `^∘` and `^` of
  `pga/operators.nim`. `conformal-norms` edits `normCenter` of `pga.nim`, and `|⊘` of
  `pga/operators.nim`. If P11 lands too, the `unitize` of `pga.nim` stays `^m`, and calls the `^∘`
  of P11.

## Evidence

`laws.nim` holds each law on 256 seeded samples. It imports the library with P04 and this change
applied, and nothing else. Each law compares against a product of the library on a whole
`Multivector`, so no law tests the emission of P04 against itself.

- The square read from each table equals that of the product of the library, with the sign that
  the metric gives.
- The complement of a homogeneous scalar equals that of the library.
- 𝟏 is the unit of ⟑, and z ⟑ z⁻¹ = 𝟏. 𝟙 is the unit of ⟇, and z ⟇ z⁻¹ = 𝟙. Also (y / z) ⟇ z = y.
- √z ⟑ √z = z and √z ⟇ √z = z, for each z with a root. Under the rigid metric the unit part of z
  is positive. In a complex algebra z is any. In a split-complex one the unit part is larger than
  the size of the other part. The root of zero is zero under each product.
- exp z equals its power series under each product, to 30 terms. exp(y + z) = exp y ⟑ exp z, and
  the same holds under ⟇.
- Where the pair has a root, the root of 𝐦 ∙ 𝐦 under ⟑ is not NaN. Its square under ⟑ is 𝐦 ∙ 𝐦.
- Under the rigid metric, the bulk, weight and geometric norms equal those of the library, on each
  sample and on each basis element. On a basis element one part of each root is zero, as for a
  point at the origin or a direction. The weight norm squared under ⟇ gives 𝐦 ∘ 𝐦 back. A
  multivector divided by its weight norm equals `^` of the library.
- Under the conformal metric, the radius norm squared gives 𝐦 ∘ 𝐦 back. Round points of radius r
  take 2aʷaᵘ − |a|² = ±r², as Table 4.13 gives. At cga4d and cga5d, the radius norm of each is r𝟙
  where the point is real, and r𝟏, as i, where it is imaginary. At cga3d and cga6d, the radius
  norm of an imaginary round point is NaN.

A copy that takes the dual form under the conformal metric fails the law of the root at cga5d. So
the laws see the rule.

Each coefficient of the 256 samples lies in [−1, 1]. The table counts the samples whose root of
𝐦 ∘ 𝐦 is NaN.

| Algebra | Float root at pin | `normRadius` |
|---------|-------------------|--------------|
| cga3d | 128 of 256 | 128 of 256 |
| cga4d | 141 of 256 | 0 of 256 |
| cga5d | 114 of 256 | 0 of 256 |
| cga6d | 117 of 256 | 117 of 256 |

No record times a function of this proposal, since the bench times the operators, which keep
`Multivector`. Each function on a homogeneous scalar spends a few operations on two floats.
