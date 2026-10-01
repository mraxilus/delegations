# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-29 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 1b8b3321357e533e |
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

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suite `Catalogue`. Ids are unique. Every
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
templates, rather than `Vector3()` defaults and whole-object field copies. On the pinned commit
the former costs about 4 ns and the latter about 20 ns, through the `=dup` hook. That hook
would have hidden the cost of the library. Unitize forms take one reciprocal and multiply, as
Terathon does, where the library divides each component. The divide column shows both.

Verified by `test_rga4d.nim`, suite `Chapter 2`, and by `test_cga5d.nim`, suite `Chapter 3`. For
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

Verified by `test_rga4d.nim` and `test_cga5d.nim`. Suites `Chapter 2` and `Chapter 3` run
through the widening, and suite `Measurements` runs every measurand over the pools.

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

**The bench runs five times, and each time is the median of those runs.** `bench` runs the
plain binary of each algebra in turn, algebra after algebra, `BENCH_RUNS = 5` times. So drift
of the machine lands on every algebra alike. For each implementation the runtime baseline
keeps the median of each run as `ns_runs`, in run order. `ns_median` is the median of those,
and `ns_min` is the least minimum.

One run times both implementations, so the runs pair by index, and each run gives one time
ratio. The docket draws one tick for each of those ratios. Rejected: the spread of rounds inside
one run, because it misses drift between runs. That drift is the larger part on this machine.

**The runtime baselines were taken again on 2026-09-30**, in another container of the same
description, five runs each. Their medians run ×1.7 to ×2.3 those of 2026-09-28 across the
four algebras. So times from two containers never compare, and ratios within one run do.

Even those ratios moved against the single run of 2026-09-28. From the 5th to the 95th
percentile, the typed time ratios moved between ×0.50 and ×1.54 at rga4d. At cga5d they moved
between ×0.75 and ×2.07. Within the new baselines, the least and greatest run ratios of the
median measurand are ×1.36 apart at rga4d and ×1.35 at cga5d. One run of cga4d ran ×2.5
slower than its median, and the machine reported steal time.

So one run's time ratio is weak evidence, and the ticks on the docket say how weak. The
figures below stay as taken on 2026-09-28.

**`ns` stays in names as a unit symbol.** The Architect ruled so for this project, as for `ms`,
`px`, `kb` and `mb` on pull request 322. So `ns_median` and `ns_library` keep it. A single
letter stays only where an equation or a small index scope gives it meaning (V.6). Examples
are `i` in a scan and `a + b` in the sum of counts.

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suites `Measurements` and `Allocation`.
`summarise` runs on fixture rounds, and fixture runs combine to the median of their medians,
the least minimum, and each run's median in order. A short run gives finite positive
nanoseconds and a non-zero sink. The positive control raises the counter, and then no
measurand allocates over a preallocated loop.

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

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suite `Inspector`. It covers:

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

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suite `Guard`. Equal documents pass silently. One
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

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suite `Lower bound`. At four dimensions with a
rigid metric the derived counts reproduce 81 for the exterior product and 192 for the
geometric product. They reproduce 8 for the bilinear form, and 54 and 27 for the
contractions. They reproduce 27 and 54 for the expansions, 16 for a scale and 24 for a
unitize.

The conformal metric is held to 1024 and to 32, and to 243 for each of the four dual
products. A chain of an expansion and an exterior product is held to their sum, 486 at five
dimensions.

The supports are held to 54 at four dimensions, and the centre and the container to 162 at
five. The partner chain is held to 324, and to its mark as an estimate.
Suite `Inspector` holds the soundness law. No lower bound outruns what the library spends
on the same operation. That law reads every measurand of the build's own nimcache.

**What it found.** Every primitive product spends what the algebra demands, and the
operations built on top of them do not. At four dimensions the library stands at the bound
on multiplies for 101 of the 107 operations that carry one. The two supports are what stand
above it, at 162 against 54. At five dimensions it stands at the bound for 110 of the 130
that carry one. The cocarrier, the centre, the container and the partner stand above it.

