discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimAllocStats -d:nimUnittestAbortOnError:on $options -r $file"
matrix: "-d:pga.dimensions=5 -d:pga.is_conformal=true"
batchable: true
joinable: true
"""
## Run shared suite on five-dimensional conformal algebra, i.e. 3D Euclidean space.
include "./suites.nim"
