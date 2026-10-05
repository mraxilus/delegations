# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-04 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 526bf32fc693c4cd |
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

## Reports and rules

**Each report names a rule, and the caller cites its article.** A rewrite reports its path, its
line and its `Rule`. A finding of a check also reports its message, which ends with the value it
got (Article IV.4). The name of a rule is the string of its enum member, such as `expression
spacing`. So `koch fix` prints the same text as before the split. `curator/audit` holds the
article of each rule in `CITATIONS`, indexed by `Rule`, so a new rule without a citation does not
compile there.

- The id of a rule is the slug of its name, such as `expression-spacing`. The id is stable, so a
  tool can read the output of the command line. Verified by `suites/test_rules.nim`: each rule
  has an id of its own.
- A finding of a check keeps its whole message, with its article. The messages share no one shape
  from which a citation could be built again, so each message moved as it was.
- Cost: the messages of the checks still cite the articles of the charter of this repository.

## Chain

**One chain runs every fixer in one order until the source settles.** `formatted` reads the
fence, masks it, runs the fixers of the dialect, and writes the fenced lines back.
`checkFormatting` reports each rule that the fixers clear, on the same masked view. A dialect is a
module (`.nim`), a script (`.nims`) or a package (`.nimble`). Only a module takes the idiom fixers
and their checks.

- `curator/audit` maps each kind of Nim onto a dialect. It applies the fixers that need more than
  one file, then gives the source to `formatted`.
- The header of `chain.nim` gives the order of the fixers, and why each one comes where it does.
- The chain can run all its rounds again, and `## Wraps` gives why.
- Verified by `suites/test_chain.nim`: a source that breaks each layout rule settles in one run,
  and a second run writes nothing. A script keeps its imports as written.

## Fences

**A fence keeps its lines as written while every fixer runs.** Each fenced line reads as one
comment at its own indent. A fixer whose rewrite would move a fenced line is skipped for that file.
A fence that crosses a bracket, a string or a comment leaves the whole file as written. Verified by
`suites/test_fences.nim` and `suites/test_chain.nim`.

**Each run warns of each fence, and names each rule that breaks inside it.** A fence is the one
escape from the rules, and a line it keeps is easy to forget. One warning stands at the first line
of each fence, and gives the lines it keeps, markers included. It names each rule that breaks
inside the fence, in the order of `Rule`, with its count and its first line. Knoller prints it as
`fence-held warning`, and `koch fix` prints it after `warning:`. A warning changes no exit code,
because the charter grants the fence (Article X.1).

**The warning runs the checks as a dry run, on the source as given.** No mask hides a fenced line,
so each marker reads as a plain comment, and each line keeps its number. `heldOf` keeps each
finding whose line falls inside a fence. So a fence counts what its lines report without the fence.
A rule that a fixer clears and a rule left for the hand count alike, because a check names both. A
module also takes the idiom checks that the static pass runs, such as `return-result`.

- Rejected: one warning for each break inside a fence. The Architect chose one line for each
  fence, so a large table in a fence costs one line.
- Rejected: a dry run of the fixers. It counts only what a fixer clears, so it misses
  `not-over-binary`, which no fixer reaches.
- Rejected: a fence as a finding that fails the run. A generated file would then fail every run,
  though its fence is allowed.
- Cost: a rule that knoller fixes and does not check goes uncounted. Those rules are
  `trailing-whitespace`, `file-ending`, `tab-in-string`, `entry-block` and `article-in-comment`.
  The static pass of `audit` holds a check of each of them, and reads no fence.
- Cost: a file with a fence takes the checks twice, once masked and once as given. A file with no
  fence takes them once. A delegate measured the cost on 2026-10-04, with a debug build and two
  runs of each. `knoller --check` on `starfield.nim` of `rga_visualiser` took 11 s, against 4 s
  before. That file has 22,560 lines, and its fence holds 11,252 calls.
- Verified by `suites/test_fences.nim`, `suites/test_chain.nim` and `suites/test_command.nim`. In
  `suites/test_chain.nim`, the lines of a fence report the same rules when no marker fences them.

## Command line

**`knoller [--check] path...` fixes each Nim file that the paths name.** A directory stands for
the Nim files that `git ls-files` lists under it. A run writes only the files that change, and
`--check` writes none. Each line of output names a path, a line and a rule id, and the count comes
last. A clean run exits 0, and a usage error exits 2. A run exits 1 where a finding is left, or
where a change is due under `--check`.

- No option sets a style. The rules are constants, and a fence is the only way to keep a layout.
- A nimble file whose copy `atlas.lock` holds is passed over, because a rewrite would leave the
  copy stale.
- The module is `command.nim`, because a path spells its words in full (Article V.9), and no
  glossary lists the acronym CLI.
- `outcomeOf` decides what a run writes and prints from text alone, so its suite needs no file.
  Verified by `suites/test_command.nim`. The suite also holds the README to every rule id.
- A directory that gives no Nim file is a usage error, and its message says why. The directory
  is outside a git work tree, or git lists no Nim file under it. A silent `0 to fix.` reads as a
  clean run over files that knoller never read.
- Each fixer reads the path whole: absolute, with `.` and `..` resolved (`layoutOf`). So the
  test file, the stub and the umbrella read alike from any directory, and the output prints the
  path as named.
