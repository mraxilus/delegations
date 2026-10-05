# Align multivector to one cache line

At pin, a multivector aligns to 8 bytes, as its floats do. A large `seq` of them then starts 56
bytes into a 64-byte cache line, so each multivector touches one line more than it holds. This
change adds `alignmentOf`, which gives the alignment of a count of bases from that count alone.
It is the largest power of two that divides their bytes, and at most one line. So it pads no
count. A multivector holds 2^D floats, so it aligns to `min(64, size)` and starts on a line.

## Edit `pga/algebra.nim`

```nim
func toBase*(grade: GradeAnti): Grade {.inline, noinit.} = Grade(GradeAnti.high - grade)
  ## Convert antigrade to equivalent grade form.
```

```nim
func toBase*(grade: GradeAnti): Grade {.inline, noinit.} = Grade(GradeAnti.high - grade)
  ## Convert antigrade to equivalent grade form.



#[ Basis Storage ]#

func alignmentOf*(count: int): int =
  ## Align coefficients of `count` bases to largest power of two dividing their bytes, at most
  ##   one cache line. Alignment divides size, so it pads at no count.
  ##   Multivector holds 2^D coefficients, so it aligns to `min(64, size)` and starts on line.
  const size_line = 64
  let size = sizeof(float) * count
  min(size_line, size and -size)
```

## Edit `pga/multivectors.nim`

```nim
type
  Multivector* = object  ## Define generalised multivector for n-dimensional PGA.
    elements: array[Basis, float]
```

```nim
type
  Multivector* = object  ## Define generalised multivector for n-dimensional PGA.
    elements {.align(alignmentOf(ord(Basis.high) + 1)).}: array[Basis, float]
      ## Align by size of basis set, so multivector starts on cache line and touches fewest lines.
```
