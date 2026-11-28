## skicu lo stecmi pe ro vlaste pe `Logical Language Group` ge'u ta'i lo nu le vi selgu'a cu ralte
##     le liste
##   .i `lists/gismu.nim` .e `lists/cmavo.nim` vasru lo stecmi
##   .i `tools/lists.nim` ciska le stecmi ra'i `gismu.txt` .e `cmavo.txt` vu'o poi `lojban-common`
##       noi bakfu ne'i `Debian` punji ke'a
##   .i ca ro djedi lo minde po'u `nim r tools/build.nim head` karbi le stecmi le re datnyvei
##
##   |----------------|-------------|-------------------------------------------------------------|
##   | lo datnypau | lo krasi    | lo stuzi                                                    |
##   |----------------|-------------|-------------------------------------------------------------|
##   | `word`         | `gismu.txt` | `2 .. 6`                                                    |
##   | `rafsi`        | `gismu.txt` | `8 .. 10, 12 .. 14, 16 .. 19`                               |
##   |                |             | .i lo kutstu cu selvi'u                               |
##   | `word`         | `cmavo.txt` | `1 .. 11`                                                   |
##   |                |             | .i lo lerfu po'u denpa bu cu selvi'u                       |
##   | `selmaho`      | `cmavo.txt` | `12 .. 20`                                                  |
##   |                |             | .i lo cmene poi lidne lo klesi pe le liste                  |
##   |----------------|-------------|-------------------------------------------------------------|
##
## ni'o le vi selgu'a cu ralte le liste ta'i lo samtci pe `Nim` zi'e poi ponse lo klesi ku'o .enai
##     lo se ciska datnyvei
##   .i ki'u bo ge le jdice samtci cu tcidu no datnyvei pe `.txt` gi lo fanva pe `Nim` karbi ro
##       datnypau lo klesi pe le vi datnyvei
##   .i ku'i `JSON` cipra no datnypau
##
## ni'o lo javni pe `CLL` nitcu ro datnypau poi selra'e ku'o .e no datydatnypau
##   .i lo javni cu nitcu lo valsi .e lo rafsi vu'o pe le gimste ki'u lo nu `CLL 4.11` .e `CLL 4.12`
##       pilno lo rafsi be ro valsi pe lo tanru be'o lo nu jmina gi'e dunda lo namcu
##   .i lo javni cu nitcu lo valsi .e lo selma'o vu'o pe le ma'oste ki'u lo nu le gerna pe `CLL`
##       tcidu le re datnypau
##   .i lo glipau be ro liste cu dunda lo smuni gi'e no roi dunda lo ka drani
##   .i se ki'u bo le vi selgu'a cu ralte no glipau
##   .i jdima fa lo nu lo samtci poi djica pa stuzi poi selvi'u cu galfi le galfi samtci .e le liste
##       ca pa nu ralte
##
## ni'o le ma'oste cu ralte lo linji poi vasru pa cmavo po'o ku'o .e no datli'i
##   .i ki'u bo ge ki'u lo nu le genturfa'i cu tcidu lo cmavo pe lo ma'orgunma fi lo cmavo gunma to
##       `CLL 4.2` toi kei lo linji be lo ma'orgunma cu jmina no datni gi lo jufpau cu vasru su'o re
##       valsi
##   .i lo klesi be lo selma'o be'o poi le liste cu ciska ke'a ba lo cmene be le selma'o ku'o mu'u
##       `1` pe `UI1` fendi lo cmavo mu'i lo tadni
##   .i no javni pe `CLL` tcidu le klesi
##
## ni'o ro stecmi cu ralte le porsi be lo stuzi be lo rafsi
##   .i le stuzi be `CVC` cu lidne le stuzi be `CCV` be'o noi lidne le stuzi be `CVV`
##   .i ca lo nu tcidu lo rafsi kei lo lerfu cu rapyjdi lo tarmi be le rafsi to `forms.nim` toi
##   .i se ki'u bo le porsi cu selsmu no da vi
##
## ni'o ro datnypau poi ro linji cu vasru ke'a se tcita `{.requiresInit.}` to le pagbu poi selcme
##     zoi gy. Data .gy. ne'i `CONTRIBUTOR.md` toi
##   .i se ki'u bo lo fanva cu to'e curmi ro zbasu be lo stecmi be'o poi claxu pa le datnypau ku'o
##       gi'e jarco le stecmi
##   .i le datnypau cu du lo valsi pe ro liste ge'u jo'u lo selma'o
##   .i va'o lo nu no da ciska le selma'o kei le selma'o cu du `Selmaho.A` noi ka'e stali ta'i lo nu
##       smaji
##   .i lo rafsi cu ka'e kunti
##   .i se ki'u bo le rafsi cu na se tcita
##
## ni'o jdima fa lo nu ro `var` pe lo stecmi cu nitcu lo cfadatni
##   .i jdima fa lo nu lo fanva cu to'e curmi lo nu `mapIt` tcidu lo stecmi kei ki'u lo nu `mapIt`
##       ciska `var it`
##   .i se ki'u bo lo cipra cu tcidu lo datnypau sepi'o lo rapli samtci .a `collect`
##
## ni'o lo porsi be lo stecmi cu rinka lo kajde po'u `UnsafeSetLen` .e `UnsafeDefault` ca lo nu le
##     porsi cu zenba
##   .i `newSeq` pe lo stecmi cu rinka lo kajde po'u `ProveInit` noi `Nim` cusku lo du'u ke'a ba
##       binxo lo srera
##   .i se ki'u bo lo cipra cu zbasu sepi'o `newSeqOfCap`

{.experimental: "strictFuncs".}

import ./selmaho


type  # lo klesi pe lo linji pe le liste
  EntryGismu* = object
    ## pa linji pe le gimste
    ##   .i le linji cu vasru pa gismu .a pa cmavo poi ponse lo rafsi
    word* {.requiresInit.}: string
      ## lo valsi
      ##   .i lo gismu cu vasru mu lerfu
      ##   .i lo cmavo cu vasru me'i mu lerfu
    rafsi*: seq[string]
      ## lo cmarafsi poi le liste cu dunda ke'a le valsi
      ##   .i ro valsi cu ponse su'e ci rafsi

  EntryCmavo* = object
    ## pa linji poi vasru pa cmavo po'o ne'i le ma'oste
    ##   .i le linji no roi vasru lo ma'orgunma
    word* {.requiresInit.}: string
      ## lo cmavo
      ##   .i lo lerfu po'u denpa bu cu se vimcu to `CLL 3.3` toi
    selmaho* {.requiresInit.}: Selmaho  ## lo selma'o be le cmavo ja'i `CLL 20`
