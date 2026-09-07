## Build real solar neighbourhood, at one of three sizes, for stress testing.
##
## Orrery exists so build can be looked at under load.
##   Every drawable kind present, and objects scattered through volume so large that one
##   camera move swings tessellation load by order of magnitude, which flat helix
##   `visualiser.fillSceneForBenchmark` builds for `--timings` deliberately does not.
## Three sizes of one arrangement, so cost reads as slope rather than single number.
##   `ScaleOrrery.Nearest` (60), `Neighbourhood` (360, default) and `Catalogue` (5038,
##   two handles short of pool). Every one is same construction truncated at different depth.
## Also claim about world.
##   Every system but ours is real star known to carry planets, at real distance in real
##   direction, carrying planets it really has at real relative distances.
##     From `neighbourhood.nim`, shipped snapshot of NASA Exoplanet Archive;
##     `PROVENANCE.md` records query, date and acknowledgement, and what is checked.
##   `SOL` is our own, hand-written and modelled same way, at origin rest are measured
##   from. Nothing stands at `POSITION_ORRERY`'s coordinate but Sol itself.
##
##   |------------------|-------------------------------------|--------------------------|
##   | Object             | Built from                          | Present when             |
##   |------------------|-------------------------------------|--------------------------|
##   | star             | placed at its real position         | always                   |
##   | planets          | placed, ringing it at real radii    | as many as it has        |
##   | ecliptic plane   | `star ∧ planet[0] ∧ planet[1]`      | it has two planets       |
##   |------------------|-------------------------------------|--------------------------|
##
## Sol alone also carries moons and only two finite lines in whole scene: `sol ∧ earth`
## and `earth ∧ luna`.
##   Line is infinite, so each crosses entire frame; more read as line traffic.
## Four objects at horizon, two of them points because only one can make plane.
##   Earth lies in Sol's ecliptic, so `att(sol ∧ earth)` sits *on* line at horizon
##   ecliptic gives.
##   Luna's ring is tipped out of it, so `att(earth ∧ luna)` sits off that line and spans
##   plane at horizon with it. See horizon block in `constructOrrery`.
## `objectsOf(scale)` objects on nose at every size, asserted.
##   Walk passes over system too large for room left rather than stopping on it.
##   Only Sol's block and four at horizon are fixed; everything between is however many
##   real stars fit.
## Colour says what thing is, not which system it belongs to; see `lut_role_to_ink`.
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import pga
import ./[boundary, camera, euclid, neighbourhood, objects, scene, starfield,
  tessellate]



#[ Type Definitions ]#

type
  Role* {.pure.} = enum ## Define what object in arrangement is.
    Sun, ## Body at system's own centre.
    Planet, ## Body ringing its sun.
    Moon, ## Body ringing planet.
    Derived, ## Anything joined or taken attitude of: every line, every plane.

  SolBody* = object ## Define one body of modelled solar system.
    name*: string ## What it is called, also label it carries in scene.
    role*: Role ## What kind of body it is.
    distance*: float ## How far it really stands from Sol, in astronomical units.
    kilometres_radius*: float ## Real mean radius, in kilometres; see `radiusDrawnOf`.

  SolMoon* = object ## Define one real moon of modelled solar system.
    name*: string ## What it is called, also label it carries in scene.
    parent*: int ## Which entry of `SOL` it rings.
    kilometres_orbit*: float ## Real semi-major axis about that parent, in kilometres.
    kilometres_radius*: float ## Real mean radius, in kilometres; see `radiusDrawnOf`.

  System* = object ## Define where one system stands and how wide it is drawn.
    reach*: float ## How far its sun stands from `POSITION_ORRERY`, in world units.
    bearing*: float ## Which way it lies from that centre, in radians about vertical.
    rise*: float ## How far it stands above or below centre's level, in radians.
    radius*: float ## How far outermost planet rings its sun, in world units.
    lean*: float ## How far its plane leans out of horizontal, in radians.
    spin*: float ## Where first planet stands on its ring, in radians.



#[ Layout ]#

