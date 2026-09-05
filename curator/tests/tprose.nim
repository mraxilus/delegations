discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article VI.5: comments are telegraphic, i.e. hold no articles.

import std/[random, sequtils, strutils, unittest]
import ../src/[kinds, prose]


const
  TELEGRAPHIC = ["Order", "files", "for", "reader", "learning", "subject,", "not", "compiler."]
    ## Word pool without articles.
  SAMPLES = 300
    ## Random comments drawn per property.


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

  test "VI.5 lines reported with articles named":
    let found = checkProse("x.nim", "# fine\n# the trap\nlet a = 1  # an alias\n", Syntax.Nim)
    check found.mapIt(it.line) == @[2, 3]  # one finding per offending line
    check found[0].message.endsWith("got `the`.")  # IV.4 echo value
    check found[1].message.endsWith("got `an`.")  # IV.4 echo value

  test "VI.5 property: random telegraphic comments pass, one article fails":
    randomize(0)
    for _ in 1 .. SAMPLES:  # 300 samples, seeded
      var words = newSeqWith(rand(1 .. 8), TELEGRAPHIC[rand(TELEGRAPHIC.high)])
      check findArticles(words.join(" ")).len == 0  # no article, no finding
      words.insert(["a", "An", "the."][rand(2)], rand(words.len))
      check findArticles(words.join(" ")).len == 1  # one article, one finding
