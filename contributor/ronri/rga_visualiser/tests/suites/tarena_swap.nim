## Run `Arena Swap` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


# Arena is desktop-only -- it casts pointer over global and carves typed slices.
#   from it, which JS backend cannot do -- so its own suite runs on that backend alone.
when not defined(js):
  suite "Arena Swap":
    # Two blocks big enough to tell apart by what is written into them, and small enough.
    #   that filling one is test rather than wait.
    var backing_first: array[512, byte]
    var backing_second: array[512, byte]

    test "a frame carves from one block while the other holds the frame before it":
      # Pair's whole promise: what this frame writes is still readable next frame.
      var pair = initArenaSwap(backing_first, backing_second)
      let written = pair.current.push[:int32](4)
      for i in 0 ..< 4: written[i] = int32(100 + i)
      check pair.current.used == 4*sizeof(int32)

      pair.swap()
      # Last frame's block, untouched by swap that reclaimed other one.
      let carried = cast[ptr UncheckedArray[int32]](addr backing_first[0])
      for i in 0 ..< 4: check carried[i] == int32(100 + i)
      check pair.previous.used == 4*sizeof(int32)

    test "the block a frame begins on holds nothing, whatever was in it":
      var pair = initArenaSwap(backing_first, backing_second)
      discard pair.current.push[:int32](8)
      pair.swap()
      discard pair.current.push[:int32](2)
      check pair.current.used == 2*sizeof(int32)
      # Swap again: first block comes back current and is reclaimed on way in.
      #   What "starts completely clean" means; not reclaimed on way out, since that
      #   would take last frame's bytes away while they were still wanted.
      pair.swap()
      check pair.current.used == 0
      check pair.previous.used == 2*sizeof(int32)

    test "a carve outlives exactly one swap and no more":
      # Two frames is lifetime. On second swap block is current again and its.
      #   offset is back to zero, so next carve hands out very same bytes.
      var pair = initArenaSwap(backing_first, backing_second)
      let first = pair.current.push[:int32](1)
      pair.swap()
      pair.swap()
      let again = pair.current.push[:int32](1)
      check cast[int](first) == cast[int](again)

    test "the pair reports both blocks, and the high-water mark of either":
      var pair = initArenaSwap(backing_first, backing_second)
      check pair.capacitySwap == len(backing_first) + len(backing_second)
      discard pair.current.push[:int32](6)
      pair.swap()
      discard pair.current.push[:int32](2)
      # Larger of two, never their sum: they hold one frame's work each, so sum.
      #   would name quantity no single frame ever reached.
      check pair.peakUsedSwap == 6*sizeof(int32)
      check pair.usedSwap == 2*sizeof(int32)
