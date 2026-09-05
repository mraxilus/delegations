# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-05 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 62d39efca9bd8ffb |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: first contributor project, opened to exercise the repository's process end to end.
Authority: Open Music Theory (openmusictheory.github.io), pages *Pitch (class)*,
*Interval (class)*, *Transposition* and *Intervals*, read on 2026-09-05. No vendored source.

## Representation

**Pitch classes are an enum in sharp spelling; intervals are `distinct range[0 .. 11]`.**
The enum puts integer notation in the declaration order (C = 0 through B = 11), so every
table is enum-indexed and every walk is bounded by the type. The distinct range makes
`Interval(12)` a compile-time error and lets the sum of two pitch classes be poisoned.
Rejected: a single `int` for both, which lets a semitone count pass where a pitch class was
meant. Cost: enharmonic spelling is display only, so diatonic quality (augmented against
minor) and compound intervals are out of scope; a project needing them starts from letter
names, not from this enum. Verified: `not compiles` checks for both poisons pass in both
matrix rows.

## Operations

**Transposition is `+`, measurement is `-`, inversion and interval class are named.**
`p + i` is Tₙ(p) = p + n mod 12; `q - p` is the ordered pitch-class interval clockwise
from p to q; `p - i` transposes down. Inversion returns 12 − n mod 12, so unison inverts to
unison, stated in its doc. Interval class is the smaller of an interval and its inversion.
Where the authority has notation (Tₙ, integer notation) the symbol is the spelling and
`transpose` forwards to `+` (Article III.2); inversion and interval class have no glyph in
the source, so they carry plain names (Article III.1). Verified by exhaustive enumeration:
all 144 pitch-class and interval pairs for Tₙ, round trips up and down, both-direction sums,
involution of inversion, and the authority's worked examples (T4 of {11, 2, 4}; G to A♯ is
3, A♯ to G is 9).

## Spelling

**`SPELLING` is a build-time define, `sharp` by default, validated statically.** Display is
the only thing it changes; `when` selects the flat table, so no runtime branch exists.
Rejected: a runtime parameter to `$`, which would make every caller carry a mode for a
choice made once per build (Article II.5). Cost: showing both spellings in one program needs
two builds. Verified: the test matrix runs every suite under both values; an invalid value
fails at compile time with the offending value echoed (checked by hand once with
`-d:intervals.spelling=natural`, not by a test, because testament has no failing-build row
for a single file).

## Tests

**One testament stub with a matrix header, suites named after the authority's pages.**
Rejected: per-configuration stub files including a shared suite, which STYLE.md §6 shows,
because `matrix:` already runs one file once per configuration and a second file would
carry nothing. Cost: if configurations ever need different includes, split then. Sample
counts stand beside each loop. Verified: 2 matrix rows pass, 8 tests each.

## Figures

Unmeasured. No hot path exists; each operation is one addition and one modulo.

## Open questions

- Root `.gitignore` ignores testament binaries under `curator/tests/` only, so every project
  must add its own `.gitignore` for `tests/t*` or the audit reports an unregistered file.
  Curator could generalise the root rule; until then the per-project file is the fix.
- Should CONTRIBUTOR.md name a per-project `.gitignore` among the starting files? This
  project needed one on its first `make check`.
