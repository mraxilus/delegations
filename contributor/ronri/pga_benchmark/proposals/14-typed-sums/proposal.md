# P14: Add and subtract any basis-set types

**What it is.** `+` and `-` take two multivectors of any basis-set types, or a scalar beside a
multivector of any type, and negation takes any type. Two operands of one type keep that type.
Two types give the exact union of their bases, as the named type with exactly those bases where
one exists. Each body writes one loop for each run of consecutive bases, at constant bounds, so no
set is read at run time.

**What it is for.** At pin, `+` takes two operands of one type, and `-` and each sum with a
scalar take whole multivectors alone. So a caller widens a vector and a bivector to add them, and
widens a line to negate it. On the JS backend, `+` of whole multivectors also copies its set of
bases at each call.

**What it costs.** A sum of two types can take a type that no alias names, as a scalar and a
vector at rga4d take a type of 5 bases. The library exports `zeroNamed`, which names each result
type. In the bench, a sum of whole multivectors at rga4d takes ×1.02 of the time at pin.

## Problem

At pin the library declares `+` for two operands of one basis-set type, and `-` for `Multivector`
alone. Each sum and difference with a scalar takes a `Multivector` alone too. A product of P04
returns the exact bases that it reaches, so its results are often of two types. To add a vector
and a bivector, a caller converts each to `Multivector` first. Then it narrows the sum back.

The body of `+` at pin loops over every basis, and tests the set of the type for each one. On the
JS backend, each call of `+` on whole multivectors also copies that set through `nimCopy`.
pga_visualiser traced to this `+` the growth of the copies of its lattice at `3d9696e`. It counted
356 725 copies over 9 frames there, against 340 767 at `295bafc`.

## Idea

- **Result type.** One type keeps itself. Two types give the exact union of their bases, as each
  product of P04 returns the bases that it reaches. The Architect ruled the exact union on
  2026-11-17, in place of the named type with the fewest bases that holds both.
- **Names.** `zeroNamed[R]()` gives the zero of the named type whose bases are `R`. Where no named
  type has them, it gives `MultivectorOf[R]`, with `R` built again in the order of the bases. Nim
  compares two static sets as each is written, so equal sets then give one type.
