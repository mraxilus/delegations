## Two dancers in rigid body engine, and what turning one of them does to their arms.
##
##   Solver this replaces proposed poses and checked them, with no motion between two
##     of them, so arms could never slide along one another and chain wound to one
##     crossing and stopped.  Here arms are bodies with mass, on joints with ends, and
##     turn is motion: sliding is what engine does rather than what it cannot say.
##   Engine stands Y up and project stands Z up.  `simulation/engine` holds no translation on
##     purpose, so this module is that one place.  `asEngine` and `asWorld` are only
##     two doors between them and both are rotations, never swaps of two axes: swap
##     mirrors world, and mirrored swan is other-handed swan.
##   Joint axes are engine's own convention, read off its source rather than guessed.
##     Spherical joint twists about frame B's local z and cones about frame A's local
##     z; revolute joint hinges about frame A's local z.  So every link is built with
##     its own length along its local z, which puts humeral rotation onto shoulder's
##     twist by construction.
##   What each joint may do comes from `simulation/rig`, which is tape and clinical tables.
##     Engine holds elbow's hinge and wrist's cone exactly.  Shoulder's swing it
##     cannot: rig gives extension and adduction as two ranges of their own, engine
##     offers one cone about rest.  Cone is left off rather than invented, and swing is
##     read back off pose and judged against rig.  Leaving it off also leaves arm's
##     elevation free, for which rig gives no range either.  Over crown, then, where
##     arms are clear of both bodies and swing is nowhere near its ends, twist is only
##     thing left to run out -- which is what Architect reports of dancing it.
##   Twist's ends are stated for right arm, in negative and out positive.  Left arm is
##     same joint seen in mirror, so its frame is not mirrored -- that would turn its
##     elbow backwards -- and its two ends are swapped instead.
##   Torso's section is stadium rather than ellipse: engine collides capsules, and two
##     of them side by side give stadium of same tape round at same flatness.  Neck and
##     head fall out of same formula, flatness of one leaving one capsule.

{.experimental: "strictFuncs".}

import std/[locks, math]

import ./[body, hold, limb, rig, vector]
from ./engine import nil


# Mutable: lock is state by nature.  Global, because every couple on every thread shares
# engine's one table of worlds.
var LOCK_WORLDS: Lock
  ## Engine keeps its worlds in one table and makes and destroys them without
  ## locking, so two threads building couples at once took one slot for two
  ## worlds and died of illegal instruction inside engine.  Stepping is each
  ## world's own and needs no lock.
initLock(LOCK_WORLDS)


const
  HERTZ* = 240.0  ## Steps per second.  Arm is short and stiff; slower step lets
                      ## grip joint stretch before solver catches it.
  SUBSTEPS* = cint(8)  ## Engine's own inner steps, where joint limits are met.
  DENSITY = 1000.0  ## Flesh is about water, so links weigh what arms weigh.
  DAMPING = 4.0  ## Linear and angular damping: arms settle, never ring.
                      ## Measured against leaps between moments: seven times this
                      ## took 232 mm to 204, so it is not what leaps were.
  PARTED* = 0.02  ## Hands this far apart, in metres, are no longer joined.
  AT_END* = 0.02  ## Joint within this of its end, in radians, is at its end.
  GIVE* = 0.1  ## How far past its end joint may sit and still hold, in that
                      ## end's ease.  Same reading, and same reason, old solver's
                      ## `TOLERANCE` had: under three degrees at joint is less than
                      ## flesh gives.  Without it arm cannot rest against its limit
                      ## and slide along it, which is what arm does: hold reads
                      ## blocked at very moment limit is first touched, and torque
                      ## that should push arm back never gets one step to act in.
  CONTACT = 0.125 * HERTZ * float(SUBSTEPS)  ## Hertz overlap is pushed apart at:
                      ## engine's own cap, eighth of its substep rate.  Its default
                      ## of thirty is softer than simulation's own forces, and arms were
                      ## crushed through bodies with hands still joined -- forearm
                      ## 45 mm inside its own trunk, then popping out.  Architect:
                      ## arms "get crushed and phase through".  Measured over
                      ## crown sweep: 44.7 mm deepest at thirty, 7.9 at 120, 2.2 at
                      ## 240 and no less at 480, under engine's 5 mm slop.
  FRICTION = 0.2  ## Coulomb friction where arm meets body.  Engine's default
                      ## of 0.6 is rubber on road; cloth on cloth is nearer this,
                      ## and arm lying over head at 0.6 was dragged round with it
                      ## as dancer turned under, winding follow's shoulder to its end by
                      ## 1.24 turns.  Measured: cross-name crown hold stops at 1.24
                      ## at 0.6, at 1.46 at nought, and turns free at this.
  THROUGH* = 0.01  ## Overlap this deep, in metres, is arm through body: twice
                      ## engine's slop, where contact holding is never seen.
  GRIP = 30.0  ## Hertz joined hands hold at: half engine's default, and
                      ## and softest thing in couple after shoulder girdle, so
                      ## hold forced past what arms can do gives at hands, in
                      ## life as here, and parting is what says which joint was
                      ## at its end.  Measured through forced whole turn at
                      ## 1.10 m: at sixty, twist and wrist carried three degrees
                      ## past their ends' slack; at thirty, once girdle could give
                      ## its five centimetres first, wrist carried nine past its
                      ## cone; at this, nothing.  Held as stiffly as joints,
                      ## joints tore.
  HOLD = 0.25 * HERTZ * float(SUBSTEPS)  ## Hertz every joint but grip holds at: engine's
                      ## own cap, quarter of its substep rate, and above contact's,
                      ## so what gives first is contact and not joint.  At its
                      ## default of sixty, arm pressing own chest carried chest
                      ## 34 mm off hips' axis (16 at 240, 6 here and no less at
                      ## twice this), and once contact was stiff, joints tore
                      ## instead: elbow 42 degrees past straight, wrist 40 past
                      ## its cone, twist 27 past its end.
  SETTLE* = 3000  ## Steps given to first pose before anything is read off it.
                      ## Measured: twist still moving at 1000, settled by 3000.
  CLEAR* = 0.10  ## Least clear air between two torsos, metres.
  EASE* = 1.0  ## Hertz of spring holding each joint toward its rest.
  EASE_DAMPING* = 1.0  ## And its damping.  Soft: it biases pose, never drives it.
  HANG_HERTZ* = 5.0  ## Hertz of shoulder's spring on arm hanging free, standing
                      ## in for weight that holds hanging arm plumb: five kilograms
                      ## of arm at third of metre is seventeen newton metres per
                      ## radian.  At one hertz, spring is about two, and flank's
                      ## friction dragged follow's arms behind follow's slow half turn by
                      ## forty nine degrees, creeping back to thirty three through
                      ## settle; at two, twenty four and eight; three, thirteen and
                      ## five; here, five and four.  Assumed.
  WRIST_EASE* = 5.0  ## Hertz of wrist's spring.  Hand weighs four hundred grams,
                      ## so at one hertz its spring is three hundredths of newton
                      ## metre per radian and wrist meets nothing before its cone:
                      ## joined at rest, wrists sat at sixty of sixty, and plainest
                      ## hold carried 0.56 where it had carried 1.04.  Passive
                      ## wrist stiffness is about one newton metre per radian,
                      ## which on that hand is five hertz; measured, wrists rest at
                      ## forty four degrees with room to spare.


type
  Limb* {.pure.} = enum  ## Three links of one arm, shoulder outward.
    Upper, Fore, Palm

  ArmRig = object  ## One arm's bodies and its three joints, and what it hangs from.
    collar: engine.BodyId  ## Collarbone: hinged to chest at breastbone about trunk's up.
    girdle: engine.BodyId  ## Shoulder girdle: hinged to collarbone about trunk's fore,
                       ## so shoulder joint rolls fore and aft and shrugs up, as
                       ## scapula on its collarbone does.
    link: array[Limb, engine.BodyId]
    swing: array[Collar, engine.JointId]  ## Collarbone's two hinges, `Collar`'s order.
    shoulder, elbow, wrist: engine.JointId

  Figure = object  ## One dancer: trunk that is turned, and two arms that follow.
    trunk: engine.BodyId  ## Hips: kinematic, turned by simulation, never pushed.
    chest: engine.BodyId  ## What shoulders hang from: dynamic, yaws on hips.
    waist: engine.JointId  ## Hinge between them, about trunk's up.
    arm: array[Arm, ArmRig]

  Mark* {.pure.} = enum  ## What part of whom one capsule is.
    Trunk, Upper, Fore, Palm,
    Girdle  ## Shoulder: from neck's side out to shoulder joint, on body that gives.

  Shape* = object  ## One capsule engine collides, as engine was given it.
    body*: engine.BodyId
    who*: Body  ## Whose.
    arm*: Arm  ## Which arm, where `mark` is not `Trunk`.
    mark*: Mark
    a*, z*: engine.Vector  ## Its segment's two ends, in that body's own terms.
    radius*: float  ## And radius round segment.

  Couple* = object  ## Both dancers, their world, and connections between their hands.
    world: engine.WorldId
    rig*: Rig
    stance*: array[Body, Stance]
    band*: Band
    links*: seq[Link]
    turning*: Body  ## Whose head hands are carried over, at crown.
    rest_twist: float  ## Twist of couple's rest, so how far they have wound is known.
    rest_tip: seq[array[2, float]]  ## Where each joined hand settled at rest, per
                                  ## connection and end, from which it rises.
    who: array[Body, Figure]
    grip: seq[engine.JointId]
    is_steered*: bool  ## Joints sprung to plan; carry's lift and draw left off.
    shapes*: seq[Shape]  ## Every capsule above, kept as it was handed to engine.
      ## Recorded rather than worked out again, so anything drawing couple draws
      ## what is being simulated and cannot quietly disagree with it.

  Pose* = object  ## Where one connection's two arms lie, and what their joints read.
    arms*: array[2, ArmPose]
    twist*, bend*, wrist*: array[2, float]  ## Each arm's three joints, radians.
    apart*: float  ## How far engine has pulled two hands apart, metres.

  Strain* = object  ## Where couple's pose is nearest some end, over every arm,
                        ## both waists and every shoulder girdle.
    most*: float  ## Nought outside every ease, one at some end, more past it.
    whose*: Hand  ## Arm it sits at, where it is arm's.
    what*: string  ## Which joint: freedom's name, `waist` or `girdle`.



#[ Engine Doors ]#

func asEngine(vector: Vector): engine.Vector = engine.initVector(vector.x, vector.z, -vector.y)
  ## Project's Z up into engine's Y up.  Rotation, so handedness survives.

func asWorld(vector: engine.Vector): Vector = (float(vector.x), -float(vector.z), float(vector.y))
  ## And back.

func asWorld(position: engine.Position): Vector =
  ## Read engine's place in project's terms.
  let (x, y, z) = engine.at(position)
  (x, -z, y)

func asPlace(point: Vector): engine.Position = engine.Position(x: point.x, y: point.z, z: -point.y)
  ## Write project's point as engine's place.



#[ Engine Turns ]#

func quaternionOf(x, y, z: engine.Vector): engine.Quaternion =
  ## Turn whose frame these three units are, given in parent's terms.
  let trace = x.x + y.y + z.z
  if trace > 0.0:
    let s = sqrt(trace + 1.0) * 2.0
    engine.Quaternion(
      vector: engine.initVector((y.z - z.y) / s, (z.x - x.z) / s, (x.y - y.x) / s),
      scalar: cfloat(0.25 * s),
    )
  elif x.x > y.y and x.x > z.z:
    let s = sqrt(1.0 + x.x - y.y - z.z) * 2.0
    engine.Quaternion(
      vector: engine.initVector(0.25 * s, (y.x + x.y) / s, (z.x + x.z) / s),
      scalar: cfloat((y.z - z.y) / s),
    )
  elif y.y > z.z:
    let s = sqrt(1.0 + y.y - x.x - z.z) * 2.0
    engine.Quaternion(
      vector: engine.initVector((y.x + x.y) / s, 0.25 * s, (z.y + y.z) / s),
      scalar: cfloat((z.x - x.z) / s),
    )
  else:
    let s = sqrt(1.0 + z.z - x.x - y.y) * 2.0
    engine.Quaternion(
      vector: engine.initVector((z.x + x.z) / s, (z.y + y.z) / s, 0.25 * s),
      scalar: cfloat((x.y - y.x) / s),
    )

