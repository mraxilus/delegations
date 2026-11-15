## rapli zbasu lo rafsi .e lo gismu vu'o poi `CLL 4` cu cusku ke'a gi'e cipra lo du'u lo nu sisku pe
##   `dictionary.nim` cu mapti le se zbasu
##   .i le cipra cu sisku ro liste cmima .e ro cmalu rafsi .e ro lerpoi poi se tarmi lo tarmi be lo
##     cmalu rafsi .a lo rafsi poi vasru vo lerfu
##   .i se ki'u bo le cipra cu tcidu lo mulno se tcidu be ro sisku fancu to `Article IX.3` toi
##   .i le cipra cu tcidu lo mupli be lo lerpoi poi na zvati le liste
##   .i lo tsiju cu jdice le mupli
##   .i ro mupli cu se zbasu ta'i lo nu basti pa lerfu pe pa valsi pe le liste
##   .i le cipra cu karbi ro nu sisku lo nu tcidu ro liste cmima pe `LIST_GISMU` ta'i lo porsi
##   .i le nu tcidu cu se ciska vi gi'e sepli lo nu sisku pe `dictionary.nim` ta'i lo nu rapli fendi
##     fi re pagbu
##   .i se ki'u bo lo sisku liste poi porsi .e le nu sisku cu tugni le liste poi krasi le sisku
##     liste
##   .i ro cipra cu dunda pa tsiju le cupra be lo cunso namcu pa roi gi'e cuxna lo mupli pe vo'a
##     gi'e punji le mupli lo vasru
##   .i lo rapli fancu cu dunda le mupli pe le vasru
##   .i la'o gy. CLL .gy. cu cusku lo gismu .e lo lujvo ne'i `CLL 4.4` .e `CLL 4.6` .e `CLL 4.13` .e
##     `CLL 4.14` .e `CLL 4.15`
##   .i le cipra cu pilno le valsi ta'i lo mupli
##   .i le cipra cu sisku ro rafsi pe ro le valsi ja'i lo cmene gi'e no roi sisku ja'i lo namcu
##   .i va'o lo nu la'o gy. CLL .gy. cu dunda lo lujvo gi'e na fendi le lujvo fi lo rafsi kei lo
##     pinka cu vasru lu le nu fendi cu se sruma li'u
##   .i lo pinka be lo lerpoi poi no krasi cu vasru ke'a cu vasru lu le lerpoi cu se zbasu li'u
##   .i lo cipra pe `Internal: Dictionary` cu cipra lo se ckaji poi la'o gy. CLL .gy. na cusku ke'a
##   .i le se ckaji cu du lo klesi be ro valsi jo'u lo porsi jo'u lo nu ciska jo'u lo datni pagbu

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, unittest]

