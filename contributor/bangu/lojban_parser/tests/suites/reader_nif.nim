## Give module of NIF each reading should read as, and read module back into tree, so law of
##   suite is reader of what writer writes; reader of spec is `nif_read.nim` of library, which
##   page reads NIF through too.
##   Module of reading is model of format `nif.nim` gives in its header: directives, then each
##     chain by its two ends, tag and number of each rule closing chain, and class of each terminal
##     with bytes and letters of each word; for reading that marks each error, error node and unit
##     no terminal holds too. Writer gives text, and model gives nodes, so neither checks itself.
##   Rebuild reads module back into tree and terminals: each rule between two ends of chain from
##     `LUT_CHAIN_BY_ENDS`, `-` for `_` of tag, `'` for `h` of word. So law holds that format loses
##     nothing of tree, not just that writer and model agree.
##   Law of cover (`isCovering`) holds tree to bytes of text: each byte of each word lies in one
##     leaf, leaves follow text, and each other byte is mark between words; suites of marks and
##     of live text read it.
##   Suites of native and JavaScript builds read same reader, model and worked example, so each
##     is written once (II.9).

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, tables]

import ../../src/lojban_parser/[grammar, nif, nif_read, prose, selmaho, stream, tanru]

export nif_read


type
  WordNif* = tuple[start, finish: int, letters: string]
    ## Define word as module gives it back: byte where it opens, byte past it, and its letters.

  TerminalNif* = tuple[terminal: string, words: seq[WordNif]]
    ## Define terminal as module gives it back: class, then each word; unit no terminal holds
    ##   gives `rivbi`, then stage, then refusal of stream for stage `Stream`.


const
  TAG_ERROR = "srera"  ## Tag of error node, gismu of rulings on #859, as model gives it.
  TAG_EXPECTS = "nitcu"  ## Tag of terminals grammar reads where it stops, as model gives it.
  TAG_UNREAD = "rivbi"  ## Tag of unit no terminal holds, as model gives it.
  EXAMPLE_NIF* = (
    text: "me'o vo",  # Example 6.98 of CLL 1.1
    module: "(.nif27)\n(.lang \"cll-21.1\")\n" &
      "(sumti_6 0 97 (LI 0 4 \"meho\") (number 310 812 (PA 5 7 \"vo\")))\n",
  )
    ## Text, and module `nif.nim` writes for it, byte for byte: chain from `text` 0 to `sumti-6`
    ##   97 is one node, and so is chain from `mex` 310 to `number` 812; tag `sumti-6` takes `_`,
    ##   and word `me'o` takes `h`.



#[ Model ]#

func letters(occurrence: Occurrence): string =
  ## Give letters string literal of occurrence holds: word with `h` for each `'`, or text
  ##   quotation holds, or written word stream refuses, as it is.
  if occurrence.reading.is_word: occurrence.text.replace('\'', 'h') else: occurrence.text


func spelled(stage: RefusalText): string =
  ## Give tag stage should read as: selma'o as chapter 20 names it, lojban word in lower case,
  ##   English term of CLL as it stands (rulings on #859).
  case stage
  of RefusalText.Su: "SU"
  of RefusalText.Faho: "FAhO"
  of RefusalText.Selmaho: "selmaho"
  else: $stage


func spelled(refusal: Refusal): string =
  ## Give tag refusal of stream should read as, spelled as stage is.
  case refusal
  of Refusal.Faho: "FAhO"
  of Refusal.Slinkuhi: "slinkuhi"
  else: $refusal


func byteStop(reading: ReadingMarked, at: int): int =
  ## Give byte grammar stops at, from unit `at`: byte where unit opens, or size of text at end.
  if at < reading.units.len: reading.occurrences[reading.units[at].words[0]].start
  else: reading.size


