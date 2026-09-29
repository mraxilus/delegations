discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimAllocStats -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=4 -d:pga.is_conformal=false"
"""
## Run shared suite on four-dimensional rigid algebra, i.e. 3D Euclidean space.

{.experimental: "strictFuncs".}

include "suites.nim"
