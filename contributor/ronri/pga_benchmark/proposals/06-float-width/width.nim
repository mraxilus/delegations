## Hold each element of multivector to width `FLOAT_BITS` names, at no padding (`float-width`).
##   Evaluation compiles this against changed library at each algebra its claim names, at default
##     width and at 32 bits, and exit code is verdict: every law below holds, or program stops on
##     assertion.
##   Tolerance follows width by default, since 32-bit element holds about seven places.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import pga


const
  COUNT_BASES = ord(Basis.high) + 1  ## Size of basis set of multivector, 2^D.
  PLACES = (when FLOAT_BITS == 32: 5 else: 9)  ## Default tolerance of each width, in places.


proc main() =
  ## Hold width, size and tolerance of this build, then print them.
  doAssert sizeof(Real) * 8 == FLOAT_BITS, "Element is as wide as define names."
  doAssert sizeof(Multivector) == COUNT_BASES * sizeof(Real), "Multivector holds elements alone."
  doAssert TOLERANCE_PLACES == PLACES, "Tolerance follows width by default."
  echo "width ", FLOAT_BITS, " size ", sizeof(Multivector), " tolerance ", TOLERANCE_PLACES


main()
