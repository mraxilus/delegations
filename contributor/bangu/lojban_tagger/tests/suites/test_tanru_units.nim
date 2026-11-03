## Replicate what cmavo bind in CLL chapters 5, 7, 9, 12 and 15 against `tanru_units.nim`: which
##   word each cmavo binds, how conversions compose, and where lujvo leaves `ke` out.
##   Each assertion folds example CLL gives, or tanru of `ciska`, `vreji` and `gunka` where
##     section gives none holding SE. Tanru is read as text, so no rafsi choice enters; where
##     CLL gives lujvo, its words are those reader gives it.
##   Laws enumerate small domains whole: every chain of SE up to `LENGTH_CHAIN`, every chain of
##     binding cmavo up to `LENGTH_GROUPED` before group of one, every tanru over `ALPHABET` up
##     to `LENGTH_TANRU` words; counts are named beside each claim.
##   Places of conversion are checked against oracle swapping names of places as text, so it
##     shares no code with `toLinks`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[dictionary, tags, tanru_units]


const
  LENGTH_CHAIN = 4  ## Longest chain of SE folded by law of composition.
  COUNT_CHAINS = 1 + 4 + 16 + 64 + 256  ## Chains of SE of length 0 to `LENGTH_CHAIN`.
  LENGTH_GROUPED = 2  ## Longest chain of binding cmavo put before group of one by law.
  COUNT_GROUPED = 1 + 4 + 16  ## Chains of `BINDING` of length 0 to `LENGTH_GROUPED`.
  BINDING = ["se", "te", "na'e", "nu"]  ## Binding cmavo laws draw: two SE, NAhE and NU.
  ALPHABET = ["se", "te", "ke", "ke'e", "na'e", "ciska", "vreji"]
    ## Words tanru of gismu law draws: binding cmavo, grouping cmavo and two gismu.
  LENGTH_TANRU = 4  ## Longest tanru gismu law folds, last word gismu.
  COUNT_TANRU = (1 + 7 + 49 + 343) * 2  ## Tanru of that law: prefix of up to three, then gismu.
  CONVERSIONS = ["se", "te", "ve", "xe"]  ## SE cmavo, as 9.4 orders them.
  LINK_SE = Link(places: [2, 1, 3, 4, 5])  ## Link of `se`: x1 and x2 swap places (9.4).
  ABSTRACTORS = [
    "du'u", "jei", "ka", "li'i", "mu'e", "ni", "nu", "pu'u", "si'o", "su'u", "za'i", "zu'o",
  ]
    ## NU cmavo that list gives rafsi (11.13).


func folded(text: string): seq[TanruUnit] =
  ## Fold tanru text, words joined by `+`, into tanru units.
  readTanru(text).get.tanruUnits


func tanruUnit(text: string, links: seq[Link] = @[]): TanruUnit =
  ## Build tanru unit of word `text` bound by `links`, outer first.
  TanruUnit(word: text.word.get, links: links)


func conversion(places: Places): Link =
  ## Build link of conversion putting places in order `places`.
  Link(places: places)


func operator(text: string): Link =
  ## Build link of binding cmavo `text` other than SE.
  Link(places: PLACES_SAME, operator: some(text.word.get))


func placesOracle(chain: openArray[string]): Places =
  ## Compose conversions of `chain` by swapping names of places as text, inner first (9.4).
  var names = @["x1", "x2", "x3", "x4", "x5"]
  for i in countdown(chain.high, 0):
    let swapped = CONVERSIONS.find(chain[i]) + 1
    swap(names[0], names[swapped])
  for i, name in names: result[i + 1] = int(name[1]) - int('0')


func chains(alphabet: openArray[string], length: int): seq[seq[string]] =
  ## List every chain over `alphabet` of length 0 to `length`, shorter first.
  result = @[newSeq[string]()]
  for size in 1 .. length:
    for prefix in result.filterIt(it.len == size - 1):
      for word in alphabet: result.add prefix & word



