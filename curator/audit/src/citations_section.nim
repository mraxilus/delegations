## Hold each citation of section to section its document holds (CURATOR.md, duty 1).
##   Citation is name of Markdown document, comma, then section: heading or bold rule opening
##     with capital, or quote. Name is `NAME.md` in capitals, path from root, or path opening
##     `../`, backticks optional. Quote is text in double quotes or backticks, after optional
##     `section` or `under`. Rename of heading or move of rule leaves citation naming nothing, and
##     only check sees it, since reader trusts citation and writer of rename never reads it.
##   Further comma and capital name subsection inside section before it, at any depth, as
##     (`GUIDE.md`, Provenance guide, Prune, never narrate) does; `and` and capital name second
##     section beside first. Longest heading opening text after comma wins, since heading may
##     hold comma, as that one does.
##   Match is lenient, as Architect ruled (option b of #892), so citation in telegraphic comment
##     passes (VI.5): case and articles are not compared; first words of heading or bold rule
##     pass, up to first mark; quote passes where text of document outside fences holds its
##     words one after another.
##   Heading is two to six `#` outside fences (`headings` over `fencedOut`), since fence quotes
##     example. Bold rule is line or list item opening with bold text: text to closing `**`,
##     last stop or colon cut, as duty, term of glossary and rule of guide open.
##   Document resolves as reader finds it: bare name at nearest folder above file that holds it,
##     then root, so project code citing `PROVENANCE.md` reads its own record; path from root;
##     path opening `../` or `./` from folder of file. Document tree lacks is skipped.
##   Text read: Markdown outside fences, cut at blank line; comments of every kind through
##     `comments.nim`, comments of consecutive lines joined, so wrapped citation reads whole.
##     Comment after code on its line stands alone, since comment of next line never continues
##     it, as two lines of test that each end in citation show. Line end reads as space, and
##     ends citation after whole name, as heading line followed by paragraph shows.
##   Skipped: article as `VI.5`, `duty N`, `section N` and `§N`, which name no heading; lower
##     case after comma, which continues prose; file name after comma, which lists documents.
##
##   Rejected: word-for-word match, which reports comment dropping article of heading it cites,
##     as VI.5 asks and `koch fix` writes.
##   Rejected: string literals read, since literal split by `&` reads as two broken halves, and
##     fixtures of suite would report themselves.
##   Cost: citation in string literal, as message of finding writes, passes unread.
##   Cost: reference to heading of same document, as `(Boundaries)`, names no document, so its
##     rename stays unseen.
##   Cost: first words pass, so rename keeping first words of heading keeps its citations; quote
##     passes on any text of document, so rule moved to other section keeps its quote.
##   Cost: bare name that project also holds reads file of project, so citation of root glossary
##     from project code reads glossary of that project.
##   Cost: citation of document tree lacks passes, since root holds no file for record that each
##     project holds, which root documents cite.
##   Cost: comments of each file holding `.md` are scanned once more, beside scan of prose check;
##     words of document wait for its first quote, since most documents are cited by heading
##     alone. Time is measured (PROVENANCE.md, Figures).

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils, tables]
import ./[comments, findings, kinds, layout, markdown]


type
  KindToken {.pure.} = enum  ## Define what one token of text is.
    Word  ## Run of letters and digits; apostrophe, hyphen, stop or slash between two joins it.
    Mark  ## Character of punctuation, alone.
    Break  ## Line end inside joined text.

  Token = object  ## Define one token, and where text holds it.
    kind: KindToken  ## Word, mark or line end.
    text: string  ## Spelling as written.
    at: int  ## Offset of first byte in text.

  Target = object  ## Define one section citation may name: heading, or bold rule.
    level: int  ## Level of heading; bold rule takes `LEVEL_BOLD`, under every heading.
    name: seq[string]  ## Tokens as compared: words in lower case and marks; articles, markup out.
    after: int  ## Index of first target past section this one opens.

  Document = object  ## Define what citation of one document is held to.
    targets: seq[Target]  ## Headings and bold rules, in order of line.
    shown: string  ## Text outside fences, line count kept.
    words: Option[seq[string]]
      ## Words of shown text as quote compares them; none until first quote of document reads
      ##   them, since most documents are cited by heading alone.

  Unit = object  ## Define text read whole: Markdown paragraph, or block of comment lines.
    text: string  ## Lines joined by line end.
    starts: seq[int]  ## Offset each line opens at in text.
    lines: seq[int]  ## One-based line of each in file.

  Citation = object  ## Define one citation as text writes it.
    name_document: string  ## Document name as written, backticks out.
    at: int  ## Offset of document name in text.
    rest: int  ## Offset of section after comma.


