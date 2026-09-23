# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 874ef979b21fbc1e |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: built from the brief of the Architect, the constitution, the Nim style guide and the
provenance guide, all supplied by the Architect. It was reshaped on the direction of the
Architect into two project roots, driven by koch, with Atlas for dependencies. There is no
vendored source.

This file describes the checker as it is. How each pass got here is in the log (Article
XI.2). A trap that a later curator would otherwise find again is kept beside the decision
that carries it.

## Build glue

**One compiled driver, `koch.nim` at the root, as the repository of Nim itself builds.** It
holds dispatch only. Every check is a library module here, and is tested here. A project that
needs more verbs carries its own `tools/build.nim`, which `koch types`, `koch driven` and
`koch system` reach through.

- Rejected: make, which is a second toolchain with recipe tabs and untested glue.
- Rejected: NimScript `config.nims` tasks. They run in the VM of the compiler on a subset of
  the standard library, and load on every compile in the tree. They can shadow compiler
  commands such as `check`, and they cannot be unit-tested.
- Rejected: nimble tasks, which need nimble as a runner.
- Cost: one bootstrap compile for each checkout, and `koch` is a code file outside any
  project.
- Verified: `nim r koch` warm run, 0.085 s.

## Enumeration

**Git decides what the tree is.** `tree.nim` lists
`git ls-files -z --cached --others --exclude-standard`. It drops the paths absent from disk,
and reads content only for registered kinds. Git runs as a direct process with an argument
list, and never through a shell.

**The two streams are read apart.** Git writes a warning to stderr and ends it in a newline,
while the fields it is asked for end in NUL. One stream carrying both would leave the warning
glued to the first field, because the split never cuts at a newline.

`git diff base...HEAD` warns whenever a branch and its base share two merge bases. That is
ordinary: a branch merges `main`, and `main` later takes another branch that merged it
elsewhere. The glued field then opens with `warning:` rather than with a path. The scope check
then reads a branch's own file as standing outside its own scope.

Stderr is kept rather than dropped, because it is where git says why it failed, and the
`IOError` carries it. Both pipes are drained before the exit is waited on, since a child blocks
where one fills while the other is read.

- Rejected: `execCmdEx`, which reads by line and appends a newline to NUL-separated output.
- Met in `changedPaths`, and every caller of `gitFields` carried the same exposure. `ls-files`
  and `log` warn on their own occasions, and those warnings would have read as a path or as a
  commit subject.
- Cost: a warning is no longer reported anywhere. Git wrote it to be read by a person, and this
  check reads no person's stream.
- Cost: git must be on `PATH`.
- Verified by `ttree.nim` on a throwaway repository: an ignored `bin/` is absent, an untracked
  file is present, and a rename shows as its destination alone. On one built with two merge
  bases, no field holds the warning and every field is a path. A second case holds that the
  `IOError` still carries git's own reason.

## File kinds

**An allow-list of fourteen kinds is the registry, and an unregistered kind is a finding.**
`kinds.nim` maps a basename or an extension to a comment syntax, and to whether prose is
checked. Its header table is a derived view of `lut_kind_rule`. Nimble files and NimScript
read as Nim, and cfg files as hash comments. `atlas.config` and `atlas.lock` read as JSON, by
basename. Markdown is prose rather than comment, so articles pass while the form rules still
apply.

TypeScript and JSON are registered ahead of use. Html and Svg carry hand-written pages, which
the layout check confines to `pages/` or `mockups/`. Generated markup is one long line, and
fails width on its own.

- Retired: Makefile, with make. The registry admits no second build verb, and the recipe-tab
  exemption went with it, so any tab is a finding.
- Rejected: content sniffing, which lets an unknown kind in silently.
- Cost: matching is by basename or extension only, so `nimble.paths` or `.mk` is unread.
- Verified by `tkinds.nim` over every match and five unregistered names. `tlayout.nim` yields
  one finding on `data.csv`, which names `curator/audit/src/kinds.nim`.

**A gated kind argues for itself in its header, and the gate is checked rather than trusted.**
`Cpp` and `C` join TypeScript as languages admitted only where Nim cannot serve. `.hpp` reads
as C++ and `.h` as C, because the name alone cannot tell them apart. `justification.nim`
demands `not Nim because <reason>` in the opening comment run. A gap of one line is allowed,
so an include guard above the block, and a blank line inside it, both keep the run whole.

Before this, the gate was a sentence in CONTRIBUTOR.md. A second language registered "under
the same gate as TypeScript" would then have been under no gate at all.

- Rejected: the marker anywhere in the file, which admits an argument buried at line 900.
  Rejected: the marker on line 1 exactly, which forbids `#pragma once`. Rejected: a separate
  register of justified files, which is a second place for truth to drift from.
- Cost: the check proves that a justification exists where a reader will meet it, and never
  that it is true. A curator still weighs the claim.
- Cost: the one-line gap can reach a comment on the first line of code. That is deliberate,
  because the alternative is a finding on a correct header.
- Verified by `tjustification.nim` and `tkinds.nim`, and driven over real files, 2026-09-06.
  An unjustified `shim.cpp` and an unjustified `glue.ts` each yield one finding at line 1, and
  fall silent once the phrase is added.

## Comment extraction

**Six hand-written scanners, and one accumulator for each line.**

- Nim: line, doc and nesting block comments, plain, triple and generalized raw strings, char
  literals, and numeric suffix quotes.
- Cfg: `#`, unless `\#`.
- YAML: `#` at line start, or after whitespace, outside quotes.
- Ignore files: a leading `#` only.
- TypeScript: `//`, `/* */`, three string forms, and doc stars stripped.
- Markup: `<!-- -->`, which may span lines.

Whitespace runs collapse, so texts compare stably.

- Rejected: real parsers, which cost dependencies for a question that needs no syntax tree.
- Cost, assumed: a TypeScript regex literal that holds `//` opens a false comment.
- Cost: the markup scanner reads `<!-- -->` only, so comments inside `<script>` and `<style>`
  stay unread. Markup hosted in a Nim string already carried the same blind spot.
- Verified by `tcomments.nim` across the syntaxes, including the testament header string and
  markup comments that span lines.

## Prose

**Articles are the whole rule, as data.** `ARTICLES = ["a", "an", "the"]`. Tokens are
whitespace-split, punctuation-stripped and lowercased, after the backtick spans are removed.

- Cost, found on the first build: the label `A`, as in "Appendix A", is flagged. `prose.nim`
  tripped on its own example, and now writes the label in backticks.
- Verified by `tprose.nim`: 300 seeded random telegraphic comments pass, and each one with an
  inserted article fails. The citation `2.2a`, a URL and an underscored name pass. The corpus
  is seeded with `randomize(0)`, so the 300 are the same 300 on every run. It is the only
  sampled corpus in this project, and that seed is why its verdict does not vary
  (CONTRIBUTOR.md, "Tests are paramount").

## English

**Three rules of ASD-STE100 are mechanical, and the rest hold by reading.** Those three are a
sentence of at most 25 words, and a paragraph of at most 6 sentences. The third is a table of 42
words, each with one approved replacement. The dictionary of about 900 words belongs to ASD, so no
check can hold all of it. `GUIDE.md` carries the other eleven rules.

**The governed set is half data and half derivation.** `ENGLISH_PATHS` holds the charter, the
two prompts, the guide, the root `README.md` and the four templates. No rule can derive those.
Everything else comes from the layout. That is the README of each project root, the README of
each registered domain, and the three records directly inside a project directory.

**A row somebody must remember is a row somebody forgets.** The records were listed one row at a
time, one row for each record of each project. Nothing wrote the row after the last one. A
project created after the list was last touched carries three records that no check reads. The
audit then stays green over prose it never looked at. The derivation answers the question from
the path, so the next project is governed from its first line.

**A README below a project directory is outside the set.** `dance_ontology` keeps prose under
`sim/` and `design/` in its own register. Add `design/README.md`, `sim/README.md` and
`sim/verdicts.md` to `ENGLISH_PATHS`, then run `nim r koch tree`: 192 findings, measured
2026-09-23. Curator duty 3 forbids a check that reddens a project which cannot see it yet.
Cost: that prose holds Article VI.8 by reading alone.

**Each widening is taken at the first moment it is free.** The set opened as the root documents
alone, so no project reddened for a rule that its writer had not read. The records of the
projects joined once every one of them was written in the register. The index READMEs joined
while they still passed, which was measured before the change rather than after it. Widening
costs one finding for every line of prose written between a rewrite and the widening that
follows it.

The record widening found one word that the rewrite itself had missed, `attempt` in this record.
That is the argument for the check over reading alone, made against the reader who wrote the
rewrite.

**A quotation is skipped whole.** Quoted text comes from outside this repository, and a delegate
may not rewrite it. A finding on it could never be fixed. The case that settled it sits in the
record of `rga_visualiser`. The NASA Exoplanet Archive asks for its acknowledgement word for
word: 28 words, and not ours to shorten.

- Cost: the worked example inside the quotation in `GUIDE.md` goes unchecked. It holds by
  reading, as the rest of the guide does. The alternative was an allowlist of exact sentences,
  which is the grandfathering that curator duty 3 forbids.
- Cost: a sentence ends at a stop after a letter, a digit or a closing bracket. A stop after a
  degree sign or a superscript does not end one. Two sentences then read as one, and the finding
  that follows is a long sentence rather than a missed one.
- Verified by `tenglish.nim`: the three finding kinds, the sentence-end cases and the block
  split. It also covers the collapsed span, the skipped quotation, and a path outside the set.
  That path is `gaps.md`, which a generator writes and no delegate may rewrite by hand.
- Verified by `tenglish.nim`: the derived arms. A project and a domain that do not exist yet
  are governed. A domain outside the registry is not, and neither is a README below a project
  directory. That last arm is the one that would redden `dance_ontology`, so it has its own
  assertion. One more assertion holds that a derived path is read, and not merely listed.
