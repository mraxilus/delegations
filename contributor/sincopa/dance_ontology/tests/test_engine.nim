discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
"""
## Hold rigid body engine to what this project needs of it, before anything is built on it.
##
##   Two laws and no more: that engine runs at all from Nim, and that two arms stop each
##     other. Second is whole reason engine is here -- pose search this project had let
##     arms pass through one another, and engine is answer to that, so it is what must be
##     checked rather than assumed.
##   Suite drives build that makes library it links (Article IX.6): importing module runs
##     `tools/build.nim engine` at compile time, so no machine needs verb run by hand.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, unittest]

import ../simulation/engine


proc world(): WorldId =
  ## World with no gravity and nothing asleep: every question here is about contact.
  var definition = defaultWorld()
  definition.gravity = initVector(0, 0, 0)
  definition.should_sleep = false
  createWorld(addr definition)

proc capsule(world_id: WorldId; x: float): BodyId =
  ## Upright limb-thick capsule, standing where told.
  var body_definition = defaultBody()
  body_definition.kind = BODY_DYNAMIC
  body_definition.position = Position(x: x, y: 0.0, z: 0.0)
  result = createBody(world_id, addr body_definition)
  var
    shape_definition = defaultShape()
    capsule = Capsule(
      center1: initVector(0, -0.15, 0),
      center2: initVector(0, 0.15, 0),
      radius: 0.045,
    )
  discard createCapsule(result, addr shape_definition, addr capsule)


suite "the engine this project turns couples with":
  test "engine runs, and a body falls as far as gravity says":
    ## Cheapest proof binding is right: struct laid out wrong gives wrong figure here
    ##   rather than failing to link.
    var definition = defaultWorld()
    definition.should_sleep = false
    let
      world_id = createWorld(addr definition)
      gravity = abs(float(definition.gravity.y))
    check gravity > 9.0     # Engine's own, not this project's; only its order matters.
    var body_definition = defaultBody()
    body_definition.kind = BODY_DYNAMIC
    body_definition.position = Position(x: 0.0, y: 10.0, z: 0.0)
    let body = createBody(world_id, addr body_definition)
    var
      shape_definition = defaultShape()
      capsule = Capsule(
        center1: initVector(0, -0.1, 0),
        center2: initVector(0, 0.1, 0),
        radius: 0.05,
      )
    discard createCapsule(body, addr shape_definition, addr capsule)
    for i in 1 .. 240:
      step(world_id, cfloat(1.0 / 240.0), 8)
    let fell = 10.0 - positionOf(body).at.y
    # Half g t squared, with one second walked.
    check abs(fell - 0.5 * gravity) < 0.05

  test "two arms cannot stand inside one another":
    ## Reason engine is here at all.  Two capsules are started deep inside each other
    ##   and must part: arms of this project are capsules of this thickness, and pose
    ##   search that came before let them lie through one another unremarked.
    let
      world_id = world()
      body_a = capsule(world_id, -0.01)
      body_b = capsule(world_id, 0.01)
    check abs(positionOf(body_b).at.x - positionOf(body_a).at.x) < 0.03
    for i in 1 .. 240:
      step(world_id, cfloat(1.0 / 240.0), 8)
    let apart = abs(positionOf(body_b).at.x - positionOf(body_a).at.x)
    checkpoint("centres ended " & $apart & " m apart")
    # Two radii is where they touch; anything less is one standing inside other.
    check apart >= 2.0 * 0.045

  test "body touched by more things than eight reports every one":
    ## Contacts are read into room caller gives, and rest are dropped unsaid.
    ##   Forearm wound into chain touches nine things at once, and asked with room
    ##   for eight it lost its deepest: two forearms stood 22 mm through each other
    ##   with nothing said.  Engine says how much room body needs, and that is what
    ##   is asked for.
    let world_id = world()
    var body_definition = defaultBody()
    body_definition.kind = BODY_DYNAMIC
    body_definition.position = Position(x: 0.0, y: 0.0, z: 0.0)
    let centre = createBody(world_id, addr body_definition)
    var
      shape_definition = defaultShape()
      big = Capsule(center1: initVector(0, -0.3, 0), center2: initVector(0, 0.3, 0), radius: 0.2)
    discard createCapsule(centre, addr shape_definition, addr big)
    const AROUND = 10
    var around: seq[BodyId]
    for i in 0 ..< AROUND:
      # Ring of thin capsules, each poking into big one from its own side.
      let angle = 2.0 * PI * float(i) / float(AROUND)
      var thin_definition = defaultBody()
      thin_definition.kind = BODY_DYNAMIC
      thin_definition.position = Position(x: 0.22 * cos(angle), y: 0.0, z: 0.22 * sin(angle))
      let thin_body = createBody(world_id, addr thin_definition)
      var thin = Capsule(
        center1: initVector(0, -0.02, 0),
        center2: initVector(0, 0.02, 0),
        radius: 0.02,
      )
      discard createCapsule(thin_body, addr shape_definition, addr thin)
      around.add thin_body
    step(world_id, cfloat(1.0 / 240.0), 8)
    let room = touchRoom(centre)
    check room >= AROUND
    var seen = newSeq[Touch](max(1, int(room)))
    let reported = touches(centre, addr seen[0], cint(seen.len))
    checkpoint("room " & $room & ", contacts reported " & $reported)
    check reported == AROUND
    var eight: array[8, Touch]
    check touches(centre, addr eight[0], 8) == 8
