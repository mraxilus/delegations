## Run `Timings` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../src/rga_visualiser/timings



suite "Timings":
  test "placing an object charges its time to the placing side":
    # Placing stops as soon as it knows its answer; charge lands whichever path it takes.
    #   Every kind at once, from clear totals: stretch never charged reads exactly zero.
    setTallying(true)
    openFrameTimings()
    for index in 0..<SAMPLES:
      discard placeObject(POINTS[index])
      discard placeObject(LINES[index])
      discard placeObject(PLANES[index])
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
