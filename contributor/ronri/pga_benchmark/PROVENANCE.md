# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-29 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 6d66292a627b7509 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |
| Pruned  | de53b987e9686537ecae415d637952640dafb9ce |

Origin: the Architect audited `pga` (head `0bc4655`) in the session that opened this project.
The audit measured:

- a dense-representation cost of about nine times a hand-written sparse product at 4D;
- zero-filled intermediates on every operator chain;
- no cross-module inlining;
- per-term error-flag checks;
- dead compile-time Cayley work;
- conformal norms that return NaN.

This project turns that audit into a standing instrument. It is the gap list that the
Architect reads during work on the library, and the measurements that show nothing
regressed.

Authority replicated: Lengyel's equations, through the library's own suites and through the
typed reference here. There is no vendored source. The list itself is `gaps.md`, generated
and committed, and its identifiers live in `baseline/docket.json`. The words are in
`GLOSSARY.md`, and the Architect chose every one. Nothing here counts its own gaps in prose:
`nim r tools/build.nim gaps` counts them, and the list says.

## Catalogue

Every operation that the library exports is one `Measurand` value, built at compile time
under the same `when` that the library selects its algebra with. So one list serves every
algebra. A general measurand spells each exported operator over dense multivectors. A typed
measurand spells the same operator over the operand kinds that Lengyel's reference has a form
for, and it names that form. Three composed measurands spell the motor sandwich that the
library has no operator for.

Expressions are strings, fully parenthesised, because the header of the library warns that
`∨` parses as additive and `∧` as multiplicative. They are lowered by `parseExpr` where the
measurements are emitted. `^` is a template over `^∘` in the library, so the C carries only
the latter. `TEMPLATES` records the pair, and the suite holds it to the source of the
library. `MISSING` names the two conformal norms that the library declares as errors.

`INLINED` names the symbols that the library spells as a template over a field read. At the pin the
component accessor `[]` is such a template. So the C carries no function for it, and the emission
suite passes over it. A suite holds `INLINED` to the source of the library, as it holds `TEMPLATES`.
The gap row for `select_part` carries a dash for every count, and its verdict rests on time alone.

The squared norms `|∙²` and `|∘²` are spelled in backticks, as `` (`|∙²`(m)) ``. The
character `²` is no operator character to the lexer, so the prefix form splits it off as an
identifier and `parseExpr` fails on it. These two operators carry no alias in the umbrella,
so their alias field stands empty and the alias suite passes over them.

