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

import std/[math, options]

import ./[body, limb, read, rig, solve]


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
  SUBSTEPS* = 4 ## Small moves per moment: arm sliding round flank needs
               ## flank to move bit by bit.
  CREEP* = STEP / SUBSTEPS.float ## Turns per small move: most any body is
               ## turned before arms are asked to follow, here and on
               ## page, which carries its sliders same way.
  SETTLING = 0.05 ## Comfort fresh pose must gain to be taken over
                  ## carried one, plus one unit per metre any joint would jump:
                  ## arms do not flip over for nothing.
  MOST* = 2.5 ## Turns swept each way looking for block.
  APART_STEP* = 0.01 ## How far couple step in or out each time.
  APART_MOST* = 0.90 ## Further than this no hold reaches anyway.
  GAP* = 0.10 ## Least clear air between torsos, metres.
  SHIFTS* = 3 ## Steps in or out tried after each moment of turn.


#[ Standing ]#

func apartOf*(st: array[Body, Stance]): float =
  let
    dx = st[Body.Two].centre.x - st[Body.One].centre.x
    dy = st[Body.Two].centre.y - st[Body.One].centre.y
  sqrt(dx * dx + dy * dy)

func withStance*(s: State; st: array[Body, Stance]): State =
  result = s
  result.stance = st

func shifted*(st: array[Body, Stance]; by: float): array[Body, Stance] =
  ## Follow moved `by` metres away from lead along line between
  ## their axes, lead standing still.
  let
    apart = apartOf(st)
    ux = (st[Body.Two].centre.x - st[Body.One].centre.x) / apart
    uy = (st[Body.Two].centre.y - st[Body.One].centre.y) / apart
  result = st
  result[Body.Two].centre = (st[Body.Two].centre.x + ux * by,
                             st[Body.Two].centre.y + uy * by)


func leastApart*(rig: Rig; st: array[Body, Stance]): float =
  ## Closest two may stand, axis to axis, with `GAP` of clear air
  ## between their torsos along line between them, whichever way each
  ## faces: each torso's half-extent along that line, and gap.
  let
    apart = apartOf(st)
    dx = (st[Body.Two].centre.x - st[Body.One].centre.x) / apart
    dy = (st[Body.Two].centre.y - st[Body.One].centre.y) / apart
    a = halfBreadth(rig, Part.Torso)
    b = halfDepth(rig, Part.Torso)
  result = GAP
  for who in Body:
    let
      dr = dx * sin(st[who].facing) - dy * cos(st[who].facing)
      df = dx * cos(st[who].facing) + dy * sin(st[who].facing)
    result += sqrt((a * dr) * (a * dr) + (b * df) * (b * df))


func roomOf*(rig: Rig; v: Verdict): float =
  ## Least room any held arm's joints have, either way.
  result = Inf
  for i in 0 ..< v.n:
    for k in 0 .. 1:
      result = min(result, room(rig, v.fits[i].joints[k]))

func freer*(rig: Rig; a, b: Verdict): bool =
  ## Whether `a` leaves joints freer than `b`: nearest joint further
  ## from either end of its range first, and more comfortable where that
  ## is equal.
  ##   Freedom, not comfort, is what stance is chosen for: couple who
  ##     stood where arms hang easiest would stand at arm's length with
  ##     elbows straight, and straight elbow is joint with nowhere
  ##     to go.
  let
    ra = roomOf(rig, a)
    rb = roomOf(rig, b)
  if abs(ra - rb) > 1e-9: ra > rb
  else: a.cost < b.cost - 1e-9


func agrees*(here: Solved; there: Option[Solved]): bool =
  ## Whether pose is one arms can be carried to from here: it holds, goes
  ## round bodies same way, and crosses same way.
  ##   Guards stepping in or out only, which couple choose to do and can
  ##     decline.  Carrying turn on is not choice, and gating it here is what
  ##     made page block turns sweep holds; `advanced` decides those.
  there.isSome and
    sameRoute(here.state, here.verdict, there.get.state, there.get.verdict) and
    sameCrossings(here.state, here.verdict, there.get.state, there.get.verdict)


func steppedIn*(here: var Solved): bool =
  ## Step couple in or out by one step where that leaves arms
  ## freer; whether they did.
  ##   Each way is first judged cheaply -- pose as it is, with
  ##     bodies moved -- and only way that promises is followed for
  ##     real, and taken only if it delivers.
  let
    apart = apartOf(here.state.stance)
    least = leastApart(here.state.rig, here.state.stance)
  var
    best = here.verdict
    by = 0.0
  for step in [-APART_STEP, APART_STEP]:
    if apart + step < least or apart + step > APART_MOST:
      continue
    let guess = evaluate(withStance(here.state, shifted(here.state.stance, step)))
    if freer(here.state.rig, guess, best):
      best = guess
      by = step
  if by == 0.0:
    return false
  let got = followed(withStance(here.state, shifted(here.state.stance, by)), here.state)
  if agrees(here, got) and freer(here.state.rig, got.get.verdict, here.verdict):
    here = got.get
    return true
  false


