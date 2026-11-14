## Enforce telegraphic prose in comments, i.e. no articles (Article VI.5), in every kind whose
##   comments `comments.nim` reads.
##   Articles are found, reported and fixed in Nim by knoller (`articles.nim`): Nim source takes
##   its check whole, which reads comments as its fixer does; comments of every other syntax are
##   read here and passed to same check, so each kind reports in same words, with article
##   `toFinding` cites.
##   File of project whose prose stays in its own language is read by none of this
##     (`prose_own.nim`): word reading as English article is word of that language there, as `a`
##     of lojban joins two names as `or`.
##
##   Cost: label `A` (as in "Appendix `A`") is flagged unless written in backticks.
##   Cost: only English articles; other languages' articles pass.

{.experimental: "strictFuncs".}

import std/sequtils
import ../../knoller/src/knoller
import ./[comments, findings, kinds, prose_own]



func checkProse*(path, source: string; syntax: Syntax): seq[Finding] =
  ## Report every comment line holding article, outside project keeping its own prose.
  if path.isProseOwn: return
  if syntax == Syntax.Nim: return checkArticles(path, source).toFindings
  checkArticles(path, comments(source, syntax).mapIt((it.line, it.text))).toFindings