Their cite is the
equation that defines the norm. The squared quantity is what stands under its root. The
suites of the library cite none. The reference returns the weight squared norm as an
`Antiscalar`, so that widening puts it in the antiscalar slot where the library writes it.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Catalogue`. Ids are unique. Every
expression compiles against the library. The set of symbols equals the set of exported
operators, read out of `pga/operators.nim` and `pga/multivectors.nim`. The set of aliases
equals the exports of the umbrella.

## Reference

`reference/rigid3.nim` (4D, rigid) and `reference/conformal3.nim` (5D, conformal) hold
Lengyel's typed objects and optimal forms for 3D Euclidean space, written in Nim.
`reference/rigid2.nim` (3D, rigid) and `reference/conformal2.nim` (4D, conformal) hold them
for 2D Euclidean space. They are in 64-bit floats, so both implementations run the same
scalar. Every 3D operation was derived from the equations of the book and from the library's
own definitions. The Terathon Math Library was read as a cross-check of forms and counts, and
nothing of it was copied.

**The 2D forms come from an expansion of the definitions.** A script expands each definition
of Lengyel's exterior algebra on the components of the typed objects. At rga3d its metric is
e₁² = e₂² = 1 and e₃² = 0. At cga4d it is e₁² = e₂² = 1 and e₃ ∙ e₄ = −1. The expansion
reproduces the library on every pair of basis elements: 400 cases at rga3d, 1,245 at cga4d.
They cover every product, complement, dual, part, attitude, carrier and cocarrier.

The expansion also reproduces the support, center, container and partner on one integer operand of
each grade. The attitude takes 𝐞̅₃, the complement of the origin, as it takes 𝐞̅₄ at cga5d. The
motor transforms take the form of Terathon for a unit motor, 15 multiplies where the expansion
spends 30. The partners are factored by hand, 15 multiplies for a dipole where the expansion spends
36. The script stays out of the tree, because no checker reads its kind of file. The law suites hold
every form to the library on the pools instead.

Where the sign conventions of the library differ from Terathon's, the library's were adopted,
because the library is what is measured. The bulk and weight duals of points and planes carry
the opposite sign. The conformal antidot is the negated dot. The cocarrier of a circle reads
`LineFlat(v: -g.xyz, m: -c.v)`. The `Partner(Circle)` scalar of Terathon carries a sign typo,
and the form here is `f = gw² - v·v - g·m`, which the law suite confirms against the library.

Every form is `{.inline.}`, so it lands in the same nimcache as the operators of the library, and
the same reader counts it. Object construction goes through the `zero3` and `read3` templates,
rather than `Vector3()` defaults and whole-object field copies. In C, a default zero-fills its field
through `nimZeroMem`, and a whole-object copy calls the `=dup` hook that the compiler makes for
`Vector3`. Either cost would charge the reference for work that hand-written code does not do.

Three builds of the bench differ only in these two templates: as committed, `Vector3()` for
`zero3`, and a whole copy for `read3`. Five alternating runs of each, on `linux amd64, 4 cores` on
2026-10-03 at `3121342`, time them at rga4d and cga5d. At rga4d `bulk_line` runs 2.61 ns as
committed, 23.49 ns with `Vector3()` and 4.19 ns with the copy. The other three line rows with a
default run 22.5 to 23.5 ns, and `attitude_plane` runs 3.35 ns against 2.14 ns.

Rows that use neither template move ×0.65 to ×1.29, so the copy in `transform_line_motor`, ×1.04,
does not show. At cga5d a default adds 18 to 30 ns to eight rows, and a copy adds 1.6 to 4.4 ns to
seven. Why a default costs 20 ns in a line row and 1.2 ns in `attitude_plane` is not isolated.

Unitize forms take one reciprocal and multiply, as Terathon does, where the library divides each
component. The divide column shows both.

**No reference function calls another.** Under `--panics:off`, each call to a Nim function
fills its result with zeros and branches on the error flag after it. Hand-written code spends
neither. So the vector helpers and the rotation are templates, and a form that two functions
share is spelled in each. A spelled form carries the terms of the form it repeats, so their
arithmetic counts are equal.

Five alternating runs on `linux amd64, 4 cores` on 2026-10-02 time the reference with and without
those calls, one build each. At rga4d the unitize of a line, a plane and a motor ran ×0.23 to
×0.24 of its time with the call. The other changed measurands moved ×0.52 to ×1.35. In the
same runs, measurands with unchanged code moved ×0.60 to ×1.11. So outside the unitize forms,
the effect on time is not separable from code layout.

Verified by `test_rga4d.nim` and the other stubs, suite `Chapter 2` and one suite `Wiki: <page>` for
each wiki page that a typed measurand cites. For every typed measurand and every seeded sample, the
reference widened into the dense multivector equals the library within `=~`. Each check cites its
equation or wiki page. Each of the four algebras of the stubs carries a typed reference. An
algebra that the sweep alone reaches holds one skipped test in each of those suites, which names
the gap. Suite `Internal: Catalogue` holds every typed cite under
chapter 2 or a wiki page, so no cite falls outside every suite.

Suite `Internal: Inspector` reads the nimcache of the test binary itself. It finds
that `wedge(Point,Point)` spends twelve multiplies and six subtractions at rga4d, and six and
three at rga3d, as its documentation states. It holds every reference function in that
nimcache to no zero fill and no error check. The count it reads must reach
`FLOOR_FUNCTIONS_REFERENCE`, which is 73 at rga4d, 84 at cga5d, 50 at rga3d and 66 at cga4d.

The movement model reads the size of a typed stem from the module of the function that reads
it. The 2D and 3D references share type names at other sizes: a 2D point is 24 bytes, and a 3D
one 32. Suite `Internal: Inspector` holds both sizes.

## Widening and pools

A widen puts each typed object into the dense multivector at its basis slots. A narrow reads
it back, and asserts under `-d:testing` that every other slot is zero. Pools are filled once
from `randomize(0)`: dense multivectors of every grade, typed objects in general position,
lines and planes joined from points, and motors unitized. Every typed pool has a widened
image, so the two implementations read equivalent operands.

Verified by `test_rga4d.nim` and the other stubs. Suite `Chapter 2` and the `Wiki` suites run
through the widening, and suite `Internal: Measurements` runs every measurand over the pools.

## Measurements

`emitCatalogue` turns the catalogue into one timed loop for each measurand of each
implementation. Operands are template aliases into pool slots, and never copies, so the loop
moves only the traffic of the operation itself. Every result is folded into one sink after
the timing, so nothing is dead. The share of results that carry NaN is counted. The conformal
norms of the library return NaN on real objects, and that is measured rather than stated.

**Each timed loop has a procedure of its own**, one for each measurand of each implementation,
as the function of a caller would call it. In one function that holds every loop, Nim puts an
error check after each call, and gcc guesses that each check may be taken. Its estimate of
reaching code below then falls to zero after the first measurand. Code that gcc estimates
never to run is optimised for size, and gcc does not vectorise its loops. So the loop of `+`
stayed scalar, while the straight-line dense form still became two-wide adds.

At rga4d at `d9be8ae`, gcc estimated 5,215 of the 5,306 blocks of that function never to run.
It analysed 5 of its loops for vectorisation. Without its guessed profile, it analysed 673 and
vectorised the loop of `+`. Three alternating runs of each build at rga4d, on `linux amd64,
4 cores` on 2026-10-03, time the library against its dense form:

| Measurand | One function | A procedure each |
|-----------|--------------|------------------|
| `+` | ×1.54 | ×0.78 |
| `-` | ×1.48 | ×0.79 |
| `-m` | ×1.85 | ×1.00 |
| `scale` | ×1.29 | ×1.01 |
| median general measurand | ×1.035 | ×1.001 |

The norms stay at ×1.7 and the antigrade selection at ×2.9, so those gaps are the library's.
Suite `Internal: Inspector` holds each timed loop in a C function of its own.

**Pools and results start on a cache line.** The linker put each pool 32 bytes into a line at
rga4d, so a multivector read spanned three lines and not two. Typed objects straddle lines in
other patterns, so dense and typed operands read different layouts. On the same machine and
day, one straight-line form ran 6.40 to 7.59 ns as its arrays moved. Without aligned results,
`dual_weight_point` at rga4d ran 5.44 ns against 2.71 ns. Suite `Internal: Measurements` holds
each pool to a line.

**Result slots start uninitialised (`noinit`).** A fill of zeros that the compiler sees lets it
delete each store of zero that repeats the fill. The bench then times fewer stores than a caller
pays.

Alone, `∙` at rga4d ran at 4.4 ns into slots filled once with zeros, and at 7.0 ns into slots
left uninitialised. In the bench at `3121342`, the machine code holds 245 stores of zero
with or without the fill. So there a fill gives no measurand a discount, and the `noinit`
keeps it so as the catalogue grows. Both figures are from `linux amd64, 4 cores` on 2026-10-02.

**A result of three floats or fewer is bound before its slot.** Nim returns such a result by
value, through a temporary that the call site fills with zeros. In a large function, the
compiler keeps that fill as a call to an out-of-line `rep stosq`. A caller of normal size pays
nothing, because there the fill is two stores that the compiler deletes.
Of the 2D reference rows, 30 return such a result, and of the 3D ones none.

Two sessions of five alternating runs on `linux amd64, 4 cores` on 2026-10-03 time the 2D
references, one with the fill and one bound first. With the fill, those 26 rows at rga3d and 4
at cga4d take 12.1 to 15.5 ns. Bound first, they take 0.8 to 5.0 ns. Within each session,
library over reference for `complement_left_line` reads ×0.20 with the fill and ×2.98 bound
first. The other reference rows move ×0.42 to ×1.70 between the sessions.

The session bound first is the committed baseline, and the session with the fill is not
committed. Bound first or not, the C at rga4d and cga5d is the same byte for byte. Suite
`Internal: Inspector` holds the loop to no temporary filled with zeros.

`bench` runs `ROUNDS` rounds over `OBJECTS` objects, and reports the median and minimum
nanoseconds for each object: the runtime measurements. The allocation gauge is live only
under `-d:nimAllocStats`. The bench refuses to report allocation counts unless a positive
control raised the counter first. A zero then means zero, and never an inert instrument
(Article VII.4). The plain build reports the gauge as off, and that is the measurement taken
once compiled out.

**The bench runs five times, and each time is the median of those runs.** `bench` runs the
plain binary of each algebra in turn, algebra after algebra, `RUNS_BENCH = 5` times. So drift
of the machine lands on every algebra alike. For each implementation the runtime baseline
keeps the median of each run as `ns_runs`, in run order. `ns_median` is the median of those,
and `ns_min` is the least minimum.

One run times both implementations, so the runs pair by index, and each run gives one time
ratio. The docket draws one tick for each of those ratios. Rejected: the spread of rounds inside
one run, because it misses drift between runs. That drift is the larger part on this machine.

**The runtime baselines are from 2026-10-03 at all four algebras**, at `d9be8ae`, five runs each
on `linux amd64, 4 cores`. The bench of 2026-10-01, run at `3121342` on 2026-10-02 in turn with
the baselines of that day, gives the drift between days. At rga4d its library runs ×1.19 to ×1.22
of its own times of 2026-10-01. Its reference runs ×1.26 to ×1.27, and its dense forms ×1.00 to
×1.01. The bench of 2026-10-02 runs ×0.99 to ×1.01 of it in the same runs.

So the machine moves between days, and not by one factor for each implementation. Times
taken at different hours never compare, and ratios within one run do.

Within these baselines, the least and greatest run ratios of the median measurand are ×1.10
to ×1.12 apart at each algebra. The widest measurand spreads ×2.24, as `partner_circle` at
cga4d does. Its reference takes about 1.4 ns, and in one run of five it takes 3.1 ns.

So one run's time ratio is weak evidence, and the ticks on the docket say how weak.

**`ns` stays in names as a unit symbol.** The root glossary takes every prefix of SI Table 7
under `## Standards`, so `ns_median` and `ns_library` keep it (V.6). A single
letter stays only where an equation or a small index scope gives it meaning (V.6). Examples
are `i` in a scan and `a + b` in the sum of counts.

