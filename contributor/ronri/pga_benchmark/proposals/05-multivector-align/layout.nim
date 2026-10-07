## Hold multivector to cache-line alignment at no cost in size (`multivector-align`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Multivector holds 2^D floats, so it aligns to `min(64, size)` and starts on cache line in
##     every storage caller holds.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import pga


const
  LINE = 64  ## Bytes of one cache line.
  SIZE = sizeof(float) * (ord(Basis.high) + 1)  ## Bytes of 2^D floats, multivector unpadded.
  ALIGNMENT = min(LINE, SIZE)  ## Alignment proposed: one line, or own size where smaller.


var MULTIVECTORS_GLOBAL: array[3, Multivector]  ## Global storage, which linker lays out.


proc main() =
  ## Check size, alignment and address of multivector in each storage caller holds.
  let
    multivectors = newSeq[Multivector](3)
    boxed = new Multivector
  var local: Multivector
  local[Basis.scalar] = 1.0
  doAssert alignof(Multivector) == ALIGNMENT  # aligned to line, or to own size
  doAssert sizeof(Multivector) == SIZE  # no padding
  doAssert cast[uint](addr multivectors[0]) mod ALIGNMENT == 0  # heap, as `seq`
  doAssert cast[uint](addr multivectors[1]) mod ALIGNMENT == 0  # every element of `seq`
  doAssert cast[uint](addr boxed[]) mod ALIGNMENT == 0  # heap, as `ref`
  doAssert cast[uint](addr MULTIVECTORS_GLOBAL[0]) mod ALIGNMENT == 0  # global
  doAssert cast[uint](addr local) mod ALIGNMENT == 0  # stack
  echo "multivector-align: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL, ", ",
    ALIGNMENT, " bytes, ", local[Basis.scalar]


main()
