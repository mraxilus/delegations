## tcidu ro spisa be lo jmive se ciska ca lo nu le spisa cu klama
##   .i ro jufra cu se benji ta'i la'o gy. NIF .gy. ca lo nu le jufra cu se fanmo
##   .i lo valsi poi galfi lo pu valsi cu katna la'o gy. NIF .gy.
##   .i se ki'u bo lo jmive se ciska pe so'i cacra cu se tcidu ca lo temci poi lo ni le se ciska cu
##     clani cu jarco ke'a to `#859` toi
##
##   |------------------|--------------------------------------------------------------------------|
##   | lo cmene         | lo smuni                                                                 |
##   |------------------|--------------------------------------------------------------------------|
##   | `ReaderLive`     | le ca se ciska .e `NIF` poi pu se benji .e lo krasi valsi poi denpa      |
##   | `ChangeNif`      | lo cenba pe pa spisa ne'i `NIF`                                          |
##   |                  | .i re stuzi .e lo jgena .e lo rebla                                      |
##   | `initReaderLive` | lo jmive se ciska tcidu noi `NIF` pe ke'a cu vasru lo minde po'o         |
##   | `push`           | tcidu lo bavla'i spisa be lo jmive se ciska                              |
##   | `finish`         | tcidu lo fanmo be lo jmive se ciska gi'e jarco lo stali pagbu be `NIF`   |
##   | `toNif`          | `NIF` poi pu se benji                                                    |
##   | `countRead`      | le jdima cipra cu tcidu lo sumji be lo stuzi poi se tcidu ca ro nu tcidu |
##   | `toSentences`    | katna lo spisa pu ro valsi poi krasi lo jufra ja'i le porsi be lo valsi  |
##   | `combine`        | jmina lo cenba pe lo spisa poi se tcidu ta'i lo porsi ku'o fo pa cenba   |
##   |------------------|--------------------------------------------------------------------------|
##
## ni'o le tarmi cu se jdice la'o gy. Architect .gy. bu'u `#859`
##   .i ro pagbu be le se ciska cu se tcidu ta'i pa mulno se ciska to `readTextParts` toi
##   .i lo jgena pe ro pagbu be le se ciska cu se benji ne'i pa linji pe vo'a ca lo nu le bavla'i
##     pagbu cu cfari
##   .i ro pagbu poi se to'e curmi gi'e jbini re pagbu be le se ciska cu go'i ji'a
##   .i lo tricu be le se ciska cu jalge le jgena to `assembleText` toi
##   .i se ki'u bo no pagbu be le tricu cu se cirko
##   .i no spisa cu rapli tcidu le mulno se ciska
##   .i ro spisa cu tcidu le se ciska poi se krasi le pagbu poi ca'o kalri
##   .i lo valsi poi galfi lo pu valsi cu rinka lo nu rapli tcidu le se ciska poi se krasi lo jgena
##     poi le valsi cu klama ke'a
##   .i la'o gy. NIF .gy. cu se katna bu'u lo stuzi poi le jgena cu krasi bu'u ke'a
##   .i `ChangeNif` cu jarco le stuzi ta'i lo sinxa be lo stuzi
##   .i ji'a ro cenba cu jarco lo stuzi be le se ciska be'o poi le jgena cu krasi bu'u ke'a
##   .i se ki'u bo ca ro cenba lo drata samtci cu ka'e rinka lo nu ro jgena cu jorne lo se ciska poi
##     le jgena cu tcidu ke'a
##   .i lo jgena pe le pagbu poi ca'o kalri cu se benji ta'i lo rebla
##   .i lo bavla'i cenba cu basti le rebla
##   .i se ki'u bo le tricu cu zenba ca ro nu pa valsi cu klama
##   .i lo samtci poi pixra lo nu le tricu cu binxo cu ka'e jarco lo nu le tricu cu zenba
##   .i lo spisa cu ka'e katna lo valsi
##   .i se ki'u bo le se tcidu cu sisti pu lo romoi se ciska valsi poi no sinxa cu fanmo ke'a
##   .i se ki'u bo zo su poi lo bavla'i spisa cu galfi ke'a zo su'i cu vimcu no da
##   .i le se tcidu cu krasi bu'u lo se kuspe be pa jgena
##   .i le se kuspe cu krasi bu'u lo pamoi valsi poi se lidne lo valsi pe lo jgena poi lidne le
##     jgena
##   .i se ki'u bo le se kuspe cu vasru ro valsi poi lo nu vimcu cu pu vimcu ke'a zi'e poi lidne le
##     jgena
##   .i lo jgena goi ko'e cu pilno lo se kuspe be lo jgena poi lidne ko'e ku'o va'o lo nu lo nu
##     sitna cu vasru lo valsi poi le se kuspe be ko'e cu ka'e krasi bu'u ke'a
##   .i ji'a ko'e cu pilno lo se kuspe be lo jgena poi lidne ko'e ku'o va'o lo nu lo pamoi valsi pe
##     ko'e cu cmima lo valsi pe lo jgena poi lidne ko'e
##   .i mupli fa lo valsi poi le porsi be lo valsi cu to'e curmi ke'a zi'e poi jbini pa valsi .e zo
##     bu
##   .i ji'a ko'e cu pilno lo se kuspe be lo jgena poi lidne ko'e ku'o va'o lo nu le javni cu to'e
##     curmi pa zo zei poi lidne ko'e
##   .i zo zei cu jorne lo valsi poi se lidne zo zei ca lo nu le javni cu tcidu pa valsi to
##     `CLL 19.16` toi
##   .i lo nu galfi lo pu valsi cu se krasi le se ciska poi se rapli tcidu gi'e klama lo jgena poi
##     lidne le se ciska
##   .i zo si poi facki no valsi cu klama ro pu valsi poi zo si cu vimcu ke'a
##   .i zo bu .a zo zei cu klama lo pu valsi va'o lo nu le cmavo cu facki no valsi
##   .i zo sa poi facki no sinxa cu klama lo jgena poi vasru le sinxa .a lo krasi be le se ciska to
##     `CLL 19.13` toi
##   .i lo nu vimcu cu klama no jgena poi lidne zo su to `CLL 19.13` toi
##   .i lo pamoi pagbu poi se tcidu zi'e poi krasi no pagbu be le se ciska cu klama lo jgena poi
##     vasru lo romoi pagbu poi se tcidu
##   .i mupli fa zo zei poi rinka lo nu zo .i cu jorne lo valsi poi se lidne zo zei
##   .i lo srera jgena goi ko'i cu se klama ca lo nu cenba fa lo pagbu poi se tcidu gi'e se lidne
##     ko'i va'o lo nu lo nu ko'i cu sisti cu cmene le pagbu
##   .i lo fanmo valsi be lo krasi valsi poi denpa cu klama lo jgena poi vasru le krasi valsi
##   .i zo su cu fanmo lo se ciska poi lidne zo su
##   .i le se ciska cu stali ta'i lo nu pu se tcidu
##   .i se ki'u bo la'o gy. NIF .gy. cu se katna bu'u no stuzi
##   .i zo su cu se benji ta'i pa jgena poi vasru zo su po'o
##   .i le jgena cu se benji pu lo se ciska poi se lidne zo su
##   .i le se ciska cu se tcidu ta'i pa mulno se ciska to la'o gy. Architect .gy. cu jdice di'u bu'u
##     `#859` toi
##   .i lo krasi valsi poi denpa gi'e zvati lo se ciska poi lidne zo su cu se fanmo bu'u zo su ta'i
##     lo nu se fanmo bu'u lo fanmo be lo se ciska
##   .i le krasi valsi cu du zo tu'e .a zo lu .a zo to
##   .i se ki'u bo le se ciska cu se rapli tcidu bu'u le krasi valsi
##   .i lo nu sitna poi denpa cu sitna zo su ca lo nu le nu sitna cu se fanmo to `CLL 19.9` .e
##     `CLL 19.10` toi
##   .i lo krasi valsi poi denpa lo fanmo valsi pe ke'a cu se tcidu ta'i lo sampu gerna valsi
##   .i le krasi valsi cu du zo tu'e .a zo lu .a zo to .a zo lo'u .a zo zoi .a zo la'o
##   .i se ki'u bo lo jufra poi se lidne le krasi valsi cu zi se benji
##   .i lo fanmo valsi pe le krasi valsi cu rapli tcidu le jufra
##   .i va'o lo nu lo nu vimcu cu vimcu lo valsi poi lidne lo krasi valsi pe lo nu sitna kei kei le
##     se ciska poi vasru le krasi valsi cu se rapli tcidu bu'u lo krasi be le se ciska
##   .i ki'u bo lo fanmo valsi pe le nu sitna cu ka'e sitna lo valsi poi vimcu le valsi
##   .i ca lo fanmo lo se ciska poi se krasi lo pamoi krasi valsi poi ca'o denpa cu se tcidu ta'i lo
##     nu le mulno se ciska cu se tcidu
##   .i ca le fanmo zo lu .e zo to .e zo tu'e cu se fanmo
##   .i ki'u bo `CLL 21.1` cu curmi lo nu lo fanmo valsi pe le ci cmavo cu na se ciska
##   .i zo zoi .e zo la'o .e zo lo'u cu se tcidu ta'i lo srera
##   .i lo se ciska poi se lidne zo lo'u poi denpa cu se tcidu ne'i lo valsi poi zo lo'u cu sitna
##     ke'a ta'i lo nu le porsi be lo valsi cu tcidu to `CLL 19.9` toi
##   .i bu'u le se ciska zo zoi cu sitna le ci valsi poi se lidne zo zoi ca lo nu le ci valsi cu
##     klama to `toRoles` toi
##   .i se ki'u bo zo zoi cu denpa
##   .i zo lo'u poi lo nu vimcu cu vimcu zo le'u pe ke'a cu denpa no da
##   .i ki'u bo le porsi be lo valsi cu tcidu zo le'u
##   .i zo fa'o poi fanmo lo se ciska to `CLL 19.15` toi cu rinka lo nu ro spisa cu sisti bu'u zo
##     fa'o
##   .i lo fanmo valsi pe pa zo zoi poi lidne zo fa'o cu vimcu le nu sisti ca lo nu le fanmo valsi
##     cu klama
##   .i ki'u bo zo zoi cu sitna zo fa'o
##   .i ro jgena cu se benji ca lo nu zo fa'o cu se tcidu
##   .i ro se ciska valsi poi se lidne zo fa'o cu se benji ta'i pa pagbu poi vasru le se ciska valsi
##     po'o ca lo nu lo sinxa cu fanmo le se ciska valsi
##   .i se ki'u bo no spisa cu rapli tcidu le se ciska
##   .i se ki'u bo ba zo fa'o le jdima cu zenba ta'i lo linji
##   .i ca lo fanmo le se ciska cu se rapli tcidu bu'u zo fa'o ta'i lo nu le mulno se ciska cu se
##     tcidu
##   .i ro valsi poi lo nu vimcu cu vimcu ke'a cu zvati pa pagbu poi vasru le valsi po'o to
##     `prose.nim` toi
##   .i lo jgena poi se lidne le pagbu cu pilno lo se kuspe be le pagbu
##   .i se ki'u bo le valsi cu se rapli tcidu ca lo nu le se ciska cu se rapli tcidu bu'u le jgena
##   .i ki'u bo lo nu vimcu poi zvati le se ciska cu pu ka'e vimcu le valsi
##   .i flalu fa lo du'u ca lo fanmo la'o gy. NIF .gy. pe lo se ciska poi ro spisa be ke'a cu se
##     tcidu ta'i lo porsi cu mintu la'o gy. NIF .gy. pe lo pagbu be le se ciska poi se tcidu ta'i
##     lo mulno kei .e lo du'u pu lo fanmo la'o gy. NIF .gy. .e le rebla pe ro cenba cu mintu la'o
##     gy. NIF .gy. pe lo pagbu be lo se ciska poi ca zvati gi'e fanmo bu'u lo romoi sinxa pe ke'a
##     be'o poi se tcidu ta'i pa mulno jmive se ciska to `test_live.nim` toi
##   .i jdima fa lo nu ro spisa cu rapli tcidu le pagbu poi ca'o kalri
##   .i se ki'u bo le temci cu zenba ta'i lo pilji be lo ni le se ciska cu clani kei bei lo ni pa
##     jufra cu clani
##   .i lo valsi poi galfi lo pu valsi cu rinka lo nu rapli tcidu pa roi bu'u lo jgena poi le valsi
##     cu klama ke'a
##   .i le tcidu cu rapli ja'i lo namcu pe lo porsi
##   .i ki'u bo `items` cu fukpi va'o lo nu fanva fi la'o gy. JavaScript .gy.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]

