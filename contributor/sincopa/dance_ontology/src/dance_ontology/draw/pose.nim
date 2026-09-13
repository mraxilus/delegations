## Place couple in world coordinates, and give them every way to rotate.
##
##   Pose is where two dancers actually are; `canonicalise` turns
##     world until lead faces up page, which is what makes two poses
##     that are same configuration seen from different angles same
##     picture.
##     Cost of canonicalising: pose's world coordinates are never shown, so
##       reader cannot tell from one picture which way room was.
##       Accepted -- room was never subject.
##   Cycle is move, come home, move back, come home, so animation
##     returns exactly to its start and loops without snap.
##     Cost of palindrome: half of every cycle is other half played
##       backwards, so move is only ever seen at pace it can be
##       unseen at.  Accepted -- loop that snapped would say move has
##       end, and no frame's hold does.
##   Dancers and arms index fixed arrays: domain is closed and two wide,
##     so storage is enum-indexed rather than keyed by name.
##     Cost of fixed storage: third dancer is type change, not datum.
##       Accepted -- partner dance is couple by definition.

{.experimental: "strictFuncs".}

import std/[math, options]

import ./[geometry, terms]


const SEPARATION* = 56.0     ## Between two dancers' centres.

type
  Wind* = array[Arm, float] ## Degrees each arm has been carried past rest.
  Winds* = array[Dancer, Wind] ## Both dancers' windings at once.
  Ring* = tuple ## Orbit ring, drawn only while orbit is happening.
    centre: Point
    radius: float
  Pose* = object ## Hold where couple are, and how far their arms wound.
    place*: array[Dancer, Point]  ## World position of each dancer.
    facing*: array[Dancer, float] ## Bearing each dancer faces, degrees.
    wind*: Winds                  ## How far each arm is carried round.
    ring*: Option[Ring]           ## Orbit ring, where one is happening.



#[ Standing and Turning ]#

func rest*(wind: Winds = default(Winds)): Pose =
  ## Get pose every picture is measured from: lead facing up page.
  Pose(
    place: [(0.0, SEPARATION / 2), (0.0, -SEPARATION / 2)],
    facing: [0.0, 180.0],
    wind: wind,
    ring: none(Ring),
  )


func movedPose*(pose: Pose; mid: Point; spin, amount: float): Pose =
  ## Turn whole pose about `mid`, then pull it `amount` of way home.
  func moved(p: Point): Point =
    let q = turn(p, mid, spin)
    (q.x - amount * mid.x, q.y - amount * mid.y)

  result = pose
  for who in Dancer:
    result.place[who] = moved(pose.place[who])
    result.facing[who] = pose.facing[who] + spin
  if pose.ring.isSome:
    result.ring = some (moved(pose.ring.get.centre), pose.ring.get.radius)


type Anchor* {.pure.} = enum ## Say what picture is framed on.
  Pair,                      ## Couple's midpoint: they sit in middle.
  Lead                       ## Lead's own place: they are still point.


func canonicalise*(pose: Pose; amount = 1.0; on = Anchor.Pair): Pose =
  ## Turn world until lead faces up page.
  ##   Not until pair stands upright -- until *lead* does.
  ##     Everything is read from them, so they are thing that holds
  ##     still, and where follow has got to is then part of what
  ##     picture says rather than something framing has thrown away.
  ##   `on` says what turning goes round and what is brought to
  ##     middle afterwards.  On pair, couple is centred and any move
  ##     that shifts their midpoint carries lead across box with it.
  ##     On lead, lead never moves at all: follow's orbit leaves
  ##     framing exactly as it found it and needs no second stage, and
  ##     lead's axis turn swings only follow (rule 25).
  ##   At `amount` 0 it leaves pose alone and at 1 it finishes job,
  ##     so second stage of move is animated rather than snapped.
  let hub =
    case on
    of Anchor.Pair:
      ((pose.place[Dancer.Lead].x + pose.place[Dancer.Follow].x) / 2,
       (pose.place[Dancer.Lead].y + pose.place[Dancer.Follow].y) / 2)
    of Anchor.Lead:
      pose.place[Dancer.Lead]
  movedPose(pose, hub, -amount * wrap180(pose.facing[Dancer.Lead]), amount)


func spinAbout*(pose: Pose; who: Dancer; degrees: float): Pose =
  ## Turn one dancer on their own axis: nothing travels.
  result = pose
  result.facing[who] = pose.facing[who] + degrees
  result.ring = none(Ring)


func orbit*(pose: Pose; who: Dancer; degrees: float; locked = true): Pose =
  ## Walk one dancer round other, who stands still.
  ##   `locked` is what orbit is (rule 32): **whatever side of walker
  ##     faced centre goes on facing it**, so their facing swings with
  ##     radius and they turn as far as they travel.  Where they set off
  ##     facing their partner they keep facing them; where they set off
  ##     facing away they stay facing away.
  ##   Without it they keep their own bearing and arrive facing way they
  ##     set off, which is orbit and counter-turn danced together --
  ##     compound, and different move landing in different place.
  let pivot = pose.place[if who == Dancer.Lead: Dancer.Follow else: Dancer.Lead]
  result = pose
  result.place[who] = turn(pose.place[who], pivot, degrees)
  result.facing[who] = pose.facing[who] + (if locked: degrees else: 0.0)
  result.ring = some (pivot, dist(pose.place[who], pivot))


