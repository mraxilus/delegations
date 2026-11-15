## rapli zbasu lo tarmi be lo brivla .e lo gismu .e lo rafsi vu'o pe `CLL 4` gi'e cipra lo du'u
##   `forms.nim` cu mapti le se zbasu
##   .i le cipra cu tcidu ro lerpoi poi vasru su'e vo lerfu
##   .i ro le lerfu cu cmima lo fange lerfu .a le lerfu liste pe `CLL 3.1`
##   .i le cipra cu tcidu ji'a ro lerpoi poi lo lerfu pe ke'a cu mapti `CVC/CV` .a `CCVCV`
##   .i le cipra cu tcidu lo mupli be lo drata lerpoi poi vasru mu lerfu
##   .i lo tsiju cu jdice le mupli
##   .i ro mupli cu se zbasu ta'i lo nu basti pa lerfu pe pa gismu pe le liste to `Article IX.3` toi
##   .i ro cipra cu dunda pa tsiju le cupra be lo cunso namcu pa roi gi'e cuxna lo mupli pe vo'a
##     gi'e punji le mupli lo vasru
##   .i lo rapli fancu cu dunda le mupli pe le vasru
##   .i lo tarmi cu rapli se ciska vi ja'i lo sinxa pe `CLL 4.1` gi'e sepli `form`
##   .i le cipra cu rapli pilno lo se jdice be fi lo zunsna remei be'o pe `clusters.nim` ki'u lo nu
##     `test_clusters.nim` cu cipra le se jdice
##   .i va'o lo nu la'o gy. CLL .gy. cu casnu ro gismu .a ro rafsi kei le cipra cu cipra fi ro liste
##     cmima pe le liste poi se ralte
##   .i se ki'u bo lo liste poi na'e mapti lo xusra pe la'o gy. CLL .gy. cu rinka lo nu le cipra cu
##     fliba gi'e cusku lo cmene be le liste cmima poi srera
##   .i va'o lo nu la'o gy. CLL .gy. cu casnu ro lujvo kei le cipra cu cipra fi ro valsi pe
##     `lujvo.txt`
##   .i le valsi cu se tcidu ta'i lo drata se ciska to `texts_outside.nim` toi
##   .i le cipra cu na zukte va'o lo nu le datnyvei cu na zvati gi'a cenba to `Article IX.9` toi
##   .i va'o lo nu lo cmalu rafsi cu na zvati lo liste pe `CLL 4.6` kei le rafsi cu se ralte ne'i lo
##     stodi pe lo na'e mapti gi'e na rinka lo nu fliba
##   .i le gismu liste cu vasru no le cmalu rafsi
##   .i lo pinka be lo lerpoi poi no krasi cu vasru ke'a cu vasru lu le lerpoi cu se zbasu li'u
##   .i slaka bu cu cmima le lerfu liste poi le cipra pe `CLL 4` cu tcidu ke'a ki'u lo nu `CLL 3.1`
##     cu ciska slaka bu ne'i lo liste be lo sinxa
##   .i slaka bu na se sinxa zoi gy. C .gy. .a zoi gy. V .gy. pe `CLL 4.1`
##   .i se ki'u bo no tarmi cu vasru slaka bu
##   .i lo cipra pe `Internal: Forms` cu cipra lo se cuxna poi la'o gy. CLL .gy. na cuxna ke'a
##   .i `form` cu tcidu lo ralju lerfu po'o
##   .i lo tcidu pe `tanru.nim` cu to'e curmi slaka bu pu lo nu retsku fi su'o tarmi
##   .i jdima fa lo nu le cipra cu tcidu ji'i paxanononononono lerpoi
##   .i le cipra po'o cu gunka ze'a `2.02 s` bi'o `2.13 s` ca lo nu le fanva na troci lo nu le
##     samtci cu sutra
##   .i lo nu merli cu se ciska ne'i `PROVENANCE.md` ne'i le pagbu poi se cmene lu lo namcu li'u

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, sets, strutils, tables, unittest]

