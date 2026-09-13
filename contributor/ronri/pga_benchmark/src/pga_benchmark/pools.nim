## Fill sample pools once, seeded, so every suite and probe reads same objects.
##   Dense pool holds Gaussian components on every basis; graded pools hold one grade
##   each, for operations that read grade; typed pools hold objects built as geometry
##   builds them (lines as joins of points, planes as joins of line and point, motors as
##   translation composed with rotation), beside their dense images.
##   Pools are module globals sized by `OBJECTS`, filled by one proc, walked by `lent`;
##   nothing on timed path allocates or reseeds.
##
##   Cost: memory is `OBJECTS` × every pool, i.e. few megabytes at 6D; taken once.

{.experimental: "strictFuncs".}

import std/[math, options, random]

import pga

import ./[bridge, kinds]


var
  POOL_GENERAL*: array[OBJECTS, Multivector]
    ## Dense multivectors, every component Gaussian.
  POOL_GRADED*: array[0 .. DIMENSIONS, array[OBJECTS, Multivector]]
    ## Dense multivectors holding one grade each.
  POOL_SCALAR*: array[OBJECTS, float]
    ## Scalars, Gaussian.

when IS_RIGID and DIMENSIONS == 4:
  var
    POOL_POINT*: array[OBJECTS, Point]
      ## Points with weight near one.
    POOL_LINE*: array[OBJECTS, Line]
      ## Lines joining two points.
    POOL_PLANE*: array[OBJECTS, Plane]
      ## Planes joining line and point.
    POOL_MOTOR*: array[OBJECTS, Motor]
      ## Unit motors, translation composed with rotation.
    POOL_POINT_MV*: array[OBJECTS, Multivector]
      ## Dense images of `POOL_POINT`.
    POOL_LINE_MV*: array[OBJECTS, Multivector]
      ## Dense images of `POOL_LINE`.
    POOL_PLANE_MV*: array[OBJECTS, Multivector]
      ## Dense images of `POOL_PLANE`.
    POOL_MOTOR_MV*: array[OBJECTS, Multivector]
      ## Dense images of `POOL_MOTOR`.


func toUpperAscii(s: string): string {.compileTime.} =
  ## Upper-case ASCII letters; local so runtime imports no string library.
  for c in s:
    result.add (if c in 'a' .. 'z': char(ord(c) - 32) else: c)


func libraryPoolName*(kind: Kind; grade: Option[int]): string {.compileTime.} =
  ## Name pool feeding library side of probe: dense image, graded dense, or scalar.
  case kind
  of Kind.General: (if grade.isSome: "POOL_GRADED[" & $grade.get & "]" else: "POOL_GENERAL")
  of Kind.Scalar: "POOL_SCALAR"
  else: "POOL_" & toUpperAscii($kind) & "_MV"


func referencePoolName*(kind: Kind): string {.compileTime.} =
  ## Name pool feeding reference side of probe: typed object, or same as library side.
  case kind
  of Kind.General: "POOL_GENERAL"
  of Kind.Scalar: "POOL_SCALAR"
  else: "POOL_" & toUpperAscii($kind)



#[ Filling ]#

proc randMultivector(grade = none(int)): Multivector =
  ## Draw dense multivector, every component Gaussian, or one grade alone.
  for b in Basis:
    if grade.isNone or int(b.grade) == grade.get:
      result[b] = gauss(0.0, 1.0)


when IS_RIGID and DIMENSIONS == 4:
  proc randPoint(): Point =
    ## Draw point with Gaussian position and weight near one.
    Point(x: gauss(0.0, 1.0), y: gauss(0.0, 1.0), z: gauss(0.0, 1.0), w: gauss(1.0, 0.25))

  proc randUnitAxis(): Vec3 =
    ## Draw unit vector, Gaussian direction normalized.
    let v = Vec3(x: gauss(0.0, 1.0), y: gauss(0.0, 1.0), z: gauss(0.0, 1.0))
    v * (1.0 / sqrt(dot(v, v)))

  proc randMotor(): Motor =
    ## Draw unit motor: translation by Gaussian vector after rotation by Gaussian angle.
    let t = Vec3(x: gauss(0.0, 1.0), y: gauss(0.0, 1.0), z: gauss(0.0, 1.0))
    wedgeDotAnti(translator(t), rotor(randUnitAxis(), gauss(0.0, 1.5)))


proc fillPools*(seed = 0) =
  ## Fill every pool from seed; deterministic, so suites and probes agree across runs.
  randomize(seed)
  for i in 0 ..< OBJECTS:
    POOL_GENERAL[i] = randMultivector()
    for g in 0 .. DIMENSIONS:
      POOL_GRADED[g][i] = randMultivector(some(g))
    POOL_SCALAR[i] = gauss(0.0, 1.0)
  when IS_RIGID and DIMENSIONS == 4:
    for i in 0 ..< OBJECTS:
      POOL_POINT[i] = randPoint()
      POOL_LINE[i] = wedge(randPoint(), randPoint())
      POOL_PLANE[i] = wedge(wedge(randPoint(), randPoint()), randPoint())
      POOL_MOTOR[i] = randMotor()
      POOL_POINT_MV[i] = POOL_POINT[i].toMultivector
      POOL_LINE_MV[i] = POOL_LINE[i].toMultivector
      POOL_PLANE_MV[i] = POOL_PLANE[i].toMultivector
      POOL_MOTOR_MV[i] = POOL_MOTOR[i].toMultivector
