# pga_benchmark

Benchmark and gap list that holds `pga` to Lengyel's typed reference: what is measured, on
what, and how far each measurement sits from its target. The words of the repository itself
are in the root glossary. Only what is specific to this project is defined here.

## Standards

The root glossary holds the default standards, and this project has selected none of its own.

## Language

**Measurand**:
One catalogued operation on stated operand kinds, such as `∧` on Point and Point. It is the
unit that everything here measures.
_Avoid_: probe, case, operation, op, benchmark case

**Catalogue**:
The compile-time list of every measurand for one algebra. Every instrument walks it, so
nothing is benchmarked by hand.
_Avoid_: table, manifest, inventory, list

**Expression**:
The library code that a measurand evaluates over `m` and `n`, such as `(m ∧ n)`.
_Avoid_: spell, formula, call, form

**Reference**:
The hand-rolled typed form of Lengyel that a measurand is measured against, written here in
Nim from the book. It is the type optimised lower bound.
_Avoid_: typed form, optimal form, oracle, ground truth

**Lower bound**:
What a measurand cannot spend less than. Each one carries two, and the library stands above
both.
_Avoid_: floor, ceiling, target, minimum, best case

**Multivector lower bound**:
The arithmetic and movement that the algebra demands of any implementation over a dense
multivector, derived from the axioms rather than measured.
_Avoid_: dense floor, dense bound, representation bound

**Type optimised lower bound**:
What the typed reference spends, which needs a representation that a dense multivector
cannot reach. It is measured rather than derived.
_Avoid_: typed floor, sparse bound, reference bound

**Shape**:
The arithmetic form of one operation, such as Wedge, Geometric or Norm. Each shape carries the
rule that derives its multivector lower bound.
_Avoid_: form, pattern, product type

**Chain**:
An operation that the library composes from several operators, as a projection is a dual
product and then a full product. Its multivector lower bound sums what each step demands, so
it is an estimate and never a proved minimum.
_Avoid_: composed operation, compound operation, composite, pipeline

**Kind**:
What the operand of a measurand is: General (dense, mixed grade), Scalar, or one typed
object such as Point.
_Avoid_: type, class

**Implementation**:
Which of the three is measured: the dense operator of the library, the reference, or the dense
form.
_Avoid_: side, party, subject, control

**Dense form**:
The straight-line implementation of a general measurand, generated from the tables of the
library. It assigns each slot once as the sum of its terms, with no fill, no intermediate and no
call. A general row is timed against it, as a typed row is timed against its reference.
_Avoid_: dense reference, bound form, oracle

**Widen / narrow**:
To put a typed object into the basis slots of the dense multivector, and to read it back
out. A narrow asserts that the other slots are zero.
_Avoid_: bridge, embed, extract, lift, convert

**Measurement**:
One timing or count of a measurand, with how it was taken: machine, method, date.
_Avoid_: figure, reading, sample, result

**Static measurement**:
A count read from the C that the compiler emits. It covers multiplies, adds, subtractions,
divides, zero fills, intermediates, copies, error checks and calls, and the bytes moved that
are modelled from them.
_Avoid_: inspect document, counts, static analysis

**Runtime measurement**:
A timing, an allocation count or a NaN share, taken by a run of the measurand over its
pool.
_Avoid_: bench document, timing, benchmark result

**Movement**:
The bytes that one call moves, modelled from static measurements: operands read, result
written, zero fills, whole-object copies, intermediates. It is named bytes, and never cache
traffic.
_Avoid_: traffic, footprint, memory cost

**Intermediate**:
A local full-width multivector that a library function declares and zero-fills
mid-chain.
_Avoid_: temporary, scratch, local

**Baseline**:
The committed static measurements that the guard compares a fresh reading against. Only the
`baseline` verb moves it, after an intended change.
_Avoid_: snapshot, golden, expected, recorded

**Guard**:
The verb that fails on any static measurement or bytes moved that grew against the
baseline. It is what `drive` runs in CI.
_Avoid_: gate, check, regression test

**Gap**:
One measurand of one algebra, with the measurements of both implementations and a stable
`G` number.
_Avoid_: row, finding, entry

**Cause**:
One design-level reason that many gaps are over, decided by a rule over the documents with
its evidence, and carrying a `D` number.
_Avoid_: design gap, theme, issue, root cause

**Over / met / unmeasured**:
The verdict of a gap or a cause. The library exceeds a target, meets every target, or has
nothing to decide on.
_Avoid_: open, closed, failing, passing

**Tolerance**:
The factor that a runtime measurement may exceed its reference by, before a gap is over on
time.
_Avoid_: time band, slack, margin, noise band

**Spread**:
The range that holds 90% of the time ratios in evaluations that change no library function. A
time ratio outside it counts as moved.
_Avoid_: noise band, noise floor, jitter

**Docket**:
The committed map from the key of a gap to its number. It allots the next number to a new
key, and reuses none.
_Avoid_: ledger, register, index, roll, numbering

**Publication**:
The URL of one published page, with the digest of that page as built when it was published.
`pages/published.json` holds one publication for each page.
_Avoid_: register, ledger, listing

**Shell**:
The hand-written HTML that every page is built in, `pages/shell.html`.
_Avoid_: template, layout

**Change**:
A small proposed edit to the library: one Markdown file in `changes/` that says why, then quotes
each edit with its replacement.
_Avoid_: patch, fix, diff, case

**Proposal**:
A future state of the library, explored before the Architect adopts it. One directory in
`proposals/` holds its argument, its candidate change and its claims. Its number stays its own,
cited as `P01`, and its status is proposed, implemented or withdrawn.
_Avoid_: design, plan, RFC

**Evaluation**:
What a change or a proposal measured when tried on a copy of the library at pin. One document
in `evaluations/` holds it.
_Avoid_: trial, experiment, validation, run

**Claim**:
One statement of a proposal that its evaluation checks, such as "tables equal".
_Avoid_: assertion, promise

**Note**:
A remark on library source, anchored by a quote. `marginalia/notes.md` holds every note.
_Avoid_: annotation, comment

**Quote**:
Lines of the library at pin that a change edits or a note is about. A quote never gives a line
number, since a line number moves with every library commit.
_Avoid_: anchor, snippet, hunk

**Library head**:
The newest commit of the library repository. The pin must hold the same library tree.
_Avoid_: reference head, latest

**Restamp**:
Move the stamp of a runtime measurement to a new pin, where every build it was taken on emits
the same C there.
_Avoid_: carry, port, rebase, re-pin

**Algebra**:
One measured setting, a dimension count and a metric, such as `rga4d`.
_Avoid_: configuration, config, target, signature

**Magnitude**:
The pair x𝟏 + y𝟙 of a scalar and an antiscalar, as Lengyel's wiki names it. Under the rigid
metric it is a dual number, and under the conformal metric a complex number.
_Avoid_: dual number
