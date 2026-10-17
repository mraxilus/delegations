# P01: Derive every Cayley table from the metric and the orientation of 𝟙

**What it is.** `pga/cayleys.nim` derives every table from two inputs, as in Lengyel's figure
2.16: the metric and the orientation of 𝟙. Fixed definitions and three rules build the rest. One
rule, the new `applyMap`, puts a map into one operand of a table.

**What it is for.** A reader follows one derivation that matches Lengyel's, with two constructors
fewer. `applyMap` also lets a later change fold a chain of operators into one table.

**What it costs.** It replaces `pga/cayleys.nim` whole, and it keeps two transwedge families.

## Problem

At pin, `constructAnti` gives the anti side of 𝐆, of the wedge and of the dot, by one rule. The
antireverse, the duals and the interior products each have a constructor of their own. Two notes
at pin ask for a derivation instead: the interior products derive from base operators, and the
dot filters a grade of bulk contraction. Nothing at pin states which tables are inputs, where
Lengyel names two in his figure 2.16.

## Idea

Every table derives from two inputs, as in Lengyel's figure 2.16: the metric and the orientation
of the volume element 𝟙. The metric enters as 𝖌 on vectors, and the exomorphism builds 𝐆 from it.
RGA makes 𝐞ₙ null. CGA pairs 𝐞ₙ₋₁ and 𝐞ₙ with 𝐞ₙ₋₁ ∙ 𝐞ₙ = −1, and names one of them origin and
the other infinity. The right complement of the origin, 𝐞̄ₙ in RGA and 𝐞̄ₙ₋₁ in CGA, is the horizon,
which the attitude reads. The parts split by these projective vectors in both algebras.

![Derivation map, after Lengyel's figure 2.16, in eleven blocks in the order of the code, where
each box holds a symbol. Green boxes are the two inputs, grey boxes are basis and projective
elements, and purple anti tables stand under their blue tables. Dashed boxes on the top row of a
block bring in boxes from other blocks, and each block builds downward. A dot marks where lines
join, and a line that crosses another line with no dot passes over it. Each line carries its
formula, with the function that builds the table under it. A faded line is a route that the code
does not take, and a faded box is an operator with no table. Brown text holds in RGA alone, and
blue text in CGA alone.](../../pages/derivation-map.svg)

The figure shows RGA alone, and it predates the transwedge, by which Lengyel later unified the
geometric product. The map adds both, and it names the code that builds each table. It takes the
dot 𝐚 ∙ 𝐛 = 𝐚 ⩓ₖ 𝐛 where k = gr 𝐚 = gr 𝐛 from the transwedge, as at pin. So one product gives ∧ at
order 0, ∙ at equal grades, and ⟑ as a signed sum of its orders. A suite holds that this dot
equals the 𝐚ᵀ𝐆𝐛 of the figure, which the map gives as a faded route.

The blocks follow the groups of the code, from bases to properties. The last three blocks hold
the measures, the projections and the motion operators. A box draws only the inputs that it cannot
reach through another input, so ∨ also stands for the ∧ that it derives from. The faded lines give
every other route to a box that holds at pin. So the dot has three routes: from ⩓ₖ, which the code
takes, from 𝐚 ∨ 𝐛★ at equal grades, and from 𝐆. The faded boxes give the operators with no table,
such as the support, the distance and the flector, so the map shows how complete the library is.

P01 lays out every Cayley table of the library, so most other proposals build on it. They count
only the tables that the library builds, and they take a new table into account when the library
adds it.

### Against Lengyel's figure 2.16

