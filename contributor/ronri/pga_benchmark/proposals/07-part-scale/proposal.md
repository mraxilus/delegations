# P07: Compare each part at its own scale

At pin, `=~` weighs the difference of each coefficient against max(1, |x|, |y|) of that
coefficient alone. `grade` counts a coefficient at or under the tolerance as zero. A product
builds small coefficients, and stray ones outside the grade of its result, from terms as large as
the scene. So their noise grows with the distance of the scene from the origin, and a fixed
tolerance holds only near it.

This proposal weighs each difference against the largest absolute value of its part, bulk or
weight, in either object. `grade` counts zero the same way. In a conformal algebra, `grade` also
counts a coefficient as zero within 16 rounding units of the largest coefficient. A conformal
product leaves rounding of its largest terms in parts far smaller than they are.

This proposal builds on P06, since its claims at 32 bits need the width that P06 makes
configurable. The Architect chose it on 2026-10-06, after a check that the gain holds for typed
objects too. The Architect ruled the conformal bound of `grade` on 2026-10-12.

## What it is

- **Parts.** The parts are those of `CAYLEYS_PARTS`, which the bulk and weight extractors read. A
  rigid algebra has bulk and weight. A conformal algebra splits each into round and flat. The
  comparison walks the fields of `CAYLEYS_PARTS`, so it adds no type or table of its own.
- **Scale.** The scale of a part is its largest absolute value, and at least one. A macro spells
  the bases of a part as an array, so a loop over it reads that part alone and unrolls.
- **Comparison.** `=~` takes each part in turn. It fails when a difference in that part is past
  the tolerance times the larger scale of that part in the two objects.
- **Scalar comparison.** `m =~ s` compares m with the scalar multivector of s, so one rule holds.
- **Grade.** `grade` counts a coefficient as zero at or under the tolerance times the scale of its
  part. `isMixed` reads `grade`, so it follows.
- **Grade in a conformal algebra.** `grade` takes the larger of that bound and 16 rounding units of
  the largest coefficient, 16ε times it. ε is the machine epsilon of the width, 2⁻⁵² at 64 bits
  and 2⁻²³ at 32 bits. One scan before the parts finds the largest coefficient. The rigid
  algebras keep the bound of the part alone.
- **Overflow.** A multivector with an infinite coefficient holds no grade. Its bound is infinite,
  so `grade` returns none, and `isMixed` reads it as mixed.

The scale of a part is never under one, nor under the absolute value of one of its coefficients. So
every pair equal at pin stays equal, and every coefficient zero at pin stays zero.

## What it gains

`laws.nim` moves unitized points, lines and planes by unit motors at rga4d, in scenes at a
distance from the origin. Three laws compute one object two ways that agree in exact arithmetic:
a point moved twice, a join moved, and a meet moved. Each cell is the most places that hold for
the worst of the three with no noise in 4096 samples, in this container on 2026-10-12.

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
held within about 100 units. At 32 bits, `grade` at pin reads a moved point as mixed from about
1,000 units. The stray in its plane slot passes the tolerance there. With this proposal it reads
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

### Grade in every algebra

`laws.nim` reads populations of 1,024 elements at each algebra. Each coordinate of a scene is
Gaussian, with a deviation from 1 to 1e8 units. Some populations are mixed: motion operators of
two flat planes, products of two of them, and general multivectors. In the conformal algebras,
products of two spheres join them, and at `cga5d` transversions and dilations. The others hold
one grade: objects moved once or 30 times, and k-vectors. In the conformal algebras, round
objects moved by a conformal motion operator and spheres of radius 1 to 1e6 join them.

Each cell counts the elements that a zero test misread, in this container on 2026-10-12. A
rounding unit is ε times the largest coefficient, and each such test takes the larger of it and
the part bound. Within a column, every test reads the same elements.

| Zero test, 64 bits | `rga3d` | `rga4d` | `cga4d` | `cga5d` |
|--------------------|---------|---------|---------|---------|
| Pin: the tolerance, absolute | 684 | 2,523 | 11,357 | 25,734 |
| Part scale alone | 0 | 0 | 1,158 | 1,812 |
| Tolerance of the largest coefficient | 123 | 59 | 157 | 132 |
| Part or 16 rounding units | 0 | 0 | 0 | 0 |
| Part or 256 rounding units | 0 | 0 | 0 | 0 |
| Part or 4,096 rounding units | 1 | 0 | 1 | 0 |
| `grade` of this proposal | 0 | 0 | 0 | 0 |
| Elements read | 49,152 | 62,464 | 132,096 | 180,224 |

