## Replicate Article VI.5: articles found in comment text, check of Nim comments, and fix deleting
##   each from Nim.

{.experimental: "strictFuncs".}

import std/[random, sequtils, strutils, unittest]
import ../../src/knoller/[articles, reports]


const
  TELEGRAPHIC = ["Order", "files", "for", "reader", "learning", "subject,", "not", "compiler."]
    ## Word pool without articles.
  SAMPLES = 300  ## Random comments drawn per property.
  NOUNS = ["Order", "files", "reader", "learning", "subject,", "compiler."]
    ## Words of pool that open noun phrase, so article before one goes.
  APPLIED_MIN = 150  ## Samples that must reach article law; six of eight pool words do.



suite "Article VI":
  test "VI.5 articles found regardless of case and punctuation":
    check findArticles("Skip the header") == @["the"]  # VI.5
    check findArticles("A value, an index (the end).") == @["a", "an", "the"]  # VI.5, order kept
    check findArticles("THE END") == @["the"]  # case-insensitive


  test "VI.5 identifiers, citations and URLs pass":
    check findArticles("compare `a` with `the`").len == 0  # backtick spans removed
    check findArticles("check parity  # 2.2a").len == 0  # citation token
    check findArticles("see https://example.invalid/the/a/path").len == 0  # URL is one token
    check findArticles("a_flags and b_to").len == 0  # underscored names
    check findArticles("2.4a 3b").len == 0  # equation labels


  test "VI.5 property: random telegraphic comments pass, one article fails":
    randomize(0)
    for _ in 1 .. SAMPLES:  # 300 samples, seeded
      var words = newSeqWith(rand(1 .. 8), TELEGRAPHIC[rand(TELEGRAPHIC.high)])
      check findArticles(words.join(" ")).len == 0  # no article, no finding
      words.insert(["a", "An", "the."][rand(2)], rand(words.len))
      check findArticles(words.join(" ")).len == 1  # one article, one finding


  test "VI.5 check names each line whose comments hold article, with articles found":
    let found = checkArticles("x.nim", "# fine\n# the trap\nlet a = 1  # an alias\n")
    check found.mapIt((it.line, it.rule, it.message)) == @[
      (2, Rule.ArticleInComment, "Comment holds article; got `the`."),
      (3, Rule.ArticleInComment, "Comment holds article; got `an`."),
    ]  # one finding to line, value echoed
    check checkArticles("x.nim", "#[ A row ]# let b = 2  # the end\n").mapIt(it.message) ==
      @["Comment holds article; got `a, the`."]  # comments of one line, one finding
    check checkArticles("x.nim", "let s = \"the row\"\n").len == 0  # string, never comment
    check checkArticles("x.cfg", [(4, "Skip the header")]).mapIt((it.line, it.message)) ==
      @[(4, "Comment holds article; got `the`.")]  # lines of other syntax, same words


  test "VI.5 comment lines drop markers, hide hashes of literals, and nest blocks":
    check "x = 1 # note\n## doc\n### deep\n".linesComment ==
      @[(1, "note"), (2, "doc"), (3, "deep")]  # marker runs stripped
    check "x = 1 # note\n\n## doc\n".linesComment.mapIt(it[0]) == @[1, 3]  # one-based lines
    for (source, line) in [
      ("a = \"# not\" # yes\n", 1),  # plain string
      ("a = r\"x\\#\"\"\" # yes\n", 1),  # raw string with "", backslash before hash
      ("a = \"\"\"\n# inside\n\"\"\" # yes\n", 3),  # triple string
      ("a = '#' # yes\n", 1),  # char literal
      ("a = '\\n' # yes\n", 1),  # escaped char literal
      ("a = 1'i32 # yes\n", 1),  # numeric suffix quote
    ]:
      check source.linesComment == @[(line, "yes")]
    check "discard \"\"\"\naction: run\n\"\"\"\n# after\n".linesComment == @[(4, "after")]
    check "#[ Basis Conversion ]#\n".linesComment == @[(1, "Basis Conversion")]  # banner
    check "#[ one\n two #[ inner ]# tail\n three ]# x = 1 # four\n".linesComment ==
      @[(1, "one"), (2, "two inner tail"), (3, "three four")]  # nested, line by line
    check "##[ doc block ]##\n".linesComment == @[(1, "doc block")]  # doc block
    check "# `#[ x ]#` in line comment\n".linesComment ==
      @[(1, "`#[ x ]#` in line comment")]  # markers of line comment are its text



suite "Article VI fixes":
  test "VI.5 article naming value, capital, glued punctuation, code and quote stay":
    for kept in [
      "# Swap a and b.\n",  # function word after: `a` names value
      "# Given a, b.\n",  # punctuation glued
      "# The end.\n",  # capital opens sentence
      "# Appendix A lists rows.\n",  # capital label
      "# Use `the` word.\n",  # backtick span
      "# Print \"the row\" verbatim.\n",  # quote
      "# Move a b.\n",  # one letter after: likely names
      "let s = \"the row\"\n",  # string, never comment
    ]:
      check fixArticles("a.nim", kept).source == kept


  test "VI.5 property: fix deletes each inserted article before noun, and nothing else":
    randomize(0)
    var applied = 0
    for _ in 1 .. SAMPLES:  # 300 samples, seeded
      var words = newSeqWith(rand(1 .. 8), TELEGRAPHIC[rand(TELEGRAPHIC.high)])
      let plain = "# " & words.join(" ") & "\n"
      check fixArticles("a.nim", plain).source == plain  # telegraphic stays
      let at = rand(words.high)
      if words[at] notin NOUNS: continue  # function word after article: article kept
      words.insert(["a", "an", "the"][rand(2)], at)
      check fixArticles("a.nim", "# " & words.join(" ") & "\n").source == plain
      inc applied
    check applied >= APPLIED_MIN  # guard filters out few samples
