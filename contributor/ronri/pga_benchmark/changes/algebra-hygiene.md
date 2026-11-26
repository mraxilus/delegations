# Name tolerance for what it is, and make grades printable

`TOLERANCE_ABS` scales with the operands above one, so it is a relative tolerance. This
change calls it `TOLERANCE_REL`.

`$` is the one operator that `Grade` does not borrow, so this change borrows it. A define,
`pgaValidate`, keeps the compile-time checks in a release build.

Three proposals name `TOLERANCE_ABS`, which this change renames. Of this change and each of
them, the second to land carries the new name:

- P07, `part-scale`, replaces the zero test of `grade`, and its new `=~` names the tolerance. Both
  quote that test, so the second to land quotes the first. The new code of P07 and its programs
  `laws.nim` and `timing.nim` take the new name.
- P11, `unitize-general`, names `TOLERANCE_ABS` in `^∘`, `laws.nim` and `limits.nim`. With both
  applied, the conformal build stops on `undeclared identifier: 'TOLERANCE_ABS'`. The second to
  land carries the new name into `^∘` and into both programs.
- P10, `homogeneous-scalar`, names `TOLERANCE_ABS` in `inverse` of `pga/scalars.nim` and in its
  `laws.nim`. With both applied, the build stops on `undeclared identifier: 'TOLERANCE_ABS'`. The
  second to land carries the new name into both.

This project names `TOLERANCE_ABS` three times too, in `src/pga_benchmark/dense.nim`,
`src/pga_benchmark/widening.nim` and `tests/suites.nim`. Each takes the new name when the pin
moves to a library with this change.

## Edit `pga/algebra.nim`

```nim
const TOLERANCE_ABS* = Coefficient(10.pow(-float(FLOAT_TOLERANCE)))  ## TODO: Document.
```

```nim
const TOLERANCE_REL* = Coefficient(10.pow(-float(FLOAT_TOLERANCE)))
  ## Bound is relative above 1 and absolute below; see `=~` in `multivectors.nim`.
```

## Edit `pga/algebra.nim`

```nim
template `[]`(b: BasisDigits, i: int): char {.used.} = string(b)[i]  # Used in `cayleys.nim`.
template `in`(c: char, b: BasisDigits): bool = c in string(b)

```

```nim
template `[]`(b: BasisDigits, i: int): char {.used.} = string(b)[i]  # Used in `cayleys.nim`.
template `in`(c: char, b: BasisDigits): bool = c in string(b)
func `$`*(g: Grade): string {.borrow.}
  ## Print grade as its integer, so failing checks read as numbers.
func `$`*(g: GradeAnti): string {.borrow.}
  ## Print antigrade as its integer.
```

## Edit `pga/algebra.nim`

```nim
  ## Convert from string to digit representation of basis, checking for validity.
  when compileOption("assertions"):
```

```nim
  ## Convert from string to digit representation of basis, checking for validity.
  when defined(pgaValidate) or compileOption("assertions"):
```

## Edit `pga/algebra.nim`

```nim
  when compileOption("assertions"):
```

```nim
  when defined(pgaValidate) or compileOption("assertions"):
```

## Edit `pga/multivectors.nim`

```nim
  abs(a - b) <= TOLERANCE_ABS * max(1.0, max(abs(a), abs(b)))
```

```nim
  abs(a - b) <= TOLERANCE_REL * max(1.0, max(abs(a), abs(b)))
```

## Edit `pga/multivectors.nim`

```nim
    if abs(m[b]) > TOLERANCE_ABS:
```

```nim
    if abs(m[b]) > TOLERANCE_REL:
```

## Edit `pga/multivectors.nim`

```nim
    if abs(m[b]) <= TOLERANCE_ABS: continue
```

```nim
    if abs(m[b]) <= TOLERANCE_REL: continue
```
