# Unitize any element by one rule

At pin, unitization divides every element by its round weight norm. A flat object has no round
weight, so it stays as it is. This change divides an element by a divisor W(𝐦). In the rigid
algebra, W(𝐦) is the weight norm √(𝐦 ∘ 𝐦), as at pin. In the conformal algebra, W(𝐦) is the round
weight norm for a round object, and √|𝐦 ∘ 𝐦| for any other element.

A round object holds one grade, and its round weight is not negligible beside √|𝐦 ∘ 𝐦|. The
façade and the doc of `^` state the rule, and a line under the table of norm operators defines
W(𝐦). The doc of the weight norm says that √(𝐦 ∘ 𝐦) is that norm in the rigid algebra alone.
This change also drops `inline` from `^∘`, since its conformal body is large. Chapter 4 gains one
test at its head, and keeps its placeholder, which change `conformal-norms` replaces. Suite
Internal gains one test for motion operators, moved elements, and a plane sent through a sphere
and back.

This change applies at pin and builds on no other. Other edits reach code that this change
touches:

- P06, `float-width`, quotes no line of this change. Two locals here start at the float `0.0`:
  `largest` in `^∘` and `distance_squared` in `samplePoint`. Each compiles at 32 bits. Once both
  land, the second to land declares them `Coefficient`.
- P07, `part-scale`, removes the private `=~` of two scalars. The test of suite Internal compares
  two multivectors through the public `=~` instead, so the two build together in either order.
- The change `algebra-hygiene` renames `TOLERANCE_ABS`, which `^∘` names. The second to land
  carries the new name into `^∘`.
- The change `doc-comments` writes that `^` and `normalizeWeight` cost no call. With this change
  `^∘` is not inline, so each costs one. Once both land, that doc says so.
- The changes `doc-comments` and `doc-comments-2` edit docs next to `unitize` and `^` through
  quotes of their own, so either order holds. So does the change `conformal-norms`, which
  replaces the placeholder of Chapter 4 that this change keeps.

## Edit `pga.nim`

```nim
##   | ^∘  | normalizeWeight   | 𝐦 ÷ ‖𝐦‖∘    |
##   |-----|-------------------|-------------|
```

```nim
##   | ^∘  | normalizeWeight   | 𝐦 ÷ W(𝐦)    |
##   |-----|-------------------|-------------|
##   W(𝐦): coined divisor, ‖𝐦‖∘ for round object in CGA, else √|𝐦∘𝐦|; Lengyel gives none.
```

## Edit `pga.nim`

```nim
func normalizeWeight*(m: Multivector): Multivector {.inline.} = ^∘m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. |𝐦|∘ = 𝟙.

func unitize*(m: Multivector): Multivector {.inline.} = ^m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. 𝐦̂ = 𝐦 / ‖𝐦‖∘.
```

```nim
func normalizeWeight*(m: Multivector): Multivector {.inline.} = ^∘m
  ## Normalize multivector so its weight has unit antiscalar magnitude, i.e. 𝐦 ÷ W(𝐦).
  ##   In RGA, W(𝐦) = ‖𝐦‖∘ = √(𝐦∘𝐦) for any element.
  ##   In CGA, W(𝐦) = ‖𝐦‖∘ for round object, i.e. weight of its carrier 𝐦 ∧ 𝐞∞; else √|𝐦∘𝐦|.
  ##     Round object holds one grade, and its round weight is not negligible beside √|𝐦∘𝐦|.
  ##     Each test counts size at or under tolerance times scale it is compared with as zero.
  ##   Performs no-op where W(𝐦) is 0.

func unitize*(m: Multivector): Multivector {.inline.} = ^m
  ## Normalize multivector so its weight has unit antiscalar magnitude, i.e. 𝐦̂ = 𝐦 ÷ W(𝐦).
```

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
func `^∘`*(m: Multivector): Multivector {.noinit.} =
  ## Normalize multivector so its weight has unit antiscalar magnitude (𝟙), i.e. 𝐦 ÷ W(𝐦).
  ##   W(𝐦) is round weight norm for round object in CGA, else √|𝐦∘𝐦|; see `normalizeWeight`.
  ##   Performs no-op where W(𝐦) is 0.
  when IS_CONFORMAL:
    let
      m_norm_weight_round_squared = (`|∘²`m)[Basis.scalarAnti]
      m_norm_radius_squared = abs((`|⊘²`m)[Basis.scalarAnti])
    var is_round =
      m_norm_weight_round_squared > TOLERANCE_ABS * TOLERANCE_ABS * m_norm_radius_squared
    if is_round:  # Scan grades only where round weight passes, and stop at second grade.
      var
        largest = 0.0
        found_grade = false
        grade_first = Grade.low
      for b in Basis: largest = max(largest, abs(m[b]))
      for b in Basis:
        if abs(m[b]) <= TOLERANCE_ABS * largest: continue
        if not found_grade:
          found_grade = true
          grade_first = b.grade
        elif b.grade != grade_first:
          is_round = false
          break
    let divisor = (if is_round: m_norm_weight_round_squared else: m_norm_radius_squared).sqrt
  else:
    let divisor = (`|∘²`m)[Basis.scalarAnti].sqrt
  let reciprocal = if divisor != 0: 1.0 / divisor else: 1.0
  for b in Basis:
    result[b] = m[b] * reciprocal
