## tcidu lo prosa pe `ricyso'o` ta'i lo jboselci'a ja'i `#818`
##   .i ro lerfu pe lo selci'a cu se tcita lo stuzi pe vo'a ne'i lo datnyvei
##   .i dunda ro srera poi le genturfa'i cu tcita ke'a
##   .i lo selci'a poi se tcidu cu du lo selci'a poi re glicipra cu tcidu ke'a
##   .i se ki'u bo ca lo nu le re cipra cu na tcidu lo prosa pe le vi selgu'a ja'i `#817` kei ro le
##       prosa cu se tcidu su'o cipra
##
## ni'o le vi datnyvei cu tcidu ro rospau poi `english.nim` pe `curator/audit/src/` tcidu ke'a ne'i
##     le ci vreji ku'o .e ro pinka poi le cipra be lo gadri cu tcidu ke'a
##   .i le javni be lo nu fendi lo rospau cu fukpi lo javni pe `english.nim` .e `fencedOut` pe
##       `markdown.nim`
##   .i le vi selgu'a cu pilno no da pe `curator`
##   .i se ki'u bo lo nu cikre pa le re datnyvei cu na mulno pu lo nu le drata datnyvei cu se cipra
##       ja'i `Article II.9`
##
## ni'o ro samtci pagbu cu se tcidu ta'i pa cmene
##   .i le vi datnyvei cu sitna le samtci pagbu sepi'o zo la'o pu lo nu le genturfa'i cu tcidu le
##       samtci pagbu
##   .i se ki'u bo le gerna cu tcidu le samtci pagbu ta'i pa sumti ja'i le soze moi javni pe
##       `CLL 21.1`
##   .i `Architect` jdice di'u bu'u `#818` ta'i `D1 a`
##   .i zo zo poi lidne lo samtci pagbu cu se to'e curmi ki'u lo nu zo zo ka'e sitna zo la'o poi le
##       vi datnyvei cu jmina ke'a
##
## ni'o lo judryjo'e cu se tcidu ta'i lo selci'a pe vo'a
##   .i lo sinxa be lo nu basna cu selvi'u
##
## ni'o ro pinka cu se tcidu ta'i pa selci'a gi'e selpau lo lamli'i noi ro ke'a selkra lo mitsni
##     bu'u lo mitstu
##   .i `Architect` jdice di'u bu'u `#818` ta'i `D3 a`
##
## ni'o va'o lo nu pa linji pe lo pinka cu pagbu lo cartu kei ro pagbu be le linji cu se tcidu ta'i
##     pa selci'a ki'u lo nu le cipra be lo gadri cu tcidu ji'a le linji
##   .i lo linji pe lo cartu poi vasru no valsi cu na se tcidu
##   .i lo stesni poi krasi pa linji pe lo pinka mu'u `- ` sinxa gi'e na valsi
##   .i se ki'u bo le stesni cu na se tcidu
##   .i lo stesni pe lo vreji cu na se tcidu ji'a
##
## ni'o lo datnypau poi lo cipra cu tcidu ke'a ta'i lo cmene cu na prosa gi'e stali ta'i lo nu lo
##     cipra cu nitcu ja'i le mumoi sarcu pe `#817`
##   .i `glossary.nim` tcidu ta'i lo cmene le linji be lo valsi be'o .e le linji poi selkra
##       `_Avoid_` ne'i le vlaste
##   .i `provenance.nim` tcidu ta'i lo cmene lo sitna be lo cipra be'o poi selkra `Verified by`
##   .i le vi datnyvei cu tcidu lo prosa poi sruri ro le datnypau
##
## ni'o lo sitna cu datnypau va'o lo nu `provenance.nim` facki le sitna
##   .i le cipra cu facki le sitna va'o lo nu le re valsi .e le lerfu po'u `backtick` zvati pa linji
##       ki'u lo nu le cipra cu tcidu le mulno datnyvei
##   .i lo sitna poi se fendi fi lo fanmo be lo linji cu prosa
##   .i se ki'u bo le vi datnyvei cu tcidu le sitna
##
## ni'o ro pagbu poi no genvla cu vasru ke'a srera
##   .i ro stuzi poi le gerna cu sisti bu'u ke'a srera
##   .i ro srera cu zvati le pamoi lerfu pe le valsi pe vo'a
##
## ni'o ro valsi poi zo si .a zo sa .a zo su vimcu ke'a srera
##   .i zo fa'o .e ro se lidne be zo fa'o cu srera
##   .i lo prosa pe lo vreji cu vimcu no da gi'e fanmo no da
##   .i se ki'u bo ro le valsi cu na se sitna
##   .i ku'i le ciska be le valsi cu djica lo nu le valsi cu se sitna
##
## ni'o le vi datnyvei cu facki lo srera be lo nu punji lo selci'a fi lo linji ja'i `#818`
##   .i ro jufra cu krasi pa linji
##   .i ro ju'agri pe lo vreji cu selkra zo ni'o
##   .i ro stedu pe lo vreji poi se tcidu cu selkra su'o re cmavo po'u zo ni'o
##
## ni'o le genturfa'i cu facki ro krasi be lo jufra fi lo tricu
##   .i se ki'u bo zo .i poi zvati lo se sitna ku'o .e zo .i poi se lidne zo zo krasi no jufra
##   .i ku'i zo .i poi zvati lo se jmina be zo to cu krasi pa jufra
##
## ni'o jdima fa lo nu le tcidu be lo pinka cu facki lo lerpoi .e lo lerfu .e lo cmene poi se sitna
##     .e lo pinka pe `Nim` po'o
##   .i ne'i lo datnyvei pe le vi selgu'a le cipra be lo gadri cu tcidu lo pinka pe `Nim` po'o

