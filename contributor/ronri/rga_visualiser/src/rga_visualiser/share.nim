## Read PGA share of front-end's busy time, and share of each side of algebra boundary.
##
## Sampling profiler answers it: each sample is one stack of calls, and one rule names its owner.
##   Sample belongs to side whose code it was running: owner of innermost frame that has one.
##     PGA owns time in its own operators, whoever called them.
##     Algebra owns `motors`, `projections` and `objects`, which compose PGA's operators.
##     Boundary owns `boundary`, which lifts into algebra and reads back out.
##     Euclidean owns `euclid` and `mesh`, which never name multivector.
##   Rest is everything else: consumers' own work, panel, browser's or driver's own work.
##   Innermost, not outermost: `boundary` calling `euclid.normalize` spends Euclidean time.
##     PGA calls back into nothing of project's, so frame in PGA is innermost owned one
##     wherever it stands, and PGA share is time in its operators from any caller.
##     Frame no side owns, as `system`'s copy, belongs to owned frame that called it.
## Each front-end samples its own way, and both read their stacks through this one rule.
##   Desktop: timer on main thread's CPU clock, walking Nim's frames; see `desktop/sampler`.
##   Page: browser's own sampling profiler, where browser allows it; see `diagnostics.ts`.
##   Both name module by its path: desktop frame by file, page function by name JS backend
##   mangles from that same path (`mangled`).
## Share is pooled over `SECONDS_SHARE`: one frame holds few samples, so one frame's is noise.
##
## Shared by desktop (`main.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/strutils


const SECONDS_SHARE* = 20
  ## Span share is pooled over, in seconds.
  ##   Page samples every 10 ms at best, and opening scene's build gets about 4 samples each
  ##   second: 20 s holds about 80, against 11 to 17 in 4 s, which read 35 to 64%.



#[ Type Definitions ]#

type
  Owner* {.pure.} = enum  ## Define who owns one sample's time: side whose code it was running.
    Rest,  ## No side: consumers' own work, panel, browser, driver.
    Pga,  ## PGA, reference library: module `pga` and every module under it.
    Algebra,  ## Project's algebra side, outside PGA; see `MODULES_SIDE`.
    Boundary,  ## Crossing between algebra and Euclidean values; see `MODULES_SIDE`.
    Euclidean  ## Project's Euclidean side; see `MODULES_SIDE`.

  CountsShare* = array[Owner, int]  ## Count busy samples by owner.

  RingShare*[T] = object
    ## Pool counts over `SECONDS_SHARE`, one bucket for each whole second.
    ##   `T` is array of counts, as `CountsShare` is: buckets add it element by element.
    ##     `boundary.CountsCrossing` pools through same ring, so its window is share's.
    ##   Bucket whose second has passed out of window is skipped, never cleared ahead of time,
    ##   so second with no samples costs nothing.
    counts: array[SECONDS_SHARE, T]
    seconds: array[SECONDS_SHARE, int]  ## Whole second each bucket counts; -1 for none yet.



#[ Ownership Rule ]#

const
  PATH_PGA = "/projective_geometric_algebra_illuminated/pga"
    ## Name reference library by tail of its path: module `pga` and every module under it.
  MODULES_SIDE* = [
    ("motors", Owner.Algebra), ("projections", Owner.Algebra), ("objects", Owner.Algebra),
    ("boundary", Owner.Boundary),
    ("euclid", Owner.Euclidean), ("mesh", Owner.Euclidean),
  ]
    ## Name side each of project's modules on either side of algebra boundary belongs to.
    ##   Algebra: stand-ins for operators library lacks, and incidence in algebra's words.
    ##   Boundary: lift and read-out, by coefficient. Euclidean: positions, directions and
    ##   vertices. Every other module consumes these, and its own work is Rest.
  DIRECTORY_PROJECT = "rga_visualiser/"
    ## Name directory project's own modules sit in, under `src`.


func mangled(path: string): string {.compileTime.} =
  ## Spell `path` as JS backend mangles it into each function's name.
  ##   `/` becomes `Z`, `_` becomes `95`, `.` becomes `O`.
  for character in path:
    case character
    of '/': result.add 'Z'
    of '_': result.add "95"
    of '.': result.add 'O'
    else: result.add character


