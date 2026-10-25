## Fold tag into tanru units: each word with cmavo binding it, net of conversion, so search
##   compares what tag means rather than how it is spelt.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | TanruUnit           | one word, and cmavo binding it, outer first                 |
##   | Link                | one conversion composed, or one other cmavo binding word    |
##   | Places              | place of word standing at each position after conversion   |
##   | units               | fold words of tag into tanru units                          |
##   | positions           | every place where run stands unbroken                       |
##   | isHoldingUnchanged  | run stands unbroken, and no group around it changes it      |
##   |---------------------|-------------------------------------------------------------|
##
##   Cmavo binding next unit: SE, as scope of SE is only following brivla or equivalent unit
##     (CLL 9.4); NAhE, close-binding on individual brivla (15.4); NU, whose rafsi are short
##     scope modifiers as SE and NAhE rafsi (12.12); NA, whose rafsi `nar` is reserved for
##     lujvo (15.2). Grammar puts SE and NAhE on one tanru unit (21.2, rule 152). JAI binds too,
##     but list gives `jai` no rafsi, so no tag holds it. Every other cmavo binds nothing and
##     stands as unit of its own: KOhA fills place of what follows (7.15), JA joins (5.6).
##   Run of SE composes into one conversion, inner first (9.4): `te se ciska` puts x3 of
##     `ciska` first, and `se se ciska` is `ciska`, since two `se` cancel (12.11). Conversion
##     composing to no change leaves. Other cmavo keep their order against conversion.
##   `ke` opens group, closed by `ke'e` or by end of tag, since `ke'e` elides at end (5.5). Cmavo
##     before `ke` binds whole group (9.4; 12.11, `selkemdzukla`). Group of one unit is that
##     unit, so `se ke ciska` is `se ciska`, and its cmavo join cmavo of that unit.
##   Cmavo that only group drop, since run of units reads no grouping (`search.nim`): `ke` and
##     `ke'e` of group no cmavo binds, `ke'e` closing nothing, `bo` (5.3), and `kei`, which NU
##     rafsi as short scope modifier needs not (12.13). So `kemdatnyvei` folds as `datnyvei`.
##     Cost: `co` inverts order (5.8), yet stays as written, so run across it is not seen.
##   Lujvo leaves `ke` out in two places CLL names. Two SE in row read as SE `ke` SE, so first
##     converts rest of tag (12.11, `selsel-` as `selkemsel-`, `selter-` as `se ke te`).
##     `ke'e` closing nothing implies `ke` after cmavo opening tag, only place where it closes
##     something (15.4, `nalsu'adzuke'ekla`); in tag opening with other word it only groups.
##   Group of two units or more stands as unit `ke` carrying cmavo of group, then its units, then
##     `ke'e` where written; so its units stay whole, as modifier inside converted group does.
##   Group that cmavo bind changes run inside it in three ways. Run ending where group ends holds
##     its head, which conversion converts (5.11) and abstraction turns to event (12.12), so
##     `se ke vreji se ciska` holds `se ciska` changed. Negation denies every part of group
##     (15.4), so `na'e ke se ciska vreji` holds none unchanged. Group that run leaves open must
##     end where run ends, else group in tag runs on, and its cmavo bind more than in run.
##     Modifier inside converted group keeps its places: `se ke se ciska vreji` holds `se ciska`
##     unchanged, yet `se ciska vreji` converted (12.11).
##   Cost: 12.11 reads lujvo, yet tag read from tanru text folds by it too, as tag is lujvo.
##   Cost: cmavo CLL gives no scope for, such as `pe'a` and tense, bind nothing here.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils]

import ./[dictionary, tags]