func couple*(pose: Pose; degrees: float): Pose =
  ## Turn both round each other: pair rotates rigidly about midpoint.
  let mid = ((pose.place[Dancer.Lead].x + pose.place[Dancer.Follow].x) / 2,
             (pose.place[Dancer.Lead].y + pose.place[Dancer.Follow].y) / 2)
  result = movedPose(pose, mid, degrees, 0.0)
  result.ring = some (mid, dist(pose.place[Dancer.Lead], mid))


func relative*(pose: Pose): tuple[axis, facing: float] =
  ## Get what canonical picture holds: where follow is, and how they
  ## face.
  ##   Both measured against lead, because lead is what picture
  ##     holds still.  Two poses with same pair are same picture.
  let axis = bearing(
    pose.place[Dancer.Follow].x - pose.place[Dancer.Lead].x,
    pose.place[Dancer.Follow].y - pose.place[Dancer.Lead].y)
  (round(floorMod(axis - pose.facing[Dancer.Lead], 360.0), 6),
   round(floorMod(pose.facing[Dancer.Follow] - pose.facing[Dancer.Lead],
                  360.0), 6))



#[ Moving on One Clock ]#

func ease*(t: float): float =
  ## Slow both ends, so two stages read as stages rather than as blur.
  (1 - cos(PI * t)) / 2


type MoveApply* = proc (pose: Pose; scalar: float): Pose {.nimcall, noSideEffect.}
  ## One animated move, as pose it reaches at `scalar` of its full turn.


type Walk* = tuple ## Move sampled for animation, and its own timing.
  poses: seq[Pose]
  times: seq[float] ## How far through move each pose is due, 0 to 1.
    ## Frames are not evenly spread: what move spends its time on is part
    ##   of what it says (rule 26).


const
  RE_FRAME_PACE* = 0.4 ## Clock second stage gets beside first.
    ## Turn is subject and re-framing is picture catching
    ##   up with it, so re-framing runs at well under half pace --
    ##   quick enough to read as settle rather than as second move.
  RESET_PACE* = 0.7 ## Clock coming back gets beside going out.
    ## Going out is what figure is of and coming back only undoes it, so
    ##   return runs quicker -- enough to read as reset rather than as
    ##   second turn, and not so quick that eye cannot follow it.
    ## Judged by eye, not measured: it is smallest step that reads at
    ##   glance, and is meant to be tuned that way.
  ARRIVAL_HOLD* = 0.25 ## Beat held on turn's landing before it follows.
    ## Without it two stages run together as one long motion; with it
    ##   turn is seen to finish, and what happens next is plainly
    ##   frame and not dance.


func timed(paces: seq[float]): seq[float] =
  ## Turn how long each step takes into when each frame is due.
  var total = 0.0
  for pace in paces:
    total += pace
  var run = 0.0
  for pace in paces:
    run += pace
    result.add (if total > 0: run / total else: 0.0)


func cycle*(move: MoveApply; samples = 14): Walk =
  ## Sample move, come home, move back, come home -- returning to start.
  ##   Stages are ranked exactly as `turnWalk` ranks them, and for same
  ##     reasons (rule 26): move is what figure is of, coming home is
  ##     picture catching up with it, and second leg only undoes first,
  ##     so whole of it runs at `RESET_PACE`.
  ##   Cycle drawn on one flat clock reads as four moves of equal weight,
  ##     which is what this had before times were carried.
  for sign in [1.0, -1.0]:
    let
      first = result.poses.len == 0
      base = if first: rest() else: result.poses[^1]
      pace = if first: 1.0 else: RESET_PACE
    for i in 0 .. samples:
      result.poses.add move(base, sign * ease(i / samples))
      # Clock starts at first pose of all; first pose of second leg stands
      # on first leg's landing, so beat is held there as it is at every
      # other landing.
      result.times.add (
        if i > 0: pace / float(samples)
        elif first: 0.0
        else: ARRIVAL_HOLD)
    let landed = result.poses[^1]
    for i in 0 .. samples:
      # Nothing travels in second stage, so ring goes out with it.
      var home = canonicalise(landed, ease(i / samples))
      home.ring = none(Ring)
      result.poses.add home
      result.times.add (
        if i == 0: ARRIVAL_HOLD * pace
        else: pace * RE_FRAME_PACE / float(samples))
  result.times = timed(result.times)



#[ Ways of Turning ]#

type About* {.pure.} = enum ## What dancer's turn goes round.
  Axis,                     ## Their own centre: they turn on spot.
  Orbit                     ## Their partner: they walk ring round them.


