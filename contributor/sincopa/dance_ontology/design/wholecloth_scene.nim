## Find what whole-cloth page draws at one place of its play, between two recorded moments.
##
##   Kept apart from `wholecloth_turns`, which reads document as it loads, so law reads lookup
##     through node with no browser (`tests/test_wholecloth_scene.nim`, Article IX.5).
##     Cost: scene and its parts are exported, for `wholecloth_turns` that draws them.
##   Page plays sweep by place, not by turn: recording gives each moment its own place
##     (`turns.frame`), so every pose planned way stands at one turn is drawn, one step of play
##     each, and turn waits there (Architect, pull request 629, 2026-10-17, D2).
##     Cost: two chains held above play longer per pass (`turns.frames`).
##   Recording is read in place as `JsObject` through `std/jsffi`, never copied into Nim
##     objects, since every copy on JS backend is deep (STYLE.md §7).  Only scene at one place
##     is built as Nim value, interpolated afresh.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/jsffi


type
  Dancer* {.pure.} = enum
    ## Define who: lead (square marks, deep ink) or follow (round marks, plain ink).
    Lead, Follow

  Vector2* = array[2, float]  ## Define point on page, or centre in millimetres.

  Vector3* = array[3, float]  ## Define joint in millimetres: across, along, up.

  BodyPose* = object  ## Define where one dancer stands and faces at one moment.
    centre*: Vector2
    facing*: float

  Connection* = object
    ## Define one rope at one moment: four joints each side, and simulation's words.
    lead*, follow*: array[4, Vector3]
    lead_says*, follow_says*: cstring
    cross*: JsObject  ## Crossings from data, `undefined` where none; read in place.

  Scene* = object  ## Define everything drawn at one place, interpolated between two moments.
    turn*, strain*: float
    is_ok*, is_reseed*: bool
    worst*: cstring  ## Joint nearest its edge, or empty.
    bodies*: array[Dancer, BodyPose]
    connections*: array[2, Connection]
    connection_count*: int  ## Live bound of `connections`.


func placeOf*(moment: JsObject): float =
  ## Read where moment stands on page's play, as recording writes it (`turns.frame`).
  moment.place.to(float)


func placeAt*(frames: JsObject, turn: float): float =
  ## Find place on play where page draws `turn`: one for one with turn between two moments.
  ##   Where several poses stand at `turn`, pose plan stood last there.
  ##     Both ways run outward from turn 0, and negative way is written back to front
  ##       (`turns.frames`): so first pose along play below turn 0, last one above it.
  ##   Past either end moment, one for one with turn: walk's block lies one step past moment
  ##     it refused, and page draws end moment there at block's own turn.
  ##   Turn itself for sweep with no moment, where nothing is drawn.
  let count = frames.length.to(int)
  if count == 0: return turn

  # Past either end moment, move place one for one with turn.
  let
    turn_first = frames[0].turn.to(float)
    turn_last = frames[count-1].turn.to(float)
  if turn < turn_first: return placeOf(frames[0]) + (turn - turn_first)
  if turn > turn_last: return placeOf(frames[count-1]) + (turn - turn_last)

  # Find last moment at or before `turn` by bisection on turns, which never fall.
  var
    lower = 0
    upper = count - 1
  while upper - lower > 1:
    let middle = (lower + upper) shr 1
    if frames[middle].turn.to(float) <= turn: lower = middle else: upper = middle

  # Where poses stand at `turn`, take one plan stood last: first along play below turn 0, last
  #   above it.  Bisection never reads last moment, so it is read here.  Equality is exact,
  #   since turn asked for is one recording wrote or else falls between two.
  let
    turn_a = frames[lower].turn.to(float)
    turn_b = frames[upper].turn.to(float)
  if turn_b == turn and turn >= 0.0: return placeOf(frames[upper])
  if turn_a == turn:
    if turn < 0.0:
      while lower > 0 and frames[lower-1].turn.to(float) == turn: dec lower
    return placeOf(frames[lower])

  # Between two moments, move place as turn moves; exact equality only guards division.
  let
    place_a = placeOf(frames[lower])
    u = if turn_b == turn_a: 0.0 else: max(0.0, min(1.0, (turn - turn_a) / (turn_b - turn_a)))
  place_a + (placeOf(frames[upper]) - place_a) * u


func interpolate[N: static int](destination: var array[N, float]; a, b: JsObject; u: float) =
  ## Interpolate one vector between two moments into `destination`, reading both in place.
  ##   Writes into scene's own storage: returning array would copy it on assignment.
  for i in 0..<destination.len:
    let value_a = a[i].to(float)
    destination[i] = value_a + (b[i].to(float) - value_a) * u


func fillScene*(scene: var Scene, frames: JsObject, place: float): bool =
  ## Fill `scene` at `place`: joints interpolated between moments either side, words from nearer.
  ##   False, and `scene` untouched, for empty sweep: rest pose that never held draws nothing.
  ##   Turn is interpolated as joints are, so it waits while poses at one turn play.
  ##     Past either end moment it moves one for one with place, while joints hold end pose.
  ##   Fills caller's storage rather than returning `Option[Scene]`, which deep copied
  ##     scene twice per call on JS backend (read in emitted JS: `some` copies its
  ##     parameter into constructor, then constructor into result).
  let count = frames.length.to(int)
  if count == 0: return false

  # Find moments either side of `place` by bisection on their places.
  var
    lower = 0
    upper = count - 1
  while upper - lower > 1:
    let middle = (lower + upper) shr 1
    if placeOf(frames[middle]) <= place: lower = middle else: upper = middle

  # Weigh later moment by where `place` falls between; exact equality only guards division.
  let
    moment_a = frames[lower]
    moment_b = frames[upper]
    place_a = placeOf(moment_a)
    place_b = placeOf(moment_b)
    u =
      if place_b == place_a: 0.0
      else: max(0.0, min(1.0, (place - place_a) / (place_b - place_a)))
    near = if u < 0.5: moment_a else: moment_b
    strain_a = moment_a.strain.to(float)
    turn_a = moment_a.turn.to(float)
    turn_b = moment_b.turn.to(float)
  scene.turn =
    if place < place_a: turn_a + (place - place_a)
    elif place > place_b: turn_b + (place - place_b)
    else: turn_a + (turn_b - turn_a) * u
  scene.is_ok = near.ok.to(bool)
  scene.is_reseed = near.reseed.to(bool)
  scene.strain = strain_a + (moment_b.strain.to(float) - strain_a) * u
  scene.worst = near.worst.to(cstring)
  scene.connection_count = moment_a.connections.length.to(int)

  # Interpolate bodies, then every joint of every rope; words come from nearer moment.
  for who in Dancer:
    let
      body_a = moment_a.bodies[ord(who)]
      body_b = moment_b.bodies[ord(who)]
      facing_a = body_a.facing.to(float)
    interpolate(scene.bodies[who].centre, body_a.centre, body_b.centre, u)
    scene.bodies[who].facing = facing_a + (body_b.facing.to(float) - facing_a) * u
  for i in 0..<scene.connection_count:
    let
      connection_a = moment_a.connections[i]
      connection_b = moment_b.connections[i]
      connection_near = near.connections[i]
    for k in 0..<4:
      interpolate(scene.connections[i].lead[k], connection_a.lead[k], connection_b.lead[k], u)
      interpolate(scene.connections[i].follow[k], connection_a.follow[k], connection_b.follow[k], u)
    scene.connections[i].lead_says = connection_near.leadSays.to(cstring)
    scene.connections[i].follow_says = connection_near.followSays.to(cstring)
    scene.connections[i].cross = connection_near.cross
  true
