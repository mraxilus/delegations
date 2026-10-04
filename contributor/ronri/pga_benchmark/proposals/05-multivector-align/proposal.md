# P05: Align each multivector to one cache line

At pin, a multivector aligns to 8 bytes, as its floats do. A large `seq` of multivectors then
starts 56 bytes into a 64-byte cache line, so each multivector touches one line more than it
holds. This proposal adds `alignmentOf`, which gives the alignment of a count of bases from
that count alone. It is the largest power of two that divides their bytes, and at most 64. So it
pads no count. A multivector holds 2^D floats, so it aligns to `min(64, size)`, and from three
dimensions up it fills whole lines.

This proposal applies at pin and builds on no other. The kinds of P04 hold any count of floats. Each
kind takes `alignmentOf` of the size of its basis set when it lands, as the Architect ruled on
2026-10-04. Their timings below are the evidence for that rule.

## What it is

- **Rule.** `alignmentOf(count)` in `pga/algebra.nim` gives the alignment of `count` bases. It
  is `min(64, size and -size)`, where `size` is `8 * count`, the bytes of the floats.
- **Multivector.** Its elements carry `{.align(alignmentOf(ord(Basis.high) + 1)).}`. That is 64
  bytes at every algebra this project measures. Its size does not change.
- **Each storage.** The compiler at pin honours the alignment in a `seq`, a `ref`, a global and
  on the stack. `layout.nim` holds the size, the alignment and the address in each of them.
- **Stack.** A function that keeps a multivector on its own stack aligns its frame to 64 bytes.
  That costs a few instructions for each call.

## Why a cache line

A processor moves memory in lines of 64 bytes. A multivector that starts on a line touches the
fewest lines it can, and one that starts inside a line touches one more:

| Algebra | Floats | Bytes | Lines from a line start | Lines from 56 bytes in |
|---------|--------|-------|-------------------------|------------------------|
| rga3d | 8 | 64 | 1 | 2 |
| rga4d, cga4d | 16 | 128 | 2 | 3 |
| cga5d | 32 | 256 | 4 | 5 |

A copy of `timing.nim` that prints addresses shows where each build puts the first element of a
large `seq`. The offset inside a line is the same in every algebra and instruction set:

| Alignment | Offset of first element inside its line |
|-----------|-----------------------------------------|
| Natural, as pin | 56 bytes |
| 16 bytes | 0 bytes |
| 32 bytes | 32 bytes |
| 64 bytes | 0 bytes |

The header of a large `seq` ends 56 bytes into a page. A 16-byte alignment rounds 56 up to 64,
so it reaches a line start through that header alone. It guarantees only an offset of 0, 16,
32 or 48 bytes. An alignment of 64 bytes guarantees the line start in each storage. The cheap
operations gain most where the extra line costs most. So under SSE2, `-m` gains most at rga3d
and least at cga5d.

## What it buys

A caller holds 1024 multivectors in a `seq`, and pairs slot i with slot (7i + 3) mod 1024. Each
operation times in a procedure of its own, 41 rounds, median nanoseconds per object.
`timing.nim` is that caller. Each machine ran five alternating runs of the pin, of 16 bytes and
of 64 bytes, on one pinned core. Each cell is the median over the runs of the ratio of 64 bytes
to the pin.

On a Cascade Lake Xeon, `linux amd64, 4 cores`, SSE2, on 2026-10-03:

| Operation | rga3d | rga4d | cga4d | cga5d |
|-----------|-------|-------|-------|-------|
| `m + n` | ×0.78 | ×0.77 | ×0.82 | ×0.84 |
| `-m` | ×0.42 | ×0.46 | ×0.46 | ×0.84 |
| `/ m` | ×1.01 | ×0.92 | ×0.93 | ×0.76 |
| `★ m` | ×0.97 | ×0.96 | ×0.91 | ×0.81 |
| `m ∙ n` | ×0.92 | ×0.98 | ×1.00 | ×0.99 |
| `m ∧ n` | ×0.95 | ×0.99 | ×1.00 | ×1.00 |
| `m ⟑ n` | ×1.00 | ×1.00 | ×0.99 | ×1.00 |

