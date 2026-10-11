# P11: Unitize any element by one rule

At pin, unitization divides every element by its round weight norm. In the conformal algebra a
flat object has no round weight, so a flat point, a line or a plane stays as it is, with no
signal. This proposal gives one rule for any element of either algebra. An element divides by
√|𝐮 ∘ 𝐮|, as Lengyel's rigid unitization does. In the conformal algebra, a round object divides
instead by its round weight norm, which is the weight of its carrier.

The Architect chose this rule on 2026-10-11, after a reanalysis against Lengyel's code, book
and wikis. This page holds that reanalysis. Its figures come from `laws.nim` and `limits.nim`,
run in this container on 2026-10-11, at 64 bits, against the changed library.

## What it is

```
W(𝐮) = ‖𝐮‖○ = √((𝐮 ∧ 𝐞∞) ∘ (𝐮 ∧ 𝐞∞))   where 𝐮 is a round object, in CGA
W(𝐮) = √|𝐮 ∘ 𝐮|                         for any other element, and every element in RGA
unitize(𝐮) = 𝐮 ÷ W(𝐮), and 𝐮 as it is where W(𝐮) is 0
```

- **Round object.** The element holds one grade, and its round weight is not negligible beside
  √|𝐮 ∘ 𝐮|. These are Lengyel's round point, dipole, circle and sphere.
- **Its divisor.** The round weight norm ‖𝐮‖○ equals the weight norm of the carrier 𝐮 ∧ 𝐞∞.
  Lengyel defines it so: `RoundWeightNorm` in `ConformalAlgebra3D.wl` is the antidot norm of
  𝐱 ∧ 𝐞₅. The book says that the round weight "is equivalent to the weight of the carrier
  geometry for round objects" (p. 197).
- **Any other element.** The divisor is Lengyel's rigid unitization, which his wiki gives for any
  element: "Unitization is the process of scaling an element of a projective geometric algebra
  so that its weight norm becomes the antiscalar", with 𝐮 ÷ √(𝐮 ∘ 𝐮) ([Unitization][rigid]).
  His rigid package has `WeightNorm[x_]:=Sqrt[AntidotProduct[x,x]]`.
- **Rigid algebra.** There, the weight norm squared is 𝐮 ∘ 𝐮 for every element, so the rule is
  the rule at pin, and the change leaves the rigid branch as it is.

In words: a round object is unitized by the weight of its carrier, and any other element by its
own weight, with Lengyel's rigid formula.

## Why one rule must choose

No rule that is continuous in the coefficients can match Lengyel on both round and flat objects.
Take a plane 𝐠 of flat weight 1, a sphere 𝐬 of round weight 1, and the pencil 𝐬ₜ = t𝐬 + 𝐠.

- For every t ≠ 0, 𝐬ₜ is a sphere of round weight |t|, so Section 4.3 divides it by |t|.
- At t = 0 it is the plane, which Lengyel divides by its flat weight, 1.
- A continuous divisor would tend to 0 as t tends to 0, so it cannot give 1 at the plane.

`laws.nim` holds the pencil at both algebras: the divisor is |t| to six places for t from 1 down
to 1e-8, and 1 at t = 0. The jump is in the geometry, so no rule escapes it.

The rigid formula cannot serve round objects either. The library's antidot splits as

```
𝐮 ∘ 𝐮 = ‖𝐮‖□² − ‖𝐮‖∙² + 2 (𝐮○ · 𝐮■)
𝐮○ · 𝐮■ = u₄u₅ − (u₄₁u₁₅ + u₄₂u₂₅ + u₄₃u₃₅) + (u₄₂₃u₂₃₅ + u₄₃₁u₃₁₅ + u₄₁₂u₁₂₅) − u₁₂₃₄u₃₂₁₅
```

at `cga5d`, where the pairing matches each round weight blade with the flat bulk blade that has
𝐞₅ in place of 𝐞₄. A flat has no round part, so 𝐮 ∘ 𝐮 = ‖𝐮‖□² exactly: `laws.nim` finds an error
of 0 in both conformal algebras. A round object has round weight and flat bulk together, so
𝐮 ∘ 𝐮 is its weighted radius squared (4.45). A round point of real position has radius 0, so it
has no versor unit at all, and only its round weight can unitize it.

In the rigid algebra the object unit and the operator unit are one: the weight norm squared is
𝐮 ∘ 𝐮 for every element. That is why one formula serves there, and not in the conformal algebra.

## How it lines up with Lengyel

Lengyel's sources are his book, his Terathon Math Library in C++, his Mathematica packages in
the repository `Geometric-Algebra` at commit 473a801, and his two wikis. Each is MIT licensed
or public.

