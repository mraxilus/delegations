discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimAllocStats -d:nimUnittestAbortOnError:on $options -r $file"
matrix: "-d:pga.dimensions=4 -d:pga.is_conformal=false"
batchable: true
joinable: true
"""
## Run shared suite on four-dimensional rigid algebra, i.e. 3D Euclidean space.
include "./suites.nim"
