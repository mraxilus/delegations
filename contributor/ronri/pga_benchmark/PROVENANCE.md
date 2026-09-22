# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude Fable 5.1 |
| Date    | 2026-09-22 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 874ef979b21fbc1e |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

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

`INLINED` names the symbols that the library spells as a template over a field read. Head
made the component accessor `[]` a template, where it was a `func` with `{.inline.}`. The C
therefore carries no function for it, and the emission suite passes over it. A suite holds
`INLINED` to the source of the library, as it holds `TEMPLATES`. The gap row for
`select_part` carries a dash for every count, and its verdict rests on time alone.

The squared norms `|∙²` and `|∘²` are spelled in backticks, as `` (`|∙²`(m)) ``. The
character `²` is no operator character to the lexer, so the prefix form splits it off as an
identifier and `parseExpr` fails on it. These two operators carry no alias in the umbrella,
so their alias field stands empty and the alias suite passes over them.

Their cite is the
equation that defines the norm. The squared quantity is what stands under its root. The
suites of the library cite none. The reference returns the weight squared norm as an
`Antiscalar`, so that widening puts it in the antiscalar slot where the library writes it.

Verified by `trga4d.nim` and `tcga5d.nim`, suite `Catalogue`. Ids are unique. Every
expression compiles against the library. The set of symbols equals the set of exported
operators, read out of `pga/operators.nim` and `pga/multivectors.nim`. The set of aliases
equals the exports of the umbrella.

## Reference

`reference/rigid3.nim` (4D, rigid) and `reference/conformal3.nim` (5D, conformal) hold
Lengyel's typed objects and optimal forms, written in Nim. They are in 64-bit floats, so both
implementations run the same scalar. Every operation was derived from the equations of the
book and from the library's own definitions. The Terathon Math Library was read as a
cross-check of forms and counts, and nothing of it was copied.

Where the sign conventions of the library differ from Terathon's, the library's were adopted,
because the library is what is measured. The bulk and weight duals of points and planes carry
the opposite sign. The conformal antidot is the negated dot. The cocarrier of a circle reads
`FlatLine(v: -g.xyz, m: -c.v)`. The `Partner(Circle)` scalar of Terathon carries a sign typo,
and the form here is `f = gw² - v·v - g·m`, which the law suite confirms against the library.

Every form is `{.inline.}`, so it lands in the same nimcache as the operators of the library,
and the same reader counts it. Object construction goes through the `zero3` and `read3`
templates, rather than `Vec3()` defaults and whole-object field copies. On the pinned commit
the former costs about 4 ns and the latter about 20 ns, through the `=dup` hook. That hook
would have hidden the cost of the library. Unitize forms take one reciprocal and multiply, as
Terathon does, where the library divides each component. The divide column shows both.

Verified by `trga4d.nim`, suite `Chapter 2`, and by `tcga5d.nim`, suite `Chapter 3`. For
every typed measurand and every seeded sample, the reference widened into the dense
multivector equals the library within `=~`. Each check cites its equation or wiki page. Suite
`Inspector` reads the nimcache of the test binary itself, and finds `wedge(Point,Point)`
spending twelve multiplies and six subtractions, as its documentation states.

## Widening and pools

A widen puts each typed object into the dense multivector at its basis slots. A narrow reads
it back, and asserts under `-d:testing` that every other slot is zero. Pools are filled once
from `randomize(0)`: dense multivectors of every grade, typed objects in general position,
lines and planes joined from points, and motors unitized. Every typed pool has a widened
image, so the two implementations read equivalent operands.

Verified by `trga4d.nim` and `tcga5d.nim`. Suites `Chapter 2` and `Chapter 3` run through the
widening, and suite `Measurements` runs every measurand over the pools.

## Measurements

`emitCatalogue` turns the catalogue into one timed loop for each measurand of each
implementation. Operands are template aliases into pool slots, and never copies, so the loop
moves only the traffic of the operation itself. Every result is folded into one sink after
the timing, so nothing is dead. The share of results that carry NaN is counted. The conformal
norms of the library return NaN on real objects, and that is measured rather than stated.

