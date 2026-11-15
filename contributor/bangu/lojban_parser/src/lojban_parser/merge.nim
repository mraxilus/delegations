## jmina lo pagbu be lo selci'a ja'i lo selci'a be fi `NIF` be'o pe le pagbu
##   .i lo jalge cu du lo selci'a be fi `NIF` be'o poi lo nu tcidu le mulselci'a cu dunda ke'a
##   .i se ki'u bo lo samtci poi ponse lo selci'a be fi `NIF` po'o ku'o mu'u lo papri .a lo cikre cu
##       dunda lo tricu pe lo nu tcidu le mulno se ciska to `D1 b` pe `#859` toi
##   .i va'o lo nu lo srera cu stali kei cu jmina ro porsi be lo pagbu poi sruri le srera ku'o gi'e
##       to'e curmi no srera to lo seljdi poi se lidne `D1 b` bu'u `#859` toi
##
##   |--------------|--------------------------------------------------------------------------|
##   | lo cmene     | lo smuni                                                                 |
##   |--------------|--------------------------------------------------------------------------|
##   | `toTerminal` | lo klesi be lo genvla be'o poi selraptcidu fi lo cmene be ke'a   |
##   | `toTree`     | lo jgena pe lo tricu poi selrapyzba fi lo jgena pe `NIF` |
##   |              | .i ji'a lo genvla poi le jgena cu vasru ke'a                        |
##   | `MergeNif`   | lo selci'a be fi `NIF` be'o pe lo tricu                     |
##   |              | .i lo nu jmina cu dunda le tricu                                         |
##   |              | .i ja lo selci'a be fi `NIF` cu se to'e curmi               |
##   |              | .i le selci'a na se tcidu                                               |
##   | `mergeParts` | lo selci'a be fi `NIF` be'o pe lo tricu                     |
##   |              | .i lo nu tcidu le mulselci'a cu dunda le tricu                       |
##   |              | .i lo krasi cu du lo selci'a be fi `NIF` be'o pe lo pagbu   |
##   |--------------|--------------------------------------------------------------------------|
##
## ni'o lo pagbu be le selci'a cu du ro jgena poi zvati lo selci'a be fi `NIF` gi'e se lidne lo
##     minde
##   .i `toNifParts` ciska le jgena
##   .i lo mivyselci'a cu dunda le jgena ba lo nu ro pagbu cu se benji to `live.nim` toi
##   .i lo nu rapyzba cu cpacu lo namcu pe ro javni poi selcme ku'o lo cmene be le javni to
##       `LUT_NUMBER_BY_RULE` toi
##   .i le nu rapyzba cu cpacu ro javni poi zvati lo jbini be le re fanmo be lo porsi ku'o
##       `LUT_CHAIN_BY_ENDS`
##   .i `-` basti ro `_` pe lo tcita
##   .i `'` basti ro `h` pe lo valsi
##   .i ku'i lo selci'a poi zo zoi sitna ke'a ku'o .e lo selci'avla poi le porsi be lo valsi cu to'e
##       curmi ke'a stali
##   .i lo srejge cu ponse lo stuzi poi le gerna cu sisti bu'u ke'a ku'o ta'i lo stuzi pe vo'a to
##       `nif.nim` toi
##   .i va'o lo nu lo jgena cu ponse lo tarmi poi le ciska na ciska ke'a kei le nu rapyzba cu renro
##       `ValueError`
##   .i lo nu jmina cu to'e curmi le selci'a gi'e cusku lo namcu pe le jgena
##   .i lo nu jmina cu vimcu lo pagbu ta'i lo nu tcidu le mulno se ciska to `CLL 19.13` .e
##       `CLL 19.15` toi
##   .i le nu jmina cu vimcu ro pagbu poi se tcita `Erasure`
##   .i le pagbu cu ka'e zvati ro stuzi
##   .i le nu jmina cu vimcu zo fa'o poi fanmo le selci'a ku'o .e ro selci'avla poi se lidne zo fa'o
##   .i le nu jmina cu vimcu ro jgena poi zvati lo genja gi'e lidne zo su poi romoi
##   .i zo su poi romoi cu zvati lo genja po'o
##   .i ku'i lo pagbu poi zvati le jgena gi'e rinka lo nu lo nu tcidu le mulselci'a cu to'e curmi le
##       selci'a cu stali bu'u lo krasi be lo selja'o be lo nu jmina
##   .i le pagbu cu du lo pagbu poi le porsi be lo valsi cu to'e curmi ke'a ku'o .a zo si .a zo sa
##       poi vimcu no da ku'o .a zo lo'u poi no zo le'u fanmo ke'a
##   .i ki'u bo ja'i `CLL 19.16` le genturfa'i cu tcidu le pagbu pu lo nu zo su vimcu
##   .i lo pagbu poi vasru zo lo'u po'o jarco lo du'u xu kau zo le'u se lidne le pagbu gi'e se sitna
##       no zo zo gi'e selvau no genvla pe `ZOI` to `CLL 19.9` .e `CLL 19.10` toi
##   .i ro porsi be lo pagbu poi lamji gi'e se lidne zo su poi romoi ku'o gi'e vasru no srejge cu se
##       jmina fo pa tricu ta'i lo nu tcidu lo mulselci'a pe le porsi
##   .i `assembleText` zbasu le tricu lo tricu pe ro pagbu
##   .i va'o lo drata le gerna cu tcidu ro genvla pe le porsi ca pa nu tcidu
##   .i va'o lo nu le gerna cu sisti kei pa srejge cu vasru lo tricu pe ro pagbu ta'i lo nu le se
##       tcidu poi sinxa ro srera ca lo nu tcidu le mulselci'a cu dunda le tricu to
##       `readGrammarMarked` toi
##   .i ro pagbu poi su'o velru'e cu to'e curmi ke'a zvati lo jgena poi traji lo ka dizlo kei gi'e
##       vasru lo pagbu poi se tcidu gi'e sruri le se to'e curmi ku'o ku'o ta'i lo nu le se tcidu
##       poi sinxa ro srera ca lo nu tcidu le mulselci'a cu punji le se to'e curmi to `placeRefused`
##       pe `prose.nim` toi
##   .i se ki'u bo le se to'e curmi cu fendi no porsi
##   .i lo pagbu poi vasru pa srejge pe le gerna cu stali gi'e na cenba gi'e zvati lo jbini be lo
##       porsi
##   .i le se tcidu poi sinxa ro srera ca lo nu tcidu le mulselci'a cu ralte ro le pagbu ta'i lo nu
##       sepli kei ne'i pa srejge
##   .i se ki'u bo le gerna cu dunda no stuzi pe le tricu le pagbu
##   .i se ki'u bo va'o lo nu no srera cu stali kei lo nu jmina cu dunda lo selci'a be fi `NIF` be'o
##       poi mintu le selci'a be `readText` be'o fi ro lerfu to `is_whole` toi
##   .i va'o lo nu lo srera cu stali kei le nu jmina cu dunda lo tricu pe ro porsi ta'i lo nu tcidu
##       le mulselci'a pe le porsi to `test_merge.nim` toi
##   .i jdima fa lo nu lo temci be lo nu rapyzba .e lo nu jmina cu zenba ca lo nu lo selci'a be fi
##       `NIF` cu zenba lo ka clani
##   .i le gerna cu tcidu ro genvla pe pa porsi ca pa nu tcidu va'o lo nu le javni pe le so'i nu
##       tcidu cu spofu kei po'o
##   .i lo nu jmina cu rapli ja'i lo namcu pe lo jgena
##   .i ki'u bo `items` .e lo nu cmene lo jgena cu zbasu lo fukpi be le jgena va'o lo nu fanva fi
##       `JavaScript`

