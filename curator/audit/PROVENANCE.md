# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | c73f63e83992089d |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |
| Pruned  | ab8fb063b62bb03ba9fd7f2964a1866b3862909b |

Origin: built from the brief of the Architect, the constitution, the Nim style guide and the
provenance guide, all supplied by the Architect. Its shape is the direction of the Architect:
two project roots, driven by koch, with Atlas for dependencies. There is no vendored source.

This file describes the checker as it is. The log holds how each part came to be (Article
XI.2), and the `Pruned` row names the commit before the last prune. A trap that a later curator
would otherwise find again sits beside the decision that carries it.

## Build glue

**One compiled program, `koch.nim` at the root, as the repository of Nim itself builds.** It
holds dispatch only. Every check is a library module here, and is tested here. A project that
needs more verbs carries its own driver, `tools/build.nim`, which `koch types`, `koch driven`
and `koch system` reach through.

- Rejected: make, which is a second toolchain with recipe tabs and untested glue.
- Rejected: NimScript `config.nims` tasks. They run in the VM of the compiler on a subset of
  the standard library, and load on every compile in the tree. They can shadow compiler
  commands such as `check`, and they cannot be unit-tested.
- Rejected: nimble tasks, which need nimble as a runner.
- Cost: one bootstrap compile for each checkout, and `koch` is a code file outside any
  project. The warm cost of the static pass is in Figures.

## Enumeration

**Git decides what the tree is.** `tree.nim` lists
`git ls-files -z --cached --others --exclude-standard`. It drops the paths absent from disk,
and reads content only for registered kinds. Git runs as a direct process with an argument
list, and never through a shell.

**The two streams are read apart.** Git writes a warning to stderr and ends it in a newline,
while the fields it is asked for end in NUL. One stream that carries both leaves the warning
glued to the first field, because the split never cuts at a newline.

`git diff base...HEAD` warns whenever a branch and its base share two merge bases. That is
ordinary: a branch merges `main`, and `main` later takes another branch that merged it
elsewhere. A glued field then opens with `warning:` rather than with a path. The scope check
then reads a file of the branch as outside its own scope. `ls-files` and `log` warn on their
own occasions, so every caller of `gitFields` reads the two streams apart.

Stderr is kept rather than dropped, because it is where git says why it failed, and the
`IOError` carries it. Both pipes are drained before the exit is waited on, since a child blocks
where one fills while the other is read.

- Rejected: `execCmdEx`, which reads by line and appends a newline to NUL-separated output.
- Cost: no warning of git is reported anywhere. Git writes it for a person to read, and this
  check reads no person's stream.
- Cost: git must be on `PATH`.
- Verified by `suites/ttree.nim` on a throwaway repository: an ignored `bin/` is absent, an
  untracked file is present, and a rename shows as its destination alone. On one built with two
  merge bases, no field holds the warning and every field is a path. A second case holds that the
  `IOError` still carries git's own reason.

## File kinds

**An allow-list of kinds is the registry, and an unregistered kind is a finding.** `kinds.nim`
maps a basename or an extension to a comment syntax, and to whether prose is checked. Its
header table is a derived view of `lut_kind_rule`. Nimble files and NimScript read as Nim, and
cfg files as hash comments. `atlas.config` and `atlas.lock` read as JSON, by basename. Markdown
is prose rather than comment, so articles pass while the form rules still apply.

Html and Svg carry hand-written pages, which the layout check confines to `pages/` or
`mockups/`. Generated markup is one long line, and fails width on its own.

- Rejected: a Makefile kind. The registry admits no second build verb, so no recipe tab is
  exempt, and any tab is a finding.
- Rejected: content sniffing, which lets an unknown kind in silently.
- Cost: matching is by basename or extension only, so `nimble.paths` or `.mk` is unread.
- Verified by `suites/tkinds.nim`, which reads the header table from the source and holds each
  row to the registry. Every match classifies at the root and in a folder, and the Syntax,
  Prose and Gate cells equal the rule of the kind. It also covers the last extension of
  `koch.nim.cfg`, and a set of unregistered names. `tlayout.nim` yields one finding on
  `data.csv`, which names `curator/audit/src/kinds.nim`.

**A gated kind argues for itself in its header, and the gate is checked rather than trusted.**
`Cpp` and `C` join TypeScript as languages admitted only where Nim cannot serve. `.hpp` reads
as C++ and `.h` as C, because the name alone cannot tell them apart. `justification.nim`
demands `not Nim because <reason>` in the opening comment run. A gap of one line is allowed,
so an include guard above the block, and a blank line inside it, both keep the run whole.

- Rejected: the gate as a sentence in `CONTRIBUTOR.md` alone. No check reads that sentence, so
  a second gated language would sit under no gate at all.
- Rejected: the marker anywhere in the file, which admits an argument buried at line 900.
  Rejected: the marker on line 1 exactly, which forbids `#pragma once`. Rejected: a separate
  register of justified files, which is a second place for truth to drift from.
- Cost: the check proves that a justification exists where a reader will meet it, and never
  that it is true. A curator still weighs the claim.
- Cost: the one-line gap can reach a comment on the first line of code. That is deliberate,
  because the alternative is a finding on a correct header.
- Verified by `suites/tjustification.nim` and `tkinds.nim`. Verified by hand over real files,
  2026-09-06. An unjustified `shim.cpp` and an unjustified `glue.ts` each yield one finding at
  line 1. Each falls silent once the phrase is added.

## Comment extraction

**A hand-written scanner for each comment syntax, and one accumulator for each line.**

- Nim: line, doc and nesting block comments, plain, triple and generalized raw strings, char
  literals, and numeric suffix quotes.
- Cfg: `#`, unless `\#`.
- YAML: `#` at line start, or after whitespace, outside quotes.
- Ignore files: a leading `#` only.
- TypeScript: `//`, `/* */`, its string forms, and doc stars stripped.
- Markup: `<!-- -->`, which may span lines.

Whitespace runs collapse, so texts compare stably.

- Rejected: real parsers, which cost dependencies for a question that needs no syntax tree.
- Cost, assumed: a TypeScript regex literal that holds `//` opens a false comment.
- Cost: the markup scanner reads `<!-- -->` only, so comments inside `<script>` and `<style>`
  stay unread. Markup inside a Nim string has the same blind spot.
- Verified by `suites/tcomments.nim` across the syntaxes, including the testament header string and
  markup comments that span lines.

## Prose

**Articles are the whole rule, as data.** `ARTICLES = ["a", "an", "the"]`. Tokens are
whitespace-split, punctuation-stripped and lowercased, after the backtick spans are removed.

- Cost: the label `A`, as in "Appendix A", is flagged. So a label goes in backticks, as
  `prose.nim` writes its own example.
- Verified by `suites/tprose.nim`: 300 seeded random telegraphic comments pass, and each one with an
  inserted article fails. The citation `2.2a`, a URL and an underscored name pass. The corpus
  is seeded with `randomize(0)`, so the 300 are the same 300 on every run. It is the only
  sampled corpus in this project, and that seed is why its verdict does not vary
  (CONTRIBUTOR.md, "Tests are paramount").

## English

**Some rules of ASD-STE100 are mechanical, and the rest hold by reading.** A sentence holds at
most 25 words, and a paragraph at most 6 sentences. `REPLACEMENTS` is a short table of words,
each with one approved replacement. The dictionary of about 900 words belongs to ASD, so no
check can hold all of it. `GUIDE.md` carries the working subset of the other rules.

**The governed set is half data and half derivation.** `ENGLISH_PATHS` holds every root
Markdown document except `LICENSE.md`, and the issue and pull request templates. No rule can
derive those. Everything else comes from the layout. That is the README of each project root
and of each registered domain, and each record directly inside a project directory.

**The derived half needs no row that somebody must remember.** A list with one row for each
record goes one row short at the next project. The records of that project then go unread, and
the audit stays green over prose it never read. The derivation answers from the path, so the
next project is governed from its first line.

**A README below a project directory is outside the set.** `dance_ontology` keeps prose under
`sim/` and `design/` in its own register. With `design/README.md`, `sim/README.md` and
`sim/verdicts.md` added to `ENGLISH_PATHS`, `nim r koch tree` reports 192 findings, measured
2026-09-23. Curator duty 3 forbids a check that reddens a project which cannot see it yet.
Cost: that prose holds Article VI.8 by reading alone.

**A path joins the set only where its prose already passes.** A widening that reddens a project
breaks duty 3, so its findings are measured before the change. A widening costs one finding for
every line of prose written between a rewrite and the widening that follows it. So a widening
is taken as soon as it is free.

**A quotation is skipped whole.** Quoted text comes from outside this repository, and a
delegate may not rewrite it. A finding on it could never be fixed. The `PROVENANCE.md` of
`rga_visualiser` quotes the acknowledgement that the NASA Exoplanet Archive asks for word for
word, and it is longer than 25 words.

- Rejected: an allowlist of exact sentences, which is the grandfathering that curator duty 3
  forbids.
- Cost: the worked example inside the quotation in `GUIDE.md` goes unchecked. It holds by
  reading, as the rest of the guide does.
- Cost: a sentence ends at a stop after a letter, a digit or a closing bracket. A stop after a
  degree sign or a superscript does not end one. Two sentences then read as one, and the finding
  that follows is a long sentence rather than a missed one.
