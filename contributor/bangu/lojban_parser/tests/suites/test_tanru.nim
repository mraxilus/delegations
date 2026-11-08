## Replicate word reading of CLL chapters 3 and 4 against `tanru.nim`, and hold laws CLL implies.
##   Spellings, tanru and scores are copied from CLL text, never from library output, so suite
##     checks reading rather than repeating it. 4.13 misstates V of `gerzda` as 3; total 5878 is
##     right, and is what suite holds. CLL lujvo given without rafsi split are marked split
##     inferred; word no source holds is marked constructed.
##   Rules judge, list names (#823): suite holds text that rules admit as read, listed or not,
##     and each refusal to rule of CLL it names. Mark of stream is held as `Stream`, which
##     `readStream` reads, and `test_stream.nim` holds comma and capital CLL writes inside word
##     (3.3, 3.9).
##   Tanru form unbounded domain, so laws run over seeded random tanru of one to four gismu,
##     drawn from every gismu of list, and over each entry of list exhaustively (Article IX.3).
##   Round trip runs again over seeded tanru of one to six words, cmavo among them, since lujvo
##     hold rafsi of cmavo too (4.6).
##   Words list holds not are drawn too: every string of gismu form, and seeded lujvo of rafsi
##     whose letters fit each form, assigned or not (Article IX.4).
##   Reference for lowest score enumerates every rafsi 4.11 steps 1 and 2 allow, shared `brod`
##     included, and keeps spellings that read back; rendering is held to their minimum.
##     Cost: at most `4^n` joins and readings per tanru of `n` gismu.
##   Corpus does not cover yet: tanru of seven words or more, and lowest score of tanru of five
##     words or more or holding cmavo.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]
from std/unicode import Rune, toUTF8, validateUtf8

import ../../src/lojban_parser/[
  clusters, dictionary, forms, fuhivla, lujvo, selmaho, tanru {.all.},
]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ./[rafsi_random, texts_outside]


const
  SAMPLES = 1000  ## Random tanru laws draw, seeded.
  FLOOR_SHARED_ROUND = 2
    ## Least samples holding `brodi`, `brodo` or `brodu` before last gismu, which read back with
    ## part `brod`: 3 read at seed `0`; about one sample in three hundred holds one.
  FLOOR_LOWEST = 650
    ## Least samples of two gismu or more, free of those, that lowest score law reads: 719 read
    ## at seed `0`; three quarters expected.
  FLOOR_SEARCH = 3400
    ## Least drawn tanru that law of search holds `$` to: 3500 read at seeds of pools, every draw.
  FLOOR_BROKEN = 3  ## Least of them where step 5 of 4.11 puts `y` at first joint: 4 at seeds.
  FLOOR_LUJVO_LIST = 3700
    ## Least lines of `lujvo.txt` reading as tanru of two words or more: 3820 read.
  FLOOR_FINAL_CMAVO = 25
    ## Least CVV and CCV rafsi of cmavo, which could end word, that final law reads: 30 of list.
  SAMPLES_CMAVO = 500
    ## Random tanru of one to `COUNT_WORDS_CMAVO_MAX` words, cmavo among them, that second round
    ## trip law draws, seeded.
  COUNT_WORDS_CMAVO_MAX = 6
    ## Most words of such tanru: `$` grows about 4 times each word (`tanru.nim` header), so six
    ## keeps suite fast.
  FLOOR_CMAVO = 220  ## Least of them holding cmavo: 254 read at seed `0`.
  FLOOR_SHARED = 20
    ## Least of them holding `brodi`, `brodo` or `brodu` before last word: 27 read at seed `0`.
  SAMPLES_FORMS = 2000  ## Random lujvo of rafsi drawn from letters of each form, seeded.
  SAMPLES_LETTERS = 20000
    ## Random strings of five to ten letters, consonant one time in two, that class law reads.
  FLOOR_FUHIVLA = 1400  ## Least of them reading as fu'ivla: 1545 read at seed `0`.
  FLOOR_CMENE = 4800  ## Least of them reading as cmene: 5043 read at seed `0`.
  SAMPLES_JOINED = 2000
    ## Random joins of one or two listed cmavo, opening with consonant and `y` aside, before
    ##   listed gismu of form CCVCV, seeded; no rule of 4.9 needs pause between them, and pair
    ##   opening gismu falls in first five letters of join as brivla holds one (4.3).
  FLOOR_JOINED = 140
    ## Least of them refused as combination: 156 read at seed `3`; most others read lujvo of
    ##   wrong hyphen, or pair past fifth letter.
  CONSONANTS_LETTERS = "bcdfgjklmnprstvxz"  ## Seventeen consonants of 3.1.
  FLOOR_UNASSIGNED = 1700
    ## Least of them holding rafsi list assigns to no word: 1743 read at seed `0`, since most
    ## letters of each form name no word.
  ALPHABET = "',.abcdefgijklmnoprstuvxyz"  ## Letters and symbols of 3.1, in its order.
  GISMU_STEM_SHARED = ["brodi", "brodo", "brodu"]
    ## Gismu holding no short rafsi, so only non-final rafsi is `brod`, which `broda` and `brode`
    ## share.
  SPELLINGS_CLL = [
    "brivla", "brivalsi", "bridyvla", "bridyvalsi", "mampa'u", "soirsai", "sampli", "bralo'i",
    "zunlyjamfu", "zunlyjma", "zuljamfu", "zuljma", "mamtypatfu", "lerfyliste", "nancyprali",
    "prunyplipe", "vancysanmi", "cumfri", "klezba", "kixta'a", "sniju'o", "lerste", "patyta'a",
    "mudysiclu", "ro'inre'o", "rokre'o", "labmau", "gerzda", "gerzdani", "ge'uzda",
    "ge'urzdani", "gerkyzda", "gerkyzdani", "lotkle", "blokle", "lo'ikle", "lotlei", "blolei",
    "lo'irlei", "lojbangri", "lojbaugri", "lojbangygri", "logjybangri", "logjybaugri",
    "logjybangygri", "lojbangirzu", "lojbaugirzu", "lojbangygirzu", "logjybangirzu",
    "logjybaugirzu", "logjybangygirzu", "zbasai", "nunynau", "sairzbata'u", "zbazbasysarji",
    "nakykemcinctu",
  ]
    ## Every chapter 4 spelling suite quotes that reads as word.
  SPELLINGS_CLL_REFUSED = ["patta'a", "mudsiclu", "ro'ire'o", "ro'irre'o"]
    ## Every chapter 4 spelling suite quotes that reader refuses: hyphens 4.6 forbids, or two
    ##   cmavo run together.
  WORDS_GISMU = block:
    ## Every gismu of list, by index; cmavo carrying rafsi left out.
    var words: seq[Word]
    for i, entry in LIST_GISMU:
      if entry.word.isGismu: words.add Word(i)
    words
  WORDS_CMAVO = block:
    ## Every cmavo of list carrying rafsi, by index.
    var words: seq[Word]
    for i, entry in LIST_GISMU:
      if not entry.word.isGismu: words.add Word(i)
    words
  WORDS_CMAVO_JOINABLE = block:
    ## Every cmavo of cmavo list opening with consonant and holding no `y`, which no rule of
    ##   4.9 parts from word opening with consonant after it.
    var words: seq[string]
    for entry in LIST_CMAVO:
      if entry.word[0] in CONSONANTS_LETTERS and 'y' notin entry.word: words.add entry.word
    words
  CHARACTERS_FOREIGN = [
    "\u0080", "é", "ĉ", "ʼ", "߿", "ࠀ", "’", "日", "�",
    "￿", "\u{10000}", "\u{1D44E}", "\u{1F600}", "\u{10FFFF}",
  ]
    ## Characters outside letters, by bytes of UTF-8 each takes, Table 3-6 of Unicode Standard:
    ##   two (`é`, `ĉ`, modifier apostrophe, both ends of range), three (curly apostrophe,
    ##   ideograph, U+FFFD, both ends), four (mathematical italic, emoji, both ends).
    ##   Structured corpus alone, never whole domain: `SAMPLES_FOREIGN` seeded draws read rest.
  SAMPLES_FOREIGN = 1000
    ## Random draws past ASCII Letter law reads, seeded: bytes of UTF-8 drawn first, two to four,
    ##   then code point of that length, so each row of Table 3-6 is read often.
  FLOOR_FOREIGN = 950
    ## Fewest random draws that are scalar values, surrogates aside; 986 read at seed `0`.
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"  ## Seventeen consonants C stands for (4.1 rule 3).
  ORDER_VOWELS = "aeiou"  ## Five vowels V stands for, `y` excluded (4.1 rule 1).


