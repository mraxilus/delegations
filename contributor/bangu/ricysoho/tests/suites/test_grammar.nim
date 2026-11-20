## cipra lo du'u `grammar.nim` tcidu lo mupli pe `CLL 5` ja'i le ci'erge'a pe `CLL 21.1` simsa lo nu
##     `CLL 5` tcidu le mupli
##   .i cipra ji'a lo flalu poi ro tricu cu mapti ke'a
##
## ni'o lo mupli cu selfu'i fi lo selci'a pe `CLL` gi'e no roi selfu'i fi lo selja'o be le
##     genturfa'i
##   .i lo linji pe pa jufra cu seljo'e
##   .i lo selci'a poi no krasi cu vasru ke'a se tcita lu se finti li'u
##   .i lo kurfa grile'u pe `CLL` sinxa lo valsi poi lo selci'a cu ka'e claxu ke'a to `CLL 5.5` toi
##   .i se ki'u bo ro mupli cu se tcidu ta'i lo nu vasru le valsi kei .e lo nu claxu le valsi
##
## ni'o le se sitna pe le cipra cu du lo valsi poi `CLL` gunma ke'a ne'i lo prosa .e lo vlafanva
##     ta'i lo selku'e be lo javni ku'o .e lo famvla poi `CLL 21.1` ciska ke'a fi lo jbini be re `/`
##   .i le vi datnyvei cu liste le se sitna gi'e sepli `grammar.nim`
##
## ni'o `test_corpus.nim` tcidu ro mupli pe `CLL 1.1` fi lo selcpa poi seljva le notci pe `CLL`
##   .i le vi cipra cu cipra le tricu pe le mupli poi le vi cipra cu sitna ke'a
##   .i `test_prose.nim` cipra lo nu sitna .e lo nu vimcu .e zo zei .e zo bu vu'o noi galfi pu lo nu
##       le gerna cu tcidu
##
## ni'o le flalu pe le nu tcidu ro pagbu cu cipra lo du'u `readGrammar` noi tcidu ro pagbu be le
##     selci'a cu mintu `readWhole` noi tcidu le mulselci'a pa roi
##   .i le flalu cu tcidu ro selci'a pe le selci'agri zi'e poi selka'a ku'o .e le selci'a poi jorne
##       lo ju'agri pe pa prosa to `#849` toi

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/ricysoho/[grammar {.all.}, prose, selmaho, stream]
import ../articles_wikipedia/articles
import ../cll/examples
import ../sample_tatoeba/sentences


type
  Example = object
    ## skicu pa mupli pe `CLL` sepi'o le ckupaupau poi vasru le mupli ku'o .e le namcu .e le
    ##     jboselci'a pe le mupli
    section: string
    number: string
    text: string
      ## le jboselci'a pe le mupli
      ##   .i lo kurfa grile'u cu sinxa lo valsi poi lo selci'a cu ka'e claxu ke'a


