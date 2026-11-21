## dunda lo selci'a be fi `NIF` be'o poi lo selci'a be fi `NIF` be'o pe ro se tcidu cu se tcidu ta'i
##     ke'a
##   .i ji'a rapyzba lo tricu le selci'a
##   .i se ki'u bo lo flalu pe le cipra cu tcidu lo selci'a be le ciska
##   .i le tcidu pe le velski cu du `nif_read.nim` pe le bakfu
##   .i lo papri cu tcidu `NIF` sepi'o `nif_read.nim` ji'a
##
## ni'o le selci'a be fi `NIF` be'o poi le vi datnyvei cu dunda ke'a morna lo tarmi poi `nif.nim`
##     skicu ke'a ne'i lo krapinka pe vo'a
##   .i le morna cu selkra lo minde gi'e vasru ji'a ro porsi be lo javni .e ro genvla
##   .i ro porsi cu selci'a ta'i lo tcita be lo javni poi fanmo le porsi be'o .e lo namcu pe lo
##       javni poi krasi le porsi
##   .i ro genvla cu selci'a ta'i lo klesi pe vo'a ge'u .e lo stuzi .e lo lerfu pe ro valsi
##   .i va'o lo nu le se tcidu cu sinxa ro srera kei le morna cu vasru ji'a lo srejge .e lo pagbu
##       poi no genvla cu vasru ke'a
##
## ni'o le ciska cu dunda lo selci'a
##   .i le morna cu dunda lo jgena
##   .i se ki'u bo no le re fancu cu cipra fi vo'a
##
## ni'o lo nu rapyzba cu tcidu le selci'a gi'e rapyzba lo tricu .e lo gerna valsi to `toTree` pe
##     `merge.nim` toi
##   .i lo nu jmina lo pagbu cu tcidu `NIF` sepi'o `toTree` ji'a
##   .i le nu rapyzba cu cpacu lo namcu pe ro javni lo cmene be le javni gi'e cpacu ro javni poi
##       zvati lo jbini be le re fanmo be lo porsi ku'o `LUT_CHAIN_BY_ENDS`
##   .i `-` basti ro `_` pe lo tcita
##   .i `'` basti ro `h` pe lo valsi
##   .i se ki'u bo le flalu cu cipra lo du'u le tarmi cu cirko no pagbu be le tricu
##   .i le flalu na cipra lo du'u le ciska cu tugni le morna kei po'o
##
## ni'o le flalu pe le gacri to `isCovering` toi cu cipra lo du'u le tricu cu mapti lo stuzi pe le
##     selci'a
##   .i ro stuzi pe ro valsi cu zvati pa pezli
##   .i lo porsi be lo pezli cu mintu lo porsi be le selci'a
##   .i ro datstu cu du lo sinxa poi zvati lo jbini be lo valsi
##   .i lo cipra pe lo sinxa .e lo cipra pe lo mivyselci'a cu tcidu le flalu
##
## ni'o lo jbecipra .e lo cipra pe `JavaScript` tcidu le mitytcidu .e le mitmo'a .e le mitmupli
##   .i se ki'u bo ro le ci pagbu cu selci'a pa roi to `Article II.9` toi

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, tables]

import ../../src/ricysoho/[grammar, merge, nif, nif_read, prose, selmaho, stream, tanru]

export merge, nif_read


const
  SIGNS_CURRENCY = ["€", "$", "£", "¢", "¥"]
    ## lo jdini sinxa poi le genturfa'i cu tcidu ke'a to `D1 a` pe `#1003` toi
    ##   .i ro stuzi pe le sinxa cu zvati no valsi
  TAG_ERROR = "srera"
    ## lo tcita be lo srejge
    ##   .i le tcita cu gismu ja'i lo seljdi pe `#859`
    ##   .i le morna cu dunda le tcita
  TAG_EXPECTS = "nitcu"
    ## lo tcita be lo genvla poi le gerna cu tcidu ke'a bu'u lo stuzi poi le gerna cu sisti bu'u
    ##     ke'a
    ##   .i le morna cu dunda le tcita
  TAG_UNREAD = "rivbi"
    ## lo tcita be lo pagbu poi no genvla cu vasru ke'a
    ##   .i le morna cu dunda le tcita
  EXAMPLE_NIF* = (
    text: "me'o vo",  # lo mupli po'u `CLL 6.98` pe `CLL 1.1`
    module: "(.nif27)\n(.lang \"cll-21.1\")\n" &
      "(sumti_6 0 (LI 0 4 \"meho\") (number 310 (PA 5 7 \"vo\")))\n",
  )
    ## lo selci'a .e lo selci'a be fi `NIF` be'o poi ro lerfu pe ke'a mintu lo selci'a be `nif.nim`
    ##   .i lo porsi poi selkra `text<0>` gi'e selfa'o `sumti-6<97>` du pa jgena
    ##   .i lo porsi poi selkra `mex<310>` gi'e selfa'o `number<812>` go'i ji'a
    ##   .i lo tcita be `sumti-6` cu pilno `_`
    ##   .i lo valsi po'u zo me'o pilno `h`



