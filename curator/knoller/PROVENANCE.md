# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-04 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | aeb6bb8eae706e64 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a curator project, from the brief of the Architect. It holds the fixers of `koch fix`
that read the text of one file and nothing else, and the compiler that serves each pin. It holds
the checks of one Nim file too, which the static pass of `curator/audit` calls. The fixers that ask
the compiler stay in `curator/audit`. There is no vendored source.

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

**Each build of knoller fails on an unused import.** `nim.cfg` at the root of the package makes
the warning `UnusedImport` an error. The compiler reads `nim.cfg` in each directory above its
project file. So the flag reaches the suite that testament runs, one suite that runs alone, and the
command line built from the root of the repository.

- Rejected: the flag in the `cmd` of the stub. It reaches the build that testament runs, and no
  other.
- Verified by hand, 2026-10-06, with Nim 2.2.12. An unread import in a module of `src/` fails
  `nim c` of `tests/test_suites.nim`, of one suite alone that imports the module, and of
  `src/knoller.nim`. An unread import in a suite fails `nim c` of the stub and of that suite.
  Through `koch test`, testament reads the flag too.
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
- Verified by `suites/test_rules.nim`. The messages of `checkBlanks`, `checkDefaults` and `heldOf`
  hold no article. No string literal under `src/` holds `§`, or `(` before a Roman numeral and a
  dot.
- Rejected: the article written into each message. `CITATIONS` would then stand twice, and each
  message would cite the charter of this repository wherever knoller runs.
- Cost: no suite of knoller holds the text that `koch` prints. The suite `test_findings.nim` of
  `curator/audit` holds it, article included, through the real check of each message that `koch`
  prints.

## Chain

**One chain runs every fixer in one order until the source settles.** `formatted` reads the
fence, masks it, runs the fixers of the dialect, and writes the fenced lines back.
`checkFormatting` reports each rule that the fixers clear, on the same masked view. A dialect is a
module (`.nim`), a script (`.nims`) or a package (`.nimble`). A module takes every idiom fixer and
check, and a script or a package takes those of any Nim code (`## Idioms`).

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
- `outcomeOf` decides what a run writes and prints from text alone, so its suite needs no file.
  Verified by `suites/test_command.nim`. The suite also holds the README to every rule id.
- A directory that gives no Nim file is a usage error, and its message says why. The directory
  is outside a git work tree, or git lists no Nim file under it. A silent `0 to fix.` reads as a
  clean run over files that knoller never read.
- Each fixer reads the path whole: absolute, with `.` and `..` resolved (`layoutOf`). So the
  test file, the stub and the umbrella read alike from any directory, and the output prints the
  path as named.
- That path is `/` separated on every platform. A path join on Windows writes a backslash, so
  `layoutOf` and the listing of a directory write each separator `/` (`slashed`). Each path
  relative to a project reads with `/` too. So a rule finds `tests` on Windows as it does on
  Linux, and one tree prints the same output on every platform.
- Fixers read the text as a commit stores it. Git for Windows checks out CRLF by default, and a
  commit turns it back into LF. Where `git ls-files --eol` reports such a checkout, knoller reads
  LF and writes CRLF back (`isConverted`). So no CR reads as trailing whitespace, and no fix
  rewrites line endings. CRLF that a commit keeps stays a finding.
- Verified by `suites/test_command.nim`, on a real checkout with `core.autocrlf=true`. The suite
  also holds each setting and attribute that decides the conversion. A demo checkout gave 3
  findings, where it gave 7 before. Cost: one git call in each directory of the files named.
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
by hand on the `ronri` projects take their commit pin with no option.

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
  commit in minutes, once. A fetched release takes about 140 MB, and a built commit about
  2.4 GB, measured below. Nothing prunes them.
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

**The command takes the commit pin of `pga_benchmark` with no option.** Verified by hand,
2026-10-05, with the binary built at `db2f90a`. It ran on a copy of `pga_benchmark` in a new git
repository, with a private cache.

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

- The caller names three facts for each file it asks: the directory the run starts in, the file
  that includes it, and the toolchain. The command line reads them from disk. The run starts in
  the nearest directory that holds a nimble file, and the includer is read among the Nim files git
  lists there. The toolchain is the one that proves parentheses (`batchesOf`). `koch` reads the
  same facts from its tree instead.
- One `nimsuggest --v3 --tester` serves each entry: the file itself, or the file that includes it.
  It runs in the project directory, so the `nim.cfg` of the project applies. A file under
  `tests/` takes `-d:testing`, as the stub of STYLE.md §6 does.
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
  compiler. Knoller would also bind to one pin, and the `ronri` projects lex glyphs that only
  their commit pin knows.
- Rejected: `nim check --def` for each site, which compiles the project once for each site.
  `nimsuggest` ships with each toolchain that knoller serves, so the pass costs no build.
- Cost, measured 2026-10-02 on the container of the curator: about 2 s for each entry of a
  curator module. A front-end or a suite of `rga_visualiser` takes 5 to 9 s. Only a file with a
  candidate asks.
