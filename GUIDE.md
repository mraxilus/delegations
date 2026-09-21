# Guide

How-to for every delegate, curator or contributor. Nothing here binds on its own. What binds
is in `CONSTITUTION.md`, `STYLE.md` and `CONTRIBUTOR.md`, which the stamp covers, and in
`CURATOR.md`. This file is stamped into nothing, so a change of wording here re-audits no
project. That is why it is a file of its own.

## Simplified Technical English

Every word you write for a person follows ASD-STE100, the Simplified Technical English
specification. Issue 9 holds 53 writing rules and about 900 approved words. ASD gives the
specification away, so ask for a copy at `asd-ste100.org` and read it. The rules below are
the working subset. They bind Markdown, issues, pull requests, comments and messages. They
leave a comment in code alone, which drops its articles and keeps the rest (Article VI.5).

- **Use the approved word.** Write `start` and not `commence`, `do` and not `perform`,
  `make sure` and not `ensure`, `about` and not `approximately`, `use` and not `utilise`.
  The dictionary belongs to ASD, so no check holds all of it. The `english` check holds a
  short table of the words that turned up here, and your reading holds the rest.
- **Give each word one meaning.** Use the same word for the same thing every time. A
  synonym written for variety reads as a new term. A word that names a thing does not also
  name an action.
- **Take the glossary's word first.** Where `GLOSSARY.md` gives a word, that word wins over
  any other, approved or not.
- **Write in the active voice.** "The check reads the tree" beats "the tree is read by the
  check". The passive voice hides who acts, and then the reader must guess.
- **Use the simple tenses.** Write "the run failed" and not "the run has failed".
- **Write one instruction in one sentence.** Keep an instruction to 20 words. Keep a
  description to 25.
- **Keep a paragraph to 6 sentences.** Open it with the sentence that says the topic.
- **Put the condition before the instruction.** Write "If the run is red, read the log
  first".
- **Leave out the -ing form.** Write "How to read the queue" and not "Reading the queue". A
  technical name keeps the form it has.
- **Keep a noun cluster to 3 words.** Break a longer one apart with "of" and "for".
- **Write the articles.** A comment drops "a", "an" and "the". Prose keeps them, and a
  record written without them is wrong in the other direction.
- **Keep the punctuation simple.** The full stop and the comma carry almost everything.
  Leave out the dash and the slash. A colon may open a list. Brackets hold a reference, such
  as (Article VI.5), and little else.
- **Write an abbreviation out.** Write `for example` and not `e.g.`, and `that is` and not
  `i.e.`. Name the thing you mean rather than close a list with `etc.`.
- **Set a list out vertically** where it holds more than two items, or where each item is a
  step.

The `english` check reads three things: sentence length, paragraph length and that short
table of words. It reads the charter, the two prompts, this file, the root `README.md` and
the four templates, and no other file. Every other rule above holds because you read it.

## The queue and the shared allowance

Every delegate posts as one GitHub account. One hourly allowance covers every delegate that
runs at once, and it has run out in the middle of work. GitHub meters two APIs separately,
and the name of a tool does not say which one a call takes. The measurement is in
`curator/audit/PROVENANCE.md`. What follows from it:

- **Ask git first.** Git answers whether a pull request merged, what a change touched,
  whether your branch is behind, and what the stamp is. Run `git fetch origin main`, then
  `git log`, `git diff --stat` and `grep`. None of it costs the allowance. Reach for the API
  only for what lives on GitHub alone: issue state, a comment, a label, a run's conclusion.
- **Read the queue once, and small.** Ask for five to ten items per page. Name only the
  fields you will read. Never read a list again that you already hold.
- **A refusal on one call says nothing about another.** Try the call you need before you
  decide that GitHub is shut.
- **On a refusal, wait and try again. Never hammer.** Where it will not clear before you
  hand over, the item stays unticked on the carried list, with its reason.
