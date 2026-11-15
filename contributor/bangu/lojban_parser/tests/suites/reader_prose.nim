## tcidu lo prosa pe `lojban_parser` ta'i lo lojbo se ciska ja'i `#818`
##   .i ro lerfu pe lo se ciska cu se tcita lo stuzi pe vo'a ne'i lo datnyvei
##   .i dunda ro srera poi le genturfa'i cu tcita ke'a
##   .i lo se ciska poi se tcidu cu du lo se ciska poi re glico cipra cu tcidu ke'a
##   .i se ki'u bo ca lo nu le re cipra cu na tcidu lo prosa pe le vi se gunka ja'i `#817` kei ro le
##     prosa cu se tcidu su'o cipra
##   .i le vi datnyvei cu tcidu ro prosa pagbu poi `english.nim` pe `curator/audit/src/` cu tcidu
##     ke'a ne'i le ci vreji
##   .i ji'a le vi datnyvei cu tcidu ro pinka poi le cipra be lo gadri cu tcidu ke'a
##   .i le javni be lo nu fendi lo prosa pagbu cu fukpi lo javni pe `english.nim` .e `fencedOut` pe
##     `markdown.nim`
##   .i le vi se gunka cu pilno no da pe la'o gy. curator .gy.
##   .i se ki'u bo lo nu cikre pa le re datnyvei cu na mulno pu lo nu le drata datnyvei cu se cipra
##     ja'i `Article II.9`
##   .i ro samtci pagbu cu se tcidu ta'i pa cmene
##   .i le vi datnyvei cu sitna le samtci pagbu sepi'o zo la'o pu lo nu le genturfa'i cu tcidu le
##     samtci pagbu
##   .i se ki'u bo le gerna cu tcidu le samtci pagbu ta'i pa sumti ja'i le soze moi javni pe
##     `CLL 21.1`
##   .i la'o gy. Architect .gy. cu jdice di'u bu'u `#818` ta'i `D1 a`
##   .i zo zo poi lidne lo samtci pagbu cu se to'e curmi ki'u lo nu zo zo ka'e sitna zo la'o poi le
##     vi datnyvei cu jmina ke'a
##   .i lo judri jorne cu se tcidu ta'i lo se ciska pe vo'a
##   .i lo sinxa be lo nu basna cu se vimcu
##   .i ro pinka cu se tcidu ta'i pa se ciska
##   .i le pinka cu se pagbu lo lamji linji noi ro ke'a cu se krasi lo mintu sinxa bu'u lo mintu
##     stuzi
##   .i la'o gy. Architect .gy. cu jdice di'u bu'u `#818` ta'i `D3 a`
##   .i va'o lo nu pa linji pe lo pinka cu pagbu lo cartu kei ro pagbu be le linji cu se tcidu ta'i
##     pa se ciska ki'u lo nu le cipra be lo gadri cu tcidu ji'a le linji
##   .i lo linji pe lo cartu poi vasru no valsi cu na se tcidu
##   .i lo liste sinxa poi krasi pa linji pe lo pinka mu'u `- ` cu sinxa gi'e na valsi
##   .i se ki'u bo le liste sinxa cu na se tcidu
##   .i lo liste sinxa pe lo vreji cu na se tcidu ji'a
##   .i lo datni pagbu poi lo cipra cu tcidu ke'a ta'i lo cmene cu na prosa gi'e stali ta'i lo nu lo
##     cipra cu nitcu ja'i le mumoi sarcu pe `#817`
##   .i `glossary.nim` cu tcidu ta'i lo cmene le linji be lo valsi be'o .e le linji poi se krasi
##     `_Avoid_` ne'i le vlaste
##   .i `provenance.nim` cu tcidu ta'i lo cmene lo sitna be lo cipra be'o poi se krasi `Verified by`
##   .i le vi datnyvei cu tcidu lo prosa poi sruri ro le datni pagbu
##   .i lo sitna cu datni pagbu va'o lo nu `provenance.nim` cu facki le sitna
##   .i le cipra cu facki le sitna va'o lo nu le re valsi .e le lerfu po'u la'o gy. backtick .gy. cu
##     zvati pa linji ki'u lo nu le cipra cu tcidu le mulno datnyvei
##   .i lo sitna poi se fendi fi lo fanmo be lo linji cu prosa
##   .i se ki'u bo le vi datnyvei cu tcidu le sitna
##   .i ro pagbu poi no gerna valsi cu vasru ke'a cu srera
##   .i ro stuzi poi le gerna cu sisti bu'u ke'a cu srera ji'a
##   .i ro srera cu zvati le pamoi lerfu pe le valsi pe vo'a
##   .i ro valsi poi zo si .a zo sa .a zo su cu vimcu ke'a cu srera ji'a
##   .i zo fa'o .e ro se lidne be zo fa'o cu srera ji'a
##   .i lo prosa pe lo vreji cu vimcu no da gi'e fanmo no da
##   .i se ki'u bo ro le valsi cu na se sitna
##   .i ku'i le ciska be le valsi cu djica lo nu le valsi cu se sitna
##
## ni'o jdima fa lo nu le tcidu be lo pinka cu facki lo lerpoi .e lo lerfu .e lo cmene poi se sitna
##   .e lo pinka pe la'o gy. Nim .gy. po'o
##   .i ne'i lo datnyvei pe le vi se gunka le cipra be lo gadri cu tcidu lo pinka pe la'o gy. Nim
##     .gy. po'o

