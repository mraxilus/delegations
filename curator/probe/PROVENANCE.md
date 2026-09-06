# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-05 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 912082eea75c768d |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: curator test project replacing `abstand/intervals`, which lived in a real domain;
owner asked for a domain-neutral project serving the same testing function. No authority
replicated; the laws tested are the ring's own. No vendored source.

## Representation

**Steps are a distinct range, the ring size is a build-time define.** `Step = distinct
range[0 .. MODULUS - 1]` makes an out-of-range literal a compile-time error and lets plain
`+` be poisoned in favour of `⊕`. `MODULUS` defaults to 4 and is validated statically in
2 .. 16, echoing the value. Rejected: a plain `int` with runtime checks, which would exercise
none of the compile-time mechanisms the project exists to probe. Cost: two ring sizes mean
two builds; the test matrix covers both. Verified: both `not compiles` checks pass in both
matrix rows, and an invalid modulus fails the static assertion, driven by hand on
2026-09-05 rather than by a suite, since a build that must fail cannot sit in one. Trap found while
writing the test: `not compiles(Step(MODULUS))` is false, because only an out-of-range
literal is rejected at compile time; a constant expression compiles and fails at runtime.
The test uses the literal 16, beyond every allowed ring.

## Operations

**Advance is `⊕` with alias `advance`; inversion and identity are named.** `𝟎` is a Unicode
identifier on purpose: it exercises rune-counted line width and the prose scanner, not
notation from an authority (Article III.1 asks for canonical notation where a domain has
one; a probe has none). Verified by exhaustive enumeration: commutativity and associativity
over every pair and triple, identity, inverse, involution, positions inside the ring, in
both ring sizes.

## Tests

**One testament stub with a matrix header.** Suites are named after the header table's
subject, since no external authority exists. Verified: 2 matrix rows pass, 4 tests each.

## Figures

Unmeasured. No hot path exists; each operation is one addition and one modulo.

## Toolchain

**Compiler pinned exactly, at the version this project was verified on.**
`requires "nim == 2.2.4"` in `probe.nimble`. CONTRIBUTOR.md now demands an exact pin rather
than a lower bound, since no single compiler serves every project here. This project's two
matrix rows pass on 2.2.4 and nothing asked it to move, so the pin records that rather than
a range nobody tried. This project's pin is also the one CI installs for it, in its own job.

## Open questions

None.
