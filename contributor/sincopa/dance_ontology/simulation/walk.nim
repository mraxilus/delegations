## Turn couple until something gives, keeping every moment on way.
##
##   Page cannot run engine: engine is C and page is script in browser.  So sweep is
##     run here, natively, at build time, and page plays what came of it -- same
##     arrangement `design/turns` already uses for whole-cloth page, and reason
##     nothing on page needs to guess at physics.
##   Turn is walked in small steps rather than jumped, because whole point of engine
##     is that arms slide: pose at each moment is pose before it carried on, so arm
##     that has gone round body stays round it.
##   Couple stand for turn they are about to take.  Architect: stand for turn, hand
##     height for turn, everything for turn, nothing fixed but preventing
##     collisions.  Chosen at rest instead -- wherever joints were freest standing
##     still -- couple walk straight out of it: measured, chain over crown stood at
##     0.96 and turned 0.22 where standing at 0.36 turns 1.12.

{.experimental: "strictFuncs".}

import std/[atomics, cpuinfo, locks, math, options, sets, strutils, tables, typedthreads]
import ./[body, hold, limb, plan, rig, rigid, vector]


const
  STEP* = 0.02  ## Turns walked between two moments.
  BEATS* = 200  ## Engine steps per moment.  Slow enough to stay quasi-static.
  MOST* = 2.5  ## Turns tried each way before sweep gives up.
  SEEK* = 0.02  ## Standing distances tried, metres between them.
    ## Whole sweep is run at each distance, so search is what this costs.  Measured
    ## landscape is plateaus four centimetres wide, so grid half of one cannot step
    ## over one; finer than that buys under twentieth of turn, which is below
    ## anything any card asks.
  ROOM* = 1.0  ## And how far out from clear air search looks.
  SMOOTHER* = 2.0  ## Stance further out takes tie from nearer only for arms moving
                  ## this many times less between moments.  Largest leap of walk is
                  ## chaotic: seen in mirror it differs by up to fifth, and built
                  ## from same source by another compiler by up to thirty five per
                  ## cent, last bits amplified.  Tie broken within five millimetres
                  ## chose stances two steps apart for one hold seen in mirror, and
                  ## again for one hold built twice.
  LOOK* = 0.1  ## Metres further out looked once turn runs free, for stance
                 ## moving arms less: free way is not walked over whole `ROOM`,
                 ## fifty walks where one did.


type
  Capsule* = tuple[a, z: Vector, radius: float]  ## Segment's two ends in world, and radius.

  Moment* = object  ## One moment of turn, all page needs to draw it.
    at*: float  ## Turns from rest, signed.
    stance*: array[Body, Stance]
    arms*: seq[array[2, ArmPose]]  ## One per connection.
    trunks*: array[Body, seq[Capsule]]  ## Every trunk capsule where engine has it.
    girdles*: array[Body, array[Arm, Capsule]]  ## And each shoulder's.
    room*: float  ## Least room any joint had here.

  Walk* = object  ## One sweep, one way.
    found_rest*: bool  ## Whether hold stood at all where this was walked from.
    apart*: float  ## And how far apart couple stood to walk it.
    is_stopped*: bool
    at*: float  ## Turns reached when something gave.
    why*: Stop
    which*: int  ## Which connection gave.
    whose*: Hand  ## And whose hand, on which arm, it gave at.
    moments*: seq[Moment]

  Swept* = object  ## Both ways from one rest.
    apart*: float
    found_rest*: bool
    negative*, positive*: Walk

  Carry* = tuple[apart, got, leap: float]
    ## One walked distance summed up: metres apart couple stood, turns carried
    ## (`Inf` running free), and furthest any point of held arm moved between
    ## two moments.

  Stood* = object  ## Where couple stand for one still, and how it sits.
    is_holding*: bool
    apart*: float  ## Distance chosen, metres axis to axis.
    turns*: float  ## Way couple were wound there, signed: their own where still
                   ## fixes neither.
    strain*: Strain  ## How near pose there is to any end.
    tried*: seq[Option[float]]  ## Strain of each distance and way tried, in order: none gave.


#[ Kept Answers ]#

type Store*[T] = object
  ## Answers of one routine by every argument it was asked with, shared by every thread:
  ## each is answered once, and thread asking what another is answering waits for it.
  ##   Routine answers from its arguments alone, so answer kept is answer it gives again,
  ##     to last bit: run that keeps them writes same bytes as one that does not.
  lock: Lock
  cond: Cond
  done: Table[string, T]
  busy: HashSet[string]

proc initStore*[T](store: var Store[T]) =
  ## Make store ready, before any thread asks it.
  initLock(store.lock)
  initCond(store.cond)

proc answered*[T](store: var Store[T], key: string, got: var T): bool =
  ## Whether `key` is answered, `got` then holding answer; else caller now answers it, and
  ## keeps answer with `keep`.  Waits while another thread answers it.
  withLock store.lock:
    while true:
      if key in store.done:
        got = store.done[key]
        return true
      if key notin store.busy:
        store.busy.incl key
        return false
      wait(store.cond, store.lock)

proc claimed[T](store: var Store[T], key: string): bool =
  ## Whether `key` was neither answered nor being answered, and caller now answers it.
  withLock store.lock:
    if key in store.done or key in store.busy: return false
    store.busy.incl key
  true

proc keep*[T](store: var Store[T], key: string, answer: T) =
  ## Keep answer of `key`, and wake every thread waiting on it.
  withLock store.lock:
    store.done[key] = answer
    store.busy.excl key
  broadcast(store.cond)

proc forget*[T](store: var Store[T], key: string) =
  ## Give up `key` unanswered, so thread waiting on it answers it itself.
  withLock store.lock: store.busy.excl key
  broadcast(store.cond)