func quaternionProduct(a, b: engine.Quaternion): engine.Quaternion =
  ## One turn after another: `a` carrying `b`.
  engine.Quaternion(
    vector: engine.initVector(
      a.scalar * b.vector.x + a.vector.x * b.scalar +
        a.vector.y * b.vector.z - a.vector.z * b.vector.y,
      a.scalar * b.vector.y - a.vector.x * b.vector.z +
        a.vector.y * b.scalar + a.vector.z * b.vector.x,
      a.scalar * b.vector.z + a.vector.x * b.vector.y -
        a.vector.y * b.vector.x + a.vector.z * b.scalar,
    ),
    scalar: cfloat(
      a.scalar * b.scalar - a.vector.x * b.vector.x -
                     a.vector.y * b.vector.y - a.vector.z * b.vector.z,
    ),
  )



#[ Couple Construction ]#

func stadium(rig: Rig, part: Part): tuple[radius, spread: float] =
  ## Radius of section's round ends, and how far apart their two centres sit.
  ##   Tape gives round and flatness; stadium of that round at that flatness is
  ##     two capsules side by side.  Flatness of one gives spread of nought, so
  ##     neck and head come out of same line as one capsule each.
  let
    flatness = rig.flat[part]
    wide = rig.round[part] / (2.0 * PI * flatness + 4.0 * (1.0 - flatness))
  (wide * flatness, 2.0 * (wide - wide * flatness))

func trunkCapsules*(rig: Rig): seq[tuple[a, z: Vector, radius: float]] =
  ## Every capsule of one trunk in body's own terms: x right, y fore, z up.
  ##   One list, handed to engine and to anything reading engine's world, so
  ##     what is collided and what is measured are one shape.  Reader's own
  ##     `contact` draws parts as cylinders with flat ends, and over torso's
  ##     dome of 125 mm that reads arm inside body where engine has it clear.
  for part in Part:
    let
      (capsule_radius, spread) = stadium(rig, part)
      lower = bottom(rig, part) + capsule_radius
      upper = rig.top[part] - capsule_radius
      middle = (lower + upper) / 2.0
    for side in [-0.5, 0.5]:
      result.add ((side * spread, 0.0, (if upper > lower: lower else: middle)),
                  (side * spread, 0.0, (if upper > lower: upper else: middle)), capsule_radius)
      if spread == 0.0:
        break

const FACE_FORE* = 0.05
  ## Metres face's sphere sits ahead of head's centre, at head's radius: arm clear of sphere
  ## is clear of face.
  ##   Sphere's front reaches 14 cm ahead of head's axis, where head reaches 9; nose sits
  ##     about 12 cm ahead, by ANSUR II head length 0.20 / 0.19 m, so arm resting on sphere
  ##     stands some 2 cm off nose.  Beside head sphere stands 1.3 cm proud of head's
  ##     capsule, and over crown 0.8 cm.  Estimate and not tape.

func faceCapsule*(rig: Rig): tuple[a, z: Vector, radius: float] =
  ## Face as one sphere ahead of head, in body's own terms: x right, y fore, z up.
  let
    head = trunkCapsules(rig)[^1]
    centre = (head.a + head.z) * 0.5 + (0.0, FACE_FORE, 0.0)
  (centre, centre, head.radius)

const
  HANG_BEND = 10.0 * PI / 180.0  ## Elbow of arm hanging free at side: relaxed arm
                   ## hangs near straight.  Assumed.
  GIRDLE_RADIUS* = 0.06  ## Radius of shoulder's capsule, neck's side to shoulder joint:
                   ## deltoid and trapezius, estimate and not tape.  Architect's
                   ## to measure.
  COLLAR_HERTZ = 4.5  ## Hertz of spring holding each collarbone hinge where tape
                   ## puts shoulder.  Girdle weighs some two kilograms twelve
                   ## centimetres out, so this is about twenty newton metres per
                   ## radian: `MUSCLE`, what one arm pulls with, rolls shoulder
                   ## half way to its ease, and it costs from there.  Girdle was
                   ## welded on linear spring of three hertz with rope at five
                   ## centimetres, forty newtons moving it whole five, which is
                   ## scapula hanging slack; dancer's is held by its own muscle,
                   ## and every still with any pull on it had shoulder at rope's
                   ## end.  Hinges in place of spring and rope, since roll of
                   ## shoulder turns glenoid too, which arm raised overhead
                   ## twists by; spring alone let free arm shoved by other body
                   ## carry its girdle 251 mm off, into own torso.  Assumed.
  COLLAR_LEAN = 40.0  ## Newton metres per radian collarbone is turned back once
                   ## into its ease: seven at ease's end.  Assumed.
  COLLAR_RADIUS = 0.06  ## Radius of collarbone's own capsule, which meets nothing:
                   ## it gives collarbone half kilogram, fifth of girdle's, so
                   ## solver holds chain of chest, collarbone and girdle.  At one
                   ## centimetre, fiftieth of girdle, both girdles left their
                   ## hinges by half metre standing still.
                   ## Girdle weighs some two kilograms here, so this is 800 N/m:
                   ## forty newtons, arm's weight, moves shoulder five
                   ## centimetres, which is what scapula gives.  Architect: bodies
                   ## are too rigid, arms get dislocated because of it -- shoulder
                   ## joint sat nine centimetres outside every capsule of its own
                   ## body, and nothing of it could give.
  WAIST_LEAN = 60.0  ## Newton metres per radian chest is turned back toward
    ## square once yawed into waist's ease: fifteen at ease's end, about what
    ## trunk's passive stiffness gives near end of thoracic rotation.  Assumed.
    ## Waist's range is rig's (`Rig.waist`).  Shoulders lag or lead hips by it,
    ## sprung to neutral.  At every stop left before waist turned, several
    ## joints sat at their ends at once, which is arm reaching where rigid trunk
    ## cannot help it; dancer winding chain turns shoulders ahead of or behind
    ## hips, and this is that.
    ##   Measured, with waist: every chain over crown free or past swan under
    ##     every manner, fifty six of fifty six chain questions, and every lower
    ##     band up -- same-name chain at neck 1.00 to 1.12, at torso 0.88 to
    ##     1.06.  Low wraps of single holds now stop, at 0.96 and 1.56, where
    ##     they ran free without it, which is nearer floor's half turn though
    ##     still past it.

const
  TRUNK_BIT = 1'u64  ## Torso, neck and head.
  ARM_BIT: array[Body, uint64] = [2'u64, 4'u64]  ## Lead's arms, follow's arms.
  EVERY = high(uint64)  ## Meets everything.

func ownGroup(who: Body): cint =
  ## Group one dancer's trunk and shoulder girdles share, so they never meet:
  ## girdle lies through neck and torso by construction, and hung on its
  ## collarbone rather than welded to chest it is no longer one joint from it.
  ##   Engine skips pairs in one negative group.  Arms keep groups of their own,
  ##     so arm still meets its own trunk and other dancer's girdle meets both.
  -cint(100 + ord(who))

func isHeld(couple: Couple, who: Body, arm: Arm): bool =
  ## Whether this arm's hand is joined to any other.
  for link in couple.links:
    for hand in link.ends:
      if hand == (who, arm): return true
  false

proc capsule(
  couple: var Couple;
  body: engine.BodyId;
  who: Body;
  arm: Arm;
  mark: Mark;
  a, z: engine.Vector;
  capsule_radius, density: float;
  group: cint;
) =
  ## Hang one capsule on body, with its own group so arm's own links pass.
  ##   Kept on couple as well as handed to engine: page draws this list, so shape
  ##     drawn and shape collided are one thing said once.
  var
    capsule = engine.Capsule(center1: a, center2: z, radius: cfloat(capsule_radius))
    shape_definition = engine.defaultShape()
  shape_definition.density = cfloat(density)
  shape_definition.material.friction = cfloat(FRICTION)
  shape_definition.filter.group_index = group
  shape_definition.filter.category_bits = (if mark == Mark.Trunk: TRUNK_BIT else: ARM_BIT[who])
  # Everything meets everything, arms of two dancers included.  Letting lead's
  # arms pass through follow's was tried, on Architect's point that lead gets lead's
  # own arm out of way, and it reached swan -- by letting arms occupy same place,
  # which no couple does.  Architect: it made simulation worse.  Reverted.  Point stands
  # and wants real answer: lead who *moves* lead's arm, not one whose arm is absent.
  shape_definition.filter.mask_bits = EVERY
  discard engine.createCapsule(body, addr shape_definition, addr capsule)
  couple.shapes.add Shape(
    body: body,
    who: who,
    arm: arm,
    mark: mark,
    a: a,
    z: z,
    radius: capsule_radius,
  )

func standing(axes: Axes): engine.Quaternion =
  ## Turn carrying dancer's own axes onto world's, in engine's terms.
  ##   Engine's basis is not project's: body's forward is engine's negative z, and
  ##     its up is engine's y.  Frame is built from that correspondence, never from
  ##     project's three axes in project's order, which lays dancer down.
  quaternionOf(asEngine(axes.right), asEngine((0.0, 0.0, 1.0)), asEngine(-axes.fore))

func upFrame(): engine.Quaternion =
  ## Frame whose z is trunk's own up, for hinge that yaws.
  ##   Trunk's local frame has up on its y (`standing`), and revolute hinges
  ##     about frame A's local z, so hinge frame turns local z onto local y.
  quaternionOf(engine.initVector(1, 0, 0), engine.initVector(0, 0, -1), engine.initVector(0, 1, 0))

proc trunkOf(couple: var Couple, who: Body): tuple[hips, chest: engine.BodyId,
                                             waist: engine.JointId] =
  ## Hips as kinematic body, turned and never pushed, carrying nothing; every
  ## capsule on dynamic chest hinged to them about trunk's up, sprung to neutral
  ## and stopped at thoracic rotation.  Shoulders hang from chest.
  let
    stance = couple.stance[who]
    axes = axesOf(stance)
  var body_definition = engine.defaultBody()
  body_definition.kind = engine.BODY_KINEMATIC
  body_definition.position = asPlace(axes.origin)
  body_definition.rotation = standing(axes)
  body_definition.should_sleep = false
  result.hips = engine.createBody(couple.world, addr body_definition)
  var collar_definition = engine.defaultBody()
  collar_definition.kind = engine.BODY_DYNAMIC
  collar_definition.position = asPlace(axes.origin)
  collar_definition.rotation = standing(axes)
  collar_definition.linear_damping = cfloat(DAMPING)
  collar_definition.angular_damping = cfloat(DAMPING)
  collar_definition.gravity_scale = 0.0
  collar_definition.should_sleep = false
  result.chest = engine.createBody(couple.world, addr collar_definition)
  var hinge = engine.defaultHinge()
  hinge.base.body_id_a = result.hips
  hinge.base.body_id_b = result.chest
  hinge.base.local_frame_a = engine.Frame(origin: engine.initVector(0, 0, 0), rotation: upFrame())
  hinge.base.local_frame_b = engine.Frame(origin: engine.initVector(0, 0, 0), rotation: upFrame())
  hinge.base.constraint_hertz = cfloat(HOLD)
  hinge.should_spring = true
  hinge.hertz = cfloat(EASE)
  hinge.damping_ratio = cfloat(EASE_DAMPING)
  hinge.target_angle = 0.0
  hinge.should_limit = true
  hinge.lower_angle = cfloat(couple.rig.waist.lower)
  hinge.upper_angle = cfloat(couple.rig.waist.upper)
  result.waist = engine.createHinge(couple.world, addr hinge)
  let body = result.chest
  for (a, z, capsule_radius) in trunkCapsules(couple.rig):
    capsule(
      couple,
      body,
      who,
      Arm.Left,
      Mark.Trunk,
      asEngine(a),
      asEngine(z),
      capsule_radius,
      DENSITY,
      ownGroup(who),
    )

