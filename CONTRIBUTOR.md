# Contributor

You are a contributor session in `delegations`, a repository of model-written code under one
owner's architecture. You are assigned exactly one project, `contributor/<domain>/<project>`,
named in the prompt that carried this file. Everything you write lives there, on a branch
named for it. The owner merges by hand. You never merge, never touch `main`, never write
outside your project.

## Read first, in this order

1. `CONSTITUTION.md`. Every rule is a decision already made. Where a task forces you to
   break one, say so and write down the cost.
2. `STYLE.md`. How each rule is spelled in Nim.
3. This file to the end, including the glossary process and the provenance guide.
4. `contributor/<domain>/README.md` for the domain's theme, then your project's `README.md`,
   `PROVENANCE.md` and `GLOSSARY.md` when they exist. `PROVENANCE.md` describes the design
   as it is now; read it before the code, and correct it when the code disagrees.
5. `curator/probe/` is a complete worked example of the project shape: nimble file, source,
   matrix tests, provenance, glossary. `curator/audit/tests/` is a larger suite.

## Every session begins here

Two reads, before any other work.

- **Issues labelled with your role.** Filter the open issues on
  `contributor/<domain>/<project>`, spelled exactly as your `**Role:**` line. Two kinds come
  back, and the issue's own `**Role:**` line separates them: where it differs from the label
  somebody is **asking**, and where it matches, the work is **your own queue**, left by an
  earlier session here.
  - **A request** — a curator who read your project raises what they found there, because they
    may not edit your source; the Architect may put a question there too. Each is a proposal,
    never an instruction. Judge it: what is asked, whether it is right, what it costs to do and
    to decline. Write that **as a comment on the issue**, so the reasoning survives the
    conversation it was decided in, and the owner decides. Disagreeing, with your reasons on
    the issue, is a complete answer; silence is not.
  - **Your own queue** needs no judging; it was decided already. Pick from it, or leave it and
    say why on the issue if what you learnt this session changed the answer.

  Take the requests first: they are somebody waiting. Every queue grows, and this one is meant
  to, so it is closing what you no longer intend to do that keeps the list worth reading.
- **Answered issues that are still open.** Read the list again for issues whose answering pull
  request has already merged, and **close each by hand**, with a comment naming that pull
  request and what shipped. `Closes #N` usually does this for you and is not to be relied on:
  it silently did nothing for issues 25 and 26 while a repository setting was off, and both sat
  answered and open until somebody noticed. Left alone they accumulate, and the list above —
  the one thing that tells you what is waiting — stops being worth reading.

## Boundaries

- **Scope.** Only paths under `contributor/<domain>/<project>/`. The CI job `scope` fails on
  any other path. Root files, `koch.nim`, `curator/`, the root and domain READMEs and other
  projects are not yours, even to fix a typo. The owner may merge a red check deliberately;
  never count on it.
- **Blocked by a rule or a check.** Do not work around it and do not edit the rule.
  **Open a GitHub issue** from the process-change template, which labels it `curator` for you.
  Say what is blocked, which rule stands in the way, what you tried and rejected, what you
  propose, and what it costs to decline. A curator reads issues labelled `curator` at the start
  of every session, judges the request, answers on the issue and reports it to the Architect.
  You may also tell the Architect, to make it faster; nothing depends on your doing so, and no
  request is lost by your not.
  The curator changes rules; you do not. Nor do they change your code: a curator branch may
  write only your `README.md`, `PROVENANCE.md` and `GLOSSARY.md`, and the `scope` job holds
  them to it. An answer arrives as a changed rule or check for you to apply, never as an
  edit to your source.
- **When a curator raises something.** A curator may read your project as deeply as they like
  and may not change a line of it, so what they find arrives as an issue labelled with your
  role: the finding, its evidence, why it matters, and what it costs to leave. Weigh it as you
  would your own design question and answer on the issue — agreeing, disagreeing with your
  reasons, or proposing something else. You and the Architect settle it; the curator does not,
  and nothing obliges you to implement a finding you have argued against. What you do take on,
  you implement in your own pull request, saying `Closes #N`.
