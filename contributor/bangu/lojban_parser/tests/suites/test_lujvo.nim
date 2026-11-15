## rapli zbasu lo lujvo pe `CLL 3` .e `CLL 4` .e `CLL 7` sepi'o `lujvo.nim` gi'e cipra lo nu jmina
##   .e lo nu fendi .e lo nu dunda lo namcu
##   .i ro lujvo poi `CLL` cu ciska ke'a cu ve jmina lo rafsi pe vo'a gi'e se fendi fi le rafsi po'o
##   .i se ki'u bo pa mupli cu cipra fi lo nu jmina .e lo nu fendi
##   .i va'o lo nu `CLL` cu dunda lo valsi gi'e na dunda lo rafsi pe le valsi kei le cipra cu sruma
##     le te fendi
##   .i lo pinka cu cusku di'u
##   .i `CLL` cu dunda no mupli be lo cipra pe `tosmabru` to `step 5` pe `CLL 4.11` toi
##   .i se ki'u bo lo valsi pe `lujvo.txt` zi'e poi nitcu le cipra cu basti le mupli
##   .i lo valsi poi le cipra cu zbasu ke'a cu kansa le valsi gi'e se tcita lo pinka poi cusku di'u
##   .i pa cipra cu cipra lo du'u `lujvo.txt` cu ciska ro le valsi pe `lujvo.txt`
##   .i ja'i lo javni pe `lujvo.nim` zi'e noi `CLL 4.11` na cusku ke'a ku'o lo te jorne poi zbasu lo
##     zunsna cimei poi se to'e curmi cu cpacu `y`
##   .i lo cipra po'u `Internal: Convention` cu cusku lo mupli poi le javni cu galfi ke'a
##   .i va'o lo nu lo lerfu jorne poi se nitcu gi'e se lidne lo cmalu rafsi cu se vimcu kei no lujvo
##     cu stali
##   .i le cipra cu cipra di'u
##   .i ku'i no simsa javni cu drani va'o lo nu le lerfu jorne cu se lidne lo rafsi poi vasru vo
##     lerfu
##   .i lo nu vimcu `y` cu ka'e rinka lo nu lo drata rafsi cu stali gi'e se jmina ja'i `CLL 4.11`
##     sepi'o no lerfu jorne
##   .i mupli fa lo nu zo kramliste cu se fendi fi `kra` jo'u `mli` jo'u `ste`
##   .i papabi lo sososoxa te jorne poi simsa ku'o pe le girzu cu rapli se fendi
##   .i le namcu cu se merli
##   .i se ki'u bo le cipra cu xusra no da fi le rafsi poi vasru vo lerfu
##   .i lo javni cipra pe `lujvo.txt` cu tcidu `lujvo.txt` ta'i lo drata se ciska to
##     `texts_outside.nim` toi gi'e na zukte va'o lo nu `lujvo.txt` cu na zvati gi'a cenba to
##     `Article IX.9` toi
##   .i le javni cipra cu sitna fi ro linji poi na mapti ke'a gi'e cusku lo krinu
##   .i se ki'u bo va'o lo nu le liste .a le genturfa'i cu cenba kei le cipra cu fliba gi'e cusku le
##     valsi poi frica
##   .i va'o lo nu le liste cu na tugni `CLL` kei le krinu cu cusku le se sarji be `CLL`
##   .i lo cunso javni cipra cu tcidu pa girzu be lo porsi be lo rafsi
##   .i le girzu cu se zbasu pa roi sepi'o lo tsiju po'u `0`
##   .i se ki'u bo ro javni cipra cu tcidu le mintu mupli
##   .i no javni cipra cu rapli zbasu lo mupli
##   .i lo remoi girzu cu zbasu ro rafsi fi lo lerfu poi mapti lo tarmi be le rafsi to
##     `rafsi_random.nim` toi
##   .i se ki'u bo le cipra cu cipra lo nu fendi ji'a ne'i lo rafsi poi no liste cu dunda ke'a to
##     `Article IX.4` toi
##   .i ro porsi pe lo cimoi girzu cu se krasi lo porsi be lo rafsi poi se tarmi `CVC`
##   .i se ki'u bo ne'i ji'i pa fi'u ci le porsi `step 5` pe `CLL 4.11` cu punji `y` lo pamoi te
##     jorne
##   .i ne'i le girzu le cipra cu cipra fi lo namcu pe ro te jorne ta'i lo nu sepli

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, unittest]

import ../../src/lojban_parser/[clusters, dictionary, forms, lujvo {.all.}, tanru]
import ../../src/lojban_parser/lists/gismu
import ./[rafsi_random, texts_outside]


func constructRafsiByForm(): array[Form, seq[string]] {.compileTime.} =
  ## zbasu ro rafsi pe le gismu liste ta'i lo liste pe ro tarmi
  ##   .i le liste cu vasru lo cmalu rafsi pe ro cmima be le gismu liste
  ##   .i ba bo le liste cu vasru lo rafsi poi vasru vo lerfu .e lo rafsi poi vasru mu lerfu vu'o pe
  ##     ro gismu
  ##   .i lo jicmu po'u `brod` noi mu gismu cu ponse ke'a cu se jmina fi le liste pa roi
  for entry in LIST_GISMU:
    for one in entry.rafsi: result[one.form.get].add one
    if not entry.word.isGismu: continue
    let
      stem = entry.word[0 .. 3]
      # la'o gy. VM .gy. pe le se stodi fanva po'u la'o gy. Nim 2.4.0 .gy. cu rinka lo nu `stem` cu
      #   muvdu `add` kei pu lo nu kanji lo stuzi
      #   .i lo nu fanva le cmalu samtci cu fliba va'o lo nu le se ciska cu claxu `form`
      form = stem.form.get
    if result[form].len == 0 or result[form][^1] != stem:
      result[form].add stem
    result[entry.word.form.get].add entry.word


