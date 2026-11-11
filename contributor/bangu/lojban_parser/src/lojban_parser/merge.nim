## Merge parts of text from their NIF into NIF one pass gives text they read, so program that
##   holds NIF alone, as page or fixer, gives tree of one pass (ruling `D1 b` on #859); where
##   error stays, merge each run of parts around it, and refuse no error (ruling after it there).
##
##   |------------|------------------------------------------------------------------|
##   | Code       | Meaning                                                          |
##   |------------|------------------------------------------------------------------|
##   | toTerminal | class of terminal, read back from its name                       |
##   | toTree     | node of tree rebuilt from node of NIF, with terminals it holds   |
##   | MergeNif   | module of trees merge gives, or refusal of NIF that reads not    |
##   | mergeParts | NIF of trees one pass gives text, from NIF of its parts          |
##   |------------|------------------------------------------------------------------|
##
##   Parts: each node of module past its directives, as `toNifParts` writes them, and as live
##     text gives them once each part goes out (`live.nim`).
##   Rebuild: each rule between two ends of chain from `LUT_CHAIN_BY_ENDS`, `-` for `_` of tag,
##     `'` for `h` of word, save text `zoi` quotes and written word stream refuses; error node
##     takes byte grammar stops at as its place (`nif.nim`). Node of shape writer gives not
##     raises `ValueError`, and merge refuses its module, naming node.
##   Drop, as one pass reads text (19.13, 19.15): each unit of stage `Erasure`, wherever it
##     stands; `fa'o` that ends input, and each written word after it; each node of root up to
##     last `su`, which stands in root alone. Unit there that one pass refuses text for stays,
##     each in front: unit stream refuses, `si` or `sa` erasing nothing, and `lo'u` no `le'u`
##     closes, since 19.16 reads them before `su` erases. Unit `lo'u` holds alone tells `le'u`
##     past it that no `zo` quotes, and no `ZOI` terminal holds, from none (19.9, 19.10).
##   Merge: run of adjacent parts past last `su` that hold no error node merges to one tree, as
##     one pass reads text of run: `assembleText` builds it from trees of parts, else grammar
##     reads terminals whole, and where it stops, error node holds trees of parts, as marked
##     reading of one pass gives them (`readGrammarMarked`). Unit some
##     stage refuses stands in lowest node holding units read around it, as marked reading of
##     one pass places it (`placeRefused` of `prose.nim`), so it parts no run.
##   Part holding error node of grammar stays as it is, between runs: marked reading of one
##     pass keeps each part apart under error node, so grammar gives it no place in tree.
##   So merge gives NIF `readText` writes, byte for byte, where no error stays (`is_whole`),
##     and tree of each run as one pass reads it where error stays (`test_merge.nim`).
##   Cost: rebuild and merge grow with length of NIF; grammar reads terminals of run whole only
##     where rule of passes breaks.
##   Merge loops by index, since `items` and binding of node copy it on JavaScript backend.

{.experimental: "strictFuncs".}

import std/[options, strutils, tables]

import ./[dictionary, grammar, nif, nif_read, prose, selmaho, tanru]


type
  MergeNif* = object  ## Define outcome of merge of parts: module of trees, or refusal of NIF.
    case is_merged*: bool
    of true:
      nif*: string
        ## Module of NIF of merge: each unit before last `su` one pass refuses text for, then
        ##   tree of each run of parts that holds no error node, and each part that holds one,
        ##   in order of text, each on line of its own.
      is_whole*: bool
        ## Module holds one tree, and no error node nor unit refused: NIF `readText` writes.
    of false:
      part*: Option[int]
        ## Node of module refused, counted from 0 past directives; none where NIF reads not.
      reason*: string  ## What NIF should hold.


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


func isHoldingError(node: NodeNif): bool =
  ## Decide whether node of NIF holds error node of grammar, at any depth.
  if node.kind != KindNif.Compound: return false
  if node.text == TAG_ERROR: return true
  for k in 0 ..< node.children.len:
    if node.children[k].isHoldingError: return true


func reach(node: NodeNif): int =
  ## Give byte past last word node of NIF holds, at any depth; 0 where it holds none.
  if node.kind != KindNif.Compound: return 0
  for k in 0 ..< node.children.len:
    template child: untyped = node.children[k]
      ## Alias node, which `let` would copy on JavaScript backend.
    if child.kind == KindNif.Literal and k >= 1 and node.children[k - 1].kind == KindNif.Number:
      result = max(result, node.children[k - 1].number)
    elif child.kind == KindNif.Compound: result = max(result, child.reach)


func isRefused(terminal: TerminalNif): bool =
  ## Decide whether terminal NIF gave back is unit no terminal holds, which some stage refuses.
  terminal.terminal.startsWith(TAG_UNREAD)


