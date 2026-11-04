## Replicate word reading of CLL chapters 3 and 4 against `tanru.nim`, and hold laws CLL implies.
##   Spellings, tanru and scores are copied from CLL text, never from library output, so suite
##     checks reading rather than repeating it. 4.13 misstates V of `gerzda` as 3; total 5878 is
##     right, and is what suite holds. CLL lujvo given without rafsi split are marked split
##     inferred; word no source holds is marked constructed.
##   Canonical form is project's choice (`tanru.nim` header), so `Internal: Reading` holds it:
##     space, comma and capital refused. Comma and capital CLL writes inside word (3.3, 3.9) wait
##     in placeholder test, skipped until reader reads them (Article IX.9).
##   Tanru form unbounded domain, so laws run over seeded random tanru of one to four gismu,
##     drawn from every gismu of list, and over each entry of list exhaustively (Article IX.3).
##   Round trip runs again over seeded tanru of one to six words, cmavo among them, since lujvo
##     hold rafsi of cmavo too (4.6).
##   Reference for lowest score enumerates every rafsi 4.11 steps 1 and 2 allow, shared `brod`
##     included, and keeps spellings that read back; rendering is held to their minimum.
##     Cost: at most `4^n` joins and readings per tanru of `n` gismu.
##   Corpus does not cover yet: tanru of seven words or more, and lowest score of tanru of five
##     words or more or holding cmavo.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, unittest]
from std/unicode import Rune, toUTF8, validateUtf8

import ../../src/lojban_parser/[dictionary, forms, lujvo, tanru]
import ../../src/lojban_parser/lists/gismu


const
  SAMPLES = 1000  ## Random tanru laws draw, seeded.
  FLOOR_ROUND = 950
    ## Least samples free of `brodi`, `brodo` and `brodu` before last gismu: 997 read at seed
    ## `0`; about one sample in three hundred holds one.
  FLOOR_LOWEST = 650
    ## Least samples of two gismu or more, free of those, that lowest score law reads: 719 read
    ## at seed `0`; three quarters expected.
  FLOOR_FINAL_CMAVO = 25
    ## Least CVV and CCV rafsi of cmavo, which could end word, that final law reads: 30 of list.
  SAMPLES_CMAVO = 500
    ## Random tanru of one to `COUNT_WORDS_CMAVO_MAX` words, cmavo among them, that second round
    ## trip law draws, seeded.
  COUNT_WORDS_CMAVO_MAX = 6
    ## Most words of such tanru: `$` grows about 4 times each word (`tanru.nim` header), so six
    ## keeps suite fast.
  FLOOR_ROUND_CMAVO = 450
    ## Least of them free of `brodi`, `brodo` and `brodu` before last word: 473 read at seed `0`.
  FLOOR_CMAVO = 220  ## Least of them holding cmavo: 254 read at seed `0`.
  FLOOR_SHARED = 20
    ## Least of them holding `brodi`, `brodo` or `brodu` before last word: 27 read at seed `0`.
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
    ## Every chapter 4 spelling suite quotes that reader refuses: hyphens 4.6 forbids.
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


func toTanru(text: string): Tanru =
  ## Read listed words joined by `+` as tanru; suite writes listed words alone.
  text.readTanru.get


func tanruRead(text: string): Option[Tanru] =
  ## Read text as word; tanru, or `none` where refused.
  let reading = text.readWord
  if reading.is_word: some(reading.tanru) else: none(Tanru)


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
  for i in 0 ..< tanru.words.high:
    if $tanru.words[i] in GISMU_STEM_SHARED: return true
  false


func spellings(tanru: Tanru): seq[seq[string]] =
  ## List every rafsi sequence 4.11 steps 1 and 2 allow for tanru of two gismu or more.
  ##   Candidates are short rafsi, 4-letter rafsi and gismu itself, each where its form stands.
  result = @[newSeq[string]()]
  for i, w in tanru.words:
    let
      entry = w.entry
      forms_allowed = (if i == tanru.words.high: FORMS_FINAL else: FORMS_SHORT + FORMS_UNREDUCED)
    var extended: seq[seq[string]]
    for chosen in result:
      for one in entry.rafsi & @[entry.word[0 .. 3], entry.word]:
        if one.form.get in forms_allowed: extended.add chosen & one
    result = extended


