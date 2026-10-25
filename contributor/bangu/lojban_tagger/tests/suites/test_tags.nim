## Replicate tag reading of CLL chapters 3 and 4 against `tags.nim`, and hold laws CLL implies.
##   Spellings, tanru and scores are copied from CLL text, never from library output, so suite
##     checks reading rather than repeating it. 4.13 misstates V of `gerzda` as 3; total 5878 is
##     right, and is what suite holds. CLL lujvo given without rafsi split are marked split
##     inferred; word no source holds is marked constructed.
##   Folding capitals and stripping commas are project's choice (`tags.nim` header), and refusing
##     rafsi of cmavo is Architect's brief, so `Internal: Reading` holds them; CLL there is only
##     source of word.
##   Tags form unbounded domain, so laws run over seeded random tags of one to four gismu, drawn
##     from every gismu of list, and over each entry of list exhaustively (Article IX.3).
##   Reference for lowest score enumerates every rafsi 4.11 steps 1 and 2 allow, shared `brod`
##     included, and keeps spellings that read back; rendering is held to their minimum.
##     Cost: at most `4^n` joins and readings per tag of `n` gismu; whole suite runs in about
##     0.6 s at 1000 samples, debug build (measured).
##   Corpus does not cover yet: tags of five gismu or more, and tags holding cmavo.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[dictionary, forms, lujvo, tags]
import ../../src/lojban_tagger/lists/gismu


const
  SAMPLES = 1000  ## Random tags laws draw, seeded.
  FLOOR_ROUND = 950
    ## Least samples free of `brodi`, `brodo` and `brodu` before last gismu: 997 read at seed
    ## `0`; about one sample in three hundred holds one.
  FLOOR_LOWEST = 650
    ## Least samples of two gismu or more, free of those, that lowest score law reads: 719 read
    ## at seed `0`; three quarters expected.
  FLOOR_FINAL_CMAVO = 25
    ## Least CVV and CCV rafsi of cmavo, which could end word, that final law reads: 30 of list.
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
    "logjybaugirzu", "logjybangygirzu", "zbasai", "sairzbata'u", "zbazbasysarji",
  ]
    ## Every chapter 4 spelling suite quotes that reads as tag.
  SPELLINGS_CLL_REFUSED = [
    "patta'a", "mudsiclu", "ro'ire'o", "ro'irre'o", "nunynau", "nakykemcinctu",
  ]
    ## Every chapter 4 spelling suite quotes that reader refuses: hyphens 4.6 forbids, or rafsi
    ## of cmavo, which brief forbids.
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


func tanru(text: string): Tag =
  ## Read gismu joined by `+` as tag; suite writes listed gismu alone.
  text.readTanru.get


func tagRead(text: string): Option[Tag] =
  ## Read text as tag; `none` where refused.
  let reading = text.readTag
  if reading.is_tag: some(reading.tag) else: none(Tag)


func refusalRead(text: string): Option[(Refusal, string)] =
  ## Read refusal of text with its detail; `none` where text is tag.
  let reading = text.readTag
  if reading.is_tag: none((Refusal, string)) else: some((reading.refusal, reading.detail))


func scoreRead(text: string): Option[int] =
  ## Score rafsi of text as reader splits them (4.12); `none` where refused.
  let reading = text.readTag
  if reading.is_tag: some(reading.pieces.score) else: none(int)


func spelled(pieces: openArray[Piece]): string =
  ## Write pieces back as letters, each hyphen after its rafsi.
  for piece in pieces: result.add piece.rafsi & LUT_LETTER_BY_HYPHEN[piece.hyphen]


func isOutcomeSame(a, b: Reading): bool =
  ## Test readings agree in tag and pieces, or in refusal and detail; text aside.
  if a.is_tag != b.is_tag: return false
  if a.is_tag: a.tag == b.tag and a.pieces == b.pieces
  else: a.refusal == b.refusal and a.detail == b.detail


func isReadingSame(a, b: Reading): bool =
  ## Test readings agree in text, and in outcome.
  a.text == b.text and isOutcomeSame(a, b)


