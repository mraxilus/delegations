## Run `Share` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../src/rga_visualiser/[boundary, share]
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
      ("kindOf_u3__OOZrga95visualiserZobjects", Owner.Algebra),
      ("carried_u1__OOZrga95visualiserZmotors", Owner.Algebra),
      ("toMultivector_u1__OOZrga95visualiserZboundary", Owner.Boundary),
      ("normalize_u0__OOZrga95visualiserZeuclid", Owner.Euclidean),
      ("addDome_u0__OOZrga95visualiserZmesh", Owner.Euclidean),
      ("placeEvery_u0__OOZrga95visualiserZframing", Owner.Rest),
      ("placeInto_u9__OOZrga95visualiserZtessellate", Owner.Rest),
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
        ("/c/rga_visualiser/dependencies/replications.mraxilus.gitlab.com/lengyel/" &
          "projective_geometric_algebra_illuminated/pga/multivectors.nim", Owner.Pga),
        ("/c/rga_visualiser/dependencies/replications.mraxilus.gitlab.com/lengyel/" &
          "projective_geometric_algebra_illuminated/pga.nim", Owner.Pga),
        ("/c/rga_visualiser/src/rga_visualiser/objects.nim", Owner.Algebra),
        ("/c/rga_visualiser/src/rga_visualiser/projections.nim", Owner.Algebra),
        ("/c/rga_visualiser/src/rga_visualiser/boundary.nim", Owner.Boundary),
        ("/c/rga_visualiser/src/rga_visualiser/euclid.nim", Owner.Euclidean),
        ("/c/rga_visualiser/src/rga_visualiser/mesh.nim", Owner.Euclidean),
        ("/c/rga_visualiser/src/rga_visualiser/tessellate.nim", Owner.Rest),
        ("/root/.cache/koch/nim/lib/pure/options.nim", Owner.Rest),
      ]
      for (path, owner) in paths:
        checkpoint path
        check ownerOfPath(cstring(path)) == owner
      check ownerOfPath(nil) == Owner.Rest


    test "a desktop stack is owned by its innermost frame that has an owner":
      # Outermost first, chained through `prev` as Nim's frames are; walk starts at last.
      const
        framing = "/c/rga_visualiser/src/rga_visualiser/framing.nim"
        boundary = "/c/rga_visualiser/src/rga_visualiser/boundary.nim"
        objects = "/c/rga_visualiser/src/rga_visualiser/objects.nim"
        multivectors = "/c/rga_visualiser/dependencies/replications.mraxilus.gitlab.com/" &
            "lengyel/projective_geometric_algebra_illuminated/pga/multivectors.nim"
      let stacks = [
        (@[framing, boundary, "/c/rga_visualiser/src/rga_visualiser/euclid.nim"],
          Owner.Euclidean),
        (@[framing, boundary, "/root/.cache/koch/nim/lib/system.nim"], Owner.Boundary),
        (@[framing, boundary, objects, multivectors], Owner.Pga),
        (@[framing, objects], Owner.Algebra),
        (@[framing, "/c/rga_visualiser/src/rga_visualiser/tessellate.nim"], Owner.Rest),
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
    check pooled.percentOf(Owner.Pga) == 45.0
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
    check initRingShare[CountsShare]().pooled(0).percentOf(Owner.Pga) == 0.0


  test "each value that crosses the boundary counts once, each way, while the tally is open":
    # One drain is one frame, and frame counts only while tally is open.
    discard drainCrossings()
    discard Position(x: 1, y: 2, z: 3).toMultivector
    check drainCrossings() == default(CountsCrossing)
    setCountingCrossings(true)
    let place = Position(x: 1, y: 2, z: 3).toMultivector
    discard place.position
    discard Motor().toMultivector.motorOf
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
        discard drainSamples()
        check startSampling()
        var
          product = POINTS[0]
          spins = 0
        let seconds_started = cpuTime()
        while cpuTime() - seconds_started < 0.4:
          product = POINTS[spins mod SAMPLES] ∧ LINES[spins mod SAMPLES] + product
          inc spins
        stopSampling()
        let counts = drainSamples()
        checkpoint &"{counts} over {spins} products, {product}"
        check counts.busy >= 40
        check counts.percentOf(Owner.Pga) > 50.0
        check drainSamples().busy == 0
