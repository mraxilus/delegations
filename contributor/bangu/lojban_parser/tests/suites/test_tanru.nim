## rapli lo se tcidu be lo valsi pe le cimoi ckupau .e le vomoi ckupau be `CLL` sepi'o `tanru.nim`
##     gi'e cipra lo javni poi `CLL` nibli ke'a
##   .i lo selci'avla .e lo tanru .e lo namcu cu fukpi lo selci'a be `CLL` gi'e no roi fukpi lo
##       jalge be le genturfa'i
##   .i se ki'u bo le cipra cu cipra lo se tcidu gi'e na rapli le se tcidu
##   .i `CLL 4.13` cusku lo du'u `V` pe zo gerzda du li ci
##   .i la'e di'u srera
##   .i ku'i lo sumji po'u li mubizebi cu drani
##   .i le cipra cu cipra lo du'u le sumji cu du li mubizebi
##   .i lo pinka be lo lujvo poi `CLL` dunda ke'a gi'e na fendi ke'a lo rafsi cu cusku lu lo nu
##       fendi cu se sruma li'u
##   .i lo pinka be lo valsi poi no krasi cu vasru ke'a cu cusku lu le valsi cu se zbasu li'u
##   .i lo javni cu jdice
##   .i lo liste cu dunda lo cmene po'o to `#823` toi
##   .i le cipra cu jarco lo du'u lo selci'a poi lo javni cu curmi ke'a se tcidu
##   .iju lo liste cu vasru le selci'a
##   .i le cipra cu karbi ro nu to'e curmi lo javni pe `CLL` ge'u zi'e poi le nu to'e curmi cu cusku
##       ke'a
##   .i lo sinxa be lo porsi be lo valsi cu se cipra ta'i `Stream`
##   .i `readStream` tcidu le sinxa
##   .i `test_stream.nim` cipra lo lerfu po'u slaka bu .e lo brale'u vu'o poi `CLL` ciska ke'a ne'i
##       lo valsi to `CLL 3.3` .e `CLL 3.9` toi
##   .i lo te kancu be lo tanru cu na se jimte
##   .i se ki'u bo lo jvacipra cu tcidu lo cuntau poi lo tsiju cu jdice ke'a
##   .i lo te kancu be lo gismu pe ro le tanru cu cmima li pa bi'o li vo
##   .i ro le gismu cu selcu'a fi lo'i gismu pe le liste
##   .i lo jvacipra cu tcidu ji'a ro cmima be le liste to `Article IX.3` toi
##   .i lo jvacipra poi ciska lo tanru gi'e xrutcidu le selci'a cu tcidu ji'a lo tanru poi lo tsiju
##       cu jdice ke'a
##   .i lo te kancu be lo valsi pe ro le tanru cu cmima li pa bi'o li xa
##   .i su'o le valsi cu cmavo
##   .i ki'u bo lo lujvo cu vasru ji'a lo rafsi be lo cmavo to `CLL 4.6` toi
##   .i lo valsi poi no liste cu vasru ke'a se cipra ji'a
##   .i le cipra cu tcidu ro lerpoi poi seltai lo tarmi be lo gismu
##   .i le cipra cu tcidu ji'a lo lujvo poi lo tsiju cu jdice ke'a gi'e se gunma lo rafsi poi selzba
##       lo lerfu ja'i ro tarmi
##   .iju lo liste cu dunda le rafsi lo valsi to `Article IX.4` toi
##   .i le se karbi pe lo cmaraina'u cu liste ro rafsi poi `CLL 4.11 step 1` .e `CLL 4.11 step 2`
##       curmi ke'a
##   .i `brod` noi selpo'e su'o re gismu cu cmima le liste
##   .i le se karbi cu ralte lo selci'avla poi se tcidu ta'i le tanru
##   .i le cipra cu karbi lo namcu pe lo selci'a be `$` lo cmaraina'u pe le selci'avla
##   .i jdima fa lo nu lo te kancu be lo nu jmina .e lo nu tcidu ne'i ro tanru cu na zmadu `4^n`
##   .i `n` du lo te kancu be lo gismu pe le tanru
##   .i le mulsisku cu dunda lo namcu ro porsi be lo selcu'a poi `$` tcidu ke'a
##   .i le mulsisku cu ralte le pamoi be le porsi poi ponse lo cmaraina'u
##   .i `$` ciska le mintu tarmi to `IX.2` toi
##   .i `searchLowest` po'o cuxna le mitpoi ne'i lo cunste be lo te cuxna
##   .i ne'i le liste lo mitna'u .e lo tcini be lo porsi pe `CLL 4.11 step 5` cu so'i roi jdice
##   .i lo jdima be ro le re mulsisku cu du lo pilji be lo te kancu be lo se cuxna pe ro stuzi
##   .i lo se cipra ca na vasru lo nu karbi lo cmaraina'u pe lo tanru poi vasru su'o pano valsi kei
##       le mulsisku
##   .i pa tanru poi vasru pabi valsi cu se karbi fi le mulsisku ne'i ro lo krasi pagbu po'o poi lo
##       te kancu be lo valsi pe ke'a na zmadu `COUNT_PREFIX_MAX`

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]
from std/unicode import Rune, toUTF8, validateUtf8

import ../../src/lojban_parser/[
  clusters, dictionary, forms, fuhivla, lujvo {.all.}, selmaho, tanru {.all.},
]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ./[rafsi_random, texts_outside]


