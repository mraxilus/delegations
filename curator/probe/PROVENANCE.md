# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 0bbac90808d8b78b |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a curator test project that replaced `abstand/intervals`, which lived in a real
domain. The Architect asked for a domain-neutral project that serves the same testing
function. No authority is replicated, and the laws tested are the ring's own. There is no
vendored source.

This project exists to be checked rather than to be used. Every mechanism that the audit
enforces appears here once, so a change to the checker has something minimal to fail against.

## Representation

**Steps are a distinct range, and the ring size is a build-time define.**
`Step = distinct range[0 .. MODULUS - 1]` makes an out-of-range literal a compile-time error.
It also lets plain `+` be poisoned in favour of `⊕`. `MODULUS` defaults to 4, and a static
check validates it in 2 .. 16 and echoes the value. Rejected: a plain `int` with runtime
checks, which would exercise none of the compile-time mechanisms that the project exists to
probe. Cost: two ring sizes mean two builds, which the test matrix covers.

Here is a trap, and it is why the poison test reads as it does.
`not compiles(Step(MODULUS))` is **false**. Only an out-of-range literal is rejected at
compile time, while a constant expression compiles and then fails at runtime. The test uses
the literal 16, which is beyond every allowed ring. Verified by hand on 2026-09-05 rather
than by a suite, because a build that must fail cannot sit in one.

## Operations

**Advance is `⊕` with the alias `advance`, and inversion and identity are named.** `𝟎` is a
Unicode identifier on purpose. It exercises rune-counted line width and the prose scanner,
rather than notation from an authority. Article III.1 asks for canonical notation where a
domain has one, and a probe has none. Verified by `tprobe.nim`, exhaustively over every pair
and triple in both ring sizes: commutativity, associativity, identity, inverse, involution,
and positions inside the ring.

## Tests

**One testament stub with a matrix header**, with suites named after the subject of the
header table, because no external authority exists. Verified by `tprobe.nim`: 2 matrix rows,
and 4 tests in each.

## Toolchain

**The compiler is pinned exactly, at the version this project was verified on**:
`requires "nim == 2.2.12"` in `probe.nimble`. It is an exact pin rather than a lower bound.
No single compiler serves every project here, and a range cannot say which one a suite passed
on. The pin moved from 2.2.4 with `curator/audit`, when a sweep found it seventeen months and
five patch releases stale. Both suites were run on 2.2.12 before it moved, in 10.0 s. CI
installs it for this project alone, in its own job.

## Figures

Unmeasured. No hot path exists, and each operation is one addition and one modulo.

## Rules audits

Every rules change is audited against this project, in the pull request that makes it, which
is why the `Rules` row above moves. Article VI.8 binds the prose: this record and the README
are written in Simplified Technical English. The project carries Nim, Markdown and a nimble
file, and no target-language source, node manifest or system dependency beyond the compiler.
So the rules that govern those bind nothing in this tree today.

Its suites enumerate both rings exhaustively rather than sample them, and nothing in them
reads a clock. So the rule that a check gives the same verdict on the same code is satisfied
by construction rather than by a seed. Each rule binds the moment that changes. What each
audit found is in the log rather than restated here (Article XI.2).

## Open questions

None.