- **Wait by backoff, never by drumbeat.** This holds for a run to finish, a pull request to
  merge, and an answer to arrive. Look once after thirty seconds. Then double the wait each
  time: a minute, two, four, on through the hours and the days. Stop the doubling at a week,
  which is the cap. Fifteen waits reach it, and they span eleven days.
- **Anything that moves starts the doubling again**, because what you waited on has changed.
  A fixed short interval is the failure that the backoff replaces. A run takes minutes, so a
  look every thirty seconds spends the shared allowance many times and learns nothing. A run
  ends inside the first few waits. The long waits are for a merge and a reply, which wait on
  a person, and the cap is for them.
- **Never hold a conversation open only to poll.** Where the answer will not arrive before
  you hand over, say what you waited on and leave it. A conversation held open spends its own
  run as well.
- **Nothing found is not the same as not yet.** A run appears within seconds of a push, and a
  pull request exists from the moment somebody opens it. So an empty answer on the second
  look is a fault in the question, and not progress to wait out. These filters are exact: a
  commit hash abbreviated where forty characters are wanted matches nothing, however long you
  wait. Read what you asked before you double again, because a backoff hides a wrong question
  where a drumbeat would show it.

## Toolchain

Every project pins its compiler exactly (`CONTRIBUTOR.md`, Toolchain). What follows is how a
pin is served, installed and moved.

- **You do not have to install it.** Koch resolves each pin. It takes the compiler on `PATH`
  where that one already serves, else one cached under `~/.cache/koch/nim/<pin>/`, else a
  fetch. A release arrives as a checksummed tarball in seconds. A commit is cloned from
  `nim-lang/Nim` and built in minutes. Either fetch is paid once for each pin.
- **One toolchain serves the whole run.** `$KOCH_NIM_DIR` moves the cache. Testament and
  Atlas come from the toolchain that serves the pin, and its `bin/` leads `PATH`. So a lock
  is never replayed against another compiler. That is why `koch ci` and `koch tests` stay
  green as one command over projects that pin different compilers.
- **A pin that nothing can serve is a finding.** It names the pin and the cache that was
  tried. The network may be unreachable, or the version may not exist. Neither is a reason to
  fall back to another compiler in silence.
- **You may install it yourself, and skip the fetch.** Put a matching `bin/` on `PATH`, or a
  toolchain at `~/.cache/koch/nim/<pin>/`. `nim --version` prints `git hash:`, which a commit
  pin is compared against.
- **A bump of the pin is your work.** Run the suites on the new version. Move the line.
  Record in `PROVENANCE.md` what moved and why.
- **CI installs your pin for your project alone**, in its own job. No project is held to the
  compiler of another.

## How to add a dependency

Use Atlas, once for each project, inside your project directory.

1. Run `atlas init` once. It writes `deps/atlas.config`. Move that file to the project root
   so that it is committed. `deps/` never is.
2. Run `atlas use <package>`. It clones into `deps/`, appends `requires "<package>"` to your
   nimble file, and writes `--path` lines into `nim.cfg` between marker comments.
3. Run `atlas pin`. It writes `atlas.lock` with exact commits. The audit demands this file
   whenever the nimble file requires a package.
4. Commit `<project>.nimble`, `atlas.config`, `atlas.lock` and `nim.cfg`. Justify the import
   in the module header that uses it (Article II.8). Record the origin, the commit and the
   licence in `PROVENANCE.md` (Article XI.3).

`nim r koch deps` restores the checkouts of every project from its lock, and `koch tests`
restores before it runs. The lock stores a copy of your nimble file, and `atlas rep` writes
that copy back. So a requirement edited without a regenerated lock is reverted, and the
static pass reports the difference before that happens. Atlas needs the network for every
command, so a project with no packages carries no lock and skips this step.

## How to build on a project

Every later delegate:

1. Read `PROVENANCE.md` in full, then `GLOSSARY.md`, then the code. Take the code in the
   order that the bootstrap diagram of the umbrella module gives.