- **Which channel.** Three places, and the label says which:
  - An `## Open questions` entry in `PROVENANCE.md` is a **design question you left
    undecided**, recorded for whoever picks it up.
  - An issue labelled with **your own** role is **work you mean to do and are not doing
    now**. Open one: a session ends and takes its intentions with it, so anything not written
    to this repository or to an issue is lost. Say what the work is, why it is not being done
    now, and what done looks like — the middle one is what keeps a queue from becoming a wish
    list. Close it when it ships, or when you no longer mean to do it.
  - An issue labelled with **another** role is **something only that role can change**: a
    rule, a check, or a capability the repository does not have.

  A question only your project can answer is the first; one whose answer would change what
  every project may do is the third. When it is both, write the design half in provenance and
  open an issue for the rest. Your record and your queue must not become two backlogs: the
  record says what **is** — what is here, what is unverified, what is not ported — and an
  issue says what is **queued**. Where both apply, link the record's section from the issue
  rather than restating it, so one can never contradict the other.
- **Say which role you are.** Every session here posts to GitHub as the same account, so the
  account says nothing about who is speaking. Open every issue, pull request and comment
  with your role: `**Role:** contributor/<domain>/<project>`. Nothing checks this — GitHub
  is not this repository — so it holds because you write it. Your issue label is that same
  string. Copy it, never compose it: applying a label creates it, so a misspelling makes a
  second label nobody filters on rather than an error you would notice.
- **Language.** Nim. TypeScript only where JavaScript is unavoidable (a browser or Node
  host); C++ or C only where no Nim import expresses the library. Never plain JavaScript,
  never Python. Each such file argues for itself in its opening comment, on the phrase
  `not Nim because <reason>` — what follows the phrase is the argument, and a curator weighs
  it when reading your pull request.
- **File kinds.** Only kinds registered in `curator/audit/src/kinds.nim` may exist; the
  `audit` job rejects any other. Need a new kind: record it as an open question and leave
  the file out until the curator registers it.
- **Dependencies.** Derive what the project exists to understand (Article II.8). External
  concerns may be dependencies, each justified where imported, declared in your nimble file
  and pinned with Atlas (below). Vendored source stays out of the repository (Article
  XI.3); `deps/` is ignored and `PROVENANCE.md` records each dependency's origin and licence.
- **Comments are telegraphic** in every file kind: no `a`, `an`, `the` in any comment. The
  audit reads comments in Nim, NimScript, nimble files, cfg files, YAML, `.gitignore`,
  `.gitattributes`, TypeScript, C++ and C. Markdown documents are prose and keep their
  articles.

## Branch and commits

Branch from `main`:

```sh
git fetch origin main
git checkout -b contributor/<domain>/<project>/<name> origin/main
```

- Exactly four segments, mirroring the path. `<domain>` is one of `abstand`, `bangu`,
  `ronri`, `sincopa`, `comma_games`. `<project>` matches `[a-z][a-z0-9_]*`. `<name>` matches
  `[a-z0-9][a-z0-9_-]*`.
- Conventional Commits with the project folder as scope: `feat(<project>): add parser`.
  Lowercase imperative summary, no final period. Types: `build`, `chore`, `ci`, `docs`,
  `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`. One intention per commit.
  `PROVENANCE.md` and `GLOSSARY.md` updates travel in their own `docs(<project>)` commit,
  in the same delivery as the change they describe.
- Never rewrite pushed history. The log is part of the document (Article XI.2).
- `nim r koch ci` at the repository root passes on the exact commit you are about to push.
  Only then push with `git push -u origin <branch>` and open a pull request from the
  template. Do not merge and do not ask for a merge; the owner reads and merges.

## Starting a project

Before any code:

1. Create `contributor/<domain>/<project>/`.
2. Write `PROVENANCE.md` first, opening with the header table below. The `Rules` value is
   the stamp of the governing documents: run `nim r koch stamp` at the repository root
   (needs git and any Nim that builds koch, which is `curator/audit`'s pin) and paste its
   last line.
3. Write `GLOSSARY.md`: `# <project>` heading, one sentence on what the project is,
   `## Language`. Terms are added as they resolve, never in advance.
4. Write `README.md`: purpose, authority replicated if any, build and test command, status.
5. Write `<project>.nimble`: `version`, `author`, `description`, `license`,
   `srcDir = "src"`, and `requires "nim == <version>"` naming the compiler you verified the
   project on. Copy `curator/probe/probe.nimble`. Atlas and the audit read requirements from
   this file; the audit demands exactly one nimble file, named after the project folder, and
   an exact pin rather than a range (see Toolchain).
6. Create `src/` and `tests/` with at least one test. Use the testament stub shape from
   `STYLE.md` §6; `curator/probe/tests/tprobe.nim` is a worked example with a matrix.
   `nim r koch tests contributor/<domain>/<project>` runs your tests alone.

Directories inside your project are yours: nest `src/`, `app/`, `design/` or anything else
the work wants. Koch runs your tests; it holds no verb for anything else. A project needing
more, pages to build or an instrument to run, carries its own compiled driver
`tools/build.nim` taking one command argument, never a build file, since make is retired
and a task in the nimble file would put logic in the compiler's virtual machine.
`contributor/sincopa/dance_ontology/tools/build.nim` is the worked example; run it with
`nim r tools/build.nim <command>` from the project directory.

Header table for `PROVENANCE.md`:

```md
| Field  | Value |
|--------|-------|
| Agent  | <tool you run in, e.g. Claude Code> |
| Author | <model> |
| Date   | <YYYY-MM-DD> |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | <last line of `nim r koch stamp`> |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |
```

## Toolchain

Your project pins its own compiler. No single version serves every project here, and that is
a fact rather than a preference: one project's dependency needs 2.2.6 or later, and another
crashes the compiler on 2.2.8 and later. So the version lives in your nimble file, beside the
packages Atlas pins, and it is exact for the same reason `atlas.lock` is exact — it records
what was verified, never a range nobody tried.

- `requires "nim == 2.2.6"`. A range is rejected by the audit: `>=` cannot say which
  compiler your suites actually passed on, and cannot express an upper bound when a later
  release breaks you.
- Where your project must follow a dependency onto `devel`, and no release carries what it
  needs, pin the compiler's own commit instead: `requires "nim == <forty hex characters>"`.
  A commit records what you verified exactly as a version does. `devel` on its own is
  rejected, and rightly: it is a moving target and records nothing. Pin a release whenever
  one will do — a commit costs everyone who builds your project, including CI.
- **You do not have to install it.** `koch` resolves each project's pin on its own: the
  compiler on `PATH` when it already serves the pin, otherwise one cached under
  `~/.cache/koch/nim/<pin>/`, otherwise it fetches one — a published release as a tarball,
  and a commit (or a platform nim-lang.org publishes no build for) by cloning `nim-lang/Nim`
  and running `sh build_all.sh`. That is paid once per pin and cached; a release takes
  seconds, a commit build takes minutes. `$KOCH_NIM_DIR` moves the cache. This is why
  `koch ci` is green as one command even when your project and the next pin different
  compilers, which is the ordinary case whenever a rules change touches every project.
- Each project's suites run on its own compiler, and `testament` and `atlas` come from that
  same toolchain with its `bin/` leading `PATH` — Atlas reads `nim` from `PATH`, so without
  that it would replay your lock against whichever compiler happened to be there.
- A pin nothing can serve, because the network is unreachable or the version does not exist,
  is a finding naming the pin and the cache it tried. It is never a silent fallback to
  another compiler: the wrong one either fails confusingly or passes without testing what CI
  will run.
- Installing it yourself still works and skips the fetch: put a matching `bin/` on `PATH`,
  or drop a toolchain at `~/.cache/koch/nim/<pin>/`. `nim --version` prints `git hash:`,
  which is what a commit pin is compared against.
- Bumping the pin is your work, and it is a change like any other: run the suites on the new
  version, move the line, and record in `PROVENANCE.md` what moved and why.
- CI installs your pin for your project alone, in its own job. You are never held to another
  project's compiler, and no other project is held to yours.

## Adding a dependency

Dependencies are managed per project with Atlas, Nim's dependency manager (`atlas` ships
with Nim). Inside your project directory:

1. `atlas init` once; it writes `deps/atlas.config`. Move that file to the project root
   (`mv deps/atlas.config .`) so it is committed; `deps/` never is.
