# P10: Give homogeneous scalars the functions of Lengyel's dual number

**What it is.** A new module, `pga/scalars.nim`, treats s𝟏 + t𝟙 as one value, the homogeneous
scalar. At pin each norm returns it, as `MultivectorScalars`. The module gives it the functions of
Lengyel's `DualNum` under each product, each written once in ε², the square of 𝟙.

**What it is for.** A caller divides, roots, raises and takes the sine of a norm as one value, and
keeps a distance with its weight. A function without a value for some pair returns an `Option`, so
no NaN marks a missing value. At cga4d and cga5d the radius norm of an imaginary object is an
imaginary radius, where pin gives NaN.

**What it costs.** The root and the radius norm return an `Option` in every algebra, so a caller
at cga4d and cga5d unwraps a root that always exists. The radius norm `|⊘` moves to
`pga/scalars.nim` in both its forms, since `pga/operators.nim` cannot import the root. The change
builds on P04, whose basis-set forms give the products of pairs.

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
  under ⟑, once, at compile time. The library derives three anti tables in the same way, through
  `constructAnti`: those of the metric exomorphism, the exterior product and the dot. It builds the
  table of ⟇ from the anti transwedges. The macro swaps each name that the complement swaps: 𝟏
  and 𝟙, s and t, `base` and `anti`, and ⟑ and ⟇. So each function has one body, and no form
  calls a complement at run time. The Architect ruled this on 2026-10-25.
- **Absence.** The inverse, the root, the inverse root, the tangent and the division return an
  `Option`, because each lacks a value for some pair. Each one has one type in every algebra, as
  the Architect ruled on 2026-10-24. At cga4d and cga5d the root is never none, and the caller
  there unwraps it. No function returns infinity or NaN to mark a pair without a value.
- **Tangent.** Under ε² = 0 the tangent of a finite pair always has a value, since the float cosine
  is never 0. At the float nearest a pole it is about 1.6 × 10¹⁶. Under ε² = −1 it is none only
  where a part of the cosine squares past the float range, as for |t| above about 355. Under
  ε² = +1 it is none where the cosine is null, as at s = t = π/4.
- **Norms.** Under the rigid metric, the bulk norm of pin equals the root of 𝐦 ∙ 𝐦 under the
  geometric product. Its weight norm equals the root of 𝐦 ∘ 𝐦 under the antiproduct, as the wiki
  takes both. So they stay as at pin. A division by the weight norm unitizes a multivector. It
  turns a geometric norm into d𝟏 + 𝟙, where d is the distance, as the wiki unitizes the pair.
- **Radius norm.** Under the conformal metric, `|⊘` becomes the root of 𝐦 ∘ 𝐦 under the
  antiproduct, the radius norm of the book. Its whole form and its typed form of P04 both take the
  root of the squared radius norm `|⊘²`. The alias `normRadius` forwards to it in one line, as the
  Architect ruled on 2026-11-17. An alias only forwards, and never changes what its operator does.
- **Place of the radius norm.** `pga/scalars.nim` imports `pga/operators.nim`, which holds the
  products of pairs. So `pga/operators.nim` cannot import the root, and both forms of `|⊘` move to
  `pga/scalars.nim`, after `sqrtAnti`. The typed form reads `coefficientOr` of `pga/operators.nim`
  through `{.all.}`, and the doc of that function names this reader.
- **Suites.** At pin the suites of the library hold a stand-in root and antiroot, under a TODO
  that waits for this module, and they skip the test of (4.45). The tests of (2.87) to (2.90) call
  the root and the antiroot of this module in their place, and check that each exists. The test of
  (4.45) holds `|⊘` under the conformal metric, and fixes which root it gives. The TODO keeps `abs`
  and `div`. P04's test of typed norms checks first that both forms of `|⊘` have a value or have
  none together, then compares the value.

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
| Root in `normRadius`, float root in `\|⊘` | An alias only forwards, as the Architect ruled |
| `operators.nim` includes `scalars.nim` | It makes one module of two concepts |
| `\|⊘` as template that finds `sqrtAnti` | It reads a module that it does not import |
| A module of norms that imports both | It moves five norms that take no root of a pair |