{.experimental: "strictFuncs".}

import std/[options, strutils, tables]

import ./[dictionary, grammar, nif, nif_read, prose, selmaho, tanru]


type
  MergeNif* = object
    ## lo jalge be lo nu jmina lo pagbu
    ##   .i le jalge cu du lo selci'a be fi `NIF` be'o pe lo tricu ge'u .a lo nu to'e curmi lo
    ##       selci'a be fi `NIF`
    case is_merged*: bool
    of true:
      nif*: string
        ## lo selci'a be fi `NIF` be'o pe lo nu jmina
        ##   .i ro pagbu poi lidne zo su poi romoi ku'o gi'e rinka lo nu lo nu tcidu le mulselci'a
        ##       cu to'e curmi le selci'a cu lidne ro datyjge
        ##   .i le datyjge cu du lo tricu pe ro porsi be lo pagbu poi vasru no srejge ge'u .e ro
        ##       pagbu poi vasru pa srejge
        ##   .i le datyjge cu porsi ta'i le selci'a
        ##   .i ro jgena cu zvati lo linji pe vo'a
      is_whole*: bool
        ## le selci'a cu vasru pa tricu gi'e vasru no srejge gi'e vasru no pagbu poi se to'e curmi
        ##   .i le selci'a cu du lo selci'a be `readText`
    of false:
      part*: Option[int]
        ## lo namcu pe lo jgena poi se to'e curmi
        ##   .i li no cu krasi lo nu kancu lo jgena poi se lidne lo minde
        ##   .i va'o lo nu le selci'a na se tcidu kei le datnypau cu kunti
      reason*: string  ## lo seltcu be le se ciska be fi `NIF`


