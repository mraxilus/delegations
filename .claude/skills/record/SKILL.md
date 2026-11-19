---
name: record
description: Write the record of a design change as the design now is, then have it reviewed
when_to_use: You change a design, or you are about to edit a PROVENANCE.md
---

# Record

Use this when a design changes, before you commit its record.

1. Write the record as `GUIDE.md`, section "Provenance guide", describes.
2. Push the draft as soon as `nim r koch check` passes. Before the pull request goes ready, give
   the diff to a `reviewer` subagent, and weigh its report. Its prompt names `GUIDE.md`,
   Provenance guide, section "Prune, never narrate", and `CONTRIBUTOR.md`, section "Tests are
   paramount". Push the mends that the review asks for with no second review.

If this file and the charter disagree, the charter wins.