{.experimental: "strictFuncs".}

import std/[options, os, strutils]

import ../../src/ricysoho/[grammar, prose, selmaho, stream]


type
  Place* = object
    ## lo stuzi be pa lerfu ne'i lo datnyvei
    ##   .i le stuzi cu du lo namcu pe lo linji ge'u .e lo namcu pe lo lerfu ne'i le linji
    ##   .i ro le re namcu cu selkra li pa
    line*: int  ## lo namcu pe le linji
    column*: int  ## lo namcu pe le lerfu ne'i le linji

  Shape* = enum
    ## lo tarmi be pa selci'a ne'i lo datnyvei
    ##   .i le tarmi cu jdice lo javni be lo nu punji le selci'a fi lo linji
    Paragraph  ## lo rospau pe lo vreji
    Item  ## lo stecmi pe lo vreji
    Definition  ## lo smuni be pa valsi pe le vlaste
    Heading  ## lo cmene be pa pagbu pe lo vreji
    Run  ## lo pinka poi ro linji be ke'a cu selkra lo mitsni bu'u lo mitstu
    Trailing  ## lo pinka poi lo samtci cu lidne ke'a ne'i lo linji pe ke'a
    Banner  ## lo pinka poi selsni `#[ ]#` gi'e cmene pa pagbu be lo samtci
    Cell  ## pa pagbu be pa linji pe lo cartu
    Page  ## lo pinka pe le papri

  Text* = object
    ## pa jboselci'a poi le cipra cu tcidu ke'a
    ##   .i ji'a lo stuzi pe ro lerfu pe le selci'a
    path*: string  ## le pilno cu dunda lo cmene be lo datnyvei poi le selci'a cu selkra ke'a
    shape*: Shape  ## lo tarmi be le selci'a ne'i le datnyvei
    opening*: int
      ## lo klani be lo cmavo po'u zo ni'o poi krasi le selci'a
      ##   .i li ni'u pa va'o lo nu no javni cu jdice le klani
    text*: string
      ## le selci'a poi le genturfa'i cu tcidu ke'a
      ##   .i ro samtci pagbu cu se sitna sepi'o zo la'o
      ##   .i lo sinxa be lo judryjo'e .e lo sinxa be lo nu basna cu selvi'u
    places*: seq[Place]  ## lo stuzi be ro lerfu pe `text` ne'i lo datnyvei
    faults*: seq[Place]  ## lo stuzi be ro samtci pagbu poi zo zo lidne ke'a

  Error* = object
    ## pa srera poi le genturfa'i cu tcita ke'a ne'i lo selci'a
    ##   .i le stuzi be le srera cu du le stuzi be le pamoi lerfu pe le srera
    path*: string  ## lo cmene be lo datnyvei poi le srera cu zvati ke'a
    place*: Place  ## lo stuzi be le srera
    why*: string  ## lo krinu be lo nu to'e curmi be'o .a lo javni poi le gerna cu sisti ne'i ke'a

  Piece = tuple[c: char, place: Place]  ## pa lerfu pe lo datnyvei ge'u .e lo stuzi pe le lerfu


