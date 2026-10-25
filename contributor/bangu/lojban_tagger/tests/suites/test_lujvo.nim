## Replicate lujvo of CLL chapters 3, 4 and 7 against `lujvo.nim`: join, split and score.
##   Each lujvo CLL spells is joined from its rafsi and split back into those rafsi alone, so
##     one vector holds both directions; where CLL gives word without rafsi, split is inferred,
##     and comment says so.
##   CLL gives no example of `tosmabru` test (4.11 step 5); words of `LIST_LUJVO` that need it
##     stand in, beside constructed words marked so.
##   Forbidden triple at junction takes `y` by convention of `lujvo.nim`, which 4.11 does not
##     state; suite `Internal: Convention` names where it bites.
##   Removing required hyphen after short rafsi leaves no lujvo, and suite holds it. No such
##     law holds after 4-letter rafsi: dropping its `y` can leave other rafsi that 4.11 joins
##     with no hyphen, e.g. `kramliste` is `kra` + `mli` + `ste`, and 118 of 9996 such
##     junctions of pool split again (measured); so suite claims nothing there.
##   Corpus laws pin each list entry that breaks them, with reason, so drift in list or in
##     library fails by name.
##   Random laws read one pool of rafsi sequences, drawn once with seed `0`, so every law sees
##     same samples and no law draws again.
##   Cost: random rafsi come from gismu list alone; letters of rafsi form that list assigns to
##     no word are not covered yet, and placeholder test shows gap (Article IX.4, IX.9).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[clusters, dictionary, entries, forms, lujvo, tags]
import ../../src/lojban_tagger/lists/gismu
import ../../src/lojban_tagger/lists/lujvo as list_lujvo


func constructRafsiByForm(): array[Form, seq[string]] {.compileTime.} =
  ## Build every rafsi of gismu list by form: short rafsi of each entry, then 4-letter and
  ##   5-letter rafsi of each gismu; stem `brod` that five gismu share enters once.
  for entry in LIST_GISMU:
    for one in entry.rafsi: result[one.form.get].add one
    if not entry.word.isGismu: continue
    let stem = entry.word[0 .. 3]
    if result[stem.form.get].len == 0 or result[stem.form.get][^1] != stem:
      result[stem.form.get].add stem
    result[entry.word.form.get].add entry.word


func constructKeywords(): seq[string] {.compileTime.} =
  ## Build keyword of every gismu of list, lowercase and sorted, for binary search.
  for entry in LIST_GISMU:
    if entry.word.isGismu: result.add entry.keyword.toLowerAscii
  result.sort


