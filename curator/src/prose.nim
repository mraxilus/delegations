## Enforce telegraphic prose in comments, i.e. no articles (Article VI.5).
##   Rule is data: `ARTICLES` lists banned words. Tokeniser is whitespace split with
##   surrounding punctuation stripped, so `(a` and `the.` are caught while `2.2a` and URLs
##   pass. Backtick spans are removed first, so quoted identifiers `a` and `the` pass.
##
##   Cost: label `A` (as in "Appendix `A`") is flagged unless written in backticks.
##   Cost: only English articles; other languages' articles pass.

{.experimental: "strictFuncs".}

import std/strutils
import ./[findings, kinds, comments]


const
  ARTICLES* = ["a", "an", "the"]
    ## Words telegraphic prose omits.
  PUNCTUATION = {
    '.', ',', ';', ':', '!', '?', '(', ')', '[', ']', '{', '}', '"', '\'', '*', '<', '>',
    '/', '-', '_',
  }
    ## Characters stripped from token ends before comparison.


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


func checkProse*(path, source: string, syntax: Syntax): seq[Finding] =
  ## Report every comment line holding article.
  for c in comments(source, syntax):
    let found = c.text.findArticles
    if found.len > 0:
      result.add finding(path, c.line, "Comment holds article; got `" & found.join(", ") & "`.")
