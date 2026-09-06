## Turning body, moment by moment, until something gives.
##
##   Turn is not pose: it is path of them.  From rest that holds, one
##     body is turned one fiftieth of turn each time and arms follow by
##     small moves from where they were -- what dancer's arms do, which is
##     not same as most comfortable pose at each angle taken fresh.
##     Predecessor of this module learnt same lesson about rope:
##     shortest path has no memory, and solver that always re-minimises can
##     never report arm as wound.
##   Where no small move holds, step is halved down to one two-hundredth
##     for angle, and that is block.  Then pose is sought afresh
##     at failed angle: if one exists and is only one step's motion away
##     turn goes on from it, marked as re-seeded -- elbow flipping
##     over, say -- and if it exists but is far, block stands and
##     report says pose could hold there if arms were re-organised.
##     That double report is honest one: carried pose is what
##     dance does, found pose is what still picture allows.
##     Cost: block depends on path, so same angle reached another
##       way could hold.  Accepted -- that is what block is.
##   Every pose sweep carries is carried with its verdict, found once
##     when pose was; and sweeps of different holds, which share
##     nothing, are run side by side on what cores there are.

{.experimental: "strictFuncs".}

import std/options

import ./[body, read, solve]


type
  Moment* = object ## Couple at one turn of sweep.
    turn*: float ## Turns from rest, signed.
    state*: State
    verdict*: Verdict
    reseeded*: bool ## Reached by fresh search where no small move held.

  Block* = object ## Where sweep stopped one way.
    at*: float ## Turns reached; `most` where nothing stopped it.
    stopped*: bool
    why*: Verdict ## What fails step beyond, when stopped.
    foundAnyway*: bool ## Whether pose exists step beyond, re-organised.

  Sweep* = object ## Hold turned as far as it goes each way.
    who*: Body
    rest*: State
    restHolds*: bool
    moments*: seq[Moment] ## In ascending turn, rest among them.
    neg*, pos*: Block
    step*: float


const
  STEP* = 0.02 ## Turns per moment of sweep.
  SUBSTEPS = 4 ## Small moves per moment: arm sliding round flank needs
               ## flank to move bit by bit.
  CREEP* = STEP / SUBSTEPS.float ## Turns per small move: most any body is
               ## turned before arms are asked to follow, here and on
               ## page, which carries its sliders same way.
  SETTLING = 0.05 ## Comfort fresh pose must gain to be taken over
                  ## carried one, plus one unit per metre any joint would jump:
                  ## arms do not flip over for nothing.
  MOST* = 2.5 ## Turns swept each way looking for block.


func atTurn(rest: State; who: Body; turn: float): State =
  result = rest
  result.stance = turned(rest.stance, who, turn)


func crept(rest: State; who: Body; here: Solved; fromTurn, toTurn: float):
    tuple[got: Solved, turn: float] =
  ## Follow from `here` at `fromTurn` towards `toTurn` in small moves; where
  ## it gets to, which is `toTurn` unless move failed.
  result = (here, fromTurn)
  for i in 1 .. SUBSTEPS:
    let
      t = fromTurn + (toTurn - fromTurn) * i.float / SUBSTEPS.float
      next = followed(atTurn(rest, who, t), result.got.state)
    if next.isNone:
      return
    result = (next.get, t)


func momentOf(turn: float; got: Solved; reseeded = false): Moment =
  Moment(turn: turn, state: got.state, verdict: got.verdict, reseeded: reseeded)


func sweptWay(rest: Solved; who: Body; sign, most: float;
              moments: var seq[Moment]): Block =
  ## Turn one way from solved rest, adding moments found.
  ##   At every moment pose found afresh is taken where arms go
  ##     round bodies same way as before and it is enough more
  ##     comfortable to be worth move; otherwise arms are carried on
  ##     by small moves, and where no small move holds turn is blocked.
  var
    here = rest
    t = 0.0
  while abs(t) < most - 1e-9:
    let
      tn = t + sign * STEP
      sn = atTurn(rest.state, who, tn)
      fresh = settled(sn)
      got = crept(rest.state, who, here, t, tn)
      carried = abs(got.turn - tn) < 1e-9
    if fresh.isSome and
       sameRoute(here.state, here.verdict, fresh.get.state, fresh.get.verdict) and
       sameCrossings(here.state, here.verdict, fresh.get.state, fresh.get.verdict) and
       (not carried or fresh.get.verdict.cost <
          got.got.verdict.cost - SETTLING - jump(got.got.verdict, fresh.get.verdict)):
      here = fresh.get
      t = tn
      moments.add momentOf(t, here, reseeded = not carried)
      continue
    if carried:
      here = got.got
      t = tn
      moments.add momentOf(t, here)
      continue
    # No small move holds.  Before calling it block, look harder for
    # pose arms could take: grid is coarse and corner is narrow.
    let stuck = got.got
    let finer = settled(sn, fine = true)
    if finer.isSome and
       sameRoute(stuck.state, stuck.verdict, finer.get.state, finer.get.verdict) and
       sameCrossings(stuck.state, stuck.verdict, finer.get.state, finer.get.verdict):
      here = finer.get
      t = tn
      moments.add momentOf(t, here, reseeded = true)
      continue
    if abs(got.turn - t) > 1e-9:
      moments.add momentOf(got.turn, stuck)
    return Block(at: abs(got.turn), stopped: true,
                 why: reason(atTurn(rest.state, who, got.turn + sign * STEP / SUBSTEPS.float),
                             stuck.state),
                 foundAnyway: fresh.isSome or finer.isSome)
  Block(at: most, stopped: false)