`unitize` keeps `^m`, which leaves a multivector of zero weight norm as it is. Under the conformal
metric, a division by a root on 𝟏 does not scale the element.

### Names

At pin the library names the pair `MultivectorScalars`, and this proposal takes that name. The
Architect ruled `ScalarHomogeneous` on 2026-10-10, for the type that this proposal then added. The
constructor is `initMultivectorScalars`, as `init` names the constructor of a type. It stands in
`pga/multivectors.nim` beside `initElement`, since it builds a value of a type of that module. The
doc of the type there names the pair the homogeneous scalar, and no longer dual numbers.

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

- **One norm outside its module.** `|⊘` stands in `pga/scalars.nim`, and each other norm in
  `pga/operators.nim`. Under the conformal metric it returns `Option[MultivectorScalars]`, in both
  forms. `normRadius` returns `auto`, as each alias of P04 does, so `pga.nim` imports no
  `std/options`.
- **A private function reached.** The typed `|⊘` reads `coefficientOr` through `{.all.}`, as an
  internal of a sibling (I.6). The function stays private, and its doc names `pga/scalars.nim`.
- **Callers of `|⊘`.** No function of the library calls it. Two tests do: the test of (4.45), and
  P04's test of typed norms. The catalogue of this project measures `|⊘`, and the bench folds the
  value of an `Option` where it has one. So the bench counts no NaN for `|⊘`, where pin counts one
  for about half of all multivectors.
- **An unwrap where a root always exists.** At cga4d and cga5d the root is never none, yet the
  caller unwraps it, since each function has one type in every algebra.
- **Split-complex root.** At cga3d and cga6d a negative square has no root. So there the radius
  norm of an imaginary object is none.
- **Derivation by name.** `defineAnti` swaps names in the code of each body. So a body names each
  part as s or t. It calls a float function that shares its name with a function of the pair
  through its operand, as `s.exp`, or by module.
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
  algebras, only `|⊘` and its alias change.
- **Bulk and weight norms under the conformal metric.** There the root of the whole dot or antidot
  is no norm of the book. So this proposal gives no conformal bulk or weight norm, and `norm`
  stays that of pin.
- **Conformal unitization.** P11, `unitize-general`, sets the rule of unitization under the
  conformal metric. It divides a round object by its round weight norm, and any other element by
  √|𝐮 ∘ 𝐮| of that element. So a division by the weight norm here unitizes under the rigid metric
  alone.
- **Float range.** No function guards the range of a float. Where a step overflows, a part of the
  result is ∞ or NaN. `exp` of 710𝟏 is ∞𝟏 + NaN𝟙 in each algebra, and the root of 10³⁰⁸𝟏 is ∞𝟏.
  At cga4d `tan` of 800𝟙 is some pair of NaN.
- **Radius zero.** The root compares its domain exactly, as no scale is in hand there. 𝐦 ∘ 𝐦 of a
  point of radius zero rounds to either side of zero. Of 4 096 such points with a weight of 0.5 to
  2, 163 have no radius norm at cga3d. At cga4d 204 have an imaginary one, and at cga5d 187 do. Pin
  gives NaN for the same points. A caller compares 𝐦 ∘ 𝐦 at the scale of 𝐦 first.
- **Suites.** The suites of the library call `sqrt`, `sqrtAnti` and `|⊘` of `pga/scalars.nim`, and
  no other of its functions. The laws of the others run from this project alone.

## Open decisions

None. The Architect ruled on 2026-11-17 that `|⊘` holds the root and its alias forwards.

## Landing

- **Order.** After P04, since the module takes its basis-set forms `⟑` and `⟇`.
- **Imports of `pga.nim`.** This proposal adds `scalars` to the import and export lines of
  `pga.nim`. P04 leaves these lines as at pin, and this edit quotes them so. The change
  `doc-comments` keeps these lines, so the quotes of this proposal fit after it. If this proposal
  lands first, that change quotes the import line again. The change `doc-comments-2` edits the
  export line, so the second of the two to land quotes it again.
- **Change `doc-comments`.** It also adds a line below the first doc line of `normRadius`. This
  proposal adds its line below the same line, so either order applies with no misfit.
