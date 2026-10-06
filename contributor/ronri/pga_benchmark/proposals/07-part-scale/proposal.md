# P07: Compare each part at its own scale

At pin, `=~` weighs the difference of each coefficient against max(1, |x|, |y|) of that
coefficient alone. `grade` counts a coefficient at or under the tolerance as zero. A product
builds small coefficients, and stray ones outside the grade of its result, from terms as large as
the scene. So their noise grows with the distance of the scene from the origin, and a fixed
tolerance holds only near it. This proposal weighs each difference against the largest
magnitude of its part, bulk or weight, in either object, and `grade` counts zero the same way.

This proposal builds on P06, since its claims at 32 bits need the width that P06 makes
configurable. The Architect chose it on 2026-10-06, after a check that the gain holds for typed
objects too.

## What it is

- **Parts.** `PARTS` maps each basis to its part at compile time, as `CAYLEYS_PARTS` keeps it. A
  rigid algebra has bulk and weight. A conformal algebra has round bulk, round weight, flat bulk
  and flat weight. The scale of a part is its largest magnitude, and at least one. A macro spells
  it as one chain of `max` over the bases of that part alone.
- **Comparison.** `=~` passes each difference within the bound of its own coefficient first, as
  at pin. Only a difference past that bound reads the scale of its part in both objects, once a
  part, and fails past the tolerance times that scale.
- **Scalar comparison.** `m =~ s` compares m with the scalar multivector of s, so one rule holds.
- **Grade.** `grade` counts a coefficient as zero at or under the tolerance, or at or under the
  tolerance times the scale of its part.

The scale of a part is never under the magnitude of one of its coefficients. So every pair equal
at pin stays equal, and every coefficient zero at pin stays zero.

## What it gains

`laws.nim` moves unitized points, lines and planes by unit motors at rga4d, in scenes at a
distance from the origin. Three laws compute one object two ways that agree in exact arithmetic:
a point moved twice, a join moved, and a meet moved. Each cell is the most places that hold for
the worst of the three with no noise in 4096 samples, in this container on 2026-10-06.

| Distance | Pin, 64 | Part, 64 | Pin, 32 | Part, 32 | `grade` misread at pin, 32 |
|----------|---------|----------|---------|----------|----------------------------|
| 1 | 14 | 14 | 5 | 6 | 0 of 4096 |
| 10 | 13 | 13 | 5 | 5 | 0 of 4096 |
| 100 | 12 | 13 | 4 | 5 | 0 of 4096 |
| 1,000 | 12 | 13 | 3 | 5 | 27 of 4096 |
| 10,000 | 11 | 14 | 2 | 5 | 2084 of 4096 |
| 100,000 | 10 | 13 | 1 | 4 | 2962 of 4096 |
| 1,000,000 | 9 | 14 | 0 | 5 | 3049 of 4096 |

At pin, one place goes per decade of distance. With each part at its own scale, the places stay
level. So the default of 4 places at 32 bits holds at every distance measured, where at pin it
held within about 100 units. At pin, `grade` reads a moved point as mixed from about 1,000 units
at 32 bits, since the stray in its plane slot passes the tolerance. With this proposal it reads
grade one at every distance, at both widths.

Typed objects keep the gain. A typed point, line or plane holds no slot outside its type, so the
stray noise of a dense product goes. Noise still lands in small coefficients that the type holds,
such as a coordinate or a moment near zero. A copy of `reference/rigid3.nim` built at each width
ran the same laws by hand, since the reference holds 64 bits alone:

| Distance | Typed, pin, 32 | Typed, part, 32 | Typed, pin, 64 | Typed, part, 64 |
|----------|----------------|-----------------|----------------|-----------------|
| 1 | 5 | 5 | 14 | 14 |
| 100 | 4 | 5 | 13 | 13 |
| 1,000 | 3 | 4 | 12 | 12 |
| 10,000 | 3 | 4 | 11 | 13 |
| 1,000,000 | 0 | 5 | 10 | 13 |

## What it keeps

The weight of a far object stays as strict as at pin. `laws.nim` turns the normal of each plane
by ten tolerances and keeps its position, and that plane never compares equal to the plane it
came from, at any distance. A scale of the whole object would cost less, but it would call the
planes x = 10,000 and y = 10,000 equal at 32 bits. Their normals differ by 1, and that bound would
be 1e-4 times 10,000. So each part keeps a scale of its own.

## What it costs

`timing.nim` times both rules at rga4d, with the rule of pin copied into the program. Each cell
is the median of 41 rounds over 1024 pairs, in nanoseconds per pair, on one core:

| Case | Pin, 64 | Part, 64 | Pin, 32 | Part, 32 |
|------|---------|----------|---------|----------|
| Equal pair | 58.2 | 65.1 | 57.2 | 64.2 |
| Pair that differs in its scalar | 3.1 | 19.6 | 2.3 | 18.3 |
| Point 1000 units out, beside one with a stray | 18.3 | 39.6 | 17.1 | 41.4 |
| `grade` of mixed multivector | 2.2 | 12.6 | 2.2 | 12.7 |
| `grade` of point 1000 units out | 7.2 | 38.7 | 7.3 | 38.8 |

Two later runs give ratios within a fifth of these. An equal pair costs about a tenth more, since
every difference passes the bound of its own coefficient. An unequal pair, or a coefficient past
that bound, costs one read of its part in both objects. At pin the pair with a stray is unequal,
and the comparison stops there. `grade` reads each part that holds a coefficient past the
tolerance, so a point costs about 31 ns more.

At cga5d each part holds 8 of 32 bases. By hand on one core, over blades of grades one to four,
`grade` took 18 to 36 ns at pin and 48 to 104 ns here. The partner `⊛` calls `grade` for its
sign, so the evaluation moves it at cga4d and cga5d. It times the partner at ×1.15 to ×1.33 of
pin at cga5d, and at ×1.23 to ×1.32 at cga4d, over its kinds of operand. P03 folds that sign into
the first table of the partner, so with P03 the partner calls no `grade`. A loop over every basis
for each part cost twice the chain of `max` for `grade`, so the scale of each part is that chain.

These costs fall on the dense `Multivector` alone. A typed object knows its grade from its type
when it compiles, so `grade` costs nothing there under either rule. It knows its parts too, so the
scale of a part is a `max` over its own few slots, as three for the bulk of a point.

## What it leaves out

- `$` still prints each coefficient above the tolerance, since it shows what the multivector
  stores. A far moved point prints its stray.
- A point on a line, `^(p ∧ q) ∧ r =~ 0`, compares with zero, so it has no scale to weigh against.
  It still loses two places a decade, at pin and here. A test of incidence by a distance in the
  units of the scene is outside this proposal.
- Noise at a distance is measured at rga4d alone. The conformal algebras pass their suites at
  both widths, and their noise at a distance is unmeasured.