- Verified by `suites/tenglish.nim`: each finding kind, the sentence-end cases and the block
  split. It also covers the collapsed span, the skipped quotation, and a path outside the set.
  That path is `gaps.md`, which a generator writes and no delegate may rewrite by hand.
- Verified by `suites/tenglish.nim`: the derived arms. A project and a domain that do not exist yet
  are governed. A domain outside the registry is not, and neither is a README below a project
  directory. That last arm is the one that would redden `dance_ontology`, so it has its own
  assertion. One more assertion holds that a derived path is read, and not merely listed.

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
- Verified by `suites/tform.nim`: 100 runes pass, and 101 breakable runes fail. A 202-character
  fonts link passes, while 207 of prose and 400 of minified markup do not. A tab in Nim and in cfg
  fails, and every ending case is covered.
- Verified by hand on real pages, 2026-09-05: hand-written markup and a fonts link whose
  longest token is 179 runes audit clean. A generated drawing of 1,407 characters does not.

**A generated npm lockfile passes the width rule.** Verified by hand with npm 12, 2026-09-06: a
generated `package-lock.json` of 93 lines, longest 117 runes, audits with 0 findings. Each long
line carries one `sha512-` digest of 95 runes, and fits without it, so the unbreakable-token
rule passes it. So the shape holds at any lockfile size, and the width rule needs no exemption
beside `LICENSE.md`.

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
are findings, and are never skipped.

- Rejected: an early return under `curator/`, which drops an unknown head in silence, so a
  misplaced project leaves the audit.
- Rejected: domain READMEs that list projects, which forces a contributor to edit outside
  their scope. Rejected: a theme line for root READMEs, which is a fabricated authority.
  Rejected: an inference of mock-up from generated, which makes the distinction an accident of
  formatting.
- Cost: empty directories are invisible to git, so `tests/` must hold a file.
- Verified by `suites/tlayout.nim` over a fixture tree that the tests build. The project list is
  pinned, and the unknown-domain case asserts both the finding and the unchanged list.
  `taudit.nim` proves that fixture clean under every static check.

**Only one check reads substance, and it reads a narrow slice.** `checkCitations` resolves
every claim that opens `Verified by` and names a backticked `.nim` file in the `PROVENANCE.md`
of a project, against the `tests/` of that project. The split of verified from assumed claims
is the most valuable property of a provenance file. Without the check, a renamed suite leaves a
citation that points at nothing.

- Rejected: a match of the claim against what the test asserts, which no checker can do.
  Rejected: a flag on every backticked span, which would catch a command such as
  ``atlas changed``; the `.nim` ending is the guard.
- Cost, the honest limit: a delegate can cite a real test beside a claim that it does not
  make. That gap closes by reading.
- Verified by `suites/tprovenance.nim`. A citation renamed to an absent file, to a source file, or
  to the test of another project reports one finding. `koch tree` resolves every citation on each
  run.

## Provenance stamp

**FNV-1a 64-bit over CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md**, with CR stripped, NUL
between files, and 16 lowercase hex digits. CURATOR.md is excluded, so a curator-only edit
touches no project.

- Rejected: `std/sha1`, deprecated in Nim 2, which warns on every build. Rejected: the
  `checksums` package, a nimble install in CI for one digest. Rejected: `std/hashes`, unstable
  across Nim versions.
- Cost: it is a change detector and not a signature, so a collision needs an adversary.
- Verified by `suites/tprovenance.nim` for determinism, one-byte, order and boundary sensitivity,
  and CRLF invariance. Verified by `suites/taudit.nim`: one byte in any rules document goes stale in
  every project, and one byte in CURATOR.md in none.

**`koch stamp --write` sets the `Rules` row of every provenance file itself.** `withRulesRow`
rewrites the row in place, and finds it as `headerFields` finds it, so what is written is what
the check then reads. A provenance file already current is not touched, and each path that
moved is printed. So duty 1 takes one verb for the rows, and no hand edit (curator review,
C10).

- Rejected: a write of the whole header back, which would reformat a table that its writer
  padded.
- Verified by `suites/tprovenance.nim`. The new stamp lands, and the padding and every other byte
  stay. A second write is a no-op, and an absent row leaves the source untouched. Only the
  first `Rules` row moves.

## Provenance shape

**A `PROVENANCE.md` is read as `#` lines with the fenced code blanked, and is held to the forms
that the guide states.** No heading carries a date. `## Open questions` is the last `##`
section. No heading text appears twice. No title is underlined, because every reader here sees
`#` lines, and an underlined title is invisible to all of them.

**A provenance file over `RECORD_LINES`, 3,000, is a finding.** Its remedy is the prune that
the guide asks for. The ceiling is a backstop, and `SECTION_LINES` is the instrument that reads
narration. Simplified Technical English costs about a fifth more lines than ordinary English,
measured over the provenance files of the repository. So 2,000 lines of ordinary English scale to
2,500, and 3,000 adds a fifth of headroom above that.

- Rejected: 2,500 with no headroom. A backstop that fires on ordinary work reports growth, and
  not narration.

**A `##` section over `SECTION_LINES`, 200, is the same finding, on the unit where narration
collects.** The whole-file ceiling is crude. It punishes a wide project and lets a narrow one
narrate freely. Over the sections that the limit was set against, the median is 34 lines and
the ninetieth percentile is 137. The length of a whole file does not say which section
narrates, and the length of a section does.

- Rejected: 150, which flags more sections than 200 does and no more narration.
- A file that ends in a newline leaves an empty last line, which is not charged to the section
  it falls in.

**The header may carry a `Pruned` row that names the commit before the last prune.** The check
reads the form of that row, 7 to 40 hex digits. Koch reads its existence from `git log` on the
file itself, under `tree` and `ci`. That needs a full clone. A shallow one has no such log, so
the static job fetches every commit.

- Rejected: a split of a long provenance file into files by subsystem. The checker names one
  `PROVENANCE.md` for each project, and the stamp lives in its header. History is git's, and
  the row says where.
- Cost: line forms, and never a Markdown parse. A heading inside an HTML comment counts, and
  front matter is not skipped. No governed provenance file carries either.
- Verified by `suites/trecord.nim`, each form by line. `fencedOut` is verified by
  `suites/tmarkdown.nim`.

## Glossary

**Shape only: a heading, `## Language`, and a definition line after every `**Term**:`.** The
content is the contributor's and the Architect's, and a term enters only when the Architect
selects it. The check cannot know what was agreed, so agreement holds by reading. It runs on
the top-level `GLOSSARY.md` too. Zero terms pass, because the format creates entries lazily.
Verified by `suites/tglossary.nim`.

**The people words that the glossary avoids are held out of the root Markdown files and the
Markdown under `curator/`.** `PEOPLE_WORDS` is the avoid list under Architect, Delegate,
Curator, Contributor and Role, cut to the words for people. It is read whole and without case,
plural included, outside code spans, fences and tables. A glossary is exempt, because it lists
the words it avoids.

- Rejected: the full avoid list, which holds build, rules and version, plain words everywhere.
- `identity` is left out, as the word of algebra in `curator/probe`.
- Contributor prose is not read. Verified by `suites/tglossary.nim`.

## Prompts

**The opening prompts are held to duty 10 by a diary form and a size ceiling.** A prose line
that names a date, `#N`, `issue N`, `pull request N` or `run N` is a finding. An incident
belongs in this file or in the log, and only the rule belongs in a prompt. A prompt over
`PROMPT_BYTES`, 40,000, is a finding, so runaway growth is caught while an ordinary addition is
not. Code spans and fences pass, which keeps the carried-list example legal.

- Cost: `II.9`, `duty 10` and a bare year pass by shape, so only a whole date is diary here.
- Verified by `suites/tprompts.nim`.

## Copies

**A paragraph of 25 words or more, written twice, is a finding.** It is reported at its later
place, and it names its first. That holds within one Markdown file, and across two. Fenced
code, table rows and headings are left out, and whitespace is collapsed before the comparison.
Two copies of one rule drift.

- Cost: a paragraph reworded by one word passes. The check catches a copy, and never a
  paraphrase.
- Verified by `suites/tduplicates.nim`.

## Faces

**Every presentation target ships the faces that Article X.8 names, and line forms hold it.**
A source is read only where it declares `font-family` or the `font` shorthand. The project of
the checker is exempt, because it names the families as data and carries fixture pages. A page
that links a font host is a finding, because the viewer then fetches the face instead of
receiving it.

The first family of every stack is Noto Serif, Noto Sans or Commit Mono, subset aliases
included. The fallbacks after it are free, because the shipped face is what the viewer gets. A
selector whose subject is `h1` to `h6` sets the serif, with one level of `var()` resolved from
the page's own custom properties. A selector that styles something inside a heading is not
styling the heading. A source that names Commit Mono enables `calt`, where its functional
ligatures live.

- Cost: declarations are read and expressions are not. So a stack assembled through `&` is
  unseen, and so is a heading styled through a class alone. The desktop atlas is outside the
  ligature rule by X.8 itself, because Dear ImGui shapes no text, and it declares no CSS.
- Verified by `suites/tfaces.nim`, each rule by line, and the label beside a heading among them.

## Branch scope

**The branch grammar mirrors paths: two, three or four segments, and the scope follows from
them.** `curator/<name>` has the whole tree as its scope, so every path passes.
`curator/<project>/<name>` and `contributor/<domain>/<project>/<name>` own their folder. `main`
passes, because a push to it is a merge that the Architect approved.