| Table | Figure 2.16 | This proposal |
|-------|-------------|---------------|
| 𝐆 | input | from 𝖌, by 𝐆(𝐚 ∧ 𝐛) = 𝐆𝐚 ∧ 𝐆𝐛 |
| 𝟙 | input, by its orientation | 𝟙 = 𝐞₁ ∧ 𝐞₂ ∧ ⋯ ∧ 𝐞ₙ, the antiscalar basis |
| ∧ | fixed | 𝐞ᵢ ∧ 𝐞ⱼ = −𝐞ⱼ ∧ 𝐞ᵢ, by `multiplyExterior` on basis factors |
| Complements | from ∧ and 𝟙 | same, as 𝐮̱ ∧ 𝐮 = 𝟙 = 𝐮 ∧ 𝐮̄ |
| Reverse | from ∧, sign by grade | same sign (−1)^(k(k−1)/2) where k = gr 𝐮, by grade alone |
| 𝔾, ∨, ∘, antireverse | conjugate by complements | `constructAnti`: 𝐚 ∨ 𝐛 = 𝐮̱ where 𝐮 = 𝐚̄ ∧ 𝐛̄ |
| Duals | complement of 𝐆𝐮 or 𝔾𝐮 | same, `applyMap` |
| Transwedge | absent | 𝐚 ⩓ₖ 𝐛 = Σ (𝐜̱ ∨ 𝐚) ∧ (𝐛 ∨ 𝐜★) where gr 𝐜 = k |
| ∙ | 𝐚ᵀ𝐆𝐛 | 𝐚 ⩓ₖ 𝐛 where k = gr 𝐚 = gr 𝐛, as a suite holds equal to 𝐚ᵀ𝐆𝐛 |
| ⟑ | from 𝐆 and ∧ | 𝐚 ⟑ 𝐛 = Σ (−1)^(k(k−1)/2) 𝐚 ⩓ₖ 𝐛 |
| ⟇ | conjugate of ⟑ | 𝐚 ⟇ 𝐛 = Σ (−1)^(k(k−1)/2) 𝐚 ⩔ₖ 𝐛, not conjugates of base orders in CGA |
| Norms | √(𝐮 ∙ 𝐮) and √(𝐮 ∘ 𝐮) | ‖𝐮‖●² = 𝐮●ᵀ𝐮● as for each part, and ‖𝐮‖⊘² = 𝐮 ∘ 𝐮 in CGA |
| Projective vectors | absent | split the parts, and give the horizon and the CGA carrier |

### Three rules

| Rule | Tables it builds |
|------|------------------|
| `constructAnti`: conjugate by complements, 𝐚 ∨ 𝐛 = 𝐮̱ where 𝐮 = 𝐚̄ ∧ 𝐛̄ | ∨, 𝔾, antireverse, ∘ |
| `applyConstant`, `applyMap`: fix or map operand | ★, ☆, 𝐚 ∨ 𝐛★ and each interior product, ⊖, ⊟ |
| Transwedge sum: Σ where gr 𝐜 = k | ⩓ₖ and ⩔ₖ, ∙ at equal grades, ⟑ and ⟇ by signed sums |

Each dual is a complement after 𝐆 or 𝔾, on the left or on the right, as the library keeps both
sides. Each interior product is one dual fed into one product, by one rule. The squared radius
norm is the table of ∘ itself, so it needs no filter, and `filterGrades` leaves the file.

Direct constructors remain for the base reverse, for 𝐆 from 𝖌, for the parts and for the squared
norms. `constructDot` keeps the cells of 𝐚 ⩓ₖ 𝐛 where k = gr 𝐚 = gr 𝐛 holds. The antireverse is
`constructAnti` of the reverse, so `constructReverse` and `reverse` lose their `Spatiality`
parameter. `constructParts` splits each part by the presence of the projective vectors. The origin
splits bulk from weight, and in CGA infinity splits round from flat. In RGA, 𝐆 and 𝔾 give the same
parts, but one rule holds in both algebras.

### Tables that change

The table below gives the new rule of each derived table that changes. In it, `s` is `base` or
`anti`, and `side` is `left` or `right`, as a field and as a chirality.

| Table | Rule |
|-------|------|
| `CAYLEYS_REVERSE.anti` | `CAYLEYS_REVERSE.base.constructAnti(CAYLEYS_COMPLEMENT)` |
| `CAYLEYS_DUAL.s.side` | `CAYLEYS_COMPLEMENT.side.applyMap(CAYLEYS_EXOMORPHISM_METRIC.s)` |
| `CAYLEYS_INTERIOR.s.bulk.side` | `CAYLEYS_WEDGE.s.applyMap(CAYLEYS_DUAL.base.side, side)` |
| `CAYLEYS_INTERIOR.s.weight.side` | `CAYLEYS_WEDGE.s.applyMap(CAYLEYS_DUAL.anti.side, side)` |
| `CAYLEYS_DOT.base` | `constructDot(CAYLEYS_WEDGES_TRANS.base)` |
| `CAYLEY_ATTITUDE` | `CAYLEYS_WEDGE.anti`, with `applyConstant` of `Basis.horizon` on the right |
| `CAYLEYS_NORM_SQUARED_RADIUS` | `CAYLEYS_DOT.anti` |

### Cells of one term

A cell of `Cayley1D` is `seq[BasisSigned]` at pin, and the emitter sums the terms of a cell. Each
map that these rules build holds at most one term in a cell, so the emitter stays as at pin.
`slice` keeps its assertion of one term, so a map of two terms stops the build. `applyMap` and
`merge` both call `mergeTerm`, so `std/sequtils` leaves the imports.

