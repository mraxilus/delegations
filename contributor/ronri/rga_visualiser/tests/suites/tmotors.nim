## Run `Motors` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Motors":
  test "the algebra the module claims is the algebra the library has":
    # Header table of `motors` names which half of bivector turns and which slides.
    #   Read both halves back off library, so moved pin cannot leave table lying.
    for basis in [Basis.E41, Basis.E42, Basis.E43]:
      check wedgeDotAnti(initElement(basis, 1.0), initElement(basis, 1.0)) =~ -1.0.e1234
    for basis in [Basis.E23, Basis.E31, Basis.E12]:
      check wedgeDotAnti(initElement(basis, 1.0), initElement(basis, 1.0)) =~ Multivector()
    # Pin trap that header warns of: under base product two halves swap roles outright.
    #   Sandwich built there turns about line at infinity rather than about line meant,
    #   and both products compile, so only reading catches it without this.
    for basis in [Basis.E23, Basis.E31, Basis.E12]:
      check wedgeDot(initElement(basis, 1.0), initElement(basis, 1.0)) =~
        initElement(Basis.scalar, -1.0)
    for basis in [Basis.E41, Basis.E42, Basis.E43]:
      check wedgeDot(initElement(basis, 1.0), initElement(basis, 1.0)) =~ Multivector()

  test "a turn about the z axis agrees with the classical rotation, poles included":
    # Reference is plain trigonometry, which is what `turnAbout` reproduces.
    #   Half turn is on list deliberately: stance of orbit angles clamped 0.02 rad short
    #   of pole, and rotor has no pole to clamp.
    for radians in [0.0, 0.25*PI, 0.5*PI, PI, 1.5*PI, -0.75*PI]:
      let turned = turnAbout(1.0.e43, radians)
      check turned.isSome
      let moved = position(toMultivector(Position(x: 1, y: 0, z: 0)).carried(turned.get))
      check moved.isSome
      check moved.get =~ Position(x: cos(radians), y: sin(radians), z: 0.0)

  test "a turn about a line off the origin carries the origin about that line":
    # Rigid motion rather than turn about origin: line's moment carries offset.
    #   Axis runs along z through (1, 0, 0), so quarter turn takes origin to (1, -1, 0).
    let axis = toMultivector(Position(x: 1, y: 0, z: 0)) ∧
      toMultivector(Position(x: 1, y: 0, z: 1))
    let turned = turnAbout(axis, 0.5*PI)
    check turned.isSome
    check position(toMultivector(ORIGIN).carried(turned.get)).get =~
      Position(x: 1, y: -1, z: 0)

  test "a horizon line names no axis, so it turns nothing":
    # `unitize` returns line of no weight unchanged rather than refuse, so guard is here.
    for basis in [Basis.E23, Basis.E31, Basis.E12]:
      check turnAbout(initElement(basis, 1.0), 0.5*PI).isNone
    check turnAbout(Multivector(), 0.5*PI).isNone

  test "a slide motor carries every point by one offset, and costs two terms":
    # Slide's bivector antisquares to zero, so series stops at two terms and `exp` is
    #   exact there. Same expression as turn: no branch, so no branch to get wrong.
    for i in 0 ..< COUNT_GENERAL:
      let offset = PLACES[i]
      let slide = exp((-0.5*offset.x).e23 + (-0.5*offset.y).e31 + (-0.5*offset.z).e12)
      check slide[Basis.scalar] =~ 0.0
      for basis in [Basis.E41, Basis.E42, Basis.E43]: check slide[basis] =~ 0.0
      check slide[Basis.E1234] =~ 1.0
      for j in 0 ..< COUNT_GENERAL:
        let moved = position(POINTS[j].carried(slide))
        check moved.isSome
        check moved.get =~ Position(
          x: PLACES[j].x + offset.x, y: PLACES[j].y + offset.y, z: PLACES[j].z + offset.z,
        )

  test "every motor is unit, and the exponential and the logarithm invert each other":
    # Screws drawn from seeded pool, one for each sample, so failure reproduces by name.
    #   Angle sweeps whole turn across pool, and every seventh sample takes angle far
    #   below `ANGLE_SERIES`, so both arms of `scalesOf` are walked.
    #   Round trip is exact in coefficients here because `turnAbout` holds every angle
    #   inside half turn, which is where `log` reads motor back unnegated.
    for i in 0 ..< SAMPLES:
      let radians =
        if i mod 7 == 0: 1.0e-9 + 1.0e-6*float(i)
        else: -PI + TAU*float(i)/float(SAMPLES)
      let turn = turnAbout(LINES[i], 0.5*radians)
      check turn.isSome
      let offset = PLACES[i]
      let slide = exp((-0.5*offset.x).e23 + (-0.5*offset.y).e31 + (-0.5*offset.z).e12)
      let screw = wedgeDotAnti(turn.get, slide)
      check normWeight(screw)[Basis.scalarAnti] =~ 1.0
      check exp(log(screw)) =~ screw

  test "the identity moves nothing and a motor undoes itself":
    # Antireverse is inverse of unit motor, which is what lets `carried` stand alone.
    for i in 0 ..< COUNT_GENERAL:
      let turn = turnAbout(LINES[i], 0.3 + 0.1*float(i)).get
      for m in [POINTS[i], LINES[i], PLANES[i]]:
        check m.carried(MOTOR_IDENTITY) =~ m
        check m.carried(turn).carried(reverseAnti(turn)) =~ m
        # Grade survives, so one sandwich serves point, line and plane alike.
        check grade(m.carried(turn)) == grade(m)

  test "a motor is rigid: it keeps every distance and every weight":
    for i in 0 ..< COUNT_GENERAL:
      let turn = turnAbout(LINES[i], 0.7 + 0.2*float(i)).get
      for j in 0 ..< COUNT_GENERAL:
        let k = (j + 1) mod COUNT_GENERAL
        check distanceBetween(POINTS[j].carried(turn), POINTS[k].carried(turn)) =~
          distanceBetween(POINTS[j], POINTS[k])
        # Weight says place or direction, and rigid motion never turns one into other.
        check POINTS[j].carried(turn)[Basis.E4] =~ POINTS[j][Basis.E4]
        check toMultivector(Direction(x: 1, y: 0, z: 0)).carried(turn)[Basis.E4] =~ 0.0

  test "motors compose right to left, as the sandwich does":
    # `m.carried(a).carried(b)` is `m.carried(b ⟇ a)`: inner motor runs first.
    #   Order is worth pinning because both spellings compile and one is silently wrong.
    for i in 0 ..< COUNT_GENERAL:
      let first = turnAbout(LINES[i], 0.4 + 0.1*float(i)).get
      let second = turnAbout(LINES[(i + 1) mod COUNT_GENERAL], -0.9).get
      for m in [POINTS[i], LINES[i], PLANES[i]]:
        check m.carried(first).carried(second) =~ m.carried(wedgeDotAnti(second, first))