- Rejected: a special case for the curator root. The whole tree is a scope like any other, and
  one mechanism reads it.
- Cost: fixed segment counts reject a nested branch name. The Architect may merge red
  deliberately, so this is a guard and not a gate.
- Verified by `suites/tscope.nim` over each branch form and rejected forms. `tdomains.nim` covers
  the rejected forms of the branch grammar.

**The reach of a curator into a contributor project stops at its records.** Under
`contributor/`, the only writable paths on a curator branch are `README.md`, `PROVENANCE.md`
and `GLOSSARY.md`. Those are `PROJECT_FILES`, read from `layout.nim` rather than repeated.
Without this, duty 11 holds by reading alone, on the role that runs most often.

- Rejected: `PROVENANCE.md` and `GLOSSARY.md` alone. A rule change can make the README of a
  project false, for example where it names a pin, and that set blocks the fix.
- Cost: the README stays writable. So restraint about a rewrite of a project's prose is duty
  11's to govern by reading, and never the check's.
- Verified by `suites/tscope.nim`: a curator branch that writes contributor code is a finding, and
  one that writes the records of that project is not.

**A curator may move the files of a contributor, and never edit them.** `tree.movedPaths`
reads `--name-status --find-renames=100%`, and `checkScope` exempts exactly those paths on a
curator branch. So only an exact rename qualifies, and an edit disguised as a move is still
caught. To rename a domain is a registry change, and the registry is the curator's. To move
files is the consequence, and never authorship.

Cost: a curator may reorder the files of a contributor without asking. Content cannot change
and the move is visible in review, so the cost is disorder rather than damage.

- Verified by `suites/tscope.nim`: a moved path is exempt on the curator root alone, and a move
  never widens a project branch. `suites/ttree.nim` holds on a throwaway repository that only
  an exact rename is a move.

**Domain folders are ASCII slugs, and the accent lives in the display name.** The folder is
`sincopa` and the name is `síncopa`, the split that `comma_games` and `comma, games` use too.
Git quotes a non-ASCII path by default, so `git ls-files` piped into any shell tool fails on
it. An ASCII folder needs no `core.quotepath off` instruction for any delegate. macOS stores
such a name as NFD, so the same folder has different bytes there. A `static` assertion in
`domains.nim` holds every folder to `isProjectName`, and fails the build rather than the suite
(Article IV.4).

Cost: a path written with the accented folder name does not parse, so an old link to one
breaks.

**A branch must carry the rules and the checker of its base before it may merge.** `base`
reads what the base gained since the branch forked. It reports a branch that predates a charter
document or the checker. Without it, a branch green against the `main` it forked from can merge
into a later `main`. Its stamp can then be one that a later rules change falsified.

Only two kinds of path count. A charter document moves the stamp that every project claims,
and the checker decides what the audit accepts. Everything else may differ freely. `base`
feeds the `audit` gate that branch protection requires, so no setting changes.

On the runner the job checks out the branch head, and never the merge ref that a pull request
offers. The first parent of that ref is the tip of the base. So what it gained over the base is
empty by construction, and the check would report nothing on every fresh run. `static` on the
same merge ref is what holds a stale stamp there.

- Rejected: the GitHub setting "require branches to be up to date". It is blanket, and makes
  every open pull request stale on each merge. At this merge rate that costs more than it
  saves: 48 pull requests merged in the week to 2026-09-23, and 16 in its last day.
- Cost: a merge of a rules change reddens every open pull request until each one merges the
  base. The blanket setting costs the same, and this fires only where the staleness is real.
- Cost, the honest limit: this reads at pull request time, and never at merge time. So a
  branch green at ten can merge at five past, after another one lands. Only a merge queue
  closes that.
- Verified by `suites/tbase.nim`. Verified by hand with `nim r koch base`, recorded 2026-09-14. A
  branch a week behind `main` reports the finding at its head, which names `CONTRIBUTOR.md`,
  check sources and `koch.nim`. At a synthetic merge of that head into `main`, with `main` as
  the first parent, it reports nothing.

## Commits

**`type(scope)!?: summary`, with the commit types as data. On a project branch the scope must equal
the project.** The curator root accepts any valid scope, because a rules change propagates under the
scope of each project. A branch outside the grammar still gets format checking. Cost: the imperative
mood is unverified. Verified by `suites/tcommits.nim`: every type with several scopes, the breaking
marker, rejected forms, and scope enforcement on both project branch forms.

**The regression rule is enforced, and not hoped for.** `commits` reads the subjects newest
first. It demands that the commit immediately before every `fix` is a `test` of the same
scope, one test to one fix, with nothing between them. So the priority of the Architect,
"every mistake becomes a test", holds by a check and not by prose alone.

- Rejected: any earlier `test` of the scope on the branch. One token test then satisfies every
  later fix, so it measures the order of kinds and nothing of the pairing.
- Rejected: a match across the history of `main`, which needs the whole log. It would still
  pass a fix whose test landed years earlier under a different intent.
- Cost: a fix whose test already sits on `main` needs a test here, or another type. The escape
  is honest, because a change that needs no new test is not a `fix`.
- Cost: a `revert` or a `docs` between the pair breaks it, and so does a second fix on one
  test. Three tests and then one fix pass, because only the commit before is read.
- Verified by `suites/tcommits.nim`. The pair passes, and tests before the test pass. One finding
  comes from a fix alone, from a test after its fix, and from the test of another scope. One
  comes from a second fix on one test, and from a commit or a revert between them.

## Role

**The opening line of a pull request and its labels are the role that its branch names.** The
runner holds it to that before the merge. The role line says who speaks, and the label says
whose work it is. On a pull request both are the role of the branch itself. So `parseBranch`
derives one string through `roleName`, and the check is equality rather than presence.

**The body comes from the event payload, and the labels come from the API.** The job passes
the body as `ROLE_BODY`, and the label names as `ROLE_LABELS`, a JSON array. `gh pr view` with
`--json labels` reads the labels that stand at the moment the check runs. The read is its own
shell assignment. Under `set -e`, a failed substitution that only sets a variable for one
command goes unseen. Koch would then read the empty list as a missing label.

- Rejected: the label list of the event payload. GitHub sends `opened` before `labeled`, so
  that list is empty on `opened`.
- Cost: the `pull-requests: read` scope, and one API call for each run. The read is shell
  inside `role.yml`, so no suite drives it.

**`role.yml` is its own workflow, apart from `check.yml`.** It must fire on a label event, and
in `check.yml` that event would run every job again. Its `concurrency` group carries the action
of the event. So `opened`, `labeled` and `ready_for_review` do not cancel each other, while a
stale run of one action still cancels. A cancelled run is not a success, and where it lands
last, the required check stays blocked with nothing to fire it again.

`ready_for_review` is a trigger, because a delegate fixes the line in a draft, and a pull
request marked ready must be asked again. An unfilled template opens `**Role:** <!-- … -->`.
So the line is read with any trailing comment dropped, and it then fails equality rather than
passes as a line that names nothing. The echoed line is cut at `ECHO_MAX` runes, because a body
may open with a whole paragraph, and the finding is read in a log.

- Rejected: the daily read of the ledger alone. It samples open items once a day and reports
  after the merge. Of 123 pull requests merged in the week to 2026-09-14, 14 were open at any
  of its runs, because half live under half an hour.
- Rejected: `opened` dropped from the trigger. The check then says nothing to a delegate who
  opened a pull request wrongly, which is the reason it exists.
- An empty label list can still be the state a pull request opens in. No API call creates a
  pull request and its label together, so a label can land after the run reads the list. The
  `labeled` event then starts a run that clears it.
- So the two states carry two messages. The empty one names the event that clears it, and the
  one that names a wrong label does not. The finding stays red either way. A green run on an
  empty list would let a pull request opened and merged in one go carry no label.
- Cost: an issue carries no branch, so which label it needs stays a judgement, and stays the
  ledger's. A comment is unreachable, and that is what remains of the first carried rule.
- Cost: the labels are searched for the expected string rather than compared whole. A label
  joins when work hands across, and labels are never removed.
- Cost: `ci` cannot run this verb, because it has no pull request to read. It is the one check
  that a delegate meets on the runner rather than before a push.
- Verified by `suites/trole.nim` on the line reader, the cut, and each arm of the grammar.
- Verified by hand with `nim r koch role`, recorded 2026-09-14. Pull requests replayed as they
  stood before they were mended, with neither line nor label, report both findings each. Pull
  requests of each role, as they stand, report none.

## Assets

**One declaration of every file fetched at build time, in `assets.nim`.** CONTRIBUTOR.md names
the class: *"binaries are never committed, and neither are fonts, images or any file the audit
cannot read"*. Each one is recorded with origin, version, licence and checksum. The store is
that class kept once, rather than once for each project.

Faces are the only rows, and the rows say so by grouping rather than by column. The shape is
file, address and digest, which is what any such file needs and no more. **An asset that wants
a field this row lacks is a change, and not something this shape answers.** Such a field is
unpacking, or a variant set. The header says so, rather than implies that it is settled for all
time.

The name is general, and names no class of file. So a second class needs no rename across
projects that a curator may not edit.

The store exists because Article X.8 gives the same families to every presentation target, so
a second target repeats the pins of the first. Two pins of one file, each in its own
`tools/build.nim`, are a copy that no real constraint forces (Article II.9). Nothing tells such
a copy from two different faces.

