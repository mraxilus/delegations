## Ask body sim about every card reference draws, and write down which it agrees with.
##
##   Reference page carries two tags on each cell.  `kept` is Architect's, given by
##     eye on floor.  `modelled` is this one: whether sim reaches what card draws.
##     Goal is both at hundred per cent, and gap between them is work left.
##   Tag is written here rather than on page because asking sim costs minutes and
##     page is markup.  Same arrangement `design/turns` uses, and same reason.
##   Tag must not touch pins.  `review_page.drawingOf` cuts cards back out of built
##     page by collecting their `svg` elements alone, so badge outside drawing
##     changes no pin and no kept card is re-drawn by adding this.
##   Only cards sim has actually been asked about appear.  Card with no answer gets
##     no tag, which reads as unasked rather than as disagreement.

{.experimental: "strictFuncs".}

import std/[json, tables]

import ../sim/[body, hold, rig, walk]
import ./parts


const CROWN = Band.Crown
  ## Whole reference is drawn over crown: `design/parts` picks `ABOVE_BOTH` for
  ## chains, and every other card above too.


proc reached(arms: seq[(Arm, Arm)]; away: bool): seq[bool] =
  ## Whether sweep carries this chain to each of `STEPS`, in their order.
  ##   Captions count clockwise seen from above, which is sweep's negative way.
  var links: seq[Link] = @[]
  for (a, b) in arms:
    links.add Link(ends: [(Body.One, a), (Body.Two, b)])
  let sw = swept(HUMAN, CROWN, links, most = 1.6, away = away)
  for w in STEPS:
    if not sw.restHolds:
      result.add false
    else:
      let side = if w >= 0.0: sw.neg else: sw.pos
      result.add (not side.stopped or abs(w) <= side.at)


proc answers(): OrderedTable[string, bool] =
  ## Every card sim can be asked about today, and what it says.
  result = initOrderedTable[string, bool]()
  for i, got in reached(@[(Arm.Left, Arm.Right), (Arm.Right, Arm.Left)], false):
    result["C" & $(i + 1)] = got
  for i, got in reached(@[(Arm.Left, Arm.Left), (Arm.Right, Arm.Right)], true):
    result["D" & $(i + 1)] = got


when isMainModule:
  var said = newJObject()
  for id, got in answers():
    said[id] = %got
  writeFile("design/modelled.json", pretty(said) & "\n")
  echo "wrote design/modelled.json"
