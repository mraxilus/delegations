# P11: Unitize any element by one rule

**What it is.** One rule unitizes any element of either algebra: it divides the element by a
divisor W(𝐮), which this proposal coins. For a round object of the conformal algebra, W(𝐮) is its
round weight norm. For any other element, W(𝐮) is √|𝐮 ∘ 𝐮|, as in Lengyel's rigid unitization. A
test at run time picks the branch, and the rigid algebras keep the rule of pin.

**What it is for.** At pin, conformal unitization divides every element by its round weight norm.
A flat point, a line or a plane has no round weight, so it comes back unscaled, with no sign of
it. Here every element of both algebras comes back with unit weight.

**What it costs.** Conformal unitize ran at ×7.75 of pin at cga4d and ×11.51 at cga5d in the
evaluation of 2026-10-15, and the rigid algebras keep their cost. The test of a round object has
edges, such as a sphere of radius 1e9 units or more, a far transversion and 32 bits, which the
page states.

The rule stands as the Architect ruled on 2026-10-11, on a reanalysis against Lengyel's code,
book and wikis. This page holds that reanalysis. Most of its figures come from `laws.nim` and
`limits.nim`, which ran on this machine on 2026-10-11, at 64 bits, against the changed library.
The costs come from the evaluation of 2026-10-12. Other figures come from runs by hand, and each
section names its run.

## How it works

```
W(𝐮) = ‖𝐮‖∘ = √((𝐮 ∧ 𝐞∞) ∘ (𝐮 ∧ 𝐞∞))   where 𝐮 is a round object, in CGA
W(𝐮) = √|𝐮 ∘ 𝐮|                         for any other element, and every element in RGA
unitize(𝐮) = 𝐮 ÷ W(𝐮), and 𝐮 as it is where W(𝐮) is 0
```

- **Round object.** The element holds one grade, and its round weight is not negligible beside
  √|𝐮 ∘ 𝐮|. These are Lengyel's round point, dipole, circle and sphere.
- **Its divisor.** The round weight norm ‖𝐮‖∘ equals the weight norm of 𝐮 ∧ 𝐞∞, its carrier.
  Lengyel defines it so: `RoundWeightNorm` in `ConformalAlgebra3D.wl` is the antidot norm of 𝐱 ∧ 𝐞₅,
  and his 𝐞₅ is the 𝐞∞ of the library. The book says that the round weight "is equivalent to the
  weight of the carrier geometry for round objects" (page 197).
- **Any other element.** Its divisor is Lengyel's rigid unitization. His wiki gives it for any
  element. It says: "Unitization is the process of scaling an element of a projective geometric
  algebra so that its weight norm becomes the antiscalar". The formula is 𝐮 ÷ √(𝐮 ∘ 𝐮)
  ([Unitization][rigid]).
  His rigid package has `WeightNorm[x_]:=Sqrt[AntidotProduct[x,x]]`.
- **Rigid algebra.** There, 𝐮 ∘ 𝐮 is the weight norm squared for every element. So the rule is the
  rule at pin, and the change leaves the rigid branch as it is.

The rule divides a round object by the weight of its carrier. It divides any other element by
√|𝐮 ∘ 𝐮|, with Lengyel's rigid formula.

This change puts one test at the head of suite Chapter 4, and keeps the placeholder test there.
It also puts one test at the head of suite Internal. Change `conformal-norms` replaces that
placeholder with its two tests. So the two apply in either order, and their three tests in
Chapter 4 then stand side by side.

## Why one rule must choose

No rule that is continuous in the coefficients can match Lengyel on both round and flat objects.
Take a plane 𝐠 of flat weight 1, a sphere 𝐬 of round weight 1, and the pencil 𝐬ₜ = t𝐬 + 𝐠.

- For every t ≠ 0, 𝐬ₜ is a sphere of round weight |t|, so Section 4.3 divides it by |t|.
- At t = 0 it is the plane, which Lengyel divides by its flat weight, 1.
- A continuous divisor tends to 0 as t tends to 0, so it cannot give 1 at the plane.

`laws.nim` holds the pencil at both conformal algebras. The divisor is |t| to six places for t
from 1 down to 1e-8, and 1 at t = 0. The jump is in the geometry, so no rule escapes it.

The rigid formula cannot serve round objects either. The library's antidot splits as follows at
`cga5d`:

```
𝐮 ∘ 𝐮 = ‖𝐮‖□² − ‖𝐮‖∙² + 2 (𝐮∘ · 𝐮■)
𝐮∘ · 𝐮■ = u₄u₅ − (u₄₁u₁₅ + u₄₂u₂₅ + u₄₃u₃₅) + (u₄₂₃u₂₃₅ + u₄₃₁u₃₁₅ + u₄₁₂u₁₂₅) − u₁₂₃₄u₃₂₁₅
```

The pairing 𝐮∘ · 𝐮■ matches each round weight blade with a flat bulk blade, which has 𝐞₅ in place of
𝐞₄ in its factors. A flat has no round part, so 𝐮 ∘ 𝐮 = ‖𝐮‖□² exactly, and `laws.nim` finds an error
of 0 in both conformal algebras. A round object has round weight and flat bulk together. So 𝐮 ∘ 𝐮 is
its radius squared, times its weight squared (4.45).

Two units therefore differ. The object unit makes the round weight 1. The unit of a motion or
reflection operator makes |𝐮 ∘ 𝐮| equal to 1, so that 𝐮 ⟇ ~∘𝐮 = ±𝟙 holds. A round point of real
position has radius 0. So it has no such unit at all, and only its round weight can unitize it.

In the rigid algebra the two units are one, since 𝐮 ∘ 𝐮 is the weight norm squared for every
element. That is why one formula serves there, and not in the conformal algebra.

## How it lines up with Lengyel

Lengyel's sources are his book, his Terathon Math Library in C++, his Mathematica packages in the
repository `Geometric-Algebra` at commit 473a801, and his two wikis. The code is MIT licensed.

| Kind | Lengyel divides by | This rule |
| --- | --- | --- |
| Round point | signed weight w, so w becomes 1 | \|w\|, same up to sign |
| Dipole, circle | round weight norm | same |
| Sphere | −u, so u becomes −1 | \|u\|, same up to sign |
| Flat point | signed weight, as a rigid point | same up to sign |
| Line, plane | rigid weight, which is the conformal flat weight | same |
| Rigid point | signed weight w, so w becomes 1 | same up to sign |
| Rigid line, plane, motor, flector | √(𝐮 ∘ 𝐮) | same |
| Conformal screw motor | flat weight | same |
| Translation, rotation, transversion | nothing: unit as the wiki writes them | divisor 1 |
| Transversion with some \|τᵢ\| of 2e9 or more | nothing: unit as the wiki writes it | ½\|τ\| |
| Inversion | nothing: a sphere of round weight 1 | same |
| Dilation | nothing: scaled to keep the operand's round weight | √σ |
| Any other conformal element | no rule in any source | √\|𝐮 ∘ 𝐮\| |

Apart from sign, the rule differs from Lengyel in two places alone. It rescales his dilation,
and it divides a far transversion by ½|τ|, as the numerical concessions below show.

The round objects are Terathon's `RoundPoint3D`, `Dipole3D`, `Circle3D` and `Sphere3D`, with the
book's Table 4.12. The flats are its rigid `FlatPoint3D`, `Line3D` and `Plane3D`. The rigid
motion and reflection operators are `Motor3D` and `Flector3D`. The screw motor and the inversion,
`RoundSphere`, are in `Conformal-3D-Transforms.nb`. The other motion operators are on the
conformal wiki. The 2D types of `TSConformal2D.h` follow the same pattern, and their round point
and circle are signed.

The table reads "up to sign" because the Architect ruled on 2026-10-10 that unitization keeps the
sign of the weight. `laws.nim` holds each object kind, the motor and the flector at unit weight to
3.3e-16 in all four algebras. It holds the translation, rotation, transversion and dilation forms
at `cga5d`, since the wiki writes them in that algebra.

- **Dilation.** His wiki says "This dilation operator is scaled so that the round weight of u
  remains the same after the dilation is applied." Since 𝐃 ⟇ ~∘𝐃 = σ𝟙, this rule divides 𝐃 by
  √σ, which gives the unit form of his exponential. The sandwich holds 𝐃 twice, so a round
  object of round weight 1 then leaves with round weight 1/σ, at the same place. So unitize
  commutes with his 𝐃 on round objects, and with 𝐃 ÷ √σ on every other element. No one scale of
  𝐃 serves both, and no rule that this page tested keeps his scale.
- **What "unitized" means on his conformal wiki.** It says "A unitized dipole is equal to the meet
  of its carrier and container", and the same of a circle. That identity holds exactly when the
  round weight norm is 1, which is the object unit of this rule.

## Rigour

### What holds, and how it is checked

