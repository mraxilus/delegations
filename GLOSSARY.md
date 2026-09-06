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
_Avoid_: area, field, theme, category

**Project**:
One folder holding its own README, provenance, glossary, package file and tests; the unit a
delegate is assigned to and confined to.
_Avoid_: package, work, module, repo

**Artifact**:
A file a build writes and git never keeps, under `build/`.
_Avoid_: build product, output, asset

**Charter**:
The three documents every delegate follows: CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md.
_Avoid_: rules, law, guidelines, policy

**Stamp**:
The short code recording which charter a project was last checked against.
_Avoid_: seal, digest, hash, fingerprint, version

**Provenance**:
A project's record of who made it, from what, how far it has been checked, and why the
design is as it is.
_Avoid_: changelog, history, notes

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
_Avoid_: violation, fault, error, issue

**Scope**:
The folder a branch may change, fixed by the branch's name.
_Avoid_: bounds, prefix, boundary

**Commit scope**:
The word in parentheses in a commit subject, naming the project the commit belongs to.
_Avoid_: tag, label