- **Bodies.** `emitCombinedByRun` writes one loop for each run of consecutive bases of the union,
  at constant bounds. Each operand holds each basis of a run alike, so a basis that one operand
  lacks reads as zero. `emitNegatedByRun` writes each negation the same way. The Architect ruled
  the loop on 2026-11-19, on
  [the order of the work (#959)](https://github.com/mraxilus/delegations/issues/959).
- **Signatures.** `+` and `-` of two operands take `MultivectorOf[A]` and `MultivectorOf[B]`, and
  negation takes `MultivectorOf[B]`. Each sum and difference with a scalar takes
  `MultivectorOf[B]`, and reads the scalar as a value of the type of the scalar basis alone. So
  each routine here takes every instance of `MultivectorOf`, as the rule that a routine is
  correct for each value of each type that it takes asks (IV.8).
- **Tests.** The tests stand in a new suite `Arithmetic` of the library. They hold the type, the
  bases and each coefficient of each sum and difference, on 512 samples. One test holds that two
  operands give one type in either order.

The edits start from
[the patch of D3](https://github.com/mraxilus/delegations/pull/702#issuecomment-6611854105) of
pga_visualiser, as it applies to pin through `git am`. They take the exact union in place of its
named type with the fewest bases, and a loop for each run in place of its line for each basis.
They also add the sums with a scalar. At rga4d, `Multivector1 + Multivector2` returns
`MultivectorOf[{E1, E2, E3, E4, E41, ..., E12}]`, of 10 bases. `MultivectorOf[{E1}] + Multivector1`
returns `Multivector1`.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Named type with the fewest bases that holds both | The Architect ruled the exact union |
| Loop over the set, as at pin | It reads the set at run time, and copies it on JS |
| One line for each basis, as the patch of D3 | A register spills at cga5d, and alone it is scalar |
| No sum of two types | A caller widens both operands, then narrows the result |
| Sums with a scalar for `Multivector` alone | Each routine takes every instance (IV.8) |

## Costs

- **Unnamed results.** A sum of two types takes the union of their bases, which no alias may
  name. So a scalar and a vector at rga4d add to a type of 5 coefficients, and a compiler message
  prints that type with its bases.
- **Export.** `pga/multivectors.nim` exports `zeroNamed`, since the patch of D1 reads its result
  types through it.
- **Build.** In the evaluation, `import pga` at cga5d peaks at 210.5 MiB against 210.3 MiB at pin.
  At cga6d it takes 13.48 s against 13.76 s, so ×0.98.
- **Sum at rga4d.** In the bench, `+` of whole multivectors reads ×1.02 of pin at rga4d, about
  0.08 ns. Its loop holds the same 8 vector sums as the code of pin, and takes them in turn on
  three registers. The cause of the 0.08 ns is not isolated.
- **Overloads.** `+` and `-` of two whole multivectors, and each sum with a scalar, become
  instances of the generic forms. Each body loops over each run of bases, as pin loops over the
  set.

## Open decisions

None. The Architect ruled the exact union of two types (D53 b) and the export of `zeroNamed`
(D54 a), on [the list of decisions (#921)](https://github.com/mraxilus/delegations/issues/921).

## Landing

- **P04, `basis-set-forms`.** It edits the type of `pga/multivectors.nim`, and this proposal edits
  its arithmetic. The code of the patch of D1, which P04 takes (D51 b), reads `zeroNamed`. So P04
  builds on this proposal.
- **P01, P10 and P11.** They edit `tests/suites.nim` elsewhere. This proposal adds its suite after
  the last suite of pin, which no other edit quotes.
- **Change `code-reordering-drop`.** It drops the pragma `codeReordering` from
  `pga/multivectors.nim`. This proposal places each routine after each routine that it reads, so
  either order holds.
- **This project.** `copies.nim` builds for Node through the field `backend` of a program claim.

## Evidence

`laws.nim` holds each sum, difference and negation of every pair of named types, at each of the
nine algebras. It also holds each sum and difference of a scalar and each named type. It reads
each coefficient against the coefficients of the operands, and each type against the rule. Where
a named type has exactly the bases of a result, the result must take that type. A copy whose sum
takes the named type with the fewest bases that holds both fails it at rga4d.

`copies.nim` counts each `nimCopy` call that an operation adds to the assignment of its result,
on Node. With the change, no operation adds one at rga3d, rga4d, cga4d and cga5d. There it holds
136, 171, 171 and 210 operations. At pin it fails at each of those algebras on `Multivector +`,
one copy for each call, and on no other operation.

Its evaluation of 2026-11-19 finds three functions moved at each algebra: `+`, `-` and negation
of whole multivectors. At rga4d each holds 16 lines of C and no call, against 132 to 183 lines and
32 to 48 calls at pin. There `+` zeroes no byte before it writes, where pin zeroes 128. At rga4d
the three read ×1.00 of pin, and the other 108 measurands read ×0.98 to ×1.01. At cga5d sums and
differences read ×1.00 to ×1.01, and the other 132 measurands read ×0.98 to ×1.05. Negation there
reads ×1.58, as Costs gives.

One line for each basis costs time in two ways, which a loop for each run avoids. In the timed loop
at cga5d, the compiler loads all 16 vectors of a negation before it stores any, and keeps the sign
mask too. SSE2 has 16 registers, so one value spills to the stack for each object. Alone, across a
boundary that the optimiser cannot see through, each line compiles to scalar code. There the loop
of pin and the loop for each run compile to vector code. A check that the result and the operand
do not overlap guards that code.

Runs by hand on 2026-11-19 give these medians of paired ratios against pin. They ran on
`linux amd64, 4 cores`, a Xeon of family 6 model 207, with Nim `14991af`, gcc 13.3.0 and
`-d:release`. Each bench take is 41 alternating runs, and each take alone is 21.

| Measure | Algebra | One line for each basis | Loop for each run |
|---------|---------|------------------------:|------------------:|
| Negation in the bench | cga5d | ×1.58, ×1.59 | ×1.00, ×0.99 |
| Negation alone | cga5d | ×1.27, ×1.31 | ×1.00, ×1.00 |
| Sum alone | cga5d | ×1.30, ×1.42 | ×1.00, ×1.00 |
| Difference alone | cga5d | ×1.30, ×1.40 | ×1.00, ×1.00 |
| Negation alone | rga4d | ×1.27, ×1.27 | ×1.00, ×1.00 |
| Sum and difference alone | rga4d | ×1.20, ×1.20 | ×1.00, ×1.00 |

The same line for each basis read ×1.13 of pin for negation at cga5d on 2026-11-15, on a host of the
same model. So the size of the cost of the spill varies with the host, and the spill does not.
