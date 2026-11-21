## rapyzba lo nu tcidu lo porsi be lo valsi pe `CLL 3` .e `CLL 4` kei gi'e cipra lo du'u
##     `stream.nim` mapti le selzba
##   .i cipra lo flalu poi `CLL` nibli ke'a
##
## ni'o lo mupli cu fukpi lo selci'a pe `CLL` gi'e no roi fukpi lo selci'a be le samtci
##   .i lo pinka be lo mupli poi no krasi cu vasru ke'a cu cusku lo du'u le mupli cu selfi'i
##
## ni'o lo flalu cu tcidu lo cunpoi be lo valsi poi gismu ja cmavo ja lujvo be'o poi lo tsiju cu
##     jdice ke'a ku'o .e ro stuzi be ro valsi to `Article IX.3` toi
##   .i lo gismu pe le porsi cu selcu'a fi ro cmima be le gimste
##   .i lo cmavo pe le porsi cu selcu'a fi ro cmima be le ma'oste
##   .i lo lujvo pe le porsi cu selcu'a fi lo lujvo poi `$` ciska ke'a
##   .i lo fancu pe lo rapyjva cu cusku ro javni ta'i lo nu `CLL` cusku kei gi'e na pilno le
##       genturfa'i
##
## ni'o lo se cipra na ca vasru lo cunpoi poi vasru lo cmene .a lo fu'ivla .a lo nu sitna
##   .i le cipra cu cipra le cmene .e le fu'ivla .e le nu sitna sepi'o lo mupli pe `CLL` po'o
##   .i `test_prose.nim` cipra lo nu sitna ta'i di'u

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, tables, unittest]

import ../../src/ricysoho/[dictionary, forms, selmaho, stream, tanru]
import ../../src/ricysoho/lists/[cmavo, gismu]


const
  LUT_CMAVO_BY_DIGIT = ["no", "pa", "re", "ci", "vo", "mu", "xa", "ze", "bi", "so"]
    ## lo cmavo pe `PA` poi ro lerfu pe `0` bi'o `9` cu sinxa ke'a to `CLL 18.2` toi
  MARKS_NUMBERED = ['1', '.', ',', ' ']
    ## lo lerfu poi le flalu pe `D1 a` cu zbasu lo selci'a sepi'o ke'a
  LENGTH_NUMBERED_MOST = 7
    ## lo selci'a poi le flalu cu zbasu ke'a cu vasru su'e ze lerfu
    ##   .i se ki'u bo pa boi slaka bu cu ka'e lidne mu lerfu
  COUNT_NUMBERED = 21845
    ## lo te kancu be ro selci'a poi le flalu cu tcidu ke'a
    ##   .i ro le selci'a cu vasru su'e ze lerfu pe `MARKS_NUMBERED`
  SIGNS_RULED = [
    ("€", @["ronru'u"]), ("$", @["rupnu"]), ("£", @["rupnu"]), ("¢", @["fepni"]),
    ("¥", @["ponjo", "ja", "jungo", "rupnu"]),
  ]
    ## lo jdini sinxa .e lo valsi poi le sinxa cu sinxa ke'a
    ##   .i `Architect` jdice di'u bu'u `#1003` ta'i `D1 a`
  WORDS_SIGNED = [
    "lo", "be", "li", "be'o", "ku", "ronru'u", "rupnu", "fepni", "ponjo", "ja", "jungo",
  ]
    ## ro valsi poi lo jdini sinxa cu sinxa ke'a
  MARKS_SIGNED = ["1", "a", "$", "€", "¥", " "]
    ## lo pagbu poi le flalu pe `D3 a` cu zbasu lo selci'a sepi'o ke'a
    ##   .i lo lerfu po'u `1` .e lo lerfu po'u `a` .e ci jdini sinxa .e pa kutle'u
    ##   .i ro le jdini sinxa cu vasru su'e ci lerfu
  LENGTH_SIGNED_MOST = 6  ## lo selci'a poi le flalu cu zbasu ke'a cu vasru su'e xa pagbu
  COUNT_SIGNED = 55987
    ## lo te kancu be ro selci'a poi le flalu cu tcidu ke'a
    ##   .i ro le selci'a cu vasru su'e xa pagbu pe `MARKS_SIGNED`
  PREFIXES_RULED = [("+", "ma'u"), ("-", "ni'u"), ("−", "ni'u"), ("~", "ji'i")]
    ## lo sinxa poi lidne lo namcu .e le cmavo pe `PA` poi le sinxa cu sinxa ke'a
    ##   .i `Architect` jdice di'u bu'u `#1003` ta'i `D4 b`
  CONSTANTS_RULED = [("π", @["pai"]), ("∞", @["ci'i"]), ("½", @["pa", "fi'u", "re"])]
    ## lo sinxa poi sinxa pa namcu .e le cmavo pe `PA` poi le sinxa cu sinxa ke'a
    ##   .i `Architect` jdice di'u bu'u `#1003` ta'i `D4 b`
  MARKS_PREFIXED = ["1", "a", " ", "-", "−", "%", "π", "½", "€"]
    ## lo pagbu poi le flalu pe `D4 b` cu zbasu lo selci'a sepi'o ke'a
    ##   .i lo lerfu po'u `1` .e lo lerfu po'u `a` .e pa kutle'u .e xa sinxa
  LENGTH_PREFIXED_MOST = 5  ## lo selci'a poi le flalu cu zbasu ke'a cu vasru su'e mu pagbu
  COUNT_PREFIXED = 66430
    ## lo te kancu be ro selci'a poi le flalu cu tcidu ke'a
    ##   .i ro le selci'a cu vasru su'e mu pagbu pe `MARKS_PREFIXED`
  SAMPLES = 1000
    ## lo cunpoi poi lo flalu cu cuxna ke'a sepi'o lo tsiju ku'o .e lo cunjvo poi le girzu cu cuxna
    ##     ke'a
  COUNT_WORDS_MAX = 8  ## lo rairlai be lo valsi pe lo cunpoi
  FLOOR_COMMA_READ = 11000
    ## lo mecrailai be lo lerfu po'u slaka bu poi le flalu pe slaka bu cu tcidu ke'a ta'i lo nu
    ##     fendi lo slaka
    ##   .i 11592 lerfu cu se tcidu ne'i le re liste .e lo lujvo poi selcu'a ca lo nu lo tsiju
    ##       cu du `1`
  FLOOR_COMMA_REFUSED = 4000
    ## lo mecrailai be lo lerfu po'u slaka bu poi le flalu pe slaka bu cu to'e curmi ke'a
    ##   .i 4221 lerfu cu se tcidu ne'i le mi'uvla
  FLOOR_STRESS_REFUSED = 3900
    ## lo mecrailai be lo brale'u poi na zvati le slaka poi lidne le romoi slaka pe lo brivla ku'o
    ##     gi'e se to'e curmi le genturfa'i
    ##   .i le genturfa'i na tcidu lo datyvla fi le brale'u
    ##   .i 4130 brale'u cu se tcidu ne'i le gimste .e lo lujvo poi selcu'a ca lo nu lo tsiju cu
    ##       du `1`
    ##   .i ne'i le se cipra ro drata brivla cu nitcu lo barda lerfu to `D3 a` pe `#811` toi
  SAMPLES_JOINED = 4000
    ## lo cunpoi be lo valsi be'o poi vasru re valsi .a ci valsi zi'e poi selci'a ne'i pa selci'avla
    ##     zi'e poi lo tsiju cu jdice ke'a
    ##   .i lo porsi poi nitcu lo denpa poi zvati lo jbini be le valsi cu selvi'u ki'u lo nu lo
    ##       selci'a poi jorne cu ciska no denpa
  FLOOR_JOINED = 2500
    ## lo mecrailai be lo porsi poi lo nu basna pe ke'a mapti ro brivla zi'e poi le genturfa'i cu
    ##     tcidu le mi'uvla fi ke'a
    ##   .i 2757 porsi cu se tcidu ca lo nu lo tsiju cu du `2`
  FLOOR_JOINED_OTHER = 800
    ## lo mecrailai be lo porsi poi lo nu basna pe ke'a mapti no brivla
    ##   .i 885 porsi cu se tcidu ca lo nu lo tsiju cu du `2`
  COUNT_COMMA_MARKED = 88
    ## lo lerfu po'u slaka bu poi le flalu pe lo valsi poi claxu lo brale'u cu tcidu ke'a
    ##   .i ro stuzi poi na lamji zoi gy. ' .gy. ne'i ro valsi pe `WORDS_BORROWED` .e `WORDS_NAMED`
  FLOOR_COMMA_KEPT = 65
    ## lo mecrailai be le lerfu po'u slaka bu poi za'o se tcidu
    ##   .i 71 lerfu cu se tcidu
  WORDS_GROUPED = ["meiin", "iuain", "dauarnold", "meiris", "vauensas", "uiliam", "xuakin"]
    ## lo cmene poi slaka bu ka'e fendi lo karsna pe ke'a
    ##   .i le cmene cu du lo cmene pe `Example 3.6` .e `Example 3.7` ge'u .e re cmene poi lo nu
    ##       lanli `#811` cu facki ke'a ku'o .e lo jbocme pe `CLL 4.8`
  COUNT_GROUPED = 36  ## lo klani be lo slaka pe ro nu fendi pe ro cmene poi le flalu cu tcidu ke'a
  FLOOR_COMMA_STRESS = 8
    ## lo mecrailai be lo fu'ivla poi vasru slaka bu .e lo nu basna kei gi'e se tcidu le flalu pe le
    ##     mumoi javni
    ##   .i bi fu'ivla cu se tcidu
  SAMPLES_COMMA_PAUSE = 2000
    ## lo cunso remei be lo cmavo be'o poi lo tsiju cu jdice ke'a
    ##   .i le flalu pe slaka bu ne'i lo denpa cu cuxna le remei
  FLOOR_COMMA_PAUSE = 190
    ## lo mecrailai be le remei poi nitcu lo denpa poi zvati lo jbini be le re cmavo
    ##   .i 201 boi remei cu se tcidu ca lo nu lo tsiju cu du `4`
  FLOOR_GLIDE_READ = 40
    ## lo mecrailai be lo brale'u poi le flalu pe lo sakli karsna cu tcidu ke'a ta'i pa brivla
    ##   .i 40 brale'u cu se tcidu bu'u le slaka poi lidne le romoi slaka
    ##   .i ro sakli karsna cu zvati vo greku poi vasru re slaka .a ci slaka
  FLOOR_STRESS_OTHER = 200
    ## lo mecrailai be lo brale'u poi na zvati le slaka poi lidne le romoi slaka pe lo brivla ku'o
    ##     gi'e se tcidu ta'i lo datyvla
    ##   .i 228 brale'u cu se tcidu
    ##   .i mupli fa lo nu le genturfa'i cu tcidu `xlusni pa` fi `xlUsnipa`
  FLOOR_STRESS = 800
    ## lo mecrailai be lo denpa poi le flalu pe lo nu basna cu facki ke'a ba lo romoi slaka poi se
    ##     basna
    ##   .i no datyjva cu nitcu le denpa
    ##   .i 842 denpa cu se tcidu ca lo nu lo tsiju cu du `0`
  VOWELS_SYLLABLE = "aeiouy"
    ## lo lerfu poi zbasu lo slaka
    ##   .i lo karsna pe `CLL 3.1` ge'u .e `y` to `CLL 3.4` .e `CLL 3.9` toi
  WRITTEN_SPANNED = [
    "bar,da", "le,nu", "KLAmaku", "miBROda", "secusku", ".ui,ku", "zoi gy. a, b .gy.",
    "la'o gy. X .gy. cu",
  ]
    ## lo selci'avla poi le flalu pe lo stuzi cu tcidu lo stuzi pe ke'a
    ##   .i le selci'avla cu vasru slaka bu poi zvati pa valsi ku'o .e slaka bu poi zvati lo jbini
    ##       be re valsi pe pa selci'avla ku'o .e lo brale'u .e lo ve fendi .e lo nu sitna poi vasru
    ##       slaka bu .e denpa bu
    ##   .i le mupli cu selfi'i
  CONSONANTS_SYLLABIC = "lmnr"  ## lo zunsna poi ka'e slaka to `CLL 3.4` toi
  DIPHTHONGS_OFF = ["ai", "ei", "oi", "au"]
    ## lo karsna gunma poi le romoi pagbu be ke'a cu sakli zi'e poi ka'e zvati ro valsi to `CLL 3.4`
    ##     toi
  DIPHTHONGS_ON = ["ia", "ie", "ii", "io", "iu", "ua", "ue", "ui", "uo", "uu"]
    ## lo karsna gunma poi le pamoi pagbu be ke'a cu sakli
    ##   .i le karsna gunma cu ka'e pamoi ne'i lo valsi poi sepli ku'o gi'e ka'e zvati lo cmene .e
    ##       lo fu'ivla to `CLL 3.4` .e `CLL 4.2` toi
  DIPHTHONGS_NAME = ["iy", "uy"]  ## lo karsna gunma poi `CLL 3.4` curmi ke'a ne'i lo cmene po'o
  KINDS_BRIVLA = {Kind.Gismu, Kind.Lujvo, Kind.Fuhivla}  ## lo klesi be lo brivla to `CLL 4.3` toi
  WORDS_BORROWED = [
    "spageti", "kuarka", "integrale", "saskrkuarka", "bangrkorea", "zgiee", "crarciae",
    "gackioto",
  ]
    ## lo fu'ivla poi slaka bu .e lo brale'u cu barna ke'a
    ##   .i le fu'ivla cu du lo fu'ivla pe `Example 4.46` .e `Example 4.50` .e `Example 4.56` ge'u
    ##       .e lo fu'ivla poi selzba ta'i lo nu jmina lo krapau ja'i `CLL 4.7` ku'o .e ci fu'ivla
    ##       poi lo nu lanli `#811` cu facki ke'a
    ##   .i slaka bu ka'e fendi lo lamji karsna pe le ci fu'ivla
    ##   .i le ci mupli cu selfi'i
  WORDS_NAMED = ["djim", "katrinas", "uiliam", "xuakin", "meiris", "vauensas"]
    ## lo cmene poi slaka bu .e lo brale'u cu barna ke'a
    ##   .i le cmene cu du lo cmene pe `Example 4.57` .e `Example 4.61` ge'u .e lo jbocme pe
    ##       `CLL 4.8`
  FRAMES_NAME = ["k_n", "dj_m", "m_tan", "s_lis"]
    ## lo lerfu pe lo cmene ge'u zi'e poi sruri lo karsna gunma po'u `_` pe lo cmene
    ##   .i le lerfu cu zbasu pa slaka .a re slaka
    ##   .i le mupli cu selfi'i
  FRAMES_GLIDE = ["br_", "kobr_", "spag_", "br_na", "kobr_na"]
    ## lo lerfu poi sruri lo sakli karsna po'u `_`
    ##   .i le lerfu cu zbasu pa slaka .a re slaka .a ci slaka
    ##   .i le mupli cu selfi'i
  COUNT_NAME_CAPITALS = 12
    ## lo slaka pe ro karsna gunma pe lo cmene ne'i ro greku
    ##   .i li 12 du li 2 pi'i vei pa su'i pa su'i re su'i re
  COUNT_GLIDE_CAPITALS = 100
    ## lo slaka pe ro sakli karsna ne'i ro greku
    ##   .i li 100 du li 10 pi'i vei pa su'i re su'i re su'i re su'i ci



