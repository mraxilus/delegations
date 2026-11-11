## Hold reader of live text to its laws (#859): text read piece by piece gives, at its end, NIF of
##   its parts read whole (`toNifParts` of `readTextParts`), byte for byte, however pieces cut it.
##   Pieces: seeded random cuts, inside words too, over each second text of corpora, and over
##     texts built of words that reach back (`texts_built.nim`), since corpora hold few of them;
##     each written word, in law of cost.
##   Each change cuts NIF back only within NIF held, and NIF it leaves is NIF reader holds. Before
##     end, NIF and tail of each change are parts of text so far, up to its last mark between
##     words, read whole as live text, so tree grows as text so far gives it.
##   Each change ties to text: each word of NIF it keeps ends at byte where it opens, or before,
##     and each word of nodes it gives opens there, or past.
##   Parts lose nothing of tree: `assembleText` builds from them tree `readGrammar` gives.
##   Piece cut into sentences (`toSentences`), each read in turn, gives in one change (`combine`)
##     what piece read whole gives: NIF of its parts at end, NIF held and grown, and tie to text.
##     Sentences join to piece, and each holds word of I or NIhO as its first word alone.
##   Cost: bytes each reading reads grow with length of text: sentences of Tatoeba joined, read
##     word by word, read at most `COST_MOST` times their bytes, and twice them as many again.
##   Worked examples give change of each piece, byte for byte: sentence going out, word cut,
##     `si` cutting back, `su` ending text with no cut back, or closing `lu` before it, closer
##     reading quotation again, `le'u` quoting `su`, `zei` joining `.i`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_parser/[grammar, live, nif, prose, selmaho, stream]
import ../sample_tatoeba/sentences
import ./[corpora, reader_nif, texts_built]


type
  Change = tuple[at, start: int, text, tail: string]  ## Define change of NIF one piece gives.

  ReadingLive = object  ## Define outcome of reading text piece by piece.
    nif: string  ## NIF held at end, as each change leaves it.
    changes: seq[Change]  ## Change of each piece, then of end.
    is_held: bool  ## Each change cuts NIF back within NIF held, which reader holds after it.
    is_grown: bool  ## Before end, NIF and tail of each change are parts of text so far.
    is_tied: bool
      ## Each word of NIF each change keeps ends at byte where change opens, or before; each word
      ##   of nodes it gives opens there, or past.
    is_cut: bool
      ## Sentences each piece is cut into join to it, and each that stream reads alone holds word
      ##   of I or NIhO as its first word alone; true where pieces are read whole.
    count_sentences: int  ## Sentences stream read alone, which `is_cut` holds.
    count_read: int  ## Bytes each reading read, summed.