- Cost, found by pushing a red branch: testament keys its cache on the test file. A change to
  a source module alone then reuses the binary linked against the module before it.
  `koch ci` then passes on a tree that a fresh checkout fails. Remove `nimcache` where a check
  changed and its suite did not.

## Form

**Width is counted in runes. Any tab, any CR, and any ending but exactly one newline is a
finding.** An over-long line passes only where a break cannot fix it. Its longest
whitespace-free token, with the indent of the line, already overruns. That token is within
`TOKEN_MAX` (400 runes), and the rest fits once it is removed. A font URL has no whitespace to
break at, prose always does, and minified markup is one run far past the bound.

Lines split on LF only, so a CR survives. Nim banners need two blank lines before and one
after. The tiers are unmarked in syntax, so the second-tier minimum is demanded of every
banner.

- Rejected: an exemption for URLs by pattern, which guesses at intent. Rejected: an exemption
  for any single-token line, which admits machine output of any length. Rejected:
  `splitLines`, which swallows CRLF.
- Cost: a long identifier gets the same exemption that a URL does, because neither one breaks
  at whitespace. `LICENSE.md` is width-exempt, so third-party text stays verbatim.
- Assumed, and not checked: a two-space indent.
- Verified by `tform.nim`: 100 runes pass, and 101 breakable runes fail. A 202-character fonts
  link passes, while 207 of prose and 400 of minified markup do not. A tab in Nim and in cfg
  fails, and every ending case is covered. Driven on real pages, 2026-09-05: 391 markup lines
  and a fonts link whose longest token is 179 runes audit clean. A generated 1,407-character
  drawing does not.

**A generated npm lockfile passes the width rule, measured rather than assumed.** Before
CONTRIBUTOR.md could demand a committed `package-lock.json`, one was generated and audited: 93
lines, longest 117 runes, **0 findings** (npm 12, 2026-09-06). The unbreakable-token rule is
what saves it: the long lines carry one `sha512-` digest of 95 runes, and fit without it. So
the shape holds at any lockfile size, and that is why the rule needed no exemption beside
`LICENSE.md`.

## Layout

**Two project roots. Each holds README.md and folders only, and every folder is checked at its
depth.** A project is `curator/<project>` or `contributor/<domain>/<project>`. It must hold
README.md, PROVENANCE.md, GLOSSARY.md, exactly one nimble file named after the folder, and at
least one file under `tests/`. A nimble file that requires packages demands `atlas.lock`.

The root README carries one row for each domain, equal to `DOMAINS`. Each root README opens
with its folder name. Each domain README opens with the domain name, and holds the theme line.
A committed page sits under `pages/`, which is what the project stands behind, or under
`mockups/`, which is an exploration kept for reference. The directory declares which one, and
nothing is inferred from content.

An unknown root directory, a stray file in a root or domain folder, and an unregistered domain
are findings, and are never skipped. An earlier form returned early under `curator/` and
dropped unknown heads in silence, so a misplaced project vanished from the audit.

- Rejected: domain READMEs that list projects, which forces a contributor to edit outside
  their prefix. Rejected: a theme line for root READMEs, which is a fabricated authority.
  Rejected: an inference of mock-up from generated, which makes the distinction an accident of
  formatting.
- Cost: empty directories are invisible to git, so `tests/` must hold a file.
- Verified by `tlayout.nim` over a fixture tree that the tests build. The project list is
  pinned, and the unknown-domain case asserts both the finding and the unchanged list.
  `taudit.nim` proves that fixture clean under every static check.

**Only one check reads substance, and it reads a narrow slice.** `checkCitations` resolves
every claim that opens `Verified by` and names a backticked `.nim` file in the `PROVENANCE.md`
of a project, against the `tests/` of that project. It was chosen because the most valuable
property of the record is its verified-against-assumed split. Nothing stopped a citation
rotting when a suite was renamed.

- Rejected: a match of the claim against what the test asserts, which no checker can do.
  Rejected: a flag on every backticked span, which would catch a command such as
  ``atlas changed``; the `.nim` ending is the guard.
- Cost, the honest limit: a delegate can cite a real test beside a claim that it does not
  make. That gap closes by reading.
- Verified by `tprovenance.nim`, and driven on this repository. Every citation on `main`
  resolves. Rename one to an absent file, to a source file, or to the test of another project,
  and each case reports one finding.

## Provenance stamp

**FNV-1a 64-bit over CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md**, with CR stripped, NUL
between files, and 16 lowercase hex digits. CURATOR.md is excluded, so a curator-only edit
touches no project.

- Rejected: `std/sha1`, deprecated in Nim 2, which warns on every build. Rejected: the
  `checksums` package, a nimble install in CI for one digest. Rejected: `std/hashes`, unstable
  across Nim versions.
- Cost: it is a change detector and not a signature, so a collision needs an adversary.
- Verified by `tprovenance.nim` for determinism, one-byte, order and boundary sensitivity, and
  CRLF invariance. Verified by `taudit.nim`: one byte in any rules document goes stale in
  every project, and one byte in CURATOR.md in none.

**`koch stamp --write` sets the `Rules` row of every record itself.** `withRulesRow` rewrites
the row in place, and finds it as `headerFields` finds it, so what is written is what the
check then reads. A record already current is not touched, and each path that moved is
printed. The four hand edits of duty 1 were one step too many (curator review, C10).

- Rejected: a write of the whole header back, which would reformat a table that its writer
  padded.
- Verified by `tprovenance.nim`. The new stamp lands, and the padding and every other byte
  stay. A second write is a no-op, and an absent row leaves the source untouched. Only the
  first `Rules` row moves.

## Record shape

**A record is read as `#` lines with the fenced code blanked, and is held to four forms that
the guide states.** No heading carries a date. `## Open questions` is the last `##` section.
No heading text appears twice. No title is underlined, because every reader here sees `#`
lines, and an underlined title is invisible to all of them.

A record over 3,000 lines is a finding, and its remedy is the prune that the guide already
asks for. The ceiling was 2,000 while records were written in ordinary English. Simplified
Technical English costs about a fifth more lines, measured over five records.

2,500 scaled the old number by that cost and kept the old headroom, which was none. The largest
record stood at the ceiling before the rewrite and at the ceiling after it. Two merges then
spent 17 lines of margin inside one day, and the next sentence anybody wrote would have
reddened `main`.

A backstop that fires on ordinary work reports growth, and not narration. This one carries 20%
clear of the largest record. `SECTION_LINES` is the instrument that reads narration.

**A `##` section over 200 lines is the same finding, on the unit where narration collects.**
The whole-file ceiling is crude. It punishes a wide project and lets a narrow one narrate
freely. Measured over the 93 sections of the five records, the median section is 34 lines and
the ninetieth percentile is 137.

The longest is 505 lines and holds 39% of its record, inside a record the whole-file ceiling
never touches. The widest record, at 2,484 lines, has no section over 194. Length alone does
not say which one is narrating, and the section does.

200 rather than 150: 150 flags three sections across three projects, 200 flags one, and both
flag the same narration. Tighten it once that one is pruned. A record that ends in a newline
leaves an empty last line, which is not charged to the section it falls in.

The header may carry a `Pruned` row that names the commit before that prune. The
check reads the form of that row, and koch reads its existence from `git log` on the record
itself, under `tree` and `ci`. That needs a full clone. A shallow one has no such log, so the
static job fetches every commit.

- Rejected: a split of a long record into files by subsystem. The checker names one record for
  each project, and the stamp lives in its header. History is git's, and the row says where.
- Cost: line forms, and never a Markdown parse. A heading inside an HTML comment counts, and
  front matter is not skipped. No governed record carries either.
- Verified by `trecord.nim`, each form by line. `fencedOut` is verified by `tmarkdown.nim`.

## Glossary

**Shape only: a heading, `## Language`, and a definition line after every `**Term**:`.** The
content is the contributor's and the Architect's, and a term enters only when the Architect
selects it. The check cannot know what was agreed, so agreement holds by reading. It runs on
the top-level `GLOSSARY.md` too. Zero terms pass, because the format creates entries lazily.
Verified by `tglossary.nim`.

**The people words that the glossary avoids are held out of root files and curator records.**
`PEOPLE_WORDS` is the avoid list under Architect, Delegate, Curator, Contributor and Role. It
is read whole and without case, plural included, outside code spans, fences and tables. It
holds people words only.

The full avoid list holds build, rules and version, which are plain words everywhere, and it
would have flagged 367 places. `identity` is left out, as the word of algebra in
`curator/probe`. Contributor prose is not read, and `tglossary.nim` verifies all of it.

## Prompts

**Both opening prompts are held to duty 10 by two forms.** A prose line that names a date,
`#N`, `issue N`, `pull request N` or `run N` is a finding. An incident belongs in this record
or in the log, and only the rule belongs in a prompt. A prompt over `PROMPT_BYTES`, 40,000, is
a finding, so runaway growth is caught while an ordinary addition is not. Code spans and
fences pass, which keeps the carried-list example legal.

- Cost: `II.9`, `duty 10` and a bare year pass by shape, so only a whole date is diary here.
- Verified by `tprompts.nim`.

## Copies

**A paragraph of 25 words or more, written twice, is a finding.** It is reported at its later
place, and it names its first. That holds within one Markdown file, and across two. Fenced
code, table rows and headings are left out, and whitespace is collapsed before the comparison.
Two copies of one rule drift, and the prompts drifted that way.

- Cost: a paragraph reworded by one word passes. The check catches a copy, and never a
  paraphrase.
- Verified by `tduplicates.nim`.

## Faces

**Every presentation target ships the faces that Article X.8 names, and four line forms hold
it.** A source is read only where it declares `font-family` or the `font` shorthand. The
project of the checker is exempt, because it names the families as data and carries fixture
pages. A page that links a font host is a finding, because the viewer then fetches the face
instead of receiving it.

