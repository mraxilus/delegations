## Hold reader of live text to its laws (#859): text read piece by piece gives, at its end, NIF of
##   its parts read whole (`toNifParts` of `readTextParts`), byte for byte, however pieces cut it.
##   Pieces: seeded random cuts, inside words too, over each second text of corpora, and over
##     texts built of words that reach back (`WORDS_BUILT`), since corpora hold few of them;
##     each written word, in law of cost.
##   Each change cuts NIF back only within NIF held, and NIF it leaves is NIF reader holds. Before
##     end, NIF and tail of each change are parts of text so far, up to its last mark between
##     words, read whole as live text, so tree grows as text so far gives it.
##   Parts lose nothing of tree: `assembleText` builds from them tree `readGrammar` gives.
##   Cost: bytes each reading reads grow with length of text: sentences of Tatoeba joined, read
##     word by word, read at most `COST_MOST` times their bytes, and twice them as many again.
##   Worked examples give change of each piece, byte for byte: sentence going out, word cut,
##     `si` and `su` cutting back, closer reading quotation again, `zei` joining `.i`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_parser/[grammar, live, nif, prose, stream]
import ../sample_tatoeba/sentences
import ./corpora


type
  Change = tuple[at: int, text, tail: string]  ## Define change of NIF one piece gives.

  ReadingLive = object  ## Define outcome of reading text piece by piece.
    nif: string  ## NIF held at end, as each change leaves it.
    changes: seq[Change]  ## Change of each piece, then of end.
    is_held: bool  ## Each change cuts NIF back within NIF held, which reader holds after it.
    is_grown: bool  ## Before end, NIF and tail of each change are parts of text so far.
    count_read: int  ## Bytes each reading read, summed.


