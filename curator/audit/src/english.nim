## Enforce Simplified Technical English in governed prose (Article VI.8).
##   ASD-STE100 is ASD's specification, Issue 9: 53 writing rules and dictionary of about 900
##     approved words. Dictionary is ASD's and is not copied here. Three rules are mechanical
##     enough to check: sentence length, paragraph length, and words outside dictionary that
##     have one approved replacement. Rest holds by reading, as `GUIDE.md` sets out.
##   Paths are data in `ENGLISH_PATHS`, governed documents alone, so no contributor record
##     reddens for rule whose writer has not read it yet. Widening check is one row.
##   Block is bullet, numbered item or run of plain lines, each read alone: list of six
##     bullets is six blocks rather than one paragraph of six sentences. Quote marker is
##     dropped, so quoted example counts words it holds rather than markers before them.
##   Backticked span counts as one word, since reader takes `nim r koch ci` as one name.
##
##   Cost: finding names line block opens on, never line sentence opens on; block is short
##     by rule this check enforces, so distance is small.
##   Cost: sentence ends at stop after letter or closing bracket, so abbreviation carrying
##     period ends sentence early; STE bans those abbreviations, and table below names two.
##   Cost: replacement table is short list rather than dictionary; word outside it passes,
##     and reading catches what table misses.
##   Cost: 25 words is limit for description. Procedure's 20 goes unchecked, since check
##     cannot tell instruction from description.
##   Cost: front matter and fenced code are skipped, so `about:` line of issue template holds
##     by reading.

{.experimental: "strictFuncs".}

import std/strutils
import ./[findings, markdown]


const
  ENGLISH_PATHS* = [
    ".github/ISSUE_TEMPLATE/process-change.md",
    ".github/ISSUE_TEMPLATE/queued-work.md",
    ".github/ISSUE_TEMPLATE/review-finding.md",
    ".github/pull_request_template.md",
    "CLAUDE.md",
    "CONSTITUTION.md",
    "CONTRIBUTOR.md",
    "CURATOR.md",
    "GLOSSARY.md",
    "GUIDE.md",
    "README.md",
    "STYLE.md",
  ]
    ## Documents this check reads; every other prose file holds rule by reading alone.
  SENTENCE_WORDS* = 25
    ## Words one sentence may hold, which is STE's limit for descriptive writing.
  PARAGRAPH_SENTENCES* = 6
    ## Sentences one paragraph may hold.
  ECHO_WORDS = 8
    ## Words finding quotes back of sentence it names.
  SPAN_WORD = "name"
    ## Word backticked span collapses to, so identifier counts once however long it is.
  REPLACEMENTS* = [
    ("additional", "more"),
    ("additionally", "also"),
    ("aforementioned", "this"),
    ("amongst", "among"),
    ("approximately", "about"),
    ("assist", "help"),
    ("attempt", "try"),
    ("commence", "start"),
    ("demonstrate", "show"),
    ("e.g", "for example"),
    ("eliminate", "remove"),
    ("endeavour", "try"),
    ("ensure", "make sure"),
    ("etc", "name what you mean"),
    ("facilitate", "help"),
    ("furthermore", "also"),
    ("hence", "so"),
    ("i.e", "that is"),
    ("in order to", "to"),
    ("indicate", "show"),
    ("initiate", "start"),
    ("leverage", "use"),
    ("methodology", "method"),
    ("modify", "change"),
    ("moreover", "also"),
    ("nevertheless", "but"),
    ("numerous", "many"),
    ("obtain", "get"),
    ("perform", "do"),
    ("possess", "have"),
    ("prior to", "before"),
    ("purchase", "buy"),
    ("regarding", "about"),
    ("subsequently", "then"),
    ("sufficient", "enough"),
    ("terminate", "stop"),
    ("thus", "so"),
    ("utilisation", "use"),
    ("utilise", "use"),
    ("utilize", "use"),
    ("via", "by"),
    ("whilst", "while"),
  ]
    ## Words outside approved dictionary, each with word STE approves, matched without case.
    ## Two carry period, since token keeps period STE's own spelling holds.


type Block* = object
  ## Define one prose block and where it opens.
  text*: string  ## Words joined by single space, backticked spans collapsed.
  line*: int     ## Line block opens on, 1-based.


