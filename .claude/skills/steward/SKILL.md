---
name: steward
description: Drive a pull request of this repository to green and ready, by its own rules
invokeAs: claude
---

# Steward

The harness reads this file when it drives a pull request of this repository.

1. Follow the section "Before you open a pull request" of your role's prompt, `CONTRIBUTOR.md`
   or `CURATOR.md`. It covers `koch check` before each push, draft and ready, and the backoff.
2. End each turn with `/sign-off`.

If this file and the charter disagree, the charter wins.
