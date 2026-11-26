# P07: Compare each part at its own scale

**What it is.** `=~` and `grade` weigh each coefficient against the largest absolute value of its
own part, bulk or weight, and at least 1, where pin weighs it against 1 alone. In a conformal
algebra, `grade` also counts a coefficient as zero within rounding of the largest coefficient.

**What it is for.** At pin the places of precision fall with the distance from the origin. Here
they stay level at every distance measured, and `grade` misreads far fewer elements.

**What it costs.** In runs at library commit `3d9696e`, a pair that differs takes 6 to 12 ns to
compare, against 2 to 3 ns under the rule of pin. A conformal `grade` takes 1.5 to 3.5 times as
long as under the rule of pin. A multivector with a coefficient that is not finite equals nothing,
itself included.

## Problem

At pin, `=~` weighs the difference of each coefficient against max(1, |x|, |y|) of that
coefficient alone. `grade` counts a coefficient as zero at or under the comparison tolerance, which
is absolute. A product builds small coefficients, and stray ones outside the grade of its result,
from terms as large as the scene. Their noise grows with the distance from the origin, so a fixed
comparison tolerance holds only near it, and one decimal place goes per decade. At 32 bits at pin,
`grade` reads a moved point as mixed from about 1 000 units. There the stray in its plane
coefficient passes the comparison tolerance.

## Idea

- **Parts.** The parts are those of `CAYLEYS_PARTS`, which the bulk and weight extractors read. A
  rigid algebra has bulk and weight. A conformal algebra splits each into round and flat. The
  comparison walks the fields of `CAYLEYS_PARTS`, so it adds no type or table of its own.
- **Scale.** The scale of a part is its largest absolute value, and at least one. A macro spells
  the bases of a part as an array, so a loop over it reads that part alone and unrolls. A branch,
  as in the scan of `grade`, finds the largest value.
- **Comparison.** `=~` takes each part in turn. It fails when a difference in that part is past
  the comparison tolerance times the larger scale of that part in the two objects. `m =~ s`
  compares m with `initElement(Basis.scalar, s)`, so one rule holds. The private `=~` of two
  scalars stays, since the narrowing check of `toMultivectorOf` reads it.
- **Sets of bases.** `=~` stays generic over the set of bases of its multivectors, as at pin. The
  macro spells the bases of a part that the set holds, so `MultivectorScalars` compares its two
  coefficients alone.
- **Grade.** `grade` counts a coefficient as zero at or under the comparison tolerance times the
  scale of its part. `isMixed`, `gradeAnti` and the partner `⊛` read `grade`, so they follow.
- **Grade in a conformal algebra.** `grade` takes the larger of that bound and 16 rounding units of
  the largest coefficient, 16ε times it. ε is the machine epsilon of the width, 2⁻⁵² at 64 bits
  and 2⁻²³ at 32 bits. One scan before the parts finds the largest coefficient. The rigid
  algebras keep the bound of the part alone.

The scale of a part is never under one, nor under the absolute value of one of its coefficients.
So where every coefficient is finite, every pair equal at pin stays equal, and every coefficient
zero at pin stays zero.

### Why rounding units, in the conformal algebras alone

A conformal product leaves rounding of its largest terms in parts far smaller than they are. On
𝐞∞, a round point at a deviation of 1e8 units holds about 1e16. A product leaves rounding of about
1 there, in a part whose scale stays at 1. So the part scale alone reads a far round object as
mixed.

The largest coefficient alone fails the other way. It reads far motion operators and products of
two spheres as one grade, since their 𝟙 part falls under 1e-9 of their largest coefficient.
Sixteen rounding units of the largest coefficient clear the residue of a far round object. They
stay far under the 𝟙 part of a far motion operator. The conformal bound stands as the Architect
ruled on 2026-10-12.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Scale of the whole object | At 32 bits it calls the planes x = 10 000 and y = 10 000 equal |
| A larger multiple of rounding units | The 𝟙 part of a far motion operator falls under it sooner |
| Rounding units in the rigid algebras | The part scale alone misreads far fewer at 32 bits |
| The split of P11 | At 64 bits it misreads more conformal elements than this bound |
| `max` in place of the branch | Each step of `max` waits on the last, so a scan takes longer |
| A loop that tests the part of each basis | `=~` takes 1.6 to 15 times as long, `grade` 1.3 to 5 |

