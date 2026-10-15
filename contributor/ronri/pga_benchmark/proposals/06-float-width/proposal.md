# P06: Make the width of each float configurable

**What it is.** A define, `pga.float_width`, 64 by default or 32, selects the type `Coefficient`.
Each coefficient, scalar operand and comparison takes `Coefficient` in place of `float`, and the
default comparison tolerance follows the width: 9 places at 64 bits, 4 at 32. The define
`pga.tolerance_places` becomes `pga.float_tolerance`.

**What it is for.** A caller can halve the bytes of every multivector. At 32 bits, operations that
mostly move data run at ×0.25 to ×0.64 of pin, and the wedge holds near ×1. At 64 bits the
library emits the same C as pin, so the default costs nothing.

**What it costs.** Precision: at 32 bits the default of 4 places holds for every law within about
10 units of the origin, and for moves, joins and meets within about 100. P07 keeps the places
level at every distance. `★m` at rga3d runs at ×1.71 of pin at 32 bits.

This proposal applies at pin and builds on no other. The Architect ruled on 2026-10-06 that
32-bit floats and SIMD forms stay unmeasured while the library holds 64-bit floats alone. A
SIMD form may come later as a proposal that keeps 64-bit floats, and this proposal comes first.

## How it works

- **Define.** `FLOAT_WIDTH` in `pga/algebra.nim` reads `pga.float_width`, 64 by default. A
  static assertion refuses any width other than 32 or 64.
- **Type.** `Coefficient` is `float32` at 32 bits and `float64` at 64 bits. `float64` is the type
  that `float` names, so at 64 bits each signature means what it meant at pin.
- **Uses.** The coefficients of `Multivector`, its indexers and `initElement` take `Coefficient`.
  So do the generated constructors that take a value, `=~`, each operator that takes a scalar,
  `selectPart`, and the sign of the partner `⊛`. The library's own suites take it for `div` and
  four signs, so that each suite reads in one type.
- **Literal constructors.** A constructor such as `e1"0.5"` still parses a `float`. Nim narrows
  it to `Coefficient` by itself at 32 bits, so its line stays as at pin.
- **Comparison tolerance.** `FLOAT_TOLERANCE` reads `pga.float_tolerance`, which takes the place
  of `pga.tolerance_places` and still counts decimal places. It defaults to 9 at 64 bits, as at
  pin, and to 4 at 32 bits. A 32-bit coefficient holds about seven places, so 9 places would fail.
- **Laws.** `width.nim` holds the size of `Coefficient` and of `Multivector`, the default
  comparison tolerance and the literal constructor. Two claims run it at four algebras, one
  claim at each width.

## What it costs at 64 bits

A check by hand on 2026-10-13, at pin `28f4e11`, built the bench against pin and against the
changed library from one path. The C was the same, file for file, at rga3d, rga4d, cga4d and
cga5d. A check at pin `edb0c9d` on 2026-10-06 found the same at rga4d and cga5d. The record
below moves no function at any of four algebras, so a caller who names no width pays nothing.

The record also holds a digest of the C of each build, and the two digests differ at every
algebra. They also differ in the record of `exact-kinds`, which edits no library file. So the
digests cannot show the same C, and the checks by hand do.

The times still stray, though each evaluation ran the same C. Two evaluations of this C at pin
`edb0c9d` on 2026-10-06 put these counts of times outside the spread of the pages on that date:

| Evaluation | rga4d | cga5d | rga3d | cga4d |
|------------|-------|-------|-------|-------|
| First | 1 of 111 | 1 of 131 | 0 of 88 | 21 of 113 |
| Second | 16 of 111 | 15 of 131 | 17 of 88 | 41 of 113 |

The first moved 21 of 113 times at cga4d, and at most 1 at each other algebra. So a cluster of
moved times at one algebra of one evaluation is the noise of this machine, and the counts carry
the verdict.

The evaluation at pin `28f4e11` on 2026-10-13 timed 111, 135, 88 and 117 measurands at rga4d,
cga5d, rga3d and cga4d. Against the spread that the pages read on 2026-10-13, ×0.95 to ×1.04, 9,
30, 4 and 19 of those times moved. The evaluation of 2026-10-15 timed the same measurands of the
same C. Against the spread that the pages read on that date, ×0.91 to ×1.07, 6, 32, 80 and 72
moved. Its times at rga3d read a median of ×0.73, and at cga4d of ×1.17, so the machine drifted
during those runs. That evaluation is the one the page shows.

## What 32 bits buy

`timing.nim` holds 1024 multivectors in a `seq`, and pairs slot i with slot (7i + 3) mod 1024.
Each operation times in a procedure of its own, 41 rounds, median nanoseconds per object. The
program ran at each width in five alternating runs, pinned to one core. Each cell is the median
over the runs of the ratio of 32 bits to 64 bits. The machine is an Intel Xeon at 2.80 GHz,
`linux amd64, 4 cores`, SSE2, and the runs are by hand at pin `edb0c9d` on 2026-10-06.

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

