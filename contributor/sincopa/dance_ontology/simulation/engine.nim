## Bind rigid body engine this project turns couples with: Box3D, by Box2D's author.
##
##   Not C of this project's own, and so argues for nothing under CONTRIBUTOR.md's
##     gated-language rule: engine's own headers are C and every line here is Nim.
##     Source is cloned at pinned commit by `tools/build.nim engine`, never vendored
##     (Article XI.3), and archived into `binaries/libbox3d.a` which this links.
##   Why engine at all: pose search this project had proposed poses and checked
##     them, with no notion of motion between two of them, so arms could not slide
##     along one another as couple's do. It wound chain to one crossing and no
##     further, where reference Architect signed off draws two at whole turn and
##     three at turn and half. Engine integrates motion with contacts, so sliding is
##     what it does rather than what it cannot express (`PROVENANCE.md`).
##   Engine stands Y up and this project stands Z up. Translation is deliberately not
##     made here: this module is binding and nothing more, so what calls it says which
##     way is up and one place holds that decision.
##   Library is built before anything links it, by same verb reader would run by hand,
##     so suite that drives engine drives its build too (Article IX.6).

{.experimental: "strictFuncs".}

import std/os

const
  HERE = currentSourcePath().parentDir.parentDir
    ## Project directory, which every path below is relative to.
  LIBRARY = HERE / "binaries" / "libbox3d.a"
  INCLUDE = HERE / "dependencies" / "box3d" / "include"

static:
  # Verb is cheap where library already stands, so this costs one process, not build.
  let made = staticExec("cd " & HERE & " && nim r --hints:off tools/build.nim engine")
  if not fileExists(LIBRARY):
    raise newException(
      IOError,
      "Engine's library did not build, so nothing here can link; got:\n" & made,
    )

{.passC: "-I" & INCLUDE.}
{.passL: LIBRARY & " -lm -lpthread".}

