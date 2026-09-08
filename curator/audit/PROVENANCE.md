# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-06 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 1931060895ce28b1 |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: built from the owner's brief for the repository, the constitution, the Nim style
guide and the provenance guide, all supplied by the owner; reshaped on the owner's
direction into two project roots driven by koch with Atlas for dependencies. No vendored
source.

## Build glue

**One compiled driver, `koch.nim` at the root, as Nim's own repository builds.** It holds
dispatch only; every check is a library module here, tested here. Koch drives tests and
nothing else, so a project needing verbs beyond them carries its own compiled driver
`tools/build.nim`, same pattern one level down; `contributor/sincopa/dance_ontology` is the
first, and CONTRIBUTOR.md names the convention. Invoked as
`nim r koch <command>`, which rebuilds when sources changed and runs (Article IX.6), or
`nim c koch` once and `./koch`. Rejected: make, a second toolchain with recipe tabs and
untested glue; NimScript `config.nims` tasks, which run in the compiler's VM with a subset
of the standard library, load for every compile in the tree, can silently shadow compiler
commands such as `check`, and cannot be unit-tested; nimble tasks, which need nimble as a
runner. Cost: a bootstrap compile per checkout, and `koch` at the root is a code file
outside any project, audited as a root file. Verified: `nim r koch` warm run 0.085 s in the
spike; `nim r koch <command> --branch:x` passes options through to the program.

## Enumeration

**Git decides what the tree is.** `tree.nim` lists `git ls-files -z --cached --others
--exclude-standard`, drops paths absent from disk, and reads content only for registered
kinds. Git runs as a direct process with an argument list, never through a shell; rejected
`execCmdEx`, which reads by line and appends a newline to NUL-separated output. Cost: git
must be on PATH. Verified by `ttree.nim` on a throwaway repository: ignored `bin/` absent,
untracked file present, accented path unquoted, rename shows as its
destination only because the source never reached the base.

## File kinds

**An allow-list of fourteen kinds is the registry, and an unregistered kind is a finding.**
`kinds.nim` maps basename or extension to comment syntax and whether prose is checked. Nimble files
and NimScript read as Nim; cfg files (`nim.cfg` Atlas writes, `koch.nim.cfg`) read as hash comments;
`atlas.config` and `atlas.lock` are JSON by basename. Markdown is registered as prose, not comment,
so articles in documents pass while form rules still apply. TypeScript and JSON are registered ahead
of use because the owner allows TypeScript where JavaScript is forced. Retired: Makefile, with make;
the registry admits no second build verb, and its recipe-tab exemption went with it, so any tab is a
finding. Rejected: content sniffing, which would let an unknown kind in silently. Html and Svg carry
hand-written pages, which the layout check confines to a project's `pages/` or `mockups/`; generated
markup is one long line and fails width on its own, so the registry admits what hand writes and
rejects what a build emits. Verified by `tkinds.nim` over every match and five unregistered names,
and by `tlayout.nim`: `data.csv` under `curator/audit` yields one finding naming
`curator/audit/src/kinds.nim`.

**A gated kind must argue for itself in its header, and the gate is now checked rather than
trusted.** `Cpp` (`.cpp`, `.hpp`) and `C` (`.c`, `.h`) join TypeScript as languages the owner
admits only where Nim cannot serve; `.hpp` reads as a C++ header and `.h` as a C one, since
the name alone cannot tell them apart. `KindRule` carries `is_gated`, and
`justification.nim` demands the phrase `not Nim because <reason>` in the file's opening
comment run. Until this landed the gate existed only as a sentence in CONTRIBUTOR.md:
`kinds.nim` admitted `.ts` on its extension and asked nothing, so registering a second
language "under the same gate as TypeScript" would have registered it under no gate at all.
Spotted by `contributor/ronri/rga_visualiser` as an aside inside issue 26, and the aside was
sharper than the request. The header is the first run of comments, gaps of one line allowed,
so an include guard above the block and a blank line inside it both keep the run whole; a
marker below the header does not satisfy the gate, because an argument the reader never
meets is no argument. Rejected: the marker anywhere in the file, which admits an argument
buried at line 900; the marker on line 1 exactly, which forbids `#pragma once`; a separate
register of justified files, a second place for the truth to live and drift from. Costs: the
check proves a justification exists and sits where a reader looks, never that it is true, so
a curator still weighs the claim; the one-line gap can reach a comment on the first line of
code, a deliberate laxity whose alternative is a finding on a correct header; and C is
registered ahead of use, which is what produced issue 27 for TypeScript — the curator
recommended holding `.c` and `.h` back and the Architect ruled to take them now, with this
check as what stops an unused kind becoming a free pass. Verified by `tjustification.nim`
and `tkinds.nim`, and driven on 2026-09-06 over real files under `curator/probe/src`: an
unjustified `shim.cpp` and `glue.ts` each yield one finding at line 1, both fall silent once
the phrase is added, and both languages are held to the identical rule.

**A curator pass found six pieces of drift, all of it introduced the same day.** Seven
changes merged on 2026-09-06 and three documents kept describing the behaviour they replaced:
`CURATOR.md` duty 7, `README.md` and `toolchain.nim`'s own header each still told a curator to
install every pinned compiler by hand, which compiler resolution had removed hours earlier.
The checks-reference row for `ci` still omitted `base`, which it has run since that check
landed. And `audit.nim` carried a hand-written copy of the module graph that was wrong in five
places — it named dependencies four modules do not have and omitted `base` entirely — so it is
deleted rather than corrected: a copy of a graph drifts from the graph, and each module's
`import` line is the graph. That is the lesson that retired the run-number ledger, applied to
the module that composes everything.

**`checkRunning` was dead and is gone.** Resolution replaced it; nothing called it in any
module or in koch, and only its own test kept it compiling. A rule with no caller enforces
nothing, and a test covering one measures nothing. What that test was really pinning — a pin
matches by commit for a commit pin and by version otherwise — is kept as a test of `serves`,
which resolution does call.

**`toolchain.nim` was doing two jobs and is split.** It grew from 165 to 287 lines in one day
by absorbing cache paths, a platform table, a downloader and a source build, while its header
still described only the pin rule. Acquisition moves to `compilers.nim`; stating what a pin is
and demanding agreement stays. Tests split the same way. Cost: one more module, and a reader
follows one import to see how a compiler is obtained.

**`DOCS` is retired for `PROJECT_FILES`.** `plan.nim` carried a second list of a project's
records differing from `layout.nim`'s by one entry, `README.md`, with no reason stated
anywhere — so a one-word README fix compiled that project's whole suite. All three records
describe a project and run nothing. Driven on 2026-09-06 against this branch's own history:
a README-only commit plans `[]`, and a one-line source change in the same project plans that
project alone. `nimblePath` replaces the same path expression written out in three modules.

**`findings.nim` and `markdown.nim` were the only modules with no test, and now have one.**
`findings.render` composes every message anyone reads and `<` is what makes a report stable
under reordering; neither was covered, in the module every other module imports.
`tmarkdown.nim` also pins the two costs that module's header states, so a later parser is a
decision rather than a surprise.

**The checker now checks itself, in three ways the curator pass had to find by reading.**
Nothing checked the checker, so faults it would report anywhere else lived in it: a routine
exported and called nowhere (`checkRunning`, kept compiling by its own test, so coverage
looked like use), two modules with no suite at all (`findings.nim`, whose `render` and order
carry every message anyone reads, and `markdown.nim`), and a table naming a verb that had
been retired. `checker.nim` makes each a rule. Dead export counts identifier runs across
every check module and koch, so `tree.auditTree` counts as a call exactly as
`auditTree(tree)` does — the first form is why counting whitespace words was wrong, found by
the check reporting six live routines as dead on its first run. Verbs are read from the
command dispatch alone, bounded between `case options.command` and its `else`, since the
option parser cases over labels a few lines above and contributed `root`, `all`, `branch` and
`sweep` before that bound existed.