const
  EXTENSION_MARKDOWN = ".md"  ## Extension of document citation names.
  ARTICLES = ["a", "an", "the"]  ## Words comparison leaves out, as telegraphic comment does.
  MARKUP = {'`', '*'}  ## Marks of code span and emphasis, which comparison passes over.
  JOINERS = {'\'', '-', '.', '/'}  ## Characters joining two runs of word into one.
  LEVEL_BOLD = 7  ## Level of bold rule: under every heading, so it opens no section of its own.
  WORD_SECOND = "and"  ## Word joining second section to first.
  WORDS_QUOTE = ["section ", "under "]  ## Words quote may follow, as `under "Carry …"`.
  LETTERS_CAPITAL = {'A' .. 'Z'}  ## Letters document name and section open with.
  CHARS_FOLDER = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_', '-', '.'}
    ## Characters of folder in document path, `..` and `.` among them.
  CHARS_PATH = CHARS_FOLDER + {'/'}  ## Characters of document path, folders and name.
  CHARS_FILE = CHARS_PATH + {'<', '>'}
    ## Characters of file name listed after comma, placeholder as `<project>.nimble` included.
  NUMERALS_ROMAN = {'I', 'V', 'X'}  ## Numerals article of constitution is numbered with.
  MARKS_COMMENT = {'#', '[', ']', '/', '*', '<', '!', '-'}
    ## Characters opening comment in each syntax `comments.nim` reads, as `#[`, `//` and `<!--`.



#[ Tokens ]#

func isCharWord(c: char): bool =
  ## Decide whether character builds word: letter, digit, underscore, or byte of non-ASCII rune.
  c in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'} or ord(c) >= 0x80


func tokens(text: string): seq[Token] =
  ## Read text as words, marks and line ends; other whitespace separates, and reads as none.
  var i = 0
  while i < text.len:
    let c = text[i]
    if c == '\n':
      if result.len == 0 or result[^1].kind != KindToken.Break:
        result.add Token(kind: KindToken.Break, text: "\n", at: i)
      inc i
    elif c in Whitespace: inc i
    elif c.isCharWord:
      var j = i + 1
      while j < text.len and (text[j].isCharWord or
          (text[j] in JOINERS and j + 1 < text.len and text[j + 1].isCharWord)):
        inc j
      result.add Token(kind: KindToken.Word, text: text[i ..< j], at: i)
      i = j
    else:
      result.add Token(kind: KindToken.Mark, text: $c, at: i)
      inc i


func compared(t: Token): string =
  ## Spell token as comparison reads it: word in lower case, mark as written.
  if t.kind == KindToken.Word: t.text.toLowerAscii else: t.text


func isPassed(t: Token): bool =
  ## Decide whether comparison passes over token: article, markup, or line end inside name.
  case t.kind
  of KindToken.Word: t.compared in ARTICLES
  of KindToken.Mark: t.text[0] in MARKUP
  of KindToken.Break: true


func nameCompared(text: string): seq[string] =
  ## Read heading or bold rule as comparison reads it: tokens compared, those it passes over out.
  for t in text.tokens:
    if not t.isPassed: result.add t.compared


func wordsCompared(text: string): seq[string] =
  ## Read words of text as quote compares them: lower case, articles, marks and line ends out.
  for t in text.tokens:
    if t.kind == KindToken.Word and t.compared notin ARTICLES: result.add t.compared



#[ Documents ]#

func rulesBold(markdown: string): seq[(int, string)] =
  ## Read line and text of each bold rule: line or list item opening with bold text, cut at
  ##   closing `**`, without its last stop or colon.
  ##   Bold text may wrap, so close is sought on later lines of its paragraph too.
  let lines = markdown.splitLines
  for i, line in lines:
    # Pass over quote mark and list marker, bullet or number, to opening of line's text.
    var s = line.strip(trailing = false)
    if s.startsWith("> "): s = s[2 .. ^1].strip(trailing = false)
    var k = 0
    while k < s.len and s[k] in Digits: inc k
    if k > 0 and s.continuesWith(". ", k): s = s[k + 2 .. ^1].strip(trailing = false)
    elif s.len > 1 and s[0] in {'-', '*', '+'} and s[1] == ' ':
      s = s[2 .. ^1].strip(trailing = false)
    if not s.startsWith("**"): continue

    # Read bold text to its close, joining lines of paragraph it wraps over.
    var
      text = s[2 .. ^1]
      last = i
    while "**" notin text and last + 1 < lines.len and lines[last + 1].strip.len > 0:
      inc last
      text.add "\n" & lines[last]
    let close = text.find("**")
    if close < 0: continue
    text = text[0 ..< close].strip
    if text.endsWith('.') or text.endsWith(':'): text.setLen(text.len - 1)
    if text.len > 0: result.add (i + 1, text)


