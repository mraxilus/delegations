## rapli zbasu le liste be lo selma'o pe `CLL 20` gi'e cipra lo du'u `selmaho.nim` .e le cmavo liste
##   cu mapti le se zbasu
##   .i lo cmene .e lo porsi be le cmene cu fukpi lo se ciska pe `CLL 20` gi'e no roi fukpi lo se
##     ciska be le samtci
##   .i se ki'u bo le cipra cu cipra le cmene gi'e na rapli ciska le cmene
##   .i `CLL 20` cu dunda lo cmene ro selma'o sepi'o pa cmavo poi sinxa le selma'o
##   .i se ki'u bo le cmavo poi se ciska ja'i le cmene cu cmima le selma'o ne'i le cmavo liste
##   .i le cipra cu cipra di'u fi ro cmene
##   .i lo cipra cu cipra lo du'u lo nu sisku cu mintu lo nu sisku fi ro cmima be `LIST_CMAVO` ta'i
##     lo porsi
##   .i le vi cipra cu ciska le nu sisku ta'i lo porsi gi'e na pilno lo nu sisku pe `dictionary.nim`
##     zi'e noi fendi lo liste fi re pagbu
##   .i le cipra cu tcidu ro cmima be le liste be'o .e lo cmavo poi se cuxna lo tsiju gi'e se galfi
##     pa lerfu to `Article IX.3` toi
##   .i lo flalu pe `cmavo.txt` cu tcidu `cmavo.txt` ta'i lo se ciska poi na pagbu le vi se gunka to
##     `texts_outside.nim` toi
##   .i le flalu cu na se cipra va'o lo nu `cmavo.txt` cu na zvati gi'a muvdu fo lo stuzi poi se
##     jgari to `Article IX.9` toi
##   .i lo linji poi vasru pa cmavo po'o cu se tcidu
##   .i le se tcidu cu vasru lo selma'o poi le linji cu dunda ke'a
##   .i lo cmavo gunma cu se fendi fi lo cmavo poi le liste cu vasru ke'a
##   .i le genturfa'i cu tcidu ro valsi pe lo jufra pagbu

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_parser/[dictionary, forms, selmaho, tanru]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ./texts_outside


const
  CATALOGUE = [
    "A", "BAI", "BAhE", "BE", "BEI", "BEhO", "BIhE", "BIhI", "BO", "BOI", "BU", "BY", "CAI",
    "CAhA", "CEI", "CEhE", "CO", "COI", "CU", "CUhE", "DAhO", "DOI", "DOhU", "FA", "FAhA",
    "FAhO", "FEhE", "FEhU", "FIhO", "FOI", "FUhA", "FUhE", "FUhO", "GA", "GAhO", "GEhU", "GI",
    "GIhA", "GOI", "GOhA", "GUhA", "I", "JA", "JAI", "JOI", "JOhI", "KE", "KEI", "KEhE", "KI",
    "KOhA", "KU", "KUhE", "KUhO", "LA", "LAU", "LAhE", "LE", "LEhU", "LI", "LIhU", "LOhO",
    "LOhU", "LU", "LUhU", "MAI", "MAhO", "ME", "MEhU", "MOI", "MOhE", "MOhI", "NA", "NAI",
    "NAhE", "NAhU", "NIhE", "NIhO", "NOI", "NU", "NUhA", "NUhI", "NUhU", "PA", "PEhE", "PEhO",
    "PU", "RAhO", "ROI", "SA", "SE", "SEI", "SEhU", "SI", "SOI", "SU", "TAhE", "TEI", "TEhU",
    "TO", "TOI", "TUhE", "TUhU", "UI", "VA", "VAU", "VEI", "VEhA", "VEhO", "VIhA", "VUhO",
    "VUhU", "XI", "Y", "ZAhO", "ZEI", "ZEhA", "ZI", "ZIhE", "ZO", "ZOI", "ZOhU",
  ]
    ## lo cmene be ro selma'o pe `CLL 20` ta'i le porsi .e le lerfu pe `CLL 20`
  LETTERS_MUTATION = "'abcdefgijklmnoprstuvxyz.ABh"
    ## lo lerfu poi lo galfi cu cuxna ke'a
    ##   .i le lerfu cu du lo lerfu pe `CLL 3.1` ge'u .e denpa bu .e lo barda lerfu .e `h`
    ##   .i no cmavo cu vasru lo barda lerfu .a `h`
  SAMPLES_MUTATION = 5000
    ## lo cmavo poi se cuxna fi le liste sepi'o lo tsiju gi'e se sisku ba lo nu pa lerfu pe ke'a cu
    ##   se galfi
  FLOOR_UNLISTED = 3000
    ## lo mleca traji klani be le galfi poi no liste cu vasru ke'a
    ##   .i le mleca traji cu ralte lo nu lo se cipra cu vasru lo valsi poi no liste cu vasru ke'a
    ##   .i ca lo nu lo tsiju cu du `0` kei cixavoso le galfi cu se kancu
  COUNT_COMPOUNDS = 472
    ## lo klani be lo linji poi ciska lo cmavo gunma ta'i pa valsi ne'i `cmavo.txt`
    ##   .i le cipra cu jdice lo du'u le klani cu stodi
  COUNT_PHRASES = 21
    ## lo klani be lo linji poi ciska lo jufra pagbu poi vasru su'o re valsi ku'o ne'i `cmavo.txt`
    ##   .i le cipra cu jdice lo du'u le klani cu stodi