The first family of every stack is Noto Serif, Noto Sans or Commit Mono, subset aliases
included. The fallbacks after it are free, because the shipped face is what the viewer gets. A
selector whose subject is `h1` to `h6` sets the serif, with one level of `var()` resolved from
the page's own custom properties. A selector that styles something inside a heading is not
styling the heading. A source that names Commit Mono enables `calt`, where its functional
ligatures live.

- Cost: declarations are read and expressions are not. So a stack assembled through `&` is
  unseen, and so is a heading styled through a class alone. The desktop atlas is outside the
  ligature rule by X.8 itself, because Dear ImGui shapes no text, and it declares no CSS.
- Verified by `tfaces.nim`, each rule by line, and the label beside a heading among them.

## Branch scope

**The branch grammar mirrors paths: two, three or four segments, and the prefix decides.**
`curator/<name>` owns the empty prefix, so every path passes. `curator/<project>/<name>` and
`contributor/<domain>/<project>/<name>` own their folder. `main` passes, because a push to it
is a merge that the Architect approved.

- Rejected: a special case for the curator root, because the empty prefix is one mechanism.
- Cost: fixed segment counts reject a nested branch name. The Architect may merge red
  deliberately, so this is a guard and not a gate.
- Verified by `tscope.nim` over five domains, one curator project, the curator root and two
  rejected forms. `tdomains.nim` covers 18 rejected branch forms.

**The reach of a curator into a contributor project stops at their records.** Under
`contributor/`, the only writable paths on a curator branch are `README.md`, `PROVENANCE.md`
and `GLOSSARY.md`. Those are `PROJECT_FILES`, read from `layout.nim` rather than repeated.
That empty prefix was the one hole in an otherwise mechanical system, and it belonged to the
role that runs most often. Duty 11 forbade a curator to write contributor code, and nothing
but reading held it.

- Rejected: a restriction to `PROVENANCE.md` and `GLOSSARY.md` alone, which the toolchain
  propagation disproved. That propagation removed "Needs Nim 2.2.4" from three contributor
  READMEs, which is prose that the rule itself invalidated. The tighter set would have blocked
  it.
- Cost: the README stays writable. So restraint about a rewrite of a project's prose is duty
  11's to govern by reading, and never the check's.
- Verified by driven check. A curator branch that touches the source of `dance_ontology`
  reports one finding, which names the path. The same branch that touches its `PROVENANCE.md`
  and `README.md` reports none.

**A curator may move the files of a contributor, and never edit them.** `tree.movedPaths`
reads `--name-status --find-renames=100%`, and `checkScope` exempts exactly those paths on a
curator branch. So only an exact rename qualifies, and an edit disguised as a move is still
caught. To rename a domain is a registry change, and the registry is the curator's. To move
files is the consequence, and never authorship.

Cost: a curator may reorder the files of a contributor without asking. Content cannot change
and the move is visible in review, so the cost is disorder rather than damage.

**Domain folders are ASCII slugs, and the accent lives in the display name.** The folder is
`sincopa` and the name is `síncopa`, which is the split that `comma_games` and `comma, games`
already used. Git quotes a non-ASCII path by default, so `git ls-files` piped into any shell
tool fails on it. That had forced a `core.quotepath off` instruction on every delegate, and
that instruction is gone with its cause. macOS stores such a name as NFD, so the same folder
has different bytes there. A `static` assertion in `domains.nim` holds every folder to
`isProjectName`, and fails the build rather than the suite (Article IV.4).

Cost: 72 files moved, and the old prefix `contributor/síncopa/...` no longer parses.

**A branch must carry the rules and the checker of its base before it may merge.** `base`
reads what the base gained since the branch forked, and reports a branch that predates a
charter document or the checker. Pull request 11 was green against the `main` of its day, and
merged into a later one. It arrived carrying a stamp that three rules changes had falsified.
The run failed, and nobody was told.

GitHub offers "require branches to be up to date", which prevents this. That setting is
blanket, and it makes every open pull request stale on each merge. The merge rate is what
makes it the wrong trade. 48 pull requests merged in the week to 2026-09-23, and 16 in its
last day.

`base` is the narrow form: it reports only where the base gained a charter document or a
checker. It feeds the `audit` gate that branch protection requires, so no setting changed.

Only two kinds of path count. A charter document moves the stamp that every project claims,
and the checker decides what the audit accepts. Everything else may differ freely. On the
runner the job checks out the branch head, and never the merge ref that a pull request
offers.

The first parent of that ref is the tip of the base. So what it gained over the base is empty
by construction, and the check would report nothing on every fresh run. `static` on the same
merge ref is what holds a stale stamp there.

- Cost: a merge of a rules change reddens every open pull request until each one merges the
  base. That is the cost of the blanket setting too, and it fires exactly when the staleness is
  real.
- Verified by a replay of a branch left behind by a week of `main`. At its head, `koch base`
  reports the finding. At a synthetic merge of that head into `main`, with `main` as the first
  parent, it reports nothing.
- Cost, the honest limit: this reads at pull request time, and never at merge time. So a
  branch green at ten can merge at five past, after another one lands. Only a merge queue
  closes that.
- Verified by `tbase.nim`, and by a replay of the incident. The branch of pull request 11,
  against the `main` of today, reports the finding, which names `CONTRIBUTOR.md`, five check
  sources and `koch.nim`. Against its own fork point it reports nothing, which is why its run
  was green at the time.

## Commits

**`type(scope)!?: summary`, with eleven types as data. On a project branch the scope must
equal the project.** The curator root accepts any valid scope, because a rules change
propagates under the scope of each project. A branch outside the grammar still gets format
checking. Cost: the imperative mood is unverified. Verified by `tcommits.nim`: every type with
three scopes, the breaking marker, 11 rejected forms, and scope enforcement on both project
branch forms.

**The regression rule is enforced, and not hoped for.** `commits` reads the subjects newest
first. It demands that the commit immediately before every `fix` is a `test` of the same
scope, one test to one fix, with nothing between them. "Every mistake becomes a test" was the
stated priority of the Architect, and it lived only in prose. The log now reads as the ladder
that the rule describes.

- Rejected: any earlier `test` of the scope on the branch. One token test then satisfies every
  later fix, so it measures the order of kinds and nothing of the pairing.
- Rejected: a match across the history of `main`, which needs the whole log. It would still
  pass a fix whose test landed years earlier under a different intent.
- Cost: a fix whose test already sits on `main` needs a test here, or another type. The escape
  is honest, because a change that needs no new test is not a `fix`.
- Cost: a `revert` or a `docs` between the pair breaks it, and so does a second fix on one
  test. Three tests and then one fix pass, because only the commit before is read.
- Verified by `tcommits.nim`. The pair passes, and tests before the test pass. One finding
  comes from a fix alone, from a test after its fix, and from the test of another scope. One
  comes from a second fix on one test, and from a commit or a revert between them.

## Role

**The opening line of a pull request and its labels are the role that its branch names.** The
runner holds it to that before the merge. The role line says who speaks, and the label says
whose work it is. On a pull request both are the role of the branch itself. So `parseBranch`
derives one string through `roleName`, and the check is equality rather than presence.

The two facts arrive from the event payload through `ROLE_BODY` and `ROLE_LABELS`, so the job
needs no token scope and makes no API call. `role.yml` is separate from `check.yml`, because
it must fire on a label event, which would otherwise re-run nine jobs. An unfilled template
opens `**Role:** <!-- … -->`. So the line is read with any trailing comment dropped, and it
then fails equality rather than passes as a line that names nothing.

- Rejected: the daily read alone. `ledger.yml` sees the same two facts, but it samples open
  items once a day and reports after the merge. Of 123 pull requests merged in the week to
  2026-09-14, 14 were open at any of its runs, because half live under half an hour.
- Cost: an issue carries no branch, so which label it needs stays a judgement, and stays the
  ledger's. A comment is unreachable, and that is what remains of the first carried rule.
- Cost: the labels are searched for the expected string rather than compared whole. A label
  joins when work hands across, and labels are never removed.
- Cost: `ci` cannot run this verb, because it has no pull request to read. It is the one check
  that a delegate meets on the runner rather than before a push.
- An empty label list is the state a pull request opens in, and not a mistake. No API call
  creates a pull request and its label together. A run on `opened` therefore reads none, and
  the `labeled` event clears it seconds later. Whether that first run fails or is cancelled
  turns only on whether the label lands before it finishes.
- A cancelled first run may report nothing at all. One cancelled three seconds in died at
  `Getting action download info`, before its checkout, so neither message reached its log.
  Read the run that the `labeled` event started, and never the first one.
- So the two states carry two messages. The empty one names the event that clears it, and the
  one that names a wrong label does not. The finding stays red either way. A green run at
  `opened` would let a pull request opened and merged in one go carry no label. Half of them
  live under half an hour.
- Rejected: reading the current labels through the API. It would end the red run, and it costs
  the `pull-requests` scope and a call for every run, against a job that holds neither today.
- Rejected: dropping `opened` from the trigger. The check then says nothing to a delegate who
  opened a pull request wrongly, which is the reason it was written.
- The echoed line is cut at `ECHO_MAX` runes, because a body may open with a whole paragraph,
  and one did. The finding is meant to be read in a log.
- Verified by `trole.nim` on the line reader, the cut, and each arm of the grammar. Verified
  by driven check on this repository. Two pull requests replayed as they stood before they
  were mended, with neither line nor label, report both findings each. Four as they stand, two
  of each role, report none.

## Assets

**One declaration of every file fetched at build time, in `assets.nim`.** CONTRIBUTOR.md
already names the class: *"binaries are never committed, and neither are fonts, images or any
file the audit cannot read"*. Each one is recorded with origin, version, licence and checksum.
The store is that class kept once, rather than once for each project.

