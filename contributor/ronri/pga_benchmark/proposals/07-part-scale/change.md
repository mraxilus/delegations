# Compare each part at its own scale

With P06, `=~` weighs the difference of each coefficient against max(1, |x|, |y|) of that
coefficient alone, and `grade` counts a coefficient at or under the tolerance as zero. This
change weighs each difference against the largest magnitude of its part in either multivector.
The parts are those of `CAYLEYS_PARTS`, which bulk and weight extraction read: bulk and weight,
each round and flat in a conformal algebra. Both loops walk the fields of `CAYLEYS_PARTS`, so a
rigid build holds no flat part. A macro spells the bases of a part, so each loop reads that part
alone. `grade` counts a coefficient as zero under the same bound. The scalar comparison goes,
since `m =~ s` now compares with the scalar multivector of s.

## Edit `pga/multivectors.nim`

```nim
import ./[algebra, helpers]
```

```nim
import ./[algebra, cayleys, helpers]
```

## Edit `pga/multivectors.nim`

```nim
func `=~`(a, b: Coefficient): bool =
  ## Compare approximate equality between scalars, i.e. 𝐬 ≈ 𝐬.
  abs(a - b) <= TOLERANCE_ABS * max(1.0, max(abs(a), abs(b)))


func `=~`*(m: Multivector, s: Coefficient): bool =
  ## Compare approximate equality between multivector and scalar, i.e. 𝐦 ≈ 𝐬.
  if not (m[Basis.scalar] =~ s):
    return false
  for b in Basis.scalar.succ..Basis.scalarAnti:
    if not (m[b] =~ 0.0):
      return false
  true


template `=~`*(s: Coefficient, m: Multivector): bool =
  ## Compare approximate equality between scalar and multivector, i.e. 𝐬 ≈ 𝐦.
  m =~ s


func `=~`*(m, n: Multivector): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  for b in Basis:
    if not (m[b] =~ n[b]):
      return false
  true
```

```nim
macro bases(part: static Cayley1D): untyped =
  ## Spell bases that part holds as array literal, so loop over it unrolls.
  result = nnkBracket.newTree()
  for b in Basis:
    if part[b].len > 0: result.add newLit(b)


func scale(m: Multivector, part: static Cayley1D): Coefficient =
  ## Get largest magnitude in part of multivector, and at least one.
  result = 1
  for b in part.bases: result = max(result, abs(m[b]))


func `=~`*(m, n: Multivector): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  ##   Weigh each difference against largest magnitude of its part in either, as
  ##   `CAYLEYS_PARTS` splits parts.
  for forms in CAYLEYS_PARTS.fields:
    for part in forms.fields:
      let bound = TOLERANCE_ABS * max(m.scale(part), n.scale(part))
      for b in part.bases:
        if abs(m[b] - n[b]) > bound: return false
  true


func `=~`*(m: Multivector, s: Coefficient): bool =
  ## Compare approximate equality between multivector and scalar, i.e. 𝐦 ≈ 𝐬.
  m =~ initElement(Basis.scalar, s)


template `=~`*(s: Coefficient, m: Multivector): bool =
  ## Compare approximate equality between scalar and multivector, i.e. 𝐬 ≈ 𝐦.
  m =~ s
```

## Edit `pga/multivectors.nim`

```nim
  ## Get grade of multivector, if k-vector.
  var found_grade = false
  for b in Basis:
    if abs(m[b]) <= TOLERANCE_ABS: continue

    if result.isNone:
      found_grade = true
      result = some(b.grade)
    elif result.get != b.grade:  # Detect mixed grade.
      return none[Grade]()
```

```nim
  ## Get grade of multivector, if k-vector.
  ##   Count coefficient as zero within tolerance of largest magnitude of its part.
  var found_grade = false
  for forms in CAYLEYS_PARTS.fields:
    for part in forms.fields:
      let bound = TOLERANCE_ABS * m.scale(part)
      for b in part.bases:
        if abs(m[b]) <= bound: discard  # Count as zero; `fields` loop refuses `continue`.
        elif result.isNone:
          found_grade = true
          result = some(b.grade)
        elif result.get != b.grade:  # Detect mixed grade.
          return none[Grade]()
```
