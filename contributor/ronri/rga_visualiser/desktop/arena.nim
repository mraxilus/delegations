## Allocate scratch memory from fixed block by bumping offset.
##
## Short-lived buffer costs offset bump instead of allocator call, and whole block is
## reclaimed at once by resetting offset.
##   Style Casey Muratori and Ryan Fleury both write about.
## Three lifetimes cover everything this project still allocates dynamically:
##
##   |-----------|---------------------------------|--------------------------------------|
##   | Arena     | Reset                           | Backs                                |
##   |-----------|---------------------------------|--------------------------------------|
##   | Permanent | Never; lives until process exit | Pixel readback buffer, sized once    |
##   |           |                                 | and reused for every export.         |
##   | Export    | After each throwaway unit of    | PNG's filtered/compressed scanlines, |
##   |           | work: one PNG write, one GIF    | GIF's quantized indices and LZW      |
##   |           | sub-frame.                      | output; built once, read once.       |
##   | Frame     | On next frame's swap, so last   | Draw loop's scratch: points          |
##   | swap pair | frame's bytes survive this one. | tessellation step assembles before   |
##   |           | See `ArenaSwap`.                | emitting them.                       |
##   |-----------|---------------------------------|--------------------------------------|
##
## `Scene` and `MeshSet` are on none of them.
##   Fixed arrays with own lifetime, permanent and cleared-in-place.
##   Loop's text formatting writes into stack buffers (`format.nim`).
## Export arena and frame pair are kept apart deliberately.
##   Export's scratch is tens of megabytes once per keypress, frame's tens of kilobytes
##   sixty times per second.
##   Sizing one block for both would reserve export's capacity twice to buy frame's swap.
## Backing storage is plain global array, not runtime allocation.
##   Reserving block costs one line in binary's data segment, and every arena is exhausted
##   by `doAssert` rather than by growing.
##
## Desktop-only; unreachable from browser build. See `visualiser.nim`'s "Render Paths".

{.experimental: "strictFuncs".}

import std/strformat



#[ Type Definitions ]#

type Arena* = object ## Define fixed block of bytes and how much of it is in use.
  buffer: ptr UncheckedArray[byte]
  capacity: int
  used: int
  peak_used: int ## Highest `used` has ever reached; never falls back on `reset`.
    ## Lets live display show what arena's activity looks like.
    ##   `used` alone reads near zero wherever sampled, since carving and reset both
    ##   happen within one frame.



#[ Arena Lifetime ]#

func initArena*(backing: var openArray[byte]): Arena =
  ## Wrap caller-owned backing storage as arena.
  ##   Nothing is allocated, as `backing` is expected to be fixed global array.
  Arena(
    buffer: cast[ptr UncheckedArray[byte]](addr backing[0]),
    capacity: len(backing),
    used: 0,
    peak_used: 0,
  )


func reset*(arena: var Arena) =
  ## Reclaim everything carved from `arena` so far, in one step.
  ##   Nothing is freed individually.
  ##   `peak_used` is untouched: it tracks high-water mark across whole lifetime.
  arena.used = 0



#[ Arena Allocation ]#

func push*[T](arena: var Arena, count: int): ptr UncheckedArray[T] =
  ## Carve `count` elements of `T` from `arena`, uninitialised.
  ##   Never freed on its own; reclaimed only when `reset` reclaims whole arena.
  let bytes_needed = count * sizeof(T)
  doAssert arena.used + bytes_needed <= arena.capacity,
    &"Arena holds {arena.capacity} bytes, raise whichever `--define:visualiser.capacity_arena_*` " &
    &"backs it; got `{arena.used + bytes_needed}` asked for."
  result = cast[ptr UncheckedArray[T]](addr arena.buffer[arena.used])
  arena.used += bytes_needed
  if arena.used > arena.peak_used: arena.peak_used = arena.used



#[ Frame Swap Pair ]#

type ArenaSwap* = object ## Define two frame arenas and which of them this frame is writing.
  ## Two-frame lifetime.
  ##   What frame carves stays readable through next frame as `previous`, reclaimed only
  ##   when its block comes round again.
  ##   Frame can read what one before it worked out without copying or keeping it alive
  ##   forever.
  ## `swap` moves write cursor to other block and resets it, so frame always begins with
  ## arena holding nothing.
  ##   Reclaiming on way in leaves block written last frame intact until needed again.
  arenas: array[2, Arena]
  index_current: int ## Which of `arenas` this frame carves from; other is last frame's.


func initArenaSwap*(backing_first, backing_second: var openArray[byte]): ArenaSwap =
  ## Wrap two caller-owned blocks as swap pair, first of them current.
  ##   Two blocks rather than one twice size: point is that last frame's bytes are still
  ##   there, which single arena reset in place cannot promise.
  ArenaSwap(
    arenas: [initArena(backing_first), initArena(backing_second)],
    index_current: 0,
  )


func swap*(pair: var ArenaSwap) =
  ## Begin new frame.
  ##   What was current becomes readable as `previous`, and block moved to is reclaimed so
  ##   this frame starts clean.
  pair.index_current = 1 - pair.index_current
  pair.arenas[pair.index_current].reset()


func current*(pair: var ArenaSwap): var Arena = pair.arenas[pair.index_current]
  ## Reach arena this frame carves from.

func previous*(pair: var ArenaSwap): var Arena = pair.arenas[1 - pair.index_current]
  ## Reach arena previous frame carved from, still holding what it wrote.
  ##   Read-only in spirit: carving from it takes memory this frame's `swap` is about to
  ##   reclaim, and nothing stops that; discipline is caller's.

func usedSwap*(pair: ArenaSwap): int = pair.arenas[pair.index_current].used
  ## Report bytes carved this frame.

func capacitySwap*(pair: ArenaSwap): int = pair.arenas[0].capacity + pair.arenas[1].capacity
  ## Report both blocks together, which is what pair reserves.

func peakUsedSwap*(pair: ArenaSwap): int =
  ## Report most either block has ever held at once.
  ##   Larger of two rather than sum: they hold one frame's work each, not halves of one.
  max(pair.arenas[0].peak_used, pair.arenas[1].peak_used)



#[ Arena Introspection ]#

func used*(arena: Arena): int = arena.used
  ## Report bytes carved from `arena` and not yet reclaimed by `reset`.

func capacity*(arena: Arena): int = arena.capacity
  ## Report fixed size `arena` was constructed with.

func peakUsed*(arena: Arena): int = arena.peak_used
  ## Report most `arena` has ever held at once, across every `reset`.
