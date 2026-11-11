## Read module of NIF data format, version 2027, by grammar `doc/nif-spec.md` of
##   `nim-lang/nifspec` writes at `a31513c6`, so suites hold `nif.nim` to spec, never to itself;
##   give module each reading should read as, so law of suite is reader of what writer writes.
##   Reader takes subset of NIF: directive, compound node, identifier as tag or as atom, integer
##     of decimal digits, string literal, escape `\xx` and its five shortcuts, whitespace between
##     them. Every other construct is refused, as symbol, char literal, empty node, line
##     information and comment; writer writes none, so what reader takes is NIF, and no more.
##   Grammar of spec this reader follows:
##     IdentStart is letter, `_`, byte from 128, or escape; IdentChar adds digit (Identifiers).
##     Escape is `\` with two hex digits of upper case, or one of `n t r | ^` (Escape sequences).
##     String literal holds byte from 32 that is no control character, byte from 128, `#`, `:`,
##       whitespace and escape, between `"` (String literals).
##     Compound node is `(`, tag, nodes, `)`; directive is `(.name ...)` (Directives); node is
##       atom or compound node, and identifier is atom (Atoms).
##     Version directive opens module, with no byte before it (Version directive).
##   Token ends at whitespace, at parenthesis, or at end of module; byte after it, as `@` of
##     line information or `#` of comment, is refused.
##   Module of reading is model of format `nif.nim` gives in its header: directives, then each
##     chain by its two ends, tag and number of each rule closing chain, and class, byte and words
##     of each terminal; for reading that marks each error, error node and unit no terminal
##     holds too. Writer gives text, and model gives nodes, so neither checks itself.
##   Rebuild reads module back into tree and terminals: each rule between two ends of chain from
##     `LUT_CHAIN_BY_ENDS`, `-` for `_` of tag, `'` for `h` of word. So law holds that format loses
##     nothing of tree, not just that writer and model agree.
##   Suites of native and JavaScript builds read same reader, model and worked example, so each
##     is written once (II.9).
##   Refusal raises `ValueError`, naming byte and what NIF asks there.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, tables]

import ../../src/lojban_parser/[grammar, nif, prose, selmaho, stream]


type
  KindNif* {.pure.} = enum  ## Define kind of node reader gives.
    Compound  ## Compound node, `(tag child ...)`; directive too, whose tag opens with `.`.
    Identifier  ## Identifier standing as atom, as `sumti_6` of error node.
    Number  ## Integer, as `97`.
    Literal  ## String literal, as `"mi"`.

  NodeNif* = object  ## Define node of NIF as read, each escape decoded.
    kind*: KindNif
    text*: string  ## Tag of compound node, identifier, or bytes of string literal; else empty.
    number*: int  ## Value of integer; zero otherwise.
    children*: seq[NodeNif]  ## Nodes compound node holds, in order; empty otherwise.

  Reader = object  ## Define module being read, and byte reader stands at.
    text: string
    at: int

  TerminalNif* = tuple[terminal: string, start: int, words: seq[string]]
    ## Define terminal as module gives it back: class, byte where first word opens, letters; unit
    ##   no terminal holds gives `unread`, then stage, then refusal of stream for stage `Stream`.


const
  WHITESPACE = {' ', '\t', '\n', '\r'}  ## Whitespace of NIF, which parts tokens (Whitespace).
  CONTROLS = {'(', ')', '[', ']', '{', '}', '~', '#', '\'', '"', '\\', ':', '@'}
    ## Control characters of NIF (Control characters).
  OPENERS_IDENTIFIER = {'a'..'z', 'A'..'Z', '_', '\x80'..'\xFF'}
    ## Bytes opening identifier, escape aside (IdentStart).
  DIGITS = {'0'..'9'}
  HEX = {'0'..'9', 'A'..'F'}  ## Digits of escape, upper case alone (Escape sequences).
  SHORTCUTS = [('n', '\n'), ('t', '\t'), ('r', '\r'), ('|', '\\'), ('^', '"')]
    ## Shortcut of escape, with byte it gives (Escape sequences).
  VERSION* = "(.nif27)"  ## Version directive, which opens module with no byte before it.
  EXAMPLE_NIF* = (
    text: "me'o vo",  # Example 6.98 of CLL 1.1
    module: "(.nif27)\n(.lang \"cll-21.1\")\n" &
      "(sumti_6 0 97 (LI 0 \"meho\") (number 310 812 (PA 5 \"vo\")))\n",
  )
    ## Text, and module `nif.nim` writes for it, byte for byte: chain from `text` 0 to `sumti-6`
    ##   97 is one node, and so is chain from `mex` 310 to `number` 812; tag `sumti-6` takes `_`,
    ##   and word `me'o` takes `h`.