#[ ni'o ni'o ni'o lo morna ]#

func letters(occurrence: Occurrence): string =
  ## dunda lo lerfu poi lo lerpoi pe lo selci'avla cu vasru ke'a
  ##   .i va'o lo nu le selci'avla cu valsi kei `h` basti ro `'`
  ##   .i lo selci'a poi lo nu sitna cu vasru ke'a ku'o .e lo selci'avla poi le porsi be lo valsi cu
  ##       to'e curmi ke'a stali
  if occurrence.reading.is_word: occurrence.text.replace('\'', 'h') else: occurrence.text


func spelled(stage: RefusalText): string =
  ## dunda lo tcita poi lo velru'e cu se tcidu ta'i ke'a
  ##   .i lo cmene be lo selma'o cu mintu lo cmene poi `CLL 20` dunda ke'a
  ##   .i lo jbovla cu selci'a ta'i lo cmale'u
  ##   .i lo glivla pe `CLL` stali to lo seljdi pe `#859` toi
  case stage
  of RefusalText.Su: "SU"
  of RefusalText.Faho: "FAhO"
  of RefusalText.Selmaho: "selmaho"
  else: $stage


func spelled(refusal: Refusal): string =
  ## dunda lo tcita poi lo nu to'e curmi pe lo porsi be lo valsi cu se tcidu ta'i ke'a
  ##   .i le tcita cu selci'a ta'i lo tcita be lo velru'e
  case refusal
  of Refusal.Faho: "FAhO"
  of Refusal.Slinkuhi: "slinkuhi"
  else: $refusal


func byteStop(reading: ReadingMarked, at: int): int =
  ## dunda lo stuzi poi le gerna cu sisti bu'u ke'a sepi'o le pagbu poi `at` sinxa ke'a
  ##   .i le stuzi cu du lo stuzi poi le pagbu cu krasi bu'u ke'a
  ##   .i va'o lo nu `at` zvati lo fanmo kei le stuzi cu du lo ni le selci'a cu barda
  if at < reading.units.len: reading.occurrences[reading.units[at].words[0]].start
  else: reading.size


func toNodeNif(node: Node, top: int, reading: ReadingText | ReadingMarked): NodeNif =
  ## dunda lo jgena pe `NIF` poi lo jgena pe lo tricu cu se tcidu ta'i ke'a
  ##   .i va'o lo nu lo javni cu vasru pa javni po'o kei le fancu cu dunda le selvau ta'i lo pagbu
  ##       be lo porsi poi krasi bu'u `top`
  ##   .i lo javni poi fanmo lo porsi cu dunda lo tcita pe vo'a ge'u ce'o `top` ce'o lo jgena pe
  ##       vo'a
  ##   .i va'o lo nu le porsi cu selkra le javni poi fanmo le porsi kei `top` na seldu'a
  ##   .i lo genvla cu dunda lo klesi ce'o lo stuzi .e bo lo lerfu pe ro valsi
  ##
  ## ni'o lo srejge cu dunda `srera` ce'o lo stuzi poi le gerna cu sisti bu'u ke'a ku'o ce'o lo
  ##     cmene be lo javni be'o ce'o `nitcu` joi bo lo klesi ce'o lo jgena pe vo'a gi'e fanmo lo
  ##     porsi poi gapru le srejge
  ##   .i lo pagbu poi no genvla cu vasru ke'a dunda `rivbi` ce'o lo velru'e ce'o lo valsi pe vo'a
  ##   .i le velru'e po'u `Stream` se lidne lo nu to'e curmi pe lo porsi be lo valsi
  if node.is_terminal:
    template unit: untyped = reading.units[node.at]
      ## datcme lo pagbu pe le genvla
      ##   .i `let` zbasu lo fukpi be le pagbu va'o lo nu fanva fi `JavaScript`
    result = NodeNif(
      kind: KindNif.Compound, text: (if unit.is_read: $unit.terminal else: TAG_UNREAD)
    )
    if not unit.is_read:
      result.children.add NodeNif(kind: KindNif.Identifier, text: unit.refusal.spelled)
      if unit.refusal == RefusalText.Stream:
        let refusal = reading.occurrences[unit.words[0]].reading.refusal.spelled
        result.children.add NodeNif(kind: KindNif.Identifier, text: refusal)
    for k in 0 ..< unit.words.len:
      template word: untyped = reading.occurrences[unit.words[k]]
        ## datcme lo valsi pe le pagbu
        ##   .i `let` zbasu lo fukpi be le valsi va'o lo nu fanva fi `JavaScript`
      result.children.add NodeNif(kind: KindNif.Number, number: word.start)
      result.children.add NodeNif(kind: KindNif.Number, number: word.finish)
      result.children.add NodeNif(kind: KindNif.Literal, text: word.letters)
    return
  let is_chain = node.stop.isNone and node.children.len == 1 and
    not node.children[0].is_terminal and node.children[0].stop.isNone
  if is_chain: return node.children[0].toNodeNif(top, reading)
  let tag = node.rule.replace('-', '_')
  if node.stop.isSome:
    when reading is ReadingMarked:
      result = NodeNif(kind: KindNif.Compound, text: TAG_ERROR)
      result.children.add NodeNif(
        kind: KindNif.Number, number: reading.byteStop(node.stop.get.at)
      )
      result.children.add NodeNif(kind: KindNif.Identifier, text: tag)
      var expects = NodeNif(kind: KindNif.Compound, text: TAG_EXPECTS)
      for terminal in node.stop.get.expected:
        expects.children.add NodeNif(kind: KindNif.Identifier, text: $terminal)
      result.children.add expects
    else:
      doAssert false, "Reading that reads should hold no error node."
  else:
    result = NodeNif(kind: KindNif.Compound, text: tag)
    if top != node.number: result.children.add NodeNif(kind: KindNif.Number, number: top)
  for k in 0 ..< node.children.len:
    let top_child = (if node.children[k].is_terminal: 0 else: node.children[k].number)
    result.children.add node.children[k].toNodeNif(top_child, reading)