Faces are the only instances today, and the rows say so by grouping rather than by column. The
shape is file, address and digest, which is what any such file needs and no more. **An asset
that wants a field this row lacks is a change, and not something this shape answers.** Such a
field is unpacking, or a variant set. The header says so, rather than implies that it is
settled for all time.

The name was generalised before either project adopted it. A rename afterwards would have
meant three pull requests coordinated across two projects that a curator may not edit.

The reason it exists at all: Article X.8 gives three families to every presentation target, so
the second target repeats the pins of the first. It did. `rga_visualiser` and `dance_ontology`
each pinned four of the same files, byte for byte, in their own `tools/build.nim`. Article
II.9 calls that a copy no real constraint forces, and asks each copy to name its siblings.
Neither did, and nothing could have told them from two different faces (repository issue 116).

- **The digest is the curator's, and the choice is the project's.** The store says what bytes
  `noto-sans-latin-400` is. It never says which faces a target wants, and the targets differ:
  one draws maths and symbols, and the other italic serif. What stops being written twice is
  only what was already identical, so the autonomy that CONTRIBUTOR.md argues for is
  untouched.
- This is the **first shared build input** of the repository, and it stays the only one.
  Compilers are pinned for each project in nimble files, Atlas checkouts for each project, and
  npm for each project, all deliberately. The bytes of a face are not a toolchain. They are
  the same file for whoever fetches them.
- **Keyed by digest, and never by name.** Two projects that ask for one face share one entry
  by construction, and a moved pin is a different entry rather than a stale one. `check.yml`
  gets the same property from a cache keyed on the file that holds the digests, one layer
  down. The store sits at `~/.cache/koch/assets`, beside `~/.cache/koch/nim` and outside the
  checkout, because the audit reads untracked files.
- The rows are the union of two tables that already agreed. Where both projects pinned one
  file they pinned the same digest. **That agreement is what made one table safe to write**,
  rather than a merge that had to pick a winner. There are fifteen faces: nine
  `woff2` for pages, and six TrueType or OpenType for the desktop atlas, which `@fontsource`
  does not ship.
- Verified by a drive of it, and by a break of it. Cold store, three faces, two of them shared
  by both projects: **1.0 s**. Warm, same call: **0.117 s**, and it fetches nothing. Three
  files, one for each digest. A face that nobody declares is a finding, which names the table
  to add a row to. Alter one declared digest in its last character, and the fetch refuses the
  bytes and **leaves the store empty** rather than keeps them.
- Cost: the store grows and nothing prunes it. A face is about 30 kB where a compiler is about
  300 MB. So what is unbounded is the number of pins the repository has ever held, and not the
  bytes.
- Cost: an upstream that moves bytes under one address now fails every project at once, rather
  than one. That is the same failure that a digest exists to make loud, and it is louder
  shared.
- **The Nim tarball is deliberately not here.** It is fetched and checksummed too, but its
  digest comes from the sidecar of upstream at fetch time, rather than from this table. It is
  stored *unpacked by pin*, because the rest of koch resolves toolchains by pin. The trust
  model and the key both differ, so `compilers.nim` keeps it, rather than this table pretends
  that one shape serves both.
- **The declaration is published, so no consumer parses this source.** `koch assets` that
  names no file writes every row as `<file> <digest>`, one to a line. Before that, a project
  holding the law that its faces are declared read `assets.nim` as text. That is a second
  parser for a format that only this module owns. It is the duplication the store exists to
  end, one layer up (repository issue 134).
- Two columns rather than three: the address is the business of the fetcher, and the digest is
  what a consumer checks bytes against. Neither column can hold a space, so `split` reads a
  row. **A row never reads as a path, and the suite holds it so.** The verb prints paths where
  files are named, and rows where none are. Both contributor builds tell those apart by shape
  alone: one keeps the lines that `fileExists`, and the other the lines that start with `/`.
- A row that looked like an absolute path would be copied as a face by one build, and counted
  as served by the other. Neither project can check that. The store owns the shape of the row,
  so the store holds the law.

**A `/common/` tree was costed and deferred.** Issue 134 asked for one, and named the bar for
admitting anything to it. The curator and at least two contributor projects must use it, and
each of them must be named. A later refactor can then tell a common project nobody needs from
one everybody does.

The store is the only thing in the repository that clears that bar today. Compilers, Atlas
checkouts and npm are pinned for each project deliberately, and a tree with one inhabitant is
a rename with a migration attached. So the published contract above ships, and the tree waits
for a second case.

**If it is ever built, the curator writes it and contributors only read it.** A shared tree
that a contributor may write is a scope boundary the branch grammar cannot check.

**A ledger reads what GitHub records, so three carried rules stopped being only read.**
`ledger.yml` runs daily and writes one issue. It names three things:

- a pull request left ready without a green run;
- a `Closes #N` that never fired;
- an issue or pull request that opens with no role line, or carries no label.

Its shape is the shape of `watch.yml`: one issue found again by a marker, `gh issue list`
rather than search, and the label as a hardcoded literal. Its schedule idiom is the one in
`check.yml`.

- **None of the three rules left the carried list, and the change that built the sweep is
  where that was discovered.** Issue 143 claimed that three would leave, and the plan for it
  claimed two. Both were too generous. Every one of the three has a half that GitHub does not
  record.
- The sweep reads bodies but no comment, and it cannot tell a copied label from a composed one
  spelled right. It catches a `Closes #N` that misfired, but never the shape of issue 116.
  There, a ruling in a comment left an issue open, and no pull request existed to find. It
  catches a pull request ready without a green run, but not one green now and about to move.
  So the three rules were **narrowed to their remaining half** rather than struck, and the
  list stays at seven.
- **Verified against fixtures rather than only on the runner.** `gh` is not installed here,
  and a scheduled workflow runs only from the default branch. So the sweep was driven through
  a stub that stands in for `gh`. A draft is skipped, a green head is skipped, a head whose
  run is still `in_progress` is skipped, and a red head is named. A merged pull request that
  names an issue still open is named with its base, and one outside the window is not. A body
  that opens `**Role:**` and one that opens `Role:` unbolded both pass, while a null body and
  a missing label are named.
- **The unbolded form passes deliberately.** Issue bodies here open `**Role:**`, but comments
  are written loose, and the Architect's own comment on issue 134 opens `Role: architect`. A
  check that demanded bold would spend its first run naming whoever wrote the rule.
- **`workflows.nim` gained `("pull-requests", "gh pr ")` in the same change.** A `permissions`
  block sets every unnamed scope to `none`. So a workflow that reads pull requests without
  naming that scope gets 403 on its first firing. That is the exact failure `checkScopes`
  exists to prevent, and it could not see it, because no workflow had used `gh pr` before. The
  gap was found by the writing of the first such workflow, and not by a read of the check.
- **`watch.yml` watches it, and that was the condition for the merge.** A sweep cannot be
  driven before it lands, because a scheduled workflow runs only from the default branch, so
  its first real run is unattended. A ledger that quietly stopped running, while both
  documents say a runner holds half of three rules, is worse than no ledger. So a red `ledger`
  opens an issue exactly as a red `check` does.
- Its marker carries the name of the workflow itself, `watch:red:<name>`, rather than the
  single literal it used before. One shared marker would let somebody who closes a red `check`
  dismiss a broken ledger in silence, which is the failure being closed. Driven through a stub
  first: a red `ledger` beside an open `check` issue opens its own, rather than comments on
  that one.
- Cost: about 30 runner-minutes a month. Public repositories draw on no allowance, so this is
  free today. It stops being free if this repository goes private again, where 1,909 of 2,000
  free minutes were once measured used.
- Unmeasured: whether a run that authenticates as `GITHUB_TOKEN` spends the allowance of the
  repository rather than of the account. It should, and that would keep the sweep off the
  budget that every delegate shares. Nothing here has measured it, and this delegate has twice
  found a belief about GitHub metering wrong.

## Toolchain

**Each project pins its own compiler, and there is no Nim for the whole repository.**
`requires "nim == <version>"` sits in the nimble file of the project. It is read through the
same `requireLiterals` scan that `dependencies.nim` uses, so requirements are parsed in one
place. That no single version serves every project is measured, and not feared.

`rga_visualiser` pins a compiler commit that no release carries. `dance_ontology` sat on
2.2.4 for a week, because 2.2.8 onward crashed the compiler on its suites. It moved to 2.2.12
once the cause was found in its own source (repository issue 106).

- Rejected: one pin for the repository, which cannot hold both. Rejected: `>=`, which cannot
  express the upper bound that `dance_ontology` needs, and cannot say which compiler a suite
  passed on. Rejected: a `.nim-version` file, a second place a version lives, beside the
  nimble file that already names one.
- Verified that Atlas accepts an exact compiler pin rather than resolves it as a package.
  `atlas --noexec rep` cloned and set the pinned commit, and `atlas changed` exited 0 (Atlas
  0.9.0, 2026-09-06).

**A pin may name a commit as well as a version**, as forty lowercase hex characters, which is
how `atlas.lock` records commits. `rga_visualiser` asked for it. Its dependency spells its
operators in prefix form on its head, which needs a lexer change on `devel` and in no release.
`isCommit` is tested before `isVersion`, because forty digits satisfy both, and the absurd
version loses.

- Rejected: a bare `devel` label, a moving target that records nothing. Rejected: a dated
  nightly, retained only for a window, so an old pin stops installing and the record stops
  being reproducible.
- Cost: no action installs a compiler by commit, so it is built from source and cached by
  commit.
- Cost: the driver project may not pin a commit, because every other job waits on the one that
  the setup action installs. `checkDriver` reports it.

**The driver version is derived, and never a second pin.** `NIM_VERSION` in `check.yml` builds
koch and runs the whole-tree pass. `checkDriver` fails the audit unless it equals the pin of
`curator/audit`, because koch compiles the modules of that project. It is the same
derived-view rule that `layout.nim` applies to the domain table.