const
  DELIMITERS = ["gy", "ky", "ty", "py", "dy", "by", "fy", "vy"]
    ## lo valsi poi zo la'o ka'e sitna lo samtci pagbu sepi'o ke'a
    ##   .i le pamoi valsi poi le samtci pagbu na vasru ke'a selcu'a
  OPENING_COMMENT_HTML = "<!--"  ## lo krasi be lo pinka pe lo papri
  CITATION = "verified by `"
    ## le krasi be lo sitna be lo cipra
    ##   .i `provenance.nim` .e le vi datnyvei cu facki le krasi
    ##   .i lo brale'u cu mintu lo cmale'u ne'i lo nu facki
  EXT_NIM = ".nim"  ## lo fanmo be lo cmene poi `provenance.nim` tcidu ke'a ta'i lo cipra
  CLOSING_COMMENT_HTML = "-->"  ## lo fanmo be lo pinka pe lo papri
  HEADINGS_FIXED = ["Standards", "Language", "Open questions"]
    ## lo cmene be lo pagbu poi lo cipra pe `curator` tcidu ke'a ta'i lo cmene
    ##   .i le cmene cu glico gi'e na se tcidu
  OPENING_TITLED = 3
    ## lo klani be lo cmavo po'u zo ni'o poi krasi le pamoi prosa pagbu poi se lidne lo stedu poi na
    ##     se tcidu
  OPENINGS_HEADING = [2: 3, 3: 2]
    ## lo klani be lo cmavo po'u zo ni'o poi krasi lo stedu ja'i lo klani be zoi gy. # .gy.
  TERMINALS_OPENING = [Selmaho.I.toTerminal, Selmaho.Niho.toTerminal]
    ## lo genvla poi krasi pa jufra .a pa ju'agri
  RULE_TEXT = "text"  ## lo javni poi le selci'a cu mapti ke'a
  RULE_SENTENCE = "sentence"  ## lo javni poi pa jufra cu mapti ke'a
  RULE_TERMS = "terms"  ## lo javni poi lo porsi be lo sumti cu mapti ke'a
  RULE_TAIL = "bridi-tail"
    ## lo javni poi le selbri pe pa jufra ge'u .e le sumti poi se lidne le selbri cu mapti ke'a
  RULE_SELBRI = "selbri"  ## lo javni poi pa selbri cu mapti ke'a
  TERMINALS_JOINING = [TERMINAL_BRIVLA, Selmaho.Se.toTerminal, Selmaho.Nu.toTerminal,
    Selmaho.Nahe.toTerminal, Selmaho.Jai.toTerminal, Selmaho.Me.toTerminal,
    Selmaho.Goha.toTerminal, Selmaho.Ke.toTerminal]
    ## lo genvla poi ka'e krasi pa taurpau
    ##   .i lo genturfa'i poi na cuxna cu jmina le genvla lo tanru poi kalri to `CLL 21.2` toi
  RULE_QUOTING = "sumti-6"
    ## lo javni poi vasru lo se sitna be zo lu .e zo li'u
    ##   .i lo jgena po'u `text` poi selvau lo jgena po'u `sumti-6` sinxa lo se sitna
    ##   .i ku'i lo jgena po'u `text` poi selvau lo jgena po'u `free` sinxa lo se jmina be zo to
  CHARS_LEADING = {' ', '.', '#', '[', '<', '!', '-', '*', '+', '_'}
    ## lo lerfu poi ka'e lidne pa krasi be lo jufra ne'i pa linji
    ##   .i le lerfu cu du lo calyle'u .e lo sinxa be lo pinka .e lo stesni .e lo sinxa be lo nu
    ##       basna
  SHAPES_FLOWING = {Paragraph, Item, Definition, Run, Page}
    ## lo tarmi be lo selci'a poi ka'e zvati su'o re linji
  INDENT_SENTENCE = 2
    ## lo namcu poi lo stuzi be lo na pamoi jufra cu sumji ke'a lo stuzi be le pamoi linji
  INDENT_BROKEN = 4
    ## lo namcu poi lo stuzi be lo linji poi lo jufra cu ranji ke'a cu sumji ke'a lo stuzi be le
    ##     linji poi krasi le jufra
    ##   .i `Architect` jdice le namcu bu'u `#890`


