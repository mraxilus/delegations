## cipra lo du'u le galfi samtci pe `tools/lists.nim` zukte ja'i le javni be le galfi samtci
##   .i le galfi samtci cu tcidu lo valsi jo'u lo rafsi vu'o pe le gimste ra'i lo stuzi be le
##       datnypau gi'e tcidu lo valsi jo'u lo selma'o vu'o pe le ma'oste ra'i lo stuzi be le
##       datnypau
##   .i ro linji pe lo samtci datnyvei poi selci'a cu vasru su'e panono stuzi
##   .i lo cipra cu raptcidu le samtci datnyvei
##   .i va'o lo nu le liste poi selra'e cu selrapci'a kei le jalge cu mintu le samtci datnyvei poi
##       selra'e
##   .i cipra lo du'u le tcidu be lo datselci'a be'o to `texts_outside.nim` toi cu dratcidu lo linji
##
## ni'o `CLL` casnu no valsi liste datnyvei
##   .i se ki'u bo lo cmene be le vi cipra cu cfari fi `Internal:`
##   .i lo cmene be ro cipra cu skicu lo nu le se cipra cu zukte to `Article IX.10` toi
##
## ni'o ro mupli'i cu fukpi pa linji pe `gismu.txt` .a `cmavo.txt` .a `lujvo.txt` vu'o poi lo
##     snina'u cu stosni ke'a
##   .i ro stuzi pe le mupli'i cu mintu lo stuzi pe le linji
##   .i ku'i lo lerfu po'u `carriage return` selvi'u ta'i lo nu `readSource` vimcu le lerfu
##   .i lo pinka be ro mupli'i cu cusku le linji poi le mupli'i cu fukpi ke'a
##
## ni'o re cipra cu karbi le liste poi selra'e ku'o le liste poi selpu'i
##   .i va'o lo nu `lojban-common` na zvati gi'a na mapti le stosni kei ro le re cipra cu na zukte
##       gi'e cusku lo krinu to `Article IX.9` toi
##   .i lo minde po'u `system` cusku le bakfu
##   .i se ki'u bo `CI` punji le bakfu
##
## ni'o ro cunstecmi cu vasru pa valsi .e su'e ci rafsi
##   .i le valsi cu vasru su'o pa lerfu .e su'e mu lerfu
##   .i ro le rafsi cu vasru ci lerfu .a vo lerfu
##   .i ro lerfu pe le stecmi cu selcu'a fi lo jbole'u jo'u lo lerfu po'u zoi gy. ' .gy. ge'u ta'i
##       lo nu lo stecmi poi selra'e cu vasru lo mintu lerfu to `Article IX.4` toi
##
## ni'o ro cunstecmi pe le ma'oste cu vasru pa valsi .e pa selma'o
##   .i le valsi cu vasru su'o pa lerfu .e su'e bi lerfu
##   .i le selma'o cu ka'e du ro selma'o pe `CLL 20`
##
## ni'o ba lo nu dunda lo tsiju pa roi kei lo mupli cu selcu'a gi'e selpu'i fi pa vasru poi selzba
##     pa roi
##   .i `served` dunda le mupli

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, os, random, sequtils, strutils, sugar, unittest]

import ../../src/ricysoho/[entries, selmaho]
import ../../src/ricysoho/lists/[cmavo, gismu]
import ../../tools/lists
import ./texts_outside


