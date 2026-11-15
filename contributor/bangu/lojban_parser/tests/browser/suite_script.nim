## cipra lo du'u le genturfa'i pe `JavaScript` to `src/javascript/bridge.nim` toi cu mintu le jbezba
##     ne'i `headless Chromium` noi lo minde po'u `drive` rinka lo nu ke'a cfari to
##     `tools/drive.nim` toi
##   .i ro jufra pe le stomupli pe `Tatoeba` cpacu le seljdi poi le jbezba cu dunda ke'a ca lo nu
##       ciska le mupli
##   .i lo dacti pe `parseLojban` mintu `ReadingText` ro datnypau
##   .i va'o lo nu ro vomoi jufra pe le mupli cu se tcidu kei `JS` ciska lo selci'a be fi `NIF` be'o
##       pe le jufra
##   .i le selci'a cu se tcidu ta'i le velski be le tarmi gi'e rapyzba le multricu pe le jufra
##       sepi'o le tcidu pe le jbena cipra to `suites/reader_nif.nim` toi
##   .i `parseLojbanToNif` dunda lo selci'a be fi `NIF` be'o poi mintu le selci'a pe le mupli poi le
##       jbecipra cu vasru ke'a ku'o ro stuzi
##   .i jdima fa lo nu lo nu tcidu ro jufra cu nitcu ji'i `70 ms` ne'i `JS`
##   .i se ki'u bo va'o lo nu tcidu le mulmupli kei le temci cu zenba fi ji'i `13 s`
##   .i le jbecipra cu tcidu ro selci'a pe lo selci'agri
##   .i le mupli cu pilno bixa lo bibi javni poi selcme ne'i `CLL 21.1`
##   .i su'o le jufra cu se to'e curmi le tcidu be lo porsi be lo valsi
##   .i su'o le jufra cu se to'e curmi le gerna
##   .i le se to'e curmi cu du voso jufra
##   .i se ki'u bo pa nu cipra cu cipra lo so'e pagbu be le genturfa'i ne'i `JavaScript` to
##       `sample_tatoeba/sentences.nim` toi
##   .i le seljdi cu vasru lo nu to'e curmi .e le javni ta'i lo nu `tools/tatoeba.nim` ciska
##   .i le seljdi cu kunti va'o lo nu le jufra cu se tcidu
##   .i le cipra cu fasnu ne'i lo papri gi'e sepli `test_suites.nim`
##   .i ki'u bo le cripu cu pencu lo dacti pe `JavaScript` sepi'o `std/jsffi` noi le jbezba na ka'e
##       fanva ke'a
##   .i le cusku cu benji ro cipra le sabji samtci
##   .i ba bo le cusku cu benji lo famna'u pe le nu cipra
##   .i se ki'u bo pa xusra poi fliba cu rinka lo nu `drive` fliba to `report.nim` toi
##   .i `node` na pilno le cipra to lo seljdi bu'u `#859` toi
##   .i se ki'u bo le samtci cu se cipra ne'i le papri noi le samtci cu fasnu ne'i ke'a
##   .i le cipra cu se fanva sepi'o `-d:release` ta'i lo nu lo minde po'u `javascript` zbasu le
##       samtci
##   .i se ki'u bo le cipra cu cipra le selzba poi se benji to `IX.6` toi
##   .i pa xusra poi fliba cu cusku ji'a lo linji pe vo'a
##   .i `check` jdice le linji ca lo nu fanva
##   .i pa minde po'u `-d:` pe lo nu sisti cu na selpli
##   .i se ki'u bo ro jufra poi lo seljdi be fi ke'a cu cenba cu selsku ne'i pa nu cipra

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[jsffi, strutils, unittest]

import ../../src/javascript/bridge
import ../../src/lojban_parser/[nif, prose]
import ../sample_tatoeba/sentences
import ../suites/reader_nif
import ./report


const
  STRIDE_NIF = 4  ## le flalu pe `NIF` tcidu ro vomoi jufra pe le mupli
  COUNT_TREES_LEAST = 40
    ## lo du'u xo kau lo mupaso jufra poi le flalu cu cuxna ke'a se tcidu
    ##   .i le flalu cu tcidu le tricu pe ro le jufra


proc verdict(reading: JsObject): string =
  ## ciska lo jalge be `parseLojban` ta'i lo seljdi pe le mupli
  ##   .i lo kunti lerpoi va'o lo nu le selci'a cu se tcidu
  if reading.is_read.to(bool): return ""
  let rule = $reading.rule.to(cstring)
  $reading.refusal.to(cstring) & (if rule.len > 0: " " & rule else: "")



initReporter()


