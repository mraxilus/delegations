# Make the width of each float configurable

At pin, each coefficient of a multivector is a 64-bit `float`, and no build option changes it.
This change adds the define `pga.float_width`, 64 by default or 32, and the type `Coefficient`
that it selects. Each coefficient, scalar operand and comparison takes `Coefficient` in place of
`float`. The define `pga.tolerance_places` becomes `pga.float_tolerance`, and its default
follows the width. At 64 bits `Coefficient` and `float` name one type, so the library emits the
same C as pin.

## Edit `pga/algebra.nim`

```nim
  # Avoid small-value comparison failures.
  TOLERANCE_PLACES* {.define: "pga.tolerance_places".} = 9
  TOLERANCE_ABS* = 10.pow(-TOLERANCE_PLACES.float)
```

```nim
  # Choose bits in each coefficient: 64, or 32 to halve every multivector.
  FLOAT_WIDTH* {.define: "pga.float_width".} = 64

  # Avoid small-value comparison failures, in decimal places; 32-bit coefficient holds about seven.
  FLOAT_TOLERANCE* {.define: "pga.float_tolerance".} = (when FLOAT_WIDTH == 32: 4 else: 9)

type Coefficient* = (when FLOAT_WIDTH == 32: float32 else: float64)
  ## Define each coefficient of every multivector, in as many bits as `FLOAT_WIDTH` says.

const TOLERANCE_ABS* = Coefficient(10.pow(-FLOAT_TOLERANCE.float))
```

## Edit `pga/algebra.nim`

```nim
static:
```

```nim
static:
  doAssert FLOAT_WIDTH in [32, 64], &"Float width should be 32 or 64 bits; got `{FLOAT_WIDTH}`."
```

## Edit `pga/multivectors.nim`

```nim
    elements: array[Basis, float]
```

```nim
    elements: array[Basis, Coefficient]
```

## Edit `pga/multivectors.nim`

```nim
template `[]`*(m: var Multivector, b: Basis): var float = m.elements[b]
```

```nim
template `[]`*(m: var Multivector, b: Basis): var Coefficient = m.elements[b]
```

## Edit `pga/multivectors.nim`

```nim
template `[]`*(m: Multivector, b: Basis): float = m.elements[b]
```

```nim
template `[]`*(m: Multivector, b: Basis): Coefficient = m.elements[b]
```

## Edit `pga/multivectors.nim`

```nim
func initElement*(b: Basis, scalar: float = 1'f): Multivector =
```

```nim
func initElement*(b: Basis, scalar: Coefficient = 1'f): Multivector =
```

## Edit `pga/multivectors.nim`

```nim
      params = nnkFormalParams.newTree(ident"Multivector", newIdentDefs(ident"f", ident"float")),
```

```nim
      params = nnkFormalParams.newTree(
        ident"Multivector",
        newIdentDefs(ident"f", ident"Coefficient"),
      ),
```

## Edit `pga/multivectors.nim`

```nim
func `=~`(a, b: float): bool =
```

```nim
func `=~`(a, b: Coefficient): bool =
```

## Edit `pga/multivectors.nim`

```nim
func `=~`*(m: Multivector, s: float): bool =
```

```nim
func `=~`*(m: Multivector, s: Coefficient): bool =
```

## Edit `pga/multivectors.nim`

```nim
template `=~`*(s: float, m: Multivector): bool =
```

```nim
template `=~`*(s: Coefficient, m: Multivector): bool =
```

## Edit `pga/multivectors.nim`

```nim
func `+`*(s: float, m: Multivector): Multivector {.inline, noinit.} =
```

```nim
func `+`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
```

## Edit `pga/multivectors.nim`

```nim
template `+`*(m: Multivector, s: float): Multivector =
```

```nim
template `+`*(m: Multivector, s: Coefficient): Multivector =
```

## Edit `pga/multivectors.nim`

```nim
func `-`*(s: float, m: Multivector): Multivector {.inline, noinit.} =
```

```nim
func `-`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
```

## Edit `pga/multivectors.nim`

```nim
func `-`*(m: Multivector, s: float): Multivector {.inline, noinit.} =
```