const
  SAMPLES = 1000
    ## lo te kancu be lo cunso tanru poi lo javni cipra cu cuxna ke'a
    ##   .i lo tsiju cu jdice le tanru
  FLOOR_SHARED_ROUND = 2
    ## lo cmajimte be lo te kancu be lo mupli poi vasru zo brodi .a zo brodo .a zo brodu vu'o poi na
    ##     romoi
    ##   .i lo se tcidu be le mupli cu vasru lo pagbu po'u `brod`
    ##   .i ci le mupli cu se tcidu va'o lo tsiju po'u `0`
    ##   .i ji'i pa fi'u cinono lo mupli cu vasru pa le gismu
  FLOOR_LOWEST = 650
    ## lo cmajimte be lo te kancu be lo mupli poi lo javni cipra be lo cmalu traji namcu cu tcidu
    ##     ke'a
    ##   .i ro le mupli cu vasru su'o re gismu gi'e vasru no gismu poi du zo brodi .a zo brodo .a zo
    ##       brodu gi'e na romoi
    ##   .i li zepaso le mupli cu se tcidu va'o lo tsiju po'u `0`
    ##   .i lo nu ci fi'u vo lo mupli cu se tcidu cu se kanpe
  FLOOR_SEARCH = 3400
    ## lo cmajimte be lo te kancu be lo cunso tanru poi lo javni cipra be lo nu sisku cu cipra `$`
    ##     sepi'o ke'a
    ##   .i li cimunono le tanru cu se tcidu va'o lo tsiju pe le sorcu
    ##   .i la'e di'u du ro lo cunselcu'a
  FLOOR_BROKEN = 3
    ## lo cmajimte be lo te kancu be le cunso tanru poi `CLL 4.11 step 5` punji `y` lo pamoi te
    ##     jorne be ke'a
    ##   .i vo le tanru cu zasti va'o le tsiju
  FLOOR_LUJVO_LIST = 3700
    ## lo cmajimte be lo te kancu be lo linji pe `lujvo.txt` ge'u zi'e poi se tcidu ta'i lo tanru
    ##     poi vasru su'o re valsi
    ##   .i li cibireno le linji cu se tcidu
  SAMPLES_OPTIONS = 5000
    ## lo te kancu be lo cunso liste be lo te cuxna be'o poi lo javni cipra be lo nu sisku cu cuxna
    ##     ke'a
    ##   .i lo tsiju cu jdice le liste
  FLOOR_TIE = 2500
    ## lo cmajimte be lo te kancu be le liste poi lo romoi be lo porsi poi ponse lo cmalu traji
    ##     namcu cu frica lo pamoi be le porsi
    ##   .i li rebipano le liste cu se tcidu va'o lo tsiju po'u `0`
  FLOOR_STATE = 45
    ## lo cmajimte be lo te kancu be le liste poi lo nu sisku poi na pilno lo tcini be lo porsi cu
    ##     cuxna lo drata
    ##   .i li mubi le liste cu se tcidu va'o lo tsiju po'u `0`
  COUNT_PREFIX_MAX = 9
    ## lo brajimte be lo te kancu be lo valsi pe lo krasi pagbu be lo clani tanru be'o poi se karbi
    ##     fi lo mulno sisku
  FLOOR_FINAL_CMAVO = 25
    ## lo cmajimte be lo te kancu be lo rafsi be lo cmavo be'o poi se tarmi `CVV` .a `CCV` gi'e ka'e
    ##     fanmo lo valsi gi'e se tcidu lo javni cipra be lo fanmo stuzi
    ##   .i li cino le rafsi cu selvau le liste
  SAMPLES_CMAVO = 500
    ## lo te kancu be lo cunso tanru poi lo remoi javni cipra be lo nu ciska gi'e xruti tcidu cu
    ##     cuxna ke'a
    ##   .i lo te kancu be lo valsi pe ro le tanru cu cmima li pa bi'o `COUNT_WORDS_CMAVO_MAX`
    ##   .i su'o le valsi cu cmavo
    ##   .i lo tsiju cu jdice le tanru
  COUNT_WORDS_CMAVO_MAX = 6
    ## lo brajimte be lo te kancu be lo valsi pe le tanru
    ##   .i lo temci be lo mulsisku cu binxo lo pilji be lo pu temci bei li ji'i vo ca ro nu jmina
    ##       pa valsi
    ##   .i se ki'u bo lo nu li xa cu jimte cu ralte lo nu le cipra cu sutra
  FLOOR_CMAVO = 220
    ## lo cmajimte be lo te kancu be le tanru poi vasru lo cmavo
    ##   .i li remuvo le tanru cu se tcidu va'o lo tsiju po'u `0`
  FLOOR_SHARED = 20
    ## lo cmajimte be lo te kancu be le tanru poi vasru zo brodi .a zo brodo .a zo brodu vu'o poi na
    ##     romoi
    ##   .i li reze le tanru cu se tcidu va'o lo tsiju po'u `0`
  SAMPLES_FORMS = 2000
    ## lo te kancu be lo cunso lujvo poi se gunma lo rafsi poi se zbasu lo lerfu sepi'o ro tarmi
    ##   .i lo tsiju cu jdice le lujvo
  SAMPLES_LETTERS = 20000
    ## lo te kancu be lo cunso lerpoi poi lo javni cipra be lo klesi cu tcidu ke'a
    ##   .i lo te kancu be lo lerfu pe ro lerpoi cu cmima li mu bi'o li pano
    ##   .i lo nu lo lerfu cu zunsna cu cunso fi li pa fi'u re
  FLOOR_FUHIVLA = 1400
    ## lo cmajimte be lo te kancu be le lerpoi poi se tcidu ta'i lo fu'ivla
    ##   .i li pamuvomu le lerpoi cu se tcidu va'o lo tsiju po'u `0`
  FLOOR_CMENE = 4800
    ## lo cmajimte be lo te kancu be le lerpoi poi se tcidu ta'i lo cmene
    ##   .i li munovoci le lerpoi cu se tcidu va'o lo tsiju po'u `0`
  SAMPLES_JOINED = 2000
    ## lo te kancu be lo cunso se jmina
    ##   .i ro se jmina cu se gunma pa cmavo .a re cmavo vu'o pe lo liste ge'u zi'e poi selkra lo
    ##       zunsna gi'e na vasru `y`
    ##   .i ro se jmina cu se gunma ji'a pa gismu pe lo liste ge'u zi'e poi seltai `CCVCV`
    ##   .i le cmavo cu lidne le gismu
    ##   .i lo tsiju cu jdice le se jmina
    ##   .i no javni pe `CLL 4.9` nitcu lo denpa bu'u lo jbini be le valsi
    ##   .i lo zunsna remei poi krasi le gismu cu zvati le mu lerfu poi krasi le se jmina ta'i lo
    ##       brivla to `CLL 4.3` toi
  FLOOR_JOINED = 140
    ## lo cmajimte be lo te kancu be le se jmina poi se to'e curmi ta'i lo valsi gunma
    ##   .i li pamuxa le se jmina cu se tcidu va'o lo tsiju po'u `3`
    ##   .i so'e lo datseljmina cu se tcidu ta'i lo lujvo poi ponse lo srelerjo'e ku'o gi'a vasru lo
    ##       zunsna remei poi se lidne lo mumoi lerfu
  CONSONANTS_LETTERS = "bcdfgjklmnprstvxz"  ## lo paze zunsna pe `CLL 3.1`
  FLOOR_UNASSIGNED = 1700
    ## lo cmajimte be lo te kancu be lo cunso lujvo poi vasru lo rafsi poi le liste cu dunda ke'a no
    ##     valsi
    ##   .i ro le lujvo cu se gunma lo rafsi poi selzba lo lerfu
    ##   .i li pazevoci le lujvo cu se tcidu va'o lo tsiju po'u `0`
    ##   .i ki'u bo so'e lo rafsi poi selzba lo lerfu cu sinxa no valsi ne'i ro tarmi
  ALPHABET = "',.abcdefgijklmnoprstuvxyz"
    ## lo lerfu .e lo sinxa vu'o pe `CLL 3.1`
    ##   .i le porsi cu mintu le porsi pe `CLL 3.1`
  GISMU_STEM_SHARED = ["brodi", "brodo", "brodu"]
    ## le vi gismu cu ponse no cmarafsi
    ##   .i se ki'u bo le gismu cu ponse pa rafsi po'o poi na fanmo lo valsi
    ##   .i le rafsi cu du `brod`
    ##   .i zo broda .e zo brode ponse ji'a `brod`
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
    ## ro selci'avla pe le vomoi ckupau be `CLL` ge'u zi'e poi le cipra cu sitna ke'a zi'e poi se
    ##     tcidu ta'i pa valsi
  SPELLINGS_CLL_REFUSED = ["patta'a", "mudsiclu", "ro'ire'o", "ro'irre'o"]
    ## ro selci'avla pe le vomoi ckupau be `CLL` ge'u zi'e poi le cipra cu sitna ke'a zi'e poi le
    ##     tcidu cu to'e curmi ke'a
    ##   .i ro le selci'avla cu vasru lo lerjo'e poi `CLL 4.6` to'e curmi ke'a gi'a du lo ma'orgunma
    ##       be re cmavo
  WORDS_GISMU = block:
    ## ro gismu pe le liste ta'i lo stuna'u
    ##   .i lo cmavo poi ponse lo rafsi cu na selvau
    var words: seq[Word]
    for i, entry in LIST_GISMU:
      if entry.word.isGismu: words.add Word(i)
    words
  WORDS_CMAVO = block:
    ## ro cmavo pe le liste ge'u zi'e poi ponse lo rafsi ku'o ta'i lo stuna'u
    var words: seq[Word]
    for i, entry in LIST_GISMU:
      if not entry.word.isGismu: words.add Word(i)
    words
  WORDS_CMAVO_JOINABLE = block:
    ## ro cmavo pe le ma'oste ge'u zi'e poi selkra lo zunsna gi'e vasru no `y`
    ##   .i no javni pe `CLL 4.9` nitcu lo denpa poi lidne lo valsi poi selkra lo zunsna gi'e se
    ##       lidne le cmavo
    var words: seq[string]
    for entry in LIST_CMAVO:
      if entry.word[0] in CONSONANTS_LETTERS and 'y' notin entry.word: words.add entry.word
    words
  CHARACTERS_FOREIGN = [
    "\u0080", "é", "ĉ", "ʼ", "߿", "ࠀ", "’", "日", "�",
    "￿", "\u{10000}", "\u{1D44E}", "\u{1F600}", "\u{10FFFF}",
  ]
    ## lo lerfu poi na cmima le lerfu pe `LETTERS`
    ##   .i le lerfu cu selgri ja'i lo te kancu be lo stuzi pe `UTF-8` ge'u zi'e poi ro lerfu cu
    ##       pilno ke'a ja'i `Table 3-6` pe `Unicode Standard`
    ##   .i le lerfu poi pilno re stuzi cu du `é` .e `ĉ` .e lo gafle'u poi simsa zoi gy. ' .gy. ku'o
    ##       .e lo pamoi .e lo romoi
    ##   .i le lerfu poi pilno ci stuzi cu du lo krule'u poi simsa zoi gy. ' .gy. ku'o .e lo xrale'u
    ##       .e `U+FFFD` .e lo pamoi .e lo romoi
    ##   .i le lerfu poi pilno vo stuzi cu du lo sa'ormekle'u .e lo cnixra .e lo pamoi .e lo romoi
    ##   .i le se cipra cu se ganzu gi'e na du le mulselcipra
    ##   .i lo cunle'u poi lo tsiju cu jdice ke'a se tcidu ne'i lo datpau be le mulno se cipra
    ##   .i lo te kancu be le cunso lerfu cu du `SAMPLES_FOREIGN`
  SAMPLES_FOREIGN = 1000
    ## lo te kancu be lo cunso lerfu poi na cmima `ASCII` gi'e se tcidu lo javni cipra pe `Letter`
    ##   .i lo tsiju cu jdice le lerfu
    ##   .i lo te kancu be lo stuzi pe `UTF-8` cu selcu'a pu lo drata
    ##   .i le te kancu cu cmima li re bi'o li vo
    ##   .i ba bo lo lerna'u poi pilno le te kancu cu selcu'a
    ##   .i se ki'u bo ro linji pe `Table 3-6` cu so'i roi se tcidu
  FLOOR_FOREIGN = 950
    ## lo cmajimte be lo te kancu be lo cunso lerfu poi me `scalar value`
    ##   .i lo me `surrogate` cu selvi'u
    ##   .i li sobixa le lerfu cu se tcidu va'o lo tsiju po'u `0`
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"
    ## lo paze zunsna poi `C` sinxa ke'a ja'i `CLL 4.1 rule 3`
  ORDER_VOWELS = "aeiou"
    ## lo mu karsna poi `V` sinxa ke'a ja'i `CLL 4.1 rule 1`
    ##   .i `y` na cmima le mu karsna


func toTanru(text: string): Tanru =
  ## zbasu lo tanru lo valsi pe lo liste ge'u zi'e poi `+` jorne ke'a
  ##   .i le cipra cu ciska lo tanru ta'i la'e di'u
  Tanru(parts: text.split('+').mapIt(it.word.get.toPart))


func unlisted(letters: string): Part =
  ## zbasu lo pagbu poi na sinxa pa valsi pe lo liste ku'o lo lerfu pe le pagbu
  Part(is_listed: false, letters: letters)


func tanruRead(text: string): Option[Tanru] =
  ## tcidu lo selci'a ta'i pa valsi gi'e dunda lo tanru
  ##   .i va'o lo nu le selci'a cu se to'e curmi cu dunda `none`
  let reading = text.readWord
  if reading.is_word: some(reading.tanru) else: none(Tanru)


func kindRead(text: string): Option[Kind] =
  ## tcidu lo selci'a ta'i pa valsi gi'e dunda lo klesi pe le valsi
  ##   .i va'o lo nu le selci'a cu se to'e curmi cu dunda `none`
  let reading = text.readWord
  if reading.is_word: some(reading.kind) else: none(Kind)


func refusalRead(text: string): Option[(Refusal, string)] =
  ## tcidu lo selci'a gi'e dunda lo krinu be lo nu to'e curmi be'o .e lo tcila
  ##   .i va'o lo nu le selci'a cu valsi cu dunda `none`
  let reading = text.readWord
  if reading.is_word: none((Refusal, string)) else: some((reading.refusal, reading.detail))


func scoreRead(text: string): Option[int] =
  ## dunda lo namcu lo rafsi pe lo selci'a ta'i lo nu le tcidu cu fendi le se ciska to `CLL 4.12`
  ##     toi
  ##   .i va'o lo nu le selci'a cu se to'e curmi cu dunda `none`
  let reading = text.readWord
  if reading.is_word: some(reading.pieces.score) else: none(int)


func spelled(pieces: openArray[Piece]): string =
  ## ciska lo pagbu ta'i lo lerfu
  ##   .i ro rafsi cu lidne lo lerjo'e pe vo'a
  for piece in pieces: result.add piece.rafsi & LUT_LETTER_BY_HYPHEN[piece.hyphen]


func isStemShared(tanru: Tanru): bool =
  ## jdice lo du'u `$` bilga lo nu ciska `brod` noi selpo'e su'o re gismu
  ##   .i la'e di'u jetnu va'o lo nu le tanru cu vasru zo brodi .a zo brodo .a zo brodu vu'o poi na
  ##       romoi
  for i in 0 ..< tanru.parts.high:
    if $tanru.parts[i] in GISMU_STEM_SHARED: return true
  false


func withStemShared(tanru: Tanru): Tanru =
  ## tcidu lo tanru ta'i lo nu lo selci'a be le tanru cu selxrutcidu
  ##   .i zo brodi .e zo brodo .e zo brodu vu'o poi na romoi cu binxo lo pagbu po'u `brod` noi sinxa
  ##       no gismu to `CLL 4.4` toi
  result = tanru
  for i in 0 ..< result.parts.high:
    if $result.parts[i] in GISMU_STEM_SHARED: result.parts[i] = unlisted("brod")


func spellings(tanru: Tanru): seq[seq[string]] =
  ## dunda lo liste be ro porsi be lo rafsi be'o poi `CLL 4.11 step 1` .e `CLL 4.11 step 2` curmi
  ##     ke'a ne'i lo tanru poi vasru su'o re gismu
  ##   .i lo selcu'a cu du lo cmarafsi .e lo rafsi poi vasru vo lerfu .e le gismu
  ##   .i ro le selcu'a cu selpli va'o lo nu lo tarmi be le selcu'a cu selcru bu'u le stuzi
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


func scoreStateless(rafsi: openArray[string]): int =
  ## dunda lo namcu lo rafsi ta'i lo porsi be lo terjo'e gi'e ro roi sruma lo du'u lo porsi pe
  ##     `CLL 4.11 step 5` ganlo
  ##   .i la'e di'u simsa lo sisku poi na pilno lo tcini be lo porsi
  ##   .i lo jvacipra cu kancu lo nu lo selcu'a be le sisku cu frica lo selcu'a be lo namcu pe
  ##       `CLL 4.12`
  result = scoreRafsi(rafsi[0], rafsi[0].form.get)
  for at in 0 ..< rafsi.len - 1:
    result += scoreJunction(false, rafsi[at], rafsi[at+1], at, rafsi.len).score +
        scoreRafsi(rafsi[at+1], rafsi[at+1].form.get)


