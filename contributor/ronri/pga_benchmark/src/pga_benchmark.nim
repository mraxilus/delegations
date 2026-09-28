## Measure pga against Lengyel's hand-rolled reference, and keep list of gaps between them.
##   Library under measurement is pinned dependency restored into `deps/`; every module here
##   that imports it takes its algebra from `-d:pga.dimensions` and `-d:pga.is_conformal`,
##   so one source serves every configuration and stubs pick which.
##
##   Bootstrap order, `[needs] -> target`, one line for each target:
##     [] -> bound, inspector, surface, reference/scalars
##     [pga] -> kinds
##     [pga, bound, kinds] -> catalogue
##     [reference/scalars] -> reference/rigid3, reference/conformal3
##     [pga, reference/scalars, reference/rigid3 or reference/conformal3 by algebra] -> widening
##     [pga, kinds, widening] -> pools
##     [catalogue, kinds, pools, surface, widening] -> pga_benchmark (this umbrella)
##     [pga, catalogue, kinds, pools, widening] -> measurements
##     [inspector, reference/rigid3, reference/conformal3] -> model
##     [inspector, model] -> report
##     [report] -> gaps, guard
##     [pga, bound, catalogue, inspector, kinds, report] -> inspect
##     [pga, catalogue, kinds, measurements, pools, report] -> bench (entry point, tool side)
##
##   Umbrella exports what suites and instruments share; `measurements`, `report` and `bench`
##     stay behind it, since they carry measurement arrays and JSON and belong to tool side.
##   Cost: catalogue names every operation, suite holds it to library's exported surface
##     and holds every typed measurand to its reference, so instruments walk list that cannot
##     drift and measure against forms already proven equal.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import pga

import ./pga_benchmark/[catalogue, kinds, pools, surface, widening]

export catalogue, kinds, pga, pools, surface, widening


const ALGEBRA_NAME* = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  ## Name of algebra this build measures, e.g. `rga4d`; keys every baseline and bench file.
