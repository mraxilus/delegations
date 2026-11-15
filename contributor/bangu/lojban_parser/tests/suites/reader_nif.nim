## dunda lo se ciska be fi la'o gy. NIF .gy. be'o poi lo se ciska be fi la'o gy. NIF .gy. be'o pe ro
##   se tcidu cu se tcidu ta'i ke'a
##   .i ji'a rapli zbasu lo tricu le se ciska
##   .i se ki'u bo lo flalu pe le cipra cu tcidu lo se ciska be le ciska
##   .i le tcidu pe le ve skicu cu du `nif_read.nim` pe le bakfu
##   .i lo papri cu tcidu la'o gy. NIF .gy. sepi'o `nif_read.nim` ji'a
##   .i le se ciska be fi la'o gy. NIF .gy. be'o poi le vi datnyvei cu dunda ke'a cu morna lo tarmi
##     poi `nif.nim` cu skicu ke'a ne'i lo krasi pinka pe vo'a
##   .i lo minde cu krasi le morna
##   .i le morna cu vasru ji'a ro porsi be lo javni .e ro gerna valsi
##   .i ro porsi cu se ciska ta'i lo tcita be lo javni poi fanmo le porsi ku'o be'o .e lo namcu pe
##     lo javni poi krasi le porsi
##   .i ro gerna valsi cu se ciska ta'i lo klesi pe vo'a ge'u .e lo stuzi .e lo lerfu pe ro valsi
##   .i va'o lo nu le se tcidu cu sinxa ro srera kei le morna cu vasru ji'a lo srera jgena .e lo
##     pagbu poi no gerna valsi cu vasru ke'a
##   .i le ciska cu dunda lo se ciska
##   .i le morna cu dunda lo jgena
##   .i se ki'u bo no le re fancu cu cipra fi vo'a
##   .i lo nu rapli zbasu cu tcidu le se ciska gi'e rapli zbasu lo tricu .e lo gerna valsi to
##     `toTree` pe `merge.nim` toi
##   .i lo nu jmina lo pagbu cu tcidu la'o gy. NIF .gy. sepi'o `toTree` ji'a
##   .i le nu rapli zbasu cu cpacu lo namcu pe ro javni lo cmene be le javni
##   .i le nu rapli zbasu cu cpacu ro javni poi zvati lo jbini be le re fanmo be lo porsi ku'o
##     `LUT_CHAIN_BY_ENDS`
##   .i `-` cu basti ro `_` pe lo tcita
##   .i `'` cu basti ro `h` pe lo valsi
##   .i se ki'u bo le flalu cu cipra lo du'u le tarmi cu cirko no pagbu be le tricu
##   .i le flalu na cipra lo du'u le ciska cu tugni le morna kei po'o
##   .i le flalu pe le gacri to `isCovering` toi cu cipra lo du'u le tricu cu mapti lo stuzi pe le
##     se ciska
##   .i ro stuzi pe ro valsi cu zvati pa pezli
##   .i lo porsi be lo pezli cu mintu lo porsi be le se ciska
##   .i ro drata stuzi cu du lo sinxa poi zvati lo jbini be lo valsi
##   .i lo cipra pe lo sinxa .e lo cipra pe lo jmive se ciska cu tcidu le flalu
##   .i lo jbena cipra .e lo cipra pe la'o gy. JavaScript .gy. cu tcidu le mintu tcidu .e le mintu
##     morna .e le mintu mupli
##   .i se ki'u bo ro le ci pagbu cu se ciska pa roi to `Article II.9` toi

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, tables]

import ../../src/lojban_parser/[grammar, merge, nif, nif_read, prose, selmaho, stream, tanru]

export merge, nif_read


const
  TAG_ERROR = "srera"
    ## lo tcita be lo srera jgena
    ##   .i le tcita cu gismu ja'i lo se jdice pe `#859`
    ##   .i le morna cu dunda le tcita
  TAG_EXPECTS = "nitcu"
    ## lo tcita be lo gerna valsi poi le gerna cu tcidu ke'a bu'u lo stuzi poi le gerna cu sisti
    ##   bu'u ke'a
    ##   .i le morna cu dunda le tcita
  TAG_UNREAD = "rivbi"
    ## lo tcita be lo pagbu poi no gerna valsi cu vasru ke'a
    ##   .i le morna cu dunda le tcita
  EXAMPLE_NIF* = (
    text: "me'o vo",  # lo mupli po'u `CLL 6.98` pe la'o gy. CLL 1.1 .gy.
    module: "(.nif27)\n(.lang \"cll-21.1\")\n" &
      "(sumti_6 0 (LI 0 4 \"meho\") (number 310 (PA 5 7 \"vo\")))\n",
  )
    ## lo se ciska .e lo se ciska be fi la'o gy. NIF .gy. be'o poi ro lerfu pe ke'a cu mintu lo se
    ##   ciska be `nif.nim`
    ##   .i lo porsi poi se krasi `text<0>` gi'e se fanmo `sumti-6<97>` cu du pa jgena
    ##   .i lo porsi poi se krasi `mex<310>` gi'e se fanmo `number<812>` cu go'i ji'a
    ##   .i lo tcita be `sumti-6` cu pilno `_`
    ##   .i lo valsi po'u zo me'o cu pilno `h`