Each law has an algebraic argument, and `laws.nim` holds it on 2,000 samples at each algebra.

| Law | Worst error, CGA | Worst error, RGA |
| --- | --- | --- |
| Each kind ends at unit weight | 3.3e-16 | 3.3e-16 |
| Product of two or four reflections ends at 𝐯 ⟇ ~∘𝐯 = ±𝟙 | 7.3e-12 | 5.6e-16 |
| unitize(λ𝐮) = sign(λ) unitize(𝐮), for λ from 1e-100 to 1e100 | 7.7e-12 | 5.5e-16 |
| unitize(𝐌 ⟇ 𝐮 ⟇ ~∘𝐌) = 𝐌 ⟇ unitize(𝐮) ⟇ ~∘𝐌, for unit rigid motor 𝐌 | 3.6e-12 | 1.3e-15 |
| Flat has 𝐮 ∘ 𝐮 = ‖𝐮‖□² | 0 | not applicable |
| Unit motion operator keeps 𝐮 ∘ 𝐮 | 3.0e-15 | not applicable |
| unitize(★𝐮) and unitize(☆𝐮) divide by W(𝐮) | 1.8e-13 | does not hold |

- **Unit weight and unit motion operator.** The rule divides by that weight, and 𝐯 ∘ 𝐯 is the 𝟙
  part of 𝐯 ⟇ ~∘𝐯.
- **Homogeneity.** Both divisors scale by |λ|, and both tests read ratios, so no branch changes.
  In floating point, scaling can move only a coefficient within rounding of the comparison
  tolerance across it.
- **Rigid motion.** A rigid motor maps 𝐞∞ to ±𝐞∞, so it keeps the weight of the carrier. The 𝟙 part
  of a product is cyclic, so a unit motion operator keeps 𝐮 ∘ 𝐮 as it is. This holds where the
  motion moves no coefficient across the grade tolerance, so that the branch stays. The last section
  names the case where a motion moves one.
- **Duality.** In CGA, each dual maps every basis element to one basis element, up to sign. So
  the grade test reads the same. Each dual also keeps the round weight norm, and negates 𝐮 ∘ 𝐮,
  so both divisors stay. In RGA a dual swaps bulk and weight, so the law does not hold there.

### What is not true, and is not true of Lengyel's rule either

- **It is not a norm.** The conformal antidot is indefinite: 𝐞₁ + 𝐞₄₅ gives 𝐮 ∘ 𝐮 = 0. The book
  says "we are using the term 'norm' loosely here" (page 197).
- **It is not continuous at flats.** The pencil above forces the jump on any rule that matches
  Lengyel. His `Sphere3D::Unitize` divides by −u, which is 0 for a plane.
- **It does not commute with transversion or inversion.** These change the round weight. Hestenes
  calls weight normalization "not Lorentz invariant" ([Old Wine in New Bottles][hestenes],
  section 7). Mann calls it "the non-conformal step" ([AGACSE 2012][mann], page 2). With a
  dilation, it commutes at one scale of 𝐃 for round objects, and at another for flats.

### What is a convention

- A round object takes the object unit, not the unit of a motion or reflection operator. Lengyel's
  own inversion, `RoundSphere`, is a sphere of round weight 1, and its 𝐬 ∘ 𝐬 is r squared. So that
  unit is not his convention, and this rule agrees with him on a lone sphere. The conformal wiki has
  no Inversion page. No test that reads the element alone can tell a sphere used as an object from
  the same sphere used as an inversion.
- Where 𝐮 ∘ 𝐮 is negative, the rule takes its absolute value. A product of reflections in a real
  sphere and an imaginary sphere is a motion operator with 𝐮 ∘ 𝐮 < 0. Its root is NaN, which spreads
  to every coefficient. A rule that leaves such a motion operator as it is leaves it at any scale it
  has, so no product of them is unit. `laws.nim` draws such products, and unitizes each to
  |𝐮 ∘ 𝐮| = 1.
- The absolute value is the standard normalization of a motion or reflection operator. De Keninck
  and Roelfs write "one can get away with calculating |X X~|^(−1/2)" ([arXiv 2206.07496][keninck],
  page 11). Hitzer gives the same ([arXiv 1306.1660][hitzer], equation 29). It drops a sign that
  the book keeps on purpose. The radius norm "produces real values for real objects and imaginary
  values for imaginary objects" (page 198). A divisor must be real, so the rule keeps the size
  alone, and the radius norm keeps its sign.