{.experimental: "strictFuncs".}

import std/[options, os, strutils]

import ../../src/lojban_parser/[grammar, prose, stream]


type
  Place* = object
    ## lo stuzi be pa lerfu ne'i lo datnyvei
    ##   .i le stuzi cu du lo namcu pe lo linji .e lo namcu pe lo lerfu ne'i le linji
    ##   .i ro le re namcu cu se krasi li pa
    line*: int  ## lo namcu pe le linji
    column*: int  ## lo namcu pe le lerfu ne'i le linji

  Text* = object
    ## pa lojbo se ciska poi le cipra cu tcidu ke'a
    ##   .i ji'a lo stuzi pe ro lerfu pe le se ciska
    path*: string  ## le pilno cu dunda lo cmene be lo datnyvei poi le se ciska cu se krasi ke'a
    text*: string
      ## le se ciska poi le genturfa'i cu tcidu ke'a
      ##   .i ro samtci pagbu cu se sitna sepi'o zo la'o
      ##   .i lo sinxa be lo judri jorne .e lo sinxa be lo nu basna cu se vimcu
    places*: seq[Place]  ## lo stuzi be ro lerfu pe `text` ne'i lo datnyvei
    faults*: seq[Place]  ## lo stuzi be ro samtci pagbu poi zo zo cu lidne ke'a

  Error* = object
    ## pa srera poi le genturfa'i cu tcita ke'a ne'i lo se ciska
    ##   .i le stuzi be le srera cu du le stuzi be le pamoi lerfu pe le srera
    path*: string  ## lo cmene be lo datnyvei poi le srera cu zvati ke'a
    place*: Place  ## lo stuzi be le srera
    why*: string  ## lo krinu be lo nu to'e curmi be'o .a lo javni poi le gerna cu sisti ne'i ke'a

  Piece = tuple[c: char, place: Place]  ## pa lerfu pe lo datnyvei .e lo stuzi pe le lerfu