const
  TERMINATORS_ELIDABLE = {
    Selmaho.Beho, Selmaho.Boi, Selmaho.Dohu, Selmaho.Fehu, Selmaho.Gehu, Selmaho.Kehe,
    Selmaho.Kei, Selmaho.Ku, Selmaho.Kuhe, Selmaho.Kuho, Selmaho.Lihu, Selmaho.Loho,
    Selmaho.Luhu, Selmaho.Mehu, Selmaho.Nuhu, Selmaho.Sehu, Selmaho.Tehu, Selmaho.Toi,
    Selmaho.Tuhu, Selmaho.Vau, Selmaho.Veho,
  }
    ## lo selma'o poi `CLL 21.1` ciska ke'a fi lo jbini be re `/` ta'i lo famvla poi lo selci'a cu
    ##     ka'e claxu ke'a
  COUNT_ELIDED = 12
    ## lo te kancu be lo mupli pe le vi datnyvei zi'e poi ciska lo fanmo valsi po'o ne'i lo kurfa
    ##     grile'u
  EXAMPLES = [
    Example(section: "5.1", number: "5.1", text: "do mamta mi"),
    Example(section: "5.1", number: "5.5", text: "ta blotrskunri"),
    Example(section: "5.2", number: "5.6", text: "tu pelnimre tricu"),
    Example(section: "5.2", number: "5.7", text: "la djan. barda nanla"),
    Example(section: "5.3", number: "5.19", text: "ta cmalu nixli bo ckule"),
    Example(section: "5.3", number: "5.20", text: "ta cmalu bo nixli ckule"),
    Example(section: "5.3", number: "5.21", text: "ta cmalu nixli ckule"),
    Example(section: "5.4", number: "5.25", text: "do mutce bo barda gerku bo kavbu"),
    Example(section: "5.4", number: "5.29", text: "ta melbi cmalu bo nixli bo ckule"),
    Example(section: "5.4", number: "5.30", text: "ta cmalu bo nixli bo ckule"),
    Example(section: "5.5", number: "5.32", text: "ta ke ke melbi cmalu ke'e nixli ke'e ckule"),
    Example(section: "5.5", number: "5.33", text:
      "ta ke ke ke melbi cmalu ke'e nixli ke'e ckule ke'e"
    ),
    Example(section: "5.5", number: "5.35", text: "ta melbi cmalu ke nixli ckule [ke'e]"),
    Example(section: "5.5", number: "5.36", text: "ta melbi ke cmalu nixli ckule [ke'e]"),
    Example(section: "5.5", number: "5.37", text: "ta melbi ke cmalu ke nixli ckule [ke'e] [ke'e]"),
    Example(section: "5.6", number: "5.41", text: "barda je xunre gerku"),
    Example(section: "5.6", number: "5.43", text: "barda je pelxu bo xunre gerku"),
    Example(section: "5.6", number: "5.43", text: "barda je ke pelxu xunre ke'e gerku"),
    Example(section: "5.6", number: "5.61", text: "gu'e barda gi xunre gerku"),
    Example(section: "5.6", number: "5.62", text: "gu'e barda je xunre gi gerku ja mlatu"),
    Example(section: "5.7", number: "5.64", text: "ti xamgu be do bei mi [be'o] zdani"),
    Example(section: "5.7", number: "5.65", text:
      "ti cmalu be le ka canlu bei lo'e ckule be'o nixli be li mu bei lo merko be'o bo ckule la " &
      "bryklyn. loi pemci le mela nu,IORK. prenu le jecta"
    ),
    Example(section: "5.7", number: "5.73", text: "le xamgu be do noi barda cu zdani"),
    Example(section: "5.7", number: "5.74", text: "le xamgu be do be'o noi barda cu zdani"),
    Example(section: "5.7", number: "5.75", text: "le xamgu be le ctuca [ku] be'o zdani"),
    Example(section: "5.8", number: "5.77", text: "ta zdani co blanu"),
    Example(section: "5.8", number: "5.80", text: "ta nixli [bo] ckule co cmalu"),
    Example(section: "5.8", number: "5.81", text: "ta cmalu ke nixli ckule [ke'e] co melbi"),
    Example(section: "5.9", number: "5.90", text: "la djan. go'i troci"),
    Example(section: "5.9", number: "5.92", text: "li vo nu'a su'i li re li re"),
    Example(section: "5.9", number: "5.94", text: "la prim. palvr. pamoi cusku"),
    Example(section: "5.9", number: "5.96", text: "ti nu zdile kei kumfa"),
    Example(section: "5.10", number: "5.99", text: "la BALtazar. cu me le ci nolraitru"),
    Example(section: "5.10", number: "5.104", text: "ta me lai kraislr. [me'u] karce"),
    Example(section: "5.10", number: "5.106", text:
      "re me le ci nolraitru me'u .e la djan. cu blabi"
    ),
    Example(section: "5.11", number: "5.110", text: "do se prami mi"),
    Example(section: "5.11", number: "5.112", text:
      "le zarci cu se ke cadzu klama [ke'e] la .alis."
    ),
    Example(section: "5.12", number: "5.116", text:
      "la .alis. cu na'e ke cadzu klama [ke'e] le zarci"
    ),
    Example(section: "5.12", number: "5.120", text:
      "mi na'e ke sutra cadzu be fi le birka [be'o] ke'e klama le zarci"
    ),
    Example(section: "5.12", number: "5.126", text:
      "mi na'e ke sutra cadzu be fi le birka je masno klama [be'o] [ke'e] le zarci"
    ),
    Example(section: "5.13", number: "5.127", text: "mi pu klama le zarci"),
    Example(section: "5.13", number: "5.131", text: "mi na pu na ca klama le zarci"),
    Example(section: "5.16", number: "5.151", text: "ke melbi cmalu bo nixli ke'e je ckule"),
    Example(section: "5.16", number: "5.151", text: "melbi bo cmalu bo nixli je ckule"),
    Example(section: "5.16", number: "5.163", text: "melbi jebo cmalu jebo nixli jebo ckule"),
    Example(section: "5.16", number: "5.171", text: "melbi je ke cmalu je nixli je ckule [ke'e]"),
  ]
    ## lo mupli pe ro ckupaupau pe `CLL 5` ne'i `CLL 1.1`
    ##   .i lo linji pe pa jufra cu seljo'e
  TEXTS_PASSES = [
    "mi klama .i do cadzu .ije do bajra ni'o la .alis. cusku lu mi citka .i do pinxe li'u",
    "mi klama .i tu'e do klama .i mi cadzu ni'o do cadzu",
    "lu do klama .i mi klama cu xamgu .i do cadzu",
    "mi to do klama .i do cadzu cu klama .i mi klama",
    ".i .i mi klama", "ni'o mi klama .i do klama", "mi klama ni'o", ".i ni'o mi klama",
    "mi klama .i", "ni'o ni'o mi klama ni'o ni'o do klama", "mi klama .ibabo do klama",
    "mi klama .i ba bo do klama", "mi klama .i ba do klama", "mi klama .i na je do klama",
    "ro da zo'u da klama .ije da cadzu .i da bajra", "tu'e mi klama .i do klama tu'u .i mi cadzu",
    "tu'e doi djan mi klama .i do klama", "ba tu'e mi klama .i do cadzu",
    "mi klama .i doi djan do cadzu", "mi klama ni'o doi djan do cadzu",
    "mi klama .i do cadzu ni'o ni'o mi bajra .i",
    "mi klama .i tu'e do klama .i tu'e mi cadzu .i do bajra",
    "mi klama .i tu'e do klama .i lu mi cadzu", "mi klama .i tu'e ni'o do klama .i mi cadzu",
    "mi klama .i .i do klama", "ni'o .i mi klama", "mi klama .i je", "mi klama .ije .i do klama",
    "mi klama .i pu ba bo do klama", "mi klama .i pu mi klama .i ba do klama",
    ".ije mi klama .i do klama", "mi klama .i tu'e .i do klama .i mi cadzu", "mi klama .i tu'e .i",
    "le .i mi klama", "mi klama le .i do klama", "mi klama .i lu do cadzu .i mi klama",
  ]
    ## lo selci'a poi vasru ro stuzi poi le nu tcidu ro pagbu cu katna bu'u ke'a gi'a tcidu le
    ##     mulselci'a bu'u ke'a
    ##   .i le selci'a cu vasru zo .i poi jorne no da ku'o .e zo .i poi jorne ku'o .e zo ni'o gi'e
    ##       selfi'i
    ##   .i ne'i le selci'a zo tu'e .e zo lu .e zo to cu ca'o kalri gi'a selfa'o
  CUTTING = {Selmaho.I, Selmaho.Niho, Selmaho.Tuhe, Selmaho.Lu, Selmaho.To}
    ## lo selma'o poi le nu tcidu ro pagbu cu katna bu'u ke'a ku'o .a lo selma'o poi krasi lo
    ##     selci'a ne'i lo selci'a
    ##   .i lo selci'a poi vasru no le selma'o cu vasru pa pagbu po'o
  COUNT_PASSES_LEAST = 300
    ## lo dzijimte be lo te kancu be lo se ciska poi le flalu pe le nu tcidu ro pagbu cu tcidu ke'a
    ##   .i le selci'a cu du lo selci'a poi pagbu le selci'agri gi'e vasru pa cmima be `CUTTING`
    ##       ku'o .e lo selci'a pe le vi datnyvei ge'u .e le selci'a poi jorne lo ju'agri pe pa
    ##       prosa to `Article IX.3` toi
  COUNT_KEPT_LEAST = 500
    ## lo dzijimte be lo te kancu be lo se ciska poi le flalu pe lo mulcmi poi stali cu tcidu ke'a
    ##   .i ro le selci'a cu cimoi lo selci'a gi'e vasru su'o ci genvla to `Article IX.3` toi
  STRIDE_KEPT = 3
    ## lo te kancu be lo selci'a poi le flalu pe lo mulcmi poi stali cu tcidu pa ke'a
    ##   .i le flalu cu tcidu ro cimoi selci'a ki'u lo jdima be le cipra
  SEED_KEPT = 975
    ## lo tsiju be lo cunso stuzi poi le flalu pe lo mulcmi poi stali cu vimcu lo genvla bu'u ke'a
  COUNT_PARTS_JOINED = 81
    ## lo te kancu be lo pagbu poi le nu tcidu ro pagbu cu katna le se ciska poi jorne lo ju'agri pe
    ##     pa prosa ku'o fi ke'a