func spansCollapsed*(text: string): string =
  ## Replace every backticked span with one word, so identifier counts once.
  var is_code = false
  for c in text:
    if c == '`':
      if not is_code: result.add SPAN_WORD
      is_code = not is_code
    elif not is_code: result.add c


func markerLen*(line: string): int =
  ## Read length of list marker line opens with; zero when line opens none.
  if line.len > 1 and line[0] in {'-', '*', '+'} and line[1] == ' ': return 2
  var i = 0
  while i < line.len and line[i] in Digits: inc i
  if i > 0 and i + 1 < line.len and line[i] in {'.', ')'} and line[i + 1] == ' ': return i + 2
  0


func matterOut(markdown: string): string =
  ## Blank front matter, i.e. lines from opening rule to next one, keeping line count.
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
  ## Decide whether line carries prose, i.e. is neither blank, rule, table row nor heading.
  let s = line.strip
  s.len > 0 and not s.startsWith("|") and not s.startsWith("#") and not s.startsWith("---")


func blocks*(markdown: string): seq[Block] =
  ## Collect prose blocks, each list item and each run of plain lines standing alone.
  var words: seq[string]
  var opened = 0
  let lines = markdown.fencedOut.matterOut.splitLines
  for i, line in lines:
    let s = line.strip
      .multiReplace(("<!--", " "), ("-->", " "))
      .strip(trailing = false, chars = {'>', ' '})
      .strip
    if not line.isCarrying or s.len == 0:
      if words.len > 0:
        result.add Block(text: words.join(" "), line: opened)
        words = @[]
      continue
    let marker = s.markerLen
    if marker > 0 and words.len > 0:
      result.add Block(text: words.join(" "), line: opened)
      words = @[]
    if words.len == 0: opened = i + 1
    words.add s[marker .. ^1].spansCollapsed.splitWhitespace
  if words.len > 0: result.add Block(text: words.join(" "), line: opened)


func isSentenceEnd*(word: string): bool =
  ## Decide whether word closes sentence, i.e. stop after letter or closing bracket.
  var i = word.high
  while i >= 0 and word[i] in {'"', '*', '_', '\''}: dec i
  if i < 1 or word[i] notin {'.', '!', '?'}: return false
  word[i - 1] in Letters or word[i - 1] in {')', ']', '"', '%'}


func sentences*(text: string): seq[string] =
  ## Split block into sentences at every word that closes one.
  var words: seq[string]
  for word in text.splitWhitespace:
    words.add word
    if word.isSentenceEnd:
      result.add words.join(" ")
      words = @[]
  if words.len > 0: result.add words.join(" ")


func opening(sentence: string): string =
  ## Quote back first words of sentence, with ellipsis where more follow.
  let words = sentence.splitWhitespace
  if words.len <= ECHO_WORDS: return sentence
  words[0 ..< ECHO_WORDS].join(" ") & " ..."


func tokenised*(text: string): string =
  ## Reduce prose to lowercase words joined by single space, period kept inside word.
  var plain = ""
  for c in text:
    if c in Letters: plain.add c.toLowerAscii
    elif c == '.': plain.add c
    else: plain.add ' '
  var kept: seq[string]
  for token in plain.splitWhitespace:
    let bare = token.strip(chars = {'.'})
    if bare.len > 0: kept.add bare
  " " & kept.join(" ") & " "


func checkEnglish*(path, source: string): seq[Finding] =
  ## Report long sentence, long paragraph and word outside approved dictionary.
  if path notin ENGLISH_PATHS: return
  for b in source.blocks:
    let found = b.text.sentences
    if found.len > PARAGRAPH_SENTENCES:
      result.add finding(
        path, b.line,
        "Paragraph must hold at most " & $PARAGRAPH_SENTENCES &
          " sentences; split it (ASD-STE100); got `" & $found.len & "`.",
      )
    for s in found:
      if s.splitWhitespace.len > SENTENCE_WORDS:
        result.add finding(
          path, b.line,
          "Sentence must hold at most " & $SENTENCE_WORDS &
            " words; split it (ASD-STE100); got `" & s.opening & "`.",
        )
    let plain = b.text.tokenised
    for (word, approved) in REPLACEMENTS:
      if " " & word & " " in plain:
        result.add finding(
          path, b.line,
          "Word is outside approved dictionary; write `" & approved &
            "` (ASD-STE100); got `" & word & "`.",
        )