const
  DELIMITERS = ["gy", "ky", "ty", "py", "dy", "by", "fy", "vy"]
    ## lo valsi poi zo la'o ka'e sitna lo samtci pagbu sepi'o ke'a
    ##   .i le pamoi valsi poi le samtci pagbu na vasru ke'a ku'o cu se cuxna
  OPENING_COMMENT_HTML = "<!--"  ## lo krasi be lo pinka pe lo papri
  CITATION = "verified by `"
    ## le krasi be lo sitna be lo cipra
    ##   .i `provenance.nim` .e le vi datnyvei cu facki le krasi
    ##   .i lo barda lerfu cu mintu lo cmalu lerfu ne'i lo nu facki
  EXT_NIM = ".nim"  ## lo fanmo be lo cmene poi `provenance.nim` cu tcidu ke'a ta'i lo cipra
  CLOSING_COMMENT_HTML = "-->"  ## lo fanmo be lo pinka pe lo papri


func fencedOut(markdown: string): string =
  ## vimcu ro lerfu pe ro linji pe lo samtci poi se bitmu
  ##   .i le bitmu linji cu se vimcu ji'a
  ##   .i le klani be lo linji .e lo fanmo be ro linji cu stali
  ##   .i fukpi `fencedOut` pe `markdown.nim`
  var is_inside = false
  for line in markdown.splitLines(keepEol = true):
    let is_fence = line.strip.startsWith("```")
    if is_fence: is_inside = not is_inside
    let body = line.strip(leading = false, chars = {'\r', '\n'})
    result.add(if is_fence or is_inside: line[body.len .. ^1] else: line)


func matterOut(markdown: string): string =
  ## vimcu ro lerfu pe lo cfari datni poi se krasi pa linji po'u `---` gi'e se fanmo le bavlamji
  ##   linji po'u `---`
  ##   .i le klani be lo linji cu stali
  ##   .i fukpi `matterOut` pe `english.nim`
  let lines = markdown.splitLines
  if lines.len == 0 or lines[0].strip != "---": return markdown
  var closed = -1
  for i in 1 .. lines.high:
    if lines[i].strip == "---":
      closed = i
      break
  if closed < 0: return markdown
  var kept = lines
  for i in 0 .. closed: kept[i] = ""
  kept.join("\n")


func isCarrying(line: string): bool =
  ## jdice lo du'u xu kau le linji cu bevri lo prosa
  ##   .i ro linji poi na kunti gi'e na sepli linji gi'e na pagbu lo cartu gi'e na stedu linji gi'e
  ##     na sitna linji cu bevri lo prosa
  ##   .i fukpi `isCarrying` pe `english.nim`
  let s = line.strip
  s.len > 0 and not s.startsWith("|") and not s.startsWith("#") and
    not s.startsWith("---") and not s.startsWith(">")


func markerLen(line: string): int =
  ## tcidu lo ni clani be lo liste sinxa poi krasi le linji
  ##   .i li no jalge va'o lo nu no liste sinxa cu krasi le linji
  ##   .i fukpi `markerLen` pe `english.nim`
  if line.len > 1 and line[0] in {'-', '*', '+'} and line[1] == ' ': return 2
  var i = 0
  while i < line.len and line[i] in Digits: inc i
  if i > 0 and i + 1 < line.len and line[i] in {'.', ')'} and line[i + 1] == ' ': return i + 2
  0


func isField(file, line: string): bool =
  ## jdice lo du'u xu kau le linji pe lo vreji cu datni pagbu poi lo cipra cu tcidu ke'a ta'i lo
  ##   cmene
  ##   .i le datni pagbu cu du le linji be lo valsi .a le linji poi se krasi `_Avoid_` ne'i le
  ##     vlaste
  let s = line.strip
  file == "GLOSSARY.md" and
    (s.len > 5 and s.startsWith("**") and s.endsWith("**:") or s.startsWith("_Avoid_"))


func delimiter(span: string): string =
  ## dunda lo valsi poi zo la'o cu sitna lo samtci pagbu sepi'o ke'a
  ##   .i le valsi cu pamoi lo cmima be `DELIMITERS` be'o poi le samtci pagbu na vasru ke'a ta'i lo
  ##     valsi
  var words: seq[string]
  for word in span.splitWhitespace: words.add word.strip(chars = {'.', ','}).toLowerAscii
  for candidate in DELIMITERS:
    if candidate notin words: return candidate
  DELIMITERS[0]


