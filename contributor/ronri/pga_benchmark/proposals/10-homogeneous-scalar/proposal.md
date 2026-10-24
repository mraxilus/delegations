# P10: Give homogeneous scalars the functions of Lengyel's dual number

**What it is.** A new module, `pga/scalars.nim`, treats x𝟏 + y𝟙 as one value, the homogeneous
scalar. At pin each norm returns it, as `MultivectorScalars`. The module gives it the functions of
Lengyel's `DualNum` under each product, each written once in ε², the square of 𝟙.

**What it is for.** A caller divides, roots, raises and takes the sine of a norm as one value, and
keeps a distance with its weight. A function without a value for some pair returns an `Option`, so
no NaN reaches the caller. At cga4d and cga5d the radius norm of an imaginary object is an
imaginary radius, where pin gives NaN.

**What it costs.** The type of the root and of the radius norm differs by algebra. The alias
`normRadius` stops forwarding to its operator `|⊘`.

## Problem

At pin, every norm returns `MultivectorScalars`, the pair of the scalar and the antiscalar, and
takes a float root of one coefficient. The pair has `+` and `=~`, and no product, inverse, root or
exponential. Section 4.3 of the book defines the radius norm as √(𝐮 ∘ 𝐮), in (4.45). It is real
for a real object, and imaginary for an imaginary one. Under the conformal metric, 𝐦 ∘ 𝐦 is
negative for about half of all multivectors, and there the float root of `|⊘` gives NaN.

## Idea

- **Basis-set type.** The homogeneous scalar is `MultivectorScalars` at pin, the basis-set type on
  𝟏 and 𝟙. So it holds two coefficients, 16 bytes at 64 bits, in each algebra. Its bulk x lies on
  𝟏, and its weight y on 𝟙. It stands for the value x/y, kept with its weight y, as a homogeneous
  point keeps a position with its weight.
- **Square.** ε² is the square of 𝟙, as 𝟙 ⟑ 𝟙 = ε²𝟏, and it fixes the arithmetic of the pair.
  `SQUARE_WEIGHT` reads it from the table of the geometric product, and `SQUARE_BULK` reads the
  square of 𝟏 from the table of the antiproduct. The Architect ruled on 2026-10-09 that the rule
  reads them from the table. A static check holds both equal to rev(n) det 𝖌, from the metric, as
  the Architect ruled on 2026-10-24. The symbol follows the dual unit ε of Lengyel's `DualNum`,
  which writes the pair s + tε with ε² = 0.
- **Products.** 𝟏 is the unit of the geometric product, and 𝟙 is the unit of the antiproduct. The
  module multiplies two pairs from ε² alone, in the block of the table that its static check
  holds. Each form under the antiproduct is the complement of its form under the geometric
  product.
- **Functions.** Each of seven functions has a form under each product, as in Lengyel's `DualNum`,
  with a division. They are the inverse, the root, the inverse root, the exponential, the sine, the
  cosine and the tangent. Each is written once in ε²:
  - The inverse is (x𝟏 − y𝟙) / (x² − ε²y²).
  - The root solves b² + ε²a² = x and 2ab = y through ρ = √(x² − ε²y²). The larger part comes from
    a root, and the smaller part from a division, so neither cancels.
  - The exponential is eˣ (C(y)𝟏 + S(y)𝟙). C and S are the even and odd parts of e^(y𝟙) under ε².
    The sine and the cosine take −ε².
  - The inverse root, the tangent and the division come from these.
- **Absence.** The inverse, the inverse root, the tangent and the division return an `Option`,
  because each lacks a value for some pair. The root returns a plain pair at cga4d and cga5d, where
  every pair has a root, and an `Option` elsewhere, as the Architect ruled on 2026-10-23. So its
  type is `MultivectorScalarsRoot`, which the square fixes. No function returns infinity or NaN.
- **Norms.** Under the rigid metric, the bulk norm of pin equals the root of 𝐦 ∙ 𝐦 under the
  geometric product. Its weight norm equals the root of 𝐦 ∘ 𝐦 under the antiproduct, as the wiki
  takes both. So they stay as at pin. A division by the weight norm unitizes a multivector. It
  turns a geometric norm into d𝟏 + 𝟙, where d is the distance, as the wiki unitizes the pair.
  Under the conformal metric, `normRadius` becomes the root of 𝐦 ∘ 𝐦 under the antiproduct, the
  radius norm of the book.

