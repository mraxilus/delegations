## Measure pga against Lengyel's hand-rolled reference, and keep list of gaps between them.
##   Library under measurement is pinned dependency restored into `deps/`; every module here
##   that imports it takes its algebra from `-d:pga.dimensions` and `-d:pga.is_conformal`,
##   so one source serves every configuration and stubs pick which.
##
##   Bootstrap order:
##     [pga] -> pga_benchmark (this umbrella)
##
##   Cost: nothing measured yet; this commit opens project shape audit demands, and every
##     later module lands with test that holds it.

{.experimental: "strictFuncs".}

import pga

export pga


const CONFIG* = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  ## Name of algebra this build measures, e.g. `rga4d`; keys every baseline and bench file.
