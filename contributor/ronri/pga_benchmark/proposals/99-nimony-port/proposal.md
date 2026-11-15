# P99: Port of the library to Nimony

**What it is.** The library at pin, ported to Nimony, the new compiler of the Nim language in
`nim-lang/nimony`. Each module, name and function stays, and the tables stay typed by `Basis`. The
four macros become templates over one plugin program, and the port builds with 9 patches of Nimony
at commit 941d128.

**What it is for.** Nimony has no release yet, so this proposal is deferred. It reports now what a
move to Nimony keeps and what it costs. For 9 algebras the suites pass as under Nim 2, and 422 670
regression lines have the same bytes.

**What it costs.** A clean build of the rga4d suite takes 40.4 s, against 4.0 s under Nim 2. The
kernels run at the speed of Nim 2 at 4D, apart from `unitize`, and slower at 5D. 58 rows record
where the text differs from the library at pin, each with its reason.

## Problem

The library builds under Nim 2.4.0 alone. At pin it does not build under Nimony, for four kinds
of reason. Nimony has no `strformat` and no `std/unittest`, and it declares no `{.compileTime.}`
(rows B1, B9 and L1 of `deviations.md`). A macro runs as a program of its own, with no access to
the code of the library (S4). Nimony also evaluates each constant where it stands, by a program
that it compiles for it, so a type must be complete before a constant uses it (S1 to S3).

Nimony has no release, and each of its commits can change what builds. So a port now measures a
moving target. This proposal records that target at one commit, and waits for a release.

## Idea

- **Modules.** `pga/basis.nim` declares `Basis` before the code that uses it (S1). The folder
  `pga/cayleys/` holds the types, the functions and the tables in modules of their own (S2, S3).
  Each module of the library keeps its name and its order.
- **Macros.** Each of the four macros becomes a template of the same name. One plugin program,
  `pga/emitters.nim`, writes the code of all four (S4, S5). Each table reaches the plugin as a
  plain value.
- **Cells.** A cell of a table is an array with a count, in place of `seq`, so the plugin reads
  it as a value (S8). It holds 2 terms under the conformal metric and 1 under the rigid one. P12
  proposes a cell of the same kind for the library at pin.
- **Tests.** The suites of the library run on `tests/unittest.nim`. It stands in for
  `std/unittest`, with the same status lines (B9).
- **Compiler.** Nimony at 941d128 needs 9 patches, C1 to C9, which `compiler.md` holds. Without
  any one of them, the build of the rga3d suite fails.
- **Record.** `deviations.md` holds 80 rows. 58 rows give each difference of text, and 3 more give
  each form that costs too much under Nimony. 3 rows give limits above 6D, 7 the costs at run
  time, and 9 the compiler patches.

## Alternatives

- **Port at a release of Nimony.** No release exists. A port now finds the defects of Nimony
  while they can still be mended upstream.
- **Nimony master at 1df3edf5.** It needs 3 patches in place of 9. But it builds the imports again
  for each module that evaluates a constant. The port stays at 941d128, as the Architect ruled on
  2026-11-15.
- **Macros through the macro plugin of Nimony.** Its program takes one tree for each argument,
  with no helper of the library and no `static` value (S4).
- **`pga/cayleys.nim` as one module.** Its first table constant fails, since the types of its own
  module are not complete there (S2).

## Costs

- **Build.** A clean build of the rga4d suite takes 40.4 s and 123.0 s of CPU time, against 4.0 s
  under Nim 2. At rga6d it takes 96.5 s, against 11.1 s. Constant programs take 83.3 % of the CPU
  time of a traced rga4d build: Nimony compiles 41 of them. A build of the same source again takes
  0.0 s, where Nim 2 takes 2.7 s.
- **Kernels.** Release builds of six kernels, with both compilers running them in one routine.
  At 4D, five of six run at the speed of Nim 2. `unitize` takes 1.72 times the time of Nim 2,
  since the own `sqrt` of Nimony does not call libc, and 0.98 times with `-d:useLibcIo`. At 5D,
  each kernel takes 1.08 to 3.31 times, since gcc keeps copies of the 256-byte result in memory
  (R4, R5). At 6D, `wedgeDot` takes 1.18 times, `unitize` 1.20 times and `subset` 1.75 times.