const
  DIRECTIVES = 2
    ## lo klani be lo minde poi krasi lo selci'a be fi `NIF`
    ##   .i le minde cu cusku lo namcu pe le tarmi .e lo bangu to `HEADER` toi
  ERASERS = {Selmaho.Si, Selmaho.Sa}
    ## lo selma'o be lo cmavo poi vimcu lo valsi poi lidne le cmavo to `CLL 19.13` toi
  QUOTERS = {Selmaho.Zo, Selmaho.Zoi}
    ## lo selma'o be lo cmavo poi sitna lo valsi poi se lidne le cmavo
    ##   .i ji'a lo selma'o be lo genvla poi vasru lo valsi poi le genvla cu sitna ke'a
    ##   .i zo le'u poi pa le re klesi cu vasru ke'a fanmo no zo lo'u to `CLL 19.9` .e `CLL 19.10`
    ##       toi



func toTerminal*(name: string): Terminal =
  ## raptcidu lo klesi be lo genvla be'o fi lo cmene be le klesi mu'u `KOhA` .a `BRIVLA`
  ##   .i va'o lo nu le cmene cu cmene no klesi kei renro `ValueError`
  if name == $TERMINAL_BRIVLA: return TERMINAL_BRIVLA
  if name == $TERMINAL_CMENE: return TERMINAL_CMENE
  let named = name.toSelmaho
  if named.isNone:
    raise newException(ValueError, "Class of terminal should name selma'o; got `" & name & "`.")
  named.get.toTerminal