- Cost: a directory named `tests` above the repository makes each file below it a test file,
  from the command line alone. `koch` gives paths from the root of the repository.
- Each line of output is a line of the file as given. A finding left in the fixed text traces
  back through the fix, as a rewrite does. A line that the fix inserts has no line as given, so
  a finding there prints with the path alone.
- `koch fix` needs no such trace. It prints no check of the fixed text, and each edit before
  knoller keeps its lines.
- Verified by `suites/test_command.nim`. One file named from two directories prints the same
  lines, and a finding left prints at its line as given.
- Verified by hand, 2026-10-04, with the built binary. `--check` of a directory outside a git
  work tree, and of one where git lists no Nim file, exited 2 with its reason. On the PGA
  library, `--check suites.nim` from inside `tests/` and `--check tests/suites.nim` from its
  parent each gave 73 changes, with the same lines.
- Verified by hand, 2026-10-04: the built binary fixed a scratch file, and a second run wrote
  nothing. A run without a path, and a run with an unknown option, exited 2.

## Tests

**A test that also reads a check of `curator/audit` stays in the suites of audit.** Such a test
holds that a fixer of knoller clears what a check of audit reports, so it needs both projects. A
test that reads knoller alone sits here. A fixture that both suites read is copied, and each copy
names the other.

## Tokens

**`tokens.nim` keeps the rules of the lexer of the compiler.** A run of operator characters is one
operator. A `-` before a digit opens a number after a space or an opening bracket.

- The glyphs are those of the commit pin of the `ronri` projects. It adds `☆ ⟑ ⟇ ⩓ ⩔ ■ □` to the
  glyphs of 2.2.12, and no project on 2.2.12 spells them in code.
- Verified by `suites/test_tokens.nim`. Verified by hand over the tree, 2026-10-02: each byte of
  each Nim file outside whitespace lies in one token, and each bracket finds its partner.

## Form

**A trailing comment in Nim takes exactly two spaces before its marker (X.9).** The marker is the
first `#` after the code of a line. The check reads it on the code-only view and on a
code-and-comments view, which blanks strings alone. So a `#` inside a string or a char never trips
it. A line with no code, such as a whole comment or a doc line, holds no trailing comment. The
static pass of `audit` does not run this check yet.

- A column of aligned trailing comments is a finding, by the ruling of the Architect. The charter
  examples that aligned a column now take two spaces. The excerpt of `algebra.nim` in
  `EXAMPLES.md` keeps its one space, because it is quoted verbatim at its pin.
- Verified by `suites/test_form.nim`: a gap of one, of none and of five fails, after code and after
  a string. A `#` in a string, a char, a block comment or a long string passes, and so does a whole
  comment line.

## Layout fixes

**Each layout rule that has one right answer has a check and a fixer, from one reading.** The
checks and fixers of separators, signatures, calls and trailing separators share the reading of
`wrapping.nim`. Spaces read `spacing.nim`, and `## Spaces` gives them. Blank lines read
`blanks.nim`, and docs and defaults `declarations.nim`. A construct that the scanner cannot read
with certainty stays as written, and its check stays silent.

**Parameters take commas while each type appears once, and semicolons where a group shares a
type (STYLE.md §5).** The rule holds on one line and across several, the trailing separator
included, in a routine, a routine type and a lambda. The separator after a typed group never
changes what the compiler reads. A group without a type or a default stays, because a semicolon
after it ends the group.

**A tuple type takes commas between its fields (STYLE.md §5).** `tuple[a, b: int, c: X]` and its
form with `;` parse to one tree, so the rewrite moves no reading. A comment after a field stays.
A `;` in parentheses is a list of statements, and stays.

**Each signature has one layout (X.3).** A signature that fits stands on one line, and a wrapped
one that would fit is joined. Otherwise its parameters take one line of their own, where that
line fits. Otherwise one parameter, or one group of a shared type, takes each line. Each layout
indents one level, and the closing line opens with `)`.

- One parameter alone on its line is a list written one item to a line, so it takes a separator.
- A signature that holds a comment, or a group that spans lines, stays. So does one that fits
  where the body after `=` on its line does not, because a moved body and a wrap are two answers.

**A call that fits stays on its line, and one that does not keeps the line breaks of the hand
while each line fits (X.3).** A wrapped call that would fit is joined. Otherwise the line breaks
that the hand gave it stay, its arguments on one line of their own among them (`handLines`). Only
where a line would cross `LINE_MAX` does it take one argument to a line, with a trailing comma.
The outermost call that crosses `LINE_MAX` splits first, and each line it leaves is read again.
An argument splits its own call only where that call is the whole argument.

- An argument that the hand wrapped, and that fits no line, keeps its line breaks and moves with
  its new indent.
- A call that spans lines, with a comma after its last argument on a line before its `)`, is
  never joined (`isTrailed`). That comma marks the split that the hand wants. So such a call
  keeps one argument to a line, even where it fits. A call that knoller splits keeps its
  split on the next run, since the split writes that comma. Verified by
  `suites/test_wrapping.nim`: the `newEnum` call of `algebra.nim` of the PGA library stays.
- The rule reads each bracket that call wrapping joins: a call `f(…)`, a method call `x.f(…)`,
  a generic call `f[T](…)` and an object constructor `T(…)`. A signature keeps its own layout,
  and a list that no call opens is never joined.