func toTanru(text: string): Tanru =
  ## Build tanru of listed words joined by `+`, as suite writes tanru.
  Tanru(parts: text.split('+').mapIt(it.word.get.toPart))


func unlisted(letters: string): Part =
  ## Build part naming no one word of list, by its letters.
  Part(is_listed: false, letters: letters)


func tanruRead(text: string): Option[Tanru] =
  ## Read text as word; tanru, or `none` where refused.
  let reading = text.readWord
  if reading.is_word: some(reading.tanru) else: none(Tanru)


func kindRead(text: string): Option[Kind] =
  ## Read class of text as word; `none` where refused.
  let reading = text.readWord
  if reading.is_word: some(reading.kind) else: none(Kind)


func refusalRead(text: string): Option[(Refusal, string)] =
  ## Read refusal of text with its detail; `none` where text is word.
  let reading = text.readWord
  if reading.is_word: none((Refusal, string)) else: some((reading.refusal, reading.detail))


func scoreRead(text: string): Option[int] =
  ## Score rafsi of text as reader splits them (4.12); `none` where refused.
  let reading = text.readWord
  if reading.is_word: some(reading.pieces.score) else: none(int)


func spelled(pieces: openArray[Piece]): string =
  ## Write pieces back as letters, each hyphen after its rafsi.
  for piece in pieces: result.add piece.rafsi & LUT_LETTER_BY_HYPHEN[piece.hyphen]


func isStemShared(tanru: Tanru): bool =
  ## Test `$` must write shared `brod`: tanru holds `brodi`, `brodo` or `brodu` before last word.
  for i in 0 ..< tanru.parts.high:
    if $tanru.parts[i] in GISMU_STEM_SHARED: return true
  false


func withStemShared(tanru: Tanru): Tanru =
  ## Read tanru as its rendering reads back: `brodi`, `brodo` and `brodu` before last word
  ##   become part `brod`, which names no one gismu (4.4).
  result = tanru
  for i in 0 ..< result.parts.high:
    if $result.parts[i] in GISMU_STEM_SHARED: result.parts[i] = unlisted("brod")


func spellings(tanru: Tanru): seq[seq[string]] =
  ## List every rafsi sequence 4.11 steps 1 and 2 allow for tanru of two gismu or more.
  ##   Candidates are short rafsi, 4-letter rafsi and gismu itself, each where its form stands.
  result = @[newSeq[string]()]
  for i, part in tanru.parts:
    let
      entry = part.word.entry
      forms_allowed = (if i == tanru.parts.high: FORMS_FINAL else: FORMS_SHORT + FORMS_UNREDUCED)
    var extended: seq[seq[string]]
    for chosen in result:
      for one in entry.rafsi & @[entry.word[0 .. 3], entry.word]:
        if one.form.get in forms_allowed: extended.add chosen & one
    result = extended


func renderExhaustive(tanru: Tanru): string =
  ## Render tanru by scoring every sequence of choices `$` reads, first of lowest kept.
  ##   Reference search law holds `$` to (IX.2): same choices, same order, same score of 4.12,
  ##     and time exponential in words, so laws read it on short tanru alone.
  if tanru.parts.len == 0: return ""
  if tanru.parts.len == 1: return $tanru.parts[0]
  var options = @[newSeq[string]()]
  for i, part in tanru.parts:
    var extended: seq[seq[string]]
    for chosen in options:
      for one in choices(part, is_final = i == tanru.parts.high): extended.add chosen & one
    options = extended
  if options.len == 0: return tanru.parts.mapIt($it).join(" ")
  var best = (score: high(int), word: "")
  for rafsi in options:
    let value = rafsi.toPieces.score
    if value < best.score: best = (value, joinRafsi(rafsi))
  best.word


func isBrokenFirst(text: string): bool =
  ## Test word holds `y` step 5 of 4.11 puts at first joint: CVC first and `y` after it, where
  ##   step 4b puts none, since pair is permissible and forms no forbidden triple.
  let reading = text.readWord
  if not reading.is_word or reading.pieces.len < 2: return false
  let
    (first, second) = (reading.pieces[0], reading.pieces[1])
    (a, b) = (first.rafsi[^1], second.rafsi[0])
  first.form == Form.Cvc and first.hyphen == Hyphen.Y and isPairPermissible(a, b) and
      (not second.rafsi[1].isConsonant or isTriplePermissible(a, b, second.rafsi[1]))


func partNamed(rafsi: string): Part =
  ## Find part rafsi names apart from reader: short rafsi by its table, 4-letter rafsi by stem
  ##   of one gismu, 5-letter rafsi by word itself (4.6); else its letters.
  let found =
    case rafsi.form.get
    of Form.Cvc, Form.Ccv, Form.Cvv: rafsi.wordRafsi
    of Form.Cvcc, Form.Ccvc:
      if rafsi.wordsStem.len == 1: some(rafsi.wordsStem[0]) else: none(Word)
    of Form.Cvccv, Form.Ccvcv: rafsi.word
  if found.isSome: found.get.toPart else: unlisted(rafsi)