const
  SAMPLES = 10000
    ## lo te kancu be lo cunso porsi be lo rafsi be'o pe le girzu
    ##   .i ro cunso javni cipra cu tcidu ro le porsi to `Article IX.4` toi
  SAMPLES_FLOOR_ADDED = SAMPLES div 2
    ## lo mupli poi bilga lo nu vasru lo te jorne poi ponse no lerfu jorne kei ca lo nu lo javni
    ##   cipra pe lo nu jmina lo lerfu jorne cu gunka
    ##   .i zepanono mupli cu se tcidu
  SAMPLES_FLOOR_REMOVED = SAMPLES div 4
    ## lo mupli poi bilga lo nu vasru lo lerfu jorne poi se lidne lo cmalu rafsi kei ca lo nu lo
    ##   javni cipra pe lo nu vimcu cu gunka
    ##   .i cicipaci mupli cu se tcidu
  JUNCTIONS_FLOOR_IMPERMISSIBLE = 5000
    ## lo rafsi poi se tarmi `CVC` gi'e lidne lo gismu zi'e poi `step 4b` pe `CLL 4.11` cu bilga lo
    ##   nu jdice lo du'u lo zunsna remei pe ke'a cu na se curmi
    ##   .i mucirexa le rafsi cu se tcidu
  LENGTH_MIN = 2
    ## lo mleca traji te kancu be lo rafsi pe pa cunso porsi
    ##   .i ro lujvo cu vasru su'o re rafsi to `CLL 4.6` toi
  LENGTH_MAX = 5  ## lo zmadu traji te kancu be lo rafsi pe pa cunso porsi
  ENTRIES_FLOOR_LOJBAN = 3000
    ## lo cmima be le lujvo liste be'o poi se ciska ta'i lo lojbo sinxa zi'e poi ro pagbu be ke'a cu
    ##   bilga lo nu se liste
  ENTRIES_FLOOR_ENGLISH = 600
    ## lo linji poi se ciska ta'i lo glico sinxa gi'e vasru su'o re ckiku valsi zi'e poi le javni
    ##   cipra cu tcidu ke'a
    ##   .i zexaze linji cu se tcidu
  FORMS_MEDIAL = [Form.Cvc, Form.Ccv, Form.Cvv, Form.Cvcc, Form.Ccvc]
    ## lo tarmi poi `step 1` pe `CLL 4.11` cu curmi ke'a bu'u lo stuzi poi lidne lo romoi rafsi
    ##   .i lo rafsi poi se tarmi le tarmi cu vasru ci lerfu gi'a vasru vo lerfu
  FORMS_LAST = [Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv]
    ## lo tarmi poi `step 2` pe `CLL 4.11` cu curmi ke'a bu'u lo romoi stuzi
    ##   .i le tarmi cu du `CVV` .a `CCV` .a lo tarmi poi vasru mu lerfu
  SAMPLES_RUN = 4000
    ## lo cunso porsi be lo rafsi be'o noi lo tsiju cu jdice ke'a
    ##   .i ro le porsi cu se krasi lo porsi poi `step 5` pe `CLL 4.11` cu tcidu ke'a
  SAMPLES_FLOOR_BROKEN = 1100
    ## lo mleca traji te kancu be lo porsi pe `SAMPLES_RUN` zi'e poi `step 5` cu punji `y` lo pamoi
    ##   te jorne pe ke'a
    ##   .i parereze porsi cu se tcidu va'o lo nu lo tsiju cu du `0`
  TRIPLES_NAMED = ["ndj", "ndz", "ntc", "nts"]
    ## lo zunsna cimei poi `CLL 3.7` cu to'e curmi ke'a ta'i lo nu cusku ke'a
  LUT_RAFSI_BY_FORM = constructRafsiByForm()
    ## ro rafsi pe le gismu liste ta'i lo liste pe ro tarmi
  EXCEPTIONS_SPLIT = [
    # lo rafsi poi se tarmi `CVV` gi'e krasi lo lujvo poi vasru ci rafsi cu claxu `r` pe
    #   `CLL 4.11 step 4a`
    "maicpukai",  # `CLL 4.11 step 4a`
    "natmyrgu'e",  # no te fendi cu cumki to `r` noi se lidne `natmy` cu mapti no rafsi toi
  ]
    ## lo cmima be le lujvo liste be'o poi se ciska ta'i lo lojbo sinxa .a lo glico sinxa gi'e na se
    ##   fendi pa roi po'o
    ##   .i lo krinu cu kansa ro cmima
  EXCEPTIONS_LOJBAN = [
    # ne'i le liste zo dzena cu lidne zo fetsi
    #   .i ku'i ne'i le valsi `fe'i` cu lidne lo rafsi be zo dzena
    "kamfe'idzeseltru",  # ne'i le liste zo dzena cu lidne zo fetsi
    # ne'i le liste zo dzena cu lidne zo nakni
    #   .i ku'i ne'i le valsi `nak` cu lidne lo rafsi be zo dzena
    "kamnakydzeseltru",  # ne'i le liste zo dzena cu lidne zo nakni
    "mumcte",  # `mum` cu rafsi zo mu to le liste cu ciska zo re toi
    "mumdei",  # `mum` cu rafsi zo mu to le liste cu ciska zo re toi
    "mumdo'i",  # `mum` cu rafsi zo mu to le liste cu ciska zo re toi
    "mumvanbi",  # `mum` cu rafsi zo mu to le liste cu ciska zo re toi
    "narmitsi'u",  # `nar` cu rafsi zo na to le liste cu ciska zo na'e noi `nal` cu rafsi ke'a toi
    "narselfendi",  # `nar` cu rafsi zo na to le liste cu ciska zo na'e noi `nal` cu rafsi ke'a toi
    "nildicka'ukezyjdika",  # le valsi cu vasru `kez` pe zo kei to le liste cu na ciska zo kei toi
    "xavdei",  # `xav` cu rafsi zo xa to le liste cu ciska zo re toi
    "xavdo'i",  # `xav` cu rafsi zo xa to le liste cu ciska zo re toi
    "xavycte",  # `xav` cu rafsi zo xa to le liste cu ciska zo re toi
    "xavyvanbi",  # `xav` cu rafsi zo xa to le liste cu ciska zo re toi
  ]
    ## lo cmima be le lujvo liste be'o poi se ciska ta'i lo lojbo sinxa zi'e poi lo rafsi pe ke'a cu
    ##   na sinxa lo pagbu poi le liste cu ciska ke'a ku'o ta'i lo porsi
    ##   .i lo krinu cu kansa ro cmima
  EXCEPTIONS_ENGLISH = [
    # lo rafsi poi se tarmi `CVV` gi'e krasi lo lujvo poi vasru ci rafsi cu claxu `r` pe
    #   `CLL 4.11 step 4a`
    "maicpukai",  # `CLL 4.11 step 4a`
    # lo lerfu po'u `r` noi se lidne `natmy` cu mapti no rafsi
    #   .i ku'i zo natmygu'e cu ka'e se tcidu
    "natmyrgu'e",  # lo lerfu po'u `r` noi se lidne `natmy` cu mapti no rafsi
    "tolmipygau",  # le valsi cu vasru `tol` pe zo to'e to le liste cu na ciska le cmavo toi
    # le liste cu ciska `2nd-place-of` noi sinxa lo cmavo be zoi gy. SE .gy. to `CLL 9.4` toi
    #   .i le valsi cu vasru no rafsi be le cmavo
    "vikmau",  # `CLL 9.4`
  ]
    ## lo linji poi se ciska ta'i lo glico sinxa
    ##   .i lo te kancu be lo pagbu poi le tcidu cu tcidu fi le linji cu frica lo te kancu be lo
    ##     ckiku valsi pe le linji
    ##   .i lo krinu cu kansa ro le linji
  WORDS_CITED = [
    "cakyrespa", "cibylajyterkruca", "detyselylacri", "digyligykamju", "pucyteryrunta",
    "xasymabru", "kanydzu", "penydjuxa'a",
  ]
    ## lo valsi poi le cipra cu sitna `lujvo.txt` ke'a ta'i lo nu se ciska
    ##   .i le valsi cu mupli `step 5` pe `CLL 4.11` .e lo zunsna cimei poi se to'e curmi