The claims run `timing.nim` at the same four algebras and at both widths. They hold only that it
runs, and its figures never guard.

Operations that mostly move data gain most, since each multivector takes half the bytes. The
products spend their time in arithmetic, and one scalar operation in 32 bits costs what one in
64 bits costs. So the wedge and the geometric product hold near ×1.00. The geometric product at
cga5d gains ×0.73, and why it alone gains is unmeasured.

The bytes hold while no alignment larger than the multivector applies. P05,
`multivector-align`, aligns it to `min(64, size)`. In the merged line that Implementation gives,
the size reads `Coefficient`, so at 32 bits rga3d aligns to 32 bytes and holds 32. With `float`
left in that rule, it pads to 64 bytes.

`★m` at rga3d costs ×1.71. Its C is the same at both widths, apart from `0.0f` in place of
`0.0`. In the machine code, the caller builds the dual on its stack with stores of 4 and 8
bytes. It then copies the dual out with loads of 16 bytes, and each load spans two or more of
those stores. A processor cannot forward such a load from its stores, so the load waits. That is
the likely cause, since this machine offers no hardware counters to confirm it.

## Comparison tolerance

The library's own suites ran at 32 bits at each algebra, at three comparison tolerances. A run by
hand at pin `28f4e11` on 2026-10-13 gave the same counts as the runs at pin `edb0c9d`:

| Places | rga3d | rga4d | cga4d | cga5d |
|--------|-------|-------|-------|-------|
| 4 | 33 of 33 | 33 of 33 | 28 of 28 | 28 of 28 |
| 5 | 33 of 33 | 33 of 33 | 28 of 28 | 28 of 28 |
| 6 | 33 of 33 | 33 of 33 | 28 of 28 | 27 of 28 |

`noise.nim` measures the noise that `=~` sees among unitized points, lines, planes and motors at
rga4d. Each law computes one object two ways that agree in exact arithmetic. The scene sits at a
distance from the origin, in its own units. Each cell is the most places a comparison tolerance
may keep with no noise in 4096 samples. The runs are on this machine, at pin `edb0c9d` on
2026-10-06, and a run by hand at pin `28f4e11` on 2026-10-13 gave the same table.

| Distance | 64 bits | 32 bits | Point on line, 64 bits | Point on line, 32 bits |
|----------|---------|---------|------------------------|------------------------|
| 1 | 14 | 5 | 15 | 6 |
| 10 | 13 | 5 | 13 | 4 |
| 100 | 13 | 4 | 11 | 2 |
| 1,000 | 12 | 3 | 9 | 0 |
| 10,000 | 11 | 2 | 7 | 0 |
| 100,000 | 10 | 1 | 5 | 0 |
| 1,000,000 | 9 | 0 | 3 | 0 |

The first two columns take the worst of three laws: a point moved twice, a join moved, and a meet
moved. Point on line tests `^(p ∧ q) ∧ r =~ 0`, where r lies on the line through p and q.

P07, `part-scale`, runs the same three laws in its `laws.nim`, with the same seed. Its samples
differ, since this program also draws a point on each line. So the rule of pin keeps 13 places at
100 here, and 12 there.

The noise lands in coefficients that should be zero or small, such as the `𝐞₃₂₁` part of a moved
point. The products build them from terms as large as the scene. `=~` weighs such a coefficient
against 1, so one place goes per decade of distance, and two for a point on a line.

So the default at 32 bits is 4 places. It holds for every law within about 10 units, and for
moves, joins and meets within about 100. Engines on 32-bit floats compare vectors at a similar
size, since `KINDA_SMALL_NUMBER` of Unreal is 1e-4 in its unit, the centimetre. The default at 64
bits stays 9, as at pin. It holds for every law within 1,000 units, and for moves, joins and meets
within 1,000,000.

A 32-bit scene larger than that moves its origin near the camera, as engines do, or takes 64 bits.
A caller who needs another comparison tolerance names `pga.float_tolerance`.

## Names

The Architect chose `Coefficient`, `pga.float_width` and `pga.float_tolerance` on 2026-10-06.

- `Coefficient` is the word the library already uses for each slot of a multivector, as the
  docs of its indexers say.
- `pga.float_width` takes a count of bits, as Nim names `float32` and `float64` by bits.
- `pga.float_tolerance` sits beside it, since the comparison tolerance follows the width. Both
  share the prefix `float_`, so a reader finds the two together.
- Each constant is its define in capitals, as `DIMENSIONS` reads `pga.dimensions`.
- `Real` names a number in mathematics, and not the slot that it fills.
- `Scalar` is the element of grade zero in the book, so it would name two things.
- `Float` reads as `float` at a glance, and Nim tells them apart by the case of one letter.

## What it leaves out