- Where the divisor is 0, the element stays as it is, as at pin.
- The scale of a motion operator is a choice for each family. Lengyel's dilation shows it.

### What is a numerical concession

Each test reads zero at a scale, as Article IV.5 asks. It says: "Compare against zero at the scale
of what you test, and exactly only where no scale is in hand." Each scale has a cost.

- **Grade test.** A coefficient at or under the comparison tolerance times the largest coefficient
  counts as zero. The tolerance is 1e-9 at 64 bits.
  Rounding leaves residue in other grades. Each round object below moved by three products of
  reflections, and each cell counts the objects that a test read right, of 256.

| Test | `cga5d` at 1 | `cga5d` at 1e8 | `cga4d` at 1 | `cga4d` at 1e8 |
| --- | --- | --- | --- | --- |
| Exact grade scan | 0 | 0 | 2 | 2 |
| Grade at pin, 1e-9 absolute | 256 | 0 | 256 | 2 |
| Antiscalar part is zero | 131 | 141 | 172 | 181 |
| Each part at its own scale alone | 256 | 122 | 256 | 86 |
| P11, 1e-9 of largest coefficient | 256 | 256 | 256 | 256 |

- **Exact grade scan.** It counts any residue as a second grade, so it reads almost no moved
  object as round.
- **Grade at pin.** Residue grows with the coefficients. At a deviation of 1e8 units a round point
  holds about 1e16 on 𝐞∞, so its residue passes an absolute 1e-9.
- **Antiscalar part is zero.** It reads an object as round only where its 𝟙 coefficient is
  exactly 0. Rounding leaves residue there in about a third to a half of the moved objects.
- **Part scale alone.** It floors the scale of each part at 1. A sphere has no round bulk, and a
  round point has no flat weight. So their residue falls in an empty part, whose scale stays at 1,
  and the part scale alone misreads them far from the origin. A circle uses all four parts. P07
  also counts a coefficient as zero within 16 rounding units of the largest coefficient, and so
  reads these objects right.
- **Round weight test.** The round weight counts as zero at or under 1e-9 times √|𝐮 ∘ 𝐮| of the
  element. A plane sent through a sphere and back keeps residue in its round weight. An exact test
  then takes it for a huge sphere: 9,933 of 10,000 planes at `cga5d`, and 9,557 at `cga4d`. This
  rule misreads none at either. Terathon's `Sphere3D::Unitize` divides by −u, so it would probably
  read such residue as a huge sphere too, at a probability of 0.75 to 0.8.
- **Its radius.** A round object of radius r and round weight w has √|𝐮 ∘ 𝐮| = rw. So the test
  passes it as round while r is under 1e9 units, and unitizes a larger sphere as a plane. A huge
  sphere and a plane differ only by that size, so every scale has such a radius.
- **Near the identity.** At `cga5d`, a transversion with ½τ of 1e-9 or 1e-13 keeps divisor 1. Its
  round weight is then negligible beside √|𝐮 ∘ 𝐮| too.
- **Far from the identity.** At `cga5d`, a transversion with τ = (2.1e9, −1.05e9, 0), so that
  |τ| = 2.35e9, has its 𝟙 term under the grade tolerance. It divides by |τ| ÷ 2 = 1.17e9 in place
  of 1. Terathon has no transversion, so no comparison with it tests this.
- **Range.** Results hold while the squared coefficients stay inside the range of 64-bit floats,
  as at pin.

### Outside the claims

This change applies at pin, at 64 bits alone, and its claims run at 64 bits. So no claim checks
the statements below. Under P06, `float-width`, the local `largest` of the grade scan in `^∘`
would be declared `Coefficient`.

- **At 32 bits.** P06 sets the comparison tolerance to 1e-4 at 32 bits. A projection from that
  tolerance moves both edges in with it. The radius edge falls to about 1e4 units, and the
  transversion edge to about 2e4.
- **What a run at 32 bits shows.** A run by hand at `cga5d` on 2026-10-12 used a copy of the
  library with P06. It unitized round objects with coordinates of deviation 1e4 units, and then
  moved them. The round test failed on 563 of 1,024 dipoles, 923 circles and 1,006 spheres, and
  on every dipole from 1e5. The same run in 64-bit arithmetic, with each input rounded to 32 bits
  and the tolerance of 1e-4, gave the same counts. So the edge comes from the tolerance, not from
  rounding.
- **Far round points at 32 bits.** In the same run, round points failed on 753 of 1,024 at 1e8.
  A 32-bit point that far out is a sphere of radius about √ε times its distance. At 64 bits no
  round point failed.