The normals of those two planes differ by 1, and the bound of the whole object would be 1e-4 times
10 000. Each part takes a scale of its own, as the Architect ruled on 2026-10-06, since the gain
holds for typed objects too.

At 64 bits, 16, 256 and 4 096 rounding units each misread at most one element in any algebra. At
32 bits in the conformal algebras, 16 misreads fewest. In the rigid algebras the part scale alone
misreads none at 64 bits.

The split of P11 tells a round object by its round weight. Its zero test takes the part scale where
that test reads flat, and the largest coefficient where it reads round.

The branch stands in the scan of `grade` and in `scale`. Evidence, Time, gives the measures of
`max` and of the loop that tests the part of each basis.

A lookup table from each basis to its part gives that loop. It names the members of
`CAYLEYS_PARTS` once, in a `const`. `=~` then takes one loop over the bases of its set. `grade`
takes one loop over every basis, and keeps the guard `continue` of pin. That form holds the idioms
of pin but for an integer part number, and it keeps the import of `./cayleys`.

## Costs

- **Time.** The runs under Time took library commit `3d9696e`. Pin `7ef9f4d` reads a coefficient of
  a whole multivector by a basis known only at run time with no call. So both rules probably run
  faster there, and their ratios can move, but no run measures that. A pair that differs reads the
  scale of its first part in both objects before it stops. So it takes 6 to 12 ns, against
  2 to 3 ns under the rule of pin. `grade` reads the scale of each part, and in a conformal algebra
  it also scans for the largest coefficient. So it takes up to 1.3 times as long at rga4d, and 1.5
  to 3.5 times as long at cga4d and cga5d. `m =~ s` builds the scalar multivector of s and
  compares it part by part. At pin it compares each coefficient with s or with zero, with no scale
  of a part. At rga4d at 64 bits `m =~ 0` takes 1.7 times as long, and in each other build it takes
  ×0.88 to ×1.05 of the time of pin. An equal pair takes about a quarter of the time of pin.
- **Typed objects.** These costs fall on the types of the library at pin. A typed object knows its
  grade from its type when it compiles, so `grade` would cost nothing there under either rule. It
  knows its parts too. So the scale of a part is the largest of its own few coefficients, as three
  for the bulk of a point.
- **Partner.** `⊛` calls `grade` for its sign, so it slows at cga4d and cga5d too. P03 folds
  that sign into the first table of the partner, so with P03 the partner calls no `grade`.
- **Not finite.** A multivector with a coefficient that is not finite equals nothing, itself
  included. At pin NaN fails too, but an infinite coefficient equals any finite one. An infinite
  coefficient makes the bound of its part infinite, so `grade` returns none, and `isMixed` reads
  the multivector as mixed. So `⊛` stops on such an operand, since it reads `m.grade.get`. At pin
  such an operand can still hold one grade, and `⊛` goes on.
- **Callers.** No exported signature changes, so no caller changes its text. Each test that reads
  `=~` takes the new rule.
- **Narrowing.** `toMultivectorOf` still asserts each coefficient that it drops at the comparison
  tolerance, absolute. So a far object that `grade` reads as one grade does not narrow to the type
  of that grade.
- **Form.** `bases` is the first macro of the library that yields a value. At pin each macro is a
  private `define` macro that emits definitions. The loops walk `CAYLEYS_PARTS` with the iterator
  `fields`, which pin never uses. That iterator refuses `continue`, so `grade` counts a zero by
  `discard`, where pin skips it by the guard `continue`.
- **Conformal grade at 32 bits.** A conformal `grade` misreads far motion operators at 32 bits,
  and the misread follows the size of the pose. No multiple of rounding units reads every
  population right at this width. So a 32-bit program keeps its scene within about 1e3 units of
  the origin, or takes 64 bits.
- **Print.** `$` still prints each coefficient above the comparison tolerance, since it shows what
  the multivector stores. A far moved point prints its stray.
- **Incidence.** A point on a line, `^(p ∧ q) ∧ r =~ 0`, compares with zero, so it has no scale
  to weigh against. It still loses two decimal places a decade, at pin and here. A test of
  incidence by a distance in the units of the scene is outside this proposal.
- **Comparison far out.** Noise of `=~` at a distance is measured at rga4d alone. In the
  conformal algebras it is unmeasured, and only `grade` is measured.
- **Basis-set types.** `=~` takes each `MultivectorOf[B]`, as at pin, and reads only the parts of
  B. `grade` takes the dense `Multivector` alone, as at pin. Evidence measures the dense type, and
  the typed reference there is no basis-set type.

