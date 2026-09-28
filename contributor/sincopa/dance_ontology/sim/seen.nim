## One sweep recorded in full, as engine holds it, for page to draw.
##
##   Page cannot run engine -- engine is C and page is script in browser -- so what
##     page draws is recorded here, natively, at build time.  Same arrangement
##     `design/turns` uses, and reason nothing on page guesses at physics.
##   Every figure comes off engine.  Capsules are ones `rigid` handed it, asked
##     for their world ends rather than worked out again from stance; joints are
##     read where laws read them.  Drawing that works anything out for itself can
##     disagree with what was simulated, and this is meant to be way to see what
##     was simulated.
##   Kept apart from `walk` on purpose.  `walk` searches, and search runs whole
##     sweep at every distance couple may stand at; carrying this much at each of
##     them would cost tens of times what answering costs.  So sweep is answered
##     first, and only one that won is recorded.

{.experimental: "strictFuncs".}

import std/math

import ./[body, hold, limb, rig, rigid, vec, walk]


type
  Bar* = object ## One capsule, where it lies now.
    who*: Body
    arm*: Arm   ## Which arm, where `mark` is not `Trunk`.
    mark*: Mark
    a*, z*: Vec ## Segment's two ends, in world.
    r*: float   ## And radius round it.

  Ache* = object ## One arm's joints, each beside range it has to stay inside.
    who*: Body
    arm*: Arm
    read*: array[Dof, float]  ## What joint reads.
    lower*, upper*: array[Dof, float] ## And ends it is held between.

  Faces* = object ## Where one dancer stands and which way they look.
    at*: Vec   ## Axis at floor.
    fore*: Vec ## Unit, horizontal, out of their chest.

  Still* = object ## One moment, everything page draws of it.
    at*: float          ## Turns from rest, signed.
    faces*: array[Body, Faces]
    bars*: seq[Bar]
    arms*: seq[Ache]
    grips*: seq[Vec]    ## Where each pair of joined hands has got to.
    apart*: seq[float]  ## And how far engine has pulled each pair apart.

  Shown* = object ## Whole sweep, and what came of it.
    hold*: string       ## Which hold, in words.
    band*: Band
    apart*: float       ## Where couple stood for it.
    turns*: float       ## How far it got.
    stopped*: bool
    why*: Stop
    whose*: Hand        ## Whose hand it gave at.
    stills*: seq[Still]


func degrees*(r: float): float = r * 180.0 / PI
  ## Convert radians to degrees.


proc acheOf(c: Couple; who: Body; arm: Arm): Ache =
  ## Read one arm's six joints, each against its own two ends.
  ##   Twist's ends are swapped for left arm, as `twistEnds` has it, so range
  ##     quoted here is arm's own rather than rig's unmirrored one.
  let
    (swings, twist_angle, bend_angle, wrist_angle) = c.jointsOf(who, arm)
    (twist_lower, twist_upper) = twistEnds(c.rig, arm)
  result = Ache(who: who, arm: arm)
  result.read = [swings.extend, swings.across, twist_angle, bend_angle, wrist_angle]
  for d in Dof:
    result.lower[d] = c.rig.range[d].lower
    result.upper[d] = c.rig.range[d].upper
  result.lower[Dof.Twist] = twist_lower
  result.upper[Dof.Twist] = twist_upper

proc stillOf(c: Couple; at: float): Still =
  ## Everything page draws of couple as they stand this moment.
  result.at = at
  for who in Body:
    let axes = axesOf(c.chestStance(who))
    result.faces[who] = Faces(at: axes.origin, fore: axes.fore)
  for s in c.shapes:
    let (a, z) = c.endsOf(s)
    result.bars.add Bar(who: s.who, arm: s.arm, mark: s.mark, a: a, z: z, r: s.r)
  for who in Body:
    for arm in Arm:
      result.arms.add c.acheOf(who, arm)
  for i in 0 ..< c.links.len:
    let p = c.poseOf(i)
    result.grips.add (p.arms[0].g + p.arms[1].g) * 0.5
    result.apart.add p.apart

proc still*(rig: Rig; band: Band; links: seq[Link]; name: string;
            turns: float; away = false; head = Body.Two; either = false): Shown =
  ## One still, from distance couple stand for it, or none if no distance holds.
  ##   Still is wound to its facing and left standing, as `walk.stood` has it,
  ##     and distance is `walk.standing`'s choice, as is way about where still
  ##     fixes none, so what page draws of it is what `modelled` answered about
  ##     it, where model has couple stand.
  result = Shown(hold: name, band: band, turns: turns, stopped: true, why: Stop.None)
  let where = standing(rig, band, links, turns, away, head, either)
  if not where.holds: return
  let (holds, c) = stood(rig, band, links, where.turns, away, head, where.apart)
  if holds:
    result.apart = where.apart
    result.turns = where.turns
    result.stopped = false
    result.stills.add stillOf(c, where.turns)
  c.free()

proc shown*(rig: Rig; band: Band; links: seq[Link]; name: string;
            who = Body.Two; step = STEP; away = false;
            head = Body.Two): Shown =
  ## Walk one way from wherever it carries furthest, keeping every moment whole.
  ##   Distance is asked of `walk.swept`, so page shows couple standing exactly
  ##     where model has them stand and not somewhere chosen for drawing.
  let
    sweep = swept(rig, band, links, who = who, most = MOST, step = step,
               away = away, head = head)
    best = (if step >= 0.0: sweep.positive else: sweep.negative)
  result = Shown(
    hold: name,
    band: band,
    apart: best.apart,
    turns: best.at,
    stopped: best.stopped,
    why: best.why,
    whose: best.whose,
  )
  if not best.restHolds:
    return
  var c = build(rig, restStance(rig, best.apart, away), band, links, head, away)
  c.settle()
  var at = 0.0
  result.stills.add stillOf(c, at)
  let most = (if best.stopped: best.at else: MOST)
  while abs(at) < most:
    c.turn(who, step, BEATS)
    at += step
    result.stills.add stillOf(c, at)
  c.free()
