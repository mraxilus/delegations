# audit

Checks of the delegations repository: what the rules are as data, and how the repository
is read to check them.

## Language

**Audit**:
One run of the checks over the tree, a branch, or both, producing findings.
_Avoid_: lint, validation, check run

**Finding**:
One rule violation at a path and line, with a telegraphic message that echoes the offending
value.
_Avoid_: error, issue, violation, diagnostic

**Check**:
One rule family applied by one module: layout, form, prose, provenance, glossary, scope,
commits, dependencies, tests.
_Avoid_: linter, rule set, validator

**Koch**:
The compiled driver at the repository root that builds nothing but dispatch over the
checks; the name and shape come from Nim's own repository.
_Avoid_: build script, makefile, task runner

**Tree**:
The repository as git sees it: every tracked or untracked-unignored file, with content read
for registered kinds.
_Avoid_: working copy, file list, repo

**Kind**:
A registered file type, matched by basename or extension, carrying its comment syntax. An
unregistered kind does not exist.
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

**Root**:
One of the two project roots, `curator/` or `contributor/`; each holds README.md and
folders only.
_Avoid_: top level, tree root, workspace

**Domain**:
One of the owner's life areas, a folder under `contributor/` with a slug, a display name
and a theme.
_Avoid_: area, category, topic

**Project**:
A directory `curator/<project>` or `contributor/<domain>/<project>`, holding README.md,
PROVENANCE.md, GLOSSARY.md, a nimble file named after it, and tests.
_Avoid_: package, module, repo

**Requirement**:
A package named by a `requires` line in a project's nimble file, `nim` excluded.
_Avoid_: dependency declaration, import

**Lock**:
The project's `atlas.lock`, pinning each requirement to a commit; demanded whenever a
requirement exists.
_Avoid_: lockfile, manifest, pin file

**Scope**:
The path prefix a branch may change; also the Conventional Commit scope that names it.
_Avoid_: boundary, ownership, sandbox

**Curator**:
The session role that maintains rules, root files and curator projects; also the root
folder of those projects and the head of its branches.
_Avoid_: maintainer, admin

**Contributor**:
The session role confined to one domain project; also the root folder of domain folders
and the head of its branches.
_Avoid_: agent, worker, developer

**Probe**:
The curator project `curator/probe`, and a throwaway pull request from
`curator/probe/probe-<name>` that drives the merge process without touching a real project.
_Avoid_: smoke test, canary, dry run

**Owner**:
The human who architects, reads and merges.
_Avoid_: user, maintainer, reviewer
