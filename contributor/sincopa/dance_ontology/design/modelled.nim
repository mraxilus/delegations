## Ask body simulation about every card reference draws, and write down which it agrees with.
##
##   Reference page carries two tags on each cell.  `kept` is Architect's, given by eye
##     on floor.  `modelled` is this one: whether simulation reaches what card draws.  Goal is
##     both at hundred per cent, and gap between them is work left.
##   Written here rather than on page because asking simulation costs minutes and page is
##     markup.  Same arrangement `design/turns` uses, and same reason.
##   Tag must not touch pins.  `review_page.drawingOf` cuts cards back out of built page
##     by collecting their `svg` elements alone, so badge outside drawing changes no pin
##     and no kept card is re-drawn by adding this.
##   Answers are keyed by question, never by card's own name: page already folds
##     duplicate pictures together and hands out identifiers, and second place doing
##     that would be second place to get it wrong.
##   Four manners are two motions.  Orbit keeps walker facing centre, so it is physically
##     turn of dancer at centre, other way about.  Architect's reading, and it is what
##     `simulation/rigid` is asked (`asks.turnerOf`).  Connection goes round dancer who
##     turns, so hands go over their crown, orbit or not.
##   Card simulation has not been asked about is absent, and gets no tag: unasked reads as
##     unasked rather than as disagreement.
##   Answers are kept with stamp of physics, questions and this verb (`design/stamps`), and
##     verb whose stamp is unchanged asks nothing again.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[cpuinfo, json, os, sequtils, strformat, tables, typedthreads]

import ../simulation/[body, hold, rig, walk]
import ./[asks, parts, stamps]


const KEPT_MODELLED* = currentSourcePath().parentDir / "modelled.json"
  ## Where answers are kept, with their stamp.


const CROWN = Band.Crown
  ## Whole reference is drawn over crown: `design/parts` picks `ABOVE_BOTH` for chains
  ## and `ABOVE_ONE`/`ABOVE_OTHER` for singles, so no card asks about any other band.


type Question* = object  ## One card's question, as data, so threads may share it.
  key*: string
  links*: seq[Link]
  is_away*: bool
  is_still*: bool  ## Still card: whether pose holds; else whether couple carry.
  turns*: float  ## How far `who` turns, simulation's own sense: to still, or carried.
  is_either_way*: bool  ## Still that fixes no way about: wound either way.
  who*, head*: Body  ## Who turns, and whose crown hands go over: one dancer.


func moving(key: string, links: seq[Link], is_away: bool, manner: Manner, amount: float): Question =
  ## Whether this hold carries this far under this manner, page turning manner's own
  ## dancer `amount` turns clockwise (`asks.turnerOf`).
  ##   Couple stand for turn they are about to take, so question goes straight to
  ##     `walk.reaches`, which asks it of every distance couple may stand at and
  ##     answers at first that carries it.  Sweeping once and reading several
  ##     answers off it would be cheaper, but it would pin whole manner to one
  ##     distance again, which is what Architect ruled against.
  let (who, turns) = turnerOf(manner, amount)
  Question(
    key: key,
    links: links,
    is_away: is_away,
    is_still: false,
    turns: turns,
    who: who,
    head: who,
  )

func questions*(): seq[Question] =
  ## Every card simulation can be asked about, keyed as page keys its own pictures, in
  ## page's own order.
  # Every still, as `asks` lists them: wound to its facing and asked whether
  # pose holds there.
  for ask in stillAsks():
    result.add Question(
      key: ask.key,
      links: ask.links,
      is_away: ask.isRestAway,
      is_still: true,
      turns: ask.turns,
      is_either_way: ask.is_either_way,
      who: ask.who,
      head: ask.head,
    )

  # `B` and `E`: four single-hand holds, four manners, four quarters, moving.  Page walks
  # every manner's own dancer clockwise, one quarter per card (`parts.singleTurnParts`).
  #   Turned by chain's sense instead, lead's own turn and lead's orbit went anticlockwise
  #     where caption says clockwise.
  for connection, single in SINGLES:
    let links = linksOf(single.holds)
    for manner in Manner:
      let tag = MANNERS[manner].tag
      for quarter in 0..<QUARTERS_ROUND:
        result.add moving(
          &"tr_{tag}_{connection}_{quarter}_{(quarter + 1) mod QUARTERS_ROUND}",
          links,
          isRestAway(restOf(single.holds)),
          manner,
          float(quarter + 1) / float(QUARTERS_ROUND),
        )
      result.add moving(
        &"rd_{tag}_{connection}",
        links,
        isRestAway(restOf(single.holds)),
        manner,
        1.0,
      )

  # `F` and `G`: each chain under each manner, whole chain and each half of it.
  #   These are moving cards, so they are asked whether couple carry along them
  #   rather than whether pose stands there.
  for (key, arms) in [("h", HAND_TO_HAND), ("p", PAIRED)]:
    let
      links = linksOf(arms)
      is_away = isRestAway(restOf(arms))
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
      # Page walks chain by manner's own dancer, `windSense` half turns per step
      # (`parts.chainTurnParts`).
      result.add moving(&"{key}c_{tag}", links, is_away, manner, sense * STEPS[^1])
      for i in 0..<STEPS.len - 1:
        # Edge is walked entire, so what it asks of couple is its *furthest*
        # wound end, kept with its own sign, and not where it happens to
        # finish.  Chain runs from swan in to frame and out to other swan, so
        # magnitude falls then rises: asking destination alone made first edge,
        # which leaves far swan, read as easy as its near end, while last edge,
        # which arrives at other swan, read as hard as its far one.  Architect
        # saw it at once -- they are same edge mirrored.
        let far = (if abs(STEPS[i]) > abs(STEPS[i + 1]): STEPS[i]
                   else: STEPS[i + 1])
        result.add moving(&"{key}w_{tag}_{i}", links, is_away, manner, sense * far)

