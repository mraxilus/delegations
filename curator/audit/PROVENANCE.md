# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-06 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 3de2c53c542bac80 |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: built from the owner's brief, the constitution, the Nim style guide and the provenance
guide, all supplied by the owner; reshaped on the owner's direction into two project roots
driven by koch with Atlas for dependencies. No vendored source.

This file describes the checker as it is. How each pass got here is in the log (Article XI.2).
Traps a later curator would otherwise rediscover are kept beside the decision that carries them.

## Build glue

**One compiled driver, `koch.nim` at the root, as Nim's own repository builds.** Dispatch only;
every check is a library module here, tested here. A project needing more verbs carries its own
`tools/build.nim`, which `koch types`, `koch driven` and `koch system` reach through.

- Rejected: make, a second toolchain with recipe tabs and untested glue; NimScript
  `config.nims` tasks, which run in the compiler's VM on a subset of the standard library, load
  on every compile in the tree, can shadow compiler commands such as `check`, and cannot be
  unit-tested; nimble tasks, which need nimble as a runner.
- Cost: a bootstrap compile per checkout, and `koch` is a code file outside any project.
- Verified: `nim r koch` warm run 0.085 s.

## Enumeration

**Git decides what the tree is.** `tree.nim` lists `git ls-files -z --cached --others
--exclude-standard`, drops paths absent from disk, and reads content only for registered kinds.
Git runs as a direct process with an argument list, never through a shell.

- Rejected: `execCmdEx`, which reads by line and appends a newline to NUL-separated output.
- Cost: git must be on `PATH`.
- Verified by `ttree.nim` on a throwaway repository: ignored `bin/` absent, untracked file
  present, accented path unquoted, rename showing as its destination alone.

## File kinds

**An allow-list of fourteen kinds is the registry; an unregistered kind is a finding.**
`kinds.nim` maps basename or extension to comment syntax and whether prose is checked, and its
header table is a derived view of `lut_kind_rule`. Nimble files and NimScript read as Nim; cfg
files as hash comments; `atlas.config` and `atlas.lock` as JSON by basename. Markdown is prose
rather than comment, so articles pass while form rules still apply. TypeScript and JSON are
registered ahead of use. Html and Svg carry hand-written pages, confined by the layout check to
`pages/` or `mockups/` — generated markup is one long line and fails width on its own.

- Retired: Makefile, with make. The registry admits no second build verb, and the recipe-tab
  exemption went with it, so any tab is a finding.
- Rejected: content sniffing, which lets an unknown kind in silently.
- Cost: matching is by basename or extension only, so `nimble.paths` or `.mk` is unread.
- Verified by `tkinds.nim` over every match and five unregistered names; `tlayout.nim` yields
  one finding on `data.csv` naming `curator/audit/src/kinds.nim`.

**A gated kind argues for itself in its header, and the gate is checked rather than trusted.**
`Cpp` and `C` join TypeScript as languages admitted only where Nim cannot serve; `.hpp` reads
as C++ and `.h` as C, since the name alone cannot tell them apart. `justification.nim` demands
`not Nim because <reason>` in the opening comment run — gaps of one line allowed, so an include
guard above the block and a blank line inside it both keep the run whole. Before this, the gate
was a sentence in CONTRIBUTOR.md, so a second language registered "under the same gate as
TypeScript" would have been under no gate at all.

- Rejected: the marker anywhere in the file, which admits an argument buried at line 900; the
  marker on line 1 exactly, which forbids `#pragma once`; a separate register of justified
  files, a second place for truth to drift from.
- Cost: the check proves a justification exists where a reader will meet it, never that it is
  true; a curator still weighs the claim.
- Cost: the one-line gap can reach a comment on the first line of code — deliberate, since the
  alternative is a finding on a correct header.
- Verified by `tjustification.nim` and `tkinds.nim`, and driven over real files, 2026-09-06: an
  unjustified `shim.cpp` and `glue.ts` each yield one finding at line 1 and fall silent once the
  phrase is added.

## Comment extraction

**Five hand-written scanners, one per-line accumulator.** Nim: line, doc, nesting block
comments, plain, triple and generalized raw strings, char literals, numeric suffix quotes. Cfg:
`#` unless `\#`. YAML: `#` at line start or after whitespace, outside quotes. Ignore files:
leading `#` only. TypeScript: `//`, `/* */`, three string forms, doc stars stripped. Markup:
`<!-- -->`, spanning lines. Whitespace runs collapse so texts compare stably.

- Rejected: real parsers, which cost dependencies for a question needing no syntax tree.
- Cost, assumed: a TypeScript regex literal containing `//` opens a false comment.
- Cost: the markup scanner reads `<!-- -->` only, so comments inside `<script>` and `<style>`
  stay unread — the same blind spot markup hosted in a Nim string already carried.
- Verified by `tcomments.nim` across the syntaxes, including the testament header string and
  markup comments spanning lines.

## Prose

**Articles are the whole rule, as data.** `ARTICLES = ["a", "an", "the"]`; tokens are
whitespace-split, punctuation-stripped, lowercased, after backtick spans are removed.

- Cost, found on the first build: the label `A`, as in "Appendix A", is flagged; `prose.nim`
  tripped on its own example and writes the label in backticks.
- Verified by `tprose.nim`: 300 seeded random telegraphic comments pass, each with one inserted
  article fails; citations `2.2a`, URLs and underscored names pass. The corpus is seeded with
  `randomize(0)`, so the 300 are the same 300 on every run — the only sampled corpus in this
  project, and the reason its verdict does not vary (CONTRIBUTOR.md, "Tests are paramount").

## Form

**Width is counted in runes; any tab, any CR, and any ending but exactly one newline is a
finding.** An over-long line passes only when breaking cannot fix it: its longest
whitespace-free token with the line's indent already overruns, that token is within `TOKEN_MAX`
(400 runes), and the rest fits once it is removed. A font URL has no whitespace to break at;
prose always does; minified markup is one run far past the bound. Lines split on LF only, so CR
survives. Nim banners need two blank lines before and one after; tiers are unmarked in syntax,
so the second-tier minimum is demanded of every banner.

- Rejected: exempting URLs by pattern, which guesses at intent; exempting any single-token
  line, which admits machine output of any length; `splitLines`, which swallows CRLF.
- Cost: a long identifier gets the same exemption a URL does, since neither breaks at
  whitespace. `LICENSE.md` is width-exempt, third-party text staying verbatim.
- Assumed, not checked: two-space indent.
- Verified by `tform.nim`: 100 runes pass, 101 breakable runes fail; a 202-character fonts link
  passes while 207 of prose and 400 of minified markup do not; tab in Nim and cfg fails; every
  ending case. Driven on real pages, 2026-09-05: 391 markup lines and a fonts link whose longest
  token is 179 runes audit clean, while a generated 1,407-character drawing does not.

**A generated npm lockfile passes the width rule, measured rather than assumed.** Before
CONTRIBUTOR.md could demand a committed `package-lock.json`, one was generated and audited:
93 lines, longest 117 runes, **0 findings** (npm 12, 2026-09-06). The unbreakable-token rule is
what saves it — the long lines carry one `sha512-` digest of 95 runes and fit without it — so
the shape holds at any lockfile size. That is why the rule needed no exemption beside
`LICENSE.md`.