func turned*(base: Pose; who: Dancer; about: About; degrees: float): Pose =
  ## Turn one dancer, on their own axis or round their partner.
  ##   Orbit **faces centre** (rule 32): whatever side of walker
  ##     faced their partner goes on facing them, so walker turns as far
  ##     as they travel.
  ##     Which is what lets half turn mean one thing however it is danced.
  ##       Walker who kept their own bearing would never turn relative to
  ##         their partner and so would wind pair not at all, and half
  ##         turn of orbit would not be half turn of anything -- which is
  ##         correction rule 32 makes to rule 20.
  ##     Keeping bearing is still move; it is orbit and
  ##       counter-turn danced together, and is named as compound it is
  ##       wherever it is still wanted.
  case about
  of About.Axis: spinAbout(base, who, degrees)
  of About.Orbit: orbit(base, who, degrees, locked = true)


func turnWalk*(base: Pose; who: Dancer; about: About; degrees: float;
    samples = 12; on = Anchor.Pair; steps = 1; back = true): Walk =
  ## Sample turn and its return, in stages dance has.
  ##   Stage one is turn itself, **with world held still**:
  ##     dancer turns where they are and picture does not follow them.
  ##   Stage two reorients picture, turning it until lead faces up
  ##     again (rule 18).  It is only there when there is something to
  ##     bring back -- turn that leaves framing as it found it is
  ##     drawn in one stage, and what counts as framing is `on`.
  ##   `steps` says how many such turns run one after another, each
  ##     setting off from where last landed.  One is single turn; four
  ##     quarters walk whole round, and six halves walk whole chain.
  ##     Landing between two of them is held for beat, as landing
  ##       between stages is: without it walk reads as one long slide
  ##       and its steps cannot be counted by eye.
  ##   `back` says whether same again in reverse follows, so going and
  ##     coming read from one figure.  Walk that closes on itself needs
  ##     no return and takes none: round of four quarters ends where it
  ##     began.
  ##   Stages do not share clock evenly.  Turn is what
  ##     figure is of; re-framing is picture catching up with it,
  ##     and is paced to read that way (rule 26).
  ##   Turn that leaves picture as it found it is still drawn: pair
  ##     can come back to same places and facings with its arms wound,
  ##     and wind is what drawing measures for itself (rule 28).
  ##     Only turn of nothing at all is skipped.
  func legs(from_pose: Pose; by: float): Walk =
    let landed = turned(from_pose, who, about, by)
    if abs(by) < 1e-9:
      return (@[from_pose], @[0.0])
    # Stage one: turn, as room sees it, over whole beat of clock.
    for i in 0 .. samples:
      result.poses.add turned(from_pose, who, about, by * ease(i / samples))
      result.times.add (if i == 0: 0.0 else: 1.0 / float(samples))
    # Stage two: picture is re-framed until lead faces up and
    # anchor is back in middle.  Nothing travels in it, so orbit's
    # ring goes out with it.  It is skipped where it would draw nothing --
    # framed on lead, that is every turn but lead's own (rule 25).
    var settled_home = canonicalise(landed, on = on)
    settled_home.ring = none(Ring)
    if settled_home.place == landed.place and
        settled_home.facing == landed.facing:
      result.poses[^1] = settled_home
      return result
    # Beat on landing first: same pose twice, which is one still.
    result.poses.add result.poses[^1]
    result.times.add ARRIVAL_HOLD
    for i in 1 .. samples:
      var home = canonicalise(landed, ease(i / samples), on)
      home.ring = none(Ring)
      result.poses.add home
      result.times.add RE_FRAME_PACE / float(samples)

  # Two legs meet on one pose, so every join is beat like landing between
  # stages.  Coming back runs at `RESET_PACE` throughout: emphasis rule 26
  # takes off re-framing comes off whole return for same reason, since
  # return is not what figure is of either.
  var standing = base
  for (by, pace) in [(degrees, 1.0), (-degrees, RESET_PACE)]:
    if pace != 1.0 and not back:
      break
    for step in 1 .. steps:
      let one = legs(standing, by)
      for i, p in one.poses:
        result.poses.add p
        result.times.add (
          if result.poses.len == 1: 0.0
          elif i == 0: ARRIVAL_HOLD
          else: one.times[i] * pace)
      standing = result.poses[^1]
  result.times = timed(result.times)


func moveLeadAxis(pose: Pose; scalar: float): Pose =
  spinAbout(pose, Dancer.Lead, 90 * scalar)

func moveFollowOrbits(pose: Pose; scalar: float): Pose =
  orbit(pose, Dancer.Follow, 90 * scalar, locked = true)

func moveLeadOrbits(pose: Pose; scalar: float): Pose =
  orbit(pose, Dancer.Lead, 90 * scalar, locked = true)

func moveCouple(pose: Pose; scalar: float): Pose =
  couple(pose, 90 * scalar)

const MOVES*: array[4, tuple[name: string, apply: MoveApply]] = [
  ("lead axis", MoveApply moveLeadAxis),
  ("follow orbits the lead", moveFollowOrbits),
  ("the lead orbits the follow", moveLeadOrbits),
  ("both, round each other", moveCouple),
] ## Every animated move, in order page and checks walk them.