The attitude and the carrier are generated from a Cayley table, so each spends no multiply,
as the algebra demands. The centre spends 486 against 162, the container 243 against 162,
and the partner 518 against 324. The cocarrier still wedges against a constant that carries
one unit component. So it spends 243 multiplies where the algebra demands none.

On bytes moved the library stands at the bound for 55 of 107 operations at four dimensions,
and for 81 of 130 at five. Those are the operations that one generated function serves,
since that function writes every slot and fills nothing. A chain still fills its
intermediates, and stands above the bound.

At four dimensions the exterior product spends the bound's 81 multiplies and moves the
bound's 384 bytes. The bulk norm spends the bound's 8 multiplies, and moves 640 bytes
against the bound's 136.

At four dimensions 65 operations carry a library function, a bound and a reference. Over
those, reaching the bound closes 58 per cent of the byte distance to the reference. It
closes 24 per cent of the multiply distance. At five dimensions 84 operations carry all
three, and reaching the bound closes 83 per cent and 39 per cent. Without the chains, the
byte shares are 55 and 49 per cent. Those shares rest on one population, so
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
first step leaves whole grades at zero, and the second step reads none of them. That is new
evidence that a chain bound is an estimate.

**What the library spends in time against them.** The runtime baselines of 2026-09-30 time
each dense form beside the library, five alternating runs. The median general measurand runs
×1.00 to ×1.04 its dense form, since most library operators are already one generated table.
The compound operations are not. They run ×2.1 to ×6.1 their dense forms, from the
container at cga5d to the support at rga4d.

Negation and the antigrade selection run ×1.9 to ×2.9, and the norms ×1.3 to ×3.4. The
weight unitizes run faster than their dense forms, ×0.68 to ×0.98, and the bulk unitize
slower, ×1.4 to ×2.3. So a dense form is a measure, and never a lower bound on time.

Rejected: a dense form written by hand for each operation. There are 40 to 47 operations at
each of four algebras, and forms by hand would drift from the library as it moves. The
tables are the library's, so a dense form shares any sign that the library gets wrong. The
chapter suites hold the library to the reference, and the suite below holds the dense form to
the library.

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suites `Dense forms` and `Inspector`. Every
dense form equals the library on the seeded pools, NaN included. The same suite, compiled by
hand at rga3d and cga4d on 2026-09-30, passes there too. The inspector holds each dense form
at the multivector lower bound, or at or below it for a chain. It also holds each one free of
fill, intermediate, copy, call and check.

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

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suite `Gaps`. It covers the gap verdicts on
fixture documents, an unmeasured gap, and docket stability across a reorder and a new key. It
also covers the verdict and evidence of every cause, the rendered width, and rune-counted
wrap.

## Driver

`tools/build.nim` carries `inspect`, `bench`, `baseline`, `guard`, `evaluate`, `pages`,
`published`, `drive`, `gaps`, `show`, `sweep`, `system` and `clean`, dispatched from
`case paramStr(1)`, so koch reads the verbs itself. `system` prints `git`, `curl` and
`coreutils`: git reads the library head, and the other two serve `koch fetch-assets`, which
fetches and checks the faces. `sweep` compiles the bench at two to six dimensions, rigid
metric, and prints the medians of the general measurands. It never runs in CI.

Verified by hand on 2026-09-13. `nim r tools/build.nim drive` exits 0 on the recorded
baselines. Lower the total multiplies of `∧(Multivector,Multivector)` in
`baseline/static_rga4d.json` from 81 to 80, and `guard` exits 1 with the finding below.
Restore it, and the guard returns 0 findings.

```text
baseline/static_rga4d.json:0: Total `multiplies` of `∧(Multivector,Multivector)` grew;
got `81`, baseline `80`.
```

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suite `Driver`: the dispatch, the usage
string and the header table name the same verbs.

## Changes, proposals and evaluations

**A change is Markdown, and quotes what it edits.** Each file in `changes/` holds a title,
why, and one section for each edit: a quote of the library at pin, then its replacement. A
whole-file replacement carries the digest of the file it replaces instead. A quote must occur
once at pin. A line number moves with every library commit, and a quote moves only when its
own lines do. So a change that still applies at head still says what it meant.

