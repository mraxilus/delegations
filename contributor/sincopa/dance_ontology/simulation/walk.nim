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

import ./[body, hold, limb, rig, rigid, vector]


const
  STEP* = 0.02   ## Turns walked between two moments.
  BEATS* = 200   ## Engine steps per moment.  Slow enough to stay quasi-static.
  MOST* = 2.5    ## Turns tried each way before sweep gives up.
  SEEK* = 0.02   ## Standing distances tried, metres between them.
    ## Whole sweep is run at each distance, so search is what this costs.  Measured
    ## landscape is plateaus four centimetres wide, so grid half of one cannot step
    ## over one; finer than that buys under twentieth of turn, which is below
    ## anything any card asks.
  ROOM* = 1.0    ## And how far out from clear air search looks.
  SMOOTHER* = 2.0 ## Stance further out takes tie from nearer only for arms moving
                  ## this many times less between moments.  Largest leap of walk is
                  ## chaotic: seen in mirror it differs by up to fifth, and built
                  ## from same source by another compiler by up to thirty five per
                  ## cent, last bits amplified.  Tie broken within five millimetres
                  ## chose stances two steps apart for one hold seen in mirror, and
                  ## again for one hold built twice.
  LOOK* = 0.1    ## Metres further out looked once turn runs free, for stance
                 ## moving arms less: free way is not walked over whole `ROOM`,
                 ## fifty walks where one did.


type
  Capsule* = tuple[a, z: Vector, radius: float] ## Segment's two ends in world, and radius.

  Moment* = object ## One moment of turn, all page needs to draw it.
    at*: float ## Turns from rest, signed.
    stance*: array[Body, Stance]
    arms*: seq[array[2, ArmPose]] ## One per connection.
    trunks*: array[Body, seq[Capsule]] ## Every trunk capsule where engine has it.
    girdles*: array[Body, array[Arm, Capsule]] ## And each shoulder's.
    room*: float ## Least room any joint had here.

  Walk* = object ## One sweep, one way.
    found_rest*: bool ## Whether hold stood at all where this was walked from.
    apart*: float ## And how far apart couple stood to walk it.
    is_stopped*: bool
    at*: float  ## Turns reached when something gave.
    why*: Stop
    which*: int ## Which connection gave.
    whose*: Hand ## And whose hand, on which arm, it gave at.
    moments*: seq[Moment]

  Swept* = object ## Both ways from one rest.
    apart*: float
    found_rest*: bool
    negative*, positive*: Walk

  Carry* = tuple[apart, got, leap: float]
    ## One walked distance summed up: metres apart couple stood, turns carried
    ## (`Inf` running free), and furthest any point of held arm moved between
    ## two moments.

  Stood* = object ## Where couple stand for one still, and how it sits.
    is_holding*: bool
    apart*: float  ## Distance chosen, metres axis to axis.
    turns*: float  ## Way couple were wound there, signed: their own where still
                   ## fixes neither.
    strain*: Strain ## How near pose there is to any end.


iterator stands*(rig: Rig): float =
  ## Every distance couple may stand at, from clear of each other outward.
  ##   Only thing fixed about where couple stand is that they are not inside each
  ##   other.  Everything else is theirs to choose for what they are about to do.
  let least = touching(rig) + CLEAR
  var apart = least
  while apart <= least + ROOM:
    yield apart
    apart += SEEK


