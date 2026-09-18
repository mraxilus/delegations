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
