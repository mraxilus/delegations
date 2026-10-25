## Hold converter of `tools/lists.nim` to its laws: each field read from its columns or fields,
##   odd lujvo line left out and counted, rendered module kept to 100 columns and read back, and
##   committed modules equal to committed lists rendered again.
##   CLL covers no word list file, so suite is `Internal:`, tests named by behaviour (IX.10).
##   Sample lines are copied byte for byte from `gismu.txt` and `lujvo.txt` that `DIGEST_GISMU`
##     and `DIGEST_LUJVO` pin, carriage return removed as `readSource` removes it; doc of each
##     names its line. CI installs no `lojban-common`, so no law needs it: one test compares
##     with installed gismu list and one with lujvo list where present, and each skips with
##     reason where absent (IX.9).
##   Random entries hold words of one to twenty characters, `"` among them, one space apart;
##     spaced texts hold runs of one to five spaces, at either end too.
##     Corpus holds no backslash, which `toLiteral` leaves unescaped since lists hold none, and
##     no word too long for any line, which no wrap at spaces can split (Article IX.4).
##   Regression test of wrapping draws its spaced texts inside its loop, after one seeding.
##   Other samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, os, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/entries
import ../../src/lojban_tagger/lists/[gismu, lujvo]
import ../../tools/lists