const
  SEED = 859  ## Seed of random cuts and of texts built.
  COUNT_BUILT = 300  ## Texts built of words that reach back.
  PIECE_MOST = 6  ## Bytes of random piece of text built, at most, so pieces cut words.
  PIECE_CORPORA_MOST = 96
    ## Bytes of random piece of text of corpora, at most: text of one sentence reads again at
    ##   each piece, so piece of each word would cost 100 s of debug build, 14 times reading it.
  COUNT_CORPORA_LEAST = 950
    ## Texts of corpora read live: each second text, of 1,941, since each costs 3 times reading it
    ##   whole, about 12 s of debug build for half.

  COUNT_PARTED_LEAST = 100  ## Texts of corpora of more than one part, each unit read.
  COUNT_SENTENCES_CORPORA_LEAST = 450
    ## Texts of corpora read sentence by sentence: each fourth, of 1,941, which law of each second
    ##   text reads not, for cost of suite.
  COUNT_SENTENCES_LEAST = 600
    ## Sentences that stream reads alone, which law of cut holds, over texts built; 677 on adding
    ##   law, since sentence alone may cut word, or open inside quotation.
  SENTENCES_COST = 30  ## Sentences of Tatoeba joined that cost law reads, then that text twice.
  COST_MOST = 12.0
    ## Bytes read, over bytes of text, at most, word by word; 8.2 on adding law, as each piece
    ##   reads sentence still open again.
  COST_TWICE_MOST = 2.2  ## Bytes twice text reads, over bytes text reads, at most.
  TEXTS_LOHU_ERASED = [
    "lo'u cu le'u si mi .i fa'o zarci",  # fuzz of live law found it: `fa'o` read as word
    "lo'u le'u si mi .i zoi gy. ko .gy.",  # `zoi` read as word, as inside quotation
    "lo'u mi le'u sa le'u do .i fa'o ko",  # `sa` erases `le'u`
    "lo'u zo le'u le'u si mi .i fa'o ko",  # `zo` quotes first `le'u`, and second closes
  ]
    ## Texts holding `lo'u` whose `le'u` erasure erases, then word stream reads otherwise inside
    ##   words `lo'u` quotes: `fa'o`, which ends input, or `zoi`, which quotes text; constructed.
  TEXTS_LOHU_QUOTED = [
    "zo lo'u si nai fa'o cu",  # fuzz of live law found it: `fa'o` read as word
    "zo lo'u si .i zoi gy. ko .gy.",  # `zoi` read as word, as inside quotation
    "zo lo'u si ui fa'o mi",  # indicator after `si`
  ]
    ## Texts where `zo` quotes `lo'u`, as stream reads it, and `si` erases that `lo'u`: rules then
    ##   refuse `zo`, and `lo'u` stands alone, though stream reads no words it quotes; then word
    ##   stream reads otherwise inside words `lo'u` quotes; constructed.
  TEXTS_LOHU_HELD = [
    "zo la'o si lo'u mi .i la'o",  # fuzz of live law found it: `la'o` read as quotation
    "zo la'o si lo'u do .i fa'o mi",  # `fa'o` read as end of input
    "zo zoi si lo'u mi .i zoi gy. ko .gy.",  # `zoi` read as quotation
  ]
    ## Texts where `zo` quotes `la'o` or `zoi`, as stream reads it, `si` erases it, and rules
    ##   then read it as quotation of three words, `lo'u` among them; stream reads words `lo'u`
    ##   quotes to end of text, so word after reads inside them; constructed.
  TEXTS_SA_PARTED = [
    "ni'o .i sa 1987 zo .i si",  # fuzz of live law found it: `sa` reads again not
    "mi klama .i sa 1987 zo .i si do",  # word after it
    "ni'o .i sa 1987 1988 zo .i si",  # two words stream refuses
    "ui lo sa bu ba'e le si",  # fuzz of live law found it: `bu`, then `ba'e`, refused
    "ui lo sa zei ba'e le si",  # `zei`, then `ba'e`, refused
  ]
    ## Texts where words stream or rules refuse stand between `sa` and word after them, which
    ##   gives its marker (19.13); later word refuses that word too, so marker changes:
    ##   `si` erases word `zo` quotes, so `zo` is refused, or `ba'e` marks no word; constructed.
  TEXTS_ZEI_REFUSED = [
    "lo'u bu zei zoi lu nai ui si cu je",  # fuzz of live law found it: `zei` reads again not
    "lo'u bu zei la'o lu nai ui si cu je",  # `la'o`
    "lo'u bu zei zoi lu nai ui si klama do",  # `klama`
    "lo'u bu bu zei zoi lu nai ui si cu je",  # two `bu`
    "lo'u bu zei ui si zoi lu nai ui si cu je",  # erasure between `zei` and quotation
  ]
    ## Texts where rules refuse `bu` and `zei`, then quotation opens, inside words `lo'u` quotes,
    ##   which waits as opener; `si` erases word quotation takes, so rules refuse quotation too,
    ##   and `zei` joins `bu` to word after it (19.16); constructed.
  CUTS_CLOSER = [
    (text: "to .i to toi to bu toi ba'e", cuts: @[1, 9, 18, 23, 24]),  # fuzz of live law found it
    (text: "to mi .i to bu toi do", cuts: @[6, 12, 13, 19]),
    (text: "lu mi .i lu bu li'u do", cuts: @[5, 11, 14, 20]),
    (text: "tu'e mi .i tu'e bu tu'u do", cuts: @[6, 8, 9, 11, 14, 16, 18, 24]),
  ]
    ## Texts where opener waits, then text read again opens past it; `bu` then makes opener
    ##   after it lerfu word, so closer closes first opener, past text read again; with cuts
    ##   that cut it so, which search over random cuts found; constructed.
  TEXTS_SU = [
    "mi su si do", "mi su sa do",  # erasure after `su` reaches no word before it (19.13)
    "lu mi klama .i do su ko li'u",  # `lu` closes at `su`, so `li'u` after it closes none
    "lo'u mi su do le'u .i ko",  # `le'u` quotes `su`
    "ba'e zoi su li'u bu si cu .i su fa'o",  # `zoi` quotes `su`, and `ba'e` marks quotation
    "zo su si si", "zo su si sa zarci",  # erasure quotes `su` again, as quotation reads whole
    "lo'u su la'o le le'u sa le klama",  # `le'u` quotes `su`, and `la'o` reads as word
  ]
    ## Texts where `su` ends text before it, or where quotation quotes it once closed, which
    ##   reach back past it; fuzz of live law found last four, of which last read wrong when `su`
    ##   erased text before it.
  CUTS_ENDED = [
    (text: "tu'u si fa'o lo", cuts: toSeq(1 .. 14)),
    (text: "gy ku xyz ba'e gy si fa'o zo sa 1987", cuts: @[2, 6, 7, 12, 17, 22, 25, 31, 33, 34]),
    (
      text: "cu sa'a sa'a li'u si fa'o ni'o 1987 .i",
      cuts: @[4, 5, 8, 13, 19, 23, 25, 26, 31, 36],
    ),
  ]
    ## Texts where words erasure erases stand before `fa'o`, whose node shares their span; with
    ##   cuts fuzz of live law found, as unit of each word no unit held came in.
  LINE_MI_KLAMA = "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
    "(tanru_unit_2 130 (BRIVLA 3 8 \"klama\")) (tail_terms)))\n"
    ## Line of node of `mi klama`, which examples open with.
  LINE_DO = "(text_1 0 (I 10 11 \"i\") (sumti_6 4 (KOhA 12 14 \"do\")))\n"
    ## Line of node of `.i do` after it, while sentence is open.
  LINE_ERASED = "(rivbi Erasure 3 8 \"klama\" 10 11 \"i\" 12 14 \"do\" 15 17 \"si\" " &
    "18 20 \"si\" 21 23 \"si\")\n"
    ## Line of words three `si` erase in `mi klama .i do si si si`, each `si` with them, as one
    ##   unit.
  LINE_SUHI = "(srera 3 paragraphs 4 (nitcu A BAI BIhI BU BY CAhA CEhE COI CU CUhE DOI FA " &
    "FAhA FEhE FIhO GA GAhO GOI GOhA GUhA I JAI JOI KE KI KOhA LA LAU LAhE LE LI LOhU LU ME " &
    "MOhI NA NAhE NIhO NOI NU NUhA NUhI PA PEhE PU SE SEI SOI TAhE TEI TO VA VAU VEI VEhA " &
    "VIhA VUhO XI ZAhO ZEI ZEhA ZI ZO ZOI ZOhU BRIVLA) (sumti_6 0 (KOhA 0 2 \"mi\")) " &
    "(mex_operator 370 (VUhU 3 7 \"suhi\")) (sumti_6 0 (KOhA 8 10 \"do\")))\n"
    ## Line of node of `mi su'i do`, which grammar stops in at `su'i`.
  LINE_ZEI = "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
    "(selbri_3 130 (tanru_unit_2 134 (BRIVLA 3 8 \"klama\")) (tanru_unit_2 134 " &
    "(ZEI 10 11 \"i\" 12 15 \"zei\" 16 21 \"broda\"))) (tail_terms)))\n"
    ## Line of node of `mi klama .i zei broda`, one sentence.
  EXAMPLES_LIVE: seq[tuple[pieces: seq[string], changes: seq[Change]]] = @[
    (
      pieces: @["mi klama .i do ", "cad", "zu"],
      changes: @[
        (28, 0, LINE_MI_KLAMA, LINE_DO),
        (141, 10, "", LINE_DO),
        (141, 10, "", LINE_DO),
        (
          141, 10, "(text_1 0 (I 10 11 \"i\") (sentence 4 (sumti_6 80 " &
            "(KOhA 12 14 \"do\")) (bridi_tail_3 50 (tanru_unit_2 130 " &
            "(BRIVLA 15 20 \"cadzu\")) (tail_terms))))\n",
          "",
        ),
      ],
    ),  # sentence goes out once next opens; word cut waits for mark that ends it
    (
      pieces: @["mi klama .i do ", "si si si "],
      changes: @[
        (28, 0, LINE_MI_KLAMA, LINE_DO),
        (28, 0, "", "(sumti_6 0 (KOhA 0 2 \"mi\"))\n" & LINE_ERASED),
        (28, 0, "(sumti_6 0 (KOhA 0 2 \"mi\"))\n" & LINE_ERASED, ""),
      ],
    ),  # third `si` erases `klama`, so NIF cuts back to sentence that held it (19.13)
    (
      pieces: @["mi 1987 klama .i ", "su ko "],
      changes: @[
        (
          28, 0, "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) " &
            "(rivbi Stream Letter 3 7 \"1987\") (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 8 13 \"klama\")) (tail_terms)))\n",
          "(text_1 0 (I 15 16 \"i\"))\n",
        ),
        (
          175, 15, "(text_1 0 (I 15 16 \"i\"))\n(rivbi SU 17 19 \"su\")\n",
          "(sumti_6 0 (KOhA 20 22 \"ko\"))\n",
        ),
        (222, 20, "(sumti_6 0 (KOhA 20 22 \"ko\"))\n", ""),
      ],
    ),  # `su` ends text before it, which stays as it read: NIF cuts back nowhere (ruling on #859)
    (
      pieces: @["lu mi klama .i do ", "su ko "],
      changes: @[
        (
          28, 0, "(sumti_6 0 (LU 0 2 \"lu\") (sentence 0 (sumti_6 80 (KOhA 3 5 \"mi\")) " &
            "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 6 11 \"klama\")) " &
            "(tail_terms))))\n",
          "(text_1 0 (I 13 14 \"i\") (sumti_6 4 (KOhA 15 17 \"do\")))\n",
        ),
        (
          28, 0, "(sumti_6 0 (LU 0 2 \"lu\") (paragraph 0 (sentence 11 (sumti_6 80 " &
            "(KOhA 3 5 \"mi\")) (bridi_tail_3 50 (tanru_unit_2 130 " &
            "(BRIVLA 6 11 \"klama\")) (tail_terms))) (I 13 14 \"i\") " &
            "(sumti_6 20 (KOhA 15 17 \"do\"))))\n(rivbi SU 18 20 \"su\")\n",
          "(sumti_6 0 (KOhA 21 23 \"ko\"))\n",
        ),
        (250, 21, "(sumti_6 0 (KOhA 21 23 \"ko\"))\n", ""),
      ],
    ),  # `lu` waits till `su` ends its text, and closes there, as at end, so NIF cuts back to it
    (
      pieces: @["lo'u mi su do ", "le'u .i ko "],
      changes: @[
        (
          28, 0,
          "(rivbi Quotation 0 4 \"lohu\")\n(sumti_6 0 (KOhA 5 7 \"mi\"))\n" &
            "(rivbi SU 8 10 \"su\")\n",
          "(sumti_6 0 (KOhA 11 13 \"do\"))\n",
        ),
        (
          28, 0,
          "(sumti_6 0 (LOhU 0 4 \"lohu\" 5 7 \"mi\" 8 10 \"su\" 11 13 \"do\" 14 18 \"lehu\"))\n",
          "(text_1 0 (I 20 21 \"i\") (sumti_6 4 (KOhA 22 24 \"ko\")))\n",
        ),
        (101, 20, "(text_1 0 (I 20 21 \"i\") (sumti_6 4 (KOhA 22 24 \"ko\")))\n", ""),
      ],
    ),  # `lo'u` waits, so `su` after it ends text; `le'u` quotes `su` once it comes (19.9)
    (
      pieces: @["mi cusku lu do klama .i mi cadzu ", "li'u .i ko "],
      changes: @[
        (
          28, 0, "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 3 8 \"cusku\")) (sumti_6 71 (LU 9 11 \"lu\") " &
            "(sentence 0 (sumti_6 80 (KOhA 12 14 \"do\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 15 20 \"klama\")) (tail_terms))))))\n",
          "(text_1 0 (I 22 23 \"i\") (sentence 4 (sumti_6 80 (KOhA 24 26 \"mi\")) " &
            "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 27 32 \"cadzu\")) " &
            "(tail_terms))))\n",
        ),
        (
          28, 0, "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 3 8 \"cusku\")) (sumti_6 71 (LU 9 11 \"lu\") " &
            "(paragraph 0 (sentence 11 (sumti_6 80 (KOhA 12 14 \"do\")) " &
            "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 15 20 \"klama\")) " &
            "(tail_terms))) (I 22 23 \"i\") " &
            "(sentence 11 (sumti_6 80 (KOhA 24 26 \"mi\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 27 32 \"cadzu\")) (tail_terms)))) " &
            "(LIhU 33 37 \"lihu\"))))\n",
          "(text_1 0 (I 39 40 \"i\") (sumti_6 4 (KOhA 41 43 \"ko\")))\n",
        ),
        (440, 39, "(text_1 0 (I 39 40 \"i\") (sumti_6 4 (KOhA 41 43 \"ko\")))\n", ""),
      ],
    ),  # `lu` waits, so sentences after it go out; `li'u` reads them again as quotation
    (
      pieces: @["mi su", "'i do "],
      changes: @[
        (28, 0, "", "(sumti_6 0 (KOhA 0 2 \"mi\"))\n"),
        (28, 0, "", LINE_SUHI),
        (28, 0, LINE_SUHI, ""),
      ],
    ),  # `su` that piece cuts is `su'i` once next piece ends it, so erases nothing
    (
      pieces: @["mi klama .i ", "zei broda "],
      changes: @[
        (28, 0, LINE_MI_KLAMA, "(text_1 0 (I 10 11 \"i\"))\n"),
        (28, 0, "", LINE_ZEI),
        (28, 0, LINE_ZEI, ""),
      ],
    ),  # `zei` joins `.i` to word after it, so `.i` opens no sentence, and NIF cuts back (4.6)
  ]
    ## Pieces of text, and change NIF gives for each, then for end, byte for byte.