type
  Places* = array[1..5, int]
    ## Place of word standing at each position after conversion; `xe` reaches x5 (9.4).
  Link* = object  ## Define one step binding unit: conversion composed, or other cmavo.
    places*: Places  ## Conversion composed; `PLACES_SAME` where `operator` binds instead.
    operator*: Option[Word]  ## NAhE, NA or NU cmavo binding unit; none where link converts.
  TanruUnit* = object  ## Define tanru unit: one word, and cmavo binding it (21.2, rule 152).
    word*: Word  ## Brivla, or cmavo binding nothing, as `ke`.
    links*: seq[Link]  ## Steps binding word, outer first; empty where nothing binds it.


const
  PLACES_SAME*: Places = [1, 2, 3, 4, 5]  ## No conversion: each place at its own position.
  CONVERSIONS = ["se", "te", "ve", "xe"]
    ## SE cmavo, in order: `n`th of them swaps x1 with place `n + 2` (9.4).
  OPERATORS = [
    "du'u", "jei", "ka", "li'i", "mu'e", "na", "na'e", "ni", "no'e", "nu", "pu'u", "si'o",
    "su'u", "to'e", "za'i", "zu'o",
  ]
    ## Cmavo other than SE binding next unit, as list holds them: NAhE (15.4), NA (15.2) and
    ##   NU (12.12).
  WORDS_CONVERSION = CONVERSIONS.mapIt(it.word.get)  ## SE cmavo, as words of list.
  WORDS_OPERATOR = OPERATORS.mapIt(it.word.get)  ## Other binding cmavo, as words of list.
  WORD_KE = "ke".word.get  ## Cmavo opening group (5.5).
  WORD_KEHE = "ke'e".word.get  ## Cmavo closing group (5.5).
  WORDS_GROUPING = ["bo", "kei"].mapIt(it.word.get)
    ## Cmavo that only group wherever they stand: `bo` (5.3) and `kei` (12.13).
  WORDS_NEGATION = ["na", "na'e", "no'e", "to'e"].mapIt(it.word.get)
    ## Binding cmavo that deny what they bind: NA (15.2) and NAhE (15.4, 15.5).

static:
  for word in WORDS_CONVERSION & WORDS_OPERATOR & WORDS_GROUPING & @[WORD_KE, WORD_KEHE]:
    doAssert word.kind == Kind.Cmavo, "Folded word should be cmavo; got `" & $word & "`."
  doAssert "jai".word.isNone,
    "List should give `jai` no rafsi, as fold has no JAI (5.11); got entry `jai`."



#[ Folding ]#

func swapping(word: Word): int =
  ## Read place SE cmavo swaps with x1; 0 where word is no SE cmavo.
  let at = WORDS_CONVERSION.find(word)
  if at < 0: 0 else: at + 2


func isBinding*(word: Word): bool =
  ## Test word is cmavo binding next unit: SE, NAhE, NA or NU.
  word in WORDS_CONVERSION or word in WORDS_OPERATOR


func toLinks*(chain: openArray[Word]): seq[Link] =
  ## Fold cmavo binding one word into links, outer first: each run of SE composes into one
  ##   conversion, inner applied first (9.4), and leaves where it composes to no change.
  var places = PLACES_SAME
  for i in countdown(chain.high, 0):
    let swapped = chain[i].swapping
    if swapped > 0:
      swap(places[1], places[swapped])
      continue
    if places != PLACES_SAME: result.add Link(places: places)
    places = PLACES_SAME
    result.add Link(places: PLACES_SAME, operator: some(chain[i]))
  if places != PLACES_SAME: result.add Link(places: places)
  result.reverse


func withImplied(words: openArray[Word]): seq[Word] =
  ## Insert `ke` that lujvo leaves out: after first of two SE in row (12.11), then after cmavo
  ##   opening tag once for each `ke'e` closing nothing (15.4).
  for i, word in words:
    result.add word
    if i + 1 < words.len and word.swapping > 0 and words[i + 1].swapping > 0:
      result.add WORD_KE
  var (depth, lone) = (0, 0)
  for word in result:
    if word == WORD_KE: inc depth
    elif word == WORD_KEHE:
      if depth > 0: dec depth else: inc lone
  var opening = 0
  while opening < result.len and result[opening].isBinding: inc opening
  if opening > 0: result.insert(WORD_KE.repeat(lone), opening)


