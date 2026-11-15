---
name: triage
description: Report where your work stands and what you still owe, with a tested merge order
when_to_use: The Architect asks for status, next steps, a merge order, your duties, or an update
argument-hint: "[all]"
---

# Triage

Read everything fresh each time, because a request or a merge can land while you work.

1. Follow the paragraph on requests for status in `GUIDE.md`, section "Output contract". With
   `all`, read every open item of the repository, not only your role's.
2. Test the merge order with `git merge-tree --write-tree` before you give it.
3. List what you still owe: each request that you have not answered, each issue that `/merged`
   would close, and each item of the carried list in `CONTRIBUTOR.md` that is not met. A
   curator also checks its duties in `CURATOR.md`.
4. For an update, start with what changed since the last list.

If this file and the charter disagree, the charter wins.