func isShapeBrivla(text: string): bool =
  ## Test text has shape 4.3 gives brivla, apart from reader: vowel last, and consonant pair
  ##   among first five letters, `y` and apostrophe left out.
  var head = ""
  for c in text:
    if c notin {'y', '\''} and head.len < 5: head.add c
  let is_pair = toSeq(1 ..< head.len).anyIt(
    head[it - 1] in CONSONANTS_LETTERS and head[it] in CONSONANTS_LETTERS
  )
  text[^1] in "aeiou" and is_pair


func isShapeGismu(text: string): bool =
  ## Test text has shape of gismu by class of each letter alone: CVCCV or CCVCV (4.4).
  var shape = ""
  for c in text: shape.add(if c in "aeiou": 'V' else: 'C')
  shape in ["CVCCV", "CCVCV"]


func isBrokenUp(text: string): bool =
  ## Test text holds `la` or `doi` opening it or after no consonant, which breaks cmene up (4.8).
  for i in 0 ..< text.len:
    if i > 0 and text[i - 1] in CONSONANTS_LETTERS: continue
    if text.continuesWith("la", i) or text.continuesWith("doi", i): return true
  false


proc drawTanru(): seq[Tanru] =
  ## Draw `SAMPLES` tanru of one to four gismu, seeded, each gismu from every gismu of list.
  randomize(0)
  for _ in 1 .. SAMPLES:
    result.add Tanru(parts: newSeqWith(rand(1 .. 4), WORDS_GISMU[rand(WORDS_GISMU.high)].toPart))


let TANRU_RANDOM = drawTanru()  ## Random tanru every law reads, drawn once.


iterator tanruRandom(): lent Tanru =
  ## Serve each random tanru of pool, with no copy.
  for i in 0 ..< TANRU_RANDOM.len: yield TANRU_RANDOM[i]


proc drawTanruCmavo(): seq[Tanru] =
  ## Draw `SAMPLES_CMAVO` tanru of one to `COUNT_WORDS_CMAVO_MAX` words, seeded: last word gismu,
  ##   each word before it cmavo one time in three, else `brodi`, `brodo` or `brodu` one time in
  ##   twenty-five, else gismu; each from every word of its kind in list.
  randomize(0)
  for _ in 1 .. SAMPLES_CMAVO:
    let count = rand(1 .. COUNT_WORDS_CMAVO_MAX)
    var parts = newSeqOfCap[Part](count)
    for i in 1 .. count:
      parts.add(
        if i == count: WORDS_GISMU[rand(WORDS_GISMU.high)].toPart
        elif rand(2) == 0: WORDS_CMAVO[rand(WORDS_CMAVO.high)].toPart
        elif rand(24) == 0: GISMU_STEM_SHARED[rand(GISMU_STEM_SHARED.high)].word.get.toPart
        else: WORDS_GISMU[rand(WORDS_GISMU.high)].toPart
      )
    result.add Tanru(parts: parts)


let TANRU_CMAVO = drawTanruCmavo()  ## Random tanru second round trip law reads, drawn once.


iterator tanruCmavo(): lent Tanru =
  ## Serve each random tanru of second pool, cmavo among its words, with no copy.
  for i in 0 ..< TANRU_CMAVO.len: yield TANRU_CMAVO[i]


iterator textsNotation(notation: string): string =
  ## Yield every string of C and V notation of 4.1, last position fastest.
  let positions = notation.mapIt(if it == 'C': ORDER_CONSONANTS else: ORDER_VOWELS)
  var at = newSeq[int](positions.len)
  while true:
    var text = newStringOfCap(positions.len)
    for i, letters in positions: text.add letters[at[i]]
    yield text
    var i = positions.high
    while i >= 0:
      inc at[i]
      if at[i] < positions[i].len: break
      at[i] = 0
      dec i
    if i < 0: break


let SEQUENCES_FORMS = drawSequencesLetters(SAMPLES_FORMS, 2 .. 4, seed = 0)
  ## Random rafsi sequences of forms law reads, drawn once from letters (`rafsi_random.nim`).


iterator lujvoForms(): lent seq[string] =
  ## Serve each random rafsi sequence of forms pool, with no copy.
  for i in 0 ..< SEQUENCES_FORMS.len: yield SEQUENCES_FORMS[i]



suite "Chapter 3":
  test "Section 3.1":
    var alphabet: set[char]
    for c in ALPHABET: alphabet.incl c
    check tanru.LETTERS == alphabet - {',', '.'}  # 3.1 list; comma, period divide syllables (3.3)
    for c in 'a' .. 'z':
      check (c in tanru.LETTERS) == (c notin {'h', 'q', 'w'})  # 3.1, omitting "h", "q", and "w"
    for c in char.low .. char.high:  # 256 bytes; marks of stream held in `Internal: Reading`
      if c in tanru.LETTERS or c in MARKS_STREAM: continue
      check ("bri" & c & "vla").refusalRead == some((Refusal.Letter, $c))  # 3.1, alphabet


  test "Section 3.3":
    check "rohinreho".refusalRead == some((Refusal.Letter, "h"))  # 3.3, no "h" for `'`; constructed
    check "kixtaha".refusalRead == some((Refusal.Letter, "h"))  # 3.3, no "h" for `'`; constructed
    check "bri.vla".refusalRead == some((Refusal.Stream, "."))  # 3.3, period makes two words
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):  # each CLL spelling quoted
      for i in 1 ..< spelling.len:  # every position inside word
        let (head, tail) = (spelling[0 ..< i], spelling[i .. ^1])
        check (head & "." & tail).refusalRead ==
            some((Refusal.Stream, "."))  # 3.3, period embedded in word makes two words
    for text in ["'a", "a'", "zba'", "kla'ma", "bri''a"]:  # constructed
      check text.refusalRead == some((Refusal.Apostrophe, ""))  # 3.3, apostrophe joins vowels