`bench` runs `ROUNDS` rounds over `OBJECTS` objects, and reports the median and minimum
nanoseconds for each object: the runtime measurements. The allocation gauge is live only
under `-d:nimAllocStats`. The bench refuses to report allocation counts unless a positive
control raised the counter first. A zero then means zero, and never an inert instrument
(Article VII.4). The plain build reports the gauge as off, and that is the measurement taken
once compiled out.

Verified by `trga4d.nim` and `tcga5d.nim`, suites `Measurements` and `Allocation`.
`summarise` runs on fixture rounds. A short run gives finite positive nanoseconds and a
non-zero sink. The positive control raises the counter, and then no measurand allocates over
a preallocated loop.

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
hold whatever order the C emits them in. Emission order moved when a module was renamed, and
swapped two keys, which is how that was found. Movement turns counts and type sizes into
bytes read, written, zeroed, copied and materialised for each call. It names the bytes that
the code moves, and is not a measurement of cache traffic (Article VIII.1).

On the pinned commit an error-flag branch follows every call of a Nim procedure under goto
exceptions, in both implementations. `{.raises: [].}` on the callee does not remove it, and
only `--panics:on` does (see Figures). Counts are taken with the flags that the documents
name, `-d:release`, which is what a user of the library gets by default.

Verified by `trga4d.nim` and `tcga5d.nim`, suite `Inspector`. It covers:

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

Verified by `trga4d.nim` and `tcga5d.nim`, suite `Guard`. Equal documents pass silently. One
grown count is one finding, which names function, metric and both values. A shrink is an
improvement only. Bytes moved are gated. A function absent in either document is a finding,
and another build or schema is refused.

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

The library composes some operations from several operators. A norm reads two slots. A
support wedges against a constant and then takes a full product. The four projections take a
dual product and then a full product. Such an operation carries a chain of shapes, and its
bound sums what each step demands. A step that carries no rule adds nothing to that sum.

A chain bound is an estimate of that chain, and never a proved minimum. A special routine
can share work between steps, or reach the same answer by a shorter route, so the true
minimum sits below it. `gaps.md` names the steps in the shape column, so every chain bound
reads as one. Every other bound in those tables follows from the axioms alone.

The dual product rule needs a degenerate vector, so a conformal algebra carries no such bound. The
bound spends no zero fill, no intermediate, no error check and no allocation, because a
dense operation needs none of them to be correct. It moves its operands read once plus its
result written once. `gaps.md` carries one row for each operation of each algebra, since the
bound rests on the operation and never on the operand kinds.

Verified by `trga4d.nim` and `tcga5d.nim`, suite `Lower bound`. At four dimensions with a
rigid metric the derived counts reproduce 81 for the exterior product and 192 for the
geometric product. They reproduce 8 for the bilinear form, and 54 and 27 for the
contractions. They reproduce 27 and 54 for the expansions, 16 for a scale and 24 for a
unitize.

The conformal metric is held to 1024 and to 32, and to carrying no bound for the four dual
products. A chain of an expansion and an exterior product is held to their
sum. It is also held to dropping the expansion where the metric carries no rule for it.
Suite `Inspector` holds the soundness law. No lower bound outruns what the library spends
on the same operation. That law reads every measurand of the build's own nimcache.

**What it found.** Every primitive product spends what the algebra demands, and the
operations built on top of them do not. At four dimensions the library stands at the bound
on multiplies for 97 of the 107 operations that carry one. The attitude and the two supports
are what stand above it. At five dimensions it stands at the bound for 92 of 126. The
attitude, the carrier, the cocarrier, the centre, the container, the partner and the four
projections stand above it.

The carrier reads as the attitude does. It wedges against a constant that carries one unit
component, so the algebra demands no multiply at all, and the library spends 243. The
partner spends 1004 multiplies against its chain's 518. On bytes moved the library stands at
the bound nowhere, in either algebra.

