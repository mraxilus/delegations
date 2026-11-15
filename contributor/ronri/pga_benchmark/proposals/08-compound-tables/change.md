# One table for each chain, as edits on P01

Five chains of the book each read one table that P01's rules derive. So each runs as one
product, or as one map for the cocarrier. At pin, each one runs as dense products, with an
intermediate between each step.

### Order of edits

Other edits land in this order against the edits below:

- P01, `cayley-derivation`, lands first. Only the first edit quotes text of P01, a line of its
  header, and the block of `CAYLEY_CARRIER` is the same at pin. Every table reads `applyMap` of
  P01, so no build holds these edits without P01.
- P03, `partner-sign`, quotes `CAYLEY_CONTAINER` below, so it lands after this change.
- The change `imports-narrow` names each symbol that `pga/operators.nim` imports. With both
  applied, the build stops on `undeclared identifier: 'CAYLEYS_SUPPORT'` under the rigid metric.
  Under the conformal metric, it stops on `undeclared identifier: 'CAYLEY_CARRIER_CO'`. Whichever
  of the two lands second adds `CAYLEYS_SUPPORT` in an import under `when IS_RIGID:`, and
  `CAYLEY_CARRIER_CO`, `CAYLEY_CENTER` and `CAYLEY_CONTAINER` to the conformal import. It
  drops `origin`, `horizon` and `infinity`, which no operator then reads.
- The change `doc-comments` writes in the header of `pga/operators.nim` that the support is
  written by hand. That line is stale once this change lands. Whichever of the two lands second
  drops `support` from that line.

## Edit `pga/cayleys.nim`

```nim
##       (attitude, carrier, duals, interior products).
```

```nim
##       (attitude, carrier, duals, interior products, chains folded to one table).
```

## Edit `pga/cayleys.nim`

```nim
when IS_CONFORMAL:
  const CAYLEY_CARRIER*: Cayley1D = block:
    var cayley = CAYLEYS_WEDGE.base
    cayley.applyConstant(Basis.infinity.toSigned, Chirality.Right)
```

```nim
when IS_RIGID:
  const CAYLEYS_SUPPORT* = block:
    var
      cayley = CAYLEYS_INTERIOR.base.weight.right
      cayley_anti = CAYLEYS_INTERIOR.anti.bulk.right
    let
      map = cayley.applyConstant(Basis.origin.toSigned, Chirality.Left)
      map_anti = cayley_anti.applyConstant(Basis.horizon, Chirality.Left)
    Spatial[Cayley2D](
      base: CAYLEYS_WEDGE.anti.applyMap(map, Chirality.Right),
      anti: CAYLEYS_WEDGE.base.applyMap(map_anti, Chirality.Right),
    )

when IS_CONFORMAL:
  const
    CAYLEY_CARRIER*: Cayley1D = block:
      var cayley = CAYLEYS_WEDGE.base
      cayley.applyConstant(Basis.infinity.toSigned, Chirality.Right)
    CAYLEY_CARRIER_CO*: Cayley1D = CAYLEY_CARRIER.applyMap(CAYLEYS_DUAL.anti.right)
    CAYLEY_CENTER*: Cayley2D = CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER_CO, Chirality.Left)
    CAYLEY_CONTAINER*: Cayley2D =
      CAYLEYS_INTERIOR.base.weight.right.applyMap(CAYLEY_CARRIER, Chirality.Right)
```

## Edit `pga/operators.nim`

```nim
when IS_CONFORMAL:
  defineOperator(
    symbols = "⊟",
    docs = "Get carrier of multivector, i.e. 𝐦 ∧ 𝐞ₙ.",
    cayley = CAYLEY_CARRIER,
  )
```

```nim
when IS_RIGID:
  defineOperator(
    symbols = "∩",
    docs = "Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).",
    cayley = CAYLEYS_SUPPORT.base,
    as_unary = true,
  )
  defineOperator(
    symbols = "∪",
    docs = "Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).",
    cayley = CAYLEYS_SUPPORT.anti,
    as_unary = true,
  )
when IS_CONFORMAL:
  defineOperator(
    symbols = "⊟",
    docs = "Get carrier of multivector, i.e. 𝐦 ∧ 𝐞ₙ.",
    cayley = CAYLEY_CARRIER,
  )
  defineOperator(
    symbols = "⊞",
    docs = "Get cocarrier of multivector, i.e. 𝐦☆ ∧ 𝐞ₙ.",
    cayley = CAYLEY_CARRIER_CO,
  )
  defineOperator(
    symbols = "⊙",
    docs = "Get center of multivector, i.e. 𝐦⊞ ∨ 𝐦.",
    cayley = CAYLEY_CENTER,
    as_unary = true,
  )
  defineOperator(
    symbols = "⊡",
    docs = "Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.",
    cayley = CAYLEY_CONTAINER,
    as_unary = true,
  )
```

## Edit `pga/operators.nim`

```nim
when IS_RIGID:
  func `∩`*(m: Multivector): Multivector =
    ## Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).
    const 𝐞ₙ = initElement(Basis.origin)
    m ∨ (𝐞ₙ ∧ ☆m)

  func `∪`*(m: Multivector): Multivector =
    ## Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).
    const 𝐞̄ₙ = block:
      let h = Basis.horizon
      h.basis.initElement(if h.is_negated: -1 else: 1)
    m ∧ (𝐞̄ₙ ∨ ★m)

when IS_CONFORMAL:
  func `⊞`*(m: Multivector): Multivector =
    ## Get cocarrier of multivector, i.e. 𝐦☆ ∧ 𝐞ₙ.
    const 𝐞ₙ = Basis.infinity.initElement()
    ☆m ∧ 𝐞ₙ

  func `⊙`*(m: Multivector): Multivector = ⊞m ∨ m
    ## Get center of multivector, i.e. 𝐦⊞ ∨ 𝐦.

  func `⊡`*(m: Multivector): Multivector = m ∧ ☆(⊟m)
    ## Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.

```

```nim
when IS_CONFORMAL:
```
