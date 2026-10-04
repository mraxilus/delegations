## Enforce telegraphic prose in comments, i.e. no articles (Article VI.5), and fix it in Nim
##   (`koch fix`).
##   Rule is data: `ARTICLES` lists banned words. Tokeniser is whitespace split with
##   surrounding punctuation stripped, so `(a` and `the.` are caught while `2.2a` and URLs
##   pass. Backtick spans are removed first, so quoted identifiers `a` and `the` pass.
##   Fixer deletes lowercase article, with space after it, in comment of Nim syntax, outside
##     backticks and double quotes, where word after it can open noun phrase: it starts with
##     letter, digit or backtick, is not one letter, and is no function word (`and`, `to`,
##     `is`, …). So `swap a and b` and `a, b` stay, since there `a` names value.
##   No fixer: capital `A`, `An` or `The`, since `A` is often label and capital opens
##     sentence; article with punctuation glued after it (`the.`), at line end, or before
##     word above; article in other syntax, since `koch fix` writes Nim alone.
##
##   Cost: label `A` (as in "Appendix `A`") is flagged unless written in backticks.
##   Cost: only English articles; other languages' articles pass.
##   Cost: variable named `a` before noun stays article to fixer, as in `scale a vector`; fix
##     deletes it, and reading holds that case, which VI.10 asks in backticks anyway.

{.experimental: "strictFuncs".}

import std/[algorithm, strutils]
import ../../knoller/src/knoller
import ./[comments, findings, kinds]


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


func checkProse*(path, source: string; syntax: Syntax): seq[Finding] =
  ## Report every comment line holding article.
  for c in comments(source, syntax):
    let found = c.text.findArticles
    if found.len > 0:
      result.add finding(path, c.line, "Comment holds article; got `" & found.join(", ") & "`.")


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
      result.fixed.add finding(path, line, "article in comment (VI.5)")
