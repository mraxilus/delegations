# Measure each conformal norm as the size of its own part

At pin, the round norms read `|∙²` and `|∘²`, and the flat norms compute `m ∙ m` and `m ∘ m`.
Each one takes the dot or the antidot of the whole multivector. Under the conformal metric the
antimetric is the negative of the metric, so one of the two roots is NaN for each nonzero
multivector. The book splits a conformal object into round bulk, round weight, flat bulk and flat
weight, and each norm measures the size of one part, in Section 4.3 and Table 4.12.

This change builds the squared norms from `CAYLEYS_PARTS`: each basis of a part times itself
lands on 𝟏 or 𝟙. Under the rigid metric that table equals the dot and antidot tables, cell for
cell, so nothing changes there. It adds `|■²` and `|□²` for the flat parts. It fills the stubs of
the center norm, (4.43), and of the radius norm, (4.45). The center norm lands on 𝟏, as a weighted
distance, and the radius norm on 𝟙, as the antidot gives it.

Unitization divides by the round weight norm, as the book says for a round object. A flat object
has no round weight, so its flat weight serves, as at pin, where `m ∘ m` of a flat object is the
square of its flat weight. Chapter 4 gains three suites, from Tables 4.12 and 4.13 and Section 4.3.

## Edit `pga/cayleys.nim`

```nim
  CAYLEYS_NORM_SQUARED* = block:
    var cayleys = CAYLEYS_DOT
    cayleys.base.filterGrades(products = @[Grade.low])
    cayleys.anti.filterGrades(products = @[Grade.high])
    cayleys
```

```nim
  CAYLEYS_NORM_SQUARED* = Partial[Formal[Cayley2D]](
    bulk: constructSizes(CAYLEYS_PARTS.bulk, Basis.scalar),
    weight: constructSizes(CAYLEYS_PARTS.weight, Basis.scalarAnti),
  )
```

## Edit `pga/cayleys.nim`

```nim
      round: constructPart(inclusions, exclusions & @[Basis.infinity]),
      flat: constructPart(inclusions & @[Basis.infinity], exclusions),
    )
```

```nim
      round: constructPart(inclusions, exclusions & @[Basis.infinity]),
      flat: constructPart(inclusions & @[Basis.infinity], exclusions),
    )


func constructSizes(parts: Formal[Cayley1D], basis: Basis): Formal[Cayley2D] {.compileTime.} =
  ## Construct Cayley table for squared size of each (round/flat) part.
  ##   Each basis of part times itself lands on given basis, i.e. sum of squares of part's
  ##   coefficients, as book's conformal norms measure (Table 4.12).
  ##   E.g. this is, in RGA, equal to dot table for bulk and antidot table for weight.

  func constructSize(part: Cayley1D): Cayley2D {.compileTime.} =
    ## Construct Cayley table for squared size of one part.
    for b in Basis:
      if part[b].len > 0:
        result[b][b] = @[basis.toSigned]

  when IS_RIGID:
    Formal[Cayley2D](round: constructSize(parts.round))
  else:
    Formal[Cayley2D](round: constructSize(parts.round), flat: constructSize(parts.flat))
```

## Edit `pga/operators.nim`

```nim
  I.e. ‖𝐦‖∙² = 𝐦∙𝐦.""",
  cayley = CAYLEYS_NORM_SQUARED.base,
  as_unary = true,
)
```

```nim
  I.e. ‖𝐦‖∙² = 𝐦∙𝐦 in RGA, and sum of squares of round bulk components in CGA.""",
  cayley = CAYLEYS_NORM_SQUARED.bulk.round,
  as_unary = true,
)
```

## Edit `pga/operators.nim`

```nim
  I.e. ‖𝐦‖∘² = 𝐦∘𝐦.""",
  cayley = CAYLEYS_NORM_SQUARED.anti,
  as_unary = true,
)
```

```nim
  I.e. ‖𝐦‖∘² = 𝐦∘𝐦 in RGA, and sum of squares of round weight components in CGA.""",
  cayley = CAYLEYS_NORM_SQUARED.weight.round,
  as_unary = true,
)
when IS_CONFORMAL:
  defineOperator(
    symbols = "|■²",
    docs = """Get flat bulk squared norm of multivector,
    as squared size of flat bulk components.""",
    cayley = CAYLEYS_NORM_SQUARED.bulk.flat,
    as_unary = true,
  )
  defineOperator(
    symbols = "|□²",
    docs = """Get flat weight squared norm of multivector,
    as squared size of flat weight components.""",
    cayley = CAYLEYS_NORM_SQUARED.weight.flat,
    as_unary = true,
  )
```

