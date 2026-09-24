# delegations

The words that this repository uses for itself: who works in it, how it is laid out, what it
records, and what the audit reports. A term enters only when the Architect selects it.

## Language

**Architect**:
The person who decides what to build and how to build it, reads the work, merges it, and
writes none of the code.
_Avoid_: owner, director, user, reviewer

**Curator**:
The role that keeps the charter, the root files and the curator projects, and never writes
code inside a contributor project.
_Avoid_: maintainer, admin

**Contributor**:
The role that works in one project under `contributor/`, and nowhere else.
_Avoid_: developer, worker, author

**Delegate**:
One run of a model under one role, on one branch, which starts from a pasted opening
prompt.
_Avoid_: session, agent, assistant, bot

**Domain**:
One area of interest of the Architect. It is a folder under `contributor/` that holds the
projects which share a subject.
_Avoid_: area, category

**Project**:
One folder that holds its own README, provenance, glossary, package file and tests. It is
the unit that one delegate works in, and does not leave.
_Avoid_: package, repo

**Artifact**:
A file that a build writes under `build/`, and that git never keeps.
_Avoid_: build product, output

**Charter**:
The three documents that every delegate follows: CONSTITUTION.md, STYLE.md and
CONTRIBUTOR.md.
_Avoid_: rules, law, guidelines, policy

**Stamp**:
The short code that says which charter the audit last checked a project against.
_Avoid_: seal, hash, fingerprint

**Provenance**:
The record of a project: who made it, from what, how far it is checked, and why the design
is as it is.
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
One broken rule that the audit reports, at a path and a line, with a message that ends in
the offending value.
_Avoid_: violation, fault, error

**Scope**:
The folder that a branch may change. The name of the branch fixes it.
_Avoid_: bounds, prefix, boundary

**Commit scope**:
The word inside brackets in a commit subject. It names the project that the commit belongs
to.
_Avoid_: tag

**Record**:
The three files that every project carries and a curator may write: `README.md`,
`PROVENANCE.md` and `GLOSSARY.md`.
_Avoid_: docs, metadata

**Role**:
The string that says who is speaking: `curator`, `curator/<project>` or
`contributor/<domain>/<project>`. It opens every issue, pull request and comment, and it
labels every issue and pull request.
_Avoid_: identity, persona

**Queue**:
The open issues that carry the string of one role. They hold work that an earlier delegate
decided and left.
_Avoid_: todo, backlog, wish list

**Driver**:
The `tools/build.nim` of a project. It holds every verb that the project answers to.
_Avoid_: script, makefile, build file

**Verb**:
One command that a driver or `koch` dispatches, such as `test` or `fetch-assets`.
_Avoid_: task, target, subcommand

**Pin**:
The exact compiler that a project needs, as a version or a commit. Its package file names
it.
_Avoid_: version, requirement

**Store**:
The shared cache of fetched files, keyed by digest. `koch fetch-assets` fills it, and every
project reads it.
_Avoid_: asset store, cache, vault

**Front-end**:
One presentation target of a project: a browser page, or a desktop window.
_Avoid_: client, build, UI

**Ledger**:
The daily read of what GitHub records about the rules that no check reaches. `ledger.yml`
writes it into one issue.
_Avoid_: sweep

**Carried list**:
The unchecked rules that a delegate posts in the conversation. It posts them at the start,
as each one resolves, and at handover, so the Architect sees where the work stands.
_Avoid_: checklist, todo list

**Handover**:
The moment when a delegate ends. It posts the carried list in full, and what is left.
_Avoid_: end of session, wrap-up, sign-off