## Layout

**Two project roots, each holding README.md and folders only, every folder checked at its
depth.** A project is `curator/<project>` or `contributor/<domain>/<project>` and must hold
README.md, PROVENANCE.md, GLOSSARY.md, exactly one nimble file named after the folder, and at
least one file under `tests/`; a nimble file requiring packages demands `atlas.lock`. The root
README carries one row per domain equal to `DOMAINS`; each root README opens with its folder
name; each domain README opens with the domain name and holds the theme line. A committed page
sits under `pages/`, what the project stands behind, or `mockups/`, an exploration kept for
reference — declared by directory, never inferred from content.

An unknown root directory, a stray file in a root or domain folder, and an unregistered domain
are findings, never skipped: an earlier form returned early under `curator/` and dropped unknown
heads silently, so a misplaced project vanished from the audit.

- Rejected: domain READMEs listing projects, which forces a contributor to edit outside their
  prefix; a theme line for root READMEs, a fabricated authority; inferring mock-up from
  generated, which makes the distinction an accident of formatting.
- Cost: empty directories are invisible to git, so `tests/` must hold a file.
- Verified by `tlayout.nim` over a fixture tree the tests build, with the project list pinned
  and the unknown-domain case asserting both the finding and the unchanged list; `taudit.nim`
  proves that fixture clean under every static check.

**Only one check reads substance, and it reads a narrow slice.** `checkCitations` resolves
every claim opening `Verified by` and naming a backticked `.nim` file in a project's
`PROVENANCE.md` against that project's `tests/`. Chosen because the record's most valuable
property is its verified-versus-assumed split, and nothing stopped a citation rotting when a
suite was renamed.

- Rejected: matching the claim against what the test asserts, which no checker can do; flagging
  every backticked span, which would catch commands such as ``atlas changed`` — the `.nim`
  ending is the guard.
- Cost, the honest limit: a delegate can cite a real test beside a claim it does not make. That
  gap closes by reading.
- Verified by `tprovenance.nim`, and driven on this repository: all nineteen citations on `main`
  resolve, while renaming one to an absent file, a source file, or another project's test each
  reports one finding.

## Provenance stamp

**FNV-1a 64-bit over CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md**, CR stripped, NUL between
files, 16 lowercase hex digits. CURATOR.md is excluded, so curator-only edits touch no project.

- Rejected: `std/sha1` (deprecated in Nim 2, warns on every build); the `checksums` package (a
  nimble install in CI for one digest); `std/hashes` (unstable across Nim versions).
- Cost: a change detector, not a signature; collision needs an adversary.
- Verified by `tprovenance.nim` for determinism, one-byte, order and boundary sensitivity and
  CRLF invariance; by `taudit.nim`, one byte in any rules document goes stale in every project
  and one byte in CURATOR.md in none.

## Glossary

**Shape only: heading, `## Language`, and a definition line after every `**Term**:`.** Content
is the contributor's and the Architect's; a term enters only when the Architect selects it. The
check cannot know what was agreed, so agreement holds by reading. It runs on the top-level
`GLOSSARY.md` too. Zero terms pass, because the format creates entries lazily. Verified by
`tglossary.nim`.

## Branch scope

**Branch grammar mirrors paths: two, three or four segments, and the prefix decides.**
`curator/<name>` owns the empty prefix, so every path passes; `curator/<project>/<name>` and
`contributor/<domain>/<project>/<name>` own their folder. `main` passes because pushes to it are
merges the owner approved.

- Rejected: a special case for the curator root; the empty prefix is one mechanism.
- Cost: fixed segment counts reject nested branch names; the owner may merge red deliberately,
  so this is a guard, not a gate.
- Verified by `tscope.nim` over five domains, one curator project, the curator root and two
  rejected forms; `tdomains.nim` over 18 rejected branch forms.

**Curator reach into contributor projects stops at their records.** Under `contributor/`, the
only writable paths on a curator branch are `README.md`, `PROVENANCE.md` and `GLOSSARY.md` —
`PROJECT_FILES`, read from `layout.nim` rather than repeated. That empty prefix was the one hole
in an otherwise mechanical system, and it belonged to the most-run role: duty 9 forbade writing
contributor code and nothing but reading held it.

- Rejected: restricting to `PROVENANCE.md` and `GLOSSARY.md` alone, which the toolchain
  propagation disproved — it removed "Needs Nim 2.2.4" from three contributor READMEs, prose
  the rule itself invalidated, and the tighter set would have blocked it.
- Cost: the README stays writable, so restraint about rewriting a project's prose is duty 9's
  to govern by reading, never the check's.
- Verified by driven check: a curator branch touching `dance_ontology`'s source reports one
  finding naming the path; the same branch touching its `PROVENANCE.md` and `README.md` reports
  none.

**A curator may move a contributor's files, never edit them.** `tree.movedPaths` reads
`--name-status --find-renames=100%` and `checkScope` exempts exactly those paths on a curator
branch, so only an exact rename qualifies and an edit disguised as a move is still caught.
Renaming a domain is a registry change and the registry is the curator's; moving files is the
consequence, never authorship. Cost: a curator may reorder a contributor's files without asking
— content cannot change and the move is visible in review, so the cost is disorder rather than
damage.

**Domain folders are ASCII slugs; the accent lives in the display name.** Folder `sincopa`,
name `síncopa` — the split `comma_games` and `comma, games` already used. Git quotes a non-ASCII
path by default, so `git ls-files` piped into any shell tool fails on it, which had forced a
`core.quotepath off` instruction on every delegate; that instruction is gone with its cause.
macOS stores such a name as NFD, so the same folder has different bytes there. A `static`
assertion in `domains.nim` holds every folder to `isProjectName`, failing the build rather than
the suite (Article IV.4). Cost: 72 files moved, and the old prefix `contributor/síncopa/...` no
longer parses.

**A branch must carry base's rules and checker before it may merge.** `base` reads what the base
gained since the branch forked and reports a branch predating a charter document or the checker.
Pull request 11 was green against the `main` of its day, merged into a later one, and arrived
carrying a stamp three rules changes had falsified; the run failed and nobody was told. GitHub
prevents this with "require branches to be up to date", which is behind paid rulesets — `base`
feeds the `audit` gate branch protection already requires, so no setting changed.

Only two kinds of path count: a charter document moves the stamp every project claims, and the
checker decides what the audit accepts. Everything else may differ freely.

- Cost: merging a rules change reddens every open pull request until each merges the base. That
  is the paid setting's cost too, and it fires exactly when staleness is real.
- Cost, the honest limit: this reads at pull request time, never merge time, so a branch green
  at ten can merge at five past after another lands. Only a merge queue closes that, and that is
  the paid feature again.
- Verified by `tbase.nim`, and by replaying the incident: pull request 11's branch against
  today's `main` reports the finding naming `CONTRIBUTOR.md`, five check sources and `koch.nim`;
  against its own fork point it reports nothing, which is why its run was green at the time.