### Transwedge

Order k of the transwedge, 𝐚 ⩓ₖ 𝐛, sums one term for each basis 𝐜 where gr 𝐜 = k. The term strips 𝐜
from 𝐚 by its complement and from 𝐛 by its dual, and then joins the two results.

The transwedge has 32 variants. Three choices matter: which product strips, which dual strips 𝐛,
and whether the two complements are on opposed sides. Chirality changes no table, and grade order
against antigrade order is a relabel. So eight families stay at even dimension, and four at odd
dimension, where the complements are equal.

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

Family 1 is 𝐚 ⩓ₖ 𝐛, and it gives wedge, dot, geometric product and bulk contraction. Family 5 is
the antitranswedge 𝐚 ⩔ₖ 𝐛, which gives ⟇. The build takes the dot from family 1 at equal grades,
and the contraction as a map. A suite holds the identity at order gr 𝐚, so the build and the
transwedge cannot drift apart. The same suite holds that the dot equals 𝐚ᵀ𝐆𝐛.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Four dual products from transwedge | Built, tables equal; four N³ families where maps cost N² |
| Left and right chirality | Tables identical in the census by hand |
| Dot as scalar part of ⟑ | Checked; equal only up to (−1)^(k(k−1)/2) |
| Blade products by bit operations | Weighed; second generator beside the derivation |
| Dot as 𝐚ᵀ𝐆𝐛 from 𝐆, as in figure 2.16 | Built, equal; ruled on 2026-10-17 for the transwedge |
| Dot as grade 0 of 𝐚 ∨ 𝐛★, as a pin note asks | Built, equal; ruled on 2026-10-17 for transwedge |
| Radius norm by `filterGrades` of ∘ | Removes no cell; ruled on 2026-10-17 to read ∘ whole |
| RGA parts as 𝐆 and 𝔾 | Built, equal; ruled on 2026-10-16 for one rule in both algebras |
| `Option` cells in `Cayley1D` | Library before `3121342`; two cell shapes, and no sum of terms |
| ⟇ as conjugate of ⟑, one family | Built; equal sum, but anti orders differ at cga4d and cga5d |
| Drop `CAYLEYS_NORM_SQUARED` | Built from parts at pin; outside this idea, so it stays |

## Costs

- **Whole file.** The change replaces `pga/cayleys.nim` whole, from the digest `4aa7a2507c537c06`
  of the file at pin. So each change of that file at head needs the replacement written again.
- **Two transwedge families.** The library keeps one family for ⟑ and one for ⟇. Under the
  conformal metric, an order of the anti family is not the conjugate of that order of the base
  family.
- **No gain at run time.** Every exported name, type, table and cell stays as at pin. So no
  operator changes, none runs faster, and no caller must migrate.
- **Private functions.** The removed and changed functions are private. `pga/operators.nim` and
  the modules of this project that import `cayleys {.all.}` call none of them.

## Open decisions

- Adopt the derivation into the library, before the typed layer, or not.

## Landing

- **P08, `compound-tables`.** It quotes a line of the header of this file and reads `applyMap`,
  so it lands after this proposal. Its support, antisupport, cocarrier, center and container follow
  the carrier, so they join the group of properties.
- **Change `cayleys-hygiene`.** It renames an overload of `constructProductInterior`, which this
  proposal deletes, so its edits are void once this proposal lands. Its other idea still applies,
  because this proposal writes the parity k(k−1)/2 of the reverse twice, in `reverse` and in
  `constructProductGeometric`.
- **Changes `doc-comments` and `doc-comments-2`.** Each edits `pga/cayleys.nim` too, and whichever
  lands second quotes again against the first. If this proposal lands second, its Replace carries
  their text under a new digest. `doc-comments-2` also edits the import line of `tests/suites.nim`
  that this proposal edits, so the second to land quotes that line again.
- **Edit that `doc-comments` drops.** Once this proposal lands, `doc-comments` drops its edit that
  quotes `  CAYLEYS_DOT* = block:`. Applied after this proposal, that edit gives a line of 136
  characters with two docs that contradict each other. This proposal gives the dot its doc on that
  line already.

## Evidence

A check by hand on 2026-10-17 builds each faded route of the map at rga3d, rga4d, cga4d and
cga5d. Each route gives the table that it leads to, and the two brown routes hold in RGA alone.

A census by hand on 2026-10-12 checks chirality and the family count at nine algebras: rga2d to
rga6d, and cga3d to cga6d. It calls `constructProductsTransitional` with each strip product, dual,
chirality and side of each complement. At each of the nine, its tables agree with the families
and the chirality that Idea states.