2. `nim r koch tests contributor/<domain>/<project>` must be green before you start.
3. `Rules stamp stale` means that the governing documents changed after the last audit of
   this project. The curator re-audits every project in the same pull request as a rules
   change, so this appears only where your branch is older than one. Merge `origin/main` and
   read the diff of `CONSTITUTION.md`, `STYLE.md` and `CONTRIBUTOR.md`. Re-audit the project
   against each changed rule and fix what it asks. Then paste the new stamp in a `docs`
   commit of its own.
4. Work in small commits. Update `PROVENANCE.md` in the same delivery as each design change,
   and prune what the change replaced.

## Glossary process

`GLOSSARY.md` follows the `CONTEXT.md` format of Matt Pocock, and his domain-modelling
discipline, renamed for this repository. It is the ubiquitous language of the project: the
words that the Architect, the code and every later delegate share. The words of the
repository itself are in the top-level `GLOSSARY.md`. Use those, and define here only what is
specific to this project. The format:

```md
# <project>

<One or two sentences on what this project is and why it exists.>

## Language

**Term**:
<One or two sentences: what the thing IS, not what it does.>
_Avoid_: <rejected synonyms, comma separated>
```

Rules of the file:

- Be opinionated. Where several words exist for one concept, pick one and list the others
  under `_Avoid_`.
- Keep a definition tight: one or two sentences, which say what the thing is.
- Hold only the terms specific to this project. A general programming concept does not
  belong, however often the code uses it.
- Group terms under subheadings where a natural cluster appears. A flat list is fine
  otherwise.
- Write a glossary and nothing else. No implementation detail, no specification, no scratch
  note, and no history of what was removed.

Five moves throughout the work, and not at its end:

1. **Challenge against the glossary.** Where the Architect or the code uses a term that
   conflicts with an entry, say so at once and ask which meaning holds.
2. **Sharpen fuzzy language.** Where a term is vague or carries two meanings, propose one
   precise term for it.
3. **Discuss concrete scenarios.** Test the relations between concepts against specific edge
   cases, until the boundaries are exact.
4. **Cross-reference with the code.** Where a statement about behaviour disagrees with the
   code, show the contradiction rather than choose in silence.
5. **Propose the term. Never write it on sight.** Set out the concept, offer candidate names
   with what each one would displace, and stop. Only the name that the Architect selects is
   written, and only then. The audit checks the shape of a glossary, and never whether its
   words were chosen. This rule holds by the reading of the Architect, and by nothing else.

Where the process of Pocock would write an architecture decision record, this repository
writes the decision into `PROVENANCE.md`, under its subsystem (Article VIII.6). There is no
`docs/adr/`.

## Output contract

From the constitution: return the implementation first. Report only what is material: an
assumption, a choice of representation or staging, or a trade-off that is not obvious. Report
a question left open, and the verification you did, which is what ran and on which build.

**Put the URL of a published page in the message itself, and not only in the pull request.**
The same URL belongs in both places. The pull request is the record, and the message is what
gets read first.

**Show the change in that same message.** Give a screenshot where it is visual, and a worked
example where it is not. Where there is nothing to show, give one sentence that says why.
GitHub takes no image from an API, so this message is the only channel that a picture has.

**Write it for a reader who did not watch.** The Architect sees the result, and not the work.
What you tried and discarded, what a run answered, and which file you opened first are all
invisible unless the message carries them. Say what changed, what it cost, what you verified
and how, and what you left undone and why. Do not replay the order you did things in, because
that is what the log is for.

**An Architect who asks is not an Architect who instructs.** A question about the tree is
answered, and that is all: what something does, whether a rule reaches a case, why a check is
red. Read the answer back and stop. The change that the answer implies waits for the words
that ask for it. Where the line is genuinely unclear, say what you would do, and ask before
you do it.

## Provenance guide

Instructions for a delegate who works on a project that keeps a `PROVENANCE.md`. The file
records who made the work, from what, how far it has been checked, and why the design is the
way it is. Whoever picks the project up next reads it, human or model. They rebuild it from
the file and the source, without a repeat of your mistakes.