#[ ni'o ni'o ni'o lo tcidu ]#

func occurrencesRead(text: string): seq[Occurrence] =
  ## tcidu lo porsi be lo valsi gi'e liste le valsi
  ##   .i lo porsi be lo valsi pe ro mupli pe `CLL` cu se tcidu ro roi
  let reading = text.readStream
  doAssert reading.is_read, "Stream of example should read; got `" & text & "`."
  reading.occurrences


func readingRead(text: string): ReadingGrammar =
  ## tcidu lo valsi pe lo porsi be lo valsi ta'i lo genvla
  ##   .i tcidu le genvla ja'i le gerna pe `CLL 21.1`
  var terminals: seq[Terminal]
  for occurrence in text.occurrencesRead:
    let terminal = occurrence.reading.toTerminal
    doAssert terminal.isSome, "Word of example should be terminal; got `" & occurrence.text & "`."
    terminals.add terminal.get
  terminals.readGrammar


func treeRead(text: string): Option[Node] =
  ## tcidu lo selci'a ja'i le gerna gi'e dunda le tricu pe le selci'a
  ##   .i va'o lo nu le gerna cu to'e curmi le selci'a kei dunda no da
  let reading = text.readingRead
  if reading.is_read: some(reading.tree) else: none(Node)


func terminalsStream(text: string): Option[seq[Terminal]] =
  ## dunda ro valsi pe lo porsi be lo valsi pe le selci'a ta'i lo genvla
  ##   .i va'o lo nu lo porsi be lo valsi cu se to'e curmi kei .a lo nu pa valsi cu vasru no genvla
  ##       kei dunda no da
  let stream = text.readStream
  if not stream.is_read: return none(seq[Terminal])
  var terminals: seq[Terminal]
  for occurrence in stream.occurrences:
    let terminal = occurrence.reading.toTerminal
    if terminal.isNone: return none(seq[Terminal])
    terminals.add terminal.get
  some(terminals)


