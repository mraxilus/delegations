## Build real solar neighbourhood, at one of three sizes, for stress testing.
##
## Orrery exists so build can be looked at under load.
##   Every drawable kind present, and objects scattered through volume so large that one
##   camera move swings tessellation load by order of magnitude, which flat helix
##   `main.fillSceneForBenchmark` builds for `--timings` deliberately does not.
## Three sizes of one arrangement, so cost reads as slope rather than single number.
##   `ScaleOrrery.Nearest` (60), `Neighbourhood` (360, default) and `Catalogue` (5038,
##   two handles short of pool). Every one is same construction truncated at different depth.
## Also claim about world, made to scale.
##   One world unit is one astronomical unit (`KILOMETRES_PER_ASTRONOMICAL_UNIT`). Every distance
##   is real distance and every drawn radius real radius: Sol 0.00465 units wide, Earth one unit
##   out, Proxima 268,000 units out. Nothing is compressed to preference.
##   Every system but ours is real star known to carry planets, at real distance in real
##   direction, carrying planets it really has at real semi-major axes.
##     From `neighbourhood.nim`, shipped snapshot of NASA Exoplanet Archive;
##     `PROVENANCE.md` records query, date and acknowledgement, and what is checked.
##     Planet archive records no semi-major axis for is left out, not placed by guess.
##   `SOL` is our own, hand-written and modelled same way, at origin rest are measured
##   from. Nothing stands at `POSITION_ORRERY`'s coordinate but Sol itself.
##   Every moon rings its planet in its real orbit plane; see `normalOfMoon`.
## Each system is stored about its own sun, as anchor of every object it holds.
##   Sun, planets, moons and plane are built about origin, then anchored at sun's place: star
##   millions of units out keeps its planets to their own scale, never to that distance's.
##   Star with no planet is anchored at itself. Sol's anchor is world origin, so its objects
##   stand about Sol as built; four in horizon are anchored there too.
## Every place and every frame is algebra's construction, since where thing stands is its.
##   Node is meet of two planes, bearing is meet of ground with vertical plane, each lean
##   and each phase is motor's turn, and each body is point plus weightless direction.
##   Only reading of catalogue's angles into direction stays closed form.
##   Turns every star shares are built once, at compile time (`TURN_ECLIPTIC`).
##   Cost: on JS backend largest size builds in about 150 ms against 21 ms in closed form,
##     since each star pays one sandwich and one point of dense multivectors. Once at
##     build, never per frame; measured pairs in `PROVENANCE.md`, Demo.
##   Stated simplifications, each one claim short of ephemeris: planets ring Sol in
##   ecliptic itself, inclinations dropped (Mercury's 7 degrees largest); where on its
##   ring any body stands is spread by rule, not read off date; neighbour systems lie flat.
##
##   |------------------|-------------------------------------|--------------------------|
##   | Object             | Built from                          | Present when             |
##   |------------------|-------------------------------------|--------------------------|
##   | star             | placed at its real position         | always                   |
##   | planets          | placed, ringing it at real radii    | axis is on record        |
##   | ecliptic plane   | `star ∧ along ∧ across`, its plane  | two planets are placed   |
##   |------------------|-------------------------------------|--------------------------|
##
## Sol alone also carries moons and only two finite lines in whole scene: `sol ∧ earth`
## and `earth ∧ luna`.
##   Line is infinite, so each crosses entire frame; more read as line traffic.
## Four objects in horizon, two of them points because only one can make plane.
##   Earth lies in Sol's ecliptic, so `att(sol ∧ earth)` sits *on* horizon line
##   ecliptic gives.
##   Luna's ring is tipped out of it by its real 5.16 degrees, so `att(earth ∧ luna)`
##   sits off that line and spans horizon plane with it. See horizon block in
##   `constructOrrery`.
## `objectsOf(scale)` objects on nose at every size, asserted.
##   Walk passes over system too large for room left rather than stopping on it.
##   Only Sol's block and four in horizon are fixed; everything between is however many
##   real stars fit.
## Colour says what thing is, not which system it belongs to; see `LUT_INK_BY_ROLE`.
##
## Shared by desktop (`main.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import pga
import ./[boundary, camera, euclid, motors, neighbourhood, objects, scene, starfield,
  tessellate]



#[ Type Definitions ]#