Driven on 2026-09-06 rather than argued: a routine added and never called is one finding
naming it; a row deleted from the checks table is one finding naming the missing verb; a verb
dropped from the usage line is one finding naming what usage prints. At rest the tree is
clean, so none of the three fights the code as it stands.

Rejected: flagging an export only tests use, which is how every pure rule here is covered and
would need an exemption list — a second place for truth to live; warning rather than finding,
since every finding fails and a warning nobody must act on is read by nobody; one suite per
module for contributor projects, which group tests by subject rather than by file. Costs: a
routine named in a comment is not dead, so prose mentioning a retired routine hides it, paid
to keep the rule free of false findings; an exported operator is skipped, since it is spelled
at call sites rather than named; and the table's other columns say what each verb reads and
enforces, which stays prose no check reads — only the verb set is derived.

## Comment extraction

**Five hand-written scanners, one per-line accumulator.** Nim: line, doc, nesting block comments,
plain, triple and generalized raw strings, char literals, numeric suffix quotes. Cfg: `#` anywhere
unless `\#`. YAML: `#` at line start or after whitespace, outside quotes. Ignore files: leading `#`
only. TypeScript: `//`, `/* */`, three string forms, documentation stars stripped. Markup: `<!--
-->`, spanning lines, several per line. Whitespace runs collapse so texts compare stably. Rejected:
real parsers, which cost dependencies for a question (where do comments begin) that needs no syntax
tree. Cost, assumed: TypeScript regex literals containing `//` open a false comment until a fixture
lands. Cost: markup scanner reads `<!-- -->` only, so comments inside `<script>` and `<style>` stay
unread, the same blind spot markup hosted in a Nim string already carried. Verified by
`tcomments.nim` across the syntaxes, including the testament header string and markup comments that
span lines.

## Prose

**Articles are the whole rule, as data.** `ARTICLES = ["a", "an", "the"]`; tokens are
whitespace-split, punctuation-stripped, lowercased, after backtick spans are removed.
Verified by `tprose.nim`: 300 seeded random telegraphic comments pass and each with one
inserted article fails; citations `2.2a`, URLs and underscored names pass. Cost, verified
during the first build: label `A` as in "Appendix A" is flagged; the header of `prose.nim`
tripped on its own example and now writes the label in backticks.

## Form

**Width is counted in runes, any tab is a finding, CR is a finding, and a file ends with exactly one
newline.** A line over the limit passes only when breaking cannot fix it: its longest
whitespace-free token with the line's indent already overruns the limit, that token is within
`TOKEN_MAX` (400 runes), and the rest of the line fits once it is removed. A font URL has no
whitespace to break at; prose always does; minified markup is one run far past the bound. Rejected:
exempting URLs by pattern, which would guess at intent, and exempting any single-token line, which
admits machine output of any length. Cost: a long identifier gets the same exemption a URL does,
since neither can be broken at whitespace. Lines are split on LF only so CR survives; `splitLines`
was rejected because it swallows CRLF. `LICENSE.md` is width-exempt because third-party text stays
verbatim. Nim banners `#[ Title ]#` need two blank lines before and one after; tiers are unmarked in
syntax, so the second-tier minimum is demanded of every banner. Assumed, not checked: two-space
indent. Verified by `tform.nim`: 100 runes pass and 101 breakable runes fail; a 202-character fonts
link passes while 207 characters of prose and 400 characters of minified markup do not; tab in Nim
and cfg fails; every ending case. Verified by driven check on real pages, 2026-09-05: the
validator's 391
markup lines extracted verbatim to a file and the whole-cloth fonts link, whose longest token is 179
runes, both audit clean, while a generated single-line drawing of 1,407 characters and a page
outside `pages/` do not.

**A generated npm lockfile passes the width rule, measured rather than assumed.** Before
CONTRIBUTOR.md was allowed to demand a committed `package-lock.json`, one was generated
(`typescript` 5.6.3 and `@playwright/test` 1.48.2, npm 12, 2026-09-06), placed under
`curator/probe`, and put through `nim r koch tree`: 93 lines, longest 117 runes, **0
findings**. `package.json` and a `tsconfig.json` carrying `strict`,
`noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` passed with it. The exemption
that saves it is the unbreakable-token rule: the long lines carry one `sha512-` digest of 95
runes, and the rest of the line fits without it. The shape holds at any lockfile size, since
the longest token in such a file is always a digest or a registry URL, both far inside
`TOKEN_MAX`. Arithmetic had predicted this; the figure above is what was run, and it is the
reason the rule could be written without an exemption beside `LICENSE.md`.

## Layout

**Two project roots, each holding README.md and folders only, and every folder checked at its
depth.** A project is `curator/<project>` or `contributor/<domain>/<project>` and must hold
README.md, PROVENANCE.md, GLOSSARY.md, exactly one nimble file named after the folder, and at least
one file under `tests/`; a nimble file requiring packages demands `atlas.lock`. Root README.md
carries one table row per domain equal to `DOMAINS`; each root README opens with its folder name;
each domain README opens with the domain name and holds the theme line. An unknown root directory, a
stray file inside a root or domain folder, and an unregistered domain are findings, never skipped:
an earlier form of this check returned early for everything under `curator/` and dropped unknown
heads silently, so a misplaced project vanished from the audit. A committed page, Html or Svg, must
sit under a project's `pages/`, what the project stands behind, or `mockups/`, a one-off exploration
kept for reference; the separation is declared by directory, never inferred from content. Rejected:
letting domain READMEs list projects, which would force a contributor to edit outside their prefix;
a theme line for root READMEs, which would be a fabricated authority; inferring mock-up from
generated, which would make the distinction an accident of formatting. Cost: empty directories are
invisible to git, so `tests/` must hold a file. Verified by `tlayout.nim` over a fixture tree the
tests build, with the project list pinned and the unknown-domain case asserting both the finding and
the unchanged project list; `taudit.nim` proves the fixture is clean under every static check.

**Only one check reads substance, and it reads a narrow slice of it.** `checkCitations`
resolves every claim opening `Verified by` and naming a backticked `.nim` file, in a
project's `PROVENANCE.md`, against that project's
`tests/`, from the path set the tree already holds, and reports a citation naming no such
file. Chosen because the record's most valuable property is its verified-versus-assumed
split, and until now nothing stopped a citation rotting when a suite was renamed: the audit
checked the file's shape and never a word of its content. Rejected: matching the claim
against what the named test asserts, which no checker can do; and flagging every backticked
span, which would catch commands such as ``atlas changed``, so the `.nim` ending is the
guard. Cost, and it is the honest limit: a delegate can still cite a real test beside a claim
that test does not make. That gap closes by reading.
Verified by `tprovenance.nim`, and by driven check on this repository, 2026-09-06: all
nineteen citations on `main` resolve untouched, so the rule is a ratchet on today's honesty
rather than a cleanup; renaming one to an absent file, to a source file rather than a test,
or to another project's test each reports one finding naming it, while the same sentence
carrying ``atlas changed`` reports none.

## Provenance stamp

**FNV-1a 64-bit over CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md, CR stripped, NUL
between files, 16 lowercase hex digits.** Rejected: `std/sha1` (deprecated in Nim 2, warns
on every build), the `checksums` package (a nimble install in CI for one digest),
`std/hashes` (unstable across Nim versions). CURATOR.md is excluded so curator-only edits
touch no project. Cost: a change detector, not a signature; collision needs an adversary.
Verified by `tprovenance.nim`: determinism, one-byte sensitivity, order sensitivity, boundary
sensitivity, CRLF invariance; and by `taudit.nim`: one byte in any rules document goes
stale in every project, one byte in CURATOR.md in none.

