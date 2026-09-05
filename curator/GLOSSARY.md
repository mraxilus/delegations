# curator

Audit tooling for the delegations repository: what the rules are as data, and how the
repository is read to check them.

## Language

**Audit**:
One run of the `audit` program over the tree, a branch, or both, producing findings.
_Avoid_: lint, validation, check run

**Finding**:
One rule violation at a path and line, with a telegraphic message that echoes the offending
value.
_Avoid_: error, issue, violation, diagnostic

**Check**:
One rule family applied by one module: layout, form, prose, provenance, glossary, scope,
commits, projects.
_Avoid_: linter, rule set, validator

**Tree**:
The repository as git sees it: every tracked or untracked-unignored file, with content read
for registered kinds.
_Avoid_: working copy, file list, repo

**Kind**:
A registered file type, matched by basename or extension, carrying its comment syntax and
form rule. An unregistered kind does not exist.
_Avoid_: file type, extension, language

**Syntax**:
The way comments are found in a kind: `Nim`, `Hash`, `HashSpaced`, `HashLeading`, `Slash`,
or `None`.
_Avoid_: grammar, comment style

**Telegraphic**:
Comment prose holding no article (`a`, `an`, `the`).
_Avoid_: terse, concise

**Rules**:
The three stamped documents: `CONSTITUTION.md`, `STYLE.md`, `CONTRIBUTOR.md`.
_Avoid_: guidelines, docs, policy

**Stamp**:
The FNV-1a 64-bit digest of the rules, 16 hex digits, recorded in every `PROVENANCE.md`
header as `Rules`.
_Avoid_: hash, version, checksum, fingerprint

**Stale**:
A project whose recorded stamp differs from the stamp of the rules as they are now.
_Avoid_: outdated, old

**Domain**:
One of the owner's life areas, a root folder with a slug, a display name and a theme.
_Avoid_: area, category, topic

**Project**:
A directory `<domain>/<project>` or `curator`, holding README.md, PROVENANCE.md,
GLOSSARY.md, a Makefile with `check`, and tests.
_Avoid_: package, module, repo

**Scope**:
The path prefix a branch may change; also the Conventional Commit scope that names it.
_Avoid_: boundary, ownership, sandbox

**Curator**:
The session role that maintains rules and tooling; also the project folder holding the
tooling and the branch prefix it works on.
_Avoid_: maintainer, admin

**Contributor**:
The session role confined to one project.
_Avoid_: agent, worker, developer

**Owner**:
The human who architects, reads and merges.
_Avoid_: user, maintainer, reviewer
