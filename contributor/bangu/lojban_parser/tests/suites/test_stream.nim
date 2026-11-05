## Replicate stream reading of CLL chapters 3 and 4 against `stream.nim`; hold laws CLL implies.
##   Examples are copied from CLL text, never from library output; text no source holds is marked
##     constructed.
##   Laws run over seeded random streams of gismu, cmavo and lujvo, each drawn from every word of
##     its list or from lujvo `$` renders, and over positions of each word exhaustively
##     (Article IX.3). References restate each rule as CLL states it, apart from reader.
##   Corpus does not cover yet: cmene and fu'ivla, gaps of #812, and quotation, gap of #814.

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
  FLOOR_STRESS = 800
    ## Least pauses stress law infers after stressed last syllable, which no other rule needs:
    ##   850 read at seed `0`.
  VOWELS_SYLLABLE = "aeiouy"  ## Letters making syllable: vowels of 3.1, and `y` (3.4, 3.9).
  CONSONANTS_SYLLABIC = "lmnr"  ## Consonants that may make syllable alone (3.4).
  DIPHTHONGS_OFF = ["ai", "ei", "oi", "au"]  ## Diphthongs with off-glide, in every word (3.4).
  DIPHTHONGS_ON = ["ia", "ie", "ii", "io", "iu", "ua", "ue", "ui", "uo", "uu"]
    ## Diphthongs with on-glide, in words standing alone, first (3.4, 4.2).



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


func syllables(word: string): seq[Slice[int]] =
  ## List vowels of each syllable of word, as 3.4 groups them: diphthong with off-glide, or
  ##   with on-glide first in word opening with it, is one syllable; each other vowel is one.
  var at = 0
  while at < word.len:
    if word[at] notin VOWELS_SYLLABLE:
      inc at
      continue
    let
      pair = word[at .. min(at + 1, word.high)]
      size = (if pair in DIPHTHONGS_OFF or (at == 0 and pair in DIPHTHONGS_ON): 2 else: 1)
    result.add at .. at + size - 1
    at += size


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
    check ".i,ai,i,ai,on.".refusalRead == some((Refusal.Cmene, 1))  # 3.3, Example 3.2; gap #812
    check ".i'ai'i'ai'on.".refusalRead == some((Refusal.Cmene, 1))  # 3.3, Example 3.4; gap #812
    check ",klama".refusalRead == some((Refusal.Comma, 0))  # 3.3, comma within word; constructed
    check "kla,,ma".refusalRead == some((Refusal.Comma, 3))  # 3.3, comma separates syllables


  test "Section 3.4":
    check "ka,i".refusalRead == some((Refusal.Comma, 2))  # 3.4, diphthong one syllable; constructed
    check "sai,r,goi".wordsRead == some(@["sairgoi"])  # 3.4, syllabic "r"; Example 9.4
    check "b,ridi".refusalRead == some((Refusal.Comma, 1))  # 3.4, "b" no syllable; constructed
    check "sai,R,goi".refusalRead == some((Refusal.Stress, 4))  # 3.4, syllabic never stressed


  test "Section 3.9":
    check "pu,je,nai,ca,je,ba".wordsRead == some(@["pu", "je", "nai", "ca", "je", "ba"])  # 9.1
    check "pujenaicajeba".wordsRead == "pu,je,nai,ca,je,ba".wordsRead  # 9.1; comma not required
    for (text, word) in [
      ("nin,mu", "ninmu"), ("fit,pri", "fitpri"), ("sair,goi", "sairgoi"),
      ("sai,r,goi", "sairgoi"), ("klez,ba", "klezba"), ("kle,zba", "klezba"),
    ]:
      check text.wordsRead == some(@[word])  # 3.9, Examples 9.2-5
    for (text, word, nucleus) in [
      ("DI,ky,jvo", "dikyjvo", 0), ("BI,sy,dja", "bisydja", 0), ("BI,syd,ja", "bisydja", 0),
      ("da'UD,ja", "da'udja", 1), ("da'U,dja", "da'udja", 1),
    ]:
      check text.wordsRead == some(@[word])  # 3.9, Examples 9.6, 9.11-12
      check text.stressesRead == some(@[some(nucleus)])  # 3.9, penultimate, `y` not counted
    for text in ["e'u bridi", "e'u BRI,di", "E'u BRI,di"]:
      check text.pausesRead == some(@[Pause.Inferred, Pause.Absent])  # 3.9, Example 9.13
    check "e'U.BRI,di".pausesRead == some(@[Pause.Inferred, Pause.Written])  # 3.9, Example 9.13
    check "e'U.BRI,di".stressesRead == some(@[some(1), some(0)])  # 3.9, Example 9.13
    check "e'U BRI,di".pausesRead ==
        some(@[Pause.Inferred, Pause.Inferred])  # 3.9, Example 9.13; period inferred (3.3)
    check "le re NObli PREnu".stressesRead ==
        some(@[none(int), none(int), some(0), some(0)])  # 3.9, Example 9.14
    check "le re no bliPREnu".wordsRead == some(@["le", "re", "no", "bliprenu"])  # 9.15
    check "le re no bliPREnu".stressesRead ==
        some(@[none(int), none(int), none(int), some(1)])  # 3.9, Example 9.15
    check "briDI".refusalRead == some((Refusal.Stress, 3))  # 3.9, penultimate; constructed
    check "dikYjvo".refusalRead == some((Refusal.Stress, 3))  # 3.9, "y" never stressed
    check "BrIdi".refusalRead == some((Refusal.Stress, 0))  # 3.9, one syllable; constructed
    check ".ARM,strong.".refusalRead == some((Refusal.Cmene, 1))  # 3.9, Example 9.7; gap #812