Verified by `test_rga4d.nim` and the other stubs, suites `Internal: Measurements` and
`Internal: Allocation`. `summarise` runs on fixture rounds, and fixture runs combine to the median
of their medians, the least minimum, and each run's median in order. A short run of the timing
instrument reads the real clock, as Article IX.12 lets an instrument test do. It shows that the
clock was read, that each minimum sits at or under its median, and that results reach a non-zero
sink. No limit on time decides it. The positive control raises the counter, and then no measurand
allocates over a preallocated loop.

## Inspector and movement

The inspector reads the C that the compiler emits for the `bench` entry: the static
measurements. It splits function definitions at their braces. It reads the name mangling of
the compiler back to symbols. ASCII operator characters become words such as `bar` and
`roof`, and other bytes become `X<hex>`. `_u<n>` numbers the overloads, and `__<module>`
names the module.

It keys every function by symbol and by parameter type stems. It then counts what the C
spells:

- multiplies, adds, subtractions and divides;
- `nimZeroMem` calls, intermediates and whole-object copies;
- `nimErr_` branches, call sites, allocation calls and lines.

A term inside a loop counts once for each trip, where the bound of the loop is a literal.
`for b in Basis` emits `res <= ((NI) 15)`, and `0 ..< 16` emits `i < ((NI) 16)`; the start of
the counter is read from its last assignment. Nested loops multiply. A bound that names a
variable counts once, because its trips are not in the text. Callees fold at each call site,
once for each trip, because the library chains operators.

Functions that share stems are numbered by overload index: `{}` over grade and antigrade, and
`[]` beside its `var` twin. The compiler assigns that index in declaration order, so the keys
hold whatever order the C emits them in. Emission order moves when a module is renamed, so a
key by position would swap. Movement turns counts and type sizes into
bytes read, written, zeroed, copied and materialised for each call. It names the bytes that
the code moves, and is not a measurement of cache traffic (Article VIII.1).

On the pinned commit an error-flag branch follows every call of a Nim procedure under goto
exceptions. `{.raises: [].}` on the callee does not remove it, and only `--panics:on` does, which is
unmeasured at the pin. The library does not stand behind `--panics:on`, as the Architect ruled. So
counts are taken with the flags that the documents name, `-d:release`, which is
what a user of the library gets by default.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Inspector`. It covers:

- a demangling table with overload indices;
- a fixture C source with known counts;
- loops of literal, nested and variable bound;
- divisions inside a loop and inside a callee, and callee folding;
- movement from stems;
- the nimcache of the test binary itself, which holds every catalogued symbol at its arity.

## Baseline and guard

`baseline/static_<algebra>.json` records the static measurements, and
`baseline/runtime_<algebra>.json` records the runtime ones. Both are schema 1, with a header
that names algebra, compiler commit, library commit, flags, machine and date. `guard`
compares a fresh inspection against the baseline. Any gated count or bytes moved that grew is
a finding, rendered as `path:0: message; got value`. Any shrink is a notice. A document of
another algebra, compiler or set of flags is refused rather than compared.

Date and machine are ignored, because static measurements owe them nothing. `drive` is the
verb that koch and CI run: inspect every algebra, guard, and hold the committed `gaps.md` and
docket to regeneration. It is deterministic because it times nothing.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Guard`. Equal documents pass
silently. One grown count is one finding, which names function, metric and both values. A shrink is
an improvement only, and bytes moved are gated. A function absent in either document is a finding,
and another build or schema is refused. A lower bound that moves either way, or that is absent now,
is a finding.

## Lower bounds

**Each operation carries two lower bounds, and the library stands above both.** The
multivector lower bound is what the algebra demands of any implementation over a dense
multivector. The type optimised lower bound is what the typed reference spends, and it needs
a representation that a dense multivector cannot reach. The distance between them says how
much of the gap is the representation, and how much is the quality of what the generator
emits.

The two differ in kind, and the record keeps that difference (Article VIII.1). The
multivector lower bound is **derived** from the axioms, so it is a bound in the strict
sense: nothing can spend less. The type optimised lower bound is **measured**, so it is the
best known rather than the provably least. Work that reaches the first changes no type, and
work that reaches the second changes every one.

`src/pga_benchmark/bound.nim` derives the first, and reads nothing from the library
(Article II.8). Blades are bitmasks over dimensions. A rigid algebra degenerates its last
vector, so its metric is singular and a blade carrying that vector has no image. A conformal
algebra pairs its last two vectors off diagonal, so its metric is invertible and every blade
has an image.

