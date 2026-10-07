# P01: Derive every Cayley table from three

The library writes three tables by hand: the metric on vectors, the exterior product of bases,
and the complement permutation. Four rules derive the other tables, and each rule is used the
same way everywhere. This proposal is that state of `pga/cayleys.nim`, with the suites that read
it. Every exported table keeps its name, its shape and its cells, so no operator changes.

![Derivation map. The three accented tables are written by hand, and each arrow is one rule.
Each anti side but ⟇ is `constructAnti` of its base.](../../pages/derivation-map.svg)

## Four rules

| Rule | Tables it builds |
|------|------------------|
| `constructAnti`: conjugate by complements | antiwedge, 𝔾, antireverse, antidot |
| `applyConstant`, `applyMap`: fix or map operand | ★ ☆ ∨★ ∨☆ ∧★ ∧☆ each side, attitude, carrier |
| `filterGrades`: keep one grade of product | ∙, as grade 0 of ∨★ |
| Transwedge sum: wedge chains over one grade | ⟑, and ⟇ from the anti family |

Two constructors stay direct: `constructReverse` for the base side alone, and `constructParts`.
The weight part is the conjugate of the bulk part under the rigid metric only. Each dual is a
complement after 𝐆 or 𝔾, on the left or on the right, as the library keeps both sides.

A cell of `Cayley1D` is `seq[BasisSigned]` at pin, and the emitter reads its first term alone.
Each map that these rules build holds at most one term in a cell, so the emitter stays as at pin.
`slice` keeps its assertion of one term, so a map of two terms stops the build.

## Why

- **Simplicity.** Three constructors go: `constructDual` and both overloads of
  `constructProductInterior`. Two notes at pin ask for this: the interior products derive from
  base operators, and the dot filters a grade of bulk contraction.
- **Consistency.** Each interior product is one dual fed into one product, by one rule. At pin,
  `constructAnti` gives the anti side of 𝐆, wedge and dot. The antireverse, the duals and the
  interior products each have a constructor of their own.

## Transwedge

The library builds two transwedge families, one for ⟑ and one for ⟇, and this proposal keeps both.
Under the conformal metric, an order of the anti family is not the conjugate of that order of the
base family, although the two sums agree. So the families stay as the library exports them. Order
k sums one term
for each basis 𝐜 of grade k. The term strips 𝐜 from 𝐚 by its complement and from 𝐛 by its
dual, and then joins the two results.

The transwedge has 32 variants. Three choices matter: which product strips, which dual strips
𝐛, and whether the two complements are on opposed sides. Chirality changes nothing at any of
five algebras, and grade order against antigrade order is a relabel. So eight families stay at
even dimension, and four at odd dimension, where the complements are equal.

Below, 𝐜̱ is the left complement of 𝐜 and 𝐜̄ is its right complement. The library takes ★ and ☆
by the right complement, so 𝐜̱ is the opposed side. Each pair of rows differs in that choice
alone.

**Strip by ∨, join by ∧, order by grade.**

| # | Term for each 𝐜 | Order 0 | Equal grades | Order gr 𝐚 | Signed sum |
|---|-----------------|---------|--------------|------------|------------|
| 1 | `(𝐜̱ ∨ 𝐚) ∧ (𝐛 ∨ 𝐜★)` | ∧ | ∙ | 𝐛 ∨ 𝐚★ | ⟑, built |
| 2 | `(𝐜̄ ∨ 𝐚) ∧ (𝐛 ∨ 𝐜★)` | ∧ | ∙, signs differ | 𝐚★ ∨ 𝐛 | ⟑, antigrade sign |
| 3 | `(𝐜̱ ∨ 𝐚) ∧ (𝐛 ∨ 𝐜☆)` | 0 | weight on 𝟏 | 𝐛 ∨ 𝐚☆ | no unit |
| 4 | `(𝐜̄ ∨ 𝐚) ∧ (𝐛 ∨ 𝐜☆)` | 0 | weight, signs differ | 𝐚☆ ∨ 𝐛 | no unit |

**Strip by ∧, join by ∨, order by antigrade.**

| # | Term for each 𝐜 | Order 0 | Equal grades | Order antigrade 𝐚 | Signed sum |
|---|-----------------|---------|--------------|-------------------|------------|
| 5 | `(𝐜̱ ∧ 𝐚) ∨ (𝐛 ∧ 𝐜☆)` | ∨ | ∘ | 𝐛 ∧ 𝐚☆ | ⟇, by conjugate |
| 6 | `(𝐜̄ ∧ 𝐚) ∨ (𝐛 ∧ 𝐜☆)` | ∨ | ∘, signs differ | 𝐚☆ ∧ 𝐛 | ⟇, grade sign |
| 7 | `(𝐜̱ ∧ 𝐚) ∨ (𝐛 ∧ 𝐜★)` | 0 | bulk on 𝟙 | 𝐛 ∧ 𝐚★ | no unit |
| 8 | `(𝐜̄ ∧ 𝐚) ∨ (𝐛 ∧ 𝐜★)` | 0 | bulk, signs differ | 𝐚★ ∧ 𝐛 | no unit |

Order 0 is zero under the rigid metric only. Under the conformal metric 𝔾 = −𝐆, so family 3 is
−1 and family 7 is −5.

Family 1 gives wedge, dot, geometric product and bulk contraction. The dot and the contraction
are cheaper as maps, so the build takes them as maps. The identity at order gr 𝐚 stays as a
suite, so the build and the transwedge cannot drift apart.

## Grade restriction

A typed operand names its bases, and the emitter reads only those cells of the whole table.
The tables stay whole, so the table count does not grow with the number of types. Proposal P04,
`exact-kinds`, builds on this.

The alternative filters a copy of each table for each pair of operand types. One copy of a 2D
table costs 0.1 MB at 4D, 0.35 MB at 5D and 0.9 MB at 6D. About eight types and thirty binary
operators give some 1 900 tables, or about 1.7 GB of front-end memory at 6D. The 2D
`filterGrades` defines the dot.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Four dual products from transwedge | Built, tables equal; four N³ families where maps cost N² |
| Left and right chirality | Census at five algebras; tables identical |
| Dot from equal-grade transwedge cells | Built, equal; needs transwedge for what filter gives |
| Dot as scalar part of ⟑ | Checked; equal only up to (−1)^(k(k−1)/2) |
| Blade products by bit operations | Weighed; second generator, against three tables |
| `Option` cells in `Cayley1D` | Library before `3121342`; two cell shapes, and no sum of terms |
| ⟇ as conjugate of ⟑, one family | Built; equal sum, but anti orders differ at cga4d and cga5d |
| Drop `CAYLEYS_NORM_SQUARED` | Equal to dot, cell for cell; outside this idea, so it stays |

## Open decisions

- Adopt the derivation into the library, before the typed layer. It keeps every exported name,
  shape and cell.
- Keep `constructParts` direct on both sides, or conjugate it under the rigid metric only.
