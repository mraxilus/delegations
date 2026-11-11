## Write tree of text as module of NIF data format, version 2027 of `nim-lang/nifspec`, so that
##   other programs read it: Nim 3 holds its own trees in NIF (ruling `D1 c` of #852).
##
##   |-------------|-----------------------------------------------------------------------|
##   | Code        | Meaning                                                               |
##   |-------------|-----------------------------------------------------------------------|
##   | TerminalNif | terminal as NIF writes it: class, then bytes and letters of words     |
##   | LeavesNif   | terminals of tree rebuilt from NIF (`merge.nim`), which it indexes    |
##   | toNif       | module of NIF holding tree of reading or tree rebuilt, words in place |
##   |-------------|-----------------------------------------------------------------------|
##
##   Module opens with directive `(.nif27)`, with no byte before it, then `(.lang "cll-21.1")`:
##     tags are names of rules of 21.1 and classes of terminals, as grammar spells them.
##   Named rule is compound node: tag is its name, then nodes it holds. Its number in 21.1 is no
##     node, since its name gives it (`LUT_NUMBER_BY_RULE`, ruling on #859, comment 6805527878):
##     copy of it would let node name two rules.
##   Chain of rules, each holding next alone, is one node: tag of rule closing it, then number of
##     rule opening it, as `(sumti_6 80 ...)` from `terms` 80 down to `sumti-6` 97. Two ends give
##     one chain in 21.1 (`LUT_CHAIN_BY_ENDS`), so reader rebuilds each rule between them, and
##     tree reads back whole. Node that writes no number opens no chain, as `(tail_terms)`.
##   Terminal is compound node: tag is its class, as `KOhA` or `BRIVLA`; then, for each word, byte
##     where it opens, byte past its last letter, and its letters as string literal, as
##     `(BU 15 17 "ta" 18 20 "bu")`. So each word ties to bytes of text it reads from. Order of
##     terminals in tree gives index of each unit, so node holds none.
##   Named rule writes no byte: it spans bytes of leaves under it, which reader takes from them.
##     Cost: byte past each word adds 7% to modules of corpora (PROVENANCE.md, NIF); byte where
##       word opens alone was rejected, since reader could not tell where word ends from letters
##       alone, as comma inside word writes byte letters drop.
##   Reading that marks each error (`readTextMarked`, #859) writes two nodes more:
##     Error node: tag `srera`, byte where grammar stops, tag of rule stopping innermost there,
##       as name of rule gives its number (ruling on #859, comment 6806614095), then
##       `(nitcu ...)` holding class of each terminal some derivation
##       reads there, then nodes it holds. Chain stops above it, as no chain of 21.1 holds it.
##     Unit no terminal holds: tag `rivbi`, stage refusing it as identifier, as `selmaho`, then
##       bytes and letters of each word, as terminal writes them. Stage `Stream` adds refusal of
##       stream, as `Letter`, and written word it refuses keeps its bytes, as text `zoi` quotes
##       does: no `h` for `'`, and `'` takes escape. Stage alone was rejected, since stream and
##       grammar of quotation both name refusal `Quotation`, so reader could not tell bytes from
##       word.
##     Unit of stage `SU`, `Erasure` or `FAhO` is no refusal, but words no terminal reads: `su`
##       that ends text before it, words erasure erases with cmavo erasing them, and `fa'o` that
##       ends input. Written word after `fa'o` takes stage `Stream` and refusal `FAhO`, and keeps
##       its bytes. So each byte of each word lies in one leaf (`isCovering` of suites).
##   Each tag of mark, stage and refusal takes term of CLL, as CLL spells it, where CLL gives one:
##     selma'o as chapter 20 names it, as `SU`, lojban word in lower case, as `slinkuhi`, and
##     English term as it stands, as `Erasure` of 19.13. Tag CLL gives no term for is gismu of
##     official list: `srera` "errs", `nitcu` "needs" and `rivbi` "avoids" (rulings on #859).
##     Rejected: lojban names of rules of 21.1, which CLL gives not, so tags of rules keep its
##     names, till CLL gives lojban ones; and lujvo `naltcidu` for `rivbi`, which no list holds.
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
##   Tree rebuilt from NIF (`toTree` of `merge.nim`) writes as reading does: its leaves index
##     terminals NIF gave back, whose words hold `'` for `h`, save text quotation and written
##     word stream refuses; error node holds byte where grammar stops, as NIF gives it. So tree
##     writes back to NIF it read from, byte for byte (`test_merge.nim`).

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ./[dictionary, grammar, prose, selmaho, stream, tanru]