func document(markdown: string): Document =
  ## Read sections of document as citation is held to them, fenced code left out; words wait
  ##   for first quote.
  result.shown = markdown.fencedOut
  var marked: seq[(int, int, string)]
  for h in result.shown.headings: marked.add (h.line, h.level, h.text)
  for (line, text) in result.shown.rulesBold: marked.add (line, LEVEL_BOLD, text)
  marked.sort
  for (_, level, text) in marked:
    let name = text.nameCompared
    if name.len > 0: result.targets.add Target(level: level, name: name)

  # Close each section at first target of its level or above, so subsection lies inside it.
  for i in 0 ..< result.targets.len:
    var j = i + 1
    while j < result.targets.len and result.targets[j].level > result.targets[i].level: inc j
    result.targets[i].after = j


func folder(path: string): string =
  ## Read folder of path, `/` separated; empty at root.
  let slash = path.rfind('/')
  if slash < 0: "" else: path[0 ..< slash]


func pathJoined(folder, name: string): Option[string] =
  ## Join relative name onto folder, `..` and `.` resolved; none where it climbs above root.
  var parts = if folder.len == 0: @[] else: folder.split('/')
  for part in name.split('/'):
    case part
    of "", ".": discard
    of "..":
      if parts.len == 0: return none(string)
      parts.setLen(parts.len - 1)
    else: parts.add part
  some(parts.join("/"))


func pathResolved(path, name: string, lut_index_by_path: Table[string, int]): Option[string] =
  ## Resolve document name that file at path cites, among documents tree holds: bare name at
  ##   nearest folder above file that holds it, then root; path from root; path opening `./` or
  ##   `../` from folder of file.
  if '/' in name:
    let
      is_relative = name.startsWith("./") or name.startsWith("../")
      joined = pathJoined(if is_relative: path.folder else: "", name)
    if joined.isSome and joined.get in lut_index_by_path: return joined
    return none(string)
  var at = path.folder
  while true:
    let candidate = if at.len == 0: name else: at & "/" & name
    if candidate in lut_index_by_path: return some(candidate)
    if at.len == 0: return none(string)
    at = at.folder



#[ Citations ]#

func unitsMarkdown(markdown: string): seq[Unit] =
  ## Cut Markdown outside fenced code into paragraphs, i.e. runs of lines holding text.
  let lines = markdown.fencedOut.splitLines
  var unit = Unit()
  for i, line in lines:
    if line.strip.len == 0:
      if unit.lines.len > 0: result.add unit
      unit = Unit()
      continue
    if unit.lines.len > 0: unit.text.add '\n'
    unit.starts.add unit.text.len
    unit.lines.add i + 1
    unit.text.add line
  if unit.lines.len > 0: result.add unit


func isAfterCode(line, text: string): bool =
  ## Decide whether comment text follows code on its line: anything but whitespace and marks of
  ##   comment before its first word.
  let at = line.find(text.splitWhitespace[0])
  at > 0 and line[0 ..< at].anyIt(it notin Whitespace + MARKS_COMMENT)


func unitsComment(source: string, syntax: Syntax): seq[Unit] =
  ## Join comments of consecutive lines into one block, so wrapped citation reads whole.
  ##   Comment after code stands alone: comment of next line never continues it, as two lines
  ##   of code that each end in comment show.
  ##   Source whose comments name no document gives none, since document name never wraps.
  let found = comments(source, syntax)
  if not found.anyIt(EXTENSION_MARKDOWN in it.text): return
  let lines = source.split('\n')
  var
    unit = Unit()
    is_closed = false
  for c in found:
    let is_after_code = lines[c.line - 1].isAfterCode(c.text)
    if unit.lines.len > 0 and (c.line != unit.lines[^1] + 1 or is_closed or is_after_code):
      result.add unit
      unit = Unit()
    if unit.lines.len > 0: unit.text.add '\n'
    unit.starts.add unit.text.len
    unit.lines.add c.line
    unit.text.add c.text
    is_closed = is_after_code
  if unit.lines.len > 0: result.add unit


func lineAt(unit: Unit, at: int): int =
  ## Read one-based line of file holding offset of text of unit.
  var k = 0
  while k + 1 < unit.starts.len and unit.starts[k + 1] <= at: inc k
  unit.lines[k]


