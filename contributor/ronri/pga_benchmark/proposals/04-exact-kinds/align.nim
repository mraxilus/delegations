## Hold rule that aligns each basis-set type by size of its basis set (`exact-kinds`).
##   Evaluation compiles this against library at pin, at each algebra its claim names, and exit
##     code is verdict: every law below holds, or program stops on assertion.
##   `alignmentOf` gives alignment of any count of floats from count alone: largest power of two
##     dividing their bytes, at most one line, so it pads no count. Each basis-set type takes it
##     from size of its basis set, as Architect ruled on 2026-10-04; laws hold it at each count.
##   Prototype imports it, so rule its basis-set types take is rule these laws hold.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof


const
  LINE = 64  ## Bytes of one cache line.
  ALIGNMENTS_KIND = [(3, 8), (4, 32), (5, 8), (6, 16), (8, 64), (10, 16), (16, 64)]
    ## Count of floats of each named basis-set type, from rga3d to cga5d, and its alignment.


func alignmentOf*(count: int): int =
  ## Align coefficients of `count` bases to largest power of two dividing their bytes, at most
  ##   one cache line. Alignment divides size, so it pads at no count.
  let size = sizeof(float) * count
  min(LINE, size and -size)


proc main() =
  ## Check alignment of every count, then of each count that basis-set types reach.
  for count in 1..64:
    let
      size = sizeof(float) * count
      alignment = alignmentOf(count)
    doAssert alignment in [8, 16, 32, 64]  # power of two, from float to line
    doAssert size mod alignment == 0  # pads no count
    doAssert alignment == LINE or size mod (2 * alignment) != 0  # largest that pads none
  for (count, alignment) in ALIGNMENTS_KIND:
    doAssert alignmentOf(count) == alignment  # basis-set types, as proposal tables them
  echo "exact-kinds: alignment laws hold at every count from 1 to 64"


when isMainModule:
  main()