- **The digest is the curator's, and the choice is the project's.** The store says what bytes
  `noto-sans-latin-400` is. It never says which faces a target wants, and the targets differ:
  one draws maths and symbols, and the other italic serif. What stops being written twice is
  only what is identical, so the autonomy that CONTRIBUTOR.md argues for is untouched.
- The store is the **only shared build input** of the repository. Compilers are pinned for each
  project in nimble files, Atlas checkouts for each project, and npm for each project, all
  deliberately. The bytes of a face are not a toolchain. They are the same file for whoever
  fetches them.
- **Keyed by digest, and never by name.** Two projects that ask for one face share one entry
  by construction, and a moved pin is a different entry rather than a stale one. `check.yml`
  gets the same property from a cache keyed on the file that holds the digests, one layer
  down. The store sits at `~/.cache/koch/assets`, beside `~/.cache/koch/nim` and outside the
  checkout, because the audit reads untracked files.
- The rows hold `woff2` faces for pages, and TrueType or OpenType faces for the desktop atlas,
  which `@fontsource` does not ship. Where two projects pin one file, they pin one digest.
- One digest reader serves both fetches. `fetchAsset` reads the bytes that it fetched through
  `compilers.digestOf`, so the parse that `tcompilers.nim` tests also guards the store.
- Verified by `suites/tassets.nim`. Verified by hand with `nim r koch assets`, recorded 2026-09-10,
  machine unrecorded. A cold store fills with three faces in **1.0 s**, two of them shared by
  two projects. The same call warm takes **0.117 s**, and fetches nothing.
- Verified by a break of it, on the same date. A face that nobody declares is a finding, which
  names the table to add a row to. Alter one declared digest in its last character, and the
  fetch refuses the bytes and **leaves the store empty** rather than keeps them.
- Cost: the store grows and nothing prunes it. A face is about 30 kB where a compiler is about
  300 MB. So what is unbounded is the number of pins the repository has ever held, and not the
  bytes.
- Cost: an upstream that moves bytes under one address fails every project at once, rather
  than one. That is the same failure that a digest exists to make loud, and it is louder
  shared.
- **The Nim tarball is deliberately not here.** It is fetched and checksummed too, but its
  digest comes from the sidecar of upstream at fetch time, rather than from this table. It is
  stored *unpacked by pin*, because the rest of koch resolves toolchains by pin. The trust
  model and the key both differ, so `compilers.nim` keeps it, rather than this table pretends
  that one shape serves both.
- **The declaration is published, so no consumer parses this source.** `koch assets` that
  names no file writes every row as `<file> <digest>`, one to a line. Rejected: a consumer that
  reads `assets.nim` as text, which is a second parser for a format that only this module owns.
- Two columns rather than three: the address is the business of the fetcher, and the digest is
  what a consumer checks bytes against. Neither column can hold a space, so `split` reads a
  row. **A row never reads as a path, and the suite holds it so.** The verb prints paths where
  files are named, and rows where none are. Both contributor builds tell those apart by shape
  alone: one keeps the lines that `fileExists`, and the other the lines that start with `/`.
- A row that looked like an absolute path would be copied as a face by one build, and counted
  as served by the other. Neither project can check that. The store owns the shape of the row,
  so the store holds the law.

**A `/common/` tree is deferred.** The bar for admitting anything to one: the curator and at
least two contributor projects use it, and each of them is named. A later refactor can then
tell a common project nobody needs from one everybody does.

The store is the only thing in the repository that clears that bar. Compilers, Atlas checkouts
and npm are pinned for each project deliberately, and a tree with one inhabitant is a rename
with a migration attached. So the published contract above serves, and the tree waits for a
second case.

**If it is ever built, the curator writes it and contributors only read it.** A shared tree
that a contributor may write is a scope boundary the branch grammar cannot check.

## Ledger

**The ledger reads what GitHub records about rules that no check reaches.** `ledger.yml` runs
daily and writes one issue labelled `curator`. It names these:

- a pull request left ready without a green run;
- a `Closes #N` that never fired;
- an issue or pull request that opens with no role line, or carries no label;
- an issue whose title takes the form of a commit subject.

Its shape is the shape of `watch.yml`: one issue found again by a marker, `gh issue list`
rather than search, and the label as a hardcoded literal. Its schedule idiom is the one in
`check.yml`. It runs daily rather than weekly, because a pull request ready and red for a week
is the failure it exists to catch.

- **Each carried rule that the ledger reads stays on the carried list, narrowed to its other
  half.** Each one has a half that GitHub does not record. The ledger reads bodies but no
  comment, and cannot tell a copied label from a composed one spelled right.
- It catches a `Closes #N` that misfired, but not an issue that a ruling in a comment left
  open, with no pull request to find. It catches a pull request ready without a green run, but
  not one green now and about to move.
- **The unbolded form passes deliberately.** Issue bodies open `**Role:**`, but a comment is
  written loose, and the Architect writes `Role: architect`. A check that demanded bold would
  name whoever wrote the rule.
- **The role line may follow HTML comments.** An issue that `watch.yml` or the ledger opens
  carries its marker first, and a marker renders as nothing. Rejected: the pattern that read
  from the first character, which named each such issue as having no role line. The same
  pattern still names an unfilled template, whose role line opens `**Role:** <!--`.
- The `permissions` block of `ledger.yml` names `actions: read`, `issues: write` and
  `pull-requests: read`, and nothing else. `workflows.nim` marks `gh pr` as a use of
  `pull-requests`, so a block that leaves that scope out is a finding.
- **`watch.yml` watches the ledger as it watches `check`.** A scheduled workflow runs only from
  the default branch, so no run of the ledger is attended. A ledger that stops in silence,
  while the documents say that a runner holds half of those rules, is worse than no ledger.
- The marker of `watch.yml` carries the name of the workflow, `watch:red:<name>`. One shared
  marker would let somebody who closes a red `check` dismiss a broken ledger in silence.
- Verified by hand through a stub for `gh`, recorded 2026-09-12. `gh` is not installed here,
  and a scheduled workflow runs only from the default branch. A draft, a green head and a head
  whose run is still `in_progress` are skipped, and a red head is named.
- The list asks for 200 merged pull requests, newest first, because the window of 14 days
  must fit inside it. Fourteen days held under a hundred merges, counted by
  `git log --first-parent --merges` on 2026-09-24. Rejected: a limit of 60, which the same
  count showed to end inside the window.
- A merged pull request that names an issue still open is named with its base. One outside the
  window is not. A body that opens `**Role:**` and one that opens
  `Role:` unbolded both pass, while a null body and a missing label are named. A red `ledger`
  beside an open `check` issue opens its own issue.
- Cost: about 30 runner-minutes a month. Public repositories draw on no allowance, so this is
  free while the repository is public. A private one pays: 1,909 of 2,000 free minutes were
  measured used while this repository was private.

**The ledger names an issue titled as a commit.** A title is a fact that GitHub records, so the
convention is a check, and never a carried rule. The convention sits in each issue template,
beside the section that each title comes from.

- **Issues alone, and not pull requests.** A pull request title takes the commit form by rule,
  because the merge commit takes the title as its subject. An issue is no change, and its label
  and its template already say whose it is and what kind.
- **The shape is read, and not the list of commit types.** `^[a-z]+(\([^)]*\))?!?: ` names
  `bug:` and `koch:` as well as `feat(audit):`. Each one takes the commit form, and the
  convention asks for none.
- **Case is kept.** A title in sentence case that holds a colon passes, such as
  `Rework the camera: free flight with no selection`. Cost: `Feat(audit): …` passes too, and
  holds by reading, as the positive half of the convention does.
- The role-line pattern, verified by hand through real `jq` 1.7 on 2026-09-24. The program was
  read from the workflow file, and it was run over fixture bodies. A marker before the role
  line passes, and an unfilled template, a missing role line and a null body are named.
- Verified by hand through a stub for `gh` that serves fixture JSON through real `jq` 1.7,
  2026-09-24. The step runs as the workflow holds it. Over the fixture titles, each expected
  title is named and no other, among them `fix:`, `feat(audit)!:`, `bug:` and `koch:`. Over
  the real titles of that day, the step names nothing.
- Cost: the pattern is `jq` inside shell, as the role-line pattern is, so no suite drives it.

## Toolchain

**Each project pins its own compiler, and there is no Nim for the whole repository.**
`requires "nim == <version>"` sits in the nimble file of the project. It is read through the
same `requireLiterals` scan that `dependencies.nim` uses, so requirements are parsed in one
place. No single version serves every project, because `rga_visualiser` and `pga_benchmark`
pin a compiler commit that no release carries.

- Rejected: one pin for the repository, which cannot hold a commit pin and a release pin at
  once. Rejected: `>=`, which cannot express an upper bound, and cannot say which compiler a
  suite passed on. Rejected: a `.nim-version` file, a second place a version lives, beside the
  nimble file that already names one.
- Verified that Atlas accepts an exact compiler pin rather than resolves it as a package.
  `atlas --noexec rep` cloned and set the pinned commit, and `atlas changed` exited 0 (Atlas
  0.9.0, 2026-09-06).

**A pin may name a commit as well as a version**, as forty lowercase hex characters, which is
how `atlas.lock` records commits. A project needs one where its dependency spells operators,
on its head, in a form that no release can lex. Only a lexer change on `devel` serves it.
`isCommit` is tested before `isVersion`, because forty digits satisfy both, and the absurd
version loses.