#[ ni'o ni'o ni'o lo tcidu ]#

func wordsRead(text: string): Option[seq[string]] =
  ## tcidu le porsi gi'e liste lo lerfu pe ro valsi ta'i lo porsi
  ##   .i dunda no da va'o lo nu le porsi cu se to'e curmi
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.text)) else: none(seq[string])


func pausesRead(text: string): Option[seq[Pause]] =
  ## tcidu le porsi gi'e liste lo denpa poi lidne lo valsi ta'i lo porsi
  ##   .i dunda no da va'o lo nu le porsi cu se to'e curmi
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.pause)) else: none(seq[Pause])


func stressesRead(text: string): Option[seq[Option[int]]] =
  ## tcidu le porsi gi'e liste lo slaka karsna poi lo brale'u cu basna ke'a ne'i lo valsi ta'i lo
  ##     porsi
  ##   .i dunda no da va'o lo nu le porsi cu se to'e curmi
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.stress)) else: none(seq[Option[int]])


func startsRead(text: string): Option[seq[int]] =
  ## tcidu le porsi gi'e liste lo stuzi poi lo valsi cu cfari bu'u ke'a ta'i lo porsi
  ##   .i dunda no da va'o lo nu le porsi cu se to'e curmi
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.start)) else: none(seq[int])


func isSigned(text: string, at: int): bool =
  ## jdice lo du'u le stuzi po'u `at` cu korbi lo namcu poi lo jdini sinxa pe `SIGNS_RULED` cu
  ##     pencu ke'a
  ##   .i le namcu cu porsi lo lerfu pe `0` bi'o `9` .e denpa bu .e slaka bu poi zvati lo jbini
  ##       be re lerfu
  ##   .i ji'a lo sinxa pe `PREFIXES_RULED` cu ka'e krasi le namcu
  ##   .i ji'a zoi gy. % .gy. cu ka'e fanmo le namcu
  ##   .i le jdini sinxa cu pencu lo lerfu pe `0` bi'o `9` pe le namcu
  func isInner(i: int): bool =
    ## jdice lo du'u le lerfu po'u `i` cu pagbu le namcu
    i >= 0 and i < text.len and (text[i] in Digits or
      (text[i] in {'.', ','} and i > 0 and text[i - 1] in Digits and
        i + 1 < text.len and text[i + 1] in Digits))
  func sizePrefix(i: int): int =
    ## dunda lo klani be lo stuzi pe le sinxa pe `PREFIXES_RULED` poi fanmo pu `i` gi'e lidne lo
    ##     lerfu pe le namcu
    ##   .i dunda li 0 va'o lo nu no sinxa cu mapti
    for (sign, _) in PREFIXES_RULED:
      if i >= sign.len and text.continuesWith(sign, i - sign.len) and isInner(i): return sign.len
  func isTouched(first, last: int): bool =
    ## jdice lo du'u lo jdini sinxa cu pencu lo lerfu pe `0` bi'o `9` pe le namcu poi cfari bu'u
    ##     `first` gi'e fanmo bu'u `last`
    SIGNS_RULED.anyIt((text.continuesWith(it[0], last) and text[last - 1] in Digits) or
      (first >= it[0].len and text.continuesWith(it[0], first - it[0].len) and
        text[first] in Digits))
  # le namcu poi cfari bu'u `at`
  let opening = PREFIXES_RULED.filterIt(text.continuesWith(it[0], at) and isInner(at + it[0].len))
  if opening.len > 0 or (isInner(at) and not isInner(at - 1) and sizePrefix(at) == 0):
    var last = at + (if opening.len > 0: opening[0][0].len else: 0)  # le stuzi pe le namcu
    while isInner(last): inc last
    if text.continuesWith("%", last): inc last
    if isTouched(at, last): return true
  # le namcu poi fanmo bu'u `at`
  if (isInner(at - 1) and not isInner(at) and not text.continuesWith("%", at)) or
      (at >= 2 and text[at - 1] == '%' and isInner(at - 2)):
    var first = (if text[at - 1] == '%': at - 1 else: at)  # le stuzi pe le namcu
    while isInner(first - 1): dec first
    first -= sizePrefix(first)
    if isTouched(first, at): return true
  false


func isSpanned(text: string): bool =
  ## jdice lo du'u ro valsi pe le porsi cu selfa'o ba le romoi lerfu pe vo'a gi'e selfa'o pu lo nu
  ##     lo bavla'i valsi cu cfari
  ##   .i ji'a lo stuzi poi le valsi cu kuspe ke'a ciska le valsi ba lo nu ro brale'u cu binxo lo
  ##       cmale'u kei .e lo nu ro boi slaka bu cu selvi'u
  ##   .i ja le stuzi cu ciska le selci'a poi se sitna ta'i lo nu selci'a
  ##   .i lo jalge cu jitfa va'o lo nu le porsi cu se to'e curmi
  ##
  ## ni'o lo valsi poi lo jdini sinxa cu sinxa ke'a cu vasru no stuzi
  ##   .i se ki'u bo le valsi cu cmima `WORDS_SIGNED` gi'e na se ciska ne'i le selci'a
  ##   .i ji'a le valsi cu zvati lo korbi be lo namcu poi lo jdini sinxa cu pencu ke'a to
  ##       `isSigned` toi
  ##   .i ji'a slaka bu poi sinxa zo ki'o cu du pa valsi to `D1 a` pe `#991` toi
  ##
  ## ni'o lo pamoi valsi poi pa sinxa pe `CONSTANTS_RULED` cu sinxa ke'a cu vasru ro stuzi pe le
  ##     sinxa
  ##   .i ro drata valsi pe le sinxa cu vasru no stuzi gi'e cfari bu'u le stuzi poi se lidne le
  ##       sinxa
  let reading = text.readStream
  if not reading.is_read: return false
  for k, occurrence in reading.occurrences:
    let
      is_group = occurrence.text == ","  # slaka bu poi sinxa zo ki'o
      written = text[occurrence.start ..< occurrence.finish]
      spelled =
        if occurrence.reading.is_word and not is_group: written.toLowerAscii.replace(",", "")
        else: written
      is_before = k == reading.occurrences.high or
        occurrence.finish <= reading.occurrences[k + 1].start
      # lo drata valsi pe pa sinxa pe `CONSTANTS_RULED`
      is_constant = CONSTANTS_RULED.anyIt(occurrence.start >= it[0].len and
        text.continuesWith(it[0], occurrence.start - it[0].len) and
        occurrence.text in it[1][1 .. ^1])
    if not is_before: return false
    if occurrence.start == occurrence.finish:
      if is_constant: continue
      if occurrence.text notin WORDS_SIGNED or not text.isSigned(occurrence.start): return false
      continue
    if spelled != occurrence.text: return false
    if occurrence.reading.is_word and not is_group and text[occurrence.finish - 1] == ',':
      return false
  true


func refusalNamed(text: string): Option[(string, int)] =
  ## tcidu le porsi gi'e dunda lo cmene be le javni poi to'e curmi le porsi ku'o .e le stuzi poi le
  ##     javni cu cusku ke'a
  ##   .i dunda no da va'o lo nu le porsi cu se tcidu
  ##   .i le cmene cu se pilno ki'u lo nu lo flalu pe `#1003` cu cmene lo javni poi `D3 a` cu
  ##       zbasu ke'a
  let reading = text.readStream
  if reading.is_read: none((string, int)) else: some(($reading.refusal, reading.start))


func widthsRead(text: string): Option[seq[int]] =
  ## tcidu le porsi gi'e liste lo klani be lo stuzi pe ro valsi ta'i lo porsi
  ##   .i dunda no da va'o lo nu le porsi cu se to'e curmi
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.finish - it.start)) else: none(seq[int])


func selmahoRead(text: string): Option[seq[Option[Selmaho]]] =
  ## tcidu le porsi gi'e liste lo selma'o be lo valsi ta'i lo porsi
  ##   .i dunda no da va'o lo nu le porsi cu se to'e curmi
  let reading = text.readStream
  if reading.is_read: some(reading.occurrences.mapIt(it.reading.selmaho))
  else: none(seq[Option[Selmaho]])


func cmavoRead(text: string): Option[seq[string]] =
  ## tcidu le porsi gi'e liste lo valsi poi le genturfa'i cu tcidu ro valsi ta'i ke'a
  ##   .i dunda no da va'o lo nu le porsi cu se to'e curmi
  let reading = text.readStream
  if not reading.is_read: return none(seq[string])
  some(reading.occurrences.mapIt(if it.reading.is_word: $it.reading.tanru else: it.text))


func refusalRead(text: string): Option[(Refusal, int)] =
  ## tcidu le porsi gi'e dunda lo javni poi to'e curmi le porsi ku'o .e lo stuzi poi le javni cu
  ##     cusku ke'a
  ##   .i dunda no da va'o lo nu le porsi cu se tcidu
  let reading = text.readStream
  if reading.is_read: none((Refusal, int)) else: some((reading.refusal, reading.start))



#[ ni'o ni'o ni'o lo rapli javni ]#

func isLetteralConsonant(text: string): bool =
  ## jdice lo du'u le valsi cu seltai `Cy` gi'e sinxa lo zunsna to `CLL 4.2` .e `CLL 17.2` toi
  text.len == 2 and text[1] == 'y' and text[0] notin VOWELS_SYLLABLE & "'"


