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

## Re-audit, 2026-09-06

Audited by a curator against the rules change that registers C++ and C and puts a check
behind the gated-language rule. This project carries Nim, Markdown and a nimble file only,
so the new rule binds nothing here and nothing needed correcting; the stamp moves because
the charter did, not because this project did.

## Re-audit, 2026-09-06, TypeScript conventions

Audited by a curator against the rules change that added the TypeScript and Node section to
CONTRIBUTOR.md. This project carries no `.ts` file, so the section binds nothing here and
nothing needed correcting; the stamp moves because the charter did.

## Re-audit, 2026-09-06, draft pull requests

Audited by a curator against the rules change that asks every pull request to open as a
draft and be marked ready only when it is. It binds how this project's next pull request is
opened, not anything in the tree; nothing needed correcting. The stamp moves because the
charter did.

## Re-audit, 2026-09-06, compiler resolution

Audited by a curator against the rules change that has koch resolve each project's pin to its
own compiler and fetch one it lacks. Nothing here needed correcting: the pin itself is
unchanged, and what moved is how koch finds a compiler for it. The practical effect is that
`nim r koch ci` is green as one command on a machine holding any one Nim, so verifying a
change that touches every project no longer needs two compilers and two commands.

## Re-audit, 2026-09-06, published pages linked

Audited by a curator against the rules change requiring a published page to be linked rather
than described — in the pull request's verification section and in the message to the
Architect both. Raised by `contributor/sincopa/dance_ontology` as issue 42, after the
omission it describes happened in pull request 40.

## Re-audit, 2026-09-06, curator pass

Audited by a curator against the pass that corrected six pieces of drift, split compiler
acquisition out of `toolchain.nim`, and covered the two modules that had no test. One change
reaches this project: a change touching only its `README.md`, `PROVENANCE.md` or
`GLOSSARY.md` now compiles nothing, where a README change previously ran the whole suite.
Nothing here needed correcting.

## Re-audit, 2026-09-07, issue routing

Audited by a curator against the change that made the issue channel run both ways and gave each
session a queue. A session now reads the open issues labelled with its own role before any other
work; a curator who reads this project raises what they find as an issue rather than editing it,
since they may not; an issue labelled with a session's own role is that session's queue, work
decided and deferred where the next session here will see it rather than in a conversation that
ends; and a label is the role string exactly, copied and never composed, because applying a
label creates it and a misspelling makes a second label nobody filters on.

Nothing in this tree changes: the rule binds how the next session here starts. No issue is open
against this project today, so its filter starts empty, which is the answer the rule is meant
to give when there is nothing waiting.

## Re-audit, 2026-09-07, Article II.9 bound

Audited by a curator against the amendment to Article II.9, which bounds when target code may
be hand-written: the source language by default, the crossing kept narrow, and the target
language only where the source cannot reach at all or where crossing would forfeit what the
target gives for free — a check its own compiler makes over the bulk of a file, a cost the glue
would add to a hot path — with the file's opening comment saying which.

This project holds no target-language file, so the rule binds nothing here today. It binds the
moment one arrives, and the `not Nim because` gate already refuses one that argues nothing.

## Open questions

None.

## Re-audit, 2026-09-07, type check on runner

Audited by a curator against the rule that a project carrying `package.json` beside its lock
carries a `types` verb in `tools/build.nim`, and that CI runs it: `koch types` restores node
tools and drives that verb, scoped to projects one change asks for.

This project carries no node manifest, so nothing here is type-checked and the rule binds
nothing today. It binds the moment this project grows scripts of its own.

## Re-audit, 2026-09-07, system dependencies

Audited by a curator against rule that system dependencies -- library compiler links against,
tool build shells out to, browser driven check drives, source clone no package manager carries
-- are declared as data in project's own `tools/build.nim`, each entry carrying its reason, and
reached by verb. Source clone carries its commit; system package carries no pin surviving across
distributions and record says so rather than implying one; anything fetched at build time
carries checksum build verifies. No machine's paths in committed source.

This project needs nothing beyond Nim itself, so rule binds nothing here and nothing needed
correcting. It binds moment this project shells out to anything.