func terminalsRead(text: string): Option[seq[Terminal]] =
  ## dunda le genvla poi `readText` ralte ke'a ku'o va'o lo nu le selci'a cu se tcidu
  ##   .i va'o lo drata ku dunda ro valsi pe le porsi be lo valsi
  let reading = text.readText
  if reading.is_read: some(reading.units.mapIt(it.terminal)) else: text.terminalsStream


func partsRead(text: string): Option[seq[Slice[int]]] =
  ## tcidu le genvla pe le selci'a gi'e dunda ro pagbu poi le nu tcidu ro pagbu cu katna le selci'a
  ##     fi ke'a
  let
    terminals = text.terminalsRead.get
    split = terminals.toParts(0, terminals.len)
  some(split.parts)


func isCutting(text: string): bool =
  ## jdice lo du'u xu kau lo porsi be lo valsi pe le selci'a cu vasru pa cmima be `CUTTING`
  ##   .i le valsi cu se tcidu ja'i lo tarmi be vo'a po'o pu lo nu le gerna cu tcidu
  let stream = text.readStream
  stream.is_read and stream.occurrences.anyIt(
    it.reading.toTerminal.isSome and it.reading.toTerminal.get.isAmong(CUTTING)
  )


func textJoined(): string =
  ## zbasu pa selci'a lo ju'agri poi se tcidu ba zo ni'o zi'e pe le prosa po'u `lo jbobau`
  ##   .i lo sinxa be lo ju'agri .a lo jufra be'o poi krasi le ju'agri cu selvi'u
  ##   .i zo ni'o zvati lo jbini be ro re lamji ju'agri
  ##
  ## ni'o le 23moi ju'agri pe le prosa cu selfa'o zo tu'e
  ##   .i le 29moi ju'agri cu vasru zo tu'u po'o gi'e na se tcidu
  ##   .i se ki'u bo zo tu'e cu ca'o kalri vi le fanmo be le selci'a
  var paragraphs: seq[string]
  for paragraph in PARAGRAPHS_WIKIPEDIA:
    if paragraph.article != "lo jbobau" or paragraph.verdict.len > 0: continue
    var text = paragraph.text
    for mark in ["ni'o ", ".i ", "i "]:
      if text.startsWith(mark): text = text[mark.len .. ^1]
    if ("ni'o " & text).readText.is_read: paragraphs.add text
  paragraphs.join(" ni'o ")


func refusalRead(text: string): Option[(int, string)] =
  ## tcidu lo selci'a ja'i le gerna gi'e dunda le stuzi .e le javni vu'o poi to'e curmi le selci'a
  ##   .i va'o lo nu le gerna cu tcidu le selci'a kei dunda no da
  let reading = text.readingRead
  if reading.is_read: none((int, string)) else: some((reading.at, reading.rule))