## Glossary

**Shape only: heading, `## Language`, and a definition line after every `**Term**:`.**
Content is the contributor's and Architect's, and a term enters only when the Architect
selects it. The check cannot know what was agreed, so it reads shape alone; agreement holds
by the Architect's reading. The same check now runs on the top-level `GLOSSARY.md`, which
layout requires at root. Zero terms pass, because the format creates
entries lazily. Verified by `tglossary.nim`.

## Scope

**A branch must carry base's rules and checker before it may merge.** `base` reads what the
base gained since the branch forked (`gainedPaths`, the mirror of `changedPaths`) and reports
a branch predating a charter document or the checker. Chosen because pull request 11 was
green against the `main` of its day, merged into a later one, and arrived carrying a stamp
three rules changes had falsified: run 45 failed and nobody was told. GitHub prevents exactly
this with "require branches to be up to date before merging", which sits behind paid
rulesets, so the process catches it instead. It needs no setting change: the `base` job feeds
the `audit` gate, which branch protection already requires, so a stale branch is refused
through a check that is already in place.

Only two kinds of path count. A charter document moves the stamp every project claims, so a
branch predating one carries a claim already false. The checker decides what the audit
accepts, so a branch predating it was measured by an older ruler. Everything else may differ
freely — another project's code cannot make this branch's stamp wrong, and demanding currency
with all of it would be friction for nothing.

Verified by `tbase.nim`, and by replaying the incident itself, 2026-09-06: pull request 11's
branch checked against today's `main` reports the finding, naming `CONTRIBUTOR.md`, five
check sources and `koch.nim`; the same branch checked against its own fork point reports
nothing, which is why its run was green at the time. A branch behind only on another
project's records and glossary reports nothing, and a branch that merges the base reports
nothing after.

Cost: merging a rules change reddens every open pull request until each merges the base. That
is the same cost the paid setting carries, and it fires exactly when staleness is real.
Cost, and the honest limit: this reads at pull request time, never at merge time. A branch
green at ten can still merge at five past after another lands. The window shrinks from days
to minutes and does not close; only a merge queue closes it, and that is the paid feature
again. It nearly recurred while the role channel was in flight — pull requests 23 and 24
merged two minutes apart, both re-stamping, and resolved cleanly by luck of which files each
touched.

**Roles reach each other through issues, and nothing waits on the Architect to relay.** A
contributor blocked by a rule opens an issue from `.github/ISSUE_TEMPLATE/process-change.md`;
a curator reads open issues at the start of every session, answers on the issue and reports
to the Architect, who decides. Chosen against routing the request through the Architect,
which was the shape first proposed: that keeps one person as the link that makes it work, and
a request is then lost by their not relaying it rather than merely delayed. Telling them
still helps and is still invited; it is no longer load-bearing. The template mirrors the pull
request template's discipline — what is blocked, which rule stands in the way, what was tried
and rejected, what is proposed, what declining costs — so requests arrive comparable and the
evaluation is nearly mechanical. The evaluation is written on the issue rather than only to
the Architect, so the reasoning outlives the conversation that decided it.

Cost: nothing checks any of this. GitHub is not repository state, so the role line, the
template's use, and which channel a contributor picks are all held by reading — the same
class of gap as glossary agreement, and recorded beside it rather than implied away.
Cost: a curator who never starts a session is a channel nobody is reading; the sweep is
weekly, sessions are not scheduled at all.

**A session starts by reading `main`, not only issues.** The second half of the session-start
duty exists because a contributor's merge reddened `main` on 2026-09-06 and nothing said so:
pull request subscriptions do not cover `main` pushes, and the merge-process duty has a
curator watch only their own merge. It was found by accident twenty-four minutes later.
Rejected: requiring branches to be up to date before merging, which would have prevented the
cause outright and is behind paid rulesets. The process now catches what the setting would
have.

**Domain folders are ASCII slugs; the accent lives in the display name.** `síncopa` became
folder `sincopa`, name `síncopa`, which is the split `comma_games` and `comma, games` already
used — the registry's own rule, applied to the one row that broke it. Chosen because git
quotes a non-ASCII path by default, so `git ls-files` piped into any shell tool fails on it,
which cost two mistakes while writing the structure review and forced a `core.quotepath off`
instruction on every delegate; that instruction is gone with its cause. This file already
recorded a second cost nobody had hit: macOS stores such a name as NFD, so the same folder
has different bytes there. A `static` assertion in `domains.nim` now holds every folder to
`isProjectName`, so an accented folder fails the build rather than the suite, which is the
earliest boundary available (Article IV.4). Cost: 72 files moved, and the old branch prefix
`contributor/síncopa/...` no longer parses.

**A curator may move a contributor's files, never edit them.** The rename was work no role
could do: `scope` reads a move as a delete plus an add (`--no-renames`, deliberately), so a
curator branch was refused all 144 paths, while a contributor branch cannot reach the domain
folder or `DOMAINS` at all. `tree.nim` gained `movedPaths`, which reads
`--name-status --find-renames=100%`, and `checkScope` exempts exactly those paths on a curator
branch. Only an exact rename qualifies, so an edit disguised as a move is still caught.
Chosen because renaming a domain is a registry change and the registry is the curator's;
moving files is the consequence, never authorship. Rejected: merging this one red, which
spends a green `main` on a problem that recurs whenever anything is renamed; and splitting it
across a contributor pull request and a curator one, briefly broken between merges. Cost: a
curator may reorder a contributor's files without asking — content cannot change and the move
is visible in review, so the cost is disorder rather than damage. Cost: one line of display
text inside `dance_ontology`'s review page still names the old path, because a curator may
move that file and not edit it; it is recorded as that project's open question rather than
corrected by a hand that has no business there.

**Curator reach into contributor projects stops at their records.** `curator/<name>` still
owns the empty prefix, because a rules change must reach every project, but under
`contributor/` the only writable paths are a project's `README.md`, `PROVENANCE.md` and
`GLOSSARY.md` — `PROJECT_FILES`, read from `layout.nim` rather than repeated. Chosen because
that empty prefix was the one hole in an otherwise mechanical scope system, and it belonged
to the most-run role: CURATOR.md duty 9 forbade writing contributor code, and nothing but
reading held it. Rejected: restricting to `PROVENANCE.md` and `GLOSSARY.md` alone, which the
per-project-toolchain propagation had already disproved — that change removed "Needs Nim
2.2.4" from three contributor READMEs, prose the rule itself invalidated, and the tighter set
would have blocked it and left stale text no contributor knew was stale. Cost: the README
stays writable, so restraint about rewriting a project's prose is still duty 9's to govern by
reading, never the check's. Verified by driven check on this repository: a curator branch
touching `dance_ontology/src/dance_ontology.nim` reports one finding naming the path, while
the same branch touching that project's `PROVENANCE.md` and `README.md` reports none.

**The regression rule is enforced, not hoped for.** `commits` reads subjects newest first and
demands every `fix` carry an earlier `test` of the same scope on the same branch (Article
IX.8). Chosen because "every mistake becomes a test" was the Architect's stated priority and
lived only in prose. Rejected: matching across `main`'s history, which would need the whole
log and would still pass a fix whose test landed years earlier under a different intent.
Cost: a fix of a mistake whose test already sits on `main` needs a test here or another type;
the escape is honest, since a change needing no new test is not a `fix`. Verified by driven
check: a branch carrying `fix(audit)` alone reports one finding, and the same branch with
`test(audit)` committed first reports none.