import ./[grammar, nif, prose, selmaho, stream, tanru]


type
  ChangeNif* = object
    ## lo cenba poi pa spisa be lo jmive se ciska cu rinka ke'a ne'i la'o gy. NIF .gy.
    at*: int
      ## lo stuzi poi le cenba cu krasi bu'u ke'a ne'i la'o gy. NIF .gy.
      ##   .i la'o gy. NIF .gy. poi se krasi le stuzi cu se vimcu
      ##   .i ba bo `text` cu se jmina
    start*: int
      ## lo stuzi poi le cenba cu krasi bu'u ke'a ne'i le se ciska
      ##   .i ro valsi pe la'o gy. NIF .gy. poi lidne `at` cu fanmo bu'u lo stuzi poi na se lidne le
      ##     stuzi
      ##   .i ro valsi pe `text` .e `tail` cu krasi bu'u lo stuzi poi na lidne le stuzi
      ##   .i se ki'u bo la'o gy. NIF .gy. cu jorne le se ciska poi se tcidu
    text*: string
      ## la'o gy. NIF .gy. pe ro jgena poi se benji
      ##   .i ro le jgena cu zvati pa linji pe vo'a
    tail*: string
      ## la'o gy. NIF .gy. pe ro jgena poi ca'o kalri
      ##   .i le se ciska poi ca zvati cu jarco le jgena
      ##   .i ro le jgena cu zvati pa linji pe vo'a
      ##   .i lo bavla'i cenba cu basti le rebla

  ItemLive = object
    ## lo jgena poi pu se benji
    ##   .i le jgena cu srana pa pagbu be le se ciska be'o .a pa pagbu poi se to'e curmi gi'e jbini
    ##     re pagbu be le se ciska
    start: int
      ## lo stuzi poi lo se kuspe be le jgena cu krasi bu'u ke'a
      ##   .i lo valsi poi se lidne lo valsi pe lo jgena poi lidne le jgena cu krasi bu'u le stuzi
      ##     to `toSpans` toi
    offset: int  ## lo stuzi poi lo linji pe le jgena cu krasi bu'u ke'a ne'i la'o gy. NIF .gy.
    kept: seq[Option[Terminal]]
      ## lo porsi be lo gerna valsi pe ro valsi poi le jgena cu vasru ke'a zi'e poi lo nu vimcu cu
      ##   ka'e vimcu ke'a
      ##   .i le valsi cu pagbu lo pagbu poi se tcidu .a lo pagbu poi vasru lo cmavo poi no liste cu
      ##     dunda lo selma'o ke'a
    last: Option[Terminal]
      ## lo gerna valsi pe lo romoi pagbu poi se tcidu ne'i le jgena .a lo jgena poi lidne le jgena
    held: int
      ## lo namcu pe lo romoi jgena poi vasru lo pagbu poi se tcidu
      ##   .i le romoi jgena cu du le jgena .a lo jgena poi lidne le jgena
      ##   .i va'o lo nu no jgena cu vasru lo pagbu poi se tcidu kei le namcu cu du li ni'u pa
    is_parted: bool
      ## lo du'u su'o pagbu be lo se ciska pe le jgena cu pu se benji bu'u le jgena .a lo jgena poi
      ##   lidne le jgena
      ##   .i ki'u la'e di'u lo pagbu be le se ciska be'o poi vasru no pagbu zi'e noi lo se ciska
      ##     poi vasru no pagbu poi se tcidu cu jarco ke'a cu zvati le se ciska pa roi
    stop: Option[int]
      ## lo stuzi pe lo pagbu poi se tcidu gi'e se lidne le jgena
      ##   .i lo nu sisti pe lo srera jgena pe le jgena cu cmene le pagbu
      ##   .i le datni pagbu cu kunti va'o lo nu no nu sisti cu cmene lo pagbu poi se lidne lo pagbu
      ##     pe le jgena
    is_su: bool
      ## lo du'u le jgena cu pezli zo su noi fanmo lo se ciska poi lidne zo su
      ##   .i lo nu vimcu poi se lidne zo su cu klama no jgena poi lidne zo su
      ##   .i ku'i va'o lo nu `is_quoted` cu jetnu kei lo nu vimcu cu ka'e klama lo jgena poi lidne
      ##     zo su
    is_quoted: bool
      ## lo du'u le jgena cu pezli zo su poi lo nu sitna cu vasru ke'a ca lo pamoi nu le javni pe
      ##   `CLL 19.16` cu tcidu
      ##   .i lo nu vimcu poi se lidne zo su cu klama lo jgena poi lidne zo su
      ##   .i ki'u bo lo nu vimcu poi vimcu lo drata pagbu be le nu sitna cu rinka lo nu zo su cu
      ##     rapli se sitna
    start_reading: int
      ## lo stuzi poi lo nu tcidu poi benji le jgena cu cfari bu'u ke'a
      ##   .i lo fanmo valsi pe lo nu sitna poi sitna zo su cu rinka lo nu le se ciska cu se rapli
      ##     tcidu bu'u le stuzi
      ##   .i ki'u bo ca la'e di'u zo su cu fanmo no se ciska

  OpenerLive = object
    ## lo krasi valsi poi denpa lo fanmo valsi pe ke'a ne'i le se ciska poi ca zvati
    selmaho: Selmaho
      ## lo selma'o be le krasi valsi
      ##   .i le selma'o cu du zoi gy. TUhE .gy. .a zoi gy. LU .gy. .a zoi gy. TO .gy. .a zoi gy.
      ##     LOhU .gy. .a zoi gy. ZOI .gy. pe zo zoi .e zo la'o
    at: int  ## lo stuzi poi le krasi valsi cu krasi bu'u ke'a
    start: int
      ## lo stuzi poi lo se kuspe be lo jgena poi vasru le krasi valsi cu krasi bu'u ke'a
      ##   .i lo fanmo valsi pe le krasi valsi cu rinka lo nu rapli tcidu bu'u le stuzi
    after: int
      ## lo stuzi poi krasi lo se ciska poi zo zoi cu sitna ke'a
      ##   .i le stuzi cu se lidne lo korbi valsi pe zo zoi
      ##   .i li no va'o lo nu le krasi valsi cu na du zo zoi
    delimiter: string
      ## lo korbi valsi pe zo zoi noi fanmo le nu sitna
      ##   .i le korbi valsi cu kunti va'o lo nu le krasi valsi cu na du zo zoi
      ##   .i ji'a le korbi valsi cu kunti va'o lo nu zo zoi goi ko'u cu sitna le ci valsi poi se
      ##     lidne ko'u ne'i lo valsi poi zo lo'u cu sitna ke'a
      ##   .i ro valsi cu fanmo ko'u

  ReaderLive* = object
    ## lo tcidu be lo jmive se ciska
    ##   .i le tcidu cu ponse le se ciska poi ca zvati .e la'o gy. NIF .gy. poi pu se benji .e lo
    ##     krasi valsi poi denpa
    text: string
    nif: string  ## le minde cu lidne lo linji pe ro jgena poi pu se benji
    tail: string
      ## la'o gy. NIF .gy. pe ro jgena poi ca'o kalri
      ##   .i le romoi cenba cu jarco le jgena
    start_tail: int
      ## lo stuzi poi lo pamoi valsi pe le rebla cu krasi bu'u ke'a
      ##   .i le stuzi cu se lidne ro valsi poi pu se benji
      ##   .i lo cenba pe lo spisa poi rinka lo nu tcidu no drata valsi cu krasi bu'u le stuzi
      ##   .i va'o lo nu le rebla cu vasru no valsi kei le stuzi cu du lo fanmo be le se tcidu
    items: seq[ItemLive]  ## lo porsi be ro jgena poi pu se benji
    openers: seq[OpenerLive]  ## lo porsi be ro krasi valsi poi denpa ku'o bei lo stuzi
    start: int  ## lo stuzi poi lo se ciska poi na pu se benji cu krasi bu'u ke'a
    count_read: int
      ## lo sumji be lo stuzi poi se tcidu ca ro nu tcidu
      ##   .i le jdima cipra cu tcidu le sumji
    ending: int
      ## lo stuzi poi le romoi se tcidu cu fanmo bu'u ke'a
      ##   .i le stuzi cu se lidne lo romoi sinxa poi jbini lo valsi
    stop: Option[int]
      ## lo stuzi poi se lidne lo se ciska valsi pe zo fa'o poi fanmo lo se ciska to `CLL 19.15` toi
      ##   .i ro spisa cu sisti lo nu tcidu bu'u le stuzi
      ##   .i le datni pagbu cu kunti pu lo nu zo fa'o cu se tcidu
      ##   .i lo fanmo be le se ciska cu tcidu ba le stuzi
      ##   .i ki'u bo lo fanmo valsi pe lo krasi valsi poi lidne zo fa'o cu ka'e sitna zo fa'o
    is_ended: bool  ## lo du'u lo fanmo be le jmive se ciska cu pu se tcidu