const MARKS = [Mark.Upper, Mark.Fore, Mark.Palm]
  ## Which mark each of arm's three links carries, in `Limb`'s own order.

func restFrame(): engine.Quaternion =
  ## Shoulder's frame at rest, in trunk's own terms: arm hanging, elbow forward.
  ##   Its z is arm's length, which is what engine twists about.  Its x is elbow's
  ##     hinge, which points along body's right for both arms -- mirroring it would
  ##     bend left elbow backwards.  Twist's two ends are swapped instead.
  quaternionOf(asEngine((1.0, 0.0, 0.0)), asEngine((0.0, -1.0, 0.0)), asEngine((0.0, 0.0, -1.0)))

func hingeFrame(): engine.Quaternion =
  ## Elbow's frame within upper arm: its z is hinge, upper arm's own x.
  quaternionOf(engine.initVector(0, 0, 1), engine.initVector(0, -1, 0), engine.initVector(1, 0, 0))

func foreFrame(): engine.Quaternion =
  ## Frame whose z is trunk's own fore, for hinge that shrugs.
  ##   Trunk's fore is engine's negative z (`standing`), so frame turns local z
  ##     onto it: x stays, y is turned about.
  quaternionOf(engine.initVector(1, 0, 0), engine.initVector(0, -1, 0), engine.initVector(0, 0, -1))

func collarSign(arm: Arm, hinge: Collar): float =
  ## Which way hinge's own angle runs against rig's stated sense for this arm.
  ##   Rig states protraction and elevation positive.  Right shoulder swung
  ##     about trunk's up by positive angle goes fore; left goes aft.  Shoulder
  ##     swung about trunk's fore by positive angle goes down at right and up at
  ##     left.
  case hinge
  of Collar.Fore: side(arm)
  of Collar.Up: -side(arm)

func collarEnds*(rig: Rig, arm: Arm, hinge: Collar): tuple[lower, upper: float] =
  ## One collarbone hinge's two ends in hinge's own sense, for this arm.
  let collar_range = rig.collar[hinge]
  if collarSign(arm, hinge) > 0.0: (collar_range.lower, collar_range.upper)
  else: (-collar_range.upper, -collar_range.lower)

func collarRange(rig: Rig, arm: Arm, hinge: Collar): Range =
  ## One collarbone hinge's range in hinge's own sense, eases carried with ends.
  let collar_range = rig.collar[hinge]
  if collarSign(arm, hinge) > 0.0: collar_range
  else: Range(
    lower: -collar_range.upper,
    upper: -collar_range.lower,
    ease_lower: collar_range.ease_upper,
    ease_upper: collar_range.ease_lower,
    neutral: -collar_range.neutral,
  )

proc limbOf(
  couple: var Couple,
  who: Body,
  arm: Arm,
  mark: Mark,
  at: Vector,
  turn: engine.Quaternion,
  long: float,
  group: cint,
): engine.BodyId =
  ## One link: its own length along its local z, hung from `at`.
  var body_definition = engine.defaultBody()
  body_definition.kind = engine.BODY_DYNAMIC
  body_definition.position = asPlace(at)
  body_definition.rotation = turn
  body_definition.linear_damping = cfloat(DAMPING)
  body_definition.angular_damping = cfloat(DAMPING)
  body_definition.gravity_scale = 1.0
  body_definition.should_sleep = false
  result = engine.createBody(couple.world, addr body_definition)
  let limb_radius = couple.rig.limb
  if long > 2.0 * limb_radius:
    capsule(
      couple,
      result,
      who,
      arm,
      mark,
      engine.initVector(0, 0, limb_radius),
      engine.initVector(0, 0, long - limb_radius),
      limb_radius,
      DENSITY,
      group,
    )
  else:
    let middle = engine.initVector(0, 0, long / 2.0)
    capsule(couple, result, who, arm, mark, middle, middle, long / 2.0, DENSITY, group)

proc armOf(couple: var Couple, who: Body, arm: Arm, group: cint): ArmRig =
  ## Three links on shoulder, elbow and wrist, laid out hanging.
  let
    stance = couple.stance[who]
    axes = axesOf(stance)
    trunk_turn = standing(axes)
    frame = restFrame()
    turn = quaternionProduct(trunk_turn, frame)
    top = shoulder(couple.rig, stance, arm)
    long = [couple.rig.upper, couple.rig.fore, couple.rig.hand]
  var at = top
  for limb in Limb:
    result.link[limb] = limbOf(couple, who, arm, MARKS[ord(limb)], at, turn, long[ord(limb)], group)
    at = at + (0.0, 0.0, -long[ord(limb)])

  # Shoulder girdle: its own body at shoulder joint, carrying capsule from
  # neck's side out to joint, on collarbone hinged to chest at breastbone.
  #   Collarbone is body of its own at neck's side, hinged to chest about
  #   trunk's up (protraction, retraction); girdle hinges on it about trunk's
  #   fore (elevation, depression).  Two hinges in series are one universal
  #   joint, which engine has no one joint for.  Each is sprung to tape and
  #   stopped at collarbone's own range.  Collarbone's capsule meets nothing
  #   and is not drawn: it is there to give body mass.
  let
    # Collarbone's inner end in body's own terms, and shoulder joint from it.
    root: Vector = (side(arm) * halfBreadth(couple.rig, Part.Neck), 0.0, couple.rig.top[Part.Torso])
    inner: Vector = (side(arm) * (halfBreadth(couple.rig, Part.Neck) - couple.rig.shoulder_out),
                     0.0,
                     couple.rig.top[Part.Torso] - couple.rig.shoulder_up)
  var link_definition = engine.defaultBody()
  link_definition.kind = engine.BODY_DYNAMIC
  link_definition.position = asPlace(toWorld(axes, root))
  link_definition.rotation = trunk_turn
  link_definition.linear_damping = cfloat(DAMPING)
  link_definition.angular_damping = cfloat(DAMPING)
  link_definition.gravity_scale = 0.0
  link_definition.should_sleep = false
  result.collar = engine.createBody(couple.world, addr link_definition)
  var
    bone = engine.Capsule(
      center1: engine.initVector(0, 0, 0),
      center2: asEngine(-inner),
      radius: COLLAR_RADIUS,
    )
    shape_definition = engine.defaultShape()
  shape_definition.density = cfloat(DENSITY)
  shape_definition.filter.group_index = 0
  shape_definition.filter.category_bits = 0'u64
  shape_definition.filter.mask_bits = 0'u64
  discard engine.createCapsule(result.collar, addr shape_definition, addr bone)
  var grip_definition = engine.defaultBody()
  grip_definition.kind = engine.BODY_DYNAMIC
  grip_definition.position = asPlace(top)
  grip_definition.rotation = trunk_turn
  grip_definition.linear_damping = cfloat(DAMPING)
  grip_definition.angular_damping = cfloat(DAMPING)
  grip_definition.gravity_scale = 0.0
  grip_definition.should_sleep = false
  result.girdle = engine.createBody(couple.world, addr grip_definition)
  capsule(
    couple,
    result.girdle,
    who,
    arm,
    Mark.Girdle,
    asEngine(inner),
    asEngine((0.0, 0.0, 0.0)),
    GIRDLE_RADIUS,
    DENSITY,
    ownGroup(who),
  )
  # Hinge's angle is turn about its frame's local z, right handed.  Right
  # shoulder at trunk's right turned about trunk's up goes fore for positive
  # angle, and about trunk's fore goes down; left shoulder goes other way each
  # time.  Ranges are stated for right arm's fore and up, so left's are turned
  # about, and rise's sign is turned for both (`collarEnds`).
  for k in Collar:
    var hinge = engine.defaultHinge()
    if k == Collar.Fore:
      hinge.base.body_id_a = couple.who[who].chest
      hinge.base.body_id_b = result.collar
      hinge.base.local_frame_a = engine.Frame(origin: asEngine(root), rotation: upFrame())
      hinge.base.local_frame_b = engine.Frame(
        origin: engine.initVector(0, 0, 0),
        rotation: upFrame(),
      )
    else:
      hinge.base.body_id_a = result.collar
      hinge.base.body_id_b = result.girdle
      hinge.base.local_frame_a = engine.Frame(
        origin: engine.initVector(0, 0, 0),
        rotation: foreFrame(),
      )
      hinge.base.local_frame_b = engine.Frame(origin: asEngine(inner), rotation: foreFrame())
    let (lower, upper) = collarEnds(couple.rig, arm, k)
    hinge.should_spring = true
    hinge.hertz = cfloat(COLLAR_HERTZ)
    hinge.damping_ratio = 1.0
    hinge.target_angle = 0.0
    hinge.should_limit = true
    hinge.lower_angle = cfloat(lower)
    hinge.upper_angle = cfloat(upper)
    hinge.base.constraint_hertz = cfloat(HOLD)
    result.swing[k] = engine.createHinge(couple.world, addr hinge)

  var ball = engine.defaultBall()
  ball.base.body_id_a = result.girdle
  ball.base.body_id_b = result.link[Limb.Upper]
  ball.base.local_frame_a = engine.Frame(origin: engine.initVector(0, 0, 0), rotation: frame)
  ball.base.local_frame_b = engine.Frame(
    origin: engine.initVector(0, 0, 0),
    rotation: engine.IDENTITY,
  )
  # Upper arm and girdle overlap at joint by construction and never collide;
  # upper arm and chest are no longer one joint apart, so they do, and arm
  # hung from chest no longer sinks into own torso, neck and head unseen --
  # 67 mm inside own head by capsule geometry while engine reported no touch,
  # before shoulder was told to collide with what it hung from.
  # Held arm is placed by its hold and biased alone; free arm hangs by weight.
  ball.should_spring = true
  ball.hertz = cfloat(if couple.isHeld(who, arm): EASE else: HANG_HERTZ)
  ball.damping_ratio = cfloat(EASE_DAMPING)
  ball.target_rotation = engine.IDENTITY
  ball.should_limit_twist = true
  let twist_range = couple.rig.range[Dof.Twist]
  if arm == Arm.Right:
    ball.lower_twist_angle = cfloat(twist_range.lower)
    ball.upper_twist_angle = cfloat(twist_range.upper)
  else:
    ball.lower_twist_angle = cfloat(-twist_range.upper)
    ball.upper_twist_angle = cfloat(-twist_range.lower)
  ball.base.constraint_hertz = cfloat(HOLD)
  result.shoulder = engine.createBall(couple.world, addr ball)

  var hinge = engine.defaultHinge()
  hinge.base.body_id_a = result.link[Limb.Upper]
  hinge.base.body_id_b = result.link[Limb.Fore]
  hinge.base.local_frame_a = engine.Frame(
    origin: engine.initVector(0, 0, cfloat(couple.rig.upper)),
    rotation: hingeFrame(),
  )
  hinge.base.local_frame_b = engine.Frame(
    origin: engine.initVector(0, 0, 0),
    rotation: hingeFrame(),
  )
  hinge.should_spring = true
  hinge.hertz = cfloat(EASE)
  hinge.damping_ratio = cfloat(EASE_DAMPING)
  # Held arm rests at soft elbow, rig's neutral; free arm hangs, elbow near
  # straight, as relaxed arm at side does.  Hanging at thirty, forearm pointed
  # at partner and free couple at rest stood with arms crossed between them.
  hinge.target_angle = cfloat(if couple.isHeld(who, arm): couple.rig.range[Dof.Bend].neutral
                             else: HANG_BEND)
  hinge.should_limit = true
  hinge.lower_angle = cfloat(couple.rig.range[Dof.Bend].lower)
  hinge.upper_angle = cfloat(couple.rig.range[Dof.Bend].upper)
  hinge.base.constraint_hertz = cfloat(HOLD)
  result.elbow = engine.createHinge(couple.world, addr hinge)

  var cuff = engine.defaultBall()
  cuff.base.body_id_a = result.link[Limb.Fore]
  cuff.base.body_id_b = result.link[Limb.Palm]
  cuff.base.local_frame_a = engine.Frame(
    origin: engine.initVector(0, 0, cfloat(couple.rig.fore)),
    rotation: engine.IDENTITY,
  )
  cuff.base.local_frame_b = engine.Frame(
    origin: engine.initVector(0, 0, 0),
    rotation: engine.IDENTITY,
  )
  cuff.should_spring = true
  cuff.hertz = cfloat(WRIST_EASE)
  cuff.damping_ratio = cfloat(EASE_DAMPING)
  cuff.target_rotation = engine.IDENTITY
  cuff.should_limit_cone = true
  cuff.cone_angle = cfloat(couple.rig.range[Dof.Wrist].upper)
  cuff.base.constraint_hertz = cfloat(HOLD)
  result.wrist = engine.createBall(couple.world, addr cuff)

