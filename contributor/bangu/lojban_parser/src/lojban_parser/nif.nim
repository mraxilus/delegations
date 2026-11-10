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
##   Terminal is compound node: tag is its class, as `KOhA` or `BRIVLA`; then byte where its first
##     word opens, then letters of each word as string literal. Order of terminals in tree gives
##     index of each unit, so node holds none.
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

import std/strutils

import ./[grammar, prose, stream]


const
  CONTROLS = {'(', ')', '[', ']', '{', '}', '~', '#', '\'', '"', '\\', ':', '@'}
    ## Control bytes of NIF, which literal and identifier hold only as escape (spec, Control
    ##   characters).
  KEPT_STRING = {'#', ':'}  ## Control bytes string literal holds as they are (String literals).
  KEPT_IDENTIFIER = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
    ## Bytes below 128 that identifier holds as they are (Identifiers).
  HEADER = "(.nif27)\n(.lang \"cll-21.1\")\n"
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


func addNode(text: var string, node: Node, reading: ReadingText)


func addRule(text: var string, node: Node, top: int, reading: ReadingText) =
  ## Add named rule to text: rule holding rule alone passes on to it, as chain opening at `top`;
  ##   rule closing chain writes its tag, `top` where chain stands, its number, then its nodes.
  if node.children.len == 1 and not node.children[0].is_terminal:
    text.addRule(node.children[0], top, reading)
    return
  text.add '('
  text.add node.rule.tag
  if top != node.number:
    text.add ' '
    text.add $top
  text.add ' '
  text.add $node.number
  for k in 0 ..< node.children.len:
    text.add ' '
    text.addNode(node.children[k], reading)
  text.add ')'


func addNode(text: var string, node: Node, reading: ReadingText) =
  ## Add node of tree to text: chain of named rules opening at it, or terminal with its class,
  ##   byte where it opens, and letters of each word.
  if not node.is_terminal:
    text.addRule(node, node.number, reading)
    return
  template unit: untyped = reading.units[node.at]
    ## Alias unit of terminal, which `let` would copy on JavaScript backend.
  text.add '('
  text.add ($unit.terminal).tag
  text.add ' '
  text.add $reading.occurrences[unit.words[0]].start
  for k in 0 ..< unit.words.len:
    text.add " \""
    text.add reading.occurrences[unit.words[k]].letters
    text.add '"'
  text.add ')'


func toNif*(reading: ReadingText): string =
  ## Write tree of reading as module of NIF: directives, then node of rule `text`, then line end.
  doAssert reading.is_read, "Reading should read, since refusal holds no tree; got refusal `" &
    $reading.refusal & "`."
  result = HEADER
  result.addNode(reading.tree, reading)
  result.add '\n'