func isStemShared(tag: Tag): bool =
  ## Test `$` must write shared `brod`: tag holds `brodi`, `brodo` or `brodu` before last gismu.
  for i in 0 ..< tag.words.high:
    if $tag.words[i] in GISMU_STEM_SHARED: return true
  false


func spellings(tag: Tag): seq[seq[string]] =
  ## List every rafsi sequence 4.11 steps 1 and 2 allow for tag of two gismu or more.
  ##   Candidates are short rafsi, 4-letter rafsi and gismu itself, each where its form stands.
  result = @[newSeq[string]()]
  for i, w in tag.words:
    let
      entry = w.entry
      forms_allowed = (if i == tag.words.high: FORMS_FINAL else: FORMS_SHORT + FORMS_UNREDUCED)
    var extended: seq[seq[string]]
    for chosen in result:
      for one in entry.rafsi & @[entry.word[0 .. 3], entry.word]:
        if one.form.get in forms_allowed: extended.add chosen & one
    result = extended


proc drawTags(): seq[Tag] =
  ## Draw `SAMPLES` tags of one to four gismu, seeded, each gismu from every gismu of list.
  randomize(0)
  for _ in 1 .. SAMPLES:
    result.add Tag(words: newSeqWith(rand(1 .. 4), WORDS_GISMU[rand(WORDS_GISMU.high)]))


let TAGS = drawTags()  ## Random tags every law reads, drawn once.


iterator tagsRandom(): lent Tag =
  ## Serve each random tag of pool, with no copy.
  for i in 0 ..< TAGS.len: yield TAGS[i]



suite "Chapter 3":
  test "Section 3.1":
    var alphabet: set[char]
    for c in ALPHABET: alphabet.incl c
    check tags.LETTERS == alphabet - {',', '.'}  # 3.1 list; comma and period divide syllables (3.3)
    for c in 'a' .. 'z':
      check (c in tags.LETTERS) == (c notin {'h', 'q', 'w'})  # 3.1, omitting "h", "q", and "w"
    for c in char.low .. char.high:  # 256 bytes; comma and capitals in `Internal: Reading`
      if c in tags.LETTERS or c in {',', 'A' .. 'Z'}: continue
      check ("bri" & c & "vla").refusalRead == some((Refusal.Letter, $c))  # 3.1, alphabet


  test "Section 3.3":
    check "rohinreho".refusalRead == some((Refusal.Letter, "h"))  # 3.3, no "h" for `'`; constructed
    check "kixtaha".refusalRead == some((Refusal.Letter, "h"))  # 3.3, no "h" for `'`; constructed
    check "ro'i,n,re'o".tagRead == some(tanru("rokci+renro"))  # 3.3, comma never required
    check "bri.vla".refusalRead == some((Refusal.Letter, "."))  # 3.3, period makes two words
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):  # each CLL spelling quoted
      let plain = spelling.readTag
      for i in 1 ..< spelling.len:  # every position inside word
        let (head, tail) = (spelling[0 ..< i], spelling[i .. ^1])
        check isReadingSame((head & "," & tail).readTag, plain)  # 3.3, never differ by comma alone
        check (head & "." & tail).refusalRead ==
            some((Refusal.Letter, "."))  # 3.3, period embedded in word makes two words



