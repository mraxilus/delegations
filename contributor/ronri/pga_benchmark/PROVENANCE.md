# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-29 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 50ecd726ec1a5108 |
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
`Antiscalar`, so that widening puts it in the antiscalar coefficient where the library writes it.

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
motor transforms factor the expansion to 14 multiplies, where it spends 30. The partners are
factored by hand, 15 multiplies for a dipole where the expansion spends 36. The script stays out of
the tree, because no checker reads its kind of file. The law suites hold every form to the library
on the pools instead.

Where the sign conventions of the library differ from Terathon's, the library's were adopted,
because the library is what is measured. The bulk and weight duals of points and planes carry
the opposite sign. The conformal antidot is the negated dot. The cocarrier of a circle reads
`LineFlat(v: -g.xyz, m: -c.v)`. The `Partner(Circle)` scalar of Terathon carries a sign typo,
and the form here is `f = gw² - v·v - g·m`, which the law suite confirms against the library.

**A typed point unitizes by the size of its weight, as the book does.** The weight norm of a
point is |w|, so the sign of w stays, as `^` of the library keeps it. Lengyel's code divides by the
signed w, so w = 1, and the Architect chose the rule of the book on 2026-10-10. The form spends
one absolute value and one multiply more than the code.

Rejected: the signed w of the code. `^` takes any multivector, where only the norm is defined, and
the sign needs the type of the object. `marginalia/notes.md` gives what the code saves, under
"Unitization keeps the sign of the weight".

Verified by `test_rga4d.nim` and `test_rga3d.nim`, suite `Chapter 2`: each point of the pool,
with its weight negated, unitizes as the library unitizes it. The pools draw w near 1, so without
the negation no measurand sees the sign.

Every form is `{.inline.}`, so it lands in the same nimcache as the operators of the library, and
the same reader counts it.

**Each form that builds an object reads its operands into scalars, and writes its result from
them alone.** A scalar takes the notation of the header of its module (III.5). So `pˣ` is the x of
a point `p`, and `lᵛˣ` is the x of the direction of a line `l`. A zero is `0.0` in each component,
and a copy goes component by component. In C, a `Vector3()` default zero-fills through
`nimZeroMem`, and a whole-object copy calls the `=dup` hook that the compiler makes for `Vector3`.
Either cost would charge the reference for work that hand-written code does not do.

The result arrives by pointer, and Nim builds C with `-fno-strict-aliasing`. So gcc must take the
result as a possible overlap of an operand. Then a form that writes one field before it reads the
next gets no vector instruction. With each read first, `reverse(Line)` at rga4d takes 14
instructions under Nim 2.4.0, and 22 where each component is read just before its write. Measured
on 2026-10-28 by `objdump` of a `noipa` wrapper of each form, built with the flags of the machine
build.

Rejected: a vector template that holds a `let`. Nim 2.4.0 zero-fills an object that `let` binds
to the result of such a template. The forms that used them held 52 fills at rga3d and rga4d.
Rejected too: `{.noalias.}` on each operand, which gives the same instructions as the scalars. It
is a promise that the compiler never checks, and it keeps the copies of the templates in C.

Three builds of the bench timed zeros and copies at rga4d and cga5d, five alternating runs each.
They ran on `linux amd64, 4 cores` on 2026-10-03 at `3121342`. The builds spell zeros and copies by
component, through `Vector3()`, and as a whole copy. At rga4d `bulk_line` runs 2.61 ns by component,
23.49 ns with `Vector3()` and 4.19 ns with the copy. The other three line rows with a default run
22.5 to 23.5 ns, and `attitude_plane` runs 3.35 ns against 2.14 ns.

Rows that use neither move ×0.65 to ×1.29, so the copy in `transform_line_motor`, ×1.04, does not
show. At cga5d a default adds 18 to 30 ns to eight rows, and a copy adds 1.6 to 4.4 ns to seven.
Why a default costs 20 ns in a line row and 1.2 ns in `attitude_plane` is not isolated.

Unitize forms take one reciprocal and multiply, as Terathon does, where the library divides each
component. The divide column shows both. A form selects the factor 1 at zero weight, in place of
an early `return`. Nim 2.4.0 fills the whole result of a function that returns early, and gcc
keeps that fill, since the result can alias the operand.

**Each motor transform spells the antisandwich 𝐐 ⟇ 𝐱 ⟇ 𝐐̰ exactly, for every motor.** In 3D the
rotation is the matrix of the quaternion (Qᵛ, Qᵛʷ), scaled by its squared norm s. The translation
is 𝐭 = 2(Qᵛʷ Qᵐ − Qᵐʷ Qᵛ + Qᵛ × Qᵐ). The weight of a point and the position of a plane take s.
The moment of a line gains 2(Qᵐʷ 𝐤 + kʷ Qᵐ + Qᵐ × 𝐤), from the quaternion k = lᵛ (Qᵛʷ, −Qᵛ).

