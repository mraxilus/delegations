## Fold tanru into tanru units: each word with cmavo binding it, net of conversion, so two
##   spellings of one meaning fold alike.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | TanruUnit           | one part of tanru, and cmavo binding it, outer first        |
##   | Link                | one conversion composed, or one other cmavo binding word    |
##   | Places              | place of word standing at each position after conversion   |
##   | tanruUnits          | fold parts of tanru into tanru units                        |
##   |---------------------|-------------------------------------------------------------|
##
##   Sibling: part of `lojban_tagger/src/lojban_tagger/tanru_units.nim` holds earlier copy, folding
##     listed words alone, until #809 drops it (II.9); its `positions` and `isHoldingUnchanged`,
##     which search reads, have no copy here.
##   Fold reads parts (`tanru.nim`): binding cmavo are words of list, so part no list names
##     binds nothing, and stands as tanru unit of its own.
##   Cmavo binding next tanru unit: SE, as SE binds only following brivla or "equivalent unit"
##     (CLL 9.4); NAhE, close-binding on individual brivla (15.4); NU, whose rafsi modify next
##     tanru unit alone, as SE and NAhE rafsi do (12.12). Grammar puts SE and NAhE on one
##     tanru unit (21.2, rule 152). JAI binds too, but list gives `jai` no rafsi, so no lujvo
##     holds it.
##   NA binds whole tanru: `na` applies to entire bridi, and not to part of selbri (15.2). So
##     odd count of `na`, wherever it stands, folds as one `na` before group of whole tanru, and
##     even count as none, since adjacent `na` cancel out (15.2).
##   Every other cmavo binds nothing, and stands as tanru unit of its own where it does not
##     only group: KOhA fills place of what follows (7.15), JA joins (5.6).
##     Cost: number and MOI form one tanru unit (21.2, rule 152), yet each digit stands as
##     tanru unit of its own, so `relpavmomci'a` folds `re`, `pa` and `moi` apart.
##   Run of SE binding one tanru unit composes into one conversion, inner first (9.4):
##     `te se ciska` puts x3 of `ciska` first, and `se se ciska` is `ciska`, since two `se`
##     cancel (12.11). Conversion composing to no change leaves. Other cmavo keep their order
##     against it.
##   `ke` opens group, closed by `ke'e` or by end of tanru, since `ke'e` elides at end (5.5).
##     Cmavo before `ke` binds whole group (9.4; 12.11, `selkemdzukla`). Group of one tanru unit
##     is that tanru unit: `se ke ciska` is `se ciska`, and cmavo before `ke` join its own.
##   Cmavo that only group drop, since fold tells what cmavo bind: `ke` and `ke'e` of group no
##     cmavo binds, or whose cmavo fold to no link, `ke'e` closing nothing, and `bo` (5.3). So
##     `kemdatnyvei` folds as `datnyvei`.
##     Cost: grouping that no cmavo binds is lost, so `datni ke vreji liste` folds as `datni
##     vreji liste`, which 5.3 groups otherwise.
##   `kei` closes abstraction (21.2, rule 152): it reads as `ke'e` closing `ke` after its NU, so
##     `nu citka gasnu kei klama` abstracts two tanru units. After one tanru unit that group is
##     of one, as `kez` of `nunctikezgau` tells only what reader would guess (12.13).
##   No group holds `co`: `ke'e` goes in before it for each group open there (5.8).
##     Cost: `co` inverts order (5.8), yet stays as written, so fold keeps written order.
##   Lujvo leaves `ke` out in two places CLL names. Two SE in row read as SE `ke` SE, so first
##     converts rest of tanru, up to `ke'e` closing it (12.11, `selsel-` as `selkemsel-`).
##     `ke'e` closing nothing implies `ke` after nearest run of binding cmavo before it that
##     leaves two tanru units or more up to it, only place where `ke'e` means something
##     (15.4, `nalsu'adzuke'ekla`); with no such run, `ke'e` only groups, and drops.
##     Cost: run of `na'e se` before such group binds group by both, where 15.4 names `na'e`.
##   Group of two tanru units or more stands as tanru unit `ke` carrying cmavo of group, then
##     its tanru units, then `ke'e` where written; so its tanru units stay whole, as modifier
##     inside converted group does.
##   Cost: 12.11 reads lujvo, yet tanru `readTanru` reads from text folds by it too.
##   Cost: `pe'a` and tense cmavo bind nothing here, though CLL gives them whole lujvo (13.13)
##     or whole bridi (5.13).

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils]

import ./[dictionary, forms, tanru]


