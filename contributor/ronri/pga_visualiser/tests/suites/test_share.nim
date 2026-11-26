## Run `Share` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../src/pga_visualiser/[boundary, share]
when not defined(js):
  import std/times
  import ../../src/desktop/sampler



suite "Share":
  test "a page function is owned by the module its mangled name ends in":
    # Names as JS backend emits them into built page, one for each kind of owner.
    let names = [
      ("HEX5BHEX5D_u0__OOZOOZdependenciesZreplicationsOmraxilusOgitlabOcomZlengyelZ" &
        "projective95geometric95algebra95illuminatedZpgaZmultivectors", Owner.Pga),
      ("wedge_u12__OOZOOZdependenciesZreplicationsOmraxilusOgitlabOcomZlengyelZ" &
        "projective95geometric95algebra95illuminatedZpga", Owner.Pga),
      ("classify_u3__OOZpga95visualiserZobjects", Owner.Algebra),
      ("carried_u1__OOZpga95visualiserZmotors", Owner.Algebra),
      ("toMultivector_u1__OOZpga95visualiserZboundary", Owner.Boundary),
      ("normalize_u0__OOZpga95visualiserZeuclid", Owner.Euclidean),
      ("addDome_u0__OOZpga95visualiserZmesh", Owner.Euclidean),
      ("placeEvery_u0__OOZpga95visualiserZframing", Owner.Rest),
      ("placeInto_u9__OOZpga95visualiserZtessellate", Owner.Rest),
      ("nimBuildFrame", Owner.Rest),
      ("(program)", Owner.Rest),
    ]
    for (name, owner) in names:
      checkpoint name
      check ownerOfName(name) == owner


  when not defined(js):
    test "a desktop frame is owned by the file its code is in":
      # Paths as debug build's frames carry them, absolute and checkout-dependent.
      let paths = [
        ("/c/pga_visualiser/dependencies/replications.mraxilus.gitlab.com/lengyel/" &
          "projective_geometric_algebra_illuminated/pga/multivectors.nim", Owner.Pga),
        ("/c/pga_visualiser/dependencies/replications.mraxilus.gitlab.com/lengyel/" &
          "projective_geometric_algebra_illuminated/pga.nim", Owner.Pga),
        ("/c/pga_visualiser/src/pga_visualiser/objects.nim", Owner.Algebra),
        ("/c/pga_visualiser/src/pga_visualiser/motors.nim", Owner.Algebra),
        ("/c/pga_visualiser/src/pga_visualiser/boundary.nim", Owner.Boundary),
        ("/c/pga_visualiser/src/pga_visualiser/euclid.nim", Owner.Euclidean),
        ("/c/pga_visualiser/src/pga_visualiser/mesh.nim", Owner.Euclidean),
        ("/c/pga_visualiser/src/pga_visualiser/tessellate.nim", Owner.Rest),
        ("/root/.cache/koch/nim/lib/pure/options.nim", Owner.Rest),
      ]
      for (path, owner) in paths:
        checkpoint path
        check ownerOfPath(cstring(path)) == owner
      check ownerOfPath(nil) == Owner.Rest


    test "a desktop stack is owned by its innermost frame that has an owner":
      # Outermost first, chained through `prev` as Nim's frames are; walk starts at last.
      const
        framing = "/c/pga_visualiser/src/pga_visualiser/framing.nim"
        boundary = "/c/pga_visualiser/src/pga_visualiser/boundary.nim"
        objects = "/c/pga_visualiser/src/pga_visualiser/objects.nim"
        multivectors = "/c/pga_visualiser/dependencies/replications.mraxilus.gitlab.com/" &
            "lengyel/projective_geometric_algebra_illuminated/pga/multivectors.nim"
      let stacks = [
        (@[framing, boundary, "/c/pga_visualiser/src/pga_visualiser/euclid.nim"],
          Owner.Euclidean),
        (@[framing, boundary, "/root/.cache/koch/nim/lib/system.nim"], Owner.Boundary),
        (@[framing, boundary, objects, multivectors], Owner.Pga),
        (@[framing, objects], Owner.Algebra),
        (@[framing, "/c/pga_visualiser/src/pga_visualiser/tessellate.nim"], Owner.Rest),
      ]
      for (paths, owner) in stacks:
        var frames = newSeq[TFrame](paths.len)
        for i, path in paths:
          frames[i].filename = cstring(path)
          if i > 0: frames[i].prev = addr frames[i-1]
        checkpoint $paths
        check ownerOfFrames(addr frames[^1]) == owner


  test "the tooltip names the span the ring pools over":
    # Catalogue holds literal text alone, so span is written there twice and held equal here.
    check ($SECONDS_SHARE & " seconds") in $wordingText(TipDiagnosticsPga)


  test "the ring pools the last twenty seconds, and forgets a second that left them":
    var ring = initRingShare[CountsShare]()
    ring.add(
      100,
      [Owner.Rest: 6, Owner.Pga: 3, Owner.Algebra: 1, Owner.Boundary: 0,
        Owner.Euclidean: 0],
    )
    ring.add(
      100,
      [Owner.Rest: 2, Owner.Pga: 5, Owner.Algebra: 1, Owner.Boundary: 1,
        Owner.Euclidean: 1],
    )
    ring.add(
      110,
      [Owner.Rest: 10, Owner.Pga: 10, Owner.Algebra: 0, Owner.Boundary: 0,
        Owner.Euclidean: 0],
    )
    let pooled = ring.pooled(110)
    check pooled == [Owner.Rest: 18, Owner.Pga: 18, Owner.Algebra: 2, Owner.Boundary: 1,
      Owner.Euclidean: 1]
    check pooled.busy == 40
    check pooled.percent(Owner.Pga) == 45.0
    # Second 100 left window at 120; its bucket is counted again from nothing at 120.
    check ring.pooled(119)[Owner.Pga] == 18
    check ring.pooled(120)[Owner.Pga] == 10
    ring.add(
      120,
      [Owner.Rest: 1, Owner.Pga: 0, Owner.Algebra: 0, Owner.Boundary: 0,
        Owner.Euclidean: 0],
    )
    check ring.pooled(120) == [Owner.Rest: 11, Owner.Pga: 10, Owner.Algebra: 0,
      Owner.Boundary: 0, Owner.Euclidean: 0]
    check initRingShare[CountsShare]().pooled(0).percent(Owner.Pga) == 0.0


  test "an empty bucket of the ring is an empty value, and no mark in the range of its second":
    # Fault: fresh ring marked each bucket's second -1, sentinel in range of `int`, where empty
    #   bucket's zero counts already add nothing to any pool (Article IV.4).
    # Domain: fresh ring against default value of its type, for both counts it pools, and its
    #   pool at each second of first two windows, before and after one sample at second 0.
    check initRingShare[CountsShare]() == default(RingShare[CountsShare])
    check initRingShare[CountsCrossing]() == default(RingShare[CountsCrossing])
    var ring = initRingShare[CountsShare]()
    for second in 0 ..< 2 * SECONDS_SHARE:
      checkpoint $second
      check ring.pooled(second) == default(CountsShare)
    let sample = [Owner.Rest: 1, Owner.Pga: 2, Owner.Algebra: 0, Owner.Boundary: 0,
      Owner.Euclidean: 0]
    ring.add(0, sample)
    for second in 0 ..< 2 * SECONDS_SHARE:
      checkpoint $second
      check ring.pooled(second) == (if second < SECONDS_SHARE: sample else: default(CountsShare))


  test "a second before the start has no bucket, so the ring refuses it by its type":
    # Fault: negative second indexed ring below its first bucket and stopped, or, as multiple of
    #   `SECONDS_SHARE`, wrote into one in silence. `pooled` read -1 as ring's own mark of empty
    #   bucket (repository issue 970).
    # Domain: each second of two spans before start, both multiples among them. Second 0, low
    #   end of `Natural`, keeps what it counts.
    var ring = initRingShare[CountsShare]()
    for second_before in -2 * SECONDS_SHARE .. -1:
      checkpoint $second_before
      expect RangeDefect:
        ring.add(second_before, default(CountsShare))
      expect RangeDefect:
        discard ring.pooled(second_before)
    let counts = [Owner.Rest: 1, Owner.Pga: 2, Owner.Algebra: 0, Owner.Boundary: 0,
      Owner.Euclidean: 0]
    ring.add(0, counts)
    check ring.pooled(0) == counts


  test "each value that crosses the boundary counts once, each way, while the tally is open":
    # One drain is one frame, and frame counts only while tally is open.
    discard drainCrossings()
    discard Position(x: 1, y: 2, z: 3).toMultivector
    check drainCrossings() == default(CountsCrossing)
    setCountingCrossings(true)
    let place = Position(x: 1, y: 2, z: 3).toMultivector
    discard place.position
    discard Motor().toMultivector.toMotor
    discard Direction(x: 0, y: 2, z: 0).toMultivector.directionFrom
    # Weightless point names no place, so read refuses and nothing leaves algebra.
    discard Direction(x: 0, y: 0, z: 1).toMultivector.position
    let counts = drainCrossings()
    setCountingCrossings(false)
    check counts == [Crossing.Frames: 1, Crossing.ToAlgebra: 4, Crossing.ToEuclidean: 3]
    check drainCrossings() == default(CountsCrossing)


  test "the ring pools crossings as it pools samples, as a mean for each frame":
    var ring = initRingShare[CountsCrossing]()
    ring.add(5, [Crossing.Frames: 1, Crossing.ToAlgebra: 10, Crossing.ToEuclidean: 30])
    ring.add(5, [Crossing.Frames: 1, Crossing.ToAlgebra: 20, Crossing.ToEuclidean: 50])
    let pooled = ring.pooled(5)
    check pooled.perFrame(Crossing.ToAlgebra) == 15.0
    check pooled.perFrame(Crossing.ToEuclidean) == 40.0
    check initRingShare[CountsCrossing]().pooled(0).perFrame(Crossing.ToAlgebra) == 0.0


  when not defined(js):
    when IS_SAMPLER_BUILT:
      test "the sampler counts a loop of PGA calls as PGA's":
        # Spins on geometric products, so nearly every busy sample is inside PGA.
        #   Bound sits below that, since sample landing in push or pop of tiny proc misses.
        #   Clock read once for 256 products: `cpuTime` is system call, about as dear as one.
        discard drainSamples()
        check startSampling()
        var
          product = POINTS[0]
          spins = 0
        let seconds_started = cpuTime()
        while cpuTime() - seconds_started < 0.4:
          for _ in 0..<256:
            product = POINTS[spins mod SAMPLES] ∧ LINES[spins mod SAMPLES] + product
            inc spins
        stopSampling()
        let counts = drainSamples()
        checkpoint &"{counts} over {spins} products, {product}"
        check counts.busy >= 40
        check counts.percent(Owner.Pga) > 50.0
        check drainSamples().busy == 0
