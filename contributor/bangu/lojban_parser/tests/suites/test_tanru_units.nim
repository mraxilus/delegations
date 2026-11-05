## Replicate what cmavo bind in CLL chapters 5, 7, 9, 12 and 15 against `tanru_units.nim`: which
##   word each cmavo binds, how conversions compose, and where lujvo leaves `ke` out.
##   Sibling: part of `lojban_tagger/tests/suites/test_tanru_units.nim` holds earlier copy, over
##     listed words alone, until #809 drops it (II.9).
##   Each assertion folds example CLL gives, or tanru of `ciska`, `vreji` and `gunka` where
##     section gives none holding SE. Tanru is built from listed words joined by `+`, as suite
##     writes it, so no rafsi choice enters; where CLL gives lujvo, its words are those reader
##     gives it.
##   Laws enumerate small domains whole: every chain of SE up to `LENGTH_CHAIN`, every chain of
##     binding cmavo up to `LENGTH_GROUPED` before group of one, every tanru over `ALPHABET` up
##     to `LENGTH_TANRU` words; counts are named beside each claim.
##   Places of conversion are checked against oracle swapping names of places as text, so it
##     shares no code with `toLinks`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, strutils, unittest]

import ../../src/lojban_parser/[dictionary, forms, tanru, tanru_units]


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


func toTanru(text: string): Tanru =
  ## Build tanru of listed words joined by `+`, as suite writes tanru.
  Tanru(parts: text.split('+').mapIt(it.word.get.toPart))


func folded(text: string): seq[TanruUnit] =
  ## Fold tanru text, words joined by `+`, into tanru units.
  text.toTanru.tanruUnits


func tanruUnit(text: string, links: seq[Link] = @[]): TanruUnit =
  ## Build tanru unit of word `text` bound by `links`, outer first.
  TanruUnit(part: text.word.get.toPart, links: links)


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
    check "veirborselci'a".readWord.tanru.tanruUnits == folded("vreji+se+ciska")  # 5.3, as `bo`


  test "Section 5.5":
    check folded("se+ke+ciska") == folded("se+ciska")  # 5.5, group is single component
    check folded("se+ke+ciska+vreji") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("ciska"), tanruUnit("vreji")]  # 5.5
    check folded("se+ke+ciska+vreji+ke'e+gunka") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("ciska"), tanruUnit("vreji"), tanruUnit("ke'e"),
      tanruUnit("gunka"),
    ]  # 5.5, `ke'e` closes group, so `gunka` stands outside it
    check folded("se+ke+te+ke+ciska+vreji+ke'e+gunka") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("ke", @[conversion([3, 2, 1, 4, 5])]),
      tanruUnit("ciska"), tanruUnit("vreji"), tanruUnit("ke'e"), tanruUnit("gunka"),
    ]  # 5.5, group inside group: `ke'e` closes inner one, and end of tanru outer one


  test "Section 5.8":
    check folded("se+ke+ciska+co+gunka") ==
        folded("se+ciska+co+gunka")  # 5.8, `ke'e` implied before `co`: group holds one tanru unit


  test "Section 5.11":
    check folded("se+cadzu+klama") ==
        @[tanruUnit("cadzu", @[LINK_SE]), tanruUnit("klama")]  # 5.11, Example 5.113
    check folded("cadzu+se+klama") ==
        @[tanruUnit("cadzu"), tanruUnit("klama", @[LINK_SE])]  # 5.11, Example 5.114
    check folded("se+ke+cadzu+klama") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("cadzu"), tanruUnit("klama")]  # 5.11, 11.4