type
  Role* {.pure.} = enum  ## Define what object in arrangement is.
    Sun,  ## Body at system's own centre.
    Planet,  ## Body ringing its sun.
    Moon,  ## Body ringing planet.
    Derived,  ## Anything joined or taken attitude of: every line, every plane.

  SolBody* = object  ## Define one body of modelled solar system.
    name*: string  ## What it is called, also label it carries in scene.
    role*: Role  ## What kind of body it is.
    distance*: float  ## How far it really stands from Sol, in astronomical units.
    kilometres_radius*: float  ## Real mean radius, in kilometres; see `radiusDrawnOf`.

  SolMoon* = object  ## Define one real moon of modelled solar system.
    name*: string  ## What it is called, also label it carries in scene.
    parent*: int  ## Which entry of `SOL` it rings.
    kilometres_orbit*: float  ## Real semi-major axis about that parent, in kilometres.
    kilometres_radius*: float  ## Real mean radius, in kilometres; see `radiusDrawnOf`.
    inclination*: float  ## Real inclination of its orbit to its reference plane, in degrees.
    node*: float  ## Real longitude of its ascending node on that plane, in degrees.
    pole_ascension*: float  ## Right ascension of reference plane's pole, in degrees, J2000.
    pole_declination*: float  ## Declination of reference plane's pole, in degrees, J2000.

  System* = object  ## Define where one system stands and which way its ring is spun.
    reach*: float  ## How far its sun stands from `POSITION_ORRERY`, in world units.
    toward*: Direction  ## Which way it lies from that centre, unit, in ecliptic frame.
    spin*: float  ## Where first planet stands on its ring, in radians.

  ScaleOrrery* {.pure.} = enum
    ## Name how deep into catalogue one build of arrangement reaches.
    ##   Three sizes of same scene, not three scenes: Sol entire, then real stars outward,
    ##   then four objects in horizon, truncated at different depth.
    ##   They exist to be *benchmarked against each other*, so cost of change reads as
    ##   slope.
    Nearest  ## Sol entire, and about dozen of its nearest real neighbours.
    Neighbourhood  ## Default everywhere: scene worth looking at, quick to build.
    Catalogue  ## Load case, two handles short of pool.



#[ Layout ]#