const
  SAMPLES = 10000  ## Random rafsi sequences pool holds; each random law reads all (IX.4).
  SAMPLES_FLOOR_ADDED = SAMPLES div 2
    ## Samples that must hold junction with no hyphen, where added hyphen law runs; 7100 read.
  SAMPLES_FLOOR_REMOVED = SAMPLES div 4
    ## Samples that must hold hyphen after short rafsi, where removal laws run; 3313 read.
  JUNCTIONS_FLOOR_IMPERMISSIBLE = 5000
    ## CVC rafsi before gismu whose pair 4.11 step 4b must read as impermissible; 5326 read.
  LENGTH_MIN = 2  ## Fewest rafsi of random sequence; lujvo has two or more (4.6).
  LENGTH_MAX = 5  ## Most rafsi of random sequence.
  ENTRIES_FLOOR_LOJBAN = 3000  ## Entries in Lojban notation whose parts must all be listed.
  ENTRIES_FLOOR_ENGLISH = 600  ## Entries in English notation whose parts must all be keywords.
  FORMS_MEDIAL = [Form.Cvc, Form.Ccv, Form.Cvv, Form.Cvcc, Form.Ccvc]
    ## Forms 4.11 step 1 allows before last rafsi: 3-letter or 4-letter.
  FORMS_LAST = [Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv]
    ## Forms 4.11 step 2 allows last: CVV, CCV or 5-letter.
  TRIPLES_NAMED = ["ndj", "ndz", "ntc", "nts"]  ## Triples 3.7 forbids by name.
  LUT_RAFSI_BY_FORM = constructRafsiByForm()  ## Every rafsi of gismu list, by form.
  KEYWORDS = constructKeywords()  ## Keyword of every gismu, lowercase, sorted.
  EXCEPTIONS_SPLIT = [
    "maicpukai",  # CVV opening three-part lujvo lacks `r` of 4.11 step 4a
    "natmyrgu'e",  # no segmentation at all: letter `r` after `natmy` fits no rafsi
  ]
    ## Entries of either notation that do not split exactly once, with reason.
  EXCEPTIONS_LOJBAN = [
    "kamfe'idzeseltru",  # list writes `dzena` before `fetsi`; word holds `fe'i` first
    "kamnakydzeseltru",  # list writes `dzena` before `nakni`; word holds `nak` first
    "mumcte",  # `mum` is rafsi of `mu`; list writes `re`
    "mumdei",  # `mum` is rafsi of `mu`; list writes `re`
    "mumdo'i",  # `mum` is rafsi of `mu`; list writes `re`
    "mumvanbi",  # `mum` is rafsi of `mu`; list writes `re`
    "narmitsi'u",  # `nar` is rafsi of `na`; list writes `na'e`, whose rafsi is `nal`
    "narselfendi",  # `nar` is rafsi of `na`; list writes `na'e`, whose rafsi is `nal`
    "nildicka'ukezyjdika",  # word holds `kez` of `kei`; list leaves it out
    "xavdei",  # `xav` is rafsi of `xa`; list writes `re`
    "xavdo'i",  # `xav` is rafsi of `xa`; list writes `re`
    "xavycte",  # `xav` is rafsi of `xa`; list writes `re`
    "xavyvanbi",  # `xav` is rafsi of `xa`; list writes `re`
  ]
    ## Entries in Lojban notation whose rafsi do not name listed parts in order, with reason.
  EXCEPTIONS_ENGLISH = [
    "natmyrgu'e",  # letter `r` after `natmy` fits no rafsi; `natmygu'e` would read
    "tolmipygau",  # word holds `tol` of cmavo `to'e`; list leaves it out
  ]
    ## Entries in English notation that read as no tag of listed keywords, with reason.


func rafsiSplit(word: string): seq[seq[string]] =
  ## Read rafsi of each segmentation `splitLujvo` finds in word.
  for pieces in word.splitLujvo: result.add pieces.mapIt(it.rafsi)


func isRoundTrip(rafsi: openArray[string], word: string): bool =
  ## Test rafsi join into word, and word splits back into those rafsi alone.
  joinRafsi(rafsi) == word and rafsiSplit(word) == @[@rafsi]


func spell(pieces: openArray[Piece], at = -1, letter = ""): string =
  ## Spell pieces with their hyphens; hyphen after piece `at` is replaced by `letter`.
  for i, piece in pieces:
    result.add piece.rafsi
    result.add(if i == at: letter else: LUT_LETTER_BY_HYPHEN[piece.hyphen])


func value(rafsi: string): int =
  ## Recover value 4.12 step 4 gives rafsi, from score of rafsi alone and formula of 4.12.
  let
    piece = Piece(rafsi: rafsi, form: rafsi.form.get)
    weighed = 1000 * rafsi.len - 500 * rafsi.count('\'') - rafsi.countIt(it in "aeiou")
  (weighed - score([piece])) div 10


func isStanding(piece: Piece, listed: Word): bool =
  ## Test piece stands for listed word: short rafsi by rafsi table, 4-letter rafsi by stem,
  ##   5-letter rafsi by word itself (4.6).
  case piece.form
  of Form.Cvc, Form.Ccv, Form.Cvv: piece.rafsi.wordRafsi == some(listed)
  of Form.Cvcc, Form.Ccvc: listed in piece.rafsi.wordsStem
  of Form.Cvccv, Form.Ccvcv: piece.rafsi.word == some(listed)


func isKeyword(part: string): bool =
  ## Test English part equals keyword of some gismu, case aside.
  KEYWORDS.binarySearch(part.toLowerAscii) >= 0