import ../../src/lojban_parser/[clusters, forms]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ./texts_outside


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"
    ## le paze zunsna poi zoi gy. C .gy. cu sinxa ke'a to le cimoi javni pe `CLL 4.1` toi
  ORDER_VOWELS = "aeiou"
    ## le mu karsna poi zoi gy. V .gy. cu sinxa ke'a
    ##   .i zoi gy. V .gy. na sinxa `y` to le pamoi javni pe `CLL 4.1` toi
  ALPHABET = "',.abcdefgijklmnoprstuvxyz"
    ## lo lerfu pe `CLL 3.1` .e zoi gy. ' .gy. .e slaka bu .e denpa bu
  LETTERS_FOREIGN = "ABhqw"
    ## lo barda lerfu .e `h` .e `q` .e `w`
    ##   .i `CLL 3.1` cu claxu `h` .e `q` .e `w`
  DIPHTHONGS_NOTATION = ["ai", "ei", "oi", "au"]
    ## lo karsna remei poi `VV` cu sinxa ke'a zi'e poi na se fendi to le remoi javni pe `CLL 4.1`
    ##   toi
    ##   .i le vi liste cu rapli se ciska gi'e sepli `forms.nim`
  GLIDES_ON = ["ia", "ie", "ii", "io", "iu", "ua", "ue", "ui", "uo", "uu"]
    ## le pano sakli karsna pe le liste pe `CLL 3.4`
    ##   .i `CLL 4.2` cu jmina le sakli karsna lo cmavo poi se tarmi `VV`
    ##   .i le vi liste cu rapli se ciska
  ALPHABET_CMAVO = "'abceiouy"
    ## lo lerfu poi le flalu pe lo cmavo cu tcidu ro lerpoi pe ke'a
    ##   .i le lerfu cu du le mu karsna jo'u `y` jo'u zoi gy. ' .gy. jo'u re zunsna ki'u lo nu ro
    ##     zunsna cu mintu ja'i `CLL 4.2`
  LENGTH_CMAVO = 6
    ## lo te kancu be lo lerfu pe lo lerpoi poi traji lo ka clani kei gi'e se tcidu le flalu pe lo
    ##   cmavo
    ##   .i le te kancu cu banzu zo ku'a'e pe `CLL 4.2`
  SAMPLES_COMPOUND = 2000
    ## lo cunso cmavo gunma poi vasru su'o pa cmavo gi'e vasru su'e mu cmavo pe le liste
    ##   .i lo tsiju cu jdice le cmavo gunma
  FLOOR_COMPOUND = 1500
    ## lo cnita jimte be lo te kancu be le cmavo gunma poi vasru su'o re cmavo
    ##   .i ca lo nu le tsiju cu du `0` kei le te kancu cu du li paxacimu
  FLOOR_CMAVO_SIMPLE = 590
    ## lo cnita jimte be lo te kancu be lo linji pe `cmavo.txt` zi'e poi vasru pa cmavo po'o
    ##   .i le te kancu poi se tcidu cu du li musobi
  ROWS_SAKLI = [
    (Form.Cvc, "123", "sak"),
    (Form.Cvc, "124", "sal"),
    (Form.Cvv, "12'5", "sa'i"),
    (Form.Cvv, "125", "sai"),
    (Form.Ccv, "345", "kli"),
    (Form.Ccv, "132", "ska"),
  ]
    ## lo linji be le liste pe zo sakli ne'i `CLL 4.6`
    ##   .i zo sakli cu se tarmi `CVC/CV`
    ##   .i ro linji cu vasru lo tarmi .e lo stuzi be lo lerfu pe le gismu be'o poi se pilno .e lo
    ##     rafsi
  ROWS_BLACI = [
    (Form.Cvc, "134", "bac"),
    (Form.Cvc, "234", "lac"),
    (Form.Cvv, "13'5", "ba'i"),
    (Form.Cvv, "135", "bai"),
    (Form.Cvv, "23'5", "la'i"),
    (Form.Cvv, "235", "lai"),
    (Form.Ccv, "123", "bla"),
  ]
    ## lo linji be le liste pe zo blaci ne'i `CLL 4.6`
    ##   .i zo blaci cu se tarmi `CCVCV`
    ##   .i ro linji cu vasru lo tarmi .e lo stuzi be lo lerfu pe le gismu be'o poi se pilno .e lo
    ##     rafsi
  EXCEPTIONS_TABLE: seq[string] = @[]
    ## lo cmalu rafsi be lo gismu pe le gismu liste be'o poi no linji be lo liste pe `CLL 4.6` cu
    ##   ciska ke'a
    ##   .i le liste cu mapti lo tarmi be le gismu
    ##   .i le stodi cu ralte le gismu .e le rafsi
    ##   .i le gismu liste cu vasru no le rafsi
  EXCEPTIONS_LETTERS: seq[string] = @[]
    ## lo cmalu rafsi be lo gismu pe le gismu liste be'o poi vasru lo lerfu poi le gismu cu claxu
    ##   ke'a
    ##   .i le stodi cu ralte le gismu .e le rafsi
    ##   .i le gismu liste cu vasru no le rafsi
  SAMPLES_MUTATION = 20000
    ## lo gismu pe le gismu liste zi'e poi pa lerfu pe ke'a cu se basti
    ##   .i le cipra cu facki lo tarmi be ro le gismu
    ##   .i lo tsiju cu jdice le gismu
  FLOOR_MUTATION = 3080
    ## lo cnita jimte be lo te kancu be le se galfi poi ralte lo tarmi be lo gismu
    ##   .i se ki'u bo le se cipra cu vasru le re se jdice
    ##   .i le jimte cu xadba li xapaxano
    ##   .i ca lo nu le tsiju cu du li no kei le te kancu cu du li xapaxano
  SAMPLES_INSERTION = 2000
    ## lo valsi poi `y` .a zoi gy. ' .gy. cu se punji fi ke'a
    ##   .i le stodi cu te kancu le valsi pe ro klesi po'u lo cmavo .e lo gismu .e lo lujvo
  SAMPLES_LONG = 3000
    ## lo gismu pe le gismu liste zi'e poi zenba lo ka clani kei gi'e vasru za'u mu lerfu
    ##   .i lo tsiju cu jdice le gismu


func notation(text: string): string =
  ## ciska le se ciska ja'i lo sinxa pe `CLL 4.1`
  ##   .i `C` fa'u `V` cu sinxa lo zunsna fa'u lo karsna
  ##   .i zoi gy. ' .gy. cu stali
  ##   .i `?` cu sinxa ro drata lerfu
  for c in text:
    result.add(
      if c in ORDER_CONSONANTS: 'C'
      elif c in ORDER_VOWELS: 'V'
      elif c == '\'': '\''
      else: '?'
    )


func formRestated(text: string): Option[Form] =
  ## facki lo tarmi be le se ciska ja'i lo tarmi pe `CLL 4.4` .e `CLL 4.6`
  ##   .i le tarmi cu rapli se ciska ja'i lo sinxa pe `CLL 4.1` gi'e sepli `form`
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
  ## tcidu lo lerfu poi ro stuzi be lo sinxa pe `CLL 4.1` cu curmi ke'a
  ##   .i `C` cu curmi lo zunsna
  ##   .i `V` cu curmi lo karsna
  ##   .i ro drata sinxa cu curmi vo'a po'o
  for symbol in notation:
    result.add(
      case symbol
      of 'C': ORDER_CONSONANTS
      of 'V': ORDER_VOWELS
      else: $symbol
    )


func positionsAny(length: int): seq[string] =
  ## curmi ro lerfu pe `CLL 3.1` .e ro fange lerfu bu'u ro stuzi
  ##   .i lo te kancu be le stuzi cu du `length`
  newSeqWith(length, ALPHABET & LETTERS_FOREIGN)


iterator texts(positions: seq[string]): string =
  ## dunda ro lerpoi poi ro stuzi be ke'a cu cpacu pa lerfu le selcmi pe le stuzi
  ##   .i le romoi stuzi cu traji lo ka sutra cenba
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
  ## ciska lo rafsi ja'i lo namcu morna pe lo liste pe `CLL 4.6`
  ##   .i mupli fa lo nu `12'5` pe zo sakli cu dunda `sa'i`
  for c in pattern:
    result.add(if c == '\'': '\'' else: gismu[ord(c)-ord('1')])