#[ Readers ]#

func spansNif(nif: string): seq[tuple[start, finish: int]] =
  ## Give byte where each word of each terminal of module opens, and byte past it, in order of
  ##   module.
  func addSpans(node: NodeNif, spans: var seq[tuple[start, finish: int]]) =
    ## Add bytes of each word of each terminal under node to `spans`; directive holds none.
    if node.kind != KindNif.Compound or node.text.startsWith("."): return
    if node.children.len > 0 and node.children[^1].kind == KindNif.Literal:
      var k = 0
      while node.children[k].kind == KindNif.Identifier: inc k
      for m in countup(k, node.children.high, 3):
        spans.add (node.children[m].number, node.children[m + 1].number)
      return
    for child in node.children: child.addSpans(spans)

  for node in nif.readModule: node.addSpans(result)


func isOpener(occurrence: Occurrence): bool =
  ## Tell whether word opens sentence or paragraph: cmavo of selma'o I or NIhO.
  occurrence.reading.is_word and occurrence.reading.selmaho.isSome and
    occurrence.reading.selmaho.get in {Selmaho.I, Selmaho.Niho}


func countCut(piece: string, sentences: openArray[string]): int =
  ## Count sentences stream reads alone, where sentences join to piece and each such holds word of
  ##   I or NIhO as its first word alone, save first, which may hold none; -1 where not.
  if sentences.join != piece: return -1
  for k in 0 ..< sentences.len:
    let reading = sentences[k].readStream
    if not reading.is_read or reading.occurrences.len == 0: continue  # sentence alone cuts word
    for n in 0 ..< reading.occurrences.len:
      if reading.occurrences[n].isOpener != (n == 0 and (k > 0 or reading.occurrences[0].isOpener)):
        return -1
    inc result


