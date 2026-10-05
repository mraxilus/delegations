# Correct doc comments, first pass

Some doc comments at pin say things that are not true, and some say nothing. This change
corrects the header of `pga.nim`: most operators derive from the metric and the exterior
product, but not all.

It removes table rows for operators that the library does not define. It replaces each
`TODO: Document.` header, and documents the projections and the squared norms. No count
changes.

## Edit `pga.nim`

```nim
## Up to 9D PGAs supported, however recommendation is <= 6D.
```

```nim
## Dimensions 2 to 6 supported; `algebra.nim` asserts range at compile time.
##   Digit encoding of bases admits 9D; build cost is what forbids it.
##   At 6D dense geometric product is 4 096-term function, and C compiler dominates build.
```

## Edit `pga.nim`

```nim
##
## All operators are derived from (anti)metric and exterior product definitions.
```

```nim
##   [Cayley1D, Cayley2D] -> defineOperator -> one function per symbol
##   helpers.nim builds emitted AST; this file only aliases what operators.nim defines.
##
## Most operators are derived from (anti)metric and exterior product definitions.
##   Two, `∧★` and `∨☆`, come from older dual-and-exterior path (cayleys.nim:167).
##   Both paths give same term counts at 4D; see TODO at cayleys.nim:162 to keep one.
```

## Edit `pga.nim`

```nim
##   NOTE: Partially true in current implementation, but should be at end state.
```

```nim
##   Measured: zero allocations on every operator at 4D and 5D.
##   Cayley tables hold `seq` per cell, so reading `CAYLEYS_*` at runtime allocates;
##     inspect them inside `static:` or `const` instead.
```

## Edit `pga.nim`

```nim
##   Recommend to always parenthesize complex operations, or used named aliases.
```

```nim
##   Recommend to always parenthesize complex operations, or used named aliases.
##   Library parenthesizes its own mixed expressions for same reason (operators.nim:472).
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
##   | |∘  | normWeight        | ‖𝐦‖∘        |
```

```nim
##   | |∘  | normWeight        | ‖𝐦‖∘        |
##   | |∙² | normBulkSquared   | ‖𝐦‖∙²       |
##   | |∘² | normWeightSquared | ‖𝐦‖∘²       |
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
when compileOption("profiler"): import std/nimprof

import std/math
```

```nim
when compileOption("profiler"):
  import std/nimprof
  ## Driven by `nim c -d:release --profiler:on --stackTrace:on -r tests/rga/test_4d.nim`.

import std/math
export math  # re-export sqrt and friends, since norms return multivectors of them
```

## Edit `pga.nim`

```nim
  ##   Projects higher-dimensional representations of objects into Eucledian space.
  ##     By scaling weight of 𝐦 to unit magnitude.
```

```nim
  ##   Same function as `normalizeWeight`; `^` is template over `^∘`, so neither costs call.
  ##   Projects higher-dimensional representations of objects into Eucledian space.
```

## Edit `pga.nim`

```nim
    ## Get radius norm of multivector.
```

```nim
    ## Get radius norm of multivector.
    ##   Not implemented; operator table above marks both center and radius norms so.
```

## Edit `pga.nim`

```nim
    ##   I.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
```

```nim
    ##   I.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    ##   Requires single-grade multivector: grade is read at runtime and must be definite.
```

## Edit `pga.nim`

```nim
  ## TODO: Document.

func projectCentralAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨★ n)
  ## TODO: Document.

func projectOrthogonal*(m, n: Multivector): Multivector {.inline.} = n ∨ (m ∧☆ n)
  ## TODO: Document.

func projectOrthogonalAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨☆ n)
  ## TODO: Document.
```

```nim
  ## Project 𝐦 centrally onto 𝐧 through origin, i.e. 𝐧 ∨ (𝐦 ∧ 𝐧★).

func projectCentralAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨★ n)
  ## Project 𝐦 centrally onto 𝐧 in antispace, i.e. 𝐧 ∧ (𝐦 ∨ 𝐧★).

func projectOrthogonal*(m, n: Multivector): Multivector {.inline.} = n ∨ (m ∧☆ n)
  ## Project 𝐦 orthogonally onto 𝐧, i.e. 𝐧 ∨ (𝐦 ∧ 𝐧☆); nearest point of 𝐧 to 𝐦.

func projectOrthogonalAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨☆ n)
  ## Project 𝐦 orthogonally onto 𝐧 in antispace, i.e. 𝐧 ∧ (𝐦 ∨ 𝐧☆).
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
    ##       I.e. e₄₁ is right complement of e₂₃ and vice versa, so complement is index
    ##       reversal rather than permutation table, and plane's coefficients sit in
    ##       matrix row where point's sit in column, with no re-indexing between them.
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
##   Compile-time only: each cell holds `seq`, so runtime read of table allocates.
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
    # TODO: Avoid seq as heap allocated, perhaps array with count custom type.
```

```nim
    # TODO: Avoid seq as heap allocated, perhaps array with count custom type.
    #   Heap here is compiler's VM only: macros alone read these tables.
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
    ##   Right is library default; left tables are built but nothing reads them.
  Partiality {.pure.} = enum Bulk, Weight  ## Define distinction between PGA's disjoint parts.
  Spatiality {.pure.} = enum Base, Anti  ## Define distinction between PGA's spacial duality.
    ##   Base spans 𝟏..eₙ; anti is its complement under antiscalar.
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
  ##   1D table holds signed permutation only: diagonal or basis-swapping metrics.
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
#   Measured gap this would close: 79 of 315 measurands spend more multiplies than
#     typed reference, widest being 1 004 against 10 (5D partner).
```

## Edit `pga/multivectors.nim`

```nim
  ## Convert multivector to readable string representation.
```

```nim
  ## Convert multivector to readable string representation.
  ##   Components at or below tolerance are omitted, so small non-zero prints as nothing.
```

## Edit `pga/operators.nim`

```nim
## TODO: Document.
```

```nim
## Operator definitions: one function generated per Cayley table.
##   Cayley cell (i, j) -> k with sign: product of basis i and j lands in slot k.
##   Negative sign emits leading `-`; absent cell leaves slot at zero fill.
##   Generated functions take pragma from macro's `emitFunc` call, currently empty.
##   Hand-written below generated block: norms, unitize, support, attitude, properties.
```

## Edit `pga/operators.nim`

```nim
      if destination.is_negated: some(prefix(mapping, "-")) else: some(mapping)
    )
```

```nim
      if destination.is_negated: some(prefix(mapping, "-")) else: some(mapping)
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
##   Basis-pair suites run each identity at every pair; sample suites draw from pool.
# TODO: Check which tests should be modified for CGA (after full CGA support).
#   Norm suites are gated `when IS_RIGID` at line 293; ungated they fail (five suites).
```

## Edit `tests/suites.nim`

```nim
    var 𝐦 = ELEMENTS[Basis.scalar.succ]  # 1'e1
```

```nim
    var 𝐦 = ELEMENTS[Basis.scalar.succ]  # e1, constructed as e1(1.0)
```
