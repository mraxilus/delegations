## tcidu pa selci'a be fi `NIF 2027` ja'i lo gerna poi `doc/nif-spec.md` pe `nim-lang/nifspec` pe
##     `a31513c6` ciska ke'a
##   .i lo papri cu tcidu sepi'o le vi datnyvei lo selci'a be fi `NIF` be'o poi lo tcidu be lo
##       mivyselci'a cu dunda ke'a
##   .i lo cipra cu cipra fi `nif.nim` sepi'o le vi datnyvei
##   .i se ki'u bo lo cipra cu cipra fi le ciska ja'i le velski gi'e no roi cipra fi le ciska ja'i
##       le ciska
##
##   |--------------|---------------------------------------|
##   | lo cmene     | lo smuni                              |
##   |--------------|---------------------------------------|
##   | `readModule` | lo jgena pe lo selci'a be fi `NIF`    |
##   |              | .i ro basysni cu selga'i fi lo stuzi  |
##   |              | .i `ValueError` va'o lo nu to'e curmi |
##   |--------------|---------------------------------------|
##
## ni'o le tcidu cu tcidu lo pagbu be `NIF` po'o
##   .i le tcidu cu tcidu lo minde .e lo jgena poi vasru lo tcita .e lo jgena
##   .i le tcidu cu tcidu lo cmene poi tcita .a lo cmene poi jgena gi'e vasru no jgena
##   .i le tcidu cu tcidu lo mulna'u poi pilno pano lerfu ku'o .e lo lerpoi .e `\xx` .e lo mu
##       torbasysni pe `\xx`
##   .i le tcidu cu tcidu lo kutle'u poi zvati lo jbini be le se tcidu
##
## ni'o le tcidu cu to'e curmi ro datytai mu'u lo sinxa .e lo lerfu poi se sitna .e lo kutyjge .e lo
##     datni be lo linji be'o .e lo pinka
##   .i le ciska cu ciska no le datytai
##   .i se ki'u bo ro selci'a poi le tcidu cu tcidu ke'a selci'a fi `NIF` po'o
##
## ni'o le tcidu cu jersi lo gerna pe le velski
##   .i `IdentStart` du lo lerfu .a `_` .a lo stuzi poi na mleca li parebi .a lo basysni
##   .i `IdentChar` jmina lo namcu lerfu to `Identifiers` toi
##
## ni'o `\` krasi lo basysni
##   .i le basysni cu vasru re lerfu pe li paxa gi'a vasru pa lerfu pe `n t r | ^`
##   .i le lerfu pe li paxa cu barda lerfu to `Escape sequences` toi
##   .i lo lerpoi cu vasru ro stuzi poi na mleca li cire gi'e na midle'u ku'o .e ro stuzi poi na
##       mleca li parebi ku'o .e `#` .e `:` .e lo kutle'u .e lo basysni
##   .i re `"` sruri le lerpoi to `String literals` toi
##
## ni'o lo jgena poi vasru lo tcita .e lo jgena cu du `(` ce'o lo tcita ce'o lo jgena ce'o `)`
##   .i lo minde cu du `(.name ...)` to `Directives` toi
##   .i ro jgena cu du lo jgena poi vasru no jgena ku'o .a lo jgena poi vasru lo tcita .e lo jgena
##   .i ro cmene cu du lo jgena poi vasru no jgena to `Atoms` toi
##   .i lo minde poi cusku lo namcu pe le tarmi cu krasi le selci'a gi'e se lidne no stuzi to
##       `Version directive` toi
##
## ni'o ro valsi pe `NIF` fanmo bu'u lo kutle'u .a `(` .a `)` .a lo fanmo be le selci'a
##   .i le tcidu cu to'e curmi ro datstu poi se lidne le valsi mu'u `@` pe lo datni be lo linji ge'u
##       .a `#` pe lo pinka
##   .i lo nu to'e curmi cu renro `ValueError` noi cusku lo stuzi .e lo selcpe be `NIF` bu'u le
##       stuzi
##   .i le notci pe `ValueError` cu jboselci'a to `D1 a` pe `#987` toi gi'e cusku le stuzi ta'i lo
##       lerfu pe li 10
##   .i `test_nif.nim` cipra di'u
##
## ni'o le tcidu cu sepli le ciska po'u `nif.nim` gi'e nerbei no pagbu be `nif.nim`
##   .i se ki'u bo ro le re datnyvei cu cipra fi le drata

{.experimental: "strictFuncs".}

import std/strutils