func selmahoScanned(text: string): Option[Selmaho] =
  ## facki lo selma'o be lo cmavo po'u `text` sepi'o lo nu sisku fi ro cmima be le liste ta'i lo
  ##   porsi
  ##   .i le fancu cu sepli lo nu sisku pe `dictionary.nim`
  for entry in LIST_CMAVO:
    if entry.word == text: return some(entry.selmaho)
  none(Selmaho)


func nameColumn(column: string): string =
  ## lebna lo cmene be lo selma'o lo pagbu be lo linji pe `cmavo.txt`
  ##   .i le cmene cu lidne lo klesi pagbu .a lo sinxa
  ##   .i le fancu cu sepli le galfi samtci
  for letter in column:
    if letter in {'A' .. 'Z', 'h'}: result.add letter
    else: break


func toWord(name: string): string =
  ## ciska lo cmavo poi `CLL 20` cu pilno ke'a lo nu cmene lo selma'o
  ##   .i ro lerfu cu cmalu
  ##   .i `h` cu sinxa zoi gy. ' .gy.
  name.toLowerAscii.replace('h', '\'')


proc drawMutated(): seq[string] =
  ## cuxna lo cmavo pe le liste
  ##   .i le klani be le cmavo cu du `SAMPLES_MUTATION`
  ##   .i pa lerfu pe ro le cmavo cu se galfi
  ##   .i lo tsiju cu se cuxna pa roi
  randomize(0)
  result = newSeqOfCap[string](SAMPLES_MUTATION)
  for _ in 1 .. SAMPLES_MUTATION:
    var text = LIST_CMAVO[rand(LIST_CMAVO.high)].word
    text[rand(text.high)] = LETTERS_MUTATION.sample
    result.add text



suite "Chapter 20":
  test "Catalogue of selma'o":
    # `CLL 20`
    #   .i ro selma'o pe le liste cu se srana pa cmima
    check CATALOGUE.len == Selmaho.high.ord + 1  # `CLL 20`
    for i, name in CATALOGUE:
      check $Selmaho(i) == name  # `CLL 20` to lo lerfu .e lo porsi pe le liste toi
      check name.toSelmaho == some(Selmaho(i))  # `CLL 20` to le cmene cu rapli se tcidu toi
      # `CLL 20` cu cusku zoi gy. names of representative cmavo .gy.
      check name.toWord.selmaho == some(Selmaho(i))  # `CLL 20`
    # `BAhE` pe `CLL 20`
    #   .i mupli fa zoi gy. la ba'e .djordj. klama .gy.
    check "ba'e".selmaho == some(Selmaho.Bahe)  # `CLL 20`
    # `BAI` pe `CLL 20`
    #   .i mupli fa zoi gy. mi tavla bau la lojban. .gy.
    check "bau".selmaho == some(Selmaho.Bai)  # `CLL 20`
    # `BE` pe `CLL 20`
    #   .i mupli fa zoi gy. mi klama be ta troci .gy.
    check "be".selmaho == some(Selmaho.Be)  # `CLL 20`
    # `CLL 20`
    #   .i `h` cu cmalu
    #   .i lo drata lerfu cu barda
    check "BAHE".toSelmaho.isNone and "bahe".toSelmaho.isNone  # `CLL 20`



