## dunda ro selci'a pe le selci'agri poi lo cipra cu tcidu ke'a ta'i pa selci'a
##   .i ro mupli pe `CLL 1.1` du pa selci'a
##   .i le linji pe le mupli cu seljo'e
##   .i lo valsi poi lo kurfa grile'u cu sinxa ke'a stali
##   .i ro jufra pe le stomupli pe `Tatoeba` du pa selci'a
##   .i ro ju'agri pe lo prosa pe `Wikipedia` du pa selci'a
##   .i `test_nif.nim` .e `test_marks.nim` tcidu le mitselci'a
##   .i se ki'u bo le liste cu selci'a pa roi to `Article II.9` toi

{.experimental: "strictFuncs".}

import std/strutils

import ../articles_wikipedia/articles
import ../cll/examples
import ../sample_tatoeba/sentences


func textsCorpora*(): seq[(string, string)] =
  ## dunda lo ckiku .e lo selci'a vu'o pe ro selci'a pe le selci'agri
  ##   .i ro mupli pe `CLL` du pa selci'a
  ##   .i le linji pe le mupli cu seljo'e
  ##   .i lo valsi poi lo kurfa grile'u cu sinxa ke'a stali
  ##   .i ro jufra pe le stomupli pe `Tatoeba` du pa selci'a
  ##   .i ro ju'agri pe `Wikipedia` du pa selci'a
  for example in EXAMPLES_CLL:
    let text = example.rows.join(" ").multiReplace(("[", ""), ("]", ""))
    result.add ("CLL " & example.number, text)
  for sentence in SENTENCES_TATOEBA: result.add ("Tatoeba " & $sentence.id, sentence.text)
  for paragraph in PARAGRAPHS_WIKIPEDIA:
    result.add ("Wikipedia " & paragraph.article & " " & $paragraph.index, paragraph.text)
