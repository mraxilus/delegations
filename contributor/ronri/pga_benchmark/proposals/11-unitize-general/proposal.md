# P11: Unitize any element by one rule

**What it is.** One rule unitizes any element of either algebra. It divides a round object of the
conformal algebra by its round weight norm, and any other element by √|𝐮 ∘ 𝐮|.

**What it is for.** At pin, conformal unitization leaves a flat point, a line or a plane unscaled,
with no sign of it. Here every element of both algebras comes back with unit weight.

**What it costs.** Conformal unitize is much slower than at pin, and the rigid algebras keep their
cost. The test of a round object has edges at a huge sphere, a far transversion and 32 bits.

## Problem

At pin, `^∘` divides a rigid element by its weight norm, as Lengyel does, and a conformal element
by its round weight norm. A flat point, a line or a plane has no round weight, so it comes back
unscaled, with no sign of it.

### Why one rule must choose

No rule that is continuous in the coefficients can match Lengyel on both round and flat objects.
Take a plane 𝐠 of flat weight 1, a sphere 𝐬 of round weight 1, and the pencil 𝐬ₜ = t𝐬 + 𝐠.

- For every t ≠ 0, 𝐬ₜ is a sphere of round weight |t|, so Section 4.3 divides it by |t|.
- At t = 0 it is the plane, which Lengyel divides by its flat weight, 1.
- A continuous divisor tends to 0 as t tends to 0, so it cannot give 1 at the plane.

The jump is in the geometry, so no rule escapes it. The rigid formula cannot serve round objects
either. The library's antidot splits as follows at `cga5d`:

```
𝐮 ∘ 𝐮 = ‖𝐮‖□² − ‖𝐮‖∙² + 2 (𝐮∘ · 𝐮■)
𝐮∘ · 𝐮■ = u₄u₅ − (u₄₁u₁₅ + u₄₂u₂₅ + u₄₃u₃₅) + (u₄₂₃u₂₃₅ + u₄₃₁u₃₁₅ + u₄₁₂u₁₂₅) − u₁₂₃₄u₃₂₁₅
```

The pairing 𝐮∘ · 𝐮■ matches each round weight blade with a flat bulk blade, which has 𝐞₅ in
place of 𝐞₄ in its factors. A flat has no round part, so 𝐮 ∘ 𝐮 = ‖𝐮‖□² exactly. A round object
has round weight and flat bulk together, so 𝐮 ∘ 𝐮 is its radius squared, times its weight squared
(4.45).

So two units differ. The object unit makes the round weight 1. The unit of a motion or reflection
operator makes |𝐮 ∘ 𝐮| equal to 1, so that 𝐮 ⟇ ~∘𝐮 = ±𝟙 holds. A round point of real position
has radius 0, so it has no such unit, and only its round weight can unitize it. In the rigid
algebra 𝐮 ∘ 𝐮 is the weight norm squared for every element, so the two units are one, and one
formula serves.

### What Lengyel defines

His rigid wiki gives unitization for any element, as 𝐮 ÷ √(𝐮 ∘ 𝐮) ([Unitization][rigid]). It
says: "Unitization is the process of scaling an element of a projective geometric algebra so that
its weight norm becomes the antiscalar". His rigid package has
`WeightNorm[x_]:=Sqrt[AntidotProduct[x,x]]`.

His conformal packages give the same formula the name `RadiusNorm`. The book says that the radius
norm "needs to be divided by the round weight norm" (page 198). None of his seven packages holds
the word "unitiz", and his conformal wiki has no Unitization page. His tables check unitization
for the four round objects alone.

The most likely reason that he writes no conformal rule is the jump above. This is an inference,
at a probability of about 0.7, since he does not state it. His typed classes fix the branch when
the code compiles, so no test at run time arises. Typing alone does not explain it, since his
`Motor3D`, `Flector3D` and rigid wiki apply one weight norm across grades.

## Idea

This proposal coins a divisor W(𝐮), and a test at run time picks its branch:

```
W(𝐮) = ‖𝐮‖∘ = √((𝐮 ∧ 𝐞∞) ∘ (𝐮 ∧ 𝐞∞))   where 𝐮 is a round object, in CGA
W(𝐮) = √|𝐮 ∘ 𝐮|                         for any other element, and every element in RGA
unitize(𝐮) = 𝐮 ÷ W(𝐮), and 𝐮 as it is where W(𝐮) is 0
```