Each operation carries a shape, and the shape carries the rule. An exterior product spends
three raised to the dimensions, because each dimension stands in one of three states for a
pair of blades. A geometric product loses one of four states for each null dimension. A
bilinear form landing in one slot spends one term for each blade that carries an image.

A product against the dual of its second operand spends what the grade of that operand
allows. A permutation and a product against a one-component constant spend nothing. The
carrier, the cocarrier and the attitude each take that last form, and so spend nothing.

A support, an antisupport, a centre and a container each apply maps to the operand and then
take one product. A map is a signed read, so the product against the mapped operand is one
table, and the cells of that table are the bound. The supports count 54 at four dimensions,
and the centre and the container count 162 at five. Those counts rest on the same assumption
as the primitives, that no slot shares a subexpression with another.

The library composes some other operations from several operators. A norm reads two slots.
The four projections take a dual product and then a full product. The partner is cubic in
its operand, so it stays a chain of two folded tables. Those are the container of a dual,
then an antiwedge against the carrier.

Such an operation carries a chain of shapes, and its bound sums what each step demands. A
step that carries no rule adds nothing to that sum.

A chain bound is an estimate of that chain, and never a proved minimum. A special routine
can share work between steps, or reach the same answer by a shorter route, so the true
minimum sits below it. `gaps.md` names the steps in the shape column, so every chain bound
reads as one. Every other bound in those tables follows from the axioms alone.

Under a rigid metric a dual product thins out by grade. One dual drops the blade that carries
the null vector, and the other keeps only that blade. Under a conformal metric each dual is a
signed permutation of every blade. A product against it then keeps every cell of the wedge,
243 at five dimensions. The tables the library emits carry that count, and the bound follows.

The bound spends no zero fill, no intermediate, no error check and no allocation, because a
dense operation needs none of them to be correct. It moves its operands read once plus its
result written once. `gaps.md` carries one row for each operation of each algebra, since the
bound rests on the operation and never on the operand kinds.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Lower bound`. At four dimensions
with a rigid metric the derived counts reproduce 81 for the exterior product and 192 for the
geometric product. They reproduce 8 for the bilinear form, and 54 and 27 for the contractions. They
reproduce 27 and 54 for the expansions, 16 for a scale and 24 for a unitize.

The conformal metric is held to 1024 and to 32, and to 243 for each of the four dual
products. A chain of an expansion and an exterior product is held to their sum, 486 at five
dimensions.

The supports are held to 54 at four dimensions, and the centre and the container to 162 at
five. The partner chain is held to 324, and to its mark as an estimate.
Suite `Internal: Inspector` holds the soundness law. No lower bound outruns what the library
spends on the same operation. That law reads the build's own nimcache, and every measurand
with a derived bound meets its library function there. It reads at least `FLOOR_ROWS_BOUND`
measurands: 107 at rga4d, 130 at cga5d, 39 at rga3d and 46 at cga4d.

**What the bound finds at the pin.** Every primitive product spends what the algebra demands,
and the operations built on top of them do not. At four dimensions the library stands at the bound
on multiplies for 101 of the 107 operations that carry one. The two supports are what stand
above it, at 162 against 54. At five dimensions it stands at the bound for 110 of the 130
that carry one. The cocarrier, the centre, the container and the partner stand above it.

The attitude and the carrier are generated from a Cayley table, so each spends no multiply,
as the algebra demands. The centre spends 486 against 162, the container 243 against 162,
and the partner 518 against 324. The cocarrier wedges against a constant that carries
one unit component. So it spends 243 multiplies where the algebra demands none.

On bytes moved the library stands at the bound for 55 of 107 operations at four dimensions,
and for 81 of 130 at five. Those are the operations that one generated function serves,
since that function writes every slot and fills nothing. A chain fills its
intermediates, and stands above the bound.

At four dimensions the exterior product spends the bound's 81 multiplies and moves the
bound's 384 bytes. The bulk norm spends the bound's 8 multiplies, and moves 640 bytes
against the bound's 136.

At four dimensions 65 operations carry a library function, a bound and a reference. Over
those, reaching the bound closes 54 per cent of the byte distance to the reference. It
closes 24 per cent of the multiply distance. At five dimensions 84 operations carry all
three, and reaching the bound closes 82 per cent and 39 per cent. Without the chains, the
byte shares are 51 and 47 per cent. Those shares rest on one population, so
the figures compare.

Cost: the multivector lower bound is derived, and never measured (Article VIII.1). It bounds
arithmetic and movement, and never time. It assumes that no result slot shares a
subexpression with another, which holds for these products and would not hold where
factoring helps.

Cost: a chain bound sums the steps of the library's own definition, so it is an estimate
rather than a proved minimum. The record marks every such bound, and `gaps.md` names the
steps.

## Dense form

**A general row is timed against its dense form**, as the Architect chose. A general row has
no reference, so nothing measured stood for what a dense multivector could spend. The dense
form is that measure. It assigns each slot once as the sum of its terms, with no fill, no
intermediate multivector and no call.

`dense.nim` generates one dense form for each general measurand at build time. It evaluates
the operation symbolically over the library's own Cayley tables. Each slot is a polynomial
over the components of the operands. A sign map composes for free, a product multiplies
polynomials, and like terms combine. An operand that is already a product binds scalar
temporaries first, so a chain spends the sum of its steps.

An operand that is only a map of another folds into the product. So the support, the
antisupport, the centre and the container each spend one folded table. The partner carries
the sign of the grade of its operand, as the library's does. Its scan of the grade is
unrolled at build time, since a loop over `Basis` guards its counter against overflow even
in a release build.

**What the dense forms spend.** At rga4d and cga5d every dense form that one rule covers
spends exactly the multivector lower bound. The support and the antisupport spend 54 where
the library spends 162. The centre spends 162 where the library spends 486, and the partner
324 where the library spends 518. No dense form fills, copies, calls, checks or declares an
intermediate.

Two chains in each rigid algebra spend less than their bound. The central projection and the
orthogonal antiprojection spend 81 against 108 at rga4d, and 27 against 36 at rga3d. Their
first step leaves whole grades at zero, and the second step reads none of them. So a chain
bound is an estimate.

**What the library spends in time against them.** The runtime baselines time each dense form
beside the library, five alternating runs at `d9be8ae`, at four algebras, on `linux amd64, 4 cores`
on 2026-10-03. The median general measurand runs ×1.00 to ×1.01 its dense form, since most
library operators are already one generated table. The compound operations are not. They run
×2.1 to ×6.5 their dense forms, from the container at cga5d to the support at rga4d.

The antigrade selection runs ×2.4 to ×3.2, and the norms ×0.77 to ×2.1. Sum, difference and
negation run ×0.65 to ×1.12, and the unitizes ×0.89 to ×1.14. So a dense form is a measure, and
never a lower bound on time.

Rejected: a dense form written by hand for each operation. There are 40 to 47 operations at
each of four algebras, and forms by hand would drift from the library as it moves. The
tables are the library's, so a dense form shares any sign that the library gets wrong. The
chapter suites hold the library to the reference, and the suite below holds the dense form to
the library.

Verified by `test_rga4d.nim` and the other stubs, suites `Internal: Dense forms` and
`Internal: Inspector`, at all four algebras. Every dense form equals the library on the seeded
pools, NaN included. The inspector holds each dense form at the multivector lower bound, or at or
below it for a chain. It also holds each one free of fill, intermediate, copy, call and check.

## Gap list

One gap for each measurand of each algebra. A gap is over where the library exceeds its
reference on multiplies, divides or bytes moved. It is over where it spends any zero fill,
intermediate, error check or allocation, or returns any NaN. Time is over beyond a tolerance
of `TOLERANCE = 1.25` times the reference median, because medians on a shared machine move by
tens of percent between runs. A gap with no reference is decided on the absolute targets
alone.

Every key `<algebra>/<measurand>` is given a number by the docket on first sight, and keeps
it. The docket never reuses a number. It is a docket rather than a ledger, because the
glossary of the repository uses ledger for the daily read of GitHub.

Causes sit above the gaps. Each cause is decided by a rule over the documents, and carries
its evidence and the condition that closes it. The list then closes by measurement, and never
by an edit. The renderer refuses any line beyond 100 runes, because the product is committed
and form-checked.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Gaps`. It covers the gap verdicts
on fixture documents, an unmeasured gap, and docket stability across a reorder and a new key. It
also covers the verdict and evidence of every cause, the rendered width, and rune-counted wrap.