func initReaderLive*(): ReaderLive =
  ## zbasu lo tcidu be lo jmive se ciska be'o noi la'o gy. NIF .gy. pe ke'a cu vasru lo minde po'o
  ReaderLive(nif: HEADER)


func toNif*(reader: ReaderLive): string = reader.nif
  ## jarco la'o gy. NIF .gy. poi pu se benji
  ##   .i le minde cu lidne lo linji pe ro jgena

func countRead*(reader: ReaderLive): int = reader.count_read
  ## jarco lo sumji be lo stuzi poi se tcidu ca ro nu tcidu le se ciska
  ##   .i le sumji cu jdima
  ##   .i le jdima cu zenba ta'i lo pilji be lo ni le se ciska cu clani kei bei lo ni pa jufra cu
  ##     clani



#[ ni'o ni'o ni'o lo se tcidu ]#

func isSu(unit: Unit): bool =
  ## jdice lo du'u le pagbu cu vasru zo su po'o
  ##   .i zo su cu fanmo lo se ciska poi lidne zo su
  not unit.is_read and unit.refusal == RefusalText.Su


func isErasure(unit: Unit): bool =
  ## jdice lo du'u le pagbu cu vasru lo valsi poi lo nu vimcu cu vimcu ke'a .e lo cmavo poi vimcu le
  ##   valsi
  not unit.is_read and unit.refusal == RefusalText.Erasure


func isWall(item: ItemLive): bool =
  ## jdice lo du'u le jgena cu pezli zo su gi'e se klama no nu vimcu poi se lidne le jgena
  ##   .i no nu sitna cu vasru le jgena ca lo pamoi nu tcidu
  item.is_su and not item.is_quoted


func addLeaves(node: Node, leaves: var seq[int]) =
  ## jmina lo namcu pe ro pagbu poi cnita le jgena ku'o `leaves` ta'i le porsi pe le tricu
  if node.is_terminal:
    leaves.add node.at
    return
  for k in 0 ..< node.children.len: node.children[k].addLeaves(leaves)


func stopMost(node: Node): int =
  ## jarco lo romoi pagbu poi le gerna cu sisti bu'u ke'a ne'i le tricu
  ##   .i lo srera jgena cu sinxa le stuzi poi le gerna cu sisti bu'u ke'a
  ##   .i va'o lo nu le gerna cu sisti bu'u no pagbu kei jarco li ni'u pa
  if node.is_terminal: return -1
  result = (if node.stop.isSome: node.stop.get.at else: -1)
  for k in 0 ..< node.children.len: result = max(result, node.children[k].stopMost)


func toCleans(occurrences: openArray[Occurrence]): seq[bool] =
  ## jdice fi ro valsi pe le se tcidu fe lo du'u xu kau le porsi be lo valsi cu tcidu le se ciska
  ##   poi se krasi le valsi ta'i lo nu tcidu le valsi bu'u lo stuzi pe le valsi
  ##   .i la'e di'u jetnu va'o lo nu no nu sitna cu vasru le valsi
  ##   .i mupli fa lo valsi poi zo zo cu sitna ke'a
  ##   .i mupli fa ji'a lo valsi poi zo zoi .a zo la'o cu sitna ke'a
  ##   .i mupli fa ji'a lo valsi poi zo lo'u cu sitna ke'a zi'e poi zo le'u cu fanmo lo nu sitna pe
  ##     ke'a
  ##   .i ro valsi poi le porsi be lo valsi cu to'e curmi ke'a cu ponse lo jalge pe lo valsi poi le
  ##     porsi cu tcidu ke'a zi'e poi se lidne le valsi
  ##   .i zo lo'u poi no zo le'u cu fanmo ke'a cu denpa ta'i lo krasi valsi to `OpenerLive` toi
  func isSelmaho(word: Occurrence, selmaho: Selmaho): bool =
    ## jdice lo du'u le valsi cu cmavo `selmaho`
    word.reading.is_word and word.reading.selmaho == some(selmaho)

  result = newSeq[bool](occurrences.len)
  var
    # ro valsi poi le porsi be lo valsi cu tcidu ke'a
    #   .i no valsi poi le porsi cu to'e curmi ke'a cu cmima
    reads: seq[int]
    is_reads = newSeq[bool](occurrences.len)
  for k in 0 ..< occurrences.len:
    result[k] = true
    is_reads[k] = occurrences[k].reading.is_word or
      occurrences[k].reading.refusal == Refusal.Foreign
    if is_reads[k]: reads.add k
  var i = 0
  while i < reads.len:
    template word: untyped = occurrences[reads[i]]
      ## lo drata cmene be le valsi
      ##   .i `let` da'i fukpi le valsi
    var last = i  # lo romoi valsi poi lo nu sitna cu vasru ke'a
    if word.isSelmaho(Selmaho.Zo): last = i + 1
    elif word.isSelmaho(Selmaho.Zoi):
      let is_quoting = i + 2 < reads.len and not occurrences[reads[i + 2]].reading.is_word
      if is_quoting: last = i + 3
    elif word.isSelmaho(Selmaho.Lohu):
      var j = i + 1
      while j < reads.len and not occurrences[reads[j]].isSelmaho(Selmaho.Lehu):
        j += (if occurrences[reads[j]].isSelmaho(Selmaho.Zo): 2 else: 1)
      if j < reads.len: last = j
    for q in i + 1 .. min(last, reads.high): result[reads[q]] = false
    i = last + 1
  # le porsi be lo valsi cu tcidu lo se ciska poi se krasi le bavla'i valsi ta'i lo nu tcidu le
  #   valsi bu'u lo stuzi pe le valsi
  var is_clean = true
  for k in countdown(occurrences.high, 0):
    if is_reads[k]: is_clean = result[k] else: result[k] = is_clean


