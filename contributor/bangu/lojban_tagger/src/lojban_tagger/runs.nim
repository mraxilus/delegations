## Find runs of tanru units that tag holds unbroken and unchanged, which search ranks by.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | positions           | every place where run stands unbroken                       |
##   | isHoldingUnchanged  | run stands unbroken, and no group around it changes it      |
##   |---------------------|-------------------------------------------------------------|
##
##   Tanru units come from fold of `lojban_parser` (`tanru_units.nim` there), which keeps `ke`
##     and `ke'e` of each group that cmavo bind as tanru units of their own, and drops rest.
##   Group that cmavo bind changes run inside it in three ways. Run ending where group ends holds
##     its head, which conversion converts (5.11) and abstraction turns to event (12.12), so
##     `se ke vreji se ciska` holds `se ciska` changed. Negation denies every part of group
##     (15.4), so `na'e ke se ciska vreji` holds none unchanged. Group that run leaves open must
##     end where run ends, else group in tag runs on, and its cmavo bind more than in run.
##     Modifier inside converted group keeps its places: `se ke se ciska vreji` holds `se ciska`
##     unchanged, yet `se ciska vreji` converted (12.11).
##   Role of each cmavo is read from its selma'o, as cmavo list of parser gives it (chapter 20):
##     KE opens group, KEhE closes it, NA and NAhE deny. Fold makes no other cmavo deny, so test
##     is exact, and runs name no word of fold, whose words parser keeps private.
##   `ending` walks tanru units as `ending` of parser walks parts before fold, which parser keeps
##     private (II.9); fix to one is finished only when other is checked.

{.experimental: "strictFuncs".}

import std/[options, sequtils]

import ../../../lojban_parser/src/lojban_parser


func isSelmaho(unit: TanruUnit, selmaho: Selmaho): bool =
  ## Test tanru unit is listed cmavo of selma'o `selmaho` (chapter 20).
  unit.part.is_listed and ($unit.part.word).selmaho == some(selmaho)


func isDenying(link: Link): bool =
  ## Test link is cmavo denying what it binds: NA (15.2) or NAhE (15.4).
  if link.operator.isNone: return false
  let found = ($link.operator.get).selmaho
  found.isSome and found.get in {Selmaho.Na, Selmaho.Nahe}


func positions*[T](items, run: openArray[T]): seq[int] =
  ## List every index where `run` stands in `items` unbroken and in order; none for empty `run`.
  if run.len == 0: return
  for start in 0 .. items.len - run.len:
    if (0 ..< run.len).allIt(items[start + it] == run[it]): result.add start


func isChanged(held: openArray[TanruUnit], start, stop: int): bool =
  ## Test group around tanru units from `start` to before `stop` changes them: group run leaves open
  ##   runs on past it, or group that encloses run ends where run ends, so run holds its head
  ##   (5.11, 12.12), or cmavo deny group that encloses run (15.4).

  func ending(held: openArray[TanruUnit], start: int): int =
    ## Find index of `ke'e` closing `ke` at `start`, or `held.len` where none does (5.5).
    var depth = 0
    for i in start + 1 ..< held.len:
      if held[i].isSelmaho(Selmaho.Ke): inc depth
      elif held[i].isSelmaho(Selmaho.Kehe):
        if depth == 0: return i
        dec depth
    held.len

  # Close each group run opens with `ke'e` right after run; group run leaves open changes it.
  var open = 0
  for i in start ..< stop:
    if held[i].isSelmaho(Selmaho.Ke): inc open
    elif held[i].isSelmaho(Selmaho.Kehe) and open > 0: dec open
  var finish = stop
  for _ in 1 .. open:
    if finish == held.len: break
    if not held[finish].isSelmaho(Selmaho.Kehe): return true
    inc finish

  # Test each group enclosing run: one that cmavo deny, or one ending where run ends, changes it.
  var depth = 0
  for i in countdown(start - 1, 0):
    if held[i].isSelmaho(Selmaho.Kehe):
      inc depth
    elif held[i].isSelmaho(Selmaho.Ke):
      if depth > 0:
        dec depth
        continue
      if held[i].links.anyIt(it.isDenying): return true
      if held.ending(i) == finish: return true
  false


func isHoldingUnchanged*(held, run: openArray[TanruUnit]): bool =
  ## Test `run` stands in `held` unbroken somewhere no group around it changes it.
  held.positions(run).anyIt(not held.isChanged(it, it + run.len))