#[ ni'o ni'o ni'o lo morna ]#

func letters(occurrence: Occurrence): string =
  ## dunda lo lerfu poi lo lerpoi pe lo se ciska valsi cu vasru ke'a
  ##   .i va'o lo nu le se ciska valsi cu valsi kei `h` cu basti ro `'`
  ##   .i lo se ciska poi lo nu sitna cu vasru ke'a ku'o .e lo se ciska valsi poi le porsi be lo
  ##     valsi cu to'e curmi ke'a cu stali
  if occurrence.reading.is_word: occurrence.text.replace('\'', 'h') else: occurrence.text


func spelled(stage: RefusalText): string =
  ## dunda lo tcita poi lo ve pruce cu se tcidu ta'i ke'a
  ##   .i lo cmene be lo selma'o cu mintu lo cmene poi `CLL 20` cu dunda ke'a
  ##   .i lo lojbo valsi cu se ciska ta'i lo cmalu lerfu
  ##   .i lo glico valsi pe la'o gy. CLL .gy. cu stali to lo se jdice pe `#859` toi
  case stage
  of RefusalText.Su: "SU"
  of RefusalText.Faho: "FAhO"
  of RefusalText.Selmaho: "selmaho"
  else: $stage


func spelled(refusal: Refusal): string =
  ## dunda lo tcita poi lo nu to'e curmi pe lo porsi be lo valsi cu se tcidu ta'i ke'a
  ##   .i le tcita cu se ciska ta'i lo tcita be lo ve pruce
  case refusal
  of Refusal.Faho: "FAhO"
  of Refusal.Slinkuhi: "slinkuhi"
  else: $refusal


func byteStop(reading: ReadingMarked, at: int): int =
  ## dunda lo stuzi poi le gerna cu sisti bu'u ke'a sepi'o le pagbu poi `at` cu sinxa ke'a
  ##   .i le stuzi cu du lo stuzi poi le pagbu cu krasi bu'u ke'a
  ##   .i va'o lo nu `at` cu zvati lo fanmo kei le stuzi cu du lo ni le se ciska cu barda
  if at < reading.units.len: reading.occurrences[reading.units[at].words[0]].start
  else: reading.size


func toNodeNif(node: Node, top: int, reading: ReadingText | ReadingMarked): NodeNif =
  ## dunda lo jgena pe la'o gy. NIF .gy. poi lo jgena pe lo tricu cu se tcidu ta'i ke'a
  ##   .i va'o lo nu lo javni cu vasru pa javni po'o kei le fancu cu dunda le se vasru ta'i lo pagbu
  ##     be lo porsi poi krasi bu'u `top`
  ##   .i lo javni poi fanmo lo porsi cu dunda lo tcita pe vo'a ge'u ce'o `top` ce'o lo jgena pe
  ##     vo'a
  ##   .i va'o lo nu le porsi cu se krasi le javni poi fanmo le porsi kei `top` na se dunda
  ##   .i lo gerna valsi cu dunda lo klesi ce'o lo stuzi .e bo lo lerfu pe ro valsi
  ##   .i lo srera jgena cu dunda `srera` ce'o lo stuzi poi le gerna cu sisti bu'u ke'a ku'o ce'o lo
  ##     cmene be lo javni be'o ce'o `nitcu` joi bo lo klesi ce'o lo jgena pe vo'a
  ##   .i lo srera jgena cu fanmo lo porsi poi gapru le srera jgena
  ##   .i lo pagbu poi no gerna valsi cu vasru ke'a cu dunda `rivbi` ce'o lo ve pruce ce'o lo valsi
  ##     pe vo'a
  ##   .i le ve pruce po'u `Stream` cu se lidne lo nu to'e curmi pe lo porsi be lo valsi
  if node.is_terminal:
    template unit: untyped = reading.units[node.at]
      ## drata cmene lo pagbu pe le gerna valsi
      ##   .i `let` cu zbasu lo fukpi be le pagbu va'o lo nu fanva fi la'o gy. JavaScript .gy.
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
        ## drata cmene lo valsi pe le pagbu
        ##   .i `let` cu zbasu lo fukpi be le valsi va'o lo nu fanva fi la'o gy. JavaScript .gy.
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
  ## dunda lo se ciska poi lo se ciska be fi la'o gy. NIF .gy. be'o pe lo se tcidu cu se tcidu ta'i
  ##   ke'a
  ##   .i lo namcu pe le tarmi cu krasi le se ciska
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
  ## dunda lo gerna valsi poi lo se tcidu cu vasru ke'a
  ##   .i lo klesi cu lidne lo stuzi .e lo lerfu pe ro valsi
  ##   .i lo pagbu poi no gerna valsi cu vasru ke'a cu dunda `rivbi` ce'o lo ve pruce
  ##   .i le ve pruce po'u `Stream` cu se lidne lo nu to'e curmi pe lo porsi be lo valsi
  for k in 0 ..< reading.units.len:
    template unit: untyped = reading.units[k]
      ## drata cmene le pagbu
      ##   .i `let` cu zbasu lo fukpi be le pagbu va'o lo nu fanva fi la'o gy. JavaScript .gy.
    var
      terminal = (if unit.is_read: $unit.terminal else: TAG_UNREAD & " " & unit.refusal.spelled)
      words: seq[WordNif]
    if not unit.is_read and unit.refusal == RefusalText.Stream:
      terminal.add " " & reading.occurrences[unit.words[0]].reading.refusal.spelled
    for m in 0 ..< unit.words.len:
      template word: untyped = reading.occurrences[unit.words[m]]
        ## drata cmene lo valsi pe le pagbu
        ##   .i `let` cu zbasu lo fukpi be le valsi va'o lo nu fanva fi la'o gy. JavaScript .gy.
      words.add (word.start, word.finish, word.text)
    result.add (terminal: terminal, words: words)


