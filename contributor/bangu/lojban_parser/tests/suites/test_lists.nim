## cipra lo du'u le galfi samtci pe `tools/lists.nim` cu zukte ja'i le javni be le galfi samtci
##   .i le galfi samtci cu tcidu lo valsi jo'u lo rafsi vu'o pe le gismu liste ra'i lo stuzi be le
##     datni pagbu
##   .i le galfi samtci cu tcidu ji'a lo valsi jo'u lo selma'o vu'o pe le cmavo liste ra'i lo stuzi
##     be le datni pagbu
##   .i ro linji pe lo samtci datnyvei poi se ciska cu vasru su'e panono stuzi
##   .i lo cipra cu rapli tcidu le samtci datnyvei
##   .i va'o lo nu le liste poi se ralte cu se rapli ciska kei le jalge cu mintu le samtci datnyvei
##     poi se ralte
##   .i ji'a cipra lo du'u le tcidu be lo drata se ciska be'o to `texts_outside.nim` toi cu drani
##     tcidu lo linji
##   .i la'o gy. CLL .gy. cu casnu no valsi liste datnyvei
##   .i se ki'u bo lo cmene be le vi cipra cu cfari fi `Internal:`
##   .i lo cmene be ro cipra cu skicu lo nu le se cipra cu zukte to `Article IX.10` toi
##   .i ro mupli linji cu fukpi pa linji pe `gismu.txt` .a `cmavo.txt` .a `lujvo.txt` vu'o poi lo
##     sinxa namcu cu stodi sinxa ke'a
##   .i ro stuzi pe le mupli linji cu mintu lo stuzi pe le linji
##   .i ku'i lo lerfu po'u la'o gy. carriage return .gy. cu se vimcu ta'i lo nu `readSource` cu
##     vimcu le lerfu
##   .i lo pinka be ro mupli linji cu cusku le linji poi le mupli linji cu fukpi ke'a
##   .i re cipra cu karbi le liste poi se ralte ku'o le liste poi se punji
##   .i va'o lo nu `lojban-common` cu na zvati gi'a na mapti le stodi sinxa kei ro le re cipra cu na
##     zukte gi'e cusku lo krinu to `Article IX.9` toi
##   .i lo minde po'u `system` cu cusku le bakfu
##   .i se ki'u bo la'o gy. CI .gy. cu punji le bakfu
##   .i ro cunso liste cmima cu vasru pa valsi .e su'e ci rafsi
##   .i le valsi cu vasru su'o pa lerfu gi'e vasru su'e mu lerfu
##   .i ro le rafsi cu vasru ci lerfu .a vo lerfu
##   .i ro lerfu pe le liste cmima cu se cuxna fi lo lojbo lerfu jo'u lo lerfu po'u zoi gy. ' .gy.
##     ge'u ta'i lo nu lo liste cmima poi se ralte cu vasru lo mintu lerfu to `Article IX.4` toi
##   .i ro cunso liste cmima pe le cmavo liste cu vasru pa valsi .e pa selma'o
##   .i le valsi cu vasru su'o pa lerfu gi'e vasru su'e bi lerfu
##   .i le selma'o cu ka'e du ro selma'o pe `CLL 20`
##   .i ba lo nu dunda lo tsiju pa roi kei lo mupli cu se cuxna gi'e se punji fi pa vasru poi se
##     zbasu pa roi
##   .i `served` cu dunda le mupli

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, os, random, sequtils, strutils, sugar, unittest]

import ../../src/lojban_parser/[entries, selmaho]
import ../../src/lojban_parser/lists/[cmavo, gismu]
import ../../tools/lists
import ./texts_outside