suite "Chapter 4":
  test "Section 4.2":
    for text in ["a", "e", "i", "o", "u", "ba", "ce", "di", "fo", "gu"]:
      check text.kindRead == some(Kind.Cmavo)  # 4.2, V-form and CV-form; pause unwritten
    for text in ["au", "ei", "ia", "o'u", "u'e", "ki'a", "pei", "mi'o", "coi", "cu'u"]:
      check text.kindRead == some(Kind.Cmavo)  # 4.2, VV-form and CVV-form
    for text in ["ku'a'e", "sau'e", "bai'ai", "ki'e'u'e"]:
      check text.kindRead == some(Kind.Cmavo)  # 4.2, experimental, Example 4.4
    check "y".kindRead == some(Kind.Cmavo) and "by".kindRead == some(Kind.Cmavo)  # 4.2, 17.2
    check "lo".tanruRead == some(Tanru(parts: @[unlisted("lo")]))  # 4.2, no list gives `lo` rafsi
    check "se".tanruRead == some(toTanru("se"))  # 4.2, cmavo gismu list holds, for its rafsi
    check "lo".readWord.selmaho == some(Selmaho.Le)  # 20, `lo` of LE, which cmavo list holds
    check "se".readWord.selmaho == some(Selmaho.Se)  # 20, `se` of SE
    check "ku'a'e".readWord.selmaho.isNone  # 4.2, experimental, so no list holds it
    check "klama".readWord.selmaho.isNone  # 4.3, brivla has no selma'o
    check "kauzba".readWord.selmaho.isNone  # rafsi `kau` names `kampu`, not cmavo; constructed
    for text in ["iseci'i", "punaijecanai", "da'amei"]:
      check text.refusalRead == some((Refusal.Stream, ""))  # 4.2, Examples 4.1-2; 4.3, compound
    check "ki'e.u'e".refusalRead == some((Refusal.Stream, "."))  # 4.2, Example 4.3, pause


  test "Section 4.3":
    check "lojban".kindRead == some(Kind.Cmene)  # 4.3, "lojban." must be name
    check "da'amei".refusalRead == some((Refusal.Stream, ""))  # 4.3, "must be compound cmavo"
    check "bisycla".kindRead.isSome  # 4.3, `sc` counted through `y`, so brivla; constructed
    for text in ["zba", "brai"]:  # constructed
      check text.refusalRead == some((Refusal.Shape, ""))  # 4.3, penultimate stress, two syllables
    check "bridy".refusalRead == some((Refusal.Shape, ""))  # 4.3, brivla end in vowel; constructed


  test "Section 4.4":
    for text in ["creka", "lijda", "blanu", "mamta", "cukta", "patfu", "nanmu", "ninmu"]:
      check text.kindRead == some(Kind.Gismu)  # 4.4, Examples 4.11-18
      check text.tanruRead == some(toTanru(text))  # 4.4, listed gismu names itself
    for text in ["kismu", "xismu", "gicmu", "gizmu", "gisnu"]:
      check text.kindRead == some(Kind.Gismu)  # 4.4, form of gismu, though no list holds it
      check text.tanruRead == some(Tanru(parts: @[unlisted(text)]))  # 4.4, no meaning given


  test "Section 4.5":
    for spelling in ["brivla", "brivalsi", "bridyvla", "bridyvalsi"]:
      check spelling.tanruRead == some(toTanru("bridi+valsi"))  # 4.5, four spellings, one lujvo
      check spelling.kindRead == some(Kind.Lujvo)  # 4.5, lujvo
    check "mampa'u".tanruRead == some(toTanru("mamta+patfu"))  # 4.5, Example 4.25 from Example 4.22
    check "mampa'u".readWord.pieces.mapIt(it.rafsi) == @["mam", "pa'u"]  # 4.5, "mam-", "-pa'u"
    check "soirsai".tanruRead == some(toTanru("sonci+sanmi"))  # 4.5, Example 4.26
    check "soirsai".readWord.pieces.spelled == "soirsai"  # 4.5, Example 4.26, "r" between rafsi
    check "soirsai".readWord.pieces[0].hyphen == Hyphen.R  # 4.5, Example 4.26, additional "r"
    check "sampli".tanruRead == some(toTanru("skami+pilno"))  # 4.5, Example 4.23 from Example 4.19
    check "bralo'i".tanruRead == some(toTanru("barda+bloti"))  # 4.5, Example 4.24 from Example 4.20
    let (paternal, maternal) = (toTanru("patfu+mamta"), toTanru("mamta+patfu"))
    check ($paternal).tanruRead == some(paternal)  # 4.5, rafsi attached in order of tanru
    check ($maternal).tanruRead == some(maternal)  # 4.5, rafsi attached in order of tanru
    check $paternal != $maternal  # 4.5, first modifies second, so order is kept


  test "Section 4.6":
    for spelling in ["zunlyjamfu", "zunlyjma", "zuljamfu", "zuljma"]:
      check spelling.tanruRead == some(toTanru("zunle+jamfu"))  # 4.6, "legitimate and equivalent"
    check $toTanru("zunle+jamfu") == "zuljma"  # 4.6, "zuljma" is preferred one
    for (spelling, text_tanru) in [
      ("mamtypatfu", "mamta+patfu"), ("lerfyliste", "lerfu+liste"),
      ("nancyprali", "nanca+prali"), ("prunyplipe", "pruni+plipe"),
      ("vancysanmi", "vanci+sanmi"),
    ]:
      let pieces = spelling.readWord.pieces
      check spelling.tanruRead == some(toTanru(text_tanru))  # 4.6, Example 4.27-31, unreduced
      check pieces.allIt(it.form in FORMS_UNREDUCED + FORMS_GISMU)  # 4.6, long rafsi alone
    for (spelling, text_tanru) in [
      ("cumfri", "cumki+lifri"), ("klezba", "klesi+zbasu"), ("kixta'a", "krixa+tavla"),
      ("sniju'o", "sinxa+djuno"), ("mampa'u", "mamta+patfu"), ("lerste", "lerfu+liste"),
    ]:
      let pieces = spelling.readWord.pieces
      check spelling.tanruRead == some(toTanru(text_tanru))  # 4.6, Example 4.32-37, fully reduced
      check pieces.allIt(it.form in FORMS_SHORT)  # 4.6, "made up solely of short rafsi"
    check "mamtypatfu".tanruRead == "mampa'u".tanruRead  # 4.6, Example 4.36 reduces Example 4.27
    check "lerfyliste".tanruRead == "lerste".tanruRead  # 4.6, Example 4.37 reduces Example 4.28
    check "patyta'a".tanruRead == some(toTanru("pante+tavla"))  # 4.6, "must be patyta'a"
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # 4.6, "tt" impermissible
    check "mudysiclu".tanruRead == some(toTanru("mudri+siclu"))  # 4.6, "mudysiclu must be used"
    check "mudsiclu".refusalRead == some((Refusal.Hyphen, "mudysiclu"))  # 4.6, cannot form
    check "ro'inre'o".tanruRead == some(toTanru("rokci+renro"))  # 4.6, "n"-hyphen required
    check "rokre'o".tanruRead == some(toTanru("rokci+renro"))  # 4.6, same lujvo, no hyphen
    check "ro'ire'o".refusalRead == some((Refusal.Stream, ""))  # 4.6, "breaks up into two cmavo"
    check "ro'irre'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # 4.6, "rr" double
    check "labmau".tanruRead == some(toTanru("blabi+zmadu"))  # 4.6, "whiter"; split inferred


  test "Section 4.7":
    for text in ["spageti", "cidjrspageti", "djarspageti"]:
      check text.kindRead == some(Kind.Fuhivla)  # 4.7, Example 4.46
    for text in ["tricrxaceru", "ricrxaceru", "saktrxaceru"]:
      check text.kindRead == some(Kind.Fuhivla)  # 4.7, Example 4.47, and "maple sugar"
    for text in ["cirlrbri", "sincrkobra", "saskrkuarka", "lerfrdjamo", "lerldjamo"]:
      check text.kindRead == some(Kind.Fuhivla)  # 4.7, Examples 4.48-51
    for text in ["kulnrblgaria", "gugdrblgaria", "bangrblgaria", "bangrkorea", "kulnrkorea"]:
      check text.kindRead == some(Kind.Fuhivla)  # 4.7, Examples 4.52-56
    for text in ["kuarka", "integrale", "cmacrntegrale", "cmacrnintegrale", "dinjrnintegrale"]:
      check text.kindRead == some(Kind.Fuhivla)  # 4.7, "valid Stage 4 fu'ivla", prefix method
    check "tarmrnintegrale".kindRead == some(Kind.Fuhivla)  # 4.7, architectural "integral"
    check "spraile".kindRead == some(Kind.Fuhivla)  # 4.7, "spraile is acceptable"
    check "ktraile".refusalRead == some((Refusal.Cluster, "ktr"))  # 4.7, "but not ktraile"
    check "trkaile".refusalRead == some((Refusal.Cluster, "trk"))  # 4.7, "or trkaile"
    check "lerndjamo".refusalRead == some((Refusal.Cluster, "ndj"))  # 4.7, "forbidden cluster"
    check "xaceru".refusalRead == some((Refusal.Stream, ""))  # 4.7, "looks like compound cmavo"
    check "kobra".kindRead == some(Kind.Gismu)  # 4.7, `kobra` looks like gismu
    check "slinku'i".refusalRead == some((Refusal.Slinkuhi, "baslinku'i"))  # 4.7, slinku'i test
    check "mibroda".refusalRead == some((Refusal.Combination, "mi broda"))  # 4.7; constructed


  test "Section 4.8":
    for text in ["djim", "djein", "arnold", "pit", "katrinas", "katrin", "katis", "keit"]:
      check text.kindRead == some(Kind.Cmene)  # 4.8, Examples 4.57-64
    for text in ["djan", "braun", "djanbraun", "pav", "sol", "ralj", "nol"]:
      check text.kindRead == some(Kind.Cmene)  # 4.8, Examples 4.65-70
    for text in ["meris", "maris", "meiris", "merix", "marys"]:
      check text.kindRead == some(Kind.Cmene)  # 4.8, "Mary" can be Lojbanized as these
    for text in [
      "smit", "djonz", "jan", "djon", "jon", "alis", "elis", "djansn", "uiliam", "tcarlz", "carl",
      "dygol", "xainrix", "xuakin", "sfietlanys", "xructcof", "kricnas", "lex", "vauensas", "don",
      "kicotes", "kixotes", "ki'otes", "maudzydyn", "fudjikos", "fujikos",
    ]:
      check text.kindRead == some(Kind.Cmene)  # 4.8, table of Lojbanized names
    check "laplas".refusalRead == some((Refusal.Breakup, "la"))  # 4.8, "invalid name laplas."
    check "ilanas".refusalRead == some((Refusal.Breakup, "la"))  # 4.8, as ".i la nas."
    check "nederlants".kindRead == some(Kind.Cmene)  # 4.8, `la` after consonant, `nts` held
    check "djandjonz".kindRead == some(Kind.Cmene)  # 4.8, pairs alone; 1997 example 1.1 dropped
    check "lars".refusalRead == some((Refusal.Breakup, "la"))  # 4.8, `la` first; constructed
    check "djeimz".refusalRead == some((Refusal.Cluster, "mz"))  # 3.6, Example 3.8 forbids pair
    check "djeimyz".kindRead == some(Kind.Cmene)  # 3.6, Example 3.8, "y can be inserted"
    for text in ["rl", "brlgan"]:
      check text.kindRead == some(Kind.Cmene)  # 3.4, syllabic consonants, "rl." and Example 3.5
    check "c".refusalRead == some((Refusal.Shape, ""))  # 3.4, no syllable; constructed


  test "Section 4.12-13":
    for (spelling, value) in [
      ("gerzda", 5878), ("gerzdani", 7917), ("ge'uzda", 6367), ("ge'urzdani", 9506),
      ("gerkyzda", 8008), ("gerkyzdani", 10047),
    ]:
      check spelling.tanruRead == some(toTanru("gerku+zdani"))  # 4.13, six forms of one lujvo
      check spelling.scoreRead == some(value)  # 4.13, scores; V of `gerzda` misstated, 5878 kept
    check $toTanru("gerku+zdani") == "gerzda"  # 4.13, "would probably appear ... gerzda"
    for (spelling, value) in [
      ("lotkle", 5878), ("blokle", 5858), ("lo'ikle", 6367), ("lotlei", 5867),
      ("blolei", 5847), ("lo'irlei", 7456),
    ]:
      let is_hyphenated = spelling.readWord.pieces.anyIt(it.hyphen != Hyphen.None)
      check spelling.tanruRead == some(toTanru("bloti+klesi"))  # 4.13, "all six forms are valid"
      check spelling.scoreRead == some(value)  # 4.13, scoring table of `bloti klesi`
      check is_hyphenated == (spelling == "lo'irlei")  # 4.13, "only lo'irlei requires hyphenation"
    check $toTanru("bloti+klesi") == "blolei"  # 4.13, "blolei is preferred"
    for spelling in [
      "lojbangri", "lojbaugri", "lojbangygri", "logjybangri", "logjybaugri", "logjybangygri",
      "lojbangirzu", "lojbaugirzu", "lojbangygirzu", "logjybangirzu", "logjybaugirzu",
      "logjybangygirzu",
    ]:
      check spelling.tanruRead == some(toTanru("logji+bangu+girzu"))  # 4.13, 12 possibilities
      check spelling.readWord.pieces.allIt(it.form in FORMS_SHORT) ==
          (spelling in ["lojbangri", "lojbaugri"])  # 4.13, "only fully reduced lujvo forms"
    check "lojbangri".scoreRead == some(8827)  # 4.13, "8827 versus 8796"
    check "lojbaugri".scoreRead == some(8796)  # 4.13, "8827 versus 8796"
    check $toTanru("logji+bangu+girzu") == "lojbaugri"  # 4.13, latter has lower score
    check "zbasai".scoreRead == some(5847)  # 4.12, Example 4.71
    check ["nun", "nau"].toPieces.spelled == "nunynau"  # 4.12, Example 4.72, "nun + y + nau"
    check lujvo.score(["nun", "nau"].toPieces) == 6967  # 4.12, Example 4.72
    check "sairzbata'u".scoreRead == some(10385)  # 4.12, Example 4.73
    check "zbazbasysarji".scoreRead == some(12976)  # 4.12, Example 4.74