## Driver

`tools/build.nim` carries `inspect`, `bench`, `baseline`, `guard`, `evaluate`, `pages`,
`published`, `drive`, `gaps`, `show`, `sweep`, `system` and `clean`, dispatched from
`case paramStr(1)`, so koch reads the verbs itself. `system` prints `git`, `curl` and
`coreutils`: git reads the library head, and the other two serve `koch fetch-assets`, which
fetches and checks the faces. `sweep` compiles the bench at two to six dimensions, rigid
metric, and prints the medians of the general measurands. It never runs in CI.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Guard`. A grown total is one
finding. With the fixture path of the suite, it renders so:

```text
baseline/rga4d.json:0: Total `multiplies` of `∧(Multivector,Multivector)` grew; got `90`,
baseline `81`.
```

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Driver`: the dispatch, the usage
string and the header table name the same verbs.

## Changes, proposals and evaluations

**A change is Markdown, and quotes what it edits.** Each file in `changes/` holds a title,
why, and one section for each edit: a quote of the library at pin, then its replacement. A
whole-file replacement carries the digest of the file it replaces instead. A quote must occur
once at pin. A line number moves with every library commit, and a quote moves only when its
own lines do. So a change that still applies at head still says what it meant.

**A proposal is one directory, with one shape.** `proposal.md` argues the future state,
`change.md` holds its candidate edits, and `claims.json` lists the proposals it builds on and the
claims that its evaluation checks. A claim is data, so the page shows each verdict beside it. The
kinds are `suites`, `tables`, `program`, `count` and `build`. Rejected: a proposal as prose
alone, because nothing could then say whether it still holds at head.

**A proposal keeps its number for good.** Its directory opens with the number, as
`01-cayley-derivation`, and its title with the citation, as `P01`. `drive` holds the numbers
unique and without a gap, so no number goes to a second proposal. A proposal that the library
implements stays, with status `implemented` and the library commit, and a withdrawn one stays
too. `drive` applies neither at pin, and each page keeps its last evaluation. So a
citation still leads to what was proposed and measured.

A program claim names its program relative to its proposal, so a new directory name moves no
digest.

**Proposals build on each other as a graph without cycles,** as the Architect ruled on
2026-10-04. The Architect decides each proposal on its own. So each one lists in `builds_on` the
proposals whose changes it needs, and an empty list says that it needs none. Rejected: one base
for each proposal. A proposal that needs two others could then not say so.

`dependenciesOf` walks the graph depth first. It gives what an adoption needs first, each one
after its own bases and once only. `dependentsOf` gives what a rejection blocks. A cycle, an
unknown name, a withdrawn base or a `builds_on` that is not a list is a finding. A base that the
library implements drops out, since the library holds its edits.

**Each proposal page states its dependencies, and one page lists every proposal.** The page of a
proposal names what it depends on and what its rejection blocks. Where a proposal is reached
through another, the page names that one too, as `(through P02)`. The list page gives each
proposal its standing, its claims that hold, its dependencies and what it blocks.

Above the table, the list page draws the undecided proposals as a graph, in columns by depth and
in rows by number. An arrow points from a proposal to one that it builds on, as `builds_on`
reads. A decided proposal needs no choice, so the graph leaves it out, and the table keeps it.

**The list page shows each selected proposal in place,** as the Architect asked. Each box of the
graph and each row of the table is a label of one checkbox for each proposal. A checked proposal
shows whole under the table, as its own page renders it, one heading level down. A close label
deselects one, and the reset of the form clears them all. One rule for each proposal ties its
labels to its checkbox, so the page runs no script. The cost is weight: the list page carries
each proposal, 4.5 MiB against 4.3 MiB without them, by `ls -l build` on 2026-10-04.

**An evaluation measures a copy of the library at pin.** It copies the checkout, applies the edits
(what the proposal depends on first, in the order of `dependenciesOf`), and measures the copy
against the pin. It runs the suites of the
library, reads the static measurements of every function, and times each measurand. The
binaries of the pin and of the copy run alternately, five times each, so drift of the machine
lands on both.

**An evaluation builds without dense forms**, under `-d:pga_benchmark.has_forms_dense=false`.
A dense form reads tables by their names at pin, and a change may rename them, as
`cayley-derivation` does. The evaluation compares the library with the pin, so it needs no
dense form.

