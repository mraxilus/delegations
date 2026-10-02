# Partner as two folded tables, its sign read by grade

The partner reads its operand's grade at run time, then scales by the sign of that grade. This
change folds that sign into the left read of its first table instead, by the grade of each
term. It also folds the carrier into the antiwedge that follows. So the partner is two
generated tables, read in a chain, and no grade scan.

## Edit `pga/cayleys.nim`

```nim
    CAYLEY_CONTAINER*: Cayley2D = # 𝐦 ∧ (𝐦⊟)☆, read with both operands 𝐦.
      CAYLEYS_WEDGE.base.applyMap(
        CAYLEYS_DUAL.anti.applyMap(CAYLEY_CARRIER),
        Chirality.Right,
      )
```

```nim
    CAYLEY_CONTAINER*: Cayley2D = # 𝐦 ∧ (𝐦⊟)☆, read with both operands 𝐦.
      CAYLEYS_WEDGE.base.applyMap(
        CAYLEYS_DUAL.anti.applyMap(CAYLEY_CARRIER),
        Chirality.Right,
      )
    CAYLEY_PARTNER_CONTAINER*: Cayley2D = block: # (-1)^(gr 𝐦 + 1) (𝐦☆)⊡, read with both 𝐦.
      # Sign rides left read alone, by grade of its term. Container is quadratic, so sign on
      #   both reads would square away; on one, it is exact for single-grade operand.
      var sign: Cayley1D
      for b in Basis: sign[b] = @[BasisSigned(basis: b, is_negated: int(b.grade) mod 2 == 0)]
      CAYLEY_CONTAINER
        .applyMap(CAYLEYS_DUAL.anti.applyMap(sign), Chirality.Left)
        .applyMap(CAYLEYS_DUAL.anti, Chirality.Right)
    CAYLEY_PARTNER_JOIN*: Cayley2D = # 𝐭 ∨ 𝐦⊟, i.e. antiwedge against carrier of second.
      CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER, Chirality.Right)
```

## Edit `pga/operators.nim`

```nim
  filter_product: static[seq[Grade]] = default(seq[Grade]);
  as_unary: static[bool] = false;
): untyped =
  ## Construct multivector product variant using provided Cayley table.
```

```nim
  filter_product: static[seq[Grade]] = default(seq[Grade]);
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
    let sign = float(-1^(int(m.grade.get) + 1))
    sign * ⊡( ☆ m) ∨ ⊟ m
```

```nim
  defineOperator(
    symbols = "containPartner",
    docs = "Get first step of partner, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡.",
    cayley = CAYLEY_PARTNER_CONTAINER,
    as_unary = true,
    is_public = false,
  )
  defineOperator(
    symbols = "joinCarrier",
    docs = "Get antiwedge of first operand with carrier of second, i.e. 𝐭 ∨ 𝐦⊟.",
    cayley = CAYLEY_PARTNER_JOIN,
    is_public = false,
  )

  func `⊛`*(m: Multivector): Multivector {.inline.} = joinCarrier(containPartner(m), m)
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    ##   Sign rides each term by its own grade, so operand of one grade is required; mixed
    ##     grade has no defined partner, and gets no check.
```