In 2D the cosine is (Qʷ Qʷ − Qᶻ Qᶻ), and the weight takes the factor (Qᶻ Qᶻ + Qʷ Qʷ). The Architect
asked on 2026-10-28 for the form most accurate to each operation (D2 of #772). That holds even
where the form changes.

The motors of the pools are unit only to within rounding. So a form that takes s as 1 errs by
as much as it rounds. The table holds each form against the antisandwich in exact rational
arithmetic, on motors drawn as the pools draw them. Each cell reads the unit form, then the
exact one:

| Transform | Multiplies | Worst error | Root mean square error |
|-----------|------------|-------------|------------------------|
| 3D point | 25 → 35 | 1.9e-15 → 1.3e-15 | 1.79e-16 → 1.45e-16 |
| 3D line | 57 → 52 | 4.4e-15 → 2.0e-15 | 2.53e-16 → 1.69e-16 |
| 3D plane | 36 → 35 | 4.3e-15 → 2.1e-15 | 2.28e-16 → 1.47e-16 |
| 2D point | 15 → 14 | 1.71e-15 → 1.71e-15 | 1.68e-16 → 1.60e-16 |
| 2D line | 15 → 14 | 2.37e-15 → 2.37e-15 | 1.62e-16 → 1.56e-16 |

Measured on 2026-10-28 by a script in Python 3 with `fractions`. It evaluates the antisandwich
from the definitions of the book, on 6 000 samples at rga4d and 4 000 at rga3d, seed 772.
The same script holds each exact form equal to the antisandwich on 300 arbitrary rational motors,
so the form errs by rounding alone. The script stays out of the tree, as the expansion does.
Verified by `test_rga4d.nim` and `test_rga3d.nim`, suite `Reference: Motor of any norm`: each
transform equals the library at each motor of the pool, scaled by 2.

Rejected: a matrix that takes the motor as unit, 45 multiplies for a line, which keeps the error
of the unit form. Rejected too: the exact form through the quaternion, as the unit form spells it.
Its root mean square error is higher for each transform. It spends 30 multiplies for a point
against 35, 64 for a line against 52, and 38 for a plane against 35.

**No reference function calls another.** Under `--panics:off`, each call to a Nim function
fills its result with zeros and branches on the error flag after it. Hand-written code spends
neither. So each form spells every component itself, and a form that two functions share is
spelled in each. A spelled form carries the terms of the form it repeats, so their
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

Suite `Internal: Inspector` reads the nimcache of the test binary itself. It holds the doc of
every reference function to the multiplies, adds and divides that its C spends. It holds every
reference function to no zero fill, no whole copy and no error check. The count it reads must reach
`FLOOR_FUNCTIONS_REFERENCE`, which is 73 at rga4d, 84 at cga5d, 50 at rga3d and 66 at cga4d.

The movement model reads the size of a typed stem from the module of the function that reads
it. The 2D and 3D references share type names at other sizes: a 2D point is 24 bytes, and a 3D
one 32. Suite `Internal: Inspector` holds both sizes.

## Widening and pools

A widen puts each typed object into the dense multivector at the indexes of its bases. A narrow
reads it back, and asserts under `-d:testing` that every other coefficient is zero. Pools are filled
once from `randomize(0)`: dense multivectors of every grade, typed objects in general position,
lines and planes joined from points, and motors unitized. Every typed pool has a widened
image, so the two implementations read equivalent operands.

Verified by `test_rga4d.nim` and the other stubs. Suite `Chapter 2` and the `Wiki` suites run
through the widening, and suite `Internal: Measurements` runs every measurand over the pools.

## Measurements

`defineCatalogue` turns the catalogue into one timed loop for each measurand of each
implementation. Operands are template aliases into pool elements, and never copies, so the loop
moves only the traffic of the operation itself. Every result is folded into one sink after
the timing, so nothing is dead. The share of results that carry NaN is counted. The radius norm
of the library returns NaN where 𝐦 ∘ 𝐦 is negative, and that is measured rather than stated.

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

**Result elements start uninitialised (`noinit`).** A fill of zeros that the compiler sees lets it
delete each store of zero that repeats the fill. The bench then times fewer stores than a caller
pays.

Alone, `∙` at rga4d ran at 4.4 ns into elements filled once with zeros, and at 7.0 ns into elements
left uninitialised. In the bench at `3121342`, the machine code holds 245 stores of zero
with or without the fill. So there a fill gives no measurand a discount, and the `noinit`
keeps it so as the catalogue grows. Both figures are from `linux amd64, 4 cores` on 2026-10-02.

**A result of three floats or fewer is bound before it is stored.** Nim returns such a result by
value. Stored straight into its element, it passes under Nim 2.3.1 through a temporary that the
call site fills with zeros. In a large function, gcc keeps that fill as a call to an out-of-line
`rep stosq`. A caller of normal size pays nothing, because there the fill is two stores that gcc
deletes. Nim 2.4.0 stores such a result in place, so the binding holds the loop free of that fill
under either.

Of the 2D reference rows, 30 return such a result, and of the 3D ones none. Compiled unbound at
rga3d on 2026-10-28, Nim 2.3.1 sends 26 of 144 reference calls through a filled temporary, and Nim
2.4.0 sends none.

Two sessions of five alternating runs on `linux amd64, 4 cores` on 2026-10-03 time the 2D
references, one with the fill and one bound first. With the fill, those 26 rows at rga3d and 4
at cga4d take 12.1 to 15.5 ns. Bound first, they take 0.8 to 5.0 ns. Within each session,
library over reference for `complement_left_line` reads ×0.20 with the fill and ×2.98 bound
first. The other reference rows move ×0.42 to ×1.70 between the sessions.

Neither session is committed, and both ran under Nim 2.3.1. Bound first or not, the C at rga4d and
cga5d is the same byte for byte. Suite `Internal: Inspector` holds the loop to no temporary filled
with zeros.

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

**The runtime baselines are from 2026-10-28 at all four algebras**, five runs each on `linux
amd64, 4 cores`. They ran at the pin `3d9696e` under Nim 2.4.0, with nothing else on the machine.
Each algebra keeps the take whose median paired spread is smaller, as the Architect ruled on
2026-10-19 (D5). A take under another compiler times other C, so this take is the only one at the
pin.

The bench of 2026-10-01, run at `3121342` on 2026-10-02 in turn with the baselines of that day,
gives the drift between days. At rga4d its library runs ×1.19 to
×1.22 of its own times of 2026-10-01. Its reference runs ×1.26 to ×1.27, and its dense forms ×1.00
to ×1.01. The bench of 2026-10-02 runs ×0.99 to ×1.01 of it in the same runs.

So the machine moves between days, and not by one factor for each implementation. Times
taken at different hours never compare, and ratios within one run do.

Within these baselines, the least and greatest run ratios of the median measurand are ×1.03
to ×1.13 apart at each algebra. The widest measurand spreads ×1.87, as `complement_left_point` at
rga3d does. Its library takes 2.41 to 3.55 ns across the five runs, and its reference 0.63 to
1.74 ns, both slowest in the fourth run. Under Nim 2.3.1, the takes of 2026-10-03 and 2026-10-19
spread ×1.10 to ×1.12 and ×1.15 to ×1.19, so this figure moves between takes.

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

It keys every function by symbol and by parameter type stems. A stem drops the hash that the
compiler puts in the name of a type, since that hash follows the path of its module. So a set of
an enum reads as `set[Basis]`, and a key holds on every machine. It then counts what the C
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
`baseline/runtime_<algebra>.json` records the runtime ones. `baseline/machine_<algebra>.json`
records the machine measurements, as the next section says. All are schema 1, with a header
that names algebra, compiler commit, library commit, flags, machine and date.

`guard` compares a fresh inspection against the baseline. Any gated count or bytes moved that
grew is a finding, rendered as `path:0: message; got value`. Any shrink is a notice. A document
of another algebra, compiler or set of flags is refused rather than compared.

Date and machine are ignored, because static measurements owe them nothing. `drive` is the
verb that koch and CI run: inspect every algebra, guard, and hold the committed `gaps.md` and
docket to regeneration. It is deterministic because it times nothing.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Guard`. Equal documents pass
silently. One grown count is one finding, which names function, metric and both values. A shrink is
an improvement only, and bytes moved are gated. A function absent in either document is a finding,
and another build or schema is refused. A lower bound that moves either way, or that is absent now,
is a finding.

## Machine measurements

`inspect` also counts the work of the machine for each measurand, as Article VII.10 asks. The
entry `machine` puts the library expression of each measurand in a wrapper of its own. It calls
each wrapper once, on pools of two objects that seed 0 fills. So a binary measurand reads two
objects, and never one object twice.

Each wrapper is `noinit`, and carries the gcc attributes `noinline` and `noipa`. So the driver
cannot inline, clone, fold or drop a call, and the wrapper knows nothing of its operands (VII.9).
The library inlines its operators into each caller, so a count of the bench names no operator.
The count of a wrapper does.

Every wrapper shares one C file. gcc inlines a function that the file calls once, and it stops
inlining and cloning where the file has grown past its limit. Either makes the count of one
wrapper move with the others. So `inspect` builds the entry with
`-fno-inline-functions-called-once`, and sets `large-unit-insns` and `ipa-cp-unit-growth` past
any file. Then what gcc inlines into a wrapper depends on that wrapper alone.

Each wrapper has a copy, later in the same C file, which the driver calls on the same operands
after every wrapper. `guard` makes a finding of a wrapper whose copy reads other counts. That
finding holds the flags: under Nim 2.3.1 without them, one copy reads apart at rga4d and one at
cga5d.

- Rejected: a twin of the same C over other operands, such as `wedge` beside `wedge_point_point`.
  `⊛` branches on the kind of its operand, so `partner` and `partner_dipole` read apart with no
  coupling.

Valgrind's `lackey` traces the binary. It lists each instruction executed, and each access to
memory with its bytes. The trace names no function. So `machine` writes the runtime entry of
each wrapper and of the driver, and `nm -S` gives the extent of the driver.

The work of a wrapper opens at its entry, and closes at the first instruction back in the
driver. It holds the return and each function that the wrapper calls, but not the call itself.
That is the inclusive cost of callgrind.

`baseline/machine_<algebra>.json` records three counts and two flags for each measurand:

- the instructions executed, where each trip of a `rep` instruction is one;
- the bytes read and the bytes written, where an access that reads and writes the same bytes
  counts in both;
- whether any instruction ran outside the text of the binary, in a shared object;
- whether the copy of the wrapper read other counts.

The header names the Nim commit, the flags, the C compiler with its version, and the tracer
(VII.11). `guard` refuses a baseline whose header names another build. A grown count is a
finding, and a shrink is a notice. Each message names the static count of the library function
of the measurand beside it, because that count names the line of C (VII.10). A measurand that
composes several calls names no library function, and its message says so.

**The band of each count is zero, and this is its cause (VII.12).** Valgrind 3.22 ran the four
algebras under Nim 2.3.1 on `linux amd64, 4 cores` on 2026-10-21, at 451 measurands:

- Two runs of one binary gave the same counts for each measurand.
- A run with `GLIBC_TUNABLES=glibc.cpu.hwcaps=-AVX2,-AVX512F,-ERMS,-AVX_Fast_Unaligned_Load,-FMA`
  gave the same counts. Under it the C library reads the processor of valgrind as x86-64-v2,
  and not v3, and the trace outside the wrappers changed.
- Seeds 1 and 7 gave the counts of seed 0 for each measurand. So the values of the operands
  move no branch.
- No wrapper reaches a shared object. So no counted code runs code that the processor selects.
- Two builds that each hold every other wrapper gave the counts of the whole build. So did the
  build with a copy of each wrapper, which doubles the C file. Without the three flags of gcc, 5
  counts of 111 moved at rga4d, and 10 of 135 at cga5d. Then `wedge` and
  `wedge_round_point_dipole` at cga5d, of the same C, read 871 and 774 instructions.

**The gate pins a fault that grows a count, and the record holds its reading beside unchanged
code** (`CONTRIBUTOR.md`, Tests are paramount). The fault is `+` of the library without `inline`.
Its C body stays the same, so no static count moves. Under Nim 2.4.0 only the instructions of
`add` grow, by 2 at each algebra, and its bytes stay. In each cell below, the first figure is the
slowest and the typical reading of unchanged code, which are equal. The second figure is the
reading of the fault:

| Algebra | Instructions | Bytes read | Bytes written |
| --- | --- | --- | --- |
| rga3d | 25, fault 27 | 136, fault 136 | 64, fault 64 |
| rga4d | 42, fault 44 | 264, fault 264 | 128, fault 128 |
| cga4d | 42, fault 44 | 264, fault 264 | 128, fault 128 |
| cga5d | 72, fault 74 | 520, fault 520 | 256, fault 256 |

The readings of unchanged code are 20 runs of `inspect` and `guard` under Nim 2.4.0 on `linux
amd64, 4 cores`, on 2026-10-28 and 2026-10-29. In each run, each count of each measurand equalled
its baseline. `guard` gave no finding and no notice in any run. The fault was read on a copy of the
library at the pin, with `inline` taken from `+` in `pga/multivectors.nim`.

The runner of CI read the same under Nim 2.3.1. Run 1340 of `check`, on 2026-10-22, gave no finding
and no notice, under the same gcc package. Runs 1296, 1298 and 1306, on 2026-10-21, gave no
finding. So the spread of unchanged code is zero, and the fault reads beyond it at the instructions
of `add`.

A wrapper that reaches a shared object is a finding. Its band would need readings of the
runner and of a delegate, and no record holds them.

- Cost: the counted build is not the build that ships. A shipped caller inlines the operator,
  and the driver calls the wrapper. The flags lift limits that gcc keeps for a shipped build. So
  the counts are evidence for this build alone (VII.11).
- Cost: the wrapper returns its expression as `result`, so the count holds what that call site
  pays. Under Nim 2.4.0 the operator writes straight into that result, with no temporary. Nim
  builds C with `-fno-strict-aliasing`, so gcc must take that result as a possible overlap of the
  operand. Then a map that writes one element before it reads the next gets no vector
  instruction, as `reverse` at rga4d shows in 45 instructions. The temporary of Nim 2.3.1 lets gcc
  vectorise it in 27, as does `restrict` on both pointers of its C body. Read with gcc 13.3.0 on
  2026-10-28.
- Cost: the counts are for one pair of operands. A path that another operand takes is not
  counted, such as `sqrt` of a negative number, which calls the C library.
- Cost: the C compiler joins the build. A runner image with another gcc package fails `drive`
  until `baseline` is taken again on it.
- Cost: `drive` needs valgrind, and runs the machine build of each algebra under it, about one
  second each.
- Bytes allocated are not counted. Suite `Internal: Allocation` holds that no measurand
  allocates in any implementation.
- Rejected: callgrind, which the table on #665 used. It counts each access, and not its bytes,
  so a load of 16 bytes counts as one, as a load of 8 bytes does.
- Rejected: counts of the bench, since each loop inlines its operator, and no count names it.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Machine`. A fixture trace
holds two wrappers, a callee, a `rep` instruction and a shared object. A trace that ends inside a
wrapper, or that misses one, is refused. The gate refuses another compiler, and reports growth,
shrink, a shared object, a copy that reads apart and an absent measurand. The C of the test
binary declares each wrapper and each copy behind `noipa`, at its own entry, copies after
wrappers.

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
bilinear form landing in one coefficient spends one term for each blade that carries an image.

A norm of one part spends one term for each blade of that part. That is half the blades under
the rigid metric, and a quarter under the conformal metric, since the four parts are of one size.
A unitize spends the norm of one part, then one term for each coefficient. The radius norm squares
the whole antidot, so it spends what a bilinear form spends. Under the rigid metric a part holds the
blades that carry an image, so each norm counts as the bilinear form did.

A product against the dual of its second operand spends what the grade of that operand
allows. A permutation and a product against a one-component constant spend nothing. The
carrier, the cocarrier and the attitude each take that last form, and so spend nothing.

A support, an antisupport, a centre and a container each apply maps to the operand and then
take one product. A map is a signed read, so the product against the mapped operand is one
table, and the cells of that table are the bound. The supports count 54 at four dimensions,
and the centre and the container count 162 at five. Those counts rest on the same assumption
as the primitives, that no coefficient shares a subexpression with another.

The library composes some other operations from several operators. A norm reads two coefficients.
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
dimensions. At five dimensions a norm of one part is held to 8, the radius norm to 32 and a
unitize to 40.

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
since that function writes every coefficient and fills nothing. A chain fills its
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
arithmetic and movement, and never time. It assumes that no result coefficient shares a
subexpression with another, which holds for these products and would not hold where
factoring helps.

Cost: a chain bound sums the steps of the library's own definition, so it is an estimate
rather than a proved minimum. The record marks every such bound, and `gaps.md` names the
steps.

## Dense form

**A general row is timed against its dense form**, as the Architect chose. A general row has
no reference, so nothing measured stood for what a dense multivector could spend. The dense
form is that measure. It assigns each coefficient once as the sum of its terms, with no fill, no
intermediate multivector and no call.

`dense.nim` generates one dense form for each general measurand at build time. It evaluates
the operation symbolically over the library's own Cayley tables. Each coefficient is a polynomial
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
beside the library, five alternating runs at four algebras, on `linux amd64, 4 cores` on
2026-10-19. The median general measurand runs ×1.00 to ×1.01 its dense form at each algebra,
since most library operators are already one generated table. The compound operations are not.
They run ×2.0 to ×5.7 their dense forms, from the container at cga5d to the support at rga4d.

The antigrade selection runs ×2.5 to ×4.6, and the norms ×0.68 to ×1.11. Sum, difference and
negation run ×0.63 to ×1.14, and the unitizes and normalizations ×0.59 to ×0.89. So a dense
form is a measure, and never a lower bound on time.

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

`tools/build.nim` dispatches every verb from `case paramStr(1)`, so koch reads the verbs itself.
The header table of the driver says what each verb does. `sweep` compiles the bench at two to six
dimensions, rigid metric, and prints the medians of the general measurands. It runs each dimension
in turn, five times, as `bench` runs the algebras, and keeps the median of the run medians. It
never runs in CI. It records the medians in `baseline/sweep.json`, stamped as `bench` stamps its
own, and `drive` holds that stamp to the pin.

Rejected: one run of each dimension. The drift of the host then lands on one dimension alone. Two
such sweeps on 2026-10-04 differ by ×1.05 at the median cell, and three sweeps of five runs differ
by ×1.002 to ×1.004 there. Cost: four runs more add about 4 s to a sweep of about 80 s.

`unitized` times six point operations of Lengyel's code, each in the homogeneous form and in the
unitized form that skips each product with w. It takes three layouts: four floats, his three, and
three padded to four, so the saved arithmetic shows apart from the smaller layout. It takes 1024
points in cache and 1,048,576 streamed from memory. Each operation runs behind a call that the
optimiser does not inline, and writes its result in place, as return value optimisation of C++
does.

A null pair times the homogeneous form against itself. The verb takes each pair twice, as
Article VII.9 asks, and records both takes in `baseline/unitized.json`. It never runs in CI.

Rejected: a result returned by value. It passes through a temporary, and its copy reloads the
stores that the callee just made. On `linux amd64, 4 cores` on 2026-10-10, that stall put the
unitized join of two points at ×4.4 in one build and ×1.0 in another. So it timed layout, and not
arithmetic.

Each timed call reads its operands in place. Operands and results lie in two objects, so Nim sees
no alias between them. In one object, Nim copied each operand to a temporary before the call. The
vectorised join then read 16 bytes across two stores of that copy, which no store forwards. On
`linux amd64, 4 cores` on 2026-10-10, that put the unitized join of two points at ×2.2.

The program imports no library code, so its record carries no library commit, and `drive` holds
no stamp of it. Cost: the verb takes 55 s on `linux amd64, 4 cores` on 2026-10-10, and its pools
hold 400 MB.

Verified by `test_rga4d.nim`, suite `Internal: Unitized`. Where the weight is one, each unitized
form equals its homogeneous form, in both layouts. Each row of `baseline/unitized.json` saves the
multiplies that the C of its two forms differs by. Each timed call hands the element of its pool to
the form, and no temporary.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Guard`. A grown total is one
finding. With the fixture path of the suite, it renders so:

```text
baseline/rga4d.json:0: Total `multiplies` of `∧(Multivector,Multivector)` grew; got `90`,
baseline `81`.
```

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Driver`: the dispatch, the usage
string and the header table name the same verbs.

`system` prints the packages of `SYSTEM`, and each one carries its reason there. Git reads the
library head, and `curl` and `coreutils` serve `koch fetch-assets`, which fetches and checks the
font faces. `binutils` gives `show` its `objdump`. `nodejs` runs the type checker of `types` and the
render harness of `drive`. `libbrotli1` serves `koch drive`, which reads the `woff2` of Commit Mono
through it. Suite `Internal: Driver` holds that package to the `woff2` font face that pages ship.

**The driver dispatches, and imports the standard library alone.** `koch check-types` runs
`types` on the compiler of koch, and a type check compiles no project code (`CONTRIBUTOR.md`,
TypeScript and Node). So `tools/build.nim` runs `types` and `system` itself, and hands every other
verb to `tools/verbs.nim`. It runs that program through `nim r` on the compiler on `PATH`, which
koch sets to the pin. So project code compiles on the pin alone.

Before `drive`, the dispatcher type-checks and emits the harness and readies the browser, so
project code compiles once. `nim r` exits 1 for any program that fails, so the dispatcher checks
usage before it hands a verb on. Rejected: one driver that imports project modules, which
`check-types` then compiles on the compiler of koch. On Nim 2.2.12 that driver compiled 22 modules
under `src/`, and the dispatcher compiles none, by `--processing:filenames` on 2026-10-04. Cost: a
second program, which compiles again whenever its sources change.

Suite `Internal: Driver` of `test_rga4d.nim` holds the imports of the dispatcher to `std/`. It
also holds each verb that the dispatcher hands on to one that `tools/verbs.nim` answers.

**Each suite runs in a proc of its own.** The template `suite` of `std/unittest` writes each test
into the function that runs the module. Template `suiteInProc` in `tests/suites.nim` puts each
suite in a proc of its own. That function then holds 0.4 MB of C at rga4d, and the largest suite
about 1 MB.

Rejected: suites at module level. They put every test in one C function of 8.1 MB at rga4d. There
gcc spends 31 s on its file, and the count of its multiplies spends 51 s of the run, measured
2026-10-19.

On `linux amd64, 4 cores` on 2026-10-19, nothing else ran. There the tests of this project took
79 s in place of 221 s. The stub of rga4d took 21 s in place of 82 s, and cga5d 24 s in place of
49 s. The stub of cga4d took 19 s in place of 45 s, and rga3d 14 s in place of 32 s. Both layouts
ran the same tests, by name, at rga4d. A suite that reads no algebra still compiles once for each
of the four stubs.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Inspector`: the function that
runs the module holds under 2 MB of C. The law fails on suites at module level, where that
function holds 8,316,057 bytes.

## Changes, proposals and evaluations

**A change is Markdown, and quotes what it edits.** Each file in `changes/` holds a title,
why, and one section for each edit: a quote of the library at pin, then its replacement. A
whole-file replacement carries the digest of the file it replaces instead. A quote must occur
once at pin. A line number moves with every library commit, and a quote moves only when its
own lines do. So a change that still applies at head still says what it meant.

A section `## Add` holds a new file whole, and applies only where no file stands at its path. A
file that head adds under the same path makes the addition stale, so it is a finding and never an
overwrite. So a proposal that adds a module is a change of the library, and its laws import the
library alone. P04 adds `pga/basis_sets.nim` this way, and P10 adds `pga/scalars.nim`. Rejected: a
prototype beside the library, which P04 was. Each proposal on it then imported the prototype, and
no evaluation built the library that the proposals described.

Verified by `test_rga4d.nim`, suite `Internal: Changes`.

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

**The Architect reads each proposal, and implements it in the library over time,** as the
Architect ruled on 2026-10-04. So no sign-off asks whether the library takes a proposal, and each
one stays `proposed` until the library or the Architect settles it. The Architect states each
rejection, and that proposal is then withdrawn. The Architect may never state an adoption, since
a try to implement can lead elsewhere. So a new commit of the library is where an adoption
shows.

The daily `head` workflow opens an issue for this project when the head moves past the pin. This
project then checks each proposal against that head, and updates it, or sets `implemented` with
that commit.

A program claim names its program relative to its proposal, so a new directory name moves no
digest.

**A program runs against the library with its bases applied.** So `laws.nim` of P09 and of P10
imports `pga` alone, and reaches the products of basis-set types that the change of P04 adds. A
program may still import a program of a base by a path relative to its own directory, and no
proposal does so now. The digest of an evaluation reads the programs of each base first, and then
its own. So a change to a program of a base moves the digest of each proposal on it.

**A suites or program claim may name `defines`**, each `name=value`, and each of its builds
passes them as `-d:`. So a proposal can hold the library at a build option other than its
default, as P06 holds its own suites at 32 bits. The defines are part of the claim, so they move
the digest of the evaluation. The page names each define beside its claim. Rejected: a config
file beside each program. It would reach programs alone, and the digest would not read it.

**Proposals build on each other as a graph without cycles,** as the Architect ruled on
2026-10-04. The Architect decides each proposal on its own. So each one lists in `builds_on` the
proposals whose changes it needs, and an empty list says that it needs none. Rejected: one base
for each proposal. A proposal that needs two others could then not say so.

`dependencies` walks the graph depth first. It gives what an adoption needs first, each one
after its own bases and once only. `dependents` gives what a rejection blocks. A cycle, an
unknown name, a withdrawn base or a `builds_on` that is not a list is a finding. A base that the
library implements drops out, since the library holds its edits.

**Each proposal page states its dependencies, and one page lists every proposal.** The page of a
proposal names what it depends on and what its rejection blocks. Where a proposal is reached through
another, the page names that one too, as `(through P02)`. The proposals tab of the Proposals page
gives each proposal its standing, its claims that hold, its dependencies and what it blocks.

Above the table, the tab draws the undecided proposals as a graph, in columns by depth and in rows
by number. An arrow points from a proposal to one that it builds on, as `builds_on` reads. A decided
proposal needs no choice, so the graph leaves it out, and the table keeps it.

**The proposals tab shows each selected proposal in place,** as the Architect asked. Each box of the
graph and each row of the table is a label of one checkbox for each proposal. A checked proposal
shows whole under the table, as its own page renders it, one heading level down. A close label
deselects one, and the reset of the form clears them all. One rule for each proposal ties its labels
to its checkbox, so the page runs no script. The cost is weight: the page carries each proposal, 4.5
MiB against 4.3 MiB without them, by `ls -l build` on 2026-10-04.

**An evaluation measures a copy of the library at pin.** It copies the checkout, applies the edits
(what the proposal depends on first, in the order of `dependencies`), and measures the copy
against the pin. It runs the suites of the
library, reads the static measurements of every function, and times each measurand. The
binaries of the pin and of the copy run alternately, five times each, so drift of the machine
lands on both.

**An evaluation builds without dense forms**, under `-d:pga_benchmark.has_forms_dense=false`.
A dense form reads tables by their names at pin, and a change may rename them, as
`cayley-derivation` does. The evaluation compares the library with the pin, so it needs no
dense form.

The pristine counts are the baseline, which holds the dense forms. So a dense form that the changed
build leaves out is no moved function. At rga4d, P08 moves 2 functions, and P01 and
`multivector-align` move none. So an evaluation of a change that moves no function reads as
quiet, and the pages take their spread from it.

**A build claim compiles the library alone**, from an entry that holds `import pga` and nothing
else. It compares the peak memory that the compiler reports for the pin and for the changed
library. No proposal makes one at the pin. P01 made one, and the Architect ruled to drop it,
since head now holds the saving that it measured. At rga6d head peaks at 195.8 MiB and P01 at
200.3 MiB, ×1.02 (`evaluations/cayley-derivation.json` at `b9ed6685`, 2026-10-07,
`linux amd64, 4 cores`).

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

The laws of P04 and P10 hold against the library with their changes applied. They hold at each of
the nine algebras of the library, from rga2d to rga6d and from cga3d to cga6d. A copy of P10 whose
root takes the smaller part by its own root fails the law of the small part at cga3d and cga4d.
`proposals/11-unitize-general/laws.nim` holds the laws of its rule, and `limits.nim` its limits
over long chains and frames, at rga3d, rga4d, cga4d and cga5d.

A basis-set form of P04 that reaches no basis stops the compile. So its laws hold such a form to
zero in the library, at each type and pair that they sweep. Where a map drops the sign of its
table, the laws fail at rga4d. Where a squared norm reads half its table, they fail at cga5d and
hold at rga4d, whose metric is diagonal.

Up to 4D the laws of P04 sweep each product over every pair of named types and the whole
multivector. At 5D and 6D they sweep a vector with each type. The compiler takes about 0.3 MiB
for each term that a form emits. Every pair at rga5d emits some 20 000 terms, and its build peaks
at 7 158 MiB.

Verified by `test_rga4d.nim` and the other stubs, suites `Internal: Markdown`, `Internal: Changes`,
`Internal: Proposals`, `Internal: Evaluations`, `Internal: Cells` and `Internal: Figures`. They
cover parse, quote and digest rules, and claim kinds, with the defines a claim may name and the page
names. They cover the programs of a chain of proposals, base first.

The same suites cover proposal numbers taken twice or skipped, and the status that freezes a
proposal. They also cover pairing of runs, NaN shares, the success line of the compiler, and the
table serialiser at pin. They cover the algebras that an evaluation measures, with the flag and
without it. A digest moves with edits, and never with prose.

## Notes

`marginalia/notes.md` holds the notes on library source. Each note quotes the lines it is
about, and the page computes the line number at build from where the quote stands at pin. A
quote that no longer occurs once is a finding.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Notes`: parse, location at pin,
and a stale anchor.

## Pages

**Every page is one shell and one body.** The shell is `pages/shell.html`, committed and
hand-written. The body is rendered in Nim from committed files, so a page says only what those files
say. The font faces are the six that `pga_visualiser` embeds, fetched through `koch fetch-assets`
and inlined as base64. Interaction is CSS: tabs, filters and sort are inputs that `:has()` rules
read.

**Each Noto font face ships whole, as the TrueType of its own release** (Article X.8, as the
Architect ruled it on 2026-10-03). Commit Mono is no Noto, so it ships as the Latin `woff2` of
`@fontsource`. All six font faces are under the SIL Open Font License 1.1. The cost is weight: each
page is 4.3 to 5.2 MiB, against 0.9 to 1.8 MiB with the subsets, by `ls -l build` on 2026-10-04.

**Each stack holds every family of the sans stack before any family of the system.** So a character
that the first families of a stack lack falls to a font face that the page ships. Noto Sans draws
`ₙ`, `ₖ` and `ᵀ` in code, which no family of the mono stack holds, at a width that is not one
column. Verified by `test_rga4d.nim`, which reads the stacks of the shell, and by `koch drive`,
which judges every page that `drive` renders (below).

**Each family of one font face is declared over the weights 400 to 700** (Article X.8). Commit
Mono, Noto Sans Math and Noto Sans Symbols 2 each ship one file, at weight 400. Headings, table
heads and strong text ask them for 600 and 700. Over its declared range, the browser draws the file
as it is, and never a bold of its own. So bold code and bold maths draw their regular glyphs, at
the width that they had. `pga_visualiser` declares the same files over a range in the same way.

- Rejected: a bold file of Commit Mono. The pages ship the six font faces of `pga_visualiser`, and
  maths and symbols have no bold file at all.

The collector keeps the characters beyond ASCII alone, so `koch drive` cannot see a bold that the
browser synthesises over ASCII, as in bold code. So `test_rga4d.nim` holds each family of the shell
to a font face of weight 600 or more, whatever text the family draws. Verified on 2026-10-28 in
Chromium, where bold code keeps its width and draws 32 % less ink than the bold of the browser.

**A proposal can carry a figure.** A paragraph of one image alone, as
`![Derivation map.](../../pages/derivation-map.svg)`, embeds the SVG that it names. The SVG lives
under `pages/`, since the layout admits hand-written markup there alone. Its colours are shell
tokens with fallbacks, so it follows the theme of the page and still reads alone. A figure that
names no file is a finding of `drive`. Rejected: a figure kept outside the repository, because no
page is built from it.

**Bar marks on bold letters are drawn by markup,** as the Architect ruled on 2026-10-04. The left
complement is written 𝐜̱, with U+0331, and the right one 𝐜̄, with U+0304. Noto Sans Math holds each
bold maths letter and both marks, but it puts each mark beside the letter. So `htmlMarked` boxes
each bold letter that carries a bar mark, together with its marks, and the shell draws the bar. The
bar under stands where the font face draws its macron below. The bar over stands 0.054em higher than
the macron of the font face, to clear the bold x-height.

The mark stays in the text and a clip hides it, so copy and search read what the source says. Each
word that holds such a letter stays on one line, because a box is a place where a line may break.
Tags, attributes, and the content of `svg`, `script` and `style` pass as they are. Rejected: the
marks as the font face places them, since each sits after its letter and meets the next sign.
Rejected: sans-serif bold letters, which carry all three anchors, since the letters change shape and
the library code that a page quotes cannot change.

In code, ★ comes from Noto Sans Math as ☆ does, because Commit Mono draws ★ smaller.

The cause is in the font face. In Noto Sans Math 2.539, the 52 letters of the bold block, U+1D400 to
U+1D433, carry a `center` anchor alone. A mark such as U+0338 uses that anchor. A top or bottom mark
finds no anchor on them, so HarfBuzz leaves it at the pen, after the letter. The italic, bold
italic, sans-serif bold and monospace blocks carry `top`, `center` and `bottom`, and so does the
Latin `c`.

Verified on 2026-10-04 by fontTools, which read the GPOS table of the font face in the store.
HarfBuzz shapes `uni0331` with an offset of 0 after `u1D41C`, and of −373 after `c`. HarfBuzz moves
a mark by its own rule only for a font face with no GPOS table. With that table removed, it puts the
same mark at an offset of −437, under the letter.

The glyph source of release 2.539 gives `cbold-math` the `center` anchor alone. Tag 3.000 holds
sources alone, with no bold letter source, and `notofonts.github.io` publishes 2.539 as its last
build. So whether a later release mends the anchors is unverified.

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

**The docket carries the rules that it alone draws with,** as `STYLE` in `docket.nim`. So a
change to its look moves its digest alone, and the cost is that its look reads from two files. A
class that the shell styles for another page must not mark an element of the docket. The shell
gives `.summary div` to the card of a proposal page. A rule through a class and a bare tag
outranks the own rule of each element that it reaches. Suite `Internal: Pages` of
`test_rga4d.nim` holds that law over the docket and a proposal page.

**Each count of a proposal is one bar** over the general operations bounded now, and each
operation counts once. A proposal names itself once, then gives one line to each algebra that it
changes. Grey marks an operation at the bound now and with the proposal. Blue marks one that the
proposal brings to the bound, and orange one that it takes off. The exact counts stand beside, as
`37 → 39 of 39`. Where the proposal drops a function, its operation leaves the second count, and
the label names both totals.

Rejected: green for a gain and red for a loss. The palette validator of the `dataviz` skill put
them 3.8 apart to a reader with red and green colour blindness, against a floor of 8. It put blue
and orange 24.7 apart. Verified by `test_rga4d.nim`, and by hand in Chromium 141 on 2026-10-19.
The hand check rendered the docket as `drive` wraps it, at 400 px and 1100 px in both themes.

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
on the map. It also covers the summary above the claims. Suite `Internal: Edits` covers the diff
with its numbers and folds, a new file, and the class of the sign column. It also covers the
signatures an edit defines or sits in, and a header that closes at its own indent.

## Render of pages

**`drive` renders every page, and `koch drive` judges the font faces that each page draws**
(`CONTRIBUTOR.md`, Pages and assets). The driver builds the pages once, for the digests and for the
render. It wraps each page in the skeleton that the publish host adds, and writes it to
`build/hosted/`. The harness in `tools/drive/` loads each one in Chromium through Playwright, and
opens every `details`. Its collector reads each string that the page draws, with the font stack,
weight and case transform of its element. That covers text nodes, SVG text, placeholders, and the
strings of `content` on `::before`, `::after` and `::marker`.

The collector also reads each `@font-face` rule of the page, and each font face that the browser
does not load. The harness writes what it reads into `build/font-faces/written.json`, in the shape
that `font_stacks.nim` in `curator/audit/src/` gives. Each rule there names the file of its font
face. The harness writes the bytes of each `data:` source into `build/font-faces/files/`, and names
each file by the digest of its bytes. So `koch drive` reads the bytes that a viewer receives, and
the harness writes each font face once, however many pages ship it. Verified by hand on 2026-10-24:
one run wrote six files, and their names equal those of the six files of the store.

**`koch drive` gives the verdict, and its control page proves the collector in five kinds of
place.** Before it runs `drive`, it writes a control page to `build/font-faces/control.html`. The
collector reads that page as it reads every other page, and the harness writes it as page `control`.
Once `drive` passes, `koch drive` resolves the stack of each string against the font faces of its
page. It writes `build/font-faces/found.json`, and fails where a font face of the system draws a
character beyond ASCII. It also fails where a font face does not load, or where the collector misses
a numeral of the control page.

The suite of the resolver, `test_font_stacks.nim` in `curator/audit`, holds each of the three.

The project keeps no reader of `cmap` and no judge of font faces. The costs of the resolver are in
the header of `font_stacks.nim`. `koch drive` leaves its control page in `build/font-faces/`, so a
later run of `drive` alone reads it too. Where that folder holds no control page, the harness writes
`written.json` with the pages alone, and the driver prints that it does so. Nothing judges that
file, because only `koch drive` resolves it.

Before it reads, the collector shows every element through one `display: revert` rule. Chromium
styles a hidden element on demand, one at a time, and the docket hides 28 540 of its 31 355
elements. One read of the docket took 65 s that way, and three reads took 1.4 to 1.7 s with the
rule. `Date.now()` in node timed each read, in Chromium 141 on `linux amd64, 4 cores` on
2026-10-04. `display` sets no property of a font, and the 2 623 strings that the docket draws read
identical both ways.

**Each card holds its blocks apart.** Before the collector reads, the harness reads layout, in
`tools/drive/layout.ts`. It opens each `details.card`, then checks each tab that `nav.tabs` offers,
since a card behind another tab draws no box. Two blocks of one card that share a column and stand
closer than 4 px are one crowded pair. The harness writes each pair into `build/crowded.json`, and
`src/pga_benchmark/pages/render.nim` turns each one into a finding at its page:

```text
build/hosted/proposals.html:0: details#change-imports-narrow.card: Blocks of card touch; got `p, p`
at `0 px`.
```

The shell spaces a card by the gap of its grid. A `details` holds each child after its summary in
one box, so that gap stops at the summary. The shell gives each block after the summary a margin
of 10 px, the gap of a card that is not a `details`. Without that rule, 34 pairs on the proposal
list touched, and 17 pages held none.

**A control page of the project proves the layout read.** `drive` builds it through the shell from
`tests/fixtures/control_render.json`, so it ships the same styles as every page. The card `crowded`
sets an inline margin of zero on its second block, and no rule of the shell outranks it. So that
card must raise one finding. The card `spaced` keeps the margins of the shell, so it must raise
none, and it fails where the shell loses the rule.

The verdict holds the control to exactly the cards that it expects. An expected pair that is absent
is a finding, because the read is then blind. A pair that the control does not expect is a finding
too, and so is a control that expects nothing. The harness reads this page for layout alone, so it
stays out of `written.json`. It is no page that the project ships, and `koch drive` would judge it
as one. The fixture lives under `tests/`, since the suites read it as `drive` does.

Costs: the harness reads one viewport, the default of Playwright. So a string, a stack or a card
that `@media` changes at another width is unread. The harness compares no two blocks that stand
side by side, as the columns of a grid do.

Three runs of the harness over every page and both control pages took 11.4 to 12.0 s. The harness
that resolved each character itself, built from `28c559ae`, took 11.3 to 11.6 s in three runs. Those
runs read every page and the control page of layout. The wall clock timed each run, on `linux amd64,
4 cores` on 2026-10-24. The resolver of `koch drive` is unmeasured, so the pair holds the harness
alone.

Verified by `koch drive` on 2026-10-24, in Chromium 153.0.8010.12, which is revision 1243 that the
lock pins. Every page held no finding, and `found.json` held each numeral of the control page. A run
of `drive` alone with no control page wrote `written.json` with the pages alone, and said so. With
the read of placeholders removed by hand, `koch drive` failed so:

```text
contributor/ronri/pga_benchmark/build/font-faces/written.json: Collector reads text in every kind
of place control page holds; got `U+4E8C` in placeholder of field uncollected.
```

Suite `Internal: Render` of `test_rga4d.nim` holds the verdict on cards, its control, and the
command line of the harness. Suite `Internal: Pages` holds the skeleton, and suite
`Internal: Driver` holds one build for both uses.

The one script is the search box of the docket. It is Nim, `pages/find.nim`, which the driver
compiles to JavaScript under the flags of every build. The compiler is pinned, so the script
and the digest of each page still follow those files.

## Home and views

**A home page and three views carry every page,** as the Architect proposed on 2026-10-17. The
Architect named the views Progress, Performance and Proposals on 2026-10-18. Progress shows how
complete the library is, in the library map. Performance shows how far each operation stands from
what it could spend, in the gap docket. Proposals shows what to change next.

The home page gives each view a card with one figure, read from the files that the view reads. A bar
on top of each page links the home page and the views, and it marks the view that the page belongs
to.

The card of the docket counts the operations at the multivector lower bound on multiplies, at the
first algebra of the docket. One figure fits a card, and the docket opens on that algebra.

**The marginalia are a tab of the Proposals page,** as the Architect ruled on 2026-10-17. The
changes and the notes record explorations, as the proposals do. The Proposals page keeps the name
and the URL of the list of proposals, and Performance keeps those of the docket. No verb builds the
marginalia page now, so `pages/published.json` does not name it.

**The library map has a page of its own, Progress,** as the Architect ruled on 2026-10-17. It grows
with the library, so it outlives P01, and P01 links to it. Each box of `pages/derivation-map.svg`
names the catalogue ids that it stands for. A box of a table alone names its constant, as
`CAYLEYS_WEDGES_TRANS.base`.

**The state of each box is read from the library at pin and from the catalogue.** An operation has
a table of its own where a call of `defineOperator` in `pga/operators.nim` names its symbol. A table
alone has one where `pga/cayleys.nim` exports its constant. The library offers an operation that the
catalogue holds at some algebra, as `baseline/static_<algebra>.json` records it. Any other box is
missing, and the page gives it a dashed edge.

**`drive` holds the map to the library at pin.** It fails where the map fades a box that has a table
of its own, or draws solid a box that has none. It also fails where the library builds an operation
from a table that no box stands for. A table that the library exports, and that no box and no
operator names, fails too. A suite holds the committed map to the same rules, so `koch check` fails
first.

The SVG fades each box itself, so the map reads alone, and the check keeps each fade true. The cost:
the table of an operation is read by its symbol, so the unary and the binary dot share one answer.
At pin the library builds both from tables. Rejected: a fade that the page alone writes. A faded
line is a route that the code does not take, and no file states which route a new table takes.

## Derivation map

The library map draws its bars in its SVG, as an underline or an overline, with the mark at size
zero. A bar over a group of signs, as in 𝐚 ∨ 𝐛 = 𝐮̱ where 𝐮 = 𝐚̄ ∧ 𝐛̄, is the decoration alone. The
font face sets an overline near its ascent, so no text stands just above a formula with a bar over
it. The tilde and the hat are spacing marks, ˜ and ˆ, since the font face puts a combining mark
beside its letter. Two advances, of the mark and of the letter, set each over or under its letter.
The tilde under 𝐐 sits lower, to clear its tail.

The map holds eleven blocks, in the order of the groups of the code, under its legend, and each anti
table stands under its base. Each box holds a symbol alone, and the line into it carries its
formula, as in Lengyel's figure. Under the line stands the function that builds the table. A box
from elsewhere is a cell of a dashed box, filled in the colour of its kind, so that no line leaves
its block. Brown text holds in RGA alone and blue text in CGA alone, so that no formula names its
algebra. The two colours are shell tokens for code, so they follow the theme.

Each box takes its own line from each box that it uses, and no two lines join or fork, as the
Architect asked on 2026-10-17. Each line turns at right angles. The formulas take the form of the
maths, as Lengyel writes them. So a unary operator, such as ★ in 𝐮★, stands after its operand. An
interior product, such as 𝐚 ∨ 𝐛★, is a product with a dual. The code puts a unary operator first and
spells ∨★ as one operator, as Nim needs.

Each block takes the boxes of other blocks on its top row, and it builds downward from them. The
boxes from one block share one dashed box, with a cell for each box, as the Architect asked on
2026-10-17. A separate line leaves a dashed box for each box that uses that block. The dashed boxes
stand in the order of the blocks, and the cells in the order that their block derives them. A box of
the same block is never in a dashed box, since its own line reaches it.

The line of each block that a formula draws on reaches its box, unless the box reaches that operator
through another input. So ∨ also stands for the ∧ that it derives from, and ★ stands for the 𝐆 that
it derives from. A line that crosses another line passes over it, and the line under it shows a gap.

The map gives every route to a box that holds at pin, and it fades each route that the code does
not take. A faded box is an operator with no table, so the map shows what the tables serve. The
center norm has no formula in the library, so its box has no line. A check by hand on 2026-10-17
builds each faded route at rga3d, rga4d, cga4d and cga5d, and each gives the table it leads to. Two
of them hold in RGA alone, so the map writes them in brown.

The last three blocks hold the measures, the projections and the motion operators. Of the
operators that Lengyel gives, the map adds the flector, the distance and the angle, as the
Architect ruled on 2026-10-17. The exponential, the logarithm and the square root of a motor are
not on it. The map also leaves out the motor that moves one object onto another, and the dilation
and the transversion of CGA.

P01 lays out every Cayley table of the library, so most other proposals build on it. The map shows
how complete the library is, and a faded box is an operator that waits for its table. Other
proposals count only the tables that the library builds. When the library adds a table, each
proposal that it concerns takes the new table into account.

The metric shows as its matrix in each algebra, with ellipses for the rows that repeat. The map
writes the origin as 𝐞ᵒ and infinity as 𝐞 with ∞ raised, so that neither reads as 𝐞₀ or as
another basis vector. A comma or a word parts two formulas or two signs, so the sign ∙ in the map
is always the dot product.

## Proposal pages and code

**Every proposal page has one shape, argument first, as the Architect ordered on 2026-10-16.** A
card opens it: what the proposal is, is for and costs, what it needs and blocks, and its verdicts.
Then five numbered sections follow: Problem, Idea, Alternatives, Costs and Open decisions. An
appendix holds Code and Evidence, so the reader meets the idea and its cost before what checks it.

**Each fact stands once.** The page generates the dependencies, the verdicts, the code and the
measurements, so `proposal.md` restates none of them. Its summary is three labelled paragraphs,
and its sections are the five, then Landing and Evidence notes, each once, in order. `drive`
names any file that departs from it. Rejected: free headings for each proposal, which read
unorganised and said each figure up to three times.

**Evidence condenses what the evaluation moved, as the docket draws it but static.** Per algebra,
one row stands for each function that moved: its multiplies, bytes moved and time, each a bar of
the proposal over pin. The axis runs from ×1/16 to ×16, so a bar left of the line is a gain. An
operation within the spread is counted, and a helper that moved is named. The proposal stands
with its bases applied, and the page says so.

**A proposal shows its code one block per file, folded, as the Architect asked on 2026-10-16.**
Inside, each definition that the change adds, removes or changes shows its signature and doc
comment, and folds its body. A definition is a routine, a member of a section, an import, a test
or a statement, at top level or under `when` and `suite`. Two versions pair definitions by
context, kind and name, same head first. Lines in no definition follow as other lines.

**The marginalia tab shows each edit as a diff of lines, open, under a list of the files it
touches.** Each line carries its number in the file as the edit finds it. The earlier edits apply
first.

A run of unchanged lines longer than twice the context of 3 folds to its count. So a whole-file
replacement, as P01 makes, shows its hunks and not the whole file. The diff is a longest common
subsequence over the lines between the head and tail that both sides share.

The summary of each edit names the file and line, and the lines it removes and adds. It lists the
signatures of the routines, tests and suites that the edit defines, with no body, pragma or
comment. A whole-file replacement lists only the signatures that the file it replaces lacked. An
edit that defines none names the routine that it sits in, and an edit at top level names none.

**A fence of Nim marks its keywords, declared names, doc comments, comments, literals and
pragmas.** So a signature reads apart from its doc comment. Keyword, name, doc comment and literal
each take a colour token of their own. Each holds 5.4:1 or more on the code ground in both themes.
A comment takes the muted ink, and a pragma takes the second ink.

The marks read one line at a time, so a string or a comment that spans lines marks wrongly. No
fence here holds one. Each fenced line flows inline and ends at its newline, so no line doubles
and a copy keeps each line.

## Library head

**The verb `head` holds the pin to library head.** It reads the head of the library repository
with `git ls-remote`, and compares the tree of the library directory at head with its tree at
pin. A commit elsewhere in the repository changes nothing measured, so the check compares trees,
not commits. Where the trees agree, it exits 0. Where they do not, it prints its finding and
exits 1.

**`drive` holds every measurement and file to the pin.** Each baseline and each evaluation must be
taken at the pin. Each evaluation must carry the digest of its edits as they are now. Each change
and proposal must apply at pin, and each note must find its quote.

**`restamp` moves a timed record to a new pin where its C is the same.** Each runtime baseline,
the sweep and each algebra of an evaluation name the digest of the C that their timed builds
emitted. The digest leaves out the commit of the pin, since the build writes that commit into its
documents. `restamp` compiles the same builds at the pin. Where each digest holds, the record moves
its stamp to the pin, keeps its times, and names the commit it was timed at. The same C on the
same compiler and flags makes the same machine code, so the times stand.

An evaluation is tried again with its times kept, so its suites, counts and claims are taken at
the pin. The suites of the library hold line numbers in their C, so `restamp` cannot keep them. A
record whose C differs is a finding, and `bench`, `sweep` or `evaluate` takes it again. Each
evaluation timed at `d9be8ae` predates digests, and carries the digest of its builds at its own
pin. The Architect chose this rule for a head that moved only comments and form.

**The digest reads C alone, at any path.** Nim folds the path of a module into the hash in the
name of each type. The digest names each run of 20 to 32 letters and digits after `__` by its
order of first appearance. A full build also writes the command of the C compiler, with absolute
paths, at the head of each file. The digest leaves that header out, and a build that stops at C
writes none. So any checkout takes one digest, from either build.

The body of each type stays in the digest, so a type that changes shape still moves it. A copy of
the tree at a second path emits 181 such runs in the bench at rga4d. Some are module names, such
as `pureZcollectionsZtables`, which read the same at each path. Read with names by order, the C of
the copy matches the first, file for file. The sweep, built in full, takes the digest of its C
alone at each of five dimensions.

Rejected: a new timing of each record at such a head. The binaries are the same, so new times
would record the drift of this host alone, ×1.19 to ×1.27 between days at rga4d. Cost: `restamp`
compiles each evaluation at each algebra, and runs its suites and claims again.

Verified by `test_rga4d.nim` and the other stubs, suite `Internal: Head`. It holds the order of
files, and the commit left out of the digest. It holds a type hash and the header of a full build,
which move no digest. It holds a move on equal digests alone, a digest taken at its own pin, and
the first commit timed at. Suite `Internal: Gaps` holds the list to name that commit.

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
records the resolved commit `3d9696edbaaa5dca655c3024174bd46fd156d7c6`, and `nim.cfg` names
the subdirectory that Atlas restores it to.

That commit is the head of the library on 2026-10-19, as the standing instruction of the
Architect asks. Both projects are under the Prosperity Public License 3.0.0. Rejected: a copy
of the library in this tree, which Article XI.3 forbids.

**The compiler is pinned by release**, Nim 2.4.0. It is the first release whose lexer holds the
seven operators that the library spells, which nim-lang/Nim#26074 added. Nim 2.2.14 holds none of
them. Atlas writes `"objects": {}` for a repository without a nimble file, so the resolved commit is
patched into `atlas.lock` by hand. The stored copies in the lock of the nimble file and of `nim.cfg`
are kept byte-identical to the committed files, which the static pass checks.

**`package-lock.json` pins the Node tools, and git ignores their checkout.** The project commits
`package.json` and `package-lock.json` with the versions that `pga_visualiser` pins.
`typescript` 7.0.2 type-checks the harness, and `@playwright/test` 1.63.0 drives Chromium. Both
are Microsoft's, under Apache-2.0. `@types/node` 22.20.2 is DefinitelyTyped's, under MIT, and
types the Node surface that the harness reaches. The `license` field of each entry in
`package-lock.json` gives these licences.

**Chromium is the build that Playwright pins, or the one that `PGA_CHROMIUM` names.** The lock
fixes `@playwright/test`, and that version fixes the revision of the browser. `drive` fetches it
with `npx playwright install chromium`, and keeps the one that `PGA_CHROMIUM` names instead.
Playwright publishes no checksum, so the pin is a version and not a digest.

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
under `taken`, and at the pin they are from 2026-10-11 on `linux amd64, 4 cores`.

`gaps.md` and the docket show each gap of the pin from those files, and `show` prints the C and
the machine code of one function. The times of the point forms of Lengyel's code are
`baseline/unitized.json`, from `unitized`. The figures of each proposal before and after its edits
are in `evaluations/<name>.json`, and its page shows them. Allocation is zero on every measurand in
every implementation, with the gauge live, as the runtime baselines record. Scaling across
dimensions is in `baseline/sweep.json`, from `sweep`, by hand. It holds five alternating runs of
each algebra from rga2d to rga6d, each 40 rounds over 1024 objects.

**Generated operators write each zero element, and hand-written functions leave theirs to the
default fill.** A generated operator writes every element as a straight statement, zeros included,
because generation lowers a Cayley table and nobody writes the zeros by hand. At the pin, what the
default fill would cost the generated operators is unmeasured. A hand-written function, such as a
norm, writes no zero. The Architect decided this, because the library is about PGA and not about
micro-optimisation.

Each function that a Cayley table can express moves to generation, and so gets its zeros
unrolled at no cost. At the pin `3d9696e` the library works this way, and its attitude and
carrier are generated. Its hand-written `+` and `-` carry `noinit` and write each coefficient, so
they fill nothing. The cost that stays is what the hand-written norms pay.

The cost is measured at `3121342` on `linux amd64, 4 cores`, an Intel Xeon at 2.10 GHz, on
2026-10-03. The harness calls each function through a volatile procedure pointer. So the body of
each function compiles alone, and writes to memory that it cannot see. Each figure comes from two
passes, and each pass is the median of nine runs of 41 rounds over 1024 objects. Nine in ten
functions that did not change moved ×0.86 to ×1.02. The pins `d9be8ae` to `e993419`
change no norm and no generated operator, as their static baselines show, so these figures stand
for them.

At `28f4e11` each conformal norm reads one part, so its cells stand for `3121342` alone.

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

- Evaluations time rga4d and cga5d unless `--thorough` asks for rga3d and cga4d too. Each
  evaluation committed now measures all four, from one run of `evaluate all --thorough`.
- The `build` claim reads the peak memory and seconds that the compiler reports of itself, for
  the library alone. It compares two builds on one machine, and is no measurement of the
  machine.

- Timings come from a shared cloud container, and vary by tens of percent between runs. The
  tolerance absorbs some of that, and the rest is why timing never guards.
- Movement is modelled from the bytes that the code names, and never measured as cache
  traffic.
- The inspector reads text patterns of Nim 2.4.0. Another release could spell the same C
  differently. The suite that holds the reader to the nimcache of the test binary is
  what would say so. A loop whose bound is a variable counts once.
- 32-bit floats and SIMD forms are unmeasured, and the SSE paths of Terathon were not
  compared. The Architect ruled on 2026-10-06 that they stay unmeasured while the library holds
  64-bit floats alone. A SIMD form may come as a proposal that keeps 64-bit floats, after a
  proposal that makes the width of the float configurable.
- `sweep` is hand-run only. Three sweeps of five runs at `edb0c9d`, on `linux amd64, 4 cores` on
  2026-10-05 and 2026-10-06, differ by ×1.002 to ×1.004 at the median cell. At the 90th
  percentile they differ by ×1.025 to ×1.030. Five of 319 cells differ by more than ×1.10. The
  widest is `wedge_dot_anti` at rga2d, ×1.62 at 3 to 4 ns, so one fast cell is weak evidence
  alone. The growth from 2D to 6D holds: `wedge_dot` grows ×601 to ×616.
- A change to the bench outside a measurand moves the time of that measurand. Ten alternating
  runs with and without `noinit`, on `linux amd64, 4 cores` on 2026-10-02, keep the median ratio of
  each implementation at ×0.99 to ×1.00. Single measurands move steadily from ×0.80 (`scale`)
  to ×1.16 (`wedge_anti`). Code layout is the likely cause. So a time ratio inside about ×0.6
  to ×1.4 between two builds is weak evidence of a change.
- Two forms that spend the same arithmetic can differ in time. At rga4d `+` and its dense form
  compile to the same 16 loads, 8 adds and 8 stores. The loop of the library interleaves each
  load, add and store, and the dense form groups its loads first. Of the 66 rows that spend the
  same counts in both, the median reads ×1.00, and light rows stray to ×0.65 at cga5d. Why order
  moves time is unmeasured, since this machine offers no hardware counters.

## Open questions

- Whether the library takes P03, `partner-sign`, and with it a partner that does not check the
  grade of its operand. At cga5d, P03 on P01 and P08 spends the chain bound of 324 multiplies,
  three zero fills and two error checks. P01 and P08 alone spend 437, 104 and 268. Both are the
  counts after the edits in `evaluations/partner-sign.json` and `evaluations/compound-tables.json`.
- Whether the library takes P04, `exact-kinds`, so that each operator from one table returns the
  exact basis-set type of the bases it reaches. At rga4d 16 measurands stand above the byte bound
  only because they write a whole multivector for one coefficient, and at cga5d 15 do. Each is a
  dot, an antidot or a squared norm. Under P04 each of them writes 8 bytes on a basis-set type.
  The measurands hold whole multivectors, so they keep the operators of the library.
- Whether the library takes P05, `multivector-align`. It aligns the whole set to `min(64, size)`,
  one cache line from three dimensions up, so it pads no multivector. P04 aligns every basis-set
  type to `alignment` of its count instead, as the Architect ruled on 2026-10-04. That is the
  largest power of two that divides their bytes, at most 64, and it gives the whole set the same.
  Both edit the one definition of `MultivectorOf`, so the second to land quotes the first.

  On two machines and three instruction sets, a caller that holds multivectors in a `seq` times
  `-m` at ×0.42 to ×0.93 of the pin. It times `m + n` at ×0.70 to ×0.88, at no cost in size. On
  Emerald Rapids under SSE2, `/ m` and `★ m` at cga5d run ×1.10 and ×1.11 of the pin. The
  figures are in `proposals/05-multivector-align/proposal.md`.

[replications]: https://gitlab.com/mraxilus/replications
[terathon]: https://github.com/EricLengyel/Terathon-Math-Library