#[ Turning ]#

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


type
  Advance* {.pure.} = enum ## What one moment of turn came to.
    Fresh, ## Pose found afresh, worth moving to.
    Carried, ## Arms carried on from pose they were already in.
    Finer, ## Pose found past coarse grid where no small move held.
    Blocked ## Nothing holds there that arms can reach.

  Moved* = object ## Where one moment got to, and how.
    case how*: Advance
    of Advance.Blocked:
      why*: Verdict ## What refuses, once largest failure is as small as it goes.
      found*: bool ## Whether pose holds there anyway, out of arms' reach.
    else:
      got*: Solved ## Pose arms are in at moment's end.


func advanced*(here, stuck: Solved; next, blame: State;
               carried: Option[Solved]): Moved =
  ## Decide one moment of turn: take fresh pose, carry arms on, look harder,
  ## or block.
  ##   Fresh pose is taken only where arms go round bodies and cross same way
  ##     as before, and where it is enough more comfortable to be worth move.
  ##   Carried pose is taken as it stands: arms that reached it reached it, so
  ##     nothing further is asked of it.  Gating it as well refuses turns that
  ##     hold, which is what page used to do.
  ##   Where no small move holds, past coarse grid is looked once before turn
  ##     is called blocked: grid is coarse and corner is narrow.
  ##   `blame` is state failure is read in, which is step beyond where arms
  ##     stuck rather than whole moment, so reason names what stopped them.
  ##   Written once, for sweep and page both: they drew apart here, and page
  ##     blocked turns sweep did not (Article II.1).
  let fresh = settled(next)
  if fresh.isSome and
     sameRoute(here.state, here.verdict, fresh.get.state, fresh.get.verdict) and
     sameCrossings(here.state, here.verdict, fresh.get.state, fresh.get.verdict) and
     (carried.isNone or fresh.get.verdict.cost <
        carried.get.verdict.cost - SETTLING -
          jump(carried.get.verdict, fresh.get.verdict)):
    return Moved(how: Advance.Fresh, got: fresh.get)
  if carried.isSome:
    return Moved(how: Advance.Carried, got: carried.get)
  let finer = settled(next, fine = true)
  if finer.isSome and
     sameRoute(stuck.state, stuck.verdict, finer.get.state, finer.get.verdict) and
     sameCrossings(stuck.state, stuck.verdict, finer.get.state, finer.get.verdict):
    return Moved(how: Advance.Finer, got: finer.get)
  Moved(how: Advance.Blocked, why: reason(blame, stuck.state),
        found: fresh.isSome or finer.isSome)


func sweptWay(rest: Solved; who: Body; sign, most: float;
              moments: var seq[Moment]): Block =
  ## Turn one way from solved rest, adding moments found.
  ##   At every moment pose found afresh is taken where arms go
  ##     round bodies same way as before and it is enough more
  ##     comfortable to be worth move; otherwise arms are carried on
  ##     by small moves, and where no small move holds turn is blocked.
  ##   Couple step in or out after each moment, wherever that leaves joints
  ##     freer: dancers adjust their distance as they turn, and sweep that
  ##     held them still refused turns they could take by shifting their feet.
  var
    here = rest
    t = 0.0
  while abs(t) < most - 1e-9:
    let
      tn = t + sign * STEP
      sn = atTurn(rest.state, who, tn)
      got = crept(rest.state, who, here, t, tn)
      carried = abs(got.turn - tn) < 1e-9
      beyond = atTurn(rest.state, who, got.turn + sign * STEP / SUBSTEPS.float)
      moved = advanced(here, got.got, sn, beyond,
                       if carried: some(got.got) else: none(Solved))
    if moved.how == Advance.Blocked:
      if abs(got.turn - t) > 1e-9:
        moments.add momentOf(got.turn, got.got)
      return Block(at: abs(got.turn), stopped: true, why: moved.why,
                   foundAnyway: moved.found)
    here = moved.got
    t = tn
    # Couple stand where joints are freest and go on doing so as they turn,
    # stepping in or out centimetre at time, as they do on page.
    for i in 0 ..< SHIFTS:
      if not steppedIn(here):
        break
    # Moment counts as reseeded only where arms could not have carried
    # themselves there: fresh pose taken over working one is not reseeding.
    moments.add momentOf(t, here, reseeded = moved.how == Advance.Finer or
                                            (moved.how == Advance.Fresh and not carried))
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