func toTree*(node: NodeNif, terminals: var seq[TerminalNif]): Node =
  ## rapyzba lo jgena pe lo tricu lo jgena pe `NIF`
  ##   .i le fancu cu cpacu lo namcu pe lo javni poi selcme ku'o lo cmene be le javni
  ##   .i le fancu cu cpacu ro porsi le re fanmo be le porsi sepi'o `LUT_CHAIN_BY_ENDS`
  ##   .i le re fanmo cu du lo namcu pe lo javni poi krasi le porsi ku'o .e lo cmene be lo javni poi
  ##       fanmo le porsi
  ##   .i `-` basti ro `_` pe lo tcita
  ##   .i lo genvla cu jmina lo klesi .e lo valsi `terminals`
  ##   .i `'` basti ro `h` pe lo valsi
  ##   .i ku'i lo cimoi lerpoi pe `ZOI` stali
  ##   .i lo srejge cu ponse lo stuzi poi le gerna cu sisti bu'u ke'a ku'o ta'i lo stuzi pe vo'a
  ##   .i lo pagbu poi se tcita `rivbi` jmina `rivbi` .e lo cmene pe vo'a
  ##   .i va'o lo nu le velru'e cu du `Stream` kei lo lerfu cu stali
  ##   .i va'o lo nu le jgena cu vasru no tarmi poi `nif.nim` ciska ke'a kei renro `ValueError`
  template refuse(shape: string) =
    raise newException(ValueError, "Node `" & node.text & "` of NIF should hold " & shape & ".")

  if node.kind != KindNif.Compound: refuse("tag")
  if node.children.len > 0 and node.children[^1].kind == KindNif.Literal:
    var
      terminal = node.text
      k = 0
    while node.children[k].kind == KindNif.Identifier:
      terminal.add ' '
      terminal.add node.children[k].text
      inc k
    if (node.children.len - k) mod 3 != 0: refuse("bytes and letters of each word")
    var literals: seq[string]
    for m in countup(k, node.children.high, 3):
      let is_word = node.children[m].kind == KindNif.Number and
        node.children[m + 1].kind == KindNif.Number and
        node.children[m + 2].kind == KindNif.Literal
      if not is_word: refuse("bytes and letters of each word")
      literals.add node.children[m + 2].text
    let
      is_kept = terminal.startsWith(TAG_UNREAD & " " & RefusalText.Stream.spelling)
      quoted = (if node.text == $Selmaho.Zoi: some(literals.indexQuoted) else: none(int))
    var words: seq[WordNif]
    for w in 0 ..< literals.len:
      let letters =
        if is_kept or quoted == some(w): literals[w] else: literals[w].replace('h', '\'')
      words.add (node.children[k + 3 * w].number, node.children[k + 3 * w + 1].number, letters)
    terminals.add (terminal: terminal, words: words)
    return Node(is_terminal: true, at: terminals.high)
  if node.text == TAG_ERROR:
    let is_error = node.children.len > 2 and node.children[0].kind == KindNif.Number and
      node.children[1].kind == KindNif.Identifier and
      node.children[2].kind == KindNif.Compound and node.children[2].text == TAG_EXPECTS
    if not is_error: refuse("byte, rule and terminals read where grammar stops")
    let rule = node.children[1].text.replace('_', '-')
    if rule notin LUT_NUMBER_BY_RULE: refuse("name of rule of 21.1")
    var expected: seq[Terminal]
    for k in 0 ..< node.children[2].children.len:
      expected.add node.children[2].children[k].text.toTerminal
    result = Node(
      is_terminal: false, rule: rule, number: LUT_NUMBER_BY_RULE[rule],
      stop: some(Stop(at: node.children[0].number, expected: expected)),
    )
    for k in 3 ..< node.children.len: result.children.add node.children[k].toTree(terminals)
    return
  let rule = node.text.replace('_', '-')
  if rule notin LUT_NUMBER_BY_RULE: refuse("name of rule of 21.1")
  var count = 0
  while count < node.children.len and node.children[count].kind == KindNif.Number: inc count
  if count > 1: refuse("at most number of rule opening its chain")
  result = Node(is_terminal: false, rule: rule, number: LUT_NUMBER_BY_RULE[rule])
  for k in count ..< node.children.len: result.children.add node.children[k].toTree(terminals)
  if count == 1:
    let ends = (node.children[0].number, result.number)
    if ends notin LUT_CHAIN_BY_ENDS: refuse("two ends of chain of 21.1")
    let chain = LUT_CHAIN_BY_ENDS[ends]
    for k in countdown(chain.len - 2, 0):
      result = Node(
        is_terminal: false, rule: chain[k].rule, number: chain[k].number, children: @[result]
      )


func isUnit(node: NodeNif, stage: string): bool =
  ## jdice lo du'u lo jgena pe `NIF` du lo pagbu poi no genvla cu vasru ke'a gi'e se tcita `stage`
  node.kind == KindNif.Compound and node.text == TAG_UNREAD and node.children.len > 0 and
    node.children[0].kind == KindNif.Identifier and node.children[0].text == stage


func isCmavo(literal: string, selmahos: set[Selmaho]): bool =
  ## jdice lo du'u lo lerpoi pe `NIF` ciska lo cmavo be pa selma'o pe `selmahos`
  ##   .i `h` se tcidu ta'i `'`
  let named = literal.replace('h', '\'').selmaho
  named.isSome and named.get in selmahos