suite "Internal: Reading":
  test "Empty text is refused as Empty":
    check "".refusalRead == some((Refusal.Empty, ""))  # degenerate input, no detail


  test "Character outside letters is refused as Letter, naming character":
    check "hello".refusalRead == some((Refusal.Letter, "h"))  # first offending; constructed
    check "bwa".refusalRead == some((Refusal.Letter, "w"))  # `w` outside letters; constructed
    check "datni+vreji".refusalRead == some((Refusal.Letter, "+"))  # tanru text is no spelling
    check "brivlaH".refusalRead == some((Refusal.Letter, "H"))  # capital of no letter (3.1)


  test "Character outside letters is named whole, so detail of UTF-8 stays UTF-8":
    check "café".refusalRead ==
        some((Refusal.Letter, "é"))  # review finding logic-6, 2026-10-29: named byte `C3`
    check "ci’a".refusalRead ==
        some((Refusal.Letter, "’"))  # review finding logic-6, 2026-10-29: named byte `E2`
    for character in CHARACTERS_FOREIGN:  # 14 characters, both ends of each byte length
      for text in [character & "brivla", "bri" & character & "vla", "brivla" & character]:
        check text.refusalRead == some((Refusal.Letter, character))  # lead and continuation
        check text.readWord.detail.validateUtf8 == -1  # detail well-formed, at each position
    randomize(0)
    var count_scalar = 0
    for _ in 1..SAMPLES_FOREIGN:  # `SAMPLES_FOREIGN` draws, seeded
      let code =
        case rand(2..4)
        of 2: rand(0x80..0x7FF)
        of 3: rand(0x800..0xFFFF)
        else: rand(0x10000..0x10FFFF)
      if code in 0xD800..0xDFFF: continue  # Surrogate is no scalar value.
      inc count_scalar
      let character = Rune(code).toUTF8
      for text in [character & "brivla", "bri" & character & "vla", "brivla" & character]:
        check text.refusalRead == some((Refusal.Letter, character))  # whole, at any plane
        check text.readWord.detail.validateUtf8 == -1  # detail well-formed, at each position
    check count_scalar >= FLOOR_FOREIGN  # guard keeps most draws


  test "Mark of stream is refused as Stream, which readStream reads":
    check " brivla".refusalRead == some((Refusal.Stream, " "))  # 3.3, space ends word; no trim
    check "brivla\t".refusalRead == some((Refusal.Stream, "\t"))  # whitespace ends word
    check "bri vla".refusalRead == some((Refusal.Stream, " "))  # two words
    for c in MARKS_STREAM:  # every mark, whitespace among them, exhaustive
      check ("bri" & c & "vla").refusalRead == some((Refusal.Stream, $c))  # 3.3, 3.9
    check "BRIVLA".refusalRead == some((Refusal.Stream, "B"))  # 3.9, capital marks stress
    for c in tanru.LETTERS - {'\''}:  # capital of each letter, exhaustive
      check ("bri" & c.toUpperAscii & "vla").refusalRead ==
          some((Refusal.Stream, $c.toUpperAscii))  # 3.9, capital marks stress; no fold
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):  # each CLL spelling quoted
      for i in 0 .. spelling.len:  # every position, both ends included
        let text = spelling[0 ..< i] & "," & spelling[i .. ^1]
        check text.refusalRead ==
            some((Refusal.Stream, ","))  # 3.3, comma breaks syllable, which stream holds


  test "Cmavo run together is refused as Stream, which readStream splits":
    check "ga'inai".refusalRead == some((Refusal.Stream, ""))  # 4.2, `ga'i nai`; Tatoeba
    check "so'imei".refusalRead == some((Refusal.Stream, ""))  # 4.2, `so'i mei`; Tatoeba


  test "Letters of no class, nor cmavo run together, are refused as Shape":
    check "lonubroda".refusalRead == some((Refusal.Shape, ""))  # 3.3, pair past fifth; constructed
    check "cia".refusalRead == some((Refusal.Shape, ""))  # 3.4, `ia` after consonant; constructed
    check "ki'eu'e".refusalRead == some((Refusal.Shape, ""))  # 4.2, Example 4.3 writes period


  test "Word ending in consonant reads as cmene where its letters admit one":
    for text in ["lojban", "gerk", "xyz", "djan"]:  # `gerk`, `xyz` constructed
      check text.kindRead == some(Kind.Cmene)  # 4.3, cmene end in consonant (4.8)


  test "Brivla neither gismu nor lujvo reads as fu'ivla where it meets each rule of 4.7":
    check "bongnanba".kindRead == some(Kind.Fuhivla)  # 3.8, "possible borrowing"
    check "brodrzba".kindRead == some(Kind.Fuhivla)  # 4.7, each rule met; constructed
    check "ci'onmau".kindRead == some(Kind.Fuhivla)  # 4.7, though 4.11 gives `ci'ormau`; Tatoeba
    check "natmyrgu'e".refusalRead == some((Refusal.Shape, ""))  # 4.7, no `y`; `lujvo.txt`


  test "Lujvo ending in rafsi of cmavo reads, its last part that cmavo":
    check "zbadoi".tanruRead == some(toTanru("zbasu+do"))  # 4.6, `doi` of `do`; constructed
    check "zbadu'o".tanruRead == some(toTanru("zbasu+du"))  # 4.6, `du'o` of `du`; constructed
    check "zbadoi".kindRead == some(Kind.Lujvo)  # 4.11 step 2 gives no rule letters can read
    check "nunco'e".tanruRead == some(toTanru("nu+co'e"))  # `co'e` ends lujvo; Tatoeba


  test "Lujvo holding rafsi of cmavo reads as tanru keeping cmavo":
    let
      se = "se".word.get.toPart
      ciska = "ciska".word.get.toPart
      selcia = "selci'a".tanruRead
    check selcia == some(Tanru(parts: @[se, ciska]))  # 4.6, `sel` of cmavo `se`; constructed word
    check selcia.get != Tanru(parts: @[ciska])  # 9.4, `se` converts, so tanru keeps it
    check $selcia.get == "selci'a"  # 4.12, `sel` and `ci'a` score lowest; constructed word
    check "nunkla".tanruRead == some(toTanru("nu+klama"))  # 12.12, `nunkla`
    check "nunynau".tanruRead == some(toTanru("nu+nanmu"))  # 4.12, Example 4.72
    let kem = "nakykemcinctu".tanruRead
    check kem == some(toTanru("nakni+ke+cinse+ctuca"))  # 4.13, tanru `nakni ke cinse ctuca`
    check $kem.get == "nakykemcinctu"  # 4.13, shortest form, preferred by scoring


  test "Gismu shape outside list reads as gismu, its part keeping letters":
    check "kukta".tanruRead == some(Tanru(parts: @[unlisted("kukta")]))  # 4.4; constructed
    check "kukta".kindRead == some(Kind.Gismu)  # 4.4, five letters, CVC/CV
    check "gerkukta".tanruRead ==
        some(Tanru(parts: @["gerku".word.get.toPart, unlisted("kukta")]))  # final; constructed


  test "Rafsi no list assigns reads, its part keeping letters":
    check "clozba".tanruRead ==
        some(Tanru(parts: @[unlisted("clo"), "zbasu".word.get.toPart]))  # CCV; constructed
    check "kukfyzba".tanruRead ==
        some(Tanru(parts: @[unlisted("kukf"), "zbasu".word.get.toPart]))  # 4-letter; constructed
    check "ditybra".tanruRead ==
        some(Tanru(parts: @[unlisted("dit"), "barda".word.get.toPart]))  # `dit`; Tatoeba


  test "Shared 4-letter rafsi reads, its part naming no one gismu":
    check "brodyzba".tanruRead ==
        some(Tanru(parts: @[unlisted("brod"), "zbasu".word.get.toPart]))  # five share; constructed
    check "brodyprenu".tanruRead ==
        some(Tanru(parts: @[unlisted("brod"), "prenu".word.get.toPart]))  # five share; constructed
    check "rodzba".tanruRead == some(toTanru("broda+zbasu"))  # `rod` unshared; constructed


  test "Hyphen 4.11 does not give is refused as Hyphen, naming form 4.11 gives":
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # missing `y`; CLL 4.6
    check "kitymatci".refusalRead == some((Refusal.Hyphen, "kitmatci"))  # surplus `y`; constructed
    check "kicmatci".refusalRead == some((Refusal.Hyphen, "kicymatci"))  # tosmabru `y`; constructed
    check "ro'irre'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # `n`, not `r`; CLL 4.6
    check "clozbas".kindRead == some(Kind.Cmene)  # control: consonant ends; constructed


  test "Each class reads by its letters, whether list holds word or not":
    for (text, kind, is_listed) in [
      ("klama", Kind.Gismu, true), ("kukta", Kind.Gismu, false),
      ("se", Kind.Cmavo, true), ("lo", Kind.Cmavo, false),
      ("bridyvalsi", Kind.Lujvo, true), ("clozba", Kind.Lujvo, false),
    ]:
      let reading = text.readWord
      check reading.is_word and reading.kind == kind  # 4.1, class follows letters
      check reading.tanru.parts.allIt(it.is_listed) == is_listed  # list names, never judges


  test "Pieces spell text, hyphens included; word read whole has none":
    for spelling in SPELLINGS_CLL:  # each CLL spelling quoted that reads, exhaustive
      let reading = spelling.readWord
      check reading.is_word and reading.pieces.spelled == spelling  # split, then spelled
    for text in ["gerku", "kukta", "se", "lo"]:
      check text.readWord.pieces.len == 0  # gismu and cmavo read whole, listed or not



