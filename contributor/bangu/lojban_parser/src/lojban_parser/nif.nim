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
##   Named rule is compound node: tag is its name, each byte identifier holds not written `\xx`,
##     as `sumti\2D6`; first child is its number in 21.1, then nodes it holds, in order.
##   Terminal is compound node: tag is its class, as `KOhA` or `BRIVLA`; then byte where its
##     first word opens, then letters of each word as string literal. Order of terminals in tree
##     gives index of each unit, so node holds none.
##   Literal writes each control byte of NIF as `\xx`, `'` of lojban among them, and each byte
##     below space; `#`, `:` and space stay, as spec lets string hold them. Byte from 128 stays.
##   Tag keeps escape spec asks of identifier. Reader of nimony at `2c5b3dca` takes tag as its
##     bytes, since its branch of `(` marks no escape (`nifreader.nim`), so caller reading with
##     it gets `sumti\2D6` and decodes it.
##   NIF needs no exception to rule on data between programs, as native format of Nim 3
##     (CONTRIBUTOR.md, Data; #852).
##   Rejected: line information for byte of word, since NIF writes it as difference from parent,
##     and reader of nimony keeps 10 bits of column, so byte past 1,023 is cut (#852).
##   Rejected: library of nimony, which compiles not for JavaScript (#852).
##   Writer loops by index, since `items` copies each node on JavaScript backend.

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


func addNode(text: var string, node: Node, reading: ReadingText) =
  ## Add node of tree to text: named rule with its number and nodes, or terminal with its class,
  ##   byte where it opens, and letters of each word.
  if node.is_terminal:
    template unit: untyped = reading.units[node.at]
      ## Alias unit of terminal, which `let` would copy on JavaScript backend.
    text.add '('
    text.add escaped($unit.terminal, is_identifier = true)
    text.add ' '
    text.add $reading.occurrences[unit.words[0]].start
    for k in 0 ..< unit.words.len:
      text.add " \""
      text.add escaped(reading.occurrences[unit.words[k]].text, is_identifier = false)
      text.add '"'
    text.add ')'
    return
  text.add '('
  text.add escaped(node.rule, is_identifier = true)
  text.add ' '
  text.add $node.number
  for k in 0 ..< node.children.len:
    text.add ' '
    text.addNode(node.children[k], reading)
  text.add ')'


func toNif*(reading: ReadingText): string =
  ## Write tree of reading as module of NIF: directives, then node of rule `text`, then line end.
  doAssert reading.is_read, "Reading should read, since refusal holds no tree; got refusal `" &
    $reading.refusal & "`."
  result = HEADER
  result.addNode(reading.tree, reading)
  result.add '\n'