func rows(gismu: string): seq[(Form, string, string)] =
  ## tcidu lo linji be le liste poi mapti lo tarmi be `gismu` ne'i `CLL 4.6`
  ##   .i le liste cu du le liste pe zo sakli .a le liste pe zo blaci
  if gismu.form == some(Form.Cvccv): @ROWS_SAKLI else: @ROWS_BLACI


func rafsiPossible(gismu: string): seq[string] =
  ## ciska ro cmalu rafsi poi `CLL 4.6` cu curmi lo nu `gismu` cu ponse ke'a
  ##   .i le rafsi cu se krasi lo linji be le liste pe `gismu` be'o poi `form` cu curmi ke'a
  gismu.rows.mapIt(rafsiPattern(gismu, it[1])).filterIt(it.form.isSome)


func hyphenBefore(rafsi: string): char =
  ## cuxna lo lerfu jorne poi lo cmalu rafsi poi se tarmi `CVV` ku'o cu cpacu ke'a pu `rafsi`
  ##   .i `n` cu se cuxna va'o lo nu `rafsi` cu se krasi `r`
  ##   .i va'o lo drata `r` cu se cuxna
  if rafsi[0] == 'r': 'n' else: 'r'


func formsHeld(texts: openArray[string]): set[Form] =
  ## zbasu lo selcmi be lo tarmi poi `texts` cu se tarmi ke'a
  ##   .i lo se ciska poi se tarmi no tarmi cu jmina no tarmi
  for text in texts:
    let found = text.form
    if found.isSome: result.incl found.get


func countPairs(text: string): int =
  ## kancu lo remei be lo lamji zunsna ne'i le se ciska
  for i in 0..<text.high:
    if text[i] in ORDER_CONSONANTS and text[i+1] in ORDER_CONSONANTS: inc result


func isBrivlaRestated(text: string): bool =
  ## jdice lo du'u xu kau le se ciska cu ckaji le se ckaji pe `CLL 4.3`
  ##   .i le se ckaji cu rapli se ciska gi'e sepli `isBrivla`
  ##   .i le se ckaji cu du lo ka se fanmo lo karsna kei jo'u lo ka vasru lo zunsna remei ne'i le mu
  ##     lerfu poi krasi
  ##   .i `y` .e zoi gy. ' .gy. cu se vimcu pu lo nu kancu
  let counted = text.filterIt(it notin {'y', '\''})
  if text.len == 0 or text[^1] notin ORDER_VOWELS: return false
  counted[0..<min(counted.len, 5)].join.countPairs > 0


func wordsListed(): (seq[string], seq[string]) =
  ## fendi lo valsi pe le gismu liste fi lo cmavo jo'u lo gismu
  ##   .i ro le re klesi cu porsi ja'i le gismu liste
  for entry in LIST_GISMU:
    if entry.word.len == 5: result[1].add entry.word else: result[0].add entry.word


proc mutate(text: string): string =
  ## galfi pa lerfu pe `text` noi se cuxna ta'i lo nu cunso ku'o lo lerfu pe `CLL 3.1` .a lo fange
  ##   lerfu
  result = text
  result[rand(text.high)] = sample(ALPHABET & LETTERS_FOREIGN)


proc insertUncounted(text: string): string =
  ## punji `y` .a zoi gy. ' .gy. lo cunso stuzi poi lidne lo romoi lerfu pe `text`
  let at = rand(text.high)
  text[0..<at] & sample(['y', '\'']) & text[at .. ^1]


proc drawLengthened(words: seq[string]): seq[string] =
  ## cuxna lo valsi pe `words`
  ##   .i lo te kancu cu du `SAMPLES_LONG`
  ##   .i ro le valsi cu te jmina lo lerfu poi lo te kancu be ke'a cu cmima li pa bi'o li vo
  ##   .i lo tsiju cu jdice le nu cuxna .e le nu jmina
  result = newSeqOfCap[string](SAMPLES_LONG)
  for _ in 1..SAMPLES_LONG:
    var text = sample(words)
    for _ in 1..rand(1..4): text.add sample(ALPHABET & LETTERS_FOREIGN)
    result.add text


proc drawInserted(kinds: openArray[seq[string]]): seq[(string, string)] =
  ## cuxna lo valsi pe ro klesi
  ##   .i lo te kancu be lo valsi pe ro klesi cu du `SAMPLES_INSERTION`
  ##   .i ro valsi cu kansa lo fukpi be vo'a be'o poi `y` .a zoi gy. ' .gy. cu se punji fi ke'a
  result = newSeqOfCap[(string, string)](SAMPLES_INSERTION * kinds.len)
  for words in kinds:
    for _ in 1..SAMPLES_INSERTION:
      let text = sample(words)
      result.add (text, text.insertUncounted)


proc drawMutated(words: seq[string]): seq[string] =
  ## cuxna lo valsi pe `words`
  ##   .i lo te kancu cu du `SAMPLES_MUTATION`
  ##   .i pa lerfu pe ro le valsi cu se galfi
  ##   .i lo tsiju cu jdice le nu cuxna .e le nu galfi
  result = newSeqOfCap[string](SAMPLES_MUTATION)
  for _ in 1..SAMPLES_MUTATION: result.add mutate(sample(words))


func runsVowel(first: openArray[string], length_max: int): seq[string] =
  ## jmina lo porsi be lo karsna be'o poi lo te kancu be lo lerfu pe ke'a cu na zmadu `length_max`
  ##   .i pa midju pe `first` cu krasi ro porsi
  ##   .i ro drata pagbu cu du pa karsna .a pa karsna remei pe `CLL 4.1` gi'e se lidne zoi gy. '
  ##     .gy.
  ##   .i lo nu zbasu cu klama fi lo krasi fe lo fanmo gi'e sepli `isCmavo` noi tcidu le se zbasu
  var frontier = @first.filterIt(it.len <= length_max)
  while frontier.len > 0:
    result.add frontier
    var longer: seq[string]
    for run in frontier:
      for nucleus in @ORDER_VOWELS.mapIt($it) & @DIPHTHONGS_NOTATION:
        if run.len + 1 + nucleus.len <= length_max: longer.add run & "'" & nucleus
    frontier = longer