**A build claim compiles the library alone**, from an entry that holds `import pga` and nothing
else. At rga6d the library with P01 peaks at 170.8 MiB against 235.0 MiB at the pin, ×0.73
(`evaluations/cayley-derivation.json`, 2026-10-04, `linux amd64, 4 cores`). The claim of P01
holds ×0.75 at most, as the Architect ruled on 2026-10-04, so P01 saves 64.2 MiB within its
claim. The pin builds most anti tables with `constructAnti`, as P01 does, which is why the
claim is not ×0.70. Which part of the cost the two share is not isolated.

Rejected: the bench entry, which puts the harness in the measured build. With the library
fixed at `bd6b23c`, one change to `inspector.nim` alone moved the P01 side from 211.7 MiB to
261.2 MiB at rga6d on 2026-10-01. A wider bound would not hold either, since the next change to
the harness moves it again.

The evaluation then checks the claims. The document names the pin and a digest of what it
tried: every edit, every claim and every program, and never the prose. So an evaluation is current
exactly while its edits are. Evaluations measure rga4d and cga5d, the 3D Euclidean algebras,
since each algebra more costs builds and runs. After `--thorough`, as `evaluate all
--thorough`, they measure rga3d and cga4d as well, as the Architect chose.

**The spread comes from the evaluations themselves.** An evaluation that changes no library function
moves no count, so the range of its time ratios is the range of the machine. The pages state
the spread beside the figures it qualifies. They compute it from the committed evaluations
each time they build, so the record states no figure of it.

Alternation does not cancel all drift of a shared machine, so the time of one evaluation is
weak evidence alone. Counts are exact, and carry the verdicts.

`proposals/02-typed-multivectors/prototype.nim` holds its laws against the change of
`cayley-derivation` at rga3d, rga4d and cga5d.

Verified by `test_rga4d.nim` and the other stubs, suites `Internal: Markdown`, `Internal: Changes`,
`Internal: Proposals`, `Internal: Evaluations` and `Internal: Cells`. They cover parse, quote and
digest rules, and claim kinds. They cover proposal numbers taken twice or skipped, and the status
that freezes a proposal. They also cover pairing of runs, NaN shares, the success line of the
compiler, and the table serialiser at pin. They cover the algebras that an evaluation measures, with
the flag and without it. A digest moves with edits, and never with prose.

## Notes

`marginalia/notes.md` holds the notes on library source. Each note quotes the lines it is
about, and the page computes the line number at build from where the quote stands at pin. A
quote that no longer occurs once is a finding.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Notes`: parse, location at pin,
and a stale anchor.

## Pages

**Every page is one shell and one body.** The shell is `pages/shell.html`, committed and
hand-written. The body is rendered in Nim from committed files, so a page says only what those
files say. The faces are the six that `rga_visualiser` embeds, fetched through
`koch fetch-assets` and inlined as base64. Interaction is CSS: tabs, filters and sort are
inputs that `:has()` rules read.

**Each Noto face ships whole, as the TrueType of its own release** (Article X.8, as the
Architect ruled it on 2026-10-03). Commit Mono is no Noto, so it ships as the Latin `woff2` of
`@fontsource`. All six faces are under the SIL Open Font License 1.1. The cost is weight: each
page is 4.3 to 5.2 MiB, against 0.9 to 1.8 MiB with the subsets, by `ls -l build` on
2026-10-04.

**Each stack holds every face of the sans stack before any family of the system.** So a
character that the first faces of a stack lack falls to a face that the page ships. Noto Sans
draws `ₙ`, `ₖ` and `ᵀ` in code, which no face of the mono stack holds, at a width that is not
one column. Verified by `test_rga4d.nim`, which reads the stacks of the shell. A render in
Chromium 141 on 2026-10-04 asked DevTools, through `CSS.getPlatformFontsForNode`, which fonts
drew each text element of each page. With the subsets, faces of the system drew 106 glyphs on
two pages, and with the whole faces and closed stacks they drew none.

The one script is the search box of the docket. It is Nim, `pages/find.nim`, which the driver
compiles to JavaScript under the flags of every build. The compiler is pinned, so the script
and the digest of each page still follow those files.

**A proposal can carry a figure.** A paragraph of one image alone, as
`![Derivation map.](../../pages/derivation-map.svg)`, embeds the SVG that it names. The SVG lives
under `pages/`, since the layout admits hand-written markup there alone. Its colours are shell
tokens with fallbacks, so it follows the theme of the page and still reads alone. A figure that
names no file is a finding of `drive`. Rejected: a figure kept outside the repository, because no
page is built from it.

**Marks render as the faces allow.** The left complement is written 𝐜̱, with U+0331. Noto Sans
Math holds each bold maths letter and both macrons, so it draws 𝐜̱, 𝐜̄ and 𝐞̄
whole. It puts each mark beside the letter, and not under or over it, as the same render
showed. The Architect ruled on 2026-10-04 to keep the marks as Noto Sans Math places them,
rather than draw them by markup. In code, ★ comes from the math face as ☆ does, because the mono
face draws ★ smaller.

The cause is in the face. In Noto Sans Math 2.539, the 52 letters of the bold block, U+1D400 to
U+1D433, carry a `center` anchor alone. A mark such as U+0338 uses that anchor. A top or bottom
mark finds no anchor on them, so HarfBuzz leaves it at the pen, after the letter. The italic, bold
italic, sans-serif bold and monospace blocks carry `top`, `center` and `bottom`, and so does the
Latin `c`.

Verified on 2026-10-04 by fontTools, which read the GPOS table of the face in the store.
HarfBuzz shapes `uni0331` with an offset of 0 after `u1D41C`, and of −373 after `c`. The glyph
source of release 2.539 gives `cbold-math` the `center` anchor alone. Tag 3.000 holds
sources alone, with no bold letter source, and `notofonts.github.io` publishes 2.539 as its last
build. So whether a later release mends the anchors is unverified.

**Every edit renders closed**, as the Architect asked. Its summary names the file and line at
pin, and how many lines the edit replaces. It lists the signatures of the routines, tests and
suites that the edit defines, with no body, pragma or comment. An edit that defines none names
the routine that it sits in at pin, and an edit at top level names none. So a reader sees what
changes before the edit opens.

**The docket draws each measure as one bar off its lower bound**, as the Architect chose.
Multiplies, bytes moved and time each give one bar from ×1 to the library over the lower
bound that the row is measured against. A typed row is measured against its reference, and a
tick on its count bars marks the multivector lower bound. A general row counts against the
multivector lower bound, and times against its dense form.

The time bar ends at the median of the run ratios, and each run is one tick on it, as the
Architect chose. So one slow run shows as one tick apart, and not as a wide span.
Every bar on the page shares one log axis in whole powers of two, so a length reads as a
factor. A count whose reference spends none has no ratio. It reads as its excess, such as
`8 over 0`, and its bar runs to the end of the axis.

Rejected: three bars of absolute values for each measure. The eye then compares three lengths
to read one factor, and a time carries no place for its variance.

**The docket sorts and filters through dropdowns**, as the Architect asked. Sort ranks rows by
how far bytes moved, multiplies or time stand over what they are measured against. It also
ranks them by the spread of their run ratios, by divides, by error checks, or in docket order.
A row with no figure for a key sorts last.

Show keeps the rows over their lower bound on any measure, or on one measure. It also keeps
the rows at that bound on both counts, the chains, and the rows with error checks, zero fills or
NaN results. A time is over when its ratio is more than `TOLERANCE`, the band that `gaps.md`
uses. Operation keeps the rows of one operation, and Operand keeps the typed rows over
one operand kind. A typed id splits into its operation and its kinds at the longest kind name,
so `bulk_flat_round_point` is `bulk_flat` over `round_point`.

One list in `docket.nim` spells each option and the rule that reads it, so the two cannot
drift apart. An option of Operation or Operand hides on an algebra with no row for it. A CSS
counter above the rows says how many show. A search box finds rows by words, as the Architect
chose at the cost of a script. A row shows while its name, identifier, symbol, operation,
expression and operand kinds hold every word typed.

That rule is `isFound` in `pages/search.nim`, which the suites run natively and the script runs
in the browser. Rejected: JavaScript in a Nim string, which no compiler reads. Rejected:
TypeScript, which brings Node and a lockfile for eight lines, where Article II.9 keeps the
source in Nim.

**A publication holds each published page to its build.** `pages/published.json` maps each
page to its URL and to the digest of the page as built when it was published. `drive` builds
every page again, and any page whose digest differs is a finding. `README.md` must name the URL
of every publication, so the two copies of a URL cannot drift apart. Rejected: a page written by
hand, or by a script outside this project, because nothing held it to the files.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Pages`. Assembly fills every
token. It covers the spread until evaluations give enough ratios, and the chip that names removed
NaN results.