template kept*(store: var Store, key: string, answer: untyped): untyped =
  ## Answer of `key` from `store`, or `answer` worked out once and kept there; plain
  ## `answer` where answers are not kept.
  var got: typeof(answer)
  if not IS_KEEPING:
    got = answer
  elif not store.answered(key, got):
    try:
      got = answer
    except CatchableError as error:
      store.forget(key)
      raise error
    store.keep(key, got)
  got

func bits*(value: float): string = toHex(cast[uint64](value))
  ## Float as its bits: key that tells every two values apart, nought from minus nought too.

func keyOf*(rig: Rig, links: seq[Link], parts: varargs[string]): string =
  ## Key of one question: rig, hold and every other argument, each as its own text.
  result = $rig
  for link in links: result.add "|" & $link
  for part in parts: result.add "|" & part

# Mutable and global: one run keeps every answer for every thread, set before any starts.
var
  IS_KEEPING* = false  ## Whether answers are kept: off unless run asks, so laws ask afresh.
  PLANS: Store[Path]  ## Every path planned, by `keyOfPlan`.
  SWEEPS: Store[tuple[positive, negative: Walk]]  ## Both ways of every sweep.
  WALKS: Store[tuple[walk: Walk, most: float]]  ## Every walk from one distance, as far as asked.
  STANDS: Store[Stood]  ## Every distance search of still.
  REACHES: Store[bool]  ## Every carried reach.
  PLANNED_HOLDS: Store[bool]  ## Every planned still, as `isPlannedHolding` answers it.
  PLANNED_REACHES: Store[bool]  ## Every planned reach.
initStore(PLANS)
initStore(SWEEPS)
initStore(WALKS)
initStore(STANDS)
initStore(REACHES)
initStore(PLANNED_HOLDS)
initStore(PLANNED_REACHES)

proc keepAnswers*() =
  ## Keep every answer of this run, for every thread: call before any thread starts.
  ##   Recording asks one question in many jobs: 384 planned paths, of which 132 differ, and
  ##     95 stills that rig and modelled both ask, field for field (2026-10-04).
  IS_KEEPING = true


#[ Mirror ]#

type Twin* = object
  ## Question as its mirror twin asks it: one of two questions that are each other's mirror
  ## is answered, and other is that answer reflected.
  ##   Twin of hold is its mirror image, each hand on other arm, at other turn.  Lead's left
  ##     arm first is answered, of two holds that are each other's mirror; of hold that is
  ##     its own mirror, way that turns positive.
  ##   Hold that rests face to back has no twin: its rest is wound one way (`restsOf`), so
  ##     mirror image of its rest is other rest.  Same-name chain at minus half unwinds to
  ##     face to face, and at plus half winds whole turn.
  is_reflected*: bool  ## Whether question is answered as its twin's answer, reflected.
  links*: seq[Link]  ## Hold twin asks, in its own order.
  turns*: float  ## And turn twin asks, other sign.
  order*: seq[int]  ## Link of twin that each link of question is mirror of.

func isSameEnds(a, b: Link): bool = a.ends[0] == b.ends[0] and a.ends[1] == b.ends[1]
  ## Whether two connections join same two hands, in same order.

func twinOf*(links: seq[Link], turns: float, is_away: bool): Twin =
  ## Twin that answers question of this hold and turn, or question itself.
  let is_own = isMirrorSame(links)
  result = Twin(links: links, turns: turns)
  result.is_reflected = not is_away and
                        (if is_own: turns < 0.0 else: links[0].ends[0].arm == Arm.Right)
  if not result.is_reflected:
    for k in 0..<links.len: result.order.add k
    return
  result.turns = -turns
  if not is_own:
    result.links = @[]
    for link in links: result.links.add mirrored(link)
  for link in links:
    let image = mirrored(link)
    for j, other in result.links:
      if isSameEnds(other, image): result.order.add j

func otherArm(arm: Arm): Arm = (if arm == Arm.Left: Arm.Right else: Arm.Left)
  ## Arm on other side of same body.

func partnersOf*(rig: Rig): seq[int] =
  ## Trunk capsule on other side of body from each, as `rigid.trunkCapsules` lists them:
  ## itself where it lies on body's middle.
  let trunk = trunkCapsules(rig)
  for t, capsule in trunk:
    var partner = t
    for u, other in trunk:
      if other.a.x == -capsule.a.x and other.a.z == capsule.a.z and
         other.radius == capsule.radius: partner = u
    result.add partner

func reflected(capsule: Capsule): Capsule =
  ## Capsule seen in mirror across couple's line.
  (mirrored(capsule.a), mirrored(capsule.z), capsule.radius)

func reflected(pose: ArmPose): ArmPose =
  ## Arm's four points seen in mirror: arm of other side.
  ArmPose(shoulder: mirrored(pose.shoulder), elbow: mirrored(pose.elbow),
          wrist: mirrored(pose.wrist), grip: mirrored(pose.grip))

func reflected*(stance: Stance, rest: float): Stance =
  ## Stance seen in mirror: facing reflected about way body faces at rest, so turn wound
  ## either way keeps its laps.
  Stance(centre: (-stance.centre.x, stance.centre.y), facing: 2.0 * rest - stance.facing)

func reflected(
  moment: Moment, order: seq[int], rests: array[Body, float], partners: seq[int]
): Moment =
  ## Moment of twin seen in mirror: moment of question it answers.
  result = Moment(at: -moment.at, room: moment.room)
  for who in Body: result.stance[who] = reflected(moment.stance[who], rests[who])
  for k in 0..<order.len:
    let arms = moment.arms[order[k]]
    result.arms.add [reflected(arms[0]), reflected(arms[1])]
  for who in Body:
    for t in 0..<moment.trunks[who].len:
      result.trunks[who].add reflected(moment.trunks[who][partners[t]])
    for arm in Arm: result.girdles[who][arm] = reflected(moment.girdles[who][otherArm(arm)])

