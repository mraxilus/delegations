# P03: Fold the sign of the partner into its first table

The partner reads the grade of its operand at run time, and then scales by the sign of that
grade. This proposal folds that sign into the first table of the partner instead, by the grade
of each term. It also folds the carrier into the antiwedge that follows. So the partner is two
generated tables in a chain, with no grade scan and no scale.

This proposal builds on P01, `cayley-derivation`, and on P08, `compound-tables`. It reads
`applyMap` of P01, `CAYLEY_CONTAINER` of P08, and `CAYLEY_CARRIER`, which the pin has.

## What it is

- **First table.** `CAYLEY_PARTNER_CONTAINER` is the container of the weight dual, read with
  𝐦 as both operands. The sign (-1)^(gr 𝐦 + 1) rides the left read alone, by the grade of each term.
- **Second table.** `CAYLEY_PARTNER_MEET` is 𝐭 ∨ 𝐦⊟, the meet with the carrier of its second
  operand. The carrier folds in, so the product reads only the slots of the second operand that
  the carrier reaches. It takes two thirds of the multiplies of `∨`: 162 of 243 at cga5d, and
  54 of 81 at cga4d.
- **Operator.** `⊛` reads `partnerMeet(partnerContainer(m), m)`. Both steps are private,
  through a new `is_public` argument of the Cayley2D overload of `defineOperator`, true by
  default.

The container is quadratic in its operand. A sign on both reads would square away. On one read,
it is exact when every term of the operand has the same grade.

## What it buys

The partner at cga5d, as the inspector counts the C of the bench, at pin `28f4e11`:

| Build | Multiplies | Zero fills | Error checks | Lines | Bytes moved |
|-------|------------|------------|--------------|-------|-------------|
| Pin | 518 | 108 | 271 | 2710 | 30720 |
| P01 and P08 | 437 | 104 | 268 | 2621 | 28672 |
| P01, P08 and this proposal | 324 | 3 | 2 | 83 | 2048 |

324 is the chain bound of the partner: 162 for each folded table. The evaluation of 2026-10-13
times the partner over every operand kind, in five runs that alternate the two builds. It ran on
this machine (linux amd64, 4 cores). With this proposal, the partner takes ×0.46 to ×0.52 of
pin at cga5d, and ×0.45 to ×0.50 at cga4d.

The evaluation of P08, of the same date, times P01 and P08 alone. There the partner takes ×0.66 to
×0.86 of pin at cga5d, and ×0.56 to ×0.59 at cga4d. Each ratio is the median of the ratios of the
runs.

## Limits

- An operand of mixed grade has no defined partner. The pin stops on one, through
  `m.grade.get`, with no message. This proposal returns a value that means nothing, and checks
  nothing.
- The chain still calls two functions. So the partner keeps three fills and two error checks,
  for two intermediates and two calls.
- The partner is cubic, so no one table of two operands holds it. A table of three operands
  would, and the emitter reads none.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Sign on both reads of the container | Squares away, since the container is quadratic |
| Sign on the right read of the second step | Exact and as cheap; one of the two must carry it |
| Scan of grade, unrolled at build | What the dense form does; still a branch for each slot |
| Assert of single grade in release | Costs the scan this proposal removes |

## Implementation

- **Files.** `pga/cayleys.nim` and `pga/operators.nim`, as P01 and P08 leave them.
- **Types and signatures.** Two `Cayley2D` consts join the `when IS_CONFORMAL` const block of
  P08, after `CAYLEY_CONTAINER`. `CAYLEY_PARTNER_CONTAINER*` is `CAYLEY_CONTAINER`, with
  `CAYLEYS_DUAL.anti.right.applyMap(sign)` applied to its left read and `CAYLEYS_DUAL.anti.right`
  to its right read. Here `sign` is a local `Cayley1D` that negates each basis of even grade, so
  a term of grade k in 𝐦 takes (-1)^(k+1). `CAYLEY_PARTNER_MEET*` is
  `CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER, Chirality.Right)`. The library calls ∨ the meet,
  so the name says meet. The Cayley2D overload of `defineOperator` gains
  `is_public: static[bool] = true` after `as_unary`, and passes it to `emitFunc`, while the
  Cayley1D overload stays as at pin.
- **Functions.** Added: the private `partnerContainer(m: Multivector): Multivector`, which reads
  its table with both operands 𝐦, and the private `partnerMeet(m, n: Multivector): Multivector`.
  Changed: `` func `⊛`*(m: Multivector): Multivector `` gains `{.inline.}`, and its body is
  `partnerMeet(partnerContainer(m), m)`, with no grade scan and no scale, and nothing is removed.
  Then `pga/operators.nim` uses nothing of `std/options` under either metric, so this proposal
  drops `options` from its imports. A build by hand on 2026-10-15 with `--warnings:on` showed no
  unused import at rga3d, rga4d, cga4d and cga5d. `laws.nim` holds `⊛` to its definition through
  `⊡`, which here is the table of P08. The `laws.nim` of P08 holds that table to the chain of pin.
- **Callers.** The signature of `⊛` stays, so `partner` of `pga.nim` and every other caller
  compiles with no edit. A caller that passes an operand of mixed grade no longer stops, and
  gets a value that means nothing (Limits). The change `doc-comments` writes in `pga.nim` that
  `partner` reads grade at run time, and that line goes once this proposal lands.
- **Order of edits.** P01 (`cayley-derivation`) lands first and P08 (`compound-tables`) second,
  since this proposal reads `applyMap` and quotes `CAYLEY_CONTAINER`. This proposal removes the
  sign line of `⊛`, so the edit of that line in P06 (`float-width`) is void once it lands. If
  P06 lands first, this proposal quotes `Coefficient(...)` in place of `float(...)`. The change
  `partner-guard` quotes the same two lines of `⊛` for a message on mixed grade, so it is void
  once this proposal lands. If it lands first, this proposal quotes
  its lines, and so removes its assert too.

## Open decisions

- Keep a check of single grade under `-d:testing` alone, or none.
- Export `partnerContainer` and `partnerMeet`, or keep them private as here.