func fencedOut(markdown: string): string =
  ## vimcu ro lerfu pe ro linji pe lo samtci poi selbi'u
  ##   .i le bimli'i cu se vimcu ji'a
  ##   .i le klani be lo linji .e lo fanmo be ro linji cu stali
  ##   .i fukpi `fencedOut` pe `markdown.nim`
  var is_inside = false
  for line in markdown.splitLines(keepEol = true):
    let is_fence = line.strip.startsWith("```")
    if is_fence: is_inside = not is_inside
    let body = line.strip(leading = false, chars = {'\r', '\n'})
    result.add(if is_fence or is_inside: line[body.len .. ^1] else: line)


func matterOut(markdown: string): string =
  ## vimcu ro lerfu pe lo cfadatni poi selkra pa linji po'u `---` gi'e selfa'o le bavlamji linji
  ##     po'u `---`
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
  ##   .i ro linji poi na kunti gi'e na sepli'i gi'e na pagbu lo cartu gi'e na sedli'i gi'e na
  ##       sitli'i cu bevri lo prosa
  ##   .i fukpi `isCarrying` pe `english.nim`
  let s = line.strip
  s.len > 0 and not s.startsWith("|") and not s.startsWith("#") and
    not s.startsWith("---") and not s.startsWith(">")


func markerLen(line: string): int =
  ## tcidu lo ni clani be lo stesni poi krasi le linji
  ##   .i li no jalge va'o lo nu no stesni cu krasi le linji
  ##   .i fukpi `markerLen` pe `english.nim`
  if line.len > 1 and line[0] in {'-', '*', '+'} and line[1] == ' ': return 2
  var i = 0
  while i < line.len and line[i] in Digits: inc i
  if i > 0 and i + 1 < line.len and line[i] in {'.', ')'} and line[i + 1] == ' ': return i + 2
  0


func isField(file, line: string): bool =
  ## jdice lo du'u xu kau le linji pe lo vreji cu datnypau poi lo cipra cu tcidu ke'a ta'i lo cmene
  ##   .i le datnypau cu du le linji be lo valsi .a le linji poi selkra `_Avoid_` ne'i le vlaste
  let s = line.strip
  file == "GLOSSARY.md" and
    (s.len > 5 and s.startsWith("**") and s.endsWith("**:") or s.startsWith("_Avoid_"))


func delimiter(span: string): string =
  ## dunda lo valsi poi zo la'o sitna lo samtci pagbu sepi'o ke'a
  ##   .i le valsi cu pamoi lo cmima be `DELIMITERS` be'o poi le samtci pagbu na vasru ke'a ta'i lo
  ##       valsi
  var words: seq[string]
  for word in span.splitWhitespace: words.add word.strip(chars = {'.', ','}).toLowerAscii
  for candidate in DELIMITERS:
    if candidate notin words: return candidate
  DELIMITERS[0]


func wordLast(text: string): string =
  ## dunda le romoi valsi pe le selci'a ta'i lo cmale'u
  ##   .i lo depsni cu selvi'u
  let words = text.splitWhitespace
  if words.len == 0: "" else: words[^1].strip(chars = {'.', ','}).toLowerAscii


