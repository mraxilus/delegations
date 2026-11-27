---
name: sync
description: Read each change of the charter or stamp code, merge main, and re-stamp where it moved
when_to_use: The drift line or check-drift reports drift, or your branch conflicts with main
---

# Sync

Use this when `main` has rules or code of the stamp that your branch does not have yet, or when
your branch conflicts with `main`. A change of the checker alone needs no merge, since
`koch check` judges your branch as merged with `main`.

1. Follow the `check-drift` steps in `CONTRIBUTOR.md`, under "Before you open a pull request".
   Curators also follow duty 1 in `CURATOR.md`.
2. Resolve each conflict hunk by hunk, so that the merge keeps each change of both sides. Never
   take one side of a whole file, as `git checkout --ours` does. Where the `Rules` row of a
   record conflicts, keep either version of that row alone. Then run `nim r koch stamp --write`,
   which writes the row that the merged charter gives.
3. Push the way `/steward` describes.

If this file and the charter disagree, the charter wins.