- A call that the hand hugs around a split call keeps the hug (`isHug`), as `x.add(Y(` with
  its `))`. The inner call takes the layout of its own, in place.
- The line breaks of the hand stay only where that call is the one bracket that spans lines.
  Cost: a call that holds another call spanning lines, and does not fit, splits one argument to
  a line. Each argument is then laid out again. Verified by
  `suites/test_wrapping.nim`: the call of `cayleys.nim` of the PGA library stays as written.
- A list that no call opens, and that spans lines, keeps its rows: the fixer never reflows it.
- A call stays where it holds a comment, a long string that spans lines, or a block. A block is
  a keyword that opens one, `;`, `do`, or `:` at the end of a line outside a condition.
- A line break that joining could read again stays, such as one between two operands.

**A list written one item to a line takes a trailing separator (X.3).** That holds for a call,
parameters, an array, a seq, a set, a table, a tuple of several items, a constructor and an import
bracket. Parameters take the separator that their groups take. A parenthesis of one item takes
none, because `(a,)` is a tuple and `(a)` is a grouping. Verified by hand with 2.2.12, 2026-10-02:
the compiler accepts the separator in each of these lists, and `;` after the last parameter group.

- The separator stands only where the list would not fit joined onto the line where it opens
  (`isFittingJoined`). A list that fits joined takes none: a call joins under the call layout,
  and any other list keeps the rows of the hand. So the separator stays the one mark of a split
  that the hand wants. A list that gains it stays split on the next run.
- A list whose items share a line takes none, since there the separator would read as that mark.
- Verified by `suites/test_wrapping.nim` and `suites/test_chain.nim`. The blocks of `cayleys.nim`
  of the PGA library at lines 271, 338 and 604 gain their separator and keep their lines.

**Adjacent imports of one directory share one bracket, and a bracket of one module drops it
(X.5).** The merged statement takes the place of the first, and its items sort as bracket items
sort. An item keeps `{.all.}`. An import with `except`, `as`, another pragma, a comment or a
string stays apart, and so does a statement that spans lines. Imports apart across a blank line
stay too, because where they meet is a choice.

**Each list that the language leaves unordered sorts in dictionary order (X.10).** That covers
the imports, an `export` list, a pragma list of a declaration and the names after
`from … import`. Case and `_` are ignored, and a tie falls to the code point, so `Facing` comes
before `facing`. A pragma list holds its bare pragmas first, then those with an argument, each
group sorted. The items sort into the slots they held, and a `key: value` item moves whole.

- A pragma statement that opens its line stays, such as `{.push.}`.
- A list that holds a pragma which code defines stays. The compiler applies macro pragmas in the
  order written: `semProcAnnotation` takes the first macro, and that macro sees the rest. So a
  moved pragma of that kind can change the routine it yields.
- Cost: such a list stays even where its order moves nothing, and reading holds it. A built-in
  pragma missing from `PRAGMAS_BUILT_IN` reads as one that code defines, with the same cost.
- The built-in pragmas come from the sets of `compiler/pragmas.nim`.
- Verified by hand with `koch check-files`, 2026-10-02: the wired import check, now in
  dictionary order, reports no new finding on the tree.

**Banners take the blank lines of X.2 exactly, and `strictFuncs` after the imports moves.** The
banner fixer sets each run beside a banner to the count that `checkBanners` reads. The late
`strictFuncs` moves to the place where a missing one goes. The blank lines above it go with it
where blank lines stand below it too.

**A suite takes three blank lines before it, and a test two (X.2).** A first child follows its
opener at once, such as a test that opens a suite, or a suite that opens a `when` body. A suite
or a test after a banner takes the one blank line of the banner. The rule reads files under
`tests/` alone.

- A test file has a directory `tests` in its path, at any depth. A stub is a `test_*` file
  directly in that directory. `reports.nim` holds both readings, from the names below the last
  directory `tests`, so the blank-line rule and the stub rules read one definition.
- `isTestFile` holds exactly where `/tests/` stands in the path with a `/` before it. `isStub`
  holds exactly where the parent of a `test_*` file is `tests`. Verified by
  `suites/test_blanks.nim`, which holds both readings to a table of paths. Verified by hand,
  2026-10-04, over each path that git lists in this repository, relative and absolute.
- Cost: a stub one level down, such as `tests/rga3d/test_rga3d.nim` of the PGA library, is a
  test file and no stub. So it takes the blank-line rules, and not `stub-keys` or
  `profiler-import`.

**A nested helper takes one blank line on each side (STYLE.md §1).** A helper is a routine that
the body of a routine declares at its own level. The rule holds right after the doc of the
enclosing routine too. A one-line `template` is an alias, and stays. The side that leaves the
enclosing body is not read, because a sibling of the enclosing routine stands there. No helper
moves.

- A routine on one line takes no blank line after the head or doc of the enclosing routine, or
  after another such routine. That is a `{.borrow.}` with no body, or a body
  on the line of its signature, with no doc after it. Borrowed funcs and thin wrappers then read
  as one group, as X.2 stacks undocumented one-line helpers. Verified by `suites/test_blanks.nim`:
  the template of borrowed funcs of the PGA library stays as written.
- One blank line still stands between the last of them and a stage or a routine of several
  lines. A routine with a doc on its next line counts as several lines. So it keeps one on each
  side, as documented definitions do in X.2.