suite "Chapter 4":
  test "Section 4.5":
    for spelling in ["brivla", "brivalsi", "bridyvla", "bridyvalsi"]:
      check spelling.tagRead == some(tanru("bridi+valsi"))  # 4.5, four spellings, one lujvo
    check "mampa'u".tagRead == some(tanru("mamta+patfu"))  # 4.5, Example 5.7 from 5.4
    check "mampa'u".readTag.pieces.mapIt(it.rafsi) == @["mam", "pa'u"]  # 4.5, "mam-", "-pa'u"
    check "soirsai".tagRead == some(tanru("sonci+sanmi"))  # 4.5, Example 5.8
    check "soirsai".readTag.pieces.spelled == "soirsai"  # 4.5, Example 5.8, "r" between rafsi
    check "soirsai".readTag.pieces[0].hyphen == Hyphen.R  # 4.5, Example 5.8, additional "r"
    check "sampli".tagRead == some(tanru("skami+pilno"))  # 4.5, Example 5.5 from 5.1
    check "bralo'i".tagRead == some(tanru("barda+bloti"))  # 4.5, Example 5.6 from 5.2
    let (paternal, maternal) = (tanru("patfu+mamta"), tanru("mamta+patfu"))
    check ($paternal).tagRead == some(paternal)  # 4.5, rafsi attached in order of tanru
    check ($maternal).tagRead == some(maternal)  # 4.5, rafsi attached in order of tanru
    check $paternal != $maternal  # 4.5, first modifies second, so order is kept


  test "Section 4.6":
    for spelling in ["zunlyjamfu", "zunlyjma", "zuljamfu", "zuljma"]:
      check spelling.tagRead == some(tanru("zunle+jamfu"))  # 4.6, "legitimate and equivalent"
    check $tanru("zunle+jamfu") == "zuljma"  # 4.6, "zuljma" is preferred one
    for (spelling, text_tanru) in [
      ("mamtypatfu", "mamta+patfu"), ("lerfyliste", "lerfu+liste"),
      ("nancyprali", "nanca+prali"), ("prunyplipe", "pruni+plipe"),
      ("vancysanmi", "vanci+sanmi"),
    ]:
      let pieces = spelling.readTag.pieces
      check spelling.tagRead == some(tanru(text_tanru))  # 4.6, Example 6.1-5, unreduced
      check pieces.allIt(it.form in FORMS_UNREDUCED + FORMS_GISMU)  # 4.6, long rafsi alone
    for (spelling, text_tanru) in [
      ("cumfri", "cumki+lifri"), ("klezba", "klesi+zbasu"), ("kixta'a", "krixa+tavla"),
      ("sniju'o", "sinxa+djuno"), ("mampa'u", "mamta+patfu"), ("lerste", "lerfu+liste"),
    ]:
      let pieces = spelling.readTag.pieces
      check spelling.tagRead == some(tanru(text_tanru))  # 4.6, Example 6.6-11, fully reduced
      check pieces.allIt(it.form in FORMS_SHORT)  # 4.6, "made up solely of short rafsi"
    check "mamtypatfu".tagRead == "mampa'u".tagRead  # 4.6, Example 6.10 reduces 6.1
    check "lerfyliste".tagRead == "lerste".tagRead  # 4.6, Example 6.11 reduces 6.2
    check "patyta'a".tagRead == some(tanru("pante+tavla"))  # 4.6, "must be patyta'a"
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # 4.6, "tt" impermissible
    check "mudysiclu".tagRead == some(tanru("mudri+siclu"))  # 4.6, "mudysiclu must be used"
    check "mudsiclu".refusalRead == some((Refusal.Hyphen, "mudysiclu"))  # 4.6, cannot form
    check "ro'inre'o".tagRead == some(tanru("rokci+renro"))  # 4.6, "n"-hyphen required
    check "rokre'o".tagRead == some(tanru("rokci+renro"))  # 4.6, same lujvo, no hyphen
    check "ro'ire'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # 4.6, two cmavo
    check "ro'irre'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # 4.6, "rr" double
    check "labmau".tagRead == some(tanru("blabi+zmadu"))  # 4.6, "whiter"; split inferred


  test "Section 4.12-13":
    for (spelling, value) in [
      ("gerzda", 5878), ("gerzdani", 7917), ("ge'uzda", 6367), ("ge'urzdani", 9506),
      ("gerkyzda", 8008), ("gerkyzdani", 10047),
    ]:
      check spelling.tagRead == some(tanru("gerku+zdani"))  # 4.13, six forms of one lujvo
      check spelling.scoreRead == some(value)  # 4.13, scores; V of `gerzda` misstated, 5878 kept
    check $tanru("gerku+zdani") == "gerzda"  # 4.13, "would probably appear ... gerzda"
    for (spelling, value) in [
      ("lotkle", 5878), ("blokle", 5858), ("lo'ikle", 6367), ("lotlei", 5867),
      ("blolei", 5847), ("lo'irlei", 7456),
    ]:
      let is_hyphenated = spelling.readTag.pieces.anyIt(it.hyphen != Hyphen.None)
      check spelling.tagRead == some(tanru("bloti+klesi"))  # 4.13, "all six forms are valid"
      check spelling.scoreRead == some(value)  # 4.13, scoring table of `bloti klesi`
      check is_hyphenated == (spelling == "lo'irlei")  # 4.13, "only lo'irlei requires hyphenation"
    check $tanru("bloti+klesi") == "blolei"  # 4.13, "blolei is preferred"
    for spelling in [
      "lojbangri", "lojbaugri", "lojbangygri", "logjybangri", "logjybaugri", "logjybangygri",
      "lojbangirzu", "lojbaugirzu", "lojbangygirzu", "logjybangirzu", "logjybaugirzu",
      "logjybangygirzu",
    ]:
      check spelling.tagRead == some(tanru("logji+bangu+girzu"))  # 4.13, 12 possibilities
      check spelling.readTag.pieces.allIt(it.form in FORMS_SHORT) ==
          (spelling in ["lojbangri", "lojbaugri"])  # 4.13, "only fully reduced lujvo forms"
    check "lojbangri".scoreRead == some(8827)  # 4.13, "8827 versus 8796"
    check "lojbaugri".scoreRead == some(8796)  # 4.13, "8827 versus 8796"
    check $tanru("logji+bangu+girzu") == "lojbaugri"  # 4.13, latter has lower score
    check "zbasai".scoreRead == some(5847)  # 4.12, Example 12.1
    check ["nun", "nau"].toPieces.spelled == "nunynau"  # 4.12, Example 12.2, "nun + y + nau"
    check lujvo.score(["nun", "nau"].toPieces) == 6967  # 4.12, Example 12.2
    check "sairzbata'u".scoreRead == some(10385)  # 4.12, Example 12.3
    check "zbazbasysarji".scoreRead == some(12976)  # 4.12, Example 12.4