proc build*(
  rig: Rig,
  stance: array[Body, Stance],
  band: Band,
  links: seq[Link],
  turning = Body.Two,
  is_away = false,
): Couple =
  ## Stand two dancers, hang four arms, and join hands each link names.
  ##   No gravity.  Question reference asks is where arms can be, not what they
  ##     weigh, and weightless arms stay where turn leaves them, so pose at one
  ##     moment is pose before it carried forward rather than found afresh.
  var world_definition = engine.defaultWorld()
  world_definition.gravity = engine.initVector(0, 0, 0)
  world_definition.contact_hertz = cfloat(CONTACT)
  world_definition.should_sleep = false
  world_definition.should_collide_continuously = true
  withLock LOCK_WORLDS:
    result.world = engine.createWorld(addr world_definition)
  result.rig = rig
  result.stance = stance
  # Rest is Face-to-face, or Face-to-back for hold built so, whatever stance couple
  # are built at: still card built already wound is wound from that rest and
  # asks what turning does, and built as its own rest it asked for nothing --
  # no lift, no draw -- and four chain cards Architect keeps were lost.
  result.rest_twist = (if is_away: PI else: 0.0)
  result.band = band
  result.links = links
  result.turning = turning
  for who in Body:
    let (hips, chest, waist) = trunkOf(result, who)
    result.who[who].trunk = hips
    result.who[who].chest = chest
    result.who[who].waist = waist
  var group = cint(1)
  for who in Body:
    for arm in Arm:
      let built = armOf(result, who, arm, -group)
      result.who[who].arm[arm] = built
      group += 1
  for link in links:
    var grip = engine.defaultBall()
    grip.base.body_id_a = result.who[link.ends[0].body].arm[link.ends[0].arm].link[Limb.Palm]
    grip.base.body_id_b = result.who[link.ends[1].body].arm[link.ends[1].arm].link[Limb.Palm]
    grip.base.local_frame_a = engine.Frame(
      origin: engine.initVector(0, 0, cfloat(rig.hand)),
      rotation: engine.IDENTITY,
    )
    grip.base.local_frame_b = engine.Frame(
      origin: engine.initVector(0, 0, cfloat(rig.hand)),
      rotation: engine.IDENTITY,
    )
    grip.base.constraint_hertz = cfloat(GRIP)
    result.grip.add engine.createBall(result.world, addr grip)

proc partedAt*(couple: Couple, who: Body, arm: Arm): array[3, float] =
  ## How far shoulder, elbow and wrist of one arm have each been pulled apart,
  ## metres: engine's joints are soft, and what they give is dislocation.
  let arm_rig = couple.who[who].arm[arm]
  [
    float(engine.partedBy(arm_rig.shoulder)),
    float(engine.partedBy(arm_rig.elbow)),
    float(engine.partedBy(arm_rig.wrist)),
  ]

proc chestStance*(couple: Couple, who: Body): Stance =
  ## Where shoulders stand: hips' stance, turned by waist.
  ##   Every reading of arm in body's own terms goes through this, since arm
  ##     hangs from chest and not from hips.
  result = couple.stance[who]
  result.facing += float(engine.angleOf(couple.who[who].waist))

proc chestStances*(couple: Couple): array[Body, Stance] =
  ## Give stance of each dancer's chest, which waist turns off hips.
  for who in Body: result[who] = couple.chestStance(who)

proc free*(couple: Couple) =
  ## Give engine its world back.
  withLock LOCK_WORLDS:
    engine.destroyWorld(couple.world)



#[ Turn Readings ]#

const
  LIFT = 400.0  ## Newtons per metre couple carry joined hands toward their band by.
  RAISE = 0.25  ## Turns over which hands rise from where they rest to their band.
    ## Hands go up before head passes under, which is at quarter turn, and they
    ## go up as arm moves and not as switch is thrown: asked for band's edge
    ## outright, hand crossed 359 mm in first fiftieth of turn, which page draws
    ## as leap.  Architect: watch for sharp movements.  Rise starts from where
    ## each hand settled, and pull is not eased in on top of it: eased in, hand
    ## lagged ramp and caught up in one burst of 200 mm.
  FALL = 40.0  ## And damping on it, so hands arrive rather than swing.
  MUSCLE = 40.0  ## Newtons one arm carries its wrist with, at most: arm's own
    ## weight, which is what dancer lifts arm against and plainly can.  Lift
    ## and draw are springs toward where hands are meant to be, and spring
    ## wanting more than this is force dancer does not have: uncapped, hand
    ## twenty centimetres under its rise pulled with eighty newtons, through
    ## grip, on partner's shoulder, and every girdle sat at its rope's end
    ## before quarter turn.  Assumed.
  DRAW = [40.0, 40.0, 10.0]  ## Per band, newtons per metre hands are drawn toward
    ## where couple mean to carry them.  Weighted as old solver's `CENTRING` was,
    ## two to two to one half, and weak on purpose: this is preference couple have,
    ## not constraint.  Strong, it drags hands to one spot and arms trail into
    ## swings no shoulder makes, and hold reads blocked when only hands were held
    ## wrongly.  Measured at two hundred newtons per metre: crown blocked at 0.34
    ## of turn where floor says it never blocks.
  SHOULDER_BACK = 200.0  ## Newton metres per radian arm is past its swing.
    ## Stiff, so arm pressed against its end stays within `GIVE` of it rather than
    ## sinking through.  Upper arm's inertia is about 0.074, so this rings at some
    ## eight hertz, well inside step of two hundred and forty.
    ## Swing is only range engine was never given.  Judging it after each step and
    ## never resisting it let engine walk arm into places no shoulder goes and made
    ## hold read blocked where dancer would simply have put arm elsewhere.  Torque
    ## is what other three joints already get from engine; this gives swing same.
  SWING_LEAN = 200.0  ## Newton metres per radian arm is into its swing's ease: as
    ## stiff as wall past its end.  End alone is wall, and arm led over crown
    ## went round back of head at that wall, forty five degrees behind frontal
    ## plane at head's height, where going over top costs nothing.  Architect:
    ## no one would let their arm wrap behind their head like this.  Comfort is
    ## slope inside range, and this is that slope for swing.  Measured at ten,
    ## three and half newton metres at ease's end: hold carried follow's arm to wall
    ## at 0.24 of cross-name crown turn and stopped there; at this, follow's
    ## extension peaks at 27 and turn is free.

func awayFrom*(couple: Couple): float =
  ## How far couple are from face to face, in turns, nought to half: whole
  ## turns are not counted, since face to face is facing and not winding.
  var angle = twist(couple.stance) mod (2.0 * PI)
  if angle > PI: angle -= 2.0 * PI
  elif angle <= -PI: angle += 2.0 * PI
  abs(angle) / (2.0 * PI)

func wound*(couple: Couple): float =
  ## How far couple have wound from their rest, in turns, whole turns and all.
  abs(twist(couple.stance) - couple.rest_twist) / (2.0 * PI)

func risen*(couple: Couple): float =
  ## How far joined hands have risen from where they rest toward their band,
  ## nought to one.
  ##   Whole from rest for hold that rests Face-to-back, which is not Face-to-face.
  ##     Otherwise hands rise over first `RAISE` of wind and stay up: head that
  ##     passes under them is under them at every wind past that, whole turns
  ##     and all.  Keyed to distance from face to face instead, which folds
  ##     whole turns away, hands were let down onto follow's head through second
  ##     half of every whole turn, and every diamond and swan was wound with
  ##     hands at shoulder.
  if couple.rest_twist != 0.0: 1.0 else: min(1.0, couple.wound / RAISE)

func up*(couple: Couple): float =
  ## How far joined hands are from resting at mid torso toward being over
  ## crown, nought to one, by how far couple are from face to face: whole by
  ## `RAISE` of turn away, whole turns folding away.
  ##   Architect: relaxed position facing is hands at mid torso; pillion or back
  ##     to back they have to be above; facing, arms come down.  Couple wound
  ##     whole turn face each other again and their hands are down again,
  ##     which `risen` keyed to wind from rest never let them be: A09 stood
  ##     facing with hands over heads.
  if couple.band != Band.Crown: return couple.risen
  min(1.0, couple.awayFrom / RAISE)

func isLeavingCrown*(couple: Couple): bool =
  ## Whether couple are winding away from face to face rather than back toward
  ## it: hands go up and over follow's head one way, and come down in front of follow's
  ## other way.
  ##   Let down straight from over follow's crown as follow came back to face to face,
  ##     hands passed through follow's head; coming back they first come forward
  ##     off follow's crown to between two bodies, at crown height, then down.
  var fraction = (twist(couple.stance) / (2.0 * PI)) mod 1.0
  if fraction < 0.0: fraction += 1.0
  let direction = twist(couple.stance) - couple.rest_twist
  if direction == 0.0: return true
  (fraction < 0.5) == (direction > 0.0)

func over*(couple: Couple): float =
  ## How far joined hands are carried from between two bodies toward over crown
  ## of dancer who turns, nought to one: all way while going up, and coming
  ## back, first half of way down.
  if couple.band != Band.Crown or couple.isLeavingCrown: 1.0
  else: clamp((couple.up - 0.5) / 0.5, 0.0, 1.0)

func height*(couple: Couple): float =
  ## How far joined hands are from torso band toward crown band, nought to one:
  ## with `up` going up, and coming back, over second half of way down.
  if couple.band != Band.Crown: couple.risen
  elif couple.isLeavingCrown: couple.up
  else: clamp(couple.up / 0.5, 0.0, 1.0)

func bandNow*(couple: Couple): tuple[lower, upper: float] =
  ## Band joined hands are held to here: asked over crown, torso band facing,
  ## crown band away, and between by `height`.
  if couple.band != Band.Crown: return couple.rig.band[couple.band]
  let
    low = couple.rig.band[Band.Torso]
    high = couple.rig.band[Band.Crown]
    height_fraction = couple.height
  (lower: low.lower + (high.lower - low.lower) * height_fraction,
   upper: low.upper + (high.upper - low.upper) * height_fraction)

func tipOf(couple: Couple, arm_rig: ArmRig): Vector =
  ## Fingertip, which band is asked of.
  ##   Fingertip alone, forearm's lower end not too: asked of elbow as well over
  ##     crown, so forearm would clear head outright, every rise went in bursts,
  ##     elbow alone asked to climb swinging upper arm and hand at end of forearm
  ##     going three times as far -- 289 mm in one moment.  Forearm meeting head
  ##     is contact's to answer, and contact is stiff enough to now.
  asWorld(engine.pointOf(arm_rig.link[Limb.Palm], engine.initVector(0, 0, cfloat(couple.rig.hand))))