- **Round object.** The element holds one grade, and its round weight is not negligible beside
  √|𝐮 ∘ 𝐮|. These are Lengyel's round point, dipole, circle and sphere.
- **Its divisor.** ‖𝐮‖∘ is the weight norm of 𝐮 ∧ 𝐞∞, its carrier. Lengyel defines it so:
  `RoundWeightNorm` in `ConformalAlgebra3D.wl` is the antidot norm of 𝐱 ∧ 𝐞₅, and his 𝐞₅ is the
  𝐞∞ of the library. The book says that the round weight "is equivalent to the weight of the
  carrier geometry for round objects" (page 197). So the branch divides by the root of `|∘²` of
  pin, the sum of squares of the round weight.
- **Other elements.** The divisor is Lengyel's rigid unitization, for any element. In RGA this is
  the rule at pin, so the rigid branch stays as it is.
- **Zero.** Each test compares against zero at the scale of what it tests, as Article IV.5 asks.
  The grade test reads a coefficient as zero at or under the comparison tolerance times the
  largest coefficient. That tolerance is 1e-9 at 64 bits. The round weight test reads the round
  weight as zero at or under 1e-9 times √|𝐮 ∘ 𝐮| of the element.

### Conventions

- **Object unit.** A round object takes the object unit, not the unit of a motion or reflection
  operator. Lengyel's own inversion, `RoundSphere`, is a sphere of round weight 1, whose 𝐬 ∘ 𝐬 is
  r squared. So that unit is not his convention, and this rule agrees with him on a lone sphere.
  No test that reads the element alone can tell a sphere used as an object from one used as an
  inversion. His conformal wiki has no Inversion page.
- **Unitized on his conformal wiki.** It says "A unitized dipole is equal to the meet of its
  carrier and container", and the same of a circle. That identity holds exactly at round weight
  norm 1, the object unit of this rule.
- **Absolute value.** A product of reflections in a real sphere and an imaginary sphere has
  𝐮 ∘ 𝐮 < 0. Its root is NaN, which spreads to every coefficient. A rule that leaves it as it is
  leaves it at any scale, so no product of such operators is unit. So the rule takes |𝐮 ∘ 𝐮|.
- **Standard normalization.** That is the standard normalization of a motion or reflection
  operator. De Keninck and Roelfs write "one can get away with calculating |X X~|^(−1/2)"
  ([arXiv 2206.07496][keninck], page 11). Hitzer gives the same ([arXiv 1306.1660][hitzer],
  equation 29). The absolute value drops a sign that the book keeps on purpose. The radius norm
  "produces real values for real objects and imaginary values for imaginary objects" (page 198).
- **Sign and scale.** A divisor must be real, so the rule keeps the size alone, and the radius
  norm keeps its sign. Unitization keeps the sign of the weight, as the Architect ruled on
  2026-10-10. The scale of a motion operator is a choice for each family, as the dilation shows.

### How it lines up with Lengyel

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

Apart from sign, the rule differs from Lengyel in two places alone: his dilation, and a far
transversion, which Costs gives.

**Dilation.** His wiki says "This dilation operator is scaled so that the round weight of u remains
the same after the dilation is applied." Since 𝐃 ⟇ ~∘𝐃 = σ𝟙, this rule divides 𝐃 by √σ, the unit
form of his exponential. The sandwich holds 𝐃 twice, so a round object of round weight 1 leaves
with round weight 1/σ, at the same place. So unitize commutes with his 𝐃 on round objects, and
with 𝐃 ÷ √σ on every other element. No one scale of 𝐃 serves both, and no rule tested here keeps
his scale.

### Whether it is pure

| Part of the rule | Origin |
| --- | --- |
| Weight of the carrier, for a round object | Lengyel: book page 197; `RoundWeightNorm` |
| √(𝐮 ∘ 𝐮), for any other element | Lengyel's rigid unitization, for any element |
| √(𝐮 ∘ 𝐮) is flat weight, for a flat object | Lengyel: book page 197, as rigid weight |
| \|𝐮 ∘ 𝐮\| where it is negative | literature's normalization of motion and reflection operators |
| The test between the branches, and its two scales | new |