func rafsiSplit(word: string): seq[seq[string]] =
  ## tcidu lo rafsi pe ro te fendi poi `splitLujvo` cu facki ke'a ne'i `word`
  for pieces in word.splitLujvo: result.add pieces.mapIt(it.rafsi)


func isRoundTrip(rafsi: openArray[string], word: string): bool =
  ## jdice lo du'u xu kau `rafsi` cu se jmina fo `word` kei .e lo du'u xu kau `word` cu se fendi fi
  ##   `rafsi` po'o
  joinRafsi(rafsi) == word and rafsiSplit(word) == @[@rafsi]


func spell(pieces: openArray[Piece], at = -1, letter = ""): string =
  ## ciska `pieces` .e lo lerfu jorne pe ro pagbu
  ##   .i `letter` cu basti lo lerfu jorne poi se lidne lo pagbu poi zvati lo stuzi po'u `at`
  for i, piece in pieces:
    result.add piece.rafsi
    result.add(if i == at: letter else: LUT_LETTER_BY_HYPHEN[piece.hyphen])


func value(rafsi: string): int =
  ## kanji lo namcu poi `step 4` pe `CLL 4.12` cu dunda ke'a `rafsi` ku'o fi lo namcu pe `rafsi`
  ##   po'o ge'u .e lo mekso pe `CLL 4.12`
  let
    piece = Piece(rafsi: rafsi, form: rafsi.form.get)
    weighed = 1000 * rafsi.len - 500 * rafsi.count('\'') - rafsi.countIt(it in "aeiou")
  (weighed - score([piece])) div 10


func isStanding(piece: Piece, listed: Word): bool =
  ## jdice lo du'u xu kau `piece` cu sinxa `listed`
  ##   .i lo cmalu rafsi cu sinxa ja'i le liste be lo rafsi
  ##   .i lo rafsi poi vasru vo lerfu cu sinxa lo gismu poi le rafsi cu jicmu ke'a
  ##   .i lo rafsi poi vasru mu lerfu cu sinxa vo'a to `CLL 4.6` toi
  case piece.form
  of Form.Cvc, Form.Ccv, Form.Cvv: piece.rafsi.wordRafsi == some(listed)
  of Form.Cvcc, Form.Ccvc: listed in piece.rafsi.wordsStem
  of Form.Cvccv, Form.Ccvcv: piece.rafsi.word == some(listed)


proc drawRafsi(): seq[seq[string]] =
  ## cuxna lo porsi be lo rafsi be'o poi mapti lo stuzi poi `step 1` .e `step 2` vu'o pe `CLL 4.11`
  ##   cu curmi ke'a
  ##   .i `SAMPLES` cu te kancu le porsi
  ##   .i lo tsiju cu jdice le porsi pa roi
  ##   .i pamoi fa lo nu cuxna lo tarmi ta'i lo nu ro tarmi cu dunli fi lo ka ce'u lakne se cuxna
  ##   .i remoi fa lo nu cuxna lo rafsi poi se tarmi le tarmi
  ##   .i se ki'u bo lo nu cuxna lo rirci tarmi mu'u `CCVC` .e `CV'V` cu dunli lo nu cuxna `CVC` lo
  ##     ka ce'u lakne
  randomize(0)
  result = newSeq[seq[string]](SAMPLES)
  for sample in result.mitems:
    let length = rand(LENGTH_MIN .. LENGTH_MAX)
    sample = newSeqOfCap[string](length)
    for i in 0 ..< length:
      let chosen = (if i == length - 1: FORMS_LAST.sample else: FORMS_MEDIAL.sample)
      sample.add LUT_RAFSI_BY_FORM[chosen].sample


let SEQUENCES_RAFSI = drawRafsi()
  ## lo cunso porsi be lo rafsi be'o poi ro cunso javni cipra cu tcidu ke'a
  ##   .i le porsi cu se cuxna pa roi


iterator rafsiRandom(): lent seq[string] =
  ## dunda ro cunso porsi be lo rafsi be'o pe le girzu
  ##   .i no fukpi cu se zbasu
  for i in 0 ..< SEQUENCES_RAFSI.len: yield SEQUENCES_RAFSI[i]


let SEQUENCES_LETTERS = drawSequencesLetters(SAMPLES, LENGTH_MIN .. LENGTH_MAX, seed = 0)
  ## lo cunso porsi be lo rafsi be'o noi se cuxna pa roi
  ##   .i ro rafsi cu se zbasu fi lo lerfu poi mapti lo tarmi be le rafsi
  ##   .iju lo liste cu dunda le rafsi


iterator rafsiLetters(): lent seq[string] =
  ## dunda ro porsi be lo rafsi be'o poi se zbasu fi lo lerfu
  ##   .i no fukpi cu se zbasu
  for i in 0 ..< SEQUENCES_LETTERS.len: yield SEQUENCES_LETTERS[i]


func isOpeningInitial(first: char): bool =
  ## jdice lo du'u xu kau lo zunsna po'u `first` cu krasi su'o zunsna remei poi ka'e krasi lo valsi
  ##   to `CLL 3.7` toi
  ##   .i `l` .e `n` .e `r` cu krasi no le zunsna remei
  for c in 'a'..'z':
    if c.isConsonant and isPairInitial(first, c): return true
  false


proc drawSequencesRun(): seq[seq[string]] =
  ## cuxna lo porsi be lo rafsi be'o poi se zbasu fi lo lerfu gi'e se krasi lo porsi poi `step 5` pe
  ##   `CLL 4.11` cu tcidu ke'a
  ##   .i `SAMPLES_RUN` cu te kancu le porsi
  ##   .i lo tsiju cu jdice le porsi
  ##   .i le krasi porsi cu se gunma lo rafsi poi se tarmi `CVC`
  ##   .i lo te kancu be le rafsi cu du li pa bi'o li vo
  ##   .i ro te jorne ne'i le krasi porsi zo'u bapli lo nu le te jorne cu zbasu lo zunsna remei poi
  ##     ka'e krasi lo valsi kei ne'i pa fi'u re lo nu cuxna
  ##   .i la'e di'u fasnu va'o lo nu su'o zunsna remei poi ka'e krasi lo valsi cu se krasi lo zunsna
  ##     poi lidne le te jorne
  ##   .i se ki'u bo ro nu cuxna cu se fanmo
  ##   .i ne'i pa fi'u re lo nu cuxna le romoi rafsi cu se tarmi `CVCCV` gi'e vasru lo zunsna remei
  ##     poi ka'e krasi lo valsi gi'e jorne le krasi porsi sepi'o lo zunsna remei poi ka'e krasi lo
  ##     valsi ku'o va'o lo nu su'o le simsa zunsna remei cu cumki
  ##   .i va'o lo drata le romoi rafsi cu se tarmi lo tarmi poi `step 2` cu curmi ke'a
  randomize(0)
  result = newSeqOfCap[seq[string]](SAMPLES_RUN)
  for _ in 1..SAMPLES_RUN:
    var rafsi: seq[string]
    for i in 0..<rand(1..4):
      let is_forced = i > 0 and rand(1) == 0 and rafsi[^1][^1].isOpeningInitial
      var one = drawRafsiLetters(Form.Cvc)
      while is_forced and not isPairInitial(rafsi[^1][^1], one[0]):
        one = drawRafsiLetters(Form.Cvc)
      rafsi.add one
    var last = drawRafsiLetters(FORMS_LAST.sample)
    if rand(1) == 0:
      let is_joined = rafsi[^1][^1].isOpeningInitial
      last = drawRafsiLetters(Form.Cvccv)
      while not isPairInitial(last[2], last[3]) or
          (is_joined and not isPairInitial(rafsi[^1][^1], last[0])):
        last = drawRafsiLetters(Form.Cvccv)
    rafsi.add last
    result.add rafsi


