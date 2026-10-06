# Make the width of each float configurable

At pin, each element of a multivector is a 64-bit `float`, and no build option changes it. This
change adds the define `pga.float_bits`, 64 by default or 32, and the type `Real` that it
selects. Each element, scalar operand and comparison takes `Real` in place of `float`. At 64 bits
`Real` and `float` name one type, so the library emits the same C as pin.

## Edit `pga/algebra.nim`

```nim
  # Avoid small-value comparison failures.
  TOLERANCE_PLACES* {.define: "pga.tolerance_places".} = 9
  TOLERANCE_ABS* = 10.pow(-TOLERANCE_PLACES.float)
```

```nim
  # Choose width of each element: 64 bits, or 32 to halve every multivector.
  FLOAT_BITS* {.define: "pga.float_bits".} = 64

  # Avoid small-value comparison failures; 32-bit element holds about seven places.
  TOLERANCE_PLACES* {.define: "pga.tolerance_places".} = (when FLOAT_BITS == 32: 5 else: 9)

type Real* = (when FLOAT_BITS == 32: float32 else: float64)
  ## Define element of every multivector, as wide as `FLOAT_BITS` says.

const TOLERANCE_ABS* = Real(10.pow(-TOLERANCE_PLACES.float))
```

## Edit `pga/algebra.nim`

```nim
static:
```

```nim
static:
  doAssert FLOAT_BITS in [32, 64], &"Float width should be 32 or 64 bits; got `{FLOAT_BITS}`."
```

## Edit `pga/multivectors.nim`

```nim
    elements: array[Basis, float]
```

```nim
    elements: array[Basis, Real]
```

## Edit `pga/multivectors.nim`

```nim
template `[]`*(m: var Multivector, b: Basis): var float = m.elements[b]
```

```nim
template `[]`*(m: var Multivector, b: Basis): var Real = m.elements[b]
```

## Edit `pga/multivectors.nim`

```nim
template `[]`*(m: Multivector, b: Basis): float = m.elements[b]
```

```nim
template `[]`*(m: Multivector, b: Basis): Real = m.elements[b]
```

## Edit `pga/multivectors.nim`

```nim
func initElement*(b: Basis, scalar: float = 1'f): Multivector =
```

```nim
func initElement*(b: Basis, scalar: Real = 1'f): Multivector =
```

## Edit `pga/multivectors.nim`

```nim
      params = nnkFormalParams.newTree(ident"Multivector", newIdentDefs(ident"f", ident"float")),
```

```nim
      params = nnkFormalParams.newTree(ident"Multivector", newIdentDefs(ident"f", ident"Real")),
```

## Edit `pga/multivectors.nim`

```nim
func `=~`(a, b: float): bool =
```

```nim
func `=~`(a, b: Real): bool =
```

## Edit `pga/multivectors.nim`

```nim
func `=~`*(m: Multivector, s: float): bool =
```

```nim
func `=~`*(m: Multivector, s: Real): bool =
```

## Edit `pga/multivectors.nim`

```nim
template `=~`*(s: float, m: Multivector): bool =
```

```nim
template `=~`*(s: Real, m: Multivector): bool =
```

## Edit `pga/multivectors.nim`

```nim
func `+`*(s: float, m: Multivector): Multivector {.inline, noinit.} =
```

```nim
func `+`*(s: Real, m: Multivector): Multivector {.inline, noinit.} =
```

## Edit `pga/multivectors.nim`

```nim
template `+`*(m: Multivector, s: float): Multivector =
```

```nim
template `+`*(m: Multivector, s: Real): Multivector =
```

## Edit `pga/multivectors.nim`

```nim
func `-`*(s: float, m: Multivector): Multivector {.inline, noinit.} =
```

```nim
func `-`*(s: Real, m: Multivector): Multivector {.inline, noinit.} =
```

## Edit `pga/multivectors.nim`

```nim
func `-`*(m: Multivector, s: float): Multivector {.inline, noinit.} =
```

