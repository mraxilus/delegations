## Name operand kinds every measurand speaks in, and sizes every measurement is scaled by.
##   Kinds are typed objects Lengyel's reference carries for one algebra, plus `General`
##   for library's full multivector and `Scalar` for plain float. Algebra decides which
##   kinds exist, so each branch of `when` holds one complete enum: enum cannot hold `when`.
##
##   |-------|-------------------------------------------------------------------|
##   | Name  | Typed kinds beside `General` and `Scalar`, by module of reference |
##   |-------|-------------------------------------------------------------------|
##   | rga3d | Point, Line, Motor; `reference/rigid2.nim`                        |
##   | rga4d | Point, Line, Plane, Motor, Flector; `reference/rigid3.nim`        |
##   | cga4d | PointRound, Dipole, Circle; `reference/conformal2.nim`            |
##   | cga5d | PointRound, Dipole, Circle, Sphere, PointFlat, LineFlat,          |
##   |       | PlaneFlat; `reference/conformal3.nim`                             |
##   |-------|-------------------------------------------------------------------|
##
##   Each module's header table spells components of its kinds against library's basis.
##   `General` is any multivector, 2^n floats; `Scalar` is float.
##   Cost: algebras of other dimension carry only `General` and `Scalar` measurands, since
##     Lengyel's typed reference exists for 2D and 3D Euclidean space alone here; scaling
##     sweep measures those dense against dense.

{.experimental: "strictFuncs".}

import pga


when IS_RIGID and DIMENSIONS == 4:
  type Kind* {.pure.} = enum  ## Define operand kinds of 4D rigid algebra.
    General, Scalar, Point, Line, Plane, Motor, Flector
elif IS_CONFORMAL and DIMENSIONS == 5:
  type Kind* {.pure.} = enum  ## Define operand kinds of 5D conformal algebra.
    General, Scalar, PointRound, Dipole, Circle, Sphere, PointFlat, LineFlat, PlaneFlat
elif IS_RIGID and DIMENSIONS == 3:
  type Kind* {.pure.} = enum  ## Define operand kinds of 3D rigid algebra.
    General, Scalar, Point, Line, Motor
elif IS_CONFORMAL and DIMENSIONS == 4:
  type Kind* {.pure.} = enum  ## Define operand kinds of 4D conformal algebra.
    General, Scalar, PointRound, Dipole, Circle
else:
  type Kind* {.pure.} = enum
    ## Define operand kinds of algebra without typed reference: dense and scalar only.
    General, Scalar


const
  OBJECTS* {.define: "pga_benchmark.objects".} = (when defined(testing): 64 else: 1024)
    ## Objects per sample pool; small under `-d:testing` so suites stay quick.
  ROUNDS* {.define: "pga_benchmark.rounds".} = (when defined(testing): 3 else: 40)
    ## Timed rounds per measurand; median and minimum over rounds are measurements reported.
  SIZE_MULTIVECTOR* = sizeof(Multivector)
    ## Bytes one dense multivector occupies, i.e. 8 × 2^DIMENSIONS.

static:
  doAssert OBJECTS >= 2, "Pool should hold at least two objects; got `" & $OBJECTS & "`."
  doAssert ROUNDS >= 1, "Measurand should time at least one round; got `" & $ROUNDS & "`."
