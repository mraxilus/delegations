## rapyzba lo nu lo cmavo cu jorne kei pe `CLL 5` .e `CLL 7` .e `CLL 9` .e `CLL 12` .e `CLL 15`
##     sepi'o `tanru_units.nim`
##   .i le cipra cu cipra lo du'u ro cmavo cu jorne ma kau poi valsi kei .e lo du'u lo nu galfi lo
##       porsi be lo sumti cu se jmina ta'i ma kau kei .e lo du'u lo lujvo cu claxu zo ke bu'u ma
##       kau
##   .i ro xusra cu fendi lo mupli poi `CLL` dunda ke'a
##   .i va'o lo nu le ckupau cu dunda no mupli poi vasru lo cmavo be `SE` kei le xusra cu fendi lo
##       tanru pe zo ciska .e zo vreji .e zo gunka
##   .i lo tanru cu selzba fi lo stevla poi seljo'e sepi'o `+`
##   .i le cipra cu ciska lo tanru ta'i la'e di'u
##   .i se ki'u bo no nu cuxna lo rafsi cu selpli
##   .i va'o lo nu `CLL` dunda lo lujvo kei lo valsi pe le lujvo cu du lo valsi poi le tcidu cu
##       dunda ke'a le lujvo
##   .i lo jvacipra cu cipra fi ro cmima be lo cmagri
##   .i pa girzu cu du ro porsi be `SE` be'o poi lo nilclani be ke'a na zmadu `LENGTH_CHAIN`
##   .i pa girzu cu du ro porsi be lo cmavo poi jorne be'o poi lo nilclani be ke'a na zmadu
##       `LENGTH_GROUPED` zi'e poi lidne lo girzu poi vasru pa tanru pagbu po'o
##   .i pa girzu cu du ro tanru poi selzba fi `ALPHABET` zi'e poi lo te kancu be lo valsi pe ke'a na
##       zmadu `LENGTH_TANRU`
##   .i lo te kancu cu selsku bu'u lo stuzi poi jibni ro xusra
##   .i lo stuzi poi lo nu galfi cu dunda ke'a se karbi lo jalge be `placesOracle` noi galfi lo
##       porsi be lo cmene be lo sumti noi lerpoi
##   .i se ki'u bo `placesOracle` pilno no pagbu be `toLinks`

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, strutils, unittest]

import ../../src/lojban_parser/[dictionary, forms, tanru, tanru_units]


const
  LENGTH_CHAIN = 4
    ## lo zmaraiterkancu be lo cmavo be `SE` be'o pe pa porsi poi lo javni cipra pe lo nu jmina cu
    ##     fendi ke'a
  COUNT_CHAINS = 1 + 4 + 16 + 64 + 256
    ## lo te kancu be lo porsi be `SE` be'o poi lo nilclani be ke'a cu du li no bi'o `LENGTH_CHAIN`
  LENGTH_GROUPED = 2
    ## lo zmadu traji nilclani be lo porsi be lo cmavo poi jorne be'o be'o poi lo jvacipra cu punji
    ##     ke'a lo stuzi poi lidne lo girzu poi vasru pa tanru pagbu po'o
  COUNT_GROUPED = 1 + 4 + 16
    ## lo te kancu be lo porsi be `BINDING` be'o poi lo nilclani be ke'a cu du li no bi'o
    ##     `LENGTH_GROUPED`
  BINDING = ["se", "te", "na'e", "nu"]
    ## lo cmavo poi jorne zi'e poi lo jvacipra cu cuxna ke'a
    ##   .i le cmavo cu du re cmavo be `SE` be'o .e pa cmavo be `NAhE` be'o .e pa cmavo be `NU`
  ALPHABET = ["se", "te", "ke", "ke'e", "na'e", "ciska", "vreji"]
    ## lo valsi poi lo jvacipra pe lo tanru pe lo gismu cu cuxna ke'a
    ##   .i le valsi cu du lo cmavo poi jorne ku'o .e lo cmavo poi zbasu lo girzu ku'o .e re gismu
  LENGTH_TANRU = 4
    ## lo zmadu traji nilclani be lo tanru poi le jvacipra pe lo gismu cu fendi ke'a
    ##   .i lo romoi valsi cu gismu
  COUNT_TANRU = (1 + 7 + 49 + 343) * 2
    ## lo te kancu be lo tanru pe le javni cipra
    ##   .i ro tanru cu selkra lo porsi be su'e ci valsi
    ##   .i lo gismu cu se lidne le porsi
  CONVERSIONS = ["se", "te", "ve", "xe"]
    ## lo cmavo be `SE` ta'i lo porsi poi `CLL 9.4` dunda ke'a
  LINK_SE = Link(places: [2, 1, 3, 4, 5])
    ## lo me `Link` pe zo se
    ##   .i lo pamoi sumti .e lo remoi sumti cu simxu lo ka basti to `CLL 9.4` toi
  ABSTRACTORS = [
    "du'u", "jei", "ka", "li'i", "mu'e", "ni", "nu", "pu'u", "si'o", "su'u", "za'i", "zu'o",
  ]
    ## lo cmavo be `NU` poi le liste cu dunda lo rafsi ke'a to `CLL 11.13` toi