suite "Chapter 7":
  test "Section 7.15":
    check "fo'arselsanga".readWord.tanru.tanruUnits ==
        @[tanruUnit("fo'a"), tanruUnit("sanga", @[LINK_SE])]  # 7.15, Example 7.78



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
    ]  # 9.4, SE converts following tanru unit, here `na'e se ciska` (21.1, rule 152)



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
    check "seldzukla".readWord.tanru.tanruUnits ==
        @[tanruUnit("cadzu", @[LINK_SE]), tanruUnit("klama")]  # 12.11, "selcadzu klama"
    check "selkemdzukla".readWord.tanru.tanruUnits ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("cadzu"), tanruUnit("klama")]  # 12.11
    check "nalbrablo".readWord.tanru.tanruUnits ==
        @[tanruUnit("barda", @[operator("na'e")]), tanruUnit("bloti")]  # 12.11, "non-big boat"
    check folded("se+se+ke+ciska+vreji") ==
        folded("ciska+vreji")  # 12.11, two `se` cancel, so group they bind binds nothing
    check "selselkemci'avei".readWord.tanru.tanruUnits ==
        folded("ciska+vreji")  # 12.11, as above


  test "Section 12.12":
    check "nunkla".readWord.tanru.tanruUnits ==
        @[tanruUnit("klama", @[operator("nu")])]  # 12.12, NU rafsi modifies next tanru unit alone
    for text in ABSTRACTORS:
      check folded(text & "+klama") == @[tanruUnit("klama", @[operator(text)])]  # 12.12, each NU


  test "Section 12.13":
    check "nunctikezgau".readWord.tanru.tanruUnits == @[
      tanruUnit("citka", @[operator("nu")]), tanruUnit("gasnu"),
    ]  # 12.13, `nun` and `kez` tell only what we would already have guessed
    check "nunctigaukezykla".readWord.tanru.tanruUnits == @[
      tanruUnit("ke", @[operator("nu")]), tanruUnit("citka"), tanruUnit("gasnu"),
      tanruUnit("ke'e"), tanruUnit("klama"),
    ]  # 21.1, rule 152: `kei` closes abstraction, here of two tanru units



suite "Chapter 15":
  test "Section 15.2":
    check "narselci'a".readWord.tanru.tanruUnits == @[
      tanruUnit("ciska", @[operator("na"), LINK_SE]),
    ]  # 15.2, `na` applies to entire bridi, here of one tanru unit
    check "narselci'avei".readWord.tanru.tanruUnits == @[
      tanruUnit("ke", @[operator("na")]), tanruUnit("ciska", @[LINK_SE]), tanruUnit("vreji"),
    ]  # 15.2, `na` applies to entire bridi, and not to just part of selbri
    check folded("vreji+na+se+ciska") ==
        folded("na+vreji+se+ciska")  # 15.2, entire bridi, wherever `na` stands in tanru
    check folded("na+na+se+ciska") == folded("se+ciska")  # 15.2, adjacent `na` cancel out
    check "narnarselci'a".readWord.tanru.tanruUnits == folded("se+ciska")  # 15.2, as above


  test "Section 15.4":
    check "nalsu'adzuke'ekla".readWord.tanru.tanruUnits == @[
      tanruUnit("ke", @[operator("na'e")]), tanruUnit("stura"), tanruUnit("cadzu"),
      tanruUnit("ke'e"), tanruUnit("klama"),
    ]  # 15.4, `ke'e` implies `ke` after `-nal-`; list gives `su'a` to `stura`, not `sutra`
    check folded("na'e+se+ciska") ==
        @[tanruUnit("ciska", @[operator("na'e"), LINK_SE])]  # 15.4, close-binding
    check folded("se+ciska+vreji+ke'e+gunka") ==
        folded("se+ke+ciska+vreji+ke'e+gunka")  # 15.4, `ke` implied after opening cmavo
    check folded("vreji+na'e+ciska+gunka+ke'e+klama") == @[
      tanruUnit("vreji"), tanruUnit("ke", @[operator("na'e")]), tanruUnit("ciska"),
      tanruUnit("gunka"), tanruUnit("ke'e"), tanruUnit("klama"),
    ]  # 15.4, `ke'e` implies `ke` after negation, wherever negation stands
    check folded("vreji+ciska+ke'e+gunka") ==
        folded("vreji+ciska+gunka")  # 15.4 implies `ke` after binding cmavo; none here, so drops


  test "Section 15.5":
    check "tolselci'a".readWord.tanru.tanruUnits ==
        @[tanruUnit("ciska", @[operator("to'e"), LINK_SE])]  # 15.5, as `na'e`
    check folded("no'e+se+ciska") ==
        @[tanruUnit("ciska", @[operator("no'e"), LINK_SE])]  # 15.5, as `na'e`



