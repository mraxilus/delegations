## Read module of NIF data format, version 2027, by grammar `doc/nif-spec.md` of
##   `nim-lang/nifspec` writes at `a31513c6`, so suites hold `nif.nim` to spec, never to itself;
##   give module each reading should read as, so law of suite is reader of what writer writes.
##   Reader takes subset of NIF: directive, compound node, identifier as tag, integer of decimal
##     digits, string literal, escape `\xx` and its five shortcuts, whitespace between them.
##     Every other construct is refused, as symbol, char literal, empty node, line information
##     and comment; writer writes none, so what reader takes is NIF, and no more.
##   Grammar of spec this reader follows:
##     IdentStart is letter, `_`, byte from 128, or escape; IdentChar adds digit (Identifiers).
##     Escape is `\` with two hex digits of upper case, or one of `n t r | ^` (Escape sequences).
##     String literal holds byte from 32 that is no control character, byte from 128, `#`, `:`,
##       whitespace and escape, between `"` (String literals).
##     Compound node is `(`, tag, nodes, `)`; directive is `(.name ...)` (Directives).
##     Version directive opens module, with no byte before it (Version directive).
##   Token ends at whitespace, at parenthesis, or at end of module; byte after it, as `@` of
##     line information or `#` of comment, is refused.
##   Module of reading is model of format `nif.nim` gives in its header: directives, then tag,
##     number and nodes of each rule, and class, byte and words of each terminal. Writer gives
##     text, and model gives nodes, so neither checks itself.
##   Suites of native and JavaScript builds read same reader, model and worked example, so each
##     is written once (II.9).
##   Refusal raises `ValueError`, naming byte and what NIF asks there.

{.experimental: "strictFuncs".}

import std/strutils

import ../../src/lojban_parser/[grammar, prose]


type
  KindNif* {.pure.} = enum  ## Define kind of node reader gives.
    Compound  ## Compound node, `(tag child ...)`; directive too, whose tag opens with `.`.
    Number  ## Integer, as `97`.
    Literal  ## String literal, as `"mi"`.

  NodeNif* = object  ## Define node of NIF as read, each escape decoded.
    kind*: KindNif
    text*: string  ## Tag of compound node, or bytes of string literal; empty for integer.
    number*: int  ## Value of integer; zero otherwise.
    children*: seq[NodeNif]  ## Nodes compound node holds, in order; empty otherwise.

  Reader = object  ## Define module being read, and byte reader stands at.
    text: string
    at: int


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
    text: "co'o. djan.",  # Example 2.57 of CLL 1.1
    module: "(.nif27)\n(.lang \"cll-21.1\")\n" &
      "(text 0 (free 32 (vocative 415 (COI 0 \"co\\27o\")) (CMENE 6 \"djan\")) (text\\2D1 2))\n",
  )
    ## Text, and module `nif.nim` writes for it, byte for byte: tag `text-1` and word `co'o`
    ##   take escape, and `djan` opens at byte 6, after pause.



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
    else: reader.refuse("byte string literal holds")


func readNode(reader: var Reader): NodeNif =
  ## Read node: compound node with nodes it holds, integer, or string literal.
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


func toNodeNif(node: Node, reading: ReadingText): NodeNif =
  ## Give node of NIF that node of tree should read as: tag and number of named rule, then its
  ##   nodes; or class of terminal, byte where its first word opens, then letters of each word.
  if node.is_terminal:
    template unit: untyped = reading.units[node.at]
      ## Alias unit of terminal, which `let` would copy on JavaScript backend.
    result = NodeNif(kind: KindNif.Compound, text: $unit.terminal)
    result.children.add NodeNif(
      kind: KindNif.Number, number: reading.occurrences[unit.words[0]].start
    )
    for k in 0 ..< unit.words.len:
      result.children.add NodeNif(
        kind: KindNif.Literal, text: reading.occurrences[unit.words[k]].text
      )
    return
  result = NodeNif(kind: KindNif.Compound, text: node.rule)
  result.children.add NodeNif(kind: KindNif.Number, number: node.number)
  for k in 0 ..< node.children.len: result.children.add node.children[k].toNodeNif(reading)


func toModule*(reading: ReadingText): seq[NodeNif] =
  ## Give module that NIF of reading should read as: version, language, then tree.
  @[
    NodeNif(kind: KindNif.Compound, text: ".nif27"),
    NodeNif(
      kind: KindNif.Compound, text: ".lang",
      children: @[NodeNif(kind: KindNif.Literal, text: "cll-21.1")],
    ),
    reading.tree.toNodeNif(reading),
  ]
