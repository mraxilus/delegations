# Delegations

Third repository in a chain. [explorations](https://gitlab.com/mraxilus/explorations) tries
ideas, [replications](https://gitlab.com/mraxilus/replications) rebuilds work worth
understanding, and delegations makes quick progress on prototypes without the Architect
writing code directly. The Architect decides every design; language models write every line,
under [CONSTITUTION.md](CONSTITUTION.md) and [STYLE.md](STYLE.md), and record what was
decided, what was rejected and what it costs in each project's `PROVENANCE.md`. The words the
repository uses for itself are in [GLOSSARY.md](GLOSSARY.md).

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
README.md  LICENSE.md  CONSTITUTION.md  STYLE.md  CURATOR.md  CONTRIBUTOR.md  CLAUDE.md
GLOSSARY.md  koch.nim  koch.nim.cfg  .gitignore  .gitattributes  .github/
curator/README.md                        curator projects: audit, probe, any other
curator/<project>/                       README.md  PROVENANCE.md  GLOSSARY.md  <project>.nimble
                                         src/  tests/  [tools/build.nim  pages/  mockups/
                                         atlas.config  atlas.lock  nim.cfg  package.json]
contributor/README.md                    contributor projects, grouped by domain
contributor/<domain>/README.md           domain theme
contributor/<domain>/<project>/          same shape as a curator project
```

## Roles

- A **curator** delegate maintains the rules, the root files and the curator projects, and
  never writes contributor project code. It starts from [CURATOR.md](CURATOR.md).
- A **contributor** delegate builds one project and touches nothing outside its folder. It
  starts from [CONTRIBUTOR.md](CONTRIBUTOR.md).

## Issues

Issues carry what the two roles say to each other, in both directions, without the Architect
standing between them. A contributor blocked by a rule opens one asking for the rule to
change; a curator who reads a project and finds something opens one saying what they found,
since they may not edit a contributor's source. Either way the answer is written on the
issue, and the Architect decides.

They also carry each delegate's own queue, since a delegate ends and takes its intentions with
it. The record says what **is**; an issue says what is **queued**, and links the record rather
than restating it.

Every delegate posts as the same account, so each issue carries a label saying whose it is,
spelled exactly as the branch prefix: `curator` for the rules, the checks, the merge process
and the root files; `curator/<project>` or `contributor/<domain>/<project>` for one project.
A delegate finds its work by filtering on its own label. Labels are added and never removed,
so when an answer hands work across, the other role's label joins the first.

## Branches and checks

`main` is protected; the Architect merges pull requests by hand. Branches mirror paths:
`contributor/<domain>/<project>/<name>` and `curator/<project>/<name>` may change only that
project; `curator/<name>` is rules and root work. Every pull request runs:

- `static`: layout, form, telegraphic comments, provenance headers and rules stamps,
  glossary shape, and each project's compiler pin, over the whole tree.
- `project`: one job per project whose code changed, each installing that project's own
  pinned compiler, restoring its dependencies from its lock file and running its tests.
  These run in parallel, so wall time follows the slowest changed project rather than the
  number of projects in the repository.
- `types`: `npm ci` then that project's own `types` verb, for every changed project carrying
  a node manifest. One job on the driver's compiler, since type-checking compiles no project
  code.
- `driven`: that project's own `drive` verb, for every changed project carrying one — the
  page built and driven through real keys, wheels, pointers and touches. A matrix like
  `project` and on the same pins, because building the page does compile project code.
- `scope`: every changed path lies inside the branch's folder.
- `commits`: every subject is a Conventional Commit whose scope matches the branch.
- `base`: the branch carries the rules and the checker as `main` now holds them, so a stamp
  falsified by a rules change that merged after the branch forked is caught before merging.
- `audit`: the gate the other jobs report to, and one of the three required checks.

A ninth job, `plan`, runs first and computes the matrices `project` and `driven` fan out over;
it names projects rather than checking them. Weekly, the same workflow compiles every project
whenever code merged that week. Two more workflows watch the rest: `watch.yml` opens an issue
labelled `curator` when a run on `main` concludes failure, and `sweep.yml` reads daily what
GitHub records of the rules no check reaches — a pull request ready without a green run, a
`Closes #N` that never fired, an issue or pull request without its role line or label — into
one issue.

Everything is driven by `koch.nim`, a compiled Nim program as in Nim's own repository:
`nim r koch ci` runs the same checks locally against a fresh `origin/main`, and every pull
request passes it before it is opened. `nim r koch system` prints what a machine needs
installed before any of it runs — koch's own packages and every project's, one per line, so it
pipes straight into a package manager; any Nim that builds koch is the only thing it cannot
name for you. Each project's pinned compiler is resolved from `PATH`, a cache or a download,
so one machine runs every project's suites whatever they pin. Dependencies are per project
with Atlas; lock files are committed, checkouts never.

## Licence

[Prosperity Public License 3.0.0](LICENSE.md).
