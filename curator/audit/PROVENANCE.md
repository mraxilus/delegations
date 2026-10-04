# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | a2dba8c2495cd005 |
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
needs more verbs carries its own driver, `tools/build.nim`, which `koch check-types`, `koch drive`
and `koch list-packages` reach through.

- Rejected: make, which is a second toolchain with recipe tabs and untested glue.
- Rejected: NimScript `config.nims` tasks. They run in the VM of the compiler on a subset of
  the standard library, and load on every compile in the tree. They can shadow compiler
  commands such as `check`, and they cannot be unit-tested.
- Rejected: nimble tasks, which need nimble as a runner.
- Cost: one bootstrap compile for each checkout, and `koch` is a code file outside any
  project. The warm cost of the static pass is in Figures.

**Each verb names its action and its object.** `check` runs every check that a pull request
runs, and each `check-<object>` runs one of them. The other verbs act (`test`, `drive`, `head`,
`fix`, `fetch-deps`, `fetch-assets`, `stamp`) or print (`list-packages`, `list-projects`). A CI job
carries the name of the verb that it runs, so a red job names the command to run locally.
`./koch` alone prints every verb and option with its effect.

- Every verb that takes projects reads the one named, else `--recent`, else `--all`, else the
  projects whose code changed. One rule serves all of them.
- A verb refuses an option or an argument that it does not read, with usage and exit 2. So a
  typo never passes as an input that nothing reads.
- Rejected: a verb and its object as two words, such as `koch check files`. That puts a second
  dispatch inside the first, and makes the project the third argument.
- Rejected: `lint` for `check-files`, because the glossary avoids that word for Audit.
- Cost: the required checks carry the names of verbs. So a rename of a checking verb is also
  a change that the Architect makes to branch protection.
- Verified by hand, 2026-09-24: `koch check-scope contributor/x`, `koch stamp --drive` and
  `koch check-commits --all` each print usage and exit 2.

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
- Verified by `suites/test_tree.nim` on a throwaway repository: an ignored `bin/` is absent, an
  untracked file is present, and a rename shows as its destination alone. On one built with two
  merge bases, no field holds the warning and every field is a path. A second case holds that the
  `IOError` still carries git's own reason.

## File kinds

**An allow-list of kinds is the registry, and an unregistered kind is a finding.** `kinds.nim`
maps a basename or an extension to a comment syntax, and to whether prose is checked. Its
header table is a derived view of `LUT_RULE_BY_KIND`. Nimble files and NimScript read as Nim, and
cfg files as hash comments. `atlas.config` and `atlas.lock` read as JSON, by basename. Markdown
is prose rather than comment, so articles pass while the form rules still apply.

Html and Svg carry hand-written pages, which the layout check confines to `pages/` or
`mockups/`. Generated markup is one long line, and fails width on its own.

- Rejected: a Makefile kind. The registry admits no second build verb, so no recipe tab is
  exempt, and any tab is a finding.
- Rejected: content sniffing, which lets an unknown kind in silently.
- Cost: matching is by basename or extension only, so `nimble.paths` or `.mk` is unread.
- Verified by `suites/test_kinds.nim`, which reads the header table from the source and holds each
  row to the registry. Every match classifies at the root and in a folder, and the Syntax,
  Prose and Gate cells equal the rule of the kind. It also covers the last extension of
  `koch.nim.cfg`, and a set of unregistered names. `test_layout.nim` yields one finding on
  `data.csv`, which names `curator/audit/src/kinds.nim`.

**A kind whose language has a style guide is the only kind that `koch fix` writes.** The `Guide`
column of the table is `KindRule.has_guide`. STYLE.md is the guide of Nim, so Nim, NimScript and
nimble carry it, and they are the kinds that read as Nim syntax. No other language has a guide.

- Verified by `suites/test_kinds.nim`: the column equals the registry, and the guide marks the
  kinds of Nim syntax and no other kind.

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
- Verified by `suites/test_justification.nim` and `test_kinds.nim`. Verified by hand over real
  files, 2026-09-06. An unjustified `shim.cpp` and an unjustified `glue.ts` each yield one finding
  at line 1. Each falls silent once the phrase is added.

**Shell is gated as well, and the layout check holds it to `.claude/` and `.githooks/`.** It is
the hook glue of the curator: the command that Claude Code runs, and the scripts that git runs
as hooks. It never enters a project, by the ruling of the Architect (CONTRIBUTOR.md, The
language is Nim). Verified by `suites/test_layout.nim`.

## Comment extraction

**A hand-written scanner for each comment syntax, and one accumulator for each line.**

- Nim: line, doc and nesting block comments, plain, triple and generalized raw strings, char
  literals, and numeric suffix quotes.
- Configuration: `#`, unless `\#`.
- YAML: `#` at line start, or after whitespace, outside quotes.
- Ignore files: a leading `#` only.
- TypeScript: `//`, `/* */`, its string forms, and doc stars stripped.
- Markup: `<!-- -->`, which may span lines.

Whitespace runs collapse, so texts compare stably.

- Rejected: real parsers, which cost dependencies for a question that needs no syntax tree.
- Cost, assumed: a TypeScript regex literal that holds `//` opens a false comment.
- Cost: the markup scanner reads `<!-- -->` only, so comments inside `<script>` and `<style>`
  stay unread. Markup inside a Nim string has the same blind spot.
- Verified by `suites/test_comments.nim` across the syntaxes, including the testament header string
  and markup comments that span lines.

## Prose

**The prose check reads each comment of each kind, and knoller finds the articles in it.** The
rule, its data and its fixer are in the record of knoller, under Articles. Verified by
`suites/test_prose.nim`: a line that holds an article is reported, with the article named.

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
`sim/verdicts.md` added to `ENGLISH_PATHS`, `nim r koch check-files` reports 192 findings, measured
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
- Verified by `suites/test_english.nim`: each finding kind, the sentence-end cases and the block
  split. It also covers the collapsed span, the skipped quotation, and a path outside the set.
  That path is `gaps.md`, which a generator writes and no delegate may rewrite by hand.
- Verified by `suites/test_english.nim`: the derived arms. A project and a domain that do not exist
  yet are governed. A domain outside the registry is not, and neither is a README below a project
  directory. That last arm is the one that would redden `dance_ontology`, so it has its own
  assertion. One more assertion holds that a derived path is read, and not merely listed.

## Form

**Width is counted in runes. Any tab, any CR, and any ending but exactly one newline is a
finding.** An over-long line passes only where a break cannot fix it. Its longest
whitespace-free token, with the indent of the line, already overruns. That token is within
`TOKEN_MAX` (400 runes), and the rest fits once it is removed. A font URL has no whitespace to
break at, prose always does, and minified markup is one run far past the bound.

Lines split on LF only, so a CR survives. The syntax of a Nim banner marks its tier:
`#[ Title ]#` is the first tier, and `#[[ Title ]]#` is the second. The wired check demands two
blank lines before every banner, and one after. Where a second-tier banner follows its parent at
once, the child's own check governs the space between them.

**`checkBanners` holds X.2 exactly, outside the static pass for now.** A first tier takes three
blank lines before it, a second tier two, and either one after. A second tier that follows its
parent at once keeps its own two. The wired check accepts three, so the two checks agree on what
the fixer writes. The pull request that wires the exact check drops the lenient one, after each
project runs `koch fix` (CURATOR.md, duty 3).

- X.2 gives no count for a banner that opens the file, or for a run that ends the file. It
  gives none between two banners either, unless they are a parent and its child.
- The wired check reads no side of a banner where the exact check gives no count. So each
  layout that the fixer writes passes it, and the wired check reports no finding that it did
  not report before.
- Verified by `suites/test_form.nim`: the lenient check passes three blank lines before a first
  tier, and the exact check reports two. A fix writes the exact counts, and a second fix writes
  nothing. A banner at either end of a file, and a banner beside a banner, pass both checks.

- Rejected: an exemption for URLs by pattern, which guesses at intent. Rejected: an exemption
  for any single-token line, which admits machine output of any length. Rejected:
  `splitLines`, which swallows CRLF.
- Cost: a long identifier gets the same exemption that a URL does, because neither one breaks
  at whitespace. `LICENSE.md` is width-exempt, so third-party text stays verbatim.
- Assumed, and not checked: a two-space indent.
- Verified by `suites/test_form.nim`: 100 runes pass, and 101 breakable runes fail. A 202-character
  fonts link passes, while 207 of prose and 400 of minified markup do not. A tab in Nim and in cfg
  fails, and every ending case is covered.
- Verified by hand on real pages, 2026-09-05: hand-written markup and a fonts link whose
  longest token is 179 runes audit clean. A generated drawing of 1,407 characters does not.

**A generated npm lockfile passes the width rule.** Verified by hand with npm 12, 2026-09-06: a
generated `package-lock.json` of 93 lines, longest 117 runes, audits with 0 findings. Each long
line carries one `sha512-` digest of 95 runes, and fits without it, so the unbreakable-token
rule passes it. So the shape holds at any lockfile size, and the width rule needs no exemption
beside `LICENSE.md`.

**The static pass reads no gap of a trailing comment yet.** The check and its fixer are in the
record of knoller, under Form. Only Nim syntax is read, so a trailing comment in TypeScript, C,
C++, YAML, cfg or shell stays unread until each kind has a scanner. Verified by
`suites/test_form.nim`: `checkForm` reports no gap.

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
are findings, and are never skipped. `.claude` and `.githooks` are root directories beside
`.github`, unchecked inside. The hooks, the permission rules, the skill and the
`record-reviewer` live in the first, and git's own hooks in the second.

- Rejected: an early return under `curator/`, which drops an unknown head in silence, so a
  misplaced project leaves the audit.
- Rejected: domain READMEs that list projects, which forces a contributor to edit outside
  their scope. Rejected: a theme line for root READMEs, which is a fabricated authority.
  Rejected: an inference of mock-up from generated, which makes the distinction an accident of
  formatting.
- Cost: empty directories are invisible to git, so `tests/` must hold a file.
- No tracked path lies under `build/`, `dependencies/` or `node_modules/` at any depth (XI.3).
  The ignore file keeps them out, so this catches a forced add. A file that only bears such a
  name, such as `dependencies.nim`, is no directory and passes.
- Verified by `suites/test_layout.nim` over a fixture tree that the tests build. The project list is
  pinned, and the unknown-domain case asserts both the finding and the unchanged list.
  `test_audit.nim` proves that fixture clean under every static check.

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
- Verified by `suites/test_provenance.nim`. A citation renamed to an absent file, to a source file,
  or to the test of another project reports one finding. `koch check-files` resolves every
  citation on each run.

## Provenance stamp

**FNV-1a 64-bit over CONSTITUTION.md, STYLE.md, CONTRIBUTOR.md, EXAMPLES.md and GUIDE.md**, with CR
stripped, NUL between files, and 16 lowercase hex digits. CURATOR.md is excluded, so a
curator-only edit touches no project.

- Rejected: `std/sha1`, deprecated in Nim 2, which warns on every build. Rejected: the
  `checksums` package, a nimble install in CI for one digest. Rejected: `std/hashes`, unstable
  across Nim versions.
- Cost: it is a change detector and not a signature, so a collision needs an adversary.
- Verified by `suites/test_provenance.nim` for determinism, one-byte, order and boundary
  sensitivity, and CRLF invariance. Verified by `suites/test_audit.nim`: one byte in any rules
  document goes stale in every project, and one byte in CURATOR.md in none.

**`koch stamp --write` sets the `Rules` row of every provenance file itself.** `withRulesRow`
rewrites the row in place, and finds it as `headerFields` finds it, so what is written is what
the check then reads. A provenance file already current is not touched, and each path that
moved is printed. So duty 1 takes one verb for the rows, and no hand edit (CURATOR.md, duty
1).

- Rejected: a write of the whole header back, which would reformat a table that its writer
  padded.
- Verified by `suites/test_provenance.nim`. The new stamp lands, and the padding and every other
  byte stay. A second write is a no-op, and an absent row leaves the source untouched. Only the
  first `Rules` row moves.

## Provenance shape

**A `PROVENANCE.md` is read as `#` lines with the fenced code blanked, and is held to the forms
that the guide states.** No heading carries a date. `## Open questions` is the last `##`
section. No heading text appears twice. No title is underlined, because every reader here sees
`#` lines, and an underlined title is invisible to all of them.

**A provenance file over `RECORD_LINES`, 5,000, is a finding.** Its remedy is the prune that
the guide asks for. The ceiling is a backstop, and `SECTION_LINES` is the instrument that reads
narration. The Architect chose 5,000. At 3,000, the largest record, that of `rga_visualiser`,
stood exactly at the ceiling, so every addition there had to prune first. At 5,000, that record
stands two fifths clear.

- Cost: a long record can grow further before a prune is asked. The section ceiling still
  catches narration inside it.
- Rejected: 3,000. A backstop that fires on ordinary work reports growth, and not narration.

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
file itself, under `check-files` and `check`. That needs a full clone. A shallow one has no
such log, so the `check-files` job fetches every commit.

- Rejected: a split of a long provenance file into files by subsystem. The checker names one
  `PROVENANCE.md` for each project, and the stamp lives in its header. History is git's, and
  the row says where.
- Cost: line forms, and never a Markdown parse. A heading inside an HTML comment counts, and
  front matter is not skipped. No governed provenance file carries either.

**A number written before `files`, `suites`, `checks` or `tests` in the prose of a record is a
finding.** A count goes stale by the next commit, and nothing here reads it again, so the guide
asks for the command that counts. Fenced code and code spans are skipped, so a command and its
output may quote a count.

- Cost: a count spelled in words passes, and reading holds it.

- Verified by `suites/test_record.nim`, each form by line. `fencedOut` is verified by
  `suites/test_markdown.nim`.

## Glossary

**Shape only: a heading, `## Standards`, `## Language`, and a definition line after every
`**Term**:`.** The content is the contributor's and the Architect's, and a term enters only
when the Architect selects it. The check cannot know what was agreed, so agreement holds by
reading. It runs on the top-level `GLOSSARY.md` too. Zero terms and zero standards pass,
because the format creates entries lazily. Verified by `suites/test_glossary.nim`.

**A standards entry reads `- **Name**, owner and edition: symbols`, and the root holds what two
projects share.** The check demands the bold name, a comma after it and a colon after that, and
never reads whether the edition is true. Across glossaries, a standard that a project repeats from
the root is a finding at the project. So is one that two projects both list, at the later place,
and the finding names the root as its home. The match is on the bold name, so a standard written
two ways passes, as a paraphrase passes the duplicates check. Verified by
`suites/test_glossary.nim`.