**A proposal is one directory, with one shape.** `proposal.md` argues the future state,
`change.md` holds its candidate edits, and `claims.json` names the proposal it builds on and the
claims that its evaluation checks. A claim is data, so the page shows each verdict beside it. The
kinds are `suites`, `tables`, `program`, `count` and `build`. Rejected: a proposal as prose
alone, because nothing could then say whether it still holds at head.

**A proposal keeps its number for good.** Its directory opens with the number, as
`01-cayley-derivation`, and its title with the citation, as `P01`. `drive` holds the numbers
unique and without a gap, so no number goes to a second proposal. A proposal that the library
implements stays, with status `implemented` and the library commit, and a withdrawn one stays
too. `drive` no longer applies either at pin, and each page keeps its last evaluation. So a
citation still leads to what was proposed and measured.

A program claim names its program relative to its proposal, so a new directory name moves no
digest.

**An evaluation measures a copy of the library at pin.** It copies the checkout, applies the edits
(the base proposal first), and measures the copy against the pin. It runs the suites of the
library, reads the static measurements of every function, and times each measurand. The
binaries of the pin and of the copy run alternately, five times each, so drift of the machine
lands on both.

The evaluation then checks the claims. The document names the pin and a digest of what it
tried: every edit, every claim and every program, and never the prose. So an evaluation is current
exactly while its edits are. Evaluations measure the two
typed algebras, rga4d and cga5d, which both lower bounds cover. After `--thorough`, as
`evaluate all --thorough`, they measure rga3d and cga4d as well, as the Architect chose. Those
two carry no reference, so only the multivector lower bound covers them there.

**The spread comes from the evaluations themselves.** An evaluation that changes no library function
moves no count, so the range of its time ratios is the range of the machine. The pages state
the spread beside the figures it qualifies. On 2026-09-29, in this container (linux amd64, 4
cores), those evaluations gave 2 904 ratios, with 90% between ×0.91 and ×1.09.

Measured variance: `typed-multivectors` applies the same library edits as `cayley-derivation`.
Its evaluations on 2026-09-29 and 2026-09-30 gave median ratios over every rga4d measurand of
×1.16, ×1.00, ×1.00, ×1.00 and ×1.01. Over every cga5d measurand, the last four gave ×0.99,
×1.07, ×0.99 and ×1.01. Alternation does not cancel all drift of a shared machine, so one
evaluation's time is weak evidence alone. Counts are exact, and carry the verdicts.

The changes come from edits measured at `bd6b23c` by line range. Converted to quotes, each
one applied at pin gives files byte-identical to the measured edits.
The change of `cayley-derivation` reproduces its draft byte for byte, and
`proposals/02-typed-multivectors/prototype.nim` holds its laws against that draft at rga3d, rga4d
and cga5d.

Verified by `test_rga4d.nim` and `test_cga5d.nim`, suites `Markdown`, `Changes`,
`Proposals`, `Evaluations` and `Cells`. They cover parse, quote and digest rules, and claim
kinds. They cover proposal numbers taken twice or skipped, and the status that freezes a
proposal. They also cover pairing of runs, NaN shares, the success line of the compiler, and
the table serialiser at pin. They cover the algebras that an evaluation measures, with the
flag and without it.
A digest moves with edits, and never with prose.

## Notes

`marginalia/notes.md` holds the notes on library source. Each note quotes the lines it is
about, and the page computes the line number at build from where the quote stands at pin. A
quote that no longer occurs once is a finding.

Verified by suite `Notes`: parse, location at pin, and a stale anchor.

## Pages

**Every page is one shell and one body.** The shell is `pages/shell.html`, committed and
hand-written. The body is rendered in Nim from committed files, so a page says only what those
files say. The faces are the six that `rga_visualiser` embeds, fetched through
`koch fetch-assets` and inlined as base64. Interaction is CSS: tabs, filters and sort are
inputs that `:has()` rules read. The one script is the search box of the docket, and its text
is constant, so the digest of each page still follows those files.