func mergedRun(
    trees: openArray[Node], span: Slice[int], terminals: openArray[TerminalNif], ending: int
): Node =
  ## Merge run of trees rebuilt from parts that hold no error node into one tree, as marked
  ##   reading of one pass reads their text, whose terminals are `span`: grammar reads
  ##   terminals that read, and each unit some stage refuses stands in lowest node holding
  ##   units read around it (`placeRefused` of `prose.nim`). Where trees of parts build no
  ##   tree, grammar reads terminals whole, and where it stops, error node holds trees of parts
  ##   (`readGrammarMarked`); it stops at byte where its terminal opens, or at `ending`.
  func indexed(node: Node, indexes: openArray[int], is_kept: openArray[bool]): Node =
    ## Give node with each leaf `is_kept` refuses left out, and each other leaf at `indexes`.
    if node.is_terminal: return Node(is_terminal: true, at: indexes[node.at])
    result = Node(is_terminal: false, rule: node.rule, number: node.number, stop: node.stop)
    for k in 0 ..< node.children.len:
      template child: untyped = node.children[k]
        ## Alias node, which `let` would copy on JavaScript backend.
      if not child.is_terminal or is_kept[child.at]:
        result.children.add child.indexed(indexes, is_kept)

  func placed(node: var Node, globals: openArray[int], terminals: openArray[TerminalNif],
      ending: int) =
    ## Index each leaf of node among terminals by `globals`, and give each place grammar stops
    ##   at as byte where its terminal opens, or `ending` past last terminal, as NIF writes it.
    if node.is_terminal:
      node.at = globals[node.at]
      return
    if node.stop.isSome:
      let at = node.stop.get.at
      node.stop.get.at =
        if at < globals.len: terminals[globals[at]].words[0].start else: ending
    for k in 0 ..< node.children.len: node.children[k].placed(globals, terminals, ending)

  var
    reads = newSeq[bool](terminals.len)  # terminal of grammar, by index
    indexes = newSeq[int](terminals.len)  # index among terminals read, by index
    globals: seq[int]  # index of each terminal read, in order
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
  result = (if built.isSome: built.get else: classes.readGrammarMarked)  # copy: `move` breaks JS
  result.placed(globals, terminals, ending)
  result.placeRefused(reads, span)


func mergeParts*(nif: string): MergeNif =
  ## Give NIF of trees one pass gives text, from NIF of its parts, as `toNifParts` writes it and
  ##   live text gives it: drop each unit one pass holds no word of, and each node of root up to
  ##   last `su`, save unit one pass refuses text for; merge each run of parts that holds no
  ##   error node, as one pass reads it, and keep each part that holds one as it is.
  func refused(part: Option[int], reason: string): MergeNif =
    MergeNif(is_merged: false, part: part, reason: reason)

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

  func addFatal(node: NodeNif, closer: Option[int], units: var seq[NodeNif]) =
    ## Add each unit node holds that one pass refuses text for, though `su` past it erases it:
    ##   unit stream refuses, `si` or `sa` erasing nothing, or `lo'u` no `le'u` closes, as no
    ##   `le'u` past it that `closer` gives stands: stream reads `su` after it as word it quotes.
    if node.kind != KindNif.Compound or node.isDropped: return
    if node.text != TAG_UNREAD:
      for k in 0 ..< node.children.len: node.children[k].addFatal(closer, units)
      return
    if node.children.len == 0: return
    var start = 0  # first byte unit writes, past its identifiers
    while start < node.children.len and node.children[start].kind != KindNif.Number: inc start
    var is_closed = false  # unit holds `le'u`, or `le'u` stands past it
    for k in start ..< node.children.len:
      template child: untyped = node.children[k]
        ## Alias node, which `let` would copy on JavaScript backend.
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
    ## Give node with each unit one pass holds no word of left out, at any depth.
    result = NodeNif(kind: node.kind, text: node.text, number: node.number)
    for k in 0 ..< node.children.len:
      if not node.children[k].isDropped: result.children.add node.children[k].kept

  if not nif.startsWith(HEADER):
    return refused(none(int), "NIF should open with directives `nif.nim` writes")
  var module: seq[NodeNif]
  try: module = nif.readModule
  except ValueError as error: return refused(none(int), error.msg)

  # Last `su` of root: nodes before it stand in text it erases, save unit one pass refuses.
  var
    su = DIRECTIVES - 1
    closer = none(int)
    is_quoted_next = false
    fatal: seq[NodeNif]
  for k in DIRECTIVES ..< module.len:
    if module[k].isUnit(RefusalText.Su.spelling): su = k
    module[k].addCloser(closer, is_quoted_next)
  for k in DIRECTIVES ..< su: module[k].addFatal(closer, fatal)
  var faho = none(int)  # byte where `fa'o` that ends input opens
  for k in su + 1 ..< module.len:
    let is_faho = module[k].isUnit(RefusalText.Faho.spelling) and module[k].children.len > 1 and
      module[k].children[1].kind == KindNif.Number
    if is_faho and faho.isNone: faho = some(module[k].children[1].number)

  # Rebuild each unit kept before `su`, then each node past it, each class of terminal read.
  var
    terminals: seq[TerminalNif]
    rebuilt: seq[tuple[tree: Node, span: Slice[int], has_error: bool, reach: int]]
      # reach: byte past last word node holds, or unit dropped after it
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

  # Merge each run of nodes that hold no error node; keep each that holds one as it is. Grammar
  #   that stops past last terminal of run stops at `fa'o` past it, else past last word of run,
  #   erased words among them, as marked reading stops where text ends.
  var
    trees: seq[Node]
    run: seq[Node]
    span = 0 ..< 0  # terminals of run
    ending = 0  # byte past last word of run
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
  var is_whole = trees.len == 1 and trees[0].stop.isNone  # error node of run stands at root
  for m in 0 ..< terminals.len: is_whole = is_whole and not terminals[m].isRefused
  MergeNif(is_merged: true, nif: trees.toNif(LeavesNif(terminals: terminals)), is_whole: is_whole)
