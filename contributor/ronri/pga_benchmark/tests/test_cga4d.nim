discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimAllocStats -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=4 -d:pga.is_conformal=true"
"""
## Run shared suite on four-dimensional conformal algebra, i.e. 2D Euclidean space.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

include "suites.nim"
