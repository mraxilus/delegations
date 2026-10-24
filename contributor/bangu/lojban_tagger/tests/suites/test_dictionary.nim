## Replicate rafsi and gismu CLL chapter 4 names against lookups of `dictionary.nim`.
##   Every entry, every short rafsi, and every string of short or 4-letter rafsi form is looked
##     up, so each lookup is held over its whole domain (Article IX.3); spellings outside list
##     are sampled, seeded, as one-letter mutations of listed words.
##   Each lookup is held to linear scan of `LIST_GISMU`, written here apart from binary search
##     of `dictionary.nim`, so sorted tables and search agree with list they come from.
##   Each test seeds generator once, draws its samples into pool, and iterator serves pool.
##   Vectors are gismu and lujvo CLL names in 4.4, 4.6, 4.13, 4.14 and 4.15; each rafsi of each
##     is looked up by name, never by number. Where CLL gives lujvo without its rafsi split,
##     citation says `split inferred`; string no source holds is marked `constructed`.
##   Internal suite holds what CLL does not state: kind of each word, order, rendering, fields.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[dictionary, forms]
import ../../src/lojban_tagger/lists/gismu


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"  ## Seventeen consonants C stands for (4.1 rule 3).
  ORDER_VOWELS = "aeiou"  ## Five vowels V stands for, `y` excluded (4.1 rule 1).
  ALPHABET = "',.abcdefgijklmnoprstuvxyz"  ## Letters of 3.1, apostrophe, comma and period.
  RAFSI_BLACI = ["bac", "lac", "ba'i", "bai", "la'i", "lai", "bla"]
    ## Short rafsi 4.6 table lets `blaci` have, all assigned elsewhere.
  GISMU_ASSIGNABLE = ["broda", "brode", "brodi", "brodo", "brodu"]
    ## Assignable predicates of 4.15, which differ in final vowel alone (4.4).
  GISMU_COINED = ["cmavo", "lojbo", "lujvo", "mekso"]  ## Other coined gismu of 4.15.
  GISMU_METRIC_SMALL = [
    "decti", "centi", "milti", "mikri", "nanvi", "picti", "femti", "xatsi", "zepti", "gocti",
  ]
    ## Small metric prefixes of 4.15.
  GISMU_METRIC_LARGE = [
    "dekto", "xecto", "kilto", "megdo", "gigdo", "terto", "petso", "xexso", "zetro", "gotro",
  ]
    ## Large metric prefixes of 4.15.
  GISMU_SCIENTIFIC = ["delno", "kelvo", "molro", "radno", "sinso", "stero", "tanjo", "xampo"]
    ## Other scientific or mathematical terms of 4.15.
  GISMU_CULTURAL = [
    "jungo", "glico", "xindo", "spano", "rusko", "xrabo",
    "bengo", "porto", "baxso", "ponjo", "dotco", "fraso", "xurdo",
    "merko", "brito", "skoto", "sralo", "kadno", "gento", "mexno", "softo", "vukro",
    "filso", "jerxo", "jordo", "libjo", "lubno", "misro", "morko", "rakso", "sadjo", "sirxo",
    "bindo", "meljo", "brazo", "kisto",
    "bemro", "dzipo", "ketco", "friko", "polno", "ropno", "xazdo",
    "latmo", "srito", "xebro", "xelso",
    "budjo", "dadjo", "muslo", "xriso",
    "jegvo", "semto", "slovo", "xispo",
  ]
    ## Cultural gismu of 4.15, in page order: source languages, seven others, countries,
    ## continents, cultures, religions, then terms covering several groups.
  COUNT_LISTED_4_15 = 92  ## Gismu 4.15 lists, counted on page; CLL states no count.
  SAMPLES_MUTATION = 20000  ## Listed words mutated in one letter and looked up, seeded.
  FLOOR_UNLISTED = 9450
    ## Least of those mutations absent from list, so miss stays tested: half of 18905 read at
    ## seed 0.
  FLOOR_LISTED = 177
    ## Least of those mutations landing on other entry, so hit stays tested: half of 354 read
    ## at seed 0.
  SAMPLES_PAIRS = 20000  ## Pairs of words compared, seeded.
  STEMS_4_13 = [
    ("gerk", "gerku"), ("zdan", "zdani"), ("logj", "logji"), ("bang", "bangu"),
    ("girz", "girzu"), ("nakn", "nakni"), ("cins", "cinse"),
  ]
    ## 4-letter rafsi 4.13 writes in its examples, each with its gismu.