- **Part scale alone.** In the conformal algebras it misreads far round objects as mixed. At a
  deviation of 1e8 units it misread 859 of 1,024 moved round points at `cga5d`, and 953 spheres.
  A round point that far holds more than 1e16 on 𝐞∞. A product leaves rounding of about 1 there,
  in a part whose scale stays at 1. In the rigid algebras it misreads nothing at 64 bits.
- **Largest coefficient alone.** It misreads far motion operators and products of two spheres as
  one grade. At a deviation of 1e8 units at `cga5d` it misread 65 and 65 of 1,024. Their 𝟙 part
  falls under 1e-9 of their largest coefficient.
- **This proposal.** Sixteen rounding units of the largest coefficient clear the residue of a far
  round object. They stay far under the 𝟙 part of a far motion operator. So at 64 bits `grade`
  reads every element right, and agrees with the twin test in `laws.nim` on each one. The
  program holds both as laws, and holds that it read all 1,024 elements of each population.

### At 32 bits

| Zero test, 32 bits | `rga3d` | `rga4d` | `cga4d` | `cga5d` |
|--------------------|---------|---------|---------|---------|
| Pin: the tolerance, absolute | 4,781 | 8,354 | 26,813 | 31,353 |
| Part scale alone | 3 | 3 | 7,752 | 5,589 |
| Tolerance of the largest coefficient | 9,460 | 1,441 | 9,500 | 5,520 |
| Part or 16 rounding units | 4,083 | 42 | 4,086 | 1,071 |
| Part or 256 rounding units | 7,644 | 694 | 7,662 | 3,709 |
| Part or 4,096 rounding units | 10,896 | 2,191 | 11,092 | 7,346 |
| `grade` of this proposal | 3 | 3 | 4,086 | 1,071 |
| Elements read | 49,152 | 46,255 | 122,038 | 133,739 |

The program skips each element that overflows, so it reads fewer at 32 bits in every algebra but
`rga3d`. At `rga4d` it reads few elements from 1e5 units. At `cga5d` it reads few motion
operators or objects moved once from 1e5 units, and no product of two spheres from 1e3. So the
columns read different elements. `cga5d` misreads fewer partly because it reads no motion
operator past 1e5 units, where `cga4d` misreads most of them.

No bound in rounding units of the largest coefficient reads every population right at 32 bits. At
5e4 units, the 𝟙 part of a translation was 336 to 581 rounding units. The residue of an object
moved 30 times reached about 1,000. So no multiple keeps the one and clears the other. A run by
hand measured both on 2026-10-12.

In the conformal algebras, this proposal misreads motion operators of two planes. At `cga4d` it
misreads 1 of 1,024 at a deviation of 1e3 units, 11 at 1e4, 809 at 1e6, and all of them at 1e8.
Products of two motion operators follow the same course there. At `cga5d` it misreads 15 of 1,024
from 1e4. It misreads every transversion of size 1e8 at `cga5d`. In every other population it
misreads at most 2 of 1,024.

### Why 16, and why only in the conformal algebras

- **The multiple.** At 64 bits, 16, 256 and 4,096 rounding units each misread at most 1 element
  in any algebra. At 32 bits in the conformal algebras, 16 misreads fewest. A larger multiple
  counts the 𝟙 part of a far motion operator as zero sooner.
- **The rigid algebras.** At 32 bits the part scale alone misreads 3 elements at `rga3d` and 3
  at `rga4d`. The conformal bound misreads 4,083 and 42 there, and the largest coefficient alone
  9,460 and 1,441. At 64 bits the part scale misreads none. So the rigid algebras keep the part
  scale alone.
- **P11's split.** P11 tells a round object by its round weight. A zero test can take the part
  scale where P11's test reads flat, and the largest coefficient where it reads round. A run by
  hand on 2026-10-12 found that it misread 140 elements at `cga5d` and 71 at `cga4d`, at 64 bits.

## What it keeps

The weight of a far object stays as strict as at pin. `laws.nim` turns the normal of each plane
by ten tolerances and keeps its position. At any distance, that plane never compares equal to the
plane it came from.

A scale of the whole object would cost less. But at 32 bits it would call the planes x = 10,000
and y = 10,000 equal. Their normals differ by 1, and that bound would be 1e-4 times 10,000. So
each part keeps a scale of its own.

## What it costs

`timing.nim` times both rules, with the rule of pin copied into the program. Each cell is the
median of three runs by hand in this container on 2026-10-12. Each run takes the median of 41
rounds over 1024 pairs or objects, in nanoseconds per pair or per object, on one core. Each point
has Gaussian coordinates of deviation 1000 units. At `rga4d`:

| Case, `rga4d` | Pin, 64 | Part, 64 | Pin, 32 | Part, 32 |
|---------------|---------|----------|---------|----------|
| Equal pair | 54.8 | 42.5 | 55.9 | 41.9 |
| Pair that differs in its scalar | 3.7 | 19.2 | 3.5 | 18.0 |
| Point beside the same point with a stray | 19.3 | 42.0 | 19.3 | 56.9 |
| `grade` of mixed multivector | 2.5 | 7.5 | 2.5 | 8.1 |
| `grade` of point | 8.2 | 25.0 | 8.1 | 26.1 |

An equal pair costs about a quarter less than at pin. Pin takes max(1, |x|, |y|) and a product
for each coefficient, and this rule takes one bound for each part. An unequal pair reads the
scale of its first part in both objects before it stops. At pin the pair with a stray is
unequal, and the comparison stops there. `grade` reads the scale of each part, so a point costs
about 17 ns more.

In the conformal algebras, `grade` also scans for the largest coefficient. The point is a round
point.

| Case, 64 bits | Pin, `cga4d` | This, `cga4d` | Pin, `cga5d` | This, `cga5d` |
|---------------|--------------|---------------|--------------|---------------|
| Equal pair | 59.9 | 43.8 | 142.3 | 120.3 |
| Pair that differs in its scalar | 2.1 | 21.2 | 2.5 | 46.5 |
| `grade` of mixed multivector | 2.8 | 16.7 | 4.2 | 29.1 |
| `grade` of round point | 8.1 | 31.1 | 29.0 | 62.4 |

| Case, 32 bits | Pin, `cga4d` | This, `cga4d` | Pin, `cga5d` | This, `cga5d` |
|---------------|--------------|---------------|--------------|---------------|
| Equal pair | 54.2 | 46.2 | 130.6 | 124.5 |
| Pair that differs in its scalar | 2.6 | 20.0 | 2.6 | 43.4 |
| `grade` of mixed multivector | 3.2 | 10.6 | 5.9 | 27.1 |
| `grade` of round point | 8.1 | 35.8 | 20.9 | 62.2 |

A build with the part scale alone timed the two cases of `grade` in the same runs. At 64 bits it
took 6.5 and 25.2 ns at `cga4d`, and 7.0 and 40.5 ns at `cga5d`. At 32 bits it took 7.2 and 24.2
ns, and 6.6 and 39.5 ns. So the scan adds about 3 to 12 ns at `cga4d` and 20 to 23 ns at `cga5d`.

The rule of pin is the same code in every build. Yet its `grade` of a round point at `cga5d` took
20.9 ns in that build and 29.0 ns in this one, at 64 bits. So a difference of up to about 40%
between two builds can come from the layout of the code alone.

It tests each coefficient with a branch. With `max` in place of the branch, `grade` of a mixed
multivector took 78 ns at `cga5d`. The probable cause is that each step of `max` waits on the
last. A loop that tests the part of each basis cost two to three times as much as a loop over
the bases of one part. So a macro spells those bases.

The partner `⊛` calls `grade` for its sign, so the evaluation moves it at `cga4d` and `cga5d`.
Over its kinds of operand, the evaluation of 2026-10-12 times the partner at ×1.19 to ×1.28 of
pin at `cga5d`. At `cga4d` it gives ×1.18 to ×1.20. Two evaluations earlier on the same day gave
×1.08 to ×1.32 over both. P03 folds that sign into the first table of the partner, so with P03
the partner calls no `grade`.

These costs fall on the dense `Multivector` alone. A typed object knows its grade from its type
when it compiles, so `grade` costs nothing there under either rule. It knows its parts too. So
the scale of a part is a `max` over its own few slots, as three for the bulk of a point.

## What it leaves out

- `$` still prints each coefficient above the tolerance, since it shows what the multivector
  stores. A far moved point prints its stray.
- A point on a line, `^(p ∧ q) ∧ r =~ 0`, compares with zero, so it has no scale to weigh against.
  It still loses two places a decade, at pin and here. A test of incidence by a distance in the
  units of the scene is outside this proposal.
- Noise of `=~` at a distance is measured at rga4d alone. The conformal algebras pass their
  suites at both widths, and the noise of their comparison at a distance is unmeasured. Their
  `grade` is measured, as above.
- At 32 bits a conformal `grade` misreads far motion operators, as above. The misread follows the
  size of the pose. So a 32-bit program keeps its scene within about 1e3 units of the origin, or
  takes 64 bits.
