# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-05 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | d27dcdddede02dbd |
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
matrix rows, and an invalid modulus fails the static assertion by hand. Trap found while
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

## Open questions

None.