func toTanru(text: string): Tanru =
  ## zbasu lo tanru fi lo stevla poi seljo'e sepi'o `+`
  ##   .i le cipra cu ciska lo tanru ta'i la'e di'u
  Tanru(parts: text.split('+').mapIt(it.word.get.toPart))


func folded(text: string): seq[TanruUnit] =
  ## fendi lo selci'a be lo tanru fi lo taurpau
  ##   .i lo valsi pe le selci'a cu seljo'e sepi'o `+`
  text.toTanru.tanruUnits


func tanruUnit(text: string, links: seq[Link] = @[]): TanruUnit =
  ## zbasu lo taurpau pe lo valsi po'u `text` zi'e noi `links` jorne ke'a
  ##   .i lo bartu cu pamoi
  TanruUnit(part: text.word.get.toPart, links: links)


func conversion(places: Places): Link =
  ## zbasu lo me `Link` pe lo nu galfi poi punji lo sumti ta'i le porsi po'u `places`
  Link(places: places)


func operator(text: string): Link =
  ## zbasu lo me `Link` pe lo cmavo po'u `text` zi'e noi jorne gi'e na cmavo be `SE`
  Link(places: PLACES_SAME, operator: some(text.word.get))


func placesOracle(chain: openArray[string]): Places =
  ## jmina lo nu galfi pe `chain` ta'i lo nu galfi lo porsi be lo cmene be lo sumti noi lerpoi
  ##   .i lo nenri cu pamoi to `CLL 9.4` toi
  var names = @["x1", "x2", "x3", "x4", "x5"]
  for i in countdown(chain.high, 0):
    let swapped = CONVERSIONS.find(chain[i]) + 1
    swap(names[0], names[swapped])
  for i, name in names: result[i + 1] = int(name[1]) - int('0')


func chains(alphabet: openArray[string], length: int): seq[seq[string]] =
  ## liste ro porsi be lo valsi pe `alphabet` be'o poi lo nilclani be ke'a cu du li no bi'o `length`
  ##   .i lo tordu cu pamoi
  result = @[newSeq[string]()]
  for size in 1 .. length:
    for prefix in result.filterIt(it.len == size - 1):
      for word in alphabet: result.add prefix & word