func positionsNotation(notation: string): seq[string] =
  ## Read letters each position of 4.1 notation admits: `C`, `V`, or symbol as written.
  for symbol in notation:
    result.add(
      case symbol
      of 'C': ORDER_CONSONANTS
      of 'V': ORDER_VOWELS
      else: $symbol
    )


iterator texts(positions: seq[string]): string =
  ## Yield every string taking one letter from set of each position, last position fastest.
  var
    at = newSeq[int](positions.len)
    text = newString(positions.len)
  for i, letters in positions: text[i] = letters[0]
  var is_done = false
  while not is_done:
    yield text
    var i = positions.high
    while i >= 0:
      inc at[i]
      if at[i] < positions[i].len:
        text[i] = positions[i][at[i]]
        break
      at[i] = 0
      text[i] = positions[i][0]
      dec i
    is_done = i < 0


iterator words(): Word =
  ## Yield every word of gismu list, in list order.
  for i in 0..<LIST_GISMU.len: yield Word(i)


func wordScanned(text: string): Option[Word] =
  ## Find entry spelled `text` by linear scan of list, apart from `word`.
  for i, entry in LIST_GISMU:
    if entry.word == text: return some(Word(i))
  none(Word)


func wordRafsiScanned(text: string): Option[Word] =
  ## Find word short rafsi `text` stands for by linear scan of list, apart from `wordRafsi`.
  for i, entry in LIST_GISMU:
    if text in entry.rafsi: return some(Word(i))
  none(Word)


func wordsStemScanned(text: string): seq[Word] =
  ## Find gismu that `text` begins, four letters, by linear scan of list, apart from `wordsStem`.
  if text.len != 4: return
  for i, entry in LIST_GISMU:
    if entry.word.len == 5 and entry.word.startsWith(text): result.add Word(i)


func isAssigned(rafsi, gismu: string): bool =
  ## Test short rafsi `rafsi` stands for listed word `gismu`.
  word(gismu).isSome and wordRafsi(rafsi) == word(gismu)


func rafsiSorted(text: string): seq[string] =
  ## Read short rafsi list assigns word `text`, sorted; empty where list lacks word.
  let found = word(text)
  if found.isSome: result = sorted(found.get.entry.rafsi)


proc mutate(text: string): string =
  ## Replace one letter of `text`, chosen at random, by letter of 3.1.
  result = text
  result[rand(text.high)] = sample(ALPHABET)


proc drawMutated(): seq[(string, string)] =
  ## Draw `SAMPLES_MUTATION` listed words, each beside copy mutated in one letter, as seeded.
  result = newSeqOfCap[(string, string)](SAMPLES_MUTATION)
  for _ in 1..SAMPLES_MUTATION:
    let source = LIST_GISMU[rand(LIST_GISMU.high)].word
    result.add (source, mutate(source))


proc drawPairs(): seq[(Word, Word)] =
  ## Draw `SAMPLES_PAIRS` pairs of listed words, as seeded.
  result = newSeqOfCap[(Word, Word)](SAMPLES_PAIRS)
  for _ in 1..SAMPLES_PAIRS:
    let (i, j) = (rand(LIST_GISMU.high), rand(LIST_GISMU.high))
    result.add (Word(i), Word(j))


iterator samples[T](pool: seq[T]): lent T =
  ## Serve each sample of preallocated pool, with no copy.
  for i in 0..<pool.len: yield pool[i]



