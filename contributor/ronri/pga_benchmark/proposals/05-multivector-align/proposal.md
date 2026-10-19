# P05: Align each multivector to one cache line

**What it is.** One alignment pragma makes each multivector start on a cache line, or on its own
size where that is smaller. Its size and every signature stay as at pin.

**What it is for.** A multivector in a large `seq` then touches no more cache lines than it fills,
so work that mostly moves data runs faster. The products run in about the same time.

**What it costs.** A function that keeps a multivector on its own stack aligns its frame at each
call. On one of two cores, most operations at cga5d run slower under SSE2.

## Problem

At pin, a multivector aligns to 8 bytes at 64 bits, as its coefficients do. A processor moves memory in lines of
64 bytes. A multivector that starts on a line touches the fewest lines it can, and one that starts
inside a line touches one more. A large `seq` of multivectors at pin starts 56 bytes into a line,
so each element touches one line more than it holds:

| Algebra | Floats | Bytes | Lines from a line start | Lines from 56 bytes in |
|---------|--------|-------|-------------------------|------------------------|
| rga3d | 8 | 64 | 1 | 2 |
| rga4d, cga4d | 16 | 128 | 2 | 3 |
| cga5d | 32 | 256 | 4 | 5 |

## Idea

- **Multivector.** At pin `Multivector` is the alias of `MultivectorOf` of all bases. A `when` in
  `MultivectorOf` gives that set alone the field `elements` with
  `{.align(min(64, sizeof(array[Basis, Coefficient]))).}`. That is 64 bytes at every algebra of
  three dimensions or more at 64 bits. At rga2d a multivector aligns to its own 32 bytes, so it
  never crosses a line. Every other basis-set type keeps the alignment of its coefficient.
- **Size.** A multivector still holds its 2^D coefficients alone, so its size stays 2^D times the
  size of one coefficient.
- **Each storage.** The pinned compiler honours the alignment in a `seq`, a `ref`, a global and on
  the stack. So from three dimensions up, each multivector starts on a line in each storage.
  `layout.nim` holds the size, the alignment and the address in each of them.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| 16 bytes | Times as 64 bytes on large `seq`s, but finds a line start only through the allocator |
| 32 bytes | Starts 32 bytes into a line, and gains nothing on `-m` at some algebras |

## Costs

- **Stack frames.** A function that keeps a multivector on its own stack aligns its frame to 64
  bytes, from three dimensions up. That costs a few instructions for each call. Each routine keeps
  its source, but its machine code can change. Of the 7 procedures of `timing.nim`, the compiler
  realigns the stack in 2 or 3 under SSE2, and in none at pin. Under AVX2 or AVX-512 it realigns
  all 7, and 5 or 6 at pin. No timing isolates that cost.
- **Slower at cga5d on one core.** On the Emerald Rapids Xeon under SSE2, five of seven operations
  at cga5d run ×1.07 to ×1.11 of pin. There each of the five runs of `/ m` and `★ m` reads ×1.04
  to ×1.17, and 16 bytes also runs them slower than pin. On the Cascade Lake Xeon the same five
  operations gain or hold, so that cost likely depends on the core.
- **Objects of callers.** An object of a caller that holds a multivector beside other fields pads
  to the new alignment, so it can grow. The type, its field and every signature stay, so no caller
  must migrate.
- **Unmeasured cores.** Both machines are Intel Xeons. No measurement covers an AMD or ARM core.

## Open decisions

- Take this alignment of the multivector into the library, or keep the alignment of pin.
- Align the whole set alone, as here, or every basis-set type by the rule of P04, `exact-kinds`,
  which gives the whole set the same alignment.

## Landing

- **Float width.** The alignment reads the size of `Coefficient`. So at 32 bits a multivector at
  rga3d aligns to its own 32 bytes and pads none, and from rga4d up it aligns to 64.
- **P04, `exact-kinds`.** It replaces the same type definition, and aligns every basis-set type to
  `alignment` of its count. That is the largest power of two that divides its bytes, and at most
  64. The second of the two to land quotes the first. For the whole set, that rule gives `min(64, size)`,
  since 2^D coefficients take a power of two bytes. So once P04 lands, its rule spells both.

## Evidence

### Offsets

A probe of addresses reads where each build puts the first element of a large `seq`. The offset
inside a line is the same in every algebra and instruction set. The probe read these offsets at
pin `d9be8ae` on 2026-10-04, and a run by hand at pin `28f4e11` on 2026-10-13 read them again:

| Alignment | Offset of first element inside its line |
|-----------|-----------------------------------------|
| Natural, as pin | 56 bytes |
| 16 bytes | 0 bytes |
| 32 bytes | 32 bytes |
| 64 bytes | 0 bytes |

