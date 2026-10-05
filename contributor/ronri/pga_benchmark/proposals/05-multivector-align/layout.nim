## Hold multivector to cache-line alignment at no cost in size (`multivector-align`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   `alignmentOf` gives alignment of any count of floats from count alone: largest power of two
##     dividing their bytes, at most one line, so it pads no count. Multivector holds 2^D floats,
##     so it aligns to `min(64, size)` and starts on cache line in every storage caller holds.
##   Kinds of P04 take `alignmentOf` of size of their basis set when they land, as Architect
##     ruled on 2026-10-04; laws here hold function at each count they reach.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import pga
import pga/algebra


const
  LINE = 64  ## Bytes of one cache line.
  COUNT_BASES = ord(Basis.high) + 1  ## Size of basis set of multivector, 2^D.
  SIZE = sizeof(float) * COUNT_BASES  ## Bytes of 2^D floats, multivector unpadded.
  ALIGNMENT = min(LINE, SIZE)  ## Alignment proposed: one line, or own size where smaller.
  ALIGNMENTS_KIND = [(3, 8), (4, 32), (5, 8), (6, 16), (8, 64), (10, 16), (16, 64)]
    ## Count of floats of each kind P04 reaches, from rga3d to cga5d, and its alignment.


var MULTIVECTORS_GLOBAL: array[3, Multivector]  ## Global storage, which linker lays out.


proc main() =
  ## Check alignment of every count, then size, alignment and address of multivector in each
  ##   storage caller holds.
  for count in 1..64:
    let
      size = sizeof(float) * count
      alignment = alignmentOf(count)
    doAssert alignment in [8, 16, 32, 64]  # power of two, from float to line
    doAssert size mod alignment == 0  # pads no count
    doAssert alignment == LINE or size mod (2 * alignment) != 0  # largest that pads none
  for (count, alignment) in ALIGNMENTS_KIND:
    doAssert alignmentOf(count) == alignment  # kinds, as proposal tables them
  let
    multivectors = newSeq[Multivector](3)
    boxed = new Multivector
  var local: Multivector
  local[Basis.scalar] = 1.0
  doAssert alignmentOf(COUNT_BASES) == ALIGNMENT  # multivector takes rule of its basis set
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
