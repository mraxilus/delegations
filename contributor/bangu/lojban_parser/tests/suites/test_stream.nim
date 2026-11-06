## Replicate stream reading of CLL chapters 3 and 4 against `stream.nim`; hold laws CLL implies.
##   Examples are copied from CLL text, never from library output; text no source holds is marked
##     constructed.
##   Laws run over seeded random streams of gismu, cmavo and lujvo, each drawn from every word of
##     its list or from lujvo `$` renders, and over positions of each word exhaustively
##     (Article IX.3). References restate each rule as CLL states it, apart from reader.
##   Corpus does not cover yet: random streams holding cmene or fu'ivla, which suite holds by
##     examples of CLL alone, and quotation, gap of #814.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, tables, unittest]

import ../../src/lojban_parser/[dictionary, forms, selmaho, stream, tanru]
import ../../src/lojban_parser/lists/[cmavo, gismu]


const
  SAMPLES = 1000  ## Random streams laws draw, seeded; also random lujvo pool draws.
  COUNT_WORDS_MAX = 8  ## Most words of random stream.
  FLOOR_COMMA_READ = 11000
    ## Least commas comma law reads as syllable breaks: 11592 read over both lists and lujvo
    ##   drawn at seed `1`.
  FLOOR_COMMA_REFUSED = 4000
    ## Least commas comma law reads as refused: 4224 read over same words.
  FLOOR_STRESS_REFUSED = 3500
    ## Least capitals off penultimate syllable of brivla that reader refuses, rather than
    ##   reading other words: 3728 read over gismu list and lujvo drawn at seed `1`.
  SAMPLES_JOINED = 4000
    ## Random runs of two or three words written together, seeded; runs needing pause between
    ##   words left out, since text written together writes none.
  FLOOR_JOINED = 2200  ## Least runs read back as same words: 2411 read at seed `2`.
  FLOOR_TIED = 900
    ## Least runs refused as tie that names them: 1025 read at seed `2`; 432 of them hold
    ##   fu'ivla in one split, and others split cmavo and gismu two ways, as `mibroda` does.
  COUNT_COMMA_MARKED = 371
    ## Commas law of marked words reads: each place in each word of `WORDS_BORROWED` and
    ##   `WORDS_NAMED`, with capital on each vowel or none, where text without comma reads.
  FLOOR_COMMA_KEPT = 280  ## Least of them that still read: 294 read, 5 where pause stands.
  FLOOR_GLIDE_READ = 40
    ## Least capitals law of on-glide reads as one brivla: 40 read, on penultimate syllable of
    ##   each on-glide in four frames of two syllables or three.
  FLOOR_STRESS_OTHER = 600
    ## Least capitals off penultimate syllable of brivla read as other words: 630 read, as
    ##   `djAcadyfanta` reads `djaca dy fanta`.
  FLOOR_STRESS = 800
    ## Least pauses stress law infers after stressed last syllable, which no other rule needs:
    ##   850 read at seed `0`.
  VOWELS_SYLLABLE = "aeiouy"  ## Letters making syllable: vowels of 3.1, and `y` (3.4, 3.9).
  CONSONANTS_SYLLABIC = "lmnr"  ## Consonants that may make syllable alone (3.4).
  DIPHTHONGS_OFF = ["ai", "ei", "oi", "au"]  ## Diphthongs with off-glide, in every word (3.4).
  DIPHTHONGS_ON = ["ia", "ie", "ii", "io", "iu", "ua", "ue", "ui", "uo", "uu"]
    ## Diphthongs with on-glide, first in words standing alone, and in names and borrowings
    ##   (3.4, 4.2).
  DIPHTHONGS_NAME = ["iy", "uy"]  ## Diphthongs 3.4 keeps to names.
  KINDS_BRIVLA = {Kind.Gismu, Kind.Lujvo, Kind.Fuhivla}  ## Classes of brivla (4.3).
  WORDS_BORROWED = [
    "spageti", "kuarka", "integrale", "saskrkuarka", "bangrkorea", "zgiee", "crarciae",
    "gackioto",
  ]
    ## Fu'ivla commas and capitals mark: Examples 4.46, 4.50, 4.56, prefix method of 4.7, and
    ##   three that review of #811 found, whose vowels side by side comma may part; constructed.
  WORDS_NAMED = ["djim", "katrinas", "uiliam", "xuakin", "meiris", "vauensas"]
    ## Cmene commas and capitals mark: Examples 4.57, 4.61, and Lojbanized names of 4.8.
  FRAMES_NAME = ["k_n", "dj_m", "m_tan", "s_lis"]
    ## Letters of cmene around diphthong `_` of name, which make one syllable or two; constructed.
  FRAMES_GLIDE = ["br_", "kobr_", "spag_", "br_na", "kobr_na"]
    ## Letters around on-glide `_`, which make one syllable, two, or three; constructed.
  COUNT_GLIDE_CAPITALS = 100  ## Syllables of each on-glide in each frame: 10 times 1+2+2+2+3.