func cmavoGenerated(length_max: int): HashSet[string] =
  ## zbasu ro cmavo pe `CLL 4.2` poi lo te kancu be lo lerfu pe ke'a cu na zmadu `length_max` gi'e
  ##   vasru lo lerfu pe `ALPHABET_CMAVO` po'o
  ##   .i ro cmavo cu se zbasu ta'i lo nu jmina pa pagbu ro roi
  let nuclei = @ORDER_VOWELS.mapIt($it) & @DIPHTHONGS_NOTATION
  # `V` .e `VV` .e lo sakli karsna
  for run in runsVowel(nuclei & @GLIDES_ON, length_max): result.incl run
  for consonant in ALPHABET_CMAVO:
    if consonant notin ORDER_CONSONANTS: continue
    for run in runsVowel(nuclei, length_max - 1): result.incl consonant & run  # `CV` .e `CVV`
    result.incl consonant & "y"  # lo lerfu cmavo po'u `Cy` to `CLL 4.2` .e `CLL 17.2` toi
  result.incl "y"  # lo cmavo po'u zo .y. to `CLL 4.2` toi
  result.incl "y'y"  # lo lerfu cmavo pe zoi gy. ' .gy. to `CLL 17.2` toi


iterator samples[T](pool: seq[T]): lent T =
  ## dunda ro mupli pe le vasru poi pu se zbasu
  ##   .i fukpi no da
  for i in 0..<pool.len: yield pool[i]