func searchExhaustive(
  options: seq[seq[string]], as_stateless = false
): tuple[first, last: seq[string]] =
  ## cuxna lo rafsi pe ro stuzi ta'i lo nu dunda lo namcu ro porsi be lo selcu'a
  ##   .i dunda le pamoi .e le romoi vu'o pe lo porsi poi ponse lo cmaraina'u
  ##   .i se ki'u bo lo jvacipra cu viska lo nu lo porsi be le tercu'a cu jdice va'o lo nu lo namcu
  ##       cu mintu
  ##   .i lo jvacipra cu karbi `searchLowest` .e `$` le vi mulno sisku to `IX.2` toi
  ##   .i le mulsisku cu pilno lo namcu pe `CLL 4.12`
  ##   .i va'o lo nu `as_stateless` jetnu kei le mulsisku cu pilno lo namcu poi na pilno lo tcini be
  ##       lo porsi
  ##   .i lo temci cu simsa lo pilji be lo te kancu be lo te cuxna pe ro stuzi
  var sequences = @[newSeq[string]()]
  for at_options in options:
    var extended: seq[seq[string]]
    for chosen in sequences:
      for one in at_options: extended.add chosen & one
    sequences = extended
  var lowest = high(int)
  for rafsi in sequences:
    let value = (if as_stateless: rafsi.scoreStateless else: rafsi.toPieces.score)
    if value < lowest: (lowest, result.first) = (value, rafsi)
    if value <= lowest: result.last = rafsi


func choicesTanru(tanru: Tanru): seq[seq[string]] =
  ## dunda lo liste be lo selcu'a poi `$` tcidu ke'a bu'u ro stuzi pe lo tanru ta'i lo porsi pe le
  ##     tanru
  for i, part in tanru.parts: result.add choices(part, is_final = i == tanru.parts.high)


func renderExhaustive(tanru: Tanru): string =
  ## ciska lo tanru ta'i lo nu dunda lo namcu ro porsi be lo selcu'a poi `$` tcidu ke'a
  ##   .i le pamoi be le porsi poi ponse lo cmaraina'u cu selra'e
  ##   .i lo jvacipra cu karbi `$` le vi mulno sisku to `IX.2` toi
  ##   .i le re tadji cu pilno lo mitselcu'a .e lo mitpoi .e lo mitna'u pe `CLL 4.12`
  ##   .i lo temci be le mulsisku cu binxo lo pilji be lo pu temci ca ro nu jmina pa valsi
  ##   .i se ki'u bo lo jvacipra cu pilno le mulsisku ne'i lo tordu tanru po'o
  if tanru.parts.len == 0: return ""
  if tanru.parts.len == 1: return $tanru.parts[0]
  let options = tanru.choicesTanru
  if options.anyIt(it.len == 0): return tanru.parts.mapIt($it).join(" ")
  joinRafsi(options.searchExhaustive.first)


proc drawOptions(): seq[seq[seq[string]]] =
  ## zbasu lo liste be lo tercu'a be'o lo lerfu
  ##   .i lo te kancu be le liste cu du `SAMPLES_OPTIONS`
  ##   .i lo tsiju cu jdice le liste
  ##   .i lo te kancu be lo stuzi pe ro liste cu cmima li re bi'o li mu
  ##   .i lo te kancu be lo rafsi pe ro stuzi cu cmima li pa bi'o li vo
  ##   .i ro rafsi cu seltai pa tarmi poi `CLL 4.11 step 1` .e `CLL 4.11 step 2` curmi ke'a bu'u le
  ##       stuzi
  ##   .i lo nu lo rafsi poi na romoi cu seltai `CVC` cunso fi li pa fi'u re
  ##   .i se ki'u bo lo porsi pe `CLL 4.11 step 5` cu so'i roi kalri
  ##   .i ro rafsi poi seltai pa tarmi cu ponse lo mitna'u ta'i lo nu sepli
  ##   .i se ki'u bo lo mitna'u cu so'i roi zasti ji'a
  randomize(0)
  result = newSeqOfCap[seq[seq[string]]](SAMPLES_OPTIONS)
  for _ in 1..SAMPLES_OPTIONS:
    let count = rand(2..5)
    var options = newSeq[seq[string]](count)
    for at in 0..<count:
      for _ in 1..rand(1..4):
        let shape =
          if at == count - 1: FORMS_AS_LAST.sample
          elif rand(1) == 0: Form.Cvc
          else: FORMS_BEFORE_LAST.sample
        options[at].add drawRafsiLetters(shape)
    result.add options


let OPTIONS_DRAWN = drawOptions()
  ## lo cunste be lo te cuxna be'o poi lo jvacipra be lo nu sisku cu tcidu ke'a
  ##   .i le liste cu selcu'a pa roi


iterator optionsDrawn(): lent seq[seq[string]] =
  ## dunda ro cunste be lo te cuxna gi'e fukpi no da
  for i in 0..<OPTIONS_DRAWN.len: yield OPTIONS_DRAWN[i]


func isBrokenFirst(text: string): bool =
  ## jdice lo du'u le valsi cu vasru `y` noi `CLL 4.11 step 5` punji ke'a lo pamoi te jorne
  ##   .i lo pamoi rafsi cu seltai `CVC`
  ##   .i `y` se lidne le rafsi
  ##   .i `CLL 4.11 step 4b` na punji `y` bu'u le terjo'e ki'u lo nu le zunsna remei cu selcru gi'e
  ##       zbasu no zunsna cimei poi se to'e curmi
  let reading = text.readWord
  if not reading.is_word or reading.pieces.len < 2: return false
  let
    (first, second) = (reading.pieces[0], reading.pieces[1])
    (a, b) = (first.rafsi[^1], second.rafsi[0])
  first.form == Form.Cvc and first.hyphen == Hyphen.Y and isPairPermissible(a, b) and
      (not second.rafsi[1].isConsonant or isTriplePermissible(a, b, second.rafsi[1]))


func partNamed(rafsi: string): Part =
  ## facki lo pagbu poi lo rafsi cu sinxa ke'a ku'o gi'e na pilno le tcidu
  ##   .i lo cmarafsi cu sinxa lo valsi ja'i lo liste be lo cmarafsi
  ##   .i lo rafsi poi vasru vo lerfu cu sinxa lo gismu poi le rafsi cu jicmu ke'a va'o lo nu le
  ##       rafsi cu jicmu pa gismu po'o
  ##   .i lo rafsi poi vasru mu lerfu cu sinxa vo'a to `CLL 4.6` toi
  ##   .i va'o lo drata le pagbu cu ralte lo lerfu
  let found =
    case rafsi.form.get
    of Form.Cvc, Form.Ccv, Form.Cvv: rafsi.wordRafsi
    of Form.Cvcc, Form.Ccvc:
      if rafsi.wordsStem.len == 1: some(rafsi.wordsStem[0]) else: none(Word)
    of Form.Cvccv, Form.Ccvcv: rafsi.word
  if found.isSome: found.get.toPart else: unlisted(rafsi)


func isShapeBrivla(text: string): bool =
  ## jdice lo du'u lo selci'a cu seltai lo tarmi poi `CLL 4.3` dunda ke'a lo brivla kei gi'e na
  ##     pilno le tcidu
  ##   .i le tarmi cu nitcu lo nu lo romoi lerfu cu karsna .e lo nu lo zunsna remei cu zvati le mu
  ##       lerfu poi krasi
  ##   .i `y` .e zoi gy. ' .gy. na se kancu
  var head = ""
  for c in text:
    if c notin {'y', '\''} and head.len < 5: head.add c
  let is_pair = toSeq(1 ..< head.len).anyIt(
    head[it - 1] in CONSONANTS_LETTERS and head[it] in CONSONANTS_LETTERS
  )
  text[^1] in "aeiou" and is_pair


func isShapeGismu(text: string): bool =
  ## jdice lo du'u lo selci'a cu seltai lo tarmi be lo gismu ja'i lo du'u ro lerfu cu zunsna ja
  ##     karsna kei po'o
  ##   .i le tarmi cu du `CVCCV` .a `CCVCV` to `CLL 4.4` toi
  var shape = ""
  for c in text: shape.add(if c in "aeiou": 'V' else: 'C')
  shape in ["CVCCV", "CCVCV"]


func isBrokenUp(text: string): bool =
  ## jdice lo du'u lo selci'a cu vasru zo la .a zo doi vu'o poi krasi le selci'a gi'a se lidne no
  ##     zunsna
  ##   .i la'e di'u fendi lo cmene to `CLL 4.8` toi
  for i in 0 ..< text.len:
    if i > 0 and text[i - 1] in CONSONANTS_LETTERS: continue
    if text.continuesWith("la", i) or text.continuesWith("doi", i): return true
  false


proc drawTanru(): seq[Tanru] =
  ## zbasu lo cuntau
  ##   .i lo te kancu be le tanru cu du `SAMPLES`
  ##   .i lo te kancu be lo gismu pe ro tanru cu cmima li pa bi'o li vo
  ##   .i lo tsiju cu jdice le tanru
  ##   .i ro gismu cu selcu'a fi lo'i ro gismu pe le liste
  randomize(0)
  for _ in 1 .. SAMPLES:
    result.add Tanru(parts: newSeqWith(rand(1 .. 4), WORDS_GISMU[rand(WORDS_GISMU.high)].toPart))


let TANRU_RANDOM = drawTanru()
  ## lo cuntau poi ro jvacipra cu tcidu ke'a
  ##   .i le tanru cu selcu'a pa roi


iterator tanruRandom(): lent Tanru =
  ## dunda ro cuntau pe le sorcu gi'e fukpi no da
  for i in 0 ..< TANRU_RANDOM.len: yield TANRU_RANDOM[i]


proc drawTanruCmavo(): seq[Tanru] =
  ## zbasu lo cuntau
  ##   .i lo te kancu be le tanru cu du `SAMPLES_CMAVO`
  ##   .i lo te kancu be lo valsi pe ro tanru cu cmima li pa bi'o `COUNT_WORDS_CMAVO_MAX`
  ##   .i lo tsiju cu jdice le tanru
  ##   .i lo romoi valsi cu gismu
  ##   .i lo nu lo valsi poi na romoi cu cmavo cu cunso fi li pa fi'u ci
  ##   .i va'o lo drata lo nu le valsi cu du zo brodi .a zo brodo .a zo brodu cu cunso fi li pa fi'u
  ##       remu
  ##   .i va'o lo drata le valsi cu gismu
  ##   .i ro valsi cu selcu'a fi ro valsi pe le liste ge'u zi'e poi cmima le mitlei
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


let TANRU_CMAVO = drawTanruCmavo()
  ## lo cuntau poi lo remoi javni cipra be lo nu ciska gi'e xrutcidu cu tcidu ke'a
  ##   .i le tanru cu selcu'a pa roi


iterator tanruCmavo(): lent Tanru =
  ## dunda ro cuntau pe le remoi sorcu gi'e fukpi no da
  ##   .i su'o valsi pe le tanru cu cmavo
  for i in 0 ..< TANRU_CMAVO.len: yield TANRU_CMAVO[i]


iterator textsNotation(notation: string): string =
  ## dunda ro lerpoi pe pa sinxa poi selci'a sepi'o `C` .e `V` ja'i `CLL 4.1`
  ##   .i lo romoi stuzi cu traji lo ka sutcne
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
  ## lo cunpoi be lo rafsi be'o poi lo jvacipra be lo tarmi cu tcidu ke'a
  ##   .i le porsi cu selzba lo lerfu pa roi to `rafsi_random.nim` toi