func shaped(path: string, pieces: seq[Piece]): Text =
  ## zbasu lo selci'a poi le genturfa'i cu tcidu ke'a ku'o fi lo lerfu pe pa rospau .a pa pinka
  ##   .i ro samtci pagbu cu se sitna sepi'o zo la'o
  ##   .i lo judryjo'e cu se tcidu ta'i lo selci'a pe vo'a
  ##   .i lo sinxa be lo nu basna cu selvi'u
  result = Text(path: path)
  var dropped = newSeq[bool](pieces.len)
  # facki ro samtci pagbu
  #   .i ro lerfu po'u `backtick` krasi ja fanmo pa samtci pagbu ta'i lo nu `spansCollapsed` pe
  #       `english.nim` tcidu
  var
    is_span = newSeq[bool](pieces.len)
    is_code = false
  for i, piece in pieces:
    if piece.c == '`':
      is_code = not is_code
      is_span[i] = true
    else: is_span[i] = is_code
  # vimcu ro sitna be lo cipra
  #   .i `provenance.nim` tcidu le sitna ta'i lo cmene
  var lower = ""
  for piece in pieces: lower.add piece.c.toLowerAscii
  var at = lower.find(CITATION)
  while at >= 0:
    let close = lower.find('`', at + CITATION.len)
    if close < 0: break
    if lower[at + CITATION.len ..< close].endsWith(EXT_NIM):
      for m in at .. close: dropped[m] = true
    at = lower.find(CITATION, close + 1)
  # vimcu `[` .e `](address)` pe ro judryjo'e poi na pagbu lo samtci pagbu
  #   .i se ki'u bo ro judryjo'e cu se tcidu ta'i lo selci'a pe vo'a
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
  #   .i ro samtci pagbu cu selci'a ta'i pa cmene poi se sitna
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
  ## tcidu ro rospau pe le vreji ta'i pa selci'a
  ##   .i le rospau cu du ro stecmi .e ro porsi be lo sapli'i ta'i lo nu `blocks` pe `english.nim`
  ##       tcidu
  ##   .i ro stedu cu se tcidu ta'i pa selci'a
  ##   .i ku'i le stedu be le vreji .e lo stedu poi lo cipra cu tcidu ke'a ta'i lo cmene cu na se
  ##       tcidu
  ##   .i ro lerfu cu se tcita lo stuzi pe vo'a
  var
    carried: seq[Piece]
    (shape, opening) = (Shape.Paragraph, 1)
    is_titled = false  # le bavla'i prosa pagbu cu se lidne lo stedu poi na se tcidu
    is_term = false  # le bavla'i prosa pagbu cu se lidne lo linji be lo valsi pe le vlaste
  template flush() =
    if carried.len > 0:
      var text = shaped(path, carried)
      (text.shape, text.opening) = (shape, opening)
      result.add text
    carried = @[]
  let lines = markdown.fencedOut.matterOut.splitLines
  for i, line in lines:
    let
      opened = line.multiReplace(("<!--", "    "), ("-->", "   "))
      s = opened.strip
      lead = opened.len - opened.strip(trailing = false).len
    if s.startsWith("#"):
      flush()
      let level = s.len - s.strip(trailing = false, chars = {'#'}).len
      is_titled = level == 1 or s[level .. ^1].strip in HEADINGS_FIXED
      is_term = false
      if is_titled or level notin 2 .. 3: continue
      var
        pieces: seq[Piece]
        k = level
      while k < s.len and s[k] == ' ': inc k
      for m in k ..< s.len: pieces.add (s[m], Place(line: i + 1, column: lead + m + 1))
      var text = shaped(path, pieces)
      (text.shape, text.opening) = (Shape.Heading, OPENINGS_HEADING[level])
      result.add text
      continue
    if not line.isCarrying or s.len == 0 or path.extractFilename.isField(line):
      flush()
      if s.len > 0: is_term = path.extractFilename.isField(line) and not s.startsWith("_Avoid_")
      continue
    let marker = s.markerLen
    if marker > 0 and carried.len > 0: flush()
    if carried.len == 0:
      (shape, opening) =
        if marker > 0: (Shape.Item, (if is_titled: OPENING_TITLED else: 0))
        elif is_term: (Shape.Definition, 0)
        else: (Shape.Paragraph, (if is_titled: OPENING_TITLED else: 1))
      (is_titled, is_term) = (false, false)
    if carried.len > 0: carried.add ('\n', Place(line: i + 1, column: lead + 1))
    for k in marker ..< s.len: carried.add (s[k], Place(line: i + 1, column: lead + k + 1))
  flush()


type
  Comment = object
    ## pa pinka pe lo samtci ge'u .e le linji pe le pinka ge'u .e lo stuzi pe ro lerfu
    lines: seq[seq[Piece]]  ## lo selci'a pe ro linji poi se lidne lo sinxa be lo pinka
    line: int  ## lo linji poi krasi le pinka
    column: int  ## lo stuzi be lo sinxa be le pinka ne'i le linji
    is_doc: bool  ## le sinxa cu du `##`
    is_trailing: bool  ## lo samtci cu lidne le pinka ne'i le linji pe le pinka
    is_block: bool  ## le pinka cu selsni `#[ ]#` .a `##[ ]##`
    tier: int  ## lo klani be lo lerfu po'u zoi gy. [ .gy. poi lidne lo sinxa be le pinka


func commentsNim(source: string): seq[Comment] =
  ## facki ro pinka poi na pagbu lo lerpoi .a lo lerfu .a lo cmene poi se sitna ku'o ne'i lo samtci
  ##     pe `Nim`
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
        let
          is_doc = source.continuesWith("##[", i)
          tier = (if source.continuesWith("#[[", i): 2 else: 1)
        var
          depth = 0
          comment = Comment(line: opened_line, column: opened_column, is_doc: is_doc,
            is_trailing: is_trailing, is_block: true, tier: tier)
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
  ## tcidu ro pagbu be le linji pe le cartu ta'i pa selci'a
  ##   .i lo pagbu poi vasru `-` .e `:` po'o na se tcidu
  var cell: seq[Piece]
  for piece in pieces & @[('|', Place())]:
    if piece.c != '|':
      cell.add piece
      continue
    var letters = ""
    for c in cell: letters.add c.c
    if letters.strip.len > 0 and not letters.strip.allCharsInSet({'-', ':', ' '}):
      var text = shaped(path, cell)
      (text.shape, text.opening) = (Shape.Cell, -1)
      result.add text
    cell = @[]