func toSpans(region: ReadingParts, leaves: openArray[seq[int]], first: int): seq[int] =
  ## jarco lo stuzi poi lo se kuspe be ro panzi be lo genja be le se tcidu cu krasi bu'u ke'a
  ##   .i le se kuspe cu krasi bu'u lo pamoi valsi poi se lidne lo valsi pe lo panzi poi lidne le
  ##     panzi
  ##   .i se ki'u bo le se kuspe cu vasru ro valsi poi lo nu vimcu cu pu vimcu ke'a zi'e poi lidne
  ##     le panzi zi'e noi lo nu vimcu poi zvati le panzi cu pu ka'e vimcu ke'a
  ##   .i le pamoi se kuspe cu krasi bu'u `first`
  ##   .i lo panzi goi ko'e cu pilno lo se kuspe be lo panzi poi lidne ko'e ku'o va'o lo nu lo pamoi
  ##     valsi pe ko'e cu cmima lo valsi pe le panzi poi lidne ko'e
  ##   .i mupli fa lo valsi poi se to'e curmi gi'e jbini pa valsi .e lo cinmo valsi poi tcita le
  ##     valsi
  ##   .i ji'a ko'e cu pilno lo se kuspe be lo panzi poi lidne ko'e ku'o va'o lo nu lo nu sitna cu
  ##     vasru lo valsi poi le se kuspe be ko'e cu ka'e krasi bu'u ke'a to `toCleans` toi
  ##   .i lo nu vimcu cu pu vimcu le valsi
  ##   .i ji'a ko'e cu pilno lo se kuspe be lo panzi poi lidne ko'e ku'o va'o lo nu lo valsi poi
  ##     lidne lo pamoi valsi pe ko'e cu du pa zo sa poi lo nu vimcu cu pu vimcu ke'a
  ##   .i lo nu sisku lo pu valsi cu cliva ro valsi poi se to'e curmi le porsi be lo valsi .a le
  ##     javni
  ##   .i ki'u bo lo pamoi valsi poi le javni cu tcidu ke'a zi'e poi se lidne zo sa cu dunda lo
  ##     sinxa be zo sa to `CLL 19.13` toi
  ##   .i ji'a ko'e cu pilno lo se kuspe be lo panzi poi lidne ko'e ku'o va'o lo nu le panzi poi
  ##     lidne ko'e cu du lo valsi poi lo nu vimcu cu pu vimcu ke'a
  ##   .i lo nu vimcu poi zvati ko'e cu pu ka'e vimcu le valsi
  ##   .i ji'a ko'e cu pilno lo se kuspe be lo panzi poi lidne ko'e ku'o va'o lo nu le javni cu to'e
  ##     curmi pa zo zei poi lidne lo pamoi valsi pe ko'e
  ##   .i lo nu sisku lo pu valsi cu cliva ro valsi poi se to'e curmi le porsi be lo valsi .a le
  ##     javni gi'a se vimcu lo nu vimcu
  ##   .i ki'u bo zo zei cu jorne lo valsi poi se lidne zo zei ca lo nu le javni cu tcidu pa valsi
  ##     bu'u le stuzi
  ##   .i mupli fa lo nu le javni cu to'e curmi lo nu sitna poi krasi bu'u le stuzi to `CLL 19.16`
  ##     toi
  func isRefused(unit: Unit): bool =
    ## jdice lo du'u lo javni pe `CLL 19.16` cu to'e curmi le pagbu
    ##   .i se ki'u bo le javni cu ranji lo nu tcidu ba lo valsi pe le pagbu
    not unit.is_read and unit.refusal in {RefusalText.Quotation, RefusalText.Construct}

  func isRefusedZei(unit: Unit, word: Occurrence): bool =
    ## jdice lo du'u le valsi pe le pagbu cu du zo zei gi'e se to'e curmi le javni
    ##   .i zo zei cu jorne lo valsi poi se lidne zo zei ca lo nu le javni cu tcidu pa valsi
    not unit.is_read and unit.refusal == RefusalText.Construct and word.reading.is_word and
      word.reading.selmaho == some(Selmaho.Zei)

  template units: untyped = region.reading.units
    ## lo drata cmene be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo drata cmene be lo valsi pe le se tcidu
    ##   .i `let` da'i fukpi le valsi
  let cleans = occurrences.toCleans
  # ro valsi cu ponse lo namcu pe lo pagbu poi vasru le valsi
  #   .i li ni'u pa cu sinxa lo nu no pagbu cu vasru le valsi
  var holders = newSeq[int](occurrences.len)
  for w in 0 ..< occurrences.len: holders[w] = -1
  for u in 0 ..< units.len:
    for w in units[u].words: holders[w] = u
  result = newSeq[int](leaves.len)
  var next = 0  # lo valsi poi se lidne lo valsi pe lo pu panzi
  for k in 0 ..< leaves.len:
    let opening = (if leaves[k].len > 0: units[leaves[k][0]].words[0] else: next)  # lo pamoi valsi
    var
      before = opening - 1  # lo pu valsi poi na se to'e curmi le porsi be lo valsi .a le javni
      # lo pu valsi poi na se to'e curmi le porsi be lo valsi .a le javni gi'e na se vimcu
      #   .i ku'i lo nu sisku cu na cliva zo zei poi le javni cu to'e curmi ke'a
      prior = opening - 1
    while before >= 0 and (not occurrences[before].reading.is_word or
        (holders[before] >= 0 and units[holders[before]].isRefused)):
      dec before
    while prior >= 0 and (not occurrences[prior].reading.is_word or holders[prior] < 0 or
        units[holders[prior]].isErasure or (units[holders[prior]].isRefused and
          not units[holders[prior]].isRefusedZei(occurrences[prior]))):
      dec prior
    let
      is_among = leaves[k].len > 0 and units[leaves[k][0]].words[0] < next
      is_marked = before >= 0 and
        (holders[before] < 0 or units[holders[before]].isErasure) and
        occurrences[before].reading.selmaho == some(Selmaho.Sa)
      is_after_erasure = k > 0 and leaves[k - 1].len == 1 and
        region.reading.tree.children[k - 1].is_terminal and units[leaves[k - 1][0]].isErasure
      is_after_zei = prior >= 0 and holders[prior] >= 0 and
        units[holders[prior]].isRefusedZei(occurrences[prior])
    if k == 0: result[k] = first
    elif is_among or is_marked or is_after_erasure or is_after_zei or
        (next < occurrences.len and not cleans[next]):
      result[k] = result[k - 1]
    elif next < occurrences.len: result[k] = occurrences[next].start
    else: result[k] = region.reading.size
    for u in leaves[k]: next = max(next, units[u].words[^1] + 1)


func byteQuoted(text: string, at: int, delimiter: string): int =
  ## jarco lo stuzi poi krasi lo se ciska poi zo zoi cu sitna ke'a
  ##   .i zo zoi cu krasi bu'u `at`
  ##   .i le stuzi cu se lidne lo se ciska valsi poi se lidne zo zoi va'o lo nu le se ciska valsi cu
  ##     du le korbi valsi
  ##   .i va'o lo drata le stuzi cu se lidne lo se ciska valsi poi vasru zo zoi
  ##   .i ca la'e di'u le se ciska valsi cu vasru le korbi valsi
  var a = at
  while a < text.len and text[a] notin MARKS_BOUNDARY: inc a
  var b = a
  while b < text.len and text[b] in MARKS_BOUNDARY: inc b
  var c = b
  while c < text.len and text[c] notin MARKS_BOUNDARY: inc c
  if text[b ..< c].toLowerAscii.replace(",", "") == delimiter: c else: a


func isSpelled(text: string, first, last: int, delimiter: string): bool =
  ## jdice lo du'u su'o se ciska valsi pe lo stuzi po'u `first ..< last` pe le se ciska cu du
  ##   `delimiter` ta'i lo nu le porsi be lo valsi cu tcidu lo valsi poi fanmo lo se ciska poi zo
  ##   zoi cu sitna ke'a to `CLL 19.10` toi
  var at = first
  while at < last:
    if text[at] in MARKS_BOUNDARY:
      inc at
      continue
    let start = at
    while at < last and text[at] notin MARKS_BOUNDARY: inc at
    if text[start ..< at].toLowerAscii.replace(",", "") == delimiter: return true
  false


