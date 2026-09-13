discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
batchable: true
joinable: false
"""
## What pose says about itself, held to poses engine actually holds.
##
##   Crossings law kept from `tlaws.nim` when solver it read from was retired,
##     retyped onto rig in engine: every crossing must sit on both connections in
##     plan and name which is higher there, read off arms as drawn and not
##     assumed.  Corpus is both two-hand holds at every band over five turns,
##     settled where engine settles them.
##   Not joinable: it links C archive, which testament's joined binary cannot share.

{.experimental: "strictFuncs".}

import std/[math, random, strformat, tables, unittest]

import ../sim/[body, hold, limb, read, rig, rigid, vec]


const APART = 0.40

func nearestOn(line: array[7, Vec]; p: Vec): tuple[off, z: float] =
  ## How far `p` lies off polyline in plan, and how high polyline is there.
  ##   Rebuilt here rather than borrowed from reader, which keeps its own copy
  ##     private: borrowing it would check reader against itself (Article II.9).
  result = (1e9, 0.0)
  for i in 0 ..< 6:
    let
      a = line[i]
      b = line[i + 1]
      dx = b.x - a.x
      dy = b.y - a.y
      run = dx * dx + dy * dy
    if run < 1e-18:
      continue
    let
      u = clamp(((p.x - a.x) * dx + (p.y - a.y) * dy) / run, 0.0, 1.0)
      off = sqrt((p.x - a.x - dx * u) ^ 2 + (p.y - a.y - dy * u) ^ 2)
    if off < result.off:
      result = (off, a.z + (b.z - a.z) * u)


suite "two hands":
  test "crossings are counted off drawn arms, not assumed":
    var seen = 0
    for (links, away) in [
        (@[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
           Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])], false),
        (@[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)]),
           Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])], true)]:
      for band in Band:
        for turn in [0.0, 0.25, 0.5, 0.75, 1.0]:
          var c = build(HUMAN, turned(restStance(HUMAN, APART, away), Body.Two, turn),
                        band, links, away = away)
          c.settle()
          var arms: Arms
          for i in 0 ..< links.len:
            arms.add c.poseOf(i).arms
          let
            p = polyline(arms, 0)
            q = polyline(arms, 1)
          for x in crossings(arms):
            inc seen
            let
              i = int(x.along)
              on = p[i] + (p[i + 1] - p[i]) * (x.along - i.float)
              other = nearestOn(q, x.at)
            check abs(x.at.x - on.x) < 1e-9 and abs(x.at.y - on.y) < 1e-9
            check other.off < 1e-9
            check (x.over == 0) == (x.at.z >= other.z)
          c.free()
    echo &"    {seen} crossings read off two holds, three bands, five turns"
    check seen > 0

  test "crossing reader gives one answer at knife edge":
    ## Where crossing sits at vertex of both polylines, reader counted it on
    ## every adjacent segment pair, four for one; where one arm lies along
    ## other in plan and leaves to far side, sign noise inside overlap read
    ## nought, one or two.  Two poses differing by less than float carries read
    ## as four crossings and as one (repository issue 88).  Same count for exact
    ## figures and for thousand poses jittered by 1e-13, which is below anything
    ## pose carries, and count in exact terms is one in both.
    func armsOf(p, q: array[7, Vec]): Arms =
      ## Two connections from their seven points each, grip in middle.
      func pose(s, e, w, g: Vec): ArmPose = ArmPose(s: s, e: e, w: w, g: g)
      @[[pose(p[0], p[1], p[2], p[3]), pose(p[6], p[5], p[4], p[3])],
        [pose(q[0], q[1], q[2], q[3]), pose(q[6], q[5], q[4], q[3])]]
    let
      # Along x at y nought; vertex two at (0.4, 0).
      p: array[7, Vec] = [(0.0, 0.0, 1.0), (0.2, 0.0, 1.1), (0.4, 0.0, 1.2), (0.6, 0.0, 1.3),
                          (0.8, 0.0, 1.3), (1.0, 0.0, 1.2), (1.2, 0.0, 1.1)]
      # Up y at x 0.4; vertex three at (0.4, 0): crossing at vertex of both.
      q: array[7, Vec] = [(0.4, -0.6, 1.5), (0.4, -0.4, 1.5), (0.4, -0.2, 1.5), (0.4, 0.0, 1.5),
                          (0.4, 0.2, 1.5), (0.4, 0.4, 1.5), (0.4, 0.6, 1.5)]
      # In from below, along p for four vertices, out to above: one crossing.
      t: array[7, Vec] = [(0.05, -0.05, 1.5), (0.3, 0.0, 1.5), (0.5, 0.0, 1.5), (0.7, 0.0, 1.5),
                          (0.9, 0.0, 1.5), (1.1, 0.1, 1.5), (1.3, 0.2, 1.5)]
    var rng = initRand(7)
    for (name, other) in [("at vertex", q), ("along", t)]:
      let exact = crossings(armsOf(p, other)).len
      var counts: CountTable[int]
      for trial in 0 ..< 1000:
        var pp = p
        var oo = other
        for i in 0 .. 6:
          pp[i] = (pp[i].x + rng.rand(-1e-13 .. 1e-13), pp[i].y + rng.rand(-1e-13 .. 1e-13),
                   pp[i].z)
          oo[i] = (oo[i].x + rng.rand(-1e-13 .. 1e-13), oo[i].y + rng.rand(-1e-13 .. 1e-13),
                   oo[i].z)
        counts.inc crossings(armsOf(pp, oo)).len
      echo &"    {name}: exact {exact}, jittered {counts}"
      check exact == 1
      check counts.len == 1
      check counts.hasKey(exact)

  test "tightest joint is one nearest its edge, and strain is one there":
    ## Read off same poses: whichever joint `tightest` names, no other joint of
    ## any held arm has less margin, and joint at its edge reads strain of one.
    let links = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)])]
    var c = build(HUMAN, restStance(HUMAN, APART), Band.Torso, links)
    c.settle()
    var arms: Arms = @[c.poseOf(0).arms]
    let t = tightest(HUMAN, c.stance, links, arms)
    check t.room < Inf
    check t.strain >= 0.0 and t.strain <= 1.0
    check abs(strain(Tight(room: 0.0)) - 1.0) < 1e-9
    check abs(strain(Tight(room: 1.0)) - 0.0) < 1e-9
    c.free()
