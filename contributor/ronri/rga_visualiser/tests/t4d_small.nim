discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options -r $file"
matrix: "-d:visualiser.objects_max=12 -d:visualiser.label_max=12 -d:visualiser.history_capacity=4"
batchable: true
joinable: true
"""
## Run shared suite at capacities small enough that its tests reach them.
##
## Every capacity is `.define`; at defaults suite reaches limits only where test spells
## limit out.
##   Shrinking them makes boundaries cheap to reach and makes any constant tuned to
##   default rather than derived from define fail here.
##   `LABEL_MAX` at 12 is sharpest: under length of several labels suite constructs, so
##   truncation happens for real.
## Backend is C, matching desktop entry point.
##   What varies is capacity, not render path; see `t4d_browser.nim` for other axis.
include "./suites.nim"
