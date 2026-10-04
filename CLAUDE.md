# How to work in this repository

A model writes every line here, under the direction of the Architect. Before any change:

1. Read `CONSTITUTION.md`, `STYLE.md`, then `GLOSSARY.md`.
2. Find your role from your branch or your opening prompt. `curator/<name>` and
   `curator/<project>/<name>` follow `CURATOR.md`. `contributor/<domain>/<project>/<name>`
   follows `CONTRIBUTOR.md`, and writes only under `contributor/<domain>/<project>/`. The
   `coordinator` follows `COORDINATOR.md`, holds no branch, and writes no file. All then read
   `GUIDE.md`. A branch that a tool named for you (`claude/...`) is outside the grammar, so
   push to one inside it.
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