const
  POSITION_ORRERY* = Position(x: 0.0, y: 0.0, z: 0.0)
    ## Fix coordinate every system's placement is measured from, and demo's camera aims at.
    ##   Sol stands here, at world origin, where axes cross and grid is ruled from:
    ##   neighbourhood is real map measured from our own star.
    ##   Not lifted to keep southern systems above ground; they stand below it, where they
    ##   are.

  KILOMETRES_PER_ASTRONOMICAL_UNIT* = 149_597_870.7
    ## Fix how many kilometres one astronomical unit is, IAU 2012 definition.
    ##   One world unit is one astronomical unit: every radius in kilometres and every
    ##   orbit in kilometres is divided by this and nothing else.

  ASTRONOMICAL_UNITS_PER_PARSEC* = 206_264.806
    ## Fix how many astronomical units one parsec is, 648,000 over pi.
    ##   Every star's distance in parsecs is multiplied by this and nothing else.

  OBLIQUITY_ECLIPTIC = degToRad(23.4392911)
    ## Fix angle Earth's equator leans from ecliptic, J2000, in radians.
    ##   Both catalogues and every moon's reference pole are equatorial, right ascension and
    ##   declination; scene's ground is ecliptic, plane Sol's planets ring in. Turning
    ##   equatorial direction about x axis by this puts it in ecliptic frame; see
    ##   `toEcliptic`.

  ASCENSION_POLE_ECLIPTIC = 270.0
  DECLINATION_POLE_ECLIPTIC = 90.0 - 23.4392911
    ## Name ecliptic's own north pole in equatorial terms.
    ##   Reference pole of moons whose elements are given against ecliptic itself.

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
  ]  ## One system modelling real one: ours, to scale.
    ##   Distances are real semi-major axes in astronomical units, and are radii planets
    ##   ring Sol at: one unit is one astronomical unit.
    ##   Sol and eight planets, nothing else: moons are table of own, since moon's
    ##   distance is measured from parent and one field holding two units is wrong.
    ##   Only system whose bodies are named and whose planets stand at different radii,
    ##   so it gets own constructor.

  MOONS*: array[21, SolMoon] = [
    SolMoon(name: "luna", parent: 3, kilometres_orbit: 384_400.0,
      kilometres_radius: 1_737.4, inclination: 5.16, node: 125.08,
      pole_ascension: ASCENSION_POLE_ECLIPTIC, pole_declination: DECLINATION_POLE_ECLIPTIC),
    SolMoon(name: "phobos", parent: 4, kilometres_orbit: 9_376.0,
      kilometres_radius: 11.1, inclination: 1.1, node: 169.2,
      pole_ascension: 317.7, pole_declination: 52.9),
    SolMoon(name: "deimos", parent: 4, kilometres_orbit: 23_463.0,
      kilometres_radius: 6.2, inclination: 1.8, node: 54.3,
      pole_ascension: 316.6, pole_declination: 53.5),
    SolMoon(name: "io", parent: 5, kilometres_orbit: 421_800.0,
      kilometres_radius: 1_821.6, inclination: 0.0, node: 0.0,
      pole_ascension: 268.1, pole_declination: 64.5),
    SolMoon(name: "europa", parent: 5, kilometres_orbit: 671_100.0,
      kilometres_radius: 1_560.8, inclination: 0.5, node: 184.0,
      pole_ascension: 268.1, pole_declination: 64.5),
    SolMoon(name: "ganymede", parent: 5, kilometres_orbit: 1_070_400.0,
      kilometres_radius: 2_634.1, inclination: 0.2, node: 58.5,
      pole_ascension: 268.2, pole_declination: 64.6),
    SolMoon(name: "callisto", parent: 5, kilometres_orbit: 1_882_700.0,
      kilometres_radius: 2_410.3, inclination: 0.3, node: 309.1,
      pole_ascension: 268.7, pole_declination: 64.8),
    SolMoon(name: "mimas", parent: 6, kilometres_orbit: 185_540.0,
      kilometres_radius: 198.2, inclination: 1.6, node: 66.2,
      pole_ascension: 40.6, pole_declination: 83.5),
    SolMoon(name: "enceladus", parent: 6, kilometres_orbit: 238_040.0,
      kilometres_radius: 252.1, inclination: 0.0, node: 0.0,
      pole_ascension: 40.6, pole_declination: 83.5),
    SolMoon(name: "tethys", parent: 6, kilometres_orbit: 294_670.0,
      kilometres_radius: 531.1, inclination: 1.1, node: 273.0,
      pole_ascension: 40.6, pole_declination: 83.5),
    SolMoon(name: "dione", parent: 6, kilometres_orbit: 377_420.0,
      kilometres_radius: 561.4, inclination: 0.0, node: 0.0,
      pole_ascension: 40.6, pole_declination: 83.5),
    SolMoon(name: "rhea", parent: 6, kilometres_orbit: 527_070.0,
      kilometres_radius: 763.8, inclination: 0.3, node: 133.7,
      pole_ascension: 40.6, pole_declination: 83.5),
    SolMoon(name: "titan", parent: 6, kilometres_orbit: 1_221_870.0,
      kilometres_radius: 2_574.7, inclination: 0.3, node: 78.6,
      pole_ascension: 36.4, pole_declination: 84.0),
    SolMoon(name: "iapetus", parent: 6, kilometres_orbit: 3_560_840.0,
      kilometres_radius: 734.5, inclination: 7.6, node: 86.5,
      pole_ascension: 288.7, pole_declination: 78.9),
    SolMoon(name: "miranda", parent: 7, kilometres_orbit: 129_900.0,
      kilometres_radius: 235.8, inclination: 4.4, node: 100.9,
      pole_ascension: 77.311, pole_declination: 15.175),
    SolMoon(name: "ariel", parent: 7, kilometres_orbit: 190_900.0,
      kilometres_radius: 578.9, inclination: 0.0, node: 0.0,
      pole_ascension: 77.311, pole_declination: 15.175),
    SolMoon(name: "umbriel", parent: 7, kilometres_orbit: 266_000.0,
      kilometres_radius: 584.7, inclination: 0.1, node: 174.8,
      pole_ascension: 77.311, pole_declination: 15.175),
    SolMoon(name: "titania", parent: 7, kilometres_orbit: 436_300.0,
      kilometres_radius: 788.4, inclination: 0.1, node: 29.5,
      pole_ascension: 77.311, pole_declination: 15.175),
    SolMoon(name: "oberon", parent: 7, kilometres_orbit: 583_500.0,
      kilometres_radius: 761.4, inclination: 0.1, node: 76.8,
      pole_ascension: 77.311, pole_declination: 15.175),
    SolMoon(name: "triton", parent: 8, kilometres_orbit: 354_760.0,
      kilometres_radius: 1_353.4, inclination: 157.3, node: 178.1,
      pole_ascension: 299.8, pole_declination: 43.1),
    SolMoon(name: "nereid", parent: 8, kilometres_orbit: 5_513_800.0,
      kilometres_radius: 170.0, inclination: 5.1, node: 319.5,
      pole_ascension: ASCENSION_POLE_ECLIPTIC, pole_declination: DECLINATION_POLE_ECLIPTIC),
  ]  ## Major named satellites of modelled system, real semi-major axes and radii in km,
    ## real orbit orientation.
    ##   Major ones, not all: some three hundred are known, most unnamed rocks; these are
    ##   ones reader recognises, stated here so what is drawn is what is written down.
    ##   Orientation is JPL's mean elements: inclination and node against each moon's own
    ##   reference plane, that plane named by its pole. Luna and Nereid against ecliptic;
    ##   Uranus's five against Uranus's equator, pole being spin's own (RA 77.311, Dec
    ##   15.175), antipode of IAU's north, so their orbits read prograde about it as
    ##   elements state them; rest against local Laplace planes. `normalOfMoon` turns each
    ##   into one unit normal in scene's ecliptic frame. `PROVENANCE.md` names source and
    ##   date.
    ##   `radiusDrawnOf` says what is done to radius's: divided into astronomical units,
    ##   nothing more.
    ##   `parent` indexes `SOL`; static block below checks every one is planet.

  INDEX_SOL_EARTH = 3
    ## Name which entry of `SOL` is Earth.
    ##   Named rather than searched: one body arrangement's orbit line joins, load-bearing
    ##   in three places. Held to `SOL`'s name by compile-time check below.

  INDEX_SOL_NEPTUNE = 8
    ## Name which entry of `SOL` is outermost planet, body setting system's reach.
    ##   Named rather than counted from end, which slid reach onto wrong body when last
    ##   entry was removed. Held by compile-time check below.

  INDEX_MOON_LUNA = 0
    ## Name which entry of `MOONS` is Luna.
    ##   Second finite line joins it to Earth, and horizon plane exists only because
    ##   Luna's ring is tipped out of ecliptic; load-bearing as `INDEX_SOL_EARTH` is.

  SYSTEM_SOL = System(reach: 0.0, toward: Direction(x: 1.0, y: 0.0, z: 0.0), spin: 0.4)
    ## Place Sol.
    ##   At `POSITION_ORRERY` itself, reach zero: Sol is origin every other system is
    ##   measured from, so it is one system not placed at all.
    ##   `toward` is then any direction; x axis, so its ring counts from x.
    ##   Its ecliptic lies flat on plane z = 0, which world axes x and y span; every other
    ##   direction in scene is measured against it.

  RADIUS_ORRERY* = SOL[INDEX_SOL_NEPTUNE].distance
    ## Fix how far out demo's camera stands back to hold Sol's system to Neptune.
    ##   Opening frame holds our own system whole and nothing beyond it: nearest star
    ##   stands nine thousand Neptune orbits out, and frame holding it would show one dot.
    ##   Every body is under least dot from here; reader dollies in to any of them.
    ##   Folded from table, so it moves when `SOL` does.

