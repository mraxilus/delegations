## tcidu ro spisa be lo mivyselci'a ca lo nu le spisa cu klama
##   .i ro jufra cu selbe'i ta'i `NIF` ca lo nu le jufra cu selfa'o
##   .i lo valsi poi galfi lo pu valsi cu katna `NIF`
##   .i se ki'u bo lo mivyselci'a pe so'i cacra cu se tcidu ca lo temci poi lo ni le selci'a cu
##       clani cu jarco ke'a to `#859` toi
##
##   |------------------|--------------------------------------------------------------------------|
##   | lo cmene         | lo smuni                                                                 |
##   |------------------|--------------------------------------------------------------------------|
##   | `ReaderLive`     | le ca selci'a .e `NIF` poi pu selbe'i .e lo kravla poi denpa      |
##   | `ChangeNif`      | lo cenba pe pa spisa ne'i `NIF`                                          |
##   |                  | .i re stuzi .e lo jgena .e lo rebla                                      |
##   | `initReaderLive` | lo mivyselci'atcidu noi `NIF` pe ke'a vasru lo minde po'o         |
##   | `push`           | tcidu lo bavla'i spisa be lo mivyselci'a                              |
##   | `finish`         | tcidu lo fanmo be lo mivyselci'a gi'e jarco lo stapau be `NIF`   |
##   | `toNif`          | `NIF` poi pu selbe'i                                                    |
##   | `countRead`      | le di'arcipra cu tcidu lo sumji be lo stuzi poi se tcidu ca ro nu tcidu |
##   | `toSentences`    | katna lo spisa pu ro valsi poi krasi lo jufra ja'i le porsi be lo valsi  |
##   | `combine`        | jmina lo cenba pe lo spisa poi se tcidu ta'i lo porsi ku'o fo pa cenba   |
##   |------------------|--------------------------------------------------------------------------|
##
## ni'o le tarmi cu seljdi `Architect` bu'u `#859`
##   .i ro pagbu be le selci'a cu se tcidu ta'i pa mulno se ciska to `readTextParts` toi
##   .i lo jgena pe ro pagbu be le selci'a cu selbe'i ne'i pa linji pe vo'a ca lo nu le bavla'i
##       pagbu cu cfari
##   .i ro pagbu poi se to'e curmi gi'e jbini re pagbu be le selci'a cu go'i ji'a
##   .i lo tricu be le selci'a cu jalge le jgena to `assembleText` toi
##   .i se ki'u bo no pagbu be le tricu cu selcri
##   .i no spisa cu raptcidu le mulselci'a
##   .i ro spisa cu tcidu le selci'a poi selkra le pagbu poi ca'o kalri
##   .i lo valsi poi galfi lo pu valsi cu rinka lo nu raptcidu le selci'a poi selkra lo jgena poi le
##       valsi cu klama ke'a
##   .i `NIF` selka'a bu'u lo stuzi poi le jgena cu krasi bu'u ke'a
##   .i `ChangeNif` jarco le stuzi ta'i lo sinxa be lo stuzi
##   .i ji'a ro cenba cu jarco lo stuzi be le selci'a be'o poi le jgena cu krasi bu'u ke'a
##   .i se ki'u bo ca ro cenba lo drata samtci cu ka'e rinka lo nu ro jgena cu jorne lo selci'a poi
##       le jgena cu tcidu ke'a
##   .i lo jgena pe le pagbu poi ca'o kalri cu selbe'i ta'i lo rebla
##   .i lo bavla'i cenba cu basti le rebla
##   .i se ki'u bo le tricu cu zenba ca ro nu pa valsi cu klama
##   .i lo samtci poi pixra lo nu le tricu cu binxo cu ka'e jarco lo nu le tricu cu zenba
##   .i lo spisa cu ka'e katna lo valsi
##   .i se ki'u bo le se tcidu cu sisti pu lo romoi se ciska valsi poi no sinxa cu fanmo ke'a
##   .i se ki'u bo zo su poi lo bavla'i spisa cu galfi ke'a zo su'i vimcu no da
##   .i le se tcidu cu krasi bu'u lo selku'e be pa jgena
##   .i le selku'e cu krasi bu'u lo pamoi valsi poi se lidne lo valsi pe lo jgena poi lidne le jgena
##   .i se ki'u bo le selku'e cu vasru ro valsi poi lo nu vimcu cu pu vimcu ke'a zi'e poi lidne le
##       jgena
##   .i lo jgena goi ko'e pilno lo selku'e be lo jgena poi lidne ko'e ku'o va'o lo nu lo nu sitna cu
##       vasru lo valsi poi le selku'e be ko'e cu ka'e krasi bu'u ke'a
##   .i ji'a ko'e pilno lo selku'e be lo jgena poi lidne ko'e ku'o va'o lo nu lo pamoi valsi pe ko'e
##       cmima lo valsi pe lo jgena poi lidne ko'e
##   .i mupli fa lo valsi poi le porsi be lo valsi cu to'e curmi ke'a zi'e poi jbini pa valsi .e zo
##       bu
##   .i ji'a ko'e pilno lo selku'e be lo jgena poi lidne ko'e ku'o va'o lo nu le javni cu to'e curmi
##       pa zo zei poi lidne ko'e
##   .i zo zei jorne lo valsi poi se lidne zo zei ca lo nu le javni cu tcidu pa valsi to `CLL 19.16`
##       toi
##   .i lo nu galfi lo pu valsi cu selkra le selci'a poi selraptcidu gi'e klama lo jgena poi lidne
##       le selci'a
##   .i zo si poi facki no valsi cu klama ro pu valsi poi zo si vimcu ke'a
##   .i zo bu .a zo zei klama lo pu valsi va'o lo nu le cmavo cu facki no valsi
##   .i zo sa poi facki no sinxa cu klama lo jgena poi vasru le sinxa .a lo krasi be le se ciska to
##       `CLL 19.13` toi
##   .i lo nu vimcu cu klama no jgena poi lidne zo su to `CLL 19.13` toi
##   .i lo pamoi pagbu poi se tcidu zi'e poi krasi no pagbu be le selci'a cu klama lo jgena poi
##       vasru lo romoi pagbu poi se tcidu
##   .i mupli fa zo zei poi rinka lo nu zo .i jorne lo valsi poi se lidne zo zei
##   .i lo srejge goi ko'i selkla ca lo nu cenba fa lo pagbu poi se tcidu gi'e se lidne ko'i va'o lo
##       nu lo nu ko'i sisti cu cmene le pagbu
##   .i lo famvla be lo krasi valsi poi denpa cu klama lo jgena poi vasru le kravla
##   .i zo su fanmo lo selci'a poi lidne zo su
##   .i le selci'a cu stali ta'i lo nu pu se tcidu
##   .i se ki'u bo `NIF` selka'a bu'u no stuzi
##   .i zo su selbe'i ta'i pa jgena poi vasru zo su po'o
##   .i le jgena cu selbe'i pu lo selci'a poi se lidne zo su
##   .i le selci'a cu se tcidu ta'i pa mulno se ciska to `Architect` jdice di'u bu'u `#859` toi
##   .i lo kravla poi denpa gi'e zvati lo selci'a poi lidne zo su selfa'o bu'u zo su ta'i lo nu
##       selfa'o bu'u lo fanmo be lo selci'a
##   .i le kravla cu du zo tu'e .a zo lu .a zo to
##   .i se ki'u bo le selci'a cu selraptcidu bu'u le kravla
##   .i lo nu sitna poi denpa cu sitna zo su ca lo nu le nu sitna cu se fanmo to `CLL 19.9` .e
##       `CLL 19.10` toi
##   .i lo kravla poi denpa lo famvla pe ke'a se tcidu ta'i lo sapygenvla
##   .i le kravla cu du zo tu'e .a zo lu .a zo to .a zo lo'u .a zo zoi .a zo la'o
##   .i se ki'u bo lo jufra poi se lidne le kravla cu zi selbe'i
##   .i lo famvla pe le kravla cu raptcidu le jufra
##   .i va'o lo nu lo nu vimcu cu vimcu lo valsi poi lidne lo kravla pe lo nu sitna kei kei le
##       selci'a poi vasru le kravla cu selraptcidu bu'u lo krasi be le selci'a
##   .i ki'u bo lo famvla pe le nu sitna cu ka'e sitna lo valsi poi vimcu le valsi
##   .i ca lo fanmo lo selci'a poi selkra lo pamoi krasi valsi poi ca'o denpa cu se tcidu ta'i lo nu
##       le mulselci'a cu se tcidu
##   .i ca le fanmo zo lu .e zo to .e zo tu'e selfa'o
##   .i ki'u bo `CLL 21.1` curmi lo nu lo famvla pe le ci cmavo cu na selci'a
##   .i zo zoi .e zo la'o .e zo lo'u se tcidu ta'i lo srera
##   .i lo selci'a poi se lidne zo lo'u poi denpa cu se tcidu ne'i lo valsi poi zo lo'u sitna ke'a
##       ta'i lo nu le porsi be lo valsi cu tcidu to `CLL 19.9` toi
##   .i bu'u le selci'a zo zoi sitna le ci valsi poi se lidne zo zoi ca lo nu le ci valsi cu klama
##       to `toRoles` toi
##   .i se ki'u bo zo zoi denpa
##   .i zo lo'u poi lo nu vimcu cu vimcu zo le'u pe ke'a denpa no da
##   .i ki'u bo le porsi be lo valsi cu tcidu zo le'u
##   .i zo fa'o poi fanmo lo se ciska to `CLL 19.15` toi cu rinka lo nu ro spisa cu sisti bu'u zo
##       fa'o
##   .i lo famvla pe pa zo zoi poi lidne zo fa'o vimcu le nu sisti ca lo nu le famvla cu klama
##   .i ki'u bo zo zoi sitna zo fa'o
##   .i ro jgena cu selbe'i ca lo nu zo fa'o se tcidu
##   .i ro selci'avla poi se lidne zo fa'o selbe'i ta'i pa pagbu poi vasru le se ciska valsi po'o ca
##       lo nu lo sinxa cu fanmo le selci'avla
##   .i se ki'u bo no spisa cu raptcidu le selci'a
##   .i se ki'u bo ba zo fa'o le jdima cu zenba ta'i lo linji
##   .i ca lo fanmo le selci'a cu selraptcidu bu'u zo fa'o ta'i lo nu le mulselci'a cu se tcidu
##   .i ro valsi poi lo nu vimcu cu vimcu ke'a zvati pa pagbu poi vasru le valsi po'o to `prose.nim`
##       toi
##   .i lo jgena poi se lidne le pagbu cu pilno lo selku'e be le pagbu
##   .i se ki'u bo le valsi cu selraptcidu ca lo nu le selci'a cu selraptcidu bu'u le jgena
##   .i ki'u bo lo nu vimcu poi zvati le selci'a cu pu ka'e vimcu le valsi
##   .i flalu fa lo du'u ca lo fanmo `NIF` pe lo selci'a poi ro spisa be ke'a se tcidu ta'i lo porsi
##       cu mintu `NIF` pe lo pagbu be le selci'a poi se tcidu ta'i lo mulno kei .e lo du'u pu lo
##       fanmo `NIF` .e le rebla pe ro cenba cu mintu `NIF` pe lo pagbu be lo selci'a poi ca zvati
##       gi'e fanmo bu'u lo romoi sinxa pe ke'a be'o poi se tcidu ta'i pa mulno jmive se ciska to
##       `test_live.nim` toi
##   .i jdima fa lo nu ro spisa cu raptcidu le pagbu poi ca'o kalri
##   .i se ki'u bo le temci cu zenba ta'i lo pilji be lo ni le selci'a cu clani kei bei lo ni pa
##       jufra cu clani
##   .i lo valsi poi galfi lo pu valsi cu rinka lo nu raptcidu pa roi bu'u lo jgena poi le valsi cu
##       klama ke'a
##   .i le tcidu cu rapli ja'i lo namcu pe lo porsi
##   .i ki'u bo `items` fukpi va'o lo nu fanva fi `JavaScript`

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]