- Rejected: a bare `devel` label, a moving target that records nothing. Rejected: a dated
  nightly, retained only for a window, so an old pin stops installing and the pin stops
  being reproducible.
- Cost: no action installs a compiler by commit, so it is built from source and cached by
  commit.
- Cost: `curator/audit` may not pin a commit, because every other job waits on the one that the
  setup action installs. `checkDriver` reports it.

**The compiler of koch is derived, and never a second pin.** `NIM_VERSION` in `check.yml`
builds koch and runs the whole-tree pass. `checkDriver` fails the audit unless it equals the
pin of `curator/audit`, because koch compiles the modules of that project. It is the same
derived-view rule that `layout.nim` applies to the domain table.

Every workflow that installs a compiler is held to it, and not `check.yml` alone, because a
second copy drifts. `check.yml` must state it, and a commit pin is one finding, however many
workflows state a version. Verified by `suites/ttoolchain.nim` over both paths.

**A pin moves on evidence, and the evidence is a run rather than a release note.** Nim assigns
no CVE, so no release in the 2.2 series carries one. So the reason to move is what the release
notes carry. Between 2.2.6 and 2.2.12 they fix a SIGSEGV under ARC, ORC and refc, and a use
after free. They also fix an overlapping `copyMem`, and overflow checks that could be escaped.
The curator projects pin 2.2.12 for that reason.

- Verified by `nim r koch tests` over `curator/audit` and `curator/probe` on 2.2.12,
  2026-09-09: every suite passes.
- Trap from 2.2.8 on: a `func` whose implicit `float` result is read by `+=` before it is ever
  assigned gets an int register for it. To write `result = 0.0` first avoids it. The
  `PROVENANCE.md` of `dance_ontology` holds the diagnosis.
- Cost: the modules of koch compile under every pin in the tree, because the job of every
  project installs its own. The matrix proves that, and not this paragraph.

**Koch resolves each pin to its own compiler, and fetches one it lacks.** It takes `PATH`
where that already serves, then `~/.cache/koch/nim/<pin>/bin`, then a fetch. A release comes
as a tarball. A commit comes from a clone of `nim-lang/Nim` and a run of `sh build_all.sh`,
which is the recipe that `check.yml` uses. So does any platform that nim-lang.org publishes no
build for. The cache sits outside the checkout, because the audit reads untracked files, and
`$KOCH_NIM_DIR` moves it.

So `nim r koch ci` stays green as one command over a changed set that spans pins. These traps
hold here.

- **A half-built toolchain lies.** A probe of `bin/nim` before `koch boot` finishes returns the
  csources bootstrap binary, which answers `--version` with an unrelated commit. So a source
  build completes beside its destination, and moves in only when it is done, as a tarball
  does.
- **To name a tool by path is not enough.** Atlas resolves `nim` through `PATH`, so an Atlas
  named by path alone reads whichever compiler `PATH` holds, and warns `environment mismatch`.
  Children run with the `bin` of the toolchain leading `PATH`. A tool absent from a toolchain
  falls back to `PATH` rather than raises, because what `koch tools` produces moves between
  Nim versions.
- Rejected: a directory that a delegate populates by hand, which leaves the defect for anyone
  who has not. Rejected: the layout of `choosenim`, a second convention that cannot serve a
  commit pin at all.
- Costs: the checker reaches the network, and may build a compiler. That is seconds for a
  release and minutes for a commit, once for each pin. Each cached toolchain is a few hundred
  megabytes, and nothing prunes them.
- On CI, the installed compiler of every job already satisfies its pin, so resolution stops at
  `PATH` and never fetches.

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
- Verified by a break of it, and not by a fetch that happened to pass. `tcompilers.nim` digests
  a temporary file, changes one byte, and checks that the digest moves. The parse is
  mutation-tested: drop its hex validation and the suite reddens.
- Verified by hand, 2026-09-10: `2.2.2`, which nothing on the machine served, fetched,
  digest-checked and unpacked.
- Honest limit of that test: the exit-code check of `sha256sum` is belt-and-braces, because
  the parse already rejects the error text, so no test distinguishes it. It is kept for saying
  what it means.
- Verified by `suites/ttoolchain.nim`, `tcompilers.nim` and `tprojects.nim`. Verified by hand,
  2026-09-06: `curator/probe`, pinned to a release that nothing local served, fetched the
  tarball and ran. One command over projects on two pins gave **0 findings**, and its log held
  no Atlas mismatch warning.
- A pin that nothing can serve is one finding, which names the pin and the cache it tried, and
  not a crash. Cost, unmeasured on the current pin: the time of a cold fetch.

## Dependencies

**Atlas for each project: requirements in `<project>.nimble`, checkouts in an ignored `deps/`,
exact commits in a committed `atlas.lock`, and paths in a committed `nim.cfg`.** `koch deps`
runs `atlas --noexec rep` in every project that holds a lock. It judges success by
`atlas changed` exiting zero.

- Rejected: one Atlas project at the root. Atlas 0.9.0 has no shared-workspace model, and a
  root `nim.cfg` would leak every dependency into every project through parent-config lookup.
  The constitution also wants each dependency justified where it is imported (II.8).
- Costs, verified by hand with Atlas 0.9.0, 2026-09-05. Atlas clones `nim-lang/packages` before
  any command, so it needs the network even for zero packages, which is why a lock-less
  project skips it. `atlas rep` exits 1 after a restore, because its submodule step fails, and
  that is why `atlas changed` gives the verdict. A dependency used by two projects is cloned
  twice.
- Verified by `suites/tdependencies.nim` for the parser and the lock-less skip. The Atlas command
  flow was verified by hand on a throwaway project, 2026-09-05. Assumed, and not verified here:
  the same flow on the runner.

**`atlas changed` alone does not prove that a restore happened.** It exits 0 while it warns
`repo missing!`, so a restore that fetches nothing reports success. `checkCheckouts` reads
the `dir` of every lock item, resolves `$deps`, and demands that the directory exists before
`atlas changed` is consulted. Measured on Atlas 0.9.0 by a delete of `deps/` and a re-run.
Cost: the lock is parsed twice for each restore. Verified by `suites/tdependencies.nim` over a
project with and without the directory, and over a lock that is not JSON.

**The lock silently reverts an edit to the nimble file.** `atlas.lock` stores a whole copy of
the nimble file under `nimbleFile.content`, and `atlas rep` writes it back over the file. So a
requirement edited without a regenerated lock is undone on the next `koch tests` or `koch ci`.
Nothing fails at that moment, so the loss surfaces later, as a `koch tree` finding on a
reverted line that the contributor never wrote. `checkLockNimble` compares the stored copy
against the committed file, and reports the first differing line.

- The comparison runs in the static pass, over the tree as git holds it. Run after
  `restoreAll`, it would compare the file against the copy it had just been written from, pass
  always, and cover nothing. That is the same trap as `atlas changed`.
- The finding points at the nimble file rather than at the lock, because that is the file the
  restore overwrites, and its line numbers resolve.
- Costs: a project that changes a requirement must regenerate the lock, or make the stored
  copy match. `atlas pin` writes `"items": {}` for a dependency whose repository carries no
  nimble file, so a hand-patch stays necessary until Atlas changes. A lock that stores no copy
  is compared against nothing.
- `auditTree` is a `proc`, because it composes a check that reads JSON, which Nim marks
  effectful. Every rule it composes stays pure, and `layout.nim` still reads paths only.
- Verified by `suites/tdependencies.nim`. Verified by hand against the real lock, recorded
  2026-09-06: a stored copy that holds `nim >= 2.2.6` names `rga_visualiser.nimble:13`, and
  the restored lock is silent.

## Scoped checks

**The static pass stays whole-tree, and only compilation is scoped.** A project enters the test
set when a changed path under it is anything but its records (`PROJECT_FILES`). A change to
`koch.nim`, `koch.nim.cfg` or `curator/audit/src/` selects `curator/audit` alone. Its suites
read koch, and the check sources are its code. Nothing selects every project.

The push run on `main` plans against the base of that push, and the weekly run against its
window. So every run compiles what changed and nothing else (CURATOR.md duty 11). The suite of
a contributor is the contributor's to run. A path inside no project selects nothing by itself.
So rules propagation compiles nothing, while every stamp is still checked.

- Rejected: a scope on the static pass. The static pass costs about a second, against seconds to
  minutes for the suites of one project (Figures). A scope buys nothing measurable there, and costs
  a second code path and the whole-tree layout and stamp guarantees.
- Cost: a change to the checker can leave an unchanged project red until it next changes, and
  nothing compiles it sooner. To run that suite is the work of that project, which is the
  point of the rule.
- Cost: `isChecker` reads the path, and never the content. So a comment edit in `koch.nim`
  compiles `curator/audit`: one project, seconds. `comments.nim` already extracts comments for
  each kind, so `plan` could ask whether anything but comments changed.
- Rejected: that comment detector, because it errs toward compiling too little. A wrong
  "comments only" reports green for work it never did, which is the failure this repository
  refuses everywhere else.
- Verified by `suites/tplan.nim`: a README-only change plans `[]`, and a one-line source change
  plans that project alone. A change to `koch.nim` plans `curator/audit` alone. `--sweep` plans
  every project in a repository younger than its window, and nothing over a window without a
  commit.

