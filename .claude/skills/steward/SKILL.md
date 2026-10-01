---
name: steward
description: Drive a pull request of this repository to green and ready, by its own rules
invokeAs: claude
---

# Steward

This skill points at the rules, and repeats none of them. The harness reads it when it drives
a pull request of this repository.

1. Read `CLAUDE.md`, then the prompt of your role, `CONTRIBUTOR.md` or `CURATOR.md`, section
   "Before you open a pull request". Those sections bind, and this file does not.
2. `nim r koch check` at the repository root passes on the exact commit you push, and again
   before every later push. The `pre-push` hook refuses a push whose tree it did not pass on.
3. Open as a draft, and mark it ready only when the runner is green, every review comment is
   answered, and nothing is left to change. A push to a ready pull request returns it to
   draft, by the `draft` workflow. Mark it ready again after.
4. Every comment opens with the role line of your branch and ends with the footer, and the
   `body` hook refuses one that does not. Write Simplified Technical English (`GUIDE.md`).
5. Never rewrite pushed history, never merge, and never weaken a test to pass (`CLAUDE.md`).
6. A turn that pushed or posted ends with the sign-off block (`GUIDE.md`, Output contract).
7. Wait by backoff, never by a fixed short interval (`GUIDE.md`, The queue and the shared
   allowance).