func textsSource*(path, source: string): seq[Text] =
  ## tcidu ro pinka pe lo samtci pe `Nim` ta'i pa selci'a
  ##   .i lo lampinka poi no samtci cu zvati lo linji pe ke'a zi'e poi selkra lo mitsni bu'u lo
  ##       mitstu cu seljo'e ta'i pa selci'a
  ##   .i ro pagbu be ro linji pe lo cartu poi zvati le pinka cu se tcidu ta'i pa selci'a
  let comments = source.commentsNim
  var
    k = 0
    carried: seq[Piece]
    (shape, opening) = (Shape.Run, 0)
  template flush() =
    if carried.len > 0:
      var text = shaped(path, carried)
      (text.shape, text.opening) = (shape, opening)
      result.add text
    carried = @[]
  template carry(pieces: seq[Piece]) =
    if pieces.isRowTable:
      flush()
      result.add cellsRow(path, pieces)
      opening = 1  # le rospau poi se lidne lo cartu cu ju'agri
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
    (shape, opening) =
      if first.is_trailing: (Shape.Trailing, -1)
      elif first.is_block: (Shape.Banner, OPENINGS_HEADING[first.tier + 1])
      else: (Shape.Run, 0)
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
  ## tcidu ro pinka pe le papri ta'i pa selci'a
  ##   .i ro pinka cu selsni `<!-- -->`
  ##   .i le linji pe ro pinka cu seljo'e
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
      if pieces.len > 0:
        var text = shaped(path, pieces)
        (text.shape, text.opening) = (Shape.Page, 0)
        result.add text
      continue
    if source[i] == '\n':
      inc line
      column = 1
    else: inc column
    inc i


func place(text: Text, at: int): Place =
  ## dunda lo stuzi be pa lerfu pe le selci'a ne'i le datnyvei
  ##   .i va'o lo nu le lerfu cu bartu le selci'a kei dunda lo stuzi be le romoi lerfu
  if text.places.len == 0: Place(line: 0, column: 0)
  elif at < text.places.len: text.places[at]
  else: text.places[^1]


func errorsTree(node: Node, marked: ReadingMarked, text: Text, found: var seq[Error]) =
  ## jmina lo stuzi poi ro srejge pe le tricu cu sisti bu'u ke'a ku'o .e lo javni poi le srejge cu
  ##     sisti ne'i ke'a
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


func errors*(text: Text, marked: ReadingMarked): seq[Error] =
  ## dunda ro srera poi le genturfa'i cu tcita ke'a ne'i le selci'a ku'o .e ro samtci pagbu poi zo
  ##     zo lidne ke'a ku'o pa roi
  ##   .i `marked` se tcidu fi le selci'a
  ##   .i ki'u bo lo srejge pe pa pagbu .e lo srejge pe lo selci'a poi vasru le pagbu cu sisti bu'u
  ##       pa stuzi
  var found: seq[Error]
  for fault in text.faults:
    found.add Error(path: text.path, place: fault, why: "`zo` before span")
  if text.text.strip.len > 0:
    for unit in marked.units:
      if unit.is_read: continue
      let start =
        if unit.words.len > 0: marked.occurrences[unit.words[0]].start else: marked.size
      found.add Error(path: text.path, place: text.place(start),
        why: ($unit.refusal).toLowerAscii)
    errorsTree(marked.tree, marked, text, found)
  for error in found:
    if error notin result: result.add error


func errors*(text: Text): seq[Error] =
  ## dunda ro srera poi le genturfa'i cu tcita ke'a ne'i le selci'a
  ##   .i le vi fancu cu tcidu le selci'a gi'e pilno `errors` poi seldu'a lo se tcidu
  text.errors(text.text.readTextMarked)


