# P13: One operator for the transform of a multivector, built from the types of its operands

**What it is.** `m ⟇⟇~∘ n` transforms 𝐦 by 𝐧 in one call: the sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, which pin spells
in three steps. Its typed form builds the table of that sandwich from the types of both operands,
when the code compiles. So each value of each type transforms exactly, and the result takes the
bases that the table reaches. A full operator takes the three steps of pin, whatever the type of
𝐦 is. The alias `transform` of `pga.nim` reads the operator.

**What it is for.** At pin a transform spells three steps, two antiproducts and an antireverse,
which is gap cause D08. With this proposal the transform by a motor type is one function. At
rga4d it spends 82 multiplies and 110 adds and subtractions, where the chain spends 384 and 352.
Each transform there then runs at ×0.27 of pin. A typed point, line or plane at rga4d, and the
typed point and line at rga3d, spend the multiplies of Lengyel's code. They spend his adds too,
except the line at rga4d, which spends one add fewer.

**What it costs.** Each pair of types builds its table when a program first calls it, so
`import pga` builds none. The macro builds two forms of each table and counts a third, then keeps
the form of fewest operations. At cga6d a full multivector by a motor type then adds about 5 s to
the build of a program. The macro holds 226 lines of Nim.

## Problem

The library has no operator for a transform. So the catalogue spells each transform by motor as
`((n ⟇ m) ⟇ (~∘ n))`. The gap list names the five transform measurands under D08. Each step
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
  It spells the three steps of pin for each type of 𝐦, as the Architect ruled (D1 b on #990). A
  table over every pair spends 204 multiplies and 607 adds at rga4d, which is more adds than the
  chain. Code that needs speed types both the object and the operator.
- **Three forms.** A macro weighs three forms of each typed transform. It builds the table form
  and the cross form, and counts the chain. It keeps the form of fewest multiplies, adds and
  subtractions. A tie keeps the earlier form: the table form, then the cross form. It counts each
  form from the Cayley tables alone, so the choice reads no time and holds on every machine. So no
  form is written by hand for one object or one algebra, as [the gap of the table to Lengyel
  (#1015)](https://github.com/mraxilus/delegations/issues/1015) asks.
- **Table form.** The macro names the product of each pair once. A cross pair reads one of its
  bases doubled. The macro doubles the basis that most cross pairs hold, then the next, until each
  cross pair holds a doubled basis. So a motor doubles four bases at rga4d, where the first basis
  of each pair gave seven. Then the macro writes each coefficient of the result as a sum over the
  bases of 𝐦, through `emitBasis` and `emitSum` of P04.
- **Entries.** In a coefficient, the factor of a basis of 𝐦 is an entry, a signed sum of products
  of pairs. Where several coefficients read one entry, up to its sign, the macro names it once. So
  the rotation that moves both the direction and the moment of a line is computed once, as
  Lengyel computes his matrix R once. The macro finds equal entries term by term, among the
  entries of one first pair. So its loops walk terms, pairs or the entries of one first pair.
  The table of a full 𝐦 by a motor type then builds at cga6d inside the loop bound of the
  compiler.
- **Cross form.** The library parts each operator into its bulk and its weight. The cross form
  reads each pair of a bulk basis and a weight basis as a short chain. It multiplies the bulk
  basis by 𝐦 first, then that product by the weight basis. The bulk comes first, as the library
  declares it before the weight. The sum of such a pair stands for both of its orders, so the
  result adds it twice. The other pairs and the entries stay as the table form has them. So the
  line at rga4d spends 52 multiplies and 53 adds, against 53 and 67 of the table form.
- **Chain form.** It spells `(n ⟇ m) ⟇ (~∘ n)` through the typed antiproducts of P04. The macro
  counts it term by term from `CAYLEYS_WEDGE_DOT.anti`. It wins where both operands hold many
  bases. So a bivector by a motor at cga5d spends 416 multiplies and 384 adds, against 236 and 797
  of the table form.
- **Place.** The operator carries `inline` and `noinit`, as each form of P04 does. It stands in
  the typed section of `pga/operators.nim`, and edits no table of `pga/cayleys.nim`.
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
| rga3d | 96 and 80 | 23 and 16 | 14 and 10 | ×0.27 |
| rga4d | 384 and 352 | 82 and 110 | 35 and 40 | ×0.27 |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Antieven pairs for any 𝐧 | A reflection operator transforms each multivector to zero (D49 f) |
| Every pair for full operands | 204 multiplies and 607 adds at rga4d, more adds than the chain |
| Table for a typed 𝐦 by a full 𝐧 | Code that needs speed types its operator (D1 b on #990) |
| Chain as one function | Closes D08, but spends what the chain spends |
| A pair counted twice | 72 adds more at rga4d, one for each of 76 reads of a cross pair, less 4 |
| First basis of each pair doubled | Seven doubled bases at rga4d: 3 adds more per typed object |
| Each entry where it is read | 54 adds more for a full 𝐦 by a motor type at rga4d |
| Table form alone | The line at rga4d spends 53 multiplies and 67 adds, at ×1.18 of Lengyel |
| Table or cross form, no chain | Full 𝐦 by a motor at cga6d: 2 544 and 6 430, not 4 096 and 3 968 |
| Weight folded first | Same counts, but bulk comes first by convention. Line at ×1.23 of Lengyel |
| Choice by time | It reads one machine, which the goal of the library keeps out |
| Balanced sum of each entry | No count moves. Table form: point and plane at ×0.98, line at ×1.22 |
| Shared sums of two terms | Not one of the three forms. Table form: point 36 adds, line 57 (D1) |
| Line through quaternion 𝐤 | Lengyel's form for one object, which no rule of the tables gives |

## Costs

- **Build of a call.** Each pair of types builds its table once in the virtual machine of the
  compiler, the first time a program calls it. The macro builds the table form and the cross
  form, and counts the chain. At cga6d a full multivector by a motor type adds 5.3 s to the build
  of a program, and 122 MiB to the peak of the compiler. The table form alone adds 3.8 s and
  29 MiB there. At rga4d the call moves the build by less than the spread of the builds.
- **Build of `import pga`.** It builds no table. In the evaluation, it takes 12.75 s at cga6d
  against 11.84 s at pin, with P04 and P14 under it. Two takes of the same C read ×1.02 and
  ×1.08, so the spread of the builds holds the difference. At cga5d it peaks at 210.3 MiB, against
  210.2 MiB at pin.
- **Size.** At rga4d the function holds 96 lines of C, inline in each caller. The macro holds
  226 lines of Nim, and runs only when the code compiles.
- **Dimensions.** The adds of the table form grow faster than its multiplies, so the other forms
  win at more dimensions. For a full 𝐦 by a motor type at cga5d, the macro keeps the table form:
  408 multiplies and 1 223 adds, against 2 048 and 1 984 of the chain at pin. At rga6d it keeps
  the cross form: 1 704 and 2 567, against 6 144 and 6 016. At cga6d it keeps the chain of typed
  antiproducts: 4 096 and 3 968, against 8 192 and 8 064.

## Open decisions

One decision waits on [the rules of the table for the gap to Lengyel
(#1056)](https://github.com/mraxilus/delegations/pull/1056):

- **D1.** Shared sums of two terms name once the sum of two terms that most sums of the table
  hold, then the next, until no two terms repeat. On the table form, they bring the point at
  rga4d to 35 multiplies and 36 adds, 4 adds fewer than Lengyel's. The line takes 57 adds there,
  against 53 of the cross form. They are not one of the three forms that D1 c weighs, and their
  build at six dimensions is not measured. So the choice is to keep the three forms (a), or to
  weigh shared sums as a fourth form in an item of its own (b).

The Architect ruled four decisions on #1056. The rulings of 2026-11-26 keep the cover of doubled
bases, though two pairs of types read ×1.04 of the old cover under it (D1 a). Each entry sums its
terms in order (D2 a). The rulings of 2026-11-27 fold the bulk basis of a cross pair first, as
bulk comes first by convention. They also keep the fewest of the three forms (D1 c).

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
vector. They take a vector, a motor part and a full multivector by a full multivector. Across the
nine algebras they reach each form: a bivector by a motor part takes the table form at rga3d, the
cross form at rga4d and the chain at cga5d.

The laws also hold the type of each result to the bases that the chain reaches, and the alias
equal to the chain. By a full multivector, they hold the result to the chain bit for bit, and its
type to full. Ten count claims hold the multiplies and the adds of each transform measurand: 82
and 83 at rga4d, and 23 and 14 at rga3d. The operator spends no zero fill, intermediate or error
check there.

Its evaluation of 2026-11-27 times the transforms at ×0.27 of pin at rga4d, 23.1 to 23.2 ns
against 84.7 to 85.4 ns. At rga3d they take ×0.27, 5.8 ns against 24.0 to 26.2 ns. The other
measurands read ×0.93 to ×1.09. Each of them above ×1.05 reads the C of pin, so the run moved it.
The suites pass at the four algebras, with the two tests of this proposal.

A typed object by a typed motor reads the table of its own two types. Lengyel's reference holds
five such transforms. The line at rga4d takes the cross form. A motor there holds four bulk bases
and four weight bases. Each cross pair multiplies its bulk basis by the direction of the line
first, and the moment adds the sum twice:

```c
folded0 = fold_E23_E41 + fold_E31_E42 + fold_E12_E43;
crossed_E23 = folded0 * n[E41] + folded1 * n[E42] - folded2 * n[E43] + folded3 * n[E1234];
r[E23] = entry0 * m[E23] + entry1 * m[E31] + entry2 * m[E12] + crossed_E23 + crossed_E23;
```

The listing shortens the C. It drops the casts and the suffixes of the names, and writes each
negation as the sign of its term.

The five transforms read:

| Algebra | Object | Form | Operator: multiplies, adds | Lengyel: multiplies, adds | Of his time |
|---|---|---|---|---|---|
| rga4d | point | table | 35, 40 | 35, 40 | ×1.06 to ×1.10 |
| rga4d | line | cross | 52, 53 | 52, 54 | ×1.00 |
| rga4d | plane | table | 35, 40 | 35, 40 | ×1.00 to ×1.05 |
| rga3d | point | table | 14, 10 | 14, 10 | ×0.96 |
| rga3d | line | table | 14, 10 | 14, 10 | ×1.01 to ×1.08 |

Each count reads the C of the operator. Each pair ran four times on 2026-11-27, on the Xeon of
family 6 model 207, with seven passes in a copy of the timed loop of `measurements.nim`. Each ratio
is the time of the operator against the time of Lengyel's code in the same run. Before the rules of
#1015, these ratios read ×1.07 to ×1.08, ×1.23, ×1.05 to ×1.14, ×1.03 and ×1.02. The point stays
above ×1.05 of his time, though its counts equal his.

The same loop timed 148 pairs of types at the nine algebras on 2026-11-27, on the same machine: each
grade, the even part, the odd part and a full 𝐦, by a motor type and by a flector type. The macro
keeps the table form for 82, the cross form for 46 and the chain for 20. Against the table form
alone, the median reads ×0.99, and a full 𝐦 by a motor at rga6d reads ×0.32. Against the chain of
typed antiproducts, the median reads ×0.69.

The counts and the times disagree on two pairs. A line by a flector at rga4d reads ×1.09 of the
table form, though the cross form spends 15 operations fewer. A vector by a flector at cga3d reads
×1.07 of the chain, though the table form spends 8 fewer. This loop also moves a pair by up to
×1.21 in one run with no change of C, as a scalar by a motor at rga3d reads.

The counts of the chain, of the other algebras and of the forms that lost come from scripts that
read the tables of pin. The build of one call is the median of four builds of a program with the
call, against four without it. The scripts are not committed, so these figures are assumed until
a claim holds them. No claim holds the form that each pair keeps either. The laws hold each form
equal to the chain, but they pass whichever form the macro keeps. So the form and the counts of
each typed transform above are assumed too.
