## cipra lo nu `prose.nim` tcidu lo prosa
##   .i le cipra cu cipra lo nu sitna .e lo nu vimcu .e zo zei .e lo cmavo be `BAhE` be'o .e zo bu
##       .e lo cnivla ja'i `CLL 4` .e `CLL 6` .e `CLL 13` .e `CLL 17` .e `CLL 19`
##   .i ba bo le cipra cu cipra le gerna pe `CLL 21.1`
##
## ni'o lo mupli cu fukpi lo selci'a pe `CLL` gi'e no roi fukpi lo selja'o be le genturfa'i
##   .i lo linji pe pa jufra cu seljo'e
##   .i lo selci'a poi no krasi cu vasru ke'a se tcita lu se finti li'u
##
## ni'o lo flalu cu cipra lo mupli poi se sitna ku'o bu'u ro stuzi poi zvati lo jbini be le valsi pe
##     le mupli
##   .i lo flalu cu cipra ro cmavo pe le cmavo liste to `Article IX.3` toi
##
## ni'o `test_corpus.nim` tcidu ro mupli pe `CLL 1.1` fi lo selcpa poi seljva le notci pe `CLL`
##   .i lo javni pe `CLL 19.16` dunda lo pagbu .e lo gensu'a lo mupli poi le vi cipra cu sitna ke'a
##   .i le vi cipra cu cipra le pagbu .e le gensu'a

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, sequtils, strutils, unittest]

import ../../src/ricysoho/[grammar, prose, selmaho, stream, tanru]
import ../../src/ricysoho/lists/cmavo


const
  EXAMPLES = [
    "bridi zei valsi", "xy. zei kantu", "kulnr,farsi zei lolgai",
    "na'e zei .a zei na'e zei by. livgyterbilma", ".cerman. zei jamkarce",
    "na'e zei .a zei na'e zei by. zei livgyterbilma", "me la'o ly. spaghetti .ly.",
    "mi cusku lo'u li mi le'u", "mi cusku zo .ai", "mi cusku zoi kuot. I'm John .kuot.",
    ".ui la djan klama", ".ui mi facki fi le mi mapku", ".uiro'obe'unai", "mi .e .ui nai do",
    "mi .e nai .ui do", ".o'onai bu'o", ".iu bu'onai .uinai", "zo bu", "ky.bu .ubu .abu cy. ky.",
    "zai .devanagar. bu", "tei .ebu .akut.bu foi ty. tei .akut.bu .ebu foi",
    ".y'y.bu .abu ny. vo zy. .ibu vo", "mi viska le fu'e .ia blanu zdani fu'o ponse",
    "lo'u mi du do du la djan. le'u na tergerna la lojban.",
    "lu le mlatu cu viska le finpe li'u zo'u lo'u viska le le'u cu selbasti .ei lo'u viska lo " &
      "le'u",
    "la tcarlis. cusku lo'u le ninmu cu morsi le'u .iku'i ri jmive", "zo si cu lojbo valsi",
    "zoi gy. John is a man .gy. cu glico jufra",
    "mi djuno fi le valsi po'u zoi jai. gyrations .jai.",
    "zoi ry. sku .ry. cu rafsi zo cusku", "zo .bab. cmene la bab.", "zo .bab. cmene la'e zo .bab.",
    "la'o dy. Goethe .dy. cu me la'o ly. Homo sapiens .ly.", "ti gerku si mlatu",
    "ta blanu zdani si si xekri zdani", "zo .bab. se cmene zo si si si la bab.",
    "mi cusku zoi fy. gy. .fy. si si si si zo .djan.", "mi se cmene zo .djan. si si zo .djordj.",
    "mi viska le sa .i mi cusku zo .djan.", "mi viska le blanu .zdan. sa le xekri zdani",
  ]
    ## lo mupli po'u `CLL 4.38-44, 6.92-94, 13.2, 13.9, 13.55, 13.61-62, 13.74-75, 17.10-12,
    ##     17.18-19, 19.42, 19.44-45, 19.47-49, 19.51-53, 19.57, 19.75-77, 19.79-81, 19.83` ta'i le
    ##     porsi
  FLOOR_ERASED = 150
    ## lo mecraiterkancu be lo stuzi poi le flalu pe lo nu vimcu cu tcidu ke'a
    ##   .i le flalu cu tcidu 162 stuzi
    ##   .i le stuzi cu zvati lo jbini be lo valsi pe ro mupli poi vasru no nu vimcu
    ##   .i ku'i le flalu cu tcidu no stuzi poi se lidne zo zo .a zo zoi .a zo la'o



