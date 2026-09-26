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

import std/[math, unittest]

import ../sim/engine


proc world(): WorldId =
  ## World with no gravity and nothing asleep: every question here is about contact.
  var def = defaultWorld()
  def.gravity = vec(0, 0, 0)
  def.enableSleep = false
  createWorld(addr def)

proc capsule(w: WorldId; x: float): BodyId =
  ## Upright limb-thick capsule, standing where told.
  var bd = defaultBody()
  bd.kind = Dynamic
  bd.position = Pos(x: x, y: 0.0, z: 0.0)
  result = createBody(w, addr bd)
  var sd = defaultShape()
  var cap = Capsule(center1: vec(0, -0.15, 0), center2: vec(0, 0.15, 0), radius: 0.045)
  discard createCapsule(result, addr sd, addr cap)


suite "the engine this project turns couples with":
  test "engine runs, and a body falls as far as gravity says":
    ## Cheapest proof binding is right: struct laid out wrong gives wrong figure here
    ##   rather than failing to link.
    var def = defaultWorld()
    def.enableSleep = false
    let w = createWorld(addr def)
    let g = abs(def.gravity.y.float)
    check g > 9.0     # Engine's own, not this project's; only its order matters.
    var bd = defaultBody()
    bd.kind = Dynamic
    bd.position = Pos(x: 0.0, y: 10.0, z: 0.0)
    let body = createBody(w, addr bd)
    var sd = defaultShape()
    var cap = Capsule(center1: vec(0, -0.1, 0), center2: vec(0, 0.1, 0), radius: 0.05)
    discard createCapsule(body, addr sd, addr cap)
    for i in 1 .. 240:
      step(w, (1.0 / 240.0).cfloat, 8)
    let fell = 10.0 - positionOf(body).at.y
    # Half g t squared, with one second walked.
    check abs(fell - 0.5 * g) < 0.05

  test "two arms cannot stand inside one another":
    ## Reason engine is here at all.  Two capsules are started deep inside each other
    ##   and must part: arms of this project are capsules of this thickness, and pose
    ##   search that came before let them lie through one another unremarked.
    let w = world()
    let a = capsule(w, -0.01)
    let b = capsule(w, 0.01)
    check abs(positionOf(b).at.x - positionOf(a).at.x) < 0.03
    for i in 1 .. 240:
      step(w, (1.0 / 240.0).cfloat, 8)
    let apart = abs(positionOf(b).at.x - positionOf(a).at.x)
    checkpoint("centres ended " & $apart & " m apart")
    # Two radii is where they touch; anything less is one standing inside other.
    check apart >= 2.0 * 0.045

  test "body touched by more things than eight reports every one":
    ## Contacts are read into room caller gives, and rest are dropped unsaid.
    ##   Forearm wound into chain touches nine things at once, and asked with room
    ##   for eight it lost its deepest: two forearms stood 22 mm through each other
    ##   with nothing said.  Engine says how much room body needs, and that is what
    ##   is asked for.
    let w = world()
    var bd = defaultBody()
    bd.kind = Dynamic
    bd.position = Pos(x: 0.0, y: 0.0, z: 0.0)
    let centre = createBody(w, addr bd)
    var sd = defaultShape()
    var big = Capsule(center1: vec(0, -0.3, 0), center2: vec(0, 0.3, 0), radius: 0.2)
    discard createCapsule(centre, addr sd, addr big)
    const AROUND = 10
    var around: seq[BodyId]
    for i in 0 ..< AROUND:
      # Ring of thin capsules, each poking into big one from its own side.
      let angle = 2.0 * PI * i.float / AROUND.float
      var od = defaultBody()
      od.kind = Dynamic
      od.position = Pos(x: 0.22 * cos(angle), y: 0.0, z: 0.22 * sin(angle))
      let b = createBody(w, addr od)
      var thin = Capsule(center1: vec(0, -0.02, 0), center2: vec(0, 0.02, 0), radius: 0.02)
      discard createCapsule(b, addr sd, addr thin)
      around.add b
    step(w, (1.0 / 240.0).cfloat, 8)
    let room = touchRoom(centre)
    check room >= AROUND
    var seen = newSeq[Touch](max(1, room.int))
    let n = touches(centre, addr seen[0], seen.len.cint)
    checkpoint("room " & $room & ", contacts reported " & $n)
    check n == AROUND
    var eight: array[8, Touch]
    check touches(centre, addr eight[0], 8) == 8