func openersTree(node: Node, units: seq[Unit], parent: string, found: var seq[int]) =
  ## jmina lo namcu be ro pagbu poi krasi pa jufra .a pa ju'agri pe le jgena
  ##   .i `parent` du lo cmene be le javni pe lo jgena poi vasru le jgena
  ##   .i lo jgena po'u `text` poi selvau lo jgena po'u `sumti-6` sinxa lo se sitna
  ##   .i se ki'u bo no pagbu pe le se sitna cu se jmina
  if node.is_terminal:
    if node.at < units.len and units[node.at].is_read and
        units[node.at].terminal in TERMINALS_OPENING:
      found.add node.at
    return
  if node.rule == RULE_TEXT and parent == RULE_QUOTING: return
  for child in node.children: openersTree(child, units, node.rule, found)


func indentLine(line: string, shape: Shape, is_first: bool): int =
  ## dunda lo stuzi be le pamoi lerfu pe le selci'a ne'i le linji
  ##   .i lo pinka cu kancu le stuzi ba le sinxa be le pinka
  ##   .i lo vreji cu kancu le stuzi ba le krasi be le linji .a le stesni
  let s = line.strip(trailing = false)
  case shape
  of Run:
    let body = s.strip(trailing = false, chars = {'#'})
    body.len - body.strip(trailing = false).len
  of Page:
    if is_first:
      let body = s[min(OPENING_COMMENT_HTML.len, s.len) .. ^1]
      body.len - body.strip(trailing = false).len
    else: line.len - s.len - OPENING_COMMENT_HTML.len
  of Item:
    line.len - s.len + (if is_first: s.markerLen else: 0)
  else: line.len - s.len


func faultsLayout*(text: Text, lines: seq[string], marked: ReadingMarked,
    checked: var int): seq[Error] =
  ## dunda ro srera be lo nu punji le selci'a fi lo linji ja'i lo seljdi pe `#818`
  ##   .i `lines` du ro linji pe le datnyvei
  ##   .i `marked` se tcidu fi le selci'a
  ##
  ## ni'o ro krasi be lo jufra .e lo ju'agri cu krasi lo linji
  ##   .i `INDENT_SENTENCE` jdice lo stuzi be lo na pamoi jufra
  ##   .i ku'i ne'i lo stecmi lo jufra poi na pamoi cu zvati lo stuzi be le pamoi lerfu pe le stecmi
  ##   .i `INDENT_BROKEN` jdice lo stuzi be lo linji poi lo jufra cu ranji ke'a
  ##   .i ro ju'agri pe lo pinka cu se lidne lo linji poi vasru lo sinxa be le pinka po'o
  ##
  ## ni'o `checked` se jmina lo klani be lo linji poi le vi fancu cu cipra ke'a
  template fault(at: Place, reason: string) =
    result.add Error(path: text.path, place: at, why: reason)
  if text.opening >= 0:
    let words = text.text.splitWhitespace
    var count = 0
    while count < words.len and words[count] == "ni'o": inc count
    let is_marked = text.shape != Shape.Item or (count < words.len and words[count] == "ny.mai")
    if count != text.opening or not is_marked: fault(text.place(0), "opening")
  if text.text.strip.len == 0: return
  var openers: seq[int]
  for child in marked.tree.children: openersTree(child, marked.units, RULE_TEXT, openers)
  var (lines_sentence, lines_paragraph) = (newSeq[int](), newSeq[int]())
  for at in openers:
    let unit = marked.units[at]
    # le pamoi valsi cu krasi le selci'a bu'u lo stuzi be le selci'a
    #   .i zo ni'o poi se lidne zo ni'o pagbu lo krasi be lo ju'agri
    if at == 0 or unit.words.len == 0: continue
    if unit.terminal == Selmaho.Niho.toTerminal and marked.units[at - 1].is_read and
        marked.units[at - 1].terminal == Selmaho.Niho.toTerminal:
      continue
    let
      place = text.place(marked.occurrences[unit.words[0]].start)
      line = lines[place.line - 1]
    var leading = line[0 ..< min(place.column - 1, line.len)]
    if text.shape == Shape.Cell: leading = leading[leading.rfind('|') + 1 .. ^1]
    if not leading.allCharsInSet(CHARS_LEADING): fault(place, "sentence opens mid-line")
    elif unit.terminal == Selmaho.Niho.toTerminal: lines_paragraph.add place.line
    else: lines_sentence.add place.line
  if text.shape notin SHAPES_FLOWING: return
  var seen: seq[int]
  for place in text.places:
    if place.line notin seen: seen.add place.line
  var (first, sentence) = (0, 0)
  for j, number in seen:
    let
      line = lines[number - 1]
      column = line.indentLine(text.shape, j == 0)
      place = Place(line: number, column: line.len - line.strip(trailing = false).len + 1)
    inc checked
    if j == 0:
      let wanted =
        case text.shape
        of Run, Page: 1
        of Item: column
        else: 0
      if column != wanted: fault(place, "indent")
      (first, sentence) = (wanted, wanted)
      continue
    let is_after_bare = number >= 2 and lines[number - 2].strip in ["#", "##"]
    if (number in lines_paragraph) != (text.shape == Shape.Run and is_after_bare):
      fault(place, "paragraph")
    let wanted =
      if number in lines_paragraph: first
      elif number in lines_sentence:
        if text.shape == Shape.Item: first else: first + INDENT_SENTENCE
      else: sentence + INDENT_BROKEN
    if column != wanted: fault(place, "indent")
    if number in lines_paragraph or number in lines_sentence: sentence = wanted