func wordLast(text: string): string =
  ## dunda le romoi valsi pe le se ciska ta'i lo cmalu lerfu
  ##   .i lo denpa sinxa cu se vimcu
  let words = text.splitWhitespace
  if words.len == 0: "" else: words[^1].strip(chars = {'.', ','}).toLowerAscii


func shaped(path: string, pieces: seq[Piece]): Text =
  ## zbasu lo se ciska poi le genturfa'i cu tcidu ke'a ku'o fi lo lerfu pe pa prosa pagbu .a pa
  ##   pinka
  ##   .i ro samtci pagbu cu se sitna sepi'o zo la'o
  ##   .i lo judri jorne cu se tcidu ta'i lo se ciska pe vo'a
  ##   .i lo sinxa be lo nu basna cu se vimcu
  result = Text(path: path)
  var dropped = newSeq[bool](pieces.len)
  # facki ro samtci pagbu
  #   .i ro lerfu po'u la'o gy. backtick .gy. cu krasi ja fanmo pa samtci pagbu ta'i lo nu
  #     `spansCollapsed` pe `english.nim` cu tcidu
  var
    is_span = newSeq[bool](pieces.len)
    is_code = false
  for i, piece in pieces:
    if piece.c == '`':
      is_code = not is_code
      is_span[i] = true
    else: is_span[i] = is_code
  # vimcu ro sitna be lo cipra
  #   .i `provenance.nim` cu tcidu le sitna ta'i lo cmene
  var lower = ""
  for piece in pieces: lower.add piece.c.toLowerAscii
  var at = lower.find(CITATION)
  while at >= 0:
    let close = lower.find('`', at + CITATION.len)
    if close < 0: break
    if lower[at + CITATION.len ..< close].endsWith(EXT_NIM):
      for m in at .. close: dropped[m] = true
    at = lower.find(CITATION, close + 1)
  # vimcu `[` .e `](address)` pe ro judri jorne poi na pagbu lo samtci pagbu
  #   .i se ki'u bo ro judri jorne cu se tcidu ta'i lo se ciska pe vo'a
  var i = 0
  while i < pieces.len:
    if pieces[i].c == '[' and not is_span[i]:
      var j = i + 1
      while j + 1 < pieces.len and not (pieces[j].c == ']' and pieces[j + 1].c == '(') and
          pieces[j].c != '[':
        inc j
      if j + 1 < pieces.len and pieces[j].c == ']' and pieces[j + 1].c == '(':
        var k = j + 2
        while k < pieces.len and pieces[k].c != ')': inc k
        if k < pieces.len:
          dropped[i] = true
          for m in j .. k: dropped[m] = true
          i = k
    inc i
  # ciska ro lerfu poi stali
  #   .i ro samtci pagbu cu se ciska ta'i pa cmene poi se sitna
  i = 0
  while i < pieces.len:
    let piece = pieces[i]
    if dropped[i] or (not is_span[i] and piece.c in {'*', '_'}):
      inc i
      continue
    if piece.c == '`':
      var
        j = i + 1
        span: seq[Piece]
      while j < pieces.len and pieces[j].c != '`':
        span.add pieces[j]
        inc j
      var letters = ""
      for s in span: letters.add s.c
      if result.text.wordLast == "zo": result.faults.add piece.place
      let word = letters.delimiter
      if result.text.len > 0 and result.text[^1] notin Whitespace:
        result.text.add ' '
        result.places.add piece.place
      for c in "la'o " & word & ". ":
        result.text.add c
        result.places.add piece.place
      for s in span:
        result.text.add s.c
        result.places.add s.place
      for c in " ." & word & ".":
        result.text.add c
        result.places.add piece.place
      if j + 1 < pieces.len and pieces[j + 1].c notin Whitespace:
        result.text.add ' '
        result.places.add piece.place
      i = j + 1
      continue
    result.text.add(if piece.c == '\n': ' ' else: piece.c)
    result.places.add piece.place
    inc i


