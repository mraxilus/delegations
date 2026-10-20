## Measure how far plan carries each hold over crown each way from rest: floors law of planned
## sweep holds both recordings to (`tests/suites/test_asks.TURNS_PLANNED`).
##
##   Instrument run by hand (`tools/build.nim floors`), never by suite: each way plans every
##     style on every core, and both chains alone planned 64 paths in 377 s on four cores,
##     measured 2026-10-12.  Law reads floors as figures, so this is how they are read again.
##   Asks `walk.plannedWay`, which recordings ask where walk falls short, of holds over crown
##     `design/turns` sweeps (`turns.sweeps`): rig's four sweeps over crown are four of those holds.
##   Prints one row of `TURNS_PLANNED` for each hold, as table writes it, then style and start
##     of each way's path, so floor and its source are read off one run.
##   Cost: plans hold that walk carries free too, which no recording asks, so its row says what
##     plan carries and not what walk does.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[strformat, strutils]

import ../simulation/[body, rig, walk]
import ./turns


proc main() =
  ## Plan each hold over crown toward `walk.MOST` each way, follow turning, and print each row.
  keepAnswers()
  for sweep in sweeps():
    if sweep.band != Band.Crown: continue
    let
      links = linksOf(sweep.hold)
      is_away = isRestingAway(sweep.hold)
    var
      row = &"(hold: \"{sweep.hold}\""
      sources: seq[string]
    for (name, step) in [("negative", -STEP), ("positive", STEP)]:
      let
        way = plannedWay(HUMAN, Band.Crown, links, Body.Two, MOST, step, is_away, Body.Two)
        held = turnsHeld(way)
        style = STYLES.find(way.path.problem.style)
      row.add (if way.found_rest and not way.is_stopped: &", {name}: MOST"
               else: &", {name}: {held:.4f}")
      sources.add &"{name} by style {style} from {way.apart:.3f} m, {way.moments.len} moments"
    echo row, "),  # ", sources.join("; ")


when isMainModule:
  main()
