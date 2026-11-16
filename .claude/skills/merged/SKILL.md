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
3. Remove the worktree of the merged pull request. A contributor keeps its merged branch checked
   out until its next item starts, so that the app shows its latest work. The next item starts
   its branch from `main`, and removes the merged one. The root curator removes the local branch
   at once, and keeps `main` detached (`CURATOR.md`, Branch and commits).
4. A curator also reads each branch on GitHub for one that is merged and not deleted, as
   `CURATOR.md`, duty 12, says.
5. If the merge changed the charter or the code of the stamp, run `/sync` on each of your open
   branches.
6. Take your next item with `/triage`.

If this file and the charter disagree, the charter wins.
