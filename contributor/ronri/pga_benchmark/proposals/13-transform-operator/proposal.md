# P13: One operator for the transform of a multivector, built from the types of its operands

**What it is.** `m ⟇⟇~∘ n` transforms 𝐦 by 𝐧 in one call: the sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, which pin spells
in three steps. Its typed form builds the table of that sandwich from the types of both operands,
when the code compiles. So each value of each type transforms exactly, and the result takes the
bases that the table reaches. A full operator takes the three steps of pin, whatever the type of
𝐦 is. The alias `transform` of `pga.nim` reads the operator.

**What it is for.** At pin a transform spells three steps, two antiproducts and an antireverse,
which is gap cause D08. With this proposal the transform by a motor type is one function. At
rga4d it spends 82 multiplies and 110 adds and subtractions, where the chain spends 384 and 352.
Each transform there then runs at ×0.26 of pin. A typed point or plane, and each typed object at
rga3d, spends the multiplies and adds of Lengyel's code. A typed line spends one multiply and 13
adds more.

**What it costs.** Each pair of types builds its table when a program first calls it, so
`import pga` builds none. At cga6d a full multivector by a motor type adds about 4 s to the build
of a program. There the table of a motor spends more adds than the chain, though far fewer
multiplies.

## Problem

The library has no operator for a transform. So the catalogue spells each transform by motor as
`((n ⟇ m) ⟇ (~∘ n))`, and the gap list names the five transform measurands under D08. Each step
writes a whole multivector, and the next step reads it. Each antiproduct reads every pair of
bases, though a motor holds the antieven bases alone.

At rga4d the reference transforms a point in 35 multiplies, a line in 52 and a plane in 35. The
chain spends 384 on each, and runs 100 to 125 ns against 10.5 to 16 ns of the reference, in the
runtime baselines.

## Idea

- **Table from types.** `constructSandwich` expands 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ term by term, from
  `CAYLEYS_WEDGE_DOT.anti` and `CAYLEYS_REVERSE.anti`. So the table follows the metric and the
  orientation of the library. It walks the bases of the type of 𝐦, and the pairs of bases of the
  type of 𝐧, when the code compiles. So a motor type reads its antieven pairs alone, and a flector
  type its antiodd pairs. The operator is then correct for each value of each type that it takes
  (IV.8), as the Architect ruled (D49 f).
- **Pairs.** The coefficients of 𝐧 commute, so the terms of 𝐧ᵢ𝐧ⱼ and 𝐧ⱼ𝐧ᵢ merge into one pair.
  A pair of two bases sums both orders, which comes out even in each of the nine algebras. Its
  product reads one of its bases doubled, so each term of the rigid table weighs ±1.
- **Result type.** The result takes the bases that the table reaches, through `zeroNamed` of P14.
  So a motor transforms a vector to a vector, and a full multivector to a full one.
- **Full operator.** `Multivector` is the instance of `MultivectorOf` over every basis. So a full
  𝐧 takes a function of its own, generic in 𝐦 alone, which Nim picks over the form of two types.
  It spells the three steps of pin for each type of 𝐦, as the Architect ruled (D1 b). A table
  over every pair spends 204 multiplies and 607 adds at rga4d, which is more adds than the chain.
  Code that needs speed types both the object and the operator.
- **Body.** A macro names the product of each pair once. A cross pair reads one of its bases
  doubled. The macro doubles the basis that most cross pairs hold, then the next, until each cross
  pair holds a doubled basis. So a motor doubles four bases at rga4d, where the first basis of
  each pair gave seven. Then the macro writes each coefficient of the result as a sum over the
  bases of 𝐦, through `emitBasis` and `emitSum` of P04. The operator carries `inline` and
  `noinit`, as each form of P04 does. It stands in the typed section of `pga/operators.nim`, and
  edits no table of `pga/cayleys.nim`.
- **Entries.** In a coefficient, the factor of a basis of 𝐦 is an entry, a signed sum of products
  of pairs. Where several coefficients read one entry, up to its sign, the macro names it once. So
  the rotation that moves both the direction and the moment of a line is computed once, as
  Lengyel computes his matrix R once. The macro finds equal entries term by term, among the
  entries of one first pair. So its loops walk terms, pairs or the entries of one first pair, and
  the table of a full 𝐦 by a motor type builds at cga6d inside the loop bound of the compiler.