const
  POSITION_ORRERY* = Position(x: 0.0, y: 0.0, z: 0.0)
    ## Fix coordinate every system's placement is measured from, and demo's camera aims at.
    ##   Sol stands here, at world origin, where axes cross and grid is ruled from:
    ##   neighbourhood is real map measured from our own star.
    ##   Not lifted to keep southern systems above ground; they stand below it, where they
    ##   are.

  SOL*: array[9, SolBody] = [
    SolBody(name: "sol", role: Role.Sun, distance: 0.0, kilometres_radius: 695_700.0),
    SolBody(name: "mercury", role: Role.Planet, distance: 0.39, kilometres_radius: 2_439.7),
    SolBody(name: "venus", role: Role.Planet, distance: 0.72, kilometres_radius: 6_051.8),
    SolBody(name: "earth", role: Role.Planet, distance: 1.00, kilometres_radius: 6_371.0),
    SolBody(name: "mars", role: Role.Planet, distance: 1.52, kilometres_radius: 3_389.5),
    SolBody(name: "jupiter", role: Role.Planet, distance: 5.20, kilometres_radius: 69_911.0),
    SolBody(name: "saturn", role: Role.Planet, distance: 9.58, kilometres_radius: 58_232.0),
    SolBody(name: "uranus", role: Role.Planet, distance: 19.20, kilometres_radius: 25_362.0),
    SolBody(name: "neptune", role: Role.Planet, distance: 30.05, kilometres_radius: 24_622.0),
  ] ## One system modelling real one: ours, not to scale.
    ##   Distances are real semi-major axes in astronomical units; `radiusOfSolBody` says
    ##   what is done to them.
    ##     True numbers kept because they are thing worth checking, and compression is
    ##     then one function rather than nine hand-tuned constants.
    ##   Sol and eight planets, nothing else: moons are table of own, since moon's
    ##   distance is measured from parent and one field holding two units is wrong.
    ##   Only system whose bodies are named and whose planets stand at different radii,
    ##   so it gets own constructor.

  MOONS*: array[21, SolMoon] = [
    SolMoon(name: "luna", parent: 3, kilometres_orbit: 384_400.0,
      kilometres_radius: 1_737.4),
    SolMoon(name: "phobos", parent: 4, kilometres_orbit: 9_376.0,
      kilometres_radius: 11.1),
    SolMoon(name: "deimos", parent: 4, kilometres_orbit: 23_463.0,
      kilometres_radius: 6.2),
    SolMoon(name: "io", parent: 5, kilometres_orbit: 421_800.0,
      kilometres_radius: 1_821.6),
    SolMoon(name: "europa", parent: 5, kilometres_orbit: 671_100.0,
      kilometres_radius: 1_560.8),
    SolMoon(name: "ganymede", parent: 5, kilometres_orbit: 1_070_400.0,
      kilometres_radius: 2_634.1),
    SolMoon(name: "callisto", parent: 5, kilometres_orbit: 1_882_700.0,
      kilometres_radius: 2_410.3),
    SolMoon(name: "mimas", parent: 6, kilometres_orbit: 185_540.0,
      kilometres_radius: 198.2),
    SolMoon(name: "enceladus", parent: 6, kilometres_orbit: 238_040.0,
      kilometres_radius: 252.1),
    SolMoon(name: "tethys", parent: 6, kilometres_orbit: 294_670.0,
      kilometres_radius: 531.1),
    SolMoon(name: "dione", parent: 6, kilometres_orbit: 377_420.0,
      kilometres_radius: 561.4),
    SolMoon(name: "rhea", parent: 6, kilometres_orbit: 527_070.0,
      kilometres_radius: 763.8),
    SolMoon(name: "titan", parent: 6, kilometres_orbit: 1_221_870.0,
      kilometres_radius: 2_574.7),
    SolMoon(name: "iapetus", parent: 6, kilometres_orbit: 3_560_840.0,
      kilometres_radius: 734.5),
    SolMoon(name: "miranda", parent: 7, kilometres_orbit: 129_900.0,
      kilometres_radius: 235.8),
    SolMoon(name: "ariel", parent: 7, kilometres_orbit: 190_900.0,
      kilometres_radius: 578.9),
    SolMoon(name: "umbriel", parent: 7, kilometres_orbit: 266_000.0,
      kilometres_radius: 584.7),
    SolMoon(name: "titania", parent: 7, kilometres_orbit: 436_300.0,
      kilometres_radius: 788.4),
    SolMoon(name: "oberon", parent: 7, kilometres_orbit: 583_500.0,
      kilometres_radius: 761.4),
    SolMoon(name: "triton", parent: 8, kilometres_orbit: 354_760.0,
      kilometres_radius: 1_353.4),
    SolMoon(name: "nereid", parent: 8, kilometres_orbit: 5_513_800.0,
      kilometres_radius: 170.0),
  ] ## Major named satellites of modelled system, real semi-major axes and radii in km.
    ##   Major ones, not all: some three hundred are known, most unnamed rocks; these are
    ##   ones reader recognises, stated here so what is drawn is what is written down.
    ##   `radiusOfMoon` says what is done to orbit's kilometres.
    ##     Phobos rings Mars 588 times nearer than Nereid rings Neptune, so same logarithm
    ##     `radiusOfSolBody` uses squashes it.
    ##   `radiusDrawnOf` says what is done to radius's.
    ##   `parent` indexes `SOL`; static block below checks every one is planet.

  INDEX_SOL_EARTH = 3
    ## Name which entry of `SOL` is Earth.
    ##   Named rather than searched: one body arrangement's orbit line joins, load-bearing
    ##   in three places. Held to `SOL`'s name by compile-time check below.

  INDEX_SOL_URANUS = 7
  INDEX_SOL_NEPTUNE = 8
    ## Name which entries of `SOL` are two outermost planets.
    ##   Pair ecliptic is spanned from, and body setting system's scale.
    ##   Named rather than counted from end, which slid ecliptic onto wrong pair when last
    ##   entry was removed. Each is held by compile-time check below.

  INDEX_MOON_LUNA = 0
    ## Name which entry of `MOONS` is Luna.
    ##   Second finite line joins it to Earth, and plane at horizon exists only because
    ##   Luna's ring is tipped out of ecliptic; load-bearing as `INDEX_SOL_EARTH` is.

  SYSTEM_SOL = System(reach: 0.0, bearing: 0.0, rise: 0.0, radius: 12.0, lean: 0.0,
    spin: 0.4)
    ## Place Sol, and say how wide it is drawn.
    ##   At `POSITION_ORRERY` itself, reach zero: Sol is origin every other system is
    ##   measured from, so it is one system not placed at all.
    ##   Lean zero: ecliptic lies flat on ground grid, plane z = 0 grid is ruled on.
    ##     That is why moons have tilt of own (`TILT_MOON`): lean once tipped both
    ##     system's plane and Luna's ring, and plane at horizon is built from difference.

  UNITS_PER_PARSEC* = 100.0
    ## Fix how many world units one parsec stands for.
    ##   Single number turning real neighbourhood into scene.
    ##     Proxima, 1.30 parsecs out, stands 130 units from Sol, fourteen neighbour
    ##     widths; outermost star at 31.5 parsecs stands about 3,153 units out.
    ##   Chosen, not derived: knob for how far apart.
    ##     What reads as clustered is *ratio* of spacing to system size, so
    ##     `RADIUS_NEIGHBOUR` and `SYSTEM_SOL.radius` do not move with it.
    ##     Cost is stated at `RADIUS_ORRERY`.
    ##   Units-per-parsec rather than reciprocal because that is question anyone asks.

  RADIUS_NEIGHBOUR* = 9.0
    ## Fix how wide neighbour system is drawn, in world units.
    ##   One width for all: real extents differ enormously, but at this scale difference
    ##   is invisible and pretending to it is fiction dressed as data.
    ##   Sol is drawn wider (`SYSTEM_SOL.radius`) because it is one system reader looks
    ##   into.

  FACTOR_ISOLATION_ORRERY* = 2.0
    ## Fix how many times combined width two systems' suns must stand apart.
    ##   Concrete meaning of isolated, checkable: nearer than this bodies interleave.
    ##     Held by suite case over built scene.
    ##   Two, not three: clear gap between outer edges is still as wide as both systems,
    ##   and every unit demanded here is paid by shrinking systems against framed view.
    ##   Table measures 2.20 at tightest pair, so floor is pinned just under what layout
    ##   achieves: edit eating tenth of margin fails run.

  FRAMED_ORRERY* = 2
    ## Fix how many systems, nearest first, demo's opening camera is fitted to.
    ##   Sol and Proxima, two of three hundred and thirty-two.
    ##     Fitted to more, opening camera stood so far off that nothing was left to go and
    ##     find.
    ##   Distant stars stay *visible* whatever this is: point never falls under least
    ##   pixel size (`mesh.DIAMETER_POINT_LEAST`).

