discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
batchable: true
joinable: false
"""
## Hold rig built on engine to what tape and clinical tables say, and to geometry.
##
##   Every law here failed on tree before it passed on this one.  First caught rig laid
##     flat on floor: trunk's turn was built from project's three axes in project's
##     order, where engine's basis puts body's forward on its negative z, and both
##     dancers lay down with shoulders at ankle height.
##   Second law is why engine's readings may be trusted at all: engine reports wrist's
##     cone, and same angle is worked out from three drawn points.  They agree, so
##     every other law may ask engine rather than measure pose again.
##     Law itself was wrong first time it ran, and rig was right: `angleBetween` takes
##     units, and raw vectors gave it constant eighty-nine degrees whatever pose was.
##   Not joinable: it links C archive, which testament's joined binary cannot share.

{.experimental: "strictFuncs".}

import std/[math, unittest]

import ../sim/[body, hold, limb, rig, rigid, vec, walk]


const
  SHAKE = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Plainest hold there is: one hand each, face to face.
  APART = 1.10 ## Where that hold leaves joints freest, to nearest centimetre.
  SLACK = 3.0 * PI / 180.0 ## Engine's limits are solved, not clamped, so joint may
                           ## stand this far past its end for one step and come back.


proc rest(band = Band.Torso; apart = APART): Couple =
  result = build(HUMAN, facing(HUMAN, apart), band, SHAKE)
  result.settle()


suite "two dancers in rigid body engine":

  test "each dancer stands where tape puts them":
    let
      c = rest()
      p = c.poseOf(0)
    for k in 0 .. 1:
      let h = c.links[0].ends[k]
      check dist(p.arms[k].s, shoulder(HUMAN, c.stance[h.body], h.arm)) < 0.001
    check abs(p.arms[0].s.z - HUMAN.shoulderUp) < 0.001
    c.free()

  test "engine's own reading of wrist is angle its three points make":
    for apart in [0.6, 0.9, 1.1]:
      let
        c = rest(apart = apart)
        p = c.poseOf(0)
      for k in 0 .. 1:
        let
          a = p.arms[k]
          drawn = angleBetween(unit(a.w - a.e), unit(a.g - a.w))
        check abs(p.wrist[k] - drawn) < 0.01
      c.free()

  test "hands that are joined stay joined":
    for band in Band:
      let
        c = rest(band)
        p = c.poseOf(0)
      check p.apart < PARTED
      check c.stopOf(0) == Stop.None
      c.free()

  test "no joint goes past what rig allows it, at rest or through quarter":
    for band in Band:
      var c = rest(band)
      for quarter in 0 .. 3:
        let p = c.poseOf(0)
        for k in 0 .. 1:
          let (lo, hi) = twistEnds(HUMAN, c.links[0].ends[k].arm)
          check p.twist[k] >= lo - SLACK
          check p.twist[k] <= hi + SLACK
          check p.bend[k] >= HUMAN.range[Dof.Bend].lo - SLACK
          check p.bend[k] <= HUMAN.range[Dof.Bend].hi + SLACK
          check p.wrist[k] <= HUMAN.range[Dof.Wrist].hi + SLACK
        c.turn(Body.Two, 0.25, 600)
      c.free()

  test "couple stand further off than their two torsos allow":
    check restApart(HUMAN, Band.Torso, SHAKE) >= touching(HUMAN) + CLEAR

  test "couple do not stand as close as they are permitted to":
    ## Least of several starts at infinity.  Started at nought, which is what
    ## float comes as, every distance scores nought, first one tried wins, and
    ## couple stand chest to chest whatever their joints say.
    for band in Band:
      check restApart(HUMAN, band, SHAKE) > touching(HUMAN) + CLEAR + PACE

  test "at rest every joint is free to move either way":
    ## Where couple stand cannot be chosen on `margin`, which counts stop with no
    ## ease as costing nothing to lean on: that reads straight elbow as perfectly
    ## comfortable and sends couple out to arm's length, where no turn is possible
    ## at all.  Freedom to move is what standing asks about.
    for band in Band:
      let c = rest(band, restApart(HUMAN, band, SHAKE))
      check roomAt(c, c.poseOf(0), 0) > 0.0
      c.free()

  test "no arm swings past what rig allows while hold still stands":
    ## Engine holds elbow, wrist and twist.  Extension and adduction across body
    ## it was never given -- rig states them as two ranges of their own and engine
    ## offers one cone -- so nothing holds them but this reading.  Asking only once
    ## hands had parted meant nothing held them at all: follow could turn two whole
    ## turns and more with their arm wrapped away behind them, and sweep called it
    ## free.
    let sw = swept(HUMAN, Band.Torso, SHAKE, most = 1.5, apart = APART)
    check sw.restHolds
    for w in [sw.pos, sw.neg]:
      for m in w.moments:
        for k in 0 .. 1:
          let
            h = SHAKE[0].ends[k]
            j = joints(m.stance[h.body], h.arm, m.arms[0][k])
          check margin(HUMAN.range[Dof.Extend], j.extend) >= 0.0
          check margin(HUMAN.range[Dof.Across], j.across) >= 0.0
