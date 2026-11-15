## Read module of NIF data format, version 2027, by grammar `doc/nif-spec.md` of
##   `nim-lang/nifspec` writes at `a31513c6`: page reads NIF live reader gives through it, and
##   suites hold `nif.nim` to it, so writer is held to spec, never to itself.
##
##   |------------|------------------------------------------------------------------------|
##   | Code       | Meaning                                                                |
##   |------------|------------------------------------------------------------------------|
##   | readModule | nodes of module of NIF, each escape decoded; `ValueError` where refused |
##   |------------|------------------------------------------------------------------------|
##
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
##   Refusal raises `ValueError`, naming byte and what NIF asks there.
##   Reader stands apart from writer `nif.nim`, and imports nothing of it, so each holds other.

{.experimental: "strictFuncs".}

import std/strutils


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