| Kind | Lengyel divides by | This rule |
| --- | --- | --- |
| Round point | signed weight w, so w becomes 1 | \|w\|, same up to sign |
| Dipole, circle | round weight norm | same |
| Sphere | −u, so u becomes −1 | \|u\|, same up to sign |
| Flat point | signed weight, as a rigid point | same up to sign |
| Line, plane | rigid weight, which is the conformal flat weight | same |
| Rigid point, line, plane, motor, flector | √(𝐮 ∘ 𝐮) | same |
| Conformal screw motor | flat weight | same |
| Translation, rotation, transversion | nothing: unit as the wiki writes them | divisor 1 |
| Inversion | nothing: a sphere of round weight 1 | same |
| Dilation | nothing: scaled to keep the operand's round weight | √σ |
| Any other conformal element | no rule in any source | √\|𝐮 ∘ 𝐮\| |

The round objects are Terathon's `RoundPoint3D`, `Dipole3D`, `Circle3D` and `Sphere3D`, with the
book's Table 4.12. The flats are its rigid `FlatPoint3D`, `Line3D` and `Plane3D`, and the rigid
operators are `Motor3D` and `Flector3D`. The screw motor and the inversion, `RoundSphere`, are in
`Conformal-3D-Transforms.nb`, and the other operators are on the conformal wiki.

"Up to sign" holds because the Architect ruled on 2026-10-10 that unitization keeps the sign of
the weight. `laws.nim` holds each kind at unit weight to 3.3e-16 in all four algebras.

- **Dilation.** His wiki says "This dilation operator is scaled so that the round weight of u
  remains the same after the dilation is applied." Since 𝐃 ⟇ ~𝐃 = σ𝟙, this rule divides 𝐃 by
  √σ, which gives the unit form of his exponential. No rule that this page tested keeps his
  scale, because his choice is a choice for one operator family.
- **What "unitized" means on his conformal wiki.** It says "A unitized dipole is equal to the meet
  of its carrier and container", and the same of a circle. That identity holds exactly when the
  round weight norm is 1, which is this rule's unit for round objects.

## Rigour

### What is proved

Each law has an algebraic argument, and `laws.nim` holds it on 2,000 samples at each algebra.

| Law | Worst error, CGA | Worst error, RGA |
| --- | --- | --- |
| Each kind ends at unit weight | 3.3e-16 | 3.3e-16 |
| Product of two or four reflections ends at 𝐯 ⟇ ~𝐯 = ±𝟙 | 7.3e-12 | 5.6e-16 |
| unitize(λ𝐮) = sign(λ) unitize(𝐮), for λ from 1e-100 to 1e100 | 7.7e-12 | 5.5e-16 |
| unitize(𝐌 ⟇ 𝐮 ⟇ ~𝐌) = 𝐌 ⟇ unitize(𝐮) ⟇ ~𝐌, for unit rigid motor 𝐌 | 3.6e-12 | 1.3e-15 |
| Flat has 𝐮 ∘ 𝐮 = ‖𝐮‖□² | 0 | not applicable |
| Unit versor keeps 𝐮 ∘ 𝐮 | 3.0e-15 | not applicable |

- **Unit weight and unit versor.** The rule divides by that weight, and 𝐯 ∘ 𝐯 is the 𝟙 part of
  𝐯 ⟇ ~𝐯.
- **Homogeneity.** Both divisors scale by |λ|, and both tests read ratios, so no branch changes.
- **Rigid motion.** A rigid motor maps 𝐞∞ to ±𝐞∞, so it keeps the weight of the carrier. The 𝟙
  part of a product is cyclic, so a unit versor keeps 𝐮 ∘ 𝐮.

### What is not true, and is not true of Lengyel's rule either

- **It is not a norm.** The conformal antidot is indefinite: 𝐞₁ + 𝐞₄₅ gives 𝐮 ∘ 𝐮 = 0. The book
  says "we are using the term 'norm' loosely here" (p. 197).
- **It is not continuous at flats.** The pencil above forces the jump on any rule that matches
  Lengyel. His `Sphere3D::Unitize` divides by u, which is 0 for a plane.
- **It does not commute with transversion or inversion.** These change the round weight. Hestenes
  calls weight normalization "not Lorentz invariant" ([Old Wine in New Bottles][hestenes],
  section 7). Mann calls it "the non-conformal step" ([AGACSE 2012][mann], p. 2).

### What is a convention

- A round object takes the object unit, round weight 1, and not the versor unit. Lengyel's own
  inversion uses a sphere of round weight 1, so the two agree on a lone sphere.