const
  COUNT_OBJECT_HORIZON = 4
    ## Count objects closing block comes to.
    ##   Four, not three: two points in horizon, because one cannot make plane. See
    ##   horizon block in `constructOrrery`.

const LUT_INK_BY_ROLE*: array[Role, Ink] = [
  Role.Sun: Ink.Copper,
  Role.Planet: Ink.Cobalt,
  Role.Moon: Ink.Rose,
  Role.Derived: Ink.Olive,
]  ## Colour every object by what it is, not by which system it belongs to.
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



#[ Frames ]#

func directionEquatorial(ascension, declination: float): Direction =
  ## Report unit direction right ascension and declination name, both in degrees.
  ##   Equatorial frame: x toward vernal equinox, z along Earth's spin axis.
  let
    along = degToRad(ascension)
    up = degToRad(declination)
  Direction(x: cos(up) * cos(along), y: cos(up) * sin(along), z: sin(up))


func planeAbout(normal: Direction): Multivector =
  ## Build plane through origin at right angles to `normal`, i.e. 𝐨 ∧ (𝐨 ∧ 𝐧)☆.
  ##   Weight expansion of origin by line along `normal`: plane holding point, square to line.
  ##   Faces against line (read by probe), so only meet of two such planes is read, never
  ##     normal of one; flip shared by both operands cancels in meet.
  1.0.e4 ∧☆ (1.0.e4 ∧ normal.toMultivector)


func nodeAscending(normal, pole: Direction): Option[Direction] =
  ## Report where plane of unit `normal` climbs through plane of unit `pole`, as unit direction.
  ##   Meet of two planes through origin, i.e. line both hold, read by its attitude.
  ##   Sense is ascending: going round `normal` as right hand turns, plane crosses other
  ##     there toward side `pole` points to. Suite pins sense for every moon.
  ##   None where two planes are one, as they then meet in no line: judged against scale
  ##   one, as both normals are unit.
  direction(planeAbout(normal) ∨ planeAbout(pole), scale = 1.0)


func turnedAbout(d, axis: Direction; radians: float): Direction =
  ## Turn direction `d` about unit `axis` by `radians`, as right hand turns, through motor.
  ##   Direction lifts to horizon point, which has no place, so line through origin carries
  ##     it as line through any point along `axis` would.
  ##   Keeps `d` where turn or read refuses; neither can for unit `axis`, as `turnAbout`
  ##     refuses only line with no direction, and rigid motion keeps horizon in horizon.
  let turn = turnAbout(1.0.e4 ∧ axis.toMultivector, radians)
  if turn.isNone: return d
  directionHorizon(d.toMultivector.carried(turn.get)).get(d)


const
  TURN_ECLIPTIC = turnAbout(1.0.e4 ∧ 1.0.e1, -OBLIQUITY_ECLIPTIC).get
    ## Hold motor turning equatorial frame into ecliptic, about equinox, which is x axis.
    ##   Built at compile time: every star and every moon turns by this one motor, and
    ##     building it is most of what turn costs on JS backend (`PROVENANCE.md`, Demo).
  TURN_ECLIPTIC_REVERSED = ~∘TURN_ECLIPTIC
    ## Hold its antireverse, so each turn pays sandwich alone.
  TURN_QUARTER_UP = turnAbout(1.0.e4 ∧ 1.0.e3, 0.5 * PI).get
    ## Hold motor turning quarter turn about world up.
    ##   Carries flat ring's bearing to its second direction.
  TURN_QUARTER_UP_REVERSED = ~∘TURN_QUARTER_UP  ## Hold its antireverse.
  AXIS_UP = 1.0.e4 ∧ 1.0.e3
    ## Hold world's vertical axis through origin; joined with direction, it spans that
    ##   direction's vertical plane.
  PLANE_GROUND = groundPlane()  ## Hold plane `z = 0`, which every bearing lies in.


func turnedBy(d: Direction; motor, motor_reversed: Multivector): Direction =
  ## Turn direction `d` through motor caller already holds, with its antireverse.
  ##   Keeps `d` where read refuses, which rigid motion of horizon point never causes.
  directionHorizon(d.toMultivector.carried(motor, motor_reversed)).get(d)