## Commits

**`type(scope)!?: summary`, eleven types as data; on a project branch the scope must equal the
project.** The curator root accepts any valid scope, because propagating a rules change commits
under each project's scope. A branch outside the grammar still gets format checking. Cost:
imperative mood is unverified. Verified by `tcommits.nim`: every type with three scopes, the
breaking marker, 11 rejected forms, scope enforcement on both project branch forms.

**The regression rule is enforced, not hoped for.** `commits` reads subjects newest first and
demands every `fix` carry an earlier `test` of the same scope on the same branch (Article IX.8),
because "every mistake becomes a test" was the Architect's stated priority and lived only in
prose.

- Rejected: matching across `main`'s history, which needs the whole log and would still pass a
  fix whose test landed years earlier under a different intent.
- Cost: a fix whose test already sits on `main` needs a test here or another type. The escape is
  honest — a change needing no new test is not a `fix`.
- Verified by driven check: a branch carrying `fix(audit)` alone reports one finding; the same
  branch with `test(audit)` first reports none.

## Assets

**One declaration of every file fetched at build time, in `assets.nim`.** CONTRIBUTOR.md already
names the class — *"binaries are never committed, and neither are fonts, images or any file the
audit cannot read"*, each recorded with origin, version, licence and checksum. The store is that
class kept once rather than once per project.

Faces are the only instances today, and the rows say so by grouping rather than by column: the
shape is file, address and digest, which is what any such file needs and no more. **An asset
wanting a field this row lacks — unpacking, a variant set — is a change rather than something this
shape already answers**, and the header says so rather than implying it is settled for all time.
The name was generalised before either project adopted it, since renaming afterwards would have
meant coordinating three pull requests across two projects a curator may not edit.

The reason it exists at all: Article X.8 gives three families to every presentation target, so
the second target repeats the first target's pins — and it did. `rga_visualiser` and
`dance_ontology` each pinned four of the same files, byte for byte, in their own
`tools/build.nim`. Article II.9 calls that a copy no real constraint forces and
asks each copy to name its siblings; neither did, and nothing could have told them from two
different faces (repository issue 116).

- **The digest is the curator's, the choice is the project's.** The store says what bytes
  `noto-sans-latin-400` is; it never says which faces a target wants, and the targets differ — one
  draws maths and symbols, the other italic serif. What stops being written twice is only what was
  already identical, so the per-project autonomy CONTRIBUTOR.md argues for is untouched.
- This is the repository's **first shared build input**, and stays the only one. Compilers are
  pinned per project in nimble files, Atlas checkouts per project, npm per project, deliberately.
  The bytes of a face are not a toolchain: they are the same file whoever fetches them.
- **Keyed by digest, never by name.** Two projects asking for one face share one entry by
  construction, and a moved pin is a different entry rather than a stale one — the same property
  `check.yml` gets from keying its cache on the file holding the digests, one layer down. The
  store sits at `~/.cache/koch/assets`, beside `~/.cache/koch/nim` and outside the checkout,
  because audit reads untracked files.
- The rows are the union of two tables that already agreed: where both projects pinned one file
  they pinned the same digest, and **that agreement is what made one table safe to write** rather
  than a merge that had to pick a winner. Fifteen faces, nine `woff2` for pages and six TrueType
  or OpenType for the desktop atlas, which `@fontsource` does not ship.
- Verified by driving it, and by breaking it. Cold store, three faces including two that both
  projects shared: **1.0 s**. Warm, same call: **0.117 s**, fetching nothing. Three files, one per
  digest. A face nobody declares is a finding naming the table to add a row to. And with one
  declared digest altered in its last character, the fetch refuses the bytes and **leaves the
  store empty** rather than keeping them.
- Cost: the store grows and nothing prunes it. A face is ~30 kB where a compiler is ~300 MB, so
  what is unbounded is the number of pins the repository has ever held, not the bytes.
- Cost: an upstream that moves bytes under one address now fails every project at once rather
  than one. That is the same failure a digest exists to make loud, and it is louder shared.
- **The Nim tarball is deliberately not here.** It is fetched and checksummed too, but its digest
  comes from upstream's sidecar at fetch time rather than from this table, and it is stored
  *unpacked by pin* because the rest of koch resolves toolchains by pin. Different trust model and
  different key, so `compilers.nim` keeps it rather than this pretending one shape serves both.

## Toolchain

**Each project pins its own compiler; there is no repository-wide Nim.** `requires
"nim == <version>"` in the project's nimble file, read through the same `requireLiterals` scan
`dependencies.nim` uses, so requirements are parsed in one place. That no single version serves
every project is measured, not feared: `rga_visualiser` depends on a library 2.2.4 cannot
compile, and `dance_ontology` crashes the compiler itself on 2.2.8, 2.2.10 and 2.2.12 in
six of its twelve suites (repository issue 106).

- Rejected: one pin for the repository, which cannot hold both; `>=`, which cannot express the
  upper bound `dance_ontology` needs nor say which compiler a suite passed on; a `.nim-version`
  file, a second place a version lives beside the nimble file already naming one.
- Verified that Atlas accepts an exact compiler pin rather than resolving it as a package:
  `atlas --noexec rep` cloned and set the pinned commit and `atlas changed` exited 0 (Atlas
  0.9.0, 2026-09-06).

**A pin may name a commit as well as a version** — forty lowercase hex characters, as
`atlas.lock` records commits. Asked for by `rga_visualiser`, whose dependency spells its
operators in prefix form on its head, needing a lexer change on `devel` and in no release.
`isCommit` is tested before `isVersion`, since forty digits satisfy both and the absurd version
loses.

- Rejected: a bare `devel` label, a moving target recording nothing; a dated nightly, retained
  only for a window, so an old pin stops installing and the record stops being reproducible.
- Cost: no action installs a compiler by commit, so it is built from source and cached by commit.
- Cost: the driver project may not pin a commit, since every other job waits on the one the
  setup action installs; `checkDriver` reports it.

**The driver version is derived, never a second pin.** `NIM_VERSION` in `check.yml` builds koch
and runs the whole-tree pass, and `checkDriver` fails the audit unless it equals
`curator/audit`'s pin, because koch compiles that project's modules — the same derived-view rule
`layout.nim` applies to the domain table. Verified by driven check: `NIM_VERSION` of `2.2.6`
against a `2.2.4` pin reports one finding at the workflow, and restoring it clears.

**A pin moves on evidence, and the evidence is a run rather than a release note.** The curator
projects moved `2.2.4` → `2.2.12` on 2026-09-09, five patch releases and seventeen months, after
a sweep for versions nothing here should still be running. No release in that series carries a
CVE — Nim assigns none — so the reason is what the notes carry between 2.2.6 and 2.2.12: SIGSEGV
under ARC/ORC and under refc, a use after free, an overlapping `copyMem`, and overflow checks
that could be escaped.

- Verified by running, not by reading: 23 audit suites and 2 probe suites pass on 2.2.12, in
  41.0 s and 10.0 s on this container, before the pin was pushed anywhere.