const
  SEED = 1997
    ## lo tsiju be ro cuncu'a
    ##   .i le tsiju cu du lo namcu pe lo nanca poi `CLL` pamoi se cupra ca ke'a
  SAMPLES = 200
    ## lo te kancu be lo cunso liste cmima
    ##   .i ro javni cu se cipra ne'i le cunstecmi
  WIDTH = 100
    ## lo jimte be lo stuzi pe pa linji ja'i `Article X.1`
    ##   .i ro linji poi selci'a cu na zmadu le jimte
  LETTERS_LOJBAN = {'a'..'z', '\''}
    ## lo lerfu poi lo valsi .e lo rafsi vu'o pe le liste cu vasru ke'a
  LETTERS_RANDOM = "abcdefgijklmnoprstuvxyz'"
    ## lo lerfu poi lo cunvla .e lo cunrafsi cu selcu'a fi ke'a
  TEXT_MODULE_GISMU = staticRead("../../src/ricysoho/lists/gismu.nim")
    ## le datnyvei pe le gimste zi'e poi selra'e ku'o ta'i lo lerpoi

  LINE_HEADER =
      " 01436 Lojban                  gismu list  9/26/94        01436 Draft dictionary " &
      "rebaseline posted for review; Logflash format compatible Note: Metaphor usage risks " &
      "cultural neutrality; physical attributes are safest. Use place structures.  rafsi " &
      "list baselined as of this date.  Note: a complete set can be partially specified " &
      "with etcetera (ce zo'e)"
    ## le pamoi linji pe `gismu.txt`
    ##   .i le linji cu stedu
    ##   .i le galfi samtci cu na tcidu le linji
  LINE_BACRU =
      " bacru         ba'u utter                                     x1 utters " &
      "verbally/says/phonates/speaks [vocally makes sound] x2                              " &
      "   1h 386    [also voices; does not necessarily imply communication or audience; " &
      "('says' is usually cusku)]; (cf. krixa, cusku, casnu, tavla, voksa, pinka)"
    ## le remoi linji pe `gismu.txt`
    ##   .i zo bacru
    ##   .i pa rafsi poi seltai `CV'V` zvati le cimoi stuzi
  LINE_BAKFU =
      " bakfu baf          bundle               'pack'               x1 is a " &
      "bundle/package/cluster/clump/pack [shape/form] containing x2, held together by x3   " &
      "     9b   3    (cf. daski, dakli, tanxe)"
    ## le xamoi linji pe `gismu.txt`
    ##   .i zo bakfu
    ##   .i le linji cu vasru pa djuvla poi se sitna
  LINE_BI =
      " bi    biv          8                                         digit/number: 8 " &
      "(digit)                                                                          3a " &
      "  0"
    ## le vomumoi linji pe `gismu.txt`
    ##   .i le cmavo po'u zo bi noi ponse lo rafsi
  LINE_BLOTI =
      " bloti lot blo lo'i boat                                      x1 is a " &
      "boat/ship/vessel [vehicle] for carrying x2, propelled by x3                         " &
      "     7f  33    (cf. falnu, fulta, marce, jatna, sabnu)"
    ## le xamumoi linji pe `gismu.txt`
    ##   .i zo bloti
    ##   .i ro stuzi be lo rafsi cu culno
  LINE_CUKTA =
      " cukta     cku      book                                      x1 is a book " &
      "containing work x2 by author x3 for audience x4 preserved in medium x5              " &
      "1f 163    [x1 is a manifestation/container [a physical object or its analogue] of a " &
      "work/content, not necessarily using paper (= selpapri)]; (cf. cfika, prina, prosa, " &
      "tcidu, papri)"
    ## le revozemoi linji pe `gismu.txt`
    ##   .i zo cukta
    ##   .i le linji cu vasru pa rafsi po'o noi seltai `CCV`
  LINE_DATNI =
      " datni              data                                      x1 (du'u) " &
      "[fact/measurement] is data/information/statistic(s) about x2 gathered by method x3  " &
      "   8b  14    [evidence (= velji'i datni or just velji'i, sidydatni)] (cf. fatci, " &
      "saske, vreji)"
    ## le resonomoi linji pe `gismu.txt`
    ##   .i zo datni
    ##   .i le linji cu vasru no rafsi
  LINE_VREJI =
      " vreji rej     vei  record                                    x1 is a record of x2 " &
      "(data/facts/du'u) about x3 (object/event) preserved in medium x4            8c   4  " &
      "  (cf. sorcu, datni, papri)"
    ## le pacicicimoi linji pe `gismu.txt`
    ##   .i zo vreji
    ##   .i le linji cu vasru pa rafsi poi seltai `CVC` ku'o .e pa rafsi poi seltai `CVV`
  LINES_GISMU = [LINE_BACRU, LINE_BAKFU, LINE_BI, LINE_BLOTI, LINE_CUKTA, LINE_DATNI, LINE_VREJI]
    ## lo mupli'i pe `gismu.txt` zi'e poi se lidne le stedu ku'o ta'i le porsi pe le datnyvei
  TEXT_GISMU = LINE_HEADER & "\n" & LINES_GISMU.join("\n") & "\n"
    ## lo mupli be `gismu.txt`
    ##   .i le mupli cu vasru le stedu .e ro mupli'i
    ##   .i le stedu cu lidne ro mupli'i
  EXPECTED_GISMU = [
    EntryGismu(word: "bacru", rafsi: @["ba'u"]),
    EntryGismu(word: "bakfu", rafsi: @["baf"]),
    EntryGismu(word: "bi", rafsi: @["biv"]),
    EntryGismu(word: "bloti", rafsi: @["lot", "blo", "lo'i"]),
    EntryGismu(word: "cukta", rafsi: @["cku"]),
    EntryGismu(word: "datni", rafsi: @[]),
    EntryGismu(word: "vreji", rafsi: @["rej", "vei"]),
  ]
    ## lo stecmi pe ro mupli'i
    ##   .i lo prenu cu tcidu lo datnypau lo stuzi pe `entries.nim`
  LINE_BAARMOA = "ba'armo'a:barna+morna:pattern of marks:$morna1 $morna2 $=barna1 $morna3 $barna2"
    ## le pamoi linji pe `lujvo.txt`
    ##   .i le tanru pe le linji cu lojbo
  LINE_BADGAI =
      "badgai#defend+cover: protective cover/ shield:$bandu1 $=gacri1 $bandu2 $=gacri1 " &
      "$bandu3"
    ## le pavomoi linji pe `lujvo.txt`
    ##   .i le tanru pe le linji cu vasru lo glikikyvla
    ##   .i `#` lidne le tanru
  LINE_DATNYVEI =
      "datnyvei:datni+vreji:file (incl. computers):$vreji1 $vreji2 $=datni2 $vreji3 " &
      "$vreji4 [ = manner of encoding]"
    ## le xacivomoi linji pe `lujvo.txt`
    ##   .i zo datnyvei
    ##   .i le tanru pe le linji cu lojbo
  LINE_FEBJICLA = "febjicla#boil+stir:roil:roil:$jicla1 $jicla2 $=febvi1"
    ## le bivopamoi linji pe `lujvo.txt`
    ##   .i le tanru cu glico
    ##   .i lo smuvla cu selci'a re roi
    ##   .i le pamoi cu selra'e
  LINE_CIMNALSRA = "cimnalsra:foldi::cilmo+na'e+srasu foldi marsh"
    ## le cixanomoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru pa pagbu
    ##   .i lo smuvla cu kunti
  LINE_SEZYPEVDUA =
      "sezypevdu'a:sevzi+[figurative::]+dunda to dedicate oneself to someone/something, to " &
      "give oneself away"
    ## le rebivobimoi linji pe `lujvo.txt`
    ##   .i lo lerfu po'u zoi gy. : .gy. zvati lo jbini be zoi gy. [ .gy. jo'u zoi gy. ] .gy.
    ##   .i lo smuvla cu kunti
  LINE_JGETERJOE = "jgeterjo'e#knot+3rd-place-of+joined"
    ## le parecibimoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru `#` .e no lerfu po'u zoi gy. : .gy.
    ##   .i se ki'u bo le linji cu vasru no smuvla
  LINE_CIERSMITAI =
      "ci'ersmitai#system+similar+shape:$tarmi1 $=simsa1 $tarmi2 $=simsa2 $ciste1 $=simsa3"
    ## le cireremoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru `#`
    ##   .i lo smuvla cu du lo porsi be lo terbri
  LINE_PEVYSOASELTAI =
      "pevyso'aseltai#[figurative:]+egg+2nd-place-of+shape:egg-shaped:$tarmi2 $tarmi1"
    ## le rerexapamoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru `#`
    ##   .i lo lerfu po'u zoi gy. : .gy. zvati lo jbini be zoi gy. [ .gy. jo'u zoi gy. ] .gy.
  LINE_DATKYPIU = "datkypi'u gairki'e:datka+pimlu gacri+kicne:eiderdown [quilt]"
    ## le xacinomoi linji pe `lujvo.txt`
    ##   .i le linji cu ciska lo jufpau ne'i lo stuzi be lo valsi
    ##   .i lo kutle'u cu zvati ne'i le jufpau
  LINE_JAIRTAI = "jairtai:denmi:xance jgari+tarmi denmi xance:fist:$tarmi1 (omit $tarmi2 $=jgari3)"
    ## le panosopamoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru mu datnypau
    ##   .i le tanru cu vasru pa pagbu
  LINE_BLOTI_ZERLEA = "bloti zerle'a:bloti zekri+lebna:pirate:"
    ## le pamunomoi linji pe `lujvo.txt`
    ##   .i le linji cu ciska lo jufpau ne'i lo stuzi be lo valsi
    ##   .i lo lerfu po'u zoi gy. : .gy. fanmo lo smuvla
  LINE_NALSUTYDZUKEPKLA =
      "nalsutydzukepkla:na'e+sutra+cadzu+,+klama:to go without walking fast:$klama1 " &
      "$klama2 $klama3 $klama4 $klama5"
    ## le renonobimoi linji pe `lujvo.txt`
    ##   .i `,` zvati lo jbini be lo pagbu
  LINES_LUJVO = [
    LINE_BAARMOA, LINE_BADGAI, LINE_DATNYVEI, LINE_FEBJICLA, LINE_CIMNALSRA, LINE_SEZYPEVDUA,
    LINE_JGETERJOE, LINE_CIERSMITAI, LINE_PEVYSOASELTAI, LINE_DATKYPIU, LINE_JAIRTAI,
    LINE_BLOTI_ZERLEA, LINE_NALSUTYDZUKEPKLA,
  ]
    ## lo mupli'i pe `lujvo.txt`
    ##   .i ro tarmi poi le tcidu be lo datselci'a cu penmi ke'a tarmi pa mupli'i
  EXPECTED_LUJVO = [
    LineLujvo(word: "ba'armo'a", is_english: false, parts: @["barna", "morna"]),
    LineLujvo(word: "badgai", is_english: true, parts: @["defend", "cover"]),
    LineLujvo(word: "datnyvei", is_english: false, parts: @["datni", "vreji"]),
    LineLujvo(word: "febjicla", is_english: true, parts: @["boil", "stir"]),
    LineLujvo(word: "cimnalsra", is_english: false, parts: @[]),
    LineLujvo(word: "sezypevdu'a", is_english: false, parts: @[]),
    LineLujvo(word: "jgeterjo'e", is_english: true, parts: @["knot", "3rd-place-of", "joined"]),
    LineLujvo(word: "ci'ersmitai", is_english: true, parts: @["system", "similar", "shape"]),
    LineLujvo(word: "pevyso'aseltai", is_english: true, parts: @[]),
    LineLujvo(word: "jairtai", is_english: false, parts: @[]),
    LineLujvo(word: "nalsutydzukepkla", is_english: false, parts: @[]),
  ]
    ## lo se tcidu pe ro mupli'i poi lo valsi pe ke'a gunma lo lerfu po'o
    ##   .i lo prenu cu tcidu le se tcidu
    ##   .i va'o lo nu le linji cu ciska su'o re pagbu kei le se tcidu cu vasru le pagbu
    ##   .i ro jbopau cu gunma lo lerfu po'o
  LINE_HEADER_CMAVO =
      "01090 Lojban         LogFlash cmavo list 26 August 2002 -- added va'e        01090"
    ## le pamoi linji pe `cmavo.txt`
    ##   .i le linji cu stedu
    ##   .i le galfi samtci cu na tcidu le linji
  LINE_A =
      ".a         A        sumti or                                  logical connective: su" &
      "mti afterthought or"
    ## le remoi linji pe `cmavo.txt`
    ##   .i `.a`
    ##   .i lo lerfu po'u denpa bu cu lidne lo karsna
  LINE_AACUHI =
      ".a'acu'i   UI*1     inattentive                               attitudinal: attentive" &
      " - inattentive - avoiding"
    ## le vomoi linji pe `cmavo.txt`
    ##   .i `.a'acu'i` noi ma'orgunma
    ##   .i `*` se lidne lo selma'o
  LINE_BAHE =
      " ba'e      BAhE     emphasize next                            forethought emphasis i" &
      "ndicator; indicates next word is especially emphasized"
    ## le rezemoi linji pe `cmavo.txt`
    ##   .i `ba'e`
    ##   .i le selma'o po'u `BAhE` vasru `h`
  LINE_BIHU =
      " bi'u      UI3a     new information                           discursive: newly intr" &
      "oduced information - previously introduced information                              " &
      "(cf. nindatni, saurdatni)"
    ## le muremoi linji pe `cmavo.txt`
    ##   .i `bi'u`
    ##   .i lo klesi po'u `3a` se lidne le selma'o
  LINE_CINO =
      " cino      PA*      30                                        number/quantity: 30 [t" &
      "hirty]"
    ## le panopamoi linji pe `cmavo.txt`
    ##   .i `cino`
    ##   .i le ma'orgunma cu vasru re cmavo be `PA`
  LINE_LE_GOHI =
      " le go'i   KOhA*    the x1 of last bridi                      description pro-sumti:" &
      " reuses the value of the x1 of the previous bridi"
    ## le vonobimoi linji pe `cmavo.txt`
    ##   .i `le go'i` noi jufpau gi'e vasru re valsi
  LINE_YHY =
      ".y'y       BY2      '                                         letteral for '"
    ## le panovobimoi linji pe `cmavo.txt`
    ##   .i `.y'y`
    ##   .i pa nacle'u cu se lidne le selma'o gi'e sinxa lo klesi
  LINES_CMAVO = [LINE_A, LINE_AACUHI, LINE_BAHE, LINE_BIHU, LINE_CINO, LINE_LE_GOHI, LINE_YHY]
    ## lo mupli'i pe `cmavo.txt` zi'e poi se lidne le stedu ku'o ta'i le porsi pe le datnyvei
    ##   .i ro tarmi be lo linji cu tarmi pa mupli'i
  TEXT_CMAVO = LINE_HEADER_CMAVO & "\n" & LINES_CMAVO.join("\n") & "\n"
    ## lo mupli be `cmavo.txt`
    ##   .i le mupli cu vasru le stedu .e ro mupli'i
    ##   .i le stedu cu lidne ro mupli'i
  EXPECTED_CMAVO = [
    EntryCmavo(word: "a", selmaho: Selmaho.A),
    EntryCmavo(word: "ba'e", selmaho: Selmaho.Bahe),
    EntryCmavo(word: "bi'u", selmaho: Selmaho.Ui),
    EntryCmavo(word: "y'y", selmaho: Selmaho.By),
  ]
    ## lo stecmi pe ro mupli'i poi vasru pa cmavo po'o
    ##   .i lo prenu cu tcidu le stecmi
    ##   .i lo ma'orgunma .e lo jufpau cu selvi'u
  TEXT_MODULE_CMAVO = staticRead("../../src/ricysoho/lists/cmavo.nim")
    ## le datnyvei pe le ma'oste zi'e poi selra'e ku'o ta'i lo lerpoi


