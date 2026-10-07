# P08: Give each compound operator one table

At pin, each compound operator of the book runs as a chain of dense products, with a
multivector between each step. The support `∩`, the antisupport `∪`, the cocarrier `⊞`, the
center `⊙` and the container `⊡` are such chains. This proposal gives each one table, which the
rules of P01 derive, so each runs as one product.

This proposal builds on P01, `cayley-derivation`. It reads `applyMap` of P01 and `applyConstant` of
the library.
It came out of P01 when the Architect ruled on 2026-10-07, so that P01 holds its derivation
alone.

## What it is

- **Tables.** `CAYLEY_SUPPORT` and `CAYLEY_SUPPORT_ANTI` under the rigid metric, and
  `CAYLEY_CARRIER_CO`, `CAYLEY_CENTER` and `CAYLEY_CONTAINER` under the conformal metric. Each
  folds a chain of maps and products of P01 when the library compiles.
- **Operators.** `∩`, `∪`, `⊙` and `⊡` read their table with both operands 𝐦, through the
  `as_unary` argument of the emitter at pin. `⊞` reads a map of one operand.

## What it buys

The evaluation times each operator at pin, and with P01 and this proposal, in this container on
2026-10-07. Each cell is nanoseconds for one operand of the whole algebra:

| Operator | Algebra | Pin | Here | Ratio |
|----------|---------|-----|------|-------|
| `∩` support | rga4d | 87.1 | 13.9 | ×0.16 |
| `∪` antisupport | rga4d | 56.4 | 13.6 | ×0.24 |
| `∩` support | rga3d | 10.8 | 4.2 | ×0.38 |
| `⊞` cocarrier | cga5d | 60.2 | 16.6 | ×0.27 |
| `⊙` center | cga5d | 164.3 | 49.4 | ×0.30 |
| `⊡` container | cga5d | 103.6 | 51.1 | ×0.48 |

P01 alone moves none of these operators, so the gain belongs to this proposal. Both count
claims hold: the support and the antisupport at rga4d each take 54 multiplies. The partner of
P03 reads the container, so it gains too.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Shared operand as table operation | Built; drops cross cells, since it is binding, `as_unary` |

## Open decisions

- Adopt the tables into the library with P01, or after it.
