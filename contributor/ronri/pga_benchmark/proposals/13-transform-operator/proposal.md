# P13: One operator for the transform of a multivector, built from the types of its operands

**What it is.** `m ⟇⟇~∘ n` transforms 𝐦 by 𝐧 in one call: the sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, which pin spells
in three steps. Its typed form builds the terms of that sandwich from the types of both operands,
when the code compiles. So each value of each type transforms exactly, and the result takes the
bases that the terms reach. A full operator takes the three steps of pin, whatever the type of
𝐦 is. The alias `transform` of `pga.nim` reads the operator.

**What it is for.** At pin a transform spells three steps, two antiproducts and an antireverse,
which is gap cause D08. With this proposal the transform by a motor type is one function. At
rga4d it spends ⟦82 multiplies and 113 adds and subtractions⟧, where the chain spends 384 and
352. Each transform there then runs at ⟦×0.27⟧ of pin. A typed point and line at rga3d spend the
multiplies and adds of Lengyel's code. At rga4d a typed point and plane spend his multiplies and 3
adds more, and a line 1 multiply and 16 adds more.

**What it costs.** Each pair of types builds its sum when a program first calls it, so
`import pga` builds none. The macro writes out two orders of each sum, and keeps the order of
fewer operations. At cga6d a full multivector by a motor type then adds ⟦about 5 s⟧ to the build
of a program. The macro holds ⟦150⟧ lines of Nim.

## Problem

The library has no operator for a transform. So the catalogue spells each transform by motor as
`((n ⟇ m) ⟇ (~∘ n))`. The gap list names the five transform measurands under D08. Each step
writes a whole multivector, and the next step reads it. Each antiproduct reads every pair of
bases, though a motor holds the antieven bases alone.

At rga4d the reference transforms a point in 35 multiplies, a line in 52 and a plane in 35. The
chain spends 384 on each, and runs 100 to 125 ns against 10.5 to 16 ns of the reference, in the
runtime baselines.

## Idea

- **Terms from types.** `constructSandwich` expands 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ term by term, from
  `CAYLEYS_WEDGE_DOT.anti` and `CAYLEYS_REVERSE.anti`. So each term follows the metric and the
  orientation of the library. It walks the bases of the type of 𝐦, and the pairs of bases of the
  type of 𝐧, when the code compiles. So a motor type reads its antieven pairs alone, and a flector
  type its antiodd pairs. The operator is then correct for each value of each type that it takes
  (IV.8), as the Architect ruled (D49 f).
- **Pairs.** The coefficients of 𝐧 commute, so the terms of 𝐧ᵢ𝐧ⱼ and 𝐧ⱼ𝐧ᵢ merge into one pair.
  A pair of two bases sums both orders, which comes out even in each of the nine algebras. Its
  product reads one of its bases doubled, so each term of a rigid sum weighs ±1.
- **Result type.** The result takes the bases that the terms reach, through `zeroNamed` of P14.
  So a motor transforms a vector to a vector, and a full multivector to a full one.