proc drawTanru(): seq[Tanru] =
  ## Draw `SAMPLES` tanru of one to four gismu, seeded, each gismu from every gismu of list.
  randomize(0)
  for _ in 1 .. SAMPLES:
    result.add Tanru(words: newSeqWith(rand(1 .. 4), WORDS_GISMU[rand(WORDS_GISMU.high)]))


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
    var words = newSeqOfCap[Word](count)
    for i in 1 .. count:
      words.add(
        if i == count: WORDS_GISMU[rand(WORDS_GISMU.high)]
        elif rand(2) == 0: WORDS_CMAVO[rand(WORDS_CMAVO.high)]
        elif rand(24) == 0: GISMU_STEM_SHARED[rand(GISMU_STEM_SHARED.high)].word.get
        else: WORDS_GISMU[rand(WORDS_GISMU.high)]
      )
    result.add Tanru(words: words)


let TANRU_CMAVO = drawTanruCmavo()  ## Random tanru second round trip law reads, drawn once.


iterator tanruCmavo(): lent Tanru =
  ## Serve each random tanru of second pool, cmavo among its words, with no copy.
  for i in 0 ..< TANRU_CMAVO.len: yield TANRU_CMAVO[i]



suite "Chapter 3":
  test "Section 3.1":
    var alphabet: set[char]
    for c in ALPHABET: alphabet.incl c
    check tanru.LETTERS == alphabet - {',', '.'}  # 3.1 list; comma, period divide syllables (3.3)
    for c in 'a' .. 'z':
      check (c in tanru.LETTERS) == (c notin {'h', 'q', 'w'})  # 3.1, omitting "h", "q", and "w"
    for c in char.low .. char.high:  # 256 bytes; comma and capitals held in `Internal: Reading`
      if c in tanru.LETTERS or c in {',', 'A' .. 'Z'}: continue
      check ("bri" & c & "vla").refusalRead == some((Refusal.Letter, $c))  # 3.1, alphabet


  test "Section 3.3":
    check "rohinreho".refusalRead == some((Refusal.Letter, "h"))  # 3.3, no "h" for `'`; constructed
    check "kixtaha".refusalRead == some((Refusal.Letter, "h"))  # 3.3, no "h" for `'`; constructed
    check "bri.vla".refusalRead == some((Refusal.Letter, "."))  # 3.3, period makes two words
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):  # each CLL spelling quoted
      for i in 1 ..< spelling.len:  # every position inside word
        let (head, tail) = (spelling[0 ..< i], spelling[i .. ^1])
        check (head & "." & tail).refusalRead ==
            some((Refusal.Letter, "."))  # 3.3, period embedded in word makes two words


  test "Section 3.9":
    skip()  # 3.3, 3.9, comma and capital inside word, as `sai,r,goi`; gap, canonical form alone



