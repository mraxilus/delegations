## How each capsule engine holds is put on canvas: stroked between its ends with
## round caps, so its outline is stadium.
##
##   One place to say so, compiled for browser by `rig_view` and natively by its
##     law, since browsers do not agree on what stroke of no length is.

{.experimental: "strictFuncs".}

type
  Spot* = tuple[x, y, z: float] ## One point in world, metres, z up.
  Drawn* = enum ## What one capsule is put on canvas as.
    Stroke, Disc


func drawnAs*(a, z: Spot): Drawn =
  ## Stroke between its two ends, whatever they are.
  Drawn.Stroke