func spanUnits(node: Node): tuple[first, last: int] =
  ## dunda lo stuna'u be le pamoi pagbu be'o .e lo stuna'u be le romoi pagbu pe le jgena
  ##   .i va'o lo nu le jgena cu vasru no pagbu kei le romoi stuna'u cu du li ni'u pa
  if node.is_terminal: return (node.at, node.at)
  result = (int.high, -1)
  for child in node.children:
    let span = child.spanUnits
    if span.last >= 0:
      result.first = min(result.first, span.first)
      result.last = max(result.last, span.last)


func isEndingOpen(node: Node, last: int): bool =
  ## jdice lo du'u xu kau pa selbri poi le jgena cu vasru ke'a fanmo bu'u le pagbu poi `last`
  ##     stuna'u ke'a
  ##   .i lo selbri poi fanmo bu'u le romoi pagbu be lo sumti cu kalri
  if node.is_terminal: return false
  if node.rule == RULE_SELBRI and node.spanUnits.last == last: return true
  for child in node.children:
    if child.isEndingOpen(last): return true


func joinedTree(node: Node, units: seq[Unit], parent: string, found: var seq[int]) =
  ## jmina lo stuna'u be le pamoi pagbu be ro selbri poi na se lidne zo cu gi'e se lidne lo sumti
  ##     poi lo selbri poi kalri cu fanmo ke'a
  ##   .i va'o lo nu le pamoi pagbu cu ka'e krasi pa taurpau kei le genturfa'i poi na cuxna cu jmina
  ##       le selbri lo tanru poi kalri
  ##   .i `parent` du lo cmene be le javni pe lo jgena poi vasru le jgena
  if node.is_terminal: return
  if node.rule == RULE_TEXT and parent == RULE_QUOTING: return
  if node.rule == RULE_SENTENCE and node.children.len == 2 and
      not node.children[0].is_terminal and node.children[0].rule == RULE_TERMS and
      not node.children[1].is_terminal and node.children[1].rule == RULE_TAIL:
    let
      last = node.children[0].spanUnits.last
      first = node.children[1].spanUnits.first
    if last >= 0 and first > last and first < units.len and units[first].is_read and
        units[first].terminal in TERMINALS_JOINING and node.children[0].isEndingOpen(last):
      found.add first
  for child in node.children: joinedTree(child, units, node.rule, found)


func faultsJoined*(text: Text, marked: ReadingMarked): seq[Error] =
  ## dunda ro selbri poi na se lidne zo cu gi'e se lidne lo sumti poi lo selbri poi kalri cu fanmo
  ##     ke'a
  ##   .i `marked` se tcidu fi le selci'a
  ##   .i le vi genturfa'i cu tcidu le selbri ta'i lo selbri pe le jufra
  ##   .i ku'i lo genturfa'i poi na cuxna cu jmina le selbri le tanru poi kalri gi'e na tcidu lo
  ##       jufra to `CLL 21.2` toi
  var found: seq[int]
  joinedTree(marked.tree, marked.units, "", found)
  for at in found:
    let start = marked.occurrences[marked.units[at].words[0]].start
    result.add Error(path: text.path, place: text.place(start),
      why: "selbri after open tanru, with no cu")


func texts*(path, content: string): seq[Text] =
  ## tcidu ro selci'a pe lo datnyvei ja'i lo klesi be le datnyvei
  ##   .i le klesi cu du lo vreji .a lo samtci pe `Nim` ge'u .a lo papri
  let extension = path.splitFile.ext
  if extension == ".md": path.textsRecord(content)
  elif extension in [".nim", ".nimble"]: path.textsSource(content)
  elif extension == ".html": path.textsHtml(content)
  else: @[]