func leaves(node: Node): seq[int] =
  ## liste lo stuna'u pe ro genvla poi selvau le jgena ku'o ja'i le porsi pe le tricu
  if node.is_terminal: return @[node.at]
  for child in node.children: result.add child.leaves


func spans(node: Node, rule: string): seq[Slice[int]] =
  ## liste lo selku'e be ro jgena pe `rule` be'o poi vasru su'o re valsi ku'o ja'i lo porsi be lo nu
  ##     le jgena cu cfari
  if node.is_terminal: return
  let leaves = node.leaves
  if node.rule == rule and leaves.len >= 2: result.add leaves[0] .. leaves[^1]
  for child in node.children: result.add child.spans(rule)


func spansRead(text, rule: string): seq[Slice[int]] =
  ## tcidu lo selci'a ja'i le gerna gi'e liste lo selku'e be ro jgena pe `rule` be'o poi vasru su'o
  ##     re valsi
  let tree = text.treeRead
  doAssert tree.isSome, "Grammar should read example; got `" & text & "`."
  tree.get.spans(rule)


func shape(node: Node, words: openArray[string], dropped: openArray[int]): string =
  ## ciska le tricu ta'i lo javni noi vasru lo valsi
  ##   .i lo valsi pe `dropped` na selci'a
  if node.is_terminal: return (if node.at in dropped: "" else: words[node.at])
  let parts = node.children.mapIt(it.shape(words, dropped)).filterIt(it.len > 0)
  node.rule & "(" & parts.join(" ") & ")"


func shape(node: Node): string =
  ## ciska le tricu ta'i lo namcu pe lo javni noi vasru lo stuna'u pe lo genvla
  if node.is_terminal: return $node.at
  $node.number & "(" & node.children.mapIt(it.shape).join(" ") & ")"


func shape(reading: ReadingGrammar): string =
  ## ciska le se tcidu ta'i lo lerpoi
  ##   .i va'o lo nu le selci'a cu se tcidu kei ciska le tricu ta'i lo nu `shape` ciska
  ##   .i va'o lo drata ku ciska le stuzi .e le javni pe le nu to'e curmi
  if reading.is_read: reading.tree.shape else: "refused " & $reading.at & " " & reading.rule


func shapesRead(text: string): Option[tuple[passes, whole: string]] =
  ## tcidu le selci'a ta'i le nu tcidu ro pagbu kei .e lo nu tcidu le mulselci'a kei gi'e ciska ro
  ##     se tcidu
  ##   .i va'o lo nu le selci'a cu se tcidu kei le tricu pe le nu tcidu ro pagbu cu selcpa fi
  ##       `readText` noi tcidu le selci'a ta'i le nu tcidu ro pagbu
  ##   .i va'o lo drata ro valsi pe le porsi be lo valsi cu genvla
  let reading = text.readText
  if reading.is_read:
    let terminals = reading.units.mapIt(it.terminal)
    return some((reading.tree.shape, terminals.readWhole.shape))
  let terminals = text.terminalsStream
  if terminals.isNone: return none(tuple[passes, whole: string])
  some((terminals.get.readGrammar.shape, terminals.get.readWhole.shape))



#[ ni'o ni'o ni'o lo se karbi ]#

func withBracketed(text: string): string =
  ## ciska le mupli poi vasru ro valsi poi lo kurfa grile'u cu sinxa ke'a
  text.multiReplace(("[", ""), ("]", ""))


func withoutBracketed(text: string): string =
  ## ciska le mupli poi vasru no valsi poi lo kurfa grile'u cu sinxa ke'a
  text.splitWhitespace.filterIt(not it.startsWith("[")).join(" ")


func bracketedAt(text: string): seq[int] =
  ## liste lo stuna'u pe ro valsi poi lo kurfa grile'u cu sinxa ke'a ku'o ne'i ro valsi pe le mupli
  ##     poi vasru le valsi
  ##   .i ro selci'avla pe `CLL 5` du pa valsi pe lo porsi be lo valsi
  let tokens = text.splitWhitespace
  for i, token in tokens:
    if token.startsWith("["): result.add i



