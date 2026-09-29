discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimAllocStats -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=5 -d:pga.is_conformal=true"
"""
## Run shared suite on five-dimensional conformal algebra, i.e. 3D Euclidean space.

{.experimental: "strictFuncs".}

include "suites.nim"