The rule stays inside a coherent projective geometric algebra. In exact arithmetic its test is
algebraic: one grade, and a carrier of nonzero weight. Lengyel chooses the branch by type when his
code compiles, and a library with one multivector type chooses it when it runs. His rigid rule is
no purer by one measure: it does not project an element onto the motion or reflection operators
either. De Keninck and Roelfs add a correction term to do so.

The rule has three defects, and none of them comes from Lengyel. They are the jump at flats, a
grade test that motion moves, and the edges of its scales. One impurity is smaller. In Lengyel's
packages, `RoundWeightNorm` returns a multiple of 𝐞₁₂₃₄, and `RadiusNorm` a multiple of 𝟙 alone.
So the two branches divide by quantities of two kinds, which reduce to the same real number. This
reading holds at a probability of about 0.8.

## Alternatives

### How to choose the branch

- **Carrier is not zero, 𝐮 ∧ 𝐞∞ ≠ 0.** It reads the book's own split into a round part and a flat
  part (page 197), and it agrees on every object. But it gives divisor 0 to a scalar, a Euclidean
  vector and every dual of a flat. So an element and its dual can take different divisors. This
  rule's test is the more natural choice, at a probability of about 0.8.
- **√|𝐮 ∘ 𝐮| everywhere.** It is continuous, and every unit motion operator keeps it. But it
  divides a round object by its weighted radius, and a round point by 0. P10,
  `homogeneous-scalar`, takes the complex root of 𝐮 ∘ 𝐮 under the conformal metric, so its
  prototype also gives a round point the divisor 0. Its `unitize` holds under the rigid metric
  alone, and in the conformal algebras the library keeps `^∘` of this rule.
- **Flat weight for any element other than a round object.** It agrees on every object. But it
  rescales a product of unit transversions and translations, which is already unit.
- **Round weight, or flat weight where it is 0.** It fails on the transversion, which has round
  weight, and on every element moved near to flat.

Under inversion or transversion, neither the carrier test nor this rule's test keeps its reading.
Under motors and dilations, both keep it. No choice that this search examined is more algebraic.

### How to read zero

Rounding leaves residue in other grades, and in the round weight of a moved plane. Each option
below misreads moved objects that this rule reads right, as Evidence counts.

- **Exact grade scan.** It counts any residue as a second grade, so it reads almost no moved
  object as round.
- **Grade at pin, 1e-9 absolute.** Residue grows with the coefficients. At a deviation of 1e8
  units a round point holds about 1e16 on 𝐞∞, so its residue passes an absolute 1e-9.
- **Antiscalar part is zero.** It reads an object as round only where its 𝟙 coefficient is
  exactly 0. Rounding leaves residue there in about a third to a half of the moved objects.
- **Each part at its own scale alone.** It floors the scale of each part at 1. A sphere has no
  round bulk, and a round point has no flat weight. So their residue falls in an empty part of
  scale 1, and this test misreads them far from the origin. A circle uses all four parts. The
  test of P07, which Costs describes, reads these objects right.
- **Exact round weight test.** It takes a plane sent through a sphere and back for a huge sphere.
  Terathon's `Sphere3D::Unitize` divides by −u, so it would probably do the same, at a
  probability of 0.75 to 0.8.

### `inline` on `^∘`

The C of `^∘` at `cga5d` grows from 91 to 1,485 lines. The guide of the language inlines a large
body only where a measurement shows the gain (`STYLE.md`, section 2). No pair of runs here shows
one, as Evidence states, so `^∘` drops `inline`.

## Costs

- **Speed.** In the conformal algebras the rule adds the antidot and a grade scan. The scan runs
  only where the round weight passes, and stops at a second grade. Most of the rest is calls and
  error checks, which the library's operators carry everywhere, and which the gap list holds as
  design gaps. The rigid algebras keep their cost, since their branch is the rule at pin.
- **One call.** Since `^∘` is not inline, each call to `unitize` or `normalizeWeight` calls it, in
  the rigid algebras too.
- **Callers.** No caller changes its text, and in the library `^` and `^∘` reach callers through
  `unitize` and `normalizeWeight` alone. In RGA every result stays as at pin. In CGA a flat object
  divides by √|𝐮 ∘ 𝐮|, its flat weight, where pin leaves it as it is. A motion operator, a
  reflection operator or a mixed element divides by √|𝐮 ∘ 𝐮| too, unless it reads as round. The
  tests of pin call `^` only under `when IS_RIGID`, so each keeps its result.

