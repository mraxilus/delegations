## Hold parser to long articles of lojban Wikipedia against `prose.nim`: each paragraph keeps
##   verdict parser gave at render, and each refused one breaks rule of CLL cited here.
##   Articles are `tests/articles_wikipedia/articles.nim`, which verb `wikipedia` of
##     `tools/build.nim` writes under CC BY-SA beside it (ruling `D5 c` of #819); never library
##     output.
##   Paragraph is line of plain text, read as one text of 21.1: connected text of several
##     sentences, longest of 458 words.
##   Line continuing sentence of line before it, as item of list does, reads alone as text it is;
##     citation says so where that refuses it, and names line it reads with.
##   Verdict and its reading come from `tools/tatoeba.nim`, so suites and verbs define them once
##     (II.9).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[sets, unittest]

import ../../tools/tatoeba
import ../articles_wikipedia/articles


const KEYS_REFUSED = [
  ("cmaci", 2),  # 20, continues line 1, reads joined to it; alone, `.e` and sumti is no fragment
  ("cmaci", 3),  # 20, continues line 1, as line 2 does
  ("cmaci", 13),  # 3.1, digit `3` is no letter of lojban: `3000moi`
  ("cmaci", 16),  # 3.1, digit `1` is no letter of lojban: `16moi`
  ("cmaci", 18),  # 3.1, digit `1` is no letter of lojban: `19xyxy`
  ("cmaci", 21),  # 3.1, digit `1` is no letter of lojban: `193xymoi`
  ("cmaci", 22),  # 4.6, `zei` joins `fermat` to `ro` alone, so `moi` has no number (152)
  ("eliogabalus", 18),  # 4.8, cmene holds no `la` after vowel: `paulas`
  ("lo jbobau", 1),  # 3.1, digit `1` is no letter of lojban: `1987`
  ("lo jbobau", 3),  # 3.1, digit `1` is no letter of lojban: `1987`
  ("lo jbobau", 5),  # 3.1, digit `2` is no letter of lojban: `27`
  ("lo jbobau", 6),  # 3.1, digit `2` is no letter of lojban: `26`
  ("lo jbobau", 9),  # 3.1, `(` is no letter of lojban, around `to ... toi`
  ("lo jbobau", 13),  # 3.1, digit `6` is no letter of lojban: `630`
  ("lo jbobau", 14),  # 3.1, digit `1` is no letter of lojban: `1400`
  ("lo jbobau", 29),  # 14, `tu'u` closes `tu'e` of line 23; alone it closes nothing
  ("lo jbobau", 30),  # 3.9, capital `L` of `Lojban` marks no syllable nor vowel
]
  ## Article and line of each refused paragraph, read against CLL 1.1; citation gives rule broken.



suite "Internal: Wikipedia":
  test "Each paragraph of each article keeps verdict parser gave at render":
    var moved: seq[(string, int)]
    for paragraph in PARAGRAPHS_WIKIPEDIA:
      if paragraph.text.reading.verdict != paragraph.verdict:
        moved.add (paragraph.article, paragraph.index)
    check moved == newSeq[(string, int)]()  # D5 c, each verdict as rendered


  test "Each refused paragraph is read against CLL, with rule it breaks":
    var refused: HashSet[(string, int)]
    for paragraph in PARAGRAPHS_WIKIPEDIA:
      if paragraph.verdict.len > 0: refused.incl (paragraph.article, paragraph.index)
    check refused == KEYS_REFUSED.toHashSet  # KEYS_REFUSED, citation beside each line