#[ Readers ]#

func wordsRead(text: string): Option[seq[string]] =
  ## Read stream, and list letters of each word in order; none where stream is refused.
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.text)) else: none(seq[string])


func pausesRead(text: string): Option[seq[Pause]] =
  ## Read stream, and list pause before each word; none where stream is refused.
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.pause)) else: none(seq[Pause])


func stressesRead(text: string): Option[seq[Option[int]]] =
  ## Read stream, and list nucleus capitals stress in each word; none where stream is refused.
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.stress)) else: none(seq[Option[int]])


func startsRead(text: string): Option[seq[int]] =
  ## Read stream, and list byte where each word opens; none where stream is refused.
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.start)) else: none(seq[int])


func selmahoRead(text: string): Option[seq[Option[Selmaho]]] =
  ## Read stream, and list selma'o of each word; none where stream is refused.
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.reading.selmaho))
  else: none(seq[Option[Selmaho]])


func refusalRead(text: string): Option[(Refusal, int)] =
  ## Read stream, and give rule refusing it with byte it names; none where stream reads.
  let reading = text.readStream
  if reading.is_read: none((Refusal, int)) else: some((reading.refusal, reading.start))



#[ References ]#

func isLetteralConsonant(text: string): bool =
  ## Test word is letteral of consonant, `Cy` (4.2, 17.2).
  text.len == 2 and text[1] == 'y' and text[0] notin VOWELS_SYLLABLE & "'"


func pausesNeeded(words: openArray[string]): seq[Pause] =
  ## List pause before each word of stream written with spaces and no capital, by rules as
  ##   CLL states them: word opening with vowel or `y` (4.9 rule 3, 4.2), word after `y` (4.2),
  ##   and word not `Cy` after `Cy` (4.9 rule 6).
  for i, word in words:
    let is_needed =
      word[0] in VOWELS_SYLLABLE or (i > 0 and words[i - 1] == "y") or
      (i > 0 and words[i - 1].isLetteralConsonant and not word.isLetteralConsonant)
    result.add(if is_needed: Pause.Inferred else: Pause.Absent)


func isCommaAdmitted(word: string, at: int): bool =
  ## Test comma before letter `at` of word breaks syllables, as 3.3 and 3.4 state: stretch on
  ##   each side, up to apostrophe or edge, holds vowel, `y`, or consonant that may be syllabic;
  ##   and comma splits no two vowels, which make diphthong in gismu, lujvo and cmavo.
  let
    before = word[0 ..< at].rsplit('\'', maxsplit = 1)[^1]
    after = word[at .. ^1].split('\'', maxsplit = 1)[0]
    letters_syllabic = VOWELS_SYLLABLE & CONSONANTS_SYLLABIC
  before.anyIt(it in letters_syllabic) and after.anyIt(it in letters_syllabic) and
      not (word[at - 1] in VOWELS_SYLLABLE and word[at] in VOWELS_SYLLABLE)


func syllables(word: string, is_borrowing = false, is_name = false): seq[Slice[int]] =
  ## List vowels of each syllable of word, as 3.4 groups them from left (3.5): diphthong with
  ##   off-glide is one syllable, and with on-glide where word opens with it, or anywhere in
  ##   borrowing or name; `iy` and `uy` in name alone; each other vowel is one.
  var at = 0
  while at < word.len:
    if word[at] notin VOWELS_SYLLABLE:
      inc at
      continue
    let
      pair = word[at .. min(at + 1, word.high)]
      is_glide =
        (pair in DIPHTHONGS_ON and (at == 0 or is_borrowing or is_name)) or
        (pair in DIPHTHONGS_NAME and is_name)
      size = (if pair in DIPHTHONGS_OFF or is_glide: 2 else: 1)
    result.add at .. at + size - 1
    at += size