## Why Lengyel wrote no conformal rule

Lengyel does define a general rule, in the rigid algebra, as quoted above. In the conformal
algebra, his packages give the same formula the name `RadiusNorm`. The book says that the radius
norm "needs to be divided by the round weight norm" (page 198). None of his seven packages holds
the word "unitiz". His conformal wiki has no Unitization page. His tables check unitization for
the four round objects alone.

The most likely reason is the jump above: no single continuous rule serves round and flat
objects. This reason is an inference, at a probability of about 0.7, since he does not state it.
His typed classes fix the branch when the code compiles, so a runtime test never arises. Typing
alone does not explain it, since his `Motor3D` and `Flector3D` and his rigid wiki apply one weight
norm across grades.

The sources checked are Terathon, the packages and notebooks at commit 473a801, book Section
4.3, and the pages of both wikis read here. The probability that one of them holds a general
conformal rule that this search missed is about 0.03. The rigid wiki cites book Section 2.10.2,
which this search did not see. The probability that it states the same general rule is about
0.85.

## Whether it is pure

| Part of the rule | Origin |
| --- | --- |
| Weight of the carrier, for a round object | Lengyel: book page 197; `RoundWeightNorm` |
| √(𝐮 ∘ 𝐮), for any other element | Lengyel's rigid unitization, for any element |
| √(𝐮 ∘ 𝐮) is flat weight, for a flat object | Lengyel: book page 197, as rigid weight |
| \|𝐮 ∘ 𝐮\| where it is negative | literature's normalization of motion and reflection operators |
| The test between the branches, and its two scales | new, see below |

This search found no equivalent of the test in Lengyel, or in the literature that it checked. The
probability that none is published is about 0.75. That figure is an estimate, from Lengyel's
sources, the papers cited here, and the Python `clifford` library.

It is not outside a coherent projective geometric algebra. In exact arithmetic the test is
algebraic: one grade, and a carrier of nonzero weight. Lengyel chooses the branch by type when his
code compiles. A library with one multivector type chooses it when it runs. Lengyel's rigid rule
is no purer by one measure: it does not project an element onto the motion or reflection
operators either. De Keninck and Roelfs add a correction term to do so.

The rule has three defects, and none of them comes from Lengyel:

- The jump at flats. Any rule that matches Lengyel has it.
- The grade test depends on motion, as What it leaves out shows.
- The scales of the two tests put an edge at a radius of 1e9 units, and at a transversion of 2e9.

One impurity is smaller. In Lengyel's packages, `RoundWeightNorm` returns a multiple of 𝐞₁₂₃₄,
and `RadiusNorm` a multiple of 𝟙 alone. So the two branches divide by quantities of two kinds, which
reduce to the same real number. This reading holds at a probability of about 0.8.

Other ways to choose, and why this rule does not take them:

- **Carrier is not zero, 𝐮 ∧ 𝐞∞ ≠ 0.** It reads the book's own split of components into a round
  part and a flat part (page 197). It agrees on every object. But it gives divisor 0 to a scalar, to
  a Euclidean vector and to every dual of a flat. So an element and its dual can take different
  divisors. This rule's test is the more natural choice, at a probability of about 0.8.
- **√|𝐮 ∘ 𝐮| everywhere.** It is continuous, and every unit motion operator keeps it. But it
  divides a round object by its weighted radius, and a round point by 0. P10,
  `homogeneous-scalar`, takes the complex root of 𝐮 ∘ 𝐮 under the conformal metric. So its
  prototype gives a round point the divisor 0 too. Its `unitize` holds under the rigid metric
  alone, and in the conformal algebras the library keeps `^∘` of this rule.
- **Flat weight for any element other than a round object.** It agrees on every object. But it
  rescales a product of unit transversions and translations, which is already unit.
- **Round weight, or flat weight where the round weight is 0.** It fails on the transversion,
  which has round weight, and on every element moved near to flat.

Under inversion or transversion, neither the carrier test nor this rule's test keeps its reading.
Under motors and dilations, both keep it. No choice that this search examined is more algebraic.

## What users do

One rule holds in all four algebras. A user need not know which algebra or which kind is in hand.

1. Compose motion and reflection operators freely, while the largest coefficient of each product
   stays under about 1e77.
2. Apply each composed motion or reflection operator once to each object.
3. Once each frame, after the last operation, unitize everything that is read or kept.
4. Keep each motion or reflection operator from frame to frame as its source values, and compose
   it again each frame.