Every workflow that installs a compiler is held to it, and not `check.yml` alone, because a
second copy drifts. `check.yml` alone must state it, and the commit-pin fault is named once,
however many workflows state a version. Verified by `ttoolchain.nim` over both paths, and by
driven check. A `NIM_VERSION` of `2.2.6` against a `2.2.4` pin reports one finding at the
workflow, and a restore of it clears.

**A pin moves on evidence, and the evidence is a run rather than a release note.** The curator
projects moved `2.2.4` to `2.2.12` on 2026-09-09, after a sweep for versions that nothing
here should still run. That is five patch releases and seventeen months. No release in that
series carries a CVE, because Nim assigns none. So the reason is what the notes carry between
2.2.6 and 2.2.12. They carry SIGSEGV under ARC and ORC and under refc, a use after free, an
overlapping `copyMem`, and overflow checks that could be escaped.

- Verified by a run, and not by a read. 23 audit suites and 2 probe suites pass on 2.2.12,
  in 41.0 s and 10.0 s on this container. That ran before the pin was pushed anywhere.
- `dance_ontology` followed once the cause was measured rather than assumed. Since 2.2.8, a
  `func` whose implicit `float` result is read by `+=` before it is ever assigned gets an int
  register for it. To write `result = 0.0` first is enough to avoid it. It was handed over as
  repository issue 106, with a five-line reproduction, and its record holds the diagnosis.
- Cost: the modules of koch compile under every pin in the tree, because the job of every
  project installs its own. The matrix is what proves that, rather than this paragraph.

**Koch resolves each pin to its own compiler, and fetches one it lacks.** It takes `PATH`
where that already serves, then `~/.cache/koch/nim/<pin>/bin`, then a fetch. A release comes
as a tarball. A commit comes from a clone of `nim-lang/Nim` and a run of `sh build_all.sh`,
which is the recipe that `check.yml` already used. So does any platform that nim-lang.org
publishes no build for. The cache sits outside the checkout, because the audit reads untracked
files, and `$KOCH_NIM_DIR` moves it.

Before this, `runJobs` read the single compiler on `PATH`, and reported a finding for every
project whose pin differed. So `nim r koch ci` could not be green as one command whenever the
changed set spanned two pins. That is the ordinary case, because any change under
`curator/audit/src/` selects every project.

Two traps, both found by a drive rather than by reasoning, and both changed the code.

- **A half-built toolchain lies.** A probe of `bin/nim` before `koch boot` finished returned
  the csources bootstrap binary, which answered `--version` with an unrelated commit. A source
  build now completes beside its destination, and moves in only when it is done, as the
  tarball path did.
- **To name a tool by path is not enough.** Atlas resolves `nim` through `PATH`, so the Atlas
  of the toolchain read whichever compiler `PATH` held, and warned `environment mismatch`.
  Children now run with the `bin` of the toolchain leading `PATH`. A tool absent from a
  toolchain falls back to `PATH` rather than raises, because what `koch tools` produces moves
  between Nim versions.
- Rejected: a directory that a delegate populates by hand, which leaves the defect for anyone
  who has not. Rejected: the layout of `choosenim`, a second convention that cannot serve a
  commit pin at all.
- Costs: the checker reaches the network, and may build a compiler. That is seconds for a
  release and minutes for a commit, once for each pin. Each cached toolchain is a few hundred
  megabytes, and nothing prunes them.
- CI is untouched. The installed compiler of every job already satisfies its `matrix.nim`, so
  resolution stops at `PATH` and never fetches.

**The fetched tarball is checked against the digest published beside it.** This paragraph used
to record the opposite as a cost, trusted on TLS alone, "because Nim publishes none in a form
worth parsing". That was simply wrong. `<tarball url>.sha256` is exactly the output of
`sha256sum`, for every release checked. `fetchRelease` now fetches it, and refuses a tarball
whose bytes differ.

- What it defends against, stated rather than overclaimed: the digest comes from the same host
  over the same TLS as the tarball. So it catches a truncated, mirrored or swapped file, and
  **not a compromised nim-lang.org**. A signature would answer that, and none is published.
  `.asc` beside these tarballs is a 404, read rather than assumed.
- Text that is not a digest reads as *nothing*, rather than as a digest that cannot match. So
  an error document or an empty answer reports "none published" instead of "mismatch". The two
  are different failures, and say different things to whoever reads the line.
- `KOCH_SYSTEM` gains `coreutils` for `sha256sum`, and `tar`, which `fetchRelease` has always
  shelled out to and the original declaration missed.
- Verified by a break of it, and not by a fetch that happened to pass. `tcompilers.nim` digests
  a temporary file, changes one byte, and checks that the digest moves. The parse is
  mutation-tested: drop its hex validation and the suite reddens. Driven end to end on
  2026-09-10: `2.2.2`, which nothing on this machine served, fetched, digest-checked and
  unpacked in **4.6 s**.
- Honest limit of that test: the exit-code check of `sha256sum` is belt-and-braces, because
  the parse already rejects the error text, so no test distinguishes it. It is kept for saying
  what it means.
- Verified by `ttoolchain.nim`, `tcompilers.nim` and `tprojects.nim`, and driven end to end on
  2026-09-06. `curator/probe` pinned to 2.2.6, with nothing local to serve it, fetched the
  tarball and ran in **7.6 s** cold, and 3.0 s warm. Then one command, with only 2.2.4 on
  `PATH` and four projects across two pins, gave **0 findings in 3 m 37 s**. The log held no
  Atlas mismatch warning. A pin that nothing can serve is one finding, which names the
  pin and the cache it tried, and not a crash.

## Dependencies

**Atlas for each project: requirements in `<project>.nimble`, checkouts in an ignored `deps/`,
exact commits in a committed `atlas.lock`, and paths in a committed `nim.cfg`.** `koch deps`
runs `atlas --noexec rep` in every project that holds a lock. It judges success by
`atlas changed` exiting zero.

- Rejected: one Atlas project at the root. Atlas 0.9.0 has no shared-workspace model, and a
  root `nim.cfg` would leak every dependency into every project through parent-config lookup.
  The constitution also wants each dependency justified where it is imported (II.8).
- Costs, verified in the spike. Atlas clones nim-lang/packages before any command, so it needs
  the network even for zero packages, which is why a lock-less project skips it. `atlas rep`
  exits 1 after a restore, because its submodule step fails, and that is why `atlas changed`
  gives the verdict. A dependency used by two projects is cloned twice.
- Verified by `tdependencies.nim` for the parser and the lock-less skip. The Atlas command
  flow was verified by hand on a throwaway project, 2026-09-05, and stays assumed for CI until
  the first real dependency lands.

**`atlas changed` alone does not prove that a restore happened.** It exits 0 while it warns
`repo missing!`, so a restore that fetched nothing reported success. `checkCheckouts` reads
the `dir` of every lock item, resolves `$deps`, and demands that the directory exists before
`atlas changed` is consulted. Measured on Atlas 0.9.0 by a delete of `deps/` and a re-run.
Cost: the lock is parsed twice for each restore. Verified by `tdependencies.nim` over a
project with and without the directory, and over a lock that is not JSON.

**The lock silently reverts an edit to the nimble file.** `atlas.lock` stores a whole copy of
the nimble file under `nimbleFile.content`, and `atlas rep` writes it back over the file. So a
requirement edited without a regenerated lock is undone on the next `koch tests` or `koch ci`.
Nothing fails at that moment, so the loss surfaces later, as a `koch tree` finding on a
reverted line that the contributor never wrote. `rga_visualiser` reported it as issue 25, and
it was reproduced here. `checkLockNimble` compares the stored copy against the committed file,
and reports the first differing line.

- The comparison runs in the static pass, over the tree as git holds it. Run after
  `restoreAll`, it would compare the file against the copy it had just been written from, pass
  always, and cover nothing. That is the defect `atlas changed` already taught.
- The finding points at the nimble file rather than at the lock, because that is the file the
  restore overwrites, and its line numbers resolve.
- Costs: a project that changes a requirement must regenerate the lock, or make the stored
  copy match. `atlas pin` writes `"items": {}` for a dependency whose repository carries no
  nimble file, so a hand-patch stays necessary until Atlas changes. A lock that stores no copy
  is compared against nothing.
- `auditTree` is a `proc`, because it composes a check that reads JSON, which Nim marks
  effectful. Every rule it composes stays pure, and `layout.nim` still reads paths only.
- Verified by `tdependencies.nim`, and driven against the real lock. A stored copy that holds
  `nim >= 2.2.6` names `rga_visualiser.nimble:13`, and the restored lock is silent.

## Scoped checks

**The static pass stays whole-tree, and only compilation is scoped.** A project enters the
test set when a changed path under it is anything but its three records (`PROJECT_FILES`). A
change to `koch.nim` or `koch.nim.cfg` selects the project of the driver, whose suites read
them. A change under `curator/audit/src/` selects it as code. Nothing selects every project.

The push run on `main` plans against the base of that push, and the weekly run against its
window. So every run compiles what changed and nothing else (CURATOR.md duty 11). The suite of
a contributor is the contributor's to run. A path inside no project selects nothing by itself.

This was chosen against a scope on the static pass, on the figures below. The static pass is
hundredths of a second against tens of seconds of suites. So to scope it buys nothing
measurable, and costs a second code path plus the whole-tree layout and stamp guarantees.
Rules propagation therefore compiles nothing, while every stamp is still checked.

- Cost: a change to the checker can leave an unchanged project red until it next changes, and
  nothing compiles it sooner. To run that suite is the work of that project, which is the
  point of the rule.
- Cost: `isChecker` reads the path, and never the content. So a comment edit in `koch.nim`
  compiles the project of the driver: one project, seconds. The machinery to do better exists,
  because `comments.nim` already extracts comments for each kind, so `plan` could ask whether
  anything but comments changed. It is rejected, because that detector errs toward compiling
  too little. A wrong "comments only" reports green for work it never did. That is the
  failure this repository refuses everywhere else, and the reason `nimcache` is still
  uncached.
