# P10: Give homogeneous scalars the functions of Lengyel's dual number

**What it is.** A new module, `pga/scalars.nim`, treats s𝟏 + t𝟙 as one value, the homogeneous
scalar. At pin each norm returns it, as `MultivectorScalars`. The module gives it the functions of
Lengyel's `DualNum` under each product, each written once in ε², the square of 𝟙.

**What it is for.** A caller divides, roots, raises and takes the sine of a norm as one value, and
keeps a distance with its weight. A function without a value for some pair returns an `Option`, so
no NaN reaches the caller. At cga4d and cga5d the radius norm of an imaginary object is an
imaginary radius, where pin gives NaN.

**What it costs.** The root and the radius norm return an `Option` in every algebra, so a caller
at cga4d and cga5d unwraps a root that always exists. The alias `normRadius` stops forwarding to
its operator `|⊘`. The change builds on P04, whose basis-set forms give the products of pairs.

## Problem

At pin, every norm returns `MultivectorScalars`, the pair of the scalar and the antiscalar, and
takes a float root of one coefficient. The pair has `+` and `=~`, and no product, inverse, root or
exponential. Section 4.3 of the book defines the radius norm as √(𝐮 ∘ 𝐮), in (4.45). It is real
for a real object, and imaginary for an imaginary one. Under the conformal metric, 𝐦 ∘ 𝐦 is
negative for about half of all multivectors, and there the float root of `|⊘` gives NaN.

## Idea

- **Basis-set type.** The homogeneous scalar is `MultivectorScalars` at pin, the basis-set type on
  𝟏 and 𝟙. So it holds two coefficients, 16 bytes at 64 bits, in each algebra. Its part s lies on
  𝟏, and its part t on 𝟙, as the basis table of `algebra.nim` names them. It stands for the value
  s/t, kept with its weight t, as a homogeneous point keeps a position with its weight.
- **Square.** ε² is the square of 𝟙, as 𝟙 ⟑ 𝟙 = ε²𝟏, and it fixes the arithmetic of the pair.
  `constructSquare` reads it from the table of each product, into `SQUARES_WEDGE_DOT`. Its `base`
  is the square of 𝟙 under ⟑, and its `anti` the square of 𝟏 under ⟇. The Architect ruled on
  2026-10-09 that the rule reads them from the table. A static check holds both equal to
  rev(n) det 𝖌, from the metric, as the Architect ruled on 2026-10-24. The symbol follows the dual
  unit ε of Lengyel's `DualNum`, which writes the pair s + tε with ε² = 0.
- **Products.** 𝟏 is the unit of the geometric product, and 𝟙 is the unit of the antiproduct. The
  module writes no product of pairs. It takes the basis-set forms `⟑` and `⟇` of P04, which read
  the table of each product over 𝟏 and 𝟙 alone.
- **Functions.** Each of seven functions has a form under each product, as in Lengyel's `DualNum`,
  with a division. They are the inverse, the root, the inverse root, the exponential, the sine, the
  cosine and the tangent. Each is written once in ε²:
  - The inverse is (s𝟏 − t𝟙) / (s² − ε²t²).
  - The root solves p² + ε²q² = s and 2pq = t through ρ = √(s² − ε²t²). The larger part comes from
    a root, and the smaller part from a division, so neither cancels.
  - The exponential is eˢ (C(t)𝟏 + S(t)𝟙). C and S are the even and odd parts of exp⟑(t𝟙) under
    ε². The sine and the cosine take −ε².
  - The inverse root, the tangent and the division come from these.
- **Forms under ⟇.** The macro `defineAnti` derives each form under ⟇ from the body of its form
  under ⟑, once, at compile time. The library derives each table of the antiproduct in the same
  way. The macro swaps each name that the complement swaps: 𝟏 and 𝟙, s and t, `base` and `anti`,
  and ⟑ and ⟇. So each function has one body, and no form calls a complement at run time. The
  Architect ruled this on 2026-10-25.
- **Absence.** The inverse, the root, the inverse root, the tangent and the division return an
  `Option`, because each lacks a value for some pair. Each one has one type in every algebra, as
  the Architect ruled on 2026-10-24. At cga4d and cga5d the root is never none, and the caller
  there unwraps it. No function returns infinity or NaN.
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
| A plain pair from the root at cga4d and cga5d | The Architect ruled one type in each algebra |
| ε² from the metric, held to the table | The Architect kept the table as the source on 2026-10-24 |
| Each form under ⟇ by a complement at run time | Two swaps in each call, and none by macro |
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
| Square of the dual unit | `SQUARES_WEDGE_DOT` | Squares read from `CAYLEYS_WEDGE_DOT` |
| None | `constructSquare` | Builds from a table, as the other `construct` functions |
| None | `defineAnti` | Emits forms, as the other `define` macros |

