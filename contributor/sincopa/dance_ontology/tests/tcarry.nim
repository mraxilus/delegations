discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
batchable: true
joinable: true
"""
## Test what page does when quarter is turned, not only what sweep does.
##
##   Page walks its own quarters through `sim/carry`, and used to decide each
##     small move its own way; laws here hold that path to what sweep finds,
##     since sweep is authority for where turn blocks and page is what reader
##     presses.
##   Model lives apart from `sim/page` so it can be driven here at all: page
##     reaches for `std/dom` and builds only on JS backend.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]

import ../sim/[body, carry, solve, sweep]


const
  ONE_HAND = [0, 1, 2, 3] ## Into `HOLDS`: four holds joining one hand to one.
  CROWN = 2 ## Into `LEVELS`: hands above head, on axis couple turn about.
  QUARTERS = 8 ## Quarters walked each way, which is two whole turns.


type Walk = object ## How far one hold turned one way, and what stopped it.
  reached: float ## Turns made good before block.
  stopped: bool
  why: Verdict ## What refused, where one did.


proc walk(h, lv: int; sign: float; quarters = QUARTERS): Walk =
  ## Walk quarters as page walks them, from fresh rest, until one is refused.
  hold = h
  level = lv
  carried = none(Solved)
  tally = default(array[Way, float])
  reseeds = 0
  settleFresh()
  doAssert carried.isSome, "Hold should rest before it is turned; got `" & HOLDS[h].name & "`."
  for q in 1 .. quarters:
    inFlight = some(Move(way: Way.FollowAxis, sign: sign))
    moveStart = carried
    tallyStart = tally
    reseedsStart = reseeds
    done = 0.0
    blocked = none(Verdict)
    while not walked(): discard
    if blocked.isSome:
      return Walk(reached: result.reached, stopped: true, why: blocked.get)
    result.reached += 0.25


suite "turning on the page":
  test "a hand over the head turns as far as it is asked, either way":
    # Arm above head is on axis couple turn about, so it winds round nothing
    # and runs out of nothing.  Sweep finds no block within two and half turns
    # for any of these; page walks same hold and must find none either.
    for h in ONE_HAND:
      for (way, sign) in [("anticlockwise", 1.0), ("clockwise", -1.0)]:
        let w = walk(h, CROWN, sign)
        if w.stopped:
          echo "    ", HOLDS[h].name, " above ", way, ": stopped at ",
            formatFloat(w.reached, ffDecimal, 2), " turns, ", w.why.reason
        check not w.stopped
        check w.reached >= 2.0 - 1e-9

  test "a block names what refused it":
    # Verdict carried out of walk is one that failed.  Block reported with no
    # reason is block page cannot explain, and page prints `holds` for it.
    for h in ONE_HAND:
      for lv in 0 ..< LEVELS.len:
        for sign in [1.0, -1.0]:
          let w = walk(h, lv, sign, quarters = 4)
          if w.stopped:
            check w.why.reason != Reason.None
            check not w.why.ok

  test "page stops no sooner than sweep does, over crown":
    # Two paths through one model must not disagree about whether hold turns:
    # one is what reader presses, other is what `verdicts.md` is written from.
    #   One hold, not four: sweep spends its time setting rest up, so each
    #     costs about minute, and test above already asks every hold whether
    #     it turns.  This one binds two paths together, which one hold does.
    const BROKEN = 0 ## `L-l`, hold page used to stop after quarter of turn.
    hold = BROKEN
    level = CROWN
    carried = none(Solved)
    settleFresh()
    let sw = swept(world(restApart), Body.Two, most = 0.75)
    check sw.restHolds
    for (blk, sign) in [(sw.pos, 1.0), (sw.neg, -1.0)]:
      if not blk.stopped:
        check not walk(BROKEN, CROWN, sign, quarters = 3).stopped
