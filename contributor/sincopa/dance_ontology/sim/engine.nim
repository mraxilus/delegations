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
  ShapeId* {.importc: "b3ShapeId", bycopy.} = object
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
    enableSleep* {.importc.}: bool
    enableContinuous* {.importc.}: bool
  BodyDef* {.importc: "b3BodyDef", bycopy.} = object
    kind* {.importc: "type".}: cint
    position* {.importc.}: Pos
    rotation* {.importc.}: Quat
  ShapeDef* {.importc: "b3ShapeDef", bycopy.} = object
    density* {.importc.}: cfloat
  Capsule* {.importc: "b3Capsule", bycopy.} = object ## Segment with radius round it.
    center1*, center2*: Vec
    radius*: cfloat
  JointDef* {.importc: "b3JointDef", bycopy.} = object
    bodyIdA* {.importc.}: BodyId
    bodyIdB* {.importc.}: BodyId
    localFrameA* {.importc.}: Frame
    localFrameB* {.importc.}: Frame
    collideConnected* {.importc.}: bool
  BallDef* {.importc: "b3SphericalJointDef", bycopy.} = object
    base* {.importc.}: JointDef

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