**A proposal can carry a figure.** A paragraph of one image alone, as
`![Derivation map.](../../pages/derivation-map.svg)`, embeds the SVG that it names. The SVG lives
under `pages/`, since the layout admits hand-written markup there alone. Its colours are shell
tokens with fallbacks, so it follows the theme of the page and still reads alone. A figure that
names no file is a finding of `drive`. Rejected: a figure kept outside the repository, because no
page is built from it.

**Marks render as the faces allow.** The left complement is written 𝐜̱, with U+0331, because
the faces draw U+0332 after the letter. In code, ★ comes from the math face as ☆ does, because
the mono face draws ★ smaller.

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

**A publication holds each published page to its build.** `pages/published.json` maps each
page to its URL and to the digest of the page as built when it was published. `drive` builds
every page again, and any page whose digest differs is a finding. `README.md` must name the URL
of every publication, so the two copies of a URL cannot drift apart. Rejected: a page written by
hand, or by a script outside this project, because nothing held it to the files.

Verified by suite `Pages`: assembly fills every token, the spread until evaluations give enough
ratios, and the chip that names removed NaN results. It covers the lower bound each docket row
is measured against, and a general row timed against its dense form. It covers the median of
run ratios with one tick for each run, and a reference that spends none. It covers the rule
that reads each dropdown option, the classes of each row, and the split of a typed id. It
covers the words each row is found by, and the shell rule that hides a row not found. Suite
`Figures` covers the path a figure resolves, the SVG a page embeds, and every rule on the map.

## Library head

**`drive` holds the pin to library head.** It reads the head of the library repository with
`git ls-remote`, and compares the tree of the library directory at head with its tree at pin.
A commit elsewhere in the repository changes nothing measured, so the check compares trees, not
commits. A pin that lags head is a finding on every push until the pin follows, as the
Architect chose. So each page shows the library as it stands.

**`drive` holds every measurement and file to the pin.** Each baseline and each evaluation must be
taken at the pin. Each evaluation must carry the digest of its edits as they are now. Each change
and proposal must apply at pin, and each note must find its quote.

**`drive` holds the checkout to the pin.** Any edit under the library directory of the
checkout is a finding. The checkout is under `dependencies/`, which git ignores, so a tool
that runs over this project reaches it too. A quote would then match text that the pin does
not hold.

Cost: the verdict of `drive` depends on the library repository as well as on this project.
The same commit here can pass today and fail after the library moves. That is the purpose of
the check, and it departs from the rule that a check gives the same verdict on the same code.

Verified by suite `Head`: tree against commit, stamps, digests of edits, the publications and
the README.

## Dependencies

**The PGA library is a pinned dependency, and never a copy.** It lives in [replications],
which carries no nimble file and holds the library three directories inside it. So the
requirement in `pga_benchmark.nimble` names the repository by URL and commit. `atlas.lock`
records the resolved commit `bd6b23c590d7e1da91a1ea288a1a4b94dedbf315`, and `nim.cfg` names
the subdirectory that Atlas restores it to.

That commit is the head of the library on 2026-09-28, as the standing instruction of the
Architect asks. Both projects are under the Prosperity Public License 3.0.0. Rejected: a copy
of the library in this tree, which Article XI.3 forbids.

**The pin never held `181c8d8`.** There `merge` added a term without its negation when
`as_negated` was set, so `e12 ⟑ e12` gave +1. That flipped 60 of the 384 terms of the
geometric product at 4D. Suite `Chapter 3` failed on it, through the motor product against
its reference, and the suites of the library passed. `16dbc17` fixes it, and the pin follows
from there.

**The bump from `0bc4655` moved the pin over two library changes that this project had to
follow.** The library made the grade table private and read it from a generic `{}`. The umbrella
module then failed to compile for every importer. The line `import pga` alone was enough to
fail.

The library then exported the table in `9f9019b`. The suites of the library did not
catch this, because they import each module with `{.all.}` and never read the umbrella. The
library also gained two operators, `|∙²` and `|∘²`, so the catalogue gained a measurand for
each one. Verified by `test_rga4d.nim` and `test_cga5d.nim`, suite `Catalogue`, which holds the
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