func reflected(walk: Walk, order: seq[int], rests: array[Body, float], partners: seq[int]):
    Walk =
  ## Walk of twin seen in mirror: walk of question it answers.
  ##   Hand that gave is named where walk stopped; otherwise it names none.
  result = Walk(found_rest: walk.found_rest, apart: walk.apart, is_stopped: walk.is_stopped,
                at: walk.at, why: walk.why, which: walk.which, whose: walk.whose)
  if walk.is_stopped:
    result.which = order.find(walk.which)
    result.whose = (walk.whose.body, otherArm(walk.whose.arm))
  for moment in walk.moments: result.moments.add reflected(moment, order, rests, partners)

func reflected(stood: Stood): Stood =
  ## Still's distance search of twin seen in mirror: way wound is other way, and each
  ## distance and way tried is tried in same order.
  result = stood
  result.turns = -stood.turns

proc restsOf(rig: Rig, apart: float, is_away: bool): array[Body, float] =
  ## Way each body faces at rest: what its facing is reflected about.
  let stance = restStance(rig, apart, is_away)
  for who in Body: result[who] = stance[who].facing


#[ Every Core ]#

type Batch[A, R] = object  ## Asks answered on every core at once, each answer in its own place.
  asks: seq[A]
  answers: seq[R]
  answer: proc(ask: A): R {.nimcall, gcsafe.}
  next: Atomic[int]  ## Place in `asks` of next ask to take.

proc answering[A, R](batch: ptr Batch[A, R]) {.thread.} =
  ## Take asks until none is left, and put each answer in its place.
  {.cast(gcsafe).}:
    while true:
      let k = batch.next.fetchAdd(1)
      if k >= batch.asks.len: break
      batch.answers[k] = batch.answer(batch.asks[k])

proc onEveryCore*[A, R](asks: seq[A], answer: proc(ask: A): R {.nimcall, gcsafe.}): seq[R] =
  ## Answer of each ask, on every core at once, in order of asks.
  ##   Each ask builds its own world and frees it, so which core answers it and when
  ##     changes no answer.
  if asks.len == 1: return @[answer(asks[0])]
  var batch = Batch[A, R](asks: asks, answer: answer)
  batch.answers.setLen(asks.len)
  var threads = newSeq[Thread[ptr Batch[A, R]]](min(asks.len, max(1, countProcessors())))
  for thread in threads.mitems: createThread(thread, answering[A, R], addr batch)
  joinThreads(threads)
  batch.answers

# Mutable and global: workers of one run say they are idle, and every search reads it.
var SPARE*: Atomic[int]  ## Cores no job of run holds: workers that found queue empty.

proc batchOf*[T](items: seq[T], first: int): seq[T] =
  ## Items from `first` on that one search asks at once: one, and one more for each spare
  ## core.  While every core holds job, search walks nothing past distance it stops at; as
  ## queue empties, its last jobs take cores others leave.
  items[first ..< min(items.len, first + min(1 + SPARE.load, max(1, countProcessors())))]


iterator stands*(rig: Rig): float =
  ## Every distance couple may stand at, from clear of each other outward.
  ##   Only thing fixed about where couple stand is that they are not inside each
  ##   other.  Everything else is theirs to choose for what they are about to do.
  let least = touching(rig) + CLEAR
  var apart = least
  while apart <= least + ROOM:
    yield apart
    apart += SEEK


proc momentOf(couple: Couple, at: float): tuple[moment: Moment, why: Stop, which: int,
                                           whose: Hand] =
  ## Read every connection at this moment, and say what gave, if anything.
  result.moment = Moment(at: at, stance: couple.chestStances, room: Inf)
  for shape in couple.shapes:
    if shape.mark == Mark.Trunk:
      let ends = couple.endsOf(shape)
      result.moment.trunks[shape.who].add (ends.a, ends.z, shape.radius)
    elif shape.mark == Mark.Girdle:
      let ends = couple.endsOf(shape)
      result.moment.girdles[shape.who][shape.arm] = (ends.a, ends.z, shape.radius)
  result.why = Stop.None
  result.which = -1
  for i in 0..<couple.links.len:
    let pose = couple.poseOf(i)
    result.moment.arms.add pose.arms
    result.moment.room = min(result.moment.room, roomAt(couple, pose, i))
    if result.why == Stop.None:
      let (gave, end_index) = couple.stoppedBy(i)
      if gave != Stop.None:
        result.why = gave
        result.which = i
        result.whose = couple.links[i].ends[end_index]

proc walkedOf*(
  rig: Rig;
  band: Band;
  links: seq[Link];
  who: Body;
  apart, most, step: float;
  is_away: bool;
  head: Body;
): Walk =
  ## Turn one way from one standing distance until something gives, or until
  ## `most` is reached.
  var couple = build(rig, restStance(rig, apart, is_away), band, links, head, is_away)
  couple.settle()
  result.apart = apart
  var at = 0.0
  let first = momentOf(couple, at)
  result.found_rest = first.why == Stop.None
  result.moments.add first.moment
  while abs(at) < abs(most):
    couple.turn(who, step, BEATS)
    at += step
    let now = momentOf(couple, at)
    if now.why != Stop.None:
      result.is_stopped = true
      result.at = abs(at)
      result.why = now.why
      result.which = now.which
      result.whose = now.whose
      break
    result.moments.add now.moment
  couple.free()

func cut(walk: Walk, most: float): Walk =
  ## Walk as `walkedOf` gives it to `most`, from one it gave to `most` or further from same
  ##   distance: each step is taken where same step was, and `most` only ends loop.
  ##   Moment keeps turn it was reached at, so loop reads same sums walk did.
  result = Walk(found_rest: walk.found_rest, apart: walk.apart)
  result.moments.add walk.moments[0]
  var k = 0
  while abs(result.moments[^1].at) < abs(most):
    inc k
    if k == walk.moments.len:
      result.is_stopped = true
      result.at = walk.at
      result.why = walk.why
      result.which = walk.which
      result.whose = walk.whose
      break
    result.moments.add walk.moments[k]