`limits.nim` holds the rule. Each move of the chains and of the hour is a product of two reflections
0.01 apart, as animation steps are. In the depth rows, each product is of two random reflections,
which grows far faster. Frames run at 60 each second. In the rigid algebras the error is the change
of distance between moved points. In the conformal algebras it is the drift of a moved round point
from radius zero.

| Measure | `rga4d` | `rga3d` | `cga5d` | `cga4d` |
| --- | --- | --- | --- | --- |
| One frame, depth 256, against step by step | 1.5e-14 | 3.6e-14 | 1.3e-14 | 2.2e-14 |
| Largest coefficient of that composed motion operator | 1.4e1 | 7.6 | 8.0e54 | 6.0e66 |
| Motion operator kept an hour, unitized each frame: error | 3.3e-16 | 1.0e-15 | 5.2e-16 | 1.7e-16 |
| Largest coefficient of that kept motion operator | 5.1 | 1.2e1 | 1.5e9 | 3.0e9 |
| Its \|𝐯 ∘ 𝐯\| before each unitize, worst distance from 1 | 1.1e-15 | 1.1e-15 | 1.4e3 | 2.3e3 |
| Same moves, never unitized: largest coefficient | 5.1 | 1.2e1 | 1.7e81 | 1.8e82 |
| Half hour: points, unitized against never, differ by | 3.0e-13 | 1.8e-12 | 2.8e-15 | 5.6e-15 |

- **Every kept motion operator is unit.** Each move is unit, and a product of unit motion
  operators is a unit motion operator. So in exact arithmetic a unitization of the kept motion
  operator divides it by 1, in all four algebras.
- **Rigid algebras.** A unit motor holds coefficients near the size of its translation. So the kept
  motor stays small, and a unitization each frame is harmless and not needed.
- **Conformal algebras.** The antidot is indefinite, so a unit motion operator can still hold large
  coefficients. Never unitized, the kept motion operator reached 1.7e81 at `cga5d` and 1.8e82 at
  `cga4d` within the hour, about 1.4 orders of magnitude each minute. That is its true size, not a
  drift of its weight. Overflow then lost the points it moves.
- **What a unitization each frame does there.** The terms of 𝐯 ∘ 𝐯 grow as the square of the
  coefficients, and they cancel to ±1. Once the coefficients pass about 1e7 to 1e8, their
  rounding is larger than 1, and |𝐯 ∘ 𝐯| read up to 2.3e3 before a unitize. So the rule divides
  by rounding, which holds the motion operator near 1e9 and keeps it in range. The action of a
  motion operator ignores its scale, so the points it moves stay the same, to 5.6e-15 at the half
  hour. The motion operator is then not unit, and it stays in range through rounding alone.
- **Why step 4.** A program that keeps each motion or reflection operator as its source values,
  such as positions, angles and factors, composes it again each frame. Then each frame's motion
  or reflection operator has the size of the current pose alone, and no rule needs rounding to
  keep it in range. At 32 bits it also stops the drift below. Near 1e9 a kept motion operator can
  also meet the far edge of the grade test.
- **How deep to compose.** A sandwich multiplies the coefficients of an object by about the square
  of those of the motion operator, and unitize squares them again. So the moved object overflows
  once the motion operator passes about 1e77, the fourth root of the largest 64-bit float. The
  motion operator kept one hour without a unitization lost its points by 1.7e81. In the depth
  rows, each product adds about 0.21 orders of magnitude at `cga5d` and 0.26 at `cga4d`. At that
  rate a composed conformal motion operator passes 1e77 near depth 360 at `cga5d` and about
  300 at `cga4d`, which nothing here measures.
- **Deeper hierarchies.** A hierarchy deeper than about 250 random products scales its composed
  motion operator down once on the way, for example by its largest coefficient. A unitization does
  that only through rounding, as above. A rigid motion operator stayed under 15 at depth 256, so in
  practice only a conformal hierarchy needs that step.
- **Grade selection is not needed.** Over 1,000,000 moves, residue in other grades reached at most
  2.1e-15 for rigid moves, and 5.8e-12 for conformal moves with a unitization after each. The
  comparison tolerance of the grade test is 1e-9. The rule does not remove residue, since it
  scales every coefficient alike. A grade selection after each move sets that residue to 0, and
  it changes no invariant that `limits.nim` measures.
