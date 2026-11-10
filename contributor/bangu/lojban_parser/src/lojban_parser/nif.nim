## Write tree of text as module of NIF data format, version 2027 of `nim-lang/nifspec`, so that
##   other programs read it: Nim 3 holds its own trees in NIF (ruling `D1 c` of #852).
##
##   |---------|-------------------------------------------------------------|
##   | Code    | Meaning                                                     |
##   |---------|-------------------------------------------------------------|
##   | toNif   | module of NIF holding tree of reading, each word in place   |
##   |---------|-------------------------------------------------------------|
##
##   Module opens with directive `(.nif27)`, with no byte before it, then `(.lang "cll-21.1")`:
##     tags are names of rules of 21.1 and classes of terminals, as grammar spells them.
##   Named rule is compound node: tag is its name, then its number in 21.1, then nodes it holds.
##   Chain of rules, each holding next alone, is one node: number of rule opening it, then tag and
##     number of rule closing it, as `(sumti_6 80 97 ...)` from `terms` 80 down to `sumti-6` 97.
##     Two ends give one chain in 21.1 (`LUT_CHAIN_BY_ENDS`), so reader rebuilds each rule between
##     them, and tree reads back whole.
##   Terminal is compound node: tag is its class, as `KOhA` or `BRIVLA`; then, for each word, byte
##     where it opens, byte past its last letter, and its letters as string literal, as
##     `(BU 15 17 "ta" 18 20 "bu")`. So each word ties to bytes of text it reads from. Order of
##     terminals in tree gives index of each unit, so node holds none.
##   Named rule writes no byte: it spans bytes of leaves under it, which reader takes from them.
##     Cost: byte past each word adds 7% to modules of corpora (PROVENANCE.md, NIF); byte where
##       word opens alone was rejected, since reader could not tell where word ends from letters
##       alone, as comma and capital write bytes letters drop.
##   Reading that marks each error (`readTextMarked`, #859) writes two nodes more:
##     Error node: tag `error`, byte where grammar stops, tag and number of rule stopping
##       innermost there, then `(expects ...)` holding class of each terminal some derivation
##       reads there, then nodes it holds. Chain stops above it, as no chain of 21.1 holds it.
##     Unit no terminal holds: tag `unread`, stage refusing it as identifier, as `Selmaho`, then
##       bytes and letters of each word, as terminal writes them. Stage `Stream` adds refusal of
##       stream, as `Letter`, and written word it refuses keeps its bytes, as text `zoi` quotes
##       does: no `h` for `'`, and `'` takes escape. Stage alone was rejected, since stream and
##       grammar of quotation both name refusal `Quotation`, so reader could not tell bytes from
##       word.
##     Unit of stage `Su`, `Erasure` or `Faho` is no refusal, but words no terminal reads: `su`
##       that ends text before it, words erasure erases with cmavo erasing them, and `fa'o` that
##       ends input. Written word after `fa'o` takes stage `Stream` and refusal `Faho`, and keeps
##       its bytes. So each byte of each word lies in one leaf (`isCovering` of suites).
##   Tag writes `_` for each `-`, and no name of 21.1 holds `_`. Word writes `h` for each `'`, as
##     chapter 20 writes capital of `'` in names of selma'o; lojban writes no `h` (3.3), and stream
##     refuses it outside quotation. So reader reads `_` as `-` and `h` as `'`, and neither tag nor
##     word needs escape of NIF.
##   Text that `zoi` or `la'o` quotes, third string of `ZOI` terminal, stays as it is: control
##     byte of NIF and byte below space as `\xx`; `#`, `:`, space and byte from 128 as they are.
##   Rejected: escape `\2D` of tag and `\27` of word, which spec gives, and Architect declined
##     (#855). Reader of nimony at `2c5b3dca` takes tag as its bytes, so it leaves `\2D` undecoded.
##   Rule on data between programs admits NIF, which law of suite holds (CONTRIBUTOR.md, Data):
##     `test_nif.nim` writes each tree of corpora and reads it back whole.
##   Rejected: line information for byte of word, since NIF writes it as difference from parent,
##     and reader of nimony keeps 10 bits of column, so byte past 1,023 is cut (#852).
##   Rejected: library of nimony, which compiles not for JavaScript (#852).
##   Writer loops by index, and recurses down chain, since `items` and binding of node copy it on
##     JavaScript backend.

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ./[grammar, prose, stream]


const
  CONTROLS = {'(', ')', '[', ']', '{', '}', '~', '#', '\'', '"', '\\', ':', '@'}
    ## Control bytes of NIF, which literal and identifier hold only as escape (spec, Control
    ##   characters).
  KEPT_STRING = {'#', ':'}  ## Control bytes string literal holds as they are (String literals).
  KEPT_IDENTIFIER = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
    ## Bytes below 128 that identifier holds as they are (Identifiers).
  HEADER* = "(.nif27)\n(.lang \"cll-21.1\")\n"
    ## Directives module opens with: version, as magic cookie, then language of its tags.