type
  Places* = array[1..5, int]
    ## Place of word standing at each position after conversion; `xe` reaches x5 (9.4).
  Link* = object  ## Define one step binding tanru unit: conversion composed, or other cmavo.
    places*: Places  ## Conversion composed; `PLACES_SAME` where `operator` binds instead.
    operator*: Option[Word]  ## NAhE, NA or NU cmavo binding tanru unit; none where link converts.
  TanruUnit* = object  ## Define tanru unit: one word, and cmavo binding it (21.2, rule 152).
    part*: Part  ## Brivla, or cmavo binding nothing, as `ke`; part no list names binds nothing.
    links*: seq[Link]  ## Steps binding word, outer first; empty where nothing binds it.


const
  PLACES_SAME*: Places = [1, 2, 3, 4, 5]  ## No conversion: each place at its own position.
  CONVERSIONS = ["se", "te", "ve", "xe"]
    ## SE cmavo, in order: `n`th of them swaps x1 with place `n + 2` (9.4).
  ABSTRACTIONS = [
    "du'u", "jei", "ka", "li'i", "mu'e", "ni", "nu", "pu'u", "si'o", "su'u", "za'i", "zu'o",
  ]
    ## NU cmavo, as list holds them: each binds next tanru unit (12.12), or tanru units up to
    ##   its `kei`.
  NEGATIONS = ["na", "na'e", "no'e", "to'e"]
    ## Binding cmavo that deny what they bind: NA (15.2) and NAhE (15.4, 15.5).
  WORDS_CONVERSION = CONVERSIONS.mapIt(it.word.get)  ## SE cmavo, as words of list.
  WORDS_ABSTRACTION = ABSTRACTIONS.mapIt(it.word.get)  ## NU cmavo, as words of list.
  WORDS_NEGATION = NEGATIONS.mapIt(it.word.get)  ## Denying cmavo, as words of list.
  WORDS_OPERATOR = WORDS_ABSTRACTION & WORDS_NEGATION  ## Binding cmavo other than SE.
  WORD_NA = "na".word.get  ## Cmavo denying entire bridi (15.2).
  WORD_KE = "ke".word.get  ## Cmavo opening group (5.5).
  WORD_KEHE = "ke'e".word.get  ## Cmavo closing group (5.5).
  WORD_KEI = "kei".word.get  ## Cmavo closing abstraction (21.2, rule 152).
  WORD_BO = "bo".word.get  ## Cmavo that only groups, wherever it stands (5.3).
  WORD_CO = "co".word.get  ## Cmavo inverting tanru, which no group holds (5.8).

static:
  for word in WORDS_CONVERSION & WORDS_OPERATOR & @[WORD_KE, WORD_KEHE, WORD_KEI, WORD_BO, WORD_CO]:
    doAssert word.kind == Kind.Cmavo, "Folded word should be cmavo; got `" & $word & "`."
  doAssert "jai".word.isNone,
    "List should give `jai` no rafsi, as fold has no JAI (5.11); got entry `jai`."



#[ Folding ]#

func isWord(part: Part, w: Word): bool = part.is_listed and part.word == w
  ## Test part is listed word `w`.


func swapping(word: Word): int =
  ## Read place SE cmavo swaps with x1; 0 where word is no SE cmavo.
  let at = WORDS_CONVERSION.find(word)
  if at < 0: 0 else: at + 2


func swapping(part: Part): int = (if part.is_listed: part.word.swapping else: 0)
  ## Read place SE cmavo of part swaps with x1; 0 where part is no SE cmavo.

func isAbstraction(part: Part): bool = part.is_listed and part.word in WORDS_ABSTRACTION
  ## Test part is NU cmavo.


func isBinding*(part: Part): bool =
  ## Test part is cmavo binding next tanru unit: SE, NAhE, NA or NU; part no list names is none.
  part.is_listed and (part.word in WORDS_CONVERSION or part.word in WORDS_OPERATOR)


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


func ending(parts: openArray[Part], start: int): int =
  ## Find index of `ke'e` closing `ke` at `start`, or `parts.len` where none does (5.5).
  var depth = 0
  for i in start + 1 ..< parts.len:
    if parts[i].isWord(WORD_KE): inc depth
    elif parts[i].isWord(WORD_KEHE):
      if depth == 0: return i
      dec depth
  parts.len


func countItems(parts: openArray[Part], start, stop: int): int =
  ## Count tanru units group from `start` to `stop` holds at its own depth: each part binding
  ##   nothing, and each nested group, counts once.
  var i = start
  while i < stop:
    if parts[i].isWord(WORD_KE):
      inc result
      i = parts.ending(i) + 1
      continue
    if not parts[i].isBinding: inc result
    inc i


func depthAt(parts: openArray[Part], stop: int): int =
  ## Count groups open just before index `stop`.
  for part in parts[0 ..< stop]:
    if part.isWord(WORD_KE): inc result
    elif part.isWord(WORD_KEHE) and result > 0: dec result