import ./[grammar, nif, prose, selmaho, stream, tanru]


type
  ChangeNif* = object
    ## lo cenba poi pa spisa be lo mivyselci'a cu rinka ke'a ne'i `NIF`
    at*: int
      ## lo stuzi poi le cenba cu krasi bu'u ke'a ne'i `NIF`
      ##   .i `NIF` poi selkra le stuzi cu selvi'u
      ##   .i ba bo `text` se jmina
    start*: int
      ## lo stuzi poi le cenba cu krasi bu'u ke'a ne'i le selci'a
      ##   .i ro valsi pe `NIF` poi lidne `at` fanmo bu'u lo stuzi poi na se lidne le stuzi
      ##   .i ro valsi pe `text` .e `tail` krasi bu'u lo stuzi poi na lidne le stuzi
      ##   .i se ki'u bo `NIF` jorne le selci'a poi se tcidu
    text*: string
      ## `NIF` pe ro jgena poi selbe'i
      ##   .i ro le jgena cu zvati pa linji pe vo'a
    tail*: string
      ## `NIF` pe ro jgena poi ca'o kalri
      ##   .i le selci'a poi ca zvati cu jarco le jgena
      ##   .i ro le jgena cu zvati pa linji pe vo'a
      ##   .i lo bavla'i cenba cu basti le rebla

  ItemLive = object
    ## lo jgena poi pu selbe'i
    ##   .i le jgena cu srana pa pagbu be le selci'a be'o .a pa pagbu poi se to'e curmi gi'e jbini
    ##       re pagbu be le selci'a
    start: int
      ## lo stuzi poi lo selku'e be le jgena cu krasi bu'u ke'a
      ##   .i lo valsi poi se lidne lo valsi pe lo jgena poi lidne le jgena cu krasi bu'u le stuzi
      ##       to `toSpans` toi
    offset: int  ## lo stuzi poi lo linji pe le jgena cu krasi bu'u ke'a ne'i `NIF`
    kept: seq[Option[Terminal]]
      ## lo porsi be lo genvla pe ro valsi poi le jgena cu vasru ke'a zi'e poi lo nu vimcu cu ka'e
      ##     vimcu ke'a
      ##   .i le valsi cu pagbu lo pagbu poi se tcidu .a lo pagbu poi vasru lo cmavo poi no liste cu
      ##       dunda lo selma'o ke'a
    last: Option[Terminal]
      ## lo genvla pe lo romoi pagbu poi se tcidu ne'i le jgena .a lo jgena poi lidne le jgena
    held: int
      ## lo namcu pe lo romoi jgena poi vasru lo pagbu poi se tcidu
      ##   .i le romoi jgena cu du le jgena .a lo jgena poi lidne le jgena
      ##   .i va'o lo nu no jgena cu vasru lo pagbu poi se tcidu kei le namcu cu du li ni'u pa
    is_parted: bool
      ## lo du'u su'o pagbu be lo selci'a pe le jgena cu pu selbe'i bu'u le jgena .a lo jgena poi
      ##     lidne le jgena
      ##   .i ki'u la'e di'u lo pagbu be le selci'a be'o poi vasru no pagbu zi'e noi lo selci'a poi
      ##       vasru no pagbu poi se tcidu cu jarco ke'a zvati le selci'a pa roi
    stop: Option[int]
      ## lo stuzi pe lo pagbu poi se tcidu gi'e se lidne le jgena
      ##   .i lo nu sisti pe lo srejge pe le jgena cu cmene le pagbu
      ##   .i le datnypau cu kunti va'o lo nu no nu sisti cu cmene lo pagbu poi se lidne lo pagbu pe
      ##       le jgena
    is_su: bool
      ## lo du'u le jgena cu pezli zo su noi fanmo lo selci'a poi lidne zo su
      ##   .i lo nu vimcu poi se lidne zo su klama no jgena poi lidne zo su
      ##   .i ku'i va'o lo nu `is_quoted` jetnu kei lo nu vimcu cu ka'e klama lo jgena poi lidne zo
      ##       su
    is_quoted: bool
      ## lo du'u le jgena cu pezli zo su poi lo nu sitna cu vasru ke'a ca lo pamoi nu le javni pe
      ##     `CLL 19.16` tcidu
      ##   .i lo nu vimcu poi se lidne zo su klama lo jgena poi lidne zo su
      ##   .i ki'u bo lo nu vimcu poi vimcu lo datpau be le nu sitna cu rinka lo nu zo su
      ##       rapselsitna
    start_reading: int
      ## lo stuzi poi lo nu tcidu poi benji le jgena cu cfari bu'u ke'a
      ##   .i lo famvla pe lo nu sitna poi sitna zo su rinka lo nu le selci'a cu selraptcidu bu'u le
      ##       stuzi
      ##   .i ki'u bo ca la'e di'u zo su fanmo no selci'a

  OpenerLive = object
    ## lo kravla poi denpa lo famvla pe ke'a ne'i le selci'a poi ca zvati
    selmaho: Selmaho
      ## lo selma'o be le kravla
      ##   .i le selma'o cu du zoi gy. TUhE .gy. .a zoi gy. LU .gy. .a zoi gy. TO .gy. .a zoi gy.
      ##       LOhU .gy. .a zoi gy. ZOI .gy. pe zo zoi .e zo la'o
    at: int  ## lo stuzi poi le kravla cu krasi bu'u ke'a
    start: int
      ## lo stuzi poi lo selku'e be lo jgena poi vasru le krasi valsi cu krasi bu'u ke'a
      ##   .i lo famvla pe le kravla cu rinka lo nu raptcidu bu'u le stuzi
    after: int
      ## lo stuzi poi krasi lo selci'a poi zo zoi sitna ke'a
      ##   .i le stuzi cu se lidne lo koivla pe zo zoi
      ##   .i li no va'o lo nu le kravla cu na du zo zoi
    delimiter: string
      ## lo koivla pe zo zoi noi fanmo le nu sitna
      ##   .i le koivla cu kunti va'o lo nu le kravla cu na du zo zoi
      ##   .i ji'a le koivla cu kunti va'o lo nu zo zoi goi ko'u sitna le ci valsi poi se lidne ko'u
      ##       ne'i lo valsi poi zo lo'u sitna ke'a
      ##   .i ro valsi cu fanmo ko'u

  ReaderLive* = object
    ## lo tcidu be lo mivyselci'a
    ##   .i le tcidu cu ponse le selci'a poi ca zvati .e `NIF` poi pu selbe'i .e lo kravla poi denpa
    text: string
    nif: string  ## le minde cu lidne lo linji pe ro jgena poi pu selbe'i
    tail: string
      ## `NIF` pe ro jgena poi ca'o kalri
      ##   .i le romoi cenba cu jarco le jgena
    start_tail: int
      ## lo stuzi poi lo pamoi valsi pe le rebla cu krasi bu'u ke'a
      ##   .i le stuzi cu se lidne ro valsi poi pu selbe'i
      ##   .i lo cenba pe lo spisa poi rinka lo nu tcidu no datyvla cu krasi bu'u le stuzi
      ##   .i va'o lo nu le rebla cu vasru no valsi kei le stuzi cu du lo fanmo be le se tcidu
    items: seq[ItemLive]  ## lo porsi be ro jgena poi pu selbe'i
    openers: seq[OpenerLive]  ## lo porsi be ro kravla poi denpa ku'o bei lo stuzi
    start: int  ## lo stuzi poi lo selci'a poi na pu selbe'i cu krasi bu'u ke'a
    count_read: int
      ## lo sumji be lo stuzi poi se tcidu ca ro nu tcidu
      ##   .i le di'arcipra cu tcidu le sumji
    ending: int
      ## lo stuzi poi le romoi se tcidu cu fanmo bu'u ke'a
      ##   .i le stuzi cu se lidne lo romoi sinxa poi jbini lo valsi
    stop: Option[int]
      ## lo stuzi poi se lidne lo selci'avla pe zo fa'o poi fanmo lo se ciska to `CLL 19.15` toi
      ##   .i ro spisa cu sisti lo nu tcidu bu'u le stuzi
      ##   .i le datnypau cu kunti pu lo nu zo fa'o se tcidu
      ##   .i lo fanmo be le selci'a cu tcidu ba le stuzi
      ##   .i ki'u bo lo famvla pe lo kravla poi lidne zo fa'o cu ka'e sitna zo fa'o
    is_ended: bool  ## lo du'u lo fanmo be le mivyselci'a cu pu se tcidu


