# curator

Curator projects: one folder for each project directly under this one, with any name that
matches `[a-z][a-z0-9_]*`. `audit` is the tooling that checks the whole repository. `probe`
is the domain-neutral test project that exercises every mechanism the audit enforces. Each
project carries README.md, PROVENANCE.md, GLOSSARY.md, `<project>.nimble` and `tests/`.

`knoller` holds the fixers of `koch fix` and the checks of the static pass that read one file
alone. It holds the compiler that serves each pin too. `audit` imports it by a relative path.

`assayer` runs each test file under each configuration of its testament header, with all the
runs in parallel. It imports knoller by a relative path too, for the compiler of each pin.

Work on a project from branch `curator/<project>/<name>`. Work on the rules and the root
files from `curator/<name>`. See [CURATOR.md](../CURATOR.md).