func isListed(word: string): bool =
  ## Test entry of `LIST_LUJVO` spells word.
  LIST_LUJVO.anyIt(it.word == word)


proc drawRafsi(): seq[seq[string]] =
  ## Draw `SAMPLES` rafsi sequences of positions 4.11 steps 1 and 2 allow, seeded once.
  ##   Form is drawn uniformly first, then rafsi of that form, so rare forms (CCVC, CV'V) come
  ##     as often as CVC.
  randomize(0)
  result = newSeq[seq[string]](SAMPLES)
  for sample in result.mitems:
    let length = rand(LENGTH_MIN .. LENGTH_MAX)
    sample = newSeqOfCap[string](length)
    for i in 0 ..< length:
      let chosen = (if i == length - 1: FORMS_LAST.sample else: FORMS_MEDIAL.sample)
      sample.add LUT_RAFSI_BY_FORM[chosen].sample


let SEQUENCES_RAFSI = drawRafsi()  ## Random rafsi sequences every random law reads, drawn once.


iterator rafsiRandom(): lent seq[string] =
  ## Serve each random rafsi sequence of pool, with no copy.
  for i in 0 ..< SEQUENCES_RAFSI.len: yield SEQUENCES_RAFSI[i]



suite "Chapter 3":
  test "Section 3.8":
    check isRoundTrip(["xap", "cke"], "xapcke")  # 3.8, Example 8.4; split inferred
    check isRoundTrip(["pon", "ni'u"], "ponyni'u")  # 3.8, Example 8.5; split inferred
    check isRoundTrip(["bong", "nanba"], "bongynanba")  # 3.8, Example 8.6; split inferred
    check rafsiSplit("bongnanba").len == 0  # 3.8, Example 8.7, "possible borrowing"


  test "Section 3.9":
    check isRoundTrip(["fit", "pri"], "fitpri")  # 3.9, Example 9.3; split inferred
    check isRoundTrip(["sai", "goi"], "sairgoi")  # 3.9, Example 9.4; split inferred
    check toPieces(["sai", "goi"])[0].hyphen == Hyphen.R  # 3.9, Example 9.4, `rg`; split inferred
    check isRoundTrip(["dik", "jvo"], "dikyjvo")  # 3.9, Example 9.6; split inferred
    check isRoundTrip(["bis", "dja"], "bisydja")  # 3.9, Example 9.11, affixes `bis` and `dja`
    check not isPairPermissible('s', 'd')  # 3.9, Example 9.11, "impermissible consonant pair"
    check toPieces(["bis", "dja"])[0].hyphen == Hyphen.Y  # 3.9, Example 9.11, `y` is inserted
    check isRoundTrip(["da'u", "dja"], "da'udja")  # 3.9, Example 9.12; split inferred