suite "Chapter 5":
  test "Section 5.3":
    # `CLL 5.3`
    #   .i zo bo zbasu lo girzu po'o
    check folded("vreji+bo+se+ciska") == folded("vreji+se+ciska")  # `CLL 5.3`
    # `CLL 5.3`
    #   .i simsa zo bo
    check "veirborselci'a".readWord.tanru.tanruUnits == folded("vreji+se+ciska")  # `CLL 5.3`


  test "Section 5.5":
    check folded("se+ke+ciska") == folded("se+ciska")  # `CLL 5.5` to le girzu cu du pa pagbu toi
    check folded("se+ke+ciska+vreji") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("ciska"), tanruUnit("vreji")]  # `CLL 5.5`
    check folded("se+ke+ciska+vreji+ke'e+gunka") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("ciska"), tanruUnit("vreji"), tanruUnit("ke'e"),
      tanruUnit("gunka"),
    # zo ke'e fanmo le girzu
    #   .i se ki'u bo zo gunka zvati lo bartu be le girzu
    ]  # `CLL 5.5`
    check folded("se+ke+te+ke+ciska+vreji+ke'e+gunka") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("ke", @[conversion([3, 2, 1, 4, 5])]),
      tanruUnit("ciska"), tanruUnit("vreji"), tanruUnit("ke'e"), tanruUnit("gunka"),
    # zo ke'e fanmo le nergri
    #   .i lo fanmo be le tanru cu fanmo le bartu
    ]  # `CLL 5.5`


  test "Section 5.8":
    # `CLL 5.8`
    #   .i zo ke'e selsni ca lo nu lidne zo co
    #   .i le girzu cu vasru pa taurpau
    check folded("se+ke+ciska+co+gunka") ==
        folded("se+ciska+co+gunka")  # `CLL 5.8`


  test "Section 5.11":
    check folded("se+cadzu+klama") ==
        @[tanruUnit("cadzu", @[LINK_SE]), tanruUnit("klama")]  # `CLL 5.11, Example 5.113`
    check folded("cadzu+se+klama") ==
        @[tanruUnit("cadzu"), tanruUnit("klama", @[LINK_SE])]  # `CLL 5.11, Example 5.114`
    check folded("se+ke+cadzu+klama") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("cadzu"), tanruUnit("klama")]  # `Example 5.112`



suite "Chapter 7":
  test "Section 7.15":
    check "fo'arselsanga".readWord.tanru.tanruUnits ==
        @[tanruUnit("fo'a"), tanruUnit("sanga", @[LINK_SE])]  # `CLL 7.15, Example 7.78`



suite "Chapter 9":
  test "Section 9.4":
    for i, text in CONVERSIONS:
      var places = PLACES_SAME
      swap(places[1], places[i + 2])
      # `CLL 9.4`
      #   .i lo pamoi sumti cu cenba lo stuzi
      check folded(text & "+klama") == @[tanruUnit("klama", @[conversion(places)])]  # `CLL 9.4`
    check folded("te+se+klama") == @[
      tanruUnit("klama", @[conversion([3, 1, 2, 4, 5])]),
    ]  # `CLL 9.4` to lo pamoi sumti cu krasi lo nu lo remoi sumti cu klama lo cimoi sumti toi
    # `CLL 9.4` zoi gy. setese .gy.
    #   .i lo remoi sumti .e lo cimoi sumti cu simxu lo ka basti
    check folded("se+te+se+klama") ==
        @[tanruUnit("klama", @[conversion([1, 3, 2, 4, 5])])]  # `CLL 9.4`
    check folded("se+ke+blanu+zdani") ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("blanu"), tanruUnit("zdani")]  # `Example 9.25`
    # `CLL 9.4`
    #   .i `SE` galfi lo bavla'i tanru pagbu po'u lo'u na'e se ciska le'u to `CLL 21.1 rule 152` toi
    check folded("se+na'e+se+ciska") == @[
      tanruUnit("ciska", @[LINK_SE, operator("na'e"), LINK_SE]),
    ]