suite "Internal: Convention":
  test "`co` stays as written, though it inverts order (5.8)":
    check folded("se+ciska+co+vreji") == @[
      tanruUnit("ciska", @[LINK_SE]), tanruUnit("co"), tanruUnit("vreji"),
    ]  # 5.8 reads `A co B` as `ke B ke'e A`; fold keeps written order, at cost


  test "`pe'a` and tense cmavo bind nothing, though CLL gives them whole lujvo or bridi":
    check "pevyselci'a".readWord.tanru.tanruUnits ==
        @[tanruUnit("pe'a"), tanruUnit("ciska", @[LINK_SE])]  # 13.13, figurative lujvo
    check folded("co'a+se+ciska") ==
        @[tanruUnit("co'a"), tanruUnit("ciska", @[LINK_SE])]  # 5.13, tense of bridi


  test "`kei` with no NU before it drops, though 21.1 has it close abstraction alone":
    check folded("vreji+kei+ciska") ==
        folded("vreji+ciska")  # 21.1, rule 152 ends NU with `kei`; none here, so `kei` drops


  test "number and MOI fold apart, though 21.1 makes them one tanru unit":
    check "relpavmomci'a".readWord.tanru.tanruUnits == @[
      tanruUnit("re"), tanruUnit("pa"), tanruUnit("moi"), tanruUnit("ciska"),
    ]  # 21.1, rule 152 joins `re pa moi`; fold keeps each digit apart, at cost


  test "group no cmavo binds drops, though 5.5 makes it one component":
    check folded("ke+se+ciska+vreji") ==
        folded("se+ciska+vreji")  # fold tells what cmavo bind, and no cmavo binds this group
    check "kemdatnyvei".readWord.tanru.tanruUnits == folded("datni+vreji")  # as group above
    check folded("vreji+ke+se+ciska+vreji+ke'e+gunka") ==
        folded("vreji+se+ciska+vreji+gunka")  # `ke'e` of dropped group drops with it
    check folded("datni+ke+vreji+liste") ==
        folded("datni+vreji+liste")  # 5.3 groups these two apart; fold keeps neither, at cost



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
          parts = toTanru((prefix & head).join("+")).parts
          folding = parts.tanruUnits
        check folding.filterIt(it.part.word.kind == Kind.Gismu).mapIt(it.part) ==
            parts.filterIt(it.word.kind == Kind.Gismu)  # fold drops and moves no gismu
        check folding.allIt(it.links.allIt(it.operator.isNone or
            it.operator.get.kind == Kind.Cmavo))  # only cmavo bind
        check folding[^1].part == head.word.get.toPart  # tanru ends in its head (4.11 step 2)
    check count == COUNT_TANRU  # every tanru over alphabet checked


  test "part no list names binds nothing, and stands as tanru unit of its own":
    let
      se = "se".word.get.toPart
      clo = Part(is_listed: false, letters: "clo")  # rafsi no list assigns; constructed
      zbasu = "zbasu".word.get.toPart
    check not clo.isBinding  # binding cmavo are words of list
    check @[se, clo, zbasu].tanruUnits == @[
      TanruUnit(part: clo, links: @[LINK_SE]),
      TanruUnit(part: zbasu),
    ]  # 9.4, `se` binds next tanru unit, whatever names it
    check @[clo, se, zbasu].tanruUnits == @[
      TanruUnit(part: clo),
      TanruUnit(part: zbasu, links: @[LINK_SE]),
    ]  # part no list names binds nothing