```nim
func `-`*(m: Multivector, s: Real): Multivector {.inline, noinit.} =
```

## Edit `pga/operators.nim`

```nim
func `∧`*(s: float, m: Multivector): Multivector {.inline, noinit.} =
```

```nim
func `∧`*(s: Real, m: Multivector): Multivector {.inline, noinit.} =
```

## Edit `pga/operators.nim`

```nim
template `∧`*(m: Multivector, s: float): Multivector =
```

```nim
template `∧`*(m: Multivector, s: Real): Multivector =
```

## Edit `pga/operators.nim`

```nim
template `*`*(s: float, m: Multivector): Multivector =
```

```nim
template `*`*(s: Real, m: Multivector): Multivector =
```

## Edit `pga/operators.nim`

```nim
template `*`*(m: Multivector, s: float): Multivector =
```

```nim
template `*`*(m: Multivector, s: Real): Multivector =
```

## Edit `pga/operators.nim`

```nim
    let sign = float(-1 ^ (int(m.grade.get) + 1))
```

```nim
    let sign = Real(-1^(int(m.grade.get) + 1))
```

## Edit `pga.nim`

```nim
func selectPart*(m: Multivector, b: Basis): float {.inline.} = m[b]
```

```nim
func selectPart*(m: Multivector, b: Basis): Real {.inline.} = m[b]
```

## Edit `pga.nim`

```nim
func add*(m: Multivector, s: float): Multivector {.inline.} = s + m
```

```nim
func add*(m: Multivector, s: Real): Multivector {.inline.} = s + m
```

## Edit `pga.nim`

```nim
func add*(s: float, m: Multivector): Multivector {.inline.} = s + m
```

```nim
func add*(s: Real, m: Multivector): Multivector {.inline.} = s + m
```

## Edit `pga.nim`

```nim
func subtract*(m: Multivector, s: float): Multivector {.inline.} = m - s
```

```nim
func subtract*(m: Multivector, s: Real): Multivector {.inline.} = m - s
```

## Edit `pga.nim`

```nim
func subtract*(s: float, m: Multivector): Multivector {.inline.} = s - m
```

```nim
func subtract*(s: Real, m: Multivector): Multivector {.inline.} = s - m
```

## Edit `pga.nim`

```nim
func wedge*(m: Multivector, s: float): Multivector {.inline.} = s ∧ m
```

```nim
func wedge*(m: Multivector, s: Real): Multivector {.inline.} = s ∧ m
```

## Edit `pga.nim`

```nim
func wedge*(s: float, m: Multivector): Multivector {.inline.} = s ∧ m
```

```nim
func wedge*(s: Real, m: Multivector): Multivector {.inline.} = s ∧ m
```

## Edit `tests/suites.nim`

```nim
func `div`*(m: Multivector, norm: float): Multivector =
```

```nim
func `div`*(m: Multivector, norm: Real): Multivector =
```

## Edit `tests/suites.nim`

```nim
      let sign = float(-1 ^ (int(b.grade) * int(c.grade)))
```

```nim
      let sign = Real(-1^(int(b.grade) * int(c.grade)))
```

## Edit `tests/suites.nim`

```nim
        𝐮̅[c] = float(-1^(int(b.grade) * int(b.gradeAnti))) * 𝐮̅[c]
```

```nim
        𝐮̅[c] = Real(-1^(int(b.grade) * int(b.gradeAnti))) * 𝐮̅[c]
```

## Edit `tests/suites.nim`

```nim
      check /(/𝐮) =~ float(-1 ^ (int(b.grade) * int(b.gradeAnti))) ∧ 𝐮  # 2.23b
```

```nim
      check /(/𝐮) =~ Real(-1^(int(b.grade) * int(b.gradeAnti))) ∧ 𝐮  # 2.23b
```

## Edit `tests/suites.nim`

```nim
      let sign = float(-1^(int(b.gradeAnti) * int(c.gradeAnti)))
```

```nim
      let sign = Real(-1^(int(b.gradeAnti) * int(c.gradeAnti)))
```