func toNodeNif(node: Node, top: int, reading: ReadingText | ReadingMarked): NodeNif =
  ## Give node of NIF that node of tree should read as: rule holding rule alone passes on to it,
  ##   as chain opening at `top`; rule closing chain gives tag, `top` where chain stands, its
  ##   number, then its nodes; terminal gives class, then bytes and letters of each word.
  ##   Error node gives `srera`, byte grammar stops at, rule and number, `nitcu` with classes,
  ##     then its nodes, and closes chain above it; unit no terminal holds gives `rivbi`, stage,
  ##     refusal of stream for stage `Stream`, then its words.
  if node.is_terminal:
    template unit: untyped = reading.units[node.at]
      ## Alias unit of terminal, which `let` would copy on JavaScript backend.
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
        ## Alias word of unit, which `let` would copy on JavaScript backend.
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
      result.children.add NodeNif(kind: KindNif.Number, number: node.number)
      var expects = NodeNif(kind: KindNif.Compound, text: TAG_EXPECTS)
      for terminal in node.stop.get.expected:
        expects.children.add NodeNif(kind: KindNif.Identifier, text: $terminal)
      result.children.add expects
    else:
      doAssert false, "Reading that reads should hold no error node."
  else:
    result = NodeNif(kind: KindNif.Compound, text: tag)
    if top != node.number: result.children.add NodeNif(kind: KindNif.Number, number: top)
    result.children.add NodeNif(kind: KindNif.Number, number: node.number)
  for k in 0 ..< node.children.len:
    let top_child = (if node.children[k].is_terminal: 0 else: node.children[k].number)
    result.children.add node.children[k].toNodeNif(top_child, reading)


func toModule*(reading: ReadingText | ReadingMarked): seq[NodeNif] =
  ## Give module that NIF of reading should read as: version, language, then tree.
  @[
    NodeNif(kind: KindNif.Compound, text: ".nif27"),
    NodeNif(
      kind: KindNif.Compound, text: ".lang",
      children: @[NodeNif(kind: KindNif.Literal, text: "cll-21.1")],
    ),
    reading.tree.toNodeNif(reading.tree.number, reading),
  ]



#[ Rebuild ]#

func toTerminal(name: string): Terminal =
  ## Read class of terminal back from its name, as `KOhA` or `BRIVLA`.
  if name == $TERMINAL_BRIVLA: return TERMINAL_BRIVLA
  if name == $TERMINAL_CMENE: return TERMINAL_CMENE
  let selmaho = name.toSelmaho
  doAssert selmaho.isSome, "Class of terminal should name selma'o; got `" & name & "`."
  selmaho.get.toTerminal


func toTree(node: NodeNif, terminals: var seq[TerminalNif]): Node =
  ## Rebuild node of tree from node of NIF: each chain from its two ends by `LUT_CHAIN_BY_ENDS`,
  ##   `-` for each `_` of tag; terminal adds class and words to `terminals`, `'` for each `h` of
  ##   word, and third string of `ZOI` as it is. Error node takes byte grammar stops at as
  ##   its place; unit `rivbi` adds `rivbi` and its identifiers, and keeps letters of stage
  ##   `Stream` as they are.
  if node.children.len > 0 and node.children[^1].kind == KindNif.Literal:
    var
      terminal = node.text
      k = 0
    while node.children[k].kind == KindNif.Identifier:
      terminal.add ' '
      terminal.add node.children[k].text
      inc k
    let is_kept = terminal.startsWith(TAG_UNREAD & " Stream")
    var words: seq[WordNif]
    for m in countup(k, node.children.high, 3):
      let
        literal = node.children[m + 2].text
        is_quoted = node.text == "ZOI" and m == k + 6
        letters = (if is_kept or is_quoted: literal else: literal.replace('h', '\''))
      words.add (node.children[m].number, node.children[m + 1].number, letters)
    terminals.add (terminal: terminal, words: words)
    return Node(is_terminal: true, at: terminals.high)
  if node.text == TAG_ERROR:
    var expected: seq[Terminal]
    for class in node.children[3].children: expected.add class.text.toTerminal
    result = Node(
      is_terminal: false, rule: node.children[1].text.replace('_', '-'),
      number: node.children[2].number,
      stop: some(Stop(at: node.children[0].number, expected: expected)),
    )
    for k in 4 ..< node.children.len: result.children.add node.children[k].toTree(terminals)
    return
  var count = 0
  while count < node.children.len and node.children[count].kind == KindNif.Number: inc count
  result = Node(
    is_terminal: false, rule: node.text.replace('_', '-'), number: node.children[count - 1].number
  )
  for k in count ..< node.children.len: result.children.add node.children[k].toTree(terminals)
  if count == 2:
    let chain = LUT_CHAIN_BY_ENDS[(node.children[0].number, node.children[1].number)]
    for k in countdown(chain.len - 2, 0):
      result = Node(
        is_terminal: false, rule: chain[k].rule, number: chain[k].number, children: @[result]
      )


