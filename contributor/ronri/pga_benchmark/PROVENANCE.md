# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude Fable 5.1 |
| Date   | 2026-09-13 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 3497e71b8d327cfa |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: the Architect audited `pga` (head `0bc4655`) in the session that opened this
project, measuring a dense-representation cost of about nine times a hand-written sparse
product at 4D, zero-filled temporaries on every operator chain, no cross-module inlining,
per-term error-flag checks, dead compile-time Cayley work and conformal norms returning NaN.
This project turns that audit into a standing instrument: the gap list the Architect reads
while improving the library, and the benchmark plus C inspection that shows nothing
regressed. Authority replicated: Lengyel's equations, through the library's own suites and
through the typed reference here. No vendored source.

## Dependencies

**The PGA library is a pinned dependency, never a copy.** It lives in [replications], which
carries no nimble file and holds the library three directories inside it, so the
requirement in `pga_benchmark.nimble` names the repository by URL and commit, `atlas.lock`
records the resolved commit `0bc465509d1c93b6bec3ced25aa29f080a2cf110`, and `nim.cfg` names
the subdirectory Atlas restores it to. That commit is the library's head on 2026-09-12, as
the Architect's standing instruction asks. Both projects are Prosperity Public License
3.0.0. Rejected: copying the library in, which Article XI.3 forbids.

**The compiler is pinned by commit**, `27763495bcfe265507ca98aedc1c7064bf1e0e4d`, the same
pin `rga_visualiser` carries, because the library spells seven operators with characters no
Nim release lexes. One cached build therefore serves both projects. Atlas writes
`"objects": {}` for a repository without a nimble file, so the resolved commit is patched
into `atlas.lock` by hand, and the lock's stored copies of the nimble file and `nim.cfg`
are kept byte-identical to the committed files, which the static pass checks.

*Checked.* Assumed: every claim here, until the suites first run on the pin.

## Open questions

None yet.
