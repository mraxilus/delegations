---
name: sync
description: Bring main into your branch after the charter or checker moved, then re-stamp
when_to_use: The drift line or check-drift reports drift, or your branch conflicts with main
---

# Sync

Use this when `main` has rules or checker code that your branch does not have yet.

1. Follow the `check-drift` steps in `CONTRIBUTOR.md`, under "Before you open a pull request".
   Curators also follow duty 1 in `CURATOR.md`.
2. If a Rules row conflicts during the merge, keep either version. The re-stamp rewrites the
   row anyway.
3. Push the way `/steward` describes.

If this file and the charter disagree, the charter wins.
