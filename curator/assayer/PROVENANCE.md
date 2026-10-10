# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-10 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | dc2f80918195f3c9 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a curator project, from the brief of the Architect. It runs each test file under each
configuration of its testament header, and all the runs go in parallel. There is no vendored
source.

The reference for each rule of testament is its source at the pin of this project, Nim 2.2.12.
The header comes from `testament/specs.nim`, and the command and the verdict come from
`testament/testament.nim`.

## Package

**Assayer imports knoller by a relative path, as `curator/audit` does.** Knoller holds the
toolchain that serves each pin (`compilers.nim`) and the reader of a pin (`pins.nim`). Assayer
imports those two modules and no other.

- Rejected: a copy of the toolchain code. Two copies of one fetch drift apart.
- Cost: the pin of assayer is the pin of knoller, which is the pin of `curator/audit`.
- Cost: no install of the package carries knoller, so assayer builds from a checkout of this
  repository alone.
- Cost: a change to knoller selects `curator/audit` and knoller for test, and not assayer
  (`plan.nim` of the audit). A change to knoller that breaks assayer shows at the next change
  to assayer, or in the weekly run.

**Assayer finds the nearest nimble file itself.** Knoller keeps its own lookup private, in its
command line. The two lookups follow one rule: the nearest folder that holds a nimble file
decides, and a folder of two nimble files gives no pin.

## Headers

**A header gives four keys, and assayer refuses any other.** The keys are `action`, `cmd`,
`matrix` and `targets`, which the stubs here use. Testament also reads keys such as `output`,
`exitcode` and `disabled`. If assayer ignored them, a run could pass here and fail under
testament. So such a key refuses the file, and the message names the key. Verified by
`suites/test_headers.nim`, over each combination of the four keys.

**Assayer finds the header as testament finds it.** The header is the text between
`discard """` and the next `"""`. The opening counts only where no space stands before it, and
only on one of the first 10 lines. A second opening anywhere in the file refuses the file, and
so does an opening that never closes. Inside the header, `'''` reads as `"""`. Verified by
`suites/test_headers.nim`.

**Each key and each value reads as testament reads it.** `std/parsecfg` parses the header, and
each key is normalized, so `Action` and `tar_gets` count. `target` is another name for
`targets`, and each word of the value adds one backend, `c++` among them. A key given twice
refuses the file, where testament stops on an assertion. Verified by `suites/test_headers.nim`.

**`matrix` splits at each semicolon, and each configuration is stripped.** An empty
configuration stays, as testament keeps it, and it runs with no options. Verified by
`suites/test_headers.nim`.

**A file without a header asks for the defaults of testament.** The action is `run`, and the
command is the default command of testament, word for word. There is one configuration with no
options, and the backend is C. Verified by `suites/test_headers.nim`.

- Rejected: a default command without `--nimblePath:build/deps/pkgs2`, which names the layout of
  the Nim repository. A changed default would let a file pass here and fail under testament.
- Cost: assayer reads no inline error marker of testament (`#[tt.`), and no
  `NIM_COMPILE_TO_CPP`. A reject run checks the file of its last error alone, and the default
  backend stays C.

## Plans

**Each backend runs under each configuration, in the order of testament.** The runs go
configuration by configuration, and each configuration takes every backend in turn. Verified by
`suites/test_plans.nim`, over every set of backends and up to three configurations.

**The command is the template of the header, filled as testament fills it.** A leading `nim `
becomes the compiler. Then `$target`, `$options`, `$file`, `$filedir` and `$nim` take their
values. Assayer quotes the compiler for the shell, where testament writes it bare. A `$` that
names nothing else refuses the run. Verified by `suites/test_plans.nim`.

**A `$` name that testament does not fill refuses the file before any run.** Each run of the
file would fail the same way, so one line says it once, and it names the `$` name. `$$` is a
dollar sign, and `${name}` reads as `$name`, as `strutils.%` reads them. Verified by
`suites/test_plans.nim`.

**The rerun of a compile is its command without the cache and the program of the run.** A
person reruns one configuration by hand with it, and a run of spaces outside quotes becomes one
space. The log keeps the command as it ran. Verified by `suites/test_plans.nim`.

**The options of a run come before its configuration, so the configuration speaks last.** The
options are the default of the backend, then `--nimCache` and `--out` of the run. The default of
JavaScript is `-d:nodejs`, as in testament. A `--backend` or `-b` in a configuration moves the
run to that backend, as testament moves it. Verified by `suites/test_plans.nim`.

- Cost: a configuration that names its own `--out` or `--nimCache` moves the program or the
  cache. The run then cannot find the program, and fails with its path in the message.

**Each run compiles into a folder of its own, so no two runs share a cache.** The folder is
under `nimcache/assayer` in the working directory, and git ignores it. Its path is the path of
the file without its extension, then the backend and the place of the configuration. The place
counts from one, so the second configuration of `tests/test_k.nim` is `tests/test_k/c_2`. The
report shows a path that says what the folder holds, and the next run of a configuration finds
its cache again. Verified by `suites/test_plans.nim`.

