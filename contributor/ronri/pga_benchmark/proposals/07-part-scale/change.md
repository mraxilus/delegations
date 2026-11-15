# Compare each part at its own scale

At pin, `=~` weighs the difference of each coefficient against max(1, |x|, |y|) of that
coefficient alone. `grade` counts a coefficient at or under the comparison tolerance as zero.
This change weighs each difference against the largest absolute value of its part in either
multivector.

The parts are those of `CAYLEYS_PARTS`, which bulk and weight extraction read: bulk and weight,
each round and flat in a conformal algebra. Both loops walk the fields of `CAYLEYS_PARTS`, so a
rigid build holds no flat part. A macro spells the bases of a part that a set holds, so each loop
reads that part alone. `=~` stays generic over the set of bases of its multivectors, and each part
keeps the bases of that set.

`grade` counts a coefficient as zero under the same bound. In a conformal algebra it also counts
a coefficient as zero within 16 rounding units of the largest coefficient. A multivector with an
infinite coefficient has no grade, and one with a coefficient that is not finite equals nothing.
`m =~ s` compares m with the scalar multivector of s, so one rule holds, and its TODO goes. The
private `=~` of two scalars stays, since the narrowing check of `toMultivectorOf` reads it.

The generic `=~` comes before `m =~ s`, which calls it, so the second edit replaces the whole
comparison. It also drops the commented copy of the `=~` of two dense multivectors.

P06, `float-width`, is implemented at pin, so the 32-bit claims build at its width. Two other
edits reach lines that this change quotes or replaces:

- The change `doc-comments-2` adds a doc line under the doc of `grade`, which the third edit
  quotes. Where this change lands second, its third edit quotes that line too. Where
  `doc-comments-2` lands second, its edit applies as written, and its line stands above the doc
  lines that this change adds.
- The change `algebra-hygiene` renames the exported constant `TOLERANCE_ABS` to `TOLERANCE_REL`.
  It also renames it in the zero test of `grade`, which this change replaces. The second to land
  quotes the first. Once it lands, the new code here and the programs `laws.nim` and
  `timing.nim` take the new name.

## Edit `pga/multivectors.nim`

```nim
import std/[macros, math, options, strformat, strutils, unicode]

import ./[algebra, emitters]
```

```nim
import std/[fenv, macros, math, options, strformat, strutils, unicode]

import ./[algebra, cayleys, emitters]
```

## Edit `pga/multivectors.nim`

```nim
func `=~`*(m: Multivector, s: Coefficient): bool =
  ## Compare approximate equality between multivector and scalar, i.e. 𝐦 ≈ 𝐬.

  # TODO: Scale tolerance based on max of parts in isolation (not max overall).
  if not (m[Basis.scalar] =~ s):
    return false
  for b in Basis.scalar.succ..Basis.scalarAnti:
    if not (m[b] =~ 0.0):
      return false
  true


template `=~`*(s: Coefficient, m: Multivector): bool =
  ## Compare approximate equality between scalar and multivector, i.e. 𝐬 ≈ 𝐦.
  m =~ s


# func `=~`*(m, n: Multivector): bool =
#   ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
#   for b in Basis:
#     if not (m[b] =~ n[b]):
#       return false
#   true


func `=~`*[B: static Bases](m, n: MultivectorOf[B]): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  for b in B:
    if not (m[b] =~ n[b]):
      return false
  true
```

```nim
macro bases(part: static Cayley1D, within: static Bases): untyped =
  ## Spell bases that part holds within set as array literal, so loop over it unrolls.
  result = nnkBracket.newTree()
  for b in within:
    if part[b].len != 0: result.add nnkDotExpr.newTree(ident"Basis", ident($b))
  if result.len == 0:
    result = newCall(
      ident"default",
      nnkBracketExpr.newTree(ident"array", newIntLitNode(0), ident"Basis"),
    )


func scale[B: static Bases](m: MultivectorOf[B], part: static Cayley1D): Coefficient =
  ## Get largest absolute value in part of multivector, and at least one.
  result = 1
  for b in part.bases(B):
    if abs(m[b]) > result: result = abs(m[b])


func `=~`*[B: static Bases](m, n: MultivectorOf[B]): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  ##   Weigh each difference against largest absolute value of its part in either.
  ##   Take parts as `CAYLEYS_PARTS` splits them, each within bases that `B` holds.
  ##   Coefficient not finite fails comparison, so such multivector equals nothing.
  for forms in CAYLEYS_PARTS.fields:
    for part in forms.fields:
      let bound = TOLERANCE_ABS * max(m.scale(part), n.scale(part))
      if bound == Inf: return false
      for b in part.bases(B):
        if not (abs(m[b] - n[b]) <= bound): return false
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
  ##   Count coefficient as zero within tolerance of largest absolute value of its part.
  ##   In CGA, also count it as zero within 16 rounding units of largest coefficient.
  ##     Conformal product leaves rounding of its largest terms in parts far smaller than they are.
  ##   Infinite coefficient makes bound infinite, so overflowed multivector holds no grade.
  var found_grade = false
  when IS_CONFORMAL:
    # Determine largest coefficient by branch, as `max` is slower here.
    var largest: Coefficient = 0
    for b in Basis:
      if abs(m[b]) > largest: largest = abs(m[b])
    let rounding = 16 * epsilon(Coefficient) * largest
  for forms in CAYLEYS_PARTS.fields:
    for part in forms.fields:
      let bound =
        when IS_CONFORMAL: max(TOLERANCE_ABS * m.scale(part), rounding)
        else: TOLERANCE_ABS * m.scale(part)
      if bound == Inf: return none[Grade]()
      for b in part.bases({Basis.scalar..Basis.scalarAnti}):
        if abs(m[b]) <= bound: discard  # Count as zero; `fields` loop refuses `continue`.
        elif result.isNone:
          found_grade = true
          result = some(b.grade)
        elif result.get != b.grade:  # Detect mixed grade.
          return none[Grade]()
```