proc walked*(
  rig: Rig;
  band: Band;
  links: seq[Link];
  who: Body;
  apart, most, step: float;
  is_away: bool;
  head: Body;
): Walk =
  ## Turn one way from one standing distance until something gives, or until `most` is
  ## reached (`walkedOf`).
  ##   Twin's walk reflected answers mirror image (`twinOf`).
  ##   Kept walk as far or further from same distance gives this one cut short (`cut`):
  ##     sweep walks every distance to `MOST`, and reach asks each again to its own turn.
  let twin = twinOf(links, step, is_away)
  if twin.is_reflected:
    return reflected(walked(rig, band, twin.links, who, apart, most, twin.turns, is_away, head),
                     twin.order, restsOf(rig, apart, is_away), partnersOf(rig))
  if not IS_KEEPING:
    return walkedOf(rig, band, links, who, apart, most, step, is_away, head)
  let key = keyOf(rig, links, $band, $who, bits(apart), bits(step), $is_away, $head)
  var got: tuple[walk: Walk, most: float]
  if WALKS.answered(key, got):
    if got.walk.is_stopped or abs(got.most) >= abs(most): return cut(got.walk, most)
    return walkedOf(rig, band, links, who, apart, most, step, is_away, head)
  try:
    result = walkedOf(rig, band, links, who, apart, most, step, is_away, head)
  except CatchableError as error:
    WALKS.forget(key)
    raise error
  WALKS.keep(key, (result, most))

type WalkAsk = tuple[rig: Rig, band: Band, links: seq[Link], who: Body, apart, most,
                      step: float, is_away: bool, head: Body, is_raw: bool]
  ## One walk, by every argument it is walked with.  Raw walk is engine's own (`walkedOf`).

proc walkedFor(ask: WalkAsk): Walk {.nimcall, gcsafe.} =
  ## Walk one ask, as `walked` walks it, or as engine walks it where raw.
  {.cast(gcsafe).}:
    if ask.is_raw:
      walkedOf(ask.rig, ask.band, ask.links, ask.who, ask.apart, ask.most, ask.step,
               ask.is_away, ask.head)
    else:
      walked(ask.rig, ask.band, ask.links, ask.who, ask.apart, ask.most, ask.step,
             ask.is_away, ask.head)

proc stood*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away: bool,
  head: Body,
  apart: float,
  who = Body.Two,
): tuple[is_holding: bool, couple: Couple] =
  ## Couple wound to this facing from rest at this one distance, `who` turning, and left
  ## standing there, and whether pose holds.  Caller frees couple, holding or not.
  ##   Wound, not built there.  Winding is path, not facing: couple built at
  ##     whole turn stand exactly as at none, so diamond read as open and swan
  ##     as cross, and every wound still on reference was answered by unwound
  ##     pose.  And built at facing and settled, lift never came: every joined
  ##     hand of every still past face to face hung at hip height, 0.87 m, over
  ##     crown.  So couple are turned there as walk turns them, hands lifted as
  ##     they leave face to face, and then let stand.
  ##   Way in is walk's own, at walk's own pace, from this one distance: still
  ##     card claims position exists, and position that is winding of arms
  ##     exists only where some winding gets there.
  result.couple = build(rig, restStance(rig, apart, is_away), band, links, head, is_away)
  result.couple.settle()
  result.is_holding = result.couple.gives == Stop.None
  if not result.is_holding:
    return
  let step = (if turns >= 0.0: STEP else: -STEP)
  var at = 0.0
  while abs(at) + 1e-9 < abs(turns):
    result.couple.turn(who, step, BEATS)
    at += step
    if result.couple.gives != Stop.None:
      result.is_holding = false
      return
  # Left to stand: turn has stopped, and hold is asked of couple at rest there.
  result.couple.advance(SETTLE)
  result.is_holding = result.couple.gives == Stop.None


proc standsAt(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away: bool,
  head: Body,
  apart: float,
  who: Body,
): Stood =
  ## Whether pose holds at this facing from this one distance, and how it sits.
  let (is_holding, couple) = stood(rig, band, links, turns, is_away, head, apart, who)
  result = Stood(is_holding: is_holding, apart: apart, turns: turns, strain: couple.strainOf)
  couple.free()

type StandAsk = tuple[rig: Rig, band: Band, links: seq[Link], turns: float, is_away: bool,
                       head: Body, apart: float, who: Body]
  ## One still stood at one distance, by every argument it is stood with.

proc stoodFor(ask: StandAsk): Stood {.nimcall, gcsafe.} =
  ## Stand one ask, as `standsAt` stands it.
  {.cast(gcsafe).}:
    standsAt(ask.rig, ask.band, ask.links, ask.turns, ask.is_away, ask.head, ask.apart, ask.who)