**Branch grammar mirrors paths: two, three or four segments, and the prefix decides.**
`curator/<name>` owns the empty prefix, so every path passes; `curator/<project>/<name>`
and `contributor/<domain>/<project>/<name>` own their folder. `main` passes because pushes
to it are merges the owner approved. Rejected: a special case for the curator root in the
scope check; the empty prefix is one mechanism. Cost: fixed segment counts reject nested
branch names; the owner may merge red deliberately, so the check is a guard, not a gate.
Verified by `tscope.nim` over all five domains, one curator project, the curator root, and
two rejected forms; `tdomains.nim` over 18 rejected branch forms including the old
three-segment domain-first form.

## Commits

**`type(scope)!?: summary` with eleven types as data; on a project branch, curator or
contributor, the scope must equal the project.** The curator root branch accepts any valid
scope, because propagating a rules change commits under each project's scope. A branch
outside the grammar still gets format checking. Cost: imperative mood is unverified.
Verified by `tcommits.nim`: every type with three scopes, the breaking marker, 11 rejected
forms, and scope enforcement on both project branch forms.

## Project runner

**`testament --nim:<absolute> pattern "tests/t*.nim"` in each project directory, serially,
output streamed.** Koch holds the verb once; no per-project build file exists. The compiler
path is absolute (`findExe`) because testament resolves `--nim` against its working
directory. Failure is a finding at the project's `tests` directory echoing the exit code.
Cost: serial; a project in another language needs its own runner arm. Verified by
`tprojects.nim` with a passing and a failing fixture project driven through real testament,
and `runIn` against `true` and `false`.

## Toolchain

**Each project pins its own compiler; there is no repository-wide Nim.** The pin is
`requires "nim == <version>"` in the project's nimble file, read by `toolchain.nim` through
the same `requireLiterals` scan `dependencies.nim` uses for packages, so requirements are
parsed in one place. Chosen because no single version serves every project, which is
measured rather than feared: `contributor/ronri/rga_visualiser` depends on a library 2.2.4
cannot compile (assignment through a `var`-returning `[]`), and `dance_ontology` crashes the
compiler itself on 2.2.8 and 2.2.10 in six of its eleven suites. Rejected: one pin for the
repository, which cannot hold both; `requires "nim >= x"`, which cannot express the upper
bound `dance_ontology` needs and cannot say which compiler a suite actually passed on; a
separate `.nim-version` file, a second place a version lives beside the nimble file already
naming one. Cost: four projects may sit on four compilers, and a curator changing the
checker needs every one installed.

Verified that Atlas accepts an exact compiler pin rather than treating it as a package to
resolve: with `requires "nim == 2.2.6"` in `rga_visualiser.nimble`, `atlas --noexec rep`
cloned and set the pinned commit and `atlas changed` exited 0 (Atlas 0.9.0, 2026-09-06).

**A pin may name a commit as well as a version.** Asked for by `rga_visualiser`'s
contributor, 2026-09-06, and the reasoning was theirs: their dependency `pga` spells its
operators in prefix form on its head, which needs a lexer change that is on Nim's `devel` and
in no release — 2.2.10 is the newest, verified here by `git ls-remote --tags`. Without a
commit pin the project sits a commit behind its dependency until a release lands, possibly
months. A commit records what was verified exactly as a version does. Rejected: a bare
`devel` label, a moving target that records nothing; a dated nightly, cheap to install and
retained only for a window, so an old pin stops installing and the record stops being
reproducible, which is the property the exactness rule exists to protect.

A pin is forty lowercase hex characters, as `atlas.lock` records commits. `isCommit` is
tested before `isVersion` because forty digits would satisfy both, and the absurd version
loses. `nim --version` prints a `git hash:` line — release tarballs carry it too, not only
builds made from source — so `checkRunning` compares a commit pin against that and a version
pin against the dotted version on the first line.

Cost, and it falls on whoever builds the project: no action installs a compiler by commit,
so CI clones `nim-lang/Nim`, checks the commit out and runs `build_all.sh`, cached by commit
so the bootstrap is paid once rather than per run. A delegate installs it the same way. Cost:
the driver project may not pin a commit, since the workflow installs it through the setup
action and every other job waits on that one; `checkDriver` reports it.

Verified by `ttoolchain.nim` and `tplan.nim`, and driven on this repository, 2026-09-06:
pinning `curator/probe` to `f7145dd2…`, which is the commit the local 2.2.4 reports as its
own, passes `koch tests` and renders `"kind": "commit"` in the plan; pinning it to forty
zeros reports one finding naming the compiler actually present; pinning `curator/audit` to a
commit reports the driver finding. Not verified, and it cannot be until a project needs it:
that CI's source build succeeds and its cache hits.

**The driver version is derived, never a second pin.** `NIM_VERSION` in
`.github/workflows/check.yml` builds koch and runs the whole-tree pass, and `checkDriver`
fails the audit unless it equals `curator/audit`'s pin, because koch compiles that project's
modules. This is the same derived-view rule `layout.nim` applies to the domain table in
`README.md`. Verified by driven check: setting `NIM_VERSION` to `2.2.6` against a `2.2.4`
pin reports one finding at the workflow, and restoring it clears.

**A run on the wrong compiler is a finding, not a warning.** `checkRunning` compares the
project's pin against `nim --version` from `findExe("nim")`, i.e. the compiler testament
will invoke, rather than `NimVersion` koch was built with, since a prebuilt `./koch` and a
newer `nim` on `PATH` would otherwise disagree silently. The mismatched project is reported
and not compiled. Rejected: skipping it quietly, which would let the runner discover what
the local run was supposed to confirm. Cost: a curator touching `koch.nim` or
`curator/audit/src/` selects every project and so needs every pinned compiler installed.
Verified by `ttoolchain.nim` for each rule, and by driven check on this repository: a
nimble file carrying `>=` reports one finding naming what it holds, and a nimble file with
no compiler requirement reports the same.

**Koch resolves each pin to its own compiler, and fetches one it lacks.** Until this landed
`runJobs` read the single compiler on `PATH` and reported a finding for every project whose
pin differed, so `nim r koch ci` — the command CONTRIBUTOR.md requires to pass before a pull
request is opened — could not be green as one command whenever the changed set spanned two
pins. Any change under `curator/audit/src/` selects every project, so that was the ordinary
case, not an edge: it shaped four pull requests on 2026-09-06, each verified by running two
compilers under two commands and stitching the halves together in prose. Resolution now goes
`PATH` when it already serves the pin, then `~/.cache/koch/nim/<pin>/bin`, then a fetch:
a published release as a tarball from nim-lang.org, and a commit — or any platform
nim-lang.org publishes no build for — by cloning `nim-lang/Nim` and running `sh build_all.sh`,
the same recipe `check.yml` already used, so it was proven rather than invented. The cache
sits outside the checkout because the audit reads untracked files, the lesson the first run
on `main` taught. `$KOCH_NIM_DIR` moves it. Rejected: a directory the developer populates by
hand, which leaves the defect in place for anyone who has not; `choosenim`'s layout, a second
convention to maintain that cannot serve a commit pin at all.

Two things were learned by driving it rather than reasoning about it, and both changed the
code. **A half-built toolchain lies.** Probing `bin/nim` five minutes before `koch boot`
finished returned the csources bootstrap binary, which answered `--version` with an unrelated
commit — so a source build now completes beside its destination and moves in only when done,
as the tarball path already did. **Naming a tool by path is not enough.** Atlas resolves `nim`
through `PATH`, so the toolchain's own Atlas still read whichever compiler `PATH` held and
warned `environment mismatch: versions differ`; measured on 2026-09-06 with one Atlas binary,
warning under one `PATH` and silent under the other. Children therefore run with the
toolchain's `bin` leading `PATH`, and that warning is gone from a full run. A tool absent from
a toolchain falls back to `PATH` rather than raising, since what `koch tools` produces moves
between Nim versions.

