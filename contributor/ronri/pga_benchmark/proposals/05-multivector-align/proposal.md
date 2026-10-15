# P05: Align each multivector to one cache line

**What it is.** One alignment pragma on the private array of coefficients makes each multivector
start on a 64-byte cache line, or on its own size where that is smaller, `min(64, size)`. The size
of a multivector and every signature stay as at pin.

**What it is for.** At pin, a multivector aligns to 8 bytes, as its floats do. A large `seq` of
multivectors then starts 56 bytes into a line, so each multivector touches one line more than it
holds. Aligned, work that mostly moves data gains: in a `seq` on a Cascade Lake Xeon, `-m` runs at
×0.42 to ×0.84 of pin and `m + n` at ×0.77 to ×0.84. The products hold near ×1.

**What it costs.** A function that keeps a multivector on its own stack aligns its frame to 64
bytes, which costs a few instructions for each call. On an Emerald Rapids Xeon at cga5d, five of
seven operations ran ×1.07 to ×1.11 of pin.

This proposal applies at pin and builds on no other. The basis-set types of P04 hold any count
of floats, and P04 holds the rule that aligns them, `alignment`. P06 edits the same line as this
proposal, and Implementation gives the order and the merged line.

## How it works

- **Multivector.** Its elements carry `{.align(min(64, sizeof(array[Basis, float]))).}`. That is
  64 bytes at every algebra of three dimensions or more, and 32 bytes at rga2d. Its size does
  not change.
- **Each storage.** The pinned compiler honours the alignment in a `seq`, a `ref`, a global and
  on the stack. `layout.nim` holds the size, the alignment and the address in each of them.
- **Stack.** A function that keeps a multivector on its own stack aligns its frame to 64 bytes,
  from three dimensions up. That costs a few instructions for each call.

## Why a cache line

A processor moves memory in lines of 64 bytes. A multivector that starts on a line touches the
fewest lines it can, and one that starts inside a line touches one more:

| Algebra | Floats | Bytes | Lines from a line start | Lines from 56 bytes in |
|---------|--------|-------|-------------------------|------------------------|
| rga3d | 8 | 64 | 1 | 2 |
| rga4d, cga4d | 16 | 128 | 2 | 3 |
| cga5d | 32 | 256 | 4 | 5 |

A probe of addresses shows where each build puts the first element of a large `seq`. The offset
inside a line is the same in every algebra and instruction set. The probe read these offsets at
pin `d9be8ae` on 2026-10-04, and a run by hand at pin `28f4e11` on 2026-10-13 read them again:

| Alignment | Offset of first element inside its line |
|-----------|-----------------------------------------|
| Natural, as pin | 56 bytes |
| 16 bytes | 0 bytes |
| 32 bytes | 32 bytes |
| 64 bytes | 0 bytes |

The source of the pinned compiler gives the cause. A `seq` puts its data after a field of 8
bytes, padded to the alignment of its element. Up to 16 bytes, the allocator returns a large
block 48 bytes into a line. So the data starts at byte 56 at pin, and at byte 64 under 16 bytes.
Above 16 bytes, the allocator first moves the block up to the alignment, here a line start. The
data then starts 32 or 64 bytes past it.

So 16 bytes reaches a line start only where the allocator puts a large block. It guarantees only
an offset of 0, 16, 32 or 48 bytes. An alignment of 64 bytes guarantees the line start in each
storage. The cheap operations gain most where the extra line costs most. So under SSE2, `-m`
gains most at rga3d and least at cga5d.

## What it buys

A caller holds 1024 multivectors in a `seq`, and pairs slot i with slot (7i + 3) mod 1024. Each
operation times in a procedure of its own, 41 rounds, median nanoseconds per object.
`timing.nim` is that caller. Each machine ran five alternating runs of pin `d9be8ae`, of 16 bytes
and of 64 bytes, on one pinned core. Each cell is the median over the runs of the ratio of 64
bytes to pin `d9be8ae`. Every timing on this page ran at that pin, on 2026-10-03 and 2026-10-04.

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
times within ×0.10, and the widest gap, `m ∧ n` at rga3d, lies inside the range of its runs.
The gain is largest where an operation does little arithmetic for each byte it moves. On
Emerald Rapids at cga5d under 64 bytes, five of seven operations read ×1.07 to ×1.11. `/ m` and
`★ m` also run slower than pin under 16 bytes, and under 64 bytes each of their five runs reads
×1.04 to ×1.17. On Cascade Lake the same five gained or held, so that cost likely depends on the
core.