On an Emerald Rapids Xeon, family 6 model 207, a KVM guest with 4 cores, SSE2, on 2026-10-04 at
a load of 0.2:

| Operation | rga3d | rga4d | cga4d | cga5d |
|-----------|-------|-------|-------|-------|
| `m + n` | ×0.73 | ×0.82 | ×0.80 | ×0.88 |
| `-m` | ×0.59 | ×0.71 | ×0.72 | ×0.93 |
| `/ m` | ×0.97 | ×0.85 | ×0.85 | ×1.10 |
| `★ m` | ×0.93 | ×1.02 | ×0.92 | ×1.11 |
| `m ∙ n` | ×0.88 | ×0.99 | ×0.95 | ×1.09 |
| `m ∧ n` | ×0.98 | ×0.98 | ×0.99 | ×1.07 |
| `m ⟑ n` | ×1.00 | ×1.00 | ×0.98 | ×1.09 |

On Cascade Lake, 16 bytes times within ×0.05 of 64 bytes at each cell. On Emerald Rapids it
times within ×0.10, and the widest gap, `m ∧ n` at rga3d, lies inside the spread of its runs.
The gain is largest where an operation does little arithmetic for each byte it moves. On
Emerald Rapids at cga5d, `/ m` and `★ m` run slower than pin under both alignments. Under 64
bytes each of their five runs reads ×1.04 to ×1.17. On Cascade Lake the same two gained, so
that cost likely depends on the core.

The same Emerald Rapids machine also ran builds for AVX2 and AVX-512, five alternating runs of
the pin and of 16, 32 and 64 bytes. With 64 bytes against the pin:

| Operation | AVX2 rga3d | rga4d | cga4d | cga5d | AVX-512 rga3d | rga4d | cga4d | cga5d |
|-----------|------------|-------|-------|-------|---------------|-------|-------|-------|
| `m + n` | ×0.70 | ×0.71 | ×0.74 | ×0.77 | ×0.76 | ×0.80 | ×0.83 | ×0.80 |
| `-m` | ×0.78 | ×0.75 | ×0.80 | ×0.79 | ×0.77 | ×0.70 | ×0.71 | ×0.90 |
| `/ m` | ×0.60 | ×0.65 | ×0.66 | ×0.76 | ×0.98 | ×0.78 | ×0.80 | ×1.00 |
| `★ m` | ×1.00 | ×0.98 | ×0.67 | ×0.92 | ×0.84 | ×0.95 | ×1.00 | ×1.00 |
| `m ∙ n` | ×0.84 | ×0.73 | ×0.84 | ×1.21 | ×0.91 | ×0.82 | ×0.88 | ×0.96 |
| `m ∧ n` | ×0.96 | ×0.92 | ×0.98 | ×1.00 | ×0.94 | ×0.98 | ×0.99 | ×1.00 |
| `m ⟑ n` | ×0.96 | ×0.98 | ×1.02 | ×1.00 | ×0.99 | ×0.97 | ×0.99 | ×0.97 |

Under AVX2 and AVX-512, 16 bytes times within ×0.10 of 64 bytes at each cell but two. At 16
bytes, `m ∙ n` at cga5d under AVX2 reads ×0.98, and `★ m` at rga3d under AVX-512 reads ×1.05.
An alignment of 32 bytes starts a large `seq` 32 bytes into a line. It gains nothing on `-m` at
rga4d and cga4d under AVX2, nor on `m + n` and `-m` under AVX-512. An AVX build is not faster
than SSE2 at each operation: `m ⟑ n` at cga5d takes 259 ns with SSE2 and 346 ns with AVX2 at
pin.

## Kinds of P04

A kind of P04 holds the count of floats of its bases. So at rga3d a vector holds 3, and
at cga5d a vector holds 5. The same runs time kinds that hold each count, since they read no
library. Each kind has its own sum and negation, which return by value, as the library writes
its operators. On Cascade Lake, the median of 60 runs, time of each alignment over the natural
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