#[ ni'o ni'o ni'o lo tcidu ]#

func unitsRead(text: string): Option[seq[seq[string]]] =
  ## tcidu lo prosa gi'e dunda lo liste be lo lerfu pe lo valsi poi ro genvla cu vasru ke'a
  ##   .i dunda no da va'o lo nu le prosa cu se to'e curmi
  let reading = text.readText
  if not reading.is_read: return none(seq[seq[string]])
  some(reading.units.mapIt(it.words.mapIt(reading.occurrences[it].text)))


func cmavoUnits(reading: ReadingText): seq[seq[string]] =
  ## liste lo valsi poi le genturfa'i cu tcidu ro valsi pe ro genvla ta'i ke'a
  reading.units.mapIt(it.words.mapIt($reading.occurrences[it].reading.tanru))


func terminalsRead(text: string): Option[seq[Terminal]] =
  ## tcidu lo prosa gi'e dunda lo liste be lo genvla pe ro pagbu
  ##   .i dunda no da va'o lo nu le prosa cu se to'e curmi
  let reading = text.readText
  if reading.is_read: some(reading.units.mapIt(it.terminal)) else: none(seq[Terminal])


func refusalRead(text: string): Option[(RefusalText, int)] =
  ## tcidu lo prosa gi'e dunda lo javni poi to'e curmi le prosa ku'o .e lo stuzi poi le javni cu
  ##     cmene ke'a
  ##   .i dunda no da va'o lo nu le prosa cu se tcidu
  let reading = text.readText
  if reading.is_read: none((RefusalText, int)) else: some((reading.refusal, reading.start))


func leaves(node: Node): seq[int] =
  ## dunda lo liste be lo namcu pe ro genvla poi zvati ne'i le jgena ku'o ta'i le porsi pe le tricu
  if node.is_terminal: return @[node.at]
  for child in node.children: result.add child.leaves


func shape(node: Node): string =
  ## ciska le tarmi be le tricu ta'i lo lerpoi
  ##   .i lo genvla cu se ciska ta'i lo namcu pe vo'a po'o
  if node.is_terminal: return $node.at
  result = node.rule & "<" & $node.number & ">("
  for child in node.children: result.add child.shape & " "
  result.add ")"



suite "Chapter 4":
  test "Section 4.6":
    check "bridi zei valsi".unitsRead == some(@[@["bridi", "zei", "valsi"]])  # `CLL 4.38` mupli
    check "xy. zei kantu".terminalsRead == some(@[Selmaho.Zei.toTerminal])  # `CLL 4.39` mupli
    check "na'e zei .a zei na'e zei by. livgyterbilma".unitsRead.get.len ==
        2  # `CLL 4.41` mupli to pa porsi pe zo zei lidne pa lujvo toi
    check "na'e zei .a zei na'e zei by. zei livgyterbilma".unitsRead.get.len ==
        1  # `CLL 4.43` mupli to le selci'a cu du pa porsi pe zo zei toi
    # zo zei jorne re valsi
    check "mi zei".refusalRead == some((RefusalText.Construct, 3))  # `CLL 4.6` to selfi'i toi


  test "Section 4.7":
    check "me la'o ly. spaghetti .ly.".unitsRead ==
        some(@[@["me"], @["la'o", "ly", "spaghetti", "ly"]])  # `CLL 4.44` mupli



suite "Chapter 6":
  test "Section 6.14":
    check "mi cusku lo'u li mi le'u".unitsRead ==
        some(@[@["mi"], @["cusku"], @["lo'u", "li", "mi", "le'u"]])  # `CLL 6.92` mupli
    # le selci'a cu mupli
    check "mi cusku zo .ai".unitsRead == some(@[@["mi"], @["cusku"], @["zo", "ai"]])  # `CLL 6.93`
    check "mi cusku zoi kuot. I'm John .kuot.".unitsRead ==
        some(@[@["mi"], @["cusku"], @["zoi", "kuot", "I'm John", "kuot"]])  # `CLL 6.94` mupli