func textsRecord*(path, markdown: string): seq[Text] =
  ## tcidu ro prosa pagbu pe le vreji ta'i pa se ciska
  ##   .i le prosa pagbu cu du ro liste cmima .e ro porsi be lo sampu linji ta'i lo nu `blocks` pe
  ##     `english.nim` cu tcidu
  ##   .i ro lerfu cu se tcita lo stuzi pe vo'a
  var carried: seq[Piece]
  let lines = markdown.fencedOut.matterOut.splitLines
  for i, line in lines:
    let
      opened = line.multiReplace(("<!--", "    "), ("-->", "   "))
      s = opened.strip
    if not line.isCarrying or s.len == 0 or path.extractFilename.isField(line):
      if carried.len > 0: result.add shaped(path, carried)
      carried = @[]
      continue
    let
      lead = opened.len - opened.strip(trailing = false).len
      marker = s.markerLen
    if marker > 0 and carried.len > 0:
      result.add shaped(path, carried)
      carried = @[]
    if carried.len > 0: carried.add ('\n', Place(line: i + 1, column: lead + 1))
    for k in marker ..< s.len: carried.add (s[k], Place(line: i + 1, column: lead + k + 1))
  if carried.len > 0: result.add shaped(path, carried)


type
  Comment = object
    ## pa pinka pe lo samtci ge'u .e le linji pe le pinka ge'u .e lo stuzi pe ro lerfu
    lines: seq[seq[Piece]]  ## lo se ciska pe ro linji poi se lidne lo sinxa be lo pinka
    line: int  ## lo linji poi krasi le pinka
    column: int  ## lo stuzi be lo sinxa be le pinka ne'i le linji
    is_doc: bool  ## le sinxa cu du `##`
    is_trailing: bool  ## lo samtci cu lidne le pinka ne'i le linji pe le pinka
    is_block: bool  ## le pinka cu se sinxa `#[ ]#` .a `##[ ]##`


func commentsNim(source: string): seq[Comment] =
  ## facki ro pinka poi na pagbu lo lerpoi .a lo lerfu .a lo cmene poi se sitna ku'o ne'i lo samtci
  ##   pe la'o gy. Nim .gy.
  var
    i = 0
    (line, column) = (1, 1)
    is_code_before = false  # lo samtci cu lidne ne'i le ca linji

  template advance() =
    if source[i] == '\n':
      inc line
      column = 1
      is_code_before = false
    else: inc column
    inc i

  while i < source.len:
    let c = source[i]
    if c == '#':
      let (opened_line, opened_column, is_trailing) = (line, column, is_code_before)
      if source.continuesWith("##[", i) or source.continuesWith("#[", i):
        let is_doc = source.continuesWith("##[", i)
        var
          depth = 0
          comment = Comment(line: opened_line, column: opened_column, is_doc: is_doc,
            is_trailing: is_trailing, is_block: true)
          current: seq[Piece]
        while i < source.len:
          if source.continuesWith("##[", i) or source.continuesWith("#[", i):
            inc depth
            let width = (if source.continuesWith("##[", i): 3 else: 2)
            for _ in 1 .. width: advance()
            continue
          if source.continuesWith("]#", i):
            dec depth
            advance()
            while i < source.len and source[i] == '#': advance()
            if depth == 0: break
            continue
          if source[i] == '\n':
            comment.lines.add current
            current = @[]
            advance()
            continue
          current.add (source[i], Place(line: line, column: column))
          advance()
        comment.lines.add current
        result.add comment
        is_code_before = true
        continue
      var hashes = 0
      while i < source.len and source[i] == '#':
        inc hashes
        advance()
      var current: seq[Piece]
      while i < source.len and source[i] != '\n':
        current.add (source[i], Place(line: line, column: column))
        advance()
      result.add Comment(lines: @[current], line: opened_line, column: opened_column,
        is_doc: hashes == 2, is_trailing: is_trailing)
      continue
    if c == '"':
      is_code_before = true
      if source.continuesWith("\"\"\"", i):
        for _ in 1 .. 3: advance()
        while i < source.len and not source.continuesWith("\"\"\"", i): advance()
        while i < source.len and source[i] == '"': advance()
        continue
      let is_raw = i > 0 and source[i - 1] in IdentChars
      advance()
      while i < source.len and source[i] notin {'"', '\n'}:
        if source[i] == '\\' and not is_raw: advance()
        if i < source.len: advance()
      if i < source.len and source[i] == '"':
        advance()
        while is_raw and i < source.len and source[i] == '"':
          advance()
          while i < source.len and source[i] notin {'"', '\n'}: advance()
          if i < source.len and source[i] == '"': advance()
      continue
    if c == '\'' and not (i > 0 and source[i - 1] in IdentChars):
      is_code_before = true
      advance()
      if i < source.len and source[i] == '\\':
        advance()
        while i < source.len and source[i] notin {'\'', '\n'}: advance()
      elif i < source.len: advance()
      if i < source.len and source[i] == '\'': advance()
      continue
    if c == '`':
      is_code_before = true
      advance()
      while i < source.len and source[i] notin {'`', '\n'}: advance()
      if i < source.len and source[i] == '`': advance()
      continue
    if c notin Whitespace: is_code_before = true
    advance()