const
  SEED = 1997  ## Seed of every random draw, year of CLL first edition.
  SAMPLES = 200  ## Random entries, and random orders of lines, each law is checked over.
  WIDTH = 100  ## Column limit of Article X.1, which rendered lines keep.
  COUNT_LINES_LUJVO = 3846  ## Lines of `lujvo.txt` that `DIGEST_LUJVO` pins, none blank.
  CHARACTERS_TEXT = "abcdefxyz0123'/()[]$;\""  ## Characters random words are spelled from.
  LETTERS_LOJBAN = {'a'..'z', '\''}  ## Characters word of either list holds.
  TEXT_MODULE_GISMU = staticRead("../../src/lojban_tagger/lists/gismu.nim")
    ## Committed module of gismu list, as text.
  TEXT_MODULE_LUJVO = staticRead("../../src/lojban_tagger/lists/lujvo.nim")
    ## Committed module of lujvo list, as text.

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
  LINE_COA =
      " co'a          co'a initiative                                interval event con" &
      "tour: at the starting point of ...; initiative                   >|<    |      -" &
      "         [beginning (= co'a(r)-)]; (cf. cfari, krasi, clira)"
    ## Line 219 of `gismu.txt`: `co'a`, definition holding run of spaces.
  LINE_COU =
      " co'u          co'u cessative                                 interval event con" &
      "tour: at the ending point of ... even if not done; cessative      |  >< |      -" &
      "         [ending (= co'u(r)-)]; (cf. sisti, fanmo)"
    ## Line 221 of `gismu.txt`: `co'u`, definition holding run of spaces.
  LINE_SIRJI =
      " sirji sir          straight                                  x1 is straight/dir" &
      "ect/line segment/interval between x2 and x3; (adjective:)  x1 is linear        6" &
      "f  13    (cf. korcu, linji, kruvi, kuspe)"
    ## Line 1083 of `gismu.txt`: `sirji`, definition holding run of spaces.
  LINE_ZAO =
      " za'o          za'o superfective                              interval event con" &
      "tour: continuing too long after natural end of ...; superfective  |     ---->  a" &
      "t   0    (cf. dukse)"
    ## Line 1397 of `gismu.txt`: `za'o`, definition holding run of spaces.
  TEXT_SPACED = LINE_HEADER & "\n" & [LINE_COA, LINE_COU, LINE_SIRJI, LINE_ZAO].join("\n") & "\n"
    ## Sample of `gismu.txt` whose definitions hold runs of spaces, header first.
  EXPECTED_GISMU = [
    EntryGismu(
      word: "bacru",
      rafsi: @["ba'u"],
      keyword: "utter",
      hint: "",
      definition: "x1 utters verbally/says/phonates/speaks [vocally makes sound] x2",
    ),
    EntryGismu(
      word: "bakfu",
      rafsi: @["baf"],
      keyword: "bundle",
      hint: "'pack'",
      definition: "x1 is a bundle/package/cluster/clump/pack [shape/form] containing x2, " &
          "held together by x3",
    ),
    EntryGismu(
      word: "bi",
      rafsi: @["biv"],
      keyword: "8",
      hint: "",
      definition: "digit/number: 8 (digit)",
    ),
    EntryGismu(
      word: "bloti",
      rafsi: @["lot", "blo", "lo'i"],
      keyword: "boat",
      hint: "",
      definition: "x1 is a boat/ship/vessel [vehicle] for carrying x2, propelled by x3",
    ),
    EntryGismu(
      word: "cukta",
      rafsi: @["cku"],
      keyword: "book",
      hint: "",
      definition: "x1 is a book containing work x2 by author x3 for audience x4 preserved " &
          "in medium x5",
    ),
    EntryGismu(
      word: "datni",
      rafsi: @[],
      keyword: "data",
      hint: "",
      definition: "x1 (du'u) [fact/measurement] is data/information/statistic(s) about x2 " &
          "gathered by method x3",
    ),
    EntryGismu(
      word: "vreji",
      rafsi: @["rej", "vei"],
      keyword: "record",
      hint: "",
      definition: "x1 is a record of x2 (data/facts/du'u) about x3 (object/event) preserved " &
          "in medium x4",
    ),
  ]
    ## Entry of each sample line, fields read off by hand from columns of `entries.nim`.

  LINE_BAARMOA = "ba'armo'a:barna+morna:pattern of marks:$morna1 $morna2 $=barna1 $morna3 $barna2"
    ## Line 1 of `lujvo.txt`: tanru in Lojban.
  LINE_BADGAI =
      "badgai#defend+cover: protective cover/ shield:$bandu1 $=gacri1 $bandu2 $=gacri1 " &
      "$bandu3"
    ## Line 14 of `lujvo.txt`: tanru in English keywords, after `#`.
  LINE_DATNYVEI =
      "datnyvei:datni+vreji:file (incl. computers):$vreji1 $vreji2 $=datni2 $vreji3 " &
      "$vreji4 [ = manner of encoding]"
    ## Line 634 of `lujvo.txt`: `datnyvei`, tanru in Lojban.
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
  LINES_LUJVO_KEPT = [LINE_BAARMOA, LINE_BADGAI, LINE_DATNYVEI, LINE_FEBJICLA]
    ## Sample lines of `lujvo.txt` converter keeps.
  LINES_LUJVO_LEFT = [
    LINE_CIMNALSRA,
    LINE_SEZYPEVDUA,
    LINE_JGETERJOE,
    LINE_CIERSMITAI,
    LINE_PEVYSOASELTAI,
    LINE_DATKYPIU,
    LINE_JAIRTAI,
    LINE_BLOTI_ZERLEA,
    LINE_NALSUTYDZUKEPKLA,
  ]
    ## Sample lines of `lujvo.txt` converter leaves out, one of each odd shape.
  EXPECTED_LUJVO = [
    EntryLujvo(
      word: "ba'armo'a",
      notation: Notation.Lojban,
      parts: @["barna", "morna"],
      gloss: "pattern of marks",
    ),
    EntryLujvo(
      word: "badgai",
      notation: Notation.English,
      parts: @["defend", "cover"],
      gloss: "protective cover/ shield",
    ),
    EntryLujvo(
      word: "datnyvei",
      notation: Notation.Lojban,
      parts: @["datni", "vreji"],
      gloss: "file (incl. computers)",
    ),
    EntryLujvo(
      word: "febjicla",
      notation: Notation.English,
      parts: @["boil", "stir"],
      gloss: "roil",
    ),
  ]
    ## Entry of each line kept, fields read off by hand.


func entryGismu(word: string): Option[EntryGismu] =
  ## Find committed entry of gismu list spelled `word`.
  for entry in LIST_GISMU:
    if entry.word == word: return some(entry)


