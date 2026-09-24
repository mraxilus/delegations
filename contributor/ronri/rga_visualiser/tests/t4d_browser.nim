discard """
action: run
targets: "js"
matrix: "-d:nimUnittestAbortOnError:on -d:visualiser.history_capacity=4"
"""
## Run shared suite as browser build compiles it, on JS backend.
##
## Desktop entry point cannot stand in for it.
##   Rule stated once and reached through two mechanisms (`format.formatMagnitude`
##   against C's `%.4g`) is held together only where both run.
##   Compiled to C alone, that comparison asks C runtime whether it agrees with itself.
## History capacity is `t4d_small`'s, and objects and labels stay shipped.
##   History laws walk whole ring, which says nothing of backend and only runs longer at
##   default. Orrery's cases need shipped object capacity, and run here on page's own backend.
## Cases needing C entry point (`snprintf`, PNG and GIF export, arena) guard themselves
## with `when not defined(js)` and are skipped here.
include "./suites.nim"