func toTerminals(reading: ReadingText | ReadingMarked): seq[TerminalNif] =
  ## Give terminals reading holds: class, then bytes and letters of each word; unit no terminal
  ##   holds gives `rivbi`, stage, and refusal of stream for stage `Stream`.
  for k in 0 ..< reading.units.len:
    template unit: untyped = reading.units[k]
      ## Alias unit, which `let` would copy on JavaScript backend.
    var
      terminal = (if unit.is_read: $unit.terminal else: TAG_UNREAD & " " & unit.refusal.spelled)
      words: seq[WordNif]
    if not unit.is_read and unit.refusal == RefusalText.Stream:
      terminal.add " " & reading.occurrences[unit.words[0]].reading.refusal.spelled
    for m in 0 ..< unit.words.len:
      template word: untyped = reading.occurrences[unit.words[m]]
        ## Alias word of unit, which `let` would copy on JavaScript backend.
      words.add (word.start, word.finish, word.text)
    result.add (terminal: terminal, words: words)


func isSame(a, b: Node, reading: ReadingText | ReadingMarked): bool =
  ## Decide whether tree of reading `a`, and tree `b` rebuilt, hold same rules, numbers and
  ##   terminals, in same order; and same place grammar stops at, which `b` holds as byte.
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
  ## Add index of each leaf under node to `leaves`, in order of tree.
  if node.is_terminal:
    leaves.add node.at
    return
  for k in 0 ..< node.children.len: node.children[k].addLeaves(leaves)


func isCovering*(marked: ReadingMarked, text: string): bool =
  ## Decide whether each byte of each word of text lies in one leaf of tree, leaves follow order
  ##   of text by their first byte, and each byte no leaf holds is mark between words, or comma
  ##   between two words of one written word (3.3).
  var
    counts = newSeq[int](text.len)  # leaves holding each byte
    last = -1  # first byte of leaf before
  var leaves: seq[int]
  marked.tree.addLeaves(leaves)
  for u in leaves:
    template unit: untyped = marked.units[u]
      ## Alias unit, which `let` would copy.
    let first = marked.occurrences[unit.words[0]].start
    if first <= last: return false
    last = first
    for w in unit.words:
      template word: untyped = marked.occurrences[w]
        ## Alias word, which `let` would copy.
      if word.start > word.finish or word.finish > text.len: return false  # empty text quoted
      for b in word.start ..< word.finish: inc counts[b]
  for b in 0 ..< text.len:
    if counts[b] > 1: return false
    if counts[b] == 0 and text[b] notin MARKS_BOUNDARY and text[b] != ',': return false
  true


func isReadBack*(reading: ReadingText | ReadingMarked): bool =
  ## Decide whether NIF of reading reads as model of format gives it, and rebuilds tree and
  ##   terminals of reading whole: law both suites hold.
  var module: seq[NodeNif]
  try: module = reading.toNif.readModule
  except ValueError: return false
  if module != reading.toModule: return false
  var terminals: seq[TerminalNif]
  let tree = module[^1].toTree(terminals)
  reading.tree.isSame(tree, reading) and terminals == reading.toTerminals