type
  WordNif* = tuple[start, finish: int, letters: string]
    ## Define word of terminal as NIF gives it back: byte where it opens, byte past it, and its
    ##   letters, `'` for each `h` of word.

  TerminalNif* = tuple[terminal: string, words: seq[WordNif]]
    ## Define terminal as NIF gives it back: class, then each word; unit no terminal holds gives
    ##   `rivbi`, then stage, then refusal of stream for stage `Stream`, each parted by space.

  LeavesNif* = object  ## Define terminals of tree rebuilt from NIF, which each leaf indexes.
    terminals*: seq[TerminalNif]


const
  CONTROLS = {'(', ')', '[', ']', '{', '}', '~', '#', '\'', '"', '\\', ':', '@'}
    ## Control bytes of NIF, which literal and identifier hold only as escape (spec, Control
    ##   characters).
  KEPT_STRING = {'#', ':'}  ## Control bytes string literal holds as they are (String literals).
  KEPT_IDENTIFIER = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
    ## Bytes below 128 that identifier holds as they are (Identifiers).
  HEADER* = "(.nif27)\n(.lang \"cll-21.1\")\n"
    ## Directives module opens with: version, as magic cookie, then language of its tags.
  TAG_ERROR* = "srera"  ## Tag of error node: gismu "x1 errs in doing x2".
  TAG_EXPECTS* = "nitcu"  ## Tag of terminals grammar reads where it stops: gismu "x1 needs x2".
  TAG_UNREAD* = "rivbi"  ## Tag of unit no terminal holds: gismu "x1 avoids x2", as grammar does.
  DISTANCE_QUOTED = 2  ## Words from cmavo of ZOI to text it quotes: delimiter stands between.


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


func spelling*(stage: RefusalText): string =
  ## Spell stage as CLL spells its term: selma'o as chapter 20 names it, lojban word in lower
  ##   case, and English term of CLL as it stands.
  case stage
  of RefusalText.Su: $Selmaho.Su
  of RefusalText.Faho: $Selmaho.Faho
  of RefusalText.Selmaho: "selmaho"
  else: $stage


func spelling*(refusal: Refusal): string =
  ## Spell refusal of stream as CLL spells its term: selma'o as chapter 20 names it, lojban word
  ##   in lower case, and English term of CLL as it stands.
  case refusal
  of Refusal.Faho: $Selmaho.Faho
  of Refusal.Slinkuhi: "slinkuhi"
  else: $refusal


func letters(occurrence: Occurrence): string =
  ## Spell occurrence as string literal: word with `h` for each `'`, or text quotation holds as it
  ##   is, each byte string literal holds not as it is escaped.
  let text =
    if occurrence.reading.is_word: occurrence.text.replace('\'', 'h') else: occurrence.text
  escaped(text, is_identifier = false)


func indexQuoted*(letters: openArray[string]): int =
  ## Give index of word of `ZOI` terminal that holds text `zoi` or `la'o` quotes, from letters of
  ##   its words, `h` or `'` alike: second word past cmavo of ZOI, which each BAhE marking it
  ##   stands before (rule 1100).
  while result < letters.len and letters[result].replace('h', '\'').selmaho != some(Selmaho.Zoi):
    inc result
  result += DISTANCE_QUOTED


func byteAt*(reading: ReadingMarked, at: int): int =
  ## Give byte where unit `at` opens; size of text, at count of units, where text ends.
  if at < reading.units.len: reading.occurrences[reading.units[at].words[0]].start
  else: reading.size


