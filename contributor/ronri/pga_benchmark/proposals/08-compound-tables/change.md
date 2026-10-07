# One table for each compound operator, as edits on P01

Each compound operator of the book reads one table that P01's rules derive, so it runs as one
product. At pin, each one is a chain of dense products, with a multivector between each step.

## Edit `pga/cayleys.nim`

```nim
##       (attitude, carrier, duals, interior products).
```

```nim
##       (attitude, carrier, duals, interior products, compound products).
```

## Edit `pga/cayleys.nim`

```nim
when IS_CONFORMAL:
  const CAYLEY_CARRIER*: Cayley1D = block:
    var cayley = CAYLEYS_WEDGE.base
    cayley.applyConstant(Basis.infinity.toSigned, Chirality.Right)
```

```nim
when IS_CONFORMAL:
  const CAYLEY_CARRIER*: Cayley1D = block:
    var cayley = CAYLEYS_WEDGE.base
    cayley.applyConstant(Basis.infinity.toSigned, Chirality.Right)
  const
    CAYLEY_CARRIER_CO*: Cayley1D =  # 𝐦☆ ∧ 𝐞ₙ, i.e. dual, then carrier.
      CAYLEY_CARRIER.applyMap(CAYLEYS_DUAL.anti.right)
    CAYLEY_CENTER*: Cayley2D =  # 𝐦⊞ ∨ 𝐦, read with both operands 𝐦.
      CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER_CO, Chirality.Left)
    CAYLEY_CONTAINER*: Cayley2D =  # 𝐦 ∧ (𝐦⊟)☆, read with both operands 𝐦.
      CAYLEYS_WEDGE.base.applyMap(
        CAYLEYS_DUAL.anti.right.applyMap(CAYLEY_CARRIER),
        Chirality.Right,
      )

when IS_RIGID:
  const
    CAYLEY_SUPPORT*: Cayley2D = block:  # 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆), read with both operands 𝐦.
      var wedge = CAYLEYS_WEDGE.base
      let origin = wedge.applyConstant(Basis.origin.toSigned, Chirality.Left)
      CAYLEYS_WEDGE.anti.applyMap(origin.applyMap(CAYLEYS_DUAL.anti.right), Chirality.Right)
    CAYLEY_SUPPORT_ANTI*: Cayley2D = block:  # 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★), read with both operands 𝐦.
      var antiwedge = CAYLEYS_WEDGE.anti
      let horizon = antiwedge.applyConstant(Basis.horizon, Chirality.Left)
      CAYLEYS_WEDGE.base.applyMap(horizon.applyMap(CAYLEYS_DUAL.base.right), Chirality.Right)
```

## Edit `pga/operators.nim`

```nim
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
  defineOperator(
    symbols = "∩",
    docs = "Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).",
    cayley = CAYLEY_SUPPORT,
    as_unary = true,
  )
  defineOperator(
    symbols = "∪",
    docs = "Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).",
    cayley = CAYLEY_SUPPORT_ANTI,
    as_unary = true,
  )

when IS_CONFORMAL:
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