## Edit `pga/operators.nim`

```nim
  func `|■`*(m: Multivector): Multivector {.inline.} =
    ## Get flat bulk norm of multivector as size of flat bulk components, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
    result[Basis.scalar] = (m ∙ m)[Basis.scalar].sqrt

  func `|□`*(m: Multivector): Multivector {.inline.} =
    ## Get flat weight norm of multivector as size of flat weight components, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦).
    result[Basis.scalarAnti] = (m ∘ m)[Basis.scalarAnti].sqrt
```

```nim
  func `|■`*(m: Multivector): Multivector {.inline.} =
    ## Get flat bulk norm of multivector as size of flat bulk components, i.e. ‖𝐦‖■.
    result[Basis.scalar] = (`|■²`m)[Basis.scalar].sqrt

  func `|□`*(m: Multivector): Multivector {.inline.} =
    ## Get flat weight norm of multivector as size of flat weight components, i.e. ‖𝐦‖□.
    result[Basis.scalarAnti] = (`|□²`m)[Basis.scalarAnti].sqrt

  func `|⊙`*(m: Multivector): Multivector {.inline.} =
    ## Get center norm of multivector, i.e. ‖𝐦‖⊙ = √(‖𝐦‖∙² + ‖𝐦‖□²) (4.43).
    ##   Weighted distance from origin to center; divide by round weight norm for distance.
    result[Basis.scalar] = sqrt((`|∙²`m)[Basis.scalar] + (`|□²`m)[Basis.scalarAnti])

  func `|⊘`*(m: Multivector): Multivector {.inline.} =
    ## Get radius norm of multivector, i.e. ‖𝐦‖⊘ = √(𝐦∘𝐦) (4.45).
    ##   Weighted radius; NaN for imaginary object, whose 𝐦∘𝐦 is negative.
    result[Basis.scalarAnti] = (m ∘ m)[Basis.scalarAnti].sqrt
```

## Edit `pga/operators.nim`

```nim
  ##   Performs no-op where bulk norm is 0.
  let
    m_norm_bulk = (`|∙²`m)[Basis.scalar].sqrt
```

```nim
  ##   Performs no-op where bulk norm is 0.
  ##   In CGA, flat object has no round bulk, so its flat bulk norm serves.
  let
    m_norm_bulk = when IS_CONFORMAL:
        let round = (`|∙²`m)[Basis.scalar]
        (if round != 0: round else: (`|■²`m)[Basis.scalar]).sqrt
      else:
        (`|∙²`m)[Basis.scalar].sqrt
```

## Edit `pga/operators.nim`

```nim
  ##   Performs no-op where weight norm is 0.
  let
    m_norm_weight = (`|∘²`m)[Basis.scalarAnti].sqrt
```

```nim
  ##   Performs no-op where weight norm is 0.
  ##   In CGA, flat object has no round weight, so its flat weight norm serves (Section 4.3).
  let
    m_norm_weight = when IS_CONFORMAL:
        let round = (`|∘²`m)[Basis.scalarAnti]
        (if round != 0: round else: (`|□²`m)[Basis.scalarAnti]).sqrt
      else:
        (`|∘²`m)[Basis.scalarAnti].sqrt
```

## Edit `pga.nim`

```nim
  func normCenter*(m: Multivector): Multivector {.inline, error: "TODO:  |⊙m".}
    ## Get center norm of multivector.

  func normRadius*(m: Multivector): Multivector {.inline, error: "TODO:  |⊘m".}
    ## Get radius norm of multivector.
```

```nim
  func normCenter*(m: Multivector): Multivector {.inline.} = |⊙m
    ## Get center norm of multivector as weighted distance from origin to its center.

  func normRadius*(m: Multivector): Multivector {.inline.} = |⊘m
    ## Get radius norm of multivector as its weighted radius, NaN where it is imaginary.
```

## Edit `tests/suites.nim`

```nim
  test "TODO: Add chapter 4 tests":
    skip()
```

