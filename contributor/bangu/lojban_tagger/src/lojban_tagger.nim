## Tag anything with Lojban gismu and lujvo, and find it again by gismu or by English.
##   Umbrella module: re-exports surface of each module, in order reader learns subject.
##
##   |--------------|------------------------------------------------------|-------------|
##   | Module       | Concept                                              | CLL         |
##   |--------------|------------------------------------------------------|-------------|
##   | clusters     | letters, consonant pairs, initial pairs, triples     | 3.1, 3.6-7  |
##   | forms        | shapes of rafsi and gismu, properties of brivla      | 4.3-4, 4.6  |
##   | lujvo        | joining rafsi, scoring lujvo, splitting it back      | 4.5, 4.11-2 |
##   | entries      | entry of each word list                              |             |
##   | dictionary   | words and rafsi of committed gismu list              | 4.6         |
##   | tags         | text read as tag, reduced to gismu of its tanru      | 4.5         |
##   | english      | English leading to gismu, by keywords and glosses    |             |
##   | index        | tagged entities, and file holding them               |             |
##   | search       | terms read as Lojban or English, and entities found  |             |
##   | commands     | verbs of `tagger`, as pure functions                 |             |
##   | suggestions  | gismu model suggests for passage, checked by lists   |             |
##   |--------------|------------------------------------------------------|-------------|
##
##   Order of compile-time type bootstrapping:
##     [EntryGismu, EntryLujvo] -> [LIST_GISMU, LIST_LUJVO]
##     LIST_GISMU -> Word
##     Word -> Tag
##     [LIST_GISMU, LIST_LUJVO, Tag] -> MEANINGS
##     Tag -> [Entity, Term]
##     [LIST_GISMU, COUNT_TAGS_MAX] -> PROMPT_SYSTEM
##   Lists are data that `nim r tools/build.nim lists` renders; `Word` is range over entries of
##     gismu list, so its bound follows list with no number written twice (Article II.5).
##   `Reference`, `toReference` and its `toText` stay off surface: `suggestions` exports them for
##     `app/exchanges.nim` alone, which imports that module itself (Article I.6).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import ./lojban_tagger/[
  clusters, commands, dictionary, english, entries, forms, index, lujvo, search, suggestions,
  tags,
]

export clusters, commands, dictionary, english, entries, forms, index, lujvo, search, tags
export suggestions except Reference, toReference, toText