proc standingOf(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away: bool,
  head: Body,
  is_either_way: bool,
  who: Body,
): Stood =
  ## Where couple stand for this still: distance whose pose holds nearest to
  ## ease, of every distance couple may stand at.
  ##   Still card claims position exists; moving one claims couple can carry to
  ##     it under one manner.  They are not same question, and `simulation/verdicts`
  ##     keeps them apart.  Still is wound there all same, as `stood` says why:
  ##     what is asked once there is whether it holds standing, not whether
  ##     that way in was one card meant.
  ##   Every distance is asked, and one at ease is taken over one that merely
  ##     holds.  First distance that held was taken before, and first is chest to
  ##     chest: couple asked Face-to-back there had follow's free arm crushed between two
  ##     torsos, shoulder at its rope's end, twist at its end, waist at forty,
  ##     with nothing held -- couple would stand anywhere else.  Ties go to
  ##     nearer distance, as before.
  ##   Distance at ease outright ends search: no distance further out is nearer
  ##     to ease than nought, and nearer distance keeps tie, so first at ease is
  ##     couple's choice.  Only still no distance eases pays for whole search.
  ##   Still that fixes no way about (`either`) is wound either way at every
  ##     distance, and way asked keeps tie: card claims position, and couple
  ##     take whichever way there sits easier.
  ##   Distances and ways are stood on every core at once, batch by batch, and taken in
  ##     their order (`onEveryCore`).
  result = Stood(is_holding: false, strain: Strain(most: Inf))
  var
    tried: seq[Option[float]]
    asks: seq[StandAsk]
  for far in stands(rig):
    for way in (if is_either_way: @[turns, -turns] else: @[turns]):
      asks.add (rig, band, links, way, is_away, head, far, who)
  var first = 0
  while first < asks.len:
    let batch = asks.batchOf(first)
    for got in onEveryCore(batch, stoodFor):
      tried.add (if got.is_holding: some(got.strain.most) else: none(float))
      if got.is_holding and (not result.is_holding or got.strain.most < result.strain.most):
        result = got
      result.tried = tried
      if result.is_holding and result.strain.most <= 0.0: return
    first += batch.len

proc standing*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away = false,
  head = Body.Two,
  is_either_way = false,
  who = Body.Two,
): Stood =
  ## Where couple stand for this still: distance whose pose holds nearest to ease, of
  ## every distance couple may stand at (`standingOf`).
  ##   Twin's answer reflected answers mirror image (`twinOf`).
  let twin = twinOf(links, turns, is_away)
  if twin.is_reflected:
    return reflected(standing(rig, band, twin.links, twin.turns, is_away, head, is_either_way,
                              who))
  kept(STANDS, keyOf(rig, links, $band, bits(turns), $is_away, $head, $is_either_way, $who),
       standingOf(rig, band, links, turns, is_away, head, is_either_way, who))

proc isHoldingAt*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away = false,
  head = Body.Two,
  apart = 0.0,
  is_either_way = false,
  who = Body.Two,
): bool =
  ## Whether any pose holds at this facing, `who` turning, from any distance couple may
  ## stand at.  Twin's answer answers mirror image (`twinOf`).
  let twin = twinOf(links, turns, is_away)
  if twin.is_reflected:
    return isHoldingAt(rig, band, twin.links, twin.turns, is_away, head, apart, is_either_way,
                       who)
  if apart > 0.0:
    return standsAt(rig, band, links, turns, is_away, head, apart, who).is_holding
  standing(rig, band, links, turns, is_away, head, is_either_way, who).is_holding

proc isReachingOf(
  rig: Rig, band: Band, links: seq[Link], turns: float, is_away: bool, who, head: Body
): bool =
  ## Whether couple carry this hold that far from any distance they may stand at.
  ##   Card asks whether couple can do this, and couple choose where to stand for
  ##     it.  So one distance carrying it is enough, and answer comes as soon as
  ##     one does: easy card costs single sweep, and only card nothing reaches
  ##     pays for whole search.
  ##   Sweep is asked for no more than card wants, so distance that gets there is
  ##     not walked further to find out how much further it would go.
  if turns == 0.0: return true
  ##   Distances are walked on every core at once, batch by batch, and taken in their order.
  let step = (if turns >= 0.0: STEP else: -STEP)
  var asks: seq[WalkAsk]
  for far in stands(rig):
    asks.add (rig, band, links, who, far, abs(turns), step, is_away, head, false)
  var first = 0
  while first < asks.len:
    let batch = asks.batchOf(first)
    for walk in onEveryCore(batch, walkedFor):
      if walk.found_rest and not walk.is_stopped:
        return true
    first += batch.len
  false

proc isReaching*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away = false,
  who = Body.Two,
  head = Body.Two,
): bool =
  ## Whether couple carry this hold that far from any distance they may stand at
  ## (`isReachingOf`).  Twin's answer answers mirror image (`twinOf`).
  let twin = twinOf(links, turns, is_away)
  if twin.is_reflected:
    return isReaching(rig, band, twin.links, twin.turns, is_away, who, head)
  kept(REACHES, keyOf(rig, links, $band, bits(turns), $is_away, $who, $head),
       isReachingOf(rig, band, links, turns, is_away, who, head))

func leapOf*(walk: Walk): float =
  ## Furthest any point of any held arm moves between two moments of walk.
  for j in 1..<walk.moments.len:
    for i in 0..<walk.moments[j].arms.len:
      for k in 0..1:
        let
          before = walk.moments[j - 1].arms[i][k]
          after = walk.moments[j].arms[i][k]
        for (p, q) in [
          (before.shoulder, after.shoulder),
          (before.elbow, after.elbow),
          (before.wrist, after.wrist),
          (before.grip, after.grip),
        ]:
          result = max(result, distance(p, q))

func chosen*(walks: openArray[Carry]): int =
  ## Which of walked distances couple stand at, -1 for none: nearest carrying
  ## turn as far as any to one step, unless one further out moves arms less
  ## than `SMOOTHER` times as far between moments.
  ##   To one step: stop is decided at moment something gives, and mirror-image
  ##     holds give one moment apart from same distance.  Furthest to last bit
  ##     stood L-l at 0.42 for 1.00 and R-r at 0.38 for 0.98, two steps apart.
  result = -1
  var far = -Inf
  for carry in walks: far = max(far, carry.got)
  for i, carry in walks:
    if carry.got != far and far - carry.got > STEP + 1e-9: continue
    if result < 0 or carry.leap * SMOOTHER < walks[result].leap: result = i

