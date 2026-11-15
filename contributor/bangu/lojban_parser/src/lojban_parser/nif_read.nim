## tcidu pa se ciska be fi la'o gy. NIF 2027 .gy. ja'i lo gerna poi `doc/nif-spec.md` pe
##   `nim-lang/nifspec` pe `a31513c6` cu ciska ke'a
##   .i lo papri cu tcidu sepi'o le vi datnyvei lo se ciska be fi la'o gy. NIF .gy. be'o poi lo
##     tcidu be lo jmive se ciska cu dunda ke'a
##   .i lo cipra cu cipra fi `nif.nim` sepi'o le vi datnyvei
##   .i se ki'u bo lo cipra cu cipra fi le ciska ja'i le ve skicu gi'e no roi cipra fi le ciska ja'i
##     le ciska
##
##   |--------------|-------------------------------------------------|
##   | lo cmene     | lo smuni                                        |
##   |--------------|-------------------------------------------------|
##   | `readModule` | lo jgena pe lo se ciska be fi la'o gy. NIF .gy. |
##   |              | .i ro basti sinxa cu se galfi fi lo stuzi       |
##   |              | .i `ValueError` va'o lo nu to'e curmi           |
##   |--------------|-------------------------------------------------|
##
## ni'o le tcidu cu tcidu lo pagbu be la'o gy. NIF .gy. po'o
##   .i le tcidu cu tcidu lo minde
##   .i le tcidu cu tcidu lo jgena poi vasru lo tcita .e lo jgena
##   .i le tcidu cu tcidu lo cmene poi tcita .a lo cmene poi jgena gi'e vasru no jgena
##   .i le tcidu cu tcidu lo mulna'u poi pilno pano lerfu .e lo lerpoi .e `\xx` .e lo mu tordu basti
##     sinxa pe `\xx`
##   .i le tcidu cu tcidu lo kunti lerfu poi zvati lo jbini be le se tcidu
##   .i le tcidu cu to'e curmi ro drata tarmi mu'u lo sinxa .e lo lerfu poi se sitna .e lo kunti
##     jgena .e lo datni be lo linji .e lo pinka
##   .i le ciska cu ciska no le drata tarmi
##   .i se ki'u bo ro se ciska poi le tcidu cu tcidu ke'a cu se ciska fi la'o gy. NIF .gy. po'o
##   .i le tcidu cu jersi lo gerna pe le ve skicu
##   .i `IdentStart` cu du lo lerfu .a `_` .a lo stuzi poi na mleca li parebi .a lo basti sinxa
##   .i `IdentChar` cu jmina lo namcu lerfu to la'o gy. Identifiers .gy. toi
##   .i `\` cu krasi lo basti sinxa
##   .i le basti sinxa cu vasru re lerfu pe li paxa gi'a vasru pa lerfu pe `n t r | ^`
##   .i le lerfu pe li paxa cu barda lerfu to la'o gy. Escape sequences .gy. toi
##   .i lo lerpoi cu vasru ro stuzi poi na mleca li cire gi'e na minde lerfu ku'o .e ro stuzi poi na
##     mleca li parebi ku'o .e `#` .e `:` .e lo kunti lerfu .e lo basti sinxa
##   .i re `"` cu sruri le lerpoi to la'o gy. String literals .gy. toi
##   .i lo jgena poi vasru lo tcita .e lo jgena cu du `(` ce'o lo tcita ce'o lo jgena ce'o `)`
##   .i lo minde cu du `(.name ...)` to la'o gy. Directives .gy. toi
##   .i ro jgena cu du lo jgena poi vasru no jgena .a lo jgena poi vasru lo tcita .e lo jgena
##   .i ro cmene cu du lo jgena poi vasru no jgena to la'o gy. Atoms .gy. toi
##   .i lo minde poi cusku lo namcu pe le tarmi cu krasi le se ciska gi'e se lidne no stuzi to la'o
##     gy. Version directive .gy. toi
##   .i ro valsi pe la'o gy. NIF .gy. cu fanmo bu'u lo kunti lerfu .a `(` .a `)` .a lo fanmo be le
##     se ciska
##   .i le tcidu cu to'e curmi ro drata stuzi poi se lidne le valsi mu'u `@` pe lo datni be lo linji
##     ge'u .a `#` pe lo pinka
##   .i lo nu to'e curmi cu renro `ValueError` noi cusku lo stuzi .e lo se cpedu be la'o gy. NIF
##     .gy. bu'u le stuzi
##   .i le tcidu cu sepli le ciska po'u `nif.nim` gi'e nerbei no pagbu be `nif.nim`
##   .i se ki'u bo ro le re datnyvei cu cipra fi le drata

{.experimental: "strictFuncs".}

import std/strutils


type
  KindNif* {.pure.} = enum  ## lo klesi be lo jgena poi le tcidu cu dunda ke'a
    Compound
      ## lo jgena poi vasru lo tcita .e lo jgena mu'u `(tag child ...)`
      ##   .i ji'a lo minde
      ##   .i lo tcita be lo minde cu se krasi `.`
    Identifier  ## lo cmene poi jgena gi'e vasru no jgena mu'u `sumti_6` pe lo srera jgena
    Number  ## lo mulna'u mu'u `97`
    Literal  ## lo lerpoi mu'u `"mi"`

  NodeNif* = object
    ## lo jgena pe la'o gy. NIF .gy. ta'i lo nu se tcidu
    ##   .i ro basti sinxa cu se galfi fi lo stuzi
    kind*: KindNif
    text*: string
      ## lo tcita be lo jgena poi vasru lo tcita .e lo jgena ku'o be'o .a lo cmene .a lo stuzi pe lo
      ##   lerpoi
      ##   .i va'o lo drata cu kunti
    number*: int  ## lo mulna'u to va'o lo drata cu du li no toi
    children*: seq[NodeNif]
      ## ro jgena poi lo jgena poi vasru lo tcita .e lo jgena cu vasru ke'a ku'o ta'i lo porsi
      ##   .i va'o lo drata cu kunti

  Reader = object  ## lo se ciska poi se tcidu .e lo stuzi poi le tcidu cu zvati ke'a
    text: string
    at: int


