# Correct doc comments, first pass

Some doc comments at pin say things that are not true, and some say nothing. This change
corrects the header of `pga.nim`: most operators derive from the metric and the exterior
product, but not all.

It removes table rows for operators that the library does not define. It replaces each
`TODO: Document.` header, and documents the squared norms. The library at pin documents the
projections, so this change leaves them. No count changes.

Proposal P01, `cayley-derivation`, replaces `pga/cayleys.nim` whole from a digest, and this
change edits that file too. If P01 lands second, its Replace carries the text of this change under
a new digest. If this change lands second, its edits apply as written. The change
`conformal-norms` edits nearby docs in `pga.nim` and `pga/operators.nim`. The two changes quote
distinct lines, so they apply in either order.

Once P01 lands, this change keeps its edit that quotes `  CAYLEYS_DOT* = block:`. That edit
applies as written after P01. P01 gives no table constant a doc, and states the dot in the header
of the file.

Four more proposals make a line of this change stale. Of this change and each of them, the second
to land drops or corrects that line:

- P08, `compound-tables`, generates the support from a table. Then the header of
  `pga/operators.nim` that this change writes must not list `support` as written by hand.
- P03, `partner-sign`, reads no grade in the partner. Then the line that this change adds to the
  doc of `partner` in `pga.nim` is not true. The second to land rewrites it as
  `Requires single-grade multivector; mixed grade has no defined partner, and gets no check.`
- P12, `cayley-cells`, holds each cell of a table in place, with no `seq`. This change writes in
  the header of `pga.nim` that the tables hold `seq` per cell. It writes in the header of
  `pga/cayleys.nim` that each cell holds `seq`. Both lines are false once P12 lands.

Three proposals edit lines that this change quotes:

- P12 removes the TODO of the type block of `pga/cayleys.nim`, under which this change adds a
  line. That edit is void once P12 lands. If this change lands first, P12 quotes both lines.
- P04, `basis-set-forms`, adds `basis_sets` to the import line of `pga.nim`, which an edit of this
  change quotes and keeps. So P04 applies after this change as written. If P04 lands first, this
  change quotes that line again. P09 and P10 build on P04, so each meets this change as P04 does.
- P10, `homogeneous-scalar`, replaces the doc and the body of `normRadius` in `pga.nim`. If P10
  lands first, the edit of this change that adds a line to that doc is void. If this change lands
  first, P10 applies with no misfit, but the conformal build stops. A doc line then stays under
  the new body, so P10 quotes both doc lines.

## Edit `pga.nim`

```nim
## Up to 6D PGAs supported; however, potential for up to 9D (untested).
```

```nim
## Dimensions 2 to 6 supported; `algebra.nim` asserts range at compile time.
##   Digit encoding of bases admits 9D; compile and run time past 6D forbid it.
##   At 6D dense geometric product is 3 072-term function rigid, 4 096-term conformal.
```

## Edit `pga.nim`

```nim
##
## All operators derived from (anti)metric and exterior product definitions.
```

```nim
##
## Most operators derived from (anti)metric and exterior product definitions.
##   Not so for parts, reverses and squared norms of parts, which `cayleys.nim` constructs.
##   Dot comes from transwedges; TODO at `CAYLEYS_DOT` would take it from bulk contraction.
```

## Edit `pga.nim`

```nim
##   NOTE: Partially true in current implementation, but should be at end state.
```

```nim
##   Measured: zero allocations on every operator at rga3d, rga4d, cga4d and cga5d.
##   Cayley tables hold `seq` per cell, and cost of runtime read of `CAYLEYS_*` is unmeasured;
##     inspect them inside `static:` or `const` instead.
```

## Edit `pga.nim`

```nim
##   Each operator is also documented in case symbols are non-obvious for those unfamiliar.
```

```nim
##   Each operator is also documented in case symbols are non-obvious for those unfamiliar.
##   Read order: this file, then operators.nim's two macros, then cayleys.nim's tables.
```

## Edit `pga.nim`

