# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-04 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | a72b7a39a1de2b08 |
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

**Each run warns of each fence, so whoever runs it sees each line that no fixer reads.** A fence
is the one escape from the rules, and a line it keeps is easy to forget. One warning names the
first line of each fence and the lines it keeps, markers included. Knoller prints it as
`fence-held warning`, and `koch fix` prints it after `warning:`. A warning changes no exit code,
because the charter grants the fence (Article X.1).

- Rejected: a fence as a finding that fails the run. A generated file would then fail every run,
  though its fence is allowed.
- Cost: a file with many fences prints one line for each of them.
- Verified by `suites/test_fences.nim` and `suites/test_command.nim`.

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
`wrapping.nim`. Spaces read `spacing.nim`, blank lines `blanks.nim`, and docs and defaults
`declarations.nim`. A construct that the scanner cannot read with certainty stays as written,
and its check stays silent.

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
- X.9 shows both forms: `s[1 .. ^1]`, a range and a prefix `^`, and `s[1 ..^ 1]`, the compound
  operator. The fixer keeps the operator that the source lexes as, so the choice stays with the
  hand.
- A range in prefix place, such as `a[.. 2]`, stays unread. Verified by hand, 2026-10-04, with
  `checkSpacing` and `fixSpacing` on that line.

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

**A call that fits stays on its line, and one that does not takes one argument to a line (X.3).**
A wrapped call that would fit is joined, and a split call never puts all its arguments on one
line of their own. The outermost call that crosses `LINE_MAX` splits first, and each line it
leaves is read again. An argument splits its own call only where that call is the whole argument.
An argument that the hand wrapped, and that fits no line, keeps its line breaks and moves with
its new indent.

- A list that no call opens, and that spans lines, keeps its rows: the fixer never reflows it.
- A call stays where it holds a comment, a long string that spans lines, or a block. A block is
  a keyword that opens one, `;`, `do`, or `:` at the end of a line outside a condition.
- A line break that joining could read again stays, such as one between two operands.

**A list written one item to a line takes a trailing separator (X.3).** That holds for a call,
parameters, an array, a seq, a set, a table, a tuple of several items, a constructor and an import
bracket. Parameters take the separator that their groups take. A parenthesis of one item takes
none, because `(a,)` is a tuple and `(a)` is a grouping. Verified by hand with 2.2.12, 2026-10-02:
the compiler accepts the separator in each of these lists, and `;` after the last parameter group.

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

**A nested helper takes one blank line on each side (STYLE.md §1).** A helper is a routine that
the body of a routine declares at its own level. The rule holds right after the doc of the
enclosing routine too. A one-line `template` is an alias, and stays. The side that leaves the
enclosing body is not read, because a sibling of the enclosing routine stands there. No helper
moves.

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

**A `to<Target>` call of a plain argument takes its subject first (STYLE.md §5).** A plain
argument is a name, with any call, index or field glued after it. A compound argument, a literal,
a generic call, several arguments and a call across lines stay prefix calls. A call followed by
a bracket stays too, because `y.toX(z)` and `y.toX[T]` read otherwise.

- The rewrite reads no symbol. A field named like the routine, such as `to_x`, would capture the
  method call. The tree holds no such field, and every changed file checks as before.
- Verified by `suites/test_targets.nim`.

## Wraps

**A repair that widens its line past `LINE_MAX` stays, and the chain wraps the line.** The
Architect asked for this on 2026-10-04, with three properties of `koch fix`. It is deterministic,
a second run writes nothing, and no option sets a style. The tab, comment, message, condition,
spacing, continuation and trailing separator fixers are wideners. Each one repairs freely off the
held lines, and keeps the width guard on them.

- The alignment and idiom fixers stay guarded, since a table column and an import bracket have no
  wrap. The renames and conversions of `curator/audit` stay guarded too.
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
  `<project>/src/<project>.nim`. In another repository they would need to read paths relative to
  the nearest nimble file.