func entryGismu(word: string): Option[EntryGismu] =
  ## facki lo stecmi pe le gimste zi'e poi selra'e gi'e ponse lo valsi po'u `word`
  for entry in LIST_GISMU:
    if entry.word == word: return some(entry)


func entriesRendered(module: string): seq[EntryGismu] =
  ## raptcidu lo valsi jo'u lo rafsi vu'o pe ro stecmili'i poi lo samtci datnyvei poi selci'a cu
  ##     vasru ke'a
  ##   .i le fancu cu na pilno le galfi samtci
  for line in module.splitLines:
    if not line.startsWith("  EntryGismu("): continue
    let
      quoted = line.split('"')
      word = quoted[1]
      rafsi = collect(for i in countup(3, quoted.high - 1, 2): quoted[i])
    result.add EntryGismu(word: word, rafsi: rafsi)


proc textRandom(lengths: Slice[int]): string =
  ## zbasu lo cunselci'a poi gunma lo jbole'u jo'u lo lerfu po'u zoi gy. ' .gy.
  ##   .i lo ni clani be le selci'a cu cmima `lengths`
  for _ in 1..rand(lengths): result.add LETTERS_RANDOM.sample


proc poolEntries(): seq[seq[EntryGismu]] =
  ## zbasu lo mupli
  ##   .i lo te kancu be le mupli cu du `SAMPLES`
  ##   .i ro mupli cu vasru su'o pa cunstecmi .e su'e ci cunstecmi
  ##   .i le mupli cu selpu'i fi pa vasru poi selzba pa roi
  ##   .i le pilno cu dunda lo tsiju
  result = newSeqOfCap[seq[EntryGismu]](SAMPLES)
  for _ in 1..SAMPLES:
    var entries = newSeqOfCap[EntryGismu](3)
    for _ in 1..rand(1..3):
      entries.add EntryGismu(
        word: textRandom(1..5),
        rafsi: collect(for _ in 1..rand(0..3): textRandom(3..4)),
      )
    result.add entries