let SEQUENCES_RUN = drawSequencesRun()
  ## lo cunso porsi poi se krasi lo porsi be lo rafsi poi se tarmi `CVC`
  ##   .i le porsi cu se cuxna pa roi


iterator rafsiRun(): lent seq[string] =
  ## dunda ro porsi be lo rafsi be'o poi se krasi lo porsi be lo rafsi poi se tarmi `CVC`
  ##   .i no fukpi cu se zbasu
  for i in 0..<SEQUENCES_RUN.len: yield SEQUENCES_RUN[i]


func scoreJunctions(rafsi: openArray[string]): int =
  ## dunda lo namcu `rafsi` ta'i lo nu tcidu ro te jorne ta'i lo nu sepli
  ##   .i lo nu ciska lo tanru ta'i lo lujvo cu sisku ta'i le simsa
  ##   .i le namcu cu sumji lo namcu pe ro rafsi lo namcu pe ro te jorne
  ##   .i lo namcu pe ro te jorne cu se kancu sepi'o lo lanci pe le krasi porsi
  ##   .i `step 5` pe `CLL 4.11` cu tcidu le lanci
  var is_open = rafsi[0].isRunOpen
  result = scoreRafsi(rafsi[0], rafsi[0].form.get)
  for at in 0 ..< rafsi.len - 1:
    let junction = scoreJunction(is_open, rafsi[at], rafsi[at+1], at, rafsi.len)
    result += junction.score + scoreRafsi(rafsi[at+1], rafsi[at+1].form.get)
    is_open = junction.is_open


func isBrokenFirst(rafsi: openArray[string]): bool =
  ## jdice lo du'u xu kau `step 5` pe `CLL 4.11` cu punji `y` lo pamoi te jorne
  ##   .i lo pamoi rafsi cu se tarmi `CVC` gi'e lidne `y`
  ##   .i `step 4b` cu punji no lerfu jorne vi ki'u lo nu le zunsna remei cu se curmi gi'e zbasu no
  ##     zunsna cimei poi se to'e curmi
  let (a, b) = (rafsi[0][^1], rafsi[1][0])
  rafsi[0].form.get == Form.Cvc and hyphensRafsi(rafsi)[0] == Hyphen.Y and
      isPairPermissible(a, b) and
      (not rafsi[1][1].isConsonant or isTriplePermissible(a, b, rafsi[1][1]))



suite "Chapter 3":
  test "Section 3.8":
    check isRoundTrip(["xap", "cke"], "xapcke")  # `CLL 3.8, Example 3.12` to sruma le te fendi toi
    # sruma le te fendi
    check isRoundTrip(["pon", "ni'u"], "ponyni'u")  # `CLL 3.8, Example 3.13`
    # `CLL 3.8, Example 3.14`
    #   .i sruma le te fendi
    check isRoundTrip(["bong", "nanba"], "bongynanba")  # `CLL 3.8, Example 3.14`
    # `CLL 3.8, Example 3.15` zoi gy. possible borrowing .gy.
    check rafsiSplit("bongnanba").len == 0  # `CLL 3.8, Example 3.15`


  test "Section 3.9":
    check isRoundTrip(["fit", "pri"], "fitpri")  # `CLL 3.9, Example 3.20` to sruma le te fendi toi
    check isRoundTrip(["sai", "goi"], "sairgoi")  # `CLL 3.9, Example 3.21` to sruma le te fendi toi
    # `CLL 3.9, Example 3.21` lo zunsna remei po'u `rg`
    #   .i sruma le te fendi
    check toPieces(["sai", "goi"])[0].hyphen == Hyphen.R  # `CLL 3.9, Example 3.21`
    check isRoundTrip(["dik", "jvo"], "dikyjvo")  # `CLL 3.9, Example 3.23` to sruma le te fendi toi
    # `CLL 3.9, Example 3.28`
    #   .i `bis` .e `dja` cu rafsi
    check isRoundTrip(["bis", "dja"], "bisydja")  # `CLL 3.9, Example 3.28`
    # `CLL 3.9, Example 3.28` zoi gy. impermissible consonant pair .gy.
    check not isPairPermissible('s', 'd')  # `CLL 3.9, Example 3.28`
    check toPieces(["bis", "dja"])[0].hyphen == Hyphen.Y  # `CLL 3.9, Example 3.28` to punji `y` toi
    # sruma le te fendi
    check isRoundTrip(["da'u", "dja"], "da'udja")  # `CLL 3.9, Example 3.29`