Verified by `ttoolchain.nim` and `tprojects.nim`, and driven end to end on 2026-09-06.
`curator/probe` pinned to 2.2.6 with nothing local serving it: koch fetched the tarball and
ran the suite in **7.6 s** cold, 3.0 s warm, testament reporting
`/root/.cache/koch/nim/2.2.6/bin/nim`. Then the real case, one command with only 2.2.4 on
`PATH` and four projects across two pins: **0 findings in 3 m 37 s**, `rga_visualiser` on the
commit-pinned compiler and the other three on `PATH`, with no Atlas mismatch warning anywhere
in the log. A pin nothing can serve — 9.9.9, empty cache — is one finding naming the pin and
the cache it tried, not a crash.

Costs. A checker now reaches the network and may build a compiler: seconds for a release,
minutes for a commit, once per pin. Each cached toolchain is a few hundred megabytes and
nothing prunes them. Downloads are trusted on TLS alone, with no checksum or signature
verified, because Nim publishes none in a form worth parsing — the one place this repository
takes something on trust that it pins everywhere else, and worth revisiting if a digest
appears. CI is untouched: every `project` job's installed compiler already satisfies its
`matrix.nim`, so resolution stops at `PATH` and never fetches, and `check.yml` keeps its own
commit build, which caches per commit through `actions/cache` and so beats koch's own.

## Scoped checks

**The static pass stays whole-tree; only compilation is scoped.** `plan.nim` selects the
projects one change asks to compile: a project enters when a changed path under it is
anything but its `PROVENANCE.md` or `GLOSSARY.md`, and a change to `koch.nim`,
`koch.nim.cfg` or `curator/audit/src/` selects every project, because how each is checked
changed. A path inside no project selects nothing by itself. Chosen against scoping the
static pass as well, on the figures below: the static pass is hundredths of a second and
the suites are tens of seconds, so scoping the static pass would buy nothing measurable and
cost a second code path plus the whole-tree layout and stamp guarantees on every pull
request. Rules propagation therefore compiles nothing at all, since it rewrites only the two
record files, while every stamp is still checked.

Cost: a merged change can leave an unrelated project red until that project next changes.
The weekly `schedule` sweep, which plans every project, is the guard, and it is a weaker
guard than compiling everything on every push.

**The sweep fires. Observed 2026-09-07**, first Monday after cron landed: run 34120324032,
event `schedule`, success. It planned all four projects and ran each on its own pin —
`rga_visualiser` on its commit, other three on 2.2.4 — and did not skip itself, code having
merged that week. Parallelism holds on real sweep rather than only on pull request's matrix:
four jobs started within one second and phase finished in about four minutes against about
nine minutes summed.

**It fired 6 h 09 m after its 06:00 slot**, which is what GitHub does with `schedule` under
load rather than fault here. So sweep promises *some time on Monday*, never 06:00, and curator
reading cron and returning at 06:05 will find nothing and conclude guard is broken. That is
recorded because it happened: this claim was first written as "sweep did not fire", on
observation taken five and half hours in, and retracted when run arrived forty-four minutes
later. Waiting is part of reading this signal.

**The sweep skips itself in a quiet week.** `sweepJobs` plans every project when any code
merged inside `SWEEP_DAYS`, and nothing at all when none did, judging "code" by the same
record-file exclusion scoped runs use. Chosen because the sweep exists to catch rot that
scoped runs missed, and rot arrives with merges: a week nobody merged has nothing for it to
find, and a run that compiles four projects to confirm that is four projects of runner time
for no information. Rejected: sweeping the projects that changed in the window, which is
what the push runs already did, and would miss exactly the cross-project rot the sweep is
for. Cost: rot from outside the repository — a runner image moving under a pinned compiler,
say — goes unseen through a quiet week and waits for the next sweep that runs. Cost: the
window is named twice, as the cron here and `SWEEP_DAYS` in `plan.nim`; nothing checks that
they agree, so CURATOR.md duty 7 says to change them together.

A repository younger than the window has every commit inside it, so `revBefore` finds no
commit to measure from and the sweep runs whole. That is the case today and will be until
2026-09-12, so the skip is verified by its suite rather than by a live Monday: `tplan.nim`
drives the decision over code, record-only and empty changes, and `ttree.nim` drives
`revBefore` at both ends, returning HEAD for a zero-day window and empty for a ten-year one.

## Dependencies

**Atlas per project: requirements in `<project>.nimble`, checkouts in ignored `deps/`,
exact commits in committed `atlas.lock`, paths in committed `nim.cfg`.** `dependencies.nim`
parses `requires` lines (every literal on the line, `nim` excluded) so the layout check can
demand a lock; `koch deps` runs `atlas --noexec rep` in every project holding a lock and
judges success by `atlas changed` exiting zero. Rejected: one Atlas project at the root,
because Atlas 0.9.0 (shipped with Nim 2.2.4) has no shared-workspace model, a root `nim.cfg`
would leak every dependency into every project through parent-config lookup, and the
constitution wants each dependency justified where it is imported (II.8). Costs, verified
in the spike: Atlas clones nim-lang/packages before any command, so it needs the network
even for zero packages, which is why projects without a lock skip it entirely; `atlas rep`
exits 1 after restoring the checkout because its `git submodule update --init` step fails,
hence the `atlas changed` verdict; a dependency used by two projects is cloned twice.
Verified by `tdependencies.nim` for the parser and the lock-less skip; the Atlas command
flow (`init`, `use malebolgia`, `pin`, delete checkout, `rep`, compile against the
dependency) was verified once by hand on a throwaway project on 2026-09-05 and stays
assumed for CI until the first real dependency lands.

**`atlas changed` alone does not prove a restore happened.** It exits 0 while warning
`repo missing!`, so a restore that fetched nothing reported success. `checkCheckouts` now
reads the `dir` of every item in `atlas.lock`, resolves `$deps` to `deps`, and demands the
directory exists before `atlas changed` is consulted. Measured on Atlas 0.9.0, 2026-09-06,
by deleting `deps/` and re-running: `atlas changed` exited 0 with the checkout absent.
Verified by `tdependencies.nim`, which drives `checkCheckouts` over a temporary project with
and without the directory, and over a lock that is not JSON. Cost: the lock is parsed twice
per restore, once by Atlas and once here.

**The lock silently reverts an edit to the nimble file.** `atlas.lock` stores a whole copy
of the nimble under `nimbleFile.content`, and `atlas rep` writes that copy back over the
file. A requirement edited without regenerating the lock is therefore undone on the next
`koch tests` or `koch ci`, which run `restoreAll` first. Nothing fails at that moment —
compilation never reads the nimble — so the loss surfaces later as a `koch tree` finding on
a reverted line the contributor never wrote. Reported by `contributor/ronri/rga_visualiser`
as issue 25 after losing an edit to `nim == 2.2.10`, and reproduced here on 2026-09-06:
editing the pin to `nim == 2.2.4` and running `atlas --noexec rep` restored `nim == 2.2.10`
and exited 0. `checkLockNimble` now compares the stored copy against the committed file and
reports the first differing line. The comparison runs in the static pass, over the tree as
git holds it: run after `restoreAll` it would compare the file against the copy it had just
been written from, pass always, and cover nothing — the same defect `atlas changed` already
taught this project. The finding points at the nimble file rather than the lock, because
that is the file the restore overwrites and its line numbers resolve, while numbers inside
the stored copy do not. Verified by `tdependencies.nim`, and driven against the real lock:
with the stored copy holding `nim >= 2.2.6` the check names
`rga_visualiser.nimble:13`, and with the lock restored it is silent. Costs: a project
changing any requirement must regenerate the lock or make its stored copy match, and the
contributor reports that `atlas pin` writes `"items": {}` for a dependency whose repository
carries no nimble file, so the hand-patch stays necessary until Atlas changes; a lock
storing no copy is compared against nothing, since one real lock is thin evidence for
demanding the key and such a lock reverts nothing either way. Because it composes a check
that reads JSON, which Nim marks effectful, `auditTree` is now a `proc`; every rule it
composes stays pure and `layout.nim` still reads paths only.