func toModule*(reading: ReadingText | ReadingMarked): seq[NodeNif] =
  ## dunda lo selci'a poi lo selci'a be fi `NIF` be'o pe lo se tcidu cu se tcidu ta'i ke'a
  ##   .i lo namcu pe le tarmi cu krasi le selci'a
  ##   .i lo bangu cu se lidne le namcu
  ##   .i le tricu cu se lidne le bangu
  @[
    NodeNif(kind: KindNif.Compound, text: ".nif27"),
    NodeNif(
      kind: KindNif.Compound, text: ".lang",
      children: @[NodeNif(kind: KindNif.Literal, text: "cll-21.1")],
    ),
    reading.tree.toNodeNif(reading.tree.number, reading),
  ]



#[ ni'o ni'o ni'o lo nu rapli zbasu ]#

func toTerminals(reading: ReadingText | ReadingMarked): seq[TerminalNif] =
  ## dunda lo genvla poi lo se tcidu cu vasru ke'a
  ##   .i lo klesi cu lidne lo stuzi .e lo lerfu pe ro valsi
  ##   .i lo pagbu poi no genvla cu vasru ke'a dunda `rivbi` ce'o lo velru'e
  ##   .i le velru'e po'u `Stream` se lidne lo nu to'e curmi pe lo porsi be lo valsi
  for k in 0 ..< reading.units.len:
    template unit: untyped = reading.units[k]
      ## datcme le pagbu
      ##   .i `let` zbasu lo fukpi be le pagbu va'o lo nu fanva fi `JavaScript`
    var
      terminal = (if unit.is_read: $unit.terminal else: TAG_UNREAD & " " & unit.refusal.spelled)
      words: seq[WordNif]
    if not unit.is_read and unit.refusal == RefusalText.Stream:
      terminal.add " " & reading.occurrences[unit.words[0]].reading.refusal.spelled
    for m in 0 ..< unit.words.len:
      template word: untyped = reading.occurrences[unit.words[m]]
        ## datcme lo valsi pe le pagbu
        ##   .i `let` zbasu lo fukpi be le valsi va'o lo nu fanva fi `JavaScript`
      words.add (word.start, word.finish, word.text)
    result.add (terminal: terminal, words: words)


func isSame(a, b: Node, reading: ReadingText | ReadingMarked): bool =
  ## jdice lo du'u lo tricu po'u `a` pe lo se tcidu .e lo tricu po'u `b` poi selrapyzba cu vasru lo
  ##     mi'ujva .e lo mitna'u .e lo mitygenvla ta'i lo mitpoi
  ##   .i ji'a jdice lo du'u le re tricu cu vasru lo mitstu poi le gerna cu sisti bu'u ke'a
  ##   .i `b` vasru le stuzi ta'i lo stuzi pe le selci'a
  if a.is_terminal != b.is_terminal: return false
  if a.is_terminal: return a.at == b.at
  if a.rule != b.rule or a.number != b.number or a.children.len != b.children.len: return false
  if a.stop.isSome != b.stop.isSome: return false
  if a.stop.isSome:
    when reading is ReadingMarked:
      if reading.byteStop(a.stop.get.at) != b.stop.get.at: return false
      if a.stop.get.expected.mapIt(int(it)) != b.stop.get.expected.mapIt(int(it)): return false
    else: return false
  for k in 0 ..< a.children.len:
    if not a.children[k].isSame(b.children[k], reading): return false
  true