## Open decisions

- One zero test for `grade` and for `^∘` of P11, or two tests as now. P11 holds the same
  decision. One test with this `grade` fails the law of P11 that `^∘` is homogeneous, at a factor
  of 1e-100 in its `laws.nim`, since the scale of a part is at least one. So one test needs a
  `grade` whose part scale has no floor.
- The macro `bases` and the read of `CAYLEYS_PARTS` in `pga/multivectors.nim`, as here, or a
  lookup table from each basis to its part. With that table `=~` takes 1.6 to 15 times as long,
  and `grade` 1.3 to 5 times.

## Landing

- **P06, `float-width`.** It is implemented at pin `3d9696e`. The 32-bit claims build at the width
  that it makes configurable.
- **Imports.** The new import of `./cayleys` forms no cycle, since `pga/cayleys.nim` imports
  `./algebra` alone, at pin and under P01. At pin `pga/multivectors.nim` names no table. Here it
  imports `pga/cayleys.nim`, its macro `bases` indexes a table, and `scale` takes a table as a
  `static` parameter. At pin only the two `defineOperator` macros of `pga/operators.nim` take a
  table as a `static` parameter. No table reaches run time.
- **Change `doc-comments-2`.** It adds a line under the doc of `grade`, which the third edit
  quotes. Where this proposal lands second, its third edit quotes that line too. Where
  `doc-comments-2` lands second, its edit applies as written, and its line stands above the doc
  lines that this proposal adds.
- **Change `algebra-hygiene`.** It renames the exported constant `TOLERANCE_ABS` to
  `TOLERANCE_REL`, and with it the zero test of `grade` that this proposal replaces. The second of
  the two to land quotes the first again. Once `algebra-hygiene` lands, the new code and the
  programs `laws.nim` and `timing.nim` take the new name.
- **P03, `partner-sign`, and P11, `unitize-general`.** Neither edits a line here. A test that P11
  adds to suite Internal compares two multivectors through the public `=~`, as
  `abs((𝐯 ∘ 𝐯)[Basis.scalarAnti]) ∧ 𝟙 =~ 𝟙`. So that test reads this rule once both land. A run
  by hand on 2026-11-15 applied this proposal and P11 to a copy of the library at `3d9696e`. The
  suites passed at rga3d, rga4d, cga4d and cga5d, at 64 and at 32 bits.
- **Two zero tests.** P11 keeps its own grade scan in `^∘`, at the comparison tolerance times the
  largest coefficient. So once both land, `grade` and `^∘` can read one element differently. That
  scan is the test of the largest coefficient alone, under Evidence.

## Evidence

### Places at a distance

`laws.nim` moves unitized points, lines and planes by unit motors at rga4d, in scenes at a distance
from the origin. Three laws compute one object two ways that agree in exact arithmetic: a point
moved twice, a join moved, and a meet moved. Each cell is the most places that hold for the worst
of the three with no noise in 4 096 samples. The runs took pin on `linux amd64, 4 cores` on
2026-10-19. Pin is
the rule of pin, which `laws.nim` copies, and P07 the rule of this proposal. Pin at 32 bits is pin
built with `-d:pga.float_width=32`.

| Distance | Pin, 64 | P07, 64 | Pin, 32 | P07, 32 | `grade` misread by pin, 32 |
|----------|---------|---------|---------|---------|----------------------------|
| 1 | 14 | 14 | 5 | 6 | 0 of 4 096 |
| 10 | 13 | 13 | 5 | 5 | 0 of 4 096 |
| 100 | 12 | 13 | 4 | 5 | 0 of 4 096 |
| 1 000 | 12 | 13 | 3 | 5 | 27 of 4 096 |
| 10 000 | 11 | 14 | 2 | 5 | 2 084 of 4 096 |
| 100 000 | 10 | 13 | 1 | 4 | 2 962 of 4 096 |
| 1 000 000 | 9 | 14 | 0 | 5 | 3 049 of 4 096 |

So the default of 4 places at 32 bits holds at every distance measured, where at pin it held
within about 100 units. With this proposal, `grade` reads a moved point as grade one at every
distance, at both widths. These samples differ from those of `noise.nim` in P06, which also draws
a point on each line. So the rule of pin keeps 12 places at 100 units here, and 13 there.