func entryCmavo(word: string): Option[EntryCmavo] =
  ## facki lo stecmi pe le ma'oste zi'e poi selra'e gi'e ponse lo valsi po'u `word`
  for entry in LIST_CMAVO:
    if entry.word == word: return some(entry)


func entriesRenderedCmavo(module: string): seq[EntryCmavo] =
  ## raptcidu lo valsi jo'u lo selma'o vu'o pe ro stecmili'i poi lo samtci datnyvei poi selci'a cu
  ##     vasru ke'a
  ##   .i le fancu cu na pilno le galfi samtci
  for line in module.splitLines:
    if not line.startsWith("  EntryCmavo("): continue
    let
      word = line.split('"')[1]
      name = line.split("Selmaho.")[1].strip(chars = {')', ','})
    result.add EntryCmavo(word: word, selmaho: parseEnum[Selmaho](name))


proc poolEntriesCmavo(): seq[seq[EntryCmavo]] =
  ## zbasu lo mupli
  ##   .i lo te kancu be le mupli cu du `SAMPLES`
  ##   .i ro mupli cu vasru su'o pa cunstecmi pe le ma'oste gi'e vasru su'e ci cunstecmi pe le
  ##       ma'oste
  ##   .i le mupli cu selpu'i fi pa vasru poi selzba pa roi
  ##   .i le pilno cu dunda lo tsiju
  result = newSeqOfCap[seq[EntryCmavo]](SAMPLES)
  for _ in 1..SAMPLES:
    var entries = newSeqOfCap[EntryCmavo](3)
    for _ in 1..rand(1..3):
      entries.add EntryCmavo(word: textRandom(1..8), selmaho: rand(Selmaho.low .. Selmaho.high))
    result.add entries