The same suite covers the lower bound each docket row is measured against, and a general row timed
against its dense form. It covers the median of run ratios with one tick for each run, and a
reference that spends none. It covers the rule that reads each dropdown option, the classes of each
row, and the split of a typed id. It covers the words each row is found by, and the shell rule that
hides a row not found.

Suite `Internal: Figures` covers the path a figure resolves, the SVG a page embeds, and every rule
on the map. Suite `Internal: Edits` covers the closed edit, the signatures it defines or sits in,
and a header that closes at its own indent.

## Library head

**The verb `head` holds the pin to library head.** It reads the head of the library repository
with `git ls-remote`, and compares the tree of the library directory at head with its tree at
pin. A commit elsewhere in the repository changes nothing measured, so the check compares trees,
not commits. Where the trees agree, it exits 0. Where they do not, it prints its finding and
exits 1.

**`drive` holds every measurement and file to the pin.** Each baseline and each evaluation must be
taken at the pin. Each evaluation must carry the digest of its edits as they are now. Each change
and proposal must apply at pin, and each note must find its quote.

**`drive` holds the checkout to the pin.** Any edit under the library directory of the
checkout is a finding. The checkout is under `dependencies/`, which git ignores, so a tool
that runs over this project reaches it too. A quote would then match text that the pin does
not hold.

**A read of the library refuses a checkout that holds no Nim file.** A page quotes each edit
with its lines and the signatures around it. An empty read would render each edit without them,
and nothing would fail. The refusal names `nim r koch fetch-deps`, which restores the checkout from
its lock. Verified by `test_rga4d.nim`, with a missing checkout and an empty one.