func readFrom(reader: var ReaderLive, start: int, is_final: bool): ReadingParts =
  ## tcidu lo se ciska poi se krasi `start` ku'o ta'i lo pagbu be le se ciska
  ##   .i lo nu kancu ro stuzi cu cfari bu'u lo krasi be le mulno se ciska
  ##   .i va'o lo nu zo lo'u poi denpa cu lidne `start` kei le se ciska cu se tcidu ne'i lo valsi
  ##     poi zo lo'u cu sitna ke'a ta'i lo nu le porsi be lo valsi cu tcidu
  ##   .i pu lo fanmo le se tcidu cu sisti pu lo romoi se ciska valsi poi no sinxa cu fanmo ke'a
  ##   .i ki'u bo lo bavla'i spisa cu ka'e ranji le se ciska valsi mu'u lo nu zo su cu binxo zo su'i
  ##   .i ji'a le se tcidu cu sisti bu'u zo fa'o poi fanmo le se ciska
  ##   .i ku'i lo fanmo be le se tcidu cu se kancu ba lo se ciska poi se lidne zo fa'o
  var ending = reader.text.len
  if not is_final:
    while ending > start and reader.text[ending - 1] notin MARKS_BOUNDARY: dec ending
  let
    last = (if reader.stop.isSome and not is_final: min(ending, reader.stop.get) else: ending)
    is_lohu = reader.openers.anyIt(it.selmaho == Selmaho.Lohu and it.at < start)
  result = readTextParts(reader.text[start ..< last], is_live = not is_final, is_lohu)
  reader.count_read += last - start
  for occurrence in result.reading.occurrences.mitems:
    (occurrence.start, occurrence.finish) = (occurrence.start + start, occurrence.finish + start)
  result.reading.size = ending
  for zoi in result.zois.mitems: zoi.start += start
  for lohu in result.lohus.mitems: lohu += start
  for quoted in result.quoted.mitems: quoted += start



#[ ni'o ni'o ni'o lo nu galfi lo pu valsi ]#

func reopening(reader: ReaderLive, opener: OpenerLive): int =
  ## jarco lo stuzi poi lo fanmo valsi pe le krasi valsi pe lo nu sitna cu rapli tcidu le se ciska
  ##   bu'u ke'a
  ##   .i le stuzi cu du lo krasi be lo jgena poi vasru le krasi valsi
  ##   .i ja le stuzi cu du lo stuzi poi lo nu tcidu poi benji pa zo su poi se lidne le krasi valsi
  ##     cu cfari bu'u ke'a
  ##   .i ki'u bo le nu sitna cu sitna ro zo su poi se lidne le krasi valsi
  ##   .i se ki'u bo lo se ciska poi lidne zo su cu se rapli tcidu ta'i lo se ciska poi zo su na
  ##     fanmo ke'a to `CLL 19.9` .e `CLL 19.10` toi
  result = opener.start
  var k = reader.items.high
  while k >= 0 and reader.items[k].start > opener.at:
    if reader.items[k].is_su: result = min(result, reader.items[k].start_reading)
    dec k


func boundary(reader: ReaderLive, at: int): int =
  ## jarco lo stuzi poi na se lidne `at` zi'e poi lo nu tcidu cu ka'e rapli cfari bu'u ke'a
  ##   .i lo se ciska valsi goi ko'a cu vasru `at`
  ##   .i le stuzi cu du lo krasi be lo jgena poi vasru lo pamoi stuzi pe ko'a
  ##   .i ki'u bo le porsi be lo valsi cu tcidu ro se ciska valsi ta'i lo mulno
  ##   .i va'o lo nu no jgena cu zvati le stuzi kei le stuzi cu du lo krasi be le se ciska
  result = at
  while result > 0 and reader.text[result - 1] notin MARKS_BOUNDARY:
    var first = result - 1
    while first > 0 and reader.text[first - 1] notin MARKS_BOUNDARY: dec first
    var k = reader.items.high
    while k >= 0 and reader.items[k].start > first: dec k
    result = (if k >= 0: reader.items[k].start else: 0)


func reach(reader: ReaderLive, region: ReadingParts, start: int): Option[int] =
  ## jarco lo pamoi stuzi poi lidne `start` zi'e poi lo nu tcidu le se ciska poi se krasi `start` cu
  ##   klama ke'a
  ##   .i le se klama cu du lo jgena poi vasru lo krasi valsi poi le se ciska cu vasru lo fanmo
  ##     valsi pe ke'a
  ##   .i ja le se klama cu du lo jgena poi vasru lo krasi valsi poi zo su cu fanmo ke'a
  ##   .i ja le se klama cu du lo jgena poi lo nu vimcu pe le se ciska cu klama ke'a
  ##   .i ja le se klama cu du lo jgena poi lo pamoi pagbu poi se tcidu cu jorne ke'a
  ##   .i ja le se klama cu du pa srera jgena goi ko'i noi lo nu ko'i cu sisti cu cmene lo pagbu poi
  ##     se tcidu gi'e se lidne ko'i
  ##   .i va'o lo nu le se ciska poi lidne `start` cu se tcidu ta'i lo nu pu se tcidu kei kei jarco
  ##     no stuzi
  ##   .i ro valsi poi se lidne lo pamoi cmavo po'u zo su pe le se tcidu cu klama no jgena poi lidne
  ##     le cmavo
  ##   .i ku'i lo fanmo valsi pe lo nu sitna noi sitna zo su cu ka'e klama lo jgena poi lidne le
  ##     cmavo
  func earlier(back: Option[int], at: int): Option[int] =
    ## jarco lo pamoi be le stuzi poi se ralte ku'o joi `at`
    some(if back.isSome: min(back.get, at) else: at)

  func landing(reader: ReaderLive, k, j, start: int): int =
    ## jarco lo stuzi poi le jgena pe `k` cu krasi bu'u ke'a
    ##   .i lo nu vimcu pe le se ciska poi se krasi `start` cu klama le jgena
    ##   .i le nu vimcu cu cliva le jgena pe `j`
    ##   .i va'o lo nu le jgena cu pezli zo su poi lo nu vimcu cu na klama ke'a kei le stuzi cu se
    ##     lidne le jgena
    if not reader.items[k].isWall: reader.items[k].start
    elif k + 1 < j: reader.items[k + 1].start
    else: start

  template units: untyped = region.reading.units
    ## lo drata cmene be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo drata cmene be lo valsi pe le se tcidu
    ##   .i `let` da'i fukpi le valsi
  var
    back = none(int)
    j = reader.items.len  # lo jgena poi lidne `start`
    first = 0  # lo pagbu poi lidne lo pamoi cmavo po'u zo su pe le se tcidu
  while j > 0 and reader.items[j - 1].start >= start: dec j
  while first < units.len and not units[first].isSu: inc first

  # lo fanmo valsi poi no krasi valsi pe le se ciska cu mapti ke'a zi'e poi mapti zo tu'e .a zo lu
  #   .a zo to cu fanmo lo krasi valsi poi mapti le fanmo valsi gi'e denpa gi'e lidne le se ciska
  #   .i le jibni traji cu pamoi
  #   .i le so'i nu tcidu cu jersi le krasi valsi ta'i la'e di'u to `toParts` toi
  #   .i le se ciska poi se rapli tcidu cu rapli tcidu ro krasi valsi poi zvati le se ciska zi'e noi
  #     ka'e sisti lo nu krasi
  #   .i zo su cu fanmo ro le krasi valsi ta'i lo fanmo be le se ciska
  var
    # lo fanmo valsi poi fanmo no krasi valsi pe le se ciska
    #   .i ro klesi cu ponse pa namcu
    strays: array[OPENERS.len, int]
    # lo klesi be ro krasi valsi poi kalri ne'i le se ciska
    #   .i le krasi valsi poi zvati ne'i ro drata cu romoi
    opened: seq[int]
  for u in 0 ..< first:
    if not units[u].is_read: continue
    for k in 0 ..< OPENERS.len:
      if units[u].terminal == OPENERS[k].toTerminal: opened.add k
      if units[u].terminal != CLOSERS[k].toTerminal: continue
      var n = opened.high
      while n >= 0 and opened[n] != k: dec n
      if n >= 0: opened.setLen(n) else: inc strays[k]
  for k in 0 ..< OPENERS.len:
    var
      left = (if first < units.len: reader.openers.len else: strays[k])
      n = reader.openers.high
    while left > 0 and n >= 0:
      if reader.openers[n].selmaho == OPENERS[k] and reader.openers[n].start < start:
        back = back.earlier(reader.openers[n].start)
        dec left
      dec n

  # lo fanmo valsi pe lo nu sitna
  #   .i zo le'u cu fanmo lo pamoi cmavo po'u zo lo'u poi denpa
  #   .i ki'u bo le cmavo cu sitna ro zo lo'u poi se lidne le cmavo
  #   .i lo korbi valsi cu fanmo zo zoi pe vo'a
  #   .i ro le nu sitna cu sitna ro zo su poi lidne le fanmo valsi
  if occurrences.isClosingLohu:
    var n = 0
    while n < reader.openers.len and reader.openers[n].selmaho != Selmaho.Lohu: inc n
    if n < reader.openers.len: back = back.earlier(reader.reopening(reader.openers[n]))
  for n in 0 ..< reader.openers.len:
    template opener: untyped = reader.openers[n]
      ## lo drata cmene be le krasi valsi
      ##   .i `let` da'i fukpi le krasi valsi
    if opener.selmaho != Selmaho.Zoi: continue
    let is_closing = opener.delimiter.len == 0 or
      reader.text.isSpelled(max(start, opener.after), region.reading.size, opener.delimiter)
    if is_closing: back = back.earlier(reader.reopening(opener))
  if j == 0: return back

  # zo si poi facki no valsi cu vimcu lo valsi pe lo jgena poi lidne le se tcidu
  #   .i le romoi cu pamoi se vimcu
  #   .i zo bu .a zo zei cu galfi lo romoi valsi pe lo jgena poi lidne le se tcidu va'o lo nu no
  #     valsi poi se ralte cu lidne le cmavo to `CLL 19.13` .e `CLL 19.16` toi
  var
    deficit = 0
    is_kept = false  # lo valsi poi se ralte cu lidne le pagbu
  for u in 0 ..< first:
    template unit: untyped = units[u]
      ## lo drata cmene be le pagbu
      ##   .i `let` da'i fukpi le pagbu
    if unit.is_read or unit.refusal == RefusalText.Selmaho: is_kept = true
    if unit.is_read or unit.refusal != RefusalText.Construct or unit.words.len != 1: continue
    template word: untyped = occurrences[unit.words[0]]
      ## lo drata cmene be lo valsi pe le pagbu
      ##   .i `let` da'i fukpi le valsi
    if not word.reading.is_word: continue
    if word.reading.selmaho == some(Selmaho.Si): inc deficit
    elif word.reading.selmaho in [some(Selmaho.Bu), some(Selmaho.Zei)] and not is_kept:
      inc deficit
  if deficit > 0:
    var k = j - 1
    while k > 0 and not reader.items[k].isWall and reader.items[k].kept.len < deficit:
      deficit -= reader.items[k].kept.len
      dec k
    back = back.earlier(reader.landing(k, j, start))

  # zo sa poi facki no sinxa ne'i le se tcidu cu vimcu lo pu valsi
  #   .i le nu vimcu cu klama lo jgena poi vasru le sinxa .a lo krasi be lo se ciska pe zo sa to
  #     `CLL 19.13` toi
  for marker in region.markers:
    var k = j - 1
    while k > 0 and not reader.items[k].isWall and marker notin reader.items[k].kept: dec k
    back = back.earlier(reader.landing(k, j, start))

  # lo pamoi pagbu poi se tcidu cu krasi lo pagbu be le se ciska va'o po'o lo nu le pamoi pagbu cu
  #   krasi lo pagbu be le se ciska ba lo pagbu poi pu se tcidu to `isCutAt` toi
  #   .i ji'a lo nu sisti poi cmene lo pagbu poi se tcidu gi'e se lidne le jgena cu cmene le pamoi
  #     pagbu poi se tcidu vi
  let held = reader.items[j - 1].held
  if held < 0: return back
  var
    terminals: seq[Terminal]
    first_read = none(int)  # lo stuzi pe lo pamoi pagbu poi se tcidu
  for u in 0 ..< first:
    if not units[u].is_read: continue
    terminals.add units[u].terminal
    if first_read.isNone: first_read = some(region.reading.byteAt(u))
  let is_joined = terminals.len > 0 and not terminals.isCutAt(0, reader.items[j - 1].last)
  if is_joined or (reader.items[held].stop.isSome and reader.items[held].stop != first_read):
    back = back.earlier(reader.items[held].start)
  back