### What does not hold, for this rule or for Lengyel's

- **It is not a norm.** The conformal antidot is indefinite: 𝐞₁ + 𝐞₄₅ gives 𝐮 ∘ 𝐮 = 0. The book
  says "we are using the term 'norm' loosely here" (page 197).
- **It is not continuous at flats.** No rule that matches Lengyel is, as Problem shows. His
  `Sphere3D::Unitize` divides by −u, which is 0 for a plane.
- **It does not commute with transversion or inversion.** These change the round weight. Hestenes
  calls weight normalization "not Lorentz invariant" ([Old Wine in New Bottles][hestenes],
  section 7). Mann calls it "the non-conformal step" ([AGACSE 2012][mann], page 2).

### Edges of the tests

- **Radius.** A round object of radius r and round weight w has √|𝐮 ∘ 𝐮| = rw. So the test passes
  it as round while r is under 1e9 units, and unitizes a larger sphere as a plane. A huge sphere
  and a plane differ only by that size, so every scale has such a radius.
- **Transversion.** At `cga5d`, a transversion with ½τ of 1e-9 or 1e-13 keeps divisor 1, and its
  round weight is then negligible too. One with τ = (2.1e9, −1.05e9, 0), so that |τ| = 2.35e9,
  has its 𝟙 term under the grade tolerance. It divides by |τ| ÷ 2 = 1.17e9 in place of 1.
  Terathon has no transversion, so no comparison with it tests this.
- **Motion moves the branch.** The grade test reads the largest coefficient, which a motion
  changes. So a motion can move the branch of an element with residue near the tolerance. A round
  point at the origin with residue 2e-9 on 𝟙 divides by 2e-9, and after a translation by 10, by 1.
  That is a factor of 5e8.
- **Range.** Results hold while the squared coefficients stay inside the range of 64-bit floats,
  as at pin.
- **32 bits.** The library sets the comparison tolerance to 1e-4 at 32 bits. A projection from that
  tolerance moves the radius edge in to about 1e4 units, and the transversion edge to about 2e4.
  This change and its claims run at 64 bits alone, so no claim checks this.

### What it leaves out

- **The grade of the library.** This change leaves `grade` and `isMixed` as they are, and `⊛` reads
  `grade`. P07, `part-scale`, takes their zero test, as the Architect ruled on 2026-10-12. That
  test weighs each part at its own scale. In the conformal algebras it also counts a coefficient
  as zero within 16 rounding units of the largest coefficient. This rule does not build on P07,
  so once P07 lands, `grade` and the grade scan of `^∘` can read one element differently.
- **Bulk normalization.** `^∙` stays as it is. A sphere has no round bulk, so a fallback to the
  flat bulk would divide every sphere by its flat bulk. Nothing in Lengyel defines it.
- **Zero weight.** Lengyel's rigid wiki divides a point of zero weight by its bulk norm, as a
  direction ([Point][point]). This rule leaves it as it is.

### What users do

One rule holds in all four algebras, so a user need not know which algebra or kind is in hand.

1. Compose motion and reflection operators freely, while the largest coefficient of each product
   stays under about 1e77.
2. Apply each composed motion or reflection operator once to each object.
3. Once each frame, after the last operation, unitize everything that is read or kept.
4. Keep each motion or reflection operator from frame to frame as its source values, such as
   positions, angles and factors. Compose it again each frame.

- **Why 1e77.** A sandwich multiplies the coefficients of an object by about the square of those
  of the operator, and unitize squares them again. So the moved object overflows once the operator
  passes about 1e77, the fourth root of the largest 64-bit float.
- **Deep hierarchies.** A hierarchy deeper than about 250 random products scales its composed
  operator down once on the way, for example by its largest coefficient. A unitization does that
  only through rounding. A rigid operator stays small at depth 256, so in practice only a
  conformal hierarchy needs that step.
- **Why step 4.** Each frame's operator then has the size of the current pose alone, so no rule
  needs rounding to keep it in range. A kept one near 1e9 can also meet the far edge of the grade
  test. The rule cannot stop rounding of stored state. So persistent state belongs at 64 bits, or
  step 4 rebuilds it each frame.

