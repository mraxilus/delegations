## Hold converter of `tools/lists.nim` to its laws: word and rafsi of gismu list, and word and
##   selma'o of cmavo list, read from their columns, rendered module kept to 100 columns and
##   read back, and committed module equal to committed list rendered again. Hold reader of
##   outside texts (`texts_outside.nim`) to lines it reads.
##   Sibling `lojban_tagger/tests/suites/test_lists.nim` holds earlier copy, which holds English
##     fields and lujvo converter too, until #809 drops it (II.9).
##   CLL covers no word list file, so suite is `Internal:`, tests named by behaviour (IX.10).
##   Sample lines are copied byte for byte from `gismu.txt`, `cmavo.txt` and `lujvo.txt` that
##     their digests pin, carriage return removed as `readSource` removes it; doc of each names
##     its line. Two tests compare committed lists with installed ones; each skips with reason
##     where `lojban-common` is absent or moved from its pin (IX.9). `system` declares package,
##     so CI installs it.
##   Random entries hold word of one to five letters and up to three rafsi of three or four, all
##     drawn from lojban letters and apostrophe, as committed entries hold (Article IX.4).
##     Random cmavo hold word of one to eight letters, and any selma'o of chapter 20.
##   Samples are drawn into pool allocated once, after one seeding, and served by `served`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, os, random, sequtils, strutils, sugar, unittest]

import ../../src/lojban_parser/[entries, selmaho]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ../../tools/lists
import ./texts_outside