- The bench, the references and the gap list stay at 64 bits. They measure the library at its
  default, and the pin holds 64 bits alone.
- No form packs coefficients into vector registers. That is the work of the later SIMD proposal.
- `=~` keeps its floor of 1. P07, `part-scale`, weighs each part at its own scale, which keeps
  the places level. It also shows why a scale of the whole object does not serve.
- The basis-set types of P04, `exact-kinds`, hold `float`. Under this proposal they would hold
  `Coefficient`, and `alignment` would read `sizeof(Coefficient)`. Whichever of P04 and this
  proposal lands second writes them with `Coefficient`.

## Implementation

- **Files.** `pga/algebra.nim`, `pga/multivectors.nim`, `pga/operators.nim` and `pga.nim`, and
  the library's own `tests/suites.nim`.
- **Types and signatures.** Added: the constants `FLOAT_WIDTH*` and `FLOAT_TOLERANCE*`, and
  the type `Coefficient* = (when FLOAT_WIDTH == 32: float32 else: float64)`. The two constants
  stay in the one group of configuration constants at pin. `TOLERANCE_ABS*` keeps its name and
  its place in that group, and becomes a `Coefficient`. `Coefficient` goes in the `type` block of
  the types needed at runtime. The module reorders its code (`codeReordering`), so the group can
  read a type that the file declares below it. Removed: the constant `TOLERANCE_PLACES*` and the
  define `pga.tolerance_places`, with no alias. The private field `elements` of `Multivector`
  becomes `array[Basis, Coefficient]`. Each function below takes `Coefficient` where pin takes
  `float`.
- **Functions.** Changed, with no change of body: both `[]`, `initElement`, and the generated
  constructor of each basis that takes a value. Also each `=~` with a scalar, the private one of
  two scalars included, and `+`, `-`, `∧` and `*` with a scalar on either side. Also
  `selectPart`, and `add`, `subtract` and `wedge` with a scalar on either side. The sign of `⊛`
  and four signs in `tests/suites.nim` convert to `Coefficient`, and `div` there takes it. Added:
  the static assertion of the width, and nothing is removed.
- **Callers.** At 64 bits no caller must migrate, since `Coefficient` is `float` and the bench
  emits the same C. A caller that names `pga.tolerance_places` names `pga.float_tolerance`, and
  one that reads `TOLERANCE_PLACES` reads `FLOAT_TOLERANCE`. No caller in this repository names
  either. At 32 bits Nim narrows a `float` to `Coefficient` by itself, in an argument and in an
  assignment. A coefficient passed to a `var float` parameter, or put in an `openArray[float]`,
  does not compile, so there the caller takes `Coefficient`.
- **Order of edits.** P07, `part-scale`, builds on this proposal, so it lands after it and quotes
  the signatures in `Coefficient`. P05, P03, `partner-guard` and `algebra-hygiene` quote lines
  that this proposal edits, and the paragraphs below give the order of each. The change
  `doc-comments-2` and P11, `unitize-general`, read the width, and the last paragraphs give how.

P05, `multivector-align`, edits the same line, the `elements` field of `Multivector`. Each of the
two applies at pin, and the second to land quotes the first. The merged line is
`elements {.align(min(64, sizeof(array[Basis, Coefficient]))).}: array[Basis, Coefficient]`.

P03, `partner-sign`, removes the sign line of `⊛`, so the edit of that line here is void once P03
lands. If this proposal lands first, P03 quotes `Coefficient(...)` in place of `float(...)`. The
change `partner-guard` quotes the same line, and it is void once P03 lands. If this proposal lands
first, `partner-guard` quotes and keeps `Coefficient(...)`. If `partner-guard` lands first, this
proposal quotes its sign line.

The change `algebra-hygiene` renames `TOLERANCE_ABS` to `TOLERANCE_REL`, on a line that this
proposal replaces. Whichever of the two lands second quotes the first, and keeps both the new name
and `Coefficient`.

A run by hand on 2026-10-13 compiled the suites of pin, with no edit, against this proposal at 32
bits. They passed 33 of 33 at rga3d and rga4d, and 28 of 28 at cga4d and cga5d. So the edits of
the suites keep one type, and no build needs them. Probes by hand on the same date hold the other
statements on callers at 32 bits.

The change `doc-comments-2` writes "128 bytes at 4D" under `Multivector`. That holds at 64 bits
alone, since a multivector at 4D holds 64 bytes at 32 bits. Once both land, that doc names the
width.

P11, `unitize-general`, adds locals that start at the float `0.0`. One is in `^∘`, and one is in
a helper of the suites. Nim converts between the two widths by itself, so each compiles at 32
bits. But the suites then read in two types, against the statement on uses above. Once both land,
the second to land declares those locals `Coefficient`. A run by hand on 2026-10-15 applied this
proposal and P11 to a copy of the library at pin. The suites passed at 32 bits at rga4d, cga4d and
cga5d.
