## Run `Share` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../src/rga_visualiser/share
when not defined(js):
  import std/times
  import ../../src/desktop/sampler



suite "Share":
  test "a page function is owned by the module its mangled name ends in":
    # Names as JS backend emits them into built page, one for each kind of owner.
    let names = [
      ("HEX5BHEX5D_u0__OOZOOZdependenciesZreplicationsOmraxilusOgitlabOcomZlengyelZ" &
        "projective95geometric95algebra95illuminatedZpgaZmultivectors", Owner.Library),
      ("wedge_u12__OOZOOZdependenciesZreplicationsOmraxilusOgitlabOcomZlengyelZ" &
        "projective95geometric95algebra95illuminatedZpga", Owner.Library),
      ("kindOf_u3__OOZrga95visualiserZobjects", Owner.Algebra),
      ("motorBetween_u7__OOZrga95visualiserZmotors", Owner.Algebra),
      ("liftPoint_u2__OOZrga95visualiserZboundary", Owner.Algebra),
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
          "projective_geometric_algebra_illuminated/pga/multivectors.nim", Owner.Library),
        ("/c/rga_visualiser/dependencies/replications.mraxilus.gitlab.com/lengyel/" &
          "projective_geometric_algebra_illuminated/pga.nim", Owner.Library),
        ("/c/rga_visualiser/src/rga_visualiser/objects.nim", Owner.Algebra),
        ("/c/rga_visualiser/src/rga_visualiser/projections.nim", Owner.Algebra),
        ("/c/rga_visualiser/src/rga_visualiser/tessellate.nim", Owner.Rest),
        ("/root/.cache/koch/nim/lib/pure/options.nim", Owner.Rest),
      ]
      for (path, owner) in paths:
        checkpoint path
        check ownerOfPath(cstring(path)) == owner
      check ownerOfPath(nil) == Owner.Rest


  test "the tooltip names the span the ring pools over":
    # Catalogue holds literal text alone, so span is written there twice and held equal here.
    check ($SECONDS_SHARE & " seconds") in $wordingText(TipDiagnosticsLibrary)


  test "the ring pools the last twenty seconds, and forgets a second that left them":
    var ring = initRingShare()
    ring.add(100, [Owner.Rest: 6, Owner.Algebra: 1, Owner.Library: 3])
    ring.add(100, [Owner.Rest: 4, Owner.Algebra: 1, Owner.Library: 5])
    ring.add(110, [Owner.Rest: 10, Owner.Algebra: 0, Owner.Library: 10])
    let pooled = ring.pooled(110)
    check pooled == [Owner.Rest: 20, Owner.Algebra: 2, Owner.Library: 18]
    check pooled.busy == 40
    check pooled.percentOf(Owner.Library) == 45.0
    # Second 100 left window at 120; its bucket is counted again from nothing at 120.
    check ring.pooled(119)[Owner.Library] == 18
    check ring.pooled(120)[Owner.Library] == 10
    ring.add(120, [Owner.Rest: 1, Owner.Algebra: 0, Owner.Library: 0])
    check ring.pooled(120) == [Owner.Rest: 11, Owner.Algebra: 0, Owner.Library: 10]
    check initRingShare().pooled(0).percentOf(Owner.Library) == 0.0


  when not defined(js):
    when IS_SAMPLER_BUILT:
      test "the sampler counts a loop of library calls as the library's":
        # Spins on geometric products, so nearly every busy sample is inside library.
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
        check counts.percentOf(Owner.Library) > 50.0
        check drainSamples().busy == 0