func toEcliptic(d: Direction): Direction =
  ## Turn equatorial direction into ecliptic frame, scene's own, through motor.
  ##   Turn about shared x axis, vernal equinox, by `OBLIQUITY_ECLIPTIC` against right hand:
  ##   ecliptic's pole lands on +z, world axis z.
  ##   Change of frame is still rigid turn, which algebra owns.
  turnedBy(d, TURN_ECLIPTIC, TURN_ECLIPTIC_REVERSED)


func bearingOf*(toward: Direction): Option[Direction] =
  ## Report level direction `toward` leans along, unit and outward: its bearing on ground.
  ##   Meet of ground with plane joining origin, world up and `toward`; sense taken from
  ##     `toward` by inner product, since meet's own runs with order of operands.
  ##   None where `toward` stands straight up or down, or is no direction: it leans nowhere.
  ##   Exported for `showOrrery`'s camera, and for suite.
  let level = direction((AXIS_UP ∧ toward.toMultivector) ∨ PLANE_GROUND, scale = norm(toward))
  if level.isNone: return
  if innerOf(level.get.toMultivector, toward.toMultivector) < 0.0: some(-level.get)
  else: level


func normalOfMoon*(moon: SolMoon): Direction =
  ## Report unit normal of moon's real orbit plane, in scene's ecliptic frame.
  ##   Elements name plane against reference plane whose pole is given: node is where
  ##   orbit climbs through reference plane, measured from where reference plane climbs
  ##   through equator; inclination is how far orbit leans from reference plane about that
  ##   node. One meet and two turns, both right-handed about their axes, then whole thing
  ##   turned into ecliptic frame.
  ##   Reference pole along equator's own z, ecliptic's never, leaves node's origin
  ##   undefined; no moon's is, and guard takes equinox for it.
  ##   Exported so suite pins Luna's lean, Triton's retrograde ring and Uranus's tipped
  ##   family against it.
  let
    pole = directionEquatorial(moon.pole_ascension, moon.pole_declination)
    origin_node =
      nodeAscending(pole, Direction(x: 0, y: 0, z: 1)).get(Direction(x: 1, y: 0, z: 0))
    node = turnedAbout(origin_node, pole, degToRad(moon.node))
    normal = turnedAbout(pole, node, degToRad(moon.inclination))
  normal.toEcliptic


func nodeOfRing(normal: Direction): Direction =
  ## Report where ring of unit `normal` climbs through ecliptic, i.e. where its phase counts from.
  ##   Ascending node on ground, so ring turned onward from it about `normal` climbs.
  ##   Ring lying flat has no node, and takes x axis.
  nodeAscending(normal, UP_WORLD).get Direction(x: 1, y: 0, z: 0)



#[ Construction ]#

func sunOf(system: System): Position =
  ## Report where system's own sun stands: `reach` out from `POSITION_ORRERY` along `toward`.
  pointAlong(POSITION_ORRERY, system.toward, system.reach)


func spanOf(system: System): (Direction, Direction) =
  ## Report two directions system's own plane is spanned by, its bearing first.
  ##   One place orientation is written down, so planet placed on its ecliptic is on very
  ##   plane scene holds.
  ##   Flat: every system's plane is level with Sol's ecliptic. First direction is bearing of
  ##   its sun, so first planet's phase reads outward; second is first turned quarter turn
  ##   about world up. Real orientation of any neighbour's plane is not on record, and none
  ##   is claimed.
  ##   Sol leans nowhere, standing at origin, and takes x axis.
  let along = bearingOf(system.toward).get(Direction(x: 1, y: 0, z: 0))
  (along, turnedBy(along, TURN_QUARTER_UP, TURN_QUARTER_UP_REVERSED))


func ringed(centre: Position; node, normal: Direction; radius, angle: float): Position =
  ## Report point on ring of `radius` about `centre`, `angle` on from `node` about `normal`.
  ##   Node turned by phase through motor, then point that far along it from `centre`.
  ##   Turned direction rather than point carried about ring's own axis: that axis stands
  ##     up to 1e9 units out, and motor about it rounds point at that scale.
  pointAlong(centre, turnedAbout(node, normal, angle), radius)


func angleRing(spin: float; index, count: int): float =
  ## Report where one body of ring of `count` stands, in radians.
  ##   Ring of `count` is spread over `count + 1` steps.
  ##     Even spacing puts pair of two diametrically opposite, collinear with parent, and
  ##     plane wedged from three collinear points has no clean grade and draws nothing
  ##     while holding handle. `addPlane` exists because of it.
  spin + TAU * float(index) / float(count + 1)


func radiusDrawnOf*(kilometres: float): float =
  ## Report how large body of real radius `kilometres` is drawn, in world units.
  ##   Real radius in astronomical units, since one world unit is one: Sol 0.00465,
  ##   Earth 0.0000426, Phobos 0.000000074. Every body is under least dot until reader
  ##   dollies close enough to resolve it, and then it is its real size.
  ##   Exported so suite pins bodies against it.
  kilometres / KILOMETRES_PER_ASTRONOMICAL_UNIT


func radiusOfMoon(moon: SolMoon): float =
  ## Report how far moon of `MOONS` rings its planet's centre in scene, in world units.
  ##   Real semi-major axis in astronomical units, from parent's centre, as it is measured.
  moon.kilometres_orbit / KILOMETRES_PER_ASTRONOMICAL_UNIT