- **Change `doc-comments-2`.** It adds a doc line to the stand-in `sqrt` of `tests/suites.nim`,
  which this proposal removes. If that change lands first, the edit of the stand-ins quotes that
  line too. If this proposal lands first, that edit of the change is void.
- **Change `algebra-hygiene`.** It renames `TOLERANCE_ABS`, which `inverse` of `pga/scalars.nim`
  and `laws.nim` name. The second to land carries the new name into both.
- **P12, `cayley-cells`.** `constructSquare` and the check of the swap each build one cell as
  `@[BasisSigned(...)]`. The second of the two to land writes `BasisSigned(...).toBasesSigned` at
  both lines.
- **Float width.** Each part of the pair is `Coefficient`, so the arithmetic builds at each width.
- **P09 and P11.** Each edits other lines, so either order holds. P11 edits `normalizeWeight`
  and `unitize` of `pga.nim`, and `|∘`, `^∘` and `^` of `pga/operators.nim`. If P11 lands too, the
  `unitize` of `pga.nim` stays `^m`, and calls the `^∘` of P11. In `tests/suites.nim`, P11 quotes
  the head of suite `Internal`, and this proposal quotes the test of (4.45).
- **Change `conformal-norms`.** It edits the doc of the whole `|⊘` in `pga/operators.nim`, and adds
  the center norm `|⊙` after it. It also adds a test of Table 4.13 that reads `|⊘𝐮` as a
  multivector. If that change lands first, this proposal quotes its doc of `|⊘`, and keeps `|⊙`
  after `|□`. Its test then reads the value of the `Option`. If this proposal lands first, that
  change adds `|⊙` after `|□`, and its test reads that value.

## Evidence

`laws.nim` holds each law on 4 096 seeded samples, beside structured ones such as zero, the basis
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
- The tangent is none exactly where the cosine has no inverse. It is none at s = t = π/4 under
  ε² = +1, and at 1𝟏 + 360𝟙 under ε² = −1.
- The exponential, the sine and the cosine equal their power series, to 30 terms. The exponential
  of a sum is the product of the exponentials, and the squares of the sine and the cosine sum to 𝟏.
- (𝐧 / 𝐦) ⟇ 𝐦 = 𝐧, for a pair, and for a whole multivector over a pair with both parts.
- Each law holds under the antiproduct as well.
- Under the rigid metric, the root of 𝐦 ∙ 𝐦 under ⟑ equals the bulk norm of the library, and the
  root of 𝐦 ∘ 𝐦 under ⟇ equals its weight norm. A multivector divided by its weight norm equals
  `^` of the library.
- Under the conformal metric, the radius norm squared under ⟇ gives 𝐦 ∘ 𝐦 back. It has a value
  exactly where the pair has a root. Round points of radius r take 2aʷaᵘ − |a|² = ±r², as Table
  4.13 gives, and the radius norm of each is r𝟙, r𝟏 or none.
- The typed `|⊘`, the whole `|⊘` and `normRadius` give one value, exactly, or none together. A
  typed vector holds it against its widened copy, on seeded vectors and on round points.

A copy whose root takes the smaller part by its own root fails the law of the small part at cga3d
and cga4d. Its root of 1𝟏 + 10⁻¹⁰𝟙 misses the weight by 10⁻¹⁰, and the law stops it. So the laws
see the cancellation.

The laws hold at each of the nine algebras in the evaluation of 2026-11-26. The table comes from a
run of `laws.nim` on `linux amd64, 4 cores` on 2026-11-19, at library commit `3d9696e`. It counts
the pairs with a root, of 4 114. It also counts the radius norms that are none, beside the float
roots of `|⊘` that are NaN, on the same 4 096 multivectors.

| Algebra        | ε² | Pairs with a root | Float root NaN | `normRadius` none |
|----------------|----|-------------------|----------------|-------------------|
| rga2d to rga6d | 0  | 2 113             |                |                   |
| cga3d          | +1 | 1 090             | 2 022          | 2 022             |
| cga4d          | −1 | 4 114             | 2 095          | 0                 |
| cga5d          | −1 | 4 114             | 2 043          | 0                 |
| cga6d          | +1 | 1 090             | 2 061          | 2 061             |

No record times a function of this proposal, since the bench times the operators. Each function on
a homogeneous scalar spends a few operations on two coefficients.