- **Composing costs little accuracy.** A composed motion operator touches the object once. After
  1,000,000 moves, residue on that path reached at most 9.4e-15 in all four algebras. Step by step,
  rigid moves reached at most 2.1e-15.
- **At 32 bits.** A rigid motor stored at 32 bits each frame drifts from its 64-bit twin by up to
  1.2e-4 of the scene in six hours. That holds with a unitization each frame or without. The rule
  cannot stop rounding of stored state. So persistent state belongs at 64 bits, or the program
  rebuilds it from its source values, as step 4 does. `limits.nim` rounds the motor to 32 bits
  inside a 64-bit build, as 32-bit storage would, so this figure needs no P06.

## What it costs

The evaluation times unitize on the general pool, with this change and at pin. It takes five
alternating runs on linux amd64 with 4 cores, on 2026-10-15. It also counts the C of `^∘`. Each
ratio is the median of the ratios of the five runs. Earlier evaluations of the same rule, with
`^∘` inline, gave 66.59 to 91.17 ns at `cga5d` in six runs on 2026-10-11 and 2026-10-12, from
commit a712559b to commit 09e9579a. So the time of the change varies by up to about 40% between
evaluations.

| Algebra | Unitize at pin | With this change | Ratio |
| --- | --- | --- | --- |
| `rga3d` | 3.35 ns | 3.38 ns | ×1.01 |
| `rga4d` | 6.00 ns | 4.95 ns | ×1.11 |
| `cga4d` | 3.90 ns | 30.24 ns | ×7.75 |
| `cga5d` | 7.43 ns | 89.87 ns | ×11.51 |

| Count in `^∘` at `cga5d` | At pin | With this change |
| --- | --- | --- |
| Multiplies | 40 | 105 |
| Adds | 7 | 38 |
| Calls | 1 | 163 |
| Error checks | 1 | 66 |
| Lines of C | 91 | 1,485 |

The rigid algebras keep their cost, since their branch is the rule at pin. In the conformal algebras
the rule adds the antidot and a grade scan. The scan runs only where the round weight passes, and
stops at a second grade. Most of the rest is calls and error checks, which the library's operators
carry everywhere, and which the gap list holds as design gaps.

This change drops `inline` from `^∘`, since its C at `cga5d` grows from 91 to 1,485 lines. The
guide of the language inlines a large body only where a measurement shows the gain (`STYLE.md`,
section 2). So each call to `unitize` or `normalizeWeight` calls `^∘`, in the rigid algebras too.
The table above times that form. Its 89.87 ns at `cga5d` lies inside the spread of the earlier
evaluations of the inline form, so no measurement here shows a gain of `inline`.

## What it leaves out

- **The suites at `cga3d`.** No claim names `cga3d`, and there the test of suite Internal fails.
  At `cga3d` a sphere is a pair of points on a line, and two random points can lie close together.
  A plane sent through such a sphere and back then holds only about four places. In the sample
  that fails, its flat weight after unitize is 0.999924. A run by hand on 2026-10-15 found the
  failure with this change alone, and with P06 and P07 too. A test that draws a sphere of a set
  radius, or skips a small one against a floor, is an open decision.
- **The grade of the library.** This change leaves `grade` and `isMixed` as they are, and `⊛`
  reads `grade`. P07, `part-scale`, takes their zero test, as the Architect ruled on 2026-10-12.
  In the rigid algebras that test weighs each part at its own scale. In the conformal algebras it
  also counts a coefficient as zero within 16 rounding units of the largest coefficient. This
  rule keeps its own grade scan at the comparison tolerance times the largest coefficient, since
  it does not build on P07.
- **One zero test.** Once P07 lands, `grade` and `^∘` can read one element differently. On the
  populations of P07 at 64 bits, the scan of `^∘` misread 157 elements at `cga4d` and 132 at
  `cga5d`, read alone. The `grade` of P07 misread none there. P07 also measured a test split by
  the round test of this rule, which misread 71 and 140. Whether `^∘` then reads `grade` is an
  open decision.
- **Bulk normalization.** `^∙` stays as it is. A sphere has no round bulk, so a fallback to the
  flat bulk would divide every sphere by its flat bulk. Nothing in Lengyel defines it.
- **Zero weight.** The element stays as it is. Lengyel's rigid wiki divides a point of zero weight
  by its bulk norm, as a direction ([Point][point]).