func addLeaves(node: Node, leaves: var seq[int]) =
  ## jmina lo namcu pe ro pezli poi le jgena cu vasru ke'a ku'o `leaves` ta'i lo porsi pe le tricu
  if node.is_terminal:
    leaves.add node.at
    return
  for k in 0 ..< node.children.len: node.children[k].addLeaves(leaves)


func isCovering*(marked: ReadingMarked, text: string): bool =
  ## jdice lo du'u ro stuzi pe ro valsi pe le selci'a cu zvati pa pezli pe le tricu
  ##   .i ji'a jdice lo du'u lo porsi be lo pezli cu mintu lo porsi be le selci'a ja'i lo pamoi
  ##       stuzi pe ro pezli
  ##   .i ji'a jdice lo du'u ro stuzi poi no pezli cu vasru ke'a du lo sinxa poi zvati lo jbini be
  ##       lo valsi .a lo lerfu po'u slaka bu poi zvati lo jbini be re valsi pe pa se ciska valsi to
  ##       `CLL 3.3` toi
  ##
  ## ni'o lo pezli poi vasru no stuzi cu sinxa lo valsi poi lo jdini sinxa cu sinxa ke'a
  ##   .i se ki'u bo le pamoi stuzi pe le pezli poi se lidne cu ka'e mintu le pamoi stuzi pe le
  ##       pezli
  ##   .i ji'a ro stuzi pe lo jdini sinxa pe `SIGNS_CURRENCY` poi pencu lo namcu cu ka'e zvati no
  ##       pezli
  var
    counts = newSeq[int](text.len)  # lo klani be lo pezli poi vasru lo stuzi
    last = -1  # lo pamoi stuzi pe lo pezli poi lidne
    is_last_empty = false  # lo du'u xu kau le pezli poi lidne cu vasru no stuzi
    leaves: seq[int]
  marked.tree.addLeaves(leaves)
  for u in leaves:
    template unit: untyped = marked.units[u]
      ## datcme le pagbu
      ##   .i `let` zbasu lo fukpi be le pagbu
    let
      first = marked.occurrences[unit.words[0]].start
      is_empty =
        unit.words.allIt(marked.occurrences[it].start == marked.occurrences[it].finish)
    if first < last or (first == last and not is_last_empty): return false
    (last, is_last_empty) = (first, is_empty)
    for w in unit.words:
      template word: untyped = marked.occurrences[w]
        ## datcme le valsi
        ##   .i `let` zbasu lo fukpi be le valsi
      if word.start > word.finish or word.finish > text.len: return false  # lo kutselsitna
      for b in word.start ..< word.finish: inc counts[b]
  var b = 0
  while b < text.len:
    if counts[b] > 1: return false
    if counts[b] == 0 and text[b] notin MARKS_BOUNDARY and text[b] != ',':
      # lo jdini sinxa poi pencu lo namcu cu zvati no pezli
      let signs = SIGNS_CURRENCY.filterIt(text.continuesWith(it, b))
      if signs.len == 0: return false
      let
        is_after = b > 0 and text[b - 1] in Digits
        is_before = b + signs[0].len < text.len and text[b + signs[0].len] in Digits
      if not is_after and not is_before: return false
      for s in b ..< b + signs[0].len:
        if counts[s] != 0: return false
      b += signs[0].len
      continue
    inc b
  true


func isReadBack*(reading: ReadingText | ReadingMarked): bool =
  ## jdice lo du'u lo selci'a be fi `NIF` be'o pe lo se tcidu cu mapti lo seldu'a be le morna be le
  ##     tarmi
  ##   .i ji'a jdice lo du'u lo nu tcidu le selci'a cu rapyzba le multricu .e ro genvla pe le se
  ##       tcidu
  ##   .i ro le re cipra cu cipra le vi flalu
  var module: seq[NodeNif]
  try: module = reading.toNif.readModule
  except ValueError: return false
  if module != reading.toModule: return false
  var terminals: seq[TerminalNif]
  let tree = module[^1].toTree(terminals)
  reading.tree.isSame(tree, reading) and terminals == reading.toTerminals
