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

import ./[body, hold, limb, rig, rigid]


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


type
  Moment* = object ## One moment of turn, all page needs to draw it.
    at*: float ## Turns from rest, signed.
    stance*: array[Body, Stance]
    arms*: seq[array[2, ArmPose]] ## One per connection.
    room*: float ## Least room any joint had here.

  Walk* = object ## One sweep, one way.
    restHolds*: bool ## Whether hold stood at all where this was walked from.
    apart*: float ## And how far apart couple stood to walk it.
    stopped*: bool
    at*: float  ## Turns reached when something gave.
    why*: Stop
    which*: int ## Which connection gave.
    whose*: Hand ## And whose hand, on which arm, it gave at.
    moments*: seq[Moment]

  Swept* = object ## Both ways from one rest.
    apart*: float
    restHolds*: bool
    neg*, pos*: Walk


iterator stands*(rig: Rig): float =
  ## Every distance couple may stand at, from clear of each other outward.
  ##   Only thing fixed about where couple stand is that they are not inside each
  ##   other.  Everything else is theirs to choose for what they are about to do.
  let least = touching(rig) + CLEAR
  var apart = least
  while apart <= least + ROOM:
    yield apart
    apart += SEEK


proc momentOf(c: Couple; at: float): tuple[m: Moment, why: Stop, which: int,
                                           whose: Hand] =
  ## Read every connection at this moment, and say what gave, if anything.
  result.m = Moment(at: at, stance: c.stance, room: Inf)
  result.why = Stop.None
  result.which = -1
  for i in 0 ..< c.links.len:
    let p = c.poseOf(i)
    result.m.arms.add p.arms
    result.m.room = min(result.m.room, roomAt(c, p, i))
    if result.why == Stop.None:
      let (gave, k) = c.stoppedBy(i)
      if gave != Stop.None:
        result.why = gave
        result.which = i
        result.whose = c.links[i].ends[k]

proc walked*(rig: Rig; band: Band; links: seq[Link]; who: Body;
             apart, most, step: float; away: bool; head: Body): Walk =
  ## Turn one way from one standing distance until something gives, or until
  ## `most` is reached.
  var c = build(rig, restStance(rig, apart, away), band, links, head)
  c.settle()
  result.apart = apart
  var at = 0.0
  let first = momentOf(c, at)
  result.restHolds = first.why == Stop.None
  result.moments.add first.m
  while abs(at) < abs(most):
    c.turn(who, step, BEATS)
    at += step
    let now = momentOf(c, at)
    if now.why != Stop.None:
      result.stopped = true
      result.at = abs(at)
      result.why = now.why
      result.which = now.which
      result.whose = now.whose
      break
    result.moments.add now.m
  c.free()

proc standsAt(rig: Rig; band: Band; links: seq[Link]; turns: float;
              away: bool; head: Body; apart: float): bool =
  ## Whether pose holds at this facing from this one distance.
  var c = build(rig, turned(restStance(rig, apart, away), Body.Two, turns),
                band, links, head)
  c.settle()
  result = true
  for i in 0 ..< links.len:
    if c.stopOf(i) != Stop.None:
      result = false
  c.free()

proc holdsAt*(rig: Rig; band: Band; links: seq[Link]; turns: float;
              away = false; head = Body.Two; apart = 0.0): bool =
  ## Whether any pose holds at this facing, from any distance couple may stand at.
  ##   Still card claims position exists; moving one claims couple can carry to
  ##     it.  They are not same question, and `sim/verdicts` already kept them
  ##     apart -- "asked afresh whether any pose holds there at all, not whether
  ##     arms can carry to it".  Asking still card reachability calls drawing
  ##     wrong for want of way in, which is not what it says.
  ##   Card claims pose exists, so one distance holding it is enough: answer comes
  ##     as soon as one does, and only pose nothing holds pays for whole search.
  if apart > 0.0:
    return standsAt(rig, band, links, turns, away, head, apart)
  for far in stands(rig):
    if standsAt(rig, band, links, turns, away, head, far):
      return true
  false

proc reaches*(rig: Rig; band: Band; links: seq[Link]; turns: float;
              away = false; who = Body.Two; head = Body.Two): bool =
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
    let w = walked(rig, band, links, who, far, abs(turns), step, away, head)
    if w.restHolds and not w.stopped:
      return true
  false

proc furthest(rig: Rig; band: Band; links: seq[Link]; who: Body;
              most, step: float; away: bool; head: Body): Walk =
  ## Walk one way from whichever distance carries it furthest.
  ##   This is what `reaches` asks, kept whole: page has to draw one turn, so it
  ##     wants moments of best of them rather than bare yes.  Distance that never
  ##     leaves rest is no distance to stand at and is passed over.
  var far = -Inf
  for apart in stands(rig):
    let w = walked(rig, band, links, who, apart, most, step, away, head)
    if not w.restHolds: continue
    let got = (if w.stopped: w.at else: Inf)
    if got > far:
      far = got
      result = w
    if got == Inf: break

proc swept*(rig: Rig; band: Band; links: seq[Link]; who = Body.Two;
            most = MOST; step = STEP; apart = 0.0; away = false;
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
    result.pos = walked(rig, band, links, who, apart, most, step, away, head)
    result.neg = walked(rig, band, links, who, apart, most, -step, away, head)
  else:
    result.pos = furthest(rig, band, links, who, most, step, away, head)
    result.neg = furthest(rig, band, links, who, most, -step, away, head)
  result.restHolds = result.pos.restHolds or result.neg.restHolds
  result.apart = (if result.pos.at >= result.neg.at: result.pos.apart
                  else: result.neg.apart)
  if not result.restHolds:
    result = Swept(apart: result.apart)
