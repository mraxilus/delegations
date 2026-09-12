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
    lo*, hi*: array[Dof, float] ## And ends it is held between.

  Still* = object ## One moment, everything page draws of it.
    at*: float          ## Turns from rest, signed.
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


proc acheOf(c: Couple; who: Body; arm: Arm): Ache =
  ## Read one arm's six joints, each against its own two ends.
  ##   Twist's ends are swapped for left arm, as `twistEnds` has it, so range
  ##     quoted here is arm's own rather than rig's unmirrored one.
  let
    (j, tw, bd, wr) = c.jointsOf(who, arm)
    (twLo, twHi) = twistEnds(c.rig, arm)
  result = Ache(who: who, arm: arm)
  result.read = [j.extend, j.across, tw, bd, wr]
  for d in Dof:
    result.lo[d] = c.rig.range[d].lo
    result.hi[d] = c.rig.range[d].hi
  result.lo[Dof.Twist] = twLo
  result.hi[Dof.Twist] = twHi

proc stillOf(c: Couple; at: float): Still =
  ## Everything page draws of couple as they stand this moment.
  result.at = at
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

proc shown*(rig: Rig; band: Band; links: seq[Link]; name: string;
            who = Body.Two; step = STEP; away = false;
            head = Body.Two): Shown =
  ## Walk one way from wherever it carries furthest, keeping every moment whole.
  ##   Distance is asked of `walk.swept`, so page shows couple standing exactly
  ##     where model has them stand and not somewhere chosen for drawing.
  let
    sw = swept(rig, band, links, who = who, most = MOST, step = step,
               away = away, head = head)
    best = (if step >= 0.0: sw.pos else: sw.neg)
  result = Shown(hold: name, band: band, apart: best.apart, turns: best.at,
                 stopped: best.stopped, why: best.why, whose: best.whose)
  if not best.restHolds:
    return
  var c = build(rig, restStance(rig, best.apart, away), band, links, head)
  c.settle()
  var at = 0.0
  result.stills.add stillOf(c, at)
  let most = (if best.stopped: best.at else: MOST)
  while abs(at) < most:
    c.turn(who, step, BEATS)
    at += step
    result.stills.add stillOf(c, at)
  c.free()