```

## Edit `pga/operators.nim`

```nim
template `^`*(m: Multivector): Multivector = ^∘m
  ## Normalize multivector so weight norm has unit antiscalar magnitude (𝟙).
  ##   I.e. 𝐦̂ = 𝐦 ÷ ‖𝐦‖∘.
```

```nim
template `^`*(m: Multivector): Multivector = ^∘m
  ## Normalize multivector so its weight has unit antiscalar magnitude (𝟙).
  ##   I.e. 𝐦̂ = 𝐦 ÷ W(𝐦); see `normalizeWeight`.
```

## Edit `tests/suites.nim`

```nim
  m div (norm[Basis.scalar] + norm[Basis.scalarAnti])



suite "Internal":
```

```nim
  m div (norm[Basis.scalar] + norm[Basis.scalarAnti])


when IS_CONFORMAL:
  proc samplePoint(): Multivector =
    ## Sample round point at random position, of radius zero.
    var distance_squared = 0.0
    for b in Basis.scalar.succ..Basis.origin.pred:
      result[b] = gauss()
      distance_squared += result[b]^2
    result[Basis.origin] = 1
    result[Basis.infinity] = distance_squared / 2


  proc sampleReflector(): Multivector =
    ## Sample random sphere or plane, any element of antigrade one.
    for b in Basis:
      if b.grade == Grade.high.pred: result[b] = gauss()



suite "Internal":
  test "`^∘`(m: Multivector): Multivector":
    when IS_RIGID: skip()  # Round and flat objects exist in CGA alone.
    else:
      const 𝐞∞ = initElement(Basis.infinity)
      for _ in 1 .. SAMPLES div 8:
        let 𝐯 = ^(3 ∧ (sampleReflector() ⟇ sampleReflector()))
        check abs((𝐯 ∘ 𝐯)[Basis.scalarAnti]) ∧ 𝟙 =~ 𝟙  # Product of two reflections ends unit.
        let 𝐦 = 𝐯 ⟇ samplePoint() ⟇ ~∘𝐯
        check |∘(^𝐦) =~ 𝟙  # Moved round point keeps unit round weight.

        var 𝐬, 𝐠 = samplePoint()
        for _ in 2 ..< DIMENSIONS - 1:
          𝐬 = 𝐬 ∧ samplePoint()
          𝐠 = 𝐠 ∧ samplePoint()
        𝐬 = 𝐬 ∧ samplePoint()
        𝐠 = 𝐠 ∧ 𝐞∞
        let 𝐠_back = 𝐬 ⟇ (𝐬 ⟇ 𝐠 ⟇ ~∘𝐬) ⟇ ~∘𝐬
        check |□(^𝐠_back) =~ 𝟙  # Plane through sphere and back keeps unit flat weight.


```

## Edit `tests/suites.nim`

```nim
suite "Chapter 4":
```

```nim
suite "Chapter 4":
  test "Section 4.3: round object unitizes by round weight, flat object by flat weight":
    when IS_RIGID: skip()  # Round and flat objects exist in CGA alone.
    else:
      const 𝐞∞ = initElement(Basis.infinity)
      for _ in 1 .. SAMPLES div 8:
        let 𝐫 = samplePoint()
        check 𝐫 ∘ 𝐫 =~ 0  # 4.45
        var 𝐮 = 𝐫
        for grade in 1..<DIMENSIONS:
          let scale = 3 * gauss()
          check |∘(^(scale ∧ 𝐮)) =~ 𝟙  # Section 4.3, round object
          if grade < DIMENSIONS - 1:
            check |□(^(scale ∧ (𝐮 ∧ 𝐞∞))) =~ 𝟙  # Section 4.3, flat object
          𝐮 = 𝐮 ∧ samplePoint()


```
