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
  `nimcache/assayer` in the working directory, such as `tests/test_k/c_2` for the second
  configuration of `tests/test_k.nim`. So no two runs share a cache, and the next run of the same
  configuration finds its cache again.
- `--jobs` sets how many runs go at once. The default is one run for each processor.
- The compiler is the one that `--nim` names. If `--nim` names none, it is the compiler of the
  pin of the nearest nimble file above the file, which the toolchain of knoller serves. If no
  nimble file names a pin, it is `nim` on PATH.
- A pin that no compiler serves refuses the file. No other compiler takes its place.
- Exit 0 means that every run passed. Exit 1 means that a run failed, or that assayer refused a
  file. Exit 2 is a usage error, and `--help` prints the usage.

## Output

The report goes to stdout, in this order:

1. An `error:` line for each refused file, with the reason.
2. A line that says how many runs start, of how many files, and how many at once.
3. A line for each run, in the order of the plan. The status `PASS` or `FAIL` comes first, then
   the duration, the file, the backend and the configuration, each in its own column.
4. A block for each failed run: the reason, an excerpt of the output, the command that runs the
   failed step again, and the log.
5. A line that counts the runs, the time, the passed runs, and the failed runs and refused files.

- The excerpt drops compiler hints, progress dots, stack frames outside the working directory,
  and the tests that passed or that the suite skipped. Then it keeps the last 20 lines. The log
  beside the program holds the whole output of each step.
- Each path below the working directory prints relative to it.
- Color marks the status, the reasons and the count, on a terminal alone. `NO_COLOR` turns it
  off and `FORCE_COLOR` turns it on, and the text reads the same without it.
- A usage error prints its reason and the synopsis on stderr.

The PGA library, with one test file that lists the 8 configurations of its stubs, gives this
report:

```text
Starting 8 runs of 1 file, 4 at once
PASS   3.9s  tests/test_configurations.nim  c  -d:pga.dimensions=2 -d:pga.is_conformal=false
PASS   3.7s  tests/test_configurations.nim  c  -d:pga.dimensions=3 -d:pga.is_conformal=false
PASS   4.7s  tests/test_configurations.nim  c  -d:pga.dimensions=4 -d:pga.is_conformal=false
PASS   5.5s  tests/test_configurations.nim  c  -d:pga.dimensions=5 -d:pga.is_conformal=false
PASS   3.7s  tests/test_configurations.nim  c  -d:pga.dimensions=3 -d:pga.is_conformal=true
PASS   3.9s  tests/test_configurations.nim  c  -d:pga.dimensions=4 -d:pga.is_conformal=true
PASS   5.1s  tests/test_configurations.nim  c  -d:pga.dimensions=5 -d:pga.is_conformal=true
PASS  11.2s  tests/test_configurations.nim  c  -d:pga.dimensions=6 -d:pga.is_conformal=true

8 runs in 16.8s: 8 passed
```

A file with three configurations, where the second fails a check, gives this report:

```text
Starting 3 runs of 1 file, 3 at once
PASS   1.8s  tests/test_matrix.nim  c  -d:k=1
FAIL   1.8s  tests/test_matrix.nim  c  -d:k=2
PASS   1.8s  tests/test_matrix.nim  c  -d:k=3

FAIL tests/test_matrix.nim c -d:k=2: program exits 1
    [Suite] Ring
        tests/test_matrix.nim(10, 12): Check failed: k != 2
        k was 2
      [FAILED] k is not two
  rerun: nimcache/assayer/tests/test_matrix/c_2/test_matrix
  log: nimcache/assayer/tests/test_matrix/c_2/output.log

3 runs in 1.8s: 2 passed, 1 failed
```

The report follows the patterns that test runners with a good name share, such as nextest, pytest
and testament. `PROVENANCE.md`, Report, gives each pattern and its source.

## Build and test

```sh
nim r koch check                 # from repository root: every check a pull request runs
nim r koch test curator/assayer  # this project alone
nim c -d:release -o:binaries/assayer curator/assayer/src/assayer.nim  # command line
```

This needs the compiler that the project pins in `assayer.nimble`, and git. Assayer imports
`curator/knoller` by a relative path, so it builds from a checkout of this repository. The suites
run real processes through `/bin/sh`, so they need a POSIX system, and CI runs them on Linux.

## Published pages

None.

## Status

The suites hold each rule of the header, the plan, the verdict and the report. No verb of koch
calls assayer yet, and that is a decision for later. Unreviewed by a human.
