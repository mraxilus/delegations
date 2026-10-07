# Align multivector to one cache line

At pin, a multivector aligns to 8 bytes, as its floats do. A large `seq` of them then starts 56
bytes into a 64-byte cache line, so each multivector touches one line more than it holds. A
multivector holds 2^D floats, so this change aligns it to `min(64, size)`, and it starts on a
line.

## Edit `pga/multivectors.nim`

```nim
type
  Multivector* = object  ## Define generalised multivector for n-dimensional PGA.
    elements: array[Basis, float]
```

```nim
type
  Multivector* = object  ## Define generalised multivector for n-dimensional PGA.
    elements {.align(min(64, sizeof(array[Basis, float]))).}: array[Basis, float]
      ## Align to cache line, or to own size where smaller, so multivector starts on line and
      ##   touches fewest lines.
```
