# delegations

The words this repository uses for itself: who works in it, how it is arranged, what it
records, and what the audit reports. A term enters only when the Architect selects it.

## Language

**Architect**:
The person who decides what is built and how, reads the work and merges it, and writes none
of the code.
_Avoid_: owner, director, user, reviewer

**Curator**:
The role that maintains the charter, the root files and the curator projects, and never
writes contributor project code.
_Avoid_: maintainer, admin

**Contributor**:
The role confined to one project under `contributor/`.
_Avoid_: developer, worker, author

**Delegate**:
One model-run instance working under a role, on one branch, from a pasted opening prompt.
_Avoid_: session, agent, assistant, bot

**Domain**:
One of the Architect's areas of interest, a folder under `contributor/` grouping projects
that share a subject.
_Avoid_: area, category

**Project**:
One folder holding its own README, provenance, glossary, package file and tests; the unit a
delegate is assigned to and confined to.
_Avoid_: package, repo

**Artifact**:
A file a build writes and git never keeps, under `build/`.
_Avoid_: build product, output

**Charter**:
The three documents every delegate follows: CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md.
_Avoid_: rules, law, guidelines, policy

**Stamp**:
The short code recording which charter a project was last checked against.
_Avoid_: seal, hash, fingerprint

**Provenance**:
A project's record of who made it, from what, how far it has been checked, and why the
design is as it is.
_Avoid_: changelog, notes

**Glossary**:
The agreed vocabulary of the repository or of one project.
_Avoid_: dictionary, lexicon, terms

**Audit**:
One run of every check over the repository.
_Avoid_: lint, validation, review

**Check**:
One family of rules inside the audit, such as layout or form.
_Avoid_: validator, linter

**Finding**:
One rule break the audit reports, at a path and line, with a message ending in the offending
value.
_Avoid_: violation, fault, error

**Scope**:
The folder a branch may change, fixed by the branch's name.
_Avoid_: bounds, prefix, boundary

**Commit scope**:
The word in parentheses in a commit subject, naming the project the commit belongs to.
_Avoid_: tag

**Record**:
The three files every project carries and a curator may write: `README.md`, `PROVENANCE.md`
and `GLOSSARY.md`.
_Avoid_: docs, metadata

**Role**:
The string naming who is speaking — `curator`, `curator/<project>` or
`contributor/<domain>/<project>` — on the first line of every issue, pull request and comment,
and as an issue's label.
_Avoid_: identity, persona

**Queue**:
The open issues labelled with a role's own string, holding work decided and left for a later
delegate.
_Avoid_: todo, backlog, wish list

**Driver**:
A project's `tools/build.nim`, holding every verb the project answers to.
_Avoid_: script, makefile, build file

**Verb**:
One command a driver or `koch` dispatches, such as `tests` or `assets`.
_Avoid_: task, target, subcommand

**Pin**:
The exact compiler a project requires, as a version or a commit, named in its package file.
_Avoid_: version, requirement

**Store**:
The shared cache of fetched files keyed by digest, which `koch assets` fills and every project
reads.
_Avoid_: asset store, cache, vault

**Front-end**:
One of a project's presentation targets: a browser page, a desktop window.
_Avoid_: client, build, UI

**Ledger**:
The daily read of what GitHub records of the rules no check reaches, written into one issue by
`ledger.yml`.
_Avoid_: sweep

**Carried list**:
The unchecked rules a delegate posts in the conversation at its start, as each resolves, and at
handover, so the Architect sees where it stands.
_Avoid_: checklist, todo list

**Handover**:
The moment a delegate ends, posting the carried list in full and what is left.
_Avoid_: end of session, wrap-up, sign-off
