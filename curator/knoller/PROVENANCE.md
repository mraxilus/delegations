# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-04 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | fcd0c0d7055e7d4a |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a curator project, from the brief of the Architect. It holds the fixers of `koch fix`
that read the text of one file and nothing else, and the compiler that serves each pin. It holds
the checks of one Nim file too, which the static pass of `curator/audit` calls. The fixers that ask
the compiler stay in `curator/audit`. There is no vendored source.

## Package

**Knoller is a nimble package that requires its compiler and nothing else.** `src/knoller.nim`
is the umbrella, and the modules sit under `src/knoller/`. So a repository other than this one
can install it, and no rule of knoller reads the layout of this repository.

**Atlas installs knoller by its name, through an override that gives its address and folder.**
Knoller sits in the folder `curator/knoller` of this repository. So a project that requires it maps
the name `knoller` to `https://github.com/mraxilus/delegations?subdir=curator/knoller` in its
`atlas.config`. Its requirement names a commit, as `knoller#<commit>`. Its `nim.cfg` names
`curator/knoller/src` inside the clone by hand, since Atlas 0.14.7 writes a path without that
folder. `curator/assayer` requires knoller so, and its record gives each rejected form and each
cost (`curator/assayer/PROVENANCE.md`, Package).

- Verified by hand with Atlas 0.14.7 and Nim 2.4.0, 2026-11-15, in a scratch project outside this
  repository. The lock restored into a fresh clone, and a program that imports `compilers` and
  `pins` built and ran.

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

**Each build of knoller fails on an unused import.** `nim.cfg` at the root of the package makes
the warning `UnusedImport` an error. The compiler reads `nim.cfg` in each directory above its
project file. So the flag reaches the suite that testament runs, one suite that runs alone, and the
command line built from the root of the repository.

- Rejected: the flag in the `cmd` of the stub. It reaches the build that testament runs, and no
  other.
- Verified by hand with Nim 2.2.12, 2026-10-06, and with Nim 2.4.0, 2026-10-29. An unread
  import in a module of `src/` fails `nim c` of `tests/test_suites.nim`, of one suite alone that
  imports the module, and of `src/knoller.nim`. An unread import in a suite fails `nim c` of the
  stub and of that suite. Through `koch test`, testament reads the flag too.
- Cost: a build of `koch` and the suites of `curator/audit` read no configuration here. So an
  unused import in knoller fails the suite of knoller alone, which `koch check` runs whenever
  knoller changes.

## Reports and rules

**Each report names a rule, and the caller cites its article.** A rewrite reports its path, its
line and its `Rule`. A finding of a check also reports its message, which ends with the value it
got (Article IV.4). The name of a rule is the string of its enum member, such as `expression
spacing`. So `koch fix` prints the name of the rule with its article, as in `expression spacing
(X.9) fixed`. `curator/audit` holds the article of each rule in `CITATIONS`, indexed by `Rule`,
so a new rule without a citation does not compile there.

- The id of a rule is the slug of its name, such as `expression-spacing`. The id is stable, so a
  tool can read the output of the command line. Verified by `suites/test_rules.nim`: each rule
  has an id of its own.