The same Emerald Rapids machine also ran builds for AVX2 and AVX-512, five alternating runs of
pin `d9be8ae` and of 16, 32 and 64 bytes. With 64 bytes against that pin:

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
than SSE2 at each operation. At pin `d9be8ae`, `m ⟑ n` at cga5d takes 259 ns with SSE2 and 346 ns
with AVX2.

## Limits

- Both machines are Intel Xeons. An AMD or an ARM core is not measured.
- The Emerald Rapids machine is a KVM guest, and its hypervisor reports microcode 0x1.
- The address probe reads large `seq`s alone. A small `seq` starts at another offset, and this
  proposal makes it start on a line too.
- The bench aligns its own pools and results. So its evaluation shows only what intermediates
  inside the library gain, and the tables above come from `timing.nim`.
- The time of one operation moves with the layout of its storage. One ratio inside the range
  of its runs is weak evidence. On Emerald Rapids, `m ⟑ n` at cga5d ranged ×0.80 to ×1.42.
- `timing.nim` times 7 operations, each in a procedure of its own. With SSE2 and 64 bytes, the
  compiler realigns the stack in 2 or 3 of them, and under the alignment of pin in none. With
  AVX2 or AVX-512 and 64 bytes, it realigns all 7, and under the alignment of pin 5 or 6. No
  timing isolates that cost.
- `timing.nim` exits zero when it runs. Its figures never guard.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Natural alignment, as pin | Large `seq` starts 56 bytes into a line; each element spans one more |
| 16 bytes | Times as 64 bytes on large `seq`s, but finds a line start only through the allocator |
| 32 bytes | Starts 32 bytes into a line, and gains nothing on `-m` at some algebras |

## Implementation

- **Files.** `pga/multivectors.nim`, one line: the `elements` field of `Multivector`.
- **Types and signatures.** `Multivector` keeps its one private field, `elements`, of type
  `array[Basis, float]`. The field gains `{.align(min(64, sizeof(array[Basis, float]))).}` and a
  doc comment. At pin `Multivector` aligns to 8 bytes. With this change it aligns to 32 bytes
  at rga2d and to 64 bytes from three dimensions up. Its size stays 2^D times 8 bytes, and no
  signature changes.
- **Functions.** Added, removed and changed: none. Each routine on `Multivector` keeps its
  source. Its machine code can change, since a frame that holds a multivector realigns its
  stack (Limits).
- **Callers.** No caller must migrate. The type, its field and every signature stay, and the
  pinned compiler honours the alignment in each storage (`layout.nim`). An object of a caller
  that holds a multivector beside other fields pads to the new alignment, so it can grow. The
  bench aligns its pools to 64 bytes already.
- **Order of edits.** P06, `float-width`, replaces the same line with
  `elements: array[Basis, Coefficient]`. Each of the two applies at pin, and the second to land
  quotes the first. The merged line is
  `elements {.align(min(64, sizeof(array[Basis, Coefficient]))).}: array[Basis, Coefficient]`.
  With `float` left in the alignment, a 32-bit multivector at rga3d pads from 32 to 64 bytes.
  The change `doc-comments-2` adds a doc line under `Multivector* = object`, which this change
  quotes, so the second of the two to land quotes the first.

A run by hand on 2026-10-13 applied P06 and the merged line to a copy of the library at pin.
There `layout.nim` held at four algebras, at 64 and at 32 bits. At 32 bits a multivector at
rga3d aligns to 32 bytes and holds 32. `layout.nim` reads the width of a coefficient from the
library, so one program holds both the line of this change and the merged line.

P04, `exact-kinds`, edits no line of this change. Its `alignment` gives the whole basis set the
same alignment as `min(64, size)`, since 2^D coefficients take a power of two bytes. So once both
land, `Multivector` has the layout of the exact basis-set type of the whole set. At pin
`Multivector` aligns to 8, and the two layouts differ.

## Open decisions

- Whether the library takes this alignment of its multivector.
- Whether the alignment reads `alignment` of the count of bases once P04 lands, so one rule
  spells both. The two give the same value at every algebra.
