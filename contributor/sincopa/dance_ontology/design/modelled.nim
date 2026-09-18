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

import std/[cpuinfo, json, strformat, tables, typedthreads]

import ../sim/[body, hold, rig, walk]
import ../src/dance_ontology/rotation
import ./[asks, parts]


const CROWN = Band.Crown
  ## Whole reference is drawn over crown: `design/parts` picks `ABOVE_BOTH` for chains
  ## and `ABOVE_ONE`/`ABOVE_OTHER` for singles, so no card asks about any other band.


type Question = object ## One card's question, as data, so threads may share it.
  key: string
  links: seq[Link]
  away: bool
  still: bool    ## Still card: whether pose holds; else whether couple carry.
  turns: float   ## Facing for still; how far to carry, in manner's own sense.
  either: bool   ## Still that fixes no way about: wound either way.
  who, head: Body ## Who turns, and whose crown hands go over, for moving card.

func moving(key: string; links: seq[Link]; away: bool; manner: Manner;
            turns: float): Question =
  ## Whether this hold carries this far under this manner, `turns` being already
  ## in sim's own sense (`asks.asked`).
  ##   Couple stand for turn they are about to take, so question goes straight to
  ##     `walk.reaches`, which asks it of every distance couple may stand at and
  ##     answers at first that carries it.  Sweeping once and reading several
  ##     answers off it would be cheaper, but it would pin whole manner to one
  ##     distance again, which is what Architect ruled against.
  let
    walks = bodyOf(MANNERS[manner].who)
    turner = if ord(MANNERS[manner].about) == ord(About.Axis): walks
             else: otherThan(walks)
    # Orbit is other dancer turned other way about, so its sense is flipped.
    flip = ord(MANNERS[manner].about) != ord(About.Axis)
    way = (if flip: -turns else: turns)
  Question(key: key, links: links, away: away, still: false, turns: way,
           who: turner, head: walks)

func questions(): seq[Question] =
  ## Every card sim can be asked about, keyed as page keys its own pictures, in
  ## page's own order.
  # Every still, as `asks` lists them: wound to its facing and asked whether
  # pose holds there.
  for a in stillAsks():
    result.add Question(key: a.key, links: a.links, away: a.away, still: true,
                        turns: a.turns, either: a.either, who: Body.Two, head: a.head)

  # `B` and `E`: four single-hand holds, four manners, four quarters, moving.
  for c, single in SINGLES:
    let links = linksOf(single.holds)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
      for q in 0 ..< QUARTERS_ROUND:
        result.add moving(&"tr_{tag}_{c}_{q}_{(q + 1) mod QUARTERS_ROUND}", links, false,
                          manner, asked(sense * (q + 1).float / QUARTERS_ROUND.float))
      result.add moving(&"rd_{tag}_{c}", links, false, manner, asked(sense))

  # `F` and `G`: each chain under each manner, whole chain and each half of it.
  #   These are moving cards, so they are asked whether couple carry along them
  #   rather than whether pose stands there.
  for (key, arms, away) in [("h", HAND_TO_HAND, false), ("p", PAIRED, true)]:
    let links = linksOf(arms)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
      result.add moving(&"{key}c_{tag}", links, away, manner, asked(sense * STEPS[^1]))
      for i in 0 ..< STEPS.len - 1:
        # Edge is walked entire, so what it asks of couple is its *furthest*
        # wound end, kept with its own sign, and not where it happens to
        # finish.  Chain runs from swan in to frame and out to other swan, so
        # magnitude falls then rises: asking destination alone made first edge,
        # which leaves far swan, read as easy as its near end, while last edge,
        # which arrives at other swan, read as hard as its far one.  Architect
        # saw it at once -- they are same edge mirrored.
        let far = (if abs(STEPS[i]) > abs(STEPS[i + 1]): STEPS[i]
                   else: STEPS[i + 1])
        result.add moving(&"{key}w_{tag}_{i}", links, away, manner, asked(sense * far))

var told: seq[bool] ## Each worker writes its own questions' answers here.

proc work(slice: tuple[first, every: int]) {.thread.} =
  ## Answer every `every`th question from `first` on: worlds are engine's own
  ## and independent, so workers share nothing but `told`.
  ##   Each worker lists questions for itself: list holds strings and
  ##     sequences, whose counts one list read by four threads raced on, and
  ##     verb died of illegal instruction inside engine every other run.
  {.cast(gcsafe).}:
    let asked = questions()
    var i = slice.first
    while i < asked.len:
      let q = asked[i]
      told[i] = (if q.still: holdsAt(HUMAN, CROWN, q.links, q.turns, q.away, q.head,
                                     either = q.either)
                 else: reaches(HUMAN, CROWN, q.links, q.turns, away = q.away,
                               who = q.who, head = q.head))
      i += slice.every

proc answers(): OrderedTable[string, bool] =
  ## Every card's answer, keyed as page keys its own pictures.
  ##   Asked on every core at once: each question builds its own worlds, and
  ##     answering all of them one after another cost fifteen minutes where
  ##     four cores cost four minutes.  Order of answers is page's own, whatever
  ##     order they were found in.
  let asked = questions()
  told = newSeq[bool](asked.len)
  let cores = max(1, countProcessors())
  var workers = newSeq[Thread[tuple[first, every: int]]](cores)
  for w in 0 ..< cores:
    createThread(workers[w], work, (w, cores))
  joinThreads(workers)
  result = initOrderedTable[string, bool]()
  for i, q in asked:
    result[q.key] = told[i]


when isMainModule:
  var said = newJObject()
  for id, got in answers():
    said[id] = %got
  writeFile("design/modelled.json", pretty(said) & "\n")
  echo "wrote design/modelled.json: ", said.len, " answers"