- `dance_ontology` does not follow, and its `2.2.4` is an upper bound rather than neglect. The
  cause is now measured rather than assumed: `opcAddFloat` at `vm.nim:1095` reads an operand the
  VM left `rkInt`, because since 2.2.8 a `func` whose implicit `float` result is read by `+=`
  before it is ever assigned gets an int register for it. Five lines reproduce it with nothing
  of that project in them, `result = 0.0` first is enough to avoid it, and all twelve of its
  suites then pass on 2.2.12. Handed over as repository issue 106; the line is theirs to write.
- Cost: koch's own modules compile under both pins for as long as the two differ, since every
  project's job installs its own. The matrix is what proves that, rather than this paragraph.

**Koch resolves each pin to its own compiler, and fetches one it lacks.** `PATH` when it already
serves, then `~/.cache/koch/nim/<pin>/bin`, then a fetch: a release as a tarball, and a commit —
or any platform nim-lang.org publishes no build for — by cloning `nim-lang/Nim` and running
`sh build_all.sh`, the recipe `check.yml` already used. The cache sits outside the checkout
because the audit reads untracked files. `$KOCH_NIM_DIR` moves it.

Before this, `runJobs` read the single compiler on `PATH` and reported a finding for every
project whose pin differed, so `nim r koch ci` could not be green as one command whenever the
changed set spanned two pins — the ordinary case, since any change under `curator/audit/src/`
selects every project.

Two traps, both found by driving rather than reasoning, and both changed the code.

- **A half-built toolchain lies.** Probing `bin/nim` before `koch boot` finished returned the
  csources bootstrap binary, which answered `--version` with an unrelated commit. A source build
  now completes beside its destination and moves in only when done, as the tarball path did.
- **Naming a tool by path is not enough.** Atlas resolves `nim` through `PATH`, so the
  toolchain's own Atlas read whichever compiler `PATH` held and warned `environment mismatch`.
  Children now run with the toolchain's `bin` leading `PATH`. A tool absent from a toolchain
  falls back to `PATH` rather than raising, since what `koch tools` produces moves between Nim
  versions.

- Rejected: a directory the developer populates by hand, which leaves the defect for anyone who
  has not; `choosenim`'s layout, a second convention that cannot serve a commit pin at all.
- Costs: the checker reaches the network and may build a compiler — seconds for a release,
  minutes for a commit, once per pin; each cached toolchain is a few hundred megabytes and
  nothing prunes them.
- CI is untouched: every job's installed compiler already satisfies its `matrix.nim`, so
  resolution stops at `PATH` and never fetches.

**The fetched tarball is checked against the digest published beside it.** This paragraph used to
record the opposite as a cost — trusted on TLS alone, "because Nim publishes none in a form worth
parsing" — and that was simply wrong. `<tarball url>.sha256` is exactly `sha256sum` output, for
every release checked, and `fetchRelease` now fetches it and refuses a tarball whose bytes differ.

- What it defends against, stated rather than overclaimed: the digest comes from the same host
  over the same TLS as the tarball, so it catches a truncated, mirrored or swapped file, **not a
  compromised nim-lang.org**. A signature would answer that; none is published — `.asc` beside
  these tarballs is a 404, read rather than assumed.
- Text that is not a digest reads as *nothing* rather than as a digest that cannot match, so an
  error document or an empty answer reports "none published" instead of "mismatch". The two are
  different failures and say different things to whoever reads the line.
- `KOCH_SYSTEM` gains `coreutils` for `sha256sum` — and `tar`, which `fetchRelease` has always
  shelled out to and the original declaration missed.
- Verified by breaking it, not by a fetch that happened to pass: `tcompilers.nim` digests a
  temporary file, changes one byte and checks the digest moves; and the parse is mutation-tested —
  dropping its hex validation reddens the suite. Driven end to end 2026-09-10: `2.2.2`, which
  nothing on this machine served, fetched, digest-checked and unpacked in **4.6 s**.
- Honest limit of that test: the `sha256sum` exit-code check is belt-and-braces, since the parse
  already rejects the error text, so no test distinguishes it. Kept for saying what it means.
- Verified by `ttoolchain.nim`, `tcompilers.nim` and `tprojects.nim`, and driven end to end,
  2026-09-06: `curator/probe` pinned to 2.2.6 with nothing local serving it fetched the tarball
  and ran in **7.6 s** cold, 3.0 s warm; then one command with only 2.2.4 on `PATH` and four
  projects across two pins, **0 findings in 3 m 37 s**, no Atlas mismatch warning in the log. A
  pin nothing can serve is one finding naming the pin and the cache it tried, not a crash.

## Dependencies

**Atlas per project: requirements in `<project>.nimble`, checkouts in ignored `deps/`, exact
commits in committed `atlas.lock`, paths in committed `nim.cfg`.** `koch deps` runs
`atlas --noexec rep` in every project holding a lock and judges success by `atlas changed`
exiting zero.

- Rejected: one Atlas project at the root — Atlas 0.9.0 has no shared-workspace model, a root
  `nim.cfg` would leak every dependency into every project through parent-config lookup, and
  the constitution wants each dependency justified where it is imported (II.8).
- Costs, verified in the spike: Atlas clones nim-lang/packages before any command, so it needs
  the network even for zero packages, which is why lock-less projects skip it; `atlas rep` exits
  1 after restoring because its submodule step fails, hence the `atlas changed` verdict; a
  dependency used by two projects is cloned twice.
- Verified by `tdependencies.nim` for the parser and the lock-less skip. The Atlas command flow
  was verified by hand on a throwaway project, 2026-09-05, and stays assumed for CI until the
  first real dependency lands.

**`atlas changed` alone does not prove a restore happened.** It exits 0 while warning `repo
missing!`, so a restore that fetched nothing reported success. `checkCheckouts` reads the `dir`
of every lock item, resolves `$deps`, and demands the directory exists before `atlas changed` is
consulted. Measured on Atlas 0.9.0 by deleting `deps/` and re-running. Cost: the lock is parsed
twice per restore. Verified by `tdependencies.nim` over a project with and without the
directory, and over a lock that is not JSON.

**The lock silently reverts an edit to the nimble file.** `atlas.lock` stores a whole copy of
the nimble under `nimbleFile.content`, and `atlas rep` writes it back over the file, so a
requirement edited without regenerating the lock is undone on the next `koch tests` or
`koch ci`. Nothing fails at that moment, so the loss surfaces later as a `koch tree` finding on
a reverted line the contributor never wrote. Reported by `rga_visualiser` as issue 25 and
reproduced here. `checkLockNimble` compares the stored copy against the committed file and
reports the first differing line.

- The comparison runs in the static pass over the tree as git holds it. Run after `restoreAll`
  it would compare the file against the copy it had just been written from, pass always, and
  cover nothing — the defect `atlas changed` already taught.
- The finding points at the nimble file rather than the lock, because that is the file the
  restore overwrites and its line numbers resolve.
