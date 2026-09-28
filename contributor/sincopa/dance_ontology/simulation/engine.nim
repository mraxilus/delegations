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
    raise newException(IOError,
      "Engine's library did not build, so nothing here can link; got:\n" & made)

{.passC: "-I" & INCLUDE.}
{.passL: LIBRARY & " -lm -lpthread".}

{.push header: "box3d/box3d.h".}
type
  WorldId* {.importc: "b3WorldId", bycopy.} = object
  BodyId* {.importc: "b3BodyId", bycopy.} = object
    index1*: cint
    world0*, generation*: uint16
  ShapeId* {.importc: "b3ShapeId", bycopy.} = object
    index1*: cint
    world0*, generation*: uint16
  JointId* {.importc: "b3JointId", bycopy.} = object

  Vector* {.importc: "b3Vec3", bycopy.} = object ## Direction or offset, in metres.
    x*, y*, z*: cfloat
  Position* {.importc: "b3Pos", bycopy.} = object ## Place, which engine keeps wider.
    x*, y*, z*: cdouble
  Quaternion* {.importc: "b3Quat", bycopy.} = object
    vector* {.importc: "v".}: Vector
    scalar* {.importc: "s".}: cfloat
  Frame* {.importc: "b3Transform", bycopy.} = object ## Joint's own axes on one body.
    origin* {.importc: "p".}: Vector
    rotation* {.importc: "q".}: Quaternion

  WorldDefinition* {.importc: "b3WorldDef", bycopy.} = object
    gravity* {.importc.}: Vector
    contactHertz* {.importc.}: cfloat ## How stiffly overlap is pushed apart.
    enableSleep* {.importc.}: bool
    enableContinuous* {.importc.}: bool
  BodyDefinition* {.importc: "b3BodyDef", bycopy.} = object
    kind* {.importc: "type".}: cint
    position* {.importc.}: Position
    rotation* {.importc.}: Quaternion
    linearDamping* {.importc.}: cfloat
    angularDamping* {.importc.}: cfloat
    gravityScale* {.importc.}: cfloat
    enableSleep* {.importc.}: bool
  Material* {.importc: "b3SurfaceMaterial", bycopy.} = object
    friction* {.importc.}: cfloat
  ShapeDefinition* {.importc: "b3ShapeDef", bycopy.} = object
    density* {.importc.}: cfloat
    material* {.importc: "baseMaterial".}: Material
    filter* {.importc.}: Filter
    enableContactEvents* {.importc.}: bool
  Filter* {.importc: "b3Filter", bycopy.} = object
    ## Which shapes meet which.  Negative `groupIndex` shared by two shapes
    ## keeps them apart whatever bits say: how neighbouring links of one arm
    ## are stopped from colliding at joint they share.
    categoryBits* {.importc.}: uint64
    maskBits* {.importc.}: uint64
    groupIndex* {.importc.}: cint
  Capsule* {.importc: "b3Capsule", bycopy.} = object ## Segment with radius round it.
    center1*, center2*: Vector
    radius*: cfloat
  JointDefinition* {.importc: "b3JointDef", bycopy.} = object
    bodyIdA* {.importc.}: BodyId
    bodyIdB* {.importc.}: BodyId
    localFrameA* {.importc.}: Frame
    localFrameB* {.importc.}: Frame
    constraintHertz* {.importc.}: cfloat ## How stiffly joint holds its bodies together.
    constraintDampingRatio* {.importc.}: cfloat
    collideConnected* {.importc.}: bool
  BallDefinition* {.importc: "b3SphericalJointDef", bycopy.} = object
    base* {.importc.}: JointDefinition
    enableSpring* {.importc.}: bool
    hertz* {.importc.}: cfloat
    dampingRatio* {.importc.}: cfloat
    targetRotation* {.importc.}: Quaternion
    enableConeLimit* {.importc.}: bool
    coneAngle* {.importc.}: cfloat
    enableTwistLimit* {.importc.}: bool
    lowerTwistAngle* {.importc.}: cfloat
    upperTwistAngle* {.importc.}: cfloat
  HingeDefinition* {.importc: "b3RevoluteJointDef", bycopy.} = object
    ## Joint with one axis: elbow.
    base* {.importc.}: JointDefinition
    targetAngle* {.importc.}: cfloat
    enableSpring* {.importc.}: bool
    hertz* {.importc.}: cfloat
    dampingRatio* {.importc.}: cfloat
    enableLimit* {.importc.}: bool
    lowerAngle* {.importc.}: cfloat
    upperAngle* {.importc.}: cfloat
  TouchPoint* {.importc: "b3ManifoldPoint", bycopy.} = object
    ## One contact point: how deep, negative where shapes overlap.
    separation* {.importc.}: cfloat
  Manifold* {.importc: "b3Manifold", bycopy.} = object
    ## Contact points of one touching pair, one to four of them.
    points* {.importc.}: array[4, TouchPoint]
    pointCount* {.importc.}: cint
  WeldDefinition* {.importc: "b3WeldJointDef", bycopy.} = object
    ## Joint holding two bodies as one, or as one on spring: shoulder girdle.
    base* {.importc.}: JointDefinition
    linearHertz* {.importc.}: cfloat ## Nought is rigid.
    angularHertz* {.importc.}: cfloat
    linearDampingRatio* {.importc.}: cfloat
    angularDampingRatio* {.importc.}: cfloat
  DistanceDefinition* {.importc: "b3DistanceJointDef", bycopy.} = object
    ## Joint holding two points within some distance of each other: girdle's rope.
    base* {.importc.}: JointDefinition
    length* {.importc.}: cfloat
    enableSpring* {.importc.}: bool ## Off, joint is rigid rod and limit is ignored.
    hertz* {.importc.}: cfloat ## Nought with spring on is rope: free to its limit.
    dampingRatio* {.importc.}: cfloat
    enableLimit* {.importc.}: bool
    minLength* {.importc.}: cfloat
    maxLength* {.importc.}: cfloat
  Touch* {.importc: "b3ContactData", bycopy.} = object
    ## One pair of shapes engine found touching.
    shapeIdA* {.importc.}: ShapeId
    shapeIdB* {.importc.}: ShapeId
    manifolds* {.importc.}: ptr Manifold ## Engine's own, valid until next step.
    manifoldCount* {.importc.}: cint