func placeOpening(parts: openArray[Part]): int =
  ## Find index after nearest run of binding cmavo, inside no group, with two tanru units or more
  ##   after it; -1 where none is.
  for at in countdown(parts.len, 1):
    if not parts[at - 1].isBinding or (at < parts.len and parts[at].isBinding): continue
    if parts.depthAt(at) == 0 and parts.countItems(at, parts.len) >= 2: return at
  -1


func withImplied(parts: openArray[Part]): seq[Part] =
  ## Insert `ke` and `ke'e` that lujvo leaves out. Odd count of `na` sets one `na ke` before
  ##   whole tanru, and even count none, as `na` applies to entire bridi and two cancel (15.2).
  ##   `ke` goes after first of two SE in row (12.11). `kei` reads as `ke'e` closing `ke` after
  ##   nearest NU it may close (21.2, rule 152), and drops where no NU stands before it.
  let plain = parts.filterIt(not it.isWord(WORD_NA))
  if (parts.len - plain.len) mod 2 == 1: result.add [WORD_NA.toPart, WORD_KE.toPart]
  var abstractions: seq[int]
  for i, part in plain:
    if part.isWord(WORD_KEI):
      if abstractions.len > 0:
        result.insert(WORD_KE.toPart, abstractions.pop + 1)
        result.add WORD_KEHE.toPart
      continue
    if part.isAbstraction: abstractions.add result.len
    result.add part
    if i + 1 < plain.len and part.swapping > 0 and plain[i + 1].swapping > 0:
      result.add WORD_KE.toPart


func withClosedBeforeCo(parts: openArray[Part]): seq[Part] =
  ## Close each group open before `co` with `ke'e` there, since no group holds `co` (5.8).
  var depth = 0
  for part in parts:
    if part.isWord(WORD_KE): inc depth
    elif part.isWord(WORD_KEHE) and depth > 0: dec depth
    elif part.isWord(WORD_CO):
      for _ in 1 .. depth: result.add WORD_KEHE.toPart
      depth = 0
    result.add part


func withLoneOpened(parts: openArray[Part]): seq[Part] =
  ## Open group for each `ke'e` closing nothing, with `ke` after nearest run of binding cmavo
  ##   that leaves two tanru units or more up to it, only place where `ke'e` means something (15.4);
  ##   drop `ke'e` where no such run is.
  var depth = 0
  for part in parts:
    if part.isWord(WORD_KE): inc depth
    elif part.isWord(WORD_KEHE):
      if depth > 0: dec depth
      else:
        let at = result.placeOpening
        if at < 0: continue
        result.insert(WORD_KE.toPart, at)
    result.add part


func withoutGrouping(parts: openArray[Part]): seq[Part] =
  ## Drop cmavo that only group: `bo`; then, innermost first, `ke` and `ke'e` closing it around
  ##   group holding one tanru unit or bound by no cmavo; then `ke'e` closing nothing. Cmavo before
  ##   dropped `ke` then binds tanru unit after it directly (`se ke ciska` is `se ciska`).
  result = parts.filterIt(not it.isWord(WORD_BO))
  var i = result.high
  while i >= 0:
    if result[i].isWord(WORD_KE):
      let stop = result.ending(i)
      if result.countItems(i + 1, stop) == 1 or i == 0 or not result[i - 1].isBinding:
        if stop < result.len: result.delete(stop)
        result.delete(i)
    dec i
  var (kept, depth) = (newSeqOfCap[Part](result.len), 0)
  for part in result:
    if part.isWord(WORD_KE): inc depth
    elif part.isWord(WORD_KEHE):
      if depth == 0: continue
      dec depth
    kept.add part
  result = kept


func tanruUnits*(parts: openArray[Part]): seq[TanruUnit] =
  ## Fold parts of tanru into tanru units: implied `ke` and `ke'e` inserted, cmavo that only group
  ##   dropped, and cmavo binding each part folded into its links. Group whose cmavo fold to
  ##   no link binds nothing, so its `ke` and `ke'e` drop too (12.11).
  var
    chain: seq[Word]
    dropping: seq[bool]
  for part in parts.withImplied.withClosedBeforeCo.withLoneOpened.withoutGrouping:
    if part.isBinding:
      chain.add part.word
      continue
    let links = chain.toLinks
    chain.setLen 0
    if part.isWord(WORD_KE):
      dropping.add links.len == 0
      if links.len == 0: continue
    elif part.isWord(WORD_KEHE) and dropping.len > 0:
      if dropping.pop: continue
    result.add TanruUnit(part: part, links: links)


func tanruUnits*(tanru: Tanru): seq[TanruUnit] = tanru.parts.tanruUnits
  ## Fold parts of tanru into tanru units.