suite "Chapter 4":
  test "Section 4.5":
    check isRoundTrip(["mam", "pa'u"], "mampa'u")  # `CLL 4.5, Example 4.25` `mam-` .e `-pa'u`
    check isRoundTrip(["soi", "sai"], "soirsai")  # `CLL 4.5, Example 4.26` to `r` cu se jmina toi
    check rafsiSplit("soisai").len == 0  # `CLL 4.5, Example 4.26` to fendi fi lo'u soi sai le'u toi
    for (rafsi, word) in [
      (@["bri", "vla"], "brivla"),
      (@["bri", "valsi"], "brivalsi"),
      (@["brid", "vla"], "bridyvla"),
      (@["brid", "valsi"], "bridyvalsi"),
    ]:
      # `CLL 4.5`
      #   .i zo brivla .e le ci drata cu me pa lujvo
      #   .i sruma le te fendi
      check isRoundTrip(rafsi, word)  # `CLL 4.5`


  test "Section 4.6":
    for (rafsi, word) in [
      (@["mamt", "patfu"], "mamtypatfu"),
      (@["lerf", "liste"], "lerfyliste"),
      (@["nanc", "prali"], "nancyprali"),
      (@["prun", "plipe"], "prunyplipe"),
      (@["vanc", "sanmi"], "vancysanmi"),
    ]:
      # `CLL 4.6, Examples 4.27-31`
      #   .i lo lujvo poi na se jdika
      #   .i sruma le te fendi
      check isRoundTrip(rafsi, word)  # `CLL 4.6, Examples 4.27-31`
    for (rafsi, word) in [
      (@["cum", "fri"], "cumfri"),
      (@["kle", "zba"], "klezba"),
      (@["kix", "ta'a"], "kixta'a"),
      (@["sni", "ju'o"], "sniju'o"),
      (@["mam", "pa'u"], "mampa'u"),
      (@["ler", "ste"], "lerste"),
    ]:
      # `CLL 4.6, Examples 4.32-37`
      #   .i lo lujvo poi mulno se jdika
      #   .i sruma le te fendi
      check isRoundTrip(rafsi, word)  # `CLL 4.6, Examples 4.32-37`
    # `CLL 4.6`
    #   .i le lujvo cu bilga lo nu du zo patyta'a
    #   .i sruma le te fendi
    check isRoundTrip(["pat", "ta'a"], "patyta'a")  # `CLL 4.6`
    # `tt` cu na du lo zunsna remei poi se curmi
    check rafsiSplit("patta'a").len == 0  # `CLL 4.6`
    # `CLL 4.6`
    #   .i lo lerfu jorne cu bilga lo nu se pilno
    #   .i sruma le te fendi
    check isRoundTrip(["mud", "siclu"], "mudysiclu")  # `CLL 4.6`
    # `CLL 4.6` lo'u mudri siclu le'u zoi gy. cannot form .gy. `mudsiclu`
    check rafsiSplit("mudsiclu").len == 0  # `CLL 4.6`
    let
      score_zuljma = score(toPieces(["zul", "jma"]))
      forms_zunle_jamfu = [
        (@["zunl", "jamfu"], "zunlyjamfu"),
        (@["zunl", "jma"], "zunlyjma"),
        (@["zul", "jamfu"], "zuljamfu"),
        (@["zul", "jma"], "zuljma"),
      ]
    for (rafsi, word) in forms_zunle_jamfu:
      # `CLL 4.6` zoi gy. all legitimate and equivalent forms .gy.
      #   .i sruma le te fendi
      check isRoundTrip(rafsi, word)  # `CLL 4.6`
      if word != "zuljma":
        # `CLL 4.6`
        #   .i zo zuljma cu se nelci
        #   .i sruma le te fendi
        check score_zuljma < score(toPieces(rafsi))  # `CLL 4.6`
    # `CLL 4.6`
    #   .i lo lerfu jorne po'u `n` cu se nitcu
    #   .i sruma le te fendi
    check isRoundTrip(["ro'i", "re'o"], "ro'inre'o")  # `CLL 4.6`
    check rafsiSplit("ro'ire'o").len == 0  # `CLL 4.6` zoi gy. breaks up into two cmavo .gy.
    check rafsiSplit("ro'irre'o").len == 0  # `CLL 4.6` zoi gy. impermissible double consonant .gy.
    # `CLL 4.6`
    #   .i no lerfu jorne cu se jmina
    #   .i sruma le te fendi
    check isRoundTrip(["rok", "re'o"], "rokre'o")  # `CLL 4.6`
    # mulno cipra
    for first in LUT_RAFSI_BY_FORM[Form.Cvv]:  # ro liste rafsi poi se tarmi `CVV`
      for second in LUT_RAFSI_BY_FORM[Form.Cvv]:
        let expected = (if second[0] == 'r': Hyphen.N else: Hyphen.R)
        # `CLL 4.6`
        #   .i `CVV-CVV` cu cpacu lo lerfu jorne ro roi
        check hyphensRafsi([first, second])[0] == expected  # `CLL 4.6`
      for last in LUT_RAFSI_BY_FORM[Form.Cvccv] & LUT_RAFSI_BY_FORM[Form.Ccvcv]:
        let expected = (if last[0] == 'r': Hyphen.N else: Hyphen.R)
        check hyphensRafsi([first, last])[0] == expected  # `CLL 4.6` `CVV-CVC/CV` .e `CVV-CCVCV`


  test "Section 4.11":
    for one in Form:  # ro rafsi pe le liste cu se tcidu ta'i lo nu sepli to mulno cipra toi
      for rafsi in LUT_RAFSI_BY_FORM[one]:
        # `CLL 4.6`
        #   .i ro lujvo cu vasru su'o re rafsi
        #   .i `CLL 4.11 steps 1-2`
        check rafsiSplit(rafsi).len == 0  # `CLL 4.6`
    for last in LUT_RAFSI_BY_FORM[Form.Cvc]:  # ro liste rafsi poi se tarmi `CVC` to mulno cipra toi
      # `CLL 4.6`
      #   .i lo rafsi poi se tarmi `CVC` cu na ka'e romoi
      check rafsiSplit("zda" & last).len == 0  # `CLL 4.6`
    for last in LUT_RAFSI_BY_FORM[Form.Cvcc] & LUT_RAFSI_BY_FORM[Form.Ccvc]:  # mulno cipra
      # `CLL 4.11 step 2`
      #   .i lo rafsi poi vasru vo lerfu cu romoi no roi
      check rafsiSplit("zda" & last).len == 0  # `CLL 4.11 step 2`
    # `CLL 4.11 step 2`
    #   .i `CLL 4.13` cu na ciska `-zdan-`
    #   .i zbasu le valsi
    check rafsiSplit("gerzdan").len == 0  # `CLL 4.11 step 2`
    for first in LUT_RAFSI_BY_FORM[Form.Cvccv] & LUT_RAFSI_BY_FORM[Form.Ccvcv]:  # mulno cipra
      # `CLL 4.11 step 1`
      #   .i lo rafsi poi vasru mu lerfu cu midju no roi
      check @[first, "zda"] notin rafsiSplit(first & "zda")  # `CLL 4.11 step 1`
    # `CLL 4.11 step 1`
    #   .i `CLL 4.13` cu na ciska `-gerku`
    #   .i zbasu le valsi
    check rafsiSplit("gerkuzdani").len == 0  # `CLL 4.11 step 1`
    # `CLL 4.11 step 4a`
    #   .i no lerfu jorne cu se jmina
    #   .i sruma le te fendi
    check isRoundTrip(["sai", "cli"], "saicli")  # `CLL 4.11 step 4a`
    # `CLL 4.11 step 4a`
    #   .i `n` cu lidne `r`
    #   .i sruma le te fendi
    check isRoundTrip(["ro'i", "re'o"], "ro'inre'o")  # `CLL 4.11 step 4a`
    # `CLL 4.11 step 4a`
    #   .i le rafsi pe `Example 4.73`
    check isRoundTrip(["sai", "zba", "ta'u"], "sairzbata'u")  # `CLL 4.11 step 4a`
    # ro liste rafsi poi se tarmi `CVV` .a `CCV`
    #   .i mulno cipra
    for first in LUT_RAFSI_BY_FORM[Form.Cvv]:
      for second in LUT_RAFSI_BY_FORM[Form.Ccv]:
        # `CLL 4.11 step 4a`
        #   .i re rafsi
        check hyphensRafsi([first, second]) == @[Hyphen.None, Hyphen.None]  # `CLL 4.11 step 4a`
        # `CLL 4.11 step 4a`
        #   .i za'u re rafsi
        check hyphensRafsi([first, second, "zba"])[0] == Hyphen.R  # `CLL 4.11 step 4a`
    var
      finals: seq[string]  # lo pamoi gismu pe le liste zi'e pe ro krasi zunsna
      count_impermissible = 0
    for last in LUT_RAFSI_BY_FORM[Form.Cvccv] & LUT_RAFSI_BY_FORM[Form.Ccvcv]:
      if finals.allIt(it[0] != last[0]): finals.add last
    # ro lo paze zunsna cu krasi lo liste gismu
    check finals.len == CONSONANTS.card  # `CLL 3.6`
    # mulno cipra
    for first in LUT_RAFSI_BY_FORM[Form.Cvc]:  # ro liste rafsi poi se tarmi `CVC`
      for last in finals:
        if isPairPermissible(first[^1], last[0]): continue
        check hyphensRafsi([first, last])[0] == Hyphen.Y  # `CLL 4.11 step 4b`
        inc count_impermissible
    # `Article IX.3`
    #   .i le bandu cu curmi lo banzu
    check count_impermissible >= JUNCTIONS_FLOOR_IMPERMISSIBLE  # `Article IX.3`
    for stem in LUT_RAFSI_BY_FORM[Form.Cvcc] & LUT_RAFSI_BY_FORM[Form.Ccvc]:  # mulno cipra
      let after_cvv = (if stem[0] == 'r': Hyphen.N else: Hyphen.R)
      check hyphensRafsi([stem, "zda"])[0] == Hyphen.Y  # `CLL 4.11 step 4c`
      # `CLL 4.11 4a, 4c`
      check hyphensRafsi(["sai", stem, "zda"]) == @[after_cvv, Hyphen.Y, Hyphen.None]  # `4a, 4c`
    check rafsiSplit("tosmabru").len == 0  # `CLL 4.11 step 5` to lo nu fliba pe `tosmabru` toi
    for (rafsi, word) in [
      (@["cak", "respa"], "cakyrespa"),
      (@["cib", "laj", "ter", "kruca"], "cibylajyterkruca"),
      (@["det", "sel", "lacri"], "detyselylacri"),
      (@["dig", "lig", "kamju"], "digyligykamju"),
      (@["puc", "ter", "runta"], "pucyteryrunta"),
      (@["xas", "mabru"], "xasymabru"),
    ]:
      # `CLL 4.11 step 5c`
      #   .i `y` cu zvati lo pamoi jorne remei
      #   .i `lujvo.txt` cu vasru le valsi
      check isRoundTrip(rafsi, word)  # `CLL 4.11 step 5c`
    check isRoundTrip(["tos", "mabru"], "tosymabru")  # `CLL 4.11 step 5c` to zbasu le valsi toi
    # `CLL 4.11 step 5c`
    #   .i pa `y`
    #   .i zbasu le valsi
    check isRoundTrip(["tos", "tos", "mabru"], "tosytosmabru")  # `CLL 4.11 step 5c`
    # `CLL 4.11 step 5a`
    #   .i lo jorne remei poi lidne `y`
    #   .i zbasu le valsi
    check isRoundTrip(["tos", "tod", "dru"], "tosytodydru")  # `CLL 4.11 step 5a`
    # `CLL 4.11 step 5b`
    #   .i `fm` na ka'e krasi lo valsi
    #   .i zbasu le valsi
    check isRoundTrip(["tof", "mabru"], "tofmabru")  # `CLL 4.11 step 5b`
    # `CLL 4.11 step 4`
    #   .i le lerfu jorne na se nitcu
    #   .i zbasu le valsi
    check rafsiSplit("tofymabru").len == 0  # `CLL 4.11 step 4`


  test "Section 4.12":
    for (rafsi, expected) in [
      ("sarji", 1), ("sarj", 2), ("zbasu", 3), ("zbas", 4),
      ("nun", 5), ("ta'u", 6), ("zba", 7), ("sai", 8),
    ]:
      check rafsi.value == expected  # `CLL 4.12 step 4` to lo liste be lo namcu pe lo rafsi toi
    check isRoundTrip(["zba", "sai"], "zbasai")  # `CLL 4.12, Example 4.71`
    check score(toPieces(["zba", "sai"])) == 5847  # `CLL 4.12, Example 4.71`
    check isRoundTrip(["nun", "nau"], "nunynau")  # `CLL 4.12, Example 4.72`
    check score(toPieces(["nun", "nau"])) == 6967  # `CLL 4.12, Example 4.72`
    check isRoundTrip(["sai", "zba", "ta'u"], "sairzbata'u")  # `CLL 4.12, Example 4.73`
    check score(toPieces(["sai", "zba", "ta'u"])) == 10385  # `CLL 4.12, Example 4.73`
    check isRoundTrip(["zba", "zbas", "sarji"], "zbazbasysarji")  # `CLL 4.12, Example 4.74`
    check score(toPieces(["zba", "zbas", "sarji"])) == 12976  # `CLL 4.12, Example 4.74`


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
      check isRoundTrip(rafsi, word)  # `CLL 4.13` to le xa tarmi be lo'u gerku zdani le'u toi
      # `CLL 4.13`
      #   .i li mubizebi cu drani
      #   .i ku'i `V` pe zo gerzda cu du li re
      check score(toPieces(rafsi)) == expected  # `CLL 4.13`
      check score(toPieces(["ger", "zda"])) <= expected  # `CLL 4.13` to zo gerzda cu ka'e jinga toi
    let forms_bloti_klesi = [
      (@["lot", "kle"], "lotkle", 5878),
      (@["blo", "kle"], "blokle", 5858),
      (@["lo'i", "kle"], "lo'ikle", 6367),
      (@["lot", "lei"], "lotlei", 5867),
      (@["blo", "lei"], "blolei", 5847),
      (@["lo'i", "lei"], "lo'irlei", 7456),
    ]
    for (rafsi, word, expected) in forms_bloti_klesi:
      check isRoundTrip(rafsi, word)  # `CLL 4.13` to le xa tarmi be lo'u bloti klesi le'u toi
      check score(toPieces(rafsi)) == expected  # `CLL 4.13` to lo liste be lo xa namcu toi
      check score(toPieces(["blo", "lei"])) <= expected  # `CLL 4.13` to zo blolei cu se nelci toi
    for first in ["lot", "blo", "lo'i", "blot"]:
      for last in ["kle", "lei", "klesi"]:
        let rafsi = @[first, last]
        # `CLL 4.13` zoi gy. six further forms .gy.
        #   .i le tarmi cu drani ji'a
        check rafsiSplit(joinRafsi(rafsi)) == @[rafsi]  # `CLL 4.13`
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
      # le pare tarmi be lo'u logji bangu girzu le'u
      check isRoundTrip(rafsi, word)  # `CLL 4.13`
    check score(toPieces(["loj", "ban", "gri"])) == 8827  # `CLL 4.13` zoi gy. 8827 versus 8796 .gy.
    check score(toPieces(["loj", "bau", "gri"])) == 8796  # `CLL 4.13` zoi gy. 8827 versus 8796 .gy.
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
      # le bi tarmi be lo'u nakni ke cinse ctuca le'u
      check isRoundTrip(rafsi, word)  # `CLL 4.13`
      if word != "nakykemcinctu":
        check score(toPieces(["nak", "kem", "cin", "ctu"])) < score(toPieces(rafsi))  # `CLL 4.13`



