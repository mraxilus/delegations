## Measure how far plan carries each rig sweep from rest, at band of its hold: floors law of
## planned sweep holds rig's recording to (`tests/suites/test_asks.TURNS_PLANNED`).
##
##   Instrument run by hand (`tools/build.nim floors`), never by suite: each way plans every
##     style on every core, and both chains alone planned 64 paths in 377 s on four cores,
##     measured 2026-10-12.  Law reads floors as figures, so this is how they are read again.
##   Asks `walk.plannedWay`, as rig's recording asks it, of each sweep rig viewer plays
##     (`rig.SHOWN`), at band of its hold, way it plays: positive (`seen.shown`).
##   Prints one row of `TURNS_PLANNED` for each sweep, keyed by card and level as table keys
##     it, then style and start of its path, so floor and its source are read off one run.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/strformat

import ../simulation/[body, hold, rig, walk]
from ./rig {.all.} import BANDS, SHOWN


proc main() =
  ## Plan each rig sweep toward `walk.MOST` at band of its hold, follow turning, and print its
  ## row.
  keepAnswers()
  for cut in SHOWN:
    var links: seq[Link]
    for (lead_arm, follow_arm) in cut.arms:
      links.add Link(ends: [(Body.One, lead_arm), (Body.Two, follow_arm)])
    let
      way = plannedWay(HUMAN, cut.band, links, Body.Two, MOST, STEP, cut.is_away, Body.Two)
      style = STYLES.find(way.path.problem.style)
      floor = (if way.found_rest and not way.is_stopped: "MOST" else: &"{turnsHeld(way):.4f}")
    echo &"(card: \"{cut.name} · {BANDS[ord(cut.band)]}\", positive: {floor}),  # style " &
        &"{style} from {way.apart:.3f} m, {way.moments.len} moments"


when isMainModule:
  main()