func addLeaf(text: var string, terminal: TerminalNif) =
  ## Add terminal NIF gave back to text, as reading writes it: class, or `rivbi` with its
  ##   identifiers, then bytes and letters of each word, `h` for each `'`, save text quotation
  ##   holds and written word stream refuses.
  var letters: seq[string]
  for k in 0 ..< terminal.words.len: letters.add terminal.words[k].letters
  let
    names = terminal.terminal.split(' ')
    is_kept = names.len > 1 and names[0] == TAG_UNREAD and names[1] == RefusalText.Stream.spelling
    quoted = (if names[0] == $Selmaho.Zoi: some(letters.indexQuoted) else: none(int))
  text.add '('
  text.add names[0].tag
  for k in 1 ..< names.len:
    text.add ' '
    text.add names[k].tag
  for k in 0 ..< terminal.words.len:
    template word: untyped = terminal.words[k]
      ## Alias word, which `let` would copy on JavaScript backend.
    let is_quoted = quoted == some(k)
    text.add ' '
    text.add $word.start
    text.add ' '
    text.add $word.finish
    text.add " \""
    text.add escaped(
      if is_kept or is_quoted: word.letters else: word.letters.replace('\'', 'h'),
      is_identifier = false,
    )
    text.add '"'
  text.add ')'


func addUnit(text: var string, node: Node, reading: ReadingText | ReadingMarked) =
  ## Add terminal of reading to text: class, then bytes and letters of each word; unit no
  ##   terminal holds writes `rivbi`, then stage refusing it, with refusal of stream for stage
  ##   `Stream`, before its words.
  template unit: untyped = reading.units[node.at]
    ## Alias unit of terminal, which `let` would copy on JavaScript backend.
  text.add '('
  text.add (if unit.is_read: ($unit.terminal).tag else: TAG_UNREAD)
  if not unit.is_read:
    when reading is ReadingMarked:
      text.add ' '
      text.add unit.refusal.spelling.tag
      if unit.refusal == RefusalText.Stream:
        text.add ' '
        text.add reading.occurrences[unit.words[0]].reading.refusal.spelling.tag
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


func addNode(text: var string, node: Node, reading: ReadingText | ReadingMarked | LeavesNif)


func addRule(
    text: var string, node: Node, top: int, reading: ReadingText | ReadingMarked | LeavesNif
) =
  ## Add named rule to text: rule holding rule alone passes on to it, as chain opening at `top`;
  ##   rule closing chain writes its tag, then `top` where chain opens above it, then its nodes.
  ##   Error node closes chain above it, and writes tag `srera`, byte where grammar stops, tag
  ##     of rule stopping there, and `nitcu` with terminals read there.
  let is_chain = node.stop.isNone and node.children.len == 1 and
    not node.children[0].is_terminal and node.children[0].stop.isNone
  if is_chain:
    text.addRule(node.children[0], top, reading)
    return
  text.add '('
  if node.stop.isSome:
    when reading is ReadingMarked or reading is LeavesNif:
      text.add TAG_ERROR
      text.add ' '
      text.add $(when reading is LeavesNif: node.stop.get.at else: reading.byteAt(node.stop.get.at))
      text.add ' '
    else:
      doAssert false, "Reading that reads should hold no error node."
  text.add node.rule.tag
  if node.stop.isNone and top != node.number:
    text.add ' '
    text.add $top
  if node.stop.isSome:
    text.add " ("
    text.add TAG_EXPECTS
    for k in 0 ..< node.stop.get.expected.len:
      text.add ' '
      text.add ($node.stop.get.expected[k]).tag
    text.add ')'
  for k in 0 ..< node.children.len:
    text.add ' '
    text.addNode(node.children[k], reading)
  text.add ')'




func addNode(text: var string, node: Node, reading: ReadingText | ReadingMarked | LeavesNif) =
  ## Add node of tree to text: chain of named rules opening at it, or terminal with its class,
  ##   then bytes and letters of each word; unit no terminal holds writes `rivbi`, then stage
  ##   refusing it, with refusal of stream for stage `Stream`, before its words.
  if not node.is_terminal:
    text.addRule(node, node.number, reading)
    return
  when reading is LeavesNif:
    text.addLeaf(reading.terminals[node.at])
  else:
    text.addUnit(node, reading)




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


func toNif*(trees: openArray[Node], leaves: LeavesNif): string =
  ## Write each tree rebuilt from NIF as node of module, as reading writes it: directives, then
  ##   each tree on line of its own; so merge of parts writes tree of one pass, or each tree it
  ##   gives where error stays (`merge.nim`).
  result = HEADER
  for k in 0 ..< trees.len:
    result.addNode(trees[k], leaves)
    result.add '\n'