const
  RADIUS_SOL_DRAWN = 0.6
    ## Fix how large Sol is drawn, in world units, anchor every body's size is scaled from.
    ##   Under quarter of Mercury's ring at 2.75, so innermost planet stands clear; wider
    ##   than opening camera's least dot, so Sol reads as sun among stars from 139 units.
  KILOMETRES_SOL = SOL[0].kilometres_radius
    ## Name Sol's real radius, denominator of `radiusDrawnOf`.
  RADIUS_NEIGHBOUR_SUN = RADIUS_SOL_DRAWN
    ## Fix how large every neighbour star is drawn.
    ##   Catalogue carries no radii, and one figure for all is honest about that; Sol's
    ##   own, so our star is not singled out.


func radiusDrawnOf*(kilometres: float): float =
  ## Report how large body of real radius `kilometres` is drawn, in world units.
  ##   Square root of ratio to Sol, anchored at `RADIUS_SOL_DRAWN`.
  ##     True scale is unreadable: Sol's real radius is 0.0047 astronomical units, and at
  ##     Mercury's seven units per unit of orbit that is 0.03, Earth 0.0003, every body
  ##     under least dot from any camera that shows two of them. Picture would be one
  ##     before sizes existed.
  ##     Linear scale anchored at Sol puts Earth at 0.006, still dot beside 0.6 sun.
  ##     Square root keeps order and compresses Sol-to-Earth ratio from 109 to 10: Sol,
  ##     Jupiter, Earth and Luna read as four sizes, at 0.6, 0.19, 0.057 and 0.03.
  ##   Exported so suite pins bodies against it.
  RADIUS_SOL_DRAWN*sqrt(kilometres/KILOMETRES_SOL)