const
  WHITESPACE = {' ', '\t', '\n', '\r'}
    ## lo kunti lerfu pe la'o gy. NIF .gy. zi'e noi fendi lo valsi to la'o gy. Whitespace .gy. toi
  CONTROLS = {'(', ')', '[', ']', '{', '}', '~', '#', '\'', '"', '\\', ':', '@'}
    ## lo minde lerfu pe la'o gy. NIF .gy. to la'o gy. Control characters .gy. toi
  OPENERS_IDENTIFIER = {'a'..'z', 'A'..'Z', '_', '\x80'..'\xFF'}
    ## lo stuzi poi ka'e krasi lo cmene
    ##   .i lo basti sinxa na se kancu to `IdentStart` toi
  DIGITS = {'0'..'9'}
  HEX = {'0'..'9', 'A'..'F'}
    ## lo lerfu pe li paxa pe lo basti sinxa
    ##   .i no cmalu lerfu cu cmima to la'o gy. Escape sequences .gy. toi
  SHORTCUTS = [('n', '\n'), ('t', '\t'), ('r', '\r'), ('|', '\\'), ('^', '"')]
    ## ro tordu basti sinxa joi lo stuzi poi le basti sinxa cu dunda ke'a to la'o gy. Escape
    ##   sequences .gy. toi
  VERSION* = "(.nif27)"
    ## lo minde poi cusku lo namcu pe le tarmi gi'e krasi lo se ciska gi'e se lidne no stuzi



func refuse(reader: Reader, expected: string) {.noreturn.} =
  ## to'e curmi le se ciska bu'u lo stuzi poi le tcidu cu zvati ke'a
  ##   .i le fancu cu cusku lo se cpedu be la'o gy. NIF .gy. bu'u le stuzi
  let found =
    if reader.at < reader.text.len: "`" & reader.text[reader.at] & "`" else: "end of module"
  raise newException(
    ValueError, "NIF should hold " & expected & " at byte " & $reader.at & "; got " & found & "."
  )


func isAt(reader: Reader, bytes: set[char]): bool =
  ## jdice lo du'u le tcidu cu zvati lo stuzi poi cmima le selcmi
  ##   .i va'o lo nu le tcidu cu zvati lo fanmo be le se ciska kei le jalge cu jitfa
  reader.at < reader.text.len and reader.text[reader.at] in bytes


func skipWhitespace(reader: var Reader) =
  ## muvgau le tcidu lo stuzi poi se lidne lo kunti lerfu
  while reader.isAt(WHITESPACE): inc reader.at


func endToken(reader: Reader) =
  ## to'e curmi lo stuzi poi se lidne lo valsi pe la'o gy. NIF .gy.
  ##   .i ku'i le fancu cu curmi lo kunti lerfu .e `(` .e `)` .e lo fanmo be le se ciska
  if reader.at < reader.text.len and not reader.isAt(WHITESPACE + {'(', ')'}):
    reader.refuse("end of token")


func readEscape(reader: var Reader): char =
  ## tcidu lo basti sinxa
  ##   .i le fancu cu cfari bu'u lo stuzi poi se lidne `\`
  ##   .i le basti sinxa cu du re lerfu pe li paxa ge'u .a pa tordu basti sinxa
  ##   .i le fancu cu curmi lo barda lerfu po'o
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
  ## tcidu lo cmene
  ##   .i lo krasi lerfu .a lo basti sinxa cu pamoi
  ##   .i lo namcu lerfu cu ka'e se lidne le pamoi to la'o gy. Identifiers .gy. toi
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
  ## tcidu lo mulna'u poi pilno pano lerfu
  ##   .i va'o lo nu le mulna'u cu mleca li no kei `-` cu lidne le mulna'u to la'o gy. Numbers .gy.
  ##     toi
  let start = reader.at
  if reader.isAt({'-'}): inc reader.at
  if not reader.isAt(DIGITS): reader.refuse("digit")
  while reader.isAt(DIGITS): inc reader.at
  parseInt(reader.text[start ..< reader.at])


func readLiteral(reader: var Reader): string =
  ## tcidu lo lerpoi
  ##   .i le fancu cu cfari bu'u lo stuzi poi se lidne `"`
  ##   .i le fancu cu sisti bu'u `"` poi fanmo le lerpoi to la'o gy. String literals .gy. toi
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
  ## tcidu lo jgena
  ##   .i le jgena cu du lo jgena poi vasru lo tcita .e lo jgena ku'o .a lo cmene .a lo mulna'u .a
  ##     lo lerpoi
  ##   .i va'o lo nu le jgena cu vasru lo jgena kei le fancu cu tcidu ji'a ro le se vasru
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
  ## tcidu lo se ciska be fi la'o gy. NIF .gy.
  ##   .i lo minde poi cusku lo namcu pe le tarmi cu zvati lo pamoi stuzi
  ##   .i lo jgena cu se lidne le minde
  ##   .i le jgena cu klama lo fanmo be le se ciska to la'o gy. Modules .gy. toi
  var reader = Reader(text: text)
  if not text.startsWith(VERSION): reader.refuse("version directive `" & VERSION & "`")
  while true:
    reader.skipWhitespace
    if reader.at >= text.len: break
    result.add reader.readNode
