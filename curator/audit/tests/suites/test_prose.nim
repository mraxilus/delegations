## Replicate Article VI.5: comments are telegraphic, i.e. hold no articles.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../../knoller/src/knoller
import ../../src/[findings, kinds, prose]
import ./fixtures



suite "Article VI":
  test "VI.5 lines reported with articles named, as koch prints them in every kind":
    let found = checkProse("x.nim", "# fine\n# the trap\nlet a = 1  # an alias\n", Syntax.Nim)
    check found.mapIt(it.line) == @[2, 3]  # one finding per offending line
    check found.mapIt(it.brief) == @[
      "comment holds article (VI.5); got `the`",
      "comment holds article (VI.5); got `an`",
    ]  # IV.4 echo value, article where sentence ends
    check checkProse("nim.cfg", "hints:off  # the trap\n", Syntax.Hash).mapIt(it.brief) ==
      @["comment holds article (VI.5); got `the`"]  # other syntax, same words
    check checkProse("a.ts", "// A row.\nlet a = 1\n", Syntax.Slash).mapIt((it.line, it.brief)) ==
      @[(1, "comment holds article (VI.5); got `a`")]  # TypeScript, same words
    check checkProse("README.md", "The row.\n", Syntax.None).len == 0  # prose keeps articles


  test "VI.5 file of project keeping its own prose keeps its words, in every kind":
    # Case: `a` of lojban joins two names as `or`, so comment of `lojban_parser` reads as one
    #   holding article. Domain: Nim, cfg and TypeScript, in listed project and in project of
    #   same domain list leaves out.
    for (file, source, syntax) in [
      ("src/a.nim", "# la .alis. a la .bob. cu klama\n", Syntax.Nim),
      ("nim.cfg", "hints:off  # la .alis. a la .bob. cu klama\n", Syntax.Hash),
      ("src/a.ts", "// la .alis. a la .bob. cu klama\n", Syntax.Slash),
    ]:
      check checkProse(DIRECTORY_PARSER & "/" & file, source, syntax).len == 0  # own language
      check checkProse(DIRECTORY_TAGGER & "/" & file, source, syntax).mapIt(it.brief) ==
        @["comment holds article (VI.5); got `a`"]  # left out



suite "Article VI fixes":
  test "VI.5 lowercase article goes from Nim comment, with space after it":
    let
      source = "## Read the file, then a row.\nlet x = 1  # Hold an index (the end).\n" &
        "#[ Skip the\n   header. ]#\n"
      fix = fixArticles("a.nim", source)
    check fix.source == "## Read file, then row.\nlet x = 1  # Hold index (end).\n" &
      "#[ Skip the\n   header. ]#\n"  # article at line end stays
    check fix.fixed.mapIt(it.line) == @[1, 2]  # one report per line
    check fix.fixed[0].rule == Rule.ArticleInComment
    check checkProse("a.nim", fix.source, Syntax.Nim).mapIt(it.line) == @[3]  # left one alone
    check fixArticles("a.nim", fix.source).fixed.len == 0  # second fix writes nothing
