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

import std/[algorithm, math]


const DAB* = 0.04 ## Longest dab one capsule is painted in, metres: torso in
                  ## eight, upper arm in six, sphere in one.

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

func along(a, z: Spot; t: float): Spot =
  (a.x + (z.x - a.x) * t, a.y + (z.y - a.y) * t, a.z + (z.z - a.z) * t)

func drawOrder*(caps: openArray[tuple[a, z: Spot]]; az, el: float;
                f: Framing): seq[Piece] =
  ## Every capsule in pieces no longer than `DAB`, painter's order: furthest
  ## first, by depth of each piece's middle, equal depths in engine's order.
  ##   Whole capsule by depth of its nearer end painted upper arm hanging from
  ##     shoulder above torso's top over torso all way down, lower half showing
  ##     through torso's silhouette from near overhead (A5).  Piece by its own
  ##     depth goes under torso's top where it is below it.  Two capsules
  ##     through one another can still come out wrong way round within one
  ##     piece, and bodies are filtered not to.
  var keyed: seq[(float, Piece)]
  for i, c in caps:
    let
      long = sqrt((c.z.x - c.a.x) ^ 2 + (c.z.y - c.a.y) ^ 2 + (c.z.z - c.a.z) ^ 2)
      n = max(1, ceil(long / DAB).int)
    for k in 0 ..< n:
      let
        a = along(c.a, c.z, k.float / n.float)
        z = along(c.a, c.z, (k + 1).float / n.float)
        mid = along(c.a, c.z, (k.float + 0.5) / n.float)
      keyed.add (seen(mid, az, el, f).d, (cap: i, a: a, z: z))
  keyed.sort(proc (p, q: (float, Piece)): int = cmp(p[0], q[0]))
  for k in keyed: result.add k[1]