type
  KindNif* {.pure.} = enum  ## lo klesi be lo jgena poi le tcidu cu dunda ke'a
    Compound
      ## lo jgena poi vasru lo tcita .e lo jgena mu'u `(tag child ...)`
      ##   .i ji'a lo minde noi lo tcita be ke'a cu selkra `.`
    Identifier  ## lo cmene poi jgena gi'e vasru no jgena mu'u `sumti_6` pe lo srejge
    Number  ## lo mulna'u mu'u `97`
    Literal  ## lo lerpoi mu'u `"mi"`

  NodeNif* = object
    ## lo jgena pe `NIF` ta'i lo nu se tcidu
    ##   .i ro basysni cu selga'i fi lo stuzi
    kind*: KindNif
    text*: string
      ## lo tcita be lo jgena poi vasru lo tcita .e lo jgena be'o .a lo cmene .a lo stuzi pe lo
      ##     lerpoi
      ##   .i va'o lo drata cu kunti
    number*: int  ## lo mulna'u to va'o lo drata cu du li no toi
    children*: seq[NodeNif]
      ## ro jgena poi lo jgena poi vasru lo tcita .e lo jgena cu vasru ke'a ku'o ta'i lo porsi
      ##   .i va'o lo drata cu kunti

  Reader = object  ## lo selci'a poi se tcidu .e lo stuzi poi le tcidu cu zvati ke'a
    text: string
    at: int


const
  WHITESPACE = {' ', '\t', '\n', '\r'}
    ## lo kutle'u pe `NIF` zi'e noi fendi lo valsi to `Whitespace` toi
  CONTROLS = {'(', ')', '[', ']', '{', '}', '~', '#', '\'', '"', '\\', ':', '@'}
    ## lo midle'u pe `NIF` to `Control characters` toi
  OPENERS_IDENTIFIER = {'a'..'z', 'A'..'Z', '_', '\x80'..'\xFF'}
    ## lo stuzi poi ka'e krasi lo cmene
    ##   .i lo basysni na se kancu to `IdentStart` toi
  DIGITS = {'0'..'9'}
  HEX = {'0'..'9', 'A'..'F'}
    ## lo lerfu pe li paxa pe lo basysni
    ##   .i no cmale'u cu cmima to `Escape sequences` toi
  SHORTCUTS = [('n', '\n'), ('t', '\t'), ('r', '\r'), ('|', '\\'), ('^', '"')]
    ## ro torbasysni joi lo stuzi poi le basysni cu dunda ke'a to `Escape sequences` toi
  VERSION* = "(.nif27)"
    ## lo minde poi cusku lo namcu pe le tarmi gi'e krasi lo selci'a gi'e se lidne no stuzi
  BYTES_VISIBLE = {'!'..'~'} - {'`'}
    ## lo me `byte` me'u poi le notci cu sitna ke'a ta'i pa samtci pagbu



func refuse(reader: Reader, expected: string) {.noreturn.} =
  ## to'e curmi le selci'a bu'u lo stuzi poi le tcidu cu zvati ke'a
  ##   .i le fancu cu cusku lo selcpe be `NIF` bu'u le stuzi .e lo zvati be le stuzi
  ##   .i lo kutle'u cu se cusku ta'i zo kutle'u
  ##   .i lo me `byte` me'u poi na cmima `BYTES_VISIBLE` cu se cusku ta'i lo namcu pe vo'a
  let found =
    if reader.at >= reader.text.len: "le stuzi cu fanmo le selci'a"
    elif reader.text[reader.at] in WHITESPACE: "lo kutle'u cu zvati le stuzi"
    elif reader.text[reader.at] in BYTES_VISIBLE:
      "`" & reader.text[reader.at] & "` cu zvati le stuzi"
    else: "lo me `byte` me'u po'u li " & $ord(reader.text[reader.at]) & " cu zvati le stuzi"
  raise newException(ValueError, "`NIF` bu'u le stuzi poi " & $reader.at &
      " me `byte` me'u cu lidne ke'a ku'o cu cpedu " & expected & " .i ku'i " & found)


func toSumti(name: string): string {.used.} =  # selpli ne'i `merge.nim`
  ## dunda pa sumti poi sinxa le cmene ne'i lo notci pe lo nu to'e curmi
  ##   .i va'o lo nu ro lerfu pe le cmene cu cmima `BYTES_VISIBLE` kei le sumti cu samtci pagbu
  ##   .i lo kunti cmene .e lo cmene poi vasru lo drata me `byte` me'u cu se skicu ta'i lo
  ##       jboselci'a
  if name.len == 0: "lo kunti cmene"
  elif name.allCharsInSet(BYTES_VISIBLE): "`" & name & "`"
  else: "lo cmene poi le notci na ka'e sitna ke'a"


func isAt(reader: Reader, bytes: set[char]): bool =
  ## jdice lo du'u le tcidu cu zvati lo stuzi poi cmima le selcmi
  ##   .i va'o lo nu le tcidu cu zvati lo fanmo be le selci'a kei le jalge cu jitfa
  reader.at < reader.text.len and reader.text[reader.at] in bytes