- Each run of blank lines goes above a `#` comment on the line before, so the comment stays with
  what it names. A `##` doc and a banner never move with it.
- Both rules read the code view, so a `suite` or a `proc` in a fixture string never moves. A run
  inside a string or a comment that spans lines is never read.
- Cost: a helper inside a `when`, an `if` or a loop of the body is not read. X.11 asks each
  helper first in the body.

**A one-line doc of a type, a field, a binding or an enum member stands on its line (STYLE.md
§5).** It takes two spaces before `##`, where the joined line fits `LINE_MAX`. Otherwise it takes
the next line, one level in. A trailing doc that widens its line past `LINE_MAX` moves there. A
doc of two or more lines stays where it is.

- A declaration is a line of code in a `type`, `const`, `let` or `var` section, at any depth. A
  keyword line that holds one declaration is one too.
- A line that continues an expression, opens a block, leaves a bracket open or carries a `#`
  comment is none. The doc of a routine keeps its own place.

**A parameter drops a type that its literal default gives exactly (X.12).** An integer literal
gives `int`, a float literal `float`, `true` and `false` give `bool`, and a string or a character
literal gives `string` or `char`. `default(T)` gives `T`, and `none(T)` gives `Option[T]`.

- `float = 0`, `cfloat = 0.0`, `HalfTurns = 0` and a named constant stay, because there the
  literal gives another type, or none.
- A template and a macro stay, because a parameter of theirs without a type reads otherwise.
- Cost: a literal with a suffix, such as `0'u8`, and a raw string keep their type, though it is
  exact.

**A rewrite that widens its line past `LINE_MAX` stays only where a wrap fits.** `## Wraps` gives
which fixers widen, which wraps follow, and what the chain holds where none fits.

## Spaces

**Each space inside an expression takes the count of the list of X.9.** A binary operator and
`=` take one space on each side, and one that ends its line takes one before it. A range takes
none, as below. A comma and a colon take none before them and one after. The inside of a bracket
takes none. A prefix operator is glued to its operand.

- The lexer reads only whether a space stands on each side of an operator, never how many. A
  space before and none after reads as prefix, so `a -b` is the call `a(-b)`.
- So the fixer rewrites the spaces of an operator only where they stand on both sides or on
  neither. Asymmetric spacing stays, and its check is silent, because its fix is a choice of
  meaning. So `a ⊖b` stays a command call.
- A prefix operator stands after anything but an operand, which is where the parser reads a
  prefix node.
- The fix never splits or merges a token, by the ruling of the Architect. So a prefix operator
  keeps exactly one space where it and its operand lex as other tokens when glued. `|∙ ⊖m` glued
  is the one operator `|∙⊖`, `- -x` is `--x`, and `- 1` is the literal `-1`. The check accepts
  that one space, which the tokeniser demands (X.9).
- Verified by `suites/test_spacing.nim`: each token of each fixture reads the same before and
  after the fix. In `suites/test_chain.nim`, the operator tokens of the stacked form read the same
  after the whole chain.
- Verified by hand on the PGA library of `replications` at `d9be8ae`, 2026-10-04. The lines of
  `tests/suites.nim` with `|∙ ⊖` keep their space. With the commit pin of the `ronri` projects,
  `nim check` passes on 64 of 64 targets, on the library as given and as knoller writes it. The
  eight test programs, `rga2d` to `rga5d` and `cga3d` to `cga6d`, print the same output on both.
  `testament all` passes 8 of 8 on both.
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

**A range operator takes no space (X.9).** It covers `..`, `..<` and `..^`, as in `2..6` and
`0..<n`. It keeps one space on each side where a piece beside it binds tighter. Glued, `i + 1..<n`
would read as if the range starts at 1. It also keeps one where the glued tokens would lex as other
tokens. Verified by `suites/test_spacing.nim`, with each example of the ruling.

- A range that ends its line takes one space before it, as a binary operator there does.
- A piece runs from the range, at its depth and on its line, through operands, prefix operators
  and binary operators that bind tighter. A looser operator (`in`, `==`, `and`), a delimiter, the
  bracket around it or a command head ends it (`isRangeApart`).
- Precedence is that of the lexer (`getPrecedence` of `compiler/lexer.nim`, mirrored in
  `precedence.nim`). `..` binds at 6, `&` at 7, `+` at 8, and `*` and most glyphs at 9.
- A bracket group is one operand, so the spaces inside it do not count, as in `f(i + 1)..n`.
- Spacing moves no parse tree, so the rewrite moves no reading. Verified by hand, 2026-10-04,
  with the parser of the commit pin of the `ronri` projects. `i + 1 ..< n` and `i + 1..<n` read
  alike, and so do `x in 2 .. 6` and `x in 2..6`. Only a merge, as of `1 .. ^1` into `1..^1`,
  changes the tree.
- The merge guard reads a binary operator with both neighbours glued (`isMerging`). So `s[1 .. ^1]`
  and `0 .. -1` keep their spaces, and `i-1` reads as three tokens.
- Glued `1..^1` lexes as the one operator `..^`, so the compound `s[1 ..^ 1]` becomes `s[1..^1]`,
  and the fixer never splits it. A compound operator stays whole, because it can carry an
  optimisation that its parts lack. The fixer keeps the operator that the source lexes as, so the
  choice between `s[1 .. ^1]` and `s[1..^1]` stays with the hand.
