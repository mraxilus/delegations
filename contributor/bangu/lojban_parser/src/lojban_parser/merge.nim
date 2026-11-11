## Merge parts of text from their NIF into NIF one pass gives text they read, so program that
##   holds NIF alone, as page or fixer, gives tree of one pass (ruling `D1 b` on #859).
##
##   |------------|-----------------------------------------------------------------|
##   | Code       | Meaning                                                         |
##   |------------|-----------------------------------------------------------------|
##   | toTerminal | class of terminal, read back from its name                      |
##   | toTree     | node of tree rebuilt from node of NIF, with terminals it holds  |
##   | MergeNif   | NIF one pass gives, or refusal: node of module, byte and reason |
##   | mergeParts | NIF one pass gives text, from NIF of its parts                  |
##   |------------|-----------------------------------------------------------------|
##
##   Parts: each node of module past its directives, as `toNifParts` writes them, and as live
##     text gives them once each part goes out (`live.nim`).
##   Rebuild: each rule between two ends of chain from `LUT_CHAIN_BY_ENDS`, `-` for `_` of tag,
##     `'` for `h` of word, save third string of `ZOI` and written word stream refuses; error
##     node takes byte grammar stops at as its place (`nif.nim`). Node of shape writer gives
##     not raises `ValueError`.
##   Drop, as one pass reads text (19.13, 19.15): each unit of stage `Erasure`, wherever it
##     stands; `fa'o` that ends input, and each written word after it; each node of root up to
##     last `su`, which stands in root alone.
##   Refusal names node of module, counted from 0 past directives, byte where error stands, and
##     stage or rule:
##     Node past last `su` that holds error node, or unit some stage refuses.
##     Node before last `su` that holds unit stream or quotation refuses, or `si` or `sa`
##       erasing nothing: 19.16 reads them before `su` erases, so one pass refuses them too.
##       Error of grammar, selma'o, `zei`, BAhE or `bu` there drops, since those read after
##       `su` erases (`prose.nim`).
##   Merge: `assembleText` builds tree of text from trees of parts. Where rule of passes breaks,
##     as parts give that live text cuts after opener that waits, grammar reads terminals whole,
##     as `readGrammar` does. So merge gives NIF `readText` writes, byte for byte, and refuses
##     where it refuses (`test_merge.nim`).
##   Cost: rebuild and merge grow with length of NIF; grammar reads terminals whole only where
##     rule of passes breaks.
##   Merge loops by index, since `items` and binding of node copy it on JavaScript backend.

{.experimental: "strictFuncs".}

import std/[options, strutils, tables]

import ./[dictionary, grammar, nif, nif_read, prose, selmaho, tanru]


type
  MergeNif* = object  ## Define outcome of merge of parts: NIF of one pass, or refusal.
    case is_merged*: bool
    of true:
      nif*: string  ## Module of NIF one pass gives text parts read, as `readText` writes it.
    of false:
      part*: Option[int]
        ## Node of module refused, counted from 0 past directives; none where grammar refuses
        ##   text whole, or NIF reads not.
      start*: Option[int]  ## Byte of text where error stands; none where NIF reads not.
      reason*: string  ## Stage or rule refusing it, or what NIF should hold.

  ErrorNif = tuple[start: int, reason: string]  ## Define error node holds: byte, stage or rule.


const
  DIRECTIVES = 2  ## Directives module opens with, version and language (`HEADER`).
  ERASERS = {Selmaho.Si, Selmaho.Sa}  ## Selma'o of cmavo erasing word before it (19.13).
  QUOTERS = {Selmaho.Zo, Selmaho.Zoi}
    ## Selma'o of cmavo quoting word after it, or of terminal holding words it quotes: `le'u`
    ##   either holds closes no `lo'u` (19.9, 19.10).



func toTerminal*(name: string): Terminal =
  ## Read class of terminal back from its name, as `KOhA` or `BRIVLA`; `ValueError` where it
  ##   names none.
  if name == $TERMINAL_BRIVLA: return TERMINAL_BRIVLA
  if name == $TERMINAL_CMENE: return TERMINAL_CMENE
  let named = name.toSelmaho
  if named.isNone:
    raise newException(ValueError, "Class of terminal should name selma'o; got `" & name & "`.")
  named.get.toTerminal


