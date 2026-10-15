# P01: Derive every Cayley table from three

The library writes three tables by hand: the metric on vectors, the exterior product of bases,
and the complement permutation. Four rules derive most other tables, and each rule is used the
same way everywhere. This proposal is that state of `pga/cayleys.nim`, with the suites that read
it. Every exported table keeps its name, its shape and its cells, so no operator changes. P03,
`partner-sign`, and P08, `compound-tables`, build on this proposal.

![Derivation map. The three accented tables are written by hand, and each arrow is one rule.
Each anti side but ⟇, ☆, ∨★ and ∨☆ is `constructAnti` of its base.](../../pages/derivation-map.svg)

## Four rules

| Rule | Tables it builds |
|------|------------------|
| `constructAnti`: conjugate by complements | antiwedge, 𝔾, antireverse, antidot |
| `applyConstant`, `applyMap`: fix or map operand | ★ ☆ ∨★ ∨☆ ∧★ ∧☆ each side, attitude, carrier |
| `filterGrades`: keep one grade of product | ∙, as grade 0 of ∨★; ‖𝐦‖⊘², as top grade of ∘ |
| Transwedge sum: wedge chains over one grade | ⟑, and ⟇ from the anti family |

Four constructors stay direct: `constructReverse` for the base side alone, `constructParts`,
`constructExomorphismMetric` for 𝐆 from 𝖌, and `constructNormsSquared`. The weight part is the
conjugate of the bulk part under the rigid metric only. Each dual is a complement after 𝐆 or 𝔾,
on the left or on the right, as the library keeps both sides. The 2D `filterGrades` defines the
dot, as at pin it defines the squared radius norm.

A cell of `Cayley1D` is `seq[BasisSigned]` at pin, and the emitter sums the terms of a cell.
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
base family. The two sums agree, but the families stay as the library exports them. Order k sums
one term for each basis 𝐜 of grade k. The term strips 𝐜 from 𝐚 by its complement and from 𝐛 by
its dual, and then joins the two results.

The transwedge has 32 variants. Three choices matter: which product strips, which dual strips
𝐛, and whether the two complements are on opposed sides. Chirality changes no table, and grade
order against antigrade order is a relabel. So eight families stay at even dimension, and four at
odd dimension, where the complements are equal.

A census by hand on 2026-10-12 checks chirality and the family count at nine algebras: rga2d to
rga6d, and cga3d to cga6d. It calls `constructProductsTransitional` with each strip product,
dual, chirality and side of each complement. No table changes with chirality, and the calls give
eight distinct families at even dimension and four at odd dimension.

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

In families 3, 4, 7 and 8, the cells for order 0, equal grades and signed sum hold under the
rigid metric only. Under the conformal metric 𝔾 = −𝐆, so family 3 is −1 and family 7 is −5.

Family 1 gives wedge, dot, geometric product and bulk contraction. The dot and the contraction
are cheaper as maps, so the build takes them as maps. The identity at order gr 𝐚 stays as a
suite, so the build and the transwedge cannot drift apart.

## Implementation

- **Files.** `change.md` replaces `pga/cayleys.nim` whole, from the digest `4aa7a2507c537c06` of
  the file at pin. It also edits `tests/suites.nim`, which imports `cayleys {.all.}` and gains the
  suite `Internal: Transwedge`. No other file changes.
- **Types and signatures.** Every exported type, table and cell stays as at pin. Two private
  signatures lose their `Spatiality` parameter: `constructReverse()` and `reverse(b: Basis)`.
  The antireverse is `constructAnti` of the reverse, so neither needs the parameter.
- **Functions.** This proposal adds the three private functions below. Each `applyMap` applies
  the map first and the table second, and `mergeTerm` cancels an opposed term. `merge` now calls
  `mergeTerm`, so `std/sequtils` leaves the imports.
