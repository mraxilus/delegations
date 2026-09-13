# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude Fable 5.1 |
| Date   | 2026-09-13 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 3497e71b8d327cfa |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: the Architect audited `pga` (head `0bc4655`) in the session that opened this
project, measuring a dense-representation cost of about nine times a hand-written sparse
product at 4D, zero-filled temporaries on every operator chain, no cross-module inlining,
per-term error-flag checks, dead compile-time Cayley work and conformal norms returning NaN.
This project turns that audit into a standing instrument: the gap list the Architect reads
while improving the library, and the benchmark plus C inspection that shows nothing
regressed. Authority replicated: Lengyel's equations, through the library's own suites and
through the typed reference here. No vendored source. The list itself is `gaps.md`,
generated and committed; its identifiers live in `baseline/ledger.json`.

## Catalogue

Every operation the library exports is one `Probe` value built at compile time under the
same `when` the library selects its algebra with, so one list serves every configuration.
A general row spells each exported operator over dense multivectors; a typed row spells the
same operator over the operands Lengyel's reference has a form for, and names that form;
three composed rows spell the motor sandwich the library has no operator for. Spells are
strings, fully parenthesised because the library's own header warns that `∨` parses
additive and `∧` multiplicative, and are lowered by `parseExpr` where probes are emitted.
`^` is a template over `^∘` in the library, so the C carries only the latter; `TEMPLATES`
records the pair and the suite holds it to the library's source. `MISSING` names the two
conformal norms the library declares as errors.

*Checked.* Suite `Catalogue`: ids unique; every spell compiles against the library; the set
of symbols equals the set of exported operators read out of `pga/operators.nim` and
`pga/multivectors.nim`; the set of aliases equals the umbrella's exports.

## Reference

`reference/rigid3.nim` (4D, rigid) and `reference/conformal3.nim` (5D, conformal) are
Lengyel's typed objects and optimal forms written in Nim, in 64-bit floats so both sides run
the same scalar. Every operation was derived from the book's equations and the library's
own definitions; the Terathon Math Library was read as a cross-check of forms and counts
and nothing of it was copied. Where the library's sign conventions differ from Terathon's
the library's were adopted, since the library is what is measured: the bulk and weight
duals of points and planes carry the opposite sign, the conformal antidot is the negated
dot, and the cocarrier of a circle reads `FlatLine(v: -g.xyz, m: -c.v)`. Terathon's
`Partner(Circle)` scalar carries a sign typo; the form here is `f = gw² - v·v - g·m`, which
the law suite confirms against the library. Every form is `{.inline.}`, so it lands in the
same nimcache as the library's operators and is counted by the same reader. Object
construction goes through `zero3` and `read3` templates rather than `Vec3()` defaults and
whole-object field copies, because on the pinned commit the former costs about 4 ns and the
latter about 20 ns through the `=dup` hook, which would have hidden the library's cost.

*Checked.* Suites `Chapter 2` (72 laws at 4D) and `Chapter 3` (91 laws at 5D): for every
typed probe and 64 seeded samples, the reference embedded through the bridge equals the
library within `=~`, each check citing its equation or wiki page. Suite `Inspector` reads
the test binary's own nimcache and finds `wedge(Point,Point)` spending twelve multiplies and
six subtractions, as its documentation states.

## Bridge and pools

The bridge embeds each typed object into the dense multivector at its basis slots and
extracts it back, asserting under `-d:testing` that every other slot is zero. Pools are
filled once from `randomize(0)`: dense multivectors of every grade, typed objects in general
position, lines and planes joined from points, motors unitized; every typed pool has a
dense image so the two sides read equivalent operands.

*Checked.* Suites `Chapter 2` and `Chapter 3` run through the bridge; suite `Probes` runs
every probe over the pools.

## Probes and bench

`emitProbes` turns the catalogue into one timed loop per probe per side. Operands are
template aliases into pool slots, never copies, so the loop moves only the operation's own
traffic; every result is folded into one sink after timing so nothing is dead; the share
of results carrying NaN is counted, since the library's conformal norms return NaN on real
objects and that is measured rather than stated. `bench` runs `ROUNDS` rounds over
`OBJECTS` objects and reports median and minimum nanoseconds per object. The allocation
gauge is live only under `-d:nimAllocStats`, and the bench refuses to report allocation
counts unless a positive control raised the counter first, so a zero means zero and never
an inert instrument (Article VII.4). The plain build reports the gauge as off: that is the
figure taken once compiled out.

*Checked.* Suite `Probes`: `summarise` on fixture rounds; a 3-round, 64-object run gives
finite positive nanoseconds and a non-zero sink. Suite `Allocation`: the positive control
raises the counter, then no probe allocates over a preallocated loop.

## Inspector and movement model

