discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Viewer puts each capsule on canvas by what `drawn` says, and this is where that
## is held to what browsers do.

{.experimental: "strictFuncs".}

import std/unittest

import ../design/drawn


suite "capsule on canvas":
  test "capsule of no length is put down as disc, never as stroke of no length":
    ## Sphere is capsule whose two ends are one point, and palm is one.  Stroke
    ## of no length with round caps is drawn as disc by one browser and as
    ## nothing by another: on Architect's phone every hand vanished, forearms
    ## ending 118 mm short of grip they were joined at, measured 2026-09-18 on
    ## A7.  Disc is drawn by every browser.
    let p: Spot = (0.039, 0.211, 0.995)
    check drawnAs(p, p) == Drawn.Disc
    check drawnAs(p, (0.108, 0.244, 1.020)) == Drawn.Stroke

  test "capsule hanging beside another is painted behind it where it is behind":
    ## Architect, on viewer from near overhead: z ordering is messed up at some
    ## angles.  Whole capsule was ordered by depth of its nearer end, so upper
    ## arm hanging from shoulder above torso's top was painted over torso all
    ## way down, and its lower half showed through torso's silhouette (A5).
    ## Painted in pieces, each by its own depth, arm's lower pieces go under
    ## torso's top and its shoulder end stays over it.
    let
      f: Framing = ([0.0, 0.0, 1.1], 1.0)
      trunk = (a: (0.0, 0.0, 0.925), z: (0.0, 0.0, 1.235))
      arm = (a: (0.0, 0.15, 1.35), z: (0.0, 0.15, 1.05))
      order = drawOrder([trunk, arm], 0.0, 1.2, f)
    proc place(cap: int; height: float): int =
      ## Where in order piece of `cap` nearest `height` is painted.
      var best = Inf
      for i, p in order:
        if p.cap != cap: continue
        let off = abs((p.a.z + p.z.z) / 2.0 - height)
        if off < best:
          best = off
          result = i
    check place(1, 1.07) < place(0, 1.22)
    check place(1, 1.33) > place(0, 1.22)

  test "each body is lit from its own front":
    ## Architect: see facing easily, without chevrons on floor and lines at
    ## shoulder height.  Side of body toward where dancer faces is lighter than
    ## other side, body facing eye is lighter than one facing away, and colour
    ## between shade and light is mixed by that much.
    let across: Seen = (x: 1.0, y: 0.0, d: 0.0)
    check litAt(across, 1.0) > litAt(across, -1.0)
    check litAt(across, 1.0) > litAt(across, 0.0)
    check litAt((x: 0.0, y: 0.0, d: 1.0), 0.0) > litAt((x: 0.0, y: 0.0, d: -1.0), 0.0)
    check litAt((x: 0.0, y: 0.0, d: 1.0), 0.0) == 1.0
    check litAt((x: 0.0, y: 0.0, d: -1.0), 0.0) == 0.0
    check mixHex("#000000", "#ffffff", 0.0) == "rgb(0, 0, 0)"
    check mixHex("#000000", "#ffffff", 1.0) == "rgb(255, 255, 255)"
    check mixHex("#102030", "#ffffff", 0.5) == "rgb(136, 144, 152)"
