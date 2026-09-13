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

when IS_CONFORMAL and DIMENSIONS == 5:
  import ./reference/conformal3

  export conformal3


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


when (IS_RIGID and DIMENSIONS == 4) or (IS_CONFORMAL and DIMENSIONS == 5):
  func toMultivector*(t: Antiscalar): Multivector =
    ## Embed antiscalar as t𝟙.
    result[Basis.scalarAnti] = float(t)

  func toAntiscalar*(m: Multivector): Antiscalar =
    ## Extract antiscalar t𝟙.
    m.only({Basis.scalarAnti})
    Antiscalar(m[Basis.scalarAnti])


when IS_RIGID and DIMENSIONS == 4:
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


when IS_CONFORMAL and DIMENSIONS == 5:
  func toMultivector*(a: RoundPoint): Multivector =
    ## Embed round point into e₁ e₂ e₃ e₄ e₅.
    result[Basis.E1] = a.x
    result[Basis.E2] = a.y
    result[Basis.E3] = a.z
    result[Basis.E4] = a.w
    result[Basis.E5] = a.u

  func toRoundPoint*(m: Multivector): RoundPoint =
    ## Extract round point from grade-1 slots.
    m.only({Basis.E1, Basis.E2, Basis.E3, Basis.E4, Basis.E5})
    RoundPoint(x: m[Basis.E1], y: m[Basis.E2], z: m[Basis.E3], w: m[Basis.E4], u: m[Basis.E5])

  func toMultivector*(p: FlatPoint): Multivector =
    ## Embed flat point into e₁₅ e₂₅ e₃₅ e₄₅.
    result[Basis.E15] = p.x
    result[Basis.E25] = p.y
    result[Basis.E35] = p.z
    result[Basis.E45] = p.w

  func toMultivector*(d: Dipole): Multivector =
    ## Embed dipole into grade-2 slots.
    result[Basis.E41] = d.v.x
    result[Basis.E42] = d.v.y
    result[Basis.E43] = d.v.z
    result[Basis.E23] = d.m.x
    result[Basis.E31] = d.m.y
    result[Basis.E12] = d.m.z
    result[Basis.E15] = d.p.x
    result[Basis.E25] = d.p.y
    result[Basis.E35] = d.p.z
    result[Basis.E45] = d.p.w

  func toDipole*(m: Multivector): Dipole =
    ## Extract dipole from grade-2 slots.
    m.only({
      Basis.E41, Basis.E42, Basis.E43, Basis.E23, Basis.E31, Basis.E12, Basis.E15, Basis.E25,
      Basis.E35, Basis.E45,
    })
    Dipole(
      v: Vec3(x: m[Basis.E41], y: m[Basis.E42], z: m[Basis.E43]),
      m: Vec3(x: m[Basis.E23], y: m[Basis.E31], z: m[Basis.E12]),
      p: FlatPoint(x: m[Basis.E15], y: m[Basis.E25], z: m[Basis.E35], w: m[Basis.E45]),
    )

  func toMultivector*(l: FlatLine): Multivector =
    ## Embed flat line into e₄₁₅ e₄₂₅ e₄₃₅ and e₂₃₅ e₃₁₅ e₁₂₅.
    result[Basis.E415] = l.v.x
    result[Basis.E425] = l.v.y
    result[Basis.E435] = l.v.z
    result[Basis.E235] = l.m.x
    result[Basis.E315] = l.m.y
    result[Basis.E125] = l.m.z

  func toMultivector*(c: Circle): Multivector =
    ## Embed circle into grade-3 slots.
    result[Basis.E423] = c.g.x
    result[Basis.E431] = c.g.y
    result[Basis.E412] = c.g.z
    result[Basis.E321] = c.g.w
    result[Basis.E415] = c.v.x
    result[Basis.E425] = c.v.y
    result[Basis.E435] = c.v.z
    result[Basis.E235] = c.m.x
    result[Basis.E315] = c.m.y
    result[Basis.E125] = c.m.z

  func toCircle*(m: Multivector): Circle =
    ## Extract circle from grade-3 slots.
    m.only({
      Basis.E423, Basis.E431, Basis.E412, Basis.E321, Basis.E415, Basis.E425, Basis.E435,
      Basis.E235, Basis.E315, Basis.E125,
    })
    Circle(
      g: CarrierPlane(x: m[Basis.E423], y: m[Basis.E431], z: m[Basis.E412], w: m[Basis.E321]),
      v: Vec3(x: m[Basis.E415], y: m[Basis.E425], z: m[Basis.E435]),
      m: Vec3(x: m[Basis.E235], y: m[Basis.E315], z: m[Basis.E125]),
    )

  func toMultivector*(g: FlatPlane): Multivector =
    ## Embed flat plane into e₄₂₃₅ e₄₃₁₅ e₄₁₂₅ e₃₂₁₅.
    result[Basis.E4235] = g.x
    result[Basis.E4315] = g.y
    result[Basis.E4125] = g.z
    result[Basis.E3215] = g.w

  func toMultivector*(s: Sphere): Multivector =
    ## Embed sphere into grade-4 slots.
    result[Basis.E1234] = s.u
    result[Basis.E4235] = s.x
    result[Basis.E4315] = s.y
    result[Basis.E4125] = s.z
    result[Basis.E3215] = s.w

  func toSphere*(m: Multivector): Sphere =
    ## Extract sphere from grade-4 slots.
    m.only({Basis.E1234, Basis.E4235, Basis.E4315, Basis.E4125, Basis.E3215})
    Sphere(
      u: m[Basis.E1234], x: m[Basis.E4235], y: m[Basis.E4315], z: m[Basis.E4125],
      w: m[Basis.E3215],
    )