const
  SEED = 1997  ## Seed of every random draw, year of CLL first edition.
  SAMPLES = 200  ## Random entries, and random orders of lines, each law is checked over.
  WIDTH = 100  ## Column limit of Article X.1, which rendered lines keep.
  LETTERS_LOJBAN = {'a'..'z', '\''}  ## Characters word and rafsi of list hold.
  LETTERS_RANDOM = "abcdefgijklmnoprstuvxyz'"  ## Characters random words and rafsi draw from.
  TEXT_MODULE_GISMU = staticRead("../../src/lojban_parser/lists/gismu.nim")
    ## Committed module of gismu list, as text.

  LINE_HEADER =
      " 01436 Lojban                  gismu list  9/26/94        01436 Draft dictionary " &
      "rebaseline posted for review; Logflash format compatible Note: Metaphor usage risks " &
      "cultural neutrality; physical attributes are safest. Use place structures.  rafsi " &
      "list baselined as of this date.  Note: a complete set can be partially specified " &
      "with etcetera (ce zo'e)"
    ## Line 1 of `gismu.txt`: header, which converter skips.
  LINE_BACRU =
      " bacru         ba'u utter                                     x1 utters " &
      "verbally/says/phonates/speaks [vocally makes sound] x2                              " &
      "   1h 386    [also voices; does not necessarily imply communication or audience; " &
      "('says' is usually cusku)]; (cf. krixa, cusku, casnu, tavla, voksa, pinka)"
    ## Line 2 of `gismu.txt`: `bacru`, one CV'V rafsi in third slot.
  LINE_BAKFU =
      " bakfu baf          bundle               'pack'               x1 is a " &
      "bundle/package/cluster/clump/pack [shape/form] containing x2, held together by x3   " &
      "     9b   3    (cf. daski, dakli, tanxe)"
    ## Line 6 of `gismu.txt`: `bakfu`, hint in quotes.
  LINE_BI =
      " bi    biv          8                                         digit/number: 8 " &
      "(digit)                                                                          3a " &
      "  0"
    ## Line 45 of `gismu.txt`: cmavo `bi`, carrying rafsi.
  LINE_BLOTI =
      " bloti lot blo lo'i boat                                      x1 is a " &
      "boat/ship/vessel [vehicle] for carrying x2, propelled by x3                         " &
      "     7f  33    (cf. falnu, fulta, marce, jatna, sabnu)"
    ## Line 65 of `gismu.txt`: `bloti`, every rafsi slot full.
  LINE_CUKTA =
      " cukta     cku      book                                      x1 is a book " &
      "containing work x2 by author x3 for audience x4 preserved in medium x5              " &
      "1f 163    [x1 is a manifestation/container [a physical object or its analogue] of a " &
      "work/content, not necessarily using paper (= selpapri)]; (cf. cfika, prina, prosa, " &
      "tcidu, papri)"
    ## Line 247 of `gismu.txt`: `cukta`, CCV rafsi alone.
  LINE_DATNI =
      " datni              data                                      x1 (du'u) " &
      "[fact/measurement] is data/information/statistic(s) about x2 gathered by method x3  " &
      "   8b  14    [evidence (= velji'i datni or just velji'i, sidydatni)] (cf. fatci, " &
      "saske, vreji)"
    ## Line 290 of `gismu.txt`: `datni`, no rafsi.
  LINE_VREJI =
      " vreji rej     vei  record                                    x1 is a record of x2 " &
      "(data/facts/du'u) about x3 (object/event) preserved in medium x4            8c   4  " &
      "  (cf. sorcu, datni, papri)"
    ## Line 1333 of `gismu.txt`: `vreji`, CVC and CVV rafsi.
  LINES_GISMU = [LINE_BACRU, LINE_BAKFU, LINE_BI, LINE_BLOTI, LINE_CUKTA, LINE_DATNI, LINE_VREJI]
    ## Sample lines of `gismu.txt` after header, in its order.
  TEXT_GISMU = LINE_HEADER & "\n" & LINES_GISMU.join("\n") & "\n"
    ## Sample of `gismu.txt`: header, then each sample line.
  EXPECTED_GISMU = [
    EntryGismu(word: "bacru", rafsi: @["ba'u"]),
    EntryGismu(word: "bakfu", rafsi: @["baf"]),
    EntryGismu(word: "bi", rafsi: @["biv"]),
    EntryGismu(word: "bloti", rafsi: @["lot", "blo", "lo'i"]),
    EntryGismu(word: "cukta", rafsi: @["cku"]),
    EntryGismu(word: "datni", rafsi: @[]),
    EntryGismu(word: "vreji", rafsi: @["rej", "vei"]),
  ]
    ## Entry of each sample line, fields read off by hand from columns of `entries.nim`.
  LINE_BAARMOA = "ba'armo'a:barna+morna:pattern of marks:$morna1 $morna2 $=barna1 $morna3 $barna2"
    ## Line 1 of `lujvo.txt`: tanru in lojban.
  LINE_BADGAI =
      "badgai#defend+cover: protective cover/ shield:$bandu1 $=gacri1 $bandu2 $=gacri1 " &
      "$bandu3"
    ## Line 14 of `lujvo.txt`: tanru in English keywords, after `#`.
  LINE_DATNYVEI =
      "datnyvei:datni+vreji:file (incl. computers):$vreji1 $vreji2 $=datni2 $vreji3 " &
      "$vreji4 [ = manner of encoding]"
    ## Line 634 of `lujvo.txt`: `datnyvei`, tanru in lojban.
  LINE_FEBJICLA = "febjicla#boil+stir:roil:roil:$jicla1 $jicla2 $=febvi1"
    ## Line 841 of `lujvo.txt`: English, gloss given twice; first kept.
  LINE_CIMNALSRA = "cimnalsra:foldi::cilmo+na'e+srasu foldi marsh"
    ## Line 360 of `lujvo.txt`: one part, gloss empty.
  LINE_SEZYPEVDUA =
      "sezypevdu'a:sevzi+[figurative::]+dunda to dedicate oneself to someone/something, to " &
      "give oneself away"
    ## Line 2848 of `lujvo.txt`: colons inside bracket, gloss empty.
  LINE_JGETERJOE = "jgeterjo'e#knot+3rd-place-of+joined"
    ## Line 1238 of `lujvo.txt`: `#` and no colon, so no gloss.
  LINE_CIERSMITAI =
      "ci'ersmitai#system+similar+shape:$tarmi1 $=simsa1 $tarmi2 $=simsa2 $ciste1 $=simsa3"
    ## Line 322 of `lujvo.txt`: `#`, and place structure for gloss.
  LINE_PEVYSOASELTAI =
      "pevyso'aseltai#[figurative:]+egg+2nd-place-of+shape:egg-shaped:$tarmi2 $tarmi1"
    ## Line 2261 of `lujvo.txt`: `#`, colon inside bracket.
  LINE_DATKYPIU = "datkypi'u gairki'e:datka+pimlu gacri+kicne:eiderdown [quilt]"
    ## Line 630 of `lujvo.txt`: phrase for word, space inside.
  LINE_JAIRTAI = "jairtai:denmi:xance jgari+tarmi denmi xance:fist:$tarmi1 (omit $tarmi2 $=jgari3)"
    ## Line 1091 of `lujvo.txt`: five fields, one part.
  LINE_BLOTI_ZERLEA = "bloti zerle'a:bloti zekri+lebna:pirate:"
    ## Line 150 of `lujvo.txt`: phrase for word, gloss closed by colon.
  LINE_NALSUTYDZUKEPKLA =
      "nalsutydzukepkla:na'e+sutra+cadzu+,+klama:to go without walking fast:$klama1 " &
      "$klama2 $klama3 $klama4 $klama5"
    ## Line 2008 of `lujvo.txt`: `,` among parts.
  LINES_LUJVO = [
    LINE_BAARMOA, LINE_BADGAI, LINE_DATNYVEI, LINE_FEBJICLA, LINE_CIMNALSRA, LINE_SEZYPEVDUA,
    LINE_JGETERJOE, LINE_CIERSMITAI, LINE_PEVYSOASELTAI, LINE_DATKYPIU, LINE_JAIRTAI,
    LINE_BLOTI_ZERLEA, LINE_NALSUTYDZUKEPKLA,
  ]
    ## Sample lines of `lujvo.txt`, one of each shape outside text reader meets.
  EXPECTED_LUJVO = [
    LineLujvo(word: "ba'armo'a", is_english: false, parts: @["barna", "morna"]),
    LineLujvo(word: "badgai", is_english: true, parts: @["defend", "cover"]),
    LineLujvo(word: "datnyvei", is_english: false, parts: @["datni", "vreji"]),
    LineLujvo(word: "febjicla", is_english: true, parts: @["boil", "stir"]),
    LineLujvo(word: "cimnalsra", is_english: false, parts: @[]),
    LineLujvo(word: "sezypevdu'a", is_english: false, parts: @[]),
    LineLujvo(word: "jgeterjo'e", is_english: true, parts: @["knot", "3rd-place-of", "joined"]),
    LineLujvo(word: "ci'ersmitai", is_english: true, parts: @["system", "similar", "shape"]),
    LineLujvo(word: "pevyso'aseltai", is_english: true, parts: @[]),
    LineLujvo(word: "jairtai", is_english: false, parts: @[]),
    LineLujvo(word: "nalsutydzukepkla", is_english: false, parts: @[]),
  ]
    ## Line read from each sample line whose word is letters, read off by hand: parts where line
    ##   writes two or more, lojban ones in letters alone.
  LINE_HEADER_CMAVO =
      "01090 Lojban         LogFlash cmavo list 26 August 2002 -- added va'e        01090"
    ## Line 1 of `cmavo.txt`: header, which converter skips.
  LINE_A =
      ".a         A        sumti or                                  logical connective: su" &
      "mti afterthought or"
    ## Line 2 of `cmavo.txt`: `.a`, period of pause before vowel.
  LINE_AACUHI =
      ".a'acu'i   UI*1     inattentive                               attitudinal: attentive" &
      " - inattentive - avoiding"
    ## Line 4 of `cmavo.txt`: `.a'acu'i`, compound, `*` after selma'o.
  LINE_BAHE =
      " ba'e      BAhE     emphasize next                            forethought emphasis i" &
      "ndicator; indicates next word is especially emphasized"
    ## Line 27 of `cmavo.txt`: `ba'e`, selma'o `BAhE` holding `h`.
  LINE_BIHU =
      " bi'u      UI3a     new information                           discursive: newly intr" &
      "oduced information - previously introduced information                              " &
      "(cf. nindatni, saurdatni)"
    ## Line 52 of `cmavo.txt`: `bi'u`, subclass `3a` after selma'o.
  LINE_CINO =
      " cino      PA*      30                                        number/quantity: 30 [t" &
      "hirty]"
    ## Line 101 of `cmavo.txt`: `cino`, compound of two PA.
  LINE_LE_GOHI =
      " le go'i   KOhA*    the x1 of last bridi                      description pro-sumti:" &
      " reuses the value of the x1 of the previous bridi"
    ## Line 408 of `cmavo.txt`: `le go'i`, phrase of two words.
  LINE_YHY =
      ".y'y       BY2      '                                         letteral for '"
    ## Line 1048 of `cmavo.txt`: `.y'y`, subclass digit after selma'o.
  LINES_CMAVO = [LINE_A, LINE_AACUHI, LINE_BAHE, LINE_BIHU, LINE_CINO, LINE_LE_GOHI, LINE_YHY]
    ## Sample lines of `cmavo.txt` after header, in its order: one of each shape.
  TEXT_CMAVO = LINE_HEADER_CMAVO & "\n" & LINES_CMAVO.join("\n") & "\n"
    ## Sample of `cmavo.txt`: header, then each sample line.
  EXPECTED_CMAVO = [
    EntryCmavo(word: "a", selmaho: Selmaho.A),
    EntryCmavo(word: "ba'e", selmaho: Selmaho.Bahe),
    EntryCmavo(word: "bi'u", selmaho: Selmaho.Ui),
    EntryCmavo(word: "y'y", selmaho: Selmaho.By),
  ]
    ## Entry of each sample line of one cmavo, read off by hand: compound and phrase left out.
  TEXT_MODULE_CMAVO = staticRead("../../src/lojban_parser/lists/cmavo.nim")
    ## Committed module of cmavo list, as text.


