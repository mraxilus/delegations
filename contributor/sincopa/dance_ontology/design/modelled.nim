## Ask body sim about every card reference draws, and write down which it agrees with.
##
##   Reference page carries two tags on each cell.  `kept` is Architect's, given by eye
##     on floor.  `modelled` is this one: whether sim reaches what card draws.  Goal is
##     both at hundred per cent, and gap between them is work left.
##   Written here rather than on page because asking sim costs minutes and page is
##     markup.  Same arrangement `design/turns` uses, and same reason.
##   Tag must not touch pins.  `review_page.drawingOf` cuts cards back out of built page
##     by collecting their `svg` elements alone, so badge outside drawing changes no pin
##     and no kept card is re-drawn by adding this.
##   Answers are keyed by question, never by card's own name: page already folds
##     duplicate pictures together and hands out identifiers, and second place doing
##     that would be second place to get it wrong.
##   Four manners are two motions.  Orbit about couple's centre is change of world
##     frame and moves neither dancer with respect to other, so manner that orbits is
##     physically turn of *other* dancer, other way about.  Architect's reading, and it
##     is what `sim/rigid` is asked.  What survives is whose crown hands are over: couple
##     raise them over dancer who walks under, which follows manner, not physics.
##   Card sim has not been asked about is absent, and gets no tag: unasked reads as
##     unasked rather than as disagreement.

{.experimental: "strictFuncs".}

import std/[json, options, strformat, tables]

import ../sim/[body, hold, rig, rigid, walk]
import ../src/dance_ontology/draw/terms
import ../src/dance_ontology/frame
import ../src/dance_ontology/rotation
import ./parts


const CROWN = Band.Crown
  ## Whole reference is drawn over crown: `design/parts` picks `ABOVE_BOTH` for chains
  ## and `ABOVE_ONE`/`ABOVE_OTHER` for singles, so no card asks about any other band.


func bodyOf(who: terms.Dancer): Body =
  ## Two enums are named `Dancer` in this tree, `terms`' and `rotation`'s.
  ## `parts.MANNERS` carries `terms`' one, beside `rotation`'s `About`.
  if ord(who) == ord(terms.Dancer.Lead): Body.One else: Body.Two

func otherThan(who: Body): Body =
  if ord(who) == ord(Body.One): Body.Two else: Body.One

func armOf(a: terms.Arm): body.Arm =
  if ord(a) == ord(terms.Arm.L): body.Arm.Left else: body.Arm.Right

func linksOf(holds: Holds): seq[Link] =
  ## Read `parts`'s hold table: index is lead's arm, value is follow's it joins.
  for lead, follow in holds.pairs:
    if follow.isSome:
      result.add Link(ends: [(Body.One, armOf(terms.Arm(lead))),
                             (Body.Two, armOf(follow.get))])


type Carried = object ## How far one hold carries, one manner, each way.
  restHolds: bool
  stopped: array[2, bool] ## Index 0 is turning back, 1 is turning on.
  at: array[2, float]

func reaches(c: Carried; turns: float): bool =
  ## Whether that manner carries hold this far, in its own positive sense.
  if not c.restHolds: return false
  let i = if turns >= 0.0: 1 else: 0
  not c.stopped[i] or abs(turns) <= c.at[i]

var settled: Table[string, float]
  ## Where each hold stands, once found.  Finding it costs hundred settles of
  ## three thousand steps apiece, and same hold at same band was being asked for
  ## it forty times over: caching cannot move any figure, only stop re-deriving
  ## one already had.

proc standsAt(links: seq[Link]; away: bool): float =
  var key = (if away: "|" else: "")
  for l in links:
    for e in l.ends:
      key.add $ord(e.body) & $ord(e.arm)
  if key notin settled:
    settled[key] = restApart(HUMAN, CROWN, links, away)
  settled[key]

proc carried(links: seq[Link]; away: bool; manner: Manner; most: float): Carried =
  ## Sweep this hold under this manner, both ways.
  let
    walks = bodyOf(MANNERS[manner].who)
    turner = if ord(MANNERS[manner].about) == ord(About.Axis): walks
             else: otherThan(walks)
    sw = swept(HUMAN, CROWN, links, who = turner, most = most, away = away,
               head = walks, apart = standsAt(links, away))
  result.restHolds = sw.restHolds
  # Orbit is other dancer turned other way about, so its two ways are swapped.
  let flip = ord(MANNERS[manner].about) != ord(About.Axis)
  result.stopped = [(if flip: sw.pos.stopped else: sw.neg.stopped),
                    (if flip: sw.neg.stopped else: sw.pos.stopped)]
  result.at = [(if flip: sw.pos.at else: sw.neg.at),
               (if flip: sw.neg.at else: sw.pos.at)]


