discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options -r $file"
batchable: true
joinable: true
"""
## Hold drawn run to its length, at compile time as well as at run time.
##
##   Length of run is taken in compiler's virtual machine, because scene
##     table is built as `const` (`draw/scene.nim`).  Nim 2.2.8 onward gives
##     float `result` int register where nothing assigns it before first
##     `+=`, and crashes compiler; `const` below is what notices, since
##     ordinary call at run time never touches that path.
##   Cost: suite exists for one law.  Kept separate so failure names
##     drawn length rather than whichever page happened to import it.

{.experimental: "strictFuncs".}

import std/[unittest]

import ../src/dance_ontology/draw/[geometry, route]


const
  SQUARE: seq[Point] = @[(0.0, 0.0), (3.0, 0.0), (3.0, 4.0)]
    ## Three corners: three-four-five triangle's two short sides.
  WALKED = polylineLen(SQUARE)
    ## Taken in compiler's virtual machine, which is what this suite is for.


suite "drawn run":
  test "length of run is sum of its steps, taken at compile time":
    check abs(WALKED - 7.0) < 1e-9

  test "length of run is same taken at run time":
    check abs(polylineLen(SQUARE) - WALKED) < 1e-9

  test "run of one point, or none, is no length at all":
    check polylineLen(@[]) == 0.0
    check polylineLen(@[(1.0, 2.0)]) == 0.0
    const NOTHING = polylineLen(@[])
    check NOTHING == 0.0