- Where 𝐮 ∘ 𝐮 is negative, the rule takes its absolute value. That is the standard normalization
  of a versor: De Keninck and Roelfs write "one can get away with calculating |X X~|^(−1/2)"
  ([arXiv 2206.07496][keninck], p. 11), and Hitzer gives the same ([arXiv 1306.1660][hitzer],
  equation 29).
- Where the divisor is 0, the element stays as it is, as at pin.
- The scale of an operator is a choice for each operator family. Lengyel's dilation shows it.

### What is a numerical concession

The two tests read zero at a scale, as Article IV.5 asks: "Compare against zero at the scale of
what you test, and exactly only where no scale is in hand." Each scale has a cost.

- **Grade test.** A coefficient at or under 1e-9 times the largest coefficient counts as zero.
  Rounding leaves residue in other grades: of round objects moved by three products of
  reflections, each test below read this many right, of 256 at each distance from the origin.

| Test | `cga5d` at 1 | `cga5d` at 1e8 | `cga4d` at 1 | `cga4d` at 1e8 |
| --- | --- | --- | --- | --- |
| Exact grade scan | 0 | 0 | 3 | 1 |
| Grade at pin, 1e-9 absolute | 256 | 0 | 256 | 1 |
| Antiscalar part is zero | 145 | 141 | 175 | 193 |
| Grade of P07, each part at its own scale | 256 | 128 | 256 | 74 |
| This rule, 1e-9 of largest coefficient | 256 | 256 | 256 | 256 |

- **P07's grade.** P07 floors the scale of each part at 1. A sphere has no round bulk, and a round
  point has no flat weight, so their residue falls in an empty part, whose scale stays at 1. That
  is why P07 misreads them far from the origin. A circle uses all four parts.
- **Round weight test.** The round weight counts as zero at or under 1e-9 times √|𝐮 ∘ 𝐮|. A plane
  sent through a sphere and back keeps residue in its round weight. An exact test then takes it
  for a huge sphere: 9,950 of 10,000 planes at `cga5d`, and 9,579 at `cga4d`. This rule misreads
  none. The cost is a jump at a radius of 1e9 units: past it, a sphere unitizes as a plane does.
  A huge sphere and a plane differ only by that size, so every scale has such a radius.
- **Near the identity.** A transversion with ½τ of 1e-9 or 1e-13 keeps divisor 1, because its
  round weight is then negligible beside √|𝐮 ∘ 𝐮| too.
- **Far from the identity.** A transversion with τ of 2.1e9 has its 𝟙 term under the grade
  tolerance, and divides by 1.17e9 in place of 1.
- **Range.** Results hold while the squared coefficients stay inside the range of 64-bit floats,
  as at pin.

## Why Lengyel wrote no conformal rule

Lengyel does define a general rule, in the rigid algebra, as quoted above. In the conformal
algebra, his packages give the same formula the name `RadiusNorm`, and the book says that the
radius norm "needs to be divided by the round weight norm" (p. 198). None of his seven packages
holds the word "unitiz". His conformal wiki has no Unitization page, and his tables check
unitization for the four round objects alone.

The most likely reason is the jump above: no single continuous rule serves round and flat
objects (probability about 0.7, inferred, since he does not state it). His typed classes then
fix the branch when the code compiles, so a runtime test never arises. The chance that he
published a general conformal rule in a source not checked is about 0.03.

## Whether it is pure

| Part of the rule | Origin |
| --- | --- |
| Weight of the carrier, for a round object | Lengyel: book p. 197; `RoundWeightNorm` |
| √(𝐮 ∘ 𝐮), for any other element | Lengyel's rigid unitization, for any element |
| \|𝐮 ∘ 𝐮\| where it is negative | standard versor normalization in the literature |
| The test between the branches, and its two scales | new, see below |

No equivalent of the test was found in Lengyel or in the literature checked. The probability that
none is published is about 0.75.

It is not outside a coherent projective geometric algebra. In exact arithmetic the test is
algebraic: one grade, and a carrier of nonzero weight. Lengyel chooses the branch by type when
his code compiles. A library with one multivector type chooses it when it runs. Lengyel's rigid
rule is no purer by one measure: it does not project an element onto the versors either, and De
Keninck and Roelfs add a correction term to do so.

Other ways to choose, and why this rule does not take them:

- **Carrier is not zero, 𝐮 ∧ 𝐞∞ ≠ 0.** It agrees on every object. But it gives divisor 0 to a
  scalar, to a Euclidean vector and to every dual of a flat.
- **√|𝐮 ∘ 𝐮| everywhere.** It is continuous, and every unit versor keeps it. But it divides a
  round object by its weighted radius, and a round point by 0.
- **Flat weight for any element other than a round object.** It agrees on every object. But it
  rescales a product of unit transversions and translations, which is already unit.
