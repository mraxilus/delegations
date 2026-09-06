# Delegations

Third repository in a chain. [explorations](https://gitlab.com/mraxilus/explorations) tries
ideas, [replications](https://gitlab.com/mraxilus/replications) rebuilds work worth
understanding, and delegations makes quick progress on prototypes without the owner writing
code directly. The owner architects every decision; language models write every line, under
[CONSTITUTION.md](CONSTITUTION.md) and [STYLE.md](STYLE.md), and record what was decided,
what was rejected and what it costs in each project's `PROVENANCE.md`.

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
koch.nim   koch.nim.cfg  .gitignore  .gitattributes  .github/
curator/README.md                        curator projects: audit, probe, any other
curator/<project>/                       README.md  PROVENANCE.md  GLOSSARY.md  <project>.nimble
                                         src/  tests/  [atlas.config atlas.lock nim.cfg]
contributor/README.md                    contributor projects, grouped by domain
contributor/<domain>/README.md           domain theme
contributor/<domain>/<project>/          same shape as a curator project
```

## Roles

- A **curator** session maintains the rules, the root files and the curator projects, and
  never writes contributor project code. It starts from [CURATOR.md](CURATOR.md).
- A **contributor** session builds one project and touches nothing outside its folder. It
  starts from [CONTRIBUTOR.md](CONTRIBUTOR.md).

## Branches and checks

`main` is protected; the owner merges pull requests by hand. Branches mirror paths:
`contributor/<domain>/<project>/<name>` and `curator/<project>/<name>` may change only that
project; `curator/<name>` is rules and root work. Every pull request runs:

- `static`: layout, form, telegraphic comments, provenance headers and rules stamps,
  glossary shape, and each project's compiler pin, over the whole tree.
- `project`: one job per project whose code changed, each installing that project's own
  pinned compiler, restoring its dependencies from its lock file and running its tests.
  These run in parallel, so wall time follows the slowest changed project rather than the
  number of projects in the repository.
- `scope`: every changed path lies inside the branch's folder.
- `commits`: every subject is a Conventional Commit whose scope matches the branch.
- `audit`: the gate the other jobs report to, and one of the three required checks.

Everything is driven by `koch.nim`, a compiled Nim program as in Nim's own repository:
`nim r koch ci` runs the same checks locally against a fresh `origin/main`, and every
pull request passes it before it is opened. Needs git and any Nim that builds koch: each
project's own pinned compiler is resolved from `PATH`, a cache, or a download, so one machine
runs every project's suites whatever they pin. A weekly run compiles every project.
Dependencies are managed per project with Atlas; lock files are committed, checkouts never.

## Licence

[Prosperity Public License 3.0.0](LICENSE.md).
