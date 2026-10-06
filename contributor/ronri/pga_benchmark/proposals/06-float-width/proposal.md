# P06: Make the width of each float configurable

At pin, each coefficient of a multivector is a 64-bit `float`, and no build option changes it.
This proposal adds the define `pga.float`, 64 by default or 32, and the type `Coefficient` that it
selects. Each coefficient, scalar operand and comparison takes `Coefficient` in place of `float`.
At 64 bits the library emits the same C as pin, so the default costs nothing. At 32 bits each
multivector takes half the bytes.

This proposal applies at pin and builds on no other. The Architect ruled on 2026-10-06 that
32-bit floats and SIMD forms stay unmeasured while the library holds 64-bit floats alone. A
SIMD form may come later as a proposal that keeps 64-bit floats, and this proposal comes first.

## What it is

- **Define.** `FLOAT` in `pga/algebra.nim` reads `pga.float`, 64 by default. A static
  assertion refuses any width other than 32 or 64.
- **Type.** `Coefficient` is `float32` at 32 bits and `float64` at 64 bits. `float64` is the type
  that `float` names, so at 64 bits each signature means what it meant at pin.
- **Uses.** The coefficients of `Multivector`, its indexers, `=~`, each operator that takes a
  scalar, and the sign of the conjugate take `Coefficient`. So do four signs in the library's own
  suites, since a 64-bit sign does not convert to a 32-bit coefficient by itself.
- **Tolerance.** `pga.tolerance_places` defaults to 9 at 64 bits, as at pin, and to 5 at 32
  bits. A 32-bit coefficient holds about seven places, so 9 places would fail.

## What it costs at 64 bits

The bench at rga4d and at cga5d, built against pin and against the changed library from one
path, emits the same C, file for file. The evaluation below moves no function at any of four
algebras, so a caller who names no width pays nothing.

Its times still stray, since the same C ran in each evaluation. Three evaluations of this C on
2026-10-06 put these counts of times outside the spread of the pages:

| Evaluation | rga4d | cga5d | rga3d | cga4d |
|------------|-------|-------|-------|-------|
| First | 0 of 111 | 0 of 131 | 0 of 88 | 1 of 113 |
| Second | 51 of 111 | 6 of 131 | 0 of 88 | 4 of 113 |
| Third, below | 1 of 111 | 1 of 131 | 0 of 88 | 21 of 113 |

In the second, the pristine binary ran slow, as `norm_bulk_plane` read 16.18 ns against 10.34
ns in the first. So a cluster of moved times at one algebra of one evaluation is the noise of
this machine, and the counts carry the verdict.

## What 32 bits buy

`timing.nim` holds 1024 multivectors in a `seq`, and pairs slot i with slot (7i + 3) mod 1024.
Each operation times in a procedure of its own, 41 rounds, median nanoseconds per object. The
program ran at each width in five alternating runs, pinned to one core. Each cell is the median
over the runs of the ratio of 32 bits to 64 bits. The machine is an Intel Xeon at 2.80 GHz,
`linux amd64, 4 cores`, SSE2, on 2026-10-06.

| Operation | rga3d | rga4d | cga4d | cga5d |
|-----------|-------|-------|-------|-------|
| Bytes of one multivector | 64 → 32 | 128 → 64 | 128 → 64 | 256 → 128 |
| `m + n` | ×0.46 | ×0.57 | ×0.61 | ×0.62 |
| `-m` | ×0.25 | ×0.64 | ×0.63 | ×0.57 |
| `/m` | ×0.81 | ×0.92 | ×0.92 | ×0.46 |
| `★m` | ×1.71 | ×0.60 | ×0.88 | ×0.40 |
| `m ∙ n` | ×0.86 | ×0.58 | ×0.56 | ×0.91 |
| `m ∧ n` | ×1.06 | ×1.03 | ×1.04 | ×0.98 |
| `m ⟑ n` | ×1.00 | ×1.08 | ×1.08 | ×0.73 |

Operations that mostly move data gain most, since each multivector takes half the bytes. The
products spend their time in arithmetic, and one scalar operation in 32 bits costs what one in
64 bits costs. So the wedge and the geometric product hold near ×1.00. The geometric product at
cga5d gains ×0.73, and why it alone gains is unmeasured.

`★m` at rga3d costs ×1.71. Its C is the same at both widths, apart from `0.0f` in place of
`0.0`. In the machine code, the caller builds the dual on its stack with stores of 4 and 8
bytes. It then copies the dual out with loads of 16 bytes, and each load spans two or more of
those stores. A processor cannot forward such a load from its stores, so the load waits. That is
the likely cause, since this container offers no hardware counters to confirm it.

## Tolerance at 32 bits

The library's own suites ran at 32 bits at each algebra, at three tolerances:

| Places | rga3d | rga4d | cga4d | cga5d |
|--------|-------|-------|-------|-------|
| 4 | 33 of 33 | 33 of 33 | 28 of 28 | 28 of 28 |
| 5 | 33 of 33 | 33 of 33 | 28 of 28 | 28 of 28 |
| 6 | 33 of 33 | 33 of 33 | 28 of 28 | 27 of 28 |

So the default at 32 bits is 5 places, one place inside the first that fails. A caller who needs
more places at 32 bits names `pga.tolerance_places`, as at pin.

## Names

The Architect chose `Coefficient` and `pga.float` on 2026-10-06.

- `Coefficient` is the word the library already uses for each slot of a multivector, as the
  docs of its indexers say.
- `pga.float` takes a count of bits, as Nim names `float32` and `float64` by bits. The constant
  that reads it is `FLOAT`, as `DIMENSIONS` reads `pga.dimensions`.
- `Real` names a number in mathematics, and not the slot that it fills.
- `Scalar` is the element of grade zero in the book, so it would name two things.
- `Float` reads as `float` at a glance, and Nim tells them apart by the case of one letter.

## What it leaves out

- The bench, the references and the gap list stay at 64 bits. They measure the library at its
  default, and the pin holds 64 bits alone.
- No form packs coefficients into vector registers. That is the work of the later SIMD proposal.
