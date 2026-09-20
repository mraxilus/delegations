# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude Fable 5.1 |
| Date    | 2026-09-13 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 0bbac90808d8b78b |
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
records the resolved commit `0bc465509d1c93b6bec3ced25aa29f080a2cf110`, and `nim.cfg` names
the subdirectory that Atlas restores it to.

That commit is the head of the library on 2026-09-12, as the standing instruction of the
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

Every figure below was taken on 2026-09-13, in the container of that session: `linux amd64, 4
cores`, a shared cloud machine. It ran on the pinned compiler and library head, with
`-d:release`. Runtime measurements are medians over 40 rounds of 1024 objects, from
`nim r tools/build.nim bench`, in nanoseconds for each object. They move by tens of percent
between runs on this machine. The sweep below timed 4D `∧` at 55 ns where the bench timed 35
ns, so they rank and do not measure. Static measurements are from
`nim r tools/build.nim inspect`, and are exact for this compiler commit, with loop trips
weighted.

| Gap (rga4d) | Library ns | Reference ns | Mul | Div | Bytes moved | Checks |
|---|---|---|---|---|---|---|
| `wedge_point_point` (`∧`) | 29.7 | 2.8 | 81 / 12 | 0 / 0 | 512 / 112 | 178 / 0 |
| `wedge_dot_anti_motor_motor` (`⟇`) | 51.1 | 11.6 | 192 / 48 | 0 / 0 | 512 / 256 | 400 / 0 |
| `transform_point_motor` (three products) | 113.6 | 5.9 | – / 25 | – / 0 | – / 192 | – / 8 |
| `norm_bulk_point` (`\|∙`) | 12.1 | 1.8 | 8 / 3 | 0 / 0 | 768 / 40 | 20 / 1 |
| `unitize_point` (`^`) | 25.0 | 1.2 | 8 / 3 | 16 / 1 | 1152 / 128 | 54 / 0 |
| `support_line` (`∩`) | 95.3 | 2.1 | 162 / 9 | 0 / 0 | 1664 / 112 | 375 / 1 |
| `project_orthogonal_point_plane` | 94.9 | 4.8 | 135 / 14 | 0 / 0 | 1408 / 128 | 304 / 0 |

| Gap (cga5d) | Library ns | Reference ns | Mul | Div | Bytes moved | Checks |
|---|---|---|---|---|---|---|
| `wedge_round_point_round_point` (`∧`) | 58.4 | 3.6 | 243 / 20 | 0 / 0 | 1024 / 160 | 518 / 0 |
| `center_dipole` (`⊙`) | 209.0 | 3.7 | 486 / 16 | 0 / 0 | 4352 / 160 | 1104 / 1 |
| `partner_circle` (`⊛`) | 399.6 | 4.3 | 1004 / 29 | 0 / 0 | 34560 / 320 | 2569 / 2 |
| `carrier_sphere` (`■`) | 87.3 | 0.3 | 243 / 0 | 0 / 0 | 1792 / 48 | 519 / 0 |

The emitted C of the library at 4D:

- `∧` is one function of 1090 lines, 81 multiplies, 65 adds, one full-width zero fill and 178
  error-flag branches;
- `|` (norm) spends 16 multiplies, but zero-fills nine times and declares four intermediates,
  and moves 1920 bytes for two doubles;
- `^∘` (unitize) spends 8 multiplies and 16 divisions, through a loop that calls `[]` and
  `/=` for each slot with a branch after each. That is 54 branches in all, where the
  reference takes one reciprocal and 8 multiplies;
- `scale` spends 16 multiplies, and `add` spends 48 branches for one loop of sixteen;
- six of forty library functions are inline.

Allocation is zero on every measurand, in both implementations, with the gauge live.

Scaling comes from `nim r tools/build.nim sweep`, rigid metric, general measurands, same
method, same day. At two to six dimensions, `∧` is 2.9, 7.8, 55.0, 73.4, 203.4 ns. `⟑` is
3.8, 14.2, 106.6, 177.1, 1383.4 ns, and `norm` is 4.1, 7.8, 60.2, 50.5, 92.8 ns. The 4D
column of the sweep ran hot against the bench, so the shape is the figure, and not the
values.

Error checks under `--panics:on` were measured by a compile of the bench entry with
`--compileOnly`, and a count in its C. `∧` at 4D falls from 178 branches and 1090 lines to 0
and 551. The `rotate` of the reference falls from 6 branches and one zero fill to none. That
switch makes defects fatal, so whether the users of the library may take it is the call of
the Architect. The guard measures the default.

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