- Cost: a piece is read on the line of its range, so an operator of a piece on the line before
  goes unread.
- A range in prefix place, such as `a[.. 2]`, stays unread. Verified by hand, 2026-10-04, with
  `checkSpacing` and `fixSpacing` on that line.

**The power operator `^` is always tight (X.9).** With spaces it reads like an operator on bits,
as the Architect ruled. So `-1 ^ k` becomes `-1^k`, and `a + b ^ 2` becomes `a + b^2`. Only a
prefix operator binds tighter, so no piece beside it keeps it apart, and math beside it makes no
exception. Verified by `suites/test_spacing.nim`, with each example of the ruling.

- The rule reads the binary token `^` alone. The assignment `^=`, the prefix `^` of a backwards
  index, as in `s[^1]`, and the compound `..^` read as before.
- The exponent glued to `^` can lex as one token with it. There it takes parentheses instead of
  spaces: `a ^ -b` becomes `a^(-b)`, and `x ^ ~y` becomes `x^(~y)`. The exponent is
  the prefix operators and the one operand after `^`, with any call, index or field glued to it
  (`exponentLast`). An exponent that runs past its line stays as written, with no finding.
- Only the exponent takes parentheses. A left operand ends in a name, a literal, a quoted name or
  a closing bracket. None of them joins an operator run, so no left operand merges with `^`.
  The fixer still passes over such a case, should one ever lex so.
- The rule of needless parentheses reads a group after `^` as glued, so it keeps `a^(-b)`, and
  `a ^ (-b)` settles on `a^(-b)` in one round. A group of one plain operand still goes, so
  `-1 ^ (k)` becomes `-1^k` through the chain. A group that holds math stays, as in
  `-1^(int(b.grade) * int(b.gradeAnti))`. Verified by `suites/test_chain.nim`.
- A `^` that ends its line takes one space before it, as a range does.
- Spacing moves no parse tree, and the wrap adds one group around the exponent alone. Verified by
  hand, 2026-10-05, with the parser of the commit pin of the `ronri` projects. `-1 ^ k`,
  `a + b ^ 2` and `(a + b) ^ 2` read as their glued forms do. `a ^ -b` reads as `a^(-b)` once
  the group around one operand is normalised.

**A symbol operator inside a bracket glued to its operand takes no space (X.9).** The bracket is
`[` with no gap after an operand, at any depth inside it, so `prev[i - 1]` becomes `prev[i-1]`. A
range there goes tight with its math, as in `digits[i+1..<n]`, since everything inside reads as
one unit. A word operator keeps its spaces, which the tokeniser demands, and `=` and `:` keep the
form of X.9. Glued tokens that would merge keep one space on each side, so `s[1 .. ^1]` stays.
Verified by `suites/test_spacing.nim`, with each example of the ruling.

- An index, a type bracket and a generic bracket read alike, since tokens cannot tell them apart.
  So `array[N+1, int]` and `range[0..3]` take the form too.
- An array literal that stands alone, such as `[a + b, c]` or `@[a + b]`, keeps its spaces.
- The generic list that a routine or a type declares after its name is a declaration. It selects
  nothing, so it keeps its spaces, export marker or not (`isDeclaredList`). That covers
  `func scalar*[I: Basis | Grade]`, `func pick[I: Basis | Grade]` and `Foo[T: A | B] = object`.
  Its head is a routine keyword or `type` on the line of the name. An entry of a `type` section
  counts too, read from the nearest line above at a smaller indent. Verified by
  `suites/test_spacing.nim`.
- Cost: a generic list of an entry under a `when` inside a `type` section reads as a selector.
- An operator that ends its line inside such a bracket takes one space before it, as elsewhere.
- Spacing moves no parse tree here too. Verified by hand, 2026-10-04, with the parser of the
  commit pin of the `ronri` projects: `prev[i - 1]`, `digits[i + 1 ..< n]` and `a[f(x, y + 1)]`
  read as their tight forms do.

## Content fixes

**No fixer and no check reads a comment table (I.4).** The width that a reader sees depends on the
font, so no checker can read it. A glyph such as `⊖` takes one column in one font and two in
another. Article I.4 asks the columns to align as the eye reads them, so reading holds the tables.

- Rejected: alignment by display width, from the East Asian Width blocks of Unicode. On the PGA
  library it padded each table row that holds a glyph, and each row read wrong in the font of the
  Architect.
- Verified by `suites/test_chain.nim`: a table row that holds a glyph, padded as the hand's font
  shows it, passes the whole chain as written.

**A message echoes each value after `got` in backticks (IV.4).** The check reads the
concatenation from the literal that holds `; got ` to its end. Each interpolation and each
operand there must stand inside a backtick span, counted from `got`. A tail that ends on a word,
such as `got none.`, echoes no value and is no finding.

- The fixer puts a backtick on each side of a bare value, inside the literals around it.
- A value that ends the message has no literal after it, so the message takes a fixed shape. A
  backtick goes at the end of the literal before the value, and `& "`."` goes after it. So the
  message ends on its value, as IV.4 asks.
- A value whose operator binds as loosely as `&`, or more loosely, keeps its finding, since the
  appended literal would join that operator. So `"got " & a == b` stays.