suite "Chapter 4":
  test "Section 4.5":
    check isRoundTrip(["mam", "pa'u"], "mampa'u")  # 4.5, Example 5.7, `mam-` and `-pa'u`
    check isRoundTrip(["soi", "sai"], "soirsai")  # 4.5, Example 5.8, additional `r`
    check rafsiSplit("soisai").len == 0  # 4.5, Example 5.8, would break up into `soi sai`
    for (rafsi, word) in [
      (@["bri", "vla"], "brivla"),
      (@["bri", "valsi"], "brivalsi"),
      (@["brid", "vla"], "bridyvla"),
      (@["brid", "valsi"], "bridyvalsi"),
    ]:
      check isRoundTrip(rafsi, word)  # 4.5, `brivla` is same lujvo as three others; split inferred


  test "Section 4.6":
    for (rafsi, word) in [
      (@["mamt", "patfu"], "mamtypatfu"),
      (@["lerf", "liste"], "lerfyliste"),
      (@["nanc", "prali"], "nancyprali"),
      (@["prun", "plipe"], "prunyplipe"),
      (@["vanc", "sanmi"], "vancysanmi"),
    ]:
      check isRoundTrip(rafsi, word)  # 4.6, Examples 6.1-5, unreduced lujvo; split inferred
    for (rafsi, word) in [
      (@["cum", "fri"], "cumfri"),
      (@["kle", "zba"], "klezba"),
      (@["kix", "ta'a"], "kixta'a"),
      (@["sni", "ju'o"], "sniju'o"),
      (@["mam", "pa'u"], "mampa'u"),
      (@["ler", "ste"], "lerste"),
    ]:
      check isRoundTrip(rafsi, word)  # 4.6, Examples 6.6-11, fully reduced lujvo; split inferred
    check isRoundTrip(["pat", "ta'a"], "patyta'a")  # 4.6, must be `patyta'a`; split inferred
    check rafsiSplit("patta'a").len == 0  # 4.6, `tt` is not permissible consonant pair
    check isRoundTrip(["mud", "siclu"], "mudysiclu")  # 4.6, must be used; split inferred
    check rafsiSplit("mudsiclu").len == 0  # 4.6, `mudri siclu` "cannot form" `mudsiclu`
    let
      score_zuljma = score(toPieces(["zul", "jma"]))
      forms_zunle_jamfu = [
        (@["zunl", "jamfu"], "zunlyjamfu"),
        (@["zunl", "jma"], "zunlyjma"),
        (@["zul", "jamfu"], "zuljamfu"),
        (@["zul", "jma"], "zuljma"),
      ]
    for (rafsi, word) in forms_zunle_jamfu:
      check isRoundTrip(rafsi, word)  # 4.6, "all legitimate and equivalent forms"; split inferred
      if word != "zuljma":
        check score_zuljma < score(toPieces(rafsi))  # 4.6, `zuljma` preferred; split inferred
    check isRoundTrip(["ro'i", "re'o"], "ro'inre'o")  # 4.6, `n`-hyphen required; split inferred
    check rafsiSplit("ro'ire'o").len == 0  # 4.6, "breaks up into two cmavo"
    check rafsiSplit("ro'irre'o").len == 0  # 4.6, "impermissible double consonant"
    check isRoundTrip(["rok", "re'o"], "rokre'o")  # 4.6, without hyphenation; split inferred
    for first in LUT_RAFSI_BY_FORM[Form.Cvv]:  # every CVV rafsi of list, exhaustive
      for second in LUT_RAFSI_BY_FORM[Form.Cvv]:
        let expected = (if second[0] == 'r': Hyphen.N else: Hyphen.R)
        check hyphensRafsi([first, second])[0] == expected  # 4.6, CVV-CVV always takes hyphen
      for last in LUT_RAFSI_BY_FORM[Form.Cvccv] & LUT_RAFSI_BY_FORM[Form.Ccvcv]:
        let expected = (if last[0] == 'r': Hyphen.N else: Hyphen.R)
        check hyphensRafsi([first, last])[0] == expected  # 4.6, CVV-CVC/CV and CVV-CCVCV


  test "Section 4.11":
    for one in Form:  # every rafsi of list alone, exhaustive
      for rafsi in LUT_RAFSI_BY_FORM[one]:
        check rafsiSplit(rafsi).len == 0  # 4.6, lujvo has two or more rafsi; 4.11 steps 1-2
    for last in LUT_RAFSI_BY_FORM[Form.Cvc]:  # every CVC rafsi of list, exhaustive
      check rafsiSplit("zda" & last).len == 0  # 4.6, CVC-form rafsi cannot appear as final
    for last in LUT_RAFSI_BY_FORM[Form.Cvcc] & LUT_RAFSI_BY_FORM[Form.Ccvc]:  # exhaustive
      check rafsiSplit("zda" & last).len == 0  # 4.11 step 2, 4-letter rafsi never last
    check rafsiSplit("gerzdan").len == 0  # 4.11 step 2, 4.13 leaves `-zdan-` out; constructed
    for first in LUT_RAFSI_BY_FORM[Form.Cvccv] & LUT_RAFSI_BY_FORM[Form.Ccvcv]:  # exhaustive
      check @[first, "zda"] notin rafsiSplit(first & "zda")  # 4.11 step 1, 5-letter never medial
    check rafsiSplit("gerkuzdani").len == 0  # 4.11 step 1, 4.13 leaves `-gerku` out; constructed
    check isRoundTrip(["sai", "cli"], "saicli")  # 4.11 step 4a, no hyphen; split inferred
    check isRoundTrip(["ro'i", "re'o"], "ro'inre'o")  # 4.11 step 4a, `n` before `r`; split inferred
    check isRoundTrip(["sai", "zba", "ta'u"], "sairzbata'u")  # 4.11 step 4a; rafsi of Example 12.3
    for first in LUT_RAFSI_BY_FORM[Form.Cvv]:  # every CVV and CCV rafsi of list, exhaustive
      for second in LUT_RAFSI_BY_FORM[Form.Ccv]:
        check hyphensRafsi([first, second]) == @[Hyphen.None, Hyphen.None]  # 4.11 step 4a, two
        check hyphensRafsi([first, second, "zba"])[0] == Hyphen.R  # 4.11 step 4a, more than two
    var
      finals: seq[string]  # first gismu of list for each initial consonant
      count_impermissible = 0
    for last in LUT_RAFSI_BY_FORM[Form.Cvccv] & LUT_RAFSI_BY_FORM[Form.Ccvcv]:
      if finals.allIt(it[0] != last[0]): finals.add last
    check finals.len == CONSONANTS.card  # 3.6, each of seventeen consonants starts gismu of list
    for first in LUT_RAFSI_BY_FORM[Form.Cvc]:  # every CVC rafsi of list, exhaustive
      for last in finals:
        if isPairPermissible(first[^1], last[0]): continue
        check hyphensRafsi([first, last])[0] == Hyphen.Y  # 4.11 step 4b
        inc count_impermissible
    check count_impermissible >= JUNCTIONS_FLOOR_IMPERMISSIBLE  # Article IX.3, guard leaves enough
    for stem in LUT_RAFSI_BY_FORM[Form.Cvcc] & LUT_RAFSI_BY_FORM[Form.Ccvc]:  # exhaustive
      let after_cvv = (if stem[0] == 'r': Hyphen.N else: Hyphen.R)
      check hyphensRafsi([stem, "zda"])[0] == Hyphen.Y  # 4.11 step 4c
      check hyphensRafsi(["sai", stem, "zda"]) == @[after_cvv, Hyphen.Y, Hyphen.None]  # 4.11 4a, 4c
    check rafsiSplit("tosmabru").len == 0  # 4.11 step 5, `tosmabru` failure
    for (rafsi, word) in [
      (@["cak", "respa"], "cakyrespa"),
      (@["cib", "laj", "ter", "kruca"], "cibylajyterkruca"),
      (@["det", "sel", "lacri"], "detyselylacri"),
      (@["dig", "lig", "kamju"], "digyligykamju"),
      (@["puc", "ter", "runta"], "pucyteryrunta"),
      (@["xas", "mabru"], "xasymabru"),
    ]:
      check word.isListed  # `LIST_LUJVO` spells it
      check isRoundTrip(rafsi, word)  # 4.11 step 5c, `y` at first joint; word of `LIST_LUJVO`
    check isRoundTrip(["tos", "mabru"], "tosymabru")  # 4.11 step 5c; constructed
    check isRoundTrip(["tos", "tos", "mabru"], "tosytosmabru")  # 4.11 step 5c, one `y`; constructed
    check isRoundTrip(["tos", "tod", "dru"], "tosytodydru")  # 4.11 step 5a, up to `y`; constructed
    check isRoundTrip(["tof", "mabru"], "tofmabru")  # 4.11 step 5b, `fm` not initial; constructed
    check rafsiSplit("tofymabru").len == 0  # 4.11 step 4, hyphen not required; constructed


  test "Section 4.12":
    for (rafsi, expected) in [
      ("sarji", 1), ("sarj", 2), ("zbasu", 3), ("zbas", 4),
      ("nun", 5), ("ta'u", 6), ("zba", 7), ("sai", 8),
    ]:
      check rafsi.value == expected  # 4.12 step 4, table of rafsi values
    check isRoundTrip(["zba", "sai"], "zbasai")  # 4.12, Example 12.1
    check score(toPieces(["zba", "sai"])) == 5847  # 4.12, Example 12.1
    check isRoundTrip(["nun", "nau"], "nunynau")  # 4.12, Example 12.2
    check score(toPieces(["nun", "nau"])) == 6967  # 4.12, Example 12.2
    check isRoundTrip(["sai", "zba", "ta'u"], "sairzbata'u")  # 4.12, Example 12.3
    check score(toPieces(["sai", "zba", "ta'u"])) == 10385  # 4.12, Example 12.3
    check isRoundTrip(["zba", "zbas", "sarji"], "zbazbasysarji")  # 4.12, Example 12.4
    check score(toPieces(["zba", "zbas", "sarji"])) == 12976  # 4.12, Example 12.4


  test "Section 4.13":
    let forms_gerku_zdani = [
      (@["ger", "zda"], "gerzda", 5878),
      (@["ger", "zdani"], "gerzdani", 7917),
      (@["ge'u", "zda"], "ge'uzda", 6367),
      (@["ge'u", "zdani"], "ge'urzdani", 9506),
      (@["gerk", "zda"], "gerkyzda", 8008),
      (@["gerk", "zdani"], "gerkyzdani", 10047),
    ]
    for (rafsi, word, expected) in forms_gerku_zdani:
      check isRoundTrip(rafsi, word)  # 4.13, six forms of `gerku zdani`
      check score(toPieces(rafsi)) == expected  # 4.13, 5878 right though V of `gerzda` is 2
      check score(toPieces(["ger", "zda"])) <= expected  # 4.13, `gerzda` would win
    let forms_bloti_klesi = [
      (@["lot", "kle"], "lotkle", 5878),
      (@["blo", "kle"], "blokle", 5858),
      (@["lo'i", "kle"], "lo'ikle", 6367),
      (@["lot", "lei"], "lotlei", 5867),
      (@["blo", "lei"], "blolei", 5847),
      (@["lo'i", "lei"], "lo'irlei", 7456),
    ]
    for (rafsi, word, expected) in forms_bloti_klesi:
      check isRoundTrip(rafsi, word)  # 4.13, six forms of `bloti klesi`
      check score(toPieces(rafsi)) == expected  # 4.13, table of six scores
      check score(toPieces(["blo", "lei"])) <= expected  # 4.13, `blolei` is preferred
    for first in ["lot", "blo", "lo'i", "blot"]:
      for last in ["kle", "lei", "klesi"]:
        let rafsi = @[first, last]
        check rafsiSplit(joinRafsi(rafsi)) == @[rafsi]  # 4.13, "six further forms" valid too
    for (rafsi, word) in [
      (@["loj", "ban", "gri"], "lojbangri"),
      (@["loj", "bau", "gri"], "lojbaugri"),
      (@["loj", "bang", "gri"], "lojbangygri"),
      (@["logj", "ban", "gri"], "logjybangri"),
      (@["logj", "bau", "gri"], "logjybaugri"),
      (@["logj", "bang", "gri"], "logjybangygri"),
      (@["loj", "ban", "girzu"], "lojbangirzu"),
      (@["loj", "bau", "girzu"], "lojbaugirzu"),
      (@["loj", "bang", "girzu"], "lojbangygirzu"),
      (@["logj", "ban", "girzu"], "logjybangirzu"),
      (@["logj", "bau", "girzu"], "logjybaugirzu"),
      (@["logj", "bang", "girzu"], "logjybangygirzu"),
    ]:
      check isRoundTrip(rafsi, word)  # 4.13, twelve forms of `logji bangu girzu`
    check score(toPieces(["loj", "ban", "gri"])) == 8827  # 4.13, "8827 versus 8796"
    check score(toPieces(["loj", "bau", "gri"])) == 8796  # 4.13, "8827 versus 8796"
    let forms_nakni_ke_cinse_ctuca = [
      (@["nak", "kem", "cin", "ctu"], "nakykemcinctu"),
      (@["nak", "kem", "cin", "ctuca"], "nakykemcinctuca"),
      (@["nak", "kem", "cins", "ctu"], "nakykemcinsyctu"),
      (@["nak", "kem", "cins", "ctuca"], "nakykemcinsyctuca"),
      (@["nakn", "kem", "cin", "ctu"], "naknykemcinctu"),
      (@["nakn", "kem", "cin", "ctuca"], "naknykemcinctuca"),
      (@["nakn", "kem", "cins", "ctu"], "naknykemcinsyctu"),
      (@["nakn", "kem", "cins", "ctuca"], "naknykemcinsyctuca"),
    ]
    for (rafsi, word) in forms_nakni_ke_cinse_ctuca:
      check isRoundTrip(rafsi, word)  # 4.13, eight forms of `nakni ke cinse ctuca`
      if word != "nakykemcinctu":
        check score(toPieces(["nak", "kem", "cin", "ctu"])) < score(toPieces(rafsi))  # 4.13