#[ ni'o ni'o ni'o lo cenba pe la'o gy. NIF .gy. ]#

func cut(reader: var ReaderLive, start: int): int =
  ## katna lo jgena .e lo krasi valsi .e la'o gy. NIF .gy. bu'u lo pamoi jgena poi lo se ciska poi
  ##   se krasi `start` cu vasru ke'a
  ##   .i ji'a jarco lo stuzi poi la'o gy. NIF .gy. cu se katna bu'u ke'a
  var
    j = reader.items.len
    n = reader.openers.len
  while j > 0 and reader.items[j - 1].start >= start: dec j
  while n > 0 and reader.openers[n - 1].start >= start: dec n
  reader.openers.setLen(n)
  result = (if j < reader.items.len: reader.items[j].offset else: reader.nif.len)
  reader.items.setLen(j)
  reader.nif.setLen(result)


func addItems(
    reader: var ReaderLive, region: ReadingParts, leaves: openArray[seq[int]],
    spans: openArray[int], start: int, is_final: bool, change: var ChangeNif,
) =
  ## benji lo jgena pe ro pagbu be le se tcidu be'o poi na romoi
  ##   .i ji'a benji lo jgena pe ro pagbu poi se to'e curmi gi'e lidne le romoi pagbu be le se tcidu
  ##   .i ro le jgena cu zvati pa linji pe vo'a
  ##   .i le romoi pagbu be le se tcidu be'o .e ro pagbu poi se lidne le romoi pagbu cu se benji
  ##     ta'i le rebla
  ##   .i ca lo fanmo ro jgena cu se benji
  ##   .i zo su cu fanmo lo se ciska poi lidne zo su
  ##   .i se ki'u bo ro jgena poi na se lidne zo su cu zi se benji
  ##   .i lo jgena poi se lidne zo su cu cpacu no da lo jgena poi lidne zo su
  ##   .i lo pagbu be le se ciska be'o poi vasru no pagbu zi'e noi lo se ciska poi vasru no pagbu
  ##     poi se tcidu cu jarco ke'a cu se benji va'o po'o lo nu no pagbu be lo se ciska pe vo'a cu
  ##     pu se benji kei ta'i lo nu le mulno se ciska cu se tcidu
  ##   .i le pagbu cu zvati lo fanmo be le pamoi se ciska noi lidne lo pamoi cmavo po'u zo su
  template children: untyped = region.reading.tree.children
    ## lo drata cmene be lo jgena pe lo genja be le se tcidu
    ##   .i `let` da'i fukpi le jgena
  template units: untyped = region.reading.units
    ## lo drata cmene be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo drata cmene be lo valsi pe le se tcidu
    ##   .i `let` da'i fukpi le valsi
  var
    # lo pamoi pezli be zo su ne'i le panzi
    #   .i va'o lo nu no pezli be zo su cu zvati kei le namcu cu du lo klani be le panzi
    first_su = children.len
    # lo romoi pezli be zo su ne'i le panzi
    #   .i va'o lo nu no pezli be zo su cu zvati kei le namcu cu du li ni'u pa
    last_su = -1
    # lo pamoi pezli poi se lidne le se ciska
    #   .i ro le pezli cu du zo fa'o poi fanmo le se ciska .a lo valsi poi se lidne zo fa'o
    first_ended = children.len
  for k in 0 ..< children.len:
    if not children[k].is_terminal: continue
    if units[children[k].at].isSu: (first_su, last_su) = (min(first_su, k), k)
    if region.faho.isSome and children[k].at >= region.faho.get:
      first_ended = min(first_ended, k)
  let
    # lo panzi poi ka'e du lo pagbu be le se ciska be'o poi vasru no pagbu
    hollow = min(first_su, first_ended) - 1
    is_hollow = reader.items.len > 0 and reader.items[^1].is_parted and hollow >= 0 and
      not children[hollow].is_terminal and leaves[hollow].len == 0
  var order: seq[int]  # lo porsi be lo panzi poi zi se benji gi'a se benji ta'i le rebla
  for k in 0 ..< children.len:
    if not is_hollow or k != hollow: order.add k
  var count = order.len  # lo panzi poi cmima `order` gi'e ca se benji
  if not is_final:
    count = 0
    for m in 0 ..< order.len:
      let k = order[m]
      if k == last_su: count = m + 1
      elif not children[k].is_terminal and leaves[k].len > 0: count = m
  for m in 0 ..< count:
    let k = order[m]
    var item = ItemLive(start: spans[k], offset: reader.nif.len, held: -1, start_reading: start)
    if children[k].is_terminal and units[children[k].at].isSu:
      item.is_su = true
      item.is_quoted = region.reading.byteAt(children[k].at) in region.quoted
    elif reader.items.len > 0:
      (item.last, item.held) = (reader.items[^1].last, reader.items[^1].held)
      item.is_parted = reader.items[^1].is_parted or not children[k].is_terminal
    else: item.is_parted = not children[k].is_terminal
    var read_last = -1  # lo romoi pagbu poi se tcidu
    for u in leaves[k]:
      template unit: untyped = units[u]
        ## lo drata cmene be le pagbu
        ##   .i `let` da'i fukpi le pagbu
      if unit.is_read: (item.last, read_last) = (some(unit.terminal), u)
      if unit.is_read or unit.refusal == RefusalText.Selmaho:
        for w in unit.words: item.kept.add occurrences[w].reading.toTerminal
    if read_last >= 0:
      item.held = reader.items.len
      let most = children[k].stopMost
      if most > read_last: item.stop = some(region.reading.byteAt(most))
    let line = children[k].toNif(region.reading) & "\n"
    reader.nif.add line
    change.text.add line
    reader.items.add item
  for m in count ..< order.len: change.tail.add children[order[m]].toNif(region.reading) & "\n"
  reader.tail = change.tail
  reader.start = (if count < order.len: spans[order[count]] else: region.reading.size)
  reader.start_tail = region.reading.size
  for m in count ..< order.len:
    if leaves[order[m]].len > 0:
      reader.start_tail = region.reading.byteAt(leaves[order[m]][0])
      break


