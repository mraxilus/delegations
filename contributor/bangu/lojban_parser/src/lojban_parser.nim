## Parse lojban words by rules of CLL alone: letters, cmavo, gismu, rafsi, lujvo, and tanru.
##   Umbrella module: re-exports surface of each module, in order reader learns subject.
##
##   |--------------|------------------------------------------------------|------------------|
##   | Module       | Concept                                              | CLL              |
##   |--------------|------------------------------------------------------|------------------|
##   | clusters     | letters, consonant pairs, initial pairs, triples     | 3.1, 3.6-7       |
##   | forms        | shapes of rafsi, gismu and cmavo, class of word      | 4.2-4, 4.6       |
##   | lujvo        | joining rafsi, scoring lujvo, splitting it back      | 4.5, 4.11-2      |
##   | entries      | entry of gismu list: word and its rafsi              |                  |
##   | dictionary   | words and rafsi of committed gismu list              | 4.6              |
##   | tanru        | word read by rules alone, as parts of its tanru      | 4.2-6, 4.11-2    |
##   | tanru_units  | cmavo binding each tanru unit, conversions composed  | ch. 5, 9, 12, 15 |
##   |--------------|------------------------------------------------------|------------------|
##
##   Order of compile-time type bootstrapping:
##     EntryGismu -> LIST_GISMU
##     LIST_GISMU -> Word
##     Word -> Part
##     Part -> Tanru
##     [Places, Word] -> Link
##     [Link, Part] -> TanruUnit
##   List is data that `nim r tools/build.nim lists` renders; `Word` is range over entries of
##     gismu list, so its bound follows list with no number written twice (Article II.5).
##   List stays off surface: caller wanting every entry imports `lists/gismu` itself, and
##     `entry` of `dictionary` reads one entry of word. List keeps word and rafsi alone; English
##     of gismu list and whole lujvo list stay with `lojban_tagger`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import ./lojban_parser/[clusters, dictionary, entries, forms, lujvo, tanru, tanru_units]

export clusters, dictionary, entries, forms, lujvo, tanru, tanru_units