func isRowTable(pieces: seq[Piece]): bool =
  ## jdice lo du'u xu kau le linji pe lo pinka cu pagbu lo cartu
  ##   .i lo pamoi lerfu poi na canlu cu du `|`
  for piece in pieces:
    if piece.c == ' ': continue
    return piece.c == '|'
  false


func cellsRow(path: string, pieces: seq[Piece]): seq[Text] =
  ## tcidu ro pagbu be le linji pe le cartu ta'i pa se ciska
  ##   .i lo pagbu poi vasru `-` .e `:` po'o cu na se tcidu
  var cell: seq[Piece]
  for piece in pieces & @[('|', Place())]:
    if piece.c != '|':
      cell.add piece
      continue
    var letters = ""
    for c in cell: letters.add c.c
    if letters.strip.len > 0 and not letters.strip.allCharsInSet({'-', ':', ' '}):
      result.add shaped(path, cell)
    cell = @[]


func textsSource*(path, source: string): seq[Text] =
  ## tcidu ro pinka pe lo samtci pe la'o gy. Nim .gy. ta'i pa se ciska
  ##   .i lo lamji pinka poi no samtci cu zvati lo linji pe ke'a zi'e poi se krasi lo mintu sinxa
  ##     bu'u lo mintu stuzi cu se jorne ta'i pa se ciska
  ##   .i ro pagbu be ro linji pe lo cartu poi zvati le pinka cu se tcidu ta'i pa se ciska
  let comments = source.commentsNim
  var
    k = 0
    carried: seq[Piece]
  template flush() =
    if carried.len > 0: result.add shaped(path, carried)
    carried = @[]
  template carry(pieces: seq[Piece]) =
    if pieces.isRowTable:
      flush()
      result.add cellsRow(path, pieces)
    else:
      var kept = pieces
      while kept.len > 0 and kept[0].c in Whitespace: kept.delete(0)
      var opening = ""
      for piece in kept: opening.add piece.c
      let marker = opening.markerLen
      if marker > 0: kept = kept[marker .. ^1]
      if kept.len > 0:
        if carried.len > 0: carried.add (' ', kept[0].place)
        carried.add kept
  while k < comments.len:
    let first = comments[k]
    for pieces in first.lines: carry(pieces)
    var j = k + 1
    if not first.is_trailing and not first.is_block:
      while j < comments.len and not comments[j].is_trailing and not comments[j].is_block and
          comments[j].line == comments[j - 1].line + 1 and
          comments[j].column == first.column and comments[j].is_doc == first.is_doc:
        for pieces in comments[j].lines: carry(pieces)
        inc j
    flush()
    k = j


