## Replicate shapes of brivla, gismu and rafsi of CLL chapter 4 against `forms.nim`.
##   Sibling `lojban_tagger/tests/suites/test_forms.nim` holds earlier copy, over committed lujvo
##     list and without cmavo forms, until #809 drops it (II.9).
##   Every string of up to four letters over alphabet of 3.1, foreign letters added, is
##     enumerated, and so is every string of CVC/CV or CCVCV letters; other strings of five are
##     sampled, seeded, as one-letter mutations of listed gismu (Article IX.3).
##   Each test seeds generator once, draws its samples into pool, and iterator serves pool.
##   Forms are restated here from notation of 4.1, apart from `form`; pair judgements of
##     `clusters.nim` are reused, since `test_clusters.nim` replicates them.
##   Where CLL speaks of every gismu or rafsi, each entry of committed list stands as domain,
##     so list breaking claim of CLL fails here, by name. Where it speaks of every lujvo, each
##     word of `lujvo.txt` stands as domain, read as outside text (`texts_outside.nim`); that
##     test skips where file is absent or moved from its pin (IX.9).
##   Short rafsi outside 4.6 tables would be pinned as exceptions, not failed; list holds none.
##   String no source holds is marked `constructed` in its citation.
##   Comma stands in enumerated alphabet of chapter 4, since 3.1 lists it among symbols; it is
##     neither C nor V of 4.1, so no form holds it. Internal suite holds choice CLL does not
##     make: form reads canonical letters alone, and reader of `tanru.nim` refuses comma before
##     any form is asked.
##   Cost: enumeration reads about 1.6 million strings; suite alone runs in 3.0 s to 4.0 s on
##     unoptimised build (measured, PROVENANCE.md, Figures).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, sets, strutils, tables, unittest]

import ../../src/lojban_parser/[clusters, forms]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ./texts_outside


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"  ## Seventeen consonants C stands for (4.1 rule 3).
  ORDER_VOWELS = "aeiou"  ## Five vowels V stands for, `y` excluded (4.1 rule 1).
  ALPHABET = "',.abcdefgijklmnoprstuvxyz"  ## Letters of 3.1, apostrophe, comma and period.
  LETTERS_FOREIGN = "ABhqw"  ## Capitals, and `h`, `q`, `w` that 3.1 omits.
  DIPHTHONGS_NOTATION = ["ai", "ei", "oi", "au"]
    ## Vowel pairs VV stands for unbroken (4.1 rule 2), restated apart from `forms.nim`.
  GLIDES_ON = ["ia", "ie", "ii", "io", "iu", "ua", "ue", "ui", "uo", "uu"]
    ## Ten on-glides of 3.4 table, which 4.2 adds for cmavo of VV form, restated.
  ALPHABET_CMAVO = "'abceiouy"
    ## Letters cmavo law enumerates over: five vowels, `y`, apostrophe, and two consonants, since
    ##   4.2 treats every consonant alike.
  LENGTH_CMAVO = 6  ## Longest string cmavo law enumerates, long enough for `ku'a'e` of 4.2.
  SAMPLES_COMPOUND = 2000  ## Random compounds of one to five listed cmavo, seeded.
  FLOOR_COMPOUND = 1500  ## Least of them of two cmavo or more: four in five expected.
  FLOOR_CMAVO_SIMPLE = 590  ## Least lines of `cmavo.txt` holding one cmavo: 598 read.
  ROWS_SAKLI = [
    (Form.Cvc, "123", "sak"),
    (Form.Cvc, "124", "sal"),
    (Form.Cvv, "12'5", "sa'i"),
    (Form.Cvv, "125", "sai"),
    (Form.Ccv, "345", "kli"),
    (Form.Ccv, "132", "ska"),
  ]
    ## Rows of 4.6 table for CVC/CV gismu `sakli`: form, gismu letters used, rafsi.
  ROWS_BLACI = [
    (Form.Cvc, "134", "bac"),
    (Form.Cvc, "234", "lac"),
    (Form.Cvv, "13'5", "ba'i"),
    (Form.Cvv, "135", "bai"),
    (Form.Cvv, "23'5", "la'i"),
    (Form.Cvv, "235", "lai"),
    (Form.Ccv, "123", "bla"),
  ]
    ## Rows of 4.6 table for CCVCV gismu `blaci`: form, gismu letters used, rafsi.
  EXCEPTIONS_TABLE: seq[string] = @[]
    ## Listed gismu and short rafsi no row of its 4.6 table spells, pinned; list holds none.
  EXCEPTIONS_LETTERS: seq[string] = @[]
    ## Listed gismu and short rafsi holding letter gismu lacks, pinned; list holds none.
  SAMPLES_MUTATION = 20000  ## Listed gismu mutated in one letter and classified, seeded.
  FLOOR_MUTATION = 3080
    ## Least of those mutations keeping shape of gismu, so corpus holds both verdicts: half of
    ## 6160 read at seed 0.
  SAMPLES_INSERTION = 2000
    ## Words of each kind, cmavo, gismu and lujvo, `y` or apostrophe is inserted into.
  SAMPLES_LONG = 3000  ## Listed gismu lengthened past five letters, seeded.


