# P06: Make the width of each float configurable

**What it is.** A define, `pga.float_width`, selects the type `Coefficient`, a 64-bit float by
default or a 32-bit one. Each coefficient, scalar operand and comparison takes it, and the default
comparison tolerance follows the width.

**What it is for.** A caller can halve the bytes of every multivector, and so speed up the
operations that mostly move data. The default emits the same C as pin, so it costs nothing.

**What it costs.** At 32 bits a comparison keeps fewer places, so the default comparison tolerance
holds only near the origin. The define `pga.tolerance_places` takes a new name, with no alias.

## Problem

At pin, each coefficient of a multivector, each scalar operand and each comparison takes `float`,
which is `float64`. The library holds 64-bit floats alone, so a caller cannot halve the bytes of
a multivector. Operations that mostly move data would gain most from that half. `=~` keeps 9
decimal places by default, through `pga.tolerance_places`. A 32-bit coefficient holds about seven
places, so that default suits 64 bits alone.

## Idea

- **Define.** `FLOAT_WIDTH` reads `pga.float_width`, 64 by default. A static assertion refuses any
  width other than 32 or 64.
- **Type.** `Coefficient` is `float32` at 32 bits and `float64` at 64 bits. At 64 bits it is the
  type that `float` names, so each signature means what it meant at pin.
- **Uses.** The coefficients of `Multivector`, its indexers and `initElement` take `Coefficient`.
  So do the generated constructors that take a value, `=~`, each operator that takes a scalar,
  `selectPart`, and the sign of the partner `⊛`. The library's own suites take it for `div` and
  four signs, so that each suite reads in one type.
- **Narrowing.** At 32 bits Nim narrows a `float` to `Coefficient` by itself, in an argument and
  in an assignment. So a literal constructor such as `e1"0.5"` still parses a `float`, and its
  line stays as at pin.
- **Comparison tolerance.** `FLOAT_TOLERANCE` reads `pga.float_tolerance`, which takes the place
  of `pga.tolerance_places` and still counts decimal places. It defaults to 9 at 64 bits, as at
  pin, and to 4 at 32 bits. Engines on 32-bit floats compare vectors at a similar size, since
  `KINDA_SMALL_NUMBER` of Unreal is 1e-4 in its unit, the centimetre.
- **Order in the file.** `Coefficient` sits in the type block, below the configuration constants
  that read it. The module reorders its code (`codeReordering`), so that order compiles.
  `TOLERANCE_ABS` keeps its name and its place, and becomes a `Coefficient`.

## Alternatives

### Names

The Architect chose `Coefficient`, `pga.float_width` and `pga.float_tolerance` on 2026-10-06.

- `Coefficient` is the word the library already uses for each element of a multivector, as the
  docs of its indexers say.
- `pga.float_width` takes a count of bits, as Nim names `float32` and `float64` by bits.
- `pga.float_tolerance` sits beside it, since the comparison tolerance follows the width. Both
  share the prefix `float_`, so a reader finds the two together.
- Each constant is its define in capitals, as `DIMENSIONS` reads `pga.dimensions`.

| Name | Why it lost |
|------|-------------|
| `Real` | Names a number in mathematics, and not its use in a multivector |
| `Scalar` | Is the element of grade zero in the book, so it would name two things |
| `Float` | Reads as `float` at a glance, and Nim tells the two apart by the case of one letter |

## Costs

- **At 64 bits.** Checks by hand built the bench against pin and against this proposal, from one
  path. The C was the same, file for file, at rga3d, rga4d, cga4d and cga5d at pin `28f4e11` on
  2026-10-13. It was the same at rga4d and cga5d at pin `edb0c9d` on 2026-10-06. So a caller who
  names no width pays nothing, and changes nothing.
- **Precision at 32 bits.** The default of 4 places holds for every law within about 10 units of
  the origin. It holds for moves, joins and meets within about 100. At 64 bits the default of 9
  holds for every law within 1,000 units, and for moves, joins and meets within 1,000,000. A
  larger 32-bit scene moves its origin near the camera, as engines do, or takes 64 bits. A caller
  who needs another comparison tolerance names `pga.float_tolerance`.
- **Floor of `=~`.** `=~` keeps its floor of 1. P07, `part-scale`, weighs each part at its own
  scale, which keeps the places level at every distance. It also shows why a scale of the whole
  object does not serve.
- **Dual at rga3d.** At 32 bits, `★m` at rga3d runs slower than at 64 bits. Evidence gives the
  likely cause.
- **Renamed define.** The define `pga.tolerance_places` and the constant `TOLERANCE_PLACES` go,
  with no alias. A caller names `pga.float_tolerance` and reads `FLOAT_TOLERANCE` in their place.
  No caller in this repository names either.
- **Callers at 32 bits.** A coefficient passed to a `var float` parameter, or put in an
  `openArray[float]`, does not compile. There the caller takes `Coefficient`.
- **Bench at 64 bits.** The bench, the references and the gap list stay at 64 bits, the default.
  The Architect ruled on 2026-10-06 that 32-bit floats and SIMD forms stay unmeasured while the
  library holds 64-bit floats alone.
- **No SIMD form.** No form packs coefficients into vector registers. A later SIMD proposal may do
  that and keep 64-bit floats, and it lands after this one.

## Open decisions

None.

## Landing

- **P07, `part-scale`.** It lands after this proposal, and quotes each signature in
  `Coefficient`.
- **P05, `multivector-align`.** Both edit the `elements` field of `Multivector`, and each applies
  at pin. The second to land quotes the first, and writes the merged line
  `elements {.align(min(64, sizeof(array[Basis, Coefficient]))).}: array[Basis, Coefficient]`.
  Its size reads `Coefficient`, so at 32 bits rga3d aligns to 32 bytes and holds 32. With `float`
  left in that rule, it pads to 64 bytes.
