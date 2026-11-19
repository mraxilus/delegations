# P14: Add and subtract any basis-set types

**What it is.** `+` and `-` take two multivectors of any basis-set types, or a scalar beside a
multivector of any type, and negation takes any type. Two operands of one type keep that type.
Two types give the exact union of their bases, as the named type with exactly those bases where
one exists. Each body writes one assignment for each basis at compile time, so no set is read at
run time.

**What it is for.** At pin, `+` takes two operands of one type, and `-` and each sum with a
scalar take whole multivectors alone. So a caller widens a vector and a bivector to add them, and
widens a line to negate it. On the JS backend, `+` of whole multivectors also copies its set of
bases at each call.

**What it costs.** A sum of two types can take a type that no alias names, as a scalar and a
vector at rga4d take a type of 5 bases. The library exports `zeroNamed`, which names each result
type.

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
- **Bodies.** `emitCombinedByBasis` writes one assignment for each basis of the union, at a
  constant basis. A basis that one operand lacks reads as zero. `emitNegatedByBasis` writes each
  negation the same way.
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
named type with the fewest bases, and add the sums with a scalar. At rga4d,
`Multivector1 + Multivector2` returns `MultivectorOf[{E1, E2, E3, E4, E41, ..., E12}]`, of 10
bases. `MultivectorOf[{E1}] + Multivector1` returns `Multivector1`.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Named type with the fewest bases that holds both | The Architect ruled the exact union |
| Loop over the set, as at pin | It reads the set at run time, and copies it on JS |
| No sum of two types | A caller widens both operands, then narrows the result |
| Sums with a scalar for `Multivector` alone | Each routine takes every instance (IV.8) |

## Costs

- **Unnamed results.** A sum of two types takes the union of their bases, which no alias may
  name. So a scalar and a vector at rga4d add to a type of 5 coefficients, and a compiler message
  prints that type with its bases.
- **Export.** `pga/multivectors.nim` exports `zeroNamed`, since the patch of D1 reads its result
  types through it.
- **Overloads.** `+` and `-` of two whole multivectors, and each sum with a scalar, become
  instances of the generic forms. Each body writes one assignment for each basis, as the loop of
  pin does.

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

No evaluation of this text stands yet, so no figure of time or build stands here.