`laws.nim` also turns the normal of each plane by ten comparison tolerances and keeps its position.
At any distance, that plane never compares equal to the plane it came from. So the weight of a far
object stays as strict as at pin.

The typed reference keeps the gain. A typed point, line or plane holds no coefficient outside its
type, so the stray noise of a dense product goes. Noise still lands in small coefficients that the
type holds, such as a coordinate or a moment near zero. The reference holds 64 bits alone, so a copy
of `reference/rigid3.nim` built at each width ran the same laws by hand. Under P07 it kept 4 to 5
places at 32 bits at every distance, where the rule of pin fell to 0 at 1 000 000 units. At 64
bits it kept 12 to 14, where pin fell to 10.

### Grade in every algebra

`laws.nim` reads populations of 1 024 elements at each algebra, each coordinate Gaussian with a
deviation from 1 to 1e8 units. Mixed populations are motion operators of two flat planes, products
of two of them, and general multivectors. The conformal algebras add products of two spheres, and
cga5d transversions and dilations. Populations of one grade are objects moved once or 30 times,
and k-vectors. The conformal algebras add spheres, and round objects moved by a conformal motion
operator.

Each cell counts the elements that a zero test misread, on `linux amd64, 4 cores` on 2026-10-19 at
pin. Pin is the comparison tolerance, absolute, as at pin. Part or n takes the larger of the
part bound and n rounding units of the largest coefficient. Within a row, every test reads the same
elements.

| Algebra, bits | Pin | Part | Largest | Part or 16 | Part or 256 | Part or 4 096 | Read |
|---------------|-----|------|---------|------------|-------------|---------------|------|
| rga3d, 64 | 684 | 0 | 123 | 0 | 0 | 1 | 49 152 |
| rga4d, 64 | 2 523 | 0 | 59 | 0 | 0 | 0 | 62 464 |
| cga4d, 64 | 11 357 | 1 158 | 157 | 0 | 0 | 1 | 132 096 |
| cga5d, 64 | 25 734 | 1 812 | 132 | 0 | 0 | 0 | 180 224 |
| rga3d, 32 | 4 781 | 3 | 9 460 | 4 083 | 7 644 | 10 896 | 49 152 |
| rga4d, 32 | 8 354 | 3 | 1 441 | 42 | 694 | 2 191 | 46 255 |
| cga4d, 32 | 26 813 | 7 752 | 9 500 | 4 086 | 7 662 | 11 092 | 122 038 |
| cga5d, 32 | 31 353 | 5 589 | 5 520 | 1 071 | 3 709 | 7 346 | 133 739 |

The twin of `grade` in `laws.nim` is the Part test in the rigid algebras, and Part or 16 in the
conformal ones. `grade` of P07 misread as many elements as its twin, at each algebra and width.
`laws.nim` holds as a law that `grade` agrees with its twin on each element, at each width. At 64
bits it also holds that `grade` reads all 1 024 elements of each population, and reads each right.

At cga5d and a deviation of 1e8 units, the part scale alone misread 859 of 1 024 moved round
points, and 953 spheres. The largest coefficient alone misread 65 of 1 024 motion operators, and 65
products of two spheres.

At 32 bits the program skips each element that overflows, so it reads fewer in every algebra but
rga3d, and the rows read different elements. cga5d misreads fewer than cga4d partly because
it reads no motion operator past 1e5 units, where cga4d misreads most of them.

At 32 bits in the conformal algebras, `grade` of P07 misreads motion operators of two planes. At
cga4d it misreads 1 of 1 024 at a deviation of 1e3 units, 11 at 1e4, 809 at 1e6, and all of
them at 1e8. Products of two motion operators follow the same course there. At cga5d it misreads
15 of 1 024 at 1e4 and 31 of 897 at 3e4, and every transversion of size 1e8. In every other
population it misreads at most 2 of 1 024.

At that deviation of 1e4 units at cga5d, the residue of one sphere moved 30 times passed 4 096
rounding units. So that bound read it as mixed, and every multiple misreads a motion operator or
that sphere.

A run by hand on 2026-10-12 took the split of P11 as a zero test. It misread 140 elements at cga5d
and 71 at cga4d, at 64 bits.

### Laws of comparison

`laws.nim` also holds two laws of `=~` in each algebra. A multivector with a coefficient that is not
finite equals neither itself nor the finite multivector that it came from. Also, `m =~ s` weighs
a stray beside the scalar against the scale of the part of the scalar. A stray of 500 comparison
tolerances beside a scalar of 1 000 compares equal, and one of 2 000 does not.

