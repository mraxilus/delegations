# P03: Fold the sign of the partner into its first table

**What it is.** The partner `⊛` folds its sign into the first of its two generated tables, so it
reads no grade at run time and scales nothing.

**What it is for.** The partner of the conformal algebras runs as two generated tables alone, with
no grade scan, no scale and almost no zero fill.

**What it costs.** It drops the stop on an operand of mixed grade, which has no defined partner.

## Problem

The partner of the conformal algebra is the same object with its squared radius of opposite sign:
(−1)^(grade(𝐦) + 1) (𝐦☆)⊡ ∨ 𝐦⊟. At pin, `⊛` reads the grade of its operand at run time, through
`m.grade.get`. It then runs two products, and scales their result by that sign. The scan reads
every coefficient, the scale writes every coefficient, and each product fills its result with
zeros first.

## Idea

- **First table.** `CAYLEY_PARTNER_CONTAINER` is the container of the weight dual, read with 𝐦 as
  both operands. The sign (−1)^(gr 𝐦 + 1) rides the left read alone, by the grade of each term.
- **Second table.** `CAYLEY_PARTNER_MEET` is 𝐭 ∨ 𝐦⊟, the meet with the carrier of its second
  operand. The carrier folds in, so the product reads only the slots that the carrier reaches. It
  takes two thirds of the multiplies of `∨`.
- **Operator.** `⊛` reads `partnerMeet(partnerContainer(m), m)`. Both steps are private, through a
  new `is_public` argument of the Cayley2D overload of `defineOperator`, true by default.

The container is quadratic in its operand, so a sign on both reads would square away. On one
read, the sign is exact when every term of the operand has the same grade.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Sign on both reads of the container | Squares away, since the container is quadratic |
| Sign on the right read of the second step | Exact and as cheap; one of the two must carry it |
| Scan of grade, unrolled at build | What the dense form does; still a branch for each slot |
| Assert of single grade in release | Costs the scan this proposal removes |

## Costs

- **Mixed grade.** At pin, `m.grade.get` stops on an operand of mixed grade, with no message. Here
  no check runs, and such an operand gets a value that means nothing. Each caller of `partner`
  in `pga.nim` keeps its signature, so no caller changes.
- **Two calls.** The chain still calls two functions. So the partner keeps three zero fills and
  two error checks, for two intermediates and two calls.
- **No table of three operands.** The partner is cubic, so no one table of two operands holds it.
  A table of three operands would, and the emitter reads none.

## Open decisions

- Keep a check of single grade under `-d:testing` alone, or none.
- Export `partnerContainer` and `partnerMeet`, or keep them private as here.

## Landing

- **Order.** This proposal reads `applyMap` of P01, and quotes `CAYLEY_CONTAINER` of P08.
- **Change `partner-guard`.** It quotes the same two lines of `⊛`, for a message on mixed grade.
  It is void once this proposal lands. If it lands first, this proposal quotes its lines, and so
  removes its assert too.
- **Change `doc-comments`.** It adds a line on single grade to the doc of `partner` in `pga.nim`.
  That line is stale once this proposal lands, so whichever of the two lands second drops it.
- **Change `imports-narrow`.** It names each symbol that `pga/operators.nim` imports. Whichever
  of the two lands second writes the merged import of P08. It adds both new tables to the
  conformal import of `cayleys`, and drops `grade` from the import of `algebra`. A run by hand on
  2026-10-15 built that import with P01, P08 and this proposal, and the suites passed at rga2d,
  rga3d, rga4d, cga3d, cga4d and cga5d.

## Evidence

At cga5d the 324 multiplies of the partner are the bound of its chain: 162 for each folded table.
Its error checks fall from 271 to 2, and its lines of C from 2710 to 83.

P01 and P08 alone run the partner at ×0.66 to ×0.70 of pin at cga5d, and ×0.53 to ×0.60 at
cga4d. So the fold gives the rest of the gain on the partner.
