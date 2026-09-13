## Name operand kinds every measurand speaks in, and sizes every measurement is scaled by.
##   Kinds are typed objects Lengyel's reference carries for one algebra, plus `General`
##   for library's full multivector and `Scalar` for plain float. Algebra decides which
##   kinds exist, so two complete enums stand under `when`: enum cannot hold `when` inside.
##
##   |------------|-----------------------------------|--------------------------------------|
##   | Kind       | Rigid, 4D (3D Euclidean)          | Conformal, 5D (3D Euclidean)         |
##   |------------|-----------------------------------|--------------------------------------|
##   | General    | any multivector, 16 floats        | any multivector, 32 floats           |
##   | Scalar     | float                             | float                                |
##   | Point      | p = pˣe₁ + pʸe₂ + pᶻe₃ + pʷe₄    | --                                   |
##   | Line       | l = lᵛ(e₄₁ e₄₂ e₄₃) + lᵐ(e₂₃ e₃₁ e₁₂) | --                             |
##   | Plane      | g = (e₄₂₃ e₄₃₁ e₄₁₂) + gʷe₃₂₁    | --                                   |
##   | Motor      | Q = Qᵛ + Qᵐ + Qᵛʷ𝟙 + Qᵐʷ𝟏         | --                                   |
##   | Flector    | F = p + g                         | --                                   |
##   | RoundPoint | --                                | `a` = x y z (e₁ e₂ e₃) + w e₄ + u e₅ |
##   | Dipole     | --                                | d = dᵛ dᵐ + dᵖ(e₁₅ e₂₅ e₃₅ e₄₅)      |
##   | Circle     | --                                | c = cᵍ(e₄₂₃ e₄₃₁ e₄₁₂ e₃₂₁) + cᵛ + cᵐ |
##   | Sphere     | --                                | s = sᵘe₁₂₃₄ + (e₄₂₃₅ e₄₃₁₅ e₄₁₂₅ e₃₂₁₅) |
##   | FlatPoint  | --                                | p = (e₁₅ e₂₅ e₃₅ e₄₅)                |
##   | FlatLine   | --                                | l = (e₄₁₅ e₄₂₅ e₄₃₅ e₂₃₅ e₃₁₅ e₁₂₅)  |
##   | FlatPlane  | --                                | g = (e₄₂₃₅ e₄₃₁₅ e₄₁₂₅ e₃₂₁₅)        |
##   |------------|-----------------------------------|--------------------------------------|
##
##   Cost: rigid algebras of other dimension carry only `General` and `Scalar` measurands, since
##     Lengyel's typed reference exists for 3D Euclidean space alone here; scaling sweep
##     measures those dense against dense.

{.experimental: "strictFuncs".}

import pga


when IS_RIGID and DIMENSIONS == 4:
  type Kind* {.pure.} = enum
    ## Define operand kinds of 4D rigid algebra.
    General, Scalar, Point, Line, Plane, Motor, Flector
elif IS_CONFORMAL and DIMENSIONS == 5:
  type Kind* {.pure.} = enum
    ## Define operand kinds of 5D conformal algebra.
    General, Scalar, RoundPoint, Dipole, Circle, Sphere, FlatPoint, FlatLine, FlatPlane
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