## Open decisions

- One zero test for `grade` and for `^∘` once P07 lands, or two tests as now. P07 holds the same
  decision.
- Whether a grade test exists that no motor changes, and that keeps the results of this rule. The
  probability is about 0.6. That figure is an estimate, and nothing here measures it.

## Landing

- **Change `conformal-norms`.** This change puts one test at the head of suite Chapter 4, and keeps
  the placeholder test there. `conformal-norms` replaces that placeholder with its two tests. So
  the two apply in either order, and their three tests in Chapter 4 then stand side by side.
- **Float width.** The width of each float is a build option at pin. So `largest` in `^∘` and
  `distance_squared` in `toRoundPoint` are declared `Coefficient`.
- **Norms.** Each norm returns `MultivectorScalars` at pin, which compares with no `Multivector`.
  So each test converts the norm with `toMultivector` before it compares it with 𝟙.
- **P07, `part-scale`.** P07 edits `=~` and `grade` in `pga/multivectors.nim` alone, so no line
  collides. The test that this change adds to suite Internal compares the antiscalar of 𝐯 ∘ 𝐯
  with 1 through the public `=~`, as `abs((𝐯 ∘ 𝐯)[Basis.scalarAnti]) ∧ 𝟙 =~ 𝟙`. So that test
  reads the rule of P07 once both land.
- **P10, `homogeneous-scalar`.** P10 keeps `unitize` as `^m`, which then calls `^∘` of this
  change.
- **Change `algebra-hygiene`.** It renames `TOLERANCE_ABS`, which `^∘` names. So the second to land
  carries the new name into `^∘`.
- **Changes `doc-comments` and `doc-comments-2`.** They edit docs next to `unitize` and `^` through
  distinct quotes, so either order holds. `doc-comments` writes that `^` and `normalizeWeight`
  cost no call. Once it and this change land, that doc says that each costs one call.
- **Sphere of the test of suite Internal.** It has radius one about a random center, through a
  point one unit along each axis and one unit back along the first. So no two of its points lie
  close, as the Architect ruled on 2026-10-16. Random points can lie close, and at `cga3d` two
  points 0.0037 apart sent a plane through and back to a flat weight of 0.999924. A run by hand on
  2026-10-19 applied this change alone at pin, and the suites passed at `cga3d` to `cga6d`.
- **Runs by hand.** A run on 2026-10-19 applied P07 and this change to a copy of the library at
  pin. The suites passed at `rga3d`, `rga4d`, `cga4d` and `cga5d`, at 64 and at 32 bits.

## Evidence

The Architect ruled for this rule on 2026-10-11, on the reanalysis against Lengyel that this page
holds. Unless a note names another run, its figures come from `laws.nim` and `limits.nim`. These
ran on this machine on 2026-10-11, at 64 bits, against the changed library.

### Laws

`laws.nim` holds each law on 2,000 samples at each algebra.

| Law | Worst error, CGA | Worst error, RGA |
| --- | --- | --- |
| Each kind ends at unit weight | 3.3e-16 | 3.3e-16 |
| Product of two or four reflections ends at 𝐯 ⟇ ~∘𝐯 = ±𝟙 | 7.3e-12 | 5.6e-16 |
| unitize(λ𝐮) = sign(λ) unitize(𝐮), for λ from 1e-100 to 1e100 | 7.7e-12 | 5.5e-16 |
| unitize(𝐌 ⟇ 𝐮 ⟇ ~∘𝐌) = 𝐌 ⟇ unitize(𝐮) ⟇ ~∘𝐌, for unit rigid motor 𝐌 | 3.6e-12 | 1.3e-15 |
| Flat has 𝐮 ∘ 𝐮 = ‖𝐮‖□² | 0 | not applicable |
| Unit motion operator keeps 𝐮 ∘ 𝐮 | 3.0e-15 | not applicable |
| unitize(★𝐮) and unitize(☆𝐮) divide by W(𝐮) | 1.8e-13 | does not hold |

- **Unit weight.** The rule divides by that weight, and 𝐯 ∘ 𝐯 is the 𝟙 part of 𝐯 ⟇ ~∘𝐯 for a
  product. The kinds are each object kind, the motor and the flector, in all four algebras, and
  the wiki's translation, rotation, transversion and dilation at `cga5d`. Products with
  𝐮 ∘ 𝐮 < 0 each unitize to |𝐮 ∘ 𝐮| = 1.
