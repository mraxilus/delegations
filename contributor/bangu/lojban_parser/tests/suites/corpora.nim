## dunda ro se ciska pe le se ciska girzu poi lo cipra cu tcidu ke'a ta'i pa se ciska .i ro mupli pe
##   `CLL 1.1` cu du pa se ciska .i le linji pe le mupli cu se jorne .i lo valsi poi lo kurfa
##   grile'u cu sinxa ke'a cu stali .i ro jufra pe le stodi mupli pe la'o gy. Tatoeba .gy. cu du pa
##   se ciska .i ro ju'agri pe lo prosa pe la'o gy. Wikipedia .gy. cu du pa se ciska .i
##   `test_nif.nim` .e `test_marks.nim` cu tcidu le mintu se ciska .i se ki'u bo le liste cu se
##   ciska pa roi to `Article II.9` toi

{.experimental: "strictFuncs".}

import std/strutils

import ../articles_wikipedia/articles
import ../cll/examples
import ../sample_tatoeba/sentences


func textsCorpora*(): seq[(string, string)] =
  ## dunda lo ckiku .e lo se ciska vu'o pe ro se ciska pe le se ciska girzu .i ro mupli pe la'o gy.
  ##   CLL .gy. cu du pa se ciska .i le linji pe le mupli cu se jorne .i lo valsi poi lo kurfa
  ##   grile'u cu sinxa ke'a cu stali .i ro jufra pe le stodi mupli pe la'o gy. Tatoeba .gy. cu du
  ##   pa se ciska .i ro ju'agri pe la'o gy. Wikipedia .gy. cu du pa se ciska
  for example in EXAMPLES_CLL:
    let text = example.rows.join(" ").multiReplace(("[", ""), ("]", ""))
    result.add ("CLL " & example.number, text)
  for sentence in SENTENCES_TATOEBA: result.add ("Tatoeba " & $sentence.id, sentence.text)
  for paragraph in PARAGRAPHS_WIKIPEDIA:
    result.add ("Wikipedia " & paragraph.article & " " & $paragraph.index, paragraph.text)