suite "Chapter 13":
  test "Section 13.1-2":
    # lo cnivla cu krasi le selci'a
    #   .i le javni pe li 0 cu tcidu le cnivla
    check ".ui la djan klama".terminalsRead.get[0] ==
        Selmaho.Ui.toTerminal  # `CLL 13.2` mupli
    check ".ui mi facki fi le mi mapku".terminalsRead.isSome  # `CLL 13.9` mupli


  test "Section 13.7-10":
    # ro le cnivla cu krasi le selci'a
    check ".uiro'obe'unai".terminalsRead.get.len == 4  # `CLL 13.55` mupli
    # zo ui .e zo nai pagbu pa cnivla gi'e tcita zo .e
    check "mi .e .ui nai do".unitsRead.get[1] ==
        @["e", "ui", "nai"]  # `CLL 13.61` mupli
    check "mi .e nai .ui do".unitsRead.get[1 .. 2] ==
        @[@["e"], @["nai", "ui"]]  # `CLL 13.62` mupli to zo nai pagbu `ek` gi'e se tcita toi
    for text in [".o'onai bu'o", ".iu bu'onai .uinai"]:
      check text.terminalsRead.isSome  # `CLL 13.74-75` mupli



suite "Chapter 17":
  test "Section 17.4-8":
    check "zo bu".unitsRead == some(@[@["zo", "bu"]])  # `CLL 17.10` mupli to zo bu se sitna toi
    check "ky.bu .ubu .abu cy. ky.".unitsRead ==
        some(@[@["ky", "bu"], @["u", "bu"], @["a", "bu"], @["cy"], @["ky"]])  # `CLL 17.11` mupli
    # lo cmene cu binxo pa lervla
    check "zai .devanagar. bu".unitsRead ==
        some(@[@["zai"], @["devanagar", "bu"]])  # `CLL 17.12` mupli
    check "tei .ebu .akut.bu foi ty. tei .akut.bu .ebu foi".terminalsRead.isSome  # `CLL 17.18`
    check ".y'y.bu .abu ny. vo zy. .ibu vo".terminalsRead.isSome  # `CLL 17.19` mupli
    # le cukta cu cusku zoi gy. abubu is legal .gy.
    check ".abubu".unitsRead == some(@[@["a", "bu", "bu"]])  # `CLL 17.4`
    # zo bu nitcu pa valsi poi lidne zo bu
    check "bu".refusalRead == some((RefusalText.Construct, 0))  # `CLL 17.4` to selfi'i toi