proc furthest(
  rig: Rig; band: Band; links: seq[Link]; who: Body; most, step: float; is_away: bool;
  head: Body; is_raw: bool
): Walk =
  ## Walk one way from whichever distance carries it furthest, and among
  ## distances carrying it as far, from one where arms move least between
  ## moments.
  ##   This is what `reaches` asks, kept whole: page has to draw one turn, so it
  ##     wants moments of best of them rather than bare yes.  Distance that never
  ##     leaves rest is no distance to stand at and is passed over.
  ##   Nearest distance that carried turn was taken before, and nearest is
  ##     chest to chest: joined hands pinned between two torsos, then popping up
  ##     between heads 300 mm in one moment, at distance no couple would turn
  ##     under arm at.  Couple stand where move is smooth.  Once turn runs free
  ##     search looks `LOOK` further out for that and no further, since walking
  ##     every distance that carries free turn costs fifty walks where one did.
  ##   Distances are walked on every core at once, batch by batch, and taken in their order:
  ##     walk past where search stops is walked and not taken.  Raw search walks engine's own
  ##     walks (`walkedOf`).
  var
    walks: seq[Walk]
    carries: seq[Carry]
    free = Inf  ## First distance turn ran free from.
    asks: seq[WalkAsk]
  for apart in stands(rig):
    asks.add (rig, band, links, who, apart, most, step, is_away, head, is_raw)
  var first = 0
  block search:
    while first < asks.len:
      let batch = asks.batchOf(first)
      for walk in onEveryCore(batch, walkedFor):
        if walk.apart > free + LOOK + SEEK / 2.0: break search
        if not walk.found_rest: continue
        walks.add walk
        carries.add (walk.apart, (if walk.is_stopped: walk.at else: Inf), leapOf(walk))
        if carries[^1].got == Inf: free = min(free, walk.apart)
      first += batch.len
  if carries.len > 0: result = walks[chosen(carries)]

proc waysOf(
  rig: Rig,
  band: Band,
  links: seq[Link],
  who: Body,
  most, step, apart: float,
  is_away: bool,
  head: Body,
  is_raw: bool,
): tuple[positive, negative: Walk] =
  ## Both ways of sweep, each from wherever that way carries furthest.
  ##   `who` turns; `head` is whose crown joined hands are carried over.  Callers
  ##     pass same dancer for both: one whose facing turns against connection has
  ##     connection go round them, and round over crown is over their crown.
  ##   Two ways stand where each of them wants, not both where one of them does.
  ##     Turning one way and turning other are two turns, and couple about to
  ##     take either stand for that one.
  ##   Hold that is its own mirror walks way that turns positive, and other way is it
  ##     reflected (`twinOf`), unless it rests face to back or sweep is raw.
  proc way(towards: float): Walk =
    ## One way, `towards` its own step: engine's own walk where raw.
    if apart > 0.0 and is_raw:
      walkedOf(rig, band, links, who, apart, most, towards, is_away, head)
    elif apart > 0.0: walked(rig, band, links, who, apart, most, towards, is_away, head)
    else: furthest(rig, band, links, who, most, towards, is_away, head, is_raw)
  if isMirrorSame(links) and not is_away and not is_raw:
    let
      ahead = way(abs(step))
      twin = twinOf(links, -1.0, is_away)
      behind = reflected(ahead, twin.order, restsOf(rig, ahead.apart, is_away), partnersOf(rig))
    return (if step >= 0.0: (ahead, behind) else: (behind, ahead))
  (way(step), way(-step))

func sweptOf(positive, negative: Walk): Swept =
  ## Sweep of these two ways: couple stand where way that got further stood.
  result = Swept(positive: positive, negative: negative)
  result.found_rest = positive.found_rest or negative.found_rest
  result.apart = (if positive.at >= negative.at: positive.apart else: negative.apart)
  if not result.found_rest:
    result = Swept(apart: result.apart)

proc swept*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  who = Body.Two,
  most = MOST,
  step = STEP,
  apart = 0.0,
  is_away = false,
  head = Body.Two,
  is_raw = false,
): Swept =
  ## Sweep both ways, each from wherever that way carries furthest (`waysOf`).
  ##   Twin's sweep reflected answers mirror image: its way that turns positive is other
  ##     one's that turns negative (`twinOf`).
  ##   Raw sweep is engine's own: it reflects no twin, and keeps nothing, so no other
  ##     sweep reads it.
  if is_raw:
    let (positive, negative) = waysOf(rig, band, links, who, most, step, apart, is_away, head,
                                      true)
    return sweptOf(positive, negative)
  let twin = twinOf(links, 1.0, is_away)
  if twin.is_reflected and not isMirrorSame(links):
    let (positive, negative) = kept(SWEEPS, keyOf(rig, twin.links, $band, $who, bits(most),
                                                   bits(step), bits(apart), $is_away, $head),
                                    waysOf(rig, band, twin.links, who, most, step, apart,
                                           is_away, head, false))
    let partners = partnersOf(rig)
    return sweptOf(
      reflected(negative, twin.order, restsOf(rig, negative.apart, is_away), partners),
      reflected(positive, twin.order, restsOf(rig, positive.apart, is_away), partners),
    )
  let (positive, negative) = kept(SWEEPS, keyOf(rig, links, $band, $who, bits(most), bits(step),
                                                 bits(apart), $is_away, $head),
                                  waysOf(rig, band, links, who, most, step, apart, is_away,
                                         head, false))
  sweptOf(positive, negative)



#[ Planned Turn ]#