func initReaderLive*(): ReaderLive =
  ## zbasu lo tcidu be lo mivyselci'a be'o noi `NIF` pe ke'a vasru lo minde po'o
  ReaderLive(nif: HEADER)


func toNif*(reader: ReaderLive): string = reader.nif
  ## jarco `NIF` poi pu selbe'i
  ##   .i le minde cu lidne lo linji pe ro jgena

func countRead*(reader: ReaderLive): int = reader.count_read
  ## jarco lo sumji be lo stuzi poi se tcidu ca ro nu tcidu le selci'a
  ##   .i le sumji cu jdima
  ##   .i le jdima cu zenba ta'i lo pilji be lo ni le selci'a cu clani kei bei lo ni pa jufra cu
  ##       clani



#[ ni'o ni'o ni'o lo se tcidu ]#

func isSu(unit: Unit): bool =
  ## jdice lo du'u le pagbu cu vasru zo su po'o
  ##   .i zo su fanmo lo selci'a poi lidne zo su
  not unit.is_read and unit.refusal == RefusalText.Su


func isErasure(unit: Unit): bool =
  ## jdice lo du'u le pagbu cu vasru lo valsi poi lo nu vimcu cu vimcu ke'a .e lo cmavo poi vimcu le
  ##     valsi
  not unit.is_read and unit.refusal == RefusalText.Erasure


