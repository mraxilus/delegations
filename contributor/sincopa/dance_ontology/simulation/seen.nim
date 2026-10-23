## One sweep recorded in full, as engine holds it, for page to draw.
##
##   Page cannot run engine -- engine is C and page is script in browser -- so what
##     page draws is recorded here, natively, at build time, and nothing on page guesses
##     at physics.
##   Every figure comes off engine.  Capsules are ones `rigid` handed it, asked
##     for their world ends rather than worked out again from stance; joints are
##     read where laws read them.  Drawing that works anything out for itself can
##     disagree with what was simulated, and this is meant to be way to see what
##     was simulated.
##   Kept apart from `walk` on purpose.  `walk` searches, and search runs whole
##     sweep at every distance couple may stand at; carrying this much at each of
##     them would cost tens of times what answering costs.  So sweep is answered
##     first, and only one that won is recorded.
##   Way over crown that walk stops short of all it asks, by whatever stopped it, is recorded as
##     planned way where that holds further: its moments are stood again from plan, as
##     `walk.plannedWay` stood them.

{.experimental: "strictFuncs".}

import std/[math, options]

import ./[body, hold, limb, rig, rigid, vector, walk]


type
  Bar* = object  ## One capsule, where it lies now.
    who*: Body
    arm*: Arm  ## Which arm, where `mark` is not `Trunk`.
    mark*: Mark
    a*, z*: Vector  ## Segment's two ends, in world.
    radius*: float  ## And radius round it.

  Ache* = object  ## One arm's joints, each beside range it has to stay inside.
    who*: Body
    arm*: Arm
    read*: array[Dof, float]  ## What joint reads.
    lower*, upper*: array[Dof, float]  ## And ends it is held between.

  Faces* = object  ## Where one dancer stands and which way they look.
    at*: Vector  ## Axis at floor.
    fore*: Vector  ## Unit, horizontal, out of their chest.

  Still* = object  ## One moment, everything page draws of it.
    at*: float  ## Turns from rest, signed.
    faces*: array[Body, Faces]
    bars*: seq[Bar]
    arms*: seq[Ache]
    joins*: seq[Vector]  ## Where each pair of joined hands has got to.
    apart*: seq[float]  ## And how far engine has pulled each pair apart.

  Shown* = object  ## Whole sweep, and what came of it.
    hold*: string  ## Which hold, in words.
    band*: Band
    apart*: float  ## Where couple stood for it.
    turns*: float  ## How far it got.
    is_stopped*: bool
    why*: Stop
    whose*: Hand  ## Whose hand it gave at.
    stills*: seq[Still]
    is_planned*: bool
      ## Whether planner stood it: still no distance of carried walk held, or sweep's way over
      ## crown that walk stops short of all it asks (`walk.swept`).
    strain*: float  ## Worst joint of still, nought at ease and one at end.
    tried*: seq[Option[float]]  ## Strain of each pose its search tried, in order: none gave.


func degrees*(radians: float): float = radians * 180.0 / PI
  ## Convert radians to degrees.


proc toAche(couple: Couple, who: Body, arm: Arm): Ache =
  ## Read one arm's six joints, each against its own two ends.
  ##   Twist's ends are swapped for left arm, as `twistEnds` has it, so range
  ##     quoted here is arm's own rather than rig's unmirrored one.
  let
    (swings, twist_angle, bend_angle, wrist_angle) = couple.jointsNow(who, arm)
    (twist_lower, twist_upper) = twistEnds(couple.rig, arm)
  result = Ache(who: who, arm: arm)
  result.read = [swings.extend, swings.across, twist_angle, bend_angle, wrist_angle]
  for dof in Dof:
    result.lower[dof] = couple.rig.range[dof].lower
    result.upper[dof] = couple.rig.range[dof].upper
  result.lower[Dof.Twist] = twist_lower
  result.upper[Dof.Twist] = twist_upper

proc toStill(couple: Couple, at: float): Still =
  ## Everything page draws of couple as they stand this moment.
  result.at = at
  for who in Body:
    let axes = couple.chestStance(who).toAxes
    result.faces[who] = Faces(at: axes.origin, fore: axes.fore)
  for shape in couple.shapes:
    let (a, z) = couple.ends(shape)
    result.bars.add Bar(
      who: shape.who,
      arm: shape.arm,
      mark: shape.mark,
      a: a,
      z: z,
      radius: shape.radius,
    )
  for who in Body:
    for arm in Arm:
      result.arms.add couple.toAche(who, arm)
  for i in 0..<couple.links.len:
    let pose = couple.poseLink(i)
    result.joins.add (pose.arms[0].join + pose.arms[1].join) * 0.5
    result.apart.add pose.apart

