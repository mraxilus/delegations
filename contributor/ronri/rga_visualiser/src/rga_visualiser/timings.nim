## Measure what each side of algebra boundary cost this frame.
##
## Panel could say what each *stage* of frame cost, not how much went on geometric algebra
## against turning its answers into triangles, question project exists to ask.
##   `tessellate` resolves every place through algebra and emits afterwards (see
##   `mesh.RibbonPiece`), so there is seam with two sides to bracket.
##   `Placing` is working out where things are; `Emitting` is turning places into vertices.
##   Emitting is pure by construction: reached through `mesh`, which imports `euclid` alone.
##   Placing is dominated by algebra but not free of Euclidean arithmetic.
##     Lattice line's across-vector is one cross product; each piece's two fade colours
##     are scalar work; both charged here. Saying so beats claiming purity loop lacks.
## Clock is chosen at compile time, not installed at run time.
##   Two builds share no clock, and proc variable would put indirect call in every bracket.
## Also carries few figures that cannot be measured inside one frame; see `FrameRecord`.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.

{.experimental: "strictFuncs".}

when defined(js):
  proc nowMilliseconds*(): float {.importjs: "performance.now()".}
    ## Read page's monotonic clock, in milliseconds.
else:
  import std/monotimes
  proc nowMilliseconds*(): float =
    ## Read process's monotonic clock, in milliseconds.
    float(getMonoTime().ticks) / 1_000_000.0



#[ Type Definitions ]#

type Side* {.pure.} = enum ## Define which side of boundary stretch of work sat on.
  Placing, ## Working out where geometry is: algebra, and little that rides along.
  Emitting ## Turning places into vertices: `mesh`, which cannot reach algebra.


type FrameRecord* = object
  ## Define what frame measured that *next* frame reports.
  ##   Only for work outside frame's own build.
  ##   On browser, hover picking runs from event handlers, so no bracket inside
  ##   `nimBuildFrame` sees it; measured where it happens.
  ms_hover_pick*: float ## What picking under cursor cost since last frame.



#[ Frame State ]#

var
  SPENT_SIDE: array[Side, float]
    ## Accumulate what each side has cost since `openFrameTimings`.
    ##   Module state because that is what instrumentation is.
    ##   Threading accumulator through every tessellation proc would put measurement into
    ##   signatures that describe drawing.

  RECORDS_FRAME: array[2, FrameRecord]
    ## Hold this frame's record and last frame's, turned over per frame.
  INDEX_RECORD_CURRENT = 0
    ## Point at record this frame writes.

proc openFrameTimings*() =
  ## Begin frame: forget both sides' totals, and turn record pair over.
  ##   Same two-frame lifetime draw scratch has (`arena.ArenaSwap`).
  ##   Incoming record is cleared on way *in*, so last frame's stays readable until this
  ##   frame replaces it.
  for side in Side: SPENT_SIDE[side] = 0.0
  INDEX_RECORD_CURRENT = 1 - INDEX_RECORD_CURRENT
  RECORDS_FRAME[INDEX_RECORD_CURRENT] = FrameRecord()


var IS_TALLYING = true
  ## Say whether anyone reads per-side and per-kind breakdowns this frame.
  ##   Instrumentation this fine must be switchable, because it runs per object.
  ##     `timed` brackets both halves of *one object*: two clock reads per object per
  ##     frame, paid for rows nothing displays unless gated (Art. VII.4).
  ##   *Counts* are not gated: increment each, true whether or not anyone watches.
  ##   Defaults on, so front-end that never says otherwise measures everything.

proc setTallying*(is_wanted: bool) =
  ## Say whether per-side and per-kind breakdowns are being read.
  ##   Call once per frame, before `openFrameTimings`; see `IS_TALLYING`.
  IS_TALLYING = is_wanted


proc isTallying*(): bool = IS_TALLYING
  ## Report whether fine breakdowns are gathered this frame.


template timed*(side: Side, body: untyped) =
  ## Charge whatever `body` does to one side of boundary.
  ##   Never nest two: inner stretch would be counted by both, undetectably.
  ##     Call sites bracket disjoint halves of one proc.
  ##   Body runs either way; only two clock reads are skipped.
  ##     One body with guarded pair, not two branches, so measured and unmeasured paths
  ##     cannot differ.
  let ms_entered_timed = (if IS_TALLYING: nowMilliseconds() else: 0.0)
  body
  if IS_TALLYING: SPENT_SIDE[side] += nowMilliseconds() - ms_entered_timed


proc spentOn*(side: Side): float = SPENT_SIDE[side]
  ## Report what one side has cost this frame, in milliseconds.


proc recordThisFrame*(): var FrameRecord = RECORDS_FRAME[INDEX_RECORD_CURRENT]
  ## Reach record this frame is writing.

proc recordLastFrame*(): FrameRecord = RECORDS_FRAME[1 - INDEX_RECORD_CURRENT]
  ## Read what previous frame measured.
  ##   Anything happening between frames is reported from here.