suite "Chapter 4":
  test "Section 4.1":
    for length in 0..2:
      for text in texts(positionsAny(length)):  # ro le sosoci lerpoi
        check text.form.isNone  # ja'i `CLL 4.6` lo rafsi poi traji lo ka cmalu cu vasru ci lerfu
    # ja'i le pamoi javni pe `CLL 4.1` zoi gy. V .gy. na sinxa `y`
    #   .i le lerpoi cu se zbasu
    check "sya".form.isNone and "byk".form.isNone  # `CLL 4.1`
    # ja'i le pamoi javni pe `CLL 4.1` zoi gy. V .gy. na sinxa `y`
    #   .i le lerpoi cu se zbasu
    check "sy'a".form.isNone and "lerfy".form.isNone  # `CLL 4.1`
    # ja'i le cimoi javni pe `CLL 4.1` zoi gy. C .gy. cu sinxa lo cmalu lerfu po'o to `CLL 3.1` toi
    #   .i le lerpoi cu se zbasu
    check "SAL".form.isNone and "Sal".form.isNone  # `CLL 4.1`
    # le cimoi javni pe `CLL 4.1`
    #   .i lo barda lerfu cu zvati lo cmene po'o to `CLL 3.1` toi
    #   .i le lerpoi cu se zbasu
    check "BLANU".form.isNone  # `CLL 4.1`
    # le cimoi javni pe `CLL 4.1`
    #   .i lo barda lerfu cu zvati lo cmene po'o to `CLL 3.1` toi
    #   .i le lerpoi cu se zbasu
    check not "Blanu".isGismu  # `CLL 4.1`
    # ja'i `CLL 3.3` `h` no roi sinxa zoi gy. ' .gy.
    #   .i le lerpoi cu se zbasu
    check "sahi".form.isNone  # `CLL 3.3`
    # le remoi javni pe `CLL 4.1` cu cusku `V'V`
    #   .i le lerpoi cu se zbasu
    check "s'ai".form.isNone and "'sai".form.isNone  # `CLL 4.1`
    # le lerpoi cu se zbasu
    check "sai'".form.isNone  # le remoi javni pe `CLL 4.1` cu cusku `V'V`
    # ja'i `CLL 3.3` denpa bu ne'i lo valsi cu fendi le valsi fi re valsi
    #   .i le lerpoi cu se zbasu
    check "sa.i".form.isNone  # `CLL 3.3`
    # ja'i `CLL 4.4` no gismu cu vasru zoi gy. ' .gy.
    #   .i le lerpoi cu se zbasu
    check "sa'ai".form.isNone  # `CLL 4.4`
    # `CLL 4.4` cu skicu lo gismu fo zoi gy. always have five letters .gy.
    #   .i le lerpoi cu se zbasu
    check "saklii".form.isNone  # `CLL 4.4`
    let (_, words_gismu) = wordsListed()
    randomize(0)
    let pool = drawLengthened(words_gismu)
    for text in pool.samples:  # `SAMPLES_LONG` cu te kancu le lerpoi poi lo tsiju cu jdice ke'a
      check text.form.isNone  # `CLL 4.4` cu skicu lo gismu fo zoi gy. always have five letters .gy.


  test "Section 4.2":
    # lo tarmi po'u `V` pe `CLL 4.2`
    #   .i lo denpa na se ciska to `CLL 3.3` toi
    for text in ["a", "e", "i", "o", "u"]: check text.isCmavo
    # lo tarmi po'u `CV` pe `CLL 4.2`
    for text in ["ba", "ce", "di", "fo", "gu"]: check text.isCmavo
    # lo tarmi po'u `VV` pe `CLL 4.2`
    for text in ["au", "ei", "ia", "o'u", "u'e"]: check text.isCmavo
    # lo tarmi po'u `CVV` pe `CLL 4.2`
    for text in ["ki'a", "pei", "mi'o", "coi", "cu'u"]: check text.isCmavo
    check "y".isCmavo  # lo cmavo po'u zo .y. pe `CLL 4.2` to lo denpa na se ciska toi
    # ja'i `CLL 4.2` le cmavo cu cipra cmavo
    for text in ["ku'a'e", "sau'e", "bai'ai"]: check text.isCmavo
    # `Example 4.4` pe `CLL 4.2` cu skicu le valsi fo zoi gy. single cmavo .gy.
    #   .i le valsi cu vasru vo karsna
    check "ki'e'u'e".isCmavo  # `Example 4.4`
    # `CLL 4.2` cu cusku zoi gy. ten additional diphthongs .gy.
    for text in GLIDES_ON: check text.isCmavo
    # ja'i `CLL 4.2` le pano sakli karsna cu mintu le pano sakli karsna pe le liste pe `CLL 3.4`
    check sorted(DIPHTHONGS_CMAVO) == sorted(GLIDES_ON)  # `CLL 4.2`
    # ja'i `CLL 17.2` ro le valsi cu du pa cmavo be zoi gy. BY .gy.
    for text in ["by", "cy", "dy", "zy", "y'y"]: check text.isCmavo
    # `Example 4.1` pe `CLL 4.2`
    #   .i lo cmavo gunma po'u lo'u .i se ci'i le'u
    check not "iseci'i".isCmavo  # `Example 4.1`
    check not "punaijecanai".isCmavo  # `Example 4.2` pe `CLL 4.2` to lo cmavo gunma toi
    # `Example 4.3` pe `CLL 4.2`
    #   .i lo cmavo gunma
    #   .i lo denpa cu lidne zo .u'e
    check not "ki'e.u'e".isCmavo  # `Example 4.3`
    check not "cy.ibu.abu".isCmavo  # `Example 4.5` pe `CLL 4.2` to lo cmavo gunma toi
    # `CLL 4.3` cu skicu le valsi fo zoi gy. must be compound cmavo .gy.
    check not "da'amei".isCmavo  # `CLL 4.3`
    # ja'i `CLL 4.2` lo zunsna remei cu sinxa lo nu le valsi na cmavo
    check not "bla".isCmavo and not "klama".isCmavo  # `CLL 4.2`
    # ja'i `CLL 3.4` lo sakli karsna cu zvati no valsi poi na sepli
    #   .i le lerpoi cu se zbasu
    check not "cia".isCmavo  # `CLL 3.4`
    # `Example 4.1` pe `CLL 4.2`
    #   .i lo'u .i se ci'i le'u
    check ".iseci'i".splitCompound == @["i", "se", "ci'i"]  # `Example 4.1`
    # `Example 4.2` pe `CLL 4.2`
    check "punaijecanai".splitCompound == @["pu", "nai", "je", "ca", "nai"]  # `Example 4.2`
    # `Example 4.3` pe `CLL 4.2`
    #   .i lo denpa cu stali
    check "ki'e.u'e".splitCompound == @["ki'e", "u'e"]  # `Example 4.3`
    # `Example 4.4` pe `CLL 4.2` cu cusku zoi gy. single cmavo .gy.
    check "ki'e'u'e".splitCompound == @["ki'e'u'e"]  # `Example 4.4`
    check "cy.ibu.abu".splitCompound == @["cy", "i", "bu", "a", "bu"]  # `Example 4.5` pe `CLL 4.2`
    # `CLL 4.3` cu cusku zoi gy. must be compound cmavo .gy.
    check "da'amei".splitCompound == @["da'a", "mei"]  # `CLL 4.3`
    # `CLL 4.6` cu cusku zoi gy. breaks up into two cmavo .gy.
    check "ro'ire'o".splitCompound == @["ro'i", "re'o"]  # `CLL 4.6`
    # ja'i `CLL 4.2` lo zunsna remei cu sinxa lo nu le valsi na cmavo gunma
    check "klama".splitCompound.len == 0  # `CLL 4.2`
    # `CLL 3.4`
    #   .i lo sakli karsna cu se lidne lo zunsna
    #   .i le lerpoi cu se zbasu
    check "cia".splitCompound.len == 0  # `CLL 3.4`
    # ja'i `CLL 3.3` zoi gy. ' .gy. cu jorne re karsna
    check not "".isCmavo and not "'a".isCmavo and not "a'".isCmavo  # `CLL 3.3`
    let generated = cmavoGenerated(LENGTH_CMAVO)
    var count_cmavo = 0
    for length in 0..LENGTH_CMAVO:
      for text in texts(newSeqWith(length, ALPHABET_CMAVO)):  # ro le musozebizepa lerpoi
        # ja'i `CLL 4.2` lo tarmi poi se zbasu ta'i lo nu jmina pa pagbu ro roi cu tugni `isCmavo`
        check text.isCmavo == (text in generated)  # `CLL 4.2`
        if text.isCmavo: inc count_cmavo
    # lo nu lo te kancu cu stali
    #   .i ro tarmi poi se zbasu cu du pa lerpoi poi se tcidu
    check count_cmavo == generated.len  # lo nu lo te kancu cu stali


  test "Section 4.2 over cmavo list":
    let lines = readLinesCmavo()
    if lines.isNone: skip()  # `cmavo.txt` na zvati gi'a cenba to `texts_outside.nim` toi
    else:
      var count_simple = 0
      for line in lines.get:  # ro linji pe le liste
        # ja'i `CLL 3.3` denpa bu cu sinxa lo denpa noi lo tarmi na tcidu ke'a
        let bare = line.word.replace(".", "")
        # ja'i `CLL 4.2` le linji cu vasru pa cmavo poi mapti lo tarmi ku'o .a lo cmavo gunma
        check bare.isCmavo == not line.is_compound  # `CLL 4.2`
        if not line.is_compound: inc count_simple
      # ja'i `Article IX.3` le bandu cu curmi lo cmavo poi banzu
      check count_simple >= FLOOR_CMAVO_SIMPLE  # `Article IX.3`

  test "Section 4.3":
    check isBrivla("bisycla")  # ja'i `CLL 4.3` `sc` cu se kancu ki'u lo nu `y` na se kancu
    # ja'i `CLL 4.3` `nr` cu se kancu ki'u lo nu zoi gy. ' .gy. na se kancu
    check isBrivla("ro'inre'o")  # `CLL 4.3`
    check not isBrivla("da'amei")  # ja'i `CLL 4.3` lo cmavo gunma cu vasru no zunsna remei
    check not isBrivla("lojban.")  # ja'i `CLL 4.3` lo cmene cu se fanmo no karsna
    check not isBrivla("lojban")  # ja'i `CLL 4.3` ro cmene cu se fanmo lo zunsna
    # ja'i `CLL 4.3` `bl` cu vomoi je mumoi le lerfu poi se kancu
    #   .i le lerpoi cu se zbasu
    check isBrivla("ba'ibla")  # `CLL 4.3`
    # ja'i `CLL 4.3` `bl` cu mumoi je xamoi lerfu gi'e na zvati le mu lerfu poi krasi
    #   .i le lerpoi cu se zbasu
    check not isBrivla("bababla")  # `CLL 4.3`
    check not isBrivla("")  # ja'i `CLL 4.3` no karsna cu fanmo
    for length in 1..7:
      for text in texts(newSeqWith(length, "bla'y")):  # ro le sozexamumu lerpoi
        # ja'i `CLL 4.3` le ci se ckaji
        #   .i lo nu basna na se ciska
        check isBrivla(text) == isBrivlaRestated(text)  # `CLL 4.3`
    let (words_cmavo, words_gismu) = wordsListed()
    # ja'i `CLL 4.4` lo gismu cu mapti lo javni pe ro brivla
    for text in words_gismu: check isBrivla(text)
    # ja'i `CLL 4.3` lo zunsna remei cu jarco lo du'u le valsi na cmavo
    for text in words_cmavo: check not isBrivla(text)
    for text in words_cmavo & words_gismu:
      let bare = text.multiReplace(("y", ""), ("'", ""))
      # `CLL 4.3` cu skicu `y` .e zoi gy. ' .gy. fo zoi gy. not counted .gy.
      check isBrivla(bare) == isBrivla(text)  # `CLL 4.3`
      # ja'i `CLL 4.3` lo fanmo lerfu cu karsna
      check not isBrivla(text & "n") and not isBrivla(text & ".")  # `CLL 4.3`
    randomize(0)
    let pool = drawInserted([words_cmavo, words_gismu])
    # `SAMPLES_INSERTION` cu te kancu lo valsi pe ro klesi
    #   .i lo tsiju cu jdice le valsi
    for (text, inserted) in pool.samples:
      check isBrivla(inserted) == isBrivla(text)  # ja'i `CLL 4.3` `y` .e zoi gy. ' .gy. na se kancu


  test "Section 4.4":
    check "creka".form == some(Form.Ccvcv)  # `Example 4.11` pe `CLL 4.4`
    check "lijda".form == some(Form.Cvccv)  # `Example 4.12` pe `CLL 4.4`
    check "blanu".form == some(Form.Ccvcv)  # `Example 4.13` pe `CLL 4.4`
    check "mamta".form == some(Form.Cvccv)  # `Example 4.14` pe `CLL 4.4`
    check "cukta".form == some(Form.Cvccv)  # `Example 4.15` pe `CLL 4.4`
    check "patfu".form == some(Form.Cvccv)  # `Example 4.16` pe `CLL 4.4`
    check "nanmu".form == some(Form.Cvccv)  # `Example 4.17` pe `CLL 4.4`
    check "ninmu".form == some(Form.Cvccv)  # `Example 4.18` pe `CLL 4.4`
    for text in ["creka", "lijda", "blanu", "mamta", "cukta", "patfu", "nanmu", "ninmu"]:
      check text.isGismu  # `Examples 4.11-18` pe `CLL 4.4`
    for text in texts(positionsNotation("CVCCV")):  # ro le pararebiremu lerpoi
      let expected = if isPairPermissible(text[2], text[3]): some(Form.Cvccv) else: none(Form)
      # ja'i `CLL 4.4` lo midju zunsna remei pe `CVC/CV` cu bilga lo ka se curmi po'o
      check text.form == expected  # `CLL 4.4`
    var count_ccvcv = 0
    for text in texts(positionsNotation("CCVCV")):  # ro le pararebiremu lerpoi
      let expected = if isPairInitial(text[0], text[1]): some(Form.Ccvcv) else: none(Form)
      # `CLL 4.4` cu skicu lo zunsna remei poi krasi `CCVCV` ku'o fo zoi gy. permissible initial
      #   pair .gy.
      check text.form == expected  # `CLL 4.4`
      if text.isGismu: inc count_ccvcv
    # ja'i `CLL 4.4` ro valsi poi se tarmi `CCVCV` cu se krasi pa le vobi zunsna remei poi ka'e
    #   krasi lo valsi ja'i le vomoi javni pe `CLL 4.1`
    check count_ccvcv == 48 * 5 * 17 * 5  # `CLL 4.4`
    let (words_cmavo, words_gismu) = wordsListed()
    check words_gismu.len in 1300..1400  # `CLL 4.4` cu cusku zoi gy. about 1350 gismu .gy.
    var lut_words_by_stem: Table[string, seq[string]]
    for text in words_gismu:
      check text.isGismu  # ja'i `CLL 4.4` lo gismu cu se tarmi `CVC/CV` .a `CCVCV`
      # `CLL 4.4` cu skicu lo gismu fo zoi gy. always start with consonant .gy.
      check text[0] in ORDER_CONSONANTS  # `CLL 4.4`
      # ja'i `CLL 4.4` pa karsna po'o cu fanmo
      check text[3] in ORDER_CONSONANTS and text[4] in ORDER_VOWELS  # `CLL 4.4`
      check text.countPairs == 1  # `CLL 4.4` cu cusku zoi gy. exactly one consonant pair .gy.
      check '\'' notin text  # ja'i `CLL 4.4` no gismu cu vasru zoi gy. ' .gy.
      for i in 0..4:
        var broken = text
        broken[i] = '\''
        check not broken.isGismu  # ja'i `CLL 4.4` no gismu cu vasru zoi gy. ' .gy.
      lut_words_by_stem.mgetOrPut(text[0..3], @[]).add text
    for stem, words in lut_words_by_stem:
      if stem == "brod": check words == @["broda", "brode", "brodi", "brodo", "brodu"]  # `CLL 4.4`
      # ja'i `CLL 4.4` no re drata gismu cu frica fi lo fanmo karsna po'o
      else: check words.len == 1
    check lut_words_by_stem.hasKey("brod")  # ja'i `CLL 4.4` mu brivla cu ka'e basti ro selbri
    for text in words_cmavo:
      # ja'i `CLL 4.3` lo zunsna remei cu jarco lo brivla
      #   .i lo gismu cu brivla
      check not text.isGismu  # `CLL 4.3`
    randomize(0)
    let pool = drawMutated(words_gismu)
    var count_shaped = 0
    for text in pool.samples:  # `SAMPLES_MUTATION` cu te kancu le lerpoi poi lo tsiju cu jdice ke'a
      # ja'i `CLL 4.4` mu lerfu cu se tarmi `CVC/CV` .a `CCVCV` .a no tarmi
      check text.form == text.formRestated  # `CLL 4.4`
      if text.formRestated.isSome: inc count_shaped
    # le se cipra cu ralte lo tarmi be lo gismu to `Article IX.3` toi
    check count_shaped >= FLOOR_MUTATION  # `Article IX.3`
    # le se cipra cu ralte ji'a lo drata lerpoi
    check count_shaped <= SAMPLES_MUTATION - FLOOR_MUTATION  # ji'a ralte lo drata lerpoi


  test "Section 4.6":
    var counts: array[Form, int]
    for length in 3..4:
      for text in texts(positionsAny(length)):  # ro le somucicipare lerpoi
        let found = text.form
        check found == text.formRestated  # lo tarmi pe `CLL 4.6` ja'i lo sinxa pe `CLL 4.1`
        if found.isSome: inc counts[found.get]
    # `CLL 4.6` cu cusku zoi gy. only if .gy.
    #   .i `CCV` cu rafsi va'o lo nu le zunsna remei cu ka'e krasi lo valsi
    check counts[Form.Ccv] == 48 * 5  # `CLL 4.6`
    # ja'i `CLL 4.6` ro rafsi poi se tarmi `CCVC` cu se krasi pa le vobi zunsna remei pe le vomoi
    #   javni pe `CLL 4.1`
    check counts[Form.Ccvc] == 48 * 5 * 17  # `CLL 4.6`
    # ja'i `CLL 4.6` le karsna remei cu du `ai` jo'u `ei` jo'u `oi` jo'u `au`
    check sorted(forms.DIPHTHONGS) == sorted(DIPHTHONGS_NOTATION)  # `CLL 4.6`
    for (labelled, pattern, rafsi) in ROWS_SAKLI:
      check rafsiPattern("sakli", pattern) == rafsi  # le liste pe zo sakli ne'i `CLL 4.6`
      check rafsi.form == some(labelled)  # le liste pe zo sakli ne'i `CLL 4.6`
    for (labelled, pattern, rafsi) in ROWS_BLACI:
      check rafsiPattern("blaci", pattern) == rafsi  # le liste pe zo blaci ne'i `CLL 4.6`
      check rafsi.form == some(labelled)  # le liste pe zo blaci ne'i `CLL 4.6`
    # `CLL 4.6` cu cusku zoi gy. can only have .gy.
    check rafsiPossible("mamta") == @["mam", "mat", "ma'a"]  # `CLL 4.6`
    check "mamta".form == "salci".form  # ja'i `CLL 4.6` zo mamta cu se tarmi lo tarmi be zo salci
    var
      exceptions_table, exceptions_letters: seq[string]
      count_possible_most = 0
    for entry in LIST_GISMU:
      let text = entry.word
      if not text.isGismu: continue
      let possible = rafsiPossible(text)
      count_possible_most = max(count_possible_most, possible.len)
      let unreduced = if text.form == some(Form.Cvccv): Form.Cvcc else: Form.Ccvc
      # ja'i `CLL 4.6` lo rafsi poi vasru vo lerfu cu du lo gismu poi lo fanmo karsna pe ke'a cu se
      #   vimcu
      check text[0..3].form == some(unreduced)  # `CLL 4.6`
      # `CLL 4.6` cu cusku zoi gy. from two to five rafsi .gy.
      #   .i re le rafsi cu clani
      check entry.rafsi.len <= 3  # `CLL 4.6`
      var forms_seen: set[Form]
      for one in entry.rafsi:
        let found = one.form
        # `CLL 4.6` cu cusku zoi gy. CVC, CCV, or CVV .gy.
        check found.isSome and found.get in FORMS_SHORT  # `CLL 4.6`
        check found == one.formRestated  # lo javni pe `CLL 4.6` cu jimte `CVV` .e `CCV`
        if found.isNone: continue
        # `CLL 4.6` cu cusku zoi gy. at most one .gy.
        #   .i ro gismu cu ponse su'e pa rafsi pe ro tarmi
        check found.get notin forms_seen  # `CLL 4.6`
        forms_seen.incl found.get
        if one notin possible: exceptions_table.add text & " " & one
        if not one.allIt(it == '\'' or it in text): exceptions_letters.add text & " " & one
      for (labelled, pattern, _) in text.rows:
        let spelled = rafsiPattern(text, pattern)
        # lo tarmi pe ro linji be le liste pe `CLL 4.6`
        check spelled.form.isNone or spelled.form == some(labelled)  # `CLL 4.6`
    # `CLL 4.6` cu skicu lo cmalu rafsi fo zoi gy. that can possibly exist .gy.
    check exceptions_table == EXCEPTIONS_TABLE  # `CLL 4.6`
    # ja'i `CLL 4.6` lo lerfu pe ro cmalu rafsi cu se cuxna fi le mu lerfu pe le gismu
    check exceptions_letters == EXCEPTIONS_LETTERS  # `CLL 4.6`
    # `CLL 4.6` cu cusku zoi gy. at most seven possible short rafsi .gy.
    check count_possible_most == 7  # `CLL 4.6`
    var vowels_paired: seq[string]
    for entry in LIST_GISMU:
      for one in entry.rafsi:
        if one.form == some(Form.Cvv): vowels_paired.add one
    for second in vowels_paired:
      # ja'i `CLL 4.6` `n` cu basti `r`
      #   .i `CLL 4.6` cu cusku zoi gy. in place of .gy.
      check isPairPermissible(second.hyphenBefore, second[0])  # `CLL 4.6`
    for first in vowels_paired:
      for second in vowels_paired:  # ro le pazezerevopa remei
        # `CLL 4.6` cu skicu lo nu `CVV` cu lidne `CVV` kei fo zoi gy. would be no consonant cluster
        #   .gy.
        check not isBrivla(first & second)  # `CLL 4.6`
        # `CLL 4.6` cu cusku zoi gy. hyphen is always required .gy.
        check isBrivla(first & second.hyphenBefore & second)  # `CLL 4.6`
    # `CLL 4.6` cu skicu `ro'irre'o` fo zoi gy. impermissible double consonant .gy.
    check not isPairPermissible('r', 'r')  # `CLL 4.6`
    check not isBrivla("ro'ire'o")  # `CLL 4.6` cu cusku zoi gy. breaks up into two cmavo .gy.
    # ja'i `CLL 4.6` `y` na se kancu
    #   .i `CLL 4.6` cu cusku zoi gy. this is why .gy.
    check isBrivla("patyta'a") and isBrivla("mudysiclu")  # `CLL 4.6`
    # ja'i `CLL 4.6` pa le re valsi cu vasru lo lerfu jorne
    #   .i le drata cu vasru no lerfu jorne
    check isBrivla("ro'inre'o") and isBrivla("rokre'o")  # `CLL 4.6`


  test "Section 4.3-6 over lujvo list":
    let lines = readLinesLujvo()
    if lines.isNone: skip()  # `lujvo.txt` na zvati gi'a cenba to `texts_outside.nim` toi
    else:
      let words_lujvo = lines.get.mapIt(it.word)
      for text in words_lujvo:  # ro valsi pe le liste
        check isBrivla(text)  # ja'i `CLL 4.6` lo lujvo cu brivla gi'e vasru lo zunsna gunma ji'a
        # `CLL 4.4` cu cusku zoi gy. five letter length distinguishes gismu from lujvo .gy.
        check not text.isGismu  # `CLL 4.4`
        check text.len >= 6  # `CLL 4.6` cu cusku zoi gy. all lujvo have at least six letters .gy.
        let bare = text.multiReplace(("y", ""), ("'", ""))
        # `CLL 4.3` cu skicu `y` .e zoi gy. ' .gy. fo zoi gy. not counted .gy.
        check isBrivla(bare) == isBrivla(text)  # `CLL 4.3`
        # ja'i `CLL 4.3` lo fanmo lerfu cu karsna
        check not isBrivla(text & "n") and not isBrivla(text & ".")  # `CLL 4.3`
      randomize(0)
      let pool = drawInserted([words_lujvo])
      # `SAMPLES_INSERTION` cu te kancu le valsi poi lo tsiju cu jdice ke'a
      for (text, inserted) in pool.samples:
        # ja'i `CLL 4.3` `y` .e zoi gy. ' .gy. na se kancu
        check isBrivla(inserted) == isBrivla(text)  # `CLL 4.3`


  test "Section 4.11":
    # `CLL 4.6` cu cusku zoi gy. CVC, CCV, or CVV .gy.
    check FORMS_SHORT == {Form.Cvc, Form.Ccv, Form.Cvv}  # `CLL 4.6`
    # ja'i `CLL 4.6` lo rafsi poi vasru vo lerfu cu se tarmi `CVC/C` .a `CCVC`
    check FORMS_UNREDUCED == {Form.Cvcc, Form.Ccvc}  # `CLL 4.6`
    check FORMS_GISMU == {Form.Cvccv, Form.Ccvcv}  # `CLL 4.4` cu cusku zoi gy. CVC/CV or CCVCV .gy.
    check FORMS_FINAL == {Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv}  # `CLL 4.11 step 2`
    var texts_short, texts_unreduced, texts_gismu: seq[string]
    for entry in LIST_GISMU:
      texts_short.add entry.rafsi
      if entry.word.isGismu:
        texts_unreduced.add entry.word[0..3]
        texts_gismu.add entry.word
    # `CLL 4.6` cu skicu lo cmalu rafsi pe le liste fo zoi gy. CVC, CCV, or CVV .gy.
    check formsHeld(texts_short) == FORMS_SHORT  # `CLL 4.6`
    # `CLL 4.6` cu skicu `CVC/C` .e `CCVC` fo zoi gy. 4-letter rafsi .gy.
    check formsHeld(texts_unreduced) == FORMS_UNREDUCED  # `CLL 4.6`
    # `CLL 4.4` cu skicu lo gismu pe le liste fo zoi gy. CVC/CV or CCVCV .gy.
    check formsHeld(texts_gismu) == FORMS_GISMU  # `CLL 4.4`
    for text in texts_short & texts_unreduced & texts_gismu:
      let found = text.form
      check found.isSome  # ja'i `CLL 4.6` ro rafsi cu se tarmi su'o tarmi
      if found.isSome:
        # ja'i `CLL 4.6` le tarmi cu se fanmo lo karsna
        check (text[^1] in ORDER_VOWELS) == (found.get in FORMS_FINAL)  # `CLL 4.6`