func addOpeners(
    reader: var ReaderLive, region: ReadingParts, leaves: openArray[seq[int]],
    spans: openArray[int], start: int,
) =
  ## jmina ro krasi valsi poi denpa lo fanmo valsi pe ke'a gi'e zvati le se ciska poi se krasi
  ##   `start` ku'o ku'o ta'i lo porsi be lo stuzi
  ##   .i ro le krasi valsi cu du zo tu'e .a zo lu .a zo to .a zo lo'u .a zo zoi
  ##   .i zo tu'e .e zo lu .e zo to cu stali lo ka kalri
  ##   .i zo lo'u cu zvati pa pagbu poi vasru zo lo'u po'o
  ##   .i no korbi valsi cu fanmo zo zoi
  ##   .i va'o lo nu lo nu vimcu cu vimcu lo valsi poi lidne lo krasi valsi pe lo nu sitna kei kei
  ##     le krasi valsi cu rapli krasi bu'u `start`
  ##   .i lo fanmo valsi pe le krasi valsi cu tcidu le se ciska bu'u `start`
  ##   .i ki'u bo le fanmo valsi cu ka'e sitna lo valsi poi vimcu le valsi gi'a galfi lo sinxa be zo
  ##     sa poi lidne le krasi valsi
  func ownerAt(region: ReadingParts, owners: openArray[int], at: int): Option[int] =
    ## jarco lo stuzi poi lo panzi goi ko'a cu krasi bu'u ke'a
    ##   .i ko'a cu vasru lo pagbu poi vasru lo valsi poi krasi bu'u `at`
    ##   .i va'o lo nu no pagbu cu vasru lo valsi poi krasi bu'u `at` kei jarco no stuzi
    for u in 0 ..< region.reading.units.len:
      for w in region.reading.units[u].words:
        if region.reading.occurrences[w].start == at: return some(owners[u])
    none(int)

  template units: untyped = region.reading.units
    ## lo drata cmene be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo drata cmene be lo valsi pe le se tcidu
    ##   .i `let` da'i fukpi le valsi
  var
    # ro pagbu cu ponse lo stuzi poi lo se kuspe be lo panzi poi vasru le pagbu cu krasi bu'u ke'a
    owners = newSeq[int](units.len)
    # ro valsi cu ponse lo namcu pe lo pagbu poi vasru le valsi
    #   .i li ni'u pa cu sinxa lo nu no pagbu cu vasru le valsi
    holders = newSeq[int](occurrences.len)
    erased_first = int.high  # lo stuzi pe lo pamoi valsi poi lo nu vimcu cu pu vimcu ke'a
    added: seq[OpenerLive]
  for k in 0 ..< leaves.len:
    for u in leaves[k]: owners[u] = spans[k]
  for w in 0 ..< occurrences.len: holders[w] = -1
  for u in 0 ..< units.len:
    for w in units[u].words: holders[w] = u
  for w in 0 ..< occurrences.len:
    template word: untyped = occurrences[w]
      ## lo drata cmene be le valsi
      ##   .i `let` da'i fukpi le valsi
    if not word.reading.is_word or (holders[w] >= 0 and not units[holders[w]].isErasure): continue
    let
      selmaho = word.reading.selmaho
      is_erasing = selmaho.isSome and selmaho.get in {Selmaho.Si, Selmaho.Sa, Selmaho.Su}
    if not is_erasing:
      erased_first = word.start
      break
  template opening(at: int, owner: Option[int]): int =
    ## jarco lo stuzi poi lo nu tcidu cu rapli cfari bu'u ke'a ca lo nu lo fanmo valsi pe lo krasi
    ##   valsi pe lo nu sitna poi krasi bu'u `at` cu se tcidu
    if owner.isNone or erased_first < at: start else: owner.get
  for u in region.open:
    added.add OpenerLive(
      selmaho: Selmaho(int(units[u].terminal)), at: region.reading.byteAt(u), start: owners[u],
    )
  for at in region.lohus:
    let owner = region.ownerAt(owners, at)
    added.add OpenerLive(selmaho: Selmaho.Lohu, at: at, start: opening(at, owner))
  for zoi in region.zois:
    let owner = region.ownerAt(owners, zoi.start)
    added.add OpenerLive(
      selmaho: Selmaho.Zoi, at: zoi.start, start: opening(zoi.start, owner),
      after: reader.text.byteQuoted(zoi.start, zoi.delimiter), delimiter: zoi.delimiter,
    )

  # pa zo zoi goi ko'a cu zvati ne'i lo valsi poi zo lo'u cu sitna ke'a
  #   .i le porsi be lo valsi na tcidu ko'a ta'i lo krasi valsi pe lo nu sitna
  #   .i ko'a cu sitna le ci valsi poi se lidne ko'a ca lo nu le ci valsi cu klama to `toRoles` pe
  #     `prose.nim` toi
  #   .i se ki'u bo ko'a cu denpa
  #   .i ko'a cu sepli gi'a se vimcu
  for w in 0 ..< occurrences.len:
    template word: untyped = occurrences[w]
      ## lo drata cmene be le valsi
      ##   .i `let` da'i fukpi le valsi
    if not word.reading.is_word or word.reading.selmaho != some(Selmaho.Zoi): continue
    var
      # le re valsi poi le porsi be lo valsi cu tcidu ke'a zi'e poi se lidne zo zoi
      #   .i le pamoi cu korbi valsi
      #   .i le remoi cu se sitna va'o lo nu zasti
      reads: seq[int]
      next = w + 1
    while next < occurrences.len and reads.len < 2:
      template after: untyped = occurrences[next].reading
        ## lo drata cmene be lo nu tcidu lo bavla'i valsi
        ##   .i `let` da'i fukpi le nu tcidu
      if after.is_word or after.refusal == Refusal.Foreign: reads.add next
      inc next
    let
      is_quoting = reads.len == 2 and not occurrences[reads[1]].reading.is_word
      u = holders[w]
      is_erased = u < 0 or units[u].isErasure
      is_whole = not is_erased and (not units[u].is_read or units[u].words.countIt(it > w) >= 3)
    # le porsi be lo valsi cu sitna le se ciska
    #   .i ja le pagbu cu vasru le ci valsi pe zo zoi
    if is_quoting or is_whole: continue
    added.add OpenerLive(
      selmaho: Selmaho.Zoi, at: word.start,
      start: opening(word.start, if is_erased: none(int) else: some(owners[u])),
    )
  reader.openers.add added.sortedByIt(it.start)


func addRest(reader: var ReaderLive, first: int): ChangeNif =
  ## benji ro se ciska valsi pe le se ciska poi se krasi `first` ku'o ta'i pa pagbu poi vasru le se
  ##   ciska valsi po'o
  ##   .i le se ciska cu fanmo bu'u lo fanmo be le se tcidu gi'e se lidne zo fa'o poi fanmo lo se
  ##     ciska
  ##   .i le porsi be lo valsi na tcidu le se ciska valsi to `CLL 19.15` toi
  ##   .i no se ciska poi lidne le se ciska cu se rapli tcidu
  ##   .i ki'u bo ro jgena poi lidne zo fa'o cu pu se benji ca lo nu pu se tcidu
  result = ChangeNif(at: reader.nif.len, start: first)
  var at = first
  while at < reader.ending:
    if reader.text[at] in MARKS_BOUNDARY:
      inc at
      continue
    let start = at
    while at < reader.ending and reader.text[at] notin MARKS_BOUNDARY: inc at
    let
      ended = ReadingMarked(
        occurrences: @[reader.text.occurrenceEnded(start, at)],
        units: @[Unit(words: @[0], is_read: false, refusal: RefusalText.Stream)],
      )
      line = Node(is_terminal: true, at: 0).toNif(ended) & "\n"
    reader.items.add ItemLive(start: start, offset: reader.nif.len, held: -1, start_reading: start)
    reader.nif.add line
    result.text.add line
  reader.start_tail = reader.ending


