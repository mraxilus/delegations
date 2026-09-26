## Run `Objects` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Objects":
  test "position inverts toMultivector":
    for place in PLACES:
      let recovered = position(toMultivector(place))
      check recovered.isSome
      check recovered.get =~ place


  test "every lift writes the coefficients its sum of blades names":
    # Lifts write one result rather than sum one blade for each term (see `boundary`).
    #   Sum is reference they are held to: point, horizon point, motor and slide.
    for i in 0 ..< SAMPLES:
      let (p, q) = (PLACES[i], PLACES[(i + 1) mod SAMPLES])
      check toMultivector(p) =~ p.x.e1 + p.y.e2 + p.z.e3 + 1.0.e4
      let d = Direction(x: q.x, y: q.y, z: q.z)
      check toMultivector(d) =~ d.x.e1 + d.y.e2 + d.z.e3
      let motor = Motor(
        turn_x: p.x, turn_y: p.y, turn_z: p.z, slide_x: q.x, slide_y: q.y, slide_z: q.z,
        scalar: 0.1*float(i), antiscalar: 1.0 + 0.01*float(i),
      )
      check toMultivector(motor) =~ motor.turn_x.e41 + motor.turn_y.e42 + motor.turn_z.e43 +
        motor.slide_x.e23 + motor.slide_y.e31 + motor.slide_z.e12 +
        motor.antiscalar.e1234 + initElement(Basis.scalar, motor.scalar)
      let offset = toMultivector(d)
      check motorSliding(offset) =~ (-0.5*offset[Basis.E1]).e23 +
        (-0.5*offset[Basis.E2]).e31 + (-0.5*offset[Basis.E3]).e12 + 1.0.e1234


  test "the inner product of two directions is their classical dot product":
    # `innerOf` is how camera reads sides and cosines; classical form is reference.
    for i in 0 ..< SAMPLES:
      let (p, q) = (PLACES[i], PLACES[(i + 1) mod SAMPLES])
      let (d, e) = (Direction(x: p.x, y: p.y, z: p.z), Direction(x: q.x, y: q.y, z: q.z))
      check innerOf(toMultivector(d), toMultivector(e)) =~ d.x*e.x + d.y*e.y + d.z*e.z


  test "position ignores scale of homogeneous point":
    for point in POINTS:
      for scale in [-7.5, -1.0, 0.25, 3.0]:
        let (plain, scaled) = (position(point), position(scale * point))
        check plain.isSome and scaled.isSome
        check plain.get =~ scaled.get


  test "shape follows grade":
    for i in 0 ..< SAMPLES:
      check kindOf(POINTS[i]) == some(Kind.Point)
      check kindOf(LINES[i]) == some(Kind.Line)
      check kindOf(PLANES[i]) == some(Kind.Plane)
    check kindOf(1.0 + POINTS[0]).isNone


  test "support lies on its object":
    for i in 0 ..< SAMPLES:
      for geometry in [LINES[i], PLANES[i]]:
        let anchor = positionAnchor(geometry)
        check anchor.isSome
        check toMultivector(anchor.get) ∧ geometry =~ 0


  test "support of line is perpendicular to its direction":
    for line in LINES:
      let (anchor, axis) = (positionAnchor(line), direction(line))
      check anchor.isSome and axis.isSome
      check dot(anchor.get - ORIGIN, axis.get) =~ 0


  test "direction of line is unit and lies at its horizon":
    for line in LINES:
      let axis = direction(line)
      check axis.isSome
      check norm(axis.get) =~ 1.0
      check toMultivector(axis.get) ∧ line =~ 0


  test "frame of plane is orthonormal, inside plane, and normal to its normal":
    for plane in PLANES:
      let axes = frame(plane)
      check axes.isSome
      let (axis_first, axis_second, normal) =
        (axes.get.axis_first, axes.get.axis_second, axes.get.normal)
      check norm(axis_first) =~ 1.0
      check norm(axis_second) =~ 1.0
      check norm(normal) =~ 1.0
      check dot(axis_first, axis_second) =~ 0
      check dot(axis_first, normal) =~ 0
      check dot(axis_second, normal) =~ 0
      check toMultivector(axis_first) ∧ plane =~ 0
      check toMultivector(axis_second) ∧ plane =~ 0
      # Frame's own normal is same one `directionNormal` derives independently.
      check normal =~ directionNormal(plane).get


  test "object in horizon yields no anchor":
    for line in LINES:
      let attitude = ⊖ line
      check attitude.isHorizon
      check positionAnchor(attitude).isNone
      check directionHorizon(attitude).isSome


  test "the incidence vocabulary answers what the classical forms answer, sign included":
    # Classical forms live HERE, in test, and algebra lives in `objects.nim`.
    #   -- holding two equal is project's purpose, and it is also what pins every
    #   sign and argument order before anything downstream leans on them. Deterministic
    #   scatter, so failure names same case on every run.
    var seed = 3.0
    proc pseudo(): float =
      seed = (seed*97.31 + 33.77) mod 41.0
      seed - 20.5
    proc somewhere(): Position =
      Position(x: pseudo(), y: pseudo(), z: pseudo())
    proc someway(): Direction =
      var d = Direction(x: 0, y: 0, z: 0)
      while norm(d) < 0.1: d = Direction(x: pseudo(), y: pseudo(), z: pseudo())
      normalize(d).get

    # One fixed pin first: point one unit along plane's own construction.
    #   direction reads exactly +1 -- `plane ∨ point`, in that order; other order
    #   negates and must not be what ships.
    let plane_pin = planeThrough(
      toMultivector(Position(x: 0, y: 0, z: 2)),
      toMultivector(Direction(x: 0, y: 0, z: 1)),
    )
    check depthAgainst(plane_pin, toMultivector(Position(x: 0, y: 0, z: 3))) =~ 1.0
    check depthAgainst(plane_pin, toMultivector(Position(x: 0, y: 0, z: 2))) =~ 0.0
    check depthAgainst(plane_pin, toMultivector(Position(x: 5, y: -4, z: 1))) =~ -1.0
    # Doubled construction direction must change nothing: `planeThrough` unitizes, so.
    #   depth read is metric whatever length caller's direction happened to have.
    let plane_doubled = planeThrough(
      toMultivector(Position(x: 0, y: 0, z: 2)),
      toMultivector(Direction(x: 0, y: 0, z: 2)),
    )
    check depthAgainst(plane_doubled, toMultivector(Position(x: 0, y: 0, z: 3))) =~ 1.0

    for trial in 0 ..< 100:
      let
        at = somewhere()
        along = someway()
        probe = somewhere()
        other = somewhere()
      # `depthAgainst` `planeThrough` is classical signed distance along normal.
      check depthAgainst(
        planeThrough(toMultivector(at), toMultivector(along)), toMultivector(probe)
      ) =~ dot(probe - at, along)
      # `distanceBetween` is classical Euclidean distance.
      check distanceBetween(toMultivector(probe), toMultivector(other)) =~
        norm(probe - other)

    # Two ground spellings agree with each other and with what "ground" means.
    check depthAgainst(groundPlane(), toMultivector(Position(x: 3, y: -8, z: 5.5))) =~ 5.5
    let level = levelPlaneThrough(toMultivector(Position(x: 1, y: 2, z: 4)))
    check depthAgainst(level, toMultivector(Position(x: -9, y: 6, z: 7))) =~ 3.0

    # Centroid, folded one place at time, against mean written out here. Sum.
    #   of unit-weight points carries weight n and total of coordinates, so
    #   division `position` already does *is* averaging -- which is claim.
    let places = [
      Position(x: 3.0, y: -1.0, z: 2.0), Position(x: -5.0, y: 4.0, z: 0.5),
      Position(x: 1.0, y: 9.0, z: -3.5), Position(x: 8.0, y: -2.0, z: 6.0),
    ]
    # Fold starts from first point itself -- one place is its own middle -- and.
    #   carries running sum as multivector, so nothing has to be told count.
    var middle = toMultivector(places[0])
    check position(middle).get =~ places[0]
    for counted in 1 .. places.high:
      middle = centroidFolded(middle, toMultivector(places[counted]))
      var (sum_x, sum_y, sum_z) = (0.0, 0.0, 0.0)
      for i in 0 .. counted:
        sum_x += places[i].x
        sum_y += places[i].y
        sum_z += places[i].z
      # Every prefix, not only whole: incremental fold that is right at end and.
      #   wrong halfway is right by luck, and camera reads it at every length.
      check position(middle).get =~ Position(
        x: sum_x/float(counted + 1),
        y: sum_y/float(counted + 1),
        z: sum_z/float(counted + 1),
      )
      # And sum's own weight *is* how many places it is middle of -- which is what.
      #   lets running total stand in for count nobody carries.
      check middle[Basis.E4] =~ float(counted + 1)