func skipWhitespace(reader: var Reader) =
  ## muvgau le tcidu lo stuzi poi se lidne lo kutle'u
  while reader.isAt(WHITESPACE): inc reader.at


func endToken(reader: Reader) =
  ## to'e curmi lo stuzi poi se lidne lo valsi pe `NIF`
  ##   .i ku'i le fancu cu curmi lo kutle'u .e `(` .e `)` .e lo fanmo be le selci'a
  if reader.at < reader.text.len and not reader.isAt(WHITESPACE + {'(', ')'}):
    reader.refuse("lo kutle'u .a `(` .a `)`")


func readEscape(reader: var Reader): char =
  ## tcidu lo basysni
  ##   .i le fancu cu cfari bu'u lo stuzi poi se lidne `\`
  ##   .i le basysni cu du re lerfu pe li paxa ge'u .a pa torbasysni
  ##   .i le fancu cu curmi lo barda lerfu po'o
  if reader.isAt(HEX) and reader.at + 1 < reader.text.len and reader.text[reader.at + 1] in HEX:
    result = char(parseHexInt(reader.text[reader.at .. reader.at + 1]))
    reader.at += 2
    return
  for (shortcut, decoded) in SHORTCUTS:
    if reader.isAt({shortcut}):
      inc reader.at
      return decoded
  reader.refuse("re lerfu pe li paxa ge'u .a pa torbasysni")


func readIdentifier(reader: var Reader): string =
  ## tcidu lo cmene
  ##   .i lo krale'u .a lo basysni cu pamoi
  ##   .i lo nacle'u cu ka'e se lidne le pamoi to `Identifiers` toi
  while reader.at < reader.text.len:
    let c = reader.text[reader.at]
    if c == '\\':
      inc reader.at
      result.add reader.readEscape
    elif c in OPENERS_IDENTIFIER or (c in DIGITS and result.len > 0):
      result.add c
      inc reader.at
    else: break
  if result.len == 0: reader.refuse("lo cmene")


func readNumber(reader: var Reader): int =
  ## tcidu lo mulna'u poi pilno pano lerfu
  ##   .i va'o lo nu le mulna'u cu mleca li no kei `-` lidne le mulna'u to `Numbers` toi
  let start = reader.at
  if reader.isAt({'-'}): inc reader.at
  if not reader.isAt(DIGITS): reader.refuse("pa lerfu pe li pano")
  while reader.isAt(DIGITS): inc reader.at
  parseInt(reader.text[start ..< reader.at])


func readLiteral(reader: var Reader): string =
  ## tcidu lo lerpoi
  ##   .i le fancu cu cfari bu'u lo stuzi poi se lidne `"`
  ##   .i le fancu cu sisti bu'u `"` poi fanmo le lerpoi to `String literals` toi
  while true:
    if reader.at >= reader.text.len: reader.refuse("`\"` poi fanmo le lerpoi")
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
    else: reader.refuse("pa me `byte` me'u poi lo lerpoi ka'e vasru ke'a")


func readNode(reader: var Reader): NodeNif =
  ## tcidu lo jgena
  ##   .i le jgena cu du lo jgena poi vasru lo tcita .e lo jgena ku'o .a lo cmene .a lo mulna'u .a
  ##       lo lerpoi
  ##   .i va'o lo nu le jgena cu vasru lo jgena kei le fancu cu tcidu ji'a ro le selvau
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
      if reader.at >= reader.text.len: reader.refuse("`)` poi fanmo le jgena")
      result.children.add reader.readNode
    inc reader.at
  elif reader.isAt({'"'}):
    inc reader.at
    result = NodeNif(kind: KindNif.Literal, text: reader.readLiteral)
  elif reader.isAt(DIGITS + {'-'}):
    result = NodeNif(kind: KindNif.Number, number: reader.readNumber)
  elif reader.isAt(OPENERS_IDENTIFIER + {'\\'}):
    result = NodeNif(kind: KindNif.Identifier, text: reader.readIdentifier)
  else: reader.refuse("pa jgena")
  reader.endToken


func readModule*(text: string): seq[NodeNif] =
  ## tcidu lo selci'a be fi `NIF`
  ##   .i lo minde poi cusku lo namcu pe le tarmi cu zvati lo pamoi stuzi
  ##   .i lo jgena cu se lidne le minde gi'e klama lo fanmo be le se ciska to `Modules` toi
  var reader = Reader(text: text)
  if not text.startsWith(VERSION): reader.refuse("le minde po'u `" & VERSION & "`")
  while true:
    reader.skipWhitespace
    if reader.at >= text.len: break
    result.add reader.readNode