func placedOf*(star: Star): int =
  ## Report how many of real star's planets are placed: those with semi-major axis on record.
  ##   Archive stores missing axis as `0.0` (`neighbourhood.nim`); planet with none is left
  ##   out rather than placed by guess, since distance is whole of what this scene claims.
  ##   Exported so suite can count what is left out.
  result = 0
  for which in star.first ..< star.first + star.planets:
    if PLANETS[which].axis_semi_major > 0.0: inc result


static:
  doAssert SOL[INDEX_SOL_EARTH].name == "earth",
    &"`INDEX_SOL_EARTH` must name Earth, whose orbit line joins it to Sol and whose " &
    &"attitude is the horizon point; got `{SOL[INDEX_SOL_EARTH].name}`."
  doAssert SOL[INDEX_SOL_NEPTUNE].name == "neptune",
    &"`INDEX_SOL_NEPTUNE` must name the outermost planet, which sets the system's reach; " &
    &"got `{SOL[INDEX_SOL_NEPTUNE].name}`."
  doAssert MOONS[INDEX_MOON_LUNA].name == "luna",
    &"`INDEX_MOON_LUNA` must name Luna, whose line to Earth gives the horizon plane " &
    &"its attitude; got `{MOONS[INDEX_MOON_LUNA].name}`."
  doAssert SOL[0].role == Role.Sun, &"`SOL` must open with its star; got `{SOL[0].role}`."
  for moon in MOONS:
    doAssert moon.parent > 0 and moon.parent < len(SOL) and
        SOL[moon.parent].role == Role.Planet,
      &"Every moon must ring a planet of `SOL`, see `MOONS`' own `parent` column; got " &
      &"`{moon.parent}` for `{moon.name}`."
    doAssert moon.kilometres_orbit > SOL[moon.parent].kilometres_radius + moon.kilometres_radius,
      &"Every moon must ring its planet outside both bodies, or the two discs overlap; got " &
      &"`{moon.kilometres_orbit}` km for `{moon.name}`."


func addHorizon(
  scene: var Scene, geometry: Multivector, label: string, expected: Kind, now: float
) =
  ## Add one of closing objects in horizon, refusing anything that is not one.
  ##   Same guard `addPlane` is, against second way of getting it wrong.
  ##     Attitude of grade-4 volume is horizon plane only if point and plane wedged to
  ##     make it are genuinely apart: `planet[0] ∧ ecliptic` gave zero, `ecliptic` being
  ##     plane `planet[0]` built.
  ##     `storyboard`'s seeds carry same warning about `o` and `ground`.
  doAssert kindOf(geometry) == some(expected) and isHorizon(geometry),
    &"Orrery's `{label}` must be {expected} in horizon, its operands genuinely apart; got " &
    &"`{kindOf(geometry)}`."
  scene.addObject(geometry, label, LUT_INK_BY_ROLE[Role.Derived], now)


func addPlane(scene: var Scene, plane: Anchored, label: string, now: float, centre: Position) =
  ## Add derived plane, refusing anything that is not one.
  ##   `centre` is where its circle centres, about its anchor.
  ##   Plane is joined from sun and two directions its planets ring along, never from
  ##   three of its points: join of three points millions of units out sums products of
  ##   their coordinates and cancels to noise, one part in ten of plane's own normal,
  ##   where point and two directions is same plane with nothing to cancel.
  ##   Guard stays: directions that fail to span leave multivector of no clean grade,
  ##   which `objects.kindOf` reports as nothing to draw.
  doAssert kindOf(plane.local) == some(Kind.Plane),
    &"Orrery must derive `{label}` from a point and two directions spanning a plane; got " &
    &"`{kindOf(plane.local)}`."
  scene.addObject(plane, label, LUT_INK_BY_ROLE[Role.Derived], now, some(centre))


func objectsOf*(star: Star): int =
  ## Report how many scene objects one real star comes to.
  ##   Exported because suite bounds how far fill may depart from nearest-first with it.
  ##   Itself, planets with axis on record, and ecliptic plane it earns with two placed
  ##   planets to span one.
  ##     Every further object would be invention; great majority come to one object.
  let placed = placedOf(star)
  1 + placed + (if placed >= 2: 1 else: 0)


func systemAt(star: Star): System =
  ## Report where real star stands.
  ##   Right ascension and declination are real direction, distance real length:
  ##   placement is coordinate conversion, not layout.
  ##     Catalogue frame is equatorial and scene's is ecliptic, so direction is turned
  ##     by `toEcliptic` first; declination read straight as height stood every star
  ##     23 degrees off where it is against Sol's planets.
  ##   `spin` is one thing here *not* real: where on its ring each planet stands.
  ##     Spread by star's own coordinates so no two systems' phases agree; deterministic,
  ##     stated as arbitrary.
  System(
    reach: star.parsecs * ASTRONOMICAL_UNITS_PER_PARSEC,
    toward: directionEquatorial(star.ascension, star.declination).toEcliptic,
    spin: star.declination,
  )