- The rule reads every value of the tail, so a context after the value takes backticks too, as
  `for {manner}` does.
- A test that builds the old text in the same form changes with it. A test that asserts the
  text in another form changes by hand, as two tests of `test_record.nim` do.
- Verified by `suites/test_messages.nim`.

**A condition that mixes `and` with `or` takes parentheses around each `and` (X.4).** The parser
already groups it so, because `and` binds tighter than `or`. So the parentheses move no reading.
The check reads an expression on tokens, at one bracket depth, between delimiters. A command call
holds the expression after its head.

- `not` over a binary expression has a check and no fixer. Nim reads `not a == b` as
  `(not a) == b`, so the right parentheses depend on intent.
- Verified by `suites/test_precedence.nim`. The tree holds no finding of either rule.

**Parentheses that group what the parser groups anyway go, in three kinds alone (X.4).** The
Architect chose the kinds. Parentheses go around a prefix term that stands as one side of a binary
operator: `(|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ (𝐦 ∧ ⊖𝐧))` becomes `|∙ ⊖(𝐦 ∧ 𝐧) + |∘(𝐦 ∧ ⊖𝐧)`. They go
around one plain operand after a prefix operator, as `■(𝐧)` becomes `■𝐧`. They go around one plain
operand as one side of a binary operator, as `2'u^(DIMENSIONS)` becomes `2'u^DIMENSIONS`.
Verified by `suites/test_parentheses.nim` and `suites/test_chain.nim`.

- A plain operand is a name or a literal, with any call, index or field glued after it. A prefix
  term is one or more symbol prefix operators, then one operand. The elements read as
  `precedence.nim` reads them, on the line of the group and inside the bracket around it.
- A prefix operator binds tighter than any binary one, so `|∙ x + y` reads as `(|∙ x) + y`. So
  the parse tree changes only by the `nkPar` around one node. Verified by hand, 2026-10-04, with
  the parser of the commit pin of the `ronri` projects, on the PGA library as `koch fix` writes it.
- A group around a binary expression stays, whatever its precedence, as the Architect ruled. So
  `1'u shl (i-1)`, `(2'u^DIMENSIONS) - 1` and the parentheses of X.4 around `and` stay.
- A group with a suffix glued after it stays, since `■𝐧.x` reads as `■(𝐧.x)`. So do a tuple, a
  call, a signature and the argument of the command form, which hold a separator or glue to
  their callee.
- A group whose removal would glue two tokens into one stays, by the merge guard of
  `spacing.nim`. That covers `\(/𝐮)`, `^(|𝐦)`, `/(∙𝐦)`, `☆( ⊟ m)` and `-(1)`, which would lex
  as the literal `-1`.
- A group after the power operator `^` reads as glued, since spacing always glues `^`. So the
  guard keeps the wrapped exponent of `a^(-b)`, from `a ^ (-b)` too. Verified by
  `suites/test_parentheses.nim`.
- The guard reads the gaps as they stand. So where spacing sets a space beside a glued group,
  the next round removes it: `back*(-heading)` becomes `back * -heading`, with the same tree.
  Verified by hand, 2026-10-04, with `knoller --check` on `rga_visualiser`.
- A prefix term after a command head stays, since `check |∙ x` reads `|∙` as a binary operator.
- Cost: `not` and the other keyword prefix operators are not read. X.4 holds `not` apart, and
  `not(a)` glued would lex as one name.
- The chain runs the rule before spacing, so `|∘ (` glues as `|∘(` in the same round.


**A `to<Target>` call of a plain argument takes its subject first (STYLE.md §5).** A plain
argument is a name, with any call, index or field glued after it. A compound argument, a literal,
a generic call, several arguments and a call across lines stay prefix calls. A call followed by
a bracket stays too, because `y.toX(z)` and `y.toX[T]` read otherwise.

- The rewrite reads no symbol. A field named like the routine, such as `to_x`, would capture the
  method call. The tree holds no such field, and every changed file checks as before.
- Verified by `suites/test_targets.nim`.

**A dotted call statement takes the command form where its one argument is a call or a
parenthesised expression (STYLE.md §5).** So `x.f(Y(…))` becomes `x.f Y(…)`, and `x.f((a, b))`
becomes `x.f (a, b)`, and the double bracket goes. The rule reads method call syntax alone, with
the receiver chain glued from the start of the statement, as `result[a][b].add(`. The one argument
stands glued inside both brackets, with no comma after it. A call that spans lines keeps its inner
layout, and its `))` becomes `)`.

- Only a whole statement is read. It opens its line after a statement that ended, a block `:` or
  the `=` of a routine head, and its `)` ends its line. Inside an expression the command form can
  read otherwise: `x.f(g(a)) + 1` would become `x.f(g(a) + 1)`. So a binding, an assignment, a
  `discard` and a continuation stay.
- A plain call `f(g(x))` stays, and so do a call of two arguments and a comma after the argument.
  An argument of another shape stays too, such as `g(a) + 1`, `g(a).h` or `@[a]`.
- The parse tree changes in one node kind alone: the parser reads `nkCommand` where it read
  `nkCall`, with the same callee and argument. Verified by hand, 2026-10-04, with the parser of the
  commit pin of the `ronri` projects, on each shape of `suites/test_commands.nim`.