func isPathDocument(path: string): bool =
  ## Decide whether path names document: folders, `..` and `.` among them, then name of
  ##   capitals before extension.
  let
    parts = path.split('/')
    base = parts[^1][0 ..< parts[^1].len - EXTENSION_MARKDOWN.len]
  if base.len == 0 or base[0] notin LETTERS_CAPITAL or
      not base.allCharsInSet(LETTERS_CAPITAL + {'_'}):
    return false
  parts[0 .. ^2].allIt(it.len > 0 and it.allCharsInSet(CHARS_FOLDER))


func citationAt(text: string, extension: int): Option[Citation] =
  ## Read citation whose document name ends in extension at offset, then comma and space; none
  ##   where name or comma breaks form.
  var start = extension
  while start > 0 and text[start - 1] in CHARS_PATH: dec start
  let name = text[start ..< extension + EXTENSION_MARKDOWN.len]
  if not name.isPathDocument: return none(Citation)

  # Backtick closing name needs one opening it; one opening alone opens span of whole citation.
  var after = extension + EXTENSION_MARKDOWN.len
  if after < text.len and text[after] == '`':
    if start == 0 or text[start - 1] != '`': return none(Citation)
    inc after
  if after >= text.len or text[after] != ',': return none(Citation)
  var rest = after + 1
  while rest < text.len and text[rest] in {' ', '\t', '\n'}: inc rest
  if rest == after + 1 or rest >= text.len: return none(Citation)
  some(Citation(name_document: name, at: start, rest: rest))


func citationsWritten(text: string): seq[Citation] =
  ## Find each citation text writes, in order.
  var k = text.find(EXTENSION_MARKDOWN)
  while k >= 0:
    let found = text.citationAt(k)
    if found.isSome: result.add found.get
    k = text.find(EXTENSION_MARKDOWN, k + EXTENSION_MARKDOWN.len)


func isNamingNone(text: string, at: int): bool =
  ## Decide whether section after comma names no heading: article as `VI.5`, `duty N`,
  ##   `section N`, or file name, which lists documents. `§N` opens with no capital, so caller
  ##   skips it with lower case.
  var i = at
  if text.continuesWith("Article ", i): i += "Article ".len
  var k = i
  while k < text.len and text[k] in NUMERALS_ROMAN: inc k
  if k > i and k + 1 < text.len and text[k] == '.' and text[k + 1] in Digits: return true
  for word in ["duty ", "duties ", "section "]:
    if text.continuesWith(word, at) or text.continuesWith(word.capitalizeAscii, at):
      let digit = at + word.len
      if digit < text.len and text[digit] in Digits: return true

  # File name: run of path characters ending in extension, sentence stop cut.
  var j = if text.continuesWith("`", at): at + 1 else: at
  let opening = j
  while j < text.len and text[j] in CHARS_FILE: inc j
  let
    run = text[opening ..< j].strip(leading = false, chars = {'.'})
    dot = run.rfind('.')
  dot >= 0 and dot + 1 < run.len and run[dot + 1] in Letters


func quoteAt(text: string, at: int): Option[(string, int)] =
  ## Read quote opening at offset, after optional `section` or `under`: its text, and offset
  ##   past its close; none where no quote opens there.
  var i = at
  for word in WORDS_QUOTE:
    if text.continuesWith(word, i): i += word.len
  if i >= text.len or text[i] notin {'"', '`'}: return none((string, int))
  let close = text.find(text[i], i + 1)
  if close < 0: return none((string, int))
  some((text[i + 1 ..< close], close + 1))


func isHeldIn(quote, words: openArray[string]): bool =
  ## Decide whether words hold words of quote in order, one after another.
  for i in 0 .. words.len - quote.len:
    var k = 0
    while k < quote.len and words[i + k] == quote[k]: inc k
    if k == quote.len: return true
  false


func matchedName(tokens: openArray[Token], first: int, name: openArray[string]): int =
  ## Match name against tokens from index, passing over what comparison passes over; index past
  ##   last token matched, or `-1`.
  var i = first
  for want in name:
    while i < tokens.len and tokens[i].isPassed: inc i
    if i >= tokens.len or tokens[i].compared != want: return -1
    inc i
  i


func isBoundary(tokens: openArray[Token], at: int): bool =
  ## Decide whether name matched up to index ends there: end of text, line end, mark, or `and`.
  ##   Markup is mark too, since backtick closing span of whole citation ends it.
  at >= tokens.len or tokens[at].kind != KindToken.Word or tokens[at].compared == WORD_SECOND


func wordsFirst(tokens: openArray[Token], first: int): (seq[string], int) =
  ## Read words of section from index to first mark, line end read as space, articles left out;
  ##   index past last word.
  result[1] = first
  var i = first
  while i < tokens.len and tokens[i].kind != KindToken.Mark:
    if tokens[i].kind == KindToken.Word:
      if tokens[i].compared notin ARTICLES: result[0].add tokens[i].compared
      result[1] = i + 1
    inc i