func penultimate(word: string, is_borrowing: bool): int =
  ## Index syllable brivla stresses among syllables of word: penultimate, `y` not counted (3.9).
  let spans = word.syllables(is_borrowing = is_borrowing)
  toSeq(0 .. spans.high).filterIt(word[spans[it].a] != 'y')[^2]


func capitalized(word: string, span: Slice[int]): string =
  ## Write word with letters of `span` capital, as 3.9 marks stressed syllable by its vowel.
  result = word
  for i in span: result[i] = result[i].toUpperAscii



#[ Corpus ]#

let
  INDEXES_GISMU = block:
    ## Every gismu of list, by index; cmavo carrying rafsi left out.
    var indexes: seq[Word]
    for i, entry in LIST_GISMU:
      if entry.word.isGismu: indexes.add Word(i)
    indexes
  WORDS_GISMU = INDEXES_GISMU.mapIt(it.entry.word)  ## Every gismu of list.
  WORDS_CMAVO = block:
    ## Every cmavo of cmavo list but `ZOI`, whose quotation is gap of #814.
    var words: seq[string]
    for entry in LIST_CMAVO:
      if entry.selmaho != Selmaho.Zoi: words.add entry.word
    words
  LUT_SELMAHO_BY_CMAVO = block:
    ## Selma'o cmavo list gives each cmavo, read from list apart from reader (chapter 20).
    var lut: Table[string, Selmaho]
    for entry in LIST_CMAVO: lut[entry.word] = entry.selmaho
    lut


proc drawLujvo(): seq[string] =
  ## Draw `SAMPLES` lujvo, seeded: form `$` renders for tanru of two or three gismu of list.
  randomize(1)
  for _ in 1 .. SAMPLES:
    result.add $Tanru(parts: newSeqWith(rand(2 .. 3), INDEXES_GISMU.sample.toPart))


let
  WORDS_LUJVO = drawLujvo()  ## Random lujvo laws read, drawn once.
  LUT_KIND_BY_WORD = block:
    ## Class of each word of every pool, as pool it comes from gives it: list or `$` (4.2-6).
    var lut: Table[string, Kind]
    for word in WORDS_GISMU: lut[word] = Kind.Gismu
    for word in WORDS_CMAVO: lut[word] = Kind.Cmavo
    for word in WORDS_LUJVO: lut[word] = Kind.Lujvo
    lut


proc drawStreams(): seq[seq[string]] =
  ## Draw `SAMPLES` streams of one to `COUNT_WORDS_MAX` words, seeded, each word gismu, cmavo
  ##   or lujvo one time in three, from every word of its pool.
  randomize(0)
  for _ in 1 .. SAMPLES:
    var words: seq[string]
    for _ in 1 .. rand(1 .. COUNT_WORDS_MAX):
      words.add:
        case rand(2)
        of 0: WORDS_GISMU.sample
        of 1: WORDS_CMAVO.sample
        else: WORDS_LUJVO.sample
    result.add words


let STREAMS_RANDOM = drawStreams()  ## Random streams every law reads, drawn once.


iterator wordsEach(): string =
  ## Serve every gismu and cmavo of lists, then each random lujvo.
  for word in WORDS_GISMU: yield word
  for word in WORDS_CMAVO: yield word
  for word in WORDS_LUJVO: yield word



