## How each capsule engine holds is put on canvas: stroked between its ends with
## round caps, so its outline is stadium, or as disc where it has no length.
##
##   One place to say so, compiled for browser by `rig_view` and natively by its
##     law, since browsers do not agree on what stroke of no length is: disc
##     with round caps in one, nothing in another.  Palm is sphere, capsule of
##     no length, and on Architect's phone every hand vanished, forearm ending
##     118 mm short of grip it was joined at.

{.experimental: "strictFuncs".}

type
  Spot* = tuple[x, y, z: float] ## One point in world, metres, z up.
  Drawn* = enum ## What one capsule is put on canvas as.
    Stroke, Disc


func drawnAs*(a, z: Spot): Drawn =
  ## Stroke between its two ends, and disc where they are one point.
  if a == z: Drawn.Disc else: Drawn.Stroke