**The weekly run fires, and it promises a day rather than an hour.** Verified on the runner,
2026-09-07: every project planned, each on its own pin, and its jobs started within one second.
The phase finished in about four minutes, against about nine summed. It fired **6 h 09 m after
its 06:00 slot**, which is what GitHub does with `schedule` under load. So a curator who reads
the cron and returns at 06:05 finds nothing. To wait is part of a read of this signal.

**The weekly run plans what merged inside `SWEEP_DAYS`**, and nothing in a quiet week. It
judges "code" by the record-file exclusion that scoped runs use. Rot arrives with merges, and
to compile a project that nothing touched is runner time for no information.

- Rejected, by the rule of the Architect that every run covers what changed: a weekly run of
  every project whenever anything merged. Cross-project rot from a checker change surfaces when
  that project next changes.
- Cost: rot from outside the repository goes unseen through a quiet week, such as a runner
  image that moves under a pinned compiler.
- Cost: the window is named twice, as the cron and as `SWEEP_DAYS`. Nothing checks that they
  agree, so CURATOR.md duty 9 says to change them together.
- A repository younger than the window has every commit inside it. So the skip is verified by
  suite rather than by a live Monday. `tplan.nim` drives `sweepFor` on a throwaway repository,
  and drives the decision of `jobs` over code, record-only and empty changes. `ttree.nim` drives
  `revBefore` at both ends.

## Project runner

**`testament --nim:<absolute> pattern "tests/t*.nim"` in each project directory, serially,
with the output streamed.** Koch holds the verb once, and no build file for each project
exists. The compiler path is absolute, because testament resolves `--nim` against its working
directory. A failure is a finding at the `tests` directory of the project, and it echoes the
exit code.

Each project carries a `Target`: its directory, and the `bin` of the toolchain that serves its
pin. Tools come from that `bin` rather than from `PATH`, because two projects on two pins
would otherwise share one compiler in silence. Verified by `suites/tprojects.nim` with a
passing and a failing fixture, driven through real testament.

- Cost: projects and their stubs run one at a time. A project in another language needs its
  own runner arm.
- Rejected: one testament for each stub, four at a time. It took `dance_ontology` without
  `trigid` from 52 s to 17 s, measured 2026-09-24 on the Figures machine. But concurrent runs
  share `testresults/` and interleave their output, and the slowest stub bounds each project.

## System packages

**System packages are installed from the declaration of each project, and never from names in
a workflow.** `koch system` runs the `system` verb of each selected project, and prints the
union, sorted and deduplicated. The job pipes it into `apt-get`. Koch prints and never
installs, because which package manager serves a name is the business of the machine, while
the list is the project's.

Only bare names survive the read. The contract is one name to a line. The one other thing
that reaches that stream is the compiler complaining, which always spells a position first. So
a line that carries whitespace is dropped. A compiler that complained still fails, because the
absent package names itself.

**Koch declares its own system packages, as the rule it enforces asks of every project.**
`KOCH_SYSTEM` in `projects.nim` pairs each one with its reason. It holds git and curl, `tar`
for the tarball that `fetchRelease` unpacks, and `coreutils` for `sha256sum`. `koch system`
with no project prints those and every project's, unscoped, so one command answers what a
machine needs before any of this runs. To name a project keeps the meaning for each job that
the runner asks for.

Nim is deliberately absent. It is the toolchain that koch runs under, rather than a package
that a machine installs, and `compilers.nim` resolves each pin itself. npm is absent because it
belongs to the project that carries a node manifest, and `restoreNode` reports its absence by
name. The root `README.md` points at the verb rather than names packages, so the declaration
is the only statement and nothing can drift from it.

- Rejected: an exemption stated in `CONTRIBUTOR.md`, which leaves the rule true and the
  repository still answering its own question in prose.
- Cost: the packages of koch itself are unconditional, so a machine that needs none of them
  still installs them.
- Verified by `suites/tplan.nim`: koch declares what it needs, as the rule asks of every project.

## Tests

**Testament over `tests/t*.nim`, with each stub carrying the header from STYLE.md §6, and
without `-r`.** `-r` would run every test twice, and `--outdir` breaks the search of testament
for the binary. So binaries sit beside sources, and git ignores them everywhere
(`**/tests/t*`).

Suites are named after an article of the constitution where one fits, else after the module.
The suite or test name cites the clause that it replicates. A trailing comment labels the case
that one assertion separates. `suites/fixtures.nim` builds the fixtures: a smallest clean tree
with a project under each root, and throwaway git repositories. It also reads the table in the
header of a module.

**The suites of this project compile as one program.** Each suite is a module under
`tests/suites/`, and `tests/tsuites.nim` is the one stub. It imports every suite, so the
compiler reads the standard library and `std/unittest` once, and not once for each suite. The
import list is read from the directory at compile time, so a suite that is added also runs.
The stub leaves out `-d:nimUnittestAbortOnError:on`, so every failure shows in one run.

- Rejected: one stub for each suite. Almost all of their time was compile time, because each
  suite compiled the same standard library again. The run of all binaries took 2.1 s (Figures).
- Rejected: one testament for each suite, four at a time. It took twice as long as the joined
  program on four cores, and its output interleaves.
- Rejected: the `joinable` megatest of testament. `pattern` never reads that key, and
  `testament all` reports "output different" for passing `std/unittest` suites.
- Rejected: `-d:nimBetterRun`, which skips a compile whose inputs did not change. The import
  list read from the directory is not such an input, so a new suite would not run.
- Cost: a compile error in one suite, or an exception outside a `test`, stops every suite.
- Verified by hand, 2026-09-24: two failures put in two suites both show, with file and line,
  and the other suites still run. The exit is 1.

`git ls-files '*/tests/t*.nim' '*/tests/suites/t*.nim'` counts the suites. No count is written
here, because a written count goes stale. The suites of `dance_ontology` dominate every
whole-tree run. Verified by hand, 2026-09-08: `nim r koch tests` over every project passes with
0 findings. Each project ran on the compiler that it pins, with one pin alone on `PATH`.

**Trap: `koch ci` selects suites from committed paths.** `changedPaths` reads
`git diff <base>...HEAD`, so a change that is not committed selects no project. `koch ci` then
passes on a tree that a fresh checkout fails. Commit before `koch ci`, or run
`nim r koch tests <project>`, which runs that project whatever changed. Testament itself
rebuilds a suite whose source module changed, with a warm `nimcache`. Verified by hand,
2026-09-24: a change to `src/findings.nim` alone is compiled into the next run.

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
  projects that one change asks for, by the `testSet` rule. `--sweep` scopes it to the window
  of the weekly run.
- **Absent npm is a finding that names it, and never a skip.** A check that quietly does
  nothing reports green for work it never did.
- Verified by hand against the regression it exists for, 2026-09-07. A rename of
  `nimSceneHandles` to `nimSceneSlots`, with nothing else touched, reports one finding over
  `TS2304` at four sites in `construct_section.ts`. Reverted, it reports 0 findings.
- Cost, unmeasured on the current pin: the whole verb, with `npm ci` included.

## Driven checks

**The runner drives what the suites cannot reach, through the verb of that project.**
`koch driven` restores the checkouts and node tools of a project, then runs
`tools/build.nim drive`. The verb builds the page and drives it through held keys, wheels,
right-button pans, two-finger pinches and long presses. Testament tests rules, such as what a
slide does to the pivot, and nothing in it presses a key. So a rule wired to the wrong event is
a defect that no suite here can see. A driven check that the runner never runs is evidence only
that its writer ran it (Article IX.6).

**Enrolment is the verb, read from the driver of the project itself.** `verbDirs` reads the
dispatch of `tools/build.nim` and selects the projects that name `drive`, the derivation that
`nodeDirs` uses one step earlier. `dispatchVerbs` reads the dispatch of koch and of a project
driver alike, with the opening line as an argument. Koch cases over parsed options, and a
project driver over its first argument. Cost: a project that spells the verb otherwise is
passed by in silence, which is why CONTRIBUTOR.md names `drive` and `system` outright.

**It is a matrix, each project on its own pin, where `types` is one plain job.** `drive` calls
`web`, which runs `nim js` over `bridge.nim`, and that compiles project code and everything it
imports. So `rga_visualiser` on the compiler of koch fails inside `multivectors.nim` of `pga`,
whose syntax only the pinned commit can lex. The type check rests on a verb that compiles no
project code, and `drive` breaks that condition. So `driven` is planned like `tests`, and
`plan --driven` filters what `plan` already selected. It inherits the scoping, `--all` and
`--sweep` from there.

- Rejected: one plain job on the compiler of koch, as `types` runs.

**The shared store is cached, and `build/fonts` is not.** `koch assets` fetches into
`~/.cache/koch/assets`, and that store is the repository's. So the cache keys on its
declaration, `curator/audit/src/assets.nim`, and one entry serves the job of every project. On
the runner the fetch is 6.6 s cold, and the copy into `build/fonts` is milliseconds, recorded
2026-09-11.

- Rejected: a cache of `build/fonts` keyed on the driver of a project, which keeps the cheap
  half and misses the expensive one.
- A looser `restore-keys` entry is safe here by construction rather than by check. The store
  names entries by digest, so an entry that no row declares is unreachable rather than wrong.
  `koch assets` fetches whatever an older restore lacks.