- **Removed and rewritten.** This proposal removes `constructDual` and both overloads of
  `constructProductInterior`. The 1D `constructAnti` changes to two calls of
  `applyMap`: the right complement, then the table, then the left complement. The table below
  gives the new rule of each derived table that changes.
- **Callers.** None must migrate, since every exported name, type and cell stays. The two
  `tables` claims compare 27 tables at pin with the same tables under this proposal. The removed
  and changed functions are private. `pga/operators.nim` and the modules of this project that
  import `cayleys {.all.}` call none of them.
- **Order of edits.** P08, `compound-tables`, quotes a line of the header of this file and
  reads `applyMap`, so it lands after this proposal, and P03, `partner-sign`, lands after P08.
  The change `cayleys-hygiene` renames an overload of `constructProductInterior`, which this
  proposal deletes, so the edits of that change are void once this proposal lands. Its other
  idea still applies, because this proposal writes the parity k(k−1)/2 of the reverse twice, in
  `reverse` and in `constructProductGeometric`. The changes `doc-comments` and `doc-comments-2`
  edit `pga/cayleys.nim` too, and whichever lands second is quoted again against the first. If
  this proposal lands second, its Replace carries their text under a new digest. `doc-comments-2`
  also edits the import line of `tests/suites.nim` that this proposal edits, so the second to
  land quotes that line again.
- **Dropped edit.** Once this proposal lands, `doc-comments` drops its edit that quotes
  `  CAYLEYS_DOT* = block:`. Applied after this proposal, that edit gives a line of 136
  characters with two docs that contradict each other. This proposal gives the dot its doc on
  that line already.

```nim
func applyMap(cayley, map: Cayley1D): Cayley1D {.compileTime.}
func applyMap(cayley: Cayley2D, map: Cayley1D, chirality: Chirality): Cayley2D {.compileTime.}
func mergeTerm(cell: var seq[BasisSigned], term: BasisSigned, as_negated = false) {.compileTime.}
```

In the table, `s` is `base` or `anti`. `side` is `left` or `right`, as a field and as a chirality.

| Table | Rule |
|-------|------|
| `CAYLEYS_REVERSE.anti` | `CAYLEYS_REVERSE.base.constructAnti(CAYLEYS_COMPLEMENT)` |
| `CAYLEYS_DUAL.s.side` | `CAYLEYS_COMPLEMENT.side.applyMap(CAYLEYS_EXOMORPHISM_METRIC.s)` |
| `CAYLEYS_INTERIOR.s.bulk.side` | `CAYLEYS_WEDGE.s.applyMap(CAYLEYS_DUAL.base.side, side)` |
| `CAYLEYS_INTERIOR.s.weight.side` | `CAYLEYS_WEDGE.s.applyMap(CAYLEYS_DUAL.anti.side, side)` |
| `CAYLEYS_DOT.base` | `CAYLEYS_INTERIOR.anti.bulk.right`, with `filterGrades` to `Grade.low` |
| `CAYLEY_ATTITUDE` | `CAYLEYS_WEDGE.anti`, with `applyConstant` of `Basis.horizon` on the right |

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Four dual products from transwedge | Built, tables equal; four N³ families where maps cost N² |
| Left and right chirality | Census by hand at nine algebras on 2026-10-12; tables identical |
| Dot from equal-grade transwedge cells | Built, equal; needs transwedge for what filter gives |
| Dot as scalar part of ⟑ | Checked; equal only up to (−1)^(k(k−1)/2) |
| Blade products by bit operations | Weighed; second generator, against three tables |
| `Option` cells in `Cayley1D` | Library before `3121342`; two cell shapes, and no sum of terms |
| ⟇ as conjugate of ⟑, one family | Built; equal sum, but anti orders differ at cga4d and cga5d |
| Drop `CAYLEYS_NORM_SQUARED` | Built from parts at pin; outside this idea, so it stays |

## Open decisions

- Adopt the derivation into the library, before the typed layer. It keeps every exported name,
  shape and cell.
- Keep `constructParts` direct on both sides, or conjugate it under the rigid metric only.