func isDropped(node: NodeNif): bool =
  ## jdice lo du'u le jgena cu du lo pagbu poi lo nu tcidu le mulselci'a cu ralte no valsi pe ke'a
  ##   .i le pagbu cu vasru lo valsi poi lo nu vimcu cu vimcu ke'a ku'o .e lo cmavo poi vimcu le
  ##       valsi
  ##   .i ja le pagbu cu vasru zo fa'o poi fanmo le selci'a
  ##   .i ja le pagbu cu vasru lo selci'avla poi se lidne zo fa'o
  node.isUnit(RefusalText.Erasure.spelling) or node.isUnit(RefusalText.Faho.spelling) or (
    node.isUnit(RefusalText.Stream.spelling) and node.children.len > 1 and
    node.children[1].text == Refusal.Faho.spelling
  )


func isHoldingError(node: NodeNif): bool =
  ## jdice lo du'u lo jgena pe `NIF` vasru pa srejge pe le gerna
  ##   .i lo ni le srejge cu dizlo cu na vajni
  if node.kind != KindNif.Compound: return false
  if node.text == TAG_ERROR: return true
  for k in 0 ..< node.children.len:
    if node.children[k].isHoldingError: return true


func reach(node: NodeNif): int =
  ## dunda lo stuzi poi se lidne lo romoi valsi poi lo jgena pe `NIF` vasru ke'a
  ##   .i lo ni le valsi cu dizlo cu na vajni
  ##   .i va'o lo nu le jgena cu vasru no valsi kei dunda li no
  if node.kind != KindNif.Compound: return 0
  for k in 0 ..< node.children.len:
    template child: untyped = node.children[k]
      ## datcme le jgena
      ##   .i `let` zbasu lo fukpi be le jgena va'o lo nu fanva fi `JavaScript`
    if child.kind == KindNif.Literal and k >= 1 and node.children[k - 1].kind == KindNif.Number:
      result = max(result, node.children[k - 1].number)
    elif child.kind == KindNif.Compound: result = max(result, child.reach)


func isRefused(terminal: TerminalNif): bool =
  ## jdice lo du'u lo genvla poi `NIF` dunda ke'a du lo pagbu poi no genvla cu vasru ke'a
  ##   .i su'o velru'e cu to'e curmi le pagbu
  terminal.terminal.startsWith(TAG_UNREAD)


