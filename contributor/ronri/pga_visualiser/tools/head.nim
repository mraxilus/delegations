## Hold pin of `pga` to head of its repository, for driver's `head` verb.
##   Library sits three directories inside `replications`, so head is compared by tree of
##     library's own directory, never by commit: commit elsewhere in that repository changes
##     nothing this project builds against.
##   Pure over what driver reads, i.e. lock, commits and trees, so suite feeds it on both
##     backends; git and network stay in driver. Module of its own for reason
##     `declarations.nim` gives: driver compiles no project code.
##   Rejected: comparing commits, which opens issue for every change elsewhere in repository.
##   Cost: pin that lags head fails `head`, which `head.yml` runs daily and which keeps one
##     issue open until pin follows; no merge waits on it, so library moving is never red here.

{.experimental: "strictFuncs".}

import std/json


const DIGITS_SHORT = 7  ## Digits of commit finding names, as `git log --oneline` prints.



#[ Pin And Head ]#

func short(commit: string): string =
  ## Shorten commit for finding.
  if commit.len > DIGITS_SHORT: commit[0..<DIGITS_SHORT] else: commit


proc commitPinned*(lock: string): string =
  ## Read commit `atlas.lock` pins library at; empty where lock names none.
  ##   Lock names one item, `replications`, so first commit found is library's.
  ##   Proc rather than func: `parseJson` declares side effect.
  let items = parseJson(lock){"items"}
  if items.isNil: return ""
  for _, item in items.pairs: return item{"commit"}.getStr
  ""


func findingHead*(pin, tree_pin, head, tree_head: string): string =
  ## Read finding of pin against head; empty where library's tree at pin is its tree at head.
  if tree_pin.len == 0:
    return "Library at pin unread; restore it through `koch fetch-deps`; got pin `" &
        pin.short & "`."
  if head.len == 0 or tree_head.len == 0:
    return "Library head unread; got head `" & head.short & "`."
  if tree_pin != tree_head:
    return "Pin lags library head; move pin to head, and run every check there; got head `" &
        head.short & "`, pin `" & pin.short & "`."
  ""