func textsHtml*(path, source: string): seq[Text] =
  ## tcidu ro pinka pe le papri ta'i pa se ciska
  ##   .i ro pinka cu se sinxa `<!-- -->`
  ##   .i le linji pe ro pinka cu se jorne
  var
    (line, column) = (1, 1)
    i = 0
  while i < source.len:
    if source.continuesWith(OPENING_COMMENT_HTML, i):
      for _ in 1 .. OPENING_COMMENT_HTML.len:
        inc column
        inc i
      var pieces: seq[Piece]
      while i < source.len and not source.continuesWith(CLOSING_COMMENT_HTML, i):
        if source[i] == '\n':
          if pieces.len > 0: pieces.add (' ', Place(line: line, column: column))
          inc line
          column = 1
        elif not (source[i] in Whitespace and (pieces.len == 0 or pieces[^1].c == ' ')):
          pieces.add (source[i], Place(line: line, column: column))
          inc column
        else: inc column
        inc i
      if pieces.len > 0: result.add shaped(path, pieces)
      continue
    if source[i] == '\n':
      inc line
      column = 1
    else: inc column
    inc i


func place(text: Text, at: int): Place =
  ## dunda lo stuzi be pa lerfu pe le se ciska ne'i le datnyvei
  ##   .i va'o lo nu le lerfu cu bartu le se ciska kei dunda lo stuzi be le romoi lerfu
  if text.places.len == 0: Place(line: 0, column: 0)
  elif at < text.places.len: text.places[at]
  else: text.places[^1]


func errorsTree(node: Node, marked: ReadingMarked, text: Text, found: var seq[Error]) =
  ## jmina lo stuzi poi ro srera jgena pe le tricu cu sisti bu'u ke'a ku'o .e lo javni poi le srera
  ##   jgena cu sisti ne'i ke'a
  if node.is_terminal: return
  if node.stop.isSome:
    let
      at = node.stop.get.at
      start =
        if at < marked.units.len and marked.units[at].words.len > 0:
          marked.occurrences[marked.units[at].words[0]].start
        else: marked.size
    found.add Error(path: text.path, place: text.place(start), why: "grammar, in " & node.rule)
  for child in node.children: errorsTree(child, marked, text, found)


func errors*(text: Text): seq[Error] =
  ## dunda ro srera poi le genturfa'i cu tcita ke'a ne'i le se ciska ku'o .e ro samtci pagbu poi zo
  ##   zo cu lidne ke'a ku'o pa roi
  ##   .i ki'u bo lo srera jgena pe pa pagbu .e lo srera jgena pe lo se ciska poi vasru le pagbu cu
  ##     sisti bu'u pa stuzi
  var found: seq[Error]
  for fault in text.faults:
    found.add Error(path: text.path, place: fault, why: "`zo` before span")
  if text.text.strip.len > 0:
    let marked = text.text.readTextMarked
    for unit in marked.units:
      if unit.is_read: continue
      let start =
        if unit.words.len > 0: marked.occurrences[unit.words[0]].start else: marked.size
      found.add Error(path: text.path, place: text.place(start),
        why: ($unit.refusal).toLowerAscii)
    errorsTree(marked.tree, marked, text, found)
  for error in found:
    if error notin result: result.add error


func texts*(path, content: string): seq[Text] =
  ## tcidu ro se ciska pe lo datnyvei ja'i lo klesi be le datnyvei
  ##   .i le klesi cu du lo vreji .a lo samtci pe la'o gy. Nim .gy. .a lo papri
  let extension = path.splitFile.ext
  if extension == ".md": path.textsRecord(content)
  elif extension in [".nim", ".nimble"]: path.textsSource(content)
  elif extension == ".html": path.textsHtml(content)
  else: @[]