- Verified by `tplan.nim`, and driven against the history of this repository. A README-only
  commit plans `[]`, and a one-line source change plans that project alone. A change to
  `koch.nim` plans the project of the driver alone, and the sweep plans what merged in its
  window.

**The sweep fires, and it promises a day rather than an hour.** Observed on 2026-09-07, the
first Monday after the cron landed. All four projects planned, each on its own pin, and four
jobs started within one second. The phase finished in about four minutes, against about nine
summed.

It fired **6 h 09 m after its 06:00 slot**, which is what GitHub does with `schedule` under
load. So a curator who reads the cron and returns at 06:05 finds nothing, and wrongly
concludes that the guard is broken. To wait is part of a read of this signal.

**The sweep plans what merged inside `SWEEP_DAYS`**, and nothing in a quiet week. It judges
"code" by the record-file exclusion that scoped runs use. Rot arrives with merges, and to
compile a project that nothing touched is runner time for no information.

- Rejected, by the rule of the Architect that every run covers what changed: a sweep of every
  project whenever anything merged. Cross-project rot from a checker change surfaces when that
  project next changes.
- Cost: rot from outside the repository goes unseen through a quiet week, such as a runner
  image that moves under a pinned compiler.
- Cost: the window is named twice, as the cron and as `SWEEP_DAYS`. Nothing checks that they
  agree, so CURATOR.md duty 9 says to change them together.
- A repository younger than the window has every commit inside it. So the skip is verified by
  suite rather than by a live Monday. `tplan.nim` drives the decision over code, record-only
  and empty changes, and `ttree.nim` drives `revBefore` at both ends.

## Project runner

**`testament --nim:<absolute> pattern "tests/t*.nim"` in each project directory, serially,
with the output streamed.** Koch holds the verb once, and no build file for each project
exists. The compiler path is absolute, because testament resolves `--nim` against its working
directory. A failure is a finding at the `tests` directory of the project, and it echoes the
exit code.

Each project carries a `Target`: its directory, and the `bin` of the toolchain that serves its
pin. Tools come from that `bin` rather than from `PATH`, because two projects on two pins
would otherwise share one compiler in silence. Cost: it is serial, and a project in another
language needs its own runner arm. Verified by `tprojects.nim` with a passing and a failing
fixture, driven through real testament.

## Tests

**Testament over `tests/t*.nim`, with each stub carrying the header from STYLE.md §6, and
without `-r`.** `-r` would run every test twice, and `--outdir` breaks the search of testament
for the binary. So binaries sit beside sources, and git ignores them everywhere
(`**/tests/t*`). Suites are named after the articles of the constitution, and every assertion
carries a citation. Fixtures are built by `fixtures.nim`: a smallest clean tree with a project
under each root, and throwaway git repositories.

Every project carries suites, and those of `dance_ontology` dominate every whole-tree run. No
count is written here. Two written counts went stale within days, and
`git ls-files '*/tests/t*.nim'` answers in a second. Verified by a run of `nim r koch tests`
over every project, 2026-09-08. Every suite passed, with 0 findings, each on the compiler that
its project pins. Only one of the three pins was on `PATH`, which is the point of that verb.

## Type checking

**The runner reaches the TypeScript of every project through the verb of that project.**
`koch types` restores node tools from the lock of the project, and runs
`tools/build.nim types`. That verb derives whatever those scripts read, and type-checks every
configuration, and it stops before anything that needs a browser. Koch names the verb and
nothing else, because what a check needs differs for each project, while the name need not.

- **Enrolment is derived, and never listed.** `nodeDirs` selects the projects that hold
  `package.json` beside `package-lock.json`. So a project enrols by carrying them, and no
  second list can drift. The lock is demanded because `npm ci` needs one, and unpinned tools
  would be the one thing here that nothing pins.
- **No pin is resolved and no toolchain fetched**, because `tools/build.nim` compiles no
  project code. It derives declarations by a read of source as text. To build a commit-pinned
  compiler to run a build script would cost minutes for no checking. Cost, and the condition
  it rests on: this holds only while a `types` verb compiles no project code. One that did
  would need its pin, and would become a matrix job.
- **Scoped, unlike `tests`.** With no matrix, the scope lives in the verb, which takes the
  projects that one change asks for, by the `testSet` rule. `--all` drops that for the sweep.
- **Absent npm is a finding that names it, and never a skip.** A check that quietly does
  nothing reports green for work it never did.
- Driven against the regression it exists for, 2026-09-07. A rename of `nimSceneHandles` to
  `nimSceneSlots`, with nothing else touched, reports one finding over `TS2304` at four sites
  in `construct_section.ts`. Reverted, it reports 0 findings. The whole verb costs 11 s cold,
  with `npm ci` included.

## Driven checks

**The runner drives what the suites cannot reach, through the verb of that project.**
`koch driven` restores the checkouts and node tools of a project, then runs
`tools/build.nim drive`. The verb builds the page and drives it through held keys, wheels,
right-button pans, two-finger pinches and long presses. Testament tests rules, such as what a
slide does to the pivot, and nothing in it presses a key. So a rule wired to the wrong event
is the class of defect that no suite here could see. `rga_visualiser` had 135 such checks and
the runner ran none, which made every one of them evidence that its writer ran it.

**Enrolment is the verb, read from the driver of the project itself.** `verbDirs` reads the
dispatch of `tools/build.nim` and selects the projects that name `drive`, which is the
derivation `nodeDirs` uses one step earlier. The parser is not a second one. `dispatchVerbs`
already read the dispatch of koch, and now takes the opening line as an argument. Koch cases
over parsed options, and a project driver over its first argument. Cost: a project that
spells the verb otherwise is passed by in silence, which is why CONTRIBUTOR.md names `drive`
and `system` outright.

**It is a matrix on the own pin of each project, where `types` is one plain job, and that
difference was measured.** The first cut mirrored `types` on the same argument. A run of it
refuted that in thirteen seconds. `drive` calls `web`, which runs `nim js` over `bridge.nim`,
which compiles project code and everything it imports. So `rga_visualiser` on the 2.2.4 of the
driver fails inside `multivectors.nim` of `pga`, whose syntax only the pinned commit can lex.

The type-check record had written down the exact condition it rested on, and this is that
condition arriving. So `driven` is planned like `tests`. `plan --driven` filters what `plan`
already selected, which is what makes it inherit the scoping, `--all` and the sweep.

**System packages are installed from the declaration of the project, and never from names in
the workflow.** `koch system` runs the `system` verb of each selected project, and prints the
union, sorted and deduplicated. The job pipes it into `apt-get`. Koch prints and never
installs, because which package manager serves a name is the business of the machine, while
the list is the project's.

Only bare names survive the read. The contract is one name to a line. The one other thing
that reaches that stream is the compiler complaining, which always spells a position first. So
a line that carries whitespace is dropped. A compiler that complained still fails, because the
absent package names itself.

**The shared store is cached, and `build/fonts` no longer is.** `koch assets` fetches into
`~/.cache/koch/assets`, and that store is the repository's. So the cache keys on its
declaration, `curator/audit/src/assets.nim`, and one entry serves the job of every project
rather than one entry for each project.

What moved is where the cost is. The fetch is 6.6 s cold, and the copy into `build/fonts` is
milliseconds. So a key on the driver of a project cached the cheap half and missed the
expensive one. Repository issue 132 raised that with the figures.

A looser `restore-keys` prefix is safe here by construction rather than by check, which is
unusual and worth stating. The store names entries by digest, so an entry that no row
declares is unreachable rather than wrong. `koch assets` fetches whatever an older restore
lacks.

Populated, and not yet proven. On its first run, 235, `assets-Linux-…` found nothing to
restore, and saved on the way out. That is what a cache created one pull request earlier does,
and its test is the next `driven` run.

What that run did settle is that to drop `build/fonts` costs nothing. It wrote
`Wrote build/fonts (12 faces, 12 copied)`, then `(12 faces, 0 copied)`, because `assets` runs
twice in each job and the second pass finds every face already in place.

**The browser that a declaration names is the browser that runs, and the snap serves.**
`apt-get install chromium` on `ubuntu-latest` gives `/snap/bin/chromium`, a wrapper rather
than a plain binary. Whether Playwright would launch one was unknown while this was written.
It launches. This is recorded because the opposite result had a different remedy. A package
that did not serve the runner would have been the declaration of the project to change, and
never a name quietly substituted here.

Verified on the runner, 2026-09-07, which is the only place the claim means anything. **136
of 136 checks passed, 0 findings, in 5 m 30 s**, in a real Chromium over real gestures, with
`audit` reading its verdict. Verified locally first by the same verb, 2 m 36 s warm and 3 m
31 s on a tree whose `build/` was removed. Verified by a break of it. On the 2.2.4 of the
driver the same command fails inside `pga`, which is what sent this to a matrix.

Verified by the gap it found before it ever went green. On a cold checkout the first run
stopped at `Missing face … run 'assets' first`. Every expensive step was done and one cheap
one was missing, because `drive` chained `web`, `types` and `declare` but not `assets`. That
was invisible to its writer, whose `build/fonts` was always there.

## Watching main

**A red `main` opens its own issue, because to remember to look had already failed twice.**
The opening duty of CURATOR.md said to read the latest `push` run, and named its own hole in
the same breath: *"nothing else watches it"*. A merge by a contributor went red with nobody
looking, and was found by accident twenty-four minutes later. Then the driven job was red on
two `main` runs. The curator who had named that run as the leg still to read did not read it.
Both times the enforcement was somebody remembering, and the failure was silent.

`watch.yml` reads the run, and opens an issue labelled `curator` when it concludes failure,
which is the first read of that same opening duty. There is no new rule. An existing rule now
produces an artefact that the rule already asks the next delegate to read. The answer of this
repository to a delegate that ends and takes its intentions with it is an issue labelled
`curator`.