import ../../src/lojban_parser/[dictionary, forms]
import ../../src/lojban_parser/lists/gismu


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"
    ## le paze zunsna poi zoi gy. C .gy. cu sinxa ke'a to le cimoi javni pe `CLL 4.1` toi
  ORDER_VOWELS = "aeiou"
    ## le mu karsna poi zoi gy. V .gy. cu sinxa ke'a
    ##   .i zoi gy. V .gy. na sinxa `y` to le pamoi javni pe `CLL 4.1` toi
  ALPHABET = "',.abcdefgijklmnoprstuvxyz"
    ## lo lerfu pe `CLL 3.1` .e zoi gy. ' .gy. .e slaka bu .e denpa bu
  DIGITS = ["no", "pa", "re", "ci", "vo", "mu", "xa", "ze", "bi", "so"]
    ## lo cmavo pe le pano namcu po'u li no bi'o li so ja'i le liste pe `CLL 18.2`
  RAFSI_BLACI = ["bac", "lac", "ba'i", "bai", "la'i", "lai", "bla"]
    ## lo cmalu rafsi poi le liste pe `CLL 4.6` cu curmi lo nu zo blaci cu ponse ke'a
    ##   .i ro le rafsi cu se dunda fi lo drata valsi
  GISMU_ASSIGNABLE = ["broda", "brode", "brodi", "brodo", "brodu"]
    ## ja'i `CLL 4.15` lo brivla poi lo pilno cu ka'e dunda lo smuni ke'a
    ##   .i ro le brivla cu frica fi lo fanmo karsna po'o to `CLL 4.4` toi
  GISMU_COINED = ["cmavo", "lojbo", "lujvo", "mekso"]
    ## lo drata gismu poi se finti ja'i `CLL 4.15`
  GISMU_METRIC_SMALL = [
    "decti", "centi", "milti", "mikri", "nanvi", "picti", "femti", "xatsi", "zepti", "gocti",
  ]
    ## lo gismu poi sinxa lo cmalu ke merli namcu ja'i `CLL 4.15`
  GISMU_METRIC_LARGE = [
    "dekto", "xecto", "kilto", "megdo", "gigdo", "terto", "petso", "xexso", "zetro", "gotro",
  ]
    ## lo gismu poi sinxa lo barda ke merli namcu ja'i `CLL 4.15`
  GISMU_SCIENTIFIC = ["delno", "kelvo", "molro", "radno", "sinso", "stero", "tanjo", "xampo"]
    ## lo drata gismu poi saske ja cmaci valsi ja'i `CLL 4.15`
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
    ## lo kulnu gismu pe `CLL 4.15` ta'i lo porsi pe le papri
    ##   .i le gismu cu sinxa lo krasi bangu ce'o lo ze drata bangu ce'o lo gugde ce'o lo barda
    ##     tumla ce'o lo kulnu ce'o lo lijda ce'o lo se cmene poi kuspe su'o re girzu
  COUNT_LISTED_4_15 = 92
    ## lo te kancu be lo gismu poi `CLL 4.15` cu vasru ke'a
    ##   .i le te kancu cu se kancu ne'i le papri
    ##   .i la'o gy. CLL .gy. cu cusku no te kancu
  SAMPLES_MUTATION = 20000
    ## lo valsi pe le gismu liste zi'e poi pa lerfu pe ke'a cu se basti
    ##   .i le cipra cu sisku ro le valsi
    ##   .i lo tsiju cu jdice le valsi
  FLOOR_UNLISTED = 9450
    ## lo cnita jimte be lo te kancu be le se galfi poi na zvati le liste
    ##   .i se ki'u bo le cipra cu ro roi cipra fi lo nu sisku poi facki no da
    ##   .i le jimte cu xadba li pabisonomu
    ##   .i ca lo nu le tsiju cu du li no kei le te kancu cu du li pabisonomu
  FLOOR_LISTED = 177
    ## lo cnita jimte be lo te kancu be le se galfi poi du pa drata liste cmima
    ##   .i se ki'u bo le cipra cu ro roi cipra fi lo nu sisku poi facki pa liste cmima
    ##   .i le jimte cu xadba li cimuvo
    ##   .i ca lo nu le tsiju cu du li no kei le te kancu cu du li cimuvo
  SAMPLES_PAIRS = 20000  ## lo remei be lo valsi poi se karbi to lo tsiju cu jdice le remei toi
  STEMS_4_13 = [
    ("gerk", "gerku"), ("zdan", "zdani"), ("logj", "logji"), ("bang", "bangu"),
    ("girz", "girzu"), ("nakn", "nakni"), ("cins", "cinse"),
  ]
    ## lo rafsi poi vasru vo lerfu gi'e se ciska `CLL 4.13` ne'i lo mupli
    ##   .i ro rafsi cu kansa lo gismu pe vo'a


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


iterator words(): Word =
  ## dunda ro valsi pe le gismu liste ta'i lo porsi pe le liste
  for i in 0..<LIST_GISMU.len: yield Word(i)


