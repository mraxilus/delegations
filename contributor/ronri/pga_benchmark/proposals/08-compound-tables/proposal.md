# P08: Give each chain of the book one table

**What it is.** Five operators of the book each read one table, which the library folds from their
chain of products as it compiles. So four of them run as one product, and the cocarrier as one
map.

**What it is for.** Each of the five runs with no intermediate multivector, so it runs faster. The
partner `⊛` calls one of them, so it runs faster too.

**What it costs.** Each build of the library derives two more tables under the rigid metric, or
three under the conformal metric. Their cost in compile time is unmeasured.

## Problem

At pin, five operators of the book each run as a chain of two or three steps. One or two maps
come first, then one or two dense products. They are the support `∩`, the antisupport `∪`, the
cocarrier `⊞`, the center `⊙` and the container `⊡`. Each step of a chain fills a whole
intermediate multivector. The partner `⊛` calls `⊡`, so it runs that chain too.

## Idea

- **Tables.** Under the rigid metric, `CAYLEYS_SUPPORT` holds the support as `base` and the
  antisupport as `anti`, as each pair of tables at pin does. Under the conformal metric,
  `CAYLEY_CARRIER_CO`, `CAYLEY_CENTER` and `CAYLEY_CONTAINER` hold one table each. Each table
  folds the maps and products of its chain as the library compiles.
- **Example.** `CAYLEY_CARRIER_CO` folds the weight dual `☆` into `CAYLEY_CARRIER` of pin, so
  the cocarrier is one map. `CAYLEY_CENTER` then folds that map into the left read of `∨`. So the
  center 𝐦⊞ ∨ 𝐦 is one product.
- **Interior products.** Three tables start from an interior product of pin, which already
  folds a dual into a wedge. `CAYLEY_CONTAINER` folds `CAYLEY_CARRIER` into the right read of
  𝐦 ∧ 𝐧☆.
- **Constants.** The support starts from 𝐦 ∧ 𝐧☆, and the antisupport from 𝐦 ∨ 𝐧★. Each fixes
  the left operand through `applyConstant` of the library, to the origin or to the horizon. That
  gives a map, which then folds into the right read of `∨` or `∧`.
- **Operators.** `∩`, `∪`, `⊙` and `⊡` read their table with both operands 𝐦, through the
  `as_unary` argument of the emitter at pin. `⊞` reads a map of one operand. Each operator is one
  call of `defineOperator`, under the same `when` guard as at pin. Each emitted function is
  `{.inline, noinit.}`, as every generated operator at pin is.
- **Place of the operators.** The five calls stand under `#[ Operator Definitions ]#` with their
  family. `∩` and `∪` follow `⊖`, and `⊞`, `⊙` and `⊡` follow `⊟`. So `#[ Support ]#` keeps
  only `⊛`, which stays written by hand.
- **Place of the tables.** `CAYLEYS_SUPPORT` takes a `when IS_RIGID` block of its own after
  `CAYLEY_ATTITUDE`. The conformal tables join the const section of `CAYLEY_CARRIER`, since they
  read it. So the rigid block comes first, as everywhere in the library. No table carries a doc
  comment, as at pin.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Chains of pin, by hand | Each step fills a whole intermediate. Evidence gives the cost in time. |
| From `CAYLEYS_WEDGE` and `CAYLEYS_DUAL` | Equal tables, but 8 calls of `applyMap` in place of 5 |

## Costs

- **Compile time.** Each build of the library derives two or three more tables. No evaluation
  measures that cost.
- **Callers.** Each operator keeps its signature `(m: Multivector): Multivector`. So `support`,
  `supportAnti`, `carrierCo`, `center` and `container` of `pga.nim` compile with no edit. `⊛`
  reads the new table with no edit too.
- **Values.** `∩`, `∪`, `⊞` and `⊡` keep their value bit for bit. `⊙` sums its terms in another
  order, so its value differs from the chain by rounding. The difference stays within the
  comparison tolerance of `=~` that `laws.nim` checks. On 256 seeded dense samples at cga5d, it
  is 1.8e-15 at most.

## Open decisions

- Adopt the tables into the library with P01, or after it.

## Landing

- **Order.** P01, `cayley-derivation`, lands first, since every table reads its `applyMap`. This
  proposal holds the tables apart from P01, so that P01 holds its derivation alone, as the
  Architect ruled on 2026-10-07.
