# Unitize any element by one rule

At pin, unitization divides every element by its round weight norm. A flat object has no round
weight, so it stays as it is. This change keeps the rigid rule, and divides any element by
√|𝐦 ∘ 𝐦|, as Lengyel's rigid unitization does. In the conformal algebra, a round object divides by
its round weight norm instead, which is the weight of its carrier. A round object holds one
grade, and its round weight is not negligible beside √|𝐦 ∘ 𝐦|.

The doc of the weight norm also says that √(𝐦 ∘ 𝐦) is the weight norm in the rigid algebra
alone. Chapter 4 gains one suite, over every conformal dimension.

## Edit `pga/operators.nim`

```nim
func `|∘`*(m: Multivector): Multivector {.inline.} =
  ## Get (round) weight norm of multivector as size of (round) weight components.
  ##   I.e. ‖𝐦‖∘ = √(𝐦∘𝐦).
```

```nim
func `|∘`*(m: Multivector): Multivector {.inline.} =
  ## Get (round) weight norm of multivector as size of (round) weight components.
  ##   In RGA, ‖𝐦‖∘ = √(𝐦∘𝐦); in CGA, √(𝐦∘𝐦) is radius norm ‖𝐦‖⊘ instead (4.45).
```

## Edit `pga/operators.nim`

```nim
func `^∘`*(m: Multivector): Multivector {.inline, noinit.} =
  ## Normalize multivector so weight norm has unit antiscalar magnitude (𝟙).
  ##   I.e. 𝐦̂∘ = 𝐦 ÷ ‖𝐦‖∘.
  ##   Performs no-op where weight norm is 0.
  let
    m_norm_weight = (`|∘²`m)[Basis.scalarAnti].sqrt
    reciprocal = if m_norm_weight != 0: 1.0 / m_norm_weight else: 1.0
  for b in Basis:
    result[b] = m[b] * reciprocal
```

```nim
func `^∘`*(m: Multivector): Multivector {.inline, noinit.} =
  ## Normalize multivector so weight norm has unit antiscalar magnitude (𝟙).
  ##   I.e. 𝐦̂∘ = 𝐦 ÷ ‖𝐦‖∘, where ‖𝐦‖∘ = √|𝐦∘𝐦| for any element, as RGA unitizes.
  ##   In CGA, round object divides by round weight norm, i.e. weight of its carrier 𝐦 ∧ 𝐞∞.
  ##     Round object holds one grade, and its round weight is not negligible beside √|𝐦∘𝐦|.
  ##     Both tests count size at or under tolerance times scale it is compared with as zero.
  ##   Performs no-op where divisor is 0.
  when IS_CONFORMAL:
    let
      m_norm_weight_round_squared = (`|∘²`m)[Basis.scalarAnti]
      m_norm_radius_squared = abs((`|⊘²`m)[Basis.scalarAnti])
    var is_round =
      m_norm_weight_round_squared > TOLERANCE_ABS * TOLERANCE_ABS * m_norm_radius_squared
    if is_round:  # Scan grades only where round weight passes, and stop at second grade.
      var
        scale = 0.0
        found_grade = false
        grade_first = Grade.low
      for b in Basis: scale = max(scale, abs(m[b]))
      for b in Basis:
        if abs(m[b]) <= TOLERANCE_ABS * scale: continue
        if not found_grade:
          found_grade = true
          grade_first = b.grade
        elif b.grade != grade_first:
          is_round = false
          break
    let m_norm_weight =
      (if is_round: m_norm_weight_round_squared else: m_norm_radius_squared).sqrt
  else:
    let m_norm_weight = (`|∘²`m)[Basis.scalarAnti].sqrt
  let reciprocal = if m_norm_weight != 0: 1.0 / m_norm_weight else: 1.0
  for b in Basis:
    result[b] = m[b] * reciprocal
```

## Edit `tests/suites.nim`

```nim
suite "Chapter 4":
```

```nim
suite "Chapter 4":
  test "Section 4.3: round object unitizes by round weight, any other element by weight norm":
    when IS_CONFORMAL:
      const 𝐞∞ = Basis.infinity.initElement()

      proc drawPoint(): Multivector =
        ## Draw round point at random position, of radius zero.
        var distance_squared = 0.0
        for b in Basis.scalar.succ .. Basis.origin.pred:
          result[b] = gauss()
          distance_squared += result[b]^2
        result[Basis.origin] = 1
        result[Basis.infinity] = distance_squared / 2

      proc drawReflector(): Multivector =
        ## Draw random sphere or plane, any element of antigrade one.
        for b in Basis:
          if b.grade == Grade.high.pred: result[b] = gauss()

      for _ in 1..SAMPLES div 8:
        let 𝐫 = drawPoint()
        check 𝐫 ∘ 𝐫 =~ 0  # 4.45, round point of real position has radius zero
        var 𝐮 = 𝐫
        for grade in 1 ..< DIMENSIONS:
          let scale = 3 * gauss()
          check |∘(^(scale ∧ 𝐮)) =~ 𝟙  # Section 4.3, round object
          if grade < DIMENSIONS - 1:
            check |□(^(scale ∧ (𝐮 ∧ 𝐞∞))) =~ 𝟙  # Section 4.3, flat object as rigid weight
          𝐮 = 𝐮 ∧ drawPoint()

        let 𝐯 = ^(3 ∧ (drawReflector() ⟇ drawReflector()))
        check abs((𝐯 ∘ 𝐯)[Basis.scalarAnti]) =~ 1  # versor of two reflections, unit
        let 𝐦 = 𝐯 ⟇ drawPoint() ⟇ ~∘𝐯
        check |∘(^𝐦) =~ 𝟙  # moved round point keeps round weight unit

        var 𝐬, 𝐠 = drawPoint()
        for _ in 2 ..< DIMENSIONS - 1:
          𝐬 = 𝐬 ∧ drawPoint()
          𝐠 = 𝐠 ∧ drawPoint()
        𝐬 = 𝐬 ∧ drawPoint()
        𝐠 = 𝐠 ∧ 𝐞∞
        let 𝐠_back = 𝐬 ⟇ (𝐬 ⟇ 𝐠 ⟇ ~∘𝐬) ⟇ ~∘𝐬
        check |□(^𝐠_back) =~ 𝟙  # plane through sphere and back keeps flat weight, not residue

    else: skip()
```