suite "Chapter 7":
  test "Section 7.15":
    check isRoundTrip(["don", "ta'a"], "donta'a")  # 7.15, `tavla be do`; split inferred
    check isRoundTrip(["don", "ma'o"], "donma'o")  # 7.15, `cmavo be zo do`; split inferred
    check isRoundTrip(["fo'a", "sel", "sanga"], "fo'arselsanga")  # Example 15.3; split inferred
    check isRoundTrip(["zil", "rel", "sel", "pinxe"], "zilrelselpinxe")  # 7.15; split inferred
    check isRoundTrip(["zil", "pav", "pinxe"], "zilpavypinxe")  # 7.15, x1 deleted; split inferred



suite "Internal: Convention":
  test "Forbidden triple at junction takes y":
    check "kanydzu".isListed and "penydjuxa'a".isListed  # `LIST_LUJVO` spells both
    check isRoundTrip(["kan", "dzu"], "kanydzu")  # 3.7 forbids `ndz`; 4.11 step 4b silent
    check isRoundTrip(["pen", "dju", "xa'a"], "penydjuxa'a")  # 3.7 forbids `ndj`; 4.11 silent
    check isRoundTrip(["ban", "tsa"], "banytsa")  # 3.7 forbids `nts`; 4.11 silent; constructed
    check rafsiSplit("kandzu").len == 0  # convention: literal 4.11 form breaks 3.7; constructed
    for triple in TRIPLES_NAMED:
      let rafsi = ["ka" & triple[0], triple[1 .. 2] & "a"]
      check isPairPermissible(triple[0], triple[1])  # 4.11 step 4b alone adds no `y` here
      check hyphensRafsi(rafsi)[0] == Hyphen.Y  # convention: `y` breaks triple 3.7 names


  test "CVC then CCV takes y exactly where cluster breaks 3.6 or 3.7":
    for first in LUT_RAFSI_BY_FORM[Form.Cvc]:  # every CVC and CCV rafsi of list, exhaustive
      for last in LUT_RAFSI_BY_FORM[Form.Ccv]:
        let is_broken = not isPairPermissible(first[^1], last[0]) or
            not isTriplePermissible(first[^1], last[0], last[1])
        check (hyphensRafsi([first, last])[0] == Hyphen.Y) == is_broken  # 4.11 4b, convention