suite "Chapter 19":
  test "Section 19.8":
    # zo fu'e .e zo fu'o tcita lo valsi poi lidne le re cmavo to `CLL 19.16` toi
    check "mi viska le fu'e .ia blanu zdani fu'o ponse".unitsRead == some(@[
      @["mi"], @["viska"], @["le", "fu'e", "ia"], @["blanu"], @["zdani", "fu'o"], @["ponse"],
    ])  # `CLL 19.42` mupli


  test "Section 19.9":
    check "lo'u mi du do du la djan. le'u na tergerna la lojban.".unitsRead.get[0].len ==
        # le nu sitna cu mulno
        #   .iju le se sitna cu mapti le gerna
        8  # `CLL 19.44` mupli
    check "la tcarlis. cusku lo'u le ninmu cu morsi le'u .iku'i ri jmive".terminalsRead.isSome
      # `CLL 19.47` mupli
    # zo lo'u sitna su'o pa valsi
    check "lo'u le'u".refusalRead == some((RefusalText.Quotation, 5))  # `CLL 21.1`
    # zo le'u fanmo le nu sitna
    check "lo'u mi".refusalRead == some((RefusalText.Quotation, 5))  # `CLL 19.9`


  test "Section 19.10":
    # zo si se sitna
    check "zo si cu lojbo valsi".unitsRead.get[0] == @["zo", "si"]  # `CLL 19.48` mupli
    check "zoi gy. John is a man .gy. cu glico jufra".unitsRead.get[0] ==
        @["zoi", "gy", "John is a man", "gy"]  # `CLL 19.49` mupli
    # le cukta cu cusku zoi gy. ungrammatical as written .gy.
    check "mi djuno fi le valsi po'u zoi gy. gyrations .gy.".readText.refusal ==
        RefusalText.Stream  # `CLL 19.50` mupli
    check "mi djuno fi le valsi po'u zoi jai. gyrations .jai.".terminalsRead.isSome  # `CLL 19.51`
    check "zoi ry. sku .ry. cu rafsi zo cusku".terminalsRead.isSome  # `CLL 19.52` mupli
    check "zo .bab. cmene la'e zo .bab.".terminalsRead.isSome  # `CLL 19.54` mupli
    check "la'o dy. Goethe .dy. cu me la'o ly. Homo sapiens .ly.".terminalsRead.isSome  # `19.57`

    # zo zo poi fanmo le selci'a ne'i ro pagbu poi lo nu sitna cu dunda pa valsi ke'a
    #   .i lo tcidu pe `#859` zi'e poi curmi cu facki lo du'u `mi cusku zo` se tcidu
    #   .i simsa lo nu zo zo sitna pa valsi
    check "mi cusku zo".refusalRead ==
        some((RefusalText.Quotation, 9))  # `CLL 19.10` to zo zo sitna lo bavla'i gi'e fanmo toi
    # selfi'i
    check "zo".refusalRead == some((RefusalText.Quotation, 0))  # `CLL 19.10` zo zo po'o
    check "mi klama si zo".refusalRead ==
        # lo nu vimcu cu lidne zo zo
        #   .i selfi'i
        some((RefusalText.Quotation, 12))  # `CLL 19.13`
    check "mi cusku zo zo".unitsRead ==
        # zo zo se sitna
        #   .i selfi'i
        some(@[@["mi"], @["cusku"], @["zo", "zo"]])  # `CLL 19.10`
    # zo zo koivla
    check "mi cusku zoi zo gy zo".unitsRead ==
        some(@[@["mi"], @["cusku"], @["zoi", "zo", "gy", "zo"]])  # `CLL 19.10` to selfi'i toi
    check "lo'u mi zo".refusalRead ==
        some((RefusalText.Quotation, 8))  # `CLL 19.9` to ne'i zo lo'u poi zo le'u na fanmo ke'a toi


  test "Section 19.13":
    check "ti gerku si mlatu".terminalsRead == "ti mlatu".terminalsRead  # `CLL 19.75` mupli
    check "ta blanu zdani si si xekri zdani".terminalsRead ==
        "ta xekri zdani".terminalsRead  # `CLL 19.76` mupli
    # lo nu sitna pe zo zo vasru re valsi
    check "zo .bab. se cmene zo si si si la bab.".unitsRead ==
        "zo .bab. se cmene la bab.".unitsRead  # `CLL 19.77` mupli
    # le cukta cu cusku zoi gy. four words have been uttered .gy.
    check "mi cusku zoi fy. gy. .fy. si si si si zo .djan.".unitsRead ==
        "mi cusku zo .djan.".unitsRead  # `CLL 19.79` mupli
    check "mi se cmene zo .djan. si si zo .djordj.".unitsRead ==
        "mi se cmene zo .djordj.".unitsRead  # `CLL 19.80` mupli
    # le cukta cu skicu le selci'a fo zoi gy. parser will reject .gy.
    check "mi se cmene zo .djan. si .djordj.".refusalRead ==
        some((RefusalText.Quotation, 26))  # `CLL 19.13`
    # le jufra poi lidne zo .i selvi'u
    check "mi viska le sa .i mi cusku zo .djan.".unitsRead ==
        ".i mi cusku zo .djan.".unitsRead  # `CLL 19.81-82` mupli
    # zo le fanmo lo nu zo sa vimcu
    check "mi viska le blanu .zdan. sa le xekri zdani".unitsRead ==
        "mi viska le xekri zdani".unitsRead  # `CLL 19.83` mupli
    # zo si nitcu pa valsi poi lidne zo si
    check "si".refusalRead == some((RefusalText.Construct, 0))  # `CLL 19.13` to selfi'i toi


  test "Section 19.13, Example 19.78":
    # lo'u .e speranto le'u selvi'u ta'i re valsi
    check "mi tavla fo la .esperanto si si .esperanton.".unitsRead ==
        "mi tavla fo la .esperanton.".unitsRead  # `CLL 19.78` mupli


  test "Section 19.15":
    # le selci'a cu selfa'o
    check "mi klama fa'o 日本".unitsRead == some(@[@["mi"], @["klama"]])  # `CLL 19.15`
    # zo fa'o poi se sitna cu fanmo no selci'a
    check "zo fa'o cu cmavo".unitsRead.get[0] == @["zo", "fa'o"]  # `CLL 19.15`

    # zo fa'o poi fanmo le selci'a ne'i ro pagbu poi lo nu sitna cu dunda pa valsi ke'a
    #   .i lo tcidu pe `#859` zi'e poi curmi cu facki lo du'u `mi cusku zo fa'o` se tcidu ta'i zo zo
    #       po'o
    #   .i se ki'u bo le valsi poi se sitna cu selcri
    #   .i va'o lo nu zo fa'o na se sitna kei le selci'a cu selfa'o
    check "mi klama fa'o".unitsRead == some(@[@["mi"], @["klama"]])  # `CLL 19.15`
    # zo zo cu ka'e sitna ro valsi
    check "mi cusku zo fa'o".unitsRead ==
        some(@[@["mi"], @["cusku"], @["zo", "fa'o"]])  # `CLL 19.10` to selfi'i toi
    # ro valsi cu ka'e koivla
    check "mi cusku zoi fa'o gy fa'o".unitsRead ==
        some(@[@["mi"], @["cusku"], @["zoi", "fa'o", "gy", "fa'o"]])  # `CLL 19.10`
    # zo la'o simsa zo zoi
    check "mi cusku la'o fa'o gy fa'o".unitsRead ==
        some(@[@["mi"], @["cusku"], @["la'o", "fa'o", "gy", "fa'o"]])  # `CLL 19.10`
    # zo le'u fanmo le nu sitna
    #   .i le stuzi cu du le stuzi pe le romoi valsi poi se sitna
    check "mi cusku lo'u fa'o".refusalRead ==
        some((RefusalText.Quotation, 14))  # `CLL 19.9`
    # le gerna cu sisti bu'u le fanmo be le selci'a
    check "mi klama le fa'o ko".refusalRead ==
        some((RefusalText.Grammar, 12))  # `CLL 19.15` to selfi'i toi