Every figure below that names no other commit was taken on 2026-09-28, in the container of
that session: `linux amd64, 4 cores`, a shared cloud machine. It ran on the pinned compiler
and on library `bd6b23c`, with
`-d:release`. Runtime measurements are medians over 40 rounds of 1024 objects, from
`nim r tools/build.nim bench`, in nanoseconds for each object. Static measurements are from
`nim r tools/build.nim inspect`, and are exact for this compiler commit, with loop trips
weighted.

**The reference side is the drift control.** The bump of the pin does not touch the
reference, because the reference is the code of this project. The baselines of 2026-09-24
and 2026-09-28 are the pair. Over it the reference medians moved by ×0.94 at rga4d and by
×0.73 at cga5d. So the machine gave back more than it did four days before.

Over the same pair the library medians moved by ×0.83 and ×0.59. Read the two sides
together, and never one alone. The interleaved pair below is the figure that the bump
itself moved.

| Gap (rga4d) | Library ns | Reference ns | Mul | Div | Bytes moved | Checks |
|---|---|---|---|---|---|---|
| `wedge_point_point` (`∧`) | 24.4 | 3.4 | 81 / 12 | 0 / 0 | 384 / 112 | 0 / 0 |
| `wedge_dot_anti_motor_motor` (`⟇`) | 50.6 | 13.8 | 192 / 48 | 0 / 0 | 384 / 256 | 0 / 0 |
| `transform_point_motor` (three products) | 138.6 | 6.9 | – / 25 | – / 0 | – / 192 | – / 8 |
| `norm_bulk_point` (`\|∙`) | 11.7 | 1.8 | 8 / 3 | 0 / 0 | 640 / 40 | 1 / 1 |
| `norm_bulk_squared_point` (`\|∙²`) | 4.3 | 0.7 | 8 / 3 | 0 / 0 | 256 / 40 | 0 / 0 |
| `unitize_point` (`^`) | 5.2 | 1.2 | 24 / 3 | 1 / 1 | 512 / 128 | 1 / 0 |
| `support_line` (`∩`) | 56.3 | 2.1 | 162 / 9 | 0 / 0 | 1280 / 112 | 3 / 1 |
| `attitude_point` (`⊖`) | 4.2 | 0.5 | 0 / 0 | 0 / 0 | 256 / 40 | 0 / 0 |
| `project_orthogonal_point_plane` | 46.1 | 4.4 | 135 / 14 | 0 / 0 | 1152 / 128 | 2 / 0 |

| Gap (cga5d) | Library ns | Reference ns | Mul | Div | Bytes moved | Checks |
|---|---|---|---|---|---|---|
| `wedge_round_point_round_point` (`∧`) | 58.0 | 4.4 | 243 / 20 | 0 / 0 | 768 / 160 | 0 / 0 |
| `center_dipole` (`⊙`) | 100.2 | 2.4 | 486 / 16 | 0 / 0 | 3584 / 160 | 4 / 1 |
| `partner_circle` (`⊛`) | 137.4 | 3.4 | 518 / 29 | 0 / 0 | 30720 / 320 | 271 / 2 |
| `carrier_sphere` (`⊟`) | 6.1 | 0.4 | 0 / 0 | 0 / 0 | 512 / 48 | 0 / 0 |

**What the bump moved in the counts, over the functions that both commits hold.** The pair
is the static baseline of `6a91c3f` against the static baseline of `bd6b23c`, 123 functions
at rga4d and 141 at cga5d.

| Count (common functions) | rga4d | cga5d |
|---|---|---|
| Zero fills | 74 → 72 | 308 → 294 |
| Bytes moved | 30832 → 30064 | 100432 → 93776 |
| Error-flag checks | 141 → 139 | 619 → 612 |
| Calls | 143 → 141 | 683 → 676 |
| Lines of C | 3165 → 3163 | 8594 → 8503 |
| Multiplies | 2204 → 2123 | 9173 → 7958 |
| Divisions | 6 → 6 | 2 → 2 |
| Inline functions | 117 → 115 | 134 → 130 |