func isWall(item: ItemLive): bool =
  ## jdice lo du'u le jgena cu pezli zo su gi'e selkla no nu vimcu poi se lidne le jgena
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
  ##   .i lo srejge cu sinxa le stuzi poi le gerna cu sisti bu'u ke'a
  ##   .i va'o lo nu le gerna cu sisti bu'u no pagbu kei jarco li ni'u pa
  if node.is_terminal: return -1
  result = (if node.stop.isSome: node.stop.get.at else: -1)
  for k in 0 ..< node.children.len: result = max(result, node.children[k].stopMost)


func toCleans(occurrences: openArray[Occurrence]): seq[bool] =
  ## jdice fi ro valsi pe le se tcidu fe lo du'u xu kau le porsi be lo valsi cu tcidu le selci'a poi
  ##     selkra le valsi ta'i lo nu tcidu le valsi bu'u lo stuzi pe le valsi
  ##   .i la'e di'u jetnu va'o lo nu no nu sitna cu vasru le valsi
  ##   .i mupli fa lo valsi poi zo zo sitna ke'a
  ##   .i mupli fa ji'a lo valsi poi zo zoi .a zo la'o sitna ke'a
  ##   .i mupli fa ji'a lo valsi poi zo lo'u sitna ke'a zi'e poi zo le'u fanmo lo nu sitna pe ke'a
  ##   .i ro valsi poi le porsi be lo valsi cu to'e curmi ke'a ponse lo jalge pe lo valsi poi le
  ##       porsi cu tcidu ke'a zi'e poi se lidne le valsi
  ##   .i zo lo'u poi no zo le'u fanmo ke'a denpa ta'i lo krasi valsi to `OpenerLive` toi
  func isSelmaho(word: Occurrence, selmaho: Selmaho): bool =
    ## jdice lo du'u le valsi cu cmavo `selmaho`
    word.reading.is_word and word.reading.selmaho == some(selmaho)

  result = newSeq[bool](occurrences.len)
  var
    # ro valsi poi le porsi be lo valsi cu tcidu ke'a
    #   .i no valsi poi le porsi cu to'e curmi ke'a cmima
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
      ## lo datcme be le valsi
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
  # le porsi be lo valsi cu tcidu lo selci'a poi selkra le bavla'i valsi ta'i lo nu tcidu le valsi
  #     bu'u lo stuzi pe le valsi
  var is_clean = true
  for k in countdown(occurrences.high, 0):
    if is_reads[k]: is_clean = result[k] else: result[k] = is_clean


func toSpans(region: ReadingParts, leaves: openArray[seq[int]], first: int): seq[int] =
  ## jarco lo stuzi poi lo selku'e be ro panzi be lo genja be le se tcidu cu krasi bu'u ke'a
  ##   .i le selku'e cu krasi bu'u lo pamoi valsi poi se lidne lo valsi pe lo panzi poi lidne le
  ##       panzi
  ##   .i se ki'u bo le selku'e cu vasru ro valsi poi lo nu vimcu cu pu vimcu ke'a zi'e poi lidne le
  ##       panzi zi'e noi lo nu vimcu poi zvati le panzi cu pu ka'e vimcu ke'a
  ##   .i le pamoi se kuspe cu krasi bu'u `first`
  ##   .i lo panzi goi ko'e pilno lo selku'e be lo panzi poi lidne ko'e ku'o va'o lo nu lo pamoi
  ##       valsi pe ko'e cmima lo valsi pe le panzi poi lidne ko'e
  ##   .i mupli fa lo valsi poi se to'e curmi gi'e jbini pa valsi .e lo cnivla poi tcita le valsi
  ##   .i ji'a ko'e pilno lo selku'e be lo panzi poi lidne ko'e ku'o va'o lo nu lo nu sitna cu vasru
  ##       lo valsi poi le selku'e be ko'e cu ka'e krasi bu'u ke'a to `toCleans` toi
  ##   .i lo nu vimcu cu pu vimcu le valsi
  ##   .i ji'a ko'e pilno lo selku'e be lo panzi poi lidne ko'e ku'o va'o lo nu lo valsi poi lidne
  ##       lo pamoi valsi pe ko'e du pa zo sa poi lo nu vimcu cu pu vimcu ke'a
  ##   .i lo nu sisku lo pu valsi cu cliva ro valsi poi se to'e curmi le porsi be lo valsi .a le
  ##       javni
  ##   .i ki'u bo lo pamoi valsi poi le javni cu tcidu ke'a zi'e poi se lidne zo sa dunda lo sinxa
  ##       be zo sa to `CLL 19.13` toi
  ##   .i ji'a ko'e pilno lo selku'e be lo panzi poi lidne ko'e ku'o va'o lo nu le panzi poi lidne
  ##       ko'e du lo valsi poi lo nu vimcu cu pu vimcu ke'a
  ##   .i lo nu vimcu poi zvati ko'e cu pu ka'e vimcu le valsi
  ##   .i ji'a ko'e pilno lo selku'e be lo panzi poi lidne ko'e ku'o va'o lo nu le javni cu to'e
  ##       curmi pa zo zei poi lidne lo pamoi valsi pe ko'e
  ##   .i lo nu sisku lo pu valsi cu cliva ro valsi poi se to'e curmi le porsi be lo valsi .a le
  ##       javni gi'a selvi'u lo nu vimcu
  ##   .i ki'u bo zo zei jorne lo valsi poi se lidne zo zei ca lo nu le javni cu tcidu pa valsi bu'u
  ##       le stuzi
  ##   .i mupli fa lo nu le javni cu to'e curmi lo nu sitna poi krasi bu'u le stuzi to `CLL 19.16`
  ##       toi
  func isRefused(unit: Unit): bool =
    ## jdice lo du'u lo javni pe `CLL 19.16` to'e curmi le pagbu
    ##   .i se ki'u bo le javni cu ranji lo nu tcidu ba lo valsi pe le pagbu
    not unit.is_read and unit.refusal in {RefusalText.Quotation, RefusalText.Construct}

  func isRefusedZei(unit: Unit, word: Occurrence): bool =
    ## jdice lo du'u le valsi pe le pagbu cu du zo zei gi'e se to'e curmi le javni
    ##   .i zo zei jorne lo valsi poi se lidne zo zei ca lo nu le javni cu tcidu pa valsi
    not unit.is_read and unit.refusal == RefusalText.Construct and word.reading.is_word and
      word.reading.selmaho == some(Selmaho.Zei)

  template units: untyped = region.reading.units
    ## lo datcme be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo datcme be lo valsi pe le se tcidu
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
      # lo pu valsi poi na se to'e curmi le porsi be lo valsi .a le javni gi'e na selvi'u
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
  ## jarco lo stuzi poi krasi lo selci'a poi zo zoi sitna ke'a
  ##   .i zo zoi krasi bu'u `at`
  ##   .i le stuzi cu se lidne lo selci'avla poi se lidne zo zoi va'o lo nu le selci'avla cu du le
  ##       koivla
  ##   .i va'o lo drata le stuzi cu se lidne lo selci'avla poi vasru zo zoi
  ##   .i ca la'e di'u le selci'avla cu vasru le koivla
  var a = at
  while a < text.len and text[a] notin MARKS_BOUNDARY: inc a
  var b = a
  while b < text.len and text[b] in MARKS_BOUNDARY: inc b
  var c = b
  while c < text.len and text[c] notin MARKS_BOUNDARY: inc c
  if text[b ..< c].toLowerAscii.replace(",", "") == delimiter: c else: a