On Cascade Lake, each kind that an alignment pads runs slower, except 6 floats at 64 bytes.
Each kind that it does not pad runs faster. On Emerald Rapids, under SSE2, AVX2 and AVX-512, 3
and 5 floats padded to 16 bytes run ×2.6 to ×5.6. There, a kind that an alignment does not pad
runs at most ×1.11.

At 16 bytes the cause is in the machine code. The copy of a padded result reads its last 16
bytes in one load. That load spans two 8-byte stores, the last float and the zeroed padding,
and the processor cannot forward it.

So a kind takes the alignment that pads it at no count. `alignmentOf` gives it from the size of
the basis set of the kind alone. Each range below is the sum and the negation, on Cascade Lake
and on Emerald Rapids under SSE2, AVX2 and AVX-512:

| Floats | Kinds | Bytes | `alignmentOf` | Time over natural |
|--------|-------|-------|---------------|-------------------|
| 3 | rga3d point and line | 24 | 8, natural | ×1 |
| 4 | rga3d motor and flector, rga4d point and plane | 32 | 32 | ×0.85 to ×1.17, Emerald Rapids |
| 5 | cga5d round point and sphere | 40 | 8, natural | ×1 |
| 6 | rga4d line | 48 | 16 | ×0.86 to ×1.08 |
| 8 | rga4d motor and flector | 64 | 64 | ×0.65 to ×1.11 |
| 10 | cga5d dipole and circle | 80 | 16 | ×0.86 to ×1.00 |
| 16 | cga5d even and odd parts | 128 | 64 | ×0.76 to ×0.97 |

The kind of 4 floats is timed at 32 bytes on Emerald Rapids alone, on 2026-10-04: 20 executions
under each of SSE2, AVX2 and AVX-512. It pads nothing there, and it gains nothing over 16 bytes,
which reads ×0.86 to ×1.00 in the same runs. So 32 bytes is safe for that count, and not better.

A kind of an odd count keeps 8 bytes, so it can still cross a line. Only padding would prevent
that, and padding costs more than the line.

## Limits

- Both machines are Intel Xeons. An AMD or an ARM core is not measured.
- The Emerald Rapids machine is a KVM guest, and its hypervisor reports microcode 0x1.
- The address probe reads large `seq`s alone. A small `seq` starts at another offset, and this
  proposal makes it start on a line too.
- The bench aligns its own pools and results. So its evaluation shows only what temporaries
  inside the library gain, and the tables above come from `timing.nim`.
- The time of one operation moves with the layout of its storage. One ratio inside the spread
  of its runs is weak evidence. On Emerald Rapids, `m ⟑ n` at cga5d ranged ×0.80 to ×1.42.
- `timing.nim` times 7 operations, each in a procedure of its own. With SSE2 and 64 bytes, the
  compiler realigns the stack in 2 or 3 of them, and at pin in none. With AVX2 or AVX-512 and
  64 bytes, it realigns all 7, and at pin 5 or 6. No timing isolates that cost.
- Cascade Lake does not time the kind of 4 floats at 32 bytes. Under AVX2 its sum ranged ×0.86
  to ×1.47 over 20 executions on Emerald Rapids.
- At pin, `align` of an expression of a generic parameter stops the compiler. So the generic
  kind of P04 chooses among 8, 16, 32 and 64 through `when`. The macro that names its kinds
  knows each count when it runs, and writes the number.
- `timing.nim` exits zero when it runs. Its figures never guard.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Natural alignment, as pin | Large `seq` starts 56 bytes into a line; each element spans one more |
| 16 bytes | Times as 64 bytes on large `seq`s, but finds a line start only through the header |
| 32 bytes | Starts 32 bytes into a line, and gains nothing on `-m` at some algebras |
| 64 bytes for each kind | Pads 3, 4, 5, 6 and 10 floats; most padded kinds ran slower |
| `align` of an expression of `B` | Pinned compiler stops: "cannot generate code for: B" |

## Open decisions

- Whether the library takes this alignment of its multivector.