suite "Chapter 5":
  test "Each example of each section reads, with words square brackets mark and without":
    var count = 0
    for example in EXAMPLES:
      check example.text.withBracketed.treeRead.isSome  # le mupli ta'i le nu le cukta cu ciska
      # lo valsi cu ka'e selcau
      check example.text.withoutBracketed.treeRead.isSome  # `CLL 5.5`
      inc count
    check count == EXAMPLES.len


  test "Section 5.3":
    check "ta cmalu nixli bo ckule".spansRead("selbri-6") == @[2 .. 4]  # lo tertau ne'i `CLL 5.19`
    check "ta cmalu bo nixli ckule".spansRead("selbri-6") == @[1 .. 3]  # lo seltau ne'i `CLL 5.20`
    check "ta cmalu nixli ckule".spansRead("selbri-6").len == 0  # `CLL 5.21` to claxu zo bo toi


  test "Section 5.4":
    check "do mutce bo barda gerku bo kavbu".spansRead("selbri-6") ==
        @[1 .. 3, 4 .. 6]  # lo seltau .e lo tertau ne'i `CLL 5.25`
    check "ta melbi cmalu bo nixli bo ckule".spansRead("selbri-6") ==
        @[2 .. 6, 4 .. 6]  # lo nu gunma bu'u lo pritu ne'i `CLL 5.29`
    check "ta cmalu bo nixli bo ckule".spansRead("selbri-6") ==
        @[1 .. 5, 3 .. 5]  # `CLL 5.30` to mintu `CLL 5.19` toi


  test "Section 5.5":
    check "ta ke ke melbi cmalu ke'e nixli ke'e ckule".spansRead("tanru-unit-2") ==
        @[1 .. 7, 2 .. 5]  # `CLL 5.32`
    check "ta ke ke ke melbi cmalu ke'e nixli ke'e ckule ke'e".spansRead("tanru-unit-2") ==
        @[1 .. 10, 2 .. 8, 3 .. 6]  # `CLL 5.33`
    check "ta melbi ke cmalu nixli ckule".spansRead("tanru-unit-2") ==
        @[2 .. 5]  # `CLL 5.36` to zo ke'e selcau bu'u lo fanmo be le selbri toi
    check "ta melbi ke cmalu ke nixli ckule".spansRead("tanru-unit-2") ==
        @[2 .. 6, 4 .. 6]  # `CLL 5.37` to zo ke'e cu re roi selcau toi


  test "Section 5.7":
    check "le xamgu be do noi barda cu zdani".spansRead("linkargs") ==
        # le me `relative-clauses` cu ckini le romoi sumti pe zo be
        @[2 .. 5]  # `CLL 5.73`
    check "le xamgu be do be'o noi barda cu zdani".spansRead("linkargs") ==
        @[2 .. 4]  # `CLL 5.74` to zo be'o fanmo le sumti pe zo be toi
    check "le xamgu be do be'o noi barda cu zdani".spansRead("relative-clause") ==
        # le me `relative-clauses` cu ckini le sumti poi vasru zo be
        @[5 .. 6]  # `CLL 5.74`
    check "le xamgu be le ctuca be'o zdani".spansRead("sumti-6") ==
        @[0 .. 6, 3 .. 4]  # `CLL 5.75` to zo be'o fanmo le sumti pe zo be toi
    # va'o lo nu claxu zo ku .e zo be'o kei zo zdani pagbu le sumti pe zo be
    #   .i selfi'i
    check "le xamgu be le ctuca zdani".spansRead("sumti-6") ==
        @[0 .. 5, 3 .. 5]  # `CLL 5.7`



suite "Chapter 18":
  test "Section 18.16":
    check "li fu'a reboi ci su'i du li mu".treeRead.isSome  # `CLL 18.110`
    # lo pu tadji be lo nu cuxna lo tricu pu cirko le mupli po'u `CLL 18.111`
    #   .i lo nu cipra ro mupli pe `CLL` pu facki di'u
    check "li fu'a reboi ci pi'i voboi mu pi'i su'i du li rexa".treeRead.isSome  # `CLL 18.111`
    for depth in 1 .. 5:
      var (left, right) = (@["li", "fu'a", "pa"], @["li", "fu'a", "pa"])
      for _ in 1 .. depth:
        left.add @["re", "su'i"]
        right.add "re"
      for _ in 1 .. depth: right.add "su'i"
      check left.join(" ").spansRead("rp-expression") ==
          # zo su'i ba lo namcu
          toSeq(countdown(depth, 1)).mapIt(2 .. 2 + 2 * it)  # `CLL 18.16`
      check right.join(" ").spansRead("rp-expression") ==
          # lo pritygunma
          toSeq(0 ..< depth).mapIt(2 + it .. 2 + 2 * depth - it)  # `CLL 18.16`