- The rewrite never widens a line: `(` becomes a space, and its `)` goes. The chain runs it before
  the call layout, so the layout reads the command form. Verified by `suites/test_commands.nim` and
  `suites/test_chain.nim`.

## Wraps

**A repair that widens its line past `LINE_MAX` stays, and the chain wraps the line.** The
Architect asked for this on 2026-10-04, with three properties of `koch fix`. It is deterministic,
a second run writes nothing, and no option sets a style. The tab, comment, message, condition,
spacing, continuation and trailing separator fixers are wideners. Each one repairs freely off the
held lines, and keeps the width guard on them.

- The idiom fixers stay guarded, since an import bracket has no wrap. The renames and conversions
  of `curator/audit` stay guarded too.
- Each widener keeps a form of two arguments that holds every line, so its unit contract stays.

**The wraps follow one fixed order, as the Architect ruled on 2026-10-04.** A line that a repair
leaves wide takes the first of these that fits:

1. the layout of its signature, or a split of the outermost call that crosses `LINE_MAX`;
2. the line breaks that the hand gave, kept;
3. a break after an operator;
4. a doc moved to its own line, one level in;
5. the shape of a message that ends on its value (`## Content fixes`);
6. a plain `#` comment moved to its own line above, at the indent of its line.

Where none fits, the line is held, and its finding stays for the hand.

**The chain runs its rounds again, at most four times, and each time it holds the lines that the
time before left wide.** The first time holds no line. A line that is still wide once the rounds
settle, and that is narrow in the source as given, is held the next time. That time starts from
the source as given again. The fourth time holds every line, which is how the chain ran before the
wideners.

- A held line never widens again. Each widener keeps its guard there, and no other fixer or wrap
  writes a wide line. So the held lines grow each time, and an inserted line that is left wide
  holds every line at once.
- The held lines are a sorted `seq`, and each fixer is a function under `strictFuncs`. So the
  output depends on the source alone.
- A file that still changes after its last round stays as written. Its fix reports the rule
  `unsettled` in `Fix.left`, so the chain never writes a file half settled. `curator/audit` keeps
  its semantic edits for such a file, since a rename planned whole reaches other files too.
- Rejected: a fixer that wraps its own line. `form.nim` and `wrapping.nim` would then import each
  other, and a later fixer could undo the wrap.
- Rejected: one pass of wraps at the end. It can leave a wide line, and nothing then holds the
  repair back.
- Cost: a line broken at an operator stays broken where it later fits, as a break of the hand does.
- Verified by `suites/test_chain.nim`. Each case of the tree wraps to its exact output, and a
  second run writes nothing. A line that no wrap fits keeps its finding, held the second time. A
  file that never settles stays as written, with its finding.

**The whole-tree proof of the wraps: no fix changes what code means.** Verified by hand,
2026-10-04, with the scratch programs `prove.nim` and `trees.nim`. They ran `formatted` over every
Nim file of the tree, in memory. They ran it on the code that this section describes, and on the
code before the wideners.

- Every file settles with the chain run at most twice, and no file falls back to every line held.
- The run leaves no wide line. Two findings of spacing stay on one line of `test_mesh.nim` of
  `rga_visualiser`, where an `if` expression puts `:` before code. Sixty-two lines stay where the
  hand put them. Each run of them holds a line that its new indent takes past 100 runes, and
  thirteen lines do so. Four of those thirteen lines are chains of `assets.nim` of `audit`.
- The four messages that ended on their value take the shape. The usage error of `command.nim`
  writes its usage apart, so its message ends on its value.
- Rewrites, with the commit before in brackets:
  - call splits 620 (610), spaces 2,402 (2,367), comment gaps 745 (743);
  - doc positions 55 (54), messages 6 (3), signatures 117 (116);
  - operator breaks 9, continuations 1,718 and comments moved above 1, all new.
- The parser of the compiler, 2.2.12, reads each changed file to the tree it read before, once
  the rewrites of `## Layout fixes` and `## Content fixes` are normalised. Against the commit
  before, each file reads to the same tree once backticks and the shape of a message are
  normalised.
- `nim check` reads each changed file with the same result before and after, on its own pin, with
  the checkouts of each lock. A file that fails both times lacks a native library or a vendored
  source.
- A second run writes nothing, and the files in reversed order give the same output.

**The operator break adds no parentheses, by the ruling of the Architect on 2026-10-04.** Nim
refuses a line that opens with a binary operator. After an operator, the parser reads the next
line on (`optPar` in `compiler/parser.nim`). So a line breaks after the operator, and the parse
tree stays.

- The operator of lowest precedence breaks first, as the lexer reads precedence (`getPrecedence`
  in `compiler/lexer.nim`). A glyph that the lexer files with `+`, such as `⊕`, binds at 8, and
  every other glyph binds at 9. Each line takes the latest such operator that fits.
- `in`, `notin`, `is`, `isnot`, `of` and `as` never take a break, and neither does an operator
  glued on one side.
- A line that holds a comment, a `;`, a block keyword after its head, or a `:` before code stays.
  The `:` that types a binding passes, as in `let x: float = a + b`.
- A call split that fits no line falls back on the operator break.
- A compound operator stays whole, so `..^` breaks after itself.
- Verified by `suites/test_wrapping.nim`.

