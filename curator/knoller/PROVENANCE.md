# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-04 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 0d8fe4d3362ba815 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a curator project, from the brief of the Architect. It holds the fixers of `koch fix`
that read the text of one file and nothing else. The fixers that ask the compiler stay in
`curator/audit`. There is no vendored source.

## Package

**Knoller is a nimble package that requires its compiler and nothing else.** `src/knoller.nim`
is the umbrella, and the modules sit under `src/knoller/`. So a repository other than this one
can install it, and no rule of knoller reads the layout of this repository.

**`audit` reaches knoller by a relative import, as `koch.nim` reaches `audit`.** A sibling
project imported by its path is not a package, so it needs no requirement and no lock.

- Rejected: a `--path` in `koch.nim.cfg`. It reaches the compile of koch alone, so the suites
  of `audit` would need a second configuration.
- Rejected: Atlas with `requires "knoller"`. It needs a lock, a fetch of this repository over
  the network, and a new lock for each change of knoller.
- Rejected: `nimble develop`, which writes state outside the repository.
- Cost: koch compiles knoller, so the pin of knoller is the pin of `audit`. The `toolchain.nim`
  of `audit` reports a pin that differs.

**Each import of knoller is the standard library, or a module inside `src/`.** An import that
leaves `src/` reaches a sibling project, which an install of the package does not carry.
Verified by `suites/test_imports.nim`, which reads each import of each module under `src/`. Each
path must name the standard library or a file inside `src/`.

## Tokens

**`tokens.nim` keeps the rules of the lexer of the compiler.** A run of operator characters is one
operator. A `-` before a digit opens a number after a space or an opening bracket.

- The glyphs are those of the commit pin of the `ronri` projects. It adds `☆ ⟑ ⟇ ⩓ ⩔ ■ □` to the
  glyphs of 2.2.12, and no project on 2.2.12 spells them in code.
- Verified by `suites/test_tokens.nim`. Verified by hand over the tree, 2026-10-02: each byte of
  each Nim file outside whitespace lies in one token, and each bracket finds its partner.