func isSpelled(text: string, first, last: int, delimiter: string): bool =
  ## jdice lo du'u su'o selci'avla pe lo stuzi po'u `first ..< last` pe le selci'a cu du `delimiter`
  ##     ta'i lo nu le porsi be lo valsi cu tcidu lo valsi poi fanmo lo selci'a poi zo zoi sitna
  ##     ke'a to `CLL 19.10` toi
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
  ## tcidu lo selci'a poi selkra `start` ku'o ta'i lo pagbu be le selci'a
  ##   .i lo nu kancu ro stuzi cu cfari bu'u lo krasi be le mulselci'a
  ##   .i va'o lo nu zo lo'u poi denpa cu lidne `start` kei le selci'a cu se tcidu ne'i lo valsi poi
  ##       zo lo'u sitna ke'a ta'i lo nu le porsi be lo valsi cu tcidu
  ##   .i pu lo fanmo le se tcidu cu sisti pu lo romoi se ciska valsi poi no sinxa cu fanmo ke'a
  ##   .i ki'u bo lo bavla'i spisa cu ka'e ranji le selci'avla mu'u lo nu zo su binxo zo su'i
  ##   .i ji'a le se tcidu cu sisti bu'u zo fa'o poi fanmo le selci'a
  ##   .i ku'i lo fanmo be le se tcidu cu se kancu ba lo selci'a poi se lidne zo fa'o
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
  ## jarco lo stuzi poi lo famvla pe le kravla pe lo nu sitna cu raptcidu le selci'a bu'u ke'a
  ##   .i le stuzi cu du lo krasi be lo jgena poi vasru le kravla
  ##   .i ja le stuzi cu du lo stuzi poi lo nu tcidu poi benji pa zo su poi se lidne le kravla cu
  ##       cfari bu'u ke'a
  ##   .i ki'u bo le nu sitna cu sitna ro zo su poi se lidne le kravla
  ##   .i se ki'u bo lo selci'a poi lidne zo su selraptcidu ta'i lo selci'a poi zo su na fanmo ke'a
  ##       to `CLL 19.9` .e `CLL 19.10` toi
  result = opener.start
  var k = reader.items.high
  while k >= 0 and reader.items[k].start > opener.at:
    if reader.items[k].is_su: result = min(result, reader.items[k].start_reading)
    dec k


func boundary(reader: ReaderLive, at: int): int =
  ## jarco lo stuzi poi na se lidne `at` zi'e poi lo nu tcidu cu ka'e rapcfa bu'u ke'a
  ##   .i lo selci'avla goi ko'a vasru `at`
  ##   .i le stuzi cu du lo krasi be lo jgena poi vasru lo pamoi stuzi pe ko'a
  ##   .i ki'u bo le porsi be lo valsi cu tcidu ro selci'avla ta'i lo mulno
  ##   .i va'o lo nu no jgena cu zvati le stuzi kei le stuzi cu du lo krasi be le selci'a
  result = at
  while result > 0 and reader.text[result - 1] notin MARKS_BOUNDARY:
    var first = result - 1
    while first > 0 and reader.text[first - 1] notin MARKS_BOUNDARY: dec first
    var k = reader.items.high
    while k >= 0 and reader.items[k].start > first: dec k
    result = (if k >= 0: reader.items[k].start else: 0)


