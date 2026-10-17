## Find what whole-cloth page draws at one place of its play, between two recorded moments.
##
##   Split from `wholecloth_turns`, which reads document as it loads, so law reads this lookup
##     through node with no browser (`tests/test_wholecloth_scene.nim`, Article IX.5).
##     Cost: scene and its parts are exported, for `wholecloth_turns` that draws them.
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
  ## Read where moment stands on page's play: its turn.
  moment.turn.to(float)


func interpolate[N: static int](destination: var array[N, float]; a, b: JsObject; u: float) =
  ## Interpolate one vector between two moments into `destination`, reading both in place.
  ##   Writes into scene's own storage: returning array would copy it on assignment.
  for i in 0..<destination.len:
    let value_a = a[i].to(float)
    destination[i] = value_a + (b[i].to(float) - value_a) * u


func fillScene*(scene: var Scene, frames: JsObject, place: float): bool =
  ## Fill `scene` at `place`: joints interpolated between moments either side, words from nearer.
  ##   False, and `scene` untouched, for empty sweep: rest pose that never held draws nothing.
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
  scene.turn = place
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