const
  RADIUS_NEIGHBOUR_PLANET = radiusDrawnOf(SOL[INDEX_SOL_EARTH].kilometres_radius)
    ## Fix how large every neighbour planet is drawn.
    ##   Archive carries no radii either; Earth's, same rule as suns take Sol's.
  COUNT_OBJECT_HORIZON = 4
    ## Count objects closing block comes to.
    ##   Four, not three: two points at horizon, because one cannot make plane. See
    ##   horizon block in `constructOrrery`.

  RADIUS_MOON_NEAREST = 0.08
  RADIUS_MOON_FURTHEST = 0.32
    ## Fix how far nearest and furthest moon ring parents' drawn rims, in world units.
    ##   From rim rather than centre; see `radiusOfMoon`.
    ##   Small, necessarily: tightest planet pair, Venus and Earth, stands 0.74 apart, so
    ##   moon ring wider than third of that reaches next orbit.
    ##     Moon is dot beside planet at opening camera and separate body once reader goes
    ##     and looks.
    ##   Range rather than single multiple: twenty-one moons need range to map onto.
    ##   From rim, since planet now has one: Io's ring measured from Jupiter's centre lay
    ##   inside Jupiter's disc, at 0.22 against 0.19.


  TILT_MOON = 0.0897
    ## Fix how far moon's ring leans out of planet's orbital plane, in radians.
    ##   Luna's real inclination to ecliptic, 5.14 degrees.
    ##     One figure for every moon: real inclinations are all small, and one that has
    ##     to be right is Luna's.
    ##   Plane at horizon exists only because this is not zero.
    ##     `addHorizon` refuses pair if this ever goes flat.

  SHIFT_SOL = 1.0
    ## Fix how far `radiusOfSolBody`'s logarithm is lifted before normalising.
    ##   Without it Mercury lands at radius zero, *inside* Sol.
    ##   One keeps Venus and Earth about sixteenth of system's radius apart, two clear
    ##   dots at framed camera.

  AU_NEIGHBOUR_NEAREST = 0.01
    ## Fix nearest semi-major axis neighbour ring's logarithm is scaled from.
    ##   Real planets come far closer to stars than Mercury does, so scale cannot start
    ##   where Sol's does.
    ##   Clamped: below this planet is drawn at ring's inner limit, honest about drawing
    ##   being unable to separate it from star.

  AU_NEIGHBOUR_FURTHEST = 30.0
    ## Fix furthest semi-major axis scale runs to, Neptune's own.
    ##   Neighbour's ring and Sol's read on same scale.

const lut_role_to_ink*: array[Role, Ink] = [
  Role.Sun: Ink.Copper,
  Role.Planet: Ink.Cobalt,
  Role.Moon: Ink.Rose,
  Role.Derived: Ink.Olive,
] ## Colour every object by what it is, not by which system it belongs to.
  ##   Hue per cluster meant sun, planets, moons and comets all one colour.
  ##     Reader could see which system dot belonged to, which position already said, and
  ##     not moon from comet, which nothing else says.
  ##   `mesh.Ink` offers five assignable slots.
  ##     Four go to kinds of *body* and fifth to everything derived: line and disc are
  ##     told apart by shape, while two dots need hue.
  ##   Which body gets which was settled by `tools/check_palette`.
  ##     `Olive` is darkest slot and on *body* disappears, so it goes on derived side,
  ##     forcing bodies onto `Rose`, `Copper`, `Jade`, `Cobalt`.
  ##     `Jade`/`Cobalt` is palette's one declared exception (3.7 under tritanopia), so it
  ##     goes on planet and comet, which stand apart on screen, not planet and moon,
  ##     which sit beside each other.



#[ Construction ]#

func sunOf(system: System): Position =
  ## Report where system's own sun stands.
  ##   Spherical about `POSITION_ORRERY`: `bearing` turns about vertical and `rise` lifts
  ##   out of its level, so spreading systems spreads two angles and one distance.
  let flat = system.reach*cos(system.rise)
  Position(
    x: POSITION_ORRERY.x + flat*cos(system.bearing),
    y: POSITION_ORRERY.y + flat*sin(system.bearing),
    z: POSITION_ORRERY.z + system.reach*sin(system.rise),
  )


func spanOf(system: System): (Direction, Direction) =
  ## Report two directions system's own plane is spanned by.
  ##   One place orientation is written down, so planet placed on its ecliptic is on very
  ##   plane scene holds.
  ##   `lean` tips first direction out of horizontal; second stays level, so lean of zero
  ##   lays system flat.
  (
    Direction(x: cos(system.bearing)*cos(system.lean),
      y: sin(system.bearing)*cos(system.lean), z: sin(system.lean)),
    Direction(x: -sin(system.bearing), y: cos(system.bearing), z: 0.0),
  )


func normalOf(system: System): Direction =
  ## Report unit normal of system's own plane.
  ##   `spanOf` returns orthonormal pair, so cross product is already unit.
  ##     Reason pair is built orthonormal: everything tipped out of plane is tipped by
  ##     rotation, and axis not of length one stretches what it turns.
  let (along, across) = spanOf(system)
  cross(along, across)


func tipped(first, second: Direction; angle: float): Direction =
  ## Turn `first` toward `second` by `angle`, both unit and perpendicular.
  Direction(
    x: first.x*cos(angle) + second.x*sin(angle),
    y: first.y*cos(angle) + second.y*sin(angle),
    z: first.z*cos(angle) + second.z*sin(angle),
  )


func ringed(centre: Position; along, across: Direction; radius, angle: float): Position =
  ## Report point on ring of `radius` about `centre`, at `angle` in plane two span.
  Position(
    x: centre.x + radius*(cos(angle)*along.x + sin(angle)*across.x),
    y: centre.y + radius*(cos(angle)*along.y + sin(angle)*across.y),
    z: centre.z + radius*(cos(angle)*along.z + sin(angle)*across.z),
  )


func angleRing(spin: float; index, count: int): float =
  ## Report where one body of ring of `count` stands, in radians.
  ##   Ring of `count` is spread over `count + 1` steps.
  ##     Even spacing puts pair of two diametrically opposite, collinear with parent, and
  ##     plane wedged from three collinear points has no clean grade and draws nothing
  ##     while holding handle. `addPlane` exists because of it.
  spin + TAU*float(index)/float(count + 1)