suite "Chapter 12":
  test "Section 12.11":
    check folded("se+se+gleki") == folded("gleki")  # `CLL 12.11` to re zo se galfi no da toi
    check folded("se+se+gleki+zmadu") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("gleki", @[LINK_SE]), tanruUnit("zmadu"),
    ]  # `CLL 12.11` to `selsel-` se tcidu ta'i `selkemsel-` toi
    check folded("se+te+gleki+zmadu") == @[
      tanruUnit("ke", @[LINK_SE]), tanruUnit("gleki", @[conversion([3, 2, 1, 4, 5])]),
      tanruUnit("zmadu"),
    ]  # `CLL 12.11` to `selter-` se tcidu ta'i zoi gy. se ke te .gy. toi
    # `CLL 12.11` zoi gy. selcadzu klama .gy.
    check "seldzukla".readWord.tanru.tanruUnits ==
        @[tanruUnit("cadzu", @[LINK_SE]), tanruUnit("klama")]  # `CLL 12.11`
    check "selkemdzukla".readWord.tanru.tanruUnits ==
        @[tanruUnit("ke", @[LINK_SE]), tanruUnit("cadzu"), tanruUnit("klama")]  # `CLL 12.11`
    # `CLL 12.11` zoi gy. non-big boat .gy.
    check "nalbrablo".readWord.tanru.tanruUnits ==
        @[tanruUnit("barda", @[operator("na'e")]), tanruUnit("bloti")]  # `CLL 12.11`
    # `CLL 12.11`
    #   .i re zo se galfi no da
    #   .i se ki'u bo lo girzu poi le re cmavo cu jorne ke'a jorne no da
    check folded("se+se+ke+ciska+vreji") ==
        folded("ciska+vreji")  # `CLL 12.11`
    check "selselkemci'avei".readWord.tanru.tanruUnits ==
        folded("ciska+vreji")  # `CLL 12.11` to simsa di'u toi


  test "Section 12.12":
    # `CLL 12.12`
    #   .i lo rafsi be lo cmavo be `NU` cu galfi lo bavla'i tanru pagbu po'o
    check "nunkla".readWord.tanru.tanruUnits ==
        @[tanruUnit("klama", @[operator("nu")])]  # `CLL 12.12`
    for text in ABSTRACTORS:
      # `CLL 12.12`
      #   .i ro cmavo be `NU`
      check folded(text & "+klama") == @[tanruUnit("klama", @[operator(text)])]  # `CLL 12.12`


  test "Section 12.13":
    check "nunctikezgau".readWord.tanru.tanruUnits == @[
      tanruUnit("citka", @[operator("nu")]), tanruUnit("gasnu"),
    ]  # `CLL 12.13` to `nun` .e `kez` cusku po'o lo se smadi be mi'a toi
    check "nunctigaukezykla".readWord.tanru.tanruUnits == @[
      tanruUnit("ke", @[operator("nu")]), tanruUnit("citka"), tanruUnit("gasnu"),
      tanruUnit("ke'e"), tanruUnit("klama"),
    # zo kei fanmo lo sucta
    #   .i vi le sucta cu vasru re taurpau
    ]  # `CLL 21.1 rule 152`