- **Text.** 58 rows differ from the library at pin: 20 by design of Nimony, 31 from missing
  features, 13 from compiler defects, 5 by choice and 1 kept. A row of two origins counts under
  both.
- **Type checks.** 7 points are weaker than under Nim 2, and 7 are stricter. Nimony accepts an
  integer index into `array[Basis, T]` by design. A constant basis outside a subset multivector
  fails at run time, where Nim 2 rejects it at compile time (X2).
- **Compiler.** The port needs a compiler with 9 patches until Nimony mends each defect. Master
  1df3edf5 mends C1, C4, C5, C6, C7 and C9.

## Open decisions

- Take which optional changes of the review into the port. The review kept 20 changes as patches
  outside the repository, O1 to O20, and each one passes its check on the port.
- Report which defects of Nimony upstream, and when. The defect list holds 15 entries in the bug
  report form of Nim, and 26 more defects under "Seen". None is reported.
- Port again at the release of Nimony, or update this port to that release.

## Landing

- **Release of Nimony.** This proposal waits on it. At that release, the port builds with the
  patches of `compiler.md` that the release still needs, and the evidence below runs again.
- **Pin.** The change replaces each file of the library whole, from its digest at pin
  `3d9696e`. So any proposal that lands first, as P12 or P13, makes the change stale. Its update
  then ports the library at the new pin.
- **Update.** The Architect asks for each update. `applyChange` of `changes.nim` applies the
  change to a copy of the library at pin, as an evaluation does. Each suite then builds with
  `nimony c`, with `-d:pga.dimensions` and `-d:pga.is_conformal` of its algebra. The program of
  `regress.md` prints each table and each operator on fixed inputs, as raw bits. Its output under
  Nimony must have the same bytes as under Nim 2.4.0 at pin.

## Evidence

The port was verified on 2026-11-15, on `linux amd64, 4 cores`, an Intel Xeon at 2.10 GHz. The
compiler is Nimony 941d128 with the patches of `compiler.md`, and Nim 2.4.0 builds the library at
pin for each comparison. The checks below ran on sources that hash to `1f09934e0068b5ec`, by SHA-256
of their text. The sources of `change.md` hash to `29f473eaa67eafec`, since they drop trailing
spaces from 12 lines. On them the suites, the regression and the self-test pass again at rga3d and
cga3d.

- **Suites of the library**, at each of the 9 algebras from rga2d to cga6d. They give the status
  lines of Nim 2: 33 pass and 5 skip in each RGA, and 28 pass and 10 skip in each CGA.
- **Regression program of `regress.md`**, in debug builds at the 9 algebras. Its 422 670 lines
  have the same bytes as under Nim 2.
- **Same program in other builds.** Release builds at rga4d and cga5d, a danger build at rga3d,
  and 32-bit builds at rga3d, cga3d and cga5d all give the same bytes as Nim 2.
- **Suite at 32 bits**, at rga3d. It gives the status lines of Nim 2.
- **Guards of the defines.** Each of 5 bad configurations stops the build with one error, and the
  message of Nim 2.
- **Hidden names.** 37 names stay undeclared for an importer, as under Nim 2.
- **Self-test of failure paths.** 14 cases pass at each algebra, and 3 cases for
  `tests/unittest.nim`.
- **Each compiler patch removed.** The build of the rga3d suite fails without any one of C1 to C9.

[The full report](https://claude.ai/artifact/KEr1i8zyWLksRFrmfaBnSM) holds each table of this
evidence, and the deviations of each row. The defects of Nimony that the port met stand in
[the defect list](https://claude.ai/artifact/GAakVtaMvnsMrAXuUJV8Th). The scripts of the runs, the
self-test, and the review of the port stay in an archive outside the repository.
