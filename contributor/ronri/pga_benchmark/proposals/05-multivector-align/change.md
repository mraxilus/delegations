# Align multivector to one SSE register

At pin, a multivector aligns to 8 bytes, as its floats do. This change aligns its elements to 16
bytes, so no 16-byte load splits across two cache lines. A multivector holds 2^D floats, so the
alignment adds no padding at any dimension.

## Edit `pga/multivectors.nim`

```nim
type
  Multivector* = object ## Define generalised multivector for n-dimensional PGA.
    elements: array[Basis, float]
```

```nim
type
  Multivector* = object ## Define generalised multivector for n-dimensional PGA.
    elements {.align(16).}: array[Basis, float]
      ## Align to one SSE register, so no 16-byte load splits across cache lines.
      ##   Multivector holds 2^D floats, so alignment pads it at no dimension.
```
