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

import std/[algorithm, math, strutils]


const DAB* = 0.04  ## Longest dab one capsule is painted in, metres: torso in
                  ## eight, upper arm in six, sphere in one.

type
  Spot* = tuple[x, y, z: float]  ## One point in world, metres, z up.
  Framing* = tuple[middle: array[3, float], reach: float]
    ## Middle of what one entry covers, and half of how far it spreads.
  Seen* = tuple[x, y, depth: float]  ## On screen: across, down, and depth toward eye.
  Drawn* = enum  ## What one capsule is put on canvas as.
    Stroke, Disc
  Piece* = tuple[capsule: int, a, z: Spot]  ## Part of capsule `capsule` put down as one stroke.


func seen*(point: Spot; azimuth, elevation: float; framing: Framing): Seen =
  ## Project one world point: screen across, screen down, and depth toward eye.
  ##   Screen's down is world's up negated: canvas counts y downward, so point
  ##     higher off floor has to come out smaller.  Signed other way, floor grid
  ##     draws above dancers standing on it.
  let
    (cosine_azimuth, sine_azimuth) = (cos(azimuth), sin(azimuth))
    (cosine_elevation, sine_elevation) = (cos(elevation), sin(elevation))
    x = point.x - framing.middle[0]
    y = point.y - framing.middle[1]
    z = point.z - framing.middle[2]
  (x: -sine_azimuth * x + cosine_azimuth * y,
   y: cosine_azimuth * sine_elevation * x + sine_azimuth * sine_elevation * y -
     cosine_elevation * z,
   depth: cosine_azimuth * cosine_elevation * x + sine_azimuth * cosine_elevation * y +
     sine_elevation * z)

func drawnAs*(a, z: Spot): Drawn =
  ## Stroke between its two ends, and disc where they are one point.
  if a == z: Drawn.Disc else: Drawn.Stroke

func along(a, z: Spot; t: float): Spot =
  ## Find point fraction `t` of way from `a` to `z`.
  (a.x + (z.x - a.x) * t, a.y + (z.y - a.y) * t, a.z + (z.z - a.z) * t)

func drawOrder*(
  capsules: openArray[tuple[a, z: Spot]]; azimuth, elevation: float; framing: Framing
): seq[Piece] =
  ## Every capsule in pieces no longer than `DAB`, painter's order: furthest
  ## first, by depth of each piece's middle, equal depths in engine's order.
  ##   Whole capsule by depth of its nearer end painted upper arm hanging from
  ##     shoulder above torso's top over torso all way down, lower half showing
  ##     through torso's silhouette from near overhead (A05).  Piece by its own
  ##     depth goes under torso's top where it is below it.  Two capsules
  ##     through one another can still come out wrong way round within one
  ##     piece, and bodies are filtered not to.
  var keyed: seq[(float, Piece)]
  for i, capsule in capsules:
    let
      long = sqrt(
        (capsule.z.x - capsule.a.x) ^ 2 + (capsule.z.y - capsule.a.y) ^ 2 +
                    (capsule.z.z - capsule.a.z) ^ 2,
      )
      n = max(1, int(ceil(long / DAB)))
    for k in 0..<n:
      let
        a = along(capsule.a, capsule.z, float(k) / float(n))
        z = along(capsule.a, capsule.z, float(k + 1) / float(n))
        middle = along(capsule.a, capsule.z, (float(k) + 0.5) / float(n))
      keyed.add (seen(middle, azimuth, elevation, framing).depth, (capsule: i, a: a, z: z))
  keyed.sort(proc (p, q: (float, Piece)): int = cmp(p[0], q[0]))
  for entry in keyed: result.add entry[1]

func litAt*(fore: Seen, s: float): float =
  ## How lit one body's side is at offset `s` across it, -1 at its back edge to
  ## 1 at its front edge, given where it faces on screen: 0 dark, 1 light.
  ##   Each dancer is lit from their own front, as if they carried lamp on
  ##     their chest: side of body toward where they face is light, other side
  ##     dark, body facing eye light all over and one facing away dark all over.
  ##     Rounded body's normal at that offset has that much of facing across
  ##     screen and rest toward eye.  Architect: see facing without chevrons on
  ##     floor and lines at shoulder height, which were noise.
  let across = sqrt(fore.x * fore.x + fore.y * fore.y)
  clamp(0.5 + 0.5 * (s * across + sqrt(max(0.0, 1.0 - s * s)) * fore.depth), 0.0, 1.0)

func lightAcross*(fore, axis: Seen): Seen =
  ## Facing's image on screen as light runs across one piece whose screen
  ## axis is `axis`: its part along piece dropped, so gradient runs square to
  ## piece and one piece meets next without seam.  Lit along facing as it
  ## fell, torso showed bands, each piece's gradient centred on its own
  ## middle.  Sphere has no axis and takes facing whole.
  let long = axis.x * axis.x + axis.y * axis.y
  if long < 1e-12: return fore
  let t = (fore.x * axis.x + fore.y * axis.y) / long
  (x: fore.x - axis.x * t, y: fore.y - axis.y * t, depth: fore.depth)

func mixColours*(dark, light: string; t: float): string =
  ## Colour `t` of way from `dark` to `light`, each `#rrggbb`, as `rgb(r, g, b)`.
  var parts: seq[string]
  for k in 0..2:
    let
      a = float(parseHexInt(dark[1 + 2 * k..2 + 2 * k]))
      b = float(parseHexInt(light[1 + 2 * k..2 + 2 * k]))
    parts.add $int(round(a + (b - a) * t))
  "rgb(" & parts.join(", ") & ")"