The sign of 𝟙 ⟑ 𝟙 is the determinant of the metric on vectors, times (−1)^(n(n − 1)/2) for the
reverse of n vectors. The rigid metric is degenerate, so there the square is 0. The conformal
metric has two null vectors whose dot is −1, so its determinant is −1.

| Algebra        | det 𝖌 | rev(n) | ε² | Pair          |
|----------------|-------|--------|----|---------------|
| rga2d to rga6d | 0     | ±1     | 0  | dual          |
| cga3d          | −1    | −1     | +1 | split-complex |
| cga4d          | −1    | +1     | −1 | complex       |
| cga5d          | −1    | +1     | −1 | complex       |
| cga6d          | −1    | −1     | +1 | split-complex |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Dual form under every metric | Its root squares back wrong under the conformal metric |
| One form for each metric, by `when` | Three forms each, and a root that cancels a small part |
| Infinity or NaN for no value | No compiler makes a caller handle NaN in a float (IV.4) |
| An `Option` from the root in every algebra | Every pair has a root at cga4d and cga5d (IV.5) |
| ε² from the metric, held to the table | The Architect kept the table as the source on 2026-10-24 |
| `unitize` by the weight norm | Spends a whole ⟇, and has no value where the weight norm is zero |
| `sqrtAnti` in a conformal `unitize` | Is 0 at zero radius, and lies on 𝟏 where 𝐮 ∘ 𝐮 is negative |

`unitize` keeps `^m`, which leaves a multivector of zero weight norm as it is. Under the conformal
metric, a division by a root on 𝟏 does not scale the element.

### Names

At pin the library names the pair `MultivectorScalars`, and this proposal takes that name. The
Architect ruled `ScalarHomogeneous` on 2026-10-10, for the type that this proposal then added. The
constructor is `initMultivectorScalars`, as `init` names the constructor of a type.

| Lengyel | Proposed | Why |
|---------|----------|-----|
| `Inverse`, `Sqrt`, `Exp` | `inverse`, `sqrt`, `exp` | Bare noun of the function (V.3) |
| `Sin`, `Cos`, `Tan` | `sin`, `cos`, `tan` | Bare noun of the function (V.3) |
| `InverseSqrt` | `sqrtInverse` | Head first, the qualifier last (V.2) |
| `AntiInverse` and the other anti forms | `inverseAnti` and kin | Head first, as `wedgeAnti` |
| Square of the dual unit | `SQUARE_WEIGHT`, `SQUARE_BULK` | Square of 𝟙 under ⟑, and of 𝟏 under ⟇ |
| None | `MultivectorScalarsRoot` | Type of the root, which the square fixes |

- Lengyel's wiki calls the pair a magnitude. The library and the wiki also use that word for the
  size of a quantity, so this proposal does not.
- Nor does it name the pair dual. The pair is no dual number under the conformal metric, and the
  dual of a scalar is the antiscalar alone.

## Costs

- **One alias.** Under the conformal metric, `normRadius` stops forwarding to its operator `|⊘`,
  which keeps its float root. It returns `MultivectorScalarsRoot[SQUARE_BULK]`: a plain pair at
  cga4d and cga5d, and an `Option` at cga3d and cga6d. No function or test of the library calls
  `normRadius`. The catalogue of this project lists it only as an alias, so no expression changes.
- **Type by algebra.** A caller that spans algebras branches on the type of the root. One build is
  one algebra, so no build sees two types.
- **Split-complex root.** At cga3d and cga6d a negative square has no root. So there the radius
  norm of an imaginary object is none.
- **Two swaps.** Each form under the antiproduct swaps the parts of the pair twice. Unmeasured.
- **Square outside −1 to 1.** No metric of the library gives one. Such a metric needs a scaling by
  the root of its square, in the exponential and in the root of a negative bulk.
- **Division of a multivector.** It is a whole ⟇ of the library. By the static baseline at pin,
  that ⟇ spends 192 multiplies at rga4d and 1 024 at cga5d, where `^∘` spends 24 and 40.
- **Conformal part norms.** At pin each conformal norm of the library is the size of its own part,
  as Table 4.12 defines. The change `conformal-norms` fills the center norm, `normCenter`, in the
  same way. This proposal keeps the four part norms and `normCenter` as at pin. In the conformal
  algebras, only `normRadius` changes.
- **Bulk and weight norms under the conformal metric.** There the root of the whole dot or antidot
  is no norm of the book. So this proposal gives no conformal bulk or weight norm, and `norm`
  stays that of pin.