func entryLujvo(word: string): Option[EntryLujvo] =
  ## Find first committed entry of lujvo list spelled `word`.
  for entry in LIST_LUJVO:
    if entry.word == word: return some(entry)


func textsField(module, head: string): seq[string] =
  ## Read back each string field `head` opens in rendered module: pieces joined, escapes undone.
  var
    text = ""
    is_inside = false
  for line in module.splitLines:
    if line.startsWith(head): (is_inside, text) = (true, "")
    if not is_inside: continue
    text.add line[line.find('"')+1..<line.rfind('"')].replace("\\\"", "\"")
    if line.endsWith(" &"): continue
    result.add text
    is_inside = false


proc textRandom(count: int): string =
  ## Draw text of `count` words, one to twenty characters each, one space apart.
  var words: seq[string]
  for _ in 1..count:
    var word = ""
    for _ in 1..rand(1..20): word.add CHARACTERS_TEXT.sample
    words.add word
  words.join(" ")


proc textSpaced(count: int): string =
  ## Draw text of `count` words, one to five spaces apart, with spaces at either end sometimes.
  for n in 0 ..< count:
    if n > 0 or rand(3) == 0: result.add repeat(' ', rand(1..5))
    for _ in 1..rand(1..20): result.add CHARACTERS_TEXT.sample
  if rand(3) == 0: result.add repeat(' ', rand(1..5))


proc entryGismuRandom(): EntryGismu =
  ## Draw gismu entry whose fields are random text, definition long enough to wrap often.
  EntryGismu(
    word: textRandom(1),
    rafsi: @[],
    keyword: textRandom(rand(1..4)),
    hint: textRandom(rand(0..4)),
    definition: textRandom(rand(1..30)),
  )


proc entryLujvoRandom(): EntryLujvo =
  ## Draw lujvo entry of two or three random parts, gloss long enough to wrap often.
  EntryLujvo(
    word: textRandom(1),
    notation: (if rand(1) == 0: Notation.Lojban else: Notation.English),
    parts: textRandom(rand(2..3)).split(' '),
    gloss: textRandom(rand(1..30)),
  )


proc poolOrders(): seq[seq[string]] =
  ## Draw `SAMPLES` shuffled orders of sample lines of `lujvo.txt`, two blank lines among them,
  ##   into pool allocated once; caller seeds first.
  result = newSeqOfCap[seq[string]](SAMPLES)
  for _ in 1..SAMPLES:
    var lines = @LINES_LUJVO_KEPT & @LINES_LUJVO_LEFT & @["", "  "]
    lines.shuffle
    result.add lines


proc poolEntries(): seq[(seq[EntryGismu], seq[EntryLujvo])] =
  ## Draw `SAMPLES` cases of two random gismu entries and two random lujvo entries into pool
  ##   allocated once; caller seeds first.
  result = newSeqOfCap[(seq[EntryGismu], seq[EntryLujvo])](SAMPLES)
  for _ in 1..SAMPLES:
    let gismu = @[entryGismuRandom(), entryGismuRandom()]
    result.add (gismu, @[entryLujvoRandom(), entryLujvoRandom()])


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]



