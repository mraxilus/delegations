# curator

Curator projects: one folder per project directly under this one, any name matching
`[a-z][a-z0-9_]*`. `audit` is the tooling that checks the whole repository; `probe` is the
domain-neutral test project that exercises every mechanism the audit enforces and serves as
the target of merge-process probes. Each project carries README.md, PROVENANCE.md,
GLOSSARY.md, `<project>.nimble` and `tests/`.

Work on a project from branch `curator/<project>/<name>`; work on the rules and root files
from `curator/<name>`. See [CURATOR.md](../CURATOR.md).