- The parts on 𝟏 and 𝟙 are s and t, as the basis table of `algebra.nim` names them. The operands
  are m and n, as the library names its variables.
- The mark of the product sits where Lengyel puts it, under both products. It comes before a root,
  as in ⟇√𝐦, and after the name of a function, as in sin⟑𝐦. The inverse takes the mark after its
  operand, as in 𝐦⟑⁻¹, which the curator chose and the Architect took on 2026-10-25.
- Lengyel's wiki calls the pair a magnitude. The library and the wiki also use that word for the
  size of a quantity, so this proposal does not.
- Nor does it name the pair dual. The pair is no dual number under the conformal metric, and the
  dual of a scalar is the antiscalar alone.

## Costs

- **One alias.** Under the conformal metric, `normRadius` stops forwarding to its operator `|⊘`,
  which keeps its float root. It returns `Option[MultivectorScalars]`, so `pga.nim` imports
  `std/options`. No function or test of the library calls `normRadius`. The catalogue of this
  project lists it only as an alias, so no expression changes.
- **An unwrap where a root always exists.** At cga4d and cga5d the root is never none, yet the
  caller unwraps it, since each function has one type in every algebra.
- **Split-complex root.** At cga3d and cga6d a negative square has no root. So there the radius
  norm of an imaginary object is none.
- **Derivation by name.** `defineAnti` swaps names in the code of each body. So a body names each
  part as s or t, and calls each float function through its operand, as `t.sqrt`, or by module.
- **Square outside −1 to 1.** No metric of the library gives one. Such a metric needs a scaling by
  the root of its square, in the exponential and in the root of a negative s.
- **Division of a multivector.** It is the `⟇` of P04 of 𝐦 by a pair, so it reads the columns of
  𝟏 and 𝟙 of the table alone.
- **The `⟑` of P04.** At each RGA it stops the compile for two antiscalars, because 𝟙 ⟑ 𝟙 is zero
  there. No caller compiles that call at pin either, so nothing breaks. A pair holds 𝟏 as well, so
  each product of pairs compiles.
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

- **Order.** After P04, since the module takes its basis-set forms `⟑` and `⟇`.
- **Imports of `pga.nim`.** This proposal adds `scalars` to the import and export lines of
  `pga.nim`, and `std/options` above them. P04 adds `basis_sets` to the same lines, and this edit
  quotes them as P04 leaves them. The changes `doc-comments` and `doc-comments-2` quote them too.
  So whichever lands later quotes them again.
- **Float width.** Each part of the pair is `Coefficient`, so the arithmetic builds at each width.
- **P09, P11 and change `conformal-norms`.** Each edits other lines, so either order holds. P11
  edits `normalizeWeight` and `unitize` of `pga.nim`, and `|∘`, `^∘` and `^` of
  `pga/operators.nim`. `conformal-norms` edits `normCenter` of `pga.nim`, and `|⊘` of
  `pga/operators.nim`. If P11 lands too, the `unitize` of `pga.nim` stays `^m`, and calls the `^∘`
  of P11.

## Evidence

`laws.nim` holds each law on 4096 seeded samples, beside structured ones such as zero, the basis
elements and the edges of each domain. It imports the library with P04 and this change applied,
and nothing else. Each law compares against a product, a complement or a norm of the library, or
against an authority:

- Lengyel's `DualNum` at each RGA, for all fourteen functions.
- `std/complex` at cga4d and cga5d.
- The function on each idempotent at cga3d and cga6d.

The laws:

- The `⟑` and `⟇` of pairs equal the whole products of the library.
- 𝐦 ⟑ 𝐦⟑⁻¹ = 𝟏 and 𝐦 ⟇ 𝐦⟇⁻¹ = 𝟙. The inverse is none exactly where s² − ε²t² is zero at the
  scale of its terms.
- ⟑√𝐦 ⟑ ⟑√𝐦 = 𝐦, with an s of zero or more. The root is none exactly outside its domain. Where t
  is small, the square of the root misses it by a few rounding errors at most.
- (⟑√𝐦)⟑⁻¹ squared gives 𝟏 with 𝐦, and tan⟑𝐦 ⟑ cos⟑𝐦 = sin⟑𝐦, wherever each has a value.
- The exponential, the sine and the cosine equal their power series, to 30 terms. The exponential
  of a sum is the product of the exponentials, and the squares of the sine and the cosine sum to 𝟏.
- (𝐧 / 𝐦) ⟇ 𝐦 = 𝐧, for a pair and for a multivector.
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

The laws held at each of the nine algebras on `linux amd64, 4 cores`, on 2026-10-25. The table
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
