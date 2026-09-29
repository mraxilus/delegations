discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:visualiser.objects_max=12 -d:visualiser.label_max=12 -d:visualiser.history_capacity=4"
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
##   What varies is capacity, not render path; see `test_4d_browser.nim` for other axis.

{.experimental: "strictFuncs".}

include "suites.nim"