const
  SEED = 859  ## Seed of random cuts and of texts built.
  COUNT_BUILT = 300  ## Texts built of words that reach back.
  WORDS_BUILT_MOST = 14  ## Words of text built, at most.
  PIECE_MOST = 6  ## Bytes of random piece of text built, at most, so pieces cut words.
  PIECE_CORPORA_MOST = 96
    ## Bytes of random piece of text of corpora, at most: text of one sentence reads again at
    ##   each piece, so piece of each word would cost 100 s of debug build, 14 times reading it.
  COUNT_CORPORA_LEAST = 950
    ## Texts of corpora read live: each second text, of 1,941, since each costs 3 times reading it
    ##   whole, about 12 s of debug build for half.

  COUNT_PARTED_LEAST = 100  ## Texts of corpora of more than one part, each unit read.
  SENTENCES_COST = 30  ## Sentences of Tatoeba joined that cost law reads, then that text twice.
  COST_MOST = 12.0
    ## Bytes read, over bytes of text, at most, word by word; 8.2 on adding law, as each piece
    ##   reads sentence still open again.
  COST_TWICE_MOST = 2.2  ## Bytes twice text reads, over bytes text reads, at most.
  WORDS_BUILT = [
    "mi", "do", "ko", "klama", "cadzu", "zarci", "broda", "le", "lo", "ku", "cu", "je", "bo", "nai",
    ".i", ".i", "ni'o", "si", "sa", "su", "zo", "lo'u", "le'u", "zoi", "gy", "la'o", "lu", "li'u",
    "to", "toi", "tu'e", "tu'u", "zei", "bu", "ba'e", "ui", "fa'o", "sa'a", "su'i", "xyz", "1987",
  ]
    ## Words texts built hold: words that reach back, open or close quotation or text inside
    ##   text, end input, or start with words that do; and plain words around them.
  TEXTS_LOHU_ERASED = [
    "lo'u cu le'u si mi .i fa'o zarci",  # fuzz of live law found it: `fa'o` read as word
    "lo'u le'u si mi .i zoi gy. ko .gy.",  # `zoi` read as word, as inside quotation
    "lo'u mi le'u sa le'u do .i fa'o ko",  # `sa` erases `le'u`
    "lo'u zo le'u le'u si mi .i fa'o ko",  # `zo` quotes first `le'u`, and second closes
  ]
    ## Texts holding `lo'u` whose `le'u` erasure erases, then word stream reads otherwise inside
    ##   words `lo'u` quotes: `fa'o`, which ends input, or `zoi`, which quotes text; constructed.
  LINE_MI_KLAMA = "(sentence 0 40 (sumti_6 80 97 (KOhA 0 \"mi\")) (bridi_tail_3 50 53 " &
    "(tanru_unit_2 130 152 (BRIVLA 3 \"klama\")) (tail_terms 71)))\n"
    ## Line of node of `mi klama`, which examples open with.
  LINE_DO = "(text_1 0 2 (I 10 \"i\") (sumti_6 4 97 (KOhA 12 \"do\")))\n"
    ## Line of node of `.i do` after it, while sentence is open.
  LINE_SUHI = "(error 3 paragraphs 4 (expects A BAI BIhI BU BY CAhA CEhE COI CU CUhE DOI FA " &
    "FAhA FEhE FIhO GA GAhO GOI GOhA GUhA I JAI JOI KE KI KOhA LA LAU LAhE LE LI LOhU LU ME " &
    "MOhI NA NAhE NIhO NOI NU NUhA NUhI PA PEhE PU SE SEI SOI TAhE TEI TO VA VAU VEI VEhA " &
    "VIhA VUhO XI ZAhO ZEI ZEhA ZI ZO ZOI ZOhU BRIVLA) (sumti_6 0 97 (KOhA 0 \"mi\")) " &
    "(mex_operator 370 374 (VUhU 3 \"suhi\")) (sumti_6 0 97 (KOhA 8 \"do\")))\n"
    ## Line of node of `mi su'i do`, which grammar stops in at `su'i`.
  LINE_ZEI = "(sentence 0 40 (sumti_6 80 97 (KOhA 0 \"mi\")) (bridi_tail_3 50 53 " &
    "(selbri_3 130 133 (tanru_unit_2 134 152 (BRIVLA 3 \"klama\")) (tanru_unit_2 134 152 " &
    "(ZEI 10 \"i\" \"zei\" \"broda\"))) (tail_terms 71)))\n"
    ## Line of node of `mi klama .i zei broda`, one sentence.
  EXAMPLES_LIVE: seq[tuple[pieces: seq[string], changes: seq[Change]]] = @[
    (
      pieces: @["mi klama .i do ", "cad", "zu"],
      changes: @[
        (28, LINE_MI_KLAMA, LINE_DO),
        (153, "", LINE_DO),
        (153, "", LINE_DO),
        (
          153, "(text_1 0 2 (I 10 \"i\") (sentence 4 40 (sumti_6 80 97 (KOhA 12 \"do\")) " &
            "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 15 \"cadzu\")) " &
            "(tail_terms 71))))\n",
          "",
        ),
      ],
    ),  # sentence goes out once next opens; word cut waits for mark that ends it
    (
      pieces: @["mi klama .i do ", "si si si "],
      changes: @[
        (28, LINE_MI_KLAMA, LINE_DO),
        (28, "", "(sumti_6 0 97 (KOhA 0 \"mi\"))\n"),
        (28, "(sumti_6 0 97 (KOhA 0 \"mi\"))\n", ""),
      ],
    ),  # third `si` erases `klama`, so NIF cuts back to sentence that held it (19.13)
    (
      pieces: @["mi 1987 klama .i ", "su ko "],
      changes: @[
        (
          28, "(sentence 0 40 (sumti_6 80 97 (KOhA 0 \"mi\")) (unread 3 Stream Letter \"1987\") " &
            "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 8 \"klama\")) (tail_terms 71)))\n",
          "(text_1 0 2 (I 15 \"i\"))\n",
        ),
        (28, "", "(sumti_6 0 97 (KOhA 20 \"ko\"))\n"),
        (28, "(sumti_6 0 97 (KOhA 20 \"ko\"))\n", ""),
      ],
    ),  # `su` erases text before it, word stream refuses too, so NIF cuts back to directives
    (
      pieces: @["mi cusku lu do klama .i mi cadzu ", "li'u .i ko "],
      changes: @[
        (
          28, "(sentence 0 40 (sumti_6 80 97 (KOhA 0 \"mi\")) (bridi_tail_3 50 53 " &
            "(tanru_unit_2 130 152 (BRIVLA 3 \"cusku\")) (sumti_6 71 97 (LU 9 \"lu\") " &
            "(sentence 0 40 (sumti_6 80 97 (KOhA 12 \"do\")) (bridi_tail_3 50 53 " &
            "(tanru_unit_2 130 152 (BRIVLA 15 \"klama\")) (tail_terms 71))))))\n",
          "(text_1 0 2 (I 22 \"i\") (sentence 4 40 (sumti_6 80 97 (KOhA 24 \"mi\")) " &
            "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 27 \"cadzu\")) " &
            "(tail_terms 71))))\n",
        ),
        (
          28, "(sentence 0 40 (sumti_6 80 97 (KOhA 0 \"mi\")) (bridi_tail_3 50 53 " &
            "(tanru_unit_2 130 152 (BRIVLA 3 \"cusku\")) (sumti_6 71 97 (LU 9 \"lu\") " &
            "(paragraph 0 10 (sentence 11 40 (sumti_6 80 97 (KOhA 12 \"do\")) (bridi_tail_3 50 " &
            "53 (tanru_unit_2 130 152 (BRIVLA 15 \"klama\")) (tail_terms 71))) (I 22 \"i\") " &
            "(sentence 11 40 (sumti_6 80 97 (KOhA 24 \"mi\")) (bridi_tail_3 50 53 " &
            "(tanru_unit_2 130 152 (BRIVLA 27 \"cadzu\")) (tail_terms 71)))) " &
            "(LIhU 33 \"lihu\"))))\n",
          "(text_1 0 2 (I 39 \"i\") (sumti_6 4 97 (KOhA 41 \"ko\")))\n",
        ),
        (466, "(text_1 0 2 (I 39 \"i\") (sumti_6 4 97 (KOhA 41 \"ko\")))\n", ""),
      ],
    ),  # `lu` waits, so sentences after it go out; `li'u` reads them again as quotation
    (
      pieces: @["mi su", "'i do "],
      changes: @[
        (28, "", "(sumti_6 0 97 (KOhA 0 \"mi\"))\n"), (28, "", LINE_SUHI), (28, LINE_SUHI, ""),
      ],
    ),  # `su` that piece cuts is `su'i` once next piece ends it, so erases nothing
    (
      pieces: @["mi klama .i ", "zei broda "],
      changes: @[
        (28, LINE_MI_KLAMA, "(text_1 0 2 (I 10 \"i\"))\n"), (28, "", LINE_ZEI), (28, LINE_ZEI, ""),
      ],
    ),  # `zei` joins `.i` to word after it, so `.i` opens no sentence, and NIF cuts back (4.6)
  ]
    ## Pieces of text, and change NIF gives for each, then for end, byte for byte.