proc muscle(couple: Couple, arm_rig: ArmRig, force: Vector) =
  ## Carry this arm's wrist by `force`, put on as torque at shoulder and elbow
  ## with equal and opposite torque on link inside: what muscle does.
  ##   Force on links alone pulled whole chain up through shoulder and dragged
  ##     girdle to its rope's end -- shoulder five centimetres out of its socket
  ##     in every still whose hands were still rising, and nothing pulling on
  ##     any socket in life: muscle spans joint and pushes against link on its
  ##     other side.  Torque at joint is lever from joint to wrist crossed with
  ##     force, so what arm feels is force at wrist, and what socket feels is
  ##     nothing.  Shoulder's reaction goes to girdle, which is welded rigid in
  ##     turn to chest, and chest to hips.
  ##   Wrist is carried, never levered: hand is what band is asked of, and force
  ##     put on fingertip as torque at wrist too bent every wrist to its cone in
  ##     first moments of rise, hand being lightest link and torque sized for
  ##     whole arm.  Dancer raising joined hands raises arm; hand comes along.
  ##   `asEngine` is rotation and not mirror, so torque survives it whole.
  let
    shoulder_point = asWorld(engine.pointOf(arm_rig.link[Limb.Upper], engine.initVector(0, 0, 0)))
    elbow_point = asWorld(engine.pointOf(arm_rig.link[Limb.Fore], engine.initVector(0, 0, 0)))
    wrist_point = asWorld(engine.pointOf(arm_rig.link[Limb.Palm], engine.initVector(0, 0, 0)))
    shoulder_torque = cross(wrist_point - shoulder_point, force)
    elbow_torque = cross(wrist_point - elbow_point, force)
  engine.twistBy(arm_rig.girdle, asEngine(-shoulder_torque), true)
  engine.twistBy(arm_rig.link[Limb.Upper], asEngine(shoulder_torque - elbow_torque), true)
  engine.twistBy(arm_rig.link[Limb.Fore], asEngine(elbow_torque), true)

proc carry(couple: Couple) =
  ## Couple's own intent: keep each pair of joined hands somewhere in their band.
  ##   Band's two edges are held; everything between them is free.  Architect:
  ##     hand height is for turn, and nothing is fixed but keeping bodies apart.
  ##     Held at middle instead, couple spend on height reach turn wanted, and
  ##     card is answered about pose couple would never have chosen.
  ##   Lift is put on as muscle torque at every joint of arm, never as force on
  ##     hand alone.  Hand alone levers wrist, which then sits at its cone while
  ##     shoulder and elbow do nothing -- dancer raising joined hands raises arm.
  ##   Hands are drawn toward point between two bodies as well as to their band.
  ##     Without it grip floats off sideways and arms trail away behind, which
  ##     reads as shoulder giving out when it is only hands left unheld.
  let
    band = couple.bandNow
    # Asked over crown, hands rest at mid torso facing and are over crown away
    # (`up`).  Going up, lower edge rises as couple wind from rest, from where
    # hand settled to where crown band puts it, by `RAISE`, and hands are drawn
    # over follow's head as they rise; coming back, they come forward off follow's crown
    # first and then down, both edges of band let down with them (`over`,
    # `height`).  Asked lower, lower edge rises from where hand settled by
    # `RAISE` of wind (`risen`) and stays up.  Nothing is asked until rest has
    # settled and been read.
    is_crown = (couple.band == Band.Crown)
    is_leaving = couple.isLeavingCrown
    risen = couple.height
    one = axesOf(couple.stance[Body.One]).origin
    two = axesOf(couple.stance[Body.Two]).origin
    between = (one + two) * 0.5
    middle = (if is_crown: between +
                        (axesOf(couple.stance[couple.turning]).origin - between) * couple.over
              else: between)
      ## Over crown, hands go over head of dancer who turns, not between two:
      ## couple setting hold up put them there, and pulling them to midpoint
      ## instead makes both reach across their own body and spends adduction
      ## they need for turn.
  for i, link in couple.links:
    for k in 0..1:
      let
        arm_rig = couple.who[link.ends[k].body].arm[link.ends[k].arm]
        tip = tipOf(couple, arm_rig)
        drift = asWorld(engine.driftOf(arm_rig.link[Limb.Palm]))
      # While hand rises it is carried along its rise, held to it from both
      # sides, and nothing is asked of rise until rest has settled and been
      # read.  Risen, band is what holds, from first step: nought anywhere
      # inside it, hands pressed back toward whichever edge they left, and
      # left alone between them.
      var offset = 0.0
      if risen >= 1.0 or risen <= 0.0 or (is_crown and not is_leaving):
        if tip.z < band.lower: offset = band.lower - tip.z
        elif tip.z > band.upper: offset = band.upper - tip.z
      elif couple.rest_tip.len > 0:
        # Going up, ramp is to crown band's edge, as it always was.
        let
          top = (if is_crown: couple.rig.band[Band.Crown].lower else: band.lower)
          lower = couple.rest_tip[i][k] + (top - couple.rest_tip[i][k]) * risen
        offset = lower - tip.z
      let
        lift = LIFT * offset - FALL * drift.z
        # Drawn toward mid only as they rise, as lift is: face to face nothing
        # is asked.  Drawn at rest, over crown follow's hand was pulled to follow's own
        # axis before any turn, and follow's wrist sat at its cone from first moment.
        pull = (if is_crown and not is_leaving: 1.0 else: risen) * DRAW[ord(couple.band)]
        wanted: Vector = ((middle.x - tip.x) * pull - drift.x * FALL,
                       (middle.y - tip.y) * pull - drift.y * FALL, lift)
        want = norm(wanted)
        toward = (if want > MUSCLE: wanted * (MUSCLE / want) else: wanted)
      muscle(couple, arm_rig, toward)

proc holdSwing(couple: Couple) =
  ## Resist upper arm that has gone past extension or adduction.
  ##   Torque turns arm back toward range it left, about axis that carries its
  ##     own direction toward one it should not have passed.  Body's own terms
  ##     throughout, then back to world, then to engine.
  for who in Body:
    let axes = axesOf(couple.chestStance(who))
    for arm in Arm:
      let
        arm_rig = couple.who[who].arm[arm]
        shoulder_point = asWorld(
          engine.pointOf(arm_rig.link[Limb.Upper], engine.initVector(0, 0, 0)),
        )
        elbow_point = asWorld(
          engine.pointOf(
            arm_rig.link[Limb.Upper],
            engine.initVector(0, 0, cfloat(couple.rig.upper)),
          ),
        )
        upper_arm = ownTerms(axes, arm, elbow_point) - ownTerms(axes, arm, shoulder_point)
        direction = unit(upper_arm)
      var back: Vector = (0.0, 0.0, 0.0)
      let
        extend = arcsin(clamp(-direction.y, -1.0, 1.0))
        across = arcsin(clamp(-direction.x, -1.0, 1.0))
        extend_range = couple.rig.range[Dof.Extend]
        across_range = couple.rig.range[Dof.Across]
        lean_extend = extend - (extend_range.upper - extend_range.ease_upper)
        lean_across = across - (across_range.upper - across_range.ease_upper)
        out_extend = extend - extend_range.upper
        out_across = across - across_range.upper
      # Lean through ease is comfort, which plan already holds when couple are steered;
      # wall past end is range, and holds always.
      if lean_extend > 0.0 and not couple.is_steered:
        back = back + cross(direction, (0.0, 1.0, 0.0)) * (SWING_LEAN * lean_extend)
      if lean_across > 0.0 and not couple.is_steered:
        back = back + cross(direction, (1.0, 0.0, 0.0)) * (SWING_LEAN * lean_across)
      if out_extend > 0.0:
        back = back + cross(direction, (0.0, 1.0, 0.0)) * (SHOULDER_BACK * out_extend)
      if out_across > 0.0:
        back = back + cross(direction, (1.0, 0.0, 0.0)) * (SHOULDER_BACK * out_across)
      if back.x != 0.0 or back.y != 0.0 or back.z != 0.0:
        # Torque is pseudovector.  Mirrored frame is left handed, so cross product
        # worked out in it comes back negated: un-mirroring it as plain vector
        # gives exactly minus what is wanted, and turns correction into shove.
        let own: Vector = (if arm == Arm.Left: (x: back.x, y: -back.y, z: -back.z)
                        else: back)
        engine.twistBy(
          arm_rig.link[Limb.Upper],
          asEngine(axes.right * own.x + axes.fore * own.y + (0.0, 0.0, own.z)),
          true,
        )

const ELBOW_DOWN = 1.0  ## Newton metres elbow is turned down by: upper arm's
  ## weight about that line at half its lever, two kilograms at five centimetres.
  ## Measured: at nought, elbow crossed 280 mm between moments and arms rested
  ## twisted fifty four degrees to keep wrists straight; at two, wrists rested
  ## seventeen degrees twisted; at this, four, and no point of any held arm
  ## crossed 71 mm over three low and crown walks.

proc elbowDown(couple: Couple) =
  ## Turn each elbow toward hanging below line from shoulder to wrist.
  ##   Arm has no weight here, so nothing chose where elbow swivelled about that
  ##     line and it wandered: elbow crossed 280 mm between moments with hand
  ##     moving 77.  This is what weight does to elbow about that line and
  ##     nothing else weight does -- it neither loads raise nor pulls hand down.
  for who in Body:
    for arm in Arm:
      # Held arm alone: free arm hangs, and fixed newton metre about its near
      # vertical line twisted it forty degrees and swung it forward twenty,
      # forearm pointing at partner.
      if not couple.isHeld(who, arm): continue
      let
        arm_rig = couple.who[who].arm[arm]
        shoulder_point = asWorld(
          engine.pointOf(arm_rig.link[Limb.Upper], engine.initVector(0, 0, 0)),
        )
        elbow_point = asWorld(
          engine.pointOf(
            arm_rig.link[Limb.Upper],
            engine.initVector(0, 0, cfloat(couple.rig.upper)),
          ),
        )
        wrist_point = asWorld(
          engine.pointOf(arm_rig.link[Limb.Fore], engine.initVector(0, 0, cfloat(couple.rig.fore))),
        )
        line = wrist_point - shoulder_point
      if dot(line, line) < 1e-4: continue
      let
        axis = unit(line)
        offset = (elbow_point - shoulder_point) - axis * dot(elbow_point - shoulder_point, axis)
        down: Vector = (0.0, 0.0, -1.0)
        under = down - axis * dot(down, axis)
      if dot(offset, offset) < 1e-4 or dot(under, under) < 1e-4: continue
      let turn = cross(unit(offset), unit(under))
      engine.twistBy(arm_rig.link[Limb.Upper], asEngine(turn * ELBOW_DOWN), true)

const
  TWIST_LEAN = 25.0  ## Newton metres per radian twist is into its ease: eleven
                     ## at ease's end.  Was seven, three at end, gentle where
                     ## `SWING_LEAN` is stiff, and joints sat at their ends in
                     ## most stills: three newton metres is under what forty
                     ## newtons of lift at reach puts on shoulder.  Passive
                     ## stiffness of shoulder near end of rotation is about
                     ## this.  Assumed.
  ELBOW_LEAN = 15.0  ## Same for elbow, whose ease is thirty five degrees: nine
                     ## at end.  Assumed.
  WRIST_LEAN = 6.0  ## Same for wrist, two at cone: hand about it is one
                     ## thousandth, so this rings at twelve hertz there, well
                     ## inside step.  Assumed.

