# P13: One operator for the transform of a multivector, built from the types of its operands

**What it is.** `m ⟇⟇~∘ n` transforms 𝐦 by 𝐧 in one call: the sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, which pin spells
in three steps. Its typed form builds the table of that sandwich from the types of both operands,
when the code compiles. So each value of each type transforms exactly, and the result takes the
bases that the table reaches. A full operator takes the three steps of pin, whatever the type of
𝐦 is. The alias `transform` of `pga.nim` reads the operator.

**What it is for.** At pin a transform spells three steps, two antiproducts and an antireverse,
which is gap cause D08. With this proposal the transform by a motor type is one function. At
rga4d it spends 82 multiplies and 167 adds and subtractions, where the chain spends 384 and 352.
Each transform there then runs at ×0.28 of pin.

**What it costs.** Each pair of types builds its table when a program first calls it, so
`import pga` builds none. At cga6d a full multivector by a motor type adds about 5 s to the build
of a program. From cga5d up, the table of a motor spends more adds than the chain, though far
fewer multiplies.

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
  product reads 2𝐧ᵢ, as 𝐧ᵢ + 𝐧ᵢ, so each term of the rigid table weighs ±1.
- **Result type.** The result takes the bases that the table reaches, through `zeroNamed` of P14.
  So a motor transforms a vector to a vector, and a full multivector to a full one.
- **Full operator.** `Multivector` is the instance of `MultivectorOf` over every basis. So a full
  𝐧 takes a function of its own, generic in 𝐦 alone, which Nim picks over the form of two types.
  It spells the three steps of pin for each type of 𝐦, as the Architect ruled (D1 b). A table
  over every pair spends 204 multiplies and 607 adds at rga4d, which is more adds than the chain.
  Code that needs speed types both the object and the operator.
- **Body.** A macro names the doubled basis and the product of each pair once. Then it writes each
  coefficient of the result as a sum over the bases of 𝐦, through `emitBasis` and `emitSum` of
  P04. Each of its loops walks each term once, so a table over every pair builds at six
  dimensions inside the loop bound of the compiler. The operator carries `inline` and `noinit`, as
  each form of P04 does. It stands in the typed section of `pga/operators.nim`, and edits no table
  of `pga/cayleys.nim`.
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
| rga3d | 96 and 80 | 23 and 23 | 14 and 10 | ×0.27 |
| rga4d | 384 and 352 | 82 and 167 | 35 and 40 | ×0.28 |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Antieven pairs for any 𝐧 | A reflection operator transforms each multivector to zero (D49 f) |
| Every pair for full operands | 204 multiplies and 607 adds at rga4d, more adds than the chain |
| Table for a typed 𝐦 by a full 𝐧 | Code that needs speed types its operator (D1 b) |
| Chain as one function | Closes D08, but spends what the chain spends |
| A pair counted twice | 105 adds more at rga4d, one for each of 112 doubled terms, less 7 |

## Costs

- **Build of a call.** Each pair of types builds its table once in the virtual machine of the
  compiler, the first time a program calls it. At cga6d a full multivector by a motor type adds
  4.7 s to the build of a program. It also adds 35 MiB to the peak of the compiler. At rga4d it
  adds 0.06 s, inside the spread of the builds.
- **Build of `import pga`.** It builds no table. In the evaluation, it takes 11.02 s at cga6d
  against 10.67 s at pin, with P04 and P14 under it. At cga5d it peaks at 210.3 MiB, against
  210.2 MiB at pin.
- **Size.** At rga4d the function holds 82 lines of C, inline in each caller.
- **Dimensions.** The adds grow faster than the multiplies. For a full 𝐦 by a motor type at
  cga5d, the table spends 408 multiplies and 2 191 adds. The chain spends 2 048 and 1 984 there.
  At rga6d the table spends 1 192 and 8 927, against 6 144 and 6 016 of the chain. At cga6d it
  spends 1 584 and 16 479, against 8 192 and 8 064.

## Open decisions

None. The Architect ruled D48 a, D49 f and D50 a on
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
type to full. Five count claims hold the multiplies of each transform measurand: 82 at rga4d
and 23 at rga3d. The operator spends no zero fill, intermediate or error check there.

Its evaluation of 2026-11-20 times the transforms at ×0.28 of pin at rga4d, 19.9 ns against 71.6
to 71.7 ns. At rga3d they take ×0.27, 4.8 ns against 17.9 ns. The other measurands read ×0.95 to
×1.08. The suites pass at the four algebras, with the two tests of this proposal.

The counts of the chain, of the other algebras and of the forms that lost come from scripts that
read the tables of pin. The build of one call is the median of four builds of a program with the
call, against four without it. The scripts are not committed, so these figures are assumed until
a claim holds them.