The attitude and the carrier are now generated, so they spend no multiply. The container
and the partner read the carrier, so they lose half of theirs. The unitizes read the squared
norm, and make one call where they made two. The chains are no longer inline.
`∪` builds its constant `𝐞̄ₙ` with a `let`, so at runtime it calls `initElement` and moves
512 more bytes. A `const`, as `∩` already uses, would fold that constant at build time.

**What the bump moved in time.** The pristine bench of `6a91c3f` and the patched bench of
`bd6b23c` ran alternately, nine times each, and each measurand compares on medians. Noise
puts one measurand between ×0.92 and ×1.08, and a median over a whole run between ×0.98 and
×1.01. A measurand under 15 ns can move further. In runs whose patch changes no count,
`normalize_bulk` at rga4d moves between ×0.81 and ×1.20. The patched library passes its own
suites, 33 at rga4d and 28 at cga5d.

| Measurand | rga4d | cga5d |
|---|---|---|
| Median over touched measurands | ×0.35 | ×0.57 |
| `attitude` (`⊖`) | ×0.11, 29.8 → 3.4 ns | ×0.11, 76.9 → 8.6 ns |
| `carrier` (`⊟`) | | ×0.10, 79.5 → 8.1 ns |
| `container` (`⊡`) | | ×0.53 |
| `partner` (`⊛`) | | ×0.58 |
| `carrier_co` (`⊞`) | | ×0.58 |
| `center` (`⊙`) | | ×0.87 |
| `unitize` (`^`, `^∘`) | ×0.32 | ×0.65 |
| `normalize_bulk` (`^∙`) | ×1.19, 9.4 → 11.3 ns | ×0.78 |
| `support_anti` (`∪`) | ×1.23, 54.5 → 67.2 ns | |
| Measurands slower than ×1.08 | 13 of 111 | 1 of 131 |

The attitude and the carrier now run as maps of moves and signs. The cocarrier, the centre,
the container and the partner are no longer inline. At `6a91c3f` that pragma made the
chains slower, the cocarrier by ×1.72 and the attitude by ×1.47. `∪` is slower
because of its runtime constant.

The other slower measurands run under 14 ns, and their counts did not grow, so they read as
noise. `^∙` at rga4d is one of them. Over eleven runs whose patch changes no count, the
pristine bench of `bd6b23c` alone timed it between 9.1 and 11.4 ns. That range holds the
9.4 ns of `6a91c3f`.

**A candidate library, measured.** A draft of `cayleys.nim` on `bd6b23c` makes each
`Cayley1D` cell a `seq`, and adds `applyConstant`, `applyMap` and `constructAnti` in place of
five special cases. Every table comes back cell for cell at four algebras, 136 tables, and
`∩ ∪ ⊞ ⊙ ⊡` are one generated table each. No pin holds the draft.

The draft hard codes three tables: the metric, the wedge and the complement. Every
anti-variant is `constructAnti` of its base, the antiproduct included. The four dual products
are one dual fed into a wedge or antiwedge. The dot is the scalar part of the bulk
contraction, and the transwedge keeps one family, for ⟑ alone. Every table is unchanged at
five algebras, and a suite holds the order gr 𝐚 identity. At 6D the front end builds in
4.56 s against 6.62 s, ×0.69 over five rounds, and peaks at 161 MB against 288 MB.

Grade restriction lives in the emission, by decision of the Architect: a typed operand names
its slots, and the tables stay whole. One restricted copy of a 2D table costs 0.9 MB at 6D.

The pristine bench of `bd6b23c` and the bench of the draft ran alternately, nine times each,
on this container on 2026-09-28. The library suites pass, 33 at rga4d and 28 at cga5d, and
this project's suites pass, 105 and 118. The 6D front end builds in 6.37 s against 6.11 s,
×1.04 over five rounds whose spreads overlap.