At four dimensions the exterior product spends the bound's 81 multiplies, and moves 512
bytes against the bound's 384. The bulk norm spends the bound's 8 multiplies, and moves 768
bytes against the bound's 136.

At four dimensions 65 operations carry a library function, a bound and a reference. Over
those, reaching the bound closes 73 per cent of the byte distance to the reference. It
closes 27 per cent of the multiply distance. At five dimensions 84 operations carry all
three, and reaching the bound closes 87 per cent and 51 per cent. Those shares rest on one
population, so the figures compare.

Cost: the multivector lower bound is derived, and never measured (Article VIII.1). It bounds
arithmetic and movement, and never time. It assumes that no result slot shares a
subexpression with another, which holds for these products and would not hold where
factoring helps.

Cost: a chain bound sums the steps of the library's own definition, so it is an estimate
rather than a proved minimum. The record marks every such bound, and `gaps.md` names the
steps.

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

Verified by `trga4d.nim` and `tcga5d.nim`, suite `Gaps`. It covers the gap verdicts on
fixture documents, an unmeasured gap, and docket stability across a reorder and a new key. It
also covers the verdict and evidence of every cause, the rendered width, and rune-counted
wrap.

## Driver

`tools/build.nim` carries `inspect`, `bench`, `baseline`, `guard`, `drive`, `gaps`, `sweep`,
`system` and `clean`, dispatched from `case paramStr(1)`, so koch reads the verbs itself.
`system` prints nothing: the compiler is the toolchain and the library is an Atlas checkout,
both pinned, and nothing else is fetched. `sweep` compiles the bench at two to six
dimensions, rigid metric, and prints the medians of the general measurands. It never runs in
CI.

Verified by hand on 2026-09-13. `nim r tools/build.nim drive` exits 0 on the recorded
baselines. Lower the total multiplies of `∧(Multivector,Multivector)` in
`baseline/static_rga4d.json` from 81 to 80, and `guard` exits 1 with the finding below.
Restore it, and the guard returns 0 findings.

```text
baseline/static_rga4d.json:0: Total `multiplies` of `∧(Multivector,Multivector)` grew;
got `81`, baseline `80`.
```

## Dependencies

**The PGA library is a pinned dependency, and never a copy.** It lives in [replications],
which carries no nimble file and holds the library three directories inside it. So the
requirement in `pga_benchmark.nimble` names the repository by URL and commit. `atlas.lock`
records the resolved commit `9f9019b26b46490f79f383eee693b1abc84a4f63`, and `nim.cfg` names
the subdirectory that Atlas restores it to.

That commit is the head of the library on 2026-09-22, as the standing instruction of the
Architect asks. Both projects are under the Prosperity Public License 3.0.0. Rejected: a copy
of the library in this tree, which Article XI.3 forbids.

**The bump from `0bc4655` moved the pin over two library changes that this project had to
follow.** The library made the grade table private and read it from a generic `{}`. The umbrella
module then failed to compile for every importer. The line `import pga` alone was enough to
fail.

The library then exported the table in `9f9019b`. The suites of the library did not
catch this, because they import each module with `{.all.}` and never read the umbrella. The
library also gained two operators, `|∙²` and `|∘²`, so the catalogue gained a measurand for
each one. Verified by `trga4d.nim` and `tcga5d.nim`, suite `Catalogue`, which holds the
catalogue to the exported surface of the library.

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

Every figure below was taken on 2026-09-22, in the container of that session: `linux amd64, 4
cores`, a shared cloud machine. It ran on the pinned compiler and on library `9f9019b`, with
`-d:release`. Runtime measurements are medians over 40 rounds of 1024 objects, from
`nim r tools/build.nim bench`, in nanoseconds for each object. Static measurements are from
`nim r tools/build.nim inspect`, and are exact for this compiler commit, with loop trips
weighted.

**The reference side is the drift control.** The bump of the pin does not touch the
reference, because the reference is the code of this project. The reference medians moved by
×1.38 at both algebras, between the baselines of 2026-09-13 and of 2026-09-22. The machine therefore
gave back less than it did nine days before.