const
  SIGNS_PROSE = [
    ("€", "ronru'u"), ("$", "rupnu"), ("£", "rupnu"), ("¢", "fepni"),
    ("¥", "ponjo ja jungo rupnu"),
  ]
    ## lo jdini sinxa .e lo valsi poi le sinxa cu sinxa ke'a to `D1 a` pe `#1003` toi
  NUMBERS_PROSE = ["5", "86,000,704.75"]  ## lo namcu poi le jdini sinxa cu pencu ke'a
  FRAMES_PROSE = [
    "_ cu cmalu", "mi ponse _", "mi dunda _ do", "lo jdima cu du _", "mi ponse ci _",
    "mi ponse _ .e _",
  ]
    ## lo jufra poi ro sumti po'u `_` cu jdini klani
  COUNT_AMOUNTS = 120  ## lo te kancu be lo jufra poi le flalu cu tcidu ke'a
  PREFIXES_PROSE = [("+", "ma'u"), ("-", "ni'u"), ("−", "ni'u"), ("~", "ji'i")]
    ## lo sinxa poi lidne lo namcu .e le cmavo poi le sinxa cu sinxa ke'a to `D4 b` pe `#1003` toi
  CONSTANTS_PROSE = [("π", "pai"), ("∞", "ci'i"), ("½", "pa fi'u re")]
    ## lo sinxa poi sinxa pa namcu .e le cmavo poi le sinxa cu sinxa ke'a to `D4 b` pe `#1003` toi
  FRAMES_NUMBER = [
    "li _ cu barda", "mi ponse _ lo plise", "lo _moi cu klama", "mi ponse lo rupnu be li _ be'o ku",
  ]
    ## lo jufra poi ro namcu po'u `_` cu pagbu ke'a
  COUNT_NUMBERS_SIGNED = 148  ## lo te kancu be lo jufra poi le flalu cu tcidu ke'a
  NUMBERS_COMPOUND = [("1.2.3", "1 pi'e 2 pi'e 3"), ("192.168.0.1", "192 pi'e 168 pi'e 0 pi'e 1")]
    ## lo namcu poi vasru su'o re boi denpa bu .e le valsi poi le namcu cu sinxa ke'a to `D5 c`
    ##     pe `#1003` toi
  COUNT_COMPOUND = 8  ## lo te kancu be lo jufra poi le flalu cu tcidu ke'a



