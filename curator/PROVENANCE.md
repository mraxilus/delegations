# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-05 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 0c52eec980425fef |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: built from the owner's brief for the repository, the constitution, the Nim style
guide and the provenance guide, all supplied by the owner. No vendored source.

## Enumeration

**Git decides what the tree is.** `tree.nim` lists `git ls-files -z --cached --others
--exclude-standard`, drops paths absent from disk, and reads content only for registered
kinds. Rejected: walking the directory, which sees build products and needs its own ignore
logic. Rejected: `execCmdEx`, which reads by line and appends a newline to NUL-separated
output; git runs as a direct process with an argument list, so no shell quoting exists.
Cost: git must be on PATH. Verified by test `ttree.nim` on a throwaway repository: ignored
`bin/` absent, untracked file present, `síncopa` path unquoted, rename shows as its
destination only because the source never reached the base.

## File kinds

**An allow-list of nine kinds is the registry, and an unregistered kind is a finding.**
`kinds.nim` maps basename or extension to comment syntax, whether prose is checked, and
whether a leading tab is allowed. Markdown is registered as prose, not comment, so articles
in documents pass while form rules still apply; the constitution itself uses articles.
TypeScript and JSON are registered ahead of use because the owner allows TypeScript where
JavaScript is forced. Rejected: content sniffing, which would let an unknown kind in
silently. Cost: `.mk` or `Makefile.inc` is unread until registered. Verified by
`tlayout.nim`: `data.csv` yields one finding naming `kinds.nim`.

## Comment extraction

**Five hand-written scanners, one per-line accumulator.** Nim: line, doc, nesting block
comments, plain, triple and generalized raw strings, char literals, numeric suffix quotes.
Makefile: `#` anywhere unless `\#`. YAML: `#` at line start or after whitespace,
outside quotes. Ignore files: leading `#` only. TypeScript: `//`, `/* */`, three string
forms, documentation stars stripped. Whitespace runs collapse so texts compare stably.
Rejected: real parsers, which cost dependencies for a question (where do comments begin)
that needs no syntax tree. Cost, assumed: TypeScript regex literals containing `//` open
a false comment until a fixture lands. Verified by `tcomments.nim`, 23 assertions across
the five syntaxes, including the testament header string.

## Prose

**Articles are the whole rule, as data.** `ARTICLES = ["a", "an", "the"]`; tokens are
whitespace-split, punctuation-stripped, lowercased, after backtick spans are removed.
Verified by `tprose.nim`: 300 seeded random telegraphic comments pass and each with one
inserted article fails; citations `2.2a`, URLs and underscored names pass. Cost, verified
during this build: label `A` as in "Appendix A" is flagged; the header of `prose.nim`
tripped on its own example and now writes the label in backticks.

## Form

**Width is counted in runes, tabs are rejected except make recipes, CR is a finding, and a
file ends with exactly one newline.** Lines are split on LF only so CR survives; `splitLines`
was rejected because it swallows CRLF. `LICENSE.md` is width-exempt because third-party text
stays verbatim. Nim banners `#[ Title ]#` need two blank lines before and one after; tiers
are unmarked in syntax, so the second-tier minimum is demanded of every banner. Assumed, not
checked: two-space indent. Verified by `tform.nim`: 100 `é` pass, 101 fail; recipe tab
passes, inner tab fails; every ending case.

## Layout

**Root entries, project files and domain views are lists, and the check derives every rule
from them.** A project is `curator` or `<domain>/<project>` and must hold README.md,
PROVENANCE.md, GLOSSARY.md, a Makefile with a `check` target, and at least one file under
`tests/`. Root README.md must carry one table row per domain equal to `DOMAINS`; each
domain README must open with the domain name and hold the theme line. Rejected: letting
domain READMEs list projects, which would force a contributor to edit outside their prefix.
Cost: empty directories are invisible to git, so `tests/` must hold a file. Verified by
`tlayout.nim` over a fixture tree the tests build; `taudit.nim` proves that fixture is clean
under every static check.