- **Full operator.** `Multivector` is the instance of `MultivectorOf` over every basis. So a full
  𝐧 takes a function of its own, generic in 𝐦 alone, which Nim picks over the form of two types.
  It spells the three steps of pin for each type of 𝐦, as the Architect ruled (D1 b on #990). A
  sum over every pair spends 204 multiplies and 607 adds at rga4d, which is more adds than the
  chain. Code that needs speed types both the object and the operator.
- **Two orders.** Each coefficient of the result is one sum of terms ±𝐧ᵢ𝐦ₖ𝐧ⱼ. The sum has two
  orders: multiply 𝐧 by 𝐧 first, or 𝐧 by 𝐦 first. The macro writes out both, counts the
  multiplies, adds and subtractions of each, and keeps the order of fewer. A tie keeps the matrix.
  The count reads the Cayley tables alone, so the choice reads no time and holds on every
  machine. So no order is written by hand for one object or one algebra, as the Architect ruled
  (D1 a on #1056).
- **Matrix.** It multiplies 𝐧 by 𝐧 first. It names the product of each pair once, and a cross
  pair reads its second basis doubled, so each basis doubles once at most. In a coefficient, the
  factor of a basis of 𝐦 is an entry, a signed sum of products of pairs. The coefficient sums
  each entry times its basis of 𝐦. The matrix pays one multiply for each entry, so it wins where
  𝐦 holds few bases.
- **Entries.** Where an entry holds more than one term, the macro names it once, up to its sign.
  So two coefficients that read one entry compute it once, as Lengyel computes his matrix once.
  The count then reads what the C computes, since the compiler merges no named entry again. The
  macro finds an entry by its terms, written as one string with its first term positive.
- **Chain.** It multiplies 𝐧 by 𝐦 first: 𝐭 = 𝐧 ⟇ 𝐦, then 𝐭 ⟇ 𝐧̰. It spells both antiproducts
  from `CAYLEYS_WEDGE_DOT.anti`, as `emitMultipliedByBasis` of P04 spells one. 𝐭 holds only the
  bases that some coefficient of the result reads, and the sign of the antireverse folds into
  each term. One 𝐭 serves each coefficient, so the chain wins where 𝐦 holds many bases. It reads
  each cross pair twice, so it loses where 𝐦 holds few.
- **Place.** The operator carries `inline` and `noinit`, as each form of P04 does. It stands in
  the typed section of `pga/operators.nim`, and edits no table of `pga/cayleys.nim`. Each order
  is a function of its own, beside `emitSum` and `emitBasis` of P04, and the macro calls both.
- **Symbol.** The compound operators of `pga.nim` join their steps outer first, as `∨∧★` stands
  for 𝐧 ∨ (𝐦 ∧ 𝐧★). So `⟇⟇~∘` stands for 𝐧 ⟇ (𝐦 ⟇ 𝐧̰), as the Architect ruled on 2026-11-15.
  Nim 2.4.0 reads `⟇`, `~` and `∘` as characters of one operator.
- **Alias.** `transform(m, n)` reads `m ⟇⟇~∘ n`, as the Architect ruled (D50 a). Its row joins the
  compound operators of the header of `pga.nim`.
- **Tests.** Two tests join the suite `Typed operators` of P04. One holds the operator near the
  chain for seven pairs of typed operators, and its type to the bases that the chain reaches. The
  operator and the chain sum their terms in other orders, so they agree within the tolerance of
  `=~` alone. The other test holds a full, a vector and an even 𝐦 by a full operator to the chain
  exactly. It also holds the type of that result to full, and the alias to the operator.

Each cell gives multiplies, and adds with subtractions, for a full 𝐦 by a motor type. The chain
is counted from its two tables, and the operator as the evaluation reads its C:

| Algebra | Chain | This proposal | Reference, point | Time of transforms, of pin |
|---------|-------|---------------|------------------|----------------------------|
| rga3d | 96 and 80 | ⟦23 and 16⟧ | 14 and 10 | ⟦×0.27⟧ |
| rga4d | 384 and 352 | ⟦82 and 113⟧ | 35 and 40 | ⟦×0.27⟧ |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Antieven pairs for any 𝐧 | A reflection operator transforms each multivector to zero (D49 f) |
| Every pair for full operands | 204 multiplies and 607 adds at rga4d, more adds than the chain |
| Sum for a typed 𝐦 by a full 𝐧 | Code that needs speed types its operator (D1 b on #990) |
| Chain as one function | Closes D08, but spends what the chain spends |
| A pair counted twice | 72 adds more at rga4d, one for each of 76 reads of a cross pair, less 4 |
| First basis of each pair doubled | More operations on 21 of 130 pairs of types, fewer on 1 |
| Each entry where it is read | Count reads more than the C, so a line at rga4d takes the chain |
| Matrix alone, or chain alone | Each is more than ×1.9 of the faster order on some pair of types |
| Three forms of 2026-11-27 | Five rules where two orders serve, tails ⟦×1.33 and ×1.63⟧ (D1 a) |
| Cross form or chain | Three of the five rules, and a line at rga4d of 52 and 52 (D1 a on #1056) |
| Weight folded first | Same counts, but bulk comes first by convention (D1 a of 2026-11-27) |
| Choice by time | It reads one machine, which the goal of the library keeps out |
| Count weighted by cycles | It reads the cores of some machines, and moves 1 choice of 148 |
| Shared sums of two terms | The compiler fails its loop bound at six dimensions (D1 a on #1056) |
| Line through quaternion 𝐤 | Lengyel's form for one object, which no rule of the tables gives |

## Costs

- **Build of a call.** Each pair of types builds both orders once in the virtual machine of the
  compiler, the first time a program calls it. At cga6d a full multivector by a motor type adds
  ⟦5.3 s⟧ to the build of a program, and ⟦122 MiB⟧ to the peak of the compiler. At rga4d the call
  moves the build by less than the spread of the builds.
- **Build of `import pga`.** It builds no sum. In the evaluation, it takes ⟦12.75 s⟧ at cga6d
  against ⟦11.84 s⟧ at pin, with P04 and P14 under it. At cga5d it peaks at ⟦210.3 MiB⟧, against
  ⟦210.2 MiB⟧ at pin.
- **Size.** At rga4d the function holds ⟦96⟧ lines of C, inline in each caller. The macro holds
  ⟦150⟧ lines of Nim, and runs only when the code compiles.
- **Lengyel's five.** The two orders spend more adds than three of the transforms of Lengyel's
  reference. A point and a plane at rga4d spend 3 adds more, and a line 1 multiply and 16 adds
  more. So [the gap of P13's table to Lengyel
  (#1015)](https://github.com/mraxilus/delegations/issues/1015) stays open, as the Architect ruled
  (D1 a on #1056).
- **Dimensions.** The matrix grows with the entries of 𝐦, and the chain with 𝐭, so the chain
  wins at more dimensions. For a full 𝐦 by a motor type, the macro keeps the matrix at cga5d:
  464 multiplies and 1 167 adds, against 2 048 and 1 984 of the chain at pin. At rga6d it keeps
  the chain: 3 072 and 2 944, against 6 144 and 6 016. At cga6d it keeps the chain: 4 096 and
  3 968, against 8 192 and 8 064.

## Open decisions

None. The Architect ruled D1 a on [the transform of P13 by two orders
(#1056)](https://github.com/mraxilus/delegations/pull/1056) on 2026-11-28. The macro writes out
two orders and keeps the order of fewer operations, so #1015 stays open. The Architect also asked
that the macro follow the style of the pga library, and that one example show each step from the
macro to the assembly. The Evidence below holds that example.

The rulings of 2026-11-26 and 2026-11-27 on #1056 chose a cover of doubled bases, sums in order,
the bulk folded first and the fewest of three forms. D1 a of 2026-11-28 replaces each of them.

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
  `constructSandwich` and the chain read each cell through `items`, so either order applies.
- **P09, `object-names`.** It names `Motor` at rga4d, a basis-set type of the antieven bases. So
  `transform(p, motor)` reads the sum of this proposal at the type `Motor`.
- **Change `doc-comments`.** It writes in the header of `pga.nim` that `pga/operators.nim` holds
  two macros. P04 adds three, and this proposal one. It also moves the four rows of the
  projections out of the table of that header. This proposal adds its row after the last of them,
  so whichever of the two lands second quotes the other.
- **This project.** The catalogue spells each transform as `(m ⟇⟇~∘ n)` where the library
  declares the operator, and as the chain at pin. Where the operator takes a motor at its type,
  the motor reads the typed pool of motors, so the measurands time and count this sum. Against
  the library of this proposal, the suites of this project pass at rga3d and rga4d. At cga4d and
  cga5d, the suites that hold its symbols and aliases to the exports fail. The catalogue holds
  transforms under the rigid metric alone, so its conformal part then needs a measurand of `⟇⟇~∘`
  and `transform`.

## Evidence

⟦EVIDENCE⟧