func refuse(reader: Reader, expected: string) {.noreturn.} =
  ## Refuse module at byte reader stands at, naming what NIF asks there.
  let found =
    if reader.at < reader.text.len: "`" & reader.text[reader.at] & "`" else: "end of module"
  raise newException(
    ValueError, "NIF should hold " & expected & " at byte " & $reader.at & "; got " & found & "."
  )


func isAt(reader: Reader, bytes: set[char]): bool =
  ## Decide whether reader stands at byte of set; false at end of module.
  reader.at < reader.text.len and reader.text[reader.at] in bytes


func skipWhitespace(reader: var Reader) =
  ## Move reader past whitespace.
  while reader.isAt(WHITESPACE): inc reader.at


func endToken(reader: Reader) =
  ## Refuse byte after token, unless whitespace, parenthesis, or end of module stands there.
  if reader.at < reader.text.len and not reader.isAt(WHITESPACE + {'(', ')'}):
    reader.refuse("end of token")


func readEscape(reader: var Reader): char =
  ## Read escape after its `\`: two hex digits of upper case, or shortcut.
  if reader.isAt(HEX) and reader.at + 1 < reader.text.len and reader.text[reader.at + 1] in HEX:
    result = char(parseHexInt(reader.text[reader.at .. reader.at + 1]))
    reader.at += 2
    return
  for (shortcut, decoded) in SHORTCUTS:
    if reader.isAt({shortcut}):
      inc reader.at
      return decoded
  reader.refuse("escape of two hex digits, or shortcut")


func readIdentifier(reader: var Reader): string =
  ## Read identifier: opener or escape first, then digit among them (Identifiers).
  while reader.at < reader.text.len:
    let c = reader.text[reader.at]
    if c == '\\':
      inc reader.at
      result.add reader.readEscape
    elif c in OPENERS_IDENTIFIER or (c in DIGITS and result.len > 0):
      result.add c
      inc reader.at
    else: break
  if result.len == 0: reader.refuse("identifier")


func readNumber(reader: var Reader): int =
  ## Read integer of decimal digits, with `-` before it where negative (Numbers).
  let start = reader.at
  if reader.isAt({'-'}): inc reader.at
  if not reader.isAt(DIGITS): reader.refuse("digit")
  while reader.isAt(DIGITS): inc reader.at
  parseInt(reader.text[start ..< reader.at])


func readLiteral(reader: var Reader): string =
  ## Read string literal after its `"`, up to `"` closing it (String literals).
  while true:
    if reader.at >= reader.text.len: reader.refuse("`\"` closing string literal")
    let c = reader.text[reader.at]
    if c == '"':
      inc reader.at
      return
    if c == '\\':
      inc reader.at
      result.add reader.readEscape
    elif c in WHITESPACE or c in {'#', ':'} or ord(c) >= 128 or
        (ord(c) >= ord(' ') and c notin CONTROLS):
      result.add c
      inc reader.at
    else: reader.refuse("byte that string literal holds")


func readNode(reader: var Reader): NodeNif =
  ## Read node: compound node with nodes it holds, identifier, integer, or string literal.
  if reader.isAt({'('}):
    inc reader.at
    var tag = ""
    if reader.isAt({'.'}):
      inc reader.at
      tag.add '.'
    tag.add reader.readIdentifier
    reader.endToken
    result = NodeNif(kind: KindNif.Compound, text: tag)
    while true:
      reader.skipWhitespace
      if reader.isAt({')'}): break
      if reader.at >= reader.text.len: reader.refuse("`)` closing node")
      result.children.add reader.readNode
    inc reader.at
  elif reader.isAt({'"'}):
    inc reader.at
    result = NodeNif(kind: KindNif.Literal, text: reader.readLiteral)
  elif reader.isAt(DIGITS + {'-'}):
    result = NodeNif(kind: KindNif.Number, number: reader.readNumber)
  elif reader.isAt(OPENERS_IDENTIFIER + {'\\'}):
    result = NodeNif(kind: KindNif.Identifier, text: reader.readIdentifier)
  else: reader.refuse("node")
  reader.endToken


func readModule*(text: string): seq[NodeNif] =
  ## Read module of NIF: version directive at its first byte, then nodes up to end (Modules).
  var reader = Reader(text: text)
  if not text.startsWith(VERSION): reader.refuse("version directive `" & VERSION & "`")
  while true:
    reader.skipWhitespace
    if reader.at >= text.len: break
    result.add reader.readNode



#[ Model ]#