2. `atlas use <package>`: clones into `deps/`, appends `requires "<package>"` to your nimble
   file and writes `--path` lines into `nim.cfg` between marker comments.
3. `atlas pin`: writes `atlas.lock` with exact commits. The audit demands this file whenever
   the nimble file requires a package.
4. Commit `<project>.nimble`, `atlas.config`, `atlas.lock` and `nim.cfg`. Justify the import
   in the module header that uses it (Article II.8) and record origin, commit and licence
   in `PROVENANCE.md` (Article XI.3).

`nim r koch deps` restores every project's checkouts from its lock (`atlas --noexec rep`,
verified by `atlas changed`); the `audit` job runs it before the tests. Atlas needs the
network for every command, so a project with no packages carries no lock and skips Atlas.

## TypeScript and Node

TypeScript is admitted where JavaScript is forced — a browser or a Node host — and nowhere
else. Every such file argues for itself in its opening comment, as any gated language does.
Whatever a derived value depends on stays in Nim behind an export (Article II.9); what
remains in TypeScript is what the target alone can do, such as the DOM, WebGL, pointer
events, or a test driver's host API.

- **`tsconfig.json` at the project root**, with `strict`, `noUncheckedIndexedAccess` and
  `exactOptionalPropertyTypes`. `strict` alone still hands you a value the type says is
  present when it is not; those two make indexing and optionality behave the way Nim's do,
  which is what Article IV.1 asks of any target.
- **Sources are committed and everything `tsc` emits lives under `build/`**, never committed,
  like any other build product.
- **Node packages are pinned the way Atlas pins Nim ones**: `package.json` and its lockfile
  are committed, `node_modules/` never is, and `PROVENANCE.md` records each dependency's
  origin, version and licence (Article XI.3). The lock is committed, the checkout is not, and
  one verb restores it.
- **One command builds it**: a `web` verb in your project's `tools/build.nim`, so a driven
  check is evidence for a build anyone can repeat rather than for one invocation nobody saw.

A generated lockfile passes the form rules unchanged. That is measured rather than assumed:
its long lines are single unbreakable tokens — an `integrity` digest or a registry URL — and
the width rule already exempts a line that breaking cannot fix. Never reformat one to fit.

## Pages and assets

A page the project stands behind lives in `pages/`; a one-off exploration kept for reference
lives in `mockups/`. Both hold hand-written HTML and SVG, committed as files and obeying
every rule any other file obeys: 100 columns, no tabs, telegraphic comments inside
`<!-- -->`. A line may pass the width rule only when breaking cannot fix it, which covers a
long URL and nothing else.

Everything a build emits is a build product under `build/`, never committed, whatever it
looks like: generated markup is one long line and fails width on its own.

Binaries are never committed, and neither are fonts, images or any file the audit cannot
read. Record each one in `PROVENANCE.md` with its origin, version, licence and checksum,
and add an `assets` verb to `tools/build.nim` that fetches it into `build/`. This is the
rule Atlas already follows for packages: the lock is committed, the checkout is not, and one
verb restores it. A contributor who can run that verb needs nothing else from you.

## Building on a project

Every later session:

1. Read `PROVENANCE.md` in full, then `GLOSSARY.md`, then the code in the order the umbrella
   module's bootstrap diagram gives.
2. Run `nim r koch tests contributor/<domain>/<project>` for your project. It must be green
   before you start. Before every push, `nim r koch ci` must be green (see below).
3. `Rules stamp stale` on your project means the governing documents changed after the
   project's last audit. Normally the curator re-audits every project in the same pull
   request as a rules change, so this appears only when your branch predates one. Merge
   `origin/main` into your branch, read the diff of `CONSTITUTION.md`, `STYLE.md` and
   `CONTRIBUTOR.md` since the `Date` in your header, re-audit the project against each
   changed rule, fix, then paste the new stamp in its own `docs` commit.
4. Work in small commits. Update `PROVENANCE.md` in the same delivery as each design change,
   pruning what the change replaced.

## Tests are paramount

- Article IX applies in full. Where an authority exists, suites are named after its chapters
  and every assertion cites it in a trailing comment.