```nim
  test "Table 4.12: four norms measure four parts":
    when IS_CONFORMAL and DIMENSIONS == 5:
      # Round bulk, round weight, flat bulk and flat weight of each object, by Table 4.11.
      let objects: seq[array[4, seq[Basis]]] = @[
        [@[], @[], @[E15, E25, E35], @[E45]],  # flat point
        [@[], @[], @[E235, E315, E125], @[E415, E425, E435]],  # line
        [@[], @[], @[E3215], @[E4235, E4315, E4125]],  # plane
        [@[E1, E2, E3], @[E4], @[E5], @[]],  # round point
        [@[E23, E31, E12], @[E41, E42, E43], @[E15, E25, E35], @[E45]],  # dipole
        [@[E321], @[E423, E431, E412], @[E235, E315, E125], @[E415, E425, E435]],  # circle
        [@[], @[E1234], @[E3215], @[E4235, E4315, E4125]],  # sphere
      ]
      for parts in objects:
        for _ in 1..SAMPLES div 8:
          var
            𝐮: Multivector
            sizes: array[4, float]
          for i, part in parts:
            for b in part:
              𝐮[b] = gauss()
              sizes[i] += 𝐮[b] ^ 2
          check |∙𝐮 =~ initElement(Basis.scalar, sizes[0].sqrt)  # 4.12, round bulk
          check |∘𝐮 =~ initElement(Basis.scalarAnti, sizes[1].sqrt)  # 4.12, round weight
          check |■𝐮 =~ initElement(Basis.scalar, sizes[2].sqrt)  # 4.12, flat bulk
          check |□𝐮 =~ initElement(Basis.scalarAnti, sizes[3].sqrt)  # 4.12, flat weight

    else: skip()

  test "Table 4.13: center and radius norms of round objects":
    when IS_CONFORMAL and DIMENSIONS == 5:
      for _ in 1..SAMPLES:
        var 𝐚, 𝐝, 𝐜, 𝐬: Multivector
        for b in [E1, E2, E3, E4, E5]: 𝐚[b] = gauss()
        for b in [E23, E31, E12, E41, E42, E43, E15, E25, E35, E45]: 𝐝[b] = gauss()
        for b in [E321, E423, E431, E412, E235, E315, E125, E415, E425, E435]: 𝐜[b] = gauss()
        for b in [E1234, E3215, E4235, E4315, E4125]: 𝐬[b] = gauss()
        let
          centers = [
            𝐚[E1]^2 + 𝐚[E2]^2 + 𝐚[E3]^2,
            𝐝[E23]^2 + 𝐝[E31]^2 + 𝐝[E12]^2 + 𝐝[E45]^2,
            𝐜[E321]^2 + 𝐜[E415]^2 + 𝐜[E425]^2 + 𝐜[E435]^2,
            𝐬[E4235]^2 + 𝐬[E4315]^2 + 𝐬[E4125]^2,
          ]
          radii = [
            2*𝐚[E4]*𝐚[E5] - 𝐚[E1]^2 - 𝐚[E2]^2 - 𝐚[E3]^2,
            𝐝[E45]^2 - 𝐝[E23]^2 - 𝐝[E31]^2 - 𝐝[E12]^2 -
              2*(𝐝[E15]*𝐝[E41] + 𝐝[E25]*𝐝[E42] + 𝐝[E35]*𝐝[E43]),
            𝐜[E415]^2 + 𝐜[E425]^2 + 𝐜[E435]^2 - 𝐜[E321]^2 +
              2*(𝐜[E423]*𝐜[E235] + 𝐜[E431]*𝐜[E315] + 𝐜[E412]*𝐜[E125]),
            𝐬[E4235]^2 + 𝐬[E4315]^2 + 𝐬[E4125]^2 - 2*𝐬[E3215]*𝐬[E1234],
          ]
        for i, 𝐮 in [𝐚, 𝐝, 𝐜, 𝐬]:
          check |⊙𝐮 =~ initElement(Basis.scalar, centers[i].sqrt)  # 4.43, Table 4.13
          check 𝐮 ∘ 𝐮 =~ initElement(Basis.scalarAnti, radii[i])  # 4.45, Table 4.13
          if radii[i] >= 0:
            check |⊘𝐮 =~ initElement(Basis.scalarAnti, radii[i].sqrt)  # 4.45, real object

    else: skip()

  test "Section 4.3: round object unitizes by round weight, flat object by flat weight":
    when IS_CONFORMAL and DIMENSIONS == 5:
      for _ in 1..SAMPLES:
        var 𝐬, 𝐩: Multivector
        for b in [E1234, E3215, E4235, E4315, E4125]: 𝐬[b] = gauss()
        for b in [E15, E25, E35, E45]: 𝐩[b] = gauss()
        check |∘(^𝐬) =~ 𝟙  # round weight norm of unitized sphere
        check |□(^𝐩) =~ 𝟙  # flat weight norm of unitized flat point

    else: skip()
```