const OBJECTS_SOL* = len(SOL) + len(MOONS) + 3
  ## Count scene objects Sol comes to.
  ##   Star and planets, moons, ecliptic, and two lines that are only finite lines in
  ##   whole arrangement.


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
    ##   Folded from tables rather than written beside them, so it moves when they do.

  OBJECTS_ORRERY_MIN* = OBJECTS_FIXED_ORRERY + objectsOf(STARS[0])
    ## Count smallest arrangement there is.
    ##   Sol entire, block in horizon, and one neighbour: neighbourhood of one system is
    ##   no neighbourhood, so no size may stop short of nearest star.
    ##   Floor rather than preference.
    ##     Below `OBJECTS_FIXED_ORRERY` scene cannot hold Sol, and block in horizon takes
    ##     attitudes of Sol's objects.
    ##   Folded, so it moves when `SOL`, `MOONS` or catalogue's nearest entry does.

static:
  for scale in ScaleOrrery:
    doAssert objectsOf(scale) >= OBJECTS_ORRERY_MIN,
      &"`ScaleOrrery.{scale}` must ask for at least `{OBJECTS_ORRERY_MIN}` objects, Sol, the " &
      &"block in horizon and the nearest neighbour; got `{objectsOf(scale)}`."

const
  RISE_ORRERY_SHOWN* = 1.4
    ## Fix how steeply demo's eye stands over Sol: its height over its run across.
    ##   About 54 degrees up. Opening camera, at third of that, is nearly edge-on to
    ##   systems on planes: every ring collapses to line and arrangement reads as starburst.
    ##   Steeper also makes sphere fit honest.
    ##   Not overhead: straight down, plane of ecliptic disappears into own horizon.
    ##   Bearing is left where reader had it.

  INSET_ORRERY_SHOWN* = 24.0
    ## Fix how many pixels of margin arrangement is framed with, per side.
    ##   Wider than framed selection takes (`framing.INSET_POINT_SHOWN`).
    ##     Fitted tightly, Neptune's marker ring touches frame edge, and marker is drawn
    ##     in pixels about dot solve knows nothing about.


func constructSol(scene: var Scene; now: float; ecliptic, orbit, tether: var Multivector) =
  ## Build modelled solar system, handing back three objects horizon block takes attitudes of.
  ##   Planets ring Sol at their own real semi-major axes rather than one shared radius,
  ##   whole reason this is not generic template.
  ##   Built about origin and anchored at Sol's place, as every system is; that place is
  ##   world origin, so three handed back stand about it too.
  let
    anchor_sol = sunOf(SYSTEM_SOL)
    place_sol = ORIGIN_WORLD
    (along, across) = spanOf(SYSTEM_SOL)
    sol = place_sol.toMultivector
  var
    placed: array[len(SOL), Multivector]
    places: array[len(SOL), Position]
  for index, body in SOL:
    # Step phases by golden angle, so no two planets line up from opening camera.
    #   Earth's line then passes through none.
    let
      angle = SYSTEM_SOL.spin + 2.4 * float(index)
      place =
        case body.role
        of Role.Sun: place_sol
        of Role.Planet: ringed(place_sol, along, UP_WORLD, body.distance, angle)
        of Role.Moon, Role.Derived: place_sol  # `SOL` holds sun and planets; see its check.
    places[index] = place
    placed[index] = place.toMultivector
    scene.addObject(
      Anchored(anchor: anchor_sol, local: placed[index]),
      body.name,
      LUT_INK_BY_ROLE[body.role],
      now,
      radius = radiusDrawnOf(body.kilometres_radius),
    )
  # Ring every moon about planet it really rings, in plane it really rings in.
  #   Phase is measured from ring's ascending node on ecliptic and stepped by golden angle
  #   per moon, so two moons of one planet never stand together and none stands on its
  #   node, where its direction from its planet would lie in ecliptic.
  var placement_moons: array[len(MOONS), Multivector]
  for index, moon in MOONS:
    let
      normal = normalOfMoon(moon)
      place = ringed(places[moon.parent], nodeOfRing(normal), normal, radiusOfMoon(moon),
        SYSTEM_SOL.spin + 2.4 * float(index))
    placement_moons[index] = place.toMultivector
    scene.addObject(
      Anchored(anchor: anchor_sol, local: placement_moons[index]),
      moon.name,
      LUT_INK_BY_ROLE[Role.Moon],
      now,
      radius = radiusDrawnOf(moon.kilometres_radius),
    )
  # Span ecliptic by Sol and two directions planets ring along; see `addPlane`.
  ecliptic = sol ∧ along.toMultivector ∧ across.toMultivector
  orbit = sol ∧ placed[INDEX_SOL_EARTH]
  # Join two lines in whole arrangement, which horizon block is built from.
  #   Earth lies *in* ecliptic, Luna's ring is tipped out of it, and that difference
  #   makes horizon plane constructible.
  tether = placed[INDEX_SOL_EARTH] ∧ placement_moons[INDEX_MOON_LUNA]
  let ink = LUT_INK_BY_ROLE[Role.Derived]
  scene.addObject(Anchored(anchor: anchor_sol, local: orbit), "sol ∧ earth", ink, now)
  scene.addObject(Anchored(anchor: anchor_sol, local: tether), "earth ∧ luna", ink, now)
  addPlane(scene, Anchored(anchor: anchor_sol, local: ecliptic), "ecliptic sol", now, place_sol)