suite "Chapter 3":
  test "Section 3.1":
    for c in "aeiou":
      check ($c.toUpperAscii).stressesRead == some(@[some(0)])  # 3.1, capital marks stress
    for c in tanru.LETTERS - {'\''} - {'a', 'e', 'i', 'o', 'u', 'y'}:  # each consonant
      check (c.toUpperAscii & "a").refusalRead == some((Refusal.Stress, 0))  # 3.9, vowel at least
    for c in ['H', 'Q', 'W']:
      check (c & "a").refusalRead == some((Refusal.Letter, 0))  # 3.1, omitting "h", "q", and "w"
    for c in char.low .. char.high:  # 256 bytes, exhaustive
      if c in tanru.LETTERS or c in MARKS_STREAM: continue
      check ("mi " & c & "a").refusalRead == some((Refusal.Letter, 3))  # 3.1, alphabet
    check "Mi klama".refusalRead == some((Refusal.Stress, 0))  # 3.1, capital for stress alone


  test "Section 3.3":
    check ".i.ai.i.ai.o".wordsRead == some(@["i", "ai", "i", "ai", "o"])  # 3.3, Example 3.1
    check ".i.ai.i.ai.o".pausesRead == some(Pause.Written.repeat(5))  # 3.3, periods embedded
    check "mi.klama".wordsRead == some(@["mi", "klama"])  # 3.3, no space where period; constructed
    check "bri.vla".refusalRead == some((Refusal.Shape, 0))  # 3.3, not one word but two
    check "mi klama i do klama".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred, Pause.Absent, Pause.Absent])
          # 3.3, missing period inferred; constructed
    check ".i,ai,i,ai,on.".wordsRead == some(@["iaiiaion"])  # 3.3, Example 3.2, one cmene
    check ".i'ai'i'ai'on.".wordsRead == some(@["i'ai'i'ai'on"])  # 3.3, Example 3.4, one cmene
    check ",klama".refusalRead == some((Refusal.Comma, 0))  # 3.3, comma within word; constructed
    check "kla,,ma".refusalRead == some((Refusal.Comma, 3))  # 3.3, comma separates syllables
    check "crarcIae".wordsRead == some(@["crarciae"])  # 3.9, `ia` penultimate; constructed
    check "crarcI,ae".refusalRead ==
        some((Refusal.Comma, 6))  # 3.3, comma changes no word, and parts stress off; review of #811


  test "Section 3.4":
    check "ka,i".refusalRead == some((Refusal.Comma, 2))  # 3.4, diphthong one syllable; constructed
    check "sai,r,goi".wordsRead == some(@["sairgoi"])  # 3.4, syllabic "r"; Example 3.21
    check "b,ridi".refusalRead == some((Refusal.Comma, 1))  # 3.4, "b" no syllable; constructed
    check "sai,R,goi".refusalRead == some((Refusal.Stress, 4))  # 3.4, syllabic never stressed
    check "brUa".refusalRead ==
        some((Refusal.Shape, 0))  # 3.4, diphthong one syllable, so no brivla (4.3); review of #811
    check "kUYn.".stressesRead == some(@[some(0)])  # 3.4, `uy` one syllable of name; review of #811


  test "Section 3.5":
    for text in ["meiin.", "mei,in.", "me,iin."]:
      check text.wordsRead == some(@["meiin"])  # 3.5, Examples 3.6-7, comma makes no other word
    check ".nu,IOrk.".stressesRead == some(@[some(1)])  # 3.5, comma parts `u` from `io`; Tatoeba


  test "Section 3.9":
    check "pu,je,nai,ca,je,ba".wordsRead == some(@["pu", "je", "nai", "ca", "je", "ba"])  # 9.1
    check "pujenaicajeba".wordsRead == "pu,je,nai,ca,je,ba".wordsRead  # 9.1; comma not required
    for (text, word) in [
      ("nin,mu", "ninmu"), ("fit,pri", "fitpri"), ("sair,goi", "sairgoi"),
      ("sai,r,goi", "sairgoi"), ("klez,ba", "klezba"), ("kle,zba", "klezba"),
    ]:
      check text.wordsRead == some(@[word])  # 3.9, Examples 3.19-22
    for (text, word, nucleus) in [
      ("DI,ky,jvo", "dikyjvo", 0), ("BI,sy,dja", "bisydja", 0), ("BI,syd,ja", "bisydja", 0),
      ("da'UD,ja", "da'udja", 1), ("da'U,dja", "da'udja", 1),
    ]:
      check text.wordsRead == some(@[word])  # 3.9, Examples 3.23, 3.28-29
      check text.stressesRead == some(@[some(nucleus)])  # 3.9, penultimate, `y` not counted
    for text in ["e'u bridi", "e'u BRI,di", "E'u BRI,di"]:
      check text.pausesRead == some(@[Pause.Inferred, Pause.Absent])  # 3.9, Example 3.30
    check "e'U.BRI,di".pausesRead == some(@[Pause.Inferred, Pause.Written])  # 3.9, Example 3.30
    check "e'U.BRI,di".stressesRead == some(@[some(1), some(0)])  # 3.9, Example 3.30
    check "e'U BRI,di".pausesRead ==
        some(@[Pause.Inferred, Pause.Inferred])  # 3.9, Example 3.30; period inferred (3.3)
    check "le re NObli PREnu".stressesRead ==
        some(@[none(int), none(int), some(0), some(0)])  # 3.9, Example 3.31
    check "le re no bliPREnu".wordsRead == some(@["le", "re", "no", "bliprenu"])  # 9.15
    check "le re no bliPREnu".stressesRead ==
        some(@[none(int), none(int), none(int), some(1)])  # 3.9, Example 3.32
    check "briDI".refusalRead == some((Refusal.Stress, 3))  # 3.9, penultimate; constructed
    check "dikYjvo".refusalRead == some((Refusal.Stress, 3))  # 3.9, "y" never stressed
    check "BrIdi".refusalRead == some((Refusal.Stress, 0))  # 3.9, one syllable; constructed
    check ".ARM,strong.".wordsRead == some(@["armstrong"])  # 3.9, Example 3.24
    check ".ARM,strong.".stressesRead == some(@[some(0)])  # 3.9, Example 3.24, first syllable