suite "Chapter 4":
  test "Section 4.5":
    for spelling in ["brivla", "brivalsi", "bridyvla", "bridyvalsi"]:
      check spelling.tanruRead == some(toTanru("bridi+valsi"))  # 4.5, four spellings, one lujvo
    check "mampa'u".tanruRead == some(toTanru("mamta+patfu"))  # 4.5, Example 5.7 from 5.4
    check "mampa'u".readWord.pieces.mapIt(it.rafsi) == @["mam", "pa'u"]  # 4.5, "mam-", "-pa'u"
    check "soirsai".tanruRead == some(toTanru("sonci+sanmi"))  # 4.5, Example 5.8
    check "soirsai".readWord.pieces.spelled == "soirsai"  # 4.5, Example 5.8, "r" between rafsi
    check "soirsai".readWord.pieces[0].hyphen == Hyphen.R  # 4.5, Example 5.8, additional "r"
    check "sampli".tanruRead == some(toTanru("skami+pilno"))  # 4.5, Example 5.5 from 5.1
    check "bralo'i".tanruRead == some(toTanru("barda+bloti"))  # 4.5, Example 5.6 from 5.2
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
      check spelling.tanruRead == some(toTanru(text_tanru))  # 4.6, Example 6.1-5, unreduced
      check pieces.allIt(it.form in FORMS_UNREDUCED + FORMS_GISMU)  # 4.6, long rafsi alone
    for (spelling, text_tanru) in [
      ("cumfri", "cumki+lifri"), ("klezba", "klesi+zbasu"), ("kixta'a", "krixa+tavla"),
      ("sniju'o", "sinxa+djuno"), ("mampa'u", "mamta+patfu"), ("lerste", "lerfu+liste"),
    ]:
      let pieces = spelling.readWord.pieces
      check spelling.tanruRead == some(toTanru(text_tanru))  # 4.6, Example 6.6-11, fully reduced
      check pieces.allIt(it.form in FORMS_SHORT)  # 4.6, "made up solely of short rafsi"
    check "mamtypatfu".tanruRead == "mampa'u".tanruRead  # 4.6, Example 6.10 reduces 6.1
    check "lerfyliste".tanruRead == "lerste".tanruRead  # 4.6, Example 6.11 reduces 6.2
    check "patyta'a".tanruRead == some(toTanru("pante+tavla"))  # 4.6, "must be patyta'a"
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # 4.6, "tt" impermissible
    check "mudysiclu".tanruRead == some(toTanru("mudri+siclu"))  # 4.6, "mudysiclu must be used"
    check "mudsiclu".refusalRead == some((Refusal.Hyphen, "mudysiclu"))  # 4.6, cannot form
    check "ro'inre'o".tanruRead == some(toTanru("rokci+renro"))  # 4.6, "n"-hyphen required
    check "rokre'o".tanruRead == some(toTanru("rokci+renro"))  # 4.6, same lujvo, no hyphen
    check "ro'ire'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # 4.6, two cmavo
    check "ro'irre'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # 4.6, "rr" double
    check "labmau".tanruRead == some(toTanru("blabi+zmadu"))  # 4.6, "whiter"; split inferred


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
    check "zbasai".scoreRead == some(5847)  # 4.12, Example 12.1
    check ["nun", "nau"].toPieces.spelled == "nunynau"  # 4.12, Example 12.2, "nun + y + nau"
    check lujvo.score(["nun", "nau"].toPieces) == 6967  # 4.12, Example 12.2
    check "sairzbata'u".scoreRead == some(10385)  # 4.12, Example 12.3
    check "zbazbasysarji".scoreRead == some(12976)  # 4.12, Example 12.4



