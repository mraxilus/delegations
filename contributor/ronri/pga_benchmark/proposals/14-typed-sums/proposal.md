# P14: Add and subtract any two basis-set types

**What it is.** `+` and `-` take two multivectors of any basis-set types, and negation takes any
type. Two operands of one type keep that type. Two types give the named type with the fewest
bases that holds both, else `Multivector`. Each body writes one assignment for each basis at
compile time, so no set is read at run time.

**What it is for.** At pin, `+` takes two operands of one type, and `-` takes whole multivectors
alone. So a caller widens a vector and a bivector to add them, and widens a line to negate it.
On the JS backend, `+` of whole multivectors also copies its set of bases at each call.

**What it costs.** A sum of two types can hold more bases than their union, such as 16 for a
scalar and a vector at rga4d. The library exports `zeroNamed`, which names each result type.
Negation of a whole multivector at cga5d takes ×1.13 of the time at pin, for a cause not isolated.

## Problem

At pin the library declares `+` for two operands of one basis-set type, and `-` for `Multivector`
alone. A product of P04 returns the exact bases that it reaches, so its results are often of two
types. To add a vector and a bivector, a caller converts each to `Multivector` first. Then it
narrows the sum back.

The body of `+` at pin loops over every basis, and tests the set of the type for each one. On the
JS backend, each call of `+` on whole multivectors also copies that set through `nimCopy`.
pga_visualiser traced to this `+` the growth of the copies of its lattice at `3d9696e`. It counted
356 725 copies over 9 frames there, against 340 767 at `295bafc`.

## Idea

- **Result type.** `basesCombined` keeps the bases of two operands of one type. For two types it
  takes the named type with the fewest bases that holds both, else the whole set.
- **Names.** `zeroNamed[R]()` gives the zero of the named type whose bases are `R`. Where no named
  type has them, it gives `MultivectorOf[R]`, with `R` built again in the order of the bases. Nim
  compares two static sets as each is written, so equal sets then give one type.
- **Bodies.** `emitCombinedByBasis` writes one assignment for each basis of the result, at a
  constant basis. A basis that one operand lacks reads as zero. `emitNegatedByBasis` writes each
  negation the same way.
- **Signatures.** `+` and `-` of two operands take `MultivectorOf[A]` and `MultivectorOf[B]`, and
  negation takes `MultivectorOf[B]`. The sums and differences with a scalar stay as at pin.
- **Tests.** The four tests of the patch stand in a new suite `Arithmetic` of the library. They
  hold the type and each coefficient of a sum, a difference and a negation, on 512 samples.

The edits are
[the patch of D3](https://github.com/mraxilus/delegations/pull/702#issuecomment-6611854105) of
pga_visualiser, as it applies to pin through `git am`. At rga4d, `Multivector1 + Multivector2`
returns `Multivector`, and `MultivectorOf[{E1}] + Multivector1` returns `Multivector1`.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Exact union of the two sets | Open decision; the patch names a type instead |
| Loop over the set, as at pin | It reads the set at run time, and copies it on JS |
| No sum of two types | A caller widens both operands, then narrows the result |

## Costs

- **Width of a sum.** A sum of two types takes the smallest named type that holds both. So a
  scalar and a vector at rga4d add to `Multivector` of 16 coefficients, where their union holds 5.
  Each product of P04 returns its exact reach, so a sum of two of its results can be wider.
- **Export.** `pga/multivectors.nim` exports `zeroNamed`, since the patch of D1 reads its result
  types through it. Without that patch, only `+` and `-` read it.
- **Build.** In the evaluation, `import pga` at cga5d peaks at 210.5 MiB against 210.3 MiB at pin.
  At cga6d it takes 13.18 s against 13.43 s.
- **Negation at cga5d.** It reads ×1.13 of pin in the evaluation, and ×1.14 in an earlier take of
  the same day. At the other three algebras it reads ×0.98 to ×1.03. A function that negates
  alone compiles to the same 16 vector negations under pin and under this proposal. So the cause
  lies outside the body of negation, and is not isolated.
- **Overloads.** `-` of two whole multivectors becomes an instance of the generic form, as `+` is
  at pin. Its body writes one assignment for each basis, as the loop of pin does.

## Open decisions

- Give a sum of two types the named type with the fewest bases that holds both, as here, or the
  exact union of their bases, as P04 gives each product.
- Export `zeroNamed`, as here, or keep it private until a typed product reads it.

## Landing

- **P04, `basis-set-forms`.** It edits the type of `pga/multivectors.nim`, and this proposal edits
  its arithmetic, so either order applies. With both, two results of P04 add without a widening.
  D51 weighs the patch of D1, whose result types read `zeroNamed`.
- **P01, P10 and P11.** They edit `tests/suites.nim` elsewhere. This proposal adds its suite after
  the last suite of pin, which no other edit quotes.
- **This project.** `copies.nim` builds for Node through the field `backend` of a program claim.

## Evidence

`laws.nim` holds each sum, difference and negation of every pair of named types, at each of the
nine algebras. It reads each coefficient against the coefficients of the operands, and each type
against the rule. A copy whose sum takes the exact union fails it at rga4d, at a scalar and a
vector.

`copies.nim` counts each `nimCopy` call that an operation adds to the assignment of its result,
on Node. With the change, no operation adds one at rga3d, rga4d, cga4d and cga5d. There it holds
136, 171, 171 and 210 operations. At pin it fails at each of those algebras on `Multivector +`,
one copy for each call, and on no other operation.

Its evaluation of 2026-11-15 finds three functions moved at each algebra: `+`, `-` and negation of
whole multivectors. At rga4d each holds 16 lines of C and no call, against 132 to 183 lines and
32 to 48 calls at pin. There `+` zeroes no byte before it writes, where pin zeroes 128. Sums and
differences read ×0.99 to ×1.06 of pin, and negation ×0.98 to ×1.13. The other 439 measurands
read ×0.95 to ×1.07, at a median of ×1.00.