func targetsMatched(
  tokens: openArray[Token], first: int; document: Document; candidates: openArray[int]
): (seq[int], int) =
  ## Match section opening at index against candidate targets; targets matched and index past
  ##   section, none matched where document lacks it.
  ##   Longest name ending at boundary wins; else names opening with words up to first stop.
  var longest = 0
  for c in candidates:
    let
      name = document.targets[c].name
      after = matchedName(tokens, first, name)
    if after < 0 or not tokens.isBoundary(after) or name.len < longest: continue
    if name.len > longest: result = (@[], after)
    longest = name.len
    result[0].add c
  if result[0].len > 0: return
  let (words, after) = tokens.wordsFirst(first)
  result[1] = after
  if words.len == 0: return
  for c in candidates:
    let name = document.targets[c].name
    if name.len >= words.len and name[0 ..< words.len] == words: result[0].add c


func sectionLacking(
  unit: Unit, tokens: openArray[Token], citation: Citation, document: var Document
): Option[string] =
  ## Read text of citation up to section its document lacks; none where it holds each section.
  ##   Comma and capital name subsection inside each target matched; `and` and capital name
  ##   second section among same candidates. Mark of markup after section ends citation, as
  ##   backtick closing its span does.
  ##   Document is `var` for its words alone, which first quote reads.
  var
    candidates = toSeq(0 ..< document.targets.len)
    at = citation.rest
  while true:
    if unit.text.isNamingNone(at): return none(string)
    let quote = unit.text.quoteAt(at)
    if quote.isSome:
      let
        (text, after) = quote.get
        words = text.wordsCompared
      if words.len == 0: return none(string)
      if document.words.isNone: document.words = some(document.shown.wordsCompared)
      if words.isHeldIn(document.words.get): return none(string)
      return some(unit.text[citation.rest ..< after])
    if unit.text[at] notin LETTERS_CAPITAL: return none(string)
    var first = 0
    while first < tokens.len and tokens[first].at < at: inc first
    let (matched, after) = tokens.targetsMatched(first, document, candidates)
    if matched.len == 0:
      let last = tokens[max(after, first + 1) - 1]
      return some(unit.text[citation.rest ..< last.at + last.text.len])

    # Find what follows section: subsection after comma, second section after `and`.
    var i = after
    while i < tokens.len and tokens[i].kind == KindToken.Break: inc i
    if i >= tokens.len: return none(string)
    if tokens[i].kind == KindToken.Mark and tokens[i].text == ",":
      var next: seq[int]
      for c in matched: next.add toSeq(c + 1 ..< document.targets[c].after)
      candidates = next
    elif not (tokens[i].kind == KindToken.Word and tokens[i].compared == WORD_SECOND):
      return none(string)
    inc i
    while i < tokens.len and tokens[i].kind == KindToken.Break: inc i
    if i >= tokens.len: return none(string)
    at = tokens[i].at



#[ Check ]#

func checkCitationsSection*(tree: Tree): seq[Finding] =
  ## Report each citation of section that its document lacks, at line of citation (duty 1).
  ##   Document is read once, at first citation of it; file naming no document is not cut.
  var
    lut_index_by_path: Table[string, int]
    lut_document_by_path: Table[string, Document]
  for k, e in tree:
    if e.kind.isSome and e.kind.get == Kind.Markdown: lut_index_by_path[e.path] = k
  for e in tree:
    if e.kind.isNone or EXTENSION_MARKDOWN notin e.content: continue
    let units =
      if e.kind.get == Kind.Markdown: e.content.unitsMarkdown
      else: e.content.unitsComment(e.kind.get.rule.syntax)
    for unit in units:
      if EXTENSION_MARKDOWN notin unit.text: continue
      let tokens = unit.text.tokens
      for citation in unit.text.citationsWritten:
        let path = pathResolved(e.path, citation.name_document, lut_index_by_path)
        if path.isNone: continue
        if path.get notin lut_document_by_path:
          lut_document_by_path[path.get] = tree[lut_index_by_path[path.get]].content.document
        let lacking = sectionLacking(unit, tokens, citation, lut_document_by_path[path.get])
        if lacking.isNone: continue
        result.add finding(
          e.path,
          unit.lineAt(citation.at),
          Check.SectionCited,
          "Cited section is absent from `" & path.get & "`; got `" &
            lacking.get.replace('\n', ' ') & "`.",
          help = "cite heading or bold rule it holds, or quote its text",
        )