proc easeOff(couple: Couple) =
  ## Turn each joint engine holds back out of its ease, as `holdSwing` turns
  ## swing back.
  ##   Engine's limits are walls and its springs, at one hertz, are nothing, so
  ##     every joint ran to its end and stayed: twist at ninety through rise and
  ##     at minus seventy after, wrist at its cone from 0.40 on, elbow straight.
  ##     Architect: arms are not following comfort.  Comfort is slope inside
  ##     range, free in middle and rising through ease to end; this is that
  ##     slope, as torque between two links each joint joins.
  for who in Body:
    # Waist, about trunk's up: chest turned back toward square once into ease.
    let
      yaw = float(engine.angleOf(couple.who[who].waist))
      waist = couple.rig.waist
    var square = 0.0
    let (easing_upper, easing_lower) =
      (waist.upper - waist.ease_upper, waist.lower + waist.ease_lower)
    if yaw > easing_upper: square = -WAIST_LEAN * (yaw - easing_upper)
    elif yaw < easing_lower: square = WAIST_LEAN * (easing_lower - yaw)
    if square != 0.0:
      engine.twistBy(couple.who[who].chest, asEngine((0.0, 0.0, square)), true)
    let axes = axesOf(couple.chestStance(who))
    for arm in Arm:
      let arm_rig = couple.who[who].arm[arm]
      # Collarbone, each hinge about its own axis in world: girdle turned back
      # toward tape once into ease, chest taking reaction.
      for k in Collar:
        let
          collar_range = collarRange(couple.rig, arm, k)
          angle = float(engine.angleOf(arm_rig.swing[k]))
          axis = (if k == Collar.Fore: (0.0, 0.0, 1.0) else: axes.fore)
        var back = 0.0
        if angle > collar_range.upper - collar_range.ease_upper:
          back = -COLLAR_LEAN * (angle - (collar_range.upper - collar_range.ease_upper))
        elif angle < collar_range.lower + collar_range.ease_lower:
          back = COLLAR_LEAN * ((collar_range.lower + collar_range.ease_lower) - angle)
        if back != 0.0:
          engine.twistBy(arm_rig.girdle, asEngine(axis * back), true)
          engine.twistBy(couple.who[who].chest, asEngine(axis * -back), true)
    for arm in Arm:
      let
        arm_rig = couple.who[who].arm[arm]
        shoulder_point = asWorld(
          engine.pointOf(arm_rig.link[Limb.Upper], engine.initVector(0, 0, 0)),
        )
        elbow_point = asWorld(
          engine.pointOf(
            arm_rig.link[Limb.Upper],
            engine.initVector(0, 0, cfloat(couple.rig.upper)),
          ),
        )
        wrist_point = asWorld(
          engine.pointOf(arm_rig.link[Limb.Fore], engine.initVector(0, 0, cfloat(couple.rig.fore))),
        )
        grip_point = asWorld(
          engine.pointOf(arm_rig.link[Limb.Palm], engine.initVector(0, 0, cfloat(couple.rig.hand))),
        )
        upper_direction = unit(elbow_point - shoulder_point)
        fore_direction = unit(wrist_point - elbow_point)
        hand_direction = unit(grip_point - wrist_point)
      # Twist, about arm's own line.  Rig states right arm's ends; left is same
      # joint mirrored, ends and eases swapped, as `read.tightest` has them.
      let
        twist_range = couple.rig.range[Dof.Twist]
        (lower, upper, ease_lower, ease_upper) =
          if arm == Arm.Right:
            (twist_range.lower, twist_range.upper, twist_range.ease_lower, twist_range.ease_upper)
          else:
            (-twist_range.upper, -twist_range.lower, twist_range.ease_upper, twist_range.ease_lower)
        twist_angle = float(engine.twistAngleOf(arm_rig.shoulder))
      var back = 0.0
      if twist_angle > upper - ease_upper:
        back = -TWIST_LEAN * (twist_angle - (upper - ease_upper))
      elif twist_angle < lower + ease_lower:
        back = TWIST_LEAN * ((lower + ease_lower) - twist_angle)
      if back != 0.0:
        engine.twistBy(arm_rig.link[Limb.Upper], asEngine(upper_direction * back), true)
      # Elbow, about its hinge: rotating forearm toward upper arm closes nothing
      # that is already straight, and only far end has ease.
      let
        bend = float(engine.angleOf(arm_rig.elbow))
        over_bend = bend -
          (couple.rig.range[Dof.Bend].upper - couple.rig.range[Dof.Bend].ease_upper)
      if over_bend > 0.0:
        let normal = cross(upper_direction, fore_direction)
        if dot(normal, normal) > 1e-6:
          let torque = unit(normal) * (ELBOW_LEAN * over_bend)
          engine.twistBy(arm_rig.link[Limb.Fore], asEngine(torque * -1.0), true)
          engine.twistBy(arm_rig.link[Limb.Upper], asEngine(torque), true)
      # Wrist, its cone: hand turned back toward forearm's line.
      let
        cone = float(engine.coneAngleOf(arm_rig.wrist))
        over_cone = cone - (couple.rig.range[Dof.Wrist].upper -
                           couple.rig.range[Dof.Wrist].ease_upper)
      if over_cone > 0.0:
        let normal = cross(fore_direction, hand_direction)
        if dot(normal, normal) > 1e-6:
          let torque = unit(normal) * (WRIST_LEAN * over_cone)
          engine.twistBy(arm_rig.link[Limb.Palm], asEngine(torque * -1.0), true)
          engine.twistBy(arm_rig.link[Limb.Fore], asEngine(torque), true)

type Matrix* = array[3, array[3, float]]

func times(a, b: Matrix): Matrix {.used.} =  # Used in `plan.nim`.
  ## Multiply matrices of turn, i.e. turn by `b`, then by `a`.
  for i in 0..2:
    for j in 0..2:
      for k in 0..2:
        result[i][j] += a[i][k] * b[k][j]

func transposed(a: Matrix): Matrix {.used.} =  # Used in `plan.nim`.
  ## Transpose matrix of turn, i.e. its inverse.
  for i in 0..2:
    for j in 0..2:
      result[i][j] = a[j][i]

func turnAbout(v: array[3, float]): Matrix {.used.} =  # Used in `plan.nim`.
  ## Rodrigues: turn about `v` by its length.
  let angle = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
  result = [[1.0, 0, 0], [0.0, 1, 0], [0.0, 0, 1]]
  if angle < 1e-12: return
  let
    k = [v[0] / angle, v[1] / angle, v[2] / angle]
    skew: Matrix = [[0.0, -k[2], k[1]], [k[2], 0.0, -k[0]], [-k[1], k[0], 0.0]]
    square = times(skew, skew)
  for i in 0..2:
    for j in 0..2:
      result[i][j] += sin(angle) * skew[i][j] + (1.0 - cos(angle)) * square[i][j]

func quaternionOfMatrix(r: Matrix): engine.Quaternion =
  ## Matrix of turn as engine's quaternion: frame's own coordinates, so no axis swap.
  let trace = r[0][0] + r[1][1] + r[2][2]
  var w, x, y, z: float
  if trace > 0.0:
    let s = sqrt(trace + 1.0) * 2.0
    (w, x, y, z) = (0.25 * s, (r[2][1] - r[1][2]) / s, (r[0][2] - r[2][0]) / s,
                    (r[1][0] - r[0][1]) / s)
  elif r[0][0] > r[1][1] and r[0][0] > r[2][2]:
    let s = sqrt(1.0 + r[0][0] - r[1][1] - r[2][2]) * 2.0
    (w, x, y, z) = ((r[2][1] - r[1][2]) / s, 0.25 * s, (r[0][1] + r[1][0]) / s,
                    (r[0][2] + r[2][0]) / s)
  elif r[1][1] > r[2][2]:
    let s = sqrt(1.0 + r[1][1] - r[0][0] - r[2][2]) * 2.0
    (w, x, y, z) = ((r[0][2] - r[2][0]) / s, (r[0][1] + r[1][0]) / s, 0.25 * s,
                    (r[1][2] + r[2][1]) / s)
  else:
    let s = sqrt(1.0 + r[2][2] - r[0][0] - r[1][1]) * 2.0
    (w, x, y, z) = ((r[1][0] - r[0][1]) / s, (r[0][2] + r[2][0]) / s,
                    (r[1][2] + r[2][1]) / s, 0.25 * s)
  engine.Quaternion(vector: engine.initVector(x, y, z), scalar: cfloat(w))

const MATRIX_REST {.used.}: Matrix =  # Used in `plan.nim`.
  [[1.0, 0.0, 0.0], [0.0, -1.0, 0.0], [0.0, 0.0, -1.0]]
  ## Upper arm's frame at rest in body's terms, columns right, back, down (`restFrame`).

const WRIST_STEER* = 3.0
  ## Wrist spring over every other joint's: palm is lightest link, and spring in hertz
  ## holds it by that, so hand at others' rate trails plan.

proc steer*(couple: var Couple, plan: openArray[float], hertz: float) =
  ## Spring every joint toward planned pose: waists, collarbones, shoulders,
  ## elbows, wrists.  Plan is waists then nine per arm, lead's left first.
  couple.is_steered = true
  for who in Body:
    engine.aimHinge(couple.who[who].waist, cfloat(plan[2 + ord(who)]))
    engine.stiffenHinge(couple.who[who].waist, cfloat(hertz))
    for arm in Arm:
      let
        base = 4 + 9 * (2 * ord(who) + ord(arm))
        arm_rig = couple.who[who].arm[arm]
      engine.aimHinge(arm_rig.swing[Collar.Fore], cfloat(side(arm) * plan[base]))
      engine.aimHinge(arm_rig.swing[Collar.Up], cfloat(-side(arm) * plan[base + 1]))
      for k in Collar: engine.stiffenHinge(arm_rig.swing[k], cfloat(hertz))
      let shoulder_turn = times(
        transposed(MATRIX_REST),
        times(turnAbout([plan[base + 2], plan[base + 3], plan[base + 4]]), MATRIX_REST),
      )
      engine.aimBall(arm_rig.shoulder, quaternionOfMatrix(shoulder_turn))
      engine.stiffenBall(arm_rig.shoulder, cfloat(hertz))
      engine.aimHinge(arm_rig.elbow, cfloat(plan[base + 5]))
      engine.stiffenHinge(arm_rig.elbow, cfloat(hertz))
      let wrist_turn = quaternionOfMatrix(
        turnAbout(
          [plan[base + 6], plan[base + 7],
                                                         plan[base + 8]],
        ),
      )
      engine.aimBall(arm_rig.wrist, wrist_turn)
      engine.stiffenBall(arm_rig.wrist, cfloat(hertz * WRIST_STEER))

func turnVector(r: Matrix): array[3, float] =
  ## Turn's axis scaled by its angle: inverse of `turnAbout`.
  let
    cosine = clamp((r[0][0] + r[1][1] + r[2][2] - 1.0) / 2.0, -1.0, 1.0)
    angle = arccos(cosine)
  if angle < 1e-9: return [0.0, 0.0, 0.0]
  if angle > PI - 1e-6:
    # Half turn: axis from diagonal.
    let axis = [sqrt(max(0.0, (r[0][0] + 1.0) / 2.0)),
                sqrt(max(0.0, (r[1][1] + 1.0) / 2.0)),
                sqrt(max(0.0, (r[2][2] + 1.0) / 2.0))]
    var signed = axis
    if r[0][1] < 0.0: signed[1] = -signed[1]
    if r[0][2] < 0.0: signed[2] = -signed[2]
    return [signed[0] * angle, signed[1] * angle, signed[2] * angle]
  let scale = angle / (2.0 * sin(angle))
  [(r[2][1] - r[1][2]) * scale, (r[0][2] - r[2][0]) * scale, (r[1][0] - r[0][1]) * scale]

