# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | c73f63e83992089d |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a curator project, from the brief of the Architect. It is domain-neutral, so that
the worked example of the project shape depends on no real domain. No authority is
replicated, and the laws tested are the ring's own. There is no vendored source.

This project exists to be checked rather than to be used. It shows the compile-time
mechanisms that the constitution asks for, each one once, in the smallest project shape that
the audit accepts.

## Representation

**Steps are a distinct range, and the ring size is a build-time define.**
`Step = distinct range[0 .. MODULUS - 1]` makes an out-of-range literal a compile-time error.
It also lets plain `+` be poisoned in favour of `⊕`. `MODULUS` defaults to 4, and a static
check validates it in 2 .. 16 and names the value when it fails. Rejected: a plain `int`
with runtime checks, which would exercise none of the compile-time mechanisms that the
project exists to probe. Cost: two ring sizes mean two builds, which the test matrix covers.

Here is a trap, and it is why the poison test reads as it does. `compiles(Step(MODULUS))`
is **true**, but `let s = Step(MODULUS)` fails to build, because the conversion is invalid.
So `compiles` cannot hold the poison for a constant at the bound. The test uses the literal
16, which `compiles` rejects, and it pins the false positive as a check of its own. That
check fails once the compiler agrees with its own build. Verified by `tprobe.nim` on Nim
2.2.12.

## Operations

**Advance is `⊕` with the alias `advance`, and inversion and identity are named.** `𝟎` is a
Unicode identifier on purpose. It exercises rune-counted line width and the prose scanner,
rather than notation from an authority. Article III.1 asks for canonical notation where a
domain has one, and a probe has none. Verified by `tprobe.nim`, exhaustively over every pair
and triple in both ring sizes: commutativity, associativity, identity, inverse, involution,
and positions inside the ring.

## Tests

**One testament stub with a matrix header**, with suites named after the subject of the
header table, because no external authority exists. The matrix runs every test in each ring
size. Verified by `tprobe.nim`, and `nim r koch test curator/probe` lists each row.

## Toolchain

**The compiler is pinned exactly, at the version this project was verified on**:
`requires "nim == 2.2.12"` in `probe.nimble`. It is an exact pin rather than a lower bound.
No single compiler serves every project here, and a range cannot say which one a suite passed
on. The pin moves with `curator/audit`, which holds the version that builds koch. CI installs
it for this project alone, in its own job.

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
