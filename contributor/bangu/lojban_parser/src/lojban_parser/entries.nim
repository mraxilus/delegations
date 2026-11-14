## skicu lo liste cmima pe ro valsi liste pe la'o gy. Logical Language Group .gy. ge'u ta'i lo nu le
##   vi se gunka cu ralte le liste .i `lists/gismu.nim` .e `lists/cmavo.nim` cu vasru lo liste cmima
##   .i `tools/lists.nim` cu ciska le liste cmima ra'i `gismu.txt` .e `cmavo.txt` vu'o poi
##   `lojban-common` noi bakfu ne'i la'o gy. Debian .gy. ku'o cu punji ke'a .i ca ro djedi lo minde
##   po'u `nim r tools/build.nim head` cu karbi le liste cmima le re datnyvei
##
##   |----------------|-------------|-------------------------------------------------------------|
##   | lo datni pagbu | lo krasi    | lo stuzi                                                    |
##   |----------------|-------------|-------------------------------------------------------------|
##   | `word`         | `gismu.txt` | `2 .. 6`                                                    |
##   | `rafsi`        | `gismu.txt` | `8 .. 10, 12 .. 14, 16 .. 19` .i lo kunti stuzi cu se vimcu |
##   | `word`         | `cmavo.txt` | `1 .. 11` .i lo lerfu po'u denpa bu cu se vimcu             |
##   | `selmaho`      | `cmavo.txt` | `12 .. 20` .i lo cmene poi lidne lo klesi pe le liste       |
##   |----------------|-------------|-------------------------------------------------------------|
##
##   le vi se gunka cu ralte le liste ta'i lo samtci pe la'o gy. Nim .gy. zi'e poi ponse lo klesi
##     ku'o gi'e na ralte le liste ta'i lo se ciska datnyvei .i ki'u bo ge le jdice samtci cu tcidu
##     no datnyvei pe `.txt` gi lo fanva pe la'o gy. Nim .gy. cu karbi ro datni pagbu lo klesi pe le
##     vi datnyvei .i ku'i la'o gy. JSON .gy. cu cipra no datni pagbu
##   .i lo javni pe la'o gy. CLL .gy. cu nitcu ro datni pagbu poi se ralte ku'o gi'e nitcu no drata
##     datni pagbu .i lo javni cu nitcu lo valsi .e lo rafsi vu'o pe le gismu liste ki'u lo nu
##     `CLL 4.11` .e `CLL 4.12` cu pilno lo rafsi be ro valsi pe lo tanru be'o lo nu jmina gi'e
##     dunda lo namcu .i lo javni cu nitcu ji'a lo valsi .e lo selma'o vu'o pe le cmavo liste ki'u
##     lo nu le gerna pe la'o gy. CLL .gy. cu tcidu le re datni pagbu .i lo glico pagbu be ro liste
##     cu dunda lo smuni gi'e no roi dunda lo ka drani .i se ki'u bo lo glico pagbu cu stali
##     `lojban_tagger` noi sisku sepi'o lo glico pagbu
##     .i jdima fa lo nu lo samtci poi djica pa stuzi poi se vimcu cu galfi le galfi samtci .e le
##       liste ca pa nu ralte
##   .i le cmavo liste cu ralte lo linji poi vasru pa cmavo po'o ku'o gi'e ralte no drata linji .i
##     ki'u bo ge lo linji be lo cmavo gunma cu jmina no datni gi lo jufra pagbu cu vasru su'o re
##     valsi .i ki'u lo nu le genturfa'i cu tcidu lo cmavo pe lo cmavo gunma fi lo cmavo gunma to
##     `CLL 4.2` toi kei lo linji be lo cmavo gunma cu jmina no datni .i lo klesi be lo selma'o be'o
##     poi le liste cu ciska ke'a ba lo cmene be le selma'o ku'o mu'u `1` pe `UI1` cu fendi lo cmavo
##     mu'i lo tadni .i no javni pe la'o gy. CLL .gy. cu tcidu le klesi
##   .i ro liste cmima cu ralte le porsi be lo stuzi be lo rafsi .i le stuzi be `CVC` cu lidne le
##     stuzi be `CCV` .i le stuzi be `CCV` cu lidne le stuzi be `CVV` .i ca lo nu tcidu lo rafsi kei
##     lo lerfu cu rapli jdice lo tarmi be le rafsi to `forms.nim` toi .i se ki'u bo le porsi cu se
##     smuni no da vi
##   .i ro datni pagbu poi ro linji cu vasru ke'a cu se tcita `{.requiresInit.}` to le pagbu poi se
##     cmene zoi gy. Data .gy. ne'i `CONTRIBUTOR.md` toi .i se ki'u bo lo fanva cu to'e curmi ro
##     zbasu be lo liste cmima be'o poi claxu pa le datni pagbu ku'o gi'e jarco le liste cmima .i le
##     datni pagbu cu du lo valsi pe ro liste ge'u jo'u lo selma'o .i va'o lo nu no da cu ciska le
##     selma'o kei le selma'o cu du `Selmaho.A` noi ka'e stali ta'i lo nu smaji .i lo rafsi cu ka'e
##     kunti .i se ki'u bo le rafsi cu na se tcita
##     .i jdima fa lo nu ro `var` pe lo liste cmima cu nitcu lo cfari datni .i jdima ji'a fa lo nu
##       lo fanva cu to'e curmi lo nu `mapIt` cu tcidu lo liste cmima kei ki'u lo nu `mapIt` cu
##       ciska `var it` .i se ki'u bo lo cipra cu tcidu lo datni pagbu sepi'o lo rapli samtci .a
##       `collect` .i lo porsi be lo liste cmima cu rinka lo kajde po'u `UnsafeSetLen` .e
##       `UnsafeDefault` ca lo nu le porsi cu zenba .i `newSeq` pe lo liste cmima cu rinka lo kajde
##       po'u `ProveInit` noi la'o gy. Nim .gy. cu cusku lo du'u ke'a ba binxo lo srera .i se ki'u
##       bo lo cipra cu zbasu sepi'o `newSeqOfCap`

{.experimental: "strictFuncs".}

import ./selmaho


type
  EntryGismu* = object
    ## pa linji pe le gismu liste .i le linji cu vasru pa gismu .a pa cmavo poi ponse lo rafsi
    word* {.requiresInit.}: string
      ## lo valsi .i lo gismu cu vasru mu lerfu .i lo cmavo cu vasru me'i mu lerfu
    rafsi*: seq[string]
      ## lo cmalu rafsi poi le liste cu dunda ke'a le valsi .i ro valsi cu ponse su'e ci rafsi

  EntryCmavo* = object
    ## pa linji poi vasru pa cmavo po'o ne'i le cmavo liste .i le linji no roi vasru lo cmavo gunma
    word* {.requiresInit.}: string
      ## lo cmavo .i lo lerfu po'u denpa bu cu se vimcu to `CLL 3.3` toi
    selmaho* {.requiresInit.}: Selmaho  ## lo selma'o be le cmavo ja'i `CLL 20`
