# P08: Give each chain of the book one table

At pin, five operators of the book each run as a chain of dense products, with an intermediate
between each step. They are the support `∩`, the antisupport `∪`, the cocarrier `⊞`, the center
`⊙` and the container `⊡`. This proposal gives each chain one table, which the rules of P01
derive, so each runs as one product.

This proposal builds on P01, `cayley-derivation`. It reads `applyMap` of P01 and `applyConstant`
of the library. It holds the tables of the chains apart from P01, so that P01 holds its
derivation alone, as the Architect ruled on 2026-10-07.

## What it is

- **Tables.** `CAYLEY_SUPPORT` and `CAYLEY_SUPPORT_ANTI` under the rigid metric, and
  `CAYLEY_CARRIER_CO`, `CAYLEY_CENTER` and `CAYLEY_CONTAINER` under the conformal metric. Each
  folds a chain of maps and products of P01 when the library compiles.
- **Operators.** `∩`, `∪`, `⊙` and `⊡` read their table with both operands 𝐦, through the
  `as_unary` argument of the emitter at pin. `⊞` reads a map of one operand.
- **Laws.** `laws.nim` holds each operator to the chain that pin spells, on 256 seeded dense
  samples at rga3d, rga4d, cga4d and cga5d. It spells each chain through operators that this
  proposal leaves alone. It spells the center through `☆` and `∧`, since this proposal replaces
  `⊞` too.

## What it buys

The evaluation of 2026-10-13 times each operator at pin, and with P01 and this proposal, on
this machine (linux amd64, 4 cores). Five runs alternate the two builds. Pin and Here are the
median nanoseconds of the runs, for one operand of kind General. Each ratio is the median of the
ratios of the runs, so it can differ from Here over Pin.

| Operator | Algebra | Pin | Here | Ratio |
|----------|---------|-----|------|-------|
| `∩` support | rga3d | 9.36 | 3.84 | ×0.41 |
| `∪` antisupport | rga3d | 9.72 | 4.23 | ×0.44 |
| `∩` support | rga4d | 64.37 | 10.64 | ×0.17 |
| `∪` antisupport | rga4d | 55.21 | 11.83 | ×0.21 |
| `⊞` cocarrier | cga4d | 22.36 | 5.51 | ×0.25 |
| `⊙` center | cga4d | 62.26 | 11.39 | ×0.18 |
| `⊡` container | cga4d | 39.68 | 13.91 | ×0.35 |
| `⊞` cocarrier | cga5d | 53.20 | 16.69 | ×0.26 |
| `⊙` center | cga5d | 139.93 | 43.81 | ×0.27 |
| `⊡` container | cga5d | 80.46 | 44.89 | ×0.50 |

P01 alone changes no library function, and its evaluation of the same date times each of these
operators at ×0.95 to ×1.01 of pin. So the gain belongs to this proposal. Both count claims hold:
the support and the antisupport at rga4d each take 54 multiplies. The partner at pin calls `⊡`, so
with this proposal it takes ×0.66 to ×0.86 of pin at cga5d, and ×0.56 to ×0.59 at cga4d. P03
builds on this proposal and folds the partner further.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Shared operand as table operation | Built; drops cross cells, since it is binding, `as_unary` |

## Implementation

- **Files.** `pga/cayleys.nim` and `pga/operators.nim`, as P01 leaves them. The rigid tables
  take a `when IS_RIGID` block of their own after `CAYLEY_ATTITUDE`. The conformal tables follow
  in the const section of `CAYLEY_CARRIER`, which they read. So the rigid block comes first, as
  everywhere in the library. Each table is an exported `const`, folded when the library compiles.
- **Types and signatures.** `CAYLEY_CARRIER_CO` is a `Cayley1D`, and the other four are
  `Cayley2D`. `CAYLEY_SUPPORT` reads the local `wedge_origin`, which is `applyConstant` on a var
  copy of `CAYLEYS_WEDGE.base`, with `Basis.origin.toSigned` on the left. The support is then
  `CAYLEYS_WEDGE.anti.applyMap(wedge_origin.applyMap(CAYLEYS_DUAL.anti.right), Chirality.Right)`.
  `CAYLEY_SUPPORT_ANTI` reads the local `antiwedge_horizon`, which is `applyConstant` on a var
  copy of `CAYLEYS_WEDGE.anti`, with `Basis.horizon` on the left. The antisupport is then
  `CAYLEYS_WEDGE.base.applyMap` of `antiwedge_horizon.applyMap(CAYLEYS_DUAL.base.right)` on the
  right. `CAYLEY_CARRIER_CO` is `CAYLEY_CARRIER.applyMap(CAYLEYS_DUAL.anti.right)`, and
  `CAYLEY_CENTER` is `CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER_CO, Chirality.Left)`.
  `CAYLEY_CONTAINER` is
  `CAYLEYS_WEDGE.base.applyMap(CAYLEYS_DUAL.anti.right.applyMap(CAYLEY_CARRIER), Chirality.Right)`.
- **Functions.** Changed: the hand-written `∩`, `∪`, `⊞`, `⊙` and `⊡` of `pga/operators.nim`.
  Each becomes one call of `defineOperator` on its table, under the same `when` guard as at pin.
  `∩`, `∪`, `⊙` and `⊡` take the Cayley2D overload with `as_unary = true`, and `⊞` takes the
  Cayley1D overload. Each emitted function is `{.inline, noinit.}`, as every generated operator
  at pin is. Added and removed: none.
- **Callers.** Each operator keeps the signature `(m: Multivector): Multivector`. So `support`,
  `supportAnti`, `carrierCo`, `center` and `container` of `pga.nim` compile with no edit. At pin,
  `⊛` calls `⊡`, so it reads the new table with no edit too.
- **Order of edits.** P01 (`cayley-derivation`) lands first and this proposal next, since both
  edits of `pga/cayleys.nim` quote its text and the tables read its `applyMap`. P03
  (`partner-sign`) lands after it, since P03 quotes `CAYLEY_CONTAINER`. The change
  `cayleys-hygiene` is void once P01 lands. The changes `doc-comments` and `doc-comments-2` edit
  other lines of `pga/cayleys.nim`, and each is quoted again against P01 or carried in its text.
  No other proposal or change edits the lines of `pga/operators.nim` that this proposal replaces.

## Open decisions

- Adopt the tables into the library with P01, or after it.