- **Symbol.** The compound operators of `pga.nim` join their steps outer first, as `∨∧★` stands
  for 𝐧 ∨ (𝐦 ∧ 𝐧★). So `⟇⟇~∘` stands for 𝐧 ⟇ (𝐦 ⟇ 𝐧̰), as the Architect ruled on 2026-11-15.
  Nim 2.4.0 reads `⟇`, `~` and `∘` as characters of one operator.
- **Alias.** `transform(m, n)` reads `m ⟇⟇~∘ n`, as the Architect ruled (D50 a). Its row joins the
  compound operators of the header of `pga.nim`.
- **Tests.** Two tests join the suite `Typed operators` of P04. One holds the operator near the
  chain for seven pairs of typed operators, and its type to the bases that the chain reaches. The
  table and the chain sum their terms in other orders, so they agree within the tolerance of `=~`
  alone. The other test holds a full, a vector and an even 𝐦 by a full operator to the chain
  exactly. It also holds the type of that result to full, and the alias to the operator.

Each cell gives multiplies, and adds with subtractions, for a full 𝐦 by a motor type. The chain
is counted from its two tables, and the operator as the evaluation reads its C:

| Algebra | Chain | This proposal | Reference, point | Time of transforms, of pin |
|---------|-------|---------------|------------------|----------------------------|
| rga3d | 96 and 80 | 23 and 16 | 14 and 10 | ×0.28 |
| rga4d | 384 and 352 | 82 and 110 | 35 and 40 | ×0.26 |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Antieven pairs for any 𝐧 | A reflection operator transforms each multivector to zero (D49 f) |
| Every pair for full operands | 204 multiplies and 607 adds at rga4d, more adds than the chain |
| Table for a typed 𝐦 by a full 𝐧 | Code that needs speed types its operator (D1 b) |
| Chain as one function | Closes D08, but spends what the chain spends |
| A pair counted twice | 72 adds more at rga4d, one for each of 76 reads of a cross pair, less 4 |
| First basis of each pair doubled | Seven doubled bases at rga4d: 3 adds more per typed object |
| Each entry where it is read | 15 adds more for a typed line at rga4d, and 54 for a full 𝐦 |
| Balanced sum of each entry | Point and plane at ×0.98 of Lengyel, but line at ×1.22 (D2) |
| Shared sums of two terms | Line and point: 57 and 36 adds, at ×1.20 and ×1.09 of Lengyel |
| Line through quaternion 𝐤 | Lengyel's form for one object, which no rule of the table gives (D3) |

## Costs

- **Build of a call.** Each pair of types builds its table once in the virtual machine of the
  compiler, the first time a program calls it. At cga6d a full multivector by a motor type adds
  4.2 s to the build of a program. It also adds 29 MiB to the peak of the compiler. At rga4d it
  adds 0.02 s, inside the spread of the builds.
- **Build of `import pga`.** It builds no table. In the evaluation, it takes 14.81 s at cga6d
  against 14.38 s at pin, with P04 and P14 under it. At cga5d it peaks at 210.3 MiB, against
  210.2 MiB at pin.
- **Size.** At rga4d the function holds 96 lines of C, inline in each caller.
- **Dimensions.** The adds grow faster than the multiplies. For a full 𝐦 by a motor type at
  cga5d, the table spends 408 multiplies and 1 223 adds. The chain spends 2 048 and 1 984 there.
  At rga6d the table spends 1 192 and 5 672, against 6 144 and 6 016 of the chain. At cga6d it
  spends 1 584 and 8 751, against 8 192 and 8 064.

## Open decisions