### Time

`timing.nim` times both rules in one build, with the rule of pin copied into the program. Each
cell is the median of 14 runs by hand on `linux amd64, 4 cores` on 2026-11-14, in nanoseconds per
pair or per object, on one core of a Xeon of family 6 model 173. Those runs took the library at
pin `3d9696e` with `change.md` applied, under gcc 13.3.0. Each run takes the median of 41 rounds
over 1 024 pairs or objects. Each point has Gaussian coordinates of deviation 1 000 units, and is
a round point in a conformal algebra. Each dense multivector has Gaussian coefficients of
deviation 1. Each multivector near zero has Gaussian coefficients of deviation a tenth of the
comparison tolerance.

| Case, 64 bits | Pin, rga4d | P07, rga4d | Pin, cga4d | P07, cga4d | Pin, cga5d | P07, cga5d |
|---------------|------------|------------|------------|------------|------------|------------|
| Equal pair | 52.2 | 13.3 | 47.6 | 12.2 | 109.9 | 25.4 |
| Pair that differs in its scalar | 1.9 | 6.4 | 2.9 | 6.2 | 2.2 | 12.0 |
| `grade` of mixed multivector | 5.8 | 6.5 | 5.8 | 8.8 | 5.8 | 20.1 |
| `grade` of point | 16.6 | 16.8 | 13.0 | 26.3 | 32.2 | 47.3 |
| `m =~ 0` near zero | 14.9 | 25.2 | 25.5 | 26.9 | 41.3 | 37.1 |

| Case, 32 bits | Pin, rga4d | P07, rga4d | Pin, cga4d | P07, cga4d | Pin, cga5d | P07, cga5d |
|---------------|------------|------------|------------|------------|------------|------------|
| Equal pair | 47.1 | 14.1 | 46.2 | 13.0 | 102.7 | 26.2 |
| Pair that differs in its scalar | 2.8 | 6.5 | 2.7 | 6.5 | 1.8 | 12.2 |
| `grade` of mixed multivector | 5.7 | 7.0 | 5.7 | 8.9 | 5.7 | 20.2 |
| `grade` of point | 13.2 | 16.8 | 13.2 | 31.9 | 33.0 | 48.9 |
| `m =~ 0` near zero | 14.9 | 13.6 | 16.2 | 14.3 | 39.3 | 38.0 |

An equal dense pair takes about a quarter of the time of pin in each build. Pin tests
max(1, |x|, |y|) for each coefficient with a branch. On coefficients of deviation 1 that branch
goes either way, so it is probably often mispredicted. P07 takes one bound for each part, so its
loop over a part holds no such branch. On points the branch of pin goes one way. Pin reads 15 of
16 coefficients of a point beside the same point with a stray, in 18.2 ns at 64 bits and 14.5 ns
at 32 bits. P07 calls that pair equal, so it reads every coefficient, in 13.9 ns and 13.1 ns.

Four more builds by hand on the same day each changed one thing. Each of their cells is the median
of 7 or of 15 runs, and each ratio is against the P07 cell above.

- **Part scale alone.** This build has no scan and no overflow guard in `grade`. So the scan and
  the guard add 3 to 17 ns at cga4d, and 14 to 19 ns at cga5d.
- **`max` in the scan of `grade`.** `grade` of a mixed multivector at cga5d took 53.5 ns at 64
  bits, against 20.1 ns. The probable cause is that each step of `max` waits on the last.
- **`max` in `scale`.** An equal pair took 2.5 to 3.7 times as long, and a pair that differs 2.3
  to 3.3 times. `grade` took 1.1 to 2.0 times as long.
- **A lookup table from each basis to the number of its part.** One pass finds the scale of each
  part by branch, and one loop over the bases reads the table. An equal pair took 3.4 to 8.4
  times as long, and a pair that differs 4.8 to 14.7 times. `grade` took 1.3 to 5.2 times as
  long, and `m =~ 0` took 1.6 to 2.8 times as long. This build passes `laws.nim` at rga4d and
  cga5d.

The rule of pin is the same code in every build at one width. Yet at 64 bits its `grade` of a
round point at cga5d took 17.7 ns in the build of the part scale alone. It took 32.2 ns in the
build of P07. So one rule can differ by a factor of about 1.8 between two builds. The probable
cause is the layout of the code.