- Costs: a project changing a requirement must regenerate the lock or make the stored copy
  match; `atlas pin` writes `"items": {}` for a dependency whose repository carries no nimble
  file, so a hand-patch stays necessary until Atlas changes; a lock storing no copy is compared
  against nothing.
- Because it composes a check that reads JSON, which Nim marks effectful, `auditTree` is a
  `proc`; every rule it composes stays pure and `layout.nim` still reads paths only.
- Verified by `tdependencies.nim`, and driven against the real lock: a stored copy holding
  `nim >= 2.2.6` names `rga_visualiser.nimble:13`, and the restored lock is silent.

## Scoped checks

**The static pass stays whole-tree; only compilation is scoped.** A project enters the test set
when a changed path under it is anything but its three records (`PROJECT_FILES`), and a change
to `koch.nim`, `koch.nim.cfg` or `curator/audit/src/` selects every project, because how each is
checked changed. A path inside no project selects nothing by itself. Chosen against scoping the
static pass on the figures below: it is hundredths of a second against tens of seconds of
suites, so scoping it buys nothing measurable and costs a second code path plus the whole-tree
layout and stamp guarantees. Rules propagation therefore compiles nothing while every stamp is
still checked.

- Cost: a merged change can leave an unrelated project red until it next changes; the weekly
  sweep is the guard, and it is weaker than compiling everything on every push.
- Cost, and it is deliberately the safe side of the trade: `isChecker` reads the path, never
  the content, so editing a comment in `koch.nim` or under `curator/audit/src/` selects every
  project. Measured 2026-09-08: a pull request whose only changes to those two files were doc
  comments compiled four projects and drove a browser, 674 s, where the same tree's other
  commits compiled nothing. The machinery to do better exists — `comments.nim` already
  extracts comments per kind, so `plan` could ask whether anything but comments changed — and
  it is rejected, because that detector errs toward compiling too little. A wrong "comments
  only" reports green for work it never did, which is the failure this repository refuses
  everywhere else, and the reason `nimcache` is still uncached. Eleven minutes is the price of
  erring the other way.
- Verified by `tplan.nim`, and driven against this repository's history: a README-only commit
  plans `[]`, and a one-line source change plans that project alone.

**The sweep fires, and it promises a day rather than an hour.** Observed 2026-09-07, the first
Monday after the cron landed: all four projects planned, each on its own pin, four jobs starting
within one second, the phase finishing in about four minutes against about nine summed. It fired
**6 h 09 m after its 06:00 slot**, which is what GitHub does with `schedule` under load — so a
curator reading the cron and returning at 06:05 finds nothing and wrongly concludes the guard is
broken. Waiting is part of reading this signal.

**The sweep skips itself in a quiet week**, planning every project when any code merged inside
`SWEEP_DAYS` and nothing when none did, judging "code" by the record-file exclusion scoped runs
use. Rot arrives with merges, and compiling four projects to confirm a quiet week is runner time
for no information.

- Rejected: sweeping the projects that changed in the window, which the push runs already did
  and would miss exactly the cross-project rot the sweep is for.
- Cost: rot from outside the repository — a runner image moving under a pinned compiler — goes
  unseen through a quiet week.
- Cost: the window is named twice, as the cron and `SWEEP_DAYS`; nothing checks they agree, so
  CURATOR.md duty 7 says to change them together.
- A repository younger than the window has every commit inside it, so the skip is verified by
  suite rather than a live Monday: `tplan.nim` drives the decision over code, record-only and
  empty changes, and `ttree.nim` drives `revBefore` at both ends.

## Project runner

**`testament --nim:<absolute> pattern "tests/t*.nim"` in each project directory, serially,
output streamed.** Koch holds the verb once; no per-project build file exists. The compiler path
is absolute because testament resolves `--nim` against its working directory. Failure is a
finding at the project's `tests` directory echoing the exit code. Each project carries a
`Target` — its directory and the `bin` of the toolchain serving its pin — and tools come from
that `bin` rather than `PATH`, since two projects on two pins would otherwise share one compiler
silently. Cost: serial; a project in another language needs its own runner arm. Verified by
`tprojects.nim` with a passing and a failing fixture driven through real testament.

## Tests

**Testament over `tests/t*.nim`, each stub carrying the header from STYLE.md §6 without `-r`.**
`-r` would run every test twice, and `--outdir` breaks testament's search for the binary, so
binaries sit beside sources and git ignores them everywhere (`**/tests/t*`). Suites are named
after constitution articles and every assertion carries a citation. Fixtures are built by
`fixtures.nim`: a smallest clean tree with a project under each root, and throwaway git
repositories.

Every project carries suites: 22 files here, one in `curator/probe`, three in
`rga_visualiser`, twelve in `dance_ontology`, whose stubs dominate every whole-tree run. Counted
from `git ls-files` rather than by hand, which is how an earlier count of three projects and
fourteen files went stale. Verified by running `nim r koch tests` over every project,
2026-09-08: 39 suites pass, 0 findings, each on the compiler its project pins — only one of the
three pins was on `PATH`, which is the point of that verb.

## Type checking

**The runner reaches every project's TypeScript through that project's own verb.** `koch types`
restores node tools from the project's lock and runs `tools/build.nim types`, which derives
whatever those scripts read and type-checks every configuration, stopping before anything
needing a browser. Koch names the verb and nothing else, since what checking needs differs per
project while the name need not.

- **Enrolment is derived, never listed.** `nodeDirs` selects projects holding `package.json`
  beside `package-lock.json`, so a project enrols by carrying them and no second list can drift.
  The lock is demanded because `npm ci` needs one, and unpinned tools would be the one thing
  here that nothing pins.
- **No pin is resolved and no toolchain fetched**, because `tools/build.nim` compiles no project
  code — it derives declarations by reading source as text — so building a commit-pinned
  compiler to run a build script would cost minutes for no checking. Cost, and the condition it
  rests on: this holds only while a `types` verb compiles no project code. One that did would
  need its pin and become a matrix job.
- **Scoped, unlike `tests`.** With no matrix, scoping lives in the verb, which takes the
  projects one change asks for by the `testSet` rule; `--all` drops that for the sweep.
- **Absent npm is a finding naming it, never a skip**: a check that quietly does nothing reports
  green for work it never did.
- Driven against the regression it exists for, 2026-09-07: renaming `nimSceneHandles` to
  `nimSceneSlots` and touching nothing else reports one finding over `TS2304` at four sites in
  `construct_section.ts`; reverted, 0 findings. The whole verb costs 11 s cold, `npm ci`
  included.

## Driven checks

