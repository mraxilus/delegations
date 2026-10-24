## Replicate shapes of brivla, gismu and rafsi of CLL chapter 4 against `forms.nim`.
##   Every string of up to four letters over alphabet of 3.1, foreign letters added, is
##     enumerated, and so is every string of CVC/CV or CCVCV letters; other strings of five are
##     sampled, seeded, as one-letter mutations of listed gismu (Article IX.3).
##   Forms are restated here from notation of 4.1, apart from `form`; pair judgements of
##     `clusters.nim` are reused, since `test_clusters.nim` replicates them.
##   Where CLL speaks of every gismu, rafsi or lujvo, each entry of committed lists stands as
##     domain, so list breaking claim of CLL fails here, by name.
##   Short rafsi outside 4.6 tables would be pinned as exceptions, not failed; list holds none.
##   Cost: enumeration reads about million strings; suite runs in about two seconds on
##     unoptimised build, measured 2026-10-24.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, tables, unittest]

import ../../src/lojban_tagger/[clusters, forms]
import ../../src/lojban_tagger/lists/[gismu, lujvo]


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"  ## Seventeen consonants C stands for (4.1 rule 3).
  ORDER_VOWELS = "aeiou"  ## Five vowels V stands for, `y` excluded (4.1 rule 1).
  ALPHABET = "',.abcdefgijklmnoprstuvxyz"  ## Letters of 3.1, apostrophe, comma and period.
  LETTERS_FOREIGN = "ABhqw"  ## Capitals, and `h`, `q`, `w` that 3.1 omits.
  DIPHTHONGS = ["ai", "ei", "oi", "au"]  ## Vowel pairs VV stands for unbroken (4.1 rule 2).
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
    ## Least of those mutations keeping shape of gismu: half of 6160 read at seed 0.
  SAMPLES_INSERTION = 6000  ## Listed words `y` or apostrophe is inserted into, seeded.
  FLOOR_INSERTION = 1040
    ## Least of those drawn from cmavo, so false verdict stays tested: half of 2081 read at
    ## seed 0.
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
  of "CVV": (if text[1..2] in DIPHTHONGS: some(Form.Cvv) else: none(Form))
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


func countPairs(text: string): int =
  ## Count adjacent consonant pairs in text.
  for i in 0..<text.high:
    if text[i] in ORDER_CONSONANTS and text[i+1] in ORDER_CONSONANTS: inc result


func countPermissible(): int =
  ## Count permissible consonant pairs of 3.6, as `clusters.nim` judges them.
  for a in ORDER_CONSONANTS:
    for b in ORDER_CONSONANTS:
      if isPairPermissible(a, b): inc result


func isBrivlaRestated(text: string): bool =
  ## Test properties of 4.3 restated apart from `isBrivla`: final vowel, and consonant pair
  ##   among first five letters, `y` and apostrophe dropped before counting.
  let counted = text.filterIt(it notin {'y', '\''})
  if text.len == 0 or text[^1] notin ORDER_VOWELS: return false
  counted[0..<min(counted.len, 5)].join.countPairs > 0


func wordsListed(): (seq[string], seq[string], seq[string]) =
  ## Split listed words into cmavo, gismu and lujvo, each in list order.
  for entry in LIST_GISMU:
    if entry.word.len == 5: result[1].add entry.word else: result[0].add entry.word
  for entry in LIST_LUJVO: result[2].add entry.word


proc mutate(text: string): string =
  ## Replace one letter of `text`, chosen at random, by letter of 3.1 or foreign one.
  result = text
  result[rand(text.high)] = sample(ALPHABET & LETTERS_FOREIGN)


proc insertUncounted(text: string): string =
  ## Insert `y` or apostrophe at random place before last letter of `text`.
  let at = rand(text.high)
  text[0..<at] & sample(['y', '\'']) & text[at .. ^1]