```nim
##   | ∨∧★ | projectCentral        | 𝐧 ∨ (𝐦 ∧ 𝐧★)  |
##   | ∧∨★ | projectCentralAnti    | 𝐧 ∧ (𝐦 ∨ 𝐧★)  |
##   | ∨∧☆ | projectOrthogonal     | 𝐧 ∨ (𝐦 ∧ 𝐧☆) |
##   | ∧∨☆ | projectOrthogonalAnti | 𝐧 ∧ (𝐦 ∨ 𝐧☆) |
##   |-----|-----------------------|---------------|
```

```nim
##   |-----|-----------------------|---------------|
## Names below are aliases only; no operator symbol exists for them:
##   projectCentral    𝐧 ∨ (𝐦 ∧ 𝐧★)      projectCentralAnti     𝐧 ∧ (𝐦 ∨ 𝐧★)
##   projectOrthogonal 𝐧 ∨ (𝐦 ∧ 𝐧☆)      projectOrthogonalAnti  𝐧 ∧ (𝐦 ∨ 𝐧☆)
```

## Edit `pga.nim`

```nim
  import std/nimprof

import ./pga/[algebra, cayleys, multivectors, operators]
```

```nim
  import std/nimprof
  ## Enabled by `--profiler:on --stackTrace:on`, e.g. on `tests/rga4d/test_rga4d.nim`.

import ./pga/[algebra, cayleys, multivectors, operators]
```

## Edit `pga.nim`

```nim
  ##   Projects higher-dimensional representations of objects into Eucledian space.
  ##     By scaling weight of 𝐦 to unit magnitude.
```

```nim
  ##   Same function as `normalizeWeight`; `^` is template over `^∘`, so adds no call itself.
  ##   Projects higher-dimensional representations of objects into Eucledian space.
```

## Edit `pga.nim`

```nim
    ## Get radius norm of multivector.
```

```nim
    ## Get radius norm of multivector.
    ##   Conformal only, as † marks in operator table above.
```

## Edit `pga.nim`

```nim
    ##   I.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
```

```nim
    ##   I.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    ##   Requires single-grade multivector: grade is read at runtime and must be definite.
```

## Edit `pga/algebra.nim`

```nim
{.experimental: "codeReordering".}
```

```nim
{.experimental: "codeReordering".}
  # Required: `defineBasis(DIMENSIONS)` below calls constructors defined after it.
```

## Edit `pga/algebra.nim`

```nim
  ##     Order 4D 2/3-vectors to align as right complements of basis vectors,
  ##       to consider 4x4 transformation matrix rows as planes, columns as points.
  ##       TODO: Understand statement above better.
```

```nim
  ##     Order 4D 2/3-vectors to align as right complements of basis vectors,
  ##       to consider 4x4 transformation matrix rows as planes, columns as points.
  ##       I.e. right complements of e₁, e₂, e₃, e₄ are +e₄₂₃, +e₄₃₁, +e₄₁₂, +e₃₂₁ in order,
  ##       so plane's coefficients sit in matrix row where point's sit in column,
  ##       with no re-indexing between them.
```

## Edit `pga/algebra.nim`

```nim

  var algebras = {
```

```nim

  # Orders below are Lengyel's published ones through 4D; generator extends from 4D up.
  var algebras = {
```

## Edit `pga/cayleys.nim`

```nim
## Cayleys exposed to importer so they can inspect algebra's definition.
```

```nim
## Cayleys exposed to importer so they can inspect algebra's definition.
##   Each cell holds `seq`; library reads tables at compile time only.
```

## Edit `pga/cayleys.nim`

```nim
{.experimental: "codeReordering".}
```

```nim
{.experimental: "codeReordering".}
  # Required: const tables below are built by constructors defined further down.
```

## Edit `pga/cayleys.nim`

```nim
    # TODO: Avoid `seq` as heap allocated, perhaps array with count custom type.
```

```nim
    # TODO: Avoid `seq` as heap allocated, perhaps array with count custom type.
    #         Heap here is compiler's VM only: const blocks and macros alone read these tables.
```

## Edit `pga/cayleys.nim`

```nim
type  ## Define type definitions for algebraic distinctions.
  Chirality {.pure.} = enum Left, Right  ## Define distinction between PGA operation orientations.
  Partiality {.pure.} = enum Bulk, Weight  ## Define distinction between PGA's disjoint parts.
  Spatiality {.pure.} = enum Base, Anti  ## Define distinction between PGA's spacial duality.
```