proc stillAsked(
  rig: Rig,
  band: Band,
  links: seq[Link],
  name: string,
  turns: float,
  is_away: bool,
  head: Body,
  is_either_way: bool,
  who: Body,
  over: Option[Arm],
): Shown =
  ## One still, `who` turning, from distance couple stand for it, or none if no distance
  ## holds.
  ##   Still is wound to its facing and left standing, as `walk.stood` has it,
  ##     and distance is `walk.standing`'s choice, as is way about where still
  ##     fixes none, so what page draws of it is what `modelled` answered about
  ##     it, where model has couple stand.
  ##   Still no carried walk holds is stood where planned way stands it nearest to ease,
  ##     of every plan that holds (`walk.plannedStill`), as distance is chosen.
  result = Shown(hold: name, band: band, turns: turns, is_stopped: true, why: Stop.None)
  let where = standing(rig, band, links, turns, is_away, head, is_either_way, who, over)
  if not where.is_holding:
    let planned = plannedStill(
      rig,
      band,
      links,
      turns,
      is_away,
      head,
      is_either_way,
      who,
      should_seek_ease = true,
      over = over,
    )
    result.is_planned = true
    result.tried = planned.tried
    if planned.is_holding:
      result.apart = planned.apart
      result.turns = planned.turns
      result.strain = planned.strain
      result.is_stopped = false
      result.stills.add toStill(planned.couple, planned.turns)
      planned.couple.free()
    return
  let (is_holding, couple) = stood(rig, band, links, where.turns, is_away, head, where.apart, who)
  result.tried = where.tried
  if is_holding:
    result.apart = where.apart
    result.turns = where.turns
    result.strain = where.strain.most
    result.is_stopped = false
    result.stills.add toStill(couple, where.turns)
  couple.free()

proc shownAsked(
  rig: Rig,
  band: Band,
  links: seq[Link],
  name: string,
  who: Body,
  step: float,
  is_away: bool,
  head: Body,
): Shown =
  ## Walk one way from wherever it carries furthest, keeping every moment whole.
  ##   Distance is asked of `walk.swept`, so page shows couple standing exactly
  ##     where model has them stand and not somewhere chosen for drawing.
  ##   Way over crown that walk stops short of all it asks is planned way, as `walk.swept` keeps
  ##     it: each moment it keeps is stood again from plan (`walk.standMoment`), as
  ##     `walk.replayedWay` stood it, and none past them.
  let
    sweep = swept(
      rig,
      band,
      links,
      who = who,
      most = MOST,
      step = step,
      is_away = is_away,
      head = head,
      should_plan = true,
    )
    best = (if step >= 0.0: sweep.positive else: sweep.negative)
  result = Shown(
    hold: name,
    band: band,
    apart: best.apart,
    turns: best.at,
    is_stopped: best.is_stopped,
    why: best.why,
    whose: best.whose,
    is_planned: best.isPlanned,
  )
  if not best.found_rest:
    return
  if best.isPlanned:
    var planned = builtFor(rig, band, links, is_away, head, best.path)
    for i in 0..<best.path.plans.len:
      planned.standMoment(best.path, i, is_away)
      result.stills.add toStill(planned, best.path.winds[i])
    planned.free()
    return
  var couple = build(rig, restStance(rig, best.apart, is_away), band, links, head, is_away)
  couple.settle()
  var at = 0.0
  result.stills.add toStill(couple, at)
  let most = (if best.is_stopped: best.at else: MOST)
  while abs(at) < most:
    couple.turn(who, step, BEATS)
    at += step
    result.stills.add toStill(couple, at)
  couple.free()



#[ Kept ]#

# Mutable and global: one run keeps every still it stood, for every thread (`walk.keepAnswers`).
var STILLS: Store[Shown]  ## Every still asked, by every argument but its name.
initStore(STILLS)

proc still*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  name: string,
  turns: float,
  is_away = false,
  head = Body.Two,
  is_either_way = false,
  who = Body.Two,
  over = none(Arm),
): Shown =
  ## One still, `who` turning, from distance couple stand for it, or none if no distance
  ## holds (`stillAsked`).
  ##   Card that asks what another card asks reads still that one stood, under its own name.
  ##   Reflected twin is not asked here: page mirrors still its twin keeps (`design/twins`).
  ##   Card that draws crossing names lead's arm laid over (`over`), or none.
  result = kept(
    STILLS,
    key(rig, links, $band, bits(turns), $is_away, $head, $is_either_way, $who, $over),
    stillAsked(rig, band, links, name, turns, is_away, head, is_either_way, who, over),
  )
  result.hold = name

proc shown*(
  rig: Rig,
  band: Band,
  links: seq[Link],
  name: string,
  who = Body.Two,
  step = STEP,
  is_away = false,
  head = Body.Two,
): Shown =
  ## Walk one way from wherever it carries furthest, keeping every moment whole
  ## (`shownAsked`).
  shownAsked(rig, band, links, name, who, step, is_away, head)