It is a separate workflow, because a run cannot watch its own outcome. `workflow_run` fires
only from the copy on the default branch, so it cannot be driven from a branch at all. That is
why it also takes `workflow_dispatch`, which names the run to read.

There is one issue rather than one for each red run. A watcher that opened an issue for each
run trains its reader to skim, which is the failure it exists to prevent. The marker in the
body is what makes a later red comment on the first. Open issues are read directly rather than
searched, because a cold search index would produce exactly the duplicate being avoided.

**It left the list in CURATOR.md of what no check can reach, which is the direction that list
moves.** That section held four rules, and described a fifth without a listing of it. The test
for membership is now written there. It is not whether a check would be awkward, but whether
the rule turns on a fact that something already writes down. The conclusion of a run is one.
The agreement of a glossary term is not.

**A `permissions` block is the whole grant, and never an addition to the default.** A scope
left out of it is set to `none`, and not left alone. Written without `actions: read`, the
first firing got `Resource not accessible by integration (HTTP 403)` on its very first call,
as it read the run it was pointed at. The job log showed
`Contents: read, Issues: write, Metadata: read`, and no Actions.

`workflows.nim` now reports a scope that the steps of a workflow demonstrably use and that its
own block omits, over every file under `.github/workflows/`. It is narrow on purpose. It reads
what steps call, rather than what they might. A workflow that declares no block is left alone,
because to take the default of the repository is somebody's decision rather than drift. Cost:
the marks are text, so a step that reaches the same endpoint by another spelling goes unseen.
That is a floor rather than a ceiling, and the module says so.

The same failure answered a question that pull request 89 had flagged as unknown: a repository
setting does not cap this. `Issues: write` was granted. The failure was the curator's own.

*Checked.* Verified by a firing of it against real red runs, rather than a manufactured one,
2026-09-09. Dispatched at run 34165524898, which is `main` at the merge of pull request 70,
it opened issue 99. That issue named the run, and both jobs that concluded failure, `driven`
and `audit`. Dispatched again at run 34167220207, red at the merge of pull request 72, it
commented on issue 99 rather than opened a second one.

Runs 3, 4 and 7 fired on real `check` completions and concluded `skipped`, which is the guard
working on green. Issue 99 was closed after.

Verified by a break of it, before that. Delete `actions: read` from the workflow, and
`koch tree` reports it by name and by what was granted. Restore it, and 0 findings return. The
commit of that check precedes its fix on the branch, so it fails where it stands (Article
IX.8).

**Unverified**: nothing has yet driven this from a `main` run that went red on its own. Every
firing so far has been dispatched at a run already known to be red. So what is proven is the
reading and the reporting, and not the selection of the trigger itself. That waits on a red
`main`, which is not worth causing.

## Continuous integration

**Nine jobs, and the three required check names have never changed.** `plan` emits the
matrices, and `static` runs `nim r koch tree`. `project` is one matrix job for each planned
project, on its own pin. `driven` is a second matrix over the subset that carries that verb,
and `types` is one plain job on the compiler of the driver. `scope`, `commits` and `base` run
only on pull requests, with full history. `audit` is a gate that reads the rest.

The gate exists because matrix job names vary with the change, and can never be required
checks, while `audit`, `scope` and `commits` must stay required. Every job added is named in
the `needs` of the gate as well as declared. A job outside it is a red check that cannot block
a merge. That is the one mistake this arrangement makes easy to make, and impossible to see
afterwards.

- Rejected: a rename of the required checks, which would make the Architect reconfigure
  `main`. Rejected: a computation of the matrix in shell, which is untested glue where koch is
  tested.
- Branch names and the event kind reach koch through the environment, and are never
  interpolated into the script. Nim installs under the temp directory of the runner, and never
  the workspace. `.gitignore` lists `.nim_runtime/`, because the audit reads untracked files.
  A toolchain inside the checkout was audited as source once, at 33,367 findings on the first
  run.
- The empty matrix was verified separately, because no ordinary run took that path. A
  record-only change emits `[]`, `project` is skipped, and the gate passes on a skipped
  dependency. It is written to pass on `skipped` and to fail on `failure` or `cancelled`, and
  until that run only the first half had been exercised.

**`koch audit` was removed, and `koch tests` with no project is what replaced it.** The old
verb ran the static pass, and then the suites of every project on the one compiler that `PATH`
held. So once the pins differed it always exited 1. Since koch resolves each pin (Toolchain),
`nim r koch tests` alone runs every project on its own compiler, and `ci` stays scoped to what
a change touched. Cost: to check everything locally is two commands, `tree` and `tests`,
rather than one.

**`nim r koch ci` is the local form of the jobs.** It fetches `origin/main`. It then runs the
whole-tree pass, and the restores and suites of the planned projects. It runs the type check,
the driven checks, scope, commits and base, all in one process. Every pull request passes it before
somebody opens it. The runner confirms, and it never discovers.

- Cost: one network fetch for each run, accepted so that the base is the one CI will use.
- Cost: a curator whose change selects every project needs every pinned compiler, which
  resolution provides. It also needs npm, a browser and the declared packages of each driven
  project, which resolution does not provide.
- `ciJobs` resolves the pins once, restores once, runs the suites, and then drives the
  projects that carry driven checks. Before it, `runJobs` and `drivenJobs` each restored a
  driven project, and the second restore was Atlas confirming that nothing had moved. That was
  seconds for each project in each run, and work nobody asked for. A failed restore still
  stops the driving alone, as it did.

Two traps, each found by a merge rather than by a read.

- **A re-run reuses its original merge commit and workflow file**, so a fix on `main` reaches
  an open pull request only through a new head. Merge `main` into the branch, and never re-run
  and hope.
- **Two stamped changes in flight produce a third stamp that neither one carries.** Each
  re-stamps every project against its own `CONTRIBUTOR.md`. Git merges their edits cleanly
  where they touch different sections, but the merged document digests to a value that matches
  neither. So whichever merged second would leave `main` red on every project. The cure is to
  stack rather than discover. Merge the earlier branch into the later, run
  `nim r koch stamp --write` on the merged rules, and fix the merge order.

## The checker checks itself

Nothing checked the checker, so faults that it would report anywhere else lived in it. There
was a routine exported and called nowhere, two modules with no suite at all, and a table that
named a retired verb. `checker.nim` makes each one a rule, so the next one is caught by the
runner rather than by a curator who reads.

- **Dead export**: a routine exported from a check module and named nowhere in the checker.
  Mentions are counted as identifier runs rather than as whitespace words, because
  `tree.auditTree` is a call exactly as `auditTree(tree)` is. A count of words reported six
  live routines as dead on the first run.
- **Missing suite**: a check module without `tests/t<module>.nim`.
- **Verb drift**: one set named three times. The names are the verbs that koch dispatches,
  the verbs that its usage prints, and the rows of the checks table in CURATOR.md. Verbs are
  read from
  the command dispatch alone, bounded between `case options.command` and its `else`. The
  option parser cases over labels a few lines above, and contributed `root`, `all`, `branch`
  and `sweep` before that bound existed.
- Rejected: a flag on an export that only tests use, which is how every pure rule here is
  covered, and would need an exemption list. Rejected: a warning rather than a finding,
  because a warning that nobody must act on is read by nobody. Rejected: one suite for each
  module in contributor projects, which group tests by subject.
- Costs: a routine named in a comment is not dead, so prose that mentions a retired routine
  hides it. That is paid to keep the rule free of false findings. An exported operator is
  skipped, because it is spelled at call sites rather than named. The other columns of the
  table stay prose that no check reads.
- Verified by `tchecker.nim`, and driven. A routine added and never called is one finding that
  names it. A row deleted from the checks table is one finding that names the missing verb. A
  verb dropped from the usage line is one finding that names what usage prints.

The same reasoning deleted the hand-written copy of the module graph in `audit.nim`, which was
wrong in five places. A copy of a graph drifts from the graph, and the `import` line of each
module is the graph.

## Figures

Measured with `date +%s.%N`, over three consecutive warm runs, on a Linux amd64 container with
four Intel Xeon 2.10 GHz cores, Nim 2.2.4, 2026-09-06. Warm means that every test binary was
already compiled.

| Command | Compiles | Wall |
|---------|----------|------|
| `nim r koch tree` | nothing | 0.028 s, 0.023 s, 0.022 s |
| `nim r koch tests curator/probe` | one project | 1.776 s, 1.732 s, 1.832 s |
| `nim r koch audit` (since removed) | every project | 54.156 s, 53.887 s, 53.570 s |

The first and third rows are the pair for scoping. Before it, a push cost the third row
whatever it touched. After it, a change to one project costs the second, and a change to
records alone costs the first. That is roughly thirty times less for the common case, and it
no longer grows as projects arrive.

Take the real path rather than a synthetic one. A commit whose only changed path is this file
plans `[]`, and finishes `nim r koch ci` in 0.721 s, with its `git fetch` included. Re-measure
when the suites of a project grow. Otherwise treat this as unmeasured.

**Matrix jobs do run in parallel**, verified on the runner from the first run of this
arrangement. Three `project` jobs started within one second, and finished at 16 s, 52 s and
121 s. So the phase took 121 s rather than the 189 s their sum would be. The saving is the sum
minus the slowest, so it grows as projects arrive.

Cost from the same run: matrix jobs cannot start until `plan` reports, which puts 16 s between
the run starting and the first project job. That is a floor on every run, and the price of a
matrix computed in tested Nim rather than in shell.

**What the driven check costs, and where it goes.** Locally, `koch driven` on `rga_visualiser`
takes 2 m 36 s warm. Roughly two thirds of that is the deliberate wall-clock windows of the
harness itself, rather than anything a faster machine shortens. That was recorded as a local
figure that should not be treated as a prediction of the runner's, and it did not predict it.
The job on the runner is 5 m 31 s on the same checks. The gap is apt install, a restore of a
2.4 GB compiler from cache, and a slower core.