func reach(reader: ReaderLive, region: ReadingParts, start: int): Option[int] =
  ## jarco lo pamoi stuzi poi lidne `start` zi'e poi lo nu tcidu le selci'a poi selkra `start` klama
  ##     ke'a
  ##   .i le selkla cu du lo jgena poi vasru lo kravla poi le selci'a cu vasru lo famvla pe ke'a
  ##   .i ja le selkla cu du lo jgena poi vasru lo kravla poi zo su fanmo ke'a
  ##   .i ja le selkla cu du lo jgena poi lo nu vimcu pe le selci'a cu klama ke'a
  ##   .i ja le selkla cu du lo jgena poi lo pamoi pagbu poi se tcidu cu jorne ke'a
  ##   .i ja le selkla cu du pa srejge goi ko'i noi lo nu ko'i sisti cu cmene lo pagbu poi se tcidu
  ##       gi'e se lidne ko'i
  ##   .i va'o lo nu le selci'a poi lidne `start` se tcidu ta'i lo nu pu se tcidu kei kei jarco no
  ##       stuzi
  ##   .i ro valsi poi se lidne lo pamoi cmavo po'u zo su pe le se tcidu cu klama no jgena poi lidne
  ##       le cmavo
  ##   .i ku'i lo famvla pe lo nu sitna noi sitna zo su cu ka'e klama lo jgena poi lidne le cmavo
  func earlier(back: Option[int], at: int): Option[int] =
    ## jarco lo pamoi be le stuzi poi selra'e ku'o joi `at`
    some(if back.isSome: min(back.get, at) else: at)

  func landing(reader: ReaderLive, k, j, start: int): int =
    ## jarco lo stuzi poi le jgena pe `k` krasi bu'u ke'a
    ##   .i lo nu vimcu pe le selci'a poi selkra `start` klama le jgena
    ##   .i le nu vimcu cu cliva le jgena pe `j`
    ##   .i va'o lo nu le jgena cu pezli zo su poi lo nu vimcu cu na klama ke'a kei le stuzi cu se
    ##       lidne le jgena
    if not reader.items[k].isWall: reader.items[k].start
    elif k + 1 < j: reader.items[k + 1].start
    else: start

  template units: untyped = region.reading.units
    ## lo datcme be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo datcme be lo valsi pe le se tcidu
    ##   .i `let` da'i fukpi le valsi
  var
    back = none(int)
    j = reader.items.len  # lo jgena poi lidne `start`
    first = 0  # lo pagbu poi lidne lo pamoi cmavo po'u zo su pe le se tcidu
  while j > 0 and reader.items[j - 1].start >= start: dec j
  while first < units.len and not units[first].isSu: inc first

  # lo famvla poi no kravla pe le selci'a cu mapti ke'a zi'e poi mapti zo tu'e .a zo lu .a zo to
  #     fanmo lo kravla poi mapti le famvla gi'e denpa gi'e lidne le selci'a
  #   .i le jbirai cu pamoi
  #   .i le so'i nu tcidu cu jersi le kravla ta'i la'e di'u to `toParts` toi
  #   .i le selci'a poi selraptcidu cu raptcidu ro kravla poi zvati le selci'a zi'e noi ka'e sisti
  #       lo nu krasi
  #   .i zo su fanmo ro le kravla ta'i lo fanmo be le selci'a
  var
    # lo famvla poi fanmo no kravla pe le selci'a
    #   .i ro klesi cu ponse pa namcu
    strays: array[OPENERS.len, int]
    # lo klesi be ro kravla poi kalri ne'i le selci'a
    #   .i le kravla poi zvati ne'i ro drata cu romoi
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

  # lo famvla pe lo nu sitna
  #   .i zo le'u fanmo lo pamoi cmavo po'u zo lo'u poi denpa
  #   .i ki'u bo le cmavo cu sitna ro zo lo'u poi se lidne le cmavo
  #   .i lo koivla cu fanmo zo zoi pe vo'a
  #   .i ro le nu sitna cu sitna ro zo su poi lidne le famvla
  if occurrences.isClosingLohu:
    var n = 0
    while n < reader.openers.len and reader.openers[n].selmaho != Selmaho.Lohu: inc n
    if n < reader.openers.len: back = back.earlier(reader.reopening(reader.openers[n]))
  for n in 0 ..< reader.openers.len:
    template opener: untyped = reader.openers[n]
      ## lo datcme be le krasi valsi
      ##   .i `let` da'i fukpi le kravla
    if opener.selmaho != Selmaho.Zoi: continue
    let is_closing = opener.delimiter.len == 0 or
      reader.text.isSpelled(max(start, opener.after), region.reading.size, opener.delimiter)
    if is_closing: back = back.earlier(reader.reopening(opener))
  if j == 0: return back

  # zo si poi facki no valsi cu vimcu lo valsi pe lo jgena poi lidne le se tcidu
  #   .i le romoi cu pamoi se vimcu
  #   .i zo bu .a zo zei galfi lo romoi valsi pe lo jgena poi lidne le se tcidu va'o lo nu no valsi
  #       poi selra'e cu lidne le cmavo to `CLL 19.13` .e `CLL 19.16` toi
  var
    deficit = 0
    is_kept = false  # lo valsi poi selra'e cu lidne le pagbu
  for u in 0 ..< first:
    template unit: untyped = units[u]
      ## lo datcme be le pagbu
      ##   .i `let` da'i fukpi le pagbu
    if unit.is_read or unit.refusal == RefusalText.Selmaho: is_kept = true
    if unit.is_read or unit.refusal != RefusalText.Construct or unit.words.len != 1: continue
    template word: untyped = occurrences[unit.words[0]]
      ## lo datcme be lo valsi pe le pagbu
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
  #   .i le nu vimcu cu klama lo jgena poi vasru le sinxa .a lo krasi be lo selci'a pe zo sa to
  #       `CLL 19.13` toi
  for marker in region.markers:
    var k = j - 1
    while k > 0 and not reader.items[k].isWall and marker notin reader.items[k].kept: dec k
    back = back.earlier(reader.landing(k, j, start))

  # lo pamoi pagbu poi se tcidu cu krasi lo pagbu be le selci'a va'o po'o lo nu le pamoi pagbu cu
  #     krasi lo pagbu be le selci'a ba lo pagbu poi pu se tcidu to `isCutAt` toi
  #   .i ji'a lo nu sisti poi cmene lo pagbu poi se tcidu gi'e se lidne le jgena cu cmene le pamoi
  #       pagbu poi se tcidu vi
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



#[ ni'o ni'o ni'o lo cenba pe `NIF` ]#