func entryGismu(word: string): Option[EntryGismu] =
  ## Find committed entry of gismu list spelled `word`.
  for entry in LIST_GISMU:
    if entry.word == word: return some(entry)


func entriesRendered(module: string): seq[EntryGismu] =
  ## Read back word and rafsi of each entry line rendered module holds, apart from converter.
  for line in module.splitLines:
    if not line.startsWith("  EntryGismu("): continue
    let
      quoted = line.split('"')
      word = quoted[1]
      rafsi = collect(for i in countup(3, quoted.high - 1, 2): quoted[i])
    result.add EntryGismu(word: word, rafsi: rafsi)


proc textRandom(lengths: Slice[int]): string =
  ## Draw text of lojban letters and apostrophe, its length in `lengths`.
  for _ in 1..rand(lengths): result.add LETTERS_RANDOM.sample


proc poolEntries(): seq[seq[EntryGismu]] =
  ## Draw `SAMPLES` cases of one to three random entries into pool allocated once; caller seeds.
  result = newSeqOfCap[seq[EntryGismu]](SAMPLES)
  for _ in 1..SAMPLES:
    var entries = newSeqOfCap[EntryGismu](3)
    for _ in 1..rand(1..3):
      entries.add EntryGismu(
        word: textRandom(1..5),
        rafsi: collect(for _ in 1..rand(0..3): textRandom(3..4)),
      )
    result.add entries


