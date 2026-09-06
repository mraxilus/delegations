discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options -r $file"
batchable: true
joinable: true
"""
## Run shared suite at shipped capacities, on C backend desktop entry point uses.
##
## Algebra comes from `nim.cfg`: four dimensions, rigid metric, shared by every target.
include "./suites.nim"