func mergedRun(
    trees: openArray[Node], span: Slice[int], terminals: openArray[TerminalNif], ending: int
): Node =
  ## jmina lo porsi be lo tricu poi selrapyzba fi lo pagbu poi vasru no srejge ku'o be'o fo pa tricu
  ##     ta'i lo nu le se tcidu poi sinxa ro srera ca lo nu tcidu le mulselci'a cu tcidu lo selci'a
  ##     pe le tricu
  ##   .i lo genvla pe le selci'a cu du `span`
  ##   .i le gerna cu tcidu lo genvla poi se tcidu
  ##   .i ro pagbu poi su'o velru'e cu to'e curmi ke'a zvati lo jgena poi traji lo ka dizlo kei gi'e
  ##       vasru lo pagbu poi se tcidu gi'e sruri le se to'e curmi to `placeRefused` pe `prose.nim`
  ##       toi
  ##   .i va'o lo nu lo tricu pe lo pagbu cu zbasu no tricu kei le gerna cu tcidu ro genvla ca pa nu
  ##       tcidu
  ##   .i va'o lo nu le gerna cu sisti kei pa srejge cu vasru lo tricu pe ro pagbu to
  ##       `readGrammarMarked` toi
  ##   .i le gerna cu sisti bu'u lo stuzi poi lo genvla pe le nu sisti cu krasi bu'u ke'a ku'o .a
  ##       `ending`
  func indexed(node: Node, indexes: openArray[int], is_kept: openArray[bool]): Node =
    ## dunda lo fukpi be le jgena
    ##   .i ro pezli poi `is_kept` to'e curmi ke'a selvi'u
    ##   .i ro datpezli cu ponse lo namcu pe `indexes`
    if node.is_terminal: return Node(is_terminal: true, at: indexes[node.at])
    result = Node(is_terminal: false, rule: node.rule, number: node.number, stop: node.stop)
    for k in 0 ..< node.children.len:
      template child: untyped = node.children[k]
        ## datcme le jgena
        ##   .i `let` zbasu lo fukpi be le jgena va'o lo nu fanva fi `JavaScript`
      if not child.is_terminal or is_kept[child.at]:
        result.children.add child.indexed(indexes, is_kept)

  func placed(node: var Node, globals: openArray[int], terminals: openArray[TerminalNif],
      ending: int) =
    ## galfi lo namcu pe ro pezli pe le jgena lo namcu pe lo genvla ja'i `globals`
    ##   .i ji'a dunda ro stuzi poi le gerna cu sisti bu'u ke'a ku'o ta'i lo stuzi poi lo genvla pe
    ##       le nu sisti cu krasi bu'u ke'a
    ##   .i va'o lo nu le gerna cu sisti ba lo romoi gerna valsi kei dunda `ending`
    ##   .i `NIF` ciska le stuzi ta'i le mintu
    if node.is_terminal:
      node.at = globals[node.at]
      return
    if node.stop.isSome:
      let at = node.stop.get.at
      node.stop.get.at =
        if at < globals.len: terminals[globals[at]].words[0].start else: ending
    for k in 0 ..< node.children.len: node.children[k].placed(globals, terminals, ending)

  var
    reads = newSeq[bool](terminals.len)  # lo genvla pe le gerna ja'i lo namcu
    indexes = newSeq[int](terminals.len)  # lo namcu ne'i lo se tcidu ja'i lo namcu
    globals: seq[int]  # lo namcu pe ro genvla poi se tcidu ku'o ta'i lo porsi
    classes: seq[Terminal]
  for g in span:
    if terminals[g].isRefused: continue
    (reads[g], indexes[g]) = (true, globals.len)
    globals.add g
    classes.add terminals[g].terminal.toTerminal
  var parts: seq[Node]
  for k in 0 ..< trees.len:
    let is_unit = trees[k].is_terminal and not reads[trees[k].at]
    if not is_unit: parts.add trees[k].indexed(indexes, reads)
  let built = classes.assembleText(parts)
  # lo fukpi
  #   .i `move` spofu `JS`
  result = (if built.isSome: built.get else: classes.readGrammarMarked)
  result.placed(globals, terminals, ending)
  result.placeRefused(reads, span)