func ending(words: openArray[Word], start: int): int =
  ## Find index of `ke'e` closing `ke` at `start`, or `words.len` where none does (5.5).
  var depth = 0
  for i in start + 1 ..< words.len:
    if words[i] == WORD_KE: inc depth
    elif words[i] == WORD_KEHE:
      if depth == 0: return i
      dec depth
  words.len


func countItems(words: openArray[Word], start, stop: int): int =
  ## Count units group from `start` to `stop` holds at its own depth: each word binding nothing,
  ##   and each nested group, counts once.
  var i = start
  while i < stop:
    if words[i] == WORD_KE:
      inc result
      i = words.ending(i) + 1
      continue
    if not words[i].isBinding: inc result
    inc i


func withoutGrouping(words: openArray[Word]): seq[Word] =
  ## Drop cmavo that only group: `bo` and `kei`; then, innermost first, `ke` and `ke'e` closing
  ##   it around group holding one unit or bound by no cmavo; then `ke'e` closing nothing. Cmavo
  ##   before dropped `ke` then binds unit after it directly (`se ke ciska` is `se ciska`).
  result = words.filterIt(it notin WORDS_GROUPING)
  var i = result.high
  while i >= 0:
    if result[i] == WORD_KE:
      let stop = result.ending(i)
      if result.countItems(i + 1, stop) == 1 or i == 0 or not result[i - 1].isBinding:
        if stop < result.len: result.delete(stop)
        result.delete(i)
    dec i
  var (kept, depth) = (newSeqOfCap[Word](result.len), 0)
  for word in result:
    if word == WORD_KE: inc depth
    elif word == WORD_KEHE:
      if depth == 0: continue
      dec depth
    kept.add word
  result = kept


func units*(words: openArray[Word]): seq[TanruUnit] =
  ## Fold words of tanru into units: implied `ke` inserted, cmavo that only group dropped, and
  ##   cmavo binding each word folded into its links.
  var chain: seq[Word]
  for word in words.withImplied.withoutGrouping:
    if word.isBinding:
      chain.add word
      continue
    result.add TanruUnit(word: word, links: chain.toLinks)
    chain.setLen 0


func units*(tag: Tag): seq[TanruUnit] = tag.words.units
  ## Fold words of tag into units.



#[ Runs ]#

func positions*[T](items, run: openArray[T]): seq[int] =
  ## List every index where `run` stands in `items` unbroken and in order; none for empty `run`.
  if run.len == 0: return
  for start in 0 .. items.len - run.len:
    if (0 ..< run.len).allIt(items[start + it] == run[it]): result.add start


func isChanged(units: openArray[TanruUnit], start, stop: int): bool =
  ## Test group around units from `start` to before `stop` changes them: group run leaves open
  ##   runs on past it, or group that encloses run ends where run ends, so run holds its head
  ##   (5.11, 12.12), or cmavo deny group that encloses run (15.4).
  var open = 0
  for i in start ..< stop:
    if units[i].word == WORD_KE: inc open
    elif units[i].word == WORD_KEHE and open > 0: dec open
  var finish = stop
  for _ in 1 .. open:
    if finish == units.len: break
    if units[finish].word != WORD_KEHE: return true
    inc finish
  let words = units.mapIt(it.word)
  var depth = 0
  for i in countdown(start - 1, 0):
    if units[i].word == WORD_KEHE:
      inc depth
    elif units[i].word == WORD_KE:
      if depth > 0:
        dec depth
        continue
      if units[i].links.anyIt(it.operator.isSome and it.operator.get in WORDS_NEGATION):
        return true
      if words.ending(i) == finish: return true
  false


func isHoldingUnchanged*(units, run: openArray[TanruUnit]): bool =
  ## Test `run` stands in `units` unbroken somewhere no group around it changes it.
  units.positions(run).anyIt(not units.isChanged(it, it + run.len))