suite "Chapter 5":
  test "Section 5.3":
    check folded("vreji+bo+se+ciska") == folded("vreji+se+ciska")  # 5.3, `bo` only groups
    check "veirborselci'a".readTag.tag.tanruUnits == folded("vreji+se+ciska")  # 5.3, as `bo`


  test "Section 5.5":
    check folded("se+ke+ciska") == folded("se+ciska")  # 5.5, group is single component
    check folded("se+ke+ciska+vreji") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("ciska"), tanruUnit("vreji")]  # 5.5
    check folded("se+ke+ciska+vreji+ke'e+gunka") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("ciska"), tanruUnit("vreji"), tanruUnit("ke'e"),
      tanruUnit("gunka"),
    ]  # 5.5, `ke'e` closes group, so `gunka` stands outside it
    let closed = folded("se+ke+ciska+vreji+ke'e+gunka")
    check not closed.isHoldingUnchanged(folded("ciska+vreji"))  # 5.5, `se` binds group whole
    check closed.isHoldingUnchanged(folded("ciska"))  # 5.5, part of group stays as it is
    check folded("se+ke+te+ke+ciska+vreji+ke'e+gunka") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("ke", @[conversion([3, 2, 1, 4, 5])]),
      tanruUnit("ciska"), tanruUnit("vreji"), tanruUnit("ke'e"), tanruUnit("gunka"),
    ]  # 5.5, group inside group: `ke'e` closes inner one, and end of tag outer one


  test "Section 5.8":
    check folded("se+ke+ciska+co+gunka") ==
        folded("se+ciska+co+gunka")  # 5.8, `ke'e` implied before `co`: group holds one tanru unit
    check not "selkemselci'aveicolgu'a".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska+vreji"))  # 5.8, group ends before `co`, so `se` converts run whole


  test "Section 5.11":
    check folded("se+cadzu+klama") ==
        @[tanruUnit("cadzu", @[LINK_SE]), tanruUnit("klama")]  # 5.11, Example 11.5
    check folded("cadzu+se+klama") ==
        @[tanruUnit("cadzu"), tanruUnit("klama", @[LINK_SE])]  # 5.11, Example 11.6
    check folded("se+ke+cadzu+klama") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("cadzu"), tanruUnit("klama")]  # 5.11, 11.4
    check not "selkemveiselci'a".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 5.11, converting tanru converts its head: here `se se ciska`
    check "selkemselci'avei".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 5.11, modifier of converted tanru keeps its own places



suite "Chapter 7":
  test "Section 7.15":
    check "fo'arselsanga".readTag.tag.tanruUnits ==
        @[tanruUnit("fo'a"), tanruUnit("sanga", @[LINK_SE])]  # 7.15, Example 15.3



suite "Chapter 9":
  test "Section 9.4":
    for i, text in CONVERSIONS:
      var places = PLACES_SAME
      swap(places[1], places[i + 2])
      check folded(text & "+klama") == @[tanruUnit("klama", @[conversion(places)])]  # 9.4, x1 swaps
    check folded("te+se+klama") == @[
      tanruUnit("klama", @[conversion([3, 1, 2, 4, 5])]),
    ]  # 9.4, x1 is origin of x2's going to x3
    check folded("se+te+se+klama") ==
        @[tanruUnit("klama", @[conversion([1, 3, 2, 4, 5])])]  # 9.4, "setese" swaps x2 and x3
    check folded("se+ke+blanu+zdani") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("blanu"), tanruUnit("zdani")]  # 9.4, 4.8
    check folded("se+na'e+se+ciska") == @[
      tanruUnit("ciska", @[LINK_SE, operator("na'e"), LINK_SE]),
    ]  # 9.4, SE converts following tanru unit, here `na'e se ciska` (21.2, rule 152)