func mergeParts*(nif: string): MergeNif =
  ## zbasu lo selci'a be fi `NIF` be'o pe lo tricu poi lo nu tcidu le mulselci'a cu dunda ke'a ge'u
  ##     lo selci'a be fi `NIF` be'o pe lo pagbu be le selci'a
  ##   .i `toNifParts` .e lo mivyselci'a cu dunda le selci'a pe le pagbu
  ##   .i le fancu cu vimcu ro pagbu poi lo nu tcidu le mulselci'a cu ralte no valsi pe ke'a ku'o .e
  ##       ro jgena poi zvati lo genja gi'e lidne zo su poi romoi
  ##   .i ku'i le fancu na vimcu lo pagbu poi rinka lo nu lo nu tcidu le mulselci'a cu to'e curmi le
  ##       selci'a
  ##   .i le fancu cu jmina ro porsi be lo pagbu poi vasru no srejge ta'i lo nu tcidu le mulselci'a
  ##   .i le fancu cu ralte ro pagbu poi vasru pa srejge ku'o gi'e na galfi le pagbu
  func refused(part: Option[int], reason: string): MergeNif =
    MergeNif(is_merged: false, part: part, reason: reason)

  func addCloser(node: NodeNif, closer: var Option[int], is_quoted_next: var bool) =
    ## klama fo ro valsi poi le jgena cu vasru ke'a ku'o ta'i lo porsi pe le selci'a
    ##   .i le fancu cu ralte ne'i `closer` lo stuzi poi zo le'u poi romoi gi'e ka'e fanmo zo lo'u
    ##       ta'i lo nu le porsi be lo valsi cu tcidu le selci'a cu krasi bu'u ke'a
    ##   .i no zo zo poi lidne zo le'u sitna zo le'u
    ##   .i no genvla pe `ZOI` vasru zo le'u to `CLL 19.9` .e `CLL 19.10` toi
    ##   .i `is_quoted_next` jarco lo du'u xu kau lo valsi poi lidne cu sitna
    if node.kind != KindNif.Compound: return
    if node.children.len == 0 or node.children[^1].kind != KindNif.Literal:
      for k in 0 ..< node.children.len: node.children[k].addCloser(closer, is_quoted_next)
      return
    let is_quoting = node.text == $Selmaho.Zoi
    for k in 2 ..< node.children.len:
      if node.children[k].kind != KindNif.Literal: continue
      template literal: untyped = node.children[k].text
        ## datcme lo lerfu pe le valsi
        ##   .i `let` zbasu lo fukpi be le lerfu va'o lo nu fanva fi `JavaScript`
      if not (is_quoting or is_quoted_next) and literal.isCmavo({Selmaho.Lehu}):
        closer = some(node.children[k - 2].number)
      is_quoted_next = is_quoting or literal.isCmavo(QUOTERS)

  func addFatal(node: NodeNif, closer: Option[int], units: var seq[NodeNif]) =
    ## jmina ro pagbu poi le jgena cu vasru ke'a gi'e rinka lo nu lo nu tcidu le mulselci'a cu to'e
    ##     curmi le selci'a ku'o `units`
    ##   .i ku'i zo su poi se lidne le pagbu cu vimcu le pagbu
    ##   .i le pagbu cu du lo pagbu poi le porsi be lo valsi cu to'e curmi ke'a ku'o .a zo si .a zo
    ##       sa poi vimcu no da ku'o .a zo lo'u poi no zo le'u fanmo ke'a
    ##   .i zo lo'u na selfa'o va'o lo nu no zo le'u poi `closer` dunda ke'a se lidne zo lo'u
    ##   .i ki'u bo le porsi be lo valsi cu tcidu zo su poi se lidne zo lo'u ta'i lo valsi poi zo
    ##       lo'u sitna ke'a
    if node.kind != KindNif.Compound or node.isDropped: return
    if node.text != TAG_UNREAD:
      for k in 0 ..< node.children.len: node.children[k].addFatal(closer, units)
      return
    if node.children.len == 0: return
    var start = 0  # lo pamoi stuzi pe le pagbu zi'e poi se lidne lo cmene pe le pagbu
    while start < node.children.len and node.children[start].kind != KindNif.Number: inc start
    var is_closed = false  # zo le'u selvau le pagbu gi'a se lidne le pagbu
    for k in start ..< node.children.len:
      template child: untyped = node.children[k]
        ## datcme le jgena
        ##   .i `let` zbasu lo fukpi be le jgena va'o lo nu fanva fi `JavaScript`
      if child.kind == KindNif.Literal and child.text.isCmavo({Selmaho.Lehu}): is_closed = true
    if start < node.children.len:
      is_closed = is_closed or (closer.isSome and closer.get > node.children[start].number)
    let
      stage = node.children[0].text
      is_first = start + 2 < node.children.len
      is_eraser = is_first and node.children[start + 2].text.isCmavo(ERASERS)
      is_lohu = is_first and node.children[start + 2].text.isCmavo({Selmaho.Lohu})
      is_fatal = stage == RefusalText.Stream.spelling or
        (stage == RefusalText.Construct.spelling and is_eraser) or
        (stage == RefusalText.Quotation.spelling and is_lohu and not is_closed)
    if is_fatal: units.add node

  func kept(node: NodeNif): NodeNif =
    ## dunda lo fukpi be le jgena
    ##   .i ro pagbu poi lo nu tcidu le mulselci'a cu ralte no valsi pe ke'a selvi'u
    ##   .i lo ni le pagbu cu dizlo cu na vajni
    result = NodeNif(kind: node.kind, text: node.text, number: node.number)
    for k in 0 ..< node.children.len:
      if not node.children[k].isDropped: result.children.add node.children[k].kept

  if not nif.startsWith(HEADER):
    return refused(none(int), "NIF should open with directives `nif.nim` writes")
  var module: seq[NodeNif]
  try: module = nif.readModule
  except ValueError as error: return refused(none(int), error.msg)

  # zo su poi romoi ne'i lo genja
  #   .i ro jgena poi lidne zo su zvati lo selci'a poi zo su vimcu ke'a
  #   .i ku'i lo pagbu poi lo nu tcidu le mulselci'a cu to'e curmi ke'a stali
  var
    su = DIRECTIVES - 1
    closer = none(int)
    is_quoted_next = false
    fatal: seq[NodeNif]
  for k in DIRECTIVES ..< module.len:
    if module[k].isUnit(RefusalText.Su.spelling): su = k
    module[k].addCloser(closer, is_quoted_next)
  for k in DIRECTIVES ..< su: module[k].addFatal(closer, fatal)
  var faho = none(int)  # lo stuzi poi zo fa'o poi fanmo le selci'a cu krasi bu'u ke'a
  for k in su + 1 ..< module.len:
    let is_faho = module[k].isUnit(RefusalText.Faho.spelling) and module[k].children.len > 1 and
      module[k].children[1].kind == KindNif.Number
    if is_faho and faho.isNone: faho = some(module[k].children[1].number)

  # rapyzba ro pagbu poi lidne zo su gi'e stali
  #   .i ba bo rapyzba ro jgena poi se lidne zo su
  #   .i ro klesi be lo genvla cu se tcidu
  var
    terminals: seq[TerminalNif]
    rebuilt: seq[tuple[tree: Node, span: Slice[int], has_error: bool, reach: int]]
      # `reach`
      #   .i lo stuzi poi se lidne lo romoi valsi pe le jgena .a lo pagbu poi selvi'u gi'e se lidne
      #       le jgena
  for k in 0 ..< fatal.len:
    let first = terminals.len
    try: rebuilt.add (fatal[k].toTree(terminals), first ..< terminals.len, true, 0)
    except ValueError as error: return refused(none(int), error.msg)
  for k in su + 1 ..< module.len:
    if module[k].isDropped:
      if rebuilt.len > 0: rebuilt[^1].reach = max(rebuilt[^1].reach, module[k].reach)
      continue
    let
      node = module[k].kept
      first = terminals.len
    try:
      rebuilt.add (
        node.toTree(terminals), first ..< terminals.len, node.isHoldingError, module[k].reach
      )
      for g in first ..< terminals.len:
        if not terminals[g].isRefused: discard terminals[g].terminal.toTerminal
    except ValueError as error: return refused(some(k - DIRECTIVES), error.msg)

  # jmina ro porsi be lo jgena poi vasru no srejge
  #   .i ralte ro jgena poi vasru pa srejge ku'o gi'e na galfi le jgena
  #   .i va'o lo nu le gerna cu sisti ba lo romoi gerna valsi pe le porsi kei le gerna cu sisti bu'u
  #       zo fa'o poi se lidne le porsi
  #   .i va'o lo drata le gerna cu sisti bu'u lo stuzi poi se lidne lo romoi valsi pe le porsi
  #   .i lo valsi poi selvi'u cu se kancu ji'a
  #   .i le se tcidu poi sinxa ro srera cu sisti ta'i le mintu bu'u lo stuzi poi le selci'a cu fanmo
  #       bu'u ke'a
  var
    trees: seq[Node]
    run: seq[Node]
    span = 0 ..< 0  # lo genvla pe le porsi
    ending = 0  # lo stuzi poi se lidne lo romoi valsi pe le porsi
  for k in 0 .. rebuilt.len:
    if k < rebuilt.len and not rebuilt[k].has_error:
      if run.len == 0: (span, ending) = (rebuilt[k].span, 0)
      span.b = rebuilt[k].span.b
      ending = max(ending, rebuilt[k].reach)
      run.add rebuilt[k].tree
      continue
    if run.len > 0:
      if k == rebuilt.len and faho.isSome: ending = faho.get
      trees.add run.mergedRun(span, terminals, ending)
      run.setLen(0)
    if k < rebuilt.len: trees.add rebuilt[k].tree
  # lo srejge pe lo porsi cu zvati lo genja
  var is_whole = trees.len == 1 and trees[0].stop.isNone
  for m in 0 ..< terminals.len: is_whole = is_whole and not terminals[m].isRefused
  MergeNif(is_merged: true, nif: trees.toNif(LeavesNif(terminals: terminals)), is_whole: is_whole)
