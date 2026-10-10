# assayer

Assayer runs each test file under each configuration of its testament header, and all the runs
go in parallel. Each run is one compile with a cache of its own. The report names the file, the
backend and the configuration of each run, and any failure gives exit code 1.

Testament runs the configurations of one file one after another. It runs in parallel only across
category folders, under `testament all`. So a project here keeps one stub for each configuration
(STYLE.md §6). With assayer, one file can list all its configurations, and they still run at the
same time.

Authority replicated: none. Assayer reads a header, builds a command and judges a run as
testament does at the pin of this project. The reference is the source of testament 2.2.12, in
`testament/specs.nim` and `testament/testament.nim`.

## Use

```sh
assayer [--jobs:n] [--nim:path] file...
```

- A header gives four keys: `action`, `cmd`, `matrix` and `targets`. Any other key refuses the
  file. Testament reads keys such as `output` and `exitcode`, so a run that skips them could pass
  where testament fails.
- A file without a header asks for the defaults of testament. They are the action `run`, the
  default command, one configuration with no options, and the C backend.
- Each backend runs under each configuration. A run compiles into its own folder under
  `nimcache/assayer` in the working directory, so no two runs share a cache. The next run of the
  same configuration finds its cache again.
- `--jobs` sets how many runs go at once. The default is one run for each processor.
- The compiler is the one that `--nim` names. If `--nim` names none, it is the compiler of the
  pin of the nearest nimble file above the file, which the toolchain of knoller serves. If no
  nimble file names a pin, it is `nim` on PATH.
- A pin that no compiler serves refuses the file. No other compiler takes its place.
- The output gives each refused file first, then each run in the order of the plan, then the
  count. A failed run shows the command and the output of the step that failed, indented.
- Exit 0 means that every run passed. Exit 1 means that a run failed, or that assayer refused a
  file. Exit 2 is a usage error.

The PGA library, with one test file that lists its 8 configurations, gives this report:

```text
tests/test_configurations.nim c `-d:pga.dimensions=2 -d:pga.is_conformal=false`: passed
tests/test_configurations.nim c `-d:pga.dimensions=3 -d:pga.is_conformal=false`: passed
tests/test_configurations.nim c `-d:pga.dimensions=4 -d:pga.is_conformal=false`: passed
tests/test_configurations.nim c `-d:pga.dimensions=5 -d:pga.is_conformal=false`: passed
tests/test_configurations.nim c `-d:pga.dimensions=3 -d:pga.is_conformal=true`: passed
tests/test_configurations.nim c `-d:pga.dimensions=4 -d:pga.is_conformal=true`: passed
tests/test_configurations.nim c `-d:pga.dimensions=5 -d:pga.is_conformal=true`: passed
tests/test_configurations.nim c `-d:pga.dimensions=6 -d:pga.is_conformal=true`: passed
8 runs: 8 passed, 0 failed.
```

## Build and test

```sh
nim r koch check                 # from repository root: every check a pull request runs
nim r koch test curator/assayer  # this project alone
nim c -d:release -o:binaries/assayer curator/assayer/src/assayer.nim  # command line
```

This needs the compiler that the project pins in `assayer.nimble`, and git. Assayer imports
`curator/knoller` by a relative path, so it builds from a checkout of this repository. The suites
run real processes through a POSIX shell, so they run on Linux and macOS.

## Published pages

None.

## Status

The suites hold each rule of the header, the plan, the verdict and the report. No verb of koch
calls assayer yet, and that is a decision for later. Unreviewed by a human.