The inspector reads the C the compiler emits for the `bench` entry: it splits function
definitions at their braces, reads the compiler's own name mangling back to symbols (ASCII
operator characters become words such as `bar` and `roof`, other bytes become `X<hex>`,
`_u<n>` numbers overloads, `__<module>` names the module), keys every function by symbol and
parameter type stems, and counts multiplies, adds and subtractions as spelled, `nimZeroMem`
calls, local multivector temporaries, whole-object copies, `nimErr_` branches, call sites,
allocation calls and lines. Totals fold callees per call site, since the library chains
operators. The movement model turns counts and type sizes into bytes read, written, zeroed,
copied and materialised per call; it names bytes the code moves and is not a measurement of
cache traffic (Article VIII.1).

On the pinned commit an error-flag branch follows every call of a Nim procedure under goto
exceptions, on both sides, and `{.raises: [].}` on the callee does not remove it; only
`--panics:on` does (see Figures). The counts here are taken with the flags the documents
name, `-d:release`, which is what a user of the library gets by default.

*Checked.* Suite `Inspector`: a demangling table, a fixture C source with known counts,
callee folding, movement from stems, and the test binary's own nimcache holding every
catalogued symbol at its arity.

## Baseline and gate

`baseline/<algebra>.json` records the inspector's counts, `baseline/bench_<algebra>.json` the
bench figures, both schema 1 with a header naming algebra, compiler commit, library commit,
flags, machine and date. `check` compares a fresh inspection against the baseline: any gated
count or bytes moved that grew is a finding rendered as `path:0: message; got value`, any
shrink is a notice, and documents of another algebra, compiler or flags are refused rather
than compared. Date and machine are ignored, since static counts owe them nothing. `drive`
is the verb koch and CI run: inspect every algebra, check, and hold the committed `gaps.md`
and ledger to regeneration. It is deterministic because it times nothing.

*Checked.* Suite `Baseline`: equal documents pass silently; one grown count is one finding
naming function, metric and both values; shrink is an improvement only; bytes moved are
gated; a function absent on either side is a finding; another build or schema is refused.

## Gap list

One row per probe per algebra. A row is open where the library exceeds its reference on
multiplies or bytes moved, spends any zero fill, temporary, error check or allocation, or
returns any NaN; time opens beyond `TIME_BAND = 1.25` times the reference median, because
medians on a shared machine move by tens of percent between runs. Rows with no reference
are decided on the absolute metrics alone. Every row key `<algebra>/<probe>` is given a
number by the ledger on first sight and keeps it; the ledger never reuses a number. Ten
design gaps sit above the rows, each decided by a rule over the documents and carrying its
evidence and the condition that closes it, so the list closes by measurement and never by
edit. The renderer refuses any line beyond 100 runes, since the product is committed and
form-checked.

*Checked.* Suite `Gaps`: row statuses on fixture documents, an unmeasured row, ledger
stability across reorder and a new key, every design rule's verdict and evidence, rendered
width, and rune-counting wrap.

## Driver

`tools/build.nim` carries `inspect`, `bench`, `baseline`, `check`, `drive`, `gaps`,
`sweep`, `system` and `clean`, dispatched from `case paramStr(1)` so koch reads the verbs
itself. `system` prints nothing: the compiler is the toolchain and the library is an Atlas
checkout, both pinned, and nothing else is fetched. `sweep` compiles the bench at two to
six dimensions, rigid metric, and prints general-probe medians; it never runs in CI.

*Checked.* `nim r tools/build.nim drive` exits 0 on the recorded baselines; lowering one
count in a baseline by hand makes `check` exit 1 with a line naming it.

## Dependencies

**The PGA library is a pinned dependency, never a copy.** It lives in [replications], which
carries no nimble file and holds the library three directories inside it, so the
requirement in `pga_benchmark.nimble` names the repository by URL and commit, `atlas.lock`
records the resolved commit `0bc465509d1c93b6bec3ced25aa29f080a2cf110`, and `nim.cfg` names
the subdirectory Atlas restores it to. That commit is the library's head on 2026-09-12, as
the Architect's standing instruction asks. Both projects are Prosperity Public License
3.0.0. Rejected: copying the library in, which Article XI.3 forbids.

**The compiler is pinned by commit**, `27763495bcfe265507ca98aedc1c7064bf1e0e4d`, the same
pin `rga_visualiser` carries, because the library spells seven operators with characters no
Nim release lexes. One cached build therefore serves both projects. Atlas writes
`"objects": {}` for a repository without a nimble file, so the resolved commit is patched
into `atlas.lock` by hand, and the lock's stored copies of the nimble file and `nim.cfg`
are kept byte-identical to the committed files, which the static pass checks.

**The Terathon Math Library was read, not used.** Eric Lengyel's C++ library at
[terathon] is MIT licensed, copyright (c) 1999-2024 Eric Lengyel; `TSRigid3D.h`,
`TSMotor3D.h/.cpp`, `TSFlector3D.h/.cpp` and `TSConformal3D.h/.cpp` were read to cross-check
the forms and counts derived here. No line of it is in this project; the reference is Nim
written from the book and the library, so no notice is required and this paragraph is
attribution rather than licence.