const
  SEED = 1997
    ## lo tsiju be ro cunso cuxna
    ##   .i le tsiju cu du lo namcu pe lo nanca poi la'o gy. CLL .gy. cu pamoi se cupra ca ke'a
  SAMPLES = 200
    ## lo te kancu be lo cunso liste cmima
    ##   .i ro javni cu se cipra ne'i le cunso liste cmima
  WIDTH = 100
    ## lo jimte be lo stuzi pe pa linji ja'i `Article X.1`
    ##   .i ro linji poi se ciska cu na zmadu le jimte
  LETTERS_LOJBAN = {'a'..'z', '\''}
    ## lo lerfu poi lo valsi .e lo rafsi vu'o pe le liste cu vasru ke'a
  LETTERS_RANDOM = "abcdefgijklmnoprstuvxyz'"
    ## lo lerfu poi lo cunso valsi .e lo cunso rafsi cu se cuxna fi ke'a
  TEXT_MODULE_GISMU = staticRead("../../src/lojban_parser/lists/gismu.nim")
    ## le datnyvei pe le gismu liste zi'e poi se ralte ku'o ta'i lo lerpoi

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
    ##   .i pa rafsi poi se tarmi `CV'V` cu zvati le cimoi stuzi
  LINE_BAKFU =
      " bakfu baf          bundle               'pack'               x1 is a " &
      "bundle/package/cluster/clump/pack [shape/form] containing x2, held together by x3   " &
      "     9b   3    (cf. daski, dakli, tanxe)"
    ## le xamoi linji pe `gismu.txt`
    ##   .i zo bakfu
    ##   .i le linji cu vasru pa sidju valsi poi se sitna
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
    ##   .i le linji cu vasru pa rafsi po'o
    ##   .i le rafsi cu se tarmi `CCV`
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
    ##   .i le linji cu vasru pa rafsi poi se tarmi `CVC` ku'o .e pa rafsi poi se tarmi `CVV`
  LINES_GISMU = [LINE_BACRU, LINE_BAKFU, LINE_BI, LINE_BLOTI, LINE_CUKTA, LINE_DATNI, LINE_VREJI]
    ## lo mupli linji pe `gismu.txt` zi'e poi se lidne le stedu ku'o ta'i le porsi pe le datnyvei
  TEXT_GISMU = LINE_HEADER & "\n" & LINES_GISMU.join("\n") & "\n"
    ## lo mupli be `gismu.txt`
    ##   .i le mupli cu vasru le stedu .e ro mupli linji
    ##   .i le stedu cu lidne ro mupli linji
  EXPECTED_GISMU = [
    EntryGismu(word: "bacru", rafsi: @["ba'u"]),
    EntryGismu(word: "bakfu", rafsi: @["baf"]),
    EntryGismu(word: "bi", rafsi: @["biv"]),
    EntryGismu(word: "bloti", rafsi: @["lot", "blo", "lo'i"]),
    EntryGismu(word: "cukta", rafsi: @["cku"]),
    EntryGismu(word: "datni", rafsi: @[]),
    EntryGismu(word: "vreji", rafsi: @["rej", "vei"]),
  ]
    ## lo liste cmima pe ro mupli linji
    ##   .i lo prenu cu tcidu lo datni pagbu lo stuzi pe `entries.nim`
  LINE_BAARMOA = "ba'armo'a:barna+morna:pattern of marks:$morna1 $morna2 $=barna1 $morna3 $barna2"
    ## le pamoi linji pe `lujvo.txt`
    ##   .i le tanru pe le linji cu lojbo
  LINE_BADGAI =
      "badgai#defend+cover: protective cover/ shield:$bandu1 $=gacri1 $bandu2 $=gacri1 " &
      "$bandu3"
    ## le pavomoi linji pe `lujvo.txt`
    ##   .i le tanru pe le linji cu vasru lo glico ckiku valsi
    ##   .i `#` cu lidne le tanru
  LINE_DATNYVEI =
      "datnyvei:datni+vreji:file (incl. computers):$vreji1 $vreji2 $=datni2 $vreji3 " &
      "$vreji4 [ = manner of encoding]"
    ## le xacivomoi linji pe `lujvo.txt`
    ##   .i zo datnyvei
    ##   .i le tanru pe le linji cu lojbo
  LINE_FEBJICLA = "febjicla#boil+stir:roil:roil:$jicla1 $jicla2 $=febvi1"
    ## le bivopamoi linji pe `lujvo.txt`
    ##   .i le tanru cu glico
    ##   .i lo smuni valsi cu se ciska re roi
    ##   .i le pamoi cu se ralte
  LINE_CIMNALSRA = "cimnalsra:foldi::cilmo+na'e+srasu foldi marsh"
    ## le cixanomoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru pa pagbu
    ##   .i lo smuni valsi cu kunti
  LINE_SEZYPEVDUA =
      "sezypevdu'a:sevzi+[figurative::]+dunda to dedicate oneself to someone/something, to " &
      "give oneself away"
    ## le rebivobimoi linji pe `lujvo.txt`
    ##   .i lo lerfu po'u zoi gy. : .gy. cu zvati lo jbini be zoi gy. [ .gy. jo'u zoi gy. ] .gy.
    ##   .i lo smuni valsi cu kunti
  LINE_JGETERJOE = "jgeterjo'e#knot+3rd-place-of+joined"
    ## le parecibimoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru `#` gi'e vasru no lerfu po'u zoi gy. : .gy.
    ##   .i se ki'u bo le linji cu vasru no smuni valsi
  LINE_CIERSMITAI =
      "ci'ersmitai#system+similar+shape:$tarmi1 $=simsa1 $tarmi2 $=simsa2 $ciste1 $=simsa3"
    ## le cireremoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru `#`
    ##   .i lo smuni valsi cu du lo porsi be lo terbri
  LINE_PEVYSOASELTAI =
      "pevyso'aseltai#[figurative:]+egg+2nd-place-of+shape:egg-shaped:$tarmi2 $tarmi1"
    ## le rerexapamoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru `#`
    ##   .i lo lerfu po'u zoi gy. : .gy. cu zvati lo jbini be zoi gy. [ .gy. jo'u zoi gy. ] .gy.
  LINE_DATKYPIU = "datkypi'u gairki'e:datka+pimlu gacri+kicne:eiderdown [quilt]"
    ## le xacinomoi linji pe `lujvo.txt`
    ##   .i le linji cu ciska lo jufra pagbu ne'i lo stuzi be lo valsi
    ##   .i lo kunti lerfu cu zvati ne'i le jufra pagbu
  LINE_JAIRTAI = "jairtai:denmi:xance jgari+tarmi denmi xance:fist:$tarmi1 (omit $tarmi2 $=jgari3)"
    ## le panosopamoi linji pe `lujvo.txt`
    ##   .i le linji cu vasru mu datni pagbu
    ##   .i le tanru cu vasru pa pagbu
  LINE_BLOTI_ZERLEA = "bloti zerle'a:bloti zekri+lebna:pirate:"
    ## le pamunomoi linji pe `lujvo.txt`
    ##   .i le linji cu ciska lo jufra pagbu ne'i lo stuzi be lo valsi
    ##   .i lo lerfu po'u zoi gy. : .gy. cu fanmo lo smuni valsi
  LINE_NALSUTYDZUKEPKLA =
      "nalsutydzukepkla:na'e+sutra+cadzu+,+klama:to go without walking fast:$klama1 " &
      "$klama2 $klama3 $klama4 $klama5"
    ## le renonobimoi linji pe `lujvo.txt`
    ##   .i `,` cu zvati lo jbini be lo pagbu
  LINES_LUJVO = [
    LINE_BAARMOA, LINE_BADGAI, LINE_DATNYVEI, LINE_FEBJICLA, LINE_CIMNALSRA, LINE_SEZYPEVDUA,
    LINE_JGETERJOE, LINE_CIERSMITAI, LINE_PEVYSOASELTAI, LINE_DATKYPIU, LINE_JAIRTAI,
    LINE_BLOTI_ZERLEA, LINE_NALSUTYDZUKEPKLA,
  ]
    ## lo mupli linji pe `lujvo.txt`
    ##   .i ro tarmi poi le tcidu be lo drata se ciska cu penmi ke'a cu tarmi pa mupli linji
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
    ## lo se tcidu pe ro mupli linji poi lo valsi pe ke'a cu gunma lo lerfu po'o
    ##   .i lo prenu cu tcidu le se tcidu
    ##   .i va'o lo nu le linji cu ciska su'o re pagbu kei le se tcidu cu vasru le pagbu
    ##   .i ro lojbo pagbu cu gunma lo lerfu po'o
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
    ##   .i `.a'acu'i` noi cmavo gunma
    ##   .i `*` cu se lidne lo selma'o
  LINE_BAHE =
      " ba'e      BAhE     emphasize next                            forethought emphasis i" &
      "ndicator; indicates next word is especially emphasized"
    ## le rezemoi linji pe `cmavo.txt`
    ##   .i `ba'e`
    ##   .i le selma'o po'u `BAhE` cu vasru `h`
  LINE_BIHU =
      " bi'u      UI3a     new information                           discursive: newly intr" &
      "oduced information - previously introduced information                              " &
      "(cf. nindatni, saurdatni)"
    ## le muremoi linji pe `cmavo.txt`
    ##   .i `bi'u`
    ##   .i lo klesi po'u `3a` cu se lidne le selma'o
  LINE_CINO =
      " cino      PA*      30                                        number/quantity: 30 [t" &
      "hirty]"
    ## le panopamoi linji pe `cmavo.txt`
    ##   .i `cino`
    ##   .i le cmavo gunma cu vasru re cmavo be `PA`
  LINE_LE_GOHI =
      " le go'i   KOhA*    the x1 of last bridi                      description pro-sumti:" &
      " reuses the value of the x1 of the previous bridi"
    ## le vonobimoi linji pe `cmavo.txt`
    ##   .i `le go'i` noi jufra pagbu gi'e vasru re valsi
  LINE_YHY =
      ".y'y       BY2      '                                         letteral for '"
    ## le panovobimoi linji pe `cmavo.txt`
    ##   .i `.y'y`
    ##   .i pa namcu lerfu cu se lidne le selma'o gi'e sinxa lo klesi
  LINES_CMAVO = [LINE_A, LINE_AACUHI, LINE_BAHE, LINE_BIHU, LINE_CINO, LINE_LE_GOHI, LINE_YHY]
    ## lo mupli linji pe `cmavo.txt` zi'e poi se lidne le stedu ku'o ta'i le porsi pe le datnyvei
    ##   .i ro tarmi be lo linji cu tarmi pa mupli linji
  TEXT_CMAVO = LINE_HEADER_CMAVO & "\n" & LINES_CMAVO.join("\n") & "\n"
    ## lo mupli be `cmavo.txt`
    ##   .i le mupli cu vasru le stedu .e ro mupli linji
    ##   .i le stedu cu lidne ro mupli linji
  EXPECTED_CMAVO = [
    EntryCmavo(word: "a", selmaho: Selmaho.A),
    EntryCmavo(word: "ba'e", selmaho: Selmaho.Bahe),
    EntryCmavo(word: "bi'u", selmaho: Selmaho.Ui),
    EntryCmavo(word: "y'y", selmaho: Selmaho.By),
  ]
    ## lo liste cmima pe ro mupli linji poi vasru pa cmavo po'o
    ##   .i lo prenu cu tcidu le liste cmima
    ##   .i lo cmavo gunma .e lo jufra pagbu cu se vimcu
  TEXT_MODULE_CMAVO = staticRead("../../src/lojban_parser/lists/cmavo.nim")
    ## le datnyvei pe le cmavo liste zi'e poi se ralte ku'o ta'i lo lerpoi


