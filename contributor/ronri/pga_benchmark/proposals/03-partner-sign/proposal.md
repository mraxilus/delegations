# P03: Fold the sign of the partner into its first table

The partner reads the grade of its operand at run time, and then scales by the sign of that
grade. This proposal folds that sign into the first table of the partner instead, by the grade
of each term. It also folds the carrier into the antiwedge that follows. So the partner is two
generated tables in a chain, with no grade scan and no scale.

This proposal builds on P01, `cayley-derivation`. It reads `applyMap`, `CAYLEY_CONTAINER` and
`CAYLEY_CARRIER`, which P01 adds.

## What it is

- **First table.** `CAYLEY_PARTNER_CONTAINER` is the container of the weight dual, read with
  both operands 𝐦. The sign (-1)^(gr 𝐦 + 1) rides the left read alone, by the grade of each term.
- **Second table.** `CAYLEY_PARTNER_JOIN` is the antiwedge against the carrier of its second
  operand, 𝐭 ∨ 𝐦⊟. The carrier folds in, so the product reads half the cells.
- **Operator.** `⊛` reads `joinCarrier(containPartner(m), m)`. Both steps are private, through
  a new `is_public` argument of `defineOperator`.

The container is quadratic in its operand. A sign on both reads would square away. On one read,
it is exact when every term of the operand has the same grade.

## What it buys

The partner at cga5d, as the inspector counts the C of the bench, at pin `3121342`:

| Build | Multiplies | Zero fills | Error checks | Lines | Bytes moved |
|-------|------------|------------|--------------|-------|-------------|
| Pin | 518 | 108 | 271 | 2710 | 30720 |
| P01 alone | 437 | 104 | 268 | 2621 | 28672 |
| P01 and this proposal | 324 | 3 | 2 | 83 | 2048 |

324 is the chain bound of the partner: 162 for each folded table. Five alternating runs on
2026-10-02 time the partner at ×0.44 to ×0.53 of the pin, over every operand kind. P01 alone
timed ×0.65 to ×0.72 on 2026-10-01. The same container took both.

## Limits

- An operand of mixed grade has no defined partner. The pin stops on one, through
  `m.grade.get`. This proposal returns a value that means nothing, and checks nothing. The
  change `partner-guard` added a message to that stop, and said it goes when the sign folds.
- The chain still calls two functions. So the partner keeps three fills and two error checks,
  for the intermediate and its two calls.
- The partner is cubic, so no one table of two operands holds it. A table of three operands
  would, and the emitter reads none.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Sign on both reads of the container | Squares away, since the container is quadratic |
| Sign on the right read of the second step | Exact and as cheap; one of the two must carry it |
| Scan of grade, unrolled at build | What the dense form does; still a branch for each slot |
| Assert of single grade in release | Costs the scan this proposal removes |

## Open decisions

- Keep a check of single grade under `-d:testing` alone, or none.
- Export `containPartner` and `joinCarrier`, or keep them private as here.
