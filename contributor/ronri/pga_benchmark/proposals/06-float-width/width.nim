## Hold each coefficient of multivector to width `FLOAT_WIDTH` names, at no padding (`float-width`).
##   Evaluation compiles this against changed library at each algebra its claim names, at default
##     width and at 32 bits, and exit code is verdict: every law below holds, or program stops on
##     assertion.
##   Tolerance follows width by default, since 32-bit coefficient holds about seven places.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import pga


const
  COUNT_BASES = ord(Basis.high) + 1  ## Size of basis set of multivector, 2^D.
  PLACES = (when FLOAT_WIDTH == 32: 5 else: 9)  ## Default tolerance of each width, in places.


proc main() =
  ## Hold width, size and tolerance of this build, then print them.
  doAssert sizeof(Coefficient) * 8 == FLOAT_WIDTH, "Coefficient is as wide as define names."
  doAssert sizeof(Multivector) == COUNT_BASES * sizeof(Coefficient),
      "Multivector holds coefficients alone."
  doAssert FLOAT_TOLERANCE == PLACES, "Tolerance follows width by default."
  echo "width ", FLOAT_WIDTH, " size ", sizeof(Multivector), " tolerance ", FLOAT_TOLERANCE


main()
