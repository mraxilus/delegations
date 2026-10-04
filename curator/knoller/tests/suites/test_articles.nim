## Replicate Article VI.5: articles found in comment text, and fix deleting each from Nim.

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