func entryGismu(word: string): Option[EntryGismu] =
  ## facki lo liste cmima pe le gismu liste zi'e poi se ralte gi'e ponse lo valsi po'u `word`
  for entry in LIST_GISMU:
    if entry.word == word: return some(entry)


func entriesRendered(module: string): seq[EntryGismu] =
  ## rapli tcidu lo valsi jo'u lo rafsi vu'o pe ro liste cmima linji poi lo samtci datnyvei poi se
  ##   ciska cu vasru ke'a
  ##   .i le fancu cu na pilno le galfi samtci
  for line in module.splitLines:
    if not line.startsWith("  EntryGismu("): continue
    let
      quoted = line.split('"')
      word = quoted[1]
      rafsi = collect(for i in countup(3, quoted.high - 1, 2): quoted[i])
    result.add EntryGismu(word: word, rafsi: rafsi)


proc textRandom(lengths: Slice[int]): string =
  ## zbasu lo cunso se ciska poi gunma lo lojbo lerfu jo'u lo lerfu po'u zoi gy. ' .gy.
  ##   .i lo ni clani be le se ciska cu cmima `lengths`
  for _ in 1..rand(lengths): result.add LETTERS_RANDOM.sample


proc poolEntries(): seq[seq[EntryGismu]] =
  ## zbasu lo mupli
  ##   .i lo te kancu be le mupli cu du `SAMPLES`
  ##   .i ro mupli cu vasru su'o pa cunso liste cmima gi'e vasru su'e ci cunso liste cmima
  ##   .i le mupli cu se punji fi pa vasru poi se zbasu pa roi
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
  ## facki lo liste cmima pe le cmavo liste zi'e poi se ralte gi'e ponse lo valsi po'u `word`
  for entry in LIST_CMAVO:
    if entry.word == word: return some(entry)