**Each line of an expression past its statement line takes four spaces more than that line (STYLE.md
§5).** Every such line takes that one indent, by the ruling of the Architect on 2026-10-04. The
statement line is the line where the expression opens. A call and a signature keep their layout of
one level, and an argument on its own line is the line where its expression opens. The fixer sets
that indent on the lines that the hand wrote too.

- An expression whose first piece opens its own line takes no step, and every line of it takes the
  indent of that line. The first piece opens its line where an opening bracket or a comma ends the
  line above. No `=`, `:`, separator, keyword or command head stands before the operator that ends
  that line (`isOwnLine`). The bracket or the comma already sets the expression apart from a body.
  So the hand keeps each piece at the indent of the first, as every broken expression of the PGA
  library does.
- Rejected: four spaces past the line where the first piece opens. It moved each later piece of
  a bracket or an argument away from the indent of the first.
- A bare value that opens its statement line, such as the value that ends a routine, keeps the
  four spaces. No bracket or comma sets it apart from the body around it. Only an opening bracket
  or the comma of a list before the first piece makes a chain flat. Verified by
  `suites/test_wrapping.nim`: such a value written flat takes the four spaces.
- The operator break reads the same predicate, so a line that knoller breaks takes the indent
  that the check asks. An argument that a call split leaves wide breaks flat.
- A chain that opens on the line after the `=` of a binding or an assignment counts from the line
  of that `=`. So it takes the four spaces too, its first line included, as the Architect chose on
  2026-10-04. Its lines take one indent, and never step in again.
- Any other value on its own line after `=` keeps one level under its statement, by the ruling of
  the Architect on 2026-10-04. That covers an `if` or `case` expression, a split call, a list that
  the hand shaped, and a value of one line. The fixer leaves such a value as written.
- The `=` of a routine, a lambda, a `type` entry or a named argument opens no such chain.
- A run of lines stays as written where a token spans lines, or where a comment line stands
  between two of them. It also stays where a bracket opened before it closes in its middle, or
  where its last line leaves a bracket open.
- Cost: a line that the hand packed to 100 runes crosses `LINE_MAX` at its new indent. No wrap
  reflows a string across lines, so such a line is held. Its whole run then keeps the indent of the
  hand, so the lines of one expression never part. Each line of it keeps its finding for the hand.
- Verified by `suites/test_wrapping.nim` and `suites/test_chain.nim`.

**The four spaces keep the head of a block apart from its body (STYLE.md §5).** Two spaces would
put a continuation line of a head on the indent of the body below it. So where the line right
above a body stands at the indent of the body, every continuation line of that head moves
(`headLifts`). A chain that opens mid-line inside a call takes the layout of one level of that
call. Such a head would otherwise keep its last line on the body.

- A head opens its line with a keyword of a block and ends on `:` at its own depth. The keywords
  are `if`, `elif`, `while`, `for`, `when`, `case`, `of`, `try`, `block` and `except`. A routine
  signature ends on `=`. Each line before the last ends inside a bracket, or on a binary operator
  or a comma. The body is the next code line, deeper than the head. `except` is there since its
  list of types can span lines as a condition does.
- Every continuation line moves by one step, so the shallowest takes four spaces past the first
  line of the head. A head whose continuation lines stand at one indent, as every case of the
  ruling does, takes that indent on each line. A deeper line, as of a nested tuple, keeps its
  place against the others, so the shape that the hand gave stays.
- The lift reads the text that the continuation rule leaves, in the same fixer. So each line takes
  one rewrite, and a source settles in one round.
- A mid-line chain already at four spaces stays. So does a split call or a signature that closes
  on its own `):` or `) =` at the indent of the head. A statement with no body under it, as
  `doAssert a,` with its message, stays too. So does a head that holds a comment line or a token
  spanning lines.
- The lift is part of the continuation widener, so it widens a line off held lines and keeps the
  width guard on a held one. Verified by `suites/test_wrapping.nim` and `suites/test_chain.nim`.

**A plain `#` trailing comment that does not fit moves to its own line above, by the ruling of the
Architect on 2026-10-04.** It takes the indent of its line. The lexer drops a `#` comment, so the
parse tree stays. A doc `##` and a block comment stay, and so does a comment that would not fit
above. Verified by `suites/test_form.nim` and `suites/test_chain.nim`.

## Articles

**Articles are the whole rule, as data.** `ARTICLES = ["a", "an", "the"]`. Tokens are
whitespace-split, punctuation-stripped and lowercased, after the backtick spans are removed.

- Cost: the label `A`, as in "Appendix A", is flagged. So a label goes in backticks, as
  `articles.nim` writes its own example.
- Verified by `suites/test_articles.nim`: 300 seeded random telegraphic comments pass, and each one
  with an inserted article fails. The citation `2.2a`, a URL and an underscored name pass. The
  corpus is seeded with `randomize(0)`, so the 300 are the same 300 on every run. It is the only
  sampled corpus in this project, and that seed is why its verdict does not vary (CONTRIBUTOR.md,
  "Tests are paramount").

## Open questions

- Install by git URL needs the `?subdir=curator/knoller` form of nimble. It is not verified with
  the nimble that 2.2.12 ships.
- Some rules read paths in the layout of this repository: `tests/`, a test stub, and the umbrella
  `<project>/src/<project>.nim`. They read the whole path, so the spelling of a path changes
  nothing. In another repository they would need to read paths relative to the nearest nimble
  file.