Three decisions wait on [the gap of the table to Lengyel
(#1015)](https://github.com/mraxilus/delegations/issues/1015):

- **D1.** The rule that doubles the basis of most cross pairs moves how gcc packs products into
  vectors. So two pairs run at ×1.04 of the old rule: a circle by a motor at cga4d, and a grade-4
  object by a flector at rga5d. Shared entries alone keep none of the gains on Lengyel's
  transforms. So the choice is to accept the two pairs (a), or to keep the old rule until a cover
  that keeps the packing is found (b).
- **D2.** An entry summed as a balanced tree brings the point and the plane to ×0.98 of Lengyel's
  time. It moves the line to ×1.22 from ×1.18. So the choice is sums in order (a), as now, or
  balanced sums (b).
- **D3.** The line at rga4d spends 13 adds more than Lengyel's, and runs at ×1.18 of his time.
  His form computes the moment through quaternion 𝐤, which the table cannot read off. A form
  by hand for one object is what the ruling on #1015 keeps out. So the choice is to close #1015
  with the gap recorded here (a), or to keep it open for a rule that reads part of the table as
  the chain (b).

The Architect ruled D48 a, D49 f and D50 a on
[the list of decisions (#921)](https://github.com/mraxilus/delegations/issues/921). The Architect
ruled D1 b on [the typed transform of P13 (#990)](https://github.com/mraxilus/delegations/pull/990),
so a full operator takes the chain, whatever the type of 𝐦 is.

## Landing

- **P04, `basis-set-forms`.** This proposal builds on it. Its operator stands beside the forms of
  P04, reads their helpers, and names its result through `zeroNamed` of P14. Every edit quotes
  text of pin as P04 leaves it.
- **P01, `cayley-derivation`.** It replaces `pga/cayleys.nim` whole, and keeps
  `CAYLEYS_WEDGE_DOT`, `CAYLEYS_REVERSE` and the fields of each term. This proposal edits no line
  of that file, so either order applies.
- **P12, `cayley-cells`.** It gives each cell a fixed array, and keeps `items` over it.
  `constructSandwich` reads each cell through `items`, so either order applies.
- **P09, `object-names`.** It names `Motor` at rga4d, a basis-set type of the antieven bases. So
  `transform(p, motor)` reads the table of this proposal at the type `Motor`.
- **Change `doc-comments`.** It writes in the header of `pga.nim` that `pga/operators.nim` holds
  two macros. P04 adds three, and this proposal one. It also moves the four rows of the
  projections out of the table of that header. This proposal adds its row after the last of them,
  so whichever of the two lands second quotes the other.
- **This project.** The catalogue spells each transform as `(m ⟇⟇~∘ n)` where the library
  declares the operator, and as the chain at pin. Where the operator takes a motor at its type,
  the motor reads the typed pool of motors, so the measurands time and count this table. Against
  the library of this proposal, the suites of this project pass at rga3d and rga4d. At cga4d and
  cga5d, the suites that hold its symbols and aliases to the exports fail. The catalogue holds
  transforms under the rigid metric alone, so its conformal part then needs a measurand of `⟇⟇~∘`
  and `transform`.

## Evidence

`laws.nim` holds the operator equal to the chain on 256 seeded samples of ten pairs of types, at
each of the nine algebras. The pairs take a full multivector by a motor part, a flector part and
a vector. They take a vector, a bivector and a motor part by a motor part, and a vector by a
vector. They take a vector, a motor part and a full multivector by a full multivector.

The laws also hold the type of each result to the bases that the chain reaches, and the alias
equal to the chain. By a full multivector, they hold the result to the chain bit for bit, and its
type to full. Ten count claims hold the multiplies and the adds of each transform measurand: 82
and 83 at rga4d, and 23 and 14 at rga3d. The operator spends no zero fill, intermediate or error
check there.

Its evaluation of 2026-11-26 times the transforms at ×0.26 of pin at rga4d, 25.0 to 25.1 ns
against 96.3 to 97.1 ns. At rga3d they take ×0.28, 6.2 ns against 22.4 to 23.1 ns. The other
measurands read ×0.97 to ×1.06. The highest, `dual_weight` at rga4d, reads the C of pin, so the
run moved it. The suites pass at the four algebras, with the two tests of this proposal.

A typed object by a typed motor reads the table of its own two types. Lengyel's reference holds
five such transforms:

| Algebra | Object | Table: multiplies, adds | Lengyel: multiplies, adds | Time against Lengyel |
|---|---|---|---|---|
| rga4d | point | 35, 40 | 35, 40 | ×1.08, ×1.09 |
| rga4d | line | 53, 67 | 52, 54 | ×1.18, ×1.19 |
| rga4d | plane | 35, 40 | 35, 40 | ×1.00, ×1.00 |
| rga3d | point | 14, 10 | 14, 10 | ×0.96, ×0.96 |
| rga3d | line | 14, 10 | 14, 10 | ×1.00, ×1.00 |

Each count reads the C of the table. Each pair ran twice, with seven passes in a copy of the
timed loop of `measurements.nim`. Each ratio is the time of the table against the time of
Lengyel's code in the same run. Before the two rules, these ratios read ×1.07 to ×1.08, ×1.23,
×1.05 to ×1.14, ×1.03 and ×1.02.

The same loop timed 76 pairs of types at the nine algebras, against the emitter before the two
rules. Their median reads ×0.98, and a full multivector by a flector at cga6d reads ×0.74. Two
pairs read ×1.04 in five or six of six runs (D1).

The counts of the chain, of the other algebras and of the forms that lost come from scripts that
read the tables of pin. The build of one call is the median of four builds of a program with the
call, against four without it. The scripts are not committed, so these figures are assumed until
a claim holds them.