# Mutable and global: thread takes one argument, so workers write into slots allotted here.
var TOLD: seq[bool]  ## Each worker writes its own questions' answers here.

proc answered(question: Question): bool =
  ## Whether simulation models one card: carried walk first, since it answers most cards in
  ## seconds, and planned way only where it stops, since that pays minutes per card.
  if question.is_still:
    isHoldingAt(
      HUMAN,
      CROWN,
      question.links,
      question.turns,
      question.is_away,
      question.head,
      is_either_way = question.is_either_way,
      who = question.who,
    ) or isPlannedHolding(
      HUMAN,
      CROWN,
      question.links,
      question.turns,
      question.is_away,
      question.head,
      is_either_way = question.is_either_way,
      who = question.who,
    )
  else:
    isReaching(
      HUMAN,
      CROWN,
      question.links,
      question.turns,
      is_away = question.is_away,
      who = question.who,
      head = question.head,
    ) or isPlannedReaching(
      HUMAN,
      CROWN,
      question.links,
      question.turns,
      is_away = question.is_away,
      who = question.who,
      head = question.head,
    )


proc work(slice: tuple[first, every: int]) {.thread.} =
  ## Answer every `every`th question from `first` on: worlds are engine's own
  ## and independent, so workers share nothing but `TOLD`.
  ##   Each worker lists questions for itself: list holds strings and
  ##     sequences, whose counts one list read by four threads raced on, and
  ##     verb died of illegal instruction inside engine every other run.
  {.cast(gcsafe).}:
    let asked = questions()
    var i = slice.first
    while i < asked.len:
      TOLD[i] = answered(asked[i])
      i += slice.every


proc answers(): OrderedTable[string, bool] =
  ## Every card's answer, keyed as page keys its own pictures.
  ##   Asked on every core at once: each question builds its own worlds, and
  ##     answering all of them one after another cost fifteen minutes where
  ##     four cores cost four minutes.  Order of answers is page's own, whatever
  ##     order they were found in.
  let asked = questions()
  TOLD = newSeq[bool](asked.len)
  let cores = max(1, countProcessors())
  var workers = newSeq[Thread[tuple[first, every: int]]](cores)
  for worker in 0..<cores:
    createThread(workers[worker], work, (worker, cores))
  joinThreads(workers)
  result = initOrderedTable[string, bool]()
  for i, question in asked:
    result[question.key] = TOLD[i]


proc modelledStamp*(): string = stampOf(currentSourcePath(), questions().mapIt($it))
  ## Stamp answers carry: physics, this verb, and every question.


func kept(stamp: string, told: OrderedTable[string, bool]): string =
  ## Recording as file keeps it: stamp, then each card's answer in page's order.
  var said = newJObject()
  for id, is_modelled in told:
    said[id] = %is_modelled
  pretty(%*{"stamp": stamp, "answers": said}) & "\n"


proc main() =
  ## Record what simulation answers of every card, unless recording carries tree's stamp.
  let stamp = modelledStamp()
  if fileExists(KEPT_MODELLED) and parseFile(KEPT_MODELLED){"stamp"}.getStr == stamp:
    echo "design/modelled.json is up to date: ", stamp
    return
  writeFile(KEPT_MODELLED, kept(stamp, answers()))
  echo "wrote design/modelled.json: ", questions().len, " answers"


when isMainModule:
  main()