func wordScanned(text: string): Option[Word] =
  ## facki lo liste cmima poi lo valsi pe ke'a cu du `text` ku'o ta'i lo nu tcidu ro liste cmima
  ##   ta'i lo porsi gi'e sepli `word`
  for i, entry in LIST_GISMU:
    if entry.word == text: return some(Word(i))
  none(Word)


func wordRafsiScanned(text: string): Option[Word] =
  ## facki lo valsi poi lo cmalu rafsi po'u `text` cu sinxa ke'a ku'o ta'i lo nu tcidu ro liste
  ##   cmima ta'i lo porsi gi'e sepli `wordRafsi`
  for i, entry in LIST_GISMU:
    if text in entry.rafsi: return some(Word(i))
  none(Word)


func wordsStemScanned(text: string): seq[Word] =
  ## facki lo gismu poi `text` cu krasi ke'a ku'o ta'i lo nu tcidu ro liste cmima ta'i lo porsi gi'e
  ##   sepli `wordsStem`
  ##   .i `text` cu bilga lo ka vasru vo lerfu
  if text.len != 4: return
  for i, entry in LIST_GISMU:
    if entry.word.len == 5 and entry.word.startsWith(text): result.add Word(i)


func isAssigned(rafsi, gismu: string): bool =
  ## jdice lo du'u xu kau lo cmalu rafsi po'u `rafsi` cu sinxa lo valsi po'u `gismu` noi zvati le
  ##   liste
  word(gismu).isSome and wordRafsi(rafsi) == word(gismu)


func rafsiSorted(text: string): seq[string] =
  ## tcidu lo cmalu rafsi poi le liste cu dunda ke'a lo valsi po'u `text`
  ##   .i le rafsi cu porsi
  ##   .i dunda lo kunti va'o lo nu le liste cu claxu le valsi
  let found = word(text)
  if found.isSome: result = sorted(found.get.entry.rafsi)


proc mutate(text: string): string =
  ## galfi pa lerfu pe `text` noi se cuxna ta'i lo nu cunso ku'o lo lerfu pe `CLL 3.1`
  result = text
  result[rand(text.high)] = sample(ALPHABET)


proc drawMutated(): seq[(string, string)] =
  ## cuxna lo valsi pe le gismu liste
  ##   .i lo te kancu cu du `SAMPLES_MUTATION`
  ##   .i ro valsi cu kansa lo fukpi be vo'a be'o poi pa lerfu pe ke'a cu se galfi
  ##   .i lo tsiju cu jdice le nu cuxna .e le nu galfi
  result = newSeqOfCap[(string, string)](SAMPLES_MUTATION)
  for _ in 1..SAMPLES_MUTATION:
    let source = LIST_GISMU[rand(LIST_GISMU.high)].word
    result.add (source, mutate(source))


proc drawPairs(): seq[(Word, Word)] =
  ## cuxna lo remei be lo valsi pe le gismu liste
  ##   .i lo te kancu cu du `SAMPLES_PAIRS`
  ##   .i lo tsiju cu jdice le nu cuxna
  result = newSeqOfCap[(Word, Word)](SAMPLES_PAIRS)
  for _ in 1..SAMPLES_PAIRS:
    let (i, j) = (rand(LIST_GISMU.high), rand(LIST_GISMU.high))
    result.add (Word(i), Word(j))


iterator samples[T](pool: seq[T]): lent T =
  ## dunda ro mupli pe le vasru poi pu se zbasu
  ##   .i fukpi no da
  for i in 0..<pool.len: yield pool[i]