- **Round weight, or flat weight where the round weight is 0.** It fails on the transversion,
  which has round weight, and on every element moved near to flat.

## What users do

One rule holds in all four algebras, so a user need not know which algebra or which kind is in
hand: compose operators freely, apply each composed operator once to each object, and once per
frame, after the last operation, unitize everything that is read or kept.

`limits.nim` holds it. Each move is a product of two reflections 0.01 apart, as animation steps
are; frames run at 60 each second.

| Measure | `rga4d` | `rga3d` | `cga5d` | `cga4d` |
| --- | --- | --- | --- | --- |
| One frame, depth 256, against step by step | 1.5e-14 | 3.6e-14 | 1.9e-14 | 1.1e-14 |
| Largest coefficient of that composed operator | 1.4e1 | 7.6 | 2.1e62 | 1.4e68 |
| Operator kept one hour, unitized each frame: error | 4.4e-16 | 5.6e-16 | 3.4e-16 | 2.2e-16 |
| Same operator never unitized: largest coefficient | 4.3 | 9.0 | 2.8e93 | 2.6e78 |

- **Rigid algebras.** Unitize each frame is harmless and not needed: a rigid motion keeps weight.
- **Conformal algebras.** Unitize each frame is needed. Without it the kept operator grows by
  about one and a half orders of magnitude each minute. Within the hour, points that it moves
  are lost to overflow.
- **Grade selection is not needed.** Over 1,000,000 moves, residue in other grades reached at
  most 1.1e-13 for rigid moves, and 2.1e-12 for conformal moves unitized each move. The
  tolerance of the grade test is 1e-9. Unitize does not remove residue, since unitize scales
  every coefficient alike.
  Selecting the grade after each move sets it to 0, but changed no invariant measured.
- **Composing costs no accuracy.** A composed operator touches the object once. After 1,000,000
  moves, residue on that path reached at most 1.4e-13 in all four algebras.
- **At 32 bits.** A rigid motor stored at 32 bits each frame drifts from its 64-bit twin by up to
  1.7e-4 of the scene in six hours, unitized or not. Unitize cannot stop rounding of stored
  state, so persistent state belongs at 64 bits, or is rebuilt from its source values. P06 makes
  the width configurable.

## What it costs

The evaluation times unitize on the general pool with this change and at pin, in five alternating
runs on linux amd64 with 4 cores, on 2026-10-11. It also counts the C of `^∘`.

| Algebra | Unitize at pin | With this change | Ratio |
| --- | --- | --- | --- |
| `rga3d` | 3.67 ns | 3.66 ns | ×1.04 |
| `rga4d` | 5.34 ns | 5.26 ns | ×0.95 |
| `cga4d` | 4.67 ns | 21.12 ns | ×4.52 |
| `cga5d` | 8.78 ns | 66.59 ns | ×6.98 |

| Count in `^∘` at `cga5d` | At pin | With this change |
| --- | --- | --- |
| Multiplies | 40 | 105 |
| Adds | 7 | 38 |
| Calls | 1 | 163 |
| Error checks | 1 | 66 |
| Lines of C | 91 | 1,485 |

The rigid algebras keep their cost, since their branch is the rule at pin. In the conformal
algebras the rule adds the antidot, and a grade scan that runs only where the round weight
passes, and stops at a second grade. Most of the rest is calls and error checks, which the
library's operators carry everywhere, and which the gap list holds as design gaps.

## What it leaves out

- **The grade of the library.** `grade` and `isMixed` keep their absolute tolerance, and `⊛` reads
  `grade`. Whether they take this rule's relative test is a separate decision, and it touches P07.
- **Bulk normalization.** `^∙` stays as it is. A sphere has no round bulk, so a fallback to the
  flat bulk would divide every sphere by its flat bulk, and nothing in Lengyel defines it.
- **Zero weight.** The element stays as it is. Lengyel's rigid wiki divides a point of zero weight
  by its bulk norm, as a direction ([Point][point]).
- **A motor invariant grade test.** The grade test reads the largest coefficient, which a
  translation changes. So a motion can change the branch for an element with a coefficient near
  the tolerance. Whether a test exists that no motion changes is open (probability about 0.6).

[rigid]: https://rigidgeometricalgebra.org/wiki/index.php?title=Unitization
[point]: https://rigidgeometricalgebra.org/wiki/index.php?title=Point
[hestenes]: https://davidhestenes.net/geocalc/pdf/OldWine.pdf
[mann]: https://cs.uwaterloo.ca/~smann/Papers/AGACSE12b.pdf
[keninck]: https://arxiv.org/pdf/2206.07496
[hitzer]: https://arxiv.org/pdf/1306.1660
