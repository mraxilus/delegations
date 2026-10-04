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

## Layout fixes

**Each space inside an expression takes the count of the list of X.9.** A binary operator and
`=` take one space on each side, and one that ends its line takes one before it. A comma and a
colon take none before them and one after. The inside of a bracket takes none. A prefix
operator is glued to its operand.

- The lexer reads only whether a space stands on each side of an operator, never how many. A
  space before and none after reads as prefix, so `a -b` is the call `a(-b)`.
- So the fixer rewrites the spaces of an operator only where they stand on both sides or on
  neither. Asymmetric spacing stays, and its check is silent, because its fix is a choice of
  meaning. So `a ⊖b` stays a command call.
- A prefix operator stands after anything but an operand, which is where the parser reads a
  prefix node. A `-` glued before a number would become a literal, so `- 1` stays.
- A gap stays where closing it would merge two tokens: `(` before `.`, `[` before `:`, `.` before
  `)`, and a colon after an operator.
- `=` glued to an operator character lexes as another operator, such as `=-`, which the rule
  reads as that operator.
- A semicolon takes no space before it and one after, as a comma does.
- Never read: `::`, `.` and the operators that start with it, the paths of `import` and
  `export`, and the export marker.
- An export marker is a `*` glued after a name that a declaration places. That name opens its
  line, follows a declaration keyword, or follows a comma after a marked name. A name inside an
  expression declares nothing, so `PI*(a + b)` multiplies.
- Cost: a name that opens a line of a wrapped expression reads as declared, so `a*(b)` at the
  start of such a line stays.
- Cost: the spaces that align the columns of a table go, unless a fence holds them.

**A range operator takes one space on each side, as every binary operator does (X.9).** The
Architect set this rule on 2026-10-04, so that every binary operator spaces alike. It covers `..`,
`..<` and `..^`, as in `2 .. 6` and `0 ..< n`. A range that ends its line takes one space before
it. Verified by `suites/test_spacing.nim`.

- A `^` after a range is a prefix operator, so it stays glued to its operand, as in `s[1 .. ^1]`.
  Verified by `suites/test_spacing.nim`: that line passes, and `s[1 .. ^ 1]` fixes to it.
- Glued `1..^1` lexes as the one operator `..^`, so the fixer writes `1 ..^ 1`, and never splits
  it. Verified by `suites/test_spacing.nim`. The Architect ruled on 2026-10-04 that a compound
  operator stays whole, because it can carry an optimisation that its parts lack. In 2.2.12 the
  template `..^` of `lib/system/indices.nim` is `a .. ^b`, verified by hand on 2026-10-04.
- Cost: the fixer leaves `1 ..^ 1` where X.9 shows `1 .. ^1`. The split is a choice for the hand.
- A range in prefix place, such as `a[.. 2]`, stays unread. Verified by hand, 2026-10-04, with
  `checkSpacing` and `fixSpacing` on that line.
- Cost: a glued range stays where its spaces would push a line with a trailing doc past
  `LINE_MAX`. The doc fixer moves a doc only off a line that is already wide, so neither fixer
  acts. Move the doc to its next line by hand, then fix. Verified by hand, 2026-10-04, through
  `fixEntries`.

## Content fixes

**A comment table aligns its columns by display width (I.4).** A combining mark takes no width,
and a wide East Asian glyph or an emoji takes two. Every other rune takes one, and an ambiguous
one does too. A column keeps the width of its separator row. It widens only where the text of a
cell does not fit, to that text and one space.

- The width guard of X.1 counts runes, and the table counts display width. The guard bounds what
  an editor holds on one line, and the table aligns what the eye reads. So a table whose fix
  would cross 100 runes stays for the hand.
- `WIDTHS` holds the blocks that the scripts of this tree use, from Unicode 15. A mark of another
  block, such as an Indic vowel sign, counts one.
- A cell that holds `|`, even in backticks, splits. Its table then holds rows of other lengths,
  and stays unread.
- Verified by `suites/test_alignment.nim`. On the tree, line 23 of `motors.nim` of
  `rga_visualiser` aligns by runes, and the fix pads it by one space.

**A message echoes each value after `got` in backticks (IV.4).** The check reads the
concatenation from the literal that holds `; got ` to its end. Each interpolation and each
operand there must stand inside a backtick span, counted from `got`. A tail that ends on a word,
such as `got none.`, echoes no value and is no finding.

- The fixer puts a backtick on each side of a bare value, inside the literals around it. A value
  that ends the message has no literal after it, and stays for the hand.
- The rule reads every value of the tail, so a context after the value takes backticks too, as
  `for {manner}` does.
- A test that builds the old text in the same form changes with it. A test that asserts the
  text in another form changes by hand, as two tests of `test_record.nim` do.
- Verified by `suites/test_messages.nim`.