func readLive(
  text: string, cuts: openArray[int], is_growing = false, is_sentences = false
): ReadingLive =
  ## Read text piece by piece, cut at each byte of `cuts`, and hold NIF each change leaves.
  ##   With `is_growing`, test NIF and tail of each change before end against text so far. With
  ##   `is_sentences`, read each piece sentence by sentence, as script does on thread of page, and
  ##   join changes of its sentences into change of piece.
  var
    reader = initReaderLive()
    last = 0
  result = ReadingLive(nif: HEADER, is_held: true, is_grown: true, is_tied: true, is_cut: true)
  template apply(change: ChangeNif) =
    ## Cut NIF held back as change gives, then add its nodes, and keep change; test that each word
    ##   of NIF it keeps ends at byte it opens at, or before, and each word it gives opens there.
    result.is_held = result.is_held and change.at <= result.nif.len
    result.nif.setLen(min(change.at, result.nif.len))
    result.is_tied = result.is_tied and result.nif.spansNif.allIt(it.finish <= change.start) and
      (HEADER & change.text & change.tail).spansNif.allIt(it.start >= change.start)
    result.nif.add change.text
    result.is_held = result.is_held and result.nif == reader.toNif
    result.changes.add (change.at, change.start, change.text, change.tail)
  for k in 0 .. cuts.len:
    let at = (if k < cuts.len: cuts[k] else: text.len)
    var changes: seq[ChangeNif]
    if is_sentences:
      let
        sentences = text[last ..< at].toSentences
        count = text[last ..< at].countCut(sentences)
      result.is_cut = result.is_cut and count >= 0
      result.count_sentences += max(count, 0)
      for n in 0 ..< sentences.len: changes.add reader.push(sentences[n])
    else: changes.add reader.push(text[last ..< at])
    let change = (if is_sentences: changes.combine(reader.toNif) else: changes[0])
    apply(change)
    last = at
    var ending = at  # text so far, up to its last mark between words
    while ending > 0 and text[ending - 1] notin MARKS_BOUNDARY: dec ending
    if is_growing and ending > 0:
      let grown = readTextParts(text[0 ..< ending], is_live = true).reading.toNifParts
      result.is_grown = result.is_grown and result.nif & change.tail == grown
  let change = reader.finish  # template reads its argument at each use
  apply(change)
  result.count_read = reader.countRead