- **Regression rule.** Every mistake found, in any session, earns a test that fails before
  the fix and passes after, committed before the fix: `test(<project>): cover <mistake>`,
  then `fix(<project>): <fix>`. Never delete, weaken or skip a test to get green. The
  `commits` job enforces this: a `fix` with no earlier `test` of the same scope on your
  branch is a finding. A change that needs no new test is not a `fix` — it is a `refactor`,
  a `chore` or a `docs`, and saying so is honest rather than evasive.
- Test laws, not examples. Enumerate small domains exhaustively; sample large ones with a
  few hundred seeded random cases, and record the count beside the claim.
- Test where the mechanism runs: real wiring, output read back, bytes re-read.
- `koch` runs testament over `tests/t*.nim` in your project directory; there is no
  per-project build file. `nim r koch tree` runs the static audit alone, and
  `nim r koch tests <project>` restores that project's dependencies and runs its suites;
  `nim r koch ci` is the one to run before a push. Nothing runs every project at once on
  one machine, because their compilers differ; CI sweeps them, one job each.

## Glossary process

`GLOSSARY.md` follows Matt Pocock's `CONTEXT.md` format and his domain-modeling discipline,
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
- A glossary and nothing else: no implementation detail, no specification, no scratch notes.

Five moves during every session, not at its end:

1. **Challenge against the glossary.** When the owner or the code uses a term that conflicts
   with an entry, say so at once and ask which meaning holds.
2. **Sharpen fuzzy language.** When a term is vague or overloaded, propose a precise
   canonical one.
3. **Discuss concrete scenarios.** Stress-test relationships between concepts with specific
   edge cases until boundaries are exact.
4. **Cross-reference with code.** When a statement about behaviour disagrees with the code,
   surface the contradiction instead of choosing silently.
5. **Propose the term; never write it on sight.** Set out the concept, offer candidate
   names with what each would displace, and stop. Only the name the Architect selects is
   written, and only then. A term invented in passing is a term nobody agreed to, and the
   audit cannot catch it: it checks a glossary's shape, never whether its words were
   chosen. This rule holds by the Architect's reading, and by nothing else.

Where Pocock's process would write an architecture decision record, this repository writes
the decision into `PROVENANCE.md` under its subsystem (Article VIII.6): what was chosen,
what was rejected, what it costs. There is no `docs/adr/`.

## Before opening a pull request

- `nim r koch ci` at the repository root passes on the exact commit you push. It fetches
  `origin/main`, then runs what CI runs: the whole-tree static pass (layout, form, comments,
  provenance stamps, glossary shape, compiler pins), then dependency restore and the suites
  of every project whose code changed — normally yours alone — then `scope` (every changed
  path starts with `contributor/<domain>/<project>/`) and `commits` (every subject parses as
  `type(<project>): summary`). A pull request opened before it passes is a process
  violation whatever CI later says: the runner confirms, it never discovers. Run it again
  before every later push to the same pull request.
- A change touching only your project's records — `README.md`, `PROVENANCE.md` and
  `GLOSSARY.md` — compiles nothing, since it alters
  no behaviour; the static pass still checks every stamp.
- **`base` fails when the rules or the checker moved on `main` after you branched.** Your
  stamp then claims a charter that no longer exists, and merging would redden `main` — which
  has happened. Merge `origin/main`, read the diff of the rules documents, re-audit your
  project against each change, re-stamp, and push. Only the charter and the checker count:
  another project's code moving underneath you is not your problem and will not stop you.
- `PROVENANCE.md` describes the design as it now is, with each claim marked verified or
  assumed and each figure carrying its pair; nothing narrates.
- `GLOSSARY.md` holds every term that resolved.
- No debug output left behind. Whitespace, tabs and width the audit already checks.
- Pull request body follows `.github/pull_request_template.md`: intent, scope, verification
  (what ran, on which build), record, notes.
- **A published page is linked, not described.** Where your change alters what a page shows,
  republish it and put the URL in the verification section, so the Architect can open it
  rather than rebuild it to see the change. Naming a page is not evidence about a page. Where
  a page cannot be republished before review, say which pages would change and why they are
  not up.
