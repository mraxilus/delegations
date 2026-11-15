# P03: Fold the sign of the partner into its first table

**What it is.** The partner `⊛` folds its sign into the first of its two generated tables, so it
reads no grade at run time and scales nothing.

**What it is for.** The partner of the conformal algebras runs as two generated tables alone, with
no grade scan, no scale and no zero fill.

**What it costs.** It drops the stop on an operand of mixed grade, which has no defined partner.

## Problem

The partner of the conformal algebra is the same object with its squared radius of opposite sign:
(−1)^(grade(𝐦) + 1) (𝐦☆)⊡ ∨ 𝐦⊟. At pin, `⊛` reads the grade of its operand at run time, through
`m.grade.get`. It then scales the container by that sign, and meets the scaled container with
the carrier. The scan reads every coefficient, the scale writes every coefficient, and each
product fills its result with zeros first.

## Idea

- **First table.** `CAYLEY_PARTNER_CONTAINER` is the container of the weight dual, read with 𝐦 as
  both operands. The sign (−1)^(grade(𝐦) + 1) rides the left read alone, by the grade of each
  term. A private constructor, `constructSignPartner`, builds that map of the sign.
- **Second table.** `CAYLEY_PARTNER_MEET` is 𝐦 ∨ 𝐧⊟, the meet of its first operand with the
  carrier of its second. The carrier folds in, so the product reads only the coefficients that
  the carrier reaches. It takes two thirds of the multiplies of `∨`.
- **Operator.** `⊛` holds `partnerContainer(m)` in the variable `container`, declared `noinit`,
  and returns `partnerMeet(container, m)`. Both steps are private, through a new `as_private`
  argument of the Cayley2D overload of `defineOperator`, false by default. Their calls stand with
  the call of `⊡` under `#[ Operator Definitions ]#`. `⊛` takes `inline` and `noinit`, as each
  generated operator does, so its result takes no zero fill. `operators.nim` no longer imports
  `options`.

The container is quadratic in its operand, so a sign on both reads would square away. On one
read, the sign is exact when every term of the operand has the same grade.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Sign on both reads of the container | Squares away, since the container is quadratic |
| Sign on the right read of the second step | Exact and as cheap; one of the two must carry it |
| Scan of grade, unrolled at build | What the dense form does; still a branch for each coefficient |
| Check of single grade under `compileOption("assertions")` | Runs in release, with the scan |
| `partnerMeet(partnerContainer(m), m)` | Zero-fills one intermediate at cga5d |

## Costs

- **Mixed grade.** At pin, `m.grade.get` stops on an operand of mixed grade. Its message,
  ``Can't obtain a value from a `none` ``, does not name the grade. Here no check runs, and such
  an operand gets a value that means nothing. `⊛` keeps its signature, so its one caller, the
  alias `partner` in `pga.nim`, does not change.
- **Two calls.** The chain still calls two functions. Its first step writes into a multivector
  declared `noinit`, since the compiler zero-fills the result of a call that is the operand of a
  second call. So the partner keeps two error checks and two calls, and fills no intermediate. The
  plain composition `partnerMeet(partnerContainer(m), m)` zero-fills one intermediate in its C at
  cga5d, so `⊛` keeps the variable.
- **No table of three operands.** The partner is cubic, so no one table of two operands holds it.
  A table of three operands would, and the emitter reads none.

## Open decisions

- Keep a check of single grade under `when compileOption("assertions"):`, as `pga/algebra.nim`
  guards its checks, or keep no check, as here. That check runs under `-d:release` and is off
  under `-d:danger`.
- Export `partnerContainer` and `partnerMeet`, or keep them private as here.

## Landing

- **Order.** This proposal reads `applyMap` of P01. It quotes `CAYLEY_CONTAINER` and the call of
  `⊡` of P08.
- **P12, `cayley-cells`.** It holds each cell of a table in place. This proposal builds the cells
  of `constructSignPartner` as `@[...]`. So whichever of the two lands second writes
  `BasisSigned(...).toBasesSigned` there.
- **Change `partner-guard`.** It quotes the same two lines of `⊛`, for a message on mixed grade.
  It is void once this proposal lands. If it lands first, this proposal quotes its lines, and so
  removes its assert too.
- **Change `doc-comments`.** It adds a line on single grade to the doc of `partner` in `pga.nim`.
  Its clause on the grade read at run time is stale once this proposal lands. So whichever of the
  two lands second rewrites that line as
  `Requires single-grade multivector; mixed grade has no defined partner, and gets no check.`
- **Change `doc-comments-2`.** It adds to the doc of `grade` that `⊛` calls it per object. That
  clause is stale once this proposal lands, so whichever of the two lands second drops it.
- **Change `imports-narrow`.** It names each symbol that `pga/operators.nim` imports. Whichever
  of the two lands second writes the merged import of P08, and adds both new tables to its
  conformal import of `cayleys`, as below. That import builds with P01, P08 and this proposal at
  pin. The suites pass at rga2d, rga3d, rga4d, rga5d, cga3d, cga4d and cga5d, and `laws.nim`
  passes at cga4d and cga5d.

```nim
when IS_CONFORMAL:
  from ./cayleys {.all.} import
    CAYLEY_CARRIER, CAYLEY_CARRIER_CO, CAYLEY_CENTER, CAYLEY_CONTAINER,
    CAYLEY_PARTNER_CONTAINER, CAYLEY_PARTNER_MEET, CAYLEYS_NORM_SQUARED_RADIUS
```

## Evidence

At cga5d the 324 multiplies of the partner are the bound of its chain: 162 for each folded table.
Its error checks fall from 109 to 2, and its lines of C from 2 530 to 78.

P01 and P08 alone run the partner at ×0.69 to ×0.73 of pin at cga5d, over the kinds of its
operand. With this proposal it runs at ×0.36 to ×0.40. So the fold gives the rest of the gain on
the partner.