func escaped(text: string, is_identifier: bool): string =
  ## Write text with escape `\xx` of upper hex for each byte NIF holds not as it is: in
  ##   identifier, each byte below 128 that is no letter, digit or `_`; in string literal, each
  ##   control byte save `#` and `:`, each byte below space, and DEL. Byte from 128 stays.
  for c in text:
    let is_kept =
      if ord(c) >= 128: true
      elif is_identifier: c in KEPT_IDENTIFIER
      else: ord(c) >= ord(' ') and ord(c) != 127 and (c notin CONTROLS or c in KEPT_STRING)
    if is_kept: result.add c
    else:
      result.add '\\'
      result.add toHex(ord(c), 2)


func tag(name: string): string =
  ## Spell name of rule or class of terminal as tag: `_` for each `-`, and each other byte
  ##   identifier holds not as it is escaped, which no name of grammar needs.
  escaped(name.replace('-', '_'), is_identifier = true)


func letters(occurrence: Occurrence): string =
  ## Spell occurrence as string literal: word with `h` for each `'`, or text quotation holds as it
  ##   is, each byte string literal holds not as it is escaped.
  let text =
    if occurrence.reading.is_word: occurrence.text.replace('\'', 'h') else: occurrence.text
  escaped(text, is_identifier = false)


func byteAt*(reading: ReadingMarked, at: int): int =
  ## Give byte where unit `at` opens; size of text, at count of units, where text ends.
  if at < reading.units.len: reading.occurrences[reading.units[at].words[0]].start
  else: reading.size


func addNode(text: var string, node: Node, reading: ReadingText | ReadingMarked)


func addRule(text: var string, node: Node, top: int, reading: ReadingText | ReadingMarked) =
  ## Add named rule to text: rule holding rule alone passes on to it, as chain opening at `top`;
  ##   rule closing chain writes its tag, `top` where chain stands, its number, then its nodes.
  ##   Error node closes chain above it, and writes tag `error`, byte where grammar stops, tag
  ##     and number of rule stopping there, and `expects` with terminals read there.
  let is_chain = node.stop.isNone and node.children.len == 1 and
    not node.children[0].is_terminal and node.children[0].stop.isNone
  if is_chain:
    text.addRule(node.children[0], top, reading)
    return
  text.add '('
  if node.stop.isSome:
    when reading is ReadingMarked:
      text.add "error "
      text.add $reading.byteAt(node.stop.get.at)
      text.add ' '
    else:
      doAssert false, "Reading that reads should hold no error node."
  text.add node.rule.tag
  if top != node.number:
    text.add ' '
    text.add $top
  text.add ' '
  text.add $node.number
  if node.stop.isSome:
    text.add " (expects"
    for k in 0 ..< node.stop.get.expected.len:
      text.add ' '
      text.add ($node.stop.get.expected[k]).tag
    text.add ')'
  for k in 0 ..< node.children.len:
    text.add ' '
    text.addNode(node.children[k], reading)
  text.add ')'


func addNode(text: var string, node: Node, reading: ReadingText | ReadingMarked) =
  ## Add node of tree to text: chain of named rules opening at it, or terminal with its class,
  ##   then bytes and letters of each word; unit no terminal holds writes `unread`, then stage
  ##   refusing it, with refusal of stream for stage `Stream`, before its words.
  if not node.is_terminal:
    text.addRule(node, node.number, reading)
    return
  template unit: untyped = reading.units[node.at]
    ## Alias unit of terminal, which `let` would copy on JavaScript backend.
  text.add '('
  text.add (if unit.is_read: ($unit.terminal).tag else: "unread")
  if not unit.is_read:
    when reading is ReadingMarked:
      text.add ' '
      text.add ($unit.refusal).tag
      if unit.refusal == RefusalText.Stream:
        text.add ' '
        text.add ($reading.occurrences[unit.words[0]].reading.refusal).tag
    else:
      doAssert false, "Reading that reads should hold no unit refused."
  for k in 0 ..< unit.words.len:
    template word: untyped = reading.occurrences[unit.words[k]]
      ## Alias word of unit, which `let` would copy on JavaScript backend.
    text.add ' '
    text.add $word.start
    text.add ' '
    text.add $word.finish
    text.add " \""
    text.add word.letters
    text.add '"'
  text.add ')'


func toNif*(reading: ReadingText): string =
  ## Write tree of reading as module of NIF: directives, then node of rule `text`, then line end.
  doAssert reading.is_read, "Reading should read, since refusal holds no tree; got refusal `" &
    $reading.refusal & "`."
  result = HEADER
  result.addNode(reading.tree, reading)
  result.add '\n'


func toNif*(reading: ReadingMarked): string =
  ## Write tree of reading that marks each error as module of NIF: directives, then root node,
  ##   then line end. Text that reads writes as `readText` writes it.
  result = HEADER
  result.addNode(reading.tree, reading)
  result.add '\n'


func toNif*(node: Node, reading: ReadingMarked): string =
  ## Write one node of tree of reading as NIF, as module writes it, with no directive: node of
  ##   each part goes out on line of its own in live text (`live.nim`).
  result.addNode(node, reading)


func toNifParts*(reading: ReadingMarked): string =
  ## Write module of NIF whose nodes are children of root of reading, each on line of its own:
  ##   node of each part, and each unit refused between parts (`readTextParts`), as live text
  ##   writes them.
  result = HEADER
  for k in 0 ..< reading.tree.children.len:
    result.addNode(reading.tree.children[k], reading)
    result.add '\n'