suite "Chapter 4":
  test "Section 4.4":
    for text in ["creka", "lijda", "blanu", "mamta", "cukta", "patfu", "nanmu", "ninmu"]:
      check word(text).isSome  # 4.4, Examples 3.1-3.8 as page labels them
    check word("gismu").isSome  # 4.4, `gismu` is in set of gismu
    for text in ["kismu", "xismu", "gicmu", "gizmu", "gisnu"]:
      check word(text).isNone  # 4.4, these "cannot be"
    for w in words():
      let text = $w
      if text.len != 5: continue
      let found = wordsStem(text[0..3])
      check w in found  # 4.6, 4-letter rafsi is gismu less final vowel
      if text.startsWith("brod"): check found.mapIt($it) == @GISMU_ASSIGNABLE  # 4.4, `broda`
      else: check found == @[w]  # 4.4, no two gismu differ only in final vowel


  test "Section 4.6":
    var count_rafsi = 0
    for w in words():
      for one in w.entry.rafsi:
        inc count_rafsi
        check wordRafsi(one) == some(w)  # 4.6, "each such rafsi represents only one gismu"
    var count_found = 0
    for notation in ["CVC", "CCV", "CVV", "CV'V"]:
      for text in texts(positionsNotation(notation)):  # 3740 strings, exhaustive
        let found = wordRafsi(text)
        check found == wordRafsiScanned(text)  # 4.6, rafsi fixed by list, not reassigned
        if found.isSome: inc count_found
    check count_found == count_rafsi  # 4.6, listed short rafsi found, and no other
    check wordRafsi("").isNone and wordRafsi("brod").isNone  # 4.6, short rafsi three letters
    check wordRafsi("sakli").isNone  # 4.6, gismu itself is 5-letter rafsi, not short one
    check wordRafsi("SAL").isNone  # 3.1, capitals only in names; constructed
    check wordRafsi("sal").isSome  # 4.6, "only actual short rafsi" of `sakli`
    check word("zmadu").get.entry.rafsi == @["zma", "mau"]  # 4.6, `zmadu` has `zma` and `mau`
    check isAssigned("zma", "zmadu") and isAssigned("mau", "zmadu")  # 4.6, `zmadu`
    check word("bakri").get.entry.rafsi.len == 0  # 4.6, `bakri` "has no short rafsi"
    check word("sakli").get.entry.rafsi == @["sal"]  # 4.6, "only actual short rafsi"
    check word("blaci").get.entry.rafsi.len == 0  # 4.6, `blaci` "has none of these"
    for one in RAFSI_BLACI:
      let found = wordRafsi(one)
      check found.isSome and found != word("blaci")  # 4.6, "all assigned to other gismu"
      check found.isSome and found.get.kind == Kind.Gismu  # 4.6, "assigned to other gismu"
    check word("mamta").get.entry.rafsi == @["mam"]  # 4.6, only `mam` "is assigned to it"
    check not isAssigned("mat", "mamta") and not isAssigned("ma'a", "mamta")  # 4.6, `mamta`
    check isAssigned("cum", "cumki")  # 4.6, Example 6.6 `cumfri`, split inferred
    check isAssigned("fri", "lifri")  # 4.6, Example 6.6 `cumfri`, split inferred
    check isAssigned("kle", "klesi")  # 4.6, Example 6.7 `klezba`; 4.13 names `kle`
    check isAssigned("zba", "zbasu")  # 4.6, Example 6.7 `klezba`, split inferred
    check isAssigned("kix", "krixa")  # 4.6, Example 6.8 `kixta'a`, split inferred
    check isAssigned("ta'a", "tavla")  # 4.6, Example 6.8 `kixta'a`, split inferred
    check isAssigned("sni", "sinxa")  # 4.6, Example 6.9 `sniju'o`, split inferred
    check isAssigned("ju'o", "djuno")  # 4.6, Example 6.9 `sniju'o`, split inferred
    check isAssigned("mam", "mamta")  # 4.6, Example 6.10 `mampa'u`; `mam` "is assigned to it"
    check isAssigned("pa'u", "patfu")  # 4.6, Example 6.10 `mampa'u`, split inferred
    check isAssigned("ler", "lerfu")  # 4.6, Example 6.11 `lerste`, split inferred
    check isAssigned("ste", "liste")  # 4.6, Example 6.11 `lerste`, split inferred
    check isAssigned("pat", "pante")  # 4.6, `patyta'a`, split inferred
    check isAssigned("mud", "mudri")  # 4.6, `mudysiclu`, split inferred
    check isAssigned("zul", "zunle") and isAssigned("jma", "jamfu")  # 4.6, `zuljma`, split inferred
    check isAssigned("ro'i", "rokci")  # 4.6, `ro'inre'o`, split inferred
    check isAssigned("re'o", "renro")  # 4.6, `ro'inre'o`, split inferred
    check isAssigned("rok", "rokci")  # 4.6, `rokre'o`, split inferred
    var count_digits = 0
    for w in words():
      let definition = w.entry.definition
      if not (definition.startsWith("digit/number: ") and definition.endsWith(" (digit)")):
        continue
      inc count_digits
      let text = $w
      check w.kind == Kind.Cmavo and text.len == 2  # 4.6, digits "are all CV form cmavo"
      check text[0] in ORDER_CONSONANTS and text[1] in ORDER_VOWELS  # 4.6, "CV form cmavo"
      let rafsi_added = w.entry.rafsi.filterIt(it.form == some(Form.Cvc) and it.startsWith(text))
      check rafsi_added.len == 1  # 4.6, CVC rafsi is cmavo plus consonant
    check count_digits == 10  # 4.6, "ten common numerical digits"
    var count_cmavo, count_cmavo_cvc, count_ccv_cvv, count_three, count_cvc_other = 0
    for w in words():
      let forms_held = w.entry.rafsi.mapIt(it.form.get)
      if w.kind == Kind.Cmavo:
        count_cmavo += forms_held.len
        count_cmavo_cvc += forms_held.countIt(it == Form.Cvc)
        continue
      if Form.Ccv in forms_held and Form.Cvv in forms_held: inc count_ccv_cvv
      if forms_held.len == 3: inc count_three
      if Form.Cvc in forms_held and forms_held.len >= 2: inc count_cvc_other
    check 2 * count_cmavo_cvc > count_cmavo  # 4.6, cmavo rafsi "usually CVC-form"
    check count_three < count_ccv_cvv  # 4.6, "still fewer have all three forms"
    check count_ccv_cvv < count_cvc_other  # 4.6, CVC and other short rafsi "fairly common"


  test "Section 4.13":
    check rafsiSorted("gerku") == sorted(@["ger", "ge'u"])  # 4.13, every rafsi of `gerku` listed
    check isAssigned("ger", "gerku") and isAssigned("ge'u", "gerku")  # 4.13, `gerku zdani`
    check rafsiSorted("zdani") == @["zda"]  # 4.13, every rafsi of `zdani` listed
    check isAssigned("zda", "zdani")  # 4.13, `gerku zdani`
    check rafsiSorted("bloti") == sorted(@["lot", "blo", "lo'i"])  # 4.13, short rafsi of `bloti`
    check isAssigned("lot", "bloti") and isAssigned("blo", "bloti")  # 4.13, `bloti klesi`
    check isAssigned("lo'i", "bloti")  # 4.13, `bloti klesi`
    check rafsiSorted("klesi") == sorted(@["kle", "lei"])  # 4.13, short rafsi of `klesi`
    check isAssigned("kle", "klesi") and isAssigned("lei", "klesi")  # 4.13, `bloti klesi`
    check rafsiSorted("logji") == @["loj"]  # 4.13, "available rafsi" of `logji`
    check isAssigned("loj", "logji")  # 4.13, `logji bangu girzu`
    check rafsiSorted("bangu") == sorted(@["ban", "bau"])  # 4.13, "available rafsi" of `bangu`
    check isAssigned("ban", "bangu") and isAssigned("bau", "bangu")  # 4.13, `logji bangu girzu`
    check rafsiSorted("girzu") == sorted(@["gri", "gir"])  # 4.13, "available rafsi" of `girzu`
    check isAssigned("gri", "girzu")  # 4.13, `logji bangu girzu`
    check isAssigned("gir", "girzu")  # 4.13, `gir` "for name purposes only"
    check isAssigned("nak", "nakni") and isAssigned("kem", "ke")  # 4.13, `nak-kem-cin-ctu`
    check isAssigned("cin", "cinse") and isAssigned("ctu", "ctuca")  # 4.13, `nak-kem-cin-ctu`
    for (stem, gismu) in STEMS_4_13:
      check wordsStem(stem).mapIt($it) == @[gismu]  # 4.13, 4-letter rafsi of examples


  test "Section 4.14":
    for text in ["bradi", "bredi", "bridi", "brodi"]:
      check word(text).isSome  # 4.14, "are all existing gismu"
    check word("brudi").isNone  # 4.14, "but fortunately not brudi"


  test "Section 4.15":
    let groups = [
      @GISMU_ASSIGNABLE, @GISMU_COINED, @GISMU_METRIC_SMALL, @GISMU_METRIC_LARGE,
      @GISMU_SCIENTIFIC, @GISMU_CULTURAL,
    ]
    check concat(groups).deduplicate.len == COUNT_LISTED_4_15  # 4.15, every gismu page lists, once
    for group in groups:
      for text in group:
        let found = word(text)
        check found.isSome and found.get.kind == Kind.Gismu  # 4.15, full-fledged gismu
        if group != @GISMU_METRIC_SMALL and group != @GISMU_ASSIGNABLE:
          check text[^1] == 'o'  # 4.15, all end in `o` but small metric and `brod-`