**The people words that the glossary avoids are held out of the root Markdown files and the
Markdown under `curator/`.** `PEOPLE_WORDS` is the avoid list under Architect, Delegate,
Curator, Contributor and Role, cut to the words for people. It is read whole and without case,
plural included, outside code spans, fences and tables. A glossary is exempt, because it lists
the words it avoids.

- Rejected: the full avoid list, which holds build, rules and version, plain words everywhere.
- `identity` is left out, as the word of algebra in `curator/probe`.
- Contributor prose is not read. Verified by `suites/test_glossary.nim`.

## Prompts

**The opening prompts are held to duty 10 by a diary form and a size ceiling.** A prose line
that names a date, `#N`, `issue N`, `pull request N` or `run N` is a finding. An incident
belongs in this file or in the log, and only the rule belongs in a prompt. A prompt over
`PROMPT_BYTES`, 40,000, is a finding, so runaway growth is caught while an ordinary addition is
not. Code spans and fences pass, which keeps the carried-list example legal.

- Cost: `II.9`, `duty 10` and a bare year pass by shape, so only a whole date is diary here.
- Verified by `suites/test_prompts.nim`.

## Copies

**A paragraph of 25 words or more, written twice, is a finding.** It is reported at its later
place, and it names its first. That holds within one Markdown file, and across two. Fenced
code, table rows and headings are left out, and whitespace is collapsed before the comparison.
Two copies of one rule drift.

- Cost: a paragraph reworded by one word passes. The check catches a copy, and never a
  paraphrase.
- Verified by `suites/test_duplicates.nim`.

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

- **Nim literals that `&` carries across a line end are joined first.** A stack whose first
  family opens the next literal is then read whole. The joined text lands on the first line,
  and each line that it consumed is left empty, so every other line keeps its number.
- Cost: declarations are read and expressions are not. So a stack built from a variable is
  unseen, and so is a heading styled through a class alone. A finding inside a joined chain
  names the line where the chain opens. The desktop atlas is outside the ligature rule by X.8
  itself, because Dear ImGui shapes no text, and it declares no CSS.
- Verified by `suites/test_faces.nim`, each rule by line, and the label beside a heading among them.

## Coverage

**Each character beyond ASCII that the files of a project use has a face that the project
ships, and `coverage.nim` holds it.** Article X.8 merges faces by codepoint range, then renders
each codepoint against `.notdef`. A render needs a built page and a browser, and the static pass
has neither. So this check holds the static half: what the sources write, against what each face
maps. A character that no face of the project maps falls to a face that the viewer may lack.

- **The faces of a project are the store faces whose file names its files hold.** The store
  refuses a file that no row declares, so the name is the only way that a project reaches a
  face. The check takes the union over the project. Rejected: a check for each page or each
  stack, which repeats the cascade that a render decides.
- Cost: a character that no stack of its element reaches can still pass. The face that covers it
  may serve another stack, or the desktop atlas alone. The render of `drive` holds that case
  (`CONTRIBUTOR.md`, Pages and assets), as the Architect ruled on 2026-10-04.
- **The check reads every file of the project outside `tests/`, other than its records.** The
  drivers of the three page projects build pages from Nim, TypeScript, Markdown and JSON, as
  well as from `pages/` and `mockups/`, read 2026-10-04. The static pass cannot trace which file
  a build reads. A test fixture holds a character to prove its absence, so the tests stay out.
- Cost: a character in a file that no page reads is reported too, such as a message that a tool
  prints.
- **A character that a comment alone holds is set aside, line by line**, because it never
  reaches a page. The comments come from `comments.nim`, so the blind spots of that module are
  the blind spots of this check.
- **A reference counts as the character that it names.** `&name;` resolves for each name that
  HTML 4.01 defined, to the codepoint that the WHATWG standard gives, which is what a browser
  draws. `&lang;` and `&rang;` are the two names where those differ. `&#n;` and `&#xh;` resolve
  too.
- A name outside that table is unread rather than reported, because `&` opens no reference in
  most code here. C and C++ read no reference at all, because `&name;` takes an address there.
- **A finding names the file, the line, the codepoint and the spelling**, as in
  ``got `U+21C4` for `&#8644;` ``. A line gets one finding for each codepoint, however often it
  spells it.
- **A project that names no store face is skipped.** Nothing tells its page apart from a tool that
  prints text beyond ASCII. Cost: a page that ships no face at all is unseen here.
- **The checker's own project is exempt**, as the faces check exempts it, because `assets.nim`
  names every face as data.
- Cost: a codepoint that draws nothing, such as `U+FE0F`, is still reported where no face maps
  it. Verified by a search on 2026-10-04 at `de0c189`, of each file that the check reads. None
  holds `U+FE0F`, as the character or as a reference.
- Verified by `suites/test_coverage.nim`: each rule, and the law at every bound of the ranges of
  Noto Sans.

**The check decides coverage over the whole source before it scans the comments.** The faces
cover almost every character, and the comment scan is most of the cost. So only a source that
holds an uncovered character, in a comment or not, has its comments scanned.
`suites/test_coverage.nim` holds this path to a full reading of every source.

- Measured with the built koch on 2026-10-04, on the machine of Figures. `check-files` over the
  same tree took a median of 3.70 s from `origin/main` at `de0c189`, and 3.77 s with this check.
  Each median is of ten runs.
- Rejected: a comment scan of every source first. Measured the same way, it added about 0.45 s
  to the median.
- On 2026-10-04 at `de0c189`, the check reports no finding in any project. `nim r koch
  check-files` repeats it.

## Branch scope

**The branch grammar mirrors paths: two, three or four segments, and the scope follows from
them.** `curator/<name>` has the whole tree as its scope, so every path passes.
`curator/<project>/<name>` and `contributor/<domain>/<project>/<name>` own their folder. `main`
passes, because a push to it is a merge that the Architect approved.

- Rejected: a special case for the curator root. The whole tree is a scope like any other, and
  one mechanism reads it.
- Cost: fixed segment counts reject a nested branch name. The Architect may merge red
  deliberately, so this is a guard and not a gate.
- Verified by `suites/test_scope.nim` over each branch form and rejected forms. `test_domains.nim`
  covers the rejected forms of the branch grammar.

**The reach of a curator into a contributor project stops at its records.** Under
`contributor/`, the only writable paths on a curator branch are `README.md`, `PROVENANCE.md`
and `GLOSSARY.md`. Those are `PROJECT_FILES`, read from `layout.nim` rather than repeated.
Without this, duty 11 holds by reading alone, on the role that runs most often.

- Rejected: `PROVENANCE.md` and `GLOSSARY.md` alone. A rule change can make the README of a
  project false, for example where it names a pin, and that set blocks the fix.
- Cost: the README stays writable. So restraint about a rewrite of a project's prose is duty
  11's to govern by reading, and never the check's.
- Verified by `suites/test_scope.nim`: a curator branch that writes contributor code is a finding,
  and one that writes the records of that project is not.

**A curator may move the files of a contributor, and never edit them.** `tree.movedPaths`
reads `--name-status --find-renames=100%`, and `checkScope` exempts exactly those paths on a
curator branch. So only an exact rename qualifies, and an edit disguised as a move is still
caught. To rename a domain is a registry change, and the registry is the curator's. To move
files is the consequence, and never authorship.

Cost: a curator may reorder the files of a contributor without asking. Content cannot change
and the move is visible in review, so the cost is disorder rather than damage.

- Verified by `suites/test_scope.nim`: a moved path is exempt on the curator root alone, and a move
  never widens a project branch. `suites/test_tree.nim` holds on a throwaway repository that only
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

**A branch must carry the rules and the checker of its base before it may merge.**
`check-drift` reads what the base gained since the branch forked. It reports a branch that
predates a charter document or the checker. Without it, a branch green against the `main` it
forked from can merge into a later `main`. Its stamp can then be one that a later rules change
falsified.

Only two kinds of path count. A charter document moves the stamp that every project claims,
and the checker decides what the audit accepts. Everything else may differ freely.
`check-drift` feeds the `summarize` gate that branch protection requires, so no setting
changes.

On the runner the job checks out the branch head, and never the merge ref that a pull request
offers. The first parent of that ref is the tip of the base. So what it gained over the base is
empty by construction, and the check would report nothing on every fresh run. `check-files`
on the same merge ref is what holds a stale stamp there.

- Rejected: the GitHub setting "require branches to be up to date". It is blanket, and makes
  every open pull request stale on each merge. At this merge rate that costs more than it
  saves: 48 pull requests merged in the week to 2026-09-23, and 16 in its last day.
- Cost: a merge of a rules change reddens every open pull request until each one merges the
  base. The blanket setting costs the same, and this fires only where the staleness is real.
- Cost, the honest limit: this reads at pull request time, and never at merge time. So a
  branch green at ten can merge at five past, after another one lands. Only a merge queue
  closes that.
- Verified by `suites/test_base.nim`. Verified by hand with `nim r koch check-drift`, recorded
  2026-09-14. A branch a week behind `main` reports the finding at its head, which names
  `CONTRIBUTOR.md`, check sources and `koch.nim`. At a synthetic merge of that head into
  `main`, with `main` as the first parent, it reports nothing.

**A curator branch holds each finding inside a contributor project, and blocks on the rest.**
A check that reddens a project waits for that project to fix, and the curator never fixes it
(`CURATOR.md`, duty 3). Such a branch can never be clean, so `koch check` lists those findings
apart and runs types, suites and drive on the rest. It records the tree for the `pre-push`
hook when the rest is clean. The runner reads the whole tree and holds nothing, so the pull
request stays red until each project fixes, and the merge gate is unchanged.

Held means any path deeper than `contributor/<domain>/<project>/`, records included, because
duty 3 forbids the fix there too. The two indexes above a project are the curator's, so they
block. A finding that a rules change leaves for the curator carries a propagation flag at its
source, and blocks in any project. These are the stale stamp and a standard that belongs in the
root glossary. A contributor branch holds nothing: a finding in its project is its own, and one
in another project means that the base is red.

- Rejected: push past the hook with `--no-verify`, once for each branch. Every merge of the
  base after that first push needs a second one, and a red head can never pass the hook.
  The `bash` hook refuses `--no-verify` on a push.
- Rejected: match the stale stamp by its message. The flag sits where the finding is made, so
  a reworded message cannot move it into the held set.
- Cost: the role is read from the branch name alone, because every delegate posts as one
  account. A contributor that names a branch `curator/...` gets past its own hook and no
  further. On the runner, `check-scope`, `check-role` and `check-files` read the same name.
- Cost: a new check that reports false findings in contributor code has them held too, so
  its branch still pushes. The draft stays red, and duty 3 still has the curator read each
  finding before the issues open.
- Verified by `suites/test_scope.nim`, which fails with the propagation flag ignored, and by
  `suites/test_hooks.nim`, `suites/test_provenance.nim`, `suites/test_glossary.nim` and
  `suites/test_findings.nim`.

## Commits

**`type(scope)!?: summary`, with the commit types as data. On a project branch the scope must equal
the project.** The curator root accepts any valid scope, because a rules change propagates under the
scope of each project. A branch outside the grammar still gets format checking. Cost: the imperative
mood is unverified. Verified by `suites/test_commits.nim`: every type with several scopes, the
breaking marker, rejected forms, and scope enforcement on both project branch forms.

**A subject is at most `SUBJECT_MAX` runes, which is `LINE_MAX`, the limit of a line of source
(XI.1).** Branch commits carry no ` (#N)` from a squash merge, so the check counts the subject as
the delegate wrote it. Cost: subjects on `main` from before the cap run to 136 runes. They stay,
because the check reads one branch. Verified by `suites/test_commits.nim`: a subject at the limit,
one over it, and a subject counted in runes and not in bytes.

**The regression rule is enforced, and not hoped for.** `check-commits` reads the subjects
newest first. It demands that the commit immediately before every `fix` is a `test` of the same
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
- Verified by `suites/test_commits.nim`. The pair passes, and tests before the test pass. One
  finding comes from a fix alone, from a test after its fix, and from the test of another scope. One
  comes from a second fix on one test, and from a commit or a revert between them.

**A body is in sentence case, with one sentence to a line (XI.4).** Each line opens with a
capital, a digit or a code span. It ends on `.`, `!`, `?` or `:`, and holds no second sentence.
The trailer block is skipped, and so are fenced and indented code. A list marker is read past,
so each list item is held as a sentence too.

- Measured before the check, over the last three hundred commits on `main`. Half of the bodies
  with text wrapped a sentence across lines, the curator's own included. The check reads a
  branch, never the history, so it holds from the next commit on.
- Cost: a sentence boundary is a stop, a space and a capital outside a code span. An
  abbreviation such as `No. 3` then reads as two sentences, and STE writes such words out.
- Verified by `suites/test_commits.nim`. A wrapped line, two sentences on one line and a
  lowercase line each fail. A list, a code span, a version number and a fenced block pass.

**The record travels in a `docs` commit of its own.** A commit that touches `PROVENANCE.md` and
any file but Markdown is a finding. Measured over the same history, one commit in twenty mixed
them, most of them renames that the record cites. A rename and its record then take two commits.

- The message hook reads the body and the staged paths, so a delegate hears both before the
  commit lands. `check` and `check-commits` read each commit of the branch through `diff-tree`.
- Verified by `suites/test_commits.nim` and `suites/test_hooks.nim`.

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
- Cost: the labels are searched for the expected string rather than compared whole. A role
  label joins when work hands across, and role labels are never removed. The `architect` label
  marks a state and comes off, and the search passes over it.
- Cost: `check` cannot run this verb, because it has no pull request to read. It is the one check
  that a delegate meets on the runner rather than before a push.
- Verified by `suites/test_role.nim` on the line reader, the cut, and each arm of the grammar.
- Verified by hand with `nim r koch check-role`, recorded 2026-09-14. Pull requests replayed as they
  stood before they were mended, with neither line nor label, report both findings each. Pull
  requests of each role, as they stand, report none.

**The coordinator holds no branch, so `check-role` never reads it.** It opens issues and
comments, and no pull request. Its role string is `coordinator`, which `isRoleString` in the
`body` hook accepts (section Hooks on messages).

**The role line may stand below the attribution block of a harness.** A harness that starts a
delegate in a thread writes two lines above each pull request body that it opens, and it
requires them. First comes a marker, an HTML comment that opens `<!-- ccr-projects-attribution:`
and renders as nothing. Then comes a credit line in italics that opens `_Requested by **` and
names who asked. `roleLine` passes each line only whole and in its place. A credit line with no
marker, a second block or any other comment still reads as the opening line.

- Rejected: a skip of every leading comment and every italic line. Each would let a stray line
  pass where the role line belongs.
- Rejected: a request to each delegate to leave the block out. The harness marks the block as
  required, so the delegate would meet two rules that disagree.