A file outside the working directory takes its name and a hash of its absolute path, so no
folder climbs out of `nimcache/assayer`. Verified by `suites/test_plans.nim`.

- Rejected: one cache for each file and backend, as testament has it. Testament runs the
  configurations one after another, so no two write the cache at the same time. Here they do.
- Rejected: a temporary folder for each start of assayer, which loses each cache at the end.
- Cost: the program lands in the folder of its run, and not beside the test file. A test that
  reads files beside its own program (`getAppDir`) reads the cache instead. No test here does,
  verified by `git grep` on 2026-10-10.

**A JavaScript run goes under Node.js, as testament runs it.** The command is
`node --unhandled-rejections=strict` and the script. If no Node.js is on PATH, the run is
refused before its compile. Verified by `suites/test_plans.nim`. Assayer looks for `nodejs`
first, then `node`, in the order of `compiler/nodejs.nim` of Nim 2.2.12, and no test holds
that order.

## Runs

**Threads make the runs, and two channels carry the work.** One channel carries each run with
its place in the plan, and the other carries each outcome back. A channel copies the value
whole, so no thread frees memory of another. The threads are `--jobs` at most, and never more
than the runs. Verified by `suites/test_runs.nim`.

- Rejected: `execProcesses` of `std/osproc`. It reads no output until a process ends. A process
  that writes more than its pipe holds then waits forever, and so does the run.

**Each command starts and closes under one lock.** The pipe of a child process carries no
close-on-exec flag. So a child that another thread starts at the same time inherits the write end
of that pipe, and the reader waits for both children. The input of each child closes under the
lock for the same reason. Read in `std/osproc` of Nim 2.2.12 on 2026-10-10.

With stderr joined to stdout, `close` of `std/osproc` frees one descriptor twice. A pipe that
another thread opens between the two would lose its descriptor, so each process closes under the
lock too. Read in `std/osproc` of Nim 2.2.12 on 2026-10-10.

**No command takes a working folder of its own.** On POSIX, the spawn of `std/osproc` gives a
working folder by a change of the folder of the whole process. Every other thread would see that
change. So each path that a run holds is absolute, and each command runs from the working folder
of assayer. Read in `std/osproc` of Nim 2.2.12 on 2026-10-10.

**Each output is read to its end before the exit is waited on.** So a pipe never fills and
stops its child. Stderr joins stdout, as in testament. Verified by `suites/test_runs.nim`, where
four runs on two threads each print more lines than a pipe holds.

**The compile runs through the shell, and the program runs without one.** The command is shell
text, as in testament. Assayer deletes the program of an earlier run before the compile. So a
compile that writes no program fails the run, and no old program runs. Verified by
`suites/test_runs.nim`.

**The verdict of each run is the verdict of testament.**

- `run` passes where the compile exits 0 and prints no error, and the program then exits 0.
- `compile` passes where the compile exits 0 and prints no error.
- `reject` passes where the compile exits 1, and its last error names the test file.

An error is a line that testament reads as one: `<file>(<line>, <column>) Error:`, else a line
that opens with `Error:`. Verified by `suites/test_runs.nim`, over every action, three exit
codes of the compile, four kinds of error and three outcomes of the program.

**Each step records its duration on a monotonic clock, for the report alone.** No verdict reads
it, so no limit on time decides a run (Article IX.12). Verified by `suites/test_runs.nim` for the
sum of the steps.

**The outcomes arrive in any order, and the report releases them in the order of the plan.**
Each outcome goes out as soon as every run before it has one. So the report prints the same
lines in the same order each time. Verified by `suites/test_runs.nim`, over every order of
arrival of four runs.

- Cost: a run that never ends holds its thread forever, since no limit on time decides a
  verdict (Article IX.12).

## Command line

**The compiler of a file comes from the pin of its project.** `--nim` names the compiler of
every run. Otherwise the nearest nimble file at or above the file names a pin, and the toolchain
of knoller serves it from PATH, cache or fetch. If no nimble file names an exact pin, the
compiler is `nim` on PATH, as in testament. Verified by `suites/test_command.nim`, with a pin
that PATH serves and a pin that the cache serves.

**A pin that no compiler serves refuses the file, and so does a folder of two nimble files.** No
other compiler takes the place of the pin (`GUIDE.md`, Toolchain). Nimble refuses a folder of
two nimble files, so no pin there can be trusted. Verified by `suites/test_command.nim` for the
folder. A pin that nothing serves asks for a fetch, so no suite holds that refusal.

**A usage error says what is wrong, then the synopsis, on stderr, and exits 2.** The form is
that of `clap`, the argument parser of cargo: an `error:` line, the synopsis, and a pointer to
`--help`. `--help` prints the usage on stdout and exits 0. Exit 1 means that a run failed or
that assayer refused a file. Verified by `suites/test_command.nim` for each message.