## Figures

Every figure below was taken on 2026-09-13 in the session's container, `linux amd64, 4
cores`, a shared cloud machine, on the pinned compiler and library head, with
`-d:release`. Timings are medians over 40 rounds of 1024 objects from
`nim r tools/build.nim bench`, in nanoseconds per object; they move by tens of percent
between runs on this machine (the sweep below timed 4D `∧` at 55 ns where the bench timed
35 ns), so they rank and do not measure. Counts are from `nim r tools/build.nim inspect` and
are exact for this compiler commit.

| Row (rga4d) | Library ns | Reference ns | Mul | Bytes moved | Checks |
|---|---|---|---|---|---|
| `wedge_point_point` (`∧`) | 29.7 | 2.8 | 81 / 12 | 512 / 112 | 178 / 0 |
| `wedge_dot_anti_motor_motor` (`⟇`) | 51.1 | 11.6 | 192 / 48 | 512 / 256 | 400 / 0 |
| `transform_point_motor` (three products) | 113.6 | 5.9 | – / 25 | – / 192 | – / 8 |
| `norm_bulk_point` (`\|∙`) | 12.1 | 1.8 | 8 / 3 | 768 / 40 | 20 / 1 |
| `unitize_point` (`^`) | 25.0 | 1.2 | 8 / 3 | 1152 / 128 | 24 / 0 |
| `support_line` (`∩`) | 95.3 | 2.1 | 162 / 9 | 1664 / 112 | 375 / 1 |
| `project_orthogonal_point_plane` | 94.9 | 4.8 | 135 / 14 | 1408 / 128 | 304 / 0 |

| Row (cga5d) | Library ns | Reference ns | Mul | Bytes moved | Checks |
|---|---|---|---|---|---|
| `wedge_round_point_round_point` (`∧`) | 58.4 | 3.6 | 243 / 20 | 1024 / 160 | 518 / 0 |
| `center_dipole` (`⊙`) | 209.0 | 3.7 | 486 / 16 | 4352 / 160 | 1104 / 1 |
| `partner_circle` (`⊛`) | 399.6 | 4.3 | 973 / 29 | 10752 / 320 | 2228 / 2 |
| `carrier_sphere` (`■`) | 87.3 | 0.3 | 243 / 0 | 1792 / 48 | 519 / 0 |

Emitted C of the library at 4D: `∧` is one function of 1090 lines, 81 multiplies, 65 adds,
one full-width zero fill and 178 error-flag branches; `|` (norm) spends 16 multiplies but
zero-fills nine times and declares four full-width temporaries, moving 1920 bytes for two
doubles; six of forty library functions are inline. Allocation: zero on every probe, both
sides, gauge live.

Scaling (`nim r tools/build.nim sweep`, rigid metric, general probes, same method, same
day): `∧` 2.9, 7.8, 55.0, 73.4, 203.4 ns and `⟑` 3.8, 14.2, 106.6, 177.1, 1383.4 ns at two to
six dimensions; `norm` 4.1, 7.8, 60.2, 50.5, 92.8 ns. The 4D column of the sweep ran hot
relative to the bench; the shape, not the values, is the figure.

Error checks under `--panics:on`, measured by compiling the bench entry with `--compileOnly`
and counting in its C: `∧` at 4D falls from 178 branches and 1090 lines to 0 and 551; the
reference's `rotate` falls from 6 branches and one zero fill to none. That switch makes
defects fatal, so whether the library's users may take it is the Architect's call; the gate
measures the default.

## Open questions

- Whether `--panics:on` is a build the library will stand behind, or whether the checks
  should go by making the operators not call anything, e.g. reading components directly
  rather than through `[]`.
- The `{}` key numbering assumes the compiler instantiates the grade selector before the
  antigrade one, in the order `selectGrade` and `selectGradeAnti` are declared; both bodies
  cost the same, so the rows are right either way, but the assumption is unverified.
- The reference is not yet optimal on the Nim side: `rotate` and `transform` still zero-fill
  a `Vec3` result and pay a branch per helper call under the default flags. Writing their
  components directly would lower the reference figures further.
- Whether the 2D references (rga3d, cga4d) are worth deriving; their rows carry library
  counts and absolute verdicts only.

## Known limitations

- Timings come from a shared cloud container and vary by tens of percent between runs; the
  time band absorbs some of that and the rest is why timing never gates.
- Movement is modelled from the bytes the code names, never measured as cache traffic.
- The inspector reads text patterns of this compiler commit; another commit could spell the
  same C differently and the suite that holds the reader to the test binary's own nimcache
  is what would say so.
- 32-bit floats and SIMD forms are unmeasured; Terathon's SSE paths were not compared.
- `sweep` is hand-run only, and the 6D figure was taken once.

[replications]: https://gitlab.com/mraxilus/replications
[terathon]: https://github.com/EricLengyel/Terathon-Math-Library