suite "Internal: Reading":
  test "Text holding nothing but spaces or commas is refused as Empty":
    for text in ["", "   ", "\t\n", ",", " , "]:
      check text.refusalRead == some((Refusal.Empty, ""))  # degenerate input, no detail
      check text.readTag.text == ""  # text as read, trimmed and stripped


  test "Character outside letters is refused as Letter, naming character":
    check "hello".refusalRead == some((Refusal.Letter, "h"))  # first offending character
    check "bri vla".refusalRead == some((Refusal.Letter, " "))  # inner space never trimmed
    check "bwa".refusalRead == some((Refusal.Letter, "w"))  # `w` outside letters; constructed
    check "datni+vreji".refusalRead == some((Refusal.Letter, "+"))  # tanru is no spelling


  test "Cmavo alone, or lujvo ending in cmavo, is refused as Cmavo, naming it":
    check "se".refusalRead == some((Refusal.Cmavo, "se"))  # cmavo of list is no brivla
    check "zbadoi".refusalRead ==
        some((Refusal.Cmavo, "doi (do)"))  # 4.11 step 2, tanru ends in gismu; constructed
    check "zbadu'o".refusalRead ==
        some((Refusal.Cmavo, "du'o (du)"))  # 4.11 step 2, tanru ends in gismu; constructed


  test "Lujvo holding rafsi of cmavo is tag keeping cmavo, matched by its gismu":
    let
      se = "se".word.get
      ciska = "ciska".word.get
      selcia = "selci'a".tagRead
    check selcia == some(Tag(words: @[se, ciska]))  # Architect's ruling: `selci'a` tags
    check selcia.get.gismu == @[ciska]  # ruling: acts as `ciska` in search
    check not selcia.get.isGismuAlone  # tag keeps cmavo it converts with
    check selcia.get != Tag(words: @[ciska])  # `selci'a` and `ciska` are two tags
    check $selcia.get == "selci'a"  # 4.12, `sel` and `ci'a` score lowest; constructed word
    check "nunkla".tagRead.get.toTanru == "nu+klama"  # ruling; word of CLL 12.12
    check "nunynau".tagRead.get.toTanru == "nu+nanmu"  # ruling; CLL 4.12, Example 12.2
    let kem = "nakykemcinctu".tagRead
    check kem.get.toTanru == "nakni+ke+cinse+ctuca"  # 4.13, tanru `nakni ke cinse ctuca`
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
    check "rodzba".tagRead == some(tanru("broda+zbasu"))  # `rod` unshared; constructed


  test "Hyphen 4.11 does not give is refused as Hyphen, naming form 4.11 gives":
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # missing `y`; CLL 4.6
    check "kitymatci".refusalRead == some((Refusal.Hyphen, "kitmatci"))  # surplus `y`; constructed
    check "kicmatci".refusalRead == some((Refusal.Hyphen, "kicymatci"))  # tosmabru `y`; constructed
    check "ro'ire'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # missing `n`; CLL 4.6


  test "Text neither gismu nor lujvo by shape is refused as Shape":
    for text in ["lo", "xyz", "zba", "ge'u", "gerk", "brodrzba"]:  # `xyz`, `brodrzba` constructed
      check text.refusalRead == some((Refusal.Shape, ""))  # no rafsi split, no detail


  test "Text is trimmed, folded to lowercase, and stripped of commas":
    check "  Bri,Vla\t".readTag.text == "brivla"  # project choice (`tags.nim` header), each step
    check "  Bri,Vla\t".tagRead == "brivla".tagRead  # project choice, same tag after normalising
    check "ro'i,n,re'o".readTag.text == "ro'inre'o"  # project choice, comma removed before reading
    check ",brivla,".tagRead == "brivla".tagRead  # project choice, comma at either end stripped
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):  # each CLL spelling quoted
      let plain = spelling.readTag
      for text in ["," & spelling, spelling & ",", "," & spelling & ","]:
        check isReadingSame(text.readTag, plain)  # project choice, comma at ends stripped too
    for c in 'A' .. 'Z':  # 26 capitals, exhaustive
      let (upper, lower) = ("bri" & c & "vla", "bri" & c.toLowerAscii & "vla")
      check isReadingSame(upper.readTag, lower.readTag)  # project choice, capitals fold
    check "BRIVLA".tagRead == some(tanru("bridi+valsi"))  # project choice, capitals fold
    check "brIvla".readTag.text == "brivla"  # project choice, text holds no capital


  test "Pieces spell text, hyphens included; gismu has none":
    for spelling in SPELLINGS_CLL:  # each CLL spelling quoted that reads, exhaustive
      let reading = spelling.readTag
      check reading.is_tag and reading.pieces.spelled == reading.text  # split, then spelled
    check "gerku".readTag.pieces.len == 0  # gismu read whole