func readChange(reader: var ReaderLive, at: int, is_final: bool): ChangeNif =
  ## tcidu lo se ciska poi se krasi `at`
  ##   .i ji'a tcidu ro pu se ciska poi le se ciska cu klama ke'a
  ##   .i jarco lo cenba pe la'o gy. NIF .gy.
  ##   .i le cenba cu vasru lo jgena pe ro pagbu be le se ciska poi se krasi lo pamoi jgena poi se
  ##     rapli tcidu ku'o ku'o ta'i lo nu ro le jgena cu se benji
  ##   .i ba bo le cenba cu vasru lo rebla pe le pagbu poi ca'o kalri
  var
    start = reader.boundary(at)
    region = reader.readFrom(start, is_final)
  while true:
    let back = reader.reach(region, start)
    if back.isNone or back.get >= start: break
    start = reader.boundary(back.get)
    region = reader.readFrom(start, is_final)
  var leaves = newSeq[seq[int]](region.reading.tree.children.len)
  for k in 0 ..< leaves.len: region.reading.tree.children[k].addLeaves(leaves[k])
  (result.at, result.start) = (reader.cut(start), start)
  let spans = region.toSpans(leaves, start)
  reader.addItems(region, leaves, spans, start, is_final or region.faho.isSome, result)
  if is_final: return
  reader.addOpeners(region, leaves, spans, start)
  if region.faho.isNone: return
  let faho = region.reading.byteAt(region.faho.get)
  var stop = faho
  while stop < reader.text.len and reader.text[stop] notin MARKS_BOUNDARY: inc stop
  reader.stop = some(stop)
  # lo panzi poi vasru zo fa'o
  #   .i lo fanmo be le se ciska cu rapli tcidu bu'u lo se kuspe be le panzi
  var k = 0
  while k < spans.high:
    template child: untyped = region.reading.tree.children[k]
      ## lo drata cmene be lo panzi be le genja
      ##   .i `let` da'i fukpi le panzi
    if child.is_terminal and child.at == region.faho.get: break
    inc k
  reader.start = min(reader.start, spans[k])  # lo fanmo be le se ciska cu rapli tcidu zo fa'o



#[ ni'o ni'o ni'o lo jmive se ciska ]#

func push*(reader: var ReaderLive, piece: string): ChangeNif =
  ## tcidu lo bavla'i spisa be lo jmive se ciska gi'e jarco lo cenba poi le spisa cu rinka ke'a ne'i
  ##   la'o gy. NIF .gy.
  ##   .i le cenba cu vasru lo jgena poi se benji .e lo rebla pe le pagbu poi ca'o kalri
  ##   .i le spisa cu ka'e katna lo valsi
  ##   .i lo bavla'i spisa cu fanmo le valsi
  doAssert not reader.is_ended, "Live text should take no piece after its end."
  reader.text.add piece
  var ending = reader.text.len  # le se tcidu cu fanmo ba le romoi sinxa poi jbini lo valsi
  while ending > reader.ending and reader.text[ending - 1] notin MARKS_BOUNDARY: dec ending
  if ending == reader.ending:
    return ChangeNif(at: reader.nif.len, start: reader.start_tail, tail: reader.tail)  # no cnino
  for n in 0 ..< reader.openers.len:
    template opener: untyped = reader.openers[n]
      ## lo drata cmene be le krasi valsi
      ##   .i `let` da'i fukpi le krasi valsi
    if reader.stop.isNone: break
    let is_closing = opener.selmaho == Selmaho.Zoi and opener.at < reader.stop.get and
      reader.text.isSpelled(max(reader.ending, opener.after), ending, opener.delimiter)
    if is_closing: reader.stop = none(int)  # zo zoi poi lidne zo fa'o cu sitna ri ca lo nu se fanmo
  let first = reader.ending  # lo se ciska poi na pu se tcidu
  reader.ending = ending
  if reader.stop.isSome: return reader.addRest(first)
  reader.readChange(reader.start, is_final = false)


func finish*(reader: var ReaderLive): ChangeNif =
  ## tcidu lo fanmo be lo jmive se ciska
  ##   .i lo se ciska poi se krasi lo pamoi krasi valsi poi ca'o denpa cu se tcidu ta'i lo nu le
  ##     mulno se ciska cu se tcidu
  ##   .i ro jgena poi stali cu se benji
  ##   .i se ki'u bo la'o gy. NIF .gy. cu vasru lo jgena pe ro pagbu be le se ciska
  doAssert not reader.is_ended, "Live text should end once."
  reader.is_ended = true
  var start = reader.start
  for n in 0 ..< reader.openers.len: start = min(start, reader.openers[n].start)
  reader.readChange(start, is_final = true)



#[ ni'o ni'o ni'o lo nu carna ]#

func toSentences*(piece: string): seq[string] =
  ## katna lo spisa pu ro cmavo be zoi gy. I .gy. .a zoi gy. NIhO .gy. ta'i lo nu le porsi be lo
  ##   valsi cu tcidu le spisa po'o
  ##   .i le cmavo cu krasi lo jufra .a lo jufra girzu
  ##   .i le spisa cu jalge lo nu jmina ro le se katna
  ##   .i se ki'u bo le samtci cu tcidu pa jufra ca ro nu `event loop` cu carna kei va'o lo nu le
  ##     papri cu dunda no gunka to la'o gy. Architect .gy. cu jdice di'u bu'u `#859` toi
  ##   .i va'o lo nu le porsi be lo valsi cu to'e curmi le spisa kei le porsi cu katna le spisa ne'i
  ##     lo valsi po'o poi lidne le nu to'e curmi
  ##   .i le nu katna cu galfi no pagbu be la'o gy. NIF .gy.
  ##   .i lo se ciska poi ro spisa be ke'a cu se tcidu ta'i lo porsi cu jarco la'o gy. NIF .gy. pe
  ##     lo pagbu be le se ciska va'o ro nu le spisa cu katna le se ciska to lo flalu pe
  ##     `test_live.nim` toi
  var reading = piece.readStream
  # lo valsi poi lidne le nu to'e curmi
  if not reading.is_read: reading = piece[0 ..< reading.start].readStream
  var last = 0
  if reading.is_read:
    for n in 0 ..< reading.occurrences.len:
      template occurrence: untyped = reading.occurrences[n]
        ## lo drata cmene be le valsi
        ##   .i `let` da'i fukpi le valsi va'o lo nu fanva fi la'o gy. JavaScript .gy.
      let is_opener = occurrence.reading.is_word and occurrence.reading.selmaho.isSome and
        occurrence.reading.selmaho.get in {Selmaho.I, Selmaho.Niho}
      if is_opener and occurrence.start > last:
        result.add piece[last ..< occurrence.start]
        last = occurrence.start
  result.add piece[last .. ^1]


func combine*(changes: openArray[ChangeNif], nif: string): ChangeNif =
  ## jmina lo cenba poi lo spisa poi se tcidu ta'i lo porsi cu rinka ke'a ku'o fo pa cenba pe ro le
  ##   spisa
  ##   .i le jalge cu krasi bu'u lo stuzi pe la'o gy. NIF .gy. ge'u .e lo stuzi pe le se ciska
  ##   .i ro le re stuzi cu du lo mleca traji stuzi poi su'o le cenba cu krasi bu'u ke'a
  ##   .i ji'a le jalge cu ponse la'o gy. NIF .gy. poi se krasi le stuzi pe la'o gy. NIF .gy. ku'o
  ##     ta'i lo nu `nif` cu vasru le se ciska ba le romoi cenba
  ##   .i ji'a le jalge cu ponse le rebla pe le romoi cenba
  ##   .i ro cenba cu ralte la'o gy. NIF .gy. poi lidne lo stuzi pe le cenba
  ##   .i se ki'u bo la'o gy. NIF .gy. poi lidne le mleca traji stuzi cu stali ta'i lo nu zasti pu
  ##     le pamoi cenba
  ##   .i ro valsi poi pa cenba cu ralte ke'a cu fanmo bu'u lo stuzi poi na se lidne le stuzi pe le
  ##     cenba
  ##   .i ro valsi poi le cenba cu jarco ke'a cu krasi bu'u lo stuzi poi na lidne le stuzi pe le
  ##     cenba
  ##   .i se ki'u bo le jalge cu jorne le se ciska le mleca traji stuzi ta'i lo nu ro cenba cu jorne
  ##     le se ciska lo stuzi pe vo'a
  doAssert changes.len > 0, "Changes should be one or more; got none."
  result = ChangeNif(at: changes[0].at, start: changes[0].start, tail: changes[^1].tail)
  for k in 1 ..< changes.len:
    result.at = min(result.at, changes[k].at)
    result.start = min(result.start, changes[k].start)
  result.text = nif[result.at .. ^1]