func radiusOfSolBody(body: SolBody): float =
  ## Report how far body of `SOL` rings Sol in scene, in world units.
  ##   Not to scale, squashed by logarithm.
  ##     Real distances span 0.39 to 30.05 astronomical units, range of 77: laid out
  ##     faithfully, four inner planets share innermost fiftieth as single dot.
  ##     Logarithm keeps order and shape of spacing while compressing 77 to about 5.
  ##   Lifted by `SHIFT_SOL` before normalising, or Mercury lands on Sol; scaled so
  ##   Neptune sits at exactly system's radius.
  let
    nearest = ln(SOL[1].distance)
    furthest = ln(SOL[INDEX_SOL_NEPTUNE].distance)
    span = furthest - nearest + SHIFT_SOL
  SYSTEM_SOL.radius*(ln(body.distance) - nearest + SHIFT_SOL)/span


func radiusOfMoon(moon: SolMoon): float =
  ## Report how far moon of `MOONS` rings its planet's centre in scene, in world units.
  ##   Same logarithm `radiusOfSolBody` uses: real axes run from Phobos at 9,376 km to
  ##   Nereid at 5.5 million, range of 588.
  ##   Mapped onto `RADIUS_MOON_NEAREST`..`RADIUS_MOON_FURTHEST` rather than multiple of
  ##   system's radius: what bounds moon ring is gap to next planet's orbit, distance in
  ##   world units.
  var nearest = MOONS[0].kilometres_orbit
  var furthest = MOONS[0].kilometres_orbit
  for other in MOONS:
    nearest = min(nearest, other.kilometres_orbit)
    furthest = max(furthest, other.kilometres_orbit)
  let share = (ln(moon.kilometres_orbit) - ln(nearest))/(ln(furthest) - ln(nearest))
  # From parent's rim, so ring clears disc parent is drawn as; see `RADIUS_MOON_NEAREST`.
  radiusDrawnOf(SOL[moon.parent].kilometres_radius) +
    RADIUS_MOON_NEAREST + share*(RADIUS_MOON_FURTHEST - RADIUS_MOON_NEAREST)


func radiusOfNeighbourPlanet(planet: NeighbourPlanet; which, count: int): float =
  ## Report how far real planet rings its star in scene, in world units.
  ##   Same logarithm `radiusOfSolBody` uses: real axes in one system span three orders
  ##   of magnitude.
  ##   Where archive carries no semi-major axis, planet is placed by order among siblings,
  ##   spread evenly over ring.
  ##     One place number is supplied rather than read, confined to planets
  ##     `neighbourhood.nim` stores as `0.0`.
  if planet.au <= 0.0:
    return RADIUS_NEIGHBOUR*(0.35 + 0.65*float(which + 1)/float(max(count, 1)))
  let
    nearest = ln(AU_NEIGHBOUR_NEAREST)
    span = ln(AU_NEIGHBOUR_FURTHEST) - nearest + SHIFT_SOL
  RADIUS_NEIGHBOUR*clamp((ln(planet.au) - nearest + SHIFT_SOL)/span, 0.12, 1.0)


static:
  doAssert SOL[INDEX_SOL_EARTH].name == "earth",
    &"`INDEX_SOL_EARTH` must name Earth, whose orbit line joins it to Sol and whose " &
      &"attitude is the point at horizon; got `{SOL[INDEX_SOL_EARTH].name}`."
  doAssert SOL[INDEX_SOL_URANUS].name == "uranus" and
      SOL[INDEX_SOL_NEPTUNE].name == "neptune",
    &"`INDEX_SOL_URANUS` and `INDEX_SOL_NEPTUNE` must name the two outermost planets, " &
      &"which span the ecliptic and set the system's scale; got " &
      &"`{SOL[INDEX_SOL_URANUS].name}` and `{SOL[INDEX_SOL_NEPTUNE].name}`."
  doAssert MOONS[INDEX_MOON_LUNA].name == "luna",
    &"`INDEX_MOON_LUNA` must name Luna, whose line to Earth gives the plane at horizon " &
      &"its attitude; got `{MOONS[INDEX_MOON_LUNA].name}`."
  doAssert SOL[0].role == Role.Sun, &"`SOL` must open with its star; got `{SOL[0].role}`."
  for moon in MOONS:
    doAssert moon.parent > 0 and moon.parent < len(SOL) and
        SOL[moon.parent].role == Role.Planet,
      &"Every moon must ring a planet of `SOL`, see `MOONS`' own `parent` column; got " &
        &"`{moon.parent}` for `{moon.name}`."


func addHorizon(
  scene: var Scene, geometry: Multivector, label: string, expected: Kind, now: float
) =
  ## Add one of closing objects at horizon, refusing anything that is not one.
  ##   Same guard `addPlane` is, against second way of getting it wrong.
  ##     Attitude of grade-4 volume is plane at horizon only if point and plane wedged to
  ##     make it are genuinely apart: `planet[0] ∧ ecliptic` gave zero, `ecliptic` being
  ##     plane `planet[0]` built.
  ##     `storyboard`'s seeds carry same warning about `o` and `ground`.
  doAssert kindOf(geometry) == some(expected) and isHorizon(geometry),
    &"Orrery's `{label}` must be {expected} at horizon, its operands genuinely apart; got " &
      &"`{kindOf(geometry)}`."
  scene.addObject(geometry, label, lut_role_to_ink[Role.Derived], now)


