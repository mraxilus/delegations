## How what engine holds is put on canvas: where each world point lands on
## screen, in what order capsules are painted, and what each capsule is put
## down as -- stroke between its ends with round caps, so its outline is
## stadium, or disc where it has no length.
##
##   One place to say so, compiled for browser by `rig_view` and natively by its
##     law, since browsers do not agree on what stroke of no length is: disc
##     with round caps in one, nothing in another.  Palm is sphere, capsule of
##     no length, and on Architect's phone every hand vanished, forearm ending
##     118 mm short of grip it was joined at.
##   Projection is orthographic on purpose.  Under it capsule's outline is
##     exactly stadium -- round capped line from one end to other, as wide as
##     twice its radius -- so line drawn with round cap *is* shape, not likeness
##     of it.  Under perspective it is not, and drawing would quietly stop being
##     true at angles where it mattered most.

{.experimental: "strictFuncs".}

import std/math


type
  Spot* = tuple[x, y, z: float] ## One point in world, metres, z up.
  Framing* = tuple[mid: array[3, float], reach: float]
    ## Middle of what one entry covers, and half of how far it spreads.
  Seen* = tuple[x, y, d: float] ## On screen: across, down, and depth toward eye.
  Drawn* = enum ## What one capsule is put on canvas as.
    Stroke, Disc
  Piece* = tuple[cap: int, a, z: Spot] ## Part of capsule `cap` put down as one stroke.


func seen*(p: Spot; az, el: float; f: Framing): Seen =
  ## Project one world point: screen across, screen down, and depth toward eye.
  ##   Screen's down is world's up negated: canvas counts y downward, so point
  ##     higher off floor has to come out smaller.  Signed other way, floor grid
  ##     draws above dancers standing on it.
  let
    (ca, sa) = (cos(az), sin(az))
    (ce, se) = (cos(el), sin(el))
    (x, y, z) = (p.x - f.mid[0], p.y - f.mid[1], p.z - f.mid[2])
  (x: -sa * x + ca * y,
   y: ca * se * x + sa * se * y - ce * z,
   d: ca * ce * x + sa * ce * y + se * z)

func drawnAs*(a, z: Spot): Drawn =
  ## Stroke between its two ends, and disc where they are one point.
  if a == z: Drawn.Disc else: Drawn.Stroke

func drawOrder*(caps: openArray[tuple[a, z: Spot]]; az, el: float;
                f: Framing): seq[Piece] =
  ## Every capsule whole, painter's order: furthest first, by depth of its
  ## nearer end.
  var keyed: seq[(float, Piece)]
  for i, c in caps:
    let near = max(seen(c.a, az, el, f).d, seen(c.z, az, el, f).d)
    keyed.add (near, (cap: i, a: c.a, z: c.z))
  # Insertion sort, stable: equal depths keep engine's order.
  for i in 1 ..< keyed.len:
    var j = i
    while j > 0 and keyed[j - 1][0] > keyed[j][0]:
      swap(keyed[j - 1], keyed[j])
      dec j
  for k in keyed: result.add k[1]