suite "Chapter 12":
  test "Section 12.11":
    check folded("se+se+gleki") == folded("gleki")  # 12.11, two `se` cancel each other
    check folded("se+se+gleki+zmadu") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("gleki", @[LINK_SE]), tanruUnit("zmadu"),
    ]  # 12.11, `selsel-` as `selkemsel-`
    check folded("se+te+gleki+zmadu") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("gleki", @[conversion([3, 2, 1, 4, 5])]),
      tanruUnit("zmadu"),
    ]  # 12.11, `selter-` as "se ke te"
    check "seldzukla".readTag.tag.tanruUnits ==
        @[tanruUnit("cadzu", @[LINK_SE]), tanruUnit("klama")]  # 12.11, "selcadzu klama"
    check "selkemdzukla".readTag.tag.tanruUnits ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("cadzu"), tanruUnit("klama")]  # 12.11
    check "nalbrablo".readTag.tag.tanruUnits ==
        @[tanruUnit("barda", @[operator("na'e")]), tanruUnit("bloti")]  # 12.11, "non-big boat"
    let converse = "selselgekmau".readTag.tag.tanruUnits
    check not converse.isHoldingUnchanged(folded("se+gleki+zmadu"))  # 12.11, "se selgekmau"
    check converse.isHoldingUnchanged(folded("se+gleki"))  # 12.11, `se gleki` modifies `zmadu`
    check folded("se+gleki+zmadu").isHoldingUnchanged(
        folded("se+gleki+zmadu"))  # 12.11, `selgekmau` holds itself unchanged
    check not folded("se+se+ciska+vreji+gunka").isHoldingUnchanged(
        folded("se+se+ciska+vreji"))  # 12.11, outer `se` here converts group up to `gunka`
    check folded("se+se+ciska+vreji").isHoldingUnchanged(
        folded("se+se+ciska+vreji"))  # 12.11, same group, closed by end of both
    check folded("se+se+ke+ciska+vreji") ==
        folded("ciska+vreji")  # 12.11, two `se` cancel, so group they bind binds nothing
    check "selselkemci'avei".readTag.tag.tanruUnits == folded("ciska+vreji")  # 12.11, as above


  test "Section 12.12":
    check "nunkla".readTag.tag.tanruUnits ==
        @[tanruUnit("klama", @[operator("nu")])]  # 12.12, NU rafsi modifies next tanru unit alone
    for text in ABSTRACTORS:
      check folded(text & "+klama") == @[tanruUnit("klama", @[operator(text)])]  # 12.12, each NU
    check not "nunkemveiselci'a".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 12.12, x1 of abstraction is event, so head of group changes


  test "Section 12.13":
    check "nunctikezgau".readTag.tag.tanruUnits == @[
      tanruUnit("citka", @[operator("nu")]), tanruUnit("gasnu"),
    ]  # 12.13, `nun` and `kez` tell only what we would already have guessed
    check "nunctigaukezykla".readTag.tag.tanruUnits == @[
      tanruUnit("ke", @[operator("nu")]), tanruUnit("citka"), tanruUnit("gasnu"),
      tanruUnit("ke'e"), tanruUnit("klama"),
    ]  # 21.2, rule 152: `kei` closes abstraction, here of two tanru units



suite "Chapter 15":
  test "Section 15.2":
    check "narselci'a".readTag.tag.tanruUnits == @[
      tanruUnit("ciska", @[operator("na"), LINK_SE]),
    ]  # 15.2, `na` applies to entire bridi, here of one tanru unit
    check "narselci'avei".readTag.tag.tanruUnits == @[
      tanruUnit("ke", @[operator("na")]), tanruUnit("ciska", @[LINK_SE]), tanruUnit("vreji"),
    ]  # 15.2, `na` applies to entire bridi, and not to just part of selbri
    check folded("vreji+na+se+ciska") ==
        folded("na+vreji+se+ciska")  # 15.2, entire bridi, wherever `na` stands in tag
    check folded("na+na+se+ciska") == folded("se+ciska")  # 15.2, adjacent `na` cancel out
    check "narnarselci'a".readTag.tag.tanruUnits == folded("se+ciska")  # 15.2, as above


  test "Section 15.4":
    check "nalsu'adzuke'ekla".readTag.tag.tanruUnits == @[
      tanruUnit("ke", @[operator("na'e")]), tanruUnit("stura"), tanruUnit("cadzu"),
      tanruUnit("ke'e"), tanruUnit("klama"),
    ]  # 15.4, `ke'e` implies `ke` after `-nal-`; list gives `su'a` to `stura`, not `sutra`
    check folded("na'e+se+ciska") ==
        @[tanruUnit("ciska", @[operator("na'e"), LINK_SE])]  # 15.4, close-binding
    check not "nalkemselci'avei".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 15.4, `na'e ke` denies whole group, so no part holds as it is
    check folded("se+ciska+vreji+ke'e+gunka") ==
        folded("se+ke+ciska+vreji+ke'e+gunka")  # 15.4, `ke` implied after opening cmavo
    check folded("vreji+na'e+ciska+gunka+ke'e+klama") == @[
      tanruUnit("vreji"), tanruUnit("ke", @[operator("na'e")]), tanruUnit("ciska"),
      tanruUnit("gunka"), tanruUnit("ke'e"), tanruUnit("klama"),
    ]  # 15.4, `ke'e` implies `ke` after negation, wherever negation stands
    check folded("vreji+ciska+ke'e+gunka") ==
        folded("vreji+ciska+gunka")  # 15.4 implies `ke` after binding cmavo; none here, so drops


  test "Section 15.5":
    check "tolselci'a".readTag.tag.tanruUnits ==
        @[tanruUnit("ciska", @[operator("to'e"), LINK_SE])]  # 15.5, as `na'e`
    check folded("no'e+se+ciska") ==
        @[tanruUnit("ciska", @[operator("no'e"), LINK_SE])]  # 15.5, as `na'e`