- Cost: the block is the text of the harness, held as data in `LINES_ATTRIBUTION`. Where the
  harness changes it, each such pull request fails again. The suite stays green, because its
  fixture copies the block.
- The `body` hook reads the line through `roleLine` too, so it lets such a pull request through
  where the hooks run. The ledger reads the block more loosely (section Ledger).
- Verified by `suites/test_role.nim`: a body below the block reads as the body alone, with `\n`
  or `\r\n` line ends. Each stray part of a block reads as the opening line.
- Verified by hand with `nim r koch check-role` and `koch hook body`, recorded 2026-10-03. Before
  the fix, a body below the block read as an empty opening line. `check-role` exited 1, and the
  `body` hook refused the body with exit 2. After the fix, the same body reports nothing, and the
  finding echoes a wrong role below the block.

**The title of a pull request holds the grammar of a commit subject.** The merge commit takes
the title as its subject, and `main` takes no rewrite after. So `checkTitle` holds the title to
what `checkCommits` holds for each commit: the grammar, the scope that the branch requires, and
`SUBJECT_MAX`. The job passes the title as `ROLE_TITLE`, from the event payload. The `edited`
event runs the check again after a rename. The Architect ruled this check on 2026-10-04.

- Before this check, the template alone held the title. The title of #463 broke it, and it is
  the subject of `6d4606a` on `main`.
- `scopeRequired` in `commits.nim` names the scope for both checks, so the two cannot drift.
- Cost: the merge adds ` (#N)` to the title, so a subject on `main` can pass `SUBJECT_MAX` by a
  few runes. `check-commits` skips merge commits, so no check reads that width.
- Verified by `suites/test_role.nim`. Titles in form pass, and so does a branch outside the
  grammar. The title of #463 fails, as do a final period, a capital summary, a scope off its
  branch, and a width over the limit.

## Assets

**One declaration of every file fetched at build time, in `assets.nim`.** CONTRIBUTOR.md names
the class: *"binaries are never committed, and neither are fonts, images or any file the audit
cannot read"*. Each one is recorded with origin, version, licence and checksum. The store is
that class kept once, rather than once for each project.

Faces are the only rows, and the rows say so by grouping and by one column. The shape is file,
address, digest and the codepoints that the file maps. The first three are what any such file
needs, and the fourth is the face's own. **An asset that wants a field this row lacks is a
change, and not something this shape answers.** Such a field is unpacking or a variant set, and
an asset that is no face changes the fourth column too. The header says so, rather than implies
that the shape is settled for all time.

- **Each face row carries the codepoints that its file maps, as ranges.** The coverage check
  reads rows and never bytes, because the static pass fetches nothing. `suites/test_assets.nim`
  reads the `cmap` of each file and holds the row to it. So a new digest with old ranges fails,
  and the failure prints the ranges to take.
- Verified by a break, 2026-10-04. One bound of the Noto Sans Math row, one codepoint short,
  fails that test, which prints the true row beside the stale one.
- The ranges take the spelling of `fc-query --format='%{charset}'`, so a curator can check a row
  with a second reader. Fontconfig 2.15.0 printed the same text as the reader of the suite for
  every file of the store, 2026-10-04. Control characters are left out, because none draws.
- Faces that map one set share one constant. Upright Noto Sans and Noto Serif map one set at
  every weight, and the three files of Commit Mono map one set. A face whose bytes move splits
  from its constant.
- **The suite reads `woff2` through `libbrotlidec`, which it loads at run.** No Nim import decodes
  Brotli, and a codec is an external concern (Article II.8). A machine without the library fails
  that test by name, and every other suite still runs. Rejected: `fc-query` as the reader,
  which adds fontconfig to every machine and reads its charset rather than the `cmap`.
- Cost: the test fetches each face that the store lacks. Measured on 2026-10-04 on the machine
  of Figures: into an empty store, it fetched 5,670,612 bytes in 2.5 s. Warm, it took 0.08 s.
  The `test` job of the runner restores no store, so it fetches on each run.

The name is general, and names no class of file. So a second class needs no rename across
projects that a curator may not edit.

The store exists because Article X.8 gives the same families to every presentation target, so
a second target repeats the pins of the first. Two pins of one file, each in its own
`tools/build.nim`, are a copy that no real constraint forces (Article II.9). Nothing tells such
a copy from two different faces.

- **The digest is the curator's, and the choice is the project's.** The store says what bytes
  `NotoSans-Regular.ttf` is. It never says which faces a target wants, and the targets differ:
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
- **Pages and the desktop atlas embed whole Noto faces, from the Noto release (Article X.8).**
  Noto was chosen so that no character of a page falls outside its faces, and a subset undoes
  that. The rows hold each whole face that a page draws, as TrueType, which `@fontsource` does
  not ship. Where two projects pin one file, they pin one digest.
- **The store declares no Noto subset, and `suites/test_assets.nim` holds it so.** Every Noto
  row is a TrueType file of the Noto release. `koch fetch-assets` refuses a file that no row
  declares, so no page can ship a Noto subset.
- **Commit Mono keeps its Latin subset.** Article X.8 binds Noto alone, and Commit Mono is no
  Noto. Its two `woff2` rows are the only subsets of `@fontsource` in the store.
- Cost: a whole face is 610 to 780 KB of TrueType, where its Latin subset is about 13 KB. A page
  that inlines it as base64 carries about a third more again.
- One digest reader serves both fetches. `fetchAsset` reads the bytes that it fetched through
  `compilers.digestOf`, so the parse that `test_compilers.nim` tests also guards the store.
- Verified by `suites/test_assets.nim`. Verified by hand with the built `binaries/koch
  fetch-assets` on 2026-10-04, in the cloud container of Claude Code, into an empty store.
  Three whole faces, 2.0 MB, fill it in **1.5 s**. The same call warm takes **0.002 s**, and
  fetches nothing.
- Verified by a break of it, on 2026-09-10. A face that nobody declares is a finding, which
  names the table to add a row to. Alter one declared digest in its last character, and the
  fetch refuses the bytes and **leaves the store empty** rather than keeps them.
- Cost: the store grows and nothing prunes it. A face is less than 1 MB, where a compiler is
  about 300 MB. So what is unbounded is the number of pins the repository has ever held, and
  not the bytes.
- Cost: an upstream that moves bytes under one address fails every project at once, rather
  than one. That is the same failure that a digest exists to make loud, and it is louder
  shared.
- **The Nim tarball is deliberately not here.** It is fetched and checksummed too, but its
  digest comes from the sidecar of upstream at fetch time, rather than from this table. It is
  stored *unpacked by pin*, because the rest of koch resolves toolchains by pin. The trust
  model and the key both differ, so `compilers.nim` keeps it, rather than this table pretends
  that one shape serves both.
- **The declaration is published, so no consumer parses this source.** `koch fetch-assets` that
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
- an issue whose title takes the form of a commit subject;
- an issue or pull request closed with the `architect` label still on it;
- the rulesets of `main` or the ruleset on every branch drifted from the list in `CURATOR.md`.

The settings read goes through the rulesets endpoints. The classic protection endpoint answers
nothing where the rules are rulesets, so the ledger reads the rules per branch with the token of
a run. That token lacks the administration scope, so GitHub leaves the bypass actors out, and
the secret `TOKEN_DELEGATE` reads them. An anonymous read sees them too, but runners share
addresses and the anonymous limit is sixty per hour. The run token and a fine-grained token
miss the repository merge settings, so `TOKEN_DELEGATE` is a classic token and reads them. A read
that fails turns the run red, because a silent read is the failure the ledger exists to catch.

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
- **On a pull request, the role line may also follow the credit line of an attribution block**
  (section Role). The ledger passes that line after any leading comment, and not only after the
  marker. That is looser than `roleLine`, as the rest of the ledger reading is. An issue carries
  no block, so the pattern for issues does not pass the line.
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
- **An issue opened again after the merge passes.** GitHub reads a closing keyword in any
  sentence, so a body that says it does not close an issue closes it all the same. The delegate
  who opens that issue again does so on purpose, and `closingIssuesReferences` keeps the link.
  So the ledger reads the events of each issue that it would name, at the cost of one read each.
  It passes an issue with a `reopened` event after the merge, and still names one opened again
  before it. Verified by hand through a stub for `gh` and real `jq` 1.7, 2026-10-03.
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
- The pattern for pull requests, verified by hand through `jq` 1.7 and `gojq` 0.12.19 on
  2026-10-03. `gh` runs `--jq` through `gojq`, at 0.12.17 in `gh` 2.89.0. The program was read
  from the workflow file, and it was run over fixture bodies. A role line below the block
  passes, also unbolded and with `\r\n` line ends. A block over no role line, or over an
  unfilled template, is named.
- Verified by hand through a stub for `gh` that serves fixture JSON through real `jq` 1.7,
  2026-09-24. The step runs as the workflow holds it. Over the fixture titles, each expected
  title is named and no other, among them `fix:`, `feat(audit)!:`, `bug:` and `koch:`. Over
  the real titles of that day, the step names nothing.
- Cost: the pattern is `jq` inside shell, as the role-line pattern is, so no suite drives it.

**The ledger names a closed item that still carries the `architect` label.** The label marks a
state, and not a role. A delegate adds it to its own item that waits on the Architect, and
removes it once the ruling is posted (`CONTRIBUTOR.md`, Boundaries). `architect.yml` removes it
from an item that closes, because the delegate that asked has often ended by the merge. So a
closed item that still carries it marks a failed run of that workflow. The next filter on the
label would show a stale queue.

- **The workflow fires on a close alone, and never on a return to draft.** A decision can wait
  on a draft pull request, and a label removed there would hide it from the Architect. Rejected:
  removal on `converted_to_draft`, which `draft.yml` fires on each push to a ready pull request.
- The workflow reads the labels before it removes one, so an item whose label somebody removed
  first is no failure.
- Its grant is `issues: write` and `pull-requests: write`. The reference of the issues endpoint
  says that either grant reaches the labels of a pull request. For the token of a run, that is
  false. Verified by run 1 and run 2 of `architect.yml`, 2026-10-04. Run 1, with
  `issues: write` alone, failed with exit 1 on the merge of #463. Run 2, with both grants and
  the same script, removed the label on the merge of #467.

- Pull requests are read in every state and then filtered, so a closed one and a merged one
  both count.
- The role-line pattern for issues names `coordinator` beside `curator` and `contributor/`,
  because a brief and a ruling of the coordinator open with its role line. The pattern for pull
  requests does not, because the coordinator opens no pull request.
- Cost: `--limit 100` reads the newest hundred of each kind. A stale label older than those is
  missed. The coordinator removes each label as it goes, so the list stays short (inferred).
- Cost: `gh` filters a label through search, so a label that no item carries yet reads as no
  item. That is inferred from the source of `gh`, and not run against GitHub. A read that fails
  instead turns the run red, by `set -e`, and is never silent.
- Verified by hand through a stub for `gh` that serves fixture JSON through real `jq` 1.7,
  2026-10-03. The step runs as the workflow holds it. The fixture holds two closed issues and
  three pull requests: one open, one closed and one merged. The step names both issues and the
  closed and merged pull requests, and nothing else. Over no item, and over one open pull
  request, it names nothing. Through a stub whose every read fails, the step exits 1.
- The role-line pattern for issues, verified by hand through real `jq` 1.7 on 2026-10-03, over
  fixture bodies read as the workflow holds them. `**Role:** coordinator`, after a marker or
  alone, passes, and so does `Role: coordinator` unbolded. `**Role:** coordinat`, a missing
  role line, a null body and an unfilled template are named.
- Cost: `gh` runs `--jq` through `gojq`, and the two checks above ran `jq` 1.7. That the two
  agree here is inferred. No program calls a builtin that `gojq` lacks, and the pattern holds
  no lookaround and no back-reference.

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
workflows state a version. Verified by `suites/test_toolchain.nim` over both paths.

**A pin moves on evidence, and the evidence is a run rather than a release note.** Nim assigns
no CVE, so no release in the 2.2 series carries one. So the reason to move is what the release
notes carry. Between 2.2.6 and 2.2.12 they fix a SIGSEGV under ARC, ORC and refc, and a use
after free. They also fix an overlapping `copyMem`, and overflow checks that could be escaped.
The curator projects pin 2.2.12 for that reason.

- Verified by `nim r koch test` over `curator/audit` and `curator/probe` on 2.2.12,
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

So `nim r koch check` stays green as one command over a changed set that spans pins. These traps
hold here.

- **A half-built toolchain lies.** A probe of `bin/nim` before the `boot` step of Nim's own
  `koch` finishes returns the csources bootstrap binary, which answers `--version` with an
  unrelated commit. So a source build completes beside its destination, and moves in only when
  it is done, as a tarball does.
- **To name a tool by path is not enough.** Atlas resolves `nim` through `PATH`, so an Atlas
  named by path alone reads whichever compiler `PATH` holds, and warns `environment mismatch`.
  Children run with the `bin` of the toolchain leading `PATH`. A tool absent from a toolchain
  falls back to `PATH` rather than raises, because the tools that Nim's own `koch` builds move
  between Nim versions.
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
- Verified by a break of it, and not by a fetch that happened to pass. `test_compilers.nim` digests
  a temporary file, changes one byte, and checks that the digest moves. The parse is
  mutation-tested: drop its hex validation and the suite reddens.
- Verified by hand, 2026-09-10: `2.2.2`, which nothing on the machine served, fetched,
  digest-checked and unpacked.
- Honest limit of that test: the exit-code check of `sha256sum` is belt-and-braces, because
  the parse already rejects the error text, so no test distinguishes it. It is kept for saying
  what it means.
- Verified by `suites/test_toolchain.nim`, `test_compilers.nim` and `test_projects.nim`. Verified by
  hand, 2026-09-06: `curator/probe`, pinned to a release that nothing local served, fetched the
  tarball and ran. One command over projects on two pins gave **0 findings**, and its log held no
  Atlas mismatch warning.
- A pin that nothing can serve is one finding, which names the pin and the cache it tried, and
  not a crash. Cost, unmeasured on the current pin: the time of a cold fetch.

## Dependencies

**Atlas holds the packages of each project.** Requirements sit in `<project>.nimble`, and
checkouts in the ignored folder that `atlas.config` names. Exact commits sit in a committed
`atlas.lock`, and paths in a committed `nim.cfg`. `koch fetch-deps` runs `atlas --noexec rep` in
every project that holds a lock. It judges success by `atlas changed` exiting zero.

- Rejected: one Atlas project at the root. Atlas 0.9.0 has no shared-workspace model, and a
  root `nim.cfg` would leak every dependency into every project through parent-config lookup.
  The constitution also wants each dependency justified where it is imported (II.8).