suite "Internal: Grammar":
  test "Words of each tree, in order, are words of text, under rule text":
    var count = 0
    for example in EXAMPLES:
      for text in [example.text.withBracketed, example.text.withoutBracketed]:
        let tree = text.treeRead
        check tree.isSome
        if tree.isNone: continue
        # le javni pe li 0
        check tree.get.rule == "text" and tree.get.number == 0  # `CLL 21.1`
        check tree.get.leaves == toSeq(0 ..< text.occurrencesRead.len)  # `#815`
        inc count
    check count == 2 * EXAMPLES.len


  test "Terminator text leaves out changes no tree, as square brackets of CLL mark":
    var count = 0
    for example in EXAMPLES:
      if '[' notin example.text: continue
      let
        text = example.text.withBracketed
        words = text.occurrencesRead
        dropped = example.text.bracketedAt
      if dropped.anyIt(words[it].reading.selmaho.get notin TERMINATORS_ELIDABLE): continue
      let (with_all, without) = (text.treeRead, example.text.withoutBracketed.treeRead)
      check with_all.isSome and without.isSome
      if with_all.isNone or without.isNone: continue
      let words_without = example.text.withoutBracketed.occurrencesRead.mapIt(it.text)
      # lo famvla cu selcau
      #   .i zoi gy. without change of meaning .gy.
      check with_all.get.shape(words.mapIt(it.text), dropped) ==
          without.get.shape(words_without, [])  # `CLL 21.1`
      inc count
    check count == COUNT_ELIDED


  test "Refusal names place where every derivation stops, and rule stopping there":
    # selfi'i
    check "mi klama le".refusalRead == some((3, "sumti-6 97"))  # fanmo ne'i lo sumti
    check "le".refusalRead == some((1, "sumti-6 97"))  # selfi'i
    check "cu".refusalRead == some((0, "text 0"))  # zo cu na krasi lo se ciska to selfi'i toi
    # selfi'i
    check "mi cu cu klama".refusalRead == some((2, "sentence 40"))  # zo cu poi remoi
    check "mi poi".refusalRead == some((2, "relative-clause 122"))  # selfi'i
    # selfi'i
    check "lo nu".refusalRead == some((2, "tanru-unit-2 152"))  # zo nu denpa lo bridi
    # zo ku fanmo no sumti
    check "mi klama ku".refusalRead == some((2, "bridi-tail 50"))  # selfi'i


  test "Rule 972 groups and/or of tense and CAhA inside NAhE and KI, as grammar.300 does":
    check "mi na'e ka'e tavla".spansRead("simple-tense-modal") == @[1 .. 2]  # `973` to selfi'i toi
    check "mi to'e ca'a tavla".spansRead("simple-tense-modal") == @[1 .. 2]  # `973` to selfi'i toi
    # selfi'i
    check "mi na'e pu ki tavla".spansRead("simple-tense-modal") == @[1 .. 3]  # `977`
    # lo cmavo be `NAhE` cu jorne lo temtcita .a lo cmavo be `BAI`
    check "mi na'e ki tavla".treeRead.isNone  # `973` to selfi'i toi
    check "mi ze'a pu ta'e tavla".spansRead("time") == @[1 .. 3]  # `1034` `ZEhA PU` to selfi'i toi
    check "mi ta'e tavla".treeRead.isSome  # `1034` to `interval-property` po'o toi to selfi'i toi


  test "Passes give tree or refusal one pass gives, over corpora and text of article joined":
    var texts = @TEXTS_PASSES
    for example in EXAMPLES_CLL: texts.add example.rows.join(" ")
    for sentence in SENTENCES_TATOEBA: texts.add sentence.text
    for paragraph in PARAGRAPHS_WIKIPEDIA: texts.add paragraph.text
    texts.add textJoined()
    var count = 0
    for text in texts:
      if not text.isCutting: continue
      let shapes = text.shapesRead
      if shapes.isNone: continue
      check shapes.get.passes == shapes.get.whole  # `#849` to le nu tcidu pa roi cu te karbi toi
      inc count
    # le bandu cu ralte lo selci'a poi selka'a
    check count >= COUNT_PASSES_LEAST  # `Article IX.3`


  test "Passes cut before ni'o and before .i that joins nothing, where no opener is open":
    # lo'u .ije le'u jorne
    check TEXTS_PASSES[0].partsRead == some(@[0 .. 1, 2 .. 8, 9 .. 19])  # selfi'i
    # lo'u .i ba bo le'u jorne
    check TEXTS_PASSES[11].partsRead == some(@[0 .. 6])  # `statement-2` to selfi'i toi
    # no `BO` se lidne le tcita
    check TEXTS_PASSES[12].partsRead == some(@[0 .. 1, 2 .. 5])  # selfi'i
    # zo .i jorne ki'u lo me `jek` me'u poi selkra zo na
    check TEXTS_PASSES[13].partsRead == some(@[0 .. 6])  # `statement-1` to selfi'i toi
    # le nu katna cu zvati pu `NIhO ...`
    check TEXTS_PASSES[9].partsRead == some(@[0 .. 3, 4 .. 7])  # `paragraphs` to selfi'i toi
    # pa pagbu po'o
    check TEXTS_PASSES[2].partsRead == some(@[0 .. 10])  # zo lu kalri ca le krasi
    # zo to cu ca'o kalri
    #   .i no nu katna cu zvati pu zo to
    check TEXTS_PASSES[3].partsRead == some(@[0 .. 11])  # selfi'i
    # le nu katna cu zvati pu zo lu poi ca'o kalri
    check TEXTS_PASSES[^1].partsRead == some(@[0 .. 1, 2 .. 8])  # selfi'i
    let terminals = TEXTS_PASSES[1].terminalsRead.get
    # zo tu'e cu ca'o kalri
    check terminals.toParts(0, terminals.len) == (@[0 .. 1, 2 .. 3], 4)  # `statement-3`


  test "Chart filled from kept columns is chart filled anew, as words join and change":
    var texts = @TEXTS_PASSES
    for example in EXAMPLES_CLL: texts.add example.rows.join(" ")
    for sentence in SENTENCES_TATOEBA: texts.add sentence.text
    var
      whole, everywhere: Chart  # le mulcmi poi stali ca ro nu tcidu
      previous: seq[Terminal]  # le genvla pe le pu nu tcidu
      rng = initRand(SEED_KEPT)
      count = 0
    for k, text in texts:
      if k mod STRIDE_KEPT != 0: continue
      let terminals = text.terminalsRead
      if terminals.isNone or terminals.get.len < 3: continue
      let
        read = terminals.get
        cut = rng.rand(1 .. read.len - 2)  # le stuzi be le genvla poi se vimcu
        steps = [
          read[0 ..< 1], read[0 ..< read.len div 2], read[0 ..< read.len - 1], read,
          read[0 ..< read.len - 2] & read[^1], read[0 ..< cut] & read[cut + 1 .. ^1], read,
        ]
          ## le selci'a cu zenba gi'e ba bo cenba lo genvla poi lidne le romoi gi'e ba bo vimcu
          ##     lo genvla poi zvati le midju
      for step in steps:
        var
          same = 0  # lo te kancu be lo genvla poi stali
          whole_fresh, everywhere_fresh: Chart
        while same < min(previous.len, step.len) and previous[same] == step[same]: inc same
        # ro spisa cu tisna lo selcmi po'o poi se lidne le pamoi genvla poi cenba
        let filled = if previous.len == 0: step.len + 1 else: step.len - same
        check whole.fillSets(step, is_everywhere = false) == filled
        check everywhere.fillSets(step, is_everywhere = true) == filled
        check whole.readWhole(step).shape == whole_fresh.readWhole(step).shape
        let islands = everywhere.islands(step, 0, step.len).mapIt(it.shape)
        check islands == everywhere_fresh.islands(step, 0, step.len).mapIt(it.shape)
        previous = step
      inc count
    check count >= COUNT_KEPT_LEAST  # `Article IX.3`


  test "Chart filled in one mode and then in the other is chart filled anew":
    # lo catlu be le mulcmi poi stali cu facki le srera
    #   .i le pamoi tadji cu tisna le mulcmi
    #   .i ba bo le drata tadji cu tisna le mulcmi
    #   .i ku'i le mulcmi cu ralte lo selcmi pe le pamoi tadji
    for text in TEXTS_PASSES:
      let read = text.terminalsRead.get
      var whole_first, islands_first, whole_fresh, everywhere_fresh: Chart
      discard whole_first.readWhole(read)
      let islands = whole_first.islands(read, 0, read.len).mapIt(it.shape)
      check islands == everywhere_fresh.islands(read, 0, read.len).mapIt(it.shape)
      discard islands_first.islands(read, 0, read.len)
      check islands_first.readWhole(read).shape == whole_fresh.readWhole(read).shape


  test "Passes read text of article joined part by part, its open tu'e too":
    let terminals = textJoined().terminalsRead.get
    check terminals.toParts(0, terminals.len).parts.len == COUNT_PARTS_JOINED  # `#849`
    check terminals.buildText(0, terminals.len).isSome  # snada gi'e na nitcu lo nu tcidu pa roi
