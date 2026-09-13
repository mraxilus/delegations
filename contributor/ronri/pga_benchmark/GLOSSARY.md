# pga_benchmark

Benchmark and gap list holding `pga` to Lengyel's typed reference: what is measured, on what,
and how far each measurement sits from its target. The repository's own words are in the root
glossary; only what is specific to this project is defined here.

## Language

**Measurand**:
One catalogued operation on stated operand kinds, e.g. `∧` on Point and Point; the unit
everything here measures.
_Avoid_: probe, case, operation, op, benchmark case

**Catalogue**:
The compile-time list of every measurand for one algebra, walked by every instrument so
nothing is benchmarked by hand.
_Avoid_: table, manifest, inventory, list

**Expression**:
The library code a measurand evaluates over `m` and `n`, e.g. `(m ∧ n)`.
_Avoid_: spell, formula, call, form

**Reference**:
Lengyel's hand-rolled typed form a measurand is measured against, written in Nim here from
the book.
_Avoid_: typed form, optimal form, oracle, ground truth

**Kind**:
What a measurand's operand is: General (dense, mixed grade), Scalar, or one typed object
such as Point.
_Avoid_: type, shape, class

**Implementation**:
Which of the two is measured: the library's dense operator, or the reference.
_Avoid_: side, party, subject, control

**Widen / narrow**:
Putting a typed object into the dense multivector's basis slots, and reading it back out;
narrowing asserts the other slots are zero.
_Avoid_: bridge, embed, extract, lift, convert

**Measurement**:
One timing or count of a measurand, with its taking: machine, method, date.
_Avoid_: figure, reading, sample, result

**Static measurement**:
A count read from the C the compiler emits: multiplies, adds, subtractions, divides, zero
fills, intermediates, copies, error checks, calls, and the bytes moved modelled from them.
_Avoid_: inspect document, counts, static analysis

**Runtime measurement**:
A timing, allocation count or NaN share taken by running the measurand over its pool.
_Avoid_: bench document, timing, benchmark result

**Movement**:
The bytes one call moves, modelled from static measurements: operands read, result written,
zero fills, whole-object copies, intermediates. Named bytes, never cache traffic.
_Avoid_: traffic, footprint, memory cost

**Intermediate**:
A local full-width multivector a library function declares and zero-fills mid-chain.
_Avoid_: temporary, scratch, local

**Baseline**:
The committed static measurements the guard compares a fresh reading against; moved only by
the `baseline` verb after an intended change.
_Avoid_: snapshot, golden, expected, recorded

**Guard**:
The verb that fails on any static measurement or bytes moved grown against the baseline;
what `drive` runs in CI.
_Avoid_: gate, check, regression test

**Gap**:
One measurand of one algebra, with both implementations' measurements and a stable `G`
number.
_Avoid_: row, finding, entry

**Cause**:
One design-level reason many gaps are over, decided by a rule over the documents with its
evidence, and carrying a `D` number.
_Avoid_: design gap, theme, issue, root cause

**Over / met / unmeasured**:
A gap's or cause's verdict: the library exceeds a target, meets every target, or has
nothing to decide on.
_Avoid_: open, closed, failing, passing

**Tolerance**:
The factor a runtime measurement may exceed its reference by before a gap is over on time.
_Avoid_: time band, slack, margin, noise band

**Docket**:
The committed map from a gap's key to its number, allotting the next number to a new key
and reusing none.
_Avoid_: ledger, register, index, roll, numbering

**Algebra**:
One measured setting, a dimension count and a metric, e.g. `rga4d`.
_Avoid_: configuration, config, target, signature