- Verified on the runner, 2026-09-12: with no cache of `build/fonts`, the second `assets` pass
  of a job copies nothing. The first pass puts every face in place, so that cache saves
  nothing.

**The browser that a declaration names is the browser that runs, and the snap serves.**
`apt-get install chromium` on `ubuntu-latest` gives `/snap/bin/chromium`, a wrapper rather than
a plain binary, and Playwright launches it. Where a package does not serve the runner, the
declaration of the project changes. A name is never substituted here in silence.

Verified on the runner, 2026-09-07, which is the only place the claim means anything. Every
driven check passed with 0 findings, in a real Chromium over real gestures, with `audit`
reading its verdict. Verified by a break of it: on the compiler of koch the same command fails
inside `pga`.

## Watching main

**A red `main` opens its own issue, because a duty to remember to look fails in silence.**
`watch.yml` reads each finished run of `check` and `ledger` on `main`. It opens an issue
labelled `curator` when the run concludes failure. That issue lands in the queue that CURATOR.md
asks every delegate to read first, so no new rule exists. An existing rule produces an issue
that the rule already asks the next delegate to read.

It is a separate workflow, because a run cannot watch its own outcome. `workflow_run` fires
only from the copy on the default branch, so it cannot be driven from a branch at all. That is
why it also takes `workflow_dispatch`, which names the run to read.

There is one issue for each workflow rather than one for each red run. A watcher that opened an
issue for each run trains its reader to skim, which is the failure it exists to prevent. The
marker in the body is what makes a later red comment on the first. Open issues are read
directly rather than searched, because a cold search index would produce exactly the duplicate
being avoided.

**Only a red run of `main` itself is reported, and two of them never race.**

- `branches: [main]` matches the head branch of the run. A pull request from the `main` of a
  fork carries that name as well. So the job also asks that the run did not come from
  `pull_request`. Rejected: the branch filter alone, which lets a red fork run open a false
  issue with `issues: write`.
- The job carries a `concurrency` group named after the workflow that it reads, and it never
  cancels in progress. Two red runs of one workflow that finish together could each list the
  open issues, find none, and open two. The group sits on the job rather than on the workflow,
  so that only red runs queue in it. A group on the workflow would let a green completion
  replace a red one that still waits.
- Cost: a third red run that arrives while a second waits replaces it. The issue then gains
  comments for the first and the third, and none for the second.
- Unverified on the runner: the guard and the group take effect only from the default branch,
  so they are read, and not yet driven.

**A rule leaves the list of what no check can reach when it turns on a fact that something
already writes down.** The conclusion of a run is such a fact, so `watch.yml` holds it. The
agreement of a glossary term is not. CURATOR.md states that test.

**A `permissions` block is the whole grant, and never an addition to the default.** A scope
left out of it is set to `none`, and not left alone. A block without `actions: read` gets
`Resource not accessible by integration (HTTP 403)` on its first read of a run. The job log
then lists `Contents: read, Issues: write, Metadata: read`, and no Actions. That 403 comes from
the block alone, and not from a repository setting.

`workflows.nim` reports a scope that the steps of a workflow demonstrably use and that its own
block omits, over every file under `.github/workflows/`. It is narrow on purpose. It reads what
steps call, rather than what they might. A workflow that declares no block is left alone,
because to take the default of the repository is somebody's decision rather than drift. Cost:
the marks are text, so a step that reaches the same endpoint by another spelling goes unseen.
That is a floor rather than a ceiling, and the module says so.

- Verified by `suites/tworkflows.nim`. Verified by a break of it: delete `actions: read` from
  `watch.yml`, and `koch tree` reports it by name and by what was granted. Restore it, and 0
  findings return.
- Verified on the runner, 2026-09-09, against real red runs rather than a manufactured one.
  Dispatched at a red run of `main`, it opened one issue that named the run and each job that
  concluded failure. Dispatched at a second red run, it commented on that issue rather than
  opened another.
- In the same check, runs on green `check` completions concluded `skipped`, which is the guard
  working on green.

## Continuous integration

**`check.yml` runs a fixed set of jobs, and a gate stands for the ones whose names vary.**
`plan` emits the matrices, and `static` runs `nim r koch tree`. `project` is one matrix job for
each planned project, on its own pin. `driven` is a second matrix over the subset that carries
that verb, and `types` is one plain job on the compiler of koch. `scope`, `commits` and `base`
run only on pull requests, with full history. `audit` is a gate that reads the rest.