func addPlane(
  scene: var Scene, geometry: Multivector, label: string, now: float, anchor: Position
) =
  ## Add derived plane, refusing anything that is not one.
  ##   Three collinear points wedge to multivector of no clean grade, which `objects.kindOf`
  ##   reports as nothing to draw: object takes handle and never appears.
  ##   Collinearity comes from layout table and any edit can reintroduce it; `angleRing`
  ##   says what edit to avoid.
  doAssert kindOf(geometry) == some(Kind.Plane),
    &"Orrery must derive `{label}` from three points spanning a plane, so the layout " &
      &"holds a collinear triple; got `{kindOf(geometry)}`."
  scene.addObject(geometry, label, lut_role_to_ink[Role.Derived], now, some(anchor))


func objectsOf*(star: Star): int =
  ## Report how many scene objects one real star comes to.
  ##   Exported because suite bounds how far fill may depart from nearest-first with it.
  ##   Itself, known planets, and ecliptic plane it earns with two planets to span one.
  ##     Every further object would be invention; great majority come to one object.
  1 + star.planets + (if star.planets >= 2: 1 else: 0)


func systemAt(star: Star): System =
  ## Report where real star stands and how wide its system is drawn.
  ##   Right ascension and declination are real direction, distance real length:
  ##   placement is coordinate conversion, not layout.
  ##     Declination measures up from celestial equator and ascension around it, exactly
  ##     `rise`/`bearing` pair `sunOf` takes.
  ##   `lean` and `spin` are one thing here *not* real: no orientation is claimed.
  ##     Spread by star's own coordinates so no two systems lie parallel; deterministic,
  ##     stated as arbitrary.
  System(
    reach: star.parsecs*UNITS_PER_PARSEC,
    bearing: degToRad(star.ascension),
    rise: degToRad(star.declination),
    radius: RADIUS_NEIGHBOUR,
    lean: 0.25 + 0.9*abs(sin(star.ascension)),
    spin: star.declination,
  )


const OBJECTS_SOL* = len(SOL) + len(MOONS) + 3
  ## Count scene objects Sol comes to.
  ##   Star and planets, moons, ecliptic, and two lines that are only finite lines in
  ##   whole arrangement.


type ScaleOrrery* {.pure.} = enum
  ## Name how deep into catalogue one build of arrangement reaches.
  ##   Three sizes of same scene, not three scenes: Sol entire, then real stars outward,
  ##   then four objects at horizon, truncated at different depth.
  ##   They exist to be *benchmarked against each other*, so cost of change reads as
  ##   slope.
  Nearest       ## Sol entire, and about dozen of its nearest real neighbours.
  Neighbourhood ## Default everywhere: scene worth looking at, quick to build.
  Catalogue     ## Load case, two handles short of pool.


func objectsOf*(scale: ScaleOrrery): int =
  ## Report how many objects arrangement fills at this size.
  ##   Which size to use is working rule, not build setting.
  ##     `Nearest` for quick check, `Neighbourhood` for final one, `Catalogue` when
  ##     change could cost performance.
  ##     Everything not saying otherwise takes `SCALE_ORRERY_DEFAULT`.
  ##   `Catalogue` stops two short of `scene.OBJECTS_MAX`: smallest margin still proving
  ##   point of leaving one, so reader can add point and join it to something.
  case scale
  of ScaleOrrery.Nearest: 60
  of ScaleOrrery.Neighbourhood: 360
  of ScaleOrrery.Catalogue: 5038


const SCALE_ORRERY_DEFAULT* = ScaleOrrery.Neighbourhood
  ## Fix which size everything opens on unless asked for another.
  ##   Both demo buttons, desktop's `--demo`, every suite case not naming size.
  ##   One default in one place, so two front-ends cannot disagree about what demo means.


const
  OBJECTS_FIXED_ORRERY* = COUNT_OBJECT_HORIZON + OBJECTS_SOL
    ## Count objects arrangement comes to before single neighbour is placed.
    ##   Folded from tables rather than written beside them, for reason `RADIUS_ORRERY` is.

  OBJECTS_ORRERY_MIN* = OBJECTS_FIXED_ORRERY + objectsOf(STARS[0])
    ## Count smallest arrangement there is.
    ##   Sol entire, block at horizon, and one neighbour opening camera is fitted to.
    ##   Floor rather than preference.
    ##     Below `OBJECTS_FIXED_ORRERY` scene cannot hold Sol, and block at horizon takes
    ##     attitudes of Sol's objects. One neighbour beyond is what `RADIUS_ORRERY` needs
    ##     to be true.
    ##   Folded, so it moves when `SOL`, `MOONS` or catalogue's nearest entry does.

static:
  for scale in ScaleOrrery:
    doAssert objectsOf(scale) >= OBJECTS_ORRERY_MIN,
      &"`ScaleOrrery.{scale}` must ask for at least `{OBJECTS_ORRERY_MIN}` objects, Sol, the " &
        &"block at horizon and the one neighbour the opening camera is fitted to; got " &
        &"`{objectsOf(scale)}`."
  doAssert FRAMED_ORRERY == 2,
    &"`OBJECTS_ORRERY_MIN` folds in one neighbour because `FRAMED_ORRERY` is 2, and must " &
      &"fold in that many less one; got `{FRAMED_ORRERY}`."