func holdsOf(target: Frame): Holds =
  ## Which hands this frame joins, in `parts`'s own terms.
  for side in Side:
    if target.hold[side].isSome:
      let
        lead = (if ord(side) == ord(Side.Left): terms.Arm.L else: terms.Arm.R)
        follow = (if ord(target.hold[side].get) == ord(Site.LeftHand): terms.Arm.L
                  else: terms.Arm.R)
      result[lead] = some follow

func restsFacing(target: Frame): bool =
  ## Whether frame rests face to face rather than pillion lead.  Same reading
  ## `review_page` makes, by `phaseOf`, and never written down.
  if target.countHolds < 2: true else: phaseOf(holdsOf(target)) < 1e-9


proc answers(): OrderedTable[string, bool] =
  ## Every card sim can be asked about, keyed as page keys its own pictures.
  result = initOrderedTable[string, bool]()

  # `A`. Standard diagram: eight frames, each drawn at two facings.
  #   `twist` names facing *drawn* -- nought face to face, one pillion lead --
  #     and not half turns from frame's own rest, which is what this asked at
  #     first.  Frame that rests pillion is therefore at rest at twist of one,
  #     and half turn from it at nought: A10 and A12 read "at rest" for that
  #     reason, and asking them for half turn called them unreachable.
  #   A17 is last frame drawn turned other way about, and is asked so.
  func amountFor(target: Frame; twist: int): float =
    if (twist == 0) == restsFacing(target): 0.0 else: 0.5
  for i, target in FRAMES:
    let
      links = linksOf(holdsOf(target))
      away = not restsFacing(target)
      far = standsAt(links, away)
    for twist in [0, 1]:
      result[&"A{i * 2 + twist + 1}"] =
        holdsAt(HUMAN, CROWN, links, amountFor(target, twist), away, apart = far)
  result["A17"] = block:
    let
      target = FRAMES[^1]
      links = linksOf(holdsOf(target))
      away = not restsFacing(target)
    holdsAt(HUMAN, CROWN, links, -amountFor(target, 1), away,
            apart = standsAt(links, away))

  # `B` and `E`: four single-hand holds, four manners, four quarters.
  for c, single in SINGLES:
    let links = linksOf(single.holds)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
        walk = carried(links, false, manner, most = 1.2)
        far = standsAt(links, false)
      for q in 0 ..< QUARTERS_ROUND:
        let at = sense * q.float / QUARTERS_ROUND.float
        result[&"st_{tag}_{c}_{q}"] =
          holdsAt(HUMAN, CROWN, links, at, head = bodyOf(MANNERS[manner].who),
                  apart = far)
        result[&"tr_{tag}_{c}_{q}_{(q + 1) mod QUARTERS_ROUND}"] =
          walk.reaches(sense * (q + 1).float / QUARTERS_ROUND.float)
      result[&"rd_{tag}_{c}"] = walk.reaches(sense)

  # `C` and `D`: two chains, seven positions each, half turn apart.
  #   Their captions count *clockwise seen from above*, which is turn's negative
  #   way, so wind's sign is flipped before it is asked.  Both chains happen to
  #   stop at same place each way, so this changes no answer today -- it is here
  #   because it would change one for hold that did not.
  for (tag, arms, away) in [("C", HAND_TO_HAND, false), ("D", PAIRED, true)]:
    let
      links = linksOf(arms)
      far = standsAt(links, away)
    for i, w in STEPS:
      result[tag & $(i + 1)] = holdsAt(HUMAN, CROWN, links, -w, away, apart = far)

  # `F` and `G`: each chain under each manner, whole chain and each half of it.
  #   These are moving cards, so they are asked whether couple carry along them
  #   rather than whether pose stands there.
  for (key, arms, away) in [("h", HAND_TO_HAND, false), ("p", PAIRED, true)]:
    let links = linksOf(arms)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
        walk = carried(links, away, manner, most = 1.6)
      result[&"{key}c_{tag}"] = walk.reaches(sense * STEPS[^1])
      for i in 0 ..< STEPS.len - 1:
        result[&"{key}w_{tag}_{i}"] = walk.reaches(sense * STEPS[i + 1])


when isMainModule:
  var said = newJObject()
  for id, got in answers():
    said[id] = %got
  writeFile("design/modelled.json", pretty(said) & "\n")
  echo "wrote design/modelled.json: ", said.len, " answers"