iterator served[T](pool: seq[T]): lent T =
  ## dunda ro mupli pe le vasru ta'i le porsi
  ##   .i no fukpi cu selzba
  for i in 0..<pool.len: yield pool[i]



suite "Internal: Lists":
  test "gismu converter reads word and rafsi from their columns, header skipped":
    let entries = TEXT_GISMU.toEntriesGismu
    # ro linji poi se lidne le stedu cu selsni pa stecmi
    check entries.len == EXPECTED_GISMU.len  # le stedu cu na se tcidu
    for i, expected in EXPECTED_GISMU:
      # lo valsi jo'u lo rafsi cu se tcidu fi le stuzi
      #   .i lo kutle'u cu selvi'u
      check entries[i] == expected  # lo stuzi pe `entries.nim`
      check entryGismu(expected.word) == some(expected)  # le mupli cu mintu le liste poi selra'e
    for mask in 0..<(1 shl LINES_GISMU.len):  # ro gripau be lo mupli'i cu se cipra
      var (lines, expected) = (@[LINE_HEADER], newSeqOfCap[EntryGismu](LINES_GISMU.len))
      for i, line in LINES_GISMU:
        if (mask and (1 shl i)) == 0: continue
        lines.add line
        expected.add EXPECTED_GISMU[i]
      # le porsi be le linji cu stali
      check lines.join("\n").toEntriesGismu == expected  # ro linji cu se tcidu ta'i lo nu sepli
    let spaced = (@[LINE_HEADER] & LINES_GISMU.mapIt(it & "\n\n   ")).join("\n")
    check spaced.toEntriesGismu == @EXPECTED_GISMU  # lo kutli'i cu na se tcidu
    check LINE_HEADER.toEntriesGismu.len == 0 and toEntriesGismu("").len == 0  # le stedu po'o
    # lo te kancu be lo liste cmima pe le liste poi se ralte cu du le namcu poi le stedu cu cusku
    #     ke'a
    check LINE_HEADER[1..5].parseInt == LIST_GISMU.len  # le te kancu pe le stedu


  test "rendered module keeps 100 columns, and reads back each word and rafsi":
    let module_gismu = toModuleGismu(LIST_GISMU, DIGEST_GISMU)
    # le jimte cu jimte lo te kancu be lo stuzi
    check module_gismu.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
    check module_gismu.entriesRendered == @LIST_GISMU  # le sidju cu raptcidu lo selci'a
    randomize(SEED)
    let pool = poolEntries()
    # lo te kancu be lo mupli cu du `SAMPLES`
    #   .i lo tsiju cu jdice le mupli
    for entries in served(pool):
      let rendered = toModuleGismu(entries, DIGEST_GISMU)
      # ro linji pe pa stecmi cu mapti le jimte
      check rendered.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
      # lo lerpoi poi selci'a cu xruti le stecmi
      check rendered.entriesRendered == entries  # lo nu ciska kei jo'u lo nu raptcidu


  test "committed module is committed list rendered again":
    check toModuleGismu(LIST_GISMU, DIGEST_GISMU) == TEXT_MODULE_GISMU  # lo nu ciska lo se tcidu


  test "entry lacking word does not compile, as rule of data asks":
    # lo rafsi cu ka'e kunti
    #   .i se ki'u bo le rafsi cu na se tcita
    check compiles(EntryGismu(word: "cukta"))  # lo cmucipra
    check not compiles(EntryGismu(rafsi: @["cku"]))  # claxu lo valsi


  test "committed header names pinned digest, split as rendered":
    for digest in [DIGEST_GISMU, DIGEST_LUJVO, DIGEST_CMAVO]:
      # le snina'u cu selci'a ta'i `hex`
      check digest.len == 64 and digest.allCharsInSet({'0'..'9', 'a'..'f'})  # `SHA-256`
    let halves = "SHA-256 `" & DIGEST_GISMU[0..31] & "`\n##       `" & DIGEST_GISMU[32 .. ^1] & "`;"
    # le re xadba cu zvati re linji pe le stedu
    check halves in TEXT_MODULE_GISMU  # le snina'u cu se fendi fi re xadba


  test "every committed entry fits columns":
    for entry in LIST_GISMU:  # ro stecmi
      # lo stuzi pe le valsi
      check entry.word.len in 1..5 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # li re bi'o li xa
      # ro rafsi cu vasru ci lerfu .a vo lerfu
      check entry.rafsi.len <= 3 and entry.rafsi.allIt(it.len in 3..4)  # ci stuzi
      check entry.rafsi.allIt(it.allCharsInSet(LETTERS_LOJBAN))  # lo rafsi cu gunma lo lerfu
      check entry.word == entry.word.strip  # lo kutle'u pe lo fanmo be le valsi cu selvi'u


  test "cmavo converter keeps each line of one cmavo, word and selma'o from their columns":
    # lo jufpau cu selvi'u
    #   .i le porsi cu stali
    check TEXT_CMAVO.toEntriesCmavo == @EXPECTED_CMAVO  # lo ma'orgunma cu selvi'u
    for expected in EXPECTED_CMAVO:
      check entryCmavo(expected.word) == some(expected)  # le mupli cu mintu le liste poi selra'e
    for line in [LINE_AACUHI, LINE_CINO, LINE_LE_GOHI]:
      # lo linji cu vasru su'o re cmavo
      check (LINE_HEADER_CMAVO & "\n" & line).toEntriesCmavo.len == 0  # `*`
    check LINE_HEADER_CMAVO.toEntriesCmavo.len == 0 and toEntriesCmavo("").len == 0  # le stedu
    # ro linji cu selra'e gi'a selvi'u
    check EXPECTED_CMAVO.len + 3 == LINES_CMAVO.len  # no linji cu selcri


  test "rendered cmavo module keeps 100 columns, and reads back each word and selma'o":
    let module_cmavo = toModuleCmavo(LIST_CMAVO, DIGEST_CMAVO)
    # le jimte cu jimte lo te kancu be lo stuzi
    check module_cmavo.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
    check module_cmavo.entriesRenderedCmavo == @LIST_CMAVO  # le sidju cu raptcidu lo selci'a
    randomize(SEED)
    let pool = poolEntriesCmavo()
    # lo te kancu be lo mupli cu du `SAMPLES`
    #   .i lo tsiju cu jdice le mupli
    for entries in served(pool):
      let rendered = toModuleCmavo(entries, DIGEST_CMAVO)
      # ro linji pe pa stecmi cu mapti le jimte
      check rendered.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
      # lo selci'a cu xruti le stecmi
      #   .i ro selma'o cu ka'e selcuncu'a
      check rendered.entriesRenderedCmavo == entries  # lo nu ciska kei jo'u lo nu raptcidu


  test "committed cmavo module is committed cmavo list rendered again":
    check toModuleCmavo(LIST_CMAVO, DIGEST_CMAVO) == TEXT_MODULE_CMAVO  # lo nu ciska lo se tcidu
    let halves = "SHA-256 `" & DIGEST_CMAVO[0..31] & "`\n##       `" & DIGEST_CMAVO[32 .. ^1] & "`;"
    # le re xadba cu zvati re linji pe le stedu
    check halves in TEXT_MODULE_CMAVO  # le snina'u cu se fendi fi re xadba


  test "cmavo entry lacking word or selma'o does not compile, as rule of data asks":
    # ro datnypau cu selcme
    check compiles(EntryCmavo(word: "lo", selmaho: Selmaho.Le))  # lo cmucipra
    check not compiles(EntryCmavo(selmaho: Selmaho.Le))  # claxu lo valsi
    # va'o lo nu no da ciska le selma'o kei le selma'o cu du `A`
    check not compiles(EntryCmavo(word: "lo"))  # claxu lo selma'o


  test "every committed cmavo entry fits its columns, once, in order":
    for i, entry in LIST_CMAVO:  # ro stecmi
      check entry.word.len in 1..11 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # no denpa bu
      # ro valsi cu selci'a pa roi
      if i > 0: check LIST_CMAVO[i - 1].word < entry.word  # ja'i lo porsi be lo stuzi


  test "committed cmavo list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "cmavo.txt"):
      # `lojban-common` na zvati
      #   .i lo minde po'u `system` cusku le bakfu
      #   .i va'o lo nu le bakfu cu zvati kei lo minde po'u `head` karbi
      skip()
    else:
      let source = readSource("cmavo.txt")
      if source.digest != DIGEST_CMAVO:
        # le liste poi selpu'i cu na mapti le stosni
        #   .i lo minde po'u `head` cusku le nu na mapti
        skip()
      else:
        check source.text.toEntriesCmavo == @LIST_CMAVO  # le liste cu jalge le galfi samtci


  test "outside text reader keeps word of each line, and parts of either notation":
    # le porsi cu stali
    check toLinesLujvo(LINES_LUJVO.join("\n")) == @EXPECTED_LUJVO  # ro tarmi
    for line in [LINE_DATKYPIU, LINE_BLOTI_ZERLEA]:
      check toLinesLujvo(line).len == 0  # lo jufpau poi basti lo valsi cu cmima no selcmi
    check toLinesLujvo("\n  \n").len == 0  # lo kutli'i cu vasru no valsi
    # ro linji cu se tcidu gi'a selvi'u
    check EXPECTED_LUJVO.len + 2 == LINES_LUJVO.len  # no linji cu selcri


  test "committed gismu list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "gismu.txt"):
      # `lojban-common` na zvati
      #   .i lo minde po'u `system` cusku le bakfu
      #   .i va'o lo nu le bakfu cu zvati kei lo minde po'u `head` karbi
      skip()
    else:
      let source = readSource("gismu.txt")
      if source.digest != DIGEST_GISMU:
        # le liste poi selpu'i cu na mapti le stosni
        #   .i lo minde po'u `head` cusku le nu na mapti
        skip()
      else:
        check source.text.toEntriesGismu == @LIST_GISMU  # le liste cu jalge le galfi samtci
