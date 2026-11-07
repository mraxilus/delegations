## Tag anything with lojban gismu and lujvo, and find it again by gismu or by English.
##   Umbrella module: re-exports surface of each module, in order reader learns subject.
##
##   |--------------|------------------------------------------------------|-------------|
##   | Module       | Concept                                              | CLL         |
##   |--------------|------------------------------------------------------|-------------|
##   | entries      | English of gismu list, and each line of lujvo list   |             |
##   | tags         | text read as tag, reduced to gismu of its tanru      | 4.5         |
##   | runs         | runs of tanru units that tag holds unchanged         | 5.11, 15.4  |
##   | english      | English leading to gismu, by keywords and glosses    |             |
##   | index        | tagged entities, and file holding them               |             |
##   | search       | terms read as lojban or English, and entities found  |             |
##   | commands     | verbs of `tagger`, as pure functions                 |             |
##   | suggestions  | gismu model suggests for passage, checked by lists   |             |
##   |--------------|------------------------------------------------------|-------------|
##
##   Lojban is read through `lojban_parser`: letters, forms, rafsi, words of gismu list, and fold
##     of tanru into tanru units stand there, by rules of CLL alone. This project holds policy of
##     tag, English of gismu list, and whole lujvo list, as Architect ruled.
##     Surface of parser stays off this surface, so each module needing it imports parser itself.
##     Cost: caller needing `Word` or its rendering imports both umbrellas.
##   Order of compile-time type bootstrapping:
##     [EntryGismuEnglish, EntryLujvo] -> [LIST_GISMU, LIST_LUJVO]
##     Word -> Tag
##     [LIST_GISMU, LIST_LUJVO, Tag, Word] -> MEANINGS
##     Tag -> [Entity, Term]
##     [LIST_GISMU, COUNT_TAGS_MAX] -> PROMPT_SYSTEM
##   Lists are data that `nim r tools/build.nim lists` renders; `Word` is index into gismu list of
##     `lojban_parser`, and English here follows that list entry for entry (`english.nim`).
##   `Reference`, `toReference` and its `toText` stay off surface: `suggestions` exports them for
##     `app/exchanges.nim` alone, which imports that module itself (Article I.6).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import ./lojban_tagger/[commands, english, entries, index, runs, search, suggestions, tags]

export commands, english, entries, index, runs, search, tags
export suggestions except Reference, toReference, toText