func cut(reader: var ReaderLive, start: int): int =
  ## katna lo jgena .e lo kravla .e `NIF` bu'u lo pamoi jgena poi lo selci'a poi selkra `start`
  ##     vasru ke'a
  ##   .i ji'a jarco lo stuzi poi `NIF` selka'a bu'u ke'a
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
  ##   .i le romoi pagbu be le se tcidu be'o .e ro pagbu poi se lidne le romoi pagbu cu selbe'i ta'i
  ##       le rebla
  ##   .i ca lo fanmo ro jgena cu selbe'i
  ##   .i zo su fanmo lo selci'a poi lidne zo su
  ##   .i se ki'u bo ro jgena poi na se lidne zo su cu zi selbe'i
  ##   .i lo jgena poi se lidne zo su cpacu no da lo jgena poi lidne zo su
  ##   .i lo pagbu be le selci'a be'o poi vasru no pagbu zi'e noi lo selci'a poi vasru no pagbu poi
  ##       se tcidu cu jarco ke'a selbe'i va'o po'o lo nu no pagbu be lo selci'a pe vo'a cu pu
  ##       selbe'i kei ta'i lo nu le mulselci'a cu se tcidu
  ##   .i le pagbu cu zvati lo fanmo be le pamoi se ciska noi lidne lo pamoi cmavo po'u zo su
  template children: untyped = region.reading.tree.children
    ## lo datcme be lo jgena pe lo genja be le se tcidu
    ##   .i `let` da'i fukpi le jgena
  template units: untyped = region.reading.units
    ## lo datcme be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo datcme be lo valsi pe le se tcidu
    ##   .i `let` da'i fukpi le valsi
  var
    # lo pamoi pezli be zo su ne'i le panzi
    #   .i va'o lo nu no pezli be zo su zvati kei le namcu cu du lo klani be le panzi
    first_su = children.len
    # lo romoi pezli be zo su ne'i le panzi
    #   .i va'o lo nu no pezli be zo su zvati kei le namcu cu du li ni'u pa
    last_su = -1
    # lo pamoi pezli poi se lidne le selci'a
    #   .i ro le pezli cu du zo fa'o poi fanmo le selci'a .a lo valsi poi se lidne zo fa'o
    first_ended = children.len
  for k in 0 ..< children.len:
    if not children[k].is_terminal: continue
    if units[children[k].at].isSu: (first_su, last_su) = (min(first_su, k), k)
    if region.faho.isSome and children[k].at >= region.faho.get:
      first_ended = min(first_ended, k)
  let
    # lo panzi poi ka'e du lo pagbu be le selci'a be'o poi vasru no pagbu
    hollow = min(first_su, first_ended) - 1
    is_hollow = reader.items.len > 0 and reader.items[^1].is_parted and hollow >= 0 and
      not children[hollow].is_terminal and leaves[hollow].len == 0
  var order: seq[int]  # lo porsi be lo panzi poi zi selbe'i gi'a selbe'i ta'i le rebla
  for k in 0 ..< children.len:
    if not is_hollow or k != hollow: order.add k
  var count = order.len  # lo panzi poi cmima `order` gi'e ca selbe'i
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
        ## lo datcme be le pagbu
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
  ## jmina ro kravla poi denpa lo famvla pe ke'a gi'e zvati le selci'a poi selkra `start` ku'o ku'o
  ##     ta'i lo porsi be lo stuzi
  ##   .i ro le kravla cu du zo tu'e .a zo lu .a zo to .a zo lo'u .a zo zoi
  ##   .i zo tu'e .e zo lu .e zo to stali lo ka kalri
  ##   .i zo lo'u zvati pa pagbu poi vasru zo lo'u po'o
  ##   .i no koivla cu fanmo zo zoi
  ##   .i va'o lo nu lo nu vimcu cu vimcu lo valsi poi lidne lo kravla pe lo nu sitna kei kei le
  ##       kravla cu rapkra bu'u `start`
  ##   .i lo famvla pe le kravla cu tcidu le selci'a bu'u `start`
  ##   .i ki'u bo le famvla cu ka'e sitna lo valsi poi vimcu le valsi gi'a galfi lo sinxa be zo sa
  ##       poi lidne le kravla
  func ownerAt(region: ReadingParts, owners: openArray[int], at: int): Option[int] =
    ## jarco lo stuzi poi lo panzi goi ko'a krasi bu'u ke'a
    ##   .i ko'a vasru lo pagbu poi vasru lo valsi poi krasi bu'u `at`
    ##   .i va'o lo nu no pagbu cu vasru lo valsi poi krasi bu'u `at` kei jarco no stuzi
    for u in 0 ..< region.reading.units.len:
      for w in region.reading.units[u].words:
        if region.reading.occurrences[w].start == at: return some(owners[u])
    none(int)

  template units: untyped = region.reading.units
    ## lo datcme be lo pagbu pe le se tcidu
    ##   .i `let` da'i fukpi le pagbu
  template occurrences: untyped = region.reading.occurrences
    ## lo datcme be lo valsi pe le se tcidu
    ##   .i `let` da'i fukpi le valsi
  var
    # ro pagbu cu ponse lo stuzi poi lo selku'e be lo panzi poi vasru le pagbu cu krasi bu'u ke'a
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
      ## lo datcme be le valsi
      ##   .i `let` da'i fukpi le valsi
    if not word.reading.is_word or (holders[w] >= 0 and not units[holders[w]].isErasure): continue
    let
      selmaho = word.reading.selmaho
      is_erasing = selmaho.isSome and selmaho.get in {Selmaho.Si, Selmaho.Sa, Selmaho.Su}
    if not is_erasing:
      erased_first = word.start
      break
  template opening(at: int, owner: Option[int]): int =
    ## jarco lo stuzi poi lo nu tcidu cu rapcfa bu'u ke'a ca lo nu lo famvla pe lo kravla pe lo nu
    ##     sitna poi krasi bu'u `at` se tcidu
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

  # pa zo zoi goi ko'a zvati ne'i lo valsi poi zo lo'u sitna ke'a
  #   .i le porsi be lo valsi na tcidu ko'a ta'i lo kravla pe lo nu sitna
  #   .i ko'a sitna le ci valsi poi se lidne ko'a ca lo nu le ci valsi cu klama to `toRoles` pe
  #       `prose.nim` toi
  #   .i se ki'u bo ko'a denpa
  #   .i ko'a sepli gi'a selvi'u
  for w in 0 ..< occurrences.len:
    template word: untyped = occurrences[w]
      ## lo datcme be le valsi
      ##   .i `let` da'i fukpi le valsi
    if not word.reading.is_word or word.reading.selmaho != some(Selmaho.Zoi): continue
    var
      # le re valsi poi le porsi be lo valsi cu tcidu ke'a zi'e poi se lidne zo zoi
      #   .i le pamoi cu koivla
      #   .i le remoi cu se sitna va'o lo nu zasti
      reads: seq[int]
      next = w + 1
    while next < occurrences.len and reads.len < 2:
      template after: untyped = occurrences[next].reading
        ## lo datcme be lo nu tcidu lo bavla'i valsi
        ##   .i `let` da'i fukpi le nu tcidu
      if after.is_word or after.refusal == Refusal.Foreign: reads.add next
      inc next
    let
      is_quoting = reads.len == 2 and not occurrences[reads[1]].reading.is_word
      u = holders[w]
      is_erased = u < 0 or units[u].isErasure
      is_whole = not is_erased and (not units[u].is_read or units[u].words.countIt(it > w) >= 3)
    # le porsi be lo valsi cu sitna le selci'a
    #   .i ja le pagbu cu vasru le ci valsi pe zo zoi
    if is_quoting or is_whole: continue
    added.add OpenerLive(
      selmaho: Selmaho.Zoi, at: word.start,
      start: opening(word.start, if is_erased: none(int) else: some(owners[u])),
    )
  reader.openers.add added.sortedByIt(it.start)


