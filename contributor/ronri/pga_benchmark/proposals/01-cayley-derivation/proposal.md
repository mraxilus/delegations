# P01: Derive every Cayley table from three

The library writes three tables by hand: the metric on vectors, the exterior product of bases,
and the complement permutation. Four rules derive every other table, and each rule is used the
same way everywhere. This proposal is that end state of `pga/cayleys.nim`, with the operators and
suites that read it.

## Four rules

| Rule | Tables it builds |
|------|------------------|
| `constructAnti`: conjugate by complements | antiwedge, 𝔾, ☆, antireverse, antidot, ⟇ |
| `applyConstant`, `applyMap`: fix or map operand | ★, ∨★ ∨☆ ∧★ ∧☆, attitude, carrier, ∩ ∪ ⊞ ⊙ ⊡ |
| `filterGrades`: keep one grade of product | ∙, as grade 0 of ∨★ |
| Transwedge sum: wedge chains over one grade | ⟑ |

Each anti side is the conjugate of its base side, so the anti side needs no second
construction. Two constructors stay direct: `constructReverse`, and `constructParts`. The weight
part is the conjugate of the bulk part under the rigid metric only.

A cell of `Cayley1D` is `seq[BasisSigned]`, not `Option`. One cell shape then serves both table
orders, and a map of several terms needs no second path. The cost is heap use at compile time
only.

## Why

- **Completeness.** Each compound operator of the book gets one table: `∩ ∪ ⊞ ⊙ ⊡`. At pin,
  each is a chain of dense products at run time.
- **Simplicity.** Four constructors go: `constructDual`, `constructMetricExomorphismAnti`, the
  anti path of `constructProductExterior`, and the dual overload of `constructProductInterior`.
- **Consistency.** Every anti side comes from one rule, and every interior product is one dual
  fed into one product.

## Transwedge

The build keeps one transwedge family, for ⟑ alone; ⟇ is its conjugate. Order k sums, over the
bases 𝐜 of grade k, the wedge of 𝐚 and 𝐛 with 𝐜 stripped from each.

The transwedge has 32 variants. Three choices matter: which product strips, which dual strips
𝐛, and whether the two complements are on opposed sides. Chirality changes nothing at any of
five algebras, and grade order against antigrade order is a relabel. So eight families stay at
even dimension, and four at odd dimension, where the complements are equal.

| # | Strips | Dual | Complements | Order 0 | Equal grades | Order gr 𝐚 | Signed sum |
|---|--------|------|-------------|---------|--------------|------------|------------|
| 1 | ∨ | ★ | opposed | ∧ | ∙ | 𝐛 ∨ 𝐚★ | ⟑ |
| 2 | ∨ | ★ | same side | ∧ | ∙, signs differ | 𝐚★ ∨ 𝐛 | ⟑, antigrade sign |
| 3 | ∨ | ☆ | opposed | 0 | weight on 𝟏 | 𝐛 ∨ 𝐚☆ | no unit |
| 4 | ∨ | ☆ | same side | 0 | weight, signs differ | 𝐚☆ ∨ 𝐛 | no unit |
| 5 | ∧ | ☆ | opposed | ∨ | ∘ | 𝐛 ∧ 𝐚☆ | ⟇ |
| 6 | ∧ | ☆ | same side | ∨ | ∘, signs differ | 𝐚☆ ∧ 𝐛 | ⟇, grade sign |
| 7 | ∧ | ★ | opposed | 0 | bulk on 𝟙 | 𝐛 ∧ 𝐚★ | no unit |
| 8 | ∧ | ★ | same side | 0 | bulk, signs differ | 𝐚★ ∧ 𝐛 | no unit |

Rows 5 to 8 count order by antigrade. Order 0 is zero under the rigid metric only. Under the
conformal metric 𝔾 = −𝐆, so family 3 is −1 and family 7 is −5.

Family 1 alone gives wedge, dot, geometric product and bulk contraction, so the build keeps it.
The other products are cheaper as maps or conjugates. The identity at order gr 𝐚 stays as a
suite, so the build and the transwedge cannot drift apart.

## Grade restriction

A typed operand names its bases, and the emitter reads only those cells of the whole table.
The tables stay whole, so the table count does not grow with the number of types. Proposal P02,
`typed-multivectors`, builds on this.

The alternative filters a copy of each table for each pair of operand types. One copy of a 2D
table costs 0.1 MB at 4D, 0.35 MB at 5D and 0.9 MB at 6D. About eight types and thirty binary
operators give some 1 900 tables, or about 1.7 GB of front-end memory at 6D. So the 1D
`filterGrades` goes, since nothing calls it. The 2D one stays, because it defines the dot.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Four dual products from transwedge | Built, tables equal; four N³ families where maps cost N² |
| Left and right chirality | Census at five algebras; tables identical |
| Dot from equal-grade transwedge cells | Built, equal; needs transwedge for what filter gives |
| Dot as scalar part of ⟑ | Checked; equal only up to (−1)^(k(k−1)/2) |
| Blade products by bit operations | Weighed; second generator, against three tables |
| `Option` cells in `Cayley1D` | Library at pin; two cell shapes, and no sum of terms |
| Shared operand as table operation | Built; drops cross cells, since it is binding, `as_unary` |
| Separate `CAYLEYS_NORM_SQUARED` | Library at pin; equal to dot, cell for cell |

## Open decisions

- Adopt the derivation into the library, before the typed layer. It changes no exported name.
- Keep `constructParts` direct on both sides, or conjugate it under the rigid metric only.
- Decide whether the left-dual forms, such as 𝐚★ ∨ 𝐛, belong in the library. Neither the book
  nor the library defines them.