suite "Chapter 4":
  test "Section 4.1":
    for length in 0..2:
      for text in texts(positionsAny(length)):  # 993 strings, exhaustive
        check text.form.isNone  # 4.6, shortest rafsi has three letters
    check "sya".form.isNone and "byk".form.isNone  # 4.1 rule 1, V excludes `y`
    check "sy'a".form.isNone and "lerfy".form.isNone  # 4.1 rule 1, V excludes `y`
    check "SAL".form.isNone and "Sal".form.isNone  # 4.1 rule 3, C is lowercase; capitals 3.1
    check "BLANU".form.isNone and not "Blanu".isGismu  # 4.1 rule 3; capitals in names alone, 3.1
    check "sahi".form.isNone  # 3.3, `h` never stands for apostrophe
    check "s'ai".form.isNone and "'sai".form.isNone and "sai'".form.isNone  # 4.1 rule 2, V'V
    check "sa.i".form.isNone and "sa,i".form.isNone  # 3.3, period splits word; comma no letter
    check "sa'ai".form.isNone and "saklii".form.isNone  # 4.6, no form of these lengths
    let (_, words_gismu, _) = wordsListed()
    randomize(0)
    for _ in 1..SAMPLES_LONG:
      var text = sample(words_gismu)
      for _ in 1..rand(1..4): text.add sample(ALPHABET & LETTERS_FOREIGN)
      check text.form.isNone and not text.isGismu  # 4.4, gismu "always have five letters"


  test "Section 4.3":
    check isBrivla("bisycla")  # 4.3, `sc` counted through `y`
    check isBrivla("ro'inre'o")  # 4.3, `nr` counted past apostrophes
    check not isBrivla("da'amei")  # 4.3, compound cmavo, no consonant pair
    check not isBrivla("lojban.")  # 4.3, name, no final vowel
    check not isBrivla("lojban")  # 4.3, cmene always end in consonant
    check isBrivla("ba'ibla")  # 4.3, `bl` is fourth and fifth letters counted
    check not isBrivla("bababla")  # 4.3, `bl` is fifth and sixth letters, past first five
    check not isBrivla("")  # 4.3, no final vowel
    for length in 1..7:
      for text in texts(newSeqWith(length, "bla'y")):  # 97655 strings, exhaustive
        check isBrivla(text) == isBrivlaRestated(text)  # 4.3, three properties, stress unwritten
    let (words_cmavo, words_gismu, words_lujvo) = wordsListed()
    for text in words_gismu: check isBrivla(text)  # 4.4, gismu meet rules for all brivla
    for text in words_lujvo: check isBrivla(text)  # 4.6, lujvo as brivla holds cluster too
    for text in words_cmavo: check not isBrivla(text)  # 4.3, consonant pair marks off cmavo
    for text in words_cmavo & words_gismu & words_lujvo:
      let bare = text.multiReplace(("y", ""), ("'", ""))
      check isBrivla(bare) == isBrivla(text)  # 4.3, `y` and apostrophe "not counted"
      check not isBrivla(text & "n") and not isBrivla(text & ".")  # 4.3, final vowel
    randomize(0)
    var count_cmavo = 0
    for _ in 1..SAMPLES_INSERTION:
      let
        source = rand(2)
        text =
          if source == 0: sample(words_cmavo)
          elif source == 1: sample(words_gismu)
          else: sample(words_lujvo)
      check isBrivla(text.insertUncounted) == isBrivla(text)  # 4.3, `y`, apostrophe uncounted
      if source == 0: inc count_cmavo
    check count_cmavo >= FLOOR_INSERTION  # corpus keeps false verdict (Article IX.3)


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
    var count_cvccv, count_ccvcv = 0
    for text in texts(positionsNotation("CVCCV")):  # 122825 strings, exhaustive
      let expected = if isPairPermissible(text[2], text[3]): some(Form.Cvccv) else: none(Form)
      check text.form == expected  # 4.4, CVC/CV, medial pair need only be permissible
      if text.isGismu: inc count_cvccv
    for text in texts(positionsNotation("CCVCV")):  # 122825 strings, exhaustive
      let expected = if isPairInitial(text[0], text[1]): some(Form.Ccvcv) else: none(Form)
      check text.form == expected  # 4.4, CCVCV, pair at beginning "permissible initial pair"
      if text.isGismu: inc count_ccvcv
    check count_cvccv == 17 * 5 * countPermissible() * 5  # 4.4, CVC/CV over C/C, 4.1 rule 5
    check count_ccvcv == 48 * 5 * 17 * 5  # 4.4, CCVCV over 48 initial pairs of 4.1 rule 4
    let (words_cmavo, words_gismu, words_lujvo) = wordsListed()
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
    for text in words_cmavo & words_lujvo:
      check not text.isGismu  # 4.4, "five letter length distinguishes gismu from lujvo"
    randomize(0)
    var count_shaped = 0
    for _ in 1..SAMPLES_MUTATION:
      let text = mutate(sample(words_gismu))
      check text.form == text.formRestated  # 4.4, five letters hold CVC/CV, CCVCV or none
      if text.formRestated.isSome: inc count_shaped
    check count_shaped >= FLOOR_MUTATION  # corpus keeps gismu shapes (Article IX.3)


  test "Section 4.6":
    var
      counts: array[Form, int]
      count_cvv_broken = 0
    for length in 3..4:
      for text in texts(positionsAny(length)):  # 953312 strings, exhaustive
        let found = text.form
        check found == text.formRestated  # 4.6 forms in 4.1 notation
        if found.isNone: continue
        if '\'' in text: inc count_cvv_broken else: inc counts[found.get]
    check counts[Form.Cvc] == 17 * 5 * 17  # 4.6, CVC over 4.1 rules 1 and 3
    check counts[Form.Ccv] == 48 * 5  # 4.6, CCV "only if" permissible initial pair
    check counts[Form.Cvv] == 17 * 4  # 4.6, CVV unbroken only with four diphthongs
    check count_cvv_broken == 17 * 25  # 4.1 rule 2, 25 vowel pairs split by apostrophe
    check counts[Form.Cvcc] == 17 * 5 * countPermissible()  # 4.6, CVC/C
    check counts[Form.Ccvc] == 48 * 5 * 17  # 4.6, CCVC
    check counts[Form.Cvccv] == 0 and counts[Form.Ccvcv] == 0  # 4.6, 5-letter rafsi alone
    check sorted(DIPHTHONGS_RAFSI) == sorted(DIPHTHONGS)  # 4.6, "ai", "ei", "oi", "au"
    for (labelled, pattern, rafsi) in ROWS_SAKLI:
      check rafsiPattern("sakli", pattern) == rafsi  # 4.6, table for `sakli`
      check rafsi.form == some(labelled)  # 4.6, table for `sakli`
    for (labelled, pattern, rafsi) in ROWS_BLACI:
      check rafsiPattern("blaci", pattern) == rafsi  # 4.6, table for `blaci`
      check rafsi.form == some(labelled)  # 4.6, table for `blaci`
    check rafsiPossible("sakli") == ROWS_SAKLI.mapIt(it[2])  # 4.6, "only short rafsi forms"
    check rafsiPossible("blaci") == ROWS_BLACI.mapIt(it[2])  # 4.6, "only short rafsi forms"
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
    for entry in LIST_GISMU:
      for one in entry.rafsi:
        if one.len == 3 and one.form == some(Form.Cvv):
          check one[1..2] in DIPHTHONGS  # 4.6, CVV unbroken only with diphthong
        if one.form == some(Form.Ccv):
          check isPairInitial(one[0], one[1])  # 4.6, CCV only with initial pair
    let (_, _, words_lujvo) = wordsListed()
    for text in words_lujvo:
      check text.len >= 6 and not text.isGismu  # 4.6, "all lujvo have at least six letters"
    var vowels_paired: seq[string]
    for entry in LIST_GISMU:
      for one in entry.rafsi:
        if one.form == some(Form.Cvv): vowels_paired.add one
    for first in vowels_paired:
      for second in vowels_paired:  # 177241 pairs, exhaustive
        check not isBrivla(first & second)  # 4.6, CVV-CVV "would be no consonant cluster"
        check isBrivla(first & "r" & second)  # 4.6, "hyphen is always required"
    check not isBrivla("ro'ire'o")  # 4.6, "breaks up into two cmavo"
    check isBrivla("patyta'a") and isBrivla("mudysiclu")  # 4.6, `y` not counted, "this is why"
    check isBrivla("ro'inre'o") and isBrivla("rokre'o")  # 4.6, hyphenated and unhyphenated


  test "Section 4.11":
    check FORMS_SHORT == {Form.Cvc, Form.Ccv, Form.Cvv}  # 4.6, "CVC, CCV, or CVV"
    check FORMS_UNREDUCED == {Form.Cvcc, Form.Ccvc}  # 4.6, 4-letter rafsi CVC/C or CCVC
    check FORMS_GISMU == {Form.Cvccv, Form.Ccvcv}  # 4.4, "CVC/CV or CCVCV"
    check FORMS_SHORT + FORMS_UNREDUCED + FORMS_GISMU == {Form.low..Form.high}  # 4.6
    check card(FORMS_SHORT) + card(FORMS_UNREDUCED) + card(FORMS_GISMU) == 7  # 4.6, disjoint
    check FORMS_FINAL == {Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv}  # 4.11 step 2
    check FORMS_FINAL * FORMS_SHORT == {Form.Ccv, Form.Cvv}  # 4.11 step 2, CVV-form or CCV-form
    check FORMS_FINAL * FORMS_UNREDUCED == {}  # 4.6, 4-letter rafsi at beginning or middle only
    check FORMS_GISMU <= FORMS_FINAL  # 4.6, gismu itself used only at end
    check (FORMS_SHORT + FORMS_UNREDUCED) * FORMS_GISMU == {}  # 4.11 step 1, 3 or 4 letters
    check Form.Cvc notin FORMS_FINAL  # 4.6, CVC never final rafsi
    for entry in LIST_GISMU:
      var texts_formed = entry.rafsi
      if entry.word.isGismu: texts_formed.add [entry.word, entry.word[0..3]]
      for text in texts_formed:
        let found = text.form
        check found.isSome  # 4.6, every rafsi has form
        if found.isSome:
          check (text[^1] in ORDER_VOWELS) == (found.get in FORMS_FINAL)  # 4.6, end in vowels