func entriesRenderedCmavo(module: string): seq[EntryCmavo] =
  ## rapli tcidu lo valsi jo'u lo selma'o vu'o pe ro liste cmima linji poi lo samtci datnyvei poi se
  ##   ciska cu vasru ke'a
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
  ##   .i ro mupli cu vasru su'o pa cunso liste cmima pe le cmavo liste gi'e vasru su'e ci cunso
  ##     liste cmima pe le cmavo liste
  ##   .i le mupli cu se punji fi pa vasru poi se zbasu pa roi
  ##   .i le pilno cu dunda lo tsiju
  result = newSeqOfCap[seq[EntryCmavo]](SAMPLES)
  for _ in 1..SAMPLES:
    var entries = newSeqOfCap[EntryCmavo](3)
    for _ in 1..rand(1..3):
      entries.add EntryCmavo(word: textRandom(1..8), selmaho: rand(Selmaho.low .. Selmaho.high))
    result.add entries


iterator served[T](pool: seq[T]): lent T =
  ## dunda ro mupli pe le vasru ta'i le porsi
  ##   .i no fukpi cu se zbasu
  for i in 0..<pool.len: yield pool[i]



suite "Internal: Lists":
  test "gismu converter reads word and rafsi from their columns, header skipped":
    let entries = TEXT_GISMU.toEntriesGismu
    # ro linji poi se lidne le stedu cu se sinxa pa liste cmima
    check entries.len == EXPECTED_GISMU.len  # le stedu cu na se tcidu
    for i, expected in EXPECTED_GISMU:
      # lo valsi jo'u lo rafsi cu se tcidu fi le stuzi
      #   .i lo kunti lerfu cu se vimcu
      check entries[i] == expected  # lo stuzi pe `entries.nim`
      check entryGismu(expected.word) == some(expected)  # le mupli cu mintu le liste poi se ralte
    for mask in 0..<(1 shl LINES_GISMU.len):  # ro gripau be lo mupli linji cu se cipra
      var (lines, expected) = (@[LINE_HEADER], newSeqOfCap[EntryGismu](LINES_GISMU.len))
      for i, line in LINES_GISMU:
        if (mask and (1 shl i)) == 0: continue
        lines.add line
        expected.add EXPECTED_GISMU[i]
      # le porsi be le linji cu stali
      check lines.join("\n").toEntriesGismu == expected  # ro linji cu se tcidu ta'i lo nu sepli
    let spaced = (@[LINE_HEADER] & LINES_GISMU.mapIt(it & "\n\n   ")).join("\n")
    check spaced.toEntriesGismu == @EXPECTED_GISMU  # lo kunti linji cu na se tcidu
    check LINE_HEADER.toEntriesGismu.len == 0 and toEntriesGismu("").len == 0  # le stedu po'o
    # lo te kancu be lo liste cmima pe le liste poi se ralte cu du le namcu poi le stedu cu cusku
    #   ke'a
    check LINE_HEADER[1..5].parseInt == LIST_GISMU.len  # le te kancu pe le stedu


  test "rendered module keeps 100 columns, and reads back each word and rafsi":
    let module_gismu = toModuleGismu(LIST_GISMU, DIGEST_GISMU)
    # le jimte cu jimte lo te kancu be lo stuzi
    check module_gismu.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
    check module_gismu.entriesRendered == @LIST_GISMU  # le sidju cu rapli tcidu lo se ciska
    randomize(SEED)
    let pool = poolEntries()
    # lo te kancu be lo mupli cu du `SAMPLES`
    #   .i lo tsiju cu jdice le mupli
    for entries in served(pool):
      let rendered = toModuleGismu(entries, DIGEST_GISMU)
      # ro linji pe pa liste cmima cu mapti le jimte
      check rendered.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
      # lo lerpoi poi se ciska cu xruti le liste cmima
      check rendered.entriesRendered == entries  # lo nu ciska kei jo'u lo nu rapli tcidu


  test "committed module is committed list rendered again":
    check toModuleGismu(LIST_GISMU, DIGEST_GISMU) == TEXT_MODULE_GISMU  # lo nu ciska lo se tcidu


  test "entry lacking word does not compile, as rule of data asks":
    # lo rafsi cu ka'e kunti
    #   .i se ki'u bo le rafsi cu na se tcita
    check compiles(EntryGismu(word: "cukta"))  # lo jicmu cipra
    check not compiles(EntryGismu(rafsi: @["cku"]))  # claxu lo valsi


  test "committed header names pinned digest, split as rendered":
    for digest in [DIGEST_GISMU, DIGEST_LUJVO, DIGEST_CMAVO]:
      # le sinxa namcu cu se ciska ta'i la'o gy. hex .gy.
      check digest.len == 64 and digest.allCharsInSet({'0'..'9', 'a'..'f'})  # `SHA-256`
    let halves = "SHA-256 `" & DIGEST_GISMU[0..31] & "`\n##     `" & DIGEST_GISMU[32 .. ^1] & "`;"
    # le re xadba cu zvati re linji pe le stedu
    check halves in TEXT_MODULE_GISMU  # le sinxa namcu cu se fendi fi re xadba


  test "every committed entry fits columns":
    for entry in LIST_GISMU:  # ro liste cmima
      # lo stuzi pe le valsi
      check entry.word.len in 1..5 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # li re bi'o li xa
      # ro rafsi cu vasru ci lerfu .a vo lerfu
      check entry.rafsi.len <= 3 and entry.rafsi.allIt(it.len in 3..4)  # ci stuzi
      check entry.rafsi.allIt(it.allCharsInSet(LETTERS_LOJBAN))  # lo rafsi cu gunma lo lerfu
      check entry.word == entry.word.strip  # lo kunti lerfu pe lo fanmo be le valsi cu se vimcu


  test "cmavo converter keeps each line of one cmavo, word and selma'o from their columns":
    # lo jufra pagbu cu se vimcu
    #   .i le porsi cu stali
    check TEXT_CMAVO.toEntriesCmavo == @EXPECTED_CMAVO  # lo cmavo gunma cu se vimcu
    for expected in EXPECTED_CMAVO:
      check entryCmavo(expected.word) == some(expected)  # le mupli cu mintu le liste poi se ralte
    for line in [LINE_AACUHI, LINE_CINO, LINE_LE_GOHI]:
      # lo linji cu vasru su'o re cmavo
      check (LINE_HEADER_CMAVO & "\n" & line).toEntriesCmavo.len == 0  # `*`
    check LINE_HEADER_CMAVO.toEntriesCmavo.len == 0 and toEntriesCmavo("").len == 0  # le stedu
    # ro linji cu se ralte gi'a se vimcu
    check EXPECTED_CMAVO.len + 3 == LINES_CMAVO.len  # no linji cu se cirko


  test "rendered cmavo module keeps 100 columns, and reads back each word and selma'o":
    let module_cmavo = toModuleCmavo(LIST_CMAVO, DIGEST_CMAVO)
    # le jimte cu jimte lo te kancu be lo stuzi
    check module_cmavo.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
    check module_cmavo.entriesRenderedCmavo == @LIST_CMAVO  # le sidju cu rapli tcidu lo se ciska
    randomize(SEED)
    let pool = poolEntriesCmavo()
    # lo te kancu be lo mupli cu du `SAMPLES`
    #   .i lo tsiju cu jdice le mupli
    for entries in served(pool):
      let rendered = toModuleCmavo(entries, DIGEST_CMAVO)
      # ro linji pe pa liste cmima cu mapti le jimte
      check rendered.splitLines.allIt(it.len <= WIDTH)  # `Article X.1`
      # lo se ciska cu xruti le liste cmima
      #   .i ro selma'o cu ka'e se cunso cuxna
      check rendered.entriesRenderedCmavo == entries  # lo nu ciska kei jo'u lo nu rapli tcidu


  test "committed cmavo module is committed cmavo list rendered again":
    check toModuleCmavo(LIST_CMAVO, DIGEST_CMAVO) == TEXT_MODULE_CMAVO  # lo nu ciska lo se tcidu
    let halves = "SHA-256 `" & DIGEST_CMAVO[0..31] & "`\n##     `" & DIGEST_CMAVO[32 .. ^1] & "`;"
    # le re xadba cu zvati re linji pe le stedu
    check halves in TEXT_MODULE_CMAVO  # le sinxa namcu cu se fendi fi re xadba


  test "cmavo entry lacking word or selma'o does not compile, as rule of data asks":
    # ro datni pagbu cu se cmene
    check compiles(EntryCmavo(word: "lo", selmaho: Selmaho.Le))  # lo jicmu cipra
    check not compiles(EntryCmavo(selmaho: Selmaho.Le))  # claxu lo valsi
    # va'o lo nu no da cu ciska le selma'o kei le selma'o cu du `A`
    check not compiles(EntryCmavo(word: "lo"))  # claxu lo selma'o


  test "every committed cmavo entry fits its columns, once, in order":
    for i, entry in LIST_CMAVO:  # ro liste cmima
      check entry.word.len in 1..11 and entry.word.allCharsInSet(LETTERS_LOJBAN)  # no denpa bu
      # ro valsi cu se ciska pa roi
      if i > 0: check LIST_CMAVO[i - 1].word < entry.word  # ja'i lo porsi be lo stuzi


  test "committed cmavo list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "cmavo.txt"):
      # `lojban-common` cu na zvati
      #   .i lo minde po'u `system` cu cusku le bakfu
      #   .i va'o lo nu le bakfu cu zvati kei lo minde po'u `head` cu karbi
      skip()
    else:
      let source = readSource("cmavo.txt")
      if source.digest != DIGEST_CMAVO:
        # le liste poi se punji cu na mapti le stodi sinxa
        #   .i lo minde po'u `head` cu cusku le nu na mapti
        skip()
      else:
        check source.text.toEntriesCmavo == @LIST_CMAVO  # le liste cu jalge le galfi samtci


  test "outside text reader keeps word of each line, and parts of either notation":
    # le porsi cu stali
    check toLinesLujvo(LINES_LUJVO.join("\n")) == @EXPECTED_LUJVO  # ro tarmi
    for line in [LINE_DATKYPIU, LINE_BLOTI_ZERLEA]:
      check toLinesLujvo(line).len == 0  # lo jufra pagbu poi basti lo valsi cu cmima no selcmi
    check toLinesLujvo("\n  \n").len == 0  # lo kunti linji cu vasru no valsi
    # ro linji cu se tcidu gi'a se vimcu
    check EXPECTED_LUJVO.len + 2 == LINES_LUJVO.len  # no linji cu se cirko


  test "committed gismu list is list converted from installed file":
    if not fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / "gismu.txt"):
      # `lojban-common` cu na zvati
      #   .i lo minde po'u `system` cu cusku le bakfu
      #   .i va'o lo nu le bakfu cu zvati kei lo minde po'u `head` cu karbi
      skip()
    else:
      let source = readSource("gismu.txt")
      if source.digest != DIGEST_GISMU:
        # le liste poi se punji cu na mapti le stodi sinxa
        #   .i lo minde po'u `head` cu cusku le nu na mapti
        skip()
      else:
        check source.text.toEntriesGismu == @LIST_GISMU  # le liste cu jalge le galfi samtci
