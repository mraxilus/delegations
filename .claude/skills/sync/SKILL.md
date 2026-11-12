---
name: sync
description: Read each change of the charter or checker, merge main, and re-stamp where it moved
when_to_use: The drift line or check-drift reports drift, or your branch conflicts with main
---

# Sync

Use this when `main` has rules or checker code that your branch does not have yet.

1. Follow the `check-drift` steps in `CONTRIBUTOR.md`, under "Before you open a pull request".
   Curators also follow duty 1 in `CURATOR.md`.
2. If a Rules row conflicts during the merge, keep either version. Then run
   `nim r koch stamp --write`, which writes the row that the merged charter gives.
3. Push the way `/steward` describes.

If this file and the charter disagree, the charter wins.