- **Homogeneity.** Both divisors scale by |λ|, and both tests read ratios, so no branch changes.
  In floating point, only a coefficient within rounding of the tolerance can cross it.
- **Rigid motion.** A rigid motor maps 𝐞∞ to ±𝐞∞, so it keeps the weight of the carrier. The 𝟙
  part of a product is cyclic, so a unit motion operator keeps 𝐮 ∘ 𝐮 as it is. Both hold where
  the motion moves no coefficient across the grade tolerance, so that the branch stays.
- **Duality.** In CGA each dual maps every basis element to one basis element, up to sign, so the
  grade test reads the same. It keeps the round weight norm and negates 𝐮 ∘ 𝐮, so both divisors
  stay. In RGA a dual swaps bulk and weight.
- **Pencil.** At both conformal algebras the divisor of 𝐬ₜ is |t| to six places for t from 1 to
  1e-8, and 1 at t = 0.

### Zero tests

Each round object below moved by three products of reflections, and each cell counts the objects
that a test read right, of 256.

| Test | `cga5d` at 1 | `cga5d` at 1e8 | `cga4d` at 1 | `cga4d` at 1e8 |
| --- | --- | --- | --- | --- |
| Exact grade scan | 0 | 0 | 2 | 2 |
| Grade at pin, 1e-9 absolute | 256 | 0 | 256 | 2 |
| Antiscalar part is zero | 131 | 141 | 172 | 181 |
| Each part at its own scale alone | 256 | 122 | 256 | 86 |
| P11, 1e-9 of largest coefficient | 256 | 256 | 256 | 256 |

- **Round weight.** Of 10,000 planes sent through a sphere and back, an exact test takes 9,933
  for a huge sphere at `cga5d`, and 9,557 at `cga4d`. This rule misreads none.
- **Motion.** Rotations about the origin alone moved the branch of 15,198 of 20,000 round points
  with residue just past the tolerance.
- **Against P07.** On the populations of P07 at 64 bits, the scan of `^∘` misread 157 elements at
  `cga4d` and 132 at `cga5d`, read alone. The `grade` of P07 misread none there. A test split by
  the round test of this rule, which P07 also measured, misread 71 and 140.
- **At 32 bits.** A run by hand at `cga5d` on 2026-10-12 used a copy of the library with P06. It
  unitized round objects at a deviation of 1e4 units, then moved them. The round test failed on
  563 of 1,024 dipoles, 923 circles and 1,006 spheres, and on every dipole from 1e5. In 64-bit
  arithmetic, with inputs rounded to 32 bits and the tolerance of 1e-4, the counts were the same.
  So the edge comes from the tolerance, not from rounding.
- **Far round points at 32 bits.** The same run failed 753 of 1,024 round points at 1e8, and none
  at 64 bits. A 32-bit point that far out is a sphere of radius about √ε times its distance.

### Frames

`limits.nim` holds the rule, with frames at 60 each second. Each move of the chains and of the
hour is a product of two reflections 0.01 apart, as animation steps are. In the depth rows, each
product is of two random reflections, which grows far faster. The error is the change of distance
between moved points in RGA, and the drift of a moved round point from radius 0 in CGA.

| Measure | `rga4d` | `rga3d` | `cga5d` | `cga4d` |
| --- | --- | --- | --- | --- |
| One frame, depth 256, against step by step | 1.5e-14 | 3.6e-14 | 1.3e-14 | 2.2e-14 |
| Largest coefficient of that composed motion operator | 1.4e1 | 7.6 | 8.0e54 | 6.0e66 |
| Motion operator kept an hour, unitized each frame: error | 3.3e-16 | 1.0e-15 | 5.2e-16 | 1.7e-16 |
| Largest coefficient of that kept motion operator | 5.1 | 1.2e1 | 1.5e9 | 3.0e9 |
| Its \|𝐯 ∘ 𝐯\| before each unitize, worst distance from 1 | 1.1e-15 | 1.1e-15 | 1.4e3 | 2.3e3 |
| Same moves, never unitized: largest coefficient | 5.1 | 1.2e1 | 1.7e81 | 1.8e82 |
| Half hour: points, unitized against never, differ by | 3.0e-13 | 1.8e-12 | 2.8e-15 | 5.6e-15 |