- **P03, `partner-sign`.** It removes the sign line of `⊛`, so the edit of that line here is void
  once P03 lands. If this proposal lands first, P03 quotes `Coefficient(...)` in place of
  `float(...)`.
- **Change `partner-guard`.** It quotes the same sign line, and is void once P03 lands. If this
  proposal lands first, `partner-guard` quotes and keeps `Coefficient(...)`. If `partner-guard`
  lands first, this proposal quotes its sign line.
- **Change `algebra-hygiene`.** It renames `TOLERANCE_ABS` to `TOLERANCE_REL`, on a line that
  this proposal replaces. Whichever of the two lands second quotes the first, and keeps both the
  new name and `Coefficient`.
- **P04, `exact-kinds`.** Its basis-set types hold `float`. Whichever of P04 and this proposal
  lands second writes them with `Coefficient`, and `alignment` reads `sizeof(Coefficient)`.
- **Change `doc-comments-2`.** It writes "128 bytes at 4D" under `Multivector`. That holds at 64
  bits alone, since a multivector at 4D holds 64 bytes at 32 bits. Once both land, that doc names
  the width.
- **P11, `unitize-general`.** It adds locals that start at the float `0.0`, in `^∘` and in a
  helper of the suites. Nim converts between the two widths by itself, so each compiles at 32
  bits, but the suites then read in two types. Once both land, the second to land declares those
  locals `Coefficient`. A run by hand on 2026-10-15 applied this proposal and P11 to a copy of the
  library at pin. The suites passed at 32 bits at rga4d, cga4d and cga5d.

## Evidence

### Suites and callers

`width.nim` holds the size of `Coefficient` and of `Multivector`, the default comparison
tolerance and the literal constructor, at each width.

A run by hand on 2026-10-13 compiled the suites of pin, with no edit, against this proposal at 32
bits. They passed 33 of 33 at rga3d and rga4d, and 28 of 28 at cga4d and cga5d. So the edits of
the suites keep one type, and no build needs them. Probes by hand on the same date hold the
statements on callers at 32 bits.

### Same C at 64 bits

The digests of C in the record differ at every algebra, and so do those of `exact-kinds`, which
edits no library file. So only the checks by hand show the same C.

Times of that same C still stray beyond the spread of their date. Four evaluations of it, at pin
`edb0c9d` and `28f4e11`, moved 0 to 80 of the 88 to 135 times at each algebra. On 2026-10-15 the
median time was ×0.73 at rga3d and ×1.17 at cga4d, so the machine drifted during those runs. So
each moved time is the noise of this machine, and the static measurements carry the verdict.

### Time at 32 bits

`timing.nim` times each operation over 1024 multivectors, in a procedure of its own, as the
median nanoseconds per object over 41 rounds. Runs by hand at pin `edb0c9d` on 2026-10-06
alternated the two widths five times. Each run took one core of an Intel Xeon at 2.80 GHz with
SSE2. Each cell is the median over the runs of the time at 32 bits over the time at 64 bits. The
claims hold only that `timing.nim` runs, and the guard reads none of its times.

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
products spend their time in arithmetic, and one scalar operation costs the same at both widths.
So the wedge and the geometric product hold near ×1.00. Why the geometric product at cga5d alone
gains is unmeasured.

`★m` at rga3d loses, though its C is the same at both widths, apart from `0.0f` in place of
`0.0`. In the machine code, the caller builds the dual on its stack with stores of 4 and 8 bytes.
It then copies the dual out with loads of 16 bytes, and each load spans two or more of those
stores. A processor cannot forward such a load from its stores, so the load waits. That is the
likely cause, and this machine has no hardware counters to confirm it.

### Places at 32 bits

The suites ran by hand at 32 bits, at three comparison tolerances, at pin `edb0c9d` and again at
pin `28f4e11` on 2026-10-13. At 4 and 5 places the suites pass at each algebra. At 6 places,
cga5d passes 27 of 28, and each other algebra passes all.

`noise.nim` measures the noise that `=~` sees among unitized points, lines, planes and motors at
rga4d. Each law computes one object two ways that agree in exact arithmetic. The scene sits at a
distance from the origin, in its own units. Each cell is the most places that a comparison
tolerance may keep with no noise in 4096 samples. Runs at pin `edb0c9d` on 2026-10-06 and at pin
`28f4e11` on 2026-10-13 gave the same table.

| Distance | 64 bits | 32 bits | Point on line, 64 bits | Point on line, 32 bits |
|----------|---------|---------|------------------------|------------------------|
| 1 | 14 | 5 | 15 | 6 |
| 10 | 13 | 5 | 13 | 4 |
| 100 | 13 | 4 | 11 | 2 |
| 1,000 | 12 | 3 | 9 | 0 |
| 10,000 | 11 | 2 | 7 | 0 |
| 100,000 | 10 | 1 | 5 | 0 |
| 1,000,000 | 9 | 0 | 3 | 0 |

The columns 64 bits and 32 bits take the worst of three laws: a point moved twice, a join moved,
and a meet moved. Point on line tests `^(p ∧ q) ∧ r =~ 0`, where r lies on the line through p and q.

The noise lands in coefficients that should be zero or small, such as the `𝐞₃₂₁` part of a moved
point. The products build them from terms as large as the scene. `=~` weighs such a coefficient
against 1, so one place goes per decade of distance, and two for a point on a line.

P07 runs the same three laws in its `laws.nim`, with the same seed. Its samples differ, since
this program also draws a point on each line. So the rule of pin keeps 13 places at 100 here, and
12 there.