```nim
type  ## Define type definitions for algebraic distinctions.
  Chirality {.pure.} = enum Left, Right  ## Define distinction between PGA operation orientations.
    ##   Right is default; left complement serves `\`, and left interior tables reach no operator.
  Partiality {.pure.} = enum Bulk, Weight  ## Define distinction between PGA's disjoint parts.
  Spatiality {.pure.} = enum Base, Anti  ## Define distinction between PGA's spacial duality.
    ##   Base works by grade and ∧; anti by antigrade and ∨, i.e. base under complements.
```

## Edit `pga/cayleys.nim`

```nim
  CAYLEYS_DOT* = block:
```

```nim
  CAYLEYS_DOT* = block:
    ## Dot is transwedge of order k where both operands have grade k.
```

## Edit `pga/cayleys.nim`

```nim
  ## Construct metric 𝖌 simplified as 1D cayley table.
```

```nim
  ## Construct metric 𝖌 simplified as 1D cayley table.
  ##   1D table holds one signed basis or none per cell: diagonal, degenerate or swapping metric.
```

## Edit `pga/cayleys.nim`

```nim
  ##   𝖌 expands to 𝐆 via 𝐆(𝐦 ∧ 𝐧) = (𝐆𝐦) ∧ (𝐆𝐧).
```

```nim
  ##   𝖌 expands to 𝐆 via 𝐆(𝐦 ∧ 𝐧) = (𝐆𝐦) ∧ (𝐆𝐧).
  ##   So one degenerate factor makes whole blade degenerate.
```

## Edit `pga/cayleys.nim`

```nim
  ## Construct Cayley tables for each order of specific transitional product.
```

```nim
  ## Construct Cayley tables for each order of specific transitional product.
  ##   Per (a, b): reduce a by left operator, b by right operator, then multiply
  ##     both reductions through inner wedge. Order k is how many vectors pass through.
```

## Edit `pga/multivectors.nim`

```nim
# TODO: Represent multivector primitives using more compact data types.
```

```nim
# TODO: Represent multivector primitives using more compact data types.
#   Measured gap this would close: 128 of 269 typed measurands spend more multiplies than
#     typed reference, widest being 518 against 10 (cga5d partner).
```

## Edit `pga/multivectors.nim`

```nim
  ## Convert multivector to readable string representation.
```

```nim
  ## Convert multivector to readable string representation.
  ##   Components at or below tolerance are omitted; all-omitted multivector prints as `0𝟏`.
```

## Edit `pga/operators.nim`

```nim
## TODO: Document.
```

```nim
## Define operators: `defineOperator` generates one function per call, from its Cayley table.
##   Cayley cell (i, j) lists signed k per term: product of basis i and j adds into each k.
##   Negative sign emits leading `-`; basis no term reaches gets literal `0.0`.
##   Generated functions take pragmas `inline` and `noinit` from macro's `emitFunc` call.
##   Hand-written below generated block: scalar product, norms, unitize, support, ⊞ ⊙ ⊡ ⊛.
```

## Edit `pga/operators.nim`

```nim
          if destination.is_negated: prefix(source, "-") else: source
        )
```

```nim
          if destination.is_negated: prefix(source, "-") else: source
        )  # sign folded into read, so assignment below stays plain
```

## Edit `pga/operators.nim`

```nim
  docs = "Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.",
```

```nim
  docs = "Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★." &
      "\n  Built from dual-and-exterior table, not from transwedge tables.",
```

## Edit `tests/suites.nim`

```nim
## TODO: Document.
# TODO: Check which tests should be modified for CGA (after full CGA support).
```

```nim
## Law suites keyed to equation numbers of Lengyel's book.
##   Basis-pair tests walk basis pairs, some grade-filtered; sample tests draw from seeded pool.
# TODO: Check which tests should be modified for CGA (after full CGA support).
#   Norm tests 2.87-89, 2.90-94, 2.97-98, 2.99 and dual test 2.103 run only `when IS_RIGID`.
```

## Edit `tests/suites.nim`

```nim
    var 𝐦 = ELEMENTS[Basis.scalar.succ]  # `1'e1`
```

```nim
    var 𝐦 = ELEMENTS[Basis.scalar.succ]  # `e1`, i.e. `Basis.E1.initElement(1)`
```
