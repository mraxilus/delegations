# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-06 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 1931060895ce28b1 |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: curator test project replacing `abstand/intervals`, which lived in a real domain;
owner asked for a domain-neutral project serving the same testing function. No authority
replicated; the laws tested are the ring's own. No vendored source.

This project exists to be checked rather than to be used. Every mechanism the audit enforces
appears here once, so a change to the checker has something minimal to fail against.

## Representation

**Steps are a distinct range; the ring size is a build-time define.** `Step = distinct
range[0 .. MODULUS - 1]` makes an out-of-range literal a compile-time error and lets plain
`+` be poisoned in favour of `⊕`. `MODULUS` defaults to 4 and is validated statically in
2 .. 16, echoing the value. Rejected: a plain `int` with runtime checks, which would exercise
none of the compile-time mechanisms the project exists to probe. Cost: two ring sizes mean
two builds, which the test matrix covers.

Trap, and it is why the poison test reads as it does: `not compiles(Step(MODULUS))` is
**false**. Only an out-of-range *literal* is rejected at compile time, while a constant
expression compiles and fails at runtime. The test uses the literal 16, beyond every allowed
ring. Verified by hand on 2026-09-05 rather than by a suite, since a build that must fail
cannot sit in one.

## Operations

**Advance is `⊕` with alias `advance`; inversion and identity are named.** `𝟎` is a Unicode
identifier on purpose: it exercises rune-counted line width and the prose scanner, not
notation from an authority — Article III.1 asks for canonical notation where a domain has
one, and a probe has none. Verified by `tprobe.nim`, exhaustively over every pair and triple
in both ring sizes: commutativity, associativity, identity, inverse, involution, and
positions inside the ring.

## Tests

**One testament stub with a matrix header**, suites named after the header table's subject
since no external authority exists. Verified by `tprobe.nim`: 2 matrix rows, 4 tests each.

## Toolchain

**Compiler pinned exactly, at the version this project was verified on**:
`requires "nim == 2.2.4"` in `probe.nimble`. An exact pin rather than a lower bound, because
no single compiler serves every project here and a range cannot say which one a suite passed
on. Nothing has asked this project to move, so the pin records that rather than a version
nobody tried. CI installs it for this project alone, in its own job.

## Figures

Unmeasured. No hot path exists; each operation is one addition and one modulo.

## Rules audits

Every rules change is audited against this project in the pull request that makes it, which
is why the `Rules` row above moves. None has yet required a change here: the project carries
Nim, Markdown and a nimble file, no target-language source, no node manifest, and no system
dependency beyond the compiler, so the rules governing those bind nothing in this tree today.
Each binds the moment that changes. What each audit found is in the log rather than restated
here (Article XI.2).

## Open questions

None.