suite "Chapter 15":
  test "Section 15.2":
    check "narselci'a".readWord.tanru.tanruUnits == @[
      tanruUnit("ciska", @[operator("na"), LINK_SE]),
    ]  # `CLL 15.2` to zo na natfe lo mulbri toi to vi le bridi cu vasru pa taurpau toi
    check "narselci'avei".readWord.tanru.tanruUnits == @[
      tanruUnit("ke", @[operator("na")]), tanruUnit("ciska", @[LINK_SE]), tanruUnit("vreji"),
    ]  # `CLL 15.2` to zo na natfe lo mulbri gi'e na natfe lo pagbu po'o be lo selbri toi
    check folded("vreji+na+se+ciska") ==
        # lo stuzi be zo na na vajni
        folded("na+vreji+se+ciska")  # `CLL 15.2` lo mulbri
    # `CLL 15.2`
    #   .i lo re zo na poi lamji cu galfi no da
    check folded("na+na+se+ciska") == folded("se+ciska")  # `CLL 15.2`
    # `CLL 15.2`
    #   .i simsa di'u
    check "narnarselci'a".readWord.tanru.tanruUnits == folded("se+ciska")  # `CLL 15.2`


  test "Section 15.4":
    # `CLL 15.4`
    #   .i zo ke'e sinxa zo ke noi se lidne `-nal-`
    #   .i le liste cu dunda `su'a` zo stura .enai zo sutra
    check "nalsu'adzuke'ekla".readWord.tanru.tanruUnits == @[
      tanruUnit("ke", @[operator("na'e")]), tanruUnit("stura"), tanruUnit("cadzu"),
      tanruUnit("ke'e"), tanruUnit("klama"),
    ]
    check folded("na'e+se+ciska") ==
        @[tanruUnit("ciska", @[operator("na'e"), LINK_SE])]  # `CLL 15.4` to jbijo'e toi
    # `CLL 15.4`
    #   .i zo ke poi selsni cu se lidne lo krama'o
    check folded("se+ciska+vreji+ke'e+gunka") ==
        folded("se+ke+ciska+vreji+ke'e+gunka")  # `CLL 15.4`
    # `CLL 15.4`
    #   .i zo ke'e sinxa zo ke noi se lidne lo nafma'o
    #   .i lo stuzi be le nafma'o cu na vajni
    check folded("vreji+na'e+ciska+gunka+ke'e+klama") == @[
      tanruUnit("vreji"), tanruUnit("ke", @[operator("na'e")]), tanruUnit("ciska"),
      tanruUnit("gunka"), tanruUnit("ke'e"), tanruUnit("klama"),
    ]
    # `CLL 15.4` sinxa zo ke noi se lidne lo cmavo poi jorne
    #   .i no da zvati
    #   .i se ki'u bo zo ke'e selvi'u
    check folded("vreji+ciska+ke'e+gunka") ==
        folded("vreji+ciska+gunka")  # `CLL 15.4`


  test "Section 15.5":
    check "tolselci'a".readWord.tanru.tanruUnits ==
        @[tanruUnit("ciska", @[operator("to'e"), LINK_SE])]  # `CLL 15.5` to simsa zo na'e toi
    check folded("no'e+se+ciska") ==
        @[tanruUnit("ciska", @[operator("no'e"), LINK_SE])]  # `CLL 15.5` to simsa zo na'e toi



suite "Internal: Convention":
  test "`co` stays as written, though it inverts order (5.8)":
    check folded("se+ciska+co+vreji") == @[
      tanruUnit("ciska", @[LINK_SE]), tanruUnit("co"), tanruUnit("vreji"),
    # jdima fa lo nu ralte lo selci'apoi
    ]  # `CLL 5.8` tcidu `A co B` ta'i `ke B ke'e A`


  test "`pe'a` and tense cmavo bind nothing, though CLL gives them whole lujvo or bridi":
    # `CLL 13.13`
    #   .i zo pe'a srana lo muljvo
    check "pevyselci'a".readWord.tanru.tanruUnits ==
        @[tanruUnit("pe'a"), tanruUnit("ciska", @[LINK_SE])]  # `CLL 13.13`
    check folded("co'a+se+ciska") ==
        # lo temci pe lo bridi
        @[tanruUnit("co'a"), tanruUnit("ciska", @[LINK_SE])]  # `CLL 5.13`


  test "`kei` with no NU before it drops, though 21.1 has it close abstraction alone":
    # `CLL 21.1 rule 152`
    #   .i zo kei fanmo lo cmavo be `NU`
    #   .i no `NU` zvati
    #   .i se ki'u bo zo kei selvi'u
    check folded("vreji+kei+ciska") ==
        folded("vreji+ciska")  # `CLL 21.1 rule 152`


  test "number and MOI fold apart, though 21.1 makes them one tanru unit":
    check "relpavmomci'a".readWord.tanru.tanruUnits == @[
      tanruUnit("re"), tanruUnit("pa"), tanruUnit("moi"), tanruUnit("ciska"),
    ]  # `CLL 21.1 rule 152` jmina lo'u re pa moi le'u to jdima fa lo nu ro `PA` sepli toi


  test "group no cmavo binds drops, though 5.5 makes it one component":
    # le nu fendi cu jarco lo du'u ma kau poi cmavo cu jorne
    #   .i no cmavo cu jorne le girzu
    check folded("ke+se+ciska+vreji") ==
        folded("se+ciska+vreji")  # le nu fendi cu jarco lo du'u ma kau poi cmavo cu jorne
    check "kemdatnyvei".readWord.tanru.tanruUnits == folded("datni+vreji")  # simsa di'u
    check folded("vreji+ke+se+ciska+vreji+ke'e+gunka") ==
        folded("vreji+se+ciska+vreji+gunka")  # zo ke'e pe le girzu poi selvi'u cu se vimcu ji'a
    # `CLL 5.3` dunda lo ficygri le re tanru
    #   .i jdima fa lo nu le nu fendi cu ralte no le girzu
    check folded("datni+ke+vreji+liste") ==
        folded("datni+vreji+liste")  # `CLL 5.3`



