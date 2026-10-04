# Delegations

The third repository in a chain. [explorations](https://gitlab.com/mraxilus/explorations)
tries ideas, [replications](https://gitlab.com/mraxilus/replications) rebuilds work worth
understanding, and delegations makes quick progress on prototypes without the Architect
writing code directly. The Architect decides every design, and language models write every
line, under [CONSTITUTION.md](CONSTITUTION.md) and [STYLE.md](STYLE.md). They record what was
decided, what was rejected and what it costs, in the `PROVENANCE.md` of each project. The
words that the repository uses for itself are in [GLOSSARY.md](GLOSSARY.md).

Overarching theme: methods of communication.

## Domains

| Folder | Name | Theme |
|--------|------|-------|
| abstand | abstand | Music. |
| bangu | bangu | Language. |
| ronri | ronri | Computing. |
| sincopa | síncopa | Dance and movement. |
| comma_games | comma, games | Game development across every other domain. |

## Layout

```text
README.md  LICENSE.md  CONSTITUTION.md  STYLE.md  EXAMPLES.md  CURATOR.md  COORDINATOR.md
CONTRIBUTOR.md  GUIDE.md  CLAUDE.md  GLOSSARY.md  koch.nim  koch.nim.cfg  .gitignore
.gitattributes  .github/  .claude/  .githooks/
curator/README.md                        curator projects: audit, probe, any other
curator/<project>/                       README.md  PROVENANCE.md  GLOSSARY.md  <project>.nimble
                                         src/  tests/  [tools/build.nim  pages/  mockups/
                                         atlas.config  atlas.lock  nim.cfg  package.json]
contributor/README.md                    contributor projects, grouped by domain
contributor/<domain>/README.md           domain theme
contributor/<domain>/<project>/          same shape as a curator project
```

## Roles

- The **coordinator** delegate starts the other delegates and presents to the Architect, in
  one place, everything that waits on them. It decides nothing and writes no file. Exactly
  one works at a time. It starts from [COORDINATOR.md](COORDINATOR.md). The Architect trials
  it at a later date, and until then every other delegate works with the Architect directly.
- A **curator** delegate keeps the rules, the root files and the curator projects, and never
  writes code inside a contributor project. It starts from [CURATOR.md](CURATOR.md).
- A **contributor** delegate builds one project and touches nothing outside its folder. It
  starts from [CONTRIBUTOR.md](CONTRIBUTOR.md).
- All then read [GUIDE.md](GUIDE.md), the how-to that they share. Every word they write for
  a person is Simplified Technical English, and the guide gives the rules.

## Issues

Issues carry what the two roles say to each other, in both directions, without the Architect
standing between them. A contributor blocked by a rule opens one to ask for the rule to
change. A curator who reads a project and finds something opens one to say what it found. It
may not edit the source of a contributor. Either way the answer is written on the issue, and
the Architect decides.

They also carry the queue of each delegate, because a delegate ends and takes its intentions
with it. The record says what **is**, and an issue says what is **queued**. An issue links
the record rather than restates it.

Every delegate posts as the same account, so each issue carries a label that says whose it
is. The label is the role string that the branch names. It is `curator` for the rules, the
checks, the merge process and the root files. It is `curator/<project>` or
`contributor/<domain>/<project>` for one project. A delegate finds its work by a filter on
its own label. Role labels are added and never removed, so when an answer hands work across,
the label of the other role joins the first.

One label marks a state instead. `architect` sits on each issue or pull request that waits on
the Architect, and comes off when the wait ends.

## Branches and checks

`main` is protected, and the Architect merges pull requests by hand. Branches mirror paths.
`contributor/<domain>/<project>/<name>` and `curator/<project>/<name>` may change only that
project, and `curator/<name>` is rules and root work. Every pull request runs these jobs, and
each job carries the name of the koch verb that it runs:

- `check-files`: layout, form, telegraphic comments, and records with their headers and stamps.
  It also reads glossary shape, the prompts, and the Simplified Technical English of the
  root documents and of every project record. It holds the root documents and every Markdown
  file under `curator/` to the words that the glossary gives for people. It reads copied
  paragraphs, shipped faces, the compiler pin of each project, and each lock against its
  nimble file.

  In Nim it reads the words of each declared name, and the idioms that `STYLE.md` sets. It
  reads fixed waits in drive code, and the flags of each `tsconfig.json`. In each workflow it
  reads the grants, the compiler that the workflow installs, and the weekly window against its
  cron. It reads the reason that a file not in Nim gives, and the rules that the checker holds
  itself to. It runs over the whole tree.
- `test`: one job for each project whose code changed, on a pull request, on the push to
  `main`, and in the weekly run alike. Each one installs that project's own pinned compiler,
  restores its dependencies from its lock file, and runs its tests. Nothing compiles every
  project. These jobs run in parallel, so the wall time follows the slowest changed project
  rather than the number of projects in the repository.
- `check-types`: `npm ci`, then that project's own `types` verb, for every changed project that
  carries a node manifest beside its lock. It is one job on the compiler that builds koch,
  because a type check compiles no project code.
- `drive`: that project's own `drive` verb, for every changed project that carries one. The
  page is built and driven through real keys, wheels, pointers and touches. It is a matrix
  like `test`, and on the same pins, because a build of the page does compile project
  code.
- `check-scope`: every changed path lies inside the folder of the branch.
- `check-commits`: every subject is a Conventional Commit of at most 100 characters. On a
  project branch its scope is that project, and on `curator/<name>` any valid scope passes. A
  `fix` follows a `test` of the same scope, with nothing between them. A body is in sentence
  case, with one sentence to a line. `PROVENANCE.md` travels in a commit of its own, with no
  file beside it but Markdown.
- `check-drift`: the branch carries the charter and the checker as `main` now holds them. A stamp
  that a charter change falsified after the branch forked is then caught before the merge.
- `summarize`: the gate that `check-files`, `test`, `check-types`, `drive` and `check-drift`
  report to, and one of the required checks. `check-scope` and `check-commits` are required
  checks of their own.

One more job, `list-projects`, runs first and computes the matrices that `test` and `drive`
fan out over. It names projects rather than checks them, and it also reports to `summarize`. Weekly,
the same workflow compiles the projects whose code merged that week.

`role.yml` runs beside it on every pull request, and again whenever a label changes. It holds
the opening role line and the labels to the role that the branch names.

Six more workflows watch the rest. `watch.yml` opens an issue labelled `curator` when a run
on `main` concludes failure. `head.yml` runs the `head` verb of each project daily, and keeps
one issue open for each project while that verb fails.

`draft.yml` returns a ready pull request to draft when a push lands on it. `architect.yml`
removes the label `architect` from an issue or pull request that closes. `posts.yml` comments
once on an issue or a comment that lands with no role line. `ledger.yml` reads daily what
GitHub records of the rules that no check reaches:

- a pull request ready without a green run;
- a `Closes #N` that never fired;
- an issue or pull request without its role line or label;
- an issue whose title opens with a commit prefix;
- an issue or pull request closed with the `architect` label still on it;
- the rulesets of `main` and of every branch, and the merge settings, against the list in
  `CURATOR.md`.

`koch.nim` drives everything, as a compiled Nim program, in the shape that the repository of
Nim itself uses. `nim r koch check` runs the same checks locally against a fresh
`origin/main`, and every pull request passes it before somebody opens it. `./koch` alone lists
every verb with its effect. `nim r koch list-packages` prints what a machine needs installed
before any of it runs. That is the packages of koch itself and of
every project, one to a line, so it pipes straight into a package manager. Any Nim that
builds koch is the only thing it cannot name for you.

The pinned compiler of each project is resolved from `PATH`, from a cache, or from a
download. So one machine runs the suites of every project, whatever they pin. Dependencies
are held for each project with Atlas. Lock files are committed, and checkouts never are.

## Licence

[Prosperity Public License 3.0.0](LICENSE.md).
