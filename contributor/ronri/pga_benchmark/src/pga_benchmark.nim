## Measure pga against Lengyel's hand-rolled reference, and keep list of gaps between them.
##   Library under measurement is pinned dependency restored into `deps/`; every module here
##   that imports it takes its algebra from `-d:pga.dimensions` and `-d:pga.is_conformal`,
##   so one source serves every configuration and stubs pick which.
##
##   Bootstrap order:
##     [pga] -> kinds -> catalogue -> pga_benchmark (this umbrella)
##     surface (pure, reads library source; test side)
##
##   Cost: nothing timed yet; catalogue names every operation and suite holds it to
##     library's exported surface, so later instruments walk list that cannot drift.

{.experimental: "strictFuncs".}

import pga

import ./pga_benchmark/[catalogue, kinds, surface]

export catalogue, kinds, pga, surface


const CONFIG* = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  ## Name of algebra this build measures, e.g. `rga4d`; keys every baseline and bench file.
