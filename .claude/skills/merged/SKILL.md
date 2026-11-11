---
name: merged
description: Finish the work that a merge leaves, from the push run on main to open branches
when_to_use: The Architect says that a pull request merged, or its closed event arrives
---

# Merged

Use this after a pull request of yours merges, before you take your next item.

1. Read the push run on `main` for the merge. If it is red, fixing it comes first.
2. Close each issue that the pull request answered and its keyword left open, as
   `CONTRIBUTOR.md`, section "Every delegate begins here", describes.
3. Remove the worktree and the local branch of the merged pull request.
4. If the merge changed the charter or the checker, run `/sync` on each of your open branches.
5. Take your next item with `/triage`.

If this file and the charter disagree, the charter wins.