- **Kept operator.** Each move is unit, so in exact arithmetic the kept product is unit, and a
  unitization divides it by 1. A unit rigid motor holds coefficients near the size of its
  translation. So it stays small, and a unitization each frame is harmless and not needed.
- **Conformal, never unitized.** The antidot is indefinite, so a unit motion operator can hold
  large coefficients. The kept one grew about 1.4 orders of magnitude each minute, until overflow
  lost its points. That is its true size, not a drift of its weight.
- **Conformal, unitized each frame.** The terms of 𝐯 ∘ 𝐯 grow as the square of the coefficients,
  and cancel to ±1. Past about 1e7 to 1e8, their rounding passes 1, so the rule divides by
  rounding. That holds the operator near 1e9, in range though not unit, and its points stay the
  same.
- **Depth.** Each random product adds about 0.21 orders of magnitude at `cga5d` and 0.26 at
  `cga4d`. At that rate a composed conformal operator passes 1e77 near depth 360 at `cga5d` and
  about 300 at `cga4d`, which nothing here measures.
- **Residue.** Over 1,000,000 moves, residue in other grades reached at most 2.1e-15 for rigid
  moves, and 5.8e-12 for conformal moves unitized after each. Both lie under the grade tolerance,
  so grade selection is not needed. It would set that residue to 0, and change no invariant
  measured here, while the rule scales every coefficient alike and so removes none.
- **Composing.** A composed operator touches the object once. After 1,000,000 moves, residue on
  that path reached at most 9.4e-15 in all four algebras, and step by step, 2.1e-15 for rigid moves.
- **Stored at 32 bits.** A rigid motor stored at 32 bits each frame drifts from its 64-bit twin by
  up to 1.2e-4 of the scene in six hours. That holds with a unitization each frame or without.
  `limits.nim` rounds the motor to 32 bits inside a 64-bit build, as 32-bit storage would, so
  this needs no P06.

### Speed

At `cga5d` the adds of `^∘` rise from 7 to 38, its calls from 1 to 163, and its error checks from
1 to 66. Six earlier evaluations of the inline form, on 2026-10-11 and 2026-10-12, gave 66.59 to
91.17 ns at `cga5d`. They ran from commit a712559b to commit 09e9579a. So the time of the change
varies by up to about 40% between evaluations. The form here, without `inline`, ran in 89.87 ns,
inside that range, so no pair of runs separates a gain of `inline` from noise. Its ratio lies
above their ×6.98 to ×8.78, since pin ran in 7.43 ns here and in 8.56 to 9.02 ns there.

### Lengyel's sources

Lengyel's sources are his book, his Terathon Math Library in C++, his Mathematica packages in the
repository `Geometric-Algebra` at commit 473a801, and his two wikis. The code is MIT licensed.
The table of Idea reads Terathon's `RoundPoint3D`, `Dipole3D`, `Circle3D` and `Sphere3D` with the
book's Table 4.12, and its rigid `FlatPoint3D`, `Line3D`, `Plane3D`, `Motor3D` and `Flector3D`. It
reads the screw motor and `RoundSphere` in `Conformal-3D-Transforms.nb`, and the other motion
operators on the conformal wiki. `TSConformal2D.h` follows the same pattern in 2D, with a signed
round point and circle.

The search read Terathon, the packages and notebooks at commit 473a801, book Section 4.3, and the
pages of both wikis read here. The probability that it missed a general conformal rule in them is
about 0.03. The rigid wiki cites book Section 2.10.2, which the search did not see. The
probability that it states the same general rule is about 0.85. The search found no equivalent of
the test between the branches in Lengyel, or in the literature it checked. The probability that
none is published is about 0.75, from those sources, the papers cited here and Python `clifford`.

[rigid]: https://rigidgeometricalgebra.org/wiki/index.php?title=Unitization
[point]: https://rigidgeometricalgebra.org/wiki/index.php?title=Point
[hestenes]: https://davidhestenes.net/geocalc/pdf/OldWine.pdf
[mann]: https://cs.uwaterloo.ca/~smann/Papers/AGACSE12b.pdf
[keninck]: https://arxiv.org/pdf/2206.07496
[hitzer]: https://arxiv.org/pdf/1306.1660
