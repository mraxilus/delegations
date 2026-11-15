# How to work in this repository

A model writes every line here, under the direction of the Architect. This file is the entry
file, which each harness reads first. Before any change:

1. Find your role from your branch or your opening prompt. `curator/<name>` and
   `curator/<project>/<name>` follow `CURATOR.md`. `contributor/<domain>/<project>/<name>`
   follows `CONTRIBUTOR.md`, and writes only under `contributor/<domain>/<project>/`. The
   `coordinator` follows `COORDINATOR.md`, holds no branch, and writes no file. A branch that a
   tool named for you (`claude/...`) is outside the grammar, so push to one inside it.
2. Then read the section Read first of the file of your role, and follow its order. That section
   is the one reading order of each role.
3. Run `nim r koch check` at the repository root before every push. It must pass.
4. Open your own pull request as a draft when `koch check` passes, and label it with your role.
   Drive it green. The Architect merges it.
5. Never commit to `main`. Never write outside your scope. Never weaken a test to pass.
6. Comments are telegraphic. Markdown, issues, pull requests and messages are Simplified
   Technical English, and `GUIDE.md` gives the rules. A glossary term is proposed, and never
   written on sight.
7. The shared folder of the project holds only files that someone still needs.
   `CONTRIBUTOR.md`, Boundaries, gives the rule.
8. A record describes what is, and never narrates what happened. The reason a design is as
   it is belongs in the record. A list of events does not.
9. Sign off when you are done, blocked or waiting, and when a pull request goes ready, with
   the block that `GUIDE.md`, Output contract, gives. Any other turn that pushed or posted while
   work goes on ends with the working line that the same section gives.

## Under another harness

Claude Code reads this file through the import in `CLAUDE.md`, and runs the hooks of
`.claude/settings.json`. Each hook calls one verb of koch, and holds a rule before an act lands.
A harness without these hooks gets two of them by other means:

- **The start context.** Run `nim r koch hook start < /dev/null` at each start, at each resume
  and after each compaction. It prints what the start hook prints under Claude Code. That is your
  role, the reading order of your role, the headings of your record and the carried list. It
  also names each change to the charter or the checker since your branch forked.
- **The git hooks.** Each verb of koch sets `core.hooksPath` to `.githooks`, so git runs these
  hooks after the first run of koch. They refuse a commit whose subject breaks the rules, and a
  push of a tree that `koch check` did not pass. So they hold a harness that commits or pushes
  on its own too.

Under such a harness, reading holds each other rule of a hook. `curator/audit/PROVENANCE.md`,
Hooks on tool calls, lists each one.