**No merge waits on `head`.** Its verdict moves with the library and not with this project.
So `drive` and the suites read no head, and they give the same verdict on the same code
(`CONTRIBUTOR.md`, Tests are paramount). The `head` workflow runs the verb daily, and keeps one
issue open for this project while the pin lags. Following head stays the choice of this
project, and the README lists the steps. Cost: the pages can show a library one day behind its
head.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Head`: tree against commit,
stamps, digests of edits, the publications and the README. Suite `Internal: Driver` holds `drive`
to read no head, and the verb `head` to report what `checkHead` finds.

## Dependencies

**The PGA library is a pinned dependency, and never a copy.** It lives in [replications],
which carries no nimble file and holds the library three directories inside it. So the
requirement in `pga_benchmark.nimble` names the repository by URL and commit. `atlas.lock`
records the resolved commit `d9be8aefc193f6ee0a7a3fead25cd4fe1d8f09cf`, and `nim.cfg` names
the subdirectory that Atlas restores it to.

That commit is the head of the library on 2026-10-03, as the standing instruction of the
Architect asks. Both projects are under the Prosperity Public License 3.0.0. Rejected: a copy
of the library in this tree, which Article XI.3 forbids.

**The compiler is pinned by commit**, `27763495bcfe265507ca98aedc1c7064bf1e0e4d`, which is
the same pin that `rga_visualiser` carries. The library spells seven operators with
characters that no Nim release lexes. One cached build therefore serves both projects. Atlas
writes `"objects": {}` for a repository without a nimble file, so the resolved commit is
patched into `atlas.lock` by hand. The stored copies in the lock of the nimble file and of
`nim.cfg` are kept byte-identical to the committed files, which the static pass checks.

**The Terathon Math Library was read, and not used.** The C++ library of Eric Lengyel at
[terathon] is MIT licensed, copyright (c) 1999-2024 Eric Lengyel. `TSRigid3D.h`,
`TSMotor3D.h/.cpp`, `TSFlector3D.h/.cpp` and `TSConformal3D.h/.cpp` were read to cross-check
the forms and counts derived here. No line of it is in this project. The reference is Nim,
written from the book and the library, so no notice is required, and this paragraph is
attribution rather than licence.

## Figures

**Every figure at the pin lives in a file that a verb writes, and the record copies none.** The
static counts are `baseline/static_<algebra>.json`, from `baseline`. They are exact for this
compiler commit, with loop trips weighted. The runtime medians are
`baseline/runtime_<algebra>.json`, from `bench`: five alternating runs of 40 rounds over 1024
objects, in nanoseconds for each object. Each file names its date, machine, commits and flags
under `taken`, and at the pin they are from 2026-10-03 on `linux amd64, 4 cores`.

`gaps.md` and the docket show each gap of the pin from those files, and `show` prints the C and
the machine code of one function. The figures of each proposal before and after its edits are
in `evaluations/<name>.json`, and its page shows them. Allocation is zero on every measurand in
every implementation, with the gauge live, as the runtime baselines record. Scaling across
dimensions is unmeasured at the pin, and `sweep` takes it by hand.

**Generated operators write each zero element, and hand-written functions leave theirs to the
default fill.** A generated operator writes every element as a straight statement, zeros included,
because generation lowers a Cayley table and nobody writes the zeros by hand. At the pin, what the
default fill would cost the generated operators is unmeasured. A hand-written function, such as a
norm, writes no zero. The Architect decided this, because the library is about PGA and not about
micro-optimisation.

Each function that a Cayley table can express moves to generation, and so gets its zeros
unrolled at no cost. At the pin `d9be8ae` the library works this way, and its attitude and
carrier are generated. Its hand-written `+` and `-` carry `noinit` and write each slot, so they
fill nothing. The cost that stays is what the hand-written norms pay.

The cost is measured at `3121342` on `linux amd64, 4 cores`, an Intel Xeon at 2.10 GHz, on
2026-10-03. The harness calls each function through a volatile procedure pointer. So the body of
each function compiles alone, and writes to memory that it cannot see. Each figure comes from two
passes, and each pass is the median of nine runs of 41 rounds over 1024 objects. Nine in ten
functions that did not change moved ×0.86 to ×1.02. The pin `d9be8ae` changes no norm and no
generated operator, as its static baselines show, so these figures stand for it.

For the norms, a cell gives nanoseconds with the default fill, then with straight stores that
write the zeros first. The cell is the lower of the two passes:

| Norm | rga2d | rga3d | rga4d | rga5d | cga4d | cga5d | cga6d |
|------|-------|-------|-------|-------|-------|-------|-------|
| `|∙` | 2.8 / 2.8 | 4.4 / 4.4 | 15 / 7.3 | 17 / 11 | 16 / 9.6 | 21 / 17 | 45 / 31 |
| `|■` |  |  |  |  | 16 / 9.4 | 21 / 16 | 45 / 32 |
| `|∘` | 2.8 / 2.8 | 4.5 / 4.6 | 15 / 8.1 | 17 / 11 | 17 / 6.3 | 22 / 13 | 51 / 33 |
| `|□` |  |  |  |  | 16 / 6.3 | 22 / 13 | 51 / 33 |
| `|` | 4.2 / 4.2 | 5.0 / 5.0 | 28 / 16 | 32 / 20 | 31 / 19 | 42 / 35 | 94 / 83 |

The fill loses from four dimensions up, where a result holds 128 bytes or more. In the harness at
the pin, gcc emits the fill of `|∙` at rga4d as `rep stos`, under its generic tuning for x86-64.
Article VII holds the rule that these measurements set (VII.3, VII.8 and VII.9).

At the pin `^∙` and `^∘` take the root of `|∙²` or `|∘²`, and do not build the norm. Runs of the
same method on the same machine on 2026-10-03 time that form against a variant of the pin that
builds the norm. It takes ×0.36 to ×0.76 of the time from three dimensions up, and ×0.94 to ×0.97
at rga2d. Nine in ten unchanged functions in those runs moved ×0.99 to ×1.02.

## Known limitations

- Evaluations time rga4d and cga5d unless `--thorough` asks for rga3d and cga4d too. Of the
  evaluations committed now, `multivector-align` alone measures all four.
- The `build` claim reads the peak memory and seconds that the compiler reports of itself, for
  the library alone. It compares two builds on one machine, and is no measurement of the
  machine.

- Timings come from a shared cloud container, and vary by tens of percent between runs. The
  tolerance absorbs some of that, and the rest is why timing never guards.
- Movement is modelled from the bytes that the code names, and never measured as cache
  traffic.
- The inspector reads text patterns of this compiler commit. Another commit could spell the
  same C differently. The suite that holds the reader to the nimcache of the test binary is
  what would say so. A loop whose bound is a variable counts once.
- 32-bit floats and SIMD forms are unmeasured, and the SSE paths of Terathon were not
  compared.
- `sweep` is hand-run only, and no sweep has run at the pin.
- A change to the bench outside a measurand moves the time of that measurand. Ten alternating
  runs with and without `noinit`, on `linux amd64, 4 cores` on 2026-10-02, keep the median ratio of
  each implementation at ×0.99 to ×1.00. Single measurands move steadily from ×0.80 (`scale`)
  to ×1.16 (`wedge_anti`). Code layout is the likely cause. So a time ratio inside about ×0.6
  to ×1.4 between two builds is weak evidence of a change.
- Two forms that spend the same arithmetic can differ in time. At rga4d `+` and its dense form
  compile to the same 16 loads, 8 adds and 8 stores. The loop of the library interleaves each
  load, add and store, and the dense form groups its loads first. Of the 66 rows that spend the
  same counts in both, the median reads ×1.00, and light rows stray to ×0.65 at cga5d. Why order
  moves time is unmeasured, since this container offers no hardware counters.

## Open questions

- Whether the library takes P03, `partner-sign`, and with it a partner that does not check the
  grade of its operand. At cga5d, P03 on P01 spends the chain bound of 324 multiplies, three
  zero fills and two error checks. P01 alone spends 437, 104 and 268. Both are the counts
  after the edits in `evaluations/partner-sign.json` and `evaluations/cayley-derivation.json`.
- Whether the library takes P04, `exact-kinds`, so that a product returns a kind of exactly
  the bases it reaches. At rga4d 16 measurands stand above the byte bound only because they
  write a whole multivector for one slot, and at cga5d 12 do. Each is a dot, an antidot or a
  squared norm, and under P04 each writes 8 bytes.
- Whether the library takes P05, `multivector-align`, and whether P02 and P04 take its rule for
  kinds. A caller that holds multivectors in a `seq` times `-m` at ×0.37 to ×0.84 of the pin. It
  times `m + n` at ×0.78 to ×0.84, at no cost in size. A kind that the alignment pads runs ×1.18 to
  ×4.90 slower, so the rule aligns a kind of an even count of floats alone. The figures are in
  `proposals/05-multivector-align/proposal.md`.

[replications]: https://gitlab.com/mraxilus/replications
[terathon]: https://github.com/EricLengyel/Terathon-Math-Library
