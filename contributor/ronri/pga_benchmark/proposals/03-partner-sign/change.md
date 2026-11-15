# Partner as two folded tables, its sign read by grade

The partner reads its operand's grade at run time, then scales by the sign of that grade. This
change folds that sign into the left read of its first table instead, by the grade of each
term. It also folds the carrier into the antiwedge that follows. So the partner is two
generated tables, read in a chain, and no grade scan.

### Order of edits

Other edits land in this order against the edits below:

- P01, `cayley-derivation`, lands first and P08, `compound-tables`, second. The tables below
  read `applyMap` of P01. The first edit quotes `CAYLEY_CONTAINER` of P08, and the edit of the
  conformal calls quotes the call of `⊡` of P08.
- P12, `cayley-cells`, holds each cell of a table in place. This change builds the cells of
  `constructSignPartner` as `@[...]`. Whichever of the two lands second writes
  `BasisSigned(...).toBasesSigned` there.
- The change `partner-guard` quotes the same two lines of `⊛`, so it is void once this change
  lands. If it lands first, this change quotes its lines, and so removes its assert too.
- The change `doc-comments` writes a line in `pga.nim` that says `partner` reads grade at run
  time. That line is stale once this change lands. Whichever of the two lands second rewrites it
  as `Requires single-grade multivector; mixed grade has no defined partner, and gets no check.`
- The change `doc-comments-2` adds to the doc of `grade` that `⊛` calls it per object. That
  clause is stale once this change lands. Whichever of the two lands second drops it.
- The change `imports-narrow` names each symbol that `pga/operators.nim` imports. Whichever of
  the two lands second adds `CAYLEY_PARTNER_CONTAINER` and `CAYLEY_PARTNER_MEET` to the
  conformal import of `cayleys`, in the merged import of P08.

## Edit `pga/cayleys.nim`

```nim
    CAYLEY_CONTAINER*: Cayley2D =
      CAYLEYS_INTERIOR.base.weight.right.applyMap(CAYLEY_CARRIER, Chirality.Right)
```

```nim
    CAYLEY_CONTAINER*: Cayley2D =
      CAYLEYS_INTERIOR.base.weight.right.applyMap(CAYLEY_CARRIER, Chirality.Right)
    CAYLEY_PARTNER_CONTAINER*: Cayley2D = block:
      # Apply sign to left operand alone, by grade of its term.
      #   Container is quadratic, so sign on both operands would cancel.
      #   Sign on one operand is exact for operand of single grade.
      let
        antidual = CAYLEYS_DUAL.anti.right
        antidual_signed = antidual.applyMap(constructSignPartner())
      CAYLEY_CONTAINER.applyMap(antidual_signed, Chirality.Left).applyMap(antidual, Chirality.Right)
    CAYLEY_PARTNER_MEET*: Cayley2D =
      CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER, Chirality.Right)
```

The map of the sign is a constructor of its own, as each map of the basis is. Only the conformal
tables read it.

## Edit `pga/cayleys.nim`

```nim



#[ Basis Transformations ]#
```

```nim


when IS_CONFORMAL:
  func constructSignPartner(): Cayley1D {.compileTime, noinit.} =
    ## Construct Cayley table for sign of partner, i.e. (-1)^(grade(𝐦)+1) 𝐦.
    for b in Basis:
      result[b] = @[BasisSigned(basis: b, is_negated: int(b.grade) mod 2 == 0)]



#[ Basis Transformations ]#
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
  as_private: static[bool] = false;
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
    is_public = not as_private,
  )



#[ Operator Definitions ]#
```

The two steps are generated operators, so their calls stand with the calls of the carrier and
the container.

## Edit `pga/operators.nim`

```nim
  defineOperator(
    symbols = "⊡",
    docs = "Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.",
    cayley = CAYLEY_CONTAINER,
    as_unary = true,
  )
```

```nim
  defineOperator(
    symbols = "⊡",
    docs = "Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.",
    cayley = CAYLEY_CONTAINER,
    as_unary = true,
  )
  defineOperator(
    symbols = "partnerContainer",
    docs = "Get first step of partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡.",
    cayley = CAYLEY_PARTNER_CONTAINER,
    as_unary = true,
    as_private = true,
  )
  defineOperator(
    symbols = "partnerMeet",
    docs = "Multiply multivectors through exterior antiproduct with carrier, i.e. 𝐦 ∨ 𝐧⊟.",
    cayley = CAYLEY_PARTNER_MEET,
    as_private = true,
  )
```

The first step lands in an intermediate declared `noinit`. The compiler zero-fills the
intermediate of a call that is the operand of a second call.

## Edit `pga/operators.nim`

```nim
  func `⊛`*(m: Multivector): Multivector =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    let sign = Coefficient(-1^(int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

```nim
  func `⊛`*(m: Multivector): Multivector {.inline, noinit.} =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    ##   Sign follows grade of each term, so operand must have single grade.
    ##   Mixed grade has no defined partner and is not checked.
    var container {.noinit.} = partnerContainer(m)  # Compiler zero-fills nested call result.
    partnerMeet(container, m)
```
