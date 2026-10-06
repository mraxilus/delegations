## Find articles in comment text, and delete them from Nim comments (Article VI.5, `koch fix`).
##   Rule is data: `ARTICLES` lists banned words. Tokeniser is whitespace split with
##   surrounding punctuation stripped, so `(a` and `the.` are caught while `2.2a` and URLs
##   pass. Backtick spans are removed first, so quoted identifiers `a` and `the` pass.
##   Check reads comments of Nim source from tokens, as fixer reads them (`commentLines`), one
##     finding to line; caller reading comments of other syntax passes its lines, so every
##     kind reports in same words (`curator/audit`, `prose.nim`).
##   Fixer deletes lowercase article, with space after it, in comment of Nim syntax, outside
##     backticks and double quotes, where word after it can open noun phrase: it starts with
##     letter, digit or backtick, is not one letter, and is no function word (`and`, `to`,
##     `is`, …). So `swap a and b` and `a, b` stay, since there `a` names value.
##   No fixer: capital `A`, `An` or `The`, since `A` is often label and capital opens
##     sentence; article with punctuation glued after it (`the.`), at line end, or before
##     word above.
##
##   Cost: variable named `a` before noun stays article to fixer, as in `scale a vector`; fix
##     deletes it, and reading holds that case, which VI.10 asks in backticks anyway.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[reports, tokens]


const
  ARTICLES* = ["a", "an", "the"]  ## Words telegraphic prose omits.
  PUNCTUATION = {
    '.', ',', ';', ':', '!', '?', '(', ')', '[', ']', '{', '}', '"', '\'', '*', '<', '>',
    '/', '-', '_',
  }
    ## Characters stripped from token ends before comparison.
  OPENERS = {'(', '['}  ## Brackets article may follow glued, which cut keeps.
  FUNCTION_WORDS = [
    "a", "an", "and", "are", "as", "at", "be", "been", "but", "by", "for", "from", "if", "in",
    "into", "is", "it", "its", "nor", "not", "of", "on", "onto", "or", "so", "than", "that",
    "the", "then", "this", "to", "was", "were", "when", "where", "which", "while", "with",
  ]
    ## Words no noun phrase opens with, so article before one is likely name of value.


func stripCodeSpans(text: string): string =
  ## Remove backtick-delimited spans, leaving space so neighbours stay separate.
  var is_code = false
  for c in text:
    if c == '`':
      is_code = not is_code
      result.add ' '
    elif not is_code:
      result.add c


func findArticles*(text: string): seq[string] =
  ## Collect article tokens present in comment text, in order of appearance.
  for word in text.stripCodeSpans.splitWhitespace:
    let bare = word.strip(chars = PUNCTUATION).toLowerAscii
    if bare in ARTICLES: result.add bare


func commentLines*(source: string): seq[(int, string)] =
  ## Read text comments of Nim source hold on each line, as one-based line and text: markers
  ##   stripped, comments of one line joined, whitespace runs collapsed, line of no text left out.
  ##   Line comment drops its run of `#`; block comment drops `#[`, `##[` and each nested
  ##   opener, and `]#` with run of `#` after it, as lexer pairs them (`tokens.nim`).

  template keep(line: int, text: string) =
    ## Add text to entry of its line, joined to comment before it there.
    if result.len > 0 and result[^1][0] == line: result[^1][1].add " " & text
    else: result.add (line, text)

  # Read text of each comment line by line; block comment leaves its markers out.
  for t in source.tokens:
    if t.kind != TokenKind.Comment: continue
    let is_block = source.continuesWith("#[", t.first) or source.continuesWith("##[", t.first)
    var
      k = t.first
      line = t.line
      text = ""
    if source.continuesWith("##[", k): k += 3
    elif is_block: k += 2
    else:
      while k < t.after and source[k] == '#': inc k
    while k < t.after:
      if source[k] == '\n':
        keep(line + 1, text)
        text = ""
        inc line
        inc k
      elif is_block and source.continuesWith("#[", k): k += 2
      elif is_block and source.continuesWith("]#", k):
        k += 2
        while k < t.after and source[k] == '#': inc k
      else:
        text.add source[k]
        inc k
    keep(line + 1, text)

  # Collapse whitespace runs, and leave out line of no text.
  result = result.mapIt((it[0], it[1].splitWhitespace.join(" "))).filterIt(it[1].len > 0)


func checkArticles*(path: string, lines: openArray[(int, string)]): seq[Report] =
  ## Report each comment line holding article, from one-based line and text of each (VI.5), so
  ##   caller reading comments of other syntax reports in same words.
  for (line, text) in lines:
    let found = text.findArticles
    if found.len == 0: continue
    result.add initReport(
      path,
      line,
      Rule.ArticleInComment,
      "Comment holds article; got `" & found.join(", ") & "`.",
    )


func checkArticles*(path, source: string): seq[Report] =
  ## Report each line whose comments in Nim source hold article (VI.5).
  checkArticles(path, source.commentLines)


func articleCuts(source: string): seq[(int, int)] =
  ## Find byte span of each lowercase article fixer deletes, with spaces after it, in Nim
  ##   comments; outside backtick spans and double quotes, before word opening noun phrase.
  for t in source.tokens:
    if t.kind != TokenKind.Comment: continue
    var
      k = t.first
      is_code = false
      is_quoted = false
    while k < t.after:
      let c = source[k]
      if c in Whitespace:
        inc k
        continue

      # Read whitespace-free word, tracking backtick and quote state across it.
      let first = k
      var is_plain = not is_code and not is_quoted
      while k < t.after and source[k] notin Whitespace:
        if source[k] == '`':
          is_code = not is_code
          is_plain = false
        elif source[k] == '"':
          is_quoted = not is_quoted
          is_plain = false
        inc k
      if not is_plain: continue
      var opening = first
      while opening < k and source[opening] in OPENERS: inc opening
      if source[opening ..< k] notin ARTICLES: continue

      # Read word after spaces of same line; it must open noun phrase.
      var next = k
      while next < t.after and source[next] in {' ', '\t'}: inc next
      if next >= t.after or source[next] in {'\n', '\r'}: continue
      var stop = next
      while stop < t.after and source[stop] notin Whitespace: inc stop
      let word = source[next ..< stop].strip(chars = PUNCTUATION)
      if source[next] notin {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '`'}: continue
      if word.len <= 1 or word.toLowerAscii in FUNCTION_WORDS: continue
      result.add (opening, next)


func fixArticles*(path, source: string): Fix =
  ## Delete each article `articleCuts` finds, last first, so earlier offsets hold.
  let cuts = source.articleCuts
  result.source = source
  var reported: seq[int]
  for (first, after) in cuts.reversed:
    result.source = result.source[0 ..< first] & result.source[after .. ^1]
  for (first, _) in cuts:
    let line = source[0 ..< first].count('\n') + 1
    if line notin reported:
      reported.add line
      result.fixed.add initReport(path, line, Rule.ArticleInComment)
