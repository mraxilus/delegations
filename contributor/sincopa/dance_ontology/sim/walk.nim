## Turn couple until something gives, keeping every moment on way.
##
##   Page cannot run engine: engine is C and page is script in browser.  So sweep is
##     run here, natively, at build time, and page plays what came of it -- same
##     arrangement `design/turns` already uses for whole-cloth page, and reason
##     nothing on page needs to guess at physics.
##   Turn is walked in small steps rather than jumped, because whole point of engine
##     is that arms slide: pose at each moment is pose before it carried on, so arm
##     that has gone round body stays round it.
##   Couple's standing distance is found once, at rest, and kept: couple who have
##     taken hold do not step to and fro as they turn.

{.experimental: "strictFuncs".}

import ./[body, hold, limb, rig, rigid]


const
  STEP* = 0.02   ## Turns walked between two moments.
  BEATS* = 200   ## Engine steps per moment.  Slow enough to stay quasi-static.
  MOST* = 2.5    ## Turns tried each way before sweep gives up.


type
  Moment* = object ## One moment of turn, all page needs to draw it.
    at*: float ## Turns from rest, signed.
    stance*: array[Body, Stance]
    arms*: seq[array[2, ArmPose]] ## One per connection.
    room*: float ## Least room any joint had here.

  Walk* = object ## One sweep, one way.
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

proc walked(rig: Rig; band: Band; links: seq[Link]; who: Body;
            apart, most, step: float; away: bool; head: Body): Walk =
  ## Turn one way from rest until something gives, or until `most` is reached.
  var c = build(rig, restStance(rig, apart, away), band, links, head)
  c.settle()
  var at = 0.0
  let first = momentOf(c, at)
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

proc holdsAt*(rig: Rig; band: Band; links: seq[Link]; turns: float;
              away = false; head = Body.Two; apart = 0.0): bool =
  ## Whether any pose holds at this facing, asked afresh where couple stand.
  ##   Still card claims position exists; moving one claims couple can carry to
  ##     it.  They are not same question, and `sim/verdicts` already kept them
  ##     apart -- "asked afresh whether any pose holds there at all, not whether
  ##     arms can carry to it".  Asking still card reachability calls drawing
  ##     wrong for want of way in, which is not what it says.
  let far = if apart > 0.0: apart else: restApart(rig, band, links, away)
  var c = build(rig, turned(restStance(rig, far, away), Body.Two, turns),
                band, links, head)
  c.settle()
  result = true
  for i in 0 ..< links.len:
    if c.stopOf(i) != Stop.None:
      result = false
  c.free()

proc swept*(rig: Rig; band: Band; links: seq[Link]; who = Body.Two;
            most = MOST; step = STEP; apart = 0.0; away = false;
            head = Body.Two): Swept =
  ## Sweep both ways from rest, at distance hold settles to unless told one.
  ##   `who` turns; `head` is whose crown joined hands are carried over.  They
  ##     are usually same dancer and part company for orbit: orbit about
  ##     couple's centre is change of world frame and moves neither dancer with
  ##     respect to other, so it is turn of *other* dancer physically -- but
  ##     couple still raised their hands over one who walks.
  result.apart = if apart > 0.0: apart else: restApart(rig, band, links, away)
  var c = build(rig, restStance(rig, result.apart, away), band, links, head)
  c.settle()
  result.restHolds = true
  for i in 0 ..< links.len:
    if c.stopOf(i) != Stop.None:
      result.restHolds = false
  c.free()
  if not result.restHolds:
    return
  result.pos = walked(rig, band, links, who, result.apart, most, step, away, head)
  result.neg = walked(rig, band, links, who, result.apart, most, -step, away, head)