suite "Chapter 4":
  test "Section 4.4":
    for text in ["creka", "lijda", "blanu", "mamta", "cukta", "patfu", "nanmu", "ninmu"]:
      check word(text).isSome  # `Examples 4.11-18` pe `CLL 4.4`
    check word("gismu").isSome  # ja'i `CLL 4.4` zo gismu cu cmima lo selcmi be lo gismu
    for text in ["kismu", "xismu", "gicmu", "gizmu", "gisnu"]:
      check word(text).isNone  # `CLL 4.4` cu skicu le valsi fo zoi gy. cannot be .gy.
    for w in words():
      let text = $w
      if text.len != 5: continue
      let found = wordsStem(text[0..3])
      # ja'i `CLL 4.6` lo rafsi poi vasru vo lerfu cu du lo gismu poi lo fanmo karsna pe ke'a cu se
      #   vimcu
      check w in found  # `CLL 4.6`
      # zo broda pe `CLL 4.4`
      if text.startsWith("brod"): check found.mapIt($it) == @GISMU_ASSIGNABLE
      else: check found == @[w]  # ja'i `CLL 4.4` no re gismu cu frica fi lo fanmo karsna po'o


  test "Section 4.6":
    var count_rafsi = 0
    for w in words():
      for one in w.entry.rafsi:
        inc count_rafsi
        # `CLL 4.6` cu cusku zoi gy. each such rafsi represents only one gismu .gy.
        check wordRafsi(one) == some(w)  # `CLL 4.6`
    var count_found = 0
    for notation in ["CVC", "CCV", "CVV", "CV'V"]:
      for text in texts(positionsNotation(notation)):  # ro le cizevono lerpoi
        let found = wordRafsi(text)
        # ja'i `CLL 4.6` le liste cu jdice lo rafsi
        #   .i no rafsi cu rapli se dunda
        check found == wordRafsiScanned(text)  # `CLL 4.6`
        if found.isSome: inc count_found
    # ja'i `CLL 4.6` ro cmalu rafsi pe le liste cu se facki
    #   .i no drata cu se facki
    check count_found == count_rafsi  # `CLL 4.6`
    # ja'i `CLL 4.6` lo cmalu rafsi cu vasru ci lerfu
    check wordRafsi("").isNone and wordRafsi("brod").isNone  # `CLL 4.6`
    # ja'i `CLL 4.6` le gismu cu rafsi vo'a gi'e vasru mu lerfu gi'e na cmalu rafsi
    check wordRafsi("sakli").isNone  # `CLL 4.6`
    # ja'i `CLL 3.1` lo barda lerfu cu zvati lo cmene po'o
    #   .i le lerpoi cu se zbasu
    check wordRafsi("SAL").isNone  # `CLL 3.1`
    # `CLL 4.6` cu skicu `sal` fo zoi gy. only actual short rafsi .gy.
    #   .i `sal` cu rafsi zo sakli
    check wordRafsi("sal").isSome  # `CLL 4.6`
    # ja'i `CLL 4.6` zo zmadu cu ponse `zma` .e `mau`
    check word("zmadu").get.entry.rafsi == @["zma", "mau"]  # `CLL 4.6`
    check isAssigned("zma", "zmadu") and isAssigned("mau", "zmadu")  # zo zmadu pe `CLL 4.6`
    # `CLL 4.6` cu skicu zo bakri fo zoi gy. has no short rafsi .gy.
    check word("bakri").get.entry.rafsi.len == 0  # `CLL 4.6`
    # `CLL 4.6` cu cusku zoi gy. only actual short rafsi .gy.
    check word("sakli").get.entry.rafsi == @["sal"]  # `CLL 4.6`
    # `CLL 4.6` cu skicu zo blaci fo zoi gy. has none of these .gy.
    check word("blaci").get.entry.rafsi.len == 0  # `CLL 4.6`
    for one in RAFSI_BLACI:
      let found = wordRafsi(one)
      # `CLL 4.6` cu cusku zoi gy. all assigned to other gismu .gy.
      check found.isSome and found != word("blaci")  # `CLL 4.6`
      # `CLL 4.6` cu cusku zoi gy. assigned to other gismu .gy.
      check found.isSome and found.get.kind == Kind.Gismu  # `CLL 4.6`
    # ja'i `CLL 4.6` `mam` po'o cu rafsi zo mamta
    #   .i `CLL 4.6` cu cusku zoi gy. is assigned to it .gy.
    check word("mamta").get.entry.rafsi == @["mam"]  # `CLL 4.6`
    # zo mamta pe `CLL 4.6`
    check not isAssigned("mat", "mamta") and not isAssigned("ma'a", "mamta")  # `CLL 4.6`
    # `Example 4.32` pe `CLL 4.6`
    #   .i zo cumfri
    #   .i le nu fendi cu se sruma
    check isAssigned("cum", "cumki")  # `Example 4.32`
    # `Example 4.32` pe `CLL 4.6`
    #   .i zo cumfri
    #   .i le nu fendi cu se sruma
    check isAssigned("fri", "lifri")  # `Example 4.32`
    # `Example 4.33` pe `CLL 4.6`
    #   .i zo klezba
    #   .i `CLL 4.13` cu cusku `kle`
    check isAssigned("kle", "klesi")  # `Example 4.33`
    # `Example 4.33` pe `CLL 4.6`
    #   .i zo klezba
    #   .i le nu fendi cu se sruma
    check isAssigned("zba", "zbasu")  # `Example 4.33`
    # `Example 4.34` pe `CLL 4.6`
    #   .i zo kixta'a
    #   .i le nu fendi cu se sruma
    check isAssigned("kix", "krixa")  # `Example 4.34`
    # `Example 4.34` pe `CLL 4.6`
    #   .i zo kixta'a
    #   .i le nu fendi cu se sruma
    check isAssigned("ta'a", "tavla")  # `Example 4.34`
    # `Example 4.35` pe `CLL 4.6`
    #   .i zo sniju'o
    #   .i le nu fendi cu se sruma
    check isAssigned("sni", "sinxa")  # `Example 4.35`
    # `Example 4.35` pe `CLL 4.6`
    #   .i zo sniju'o
    #   .i le nu fendi cu se sruma
    check isAssigned("ju'o", "djuno")  # `Example 4.35`
    # `Example 4.36` pe `CLL 4.6`
    #   .i zo mampa'u
    #   .i `CLL 4.6` cu skicu `mam` fo zoi gy. is assigned to it .gy.
    check isAssigned("mam", "mamta")  # `Example 4.36`
    # `Example 4.36` pe `CLL 4.6`
    #   .i zo mampa'u
    #   .i le nu fendi cu se sruma
    check isAssigned("pa'u", "patfu")  # `Example 4.36`
    # `Example 4.37` pe `CLL 4.6`
    #   .i zo lerste
    #   .i le nu fendi cu se sruma
    check isAssigned("ler", "lerfu")  # `Example 4.37`
    # `Example 4.37` pe `CLL 4.6`
    #   .i zo lerste
    #   .i le nu fendi cu se sruma
    check isAssigned("ste", "liste")  # `Example 4.37`
    check isAssigned("pat", "pante")  # zo patyta'a pe `CLL 4.6` to le nu fendi cu se sruma toi
    check isAssigned("mud", "mudri")  # zo mudysiclu pe `CLL 4.6` to le nu fendi cu se sruma toi
    # zo zuljma pe `CLL 4.6`
    #   .i le nu fendi cu se sruma
    check isAssigned("zul", "zunle") and isAssigned("jma", "jamfu")  # `CLL 4.6`
    check isAssigned("ro'i", "rokci")  # zo ro'inre'o pe `CLL 4.6` to le nu fendi cu se sruma toi
    check isAssigned("re'o", "renro")  # zo ro'inre'o pe `CLL 4.6` to le nu fendi cu se sruma toi
    check isAssigned("rok", "rokci")  # zo rokre'o pe `CLL 4.6` to le nu fendi cu se sruma toi
    for text in DIGITS:  # ro le pano namcu poi `CLL 18.2` cu cusku ke'a
      let found = word(text)
      # ja'i `CLL 4.6` ro le namcu cu ponse lo rafsi poi se tarmi `CVC`
      #   .i se ki'u bo le gismu liste cu vasru le namcu
      check found.isSome  # `CLL 4.6`
      if found.isNone: continue
      let w = found.get
      # `CLL 4.6` cu skicu le namcu fo zoi gy. are all CV form cmavo .gy.
      check w.kind == Kind.Cmavo and text.len == 2  # `CLL 4.6`
      # `CLL 4.6` cu cusku zoi gy. CV form cmavo .gy.
      check text[0] in ORDER_CONSONANTS and text[1] in ORDER_VOWELS  # `CLL 4.6`
      let rafsi_added = w.entry.rafsi.filterIt(it.form == some(Form.Cvc) and it.startsWith(text))
      # ja'i `CLL 4.6` lo rafsi poi se tarmi `CVC` cu gunma le cmavo jo'u pa zunsna
      check rafsi_added.len == 1  # `CLL 4.6`
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
    # `CLL 4.6` cu skicu lo rafsi be lo cmavo fo zoi gy. usually CVC-form .gy.
    check 2 * count_cmavo_cvc > count_cmavo  # `CLL 4.6`
    # `CLL 4.6` cu cusku zoi gy. still fewer have all three forms .gy.
    check count_three < count_ccv_cvv  # `CLL 4.6`
    # `CLL 4.6` cu skicu `CVC` .e lo drata cmalu rafsi fo zoi gy. fairly common .gy.
    check count_ccv_cvv < count_cvc_other  # `CLL 4.6`


  test "Section 4.13":
    # ja'i `CLL 4.13` ro rafsi be zo gerku cu se liste
    check rafsiSorted("gerku") == sorted(@["ger", "ge'u"])  # `CLL 4.13`
    # lu gerku zdani li'u pe `CLL 4.13`
    check isAssigned("ger", "gerku") and isAssigned("ge'u", "gerku")  # `CLL 4.13`
    check rafsiSorted("zdani") == @["zda"]  # ja'i `CLL 4.13` ro rafsi be zo zdani cu se liste
    check isAssigned("zda", "zdani")  # lu gerku zdani li'u pe `CLL 4.13`
    # ja'i `CLL 4.13` lo cmalu rafsi be zo bloti
    check rafsiSorted("bloti") == sorted(@["lot", "blo", "lo'i"])  # `CLL 4.13`
    # lu bloti klesi li'u pe `CLL 4.13`
    check isAssigned("lot", "bloti") and isAssigned("blo", "bloti")  # `CLL 4.13`
    check isAssigned("lo'i", "bloti")  # lu bloti klesi li'u pe `CLL 4.13`
    # ja'i `CLL 4.13` lo cmalu rafsi be zo klesi
    check rafsiSorted("klesi") == sorted(@["kle", "lei"])  # `CLL 4.13`
    # lu bloti klesi li'u pe `CLL 4.13`
    check isAssigned("kle", "klesi") and isAssigned("lei", "klesi")  # `CLL 4.13`
    # `CLL 4.13` cu skicu lo rafsi be zo logji fo zoi gy. available rafsi .gy.
    check rafsiSorted("logji") == @["loj"]  # `CLL 4.13`
    check isAssigned("loj", "logji")  # lu logji bangu girzu li'u pe `CLL 4.13`
    # `CLL 4.13` cu skicu lo rafsi be zo bangu fo zoi gy. available rafsi .gy.
    check rafsiSorted("bangu") == sorted(@["ban", "bau"])  # `CLL 4.13`
    # lu logji bangu girzu li'u pe `CLL 4.13`
    check isAssigned("ban", "bangu") and isAssigned("bau", "bangu")  # `CLL 4.13`
    # `CLL 4.13` cu skicu lo rafsi be zo girzu fo zoi gy. available rafsi .gy.
    check rafsiSorted("girzu") == sorted(@["gri", "gir"])  # `CLL 4.13`
    check isAssigned("gri", "girzu")  # lu logji bangu girzu li'u pe `CLL 4.13`
    # `CLL 4.13` cu skicu `gir` fo zoi gy. for name purposes only .gy.
    check isAssigned("gir", "girzu")  # `CLL 4.13`
    check isAssigned("nak", "nakni") and isAssigned("kem", "ke")  # `nak-kem-cin-ctu` pe `CLL 4.13`
    # `nak-kem-cin-ctu` pe `CLL 4.13`
    check isAssigned("cin", "cinse") and isAssigned("ctu", "ctuca")  # `CLL 4.13`
    for (stem, gismu) in STEMS_4_13:
      # ja'i `CLL 4.13` lo rafsi poi vasru vo lerfu zi'e pe le mupli
      check wordsStem(stem).mapIt($it) == @[gismu]  # `CLL 4.13`


  test "Section 4.14":
    for text in ["bradi", "bredi", "bridi", "brodi"]:
      check word(text).isSome  # `CLL 4.14` cu skicu le valsi fo zoi gy. are all existing gismu .gy.
    check word("brudi").isNone  # `CLL 4.14` cu cusku zoi gy. but fortunately not brudi .gy.


  test "Section 4.15":
    let groups = [
      @GISMU_ASSIGNABLE, @GISMU_COINED, @GISMU_METRIC_SMALL, @GISMU_METRIC_LARGE,
      @GISMU_SCIENTIFIC, @GISMU_CULTURAL,
    ]
    # le cipra cu bandu le fukpi be le liste pe `CLL 4.15` be'o noi zvati le cipra po'o
    check concat(groups).len == COUNT_LISTED_4_15  # `CLL 4.15`
    check concat(groups).deduplicate.len == COUNT_LISTED_4_15  # le fukpi cu cusku ro gismu pa roi
    for group in groups:
      for text in group:
        let found = word(text)
        # ja'i `CLL 4.15` le valsi cu mulno gismu
        check found.isSome and found.get.kind == Kind.Gismu  # `CLL 4.15`
        if group != @GISMU_METRIC_SMALL and group != @GISMU_ASSIGNABLE:
          # ja'i `CLL 4.15` ro le gismu poi na cmalu ke merli gismu gi'e na du `brod-` cu se fanmo
          #   `o`
          check text[^1] == 'o'  # `CLL 4.15`



