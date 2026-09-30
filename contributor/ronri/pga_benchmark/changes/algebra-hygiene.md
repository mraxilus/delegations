# Name tolerance for what it is, and make grades printable

`TOLERANCE_ABS` scales with the operands above one, so it is a relative tolerance. This
change calls it `TOLERANCE_REL`.

`$` is the one operator that `Grade` does not borrow, so this change borrows it. A define,
`pgaValidate`, keeps the compile-time checks in a release build.

## Edit `pga/algebra.nim`

```nim
  TOLERANCE_ABS* = 10.pow(-TOLERANCE_PLACES.float)
```

```nim
  TOLERANCE_REL* = 10.pow(-TOLERANCE_PLACES.float)
    ## Bound is relative above 1 and absolute below; see `=~` in multivectors.nim.
```

## Edit `pga/algebra.nim`

```nim
template `in`(c: char; b: BasisDigits): bool = c in string(b)

```

```nim
template `in`(c: char; b: BasisDigits): bool = c in string(b)
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