#[ Readers ]#

func readLive(text: string, cuts: openArray[int], is_growing = false): ReadingLive =
  ## Read text piece by piece, cut at each byte of `cuts`, and hold NIF each change leaves.
  ##   With `is_growing`, test NIF and tail of each change before end against text so far.
  var
    reader = initReaderLive()
    last = 0
  result = ReadingLive(nif: HEADER, is_held: true, is_grown: true)
  template apply(change: ChangeNif) =
    ## Cut NIF held back as change gives, then add its nodes, and keep change.
    result.is_held = result.is_held and change.at <= result.nif.len
    result.nif.setLen(min(change.at, result.nif.len))
    result.nif.add change.text
    result.is_held = result.is_held and result.nif == reader.toNif
    result.changes.add (change.at, change.text, change.tail)
  for k in 0 .. cuts.len:
    let
      at = (if k < cuts.len: cuts[k] else: text.len)
      change = reader.push(text[last ..< at])
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


func textBuilt(rng: var Rand): string =
  ## Build text of words that reach back, at random.
  var words: seq[string]
  for k in 0 ..< rng.rand(1 .. WORDS_BUILT_MOST): words.add WORDS_BUILT[rng.rand(WORDS_BUILT.high)]
  words.join(" ")


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


  test "Lo'u whose le'u erasure erases waits for none, so text after it reads as stream reads it":
    for text in TEXTS_LOHU_ERASED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # header of `live.nim`, law
      check live.is_grown  # header of `prose.nim`, stream reads `le'u` erasure erases (19.9)


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
