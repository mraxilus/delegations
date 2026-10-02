discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimAllocStats -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=3 -d:pga.is_conformal=false"
"""
## Run shared suite on three-dimensional rigid algebra, i.e. 2D Euclidean space.

{.experimental: "strictFuncs".}

include "suites.nim"
