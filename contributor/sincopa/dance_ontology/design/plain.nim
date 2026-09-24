## Read prose off page, and hold it to two countable rules of Simplified Technical English
## (`GUIDE.md`, Article VI.8).
##
##   Two rules of subset can be counted: sentence's words and paragraph's sentences.  Rest of
##     subset, from approved word to active voice, is read rather than counted, so nothing here
##     claims to check it.
##   Prose is `p` and `li` text alone.  Caption, swatch label and heading are set in fragments
##     nobody writes sentences in, and to hold them to sentence rule would count label as
##     sentence without full stop.
##   Cost: markup is read by line forms, never parsed, exactly as curator's record checks are.
##     Page carries no comment or fenced block inside its prose, and script and style are cut
##     before reading.

{.experimental: "strictFuncs".}

import std/[strutils]


const
  WORDS* = 25
    ## Words one sentence of description may hold (`GUIDE.md`, "one instruction in one
    ##   sentence").  Instruction takes 20, which is not counted apart here: page describes.
  SENTENCES* = 6
    ## Sentences one paragraph may hold, opened by one that says topic.


func cut(markup, opens, shuts: string): string =
  ## Drop every element of this kind, tag to tag.
  result = markup
  while true:
    let a = result.find(opens)
    if a < 0: return
    let b = result.find(shuts, a)
    if b < 0: return
    result = result[0 ..< a] & " " & result[b + shuts.len .. ^1]


func plain(markup: string): string =
  ## Text of markup: tags out, entities said as what they stand for.
  var out_text = newStringOfCap(markup.len)
  var inside = false
  for ch in markup:
    case ch
    of '<': inside = true
    of '>': inside = false; out_text.add ' '
    else:
      if not inside: out_text.add ch
  out_text.multiReplace(
    ("&mdash;", "-"), ("&nbsp;", " "), ("&middot;", "-"), ("&amp;", "and"),
    ("&frac12;", "half"), ("&#189;", "half"), ("&#188;", "quarter"), ("&frac14;", "quarter"),
    ("&frac34;", "three quarters"), ("&#8722;", "minus"), ("&#10005;", "cross"),
    ("&rsquo;", "'"), ("&ldquo;", "\""), ("&rdquo;", "\""), ("&hellip;", "..."),
    ("&minus;", "minus"), ("&larr;", "left"), ("&rarr;", "right"), ("&#10003;", "tick"),
    ("&#42;", "star"), ("&lt;", "less"), ("&gt;", "more"),
  )


func prose*(markup: string): seq[string] =
  ## Every paragraph of prose on page, as text.
  let body = markup.cut("<script", "</script>").cut("<style", "</style>")
                   .cut("<!--", "-->")
  for kind in ["p", "li"]:
    var at = 0
    while true:
      let opens = body.find("<" & kind, at)
      if opens < 0 or opens + 1 + kind.len >= body.len: break
      # Element of another kind whose name starts same way, such as `path` or `line`.  Step
      #   over its opening tag alone: closing tag reader would find is next paragraph's, so
      #   jumping there skipped every paragraph that stands behind drawing (`tplain.nim`).
      if body[opens + 1 + kind.len] notin {' ', '>'}:
        at = opens + 1
        continue
      let head = body.find('>', opens)
      let shuts = body.find("</" & kind & ">", head)
      if head < 0 or shuts < 0: break
      at = shuts + 1
      let said = body[head + 1 ..< shuts].plain.splitWhitespace.join(" ")
      if said.len > 0: result.add said


func sentences*(paragraph: string): seq[string] =
  ## Sentences of paragraph, split at full stop, question mark and exclamation.
  var said = ""
  for word in paragraph.splitWhitespace:
    said.add (if said.len > 0: " " else: "") & word
    if word.len > 0 and word[^1] in {'.', '!', '?'} and not word.endsWith("..."):
      result.add said
      said = ""
  if said.strip.len > 0: result.add said


func longSentences*(markup: string): seq[string] =
  ## Every sentence of prose over `WORDS` words, whole, so failure names what to split.
  for paragraph in markup.prose:
    for said in paragraph.sentences:
      if said.splitWhitespace.len > WORDS: result.add said


func longParagraphs*(markup: string): seq[string] =
  ## Every paragraph of prose over `SENTENCES` sentences, by its first sentence.
  for paragraph in markup.prose:
    let said = paragraph.sentences
    if said.len > SENTENCES: result.add said[0]


#[ Markdown ]#

func closes(word: string): bool =
  ## Whether word closes sentence of Markdown: stop after letter, digit, bracket or mark,
  ## with closing quote and emphasis stepped over first.
  ##   Test repository's `english` check makes (`isSentenceEnd`), so `**"Stop."**` closes
  ##     sentence here as there.  `sentences` above ends only at bare stop, and read so, two
  ##     sentences run together and paragraph of seven passes as six.
  var i = word.high
  while i >= 0 and word[i] in {'"', '*', '_', '\''}: dec i
  if i < 1 or word[i] notin {'.', '!', '?'}: return false
  word[i - 1] in Letters + Digits or word[i - 1] in {')', ']', '"', '%', '*', '_'}

func markerLen(line: string): int =
  ## Length of list marker line opens with; nought where it opens none.
  if line.len > 1 and line[0] in {'-', '*', '+'} and line[1] == ' ': return 2
  var i = 0
  while i < line.len and line[i] in Digits: inc i
  if i > 0 and i + 1 < line.len and line[i] in {'.', ')'} and line[i + 1] == ' ': return i + 2
  0

func gathered(fragments: openArray[string]): string =
  ## Lines of one block as one text, each backticked span one word, since reader takes
  ## `nim r koch ci` as one name.
  var inSpan = false
  var text = ""
  for c in fragments.join(" "):
    if c == '`':
      if not inSpan: text.add "name"
      inSpan = not inSpan
    elif not inSpan: text.add c
  text.splitWhitespace.join(" ")

func markdownProse*(document: string): seq[string] =
  ## Every block of prose in Markdown document, as text.
  ##   Read as repository's `english` check reads documents it governs
  ##     (`curator/audit/src/english.nim`), so document passing here passes there too.
  ##     Fenced code, table row, heading, rule and `>` quotation carry no prose; blank line
  ##     ends block; list item opens one.  Front matter is not stepped over: no README
  ##     carries it.
  ##   Rule is copied rather than imported.  Suite compiled against curator's own check would
  ##     break whenever curator changed that check, which duty 3 forbids curator to do to
  ##     project.  Cost is two copies to keep agreeing, and `tplain.nim` pins this one.
  var carried: seq[string]
  var fenced = false
  for raw in document.splitLines:
    let line = raw.strip.multiReplace(("<!--", " "), ("-->", " ")).strip
    let fence = raw.strip.startsWith("```")
    if fence: fenced = not fenced
    let carries = not fence and not fenced and line.len > 0 and
                  not line.startsWith("|") and not line.startsWith("#") and
                  not line.startsWith("---") and not line.startsWith(">")
    let marker = (if carries: line.markerLen else: 0)
    if carried.len > 0 and (not carries or marker > 0):
      result.add carried.gathered
      carried = @[]
    if carries: carried.add line[marker .. ^1]
  if carried.len > 0: result.add carried.gathered

func markdownSentences*(text: string): seq[string] =
  ## Sentences of one block of Markdown, split where `closes` says.
  var words: seq[string]
  for word in text.splitWhitespace:
    words.add word
    if word.closes:
      result.add words.join(" ")
      words = @[]
  if words.len > 0: result.add words.join(" ")