func toTree*(node: NodeNif, terminals: var seq[TerminalNif]): Node =
  ## Rebuild node of tree from node of NIF: each chain from its two ends by `LUT_CHAIN_BY_ENDS`,
  ##   `-` for each `_` of tag; terminal adds class and words to `terminals`, `'` for each `h` of
  ##   word, and third string of `ZOI` as it is. Error node takes byte grammar stops at as its
  ##   place; unit `rivbi` adds `rivbi` and its identifiers, and keeps letters of stage
  ##   `Stream` as they are. `ValueError` where node holds no shape `nif.nim` writes.
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
    let is_error = node.children.len > 3 and node.children[0].kind == KindNif.Number and
      node.children[1].kind == KindNif.Identifier and
      node.children[2].kind == KindNif.Number and node.children[3].text == TAG_EXPECTS
    if not is_error: refuse("byte, rule, number and terminals read where grammar stops")
    var expected: seq[Terminal]
    for k in 0 ..< node.children[3].children.len:
      expected.add node.children[3].children[k].text.toTerminal
    result = Node(
      is_terminal: false, rule: node.children[1].text.replace('_', '-'),
      number: node.children[2].number,
      stop: some(Stop(at: node.children[0].number, expected: expected)),
    )
    for k in 4 ..< node.children.len: result.children.add node.children[k].toTree(terminals)
    return
  var count = 0
  while count < node.children.len and node.children[count].kind == KindNif.Number: inc count
  if count < 1 or count > 2: refuse("number of rule, or two ends of chain")
  result = Node(
    is_terminal: false, rule: node.text.replace('_', '-'), number: node.children[count - 1].number
  )
  for k in count ..< node.children.len: result.children.add node.children[k].toTree(terminals)
  if count == 2:
    let ends = (node.children[0].number, node.children[1].number)
    if ends notin LUT_CHAIN_BY_ENDS: refuse("two ends of chain of 21.1")
    let chain = LUT_CHAIN_BY_ENDS[ends]
    for k in countdown(chain.len - 2, 0):
      result = Node(
        is_terminal: false, rule: chain[k].rule, number: chain[k].number, children: @[result]
      )


func isUnit(node: NodeNif, stage: string): bool =
  ## Decide whether node of NIF is unit no terminal holds, of stage `stage`.
  node.kind == KindNif.Compound and node.text == TAG_UNREAD and node.children.len > 0 and
    node.children[0].kind == KindNif.Identifier and node.children[0].text == stage


func isCmavo(literal: string, selmahos: set[Selmaho]): bool =
  ## Decide whether literal of NIF spells cmavo of selma'o of `selmahos`, `h` read as `'`.
  let named = literal.replace('h', '\'').selmaho
  named.isSome and named.get in selmahos


func isDropped(node: NodeNif): bool =
  ## Decide whether node is unit one pass holds no word of: words erasure erases, with cmavo
  ##   erasing them; `fa'o` that ends input; written word after it.
  node.isUnit(RefusalText.Erasure.spelling) or node.isUnit(RefusalText.Faho.spelling) or (
    node.isUnit(RefusalText.Stream.spelling) and node.children.len > 1 and
    node.children[1].text == Refusal.Faho.spelling
  )