- **A grade test that no motion changes.** The grade test reads the largest coefficient, and a
  motion changes it. So a motion can move the branch of an element whose residue lies near the
  tolerance. A round point at the origin with residue 2e-9 on 𝟙 divides by 2e-9. After a
  translation by 10 it divides by 1, a factor of 5e8. Rotations about the origin alone moved the
  branch of 15,198 of 20,000 round points with residue just past the tolerance.
- **Whether a better test exists.** It is open. The probability that a grade test exists that no
  motor changes, and that keeps the results of this rule, is about 0.6. That figure is an
  estimate, and nothing here measures it.

## Implementation

`change.md` holds every edit, and applies at pin at 64 bits.

- **Files.** `pga/operators.nim`: the body and doc of `^∘`, and the docs of `|∘` and `^`.
  `pga.nim`: the row of `^∘` in the operator table, and the docs of `normalizeWeight` and
  `unitize`. `tests/suites.nim`: one test at the head of suite Internal, one at the head of suite
  Chapter 4, and the helpers `samplePoint` and `sampleReflector` under `when IS_CONFORMAL`.
- **Types and signatures.** No type changes. `^∘` keeps its parameter and its result, and drops
  `inline`, so it reads `` func `^∘`*(m: Multivector): Multivector {.noinit.} ``. The template
  `^`, `normalizeWeight` and `unitize` stay as at pin.
- **Functions.** Added and removed: none in the library. Changed: the body of `^∘` gains a branch
  under `when IS_CONFORMAL`, and the rigid branch keeps the body of pin. The round branch divides by
  the root of `|∘²` of pin, the sum of squares of the round weight. That sum is the weight norm
  squared of the carrier 𝐮 ∧ 𝐞∞, as What it is states. The docs state W(𝐮).
- **Callers.** No caller changes its text, and in the library `^` and `^∘` reach callers through
  `unitize` and `normalizeWeight` alone. In RGA every result stays as at pin. In CGA a flat object
  divides by √|𝐮 ∘ 𝐮|, its flat weight, where pin leaves it as it is. A motion operator, a
  reflection operator or a mixed element divides by √|𝐮 ∘ 𝐮| too, unless it reads as round. The
  tests of pin call `^` only under `when IS_RIGID`, so each keeps its result.
- **Order of edits.** P06 (`float-width`) quotes no line here. Two locals start at the float
  `0.0`, `largest` in `^∘` and `distance_squared` in `samplePoint`, and each compiles at 32 bits.
  Once both land, the second to land declares them `Coefficient`. The change `algebra-hygiene`
  renames `TOLERANCE_ABS`, which `^∘` names, so the second to land carries the new name into `^∘`.
  The change `doc-comments` writes that `^` and `normalizeWeight` cost no call. With this change
  `^∘` is not inline, so once both land, that doc says that each costs one call. The changes
  `doc-comments` and `doc-comments-2` edit docs next to `unitize` and `^` through distinct quotes,
  so either order holds. So does the change `conformal-norms`, which replaces the placeholder of
  Chapter 4 that this change keeps. P10 (`homogeneous-scalar`) keeps `unitize` as `^m`, which
  then calls `^∘` of this change.

P07 (`part-scale`) edits `=~` and `grade` in `pga/multivectors.nim` alone, so no line collides.
But P07 removes the private `=~` of two scalars, and the test that this change adds to suite
Internal compares the antiscalar of 𝐯 ∘ 𝐯 with 1. So that test compares two multivectors through
the public `=~`, as `abs((𝐯 ∘ 𝐯)[Basis.scalarAnti]) ∧ 𝟙 =~ 𝟙`, and the two build together in
either order. A run by hand on 2026-10-15 applied this change alone to a copy of the library at
pin, and the suites passed at `cga4d` and `cga5d`. A second run applied P06, P07 and this change.
The suites passed at `rga4d`, `cga4d` and `cga5d` at 64 bits, and at `cga4d` and `cga5d` at 32
bits.

## Open decisions

- One zero test for `grade` and for `^∘` once P07 lands, or two tests as now. P07 holds the same
  decision.
- How the test of suite Internal draws its sphere, so that it holds at `cga3d` too.

[rigid]: https://rigidgeometricalgebra.org/wiki/index.php?title=Unitization
[point]: https://rigidgeometricalgebra.org/wiki/index.php?title=Point
[hestenes]: https://davidhestenes.net/geocalc/pdf/OldWine.pdf
[mann]: https://cs.uwaterloo.ca/~smann/Papers/AGACSE12b.pdf
[keninck]: https://arxiv.org/pdf/2206.07496
[hitzer]: https://arxiv.org/pdf/1306.1660