- Costs, verified by hand with Atlas 0.9.0, 2026-09-05. Atlas clones `nim-lang/packages` before
  any command, so it needs the network even for zero packages, which is why a lock-less
  project skips it. `atlas rep` exits 1 after a restore, because its submodule step fails, and
  that is why `atlas changed` gives the verdict. A dependency used by two projects is cloned
  twice.
- Verified by `suites/test_dependencies.nim` for the parser and the lock-less skip. The Atlas
  command flow was verified by hand on a throwaway project, 2026-09-05. Assumed, and not verified
  here: the same flow on the runner.

**`atlas changed` alone does not prove that a restore happened.** It exits 0 while it warns `repo
missing!`, so a restore that fetches nothing reports success. `checkCheckouts` reads the `dir` of
every lock item, and resolves `$deps` to the directory that the project's `atlas.config` names. That
is `dependencies` (Article V.9), or Atlas's own `deps` when the file names none. It then demands
that the directory exists before `atlas changed` is consulted.

Measured on Atlas 0.9.0 by a delete of `deps/` and a re-run. Cost: the lock is parsed twice for each
restore. Verified by `suites/test_dependencies.nim` over a project with and without the directory,
and over a lock that is not JSON.

**The lock silently reverts an edit to the nimble file.** `atlas.lock` stores a whole copy of
the nimble file under `nimbleFile.content`, and `atlas rep` writes it back over the file. So a
requirement edited without a regenerated lock is undone on the next `koch test` or `koch check`.
Nothing fails at that moment, so the loss surfaces later, as a `koch check-files` finding on a
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
- Verified by `suites/test_dependencies.nim`. Verified by hand against the real lock, recorded
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

- Rejected: a scope on the static pass. The static pass costs about four seconds, against
  seconds to minutes for the suites of one project (Figures). A scope buys nothing measurable
  there, and costs a second code path and the whole-tree layout and stamp guarantees.
- Cost: a change to the checker can leave an unchanged project red until it next changes, and
  nothing compiles it sooner. To run that suite is the work of that project, which is the
  point of the rule.
- Cost: `isChecker` reads the path, and never the content. So a comment edit in `koch.nim`
  compiles `curator/audit`: one project, seconds. `comments.nim` already extracts comments for
  each kind, so `list-projects` could ask whether anything but comments changed.
- Rejected: that comment detector, because it errs toward compiling too little. A wrong
  "comments only" reports green for work it never did, which is the failure this repository
  refuses everywhere else.
- Verified by `suites/test_plan.nim`: a README-only change plans `[]`, and a one-line source change
  plans that project alone. A change to `koch.nim` plans `curator/audit` alone. `--recent` plans
  every project in a repository younger than its window, and nothing over a window without a
  commit.

**The weekly run fires, and it promises a day rather than an hour.** Verified on the runner,
2026-09-07: every project planned, each on its own pin, and its jobs started within one second.
The phase finished in about four minutes, against about nine summed. It fired **6 h 09 m after
its 06:00 slot**, which is what GitHub does with `schedule` under load. So a curator who reads
the cron and returns at 06:05 finds nothing. To wait is part of a read of this signal.

**The weekly run plans what merged inside `RECENT_DAYS`**, and nothing in a quiet week. It
judges "code" by the record-file exclusion that scoped runs use. Rot arrives with merges, and
to compile a project that nothing touched is runner time for no information.

- Rejected, by the rule of the Architect that every run covers what changed: a weekly run of
  every project whenever anything merged. Cross-project rot from a checker change surfaces when
  that project next changes.
- Cost: rot from outside the repository goes unseen through a quiet week, such as a runner
  image that moves under a pinned compiler.
- The window is named twice, as the cron and as `RECENT_DAYS`, and `checkWindow` holds the two
  together (Watching main).
- A repository younger than the window has every commit inside it. So the skip is verified by
  suite rather than by a live Monday. `test_plan.nim` drives `recentFor` on a throwaway repository,
  and drives the decision of `jobs` over code, record-only and empty changes. `test_tree.nim` drives
  `revBefore` at both ends.

## Project runner

**`testament --nim:<absolute> pattern "tests/t*.nim"` in each project directory, serially,
with the output streamed.** Koch holds the verb once, and no build file for each project
exists. The compiler path is absolute, because testament resolves `--nim` against its working
directory. A failure is a finding at the `tests` directory of the project, and it echoes the
exit code.

Each project carries a `Target`: its directory, and the `bin` of the toolchain that serves its
pin. Tools come from that `bin` rather than from `PATH`, because two projects on two pins
would otherwise share one compiler in silence. Verified by `suites/test_projects.nim` with a
passing and a failing fixture, driven through real testament.

- Cost: projects and their stubs run one at a time. A project in another language needs its
  own runner arm.
- Rejected: one testament for each stub, four at a time. It took `dance_ontology` without
  `trigid` from 52 s to 17 s, measured 2026-09-24 on the Figures machine. But concurrent runs
  share `testresults/` and interleave their output, and the slowest stub bounds each project.

## System packages

**System packages are installed from the declaration of each project, and never from names in
a workflow.** `koch list-packages` runs the `system` verb of each selected project, and prints the
union, sorted and deduplicated. The job pipes it into `apt-get`. Koch prints and never
installs, because which package manager serves a name is the business of the machine, while
the list is the project's.

Only bare names survive the read. The contract is one name to a line. The one other thing
that reaches that stream is the compiler complaining, which always spells a position first. So
a line that carries whitespace is dropped. A compiler that complained still fails, because the
absent package names itself.

**Koch declares its own system packages, as the rule it enforces asks of every project.**
`KOCH_SYSTEM` in `projects.nim` pairs each one with its reason. It holds git and curl, `tar`
for the tarball that `fetchRelease` unpacks, and `coreutils` for `sha256sum`. It also holds
`libbrotli1` for the audit suite, which reads `woff2` faces, because `curator/audit` carries no
driver with a `system` verb. The runner holds it: verified by run 906 of `check`, whose `test`
job ran that suite and passed.

`koch list-packages` with no project prints those and every project's, unscoped, so one
command answers what a machine needs before any of this runs. To name a project keeps the
meaning for each job that the runner asks for.

Nim is deliberately absent. It is the toolchain that koch runs under, rather than a package
that a machine installs, and `compilers.nim` resolves each pin itself. npm is absent because it
belongs to the project that carries a node manifest, and `restoreNode` reports its absence by
name. The root `README.md` points at the verb rather than names packages, so the declaration
is the only statement and nothing can drift from it.

- Rejected: an exemption stated in `CONTRIBUTOR.md`, which leaves the rule true and the
  repository still answering its own question in prose.
- Cost: the packages of koch itself are unconditional, so a machine that needs none of them
  still installs them.
- Verified by `suites/test_plan.nim`: koch declares what it needs, as the rule asks of every
  project.

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
`tests/suites/`, and `tests/test_suites.nim` is the one stub. It imports every suite, so the
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
whole-tree run. Verified by hand, 2026-09-08: `nim r koch test` over every project passes with
0 findings. Each project ran on the compiler that it pins, with one pin alone on `PATH`.

**Trap: `koch check` selects suites from committed paths.** `changedPaths` reads
`git diff <base>...HEAD`, so a change that is not committed selects no project. `koch check` then
passes on a tree that a fresh checkout fails. Commit before `koch check`, or run
`nim r koch test <project>`, which runs that project whatever changed. Testament itself
rebuilds a suite whose source module changed, with a warm `nimcache`. Verified by hand,
2026-09-24: a change to `src/findings.nim` alone is compiled into the next run.

## Type checking

**The runner reaches the TypeScript of every project through the verb of that project.**
`koch check-types` restores node tools from the lock of the project, and runs
`tools/build.nim types`. That verb derives whatever those scripts read, and type-checks every
configuration, and it stops before anything that needs a browser. Koch names the verb and
nothing else, because what a check needs differs for each project, while the name need not.

- **Enrolment is derived, and never listed.** `nodeDirectories` selects the projects that hold
  `package.json` beside `package-lock.json`. So a project enrols by carrying them, and no
  second list can drift. The lock is demanded because `npm ci` needs one, and unpinned tools
  would be the one thing here that nothing pins.
- **No pin is resolved and no toolchain fetched**, because `tools/build.nim` compiles no
  project code. It derives declarations by a read of source as text. To build a commit-pinned
  compiler to run a build script would cost minutes for no checking. Cost, and the condition
  it rests on: this holds only while a `types` verb compiles no project code. One that did
  would need its pin, and would become a matrix job.
- **Scoped as `test` is, though with no matrix.** The scope lives in the verb, which takes
  the projects that one change asks for, by the `testSet` rule. `--recent` scopes it to the window
  of the weekly run.
- **Absent npm is a finding that names it, and never a skip.** A check that quietly does
  nothing reports green for work it never did.
- Verified by hand against the regression it exists for, 2026-09-07. A rename of
  `nimSceneHandles` to `nimSceneSlots`, with nothing else touched, reports one finding over
  `TS2304` at four sites in `construct_section.ts`. Reverted, it reports 0 findings.
- Cost, unmeasured on the current pin: the whole verb, with `npm ci` included.

## Driven checks

**The runner drives what the suites cannot reach, through the verb of that project.**
`koch drive` restores the checkouts and node tools of a project, then runs
`tools/build.nim drive`. The verb builds the page and drives it through held keys, wheels,
right-button pans, two-finger pinches and long presses. Testament tests rules, such as what a
slide does to the pivot, and nothing in it presses a key. So a rule wired to the wrong event is
a defect that no suite here can see. A driven check that the runner never runs is evidence only
that its writer ran it (Article IX.6).

**Enrolment is the verb, read from the driver of the project itself.** `verbDirectories` reads the
dispatch of `tools/build.nim` and selects the projects that name `drive`, the derivation that
`nodeDirectories` uses one step earlier. `dispatchVerbs` reads the dispatch of koch and of a project
driver alike, with the opening line as an argument. Koch cases over parsed options, and a
project driver over its first argument. Cost: a project that spells the verb otherwise is
passed by in silence, which is why CONTRIBUTOR.md names `drive`, `head` and `system` outright.

**It is a matrix, each project on its own pin, where `check-types` is one plain job.** `drive`
calls `web`, which runs `nim js` over `bridge.nim`, and that compiles project code and
everything it imports. So `rga_visualiser` on the compiler of koch fails inside
`multivectors.nim` of `pga`, whose syntax only the pinned commit can lex. The type check rests
on a verb that compiles no project code, and `drive` breaks that condition. So `koch drive` is
planned like `test`, and `list-projects --drive` filters what `list-projects` already selected.
It inherits the scoping, `--all` and `--recent` from there.

- Rejected: one plain job on the compiler of koch, as `check-types` runs.

**The shared store is cached, and `build/fonts` is not.** `koch fetch-assets` fetches into
`~/.cache/koch/assets`, and that store is the repository's. So the cache keys on its
declaration, `curator/audit/src/assets.nim`, and one entry serves the job of every project. On
the runner the fetch is 6.6 s cold, and the copy into `build/fonts` is milliseconds, recorded
2026-09-11.

- Rejected: a cache of `build/fonts` keyed on the driver of a project, which keeps the cheap
  half and misses the expensive one.
- A looser `restore-keys` entry is safe here by construction rather than by check. The store
  names entries by digest, so an entry that no row declares is unreachable rather than wrong.
  `koch fetch-assets` fetches whatever an older restore lacks.
- Verified on the runner, 2026-09-12: with no cache of `build/fonts`, the second `assets` pass
  of a job copies nothing. The first pass puts every face in place, so that cache saves
  nothing.

**The browser that a declaration names is the browser that runs, and the snap serves.**
`apt-get install chromium` on `ubuntu-latest` gives `/snap/bin/chromium`, a wrapper rather than
a plain binary, and Playwright launches it. Where a package does not serve the runner, the
declaration of the project changes. A name is never substituted here in silence.

Verified on the runner, 2026-09-07, which is the only place the claim means anything. Every
driven check passed with 0 findings, in a real Chromium over real gestures, with the gate
reading its verdict. Verified by a break of it: on the compiler of koch the same command fails
inside `pga`.

## Head checks

**A check against an outside reference that moves runs daily, and never where a merge waits.**
Such a reference is the head of a library repository, which changes with no commit here. A
check that reads it gives two verdicts on one commit. CONTRIBUTOR.md, Tests are paramount,
forbids that for a check of the code. So the project carries that read as its own verb, `head`,
and `test` and `drive` hold the pin alone. `koch head` restores the project and runs
`tools/build.nim head` on its own pin, as `koch drive` does, and `check` never calls it.

**Enrolment is the verb, as for `drive`.** `carryingOnly` keeps the projects that
`list-projects` selected and whose driver dispatches the verb, and `drivenOnly` is that filter
for `drive`. `head.yml` asks `list-projects --all --head`, because a reference moves whether or
not code changed.

**One issue stands for each project while its verb fails.** `head.yml` edits the open issue that
carries the marker of the project to the latest run. It comments only where the finding
changed, so a subscriber hears of a new head once. A run where the verb passes closes the
issue, and the next failure opens a new one. The finding is the output from the line
`== <project>`, which koch prints before the verb, so restore output never reads as a change.

- A failing verb is a finding for the issue, and the job stays green. The job goes red only
  where it cannot set up or post, and `watch.yml` reads that.
- Rejected: a lane on each push that may fail without blocking. It repeats one finding on each
  push, and a mark that never blocks is read by nobody.
- Rejected: a read of head inside `drive`. One commit then passes and later fails, and each merge
  of that project waits on a bump.
- Cost: the reference is read daily, so a pin may lag its head for up to a day before the issue
  says so.
- Cost: the compiler arms, packages and Atlas cache of `head.yml` copy those of `drive` in
  `check.yml`. A workflow shares steps only through an action of its own.
- Verified by `suites/test_plan.nim` and `suites/test_projects.nim`: the filter, and a real
  driver whose `head` exits 1.
- Verified by hand against a stub `gh`, GNU bash 5.2, 2026-10-02. A failing verb with no issue
  opens one. The same finding the next day edits it and adds no comment. A new finding edits it
  and adds one comment. A passing verb closes an open issue, and posts nothing where none is
  open.

## Names

**Every declared name in Nim is read, and its words are held to the table and the
glossaries.** A declaration is a binding, a routine, a type, a field, a parameter, an enum
member or a placeholder. A text scanner reads them after comments and strings are blanked. A
binding comes from `let`, `var`, `const`, `for` or `except … as`. A word is a run between
underscores and case changes. The table pairs each coined abbreviation with its one full word,
as the English check pairs a word with its approved one.