suite "Internal: JavaScript build":
  test "Each sentence of Tatoeba sample takes verdict native build gave it":
    var count = 0
    for sentence in SENTENCES_TATOEBA:
      # le seljdi cu seldu'a ca lo nu ciska le mupli
      check parseLojban(cstring(sentence.text)).verdict == sentence.verdict  # le jbezba
      inc count
    check count == SENTENCES_TATOEBA.len  # `IX.3` to lo bandu cu ralte ro jufra toi


  test "Object of text that reads holds occurrences, units and tree":
    let reading = parseLojban("mi klama le zarci")  # `Example 2.1` pe `CLL 1.1`
    check reading.is_read.to(bool)  # `prose.nim` to le selci'a cu se tcidu toi
    check reading.occurrences.length.to(int) == 4  # ro valsi cu se tcidu pa roi
    # le cmene cu mintu le selci'a be le cukta
    check reading.occurrences[0].reading.selmaho.to(cstring) == "KOhA"  # `CLL 20`
    check reading.occurrences[1].reading.kind.to(cstring) == "Gismu"  # `CLL 4.4` to zo klama toi
    check reading.occurrences[1].stress == jsNull  # no brale'u cu sinxa lo nu basna
    # lo stuzi poi zo klama cfari bu'u ke'a
    check reading.occurrences[1].start.to(int) == 3  # `stream.nim`
    # lo stuzi poi se lidne le romoi lerfu be zo klama
    check reading.occurrences[1].finish.to(int) == 8  # `stream.nim`
    check reading.units.length.to(int) == 4  # ro valsi cu selvau pa genvla
    # le genvla pe lo brivla
    check reading.units[1].terminal.to(cstring) == "BRIVLA"  # `CLL 21.1`
    # le javni pe li no cu krasi le tricu
    check reading.tree.rule.to(cstring) == "text"  # `CLL 21.1`
    check reading.tree.number.to(int) == 0


  test "Object of text refused holds refusal, its byte and rule, and stream before it":
    let typo = parseLojban("mi klama le zarc")  # zo zarci claxu le romoi lerfu to selfi'i toi
    check not typo.is_read.to(bool)
    check typo.refusal.to(cstring) == "Grammar"  # `CLL 21.1` to'e curmi
    check typo.start.to(int) == 12  # lo stuzi poi zoi gy. zarc .gy. cfari bu'u ke'a
    # le javni cu ca'o kalri vi gi'e traji lo ka nenri
    check typo.rule.to(cstring) == "sumti-6 97"  # le javni pe li soze
    # lo zunsna cu romoi
    check typo.stream.occurrences[3].reading.kind.to(cstring) == "Cmene"  # `CLL 4.8`
    # `.i.ai` .a `.ia.i`
    #   .i selfi'i
    let tie = parseLojban("iai")  # `CLL 4.9` le javni pe li ci
    check tie.refusal.to(cstring) == "Stream"
    # re fendi cu nitcu lo mecraide'a
    check tie.stream.refusal.to(cstring) == "Split"  # `CLL 3.3`
    check tie.stream.detail.to(cstring) == "ia i, or i ai"


  test "Byte of refusal counts text in UTF-8, apart from index of JavaScript string":
    let
      # `CLL 19.10`
      #   .i zo la'o sitna pa cmene
      #   .i selfi'i
      text = "la'o gy. Größe .gy. cu barda le zarc"
      start = parseLojban(cstring(text)).start.to(int)
    # le stuzi cu se kancu ta'i `Nim`
    check start == text.find("zarc")  # lo stuzi poi zoi gy. zarc .gy. cfari bu'u ke'a
    check start == 34
    check cstring(text).toJs.indexOf(cstring("zarc")).to(int) == 32  # `ö` .e `ß` du pa pagbu


  test "NIF of every fourth sentence of sample that reads reads back, and rebuilds tree whole":
    var count = 0
    for k in countup(0, SENTENCES_TATOEBA.high, STRIDE_NIF):
      if SENTENCES_TATOEBA[k].verdict.len > 0: continue  # lo nu to'e curmi cu vasru no tricu
      let reading = SENTENCES_TATOEBA[k].text.readText
      check reading.isReadBack  # `test_nif.nim` to le flalu pe le jbezba toi
      inc count
    check count >= COUNT_TREES_LEAST  # `IX.3` to lo bandu cu ralte lo jufra poi se tcidu toi


  test "parseLojbanToNif gives module native build writes, and null where text is refused":
    check $parseLojbanToNif(cstring(EXAMPLE_NIF.text)) == EXAMPLE_NIF.module  # `test_nif.nim`
    # le selci'a cu selfi'i
    check parseLojbanToNif("mi klama le zarc").isNil  # lo nu to'e curmi cu vasru no tricu
    # zo la'o
    #   .i selfi'i
    let quoted = $parseLojbanToNif("la'o gy. Größe .gy.")  # `CLL 19.10`
    # lo stuzi poi na mleca li parebi cu pagre lo lerpoi pe `JavaScript`
    check "\"Größe\"" in quoted  # le stuzi pe `UTF-8` na selga'i


# lo famna'u pe le nu cipra ba lo nu ro cipra cu selsku
reportEnd(if countFailures() > 0: 1 else: 0)