func pausesNeeded(words: openArray[string]): seq[Pause] =
  ## liste lo denpa poi lidne lo valsi pe lo porsi poi selci'a sepi'o lo kutle'u gi'e vasru no
  ##     brale'u
  ##   .i le denpa cu seljdi ja'i lo javni ta'i lo nu `CLL` cusku
  ##   .i lo denpa cu lidne lo valsi poi selkra lo karsna .a `y` to le cimoi javni pe `CLL 4.9` ge'u
  ##       .e `CLL 4.2` toi ku'o .e lo valsi poi se lidne zo y to `CLL 4.2` toi ku'o .e lo valsi poi
  ##       na seltai `Cy` gi'e se lidne lo valsi poi seltai `Cy` to le xamoi javni pe `CLL 4.9` toi
  for i, word in words:
    let is_needed =
      word[0] in VOWELS_SYLLABLE or (i > 0 and words[i - 1] == "y") or
      (i > 0 and words[i - 1].isLetteralConsonant and not word.isLetteralConsonant)
    result.add(if is_needed: Pause.Inferred else: Pause.Absent)


func isCommaAdmitted(word: string, at: int): bool =
  ## jdice lo du'u slaka bu poi lidne le lerfu pe le stuzi po'u `at` fendi lo slaka ta'i lo nu
  ##     `CLL 3.3` .e `CLL 3.4` cusku
  ##   .i ro pagbu poi lamji slaka bu gi'e selfa'o zoi gy. ' .gy. .a lo korbi be le valsi cu vasru
  ##       lo karsna .a `y` .a lo zunsna poi ka'e slaka
  ##   .i ji'a slaka bu na zvati lo jbini be re karsna
  ##   .i ne'i lo gismu .e lo lujvo .e lo cmavo re karsna cu zbasu lo karsna gunma
  let
    before = word[0 ..< at].rsplit('\'', maxsplit = 1)[^1]
    after = word[at .. ^1].split('\'', maxsplit = 1)[0]
    letters_syllabic = VOWELS_SYLLABLE & CONSONANTS_SYLLABIC
  before.anyIt(it in letters_syllabic) and after.anyIt(it in letters_syllabic) and
      not (word[at - 1] in VOWELS_SYLLABLE and word[at] in VOWELS_SYLLABLE)


func syllables(
    word: string, is_borrowing = false, is_name = false, breaks: openArray[int] = []
): seq[Slice[int]] =
  ## liste lo karsna pe ro slaka pe le valsi ta'i lo nu `CLL 3.4` jmina le karsna ne'i lo slaka
  ##   .i le nu jmina cu cfari bu'u lo zunle to `CLL 3.5` toi
  ##
  ## ni'o lo karsna gunma poi le romoi pagbu be ke'a cu sakli cu du pa slaka
  ##   .i lo karsna gunma poi le pamoi pagbu be ke'a cu sakli cu du pa slaka va'o lo nu le karsna
  ##       gunma cu krasi le valsi kei .a lo nu le valsi cu fu'ivla ja cmene
  ##   .i `iy` .e `uy` du pa slaka ne'i lo cmene po'o
  ##   .i ro drata karsna cu du pa slaka
  ##   .i slaka bu poi lidne lo lerfu pe `breaks` fendi re karsna to `CLL 3.5` toi
  var at = 0
  while at < word.len:
    if word[at] notin VOWELS_SYLLABLE:
      inc at
      continue
    let
      pair = word[at .. min(at + 1, word.high)]
      is_glide =
        (pair in DIPHTHONGS_ON and (at == 0 or is_borrowing or is_name)) or
        (pair in DIPHTHONGS_NAME and is_name)
      size = (if (pair in DIPHTHONGS_OFF or is_glide) and at + 1 notin breaks: 2 else: 1)
    result.add at .. at + size - 1
    at += size


func penultimate(word: string, is_borrowing: bool): int =
  ## dunda lo stuzi be le slaka poi le brivla cu basna ke'a ne'i lo slaka pe le valsi
  ##   .i le slaka cu lidne le romoi slaka
  ##   .i `y` na se kancu to `CLL 3.9` toi
  let spans = word.syllables(is_borrowing = is_borrowing)
  toSeq(0 .. spans.high).filterIt(word[spans[it].a] != 'y')[^2]


func isStressFit(words: openArray[string], kinds: openArray[Kind]): bool =
  ## jdice lo du'u lo nu basna pe le selci'avla noi basna le slaka po'o poi lidne le romoi slaka pe
  ##     le selci'avla cu zvati le slaka poi lidne le romoi slaka pe ro brivla pe le valsi
  ##   .i lo klesi pe ro valsi cu jdice lo du'u le valsi cu brivla to `D3 a` pe `#811` toi
  ##   .i `y` na se kancu to `CLL 3.9` toi
  let
    run = words.join("")
    spans = run.syllables
    counted = toSeq(0 .. spans.high).filterIt(run[spans[it].a] != 'y')
  var lo = 0
  for i, word in words:
    if kinds[i] != Kind.Cmavo:
      if counted.len < 2: return false
      if word.syllables[word.penultimate(false)].a + lo != spans[counted[^2]].a: return false
    lo += word.len
  true


func capitalized(word: string, span: Slice[int]): string =
  ## ciska le valsi
  ##   .i lo lerfu pe `span` barda
  ##   .i `CLL 3.9` sinxa lo slaka poi se basna ta'i lo nu lo karsna pe le slaka cu barda
  result = word
  for i in span: result[i] = result[i].toUpperAscii



#[ ni'o ni'o ni'o lo se cipra ]#

let
  INDEXES_GISMU = block:
    ## lo stuzi be ro gismu pe le liste ne'i le liste
    ##   .i lo cmavo poi ponse lo rafsi cu selvi'u
    var indexes: seq[Word]
    for i, entry in LIST_GISMU:
      if entry.word.isGismu: indexes.add Word(i)
    indexes
  WORDS_GISMU = INDEXES_GISMU.mapIt(it.entry.word)  ## ro gismu pe le liste
  WORDS_CMAVO = block:
    ## ro cmavo pe le ma'oste
    ##   .i ku'i lo cmavo pe `ZOI` ge'u .e lo cmavo pe `FAhO` selvi'u
    ##   .i `ZOI` sitna lo selci'a poi na lojbo to `CLL 19.10` toi
    ##   .i `FAhO` fanmo le se ciska to `CLL 19.15` toi
    var words: seq[string]
    for entry in LIST_CMAVO:
      if entry.selmaho notin {Selmaho.Zoi, Selmaho.Faho}: words.add entry.word
    words
  LUT_SELMAHO_BY_CMAVO = block:
    ## lo selma'o poi le ma'oste cu dunda ke'a lo cmavo
    ##   .i lo selma'o cu se tcidu fi le liste gi'e na se tcidu le genturfa'i to `CLL 20` toi
    var lut: Table[string, Selmaho]
    for entry in LIST_CMAVO: lut[entry.word] = entry.selmaho
    lut


proc drawLujvo(): seq[string] =
  ## cuxna lo lujvo sepi'o lo tsiju
  ##   .i le klani be le lujvo cu du `SAMPLES`
  ##   .i ro lujvo cu sinxa lo tanru poi vasru re gismu .a ci gismu pe le liste
  ##   .i `$` ciska le lujvo
  randomize(1)
  for _ in 1 .. SAMPLES:
    result.add $Tanru(parts: newSeqWith(rand(2 .. 3), INDEXES_GISMU.sample.toPart))


let
  WORDS_LUJVO = drawLujvo()
    ## lo cunjvo poi lo flalu cu tcidu ke'a
    ##   .i le lujvo cu selcu'a pa roi
  LUT_KIND_BY_WORD = block:
    ## lo klesi pe ro valsi pe ro girzu ja'i le girzu poi le valsi cu selkra ke'a
    ##   .i le girzu cu du lo liste .a `$` to `CLL 4.2` bi'o `CLL 4.6` toi
    var lut: Table[string, Kind]
    for word in WORDS_GISMU: lut[word] = Kind.Gismu
    for word in WORDS_CMAVO: lut[word] = Kind.Cmavo
    for word in WORDS_LUJVO: lut[word] = Kind.Lujvo
    lut


proc drawStreams(): seq[seq[string]] =
  ## cuxna lo porsi be lo valsi sepi'o lo tsiju
  ##   .i le klani be le porsi cu du `SAMPLES`
  ##   .i ro porsi cu vasru lo valsi
  ##   .i le klani be le valsi cu cmima li 1 bi'o `COUNT_WORDS_MAX`
  ##
  ## ni'o ro valsi cu gismu ja cmavo ja lujvo gi'e selcu'a fi ro valsi pe lo girzu pe vo'a
  ##   .i le ci klesi cu mintu lo ka selcu'a ta'i lo nu cunso
  randomize(0)
  for _ in 1 .. SAMPLES:
    var words: seq[string]
    for _ in 1 .. rand(1 .. COUNT_WORDS_MAX):
      words.add:
        case rand(2)
        of 0: WORDS_GISMU.sample
        of 1: WORDS_CMAVO.sample
        else: WORDS_LUJVO.sample
    result.add words


let STREAMS_RANDOM = drawStreams()
  ## lo cunpoi poi ro flalu cu tcidu ke'a
  ##   .i le porsi cu selcu'a pa roi


iterator wordsEach(): string =
  ## dunda ro gismu .e ro cmavo pe le liste
  ##   .i ba bo dunda ro cunjvo
  for word in WORDS_GISMU: yield word
  for word in WORDS_CMAVO: yield word
  for word in WORDS_LUJVO: yield word