suite "Internal: Laws":
  test "Split inverts join over every form pattern of two and three rafsi":
    for first in FORMS_MEDIAL:  # first rafsi of list in each form stands for it
      for last in FORMS_LAST:
        let rafsi = @[LUT_RAFSI_BY_FORM[first][0], LUT_RAFSI_BY_FORM[last][0]]
        check rafsiSplit(joinRafsi(rafsi)) == @[rafsi]  # law: split after join is identity, once
        for middle in FORMS_MEDIAL:
          let longer = @[rafsi[0], LUT_RAFSI_BY_FORM[middle][0], rafsi[1]]
          check rafsiSplit(joinRafsi(longer)) == @[longer]  # law: split after join is identity


  test "Split inverts join over random rafsi":
    for rafsi in rafsiRandom():  # `SAMPLES` sequences, seeded
      check rafsiSplit(joinRafsi(rafsi)) == @[rafsi]  # law: split after join is identity, once


  test "Split inverts join over rafsi form list assigns to no word":
    skip()  # Article IX.4, gap: random rafsi come from gismu list alone


  test "Join makes brivla over random rafsi":
    for rafsi in rafsiRandom():  # `SAMPLES` sequences, seeded
      check joinRafsi(rafsi).isBrivla  # law: lujvo keeps brivla properties (4.3, 4.5)


  test "Segmentation keeps rafsi where required hyphen after short rafsi is removed":
    var count_removed = 0
    for rafsi in rafsiRandom():  # `SAMPLES` sequences, seeded
      let pieces = toPieces(rafsi)
      var is_removed = false
      for i in 0 ..< pieces.high:
        if pieces[i].hyphen == Hyphen.None or pieces[i].form notin FORMS_SHORT: continue
        let segments = spell(pieces, i).segmentLujvo.mapIt(it.mapIt(it.rafsi))
        check rafsi in segments  # law: reader still finds rafsi, so names form 4.11 gives
        is_removed = true
      if is_removed: inc count_removed
    check count_removed >= SAMPLES_FLOOR_REMOVED  # Article IX.3, guard leaves enough samples


  test "Hyphen added or removed breaks split over random rafsi":
    check rafsiSplit("kramyliste") == @[@["kram", "liste"]]  # 4.11 step 4c; constructed
    check rafsiSplit("kramliste") == @[@["kra", "mli", "ste"]]  # law: other lujvo; constructed
    var
      count_added = 0
      count_removed = 0
    for rafsi in rafsiRandom():  # `SAMPLES` sequences, seeded
      let pieces = toPieces(rafsi)
      var is_added, is_removed = false
      for i in 0 ..< pieces.high:
        if pieces[i].hyphen == Hyphen.None:
          for letter in ["y", "r", "n"]:
            check rafsiSplit(spell(pieces, i, letter)).len == 0  # law: added hyphen (4.11 step 4)
          is_added = true
        elif pieces[i].form in FORMS_SHORT:
          check rafsiSplit(spell(pieces, i)).len == 0  # law: hyphen after short rafsi removed
          is_removed = true
      if is_added: inc count_added
      if is_removed: inc count_removed
    check count_added >= SAMPLES_FLOOR_ADDED  # Article IX.3, guard leaves enough samples
    check count_removed >= SAMPLES_FLOOR_REMOVED  # Article IX.3, guard leaves enough samples


  test "Corpus splits exactly once in either notation":
    var failing: seq[string]
    for line in LIST_LUJVO:  # every entry, both notations, exhaustive
      if line.word.splitLujvo.len != 1: failing.add line.word
    check failing.sorted == EXCEPTIONS_SPLIT.sorted  # law: entry splits once, pinned ones aside


  test "Corpus in Lojban notation splits into listed parts":
    var
      count = 0
      failing: seq[string]
    for line in LIST_LUJVO:
      if line.notation != Notation.Lojban: continue
      let parts = line.parts.mapIt(it.word)
      if not parts.allIt(it.isSome): continue
      inc count
      let splits = line.word.splitLujvo
      var is_resolved = splits.len == 1 and splits[0].len == parts.len
      if is_resolved:
        for i, piece in splits[0]:
          is_resolved = is_resolved and piece.isStanding(parts[i].get)
      if not is_resolved: failing.add line.word
    check count >= ENTRIES_FLOOR_LOJBAN  # Article IX.3, guard leaves enough entries
    check failing.sorted == EXCEPTIONS_LOJBAN.sorted  # law: rafsi name parts in order


  test "Corpus in English notation reads as listed keywords":
    var
      count = 0
      failing: seq[string]
    for line in LIST_LUJVO:
      if line.notation != Notation.English or not line.parts.allIt(it.isKeyword): continue
      inc count
      let reading = line.word.readTag
      var is_read = reading.is_tag and reading.tag.words.len == line.parts.len
      if is_read:
        for i, found in reading.tag.words:
          is_read = is_read and cmpIgnoreCase(found.entry.keyword, line.parts[i]) == 0
      if not is_read: failing.add line.word
    check count >= ENTRIES_FLOOR_ENGLISH  # Article IX.3, guard leaves enough entries
    check failing.sorted == EXCEPTIONS_ENGLISH.sorted  # law: tag holds keywords list writes