iterator lujvoForms(): lent seq[string] =
  ## dunda ro cunpoi be lo rafsi be'o pe le sorcu be lo tarmi gi'e fukpi no da
  for i in 0 ..< SEQUENCES_FORMS.len: yield SEQUENCES_FORMS[i]



suite "Chapter 3":
  test "Section 3.1":
    var alphabet: set[char]
    for c in ALPHABET: alphabet.incl c
    # le liste pe `CLL 3.1`
    #   .i slaka bu .e denpa bu cu fendi lo slaka to `CLL 3.3` toi
    check tanru.LETTERS == alphabet - {',', '.'}  # `CLL 3.1`
    for c in 'a' .. 'z':
      # `CLL 3.1` cusku zoi gy. omitting "h", "q", and "w" .gy.
      check (c in tanru.LETTERS) == (c notin {'h', 'q', 'w'})  # `CLL 3.1`
    # ro lo remuxa stuzi
    #   .i lo sinxa be lo porsi be lo valsi cu se cipra ne'i `Internal: Reading`
    for c in char.low .. char.high:
      if c in tanru.LETTERS or c in MARKS_STREAM: continue
      # ja'i lo lerste pe `CLL 3.1`
      check ("bri" & c & "vla").refusalRead == some((Refusal.Letter, $c))  # `CLL 3.1`


  test "Section 3.3":
    # ja'i `CLL 3.3` `h` na sinxa `'`
    #   .i le valsi cu selzba
    check "rohinreho".refusalRead == some((Refusal.Letter, "h"))  # `CLL 3.3`
    # ja'i `CLL 3.3` `h` na sinxa `'`
    #   .i le valsi cu selzba
    check "kixtaha".refusalRead == some((Refusal.Letter, "h"))  # `CLL 3.3`
    # ja'i `CLL 3.3` denpa bu cu zbasu re valsi
    check "bri.vla".refusalRead == some((Refusal.Stream, "."))  # `CLL 3.3`
    # ro selci'avla pe `CLL` ge'u zi'e poi le cipra cu sitna ke'a
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):
      for i in 1 ..< spelling.len:  # ro stuzi ne'i le valsi
        let (head, tail) = (spelling[0 ..< i], spelling[i .. ^1])
        check (head & "." & tail).refusalRead ==
            # ja'i `CLL 3.3` denpa bu poi selvau le valsi cu zbasu re valsi
            some((Refusal.Stream, "."))  # `CLL 3.3`
    for text in ["'a", "a'", "zba'", "kla'ma", "bri''a"]:  # le selci'a cu selzba
      # ja'i `CLL 3.3` zoi gy. ' .gy. jorne lo karsna
      check text.refusalRead == some((Refusal.Apostrophe, ""))  # `CLL 3.3`



