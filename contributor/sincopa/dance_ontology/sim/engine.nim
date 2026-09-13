## Bind rigid body engine this project turns couples with: Box3D, by Box2D's author.
##
##   Not C of this project's own, and so argues for nothing under CONTRIBUTOR.md's
##     gated-language rule: engine's own headers are C and every line here is Nim.
##     Source is cloned at pinned commit by `tools/build.nim engine`, never vendored
##     (Article XI.3), and archived into `bin/libbox3d.a` which this links.
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
  LIB = HERE / "bin" / "libbox3d.a"
  INCLUDE = HERE / "deps" / "box3d" / "include"

static:
  # Verb is cheap where library already stands, so this costs one process, not build.
  let made = staticExec("cd " & HERE & " && nim r --hints:off tools/build.nim engine")
  if not fileExists(LIB):
    raise newException(IOError,
      "Engine's library did not build, so nothing here can link; got:\n" & made)

{.passC: "-I" & INCLUDE.}
{.passL: LIB & " -lm -lpthread".}

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

  Vec* {.importc: "b3Vec3", bycopy.} = object ## Direction or offset, in metres.
    x*, y*, z*: cfloat
  Pos* {.importc: "b3Pos", bycopy.} = object ## Place, which engine keeps wider.
    x*, y*, z*: cdouble
  Quat* {.importc: "b3Quat", bycopy.} = object
    v*: Vec
    s*: cfloat
  Frame* {.importc: "b3Transform", bycopy.} = object ## Joint's own axes on one body.
    p*: Vec
    q*: Quat

  WorldDef* {.importc: "b3WorldDef", bycopy.} = object
    gravity* {.importc.}: Vec
    contactHertz* {.importc.}: cfloat ## How stiffly overlap is pushed apart.
    enableSleep* {.importc.}: bool
    enableContinuous* {.importc.}: bool
  BodyDef* {.importc: "b3BodyDef", bycopy.} = object
    kind* {.importc: "type".}: cint
    position* {.importc.}: Pos
    rotation* {.importc.}: Quat
    linearDamping* {.importc.}: cfloat
    angularDamping* {.importc.}: cfloat
    gravityScale* {.importc.}: cfloat
    enableSleep* {.importc.}: bool
  ShapeDef* {.importc: "b3ShapeDef", bycopy.} = object
    density* {.importc.}: cfloat
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
    center1*, center2*: Vec
    radius*: cfloat
  JointDef* {.importc: "b3JointDef", bycopy.} = object
    bodyIdA* {.importc.}: BodyId
    bodyIdB* {.importc.}: BodyId
    localFrameA* {.importc.}: Frame
    localFrameB* {.importc.}: Frame
    constraintHertz* {.importc.}: cfloat ## How stiffly joint holds its bodies together.
    constraintDampingRatio* {.importc.}: cfloat
    collideConnected* {.importc.}: bool
  BallDef* {.importc: "b3SphericalJointDef", bycopy.} = object
    base* {.importc.}: JointDef
    enableSpring* {.importc.}: bool
    hertz* {.importc.}: cfloat
    dampingRatio* {.importc.}: cfloat
    targetRotation* {.importc.}: Quat
    enableConeLimit* {.importc.}: bool
    coneAngle* {.importc.}: cfloat
    enableTwistLimit* {.importc.}: bool
    lowerTwistAngle* {.importc.}: cfloat
    upperTwistAngle* {.importc.}: cfloat
  HingeDef* {.importc: "b3RevoluteJointDef", bycopy.} = object
    ## Joint with one axis: elbow.
    base* {.importc.}: JointDef
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
  Touch* {.importc: "b3ContactData", bycopy.} = object
    ## One pair of shapes engine found touching.
    shapeIdA* {.importc.}: ShapeId
    shapeIdB* {.importc.}: ShapeId
    manifolds* {.importc.}: ptr Manifold ## Engine's own, valid until next step.
    manifoldCount* {.importc.}: cint

proc defaultWorld*(): WorldDef {.importc: "b3DefaultWorldDef".}
proc defaultBody*(): BodyDef {.importc: "b3DefaultBodyDef".}
proc defaultShape*(): ShapeDef {.importc: "b3DefaultShapeDef".}
proc defaultBall*(): BallDef {.importc: "b3DefaultSphericalJointDef".}
proc createWorld*(def: ptr WorldDef): WorldId {.importc: "b3CreateWorld".}
proc createBody*(w: WorldId; def: ptr BodyDef): BodyId {.importc: "b3CreateBody".}
proc createCapsule*(b: BodyId; def: ptr ShapeDef;
                    cap: ptr Capsule): ShapeId {.importc: "b3CreateCapsuleShape".}
proc createBall*(w: WorldId; def: ptr BallDef): JointId {.importc: "b3CreateSphericalJoint".}
proc step*(w: WorldId; seconds: cfloat; substeps: cint) {.importc: "b3World_Step".}
proc positionOf*(b: BodyId): Pos {.importc: "b3Body_GetPosition".}
proc pointOf*(b: BodyId; local: Vec): Pos {.importc: "b3Body_GetWorldPoint".}
proc setSpin*(b: BodyId; spin: Vec) {.importc: "b3Body_SetAngularVelocity".}
proc defaultHinge*(): HingeDef {.importc: "b3DefaultRevoluteJointDef".}
proc createHinge*(w: WorldId; def: ptr HingeDef): JointId {.importc: "b3CreateRevoluteJoint".}
proc angleOf*(j: JointId): cfloat {.importc: "b3RevoluteJoint_GetAngle".}
proc destroyWorld*(w: WorldId) {.importc: "b3DestroyWorld".}
proc turnOf*(b: BodyId): Quat {.importc: "b3Body_GetRotation".}
proc place*(b: BodyId; at: Pos; turn: Quat) {.importc: "b3Body_SetTransform".}
proc setDrift*(b: BodyId; drift: Vec) {.importc: "b3Body_SetLinearVelocity".}
proc driftOf*(b: BodyId): Vec {.importc: "b3Body_GetLinearVelocity".}
proc bodyOf*(s: ShapeId): BodyId {.importc: "b3Shape_GetBody".}
proc touches*(b: BodyId; into: ptr Touch;
              room: cint): cint {.importc: "b3Body_GetContactData".}
proc partedBy*(j: JointId): cfloat {.importc: "b3Joint_GetLinearSeparation".}
proc coneAngleOf*(j: JointId): cfloat {.importc: "b3SphericalJoint_GetConeAngle".}
proc twistAngleOf*(j: JointId): cfloat {.importc: "b3SphericalJoint_GetTwistAngle".}
proc push*(b: BodyId; force: Vec; wake: bool) {.importc: "b3Body_ApplyForceToCenter".}
proc twistBy*(b: BodyId; torque: Vec; wake: bool) {.importc: "b3Body_ApplyTorque".}
{.pop.}

const
  Static* = 0.cint   ## No mass, no motion, moved by hand alone.
  Kinematic* = 1.cint ## No mass, motion set by caller; what turns dancer.
  Dynamic* = 2.cint  ## Mass from its shapes, motion from forces; what arms are.
  IDENTITY* = Quat(v: Vec(x: 0, y: 0, z: 0), s: 1.0)

func vec*(x, y, z: float): Vec =
  Vec(x: x.cfloat, y: y.cfloat, z: z.cfloat)

func at*(p: Pos): tuple[x, y, z: float] =
  ## Read place as plain numbers, which is what everything above this works in.
  (p.x.float, p.y.float, p.z.float)
