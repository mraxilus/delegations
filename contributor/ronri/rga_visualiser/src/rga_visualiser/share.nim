## Read what share of front-end's busy time reference library takes, and project's own algebra.
##
## Sampling profiler answers it: each sample is one stack of calls, and one rule names its owner.
##   Library owns sample with any frame inside `pga`.
##     Library calls back into nothing of project's, so whatever runs under it is its own.
##   Project's own algebra owns sample with frame in one of `MODULES_ALGEBRA`, and none in library.
##   Rest is everything else: drawing, panel, browser's or driver's own work.
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
  Owner* {.pure.} = enum  ## Define who owns one sample's time, in rule's order of precedence.
    Rest,  ## Neither library nor project's algebra: drawing, panel, browser, driver.
    Algebra,  ## Project's own algebra, one of `MODULES_ALGEBRA`.
    Library  ## Reference library, `pga`.

  CountsShare* = array[Owner, int]  ## Count busy samples by owner.

  RingShare* = object
    ## Pool counts over `SECONDS_SHARE`, one bucket for each whole second.
    ##   Bucket whose second has passed out of window is skipped, never cleared ahead of time,
    ##   so second with no samples costs nothing.
    counts: array[SECONDS_SHARE, CountsShare]
    seconds: array[SECONDS_SHARE, int]  ## Whole second each bucket counts; -1 for none yet.



#[ Ownership Rule ]#

const
  PATH_LIBRARY = "/projective_geometric_algebra_illuminated/pga"
    ## Name reference library by tail of its path: module `pga` and every module under it.
  MODULES_ALGEBRA* = ["motors", "projections", "objects", "boundary"]
    ## Name project's modules whose own work is algebra.
    ##   `motors` and `projections` carry operators library lacks; `objects` asks incidence
    ##   questions in algebra's words; `boundary` lifts into algebra and reads back out.
    ##   Others that import `pga` only call it, and their own work is drawing or picking.
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


func tailsAlgebraPath(): array[MODULES_ALGEBRA.len, string] {.compileTime.} =
  ## End path of each project algebra module, as desktop frame names its file.
  for i, module in MODULES_ALGEBRA: result[i] = DIRECTORY_PROJECT & module & ".nim"


func tailsAlgebraName(): array[MODULES_ALGEBRA.len, string] {.compileTime.} =
  ## End function name JS backend gives inside each project algebra module.
  for i, module in MODULES_ALGEBRA: result[i] = mangled(DIRECTORY_PROJECT & module)


const
  MARK_LIBRARY_NAME = mangled(PATH_LIBRARY)  ## Mark function name JS backend gives inside library.
  TAILS_ALGEBRA_PATH = tailsAlgebraPath()  ## End path of each project algebra module's file.
  TAILS_ALGEBRA_NAME = tailsAlgebraName()  ## End name of each project algebra module's function.


when not defined(js):
  # Each pushes no frame of its own: sampler's handler calls these over stack it is walking.
  func isContaining(text: cstring, part: string): bool {.stackTrace: off.} =
    ## Say whether `text` holds `part` anywhere.
    ##   Reads and allocates nothing beyond both, so signal handler may call it.
    let (length_text, length_part) = (len(text), len(part))
    for start in 0..(length_text - length_part):
      var i = 0
      while i < length_part and text[start + i] == part[i]: inc i
      if i == length_part: return true
    false


  func isEndingWith(text: cstring, part: string): bool {.stackTrace: off.} =
    ## Say whether `text` ends with `part`; allocates nothing, as `isContaining`.
    let (length_text, length_part) = (len(text), len(part))
    if length_part > length_text: return false
    for i in 0..<length_part:
      if text[length_text - length_part + i] != part[i]: return false
    true


  func ownerOfPath*(path: cstring): Owner {.stackTrace: off.} =
    ## Name owner of one desktop frame, by file its code is in.
    ##   Allocates nothing, so sampler's signal handler calls it on each frame it walks.
    if path.isNil: return Owner.Rest
    if path.isContaining(PATH_LIBRARY): return Owner.Library
    for i in 0..<TAILS_ALGEBRA_PATH.len:
      if path.isEndingWith(TAILS_ALGEBRA_PATH[i]): return Owner.Algebra
    Owner.Rest


func ownerOfName*(name: string): Owner =
  ## Name owner of one page function, by name JS backend gave it.
  ##   Name ends in mangled path of its module, after last `__`.
  let at = name.rfind("__")
  if at < 0: return Owner.Rest
  let module = name[at + 2 .. ^1]
  if MARK_LIBRARY_NAME in module: return Owner.Library
  for tail in TAILS_ALGEBRA_NAME:
    if module.endsWith(tail): return Owner.Algebra
  Owner.Rest



#[ Pooling ]#

func initRingShare*(): RingShare =
  ## Construct ring holding no samples.
  for i in 0..<SECONDS_SHARE: result.seconds[i] = -1


func add*(ring: var RingShare, second: int, counts: CountsShare) =
  ## Count `counts` into whole `second`'s bucket, starting it afresh where it held older second.
  let at = second mod SECONDS_SHARE
  if ring.seconds[at] != second:
    ring.seconds[at] = second
    ring.counts[at] = default(CountsShare)
  for owner in Owner: ring.counts[at][owner] += counts[owner]


func pooled*(ring: RingShare, second: int): CountsShare =
  ## Sum every bucket inside `SECONDS_SHARE` up to and including whole `second`.
  for at in 0..<SECONDS_SHARE:
    if ring.seconds[at] > second - SECONDS_SHARE and ring.seconds[at] <= second:
      for owner in Owner: result[owner] += ring.counts[at][owner]


func busy*(counts: CountsShare): int =
  ## Count every busy sample, whoever owns it: share's denominator.
  for owner in Owner: result += counts[owner]


func percentOf*(counts: CountsShare, owner: Owner): float =
  ## Report `owner`'s share of busy samples, in percent; 0 where nothing was sampled.
  let total = counts.busy
  if total == 0: 0.0 else: 100.0 * float(counts[owner]) / float(total)