suite "Chapter 4":
  test "Section 4.2":
    for text in ["a", "e", "i", "o", "u", "ba", "ce", "di", "fo", "gu"]:
      # ja'i `CLL 4.2` lo tarmi po'u `V` .e `CV`
      #   .i lo denpa cu na selci'a
      check text.kindRead == some(Kind.Cmavo)  # `CLL 4.2`
    for text in ["au", "ei", "ia", "o'u", "u'e", "ki'a", "pei", "mi'o", "coi", "cu'u"]:
      check text.kindRead == some(Kind.Cmavo)  # ja'i `CLL 4.2` lo tarmi po'u `VV` .e `CVV`
    for text in ["ku'a'e", "sau'e", "bai'ai", "ki'e'u'e"]:
      check text.kindRead == some(Kind.Cmavo)  # ja'i `CLL 4.2` lo cipma'o mu'u `Example 4.4`
    # `CLL 4.2` .e `CLL 17.2`
    check "y".kindRead == some(Kind.Cmavo) and "by".kindRead == some(Kind.Cmavo)  # `CLL 4.2`
    # ja'i `CLL 4.2` no liste cu dunda lo rafsi zo lo
    check "lo".tanruRead == some(Tanru(parts: @[unlisted("lo")]))  # `CLL 4.2`
    # ja'i `CLL 4.2` le gimste cu vasru le cmavo ki'u lo rafsi be le cmavo
    check "se".tanruRead == some(toTanru("se"))  # `CLL 4.2`
    # ja'i `CLL 20` zo lo cmima `LE`
    #   .i le ma'oste cu vasru zo lo
    check "lo".readWord.selmaho == some(Selmaho.Le)  # `CLL 20`
    check "se".readWord.selmaho == some(Selmaho.Se)  # ja'i `CLL 20` zo se cmima `SE`
    # ja'i `CLL 4.2` le cmavo cu cipma'o
    #   .i se ki'u bo no liste cu vasru le cmavo
    check "ku'a'e".readWord.selmaho.isNone  # `CLL 4.2`
    check "klama".readWord.selmaho.isNone  # ja'i `CLL 4.3` no brivla cu ponse lo selma'o
    # lo rafsi po'u `kau` sinxa zo kampu
    #   .i le rafsi na sinxa lo cmavo
    #   .i le valsi cu selzba
    check "kauzba".readWord.selmaho.isNone  # lo rafsi po'u `kau` sinxa zo kampu
    for text in ["iseci'i", "punaijecanai", "da'amei"]:
      # ja'i `CLL 4.2` mu'u `Examples 4.1-2`
      #   .i ja'i `CLL 4.3` lo ma'orgunma
      check text.refusalRead == some((Refusal.Stream, ""))  # `CLL 4.2`
    # ja'i `CLL 4.2` mu'u `Example 4.3`
    #   .i denpa bu cu sinxa lo denpa
    check "ki'e.u'e".refusalRead == some((Refusal.Stream, "."))  # `CLL 4.2`


  test "Section 4.3":
    check "lojban".kindRead == some(Kind.Cmene)  # ja'i `CLL 4.3` zo lojban. cmene
    # `CLL 4.3` cusku zoi gy. must be compound cmavo .gy.
    check "da'amei".refusalRead == some((Refusal.Stream, ""))  # `CLL 4.3`
    # ja'i `CLL 4.3` lo zunsna remei po'u `sc` se kancu ta'i lo nu `y` na se kancu
    #   .i se ki'u bo le valsi cu brivla
    #   .i le valsi cu selzba
    check "bisycla".kindRead.isSome  # `CLL 4.3`
    for text in ["zba", "brai"]:  # le selci'a cu selzba
      # ja'i `CLL 4.3` lo nu basna lo slaka poi lidne lo romoi slaka cu nitcu su'o re slaka
      check text.refusalRead == some((Refusal.Shape, ""))  # `CLL 4.3`
    # ja'i `CLL 4.3` ro brivla cu selfa'o lo karsna
    #   .i le valsi cu selzba
    check "bridy".refusalRead == some((Refusal.Shape, ""))  # `CLL 4.3`


  test "Section 4.4":
    for text in ["creka", "lijda", "blanu", "mamta", "cukta", "patfu", "nanmu", "ninmu"]:
      check text.kindRead == some(Kind.Gismu)  # ja'i `CLL 4.4` mu'u `Examples 4.11-18`
      # ja'i `CLL 4.4` lo gismu pe lo liste cu sinxa vo'a
      check text.tanruRead == some(toTanru(text))  # `CLL 4.4`
    for text in ["kismu", "xismu", "gicmu", "gizmu", "gisnu"]:
      # ja'i `CLL 4.4` lo tarmi be lo gismu
      #   .i ku'i no liste cu vasru le valsi
      check text.kindRead == some(Kind.Gismu)  # `CLL 4.4`
      # ja'i `CLL 4.4` no smuni cu seldu'a
      check text.tanruRead == some(Tanru(parts: @[unlisted(text)]))  # `CLL 4.4`


  test "Section 4.5":
    for spelling in ["brivla", "brivalsi", "bridyvla", "bridyvalsi"]:
      # ja'i `CLL 4.5` vo selci'avla cu sinxa pa lujvo
      check spelling.tanruRead == some(toTanru("bridi+valsi"))  # `CLL 4.5`
      check spelling.kindRead == some(Kind.Lujvo)  # ja'i `CLL 4.5` le valsi cu lujvo
    # ja'i `CLL 4.5` `Example 4.25` selzba `Example 4.22`
    check "mampa'u".tanruRead == some(toTanru("mamta+patfu"))  # `CLL 4.5`
    # `CLL 4.5` cusku zoi gy. mam- .gy. .e zoi gy. -pa'u .gy.
    check "mampa'u".readWord.pieces.mapIt(it.rafsi) == @["mam", "pa'u"]  # `CLL 4.5`
    check "soirsai".tanruRead == some(toTanru("sonci+sanmi"))  # ja'i `CLL 4.5` mu'u `Example 4.26`
    # ja'i `CLL 4.5` mu'u `Example 4.26`
    #   .i `r` zvati lo jbini be le re rafsi
    check "soirsai".readWord.pieces.spelled == "soirsai"  # `CLL 4.5`
    # ja'i `CLL 4.5` mu'u `Example 4.26`
    #   .i lo minle'u po'u `r`
    check "soirsai".readWord.pieces[0].hyphen == Hyphen.R  # `CLL 4.5`
    # ja'i `CLL 4.5` `Example 4.23` selzba `Example 4.19`
    check "sampli".tanruRead == some(toTanru("skami+pilno"))  # `CLL 4.5`
    # ja'i `CLL 4.5` `Example 4.24` selzba `Example 4.20`
    check "bralo'i".tanruRead == some(toTanru("barda+bloti"))  # `CLL 4.5`
    let (paternal, maternal) = (toTanru("patfu+mamta"), toTanru("mamta+patfu"))
    # ja'i `CLL 4.5` lo rafsi cu seljo'e ta'i lo porsi pe le tanru
    check ($paternal).tanruRead == some(paternal)  # `CLL 4.5`
    # ja'i `CLL 4.5` lo rafsi cu seljo'e ta'i lo porsi pe le tanru
    check ($maternal).tanruRead == some(maternal)  # `CLL 4.5`
    # ja'i `CLL 4.5` le pamoi cu galfi le remoi
    #   .i se ki'u bo lo porsi cu selra'e
    check $paternal != $maternal  # `CLL 4.5`


  test "Section 4.6":
    for spelling in ["zunlyjamfu", "zunlyjma", "zuljamfu", "zuljma"]:
      # `CLL 4.6` cusku zoi gy. legitimate and equivalent .gy.
      check spelling.tanruRead == some(toTanru("zunle+jamfu"))  # `CLL 4.6`
    check $toTanru("zunle+jamfu") == "zuljma"  # ja'i `CLL 4.6` zo zuljma selnei
    for (spelling, text_tanru) in [
      ("mamtypatfu", "mamta+patfu"), ("lerfyliste", "lerfu+liste"),
      ("nancyprali", "nanca+prali"), ("prunyplipe", "pruni+plipe"),
      ("vancysanmi", "vanci+sanmi"),
    ]:
      let pieces = spelling.readWord.pieces
      # ja'i `CLL 4.6` mu'u `Example 4.27-31`
      #   .i le lujvo cu na jdika
      check spelling.tanruRead == some(toTanru(text_tanru))  # `CLL 4.6`
      # ja'i `CLL 4.6` lo clani rafsi po'o
      check pieces.allIt(it.form in FORMS_UNREDUCED + FORMS_GISMU)  # `CLL 4.6`
    for (spelling, text_tanru) in [
      ("cumfri", "cumki+lifri"), ("klezba", "klesi+zbasu"), ("kixta'a", "krixa+tavla"),
      ("sniju'o", "sinxa+djuno"), ("mampa'u", "mamta+patfu"), ("lerste", "lerfu+liste"),
    ]:
      let pieces = spelling.readWord.pieces
      # ja'i `CLL 4.6` mu'u `Example 4.32-37`
      #   .i le lujvo cu muljdika
      check spelling.tanruRead == some(toTanru(text_tanru))  # `CLL 4.6`
      # `CLL 4.6` cusku zoi gy. made up solely of short rafsi .gy.
      check pieces.allIt(it.form in FORMS_SHORT)  # `CLL 4.6`
    # ja'i `CLL 4.6` `Example 4.36` tortai be `Example 4.27`
    check "mamtypatfu".tanruRead == "mampa'u".tanruRead  # `CLL 4.6`
    # ja'i `CLL 4.6` `Example 4.37` tortai be `Example 4.28`
    check "lerfyliste".tanruRead == "lerste".tanruRead  # `CLL 4.6`
    # `CLL 4.6` cusku zoi gy. must be patyta'a .gy.
    check "patyta'a".tanruRead == some(toTanru("pante+tavla"))  # `CLL 4.6`
    # ja'i `CLL 4.6` `tt` na selcru
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # `CLL 4.6`
    # `CLL 4.6` cusku zoi gy. mudysiclu must be used .gy.
    check "mudysiclu".tanruRead == some(toTanru("mudri+siclu"))  # `CLL 4.6`
    # ja'i `CLL 4.6` le valsi na ka'e selzba
    check "mudsiclu".refusalRead == some((Refusal.Hyphen, "mudysiclu"))  # `CLL 4.6`
    # ja'i `CLL 4.6` lo lerjo'e po'u `n` seltcu
    check "ro'inre'o".tanruRead == some(toTanru("rokci+renro"))  # `CLL 4.6`
    # ja'i `CLL 4.6` le lujvo cu mintu
    #   .i le valsi cu vasru no lerjo'e
    check "rokre'o".tanruRead == some(toTanru("rokci+renro"))  # `CLL 4.6`
    # `CLL 4.6` cusku zoi gy. breaks up into two cmavo .gy.
    check "ro'ire'o".refusalRead == some((Refusal.Stream, ""))  # `CLL 4.6`
    # ja'i `CLL 4.6` `rr` du re `r`
    check "ro'irre'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # `CLL 4.6`
    # `CLL 4.6` cusku zoi gy. whiter .gy.
    #   .i lo nu fendi cu selru'a
    check "labmau".tanruRead == some(toTanru("blabi+zmadu"))  # `CLL 4.6`


  test "Section 4.7":
    for text in ["spageti", "cidjrspageti", "djarspageti"]:
      check text.kindRead == some(Kind.Fuhivla)  # ja'i `CLL 4.7` mu'u `Example 4.46`
    for text in ["tricrxaceru", "ricrxaceru", "saktrxaceru"]:
      # ja'i `CLL 4.7` mu'u `Example 4.47` .e zoi gy. maple sugar .gy.
      check text.kindRead == some(Kind.Fuhivla)  # `CLL 4.7`
    for text in ["cirlrbri", "sincrkobra", "saskrkuarka", "lerfrdjamo", "lerldjamo"]:
      check text.kindRead == some(Kind.Fuhivla)  # ja'i `CLL 4.7` mu'u `Examples 4.48-51`
    for text in ["kulnrblgaria", "gugdrblgaria", "bangrblgaria", "bangrkorea", "kulnrkorea"]:
      check text.kindRead == some(Kind.Fuhivla)  # ja'i `CLL 4.7` mu'u `Examples 4.52-56`
    for text in ["kuarka", "integrale", "cmacrntegrale", "cmacrnintegrale", "dinjrnintegrale"]:
      # `CLL 4.7` cusku zoi gy. valid Stage 4 fu'ivla .gy.
      #   .i lo tadji be lo nu jmina pa krapau
      check text.kindRead == some(Kind.Fuhivla)  # `CLL 4.7`
    # ja'i `CLL 4.7` zoi gy. integral .gy. ta'i lo di'uzba
    check "tarmrnintegrale".kindRead == some(Kind.Fuhivla)  # `CLL 4.7`
    # `CLL 4.7` cusku zoi gy. spraile is acceptable .gy.
    check "spraile".kindRead == some(Kind.Fuhivla)  # `CLL 4.7`
    # `CLL 4.7` cusku zoi gy. but not ktraile .gy.
    check "ktraile".refusalRead == some((Refusal.Cluster, "ktr"))  # `CLL 4.7`
    # `CLL 4.7` cusku zoi gy. or trkaile .gy.
    check "trkaile".refusalRead == some((Refusal.Cluster, "trk"))  # `CLL 4.7`
    # `CLL 4.7` cusku zoi gy. forbidden cluster .gy.
    check "lerndjamo".refusalRead == some((Refusal.Cluster, "ndj"))  # `CLL 4.7`
    # `CLL 4.7` cusku zoi gy. looks like compound cmavo .gy.
    check "xaceru".refusalRead == some((Refusal.Stream, ""))  # `CLL 4.7`
    check "kobra".kindRead == some(Kind.Gismu)  # ja'i `CLL 4.7` zo kobra simsa lo gismu
    # ja'i `CLL 4.7` lo cipra po'u zoi gy. slinku'i test .gy.
    check "slinku'i".refusalRead == some((Refusal.Slinkuhi, "baslinku'i"))  # `CLL 4.7`
    # `CLL 4.7`
    #   .i le valsi cu selzba
    check "mibroda".refusalRead == some((Refusal.Combination, "mi broda"))  # `CLL 4.7`


  test "Section 4.8":
    for text in ["djim", "djein", "arnold", "pit", "katrinas", "katrin", "katis", "keit"]:
      check text.kindRead == some(Kind.Cmene)  # ja'i `CLL 4.8` mu'u `Examples 4.57-64`
    for text in ["djan", "braun", "djanbraun", "pav", "sol", "ralj", "nol"]:
      check text.kindRead == some(Kind.Cmene)  # ja'i `CLL 4.8` mu'u `Examples 4.65-70`
    for text in ["meris", "maris", "meiris", "merix", "marys"]:
      # ja'i `CLL 4.8` zoi gy. Mary .gy. cu ka'e jbobi'o le vi cmene
      check text.kindRead == some(Kind.Cmene)  # `CLL 4.8`
    for text in [
      "smit", "djonz", "jan", "djon", "jon", "alis", "elis", "djansn", "uiliam", "tcarlz", "carl",
      "dygol", "xainrix", "xuakin", "sfietlanys", "xructcof", "kricnas", "lex", "vauensas", "don",
      "kicotes", "kixotes", "ki'otes", "maudzydyn", "fudjikos", "fujikos",
    ]:
      # ja'i `CLL 4.8` lo liste be lo cmene poi pu jbobi'o
      check text.kindRead == some(Kind.Cmene)  # `CLL 4.8`
    # `CLL 4.8` cusku zoi gy. invalid name laplas. .gy.
    check "laplas".refusalRead == some((Refusal.Breakup, "la"))  # `CLL 4.8`
    # ja'i `CLL 4.8` le selci'a cu simsa lo'u .i la nas. le'u
    check "ilanas".refusalRead == some((Refusal.Breakup, "la"))  # `CLL 4.8`
    # ja'i `CLL 4.8` lo zunsna cu lidne zo la
    #   .i le valsi cu vasru `nts`
    check "nederlants".kindRead == some(Kind.Cmene)  # `CLL 4.8`
    # ja'i `CLL 4.8` lo zunsna remei po'o
    #   .i `Example 1.1` pe `CLL 1997` selvi'u
    check "djandjonz".kindRead == some(Kind.Cmene)  # `CLL 4.8`
    # ja'i `CLL 4.8` zo la pamoi
    #   .i le valsi cu selzba
    check "lars".refusalRead == some((Refusal.Breakup, "la"))  # `CLL 4.8`
    # ja'i `CLL 3.6` `Example 3.8` to'e curmi le zunsna remei
    check "djeimz".refusalRead == some((Refusal.Cluster, "mz"))  # `CLL 3.6`
    # `CLL 3.6` .e `Example 3.8` cusku zoi gy. y can be inserted .gy.
    check "djeimyz".kindRead == some(Kind.Cmene)  # `CLL 3.6`
    for text in ["rl", "brlgan"]:
      # ja'i `CLL 3.4` lo zunsna poi slaka mu'u zo rl. .e `Example 3.5`
      check text.kindRead == some(Kind.Cmene)  # `CLL 3.4`
    # ja'i `CLL 3.4` le valsi cu vasru no slaka
    #   .i le valsi cu selzba
    check "c".refusalRead == some((Refusal.Shape, ""))  # `CLL 3.4`


  test "Section 4.12-13":
    for (spelling, value) in [
      ("gerzda", 5878), ("gerzdani", 7917), ("ge'uzda", 6367), ("ge'urzdani", 9506),
      ("gerkyzda", 8008), ("gerkyzdani", 10047),
    ]:
      # ja'i `CLL 4.13` pa lujvo cu ponse xa tarmi
      check spelling.tanruRead == some(toTanru("gerku+zdani"))  # `CLL 4.13`
      # ja'i `CLL 4.13` lo namcu
      #   .i `CLL 4.13` sresku `V` pe zo gerzda
      #   .i li mubizebi cu selra'e
      check spelling.scoreRead == some(value)  # `CLL 4.13`
    # `CLL 4.13` cusku zoi gy. would probably appear ... gerzda .gy.
    check $toTanru("gerku+zdani") == "gerzda"  # `CLL 4.13`
    for (spelling, value) in [
      ("lotkle", 5878), ("blokle", 5858), ("lo'ikle", 6367), ("lotlei", 5867),
      ("blolei", 5847), ("lo'irlei", 7456),
    ]:
      let is_hyphenated = spelling.readWord.pieces.anyIt(it.hyphen != Hyphen.None)
      # `CLL 4.13` cusku zoi gy. all six forms are valid .gy.
      check spelling.tanruRead == some(toTanru("bloti+klesi"))  # `CLL 4.13`
      # ja'i `CLL 4.13` lo liste be lo namcu pe lo'u bloti klesi le'u
      check spelling.scoreRead == some(value)  # `CLL 4.13`
      # `CLL 4.13` cusku zoi gy. only lo'irlei requires hyphenation .gy.
      check is_hyphenated == (spelling == "lo'irlei")  # `CLL 4.13`
    # `CLL 4.13` cusku zoi gy. blolei is preferred .gy.
    check $toTanru("bloti+klesi") == "blolei"  # `CLL 4.13`
    for spelling in [
      "lojbangri", "lojbaugri", "lojbangygri", "logjybangri", "logjybaugri", "logjybangygri",
      "lojbangirzu", "lojbaugirzu", "lojbangygirzu", "logjybangirzu", "logjybaugirzu",
      "logjybangygirzu",
    ]:
      check spelling.tanruRead == some(toTanru("logji+bangu+girzu"))  # ja'i `CLL 4.13` pare cumki
      check spelling.readWord.pieces.allIt(it.form in FORMS_SHORT) ==
          # `CLL 4.13` cusku zoi gy. only fully reduced lujvo forms .gy.
          (spelling in ["lojbangri", "lojbaugri"])  # `CLL 4.13`
    check "lojbangri".scoreRead == some(8827)  # `CLL 4.13` cusku zoi gy. 8827 versus 8796 .gy.
    check "lojbaugri".scoreRead == some(8796)  # `CLL 4.13` cusku zoi gy. 8827 versus 8796 .gy.
    # ja'i `CLL 4.13` le romoi cu ponse lo mecna'u
    check $toTanru("logji+bangu+girzu") == "lojbaugri"  # `CLL 4.13`
    check "zbasai".scoreRead == some(5847)  # ja'i `CLL 4.12` mu'u `Example 4.71`
    # `CLL 4.12` .e `Example 4.72` cusku zoi gy. nun + y + nau .gy.
    check ["nun", "nau"].toPieces.spelled == "nunynau"  # `CLL 4.12`
    check lujvo.score(["nun", "nau"].toPieces) == 6967  # ja'i `CLL 4.12` mu'u `Example 4.72`
    check "sairzbata'u".scoreRead == some(10385)  # ja'i `CLL 4.12` mu'u `Example 4.73`
    check "zbazbasysarji".scoreRead == some(12976)  # ja'i `CLL 4.12` mu'u `Example 4.74`