The rule that produced the right expectation outlives the number. A figure from one machine
predicts the figure of another only where what differs has been measured.

| Step of the `driven` job | Wall |
|--------------------------|------|
| read the declaration and `apt-get install` | 1 m 47 s |
| `nim r koch driven` | 3 m 04 s |
| restore the commit-pinned compiler from cache | 28 s |

The install is 32% of the job. It is also an upper bound on what a `koch system` asked for
each verb could save. The same step compiles koch and runs the verb of the project. That is
the figure behind the ruling that `system` stays per project.

**The caching pair is settled, and it is not the pair expected.** Four caches restore on the
driven job: the store of npm, the Atlas checkouts, the commit-pinned compiler, and the faces.
The compiler is the whole figure. To restore it is seconds, where a build from source is fifteen
minutes. That is what an uncached `driven` run would have cost. Every other cache is noise beside
it: `npm ci` runs in 2 s cached, and six faces are 1.5 s uncached.

A cold half for npm and faces was never taken under runner conditions, and cannot be taken now
without a key deliberately poisoned. That measurement is dropped, rather than left owed.

**The static pass on another machine**: `nim r koch tree` warm is 1.42 s, 1.41 s, 1.43 s on a
four-core Intel Xeon 2.80 GHz container, 2026-09-08. That is fifty times the row above, on
nominally faster cores. What differs between the two containers has not been measured. So this
sits beside that row rather than replaces it, and neither one predicts the other.

**The install prefix of SDL3 is cached, the build tree beside it deliberately is not, and the
first key did not work.** No package carries SDL3, so `sdl3` clones, configures and builds it
from source. That is **55.8 s of the 357 s of run 214**, the largest single step that nothing
cached. It is larger than either lever that repository issues 79 and 80 were weighing.

- The prefix is what makes the verb return early, because `versionSdl3` reads
  `build/sdl3/lib/pkgconfig`. So to cache the product is enough, and to cache the cmake tree
  is unnecessary.
- It is also what makes it *safe*, and that is measured rather than reasoned. A cmake build
  tree carried over from a configure that had found no X11 kept reporting
  `SDL not configured with OpenGL/GLX support` after the headers arrived. It cost an hour on a
  container that had them. A product caches. A build tree remembers what it decided about a
  machine that has since changed.
- **The first key never once hit, and that is measured, and not suspected.** Keyed on the
  exact hash of the `tools/build.nim` of the project, it missed on both `driven` runs after
  it merged. Those are run 221 at `fb1fba1`, and run 226 at `b2fa891`. Each printed
  `Built SDL3 3.2.30 into build/sdl3`, where a hit prints
  `Kept SDL3 3.2.30, already reported by pkg-config`. Each ended `Cache saved` rather than
  `Cache hit`.
- The reasoning that picked the key held that the file carries both `COMMIT_SDL3` and
  `SYSTEM`. A moved pin or a changed package list then misses it. That is true, and beside the
  point. The file also carries everything else that a build driver carries, so it changed in
  two consecutive pull requests, and the key changed with it. A key has to be specific enough
  to be correct **and** stable enough to hit, and only the first was checked.
- **`restore-keys: sdl3-<os>-` fixed it, and run 235 is the evidence.** Read from the log of
  that job, on `f9e54ad`, 2026-09-12:

  ```
  11:19:07.307  Cache restored from key: sdl3-Linux-4f98cd632350a0d7…
  11:22:06.233  Kept SDL3 3.2.30, already reported by pkg-config
  11:22:06.236  Cloning into 'deps/imgui'...
  11:24:22.091  Cache saved with key:    sdl3-Linux-75e9e2df1e0287f4…
  ```

  It **restored from a different key than it saved under**, which is the whole mechanism. Pull
  requests 136 and 137 moved `tools/build.nim`, so the exact key missed exactly as before. The
  prefix matched an older entry, and `versionSdl3` read the restored `.pc` and returned early.
  The SDL3 phase runs in **about 20 ms**, against 55.8 s built, at a restore cost of roughly
  1 s in the cache step. The job logs **zero** `Building C object` lines, against roughly a
  thousand in run 226.
- **No whole-job figure is quoted, and that is deliberate.** Run 226 took 290 s with SDL3
  built, and run 235 took 314 s with it kept. But 136 and 137 added a menu and a *scene filled
  to capacity* driven run that alone costs 86 s. Those two numbers measure different work, and
  to subtract them would put a false saving in this file where a false prediction used to be.
  The phase figure above is the pair, and the job figure is not one.
- Cost: most runs stop exercising the SDL3 build. Every cache here trades that. The pin is a
  commit rather than a mutable tag now (repository issue 126, answered by pull request 131).
  So what the cache hides is a rebuild, rather than an upstream that moved underneath it.

**The allowance of GitHub belongs to one account, and every delegate spends it.** Measured
2026-09-12, on this repository, after a curator delegate stopped being able to close an issue:

| | limit | state when it failed |
|---|---|---|
| GraphQL | 5,000 points per hour per **user** | exhausted |
| REST | 5,000 requests per hour per **user** | healthy throughout |
| Secondary, shared | 80 content-creating per minute, 500 per hour | not reached, ~15 made |

The two primary allowances are separate, which is how the cause was found. `actions_list` and
`get_job_logs` kept answering, while `list_issues` refused with
`API rate limit already exceeded for user ID 1268439`. A GraphQL call gives itself away by its
cursor pagination, an `after` and an `endCursor` from a `pageInfo`. A refused mutation fails
at *"failed to get issue ID"*, which is the node lookup before the write.

**The split is by API and by nothing else, and this table said otherwise for a day.** Its rows
were first labelled by subject: *GraphQL, for issues, pull requests and comments*, against
*REST, for workflow runs, jobs and logs*. That reads well and is false.

`rga_visualiser` found it. `list_issues` and `update_pull_request` were refused in the same
seconds that `create_pull_request` and `pull_request_read` answered, in the same repository,
with pull-request calls on both sides. The subject labels could not survive that, and neither
could the charter wording derived from them.

- **It is per method, and not per tool.** `pull_request_read` pages its review-comment method
  by cursor, and its others by `page` and `perPage`. So one tool sits on both meters, and no
  name at the call site says which.
- **Measured again the same afternoon, and the second time under control.** To mark pull
  request 148 ready was refused, while calls seconds either side of it answered.
  `create_pull_request`, `actions_list`, `add_issue_comment` and `issue_read` all went
  through, and `update_pull_request`, `issue_write` and `list_issues` all refused. Seven
  calls, one window, one repository, with no room for the allowance to have run out in
  between. That is the confound the first measurement had.
- That refused `update_pull_request` passed **only** `draft`, so the draft toggle itself is on
  the GraphQL meter. To open a pull request, an ordinary REST `POST`, is not. What is still
  not established is whether the other fields of the tool take REST, because no call has
  isolated one.
- **So no delegate can route around it by a choice of tools.** That is why the guidance in
  `CONTRIBUTOR.md` and `CURATOR.md` is the observable rule rather than the mechanism. A
  refusal on one call says nothing about another, so try the one you need before you decide
  that GitHub is shut. The wrong version would have had a contributor sit out a window in
  which their pull request would have opened.
- **Per account, and not per delegate.** Every delegate posts as one account, so one allowance
  covers every delegate that runs at once. `rga_visualiser` merged three pull requests and
  raised an issue in the hours before this. That is not a complaint about that delegate. It is
  the shape of the problem, because nobody can see what the others have spent.
- **The expensive half was avoidable, and was the curator's.** The guidance of the MCP server
  itself says to page in batches of five to ten, and to ask for minimal output. This delegate
  listed twenty, thirty and forty issues with bodies and comments, several times, and read
  back things that `git log` already knew. The guidance now sits in `CONTRIBUTOR.md` and
  `CURATOR.md`, under the queue and the shared allowance.
- **It did not clear quickly.** Twenty minutes after the first refusal it was still refusing.
  A delegate that hits this does not wait it out inside one piece of work. The honest
  outcome is the unticked item on the carried list, which is what happened.
- Unmeasured: what a single `list_issues` actually costs in points. The server surfaces no
  `x-ratelimit-remaining`, so the budget is spent blind. That is the strongest argument for
  asking git first, rather than for tuning page sizes.

**Two caches are deliberately not kept, each measured rather than feared.** A restored
`nimcache` cannot let a check pass without a compile of what it claims. That was driven over
an ordinary rebuild, over a cache made six years newer than backdated sources, and over a full
save, mutate and restore. Nim decides by content rather than by mtime, and every case rebuilt
correctly.

But it can only skip Nim compilation, at most about 16 s of a 357 s driven job. The modules
that matter on such a job are exactly the ones it cannot serve. To cache apt archives saves
the download and not the install. That is 2.8 s of a 357 s job, which is 0.8%, for a
root-owned directory and one key. Both figures are from one `driven` run on 2026-09-12, and
they expire with the job they measured.

**Koch declares its own system dependencies, as the rule it enforces asks of every project.**
`KOCH_SYSTEM` in `projects.nim` pairs each one with its reason. `koch system` with no project
prints those and every project's, unscoped, so one command answers what a machine needs before
any of this runs. To name a project keeps the meaning for each job that the runner asks for.

Nim is deliberately absent. It is the toolchain that koch runs under, rather than a package
that a machine installs, and `compilers.nim` resolves each pin itself. npm is absent
because it belongs to the project that carries a node manifest, and `restoreNode` reports its
absence by name. The root `README.md` points at the verb rather than names packages, so the
declaration is the only statement and nothing can drift from it.

Rejected: an exemption stated in `CONTRIBUTOR.md`, which would have left the rule true and the
repository still answering its own question in prose. Cost: the packages of koch itself are
unconditional, so a machine that needs none of them still installs them (repository issue 78).

## Open questions

None.
