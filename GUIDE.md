# Guide

How-to for every delegate, curator or contributor. Nothing here binds on its own: what binds
is in `CONSTITUTION.md`, `STYLE.md` and `CONTRIBUTOR.md`, which the stamp covers, and in
`CURATOR.md`. This file is stamped into nothing, so a wording change here re-audits no
project, which is why it is a file of its own.

## Reading the queue without spending the shared allowance

Every delegate posts as one GitHub account, so one hourly allowance covers every delegate
running at once, and it has run out mid-work. GitHub meters two APIs separately, and a
tool's name does not say which one a call takes; the measurement is in
`curator/audit/PROVENANCE.md`. What follows from it:

- **Ask git first.** Whether a pull request merged, what a change touched, whether your branch
  is behind, what the stamp is: `git fetch origin main`, then `git log`, `git diff --stat`,
  `grep`. None of it costs the allowance. Reach for the API only for what lives on GitHub
  alone: issue state, comments, labels, a run's conclusion.
- **Read the queue once, and small.** Five to ten per page, naming only the fields you will
  read. Never re-read a list you already have.
- **A refusal on one call says nothing about another.** Try the call you need before
  concluding GitHub is shut.
- **On a refusal, wait and retry, never hammer.** If it will not clear before you hand over,
  the item stays unticked on the carried list with its reason.

## Toolchain

Every project pins its compiler exactly (`CONTRIBUTOR.md`, Toolchain). What follows is how
a pin is served, installed and moved.

- **You do not have to install it.** Koch resolves each pin: the compiler on `PATH` when it
  already serves, else one cached under `~/.cache/koch/nim/<pin>/`, else a fetch — a release
  as a checksummed tarball in seconds, a commit by cloning `nim-lang/Nim` and building in
  minutes — paid once per pin. `$KOCH_NIM_DIR` moves the cache. Testament and Atlas come from
  the same toolchain, its `bin/` leading `PATH`, so a lock is never replayed against another
  compiler. This is why `koch ci` and `koch tests` are green as one command across projects
  pinning different compilers.
- A pin nothing can serve, because the network is unreachable or the version does not exist,
  is a finding naming the pin and the cache tried, never a silent fallback to another
  compiler.
- Installing it yourself works and skips the fetch: a matching `bin/` on `PATH`, or a
  toolchain at `~/.cache/koch/nim/<pin>/`. `nim --version` prints `git hash:`, which a commit
  pin is compared against.
- Bumping the pin is your work: run the suites on the new version, move the line, and record
  in `PROVENANCE.md` what moved and why.
- CI installs your pin for your project alone, in its own job. No project is held to
  another's compiler.

## Adding a dependency

Atlas, per project, inside your project directory:

1. `atlas init` once; it writes `deps/atlas.config`. Move that file to the project root so it
   is committed; `deps/` never is.
2. `atlas use <package>`: clones into `deps/`, appends `requires "<package>"` to your nimble
   file and writes `--path` lines into `nim.cfg` between marker comments.
3. `atlas pin`: writes `atlas.lock` with exact commits. The audit demands this file whenever
   the nimble file requires a package.
4. Commit `<project>.nimble`, `atlas.config`, `atlas.lock` and `nim.cfg`. Justify the import
   in the module header that uses it (Article II.8) and record origin, commit and licence in
   `PROVENANCE.md` (Article XI.3).

`nim r koch deps` restores every project's checkouts from its lock, and `koch tests` restores
before it runs. The lock stores a copy of your nimble file and `atlas rep` writes that copy
back, so a requirement edited without regenerating the lock is reverted; the static pass
reports the difference before that happens. Atlas needs the network for every command, so a
project with no packages carries no lock and skips it.

## Building on a project

Every later delegate:

1. Read `PROVENANCE.md` in full, then `GLOSSARY.md`, then the code in the order the umbrella
   module's bootstrap diagram gives.
2. `nim r koch tests contributor/<domain>/<project>` must be green before you start.
3. `Rules stamp stale` means the governing documents changed after the project's last audit.
   The curator re-audits every project in the same pull request as a rules change, so this
   appears only when your branch predates one: merge `origin/main`, read the diff of
   `CONSTITUTION.md`, `STYLE.md` and `CONTRIBUTOR.md`, re-audit the project against each
   changed rule, fix, then paste the new stamp in its own `docs` commit.
4. Work in small commits. Update `PROVENANCE.md` in the same delivery as each design change,
   pruning what the change replaced.

## Glossary process

`GLOSSARY.md` follows Matt Pocock's `CONTEXT.md` format and his domain-modelling discipline,
renamed for this repository. It is the project's ubiquitous language: the words the
Architect, the code and every later delegate share. The repository's own words are in the
top-level `GLOSSARY.md`; use those, and define here only what is specific to this project.
Format:

```md
# <project>

<One or two sentences on what this project is and why it exists.>

## Language

**Term**:
<One or two sentences: what the thing IS, not what it does.>
_Avoid_: <rejected synonyms, comma separated>
```

Rules of the file:

- Be opinionated. When several words exist for one concept, pick one and list the others
  under `_Avoid_`.
- Keep definitions tight: one or two sentences, defining what the thing is.
- Only terms specific to this project. General programming concepts do not belong, however
  often the code uses them.