proc axesInBody(couple: Couple, who: Body, link: engine.BodyId): Matrix =
  ## Link's own three axes as columns, in its dancer's chest terms.
  let
    axes = axesOf(couple.chestStance(who))
    origin = asWorld(engine.pointOf(link, engine.initVector(0, 0, 0)))
  for j in 0..2:
    # Link's local axes are engine's; project's are turned from them (`asEngine`).
    let
      local = [engine.initVector(1, 0, 0), engine.initVector(0, 1, 0),
               engine.initVector(0, 0, 1)][j]
      world = asWorld(engine.pointOf(link, local)) - origin
      own: Vector = (dot(world, axes.right), dot(world, axes.fore), world.z)
    result[0][j] = own.x
    result[1][j] = own.y
    result[2][j] = own.z

proc poseVector*(couple: Couple): array[40, float] =
  ## Couple's pose read off engine in planner's own terms (`plan.Plan`): apart, sideways,
  ## two waists, then each arm's collarbone, shoulder, elbow and wrist.
  let
    one = axesOf(couple.stance[Body.One]).origin
    two = axesOf(couple.stance[Body.Two]).origin
  # Lead stands at origin facing along y in every planned turn, so plan's apart and
  # sideways are follow's place in those terms.
  result[0] = two.y - one.y
  result[1] = two.x - one.x
  for who in Body:
    result[2 + ord(who)] = float(engine.angleOf(couple.who[who].waist))
    for arm in Arm:
      let
        base = 4 + 9 * (2 * ord(who) + ord(arm))
        arm_rig = couple.who[who].arm[arm]
        protract = side(arm) * float(engine.angleOf(arm_rig.swing[Collar.Fore]))
        elevate = -side(arm) * float(engine.angleOf(arm_rig.swing[Collar.Up]))
        girdle_turn = (block:
          let
            (cu, su) = (cos(side(arm) * protract), sin(side(arm) * protract))
            (cf, sf) = (cos(-side(arm) * elevate), sin(-side(arm) * elevate))
            about_up: Matrix = [[cu, -su, 0.0], [su, cu, 0.0], [0.0, 0.0, 1.0]]
            about_fore: Matrix = [[cf, 0.0, sf], [0.0, 1.0, 0.0], [-sf, 0.0, cf]]
          times(about_up, about_fore))
        upper = axesInBody(couple, who, arm_rig.link[Limb.Upper])
        forearm = axesInBody(couple, who, arm_rig.link[Limb.Fore])
        hand = axesInBody(couple, who, arm_rig.link[Limb.Palm])
        shoulder_turn = times(transposed(girdle_turn), times(upper, transposed(MATRIX_REST)))
        wrist_turn = times(transposed(forearm), hand)
        shoulder_vector = turnVector(shoulder_turn)
        wrist_vector = turnVector(wrist_turn)
      result[base] = protract
      result[base + 1] = elevate
      for k in 0..2: result[base + 2 + k] = shoulder_vector[k]
      result[base + 5] = float(engine.angleOf(arm_rig.elbow))
      for k in 0..2: result[base + 6 + k] = wrist_vector[k]

type ArmPlacing* = object  ## Where one arm's five bodies stand, in world.
  root*, shoulder*, elbow*, wrist*: Vector
  collar*, girdle*, upper*, fore*, palm*: Matrix
    ## Each body's own three axes as columns, in world: what engine's turn of it carries
    ## its local x, y and z onto.

proc placeBodies*(couple: var Couple, chests: array[Body, Stance], arms: array[4, ArmPlacing]) =
  ## Stand couple where plan has them, every body at once, before anything is stepped:
  ## couple start where plan starts, rather than walking there from arms hanging.

  func turnOf(m: Matrix): engine.Quaternion =
    ## Read matrix of turn as engine's quaternion, its columns being frame's axes.
    quaternionOf(
      asEngine((m[0][0], m[1][0], m[2][0])),
      asEngine((m[0][1], m[1][1], m[2][1])),
      asEngine((m[0][2], m[1][2], m[2][2])),
    )

  for who in Body:
    let axes = axesOf(chests[who])
    engine.place(couple.who[who].chest, asPlace(axes.origin), standing(axes))
    for arm in Arm:
      let
        placing = arms[2 * ord(who) + ord(arm)]
        arm_rig = couple.who[who].arm[arm]
      engine.place(arm_rig.collar, asPlace(placing.root), turnOf(placing.collar))
      engine.place(arm_rig.girdle, asPlace(placing.shoulder), turnOf(placing.girdle))
      engine.place(arm_rig.link[Limb.Upper], asPlace(placing.shoulder), turnOf(placing.upper))
      engine.place(arm_rig.link[Limb.Fore], asPlace(placing.elbow), turnOf(placing.fore))
      engine.place(arm_rig.link[Limb.Palm], asPlace(placing.wrist), turnOf(placing.palm))

proc standAt*(
  couple: var Couple,
  stance: array[Body, Stance],
  chests: array[Body, Stance],
  arms: array[4, ArmPlacing],
) =
  ## Stand couple at one planned moment, nothing moving: hips at `stance`, chests and arms
  ## where plan places them (`walk.replay`).
  couple.stance = stance
  for who in Body:
    let axes = axesOf(stance[who])
    engine.place(couple.who[who].trunk, asPlace(axes.origin), standing(axes))
  couple.placeBodies(chests, arms)
  let still = asEngine((0.0, 0.0, 0.0))
  for who in Body:
    for body in [couple.who[who].trunk, couple.who[who].chest]:
      engine.setSpin(body, still)
      engine.setDrift(body, still)
    for arm in Arm:
      let arm_rig = couple.who[who].arm[arm]
      for body in [arm_rig.collar, arm_rig.girdle, arm_rig.link[Limb.Upper],
                   arm_rig.link[Limb.Fore], arm_rig.link[Limb.Palm]]:
        engine.setSpin(body, still)
        engine.setDrift(body, still)

proc advance*(couple: Couple, steps: int) =
  ## Run engine on, carrying hands toward their band all through.
  for _ in 1..steps:
    if not couple.is_steered: carry(couple)
    holdSwing(couple)
    if not couple.is_steered:
      elbowDown(couple)
      easeOff(couple)
    engine.step(couple.world, cfloat(1.0 / HERTZ), SUBSTEPS)

proc settle*(couple: var Couple) =
  ## Let first pose come to rest before anything is read off it, and read where
  ## each joined hand settled, which is where its rise starts.
  advance(couple, SETTLE)
  couple.rest_tip = @[]
  for link in couple.links:
    var tip: array[2, float]
    for k in 0..1:
      tip[k] = tipOf(couple, couple.who[link.ends[k].body].arm[link.ends[k].arm]).z
    couple.rest_tip.add tip

proc turn*(couple: var Couple, who: Body, by: float, steps: int) =
  ## Turn one dancer on their own spot, anticlockwise seen from above.
  ##   Stance is carried along step by step rather than set at end: swing is read
  ##     in dancer's own terms, so leaving stance behind for whole move judges
  ##     every arm against frame dancer has already left.
  let rate = by * 2.0 * PI * HERTZ / float(steps)
  engine.setSpin(couple.who[who].trunk, asEngine((0.0, 0.0, rate)))
  for _ in 1..steps:
    if not couple.is_steered: carry(couple)
    holdSwing(couple)
    if not couple.is_steered:
      elbowDown(couple)
      easeOff(couple)
    engine.step(couple.world, cfloat(1.0 / HERTZ), SUBSTEPS)
    couple.stance = turned(couple.stance, who, by / float(steps))
  engine.setSpin(couple.who[who].trunk, asEngine((0.0, 0.0, 0.0)))

proc turnStepping*(
  couple: var Couple,
  who: Body,
  by: float,
  mover: Body,
  step: Vector,
  steps: int,
  start: openArray[float] = [],
  finish: openArray[float] = [],
  hertz = 0.0,
) =
  ## Turn one dancer as `turn` does while `mover` steps by `step`, metres on floor, and
  ## where plans are given, steer from `start` to `finish` as turn goes.
  ##   Target moves with bodies, every tenth step, so joints are asked for pose that fits
  ##     where bodies are, and not for pose of moment's end while bodies are mid turn.
  ##   Who turns and who steps are two: plan stands lead still and steps follow toward
  ##     them, whichever of two turns.
  let
    rate = by * 2.0 * PI * HERTZ / float(steps)
    speed = step * (HERTZ / float(steps))
    is_blending = start.len == finish.len and finish.len > 0
  engine.setSpin(couple.who[who].trunk, asEngine((0.0, 0.0, rate)))
  engine.setDrift(couple.who[mover].trunk, asEngine(speed))
  for k in 1..steps:
    if is_blending and (k mod 10 == 1 or k == steps):
      var between = newSeq[float](finish.len)
      let share = float(k) / float(steps)
      for j in 0..<finish.len: between[j] = start[j] + (finish[j] - start[j]) * share
      couple.steer(between, hertz)
    if not couple.is_steered: carry(couple)
    holdSwing(couple)
    if not couple.is_steered:
      elbowDown(couple)
      easeOff(couple)
    engine.step(couple.world, cfloat(1.0 / HERTZ), SUBSTEPS)
    couple.stance = turned(couple.stance, who, by / float(steps))
    couple.stance[mover].centre.x += step.x / float(steps)
    couple.stance[mover].centre.y += step.y / float(steps)
  engine.setSpin(couple.who[who].trunk, asEngine((0.0, 0.0, 0.0)))
  engine.setDrift(couple.who[mover].trunk, asEngine((0.0, 0.0, 0.0)))

proc armPoseOf*(couple: Couple, who: Body, arm: Arm): ArmPose =
  ## Four points of one arm, joined or not.
  ##   Every arm, not only ones holding: arm hanging free is still arm, and
  ##     anything drawing couple has to draw it.
  let arm_rig = couple.who[who].arm[arm]
  ArmPose(
    shoulder: asWorld(engine.pointOf(arm_rig.link[Limb.Upper], engine.initVector(0, 0, 0))),
    elbow: asWorld(engine.pointOf(arm_rig.link[Limb.Fore], engine.initVector(0, 0, 0))),
    wrist: asWorld(engine.pointOf(arm_rig.link[Limb.Palm], engine.initVector(0, 0, 0))),
    grip: asWorld(
      engine.pointOf(arm_rig.link[Limb.Palm], engine.initVector(0, 0, cfloat(couple.rig.hand))),
    ),
  )

proc jointsOf*(
  couple: Couple, who: Body, arm: Arm
): tuple[swings: Joints, twist_angle, bend_angle, wrist_angle: float] =
  ## What one arm's joints read: three swings worked off its pose, and three
  ## engine states its own joints in.
  let arm_rig = couple.who[who].arm[arm]
  (joints(couple.chestStance(who), arm, couple.armPoseOf(who, arm)),
   float(engine.twistAngleOf(arm_rig.shoulder)), float(engine.angleOf(arm_rig.elbow)),
   float(engine.coneAngleOf(arm_rig.wrist)))

proc endsOf*(couple: Couple, shape: Shape): tuple[a, z: Vector] =
  ## Where one capsule's segment lies in world now.
  ##   Asked of engine rather than worked out from stance, so drawing cannot
  ##     drift from what is being simulated.
  (asWorld(engine.pointOf(shape.body, shape.a)), asWorld(engine.pointOf(shape.body, shape.z)))

proc poseOf*(couple: Couple, i: int): Pose =
  ## Where one connection's two arms lie, and what engine says their joints read.
  for k in 0..1:
    let
      hand = couple.links[i].ends[k]
      arm_rig = couple.who[hand.body].arm[hand.arm]
    result.arms[k] = couple.armPoseOf(hand.body, hand.arm)
    result.twist[k] = float(engine.twistAngleOf(arm_rig.shoulder))
    result.bend[k] = float(engine.angleOf(arm_rig.elbow))
    result.wrist[k] = float(engine.coneAngleOf(arm_rig.wrist))
  result.apart = float(engine.partedBy(couple.grip[i]))

