## Replicate Article I.4: table of header aligns its columns by display width, as eye reads
##   them; fix keeps separator widths, widens column only where text does not fit, changes
##   nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[alignment, findings]


func fixed(source: string): string =
  ## Fix tables of source, as `koch fix` does.
  fixAlignment("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no table finding and fixes to itself again.
  checkAlignment("a.nim", source).len == 0 and fixAlignment("a.nim", source).fixed.len == 0



suite "Article I":
  test "I.4 display width: combining mark none, wide glyph two, any other rune one":
    check displayWidth("abc") == 3
    check displayWidth("𝐋̂") == 1  # bold letter, combining circumflex
    check displayWidth("漢字") == 4  # wide East Asian
    check displayWidth("pˣe₁ ⟇ ☆") == 8  # modifier, subscript, glyph, ambiguous: one each


  test "I.4 row aligned by runes, not by display width, is padded to width eye reads":
    let
      source = "##   |-----|-----|\n##   | 𝐋̂  | b   |\n##   | x   | y   |\n"
      found = checkAlignment("a.nim", source)
    check found.mapIt(it.line) == @[2]  # combining mark makes row one short
    check found[0].message.endsWith("cell 4 wide stands in column of 5; got `𝐋̂`.")
    check source.fixed == "##   |-----|-----|\n##   | 𝐋̂   | b   |\n##   | x   | y   |\n"
    check source.fixed.isSettled


  test "I.4 separator keeps width; cell over it widens column, to text and one space":
    let source = "## |--|----|\n## | name | b |\n## |--|----|\n"
    check source.fixed == "## |------|----|\n## | name | b  |\n## |------|----|\n"
    check source.fixed.isSettled
    let trimmed = "  # |---|\n  # | a        |\n"
    check trimmed.fixed == "  # |---|\n  # | a |\n"  # trailing spaces trimmed to width
    check "## |:--|--:|\n## |abc|de |\n".isSettled  # colons kept, no leading space needed


  test "I.4 no table, ragged table, code and wide row stay as written":
    for kept in [
      "## | a | b |\n",  # no separator row
      "## |---|---|\n## | a | b | c |\n",  # cell counts differ
      "let s = \"|---|\\n| a  |\"\n",  # string, never comment
      "## |---|\n#  | a  |\n",  # prefix differs: two tables, neither one row of other
    ]:
      check kept.fixed == kept
    let wide = "## |-|\n## | " & "x".repeat(97) & " |\n"  # widening crosses 100 runes
    check wide.fixed == wide
    check checkAlignment("a.nim", wide).len == 1  # separator's finding stays for hand