proc momentOf(couple: Couple; at: float): tuple[moment: Moment, why: Stop, which: int,
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
  for i in 0 ..< couple.links.len:
    let pose = couple.poseOf(i)
    result.moment.arms.add pose.arms
    result.moment.room = min(result.moment.room, roomAt(couple, pose, i))
    if result.why == Stop.None:
      let (gave, end_index) = couple.stoppedBy(i)
      if gave != Stop.None:
        result.why = gave
        result.which = i
        result.whose = couple.links[i].ends[end_index]

proc walked*(rig: Rig; band: Band; links: seq[Link]; who: Body;
             apart, most, step: float; is_away: bool; head: Body): Walk =
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

proc stood*(rig: Rig; band: Band; links: seq[Link]; turns: float;
            is_away: bool; head: Body; apart: float): tuple[is_holding: bool, couple: Couple] =
  ## Couple wound to this facing from rest at this one distance and left
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
    result.couple.turn(Body.Two, step, BEATS)
    at += step
    if result.couple.gives != Stop.None:
      result.is_holding = false
      return
  # Left to stand: turn has stopped, and hold is asked of couple at rest there.
  result.couple.advance(SETTLE)
  result.is_holding = result.couple.gives == Stop.None


proc standsAt(rig: Rig; band: Band; links: seq[Link]; turns: float;
              is_away: bool; head: Body; apart: float): Stood =
  ## Whether pose holds at this facing from this one distance, and how it sits.
  let (is_holding, couple) = stood(rig, band, links, turns, is_away, head, apart)
  result = Stood(is_holding: is_holding, apart: apart, turns: turns, strain: couple.strainOf)
  couple.free()

proc standing*(rig: Rig; band: Band; links: seq[Link]; turns: float;
               is_away = false; head = Body.Two; is_either_way = false): Stood =
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
  result = Stood(is_holding: false, strain: Strain(most: Inf))
  for far in stands(rig):
    for way in (if is_either_way: @[turns, -turns] else: @[turns]):
      let got = standsAt(rig, band, links, way, is_away, head, far)
      if not got.is_holding: continue
      if not result.is_holding or got.strain.most < result.strain.most:
        result = got
      if result.strain.most <= 0.0: return

proc isHoldingAt*(rig: Rig; band: Band; links: seq[Link]; turns: float;
              is_away = false; head = Body.Two; apart = 0.0; is_either_way = false): bool =
  ## Whether any pose holds at this facing, from any distance couple may stand at.
  if apart > 0.0:
    return standsAt(rig, band, links, turns, is_away, head, apart).is_holding
  standing(rig, band, links, turns, is_away, head, is_either_way).is_holding

proc isReaching*(rig: Rig; band: Band; links: seq[Link]; turns: float;
              is_away = false; who = Body.Two; head = Body.Two): bool =
  ## Whether couple carry this hold that far from any distance they may stand at.
  ##   Card asks whether couple can do this, and couple choose where to stand for
  ##     it.  So one distance carrying it is enough, and answer comes as soon as
  ##     one does: easy card costs single sweep, and only card nothing reaches
  ##     pays for whole search.
  ##   Sweep is asked for no more than card wants, so distance that gets there is
  ##     not walked further to find out how much further it would go.
  if turns == 0.0: return true
  let step = (if turns >= 0.0: STEP else: -STEP)
  for far in stands(rig):
    let walk = walked(rig, band, links, who, far, abs(turns), step, is_away, head)
    if walk.found_rest and not walk.is_stopped:
      return true
  false

func leapOf*(walk: Walk): float =
  ## Furthest any point of any held arm moves between two moments of walk.
  for j in 1 ..< walk.moments.len:
    for i in 0 ..< walk.moments[j].arms.len:
      for k in 0 .. 1:
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

proc furthest(rig: Rig; band: Band; links: seq[Link]; who: Body;
              most, step: float; is_away: bool; head: Body): Walk =
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
  var
    walks: seq[Walk]
    carries: seq[Carry]
    free = Inf ## First distance turn ran free from.
  for apart in stands(rig):
    if apart > free + LOOK + SEEK / 2.0: break
    let walk = walked(rig, band, links, who, apart, most, step, is_away, head)
    if not walk.found_rest: continue
    walks.add walk
    carries.add (apart, (if walk.is_stopped: walk.at else: Inf), leapOf(walk))
    if carries[^1].got == Inf: free = min(free, apart)
  if carries.len > 0: result = walks[chosen(carries)]

proc swept*(rig: Rig; band: Band; links: seq[Link]; who = Body.Two;
            most = MOST; step = STEP; apart = 0.0; is_away = false;
            head = Body.Two): Swept =
  ## Sweep both ways, each from wherever that way carries furthest.
  ##   `who` turns; `head` is whose crown joined hands are carried over.  They
  ##     are usually same dancer and part company for orbit: orbit about
  ##     couple's centre is change of world frame and moves neither dancer with
  ##     respect to other, so it is turn of *other* dancer physically -- but
  ##     couple still raised their hands over one who walks.
  ##   Two ways stand where each of them wants, not both where one of them does.
  ##     Turning one way and turning other are two turns, and couple about to
  ##     take either stand for that one.
  if apart > 0.0:
    result.positive = walked(rig, band, links, who, apart, most, step, is_away, head)
    result.negative = walked(rig, band, links, who, apart, most, -step, is_away, head)
  else:
    result.positive = furthest(rig, band, links, who, most, step, is_away, head)
    result.negative = furthest(rig, band, links, who, most, -step, is_away, head)
  result.found_rest = result.positive.found_rest or result.negative.found_rest
  result.apart = (if result.positive.at >= result.negative.at: result.positive.apart
                  else: result.negative.apart)
  if not result.found_rest:
    result = Swept(apart: result.apart)
