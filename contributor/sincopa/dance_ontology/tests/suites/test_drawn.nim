## Viewer puts each capsule on canvas by what `drawn` says, and this is where that
## is held to what browsers do.

{.experimental: "strictFuncs".}

import std/unittest

import ../../design/drawn


suite "Internal: Capsule on canvas":
  test "capsule of no length is put down as disc, never as stroke of no length":
    ## Sphere is capsule whose two ends are one point, and palm is one.  Stroke
    ## of no length with round caps is drawn as disc by one browser and as
    ## nothing by another: on Architect's phone every hand vanished, forearms
    ## ending 118 mm short of grip they were joined at, measured 2026-09-18 on
    ## A7.  Disc is drawn by every browser.
    let palm: Spot = (0.039, 0.211, 0.995)
    check drawnAs(palm, palm) == Drawn.Disc
    check drawnAs(palm, (0.108, 0.244, 1.020)) == Drawn.Stroke

  test "capsule hanging beside another is painted behind it where it is behind":
    ## Architect, on viewer from near overhead: z ordering is messed up at some
    ## angles.  Whole capsule was ordered by depth of its nearer end, so upper
    ## arm hanging from shoulder above torso's top was painted over torso all
    ## way down, and its lower half showed through torso's silhouette (A5).
    ## Painted in pieces, each by its own depth, arm's lower pieces go under
    ## torso's top and its shoulder end stays over it.
    let
      framing: Framing = ([0.0, 0.0, 1.1], 1.0)
      trunk = (a: (0.0, 0.0, 0.925), z: (0.0, 0.0, 1.235))
      arm = (a: (0.0, 0.15, 1.35), z: (0.0, 0.15, 1.05))
      order = drawOrder([trunk, arm], 0.0, 1.2, framing)
    proc place(capsule: int, height: float): int =
      ## Where in order piece of `capsule` nearest `height` is painted.
      var best = Inf
      for i, piece in order:
        if piece.capsule != capsule: continue
        let offset = abs((piece.a.z + piece.z.z) / 2.0 - height)
        if offset < best:
          best = offset
          result = i
    check place(1, 1.07) < place(0, 1.22)
    check place(1, 1.33) > place(0, 1.22)

  test "each body is lit from its own front":
    ## Architect: see facing easily, without chevrons on floor and lines at
    ## shoulder height.  Side of body toward where dancer faces is lighter than
    ## other side, body facing eye is lighter than one facing away, and colour
    ## between shade and light is mixed by that much.
    let across: Seen = (x: 1.0, y: 0.0, depth: 0.0)
    check litAt(across, 1.0) > litAt(across, -1.0)
    check litAt(across, 1.0) > litAt(across, 0.0)
    check litAt((x: 0.0, y: 0.0, depth: 1.0), 0.0) > litAt((x: 0.0, y: 0.0, depth: -1.0), 0.0)
    check litAt((x: 0.0, y: 0.0, depth: 1.0), 0.0) == 1.0
    check litAt((x: 0.0, y: 0.0, depth: -1.0), 0.0) == 0.0
    check mixColours("#000000", "#ffffff", 0.0) == "rgb(0, 0, 0)"
    check mixColours("#000000", "#ffffff", 1.0) == "rgb(255, 255, 255)"
    check mixColours("#102030", "#ffffff", 0.5) == "rgb(136, 144, 152)"

  test "light runs across each piece, never along it":
    ## Lit along facing's image on screen as it fell, torso showed bands: each
    ## piece's gradient was centred on its own middle, and where facing's image
    ## ran along piece, one piece's light end met next piece's dark end.
    ## Facing is taken across piece alone, its part along piece dropped.
    let
      along: Seen = (x: 0.0, y: 1.0, depth: 0.0)
      across = lightAcross((x: 0.6, y: 0.8, depth: 0.0), along)
    check abs(across.x - 0.6) < 1e-9
    check abs(across.y) < 1e-9
    let whole = lightAcross((x: 0.6, y: 0.8, depth: 0.0), (x: 0.0, y: 0.0, depth: 0.0))
    check whole == (x: 0.6, y: 0.8, depth: 0.0)
