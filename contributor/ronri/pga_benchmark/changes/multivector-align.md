# Align each multivector to cache line

At pin, a multivector aligns to 8 bytes, as its floats do. A `seq` of multivectors at rga4d
starts 56 bytes into a cache line, so each 128-byte multivector spans three lines, not two.
Each 16-byte load at the edge of a line then reads across two lines.

This change aligns the elements to a cache line, or to their own size where that is smaller.
The size does not change: a multivector holds 2^D floats, so from three dimensions up it fills
whole lines, and at two dimensions it aligns to its 32 bytes. Storage in an array, a `seq`, a
`ref` or on the stack then starts on a line, since the compiler at pin honours the alignment
in each.

A caller holds 1024 multivectors in a `seq`, and pairs slot i with slot (7i + 3) mod 1024. Each
operation times in a procedure of its own, 41 rounds, median nanoseconds per object. Five
alternating runs of the pin and of the changed library, on `linux amd64, 4 cores` on
2026-10-03, give the changed time over the pin's:

| Operation | rga3d | rga4d | cga5d |
|-----------|-------|-------|-------|
| `m + n` | ×0.69 | ×0.76 | ×0.67 |
| `-m` | ×0.85 | ×0.91 | ×0.59 |
| `/ m` | ×0.85 | ×0.95 | ×0.73 |
| `★ m` | ×0.78 | ×1.42 | ×0.71 |
| `m ∙ n` | ×0.61 | ×0.74 | ×0.61 |
| `m ∧ n` | ×0.79 | ×0.98 | ×0.69 |
| `m ⟑ n` | ×0.95 | ×0.99 | ×0.69 |

The dual at rga4d reads ×1.42 because it compares with the best case of the pin. With the pin,
it takes 4.4 ns where results sit at the same offset in a page as operands, as two `seq` of one
size are allocated. With results 128, 256 or 2048 bytes further, it takes 7.2 to 7.6 ns.
Aligned, it takes 6.2 to 6.6 ns at each of these offsets. The same runs rule out the order of
instructions, which is the same in both, and the placement of the loop and of its branch.

The bench aligns its own pools and results, so its evaluation shows only what the temporaries
inside the library gain.

## Edit `pga/multivectors.nim`

```nim
type
  Multivector* = object ## Define generalised multivector for n-dimensional PGA.
    elements: array[Basis, float]
```

```nim
const ALIGNMENT_MULTIVECTOR = min(64, sizeof(array[Basis, float]))
  ## Align multivector to cache line, or to its own size where smaller.
  ##   So it spans fewest lines wherever it is stored: array, `seq`, `ref` or stack.

type
  Multivector* = object ## Define generalised multivector for n-dimensional PGA.
    elements {.align(ALIGNMENT_MULTIVECTOR).}: array[Basis, float]
```