func notation(text: string): string =
  ## Spell text in notation of 4.1: `C`, `V`, apostrophe as written, `?` for any other letter.
  for c in text:
    result.add(
      if c in ORDER_CONSONANTS: 'C'
      elif c in ORDER_VOWELS: 'V'
      elif c == '\'': '\''
      else: '?'
    )


func formRestated(text: string): Option[Form] =
  ## Classify text by forms of 4.4 and 4.6, restated from 4.1 notation apart from `form`.
  let
    is_initial = text.len >= 2 and isPairInitial(text[0], text[1])
    is_medial = text.len >= 4 and isPairPermissible(text[2], text[3])
  case text.notation
  of "CVC": some(Form.Cvc)
  of "CCV": (if is_initial: some(Form.Ccv) else: none(Form))
  of "CVV": (if text[1..2] in DIPHTHONGS_NOTATION: some(Form.Cvv) else: none(Form))
  of "CV'V": some(Form.Cvv)
  of "CVCC": (if is_medial: some(Form.Cvcc) else: none(Form))
  of "CCVC": (if is_initial: some(Form.Ccvc) else: none(Form))
  of "CVCCV": (if is_medial: some(Form.Cvccv) else: none(Form))
  of "CCVCV": (if is_initial: some(Form.Ccvcv) else: none(Form))
  else: none(Form)


func positionsNotation(notation: string): seq[string] =
  ## Read letters each position of 4.1 notation admits: `C`, `V`, or symbol as written.
  for symbol in notation:
    result.add(
      case symbol
      of 'C': ORDER_CONSONANTS
      of 'V': ORDER_VOWELS
      else: $symbol
    )


func positionsAny(length: int): seq[string] =
  ## Admit every letter of 3.1, and every foreign one, at each of `length` positions.
  newSeqWith(length, ALPHABET & LETTERS_FOREIGN)


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


func rafsiPattern(gismu, pattern: string): string =
  ## Spell rafsi from digit pattern of 4.6 table: `12'5` of `sakli` gives `sa'i`.
  for c in pattern:
    result.add(if c == '\'': '\'' else: gismu[ord(c)-ord('1')])


func rows(gismu: string): seq[(Form, string, string)] =
  ## Read rows of 4.6 table for form of `gismu`: that of `sakli`, or that of `blaci`.
  if gismu.form == some(Form.Cvccv): @ROWS_SAKLI else: @ROWS_BLACI


func rafsiPossible(gismu: string): seq[string] =
  ## Spell every short rafsi 4.6 lets `gismu` have: rows of its table that `form` admits.
  gismu.rows.mapIt(rafsiPattern(gismu, it[1])).filterIt(it.form.isSome)