suite "Chapter 4":
  test "Section 4.2":
    check ".iseci'i".wordsRead == some(@["i", "se", "ci'i"])  # 4.2, Example 2.1
    check ".iseci'i".pausesRead ==
        some(@[Pause.Written, Pause.Absent, Pause.Absent])  # 4.2, Example 2.1
    check ".iseci'i".selmahoRead ==
        some(@[some(Selmaho.I), some(Selmaho.Se), some(Selmaho.Pa)])  # 20, each cmavo
    check "punaijecanai".wordsRead == some(@["pu", "nai", "je", "ca", "nai"])  # 4.2, Example 2.2
    check "ki'e.u'e".wordsRead == some(@["ki'e", "u'e"])  # 4.2, Example 2.3
    check "ki'e.u'e".pausesRead == some(@[Pause.Absent, Pause.Written])  # 4.2, pause kept
    check "ki'e'u'e".wordsRead == some(@["ki'e'u'e"])  # 4.2, Example 2.4, experimental
    check "cy.ibu.abu".wordsRead == some(@["cy", "i", "bu", "a", "bu"])  # 4.2, Example 2.5
    check "cy.ibu.abu".pausesRead == some(@[
      Pause.Absent, Pause.Written, Pause.Absent, Pause.Written, Pause.Absent,
    ])  # 4.2, Example 2.5, pauses required
    check ".e'o ko ko kurji".wordsRead == some(@["e'o", "ko", "ko", "kurji"])  # 4.2, Example 2.6
    check ".E'o ko ko KURji".stressesRead ==
        some(@[some(0), none(int), none(int), some(0)])  # 4.2, Example 2.6
    check "le re nanmu".wordsRead == some(@["le", "re", "nanmu"])  # 4.2, Example 2.7
    check "le RE. NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Written])  # 4.2, Example 2.8
    check "le RE NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred])  # 4.2, stress demands pause (3.3)
    check "le RE LE nanmu".pausesRead == some(@[
      Pause.Absent, Pause.Absent, Pause.Inferred, Pause.Inferred,
    ])  # 4.2, stressed syllables meet; 4.9 rule 5; constructed
    check "LE re NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Absent])  # 4.2, Example 2.9
    check "le re NANmu".stressesRead ==
        some(@[none(int), none(int), some(0)])  # 4.2, Example 2.10
    check "mi .y. klama".pausesRead ==
        some(@[Pause.Absent, Pause.Written, Pause.Written])  # 4.2, ".y." pauses before and after
    check "mi y klama".pausesRead ==
        some(@[Pause.Absent, Pause.Inferred, Pause.Inferred])  # 4.2, inferred (3.3); constructed


  test "Section 4.8":
    for (text, at) in [
      ("djim.", 0), ("djein.", 0), (".arnold.", 1), ("pit.", 0), ("katrinas.", 0),
      ("kat,r,in.", 0), ("katis.", 0), ("keit.", 0), ("djan.  djonz.", 0), ("djandjonz.", 0),
      ("pav.", 0), ("sol.", 0), ("ralj.", 0), ("nol.", 0),
    ]:
      check text.refusalRead == some((Refusal.Cmene, at))  # 4.8, Examples 8.1-14; gap #812


  test "Section 4.9":
    check "bri.vla".refusalRead == some((Refusal.Shape, 0))  # rule 1, pause breaks up word
    check ".i mi klama".pausesRead ==
        some(@[Pause.Written, Pause.Absent, Pause.Absent])  # rule 3; constructed
    check "cy klama".pausesRead == some(@[Pause.Absent, Pause.Inferred])  # rule 6; constructed
    check "cy ky klama".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred])  # rule 6, "Cy" follows; constructed
    check "zoi gy. John .gy.".refusalRead == some((Refusal.Foreign, 0))  # rule 7; gap #814
    check "zo zoi".refusalRead == some((Refusal.Foreign, 3))  # rule 7; `zo` gap #814 reads
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


  test "Capital on penultimate syllable of brivla reads, and on any other is refused":
    var count = 0
    for word in concat(WORDS_GISMU, WORDS_LUJVO):  # every gismu, and each random lujvo
      let
        spans = word.syllables
        counted = toSeq(0 .. spans.high).filterIt(word[spans[it].a] != 'y')
      for k, span in spans:
        let text = word.capitalized(span)
        if k == counted[^2]:
          check text.stressesRead == some(@[some(k)])  # 3.9, penultimate, `y` not counted
          inc count
        else:
          check text.refusalRead == some((Refusal.Stress, span.a))  # 3.9, false primary stress
    check count == WORDS_GISMU.len + WORDS_LUJVO.len  # one stress reads in each brivla


  test "Capital on any vowel of cmavo stresses that syllable, and capital on y is refused":
    for word in WORDS_CMAVO:
      for k, span in word.syllables:
        let text = word.capitalized(span)
        if word[span.a] == 'y':
          check text.refusalRead == some((Refusal.Stress, span.a))  # 3.9, "y" never stressed
        else:
          check text.stressesRead == some(@[some(k)])  # 3.9, cmavo any syllable


  test "Stream of marks alone reads as no words":
    for text in ["", " ", ".", " .\t. \n"]:
      check text.wordsRead == some(newSeq[string]())  # 3.3, marks divide words alone


  test "Refusal names byte where offending word opens":
    check "mi klama lonubroda".refusalRead == some((Refusal.Shape, 9))  # 3.3; constructed
    check "mi klama ki'eu'e".refusalRead == some((Refusal.Shape, 9))  # 4.2; constructed
    check "mi klama djan".refusalRead == some((Refusal.Cmene, 9))  # gap #812; constructed