const
  STEER* = 30.0  ## Hertz every joint is sprung toward plan at: what dancer's muscles hold.
    ##   Measured on D07, 2026-10-01: at fifteen engine gave by twist at 1.47 of turn; at
    ##     twenty five, thirty and forty it stood, strain 0.33 to 0.34.
  STEPS_STAND = 2  ## Engine steps each planned moment is stood for before it is judged:
                  ## enough for engine to find every contact pose has (`replay`).
  STYLES* = block:
    ## Ways couple go about turn, tried in order: each moment held near last loosely,
    ## then firmly; joined pairs drawn hard to one point, then softly; from four starts
    ## of rest.
    var
      styles: array[16, Style]
      k = 0
    for stay in [0.3, 1.0]:
      for gather in [5.0, 2.0]:
        for seed in 0..3:
          styles[k] = Style(
            gather: gather,
            leap: 0.06,
            stay: stay,
            seed: seed,
            margin: 6.0 * PI / 180.0,
            room: 0.03,
            clearance: 0.02,
            slack: 300.0,
          )
          inc k
    styles

type Followed* = tuple[is_holding: bool, at: float, why: Stop, strain: Strain]
  ## How far engine followed plan, and what gave if anything did.

proc follow(
  rig: Rig, band: Band, links: seq[Link], is_away: bool, head: Body, path: Path, should_stand: bool
): tuple[followed: Followed, couple: Couple] =
  ## Whether engine, every joint sprung toward plan and nothing else steering, holds every
  ## moment of reached path, and stands at its end where `should_stand`; couple as left.
  ##   Turns plan's turner and steps follow toward lead, as plan does.
  var stance = restStance(rig, path.plans[0][0], is_away)
  stance[Body.Two].centre.x = path.plans[0][1]
  var couple = build(rig, stance, band, links, head, is_away)
  let start = placings(rig, path.plans[0], 0.0, is_away, path.problem.turner)
  couple.placeBodies(start.chests, start.arms)
  couple.steer(path.plans[0], STEER)
  couple.settle()
  var
    said: Followed = (couple.gives == Stop.None, 0.0, couple.gives, couple.strainOf)
    i = 1
  while said.is_holding and i < path.plans.len:
    # Steered toward plan planned again from where engine has couple, so drift is
    # answered rather than carried.
    var now: Plan
    let read = couple.poseVector
    for k in 0..<SIZE: now[k] = read[k]
    let target = corrected(rig, path, i, now)
    couple.turnStepping(
      path.problem.turner,
      path.winds[i] - path.winds[i - 1],
      Body.Two,
      (target[1] - now[1], target[0] - now[0], 0.0),
      BEATS,
      now,
      target,
      STEER,
    )
    let why = couple.gives
    said = (why == Stop.None, path.winds[i], why, couple.strainOf)
    inc i
  if said.is_holding and should_stand:
    couple.advance(SETTLE)
    let why = couple.gives
    said = (why == Stop.None, said.at, why, couple.strainOf)
  (said, couple)

proc replay*(
  rig: Rig, band: Band, links: seq[Link], is_away: bool, head: Body, path: Path, should_stand: bool
): tuple[followed: Followed, couple: Couple] =
  ## Engine stood at every moment of plan in turn and judged there, then left to stand at
  ## its end where `should_stand`; couple as left.
  ##   Each moment is stood afresh from plan, so what engine judges is plan itself and not
  ##     drift of engine's springs: sprung after plan instead, D01 and D07 held or not on last
  ##     bit of one sum, and lead's turn of same-name chain to its swan gave at 0.46 to 1.11
  ##     of turn in every style that reached it.
  var base = restStance(rig, path.plans[0][0], is_away)
  base[Body.Two].centre.x = path.plans[0][1]
  var
    couple = build(rig, base, band, links, head, is_away)
    said: Followed
  for i in 0..<path.plans.len:
    var stance = restStance(rig, path.plans[i][0], is_away)
    stance[Body.Two].centre.x = path.plans[i][1]
    stance = turned(stance, path.problem.turner, path.winds[i])
    let at = placings(rig, path.plans[i], path.winds[i], is_away, path.problem.turner)
    couple.standAt(stance, at.chests, at.arms)
    couple.steer(path.plans[i], STEER)
    couple.advance(STEPS_STAND)
    let why = couple.gives
    said = (why == Stop.None, path.winds[i], why, couple.strainOf)
    if not said.is_holding: break
  if said.is_holding and should_stand:
    couple.advance(SETTLE)
    let why = couple.gives
    said = (why == Stop.None, said.at, why, couple.strainOf)
  (said, couple)

proc replayed*(
  rig: Rig, band: Band, links: seq[Link], is_away: bool, head: Body, path: Path, should_stand: bool
): Followed =
  ## Whether engine stands every moment of plan, and at its end where `should_stand`
  ## (`replay`).
  if not path.is_reached or path.plans.len == 0: return (false, 0.0, Stop.None, Strain())
  let (said, couple) = replay(rig, band, links, is_away, head, path, should_stand)
  couple.free()
  said

proc followed*(
  rig: Rig, band: Band, links: seq[Link], is_away: bool, head: Body, path: Path, should_stand: bool
): Followed =
  ## Whether engine follows plan through every moment of path, and stands at its end
  ## where `should_stand` (`follow`).
  if not path.is_reached or path.plans.len == 0: return (false, 0.0, Stop.None, Strain())
  let (said, couple) = follow(rig, band, links, is_away, head, path, should_stand)
  couple.free()
  said

func keyOfPlan(rig: Rig, links: seq[Link], is_away: bool, wind: float, style: Style,
               turner: Body): string =
  ## Key of one path: every argument `planPath` reads, style field by field.
  keyOf(rig, links, $is_away, bits(wind), $turner, bits(style.gather), bits(style.leap),
        bits(style.stay), $style.seed, bits(style.margin), bits(style.room),
        bits(style.clearance), bits(style.slack))

