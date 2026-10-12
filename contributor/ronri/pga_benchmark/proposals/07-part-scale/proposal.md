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
| Pin: the tolerance, absolute | 673 | 2,543 | 11,289 | 25,750 |
| Part scale alone | 0 | 0 | 1,112 | 1,867 |
| Tolerance of the largest coefficient | 123 | 54 | 163 | 131 |
| Part or 16 rounding units | 0 | 0 | 0 | 0 |
| Part or 256 rounding units | 0 | 0 | 0 | 0 |
| Part or 4,096 rounding units | 1 | 0 | 1 | 0 |
| `grade` of this proposal | 0 | 0 | 0 | 0 |
| Elements read | 49,152 | 62,464 | 132,096 | 180,224 |

- **Part scale alone.** In the conformal algebras it misreads far round objects as mixed. At
  1e8 units it misread 903 of 1,024 moved round points at `cga5d`, and 964 spheres. A round point
  that far holds more than 1e16 on 𝐞∞. A product leaves rounding of about 1 there, in a part
  whose scale stays at 1. In the rigid algebras it misreads nothing at 64 bits.
- **Largest coefficient alone.** It misreads far motion operators and products of two spheres as
  one grade: 66 and 64 of 1,024 at 1e8 units at `cga5d`. Their 𝟙 part falls under 1e-9 of
  their largest coefficient.
- **This proposal.** Sixteen rounding units of the largest coefficient clear the residue of a far
  round object. They stay far under the 𝟙 part of a far motion operator. So at 64 bits `grade`
  reads every element right, and agrees with the twin test in `laws.nim` on each one. The
  program holds both as laws, and holds that it read all 1,024 elements of each population.

### At 32 bits

| Zero test, 32 bits | `rga3d` | `rga4d` | `cga4d` | `cga5d` |
|--------------------|---------|---------|---------|---------|
| Pin: the tolerance, absolute | 4,776 | 8,355 | 26,854 | 31,330 |
| Part scale alone | 5 | 4 | 7,777 | 5,560 |
| Tolerance of the largest coefficient | 9,463 | 1,432 | 9,499 | 5,488 |
| Part or 16 rounding units | 4,087 | 46 | 4,090 | 1,078 |
| Part or 256 rounding units | 7,646 | 679 | 7,663 | 3,741 |
| Part or 4,096 rounding units | 10,898 | 2,169 | 11,087 | 7,332 |
| `grade` of this proposal | 5 | 4 | 4,090 | 1,078 |
| Elements read | 49,152 | 46,270 | 122,024 | 133,721 |

The program skips each element that overflows, so it reads fewer at 32 bits. At `rga4d` it reads
few elements from 1e5 units. At `cga5d` it reads few motion operators or moved objects from 1e5
units, and no product of two spheres from 1e3. So the columns read different elements, and
`cga5d` misreads fewer partly because it holds less.

No bound in rounding units of the largest coefficient reads every population right at 32 bits. At
5e4 units, the 𝟙 part of a translation was 336 to 581 rounding units. The residue of an object
moved 30 times reached about 1,000. So no multiple keeps the one and clears the other. A run by
hand measured both on 2026-10-12.

In the conformal algebras, this proposal misreads motion operators of two planes from 1e3 units:
2 of 1,024 at both, and 10 at 1e4. At `cga4d` that rises to 809 at 1e6 units, and to all of them
at 1e8. Products of two motion operators follow the same course there. It misreads every
transversion of size 1e8 at `cga5d`. In every other population it misreads at most 1 of 1,024.

### Why 16, and why only in the conformal algebras

- **The multiple.** At 64 bits, 16, 256 and 4,096 rounding units each misread at most 1 element
  in any algebra. At 32 bits in the conformal algebras, 16 misreads fewest. A larger multiple
  counts the 𝟙 part of a far motion operator as zero sooner.
- **The rigid algebras.** At 32 bits the part scale alone misreads 5 elements at `rga3d` and 4
  at `rga4d`. The conformal bound misreads 4,087 and 46 there, and the largest coefficient alone
  9,463 and 1,432. At 64 bits the part scale misreads none. So the rigid algebras keep the part
  scale alone.