func cutsWords(text: string): seq[int] =
  ## Give byte of each space before word, so each written word is piece of its own.
  for k in 1 ..< text.len:
    if text[k] == ' ': result.add k


func cutsRandom(text: string, rng: var Rand, most: int): seq[int] =
  ## Give bytes at random, at most `most` apart, so pieces cut words.
  var at = rng.rand(1 .. most)
  while at < text.len:
    result.add at
    at += rng.rand(1 .. most)


func readPool(): seq[tuple[key, text: string, whole: ReadingParts]] =
  ## Read each text of corpora as its parts, once, for laws that read it.
  for (key, text) in textsCorpora(): result.add (key, text, readTextParts(text))


func textCost(count: int): string =
  ## Join first `count` sentences of Tatoeba into one text, each its own sentence.
  var texts: seq[string]
  for k in 0 ..< count: texts.add SENTENCES_TATOEBA[k].text  # slice would copy each entry
  texts.join(" .i ")



suite "Internal: Live text":
  let pool = readPool()

  test "Text read piece by piece gives NIF of its parts read whole, over corpora":
    var
      rng = initRand(SEED)
      count = 0
    for k, (key, text, whole) in pool:
      if k mod 2 == 1: continue  # each second text, for cost of suite
      checkpoint key & ": " & text
      let live = text.readLive(text.cutsRandom(rng, PIECE_CORPORA_MOST))
      check live.nif == whole.reading.toNifParts  # header of `live.nim`, law
      check live.is_held  # header of `live.nim`, cursor cuts back within NIF held
      check live.is_tied  # `ChangeNif` of `live.nim`, byte where change opens
      inc count
    check count >= COUNT_CORPORA_LEAST  # IX.3, guard keeps texts of corpora


  test "Text built of words that reach back gives NIF of its parts read whole, and grows":
    var rng = initRand(SEED)
    for k in 0 ..< COUNT_BUILT:
      let
        text = rng.textBuilt
        cuts = text.cutsRandom(rng, PIECE_MOST)
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_held  # header of `live.nim`, cursor cuts back within NIF held
      check live.is_grown  # header of `live.nim`, tail grows as text so far gives it
      check live.is_tied  # `ChangeNif` of `live.nim`, byte where change opens
      check readTextParts(text).reading.isCovering(text)  # header of `nif.nim`, word in one leaf


  test "Piece read sentence by sentence gives NIF that piece read whole gives, over corpora":
    var
      rng = initRand(SEED)
      count = 0
    for k, (key, text, whole) in pool:
      if k mod 4 != 1: continue  # each fourth text, which law of each second text reads not
      checkpoint key & ": " & text
      let live = text.readLive(text.cutsRandom(rng, PIECE_CORPORA_MOST), is_sentences = true)
      check live.nif == whole.reading.toNifParts  # `toSentences` of `live.nim`, cut moves no NIF
      check live.is_held  # `combine` of `live.nim`, NIF before least offset stands
      check live.is_tied  # `combine` of `live.nim`, least byte ties change of all
      check live.is_cut  # `toSentences` of `live.nim`, sentence opens at I or NIhO alone
      inc count
    check count >= COUNT_SENTENCES_CORPORA_LEAST  # IX.3, guard keeps texts of corpora


  test "Text built, read sentence by sentence, gives NIF of its parts read whole, and grows":
    var
      rng = initRand(SEED)
      count = 0
    for k in 0 ..< COUNT_BUILT:
      let
        text = rng.textBuilt
        cuts = text.cutsRandom(rng, PIECE_MOST * 4)  # pieces of words, so pieces hold sentences
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true, is_sentences = true)
      check live.nif == readTextParts(text).reading.toNifParts  # `toSentences`, cut moves no NIF
      check live.is_held  # `combine` of `live.nim`, NIF before least offset stands
      check live.is_grown  # `combine` of `live.nim`, tail of last sentence is tail of piece
      check live.is_tied  # `combine` of `live.nim`, least byte ties change of all
      check live.is_cut  # `toSentences` of `live.nim`, sentence opens at I or NIhO alone
      count += live.count_sentences
    check count >= COUNT_SENTENCES_LEAST  # IX.3, guard keeps sentences stream reads alone


  test "Lo'u whose le'u erasure erases waits for none, so text after it reads as stream reads it":
    for text in TEXTS_LOHU_ERASED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `prose.nim`, stream reads `le'u` erasure erases (19.9)


  test "Lo'u that zo quotes in stream waits for none, though rules refuse zo":
    for text in TEXTS_LOHU_QUOTED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `prose.nim`, stream reads `lo'u` that `zo` quotes (19.10)


  test "Lo'u that rules hold in quotation waits, where stream reads words it quotes":
    for text in TEXTS_LOHU_HELD:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `prose.nim`, stream reads words `lo'u` quotes (19.9)


  test "Sa reads again where word after it changes, past words stream or rules refuse":
    for text in TEXTS_SA_PARTED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `live.nim`, tail grows as text so far gives it (19.13)


  test "Zei that rules refuse reads again with quotation after it, once they refuse quotation":
    for text in TEXTS_ZEI_REFUSED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `live.nim`, tail grows as text so far gives it (19.16)


  test "Closer reads back past text read again, where opener there opens no more":
    for (text, cuts) in CUTS_CLOSER:
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `live.nim`, closer of opener that waits (17.4)


  test "Su ends text before it, which stays, save where quotation quotes it once closed":
    for text in TEXTS_SU:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `live.nim`, `su` and quotation that quotes it (19.13)


  test "Fa'o goes out once, and end reads it again from span of its node":
    for (text, cuts) in CUTS_ENDED:
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `live.nim`, `fa'o` that ends input (19.15)


  test "Parts lose nothing of tree: assembleText builds tree grammar gives, over corpora":
    var count = 0
    for (key, text, whole) in pool:
      template reading: untyped = whole.reading
        ## Alias reading of parts, which `let` would copy.
      let is_read = reading.units.allIt(it.is_read) and reading.tree.children.len > 1
      if not is_read: continue
      let
        terminals = reading.units.mapIt(it.terminal)
        strict = terminals.readGrammar
      if not strict.is_read: continue
      checkpoint key & ": " & text
      let tree = terminals.assembleText(reading.tree.children)
      check tree.isSome  # header of `grammar.nim`, parts build tree of text
      if tree.isNone: continue
      check tree.get.toNif(reading) == strict.tree.toNif(reading)
        # header of `live.nim`, nothing of tree is lost
      inc count
    check count >= COUNT_PARTED_LEAST  # IX.3, guard keeps texts of more than one part


  test "Bytes read grow with length of text, word by word":
    let
      text = textCost(SENTENCES_COST)
      twice = text & " .i " & text
      once = text.readLive(text.cutsWords)
      both = twice.readLive(twice.cutsWords)
    check once.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
    check float(once.count_read) <= COST_MOST * float(text.len)  # header of `live.nim`, cost
    check float(both.count_read) <= COST_TWICE_MOST * float(once.count_read)
      # header of `live.nim`, cost grows with length of text, not with its square


  test "Worked examples give change of each piece, then of end, byte for byte":
    for (pieces, changes) in EXAMPLES_LIVE:
      let text = pieces.join
      checkpoint text
      var cuts: seq[int]
      for k in 0 ..< pieces.high: cuts.add (if k == 0: 0 else: cuts[^1]) + pieces[k].len
      let live = text.readLive(cuts)
      check live.changes == changes  # header of `live.nim`, cursor, tail and reach back
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