- **Quotes.** Of the two edits of `pga/cayleys.nim`, only the edit of the header line quotes text
  of P01. The other edit quotes the block of `CAYLEY_CARRIER`, which is the same at pin. The two
  edits of `pga/operators.nim` quote the call of `⊟` and the hand-written operators of
  `#[ Support ]#` at pin. No other proposal or change edits those lines.
- **P03, `partner-sign`.** It quotes `CAYLEY_CONTAINER` and the call of `⊡`, so it lands after
  this proposal. It then folds the partner further.
- **P04, `basis-set-forms`.** It gives a basis-set form to each operator that the library builds
  from one table. The header of its `pga/basis_sets.nim` lists the supports among the operators
  from no table. Its Costs list the cocarrier, the center and the container there too. This
  proposal builds each of the five from one table. So whichever of the two lands second gives each
  of the five a form. Or it states in that header and in those Costs that these five have a table
  and stay on `Multivector`.
- **P12, `cayley-cells`.** It and P01 are written again against each other, whichever lands
  second. The edits of this proposal quote no line that P12 edits and build no cell, so they hold
  once that is done.
- **Change `cayleys-hygiene`.** Its edits are void once P01 lands.
- **Changes `doc-comments` and `doc-comments-2`.** They edit other lines of `pga/cayleys.nim`, and
  each is quoted again against P01 or carried in its text. `doc-comments` also writes in the
  header of `pga/operators.nim` that the support is written by hand. That line is stale once this
  proposal lands, since a table then generates the support. So whichever of `doc-comments` and
  this proposal lands second drops `support` from that line.
- **Change `imports-narrow`.** It names each symbol that `pga/operators.nim` imports, so with
  both applied, in either order, the build stops on `undeclared identifier: 'CAYLEYS_SUPPORT'`
  under the rigid metric. Under the conformal metric, it stops on
  `undeclared identifier: 'CAYLEY_CARRIER_CO'`. Whichever of the two lands second writes the
  merged import below, with the new tables. It drops `origin`, `horizon` and `infinity`, which no
  operator reads once this proposal lands. That import builds with P01 and this proposal at pin.
  The suites pass at rga2d, rga3d, rga4d, rga5d, cga3d, cga4d and cga5d, and `laws.nim` passes at
  rga4d and cga5d.

```nim
import ./[emitters, multivectors]
from ./algebra {.all.} import
  Basis, Coefficient, Grade, GradeAnti, DIMENSIONS, IS_CONFORMAL, IS_RIGID,
  grade, gradeAnti, scalar, scalarAnti, high, low, `==`
from ./cayleys {.all.} import
  Cayley1D, Cayley2D, BasisSigned, Chiral, Formal, Partial, Spatial, complement,
  CAYLEYS_COMPLEMENT, CAYLEYS_DOT, CAYLEYS_DUAL, CAYLEYS_INTERIOR, CAYLEYS_PARTS,
  CAYLEYS_REVERSE, CAYLEYS_WEDGE, CAYLEYS_WEDGE_DOT, CAYLEYS_NORM_SQUARED, CAYLEY_ATTITUDE
when IS_RIGID:
  from ./cayleys {.all.} import CAYLEYS_SUPPORT
when IS_CONFORMAL:
  from ./cayleys {.all.} import
    CAYLEY_CARRIER, CAYLEY_CARRIER_CO, CAYLEY_CENTER, CAYLEY_CONTAINER,
    CAYLEYS_NORM_SQUARED_RADIUS
```

## Evidence

Each of the five operators takes ×0.23 to ×0.47 of its time at pin, for one operand of kind
General. The two supports gain least at rga3d, at ×0.46 and ×0.47. The partner takes ×0.68 to
×0.69 of pin at cga5d, for each kind of its operand.

P01 alone changes no library function, so the gain belongs to this proposal. Its evaluation of
2026-11-26 times each of these operators at ×0.99 to ×1.01 of pin.

Five count claims hold the multiplies of each operator. `∩` and `∪` take 54 each at rga4d,
against 162 at pin. At cga5d, `⊞` takes none against 243, and `⊙` and `⊡` take 162 each against
486 and 243. So a count claim fails if one of the five keeps its chain.

`laws.nim` holds each operator equal to the chain that pin spells, on 256 seeded dense samples.
It spells each chain through operators that this proposal leaves alone. So it spells the center
through `☆` and `∧`, and not through `⊞`, which this proposal replaces too.