An acronym is a run of two or more capitals inside a camel or Pascal name. It passes only where
the root or the project glossary lists it, as a symbol under `## Standards` or as a term. The
jargon list of V.6 passes. Verified by `suites/test_names.nim`.

**A foreign binding keeps the library's name.** A routine carrying `importc`, `importcpp`,
`importjs` or `dynlib` declares a name that the library chose, so it is skipped. By the ruling
of the Architect, its parameters are ours, and they are read. So `wake: bool` takes a boolean
prefix like any other parameter. The pragma block may stand on its own line after the
signature, and the scanner joins it.

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
finding, which cites III.5.

- A type, a routine, an enum member and a placeholder are no variable, so their case is read.
  `std/unicode` gives no case to the mathematical alphanumeric letters. So `letterCase` reads
  them by their block, where each style runs its capitals first.
- An operator is backticked, so it is never read as a name.

**A one-letter capital local is a finding, by the ruling of the Architect.** Plain ASCII is
never notation. So `N` or `M` as a local, a parameter or a field takes the snake case of V.1.

**A parameter that holds a type is a parameter, by the ruling of the Architect.** So
`t: typedesc` takes the snake case of V.1. The one capital of V.12 is for a placeholder in
brackets, as `scalar*[I: Basis](t: typedesc[I])` shows. `STYLE.md` spells its borrow template
that way.

**One function decides the reach of a binding.** The case of a binding marks its reach, and not
its mutability (V.1). So `reachOf` reads the blocks that enclose the binding:

- A routine makes it local.
- The entry block, which is a top-level `when isMainModule:`, makes it an entry binding.
- A binding that opens its own scope, such as `for` or `except … as`, is local.
- It is global where every enclosing block opens no scope. Those blocks are a `when` chain, and
  a bare `let`, `var`, `const` or `type`. Any other block makes it local.

**The entry block holds no binding (V.10).** Where a module runs as a program, code that binds
goes in `proc main`, and the block calls it. A binding in the entry block reaches the whole
module, because `when` opens no scope. A routine makes it a true local in every language. The
Architect rejected the exception that made such a binding a local of its block.

- By the ruling of the Architect, every binding in the entry block outside a routine is a
  finding, at any depth. The reason is that code that binds moves to `main`.
- So a `for`, an `except … as`, and a `let` inside a loop of the block are findings too.
- Each binding there is one finding, and its case is not judged. A block of plain calls
  passes, and so does a routine inside it.

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
- A SCREAMING name is all capitals, so its acronyms cannot be told from words and hold by
  reading.
- Rejected: a parser, which costs a dependency and a compiler version. The scanner reads the
  line forms that this charter prescribes.
- V.6 has a fixer, which renames through the semantic pass (`## Semantic pass`). The check and
  the fixer share one reading of the words and of the exemptions of the glossaries.
- V.1 and V.11 have a fixer through the same pass, which reads the case as the check reads it
  (`## Semantic pass`). V.10 has a fixer that moves the entry block into `proc main`
  (`## Content fixes`).
- A name that a template substitutes declares nothing of that name. So `type name = object`
  inside `template defineKind(name: untyped)` is no type, and its fields are read as before.
- A `static` parameter of a generic is a placeholder, so it takes one capital letter, as V.12
  says (`[N: static int]`). The Architect weighed snake case, and kept the text.
- Rejected: a capital letter that passes every kind. It would pass `N` as a local, which the
  Architect ruled a finding.
- Cost: a declaration shape outside those forms is unread. Examples are a tuple type in
  brackets, and a name that `{.inject.}` makes.
- Cost: a boolean is read only where its declaration shows it, by the type `bool` or by the
  value `true` or `false`. A boolean that a call returns holds by reading.
- Cost: a Pascal name of capitals alone, such as `ANTI`, reads as an acronym and passes. V.9
  and reading hold it.

## Idioms

**Each idiom of STYLE.md and Article X.5 that one line shows is read on the code-only view of
the names check.** So a string or a comment never trips it, and a page template held in a string
reads as text. The module states each rule in its header, and the list here gives the reasons.

- `strictFuncs` stands in its exact form before the first import, in every module.
- A bracket import is alphabetised in dictionary order (X.10), and the standard library comes
  before packages, then local modules. A bracket that spans lines is read whole.
- Adjacent imports of one directory share one bracket, and a bracket of one module drops its
  bracket (X.5, STYLE.md §5). `checkImportBrackets` holds this, outside the static pass for now.
- A pragma list of a declaration, an `export` list and the names after `from … import` are
  alphabetised, bare pragmas first (X.10). `checkLists` reads tokens, and stays outside the
  static pass for now.
- Two consecutive single bindings of one keyword share it, reported once for each run. A `let`
  beside a `var` passes, because they cannot share one keyword.
- A `{.used.}` carries a comment that names its consumer. A `{.push.}` stands only over foreign
  bindings. `return result` never appears, because a bare `return` exits with `result`.
- Under `tests/`, a suite that imports `std/random` seeds it, and a stub carries its testament
  header, without `-r`, `batchable` or `joinable`.
- A path of one machine is a finding in every kind but Markdown. The checker names such paths
  as fixtures, so its own project is left out, as the faces check leaves it out.
- `tsconfig.json` sets its three flags to `true`, read as text, because TypeScript admits
  comments that `std/json` refuses.

**Debug output is told from a report by its shape alone.** An `echo` in a test that prints a
value with no label, outside a condition, is the shape that debug output takes. A labelled
`echo` passes as the report of a measured figure, and one under a condition passes as a failure
diagnostic.

- Rejected: every `echo` in a test, which reports a deliberate measurement as debug output.
- Cost: labelled debug output passes, and reading holds it. A seeded `initRand` passes as
  `randomize(0)` does, because both fix the sequence.
- Verified by `suites/test_idioms.nim`, each rule by its breach and by its form.

## Knoller

**The fixers that read the text of one file alone are a project of their own, `curator/knoller`.**
Each module of audit that needs one imports the umbrella of knoller by a relative path, as
`koch.nim` imports audit. A sibling imported by its path is not a package, so it needs no lock.
The record of knoller holds the design of those fixers.

- `findingOf` renders each report of knoller as a finding. A rewrite renders as its rule and the
  article that `CITATIONS` holds for it, so `koch fix` prints `expression spacing (X.9) fixed` as
  before. Verified by `suites/test_findings.nim`.
- `fixes.nim` maps each kind of Nim onto a dialect of knoller, a module, a script or a package.
- Rejected: knoller copied first and audit switched later. The code would stand twice, and the
  paragraphs of the records copied word for word would trip the check of copies.

**The checker holds knoller as it holds itself, because koch compiles it.**

- The rebuild key of `.claude/hooks.sh` holds the source and the nimble file of knoller. `git
  rev-parse` prints the first path that HEAD lacks and then stops. So knoller comes last, its
  source before its nimble file, and an older branch keeps a stable key. Verified by
  `suites/test_hooks.nim`: a commit of the source of knoller alone builds the binary again.
- A change to the source or the nimble file of knoller counts as checker for drift, and selects
  audit for test as well as knoller. A change to a suite of knoller selects knoller alone.
  Verified by `suites/test_plan.nim` and `suites/test_base.nim`.
- Knoller pins the driver version, and `checkKnoller` reports a pin that differs. Verified by
  `suites/test_toolchain.nim`.
- The rule on dead exports reads the modules and suites of knoller too. Verified by
  `suites/test_checker.nim`.

## Fixes

**`koch fix` rewrites in place each finding that has one mechanical fix, and nothing else.** It is
built from the checks. Each fixer sits beside its check. A fixer that reads the text of one file
sits in knoller, and one that reads more sits in `names.nim`, `conversions.nim` or `checker.nim`.
Each reads the same spans, runs, predicates and constants. So each rule is written once (Article
II.1), and a fixer cannot drift from the check that names its finding.

Each rewrite prints as `path:line: <rule> fixed`, at the line that the check names, and the run
ends with the count. With the layout rules below, `koch fix` replaces nimpretty.

**`nim r koch fix --dry-run` prints each change and writes no file.** Each change prints as
`path:line: <rule> to fix`, then the count. The run exits 1 where any change would apply, and 0
where none would. The Architect asked for a formatter that works like black, with a dry run that
only reports. A fix report names its rule alone, so one report serves both runs.

- Verified by hand, 2026-10-02: `koch fix --dry-run curator koch.nim` printed 739 changes,
  exited 1, and left `git status` clean. The real run then wrote the same 739 changes, and a dry
  run after it printed `0 to fix.` and exited 0.

**The lines between a line `#!fix off` and a line `#!fix on` stay as written (X.1).** Each
marker is a comment alone on its line, and a fence left open runs to the end of the file. No
fixer writes a fenced line, and no layout check reports one. While the fixers run, each fenced
line reads as one comment at its own indent. So a call, a signature or a list that holds a fence
reads as one that holds a comment, and stays as written.

- A fixer whose rewrite would move, indent, split or merge fenced lines is skipped for that file.
  Its finding stays for the hand.
- A fence that closes outside the bracket, string or comment it opens in leaves the whole file
  as written. `koch fix` prints it with its line, and `checkFormatting` reports it alone.
- `koch fix` prints a warning for each fence that it reads, with the lines that the fence keeps.
  So no held line goes unseen. A warning changes no exit code.
- Rejected: each fixer told of the fence, and each rewrite tested against it. Every fixer would
  carry the fence, and the masking holds it in one place.
- Cost: a skipped fixer is skipped whole for that file, and not for its one rewrite.
- Cost: a line that reads exactly `#!fix fenced` would read back as a fenced line, so a file that
  holds one stays as written.
- Verified by `suites/test_fixes.nim`: fenced rows keep their spaces and their blank line, and
  the call after the fence is fixed. An open fence runs to the end, and a marker inside a string
  fences nothing. A fence across a bracket leaves its file, and a fixer that would indent a fence
  is skipped.

**A nimble file whose copy sits in `atlas.lock` stays as written.** A rewrite would leave the
copy in the lock stale, and Atlas reads that as a change of package. `koch fix` prints each such
file with its reason, and no layout check reads it. The lock names its copy in
`nimbleFile.filename`. On the tree, the nimble files of `pga_benchmark` and `rga_visualiser` are
locked. Verified by `suites/test_fixes.nim`.

**`koch fix` writes Nim files alone.** A fixer applies a style guide, and STYLE.md is the guide
of Nim alone. So `fixSource` runs only on a kind that carries `has_guide`: Nim, NimScript and
nimble. Every other kind passes through unwritten, Markdown, TypeScript, JSON, YAML, cfg and
shell among them. The checks still read every kind, and a finding there stays for a fix by hand.

- Verified by `suites/test_fixes.nim`: a Markdown, TypeScript, JSON, YAML, cfg and shell source
  with trailing whitespace passes through, and its check still reports the whitespace. A Nim and
  a nimble source are fixed. The scope test no longer writes a contributor `README.md`.

**The fixers run in one order, and the chain runs again until the source settles.** First come
the fixers that read more than one file: the renames and conversions of the semantic pass, then
the dead exports. They run once, on the source as given, and their edits move no line. Form runs
next, so later fixers read clean line ends and the final gap of each comment. The entry block
moves after form, because the move shifts lines and widens none.

The content fixers follow, because each changes the width of its line. The idioms run next,
because the bindings fixer indents lines, and every later width reads that indent. The
blank lines, the doc position and the literal defaults follow, because a joined doc and a dropped
type change widths. Spacing runs before wrapping, because the spaces it adds are width that
wrapping measures.

Wrapping runs separators, then signatures, then calls, then trailing separators. A layout joins
groups with the separator it reads, and a trailing separator goes only where no layout wrote one.

- A second round catches what a first round enabled, such as a doc that a widened gap pushed
  past `LINE_MAX`. `ROUNDS_MAX` is three, and the tree settles in two. Knoller runs the rounds
  again where a line stays wide, and holds each line that no wrap fits (`## Wraps` of its record).
- Verified by `suites/test_fixes.nim`: one source that breaks each layout rule settles in one
  run. Every check then reports none of it, and a second run writes nothing.

**Each report names a line of the source as given.** A fixer that inserts or deletes lines records
the input line of each output line. `chain` traces every later report through that record.

**The layout checks are written, and the static pass does not run them yet.** Their fixers run,
because a fixer reports nothing new. So each project clears its findings with
`nim r koch fix contributor/<domain>/<project>` on its own branch, and never by hand. A check
that reddens a project merges only after that project fixes (CURATOR.md, duty 3), so #380
queues the wiring.

**`checkFormatting` of knoller is the one list of checks that the next pull request wires.**
`fixes.nim` reads it by kind. That pull request adds one call to its form for the tree in
`auditTree`. It drops the lenient
banner check of `checkForm`, which `checkBanners` replaces. The list on every kind of Nim syntax:

- `checkComments`, the gap before a trailing comment (X.9);
- `checkBanners`, the blank lines beside a banner (X.2);
- `checkBlanks`, the blank lines beside a suite, a test (X.2) and a nested helper (STYLE.md §1);
- `checkDocs`, the place of a one-line doc (STYLE.md §5);
- `checkDefaults`, a type that a literal default gives (X.12);
- `checkSpacing`, the spaces inside an expression (X.9);
- `checkSeparators`, `checkSignatures`, `checkCalls` and `checkTrailing` (X.3, STYLE.md §5);
- `checkAlignment`, the columns of a comment table (I.4);
- `checkMessages`, the backticks around a value that a message echoes (IV.4);
- `checkMixtures` and `checkNegations`, the parentheses of a condition (X.4);
- `checkTargets`, the subject of a `to<Target>` call (STYLE.md §5).

On `.nim` alone, as the idiom checks read it, the list adds `checkImportBrackets` (X.5),
`checkLists` (X.10) and `checkProfiler` (STYLE.md §3). The move of a late `strictFuncs` needs no
new check, because `checkIdioms` already reports it. `checkNegations` has no fixer, so a project
clears it by hand before the wiring. The check of a type conversion needs the semantic pass. The
static pass cannot run that pass, so `koch fix --dry-run` reports it, and the wiring decides its
place.

**X.9 asks exactly two spaces, by the ruling of the Architect.** An aligned column breaks on a
rename. One longer name moves every comment of the block. So a change of one line rewrites the
whole column, and the history of each line moves with it. Two spaces cost one line of diff for
one line of change.

These findings have a fixer:

- trailing whitespace, and the CR of a CRLF ending with it (VIII.5);
- an ending that is not exactly one newline (VIII.5);
- a gap other than two spaces before a trailing comment (X.9);
- a bracket import out of order, sorted into the slots that its items held, so the layout stays
  (X.5);
