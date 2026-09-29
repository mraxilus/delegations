# Name each interior-product derivation, and write reverse parity once

Two overloads of `constructProductInterior` derive their tables in different ways. The
overload that derives from the dual gets its own name, `constructProductInteriorFromDual`.

The parity k(k−1)/2 of the reverse becomes one function, `reverseParity`, which other
constructors can call. The local `metric_expomorphism` becomes `metric_exomorphism`.

## Edit `pga/cayleys.nim`

```nim
    let metric_expomorphism = constructMetricExomorphism(CAYLEY_METRIC)
    Spatial[Cayley1D](
      base: metric_expomorphism,
      anti: constructMetricExomorphismAnti(metric_expomorphism, CAYLEYS_COMPLEMENT),
```

```nim
    let metric_exomorphism = constructMetricExomorphism(CAYLEY_METRIC)
    Spatial[Cayley1D](
      base: metric_exomorphism,
      anti: constructMetricExomorphismAnti(metric_exomorphism, CAYLEYS_COMPLEMENT),
```

## Edit `pga/cayleys.nim`

```nim
  CAYLEY_EXPAND_BULK_RIGHT* = constructProductInterior(
```

```nim
  CAYLEY_EXPAND_BULK_RIGHT* = constructProductInteriorFromDual(
```

## Edit `pga/cayleys.nim`

```nim
  CAYLEY_CONTRACT_WEIGHT_RIGHT* = constructProductInterior(
```

```nim
  CAYLEY_CONTRACT_WEIGHT_RIGHT* = constructProductInteriorFromDual(
```

## Edit `pga/cayleys.nim`

```nim

func constructProductInterior(
  dual: Cayley1D;
```

```nim

func constructProductInteriorFromDual(
  dual: Cayley1D;
```

## Edit `pga/cayleys.nim`

```nim
func reverse(b: Basis; space: Space): BasisSigned {.compileTime.} =
  ## Get specific reverse of basis.
  let
    grade = case space
      of Space.Base: int(b.grade)
      of Space.Anti: int(b.gradeAnti)
    parity = ((int(grade * (grade - 1)) div 2) and 1) == 1
  BasisSigned(basis: b, is_negated: parity)
```

```nim
func reverseParity(grade: int): bool {.compileTime, inline.} =
  ## Determine whether reversal of grade k negates, i.e. (-1)^(k(k-1)/2).
  ((grade * (grade - 1) div 2) and 1) == 1


func reverse(b: Basis; space: Space): BasisSigned {.compileTime.} =
  ## Get specific reverse of basis.
  let grade = case space
    of Space.Base: int(b.grade)
    of Space.Anti: int(b.gradeAnti)
  BasisSigned(basis: b, is_negated: reverseParity(grade))
```