The source of the pinned compiler gives the cause. A `seq` puts its data after a field of 8
bytes, padded to the alignment of its element. Up to 16 bytes, the allocator returns a large block
48 bytes into a line. So the data starts at byte 56 at pin, and at byte 64 under 16 bytes. Above
16 bytes, the allocator first moves the block up to the alignment, here a line start. The data
then starts 32 or 64 bytes past it.

So 16 bytes guarantees only an offset of 0, 16, 32 or 48 bytes. The probe reads large `seq`s
alone. A small `seq` starts at another offset, and this proposal makes it start on a line too.

### Timing

`timing.nim` holds 1024 multivectors in a `seq`, and pairs slot i with slot (7i + 3) mod 1024. It
times each operation in a procedure of its own, as the median nanoseconds for each object over 41
rounds. Each machine ran five alternating runs of pin `d9be8ae`, of 16 bytes and of 64 bytes, on
one pinned core. A ratio is the median over the runs of 64 bytes to pin. Each cell gives the range
of that ratio over rga3d, rga4d, cga4d and cga5d.

- **Cascade Lake.** A Xeon, `linux amd64, 4 cores`, under SSE2, on 2026-10-03.
- **Emerald Rapids.** A Xeon of family 6 model 207, a KVM guest with 4 cores, at a load of 0.2,
  on 2026-10-04. It ran SSE2, AVX2 and AVX-512, and also 32 bytes under AVX2 and AVX-512. Its
  hypervisor reports microcode 0x1.

| Operation | Cascade Lake, SSE2 | Emerald Rapids, SSE2 | AVX2 | AVX-512 |
|-----------|--------------------|----------------------|------|---------|
| `m + n` | ×0.77 to ×0.84 | ×0.73 to ×0.88 | ×0.70 to ×0.77 | ×0.76 to ×0.83 |
| `-m` | ×0.42 to ×0.84 | ×0.59 to ×0.93 | ×0.75 to ×0.80 | ×0.70 to ×0.90 |
| `/ m` | ×0.76 to ×1.01 | ×0.85 to ×1.10 | ×0.60 to ×0.76 | ×0.78 to ×1.00 |
| `★ m` | ×0.81 to ×0.97 | ×0.92 to ×1.11 | ×0.67 to ×1.00 | ×0.84 to ×1.00 |
| `m ∙ n` | ×0.92 to ×1.00 | ×0.88 to ×1.09 | ×0.73 to ×1.21 | ×0.82 to ×0.96 |
| `m ∧ n` | ×0.95 to ×1.00 | ×0.98 to ×1.07 | ×0.92 to ×1.00 | ×0.94 to ×1.00 |
| `m ⟑ n` | ×0.99 to ×1.00 | ×0.98 to ×1.09 | ×0.96 to ×1.02 | ×0.97 to ×0.99 |

Each ratio above ×1.02 falls at cga5d. The gain is largest where an operation does little
arithmetic for each byte it moves, and where the extra line costs most. So under SSE2, `-m` gains
most at rga3d and least at cga5d.

- **16 bytes.** It times within ×0.05 of 64 bytes at each cell on Cascade Lake. On Emerald Rapids
  under SSE2 it times within ×0.10, and the widest gap, `m ∧ n` at rga3d, lies inside the range of
  its runs. Under AVX2 and AVX-512 it times within ×0.10 at each cell but two. There `m ∙ n` at
  cga5d under AVX2 reads ×0.98, and `★ m` at rga3d under AVX-512 reads ×1.05.
- **32 bytes.** It gains nothing on `-m` at rga4d and cga4d under AVX2, nor on `m + n` and `-m`
  under AVX-512.
- **AVX against SSE2.** An AVX build is not faster than SSE2 at each operation. At pin `d9be8ae`,
  `m ⟑ n` at cga5d takes 259 ns with SSE2 and 346 ns with AVX2.
- **Weight of one ratio.** The time of one operation moves with the layout of its storage, so one
  ratio inside the range of its runs is weak evidence. On Emerald Rapids, `m ⟑ n` at cga5d ranged
  ×0.80 to ×1.42.
- **The evaluation.** The bench aligns its own pools and results, so the evaluation shows only what
  intermediates inside the library gain. `timing.nim` exits zero when it runs, so its figures
  never guard.

### At 32 bits

A run by hand on 2026-10-19 applied this change to a copy of the library at pin. There
`layout.nim` held at rga3d, rga4d, cga4d and cga5d, at 64 and at 32 bits. It reads the width of a
coefficient from the library. At 32 bits a multivector at rga3d aligns to 32 bytes and holds
32.
