# Compare each part at its own scale

With P06, `=~` weighs the difference of each coefficient against max(1, |x|, |y|) of that
coefficient alone, and `grade` counts a coefficient at or under the tolerance as zero. This
change weighs each difference against the largest magnitude of its part, bulk or weight, in
either multivector. A conformal algebra splits each part into round and flat. `grade` counts a
coefficient as zero under the same bound. The scalar comparison goes, since `m =~ s` now
compares with the scalar multivector of s.

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
  for b in Basis.scalar.succ .. Basis.scalarAnti:
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
type Part {.pure.} = enum
  ## Define part of multivector that bulk and weight extraction keeps each basis in.
  BulkRound, WeightRound, BulkFlat, WeightFlat

const PARTS: array[Basis, Part] = block:
  ## Map each basis to its part, so comparison weighs it against scale of that part alone.
  var parts: array[Basis, Part]
  for b in Basis:
    parts[b] =
      when IS_CONFORMAL:
        if CAYLEYS_PARTS.bulk.flat[b].len > 0: Part.BulkFlat
        elif CAYLEYS_PARTS.weight.flat[b].len > 0: Part.WeightFlat
        elif CAYLEYS_PARTS.bulk.round[b].len > 0: Part.BulkRound
        else: Part.WeightRound
      else:
        if CAYLEYS_PARTS.bulk.round[b].len > 0: Part.BulkRound else: Part.WeightRound
  parts


macro scaleOf(m: Multivector, part: static Part): Coefficient =
  ## Spell largest magnitude in part of multivector, and at least one, as one chain of `max`.
  result = newCall(ident"Coefficient", newLit(1))
  for b in Basis:
    if PARTS[b] == part:
      let coefficient = nnkBracketExpr.newTree(m, newLit(b))
      result = newCall(ident"max", result, newCall(ident"abs", coefficient))


func scale(m: Multivector, part: Part): Coefficient =
  ## Get largest magnitude in part of multivector, and at least one.
  case part
  of Part.BulkRound: m.scaleOf(Part.BulkRound)
  of Part.WeightRound: m.scaleOf(Part.WeightRound)
  of Part.BulkFlat: m.scaleOf(Part.BulkFlat)
  of Part.WeightFlat: m.scaleOf(Part.WeightFlat)


func `=~`*(m, n: Multivector): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  ##   Weigh each difference against largest magnitude of its part, bulk or weight, in either.
  ##   Bound of own coefficient is never above it, so pass that first and read part only after.
  var scales: array[Part, Coefficient]  # Zero until read.
  for b in Basis:
    let difference = abs(m[b] - n[b])
    if difference <= TOLERANCE_ABS * max(1, max(abs(m[b]), abs(n[b]))): continue
    if scales[PARTS[b]] == 0: scales[PARTS[b]] = max(m.scale(PARTS[b]), n.scale(PARTS[b]))
    if difference > TOLERANCE_ABS * scales[PARTS[b]]: return false
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
```

```nim
  ## Get grade of multivector, if k-vector.
  ##   Count coefficient as zero within tolerance of largest magnitude of its part.
  var
    scales: array[Part, Coefficient]  # Zero until read.
    found_grade = false
  for b in Basis:
    if abs(m[b]) <= TOLERANCE_ABS: continue
    if scales[PARTS[b]] == 0: scales[PARTS[b]] = m.scale(PARTS[b])
    if abs(m[b]) <= TOLERANCE_ABS * scales[PARTS[b]]: continue
```