func hyphenBefore(rafsi: string): char =
  ## Pick hyphen CVV rafsi takes before `rafsi`: `n` where `rafsi` begins with `r`, else `r`.
  if rafsi[0] == 'r': 'n' else: 'r'


func formsHeld(texts: openArray[string]): set[Form] =
  ## Collect forms `texts` take; text of no form adds none.
  for text in texts:
    let found = text.form
    if found.isSome: result.incl found.get


func countPairs(text: string): int =
  ## Count adjacent consonant pairs in text.
  for i in 0..<text.high:
    if text[i] in ORDER_CONSONANTS and text[i+1] in ORDER_CONSONANTS: inc result


func isBrivlaRestated(text: string): bool =
  ## Test properties of 4.3 restated apart from `isBrivla`: final vowel, and consonant pair
  ##   among first five letters, `y` and apostrophe dropped before counting.
  let counted = text.filterIt(it notin {'y', '\''})
  if text.len == 0 or text[^1] notin ORDER_VOWELS: return false
  counted[0..<min(counted.len, 5)].join.countPairs > 0


func wordsListed(): (seq[string], seq[string]) =
  ## Split listed words into cmavo and gismu, each in list order.
  for entry in LIST_GISMU:
    if entry.word.len == 5: result[1].add entry.word else: result[0].add entry.word


proc mutate(text: string): string =
  ## Replace one letter of `text`, chosen at random, by letter of 3.1 or foreign one.
  result = text
  result[rand(text.high)] = sample(ALPHABET & LETTERS_FOREIGN)


proc insertUncounted(text: string): string =
  ## Insert `y` or apostrophe at random place before last letter of `text`.
  let at = rand(text.high)
  text[0..<at] & sample(['y', '\'']) & text[at .. ^1]


proc drawLengthened(words: seq[string]): seq[string] =
  ## Draw `SAMPLES_LONG` of `words`, each lengthened by one to four letters, as seeded.
  result = newSeqOfCap[string](SAMPLES_LONG)
  for _ in 1..SAMPLES_LONG:
    var text = sample(words)
    for _ in 1..rand(1..4): text.add sample(ALPHABET & LETTERS_FOREIGN)
    result.add text


proc drawInserted(kinds: openArray[seq[string]]): seq[(string, string)] =
  ## Draw `SAMPLES_INSERTION` words of each kind, each beside copy `y` or apostrophe went into.
  result = newSeqOfCap[(string, string)](SAMPLES_INSERTION * kinds.len)
  for words in kinds:
    for _ in 1..SAMPLES_INSERTION:
      let text = sample(words)
      result.add (text, text.insertUncounted)


proc drawMutated(words: seq[string]): seq[string] =
  ## Draw `SAMPLES_MUTATION` of `words`, each mutated in one letter, as seeded.
  result = newSeqOfCap[string](SAMPLES_MUTATION)
  for _ in 1..SAMPLES_MUTATION: result.add mutate(sample(words))


func runsVowel(first: openArray[string], length_max: int): seq[string] =
  ## Join vowel runs up to `length_max` letters: one nucleus of `first`, then each vowel or
  ##   diphthong of 4.1 after apostrophe, built forward apart from `isCmavo`, which reads back.
  var frontier = @first.filterIt(it.len <= length_max)
  while frontier.len > 0:
    result.add frontier
    var longer: seq[string]
    for run in frontier:
      for nucleus in @ORDER_VOWELS.mapIt($it) & @DIPHTHONGS_NOTATION:
        if run.len + 1 + nucleus.len <= length_max: longer.add run & "'" & nucleus
    frontier = longer