- adjacent import lines out of rank, put in order, and stable inside one rank (X.5);
- a run of single bindings, which becomes one keyword over bindings indented two spaces (X.5);
- a missing `strictFuncs`, put where X.6 puts directives: after the header docs and notes, and
  before other code (STYLE.md §2);
- a late `strictFuncs`, moved to that place;
- `return result`, which goes or becomes `return` by its place (STYLE.md §5);
- each layout rule of the next section: separators, signatures, calls, trailing separators,
  import brackets, unordered lists, spaces, blank lines, doc position and literal defaults;
- each rule of `## Content fixes` and `## Semantic pass`.

**The place of `return result` decides its fix.** STYLE.md §5 allows a bare `return` only for an
early exit. So where the line ends a routine that holds `result`, at the own indent of its body,
the line goes. The blank lines that open its paragraph go with it. Inside a branch, or before more
body, the line becomes a bare `return`, which exits with the same value. The fixer reads the place
from the line that opens its block, on the code view.

- A place that reads no one fix keeps its line and its finding. That is the only statement of a
  routine, because the body would go empty. It is also a line with a comment, or a line after a
  comment, because the comment would lose its line or name nothing.
- The end of a template or a macro keeps its line, because there `return` leaves the caller.
- An opener that the scanner cannot name, such as a lambda bound to `let`, keeps its line.

**A finding with more than one reasonable fix has no fixer.** A tab outside a one-line plain
string has no fixer, because its width is a guess. A lone CR is a line break or a stray byte. A
reflow, a wrap or a rename each fixes a long line that holds no call and no operator to break
after. An empty file has no fixer either.

- An import ranked low across lines that are not imports has no fixer, because where it lands is a
  choice.
- A bracket that holds a comment has no fixer, because the comment belongs to an item or to a slot.
- A run whose last binding opens a long string has no fixer, because a new indent changes the
  string.
- A rule that needs a fact the text does not hold has no fixer. That covers the consumer of
  `{.used.}`, the reach of `{.push.}`, a seed and a missing stub header. It also covers debug
  output, a path of one machine and the flags of TypeScript.

**A fix that widens a line past `LINE_MAX` stays only where a wrap fits.** The record of knoller
gives the wideners, the order of the wraps, and the lines that its chain holds (`## Wraps`). Each
fixer of audit keeps the width guard, so a rename or a conversion that would widen a line stays.

**The verb refuses every write outside the scope of the branch.** Each path that a fix would write
goes through `checkScope` of `scope.nim`, for the branch that `--branch`, `BRANCH` or git names. One
path outside refuses the whole run, so a run writes all that it planned or nothing. So a curator
branch never writes contributor code, because `checkPropagation` refuses it. The run prints the
scope findings and exits 1. `main` passes scope as the merge target, so a fix there writes freely.

**The verb reads what every verb that takes projects reads.** It reads named files or directories,
else the projects that `--recent`, `--all` or the change selects. A name that matches no file is a
finding, so a typo never passes as a fix of nothing. A root file such as `koch.nim` is in no
project, so only a name reaches it.

- Rejected: nimpretty. It sets one space before a trailing comment, where X.9 asks two, and a `;`
  between parameters, where STYLE.md §5 asks a `,`.
- Rejected: a fork of the layouter of nimpretty. It is a second formatter, with layout rules that
  drift from the checks.
- Rejected: an AST printer. It loses the place of each comment and every layout that a hand chose.
- The Architect weighed these three and rejected them, because each holds a rule twice: as a
  check, and as a layout.
- Cost: a fix reaches only what a check names, and reading holds every other rule of layout.
- Cost: an aligned column of trailing comments loses its alignment, by the ruling above.
- Cost: a sorted bracket item changes the width of its line by the difference in length.
- Verified by `suites/test_form.nim`, `suites/test_idioms.nim`, `suites/test_blanks.nim`,
  `suites/test_declarations.nim`, `suites/test_wrapping.nim` and `suites/test_fixes.nim`, and by
  the suites of knoller for each fixer that moved there. For each fixer, its output has no
  finding of its check, a second fix changes nothing, and nothing else changes. A clean source
  passes through unchanged. A curator branch that would write contributor code writes nothing.
- Verified by `suites/test_idioms.nim`: `return result` goes at the end of a routine, and becomes
  `return` in a branch and before more body. A wrapped signature reads as one. Each place without
  one fix keeps its line, and a report after a deleted line names the line of the source as given.
- Verified by hand over the whole tree, 2026-10-02, as `## Layout fixes` records.

## Layout fixes

**Each layout rule is a check and a fixer of knoller, and its record is there, under Layout
fixes.** What follows is what `koch fix` showed over the tree.

**Spaces inside an expression take the count of X.9, and the record of knoller holds the rule.**
No fixer of the chain writes a spaced range again. Verified by `suites/test_fixes.nim`: a spaced
source goes through every fixer unwritten, and a split call, a joined call and a wrapped
signature keep each space.

**Two generated data files of `rga_visualiser` hold most of its call findings.** They are
`starfield.nim` and `neighbourhood.nim`, contributor code that a generator writes. They hold
11,583 of its 12,134 call rewrites: 11,252 and 331. A curator branch cannot fence them, because
it never writes contributor code (CURATOR.md, duty 3). So their project fences them, or fixes
them, on its own branch.

**The whole-tree proof: no fix changes what code means.** Verified by hand, 2026-10-02, with a
scratch program over `fixEntries`, `auditTree` and the parser of the compiler. The program fixed
every Nim file of the tree in memory, on branch `main`, so scope refused nothing.

- The fix wrote 173 contributor files, and no curator file. The curator code took the same
  fixes in its own commits. The two locked nimble files stayed as written.
- Reports by rule:
  - calls 12,493, spaces 2,627, trailing comments 1,351;
  - parameter separators 587, test blank lines 502, doc positions 363;
  - signatures 191, unordered lists 142, helper blank lines 48, literal defaults 48;
  - import brackets 19, tuple separators 11, trailing separators 6, banners 2.
- Reports by project: `rga_visualiser` 15,477, `dance_ontology` 2,317, `pga_benchmark` 596.
- Lines added and removed: `rga_visualiser` 98,540 and 27,048, `dance_ontology` 3,315 and 2,246,
  `pga_benchmark` 965 and 841.
- The static pass reported 0 findings before and after. The layout checks reported 18,709
  findings before and 35 after.
- A second fix wrote nothing.
- The parser of the compiler read 131 changed files to the same tree as before. It read the
  other 42 to the same tree once order and dropped types are normalised. That covers merged
  import brackets, sorted lists, and a type that a literal default gives.
- `nim check` read each changed file with the same result before and after, on its own pin and
  config. It passed 142 on the C backend and 6 on the JavaScript backend, and 25 failed both
  times.
- A file that failed lacks a native library or a vendored source, or is a broken prototype.

## Content fixes

**Each content rule that has one right answer has a check and a fixer, from one reading.** The
rules are the I.4 tables, the IV.4 messages, the X.4 conditions, the profiler import and the
`to<Target>` calls. The static pass does not run their checks yet, as with the layout checks. So
a project clears their findings with `koch fix` on its own branch (CURATOR.md, duty 3).

**Every entry module, library umbrella and test stub imports the profiler on one line (STYLE.md
§3).** An entry module holds a `when isMainModule:` block in its code. The umbrella is
`<project>/src/<project>.nim`, and a stub is `tests/test_*.nim`. The fixer joins the form on two
lines. It inserts the line after the last pragma that opens the module, with a blank line on each
side.

- A `when isMainModule:` inside a string is no code, so `test_checker.nim` is no entry module.
- A stub that includes a suite with the import then imports the module twice. The compiler
  accepts that, and `--profiler:on` still runs (verified by hand with 2.2.12, 2026-10-02). The
  Architect accepts the duplicate, so that the fixer stays simple and reads no include.
- Verified by `suites/test_idioms.nim`.

**Four rules that the static pass already holds gain a fixer.**

- A tab inside a one-line string that is neither raw nor long becomes `\t`, which reads as the
  same byte (X.1).
- A lowercase article in a Nim comment goes, outside backticks and quotes, where the next word
  opens a noun phrase (VI.5). So `swap a and b` keeps its `a`, and a capital `A` stays a finding.
- `-r` leaves the `cmd` of a stub, and the lines of `batchable` and `joinable` go (STYLE.md §6).
- A dead export of the checker drops its `*` where its own module calls it. A routine that
  nothing calls stays, because to delete it is a choice.
- An unseeded random in a test keeps a check and no fixer, because the seed is a choice.
- Verified by `suites/test_form.nim`, `suites/test_prose.nim`, `suites/test_idioms.nim` and
  `suites/test_checker.nim`. The tree holds no finding of these four rules.

**An entry block that binds moves into `proc main` (V.10).** The fixer puts the body in
`proc main` above the block, and the block calls `main()`. The routine takes the doc
`TODO: Document.` (VI.1), because only a reader can say what it does. The body keeps its lines
and its indent, since a routine and a block indent a body alike. Each program of the tree of
`main` writes `proc main` at module level too, read by hand on 2026-10-04.

- The fixer reports one rewrite at each binding that the check names.
- A comment that opens its line after the body stays below the block. A comment on the guard line
  and an `else` branch stay with the block.
- A binding of the block that breaks the case of a local takes that case in the same run
  (`## Semantic pass`). Otherwise a second run would rename it.

**The move is refused where a routine would read the body otherwise.** The refusal prints with its
reason, and the finding stays for the hand.

- A guard other than `isMainModule` alone, such as `isMainModule and defined(js)`. A routine at
  module level compiles where that guard fails.
- A `{.global.}`, `{.threadvar.}` or foreign pragma in the body, which binds at module level
  alone.
- An `import`, `include`, `from`, `export`, `method` or `converter` at any depth of the block, or
  an export marker.
- A `quit` with a value at the block's own indent. Its code then belongs in a `main` that returns
  it, through `quit main()`, and that form is a choice.
- Two entry blocks in one module, or a module that names `main` already.
- Rejected: `proc main` inside the block, which V.10 also allows. The block then holds a routine
  and a call, where each program of the tree holds one call.
- Cost: a value that the block binds moves from static storage to the stack. A large array there
  can overflow the stack, and `nim check` never reads that. Inferred from where Nim stores a
  global and a local, and never measured.
- Verified by `suites/test_names.nim` and `suites/test_fixes.nim`. The tree proof is in
  `## Semantic pass`, beside the case rename that runs with it.

**The whole-tree proof of the content fixes: no fix changes what code means.** Verified by hand,
2026-10-03, with the scratch program of `## Layout fixes`, which now asks the semantic pass too.
It fixed every Nim file of the tree on branch `main`, with the checkouts of `koch fetch-deps`.

- The fix wrote 182 contributor files, and no curator file. The curator code took the same
  fixes in its own commits.
- Reports of the content rules by project:
  - `rga_visualiser`: `to<Target>` 474, tables 59, profiler imports 7, conversions 7, messages 3;
  - `dance_ontology`: messages 66, `to<Target>` 61, tables 1, conversion 1;
  - `pga_benchmark`: tables 22, conversions 12, profiler imports 4, `to<Target>` 3.
- The layout rules gave 18,411 more reports, close to the figures of the layout proof.
- Lines added and removed: `rga_visualiser` 99,020 and 27,522, `dance_ontology` 3,431 and
  2,362, `pga_benchmark` 1,013 and 878.
- Findings before and after: tables 100 and 18, messages 72 and 3, profiler imports 11 and 0,
  `to<Target>` 538 and 0, conversions 20 and 0. A table that stays would cross 100 runes.
- The static pass reported 0 findings before and after. A second fix wrote nothing.
- The semantic pass resolved 34 sites, in four of the files, in 8 s.
- The parser of the compiler read 107 changed files to the same tree as before. It read the
  other 75 to the same tree once normalised. To the normalisation of the layout proof, it adds
  four steps. It drops a pair of parentheses and the profiler import, reads `x.f` as `f(x)`, and
  drops backticks in a string.
- `nim check` read each changed file with the same result before and after, on its own pin and
  config. It passed 151 on the C backend and 6 on the JavaScript backend, and 25 failed both
  times.

## Semantic pass

**Two rules ask what a name means, so `koch fix` asks the semantic pass of the compiler.** Text
cannot tell a conversion `x.T` from a field or a module path, such as `rigid3.Point`. Text cannot
find every use of a name across modules either. So `symbols.nim` asks `nimsuggest` of the
toolchain that serves the pin of the project.

- One `nimsuggest --v3 --stdin` serves each entry: the file itself, or the file that includes it.
  It runs in the project directory, so the `nim.cfg` of the project applies.
- A run reads its commands from a file and writes its answers to a file, through the
  redirection of the shell. A pipe holds 64 KiB, and a run whose answers fill it stops reading
  commands. So a run fed through pipes, all commands first, waits forever on a large entry.
  Verified by `suites/test_symbols.nim`, which passes 64 KiB each way.
- `nimsuggest` waits 250 ms between two commands on its input, so each site costs a quarter of a
  second at least. Measured on this container with 2.2.12, 2026-10-04: 300 sites of one small
  file took 76 s, with 0.6 s of processor time.
- Each file is checked first. A file that reports an error on the C backend is asked again on the
  JavaScript backend. A file that fails both stays unresolved, and `koch fix` prints its first
  error.
- A routine that returns a value answers its own declared name with its implicit `result`. So that
  answer reads as the routine declared at the site, where each use of it resolves. Both pins that
  koch serves answer so (verified by hand, 2026-10-03).
- Rejected: the compiler as a library inside koch. Every build of koch would compile the
  compiler. Koch would also bind to one pin, and the `ronri` projects lex glyphs that only their
  commit pin knows.
- Rejected: `nim check --def` for each site, which compiles the project once for each site.
  `nimsuggest` ships with each toolchain that koch serves, so the pass costs no build.
- Cost, measured 2026-10-02 on this container: about 2 s for each entry of a curator module. A
  front-end or a suite of `rga_visualiser` takes 5 to 9 s. Only a file with a candidate asks.
- A site of an included file asks `dus`, whose answer opens on the same definition as `def`.
  Verified by `suites/test_symbols.nim`, which resolves a use of an included file to its `let`.
- On the commit pin, `def` in an included file recompiles the file that includes it for each
  site, and `dus` recompiles only what is dirty. Read in `executeNoHooksV3` of `nimsuggest.nim`
  at that pin. Measured on this container, 2026-10-04, over 20 sites of the shared suite of
  `rga_visualiser` at `c5c65db`: `def` took 345 s and `dus` took 50 s.
- A site of the entry itself keeps `def`, because `dus` lists every use of the symbol. Measured in
  the same run: `dus` gave 182 use lines beside the 20 definitions. That the list grows long for a
  common symbol such as `float` is inferred, and an included file pays that output alone.