suite "Chapter 3":
  test "Section 3.1":
    for c in "aeiou":
      # ja'i `CLL 3.1` lo brale'u cu sinxa lo nu basna
      check ($c.toUpperAscii).stressesRead == some(@[some(0)])  # `CLL 3.1`
    for c in tanru.LETTERS - {'\''} - {'a', 'e', 'i', 'o', 'u', 'y'}:  # ro zunsna
      # ja'i `CLL 3.9` le brale'u cu vasru su'o pa karsna
      check (c.toUpperAscii & "a").refusalRead == some((Refusal.Stress, 0))  # `CLL 3.9`
    for c in ['H', 'Q', 'W']:
      # zoi gy. h .gy. .e zoi gy. q .gy. .e zoi gy. w .gy. na cmima lo lerste pe `CLL 3.1`
      check (c & "a").refusalRead == some((Refusal.Letter, 0))  # `CLL 3.1`
    for c in char.low .. char.high:  # ro le 256 lerfu
      # ro lerfu pe `0` bi'o `9` cu sinxa pa cmavo pe `PA`
      #   .i ki'u bo le flalu cu bavykla le lerfu
      #   .i ji'a zoi gy. $ .gy. cu jdini sinxa to `D1 a` pe `#1003` toi
      #   .i ji'a zoi gy. + .gy. .e zoi gy. - .gy. .e zoi gy. ~ .gy. .e zoi gy. % .gy. cu sinxa lo
      #       namcu to `D4 b` pe `#1003` toi
      if c in tanru.LETTERS or c in MARKS_STREAM or c in {'0' .. '9', '$', '+', '-', '~', '%'}:
        continue
      # ja'i lo lerste pe `CLL 3.1`
      check ("mi " & c & "a").refusalRead == some((Refusal.Letter, 3))  # `CLL 3.1`
    # ja'i `CLL 3.1` lo brale'u cu sinxa lo nu basna po'o
    check "Mi klama".refusalRead == some((Refusal.Stress, 0))  # `CLL 3.1`


  test "Section 3.3":
    # `CLL 3.3` .e `Example 3.1`
    check ".i.ai.i.ai.o".wordsRead == some(@["i", "ai", "i", "ai", "o"])  # `CLL 3.3`
    # `CLL 3.3`
    #   .i denpa bu cu selpu'i ne'i le selci'a
    check ".i.ai.i.ai.o".pausesRead == some(Pause.Written.repeat(5))  # `CLL 3.3`
    # ja'i `CLL 3.3` no kutle'u cu seltcu va'o lo nu denpa bu cu zvati
    #   .i le mupli cu selfi'i
    check "mi.klama".wordsRead == some(@["mi", "klama"])  # `CLL 3.3`
    # ja'i `CLL 3.3` le selci'a cu vasru re valsi gi'e na du pa valsi
    check "bri.vla".refusalRead == some((Refusal.Shape, 0))  # `CLL 3.3`
    check "mi klama i do klama".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred, Pause.Absent, Pause.Absent])
          # ja'i `CLL 3.3` le genturfa'i cu facki lo denpa poi denpa bu na sinxa ke'a
          #   .i le mupli cu selfi'i
    # `CLL 3.3` .e `Example 3.2`
    #   .i pa cmene
    check ".i,ai,i,ai,on.".wordsRead == some(@["iaiiaion"])  # `CLL 3.3`
    # `CLL 3.3` .e `Example 3.4`
    #   .i pa cmene
    check ".i'ai'i'ai'on.".wordsRead == some(@["i'ai'i'ai'on"])  # `CLL 3.3`
    # ja'i `CLL 3.3` slaka bu cu zvati ne'i lo valsi po'o
    #   .i le mupli cu selfi'i
    check ",klama".refusalRead == some((Refusal.Comma, 0))  # `CLL 3.3`
    # ja'i `CLL 3.3` slaka bu cu fendi lo slaka
    check "kla,,ma".refusalRead == some((Refusal.Comma, 3))  # `CLL 3.3`
    # ja'i `CLL 3.3` `y` lidne lo denpa
    #   .i le mupli cu selkra lo nu lanli `#811`
    check "y,ku".refusalRead == some((Refusal.Comma, 1))  # `CLL 3.3`
    # ja'i `CLL 3.3` slaka bu na ka'e zvati lo stuzi be lo denpa
    #   .i le mupli cu selkra lo nu lanli `#811`
    check "ma,e".refusalRead == some((Refusal.Comma, 2))  # `CLL 3.3`
    # ja'i `CLL 3.9` `ia` du le slaka poi lidne le romoi slaka
    #   .i le mupli cu selfi'i
    check "crarcIae".wordsRead == some(@["crarciae"])  # `CLL 3.9`
    # ja'i `CLL 3.5` slaka bu cu fendi `ia`
    #   .i se ki'u bo le brale'u cu basna `crarcia`
    #   .i le mupli cu selfi'i
    check "crarcI,ae".wordsRead ==
        some(@["crarcia", "e"])  # `CLL 3.5`


  test "Section 3.4":
    # ja'i `CLL 3.4` lo karsna gunma cu du pa slaka
    #   .i le mupli cu selfi'i
    check "ka,i".refusalRead == some((Refusal.Comma, 2))  # `CLL 3.4`
    # ja'i `CLL 3.4` zoi gy. r .gy. slaka
    #   .i `Example 3.21`
    check "sai,r,goi".wordsRead == some(@["sairgoi"])  # `CLL 3.4`
    # ja'i `CLL 3.4` zoi gy. b .gy. na slaka
    #   .i le mupli cu selfi'i
    check "b,ridi".refusalRead == some((Refusal.Comma, 1))  # `CLL 3.4`
    # ja'i `CLL 3.4` lo zunsna poi slaka cu no roi se basna
    check "sai,R,goi".refusalRead == some((Refusal.Stress, 4))  # `CLL 3.4`
    # ja'i `CLL 3.4` lo karsna gunma cu du pa slaka
    #   .i se ki'u bo `brUa` na brivla to `CLL 4.3` toi
    #   .i le mupli cu selkra lo nu lanli `#811`
    check "brUa".refusalRead ==
        some((Refusal.Shape, 0))  # `CLL 3.4`
    # ja'i `CLL 3.4` `uy` du pa slaka ne'i lo cmene
    #   .i le mupli cu selkra lo nu lanli `#811`
    check "kUYn.".stressesRead == some(@[some(0)])  # `CLL 3.4`


  test "Section 3.5":
    for text in ["meiin.", "mei,in.", "me,iin."]:
      # `CLL 3.5` .e `Example 3.6` .e `Example 3.7`
      #   .i slaka bu cu zbasu no datyvla
      check text.wordsRead == some(@["meiin"])  # `CLL 3.5`
    # ja'i `CLL 3.5` `u` sepli `io` fi slaka bu
    #   .i le mupli cu selkra `Tatoeba`
    check ".nu,IOrk.".stressesRead == some(@[some(1)])  # `CLL 3.5`
    # `CLL 3.5` .e `Example 3.7`
    #   .i lo brale'u pe `CLL 4.8` zvati `ii`
    #   .i le mupli cu selkra lo nu lanli `#811`
    check "me,IIn.".stressesRead ==
        some(@[some(1)])  # `CLL 3.5`
    for text in [".i,UAin.", "da,UArnold."]:
      # ja'i `CLL 3.5` slaka bu cu fendi lo karsna
      #   .i le mupli cu selkra lo nu lanli `#811`
      check text.stressesRead == some(@[some(1)])  # `CLL 3.5`


  test "Section 3.9":
    check "pu,je,nai,ca,je,ba".wordsRead ==
        some(@["pu", "je", "nai", "ca", "je", "ba"])  # `CLL 3.9` .e `Example 3.18`
    check "pujenaicajeba".wordsRead ==
        "pu,je,nai,ca,je,ba".wordsRead  # `CLL 3.9` .e `Example 3.18` to slaka bu na bilga toi
    for (text, word) in [
      ("nin,mu", "ninmu"), ("fit,pri", "fitpri"), ("sair,goi", "sairgoi"),
      ("sai,r,goi", "sairgoi"), ("klez,ba", "klezba"), ("kle,zba", "klezba"),
    ]:
      check text.wordsRead == some(@[word])  # `CLL 3.9` .e `Example 3.19` bi'o bo `Example 3.22`
    for (text, word, nucleus) in [
      ("DI,ky,jvo", "dikyjvo", 0), ("BI,sy,dja", "bisydja", 0), ("BI,syd,ja", "bisydja", 0),
      ("da'UD,ja", "da'udja", 1), ("da'U,dja", "da'udja", 1),
    ]:
      # `CLL 3.9` .e `Example 3.23` .e `Example 3.28` .e `Example 3.29`
      check text.wordsRead == some(@[word])  # `CLL 3.9`
      # ja'i `CLL 3.9` le slaka poi lidne le romoi slaka
      #   .i `y` na se kancu
      check text.stressesRead == some(@[some(nucleus)])  # `CLL 3.9`
    for text in ["e'u bridi", "e'u BRI,di", "E'u BRI,di"]:
      check text.pausesRead == some(@[Pause.Inferred, Pause.Absent])  # `CLL 3.9` .e `Example 3.30`
    # `CLL 3.9` .e `Example 3.30`
    check "e'U.BRI,di".pausesRead == some(@[Pause.Inferred, Pause.Written])  # `CLL 3.9`
    check "e'U.BRI,di".stressesRead == some(@[some(1), some(0)])  # `CLL 3.9` .e `Example 3.30`
    # `CLL 3.9` .e `Example 3.30`
    #   .i le genturfa'i cu facki lo denpa poi denpa bu na sinxa ke'a to `CLL 3.3` toi
    check "e'U BRI,di".pausesRead ==
        some(@[Pause.Inferred, Pause.Inferred])  # `CLL 3.9`
    check "le re NObli PREnu".stressesRead ==
        some(@[none(int), none(int), some(0), some(0)])  # `CLL 3.9` .e `Example 3.31`
    check "le re no bliPREnu".wordsRead ==
        some(@["le", "re", "no", "bliprenu"])  # `CLL 3.9` .e `Example 3.32`
    check "le re no bliPREnu".stressesRead ==
        some(@[none(int), none(int), none(int), some(1)])  # `CLL 3.9` .e `Example 3.32`
    # ja'i `CLL 3.9` lo brivla cu basna le slaka poi lidne le romoi slaka
    #   .i le mupli cu selfi'i
    check "briDI".refusalRead == some((Refusal.Stress, 3))  # `CLL 3.9`
    # ja'i `CLL 3.9` zoi gy. y .gy. no roi se basna
    check "dikYjvo".refusalRead == some((Refusal.Stress, 3))  # `CLL 3.9`
    # ja'i `CLL 3.9` pa slaka po'o cu se basna
    #   .i le mupli cu selfi'i
    check "BrIdi".refusalRead == some((Refusal.Stress, 0))  # `CLL 3.9`
    check ".ARM,strong.".wordsRead == some(@["armstrong"])  # `CLL 3.9` .e `Example 3.24`
    # `CLL 3.9` .e `Example 3.24`
    #   .i le pamoi slaka
    check ".ARM,strong.".stressesRead == some(@[some(0)])  # `CLL 3.9`



suite "Chapter 4":
  test "Section 4.2":
    check ".iseci'i".wordsRead == some(@["i", "se", "ci'i"])  # `CLL 4.2` .e `Example 4.1`
    check ".iseci'i".pausesRead ==
        some(@[Pause.Written, Pause.Absent, Pause.Absent])  # `CLL 4.2` .e `Example 4.1`
    check ".iseci'i".selmahoRead ==
        some(@[some(Selmaho.I), some(Selmaho.Se), some(Selmaho.Pa)])  # `CLL 20` to ro cmavo toi
    # `CLL 4.2` .e `Example 4.2`
    check "punaijecanai".wordsRead == some(@["pu", "nai", "je", "ca", "nai"])  # `CLL 4.2`
    check "ki'e.u'e".wordsRead == some(@["ki'e", "u'e"])  # `CLL 4.2` .e `Example 4.3`
    # ja'i `CLL 4.2` le denpa cu stali
    check "ki'e.u'e".pausesRead == some(@[Pause.Absent, Pause.Written])  # `CLL 4.2`
    # `CLL 4.2` .e `Example 4.4`
    #   .i le cmavo cu cipma'o
    check "ki'e'u'e".wordsRead == some(@["ki'e'u'e"])  # `CLL 4.2`
    # `CLL 4.2` .e `Example 4.5`
    check "cy.ibu.abu".wordsRead == some(@["cy", "i", "bu", "a", "bu"])  # `CLL 4.2`
    check "cy.ibu.abu".pausesRead == some(@[
      Pause.Absent, Pause.Written, Pause.Absent, Pause.Written, Pause.Absent,
    ])  # `CLL 4.2` .e `Example 4.5` to le denpa cu bilga toi
    # `CLL 4.2` .e `Example 4.6`
    check ".e'o ko ko kurji".wordsRead == some(@["e'o", "ko", "ko", "kurji"])  # `CLL 4.2`
    check ".E'o ko ko KURji".stressesRead ==
        some(@[some(0), none(int), none(int), some(0)])  # `CLL 4.2` .e `Example 4.6`
    check "le re nanmu".wordsRead == some(@["le", "re", "nanmu"])  # `CLL 4.2` .e `Example 4.7`
    check "le RE. NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Written])  # `CLL 4.2` .e `Example 4.8`
    # ja'i `CLL 4.2` lo nu basna cu nitcu lo denpa to `CLL 3.3` toi
    check "le RE NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred])  # `CLL 4.2`
    # `CLL 4.2`
    #   .i re slaka poi se basna cu penmi
    #   .i le mumoi javni pe `CLL 4.9`
    #   .i le mupli cu selfi'i
    check "le RE LE nanmu".pausesRead == some(@[
      Pause.Absent, Pause.Absent, Pause.Inferred, Pause.Inferred,
    ])
    check "LE re NANmu".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Absent])  # `CLL 4.2` .e `Example 4.9`
    check "le re NANmu".stressesRead ==
        some(@[none(int), none(int), some(0)])  # `CLL 4.2` .e `Example 4.10`
    # ja'i `CLL 4.2` zoi gy. .y. .gy. se lidne lo denpa gi'e lidne lo denpa
    check "mi .y. klama".pausesRead ==
        some(@[Pause.Absent, Pause.Written, Pause.Written])  # `CLL 4.2`
    # ja'i `CLL 4.2` le denpa cu se facki to `CLL 3.3` toi
    #   .i le mupli cu selfi'i
    check "mi y klama".pausesRead ==
        some(@[Pause.Absent, Pause.Inferred, Pause.Inferred])  # `CLL 4.2`


  test "Section 4.7":
    for (text, word) in [("bang,r,kore,a", "bangrkorea"), ("kuln,r,kore,a", "kulnrkorea")]:
      # `CLL 4.7` .e `Example 4.55` .e `Example 4.56`
      #   .i slaka bu cu fendi `ea` pe le fu'ivla
      check text.wordsRead == some(@[word])  # `CLL 4.7`


  test "Section 4.8":
    for (text, words) in [
      ("djim.", @["djim"]), ("djein.", @["djein"]), (".arnold.", @["arnold"]),
      ("pit.", @["pit"]), ("katrinas.", @["katrinas"]), ("kat,r,in.", @["katrin"]),
      ("katis.", @["katis"]), ("keit.", @["keit"]), ("djan. braun.", @["djan", "braun"]),
      ("djanbraun.", @["djanbraun"]), ("pav.", @["pav"]), ("sol.", @["sol"]),
      ("ralj.", @["ralj"]), ("nol.", @["nol"]),
    ]:
      check text.wordsRead == some(words)  # `CLL 4.8` .e `Example 4.57` bi'o bo `Example 4.70`
    # `CLL 4.8` cusku zoi gy. look like Lojban words la plas. .gy.
    check "laplas.".wordsRead == some(@["la", "plas"])  # `CLL 4.8`
    # `CLL 4.8` cusku zoi gy. misunderstood as .i la nas. .gy.
    check "ilanas.".wordsRead == some(@["i", "la", "nas"])  # `CLL 4.8`
    # `CLL 4.8` cusku zoi gy. cannot be misheard .gy.
    check "NEderlants.".stressesRead == some(@[some(0)])  # `CLL 4.8`
    # le cmeste pe `CLL 4.8`
    #   .i zoi gy. Elise .gy.
    check ".eLIS.".stressesRead == some(@[some(1)])  # `CLL 4.8`
    # `CLL 4.8`
    #   .i zoi gy. Lech Walesa .gy.
    check "lex. va,uensas.".wordsRead == some(@["lex", "vauensas"])  # `CLL 4.8`
    # `CLL 4.7` .e `Example 4.45`
    check "me la spagetis.".wordsRead == some(@["me", "la", "spagetis"])  # `CLL 4.7`


  test "Section 4.9":
    # le pamoi javni
    #   .i lo denpa cu fendi lo valsi
    check "bri.vla".refusalRead == some((Refusal.Shape, 0))  # le pamoi javni
    check ".i mi klama".pausesRead ==
        # le mupli cu selfi'i
        some(@[Pause.Written, Pause.Absent, Pause.Absent])  # le cimoi javni
    # le xamoi javni
    #   .i le mupli cu selfi'i
    check "cy klama".pausesRead == some(@[Pause.Absent, Pause.Inferred])  # le xamoi javni
    # le xamoi javni
    #   .i lo valsi poi se lidne cu seltai zoi gy. Cy .gy.
    #   .i le mupli cu selfi'i
    check "cy ky klama".pausesRead ==
        some(@[Pause.Absent, Pause.Absent, Pause.Inferred])  # le xamoi javni
    check "la djan cu klama".pausesRead == some(@[
      Pause.Absent, Pause.Absent, Pause.Inferred, Pause.Absent,
    # zo la lidne no denpa
    #   .i le mupli cu selfi'i
    ])  # le remoi javni .e le vomoi javni
    # le vomoi javni
    #   .i le mupli cu selfi'i
    check "mi djan".pausesRead == some(@[Pause.Absent, Pause.Inferred])  # le vomoi javni
    # zo doi
    check "doi djan".pausesRead == some(@[Pause.Absent, Pause.Absent])  # le vomoi javni
    # le mumoi javni
    #   .i slaka bu cu rinka lo nu `A` zvati le slaka poi lidne le romoi slaka
    #   .i le mupli cu selkra lo nu lanli `#811`
    check "ku,Arka broda".pausesRead ==
        some(@[Pause.Absent, Pause.Absent])  # `#811`
    # le zemoi javni
    #   .i le selci'a poi se sitna cu mulno
    #   .i `CLL 19.10`
    check "zoi gy. John .gy.".wordsRead ==
        some(@["zoi", "gy", "John", "gy"])  # `CLL 19.10`
    check "zoi gy. John .gy.".pausesRead == some(@[
      Pause.Absent, Pause.Absent, Pause.Written, Pause.Written,
    ])  # le zemoi javni to le selci'a poi se sitna cu se lidne lo denpa gi'e lidne lo denpa toi
    check "zo zoi".wordsRead == some(@["zo", "zoi"])  # ja'i `CLL 19.10` zo zo sitna zo zoi
    # ja'i `CLL 19.9` le valsi cu se sitna
    check "lo'u zoi le'u".wordsRead == some(@["lo'u", "zoi", "le'u"])  # `CLL 19.9`
    # ja'i `CLL 19.10` no koivla cu zvati
    #   .i le mupli cu selfi'i
    check "mi zoi".refusalRead == some((Refusal.Quotation, 3))  # `CLL 19.10`
    # le zemoi javni
    #   .i zo la'o ji'a
    #   .i le mupli cu selfi'i
    check "mi cusku la'o gy. Mary .gy.".wordsRead ==
        some(@["mi", "cusku", "la'o", "gy", "Mary", "gy"])  # le zemoi javni
    # `CLL 19.10` .e `Example 19.50`
    #   .i le koivla cu zvati le selci'a
    check "zoi gy. gyrations .gy.".refusalRead ==
        some((Refusal.Quotation, 8))  # `CLL 19.10`
    # `CLL 19.10`
    #   .i le mupli cu selfi'i
    check "zoi gy. never closes".refusalRead == some((Refusal.Quotation, 0))  # `CLL 19.10`
    # ja'i `CLL 19.15` zo fa'o fanmo le selci'a
    check "mi fa'o 日本".wordsRead == some(@["mi", "fa'o"])  # `CLL 19.15`
    # ja'i `CLL 19.15` va'o lo nu zo fa'o na se sitna
    check "zo fa'o mi".wordsRead == some(@["zo", "fa'o", "mi"])  # `CLL 19.15`



