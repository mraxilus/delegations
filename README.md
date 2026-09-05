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
Makefile   .gitignore  .gitattributes   .github/
curator/                 audit tooling, itself a project
<domain>/README.md       domain theme
<domain>/<project>/      README.md  PROVENANCE.md  GLOSSARY.md  Makefile  src/  tests/
```

## Roles

- A **curator** session maintains the rules, the domain folders and the audit tooling, and
  never writes project code. It starts from [CURATOR.md](CURATOR.md).
- A **contributor** session builds one project and touches nothing outside its folder. It
  starts from [CONTRIBUTOR.md](CONTRIBUTOR.md).

## Branches and checks

`main` is protected; the owner merges pull requests by hand. Work happens on
`<domain>/<project>/<name>` for projects and `curator/<name>` for the tooling. Every pull
request runs three jobs:

- `audit`: layout, form, telegraphic comments, provenance headers and rules stamps,
  glossary shape, then every project's own `make check`.
- `scope`: every changed path lies inside the branch's project folder.
- `commits`: every subject is a Conventional Commit whose scope matches the branch.

Locally, `make check` runs the audit and every project. It needs Nim 2.2.4, make and git.

## Licence

[Prosperity Public License 3.0.0](LICENSE.md).
