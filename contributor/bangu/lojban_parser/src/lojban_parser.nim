## Parse lojban by rules of CLL alone: letters, each class of word, rafsi, tanru, stream, prose.
##   Umbrella module: re-exports surface of each module, in order reader learns subject.
##
##   |--------------|------------------------------------------------------|------------------|
##   | Module       | Concept                                              | CLL              |
##   |--------------|------------------------------------------------------|------------------|
##   | clusters     | letters, consonant pairs, initial pairs, triples     | 3.1, 3.6-7       |
##   | forms        | shapes of rafsi, gismu and cmavo, class of word      | 4.2-4, 4.6       |
##   |              | rules of cmene and fu'ivla by letters, and pauses    | 4.7-9            |
##   | lujvo        | joining rafsi, scoring lujvo, splitting it back      | 4.5, 4.11-2      |
##   | fuhivla      | fu'ivla as no combination of words, slinku'i test    | 4.7              |
##   | selmaho      | name of each selma'o, as chapter 20 lists them       | ch. 20           |
##   | entries      | entry of each list: word with rafsi, or selma'o      |                  |
##   | dictionary   | words and rafsi of gismu list, selma'o of cmavo      | 4.6, ch. 20      |
##   | tanru        | word read by rules alone, as parts of its tanru      | 4.2-8, 4.11-2    |
##   | tanru_units  | cmavo binding each tanru unit, conversions composed  | ch. 5, 9, 12, 15 |
##   | stream       | text read as its words, with pause and stress        | 3.3, 3.9, 4.9    |
##   | grammar      | words read by formal grammar into tree of its rules  | 21.1             |
##   | prose        | text: quotation, erasure, marks, then grammar        | 19.9-16, 21.1    |
##   | nif          | tree of text as module of NIF data format            | 21.1             |
##   | live         | live text read piece by piece, cut back by cursor    | 19.13, 21.1      |
##   |--------------|------------------------------------------------------|------------------|
##
##   Order of compile-time type bootstrapping:
##     EntryGismu -> LIST_GISMU
##     Selmaho -> EntryCmavo
##     EntryCmavo -> LIST_CMAVO
##     LIST_GISMU -> Word
##     Word -> Part
##     Part -> Tanru
##     [Places, Word] -> Link
##     [Link, Part] -> TanruUnit
##     [Pause, Reading] -> Occurrence
##     Occurrence -> ReadingStream
##     [Selmaho, Reading] -> Terminal
##     Node -> ReadingGrammar
##     [Occurrence, Terminal] -> Unit
##     [Unit, Node] -> ReadingText
##     [Unit, Node] -> ReadingMarked
##     [ReadingMarked, Terminal] -> ReadingParts
##     [Selmaho, Terminal] -> ReaderLive
##   Lists are data that `nim r tools/build.nim lists` renders; `Word` is range over entries of
##     gismu list, so its bound follows list with no number written twice (Article II.5).
##   Lists stay off surface: caller wanting every entry imports `lists/gismu` or `lists/cmavo`
##     itself, and `dictionary` reads one entry of word. Gismu list keeps word and rafsi, and
##     cmavo list word and selma'o, alone; English of each list and whole lujvo list stay with
##     `lojban_tagger`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import ./lojban_parser/[
  clusters, dictionary, entries, forms, fuhivla, grammar, live, lujvo, nif, prose, selmaho,
  stream, tanru, tanru_units,
]

export
  clusters, dictionary, entries, forms, fuhivla, grammar, live, lujvo, nif, prose, selmaho,
  stream, tanru, tanru_units