- A rule states one rewrite, so the caller cites one article for it. One check that makes two
  rewrites, which two articles state, reports each under a rule of its own (D1 c of #563). So
  `import-brackets` joins the imports of one directory (X.5), and `module-bracket` drops the
  bracket of one module (STYLE.md §5).
- A message of a check names no article. It reads `<sentence>; got <value>.`, or `<sentence>.`
  where it gives no value. The Architect chose this shape (D2 a of #505). Knoller runs on any
  repository, whose charter need not be this one, and the README lists the id that each line
  names. The one shape lets a caller find where the sentence ends, and `koch` cites the article of
  the rule there.
- Verified by `suites/test_rules.nim`. The messages of `checkBlanks`, `checkDefaults` and
  `checkFenceHeld` hold no article. No string literal under `src/` holds `§`, or `(` before a
  Roman numeral and a dot.
- Rejected: the article written into each message. `CITATIONS` would then stand twice, and each
  message would cite the charter of this repository wherever knoller runs.
- Cost: no suite of knoller holds the text that `koch` prints. The suite `test_findings.nim` of
  `curator/audit` holds it, article included, through the real check of each message that `koch`
  prints.

## Renderer

**Each finding prints in one of two forms, through `knoller/report`.** The terminal form serves a
reader at a terminal, and the line form serves a pipe or a log (STYLE.md §3). A finding is a
`Notice` that holds only the parts that its check knows (D3 a of #1002). So its location shows the
path, the line and the column, each only behind the part before it. The renderer is pure. The
caller reads the terminal, the flag and `NO_COLOR`, and passes what they say.

- The terminal form prints the location and the rule, the summary, the source line with a marker,
  `actual` and `expect`, and `help`. A blank line stands between two blocks, and a block shows
  only where the finding holds its parts.
- The source line shows only where the finding holds its line and the text of that line. The
  marker shows only where it holds a column too.
- A source line over 80 runes shows a window of 80 runes around the span, and `…` marks each
  edge that the window cuts. A finding of width names a line of hundreds of runes, which a
  terminal would wrap.
- Column and span count runes, as the width of a line counts them. A control character of the
  source line prints as its control picture, as `␉`, so the marker stays under its rune.
- The terminal form quotes a value that is empty, or whose edge or control character would hide
  it. So each value stays visible, as Article IV.4 asks.
- A message cuts at its first `; got ` outside a code span, and a code span runs to the next run
  of as many backticks (`sentenceEnd`). So a sentence that quotes ``…; got `{value}`.`` ends after
  the quote. The sentence is the summary, with its first letter lowercase (`initNotice`). The
  value after `; got ` is the actual, out of the code span that it stands in whole.
- Cost: a backtick in a sentence that no run of as many backticks closes pairs with the backtick of
  the value. The sentence then runs to its closing period. No message of knoller holds such a
  backtick, and reading holds that.
- Each suite compares the short text of a finding (`brief`), as D3 c of #1002 rules. It holds the
  summary, then the actual after `; got`, the expected value after `; expect` and the help after
  `; help:`, each where held. The rule stands apart, so the text reads as the message.
- A sentence that names an absence ends without `; got `, so the notice holds no actual. Article
  IV.4 never takes an in-range value for an absence, and `none` would read as one.
- The line form reads `path:line:column: rule: actual="…" expect="…" message="…" help="…"`. Each
  value is quoted, with `\`, `"` and each control character escaped, so a finding takes one line.
  Help stands last, so a hook and a log keep each remedy (ruling 7197275206 on #1002).
- A warning prints in both forms, with `warning` after its rule, as the command line of knoller
  marks it (D2 a of #1002). A rewrite is no finding, so its caller keeps its one line.
- Color shows in the terminal form on a terminal alone. `NO_COLOR` set to any text turns it off,
  as no-color.org reads it, and `formOutput` takes the form that a flag forces.
- Verified by `suites/test_report.nim`: both findings of the example of #1002, as that example
  draws them, and each case above.
- The command line of knoller prints each finding that stays for the hand through the renderer,
  and each warning too. Each shows the text of its line as given. A rewrite and an unsettled file
  keep their one line, since a tool reads them. `--form` forces a form, and else `main` takes the
  terminal form where stdout is a terminal. In the terminal form, a blank line stands before
  each finding and before the count.
- Verified by `suites/test_command.nim`: both forms of one run, the flag, and the line form of
  each warning. The suites that read what a run prints hold the line form.
- Cost: the marker counts each rune as one column. So a wide glyph, as of East Asian text or an
  emoji, shifts the marker to the right of its span.
- Each verb of koch that reports prints each finding and warning through the renderer too, and
  each hook prints each finding in the line form. A finding of a report of knoller keeps the id
  of its rule there. Each check of koch takes an id `koch.<name>` (D4 a of #1002).

## Chain

**One chain runs every fixer in one order until the source settles.** `formatted` reads the
fence, masks it, runs the fixers of the dialect, and writes the fenced lines back.
`checkFormatting` reports each rule that the fixers clear, on the same masked view. A dialect is a
module (`.nim`), a script (`.nims`) or a package (`.nimble`). A module takes every idiom fixer and
check, and a script or a package takes those of any Nim code (`## Idioms`).

- `curator/audit` maps each kind of Nim onto a dialect. It applies the fixers that need more than
  one file, then gives the source to `formatted`.
- The caller also gives the facts of each file that its text does not hold. They are the mode of
  its articles (`## Articles`), its nearest nimble file (`## Layout of a package`), and whether it
  is drive code (`## Fixed waits`). It gives the constants that the other modules of its package
  export (`## Staging`), and the defaults of its configurations (`## Configuration blocks`).
- The header of `chain.nim` gives the order of the fixers, and why each one comes where it does.
- The chain can run all its rounds again, and `## Wraps` gives why.
- Verified by `suites/test_chain.nim`: a source that breaks each layout rule settles in one run,
  and a second run writes nothing. A script keeps its imports as written.

## Layout of a package

**Knoller reads the layout that the tools of Nim set, and its caller gives the rest (D2 a of
#886).** Knoller takes the folder of the nearest nimble file as the root of the package. It keeps
the rules of tests and of the umbrella, and reads each below that root. The folders of drive code
and the define that stubs pass are habits of one repository. So the caller says which file is
drive code (`## Fixed waits`) and which options its compile takes (`## Semantic pass`), and the
command line says neither.

- The caller names the nimble file nearest each file, written as its path is, and nothing where
  none stands above (`nimble`). The chain takes that string and reads no file system, so it stays
  pure.
- One string carries both facts. Its folder is the folder of the package, and its name names the
  umbrella, so the two cannot disagree. Rejected: the folder and the name as two inputs, which a
  caller could give apart. Rejected: a lookup inside the chain, which would read the file system.
- A test file lies below `tests` of its package, at any depth (`partTests`). A stub is
  `tests/test_*.nim` there, or a file of a category (`## Layout fixes`). The umbrella is
  `src/<name>.nim` beside `<name>.nimble`, whatever folder holds both. So a package at the root of
  its repository has an umbrella, and a clone needs no folder that bears the name of its package.
  Cost: a package whose `srcDir` is not `src` has no umbrella here.
- A file with no nimble file above it takes no rule of tests, stubs or umbrella. So these rules
  give fewer findings there, and never a false one. Rejected: the last directory `tests` of the
  whole path, which makes a test file of each file below a directory `tests` above the repository.
- A fixer that reads the nimble file is a step of its own kind (`placing`). Those are the fixers
  of stub keys, of the profiler import and of the blank lines of tests. So no other fixer takes a
  new parameter. Cost: a fourth kind of step.
- Verified by `suites/test_blanks.nim`, against a table of paths and nimble files. It holds a
  package at the root, a folder of another name, a package inside another, a path of Windows, and
  no nimble file.
- Each test file, stub and umbrella here lies below the folder of the nimble file of its project.
  Verified by hand over each Nim file that git lists, 2026-11-14.

**The command line reads the nearest nimble file from disk, in the walk that reads the pin
(`nimblesNearest`).** One walk up from the directory of each file finds both. A directory that
holds several nimble files names no package, as it names no pin, since nimble refuses such a
directory.

- Verified by hand with the nimble 0.26.2 that 2.4.0 ships, 2026-11-14. In a directory of two
  nimble files, `nimble dump` stops with `Only one .nimble file should be present`.
- Verified by `suites/test_command.nim`, on a real tree. A package at the root of a clone takes
  the rule of its umbrella, and a package inside it takes its own stubs. A directory of two
  nimble files, and a tree with none, take no rule of stubs.
- Verified by `suites/test_command.nim`, through the command line built from its own source. Run
  over a package `foo` at the root of a clone named `clone`, it names the umbrella `src/foo.nim`.
  It names no fixed wait of `tools/build.nim`.

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
so each marker reads as a plain comment, and each line keeps its number. `checkFenceHeld` keeps each
finding whose line falls inside a fence. So a fence counts what its lines report without the fence.
A rule that a fixer clears and a rule left for the hand count alike, because a check names both.
Each check of knoller that the static pass of `curator/audit` reads counts too, in each dialect.

- Rejected: one warning for each break inside a fence. The Architect chose one line for each
  fence, so a large table in a fence costs one line.
- Rejected: a dry run of the fixers. It counts only what a fixer clears, so it misses
  `not-over-binary`, which no fixer reaches.
- Rejected: a fence as a finding that fails the run. A generated file would then fail every run,
  though its fence is allowed.
- A fence keeps its lines from the fixers and from the checks of `checkFormatting`. It never keeps
  them from a check that the static pass reads, since the static pass reads no fence. So a finding
  of such a check inside a fence fails the run, as it fails the static pass.
- A tab in a string counts as `tab`, since that check reads every tab, and `tab-in-string` names
  its fix alone.
- Cost: a file with a fence takes the checks twice, once masked and once as given. A file with no
  fence takes them once. A delegate measured the cost on 2026-10-04, with a debug build and two
  runs of each. `knoller --check` on `starfield.nim` of `rga_visualiser` took 11 s, against 4 s
  before. That file has 22,560 lines, and its fence holds 11,252 calls.
- Verified by `suites/test_fences.nim`, `suites/test_chain.nim` and `suites/test_command.nim`. In
  `suites/test_chain.nim`, the lines of a fence report the same rules when no marker fences them.

## Command line

**`knoller [--check] [--nim:path] path...` fixes each Nim file that the paths name.** A directory
stands for the Nim files that `git ls-files` lists under it. A run writes only the files that
change, and `--check` writes none. Each finding names a path, a line and a rule id, an unsettled
file names its path alone, and the count comes last. A clean run exits 0, and a usage error
exits 2. A run exits 1 where a finding is left, where a file is unsettled, or where a change is due
under `--check`.

- No option sets a style. The rules are constants, and a fence is the only way to keep a layout.
- `--nim` names the compiler whose parser proves each group of needless parentheses
  (`## Content fixes`). Without it, each file takes the compiler of the pin above it, else `nim`
  on `PATH` (`## Compilers`). Where no compiler answers, one line `needless-parentheses warning:`
  comes before the count, and the exit code stays.
- A file that holds a type conversion candidate is asked of the semantic pass before the fix
  (`## Semantic pass`). A file the pass cannot resolve prints one line `path: type-conversion
  warning:` with the reason, and the exit code stays.
- Each private symbol and `{.all.}` of a named module is asked before the fix, and so is each
  candidate `proc`. The pass reads the project of the nearest nimble file (`## Sibling markers`,
  `## Pure routines`). A file whose pass resolves nothing prints one line `path: marker-used
  warning:` or `path: func-pure warning:`, with the reason, and the exit code stays.
- Each rename that a named file asks is planned before the fix, across the project of the nearest
  nimble file (`## Semantic pass`). A rename refused prints one line `path:line: <rule-id>
  warning:` at its declaration, with the reason, beside the finding left of the check.
- A nimble file whose copy `atlas.lock` holds is passed over, because a rewrite would leave the
  copy stale.
- A file that the fixers do not settle prints one line, `path: unsettled: <message>`, after the
  rewrites and before the findings left. The line has no line number and no rule id, because the
  fault is in the tool (`## Chain`). The run exits 1, because the file stays as written.
- Verified by `suites/test_command.nim`, through `joined` with parts built by hand, for an
  unsettled file alone and beside a file that settles. The suite holds the line, its place in the
  output and the exit code.
- The module is `command.nim`, because a path spells its words in full (Article V.9), and no
  glossary lists the acronym CLI.
- `outcome` decides what a run writes and prints from text alone, so its suite needs no file.
  Verified by `suites/test_command.nim`. The suite also holds the README to every rule id.
- A directory that gives no Nim file is a usage error, and its message says why. The directory
  is outside a git work tree, or git lists no Nim file under it. A silent `0 to fix.` reads as a
  clean run over files that knoller never read.
- Each fixer reads the path whole: absolute, with `.` and `..` resolved (`toAbsolute`). So the
  test file, the stub and the umbrella read alike from any directory, and the output prints the
  path as named.
- That path is `/` separated on every platform. A path join on Windows writes a backslash, so
  `toAbsolute` and the listing of a directory write each separator `/` (`slashed`). Each path
  relative to a project reads with `/` too. So a rule finds `tests` on Windows as it does on
  Linux, and one tree prints the same output on every platform.
- Fixers read the text as a commit stores it. Git for Windows checks out CRLF by default, and a
  commit turns it back into LF. Where `git ls-files --eol` reports such a checkout, knoller reads
  LF and writes CRLF back (`isConverted`). So no CR reads as trailing whitespace, and no fix
  rewrites line endings. CRLF that a commit keeps stays a finding.
- Verified by `suites/test_command.nim`, on a real checkout with `core.autocrlf=true`. The suite
  also holds each setting and attribute that decides the conversion. A demo checkout gave 3
  findings, where it gave 7 before. Cost: one git call in each directory of the files named.
- Each line of output is a line of the file as given. A finding left in the fixed text traces
  back through the fix, as a rewrite does. A line that the fix inserts has no line as given, so
  a finding there prints with the path alone.
- `koch fix` prints no check of the fixed text. A marker that moves a trailing doc adds a line, so
  the fix traces each later report back through it (`originApplied`).
- Verified by `suites/test_command.nim`. One file named from two directories prints the same
  lines, and a finding left prints at its line as given.
- Verified by hand, 2026-10-04, with the built binary. `--check` of a directory outside a git
  work tree, and of one where git lists no Nim file, exited 2 with its reason. On the PGA
  library, `--check suites.nim` from inside `tests/` and `--check tests/suites.nim` from its
  parent each gave 73 changes, with the same lines.
- Verified by hand, 2026-10-04: the built binary fixed a scratch file, and a second run wrote
  nothing. A run without a path, and a run with an unknown option, exited 2.

**After the fix, every check of knoller reads the text that the fixers leave (`checkSource`).**
Those are the checks of `checkFormatting`, off fenced lines, and the checks of knoller that the
static pass of `curator/audit` reads, on every line. So a finding that no fixer clears prints as
`left`, and the run exits 1.

- Rejected: the checks of `checkFormatting` alone, with the idiom checks on a file that holds a
  fence. That run exits 0 on a wide line that no wrap fits, a tab outside a string, a capital
  article or a refused entry block.
- The names check takes no word as exempt beyond the jargon of V.6. The glossaries belong to a
  repository, so the command line reads none, and `koch` passes the words of its own. The acronym
  rule of V.9 needs a glossary, so the command line runs none (`## Names`).
- Verified by `suites/test_command.nim`, for each rule of knoller that the static pass reads and
  the fixers can leave. A source of each, as the fixers leave it, exits 1 and names its rule. A
  file that declares `toJSON` beside a call of `parseJson` exits 0, in each dialect.
- Verified by hand, 2026-10-06, with a debug build of `2595a5dc` and of `471007f`. `knoller
  --check` on `curator`, `rga_visualiser`, `pga_benchmark` and `dance_ontology` reports no finding
  left that `471007f` does not report.
- Cost, measured on that run, two runs each. `rga_visualiser` took 34.3 s and 34.6 s, against
  32.7 s and 32.1 s. `curator` took 20.5 s and 19.8 s, against 19.1 s and 19.5 s.

**The command line fixes each file on a pool of threads, one for each core (`pools.nim`).** The
fix of a file reads its own file and what the run read, and nothing that the fix of another file
writes. At `2d496af8`, one file waits for the one before it, and `koch fix` runs the same loop.
There the fixes of all files take 26.6 s of the 65.0 s of `koch fix --dry-run curator/knoller`.
Meanwhile three of the four cores wait (the profile on #1001).

- `outcomeProven` gives each file to a thread of the pool, and each file that asked the parser
  again, after its batch answers. The parts keep the order of the files, as one loop gives them.
- A job holds the facts of its file, as a call of `part` for one file takes them (`JobPart`). The
  proofs of its batch and the plans of the run stay in the caller. The job reads them through a
  pointer, since a copy would hold each source asked. The caller changes the proofs only between
  two runs of the pool.
- `outcome` stays one loop, since a `func` starts no thread.
- Verified by `suites/test_command.nim`, which holds `outcomeProven` equal to a loop that fixes
  every file again in each round (`outcomeEvery`). Its files ask the parser, and some do not.
  Verified by `suites/test_pools.nim`, for the order of the answers.
- Verified by run of `knoller --check --form:line curator/knoller` over the tree at `2d496af8`,
  2026-11-26. Knoller built there and at `8a7b2f61` prints the same 2,746 lines in each of three
  runs, and the runs alternate between the two builds. The median falls from 62.1 s to 34.4 s.
  Each build is the debug build that `nim c` makes, on 4 cores at 2.10 GHz, under a load of 1.42
  to 2.25.

**The command lists a directory through `runGit`, which reads stdout and stderr of git apart.**
Git ends a warning on stderr in a newline, while the paths end in NUL. So one stream that carries
both glues the warning to the first path. `tree.nim` of `curator/audit` reads git through the same
procedure.

- Rejected: `execCmdEx`, which joins stderr to stdout.
- Verified by `suites/test_command.nim`. While the trace of git writes to stderr, each path stands
  alone, and a directory outside a work tree is refused.

## Compilers

**The command takes one compiler for each file, in a fixed order.** The compiler that `--nim`
names comes first. Else knoller takes the compiler of the pin in the nearest nimble file at or
above the directory of the file. Else it takes `nim` on `PATH`. This order (D1 of #548) lets a run
by hand take the pin of each project with no option.

- A pin is `requires "nim == <pin>"`, or `requires "nim#<commit>"` with a full commit, as nimble
  writes a commit. A range, a branch, a tag and a short commit name no pin. A nimble file that
  holds one of them gives `nim` on `PATH`. Verified by `suites/test_pins.nim`.
- The nearest nimble file decides. A package inside another package, with no pin of its own,
  takes `nim` on `PATH`, and never the pin of the outer package.
- The files of one compiler form one batch. Each batch asks its own prover and holds its own
  answers, because two compilers can read one source in two ways. So the files under two pins
  get one prover for each pin.
- A pin that no compiler serves proves nothing. The rule removes no group in its files, and the
  run prints one warning that names the pin. No other compiler stands in (`GUIDE.md`,
  Toolchain).
- A directory that holds more than one nimble file has no pin that knoller can trust. Its files
  prove nothing, and the run prints one warning that names the directory.
- A warning changes no exit code.
- A pin resolves when the first file under it asks the parser. So a pin that no file asks about
  costs no fetch.
- Verified by `suites/test_command.nim`. `--nim` wins over a pin, and a pin wins over `PATH`. A
  file with no nimble file above, or under a nimble file of no pin, takes `PATH`. An unserved pin
  and a directory of two nimble files each warn once, and remove nothing. Two pins get two
  provers, and each is asked about the files of its own pin alone.
- In that suite the parser is real for `--nim` and for `PATH`. It is a stub for a pin, because
  to serve a pin can fetch a compiler.

**Knoller resolves each pin to a compiler, and `curator/audit` imports that resolution.** It
takes `PATH` where that already serves, then the cache, then a fetch. A release arrives as a
tarball. A commit comes from a clone of `nim-lang/Nim` and a run of `sh build_all.sh`, which is
the recipe of `check.yml`. A platform that nim-lang.org publishes no build for takes the same
recipe.

- On Windows, knoller fetches and builds nothing. Nim-lang.org publishes no tarball for Windows
  that this reads, and the build needs `sh`. So a pin comes from `PATH` or the cache alone there,
  and one line on stderr names both places. Before, such a pin cloned Nim and then failed.
- A compiler that will not start reads as none. On Windows no shell stands between, so the start
  raises, where `sh` exits 127.
- The root of the cache is a proc, since the home directory is an effect on Windows. As a func,
  it kept knoller from compiling for any Windows target.
- Resolution lives in knoller, because the command needs it, and the audit imports knoller and
  never the reverse (D3 of #548). One copy serves koch, the semantic pass of audit and the
  command.
- `Toolchains` holds the compiler of each pin asked so far, and resolves each pin once. It holds
  a failure too, so a pin that nothing serves costs one try.
- The cache is `~/.cache/knoller/nim/<pin>`, and `$KNOLLER_NIM_DIR` moves it (D4 of #548). Koch,
  knoller and `.claude/hooks.sh` all use it, so a machine holds one toolchain for each pin. It
  sits outside the checkout, because the audit reads untracked files.
- Everything that resolution prints goes to stderr: its own line, and the output of curl, tar,
  git and the build, line by line. So the stdout of knoller holds its sorted reports alone.
- Verified by `suites/test_compilers.nim`. Stub tools that print on both streams leave stdout
  empty. `PATH` serves its own version, and the cache serves next with no fetch. A failure is
  held, and the prover of a pin runs the parser of the compiler that serves it.
- **A half-built toolchain lies.** A probe of `bin/nim` before the `boot` step of the `koch` of
  Nim finishes returns the bootstrap binary of csources. That binary answers `--version` with an
  unrelated commit. So a build completes beside its destination, and moves in only when it is
  done, as a tarball does.
- Rejected: a directory that a delegate populates by hand, which leaves the defect for anyone
  who has not. Rejected: the layout of `choosenim`, a second convention that cannot serve a
  commit pin at all.
- Cost: the first run on a pin that the machine lacks fetches a release in seconds, or builds a
  commit in minutes, once. A fetched release takes 140 MB to 192 MB, and a built commit about
  2.4 GB. Release 2.4.0 takes 192 MB, measured with `du`, 2026-10-29, and the others are
  measured below. Nothing prunes them.
- On CI, the installed compiler of each job serves its pin, so resolution stops at `PATH`.

**The fetched tarball is checked against the digest published beside it.**
`<tarball url>.sha256` is exactly the output of `sha256sum`, for every release checked.
`fetchRelease` fetches it, and refuses a tarball whose bytes differ.

- What it defends against, stated rather than overclaimed: the digest comes from the same host
  over the same TLS as the tarball. So it catches a truncated, mirrored or swapped file, and
  **not a compromised nim-lang.org**. A signature would answer that, and none is published.
  `.asc` beside these tarballs is a 404, read rather than assumed.
- Text that is not a digest reads as *nothing*, rather than as a digest that cannot match. So
  an error document or an empty answer reports "none published" instead of "mismatch". The two
  are different failures, and say different things to whoever reads the line.
- Verified by a break of it, and not by a fetch that happened to pass. `suites/test_compilers.nim`
  digests a temporary file, changes one byte, and checks that the digest moves. The parse is
  mutation-tested: drop its hex validation and the suite reddens.
- Honest limit of that test: the exit-code check of `sha256sum` is belt-and-braces, because the
  parse already rejects the error text, so no test distinguishes it. It is kept for saying what
  it means.
- Verified by hand with koch, 2026-09-10: `2.2.2`, which nothing on the machine served, fetched,
  digest-checked and unpacked.

**The command takes a commit pin from the nimble file with no option.** Verified by hand,
2026-10-05, with the binary built at `db2f90a`. It ran on a copy of `pga_benchmark`, which pinned
a commit then, in a new git repository, with a private cache.

- With no `--nim`, knoller took the pin `27763495b` from `pga_benchmark.nimble`. The cache held
  no compiler for it, so knoller built one, and that first run took 603 s. A second run took
  8.1 s, and a run with `--nim` naming the same compiler took 8.4 s.
- The output of each run without `--nim` equals the output with `--nim`, byte for byte. Each
  gives one group to fix, `(⊛m)` at line 35 of `proposals/03-partner-sign/laws.nim`. The build
  printed 717 lines, all on stderr, and stdout held the report alone.
- On a directory with no nimble file, knoller took `nim` on `PATH`. Its output equals the output
  with `--nim` naming that compiler, byte for byte.
- With the pin `0.0.99`, which no release serves, knoller printed one warning that names the pin,
  and removed nothing. The exit code was 0. The fetch printed its line and the 404 of curl, on
  stderr alone.
- Cost, measured on that run: the built toolchain takes 2.4 GB, and its bootstrap tree
  `csources_v3` takes 2.0 GB of that. The release 2.2.12, fetched, takes 140 MB.

## Semantic pass

**Some rules ask what a name means, so knoller asks the semantic pass of the compiler.** Text
cannot tell a conversion `x.T` from a field or a module path, such as `rigid3.Point`. Text cannot
find every use of a name across modules either. So `symbols.nim` asks `nimsuggest` of the
toolchain that serves the pin of the project.

- The caller names four facts for each file it asks. They are the directory the run starts in,
  the file that includes it, the toolchain, and the options of its compile (`defines`). The
  command line reads the first three from disk. The run starts in the nearest directory that holds
  a nimble file, and the includer is read among the Nim files git lists there. The toolchain is
  the one that proves parentheses (`groupByCompiler`). `koch` reads the same facts from its tree
  instead.
- One `nimsuggest --v3 --tester` serves each entry: the file itself, or the file that includes it.
  It runs in the project directory, so the `nim.cfg` of the project applies. It takes the options
  that the first request of its entry names. Verified by `suites/test_symbols.nim`, through two
  requests of one includer, where the first alone names a define.
- The define that stubs pass is a habit of one repository, so knoller adds none, and the command
  line names none. `koch` names `-d:testing` for a file under `tests/` of a project, as each stub
  of STYLE.md §6 passes it.
- Verified by `suites/test_symbols.nim`: a name that `-d:testing` alone declares resolves where its
  request names the define, at any path, and nowhere else. Verified by `suites/test_command.nim`:
  the command line leaves that name unresolved under `tests`.
- Tester mode reads commands as `--stdin` does. It prints `!EOF!` once ready and after each
  answer, with no help and no prompt. On Windows, `--stdin` prompts `> ` before each command,
  which glues the prompt to the first line of each answer.
- A run reads its commands from a file and writes its answers to a file, through the
  redirection of the shell. A pipe holds 64 KiB, and a run whose answers fill it stops reading
  commands. So a run fed through pipes, all commands first, waits forever on a large entry.
  Verified by `suites/test_symbols.nim`, which passes 64 KiB each way.
- The shell is `sh` on POSIX and `cmd` on Windows. There `poEvalCommand` hands the line to
  `CreateProcess` with no shell between, so nothing would read the redirection (`lineRedirected`).
  Cost: `%` in a path expands in `cmd` where it names a variable.
- Each command quotes its file. `nimsuggest` reads an unquoted file up to its first `:`, and each
  Windows path holds one after its drive. Verified by `suites/test_symbols.nim`, through a colon
  in the name of a directory on POSIX.
- A toolchain with no `nimsuggest` starts no run, and each of its files stays unresolved with
  that reason. Output that holds no answer reads as none. Before, empty output read as one clean
  answer. So on the PGA library at `749fecf`, with no `nimsuggest` on `PATH`, the two conversions
  of `pga/multivectors.nim:75` stayed with no warning. Verified by `suites/test_symbols.nim`.
- `nimsuggest` waits 250 ms between two commands on its input, so each site costs a quarter of a
  second at least. Measured on the container of the curator with 2.2.12, 2026-10-04: 300 sites of
  one small file took 76 s, with 0.6 s of processor time.
- Each file is checked first. A file that reports an error on the C backend is asked again on the
  JavaScript backend. A file that fails both stays unresolved, with its first error.
- A routine that returns a value answers its own declared name with its implicit `result`. So that
  answer reads as the routine declared at the site, where each use of it resolves. Both pins that
  koch serves answer so (verified by hand, 2026-10-03).
- Rejected: the compiler as a library inside knoller. Every build of knoller would compile the
  compiler. Knoller would also bind to one pin, while two pins can lex one glyph apart, as 2.2.12
  and 2.4.0 do.
- Rejected: `nim check --def` for each site, which compiles the project once for each site.
  `nimsuggest` ships with each toolchain that knoller serves, so the pass costs no build.
- Cost, measured 2026-10-02 on the container of the curator: about 2 s for each entry of a
  curator module. A front-end or a suite of `rga_visualiser` takes 5 to 9 s. Only a file with a
  candidate asks.
- A site of an included file asks `dus`, whose answer opens on the same definition as `def`.
  Verified by `suites/test_symbols.nim`, which resolves a use of an included file to its `let`.
- On commit `27763495`, `def` in an included file recompiles the file that includes it for each
  site, and `dus` recompiles only what is dirty. Read in `executeNoHooksV3` of `nimsuggest.nim`
  at that commit. Measured on the container of the curator, 2026-10-04, over 20 sites of the shared
  suite of `rga_visualiser` at `c5c65db`. There `def` took 345 s and `dus` took 50 s.
- A site of the entry itself keeps `def`, because `dus` lists every use of the symbol. Measured in
  the same run: `dus` gave 182 use lines beside the 20 definitions. That the list grows long for a
  common symbol such as `float` is inferred, and an included file pays that output alone.
- Cost: a file that needs a checkout of its lock, or a native library, stays unresolved without
  it. A branch of `when` that the defines leave out resolves nothing.

**A type conversion `x.T` becomes `T(x)` where the pass settles it (STYLE.md §5).** The candidate
is a type-like name glued after a receiver. The name must resolve to a type, and the last name of
the receiver to a value. A parenthesised receiver gives the call its parentheses, and a tuple
keeps its own.

- The edits apply once, before the chain, on the source as given. They move no line, so the fence
  holds, and no edit lands on a fenced line.
- A receiver that is a module the file imports, or a capitalised name, asks nothing. That keeps
  the pass to the few files that hold a candidate. A global is the one capitalised name that
  asks, and its check waits (`## Conversion prefix`).
- Cost: a file whose only candidate is the conversion of a global asks the pass too. That cost is
  unmeasured.
- `knoller --check` runs the pass on each file that holds a candidate, and reports each
  conversion as due (D1 a of #558). A file that holds none asks nothing, so a run on a clean tree
  compiles nothing more. At `da2edae` no file of the four projects held one.
- A file the pass cannot resolve keeps each conversion, and prints one warning with the reason.
  The reason is its compile error, a pin that no compiler serves, or two nimble files in one
  directory.
- Verified by `suites/test_conversions.nim`, and by `suites/test_command.nim`, which runs the pass
  on a fresh repository and reads the conversion it reports.

**A coined abbreviation (V.6) is renamed to its full word at every use, or the rename is refused
whole.** `names.nim` reads each declaration that the names check reports, and spells it out word
by word, in its own case. `rewrites.nim` plans the rename from what the pass resolves.

- The declaration must resolve to the symbol declared at that very site. The names scanner can
  read a use as a declaration, and a rename there would repeat the real one.
- A site that resolves to the declaration is renamed, and one that resolves to another symbol
  stays. A site that resolves to nothing refuses the rename.
- A site whose answer names another identifier refuses the rename too. That answer is a call that
  the compiler places on the name, such as `items` in `for e in x`, or a converter. Verified by
  `suites/test_rewrites.nim`, and by hand with the `nimsuggest` of commit `27763495`, 2026-10-04:
  `def` at `WINDING` in `for (which_end, side) in WINDING:` of `mesh.nim` at `c5c65db` answers
  `items`.
- An old name inside the braces of an interpolated string, `&"…"` or `fmt"…"`, refuses the rename.
  The module strformat parses it from the text, so no token stands there to resolve. Verified by
  `suites/test_rewrites.nim`. Verified by hand on `c5c65db`, 2026-10-04: such a name left as
  written broke `nim check`.
- A named argument or a constructor field resolves through its callee. It is the declaration where
  it is a parameter or a field of that callee.
- The new name must not stand in a file that the rename writes. It must not name a global
  declaration of a module compiled with the declaring file, `system` among them.
- A global there is what a bare name reaches: `module.name`, or an enum member. The pass answers
  fields, parameters and locals of other scopes too, and none of them can collide. Verified by
  `suites/test_rewrites.nim`. Verified by hand on `c5c65db`, 2026-10-04: `globalSymbols` answered
  fields such as `camera.SphereWorld.radius`.
- Cost: the presence test reads each token of the new name, a field access among them. So a
  rename that would compile can be refused. Inferred from `sites`, which reads every name token.
- No edit may land on a fenced line, or widen a line past 100 characters. A rename that reaches a
  file that the run does not fix is refused.
- A mention of the old name in backticks, in a comment of a file where every use is renamed, is
  renamed too.
- The planner takes the new name from its caller: the V.6 rule here, and the case rule below.
- Each edit spans the name token at its site, because Nim reads `tmpDir` as `tmp_dir`. Verified
  by `suites/test_rewrites.nim`.
- A new name that is a keyword, or `result`, refuses the rename, because the compiler reads either
  as something else. Verified by `suites/test_rewrites.nim`.
- Cost: the scope is the caller's. The command line reads the project of the nearest nimble file,
  and writes only the named files (D2 a of #558). `koch` reads the project and the root files.
- Cost: overloads in one file share the qualified name of a parameter. So a named argument to
  another overload is renamed too, and its build then fails.
- Verified by `suites/test_rewrites.nim`, `suites/test_names.nim` and `suites/test_command.nim`.

**The rename has its proof on commit `c5c65db` of `main`, because the tree at `de0c1899` holds no
V.6 finding, by `nim r koch check-files`.** Verified by hand, 2026-10-03, with a scratch program
over `renamesAbbreviation`, `planRename` and `resolve`. It applied the planned renames alone to a
copy of that tree, with the checkouts of `koch fetch-deps`.

- The names check gave 105 renames to plan. The semantic pass read 43 of the files in 155 s.
- The planner planned 87 and refused 18. Among them, the declaring file of 9 compiles on no
  backend, and the new name of 4 already stands. Another 4 would cross 100 characters.
- The names scanner reads a name in the value of a tuple binding as a use, and never as a
  declaration. Verified by `suites/test_names.nim`.
- The renames wrote 39 Nim files. The parser of the compiler read each to the same tree as
  before, once the renames map back.
- `nim check` read each with the same result before and after. It passed 35 on the C backend and
  2 on the JavaScript backend, and 2 failed both times.
- A second run gave 17 renames to plan, planned none, and so wrote nothing.

**A name in the case of another kind (V.1, V.11) is renamed to the case of its own kind at every
use.** `names.nim` reads each declaration whose case the names check reports. It spells the name
word by word in the case of its kind, and the planner of the V.6 rename plans it from the pass. A
name that also coins an abbreviation takes one rename, which settles both rules.

- A rename reports the rule of the check: `name-case`, or `member-case` for a member. A name that
  also coins an abbreviation reports `name-case` alone, for the one rename.
- Camel and Pascal keep the later letters of each word, so `parse_JSON` becomes `parseJSON`. A
  name of capitals alone lowers them, so `DO_THING` becomes `doThing`.
- A binding of an entry block that moves takes the case of a local, since it is one in `main`.
- A local binding asks its declaring file alone, because no other module can name it. A file
  elsewhere that does not compile then refuses nothing, and the pass asks fewer sites.
- A new name that Nim reads as the old one, such as `local_value` for `localValue`, skips the
  presence and shadow tests. It changes no reading, so nothing new can collide.

**The case rename is refused before the pass where its meaning would leave the text.** Each
refusal prints with its reason, and the finding stays for the hand.

- A name that foreign code reads by its spelling is refused. A pragma such as `importc` or
  `exportc` on its line or on its type marks it. So do a `{.push.}` over it and a type of
  `JsRoot`. `nim check` never compiles the C or the JavaScript that such a rename would break.
  Inferred from what `nim check` runs: the front end of the compiler, and no C or JavaScript
  toolchain.
- A parameter of a foreign routine is renamed, because a foreign call passes it by place.
- A member without its own string is refused, because `$` reads its name, and output often
  shows it.
- A name that its line declares twice is refused, and so is a new name that reads as a new
  acronym.
- Rejected: a rename of a placeholder (V.12). Its letter is the initial of what it ranges over,
  which is a choice.
- Cost: a renamed field or type changes what `$`, `%` and `fieldPairs` print of it. Reading holds
  that. Inferred from how those routines read the names of fields, and never measured.
- Verified by `suites/test_names.nim`, `suites/test_rewrites.nim` and `suites/test_command.nim`.

**The case rename and the entry move have their proof on commit `c5c65db` of `main`.** The tree
at `de0c1899` holds no finding of either, by `nim r koch check-files`. Verified by hand,
2026-10-04, with a scratch program over `renamesOf`, `planRename`, `resolve` and `fixBlockEntry`.
It applied these fixers alone to a copy of that tree, with the checkouts of `koch fetch-deps` and
the engine of `dance_ontology`. The program stays outside the tree, so its figures stand in the
pull request, and the record keeps what they show.

- The parser of the compiler read each written file to the same tree as before. That holds once
  the renames map back and each moved body returns under its block.
- `nim check` gave each written file the same result before and after, on its own pin.
- Each refusal named one reason that this section gives, and each entry block moved.
- A second run refused each rename for the reason of the first, moved no block, and wrote nothing.
- Cost, measured in that run: the semantic pass spent most of an hour. A site of the shared suite
  of `rga_visualiser` took about 1.5 s, because `dus` answers it with every use.

## Sibling markers

**A sibling can reach a private symbol through `{.all.}`. Where its own module never uses it, the
symbol carries `{.used.}` and a comment that names the sibling (Article I.6, STYLE.md §2 and
§5).** An `{.all.}` that reaches no private symbol goes. The Architect ruled D1 a on rule 7 of
issue #443 on 2026-11-18. The ruling gives three answers, and `markers.nim` holds each:

- Q1 no. A suite that reaches an internal needs no marker, since a test reaches internals by
  design. So a sibling is a module of the package outside its `tests`.
- Q2 yes. The marker stands only where its own module never uses the symbol. The library marks
  its symbols so, and the compiler confirms it. Each of the five marks of `pga/algebra.nim`
  silences a real hint that the symbol is not used.
- Q3 no. Knoller reads no `{.all.}` import of a module outside the package. Its markers belong to
  its own package, as the page of #443 proposes.

**The semantic pass lists each use of each private symbol, through the command `use` of
`nimsuggest`.** A private symbol is a name that a module declares at top level, outside the entry
block, with no `*`. It is a routine, an operator among them, a type or a single binding
(`privatesTop`). Each block above it opens no scope, as a `when` chain or a section keyword does.

- The caller asks each module in the entry of each file that opens it with `{.all.}`. So the
  uses of that file and of the module stand in one answer.
- A use maps to the file of the package that its path ends with, below the folder that the root
  names. So a backslash or a short ancestor, as Windows writes a root, changes no use. Verified by
  `suites/test_markers.nim`, with the root as the answers name it, a short ancestor, a root of
  Windows and a separator at the end.
- The site of a name is its last byte, and the site of an operator is the first byte past its
  backtick. The implicit `result` of a routine answers at columns 0 to 5, so a site at column 5
  of `func toBasis` answers `result`. Verified by hand with the `nimsuggest` of 2.4.0, 2026-11-20.
- An answer holds the lines of each symbol at the site. A borrow adds the lines of the routine
  that it borrows, and its own line among them. So a line counts where its name and its type are
  those of the definition at the site.
- A use inside the name itself counts as none, since the template `[]` of `pga/algebra.nim`
  answers its own name as a use.
- An implicit call counts, as `for d in x` calls `items` and `x[i]` calls `[]`. Verified by hand
  on the library, where `items` of `pga/algebra.nim` answers a use at `pga/cayleys.nim:372`.
- `from M {.all.} import a, b` names its reach in its text, so it reaches where it names a private
  symbol of `M`.
- A comment names a sibling where it holds the file name of each sibling that reaches the symbol,
  in any spelling, as `# Used in cayleys.nim.` does. The comment rule decides the backticks.
- A file whose answer holds a reason resolves nothing, and prints one warning. Verified by
  `suites/test_command.nim`, for the warning.

**Own use also reads from the hints of the compiler, as Q2 reads it.** The caller checks each module
that a file opens with `{.all.}`, with the hint `XDeclaredButNotUsed` on. Where the compiler gives
no hint on an unmarked symbol, its module uses it. A marked symbol takes no hint, so its own use
reads from the semantic pass alone.

- The case is `BANDS` of `design/rig.nim:77` of `dance_ontology`. `design/floors.nim` reaches it,
  and `rig.nim` uses it only inside the braces of `&"…"`, which strformat parses from the text. So
  the pass lists no use there, as `## Semantic pass` finds for a rename. The compiler counts the
  use, and gives no hint, so the ruling counts no report in `dance_ontology`.
- Rejected: the hints alone. A marker silences the hint, so a marked symbol would read as used by
  nothing.
- Cost: a module that checks clean on no backend gives no hints. Its uses read from the pass alone.
- Cost: the pass reads no line that declares several bindings, and a forward declaration answers
  its routine as a use. A use inside a template body of the module counts as a use of the module.
  The compiler can count it only where the template expands. Each gives fewer reports, and never a
  false one.
- Verified by `suites/test_markers.nim`, through answers by hand and through the real `nimsuggest`,
  and by `suites/test_command.nim`, through the case of `BANDS`.

**An `{.all.}` that reaches nothing, as the pass finds, must also check clean without it.** The
caller checks the file without it, where the file checks clean with it, through `nim check` on
stdin (`checked` of `symbols.nim`). Else the import reaches what the pass cannot read, as a symbol
that a template declares, and it stays. A file that checks clean on no backend confirms nothing,
and the reading of the pass stands.

- Verified by `suites/test_command.nim`, through an `{.all.}` that reaches a symbol that a
  template declares.

**The fix puts `used` among the bare pragmas of a block in dictionary order (X.10), or opens
`{.used.}` where the declaration holds no block.** The pragma opens after the name and its
placeholders, and for a routine after its parameters and return type. The comment
``# Used in `x.nim`.`` trails the line that holds the pragma, and names each sibling.

- A doc cannot share its line with a plain comment. So a trailing doc moves to the next line, one
  level in, as the ruling accepts. That edit inserts a line before the chain runs, so the caller
  traces each line back through the edits (`originApplied`) and then the chain (`chain`).
- These cases keep the marker for hand:
  - a line that holds a plain comment;
  - a marker whose comment names no sibling;
  - a line that the marker would widen past `LINE_MAX`;
  - a fenced line (X.1), and a span that another fixer writes.
- The fix drops `{.all.}` with the space before it.
- Verified by `suites/test_markers.nim`, for each shape of declaration and each case for hand.

## Pure routines

**A `proc` whose body shows no effect becomes a `func` where the compiler checks it as one (STYLE.md
§1, Article IV.3).** The Architect ruled D1 a of rule 11 of #443 on 2026-11-18. Syntax picks each
candidate, since it cannot prove a routine pure, and the compiler checks it (`purity.nim`).

- A candidate is a `proc` with a body, of no foreign pragma, that takes no routine. It stands
  outside code that `quote` or `genAst` emits, a template substitutes, or `compiles` tests.
- Its body names no effect of `EFFECTS`. Those are output, input, files, the clock, random numbers,
  the environment, a process and an address, and a lock, a wait and a signal.
- The rule reads the default of each parameter as part of the body (D6 a of #980). A default runs
  at each call that leaves its argument out, so its effect is an effect of the call. So
  `initToolchains` of knoller, whose default reads the environment, stays a `proc`.
- STYLE.md §1 counts a lock, a wait and a signal as effects, since another thread sees each one.
  The compiler checks each routine of the store of `simulation/walk.nim` of `dance_ontology` as a
  `func`. But the answer of `claimed` depends on the order of the threads. So it is no
  deterministic transformation of its arguments, as the ruling says.
- Its body reads no global `var` of the project. It calls no routine that the project declares
  nowhere and `TRANSFORMS` does not hold, so a call that syntax cannot read never counts as pure.
- A call is a name glued before `(` or `[…](`, a name glued after `.`, or a name that opens a
  statement before an operand.
- It calls no `proc` or `method` of the project that stays, read to a fixed point.
- A proc inside `compiles` stays, since no clean check of its module proves what `compiles`
  answers. The case is `leaving` and `staying` of `tests/suites/test_timings.nim:39` of
  `pga_visualiser`.
- Rejected: the compiler alone, which checks a routine that takes a lock as a `func`.
- Cost: an effect is read from names, so a name of `EFFECTS` that means another thing keeps its
  routine a `proc`. That cost removes reports, and adds none.
- Cost: the compiler accepts a write that a routine of a library makes through a `ref` inside a
  field or a container of a parameter. `[]=` of `std/json` is such a routine.
- Verified by `suites/test_purity.nim`, with a case for each cost that adds a false report.

**The compiler checks the source with each candidate written `func`, read from stdin in the
directory of the file (`checked` of `symbols.nim`).** So its imports and its `nim.cfg` resolve as
for the file itself, and nothing is written in the tree. The error of a refused candidate stands
at its head, as `'reset' can have side effects` does where `reset` writes through a `ref`.

- A configuration whose source as given does not check clean proves nothing. A file that no
  configuration proves keeps each `proc`, with its reason, and prints one warning.
- Where C refuses the source as given, the check asks the JavaScript backend, as the semantic pass
  does. So `design/rig_view.nim` of `dance_ontology`, which imports `std/jsffi`, proves its
  routines.
- The compiler checks all candidates of a file at once. An error inside a routine refuses it, and
  an error outside every candidate asks each candidate alone. A candidate stays where any
  configuration refuses it.
- An included file checks inside the text of the file that includes it (`enclosing`).
- Rejected: `chkFile` of `nimsuggest` with a dirty file. Under `-d:pga.dimensions=3`, it reports a
  false `constant expression expected` in `pga/algebra.nim`, by hand with 2.4.0, 2026-11-20.
- Cost: a file takes one check for the source as given, and one for each round of its candidates.
  One check of `pga/algebra.nim` adds 0.61 to 0.76 s, where no check runs without the rule. Six
  runs of the command of `checked`, with its flags, on stdin and a fresh cache, gave that range.
  They ran with 2.4.0 on 4 cores at 2.10 GHz, 2026-11-20, under two different loads.
- Cost: a generic body checks where its own module instantiates it. So an instantiation in another
  module that the compiler would refuse is unread. A case holds it through a second module, whose
  `$` calls `echo`.
- Verified by `suites/test_purity.nim`, and by `suites/test_command.nim` for the warning.

**A routine that takes a parameter of a `ref` or `ptr` type stays a `proc` (D1 a of #980,
2026-11-20).** The Architect ruled so in the comment of that date. Another holder of the object,
or another thread, can change it during the call. So the routine is no deterministic
transformation of its arguments, whether it writes or only reads.

- The compiler answers whether each parameter type points: a `ref`, a `ptr` or a `pointer`, and a
  `distinct` one of each. The check of each type stands after the source, so no line moves, and its
  error refuses its routine (`probed`).
- A type that names a generic parameter of its routine takes no check. No scope at the end of the
  module names it, so its check could never answer.
- A parameter that its default alone types reads as `typeof` of the default.
- A `var` parameter of a value type keeps no routine a `proc`, as the Architect ruled, since
  STYLE.md §1 lets a `func` write it. A `var` of a `ref` type points all the same.
- Rejected: a `var` or a large object, which Nim passes by address, since a thread changes it
  only where its caller shares memory.
- Rejected: a `ref` only in a project that starts threads, since one file cannot show which threads
  share a `ref`.
- Rejected: strict funcs for the whole build. They also count the `[]` read of `std/json` as an
  effect, as in `medianTouched` of `pga_benchmark` (by hand with 2.4.0, 2026-11-20).
- Cost: a `ref` inside a field or a container of a parameter stays unread. So do a type that names
  a generic parameter, and a type that no scope at the end of the module names. A `cstring` reads
  as a string, so it stays unread too. Each can add a false report.
- Verified by `suites/test_purity.nim`, with a case for each kind of type that points, and one for
  each cost. A case cut from `MultivectorOf[B]` of `pga_benchmark` holds a type that names a
  generic parameter.
- Cost: `nim check` of 2.4.0 crashes with no line on some checks of a generic type. Its parameter
  is a `static set` that a field reads, and the argument names nothing at the end of the module.
  Then the file proves nothing. A file with a candidate warns, with the crash as its reason, and a
  file with none stays silent. Verified by hand with 2.4.0 on `Of[Zork]`, 2026-11-21.

**A `func` that takes a parameter of a `ref` or `ptr` type reports, and the fix writes `proc` (D5 a
of #980).** The Architect ruled so on 2026-11-21, so the rule holds the ruling of 2026-11-20 in
both directions. The check of the source as given asks the compiler about each such `func`, as
`probed` asks about each candidate.

- The check asks the compiler about each `func` whose shape admits a candidate (`is_candidate`).
  One of the types of that `func` must also name more than builtin types, numbers and the words of
  `WORDS_PLAIN` (`isPointingAsked`). Those words are the containers of value and the modifiers.
- The error of each check of a `func` leaves the check of the source clean, since the caller reads
  it (`checkedBackend`). So a file that holds a candidate takes no new compile. A crash of the
  compiler names no line, so it leaves that check unclean (the cost above).
- The fix writes `proc` for `func`, which has the same width. A `func` whose forward declaration
  stands keeps it for hand, since the kinds of the pair must match.
- Cost: a file that holds such a `func` and no candidate takes one check of the source as given,
  where none ran before. Its time is unmeasured, and #1001 holds the work to make it faster.
- Cost: where that check is clean in no configuration, its `func` stays unread. The file warns
  nothing, since no `proc` stays there. Six files of the projects stand so, as the count below
  gives.
- Cost: the shape leaves out a `func` that takes a routine, and one with a foreign pragma or no
  body. It also leaves out one inside a template or in code that a macro emits. A `ref` parameter
  of such a `func` adds no report.
- Verified by `suites/test_purity.nim`, by `suites/test_command.nim` for a file with no candidate,
  and by `suites/test_fixes.nim` of `curator/audit` for `koch fix`.

**The fix writes `func` for `proc`, which has the same width.** So no line moves and no line
widens. A fenced line keeps its `proc`, and so does a span that another fixer writes. The check
and the fix read the same sites, which the caller passes (`Pures`).

## Caller of both rules

**The caller passes the facts of both rules, as the type conversion takes its answer.** A rule
reads one file, as each rule of knoller does. So the caller asks the semantic pass and the compiler
across the project. It passes `Uses` and `Pures` to the check and the fix of each file. The edits
apply before the chain, on the source as given, beside those of the conversion, the renames and
the landmark aliases.

- The command line asks for each module that a file names (`resolveMarkers`, `resolvePures`). It
  reads every Nim file that git lists in the project of the file.
- The command line names no define for either pass, as D2 a of #886 rules. So each file compiles
  as its project alone compiles it. The pure rule reads each configuration that its caller names
  (`provenPure`). `resolvePures` names one, with no define, and `koch fix` reads through it. So
  neither caller reads a branch that only a stub define takes. The marker rule reads the answers
  that the caller passes, and its checks of hints and of `{.all.}` use no define.
- `koch fix` passes both facts, through `readFacts` of `curator/audit`, which calls these readers
  (`## Facts of the compiler` of its record). Neither rule reaches the static pass of `koch check`,
  which waits for step 4 of #443.
- Verified by `suites/test_command.nim`, on a fresh repository through the real compiler, and by
  `suites/test_purity.nim` for the configurations.

**Each reader runs its compiler calls on a pool of threads, one for each core (`pools.nim`).** A
call of `nim check` or of `nimsuggest` takes about a second, and its caller waits for the answer.
At `b585ea65`, before the pool, the 59 calls of rules 7 and 11 in `koch fix --dry-run
curator/knoller` run one after another. They take 61 s of 111 s, while three of the four cores
wait (the profile on #1001).

- `resolvePures` gives each file to a thread of the pool. `resolveMarkers` gives a thread each
  importer for `nimsuggest`, each module for its hints, and each importer for the checks of its
  `{.all.}`. The confirmations read the answers of both steps before them, so they run last. The
  hints read none of the answers of `nimsuggest`, and run after them all the same.
- A thread runs a whole job, so the checks of one file run in turn, as `provenPure` asks them. The
  answers keep the order of their jobs, so each table takes them as one loop gives them.
- No job and no answer holds a `ref`, since ORC counts references without atomics, and two threads
  must never count one object. A thread reads its job in place, and its answer moves into the
  sequence of the caller.
- `checked` gives the compiler its text through a file, and takes its output through a file, by
  the redirection of the shell. Its process opens no pipe. A child that another thread starts
  meanwhile inherits each pipe open then. So its copy of the write end of a pipe of text would stop
  the compiler before the end of the text, for ever.
- The shell moves into the directory of each run (`lineRedirected`). On POSIX, `startProcess` given
  `workingDir` moves the directory of the whole process around the spawn, so two threads would move
  it under each other.
- An importer whose every `{.all.}` reaches a symbol checks nothing, since that check would confirm
  nothing.
- Verified by `suites/test_pools.nim`, for the order of the answers, the jobs side by side and the
  exceptions. Verified by `suites/test_symbols.nim`, which runs more checks than threads at once
  through the real compiler. In one case, each check takes a directory of its own. The importer
  that checks nothing and the order of the steps hold by the runs below alone.
- Rejected: a pool of compiler processes, which turns the loop of each prover into a state machine
  across files.
- Rejected: `malebolgia` or `taskpools`, the first dependency of knoller for one routine.
- Cost: a job after the first that raised still runs. The caller raises that first one again as
  `CatchableError`, with its message, whatever the count of threads.
- Cost: the hints could run beside `nimsuggest`, and wait for it.

**Verified by run of `koch fix --dry-run curator/knoller` over the tree at `b585ea65`,
2026-11-21.** Koch built at `b585ea65` and at `41c24818` prints the same 2,454 lines in each of
three runs, and the runs alternate between the two builds. The median falls from 116.9 s to
67.4 s. Each build is the debug build that `nim c` makes, on 4 cores at 2.10 GHz. The load average
of one minute, read from `/proc/loadavg` after each run, is 1.05 to 1.36.

- Over the same tree, each other project that `koch list-projects --all` lists ran once with each
  build, under a branch of its own. Each prints the same text with both builds. With the first run
  of each build on knoller, the sum of their times falls from 1,347.7 s to 776.7 s.
- The tree holds no checkout of a lock. So each file that imports a package of a lock stays
  unresolved with each build, and warns.

**Verified by run, 2026-11-20, on the PGA library at `3d9696e`, with a nimble file at its root.**
`knoller --check pga.nim pga tests`, built at `bca6a142`, reports `func-pure` at
`pga/algebra.nim:172`. It reports `marker-used` at `pga/operators.nim:10` and `tests/suites.nim:11`.
The counts below come from a driver outside the tree. It calls the resolvers of the command line,
then the fix of one rule alone, on a copy of the library.

- Sibling markers: 2 reports, and the fix writes +2 −2 lines. Each drops an `{.all.}` that reaches
  no private symbol, as the ruling counts.
- Pure routines: 1 report from the driver at `bca6a142`, `generateUpTo`, and the fix writes +1 −1
  lines, as the ruling counts. That build reads no `func` that takes a `ref` or `ptr` parameter.
- `knoller --check .`, built at `d0d4e976`, also reports `func-pure` at lines 9 and 28 of
  `pga/emitters.nim`, 2026-11-21. There `emitFunc` and `emitTypeDef` are each a `func` that takes
  a `NimNode`, so the fix writes `proc` (D5 a of #980). The copy that this build fixes, every rule
  at once, builds with Nim 2.4.0 in each configuration of `tests/`. Each of rga2d to rga6d gives 33
  OK, 0 failed and 5 skipped. Each of cga3d to cga6d gives 28 OK, 0 failed and 10 skipped.
- Each rule finds nothing more on its fixed copy.
- Each fixed copy builds with Nim 2.4.0 and passes its suites. rga3d gives 33 OK, 0 failed and 5
  skipped, and cga3d gives 28 OK, 0 failed and 10 skipped. For pure routines, rga5d gives 33 OK, 0
  failed and 5 skipped, and the loop of `generateUpTo` runs there.
- Cost: `knoller --check pga.nim pga tests` takes 1.6 s at `7fea1e2d`, without both rules, and
  17.8 s at `e6c931b1`, with them. It ran on 4 cores at 2.10 GHz, under a load near 2 from other
  work. Each figure is the median of three runs, each with an empty cache of Nim, 2026-11-20. The
  output differs by the 3 reports alone.
- Cost: at `b585ea65`, the same command takes 68.4 s, and built at `207bb857`, with the pool,
  54.3 s. Both builds print the same 266 lines in each of three runs, which alternate between the
  builds. Each figure is the median of those runs of debug builds, 2026-11-21, under a load of 1.00
  to 1.95 while a subagent ran beside them.

**Verified by run over the projects of the repository at `16a573cc`.** A driver with the code of
knoller at `bca6a142` read each project as one package, by `git ls-files` (2026-11-20). It read
them with the checkouts of each lock and the engine of `dance_ontology`. Then
`koch fix --dry-run --branch:main` read the five projects that hold a routine of this rule, over
the same tree.

- Sibling markers: 1 report from the driver, the `{.all.}` of `tests/suites/test_marker.nim:9` of
  `pga_visualiser`, as the ruling counts.
- Pure routines: 150 reports, by koch built at `0ca2555c` (2026-11-21). Of them, 49 make a `proc` a
  `func`: 33 in `pga_visualiser`, 13 in `dance_ontology` and 3 in `rictadni`. The ruling counts 22,
  as 16 and 6. The page names a short list of pure routines of the standard library, and does not
  give it. So `TRANSFORMS` is the list of this rule. The cause of the difference is unmeasured
  (`## Open questions`).
- The other 101 are of a `func` that points: 65 in `pga_benchmark`, 24 in `dance_ontology`, 11 in
  `rictadni` and 1 in `pga_visualiser`.
- The ruling of 2026-11-20 keeps `mergeAllocations` of `pga_benchmark` a `proc`. Koch built at
  `a4ece9d7` and at `2f049cfe` differs by that report alone, 4,901 changes against 4,900. D6 a
  keeps `initToolchains` of knoller a `proc`, as koch built at `fd3bc4b5` and at `4c35d439` shows.
- Six of the 101 stand since a type that names a generic parameter takes no check. They are the
  `func`s of `tests/suites.nim` of `pga_benchmark` that take a `JsonNode`. Koch built at `4c35d439`
  gives 144 over the same tree, since the crash of the compiler there hid them.
- The count is a floor. Eight files check clean in no configuration, so the rule reads none of
  their routines. Two hold a candidate and warn: `src/desktop/main.nim` of `pga_visualiser`, since
  the run had no `dependencies/imgui`, and `proposals/04-basis-set-forms/laws.nim` of
  `pga_benchmark`. Six hold only a `func` that the rule asks about, and stay silent. They are four
  other `laws.nim` of proposals of `pga_benchmark`, `src/desktop/panel.nim` of `pga_visualiser` and
  `simulation/engine.nim` of `dance_ontology`.
- Cost: the time of each pass over the projects at `16a573cc` is unmeasured as a pair.

## Tests

**A test that also reads a check of `curator/audit` stays in the suites of audit.** Such a test
holds that a fixer of knoller clears what a check of audit reports, so it needs both projects. A
test that reads knoller alone sits here. A fixture that both suites read is copied, and each copy
names the other.

**A source that several suites read stands once, in `suites/sources.nim`.** That module holds
the declarations of every kind, the operators and the entry blocks, as `suites/stubs.nim` holds
the stub parser. So no suite of knoller holds a copy of another.

**Each case that the review of the PGA library or a delegate report found stands as a regression
test, end to end (`suites/test_regressions.nim`).** The Architect asked for this on 2026-10-05.
Each case quotes the source as found and names where it came from. It runs through `formatted`,
as `koch fix` runs it, and holds the exact output and a second run that writes nothing.

- The cases come from the PGA library at `d9be8ae` and `3d9696e`, from `dance_ontology` (#539),
  and from `rga_visualiser` (#521). Others come from the rulings of #533, #526 and #443.
- The cases of rules 2 to 6 of #443 quote the library at `3d9696e`. Verified by hand, 2026-11-20,
  with the suite of `060c3a76` against knoller at each commit. Each fails at `4245dca8`, before
  those rules. The cases of rules 2 and 6 alone fail at `3a6cf5e9`, and that of rule 6 alone at
  `d018a6c0`.
- The cases of rules 8, 9 and 15 of #443 quote the library at `3d9696e`. Rules 9 and 15 read
  the names of a package, so their cases run through `outcome`. Verified by hand with Nim 2.4.0,
  2026-11-20: each fails with knoller at `d6bc8979`, before those rules.
- A case keeps its domain test in the suite of its rule, which holds the rule over many inputs.
  The regression suite holds that the case as found is fixed. Neither one alone holds both.
- Each case asks the parser of the compiler that builds the suite, 2.4.2 in the job of knoller. A
  case with glyph operators asks it too. Commit `27763495` gave the same verdict on each such case,
  verified by hand, 2026-10-05, and 2.4.0 gives it, verified by hand, 2026-10-29. 2.4.2 gives it
  too, verified by the jobs of `check.yml` on the runner at `d4f7e2b1`, 2026-11-26.
- The case of `test_mesh.nim` (#521) leaves no finding under the present rules, because spacing
  now fixes `)*radius`. So it holds that each report on its lines prints at its line as given.
  `suites/test_command.nim` holds a finding left at its line as given.
- The case of the stub `tests/rga3d/test_rga3d.nim` (#443) depends on its path, and on the
  nimble file of the PGA library at its root. So it runs through `outcome`, as the command line
  runs it, with that nimble file, at that path and at `tests/test_rga3d.nim`.
  Verified by hand, 2026-10-08: it fails at the parent of the commit that builds the ruling.
- Verified by hand, 2026-10-05: the suite ran against the parent of the commit that fixed each
  case, with a shim that proves nothing. Each case that a commit fixed failed at its parent. A
  case that holds a bound of its rule, such as `[1 .. ^1]`, passed there.
- Cost: the suite asks the compiler for each case with candidates, about 6 s in all.

## Tokens

**`tokens.nim` keeps the rules of the lexer of the compiler.** A run of operator characters is one
operator. A `-` before a digit opens a number after a space or an opening bracket.

- The glyphs are the largest set that a pinned compiler reads, that of 2.4.0 and 2.4.2. It adds
  `☆ ⟑ ⟇ ⩓ ⩔ ■ □` to the glyphs of 2.2.12, and commit `27763495` reads the same set as 2.4.0.
  Verified by hand, 2026-10-29, in the source of each lexer. `unicodeOprLen` of the lexer is the
  same bytes in 2.4.2, verified by hand, 2026-11-26.
- Cost: where code on a pin that reads fewer glyphs spells one of them in a name, the scan reads
  it otherwise than that compiler. No code on 2.2.12 did, verified by hand, 2026-10-29.
- Verified by `suites/test_tokens.nim`. Verified by hand over the tree, 2026-10-02: each byte of
  each Nim file outside whitespace lies in one token, and each bracket finds its partner.

**A name of code is each run of name characters, read once (`wordsCode`).** The names check, the
fixed waits and the words among pragmas read names so. So the tail of an indented name never reads
as a name of its own.

- Rejected: a reader that skips the spaces before a name, but steps by the name alone. It reads
  the tail of each later name again, as `t` of `{.compileTime, noinit.}`.
- Verified by `suites/test_views.nim` and `suites/test_waits.nim`.

**A string literal is interpolated where `&` or `fmt` stands glued before it (`isInterpolated`).**
An `&` glued after an operand joins instead, as Nim reads `a&"…"`, so the literal after it stays
plain. The message rule and the rename planner read literals so.

- Verified by `suites/test_messages.nim` and `suites/test_rewrites.nim`.

## Form

**Each check of form reads text alone, so it serves every kind (`checkForm`).** A line holds no
CR, no tab and no trailing whitespace, and at most 100 runes where a break can fix it. A file ends
in exactly one newline, so an empty file breaks that rule too. The static pass of `curator/audit`
runs these checks on every kind it reads, and the command line on each Nim file.

- Each finding names its rule: `trailing-whitespace`, `line-ending`, `tab`, `line-width` or
  `file-ending`. A fixer reaches trailing whitespace, the file ending, and a tab in a plain string.
- Verified by `suites/test_form.nim`.

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

**Each layout rule that has one right answer has a check and a fixer, from one reading.** The checks
and fixers of separators, signatures and calls share the reading of `wrapping.nim`. Spaces read
`spacing.nim`, and `## Spaces` gives them. Blank lines read `blanks.nim`, and docs and defaults
`declarations.nim`, where `## Docs` and `## Block docs` give the docs. A construct that the
scanner cannot read with certainty stays as written, and its check stays silent.

**Parameters take commas while each type appears once, and semicolons where a group shares a
type (STYLE.md §5).** The rule holds on one line and across several, the separator after the last
group included, in a routine, a routine type and a lambda. The separator after a typed group never
changes what the compiler reads. A group without a type or a default stays, because a semicolon
after it ends the group.

**A tuple type takes commas between its fields (STYLE.md §5).** `tuple[a, b: int, c: X]` and its
form with `;` parse to one tree, so the rewrite moves no reading. A comment after a field stays.
A `;` in parentheses is a list of statements, and stays.

**Each signature has one layout, unless the hand marks its split (X.3).** A signature that fits
stands on one line, and a wrapped one that would fit is joined. Otherwise its parameters take one
line of their own, where that line fits. Otherwise one parameter, or one group of a shared type,
takes each line, with a separator after each group but the last. Each layout indents one level,
and the closing line opens with `)`.

- A separator after the last group, on a line before `)`, marks the split that the hand wants
  (`isMarked`). Such a signature keeps one group to a line, even where it fits, as a call with
  that mark does. Verified by `suites/test_wrapping.nim`: both `defineOperator` macros of
  `operators.nim` of the PGA library stay as written.
- A signature that holds a comment, or a group that spans lines, stays. So does one that fits
  where the body after `=` on its line does not, because a moved body and a wrap are two answers.

**A call that fits stays on its line, and one that does not keeps the line breaks of the hand
while each line fits (X.3).** A wrapped call that would fit is joined. Otherwise the line breaks
that the hand gave it stay, its arguments on one line of their own among them (`linesHand`). Only
where a line would cross `LINE_MAX` does it take one argument to a line, with a comma after each
argument but the last.
The outermost call that crosses `LINE_MAX` splits first, and each line it leaves is read again.
An argument splits its own call only where that call is the whole argument.

- An argument that the hand wrapped, and that fits no line, keeps its line breaks and moves with
  its new indent.
- A call that spans lines, with a comma after its last argument on a line before its `)`, is
  never joined (`isTrailed`). That comma marks the split that the hand wants. So such a call
  keeps one argument to a line, even where it fits. A split that knoller makes ends with no such
  comma, so it joins again once the call fits, as after a rename that shortens it. Verified by
  `suites/test_wrapping.nim`: the `newEnum` call of `algebra.nim` of the PGA library stays, and
  a split call joins once a rename lets it fit.
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

**No fixer adds a separator after the last item of a list (X.3).** That separator is the one
mark of a split that the hand wants. A fixer that added it would make each of its splits
permanent, since the mark keeps a call or a signature split where it fits. So no list gains one: a
call, parameters, an array, a seq, a set, a table, a tuple, a constructor or an import bracket. A
separator that the hand wrote stays. The Architect ruled so on D2 of
[the rules walk (#980)](https://github.com/mraxilus/delegations/pull/980#issuecomment-7062317070).

- Each compiler accepts the separator in each of these lists, where a tuple holds several items,
  and `;` after the last parameter group. Verified by hand with 2.2.12, 2026-10-02, and with
  2.4.0, 2026-10-29.
- A list that no call or signature opens, such as an array, keeps its rows with or without the
  separator, since no fixer joins it.
- Verified by `suites/test_wrapping.nim`, `suites/test_chain.nim` and `suites/test_regressions.nim`:
  a call one argument to a line, too wide to join, keeps its lines and gains no separator. The
  cases of `suites/test_chain.nim` take the shapes of lines 331, 410 and 693 of `pga/cayleys.nim`
  of the PGA library at `3d9696e`.
- Cost: the mark reads alike whether the hand wants the split or wrote the separator by habit.
  The tree holds many such separators on calls and signatures too wide to join, and each keeps
  its list split. Their drop waits on the fixes of each project under #443 (D2 of #980), since no
  fixer removes a separator.

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
`tests/` of their package alone.

- A test file lies below `tests` of its package, at any depth (`## Layout of a package`).
  `reports.nim` holds this reading and the reading of a stub, from the names below that
  directory. So the blank-line rule and the stub rules read one definition.
- Verified by `suites/test_blanks.nim`, which holds both readings to a table of paths.

**Knoller reads a stub as testament reads a category (#443).** A testament category is a folder
directly under `tests` of a package. Its tests are the files `t*.nim` at any depth inside it, as
`isTestFile` and `processCategory` of `testament/categories.nim` read them. Such a file is a stub
where a testament header opens it, that is, where the file opens with `discard """`. A file there
that opens with no header is a suite module, and no rule of a stub reads it. A file
`tests/test_*.nim` is a stub with or without a header, so a missing header there stays a
`stub-header` finding.

- `isStub` takes the source beside the path, since the header decides. Each caller holds the
  source already: `keysStub`, `checkTests` and `profiler` of `idioms.nim`.
- Rejected: the path alone, which reads each suite module of a category as a stub. Each one, such
  as `tests/suites/test_names.nim` here, would then take `stub-header` and `profiler-import`.
- Rejected: the header test at each of those callers, which writes the rule of a category three
  times.
- Cost: knoller reads the header of a file in a category at its first byte alone. Testament reads
  a header anywhere in the first ten lines, where no space stands before it. So a file of a
  category whose header stands lower is no stub here. The stub of STYLE.md §6 opens with its
  header.
- Verified by `suites/test_blanks.nim`, which holds `isStub` to a table of paths, each with a
  header and without. Verified by `suites/test_idioms.nim`: a stub one and two levels down in a
  category takes `stub-keys`, and a suite module takes neither. Each such stub includes its
  suite, so it takes the profiler import from that suite (STYLE.md §3).
- Verified by `suites/test_regressions.nim`: the stub `tests/rga3d/test_rga3d.nim` of the PGA
  library takes `stub-keys` and no `profiler-import`, as the same text at `tests/test_rga3d.nim`
  does.
- Verified by hand with `git ls-files`, 2026-10-08: no file of a category in this repository opens
  with a header. So the rule adds no finding here.

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

## Definition blank lines

**The run of blank lines before a definition takes the count that X.2 gives it (#443, rule
13).** The Architect ruled it so in chat on 2026-11-18, with the answers Q1 to Q3.
`checkDefinitions` and `fixDefinitions` of `blanks.nim` share one reading (`gapsDefinition`). The
rule reads each run between two items at module level. It also reads each run between two items
of each branch of a `when` there, since `when` opens no scope. The rule reads no run before the
first item of a level.

- An item is a code line at the indent of its level, with the lines that it holds. These are its
  brackets, its deeper lines, its doc, and each `elif`, `else`, `of`, `except` or `finally` branch.
- A routine, a declaration block (`type`, `const`, `let`, `var`) and a declarative call are
  definitions. A declarative call calls a template or a macro that the module declares, or a
  routine `define…`. A `when` counts as the definition that it holds first, and below it as the
  one that it holds last.
- An item is one line where its head line holds all its code. A routine with no body, as a
  borrow, is one line too, since only width wraps its signature.
- An item with a `##` doc on its head line or inside it is documented. A `##` inside a `#` comment
  is no doc. A doc right above an item stands with it, but does not make it documented.
- A `#` comment or a `##` doc at the indent of the definition, right above it, stands with it. So
  the run above them is the run that the rule reads, and the report names the head line.
- The rule reads the run only where the item above is a definition or an import. A pragma line,
  a statement, a banner or a free comment above it opens what follows, so the rule reads no run
  there. A free comment has a blank line under it.

**The definition below the run sets its count, and the item above decides each stack.** The
counts read the bullets of X.2 in this order:

- A declarative call after another stacks in its family, so no line and one line pass. Knoller
  cannot tell two families apart, so a run of two or more becomes one.
- A declarative call after a routine takes up to two, as the call of a template right under it
  (STYLE.md §2). A documented one-line call takes one there, as Q3 gives a documented one-line
  definition (D3 a of #980). A documented call over several lines is no one-line definition, so
  it takes up to two, as a call with no doc does.
- An undocumented one-line routine after another stacks in its group. Up to two lines pass, since
  X.2 gives no count between two groups. The first helper of a group takes two.
- A declaration block after another takes one.
- A documented one-line definition that no bullet above names takes one after any definition
  (Q3).
- Knoller reads Q3 after the imports too, as D3 a of #980 rules, since Q3 says that the definition
  below a run sets its count. Its case is `tools/head.nim:17` of `pga_visualiser`, two lines after
  the imports.
- Every other definition takes two, a routine of several lines among them (Q2). So the check
  reports one line and three lines.
- Inside a second-tier section, each count caps at one, since siblings there take one (X.2). Q1
  makes Wedge, Norms, Unitize and Support second tier. The nearest banner above the definition,
  outside a string, gives the section. Knoller changes the tier of no banner, so the library writes
  `#[[ ]]#` by hand where a section is second tier.
- The fixer sets each run to the nearest count that passes, last run first.
- The rule reads no run between two single bindings of one keyword on adjacent lines, since they
  share one keyword (X.5). `single-bindings` merges them earlier in the chain.
- Runs beside a banner, before a suite or a test, and beside a nested helper stay with
  `banner-spacing`, `test-blank-lines` and `helper-blank-lines`.
- Rejected: two lines after the imports for each definition, since the definition below a run
  sets its count (Q3).
- Rejected: a fence marker as a separator. It is a comment, so it stands with the definition
  below it.
- Cost: the rule reads no definition inside a `when` of a routine body, or of an `if` at module
  level. How often the library and the projects hold one is unmeasured.
- Cost: a declarative call in command form, with a generic bracket, or with a space before `(`,
  reads as a statement.
- The rule joins `checkFormatting` and the chain. The static pass of `curator/audit` does not
  read it until the projects fix their runs (step 4 of #443).
- Verified by `suites/test_definitions.nim`. It holds one case of each shape that rule 13 of #443
  names, and the documented one-line call that D3 a of #980 names. A law runs over each pair of
  forms, each count from 0 to 3 and each tier. The imports stand above alone there, since the rule
  reads no run before them.
- Verified by `suites/test_chain.nim` and `suites/test_command.nim`, which pin the output of the
  chain and the command line.
- Verified by measurement at commit `14bab954`, 2026-11-20, with a driver that calls
  `checkDefinitions` and `fixDefinitions` alone on each file of the PGA library at `3d9696e`. The
  hand change of Q1 stands at `operators.nim` lines 298, 319, 365 and 393. With it, the check
  gives 23 reports, and the fix adds 16 blank lines and removes 9.
  Without it, the check gives 33 reports, and the fix adds 28 blank lines and removes 9, by `diff`.
  One line that it removes holds spaces alone. A second check of each fixed copy gives 0 reports.
- Verified by the suites of the fixed copy with the hand change, under Nim 2.4.0 on 2026-11-20.
  `rga3d` gives 33 OK, 0 FAILED and 5 SKIPPED. `cga3d` gives 28 OK, 0 FAILED and 10 SKIPPED.
- Verified by measurement over the projects of the repository at `16a573cc`, 2026-11-21. A driver
  calls `checkDefinitions` alone on the `.nim`, `.nims` and `.nimble` files that git tracks in
  each project. Knoller at `fd3bc4b5` and knoller at `1bed07fd` give the same reports at each
  project. Knoller gives 39, audit 42, assayer 5, probe 5 and `pga_benchmark` 316.
  `pga_visualiser` gives 193, `dance_ontology` 531, `rictadni` 24 and `ricysoho` 117, which is
  1,272. A search of each file that git tracks finds no documented one-line call at module level
  there, so the ruling changes no report.
- Verified by `koch fix --dry-run --branch:main` over each project of the same tree, with koch
  built at `fd3bc4b5` and at `1bed07fd`, 2026-11-21. Each gives 1,007 fixes of this rule, and the
  two outputs are the same, byte for byte. The count differs from that of the driver, since the
  chain runs every fixer, and leaves each file that does not settle as written.

## Configuration blocks

**Definitions of one configuration that stand next to each other share one block, and the
configuration that a build gets by default comes first (X.11).** The Architect ruled so on rule
14 of #443, as option b. Knoller never moves a definition out of its family
(`checkConfigurations`, `fixConfigurations`).

- Two blocks of one configuration, each with no other branch, join only where blank lines alone
  stand between them. The fix deletes the head of the second block, so its body follows the
  first, with the blank lines between as written. A definition or a comment between keeps the two
  apart, since what stands there can belong to the family of either. Conditions that read alike,
  spaces aside, are one configuration.
- A two-way `when` whose condition is false by default puts its default last, so it reports. The
  fix swaps its branches. The new head names the complement by the constant that names it, as
  `IS_RIGID* = not IS_CONFORMAL`, or else with `not`.
- Two blocks of complementary configurations side by side put the default last where the first
  condition is false by default. So they report too, and the fix swaps the two blocks (D3 a of
  #980). Each block holds no other branch. The default reads as the two-way `when` reads it. The
  second condition is the complement of the first as the fix of a two-way `when` writes it, either
  way, spaces aside. So `IS_RIGID` and `not IS_CONFORMAL` each complement `IS_CONFORMAL`.
- The fix of such a pair moves each block whole, with its head and the comment of its head, so
  neither stays for hand. The blank lines between the blocks stay as written. A definition or a
  comment between them keeps them apart, as it keeps two blocks of one configuration apart.
- The default comes from the define of the package. A module-level constant with a `define` or
  `booldefine` pragma and a literal `true` or `false` gives it, with its type stated or not. So
  does a constant written `not` of such a constant. The audit reads them over each project
  (`readConfigurations`). Knoller reads them over the modules of its run alone, so a run on
  `pga/cayleys.nim` alone gives no report.
- A condition that no define gives names no order, as `defined(js)`, which the target sets.
  `isMainModule` and `compileOption(…)` name no configuration.
- The rule reads each `when` at module level or in a branch of one, in a type section, and among
  the fields of an object. A `when` inside a routine or inside a `block:` value holds no
  definition, so it is unread, and so is a pair there.
- Outside a pair, a head with a trailing comment stays for hand, so the fix writes no comment
  away. So does a body whose indent differs from the block that it joins.
- Verified by `suites/test_configurations.nim`, which quotes `Formal` of `pga/cayleys.nim` and the
  constants of `pga/algebra.nim` of the PGA library at `3d9696e`, and by `suites/test_fixes.nim`
  of `curator/audit`. They hold each bullet above, and the two costs below.
- Verified by hand with knoller at `0b795b5f` on the PGA library at `3d9696e`, 2026-11-20. A
  driver imports `knoller`, reads the defaults of the package, and runs the check and the fix on
  each file that `git ls-files '*.nim' '*.nims' '*.nimble'` lists. It gives 1 report, at line 37
  of `pga/cayleys.nim`, which is `Formal`, the place that the ruling names. The fix swaps its
  branches in 4 lines. The ruling gives `Formal` a hand change in their place: `round` with no
  condition, and `flat` under `when IS_CONFORMAL`.
- Verified by hand with Nim 2.4.0 on the copy that the fix wrote, 2026-11-20. Each suite builds
  and runs by `nim c -r -d:testing -d:nimUnittestAbortOnError:on` and the matrix line of its stub.
  rga3d gives 33 OK, 5 SKIPPED and 0 FAILED, and cga3d gives 28 OK, 10 SKIPPED and 0 FAILED, as
  the library as given does.
- Verified by hand with a driver over the projects of the repository at `16a573cc`, 2026-11-21.
  It reads the defaults of each project, and runs the check on each file that git tracks there.
  Knoller at `fd3bc4b5` and knoller at `1bed07fd` give no report, and so does
  `koch fix --dry-run --branch:main` built at each. Only `HAS_FORMS_DENSE` of `pga_benchmark`
  gives a default, and it guards one import on one line, so the rule reads no two-way branch and
  no pair. The pair of `IS_RIGID` and `IS_CONFORMAL` in `CATALOGUE` of `pga_benchmark` stands
  inside a `block:` value, and its project gives neither a default.
- Verified by hand with that driver on a copy of the PGA library at `3d9696e`, 2026-11-21.
  Knoller at `fd3bc4b5` and knoller at `1bed07fd` each give the 1 report at `Formal`.
- Rejected: a join of every block of one configuration in a section, which takes `■` and `□` of
  `pga/operators.nim` out of their family.
- Cost: knoller reads the lines with a scanner, and never with a parser. A body runs while its
  lines stand deeper than its head, so a line of a string at column 0 ends it. A branch on the
  line of its head, as `when C: a`, and a chain with `elif` are unread.
- Cost: a complement written in another form names no pair, so the order of the pair is unread.
  An example is `not IS_RIGID` beside `not IS_CONFORMAL`.

## Docs

**Each declaration takes a doc where its shape puts it, and `## TODO: Document.` waits for its
text (VI.1).** The rule reads each name that `declared.nim` declares. A local, a parameter and a
placeholder take none. Names that one line declares share one doc, so that line reports once.
A line of enum members is such a line (D1 a of #752). The check and the fixer share one reading,
`writesDoc` of `declarations.nim`.

- A doc counts where it trails the line of the declaration, or the last line of its value or its
  type. A doc that opens the first line below either one, at a deeper indent, counts too. The doc
  of a routine counts on the first line below its signature.
- The value of a binding runs on over each line of code below it at a deeper indent. Examples
  are the branches of `when`, a sum after `+`, and a `block:` below `=`. Nim reads those lines as
  part of the value, and `nim jsondoc` reads the doc below the last of them. Verified by hand
  with `nim jsondoc` of 2.2.12 and of commit `27763495`, 2026-10-25. 2.4.0 reads the
  same, verified by hand, 2026-10-29.
- A line of enum members ends on itself, because the `,` that closes it opens the next member.
- A name on a line that opens inside a bracket is part of an expression, and takes no doc. Such a
  name is a field of a tuple type, or a parameter of a routine type, over several lines. A doc
  among them breaks the parse, as one after the last field before `]` does. A routine declared
  there, as in `compiles(block: …)`, takes its doc as the first line of its body.
- A doc that holds another TODO, such as `## TODO: Make distinct.`, holds a design note and no
  text. The fixer moves the note above the declaration as a `#` comment (VIII.3), and the doc
  becomes `## TODO: Document.`. A doc of several lines that opens with a note stays for hand,
  because its outline can elaborate the note or the text. The lexer joins a `##` line right below
  it at any indent, so that line makes it a doc of several lines too.
- A one-line borrow or forward in a stack under a group comment passes (VI.1). The stack is a run
  of routines on one line each, at one indent, with the group comment right above it. The group
  comment is a `#` comment. A `##` doc right above the run is no group comment. Inside a
  routine, it is the doc of that routine.
- Code in `quote do:` passes too, since its generator carries its docs through a parameter. So
  does a doc on the line above a declaration that is no routine, at its indent, because it stands
  out of place.
- A doc that only blank lines and `#` comments stand above is the doc of the module. The
  Architect ruled so on
  [D3 a](https://github.com/mraxilus/delegations/pull/980#issuecomment-7054999563) and
  [D1 a](https://github.com/mraxilus/delegations/pull/980#issuecomment-7062317070) of #980.
  It is the doc of no declaration. So missing doc reports the declaration right below it, and
  writes its placeholder there.
- The rule reads the end of each line from its tokens. A string, the closing `"""` of a long
  string and a character literal hold no bracket and no comment for it. A line whose last token
  is `,`, or an operator that ends in `=` or `&`, continues its statement.
- A value or a body that opens a long string, or a comment of several lines, takes its doc where
  that string or comment closes. A doc written on its first line would stand inside the string,
  and change its value.
- Nim 2.2.12, 2.4.0 and commit `27763495` refuse a doc after the `=` of an argument
  inside an open bracket. They refuse one after the `:` of a field or a key there too, as
  `expression expected`. Verified by hand with each compiler, 2026-10-29.

**The fixer writes each doc where doc position puts it and `nim doc` reads it (D2 a of #760).** A
declaration on one line takes it joined to that line, where the joined line fits and holds no
comment. Otherwise the doc takes the next line, one level in (STYLE.md §5). A routine takes it as
the first line of its body, at the indent of the body.

- A value or a type over several lines takes the doc after an `=` that ends its first line,
  where that line fits. The library writes it so, as `Cayley1D* =  ## …`. Otherwise the value
  takes the doc joined to its last line, or on the line below it, one level in.
- A `case` value takes the doc on the line below its last branch, because `nim doc` reads none
  that trails a branch.
- A value that opens `block` takes `# TODO: Document.` above it (Block docs).
- `nim jsondoc` of 2.2.12 and of commit `27763495` reads a doc in each of these places. It
  reads none after the `(` of a call, after `[`, `,` or a binary operator. Verified by hand with
  both compilers, 2026-10-25, and with 2.4.0, 2026-10-29.
- Nim parses no doc on the line below an `=` that ends the first line. So a first line too wide
  for a joined doc sends the doc to the close. Verified by hand with both compilers, 2026-10-25,
  and with 2.4.0, 2026-10-29.

**A forward declaration takes the doc of its routine, and the fix leaves that move for hand.**
`nim doc` of Nim 2.2.12, of 2.4.0 and of commit `27763495` reads the doc of a forward
declaration, and drops the doc of the definition. Where the forward declaration holds no doc, the
page shows none. Verified by hand with `nim doc` of 2.2.12, 2026-10-25, and of each compiler,
2026-10-29. A `## TODO: Document.` there would hide the doc below it, so the fix writes none.

**Missing doc runs after the wraps, and before the comment above.** A doc joins a line only where
the line fits once the wraps settle it. Rejected: missing doc before the wraps. There a doc that
trails a line which opens a bracket holds apart a call that the wraps would join.

- A nested helper on one line that takes its doc stands on two lines. So the next round gives it
  a blank line on each side (STYLE.md §1), and the chain settles in two rounds still. Verified by
  hand with `knoller --check` on each project of this repository, 2026-10-25: no file stays
  unsettled.

- Verified by `suites/test_declarations.nim`: each kind and shape of declaration, and what passes.
  It holds a shared line, a line of enum members, a design note, a forward declaration and the
  lines that the fix traces. It holds a value over lines in each shape that takes its own place,
  and a value that opens `block`.
  It also holds cases of this repository whose value or signature runs past its first line, each
  named where it stands.
- Verified by `suites/test_chain.nim`: a call that the wraps join takes the doc after them.
- Verified by hand on the PGA library at `3d9696e`, 2026-10-25, with a driver that runs
  `fixDocsMissing` alone. It writes 43 docs where `nim doc` reads them. `nim jsondoc` of commit
  `27763495` reads 42 of those docs, in the rigid and the conformal configuration. The other one
  is the doc of a private field, which `nim doc` shows nowhere. Knoller at `9d6d168e` writes
  those 43, and `# TODO: Document.` above each of the 8 values there that open `block`, verified
  by the same driver, 2026-11-27. A second run writes nothing.
- Verified by hand on the output of those 43 writes, 2026-10-25: the suites of `rga3d` and
  `cga4d` compile and pass, with commit `27763495`.
- Verified by hand with that driver over each Nim file of this repository and of the library,
  2026-10-25. A second fix writes nothing, and no token but a comment changes. A probe parses
  each file the fix writes with `parseStmt`, under 2.2.12 and under commit `27763495`, and
  each one parses. Each one parses under 2.4.0 too, verified by hand, 2026-10-29.
- A doc that opens the line right below the first line of a declaration counts, though the
  value runs on past it. That holds for a line inside a bracket, where `nim jsondoc` reads no
  doc. Verified by hand with `nim jsondoc` of 2.2.12, 2026-10-25, and of 2.4.0, 2026-10-29. The
  fixer never writes a doc there, and doc position moves such a doc (below).
- Cost: a routine with no body reads as a forward declaration where any overload of its name
  follows.
- Cost: a routine on one line reads as a forward where its body after `= ` is shorter than
  `BODY_FORWARD_MAX`, 40 bytes. A forward calls one routine with the arguments it takes, as
  `entry(PICK)` does, and a longer body holds logic of its own. The bound is chosen and not
  measured, so a short helper under a group comment passes too.

**Each doc stands in the one position that STYLE.md §5 gives its shape (VI.9).** The Architect
ruled so on rule 5 of #443. For most shapes that position is where `nim doc` reads the doc. Doc
position and missing doc read one place for each declaration (`placements`), and where its doc
stands (`target`). So each doc that the fixer of one writes, the check of the other passes.

- For the group doc of a bare `type` and for the doc of a routine, STYLE.md §5 alone sets the
  position. `nim doc` reads the group doc on neither the keyword line nor the next line. It reads
  the doc of a routine in each place that the fix moves it from. These places are the signature
  line, the line after a blank line, and another indent. Verified by hand with `nim jsondoc` of
  2.4.0, 2026-11-20, on one probe of each shape.
- A one-line doc of a type, a field, a binding or an enum member stands on its line, where the
  joined line fits `LINE_MAX`. Two spaces stand before its `##`. Otherwise it takes the next line,
  one level in. A trailing doc that widens its line past `LINE_MAX` moves there.
- A next-line doc of several lines, or below a line that holds a `#` comment, stands one level in
  too. A trailing doc keeps the lines below it that continue it, at the column that the hand gave.
  The lexer joins each `##` line right below a doc into that doc, at any indent. So no move splits
  such a doc, and that holds on the first line of a value over lines too. Verified by
  `suites/test_declarations.nim`, with `nim jsondoc` of the compiler that builds it.
- A doc above a type, a field, a global binding or an enum member moves where missing doc writes
  it. It joins the line where it fits, else it takes the next line, one level in. A value over
  brackets takes it after its close.
- A doc moves from above only where a blank line or a `#` comment stands above it. A doc right
  below other code stays, because that code can own it. So does a doc that a declaration holds as
  its own. A doc above a local binding stays, since a local binding takes none.
- A doc that only blank lines and `#` comments stand above stays where it stands, as the doc of
  the module. The Architect ruled so on
  [D3 a](https://github.com/mraxilus/delegations/pull/980#issuecomment-7054999563) and on
  [D1 a of #980](https://github.com/mraxilus/delegations/pull/980#issuecomment-7062317070),
  since `nim doc` reads it so. So a license header or a block comment above it changes nothing.
- Doc position reads the first line of the file that holds code or opens a doc. A doc whose run
  opens there is the module's. `nim jsondoc` of 2.4.0 reads it as the description of the
  module, and gives the binding right below it no doc. Once missing doc writes its placeholder
  there, it reads both. Verified by hand, 2026-11-21, on probes under no line, under a license
  header and under a block comment, and on one probe after the placeholder.
- Elsewhere at module level, `nim jsondoc` of 2.4.0 reads a doc above a declaration into the
  description of the module too. So the move gives that doc to its declaration, since the hand
  that wrote it there meant it for that one. That holds for a doc below another doc at the start
  of the file too. Verified by hand, 2026-11-21, on a probe of a doc under a blank line past
  code, and on one below a doc of the module. A probe after each move reads the doc as that of
  its declaration, and the doc of the module stays.
- A one-line doc can stand on the line below the first line of a value over lines. It moves after
  the `=` that ends that first line, where it fits. Otherwise it moves after the close of the
  value, joined where it fits, else one level in. `nim doc` reads none below an `=` that ends the
  first line, nor after `[` or `(` (above).
- The doc of a routine opens the line after its signature, at the indent of its body. A doc on the
  signature line, after a blank line, or at another indent moves there.
- A one-line doc under a bare `type` joins the keyword line, as the group doc of the block.
- Doc position reads as a declaration each line of code in a `type`, `const`, `let` or `var`
  section, at any depth (`sections`). A keyword line that holds one declaration is one too. A
  line that continues an expression declares nothing.
- Verified by `suites/test_declarations.nim`, for each shape and for each doc that stays. The cases
  of `type Order` and `lut_grade_by_basis` quote the PGA library at `3d9696e`.
- Verified by hand with knoller at `9d6d168e` on the PGA library at `3d9696e`, 2026-11-27. A driver
  imports `knoller` and runs `checkDocs` and `fixDocs` alone on each file that
  `git ls-files '*.nim' '*.nims' '*.nimble'` lists. It gives 2 reports. The fix moves the doc of
  `type Order` onto its line, and the doc of `lut_grade_by_basis` above it as `#`. A second fix
  writes nothing.
- Cost: a doc that trails the first line of a value over brackets, or of a signature over lines,
  stays, though `nim doc` reads none there.
- Cost: a doc above a routine stays, and neither rule reads it, though `nim doc` reads none there.
  Missing doc then writes `## TODO: Document.` in the body, so the doc above and the placeholder
  both stand. Verified by hand through the whole chain, 2026-11-20, on one probe of each kind of
  routine body.
- No Nim file of the tree at `16a573cc` opens with a doc right above a declaration. Nor does one
  hold such a doc below blank lines or `#` comments alone. Verified by a scan of each file that
  `git ls-files '*.nim' '*.nims' '*.nimble'` lists, 2026-11-21.

## Block docs

**The doc of a value that opens `block` stands above its declaration, as a `#` comment.** The
Architect ruled so on D1 c of #1020. `nim doc` reads no doc of such a value with `block:` on its
`=` line, wherever the doc stands. `blocks` of `declarations.nim` reads each such binding, at any
reach, and where its doc stands. Doc position and missing doc both read it, so each doc that the
fixer of one writes, the check of the other passes.

- `block:` stays on the `=` line, so the body takes one indent. The doc stands on its own lines
  above the declaration, or above the name in a section. A blank line stands above it. None
  stands where the line above opens the body that holds it, as `if` does, or where the file opens.
- `nim jsondoc` reads no `##` there, and one above a declaration at module level joins the doc of
  the module. So the doc is `#`. The suite "Article VI.9" of `test_declarations.nim` fails once
  the compiler that builds it reads one of these places, and that place then takes `##` again.
- The comment right above the declaration, at its indent, is its doc. A `##` there stays where
  code above, the module, a routine or another declaration holds it, as the lexer joins it.
  `heads` gives the doc of a routine named in backticks, which no declaration reads.
- `blocks` reads the lines that declare in a `const`, `let` or `var` section (`sections`), and
  each placement that opens `block`. The reading of declarations passes over each name below a
  section nested in a block, so it alone would miss such a value. Verified by hand with a probe of
  `declarations` at `9d6d168e`, 2026-11-27.
- `sections` walks up from a line to the keyword of its section. It stops at an enclosing line
  that ends on `=` or opens `block`, other than the keyword alone. So a statement in the body of a
  value declares nothing, as a labelled `block` or an assignment that opens `block`.
- Missing doc writes `# TODO: Document.` above a global such value, with the blank line where it
  is due. A comment above counts as the doc, and so does a `##` that doc position moves there.
- Doc position moves a `##` doc that trails `block:` or stands first in the body. It moves the
  doc to the lines above the declaration, with each line that the lexer joins to it. Each run of
  `#` that opens a doc line there becomes one `#`, and the blank line comes where it is due.
- A doc inside or after `block:` with a comment above it too is two docs, so it stays for hand.
  So does a `block` that opens below `=`, since its body would take one indent less. Its message
  says why. A `=` that closes the head of a routine, as of a lambda, opens no such `block`. Its
  binding takes its doc after that `=`.
- Cost: a `#` comment right above such a value reads as its doc, though it may remark on the
  line above it.
- Cost: missing doc reads its names from declarations, so such a name with no doc takes no
  placeholder.
- Cost: a binding of a routine type whose `block` opens below its `=`, as `let f: proc(): int =`,
  reads as the head of a lambda. So it takes no report of this section.
- Verified by `suites/test_declarations.nim`. Its cases are `lut_grade_by_basis` and `∪` of the
  PGA library, and the doc after `block:` that knoller at `6905e55e` passes. They also hold
  `FACINGS` of `dance_ontology` and `LUT_INITIAL_BY_PAIR` of `ricysoho`, each with its domain. The
  review of #1070 found three more cases, and each is held with its domain. They are a statement
  in the body of such a value, a lambda whose body opens `block`, and a doc on `###`.
- Verified by hand, 2026-11-27, with a driver that runs `checkDocs` and `checkDocsMissing` alone
  on each Nim file that git tracks at `9d6d168e`. Knoller at `9d6d168e` gives 75 reports of doc
  position and 1,082 of missing doc, and knoller at `6905e55e` gives 47 and 1,083. Knoller at
  `672b76a3` gives the same 75 and 1,082 on the tree at that commit, with the same reports of a
  value that opens `block`.
- Of the later reports, 44 read a value that opens `block`, all in contributor projects. Of them,
  39 hold a doc inside the block, 1 a `##` above, 2 a `block` below `=`, and 2 no doc. The earlier
  knoller gives 16 of them, at the same places. It gives 1 more at `curator/audit/src/role.nim:80`,
  since it does not count the `#` doc above that value.
- `fixDocs` alone keeps each token of code in each file that it writes there, and a second fix
  writes nothing. `knoller --check`, built at `9d6d168e`, reports 40 of the 44 as `to fix` in
  those files. It leaves the 2 for hand, and the 2 in `mesh.nim` of `pga_visualiser` and
  `walk.nim` of `dance_ontology`, which neither knoller settles.

## Stages

**A paragraph that a blank line opens takes a stage comment, where its routine comments another
stage (VI.4).** The Architect ruled this narrow form on rule 4 of #443. The paragraph must hold
three lines of code or more (`LINES_CODE_MIN`). The fixer writes `# TODO: Describe stage's
purpose.` above the paragraph, at its indent, as `## TODO: Document.` waits for the text of a doc.
It writes only where the line fits `LINE_MAX`, and otherwise the report stays for hand.

- A body is the lines below the `=` that ends a signature, deeper than the head, for each kind of
  routine. The lines below `test "…":` are a body too. A routine nested in a body cuts the
  paragraphs of the routine that holds it, and its body reads as its own (STYLE.md §1).
- A comment right above a nested helper belongs to the helper. A paragraph of routines on one line
  is helpers too. Neither opens a stage of the routine that holds them, since STYLE.md §1 puts
  each helper before the first stage. Verified by `suites/test_stages.nim`.
- A paragraph is a run of lines with text and no blank line between them, at any depth of the
  body. A line inside a string or a comment that spans lines opens no paragraph, and a blank line
  there ends none. Code under `quote do:` belongs to its generator, so it opens none.
- A stage comment is a `#` comment on its own line, first in the paragraph. Any comment counts, a
  TODO among them, since text cannot tell whether it names the purpose. A trailing comment on the
  first line counts as none, and so does a fence marker.
- The first stage opens after the doc of the routine, so a comment right below the doc opens it.
- A line of code is a line whose view of code holds code, so a comment line counts as none.
- The floor of three lines is the Architect's. The routines of the PGA library that comment a stage
  hold 50 paragraphs of three lines of code or more. Of them, 43 open with a comment. Of the 16
  paragraphs of one line, 6 do. Both figures are the count on #443 of 2026-11-18, unmeasured here.
- Rejected: the broad form, every paragraph that a blank line opens: 45 lines of the library, #443.
- Rejected: `# TODO: Describe stage.`, which asks for no purpose (VI.4).
- Verified by `suites/test_stages.nim`. Its cases quote the macro `defineOperator` of
  `pga/operators.nim` and the routine `filterBases` of `pga/cayleys.nim` at `3d9696e`, and each
  case names its cut.
- Verified by hand with knoller at `048c3c36` on the PGA library at `3d9696e`, 2026-11-20. A driver
  imports `knoller` and runs `checkStages` and `fixStages` alone on each file that
  `git ls-files '*.nim' '*.nims' '*.nimble'` lists. It gives 7 reports, and the fix writes 7 lines.
  They are lines 365, 465 and 504 of `pga/cayleys.nim`, and lines 41, 45, 94 and 98 of
  `pga/operators.nim`.
- Verified by hand with that driver over the repository at `3a6cf5e9`, 2026-11-20. It gives 207
  reports, which no check of `koch check` reads yet.
- Cost: a routine reads from a line that opens with its keyword and its name. So the body of a
  lambda reads as lines of the routine that holds it, and a test reads as `test "…":` alone.
- Cost: a line inside a string that spans lines is no line of code, so a long literal counts its
  first line alone.

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
  `tests/suites.nim` with `|∙ ⊖` keep their space. With commit `27763495`,
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
- A glued `*` before `:` or `,` is a marker wherever its name stands. A binary `*` takes an
  operand after it, and neither token opens one. So `case is_read*: bool` and the field of a
  branch, `of true: fixer*: Fixer`, keep their form. Verified by `suites/test_spacing.nim`, and by
  `koch fix --dry-run` on `src/knoller/reports.nim` on 2026-11-03, which reports no spacing on
  its lines 93 to 96.
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
  with the parser of commit `27763495`. `i + 1 ..< n` and `i + 1..<n` read
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
  `a ^ (-b)` settles on `a^(-b)` in one round. A group of one plain operand goes where the parser
  proves it, so `-1 ^ (k)` becomes `-1^k` through the chain. A group that holds math stays, as in
  `-1^(int(b.grade) * int(b.gradeAnti))`. Verified by `suites/test_chain.nim`.
- A `^` that ends its line takes one space before it, as a range does.
- Spacing moves no parse tree, and the wrap adds one group around the exponent alone. Verified by
  hand, 2026-10-05, with the parser of commit `27763495`. `-1 ^ k`,
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
  nothing, so it keeps its spaces, export marker or not (`isListDeclared`). That covers
  `func scalar*[I: Basis | Grade]`, `func pick[I: Basis | Grade]` and `Foo[T: A | B] = object`.
  Its head is a routine keyword or `type` on the line of the name. An entry of a `type` section
  counts too, read from the nearest line above at a smaller indent. Verified by
  `suites/test_spacing.nim`.
- Cost: a generic list of an entry under a `when` inside a `type` section reads as a selector.
- An operator that ends its line inside such a bracket takes one space before it, as elsewhere.
- Spacing moves no parse tree here too. Verified by hand, 2026-10-04, with the parser of
  commit `27763495`: `prev[i - 1]`, `digits[i + 1 ..< n]` and `a[f(x, y + 1)]`
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

**A condition that mixes `and` with `or` takes parentheses around each `and` (X.4).** The parser
already groups it so, because `and` binds tighter than `or`. So the parentheses move no reading.
The check reads an expression on tokens, at one bracket depth, between delimiters. A command call
holds the expression after its head.

- `not` over a binary expression has a check and no fixer. Nim reads `not a == b` as
  `(not a) == b`, so the right parentheses depend on intent.
- Verified by `suites/test_precedence.nim`. The tree holds no finding of either rule.

**A group of parentheses goes only where the parser of the code's own compiler reads the same
tree without it (X.4).** The Architect ruled this on 2026-10-05, since a list of special cases
cannot hold the rule (#539). The scan names candidates of three kinds alone, which the Architect
chose. A group goes around a prefix term that stands as one side of a binary operator:
`(|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ (𝐦 ∧ ⊖𝐧))` becomes `|∙ ⊖(𝐦 ∧ 𝐧) + |∘(𝐦 ∧ ⊖𝐧)`. A group goes around one
plain operand after a prefix operator, as `■(𝐧)` becomes `■𝐧`. A group goes around one plain
operand as one side of a binary operator, as `2'u^(DIMENSIONS)` becomes `2'u^DIMENSIONS`.

- Verified by `suites/test_parentheses.nim`, `suites/test_proofs.nim` and `suites/test_chain.nim`.
- A plain operand is a name or a literal, with any call, index or field glued after it. A prefix
  term is one or more symbol prefix operators, then one operand. The elements read as
  `precedence.nim` reads them, on the line of the group and inside the bracket around it.
- The parser decides each candidate. A probe, which the compiler of the code runs under `nim
  check`, parses the source with `macros.parseStmt`. A candidate goes where the source without
  it parses to the same tree, with each group of one child collapsed on both sides.
- Then the probe removes every candidate that proved alone, together. Where that tree differs,
  each candidate joins in source order while the set still proves, so the answer is the same on
  each run. No pair of real groups was found that proves alone and not together: 39,032
  statements with two candidates or more gave none under 2.2.12. Verified by hand, 2026-10-05,
  with the scratch programs `gen.nim` and `run.nim`. `suites/test_proofs.nim` drives the fall
  back with a group named twice.
- A source that the parser cannot read keeps every group.
- So `@(x[i])` stays, since the sigil `@` binds `x` before its index. The case as found is
  `links = @(PAIRS[task.pair][0])`, line 79 of `tests/test_read.nim` of `dance_ontology`. The
  scan of `main` removed it, and `@PAIRS[task.pair][0]` reads as `(@PAIRS)[task.pair][0]`. So do
  `@(x.items)`, `@(f(a))` and `@@(x[0])`, and a bare `@(x)` goes.
- The parser also keeps a group that the scan of `main` read wrongly. In `a - (-b) -1`, the
  parser reads the group as the callee of the command `(-b) -1`. Without the group, `-` takes the
  command `b -1`. No guard of the scan looked past `-1`, so `main` removes the group. Found with
  the parser of 2.2.12, 2026-10-05, and held by `suites/test_proofs.nim`.
- The proof drops three guards of the scan, since the parser decides their cases. One is the
  merge guard of `spacing.nim`, as for `-(1)`, `\(/𝐮)` and `^(|𝐦)`. The others guard a glued
  suffix, as in `(■m).x`, and the head of a command, as in `check (|∙ x)`. Each of those groups
  still stays, as the parser of commit `27763495` answers.
- The guard on the head of a command was too wide. In `doAssert (⊛m) =~ x`, the glued `⊛` reads
  as a prefix operator, so commit `27763495` reads the same tree without the group. So the group
  goes. The case as found was line 35 of `proposals/03-partner-sign/laws.nim` of `pga_benchmark`.
- Two filters stay, and each one only saves runs of the probe. A group after the power operator
  `^` whose removal would glue the exponent into the operator is no candidate. Spacing glues `^`
  and wraps that exponent again (X.9), so `a^(-b)` and `a ^ (-b)` keep the group in one round.
  A group that spans lines or holds a comment is no candidate either.
- A group around a binary expression is never a candidate, whatever its precedence, as the
  Architect ruled. So `1'u shl (i-1)`, `(2'u^DIMENSIONS) - 1` and the parentheses of X.4 around
  `and` stay. A tuple, a call, a signature and the argument of the command form are never
  candidates either. Each holds a separator or glues to its callee.
- `checkParentheses` reports only the groups that the proof removes. A source with no answer
  reports none, so a check never names a group that the fix keeps.
- Cost: `not` and the other keyword prefix operators are not read. X.4 holds `not` apart, and
  `not(a)` glued would lex as one name.
- The chain runs the rule before spacing, so `|∘ (` glues as `|∘(` in the same round.

**The caller runs the compiler, so the chain stays pure.** The parentheses step writes what the
answers in `Proofs` prove. Where no answer holds for the source that it reads, it writes nothing
and asks (`Fix.asked`). The caller gives every source asked to one run of the compiler, holds the
answers by source, and fixes again each file that asked. An answer never changes once held, so a
file that asked nothing gives the same result again. The command line asks at most eight times.

- `koch fix` does the same for each pin (`curator/audit`).
- A fix of every file each round gives the same outcome (D2 of #548). Verified by
  `suites/test_command.nim`, where a reference loop fixes every file again. On several files,
  where some ask over two rounds, one asks through its fence and some ask nothing, both give the
  same outcome. This holds for a stub parser, for a parser that fails, and for a parser that fails
  from its second run.
- The prover is a proc value (`Prover`), so the suites stub it (`suites/stubs.nim`). The stub
  answers each case as commit `27763495` answered it, 2026-10-05. `suites/test_proofs.nim` and
  `suites/test_regressions.nim` run the compiler that builds them, 2.4.0 in the job of knoller,
  and hold their verdicts to the real parser.
- The compiler is the caller's. `koch fix` passes the pin of each project. The command line takes
  `--nim:path`, else the pin of the nearest nimble file, else `nim` on `PATH` (`## Compilers`).
- Where the compiler does not run, the rule removes nothing, and the run prints one warning that
  says why. The exit code stays. Verified by `suites/test_command.nim`.
- Rejected: the parser of the compiler linked into knoller. It would read each project with the
  grammar of one compiler, while each project may pin another. 2.2.12 lexes as names the glyph
  operators that 2.4.0 lexes as operators.
- Cost: a wrong compiler can prove what the right one refuses. 2.4.0 and commit `27763495` read
  `■m.x` as `■(m.x)`, so the group of `(■m).x + y` stays. 2.2.12 reads `■m` as one name, so it
  proves that group. So `koch fix` and the command line each take the pin of the project.
  Verified by `suites/test_proofs.nim` for 2.4.0, and by hand for each compiler, 2026-10-29.
- Cost: each round of asking compiles the probe once, about 0.6 s to 0.8 s on this container.
  Measured 2026-10-05 with `knoller --check`, this head against `main`: `rga_visualiser` took
  6.0 s against 5.5 s, and `pga_benchmark` 3.1 s against 2.0 s. `dance_ontology` took 5.3 s
  against 3.6 s, and `curator` 4.2 s against 3.1 s.

**The proof on the PGA library: the parser removes what the scan removed, and nothing more.**
Verified by hand, 2026-10-05, with the built binary and commit `27763495`.

- At `edb0c9d`, knoller at `main` and at this head each fix 84 rewrites. The counts by rule are
  the same, and so is the output, byte for byte. The one group is `(DIMENSIONS)` of
  `pga/algebra.nim:255`, and both remove it. A second run fixes none.
- `nim check` reads each of 64 targets with the same result before and after, and `testament
  all` passes 8 of 8, megatest output OK.
- At `d9be8ae`, both fix 338 rewrites with the same output, and 49 of them are groups. A second
  run fixes none.

**A `to<Target>` call of a plain argument takes its subject first (STYLE.md §5).** A plain
argument is a name, with any call, index or field glued after it. A compound argument, a literal,
a generic call, several arguments and a call across lines stay prefix calls. A call followed by
a bracket stays too, because `y.toX(z)` and `y.toX[T]` read otherwise.

- The rewrite reads no symbol. A field named like the routine, such as `to_x`, would capture the
  method call. The tree holds no such field, and every changed file checks as before.
- Verified by `suites/test_targets.nim`.

**A call of a `define…` or `emit…` routine is a prefix call (STYLE.md §5).** The rule reads a
name that opens `define` or `emit`, then a capital, after a `.` glued to it. The fixer moves the
receiver into the call as its first argument, so `MESHES.emitObject(p)` becomes
`emitObject(MESHES, p)`. A receiver is a name with any call, index or field glued after it, or a
bracket group, which gives its parentheses to the call. A `construct…` call takes the subject
test of STYLE.md §5, as every other call does.

- The rule of type conversions reads a receiver the same way, and this rule reaches its readers.
- A receiver that the file imports as a module qualifies the name, so `tessellate.emitObject`
  stays.
- No fixer reaches four shapes, since each holds a layout that hand chose. The check reports
  each, and hand writes it:
  - a receiver on the line above the dot;
  - a generic call, or an index after the name;
  - a command call;
  - arguments that open on the line after `(`.
- The rewrite reads no symbol. A field spelled like a routine would read as a call, but a field
  is in snake case (V.1).
- The fixer runs before the command form, so that rule never reads a dotted call of either verb.
- The static pass of `curator/audit` runs the check beside the entry block, and does not wait in
  `checkFormatting`. The Architect ruled the call form with the verbs of generation, so the call
  and the kind of its routine reach the projects together.
- Verified by `suites/test_generations.nim`. Verified by hand, 2026-10-12: knoller rewrote each
  dotted call in copies of `src/desktop/main.nim` and `tests/suites/test_mesh.nim` of
  rga_visualiser, and changed nothing else of those lines.

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
  `nkCall`, with the same callee and argument. Verified by hand, 2026-10-04, with the parser of
  commit `27763495`, on each shape of `suites/test_commands.nim`.
- The rewrite never widens a line: `(` becomes a space, and its `)` goes. The chain runs it before
  the call layout, so the layout reads the command form. Verified by `suites/test_commands.nim` and
  `suites/test_chain.nim`.

## Messages

**A message echoes each value after `got` in backticks (IV.4).** The check reads the
concatenation from the literal that holds `; got ` to its end. Each interpolation and each
operand there must stand inside a backtick span, counted from `got`. A tail that ends on a word,
such as `got none.`, echoes no value and is no finding.

- The fixer puts a backtick on each side of a bare value, inside the literals around it.
- A value that ends the message has no literal after it, so the message takes a fixed shape. A
  backtick goes at the end of the literal before the value, and `& "`."` goes after it. So the
  message ends on its value, in the form that IV.4 gives as its example.
- A value whose operator binds as loosely as `&`, or more loosely, keeps its finding, since the
  appended literal would join that operator. So `"got " & a == b` stays.
- The rule reads every value of the tail, so a context after the value takes backticks too, as
  `for {manner}` does.
- An `&` that joins two operands stands on the line where the first one ends. Nim continues a
  line that a binary operator ends, so a line that `&` opens is the next statement, such as an
  `&"…"` result.
- An operand ends at its line, so a bracket that opens the next line opens the next statement.
  A comment after such an `&` is no operand, and the operand follows it on the next line.
- A test that builds the old text in the same form changes with it. A test that asserts the
  text in another form takes an edit by hand.
- Verified by `suites/test_messages.nim`.

**Each value of a message stands in backticks, wherever it stands, and a value that opens its
claim stays for hand (IV.4).** The Architect ruled so on rule 6 of #443, with no demand for the
form `; got`. A message is an argument of a call that takes one (`CALLS_MESSAGE`). It is the
second argument of `assert`, `doAssert` and `newException`. It is the first of `error`, `quit`,
`raiseAssert` and `warning`. It is also the value of the pragmas `error`, `warning` and `fatal`.

- The value of a pragma is a message only where the innermost bracket around it is `{.`. So a
  field, an argument or a binding of that name holds no message.
- A message that holds no literal, as one that a binding holds, is none.
- The check reads the concatenation of a message from its first operand, as the rule of message
  value reads its tail. Each interpolation and each operand must stand inside a backtick span,
  counted from the start of the message.
- A value that the rule of message value reads, after `; got ` in its literal, takes no second
  report.
- The fixer writes the backticks as the rule of message value does. An operand that ends a message
  takes `& "`"` after it, and no period, since such a message takes a form of its own.
- A value that opens its claim, with words after it, stays for hand, since a fix cannot reword
  the claim. Its report names the words after it.
- A message under `quote do:` reads too, since the macro writes it into code. A name that the
  macro splices there is an operand.
- Verified by `suites/test_echoes.nim`. It quotes each message of the library at `3d9696e` that the
  rule reports, and the message of `tools/cll.nim` of `ricysoho` that a binding `error` tripped.
- Verified by hand with knoller at `c3c34ca8` on the PGA library at `3d9696e`, 2026-11-20. A driver
  imports `knoller` and runs `checkEchoes` and `fixEchoes` alone on each file that
  `git ls-files '*.nim' '*.nims' '*.nimble'` lists. It gives 4 reports, and the fix changes the 3
  lines that the ruling counts. The value that opens its claim keeps its report, and a second run
  writes nothing.
- Cost: a message that a binding holds, or that a routine of the project builds, stays unread.

**An interpolated string takes each value in braces, never by `&` (STYLE.md §3).** The Architect
ruled so on rule 21 of #443, after ruling D3 on `&"y is {y}, from " & $x`. A concatenation that
holds an interpolated literal, `&"…"` or `fmt"…"`, and joins an operand or a literal to it by `&`
takes one report. The fix joins it into one interpolated literal.

- The check reads each expression of each depth by precedence, as the check of conditions does
  (`segments`, `tailCommand`). An operator that binds more loosely than `&` splits the
  expression, so each operand of `&` stays whole, and `dir / name` joins as one value.
- A concatenation with no interpolated literal passes, as `"E" & $b` at `pga/algebra.nim:268`
  does. By the page's figure for ruling D1, interpolation costs 5 to 15 ns more for each message
  than `&`. So the fix never turns a plain join into one.
- The fix keeps the prefix of the first interpolated literal, `&` or `fmt`. `$x` becomes `{x}`,
  since `formatValue` of `std/strformat` turns a value to text by `$`, read in 2.4.0. A group under
  `$` gives its content. A plain
  literal joins as text, with each brace doubled. A backtick round a value stays (IV.4).
- A wrap of literals whose joined line would not fit `LINE_MAX` passes, since X.1 lets a long
  string break so. The fit counts runes alone, since the width check lets a line of one long
  token stand. A wrap whose joined line fits is joined.
- A value stays for hand, with its report, where it holds a quote, a brace, a backslash or a
  backtick. So does one that holds a line break or a colon outside brackets. So do a raw or long
  literal and a comment between two operands, and a concatenation whose joined line would not fit.
- A literal stays for hand too where the kept literal would read its escapes otherwise, since
  `fmt"…"` is raw and `&"…"` is not. So does an escape by number, which can spell a brace.
- The chain runs the fixer only where the project declares no `formatValue`, which
  interpolation calls in place of `$` (`isDeclaringFormatValue`). The audit reads each `.nim`
  file of the tree. The command line reads each file of the run in a Nim dialect. Each groups
  them by nimble file. The check still reports there, and the report stays for hand.
- Verified by `suites/test_interpolations.nim`, `suites/test_command.nim`, and
  `suites/test_fixes.nim` of `curator/audit`. Verified by hand, 2026-11-20, with each mutant built
  alone in its own cache. A mutant that drops the guard in the command line or in the audit fails
  its suite. So does each mutant that drops a guard of a value or a literal for hand.
- Verified by hand with knoller at `008ecfa1` on the PGA library at `3d9696e`, 2026-11-20. A driver
  imports `knoller` and runs `checkInterpolations` and `fixInterpolations` alone on each file
  that `git ls-files '*.nim' '*.nims' '*.nimble'` lists. It gives no report, since each wrap of
  the library would join past `LINE_MAX`, at 122 and 123 runes.
- Verified by hand with that driver over the repository at `008ecfa1`, 2026-11-20. It gives 53
  reports, and the fix joins 24, each settled, since a second run writes nothing.
- The ruling of 2026-11-19 counts 44 reports and 21 fixes. Three wraps join here at exactly 100
  runes, which X.1 allows. They are lines 2796 and 2804 of `src/desktop/main.nim` of
  `pga_visualiser`, and line 408 of `design/checks.nim` of `dance_ontology`. The cause of the
  other 6 reports, each in `dance_ontology`, is unmeasured.
- Cost: a `formatValue` that a dependency declares, or a file outside the run of the command
  line, is unread.
- Cost: a wrap that holds a value and does not fit stays whole for hand, though a join inside one
  of its lines would fit.

## Wraps

**A repair that widens its line past `LINE_MAX` stays, and the chain wraps the line.** The
Architect asked for this on 2026-10-04, with three properties of `koch fix`. It is deterministic,
a second run writes nothing, and no option sets a style. The tab, comment, message, condition,
spacing and continuation fixers are wideners. Each one repairs freely off the held lines, and
keeps the width guard on them.

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
- A file that still changes after its last round stays as written, so the chain never writes a
  file half settled. Its fix says why in `Fix.unsettled`, a message that names no rule.
  `curator/audit` keeps its semantic edits for such a file, since a rename planned whole reaches
  other files too.
- A list of rules holds the rules of style that source can break. A fixer that does not settle is
  a fault of the tool, so no rule names it (D1 a of #572). No article cites it either.
- Rejected by the Architect: `unsettled` as a member of `Rule`. It would take a row in the README
  and an article in `CITATIONS`, as if the source broke a rule of style.
- Rejected: a fixer that wraps its own line. `form.nim` and `wrapping.nim` would then import each
  other, and a later fixer could undo the wrap.
- Rejected: one pass of wraps at the end. It can leave a wide line, and nothing then holds the
  repair back.
- Cost: a line broken at an operator stays broken where it later fits, as a break of the hand does.
- Verified by `suites/test_chain.nim`. Each case of the tree wraps to its exact output, and a
  second run writes nothing. A line that no wrap fits keeps its finding, held the second time. A
  file that never settles stays as written, and its fix holds the message.

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
(`liftsHead`). A chain that opens mid-line inside a call takes the layout of one level of that
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

**The check of articles reads the comments of Nim from tokens, as the fixer reads them.**
`linesComment` gives the text of each line that a comment holds, with its markers left out, and
`checkArticles` reports each line that holds an article. A caller that reads comments of another
syntax passes its own lines to the same check. So `curator/audit` reports each kind in the same
words.

- Verified by hand, 2026-10-06, with a scratch program, on each Nim file that `git ls-files
  '*.nim'` lists. `linesComment` gives the same line and text as the Nim scanner of
  `curator/audit`.
- Verified by `suites/test_articles.nim`, with the Nim cases of the scanner of `curator/audit`.

**Commented code holds no article, as comment form reads it (VI.10).** The check and the fixer
skip each line that comment form reads as code (`linesCode` of `claims.nim`). There `a` names a
value, as in the commented `func` of `pga/cayleys.nim:48`, and no article. The Architect ruled so on
[D3 a of #980](https://github.com/mraxilus/delegations/pull/980#issuecomment-7062317070).
Code commented by hand, with no space after the marker, and by a tool, with one, both read as
code (`## Claims`).

- Verified by `suites/test_articles.nim`: line 48 of `pga/cayleys.nim` of the PGA library reports
  nothing, in either form. A line of code under prose reports nothing, and the fixer leaves it.
- Verified by run on the PGA library at `3d9696e`, 2026-11-21. `knoller --check .`, built at
  `d0d4e976`, leaves one article for hand, `the` at `pga/multivectors.nim:37`. It reports nothing
  at `pga/cayleys.nim:48`.

**The caller says of each file whether its comments drop their articles.** `formatted`,
`checkSource` and `checkFenceHeld` take `should_drop_articles`, which is true by default. Where it
is false, the chain runs no fixer and no check of articles on that file. There the rule of
comment form reads its names alone (`## Claims`). Every other rule runs.

- A comment in another language can hold a word that reads as an article. In lojban, `a` joins
  two names, as "or" does in English. The fixer would delete it and change what the comment says.
- The mode is the policy of the caller, as the words that a name may take are (`## Names`). So
  knoller holds no list of files, and reads nothing of a repository to decide.
- Rejected: a set of directories that knoller matches against each path. The caller already holds
  the path of each file that it passes, so one flag for each file is the smaller input.
- Cost: the command line sets no mode, so it drops the articles of every comment that it reads.
  A file whose comments keep another language needs a caller that sets the mode.
- Verified by `suites/test_chain.nim`: in each dialect, the mode off keeps the word in the fixer,
  the check and the fence warning. The fix of spacing still runs, and the default drops the word.
- Verified by `suites/test_command.nim`: the check of the command line reports the word and exits
  1, and its fix writes the word away.

## Outlines

**A nuance stands two spaces past where the text of its parent starts (VI.2).** A tag such as
`TODO:`, `Cost:` or `Rejected:` is text of its line. So a line below `# TODO: Implement …` stands
two spaces past where `TODO:` starts, as the Architect ruled on #1020. A summary may wrap two
spaces deeper.

- Rejected: a nuance past each leading tag, as the ruling on tags of rule 3 of #443 read it. A
  nuance then hung off the width of its tag, and the Architect wants one step under any line.

- A comment is a doc as the lexer joins it: a `##` line and each next line that opens with `##`.
  That next line can stand at any column (`scanComment` of `compiler/lexer.nim` of 2.4.0). A
  comment is also a run of own-line `#` lines at one column, or a trailing `#` comment alone. A
  block comment, a fence marker and a shebang (`#!`) are none.
- The step of a line is the count of spaces between its marker and its text. The parent of a line
  is the nearest line above it in its comment at a smaller step.
- A table row (`|`), a diagram and code between fences of three backticks hold no step. So does a
  blank line. A `#` comment whose first line stands at an even step is commented code, as `#func`
  is, so it holds no outline.
- A diagram holds one item, a name or a bracket group, each side of each arrow `->` outside
  backticks. A bracket group alone above an arrow is a line of it too. So an arrow that prose
  quotes in backticks, or writes between measures, marks no diagram (`isDiagram`). Verified by
  `suites/test_outlines.nim`, with the diagram of `pga.nim` at `3d9696e`.
- The fixer sets each line two spaces past where the text of its parent starts, as the parent stands
  once moved. So the lines below a moved line move with it. A comment whose move would widen a line
  past `LINE_MAX` stays for hand, whole, and its reports stay.
- Verified by `suites/test_outlines.nim`. Its cases quote `pga/multivectors.nim`,
  `pga/operators.nim`, `pga/algebra.nim` and `pga.nim` of the PGA library at `3d9696e`, and each
  case names its cut.
- Verified by run of `knoller --check --form:line .` on the PGA library at `3d9696e`, 2026-11-27.
  Knoller built at `8a7b2f61` gives 10 reports of this rule, and built at `4d7f3815` gives 2. The
  9 that go are lines under tags, as the library writes them. Line 354 of `pga/algebra.nim` stays,
  a nuance one space short. Line 4 of `pga/operators.nim` comes, since it stands two spaces past
  `Implement`.
- Verified by run of `knoller --check --form:line contributor curator koch.nim` over the
  repository at `5cd47d47`, 2026-11-27. The two builds give 2,296 and 1,468 reports of this rule.
  By path and line, 835 go and 7 come. The rules differ only in the width of a tag. So each line
  that goes or comes stands under a tag.
- The 7 that come stood in curator code, which now holds each of them two spaces past its tag.
- Line 29 of `design/record.nim` of `dance_ontology` takes a report with both builds. The first
  leaves it for hand, and the second fixes it. It stays for its contributor.
- Each report of another rule is the same with both builds, in each run. No check of `koch check`
  reads this rule yet.
- Cost: a line of a table, a diagram or code stays where its parent moves.

**A doc holds one summary line, and its sentence ends in a period (VI.1).** The first line of a
doc is its summary. One check reads both rules. Each reports under a rule of its own, since each
cites an article of its own (D1 c of #563).

- In the first paragraph of a doc, a line at the summary step after a line that closes a sentence
  is a second summary. It moves two spaces past where the text of the summary starts, with the
  lines below it.
- After a line that runs on, the summary wraps at its own step. It stays for hand, since the hand
  alone knows where the sentence ends.
- A paragraph after a blank `##` line can hold lines at the summary step. The header of a module
  in the example of Article I holds them so.
- A generated doc is the string that a call passes as the argument `docs`, by name. Its first line
  is its summary, which ends in a period, or wraps two spaces deeper to a line that does. Else it
  stays for hand, since a fix of its string changes its value.
- The generated doc of line 222 of `pga/operators.nim` stays for hand so, since its second line
  stands four spaces deeper. Verified by `suites/test_outlines.nim`.
- Cost: a generated doc passed by place, and not by name, is unread, and so is its outline past
  the summary.

## Claims

**A comment opens with a capital and closes with a period, and each path, literal and name in it
stands in backticks (VI.10).** The Architect ruled so on rule 2 of #443, with four answers. A
lowercase line two spaces deeper is a wrap of the sentence above, and no claim of its own. A line
with no closing mark before a capitalised line takes no report. A citation of the charter stands
bare. The rule reads no string that a generator passes as a doc.

- The comments are those that `comments` of `outlines.nim` gives, so both rules read one grouping.
- Commented code holds no prose. It is a `#` comment whose first line stands at an even step, or
  reads as code (`isCode`). Code there is a call or index glued to a name, to an operator name or
  export marker, or to a name in backticks. So `# func <=(a, b: Order)` reads as code. So does an
  assignment or comparison after a name. It is also a line that ends in `=`, a keyword line that
  ends in `:`, or a nested marker.
- The hand comments code with no space after the marker, and a tool leaves one. So both read as
  code, as the Architect ruled on
  [D3 a of #980](https://github.com/mraxilus/delegations/pull/980#issuecomment-7062317070).
  The check of articles reads the same lines (`linesCode`, `## Articles`).
- A line without a step holds no prose, as the outline reads it (`isStepless`). Nor does an
  aligned column, that is two spaces or more between words outside backticks and quotes. Nor does
  a deeper line that continues one, or a `#` line that reads as code.
- Two spaces after a closing mark, a comma or a semicolon stand between the clauses of a sentence,
  and align no column. The header of `simulation/rig.nim` of `dance_ontology` writes them so, and
  `suites/test_claims.nim` quotes it as found at `e9ac1be1`.
- A path is a word with a file extension of `EXTENSIONS_FILE`, as `cayleys.nim`, or a folder that
  a slash closes, as `draw/`. Backticks replace its double quotes, as EXAMPLES.md, I.6 writes it.
  A capitalised name with an extension and no folder, as Node.js, names a product, and stands
  bare.
- A literal is a range, a typed literal or a hex literal, as `E1..E4`, `1'e1` and `0xFF`. Literals
  with only operators and fillers between them take one pair, as in `1'e1 ∧ 1'e2 ∧ ... ∧ 1'en`. A
  possessive, as `7's`, is none.
- A name is a Nim type that is no English word (`TYPES_BARE`), as `seq` and `int`. It is also an
  identifier that the file declares in a shape that no English word takes. That shape holds `_`, a
  digit after a letter, or an inner capital. So a name in capitals alone takes `_` or a digit,
  since RGB reads as a word. A dotted name takes backticks where the file declares a part of it,
  each part two letters or more.
- A word that a reader cannot tell from a word of English stays bare. Such a word is one
  lowercase word, as `sqrt`, or one capitalised word, as `Basis`. So is an enum member alone, and
  a word with a letter outside ASCII, which is formal notation.
- A citation is a Markdown file named in capitals alone, as STYLE.md or PROVENANCE.md, and it
  stands bare. A record file stands bare too, since the ruling on rule 2 of #443 answers for
  charter and record files together. A path with a folder takes backticks.
- Cost: a name that another file declares stays bare, since a check of knoller reads one file.
- Verified by `suites/test_claims.nim`. Its cases quote each library line that a report names, and
  each case names its cut.

**A claim ends where its sentence must close, and a wrap reads no end.** A claim ends at the last
line of a comment, before a shallower line, before a line without a step, and before a bullet.
There it closes with `.`, `?`, `!`, `:` or `…`, past a closing bracket or quote. Before a bullet,
or before the next item of the list that it continues, it closes with `,` or `;` too. A line that
runs on to a line of the same depth or deeper is a wrap. The rule reads no mark at its end.

- A claim starts at the first line of a paragraph, and after a claim end. There it opens with a
  capital, and a leading tag, as `TODO:`, opens it so. A lowercase line deeper than the line above
  it continues that sentence (VI.2).
- A bullet opens as it will. A bullet that ends the sentence of the line above may open in
  lowercase, as the headers of knoller write their lists.
- A label carries neither a capital nor a period (VI.10). It is a trailing `#` comment. It is
  also an own-line `#` comment of one line that opens with no capital, or that hangs under the
  code that it labels. A comment of one line that holds one word or opens with a citation is a
  label too.
- `e.g.` and `i.e.` close no sentence, so a line that ends on one is cut.
- Verified by `suites/test_claims.nim`. It quotes the library lines of each answer: lines 163 and
  165 of `pga/algebra.nim`, and lines 30 and 229 of `pga.nim`.

**The fix writes each backtick, period and capital, and leaves each cut for hand.** A claim that
ends on a function word (`WORDS_CUT`), on another mark, or on `e.g.` is cut. So is a lowercase line
after a sentence end. A fix would hide the cut, so each one stays for hand. Backticks and a period
that would widen a line past `LINE_MAX` stay for hand too. A capital widens nothing, so the fix
writes it.

- The check and the fixer share one reading (`prose`), so one place holds the rule (Article II.1).
- The fixer runs after the fixer of articles, so a claim whose article goes takes its capital
  after (`chain.nim`).
- Verified by hand with knoller at `048c3c36` on the PGA library at `3d9696e`, 2026-11-20. A driver
  imports `knoller` and runs `checkClaims` and `fixClaims` alone on each file that
  `git ls-files '*.nim' '*.nims' '*.nimble'` lists. It gives 13 reports. The fix changes the 12
  lines of the diff on the library that D1 a of #443 accepted. A second run writes nothing, and
  `knoller --check` keeps the count of each other rule.
- Cost: two spaces between words, outside backticks and quotes and after no closing mark, comma or
  semicolon, read as an aligned column. So a sentence with two such spaces holds no prose.
- Cost: a `#` comment of code at an odd step that reads as no code, as `# echo x`, reads as prose.
  A `#` line of prose that holds a call glued to a name reads as code, so it takes no report.

**A comment in its own language reads names alone.** Where the caller says that the comments of a
file keep their articles, the chain runs `checkBackticks` and `fixBackticks` in place of the full
forms. VI.10 lets such a language set its own capitals and periods, and a name takes backticks in
every language.

- Verified by `suites/test_claims.nim`: the chain reports a capital, a name and a period in the
  default mode, and the name alone in the other mode.

## Names

**Every declared name in Nim is read, and its words are held to the table and to the words the
caller gives.** A declaration is a binding, a routine, a type, a field, a parameter, an enum
member or a placeholder. `declared.nim` reads them after comments and strings are blanked. A
binding comes from `let`, `var`, `const`, `for` or `except … as`. A word is a run between
underscores and case changes. The table pairs each coined abbreviation with its one full word.

Knoller reads no glossary, because a glossary belongs to a repository, and knoller runs on any. So
the acronym rule of V.9, which passes an acronym only where a glossary lists it, is a check of
`curator/audit` (D2 of #572). The words that a name may take beyond the table are the words of the
caller. `curator/audit` gives those that its glossaries list, and the command line gives none. The
jargon list of V.6 always passes. Verified by `suites/test_names.nim`.

- Each finding names a rule of its own: `abbreviation`, `action-verb`, `boolean-name`,
  `lookup-table`, `name-case`, `member-case`, `placeholder-letter`, `notation`, `global-word`,
  `representation-head`, `routine-suffix`, `generic-suffix` and `collection-name`.
  The case of a name takes three rules, because V.1, V.11 and V.12 state it by kind.
- This module gives the rename that each rule asks (`renamesAbbreviation`, `renamesCase`). A
  rename reaches each use of a name, and only the semantic pass of the compiler finds each use. So
  `rewrites.nim` plans it, as Semantic pass describes.
- Rejected by the Architect: the acronym rule in knoller, with the words of the caller. The
  command line would report each acronym of another repository, which has no glossary to list it.

**A foreign name keeps the spelling that foreign code reads.** A routine whose pragmas hold a word
of `MARKS_FOREIGN`, such as `importc` or `exportc`, declares such a name, so it is skipped. By the
ruling of the Architect, its parameters are ours, and they are read. So `wake: bool` takes a
boolean prefix like any other parameter. The pragma block may stand on its own line after the
signature, and the scanner joins it.

- `MARKS_FOREIGN` is the one list of these words. `{.push.}` reads it too, and so do the rename
  fixers of `curator/audit` and the move of an entry block. Each reader takes the words among
  pragmas (`wordsPragma`), never a part of another name.
- Rejected: a list for each reader, since copies drift apart, and a substring match, which reads
  `dynlib_path` as a mark.
- Verified by `suites/test_names.nim` and `suites/test_idioms.nim`, for each pragma of the list.
  `JsRoot` is no pragma, and `suites/test_names.nim` of `curator/audit` verifies it.

**The case of a name follows its kind (V.1, V.11, V.12).** A type and an enum member are
Pascal, and a routine is camel. A local, a parameter and a field are snake, and a global is
SCREAMING. A placeholder in generic brackets, or after `concept`, is one capital letter. Each
case is a fact about letters, so the check needs no list of words:

- Pascal opens on a capital and holds no underscore. Camel opens on no capital and holds no
  underscore.
- Snake holds no capital. SCREAMING holds no lowercase letter.
- One letter fits by its own case. A capital passes a type, a global and a placeholder. A
  lowercase letter passes a routine, a local, a parameter and a field.

**A variable in the notation of its source keeps that notation (III.5).** A binding, field or
parameter whose name holds a non-ASCII letter is notation, such as `𝐦`, `𝐮` or `𝐌`. At any
scope, notation holds over the case of V.1, so the check does not read its case. At module
scope, notation holds only for an immutable global. So a mutable global in notation is one
finding, of the rule `notation`.

- A type, a routine, an enum member and a placeholder are no variable, so their case is read.
  `std/unicode` gives no case to the mathematical alphanumeric letters. So `caseLetter` reads
  them by their block, where each style runs its capitals first.
- An operator is backticked, so it is never read as a name.

**A one-letter capital local is a finding, by the ruling of the Architect.** Plain ASCII is
never notation. So `N` or `M` as a local, a parameter or a field takes the snake case of V.1.

**A parameter of type `typedesc` alone takes the one capital letter of a placeholder, by the
ruling of the Architect on #443.** Such a parameter stands for any type, as a generic does, so
V.12 binds it. `declared.nim` marks it as generic (`is_generic`), and `type` alone too, since Nim
reads it as the same type. `casing` gives a generic parameter the letter of a placeholder. A
parameter of `typedesc[I]` keeps the snake case of V.1, since `I` is its placeholder, as
`scalar*[I: Basis](t: typedesc[I])` shows. `STYLE.md` spells its borrow template with `T`.

**The letter is the only form of a generic parameter.** Snake case fails as any other form
does, so one file never spells two generic parameters two ways. Each project names such a
parameter with one capital, as in `timeKind(K: typedesc, …)`.

**No rename of case touches a generic parameter.** The letter is the initial of what the
parameter ranges over, which is a choice. So `renamesCase` gives none, as it gives none for a
placeholder. A name in another form, such as `kind` or `Kind`, is one finding of
`placeholder-letter`, and the hand renames it. A rename that spells out a coined abbreviation
(V.6) still reaches it, as it reaches every kind.

- Rejected: a kind of its own in `KindName`. Each reader of `KindName.Parameter` then has to
  learn it, such as the foreign mark, the notation of III.5 and the subject of each message. A
  flag on `Declared` reaches the casing alone.
- Cost: a reader of the kind alone sees a parameter, so `casing` and `isMiscased` read the flag
  beside it.
- Cost: both forms pass, so one file may spell two generic parameters two ways. Reading holds it
  until the rename.
- Cost: the scanner reads the type as the signature spells it, so an alias of `typedesc` is
  unread.
- Verified by `suites/test_names.nim` and `suites/test_declared.nim`.

**One function decides the reach of a binding.** The case of a binding marks its reach, and not
its mutability (V.1). So `reach` of `declared.nim` reads the blocks that enclose the binding:

- A routine makes it local.
- The entry block, which is a top-level `when isMainModule:`, makes it an entry binding.
- A binding that opens its own scope, such as `for` or `except … as`, is local.
- It is global where every enclosing block opens no scope. Those blocks are a `when` chain, and
  a bare `let`, `var`, `const` or `type`. Any other block makes it local.

**The entry block holds no binding (V.10), and that is the rule of the entry block alone.** Where
a module runs as a program, code that binds goes in `proc main`, and the block calls it. A binding
in the entry block reaches the whole module, because `when` opens no scope. A routine makes it a
true local in every language.

- By the ruling of the Architect, every binding in the entry block outside a routine is a
  finding, at any depth. The reason is that code that binds moves to `main`.
- So a `for`, an `except … as`, and a `let` inside a loop of the block are findings too.
- Rejected by the Architect: an exception that makes such a binding a local of its block.
- Each binding there is one finding of `entry-block`, which `checkBlockEntry` reports beside the
  fixer of the block, and its case is not judged. A block of plain calls passes, and so does a
  routine inside it.
- Rejected: a finding of the names check beside it. The rule would stand twice, under two names.
  Verified by `suites/test_entry.nim` and `suites/test_names.nim`.

**A boolean is a proposition or a mode (V.4).** A boolean binding, field or parameter opens
with `is`, `as`, `should`, `found` or `has`, and a word follows it. A `func` that returns `bool`
is a predicate, and its name opens with `is`. The Architect ruled on the routines that are no
predicate:

- A `proc` that returns `bool` reports the success of an action (V.3), so it is unread.
- A `func` that writes a `var` parameter and returns `bool` is an action too, so it is unread.
- `contains` keeps its name, because `in` and `notin` call it by that spelling.

- V.3 is held as the first word of a routine of two words or more: never `get`, `compute` or
  `new`. V.5 is held as `_by_` once in a name that opens with `lut` and has more words. V.10
  is held as a global SCREAMING name that equals a type name without case or underscores.
- Rejected: a parser, which costs a dependency and a compiler version. The scanner reads the
  line forms that this charter prescribes.
- A name that a template substitutes declares nothing of that name. So `type name = object`
  inside `template declareKind(name: untyped)` is no type, and the check reads its fields.
- A `static` parameter of a generic is a placeholder, so it takes one capital letter, as V.12
  says (`[N: static int]`).
- Rejected by the Architect: snake case for a `static` parameter, against the text of V.12.
- Rejected: a capital letter that passes every kind. It would pass `N` as a local, which the
  Architect ruled a finding.
- Cost: a declaration shape outside those forms is unread. Examples are a tuple type in
  brackets, and a name that `{.inject.}` makes.
- Cost: a boolean is read only where its declaration shows it, by the type `bool` or by the
  value `true` or `false`. A boolean that a call returns holds by reading.
- Cost: a Pascal name of capitals alone, such as `ANTI`, passes the case of a type. Reading holds
  it.

## Names and what they name

These rules hold the words of a name to the thing that it names. That thing is the kind of a
routine, the value of a binding, a generic type or the member of a collection. Each rule reads one
file, as the rules under Names do.

**Each verb of generation fixes the kind of its routine (V.3).** A `construct…` is a `func` or a
`proc` that runs at compile time and returns a value. A `define…` is a macro, and an `emit…`
is a `func` or a `proc` that returns `NimNode`, and never a macro. The Architect ruled that the
kind never fixes the verb. So a macro of another name, or a helper that builds a syntax tree under
another name, passes. The scanner reads the keyword of each routine, the type it returns before
its pragmas, and whether it runs at compile time.

- Compile time is read from the routine's own `{.compileTime.}`, as STYLE.md §2 applies it, or
  from the body around it. Only compile time runs the body of a macro, of a `static:` block or of
  a compile-time routine. A template body runs where it expands, so it marks nothing.
- Rejected: the pragma alone, which reports a helper nested in a macro, such as
  `constructLutKvector` of the PGA library.
- `NimNode` alone marks an `emit…`, since only a compile-time routine can return one. So an
  `emit…` needs no pragma.
- Verified by `suites/test_names.nim`, over every keyword, pragma, return type, verb and body
  around a routine. Verified by `suites/test_declared.nim` for the facts that the scanner reads.

**A name that holds a value in another representation leads with that value (V.2), by the
ruling of the Architect on #443.** V.2 asks that each cut of the last qualifier of a name still
describes the thing, but more generally. Where both orders pass the cut, the value that the code
names leads. A change of representation always passes both ways, since `a_flags =
a.basis.toFlags` holds `a`, and it holds flags. So the tie-breaker settles it, and syntax shows
it.

The check reads `$`, a `to<Target>` call (V.3) or a type conversion at the end of a chain of
steps from one root (`namesConverted`). A step is a field, or a call of one input. It stands by
dot or by prefix call, so `toFlags(dual(c))` reads as `c.dual.toFlags`. Where the name holds a
name of the chain after its head, and none at its head, the rule `representation-head` reports
it (`namesLater`).

**Each step keeps the root in another representation, by the ruling of the Architect on #608.**
The dual of `c` is `c` in the dual space. So `c_dual_flags = c.dual.toFlags` passes, and
`flags_c` is reported. A step can also make a new thing, as `m.grade` makes a grade, and syntax
cannot tell the two apart. So where a step follows the root, the finding lists each name of the
chain. Reading picks the name that passes the cut, as `grade_m_int` for `int_m =
m.grade.get.toInt`.

- Rejected: the last name of the chain alone. It reports `c_dual_flags`, which the ruling keeps.
- Rejected: a finding that names the root alone. For `point_camera =
  camera.rig.target.toMultivector`, it asks for `camera` first, though a target is no camera.
- A type that roots the chain is no value, so `Basis.scalarAnti.toFlags` holds `scalarAnti`
  alone.
- A property, a lookup, a second input and a compound are no change of a named value:
  `m.grade.get`, `dual[c].toFlags`, `toFlags(a, mask)` and `toFlags(a + b)`. An index and a call
  of a second input end a chain too: `c.dual[0].toFlags` and `camera.eye(0).toMultivector`. The
  cut holds by reading there, as it does for every other name.
- A wrong name of the chain at the head passes. `m_grade_int` leads with `m`, though a grade is
  no `m`, and reading holds it.
- The check renames nothing. A name with the value first can still need a reading: `is_moved =
  moved.toHashSet` would read `moved_is`.
- `declared.nim` keeps the value of each binding on its own line, with each line below it that
  opens `.`. It keeps its element where a tuple gives one to each name. A value that runs past
  its line otherwise is unread.
- Rejected: a check of the cut itself, since "still describes the thing" asks what a word means.
- Verified by `suites/test_names.nim` and `suites/test_declared.nim`.

**A routine never closes with `Of`, and keeps it only where its name spells a generic type (V.3,
V.13).** The Architect ruled this on #649. A property drops `Of` for the bare noun, a conversion
takes `to<Target>`, and an action takes its verb. A generic type can stand in another module,
and knoller reads one file. So the check reads the spelling from the words of the name alone. A
verb of V.3 that takes a type opens the name, and two words or more follow it, the last `Of`.

- The verbs are `to`, `init`, `emit`, `construct` and `define` (`VERBS_TYPE`). So
  `toMultivectorOf` passes, and `gradeOf` and `headOf` are findings.
- The finding is of `routine-suffix`, which cites V.3. The rule `action-verb` keeps the first word
  of a routine alone, so `newMeshOf` is one finding of each rule.
- The word `Of` is read without case, so `grade_of` is a finding too, beside its finding of case.
- `Of` inside a name, as in `basesOfGrade`, is unread.
- Rejected: an exemption where the same file declares the type that the words spell. A generic
  type and a routine that spells it can stand in two modules, and the check then reads no type.
- Cost: the check reads the verb, and never the type. So `toGradeOf`, which spells no type,
  passes, and reading holds it. A routine that spells a generic type after another verb, such as
  `sampleMultivectorOf`, is a finding.
- Verified by `suites/test_names.nim`, over each keyword of a routine, each first word, and none,
  one or two words between that word and `Of`.

**A type closes with `Of` only where an alias of its instance takes its bare name (V.13).** The
rule `generic-suffix` reports each other type that closes with `Of`, and cites V.13. The check
reads the alias in the same file, such as `Multivector = MultivectorOf[…]`. `declared.nim`
keeps the value of each type on its line. The head of the value of the alias is the generic type,
then `[`.

- So a proc type with no alias, such as `ProverOf`, is a finding. So is a generic with no alias,
  or with an alias of another name or of no instance. So is a generic whose bare name another type
  takes.
- Cost: an alias in another module of the project is unread, so its generic type is a finding. An
  alias that wraps past its line is unread too.
- Verified by `suites/test_names.nim` and `suites/test_declared.nim`.

**A collection type takes the plural of its member (V.6).** A word for its form closes the name
only where two collection types would share it. The rule `collection-name` reports a type whose
name is a type of the same file and a word for a form, and cites V.6. So `MeshSet` beside `Mesh`
is a finding, and V.6 gives it the name `Meshes`.

- The words for a form are `Set`, `Seq`, `Array` and `Table`, as V.6 lists them
  (`FORMS_COLLECTION`). A word outside that list, such as `List`, is unread.
- A plural before the word for its form passes, as `BasesSet` beside `Basis` does. V.6 asks for
  that name where two collection types would share one.
- A type that the file declares as a collection is no member, so a word for a form after it
  passes. The check reads that from the opening of its value, such as `set[` or `Table[`
  (`OPENINGS_COLLECTION`). So `BasesSet` beside `Bases = set[Basis]` passes, and `MeshSet` beside
  `Mesh = object` is a finding.
- Cost: the member is read only where the same file declares it, and only where the word for its
  form follows it at once. A member of another module, or a qualifier between them, passes.
- Cost: a collection whose value opens in another way reads as a member. An alias of another
  alias, such as `Bases = Grades`, is one, and so is `distinct set[Basis]`. A word for a form
  after it is a finding.
- Verified by `suites/test_names.nim`, for each word for a form.

**A name opens with its head where its words decide the order (V.2), by D1 a of #443.** V.2 cuts
the qualifiers of a name from its end, and each shorter name still names the thing. Most orders
need the meaning of the words, as `c_complement` does, so reading holds them, as it holds the cut
of `representation-head`. Three shapes need no meaning, so the rule `name-cut` reads them
(`cuts.nim`):

- A property follows a value of one letter, as `m_norm_bulk` and `𝐦_grade` do. The property
  leads, so the names become `norm_bulk_m` and `grade_𝐦`. The properties are `grade`, `norm`,
  `centroid`, `parity` and `order` (`PROPERTIES`).
- A word glued after `anti` is a word of the names of the package, as in `antibasis`. That word
  leads, so the name becomes `basis_anti`, as V.2 spells `scalarAnti`. The word holds three
  letters or more (`LENGTH_GLUED_MIN`), so a short word of the package, as a value of one letter,
  never reads as glued. The floor of 3 over 2 is a choice.
- An axis value opens the name, and a word that is no axis value follows it, as in `left_name`.
  The axis values go last, so the name becomes `name_left`.

**An axis value is a field of a wrapper that the package declares (V.7).** A wrapper is a generic
object of one placeholder and two fields or more (`axesDeclared`). Its name closes with `-al`, and
each of its fields takes that placeholder. One field names no axis, since an axis value names one
of several values. So `Chiral[T]` gives `left` and `right`. A name of axis values alone
passes, since its first value names the thing, as `bulkFlat` does.

- A word of a library that the package imports is no axis value, so the caller reads the modules
  of the package alone (`## Names of a package`).
- Rejected: the type word first, as in `FLOAT_WIDTH`, as a fourth shape. Each such name is a
  choice of design (D1 a of #443).
- Cost: the shapes read words, and never meaning. A word of one letter that names no value, or a
  property word that names another noun, reads as a shape too.

**The rename writes the new order at every use, through the semantic pass, as the case rename
does (`## Semantic pass`).** `renamesCut` writes the words in the case of the kind of the name,
and spells out each coined abbreviation (V.6). `composed` joins it with the case rename of the
same declaration, so one new name settles both rules, under the rule of the case. The rename
reaches a name in the notation of its source too, since no letter changes its case.

- `renamesCut` refuses the rename before the semantic pass where `renamesCase` refuses it, as for
  a name that foreign code reads. It also refuses a constant that a define gives, since the fix
  never renames a define (D1 a of #443).
- The planner refuses the rest. `antiscalar` becomes `scalar_anti`, which Nim reads as the
  template `scalarAnti`. So the finding stays for hand, and that binding needs a name for what it
  holds.
- Verified by `suites/test_cuts.nim`, and through the semantic pass by `suites/test_packages.nim`.
- Verified by the run of `## Names of a package`: the check reports 20 names of the library, 12
  properties, 4 glued `anti` and 4 axis values. The fix renames 17 of them over 24 lines, as the
  ruling counts. Of these lines, 20 are the diff of the page of rule 8, line for line. The renames
  of `m_order` and `c_order` give the other 4, since D1 a of #443 makes `order` a property.
- Line 617 of `pga/cayleys.nim` takes the prefix call of rule 15 too. The fix leaves the 3
  `antiscalar` with a warning each.
- In the projects of the repository at `ea44619d`, the check reports 1 name in `knoller`, 5 in
  `pga_benchmark`, 1 in `pga_visualiser` and 1 in `dance_ontology`. Each is a glued `anti`.

## Idioms

**Each idiom of STYLE.md and Article X.5 that one line shows is read on the code-only view.** So a
string or a comment never trips it, and a page template held in a string reads as text. The module
states each rule in its header, and the list here gives the reasons. `checkIdioms` reads each
idiom that the static pass of `curator/audit` reads.

- `strictFuncs` stands in its exact form before the first import, in every module.
- A bracket import is alphabetised in dictionary order (X.10), and the standard library comes
  before packages, then local modules. A bracket that spans lines is read whole.
- Two consecutive single bindings of one keyword share it, reported once for each run. A `let`
  beside a `var` passes, because they cannot share one keyword.
- A `{.used.}` carries a comment that names its consumer. A `{.push.}` stands only over foreign
  bindings, where a word of `MARKS_FOREIGN` stands among the pragmas of the block. `return
  result` never appears, because a bare `return` exits with `result`.
- Under `tests/` of a package, a suite that imports `std/random` seeds it, and a stub carries its
  testament header, without `-r`, `batchable` or `joinable`.
- No fixer reaches `{.used.}`, `{.push.}`, the seed, the header of a stub or debug output. Each
  needs knowledge that the text does not hold.

**A module takes every idiom, and a script or a package takes those of any Nim code.** Bindings,
pragmas, `return result` and the rules of a test read any Nim code, so `.nims` and `.nimble` take
them, checks and fixers both. `strictFuncs`, import order and the keys and header of a stub stay
with a module. STYLE.md §2 asks `strictFuncs` of a module, koch runs testament over
`tests/t*.nim`, and a script keeps its imports as written.

- Rejected: the idioms on a module alone, which leave a script and a package unread.
- Verified by run, 2026-10-06: the wider check reports nothing on the tree.
- Cost: the imports of a script stay unordered.
- Verified by `suites/test_chain.nim`: each dialect reports and fixes the idioms of any Nim code,
  and `strictFuncs` reads in a module alone.

**Debug output is told from a report by its shape alone.** An `echo` in a test that prints a
value with no label, outside a condition, is the shape that debug output takes. A labelled
`echo` passes as the report of a measured figure, and one under a condition passes as a failure
diagnostic.

- Rejected: every `echo` in a test, which reports a deliberate measurement as debug output.
- Cost: labelled debug output passes, and reading holds it. A seeded `initRand` passes as
  `randomize(0)` does, because both fix the sequence.
- Verified by `suites/test_idioms.nim`, each rule by its breach and by its form.

**Other debug output warns, and fails no check (VIII.5).** The Architect ruled so on rule 19 of
#443. A fix would change what the code prints, so knoller fixes none (`warnDebug`). The warning
fails no check, as the warning of a fence does. The command line and the audit print each
warning beside those of fences.

- A build-time printer warns in any file: `expandMacros`, `dumpTree`, `dumpAstGen` and
  `dumpLisp`. So do an echo of a syntax tree, as `echo n.treeRepr`, and `debugEcho`.
- An `echo` at the top level of a library module warns, since it prints on each import. A
  library module lies outside `tests` and `tools` of its package. A module with an entry block,
  or one that quits at its top level, is a program, which no import runs.
- A commented-out print is no code, and passes.
- Verified by `suites/test_debugs.nim`, which quotes the build-time printer of
  `pga/multivectors.nim` at `3d9696e`, and by `suites/test_fixes.nim` of `curator/audit`. Each
  printer warns in a module, a test, a script and a nimble file. A module that breaks no other
  rule exits clean with its warning. A fix writes none of it, and the fix of the audit leaves no
  finding.
- Verified by hand with knoller at `44b16354` on the PGA library at `3d9696e`, 2026-11-20. A driver
  imports `knoller` and runs `warnDebug` alone on each file that
  `git ls-files '*.nim' '*.nims' '*.nimble'` lists, with a nimble file at the root of the
  library. It gives 1 warning, at line 83 of `pga/multivectors.nim`, as the ruling counts.
- Verified by hand with that driver over the repository at `44b16354`, 2026-11-20. It gives no
  warning. The one top-level `echo` of `pga_benchmark` stands in a program that quits.
- Cost: an echo inside a routine passes, since the text cannot tell output from debug output.
  An echo of a tree by `repr` there passes too, since `repr` prints any value.

## Skips

**Each gap of coverage shows in the run (IX.9).** The Architect ruled so on rule 17 of #443, and
ruled that no fix writes a reason. A skip gives its reason after it on its line, as STYLE.md §6
writes it. The reason may also stand on the comment line right above the skip, at its indent. It
may stand in an echo of text there too, which the run prints. Each report stays for hand, since
no text gives the reason (`checkSkips`).

- The check reads each file under `tests` of its package. The static pass of `koch check` does
  not read its reports yet. Knoller's command line and the warnings of fences read them, as they
  read each check of the chain.
- A skip that is the whole body of a branch may give its reason right above the head of that
  branch. This is knoller's reading, and the ruling does not name it. On one line, as
  `when IS_CONFORMAL: skip()`, the reason above the head is the reason above the skip, and two
  lines read alike. Its cases are lines 120 to 122 and 219 to 221 of
  `tests/suites/test_picking.nim` of `pga_visualiser`, which pass.
- A placeholder test, whose code is `skip()` alone, gives its reason in a name that opens with
  `TODO:`.
- A comment that opens with `TODO` inside a test that runs names a gap that the run never shows,
  so it reports. A comment that gives the reason of a skip is no gap. A test whose body skips at
  its own level shows in the run as skipped, so it holds no gap.
- A test under a `when` with no other branch leaves the run where its condition is false, so it
  reports, once for each test. `when isMainModule:` names no configuration.
- A gate around a whole suite configures the suite, and skips no test in it, so a test under it
  passes (D3 a of #980). The read of the gates above a test ends at its suite. So a gate inside
  the suite reports, and so does a gate above a test with no suite between them.
- A test under `quote do:` is generated code, and so is a skip under it. So neither reports.
- Verified by `suites/test_skips.nim`. Its cases quote `tests/suites.nim` of the PGA library at
  `3d9696e`, and each case names its cut. Its cases of a gate around a suite and of a gate inside
  one quote `tests/suites/test_arenas_frame.nim` and `tests/suites/test_share.nim` of
  `pga_visualiser` at `16a573cc`.
- Verified by hand with knoller at `44b16354` on the PGA library at `3d9696e`, 2026-11-20. A driver
  imports `knoller` and runs `checkSkips` alone on each file that
  `git ls-files '*.nim' '*.nims' '*.nimble'` lists, with a nimble file at the root of the
  library. It gives 8 reports, as the ruling counts. They are lines 288, 308, 331, 346, 358, 371,
  380 and 432 of `tests/suites.nim`. Knoller at `1bed07fd` gives the same 8, verified by hand on
  a copy of the library at `3d9696e`, 2026-11-21.
- Verified by hand with that driver over the projects of the repository at `16a573cc`,
  2026-11-21. It reads each project by `git ls-files`, with the nimble file of the project.
  Knoller at `fd3bc4b5` gives 44 reports, each a test of `pga_visualiser` under a bare gate.
  Knoller at `1bed07fd` gives 17, each a test under a gate inside a suite. They are 14 in
  `tests/suites/test_scene.nim` and 3 in `tests/suites/test_share.nim`.
- The 27 that pass stand under a gate around a whole suite. They are 19 in `test_orrery.nim`, 4 in
  `test_arenas_frame.nim` and 4 in `test_image.nim`, under `tests/suites`.
- The ruling of rule 17 counts 17 places in `pga_visualiser`. Of them, 16 are a test under a
  gate, and 1 is a skip. That skip gives its reason above the head of its branch, so it passes
  here. So knoller reports one test more than the ruling counts. The cause of the difference is
  unmeasured (`## Open questions`).
- Cost: knoller reads the lines with a scanner, and never with a parser. A test reads from a line
  that opens with `test` and ends in `:`, and a line at its indent or shallower ends it. So a
  test on one line, as `test "a": skip()`, and a head as `test("a"):` are unread. A line of a
  string at column 0 inside a test ends its body there. A suite reads alike from a line that
  opens with `suite`, so a gate around `suite("a"):` reports each test under it.
- Cost: any comment right above a skip reads as its reason, a commented-out line of code too.

## Staging

**A routine that compile time alone runs is a member of the compile-time family, and each member
carries its own `compileTime` (STYLE.md §2).** `checkFamilies` reads the members of one module. A
member is one of these routines:

- A routine whose pragmas hold `compileTime`, or that nests in a macro, a `static:` block or a
  compile-time routine. `is_compile_time` of `declared.nim` reads it so, as `action-verb` does,
  in the same walk that reads the head of each routine (`heads`).
- A private routine whose every use lies in a member, a macro, a `static:` block or the value of
  a `const`. That is the incidental const evaluation of STYLE.md §2. The greatest such set holds,
  so two members that call each other stay members.

The rule reads the uses and the module so:

- A use of a routine is a mention of its name outside its own block. An operator has no name
  that a use spells. So the rule reads its uses by the mentions of the type of its first
  parameter. A mention in a `type` section, an iterator or a template defines that type, and is
  no use. Such code runs where it is used. So `==` on `Order` of `pga/cayleys.nim` is a member.
- The body of `quote` or `genAst` is code that a macro emits. A use there is a runtime use, and a
  routine that it declares is no member, though it nests in a macro.
- The family is staged where one routine of the module carries its own `compileTime`. A module
  where no routine carries it passes, as `pga/multivectors.nim` does.
- An iterator and a template pass, since Nim refuses `compileTime` on both. A macro runs by its
  keyword, and carries no pragma for it.
- Rejected: a family of the whole project, which reports a helper of one macro in a module that
  stages nothing else (rule 10 of #443).
- Rejected: a nested routine under the pragma of its parent, since STYLE.md §2 asks the family
  to carry the pragma "the same way".
- Cost: a field, a binding or a parameter that spells the name of a routine reads as a use. So
  it keeps the routine out of the family. That gives fewer findings, never a false one.
- Cost: a runtime use of an operator through a field, as `w.o == w.o`, names no type of it. So the
  operator reads as a member, and the fix stages a routine that runtime calls. The build fails.
- Cost: two private routines that call each other, with no use outside the pair, read as members.
  So the fix stages code that no build runs.
- Verified by `suites/test_staging.nim`, which pins each cost above.

**A member of a staged family carries no runtime pragma.** The runtime pragmas are `inline`,
`noinit`, `noinline` and `codegenDecl`. Each acts on generated code alone, and the compiler
generates no code for a compile-time routine (the Nim manual, the `compileTime` pragma). So each of
them is superstition there.

- Cost: a module that stages nothing passes. So a routine that nests in its macro or its `static:`
  block keeps its runtime pragma.

**The fix writes on the line that the pragmas stand on, else on the line that closes the
parameters (`Head.last`).** It drops each runtime pragma, and puts `compileTime` among the bare
pragmas in dictionary order, before the pragmas that take an argument (X.10). So `{.borrow.}`
becomes `{.borrow, compileTime.}`. Where the line holds no pragma block, the fix opens
`{.compileTime.}` before the `=` of the body.

- The fix widens its line, so it is a widener (`## Wraps`). Off a held line it writes freely, and
  the wrapping after it lays the line out.
- The chain runs it after the idioms and before the wrapping, on a module alone. A script and a
  nimble file run in the VM alone, so no pragma there acts on generated code.
- Cost: a pragma block that spans lines is unread, so its routine stays for hand.
- Verified by `suites/test_staging.nim`. Verified by `suites/test_regressions.nim`: each snippet of
  the library with `noinit` on a compile-time routine loses it in the output of the chain.
- Verified by hand with Nim 2.4.0, 2026-11-20. An iterator or a template with the pragma gives
  `invalid pragma: compileTime`. A `when` on a static parameter in a macro gives `cannot evaluate
  at compile time`.

**A branch on what the build fixes is `when`, and never `if` (STYLE.md §3).** `checkBranches`
reports an `if` where its condition, and each `elif` of its chain, read only these:

- literals and operators, and the type after `is` or `isnot`;
- each name that a `const` binds at module level in the file;
- each local `const` above the branch in its routine;
- each constant that another module of the package exports;
- static and typedesc parameters, and placeholders, of each routine around the branch;
- `defined`, `declared`, `compileOption`, `compiles` and `sizeof`, whatever their argument;
- `len`, `high`, `low`, `ord` and `card` of a static value.

Any other name or call reads as runtime, so its chain passes.

- A runtime parameter, a loop variable, and a `let` or `var` shadow a constant of the same name,
  so that name reads as runtime. A `let` or `var` shadows from above the branch in its routine,
  or from module level.
- An `if` in the value of a `const`, a macro, a `static:` block or a compile-time routine passes,
  since it is no runtime branch. Nim 2.4.0 cannot evaluate a static parameter of a macro in
  `when`, so `if not as_unary` of `pga/operators.nim` stays.
- The fix writes `when` for `if`, and keeps each `elif` and `else`. A statement whose branch
  declares a name stays for hand, since `when` opens no scope (STYLE.md §1). A fix that widens a
  narrow line past `LINE_MAX` stays for hand too.
- Rejected: a constant read from the case of its name. A global `let` or `var` takes that case
  too, as `IS_TALLYING` of `pga_visualiser` does, and the build fixes neither.
- Cost: a constant of a package that the run does not read, such as the library that a project
  imports, reads as runtime. So `if IS_CONFORMAL` of `pga_benchmark` passes. A missing constant
  adds no false report.
- Cost: a constant counts in each file of its package, whether the file imports its module or
  not. So a runtime name of the same spelling that a dependency gives reads as fixed by the build.
  The fix then writes a `when` that the build refuses.
- Cost: a condition that spans lines is unread.
- Verified by `suites/test_staging.nim`.

**The caller gives the constants that the other modules of the package export.** The rule reads
one file, as each rule of knoller does. So the caller reads the constants of each module
(`constantsExported`), and passes them in (`constants`). A step of the kind `Reading` takes them,
as a placed step takes the nimble file (`## Layout of a package`).

- The command line reads them from each module of the run, by the nimble file of its package
  (`constantsPackage`).
- The audit reads them from each `.nim` file of the tree, by the nimble file of its project
  (`initContext` of `fixes.nim`). The fix and the fence warning of each entry take those of its
  project.
- Verified by `suites/test_staging.nim`, over two modules of one package and one module alone, and
  by `suites/test_fixes.nim` of `curator/audit`, over two modules of one project.

**Verified by run, 2026-11-20, on the PGA library at `3d9696e`, with a nimble file at its root.**
A driver ran `checkFamilies` and `fixFamilies`, then `checkBranches` and `fixBranches`, each
alone, on a copy of the library, with the code of knoller at `8088d980`. `knoller --check` lists
the same lines.

- Compile-time family: 21 reports over 21 lines, and the fix writes +21 −21 lines. That is the
  diff of the page of rule 10, line for line. The check finds nothing on the fixed copy.
- Branch on what the build fixes: 3 reports over 3 lines of `tests/suites.nim`, and the fix
  writes +3 −3 lines. The check finds nothing on the fixed copy.
- Each fixed copy builds with Nim 2.4.0 and passes its suites. rga3d gives 33 OK, 0 failed and
  5 skipped, and cga3d gives 28 OK, 0 failed and 10 skipped. For the branch, rga4d, where
  `DIMENSIONS != 3` holds, gives 33 OK, 0 failed and 5 skipped.
- The driver read each project of the repository at `8088d980` as one package, by `git ls-files`
  of its `.nim` files. The projects take 18 reports of the family: `ricysoho` 14,
  `dance_ontology` 3 and `pga_benchmark` 1. They take 3 reports of the branch: `pga_benchmark` 2
  and `pga_visualiser` 1.

## Names of a package

**A rule of one file that needs the names of its package takes them from the caller
(`NamesPackage`).** Rule 8 of #443 reads the axis values and the words of the names of the
package. Rule 9 reads the aliases of the package and of its library, and rule 15 reads the calls
of each constructor. Each rule reads one file, as each rule of knoller does. So the caller reads
the package, as it reads the constants of the staging rules (`## Staging`).

- `namesPackage` reads the names from the modules of the package, and the aliases from the modules
  of its library too.
- `checkFormatting`, `checkSource` and `checkFenceHeld` take the names (`names`). Empty names
  report none, so a caller that passes none keeps these rules silent.
- The command line reads the names from the modules of the run, by the nimble file of their
  package (`namesByPackage`). The files with no nimble file above read as one package. So the
  PGA library, which holds no nimble file, reads whole where the run names its root.
- It reads the library of each package from each directory that the `nim.cfg` beside its nimble
  file adds to the search path (`modulesLibrary`). A path that holds a variable, or names no
  directory, reads none, as a library that no lock restored does.
- It writes the alias of each landmark before the chain, beside the renames and the type
  conversions. It plans each cut rename with the case rename of its declaration (`composed`).
- Cost: where the planner refuses a composed rename, its case part goes too (`composed` of
  `cuts.nim`). So a name that breaks both rules keeps the case of another kind, and its warning
  says why. Verified by `suites/test_packages.nim`.
- `koch fix` passes the names of each project too, through `namesPackage` (`## Content fixes` of
  the record of `curator/audit`). So it writes the name cut and the landmark alias, and leaves each
  constructor call for hand. The static pass of `koch check` reads none of these rules until step 4
  of #443.
- Cost: a run that names some files of a package reads the names of those files alone. Run
  knoller on `.` at the root of a project to read them all.
- Verified by `suites/test_packages.nim`, on modules of two packages in one run, and on a library
  under `nim.cfg` in a fresh tree. It holds that the check of the chain and the warning of a
  fence read the names, so what the fix leaves reports.

**Verified by run, 2026-11-20, on the PGA library at `3d9696e`.** A copy of the library stood in
the index of a fresh git repository, with no commit and no nimble file. `knoller --check .` and
`knoller .` ran at its root with the code of `ea44619d` and Nim 2.4.0. A driver counted each check
on the library as given. It counted each project of the repository at `ea44619d` too, from the
`.nim` files that git lists there. The PGA projects took the copy of the library as their library.

- A diff against the copy that knoller of `0cc02bf4` fixes holds the lines of rules 8, 9 and 15
  alone. The type conversion of a global gives one line more, against knoller of `d018a6c0`.
- On the fixed copy, these rules find nothing more to fix. They leave the 3 `antiscalar` and the
  2 calls of `initElement` for hand, and `knoller --check` gives `0 to fix`.
- The fixed copy builds with Nim 2.4.0 and passes its suites. rga3d gives 33 OK, 0 failed and 5
  skipped, and cga3d gives 28 OK, 0 failed and 10 skipped.
- The driver gives the same counts on the projects at `3a6cf5e9`. At `c8a7a413`, it gives the
  counts of the page of #443 for rules 9 and 15. Rule 15 takes 42 reports there, and rule 9
  takes 3. That tree holds the call that the page cites at line 810 of `test_camera.nim`, and
  the trees above hold it at line 860.
- For rule 8, the driver gives 4 in `pga_benchmark` at `c8a7a413`, where the page gives 8. The
  cause is unmeasured.

## Landmarks

**A landmark index that a conversion writes bare becomes the alias of its type (V.8), by D1 a of
#443.** `landmarks.nim` reads each alias: a template or a routine at module level whose one
parameter is `typedesc[T]`, which returns `T`, and whose body is one expression. It reads the body
for each type that `T` stands for. So `Grade(1)` becomes `Grade.vector`, and `GradeAnti(1)`
becomes `GradeAnti.vectorAnti`.

- The body takes its branch of `when` on the type, as `when G is GradeAnti`, and reads another
  alias through, as `I.low`. It reads through 8 aliases at most (`DEPTH_MAX`), so a cycle of
  aliases ends. The bound is a choice, and the depth that the library needs is unmeasured.
  Verified by `suites/test_landmarks.nim`, through two aliases that name each other.
- An index is a constant: a literal, a name, or arithmetic of them (`CHARS_INDEX`). So `sample`
  of `pga_benchmark`, whose body converts `rand(-1.0..1.0)`, names no index.
- An alias that branches on the configuration names no index, as `origin` does. An alias under
  `when` exists in one configuration alone, as `infinity` does, so the fix never writes it.
- The bare form is a conversion `T(…)` whose argument, spaces aside, is the index of an alias of
  `T`. The body of the alias itself passes.
- Where two aliases name one index, the fix writes `low` or `high`, so `Grade(0)` becomes
  `Grade.low`. The Architect ruled so in D1 a of #443. By `git grep`, the library at `3d9696e`
  names these two indexes of `Grade` in 21 places, and 20 of them write `low` or `high`. V.8 cites
  `Grade.high`. Any other choice stays for hand.
- The edits apply before the chain, on the source as given, as the type conversions do. An edit on
  a fenced line or on a span that another edit writes stays for hand. So does one that would widen
  a narrow line past `LINE_MAX`.
- Rejected: `Basis.low` and `Basis.high` as indexes. Both are builtin, and `ord(Basis.high) + 1`
  counts the bases in other projects.
- Cost: where no alias names an index, as for `Basis.scalar.succ`, the rule is silent. A new
  alias is a choice of design.
- Cost: the fix reads no import. A module that sees the type and not its alias would fail to
  build, and the build of the fixed tree reads it.
- Verified by `suites/test_landmarks.nim` and `suites/test_regressions.nim`.
- Verified by the run of `## Names of a package`: the aliases of the library name 9 indexes. The
  check reports 7 bare indexes over 5 lines of `tests/suites.nim`. The fix writes each alias over
  +5 −5 lines, the diff of the page of rule 9, line for line.
- In the projects of the repository at `ea44619d`, the check reports 2 in `pga_benchmark` and 1 in
  `pga_visualiser`. Verified by hand with knoller at `ea44619d`, 2026-11-20, on a copy of
  `pga_visualiser`. Its library stood at the path that its `nim.cfg` names, and the fix wrote
  `Grade.low` for `Grade(0)` at `objects.nim:139`.

## Conversion prefix

**A `to<Target>` call by dot on a compound argument becomes a prefix call (STYLE.md §5), by D1 a
of #443.** A compound argument is a group in parentheses that holds an expression with an
operator. The call takes the parentheses of the group, so `(not b.toFlags and mask).toBasis`
becomes `toBasis(not b.toFlags and mask)` (`prefixes.nim`). A group of one plain operand, or of
one literal, is no compound, and a tuple is no group.

- The fixer runs in the chain before the needless parentheses, so `^((|𝐦).toMultivector)`
  becomes `^toMultivector(|𝐦)` in one run.
- It is the reverse of `to<Target>` subject first, which leaves a compound argument as a prefix
  call. So neither fixer undoes the other.
- The fixer takes 8 passes at most (`PASSES_MAX`). Each pass writes the calls whose spans hold no
  other call, so the inner call goes first. So one call of the fixer leaves the outer call of a
  nest of 9. The bound is a choice, and the depth of the nests in the library is unmeasured.
- The chain calls the fixer again in each of its rounds (`ROUNDS_MAX`), so one run of knoller
  settles a nest of 16. A deeper nest leaves its file as written, with the warning that it still
  changes. Verified by hand on the chain, 2026-11-20, with nests of 8, 9, 16 and 17.
- A generic call and a call over lines report, and stay for hand.
- Verified by `suites/test_prefixes.nim` and `suites/test_regressions.nim`.

**A dotted type conversion of a global becomes `T(x)`.** A global is in `SCREAMING_SNAKE_CASE`
(V.1), so it is a value, and never a type or a module. So a receiver that ends on a global of two
characters or more stays a candidate of `type-conversion`, and the semantic pass settles it. One
capital is a placeholder (V.12), and asks nothing.

- `checkConversions` passes over the conversion of a global until the static pass reads the rule
  (step 4 of #443). So `knoller` and `koch fix` write it, and `koch check` reports it in no
  project. Cost: until then, the check and the fix disagree for a global.
- Verified by `suites/test_conversions.nim`.

**A constructor that the package calls both ways reports for hand.** A constructor is an `init…`
routine that the package declares (V.3). A call takes the dot on a plain receiver, or a prefix
call on a plain first argument (`constructors.nim`). The check reports each call of the form that
fewer calls across the package take, or of both forms where they tie. No fix writes a form, since
text cannot tell whether the first argument is the subject (D1 a of #443).

- A prefix call whose first argument is compound takes neither form, since the dot cannot take it
  without parentheses. A generic call, a command call and a prefix call of no argument take
  neither form too.
- Rejected: a reading of the call forms of every routine (D1 a of #443). On the page of #443, it
  adds calls of `len`, `countSetBits` and `abs` in the library, which the library borrows or
  overloads.
- Verified by `suites/test_constructors.nim`.
- Verified by the run of `## Names of a package`: the library takes 5 reports, as the ruling
  counts. The check of compound arguments and constructors gives 4 of them. The fix writes the 2
  compound arguments and, through the type conversion, the global of `pga/algebra.nim:88`, over
  +3 −3 lines. It leaves the 2 calls of `initElement` for hand, beside 4 dotted calls.
- In the projects of the repository at `ea44619d`, the check of compound arguments and
  constructors reports 4 in `knoller` and 2 in `audit`. It reports 18 in `pga_benchmark`, 23 in
  `pga_visualiser`, 12 in `dance_ontology`, 6 in `rictadni` and 5 in `ricysoho`. The conversions
  of globals there are unmeasured.

## Fixed waits

**A fixed wait in drive code is a finding, and the caller decides which file is drive code.** The
names are `sleep` and `sleepAsync` of Nim, and `waitForTimeout` of Playwright, each with what
replaces it (`checkWaits`). The rule comes from IX.12 alone, so knoller holds the names. The
paths of drive code are a habit of one repository, so the caller gives them, and knoller holds
none.

- The chain reads fixed waits where its caller says the file is drive code (`is_drive`). It reads
  them in the checks of the source and in the fence warning. `curator/audit` says so of `tests/`
  and `tools/` of each project. The command line says so of no file.
- Nim names compare as the compiler compares them (`identity`), so `sleep_async` is `sleepAsync`.
  Nim source is read with comments and strings blanked.
- A caller that reads another kind passes the identifiers of each line, less those of its
  comments. Only the name of Playwright reads there, exactly, since `sleep` of TypeScript is the
  helper of a drive.
- Cost: `knoller --check` alone reports no fixed wait. A repository that wants the rule runs
  knoller through a caller that names its drive code, as `koch` does.
- Verified by `suites/test_waits.nim`. Verified by `suites/test_chain.nim`: the word of the caller
  reads at any path, and no path reads without it. Verified by `suites/test_command.nim`: a fixed
  wait under `tests`, `tools` and `src/tools` passes the command line.

## Platforms

**Runners hold knoller on Linux and on Windows, and koch on Linux alone.** The Architect runs
knoller on Windows, with Nim built from source on `PATH`. So `test-windows` of `check.yml` runs the
suites of knoller on Windows, whenever a change names knoller. No runner holds macOS, so knoller
there is unverified.

- Verified on the runner, 2026-10-08: every suite of knoller passes on Windows. That includes the
  semantic pass through `cmd`, the real compiler, and checkouts under the global
  `core.autocrlf=true` of the runner.

- The command line compiles for Windows, which `nim c --os:windows --compileOnly` shows on any
  host. Before this, knoller compiled for no Windows target.
- Trap: the runner of the suites finds them by a walk at compile time, and that walk finds none
  for another target. So a cross-compile of the runner proves nothing, and a file that imports
  each suite by name stands in for it.
- Three tests skip on Windows, and each says why. `sha256sum` is no tool of Windows, and the stub
  toolchain of two tests is a `sh` script. So a pin served from the cache, and its prover, are
  proven on POSIX alone.
- Cost: paths compare by case on Windows too, where the file system ignores case.

## Open questions

- Why does rule 11 make 49 routines a `func` where the ruling counts 22? `pga_visualiser` takes
  33 against 16, and `dance_ontology` 13 against 6.
- Why does rule 17 report one test more in `pga_visualiser` than the ruling counts?
- Nimble 0.26.2, which 2.4.0 ships, is not verified with the `?subdir=curator/knoller` form of a
  git URL. Its check needs the package list of nimble, which the proxy of the machine of a
  delegate refuses with status 405. Atlas reads the form through an override (`## Package`).
