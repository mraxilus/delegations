# curator

Curator projects: one folder for each project directly under this one, with any name that
matches `[a-z][a-z0-9_]*`. `audit` is the tooling that checks the whole repository. `probe`
is the domain-neutral test project that exercises every mechanism the audit enforces. Each
project carries README.md, PROVENANCE.md, GLOSSARY.md, `<project>.nimble` and `tests/`.

Work on a project from branch `curator/<project>/<name>`. Work on the rules and the root
files from `curator/<name>`. See [CURATOR.md](../CURATOR.md).
