## Carry typed reference objects into library's dense multivector and back.
##   Suites compare both sides through these images: reference result embedded must equal
##   library result on embedded operands. Extraction under `-d:testing` asserts every
##   component outside object's slots is zero, so library result of wrong grade fails
##   loudly rather than silently losing components.
##   Slots follow library's `Basis` enum for this algebra, listed in `reference/rigid3.nim`
##   header table; algebra without typed reference exports scalar images alone.
##
##   Cost: images are built component by component through library's accessor, i.e. one
##     store per slot plus zero fill of rest; suites only, never on timed path.

{.experimental: "strictFuncs".}

import pga

when IS_RIGID and DIMENSIONS == 4:
  import ./reference/rigid3

  export rigid3


func only(m: Multivector; slots: set[Basis]) =
  ## Assert, under `-d:testing`, that components outside slots are zero within tolerance.
  when defined(testing):
    for b in Basis:
      if b notin slots:
        doAssert abs(m[b]) <= TOLERANCE_ABS,
          "Component outside object's slots; got `" & $m & "` at `" & $b & "`."


func toMultivector*(s: float): Multivector =
  ## Embed scalar as s𝟏.
  result[Basis.scalar] = s

func toScalar*(m: Multivector): float =
  ## Extract scalar s𝟏; asserts nothing else present under `-d:testing`.
  m.only({Basis.scalar})
  m[Basis.scalar]


when IS_RIGID and DIMENSIONS == 4:
  func toMultivector*(t: Antiscalar): Multivector =
    ## Embed antiscalar as t𝟙.
    result[Basis.scalarAnti] = float(t)

  func toAntiscalar*(m: Multivector): Antiscalar =
    ## Extract antiscalar t𝟙.
    m.only({Basis.scalarAnti})
    Antiscalar(m[Basis.scalarAnti])

  func toMultivector*(p: Point): Multivector =
    ## Embed point into e₁ e₂ e₃ e₄.
    result[Basis.E1] = p.x
    result[Basis.E2] = p.y
    result[Basis.E3] = p.z
    result[Basis.E4] = p.w

  func toPoint*(m: Multivector): Point =
    ## Extract point from e₁ e₂ e₃ e₄.
    m.only({Basis.E1, Basis.E2, Basis.E3, Basis.E4})
    Point(x: m[Basis.E1], y: m[Basis.E2], z: m[Basis.E3], w: m[Basis.E4])

  func toMultivector*(l: Line): Multivector =
    ## Embed line into e₄₁ e₄₂ e₄₃ and e₂₃ e₃₁ e₁₂.
    result[Basis.E41] = l.v.x
    result[Basis.E42] = l.v.y
    result[Basis.E43] = l.v.z
    result[Basis.E23] = l.m.x
    result[Basis.E31] = l.m.y
    result[Basis.E12] = l.m.z

  func toLine*(m: Multivector): Line =
    ## Extract line from grade-2 slots.
    m.only({Basis.E41, Basis.E42, Basis.E43, Basis.E23, Basis.E31, Basis.E12})
    Line(
      v: Vec3(x: m[Basis.E41], y: m[Basis.E42], z: m[Basis.E43]),
      m: Vec3(x: m[Basis.E23], y: m[Basis.E31], z: m[Basis.E12]),
    )

  func toMultivector*(g: Plane): Multivector =
    ## Embed plane into e₄₂₃ e₄₃₁ e₄₁₂ e₃₂₁.
    result[Basis.E423] = g.x
    result[Basis.E431] = g.y
    result[Basis.E412] = g.z
    result[Basis.E321] = g.w

  func toPlane*(m: Multivector): Plane =
    ## Extract plane from grade-3 slots.
    m.only({Basis.E423, Basis.E431, Basis.E412, Basis.E321})
    Plane(x: m[Basis.E423], y: m[Basis.E431], z: m[Basis.E412], w: m[Basis.E321])

  func toMultivector*(q: Motor): Multivector =
    ## Embed motor into grade-2 slots, 𝟙 and 𝟏.
    result[Basis.E41] = q.v.x
    result[Basis.E42] = q.v.y
    result[Basis.E43] = q.v.z
    result[Basis.E23] = q.m.x
    result[Basis.E31] = q.m.y
    result[Basis.E12] = q.m.z
    result[Basis.scalarAnti] = q.vw
    result[Basis.scalar] = q.mw

  func toMotor*(m: Multivector): Motor =
    ## Extract motor from even-grade slots.
    m.only({
      Basis.E41, Basis.E42, Basis.E43, Basis.E23, Basis.E31, Basis.E12, Basis.scalarAnti,
      Basis.scalar,
    })
    Motor(
      v: Vec3(x: m[Basis.E41], y: m[Basis.E42], z: m[Basis.E43]),
      m: Vec3(x: m[Basis.E23], y: m[Basis.E31], z: m[Basis.E12]),
      vw: m[Basis.scalarAnti],
      mw: m[Basis.scalar],
    )
