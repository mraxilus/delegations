## Allocate scratch memory from fixed block by bumping offset.
##
## Short-lived buffer costs offset bump instead of allocator call, and whole block is
## reclaimed at once by resetting offset.
##   Style Casey Muratori and Ryan Fleury both write about.
## Three regions hold everything this project would otherwise allocate dynamically:
##
##   |--------------|--------------------------------|---------------------------------------|
##   | Region       | Reclaimed                      | Backs                                 |
##   |--------------|--------------------------------|---------------------------------------|
##   | Program      | Never; lives until process     | Pixel readback buffer, every          |
##   | arena        | exit. Export's scratch is one  | storyboard GIF frame, and export's    |
##   |              | stretch of it, overwritten by  | scratch: PNG's filtered scanlines,    |
##   |              | each export.                   | GIF's quantized indices and LZW.      |
##   | Frame arenas | Two, turned each frame; block  | Frame's placements, one for each      |
##   |              | coming round is reclaimed, so  | handle, then draw loop's scratch.     |
##   |              | last frame's bytes survive     |                                       |
##   |              | this one. See `ArenasFrame`.   |                                       |
##   | Object pool  | One handle at time: removing   | `Scene`'s objects. Free handles link  |
##   |              | object puts its handle on free | into list, and next object added      |
##   |              | list. See `scene.Scene`.       | takes most recently freed.            |
##   |--------------|--------------------------------|---------------------------------------|
##
## Object pool is arena with free list in place of offset, not `Arena`.
##   Fixed arrays in `Scene`, threaded by free list; undo timeline holds whole copies of it.
##   `MeshSet` is fixed arrays too, cleared in place; loop's text formatting writes into stack
##   buffers (`format.nim`).
## Export's scratch is stretch of program arena, not of frame arenas.
##   Tens of megabytes at most once per keypress, where frame's work is tens of kilobytes
##   every frame: in frame arenas it would reserve its capacity twice for turn it never uses.
## Backing storage is plain global array, not runtime allocation.
##   Reserving block costs one line in binary's data segment, and every arena is exhausted
##   by `doAssert` rather than by growing.
##
## Desktop-only; unreachable from browser build. See PROVENANCE.md's "Render paths".

{.experimental: "strictFuncs".}

import std/strformat



#[ Type Definitions ]#

type
  Arena* = object  ## Define fixed block of bytes and how much of it is in use.
    buffer: ptr UncheckedArray[byte]
    capacity: int
    used: int
    peak_used: int  ## Highest `used` has ever reached; never falls back on `reset`.
      ## Lets live display show what arena's activity looks like.
      ##   `used` alone reads near zero wherever sampled, since carving and reset both
      ##   happen within one frame.

  ArenasFrame* = object  ## Define two frame arenas and which of them this frame is writing.
    ## Two-frame lifetime.
    ##   What frame carves stays readable through next frame as `previous`, reclaimed only
    ##   when its block comes round again.
    ##   Frame can read what one before it worked out without copying or keeping it alive
    ##   forever.
    ## `swap` moves write cursor to other block and resets it, so frame always begins with
    ## arena holding nothing.
    ##   Reclaiming on way in leaves block written last frame intact until needed again.
    blocks: array[2, Arena]
    index_current: int  ## Which of `blocks` this frame carves from; other is last frame's.



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



#[ Frame Arenas ]#

func initArenasFrame*(backing_first, backing_second: var openArray[byte]): ArenasFrame =
  ## Wrap two caller-owned blocks as frame arenas, first of them current.
  ##   Two blocks rather than one twice size: point is that last frame's bytes are still
  ##   there, which single arena reset in place cannot promise.
  ArenasFrame(
    blocks: [initArena(backing_first), initArena(backing_second)],
    index_current: 0,
  )


func swap*(arenas: var ArenasFrame) =
  ## Begin new frame.
  ##   What was current becomes readable as `previous`, and block moved to is reclaimed so
  ##   this frame starts clean.
  arenas.index_current = 1 - arenas.index_current
  arenas.blocks[arenas.index_current].reset()


func current*(arenas: var ArenasFrame): var Arena = arenas.blocks[arenas.index_current]
  ## Reach arena this frame carves from.

func previous*(arenas: var ArenasFrame): var Arena = arenas.blocks[1-arenas.index_current]
  ## Reach arena previous frame carved from, still holding what it wrote.
  ##   Read-only in spirit: carving from it takes memory this frame's `swap` is about to
  ##   reclaim, and nothing stops that; discipline is caller's.

func used*(arenas: ArenasFrame): int = arenas.blocks[arenas.index_current].used
  ## Report bytes carved this frame.

func capacity*(arenas: ArenasFrame): int = arenas.blocks[0].capacity + arenas.blocks[1].capacity
  ## Report both blocks together, which is what frame arenas reserve.

func peakUsed*(arenas: ArenasFrame): int =
  ## Report most either block has ever held at once.
  ##   Larger of two rather than sum: they hold one frame's work each, not halves of one.
  max(arenas.blocks[0].peak_used, arenas.blocks[1].peak_used)



#[ Arena Introspection ]#

func used*(arena: Arena): int = arena.used
  ## Report bytes carved from `arena` and not yet reclaimed by `reset`.

func capacity*(arena: Arena): int = arena.capacity
  ## Report fixed size `arena` was constructed with.

func peakUsed*(arena: Arena): int = arena.peak_used
  ## Report most `arena` has ever held at once, across every `reset`.
