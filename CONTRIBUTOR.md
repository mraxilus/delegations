# Contributor

You are a contributor session in `delegations`, a repository of model-written code under one
owner's architecture. You are assigned exactly one project, `<domain>/<project>`, named in
the prompt that carried this file. Everything you write lives there, on a branch named for
it. The owner merges by hand. You never merge, never touch `main`, never write outside your
project.

## Read first, in this order

1. `CONSTITUTION.md`. Every rule is a decision already made. Where a task forces you to
   break one, say so and write down the cost.
2. `STYLE.md`. How each rule is spelled in Nim.
3. This file to the end, including the glossary process and the provenance guide.
4. `<domain>/README.md` for the domain's theme, then your project's `README.md`,
   `PROVENANCE.md` and `GLOSSARY.md` when they exist. `PROVENANCE.md` describes the design
   as it is now; read it before the code, and correct it when the code disagrees.

## Boundaries

- **Scope.** Only paths under `<domain>/<project>/`. The CI job `scope` fails on any other
  path. Root files, `curator/`, domain READMEs and other projects are not yours, even to fix
  a typo. The owner may merge a red check deliberately; never count on it.
- **Blocked by a rule or a check.** Do not work around it and do not edit the rule. Record
  the question under an `## Open questions` heading in `PROVENANCE.md` and in the pull
  request body. The curator changes rules; you do not.
- **Language.** Nim. TypeScript only where JavaScript is unavoidable (a browser or Node
  host), never plain JavaScript, never Python. Each such file justifies itself in its header.
- **File kinds.** Only kinds registered in `curator/src/kinds.nim` may exist; the `audit` job
  rejects any other. Need a new kind: record it as an open question and leave the file out
  until the curator registers it.
- **Dependencies.** Derive what the project exists to understand (Article II.8). External
  concerns may be dependencies, each justified where imported. Vendored source stays out of
  the repository (Article XI.3); `PROVENANCE.md` records its origin, commit and licence.
- **Comments are telegraphic** in every file kind: no `a`, `an`, `the` in any comment. The
  audit reads comments in Nim, Makefile, YAML, `.gitignore`, `.gitattributes` and
  TypeScript. Markdown documents are prose and keep their articles.

## Branch and commits

Branch from `main`:

```sh
git fetch origin main
git checkout -b <domain>/<project>/<name> origin/main
```

- Exactly three segments. `<domain>` is one of `abstand`, `bangu`, `ronri`, `síncopa`,
  `comma_games`. `<project>` matches `[a-z][a-z0-9_]*`. `<name>` matches
  `[a-z0-9][a-z0-9_-]*`.
- Conventional Commits with the project folder as scope: `feat(<project>): add parser`.
  Lowercase imperative summary, no final period. Types: `build`, `chore`, `ci`, `docs`,
  `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`. One intention per commit.
  `PROVENANCE.md` and `GLOSSARY.md` updates travel in their own `docs(<project>)` commit,
  in the same delivery as the change they describe.
- Never rewrite pushed history. The log is part of the document (Article XI.2).
- `make ci` at the repository root passes on the exact commit you are about to push. Only
  then push with `git push -u origin <branch>` and open a pull request from the template.
  Do not merge and do not ask for a merge; the owner reads and merges.

## Starting a project

Before any code:

1. Create `<domain>/<project>/`.
2. Write `PROVENANCE.md` first, opening with the header table below. The `Rules` value is
   the stamp of the governing documents: run `make stamp` at the repository root (needs Nim
   2.2.4, make and git) and paste its output.
3. Write `GLOSSARY.md`: `# <Project>` heading, one sentence on what the project is,
   `## Language`. Terms are added as they resolve, never in advance.
4. Write `README.md`: purpose, authority replicated if any, build and test command, status.
5. Write `Makefile` with a `check` target that rebuilds, then drives every test
   (Article IX.6).