- Cost: a file that needs a checkout of `koch fetch-deps`, or a native library, stays unresolved
  without it. A branch of `when` that the defines leave out resolves nothing.
- Verified by `suites/test_symbols.nim`, against the `nimsuggest` of the running compiler.

**A type conversion `x.T` becomes `T(x)` where the pass settles it (STYLE.md §5).** The candidate
is a type-like name glued after a receiver. The name must resolve to a type, and the last name of
the receiver to a value. A parenthesised receiver gives the call its parentheses, and a tuple
keeps its own.

- The edits apply once, before the chain, on the source as given. They move no line, so the fence
  holds, and no edit lands on a fenced line.
- A receiver that is a module the file imports, or a capitalised name, asks nothing. That keeps
  the pass to the few files that hold a candidate.
- The static pass compiles nothing, so it cannot run this check. `koch fix --dry-run` reports it.
- Verified by `suites/test_conversions.nim` and `suites/test_fixes.nim`.

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
- Cost: the scope is the project of the declaring file and the root files.
- Cost: overloads in one file share the qualified name of a parameter. So a named argument to
  another overload is renamed too, and its build then fails.
- Verified by `suites/test_rewrites.nim`, `suites/test_names.nim` and `suites/test_fixes.nim`.

**The rename has its proof on commit `c5c65db` of `main`, because the tree at `de0c1899` holds no
V.6 finding, by `nim r koch check-files`.** Verified by hand, 2026-10-03, with a scratch program
over `abbreviationRenames`, `planRename` and `resolve`. It applied the planned renames alone to a
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

- A local in capitals reports as `local constant case (V.1)`. Every other kind reports its own
  rule, such as `field case (V.1)` or `member case (V.11)`.
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
- Verified by `suites/test_names.nim`, `suites/test_rewrites.nim` and `suites/test_fixes.nim`.

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

**The entry move alone has a second proof, on commit `c4c0d400`, which holds more entry blocks.**
Verified by hand, 2026-10-04, with the same program and the engine of `dance_ontology`. Each entry
block moved, and the parser read each written file to the same tree once its body returns under
its block. `nim check` gave each written file the same result before and after, and a second run
moved nothing.

## Fixed waits

**A fixed wait in drive code is a finding, because it reads the real clock in every
context.** The names are `waitForTimeout` of Playwright, and `sleep` and `sleepAsync` of Nim.
The check reads `tests/` and `tools/` of every project, with no exemption, because a speed
check samples a count and never sleeps (Article IX.12). Each name carries its replacement, as
the English check does. Verified by `suites/test_waits.nim`.

**A timer is unread, because one name is both clocks.** Inside a page under the clock of
Playwright, `setTimeout` and `performance.now` are simulated reads. A check over them would
report every correctness drive of `rga_visualiser`, where each `setTimeout` sits inside
`evaluateOver` or `page.evaluate`. So the check holds the narrow half, and the rule holds the
rest by reading.

- Nim names compare as the compiler compares them, so `sleep_async` is `sleepAsync`. Nim
  source is read with comments and strings blanked, so the suite of the check holds its
  fixtures as strings and reports nothing.
- `sleep` of TypeScript is the drive's own helper. In `rga_visualiser` it wraps `setTimeout`
  inside a page on the simulated clock, so it is unread.
- Verified by hand with `nim r koch check-files` on 2026-10-01: no finding in any project. A
  planted `sleep(10)` in a Nim suite and a planted `waitForTimeout(100)` in a TypeScript drive
  each read as one finding.
- Cost: a drive outside `tests/` and `tools/` is unseen. So is a window built from a page
  timer, and a fixed wait of a language other than Nim and Playwright.

## Hooks on tool calls

**Each hook of `.claude/settings.json` calls `koch hook <event>` and holds no rule of its own.**
The rule stays in the audit, once, and the hook reads the fact of its event and names the check
that holds it. The events, each one a verb argument:

- `path` refuses a write outside the scope of the branch, before the write.
- `edit` runs the static checks after a write, and returns the findings of that file as
  context.
- `bash` refuses a commit or a push on `main` or outside the grammar, and a rewrite of pushed
  history. It holds a post made through `gh api` as `body` holds the post of a tool.
- `body` refuses a post that lacks the role line or the footer, or breaks the three English
  counts. It also refuses an issue titled as a commit, or one with no role label or with the
  label `coordinator`. It refuses a pull request body that leaves the template unfilled.
- `stop` refuses the end of a turn that pushed or posted and closes with neither the sign-off
  nor the working line. It also refuses a sign-off out of shape. At the end of any turn, it
  refuses `#N` outside a link, and an article or a duty cited with no description.
- `start` prints the role, the read order, the carried list and the drift state, at the start
  and after each compaction.

**`path`, `edit` and `bash` read the checkout that the call acts in, and never the primary
checkout alone.** A subagent works in a worktree of its own, on a branch of its own
(`GUIDE.md`, Work for subagents). The checkout of a write is the one that
holds the file. The checkout of a git command is the one that its `-C` or a `cd` before it
names, else the working directory of the call. A directory outside this repository falls
back to the primary checkout.

- A detached head in the primary checkout never decides the branch of a worktree. So it never
  refuses a subagent.
- Verified by hand on 2026-10-02, by fake inputs to the built koch, before and after, with a
  detached checkout as the primary. The scope of the worktree's own branch still refuses a write
  outside it.
- A path is read from the top of its checkout, and never from the working directory of the
  call, which may be a subdirectory.