- **Conformal unitization.** P11, `unitize-general`, sets the rule of unitization under the
  conformal metric. It divides a round object by its round weight norm, and any other element by
  √|𝐮 ∘ 𝐮| of that element. So a division by the weight norm here unitizes under the rigid metric
  alone.
- **Squared norms.** The radius norm reads the antidot of the library on a whole `Multivector`,
  since no change emits a squared norm. Each squared norm would be a unary 2D table.

## Open decisions

None.

## Landing

- **Order.** None. The module reads the tables of the library at pin, and no change of another
  proposal.
- **Imports of `pga.nim`.** This proposal adds `scalars` to the import and export lines of
  `pga.nim`. P04 adds `basis_sets` to the same lines, and the changes `doc-comments` and
  `doc-comments-2` quote them too. So whichever lands later quotes them again.
- **Float width.** Each part of the pair is `Coefficient`, so the arithmetic builds at each width.
- **P09, P11 and change `conformal-norms`.** Each edits other lines, so either order holds. P11
  edits `normalizeWeight` and `unitize` of `pga.nim`, and `|∘`, `^∘` and `^` of
  `pga/operators.nim`. `conformal-norms` edits `normCenter` of `pga.nim`, and `|⊘` of
  `pga/operators.nim`. If P11 lands too, the `unitize` of `pga.nim` stays `^m`, and calls the `^∘`
  of P11.

## Evidence

`laws.nim` holds each law on 4096 seeded samples, beside structured ones such as zero, the basis
elements and the edges of each domain. It imports the library with this change applied, and
nothing else. Each law compares against a product, a complement or a norm of the library, or
against an authority:

- Lengyel's `DualNum` at each RGA, for all fourteen functions.
- `std/complex` at cga4d and cga5d.
- The function on each idempotent at cga3d and cga6d.

The laws:

- The products and the complement of pairs equal those of the library.
- z ⟑ z⁻¹ = 𝟏 and z ⟇ z⁻¹ = 𝟙. The inverse is none exactly where x² − ε²y² is zero at the scale of
  its terms.
- √z ⟑ √z = z, with a bulk of zero or more. The root is none exactly outside its domain. Where the
  weight is small, the square of the root misses it by a few rounding errors at most.
- (1/√z)² ⟑ z = 𝟏, and tan z ⟑ cos z = sin z, wherever each has a value.
- The exponential, the sine and the cosine equal their power series, to 30 terms.
  e^(y + z) = eʸ ⟑ eᶻ, and sin² z + cos² z = 𝟏.
- (y / z) ⟇ z = y, for a pair and for a multivector.
- Each law holds under the antiproduct as well.
- Under the rigid metric, the root of 𝐦 ∙ 𝐦 under ⟑ equals the bulk norm of the library, and the
  root of 𝐦 ∘ 𝐦 under ⟇ equals its weight norm. A multivector divided by its weight norm equals
  `^` of the library.
- Under the conformal metric, the radius norm squared under ⟇ gives 𝐦 ∘ 𝐦 back. It has a value
  exactly where the pair has a root. Round points of radius r take 2aʷaᵘ − |a|² = ±r², as Table
  4.13 gives, and the radius norm of each is r𝟙, r𝟏 or none.

A copy whose root takes the smaller part by its own root fails the law of the small part at cga3d
and cga4d. Its root of 1𝟏 + 10⁻¹⁰𝟙 misses the weight by 10⁻¹⁰, and the law stops it. So the laws
see the cancellation.

The laws held at each of the nine algebras on `linux amd64, 4 cores`, on 2026-10-24. The table
counts the pairs with a root, of 4112. It also counts the radius norms that are none, beside the
float roots of `|⊘` that are NaN, on the same 4096 multivectors.

| Algebra        | ε² | Pairs with a root | Float root NaN | `normRadius` none |
|----------------|----|-------------------|----------------|-------------------|
| rga2d to rga6d | 0  | 2111              |                |                   |
| cga3d          | +1 | 1089              | 2022           | 2022              |
| cga4d          | −1 | 4112              | 2095           | 0                 |
| cga5d          | −1 | 4112              | 2043           | 0                 |
| cga6d          | +1 | 1089              | 2061           | 2061              |

No record times a function of this proposal, since the bench times the operators. Each function on
a homogeneous scalar spends a few operations on two coefficients.