suite "Internal: Cmavo list":
  test "Each selma'o of catalogue holds cmavo of list":
    var found: set[Selmaho]
    for entry in LIST_CMAVO: found.incl entry.selmaho
    check found == {Selmaho.low .. Selmaho.high}  # ro cmima to no cmima cu na se pilno toi


  test "Lookup agrees with linear scan":
    for entry in LIST_CMAVO:  # ro cmima be le liste
      check entry.word.selmaho == some(entry.selmaho)  # lo nu sisku cu facki lo selma'o be ro cmavo
    for entry in LIST_GISMU:
      if entry.word.isGismu: check entry.word.selmaho.isNone  # lo gismu cu ponse no selma'o
      # lo cmavo poi ponse lo rafsi cu zvati le cmavo liste ji'a
      else: check entry.word.selmaho.isSome
    check "".selmaho.isNone and ".a".selmaho.isNone and "LO".selmaho.isNone  # lo nu sisku cu fliba
    var count_unlisted = 0
    # le lerpoi cu se cuxna lo tsiju
    #   .i le klani be le lerpoi cu du `SAMPLES_MUTATION`
    for text in drawMutated():
      # lo nu sisku sepi'o lo nu fendi lo liste fi re pagbu cu mintu lo nu sisku ta'i lo porsi
      check text.selmaho == text.selmahoScanned  # lo re nu sisku cu mintu
      if text.selmaho.isNone: inc count_unlisted
    # lo se cipra cu vasru lo valsi poi no liste cu vasru ke'a to `Article IX.3` toi
    check count_unlisted >= FLOOR_UNLISTED  # `Article IX.3`


  test "Each cmavo of list reads as cmavo with its selma'o":
    for entry in LIST_CMAVO:  # ro cmima be le liste
      let reading = entry.word.readWord
      check reading.is_word and reading.kind == Kind.Cmavo  # lo tarmi be lo cmavo pe `CLL 4.2`
      # `CLL 20`
      #   .i le liste cu dunda le selma'o
      if reading.is_word: check reading.selmaho == some(entry.selmaho)


  test "Each line of cmavo list reads, each cmavo with its selma'o":
    let lines = readLinesCmavo()
    # `cmavo.txt` na zvati gi'a muvdu fo lo stuzi poi se jgari to `texts_outside.nim` toi
    if lines.isNone: skip()
    else:
      var count_simple, count_compound, count_phrase = 0
      for line in lines.get:  # ro linji
        if not line.is_compound:
          inc count_simple
          let reading = line.word.replace(".", "").readWord
          # `CLL 20`
          #   .i le se tcidu be le cmavo cu vasru lo selma'o poi le linji cu dunda ke'a
          check reading.is_word and reading.selmaho.map(`$`) ==
              some(line.selmaho.nameColumn)  # `CLL 20`
        elif ' ' notin line.word:
          inc count_compound
          let pieces = line.word.splitCompound
          # `CLL 4.2`
          #   .i le cmavo liste cu vasru ro pagbu
          check pieces.len >= 2 and pieces.allIt(it.selmaho.isSome)  # `CLL 4.2`
        else:
          inc count_phrase
          # lo porsi be lo valsi noi le genturfa'i cu tcidu ke'a ja'i `#811`
          for word in line.word.splitWhitespace:
            let pieces = word.splitCompound
            # lo cmavo pe le liste .a lo brivla
            check pieces.allIt(it.selmaho.isSome) and
                (pieces.len > 0 or word.readWord.is_word)  # lo cmavo pe le liste .a lo brivla
      # lo nu no da cu se cirko
      #   .i ro linji poi vasru pa cmavo po'o cu se vasru le liste
      check count_simple == LIST_CMAVO.len  # lo nu no da cu se cirko
      # `CLL 4.2`
      #   .i ro cmavo gunma poi se ciska ta'i pa valsi cu se fendi
      check count_compound == COUNT_COMPOUNDS  # `CLL 4.2`
      # lo nu no da cu se cirko
      #   .i le genturfa'i cu tcidu ro valsi pe ro jufra pagbu
      check count_phrase == COUNT_PHRASES  # lo nu no da cu se cirko
