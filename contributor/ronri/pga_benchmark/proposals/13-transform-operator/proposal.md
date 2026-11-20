# P13: One operator for the transform of a multivector, built from the types of its operands

**What it is.** `m ⟇⟇~∘ n` transforms 𝐦 by the operator 𝐧, that is 𝐧 ⟇ 𝐦 ⟇ 𝐧̰. Its typed form builds
the table of that sandwich from the types of both operands, when the code compiles. So each value
of each type transforms exactly, and the result takes the bases that the table reaches. Two full
multivectors take the three steps of pin. The alias `transform` of `pga.nim` reads the operator.

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

- **Table from types.** `constructSandwich` expands 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ term by term. It walks the bases
  of the type of 𝐦, and the pairs of bases of the type of 𝐧. It reads `CAYLEYS_WEDGE_DOT.anti` and
  `CAYLEYS_REVERSE.anti`, so the table follows the metric and the orientation of the library. It
  runs when the code compiles, for each pair of types that a caller passes. So a motor type reads
  its antieven pairs alone, and a flector type its antiodd pairs. The operator is then correct for
  each value of each type that it takes (IV.8), as the Architect ruled (D49 f).
- **Pairs.** The coefficients of 𝐧 commute, so the terms of 𝐧ᵢ𝐧ⱼ and 𝐧ⱼ𝐧ᵢ merge into one pair.
  A pair of two bases sums both orders, which comes out even in each of the nine algebras. Its
  product reads 2𝐧ᵢ, as 𝐧ᵢ + 𝐧ᵢ, so each term of the rigid table weighs ±1.
- **Result type.** The result takes the bases that the table reaches, through `zeroNamed` of P14.
  So a motor transforms a vector to a vector, and a full multivector to a full one.
- **Full operands.** `Multivector` is the instance of `MultivectorOf` over every basis, so two
  full multivectors take a function of their own. It spells the three steps of pin. A table over
  every pair spends 204 multiplies and 607 adds at rga4d, which is more adds than the chain. A
  typed 𝐦 by a full 𝐧 takes the table of both types, which the open decision names.
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
  chain for nine pairs of types, and its type to the bases that the chain reaches. The table and
  the chain sum their terms in other orders, so they agree within the tolerance of `=~` alone.
  The other test holds two full multivectors to the chain exactly, and the alias to the operator.

Each cell gives multiplies, and adds with subtractions, for a full 𝐦 and a motor type 𝐧. The
chain is counted from its two tables, and the operator as the evaluation reads its C:

| Algebra | Chain | This proposal | Reference, point | Time of transforms, of pin |
|---------|-------|---------------|------------------|----------------------------|
| rga3d | 96 and 80 | 23 and 23 | 14 and 10 | ×0.27 |
| rga4d | 384 and 352 | 82 and 167 | 35 and 40 | ×0.28 |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Antieven pairs for any 𝐧 | A reflection operator transforms each multivector to zero (D49 f) |
| Every pair for full operands | 204 multiplies and 607 adds at rga4d, more adds than the chain |
| Chain as one function | Closes D08, but spends what the chain spends |
| A pair counted twice | 105 adds more at rga4d, one for each of 112 doubled terms, less 7 |

## Costs

- **Build of a call.** Each pair of types builds its table once in the virtual machine of the
  compiler, the first time a program calls it. At cga6d a full multivector by a motor type adds
  4.7 s to the build of a program. It also adds 35 MiB to the peak of the compiler. At rga4d it
  adds 0.06 s, inside the spread of the builds.
- **Build of `import pga`.** It builds no table. In the evaluation, it takes 10.43 s at cga6d
  against 9.91 s at pin, with P04 and P14 under it. At cga5d it peaks at 210.5 MiB, as at pin.
- **Size.** At rga4d the function holds 82 lines of C, inline in each caller.
- **Dimensions.** The adds grow faster than the multiplies. For a full 𝐦 by a motor type, the
  table spends 408 multiplies and 2 191 adds at cga5d, against 2 048 and 1 984 of the chain. At
  rga6d it spends 1 192 and 8 927 against 6 144 and 6 016, and at cga6d 1 584 and 16 479 against
  8 192 and 8 064.

## Open decisions

The Architect ruled D48 a, D49 f and D50 a on
[the list of decisions (#921)](https://github.com/mraxilus/delegations/issues/921). One decision
waits on [the typed transform of P13 (#990)](https://github.com/mraxilus/delegations/pull/990).

- **A typed 𝐦 by a full 𝐧.** D49 f says that a whole multivector takes the three steps of pin.
  This text reads it as two full operands, so a typed 𝐦 by a full 𝐧 takes the table of both
  types. At rga4d a vector by a full 𝐧 then spends 112 multiplies and 156 adds, against 384 and
  352 of the chain. All bases but the scalar spend 202 multiplies and 595 adds, which is more
  adds than the chain.

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
  the motor reads the typed pool of motors, so the measurands time and count this table. The
  catalogue holds transforms under the rigid metric alone. So when the pin moves to a library
  with this proposal, the conformal catalogue needs a measurand of `⟇⟇~∘` and `transform`. Else
  the suites that hold its symbols and aliases to the exports fail at cga4d and cga5d. At rga3d
  and rga4d the suites of this project pass against it.

## Evidence

`laws.nim` holds the operator equal to the chain on 256 seeded samples of ten pairs of types, at
each of the nine algebras. The pairs take a full multivector by a motor part, a flector part and
a vector. They take a vector, a bivector and a motor part by a motor part, and a vector by a
vector. They take a vector and a motor part by a full multivector, and two full multivectors.

The laws also hold the type of each result to the bases that the chain reaches, and the alias
equal to the chain. Five count claims hold the multiplies of each transform measurand: 82 at rga4d
and 23 at rga3d. The operator spends no zero fill, intermediate or error check there.

Its evaluation of 2026-11-20 times the transforms at ×0.28 of pin at rga4d, 19.9 ns against 71.6
to 71.7 ns. At rga3d they take ×0.27, 4.8 ns against 17.9 ns. The other measurands read ×0.95 to
×1.08. The suites pass at the four algebras, with the two tests of this proposal.

The counts of the chain, of the other algebras and of the forms that lost come from scripts that
read the tables of pin. The build of one call is the median of four builds of a program with the
call, against four without it. The scripts are not committed, so these figures are assumed until
a claim holds them.