func constructOrrery*(scene: var Scene, scale: ScaleOrrery = SCALE_ORRERY_DEFAULT, now = 0.0) =
  ## Fill scene with every system in turn, then four objects in horizon.
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
  #   Nothing invented: star earns ecliptic with two placed planets, and great majority
  #   are single point.
  #   Each built about origin and anchored at its sun; see module header.
  #   Walk outward until scene holds what size asks for, less horizon block added after.
  #   System too large for room left is passed over, not stopped on: `break` reached
  #   pivot only where counts summed exactly.
  #     Cost is that last few systems in are not strictly nearest left, invisible in
  #     field of thousands.
  for star in STARS:
    if scene.len + objectsOf(star) > objectsOf(scale) - COUNT_OBJECT_HORIZON: continue
    let
      system = systemAt(star)
      anchor_sun = sunOf(system)
      sun = ORIGIN_WORLD.toMultivector
      count_placed = placedOf(star)
    # No radius on record for any star or planet but our own; see `mesh.RADIUS_OBJECT_LEAST`.
    scene.addObject(
      Anchored(anchor: anchor_sun, local: sun),
      star.name,
      LUT_INK_BY_ROLE[Role.Sun],
      now,
      radius = RADIUS_OBJECT_LEAST,
    )
    if count_placed == 0: continue
    # Spanned only for star with planet to ring: most stars have none, and each span is
    #   meet and sandwich of dense multivectors.
    let (along, across) = spanOf(system)

    # Planet with no axis on record is left out; see `placedOf`.
    #   Guarded by block rather than `continue`: compiled to JS, `continue` here placed
    #   every axis-less planet regardless, where C skipped them; block reads same on both.
    var which_placed = 0
    for which in 0..<star.planets:
      let planet = PLANETS[star.first+which]
      if planet.axis_semi_major > 0.0:
        let place = ringed(ORIGIN_WORLD, along, UP_WORLD, planet.axis_semi_major,
          angleRing(system.spin, which_placed, count_placed))
        inc which_placed
        scene.addObject(
          Anchored(anchor: anchor_sun, local: place.toMultivector),
          planet.name,
          LUT_INK_BY_ROLE[Role.Planet],
          now,
          radius = RADIUS_OBJECT_LEAST,
        )

    # Span plane from ring's own directions; star with single placed planet gets none.
    if count_placed >= 2:
      let ecliptic = Anchored(
        anchor: anchor_sun, local: sun ∧ along.toMultivector ∧ across.toMultivector
      )
      addPlane(scene, ecliptic, "ecliptic " & star.name, now, ORIGIN_WORLD)

  # Close in horizon, every one attitude of one of Sol's objects.
  #   Attitude drops one grade and lands in horizon: line gives point there, plane gives
  #   line.
  #   Two points, and only second can make plane.
  #     `att(sol ∧ earth)` lies along ecliptic, so sits *on* horizon line it gives;
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
  scene: var Scene;
  camera: var Camera;
  width, height: int;
  scale: ScaleOrrery = SCALE_ORRERY_DEFAULT;
  now = 0.0;
) =
  ## Replace scene with arrangement and stand camera back to hold Sol's system.
  ##   Whole preset in one place, because both front-ends open on it.
  ##   Arrives as replay: `scene.replayFrom` restamps whole construction, so nearest
  ##   system appears first, as loaded `.rgascene` does.
  ##     Restamped after fact so beat is fitted to whole arrival.
  ##   Camera stands back far enough to hold Neptune's ring, aims at Sol, pitches up over
  ##   it.
  ##     Solved: `distanceFitting` is same sphere-tangent solve framed selection uses.
  ##     Pitched first, since solve reads camera handed; bearing is left where reader had
  ##     it.
  ##   Not here: anything either front-end keeps of own (born stamps, selection, undo
  ##   timeline), bookkeeping about scene rather than part of it.
  scene.restoreFrom initScene()
  constructOrrery(scene, scale, now)
  scene.replayFrom(now)
  # Stand eye on reader's own bearing: eye goes back along it, and up by `RISE_ORRERY_SHOWN`
  #   of each unit back. Bearing is meet of ground with plane holding sight and world up;
  #   away is sum of two weightless points, read back unit.
  #   Sight straight up or down has no bearing, and reference sight stands in for it.
  let
    bearing = bearingOf(camera.frame.forward).get(FORWARD_REFERENCE)
    away = directionHorizon(
      add(wedge(-1.0, bearing.toMultivector), wedge(RISE_ORRERY_SHOWN, UP_WORLD.toMultivector)),
    ).get(UP_WORLD)
  # Pitched camera is what solve reads: it carries new pivot and sight, and distance it
  #   carries does not reach solve.
  let pitched = camera.placed(
    stanceFacing(pointAlong(POSITION_ORRERY, away, camera.distance), POSITION_ORRERY),
  )
  let fitted = distanceFitting(RADIUS_ORRERY, pitched, width, height, INSET_ORRERY_SHOWN)
  camera = camera.placed(stanceFacing(POSITION_ORRERY + fitted * away, POSITION_ORRERY))