**Color goes on where stdout is a terminal, unless `NO_COLOR` holds text.** `FORCE_COLOR` turns
it on for a pipe, and `TERM=dumb` turns it off, in the order of no-color.org and
force-color.org. Verified by `suites/test_command.nim`, over each combination of the four inputs.

**A file named twice, by any path, runs once.** Two runs of one configuration would share one
cache. Verified by `suites/test_command.nim`.

## Report

**The report follows the patterns that test runners with a good name share.** The sources are
the guidelines at clig.dev, and the reports of cargo-nextest, pytest, Jest, gotestsum, RSpec and
testament, read on 2026-10-10. Each choice below names its source.

- **The status comes first, in a fixed column**, as in nextest, gotestsum, Jest and testament.
  The eye scans the first column, and `FAIL` finds each failure in a log, as testament intends
  its `FAIL:`. The status is a word and not a symbol, so the text reads the same without color.
- **The duration, the file, the backend and the configuration align in columns.** The widths
  come from the plan, so the columns align from the first line. Nextest and testament also pad
  the duration.
- **A line at the start says what starts**, as nextest prints `Starting`. Clig.dev asks for
  output inside 100 ms.
- **The detail of each failure comes after the list of runs**, as in pytest, Vitest and RSpec.
  The list stays one line for each run, and what explains a failure stands last, where clig.dev
  says the eye ends.
- **The excerpt is short, and the log on disk is whole**, as in nextest, pytest and gotestsum.
  The excerpt drops hints, progress dots, frames outside the working directory and tests that
  passed, then keeps the last 20 lines.
- **A failure gives the command that reruns its step**, as RSpec, cargo and nextest give one.
- **One line closes the report with the counts and the total time**, as in nextest, pytest and
  gotestsum.
- **A message has the form of rustc**: `error:`, then lowercase words with no period.
- **The lines keep the order of the plan**, as go keeps the order of its packages. So the same
  run gives the same lines in the same order.

Each line form is verified by `suites/test_reports.nim`, and the whole report by
`suites/test_command.nim` on real runs.

- Rejected: the detail of each failure under its run line, as nextest prints it by default.
  Several failures break the list apart, and the end of the report holds only the last one.
- Rejected: a list of failures before the count, as pytest prints one. The blocks of failure
  already stand last.
- Rejected: symbols such as a check mark for the status. A log without color, or a font without
  the symbol, loses them.
- Rejected: a progress bar, which needs a terminal and a timer. The start line and the lines in
  plan order already show progress.
- Cost: a slow early run holds back the lines of runs that end before it.
- Cost: an excerpt of 20 lines can cut the first of several failed tests in a long output. The
  excerpt says how many lines it cut, and the log holds them.
- Cost: two reports of one run differ in their durations, and never in their verdicts.

## Tests

**One stub runs every suite as one program**, as a copy of `curator/audit/tests/test_suites.nim`.
Each module has one suite under `tests/suites/`. The suites start real processes through
`/bin/sh`, so they run on POSIX alone. The suite of the command line compiles small test files
with the compiler that built it (`getCurrentCompilerExe`), so it needs no fetch.

## Figures

**Assayer runs the 8 configurations of the PGA library in 19.7 s, where testament takes 33.6 s.**
Both start from an empty cache, on one file that lists the 8 configurations. Assayer with
`--jobs:1` takes 34.6 s. A second run of assayer, with each cache full, takes 12.7 s.

- Method: wall time by `date` around one run of each, on 2026-10-10. The machine is the
  container of this delegate, with 4 processors, Intel Xeon at 2.10 GHz.
- Setup: the library at `4130153`, with a nimble file that pins the compiler commit `27763495`.
  Assayer takes that compiler from the cache of knoller, and testament takes the same one.
- The slowest configuration bounds the parallel time. Testament gives
  `-d:pga.dimensions=6 -d:pga.is_conformal=true` 10.65 s of its 33.6 s.

## Toolchain

**The compiler is pinned exactly at 2.2.12, the pin of knoller**: `requires "nim == 2.2.12"` in
`assayer.nimble`. Assayer imports knoller by its path, so the two pins move together.

## Rules audits

Each rules change is audited against this project in the pull request that makes it, and the
`Rules` row above then moves. This record and the README use Simplified Technical English
(Article VI.8). The project holds Nim, Markdown and a nimble file, and no page, node manifest or
system package beyond the compiler and git.

## Open questions

- A change to knoller does not select assayer for test. `plan.nim` of the audit can add
  assayer beside `curator/audit`, in a merge-process change (CURATOR.md duty 2).
- The stub of `curator/audit` names one copy of itself, the stub of knoller. A root change can
  name the copy here too (Article II.9).
- `curator/README.md` does not name assayer yet, and a root change can add the line.
- No verb of koch calls assayer, and no charter allows one file under several configurations
  (Article IX.7, STYLE.md §6). Both are decisions for later.