{.push header: "box3d/box3d.h".}
type
  WorldId* {.bycopy, importc: "b3WorldId".} = object
  BodyId* {.bycopy, importc: "b3BodyId".} = object
    index1*: cint
    world0*, generation*: uint16
  ShapeId* {.bycopy, importc: "b3ShapeId".} = object
    index1*: cint
    world0*, generation*: uint16
  JointId* {.bycopy, importc: "b3JointId".} = object

  Vector* {.bycopy, importc: "b3Vec3".} = object  ## Direction or offset, in metres.
    x*, y*, z*: cfloat
  Position* {.bycopy, importc: "b3Pos".} = object  ## Place, which engine keeps wider.
    x*, y*, z*: cdouble
  Quaternion* {.bycopy, importc: "b3Quat".} = object
    vector* {.importc: "v".}: Vector
    scalar* {.importc: "s".}: cfloat
  Frame* {.bycopy, importc: "b3Transform".} = object  ## Joint's own axes on one body.
    origin* {.importc: "p".}: Vector
    rotation* {.importc: "q".}: Quaternion

  WorldDefinition* {.bycopy, importc: "b3WorldDef".} = object
    gravity* {.importc.}: Vector
    contact_hertz* {.importc: "contactHertz".}: cfloat  ## How stiffly overlap is pushed apart.
    should_sleep* {.importc: "enableSleep".}: bool
    should_collide_continuously* {.importc: "enableContinuous".}: bool
  BodyDefinition* {.bycopy, importc: "b3BodyDef".} = object
    kind* {.importc: "type".}: cint
    position* {.importc.}: Position
    rotation* {.importc.}: Quaternion
    linear_damping* {.importc: "linearDamping".}: cfloat
    angular_damping* {.importc: "angularDamping".}: cfloat
    gravity_scale* {.importc: "gravityScale".}: cfloat
    should_sleep* {.importc: "enableSleep".}: bool
  Material* {.bycopy, importc: "b3SurfaceMaterial".} = object
    friction* {.importc.}: cfloat
  ShapeDefinition* {.bycopy, importc: "b3ShapeDef".} = object
    density* {.importc.}: cfloat
    material* {.importc: "baseMaterial".}: Material
    filter* {.importc.}: Filter
    should_report_contacts* {.importc: "enableContactEvents".}: bool
  Filter* {.bycopy, importc: "b3Filter".} = object
    ## Which shapes meet which.  Negative `group_index` shared by two shapes
    ## keeps them apart whatever bits say: how neighbouring links of one arm
    ## are stopped from colliding at joint they share.
    category_bits* {.importc: "categoryBits".}: uint64
    mask_bits* {.importc: "maskBits".}: uint64
    group_index* {.importc: "groupIndex".}: cint
  Capsule* {.bycopy, importc: "b3Capsule".} = object  ## Segment with radius round it.
    center1*, center2*: Vector
    radius*: cfloat
  JointDefinition* {.bycopy, importc: "b3JointDef".} = object
    body_id_a* {.importc: "bodyIdA".}: BodyId
    body_id_b* {.importc: "bodyIdB".}: BodyId
    local_frame_a* {.importc: "localFrameA".}: Frame
    local_frame_b* {.importc: "localFrameB".}: Frame
    constraint_hertz* {.importc: "constraintHertz".}: cfloat
      ## How stiffly joint holds its bodies together.
    constraint_damping_ratio* {.importc: "constraintDampingRatio".}: cfloat
    should_collide_connected* {.importc: "collideConnected".}: bool
  BallDefinition* {.bycopy, importc: "b3SphericalJointDef".} = object
    base* {.importc.}: JointDefinition
    should_spring* {.importc: "enableSpring".}: bool
    hertz* {.importc.}: cfloat
    damping_ratio* {.importc: "dampingRatio".}: cfloat
    target_rotation* {.importc: "targetRotation".}: Quaternion
    should_limit_cone* {.importc: "enableConeLimit".}: bool
    cone_angle* {.importc: "coneAngle".}: cfloat
    should_limit_twist* {.importc: "enableTwistLimit".}: bool
    lower_twist_angle* {.importc: "lowerTwistAngle".}: cfloat
    upper_twist_angle* {.importc: "upperTwistAngle".}: cfloat
  HingeDefinition* {.bycopy, importc: "b3RevoluteJointDef".} = object
    ## Joint with one axis: elbow.
    base* {.importc.}: JointDefinition
    target_angle* {.importc: "targetAngle".}: cfloat
    should_spring* {.importc: "enableSpring".}: bool
    hertz* {.importc.}: cfloat
    damping_ratio* {.importc: "dampingRatio".}: cfloat
    should_limit* {.importc: "enableLimit".}: bool
    lower_angle* {.importc: "lowerAngle".}: cfloat
    upper_angle* {.importc: "upperAngle".}: cfloat
  TouchPoint* {.bycopy, importc: "b3ManifoldPoint".} = object
    ## One contact point: how deep, negative where shapes overlap.
    separation* {.importc.}: cfloat
  Manifold* {.bycopy, importc: "b3Manifold".} = object
    ## Contact points of one touching pair, one to four of them.
    points* {.importc.}: array[4, TouchPoint]
    point_count* {.importc: "pointCount".}: cint
  WeldDefinition* {.bycopy, importc: "b3WeldJointDef".} = object
    ## Joint holding two bodies as one, or as one on spring: shoulder girdle.
    base* {.importc.}: JointDefinition
    linear_hertz* {.importc: "linearHertz".}: cfloat  ## Nought is rigid.
    angular_hertz* {.importc: "angularHertz".}: cfloat
    linear_damping_ratio* {.importc: "linearDampingRatio".}: cfloat
    angular_damping_ratio* {.importc: "angularDampingRatio".}: cfloat
  DistanceDefinition* {.bycopy, importc: "b3DistanceJointDef".} = object
    ## Joint holding two points within some distance of each other: girdle's rope.
    base* {.importc.}: JointDefinition
    length* {.importc.}: cfloat
    should_spring* {.importc: "enableSpring".}: bool
      ## Off, joint is rigid rod and limit is ignored.
    hertz* {.importc.}: cfloat  ## Nought with spring on is rope: free to its limit.
    damping_ratio* {.importc: "dampingRatio".}: cfloat
    should_limit* {.importc: "enableLimit".}: bool
    min_length* {.importc: "minLength".}: cfloat
    max_length* {.importc: "maxLength".}: cfloat
  Touch* {.bycopy, importc: "b3ContactData".} = object  ## One pair of shapes engine found touching.
    shape_id_a* {.importc: "shapeIdA".}: ShapeId
    shape_id_b* {.importc: "shapeIdB".}: ShapeId
    manifolds* {.importc.}: ptr Manifold  ## Engine's own, valid until next step.
    manifold_count* {.importc: "manifoldCount".}: cint


# Engine's entry points, each bound on one line to its C name.
proc defaultWorld*(): WorldDefinition {.importc: "b3DefaultWorldDef".}
proc defaultBody*(): BodyDefinition {.importc: "b3DefaultBodyDef".}
proc defaultShape*(): ShapeDefinition {.importc: "b3DefaultShapeDef".}
proc defaultBall*(): BallDefinition {.importc: "b3DefaultSphericalJointDef".}
proc createWorld*(definition: ptr WorldDefinition): WorldId {.importc: "b3CreateWorld".}
proc createBody*(world: WorldId, definition: ptr BodyDefinition): BodyId {.importc: "b3CreateBody".}
proc createCapsule*(
  body: BodyId, definition: ptr ShapeDefinition, capsule: ptr Capsule
): ShapeId {.importc: "b3CreateCapsuleShape".}
  ## Hang capsule on body; engine copies both definitions.