func cmavoGenerated(length_max: int): HashSet[string] =
  ## Build every cmavo of 4.2 up to `length_max` letters over `ALPHABET_CMAVO`, part by part.
  let nuclei = @ORDER_VOWELS.mapIt($it) & @DIPHTHONGS_NOTATION
  for run in runsVowel(nuclei & @GLIDES_ON, length_max): result.incl run  # V, VV, on-glide
  for consonant in ALPHABET_CMAVO:
    if consonant notin ORDER_CONSONANTS: continue
    for run in runsVowel(nuclei, length_max - 1): result.incl consonant & run  # CV, CVV
    result.incl consonant & "y"  # letteral `Cy` (4.2, 17.2)
  result.incl "y"  # cmavo `.y.` (4.2)
  result.incl "y'y"  # letteral of apostrophe (17.2)


iterator samples[T](pool: seq[T]): lent T =
  ## Serve each sample of preallocated pool, with no copy.
  for i in 0..<pool.len: yield pool[i]



suite "Chapter 4":
  test "Section 4.1":
    for length in 0..2:
      for text in texts(positionsAny(length)):  # 993 strings, exhaustive
        check text.form.isNone  # 4.6, shortest rafsi has three letters
    check "sya".form.isNone and "byk".form.isNone  # 4.1 rule 1, V excludes `y`; constructed
    check "sy'a".form.isNone and "lerfy".form.isNone  # 4.1 rule 1, V excludes `y`; constructed
    check "SAL".form.isNone and "Sal".form.isNone  # 4.1 rule 3, C lowercase (3.1); constructed
    check "BLANU".form.isNone  # 4.1 rule 3; capitals in names alone (3.1); constructed
    check not "Blanu".isGismu  # 4.1 rule 3; capitals in names alone (3.1); constructed
    check "sahi".form.isNone  # 3.3, `h` never stands for apostrophe; constructed
    check "s'ai".form.isNone and "'sai".form.isNone  # 4.1 rule 2, V'V; constructed
    check "sai'".form.isNone  # 4.1 rule 2, V'V; constructed
    check "sa.i".form.isNone  # 3.3, period inside word makes two words; constructed
    check "sa'ai".form.isNone  # 4.4, no gismu contains "'"; constructed
    check "saklii".form.isNone  # 4.4, gismu "always have five letters"; constructed
    let (_, words_gismu) = wordsListed()
    randomize(0)
    let pool = drawLengthened(words_gismu)
    for text in pool.samples:  # `SAMPLES_LONG` strings, seeded
      check text.form.isNone  # 4.4, gismu "always have five letters"


  test "Section 4.2":
    for text in ["a", "e", "i", "o", "u"]: check text.isCmavo  # 4.2, V-form; pause unwritten (3.3)
    for text in ["ba", "ce", "di", "fo", "gu"]: check text.isCmavo  # 4.2, CV-form
    for text in ["au", "ei", "ia", "o'u", "u'e"]: check text.isCmavo  # 4.2, VV-form
    for text in ["ki'a", "pei", "mi'o", "coi", "cu'u"]: check text.isCmavo  # 4.2, CVV-form
    check "y".isCmavo  # 4.2, cmavo `.y.`, pauses unwritten
    for text in ["ku'a'e", "sau'e", "bai'ai"]: check text.isCmavo  # 4.2, experimental
    check "ki'e'u'e".isCmavo  # 4.2, Example 2.4, "single cmavo", four vowels
    for text in GLIDES_ON: check text.isCmavo  # 4.2, "ten additional diphthongs"
    check sorted(DIPHTHONGS_CMAVO) == sorted(GLIDES_ON)  # 4.2, same ten as 3.4 table
    for text in ["by", "cy", "dy", "zy", "y'y"]: check text.isCmavo  # 17.2, single cmavo of BY
    check not "iseci'i".isCmavo  # 4.2, Example 2.1, compound `.i se ci'i`
    check not "punaijecanai".isCmavo  # 4.2, Example 2.2, compound
    check not "ki'e.u'e".isCmavo  # 4.2, Example 2.3, compound, pause before `.u'e`
    check not "cy.ibu.abu".isCmavo  # 4.2, Example 2.5, compound
    check not "da'amei".isCmavo  # 4.3, "must be compound cmavo"
    check not "bla".isCmavo and not "klama".isCmavo  # 4.2, consonant pair marks no cmavo
    check not "cia".isCmavo  # 3.4, on-glides only in words standing alone; constructed
    check ".iseci'i".splitCompound == @["i", "se", "ci'i"]  # 4.2, Example 2.1, `.i se ci'i`
    check "punaijecanai".splitCompound == @["pu", "nai", "je", "ca", "nai"]  # 4.2, Example 2.2
    check "ki'e.u'e".splitCompound == @["ki'e", "u'e"]  # 4.2, Example 2.3, pause kept
    check "ki'e'u'e".splitCompound == @["ki'e'u'e"]  # 4.2, Example 2.4, "single cmavo"
    check "cy.ibu.abu".splitCompound == @["cy", "i", "bu", "a", "bu"]  # 4.2, Example 2.5
    check "da'amei".splitCompound == @["da'a", "mei"]  # 4.3, "must be compound cmavo"
    check "ro'ire'o".splitCompound == @["ro'i", "re'o"]  # 4.6, "breaks up into two cmavo"
    check "klama".splitCompound.len == 0  # 4.2, consonant pair marks no compound
    check "cia".splitCompound.len == 0  # 3.4, on-glide after consonant; constructed
    check not "".isCmavo and not "'a".isCmavo and not "a'".isCmavo  # 3.3, apostrophe joins vowels
    let generated = cmavoGenerated(LENGTH_CMAVO)
    var count_cmavo = 0
    for length in 0..LENGTH_CMAVO:
      for text in texts(newSeqWith(length, ALPHABET_CMAVO)):  # 597871 strings, exhaustive
        check text.isCmavo == (text in generated)  # 4.2, forms built part by part agree
        if text.isCmavo: inc count_cmavo
    check count_cmavo == generated.len  # conservation: every form built is one string read


  test "Section 4.2 over cmavo list":
    let lines = readLinesCmavo()
    if lines.isNone: skip()  # `cmavo.txt` absent or moved from its pin (`texts_outside.nim`)
    else:
      var count_simple = 0
      for line in lines.get:  # every line of list, exhaustive
        let bare = line.word.replace(".", "")  # 3.3, period writes pause, which form leaves out
        check bare.isCmavo == not line.is_compound  # 4.2, one cmavo of form, else compound
        if not line.is_compound: inc count_simple
      check count_simple >= FLOOR_CMAVO_SIMPLE  # Article IX.3, guard leaves enough cmavo

  test "Section 4.3":
    check isBrivla("bisycla")  # 4.3, `sc` counted through `y`
    check isBrivla("ro'inre'o")  # 4.3, `nr` counted past apostrophes
    check not isBrivla("da'amei")  # 4.3, compound cmavo, no consonant pair
    check not isBrivla("lojban.")  # 4.3, name, no final vowel
    check not isBrivla("lojban")  # 4.3, cmene always end in consonant
    check isBrivla("ba'ibla")  # 4.3, `bl` is fourth and fifth letters counted; constructed
    check not isBrivla("bababla")  # 4.3, `bl` fifth and sixth letters, past first five; constructed
    check not isBrivla("")  # 4.3, no final vowel
    for length in 1..7:
      for text in texts(newSeqWith(length, "bla'y")):  # 97655 strings, exhaustive
        check isBrivla(text) == isBrivlaRestated(text)  # 4.3, three properties, stress unwritten
    let (words_cmavo, words_gismu) = wordsListed()
    for text in words_gismu: check isBrivla(text)  # 4.4, gismu meet rules for all brivla
    for text in words_cmavo: check not isBrivla(text)  # 4.3, consonant pair marks off cmavo
    for text in words_cmavo & words_gismu:
      let bare = text.multiReplace(("y", ""), ("'", ""))
      check isBrivla(bare) == isBrivla(text)  # 4.3, `y` and apostrophe "not counted"
      check not isBrivla(text & "n") and not isBrivla(text & ".")  # 4.3, final vowel
    randomize(0)
    let pool = drawInserted([words_cmavo, words_gismu])
    for (text, inserted) in pool.samples:  # `SAMPLES_INSERTION` of each kind, seeded
      check isBrivla(inserted) == isBrivla(text)  # 4.3, `y`, apostrophe uncounted


  test "Section 4.4":
    check "creka".form == some(Form.Ccvcv)  # 4.4, Example 3.1 as page labels it
    check "lijda".form == some(Form.Cvccv)  # 4.4, Example 3.2 as page labels it
    check "blanu".form == some(Form.Ccvcv)  # 4.4, Example 3.3 as page labels it
    check "mamta".form == some(Form.Cvccv)  # 4.4, Example 3.4 as page labels it
    check "cukta".form == some(Form.Cvccv)  # 4.4, Example 3.5 as page labels it
    check "patfu".form == some(Form.Cvccv)  # 4.4, Example 3.6 as page labels it
    check "nanmu".form == some(Form.Cvccv)  # 4.4, Example 3.7 as page labels it
    check "ninmu".form == some(Form.Cvccv)  # 4.4, Example 3.8 as page labels it
    for text in ["creka", "lijda", "blanu", "mamta", "cukta", "patfu", "nanmu", "ninmu"]:
      check text.isGismu  # 4.4, Examples 3.1-3.8 as page labels them
    for text in texts(positionsNotation("CVCCV")):  # 122825 strings, exhaustive
      let expected = if isPairPermissible(text[2], text[3]): some(Form.Cvccv) else: none(Form)
      check text.form == expected  # 4.4, CVC/CV, medial pair need only be permissible
    var count_ccvcv = 0
    for text in texts(positionsNotation("CCVCV")):  # 122825 strings, exhaustive
      let expected = if isPairInitial(text[0], text[1]): some(Form.Ccvcv) else: none(Form)
      check text.form == expected  # 4.4, CCVCV, pair at beginning "permissible initial pair"
      if text.isGismu: inc count_ccvcv
    check count_ccvcv == 48 * 5 * 17 * 5  # 4.4, CCVCV over 48 initial pairs of 4.1 rule 4
    let (words_cmavo, words_gismu) = wordsListed()
    check words_gismu.len in 1300..1400  # 4.4, "about 1350 gismu"
    var lut_words_by_stem: Table[string, seq[string]]
    for text in words_gismu:
      check text.isGismu  # 4.4, gismu take forms CVC/CV or CCVCV
      check text[0] in ORDER_CONSONANTS  # 4.4, gismu "always start with consonant"
      check text[3] in ORDER_CONSONANTS and text[4] in ORDER_VOWELS  # 4.4, single final vowel
      check text.countPairs == 1  # 4.4, "exactly one consonant pair"
      check '\'' notin text  # 4.4, no gismu contains apostrophe
      for i in 0..4:
        var broken = text
        broken[i] = '\''
        check not broken.isGismu  # 4.4, no gismu contains apostrophe
      lut_words_by_stem.mgetOrPut(text[0..3], @[]).add text
    for stem, words in lut_words_by_stem:
      if stem == "brod": check words == @["broda", "brode", "brodi", "brodo", "brodu"]  # 4.4
      else: check words.len == 1  # 4.4, no two other gismu differ only in final vowel
    check lut_words_by_stem.hasKey("brod")  # 4.4, five special brivla variables
    for text in words_cmavo:
      check not text.isGismu  # 4.3, consonant pair distinguishes brivla, gismu among them
    randomize(0)
    let pool = drawMutated(words_gismu)
    var count_shaped = 0
    for text in pool.samples:  # `SAMPLES_MUTATION` strings, seeded
      check text.form == text.formRestated  # 4.4, five letters hold CVC/CV, CCVCV or none
      if text.formRestated.isSome: inc count_shaped
    check count_shaped >= FLOOR_MUTATION  # corpus keeps gismu shapes (Article IX.3)
    check count_shaped <= SAMPLES_MUTATION - FLOOR_MUTATION  # corpus keeps other strings too


  test "Section 4.6":
    var counts: array[Form, int]
    for length in 3..4:
      for text in texts(positionsAny(length)):  # 953312 strings, exhaustive
        let found = text.form
        check found == text.formRestated  # 4.6 forms in 4.1 notation
        if found.isSome: inc counts[found.get]
    check counts[Form.Ccv] == 48 * 5  # 4.6, CCV "only if" permissible initial pair
    check counts[Form.Ccvc] == 48 * 5 * 17  # 4.6, CCVC over 48 initial pairs of 4.1 rule 4
    check sorted(forms.DIPHTHONGS) == sorted(DIPHTHONGS_NOTATION)  # 4.6, "ai", "ei", "oi", "au"
    for (labelled, pattern, rafsi) in ROWS_SAKLI:
      check rafsiPattern("sakli", pattern) == rafsi  # 4.6, table for `sakli`
      check rafsi.form == some(labelled)  # 4.6, table for `sakli`
    for (labelled, pattern, rafsi) in ROWS_BLACI:
      check rafsiPattern("blaci", pattern) == rafsi  # 4.6, table for `blaci`
      check rafsi.form == some(labelled)  # 4.6, table for `blaci`
    check rafsiPossible("mamta") == @["mam", "mat", "ma'a"]  # 4.6, "can only have"
    check "mamta".form == "salci".form  # 4.6, `mamta` has form of `salci`
    var
      exceptions_table, exceptions_letters: seq[string]
      count_possible_most = 0
    for entry in LIST_GISMU:
      let text = entry.word
      if not text.isGismu: continue
      let possible = rafsiPossible(text)
      count_possible_most = max(count_possible_most, possible.len)
      let unreduced = if text.form == some(Form.Cvccv): Form.Cvcc else: Form.Ccvc
      check text[0..3].form == some(unreduced)  # 4.6, 4-letter rafsi is gismu less vowel
      check entry.rafsi.len <= 3  # 4.6, "from two to five rafsi", two of them long
      var forms_seen: set[Form]
      for one in entry.rafsi:
        let found = one.form
        check found.isSome and found.get in FORMS_SHORT  # 4.6, "CVC, CCV, or CVV"
        check found == one.formRestated  # 4.6, restrictions on CVV and CCV
        if found.isNone: continue
        check found.get notin forms_seen  # 4.6, "at most one" of each form per gismu
        forms_seen.incl found.get
        if one notin possible: exceptions_table.add text & " " & one
        if not one.allIt(it == '\'' or it in text): exceptions_letters.add text & " " & one
      for (labelled, pattern, _) in text.rows:
        let spelled = rafsiPattern(text, pattern)
        check spelled.form.isNone or spelled.form == some(labelled)  # 4.6, form column
    check exceptions_table == EXCEPTIONS_TABLE  # 4.6, short rafsi "that can possibly exist"
    check exceptions_letters == EXCEPTIONS_LETTERS  # 4.6, letters chosen from five of gismu
    check count_possible_most == 7  # 4.6, "at most seven possible short rafsi"
    var vowels_paired: seq[string]
    for entry in LIST_GISMU:
      for one in entry.rafsi:
        if one.form == some(Form.Cvv): vowels_paired.add one
    for second in vowels_paired:
      check isPairPermissible(second.hyphenBefore, second[0])  # 4.6, `n` "in place of" `r`
    for first in vowels_paired:
      for second in vowels_paired:  # 177241 pairs, exhaustive
        check not isBrivla(first & second)  # 4.6, CVV-CVV "would be no consonant cluster"
        check isBrivla(first & second.hyphenBefore & second)  # 4.6, "hyphen is always required"
    check not isPairPermissible('r', 'r')  # 4.6, `ro'irre'o` "impermissible double consonant"
    check not isBrivla("ro'ire'o")  # 4.6, "breaks up into two cmavo"
    check isBrivla("patyta'a") and isBrivla("mudysiclu")  # 4.6, `y` not counted, "this is why"
    check isBrivla("ro'inre'o") and isBrivla("rokre'o")  # 4.6, hyphenated and unhyphenated


  test "Section 4.3-6 over lujvo list":
    let lines = readLinesLujvo()
    if lines.isNone: skip()  # `lujvo.txt` absent or moved from its pin (`texts_outside.nim`)
    else:
      let words_lujvo = lines.get.mapIt(it.word)
      for text in words_lujvo:  # every word of list, exhaustive
        check isBrivla(text)  # 4.6, lujvo as brivla holds cluster too
        check not text.isGismu  # 4.4, "five letter length distinguishes gismu from lujvo"
        check text.len >= 6  # 4.6, "all lujvo have at least six letters"
        let bare = text.multiReplace(("y", ""), ("'", ""))
        check isBrivla(bare) == isBrivla(text)  # 4.3, `y` and apostrophe "not counted"
        check not isBrivla(text & "n") and not isBrivla(text & ".")  # 4.3, final vowel
      randomize(0)
      let pool = drawInserted([words_lujvo])
      for (text, inserted) in pool.samples:  # `SAMPLES_INSERTION` words, seeded
        check isBrivla(inserted) == isBrivla(text)  # 4.3, `y`, apostrophe uncounted


  test "Section 4.11":
    check FORMS_SHORT == {Form.Cvc, Form.Ccv, Form.Cvv}  # 4.6, "CVC, CCV, or CVV"
    check FORMS_UNREDUCED == {Form.Cvcc, Form.Ccvc}  # 4.6, 4-letter rafsi CVC/C or CCVC
    check FORMS_GISMU == {Form.Cvccv, Form.Ccvcv}  # 4.4, "CVC/CV or CCVCV"
    check FORMS_FINAL == {Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv}  # 4.11 step 2
    var texts_short, texts_unreduced, texts_gismu: seq[string]
    for entry in LIST_GISMU:
      texts_short.add entry.rafsi
      if entry.word.isGismu:
        texts_unreduced.add entry.word[0..3]
        texts_gismu.add entry.word
    check formsHeld(texts_short) == FORMS_SHORT  # 4.6, listed short rafsi "CVC, CCV, or CVV"
    check formsHeld(texts_unreduced) == FORMS_UNREDUCED  # 4.6, CVC/C or CCVC, "4-letter rafsi"
    check formsHeld(texts_gismu) == FORMS_GISMU  # 4.4, listed gismu "CVC/CV or CCVCV"
    for text in texts_short & texts_unreduced & texts_gismu:
      let found = text.form
      check found.isSome  # 4.6, every rafsi has form
      if found.isSome:
        check (text[^1] in ORDER_VOWELS) == (found.get in FORMS_FINAL)  # 4.6, end in vowels



suite "Internal: Forms":
  test "Compound of listed cmavo splits back into them":
    randomize(0)
    var count_long = 0
    for _ in 1 .. SAMPLES_COMPOUND:  # `SAMPLES_COMPOUND` compounds, seeded
      var (words, text) = (newSeq[string](), "")
      for i in 1 .. rand(1 .. 5):
        let word = LIST_CMAVO[rand(LIST_CMAVO.high)].word
        if i > 1 and not word[0].isConsonant: text.add '.'  # 3.3, pause before vowel
        text.add word
        words.add word
      check text.splitCompound == words  # 4.2, split is unique, every cmavo kept
      if words.len >= 2: inc count_long
    check count_long >= FLOOR_COMPOUND  # Article IX.3, guard reaches compounds of several


  test "Comma leaves no form":
    for entry in LIST_GISMU:
      for text in entry.rafsi & @[entry.word]:
        for at in 1..text.high:
          let spelled = text[0..<at] & ',' & text[at .. ^1]
          check spelled.form.isNone  # project choice: `tanru.nim` refuses comma before `form`
