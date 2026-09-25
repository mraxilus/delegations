## Run `Orrery` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


# Orrery needs room for its default size, and one configuration here deliberately compiles.
#   much smaller pool to exercise pool's own limits. Guarded rather than shrunk:
#   arrangement scaled down would no longer be stress case these cases exist to check.
when OBJECTS_MAX >= objectsOf(SCALE_ORRERY_DEFAULT):
  suite "Orrery":
    ## Check demo preset, heaviest scene this build draws, against world it claims.
    ##   Real solar neighbourhood to scale: these bodies stand where they really stand, as
    ##   large as they really are, one unit one astronomical unit.
    ##   That claim needs checking as much as counting does, and it is one thing no
    ##   amount of looking at picture would catch.

    const SCALES_HELD = block:
      ## Name which sizes this build's pool can actually hold.
      ##   Every size at shipped capacity; at reduced one suite is skipped whole by guard
      ##   above, so this only ever narrows for capacity between two.
      var held: seq[ScaleOrrery]
      for scale in ScaleOrrery:
        if OBJECTS_MAX >= objectsOf(scale): held.add(scale)
      held

    proc placesOf(scene: var Scene): Table[string, Position] =
      ## Read every finite point of scene by label, as position.
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let geometry = scene.geometryOf(handle)
        if kindOf(geometry) != some(Kind.Point) or isHorizon(geometry): continue
        result[toText(scene.labelAt(handle))] = position(geometry).get

    proc isClose(a, b: float; parts: float = 1.0e-9): bool =
      ## Compare to relative tolerance, since radii here run down to hundredths of metres.
      ##   `=~` widens to absolute tolerance under one, which is every size in this scene.
      abs(a - b) <= parts*max(abs(a), abs(b))

    test "every size fills its own target exactly, and the largest leaves two handles":
      # **Walk lands on count rather than near it.** It passes over system too.
      #   large for room left instead of stopping on it, which is only reason three
      #   unrelated pivots can each come out exact; when it stopped, size hit its pivot
      #   only where object counts happened to sum to it. Checked at every size, because
      #   one size landing exactly says nothing about another.
      #   Handles above largest size are deliberate headroom -- reader can still
      #   build on top of loaded demo rather than meeting refusal, and two is
      #   shortest construction there is: add point, then join it to something.
      for scale in SCALES_HELD:
        var scene = initScene()
        constructOrrery(scene, scale)
        checkpoint(&"{scale}: {scene.len} objects, {OBJECTS_MAX - scene.len} free")
        check scene.len == objectsOf(scale)
        check not scene.isFull
        if scale == ScaleOrrery.high: check OBJECTS_MAX - scene.len == 2

    test "every object it builds draws something":
      # Three collinear points wedge to multivector of no clean grade, which takes handle.
      #   and renders nothing while scene still counts it. Seven objects did that across
      #   two earlier rounds, so this counts *shapes* rather than objects.
      var scene = initScene()
      constructOrrery(scene)
      var without: seq[string] = @[]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        if kindOf(scene.geometryOf(handle)).isNone: without.add(toText(scene.labelAt(handle)))
      check without == newSeq[string]()

    test "every size carries every drawable kind, in horizon as well as in the finite world":
      # **Property that makes smallest size usable check at all.** Quick pass.
      #   over 60 objects is only worth running if it exercises what big one does, and
      #   block in horizon is fragile part -- it is built from attitudes of Sol's own
      #   objects and `addHorizon` refuses pair spanning nothing, so size too small to
      #   carry arrangement fails here rather than quietly drawing less.
      var counted: array[ScaleOrrery, tuple[points, planes: int]]
      for scale in SCALES_HELD:
        var scene = initScene()
        constructOrrery(scene, scale)
        var tally: array[Kind, int]
        var at_horizon: array[Kind, int]
        for handle in 0 ..< scene.bound:
          if not scene.isAlive(handle): continue
          let geometry = scene.geometryOf(handle)
          let kind = kindOf(geometry)
          if kind.isNone: continue
          inc tally[kind.get]
          if isHorizon(geometry): inc at_horizon[kind.get]
        checkpoint(&"{scale}: {tally[Kind.Point]} points, {tally[Kind.Line]} lines, " &
          &"{tally[Kind.Plane]} planes")
        for kind in Kind: check tally[kind] > 0
        # **Ceiling as well as floor, and lines are only kind with one.** They are cut.
        #   to three that mean something -- two in Sol and one in horizon -- because
        #   line is infinite and crosses whole frame whatever it joins. Floor alone
        #   would let them creep back one edit at time. Same three at every size, since
        #   only Sol carries finite lines.
        check tally[Kind.Line] in 3 .. 4
        check at_horizon[Kind.Point] == 2 # Two, and only one of them can make plane.
        check at_horizon[Kind.Line] == 1
        check at_horizon[Kind.Plane] == 1
        counted[scale] = (tally[Kind.Point], tally[Kind.Plane])
      # Points and planes are what bigger size buys, so both have to rise with it. Stated.
      #   as slope rather than as floor per size: three sets of magic numbers would be
      #   three things to keep true, and what is actually being claimed is that reaching
      #   further into catalogue reaches more stars and more of systems that earn
      #   plane. Discs are expensive kind, so second half is where stress in
      #   stress case lives.
      for index in 1 ..< len(SCALES_HELD):
        let (smaller, larger) = (SCALES_HELD[index - 1], SCALES_HELD[index])
        check counted[larger].points > counted[smaller].points
        check counted[larger].planes > counted[smaller].planes

    test "the stars stand where the catalogue says they stand, turned into the ecliptic":
      # **Claim this arrangement makes about world.** Every object after Sol is real.
      #   star placed from its real right ascension, declination and distance, so thing
      #   worth checking is conversion -- not that layout looks spread out. Measured
      #   against `starfield.STARS` itself, which is shipped snapshot and one layer
      #   that says where anything is.
      #   Distance is parsecs into astronomical units, nothing else. Direction is
      #   catalogue's equatorial one turned about equinox by obliquity, so ecliptic lands on
      #   ground grid: read straight, every star stood 23 degrees off against Sol's planets.
      #   Turn is redone here from its definition rather than through module's own.
      #   Run at largest size this build holds, which is only one that reaches far
      #   enough into catalogue for claim to be worth much.
      let scale = SCALES_HELD[^1]
      var scene = initScene()
      constructOrrery(scene, scale)
      let placed = placesOf(scene)
      let sol = placed[SOL[0].name]
      let obliquity = degToRad(23.4392911)
      var worst = 0.0
      var worst_name = ""
      var worst_turn = 0.0
      var seen = 0
      # Catalogue carries more stars than scene has room for, so what is checked is.
      #   every star that *was* placed -- and, below, that ones placed are nearest.
      for star in STARS:
        if star.name notin placed: continue
        inc seen
        let
          apart = placed[star.name] - sol
          drawn = norm(apart)
          wanted = star.parsecs*AU_PER_PARSEC
          off = abs(drawn - wanted)/wanted
        if off > worst:
          worst = off
          worst_name = star.name
        let
          along = degToRad(star.ascension)
          up = degToRad(star.declination)
          equatorial = Direction(x: cos(up)*cos(along), y: cos(up)*sin(along), z: sin(up))
          ecliptic = Direction(
            x: equatorial.x,
            y: equatorial.y*cos(obliquity) + equatorial.z*sin(obliquity),
            z: -equatorial.y*sin(obliquity) + equatorial.z*cos(obliquity),
          )
          heading = (1.0/drawn)*apart
        worst_turn = max(worst_turn, norm(heading + (-ecliptic)))
      checkpoint(&"{scale}: {seen} stars placed; worst is `{worst_name}`, " &
        &"off by {worst:.3e} of its distance; worst direction off by {worst_turn:.3e}")
      # Most of what size spends goes on stars, so most of what it holds should be one.
      #   Folded from size rather than written down, so it survives next one.
      check seen > (objectsOf(scale) - OBJECTS_FIXED_ORRERY) div 2
      check worst <= 1.0e-12
      check worst_turn <= 1.0e-9
      # Turn is real one: Proxima's ecliptic latitude, -44.8 degrees, is well north of its
      #   declination, -62.7.
      let proxima = (1.0/norm(placed[STARS[0].name] - sol))*(placed[STARS[0].name] - sol)
      check arcsin(proxima.z) > degToRad(STARS[0].declination) + degToRad(10.0)
      check abs(radToDeg(arcsin(proxima.z)) + 44.8) < 0.5
      # And they really are ordered outward, which is what nearest-first fill relies on.
      for index in 1 ..< len(STARS):
        check STARS[index].parsecs >= STARS[index - 1].parsecs
      # **Nearest-first, and no longer strict prefix -- by bounded amount.** Walk.
      #   passes over system too large for room left rather than stopping on it, which
      #   is only reason three unrelated sizes can each land on their count exactly.
      #   price is that right at end nearer multi-object system can give way to further
      #   single star. Slack is bounded and bound is derived: once system needing
      #   `k` objects is passed over there are fewer than `k` handles left, and every star costs
      #   at least one, so at most `k - 1` stars can follow it in.
      var missing_from = len(STARS)
      for index, star in STARS:
        if star.name notin placed:
          missing_from = index
          break
      var slack = 0
      for index in missing_from ..< len(STARS):
        if STARS[index].name in placed: inc slack
      var widest = 0
      for star in STARS: widest = max(widest, objectsOf(star))
      checkpoint(&"{slack} stars placed beyond the first gap; the widest system is " &
        &"{widest} objects, so at most {widest - 1} can be")
      check slack <= widest - 1

    test "the star catalogue is a snapshot, and holds together as one":
      # Everything about shipped table that can be checked without network. It is.
      #   generated, so what is worth asserting is that generator's own claims survive:
      #   bound it queried to, order fill relies on, no star listed twice, and
      #   every planet range landing inside `neighbourhood.PLANETS` exactly once.
      var names = initHashSet[string]()
      var carried, planets_claimed = 0
      var covered = newSeq[int](len(PLANETS))
      for star in STARS:
        check star.name notin names
        names.incl(star.name)
        check star.parsecs > 0.0 and star.parsecs <= 31.53
        if star.planets == 0: continue
        inc carried
        planets_claimed += star.planets
        check star.first >= 0 and star.first + star.planets <= len(PLANETS)
        for which in star.first ..< star.first + star.planets: inc covered[which]
      checkpoint(&"{len(STARS)} stars, {carried} carrying {planets_claimed} planets")
      # Planet hosts are all here, and between them they claim every archive planet once.
      check carried == len(NEIGHBOURS)
      check planets_claimed == len(PLANETS)
      for which, times in covered: check times == 1

    test "no point in it is a hub for the rest of the scene":
      # Fault that broke arrangement before this one: every line and plane joined.
      #   through single star, so scene drew as starburst. Counted, because "it looks
      #   like starburst" is not something suite can see.
      #   Gather joiners once instead of re-reading whole pool for every point. Ten
      #   thousand objects of which barely hundred are lines or planes made this hundred
      #   million handle reads for same answer, and on JS backend each of those reads
      #   copies `Multivector` -- case stopped finishing at all.
      var scene = initScene()
      constructOrrery(scene)
      var planes: seq[Multivector]
      var lines: seq[Multivector]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let geometry = scene.geometryOf(handle)
        if isHorizon(geometry): continue
        case kindOf(geometry).get(Kind.Point)
        of Kind.Plane: planes.add(unitize(geometry))
        of Kind.Line: lines.add(geometry)
        of Kind.Point: discard
      var worst = 0
      var worst_label = ""
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let point = scene.geometryOf(handle)
        if kindOf(point) != some(Kind.Point) or isHorizon(point): continue
        let place = unitize(point)
        var through = 0
        for plane in planes:
          if abs(depthAgainst(plane, place)) <= TOLERANCE_SINGLE: inc through
        for line in lines:
          let spanned = wedge(line, place)
          var apart = 0.0
          for b in Basis: apart = max(apart, abs(spanned[b]))
          if apart <= TOLERANCE_SINGLE: inc through
        if through > worst:
          worst = through
          worst_label = toText(scene.labelAt(handle))
      checkpoint(&"worst point is `{worst_label}`, carrying {worst} lines and planes")
      check worst <= 6

    test "every body is drawn at its real radius, one unit one astronomical unit":
      # Sizes are real, so what is pinned is conversion and nothing else: Sol over Earth
      #   is 109, as it is, and every body stays above what editor accepts.
      var scene = initScene()
      constructOrrery(scene)
      var radii: Table[string, float]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        radii[toText(scene.labelAt(handle))] = scene.radiusAt(handle)
      check isClose(radii["sol"], 695_700.0/149_597_870.7)
      check isClose(radii["sol"]/radii["earth"], 695_700.0/6_371.0)
      check radii["sol"] > radii["jupiter"]
      check radii["jupiter"] > radii["saturn"]
      check radii["saturn"] > radii["earth"]
      check radii["earth"] > radii["luna"]
      check radii["luna"] > radii["phobos"]
      for body in SOL: check isClose(radii[body.name], radiusDrawnOf(body.kilometres_radius))
      for moon in MOONS: check isClose(radii[moon.name], radiusDrawnOf(moon.kilometres_radius))
      # Smallest body stays above what editor accepts, so none is pinned at least dot for good.
      for moon in MOONS: check radii[moon.name] >= RADIUS_OBJECT_LEAST
      # Neighbour suns and planets claim no size, having none on record: least, and stated.
      check radii[STARS[0].name] == RADIUS_OBJECT_LEAST
      for planet in PLANETS:
        if planet.name in radii: check radii[planet.name] == RADIUS_OBJECT_LEAST

    test "every planet rings Sol at its real semi-major axis, in the ecliptic":
      # Distances are real, so what is pinned is that table's astronomical units are.
      #   radii ring is drawn at, unsquashed, and that ring lies in z = 0 ground grid is
      #   ruled on, which is what makes ecliptic ground.
      var scene = initScene()
      constructOrrery(scene)
      let placed = placesOf(scene)
      let sol = placed["sol"]
      for body in SOL:
        if body.role != Role.Planet: continue
        check isClose(norm(placed[body.name] - sol), body.distance)
        check abs(placed[body.name].z) <= 1.0e-12
      check norm(placed["neptune"] - sol) =~ RADIUS_ORRERY

    test "every moon rings its planet at its real distance, in its real orbit plane":
      # Orientation is one thing tables carry that picture cannot be trusted to show.
      #   Luna leans its real 5.16 degrees from ecliptic; Triton rings Neptune backwards;
      #   Uranus's family is tipped nearly onto its side. Each pinned against
      #   `normalOfMoon`, and every moon's place pinned perpendicular to it.
      var scene = initScene()
      constructOrrery(scene)
      let placed = placesOf(scene)
      var normals: Table[string, Direction]
      for moon in MOONS:
        let
          parent = SOL[moon.parent].name
          apart = placed[moon.name] - placed[parent]
          normal = normalOfMoon(moon)
        normals[moon.name] = normal
        check isClose(norm(apart), moon.kilometres_orbit/149_597_870.7)
        check norm(normal) =~ 1.0
        check abs(dot(apart, normal)) <= 1.0e-9*norm(apart)
        # Ring clears both discs: bodies never overlap.
        check norm(apart) > radiusDrawnOf(SOL[moon.parent].kilometres_radius) +
          radiusDrawnOf(moon.kilometres_radius)
      checkpoint(&"luna leans {radToDeg(arccos(normals[\"luna\"].z)):.2f} degrees, triton's " &
        &"normal z {normals[\"triton\"].z:.3f}, miranda's {normals[\"miranda\"].z:.3f}")
      check abs(radToDeg(arccos(normals["luna"].z)) - 5.16) <= 1.0e-6
      check normals["triton"].z < 0.0
      for name in ["miranda", "ariel", "umbriel", "titania", "oberon"]:
        check abs(normals[name].z) < 0.3
      for name in ["io", "europa", "ganymede", "callisto"]:
        check radToDeg(arccos(normals[name].z)) < 3.0
      # Luna's direction from Earth is off ecliptic: horizon plane stands on this.
      check abs((placed["luna"] - placed["earth"]).z) > 1.0e-6

    test "every neighbour planet rings its star at its real axis, and one without is left out":
      # Archive stores missing semi-major axis as zero; such planet is left out rather
      #   than placed by order among siblings, since distance is whole of claim. Counted
      #   from table, so figure is catalogue's own.
      #   Neighbour's plane is flat, stated: every placed planet shares its star's height.
      let scale = SCALES_HELD[^1]
      var scene = initScene()
      constructOrrery(scene, scale)
      let placed = placesOf(scene)
      var left_out, checked = 0
      for star in STARS:
        if star.name notin placed or star.planets == 0: continue
        for which in star.first ..< star.first + star.planets:
          let planet = PLANETS[which]
          if planet.au <= 0.0:
            check planet.name notin placed
            inc left_out
            continue
          check planet.name in placed
          let apart = placed[planet.name] - placed[star.name]
          check abs(norm(apart) - planet.au) <= 1.0e-7
          check abs(apart.z) <= 1.0e-7
          inc checked
      var without = 0
      for planet in PLANETS:
        if planet.au <= 0.0: inc without
      checkpoint(&"{checked} planets placed at their axes, {left_out} of {without} " &
        &"without one left out")
      check checked > 0
      check without == 49
      # Count each star comes to says same: placed planets, not archive's.
      for star in STARS:
        check objectsOf(star) == 1 + placedOf(star) + (if placedOf(star) >= 2: 1 else: 0)

    test "every object wears its own type's colour, and no two types share one":
      # Moon and planet are two identical dots and hue is only thing separating.
      #   them, so role collapsing onto another's handle is silent loss of their one signal.
      var scene = initScene()
      constructOrrery(scene)
      for role in Role.Sun .. Role.Derived:
        for other in Role.Sun .. Role.Derived:
          if role != other: check lut_role_to_ink[role] != lut_role_to_ink[other]
      # Roles come from tables that placed objects -- `SOL` for our own system and.
      #   `NEIGHBOURS`/`PLANETS` for real ones -- rather than from second set of name
      #   rules that could drift from them.
      var roles: Table[string, Role]
      for body in SOL: roles[body.name] = body.role
      for moon in MOONS: roles[moon.name] = Role.Moon
      for star in STARS: roles[star.name] = Role.Sun
      for planet in PLANETS: roles[planet.name] = Role.Planet
      var bodies: array[Role, int]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let label = toText(scene.labelAt(handle))
        let role = roles.getOrDefault(label, Role.Derived)
        check scene.inkAt(handle) == lut_role_to_ink[role]
        inc bodies[role]
      for role in [Role.Sun, Role.Planet, Role.Moon, Role.Derived]:
        check bodies[role] > 0

    test "two finite lines in the whole scene, and only one joins a star to a planet":
      # State layout instruction as assertion.
      #   Asked geometrically, which lines pass through which bodies, so renaming
      #   something cannot make it pass.
      var scene = initScene()
      constructOrrery(scene)
      var roles: Table[string, Role]
      for body in SOL: roles[body.name] = body.role
      for moon in MOONS: roles[moon.name] = Role.Moon
      for star in STARS: roles[star.name] = Role.Sun
      for planet in PLANETS: roles[planet.name] = Role.Planet
      var suns, planets: seq[Multivector] = @[]
      var lines: seq[string] = @[]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let
          label = toText(scene.labelAt(handle))
          geometry = scene.geometryOf(handle)
        if isHorizon(geometry): continue
        case kindOf(geometry).get(Kind.Point)
        of Kind.Line: lines.add(label)
        of Kind.Point:
          case roles.getOrDefault(label, Role.Derived)
          of Role.Sun: suns.add(geometry)
          of Role.Planet: planets.add(geometry)
          else: discard
        of Kind.Plane: discard
      check lines == @["sol ∧ earth", "earth ∧ luna"]
      proc lies(line, point: Multivector): bool =
        let place = unitize(point)
        for b in Basis:
          if abs(wedge(line, place)[b]) > TOLERANCE_SINGLE: return false
        true
      var joining = 0
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let geometry = scene.geometryOf(handle)
        if isHorizon(geometry) or kindOf(geometry) != some(Kind.Line): continue
        for sun in suns:
          if not lies(geometry, sun): continue
          for planet in planets:
            if lies(geometry, planet): inc joining
      check joining == 1

    test "of the two points in horizon, only the one off the ecliptic makes the plane":
      # **Why there are two.** Earth lies in Sol's ecliptic, so direction Sol-to-Earth.
      #   lies along that plane and therefore *on* horizon line it gives -- wedging it
      #   back with that line adds nothing. Luna's ring is tipped out, so its direction is off
      #   line and spans plane with it. Both halves are checked, because whole
      #   construction turns on difference between them.
      var scene = initScene()
      constructOrrery(scene)
      var at_horizon: Table[string, Multivector]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let geometry = scene.geometryOf(handle)
        if isHorizon(geometry): at_horizon[toText(scene.labelAt(handle))] = geometry
      let
        line = at_horizon["att(ecliptic sol)"]
        on_it = at_horizon["att(sol ∧ earth)"]
        off_it = at_horizon["att(earth ∧ luna)"]
      var along, across = 0.0
      for b in Basis:
        along = max(along, abs(wedge(line, on_it)[b]))
        across = max(across, abs(wedge(line, off_it)[b]))
      checkpoint(&"earth's direction spans {along:.9f} with the line, luna's {across:.9f}")
      check along <= TOLERANCE_SINGLE # On line: it adds nothing.
      check across > TOLERANCE_SINGLE # Off it: it spans plane.
      check kindOf(line ∧ off_it) == some(Kind.Plane)
      check isHorizon(line ∧ off_it)

    test "the opening frame holds Sol's system to Neptune, and every star stands far beyond":
      # `RADIUS_ORRERY` is Neptune's own axis, and claim worth checking is that nothing
      #   else comes near it: nearest star stands thousands of that radius out, so frame
      #   fitted to our system shows one system and crossing neighbourhood is journey.
      check RADIUS_ORRERY =~ 30.05
      var nearest = STARS[0].parsecs*AU_PER_PARSEC
      for star in STARS: nearest = min(nearest, star.parsecs*AU_PER_PARSEC)
      checkpoint(&"nearest star at {nearest:.0f} units, {nearest/RADIUS_ORRERY:.0f} " &
        &"opening radii out")
      check nearest > 1000.0*RADIUS_ORRERY
      check AU_PER_PARSEC =~ 206_264.806
      check KILOMETRES_PER_AU =~ 149_597_870.7

    test "the preset both front-ends open on is one preset":
      # `showOrrery` is whole thing demo button loads -- arrangement, its replayed.
      #   arrival and camera that holds it -- and browser's bridge and desktop's
      #   `--demo` both call it. It used to live inline in bridge, where desktop
      #   could not reach it and nothing could check it, so camera half of preset
      #   was untested on either side.
      var scene = initScene()
      var camera = initCameraDefault()
      camera = camera.placedAtAzimuth(1.25) # Left alone by preset, so it has to survive it.
      showOrrery(scene, camera, 1440, 900)
      check scene.len == objectsOf(SCALE_ORRERY_DEFAULT)
      check camera.pivot =~ POSITION_ORRERY
      check camera.elevation =~ ELEVATION_ORRERY_SHOWN
      check camera.azimuth =~ 1.25
      # Standing back far enough to hold arrangement is point of solve, and.
      #   standing *inside* it is failure it exists to prevent -- opening camera,
      #   placed for seed scene, sits within this one.
      check camera.distance > RADIUS_ORRERY
      check camera.distance =~
        distanceFitting(RADIUS_ORRERY, camera, 1440, 900, INSET_ORRERY_SHOWN)
      # Narrower window has to stand further back, since fit is bounded by whichever.
      #   of two axes runs out first.
      var camera_narrow = initCameraDefault()
      showOrrery(scene, camera_narrow, 640, 900)
      check camera_narrow.distance > camera.distance