suite "Internal: Laws":
  test "Rendered tag reads back as itself, shared brod aside":
    var count_round = 0
    for tag in tagsRandom():  # `SAMPLES` tags, seeded
      let text = $tag
      if tag.isStemShared:
        check text.refusalRead == some((Refusal.Ambiguous, "brod"))  # only rafsi `$` may write
        continue
      check text.tagRead == some(tag)  # round trip, rendering then reading
      check readTanru(tag.toTanru) == some(tag)  # round trip, tanru then reading
      inc count_round
    check count_round >= FLOOR_ROUND  # guard kept most samples
    for word in GISMU_STEM_SHARED:
      let tag = tanru(word & "+zbasu")
      check $tag == "brodyzba"  # `brod` alone stands before last gismu
      check ($tag).refusalRead == some((Refusal.Ambiguous, "brod"))  # cannot read back
      check ($tanru("zbasu+" & word)).tagRead == some(tanru("zbasu+" & word))  # final is whole


  test "Every gismu renders and reads back in head and in final position":
    for w in WORDS_GISMU:  # 1342 gismu, exhaustive
      let
        head = Tag(words: @[w, "zdani".word.get])
        final = Tag(words: @["gerku".word.get, w])
      if $w in GISMU_STEM_SHARED:
        check ($head).refusalRead == some((Refusal.Ambiguous, "brod"))  # shared stem alone
      else:
        check ($head).tagRead == some(head)  # round trip, gismu first
      check ($final).tagRead == some(final)  # round trip, gismu last


  test "Every short rafsi of list reads as its word, before gismu and after":
    let zbasu = "zbasu".word.get
    for w in WORDS_GISMU:  # 1342 gismu, every short rafsi, exhaustive
      let (head, final) = (Tag(words: @[w, zbasu]), Tag(words: @[zbasu, w]))
      for one in w.entry.rafsi:
        check joinRafsi([one, "zbasu"]).tagRead == some(head)  # rafsi names one gismu (CLL 4.6)
        if one.form.get in FORMS_FINAL:
          check joinRafsi(["zba", one]).tagRead == some(final)  # rafsi names one gismu (CLL 4.6)
    var count_final_cmavo = 0
    for w in WORDS_CMAVO:  # 94 cmavo, every rafsi, exhaustive
      for one in w.entry.rafsi:
        check joinRafsi([one, "zbasu"]).tagRead ==
            some(Tag(words: @[w, zbasu]))  # ruling: rafsi of cmavo tags, before gismu (4.6)
        if one.form.get notin FORMS_FINAL: continue
        check joinRafsi(["zba", one]).refusalRead ==
            some((Refusal.Cmavo, one & " (" & $w & ")"))  # 4.11 step 2, tanru ends in gismu
        inc count_final_cmavo
    check count_final_cmavo >= FLOOR_FINAL_CMAVO  # guard reaches cmavo rafsi that end words


  test "Rendering scores lowest of every spelling that reads back":
    var count_lowest = 0
    for tag in tagsRandom():  # `SAMPLES` tags, seeded
      if tag.words.len < 2 or tag.isStemShared: continue
      var
        lowest = high(int)
        found_rendering = false
      for rafsi in tag.spellings:
        let text = joinRafsi(rafsi)
        if text.tagRead != some(tag): continue
        lowest = min(lowest, rafsi.toPieces.score)
        found_rendering = found_rendering or text == $tag
      check found_rendering  # rendering is one of spellings 4.11 allows
      check ($tag).scoreRead == some(lowest)  # minimum over spellings, ties free (CLL 4.12)
      inc count_lowest
    check count_lowest >= FLOOR_LOWEST  # guard kept most samples


  test "Every gismu of list reads as itself, in any case":
    for w in WORDS_GISMU:  # 1342 gismu, exhaustive
      let text = $w
      check text.tagRead == some(Tag(words: @[w]))  # listed gismu is its own tag
      check text.toUpperAscii.tagRead == some(Tag(words: @[w]))  # capitals fold, project choice
      check $Tag(words: @[w]) == text  # gismu renders as itself
      check text.readTag.pieces.len == 0  # read whole, no rafsi


  test "Every cmavo of list is refused as Cmavo":
    for w in WORDS_CMAVO:  # 94 cmavo, exhaustive
      check ($w).refusalRead == some((Refusal.Cmavo, $w))  # cmavo named as itself
    check readTanru("se+cusku").get.toTanru == "se+cusku"  # ruling: tanru may hold cmavo
    check readTanru("cusku+se").isNone  # 4.11 step 2, tanru ends in gismu
    check readTanru("se").isNone  # cmavo alone is no tag
    check readTanru("datni++vreji").isNone  # empty part is no gismu


  test "Reading is idempotent":
    for tag in tagsRandom():  # `SAMPLES` tags, seeded
      let
        text = ($tag).toUpperAscii.replace("A", "A,")
        reading = text.readTag
      check isReadingSame(reading.text.readTag, reading)  # read text reads same again
      check reading.text.readTag.text == reading.text  # normalising fixes point
      check isReadingSame(reading, ($tag).readTag)  # capitals and commas change nothing
