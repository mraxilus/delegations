## tcidu la lojban. ja'i lo javni pe `CLL` po'o
##   .i tcidu lo lerfu .e ro klesi be lo valsi .e lo rafsi .e lo tanru .e lo porsi be lo valsi .e lo
##       selci'a
##   .i le vi datnyvei cu ralju samtci pagbu gi'e rapybe'i lo pagbu be ro samtci pagbu be'o poi lo
##       pilno cu ka'e pilno ke'a ku'o ta'i lo porsi be lo nu lo tcidu cu cilre le selsnu
##
##   |---------------|-------------------------------------------------------|------------------|
##   | lo datnyvei   | lo selsnu                                           | lo ckupau        |
##   |---------------|-------------------------------------------------------|------------------|
##   | `clusters`    | lo lerfu .e lo zunsna remei .e lo zunsna cimei        | `3.1, 3.6-7`     |
##   |               | lo zunsna remei poi ka'e krasi lo valsi               |                  |
##   | `forms`       | lo tarmi be lo rafsi .e lo gismu .e lo cmavo          | `4.2-4, 4.6`     |
##   |               | lo klesi be lo valsi                                  |                  |
##   |               | lo javni pe lo cmene .e lo fu'ivla ja'i lo lerfu      | `4.7-9`          |
##   |               | lo denpa                                              |                  |
##   | `lujvo`       | lo nu jmina lo rafsi .e lo nu dunda lo namcu lo lujvo | `4.5, 4.11-2`    |
##   |               | lo nu fendi le lujvo fi lo rafsi                      |                  |
##   | `fuhivla`     | lo fu'ivla poi na gunma lo valsi                      | `4.7`            |
##   |               | lo cipra pe zoi gy. slinku'i .gy.                     |                  |
##   | `selmaho`     | lo cmene be ro selma'o ja'i le liste pe `CLL 20`      | `ch. 20`         |
##   | `entries`     | lo stecmi be ro liste                            |                  |
##   |               | le stecmi cu vasru pa valsi                      |                  |
##   |               | le stecmi cu vasru lo rafsi .a lo selma'o        |                  |
##   | `dictionary`  | lo valsi .e lo rafsi vu'o pe le gimste           | `4.6, ch. 20`    |
##   |               | lo selma'o pe le ma'oste                          |                  |
##   | `tanru`       | lo valsi poi se tcidu ja'i lo javni po'o              | `4.2-8, 4.11-2`  |
##   |               | lo pagbu be lo tanru pe le valsi                      |                  |
##   | `tanru_units` | lo cmavo poi jorne ro taurpau                     | `ch. 5, 9`       |
##   |               | lo nu jmina lo nu galfi lo porsi be fi lo sumti       | `ch. 12, 15`     |
##   | `stream`      | lo selci'a poi se tcidu ta'i lo valsi pe ke'a        | `3.3, 3.9, 4.9`  |
##   |               | lo denpa .e lo nu basna                               |                  |
##   | `grammar`     | lo valsi poi le gerna cu tcidu ke'a                   | `21.1`           |
##   |               | lo tricu pe lo javni pe le gerna                      |                  |
##   | `prose`       | lo nu sitna .e lo nu vimcu .e lo nu tcita lo valsi    | `19.9-16, 21.1`  |
##   |               | lo nu tcidu ja'i le gerna ba lo drata                 |                  |
##   | `nif`         | lo tricu pe lo selci'a                               | `21.1`           |
##   |               | lo samtci pagbu pe `NIF` noi datnytai              |                  |
##   | `nif_read`    | lo nu raptcidu lo samtci pagbu pe `NIF`            |                  |
##   |               | lo jgena ja'i lo javni pe `NIF`                       |                  |
##   | `live`        | lo nu tcidu ro pagbu be lo mivyselci'a             | `19.13, 21.1`    |
##   |               | lo nu katna lo pu se tcidu bu'u lo stusni        |                  |
##   | `merge`       | lo nu jmina lo pagbu ja'i lo selci'a be fi `NIF`     | `19.13-16, 21.1` |
##   |               | lo jalge cu mintu lo se tcidu be le mulno se ciska    |                  |
##   |---------------|-------------------------------------------------------|------------------|
##
## ni'o lo porsi be lo nu zbasu lo klesi ca lo nu fanva cu du di'e
##   .i `EntryGismu` lidne `LIST_GISMU`
##   .i `Selmaho` lidne `EntryCmavo`
##   .i `EntryCmavo` lidne `LIST_CMAVO`
##   .i `LIST_GISMU` lidne `Word`
##   .i `Word` lidne `Part`
##   .i `Part` lidne `Tanru`
##   .i `Places` .e `Word` lidne `Link`
##   .i `Link` .e `Part` lidne `TanruUnit`
##   .i `Pause` .e `Reading` lidne `Occurrence`
##   .i `Occurrence` lidne `ReadingStream`
##   .i `Selmaho` .e `Reading` lidne `Terminal`
##   .i `Node` lidne `ReadingGrammar`
##   .i `Occurrence` .e `Terminal` lidne `Unit`
##   .i `Unit` .e `Node` lidne `ReadingText`
##   .i `Unit` .e `Node` lidne `ReadingMarked`
##   .i `ReadingMarked` .e `Terminal` lidne `ReadingParts`
##   .i `Selmaho` .e `Terminal` lidne `ReaderLive`
##   .i `NodeNif` .e `Terminal` lidne `MergeNif`
##   .i lo liste cu du lo datni poi lo minde po'u `nim r tools/build.nim lists` ciska ke'a
##   .i `Word` kuspe ro stecmi pe le gimste
##   .i se ki'u bo lo korbi be `Word` cu selkra le liste
##   .i no namcu cu re roi se ciska to `Article II.5` toi
##   .i le ralju samtci pagbu cu benji no liste
##   .i lo pilno poi djica ro stecmi cu cpacu `lists/gismu` .a `lists/cmavo`
##   .i `dictionary` tcidu pa stecmi pe pa valsi
##   .i le gimste cu ralte lo valsi .e lo rafsi gi'e ralte no drata
##   .i le ma'oste cu ralte lo valsi .e lo selma'o gi'e ralte no drata
##   .i `lojban_tagger` ralte lo glipau be ro liste be'o .e le mulno ke jvoste

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import ./lojban_parser/[
  clusters, dictionary, entries, forms, fuhivla, grammar, live, lujvo, merge, nif, nif_read,
  prose, selmaho, stream, tanru, tanru_units,
]

export
  clusters, dictionary, entries, forms, fuhivla, grammar, live, lujvo, merge, nif, nif_read,
  prose, selmaho, stream, tanru, tanru_units