suite "Internal: Reading":
  test "Empty text is refused as Empty":
    check "".refusalRead == some((Refusal.Empty, ""))  # degenerate input, no detail


  test "Character outside letters is refused as Letter, naming character":
    check "hello".refusalRead == some((Refusal.Letter, "h"))  # first offending; constructed
    check "bri vla".refusalRead == some((Refusal.Letter, " "))  # inner space
    check "bwa".refusalRead == some((Refusal.Letter, "w"))  # `w` outside letters; constructed
    check "datni+vreji".refusalRead == some((Refusal.Letter, "+"))  # tanru text is no spelling


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


  test "Lujvo ending in rafsi of cmavo is refused as Cmavo, naming it":
    check "zbadoi".refusalRead ==
        some((Refusal.Cmavo, "doi (do)"))  # 4.11 step 2, rafsi of final gismu; constructed
    check "zbadu'o".refusalRead ==
        some((Refusal.Cmavo, "du'o (du)"))  # 4.11 step 2, rafsi of final gismu; constructed


  test "Lujvo holding rafsi of cmavo reads as tanru keeping cmavo":
    let
      se = "se".word.get
      ciska = "ciska".word.get
      selcia = "selci'a".tanruRead
    check selcia == some(Tanru(words: @[se, ciska]))  # 4.6, `sel` of cmavo `se`; constructed word
    check selcia.get != Tanru(words: @[ciska])  # 9.4, `se` converts, so tanru keeps it
    check $selcia.get == "selci'a"  # 4.12, `sel` and `ci'a` score lowest; constructed word
    check "nunkla".tanruRead.get.toText == "nu+klama"  # 12.12, `nunkla`
    check "nunynau".tanruRead.get.toText == "nu+nanmu"  # 4.12, Example 12.2
    let kem = "nakykemcinctu".tanruRead
    check kem.get.toText == "nakni+ke+cinse+ctuca"  # 4.13, tanru `nakni ke cinse ctuca`
    check $kem.get == "nakykemcinctu"  # 4.13, shortest form, preferred by scoring


  test "Gismu shape outside list is refused as Unlisted, naming word":
    check "kukta".refusalRead == some((Refusal.Unlisted, "kukta"))  # unlisted; constructed
    check "gerkukta".refusalRead == some((Refusal.Unlisted, "kukta"))  # final; constructed


  test "Rafsi no list assigns is refused as Rafsi, naming rafsi":
    check "clozba".refusalRead == some((Refusal.Rafsi, "clo"))  # CCV of none; constructed
    check "kukfyzba".refusalRead == some((Refusal.Rafsi, "kukf"))  # 4-letter of none; constructed


  test "Shared 4-letter rafsi is refused as Ambiguous, naming rafsi":
    check "brodyzba".refusalRead == some((Refusal.Ambiguous, "brod"))  # five share; constructed
    check "brodyprenu".refusalRead == some((Refusal.Ambiguous, "brod"))  # five share; constructed
    check "rodzba".tanruRead == some(toTanru("broda+zbasu"))  # `rod` unshared; constructed


  test "Hyphen 4.11 does not give is refused as Hyphen, naming form 4.11 gives":
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # missing `y`; CLL 4.6
    check "kitymatci".refusalRead == some((Refusal.Hyphen, "kitmatci"))  # surplus `y`; constructed
    check "kicmatci".refusalRead == some((Refusal.Hyphen, "kicymatci"))  # tosmabru `y`; constructed
    check "ro'ire'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # missing `n`; CLL 4.6


  test "Text neither listed word nor lujvo by shape is refused as Shape":
    for text in ["lo", "xyz", "zba", "ge'u", "gerk", "brodrzba"]:  # `xyz`, `brodrzba` constructed
      check text.refusalRead == some((Refusal.Shape, ""))  # no rafsi split, no detail


  test "Text is read as written, so space, comma and capital are refused as Letter":
    check " brivla".refusalRead == some((Refusal.Letter, " "))  # project choice, no trim
    check "brivla\t".refusalRead == some((Refusal.Letter, "\t"))  # project choice, no trim
    check "BRIVLA".refusalRead == some((Refusal.Letter, "B"))  # 3.1, capitals in names alone
    for c in 'A' .. 'Z':  # 26 capitals, exhaustive
      check ("bri" & c & "vla").refusalRead ==
          some((Refusal.Letter, $c))  # 3.1, capitals in names alone; no fold, project choice
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):  # each CLL spelling quoted
      for i in 0 .. spelling.len:  # every position, both ends included
        let text = spelling[0 ..< i] & "," & spelling[i .. ^1]
        check text.refusalRead ==
            some((Refusal.Letter, ","))  # project choice, canonical form; 3.3 waits in 3.9


  test "Pieces spell text, hyphens included; listed word has none":
    for spelling in SPELLINGS_CLL:  # each CLL spelling quoted that reads, exhaustive
      let reading = spelling.readWord
      check reading.is_word and reading.pieces.spelled == spelling  # split, then spelled
    check "gerku".readWord.pieces.len == 0  # gismu read whole
    check "se".readWord.pieces.len == 0  # cmavo read whole