func numberedRead(written: string): tuple[words: seq[string], refused: Option[int]] =
  ## tcidu `written` ja'i `D1 a` gi'e dunda lo valsi .a le stuzi pe slaka bu poi se to'e curmi
  ##   .i ro lerfu pe `0` bi'o `9` cu du pa valsi
  ##   .i denpa bu poi zvati lo jbini be re lerfu cu du pa valsi
  ##   .i denpa bu poi na zvati lo jbini be re lerfu cu fendi
  ##   .i slaka bu poi se lidne pa lerfu gi'e lidne ci lerfu po'o cu du pa valsi
  ##   .i slaka bu poi na mapti di'u cu se to'e curmi
  ##   .i le fancu cu ciska le javni ji'a gi'e pilno no fancu pe `stream.nim`
  for at, c in written:
    case c
    of '0' .. '9': result.words.add $c
    of '.':
      if at > 0 and written[at - 1] in Digits and at + 1 < written.len and
          written[at + 1] in Digits:
        result.words.add "."
    of ',':
      var count = 0
      while at + 1 + count < written.len and written[at + 1 + count] in Digits: inc count
      if at == 0 or written[at - 1] notin Digits or count != 3: return (result.words, some(at))
      result.words.add ","
    else: discard  # lo kutle'u cu fendi


func cmavoNumbered(word: string): string =
  ## dunda le cmavo poi le valsi pe `numberedRead` cu sinxa ke'a
  case word
  of ".": "pi"
  of ",": "ki'o"
  else: LUT_CMAVO_BY_DIGIT[ord(word[0]) - ord('0')]


func signedRead(pieces: openArray[string]): tuple[words: seq[string], refused: Option[int]] =
  ## tcidu le selci'a poi `pieces` zbasu ke'a ja'i `D1 a` .e `D2 a` .e `D3 a` pe `#1003`
  ##   .i dunda lo cmavo .a le stuzi pe le jdini sinxa poi se to'e curmi
  ##   .i ro pagbu cu cmima `MARKS_SIGNED`
  ##   .i lo jdini sinxa poi pencu pa namcu po'o cu sinxa lo jdini klani
  ##   .i ro namcu cu ponse su'e pa jdini sinxa ki'u lo nu lo jdini klani cu vasru lo valsi pe pa
  ##       sinxa po'o to `D2 a` toi
  ##   .i lo drata jdini sinxa cu se to'e curmi
  ##   .i ro lerfu po'u `a` cu du pa valsi
  ##   .i le fancu cu ciska le javni ji'a gi'e pilno no fancu pe `stream.nim`
  var
    starts: seq[int]  # le stuzi pe ro pagbu
    at = 0
    owners = -1.repeat(pieces.len)  # le jdini sinxa poi ponse ro lerfu ku'o .a `-1`
  for piece in pieces:
    starts.add at
    at += piece.len
  for k, piece in pieces:
    if piece notin ["$", "€", "¥"]: continue
    let
      is_after = k > 0 and pieces[k - 1] == "1"
      is_before = k + 1 < pieces.len and pieces[k + 1] == "1"
    if is_after == is_before: return (result.words, some(starts[k]))
    # le jdini sinxa cu ponse ro lerfu pe le namcu poi pencu ke'a
    var
      digits: seq[int]
      j = (if is_after: k - 1 else: k + 1)
    while j >= 0 and j < pieces.len and pieces[j] == "1":
      digits.add j
      j += (if is_after: -1 else: 1)
    if digits.anyIt(owners[it] >= 0): return (result.words, some(starts[k]))
    for d in digits: owners[d] = k
  for k, piece in pieces:
    if piece == "a": result.words.add "a"
    if piece != "1": continue
    let
      words =
        if owners[k] < 0: newSeq[string]()
        elif pieces[owners[k]] == "$": @["rupnu"]
        elif pieces[owners[k]] == "¥": @["ponjo", "ja", "jungo", "rupnu"]
        else: @["ronru'u"]
      is_first = k == 0 or pieces[k - 1] != "1"
      is_last = k == pieces.high or pieces[k + 1] != "1"
    if owners[k] >= 0 and is_first: result.words.add @["lo"] & words & @["be", "li"]
    result.words.add "pa"
    if owners[k] >= 0 and is_last: result.words.add @["be'o", "ku"]


func prefixedRead(pieces: openArray[string]): tuple[words: seq[string], refused: Option[int]] =
  ## tcidu le selci'a poi `pieces` zbasu ke'a ja'i `D4 b` .e `D2 a` .e `D3 a` pe `#1003`
  ##   .i dunda lo cmavo .a le stuzi pe le sinxa poi se to'e curmi
  ##   .i ro pagbu cu cmima `MARKS_PREFIXED`
  ##   .i zoi gy. - .gy. .e zoi gy. − .gy. cu se tcidu va'o lo nu lo lerfu po'u `1` cu se lidne le
  ##       sinxa kei .e lo nu no lerfu po'u `1` cu lidne le sinxa
  ##   .i zoi gy. % .gy. cu se tcidu va'o lo nu lo lerfu po'u `1` cu lidne le sinxa kei .e lo nu no
  ##       lerfu po'u `1` cu se lidne le sinxa
  ##   .i zoi gy. π .gy. .e zoi gy. ½ .gy. cu se tcidu va'o lo nu no lerfu po'u `1` .e no sinxa cu
  ##       pencu le sinxa
  ##   .i lo jdini sinxa cu se tcidu va'o lo nu le sinxa cu pencu lo lerfu po'u `1` pe pa namcu
  ##       po'o poi ponse no drata jdini sinxa
  ##   .i lo jdini klani cu vasru ro sinxa pe le namcu
  ##   .i ro lerfu po'u `a` cu du pa valsi
  ##   .i lo drata sinxa cu se to'e curmi
  ##   .i le fancu cu ciska le javni ji'a gi'e pilno no fancu pe `stream.nim`
  template isDigit(k: int): bool =
    ## jdice lo du'u le pagbu po'u `k` cu lerfu po'u `1`
    k >= 0 and k < pieces.len and pieces[k] == "1"
  template isSign(k: int): bool =
    ## jdice lo du'u le pagbu po'u `k` cu sinxa
    k >= 0 and k < pieces.len and pieces[k] in ["-", "−", "%", "π", "½", "€"]
  var
    starts: seq[int]  # le stuzi pe ro pagbu
    at = 0
    numbers: seq[Slice[int]]  # le pagbu pe ro namcu
    owned: seq[int]  # lo namcu poi lo jdini sinxa cu ponse ke'a
  for piece in pieces:
    starts.add at
    at += piece.len

  # le namcu cu porsi lo lerfu po'u `1` .e lo sinxa poi lidne ja se lidne le lerfu
  var first = 0  # le pamoi pagbu pe le namcu
  while first < pieces.len:
    if not isDigit(first) and not (pieces[first] in ["-", "−"] and isDigit(first + 1)):
      inc first
      continue
    var last = (if isDigit(first): first else: first + 1)
    while isDigit(last + 1): inc last
    if last + 1 < pieces.len and pieces[last + 1] == "%" and not isDigit(last + 2): inc last
    numbers.add first .. last
    first = last + 1

  # to'e curmi le pamoi sinxa poi na mapti le javni
  for k, piece in pieces:
    var is_read = true
    case piece
    of "-", "−": is_read = isDigit(k + 1) and not isDigit(k - 1)
    of "%": is_read = isDigit(k - 1) and not isDigit(k + 1)
    of "π", "½":
      is_read = not (isDigit(k - 1) or isSign(k - 1) or isDigit(k + 1) or isSign(k + 1))
    of "€":
      is_read = false
      if isDigit(k - 1) != isDigit(k + 1):
        for n, span in numbers:
          if (isDigit(k - 1) and span.b == k - 1) or (isDigit(k + 1) and span.a == k + 1):
            is_read = n notin owned
            owned.add n
    else: discard
    if not is_read: return (result.words, some(starts[k]))

  # ciska le cmavo
  for k, piece in pieces:
    var number = none(int)  # le namcu poi vasru le pagbu
    for n, span in numbers:
      if k in span: number = some(n)
    let is_amount = number.isSome and number.get in owned
    if is_amount and k == numbers[number.get].a:
      result.words.add @["lo", "ronru'u", "be", "li"]
    case piece
    of "a": result.words.add "a"
    of "1": result.words.add "pa"
    of "-", "−": result.words.add "ni'u"
    of "%": result.words.add "ce'i"
    of "π": result.words.add "pai"
    of "½": result.words.add @["pa", "fi'u", "re"]
    else: discard  # lo kutle'u .e lo jdini sinxa
    if is_amount and k == numbers[number.get].b: result.words.add @["be'o", "ku"]