suite "Internal: Reading":
  test "Empty text is refused as Empty":
    # le tcila cu kunti
    check "".refusalRead == some((Refusal.Empty, ""))  # le selci'a cu kunti


  test "Character outside letters is refused as Letter, naming character":
    # le pamoi lerfu poi srera
    #   .i le valsi cu selzba
    check "hello".refusalRead == some((Refusal.Letter, "h"))  # le pamoi lerfu poi srera
    # `w` na cmima le lerfu
    #   .i le valsi cu selzba
    check "bwa".refusalRead == some((Refusal.Letter, "w"))  # `w` na cmima le lerfu
    # lo selci'a poi sinxa lo tanru cu na selci'avla
    check "datni+vreji".refusalRead == some((Refusal.Letter, "+"))  # lo tanru na selci'avla
    # lo brale'u poi no jbole'u cu ponse ke'a to `CLL 3.1` toi
    check "brivlaH".refusalRead == some((Refusal.Letter, "H"))  # `CLL 3.1`


  test "Character outside letters is named whole, so detail of UTF-8 stays UTF-8":
    check "café".refusalRead ==
        # lo nu lanli de'i `2026-10-29` cu facki `logic-6`
        #   .i lo pu tcila cu du lo stuzi po'u `C3`
        some((Refusal.Letter, "é"))  # lo nu lanli de'i `2026-10-29` cu facki `logic-6`
    check "ci’a".refusalRead ==
        # lo nu lanli de'i `2026-10-29` cu facki `logic-6`
        #   .i lo pu tcila cu du lo stuzi po'u `E2`
        some((Refusal.Letter, "’"))  # lo nu lanli de'i `2026-10-29` cu facki `logic-6`
    # pavo lerfu
    #   .i lo pamoi .e lo romoi vu'o pe ro te kancu be lo stuzi cu cmima
    for character in CHARACTERS_FOREIGN:
      for text in [character & "brivla", "bri" & character & "vla", "brivla" & character]:
        # le krastu .e lo minstu
        check text.refusalRead == some((Refusal.Letter, character))  # lo krasi ja jmina stuzi
        check text.readWord.detail.validateUtf8 == -1  # le tcila cu dratai bu'u ro stuzi
    randomize(0)
    var count_scalar = 0
    # `SAMPLES_FOREIGN` klani lo cunselcu'a poi lo tsiju cu jdice ke'a
    for _ in 1..SAMPLES_FOREIGN:
      let code =
        case rand(2..4)
        of 2: rand(0x80..0x7FF)
        of 3: rand(0x800..0xFFFF)
        else: rand(0x10000..0x10FFFF)
      # lo me `surrogate` na me `scalar value`
      if code in 0xD800..0xDFFF: continue
      inc count_scalar
      let character = Rune(code).toUTF8
      for text in [character & "brivla", "bri" & character & "vla", "brivla" & character]:
        # le tcila cu mulyle'u bu'u ro me `Unicode plane`
        check text.refusalRead == some((Refusal.Letter, character))  # mulno bu'u ro `plane`
        check text.readWord.detail.validateUtf8 == -1  # le tcila cu dratai bu'u ro stuzi
    check count_scalar >= FLOOR_FOREIGN  # le bandu cu ralte so'e le selcu'a


  test "Mark of stream is refused as Stream, which readStream reads":
    # ja'i `CLL 3.3` lo calyle'u cu fanmo lo valsi
    #   .i le tcidu cu vimcu no calyle'u
    check " brivla".refusalRead == some((Refusal.Stream, " "))  # `CLL 3.3`
    check "brivla\t".refusalRead == some((Refusal.Stream, "\t"))  # lo calyle'u cu fanmo lo valsi
    check "bri vla".refusalRead == some((Refusal.Stream, " "))  # re valsi
    for c in MARKS_STREAM:  # ro sinxa to su'o le sinxa cu calyle'u toi
      check ("bri" & c & "vla").refusalRead == some((Refusal.Stream, $c))  # `CLL 3.3` .e `CLL 3.9`
    # ja'i `CLL 3.9` lo brale'u cu sinxa lo nu basna
    check "BRIVLA".refusalRead == some((Refusal.Stream, "B"))  # `CLL 3.9`
    for c in tanru.LETTERS - {'\''}:  # lo brale'u pe ro lerfu
      check ("bri" & c.toUpperAscii & "vla").refusalRead ==
          # ja'i `CLL 3.9` lo brale'u cu sinxa lo nu basna
          #   .i le tcidu cu galfi no brale'u lo cmale'u
          some((Refusal.Stream, $c.toUpperAscii))  # `CLL 3.9`
    # ro selci'avla pe `CLL` ge'u zi'e poi le cipra cu sitna ke'a
    for spelling in concat(@SPELLINGS_CLL, @SPELLINGS_CLL_REFUSED):
      for i in 0 .. spelling.len:  # ro stuzi to le re fanmo cu cmima toi
        let text = spelling[0 ..< i] & "," & spelling[i .. ^1]
        check text.refusalRead ==
            # ja'i `CLL 3.3` slaka bu cu fendi lo slaka
            #   .i lo porsi be lo valsi cu ralte la'e di'u
            some((Refusal.Stream, ","))  # `CLL 3.3`


  test "Cmavo run together is refused as Stream, which readStream splits":
    # ja'i `CLL 4.2` lo'u ga'i nai le'u
    #   .i le valsi cu selkra `Tatoeba`
    check "ga'inai".refusalRead == some((Refusal.Stream, ""))  # `CLL 4.2`
    # ja'i `CLL 4.2` lo'u so'i mei le'u
    #   .i le valsi cu selkra `Tatoeba`
    check "so'imei".refusalRead == some((Refusal.Stream, ""))  # `CLL 4.2`


  test "Letters of no class, nor cmavo run together, are refused as Shape":
    # ja'i `CLL 3.3` lo zunsna remei cu se lidne lo mumoi lerfu
    #   .i le valsi cu selzba
    check "lonubroda".refusalRead == some((Refusal.Shape, ""))  # `CLL 3.3`
    # ja'i `CLL 3.4` `ia` se lidne lo zunsna
    #   .i le valsi cu selzba
    check "cia".refusalRead == some((Refusal.Shape, ""))  # `CLL 3.4`
    # ja'i `CLL 4.2` `Example 4.3` ciska denpa bu
    check "ki'eu'e".refusalRead == some((Refusal.Shape, ""))  # `CLL 4.2`


  test "Word ending in consonant reads as cmene where its letters admit one":
    for text in ["lojban", "gerk", "xyz", "djan"]:  # zo gerk .e zo xyz selzba
      # ja'i `CLL 4.3` ro cmene cu selfa'o lo zunsna to `CLL 4.8` toi
      check text.kindRead == some(Kind.Cmene)  # `CLL 4.3`


  test "Brivla neither gismu nor lujvo reads as fu'ivla where it meets each rule of 4.7":
    # `CLL 3.8` cusku zoi gy. possible borrowing .gy.
    check "bongnanba".kindRead == some(Kind.Fuhivla)  # `CLL 3.8`
    # ja'i `CLL 4.7` le valsi cu mapti ro javni
    #   .i le valsi cu selzba
    check "brodrzba".kindRead == some(Kind.Fuhivla)  # `CLL 4.7`
    # ja'i `CLL 4.7`
    #   .i ku'i `CLL 4.11` dunda zo ci'ormau
    #   .i le valsi cu selkra `Tatoeba`
    check "ci'onmau".kindRead == some(Kind.Fuhivla)  # `CLL 4.7`
    # ja'i `CLL 4.7` no fu'ivla cu vasru `y`
    #   .i le valsi cu selkra `lujvo.txt`
    check "natmyrgu'e".refusalRead == some((Refusal.Shape, ""))  # `CLL 4.7`


  test "Lujvo ending in rafsi of cmavo reads, its last part that cmavo":
    # ja'i `CLL 4.6` lo rafsi be zo do be'o po'u `doi`
    #   .i le valsi cu selzba
    check "zbadoi".tanruRead == some(toTanru("zbasu+do"))  # `CLL 4.6`
    # ja'i `CLL 4.6` lo rafsi be zo du be'o po'u `du'o`
    #   .i le valsi cu selzba
    check "zbadu'o".tanruRead == some(toTanru("zbasu+du"))  # `CLL 4.6`
    # `CLL 4.11 step 2` dunda no javni poi lo lerfu cu ka'e tcidu ke'a
    check "zbadoi".kindRead == some(Kind.Lujvo)  # `CLL 4.11 step 2`
    # zo co'e fanmo le lujvo
    #   .i le valsi cu selkra `Tatoeba`
    check "nunco'e".tanruRead == some(toTanru("nu+co'e"))  # zo co'e fanmo le lujvo


  test "Lujvo holding rafsi of cmavo reads as tanru keeping cmavo":
    let
      se = "se".word.get.toPart
      ciska = "ciska".word.get.toPart
      selcia = "selci'a".tanruRead
    # ja'i `CLL 4.6` lo rafsi be zo se be'o po'u `sel`
    #   .i le valsi cu selzba
    check selcia == some(Tanru(parts: @[se, ciska]))  # `CLL 4.6`
    # ja'i `CLL 9.4` zo se galfi
    #   .i se ki'u bo le tanru cu ralte zo se
    check selcia.get != Tanru(parts: @[ciska])  # `CLL 9.4`
    # ja'i `CLL 4.12` `sel` .e `ci'a` ponse lo cmaraina'u
    #   .i le valsi cu selzba
    check $selcia.get == "selci'a"  # `CLL 4.12`
    check "nunkla".tanruRead == some(toTanru("nu+klama"))  # `CLL 12.12` cusku zo nunkla
    check "nunynau".tanruRead == some(toTanru("nu+nanmu"))  # ja'i `CLL 4.12` mu'u `Example 4.72`
    let kem = "nakykemcinctu".tanruRead
    # ja'i `CLL 4.13` lo tanru po'u lo'u nakni ke cinse ctuca le'u
    check kem == some(toTanru("nakni+ke+cinse+ctuca"))  # `CLL 4.13`
    # ja'i `CLL 4.13` le tarmi cu traji lo ka tordu gi'e selnei lo nu dunda lo namcu
    check $kem.get == "nakykemcinctu"  # `CLL 4.13`


  test "Gismu shape outside list reads as gismu, its part keeping letters":
    # `CLL 4.4`
    #   .i le valsi cu selzba
    check "kukta".tanruRead == some(Tanru(parts: @[unlisted("kukta")]))  # `CLL 4.4`
    # ja'i `CLL 4.4` le valsi cu vasru mu lerfu gi'e seltai `CVC/CV`
    check "kukta".kindRead == some(Kind.Gismu)  # `CLL 4.4`
    check "gerkukta".tanruRead ==
        # zo kukta romoi
        #   .i le valsi cu selzba
        some(Tanru(parts: @["gerku".word.get.toPart, unlisted("kukta")]))  # zo kukta romoi


  test "Rafsi no list assigns reads, its part keeping letters":
    check "clozba".tanruRead ==
        # lo tarmi po'u `CCV`
        #   .i le valsi cu selzba
        some(Tanru(parts: @[unlisted("clo"), "zbasu".word.get.toPart]))  # lo tarmi po'u `CCV`
    check "kukfyzba".tanruRead ==
        # lo rafsi poi vasru vo lerfu
        #   .i le valsi cu selzba
        some(Tanru(parts: @[unlisted("kukf"), "zbasu".word.get.toPart]))  # vo lerfu to selzba toi
    check "ditybra".tanruRead ==
        # `dit`
        #   .i le valsi cu selkra `Tatoeba`
        some(Tanru(parts: @[unlisted("dit"), "barda".word.get.toPart]))  # `dit`


  test "Shared 4-letter rafsi reads, its part naming no one gismu":
    check "brodyzba".tanruRead ==
        # mu gismu cu ponse le rafsi
        #   .i le valsi cu selzba
        some(Tanru(parts: @[unlisted("brod"), "zbasu".word.get.toPart]))  # mu gismu to selzba toi
    check "brodyprenu".tanruRead ==
        # mu gismu cu ponse le rafsi
        #   .i le valsi cu selzba
        some(Tanru(parts: @[unlisted("brod"), "prenu".word.get.toPart]))  # mu gismu to selzba toi
    # pa gismu po'o cu ponse `rod`
    #   .i le valsi cu selzba
    check "rodzba".tanruRead == some(toTanru("broda+zbasu"))  # pa gismu po'o cu ponse `rod`


  test "Hyphen 4.11 does not give is refused as Hyphen, naming form 4.11 gives":
    # `y` claxu
    #   .i le valsi cu selkra `CLL 4.6`
    check "patta'a".refusalRead == some((Refusal.Hyphen, "patyta'a"))  # `CLL 4.6`
    # `y` dukse
    #   .i le valsi cu selzba
    check "kitymatci".refusalRead == some((Refusal.Hyphen, "kitmatci"))  # `y` dukse
    # `y` pe lo cipra pe zoi gy. tosmabru .gy.
    #   .i le valsi cu selzba
    check "kicmatci".refusalRead == some((Refusal.Hyphen, "kicymatci"))  # `tosmabru y`
    # `n` .enai `r`
    #   .i le valsi cu selkra `CLL 4.6`
    check "ro'irre'o".refusalRead == some((Refusal.Hyphen, "ro'inre'o"))  # `CLL 4.6`
    # lo kabmupli
    #   .i lo zunsna cu fanmo le valsi
    #   .i le valsi cu selzba
    check "clozbas".kindRead == some(Kind.Cmene)  # lo kabmupli


  test "Each class reads by its letters, whether list holds word or not":
    for (text, kind, is_listed) in [
      ("klama", Kind.Gismu, true), ("kukta", Kind.Gismu, false),
      ("se", Kind.Cmavo, true), ("lo", Kind.Cmavo, false),
      ("bridyvalsi", Kind.Lujvo, true), ("clozba", Kind.Lujvo, false),
    ]:
      let reading = text.readWord
      check reading.is_word and reading.kind == kind  # ja'i `CLL 4.1` lo lerfu cu jdice lo klesi
      # lo liste cu dunda lo cmene gi'e no roi jdice
      check reading.tanru.parts.allIt(it.is_listed) == is_listed  # lo liste no roi jdice


  test "Pieces spell text, hyphens included; word read whole has none":
    # ro selci'avla pe `CLL` ge'u zi'e poi le cipra cu sitna ke'a zi'e poi se tcidu
    for spelling in SPELLINGS_CLL:
      let reading = spelling.readWord
      check reading.is_word and reading.pieces.spelled == spelling  # lo nu fendi ce'o lo nu ciska
    for text in ["gerku", "kukta", "se", "lo"]:
      # lo gismu .e lo cmavo cu mulseltcidu
      #   .iju lo liste cu vasru le valsi
      check text.readWord.pieces.len == 0  # mulseltcidu



