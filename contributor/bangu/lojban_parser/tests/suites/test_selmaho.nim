## Replicate catalogue of selma'o of CLL chapter 20 against `selmaho.nim` and cmavo list.
##   Names and their order are copied from chapter 20, never from library output, so suite
##     checks names rather than repeating them.
##   Chapter 20 names each selma'o by representative cmavo, so that cmavo, spelled from name,
##     carries that selma'o in list; suite holds it for every name.
##   Lookup is held to linear scan of `LIST_CMAVO`, written here apart from binary search of
##     `dictionary.nim`, over every entry and over seeded one-letter mutations (Article IX.3).
##   Law over `cmavo.txt` reads it as outside text (`texts_outside.nim`), and skips where it is
##     absent or moved (IX.9): line of one cmavo reads with its selma'o, compound splits into
##     cmavo list holds, and phrase reads word by word.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_parser/[dictionary, forms, selmaho, tanru]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ../../tools/lists
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
    ## Every selma'o chapter 20 names, in its order, as it spells each.
  LETTERS_MUTATION = "'abcdefgijklmnoprstuvxyz.ABh"
    ## Letters of 3.1, period, and capitals and `h` that no cmavo holds, which mutations draw.
  SAMPLES_MUTATION = 5000  ## Committed cmavo mutated in one letter and looked up, seeded.
  FLOOR_UNLISTED = 3000
    ## Least of those mutations no list holds, so corpus keeps misses: 3649 read at seed `0`.
  COUNT_COMPOUNDS = 472  ## Lines of `cmavo.txt` writing compound as one word, which it pins.


func selmahoScanned(text: string): Option[Selmaho] =
  ## Find selma'o of cmavo spelled `text` by linear scan of committed list, apart from lookup.
  for entry in LIST_CMAVO:
    if entry.word == text: return some(entry.selmaho)
  none(Selmaho)


func toWord(name: string): string =
  ## Spell cmavo chapter 20 names selma'o after: lowercase, `h` standing for apostrophe.
  name.toLowerAscii.replace('h', '\'')


proc drawMutated(): seq[string] =
  ## Draw `SAMPLES_MUTATION` committed cmavo, each mutated in one letter, seeded once.
  randomize(0)
  result = newSeqOfCap[string](SAMPLES_MUTATION)
  for _ in 1 .. SAMPLES_MUTATION:
    var text = LIST_CMAVO[rand(LIST_CMAVO.high)].word
    text[rand(text.high)] = LETTERS_MUTATION.sample
    result.add text



suite "Chapter 20":
  test "Catalogue of selma'o":
    check CATALOGUE.len == Selmaho.high.ord + 1  # 20, one member for each selma'o listed
    for i, name in CATALOGUE:
      check $Selmaho(i) == name  # 20, spelling and order of catalogue
      check name.toSelmaho == some(Selmaho(i))  # 20, name reads back
      check name.toWord.selmaho == some(Selmaho(i))  # 20, "names of representative cmavo"
    check "ba'e".selmaho == some(Selmaho.Bahe)  # 20, `BAhE`, "la ba'e .djordj. klama"
    check "bau".selmaho == some(Selmaho.Bai)  # 20, `BAI`, "mi tavla bau la lojban."
    check "be".selmaho == some(Selmaho.Be)  # 20, `BE`, "mi klama be ta troci"
    check "BAHE".toSelmaho.isNone and "bahe".toSelmaho.isNone  # 20, `h` small, rest capital



suite "Internal: Cmavo list":
  test "Each selma'o of catalogue holds cmavo of list":
    var found: set[Selmaho]
    for entry in LIST_CMAVO: found.incl entry.selmaho
    check found == {Selmaho.low .. Selmaho.high}  # every member, none unused


  test "Lookup agrees with linear scan":
    for entry in LIST_CMAVO:  # every entry, exhaustive
      check entry.word.selmaho == some(entry.selmaho)  # each cmavo finds its selma'o
    for entry in LIST_GISMU:
      if entry.word.isGismu: check entry.word.selmaho.isNone  # gismu has no selma'o
      else: check entry.word.selmaho.isSome  # cmavo carrying rafsi stands in cmavo list too
    check "".selmaho.isNone and ".a".selmaho.isNone and "LO".selmaho.isNone  # misses
    var count_unlisted = 0
    for text in drawMutated():  # `SAMPLES_MUTATION` strings, seeded
      check text.selmaho == text.selmahoScanned  # binary search equals linear scan
      if text.selmaho.isNone: inc count_unlisted
    check count_unlisted >= FLOOR_UNLISTED  # corpus keeps misses (Article IX.3)


  test "Each cmavo of list reads as cmavo with its selma'o":
    for entry in LIST_CMAVO:  # every entry, exhaustive
      let reading = entry.word.readWord
      check reading.is_word and reading.kind == Kind.Cmavo  # 4.2, form of cmavo
      if reading.is_word: check reading.selmaho == some(entry.selmaho)  # 20, list gives it


  test "Each line of cmavo list reads, each cmavo with its selma'o":
    let lines = readLinesCmavo()
    if lines.isNone: skip()  # `cmavo.txt` absent or moved from its pin (`texts_outside.nim`)
    else:
      var count_simple, count_compound, count_phrase = 0
      for line in lines.get:  # every line, exhaustive
        if not line.is_compound:
          inc count_simple
          let reading = line.word.replace(".", "").readWord
          check reading.is_word and reading.selmaho ==
              line.selmaho.nameSelmaho.toSelmaho  # 20, cmavo reads with selma'o line gives
        elif ' ' notin line.word:
          inc count_compound
          let pieces = line.word.splitCompound
          check pieces.len >= 2 and pieces.allIt(it.selmaho.isSome)  # 4.2, cmavo list holds
        else:
          inc count_phrase
          for word in line.word.splitWhitespace:  # stream of words, as #811 reads
            let pieces = word.splitCompound
            check pieces.allIt(it.selmaho.isSome) and
                (pieces.len > 0 or word.readWord.is_word)  # cmavo of list, or brivla
      check count_simple == LIST_CMAVO.len  # conservation: each line of one cmavo committed
      check count_compound == COUNT_COMPOUNDS  # 4.2, each compound written as one word splits
      check count_phrase > 0  # domain reaches phrases of several words