const RADIUS_ORRERY* = block:
  ## Report how far out demo's camera stands back to hold systems it is meant to hold.
  ##   Caller frames arrangement without knowing what is in it.
  ##   Folded from table, for reason `OBJECTS_FIXED_ORRERY` is.
  ##     Only nearest `FRAMED_ORRERY` are folded in.
  ##     One figure for every size, which `OBJECTS_ORRERY_MIN` keeps true.
  ##   At 100 units per parsec this comes to about 139, against Sol's 12.
  ##     System reader looks into is under tenth of opening frame's radius, price of field
  ##     that does not read as clump. `FRAMED_ORRERY` is knob if ever too much, not
  ##     spacing.
  var far = SYSTEM_SOL.reach + SYSTEM_SOL.radius
  for index, star in STARS:
    if index + 1 < FRAMED_ORRERY:
      far = max(far, star.parsecs*UNITS_PER_PARSEC + RADIUS_NEIGHBOUR)
  far

const
  ELEVATION_ORRERY_SHOWN* = 0.95
    ## Fix how far above horizontal demo's camera stands, in radians.
    ##   Opening camera at 0.42 is nearly edge-on to systems on planes: every ring collapses
    ##   to line and arrangement reads as starburst.
    ##   Steeper also makes sphere fit honest.
    ##   Not overhead: at `TAU/4` leans stop reading and ground grid disappears into own
    ##   horizon.
    ##   Azimuth is left where reader had it.

  INSET_ORRERY_SHOWN* = 24.0
    ## Fix how many pixels of margin arrangement is framed with, per side.
    ##   Wider than framed selection takes (`framing.INSET_POINT_SHOWN`).
    ##     Fitted tightly, outermost framed system's marker ring touches frame edge, and
    ##     marker is drawn in pixels about dot solve knows nothing about.


func constructSol(
  scene: var Scene; now: float; ecliptic, orbit, tether: var Multivector
) =
  ## Build modelled solar system, handing back three objects horizon block takes attitudes of.
  ##   Planets ring Sol at `radiusOfSolBody`'s radii rather than one shared radius, whole
  ##   reason this is not generic template.
  let
    place_sol = sunOf(SYSTEM_SOL)
    (along, across) = spanOf(SYSTEM_SOL)
    sol = toMultivector(place_sol)
    # Tip moon's ring out of ecliptic; see `TILT_MOON`.
    leaned = tipped(along, normalOf(SYSTEM_SOL), TILT_MOON)
  var placed: array[len(SOL), Multivector]
  var places: array[len(SOL), Position]
  for index, body in SOL:
    # Step phases by golden angle, so no two planets line up from opening camera.
    #   Earth's line then passes through none.
    let angle = SYSTEM_SOL.spin + 2.4*float(index)
    let place =
      case body.role
      of Role.Sun: place_sol
      of Role.Planet: ringed(place_sol, along, across, radiusOfSolBody(body), angle)
      of Role.Moon, Role.Derived: place_sol # `SOL` holds sun and planets; see its check.
    places[index] = place
    placed[index] = toMultivector(place)
    scene.addObject(
      placed[index], body.name, lut_role_to_ink[body.role], now,
      radius = radiusDrawnOf(body.kilometres_radius), shines = body.role == Role.Sun,
    )
  # Ring every moon about planet it really rings, in that plane tipped by `TILT_MOON`.
  #   Phases step by golden angle per moon, so two moons of one planet never stand
  #   together.
  var placement_moons: array[len(MOONS), Multivector]
  for index, moon in MOONS:
    let place = ringed(places[moon.parent], leaned, across, radiusOfMoon(moon),
      SYSTEM_SOL.spin + 2.4*float(index))
    placement_moons[index] = toMultivector(place)
    scene.addObject(
      placement_moons[index], moon.name, lut_role_to_ink[Role.Moon], now,
      radius = radiusDrawnOf(moon.kilometres_radius),
    )
  # Span ecliptic by Sol and two outermost planets, best conditioned join of eight.
  ecliptic = sol ∧ placed[INDEX_SOL_NEPTUNE] ∧ placed[INDEX_SOL_URANUS]
  orbit = sol ∧ placed[INDEX_SOL_EARTH]
  # Join two lines in whole arrangement, which horizon block is built from.
  #   Earth lies *in* ecliptic, Luna's ring is tipped out of it, and that difference
  #   makes plane at horizon constructible.
  tether = placed[INDEX_SOL_EARTH] ∧ placement_moons[INDEX_MOON_LUNA]
  scene.addObject(orbit, "sol ∧ earth", lut_role_to_ink[Role.Derived], now)
  scene.addObject(tether, "earth ∧ luna", lut_role_to_ink[Role.Derived], now)
  addPlane(scene, ecliptic, "ecliptic sol", now, place_sol)