6. Create `src/` and `tests/` with at least one test. Use the testament stub shape from
   `STYLE.md` §6; the curator's own tests under `curator/tests/` are a worked example.

Header table for `PROVENANCE.md`:

```md
| Field  | Value |
|--------|-------|
| Agent  | <tool you run in, e.g. Claude Code> |
| Author | <model> |
| Date   | <YYYY-MM-DD> |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | <output of `make stamp`> |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |
```

Minimal `Makefile`: copy `curator/Makefile` and keep its `check` target, which runs
testament over `tests/t*.nim`. Recipe lines begin with a tab, the one place a tab is allowed.

## Building on a project

Every later session:

1. Read `PROVENANCE.md` in full, then `GLOSSARY.md`, then the code in the order the umbrella
   module's bootstrap diagram gives.
2. Run `make check` at the repository root. It must be green before you start. Before every
   push, `make ci` must be green (see below).
3. `Rules stamp stale` on your project means the governing documents changed after the
   project's last audit. Normally the curator re-audits every project in the same pull
   request as a rules change, so this appears only when your branch predates one. Merge
   `origin/main` into your branch, read the diff of `CONSTITUTION.md`, `STYLE.md` and
   `CONTRIBUTOR.md` since the `Date` in your header, re-audit the project against each
   changed rule, fix, then paste the new `make stamp` value in its own `docs` commit.
4. Work in small commits. Update `PROVENANCE.md` in the same delivery as each design change,
   pruning what the change replaced.

## Tests are paramount

- Article IX applies in full. Where an authority exists, suites are named after its chapters
  and every assertion cites it in a trailing comment.
- **Regression rule.** Every mistake found, in any session, earns a test that fails before
  the fix and passes after, committed before the fix: `test(<project>): cover <mistake>`,
  then `fix(<project>): <fix>`. Never delete, weaken or skip a test to get green.
- Test laws, not examples. Enumerate small domains exhaustively; sample large ones with a
  few hundred seeded random cases, and record the count beside the claim.
- Test where the mechanism runs: real wiring, output read back, bytes re-read.
- `make -C <domain>/<project> check` is the one command for your project. The root
  `make check` runs the audit, then that command for every project; CI runs the same.

## Glossary process

`GLOSSARY.md` follows Matt Pocock's `CONTEXT.md` format and his domain-modeling discipline,
renamed for this repository. It is the project's ubiquitous language: the words the owner,
the code and every later session share. Format:

```md
# <Project>

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
5. **Update `GLOSSARY.md` inline.** The moment a term resolves, write it. Never batch.

Where Pocock's process would write an architecture decision record, this repository writes
the decision into `PROVENANCE.md` under its subsystem (Article VIII.6): what was chosen,
what was rejected, what it costs. There is no `docs/adr/`.

## Before opening a pull request

- `make ci` at the repository root passes on the exact commit you push. It fetches
  `origin/main`, then runs the same three checks CI runs: `check` (the `audit` job: layout,
  form, comments, provenance, glossary, every project's tests), `scope` (every changed path
  starts with `<domain>/<project>/`) and `commits` (every subject parses as
  `type(<project>): summary`). A pull request opened before it passes is a process
  violation whatever CI later says: the runner confirms, it never discovers. Run it again
  before every later push to the same pull request.
- `PROVENANCE.md` describes the design as it now is, with each claim marked verified or
  assumed and each figure carrying its pair; nothing narrates.
- `GLOSSARY.md` holds every term that resolved.
- No debug output, trailing whitespace, tabs outside make recipes, or lines over 100
  characters.
- Pull request body follows `.github/pull_request_template.md`: intent, scope, verification
  (what ran, on which build), record, notes.

## Output contract

From the constitution: return the implementation first. Report only material assumptions,
representation and staging choices, non-obvious trade-offs, unresolved questions, and
verification performed, i.e. what ran, on which build. Before answering, silently review the
result against Articles I to XI and the precedence clause.

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
| Rules  | the stamp `make stamp` prints for the governing documents you audited against |
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