suite "Internal: Laws":
  test "chain of SE folds to one conversion, or to none where it composes to no change":
    var count = 0
    for chain in chains(CONVERSIONS, LENGTH_CHAIN):
      inc count
      let places = placesOracle(chain)
      # `CLL 9.4`
      #   .i lo nenri cu pamoi
      #   .i `CLL 12.11`
      check folded((chain & "klama").join("+")) == @[tanruUnit("klama",
        if places == PLACES_SAME: @[] else: @[conversion(places)])]  # `CLL 9.4`
    check count == COUNT_CHAINS  # ro porsi be `SE` cu se cipra


  test "group of one unit folds as that unit, whatever binds it":
    var count = 0
    for chain in chains(BINDING, LENGTH_GROUPED):
      inc count
      # `CLL 5.5`
      #   .i lo girzu poi vasru pa tanru pagbu po'o cu du le taurpau
      check folded((chain & @["ke", "ciska"]).join("+")) ==
          folded((chain & "ciska").join("+"))  # `CLL 5.5`
    check count == COUNT_GROUPED  # ro porsi be lo cmavo poi jorne cu se cipra


  test "fold keeps every gismu, in order, and only cmavo bind":
    var count = 0
    for prefix in chains(ALPHABET, LENGTH_TANRU - 1):
      for head in ["ciska", "vreji"]:
        inc count
        let
          parts = toTanru((prefix & head).join("+")).parts
          folding = parts.tanruUnits
        check folding.filterIt(it.part.word.kind == Kind.Gismu).mapIt(it.part) ==
            parts.filterIt(it.word.kind == Kind.Gismu)  # no gismu cu se vimcu ja muvdu
        check folding.allIt(it.links.allIt(it.operator.isNone or
            it.operator.get.kind == Kind.Cmavo))  # lo cmavo po'o cu jorne
        # le stedu cu fanmo le tanru to `CLL 4.11 step 2` toi
        check folding[^1].part == head.word.get.toPart  # `CLL 4.11 step 2`
    check count == COUNT_TANRU  # ro tanru poi selzba fi `ALPHABET` se cipra


  test "part no list names binds nothing, and stands as tanru unit of its own":
    let
      se = "se".word.get.toPart
      # lo rafsi poi no liste cu dunda ke'a
      #   .i zbasu le valsi
      clo = Part(is_listed: false, letters: "clo")
      zbasu = "zbasu".word.get.toPart
    check not clo.isBinding  # ro cmavo poi jorne cu selvau lo liste
    check @[se, clo, zbasu].tanruUnits == @[
      TanruUnit(part: clo, links: @[LINK_SE]),
      TanruUnit(part: zbasu),
    # zo se jorne lo bavla'i tanru pagbu
    #   .i lo cmene be le pagbu cu na vajni
    ]  # `CLL 9.4`
    check @[clo, se, zbasu].tanruUnits == @[
      TanruUnit(part: clo),
      TanruUnit(part: zbasu, links: @[LINK_SE]),
    ]  # lo pagbu poi no liste cu vasru ke'a jorne no da