## Tests

**Testament over `tests/t*.nim`, each stub carrying the header from STYLE.md §6 without
`-r`.** Every project carries suites: 22 files here, one in `curator/probe`, three in
`contributor/ronri/rga_visualiser`, and twelve in `contributor/sincopa/dance_ontology`, whose
stubs dominate every whole-tree run. Counted from `git ls-files '*/tests/t*.nim'` rather than
by hand, which is how the three of them this paragraph used to name went stale.
Testament runs each binary itself; `-r` in the command would run every test twice
and `--outdir` breaks testament's search for the binary, so binaries sit beside sources and
git ignores them everywhere (`**/tests/t*`). Suites are named after constitution articles
and every assertion carries a citation. Fixtures are built by `fixtures.nim`: a smallest
clean tree with a project under each root, and throwaway git repositories. Verified by
running `nim r koch tests` over every project, 2026-09-08: 39 suites pass, 0 findings, each
on the compiler its project pins — which is the whole point of that verb, since only one of
the three pins was on `PATH`.

## Type checking

**Runner reaches every project's TypeScript, and reaches it through that project's own
verb.** `koch types` restores node tools from the project's lock and runs
`tools/build.nim types` in it; the verb derives whatever those scripts read and type-checks
every configuration, stopping before anything needing browser. koch names verb and nothing
else, since what checking needs differs per project while the name need not.

**Which projects it reaches is derived, never listed.** `nodeDirs` selects projects whose
tree holds `package.json` beside `package-lock.json`. Nothing in `check.yml` names a project,
exactly as nothing names one for the compiler matrix, so a project enrols by carrying those
two files and no second list can drift. Lock is demanded beside manifest because `npm ci`
needs one, and unpinned tools would be the one thing here that nothing pins.

**No pin is resolved and no toolchain is fetched.** `tools/build.nim` compiles no project
code — it derives declarations by reading source as text — so a project's own pin buys
nothing here, and building `rga_visualiser`'s commit-pinned compiler to run a build script
would cost minutes of runner for no checking. The driver's compiler runs it, as it runs the
whole-tree pass, so this is one plain job rather than a second matrix.
  Cost, and the condition it rests on: this holds only while a `types` verb compiles no
  project code. One that did would need its pin, and this would become a matrix job like
  `project`.

**Scoped, unlike `tests`.** `koch tests` runs every project or one named; scoping for
compiling lives in the matrix `plan` renders. The type check has no matrix, so scoping lives
in the verb: it takes the projects one change asks for, by the same `testSet` rule, and
`--all` drops that for the weekly sweep, which has no base commit to compare against.

**Absent npm is a finding naming it, never a skip.** koch resolves a Nim compiler it lacks
and will not fetch node. A check that quietly does nothing is worse than one that fails,
because it reports green for work it never did.

*Checked.* Driven against the regression it exists for, on 2026-09-07: renaming
`nimSceneHandles` to `nimSceneSlots` in `bridge.nim` without touching anything else makes
`koch types` report one finding, over `TS2304: Cannot find name 'nimSceneHandles'` at four
sites in `construct_section.ts`. Reverted, it returns 0 findings. That is exactly the drift
the vocabulary pass of issue 46 would have caused, caught at build rather than one run-time
failure at a time. Whole verb costs 11 s cold on this machine, `npm ci` included.
  Scoping driven the same way: a change touching only records selects no project, and a
  change to `koch.nim` or a check source selects every one, since how each is checked
  changed.

## Driven checks

**Runner drives what the suites cannot reach, through that project's own verb.** `koch driven`
restores a project's checkouts and its node tools, then runs `tools/build.nim drive` in it: the
verb builds the page and drives it through held keys, wheels, right-button pans, two-finger
pinches and long presses. Testament tests rules — what a slide does to the pivot, what a zoom
does to distance — and nothing in it presses a key, so a rule wired to the wrong event is the
class of defect no suite here could see. `rga_visualiser` had 135 such checks and the runner
ran none of them, which made every one of them evidence that its author ran it (issue 47).

**Enrolment is the verb, read from the project's own driver.** `verbDirs` reads the dispatch of
`tools/build.nim` and selects projects naming `drive` in it, so a project enrols by carrying
the verb and nothing lists it anywhere — the same derivation `nodeDirs` uses one step earlier,
and the same reason. The parser is not a second one: `dispatchVerbs` already read koch's own
dispatch for the rule holding its verbs, usage and CURATOR.md's table to one set, and it now
takes the line opening that dispatch as an argument, since koch cases over parsed options and a
project driver over its first argument. One shape, one reader.
  Cost: a project spelling the verb otherwise is passed by in silence. That is why
  CONTRIBUTOR.md now names `drive` and `system` outright rather than describing them.

**It is a matrix on each project's own pin, where `types` is one plain job — and that
difference was measured, not reasoned.** The first cut mirrored `types` exactly, on the
argument recorded there: `tools/build.nim` compiles no project code, so the driver's own
compiler serves. Running it refuted that in thirteen seconds. The driven verb calls `web`,
which runs `nim js` over `bridge.nim`, which compiles project code and everything it imports —
so `rga_visualiser` on the driver's 2.2.4 fails inside `pga`'s `multivectors.nim`, whose syntax
only the commit that project pins can lex. The type-check record had written down the exact
condition it rested on — *"this holds only while that verb compiles no project code. One that
did would need its pin, and this would become matrix job like `project`"* — and this is that
condition arriving. So `driven` is planned like `tests`: `plan --driven` filters what `plan`
already selected, which is what makes it inherit scoping, `--all` and the sweep without
restating any of them.

**System packages are installed from the project's declaration, never from names in the
workflow.** `koch system` runs each selected project's `system` verb and prints the union,
sorted and deduplicated; the job pipes that into `apt-get`. koch prints and never installs,
because which package manager serves a name is the machine's business while the list is the
project's. The workflow therefore names no package, exactly as it names no project.
  Only bare names survive the read. The verb's contract is one name per line, and the one other
  thing that reaches that stream is the compiler complaining, which always spells a position
  before its message — so a line carrying whitespace is dropped rather than handed to a package
  manager. A compiler that complained still fails, since the absent package names itself.

**Faces are cached on the file that pins them, and that cache is the safest of the three.**
`assets` keeps a face already carrying its pinned digest and refetches any that misses, and
`web` verifies again before embedding, so a stale entry heals rather than ships — where the
Atlas and npm caches rest on the key alone. The key is the whole driver rather than the digests
inside it, so an edit moving no face still misses; the cost is refetching six files, measured
at 1.5 s.
  Rejected for now: caching apt archives. It would save the download and not the install, and
  the archive directory is root-owned and awkward to key. Measure the install first, exactly as
  `nimcache` waits on being driven against a deliberately stale cache.