suite "Chapter 4":
  test "Section 4.2":
    check ".iseci'i".wordsRead == some(@["i", "se", "ci'i"])  # 4.2, Example 4.1
    check ".iseci'i".pausesRead ==
        some(@[Pause.Written, Pause.Absent, Pause.Absent])  # 4.2, Example 4.1
    check ".iseci'i".selmahoRead ==
        some(@[some(Selmaho.I), some(Selmaho.Se), some(Selmaho.Pa)])  # 20, each cmavo
    check "punaijecanai".wordsRead == some(@["pu", "nai", "je", "ca", "nai"])  # 4.2, Example 4.2
    check "ki'e.u'e".wordsRead == some(@["ki'e", "u'e"])  # 4.2, Example 4.3
    check "ki'e.u'e".pausesRead == some(@[Pause.Absent, Pause.Written])  # 4.2, pause kept
    check "ki'e'u'e".wordsRead == some(@["ki'e'u'e"])  # 4.2, Example 4.4, experimental
    check "cy.ibu.abu".wordsRead == some(@["cy", "i", "bu", "a", "bu"])  # 4.2, Example 4.5
    check "cy.ibu.abu".pausesRead == some(@[
      Pause.Absent, Pause.Written, Pause.Absent, Pause.Written, Pause.Absent,
    ])  # 4.2, Example 4.5, pauses required
    check ".e'o ko ko kurji".wordsRead == some(@["e'o", "ko", "ko", "kurji"])  # 4.2, Example 4.6
    check ".E'o ko ko KURji".stressesRead ==
        some(@[some(0), none(int), none(int), some(0)])  # 4.2, Example 4.6
    check "le re nanmu".wordsRead == some(@["le", "re", "nanmu"])  # 4.2, Example 4.7
    check "le RE. NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Written])  # 4.2, Example 4.8
    check "le RE NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred])  # 4.2, stress demands pause (3.3)
    check "le RE LE nanmu".pausesRead == some(@[
      Pause.Absent, Pause.Absent, Pause.Inferred, Pause.Inferred,
    ])  # 4.2, stressed syllables meet; 4.9 rule 5; constructed
    check "LE re NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Absent])  # 4.2, Example 4.9
    check "le re NANmu".stressesRead ==
        some(@[none(int), none(int), some(0)])  # 4.2, Example 4.10
    check "mi .y. klama".pausesRead ==
        some(@[Pause.Absent, Pause.Written, Pause.Written])  # 4.2, ".y." pauses before and after
    check "mi y klama".pausesRead ==
        some(@[Pause.Absent, Pause.Inferred, Pause.Inferred])  # 4.2, inferred (3.3); constructed


  test "Section 4.8":
    for (text, words) in [
      ("djim.", @["djim"]), ("djein.", @["djein"]), (".arnold.", @["arnold"]),
      ("pit.", @["pit"]), ("katrinas.", @["katrinas"]), ("kat,r,in.", @["katrin"]),
      ("katis.", @["katis"]), ("keit.", @["keit"]), ("djan. braun.", @["djan", "braun"]),
      ("djanbraun.", @["djanbraun"]), ("pav.", @["pav"]), ("sol.", @["sol"]),
      ("ralj.", @["ralj"]), ("nol.", @["nol"]),
    ]:
      check text.wordsRead == some(words)  # 4.8, Examples 4.57-70
    check "laplas.".wordsRead == some(@["la", "plas"])  # 4.8, "look like Lojban words la plas."
    check "ilanas.".wordsRead == some(@["i", "la", "nas"])  # 4.8, "misunderstood as .i la nas."
    check "NEderlants.".stressesRead == some(@[some(0)])  # 4.8, "cannot be misheard"
    check ".eLIS.".stressesRead == some(@[some(1)])  # 4.8, table of names, "Elise"
    check "lex. va,uensas.".wordsRead == some(@["lex", "vauensas"])  # 4.8, "Lech Walesa"
    check "me la spagetis.".wordsRead == some(@["me", "la", "spagetis"])  # 4.7, Example 4.45


  test "Section 4.9":
    check "bri.vla".refusalRead == some((Refusal.Shape, 0))  # rule 1, pause breaks up word
    check ".i mi klama".pausesRead ==
        some(@[Pause.Written, Pause.Absent, Pause.Absent])  # rule 3; constructed
    check "cy klama".pausesRead == some(@[Pause.Absent, Pause.Inferred])  # rule 6; constructed
    check "cy ky klama".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred])  # rule 6, "Cy" follows; constructed
    check "la djan cu klama".pausesRead == some(@[
      Pause.Absent, Pause.Absent, Pause.Inferred, Pause.Absent,
    ])  # rules 2 and 4, after `la` no pause; constructed
    check "mi djan".pausesRead == some(@[Pause.Absent, Pause.Inferred])  # rule 4; constructed
    check "doi djan".pausesRead == some(@[Pause.Absent, Pause.Absent])  # rule 4, `doi`
    check "zoi gy. John .gy.".refusalRead == some((Refusal.Foreign, 0))  # rule 7; gap #814
    check "zo zoi".refusalRead == some((Refusal.Foreign, 3))  # rule 7; `zo` gap #814 reads
    check "mi zoi".refusalRead == some((Refusal.Foreign, 3))  # rule 7, no quotation; gap holds
    check "mi cusku la'o gy. Mary .gy.".refusalRead ==
        some((Refusal.Foreign, 9))  # rule 7, gap #814; constructed