suite "Internal: Laws":
  test "Rendered tanru reads back as itself, shared brod aside":
    var count_round = 0
    for tanru in tanruRandom():  # `SAMPLES` tanru, seeded
      let text = $tanru
      if tanru.isStemShared:
        check text.refusalRead == some((Refusal.Ambiguous, "brod"))  # only rafsi `$` may write
        continue
      check text.tanruRead == some(tanru)  # round trip, rendering then reading
      check readTanru(tanru.toText) == some(tanru)  # round trip, tanru text then reading
      inc count_round
    check count_round >= FLOOR_ROUND  # guard kept most samples
    for word in GISMU_STEM_SHARED:
      let shared = toTanru(word & "+zbasu")
      check $shared == "brodyzba"  # `brod` alone stands before last gismu
      check ($shared).refusalRead == some((Refusal.Ambiguous, "brod"))  # cannot read back
      check ($toTanru("zbasu+" & word)).tanruRead == some(toTanru("zbasu+" & word))  # final whole


  test "Rendered tanru of up to six words, cmavo among them, reads back as itself, brod aside":
    var (count_round, count_cmavo, count_shared) = (0, 0, 0)
    for tanru in tanruCmavo():  # `SAMPLES_CMAVO` tanru, seeded
      if tanru.words.anyIt(it.kind == Kind.Cmavo): inc count_cmavo
      if tanru.isStemShared:
        check ($tanru).refusalRead == some((Refusal.Ambiguous, "brod"))  # only rafsi `$` may write
        inc count_shared
        continue
      check ($tanru).tanruRead == some(tanru)  # 4.12, form reads back; rafsi of cmavo (4.6)
      inc count_round
    check count_round >= FLOOR_ROUND_CMAVO  # guard kept most samples
    check count_cmavo >= FLOOR_CMAVO  # corpus holds cmavo often
    check count_shared >= FLOOR_SHARED  # corpus reaches `brod` often enough


  test "Every gismu renders and reads back in head and in final position":
    for w in WORDS_GISMU:  # 1342 gismu, exhaustive
      let
        head = Tanru(words: @[w, "zdani".word.get])
        final = Tanru(words: @["gerku".word.get, w])
      if $w in GISMU_STEM_SHARED:
        check ($head).refusalRead == some((Refusal.Ambiguous, "brod"))  # shared stem alone
      else:
        check ($head).tanruRead == some(head)  # round trip, gismu first
      check ($final).tanruRead == some(final)  # round trip, gismu last


  test "Every short rafsi of list reads as its word, before gismu and after":
    let zbasu = "zbasu".word.get
    for w in WORDS_GISMU:  # 1342 gismu, every short rafsi, exhaustive
      let (head, final) = (Tanru(words: @[w, zbasu]), Tanru(words: @[zbasu, w]))
      for one in w.entry.rafsi:
        check joinRafsi([one, "zbasu"]).tanruRead == some(head)  # rafsi names one gismu (CLL 4.6)
        if one.form.get in FORMS_FINAL:
          check joinRafsi(["zba", one]).tanruRead == some(final)  # rafsi names one gismu (CLL 4.6)
    var count_final_cmavo = 0
    for w in WORDS_CMAVO:  # 94 cmavo, every rafsi, exhaustive
      for one in w.entry.rafsi:
        check joinRafsi([one, "zbasu"]).tanruRead ==
            some(Tanru(words: @[w, zbasu]))  # 4.6, rafsi of cmavo stands for it, before gismu
        if one.form.get notin FORMS_FINAL: continue
        check joinRafsi(["zba", one]).refusalRead ==
            some((Refusal.Cmavo, one & " (" & $w & ")"))  # 4.11 step 2, rafsi of final gismu
        inc count_final_cmavo
    check count_final_cmavo >= FLOOR_FINAL_CMAVO  # guard reaches cmavo rafsi that end words


  test "Rendering scores lowest of every spelling that reads back":
    var count_lowest = 0
    for tanru in tanruRandom():  # `SAMPLES` tanru, seeded
      if tanru.words.len < 2 or tanru.isStemShared: continue
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


  test "Every gismu of list reads as itself":
    for w in WORDS_GISMU:  # 1342 gismu, exhaustive
      let text = $w
      check text.tanruRead == some(Tanru(words: @[w]))  # listed gismu is tanru of itself
      check $Tanru(words: @[w]) == text  # gismu renders as itself
      check text.readWord.pieces.len == 0  # read whole, no rafsi


  test "Every cmavo of list reads as itself":
    for w in WORDS_CMAVO:  # 94 cmavo, exhaustive
      let text = $w
      check text.tanruRead == some(Tanru(words: @[w]))  # 4.2, cmavo is word of its own
      check $Tanru(words: @[w]) == text  # cmavo renders as itself
      check readTanru(text) == some(Tanru(words: @[w]))  # tanru text of one cmavo reads back
    check readTanru("se+cusku").get.toText == "se+cusku"  # 4.6, tanru holds cmavo, as lujvo does
    check readTanru("cusku+se").isNone  # 4.11 step 2, last rafsi from final gismu
    check readTanru("datni++vreji").isNone  # empty part is no listed word