**The runner drives what the suites cannot reach, through that project's own verb.** `koch
driven` restores a project's checkouts and node tools, then runs `tools/build.nim drive`: the
verb builds the page and drives it through held keys, wheels, right-button pans, two-finger
pinches and long presses. Testament tests rules — what a slide does to the pivot — and nothing
in it presses a key, so a rule wired to the wrong event is the class of defect no suite here
could see. `rga_visualiser` had 135 such checks and the runner ran none, which made every one of
them evidence that its author ran it.

**Enrolment is the verb, read from the project's own driver.** `verbDirs` reads the dispatch of
`tools/build.nim` and selects projects naming `drive`, the derivation `nodeDirs` uses one step
earlier. The parser is not a second one: `dispatchVerbs` already read koch's own dispatch and
now takes the opening line as an argument, since koch cases over parsed options and a project
driver over its first argument. Cost: a project spelling the verb otherwise is passed by in
silence, which is why CONTRIBUTOR.md names `drive` and `system` outright.

**It is a matrix on each project's own pin where `types` is one plain job, and that difference
was measured.** The first cut mirrored `types` on the same argument. Running it refuted that in
thirteen seconds: `drive` calls `web`, which runs `nim js` over `bridge.nim`, which compiles
project code and everything it imports, so `rga_visualiser` on the driver's 2.2.4 fails inside
`pga`'s `multivectors.nim`, whose syntax only the pinned commit can lex. The type-check record
had written down the exact condition it rested on, and this is that condition arriving. So
`driven` is planned like `tests`: `plan --driven` filters what `plan` already selected, which is
what makes it inherit scoping, `--all` and the sweep.

**System packages are installed from the project's declaration, never from names in the
workflow.** `koch system` runs each selected project's `system` verb and prints the union,
sorted and deduplicated; the job pipes it into `apt-get`. Koch prints and never installs,
because which package manager serves a name is the machine's business while the list is the
project's. Only bare names survive the read: the contract is one name per line, and the one
other thing reaching that stream is the compiler complaining, which always spells a position
first, so a line carrying whitespace is dropped. A compiler that complained still fails, since
the absent package names itself.

**The shared store is cached, and `build/fonts` no longer is.** `koch assets` fetches into
`~/.cache/koch/assets` and that store is the repository's, so the cache keys on its declaration —
`curator/audit/src/assets.nim` — and one entry serves every project's job rather than one per
project. What moved is where the cost is: the fetch is 6.6 s cold and the copy into `build/fonts`
is milliseconds, so keying on a project's driver cached the cheap half and missed the expensive
one, which is what repository issue 132 raised with the figures.
  A looser `restore-keys` prefix is safe here by construction rather than by check, which is
  unusual and worth stating: the store names entries by digest, so an entry no row declares is
  unreachable rather than wrong, and `koch assets` fetches whatever an older restore lacks.
  Populated and not yet proven: on its first run, 235, `assets-Linux-…` found nothing to restore
  and saved on the way out, which is what a cache created one pull request earlier does. Its test
  is the next `driven` run. What that run did settle is that dropping `build/fonts` costs nothing —
  `Wrote build/fonts (12 faces, 12 copied)` then `(12 faces, 0 copied)`, since `assets` runs twice
  per job and the second pass finds every face already in place.

**The browser a declaration names is the browser that runs, and the snap serves.** `apt-get
install chromium` on `ubuntu-latest` gives `/snap/bin/chromium`, a wrapper rather than a plain
binary, and whether Playwright would launch one was unknown while this was written. It launches.
Recorded because the opposite result had a different owner: a package that did not serve the
runner would have been the project's declaration to change, never a name quietly substituted
here.

Verified on the runner, 2026-09-07, the only place the claim means anything: **136 of 136
checks passed, 0 findings, in 5 m 30 s**, in a real Chromium over real gestures, with `audit`
reading its verdict. Verified locally first by the same verb, 2 m 36 s warm and 3 m 31 s on a
tree whose `build/` was removed. Verified by breaking: on the driver's 2.2.4 the same command
fails inside `pga`, which is what sent this to a matrix. Verified by the gap it found before it
ever went green: on a cold checkout the first run stopped at `Missing face … run 'assets'
first` — every expensive step done and one cheap one missing, because `drive` chained `web`,
`types` and `declare` but not `assets`. Invisible to its author, whose `build/fonts` was always
there.

## Watching main

**Red `main` opens its own issue, because remembering to look had already failed twice.**
CURATOR.md's session-start duty said to read the latest `push` run and named its own hole in the
same breath -- *"nothing else watches it"*. A contributor's merge went red with nobody looking and
was found by accident twenty-four minutes later; then the driven job was red on two `main` runs
while the curator who had named that run as the leg still to read did not read it. Both times
enforcement was somebody remembering, and failure was silent.
  `watch.yml` reads the run and opens issue labelled `curator` when it concludes failure, which is
  same session-start duty's first read. No new rule: existing rule now produces artefact rule
  already asks next session to read, and repository's own answer to session ending and taking its
  intentions with it is issue labelled `curator`.
  Separate workflow because run cannot watch its own outcome. `workflow_run` fires only from copy
  on default branch, so it cannot be driven from branch at all -- which is why it also takes
  `workflow_dispatch` naming run to read.
  One issue rather than one per red run, since watcher opening issue per run trains its reader to
  skim, which is failure it exists to prevent. Marker in body is what makes later red comment on
  first. Open issues are read directly rather than searched, since cold search index would produce
  exactly duplicate being avoided.

**It left CURATOR.md's list of what no check can reach, which is direction that list moves.**
That section held four rules and described fifth without listing it. Test for membership is now
written there: not whether check would be awkward, but whether rule turns on fact something
already writes down. Run's own conclusion is one. Glossary term's agreement is not.

**`permissions` block is whole grant, never addition to default.** Scope left out of it is set to
`none`, not left alone. Written without `actions: read`, first firing got
`Resource not accessible by integration (HTTP 403)` on its very first call, reading run it was
pointed at; job log showed `Contents: read, Issues: write, Metadata: read` and no Actions.
  `workflows.nim` now reports scope workflow's steps demonstrably use that its own block omits,
  over every file under `.github/workflows/`. Narrow on purpose: it reads what steps call rather
  than what they might, and workflow declaring no block is left alone, since taking repository
  default is somebody's decision rather than drift. Cost: marks are text, so step reaching same
  endpoint by other spelling goes unseen -- floor rather than ceiling, and module says so.
  Same failure answered question pull request 89 had flagged as unknown: repository setting does
  not cap this. `Issues: write` was granted. Failure was curator's own.

*Checked.* Verified by firing it against real red runs rather than manufactured one, 2026-09-09.
Dispatched at run 34165524898 -- `main` at pull request 70's merge -- it opened issue 99 naming
that run and both jobs that concluded failure, `driven` and `audit`. Dispatched again at run
34167220207, red at pull request 72's merge, it commented on issue 99 rather than opening second.
Runs 3, 4 and 7 fired on real `check` completions and concluded `skipped`, which is guard working
on green. Issue 99 closed after.
  Verified by breaking, before that: deleting `actions: read` from the workflow makes `koch tree`
  report it by name and by what was granted; restoring it returns 0 findings. That check's own
  commit precedes its fix on the branch, so it fails where it stands (Article IX.8).
  **Unverified**: nothing has yet driven this from a `main` run that went red on its own. Every
  firing so far has been dispatched at a run already known to be red, so what is proven is the
  reading and the reporting, not the trigger's own selection. That waits on a red `main`, which is
  not worth causing.

## Continuous integration

**Nine jobs, and the three required check names have never changed.** `plan` emits the matrices,
`static` runs `nim r koch tree`, `project` is one matrix job per planned project on its own pin,
`driven` is a second matrix over the subset carrying that verb, `types` is one plain job on the
driver's compiler, `scope`, `commits` and `base` run only on pull requests with full history,
and `audit` is a gate reading the rest.

The gate exists because matrix job names vary with the change and can never be required checks,
while `audit`, `scope` and `commits` must stay required. Every job added is named in the gate's
`needs` as well as declared: a job outside it is a red check that cannot block a merge, the one
mistake this arrangement makes easy to make and impossible to see afterwards.

- Rejected: renaming the required checks, which would make the owner reconfigure `main`;
  computing the matrix in shell, which is untested glue where koch is tested.
- Branch names and event kind reach koch through the environment, never interpolated into the
  script. Nim installs under the runner's temp directory, never the workspace, and `.gitignore`
  lists `.nim_runtime/`, because the audit reads untracked files and a toolchain inside the
  checkout was audited as source once — 33,367 findings on the first run.
- The empty matrix was verified separately, since no ordinary run took that path: a record-only
  change emits `[]`, `project` is skipped, and the gate passes on a skipped dependency. It is
  written to pass on `skipped` and fail on `failure` or `cancelled`, and until that run only the
  first half had been exercised.

**`koch audit` was removed.** It ran the static pass and then every project's suites, which
per-project pins made a verb that cannot succeed: one machine holds one compiler on `PATH`, pins
differ, so at least one project reported a mismatch and it always exited 1. Chosen against
teaching it a version-to-path map nobody asked for. Cost: no single local command checks
everything, the honest consequence of independent pins.

**`nim r koch ci` is the local form of the jobs**, fetching `origin/main` and then running the
whole-tree pass, the planned projects' restores and suites, the type check, the driven checks,
scope, commits and base in one process. Every pull request passes it before it is opened; the
runner confirms, it never discovers.

- Cost: a network fetch per run, accepted so the base is the one CI will use.
- Cost: a curator whose change selects every project needs every pinned compiler, which
  resolution provides, plus npm, a browser and each driven project's declared packages, which it
  does not.

Two traps, each found by a merge rather than by reading.

- **A re-run reuses its original merge commit and workflow file**, so a fix on `main` reaches an
  open pull request only through a new head. Merge `main` into the branch; never re-run and hope.
- **Two stamped changes in flight produce a third stamp neither carries.** Each re-stamps every
  project against its own `CONTRIBUTOR.md`; git merges their edits cleanly when they touch
  different sections, but the merged document digests to a value matching neither, so whichever
  merged second would leave `main` red on every project. The cure is to stack rather than
  discover: merge the earlier branch into the later, resolve each `Rules` row to what
  `nim r koch stamp` reports for the merged rules, and fix the merge order.

## The checker checks itself

Nothing checked the checker, so faults it would report anywhere else lived in it: a routine
exported and called nowhere, two modules with no suite at all, and a table naming a retired
verb. `checker.nim` makes each a rule, so the next one is caught by the runner rather than by a
curator reading.

- **Dead export**: a routine exported from a check module and named nowhere in the checker.
  Mentions are counted as identifier runs rather than whitespace words, since `tree.auditTree`
  is a call exactly as `auditTree(tree)` is — counting words reported six live routines as dead
  on the first run.
- **Missing suite**: a check module without `tests/t<module>.nim`.
- **Verb drift**: the verbs koch dispatches, the verbs its usage prints, and the rows of
  CURATOR.md's checks table are one set named three times. Verbs are read from the command
  dispatch alone, bounded between `case options.command` and its `else`, since the option parser
  cases over labels a few lines above and contributed `root`, `all`, `branch` and `sweep` before
  that bound existed.

- Rejected: flagging an export only tests use, which is how every pure rule here is covered and
  would need an exemption list; warning rather than finding, since a warning nobody must act on
  is read by nobody; one suite per module for contributor projects, which group tests by subject.
- Costs: a routine named in a comment is not dead, so prose mentioning a retired routine hides
  it — paid to keep the rule free of false findings; an exported operator is skipped, being
  spelled at call sites rather than named; the table's other columns stay prose no check reads.
- Verified by `tchecker.nim`, and driven: a routine added and never called is one finding naming
  it; a row deleted from the checks table is one finding naming the missing verb; a verb dropped
  from the usage line is one finding naming what usage prints.

The same reasoning deleted `audit.nim`'s hand-written copy of the module graph, wrong in five
places: a copy of a graph drifts from the graph, and each module's `import` line is the graph.

## Figures

Measured with `date +%s.%N`, three consecutive warm runs, Linux amd64 container with four Intel
Xeon 2.10 GHz cores, Nim 2.2.4, 2026-09-06. Warm means every test binary was already compiled.

| Command | Compiles | Wall |
|---------|----------|------|
| `nim r koch tree` | nothing | 0.028 s, 0.023 s, 0.022 s |
| `nim r koch tests curator/probe` | one project | 1.776 s, 1.732 s, 1.832 s |
| `nim r koch audit` (since removed) | every project | 54.156 s, 53.887 s, 53.570 s |

The first and third rows are the pair for scoping. Before it a push cost the third row whatever
it touched; after it, a change to one project costs the second and a change to records alone the
first — roughly thirty times less for the common case, and it no longer grows as projects
arrive. On the real path rather than a synthetic one: a commit whose only changed path is this
file plans `[]` and finishes `nim r koch ci` in 0.721 s including its `git fetch`. Re-measure
when a project's suites grow; otherwise treat as unmeasured.

**Matrix jobs do run in parallel**, verified on the runner from the first run of this
arrangement: three `project` jobs started within one second and finished at 16 s, 52 s and
121 s, so the phase took 121 s rather than the 189 s their sum would be. The saving is the sum
minus the slowest, so it grows as projects arrive. Cost from the same run: matrix jobs cannot
start until `plan` reports, putting 16 s between the run starting and the first project job — a
floor on every run, and the price of computing the matrix in tested Nim rather than shell.

**What the driven check costs, and where it goes.** Locally `koch driven` on `rga_visualiser`
takes 2 m 36 s warm, roughly two thirds of it the harness's own deliberate wall-clock windows
rather than anything a faster machine shortens. That was recorded as a local figure that should
not be treated as predicting the runner's, and it did not — the runner's job is 5 m 31 s on the
same checks, the gap being apt install, restoring a 2.4 GB compiler from cache, and a slower
core. The rule that produced the right expectation outlives the number: a figure from one
machine predicts another's only where what differs has been measured.

| Step of the `driven` job | Wall |
|--------------------------|------|
| read the declaration and `apt-get install` | 1 m 47 s |
| `nim r koch driven` | 3 m 04 s |
| restore the commit-pinned compiler from cache | 28 s |

The install is 32% of the job, and an upper bound on what asking `koch system` per verb could
save, since the same step also compiles koch and runs the project's verb. That is the figure
behind ruling `system` stays per project.

**The caching pair is settled, and it is not the pair expected.** Four caches restore on the
driven job — npm's store, Atlas checkouts, the commit-pinned compiler, the faces — and the
compiler is the whole figure: restoring it is seconds where building from source is the fifteen
minutes the first attempt would have cost, and every other cache is noise beside it (`npm ci`
runs in 2 s cached, six faces are 1.5 s uncached). A cold half for npm and faces was never taken
under runner conditions and cannot be now without deliberately poisoning a key; that measurement
is dropped rather than left owed.

**The static pass on another machine**: `nim r koch tree` warm is 1.42 s, 1.41 s, 1.43 s on a
four-core Intel Xeon 2.80 GHz container, 2026-09-08 — fifty times the row above, on nominally
faster cores. What differs between the two containers has not been measured, so this sits beside
that row rather than replacing it, and neither predicts the other.

**SDL3's install prefix is cached, the build tree beside it deliberately is not, and the first
key did not work.** No package carries SDL3, so `sdl3` clones, configures and builds it from
source: **55.8 s of run 214's 357 s**, the largest single step nothing cached, and larger than
either lever repository issues 79 and 80 were weighing.

- The prefix is what makes the verb return early — `versionSdl3` reads `build/sdl3/lib/pkgconfig`
  — so caching the product is enough and caching the cmake tree is unnecessary.
- It is also what makes it *safe*, and that is measured rather than reasoned. A cmake build tree
  carried over from a configure that had found no X11 kept reporting `SDL not configured with
  OpenGL/GLX support` after the headers arrived, and cost an hour on a container that had them.
  A product caches; a build tree remembers what it decided about a machine that has since changed.
- **The first key never once hit, and that is measured, not suspected.** Keyed on the exact hash
  of the project's `tools/build.nim`, it missed on both `driven` runs after it merged — run 221 at
  `fb1fba1` and run 226 at `b2fa891` — each printing `Built SDL3 3.2.30 into build/sdl3` where a
  hit prints `Kept SDL3 3.2.30, already reported by pkg-config`, and each ending `Cache saved`
  rather than `Cache hit`. The reasoning that picked the key held that the file carries both
  `COMMIT_SDL3` and `SYSTEM`, so a moved pin or a changed package list misses it. True, and beside
  the point: that file also carries everything else a build driver carries, so it changed in two
  consecutive pull requests and the key changed with it. A key has to be specific enough to be
  correct **and** stable enough to hit; only the first was checked.
- **`restore-keys: sdl3-<os>-` fixed it, and run 235 is the evidence.** Read from that job's log,
  on `f9e54ad`, 2026-09-12:

  ```
  11:19:07.307  Cache restored from key: sdl3-Linux-4f98cd632350a0d7…
  11:22:06.233  Kept SDL3 3.2.30, already reported by pkg-config
  11:22:06.236  Cloning into 'deps/imgui'...
  11:24:22.091  Cache saved with key:    sdl3-Linux-75e9e2df1e0287f4…
  ```

  It **restored from a different key than it saved under**, which is the whole mechanism: pull
  requests 136 and 137 moved `tools/build.nim`, so the exact key missed exactly as before, the
  prefix matched an older entry, and `versionSdl3` read the restored `.pc` and returned early.
  The SDL3 phase runs in **about 20 ms** against 55.8 s built, at a restore cost of roughly 1 s in
  the cache step, and the job logs **zero** `Building C object` lines against roughly a thousand
  in run 226.
- **No whole-job figure is quoted, and that is deliberate.** Run 226 took 290 s with SDL3 built and
  run 235 took 314 s with it kept, but 136 and 137 added a menu and a *scene filled to capacity*
  driven run that alone costs 86 s. Those two numbers measure different work, and subtracting them
  would put a false saving in this file where a false prediction used to be. The phase figure above
  is the pair; the job figure is not one.
- Cost: most runs stop exercising the SDL3 build. Every cache here trades that, and the pin is a
  commit rather than a mutable tag now (repository issue 126, answered by pull request 131), so
  what the cache hides is a rebuild rather than an upstream that moved underneath it.

## Open questions

These two were open questions and are now answered; both are kept as answers rather than
deleted, so neither is reopened from first principles.

**A restored `nimcache` does not let a check pass without compiling what it claims, and it is
still not worth caching.** Driven rather than argued, three cases: an ordinary rebuild; a cache
made six years newer than backdated sources; and a full save-mutate-restore, which is what
`actions/cache` actually does. All three rebuilt correctly — Nim decides by content, not by
mtime, so a stale restore costs a rebuild rather than a wrong answer. That is the property the
two Atlas defects lacked, and it is why those bit and this does not.

- Rejected on size, then, not on fear. `nimcache` can only skip Nim compilation, which in run
  214's `driven` job is a **2.8 s** page build plus part of a 13.7 s desktop build — at most
  ~16 s of 357 s. Smaller still in practice: that job runs *because* the project's code changed,
  so the modules that matter are exactly the ones a restored cache cannot serve.
- The claim it carried — that this was "the largest saving still on the table" — was true when
  written and is not now. SDL3 was.

**Caching apt archives is not worth it, measured.** The figure the earlier record asked for:
apt reports `Fetched 27.7 MB in 2s`, and splitting the step gives **2.8 s of download against
7.6 s of install**. The whole step is 37 s, the rest of it compiling koch and running the
project's own `system` verb, which no archive cache touches.

- So a cache removes **2.8 s from a 357 s job, 0.8%**, for a root-owned directory and a key. The
  original instinct — "saves the download and not the install" — was right, and now has a number.
- The 1 m 47 s that opened repository issue 79 described a step that no longer exists: `chromium`
  resolved to a snap and left with the browser change, taking most of the step with it. A figure
  with an expiry date is worth re-taking rather than re-citing.
**koch declares its own system dependencies, as the rule it enforces asks of every project.**
`KOCH_SYSTEM` in `projects.nim` pairs each with its reason -- git, since tree is what git lists
and `ci` fetches base to compare against; curl, since compiler pin nothing on machine serves is
downloaded. `koch system` with no project prints those and every project's, unscoped, so one
command answers what machine needs before any of this runs; naming project keeps its old meaning,
which is what runner asks per matrix job.
  Nim is deliberately absent: it is toolchain koch runs under rather than package machine
  installs, and `compilers.nim` resolves each pin itself. npm is absent for different reason --
  it is needed where project carries node manifest, so it belongs to that project, and
  `restoreNode` already reports its absence by name.
  **`README.md` stopped listing them, which is what actually closed gap.** Rule's complaint was
  prose that decays, and second copy is what decays; README now points at verb rather than
  naming packages, so declaration is only statement and nothing can drift from it. That is why
  no check was written to hold two together: there is no second thing to hold.
  Rejected: stating exemption in `CONTRIBUTOR.md` instead, which was cheaper and was earlier
  curator's lean. It would have left rule true and repository still answering its own question in
  prose; and `koch system` already existed, so this invented no mechanism -- bare form previously
  answered for changed projects, which nothing ever asked it.
  Cost: koch's two are unconditional, so machine needing neither still installs both. Both are
  already declared by `rga_visualiser` for its own reasons, so union is unchanged today
  (repository issue 78).