Over the same pair the library medians moved by
×1.15. Divide the drift out, and the library ran at about ×0.83 of its old cost. A
comparison of raw medians across two days says the opposite. Read the two
sides together, and never one alone.

| Gap (rga4d) | Library ns | Reference ns | Mul | Div | Bytes moved | Checks |
|---|---|---|---|---|---|---|
| `wedge_point_point` (`∧`) | 40.4 | 3.8 | 81 / 12 | 0 / 0 | 512 / 112 | 0 / 0 |
| `wedge_dot_anti_motor_motor` (`⟇`) | 72.3 | 16.0 | 192 / 48 | 0 / 0 | 512 / 256 | 0 / 0 |
| `transform_point_motor` (three products) | 156.2 | 7.7 | – / 25 | – / 0 | – / 192 | – / 8 |
| `norm_bulk_point` (`\|∙`) | 18.2 | 2.1 | 8 / 3 | 0 / 0 | 768 / 40 | 1 / 1 |
| `norm_bulk_squared_point` (`\|∙²`) | 13.6 | 0.8 | 8 / 3 | 0 / 0 | 384 / 40 | 0 / 0 |
| `unitize_point` (`^`) | 30.0 | 2.0 | 24 / 3 | 1 / 1 | 1152 / 128 | 18 / 0 |
| `support_line` (`∩`) | 65.9 | 2.4 | 162 / 9 | 0 / 0 | 1664 / 112 | 3 / 1 |
| `project_orthogonal_point_plane` | 53.4 | 4.9 | 135 / 14 | 0 / 0 | 1408 / 128 | 2 / 0 |

| Gap (cga5d) | Library ns | Reference ns | Mul | Div | Bytes moved | Checks |
|---|---|---|---|---|---|---|
| `wedge_round_point_round_point` (`∧`) | 85.1 | 5.0 | 243 / 20 | 0 / 0 | 1024 / 160 | 0 / 0 |
| `center_dipole` (`⊙`) | 142.3 | 3.5 | 486 / 16 | 0 / 0 | 4352 / 160 | 4 / 1 |
| `partner_circle` (`⊛`) | 283.6 | 5.1 | 1004 / 29 | 0 / 0 | 34560 / 320 | 273 / 2 |
| `carrier_sphere` (`■`) | 48.1 | 0.4 | 243 / 0 | 0 / 0 | 1792 / 48 | 1 / 0 |

**What the bump moved, over the functions that both commits hold.** The pair is the static
baseline of `0bc4655` against the static baseline of `9f9019b`, 118 functions at rga4d and
138 at cga5d.

| Count (common functions) | rga4d | cga5d |
|---|---|---|
| Error-flag checks | 4388 → 173 | 20032 → 683 |
| Lines of C | 26975 → 2973 | 120745 → 8216 |
| Divisions | 36 → 6 | 64 → 2 |
| Calls | 222 → 175 | 842 → 747 |
| Multiplies | 2154 → 2186 | 9045 → 9109 |
| Bytes moved | 35600 → 35600 | 113728 → 113728 |
| Zero fills | 114 → 114 | 362 → 362 |
| Inline functions | 85 → 104 | 97 → 118 |

The branches and the emitted C fell by an order. The arithmetic did not fall, and it rose by
a little. Every multiply and every division that moved sits in two functions, `^∙` and `^∘`.
At rga4d each one goes from 8 multiplies and 16 divisions to 24 multiplies and 1
division. At cga5d each one goes from 32 and 32 to 64 and 1.

Unitize now takes one reciprocal and
multiplies, where it divided for each slot. Movement did not move at all. The dense
representation still carries every byte it carried, and no gap closes on bytes.

The emitted C of the library at 4D:

- `∧` is one inline function of 17 lines, 81 multiplies, one full-width zero fill and no
  error-flag branch. It held 1090 lines and 178 branches at `0bc4655`;
