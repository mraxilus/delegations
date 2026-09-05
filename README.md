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
| síncopa | síncopa | Dance and movement. |
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
project; `curator/<name>` is rules and root work. Every pull request runs three jobs:

- `audit`: layout, form, telegraphic comments, provenance headers and rules stamps,
  glossary shape, dependencies restored from lock files, then every project's tests.
- `scope`: every changed path lies inside the branch's folder.
- `commits`: every subject is a Conventional Commit whose scope matches the branch.

Everything is driven by `koch.nim`, a compiled Nim program as in Nim's own repository:
`nim r koch ci` runs the same three checks locally against a fresh `origin/main`, and every
pull request passes it before it is opened. Needs Nim 2.2.4 and git. Dependencies are
managed per project with Atlas; lock files are committed, checkouts never.

## Licence

[Prosperity Public License 3.0.0](LICENSE.md).
