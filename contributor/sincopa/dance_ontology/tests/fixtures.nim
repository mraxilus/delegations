## Compare computed floats as tests of this project do (Article IV.5, STYLE.md §4).
##
##   Library has no use for it, so it lives with tests (Article IX.11).  Bound with
##     physical margin, such as 0.05 m or ten degrees, is law of its own and stays bound.

{.experimental: "strictFuncs".}

import std/math


const
  TOLERANCE_PLACES* {.intdefine: "dance_ontology.tolerance_places".} = 9
    ## Decimal places two computed floats agree to; build sets it.
  TOLERANCE_ABS* = 10.0.pow(-float(TOLERANCE_PLACES))
    ## Absolute floor of tolerance, and its scale per unit of size.


func `=~`*(a, b: float): bool =
  ## Compare approximate equality between scalars.
  ##   Near zero, tolerance falls to its absolute floor.
  abs(a - b) <= TOLERANCE_ABS * max(1.0, max(abs(a), abs(b)))
