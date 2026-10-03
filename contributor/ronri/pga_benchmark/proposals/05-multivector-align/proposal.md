# P05: Align each multivector to one register

At pin, a multivector aligns to 8 bytes, as its floats do. A `seq` of multivectors then starts 8
bytes past a 16-byte boundary, so one 16-byte load in four at rga4d reads across two cache lines.
This proposal aligns the elements of a multivector to 16 bytes, the width of one SSE register.
A multivector holds 2^D floats, so the alignment adds no padding at any dimension.

This proposal applies at pin and builds on no other. It also gives the rule for the kinds of P02
and P04, which hold any count of floats.

## What it is

- **Multivector.** Its elements carry `{.align(16).}`. Its size does not change, and the
  compiler at pin honours the alignment in an array, a `seq`, a `ref` and on the stack.
- **Kinds of P02 and P04.** A kind aligns to 16 where it holds an even count of floats, and
  keeps its natural 8 bytes where it holds an odd count. So no kind gains padding.
- **Form in a generic.** The pinned compiler stops on `align` of an expression of a static
  parameter. A `when` in the object picks the literal instead:

```nim
type MultivectorOf*[B: static set[Basis]] = object
  when card(B) mod 2 == 0:
    elements {.align(16).}: array[card(B), float]
  else:
    elements: array[card(B), float]
```

`layout.nim` holds the size, the alignment and the address of a multivector in each storage. It
holds the same rule for kinds of 1 to 16 floats.

## What it buys

A caller holds 1024 multivectors in a `seq`, and pairs slot i with slot (7i + 3) mod 1024. Each
operation times in a procedure of its own, 41 rounds, median nanoseconds per object.
`timing.nim` is that caller. Five alternating runs of the pin, of this change and of
`min(64, size)`, pinned to one core of `linux amd64, 4 cores` on 2026-10-03, give the median
ratio of this change to the pin:

| Operation | rga3d | rga4d | cga4d | cga5d |
|-----------|-------|-------|-------|-------|
| `m + n` | ×0.81 | ×0.78 | ×0.82 | ×0.84 |
| `-m` | ×0.37 | ×0.46 | ×0.46 | ×0.84 |
| `/ m` | ×1.04 | ×0.92 | ×0.92 | ×0.74 |
| `★ m` | ×0.99 | ×0.99 | ×0.91 | ×0.82 |
| `m ∙ n` | ×0.94 | ×0.98 | ×0.98 | ×0.99 |
| `m ∧ n` | ×0.96 | ×1.01 | ×1.00 | ×1.00 |
| `m ⟑ n` | ×1.00 | ×1.00 | ×0.99 | ×0.98 |

The gain is largest where an operation does little arithmetic for each byte it moves. A product
spends most of its time in arithmetic, so its loads gain little.

## Kinds of P02 and P04

A kind of P02 or P04 holds the count of floats of its bases. So at rga3d a vector holds 3, and
at cga5d a vector holds 5. Each of the same 60 runs also times kinds that hold each count, since
they read no library. Each kind has its own sum and negation, which return by value, as the
library writes its operators. Median of the 60 runs, the time of each alignment over the natural
one:

| Floats | Natural | 16-byte, size | Sum | Negation | 64-byte, size | Sum | Negation |
|--------|---------|---------------|-----|----------|---------------|-----|----------|
| 3 | 24 B | 32 B | ×2.71 | ×4.54 | 64 B | ×2.98 | ×4.90 |
| 4 | 32 B | 32 B | ×0.83 | ×0.90 | 64 B | ×1.49 | ×1.61 |
| 5 | 40 B | 48 B | ×2.09 | ×2.20 | 64 B | ×2.13 | ×2.36 |
| 6 | 48 B | 48 B | ×0.88 | ×0.90 | 64 B | ×0.92 | ×0.99 |
| 8 | 64 B | 64 B | ×0.77 | ×0.83 | 64 B | ×0.74 | ×0.76 |
| 10 | 80 B | 80 B | ×0.89 | ×0.89 | 128 B | ×1.18 | ×1.32 |
| 16 | 128 B | 128 B | ×0.81 | ×0.89 | 128 B | ×0.78 | ×0.79 |

Each kind that alignment pads runs slower, and each kind it does not pad runs faster. At 4 floats
the data aligns alike at 16 and at 64 bytes, and only the padding differs. The cause is in the
machine code. The copy of a padded result reads its last 16 bytes in one load. That load spans
two 8-byte stores, the last float and the zeroed padding, and the processor cannot forward it.

Under this rule, the vectors and bivectors of rga3d and the vectors and quadvectors of cga5d keep
natural alignment. Every other kind of P02 aligns to 16, as does every exact kind of P04 with an
even count.

## Limits

- The figures are of one core type, a Cascade Lake Xeon. Other cores split loads and forward
  stores at other costs.
- The build targets SSE2, as Nim does by default. With AVX, a 32-byte alignment could matter,
  and that is not measured.
- The bench aligns its own pools and results. So its evaluation shows only what temporaries
  inside the library gain, and the table above comes from `timing.nim`.
- The time of one operation moves with the layout of its storage. At rga4d the dual ranged
  ×0.63 to ×1.05 over the five runs. So one ratio inside the spread is weak evidence.
- At 3 floats the natural kind is 24 bytes, so Nim passes it by value. Padded, it passes by
  pointer, so part of its cost there is the call. At 5 floats both pass by pointer.
- `timing.nim` exits zero when it runs. Its figures never guard.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Natural alignment, as pin | A `seq` starts 8 bytes past a register boundary, so loads split |
| `min(64, size)`, a cache line | Built and timed: same time as 16 bytes, and realigns stack |
| 64 bytes for each kind | Pads 3, 4, 5 and 10 floats; padded kinds ran ×1.18 to ×4.90 |
| 16 bytes for each kind of 2 or more floats | Pads odd counts; 3 and 5 floats ran ×2.09 to ×4.54 |
| `align` of an expression of `B` | Pinned compiler stops: "cannot generate code for: B" |

`min(64, size)` gives 64 bytes from three dimensions up. Against the pin, in the same five runs,
each operation took within ×0.05 of 16 bytes at each algebra. It makes the compiler realign the
stack in 3 more functions of `timing.nim`. Each is a timed loop that holds a multivector on its
stack. 16 bytes is the alignment of the stack, so it costs none.

## Open decisions

- Whether the library takes this alignment of its multivector.
- Whether P02 and P04 take the rule for kinds when they land.