The gate exists because matrix job names vary with the change, and can never be required
checks. The required checks are `audit`, `scope`, `commits` and `role` (CURATOR.md, "Repository
settings the Architect applies"). Every job added to `check.yml` is named in the `needs` of the
gate, or it is a required check by name. `scope` and `commits` take the second way. A job that is
neither is a red check that cannot block a merge. That
mistake is easy to make and impossible to see afterwards.

- Rejected: a rename of the required checks, which would make the Architect reconfigure
  `main`. Rejected: a computation of the matrix in shell, which is untested glue where koch is
  tested.
- Branch names and the event kind reach koch through the environment, and are never
  interpolated into the script. Nim installs under the temp directory of the runner, and never
  the workspace, and `.gitignore` lists `.nim_runtime/`.
- Rejected: a toolchain inside the checkout. The audit reads untracked files, so it reads that
  toolchain as source, with a finding on each file that breaks a rule.
- `check.yml` declares `permissions: contents: read`, because checkout is the only use of the
  token and nothing in it writes. The caches take their own runtime token, and no step calls
  `gh`. Cost: a step that later reaches the API needs its scope named, which `workflows.nim`
  reports for the steps that it can read. Verified on the runner, 2026-09-24, for `plan`,
  `static`, `types`, `scope`, `commits`, `base` and `audit`. A change that touched no project
  code skipped `project` and `driven`, so the grant is unverified for those two jobs.
- Verified on the runner, recorded 2026-09-08: a record-only change emits `[]`, `project` is
  skipped, and the gate passes on a skipped dependency. The gate passes on `skipped`, and fails
  on `failure` or `cancelled`.

**`nim r koch tests` with no project runs every project, each on its own compiler.** `ci` stays
scoped to what a change touches. Cost: to check everything locally is two commands, `tree` and
`tests`, rather than one.

- Rejected: one verb for the static pass and every suite on the compiler that `PATH` holds. It
  fails whenever the pins differ.

**`nim r koch ci` is the local form of the jobs.** It fetches `origin/main`. It then runs the
whole-tree pass, and the restores and suites of the planned projects. It runs the type check,
the driven checks, scope, commits and base, all in one process. Every pull request passes it
before somebody opens it. The runner confirms, and it never discovers.

- Cost: one network fetch for each run, accepted so that the base is the one CI will use.
- Cost: a branch whose change spans projects on several pins needs each pinned compiler, which
  resolution provides. A driven project also needs npm, a browser and its declared packages,
  which resolution does not provide.
- `ciJobs` resolves the pins once, restores once, runs the suites, and then drives the
  projects that carry driven checks. A failed restore stops the driving alone.
- Rejected: a restore in each of `runJobs` and `drivenJobs`. The second restore is Atlas
  confirming that nothing moved, which is seconds for each project in each run.

Traps of the merge process:

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

**The checker is held to the rules it holds everything else to.** It checks every project, and
nothing else checks it. `checker.nim` makes each of these a rule, so the next case is caught by
the runner rather than by a curator who reads.

- **Dead export**: a routine exported from a check module that no other module and no suite
  names. STYLE.md §5 puts `*` on an intentional export alone, and a routine that only its own
  module calls is not one. A suite counts as a caller, because the pure rules here are covered
  by calls from their suites. Mentions are counted as identifier runs rather than as
  whitespace words, because `tree.auditTree` is a call exactly as `auditTree(tree)` is.
- Each source is counted once, and every export reads those counts. A scan of every source for
  each export took half of the static pass (Figures).
- **Missing suite**: a check module without `tests/suites/t<module>.nim`.
- **Verb drift**: one set named three times. The names are the verbs that koch dispatches, the
  verbs that its usage prints, and the rows of the checks table in CURATOR.md.
- Verbs are read from the command dispatch alone, bounded between `case options.command` and
  its `else`. The option parser cases over labels a few lines above. Without that bound,
  `root`, `all`, `branch` and `sweep` would read as verbs.
- **Option drift**: one set named twice. The names are the options that koch parses, and the
  `--` options that its usage text prints. Options are read from the one-line branches under
  `case key`, and the read stops at the first line that is not a branch. Usage is read from
  its mark to the close of the string, so header prose that names an option is not usage.
  Cost: a branch of the option parser that spans two lines hides the option under it.
- Rejected: a count of whitespace words, which reports a live routine as dead. Rejected: a
  flag on an export that only tests use, which is how every pure rule here is covered, and
  would need an exemption list.
- Rejected: a warning rather than a finding, because a warning that nobody must act on is read
  by nobody. Rejected: one suite for each module in contributor projects, which group tests by
  subject.
- Costs: a routine named in a comment is not dead, so prose that mentions a retired routine
  hides it. That is paid to keep the rule free of false findings. An exported operator is
  skipped, because it is spelled at call sites rather than named. The other columns of the
  table stay prose that no check reads.
- Verified by `suites/tchecker.nim`, and driven. A routine added and never called is one finding
  that names it, and so is one that only its own module calls. One that a suite alone names is
  not a finding. A row deleted from the checks table is one finding that names the missing verb. A
  verb dropped from the usage line is one finding that names what usage prints. An option parsed and
  not printed, or printed and not parsed, is one finding on `koch.nim`.

**No copy of the module graph is written.** The `import` line of each module is the graph, and
a hand-written copy drifts from it. So `audit.nim` names no module order.

## Figures

The machine for these figures is a four-core Intel Xeon 2.10 GHz container, on Nim 2.2.12,
2026-09-24, timed with `date +%s.%N`. Warm means that koch and the test binaries were already
compiled. Each "before" figure is `origin/main` at `8a05673`, on the same machine and date.

**The static pass costs about a second.** `nim r koch tree`, warm: 1.11 s, 1.15 s and 0.98 s
over three consecutive runs. Before, it took 1.97 s, 1.96 s and 1.82 s. Inside koch, the old
dead-export rule took 1.1 s of a 2.07 s pass, because it scanned every source once for each
export.

**A branch that changes the checker costs one project, and not every project.** Warm,
`nim r koch ci` takes 5.07 s, 5.07 s and 4.99 s over three consecutive runs. With the suite
build of `curator/audit` removed first, it took 8.1 s. Before, with one comment added to a check
module, it took 32.9 s and 32.6 s warm, and 49.2 s cold. `koch plan` holds one row on such a
branch, so the figure covers the suites of `curator/audit` and the static pass.

**The suites of `curator/audit` cost their compile, and almost nothing to run.** Each suite
compiled alone in 0.8 s to 1.2 s warm, and the run of all 30 binaries took 2.1 s. Joined,
`nim r koch tests curator/audit` takes 3.8 s to 4.2 s warm, against 31.9 s before.

These two are the pair for scoping. A change to records alone costs the static pass, and a
change to one project adds the suites of that project. An unscoped run pays every project.
On the same machine and date, `nim r koch tests <project>` took 627.5 s for `dance_ontology`
and 236.6 s for `rga_visualiser`. It took 18.2 s cold for `pga_benchmark`, and 2.8 s for
`curator/probe`.

**Matrix jobs run in parallel.** Verified on the runner, 2026-09-06: three `project` jobs
started within one second, and finished at 16 s, 52 s and 121 s. So the phase took 121 s
rather than the 189 s of their sum. The saving is the sum minus the slowest, so it grows as
projects arrive.

Cost from the same run: matrix jobs cannot start until `plan` reports. That puts 16 s between
the start of the run and the first project job. That is a floor on every run, and the price of
a matrix computed in tested Nim rather than in shell.

**What the driven check costs, and where it goes.** Locally, `koch driven` on `rga_visualiser`
takes 2 m 36 s warm, and 3 m 31 s on a tree whose `build/` was removed (2026-09-07). About two
thirds of that is the deliberate wall-clock windows of the harness, which a faster machine does
not shorten. On the runner the job is 5 m 31 s on the same checks, recorded 2026-09-08. The gap
is apt install, a restore of a 2.4 GB compiler from cache, and a slower core.

A figure from one machine predicts the figure of another only where what differs has been
measured.

| Step of the `driven` job | Wall |
|--------------------------|------|
| read the declaration and `apt-get install` | 1 m 47 s |
| `nim r koch driven` | 3 m 04 s |
| restore the commit-pinned compiler from cache | 28 s |

The install is 32% of the job. It is also an upper bound on what a `koch system` asked for
each verb could save. The same step compiles koch and runs the verb of the project. So
`system` stays for each project.

## Runner caches

**The compiler is the cache that matters on the driven job.** The job restores the store of
npm, the Atlas checkouts, the commit-pinned compiler, and the faces. To restore the compiler is
seconds, where a build from source is fifteen minutes. Every other cache is noise beside it:
`npm ci` runs in 2 s cached, and the faces of one project take 1.5 s uncached. Measured on the
runner, recorded 2026-09-07.

- Unmeasured: npm cold on the runner, which needs a key poisoned on purpose. That figure is not
  owed.

**The install directory of SDL3 is cached, and its build tree is not.** No package carries
SDL3, so `sdl3` clones, configures and builds it from source. That is 55.8 s of a 357 s
`driven` job, the largest step that nothing else caches (runner, recorded 2026-09-10).

- The install directory is what makes the verb return early, because `versionSdl3` reads
  `build/sdl3/lib/pkgconfig`. So a cache of the product is enough, and a cache of the cmake
  tree is unnecessary.
- The product is also what makes it safe. A cmake build tree carried over from a configure
  that found no X11 goes on reporting `SDL not configured with OpenGL/GLX support` after the
  headers arrive. Verified by hand on a container, recorded 2026-09-10.
- A product caches. A build tree remembers what it decided about a machine that has since
  changed.
- The key holds the project directory and the hash of the `tools/build.nim` of the project,
  with `restore-keys: sdl3-<os>-<project>-`. That file carries `COMMIT_SDL3` and `SYSTEM`, so
  a moved pin or a changed package list misses the exact key. The partial key then restores
  an older entry, and `versionSdl3` reads the restored `.pc` and returns early.
- Rejected: the exact key alone. The file carries everything else that a project driver
  carries, so it changes often, and the exact key misses on each change. A key has to be
  specific enough to be correct and stable enough to hit.
- Rejected: a key without the project directory. Its restore key then matched the prefix of
  another project. So a driven project that builds no SDL3 restored one, and saved it again
  under its own key. The path is made before the step, so such a project saves an empty entry
  rather than a warning about an absent path. Unverified on the runner until a `driven` job
  runs with this key.
- Verified on the runner, 2026-09-12. The job restored from a key other than the one it saved
  under, and printed `Kept SDL3 3.2.30, already reported by pkg-config`. The SDL3 phase ran in
  about 20 ms, against 55.8 s built, at a restore cost of about 1 s.
- No whole-job pair is quoted. The jobs on either side ran different driven checks, so the
  difference of their totals is not a saving.
- Cost: most runs stop exercising the SDL3 build. Every cache here trades that. The pin is a
  commit rather than a mutable tag, so what the cache hides is a rebuild, and not an upstream
  that moved.

**`nimcache` is not cached on the runner.** A cache of it can skip Nim compilation alone: at
most about 16 s of a 357 s `driven` job. The steps that dominate such a job are the ones it
cannot serve. Measured from one `driven` job on the runner, recorded 2026-09-10. The figures
expire with the job they measured.

- Rejected: a cache of `nimcache`, which costs a key and a step for at most 16 s of 357 s.
- Staleness is not the reason. A restored `nimcache` does not let a check pass without a
  compile of what it claims, because Nim decides by content and not by mtime.
- Verified by hand, recorded 2026-09-10. An ordinary rebuild, a cache six years newer than
  backdated sources, and a full save, mutation and restore each rebuilt correctly.

**Apt archives are not cached.** A cache saves the download and not the install: 2.8 s of the
same 357 s job, 0.8%, for a root-owned directory and one key.

## The shared allowance

**GitHub meters one allowance for each account, and every delegate spends it.** Every delegate
posts as one account, so one allowance covers every delegate that runs at once. No delegate can
see what the others spent. GitHub meters REST and GraphQL apart, and a refusal on one meter
says nothing about the other. Measured on this repository, 2026-09-12:

| Meter | Limit | State when a call was refused |
|-------|-------|-------------------------------|
| GraphQL | 5,000 points per hour per account | exhausted |
| REST | 5,000 requests per hour per account | healthy throughout |
| Secondary, shared | 80 content-creating per minute, 500 per hour | not reached |

**The split is by API, and not by subject or by tool.** Measured 2026-09-12, in one window on
one repository: `create_pull_request`, `actions_list`, `add_issue_comment` and `issue_read`
went through. `update_pull_request`, `issue_write` and `list_issues` were refused. Calls on
pull requests sat on both sides, so the subject of a call does not say which meter it takes.

- A GraphQL call shows itself by cursor pagination, an `after` and an `endCursor` from a
  `pageInfo`. A refused mutation fails at *"failed to get issue ID"*, which is the node lookup
  before the write.
- One tool can sit on both meters. `pull_request_read` pages its review-comment method by
  cursor, and its other methods by `page` and `perPage`.
- The draft toggle is on the GraphQL meter, because the refused `update_pull_request` passed
  `draft` alone. To open a pull request, a REST `POST`, is not.
- So no delegate can route around the allowance by a choice of tools. `GUIDE.md`, "The queue
  and the shared allowance", gives the observable rule: try the call you need before you
  decide that GitHub is shut.
- Unmeasured: what a single `list_issues` costs in points. The server surfaces no
  `x-ratelimit-remaining`, so the budget is spent blind. That is the strongest argument for
  asking git first, rather than for tuning page sizes.

## Open questions

- Whether a run that authenticates as `GITHUB_TOKEN` spends the allowance of the repository or
  the allowance of the account. The repository's would keep the ledger off the budget that
  every delegate shares. Nothing here has measured it.
- Whether the cache of the store restores on a `driven` run. The key `assets-<os>-…` saved an
  entry on the runner, 2026-09-12, and no run is recorded that restored one.
- Whether `watch.yml` fires from a `main` run that went red on its own. Each recorded firing
  was dispatched at a run already known to be red. So the reading and the reporting are proven,
  and the selection of the trigger is not. A red `main` is not worth causing to prove it.
- Whether the fields of `update_pull_request` other than `draft` take REST or GraphQL. No call
  has isolated one.