- A site of an included file asks `dus`, whose answer opens on the same definition as `def`.
  Verified by `suites/test_symbols.nim`, which resolves a use of an included file to its `let`.
- On the commit pin, `def` in an included file recompiles the file that includes it for each
  site, and `dus` recompiles only what is dirty. Read in `executeNoHooksV3` of `nimsuggest.nim`
  at that pin. Measured on the container of the curator, 2026-10-04, over 20 sites of the shared
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
  the pass to the few files that hold a candidate.
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
  `suites/test_rewrites.nim`, and by hand with the `nimsuggest` of the commit pin, 2026-10-04:
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
  rename that would compile can be refused. Inferred from `sitesOf`, which reads every name token.
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

- The cases come from the PGA library at `d9be8ae`, from `dance_ontology` (#539), from
  `rga_visualiser` (#521), and from the rulings of #533, #526 and #443.
- A case keeps its domain test in the suite of its rule, which holds the rule over many inputs.
  The regression suite holds that the case as found is fixed. Neither one alone holds both.
- A case that 2.2.12 reads rightly asks the parser of 2.2.12, which builds the suite. A case with
  the glyph operators of the commit pin asks the stub (`suites/stubs.nim`), since the job of
  knoller runs 2.2.12 alone. The stub gave the verdict of the commit pin on each such case,
  verified by hand, 2026-10-05.
- The case of `test_mesh.nim` (#521) leaves no finding under the present rules, because spacing
  now fixes `)*radius`. So it holds that each report on its lines prints at its line as given.
  `suites/test_command.nim` holds a finding left at its line as given.
- The case of the stub `tests/rga3d/test_rga3d.nim` (#443) depends on its path. So it runs
  through `outcomeOf`, as the command line runs it, at that path and at `tests/test_rga3d.nim`.
  Verified by hand, 2026-10-08: it fails at the parent of the commit that builds the ruling.
- Verified by hand, 2026-10-05: the suite ran against the parent of the commit that fixed each
  case, with a shim that proves nothing. Each case that a commit fixed failed at its parent. A
  case that holds a bound of its rule, such as `[1 .. ^1]`, passed there.
- Cost: the suite asks the compiler for each case with candidates, about 6 s in all.

## Tokens

**`tokens.nim` keeps the rules of the lexer of the compiler.** A run of operator characters is one
operator. A `-` before a digit opens a number after a space or an opening bracket.

- The glyphs are those of the commit pin of the `ronri` projects. It adds `☆ ⟑ ⟇ ⩓ ⩔ ■ □` to the
  glyphs of 2.2.12, and no project on 2.2.12 spells them in code.
- Verified by `suites/test_tokens.nim`. Verified by hand over the tree, 2026-10-02: each byte of
  each Nim file outside whitespace lies in one token, and each bracket finds its partner.

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
that the hand gave it stay, its arguments on one line of their own among them (`linesHand`). Only
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

- A test file has a directory `tests` in its path, at any depth. `reports.nim` holds this reading
  and the reading of a stub, from the names below the last directory `tests`. So the blank-line
  rule and the stub rules read one definition.
- `isFileTest` holds exactly where `/tests/` stands in the path with a `/` before it. Verified by
  `suites/test_blanks.nim`, which holds both readings to a table of paths. Verified by hand,
  2026-10-04, over each path that git lists in this repository, relative and absolute.

**Knoller reads a stub as testament reads a category (#443).** A testament category is a folder
directly under `tests`. Its tests are the files `t*.nim` at any depth inside it, as `isTestFile`
and `processCategory` of `testament/categories.nim` read them. Such a file is a stub where a
testament header opens it, that is, where the file opens with `discard """`. A file there that
opens with no header is a suite module, and no rule of a stub reads it. A file `tests/test_*.nim`
is a stub with or without a header, so a missing header there stays a `stub-header` finding.

- `isStub` takes the source beside the path, since the header decides. Each caller holds the
  source already: `keysStub`, `checkTests` and `profilerOf` of `idioms.nim`.
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
  `a ^ (-b)` settles on `a^(-b)` in one round. A group of one plain operand goes where the parser
  proves it, so `-1 ^ (k)` becomes `-1^k` through the chain. A group that holds math stays, as in
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
  nothing, so it keeps its spaces, export marker or not (`isListDeclared`). That covers
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
  still stays, as the parser of the commit pin answers.
- The guard on the head of a command was too wide. In `doAssert (⊛m) =~ x`, the glued `⊛` reads
  as a prefix operator, so the commit pin reads the same tree without the group. The group goes
  now, at line 35 of `proposals/03-partner-sign/laws.nim` of `pga_benchmark`.
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
  answers each case as the commit pin of the `ronri` projects answered it, 2026-10-05.
  `suites/test_proofs.nim` runs the compiler that builds it, 2.2.12 in the job of knoller, and
  holds the verdicts of the ASCII cases to the real parser.
- The compiler is the caller's. `koch fix` passes the pin of each project. The command line takes
  `--nim:path`, else the pin of the nearest nimble file, else `nim` on `PATH` (`## Compilers`).
- Where the compiler does not run, the rule removes nothing, and the run prints one warning that
  says why. The exit code stays. Verified by `suites/test_command.nim`.
- Rejected: the parser of the compiler linked into knoller. The source of the commit pin does not
  build under the standard library of 2.2.12 (`llstream.nim`: `readRawData`). Knoller builds with
  2.2.12, and the parser of 2.2.12 lexes the glyph operators of the commit pin as names.
- Cost: a wrong compiler can prove what the right one refuses. 2.2.12 reads `■m` as one name, so
  it proves the group of `(■m).x + y`, and the commit pin reads `■m.x` as `■(m.x)`. So `koch fix`
  and the command line each take the pin of the project. Verified by `suites/test_proofs.nim`.
- Cost: each round of asking compiles the probe once, about 0.6 s to 0.8 s on this container.
  Measured 2026-10-05 with `knoller --check`, this head against `main`: `rga_visualiser` took
  6.0 s against 5.5 s, and `pga_benchmark` 3.1 s against 2.0 s. `dance_ontology` took 5.3 s
  against 3.6 s, and `curator` 4.2 s against 3.1 s.

**The proof on the PGA library: the parser removes what the scan removed, and nothing more.**
Verified by hand, 2026-10-05, with the built binary and the commit pin of the `ronri` projects.

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
  `lookup-table`, `name-case`, `member-case`, `placeholder-letter`, `notation` and `global-word`.
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
reads it as the same type. `casingOf` gives a generic parameter the letter of a placeholder. A
parameter of `typedesc[I]` keeps the snake case of V.1, since `I` is its placeholder, as
`scalar*[I: Basis](t: typedesc[I])` shows. `STYLE.md` spells its borrow template with `T`.

**Snake case passes beside the letter, as step 1 of the ruling, until `pga_benchmark` renames its
`kind`.** `timeKind` in `proposals/04-exact-kinds/timing.nim` of that project declares
`kind: typedesc`. A check that reddens a contributor project cannot merge, and a curator never
edits such a project (CURATOR.md, duties 3 and 11). So `isMiscased` passes a generic parameter in
snake case too. An intended later step makes the letter the only form, once that project renames
`kind`.

**No rename of case touches a generic parameter.** The letter is the initial of what the
parameter ranges over, which is a choice, and snake case passes beside it. So `renamesCase` gives
none, as it gives none for a placeholder. A name in neither form, such as `Kind`, is one finding
of `placeholder-letter`, and the hand renames it. Its message names both forms. A rename that
spells out a coined abbreviation (V.6) still reaches it, as it reaches every kind.

- Rejected: a kind of its own in `KindName`. Each reader of `KindName.Parameter` then has to
  learn it, such as the foreign mark, the notation of III.5 and the subject of each message. A
  flag on `Declared` reaches the casing alone.
- Rejected: the letter as the only form now. It reddens `pga_benchmark`, whose code a curator
  never edits.
- Cost: a reader of the kind alone sees a parameter, so `casingOf` and `isMiscased` read the flag
  beside it.
- Cost: both forms pass, so one file may spell two generic parameters two ways. Reading holds it
  until the rename.
- Cost: the scanner reads the type as the signature spells it, so an alias of `typedesc` is
  unread.
- Verified by `suites/test_names.nim` and `suites/test_declared.nim`.

**One function decides the reach of a binding.** The case of a binding marks its reach, and not
its mutability (V.1). So `reachOf` of `declared.nim` reads the blocks that enclose the binding:

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
  inside `template defineKind(name: untyped)` is no type, and the check reads its fields.
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
- Under `tests/`, a suite that imports `std/random` seeds it, and a stub carries its testament
  header, without `-r`, `batchable` or `joinable`.
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

## Fixed waits

**A fixed wait in drive code is a finding, and the caller decides which file is drive code.** The
names are `sleep` and `sleepAsync` of Nim, and `waitForTimeout` of Playwright, each with what
replaces it (`checkWaits`). The rule comes from IX.12 alone, so knoller holds the names. The
paths of drive code belong to a layout, so the caller gives them.

- `curator/audit` reads `tests/` and `tools/` of each project. The command line reads each file
  under a directory `tests` or `tools`, at any depth (`isFileDrive`).
- Nim names compare as the compiler compares them (`identity`), so `sleep_async` is `sleepAsync`.
  Nim source is read with comments and strings blanked.
- A caller that reads another kind passes the identifiers of each line, less those of its
  comments. Only the name of Playwright reads there, exactly, since `sleep` of TypeScript is the
  helper of a drive.
- Cost: the command line knows no project, so it reads a file that the static pass passes over,
  such as `src/tests/a.nim`.
- Verified by `suites/test_waits.nim`.

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

- Install by git URL needs the `?subdir=curator/knoller` form of nimble. It is not verified with
  the nimble that 2.2.12 ships.
- Some rules read paths in the layout of this repository: `tests/`, a test stub, a drive file
  under `tests` or `tools`, and the umbrella `<project>/src/<project>.nim`. They read the whole
  path, so the spelling of a path changes nothing. In another repository they would need to read
  paths relative to the nearest nimble file.