# Engine's entry points, each bound on one line to its C name.
proc defaultWorld*(): WorldDefinition {.importc: "b3DefaultWorldDef".}
proc defaultBody*(): BodyDefinition {.importc: "b3DefaultBodyDef".}
proc defaultShape*(): ShapeDefinition {.importc: "b3DefaultShapeDef".}
proc defaultBall*(): BallDefinition {.importc: "b3DefaultSphericalJointDef".}
proc createWorld*(definition: ptr WorldDefinition): WorldId {.importc: "b3CreateWorld".}
proc createBody*(world: WorldId; definition: ptr BodyDefinition): BodyId {.importc: "b3CreateBody".}
proc createCapsule*(body: BodyId; definition: ptr ShapeDefinition;
                    capsule: ptr Capsule): ShapeId {.importc: "b3CreateCapsuleShape".}
  ## Hang capsule on body; engine copies both definitions.
proc createBall*(world: WorldId;
                 definition: ptr BallDefinition): JointId {.importc: "b3CreateSphericalJoint".}
proc step*(world: WorldId; seconds: cfloat; substeps: cint) {.importc: "b3World_Step".}
proc positionOf*(body: BodyId): Position {.importc: "b3Body_GetPosition".}
proc pointOf*(body: BodyId; local: Vector): Position {.importc: "b3Body_GetWorldPoint".}
proc setSpin*(body: BodyId; spin: Vector) {.importc: "b3Body_SetAngularVelocity".}
proc defaultHinge*(): HingeDefinition {.importc: "b3DefaultRevoluteJointDef".}
proc createHinge*(world: WorldId;
                  definition: ptr HingeDefinition): JointId {.importc: "b3CreateRevoluteJoint".}
proc defaultWeld*(): WeldDefinition {.importc: "b3DefaultWeldJointDef".}
proc defaultDistance*(): DistanceDefinition {.importc: "b3DefaultDistanceJointDef".}
proc createDistance*(world: WorldId;
    definition: ptr DistanceDefinition): JointId {.importc: "b3CreateDistanceJoint".}
proc createWeld*(world: WorldId;
                 definition: ptr WeldDefinition): JointId {.importc: "b3CreateWeldJoint".}
proc angleOf*(joint: JointId): cfloat {.importc: "b3RevoluteJoint_GetAngle".}
proc destroyWorld*(world: WorldId) {.importc: "b3DestroyWorld".}
proc turnOf*(body: BodyId): Quaternion {.importc: "b3Body_GetRotation".}
proc place*(body: BodyId; at: Position; turn: Quaternion) {.importc: "b3Body_SetTransform".}
proc setDrift*(body: BodyId; drift: Vector) {.importc: "b3Body_SetLinearVelocity".}
proc driftOf*(body: BodyId): Vector {.importc: "b3Body_GetLinearVelocity".}
proc bodyOf*(shape: ShapeId): BodyId {.importc: "b3Shape_GetBody".}
proc touchRoom*(body: BodyId): cint {.importc: "b3Body_GetContactCapacity".}
  ## How many contacts body may have now: room `touches` needs to report all.
proc touches*(body: BodyId; into: ptr Touch;
              room: cint): cint {.importc: "b3Body_GetContactData".}
  ## Copy up to `room` of body's contacts into `into`, and count them.
proc partedBy*(joint: JointId): cfloat {.importc: "b3Joint_GetLinearSeparation".}
proc coneAngleOf*(joint: JointId): cfloat {.importc: "b3SphericalJoint_GetConeAngle".}
proc twistAngleOf*(joint: JointId): cfloat {.importc: "b3SphericalJoint_GetTwistAngle".}
proc push*(body: BodyId; force: Vector; wake: bool) {.importc: "b3Body_ApplyForceToCenter".}
proc twistBy*(body: BodyId; torque: Vector; wake: bool) {.importc: "b3Body_ApplyTorque".}
{.pop.}

const
  BODY_STATIC* = cint(0)    ## No mass, no motion, moved by hand alone.
  BODY_KINEMATIC* = cint(1) ## No mass, motion set by caller; what turns dancer.
  BODY_DYNAMIC* = cint(2)   ## Mass from its shapes, motion from forces; what arms are.
  IDENTITY* = Quaternion(vector: Vector(x: 0, y: 0, z: 0), scalar: 1.0)

func initVector*(x, y, z: float): Vector =
  ## Build engine's vector from plain numbers.
  Vector(x: cfloat(x), y: cfloat(y), z: cfloat(z))

func at*(position: Position): tuple[x, y, z: float] =
  ## Read place as plain numbers, which is what everything above this works in.
  (float(position.x), float(position.y), float(position.z))