func mergeParts*(nif: string): MergeNif =
  ## Give NIF one pass gives text, from NIF of its parts, as `toNifParts` writes it and live text
  ##   gives it: drop each unit one pass holds no word of, and each node of root up to last `su`;
  ##   refuse node holding error one pass refuses, naming it; then build tree of text from trees
  ##   of parts, as passes do, or read its terminals whole where rule of passes breaks.
  func refused(part, start: Option[int], reason: string): MergeNif =
    MergeNif(is_merged: false, part: part, start: start, reason: reason)

  func addCloser(node: NodeNif, closer: var Option[int], is_quoted_next: var bool) =
    ## Walk words node holds, in order of text, keeping in `closer` byte where last `le'u`
    ##   opens that may close `lo'u` as stream reads text: no `zo` before it quotes it, and no
    ##   `ZOI` terminal holds it (19.9, 19.10). `is_quoted_next` holds whether word before quotes.
    if node.kind != KindNif.Compound: return
    if node.children.len == 0 or node.children[^1].kind != KindNif.Literal:
      for k in 0 ..< node.children.len: node.children[k].addCloser(closer, is_quoted_next)
      return
    let is_quoting = node.text == $Selmaho.Zoi
    for k in 2 ..< node.children.len:
      if node.children[k].kind != KindNif.Literal: continue
      template literal: untyped = node.children[k].text
        ## Alias letters of word, which `let` would copy on JavaScript backend.
      if not (is_quoting or is_quoted_next) and literal.isCmavo({Selmaho.Lehu}):
        closer = some(node.children[k - 2].number)
      is_quoted_next = is_quoting or literal.isCmavo(QUOTERS)

  func firstError(node: NodeNif, is_erased: bool, closer: Option[int]): Option[ErrorNif] =
    ## Give first error node holds, in order of NIF: error node, or unit some stage refuses.
    ##   Where node stands in text `su` erases (`is_erased`), give unit stream refuses, `si` or
    ##   `sa` erasing nothing, or `lo'u` no `le'u` closes, as no `le'u` past it that `closer`
    ##   gives stands: stream reads `su` after it as word it quotes (19.9).
    if node.kind != KindNif.Compound or node.isDropped: return
    var start = 0  # first byte node writes, which unit and error node write before its nodes
    while start < node.children.len and node.children[start].kind != KindNif.Number: inc start
    let byte_first = (if start < node.children.len: node.children[start].number else: 0)
    if node.text == TAG_ERROR and not is_erased:
      let rule = (
        if node.children.len > 2: node.children[1].text.replace('_', '-') & " " &
          $node.children[2].number
        else: ""
      )
      return some((byte_first, "grammar of 21.1 stops in rule `" & rule & "`"))
    if node.text == TAG_UNREAD:
      if node.children.len == 0: return some((0, "unit should name its stage"))
      var is_closed = false  # unit holds `le'u`, or `le'u` stands past it
      for k in start ..< node.children.len:
        template child: untyped = node.children[k]
          ## Alias node, which `let` would copy on JavaScript backend.
        if child.kind == KindNif.Literal and child.text.isCmavo({Selmaho.Lehu}): is_closed = true
      is_closed = is_closed or (closer.isSome and closer.get > byte_first)
      let
        stage = node.children[0].text
        is_first = start + 2 < node.children.len
        is_eraser = is_first and node.children[start + 2].text.isCmavo(ERASERS)
        is_lohu = is_first and node.children[start + 2].text.isCmavo({Selmaho.Lohu})
        is_error = (
          if is_erased:
            stage == RefusalText.Stream.spelling or
              (stage == RefusalText.Construct.spelling and is_eraser) or
              (stage == RefusalText.Quotation.spelling and is_lohu and not is_closed)
          else: true
        )
        refusal = (if node.children.len > 1 and stage == RefusalText.Stream.spelling:
          ", as `" & node.children[1].text & "`" else: "")
      if is_error: return some((byte_first, "stage `" & stage & "` refuses it" & refusal))
      return
    for k in 0 ..< node.children.len:
      result = node.children[k].firstError(is_erased, closer)
      if result.isSome: return

  func kept(node: NodeNif): NodeNif =
    ## Give node with each unit one pass holds no word of left out, at any depth.
    result = NodeNif(kind: node.kind, text: node.text, number: node.number)
    for k in 0 ..< node.children.len:
      if not node.children[k].isDropped: result.children.add node.children[k].kept

  if not nif.startsWith(HEADER):
    return refused(none(int), none(int), "NIF should open with directives `nif.nim` writes")
  var module: seq[NodeNif]
  try: module = nif.readModule
  except ValueError as error: return refused(none(int), none(int), error.msg)

  # Last `su` of root: nodes before it stand in text it erases.
  var
    su = DIRECTIVES - 1
    closer = none(int)
    is_quoted_next = false
  for k in DIRECTIVES ..< module.len:
    if module[k].isUnit(RefusalText.Su.spelling): su = k
    module[k].addCloser(closer, is_quoted_next)
  for k in DIRECTIVES ..< module.len:
    if k == su: continue
    let error = module[k].firstError(is_erased = k < su, closer)
    if error.isSome:
      return refused(some(k - DIRECTIVES), some(error.get.start), error.get.reason)

  # Rebuild each part past it, with units one pass holds no word of left out.
  var
    terminals: seq[TerminalNif]
    classes: seq[Terminal]
    parts: seq[Node]
  for k in su + 1 ..< module.len:
    if module[k].isDropped: continue
    try:
      parts.add module[k].kept.toTree(terminals)
      for m in classes.len ..< terminals.len: classes.add terminals[m].terminal.toTerminal
    except ValueError as error: return refused(some(k - DIRECTIVES), none(int), error.msg)

  # Tree of text, from trees of parts, else from terminals read whole.
  var tree = classes.assembleText(parts)
  if tree.isNone:
    var reading = classes.readGrammar
    if not reading.is_read:
      let start =
        if reading.at < terminals.len: terminals[reading.at].words[0].start
        elif terminals.len > 0: terminals[^1].words[^1].finish
        else: 0
      return refused(
        none(int), some(start), "grammar of 21.1 refuses text whole, in rule `" &
          reading.rule & "`",
      )
    tree = some(move(reading.tree))
  MergeNif(is_merged: true, nif: tree.get.toNif(LeavesNif(terminals: terminals)))
