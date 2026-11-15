## tcidu la lojban. ja'i lo javni pe la'o gy. CLL .gy. po'o
##   .i tcidu lo lerfu .e ro klesi be lo valsi .e lo rafsi .e lo tanru .e lo porsi be lo valsi .e lo
##     se ciska
##   .i le vi datnyvei cu ralju samtci pagbu gi'e rapli benji lo pagbu be ro samtci pagbu be'o poi
##     lo pilno cu ka'e pilno ke'a ku'o ta'i lo porsi be lo nu lo tcidu cu cilre le se casnu
##
##   |---------------|-------------------------------------------------------|------------------|
##   | lo datnyvei   | lo se casnu                                           | lo ckupau        |
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
##   | `entries`     | lo liste cmima be ro liste                            |                  |
##   |               | le liste cmima cu vasru pa valsi                      |                  |
##   |               | le liste cmima cu vasru lo rafsi .a lo selma'o        |                  |
##   | `dictionary`  | lo valsi .e lo rafsi vu'o pe le gismu liste           | `4.6, ch. 20`    |
##   |               | lo selma'o pe le cmavo liste                          |                  |
##   | `tanru`       | lo valsi poi se tcidu ja'i lo javni po'o              | `4.2-8, 4.11-2`  |
##   |               | lo pagbu be lo tanru pe le valsi                      |                  |
##   | `tanru_units` | lo cmavo poi jorne ro tanru pagbu                     | `ch. 5, 9`       |
##   |               | lo nu jmina lo nu galfi lo porsi be fi lo sumti       | `ch. 12, 15`     |
##   | `stream`      | lo se ciska poi se tcidu ta'i lo valsi pe ke'a        | `3.3, 3.9, 4.9`  |
##   |               | lo denpa .e lo nu basna                               |                  |
##   | `grammar`     | lo valsi poi le gerna cu tcidu ke'a                   | `21.1`           |
##   |               | lo tricu pe lo javni pe le gerna                      |                  |
##   | `prose`       | lo nu sitna .e lo nu vimcu .e lo nu tcita lo valsi    | `19.9-16, 21.1`  |
##   |               | lo nu tcidu ja'i le gerna ba lo drata                 |                  |
##   | `nif`         | lo tricu pe lo se ciska                               | `21.1`           |
##   |               | lo samtci pagbu pe `NIF` noi datni tarmi              |                  |
##   | `nif_read`    | lo nu rapli tcidu lo samtci pagbu pe `NIF`            |                  |
##   |               | lo jgena ja'i lo javni pe `NIF`                       |                  |
##   | `live`        | lo nu tcidu ro pagbu be lo jmive se ciska             | `19.13, 21.1`    |
##   |               | lo nu katna lo pu se tcidu bu'u lo stuzi sinxa        |                  |
##   | `merge`       | lo nu jmina lo pagbu ja'i lo se ciska be fi `NIF`     | `19.13-16, 21.1` |
##   |               | lo jalge cu mintu lo se tcidu be le mulno se ciska    |                  |
##   |---------------|-------------------------------------------------------|------------------|
##
## ni'o lo porsi be lo nu zbasu lo klesi ca lo nu fanva cu du di'e
##   .i `EntryGismu` cu lidne `LIST_GISMU`
##   .i `Selmaho` cu lidne `EntryCmavo`
##   .i `EntryCmavo` cu lidne `LIST_CMAVO`
##   .i `LIST_GISMU` cu lidne `Word`
##   .i `Word` cu lidne `Part`
##   .i `Part` cu lidne `Tanru`
##   .i `Places` .e `Word` cu lidne `Link`
##   .i `Link` .e `Part` cu lidne `TanruUnit`
##   .i `Pause` .e `Reading` cu lidne `Occurrence`
##   .i `Occurrence` cu lidne `ReadingStream`
##   .i `Selmaho` .e `Reading` cu lidne `Terminal`
##   .i `Node` cu lidne `ReadingGrammar`
##   .i `Occurrence` .e `Terminal` cu lidne `Unit`
##   .i `Unit` .e `Node` cu lidne `ReadingText`
##   .i `Unit` .e `Node` cu lidne `ReadingMarked`
##   .i `ReadingMarked` .e `Terminal` cu lidne `ReadingParts`
##   .i `Selmaho` .e `Terminal` cu lidne `ReaderLive`
##   .i `NodeNif` .e `Terminal` cu lidne `MergeNif`
##   .i lo liste cu du lo datni poi lo minde po'u `nim r tools/build.nim lists` cu ciska ke'a
##   .i `Word` cu kuspe ro liste cmima pe le gismu liste
##   .i se ki'u bo lo korbi be `Word` cu se krasi le liste
##   .i no namcu cu re roi se ciska to `Article II.5` toi
##   .i le ralju samtci pagbu cu benji no liste
##   .i lo pilno poi djica ro liste cmima cu cpacu `lists/gismu` .a `lists/cmavo`
##   .i `dictionary` cu tcidu pa liste cmima pe pa valsi
##   .i le gismu liste cu ralte lo valsi .e lo rafsi gi'e ralte no drata
##   .i le cmavo liste cu ralte lo valsi .e lo selma'o gi'e ralte no drata
##   .i `lojban_tagger` cu ralte lo glico pagbu be ro liste be'o .e le mulno ke lujvo liste

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
