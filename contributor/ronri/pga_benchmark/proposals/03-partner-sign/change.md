# Partner as two folded tables, its sign read by grade

The partner reads its operand's grade at run time, then scales by the sign of that grade. This
change folds that sign into the left read of its first table instead, by the grade of each
term. It also folds the carrier into the antiwedge that follows. So the partner is two
generated tables, read in a chain, and no grade scan.

### Order of edits

Other edits land in this order against the edits below:

- P01, `cayley-derivation`, lands first and P08, `compound-tables`, second. The tables below
  read `applyMap` of P01, and the first edit quotes `CAYLEY_CONTAINER` of P08.
- The change `partner-guard` quotes the same two lines of `⊛`, so it is void once this change
  lands. If it lands first, this change quotes its lines, and so removes its assert too.
- The change `doc-comments` writes a line in `pga.nim` that says `partner` reads grade at run
  time. That line is stale once this change lands. Whichever of the two lands second drops it.
- The change `imports-narrow` names each symbol that `pga/operators.nim` imports. Whichever of
  the two lands second adds `CAYLEY_PARTNER_CONTAINER` and `CAYLEY_PARTNER_MEET` to the
  conformal import of `cayleys`, and drops `grade` from the import of `algebra`.

## Edit `pga/cayleys.nim`

```nim
    CAYLEY_CONTAINER*: Cayley2D =  ## Container, i.e. 𝐦 ∧ (𝐦⊟)☆, 𝐦 twice.
      CAYLEYS_WEDGE.base.applyMap(
        CAYLEYS_DUAL.anti.right.applyMap(CAYLEY_CARRIER),
        Chirality.Right,
      )
```

```nim
    CAYLEY_CONTAINER*: Cayley2D =  ## Container, i.e. 𝐦 ∧ (𝐦⊟)☆, 𝐦 twice.
      CAYLEYS_WEDGE.base.applyMap(
        CAYLEYS_DUAL.anti.right.applyMap(CAYLEY_CARRIER),
        Chirality.Right,
      )
    CAYLEY_PARTNER_CONTAINER*: Cayley2D = block:  ## Partner step one, (-1)^(gr 𝐦 + 1) (𝐦☆)⊡.
      # Sign rides left read alone, by grade of its term. Container is quadratic, so sign on
      #   both reads would square away; on one, it is exact for single-grade operand.
      var sign: Cayley1D
      for b in Basis: sign[b] = @[BasisSigned(basis: b, is_negated: int(b.grade) mod 2 == 0)]
      CAYLEY_CONTAINER
          .applyMap(CAYLEYS_DUAL.anti.right.applyMap(sign), Chirality.Left)
          .applyMap(CAYLEYS_DUAL.anti.right, Chirality.Right)
    CAYLEY_PARTNER_MEET*: Cayley2D =  ## Partner step two, i.e. 𝐭 ∨ 𝐦⊟, meet with carrier.
      CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER, Chirality.Right)
```

## Edit `pga/operators.nim`

```nim
import std/[macros, math, options]
```

```nim
import std/[macros, math]
```

## Edit `pga/operators.nim`

```nim
  as_unary: static[bool] = false;
): untyped =
  ## Construct multivector product variant using provided Cayley table.
```

```nim
  as_unary: static[bool] = false;
  is_public: static[bool] = true;
): untyped =
  ## Construct multivector product variant using provided Cayley table.
  ##   Private variant serves as step of exported operator, as partner's two tables do.
```

## Edit `pga/operators.nim`

```nim
    body = assignments,
    is_quoted = true,
    is_public = true,
  )



#[ Operator Definitions ]#
```

```nim
    body = assignments,
    is_quoted = true,
    is_public = is_public,
  )



#[ Operator Definitions ]#
```

## Edit `pga/operators.nim`

```nim
  func `⊛`*(m: Multivector): Multivector =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    let sign = Coefficient(-1^(int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

```nim
  defineOperator(
    symbols = "partnerContainer",
    docs = "Get first step of partner, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡.",
    cayley = CAYLEY_PARTNER_CONTAINER,
    as_unary = true,
    is_public = false,
  )
  defineOperator(
    symbols = "partnerMeet",
    docs = "Get antiwedge of first operand with carrier of second, i.e. 𝐭 ∨ 𝐦⊟.",
    cayley = CAYLEY_PARTNER_MEET,
    is_public = false,
  )

  func `⊛`*(m: Multivector): Multivector {.inline, noinit.} =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    ##   Sign rides each term by its own grade, so operand of one grade is required; mixed
    ##     grade has no defined partner, and gets no check.
    ##   First step writes local declared noinit, since compiler zero-fills temporary of call.
    var container {.noinit.}: Multivector
    container = partnerContainer(m)
    result = partnerMeet(container, m)
```