suite "Internal: Dictionary":
  test "Kind follows shape of gismu":
    var count_gismu, count_cmavo = 0
    for w in words():
      let is_gismu = w.kind == Kind.Gismu
      check is_gismu == ($w).isBrivla  # kind agrees with brivla test: list holds no lujvo
      check is_gismu == (($w).len == 5)  # kind partitions list by length
      if is_gismu: inc count_gismu else: inc count_cmavo
    check count_gismu == 1342  # conservation: list holds 1342 gismu
    check count_cmavo == 94  # conservation: list holds 94 cmavo carrying rafsi


  test "Word order follows list order":
    for w in words():
      check Word(w.index) == w  # index round trips
    for i in 1..<LIST_GISMU.len:
      check $Word(i - 1) < $Word(i)  # list order is byte order, as lookup needs
    randomize(0)
    let pool = drawPairs()
    for (a, b) in pool.samples:  # `SAMPLES_PAIRS` pairs, seeded
      check (a < b) == ($a < $b)  # word order is spelling order


  test "Rendering round trips":
    for w in words():
      check word($w) == some(w)  # rendering then lookup is identity
    for entry in LIST_GISMU:
      check word(entry.word).map(`$`) == some(entry.word)  # lookup then rendering is identity


  test "Entry fields":
    for w in words():
      let entry = w.entry
      check entry.word.len in 2..5  # cmavo of two to four letters, gismu of five
      check entry.keyword.len > 0 and entry.definition.len > 0  # every entry glossed
      check entry.rafsi.len <= 3  # one rafsi slot per short form
      check entry.rafsi.allIt(it.form.get in FORMS_SHORT)  # slots hold short rafsi
      if w.kind == Kind.Cmavo: check entry.rafsi.len >= 1  # cmavo listed for its rafsi
      check entry.word.strip == entry.word and entry.keyword.strip == entry.keyword  # trimmed


  test "Lookups agree with linear scan":
    check word("").isNone  # degenerate spelling misses
    check word("Gismu").isNone and word("gismu ").isNone  # miss on spelling; constructed
    check word("gism").isNone and word("gismuu").isNone  # miss on prefix, extension; constructed
    check wordsStem("").len == 0 and wordsStem("gismu").len == 0  # stem has four letters
    randomize(0)
    let pool = drawMutated()
    var count_unlisted, count_listed = 0
    for (source, text) in pool.samples:  # `SAMPLES_MUTATION` spellings, seeded
      let found = word(text)
      check found == wordScanned(text)  # binary search equals linear scan
      if found.isNone: inc count_unlisted
      elif text != source: inc count_listed
    check count_unlisted >= FLOOR_UNLISTED  # corpus keeps misses (Article IX.3)
    check count_listed >= FLOOR_LISTED  # corpus keeps hits on other entries (Article IX.3)
    var count_stemmed = 0
    for notation in ["CVCC", "CCVC"]:
      for text in texts(positionsNotation(notation)):  # 49130 strings, exhaustive
        let found = wordsStem(text)
        check found == wordsStemScanned(text)  # binary search equals linear scan
        count_stemmed += found.len
    check count_stemmed == 1342  # conservation: each gismu found under one stem