func isSame(a, b: Node, reading: ReadingText | ReadingMarked): bool =
  ## jdice lo du'u lo tricu po'u `a` pe lo se tcidu .e lo tricu po'u `b` poi se rapli zbasu cu vasru
  ##   lo mintu javni .e lo mintu namcu .e lo mintu gerna valsi ta'i lo mintu porsi
  ##   .i ji'a jdice lo du'u le re tricu cu vasru lo mintu stuzi poi le gerna cu sisti bu'u ke'a
  ##   .i `b` cu vasru le stuzi ta'i lo stuzi pe le se ciska
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
  ## jdice lo du'u ro stuzi pe ro valsi pe le se ciska cu zvati pa pezli pe le tricu
  ##   .i ji'a jdice lo du'u lo porsi be lo pezli cu mintu lo porsi be le se ciska ja'i lo pamoi
  ##     stuzi pe ro pezli
  ##   .i ji'a jdice lo du'u ro stuzi poi no pezli cu vasru ke'a cu du lo sinxa poi zvati lo jbini
  ##     be lo valsi .a lo lerfu po'u slaka bu poi zvati lo jbini be re valsi pe pa se ciska valsi
  ##     to `CLL 3.3` toi
  var
    counts = newSeq[int](text.len)  # lo klani be lo pezli poi vasru lo stuzi
    last = -1  # lo pamoi stuzi pe lo pezli poi lidne
  var leaves: seq[int]
  marked.tree.addLeaves(leaves)
  for u in leaves:
    template unit: untyped = marked.units[u]
      ## drata cmene le pagbu
      ##   .i `let` cu zbasu lo fukpi be le pagbu
    let first = marked.occurrences[unit.words[0]].start
    if first <= last: return false
    last = first
    for w in unit.words:
      template word: untyped = marked.occurrences[w]
        ## drata cmene le valsi
        ##   .i `let` cu zbasu lo fukpi be le valsi
      if word.start > word.finish or word.finish > text.len: return false  # lo kunti se sitna
      for b in word.start ..< word.finish: inc counts[b]
  for b in 0 ..< text.len:
    if counts[b] > 1: return false
    if counts[b] == 0 and text[b] notin MARKS_BOUNDARY and text[b] != ',': return false
  true


func isReadBack*(reading: ReadingText | ReadingMarked): bool =
  ## jdice lo du'u lo se ciska be fi la'o gy. NIF .gy. be'o pe lo se tcidu cu mapti lo se dunda be
  ##   le morna be le tarmi
  ##   .i ji'a jdice lo du'u lo nu tcidu le se ciska cu rapli zbasu le mulno tricu .e ro gerna valsi
  ##     pe le se tcidu
  ##   .i ro le re cipra cu cipra le vi flalu
  var module: seq[NodeNif]
  try: module = reading.toNif.readModule
  except ValueError: return false
  if module != reading.toModule: return false
  var terminals: seq[TerminalNif]
  let tree = module[^1].toTree(terminals)
  reading.tree.isSame(tree, reading) and terminals == reading.toTerminals