suite "Internal: Laws":
  test "Rendered tanru reads back as itself, shared brod as part brod":
    var count_shared = 0
    for tanru in tanruRandom():  # `SAMPLES` tanru, seeded
      if tanru.isStemShared: inc count_shared
      check ($tanru).tanruRead == some(tanru.withStemShared)  # round trip; `brod` names none
    check count_shared >= FLOOR_SHARED_ROUND  # guard reaches shared stem
    for word in GISMU_STEM_SHARED:
      let shared = toTanru(word & "+zbasu")
      check $shared == "brodyzba"  # `brod` alone stands before last gismu
      check ($shared).tanruRead ==
          some(Tanru(parts: @[unlisted("brod"), "zbasu".word.get.toPart]))  # reads back as `brod`
      check ($toTanru("zbasu+" & word)).tanruRead == some(toTanru("zbasu+" & word))  # final whole


  test "Rendered tanru of up to six words, cmavo among them, reads back as itself, brod aside":
    var (count_cmavo, count_shared) = (0, 0)
    for tanru in tanruCmavo():  # `SAMPLES_CMAVO` tanru, seeded
      if tanru.parts.anyIt(it.word.kind == Kind.Cmavo): inc count_cmavo
      if tanru.isStemShared: inc count_shared
      check ($tanru).tanruRead == some(tanru.withStemShared)  # 4.12, form reads back (4.6)
    check count_cmavo >= FLOOR_CMAVO  # corpus holds cmavo often
    check count_shared >= FLOOR_SHARED  # corpus reaches `brod` often enough


  test "Every gismu renders and reads back in head and in final position":
    for w in WORDS_GISMU:  # 1342 gismu, exhaustive
      let
        head = Tanru(parts: @[w.toPart, "zdani".word.get.toPart])
        final = Tanru(parts: @["gerku".word.get.toPart, w.toPart])
      check ($head).tanruRead == some(head.withStemShared)  # round trip, gismu first
      check ($final).tanruRead == some(final)  # round trip, gismu last


  test "Every short rafsi of list reads as its word, before gismu and after":
    let zbasu = "zbasu".word.get.toPart
    for w in WORDS_GISMU:  # 1342 gismu, every short rafsi, exhaustive
      let (head, final) = (Tanru(parts: @[w.toPart, zbasu]), Tanru(parts: @[zbasu, w.toPart]))
      for one in w.entry.rafsi:
        check joinRafsi([one, "zbasu"]).tanruRead == some(head)  # rafsi names one gismu (CLL 4.6)
        if one.form.get in FORMS_FINAL:
          check joinRafsi(["zba", one]).tanruRead == some(final)  # rafsi names one gismu (CLL 4.6)
    var count_final_cmavo = 0
    for w in WORDS_CMAVO:  # 94 cmavo, every rafsi, exhaustive
      for one in w.entry.rafsi:
        check joinRafsi([one, "zbasu"]).tanruRead ==
            some(Tanru(parts: @[w.toPart, zbasu]))  # 4.6, rafsi of cmavo stands for it, first
        if one.form.get notin FORMS_FINAL: continue
        check joinRafsi(["zba", one]).tanruRead ==
            some(Tanru(parts: @[zbasu, w.toPart]))  # 4.6, and last; list names it, letters judge
        inc count_final_cmavo
    check count_final_cmavo >= FLOOR_FINAL_CMAVO  # guard reaches cmavo rafsi that end words


  test "Rendering scores lowest of every spelling that reads back":
    var count_lowest = 0
    for tanru in tanruRandom():  # `SAMPLES` tanru, seeded
      if tanru.parts.len < 2 or tanru.isStemShared: continue
      var
        lowest = high(int)
        found_rendering = false
      for rafsi in tanru.spellings:
        let text = joinRafsi(rafsi)
        if text.tanruRead != some(tanru): continue
        lowest = min(lowest, rafsi.toPieces.score)
        found_rendering = found_rendering or text == $tanru
      check found_rendering  # rendering is one of spellings 4.11 allows
      check ($tanru).scoreRead == some(lowest)  # minimum over spellings, ties free (CLL 4.12)
      inc count_lowest
    check count_lowest >= FLOOR_LOWEST  # guard kept most samples


  test "Rendering gives form of exhaustive search, first of lowest on tie, over drawn tanru":
    var (count, count_broken) = (0, 0)
    for tanru in tanruRandom():  # `SAMPLES` tanru of gismu, seeded
      check $tanru == tanru.renderExhaustive  # 4.12, against reference search (IX.2)
      inc count
    for tanru in tanruCmavo():  # `SAMPLES_CMAVO` tanru, cmavo among words, seeded
      check $tanru == tanru.renderExhaustive  # 4.12, against reference search (IX.2)
      inc count
    for rafsi in lujvoForms():  # `SAMPLES_FORMS` sequences of letters, seeded
      let reading = joinRafsi(rafsi).readWord
      if not reading.is_word: continue
      let rendered = $reading.tanru
      check rendered == reading.tanru.renderExhaustive  # 4.12, parts no list names among them
      if rendered.isBrokenFirst: inc count_broken
      inc count
    check count >= FLOOR_SEARCH  # guard keeps nearly every draw
    check count_broken >= FLOOR_BROKEN  # guard reaches `y` of 4.11 step 5 at first joint


  test "Rendering gives form of exhaustive search over each lujvo of lujvo list":
    let lines = readLinesLujvo()
    if lines.isNone: skip()  # `lujvo.txt` absent or moved from its pin (`texts_outside.nim`)
    else:
      var count = 0
      for line in lines.get:  # every line whose word is letters, exhaustive
        let reading = line.word.readWord
        if not reading.is_word or reading.tanru.parts.len < 2: continue
        check $reading.tanru == reading.tanru.renderExhaustive  # 4.12, reference search (IX.2)
        inc count
      check count >= FLOOR_LUJVO_LIST  # guard keeps nearly every line


  test "Every gismu of list reads as itself":
    for w in WORDS_GISMU:  # 1342 gismu, exhaustive
      let text = $w
      check text.tanruRead == some(Tanru(parts: @[w.toPart]))  # listed gismu is tanru of itself
      check text.kindRead == some(Kind.Gismu)  # 4.4, form of gismu
      check $Tanru(parts: @[w.toPart]) == text  # gismu renders as itself
      check text.readWord.pieces.len == 0  # read whole, no rafsi


  test "Every cmavo of list reads as itself":
    for w in WORDS_CMAVO:  # 94 cmavo, exhaustive
      let text = $w
      check text.tanruRead == some(Tanru(parts: @[w.toPart]))  # 4.2, cmavo is word of its own
      check text.kindRead == some(Kind.Cmavo)  # 4.2, form of cmavo
      check $Tanru(parts: @[w.toPart]) == text  # cmavo renders as itself
    let se_cusku = toTanru("se+cusku")
    check ($se_cusku).tanruRead == some(se_cusku)  # 4.6, tanru holds cmavo, as lujvo does
    check $toTanru("cusku+se") == "cusku se"  # 4.11 step 2, no rafsi of `se` ends lujvo (5.1)


  test "Every string of gismu form reads as gismu, named where list holds it":
    var count_listed, count_unlisted = 0
    for notation in ["CVCCV", "CCVCV"]:
      for text in textsNotation(notation):  # 122825 strings of each notation, exhaustive
        if not text.isGismu: continue
        let listed = text.word
        check text.kindRead == some(Kind.Gismu)  # 4.4, form alone makes gismu
        check text.tanruRead == some(Tanru(parts: @[
          if listed.isSome: listed.get.toPart else: unlisted(text)
        ]))  # list names it, or part keeps letters
        if listed.isSome: inc count_listed else: inc count_unlisted
    check count_listed == WORDS_GISMU.len  # conservation: each listed gismu met once
    check count_unlisted > 0  # domain reaches strings no list holds


  test "Lujvo of rafsi drawn from letters reads by its forms, named where list assigns":
    var count_unassigned = 0
    for rafsi in lujvoForms():  # `SAMPLES_FORMS` sequences, seeded
      let
        text = joinRafsi(rafsi)
        reading = text.readWord
      check reading.is_word and reading.kind == Kind.Lujvo  # 4.11, forms and hyphens alone
      if not reading.is_word: continue
      check reading.pieces.mapIt(it.rafsi) == rafsi  # split inverts join, assigned or not
      check reading.tanru.parts == rafsi.mapIt(it.partNamed)  # list names each part it can
      if not reading.tanru.parts.allIt(it.is_listed): inc count_unassigned
    check count_unassigned >= FLOOR_UNASSIGNED  # guard reaches rafsi no list assigns


  test "Fu'ivla and cmene read from letters keep shape 4.3, 4.7 and 4.8 give them":
    var count_fuhivla, count_cmene = 0
    randomize(0)
    for _ in 1 .. SAMPLES_LETTERS:
      var text = ""
      for _ in 1 .. rand(5 .. 10):
        text.add(if rand(1) == 0: "bcdfgjklmnprstvxz".sample else: "aeiou".sample)
      let reading = text.readWord
      if not reading.is_word or reading.kind notin {Kind.Fuhivla, Kind.Cmene}: continue
      if reading.kind == Kind.Fuhivla:
        check text.isShapeBrivla  # 4.3, consonant pair in first five letters, vowel last
        check not text.isShapeGismu  # 4.7, no gismu
        inc count_fuhivla
      else:
        check text[^1] in CONSONANTS_LETTERS  # 4.8, consonant last
        check not text.isBrokenUp  # 4.8, no `la` or `doi` after no consonant
        inc count_cmene
    check count_fuhivla >= FLOOR_FUHIVLA  # IX.3, guard keeps fu'ivla in play
    check count_cmene >= FLOOR_CMENE  # IX.3, guard keeps cmene in play


  test "Listed cmavo joined before listed gismu, needing no pause, never reads as fu'ivla":
    var count = 0
    let words_gismu = WORDS_GISMU.mapIt(it.entry.word).filterIt(it[1] in CONSONANTS_LETTERS)
    randomize(3)
    for _ in 1 .. SAMPLES_JOINED:
      var text = ""
      for _ in 1 .. rand(1 .. 2): text.add WORDS_CMAVO_JOINABLE.sample
      text.add words_gismu[rand(words_gismu.high)]
      let reading = text.readWord
      check not (reading.is_word and reading.kind == Kind.Fuhivla)  # 4.7, no combination
      if not reading.is_word and reading.refusal == Refusal.Combination: inc count
    check count >= FLOOR_JOINED  # IX.3, guard keeps refusals of combination in play