suite "Chapter 7":
  test "Section 7.15":
    # `CLL 7.15` lo'u tavla be do le'u
    #   .i sruma le te fendi
    check isRoundTrip(["don", "ta'a"], "donta'a")  # `CLL 7.15`
    # `CLL 7.15` lo'u cmavo be zo do le'u
    #   .i sruma le te fendi
    check isRoundTrip(["don", "ma'o"], "donma'o")  # `CLL 7.15`
    check isRoundTrip(["fo'a", "sel", "sanga"],
        "fo'arselsanga")  # `CLL 7.15, Example 7.78` to sruma le te fendi toi
    # `CLL 7.15`
    #   .i sruma le te fendi
    check isRoundTrip(["zil", "rel", "sel", "pinxe"], "zilrelselpinxe")  # `CLL 7.15`
    # `CLL 7.15`
    #   .i `x1` cu se vimcu
    #   .i sruma le te fendi
    check isRoundTrip(["zil", "pav", "pinxe"], "zilpavypinxe")  # `CLL 7.15`



suite "Internal: Convention":
  test "Forbidden triple at junction takes y":
    # `CLL 3.7` cu to'e curmi `ndz`
    #   .i `CLL 4.11 4b` na casnu
    #   .i `lujvo.txt`
    check isRoundTrip(["kan", "dzu"], "kanydzu")  # `CLL 3.7`
    # `CLL 3.7` cu to'e curmi `ndj`
    #   .i `lujvo.txt`
    check isRoundTrip(["pen", "dju", "xa'a"], "penydjuxa'a")  # `CLL 3.7`
    # `CLL 3.7` cu to'e curmi `nts`
    #   .i `CLL 4.11` na casnu
    #   .i zbasu le valsi
    check isRoundTrip(["ban", "tsa"], "banytsa")  # `CLL 3.7`
    # lo javni pe le vi se gunka
    #   .i lo tarmi poi `CLL 4.11` cu dunda ke'a cu na mapti `CLL 3.7`
    #   .i zbasu le valsi
    check rafsiSplit("kandzu").len == 0  # `CLL 4.11`
    for triple in TRIPLES_NAMED:
      let rafsi = ["ka" & triple[0], triple[1 .. 2] & "a"]
      check isPairPermissible(triple[0], triple[1])  # `CLL 4.11 step 4b` po'o cu jmina no `y` vi
      # lo javni pe le vi se gunka
      #   .i `y` cu fendi lo zunsna cimei poi `CLL 3.7` cu cusku ke'a
      check hyphensRafsi(rafsi)[0] == Hyphen.Y  # `CLL 3.7`


  test "CVC then CCV takes y exactly where cluster breaks 3.6 or 3.7":
    # ro liste rafsi poi se tarmi `CVC` .a `CCV`
    #   .i mulno cipra
    for first in LUT_RAFSI_BY_FORM[Form.Cvc]:
      for last in LUT_RAFSI_BY_FORM[Form.Ccv]:
        let is_broken = not isPairPermissible(first[^1], last[0]) or
            not isTriplePermissible(first[^1], last[0], last[1])
        # `CLL 4.11 4b`
        #   .i lo javni pe le vi se gunka
        check (hyphensRafsi([first, last])[0] == Hyphen.Y) == is_broken  # `CLL 4.11 4b`



