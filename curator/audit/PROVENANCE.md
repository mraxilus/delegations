# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-05 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 6cef8fc704f7f8f4 |
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

**An allow-list of twelve kinds is the registry, and an unregistered kind is a finding.**
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
guard than compiling everything on every push. Assumed, not yet verified: that the sweep
fires, which only a Monday shows. Parallelism is verified, under Figures.

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

## Tests

**Testament over `tests/t*.nim`, each stub carrying the header from STYLE.md §6 without
`-r`.** Three projects carry suites: this one, `curator/probe`, and
`contributor/sincopa/dance_ontology`, whose eleven stubs dominate every whole-tree run.
Testament runs each binary itself; `-r` in the command would run every test twice
and `--outdir` breaks testament's search for the binary, so binaries sit beside sources and
git ignores them everywhere (`**/tests/t*`). Suites are named after constitution articles
and every assertion carries a citation. Fixtures are built by `fixtures.nim`: a smallest
clean tree with a project under each root, and throwaway git repositories. Verified: 14
test files, all passing on Nim 2.2.4 Linux amd64.

## Continuous integration

**Six jobs, and the three required check names did not change.** `plan` emits the matrix,
`static` runs `nim r koch tree`, `project` is one matrix job per planned project installing
that project's own pin, `scope` and `commits` run only on pull requests with full history,
and `audit` is a gate reading the results of `plan`, `static` and `project`. The gate exists
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