suite "Internal: Forms":
  test "Compound of listed cmavo splits back into them":
    randomize(0)
    var count_long = 0
    # `SAMPLES_COMPOUND` cu te kancu le cmavo gunma poi lo tsiju cu jdice ke'a
    for _ in 1 .. SAMPLES_COMPOUND:
      var (words, text) = (newSeq[string](), "")
      for i in 1 .. rand(1 .. 5):
        let word = LIST_CMAVO[rand(LIST_CMAVO.high)].word
        # ja'i `CLL 3.3` lo denpa cu lidne lo karsna
        if i > 1 and not word[0].isConsonant: text.add '.'
        text.add word
        words.add word
      # ja'i `CLL 4.2` lo cmavo gunma cu se fendi ta'i pa tadji po'o
      #   .i ro cmavo cu stali
      check text.splitCompound == words  # `CLL 4.2`
      if words.len >= 2: inc count_long
    # ja'i `Article IX.3` le bandu cu curmi lo cmavo gunma poi vasru su'o re cmavo
    check count_long >= FLOOR_COMPOUND  # `Article IX.3`


  test "Comma leaves no form":
    for entry in LIST_GISMU:
      for text in entry.rafsi & @[entry.word]:
        for at in 1..text.high:
          let spelled = text[0..<at] & ',' & text[at .. ^1]
          # lo se cuxna be le vi se gunka
          #   .i `tanru.nim` cu to'e curmi slaka bu pu lo nu `form` cu tcidu
          check spelled.form.isNone  # lo se cuxna be le vi se gunka