*Checked.* Verified on the runner, 2026-09-07, which is the only place this claim means
anything: the `driven` job reports **136 of 136 checks passed, 0 findings, in 5 m 30 s**, in a
real Chromium over real gestures — pinches, wheel notches, held keys and pixel comparisons —
and `audit` reads its verdict. Verified locally first, by the same verb: 2 m 36 s warm and
3 m 31 s on a tree whose `build/` was removed entirely, which is the runner's own case.
  Verified by breaking: on the driver's own 2.2.4 the same command fails inside `pga` rather
  than passing, which is what sent this to a matrix rather than to one plain job.
  Verified by the gap it found, which is the return this job paid for before it ever went
  green. On a cold checkout the first run stopped at `Missing face
  'build/fonts/commit-mono-latin-400-normal.woff2'; run 'assets' first`: every expensive step
  done — Atlas restored, node packages installed, declarations derived, bridge compiled — and
  one cheap one missing, because `drive` chained `web`, `types` and `declare` but not `assets`.
  Invisible to its author, whose `build/fonts` was always there. Raised on issue 47, fixed by
  the project in pull request 71, and the next run was green.

**The browser a declaration names is the browser that runs, and the snap serves.** `apt-get
install chromium` on `ubuntu-latest` gives `/snap/bin/chromium`, a wrapper rather than a plain
binary, and whether Playwright would launch one was unknown while this was written — the risk
was recorded as open rather than guessed at either way. It launches. Recorded because the
opposite result had a different owner: a package that did not serve the runner would have been
the project's declaration to change, never a name quietly substituted here, which would have
moved a real dependency into a file its author does not read.

## Continuous integration

**Six jobs, and the three required check names did not change.** `plan` emits the matrix,
`static` runs `nim r koch tree`, `project` is one matrix job per planned project installing
that project's own pin, `scope` and `commits` run only on pull requests with full history,
and `audit` is a gate reading the results of `plan`, `static` and `project`. Since grown to
nine: `base`, `types` and `driven` joined, and each reaches the merge through that same gate,
which is what has kept the required names unchanged through every job added since. That count
was itself written as eight here, forgetting `base`, and `check.yml`'s own header inherited
the error — which is why the sentence now names every job that joined rather than a total
somebody must recount.
  Every job added since is named in `needs` of the gate as well as declared. A job outside it
  is a red check that cannot block a merge, which is the one mistake this arrangement makes
  easy to make and impossible to see afterwards. The gate exists
because matrix job names vary with the change and so can never be required checks, while
`audit`, `scope` and `commits` must stay required: branch protection needed no edit.
Rejected: renaming the required checks, which would have made the owner reconfigure `main`;
computing the matrix in shell, which is untested glue where koch is tested.
Branch names and event kind reach koch through the environment, never interpolated into the
script. The setup action installs Nim under the runner's temp directory
(`parent-nim-install-directory`), never into the workspace, and `.gitignore` also lists
`.nim_runtime/`, because the audit reads untracked files and a toolchain inside the checkout
was audited as source once (33,367 findings on the first run).

**Ceremony removed, 2026-09-06.** Four places said twice what was said once, or asked a
person to restate what a check proves. Duty 2 no longer records run numbers: branch
protection refuses a red pull request, so "its jobs were green" is guaranteed by the merge
itself, and the numbers expire with the runner's log retention. The pull request template no
longer asks for "paths outside scope: none", which the `scope` job decides and which could
only ever say none, nor for the commit ordering the `commits` job now enforces; both were
replaced by the judgement neither check can make. CONTRIBUTOR.md no longer lists whitespace,
tabs and width among what to check before pushing, since `form` checks all three one bullet
earlier. This project's README no longer copies the bootstrap diagram out of `audit.nim`:
that copy had already lost `toolchain` and `plan` within a day of their arrival, which is
the argument against copies made by a copy.

**`koch audit` removed.** It ran the static pass and then every project's suites. Per-project
pins made it a verb that cannot succeed: one machine holds one compiler on `PATH`, pins
differ, so at least one project reports a mismatch and the verb always exits 1. Chosen
against teaching it to find each pinned compiler, which needs a version-to-path map nobody
asked for. `ci` covers a change, `tests <project>` covers one project, and the CI matrix
sweeps the repository one job per project. Cost: no single local command checks everything,
which is the honest consequence of independent pins rather than a regression.

**`nim r koch ci` is the local form of the jobs.** It fetches `origin/main`, then runs the
whole-tree pass, the planned projects' restores and suites, scope and commits in one
process. Every pull request passes it before it is opened; the runner confirms, it never
discovers. Cost: a network fetch per run, accepted so the base is the one CI will use.
Cost: a curator whose change selects every project cannot run it without every pinned
compiler, which is the price of independent pins.

**Merge-process record.** The make-driven process was verified on 2026-09-05 through pull
requests 1 to 4 (runs 2 to 8, including the re-run trap: a re-run reuses the original merge
commit and workflow file, so a fix on `main` reaches an open pull request only through a
new head). The koch-driven process was verified the same day: pull request 5's three jobs
green (run 33994664255), then the `push` run on `main` after its merge green (run 14,
33995270865). Rejected, and removed from the duty: a throwaway probe pull request opened
only to be closed, which tested nothing those two runs had not.

The per-project-toolchain arrangement was verified on 2026-09-06: pull request 12's eight
checks green (run 25, 34035762337), then the `push` run on `main` after its merge green
(run 26, 34036381241). Beyond passing, that pair showed three things this restructure could
have broken. Required check names survived it: `audit` became a gate reading `plan`,
`static` and the matrix, and branch protection needed no edit, which the merge proved by
merging. `scope` and `commits` skip on a push while the gate still reports, so `main` runs
are not held by jobs that cannot apply to them. And `plan` reads `github.event.before`
correctly on a merge commit: run 26 selected all three projects, which is right, since the
diff against previous `main` is the whole pull request.

Empty matrix verified separately, since neither run took that path: this record's own pull
request 13 changed one record file, so `plan` emitted `[]`, `project` was skipped, and gate
`audit` passed on a skipped dependency (run 34038741080, 2026-09-06). Whole run 22 s. That
gate is written to pass on `skipped` and fail on `failure` or `cancelled`, and until this
run only the first half had ever been exercised.

Three further merge-process changes were verified the same day, each by its own pull request
run and then the `push` run on `main` after its merge: the sweep gate, pull request 14
(runs 30 and 32, both green); the curator reach and regression checks, pull request 15
(runs 31 and 34, both green); and the citation check, pull request 16 (runs 35 and 36, both
green). Each ran against the branch that
introduced it, which is the cheapest evidence available and was taken deliberately: pull
request 15's own `scope` run had to permit its write to a contributor `PROVENANCE.md`, and
its own `commits` run had to accept its own history under the rule it added. Both did.

Known trap, found by pull request 14 merging while 15 and 16 were open: **two stamped
changes in flight produce a third stamp neither carries.** Each re-stamps every project
against its own `CONTRIBUTOR.md`; git merges their edits cleanly when they touch different
sections, but the merged document digests to a value matching neither, so whichever merged
second would have left `main` red on every project. The stamp is doing exactly what it
exists for, and the cure is to stack rather than to discover: merge the earlier branch into
the later one, resolve the `Rules` row of each project — the only place the conflict appears
— to what `nim r koch stamp` reports for the merged rules, and fix the merge order. Done
that way here, digest `912082eea75c768d`, with both pull requests green before either
merged.

## Figures

Measured with `date +%s.%N` around each run, three consecutive warm runs, Linux amd64
container with four Intel Xeon 2.10 GHz cores, Nim 2.2.4 default build, 2026-09-06. Warm
means every test binary was already compiled by a preceding full run.

| Command | Compiles | Wall |
|---------|----------|------|
| `nim r koch tree` | nothing | 0.028 s, 0.023 s, 0.022 s |
| `nim r koch tests curator/probe` | one project | 1.776 s, 1.732 s, 1.832 s |
| `nim r koch audit` (since removed) | every project | 54.156 s, 53.887 s, 53.570 s |