proc createBall*(
  world: WorldId, definition: ptr BallDefinition
): JointId {.importc: "b3CreateSphericalJoint".}
proc step*(world: WorldId, seconds: cfloat, substeps: cint) {.importc: "b3World_Step".}
proc positionOf*(body: BodyId): Position {.importc: "b3Body_GetPosition".}
proc pointOf*(body: BodyId, local: Vector): Position {.importc: "b3Body_GetWorldPoint".}
proc setSpin*(body: BodyId, spin: Vector) {.importc: "b3Body_SetAngularVelocity".}
proc defaultHinge*(): HingeDefinition {.importc: "b3DefaultRevoluteJointDef".}
proc createHinge*(
  world: WorldId, definition: ptr HingeDefinition
): JointId {.importc: "b3CreateRevoluteJoint".}
proc defaultWeld*(): WeldDefinition {.importc: "b3DefaultWeldJointDef".}
proc defaultDistance*(): DistanceDefinition {.importc: "b3DefaultDistanceJointDef".}
proc createDistance*(
  world: WorldId, definition: ptr DistanceDefinition
): JointId {.importc: "b3CreateDistanceJoint".}
proc createWeld*(
  world: WorldId, definition: ptr WeldDefinition
): JointId {.importc: "b3CreateWeldJoint".}
proc angleOf*(joint: JointId): cfloat {.importc: "b3RevoluteJoint_GetAngle".}
proc destroyWorld*(world: WorldId) {.importc: "b3DestroyWorld".}
proc turnOf*(body: BodyId): Quaternion {.importc: "b3Body_GetRotation".}
proc place*(body: BodyId, at: Position, turn: Quaternion) {.importc: "b3Body_SetTransform".}
proc setDrift*(body: BodyId, drift: Vector) {.importc: "b3Body_SetLinearVelocity".}
proc driftOf*(body: BodyId): Vector {.importc: "b3Body_GetLinearVelocity".}
proc bodyOf*(shape: ShapeId): BodyId {.importc: "b3Shape_GetBody".}
proc touchRoom*(body: BodyId): cint {.importc: "b3Body_GetContactCapacity".}
  ## How many contacts body may have now: room `touches` needs to report all.
proc touches*(body: BodyId, into: ptr Touch, room: cint): cint {.importc: "b3Body_GetContactData".}
  ## Copy up to `room` of body's contacts into `into`, and count them.
proc partedBy*(joint: JointId): cfloat {.importc: "b3Joint_GetLinearSeparation".}
proc coneAngleOf*(joint: JointId): cfloat {.importc: "b3SphericalJoint_GetConeAngle".}
proc twistAngleOf*(joint: JointId): cfloat {.importc: "b3SphericalJoint_GetTwistAngle".}
proc push*(body: BodyId, force: Vector, should_wake: bool) {.importc: "b3Body_ApplyForceToCenter".}
proc twistBy*(body: BodyId, torque: Vector, should_wake: bool) {.importc: "b3Body_ApplyTorque".}
proc aimBall*(joint: JointId, target: Quaternion) {.importc: "b3SphericalJoint_SetTargetRotation".}
proc stiffenBall*(joint: JointId, hertz: cfloat) {.importc: "b3SphericalJoint_SetSpringHertz".}
proc aimHinge*(joint: JointId, target: cfloat) {.importc: "b3RevoluteJoint_SetTargetAngle".}
proc stiffenHinge*(joint: JointId, hertz: cfloat) {.importc: "b3RevoluteJoint_SetSpringHertz".}
proc reshape*(shape: ShapeId, capsule: ptr Capsule) {.importc: "b3Shape_SetCapsule".}
proc setFrameA*(joint: JointId, frame: Frame) {.importc: "b3Joint_SetLocalFrameA".}
proc setFrameB*(joint: JointId, frame: Frame) {.importc: "b3Joint_SetLocalFrameB".}
proc limitCone*(joint: JointId, should_limit: bool) {.importc: "b3SphericalJoint_EnableConeLimit".}
proc coneBall*(joint: JointId, angle: cfloat) {.importc: "b3SphericalJoint_SetConeLimit".}
proc limitTwist*(
  joint: JointId, should_limit: bool
) {.importc: "b3SphericalJoint_EnableTwistLimit".}
proc twistBall*(joint: JointId; lower, upper: cfloat) {.importc: "b3SphericalJoint_SetTwistLimits".}
{.pop.}

const
  BODY_STATIC* = cint(0)  ## No mass, no motion, moved by hand alone.
  BODY_KINEMATIC* = cint(1)  ## No mass, motion set by caller; what turns dancer.
  BODY_DYNAMIC* = cint(2)  ## Mass from its shapes, motion from forces; what arms are.
  IDENTITY* = Quaternion(vector: Vector(x: 0, y: 0, z: 0), scalar: 1.0)

func initVector*(x, y, z: float): Vector =
  ## Build engine's vector from plain numbers.
  Vector(x: cfloat(x), y: cfloat(y), z: cfloat(z))

func at*(position: Position): tuple[x, y, z: float] =
  ## Read place as plain numbers, which is what everything above this works in.
  (float(position.x), float(position.y), float(position.z))
