# Give conformal norms and unitizes a signed square root

Under the conformal metric, a squared norm can be negative. That is an imaginary
magnitude, and not an error. At pin, the norms and the normalizations take plain `sqrt` of it,
which gives NaN.

This change adds `signedSqrt`, which keeps the sign, and uses it in the four norms and the two
normalizations. The flat norms also move onto the squared operators, as the round norms did.

## Edit `pga/operators.nim`

```nim

func `|∙`*(m: Multivector): Multivector {.inline.} =
```

```nim

func signedSqrt(s: float): float {.inline.} =
  ## Take square root carrying sign of its argument, i.e. -√|s| where s is negative.
  ##   Conformal metric admits negative squared norms; magnitude keeps their sign.
  if s < 0: -sqrt(-s) else: sqrt(s)

func `|∙`*(m: Multivector): Multivector {.inline.} =
```

## Edit `pga/operators.nim`

```nim
  result[Basis.scalar] = (`|∙ ²`m)[Basis.scalar].sqrt
```

```nim
  result[Basis.scalar] = (`|∙ ²`m)[Basis.scalar].signedSqrt
```

## Edit `pga/operators.nim`

```nim
  result[Basis.scalarAnti] = (`|∘ ²`m)[Basis.scalarAnti].sqrt
```

```nim
  result[Basis.scalarAnti] = (`|∘ ²`m)[Basis.scalarAnti].signedSqrt
```

## Edit `pga/operators.nim`

```nim
    result[Basis.scalar] = (m ∙ m)[Basis.scalar].sqrt
```

```nim
    result[Basis.scalar] = (`|∙ ²`m)[Basis.scalar].signedSqrt
```

## Edit `pga/operators.nim`

```nim
    result[Basis.scalarAnti] = (m ∘ m)[Basis.scalarAnti].sqrt
```

```nim
    result[Basis.scalarAnti] = (`|∘ ²`m)[Basis.scalarAnti].signedSqrt
```

## Edit `pga/operators.nim`

```nim
  let m_norm_bulk = (`|∙ ²`m)[Basis.scalar].sqrt
```

```nim
  let m_norm_bulk = (`|∙ ²`m)[Basis.scalar].signedSqrt
```

## Edit `pga/operators.nim`

```nim
  let m_norm_weight = (`|∘ ²`m)[Basis.scalarAnti].sqrt
```

```nim
  let m_norm_weight = (`|∘ ²`m)[Basis.scalarAnti].signedSqrt
```
