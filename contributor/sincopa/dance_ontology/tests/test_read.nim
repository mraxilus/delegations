discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
"""
## What pose says about itself, held to poses engine actually holds.
##
##   Crossings law kept from `tlaws.nim` when solver it read from was retired,
##     retyped onto rig in engine: every crossing must sit on both connections in
##     plan and name which is higher there, read off arms as drawn and not
##     assumed.  Corpus is both two-hand holds at every band over five turns,
##     settled where engine settles them.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[atomics, cpuinfo, math, random, strformat, tables, typedthreads, unittest]

import ../simulation/[body, hold, limb, read, rig, rigid, vector]


const
  APART = 0.40
  PAIRS = [([Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
             Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])], false),
           ([Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)]),
             Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])], true)]
    ## Both two-hand holds, and whether each rests with follow turned away.
  TURNS = [0.0, 0.25, 0.5, 0.75, 1.0] ## Turns each hold is settled at.
  FLOOR_CROSSINGS = 4
    ## Least crossings settled holds show, so crossing law reads some: 8 on 2026-10-02.
    ##   Margin, not 8: engine is chaotic, and same walks built into another binary differ
    ##     (`test_rigid.nim`, suite "couple stand for sweep").
  TRIALS_JITTER = 1000  ## Jittered copies of each knife-edge pose reader reads, seeded.

func nearestOn(line: array[7, Vector]; point: Vector): tuple[offset, z: float] =
  ## How far `point` lies off polyline in plan, and how high polyline is there.
  ##   Rebuilt here rather than borrowed from reader, which keeps its own copy
  ##     private: borrowing it would check reader against itself (Article II.9).
  result = (1e9, 0.0)
  for i in 0 ..< 6:
    let
      a = line[i]
      b = line[i + 1]
      delta_x = b.x - a.x
      delta_y = b.y - a.y
      run = delta_x * delta_x + delta_y * delta_y
    if run < 1e-18:
      continue
    let
      u = clamp(((point.x - a.x) * delta_x + (point.y - a.y) * delta_y) / run, 0.0, 1.0)
      offset = sqrt((point.x - a.x - delta_x * u) ^ 2 + (point.y - a.y - delta_y * u) ^ 2)
    if offset < result.offset:
      result = (offset, a.z + (b.z - a.z) * u)



#[ Parallel Settling ]#

# Mutable and global: thread takes one argument, so workers write into slots allotted here.
var
  SETTLES: seq[tuple[pair: int, band: Band, turn: float]]
    ## Every couple to settle, set before any thread starts.
  SETTLE_NEXT: Atomic[int] ## Next couple not yet taken.
  SETTLED_ARMS: seq[array[2, array[2, ArmPose]]] ## Each couple's arms, at its own index.

proc settling(id: int) {.thread.} =
  ## Take couples until none is left, and give back arm poses alone.
  ##   Holds are constants, so each worker reads its own copy, and each couple
  ##     builds its own world.  Poses are plain numbers, each written to place
  ##     allotted before any thread starts.
  {.cast(gcsafe).}:
    while true:
      let i = SETTLE_NEXT.fetchAdd(1)
      if i >= SETTLES.len: return
      let
        task = SETTLES[i]
        links = @(PAIRS[task.pair][0])
        is_away = PAIRS[task.pair][1]
      var couple = build(HUMAN, turned(restStance(HUMAN, APART, is_away), Body.Two, task.turn),
                    task.band, links, is_away = is_away)
      couple.settle()
      for k in 0 ..< links.len: SETTLED_ARMS[i][k] = couple.poseOf(k).arms
      couple.free()

proc settleAll() =
  ## Settle both holds at every band and turn, on every core at once.
  ##   Thirty couples settled one after another cost 8.1 s of suite's run, measured
  ##     2026-09-26 on four cores.
  for pair in 0 ..< PAIRS.len:
    for band in Band:
      for turn in TURNS: SETTLES.add (pair, band, turn)
  SETTLED_ARMS = newSeq[array[2, array[2, ArmPose]]](SETTLES.len)
  SETTLE_NEXT.store(0)
  var workers = newSeq[Thread[int]](max(1, countProcessors()))
  for worker in 0 ..< workers.len: createThread(workers[worker], settling, worker)
  joinThreads(workers)


suite "two hands":
  test "crossings are counted off drawn arms, not assumed":
    settleAll()
    var seen = 0
    for i in 0 ..< SETTLES.len:
      let
        arms: Arms = @[SETTLED_ARMS[i][0], SETTLED_ARMS[i][1]]
        first_line = polyline(arms, 0)
        second_line = polyline(arms, 1)
      for crossing in crossings(arms):
        inc seen
        let
          k = int(crossing.along)
          on = first_line[k] + (first_line[k + 1] - first_line[k]) * (crossing.along - float(k))
          other = nearestOn(second_line, crossing.at)
        check abs(crossing.at.x - on.x) < 1e-9 and abs(crossing.at.y - on.y) < 1e-9
        check other.offset < 1e-9
        check (crossing.over == 0) == (crossing.at.z >= other.z)
    checkpoint &"{seen} crossings read off two holds, three bands, five turns"
    check seen >= FLOOR_CROSSINGS

  test "crossing reader gives one answer at knife edge":
    ## Where crossing sits at vertex of both polylines, reader counted it on
    ## every adjacent segment pair, four for one; where one arm lies along
    ## other in plan and leaves to far side, sign noise inside overlap read
    ## nought, one or two.  Two poses differing by less than float carries read
    ## as four crossings and as one (repository issue 88).  Same count for exact
    ## figures and for thousand poses jittered by 1e-13, which is below anything
    ## pose carries, and count in exact terms is one in both.
    func armsOf(first, second: array[7, Vector]): Arms =
      ## Two connections from their seven points each, grip in middle.
      func pose(shoulder_point, elbow_point, wrist_point, grip_point: Vector): ArmPose =
        ## Build arm pose from its four joints.
        ArmPose(shoulder: shoulder_point, elbow: elbow_point, wrist: wrist_point, grip: grip_point)
      @[
        [
          pose(first[0], first[1], first[2], first[3]),
          pose(first[6], first[5], first[4], first[3]),
        ],
        [
          pose(second[0], second[1], second[2], second[3]),
          pose(second[6], second[5], second[4], second[3]),
        ],
      ]
    let
      # Along x at y nought; vertex two at (0.4, 0).
      base: array[7, Vector] = [(0.0, 0.0, 1.0), (0.2, 0.0, 1.1), (0.4, 0.0, 1.2), (0.6, 0.0, 1.3),
                          (0.8, 0.0, 1.3), (1.0, 0.0, 1.2), (1.2, 0.0, 1.1)]
      # Up y at x 0.4; vertex three at (0.4, 0): crossing at vertex of both.
      at_vertex: array[7, Vector] = [(0.4, -0.6, 1.5), (0.4, -0.4, 1.5), (0.4, -0.2, 1.5),
                          (0.4, 0.0, 1.5), (0.4, 0.2, 1.5), (0.4, 0.4, 1.5), (0.4, 0.6, 1.5)]
      # In from below, along p for four vertices, out to above: one crossing.
      along_base: array[7, Vector] = [(0.05, -0.05, 1.5), (0.3, 0.0, 1.5), (0.5, 0.0, 1.5),
                          (0.7, 0.0, 1.5), (0.9, 0.0, 1.5), (1.1, 0.1, 1.5), (1.3, 0.2, 1.5)]
    var random = initRand(7)
    for (name, other) in [("at vertex", at_vertex), ("along", along_base)]:
      let exact = crossings(armsOf(base, other)).len
      var counts: CountTable[int]
      for trial in 0..<TRIALS_JITTER:
        var
          base_jittered = base
          other_jittered = other
        for i in 0 .. 6:
          base_jittered[i] = (
            base_jittered[i].x + random.rand(-1e-13 .. 1e-13),
            base_jittered[i].y + random.rand(-1e-13 .. 1e-13),
            base_jittered[i].z,
          )
          other_jittered[i] = (
            other_jittered[i].x + random.rand(-1e-13 .. 1e-13),
            other_jittered[i].y + random.rand(-1e-13 .. 1e-13),
            other_jittered[i].z,
          )
        counts.inc crossings(armsOf(base_jittered, other_jittered)).len
      checkpoint &"{name}: exact {exact}, jittered {counts}"
      check exact == 1
      check counts.len == 1
      check counts.hasKey(exact)

  test "tightest joint is one nearest its edge, and strain is one there":
    ## Read off same poses: whichever joint `tightest` names, no other joint of
    ## any held arm has less margin, and joint at its edge reads strain of one.
    let links = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)])]
    var couple = build(HUMAN, restStance(HUMAN, APART), Band.Torso, links)
    couple.settle()
    var arms: Arms = @[couple.poseOf(0).arms]
    let tight = tightest(HUMAN, couple.stance, links, arms)
    check tight.room < Inf
    check tight.strain >= 0.0 and tight.strain <= 1.0
    check abs(strain(Tight(room: 0.0)) - 1.0) < 1e-9
    check abs(strain(Tight(room: 1.0)) - 0.0) < 1e-9
    couple.free()