suite "Internal: Laws":
  test "Split inverts join over every form pattern of two and three rafsi":
    for first in FORMS_MEDIAL:  # ne'i ro tarmi lo pamoi rafsi pe le liste cu sinxa le tarmi
      for last in FORMS_LAST:
        let rafsi = @[LUT_RAFSI_BY_FORM[first][0], LUT_RAFSI_BY_FORM[last][0]]
        # javni
        #   .i lo nu fendi lo ve jmina cu se jalge le rafsi po'o
        check rafsiSplit(joinRafsi(rafsi)) == @[rafsi]  # javni
        for middle in FORMS_MEDIAL:
          let longer = @[rafsi[0], LUT_RAFSI_BY_FORM[middle][0], rafsi[1]]
          # javni
          #   .i lo nu fendi lo ve jmina cu se jalge le rafsi
          check rafsiSplit(joinRafsi(longer)) == @[longer]  # javni


  test "Split inverts join over random rafsi":
    for rafsi in rafsiRandom():  # lo porsi poi `SAMPLES` cu te kancu ke'a to lo tsiju cu jdice toi
      # javni
      #   .i lo nu fendi lo ve jmina cu se jalge le rafsi po'o
      check rafsiSplit(joinRafsi(rafsi)) == @[rafsi]  # javni


  test "Split inverts join over rafsi form list assigns to no word":
    # lo porsi poi `SAMPLES` cu te kancu ke'a
    #   .i lo tsiju cu jdice
    #   .i le porsi cu se zbasu fi lo lerfu pe ro tarmi
    for rafsi in rafsiLetters():
      # javni
      #   .i lo nu fendi lo ve jmina cu se jalge le rafsi po'o
      check rafsiSplit(joinRafsi(rafsi)) == @[rafsi]  # javni


  test "Join makes brivla over random rafsi":
    for rafsi in rafsiRandom():  # lo porsi poi `SAMPLES` cu te kancu ke'a to lo tsiju cu jdice toi
      # javni
      #   .i lo lujvo cu ralte lo ckaji be lo brivla to `CLL 4.3` .e `CLL 4.5` toi
      check joinRafsi(rafsi).isBrivla  # `CLL 4.3`


  test "Segmentation keeps rafsi where required hyphen after short rafsi is removed":
    var count_removed = 0
    for rafsi in rafsiRandom():  # lo porsi poi `SAMPLES` cu te kancu ke'a to lo tsiju cu jdice toi
      let pieces = toPieces(rafsi)
      var is_removed = false
      for i in 0 ..< pieces.high:
        if pieces[i].hyphen == Hyphen.None or pieces[i].form notin FORMS_SHORT: continue
        let segments = spell(pieces, i).segmentLujvo.mapIt(it.mapIt(it.rafsi))
        # javni
        #   .i le tcidu cu za'o facki le rafsi
        #   .i se ki'u bo le tcidu cu cusku lo tarmi poi `CLL 4.11` cu dunda ke'a
        check rafsi in segments  # `CLL 4.11`
        is_removed = true
      if is_removed: inc count_removed
    # `Article IX.3`
    #   .i le bandu cu curmi lo banzu mupli
    check count_removed >= SAMPLES_FLOOR_REMOVED  # `Article IX.3`


  test "Hyphen added or removed breaks split over random rafsi":
    # zbasu le valsi
    check rafsiSplit("kramyliste") == @[@["kram", "liste"]]  # `CLL 4.11 step 4c`
    # javni
    #   .i lo drata lujvo
    #   .i zbasu le valsi
    check rafsiSplit("kramliste") == @[@["kra", "mli", "ste"]]  # javni
    var
      count_added = 0
      count_removed = 0
    for rafsi in rafsiRandom():  # lo porsi poi `SAMPLES` cu te kancu ke'a to lo tsiju cu jdice toi
      let pieces = toPieces(rafsi)
      var is_added, is_removed = false
      for i in 0 ..< pieces.high:
        if pieces[i].hyphen == Hyphen.None:
          for letter in ["y", "r", "n"]:
            # javni
            #   .i lo jmina lerfu jorne to `CLL 4.11 step 4` toi
            check rafsiSplit(spell(pieces, i, letter)).len == 0  # `CLL 4.11 step 4`
          is_added = true
        elif pieces[i].form in FORMS_SHORT:
          # javni
          #   .i lo lerfu jorne poi se lidne lo cmalu rafsi cu se vimcu
          check rafsiSplit(spell(pieces, i)).len == 0  # javni
          is_removed = true
      if is_added: inc count_added
      if is_removed: inc count_removed
    # le bandu cu curmi lo banzu mupli
    check count_added >= SAMPLES_FLOOR_ADDED  # `Article IX.3`
    # `Article IX.3`
    #   .i le bandu cu curmi lo banzu mupli
    check count_removed >= SAMPLES_FLOOR_REMOVED  # `Article IX.3`


  test "Score sums part of each rafsi and each junction, y step 5 puts at first one included":
    var count_broken = 0
    # lo porsi poi `SAMPLES_RUN` cu te kancu ke'a gi'e se krasi lo porsi be lo rafsi poi se tarmi
    #   `CVC`
    #   .i lo tsiju cu jdice le porsi
    for rafsi in rafsiRun():
      # `CLL 4.12`
      #   .i ro te jorne ta'i lo nu sepli
      #   .i `CLL 4.11 step 5`
      check rafsi.scoreJunctions == rafsi.toPieces.score  # `CLL 4.12`
      if rafsi.isBrokenFirst: inc count_broken
    # lo porsi be lo liste rafsi be'o poi `SAMPLES` cu te kancu ke'a
    #   .i lo tsiju cu jdice le porsi
    for rafsi in rafsiRandom():
      # `CLL 4.12`
      #   .i ro te jorne ta'i lo nu sepli
      check rafsi.scoreJunctions == rafsi.toPieces.score  # `CLL 4.12`
    # lo porsi poi `SAMPLES` cu te kancu ke'a
    #   .i lo tsiju cu jdice
    #   .i le porsi cu se zbasu fi lo lerfu pe ro tarmi
    for rafsi in rafsiLetters():
      # `CLL 4.12`
      #   .i ro te jorne ta'i lo nu sepli
      check rafsi.scoreJunctions == rafsi.toPieces.score  # `CLL 4.12`
    # le bandu cu cipra fi lo nu `step 5` cu punji `y` lo pamoi te jorne
    check count_broken >= SAMPLES_FLOOR_BROKEN  # le bandu cu zgana `y` pe `step 5`


  test "Corpus splits exactly once in either notation":
    let lines = readLinesLujvo()
    if lines.isNone: skip()  # `lujvo.txt` cu na zvati gi'a cenba to `texts_outside.nim` toi
    else:
      var failing: seq[string]
      # ro linji poi lo valsi pe ke'a cu se gunma lo lerfu
      #   .i le re sinxa
      #   .i mulno cipra
      for line in lines.get:
        if line.word.splitLujvo.len != 1: failing.add line.word
      # javni
      #   .i ro linji cu se fendi pa roi
      #   .i lo linji poi te sitna cu se cliva
      check failing.sorted == EXCEPTIONS_SPLIT.sorted  # javni


  test "Corpus in lojban notation splits into listed parts":
    let lines = readLinesLujvo()
    if lines.isNone: skip()  # `lujvo.txt` cu na zvati gi'a cenba to `texts_outside.nim` toi
    else:
      var
        count = 0
        failing: seq[string]
      for line in lines.get:
        if line.is_english: continue
        let parts = line.parts.mapIt(it.word)
        if parts.len == 0 or not parts.allIt(it.isSome): continue
        inc count
        let splits = line.word.splitLujvo
        var is_resolved = splits.len == 1 and splits[0].len == parts.len
        if is_resolved:
          for i, piece in splits[0]:
            is_resolved = is_resolved and piece.isStanding(parts[i].get)
        if not is_resolved: failing.add line.word
      check count >= ENTRIES_FLOOR_LOJBAN  # `Article IX.3` to le bandu cu curmi lo banzu cmima toi
      # javni
      #   .i le rafsi cu sinxa le pagbu ta'i lo porsi
      check failing.sorted == EXCEPTIONS_LOJBAN.sorted  # javni


  test "Corpus in English notation reads with one part for each keyword":
    let lines = readLinesLujvo()
    if lines.isNone: skip()  # `lujvo.txt` cu na zvati gi'a cenba to `texts_outside.nim` toi
    else:
      var
        count = 0
        failing: seq[string]
      for line in lines.get:
        if not line.is_english or line.parts.len == 0: continue
        inc count
        let reading = line.word.readWord
        if not reading.is_word or reading.tanru.parts.len != line.parts.len: failing.add line.word
      check count >= ENTRIES_FLOOR_ENGLISH  # `Article IX.3` to le bandu cu curmi lo banzu linji toi
      # ro ckiku valsi cu ponse pa pagbu
      check failing.sorted == EXCEPTIONS_ENGLISH.sorted  # javni


  test "Corpus spells each word suite cites from it":
    let lines = readLinesLujvo()
    if lines.isNone: skip()  # `lujvo.txt` cu na zvati gi'a cenba to `texts_outside.nim` toi
    else:
      let words = lines.get.mapIt(it.word)
      for word in WORDS_CITED:
        check word in words  # `lujvo.txt` cu vasru le valsi poi te sitna `lujvo.txt`