- **Open it as a draft, and mark it ready only when it is.** Ready means CI green on the
  runner, every review comment answered, and nothing you still intend to change. A draft
  says "not yet" in the one place the Architect looks; an open pull request says "merge me",
  and one merged before it was ready cost a second pull request to undo. Local green is not
  the signal: `koch ci` and the runner disagree whenever the machines differ, which is what
  the runner is for. Nothing checks this — GitHub is not this repository — so it holds
  because you do it.

## Output contract

From the constitution: return the implementation first. Report only material assumptions,
representation and staging choices, non-obvious trade-offs, unresolved questions, and
verification performed, i.e. what ran, on which build. Before answering, silently review the
result against Articles I to XI and the precedence clause.

**Put a published page's URL in the message itself, not only in the pull request.** When you
tell the Architect the work is ready, every page your change republished is linked right
there, so opening one costs a click rather than a trip through the pull request to find it.
The same URL belongs in both places; the pull request is the record, the message is what gets
read first.

## Provenance guide

Instructions for an assistant working on a project that keeps a `PROVENANCE.md`. The file
records who made the work, from what, how far it has been checked, and why the design is
the way it is. It is read by whoever picks the project up next, human or model, so that
they can rebuild it from the file plus the source without repeating your mistakes.

### Create it at the start, not the end

Open the file before writing code. Begin with a table:

| Field  | Value |
|--------|-------|
| Agent  | the tool you are running in |
| Author | the model |
| Date   | today |
| Style  | which style or constitution documents govern the code, and that they were followed |
| Rules  | the stamp `nim r koch stamp` prints for the governing documents you audited against |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

The review line is the point of the file. AI-authored work must carry its own verification
status, and that line must stay true: change it only when a human has actually reviewed
something, and say what.

### Record the current design, by subsystem

Organise the body by subsystem, not by date. Each section describes the design **as it is
now**. For every non-obvious decision write three things: what was chosen, what was
rejected, and what the choice costs. Keep every concrete constant with its reasoning, so
nobody has to rediscover why a number is what it is.

Mark what is **verified** and what is **assumed**, and say how each was verified: a test
case, a driven check, a rendered frame that was looked at, a measurement. That distinction
is the file's most valuable property; it is what makes the text provenance rather than a
design document.

### Rules that keep it honest

- **Verify by running.** A claim about behaviour, cost, or appearance goes in the file
  only after you ran the code, rendered the output, or read the bytes back.
- **A claim someone else can repeat cites the test that repeats it**, written as
  ``Verified by `tfoo.nim` ``. The audit resolves that name against your `tests/` directory
  and fails when it does not exist, so a citation cannot quietly rot when a suite is renamed
  or removed. It checks only that the file exists; whether that test makes the claim beside
  it is read, never checked.
- **A claim verified any other way says so, and names the tool and the date.** Verified by
  hand, in a browser, or with something that is not in this repository means nobody can
  re-run it from a checkout, and a later reader is entitled to know that before trusting it.
  Write "verified by hand in Firefox 141, 2026-09-06" rather than "verified". Prefer turning
  such a claim into a test; where the thing genuinely cannot be tested here, the sentence
  carries its own expiry, and that is the honest outcome.
- **Measurements come in pairs.** A cost is a before and an after, on a named machine and
  scene, with the method. If you did not measure, write "unmeasured" rather than repeat an
  earlier figure.
- **A rejected alternative earns one line, and only if it is still a trap.** "Not
  camera-scaled, which visibly resizes a plane as the camera orbits" belongs; the story of
  how you found that does not.
- **Update it in the same delivery as the change**, in its own commit, so the record never
  lags the code.

### Prune, never narrate

The file is not a changelog. When a design is replaced, rewrite its section to describe the
replacement and delete the old account. Fixed bugs, abandoned experiments and superseded
figures come out. If the file starts reading as a diary of what happened, prune it until it
reads as a description of what is.

### What a good entry looks like

> **The selection menu opens beside the pointer and stays with the object.** A click that
> reveals it puts its corner 8 px from the pointer, as a desktop context menu does, and it
> remembers its offset from the object's anchor so orbiting carries it along. Rejected:
> re-gluing it to the object every frame, which snapped it away from the click one frame
> later. Verified by driven check: a right-click 15 px off a point opens the menu within
> the inset, and a pan moves menu and anchor by the same delta.

Name the mechanism, the reason, the rejected path, the cost, and the check. Nothing else.
