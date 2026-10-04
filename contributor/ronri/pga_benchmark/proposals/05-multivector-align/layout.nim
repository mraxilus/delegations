## Hold multivector to 16-byte alignment at no cost in size (`multivector-align`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Multivector holds 2^D floats, so 16-byte alignment pads it at no dimension.
##   Kind of P02 or P04 holds any count of floats, and rule below aligns it to 16 only where count
##     is even. Padding costs more than alignment gains: copy of padded result reads its tail in one
##     load across two stores, which processor cannot forward.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import pga
import pga/algebra


const ALIGNMENT = 16  ## Width of one SSE register, which no load then splits across lines.


type KindOf[C: static int] = object
  ## Define kind of `C` floats under proposed rule, as P04's `MultivectorOf` would hold them.
  when C mod 2 == 0:
    elements {.align(16).}: array[C, float]
  else:
    elements: array[C, float]


var MULTIVECTORS_GLOBAL: array[3, Multivector]  ## Global storage, which linker lays out.


proc main() =
  ## Check multivector in each storage caller holds, then size and alignment of kinds under rule.
  let
    multivectors = newSeq[Multivector](3)
    boxed = new Multivector
  var local: Multivector
  local[Basis.scalar] = 1.0
  doAssert alignof(Multivector) == ALIGNMENT  # aligned to one register
  doAssert sizeof(Multivector) == sizeof(float) * (ord(Basis.high) + 1)  # no padding
  doAssert cast[uint](addr multivectors[0]) mod ALIGNMENT == 0  # heap, as `seq`
  doAssert cast[uint](addr boxed[]) mod ALIGNMENT == 0  # heap, as `ref`
  doAssert cast[uint](addr MULTIVECTORS_GLOBAL[0]) mod ALIGNMENT == 0  # global
  doAssert cast[uint](addr local) mod ALIGNMENT == 0  # stack
  doAssert alignof(KindOf[1]) == 8 and alignof(KindOf[3]) == 8  # odd count stays natural
  doAssert alignof(KindOf[5]) == 8
  doAssert alignof(KindOf[4]) == ALIGNMENT and alignof(KindOf[6]) == ALIGNMENT  # even aligned
  doAssert alignof(KindOf[8]) == ALIGNMENT and alignof(KindOf[10]) == ALIGNMENT
  doAssert sizeof(KindOf[1]) == 8 and sizeof(KindOf[3]) == 24 and sizeof(KindOf[4]) == 32
  doAssert sizeof(KindOf[5]) == 40 and sizeof(KindOf[6]) == 48 and sizeof(KindOf[8]) == 64
  doAssert sizeof(KindOf[10]) == 80 and sizeof(KindOf[16]) == 128  # no kind padded
  echo "multivector-align: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL, ", ",
    local[Basis.scalar]


main()