First measurement on the real path rather than a synthetic one: this file's own
merge-process commit, whose only changed path is `curator/audit/PROVENANCE.md`, planned `[]`
and compiled nothing, and `nim r koch ci` finished in 0.721 s wall including its
`git fetch` (2026-09-06, same machine). Before the change the same commit would have cost
the third row below.

That is the pair for scoping, taken on one machine at one commit. Before this change a push
cost the third row whatever it touched; after it, a change to one project costs the second
and a change to records alone costs the first, since nothing is compiled. Roughly thirty
times less for the common case, and it no longer grows as projects arrive, which was the
point. `contributor/sincopa/dance_ontology` is nearly all of the third row, as it was
before.

The earlier figures on this file, 0.245 s and 62.7 s, were taken in a different container
on 2026-09-05 and are not the other half of this pair; they are gone rather than compared.
Re-measure when a project's suites grow; otherwise treat as unmeasured.

**Matrix jobs do run in parallel**, verified on the runner rather than assumed, from the
first run of this arrangement (run 34016823462, pull request 12, 2026-09-06, all eight
checks green). The three `project` jobs started within one second of each other and finished
at 16 s, 52 s and 121 s; the phase took 121 s wall, not the 189 s their sum would be. The
saving is the sum minus the slowest, so it grows as projects arrive, which is the property
that was wanted.

Cost measured in the same run: matrix jobs cannot start until `plan` reports, which put
16 s between the run starting and the first project job. That is a floor on every run,
paid whatever changed, and it is the price of computing the matrix in tested Nim rather
than in shell.

**What the driven check costs, measured locally before the runner ran it once**, 2026-09-07,
same container as the rows above. `koch driven contributor/ronri/rga_visualiser` takes
**2 m 36 s** warm — Atlas restored, node packages cached, faces present, commit-pinned
compiler already built — and reports 135 of 135 checks passed. Roughly two thirds of that is
the harness's own deliberate wall-clock windows and its largest-demo load rather than
anything a faster machine shortens. `assets` costs 1.5 s for six faces over the network.
  This was recorded as a local figure that should not be treated as predicting the runner's,
  and it did not: the runner's `driven` job is **5 m 30 s**, half again the warm local run and
  well over the cold one, on the same checks. The gap is the runner's own — apt install,
  restoring a 2.4 GB compiler from cache, and a slower core — none of which a local run pays.
  The rule that produced the right expectation is worth keeping over the number it produced:
  a figure from one machine predicts another machine's only where what differs has been
  measured, and here it had not been.

**The caching pair is settled, and it is not the pair that was expected.** Four caches now
restore on the driven job — npm's store, Atlas checkouts, the commit-pinned compiler, and the
faces — and the run at 21:49 hit all four, saving the faces for the first time. The compiler
is the whole figure: restoring it is seconds where building it from source is the fifteen
minutes the first `driven` attempt would otherwise have cost, and every other cache is noise
beside it — `npm ci` runs in 2 s cached, and the six faces are 1.5 s uncached.
  So the pair owed since the caching change lands as one number and three rounding errors,
  and the honest form of it is that sentence rather than a table of four rows implying four
  savings. A cold half for npm and faces was never taken under runner conditions and now
  cannot be without deliberately poisoning a key; that measurement is dropped rather than
  left owed.

## Re-audit, 2026-09-07, issue routing

Audited by a curator against the change that made the issue channel run both ways and gave each
session a queue. A session now reads the open issues labelled with its own role before any other
work; a curator who reads this project raises what they find as an issue rather than editing it,
since they may not; an issue labelled with a session's own role is that session's queue, work
decided and deferred where the next session here will see it rather than in a conversation that
ends; and a label is the role string exactly, copied and never composed, because applying a
label creates it and a misspelling makes a second label nobody filters on.

Nothing in this tree changes, and nothing here checks it. koch makes no network call, so the
label rule reaches no check and holds by reading alone; `CURATOR.md`'s "What no check can
reach" says so rather than leaving it implied. A check over a written list of labels was
considered and dropped: it would have held a copy in `README.md` to `projectDirs`, while the
label on GitHub — the thing that actually routes an issue — stayed invisible to it. Applying a
label reveals at once whether it exists, so the proxy bought nothing.

## Re-audit, 2026-09-07, Article II.9 bound

Audited by a curator against the amendment to Article II.9, which bounds when target code may
be hand-written: the source language by default, the crossing kept narrow, and the target
language only where the source cannot reach at all or where crossing would forfeit what the
target gives for free — a check its own compiler makes over the bulk of a file, a cost the glue
would add to a hot path — with the file's opening comment saying which.

This project holds no target-language file, so the rule binds nothing here today. It binds the
moment one arrives, and the `not Nim because` gate already refuses one that argues nothing.

## Re-audit, 2026-09-07, system dependencies

Audited by a curator against the rule that system dependencies — a library the compiler links
against, a tool the build shells out to, a browser a driven check drives, a source clone no
package manager carries — are declared as data in the project's own `tools/build.nim`, each
entry carrying its reason, and reached by a verb. A source clone carries its commit; a system
package carries no pin that survives across distributions, and the record says so rather than
implying one; anything fetched at build time carries a checksum the build verifies. No
machine's paths in committed source.

**The rule reaches this project only partly, and the gap is worth naming.** It speaks of the
project's own `tools/build.nim`; curator projects carry none, since koch drives them. koch's
own system needs are stated in `README.md` instead, which the same rule calls a pointer rather
than a declaration. Making koch declare its own needs as data is a separate change with its own
cost, filed here rather than done quietly.

**One correction found while auditing, and it was mine.** `README.md` said koch "Needs git and
any Nim that builds koch". That understated it: koch shells out to `curl` when it fetches a
compiler, and to `npm` since the `types` verb landed hours earlier — drift this curator
introduced and did not notice at the time. Corrected to name git, curl, and npm where a project
carries a node manifest.

## Re-audit, 2026-09-07, ready is not a one-way door

Audited by a curator against the rule that a pull request already marked ready goes back to
draft before its author adds another commit to it. The rule was asked for by the Architect
after this curator lost a commit to it, and both `CURATOR.md` and `CONTRIBUTOR.md` gained
direction they lacked: each already said open as a draft and mark ready only when ready,
neither said what to do when readiness stops being true.

**The rule is written from measurement, and the measurement is this curator's own mistake.**
Pull request 70 was green and ready at 21:55. The record entry for its own figures was
committed locally at 22:06:30 and never pushed, held behind a nine-minute local `koch ci`; the
merge landed sixteen seconds later. The Architect merged what was green and ready, which is
correct and is what a protected branch exists to allow. The state of the pull request was what
lied: it said merge me while its author intended another commit. The cost was a second pull
request, and a record on `main` that said 135 checks, called the runner figure unmeasured, and
described a gap already fixed.
  What makes this a rule rather than one session's lesson: the signal has to live where the
  other party looks. The Architect reads pull request state; they cannot read a working copy,
  and a commit that is not pushed does not exist to them. The same reasoning issue routing
  already rests on — a session ends and takes its intentions with it, so an intention goes
  somewhere durable.

**Rejected: asking the Architect to wait.** Merging a green, ready pull request promptly is
what keeps the chain moving, and a rule that asks the reader to hesitate over every green one
costs more than it saves. A draft is one click for the author and needs nothing of anybody
else.

**Rejected: a check enforcing it.** Nothing here can see intent. A check could compare pull
request state against later pushes and would only ever report after the fact, which is when it
is already lost. This holds by being done, as the rest of that section does.

**Cost: a rule this curator broke on the same day it was written.** That is worth stating
plainly rather than smoothing over — it is evidence the rule is needed, not evidence it is
understood.
