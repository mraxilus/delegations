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

import std/[math, strformat, unittest]

import ../sim/[body, hold, read, rig, rigid, vec]


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
                        band, links)
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