```nim
func `-`*(m: Multivector, s: Coefficient): Multivector {.inline, noinit.} =
```

## Edit `pga/operators.nim`

```nim
func `∧`*(s: float, m: Multivector): Multivector {.inline, noinit.} =
```

```nim
func `∧`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
```

## Edit `pga/operators.nim`

```nim
template `∧`*(m: Multivector, s: float): Multivector =
```

```nim
template `∧`*(m: Multivector, s: Coefficient): Multivector =
```

## Edit `pga/operators.nim`

```nim
template `*`*(s: float, m: Multivector): Multivector =
```

```nim
template `*`*(s: Coefficient, m: Multivector): Multivector =
```

## Edit `pga/operators.nim`

```nim
template `*`*(m: Multivector, s: float): Multivector =
```

```nim
template `*`*(m: Multivector, s: Coefficient): Multivector =
```

## Edit `pga/operators.nim`

```nim
    let sign = float(-1 ^ (int(m.grade.get) + 1))
```

```nim
    let sign = Coefficient(-1^(int(m.grade.get) + 1))
```

## Edit `pga.nim`

```nim
func selectPart*(m: Multivector, b: Basis): float {.inline.} = m[b]
```

```nim
func selectPart*(m: Multivector, b: Basis): Coefficient {.inline.} = m[b]
```

## Edit `pga.nim`

```nim
func add*(m: Multivector, s: float): Multivector {.inline.} = s + m
```

```nim
func add*(m: Multivector, s: Coefficient): Multivector {.inline.} = s + m
```

## Edit `pga.nim`

```nim
func add*(s: float, m: Multivector): Multivector {.inline.} = s + m
```

```nim
func add*(s: Coefficient, m: Multivector): Multivector {.inline.} = s + m
```

## Edit `pga.nim`

```nim
func subtract*(m: Multivector, s: float): Multivector {.inline.} = m - s
```

```nim
func subtract*(m: Multivector, s: Coefficient): Multivector {.inline.} = m - s
```

## Edit `pga.nim`

```nim
func subtract*(s: float, m: Multivector): Multivector {.inline.} = s - m
```

```nim
func subtract*(s: Coefficient, m: Multivector): Multivector {.inline.} = s - m
```

## Edit `pga.nim`

```nim
func wedge*(m: Multivector, s: float): Multivector {.inline.} = s ∧ m
```

```nim
func wedge*(m: Multivector, s: Coefficient): Multivector {.inline.} = s ∧ m
```

## Edit `pga.nim`

```nim
func wedge*(s: float, m: Multivector): Multivector {.inline.} = s ∧ m
```

```nim
func wedge*(s: Coefficient, m: Multivector): Multivector {.inline.} = s ∧ m
```

## Edit `tests/suites.nim`

```nim
func `div`*(m: Multivector, norm: float): Multivector =
```

```nim
func `div`*(m: Multivector, norm: Coefficient): Multivector =
```

## Edit `tests/suites.nim`

```nim
      let sign = float(-1 ^ (int(b.grade) * int(c.grade)))
```

```nim
      let sign = Coefficient(-1^(int(b.grade) * int(c.grade)))
```

## Edit `tests/suites.nim`

```nim
        𝐮̅[c] = float(-1^(int(b.grade) * int(b.gradeAnti))) * 𝐮̅[c]
```

```nim
        𝐮̅[c] = Coefficient(-1^(int(b.grade) * int(b.gradeAnti))) * 𝐮̅[c]
```

## Edit `tests/suites.nim`

```nim
      check /(/𝐮) =~ float(-1 ^ (int(b.grade) * int(b.gradeAnti))) ∧ 𝐮  # 2.23b
```

```nim
      check /(/𝐮) =~ Coefficient(-1^(int(b.grade) * int(b.gradeAnti))) ∧ 𝐮  # 2.23b
```

## Edit `tests/suites.nim`

```nim
      let sign = float(-1^(int(b.gradeAnti) * int(c.gradeAnti)))
```

```nim
      let sign = Coefficient(-1^(int(b.gradeAnti) * int(c.gradeAnti)))
```