| Measurand | Multiplies | Bytes moved | Time |
|---|---|---|---|
| `∩` support, rga4d | 162 → 54 | 1 280 → 256 | 56 → 12 ns, ×0.22 |
| `∪` antisupport, rga4d | 162 → 54 | 1 792 → 256 | 68 → 12 ns, ×0.18 |
| `⊞` cocarrier, cga5d | 243 → 0 | 2 048 → 512 | 44 → 8 ns, ×0.18 |
| `⊙` centre, cga5d | 486 → 162 | 3 584 → 512 | 115 → 38 ns, ×0.33 |
| `⊡` container, cga5d | 243 → 162 | 2 560 → 512 | 68 → 40 ns, ×0.59 |
| `⊛` partner, cga5d | 518 → 437 | 30 720 → 28 672 | 170 → 128 ns, ×0.75 |

Against the bounds above, the draft stands at the multiply bound for 107 of 107 operations
at four dimensions. At five it stands there for 125 of 130, and the five left are the
partner and its typed forms, which still scan the grade. On bytes it stands at the bound for
61 of 107 and 96 of 130. Above the byte
bound remain the scalar-valued products, the norms and the unitizes, which each hand back a
whole multivector. The chains with intermediates and the two hand-written sums remain too.

The emitted C of the library at 4D:

- `∧` is one inline function of 16 lines, 81 multiplies, no zero fill, no error-flag branch
  and 384 bytes moved, which is its bound. It held 1090 lines and 178 branches at `0bc4655`;
- `|∙²` is 16 lines and 8 multiplies, inline, with no zero fill and 256 bytes moved. Its
  unsquared partner `|∙` is 29 lines, inline, with two zero fills and 640 bytes, because it
  takes a square root through a call;
- `^∘` (unitize) spends 24 multiplies and 1 division over 75 lines, with 1 branch left,
  where the reference takes one reciprocal and 8 multiplies;
- `⊖` (attitude) is 16 lines, inline, with no multiply, no zero fill and 256 bytes moved,
  which is its bound;
- `⊛` at cga5d is the widest function in the tree. It spends 2710 lines, 518 multiplies,
  108 zero fills, 271 branches and 30720 bytes moved. Its reference spends 29 multiplies;
- 115 of 124 library functions at rga4d are inline.

Allocation is zero on every measurand, in both implementations, with the gauge live.

Scaling comes from `nim r tools/build.nim sweep`, rigid metric, general measurands. At two to
six dimensions, `∧` is 2.9, 7.8, 55.0, 73.4, 203.4 ns. `⟑` is 3.8, 14.2, 106.6, 177.1, 1383.4
ns, and `norm` is 4.1, 7.8, 60.2, 50.5, 92.8 ns. The 4D column of the sweep ran hot against
the bench, so the shape is the figure, and not the values. These numbers are from library
`0bc4655` on 2026-09-13. Nobody swept the library again at `bd6b23c`, because the sweep runs
by hand, so read them as the shape alone.

Error checks under `--panics:on` were measured at library `0bc4655` by a compile of the bench
entry with `--compileOnly`, and a count in its C. `∧` at 4D fell from 178 branches and 1090
lines to 0 and 551. That figure is now mostly spent. At `bd6b23c` the default build emits no
branch in `∧`. It emits 139 branches over the whole of rga4d, where it emitted 4388.

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

**Generated operators write each zero element, and hand-written functions leave theirs to the
default fill.** A generated operator writes every element as a straight statement, zeros
included, because generation lowers a Cayley table and nobody writes the zeros by hand. The
default fill there would cost a geometric mean of ×1.07 to ×1.23 from four dimensions up. A
hand-written function, such as a norm, writes no zero. The Architect decided this, because the
library is about PGA and not about micro-optimisation.

Each function that a Cayley table can express moves to generation, and so gets its zeros
unrolled at no cost. At the pin `bd6b23c` the library works this way, and its attitude and
carrier are generated. The cost that stays is what the hand-written norms pay.