Header table for `PROVENANCE.md`:

```md
| Field   | Value |
|---------|-------|
| Harness | <tool you run in, e.g. Claude Code> |
| Author  | <model> |
| Date    | <YYYY-MM-DD> |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | <last line of `nim r koch stamp`> |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |
```

One row is optional. `| Pruned | <commit> |` names the commit before the last prune of this
file. The `Pruned` row of that version points further back, so the history is a chain that
`git show <commit>:<path>` follows. The audit checks that the commit touched the file.

### Open it at the start, not at the end

Open the file before you write code. Begin with the header table above. The review line is
the point of the file. Work written by a model must carry its own verification status, and
that line must stay true. Change it only where a human has read something, and say what.

### Record the current design, by subsystem

Organise the body by subsystem, and not by date, under ATX headings (`## Subsystem`). Each
section describes the design as it is now. For every decision that is not obvious, write
three things: what was chosen, what was rejected, and what the choice costs. Keep every
concrete constant with its reasoning, so that nobody has to find out again why a number is
what it is.

Mark what is verified and what is assumed. Say how each one was verified: a test case, a
driven check, a rendered frame that was looked at, or a measurement. That distinction is the
most valuable property of the file. It is what makes the text provenance rather than a design
document.

### Rules that keep it honest

- **Verify by a run.** A claim about behaviour, cost or appearance goes in the file only
  after you ran the code, rendered the output, or read the bytes back.
- **A claim that somebody else can repeat cites the test that repeats it**, written as
  ``Verified by `tfoo.nim` ``. The audit resolves that name against your `tests/` directory,
  and fails where it does not exist. It checks only that the file exists. Whether that test
  makes the claim beside it is read, and never checked.
- **A claim verified in any other way names the tool and the date.** Write "Verified by hand
  in Firefox 141, 2026-09-06" rather than "verified". Nobody can run that again from a
  checkout, and a later reader is entitled to know it before they trust the claim. Prefer to
  turn such a claim into a test.
- **A measurement comes in a pair.** A cost is a before and an after, on a named machine and
  scene, with the method. Where you did not measure, write "unmeasured" rather than repeat an
  earlier figure.
- **A count of files, suites or checks is never written as a number in prose.** A count goes
  stale by the next commit, and nothing here reads it again. Name the command that counts, or
  let a test assert the count.
- **A rejected alternative earns one line, and only where it is still a trap.** "Not
  camera-scaled, which visibly resizes a plane as the camera orbits" belongs. The story of
  how you found that does not.
- **A picture shown and not kept names how to make it again.** A screenshot lives in the
  conversation rather than in the tree, so the record carries the command that took it.
- **Update it in the same delivery as the change**, in a commit of its own, so that the
  record never lags the code.

### Prune, never narrate

The file is not a changelog. Where a design is replaced, rewrite its section to describe the
replacement, and delete the old account. A fixed bug, an abandoned experiment, a superseded
figure and an answered question all come out. `## Open questions` holds only what is still
open, and it is the last section. A rules audit that binds nothing writes nothing but the
`Rules` row, because the log already records that it happened. One that binds rewrites the
sections it binds.

No section is headed by a date. Where the file starts to read as a diary of what happened,
prune it until it reads as a description of what is. A record over 3,000 lines is a finding,
and so is one `##` section over 200. The remedy is that same prune, or a split of the section
into the two subjects it grew into. Git keeps what came out, and the `Pruned` row says where.

### What a good entry looks like

> **The selection menu opens beside the pointer and stays with the object.** A click that
> reveals it puts its corner 8 px from the pointer, as a desktop context menu does. It
> remembers its offset from the anchor of the object, so an orbit carries it along. Rejected:
> a re-glue to the object every frame, which snapped it away from the click one frame later.
> Verified by driven check: a right-click 15 px off a point opens the menu inside the inset.
> A pan moves the menu and the anchor by the same delta.

Name the mechanism, the reason, the rejected path, the cost, and the check. Nothing else.