func addRest(reader: var ReaderLive, first: int): ChangeNif =
  ## benji ro selci'avla pe le selci'a poi selkra `first` ku'o ta'i pa pagbu poi vasru le se ciska
  ##     valsi po'o
  ##   .i le selci'a cu fanmo bu'u lo fanmo be le se tcidu gi'e se lidne zo fa'o poi fanmo lo
  ##       selci'a
  ##   .i le porsi be lo valsi na tcidu le se ciska valsi to `CLL 19.15` toi
  ##   .i no selci'a poi lidne le selci'a cu selraptcidu
  ##   .i ki'u bo ro jgena poi lidne zo fa'o cu pu selbe'i ca lo nu pu se tcidu
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
  ## tcidu lo selci'a poi selkra `at`
  ##   .i ji'a tcidu ro pu selci'a poi le selci'a cu klama ke'a
  ##   .i jarco lo cenba pe `NIF`
  ##   .i le cenba cu vasru lo jgena pe ro pagbu be le selci'a poi selkra lo pamoi jgena poi
  ##       selraptcidu ku'o ku'o ta'i lo nu ro le jgena cu selbe'i
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
  #   .i lo fanmo be le selci'a cu raptcidu bu'u lo selku'e be le panzi
  var k = 0
  while k < spans.high:
    template child: untyped = region.reading.tree.children[k]
      ## lo datcme be lo panzi be le genja
      ##   .i `let` da'i fukpi le panzi
    if child.is_terminal and child.at == region.faho.get: break
    inc k
  reader.start = min(reader.start, spans[k])  # lo fanmo be le selci'a cu raptcidu zo fa'o



#[ ni'o ni'o ni'o lo jmive se ciska ]#

func push*(reader: var ReaderLive, piece: string): ChangeNif =
  ## tcidu lo bavla'i spisa be lo mivyselci'a gi'e jarco lo cenba poi le spisa cu rinka ke'a ne'i
  ##     `NIF`
  ##   .i le cenba cu vasru lo jgena poi selbe'i .e lo rebla pe le pagbu poi ca'o kalri
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
      ## lo datcme be le krasi valsi
      ##   .i `let` da'i fukpi le kravla
    if reader.stop.isNone: break
    let is_closing = opener.selmaho == Selmaho.Zoi and opener.at < reader.stop.get and
      reader.text.isSpelled(max(reader.ending, opener.after), ending, opener.delimiter)
    if is_closing: reader.stop = none(int)  # zo zoi poi lidne zo fa'o sitna ri ca lo nu selfa'o
  let first = reader.ending  # lo selci'a poi na pu se tcidu
  reader.ending = ending
  if reader.stop.isSome: return reader.addRest(first)
  reader.readChange(reader.start, is_final = false)


func finish*(reader: var ReaderLive): ChangeNif =
  ## tcidu lo fanmo be lo mivyselci'a
  ##   .i lo selci'a poi selkra lo pamoi krasi valsi poi ca'o denpa cu se tcidu ta'i lo nu le
  ##       mulselci'a cu se tcidu
  ##   .i ro jgena poi stali cu selbe'i
  ##   .i se ki'u bo `NIF` vasru lo jgena pe ro pagbu be le selci'a
  doAssert not reader.is_ended, "Live text should end once."
  reader.is_ended = true
  var start = reader.start
  for n in 0 ..< reader.openers.len: start = min(start, reader.openers[n].start)
  reader.readChange(start, is_final = true)



#[ ni'o ni'o ni'o lo nu carna ]#

func toSentences*(piece: string): seq[string] =
  ## katna lo spisa pu ro cmavo be zoi gy. I .gy. .a zoi gy. NIhO .gy. ta'i lo nu le porsi be lo
  ##     valsi cu tcidu le spisa po'o
  ##   .i le cmavo cu krasi lo jufra .a lo ju'agri
  ##   .i le spisa cu jalge lo nu jmina ro le selka'a
  ##   .i se ki'u bo le samtci cu tcidu pa jufra ca ro nu `event loop` carna kei va'o lo nu le papri
  ##       cu dunda no gunka to `Architect` jdice di'u bu'u `#859` toi
  ##   .i va'o lo nu le porsi be lo valsi cu to'e curmi le spisa kei le porsi cu katna le spisa ne'i
  ##       lo valsi po'o poi lidne le nu to'e curmi
  ##   .i le nu katna cu galfi no pagbu be `NIF`
  ##   .i lo selci'a poi ro spisa be ke'a cu se tcidu ta'i lo porsi cu jarco `NIF` pe lo pagbu be le
  ##       selci'a va'o ro nu le spisa cu katna le se ciska to lo flalu pe `test_live.nim` toi
  var reading = piece.readStream
  # lo valsi poi lidne le nu to'e curmi
  if not reading.is_read: reading = piece[0 ..< reading.start].readStream
  var last = 0
  if reading.is_read:
    for n in 0 ..< reading.occurrences.len:
      template occurrence: untyped = reading.occurrences[n]
        ## lo datcme be le valsi
        ##   .i `let` da'i fukpi le valsi va'o lo nu fanva fi `JavaScript`
      let is_opener = occurrence.reading.is_word and occurrence.reading.selmaho.isSome and
        occurrence.reading.selmaho.get in {Selmaho.I, Selmaho.Niho}
      if is_opener and occurrence.start > last:
        result.add piece[last ..< occurrence.start]
        last = occurrence.start
  result.add piece[last .. ^1]


func combine*(changes: openArray[ChangeNif], nif: string): ChangeNif =
  ## jmina lo cenba poi lo spisa poi se tcidu ta'i lo porsi cu rinka ke'a ku'o fo pa cenba pe ro le
  ##     spisa
  ##   .i le jalge cu krasi bu'u lo stuzi pe `NIF` ge'u .e lo stuzi pe le selci'a
  ##   .i ro le re stuzi cu du lo mecraistu poi su'o le cenba cu krasi bu'u ke'a
  ##   .i ji'a le jalge cu ponse `NIF` poi selkra le stuzi pe `NIF` ku'o ta'i lo nu `nif` vasru le
  ##       selci'a ba le romoi cenba
  ##   .i ji'a le jalge cu ponse le rebla pe le romoi cenba
  ##   .i ro cenba cu ralte `NIF` poi lidne lo stuzi pe le cenba
  ##   .i se ki'u bo `NIF` poi lidne le mecraistu cu stali ta'i lo nu zasti pu le pamoi cenba
  ##   .i ro valsi poi pa cenba cu ralte ke'a fanmo bu'u lo stuzi poi na se lidne le stuzi pe le
  ##       cenba
  ##   .i ro valsi poi le cenba cu jarco ke'a krasi bu'u lo stuzi poi na lidne le stuzi pe le cenba
  ##   .i se ki'u bo le jalge cu jorne le selci'a le mecraistu ta'i lo nu ro cenba cu jorne le
  ##       selci'a lo stuzi pe vo'a
  doAssert changes.len > 0, "Changes should be one or more; got none."
  result = ChangeNif(at: changes[0].at, start: changes[0].start, tail: changes[^1].tail)
  for k in 1 ..< changes.len:
    result.at = min(result.at, changes[k].at)
    result.start = min(result.start, changes[k].start)
  result.text = nif[result.at .. ^1]