The cost was measured at library `181c8d8`, with the sign of `merge` fixed, on 2026-09-25.
Each function was called through a volatile procedure pointer, so its body compiled alone and
wrote to memory that it could not see. Each figure comes from two passes, and each pass is the
median of nine runs of 41 rounds over 1024 objects. Functions that did not change varied by
±3%.

For the norms, a cell gives nanoseconds with the default fill, then with straight stores that
write the zeros first. The cell is the lower of the two passes:

| Norm | rga2d | rga3d | rga4d | rga5d | cga4d | cga5d | cga6d |
|------|-------|-------|-------|-------|-------|-------|-------|
| `|∙` | 2.6 / 2.6 | 3.9 / 3.9 | 13 / 7.0 | 34 / 12 | 16 / 9.4 | 53 / 24 | 109 / 76 |
| `|■` | | | | | 16 / 9.3 | 53 / 25 | 109 / 76 |
| `|∘` | 2.6 / 2.6 | 4.6 / 4.6 | 14 / 7.2 | 34 / 12 | 17 / 9.7 | 55 / 26 | 114 / 90 |
| `|□` | | | | | 17 / 9.7 | 55 / 26 | 105 / 90 |
| `|` | 4.0 / 3.7 | 5.9 / 5.6 | 24 / 15 | 58 / 46 | 31 / 22 | 86 / 74 | 163 / 150 |

The fill loses from four dimensions up, where a result holds 128 bytes or more. There gcc
emits the fill as `rep stos` under its generic tuning for x86-64. At the pin `^∙` and `^∘`
take the root of `|∙²` or `|∘²`, and do not build the norm. Alone at `181c8d8`, that change
ran at ×0.55 to ×0.93 in all seven algebras. Issue #285 proposes a rule for Article VII from
these measurements.

## Known limitations

- Evaluations time the two typed algebras unless `--thorough` asks for rga3d and cga4d too.
  The evaluations committed now measure the typed algebras only.
- The `build` claim reads the peak memory and seconds that the compiler reports of itself.
  It compares two builds on one machine, and is no measurement of the machine.

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
- The bench writes each result into a local array that it fills with zeros once. So the
  compiler sees that memory, and deletes each store of zero that repeats the fill. A result
  with many zero elements then reads faster in the bench than it runs elsewhere. The bias
  touches every figure that compares a fill with written zeros, among them two open
  questions below. Timed alone at `181c8d8`, those functions do not lose when they write
  every element.

## Open questions

- Whether `--panics:on` is a build that the library will stand behind. The other way to drop
  the checks is to make the operators call nothing. One way is to read the components
  directly, rather than through `[]`.
- The reference is not yet optimal on the Nim side. `rotate` and `transform` still zero-fill
  a `Vector3` result, and pay a branch for each helper call under the default flags. To write
  their components directly would lower the reference figures further.
- Whether the 2D references (rga3d, cga4d) are worth a derivation. Their gaps carry library
  counts and absolute verdicts only.
- Why the write-once unitize shapes run three times slower than the in-place one under
  `-d:release`, in the reciprocal experiment above.
- Why the unary part extractions at cga5d lost ×1.1 to ×1.4 at `6a91c3f`. There they began
  to write every slot, and the same change won ×0.25 at rga4d. The byte model says they move
  less, so the cause is outside it.
- Why `contract_bulk` (`∨★`) at rga4d runs ×1.33 slower once it writes every slot, while every
  other generated product holds or wins.
- Whether the sign of the partner folds into its first table by the grade of each term.
  That is exact under the homogeneity the partner already asserts. It would take the partner
  from 437 multiplies and 104 fills to its chain bound of 324. Unmeasured.
- Why the weight unitizes of the library run faster than their dense forms, ×0.68 to ×0.98,
  while the bulk unitize runs slower, ×1.4 to ×2.3. The library scales every slot in a loop,
  which the compiler may vectorise, where the dense form spells each slot. Unmeasured.
- Whether a product whose terms all land in one slot should return a `float` from the
  emitter. At four dimensions 26 measurands stand above the byte bound for that reason
  alone.

[replications]: https://gitlab.com/mraxilus/replications
[terathon]: https://github.com/EricLengyel/Terathon-Math-Library