suite "Internal: Prose":
  test "Each currency sign at each place of a sumti reads as the tree of its words written out":
    # `Architect` jdice `D2 a` bu'u `#1003`
    #   .i lo jdini sinxa cu sinxa lo valsi po'o
    #   .i se ki'u bo lo tricu pe le selci'a cu mintu lo tricu pe le valsi
    var count = 0
    for (sign, words) in SIGNS_PROSE:
      for number in NUMBERS_PROSE:
        for amount in [sign & number, number & sign]:
          let spelled = "lo " & words & " be li " & number & " be'o ku"
          for frame in FRAMES_PROSE:
            let (a, b) = (frame.replace("_", amount).readText, frame.replace("_", spelled).readText)
            checkpoint frame.replace("_", amount)
            check a.is_read and b.is_read
            if a.is_read and b.is_read:
              check a.units.mapIt($it.terminal) == b.units.mapIt($it.terminal)
              check a.tree.shape == b.tree.shape
              check a.cmavoUnits == b.cmavoUnits  # le valsi pe ro genvla cu mintu
            inc count
    check count == COUNT_AMOUNTS  # `IX.3`
    # lo jdini klani cu sumti gi'e na selbri
    check not "lo jdima cu €5".readText.is_read
    # zo zo sitna zo lo noi krasi le jdini klani
    #   .i se ki'u bo le gerna cu to'e curmi le selci'a
    check not "zo €5 cu valsi".readText.is_read


  test "Each number sign at each place of a number reads as the tree of its words written out":
    # `Architect` jdice le cmavo bu'u `#1003` ta'i `D4 b`
    #   .i lo sinxa pe lo namcu cu sinxa lo valsi po'o
    #   .i se ki'u bo lo tricu pe le selci'a cu mintu lo tricu pe le valsi
    var
      count = 0
      pairs: seq[(string, string, seq[string])]  # lo selci'a .e lo valsi .e lo jufra
    for number in NUMBERS_PROSE:
      for (sign, word) in PREFIXES_PROSE:
        pairs.add (sign & number, word & " " & number, @FRAMES_NUMBER)
        # lo jdini klani cu vasru le sinxa pe le namcu to `CLL 18.3` toi
        pairs.add (sign & number & "€", "lo ronru'u be li " & word & " " & number & " be'o ku",
          @FRAMES_PROSE)
      pairs.add (number & "%", number & " ce'i", @FRAMES_NUMBER)  # `CLL 18.3`
    for (sign, words) in CONSTANTS_PROSE: pairs.add (sign, words, @FRAMES_NUMBER)
    pairs.add ("-5%", "ni'u 5 ce'i", @FRAMES_NUMBER)
    # lo sinxa poi pencu lo drata sinxa pe le namcu cu se tcidu to `D7 c` toi
    pairs.add ("-∞", "ni'u ci'i", @FRAMES_NUMBER)
    pairs.add ("~½", "ji'i pa fi'u re", @FRAMES_NUMBER)
    for (text, spelled) in [
        ("-$5", "lo rupnu be li ni'u 5 be'o ku"), ("$-5", "lo rupnu be li ni'u 5 be'o ku"),
        ("€½", "lo ronru'u be li pa fi'u re be'o ku"), ("5%€", "lo ronru'u be li 5 ce'i be'o ku")]:
      pairs.add (text, spelled, @FRAMES_PROSE)
    # lo kutle'u cu fendi le jdini klani .e le drata namcu to `D8` pe `#1003` toi
    #   .i le namcu pe zoi gy. 5% €5 .gy. cu klani le jdini klani
    for (text, spelled) in [
        ("5€ .e li -5", "lo ronru'u be li 5 be'o ku .e li ni'u 5"),
        ("5% €5", "5 ce'i lo ronru'u be li 5 be'o ku")]:
      pairs.add (text, spelled, @FRAMES_PROSE)
    for (text, spelled, frames) in pairs:
      for frame in frames:
        let (a, b) = (frame.replace("_", text).readText, frame.replace("_", spelled).readText)
        checkpoint frame.replace("_", text)
        check a.is_read and b.is_read
        if a.is_read and b.is_read:
          check a.units.mapIt($it.terminal) == b.units.mapIt($it.terminal)
          check a.tree.shape == b.tree.shape
          check a.cmavoUnits == b.cmavoUnits  # le valsi pe ro genvla cu mintu
        inc count
    check count == COUNT_NUMBERS_SIGNED  # `IX.3`
    # zo zo sitna le pamoi valsi pe le sinxa
    #   .i se ki'u bo le gerna cu to'e curmi le selci'a
    check not "zo ½ cu valsi".readText.is_read
    # le gerna cu to'e curmi le drata namcu poi no valsi cu dunda lo stuzi ke'a
    check "mi ponse 5€ -5".refusalRead == some((RefusalText.Grammar, 16))


  test "Run of digits with two or more periods reads as its words and tree with pi'e written out":
    # `Architect` jdice `D5 c` bu'u `#1003`
    #   .i ro boi denpa bu pe le namcu cu sinxa zo pi'e
    var count = 0
    for (text, spelled) in NUMBERS_COMPOUND:
      for frame in FRAMES_NUMBER:
        let (a, b) = (frame.replace("_", text).readText, frame.replace("_", spelled).readText)
        checkpoint frame.replace("_", text)
        check a.is_read and b.is_read
        if a.is_read and b.is_read:
          check a.units.mapIt($it.terminal) == b.units.mapIt($it.terminal)
          check a.tree.shape == b.tree.shape
          check a.cmavoUnits == b.cmavoUnits  # le valsi pe ro genvla cu mintu
        inc count
    check count == COUNT_COMPOUND  # `IX.3`


  test "Words of each tree, in order, are words of text that erasure leaves":
    var count = 0
    for text in EXAMPLES:
      let reading = text.readText
      check reading.is_read
      if not reading.is_read: continue
      # le pezli cu du le genvla ta'i le porsi
      check reading.tree.leaves == toSeq(0 ..< reading.units.len)  # `#815`
      let held = reading.units.mapIt(it.words).concat
      # lo nu vimcu cu ralte le porsi be lo valsi poi stali
      check held == held.sorted  # `CLL 19.13`
      inc count
    check count == EXAMPLES.len  # ja'i `IX.3` lo bandu cu ralte ro mupli


  test "Word and si after it, at each place between words, change no terminal":
    var count = 0
    for text in EXAMPLES:
      let
        words = text.splitWhitespace
        terminals = text.terminalsRead
      if words.anyIt(it in ["si", "sa", "su"]): continue  # le mupli cu vasru lo nu vimcu
      for at in 1 ..< words.len:
        # lo valsi poi se lidne le cmavo cu se sitna
        if words[at - 1] in ["zo", "zoi", "la'o"]: continue
        let erasing = (words[0 ..< at] & @["broda", "si"] & words[at .. ^1]).join(" ")
        # le cukta cu cusku zoi gy. as if it had never been spoken .gy.
        check erasing.terminalsRead == terminals  # `CLL 19.13`
        inc count
    check count >= FLOOR_ERASED  # ja'i `IX.3` lo bandu cu ralte lo nu vimcu


  test "zo quotes each cmavo of cmavo list as one terminal":
    var count = 0
    for entry in LIST_CMAVO:
      if '.' in entry.word: continue  # le liste cu ciska lo denpa ta'i denpa bu
      # le cukta cu cusku zoi gy. any Lojban word whatsoever .gy.
      check ("zo " & entry.word).terminalsRead ==
          some(@[Selmaho.Zo.toTerminal])  # `CLL 19.10`
      inc count
    # 598 valsi pe le liste cu vasru pa cmavo
    check count >= 590  # ja'i `IX.3` lo bandu cu ralte lo cmavo pe le liste


  test "Tie of stream is refused, though grammar reads one split alone":
    # le ciska cu cusku lo cmene po'u `lauras`
    #   .i selfi'i
    let stream = "la .lauras. klama".readStream
    # zo la na krasi lo cmene
    #   .i mupli fa `laplas.`
    check not stream.is_read and
        stream.detail == "lau ras, or la uras"  # `CLL 4.8`
    # le gerna cu jdice fi no ve fendi poi dunli
    check "la .lauras. klama".refusalRead ==
        some((RefusalText.Stream, 4))  # `D4 a` pe `#811`
    # `fragment` poi vasru pa sumti
    check "la la .uras. klama".terminalsRead.isSome  # `CLL 21.1`
    # lo cmavo be `LAU` cu nitcu pa lervla
    check "la lau .ras. klama".refusalRead ==
        some((RefusalText.Grammar, 8))  # le javni pe li 987 pe `CLL 21.1`
