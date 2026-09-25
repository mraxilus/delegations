## Check invariants of visualiser against deterministically sampled pool of RGA objects.
##
## Suites are named after visualiser's modules rather than Lengyel's chapters:
##   visualiser is tool built on library, not replication of published equations.
##
## Pool is drawn once from seeded generator, so failure reproduces from test name alone.
##   Points are sampled inside box drawn extent covers, so nothing is degenerate.
##   Lines and planes are joined from those points, so collinear cases stay improbable.
##
## `renderer`, `gui` and `panel` are absent, deliberately:
##   each needs live OpenGL context, which test runner has no business opening.
##   What they would test sits below them:
##   `mesh` holds tessellation, `scene` operations and formatting, `camera` transforms.
##
## Each suite is module of its own under `suites/`, sharing `suites/fixtures.nim`.
##   Top-level tests compile into their module's init function, so one module made one C
##   function of whole suite, which one `gcc` compiled alone; one module each gives compiler
##   one C file each, compiled in parallel (PROVENANCE.md, Testing).
##   Imported in fixed order, never read from directory: seeded generator then serves every
##   test same draws, and order is order suites ran in as one file.
##   Each module also runs alone, e.g. `nim r -d:testing tests/suites/tmotors.nim`.

{.warning[UnusedImport]: off.}  # suite modules run for effect and export nothing

when compileOption("profiler"):
  import std/nimprof

import ./suites/[
  tobjects,
  tmotors,
  tcamera,
  tmesh,
  tscene,
  thistory,
  tcamera_aim,
  tselection,
  tarena_swap,
  timage,
  thelp,
  tpicking,
  tinteraction,
  tmarker,
  torrery,
  tmessage,
  twording,
]