suite "Internal: Dictionary":
  test "Kind follows shape of gismu":
    var count_gismu, count_cmavo = 0
    for w in words():
      let is_gismu = w.kind == Kind.Gismu
      # le liste cu vasru no lujvo
      check is_gismu == ($w).isBrivla  # le klesi cu tugni `isBrivla`
      check is_gismu == (($w).len == 5)  # le klesi cu fendi le liste ja'i lo ni clani
      if is_gismu: inc count_gismu else: inc count_cmavo
    check count_gismu == 1342  # lo nu lo te kancu cu stali to le liste cu vasru pacivore gismu toi
    # lo nu lo te kancu cu stali
    #   .i le liste cu vasru sovo cmavo poi ponse lo rafsi
    check count_cmavo == 94  # lo nu lo te kancu cu stali


  test "Word order follows list order":
    for w in words():
      check Word(w.index) == w  # lo valsi poi se zbasu fi lo namcu pe le valsi cu du le valsi
    for i in 1..<LIST_GISMU.len:
      # lo porsi pe le liste cu du lo porsi be fi lo stuzi
      #   .i lo nu sisku cu nitcu di'u
      check $Word(i - 1) < $Word(i)  # lo porsi pe le liste cu du lo porsi be fi lo stuzi
    randomize(0)
    let pool = drawPairs()
    for (a, b) in pool.samples:  # `SAMPLES_PAIRS` cu te kancu le remei poi lo tsiju cu jdice ke'a
      check (a < b) == ($a < $b)  # lo porsi be lo valsi cu du lo porsi be lo se ciska


  test "Rendering round trips":
    for w in words():
      check word($w) == some(w)  # lo nu ciska gi'e ba bo sisku cu dunda le valsi
    for entry in LIST_GISMU:
      # lo nu sisku gi'e ba bo ciska cu dunda le valsi
      check word(entry.word).map(`$`) == some(entry.word)  # lo jalge cu du le valsi


  test "Entry fields":
    for w in words():
      let entry = w.entry
      # lo cmavo cu vasru su'o re lerfu gi'e vasru su'e vo lerfu
      #   .i lo gismu cu vasru mu lerfu
      check entry.word.len in 2..5  # lo cmavo cu vasru su'o re lerfu gi'e vasru su'e vo lerfu
      check entry.rafsi.len <= 3  # pa stuzi be lo rafsi cu ckini ro tarmi be lo cmalu rafsi
      check entry.rafsi.allIt(it.form.get in FORMS_SHORT)  # ro stuzi cu vasru lo cmalu rafsi
      # lo cmavo cu se liste mu'i lo rafsi pe vo'a
      if w.kind == Kind.Cmavo: check entry.rafsi.len >= 1
      check entry.word.strip == entry.word  # no kunti stuzi cu krasi ja fanmo le valsi


  test "Lookups agree with linear scan":
    check word("").isNone  # lo nu sisku lo kunti lerpoi cu facki no da
    # lo nu sisku le lerpoi cu facki no da ki'u lo nu ciska
    #   .i le lerpoi cu se zbasu
    check word("Gismu").isNone and word("gismu ").isNone  # facki no da to se zbasu toi
    # ja'i lo krasi pagbu .e lo nu jmina lo lerfu kei lo nu sisku cu facki no da
    #   .i le lerpoi cu se zbasu
    check word("gism").isNone and word("gismuu").isNone  # facki no da to se zbasu toi
    # lo se sisku cu bilga lo ka vasru vo lerfu
    check wordsStem("").len == 0 and wordsStem("gismu").len == 0  # le jicmu cu vasru vo lerfu
    randomize(0)
    let pool = drawMutated()
    var count_unlisted, count_listed = 0
    # `SAMPLES_MUTATION` cu te kancu le lerpoi poi lo tsiju cu jdice ke'a
    for (source, text) in pool.samples:
      let found = word(text)
      # lo nu sisku ta'i lo nu rapli fendi fi re pagbu cu mintu lo nu tcidu ro liste cmima ta'i lo
      #   porsi
      check found == wordScanned(text)  # lo re nu sisku cu mintu
      if found.isNone: inc count_unlisted
      elif text != source: inc count_listed
    # le se cipra cu ralte lo nu sisku poi facki no da to `Article IX.3` toi
    check count_unlisted >= FLOOR_UNLISTED  # `Article IX.3`
    # le se cipra cu ralte lo nu sisku poi facki lo drata liste cmima to `Article IX.3` toi
    check count_listed >= FLOOR_LISTED  # `Article IX.3`
    var count_stemmed = 0
    for notation in ["CVCC", "CCVC"]:
      for text in texts(positionsNotation(notation)):  # ro le vosopacino lerpoi
        let found = wordsStem(text)
        # lo nu sisku ta'i lo nu rapli fendi fi re pagbu cu mintu lo nu tcidu ro liste cmima ta'i lo
        #   porsi
        check found == wordsStemScanned(text)  # lo re nu sisku cu mintu
        count_stemmed += found.len
    # lo nu lo te kancu cu stali
    #   .i ro gismu cu se facki pa roi ta'i lo rafsi poi vasru vo lerfu
    check count_stemmed == 1342  # lo nu lo te kancu cu stali