## Provenance stamp

**FNV-1a 64-bit over CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md, CR stripped, NUL
between files, 16 lowercase hex digits.** Rejected: `std/sha1` (deprecated in Nim 2, warns
on every build), the `checksums` package (a nimble install in CI for one digest),
`std/hashes` (unstable across Nim versions). CURATOR.md is excluded so curator-only edits
touch no project. Cost: a change detector, not a signature; collision needs an adversary.
Verified by `tprovenance.nim`: determinism, one-byte sensitivity, order sensitivity, boundary
sensitivity, CRLF invariance; and by `taudit.nim`: one byte in any rules document goes
stale in every project, one byte in CURATOR.md in none.

## Glossary

**Shape only: heading, `## Language`, and a definition line after every `**Term**:`.**
Content is the contributor's and owner's. Zero terms pass, because the format creates
entries lazily. Verified by `tglossary.nim`.

## Scope

**Branch grammar is exactly three segments, and curator branches pass every path.** `main`
passes because pushes to it are merges the owner approved. Cost: the owner may merge red
deliberately; the check is a guard, not a gate. Verified by `tscope.nim` over all five
domains and `tdomains.nim` over 13 rejected branch forms.

## Commits

**`type(scope)!?: summary` with eleven types as data; on a contributor branch the scope
must equal the project.** A curator branch accepts any valid scope, because propagating a
rules change commits under each project's scope. A branch outside the grammar still gets
format checking, so this first setup branch, named by the harness rather than the grammar,
shows one red job (`scope`) and not two. Cost: imperative mood is unverified. Verified by
`tcommits.nim`: every type with three scopes, the breaking marker, and 11 rejected forms.

## Project runner

**`make -C <project> check`, serially, output streamed.** Failure is a finding at the
project's Makefile echoing the exit code. Cost: serial; parallelism waits until it costs
minutes. Verified by `tprojects.nim` with a passing and a failing fixture project.

## Tests

**Testament over `tests/t*.nim`, each stub carrying the header from STYLE.md §6 without
`-r`.** Testament runs each binary itself; `-r` in the command would run every test twice
and `--outdir` breaks testament's search for the binary, so binaries sit beside sources and
git ignores them. Suites are named after constitution articles and every assertion carries
a citation. Fixtures are built by `fixtures.nim`: a smallest clean tree, and throwaway git
repositories. Verified: 12 test files, all passing on Nim 2.2.4 Linux amd64.

## Continuous integration

**Three jobs, so the owner reads each verdict alone.** `audit` runs `make check`; `scope`
and `commits` run only on pull requests with full history and pass the branch name through
the environment, never interpolated into the script. Nim is pinned once as
`NIM_VERSION`. The setup action installs Nim under the runner's temp directory
(`parent-nim-install-directory`), never into the workspace, and `.gitignore` also lists
`.nim_runtime/`: the audit reads untracked files, so a toolchain inside the checkout is
audited as source. Verified by the first run on `main`, which reported 33,367 findings in
Nim's own tree before either guard existed, and by reproducing locally with a fake
`.nim_runtime/` file. Verified on pull request 1: `scope` and `commits` jobs green, so
`nim` reaches PATH. Assumed until the next `audit` job passes: `testament` reaches PATH
the same way. Required checks are named `audit`, `scope`, `commits` for branch protection.

## Figures

`audit tree` over this repository at its first commit: 0.02 s wall, three consecutive runs
(0.022, 0.021, 0.021), bash `time`, Linux amd64 container with four Xeon 2.80 GHz cores,
Nim 2.2.4 default build, 2026-09-05. Whole `make check`: 17 s, dominated by twelve testament
compiles. No optimisation is claimed, so no before-and-after pair exists. Re-measure when the
tree grows past a few hundred files or a check gains a second pass; otherwise treat as
unmeasured.
