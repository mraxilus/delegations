# P07: Compare each part at its own scale

At pin, `=~` weighs the difference of each coefficient against max(1, |x|, |y|) of that
coefficient alone. `grade` counts a coefficient at or under the tolerance as zero. A product
builds small coefficients, and stray ones outside the grade of its result, from terms as large as
the scene. So their noise grows with the distance of the scene from the origin, and a fixed
tolerance holds only near it. This proposal weighs each difference against the largest absolute
value of its part, bulk or weight, in either object, and `grade` counts zero the same way. In a
conformal algebra, `grade` also counts a coefficient as zero within 16 rounding units of the
largest coefficient, since a conformal product leaves rounding of its largest terms in parts far
smaller than they are.

This proposal builds on P06, since its claims at 32 bits need the width that P06 makes
configurable. The Architect chose it on 2026-10-06, after a check that the gain holds for typed
objects too. The Architect ruled the conformal bound of `grade` on 2026-10-12, as D4 e.

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

### In the conformal algebras

`laws.nim` reads populations of 1,024 elements at `cga5d` and `cga4d`, at spreads from 1 to 1e8
units. Some are mixed: motion operators of two flat planes, products of two of them, products of
two spheres, and at `cga5d` transversions and dilations. The others hold one grade. These are
round and flat objects moved once by a rigid motion operator, and round objects moved by a
conformal one. Spheres of radius 1 to 1e6, objects moved 30 times, and k-vectors join them.

Each cell counts the elements that a zero test misread, in this container on 2026-10-12. At 64
bits the test read 180,224 elements at `cga5d` and 132,096 at `cga4d`. At 32 bits it read fewer,
since it skips each element that overflows.

| Zero test | `cga5d`, 64 | `cga4d`, 64 | `cga5d`, 32 | `cga4d`, 32 |
|-----------|-------------|-------------|-------------|-------------|
| Pin: the tolerance, absolute | 25,734 | 11,357 | 31,353 | 26,813 |
| Part scale alone | 1,812 | 1,158 | 5,589 | 7,752 |
| Tolerance of the largest coefficient | 132 | 157 | 5,520 | 9,500 |
| This proposal | 0 | 0 | 1,071 | 4,086 |

- **Part scale alone.** It misreads far round objects as mixed. At 1e8 units it misread 859 of
  1,024 moved round points at `cga5d`, and 953 spheres. A round point that far holds about 5e15
  on 𝐞∞. A product leaves rounding of that size in a part whose scale stays at 1.
- **Largest coefficient alone.** It misreads far motion operators and products of two spheres as
  one grade, 65 of 1,024 of each at 1e8 units at `cga5d`. Their 𝟙 part falls under 1e-9 of
  their largest coefficient.
- **This proposal.** Sixteen rounding units of the largest coefficient clear the residue of a far
  round object. They stay far under the 𝟙 part of a far motion operator. So at 64 bits `grade`
  reads every population right, and `laws.nim` holds that as a law.

### At 32 bits

No zero test that reads values alone reads every population right at 32 bits. At 5e4 units, the
𝟙 part of a motion operator was 336 to 581 rounding units of its largest coefficient. The
residue of an object moved 30 times reached about 1,000. So no bound keeps the one and clears the
other. A run by hand measured both on 2026-10-12.

This proposal misreads motion operators of two planes from 1e4 units: 15 of 1,024 at `cga5d`, and
11 at `cga4d`. At `cga4d` that rises to 809 at 1e6 units, and to all of them at 1e8. It misreads
every transversion of size 1e8 at `cga5d`. Products of two motion operators follow the same course
at `cga4d`. Up to 1e3 units it misreads at most 2 of 1,024 in any population.

### Why 16, and why only in the conformal algebras

- **The multiple.** A run by hand on 2026-10-11 tried 16, 256 and 4,096 rounding units. Each read
  every moved object right at 64 bits. At 32 bits at `cga5d`, 4,096 read a pure translation as
  one grade from 1e4 units, and 256 from 1e5. 16 held to 1e6, so it serves farthest.
- **The rigid algebras.** A run by hand on 2026-10-12 read the same kinds of population at `rga4d`
  and `rga3d`. At 32 bits the part scale alone misread 2 and 1 of them. The bound of this
  proposal misread 48 and 4,115, and the largest coefficient alone 1,434 and 9,426. At 64 bits
  the part scale misread none. So the rigid algebras keep the bound of the part alone.
- **P11's split.** P11 tells a round object by its round weight. A zero test can take the part
  scale where P11's test reads flat, and the largest coefficient where it reads round. The run of
  2026-10-12 found that it misread 140 elements at `cga5d` and 71 at `cga4d`, at 64 bits.

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
| Equal pair | 55.8 | 37.4 | 53.1 | 37.4 |
| Pair that differs in its scalar | 2.1 | 17.9 | 3.5 | 18.0 |
| Point 1000 units out, beside one with a stray | 18.7 | 37.3 | 19.3 | 37.3 |
| `grade` of mixed multivector | 2.7 | 6.6 | 2.8 | 7.5 |
| `grade` of point 1000 units out | 7.9 | 21.0 | 8.1 | 21.8 |

Two later runs give ratios within a fifth of these. An equal pair costs about a third less than at
pin. Pin takes max(1, |x|, |y|) and a product for each coefficient, and this rule takes one bound
for each part. An unequal pair reads the scale of its first part in both objects before it stops.
At pin the pair with a stray is unequal, and the comparison stops there. `grade` reads the scale
of each part, so a point costs about 13 ns more.

At cga5d each part holds 8 of 32 bases. By hand on one core, over blades of grades one to four,
the median of three runs of `grade` took 20 to 23 ns at pin and 44 to 56 ns here. At cga4d it took
14 to 19 ns at pin and 18 to 25 ns here. The partner `⊛` calls `grade` for its sign, so the
evaluation moves it at cga4d and cga5d. It times the partner at ×1.06 to ×1.20 of pin at cga5d, and
at ×1.07 to ×1.10 at cga4d, over its kinds of operand. P03 folds that sign into the first table of
the partner, so with P03 the partner calls no `grade`. A loop over every basis that tests the part
of each cost two to three times as much as a loop over the bases of a part alone. So a macro
spells those bases.

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
- At 32 bits a conformal `grade` misreads far motion operators, as above. A program that keeps
  each motion operator as its source values, and composes it again each frame, keeps it small.