suite "Internal: Laws":
  test "Rendered tanru reads back as itself, shared brod as part brod":
    var count_shared = 0
    for tanru in tanruRandom():  # `SAMPLES` klani lo tanru poi lo tsiju cu jdice ke'a
      if tanru.isStemShared: inc count_shared
      # lo nu ciska gi'e xrutcidu
      #   .i `brod` sinxa no da
      check ($tanru).tanruRead == some(tanru.withStemShared)  # lo nu ciska gi'e xrutcidu
    # le bandu cu zgana lo jicmu poi selpo'e su'o re gismu
    check count_shared >= FLOOR_SHARED_ROUND  # le bandu cu zgana lo kancmu
    for word in GISMU_STEM_SHARED:
      let shared = toTanru(word & "+zbasu")
      check $shared == "brodyzba"  # `brod` po'o lidne le romoi gismu
      check ($shared).tanruRead ==
          # lo selxrutcidu cu vasru `brod`
          some(Tanru(parts: @[unlisted("brod"), "zbasu".word.get.toPart]))  # xrutcidu `brod`
      # le romoi gismu cu mulselci'a
      check ($toTanru("zbasu+" & word)).tanruRead == some(toTanru("zbasu+" & word))  # romoi mulno


  test "Rendered tanru of up to six words, cmavo among them, reads back as itself, brod aside":
    var (count_cmavo, count_shared) = (0, 0)
    for tanru in tanruCmavo():  # `SAMPLES_CMAVO` klani lo tanru poi lo tsiju cu jdice ke'a
      if tanru.parts.anyIt(it.word.kind == Kind.Cmavo): inc count_cmavo
      if tanru.isStemShared: inc count_shared
      # ja'i `CLL 4.12` le tarmi cu se xruti tcidu to `CLL 4.6` toi
      check ($tanru).tanruRead == some(tanru.withStemShared)  # `CLL 4.12`
    check count_cmavo >= FLOOR_CMAVO  # lo se cipra cu so'i roi vasru lo cmavo
    check count_shared >= FLOOR_SHARED  # lo se cipra cu so'i roi vasru `brod` gi'e banzu


  test "Every gismu renders and reads back in head and in final position":
    for w in WORDS_GISMU:  # ro lo pacivore gismu
      let
        head = Tanru(parts: @[w.toPart, "zdani".word.get.toPart])
        final = Tanru(parts: @["gerku".word.get.toPart, w.toPart])
      # lo nu ciska gi'e xrutcidu
      #   .i le gismu cu pamoi
      check ($head).tanruRead == some(head.withStemShared)  # lo nu ciska gi'e xrutcidu
      # le gismu cu romoi
      check ($final).tanruRead == some(final)  # lo nu ciska gi'e xrutcidu


  test "Every short rafsi of list reads as its word, before gismu and after":
    let zbasu = "zbasu".word.get.toPart
    for w in WORDS_GISMU:  # ro lo pacivore gismu .e ro cmarafsi
      let (head, final) = (Tanru(parts: @[w.toPart, zbasu]), Tanru(parts: @[zbasu, w.toPart]))
      for one in w.entry.rafsi:
        # le rafsi cu sinxa pa gismu to `CLL 4.6` toi
        check joinRafsi([one, "zbasu"]).tanruRead == some(head)  # `CLL 4.6`
        if one.form.get in FORMS_FINAL:
          # le rafsi cu sinxa pa gismu to `CLL 4.6` toi
          check joinRafsi(["zba", one]).tanruRead == some(final)  # `CLL 4.6`
    var count_final_cmavo = 0
    for w in WORDS_CMAVO:  # ro lo sovo cmavo .e ro rafsi
      for one in w.entry.rafsi:
        check joinRafsi([one, "zbasu"]).tanruRead ==
            # ja'i `CLL 4.6` lo rafsi be lo cmavo cu sinxa le cmavo
            #   .i le rafsi cu pamoi
            some(Tanru(parts: @[w.toPart, zbasu]))  # `CLL 4.6`
        if one.form.get notin FORMS_FINAL: continue
        check joinRafsi(["zba", one]).tanruRead ==
            # ja'i `CLL 4.6` ji'a le rafsi cu romoi
            #   .i lo liste cu dunda lo cmene le rafsi
            #   .i lo lerfu cu jdice
            some(Tanru(parts: @[zbasu, w.toPart]))  # `CLL 4.6`
        inc count_final_cmavo
    # le bandu cu zgana lo rafsi be lo cmavo be'o poi fanmo lo valsi
    check count_final_cmavo >= FLOOR_FINAL_CMAVO  # le bandu cu zgana lo famrafsi be lo cmavo


  test "Rendering scores lowest of every spelling that reads back":
    var count_lowest = 0
    for tanru in tanruRandom():  # `SAMPLES` klani lo tanru poi lo tsiju cu jdice ke'a
      if tanru.parts.len < 2 or tanru.isStemShared: continue
      var
        lowest = high(int)
        found_rendering = false
      for rafsi in tanru.spellings:
        let text = joinRafsi(rafsi)
        if text.tanruRead != some(tanru): continue
        lowest = min(lowest, rafsi.toPieces.score)
        found_rendering = found_rendering or text == $tanru
      check found_rendering  # le selci'a cu cmima lo selci'avla poi `CLL 4.11` curmi ke'a
      # lo cmaraina'u pe lo selci'avla
      #   .i lo mitna'u cu se curmi to `CLL 4.12` toi
      check ($tanru).scoreRead == some(lowest)  # `CLL 4.12`
      inc count_lowest
    check count_lowest >= FLOOR_LOWEST  # le bandu cu ralte so'e le mupli


  test "Rendering gives form of exhaustive search, first of lowest on tie, over drawn tanru":
    var (count, count_broken) = (0, 0)
    for tanru in tanruRandom():  # `SAMPLES` klani lo gimtau poi lo tsiju cu jdice ke'a
      # ja'i `CLL 4.12` le cipra cu karbi `$` lo mulno sisku to `IX.2` toi
      check $tanru == tanru.renderExhaustive  # `CLL 4.12`
      inc count
    # `SAMPLES_CMAVO` klani lo tanru poi lo tsiju cu jdice ke'a
    #   .i su'o valsi cu cmavo
    for tanru in tanruCmavo():
      # ja'i `CLL 4.12` le cipra cu karbi `$` lo mulno sisku to `IX.2` toi
      check $tanru == tanru.renderExhaustive  # `CLL 4.12`
      inc count
    # `SAMPLES_FORMS` klani lo porsi be lo lerfu be'o poi lo tsiju cu jdice ke'a
    for rafsi in lujvoForms():
      let reading = joinRafsi(rafsi).readWord
      if not reading.is_word: continue
      let rendered = $reading.tanru
      # ja'i `CLL 4.12`
      #   .i su'o le pagbu cu selvau no liste
      check rendered == reading.tanru.renderExhaustive  # `CLL 4.12`
      if rendered.isBrokenFirst: inc count_broken
      inc count
    check count >= FLOOR_SEARCH  # le bandu cu ralte ji'i ro le selcu'a
    # le bandu cu zgana `y` pe `CLL 4.11 step 5` bu'u lo pamoi te jorne
    check count_broken >= FLOOR_BROKEN  # `CLL 4.11 step 5`


  test "Rendering gives form of exhaustive search over each lujvo of lujvo list":
    let lines = readLinesLujvo()
    # `lujvo.txt` claxu gi'a na mapti lo stosni pe le datnyvei to `texts_outside.nim` toi
    if lines.isNone: skip()
    else:
      var count = 0
      for line in lines.get:  # ro linji poi lo valsi pe ke'a se gunma lo lerfu
        let reading = line.word.readWord
        if not reading.is_word or reading.tanru.parts.len < 2: continue
        # ja'i `CLL 4.12` le cipra cu karbi `$` lo mulno sisku to `IX.2` toi
        check $reading.tanru == reading.tanru.renderExhaustive  # `CLL 4.12`
        inc count
      check count >= FLOOR_LUJVO_LIST  # le bandu cu ralte ji'i ro le linji


  test "Tanru of 18 words renders, reads back, and scores no more than spelling it came from":
    let reading = "lotconrotybanbalbapybembedbejbesybefybevbixybimbolbogbotmlatu".readWord
    check reading.is_word and reading.tanru.parts.len == 18  # le valsi cu selzba bu'u `#782`
    if reading.is_word:
      let
        parts = reading.tanru.parts
        rendered = $reading.tanru
        chosen = rendered.readWord.pieces.mapIt(it.rafsi)
      check rendered.tanruRead == some(reading.tanru)  # ja'i `CLL 4.6` lo nu ciska gi'e xrutcidu
      # ja'i `CLL 4.12` le selci'a cu du pa selci'avla be le tanru
      check rendered.scoreRead.get <= reading.pieces.score  # `CLL 4.12`
      # ro krapau poi lo mulsisku cu dunda lo namcu ke'a ze'a lo bazytei
      for count in 2..COUNT_PREFIX_MAX:
        let prefix = Tanru(parts: parts[0..<count-1] & parts[^1])
        # ja'i `CLL 4.12` le cipra cu karbi `$` lo mulno sisku to `IX.2` toi
        check $prefix == prefix.renderExhaustive  # `CLL 4.12`
      for at, part in parts:  # ro selcu'a bu'u ro stuzi
        for one in choices(part, is_final = at == parts.high):
          var changed = chosen
          changed[at] = one
          # ja'i `CLL 4.12` no cenba be pa selcu'a cu dunda lo mecna'u
          check changed.toPieces.score >= chosen.toPieces.score  # `CLL 4.12`


  test "Search gives sequence of exhaustive search, first of lowest on tie, over drawn options":
    var (count_tie, count_state) = (0, 0)
    for options in optionsDrawn():  # `SAMPLES_OPTIONS` klani lo liste poi lo tsiju cu jdice ke'a
      let reference = options.searchExhaustive
      # ja'i `CLL 4.12` le cipra cu karbi `searchLowest` lo mulno sisku to `IX.2` toi
      check options.searchLowest == reference.first  # `CLL 4.12`
      if reference.last != reference.first: inc count_tie
      if options.searchExhaustive(as_stateless = true).first != reference.first: inc count_state
    # le bandu cu zgana lo liste poi lo porsi be lo tercu'a cu jdice va'o lo nu lo namcu cu mintu
    check count_tie >= FLOOR_TIE  # le bandu cu zgana lo liste poi lo porsi cu jdice
    # le bandu cu zgana lo liste poi lo tcini be lo porsi pe `CLL 4.11 step 5` jdice
    check count_state >= FLOOR_STATE  # `CLL 4.11 step 5`


  test "Rendering keeps first of lowest where scores tie, and reads state of run of step 5":
    # le tanru cu selzba
    #   .i lo namcu cu mintu bu'u le pamoi stuzi
    let tie_first = toTanru("condi+zmadu")
    # ja'i `CLL 4.12` re selci'avla cu ponse lo mitna'u
    check "cnomau".scoreRead == "coizma".scoreRead  # `CLL 4.12`
    # ja'i `CLL 4.12` le pamoi poi ponse lo cmalu traji namcu to `IX.2` toi
    check $tie_first == tie_first.renderExhaustive  # `CLL 4.12`
    # le tanru cu selzba
    #   .i lo namcu cu mintu bu'u lo stuzi poi se lidne le pamoi stuzi
    let tie_later = toTanru("cevni+fenra+trixe+toldi")
    # ja'i `CLL 4.12` re selci'avla cu ponse lo mitna'u
    check "ceirferti'etoldi".scoreRead == "ceirfe'arixtoldi".scoreRead  # `CLL 4.12`
    # ja'i `CLL 4.12` le pamoi poi ponse lo cmalu traji namcu to `IX.2` toi
    check $tie_later == tie_later.renderExhaustive  # `CLL 4.12`
    # lo tcini be lo porsi cu jdice
    let run = toTanru("snuji+vitci+cidja")  # le tanru cu selzba
    check run.choicesTanru.searchExhaustive(as_stateless = true).first !=
        # ja'i `CLL 4.11 step 5` lo sisku poi na pilno lo tcini cu cuxna lo drata
        run.choicesTanru.searchLowest  # `CLL 4.11 step 5`
    # ja'i `CLL 4.11 step 5` .e `CLL 4.12` le cipra cu karbi `$` lo mulno sisku to `IX.2` toi
    check $run == run.renderExhaustive  # `CLL 4.11 step 5`


  test "Every gismu of list reads as itself":
    for w in WORDS_GISMU:  # ro lo pacivore gismu
      let text = $w
      # lo tanru pe lo gismu pe lo liste cu vasru le gismu po'o
      check text.tanruRead == some(Tanru(parts: @[w.toPart]))  # lo tanru pe lo gismu cu du lo gismu
      check text.kindRead == some(Kind.Gismu)  # ja'i `CLL 4.4` lo tarmi be lo gismu
      check $Tanru(parts: @[w.toPart]) == text  # le gismu cu selci'a ta'i vo'a
      check text.readWord.pieces.len == 0  # le valsi cu mulseltcidu gi'e vasru no rafsi


  test "Every cmavo of list reads as itself":
    for w in WORDS_CMAVO:  # ro lo sovo cmavo
      let text = $w
      # ja'i `CLL 4.2` ro cmavo cu du pa valsi
      check text.tanruRead == some(Tanru(parts: @[w.toPart]))  # `CLL 4.2`
      check text.kindRead == some(Kind.Cmavo)  # ja'i `CLL 4.2` lo tarmi be lo cmavo
      check $Tanru(parts: @[w.toPart]) == text  # le cmavo cu selci'a ta'i vo'a
    let se_cusku = toTanru("se+cusku")
    # ja'i `CLL 4.6` lo tanru cu vasru lo cmavo ta'i lo lujvo
    check ($se_cusku).tanruRead == some(se_cusku)  # `CLL 4.6`
    # ja'i `CLL 4.11 step 2` no rafsi be zo se cu fanmo lo lujvo to `CLL 5.1` toi
    check $toTanru("cusku+se") == "cusku se"  # `CLL 4.11 step 2`


  test "Every string of gismu form reads as gismu, named where list holds it":
    var count_listed, count_unlisted = 0
    for notation in ["CVCCV", "CCVCV"]:
      for text in textsNotation(notation):  # ro lo parerebiremu lerpoi pe ro sinxa
        if not text.isGismu: continue
        let listed = text.word
        check text.kindRead == some(Kind.Gismu)  # ja'i `CLL 4.4` lo tarmi po'o cu zbasu lo gismu
        check text.tanruRead == some(Tanru(parts: @[
          if listed.isSome: listed.get.toPart else: unlisted(text)
        ]))  # ga lo liste cu dunda lo cmene le valsi gi le pagbu cu ralte lo lerfu
        if listed.isSome: inc count_listed else: inc count_unlisted
    # lo javni be lo nu stali
    #   .i ro gismu pe lo liste cu selfa'i pa roi
    check count_listed == WORDS_GISMU.len  # lo javni be lo nu stali
    check count_unlisted > 0  # le se cipra cu vasru lo lerpoi poi no liste cu vasru ke'a


  test "Lujvo of rafsi drawn from letters reads by its forms, named where list assigns":
    var count_unassigned = 0
    for rafsi in lujvoForms():  # `SAMPLES_FORMS` klani lo porsi poi lo tsiju cu jdice ke'a
      let
        text = joinRafsi(rafsi)
        reading = text.readWord
      # ja'i `CLL 4.11` lo tarmi .e lo lerfu jorne po'o
      check reading.is_word and reading.kind == Kind.Lujvo  # `CLL 4.11`
      if not reading.is_word: continue
      # lo nu fendi cu fatne lo nu jmina
      #   .iju lo liste cu dunda le rafsi lo valsi
      check reading.pieces.mapIt(it.rafsi) == rafsi  # lo nu fendi cu fatne lo nu jmina
      # lo liste cu dunda lo valsi ro lo pagbu poi le liste cu ka'e dunda lo valsi ke'a
      check reading.tanru.parts == rafsi.mapIt(it.partNamed)  # le liste cu dunda lo cmene ro pagbu
      if not reading.tanru.parts.allIt(it.is_listed): inc count_unassigned
    # le bandu cu zgana lo rafsi poi no liste cu dunda ke'a lo valsi
    check count_unassigned >= FLOOR_UNASSIGNED  # le bandu cu zgana lo na selsterafsi


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
        # ja'i `CLL 4.3` lo zunsna remei cu zvati le mu lerfu poi krasi
        #   .i lo karsna cu romoi
        check text.isShapeBrivla  # `CLL 4.3`
        check not text.isShapeGismu  # ja'i `CLL 4.7` le valsi cu na gismu
        inc count_fuhivla
      else:
        check text[^1] in CONSONANTS_LETTERS  # ja'i `CLL 4.8` lo zunsna cu romoi
        # ja'i `CLL 4.8` le valsi na vasru zo la .a zo doi vu'o poi no zunsna cu lidne ke'a
        check not text.isBrokenUp  # `CLL 4.8`
        inc count_cmene
    # ja'i `IX.3` le bandu cu ralte lo fu'ivla ne'i le se cipra
    check count_fuhivla >= FLOOR_FUHIVLA  # `IX.3`
    check count_cmene >= FLOOR_CMENE  # ja'i `IX.3` le bandu cu ralte lo cmene ne'i le se cipra


  test "Listed cmavo joined before listed gismu, needing no pause, never reads as fu'ivla":
    var count = 0
    let words_gismu = WORDS_GISMU.mapIt(it.entry.word).filterIt(it[1] in CONSONANTS_LETTERS)
    randomize(3)
    for _ in 1 .. SAMPLES_JOINED:
      var text = ""
      for _ in 1 .. rand(1 .. 2): text.add WORDS_CMAVO_JOINABLE.sample
      text.add words_gismu[rand(words_gismu.high)]
      let reading = text.readWord
      # ja'i `CLL 4.7` no fu'ivla cu vlagunma
      check not (reading.is_word and reading.kind == Kind.Fuhivla)  # `CLL 4.7`
      if not reading.is_word and reading.refusal == Refusal.Combination: inc count
    # ja'i `IX.3` le bandu cu ralte lo nu to'e curmi lo vlagunma ne'i le se cipra
    check count >= FLOOR_JOINED  # `IX.3`