const
  TRIES = 4 ## Rests tried before sweep.
  TRIAL = 0.30 ## Turns each way rest is tried for.


func setUp(rest: State; who: Body): Option[Solved] =
  ## Rest to sweep from: of few distinct rests search settles
  ## on, one that turns furthest in short trial each way, and
  ## least strained where two go equally far.
  ##   Couple set hold up for turn they are about to do; nothing
  ##     here is tuned, only chosen among poses that all hold at rest.
  var arranged = rest
  arranged.overhead = true
  arranged.turning = who
  let all = restingsWith(arranged, fine = true)
  var
    bestScore = -Inf
  for i in 0 ..< min(TRIES, all.len):
    var
      negs, poss: seq[Moment]
      strain = 0.0
    let
      n = sweptWay(all[i], who, -1.0, TRIAL, negs)
      p = sweptWay(all[i], who, 1.0, TRIAL, poss)
    for m in negs: strain = max(strain, m.verdict.strain)
    for m in poss: strain = max(strain, m.verdict.strain)
    let score = n.at + p.at - 0.1 * strain
    if score > bestScore:
      bestScore = score
      result = some(all[i])


func swept*(rest: State; who: Body; most = MOST): Sweep =
  ## Turn `who` from rest as far as it goes each way.
  result.who = who
  result.step = STEP
  let solved = if rest.params.len == rest.links.len:
                 some(Solved(state: rest, verdict: evaluate(rest)))
               else: setUp(rest, who)
  result.restHolds = solved.isSome
  if solved.isNone:
    result.rest = rest
    result.neg = Block(at: 0.0, stopped: true)
    result.pos = Block(at: 0.0, stopped: true)
    return
  result.rest = solved.get.state
  var neg, pos: seq[Moment]
  result.neg = sweptWay(solved.get, who, -1.0, most, neg)
  result.pos = sweptWay(solved.get, who, 1.0, most, pos)
  for i in countdown(neg.len - 1, 0):
    result.moments.add neg[i]
  result.moments.add momentOf(0.0, solved.get)
  result.moments.add pos


func limit*(sw: Sweep; sign: float): float =
  ## Turns reached that way.
  if sign < 0.0: sw.neg.at else: sw.pos.at


func at*(sw: Sweep; turn: float): Option[Moment] =
  ## Moment nearest turn, or none past block.
  if sw.moments.len == 0 or turn < -sw.neg.at - 1e-9 or turn > sw.pos.at + 1e-9:
    return none(Moment)
  var best = 0
  for i in 1 ..< sw.moments.len:
    if abs(sw.moments[i].turn - turn) < abs(sw.moments[best].turn - turn):
      best = i
  some(sw.moments[best])


#[ Many At Once ]#

type Job* = object ## One sweep to run: hold, who turns, how far.
  rest*: State
  who*: Body
  most*: float


when defined(js) or not compileOption("threads"):
  proc sweptAll*(jobs: openArray[Job]): seq[Sweep] =
    ## Every job's sweep, in jobs' order, one after another.
    for job in jobs:
      result.add swept(job.rest, job.who, job.most)
else:
  import std/[atomics, cpuinfo, typedthreads]

  type Work = object ## What worker thread is handed.
    jobs: ptr UncheckedArray[Job]
    done: ptr UncheckedArray[Sweep]
    n: int
    next: ptr Atomic[int]

  proc worker(w: Work) {.thread.} =
    ## Take next job not yet taken, sweep it, and put sweep in its
    ## slot, until there are none.
    while true:
      let i = w.next[].fetchAdd(1)
      if i >= w.n:
        break
      w.done[i] = swept(w.jobs[i].rest, w.jobs[i].who, w.jobs[i].most)

  proc sweptAll*(jobs: openArray[Job]): seq[Sweep] =
    ## Every job's sweep, in jobs' order, run on as many threads as
    ## there are cores.
    ##   Each sweep is pure function of its job and touches nothing
    ##     shared, so threads share only counter of next job;
    ##     slot each writes is its own until every thread has joined.
    result = newSeq[Sweep](jobs.len)
    if jobs.len == 0:
      return
    var
      owned = @jobs
      next: Atomic[int]
      threads = newSeq[Thread[Work]](min(jobs.len, max(1, countProcessors())))
    let w = Work(jobs: cast[ptr UncheckedArray[Job]](owned[0].addr),
                 done: cast[ptr UncheckedArray[Sweep]](result[0].addr),
                 n: jobs.len, next: next.addr)
    for t in threads.mitems:
      createThread(t, worker, w)
    joinThreads(threads)
