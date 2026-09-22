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
README.md  LICENSE.md  CONSTITUTION.md  STYLE.md  CURATOR.md  CONTRIBUTOR.md  GUIDE.md
CLAUDE.md  GLOSSARY.md  koch.nim  koch.nim.cfg  .gitignore  .gitattributes  .github/
curator/README.md                        curator projects: audit, probe, any other
curator/<project>/                       README.md  PROVENANCE.md  GLOSSARY.md  <project>.nimble
                                         src/  tests/  [tools/build.nim  pages/  mockups/
                                         atlas.config  atlas.lock  nim.cfg  package.json]
contributor/README.md                    contributor projects, grouped by domain
contributor/<domain>/README.md           domain theme
contributor/<domain>/<project>/          same shape as a curator project
```

## Roles

- A **curator** delegate keeps the rules, the root files and the curator projects, and never
  writes code inside a contributor project. It starts from [CURATOR.md](CURATOR.md).
- A **contributor** delegate builds one project and touches nothing outside its folder. It
  starts from [CONTRIBUTOR.md](CONTRIBUTOR.md).
- Both then read [GUIDE.md](GUIDE.md), the how-to that they share. Every word they write for
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
is. The label is spelled exactly as the branch prefix. It is `curator` for the rules, the
checks, the merge process and the root files. It is `curator/<project>` or
`contributor/<domain>/<project>` for one project. A delegate finds its work by a filter on
its own label. Labels are added and never removed, so when an answer hands work across, the
label of the other role joins the first.

## Branches and checks

`main` is protected, and the Architect merges pull requests by hand. Branches mirror paths.
`contributor/<domain>/<project>/<name>` and `curator/<project>/<name>` may change only that
project, and `curator/<name>` is rules and root work. Every pull request runs these jobs:

- `static`: layout, form, telegraphic comments, and records with their headers and stamps.
  It also reads glossary shape, the prompts, and the Simplified Technical English of the
  root documents and of every project record. It reads copied paragraphs, shipped faces,
  workflow grants, and the compiler pin of each project. It runs over the whole tree.
- `project`: one job for each project whose code changed, on a pull request, on the push to
  `main`, and in the weekly run alike. Each one installs that project's own pinned compiler,
  restores its dependencies from its lock file, and runs its tests. Nothing compiles every
  project. These jobs run in parallel, so the wall time follows the slowest changed project
  rather than the number of projects in the repository.
- `types`: `npm ci`, then that project's own `types` verb, for every changed project that
  carries a node manifest. It is one job on the compiler of the driver, because a type check
  compiles no project code.
- `driven`: that project's own `drive` verb, for every changed project that carries one. The
  page is built and driven through real keys, wheels, pointers and touches. It is a matrix
  like `project`, and on the same pins, because a build of the page does compile project
  code.
- `scope`: every changed path lies inside the folder of the branch.
- `commits`: every subject is a Conventional Commit whose scope matches the branch.
- `base`: the branch carries the rules and the checker as `main` now holds them. A stamp that
  a rules change falsified after the branch forked is then caught before the merge.
- `audit`: the gate that the other jobs report to, and one of the required checks.

A ninth job, `plan`, runs first and computes the matrices that `project` and `driven` fan out
over. It names projects rather than checks them. Weekly, the same workflow compiles the
projects whose code merged that week.

`role.yml` runs beside it on every pull request, and again whenever a label changes. It holds
the opening role line and the labels to the role that the branch names. Two more workflows
watch the rest. `watch.yml` opens an issue labelled `curator` when a run on `main` concludes
failure. `ledger.yml` reads daily what GitHub records of the rules that no check reaches:

- a pull request ready without a green run;
- a `Closes #N` that never fired;
- an issue or pull request without its role line or label.

`koch.nim` drives everything, as a compiled Nim program, in the shape that the repository of
Nim itself uses. `nim r koch ci` runs the same checks locally against a fresh `origin/main`,
and every pull request passes it before somebody opens it. `nim r koch system` prints what a
machine needs installed before any of it runs. That is the packages of koch itself and of
every project, one to a line, so it pipes straight into a package manager. Any Nim that
builds koch is the only thing it cannot name for you.

The pinned compiler of each project is resolved from `PATH`, from a cache, or from a
download. So one machine runs the suites of every project, whatever they pin. Dependencies
are held for each project with Atlas. Lock files are committed, and checkouts never are.

## Licence

[Prosperity Public License 3.0.0](LICENSE.md).
