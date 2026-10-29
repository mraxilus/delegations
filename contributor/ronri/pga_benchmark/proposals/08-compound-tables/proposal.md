# P08: Give each chain of the book one table

**What it is.** Five operators of the book each read one table, which the library folds from their
chain of products as it compiles. So each one runs as one product.

**What it is for.** Each of the five runs with no intermediate multivector, so it runs faster. The
partner `⊛` calls one of them, so it runs faster too.

**What it costs.** Each build of the library derives five more tables, and their cost in compile
time is unmeasured.

## Problem

At pin, five operators of the book each run as a chain of two or three dense products. They are
the support `∩`, the antisupport `∪`, the cocarrier `⊞`, the center `⊙` and the container `⊡`.
Each step of a chain fills a whole intermediate multivector. The partner `⊛` calls `⊡`, so it
runs that chain too.

## Idea

- **Tables.** `CAYLEY_SUPPORT` and `CAYLEY_SUPPORT_ANTI` under the rigid metric, and
  `CAYLEY_CARRIER_CO`, `CAYLEY_CENTER` and `CAYLEY_CONTAINER` under the conformal metric. Each
  folds the maps and products of its chain as the library compiles.
- **Example.** `CAYLEY_CARRIER_CO` folds the weight dual `☆` into `CAYLEY_CARRIER` of pin, so
  the cocarrier is one map. `CAYLEY_CENTER` then folds that map into the left read of `∨`. So the
  center 𝐦⊞ ∨ 𝐦 is one product.
- **Constants.** Each rigid table first fixes one operand of a product, through `applyConstant`
  of the library. It fixes the origin on the left of `∧`, or the horizon on the left of `∨`. That
  gives a map, which then folds in the same way.
- **Operators.** `∩`, `∪`, `⊙` and `⊡` read their table with both operands 𝐦, through the
  `as_unary` argument of the emitter at pin. `⊞` reads a map of one operand. Each operator is one
  call of `defineOperator`, under the same `when` guard as at pin. Each emitted function is
  `{.inline, noinit.}`, as every generated operator at pin is.
- **Place.** The rigid tables take a `when IS_RIGID` block of their own after `CAYLEY_ATTITUDE`.
  The conformal tables join the const section of `CAYLEY_CARRIER`, since they read it. So the
  rigid block comes first, as everywhere in the library.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Shared operand as table operation | Built; drops cross cells, since it is binding, `as_unary` |

## Costs

- **Compile time.** Each build of the library derives five more tables. No evaluation measures
  that cost.
- **Callers.** Each operator keeps its signature `(m: Multivector): Multivector`, and its value.
  So `support`, `supportAnti`, `carrierCo`, `center` and `container` of `pga.nim` compile with no
  edit. `⊛` reads the new table with no edit too.

## Open decisions

- Adopt the tables into the library with P01, or after it.

## Landing

- **Order.** P01, `cayley-derivation`, lands first, since every table reads its `applyMap`. This
  proposal holds the tables apart from P01, so that P01 holds its derivation alone, as the
  Architect ruled on 2026-10-07.
- **Quotes.** Of the two edits of `pga/cayleys.nim`, only the edit of the header line quotes text
  of P01. The other edit quotes the block of `CAYLEY_CARRIER`, which is the same at pin. No other
  proposal or change edits the lines of `pga/operators.nim` that this proposal replaces.
- **P03, `partner-sign`.** It quotes `CAYLEY_CONTAINER`, so it lands after this proposal. It then
  folds the partner further.
- **Change `cayleys-hygiene`.** Its edits are void once P01 lands.
- **Changes `doc-comments` and `doc-comments-2`.** They edit other lines of `pga/cayleys.nim`, and
  each is quoted again against P01 or carried in its text. `doc-comments` also writes in the
  header of `pga/operators.nim` that the support is written by hand. That line is stale once this
  proposal lands, since a table then generates the support. So whichever of `doc-comments` and
  this proposal lands second drops `support` from that line.
- **Change `imports-narrow`.** It names each symbol that `pga/operators.nim` imports, so with
  both applied, in either order, the build stops on `undeclared identifier: 'CAYLEY_SUPPORT'`.
  Whichever of the two lands second writes the merged import below, with the five tables. It
  drops `origin`, `horizon` and `infinity`, which no operator reads once this proposal lands. A
  run by hand on 2026-10-15 built that import with P01 and this proposal. The suites passed at
  rga2d, rga3d, rga4d, cga3d, cga4d and cga5d.

```nim
import ./[helpers, multivectors]
from ./algebra {.all.} import
  Basis, Grade, GradeAnti, DIMENSIONS, IS_CONFORMAL, IS_RIGID,
  grade, gradeAnti, scalar, scalarAnti, high, low, `==`
from ./cayleys {.all.} import
  Cayley1D, Cayley2D, BasisSigned, Chiral, Formal, Partial, Spatial, complement,
  CAYLEYS_COMPLEMENT, CAYLEYS_DOT, CAYLEYS_DUAL, CAYLEYS_INTERIOR, CAYLEYS_PARTS,
  CAYLEYS_REVERSE, CAYLEYS_WEDGE, CAYLEYS_WEDGE_DOT, CAYLEYS_NORM_SQUARED, CAYLEY_ATTITUDE
when IS_RIGID:
  from ./cayleys {.all.} import CAYLEY_SUPPORT, CAYLEY_SUPPORT_ANTI
when IS_CONFORMAL:
  from ./cayleys {.all.} import
    CAYLEY_CARRIER, CAYLEY_CARRIER_CO, CAYLEY_CENTER, CAYLEY_CONTAINER,
    CAYLEYS_NORM_SQUARED_RADIUS
```

## Evidence

Each of the five operators takes ×0.19 to ×0.38 of its time at pin, for one operand of kind
General. The partner takes ×0.65 to ×0.73 of pin at cga5d, over the kinds of its operand.

P01 alone changes no library function, so the gain belongs to this proposal. Its evaluation of
the same date times these operators at ×0.86 to ×0.99 of pin, which is noise of the machine.

`laws.nim` holds each operator equal to the chain that pin spells, on 256 seeded dense samples.
It spells each chain through operators that this proposal leaves alone. So it spells the center
through `☆` and `∧`, and not through `⊞`, which this proposal replaces too.