func entryCmavo(word: string): Option[EntryCmavo] =
  ## Find committed entry of cmavo list spelled `word`.
  for entry in LIST_CMAVO:
    if entry.word == word: return some(entry)


func entriesRenderedCmavo(module: string): seq[EntryCmavo] =
  ## Read back word and selma'o of each entry line rendered module holds, apart from converter.
  for line in module.splitLines:
    if not line.startsWith("  EntryCmavo("): continue
    let
      word = line.split('"')[1]
      name = line.split("Selmaho.")[1].strip(chars = {')', ','})
    result.add EntryCmavo(word: word, selmaho: parseEnum[Selmaho](name))


proc poolEntriesCmavo(): seq[seq[EntryCmavo]] =
  ## Draw `SAMPLES` cases of one to three random cmavo entries into pool allocated once; caller
  ##   seeds.
  result = newSeqOfCap[seq[EntryCmavo]](SAMPLES)
  for _ in 1..SAMPLES:
    var entries = newSeqOfCap[EntryCmavo](3)
    for _ in 1..rand(1..3):
      entries.add EntryCmavo(word: textRandom(1..8), selmaho: rand(Selmaho.low .. Selmaho.high))
    result.add entries


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]



suite "Internal: Lists":
  test "gismu converter reads word and rafsi from their columns, header skipped":
    let entries = TEXT_GISMU.toEntriesGismu
    check entries.len == EXPECTED_GISMU.len  # header skipped, one entry for each line after
    for i, expected in EXPECTED_GISMU:
      check entries[i] == expected  # word and rafsi from columns of `entries.nim`, trimmed
      check entryGismu(expected.word) == some(expected)  # sample agrees with committed list
    for mask in 0..<(1 shl LINES_GISMU.len):  # every subset of sample lines, exhaustive
      var (lines, expected) = (@[LINE_HEADER], newSeqOfCap[EntryGismu](LINES_GISMU.len))
      for i, line in LINES_GISMU:
        if (mask and (1 shl i)) == 0: continue
        lines.add line
        expected.add EXPECTED_GISMU[i]
      check lines.join("\n").toEntriesGismu == expected  # each line read alone, order kept
    let spaced = (@[LINE_HEADER] & LINES_GISMU.mapIt(it & "\n\n   ")).join("\n")
    check spaced.toEntriesGismu == @EXPECTED_GISMU  # blank lines skipped
    check LINE_HEADER.toEntriesGismu.len == 0 and toEntriesGismu("").len == 0  # header alone
    check LINE_HEADER[1..5].parseInt == LIST_GISMU.len  # committed list holds count header gives


  test "rendered module keeps 100 columns, and reads back each word and rafsi":
    let module_gismu = toModuleGismu(LIST_GISMU, DIGEST_GISMU)
    check module_gismu.splitLines.allIt(it.len <= WIDTH)  # X.1, bytes bound
    check module_gismu.entriesRendered == @LIST_GISMU  # helper reads back what renderer writes
    randomize(SEED)
    let pool = poolEntries()
    for entries in served(pool):  # `SAMPLES` cases, seeded
      let rendered = toModuleGismu(entries, DIGEST_GISMU)
      check rendered.splitLines.allIt(it.len <= WIDTH)  # X.1, one entry to line fits
      check rendered.entriesRendered == entries  # round trip through rendered literal


  test "committed module is committed list rendered again":
    check toModuleGismu(LIST_GISMU, DIGEST_GISMU) == TEXT_MODULE_GISMU  # render of parse


  test "entry lacking word does not compile, as rule of data asks":
    check compiles(EntryGismu(word: "cukta"))  # control: rafsi empty by right, so unmarked
    check not compiles(EntryGismu(rafsi: @["cku"]))  # no word


  test "committed header names pinned digest, split as rendered":
    for digest in [DIGEST_GISMU, DIGEST_LUJVO, DIGEST_CMAVO]:
      check digest.len == 64 and digest.allCharsInSet({'0'..'9', 'a'..'f'})  # SHA-256 in hex
    let halves = "SHA-256 `" & DIGEST_GISMU[0..31] & "`\n##   `" & DIGEST_GISMU[32 .. ^1] & "`;"
    check halves in TEXT_MODULE_GISMU  # digest split in halves over two header lines


  test "every committed entry fits columns":
    for entry in LIST_GISMU:  # every entry, exhaustive
      check entry.word.len in 1..5 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # columns 2-6
      check entry.rafsi.len <= 3 and entry.rafsi.allIt(it.len in 3..4)  # three slots, 3-4 wide
      check entry.rafsi.allIt(it.allCharsInSet(LETTERS_LOJBAN))  # rafsi are letters
      check entry.word == entry.word.strip  # spaces at field ends trimmed


  test "cmavo converter keeps each line of one cmavo, word and selma'o from their columns":
    check TEXT_CMAVO.toEntriesCmavo == @EXPECTED_CMAVO  # compound and phrase left out, order kept
    for expected in EXPECTED_CMAVO:
      check entryCmavo(expected.word) == some(expected)  # sample agrees with committed list
    for line in [LINE_AACUHI, LINE_CINO, LINE_LE_GOHI]:
      check (LINE_HEADER_CMAVO & "\n" & line).toEntriesCmavo.len == 0  # `*`: several cmavo
    check LINE_HEADER_CMAVO.toEntriesCmavo.len == 0 and toEntriesCmavo("").len == 0  # header
    check EXPECTED_CMAVO.len + 3 == LINES_CMAVO.len  # conservation: each line kept or left out


  test "rendered cmavo module keeps 100 columns, and reads back each word and selma'o":
    let module_cmavo = toModuleCmavo(LIST_CMAVO, DIGEST_CMAVO)
    check module_cmavo.splitLines.allIt(it.len <= WIDTH)  # X.1, bytes bound
    check module_cmavo.entriesRenderedCmavo == @LIST_CMAVO  # helper reads back what is written
    randomize(SEED)
    let pool = poolEntriesCmavo()
    for entries in served(pool):  # `SAMPLES` cases, seeded
      let rendered = toModuleCmavo(entries, DIGEST_CMAVO)
      check rendered.splitLines.allIt(it.len <= WIDTH)  # X.1, one entry to line fits
      check rendered.entriesRenderedCmavo == entries  # round trip, every selma'o drawn


  test "committed cmavo module is committed cmavo list rendered again":
    check toModuleCmavo(LIST_CMAVO, DIGEST_CMAVO) == TEXT_MODULE_CMAVO  # render of parse
    let halves = "SHA-256 `" & DIGEST_CMAVO[0..31] & "`\n##   `" & DIGEST_CMAVO[32 .. ^1] & "`;"
    check halves in TEXT_MODULE_CMAVO  # digest split in halves over two header lines


  test "cmavo entry lacking word or selma'o does not compile, as rule of data asks":
    check compiles(EntryCmavo(word: "lo", selmaho: Selmaho.Le))  # control: every field named
    check not compiles(EntryCmavo(selmaho: Selmaho.Le))  # no word
    check not compiles(EntryCmavo(word: "lo"))  # no selma'o, whose zero value `A` would stand


  test "every committed cmavo entry fits its columns, once, in order":
    for i, entry in LIST_CMAVO:  # every entry, exhaustive
      check entry.word.len in 1..11 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # no period
      if i > 0: check LIST_CMAVO[i - 1].word < entry.word  # byte order, each word once


  test "committed cmavo list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "cmavo.txt"):
      skip()  # `lojban-common` absent; `system` declares it, and `head` compares where present
    else:
      let source = readSource("cmavo.txt")
      if source.digest != DIGEST_CMAVO:
        skip()  # installed list moved from its pin, which `head` reports
      else:
        check source.text.toEntriesCmavo == @LIST_CMAVO  # committed list is converter's output


  test "outside text reader keeps word of each line, and parts of either notation":
    check toLinesLujvo(LINES_LUJVO.join("\n")) == @EXPECTED_LUJVO  # each shape, order kept
    for line in [LINE_DATKYPIU, LINE_BLOTI_ZERLEA]:
      check toLinesLujvo(line).len == 0  # phrase for word stands in no domain
    check toLinesLujvo("\n  \n").len == 0  # blank line holds no word
    check EXPECTED_LUJVO.len + 2 == LINES_LUJVO.len  # conservation: each line read or left out


  test "committed gismu list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "gismu.txt"):
      skip()  # `lojban-common` absent; `system` declares it, and `head` compares where present
    else:
      let source = readSource("gismu.txt")
      if source.digest != DIGEST_GISMU:
        skip()  # installed list moved from its pin, which `head` reports
      else:
        check source.text.toEntriesGismu == @LIST_GISMU  # committed list is converter's output