- Group terms under subheadings when natural clusters emerge; a flat list is fine otherwise.
- A glossary and nothing else: no implementation detail, no specification, no scratch notes,
  no history of what was removed.

Five moves throughout the work, not at its end:

1. **Challenge against the glossary.** When the Architect or the code uses a term that
   conflicts with an entry, say so at once and ask which meaning holds.
2. **Sharpen fuzzy language.** When a term is vague or overloaded, propose a precise
   canonical one.
3. **Discuss concrete scenarios.** Stress-test relationships between concepts with specific
   edge cases until boundaries are exact.
4. **Cross-reference with code.** When a statement about behaviour disagrees with the code,
   surface the contradiction instead of choosing silently.
5. **Propose the term; never write it on sight.** Set out the concept, offer candidate names
   with what each would displace, and stop. Only the name the Architect selects is written,
   and only then. The audit checks a glossary's shape, never whether its words were chosen;
   this rule holds by the Architect's reading, and by nothing else.

Where Pocock's process would write an architecture decision record, this repository writes
the decision into `PROVENANCE.md` under its subsystem (Article VIII.6). There is no
`docs/adr/`.

## Output contract

From the constitution: return the implementation first. Report only material assumptions,
representation and staging choices, non-obvious trade-offs, unresolved questions, and
verification performed, i.e. what ran, on which build. Before answering, silently review the
result against Articles I to XI and the precedence clause.

**Put a published page's URL in the message itself, not only in the pull request.** The same
URL belongs in both places; the pull request is the record, the message is what gets read
first.

**Show the change in that same message.** A screenshot where it is visual, a worked example
where it is not, and a sentence saying why there is nothing to show where there is not.
GitHub takes no image from an API, so this message is the only channel a picture has.

## Provenance guide

Instructions for a delegate working on a project that keeps a `PROVENANCE.md`. The file
records who made the work, from what, how far it has been checked, and why the design is
the way it is. It is read by whoever picks the project up next, human or model, so that
they can rebuild it from the file plus the source without repeating your mistakes.

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

### Create it at the start, not the end

Open the file before writing code. Begin with the header table above. The review line is the
point of the file: AI-authored work must carry its own verification status, and that line
must stay true. Change it only when a human has actually reviewed something, and say what.

### Record the current design, by subsystem

Organise the body by subsystem, not by date, under ATX headings (`## Subsystem`). Each
section describes the design **as it is now**. For every non-obvious decision write three
things: what was chosen, what was rejected, and what the choice costs. Keep every concrete
constant with its reasoning, so nobody has to rediscover why a number is what it is.

Mark what is **verified** and what is **assumed**, and say how each was verified: a test
case, a driven check, a rendered frame that was looked at, a measurement. That distinction
is the file's most valuable property; it is what makes the text provenance rather than a
design document.

### Rules that keep it honest

- **Verify by running.** A claim about behaviour, cost, or appearance goes in the file only
  after you ran the code, rendered the output, or read the bytes back.
- **A claim someone else can repeat cites the test that repeats it**, written as
  ``Verified by `tfoo.nim` ``. The audit resolves that name against your `tests/` directory
  and fails when it does not exist. It checks only that the file exists; whether that test
  makes the claim beside it is read, never checked.
- **A claim verified any other way names the tool and the date.** "Verified by hand in
  Firefox 141, 2026-09-06" rather than "verified": nobody can re-run it from a checkout, and a
  later reader is entitled to know that before trusting it. Prefer turning such a claim into
  a test.
- **Measurements come in pairs.** A cost is a before and an after, on a named machine and
  scene, with the method. If you did not measure, write "unmeasured" rather than repeat an
  earlier figure.
- **A count of files, suites or checks is never written as a number in prose.** Counts go
  stale by the next commit and nothing here re-reads them; name the command that counts
  instead, or let a test assert the count.
- **A rejected alternative earns one line, and only if it is still a trap.** "Not
  camera-scaled, which visibly resizes a plane as the camera orbits" belongs; the story of
  how you found that does not.
- **A picture shown and not kept still names how to remake it.** A screenshot lives in the
  conversation rather than in the tree, so the record carries the command that took it.
- **Update it in the same delivery as the change**, in its own commit, so the record never
  lags the code.

### Prune, never narrate

The file is not a changelog. When a design is replaced, rewrite its section to describe the
replacement and delete the old account. Fixed bugs, abandoned experiments, superseded figures
and answered questions come out; `## Open questions` holds only what is still open, and is
the last section. A rules audit that binds nothing writes nothing but the `Rules` row, since
the log already records that it happened; one that binds rewrites the sections it binds. No
section is headed by a date. If the file starts reading as a diary of what happened, prune it
until it reads as a description of what is.

### What a good entry looks like

> **The selection menu opens beside the pointer and stays with the object.** A click that
> reveals it puts its corner 8 px from the pointer, as a desktop context menu does, and it
> remembers its offset from the object's anchor so orbiting carries it along. Rejected:
> re-gluing it to the object every frame, which snapped it away from the click one frame
> later. Verified by driven check: a right-click 15 px off a point opens the menu within
> the inset, and a pan moves menu and anchor by the same delta.

Name the mechanism, the reason, the rejected path, the cost, and the check. Nothing else.
