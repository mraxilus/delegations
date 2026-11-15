# P13: One operator for the transform of a multivector by a motion operator

**What it is.** `m ⟇⟇~∘ n` transforms 𝐦 by the motion operator 𝐧, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, as one
generated function. Its table `CAYLEY_TRANSFORM` holds that sandwich as a map that is quadratic in
the antieven coefficients of 𝐧. The alias `transform` of `pga.nim` reads the operator.

**What it is for.** At pin a transform spells three steps, two antiproducts and an antireverse,
which is gap cause D08. With this proposal it is one function. At rga4d it spends 82 multiplies
and 167 adds and subtractions, where the chain spends 384 and 352. Each transform there then runs
at ×0.26 of pin.

**What it costs.** The operator reads the antieven part of 𝐧 alone, so a reflection operator
transforms every multivector to zero. The build of `import pga` at cga6d takes ×1.44 of the time
at pin in the evaluation.

## Problem

The library has no operator for a transform. So the catalogue spells each transform by motor as
`((n ⟇ m) ⟇ (~∘ n))`, and the gap list names the five transform measurands under D08. Each step
writes a whole multivector, and the next step reads it. Each antiproduct reads every pair of
bases, though the motion operator holds the antieven bases alone.

At rga4d the reference transforms a point in 35 multiplies, a line in 52 and a plane in 35. The
chain spends 384 on each, and runs 100 to 125 ns against 10.5 to 16 ns of the reference, in the
runtime baselines.

## Idea

- **Table.** `constructSandwich` of `pga/cayleys.nim` expands 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ term by term. It reads
  `CAYLEYS_WEDGE_DOT.anti` and `CAYLEYS_REVERSE.anti`, so the table follows the metric and the
  orientation of the library. Each term is a coefficient times 𝐧ᵢ𝐧ⱼ𝐦ₖ, where i and j are
  antieven bases.
- **Pairs.** The coefficients of 𝐧 commute, so the terms of 𝐧ᵢ𝐧ⱼ and 𝐧ⱼ𝐧ᵢ merge into one pair.
  A pair of two bases sums both orders, which comes out even in each of the nine algebras. Its
  product reads 2𝐧ᵢ, as 𝐧ᵢ + 𝐧ᵢ, so each term of the rigid table weighs ±1.
- **Operator.** A third `defineOperator` takes the table. It names the product of each pair once,
  then writes each coefficient of the result as a sum over the bases of 𝐦. The operator carries
  `inline` and `noinit`, as each generated operator does.
- **Symbol.** The compound operators of `pga.nim` join their steps outer first, as `∨∧★` stands
  for 𝐧 ∨ (𝐦 ∧ 𝐧★). So `⟇⟇~∘` stands for 𝐧 ⟇ (𝐦 ⟇ 𝐧̰), as the Architect ruled on 2026-11-15.
  Nim 2.4.0 reads `⟇`, `~` and `∘` as characters of one operator.
- **Alias.** `transform(m, n)` reads `m ⟇⟇~∘ n`, and its row joins the compound operators of the
  header of `pga.nim`.
- **Contract.** The operator equals the chain for each motion operator, i.e. each antieven
  element. For any other 𝐧 it equals the chain of the antieven part of 𝐧.

Each cell gives multiplies, and adds with subtractions. The chain is counted from its two tables,
and the operator as the evaluation reads its C:

| Algebra | Chain | This proposal | Reference, point | Time of transforms, of pin |
|---------|-------|---------------|------------------|----------------------------|
| rga3d | 96 and 80 | 23 and 23 | 14 and 10 | ×0.27 |
| rga4d | 384 and 352 | 82 and 167 | 35 and 40 | ×0.26 |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Pairs of one parity | Exact for reflection operators too, at 108 multiplies, 352 adds at rga4d |
| Every pair | Exact for any 𝐧, but 204 multiplies and more adds than the chain at rga4d |
| Chain as one function | Closes D08, but spends what the chain spends |
| A pair counted twice | 105 adds more at rga4d, one for each of 112 doubled terms, less 7 |

## Costs

- **Reflection operators.** The table reads the antieven part of 𝐧 alone. A reflection operator,
  such as a flector, holds the antiodd part, so its transform is zero. Its sandwich stays the
  chain, or another operator, which an open decision names.
- **Build.** In the evaluation, `import pga` at cga6d takes 21.53 s against 14.99 s at pin. At
  cga5d it peaks at 261.4 MiB against 210.4 MiB, so ×1.24. Two build claims bound both, at ×1.6
  of the time and ×1.3 of the peak.
- **Size.** At rga4d the function holds 82 lines of C, inline in each caller. Its table at cga5d
  holds terms for 408 multiplies and at least 2 080 adds.
- **Dimensions.** The adds grow faster than the multiplies. At cga5d the chain spends 2 048 and
  1 984, so the table spends more adds and fewer multiplies. At rga6d the table spends 1 192 and
  8 928 against 6 144 and 6 016, and at cga6d 1 584 and 15 776 against 8 192 and 8 064.

## Open decisions

- Read the antieven part of 𝐧 alone, as here, or the pairs of one parity. The second form also
  transforms by each reflection operator, at 108 multiplies and 352 adds at rga4d.
- Name the alias `transform`, as the reference and the catalogue do, or `sandwich`, as the
  glossary entry of the motion operator does.

## Landing

- **P01, `cayley-derivation`.** It replaces `pga/cayleys.nim` whole. So whichever lands second
  writes the type, the table and `constructSandwich` again, against the text of the other.
- **P12, `cayley-cells`.** It rewrites the type block of the cells, and this proposal adds a type
  section after the containers, so either order applies. `constructSandwich` reads each cell
  through `items`, which P12 keeps.
- **P04, `basis-set-forms`.** It rewrites the alias of `expandWeight`, which this proposal quotes.
  Where P04 lands first, this proposal quotes its text. A form of P04 could also take the
  grade of 𝐦, and so reach the counts of the reference, 14 at rga3d.
- **Change `doc-comments`.** It writes in the header of `pga.nim` that `pga/operators.nim` holds
  two macros. With this proposal it holds three, so whichever of the two lands second writes
  three.
- **Change `imports-narrow`.** It names each symbol that `pga/operators.nim` imports from
  `cayleys`. Whichever of the two lands second adds `CayleySandwich` and `CAYLEY_TRANSFORM`.
- **This project.** The catalogue spells each transform as `(m ⟇⟇~∘ n)` where the library
  declares the operator, and as the chain at pin. So the measurands time and count it. The
  catalogue holds transforms under the rigid metric alone. So when the pin moves to a library
  with this proposal, the conformal catalogue needs a measurand of `⟇⟇~∘` and `transform`. Else
  the suites that hold its symbols and aliases to the exports fail at cga4d and cga5d.

## Evidence

`laws.nim` holds the operator equal to the chain for 256 seeded motion operators at each of the
nine algebras. It also holds it equal to the chain of the antieven part of a dense 𝐧, and the
alias equal to the operator. Five count claims hold the multiplies of each transform measurand: 82
at rga4d and 23 at rga3d. The operator spends no zero fill, intermediate or error check there.

Its evaluation of 2026-11-15 times the transforms at ×0.26 of pin at rga4d, 27.1 to 33.3 ns
against 119.0 to 127.7 ns. At rga3d they take ×0.27, 7.2 to 7.5 ns against 21.6 to 22.0 ns. The
other measurands read ×0.94 to ×1.09, and the suites pass at the four algebras as at pin.

The counts of the chain and of the forms that lost come from scripts that read the tables of pin.
The scripts are not committed, so these counts are assumed until a claim holds them.