func twistEnds*(rig: Rig, arm: Arm): tuple[lower, upper: float] =
  ## Humeral rotation's two ends for one arm.  Rig states them for right arm,
  ## in negative and out positive; left arm is same joint mirrored, so swapped.
  let twist_range = rig.range[Dof.Twist]
  if arm == Arm.Right: (twist_range.lower, twist_range.upper)
  else: (-twist_range.upper, -twist_range.lower)

proc deepest(couple: Couple, i: int): tuple[depth: float, met: Stop, end_index: int] =
  ## Deepest any link of any arm sits in anything, by engine's own manifolds,
  ## and whether that is body or arm; `end_index` names which of connection `i`'s two
  ## arms it is, where it is one of them.
  ##   Asked whatever hands are doing: hold that stands with arm through body
  ##     is not hold couple have, and before this only hands parting said so.
  ##   Every arm, held or free: free arm crushed between two torsos is arm
  ##     through body as much as held one, and asking only held arms let couple
  ##     stand with free arm inside partner and call it holding.
  result = (0.0, Stop.None, -1)
  # Every arm's three links, and every shoulder girdle, which squeezed between
  # two torsos is shoulder through body.
  var mine: seq[tuple[body: engine.BodyId, end_index: int]]
  for who in Body:
    for arm in Arm:
      var end_index = 0
      if i >= 0:
        for side in 0..1:
          if couple.links[i].ends[side] == (who, arm): end_index = side
      for limb in Limb:
        mine.add (couple.who[who].arm[arm].link[limb], end_index)
      mine.add (couple.who[who].arm[arm].girdle, end_index)
  # One loop for each axis of data: own link, contact, dancer, arm.
  # Split would hide its shape.
  for (me, end_index) in mine:
    # Room for every contact body has: asked with room for eight, forearm
    # touching nine things had its deepest dropped unseen, and two forearms
    # stood 22 mm through each other with nothing said.
    var seen = newSeq[engine.Touch](max(1, int(engine.touchRoom(me))))
    let touch_count = engine.touches(me, addr seen[0], cint(seen.len))
    for touch_index in 0..<touch_count:
      let other = (if engine.bodyOf(seen[touch_index].shape_id_a) == me:
                     engine.bodyOf(seen[touch_index].shape_id_b)
                   else: engine.bodyOf(seen[touch_index].shape_id_a))
      var is_trunk = false
      for who in Body:
        if other == couple.who[who].chest:
          is_trunk = true
        for arm in Arm:
          if other == couple.who[who].arm[arm].girdle:
            is_trunk = true
      let folds = cast[ptr UncheckedArray[engine.Manifold]](seen[touch_index].manifolds)
      for manifold_index in 0..<seen[touch_index].manifold_count:
        for point_index in 0..<folds[manifold_index].point_count:
          let depth = -float(folds[manifold_index].points[point_index].separation)
          if depth > result.depth:
            result = (depth, (if is_trunk: Stop.Through else: Stop.Arms), end_index)

proc metBy(couple: Couple, i: int): Stop =
  ## What one connection's arms are against, if anything, once hands have parted.
  let deep = deepest(couple, i)
  if deep.depth > 0.0: deep.met else: Stop.None

func freedom(joint_range: Range, value: float, as_both_ends: bool): float =
  ## How far value sits from nearer end of range, in that end's ease.
  ##   Not `margin`: margin counts stop with no ease as costing nothing to lean
  ##     on, so straight elbow reads infinitely comfortable.  Choosing where to
  ##     stand asks what arm is free to do, and straight elbow cannot straighten
  ##     further however painless it is, so both ends count here.  `limb.room`
  ##     draws same distinction, for same reason.
  let
    ease_lower = if joint_range.ease_lower > 0.0: joint_range.ease_lower
                 else: joint_range.ease_upper
    ease_upper = if joint_range.ease_upper > 0.0: joint_range.ease_upper
                 else: joint_range.ease_lower
  result = (joint_range.upper - value) / ease_upper
  if as_both_ends:
    result = min(result, (value - joint_range.lower) / ease_lower)

func roomAt*(couple: Couple, pose: Pose, i: int): float =
  ## How free this connection's tightest joint still is to move either way.
  ##   Read off engine's own joints rather than off pose again, and without
  ##     swing, which engine was never given.  Wrist's range is cone, so its
  ##     nought is middle of it and only its edge counts.
  result = Inf
  for k in 0..1:
    let
      twist_range = couple.rig.range[Dof.Twist]
      (lower, upper) = twistEnds(couple.rig, couple.links[i].ends[k].arm)
      turning = Range(
        lower: lower,
        upper: upper,
        ease_lower: twist_range.ease_lower,
        ease_upper: twist_range.ease_upper,
      )
    result = min(result, freedom(turning, pose.twist[k], true))
    result = min(result, freedom(couple.rig.range[Dof.Bend], pose.bend[k], true))
    result = min(result, freedom(couple.rig.range[Dof.Wrist], pose.wrist[k], false))

func restStance*(rig: Rig, apart: float, is_away = false): array[Body, Stance] =
  ## Where couple start.  Same-name pair is built Face-to-back: face to face its two
  ## connections lie through each other, so couple would not collect it there.
  result = facing(rig, apart)
  if is_away: result = turned(result, Body.Two, 0.5)

proc stoppedBy*(couple: Couple, i: int): tuple[why: Stop, end_index: int] =
  ## What stops this connection here, if anything does, and at which of its two arms.
  ##   Swing is asked first and whatever hands are doing, because engine was never
  ##     given it: nothing else in model holds extension or adduction, so asking
  ##     only once hands had parted left them unheld through every hold that stood.
  ##   Everything else engine itself enforces, so it can only be reached by hands
  ##     coming apart, and then engine's own joints say which gave.
  let pose = poseOf(couple, i)
  for k in 0..1:
    let
      hand = couple.links[i].ends[k]
      arm_joints = joints(couple.chestStance(hand.body), hand.arm, pose.arms[k])
    if margin(couple.rig.range[Dof.Extend], arm_joints.extend) < -GIVE or
       margin(couple.rig.range[Dof.Across], arm_joints.across) < -GIVE:
      return (Stop.Swing, k)
  let deep = deepest(couple, i)
  if deep.depth > THROUGH:
    return (deep.met, deep.end_index)
  if pose.apart <= PARTED:
    return (Stop.None, -1)
  for k in 0..1:
    let
      hand = couple.links[i].ends[k]
      (lower, upper) = twistEnds(couple.rig, hand.arm)
    if pose.twist[k] <= lower + AT_END or pose.twist[k] >= upper - AT_END:
      return (Stop.Twist, k)
    if pose.bend[k] >= couple.rig.range[Dof.Bend].upper - AT_END:
      return (Stop.Elbow, k)
    if pose.wrist[k] >= couple.rig.range[Dof.Wrist].upper - AT_END:
      return (Stop.Wrist, k)
  let met = metBy(couple, i)
  if met != Stop.None: (met, 0) else: (Stop.Reach, 0)

proc stopOf*(couple: Couple, i: int): Stop = stoppedBy(couple, i).why
  ## What stops this connection here, if anything does.

const
  FACING* = 0.05  ## Of way up (`up`), within which couple count as facing and
                 ## hands are asked into torso band: wound whole turn, couple
                 ## come back within float of face to face, not to it.
  OVER* = 0.05  ## Metres joined hand may sit over torso band's top facing: wound
                 ## arms press hands up against lift's forty newtons, and same-name
                 ## chain come round to face to face sat at 1.37 to 1.39 m against
                 ## 1.35, mid torso by any reading and hold at no other height.
  SAG* = 0.03  ## Metres joined hand may sit under its band's edge, once
                 ## risen, lift being spring against comfort and not wall.

proc gives*(couple: Couple): Stop =
  ## What stops couple's pose here, if anything does: first connection that
  ## gives, any arm through body or arm, or joined hands that never reached
  ## their band once couple are no longer face to face.
  ##   Couple with nothing held were never asked: two free frames stood Face-to-back
  ##     chest to back with follow's arm crushed between two torsos, and read as
  ##     holding since no connection could give.
  ##   Hands under their band are hold at some other height, not this one:
  ##     before this, still whose hands never rose read as holding, and card
  ##     asked over crown was answered by hold at hip.  `SAG` is lift's own
  ##     slack.
  for i in 0..<couple.links.len:
    let why = couple.stopOf(i)
    if why != Stop.None: return why
  let deep = deepest(couple, -1)
  if deep.depth > THROUGH: return deep.met
  let is_facing = couple.band == Band.Crown and couple.up <= FACING
  if couple.height >= 1.0 or is_facing:
    let band = couple.bandNow
    for link in couple.links:
      for hand in link.ends:
        let z = tipOf(couple, couple.who[hand.body].arm[hand.arm]).z
        if z < band.lower - SAG: return Stop.Reach
        # Facing, hands over crown are hold at some other height too: A09 stood
        # facing with every hand at 1.90 m and read as holding.
        if is_facing and z > band.upper + OVER: return Stop.Reach
  Stop.None



#[ Pose Strain ]#

proc collarOf*(couple: Couple, who: Body, arm: Arm): array[Collar, float] =
  ## What one collarbone's two hinges read, radians, in rig's stated sense:
  ## protraction and elevation positive.
  for k in Collar:
    result[k] = collarSign(arm, k) * float(engine.angleOf(couple.who[who].arm[arm].swing[k]))

proc girdleOff*(couple: Couple, who: Body, arm: Arm): float =
  ## How far one shoulder joint sits from where tape puts it on chest, metres.
  distance(couple.armPoseOf(who, arm).shoulder, shoulder(couple.rig, couple.chestStance(who), arm))

proc strainOf*(couple: Couple): Strain =
  ## How near couple's pose is to any end, and where: worst of every joint of
  ## every arm held or free, each waist, and each collarbone's two swings.
  ##   Read where laws read: swing off pose in body's own terms, twist, bend and
  ##     wrist off engine's own joints, twist's ends mirrored for left arm.
  ##   Every arm, not held ones alone: free arm shoved to its twist's end by
  ##     partner's trunk is strain couple feel, and asking held arms alone let
  ##     couple stand with free arm at its end and read as at ease.
  const names: array[Dof, string] = ["extend", "across", "twist", "bend", "wrist"]
  result = Strain(most: 0.0, what: "")
  for who in Body:
    let waist = strainOf(couple.rig.waist, float(engine.angleOf(couple.who[who].waist)))
    if waist > result.most:
      result = Strain(most: waist, whose: (who, Arm.Left), what: "waist")
    for arm in Arm:
      let
        (swings, twist_angle, bend_angle, wrist_angle) = couple.jointsOf(who, arm)
        (lower, upper) = twistEnds(couple.rig, arm)
        turning = Range(
          lower: lower,
          upper: upper,
          ease_lower: couple.rig.range[Dof.Twist].ease_lower,
          ease_upper: couple.rig.range[Dof.Twist].ease_upper,
        )
      for (dof, joint_range, value) in [(Dof.Extend, couple.rig.range[Dof.Extend], swings.extend),
                          (Dof.Across, couple.rig.range[Dof.Across], swings.across),
                          (Dof.Twist, turning, twist_angle),
                          (Dof.Bend, couple.rig.range[Dof.Bend], bend_angle),
                          (Dof.Wrist, couple.rig.range[Dof.Wrist], wrist_angle)]:
        let got = strainOf(joint_range, value)
        if got > result.most:
          result = Strain(most: got, whose: (who, arm), what: names[dof])
      for k in Collar:
        let got = strainOf(
          collarRange(couple.rig, arm, k),
          float(engine.angleOf(couple.who[who].arm[arm].swing[k])),
        )
        if got > result.most:
          result = Strain(most: got, whose: (who, arm), what: "collar " & $k)
