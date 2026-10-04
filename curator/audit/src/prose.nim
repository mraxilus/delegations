## Enforce telegraphic prose in comments, i.e. no articles (Article VI.5), in every kind whose
##   comments `comments.nim` reads.
##   Articles are found, and fixed in Nim, by knoller (`articles.nim`); this module reads each
##   comment of each kind and reports articles found there.
##
##   Cost: label `A` (as in "Appendix `A`") is flagged unless written in backticks.
##   Cost: only English articles; other languages' articles pass.

{.experimental: "strictFuncs".}

import std/strutils
import ../../knoller/src/knoller
import ./[comments, findings, kinds]



func checkProse*(path, source: string; syntax: Syntax): seq[Finding] =
  ## Report every comment line holding article.
  for c in comments(source, syntax):
    let found = c.text.findArticles
    if found.len > 0:
      result.add finding(path, c.line, "Comment holds article; got `" & found.join(", ") & "`.")
