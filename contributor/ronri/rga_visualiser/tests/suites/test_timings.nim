## Run `Timings` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../src/rga_visualiser/timings



suite "Timings":
  test "placing an object charges its time to the placing side, whichever way it leaves":
    # As found by library-share study (repository issue 553): with every object of demo
    #   placed, placing side read 0.000 ms of 5.0 ms, as each answer returned inside `timed`.
    #   Domain is every exit of placing: point at place and on horizon, line through place
    #   and across sky, plane on place and everywhere, and no geometry at all.
    #   Each from clear totals, so exit never charged reads exactly zero; each placed
    #   `SAMPLES` times, so clock of either backend ticks within it.
    let exits = [
      ("point at a place", POINTS[0], Case.PointAt),
      ("point on the horizon", ⊖LINES[0], Case.PointToward),
      ("line through a place", LINES[0], Case.LineThrough),
      ("line across the sky", ⊖PLANES[0], Case.LineAcross),
      ("plane on a place", PLANES[0], Case.PlaneOn),
      ("plane everywhere", ⊖(POINTS[10] ∧ PLANES[0]), Case.PlaneEverywhere),
      ("no geometry", 1.0 + POINTS[0], Case.Nothing),
    ]
    setTallying(true)
    for (exit, geometry, expected) in exits:
      checkpoint exit
      openFrameTimings()
      var placed = Placement()
      for _ in 0..<SAMPLES:
        placed.placeInto(geometry, none(Position))
      check placed.kind == expected
      check spentOn(Side.Placing) > 0.0


  test "a timed stretch that leaves before its end fails to build":
    # Leaving skips closing clock read, so stretch is never charged, and nothing says so.
    check not compiles(block:
      proc leaving() =
        timed(Side.Placing): return
      leaving())
    check not compiles(block:
      proc leaving() =
        for index in 0..<2:
          timed(Side.Placing): break
      leaving())
    check not compiles(block:
      proc leaving() =
        block outer:
          timed(Side.Placing):
            for index in 0..<2: break outer
      leaving())
    # Stretch may still leave block or loop of its own.
    check compiles(block:
      proc staying() =
        timed(Side.Placing):
          block answered:
            for index in 0..<2: continue
            break answered
      staying())
