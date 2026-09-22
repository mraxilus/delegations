# pga_benchmark

Benchmark and gap list that holds `pga` to Lengyel's typed reference: what is measured, on
what, and how far each measurement sits from its target. The words of the repository itself
are in the root glossary. Only what is specific to this project is defined here.

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

**Kind**:
What the operand of a measurand is: General (dense, mixed grade), Scalar, or one typed
object such as Point.
_Avoid_: type, shape, class

**Implementation**:
Which of the two is measured: the dense operator of the library, or the reference.
_Avoid_: side, party, subject, control

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

**Docket**:
The committed map from the key of a gap to its number. It allots the next number to a new
key, and reuses none.
_Avoid_: ledger, register, index, roll, numbering

**Algebra**:
One measured setting, a dimension count and a metric, such as `rga4d`.
_Avoid_: configuration, config, target, signature