- Cost: a git command in another repository falls back to the primary checkout. A commit there
  is held to the branch of the primary checkout (#380).
- Cost: only the first git command of a shell line is read. A second one with another `-C`
  is held to the branch of the first.

**`hooks.sh` is the one shell file Claude Code runs, and it exists because no Nim can run
before it.** It reads the pin from the nimble file of this project, so the pin is stated once.
At the start it fetches the release tarball where no `nim` is on `PATH`. It sets
`core.hooksPath` to `.githooks`, and writes PATH to `CLAUDE_ENV_FILE` where that variable
exists. Every hook command runs the koch that it built into `binaries/`, and falls back to
`nim r`.

The tarball is linux_x64, which is what the cloud runner of Claude Code uses. Verified by hand
on 2026-10-01, by a fake input to each event, before any delegate ran under the settings file.

**The built koch is keyed on its source at HEAD, so no hook runs a checker older than the
checkout.** The key is the object ids of `koch.nim`, `koch.nim.cfg`, the nimble file of this
project and `src/` at HEAD, kept in `binaries/koch.key`. A hook whose key differs builds again
first, so a commit, a merge or a switch of branch reaches the next hook. The key reads HEAD and
never the working tree, so an edit in progress builds nothing. The build writes beside the
binary and then renames it. A directory lock lets one build run, while a concurrent hook runs
the binary that it finds.

- Rejected: a key of file times, which builds again after each edit of the checker in the main
  checkout. Half-made code then fails that build on every hook.
- Cost: about five seconds of build where the key moved, and one `git rev-parse` on each hook.
  A lock older than ten minutes is one that a killed build left, and the next hook removes it.
- Cost: a binary built from a tree with uncommitted edits keeps them under the key of HEAD. A
  checker bug that this checkout commits reaches the next hook. Checker work in a worktree
  leaves the hooks of the main checkout as they were.
- Verified by `suites/test_hooks.nim`: the real file runs through real git and `sh`, with a stub
  compiler that names the source it read. By hand on 2026-10-03, a first hook built in 2.3 s,
  and a second ran in 0.016 s.

**The git hooks hold the push and the commit from any tool in the checkout.** `koch check`
writes the tree hash it passed on into `koch-check` in the git directory when the working tree
is clean. `pre-push` refuses a push whose tree differs. The git directory is the one that
`git rev-parse --git-dir` names, so a worktree, whose `.git` is a file, keeps its own mark.

`commit-msg` runs the commit check over the new subject and the ladder before the commit
lands. A merge commit passes it, because git writes that subject and the commit check excludes
merges. Both are two-line shell wrappers that call `hooks.sh`, because git runs a hook as an
executable and a binary is never committed. A clone reads them once the start hook sets
`core.hooksPath`, so any other tool reaches CI unchecked, and CI stays the gate.

The subject that `commit-msg` reads is the first paragraph, its lines joined, because git reads
it so. A finding on an earlier subject stays with `check-commits`, because `--amend` keeps the
old head among the earlier subjects. One earlier finding cancels one same finding, so a bad
subject written again still reports. Under `--amend`, the ladder reads the old head as the
commit before the new one, and `check-commits` reads the true order in CI.

- A hook reaches only Claude Code, and only where it holds this repository alone, because a
  checkout of several repositories reads no project settings.
- Rejected: a hook per rule, which puts the rule in two places. Rejected: `nim r` on every
  hook, which recompiles on each source change and costs seconds; the built binary costs
  milliseconds, and `nim r` stays as the fallback.
- Each hook command names the script through `CLAUDE_PROJECT_DIR`, never by a relative path.
  A hook runs in the working directory of the Bash tool, which moves with each `cd`. A
  relative path then fails to open, and every hooked tool is refused.
- The shape rules of the sign-off, the body and the bash refusals are pure functions.
  Verified by `suites/test_hooks.nim`.

## Hooks on messages

**`body` and `stop` hold what a delegate writes for a person: each post, and the message that
ends a turn.** Section Hooks on tool calls gives the mechanism that both share. The `stop` hook
passes once `stop_hook_active` is set, so a blocked turn cannot loop. It counts a GitHub write
as a post only where the call carried a body, as the `body` hook does. So a label or a draft
update ends no turn with a sign-off.

- Cost: in a project thread, the Architect reads a reply, which is a tool call. `stop` reads
  only the text of the turn, so it holds the shape of a sign-off in that text alone. Reading
  holds the shape of the reply, as it does outside Claude Code. Verified by hand through the
  built hook, 2026-10-03: a valid sign-off sent only as a reply leaves the turn blocked, with
  `got none`. The same block as text passes.

**`bash` holds a post made through `gh api` as `body` holds the post of a tool.** A delegate
posts through `gh api` in Bash as well as through the GitHub tools, and one rule binds both.
The hook reads the endpoint, the method, and the fields `body`, `title` and `labels[]` of each
`gh api` command. It maps each write to the tool whose rules it shares, so `checkBody`
applies unchanged. A write with no body is no post, as it is for a tool. `stop` counts a post
through `gh api` as it counts the call of a tool.

- The hook runs before the command, so the body must be readable before the post lands. It is
  inline text, a file that `-F body=@PATH` names, or the JSON of `--input`. A body from a shell
  variable or stdin is refused, and the finding asks for a literal path.
- Cost: a post of a body that the same command writes, as by a heredoc, is refused. The file
  does not exist yet, so the finding asks for it in an earlier call. That post takes two calls.
- The words split as the shell splits them. Quotes are honoured, and the text of a heredoc is
  skipped. A file resolves against the directory of the call, moved by each `cd` before it.
- An edit of a review comment takes the rules of a reply, because both are review comments.
- The role line reads the branch of the primary checkout, as `body` does, and not the checkout
  of the call. A subagent never posts, so each post speaks for the delegate.
- Cost: a mutation through `gh api graphql` reads as no post, so reading holds its body.
- Cost: `stop` reads no file, so an `--input` file counts as a body where its JSON holds none.
- Verified by `suites/test_hooks.nim`: each endpoint of the map, each source of a body, and each
  body that the hook cannot read. Real files are read, refused and mended.
- Verified by hand through koch built from the branch, 2026-10-04. A body file with a sentence
  of 27 words is refused, and the mended file passes.

**`coordinator` is a role string that no branch names.** `isRoleString` accepts it, so a
sign-off row or a decision class may name the coordinator as the role that acts. A hook
compares a role line with the branch only where the branch is in the grammar, and the
coordinator holds no branch. An issue that carries the label `coordinator` is refused. A brief
carries the label of the role that it starts, and no item is the work of the coordinator.
Verified by `suites/test_hooks.nim`.

**The sign-off follows the order that the Architect set, and `stop` holds that order.** The
Architect reads the block first: who the delegate is and what it works on, then what happened.
Where it stands and what waits on them come last (`GUIDE.md`, The sign-off). Each decision reads as
a decision card, and its class says what blocks. Each ⚠️ row names the role that it waits on.
The coordinator, once the Architect trials it, lifts each decision onto a card without a change
of words.

The block carries seven labels in order: `Role`, `Context`, the table, `Summary`, `State`,
`Decisions` and `Next step`. The Architect set this order on 2026-10-04. The table ends where
`Summary` starts. Verified by `suites/test_hooks.nim`, which refuses a table before the context
and a state before the summary.

- The state opens with `done`, `waiting` or `blocked`. The check reads that word alone, up to
  the first comma or space. Where the branch stands follows it, and only the `english` check
  reads it. Verified by hand through the built hook, 2026-10-03: a state line over 25 words
  gives an `english` finding. The state is `blocked` exactly when a decision blocks this
  delegate.
- The block holds no brief line, by the choice of the Architect: no delegate starts from a
  brief until the Architect trials the coordinator. No check refuses a line beyond the seven
  labels, so reading holds this rule. Verified by hand through the built hook, 2026-10-03: a
  sign-off with a brief line passes.
- Decisions are numbered from `D1`, and each one names its class and where its ruling goes. With
  no decision, the label reads `**Decisions:** None.`, and over its blocks it stands alone.
- A class is `blocks this delegate`, that class with `and` and the role strings that wait too,
  `has a workaround:` with the workaround, or `fact`.
- A `fact` offers no option and picks none. Every other decision asks a question that ends with
  `?`. It offers two to four options, each with a label of at most three words, and recommends
  one by its letter. Four is what a decision card holds.
- A ⚠️ row opens its last cell with a role string or `outside`. A ⏸️ row names a decision that
  the block holds, as `D1`.
- Rejected: a fenced block of YAML. It renders as no table on GitHub, and the `english` check
  skips fenced text, so its prose would go unchecked.
- Cost: the check reads shape, and never whether a decision says anything, or whether an option
  is honest.
- Cost: `stop` cannot tell the coordinator, which holds no branch, from a delegate. Where it
  runs for the coordinator, whose message is the digest, a turn that posted is asked once for a
  sign-off. The second stop passes.
- Verified by `suites/test_hooks.nim`: one assertion for each rule above that a check holds,
  and two for the order. The fixtures are the example in `GUIDE.md`, cut short, and a sign-off
  with no decision.

**A delegate signs off only when it stops, and a turn that ends while work goes on closes with
a working line.** The Architect set this rule on 2026-10-04. A sign-off marks a stop, so one in
the middle of work hides which delegates need the Architect. So each state word is a stop:
`done`, `waiting` or `blocked`. A turn that pushed or posted closes with the sign-off, or with a
last line that opens `**Working:**` and holds text. `stop` reads the sign-off in full where its
heading is present, and else the last line.

- Verified by `suites/test_hooks.nim`. It refuses a working line with no text, a working line
  that is not last, and the state `working`. Its refusal of `working` points at the line.
- Rejected, by the choice of the Architect: the hook skips the demand while a background task
  has not reported. That ties the hook to the form of a task notification, which the harness
  can change.
- Rejected, by the same choice: no demand, with the shape read only where a sign-off is
  present. Then a delegate can stop with no word to the Architect.
- Cost: the hook reads that the working line holds text, and never whether anything runs. A
  delegate that stops behind a working line passes, and only a reader sees it.
- Cost: `stop` reads a turn that pushed or posted, and no other. A turn that reaches its stop
  by a change of label or draft alone is not asked for a sign-off.

**`stop` names each `#N` of the closing message that stands outside a link and outside code.**
Each issue and pull request goes by a short description and its number, as one link (`GUIDE.md`,
Output contract). The Architect ruled this check on 2026-10-04. It reads every turn, and not only
a turn that pushed or posted, because the rule binds every message. Each number reports once.

- A link is `[text](url)`, `[text][label]`, or `[label]` with a definition in the message. A
  definition line is a link too. A bracket with no definition is text, as GitHub shows it.
- Fenced code and code spans are skipped. A code span closes at the next run of backticks of the
  same length, as CommonMark reads it.
- A `#` after a word character, `&` or `/` opens no number. So `&#169;` and a fragment of a URL
  pass.
- Cost: `owner/repo#12` passes too, though it names an item of another repository bare.
- Cost: the hook reads the closing message of a turn alone, and no earlier message of the turn.
- Verified by `suites/test_hooks.nim`: three kinds of link, code, an undefined bracket, a
  reference, a fragment, and a number named twice.
- Verified by hand through the hook built from the branch, 2026-10-04. Of three closing messages
  of the curator, one named `#463` outside a link, and the hook refused that one alone.

**`stop` names each article and duty of the closing message that has no description beside it.**
A reference is `X.9`, after `Article` or not, or `duty 3`. It passes inside parentheses after a
word with a letter, on one line, because each example of the rule (`GUIDE.md`, Output contract)
has that form. So `(X.2, X.9)` after text passes whole, and a line or a bullet that opens with
`(` fails. It skips code and links as the check of `#N` does, and reports each reference once.

- A reference is a whole token, so `2.2.12`, `D2`, `§5`, `MIX.3` and `IX.2.1` cite none.
- Cost: a message wrapped by hand that puts the parenthesis at the head of a line fails there.
- Verified by `suites/test_hooks.nim`, where each passing form stands beside a bare reference.
  Verified by hand through the hook built from the branch, 2026-10-04.

## Watching main

**A red `main` opens its own issue, because a duty to remember to look fails in silence.**
`watch.yml` reads each finished run of `check`, `ledger` and `head` on `main`. It opens an issue
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

A workflow may hand `gh` a token other than the run token, a stored secret or one minted in a
step. That token reaches by its own grant, which no block sets, so the `gh` marks are skipped
and a checkout still wants `contents`. The `draft` workflow is the case: GitHub refuses
`convertPullRequestToDraft` to the token of a run and to a fine-grained token, so a classic
token converts. The marks are text here too: `GH_TOKEN: ${{` and the two spellings of the run
token.

**The weekly window is named twice, as the cron of `check.yml` and as `RECENT_DAYS`.** So a
workflow that passes `--recent` runs on a cron whose interval is that constant. The interval is
read for two shapes alone, one weekday and every day. Any other shape reads as zero and fails, so
a new shape is taught to `cronDays` first.

- Verified by `suites/test_workflows.nim`. Verified by a break of it: delete `actions: read` from
  `watch.yml`, and `koch check-files` reports it by name and by what was granted. Restore it, and 0
  findings return.
- Verified on the runner, 2026-09-09, against real red runs rather than a manufactured one.
  Dispatched at a red run of `main`, it opened one issue that named the run and each job that
  concluded failure. Dispatched at a second red run, it commented on that issue rather than
  opened another.
- In the same check, runs on green `check` completions concluded `skipped`, which is the guard
  working on green.

## Continuous integration

**`check.yml` runs a fixed set of jobs, and a gate stands for the ones whose names vary.**
Each job carries the name of the koch verb that it runs, so a red job names the command to run
locally.

`list-projects` emits the matrices, and `check-files` runs the static pass. `test` is one matrix
job for each listed project, on its own pin. `drive` is a second matrix over the subset that
carries that verb, and `check-types` is one plain job on the compiler of koch. `check-scope`,
`check-commits` and `check-drift` run only on pull requests, with full history. `summarize` is a
gate that reads the rest.

The gate exists because matrix job names vary with the change, and can never be required
checks. The required checks are `summarize`, `check-scope`, `check-commits` and `check-role`
(CURATOR.md, "Repository settings the Architect applies"). Every job added to `check.yml` is
named in the `needs` of the gate, or it is a required check by name. `check-scope` and
`check-commits` take the second way. A job that is
neither is a red check that cannot block a merge. That
mistake is easy to make and impossible to see afterwards.

- Cost: a rename of a required check makes the Architect reconfigure branch protection in the
  same step. The names follow the verbs anyway, because a job named after its verb tells a
  newcomer what to run. Rejected: a computation of the matrix in shell, which is untested glue
  where koch is tested.
- Branch names and the event kind reach koch through the environment, and are never
  interpolated into the script. Nim installs under the temp directory of the runner, and never
  the workspace, and `.gitignore` lists `.nim_runtime/`.
- Rejected: a toolchain inside the checkout. The audit reads untracked files, so it reads that
  toolchain as source, with a finding on each file that breaks a rule.
- `check.yml` declares `permissions: contents: read`, because checkout is the only use of the
  token and nothing in it writes. The caches take their own runtime token, and no step calls
  `gh`. Cost: a step that later reaches the API needs its scope named, which `workflows.nim`
  reports for the steps that it can read. Verified on the runner, 2026-09-24, for every job
  but `test` and `drive`. A change that touched no project code skipped those two, so the grant
  is unverified for them.
- Verified on the runner, recorded 2026-09-08: a record-only change emits `[]`, `test` is
  skipped, and the gate passes on a skipped dependency. The gate passes on `skipped`, and fails
  on `failure` or `cancelled`.

**`nim r koch test --all` runs every project, each on its own compiler.** Every verb that takes
projects reads the one named, else `--recent`, else `--all`, else what a change touches. So one
rule serves `test`, `drive`, `head`, `fix`, `check-types`, `fetch-deps` and `list-projects`.
`check` stays scoped to what a change touches. Cost: to check everything locally is two
commands, `check-files` and `test --all`, rather than one.

- Rejected: one verb for the static pass and every suite on the compiler that `PATH` holds. It
  fails whenever the pins differ.

**`nim r koch check` is the local form of the jobs.** It fetches `origin/main`. It then runs the
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
- **Missing suite**: a check module without `tests/suites/test_<module>.nim`.
- **Verb mismatch**: one set named three times. The names are the verbs that koch dispatches,
  the verbs that its usage lists, and the rows of the checks table in CURATOR.md. Usage lists
  one verb to a line under `Verbs:`, verb first, so the read takes the first word of each
  indented line.
- Verbs are read from the command dispatch alone, bounded between `case options.command` and
  its `else`. The option parser cases over labels a few lines above. Without that bound,
  `root`, `all`, `branch` and `recent` would read as verbs. Cost: only the first label of a
  branch counts, so a second label on the same line is a verb that no rule sees.
- **Option mismatch**: one set named twice. The names are the options that koch parses, and the
  `--` options that its usage text prints. Options are read from the one-line branches under
  `case key`, and the read stops at the first line that is not a branch. Usage is read from
  its mark to the close of the string, so header prose that names an option is not usage.
  Cost: a branch of the option parser that spans two lines hides the option under it.
- **Stale mention**: `koch <verb>` written as a command, where koch dispatches no such verb.
  A command is `nim r koch <verb>`, `./koch <verb>`, or a code span that opens with
  `koch <verb>`, so prose that names koch itself passes. Contributor code is not read,
  because a curator cannot write it, and its records are. A rename of a verb is complete when
  the static pass is clean.
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
- Verified by `suites/test_checker.nim`, and driven. A routine added and never called is one finding
  that names it, and so is one that only its own module calls. One that a suite alone names is
  not a finding.
- Verified by `suites/test_checker.nim` for the three statements of the verb set. A row deleted
  from the checks table is one finding that names the missing verb. A verb dropped from the
  usage list is one finding that names what usage lists. An option parsed and not printed, or
  printed and not parsed, is one finding on `koch.nim`. A mention of a verb that koch does not
  dispatch is one finding at its line, in each of the three command forms.

**No copy of the module graph is written.** The `import` line of each module is the graph, and
a hand-written copy drifts from it. So `audit.nim` names no module order.

## Figures

The machine for these figures is a four-core Intel Xeon 2.10 GHz container, on Nim 2.2.12,
2026-09-24, timed with `date +%s.%N`. Warm means that koch and the test binaries were already
compiled. Each "before" figure is `origin/main` at `8a05673`, on the same machine and date.

**The static pass costs about four seconds.** `nim r koch check-files`, warm, at `de0c189` on
2026-10-04, on the same machine: a median of 3.80 s over ten consecutive runs, from 3.69 s to
3.94 s. The dead-export rule became one pass at 2026-09-24. That pass then took 1.11 s, 1.15 s
and 0.98 s, against 1.97 s, 1.96 s and 1.82 s before. Inside koch, the old dead-export rule took
1.1 s of a 2.07 s pass, because it scanned every source once for each export.

**A branch that changes the checker costs one project, and not every project.** Warm,
`nim r koch check` takes 5.07 s, 5.07 s and 4.99 s over three consecutive runs. With the suite
build of `curator/audit` removed first, it took 8.1 s. Before, with one comment added to a
check module, it took 32.9 s and 32.6 s warm, and 49.2 s cold. `koch list-projects` holds one
row on such a branch, so the figure covers the suites of `curator/audit` and the static pass.

**The suites of `curator/audit` cost their compile, and almost nothing to run.** Each suite
compiled alone in 0.8 s to 1.2 s warm, and the run of every suite binary took 2.1 s. Joined,
`nim r koch test curator/audit` takes 3.8 s to 4.2 s warm, against 31.9 s before.

These two are the pair for scoping. A change to records alone costs the static pass, and a
change to one project adds the suites of that project. An unscoped run pays every project.
On the same machine and date, `nim r koch test <project>` took 627.5 s for `dance_ontology`
and 236.6 s for `rga_visualiser`. It took 18.2 s cold for `pga_benchmark`, and 2.8 s for
`curator/probe`.

**Matrix jobs run in parallel.** Verified on the runner, 2026-09-06: three `test` jobs
started within one second, and finished at 16 s, 52 s and 121 s. So the phase took 121 s
rather than the 189 s of their sum. The saving is the sum minus the slowest, so it grows as
projects arrive.

Cost from the same run: matrix jobs cannot start until `list-projects` reports. That puts 16 s
between the start of the run and the first `test` job. That is a floor on every run, and the
price of a matrix computed in tested Nim rather than in shell.

**What the driven check costs, and where it goes.** Locally, `koch drive` on `rga_visualiser`
takes 2 m 36 s warm, and 3 m 31 s on a tree whose `build/` was removed (2026-09-07). About two
thirds of that is the deliberate wall-clock windows of the harness, which a faster machine does
not shorten. On the runner the job is 5 m 31 s on the same checks, recorded 2026-09-08. The gap
is apt install, a restore of a 2.4 GB compiler from cache, and a slower core.

A figure from one machine predicts the figure of another only where what differs has been
measured.

| Step of the `drive` job | Wall |
|--------------------------|------|
| read the declaration and `apt-get install` | 1 m 47 s |
| `nim r koch drive` | 3 m 04 s |
| restore the commit-pinned compiler from cache | 28 s |

The install is 32% of the job. It is also an upper bound on what a `koch list-packages` asked for
each verb could save. The same step compiles koch and runs the verb of the project. So
`list-packages` stays for each project.

## Runner caches

**The compiler is the cache that matters on the `drive` job.** The job restores the store of
npm, the Atlas checkouts, the commit-pinned compiler, and the faces. To restore the compiler is
seconds, where a build from source is fifteen minutes. Every other cache is noise beside it:
`npm ci` runs in 2 s cached, and the faces of one project take 1.5 s uncached. Measured on the
runner, recorded 2026-09-07.

- Unmeasured: npm cold on the runner, which needs a key poisoned on purpose. That figure is not
  owed.
- The Atlas cache sits at the folder that `atlas.config` names, else at `deps`, the default of
  Atlas. The step before the cache reads that folder, so the cache restores where Atlas
  restores. Verified by hand on 2026-10-02, by the step run under `bash -e` for each project.

**The install directory of SDL3 is cached, and its build tree is not.** No package carries
SDL3, so `sdl3` clones, configures and builds it from source. That is 55.8 s of a 357 s
`drive` job, the largest step that nothing else caches (runner, recorded 2026-09-10).

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
  rather than a warning about an absent path. Unverified on the runner until a `drive` job
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
most about 16 s of a 357 s `drive` job. The steps that dominate such a job are the ones it
cannot serve. Measured from one `drive` job on the runner, recorded 2026-09-10. The figures
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
- Whether the cache of the store restores on a `drive` run. The key `assets-<os>-…` saved an
  entry on the runner, 2026-09-12, and no run is recorded that restored one.
- Whether `watch.yml` fires from a `main` run that went red on its own. Each recorded firing
  was dispatched at a run already known to be red. So the reading and the reporting are proven,
  and the selection of the trigger is not. A red `main` is not worth causing to prove it.
- Whether the fields of `update_pull_request` other than `draft` take REST or GraphQL. No call
  has isolated one.
- Whether `koch fix` with no name reads the changed files rather than the changed projects. Every
  verb that takes projects reads projects, so a run can rewrite a file that the branch did not
  touch (Precedence 2).
- Whether a rename should read the uses of its declaration through `dus`, as a second answer for
  each site. The usage list of `WINDING` in `mesh.nim` at `c5c65db` holds the site that `def`
  answers with `items`. So a rename that an implicit call refuses could be planned, at one more
  command for each rename.
- Whether the `test` job of `curator/audit` should restore the store, as the `drive` job does.
  Without it, each run fetches 5.7 MB of faces before the suite holds the rows to their bytes.
