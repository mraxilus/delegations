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
    moments*: seq[Moment]

  Swept* = object ## Both ways from one rest.
    apart*: float
    restHolds*: bool
    neg*, pos*: Walk


proc momentOf(c: Couple; at: float): tuple[m: Moment, why: Stop, which: int] =
  ## Read every connection at this moment, and say what gave, if anything.
  result.m = Moment(at: at, stance: c.stance, room: Inf)
  result.why = Stop.None
  result.which = -1
  for i in 0 ..< c.links.len:
    let p = c.poseOf(i)
    result.m.arms.add p.arms
    result.m.room = min(result.m.room, roomAt(c, p, i))
    if result.why == Stop.None:
      let gave = c.stopOf(i)
      if gave != Stop.None:
        result.why = gave
        result.which = i

proc walked(rig: Rig; band: Band; links: seq[Link]; who: Body;
            apart, most, step: float): Walk =
  ## Turn one way from rest until something gives, or until `most` is reached.
  var c = build(rig, facing(rig, apart), band, links)
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
      break
    result.moments.add now.m
  c.free()

proc swept*(rig: Rig; band: Band; links: seq[Link]; who = Body.Two;
            most = MOST; step = STEP; apart = 0.0): Swept =
  ## Sweep both ways from rest, at distance hold settles to unless told one.
  result.apart = if apart > 0.0: apart else: restApart(rig, band, links)
  var c = build(rig, facing(rig, result.apart), band, links)
  c.settle()
  result.restHolds = true
  for i in 0 ..< links.len:
    if c.stopOf(i) != Stop.None:
      result.restHolds = false
  c.free()
  if not result.restHolds:
    return
  result.pos = walked(rig, band, links, who, result.apart, most, step)
  result.neg = walked(rig, band, links, who, result.apart, most, -step)