- **P11's split.** P11 tells a round object by its round weight. A zero test can take the part
  scale where P11's test reads flat, and the largest coefficient where it reads round. A run by
  hand on 2026-10-12 found that it misread 140 elements at `cga5d` and 71 at `cga4d`, at 64 bits.

## What it keeps

The weight of a far object stays as strict as at pin. `laws.nim` turns the normal of each plane
by ten tolerances and keeps its position, and that plane never compares equal to the plane it
came from, at any distance. A scale of the whole object would cost less, but it would call the
planes x = 10,000 and y = 10,000 equal at 32 bits. Their normals differ by 1, and that bound would
be 1e-4 times 10,000. So each part keeps a scale of its own.

## What it costs

`timing.nim` times both rules, with the rule of pin copied into the program. Each cell is the
median of three runs by hand in this container on 2026-10-12. Each run takes the median of 41
rounds over 1024 pairs, in nanoseconds per pair, on one core. At `rga4d`:

| Case, `rga4d` | Pin, 64 | Part, 64 | Pin, 32 | Part, 32 |
|---------------|---------|----------|---------|----------|
| Equal pair | 61.9 | 37.9 | 48.7 | 32.3 |
| Pair that differs in its scalar | 2.1 | 17.9 | 2.2 | 14.9 |
| Point 1000 units out, beside one with a stray | 18.7 | 38.1 | 18.1 | 35.3 |
| `grade` of mixed multivector | 2.6 | 6.9 | 2.7 | 7.9 |
| `grade` of point 1000 units out | 8.1 | 23.5 | 7.0 | 21.7 |

An equal pair costs about a third less than at pin. Pin takes max(1, |x|, |y|) and a product
for each coefficient, and this rule takes one bound for each part. An unequal pair reads the
scale of its first part in both objects before it stops. At pin the pair with a stray is
unequal, and the comparison stops there. `grade` reads the scale of each part, so a point costs
about 15 ns more.

In the conformal algebras, `grade` also scans for the largest coefficient. The point is a round
point about 1000 units out. At 64 bits:

| Case, 64 bits | Pin, `cga4d` | This, `cga4d` | Pin, `cga5d` | This, `cga5d` |
|---------------|--------------|---------------|--------------|---------------|
| Equal pair | 46.4 | 39.2 | 132.2 | 98.8 |
| Pair that differs in its scalar | 1.8 | 18.7 | 2.3 | 42.1 |
| `grade` of mixed multivector | 2.8 | 8.9 | 3.9 | 26.4 |
| `grade` of round point | 7.7 | 28.6 | 26.9 | 54.8 |

At 32 bits each figure lies within about a fifth of its twin at 64 bits. The part scale alone
took 5.8 and 22.5 ns for the two cases of `grade` at `cga4d`, and 6.8 and 38.3 ns at `cga5d`. So
the scan adds about 3 to 20 ns. It tests each coefficient with a branch. With `max` in place of
the branch, `grade` of a mixed multivector took 78 ns at `cga5d`. The probable cause is that each
step of `max` waits on the last. A loop over every basis that tests the part of each cost two to
three times as much as a loop over the bases of a part alone, so a macro spells those bases.

The partner `⊛` calls `grade` for its sign, so the evaluation moves it at `cga4d` and `cga5d`.
The evaluation of 2026-10-12 times the partner at ×1.22 to ×1.32 of pin at `cga5d`, and at ×1.08
to ×1.26 at `cga4d`, over its kinds of operand. An evaluation earlier on the same day gave ×1.16
to ×1.28 over both. P03 folds that sign into the first table of the partner, so with P03 the
partner calls no `grade`.

These costs fall on the dense `Multivector` alone. A typed object knows its grade from its type
when it compiles, so `grade` costs nothing there under either rule. It knows its parts too, so the
scale of a part is a `max` over its own few slots, as three for the bulk of a point.

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