func letters(occurrence: Occurrence): string =
  ## Give letters string literal of occurrence holds: word with `h` for each `'`, or text
  ##   quotation holds, or written word stream refuses, as it is.
  if occurrence.reading.is_word: occurrence.text.replace('\'', 'h') else: occurrence.text


func byteStop(reading: ReadingMarked, at: int): int =
  ## Give byte grammar stops at, from unit `at`: byte where unit opens, or size of text at end.
  if at < reading.units.len: reading.occurrences[reading.units[at].words[0]].start
  else: reading.size


func toNodeNif(node: Node, top: int, reading: ReadingText | ReadingMarked): NodeNif =
  ## Give node of NIF that node of tree should read as: rule holding rule alone passes on to it,
  ##   as chain opening at `top`; rule closing chain gives tag, `top` where chain stands, its
  ##   number, then its nodes; terminal gives class, byte where its first word opens, and letters.
  ##   Error node gives `error`, byte grammar stops at, rule and number, `expects` with classes,
  ##     then its nodes, and closes chain above it; unit no terminal holds gives `unread`, byte,
  ##     stage, refusal of stream for stage `Stream`, and letters.
  if node.is_terminal:
    template unit: untyped = reading.units[node.at]
      ## Alias unit of terminal, which `let` would copy on JavaScript backend.
    result = NodeNif(
      kind: KindNif.Compound, text: (if unit.is_read: $unit.terminal else: "unread")
    )
    result.children.add NodeNif(
      kind: KindNif.Number, number: reading.occurrences[unit.words[0]].start
    )
    if not unit.is_read:
      result.children.add NodeNif(kind: KindNif.Identifier, text: $unit.refusal)
      if unit.refusal == RefusalText.Stream:
        let refusal = $reading.occurrences[unit.words[0]].reading.refusal
        result.children.add NodeNif(kind: KindNif.Identifier, text: refusal)
    for k in 0 ..< unit.words.len:
      result.children.add NodeNif(
        kind: KindNif.Literal, text: reading.occurrences[unit.words[k]].letters
      )
    return
  let is_chain = node.stop.isNone and node.children.len == 1 and
    not node.children[0].is_terminal and node.children[0].stop.isNone
  if is_chain: return node.children[0].toNodeNif(top, reading)
  let tag = node.rule.replace('-', '_')
  if node.stop.isSome:
    when reading is ReadingMarked:
      result = NodeNif(kind: KindNif.Compound, text: "error")
      result.children.add NodeNif(
        kind: KindNif.Number, number: reading.byteStop(node.stop.get.at)
      )
      result.children.add NodeNif(kind: KindNif.Identifier, text: tag)
      result.children.add NodeNif(kind: KindNif.Number, number: node.number)
      var expects = NodeNif(kind: KindNif.Compound, text: "expects")
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
  ##   `-` for each `_` of tag; terminal adds class, byte and words to `terminals`, `'` for each
  ##   `h` of word, and third string of `ZOI` as it is. Error node takes byte grammar stops at as
  ##   its place; unit `unread` adds `unread` and its identifiers, and keeps letters of stage
  ##   `Stream` as they are.
  if node.children.len > 0 and node.children[^1].kind == KindNif.Literal:
    var
      terminal = node.text
      k = 1
    while node.children[k].kind == KindNif.Identifier:
      terminal.add ' '
      terminal.add node.children[k].text
      inc k
    let is_kept = terminal.startsWith("unread Stream")
    var words: seq[string]
    for m in k ..< node.children.len:
      let
        literal = node.children[m].text
        is_quoted = node.text == "ZOI" and m == 3
      words.add (if is_kept or is_quoted: literal else: literal.replace('h', '\''))
    terminals.add (terminal: terminal, start: node.children[0].number, words: words)
    return Node(is_terminal: true, at: terminals.high)
  if node.text == "error":
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
  ## Give terminals reading holds: class, byte where first word opens, and letters of each word;
  ##   unit no terminal holds gives `unread`, stage, and refusal of stream for stage `Stream`.
  for k in 0 ..< reading.units.len:
    template unit: untyped = reading.units[k]
      ## Alias unit, which `let` would copy on JavaScript backend.
    var
      terminal = (if unit.is_read: $unit.terminal else: "unread " & $unit.refusal)
      words: seq[string]
    if not unit.is_read and unit.refusal == RefusalText.Stream:
      terminal.add " " & $reading.occurrences[unit.words[0]].reading.refusal
    for m in 0 ..< unit.words.len: words.add reading.occurrences[unit.words[m]].text
    result.add (terminal: terminal, start: reading.occurrences[unit.words[0]].start, words: words)


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
