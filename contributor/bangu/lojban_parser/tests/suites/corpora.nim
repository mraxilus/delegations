## Give each text of corpora that suites read whole: rows of each example of CLL 1.1 joined,
##   words square brackets mark kept; each sentence of sample of Tatoeba; each paragraph of
##   articles of Wikipedia. Suites of NIF and of marks read same texts, so list is written once
##   (II.9).

{.experimental: "strictFuncs".}

import std/strutils

import ../articles_wikipedia/articles
import ../cll/examples
import ../sample_tatoeba/sentences


func textsCorpora*(): seq[(string, string)] =
  ## Give key and text of each text of corpora: rows of each example of CLL joined, words square
  ##   brackets mark kept; each sentence of sample of Tatoeba; each paragraph of Wikipedia.
  for example in EXAMPLES_CLL:
    let text = example.rows.join(" ").multiReplace(("[", ""), ("]", ""))
    result.add ("CLL " & example.number, text)
  for sentence in SENTENCES_TATOEBA: result.add ("Tatoeba " & $sentence.id, sentence.text)
  for paragraph in PARAGRAPHS_WIKIPEDIA:
    result.add ("Wikipedia " & paragraph.article & " " & $paragraph.index, paragraph.text)