suite "Internal: Lists":
  test "gismu converter reads each field from its columns, header skipped":
    let entries = TEXT_GISMU.toEntriesGismu
    check entries.len == EXPECTED_GISMU.len  # header skipped, one entry for each line after
    for i, expected in EXPECTED_GISMU:
      check entries[i] == expected  # every field from its columns of `entries.nim`, trimmed
      check entryGismu(expected.word) == some(expected)  # sample agrees with committed list
    for mask in 0..<(1 shl LINES_GISMU.len):  # every subset of sample lines, exhaustive
      var (lines, expected) = (@[LINE_HEADER], newSeq[EntryGismu]())
      for i, line in LINES_GISMU:
        if (mask and (1 shl i)) == 0: continue
        lines.add line
        expected.add EXPECTED_GISMU[i]
      check lines.join("\n").toEntriesGismu == expected  # each line read alone, order kept
    let spaced = (@[LINE_HEADER] & LINES_GISMU.mapIt(it & "\n\n   ")).join("\n")
    check spaced.toEntriesGismu == @EXPECTED_GISMU  # blank lines skipped
    check LINE_HEADER.toEntriesGismu.len == 0 and toEntriesGismu("").len == 0  # header alone
    check LINE_HEADER[1..5].parseInt == LIST_GISMU.len  # committed list holds count header gives


  test "lujvo converter keeps line of either notation, tanru split at `+`":
    for i, line in LINES_LUJVO_KEPT:
      let converted = line.toEntriesLujvo
      check converted.entries == @[EXPECTED_LUJVO[i]]  # word, notation, parts, gloss
      check converted.count_left == 0  # line kept is never counted as left
      check entryLujvo(EXPECTED_LUJVO[i].word) == some(EXPECTED_LUJVO[i])  # agrees with list


  test "lujvo converter leaves each odd shape out, and counts it":
    for line in LINES_LUJVO_LEFT:
      let converted = line.toEntriesLujvo
      check converted.entries.len == 0 and converted.count_left == 1  # left out, counted once
    check toEntriesLujvo("\n  \n").count_left == 0  # blank line is no line of other shape
    randomize(SEED)
    let pool = poolOrders()
    for lines in served(pool):
      let
        converted = lines.join("\n").toEntriesLujvo
        kept = lines.filterIt(it in LINES_LUJVO_KEPT)
      check converted.entries == kept.mapIt(EXPECTED_LUJVO[LINES_LUJVO_KEPT.find(it)])  # order
      check converted.count_left == LINES_LUJVO_LEFT.len  # each odd line counted once
      check converted.entries.len + converted.count_left ==
          lines.countIt(it.strip.len > 0)  # conservation: every nonblank line kept or counted


  test "rendered module keeps 100 columns, and reads back each string":
    let
      count_left = COUNT_LINES_LUJVO - LIST_LUJVO.len
      module_gismu = toModuleGismu(LIST_GISMU, DIGEST_GISMU)
      module_lujvo = toModuleLujvo(LIST_LUJVO, count_left, DIGEST_LUJVO)
    check (module_gismu & module_lujvo).splitLines.allIt(it.len <= WIDTH)  # X.1, bytes bound
    check module_gismu.textsField("    definition: ") ==
        LIST_GISMU.mapIt(it.definition)  # helper reads back what renderer writes
    check module_lujvo.textsField("    gloss: ") == LIST_LUJVO.mapIt(it.gloss)  # read back
    randomize(SEED)
    let pool = poolEntries()
    for (entries_gismu, entries_lujvo) in served(pool):
      let
        rendered_gismu = toModuleGismu(entries_gismu, DIGEST_GISMU)
        rendered_lujvo = toModuleLujvo(entries_lujvo, 0, DIGEST_LUJVO)
      check (rendered_gismu & rendered_lujvo).splitLines.allIt(it.len <= WIDTH)  # X.1
      for (head, texts) in [
        ("    word: ", entries_gismu.mapIt(it.word)),
        ("    keyword: ", entries_gismu.mapIt(it.keyword)),
        ("    hint: ", entries_gismu.mapIt(it.hint)),
        ("    definition: ", entries_gismu.mapIt(it.definition)),
      ]:
        check rendered_gismu.textsField(head) == texts  # round trip through wrapped literal
      check rendered_lujvo.textsField("    word: ") == entries_lujvo.mapIt(it.word)  # one line
      check rendered_lujvo.textsField("    gloss: ") == entries_lujvo.mapIt(it.gloss)  # wrapped


  test "committed modules are committed lists rendered again":
    check toModuleGismu(LIST_GISMU, DIGEST_GISMU) == TEXT_MODULE_GISMU  # render of parse
    check toModuleLujvo(LIST_LUJVO, COUNT_LINES_LUJVO - LIST_LUJVO.len, DIGEST_LUJVO) ==
        TEXT_MODULE_LUJVO  # render of parse, lines left counted by conservation


  test "committed headers name pinned digests, split as rendered":
    for (module, digest) in [(TEXT_MODULE_GISMU, DIGEST_GISMU), (TEXT_MODULE_LUJVO, DIGEST_LUJVO)]:
      check digest.len == 64 and digest.allCharsInSet({'0'..'9', 'a'..'f'})  # SHA-256 in hex
      let halves = "SHA-256 `" & digest[0..31] & "`\n##   `" & digest[32 .. ^1] & "`;"
      check halves in module  # digest split in halves over two header lines
    check ("##     " & $(COUNT_LINES_LUJVO - LIST_LUJVO.len) & " lines of other shapes left out") in
        TEXT_MODULE_LUJVO  # count of lines left, as `toModuleLujvo` writes it


  test "every committed entry fits columns, and shapes converter keeps":
    for entry in LIST_GISMU:  # every entry, exhaustive
      check entry.word.len in 1..5 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # columns 2-6
      check entry.rafsi.len <= 3 and entry.rafsi.allIt(it.len in 3..4)  # three slots, 3-4 wide
      check entry.keyword.len in 1..20 and entry.hint.len <= 20  # columns 21-40 and 42-61
      check entry.definition.len in 1..96  # columns 63-158
      for field in [entry.word, entry.keyword, entry.hint, entry.definition]:
        check field == field.strip  # spaces at field ends trimmed
    for entry in LIST_LUJVO:  # every entry, exhaustive
      check entry.word.len > 0 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # word is letters
      check entry.parts.len >= 2 and entry.parts.allIt(it.len > 0)  # tanru of two parts or more
      if entry.notation == Notation.Lojban:
        check entry.parts.allIt(it.allCharsInSet(LETTERS_LOJBAN))  # Lojban parts are letters
      check entry.gloss.len > 0 and entry.gloss == entry.gloss.strip  # gloss present, trimmed
      check not entry.gloss.startsWith("$")  # place structure is no gloss


  test "committed lujvo list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "lujvo.txt"):
      skip()  # `lojban-common` absent, as in CI; `head` compares where present
    else:
      let source = readSource("lujvo.txt")
      if source.digest != DIGEST_LUJVO:
        skip()  # installed list moved from its pin, which `head` reports
      else:
        let converted = source.text.toEntriesLujvo
        check converted.entries == @LIST_LUJVO  # committed list is converter's output
        check converted.count_left == COUNT_LINES_LUJVO - LIST_LUJVO.len  # lines conserved


  test "wrapped string keeps every space, runs included":
    # Regression: `toLinesWrapped` split text by `splitWhitespace` and joined it with one space,
    #   so committed definitions of `co'a`, `co'u`, `sirji` and `za'o` lost runs of spaces.
    let entries = TEXT_SPACED.toEntriesGismu
    check entries.len == 4  # four sample lines read
    for entry in entries:
      check entry.definition.contains("  ")  # sample holds run of spaces
      check entryGismu(entry.word).get == entry  # case as found: committed entry equals source
      check toModuleGismu([entry], DIGEST_GISMU).textsField("    definition: ") ==
          @[entry.definition]  # case as found: wrapping keeps run
    randomize(SEED)
    for _ in 1..SAMPLES:  # domain: spaced text, long enough to wrap often
      let
        text = textSpaced(rand(1..30))
        entry = EntryGismu(word: "x", rafsi: @[], keyword: "x", hint: "", definition: text)
        rendered = toModuleGismu([entry], DIGEST_GISMU)
      check rendered.textsField("    definition: ") == @[text]  # domain: every space kept
      check rendered.splitLines.allIt(it.len <= WIDTH)  # X.1, wrapping still bounds lines


  test "committed gismu list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "gismu.txt"):
      skip()  # `lojban-common` absent, as in CI; `head` compares where present
    else:
      let source = readSource("gismu.txt")
      if source.digest != DIGEST_GISMU:
        skip()  # installed list moved from its pin, which `head` reports
      else:
        check source.text.toEntriesGismu == @LIST_GISMU  # committed list is converter's output