proc planned(
  rig: Rig, links: seq[Link], is_away: bool, wind: float, style: Style, turner: Body
): Path =
  ## Path `planPath` plans for these arguments, planned once in run whichever job asks it.
  kept(PLANS, keyOfPlan(rig, links, is_away, wind, style, turner),
       planPath(rig, links, is_away, wind, style, turner))

proc pathsFor(
  rig: Rig, links: seq[Link], is_away: bool, wind: float, style: Style, turner: Body
): seq[Path] =
  ## Way this style plans wind, and where hold is its own mirror image, same style's plan
  ## of other way seen in mirror: rig is same either side, planner's starts are not.
  result.add planned(rig, links, is_away, wind, style, turner)
  if isMirrorSame(links):
    result.add mirrored(planned(rig, links, is_away, -wind, style, turner))

type PlanAsk = tuple[rig: Rig, links: seq[Link], is_away: bool, wind: float, style: Style,
                     turner: Body]
  ## One path planned card may ask for, by every argument `planPath` reads.

proc plannedIfFree(ask: PlanAsk): bool {.nimcall, gcsafe.} =
  ## Plan and keep path of ask, where no thread has taken it; whether this one planned it.
  ##   Path another thread is planning is passed over, not waited on: card's own fold
  ##     waits for it, and this thread plans another meanwhile.
  {.cast(gcsafe).}:
    let key = keyOfPlan(ask.rig, ask.links, ask.is_away, ask.wind, ask.style, ask.turner)
    if not PLANS.claimed(key): return false
    var path: Path
    try:
      path = planPath(ask.rig, ask.links, ask.is_away, ask.wind, ask.style, ask.turner)
    except CatchableError:
      PLANS.forget(key)
      return false
    PLANS.keep(key, path)
    true

proc planAhead(rig: Rig, links: seq[Link], is_away: bool, winds: seq[float], turner: Body) =
  ## Plan every path that these winds ask in every style, on every core at once, where
  ## answers are kept; card then folds them in its own order, as one thread would.
  ##   Each path is pure function of its arguments, so which thread plans it and when
  ##     changes nothing card reads.
  if not IS_KEEPING: return
  var asks: seq[PlanAsk]
  for wind in winds:
    for style in STYLES:
      asks.add (rig, links, is_away, wind, style, turner)
      if isMirrorSame(links): asks.add (rig, links, is_away, -wind, style, turner)
  discard onEveryCore(asks, plannedIfFree)

type PlannedStill* = object
  ## Still planned way stands, wound which way, from where, and couple standing there.
  is_holding*: bool
  turns*, apart*: float
  couple*: Couple
  strain*: float  ## Worst joint of pose that stands, nought at ease and one at end.
  tried*: seq[Option[float]]  ## Strain of each plan tried, in order: none where none stood.

proc plannedStill*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away: bool,
  head: Body,
  is_either_way = false,
  who = Body.Two,
  should_seek_ease = false,
): PlannedStill =
  ## Planned way of winding to this facing, `who` turning, that holds and stands there,
  ## styles and ways in fixed order; caller frees couple of one that holds.
  ##   First that holds answers whether any does (`isPlannedHolding`).  Where
  ##     `should_seek_ease`, every plan is tried and one nearest to ease is kept, as
  ##     `standing` keeps distance: first that held stood C06 with follow's waist at its
  ##     end, strain 1.00, where other path of same style held at 0.19, 2026-10-03.
  ##   Plan at ease ends search, since nothing betters it; earlier plan keeps tie.
  let ways = (if is_either_way: @[turns, -turns] else: @[turns])
  planAhead(rig, links, is_away, ways, who)
  for way in ways:
    for style in STYLES:
      for path in pathsFor(rig, links, is_away, way, style, who):
        if not path.is_reached:
          result.tried.add none(float)
          continue
        let (said, couple) = replay(rig, band, links, is_away, head, path, should_stand = true)
        if not said.is_holding:
          result.tried.add none(float)
          couple.free()
          continue
        let strain = couple.strainOf.most
        result.tried.add some(strain)
        if result.is_holding and strain >= result.strain:
          couple.free()
          continue
        if result.is_holding: result.couple.free()
        result.is_holding = true
        result.turns = way
        result.apart = couple.poseVector[0]
        result.couple = couple
        result.strain = strain
        if not should_seek_ease or strain <= 0.0: return

proc isPlannedHolding*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  turns: float,
  is_away: bool,
  head: Body,
  is_either_way = false,
  who = Body.Two,
): bool =
  ## Whether some planned way of winding to this facing holds, and stands there.  Twin's
  ## answer answers mirror image (`twinOf`).
  let twin = twinOf(links, turns, is_away)
  if twin.is_reflected:
    return isPlannedHolding(rig, band, twin.links, twin.turns, is_away, head, is_either_way, who)
  proc asked(): bool =
    let found = plannedStill(rig, band, links, turns, is_away, head, is_either_way, who)
    if found.is_holding: found.couple.free()
    found.is_holding
  kept(PLANNED_HOLDS,
       keyOf(rig, links, $band, bits(turns), $is_away, $head, $is_either_way, $who), asked())

proc isPlannedReaching*(
  rig: Rig; band: Band; links: seq[Link]; turns: float; is_away: bool; who, head: Body
): bool =
  ## Whether some planned way carries couple this far, `who` turning.  Twin's answer
  ## answers mirror image (`twinOf`).
  let twin = twinOf(links, turns, is_away)
  if twin.is_reflected:
    return isPlannedReaching(rig, band, twin.links, twin.turns, is_away, who, head)
  proc asked(): bool =
    planAhead(rig, links, is_away, @[turns], who)
    for style in STYLES:
      for path in pathsFor(rig, links, is_away, turns, style, who):
        if replayed(rig, band, links, is_away, head, path, should_stand = false).is_holding:
          return true
    false
  kept(PLANNED_REACHES, keyOf(rig, links, $band, bits(turns), $is_away, $who, $head), asked())