func constructOrrery*(
  scene: var Scene, scale: ScaleOrrery = SCALE_ORRERY_DEFAULT, now: float = 0.0
) =
  ## Fill scene with every system in turn, then four objects at horizon.
  ##   `scale` says how deep into catalogue to reach; see `ScaleOrrery`. Every size runs
  ##   same code.
  ##   `now` is forwarded to `addObject` untouched, so every object animates in as one
  ##   added by hand.
  ##   Asserts scene handed is empty and that it leaves exactly size asked for.
  doAssert scene.len == 0,
    &"Orrery fills a scene to a stated size, so it must start empty; got `{scene.len}`."
  doAssert OBJECTS_MAX >= objectsOf(scale),
    &"Orrery at `{scale}` needs `{objectsOf(scale)}` object handles; this build was compiled " &
      &"with `{OBJECTS_MAX}`. Raise `--define:visualiser.objects_max`, or ask for a smaller size."

  # Build Sol first: nearest system, and horizon block takes attitudes of its objects.
  var ecliptic_sol, orbit_sol, tether_sol: Multivector
  constructSol(scene, now, ecliptic_sol, orbit_sol, tether_sol)

  # Place every other star where it really stands, with planets archive records.
  #   Nothing invented: star earns ecliptic with two known planets, and great majority
  #   are single point.
  #   Walk outward until scene holds what size asks for, less horizon block added after.
  #   System too large for room left is passed over, not stopped on: `break` reached
  #   pivot only where counts summed exactly.
  #     Cost is that last few systems in are not strictly nearest left, invisible in
  #     field of thousands.
  for star in STARS:
    if scene.len + objectsOf(star) > objectsOf(scale) - COUNT_OBJECT_HORIZON: continue
    let
      system = systemAt(star)
      place_sun = sunOf(system)
      (along, across) = spanOf(system)
      sun = toMultivector(place_sun)
    scene.addObject(
      sun, star.name, lut_role_to_ink[Role.Sun], now, radius = RADIUS_NEIGHBOUR_SUN,
      shines = true,
    )
    if star.planets == 0: continue

    var first_planet, second_planet: Multivector
    for which in 0 ..< star.planets:
      let
        planet = PLANETS[star.first + which]
        place = ringed(place_sun, along, across,
          radiusOfNeighbourPlanet(planet, which, star.planets),
          angleRing(system.spin, which, star.planets))
        body = toMultivector(place)
      if which == 0: first_planet = body
      elif which == 1: second_planet = body
      scene.addObject(
        body, planet.name, lut_role_to_ink[Role.Planet], now, radius = RADIUS_NEIGHBOUR_PLANET
      )

    # Span plane from two planets; star with single known planet gets no invented second.
    if star.planets >= 2:
      addPlane(scene, sun ∧ first_planet ∧ second_planet,
        "ecliptic " & star.name, now, place_sun)

  # Close at horizon, every one attitude of one of Sol's objects.
  #   Attitude drops one grade and lands at horizon: line gives point there, plane gives
  #   line.
  #   Two points, and only second can make plane.
  #     `att(sol ∧ earth)` lies along ecliptic, so sits *on* line at horizon it gives;
  #     `att(earth ∧ luna)` points off it, and wedged with that line spans plane at
  #     horizon. `addHorizon` refuses pair spanning nothing.
  let
    at_horizon_earth = attitude(orbit_sol)
    at_horizon_luna = attitude(tether_sol)
    at_horizon_ecliptic = attitude(ecliptic_sol)
  addHorizon(scene, at_horizon_earth, "att(sol ∧ earth)", Kind.Point, now)
  addHorizon(scene, at_horizon_luna, "att(earth ∧ luna)", Kind.Point, now)
  addHorizon(scene, at_horizon_ecliptic, "att(ecliptic sol)", Kind.Line, now)
  addHorizon(scene, at_horizon_ecliptic ∧ at_horizon_luna,
    "att(ecliptic sol) ∧ att(earth ∧ luna)", Kind.Plane, now)

  doAssert scene.len == objectsOf(scale),
    &"Orrery at `{scale}` must build `{objectsOf(scale)}` objects, and its walk passes over " &
      &"what will not fit rather than stopping, so it falls short only by running out of " &
      &"catalogue, `starfield.STARS` carrying too few stars; got `{scene.len}`."


func showOrrery*(
  scene: var Scene; camera: var Camera; width, height: int;
  scale: ScaleOrrery = SCALE_ORRERY_DEFAULT; now: float = 0.0
) =
  ## Replace scene with arrangement and stand camera back to hold it.
  ##   Whole preset in one place, because both front-ends open on it.
  ##   Arrives as replay: `scene.replayFrom` restamps whole construction, so nearest
  ##   system appears first, as loaded `.rgascene` does.
  ##     Restamped after fact so beat is fitted to whole arrival.
  ##   Camera stands back far enough to hold nearer systems, aims at arrangement's centre,
  ##   pitches up over it.
  ##     Solved: `distanceFitting` is same sphere-tangent solve framed selection uses.
  ##     Pitched first, since solve reads camera handed; azimuth is left where reader had
  ##     it. `POSITION_ORRERY` holds no object.
  ##   Not here: anything either front-end keeps of own (born stamps, selection, undo
  ##   timeline), bookkeeping about scene rather than part of it.
  scene.restoreFrom(initScene())
  constructOrrery(scene, scale, now)
  scene.replayFrom(now)
  camera.pivot = POSITION_ORRERY
  camera.elevation = ELEVATION_ORRERY_SHOWN
  camera.distance =
    distanceFitting(RADIUS_ORRERY, camera, width, height, INSET_ORRERY_SHOWN)