suite "Internal: Convention":
  test "`co` stays as written, though it inverts order (5.8)":
    check folded("se+ciska+co+vreji") == @[
      tanruUnit("ciska", @[LINK_SE]), tanruUnit("co"), tanruUnit("vreji"),
    ]  # 5.8 reads `A co B` as `ke B ke'e A`; fold keeps written order, at cost


  test "`pe'a` and tense cmavo bind nothing, though CLL gives them whole lujvo or bridi":
    check "pevyselci'a".readTag.tag.tanruUnits ==
        @[tanruUnit("pe'a"), tanruUnit("ciska", @[LINK_SE])]  # 13.13, figurative lujvo
    check folded("co'a+se+ciska") ==
        @[tanruUnit("co'a"), tanruUnit("ciska", @[LINK_SE])]  # 5.13, tense of bridi


  test "group no cmavo binds drops, though 5.5 makes it one component":
    check folded("ke+se+ciska+vreji") == folded("se+ciska+vreji")  # rank reads no such group
    check "kemdatnyvei".readTag.tag.tanruUnits == folded("datni+vreji")  # as group above
    check folded("vreji+ke+se+ciska+vreji+ke'e+gunka") ==
        folded("vreji+se+ciska+vreji+gunka")  # `ke'e` of dropped group drops with it



suite "Internal: Laws":
  test "chain of SE folds to one conversion, or to none where it composes to no change":
    var count = 0
    for chain in chains(CONVERSIONS, LENGTH_CHAIN):
      inc count
      let places = placesOracle(chain)
      check folded((chain & "klama").join("+")) == @[tanruUnit("klama",
        if places == PLACES_SAME: @[] else: @[conversion(places)])]  # 9.4, inner first; 12.11
    check count == COUNT_CHAINS  # every chain of SE checked


  test "group of one unit folds as that unit, whatever binds it":
    var count = 0
    for chain in chains(BINDING, LENGTH_GROUPED):
      inc count
      check folded((chain & @["ke", "ciska"]).join("+")) ==
          folded((chain & "ciska").join("+"))  # 5.5, group of one is that tanru unit
    check count == COUNT_GROUPED  # every chain of binding cmavo checked


  test "fold keeps every gismu, in order, and only cmavo bind":
    var count = 0
    for prefix in chains(ALPHABET, LENGTH_TANRU - 1):
      for head in ["ciska", "vreji"]:
        inc count
        let
          words = readTanru((prefix & head).join("+")).get.words
          folding = words.tanruUnits
        check folding.filterIt(it.word.kind == Kind.Gismu).mapIt(it.word) ==
            words.filterIt(it.kind == Kind.Gismu)  # fold drops and moves no gismu
        check folding.allIt(it.links.allIt(it.operator.isNone or
            it.operator.get.kind == Kind.Cmavo))  # only cmavo bind
        check folding[^1].word == head.word.get  # tanru ends in its head (4.11 step 2)
    check count == COUNT_TANRU  # every tanru over alphabet checked