suite "Internal: Stream":
  test "Each digit reads as word of PA that names it in 18.2, one word for each digit":
    for digit in '0' .. '9':
      let
        text = "li " & digit
        cmavo = LUT_CMAVO_BY_DIGIT[ord(digit) - ord('0')].readWord
      checkpoint text
      # pa valsi pe `PA` cu sinxa ro lerfu pe li 10
      check text.wordsRead == some(@["li", $digit])  # `CLL 18.2`
      check text.selmahoRead == some(@[some(Selmaho.Li), cmavo.selmaho])  # `CLL 18.2`
      check text.startsRead == some(@[0, 3])
    # lo lerfu pe li 10 cu fendi lo valsi poi lo lerfu pe la lojban. cu ciska ke'a
    check "li 1987".wordsRead == some(@["li", "1", "9", "8", "7"])
    check "li 1987".startsRead == some(@[0, 3, 4, 5, 6])
    check "li 1987".isSpanned
    check "li 1987".stressesRead == some(none(int).repeat(5))
    check "le 10moi".wordsRead == some(@["le", "1", "0", "moi"])
    check "pa3".wordsRead == some(@["pa", "3"])
    # le cipra po'u lo bavla'i cu cipra lo nu tcidu slaka bu .e denpa bu poi zvati lo jbini be re
    #     lerfu


  test "Period between two digits reads as pi, and comma before three digits as ki'o":
    # `Architect` jdice `D1 a` bu'u `#991`
    #   .i lo mupli po'u `CLL 18.6` .e `CLL 18.11` cu pilno zo pi .e zo ki'o ne'i lo namcu
    for (text, words, cmavo) in [
        ("li 3.14", @["li", "3", ".", "1", "4"], @["li", "ci", "pi", "pa", "vo"]),
        ("li 1,000", @["li", "1", ",", "0", "0", "0"], @["li", "pa", "ki'o", "no", "no", "no"]),
        ("li 1,234,567", @["li", "1", ",", "2", "3", "4", ",", "5", "6", "7"],
          @["li", "pa", "ki'o", "re", "ci", "vo", "ki'o", "mu", "xa", "ze"]),
        ("li 1,000.5", @["li", "1", ",", "0", "0", "0", ".", "5"],
          @["li", "pa", "ki'o", "no", "no", "no", "pi", "mu"]),
        ("le 1,000moi", @["le", "1", ",", "0", "0", "0", "moi"],
          @["le", "pa", "ki'o", "no", "no", "no", "moi"]),
        # slaka bu poi se lidne su'o vo lerfu cu du zo ki'o ji'a
        ("li 1234,567", @["li", "1", "2", "3", "4", ",", "5", "6", "7"],
          @["li", "pa", "re", "ci", "vo", "ki'o", "mu", "xa", "ze"])]:
      checkpoint text
      check text.wordsRead == some(words)  # `CLL 18.2`
      check text.cmavoRead == some(cmavo)  # `CLL 18.2`
      check text.startsRead == some(toSeq(0 ..< words.len).mapIt(if it == 0: 0 else: it + 2))
      check text.pausesRead == some(Pause.Absent.repeat(words.len))  # no denpa
    # slaka bu poi lidne lo drata be ci lerfu cu se to'e curmi to `CLL 3.3` toi
    for text in ["li 3,14", "li 1,2,3", "li 1,0000", "li 1,00"]:
      checkpoint text
      check text.refusalRead == some((Refusal.Comma, 4))  # `CLL 3.3`
    # denpa bu poi na zvati lo jbini be re lerfu cu sinxa lo denpa to `CLL 3.3` toi
    check "mi viska 3. do".pausesRead ==
      some(@[Pause.Absent, Pause.Absent, Pause.Absent, Pause.Written])  # `CLL 3.3`
    check "li .5".pausesRead == some(@[Pause.Absent, Pause.Written])  # `CLL 3.3`
    check "1.ai".pausesRead == some(@[Pause.Absent, Pause.Written])  # `CLL 3.3`


  test "Each text of digits, periods, commas and spaces after li reads as ruling D1 a reads it":
    # `Architect` jdice `D1 a` bu'u `#991`
    #   .i le flalu cu tcidu ro selci'a poi `MARKS_NUMBERED` cu zbasu ke'a
    #   .i `numberedRead` cu ciska le javni gi'e pilno no fancu pe `stream.nim`
    var
      count = 0
      written = @[""]  # ro selci'a poi le flalu cu tcidu ke'a ja'i le ni ke'a cu clani
    while written.len > 0:
      var longer: seq[string]
      for text in written:
        let (words, refused) = text.numberedRead
        checkpoint "li " & text
        if refused.isSome:
          # slaka bu poi na mapti `D1 a` cu se to'e curmi bu'u le stuzi pe vo'a
          let refusal = ("li " & text).refusalRead
          check refusal.isSome and refusal.get[1] == 3 + refused.get
        else:
          check ("li " & text).wordsRead == some(@["li"] & words)  # `CLL 18.2`
          check ("li " & text).cmavoRead == some(@["li"] & words.mapIt(it.cmavoNumbered))
        inc count
        if text.len < LENGTH_NUMBERED_MOST:
          for mark in MARKS_NUMBERED: longer.add text & mark
      written = longer
    check count == COUNT_NUMBERED  # `IX.3`


  test "Currency sign that touches one number reads as lo, its words, be li, number, be'o ku":
    # `Architect` jdice `D1 a` .e `D2 a` .e `D3 a` bu'u `#1003`
    #   .i le jdini sinxa cu ka'e lidne le namcu gi'a se lidne le namcu
    for (sign, words) in SIGNS_RULED:
      for text in [sign & "5", "5" & sign]:
        checkpoint text
        check text.cmavoRead == some(@["lo"] & words & @["be", "li", "mu", "be'o", "ku"])
        check text.pausesRead == some(Pause.Absent.repeat(words.len + 6))  # no denpa
    let amount = @[
      "lo", "ronru'u", "be", "li", "bi", "xa", "ki'o", "no", "no", "no", "ki'o", "ze", "no", "vo",
      "pi", "ze", "mu", "be'o", "ku",
    ]
    check "mi ponse €86,000,704.75".cmavoRead == some(@["mi", "ponse"] & amount)
    check "86,000,704.75€ cu jdima".cmavoRead == some(amount & @["cu", "jdima"])
    # lo lerfu poi se lidne le jdini klani gi'a lidne le jdini klani cu pagbu no klani
    check "5€moi".cmavoRead == some(@["lo", "ronru'u", "be", "li", "mu", "be'o", "ku", "moi"])
    check "ponse€5".cmavoRead == some(@["ponse", "lo", "ronru'u", "be", "li", "mu", "be'o", "ku"])
    # re jdini sinxa poi lamji cu sinxa re jdini klani ki'u lo nu ro le sinxa cu pencu pa namcu
    let five = @["lo", "ronru'u", "be", "li", "mu", "be'o", "ku"]
    check "5€€5".cmavoRead == some(five & five)
    # denpa bu poi lidne le jdini sinxa cu zvati zo lo
    check "xy. €5".pausesRead == some(@[Pause.Absent, Pause.Written] & Pause.Absent.repeat(6))


  test "Words that a sign stands for take no bytes, at first and last byte of its number":
    # le valsi cu vasru no stuzi gi'e zvati lo korbi be le namcu
    #   .i se ki'u bo le porsi be lo valsi cu mintu le porsi be lo stuzi
    check "€5".startsRead == some(@[3, 3, 3, 3, 3, 4, 4])
    check "€5".widthsRead == some(@[0, 0, 0, 0, 1, 0, 0])
    check "5€".startsRead == some(@[0, 0, 0, 0, 0, 1, 1])
    check "5€".widthsRead == some(@[0, 0, 0, 0, 1, 0, 0])
    check "mi ponse ci ¥5".startsRead == some(@[0, 3, 9, 14, 14, 14, 14, 14, 14, 14, 14, 15, 15])
    for (sign, _) in SIGNS_RULED:
      for text in [sign & "5", "5" & sign, "mi ponse " & sign & "1,000.5 .e " & sign & "2"]:
        checkpoint text
        check text.isSpanned  # le flalu pe lo stuzi


  test "Stream refuses as Sign, at its byte, sign that touches no number, two, or signed number":
    # `Architect` jdice lo du'u lo jdini sinxa poi pencu no namcu .a re namcu cu se to'e curmi
    #     bu'u `#1003` ta'i `D3 a`
    #   .i ji'a ro namcu cu ponse su'e pa jdini sinxa ki'u lo nu lo jdini klani cu vasru lo valsi
    #       pe pa sinxa po'o to `D2 a` toi
    for (text, at) in [
        ("€", 0), ("li €", 3), ("5 €", 2), ("€ 5", 0), ("5€6", 1), ("$5$", 2), ("€$5", 0),
        ("5€$", 4), ("€a5", 0), ("£", 0), ("¢ 5", 0), ("5¥5", 1), ("mi $a", 3), ("moi€", 3),
        ("5a€", 2), ("€.5", 0), ("5.€", 2)]:
      checkpoint text
      check text.refusalNamed == some(("Sign", at))
    # slaka bu poi na mapti `D1 a` pe `#991` cu se to'e curmi pu le jdini sinxa
    check "5,€".refusalRead == some((Refusal.Comma, 1))  # `CLL 3.3`


  test "Each text of digits, letters, signs and spaces reads as rulings D1 a, D2 a and D3 a read":
    # `Architect` jdice `D1 a` .e `D2 a` .e `D3 a` bu'u `#1003`
    #   .i le flalu cu tcidu ro selci'a poi `MARKS_SIGNED` cu zbasu ke'a
    #   .i `signedRead` cu ciska le javni gi'e pilno no fancu pe `stream.nim`
    var
      count = 0
      # ro selci'a poi le flalu cu tcidu ke'a ja'i le ni ke'a cu clani
      written = @[newSeq[string]()]
    while written.len > 0:
      var longer: seq[seq[string]]
      for pieces in written:
        let
          text = pieces.join
          (words, refused) = pieces.signedRead
        checkpoint text
        if refused.isSome: check text.refusalNamed == some(("Sign", refused.get))
        else: check text.cmavoRead == some(words)
        inc count
        if pieces.len < LENGTH_SIGNED_MOST:
          for mark in MARKS_SIGNED: longer.add pieces & mark
      written = longer
    check count == COUNT_SIGNED  # `IX.3`


  test "Sign before a number reads as ma'u, ni'u or ji'i where a digit follows, none before":
    # `Architect` jdice `D4 b` bu'u `#1003`
    #   .i lo sinxa cu pagbu le namcu poi le sinxa cu lidne ke'a to `CLL 18.3` .e `CLL 18.9` toi
    for (sign, word) in PREFIXES_RULED:
      for (text, cmavo) in [
          ("li " & sign & "5", @["li", word, "mu"]),
          ("li " & sign & "1,000.5", @["li", word, "pa", "ki'o", "no", "no", "no", "pi", "mu"]),
          ("mi" & sign & "5", @["mi", word, "mu"]), ("5 " & sign & "5", @["mu", word, "mu"])]:
        checkpoint text
        check text.cmavoRead == some(cmavo)
        check text.isSpanned  # le flalu pe lo stuzi
      # le valsi cu vasru ro stuzi pe le sinxa
      check ("li " & sign & "5").widthsRead == some(@[2, sign.len, 1])
      # le sinxa poi na lidne lo lerfu ku'o .a le sinxa poi se lidne lo lerfu cu se to'e curmi
      for (text, at) in [
          (sign, 0), ("li " & sign, 3), (sign & " 5", 0), ("5" & sign & "5", 1), ("5" & sign, 1),
          (sign & sign & "5", 0), (sign & "a5", 0), (sign & "π", 0), (sign & "∞", 0),
          (sign & "€5", 0), (sign & "$5", 0), ("€" & sign & "5", 0), (sign & ".5", 0)]:
        checkpoint text
        check text.refusalNamed == some(("Sign", at))


  test "Percent sign reads as ce'i right after a digit, where no digit follows":
    # `Architect` jdice `D4 b` bu'u `#1003`
    #   .i lo mupli po'u `CLL 18.10` cu pilno zo ce'i ba lo namcu
    for (text, cmavo) in [
        ("li 35%", @["li", "ci", "mu", "ce'i"]),
        ("li -2.5%", @["li", "ni'u", "re", "pi", "mu", "ce'i"]),
        ("le 35%moi", @["le", "ci", "mu", "ce'i", "moi"])]:
      checkpoint text
      check text.cmavoRead == some(cmavo)
      check text.isSpanned  # le flalu pe lo stuzi
    check "li 35%".widthsRead == some(@[2, 1, 1, 1])
    for (text, at) in [
        ("%", 0), ("li %", 3), ("5 %", 2), ("5%5", 1), ("%5", 0), ("5%%", 2), ("a%", 1),
        ("5.%", 2)]:
      checkpoint text
      check text.refusalNamed == some(("Sign", at))


  test "Constant sign reads as its words where no digit or other sign touches it":
    # `Architect` jdice `D4 b` bu'u `#1003`
    #   .i lo mupli po'u `CLL 18.7` .e `CLL 18.15` .e `CLL 18.18` cu pilno le cmavo
    for (sign, words) in CONSTANTS_RULED:
      for (text, cmavo) in [
          ("li " & sign, @["li"] & words), ("mi" & sign, @["mi"] & words),
          (sign & "moi", words & @["moi"])]:
        checkpoint text
        check text.cmavoRead == some(cmavo)
        check text.isSpanned  # le flalu pe lo stuzi
      # le pamoi valsi cu vasru ro stuzi pe le sinxa
      #   .i ro drata valsi cu vasru no stuzi gi'e cfari bu'u le stuzi poi se lidne le sinxa
      check ("li " & sign).startsRead == some(@[0, 3] & (3 + sign.len).repeat(words.len - 1))
      check ("li " & sign).widthsRead == some(@[2, sign.len] & 0.repeat(words.len - 1))
      for (text, at) in [
          ("2" & sign, 1), (sign & "2", 0), (sign & sign, 0), ("5%" & sign, 2),
          ("5€" & sign, 4), (sign & "€5", 0), (sign & "-5", 0), ("$" & sign, 0)]:
        checkpoint text
        check text.refusalNamed == some(("Sign", at))
    # lo kutle'u na fendi lo namcu to `CLL 18.6` toi
    #   .i se ki'u bo lo'u ci pa fi'u re le'u cu sinxa li 31 fi'u re lo'o to `CLL 18.7` toi
    check "li 3 ½".cmavoRead == some(@["li", "ci", "pa", "fi'u", "re"])


  test "Amount opens before the sign of its number":
    # `Architect` jdice `D2 a` bu'u `#1003` to le jdini klani cu vasru le namcu toi
    #   .i lo sinxa cu pagbu le namcu poi le sinxa cu lidne ke'a to `CLL 18.3` toi
    let amount = @["lo", "ronru'u", "be", "li", "ni'u", "mu", "be'o", "ku"]
    for (text, cmavo) in [
        ("-5€", amount), ("−5€", amount),
        ("mi ponse ~5¥", @["mi", "ponse", "lo", "ponjo", "ja", "jungo", "rupnu", "be", "li", "ji'i",
          "mu", "be'o", "ku"]),
        ("€5%", @["lo", "ronru'u", "be", "li", "mu", "ce'i", "be'o", "ku"]),
        ("5€-5", @["lo", "ronru'u", "be", "li", "mu", "be'o", "ku", "ni'u", "mu"])]:
      checkpoint text
      check text.cmavoRead == some(cmavo)
      check text.isSpanned  # le flalu pe lo stuzi
    check "-5€".startsRead == some(@[0, 0, 0, 0, 0, 1, 2, 2])
    check "-5€".widthsRead == some(@[0, 0, 0, 0, 1, 1, 0, 0])
    # le jdini sinxa cu pencu lo lerfu pe `0` bi'o `9` to `D3 a` toi
    for (text, at) in [("€-5", 0), ("$-5", 0), ("-€5", 0), ("5%€", 2)]:
      checkpoint text
      check text.refusalNamed == some(("Sign", at))
    # lo jdini sinxa poi se lidne lo namcu poi fanmo zoi gy. % .gy. cu krasi lo drata jdini klani
    let five = @["lo", "ronru'u", "be", "li", "mu"]
    check "€5%€5".cmavoRead == some(five & @["ce'i", "be'o", "ku"] & five & @["be'o", "ku"])
    check "€5%€5".isSpanned  # le flalu pe lo stuzi


  test "Each text of digits, letters, number signs and spaces reads as ruling D4 b reads it":
    # `Architect` jdice `D4 b` .e `D2 a` .e `D3 a` bu'u `#1003`
    #   .i le flalu cu tcidu ro selci'a poi `MARKS_PREFIXED` cu zbasu ke'a
    #   .i `prefixedRead` cu ciska le javni gi'e pilno no fancu pe `stream.nim`
    var
      count = 0
      # ro selci'a poi le flalu cu tcidu ke'a ja'i le ni ke'a cu clani
      written = @[newSeq[string]()]
    while written.len > 0:
      var longer: seq[seq[string]]
      for pieces in written:
        let
          text = pieces.join
          (words, refused) = pieces.prefixedRead
        checkpoint text
        if refused.isSome: check text.refusalNamed == some(("Sign", refused.get))
        else:
          check text.cmavoRead == some(words)
          check text.isSpanned  # le flalu pe lo stuzi
        inc count
        if pieces.len < LENGTH_PREFIXED_MOST:
          for mark in MARKS_PREFIXED: longer.add pieces & mark
      written = longer
    check count == COUNT_PREFIXED  # `IX.3`


  test "Words joined by spaces read as readWord reads each, at byte where each opens":
    var count = 0
    for words in STREAMS_RANDOM:
      let text = words.join(" ")
      # ja'i `CLL 3.3` lo kutle'u cu fendi lo valsi
      #   .i lo se tcidu cu mintu lo selci'a
      check text.wordsRead == some(words)  # `CLL 3.3`
      var
        starts: seq[int]
        at = 0
      for word in words:
        starts.add at
        at += word.len + 1
      check text.startsRead == some(starts)  # `CLL 3.3` to lo stuzi be ro valsi toi
      let reading = text.readStream
      if not reading.is_read: continue
      for i, occurrence in reading.occurrences:
        # `CLL 4.2` bi'o `CLL 4.6`
        #   .i lo klesi pe le girzu
        check occurrence.reading.kind == LUT_KIND_BY_WORD[words[i]]  # `CLL 4.2`
        if occurrence.reading.kind != Kind.Cmavo: continue
        # `CLL 20`
        #   .i lo selma'o poi le ma'oste cu dunda ke'a
        check occurrence.reading.selmaho ==
            some(LUT_SELMAHO_BY_CMAVO[words[i]])  # `CLL 20`
      inc count
    check count == SAMPLES  # `Article IX.3` to le bandu cu ralte ro porsi toi


  test "Each word ends past its last letter, and bytes it spans spell it":
    for words in STREAMS_RANDOM:
      for joint in [" ", ".", " . "]:
        # ja'i `CLL 3.3` lo sinxa cu fendi lo valsi gi'e zvati no valsi
        check words.join(joint).isSpanned  # `CLL 3.3`
    for text in WRITTEN_SPANNED:
      checkpoint text
      # `WRITTEN_SPANNED`
      #   .i slaka bu .e lo brale'u poi zvati lo valsi ku'o .e lo nu sitna
      check text.isSpanned  # `WRITTEN_SPANNED`


  test "Period between words reads as space, and writes pause before each":
    var count = 0
    for words in STREAMS_RANDOM:
      for joint in [".", " .", ". ", " . "]:
        let text = words.join(joint)
        # ja'i `CLL 3.3` no kutle'u cu seltcu va'o lo nu denpa bu cu zvati
        check text.wordsRead == some(words)  # `CLL 3.3`
        let pauses = text.pausesRead
        if pauses.isNone: continue
        # ja'i `CLL 3.3` denpa bu cu sinxa lo denpa
        check pauses.get[1 .. ^1].allIt(it == Pause.Written)  # `CLL 3.3`
        inc count
    check count == 4 * SAMPLES  # `Article IX.3` to le bandu cu ralte ro porsi pe ro jorne toi


  test "Pause is inferred where rule of 4.9 needs one, and absent elsewhere":
    for words in STREAMS_RANDOM:
      # le cimoi javni .e le xamoi javni pe `CLL 4.9`
      #   .i `CLL 4.2`
      check words.join(" ").pausesRead == some(words.pausesNeeded)  # `CLL 4.9`


  test "Stressed last syllable takes pause before brivla, or before stressed first syllable":
    var count = 0
    for words in STREAMS_RANDOM:
      var
        written: seq[string]
        is_stressed_last: seq[bool]
      for word in words:
        let is_marked =
          LUT_KIND_BY_WORD[word] == Kind.Cmavo and word[word.syllables[^1].a] != 'y'
        written.add(if is_marked: word.capitalized(word.syllables[^1]) else: word)
        is_stressed_last.add is_marked
      var pauses = words.pausesNeeded
      for i in 1 .. words.high:
        let
          is_brivla = LUT_KIND_BY_WORD[words[i]] in {Kind.Gismu, Kind.Lujvo}
          is_stressed_first = is_stressed_last[i] and words[i].syllables.len == 1
        if not is_stressed_last[i - 1] or not (is_brivla or is_stressed_first): continue
        if pauses[i] == Pause.Absent: inc count
        pauses[i] = Pause.Inferred
      # le mumoi javni pe `CLL 4.9`
      #   .i ja'i `CLL 4.2` re nu basna cu penmi
      check written.join(" ").pausesRead == some(pauses)  # `CLL 4.9`
    # le bandu cu ralte lo nu le javni cu se cipra
    check count >= FLOOR_STRESS  # `Article IX.3`


  test "Comma breaking syllables changes no word, and other comma is refused at its byte":
    var count_read, count_refused = 0
    for word in wordsEach():
      for at in 1 ..< word.len:
        let text = word[0 ..< at] & "," & word[at .. ^1]
        if word.isCommaAdmitted(at):
          # ja'i `CLL 3.3` slaka bu po'o na ka'e rinka lo nu re valsi cu frica
          check text.wordsRead == some(@[word])  # `CLL 3.3`
          inc count_read
        else:
          check text.refusalRead == some((Refusal.Comma, at))  # `CLL 3.3` .e `CLL 3.4`
          inc count_refused
    check count_read >= FLOOR_COMMA_READ  # `Article IX.3` to le bandu cu ralte so'e lo selcu'a toi
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu lo nu to'e curmi cu se cipra
    check count_refused >= FLOOR_COMMA_REFUSED  # `Article IX.3`


  test "Without capital, comma changes no word that text without it reads":
    var count, count_kept = 0
    for word in @WORDS_BORROWED & @WORDS_NAMED:
      let texts = word.wordsRead
      if texts.isNone: continue
      for at in 1 ..< word.len:
        if '\'' in [word[at - 1], word[at]]: continue
        let words = (word[0 ..< at] & "," & word[at .. ^1]).wordsRead
        # ja'i `CLL 3.3` lo valsi no roi frica ki'u slaka bu po'o
        #   .i `CLL 3.3` cusku zoi gy. differ solely because of .gy.
        check words.isNone or words == texts  # `CLL 3.3`
        inc count
        if words.isSome: inc count_kept
    # `Article IX.3`
    #   .i le bandu cu ralte ro lerfu po'u slaka bu pe ro valsi
    check count == COUNT_COMMA_MARKED  # `Article IX.3`
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu slaka bu poi se tcidu cu se cipra
    check count_kept >= FLOOR_COMMA_KEPT  # `Article IX.3`


  test "Comma grouping vowels of cmene, with capital on each syllable, reads that cmene so":
    var count = 0
    for word in WORDS_GROUPED:
      for at in 1 ..< word.len:
        if word[at - 1] notin VOWELS_SYLLABLE or word[at] notin VOWELS_SYLLABLE: continue
        for k, span in word.syllables(is_name = true, breaks = [at]):
          let
            marked = word.capitalized(span)
            text = marked[0 ..< at] & "," & marked[at .. ^1]
          # ja'i `CLL 3.5` slaka bu cu fendi lo karsna pe pa cmene
          check text.wordsRead == some(@[word])  # `CLL 3.5`
          # ja'i `CLL 4.8` lo brale'u cu ralte lo nu basna
          #   .i `CLL 4.8` cusku zoi gy. to preserve .gy.
          check text.stressesRead == some(@[some(k)])  # `CLL 4.8`
          inc count
    check count == COUNT_GROUPED  # `Article IX.3` to le bandu cu ralte ro slaka pe ro nu fendi toi


  test "Stress comma leaves penultimate takes no pause before brivla after it":
    var count = 0
    for word in WORDS_BORROWED:
      for at in 1 ..< word.len:
        if word[at - 1] notin VOWELS_SYLLABLE or word[at] notin VOWELS_SYLLABLE: continue
        let spans = word.syllables(is_borrowing = true, breaks = [at])
        if spans.len < 2: continue
        let
          marked = word.capitalized(spans[^2])
          text = marked[0 ..< at] & "," & marked[at .. ^1] & " broda"
          pauses = text.pausesRead
        if pauses.isNone: continue  # slaka bu cu fendi no slaka poi lo fu'ivla cu curmi ke'a
        # le mumoi javni pe `CLL 4.9` nitcu lo romoi slaka poi se basna
        check pauses.get[1] == Pause.Absent  # `CLL 4.9`
        inc count
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu lo fu'ivla poi se basna cu se cipra
    check count >= FLOOR_COMMA_STRESS  # `Article IX.3`


  test "Comma between two cmavo that need pause is refused at comma":
    var count = 0
    randomize(4)
    for _ in 1 .. SAMPLES_COMMA_PAUSE:
      let words = @[WORDS_CMAVO.sample, WORDS_CMAVO.sample]
      if words.pausesNeeded[1] == Pause.Absent or words.anyIt('.' in it): continue
      # ja'i `CLL 3.3` slaka bu na ka'e selba'u ta'i lo denpa
      #   .i `CLL 3.3` cusku zoi gy. cannot be pronounced as pause .gy.
      check (words[0] & "," & words[1]).refusalRead ==
          some((Refusal.Comma, words[0].len))  # `CLL 3.3`
      inc count
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu lo denpa cu se cipra
    check count >= FLOOR_COMMA_PAUSE  # `Article IX.3`


  test "Capital on penultimate syllable of brivla reads, and on any other never reads as it":
    var count_read, count_refused, count_other = 0
    for word in concat(WORDS_GISMU, WORDS_LUJVO):  # ro gismu .e ro cunjvo
      let
        spans = word.syllables
        counted = toSeq(0 .. spans.high).filterIt(word[spans[it].a] != 'y')
      for k, span in spans:
        let text = word.capitalized(span)
        if k == counted[^2]:
          # ja'i `CLL 3.9` le slaka poi lidne le romoi slaka
          #   .i `y` na se kancu
          check text.stressesRead == some(@[some(k)])  # `CLL 3.9`
          inc count_read
          continue
        let reading = text.readStream
        if not reading.is_read:
          # ja'i `CLL 3.9` le nu to'e curmi cu zvati le brale'u
          #   .i ja ja'i `CLL 4.1` lo datyvelfendi cu mintu
          check (reading.refusal == Refusal.Stress and reading.start == span.a) or
              reading.refusal == Refusal.Split  # `CLL 3.9`
          inc count_refused
          continue
        let texts = reading.occurrences.mapIt(it.text)
        # ja'i `CLL 3.9` lo nu basna poi na drani cu rinka lo srera
        #   .i `CLL 3.9` cusku zoi gy. errors in word resolution .gy.
        check texts != @[word]  # `CLL 3.9`
        check texts.join("") == word  # ja'i `CLL 4.1` lo datyvla cu fendi lo lerfu pe le valsi
        for occurrence in reading.occurrences:
          if occurrence.stress.isNone or occurrence.reading.kind notin KINDS_BRIVLA: continue
          let is_borrowing = occurrence.reading.kind == Kind.Fuhivla
          # ja'i `CLL 3.9` le brale'u cu mapti le brivla poi se tcidu
          check occurrence.stress ==
              some(occurrence.text.penultimate(is_borrowing))  # `CLL 3.9`
        inc count_other
    # `Article IX.3`
    #   .i ne'i ro valsi pa nu basna cu se tcidu
    check count_read == WORDS_GISMU.len + WORDS_LUJVO.len  # `Article IX.3`
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu lo nu to'e curmi cu se cipra
    check count_refused >= FLOOR_STRESS_REFUSED  # `Article IX.3`
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu lo datyvla cu se cipra
    check count_other >= FLOOR_STRESS_OTHER  # `Article IX.3`


  test "Capital on syllable of word holding on-glide reads one brivla on penultimate alone":
    var count, count_read = 0
    for pair in DIPHTHONGS_ON:
      for frame in FRAMES_GLIDE:
        let
          word = frame.replace("_", pair)
          spans = word.syllables(is_borrowing = true)
        for k, span in spans:
          let reading = word.capitalized(span).readStream
          inc count
          if not reading.is_read or reading.occurrences.len != 1: continue
          if reading.occurrences[0].reading.kind notin KINDS_BRIVLA: continue
          # ja'i `CLL 3.4` lo karsna gunma cu du pa slaka
          #   .i ja'i `CLL 3.9` le slaka poi lidne le romoi slaka
          check k == spans.len - 2  # `CLL 3.4`
          inc count_read
    # le bandu cu ralte ro slaka pe ro greku
    check count == COUNT_GLIDE_CAPITALS  # `Article IX.3`
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu lo brivla cu se cipra
    check count_read >= FLOOR_GLIDE_READ  # `Article IX.3`


  test "Capital on each syllable of cmene holding iy or uy stresses that syllable":
    var count = 0
    for pair in DIPHTHONGS_NAME:
      for frame in FRAMES_NAME:
        let word = frame.replace("_", pair)
        for k, span in word.syllables(is_name = true):
          # `CLL 3.4`
          #   .i ja'i `CLL 3.9` ro slaka cu ka'e se basna
          check word.capitalized(span).stressesRead == some(@[some(k)])  # `CLL 3.4`
          inc count
    # le bandu cu ralte ro slaka pe ro greku
    check count == COUNT_NAME_CAPITALS  # `Article IX.3`


  test "Capital on any vowel of cmavo stresses that syllable, and capital on y is refused":
    for word in WORDS_CMAVO:
      for k, span in word.syllables:
        let text = word.capitalized(span)
        if word[span.a] == 'y':
          # ja'i `CLL 3.9` zoi gy. y .gy. no roi se basna
          check text.refusalRead == some((Refusal.Stress, span.a))  # `CLL 3.9`
        else:
          # ja'i `CLL 3.9` ro slaka pe lo cmavo cu ka'e se basna
          check text.stressesRead == some(@[some(k)])  # `CLL 3.9`


  test "Words needing no pause, written together, read back as them where brivla stands last":
    var count_joined, count_other = 0
    randomize(2)
    for _ in 1 .. SAMPLES_JOINED:
      var words: seq[string]
      for i in 1 .. rand(2 .. 3):
        words.add(if i == 1 or rand(1) == 0: WORDS_CMAVO.sample else: WORDS_GISMU.sample)
      if words.pausesNeeded[1 .. ^1].anyIt(it != Pause.Absent): continue
      let
        text = words.join("")
        texts = text.wordsRead
      if words.isStressFit(words.mapIt(LUT_KIND_BY_WORD[it])):
        # `D3 a` pe `#811`
        #   .i ja'i `CLL 4.1` pa ve fendi po'o
        check texts == some(words) or texts == some(@[text])  # `#811`
        if texts == some(words): inc count_joined
      else:
        # `D3 a` pe `#811`
        #   .i lo brivla poi lidne lo fanmo cu nitcu lo brale'u
        check texts != some(words)  # `#811`
        inc count_other

      # lo brale'u pe ro brivla cu sinxa ro nu basna
      #   .i se ki'u bo le genturfa'i cu raptcidu le valsi
      var marked: seq[string]
      for word in words:
        if LUT_KIND_BY_WORD[word] == Kind.Cmavo:
          marked.add word
          continue
        marked.add word.capitalized(word.syllables[word.penultimate(false)])
      # `D3 a` pe `#811`
      #   .i ja'i `CLL 3.9` lo brale'u cu sinxa lo nu basna
      check marked.join("").wordsRead == some(words)  # `#811`
    # `Article IX.3`
    #   .i le bandu cu ralte lo porsi poi selraptcidu
    check count_joined >= FLOOR_JOINED  # `Article IX.3`
    # `Article IX.3`
    #   .i le bandu cu ralte lo nu lo brivla poi lidne lo fanmo cu se cipra
    check count_other >= FLOOR_JOINED_OTHER  # `Article IX.3`


  test "Stream of marks alone reads as no words":
    for text in ["", " ", ".", " .\t. \n"]:
      # ja'i `CLL 3.3` lo sinxa cu fendi lo valsi gi'e na valsi
      check text.wordsRead == some(newSeq[string]())  # `CLL 3.3`


  test "Refusal names byte where offending word opens":
    # le cimoi javni pe `CLL 4.9`
    #   .i lo ve fendi cu mintu
    #   .i le mupli cu selfi'i
    check "mi klama iai".refusalRead == some((Refusal.Split, 9))  # `CLL 4.9`
    # `CLL 4.7`
    #   .i le mupli cu selfi'i
    check "mi klama ktraile".refusalRead == some((Refusal.Cluster, 9))  # `CLL 4.7`
    # ja'i `CLL 3.4` le valsi cu vasru no slaka
    #   .i le mupli cu selfi'i
    check "mi klama c".refusalRead == some((Refusal.Shape, 9))  # `CLL 3.4`


  test "Written word splits where one split needs fewest pauses, and tie is refused as Split":
    # ja'i `CLL 4.1` pa ve fendi po'o
    #   .i le mupli cu selkra `Tatoeba`
    check "secusku".wordsRead == some(@["se", "cusku"])  # `CLL 4.1`
    # ja'i `CLL 3.3` le genturfa'i cu facki le denpa poi denpa bu cu sinxa ke'a ne'i `Example 4.3`
    check "ki'eu'e".wordsRead == some(@["ki'e", "u'e"])  # `CLL 3.3`
    # le cimoi javni pe `CLL 4.9`
    check "ki'eu'e".pausesRead == some(@[Pause.Absent, Pause.Inferred])  # `CLL 4.9`
    # ja'i `CLL 3.3` le genturfa'i cu facki lo denpa poi denpa bu na sinxa ke'a
    #   .i le mupli cu selfi'i
    check "cia".wordsRead == some(@["ci", "a"])  # `CLL 3.3`
    # le mumoi pagbu be le tadji pe `CLL 4.11`
    #   .i `CLL 4.11` cusku zoi gy. will break up .gy.
    check "tosmabru".wordsRead == some(@["to", "smabru"])  # `CLL 4.11`
    # ja'i `CLL 3.9` lo nu basna cu jdice le stuzi be le brivla
    check "miBROda".wordsRead == some(@["mi", "broda"])  # `CLL 3.9`
    # ja'i `CLL 3.9` lo nu basna pe le gismu po'u `mibro`
    check "MIbroda".wordsRead == some(@["mibro", "da"])  # `CLL 3.9`
    # ja'i `CLL 3.9` lo nu basna cu mapti zo klama po'o
    check "KLAmaku".wordsRead == some(@["klama", "ku"])  # `CLL 3.9`
    # ja'i `CLL 4.7` pa fu'ivla
    #   .i le mupli cu selfi'i
    check "klamaku".wordsRead == some(@["klamaku"])  # `CLL 4.7`
    # `D3 a` pe `#811`
    #   .i le slaka po'o poi lidne le romoi slaka pe le selci'avla
    check "mibroda".wordsRead == some(@["mi", "broda"])  # `#811`
    check "lonubroda".wordsRead == some(@["lo", "nu", "broda"])  # `D3 a` pe `#811`
    # `CLL 4.1` .e `Example 19.78`
    #   .i zoi gy. breaks up .gy.
    check ".esperanto".wordsRead == some(@["e", "speranto"])  # `CLL 4.1`
    # le cimoi javni pe `CLL 4.9`
    #   .i `.i.ai` .a `.ia.i`
    check "iai".refusalRead == some((Refusal.Split, 0))  # `CLL 4.9`
    # ja'i `CLL 3.3` slaka bu na sinxa lo denpa
    #   .i le mupli cu selfi'i
    check "ka,i".refusalRead == some((Refusal.Comma, 2))  # `CLL 3.3`