suite "Internal: Stream":
  test "Words joined by spaces read as readWord reads each, at byte where each opens":
    var count = 0
    for words in STREAMS_RANDOM:
      let text = words.join(" ")
      check text.wordsRead == some(words)  # 3.3, space divides words; round trip
      var
        starts: seq[int]
        at = 0
      for word in words:
        starts.add at
        at += word.len + 1
      check text.startsRead == some(starts)  # 3.3, byte where each word opens
      let reading = text.readStream
      if not reading.is_read: continue
      for i, occurrence in reading.occurrences:
        check occurrence.reading.kind == LUT_KIND_BY_WORD[words[i]]  # 4.2-6, class of pool
        if occurrence.reading.kind != Kind.Cmavo: continue
        check occurrence.reading.selmaho ==
            some(LUT_SELMAHO_BY_CMAVO[words[i]])  # 20, selma'o cmavo list gives
      inc count
    check count == SAMPLES  # IX.3, guard keeps every stream


  test "Period between words reads as space, and writes pause before each":
    var count = 0
    for words in STREAMS_RANDOM:
      for joint in [".", " .", ". ", " . "]:
        let text = words.join(joint)
        check text.wordsRead == some(words)  # 3.3, no space needed where period stands
        let pauses = text.pausesRead
        if pauses.isNone: continue
        check pauses.get[1 .. ^1].allIt(it == Pause.Written)  # 3.3, period writes pause
        inc count
    check count == 4 * SAMPLES  # IX.3, guard keeps every stream of each joint


  test "Pause is inferred where rule of 4.9 needs one, and absent elsewhere":
    for words in STREAMS_RANDOM:
      check words.join(" ").pausesRead == some(words.pausesNeeded)  # 4.9 rules 3, 6; 4.2


  test "Stressed last syllable takes pause before brivla, or before stressed first syllable":
    var count = 0
    for words in STREAMS_RANDOM:
      var
        written: seq[string]
        is_stressed_last: seq[bool]
      for word in words:
        let is_marked =
          LUT_KIND_BY_WORD[word] == Kind.Cmavo and word[word.syllables[^1].a] != 'y'
        written.add(if is_marked: word.capitalized(word.syllables[^1]) else: word)
        is_stressed_last.add is_marked
      var pauses = words.pausesNeeded
      for i in 1 .. words.high:
        let
          is_brivla = LUT_KIND_BY_WORD[words[i]] in {Kind.Gismu, Kind.Lujvo}
          is_stressed_first = is_stressed_last[i] and words[i].syllables.len == 1
        if not is_stressed_last[i - 1] or not (is_brivla or is_stressed_first): continue
        if pauses[i] == Pause.Absent: inc count
        pauses[i] = Pause.Inferred
      check written.join(" ").pausesRead == some(pauses)  # 4.9 rule 5; 4.2, stresses meet
    check count >= FLOOR_STRESS  # IX.3, guard keeps rule in play


  test "Comma breaking syllables changes no word, and other comma is refused at its byte":
    var count_read, count_refused = 0
    for word in wordsEach():
      for at in 1 ..< word.len:
        let text = word[0 ..< at] & "," & word[at .. ^1]
        if word.isCommaAdmitted(at):
          check text.wordsRead == some(@[word])  # 3.3, no two words differ by comma alone
          inc count_read
        else:
          check text.refusalRead == some((Refusal.Comma, at))  # 3.3, 3.4
          inc count_refused
    check count_read >= FLOOR_COMMA_READ  # IX.3, guard keeps most draws
    check count_refused >= FLOOR_COMMA_REFUSED  # IX.3, guard keeps refusals in play


  test "Comma changes no word text without it reads, but where those words need pause":
    var count, count_kept = 0
    for word in @WORDS_BORROWED & @WORDS_NAMED:
      for c in -1 .. word.high:
        if c >= 0 and word[c] notin VOWELS_SYLLABLE: continue
        let
          marked = (if c < 0: word else: word.capitalized(c .. c))
          bare = marked.readStream
        if not bare.is_read: continue
        var
          pauses: seq[int]  # letter before which words read without comma take pause
          lo = 0
        for occurrence in bare.occurrences:
          if lo > 0 and occurrence.pause != Pause.Absent: pauses.add lo
          lo += occurrence.text.len
        let texts = some(bare.occurrences.mapIt(it.text))
        for at in 1 ..< word.len:
          if '\'' in [word[at - 1], word[at]]: continue
          let words = (marked[0 ..< at] & "," & marked[at .. ^1]).wordsRead
          if at in pauses: check words != texts  # 3.3, comma marks "no pause between" syllables
          else: check words.isNone or words == texts  # 3.3, never "differ solely because of" comma
          inc count
          if words.isSome: inc count_kept
    check count == COUNT_COMMA_MARKED  # IX.3, guard keeps each comma of each marked word
    check count_kept >= FLOOR_COMMA_KEPT  # IX.3, guard keeps commas that read in play


  test "Capital on penultimate syllable of brivla reads, and on any other never reads as it":
    var count_read, count_refused, count_other = 0
    for word in concat(WORDS_GISMU, WORDS_LUJVO):  # every gismu, and each random lujvo
      let
        spans = word.syllables
        counted = toSeq(0 .. spans.high).filterIt(word[spans[it].a] != 'y')
      for k, span in spans:
        let text = word.capitalized(span)
        if k == counted[^2]:
          check text.stressesRead == some(@[some(k)])  # 3.9, penultimate, `y` not counted
          inc count_read
          continue
        let reading = text.readStream
        if not reading.is_read:
          check (reading.refusal == Refusal.Stress and reading.start == span.a) or
              reading.refusal == Refusal.Split  # 3.9, at capital; 4.1, or tie of other words
          inc count_refused
          continue
        let texts = reading.occurrences.mapIt(it.text)
        check texts != @[word]  # 3.9, false primary stress, "errors in word resolution"
        check texts.join("") == word  # 4.1, other words split letters of word
        for occurrence in reading.occurrences:
          if occurrence.stress.isNone or occurrence.reading.kind notin KINDS_BRIVLA: continue
          let is_borrowing = occurrence.reading.kind == Kind.Fuhivla
          check occurrence.stress ==
              some(occurrence.text.penultimate(is_borrowing))  # 3.9, capital fits brivla read
        inc count_other
    check count_read == WORDS_GISMU.len + WORDS_LUJVO.len  # IX.3, one stress reads in each
    check count_refused >= FLOOR_STRESS_REFUSED  # IX.3, guard keeps refusals in play
    check count_other >= FLOOR_STRESS_OTHER  # IX.3, guard keeps other words in play


  test "Capital on syllable of word holding on-glide reads one brivla on penultimate alone":
    var count, count_read = 0
    for pair in DIPHTHONGS_ON:
      for frame in FRAMES_GLIDE:
        let
          word = frame.replace("_", pair)
          spans = word.syllables(is_borrowing = true)
        for k, span in spans:
          let reading = word.capitalized(span).readStream
          inc count
          if not reading.is_read or reading.occurrences.len != 1: continue
          if reading.occurrences[0].reading.kind notin KINDS_BRIVLA: continue
          check k == spans.len - 2  # 3.4, diphthong one syllable; 3.9, penultimate
          inc count_read
    check count == COUNT_GLIDE_CAPITALS  # IX.3, guard keeps each syllable of each frame
    check count_read >= FLOOR_GLIDE_READ  # IX.3, guard keeps brivla in play


  test "Capital on each syllable of cmene holding iy or uy stresses that syllable":
    var count = 0
    for pair in DIPHTHONGS_NAME:
      for frame in FRAMES_NAME:
        let word = frame.replace("_", pair)
        for k, span in word.syllables(is_name = true):
          check word.capitalized(span).stressesRead == some(@[some(k)])  # 3.4; 3.9, any syllable
          inc count
    check count == 12  # IX.3, guard keeps each syllable of each frame: 2 times 1+1+2+2


  test "Capital on any vowel of cmavo stresses that syllable, and capital on y is refused":
    for word in WORDS_CMAVO:
      for k, span in word.syllables:
        let text = word.capitalized(span)
        if word[span.a] == 'y':
          check text.refusalRead == some((Refusal.Stress, span.a))  # 3.9, "y" never stressed
        else:
          check text.stressesRead == some(@[some(k)])  # 3.9, cmavo any syllable


  test "Words needing no pause, written together, read back as them, as one word, or as tie":
    var count_joined, count_tied = 0
    randomize(2)
    for _ in 1 .. SAMPLES_JOINED:
      var words: seq[string]
      for i in 1 .. rand(2 .. 3):
        words.add(if i == 1 or rand(1) == 0: WORDS_CMAVO.sample else: WORDS_GISMU.sample)
      if words.pausesNeeded[1 .. ^1].anyIt(it != Pause.Absent): continue
      let
        text = words.join("")
        reading = text.readStream
      if reading.is_read:
        let
          texts = reading.occurrences.mapIt(it.text)
          is_whole = texts == @[text] and reading.occurrences[0].reading.kind == Kind.Fuhivla
        check texts == words or is_whole  # 4.1, one split; or one fu'ivla, as `klamaku` (4.7)
        if texts == words: inc count_joined
      else:
        check reading.refusal == Refusal.Split  # 3.9, only stress tells them apart
        check words.join(" ") in reading.detail.split(", or ")  # 4.1, tie names them
        inc count_tied
    check count_joined >= FLOOR_JOINED  # IX.3, guard keeps runs that read back
    check count_tied >= FLOOR_TIED  # IX.3, guard keeps ties in play


  test "Stream of marks alone reads as no words":
    for text in ["", " ", ".", " .\t. \n"]:
      check text.wordsRead == some(newSeq[string]())  # 3.3, marks divide words alone


  test "Refusal names byte where offending word opens":
    check "mi klama lonubroda".refusalRead == some((Refusal.Split, 9))  # 3.9; constructed
    check "mi klama ktraile".refusalRead == some((Refusal.Cluster, 9))  # 4.7; constructed
    check "mi klama c".refusalRead == some((Refusal.Shape, 9))  # 3.4, no syllable; constructed


  test "Written word splits where one split needs fewest pauses, and tie is refused as Split":
    check "secusku".wordsRead == some(@["se", "cusku"])  # 4.1, one split; Tatoeba
    check "ki'eu'e".wordsRead == some(@["ki'e", "u'e"])  # 3.3, period of Example 4.3 inferred
    check "ki'eu'e".pausesRead == some(@[Pause.Absent, Pause.Inferred])  # 4.9 rule 3
    check "cia".wordsRead == some(@["ci", "a"])  # 3.3, period inferred; constructed
    check "tosmabru".wordsRead == some(@["to", "smabru"])  # 4.11 step 5, "will break up"
    check "miBROda".wordsRead == some(@["mi", "broda"])  # 3.9, stress places brivla
    check "MIbroda".wordsRead == some(@["mibro", "da"])  # 3.9, stress of gismu `mibro`
    check "KLAmaku".wordsRead == some(@["klama", "ku"])  # 3.9, stress fits `klama` alone
    check "klamaku".wordsRead == some(@["klamaku"])  # 4.7, one fu'ivla; constructed
    check "mibroda".refusalRead == some((Refusal.Split, 0))  # 3.9, stress alone tells them apart
    check "mibroda".readStream.detail == "mibro da, or mi broda"  # 3.9, two splits named
    check "iai".refusalRead == some((Refusal.Split, 0))  # 4.9 rule 3, `.i.ai` or `.ia.i`
    check "ka,i".refusalRead == some((Refusal.Comma, 2))  # 3.3, comma is no pause; constructed