- `|∙²`, which is new, is 2 lines and 8 multiplies, inline, with one zero fill and 384 bytes
  moved. Its unsquared partner `|∙` is 15 lines and not inline. That partner spends three
  zero fills and 768 bytes, because it takes a square root through a call;
- `^∘` (unitize) spends 24 multiplies and 1 division over 83 lines, with 18 branches left,
  where the reference takes one reciprocal and 8 multiplies;
- `⊛` at cga5d is the widest function in the tree. It spends 2743 lines, 1004 multiplies,
  119 zero fills, 273 branches and 34560 bytes moved. Its reference spends 29 multiplies;
- 104 of 123 library functions at rga4d are inline, where 85 of 118 were.

Allocation is zero on every measurand, in both implementations, with the gauge live.

Scaling comes from `nim r tools/build.nim sweep`, rigid metric, general measurands. At two to
six dimensions, `∧` is 2.9, 7.8, 55.0, 73.4, 203.4 ns. `⟑` is 3.8, 14.2, 106.6, 177.1, 1383.4
ns, and `norm` is 4.1, 7.8, 60.2, 50.5, 92.8 ns. The 4D column of the sweep ran hot against
the bench, so the shape is the figure, and not the values. These numbers are from library
`0bc4655` on 2026-09-13. Nobody swept the library again at `9f9019b`, because the sweep runs
by hand, so read them as the shape alone.

Error checks under `--panics:on` were measured at library `0bc4655` by a compile of the bench
entry with `--compileOnly`, and a count in its C. `∧` at 4D fell from 178 branches and 1090
lines to 0 and 551. That figure is now mostly spent. At `9f9019b` the default build emits no
branch in `∧`. It emits 173 branches over the whole of rga4d, where it emitted 4388.

The
switch still makes defects fatal, so whether the users of the library may take it is the call
of the Architect. The guard measures the default.

A divide against a multiply by a reciprocal was measured on a 16-double array, over 1024
objects and 40 rounds, as medians. Under `-d:danger` the in-place divide loop ran at 9.7 ns,
divide-and-write at 12.4 ns, and reciprocal-and-multiply at 12.2 ns. At this width the
divider overlaps across objects, so the shape moves the figure more than the arithmetic does.
Under `-d:release` the two write-once forms ran three times slower than the in-place one.
The reason sits in the emitted C, and is not yet pinned down. The reciprocal pays where a unitize
sits on a critical path, and not in a throughput loop.

## Known limitations

- Timings come from a shared cloud container, and vary by tens of percent between runs. The
  tolerance absorbs some of that, and the rest is why timing never guards.
- Movement is modelled from the bytes that the code names, and never measured as cache
  traffic.
- The inspector reads text patterns of this compiler commit. Another commit could spell the
  same C differently. The suite that holds the reader to the nimcache of the test binary is
  what would say so. A loop whose bound is a variable counts once.
- 32-bit floats and SIMD forms are unmeasured, and the SSE paths of Terathon were not
  compared.
- `sweep` is hand-run only, and the 6D figure was taken once.

## Open questions

- Whether `--panics:on` is a build that the library will stand behind. The other way to drop
  the checks is to make the operators call nothing. One way is to read the components
  directly, rather than through `[]`.
- Whether sparse-by-grade generation should be grade-pair bodies derived from the Cayley
  tables, or a runtime grade mask. The first keeps every body derived, and the second keeps
  one body for each operator.
- The reference is not yet optimal on the Nim side. `rotate` and `transform` still zero-fill
  a `Vec3` result, and pay a branch for each helper call under the default flags. To write
  their components directly would lower the reference figures further.
- Whether the 2D references (rga3d, cga4d) are worth a derivation. Their gaps carry library
  counts and absolute verdicts only.
- Why the write-once unitize shapes run three times slower than the in-place one under
  `-d:release`, in the reciprocal experiment above.

[replications]: https://gitlab.com/mraxilus/replications
[terathon]: https://github.com/EricLengyel/Terathon-Math-Library
