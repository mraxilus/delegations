## Hold each coefficient of multivector to width `FLOAT_WIDTH` names, at no padding (`float-width`).
##   Evaluation compiles this against changed library at each algebra its claim names, at default
##     width and at 32 bits, and exit code is verdict: every law below holds, or program stops on
##     assertion.
##   Comparison tolerance follows width by default, since 32-bit coefficient holds about seven
##     places.
##   Literal constructor parses 64-bit float and narrows it to `Coefficient` implicitly, so it
##     needs no edit at 32 bits.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/strformat

import pga


const
  COUNT_BASES = ord(Basis.high) + 1  ## Size of basis set of multivector, 2^D.
  PLACES = (when FLOAT_WIDTH == 32: 4 else: 9)
    ## Default comparison tolerance of each width, in places.


proc main() =
  ## Hold width, size, comparison tolerance and literal constructor of this build, then print them.
  let literal = e1"0.5"
  doAssert sizeof(Coefficient) * 8 == FLOAT_WIDTH,
    &"Coefficient is `{FLOAT_WIDTH}` bits wide, as define names; got `{sizeof(Coefficient) * 8}`."
  doAssert sizeof(Multivector) == COUNT_BASES * sizeof(Coefficient),
    &"Multivector holds coefficients alone, `{COUNT_BASES * sizeof(Coefficient)}` bytes; " &
    &"got `{sizeof(Multivector)}`."
  doAssert FLOAT_TOLERANCE == PLACES,
    &"Comparison tolerance follows width, `{PLACES}` places by default; got `{FLOAT_TOLERANCE}`."
  doAssert literal =~ initElement(Basis.E1, 0.5),
    &"Literal constructor narrows to coefficient; got `{literal}`."
  echo "width ", FLOAT_WIDTH, " size ", sizeof(Multivector), " tolerance ", FLOAT_TOLERANCE


main()
