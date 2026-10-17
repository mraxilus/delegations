## Hold multivector to cache-line alignment at no cost in size (`multivector-align`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Multivector holds 2^D coefficients, so it aligns to `min(64, size)` and starts on cache line
##     in every storage caller holds, from three dimensions up.
##   Laws read width of coefficient from library, so they also hold where P06 (`float-width`)
##     lands, with line merged as `min(64, sizeof(array[Basis, Coefficient]))`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/strformat

import pga


const
  LINE = 64  ## Bytes of one cache line.
  SIZE = sizeof(default(Multivector)[Basis.scalar]) * (ord(Basis.high) + 1)
    ## Bytes of 2^D coefficients at width library gives them, multivector unpadded.
  ALIGNMENT = min(LINE, SIZE)  ## Alignment proposed: one line, or own size where smaller.

var MULTIVECTORS_GLOBAL: array[3, Multivector]  ## Global storage, which linker lays out.


proc main() =
  ## Check size, alignment and address of multivector in each storage caller holds.

  func offset(address: pointer): uint =
    ## Get bytes address lies past last multiple of alignment.
    cast[uint](address) mod ALIGNMENT

  let
    multivectors = newSeq[Multivector](3)
    boxed = new Multivector
  var local: Multivector
  local[Basis.scalar] = 1.0
  doAssert alignof(Multivector) == ALIGNMENT,  # Aligned to line, or to own size.
    &"Multivector aligns to `{ALIGNMENT}` bytes; got `{alignof(Multivector)}`."
  doAssert sizeof(Multivector) == SIZE,  # No padding.
    &"Multivector holds its coefficients alone, `{SIZE}` bytes; got `{sizeof(Multivector)}`."
  doAssert offset(addr multivectors[0]) == 0,  # Heap, as `seq`.
    &"First element of `seq` starts on alignment; got offset `{offset(addr multivectors[0])}`."
  doAssert offset(addr multivectors[1]) == 0,  # Every element of `seq`.
    &"Second element of `seq` starts on alignment; got offset `{offset(addr multivectors[1])}`."
  doAssert offset(addr boxed[]) == 0,  # Heap, as `ref`.
    &"Multivector behind `ref` starts on alignment; got offset `{offset(addr boxed[])}`."
  doAssert offset(addr MULTIVECTORS_GLOBAL[0]) == 0,  # Global.
    &"Global multivector starts on alignment; got offset `{offset(addr MULTIVECTORS_GLOBAL[0])}`."
  doAssert offset(addr local) == 0,  # Stack.
    &"Local multivector starts on alignment; got offset `{offset(addr local)}`."
  echo "multivector-align: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL, ", ",
    ALIGNMENT, " bytes, ", local[Basis.scalar]


main()