func tailsSidePath(): array[MODULES_SIDE.len, string] {.compileTime.} =
  ## End path of each sided module, as desktop frame names its file.
  for i, (module, _) in MODULES_SIDE: result[i] = DIRECTORY_PROJECT & module & ".nim"


func tailsSideName(): array[MODULES_SIDE.len, string] {.compileTime.} =
  ## End function name JS backend gives inside each sided module.
  for i, (module, _) in MODULES_SIDE: result[i] = mangled(DIRECTORY_PROJECT & module)


func ownersSide(): array[MODULES_SIDE.len, Owner] {.compileTime.} =
  ## Side of each sided module, apart from its name.
  for i, (_, owner) in MODULES_SIDE: result[i] = owner


const
  MARK_NAME_PGA = mangled(PATH_PGA)  ## Mark function name JS backend gives inside library.
  TAILS_SIDE_PATH = tailsSidePath()  ## End path of each sided module's file.
  TAILS_SIDE_NAME = tailsSideName()  ## End name of each sided module's function.
  OWNERS_SIDE = ownersSide()  ## Side of each, by same index.


when not defined(js):
  # Each pushes no frame of its own: sampler's handler calls these over stack it is walking.
  func isContaining(text: cstring, part: string): bool {.stackTrace: off.} =
    ## Say whether `text` holds `part` anywhere.
    ##   Reads and allocates nothing beyond both, so signal handler may call it.
    let (length_text, length_part) = (len(text), len(part))
    for start in 0..(length_text - length_part):
      var i = 0
      while i < length_part and text[start+i] == part[i]: inc i
      if i == length_part: return true
    false


  func isEndingWith(text: cstring, part: string): bool {.stackTrace: off.} =
    ## Say whether `text` ends with `part`; allocates nothing, as `isContaining`.
    let (length_text, length_part) = (len(text), len(part))
    if length_part > length_text: return false
    for i in 0..<length_part:
      if text[length_text-length_part+i] != part[i]: return false
    true


  func ownerOfPath*(path: cstring): Owner {.stackTrace: off.} =
    ## Name owner of one desktop frame, by file its code is in.
    ##   Allocates nothing, so sampler's signal handler calls it on each frame it walks.
    if path.isNil: return Owner.Rest
    if path.isContaining(PATH_PGA): return Owner.Pga
    for i in 0..<TAILS_SIDE_PATH.len:
      if path.isEndingWith(TAILS_SIDE_PATH[i]): return OWNERS_SIDE[i]
    Owner.Rest


func ownerOfName*(name: string): Owner =
  ## Name owner of one page function, by name JS backend gave it.
  ##   Name ends in mangled path of its module, after last `__`.
  let at = name.rfind("__")
  if at < 0: return Owner.Rest
  let module = name[at+2 .. ^1]
  if MARK_NAME_PGA in module: return Owner.Pga
  for i, tail in TAILS_SIDE_NAME:
    if module.endsWith(tail): return OWNERS_SIDE[i]
  Owner.Rest



#[ Pooling ]#

func initRingShare*[T](): RingShare[T] =
  ## Construct ring holding no counts.
  for i in 0..<SECONDS_SHARE: result.seconds[i] = -1


func add*[T](ring: var RingShare[T], second: int, counts: T) =
  ## Count `counts` into whole `second`'s bucket, starting it afresh where it held older second.
  let at = second mod SECONDS_SHARE
  if ring.seconds[at] != second:
    ring.seconds[at] = second
    ring.counts[at] = default(T)
  for i in low(T)..high(T): ring.counts[at][i] += counts[i]


func pooled*[T](ring: RingShare[T], second: int): T =
  ## Sum every bucket inside `SECONDS_SHARE` up to and including whole `second`.
  for at in 0..<SECONDS_SHARE:
    if ring.seconds[at] > second - SECONDS_SHARE and ring.seconds[at] <= second:
      for i in low(T)..high(T): result[i] += ring.counts[at][i]


func busy*(counts: CountsShare): int =
  ## Count every busy sample, whoever owns it: share's denominator.
  for owner in Owner: result += counts[owner]


func percentOf*(counts: CountsShare, owner: Owner): float =
  ## Report `owner`'s share of busy samples, in percent; 0 where nothing was sampled.
  let total = counts.busy
  if total == 0: 0.0 else: 100.0 * float(counts[owner]) / float(total)
