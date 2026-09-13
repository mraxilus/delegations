## Measure pga against Lengyel's hand-rolled reference, and keep list of gaps between them.
##   Library under measurement is pinned dependency restored into `deps/`; every module here
##   that imports it takes its algebra from `-d:pga.dimensions` and `-d:pga.is_conformal`,
##   so one source serves every configuration and stubs pick which.
##
##   Bootstrap order:
##     [pga] -> kinds -> catalogue
##     [pga] -> reference/rigid3 -> bridge -> pools
##     catalogue, pools -> pga_benchmark (this umbrella)
##     surface (pure, reads library source; test side)
##
##   Cost: nothing timed yet; catalogue names every operation, suite holds it to library's
##     exported surface and holds every typed row to its reference, so later instruments
##     walk list that cannot drift and measure against forms already proven equal.

{.experimental: "strictFuncs".}

import pga

import ./pga_benchmark/[bridge, catalogue, kinds, pools, surface]

export bridge, catalogue, kinds, pga, pools, surface


const CONFIG* = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  ## Name of algebra this build measures, e.g. `rga4d`; keys every baseline and bench file.
