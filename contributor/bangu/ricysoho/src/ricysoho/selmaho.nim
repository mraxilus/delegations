## cusku lo cmene be ro selma'o pe la lojban. ta'i lo nu le liste pe `CLL 20` liste le selma'o
##
##   |-----------------|--------|--------------------------------------------------|------------|
##   | lo samtci cmene | `CLL`  | lo smuni                                         | lo ckupau  |
##   |-----------------|--------|--------------------------------------------------|------------|
##   | `Selmaho.A`     | `A`    | lo lojyjo'e poi so'e roi jorne lo sumti       | `CLL 14`   |
##   | `Selmaho.Bahe`  | `BAhE` | lo nu basna pa bavla'i valsi                     | `CLL 19`   |
##   | `Selmaho.Koha`  | `KOhA` | lo sumyma'o mu'u zo mi .e zo do .e zo ko'a    | `CLL 7`    |
##   | `Selmaho.Se`    | `SE`   | lo nu galfi lo porsi be lo sumti pe lo selbri    | `CLL 5, 9` |
##   | `Selmaho.Ui`    | `UI`   | lo cnivla .e lo valsi poi skicu lo nu tavla | `CLL 13`   |
##   |-----------------|--------|--------------------------------------------------|------------|
##
## ni'o lo selma'o cu genlei lo cmavo to `CLL 4.2` toi
##   .i `CLL 20` dunda lo cmene ro selma'o sepi'o pa cmavo poi sinxa le selma'o ku'o ta'i lo brale'u
##   .i `h` sinxa zoi gy. ' .gy. ne'i le cmene
##
## ni'o ro cmima be `Selmaho` cu ciska le cmene ta'i `Pascal case` to `Article V.11` toi
##   .i `Form.Cvc` ciska `CVC` ta'i `Pascal case` ji'a
##   .i `h` no roi lerfu la lojban. to `CLL 3.3` toi
##   .i se ki'u bo ro `h` pe ro cmima cu sinxa zoi gy. ' .gy.
##   .i `$` rapci'a lo cmene pe `CLL` ta'i lo brale'u
##   .i `h` po'o cmalu
##
## ni'o lo cipra cu cipra lo du'u `$` ciska ro cmima ta'i le liste pe `CLL 20`
##   .i se ki'u bo le liste poi gapru cu mupli gi'e na mulno
##   .i le cmima cu ralte lo porsi pe le liste pe `CLL 20`
##   .i le porsi cu du lo porsi be le cmene bei fi lo stuzi
##   .i se ki'u bo `BAI` lidne `BAhE`
##
## ni'o jdima fa lo nu `Selmaho` vasru 122 cmima
##   .i ro selma'o pe `CLL 20` selra'a pa cmima
##   .i le liste cu ciska lo selma'o be ro cmavo ta'i lo cmene to `tools/lists.nim` toi
##   .i lo cmene poi na zvati le liste pe `CLL 20` rinka lo nu le galfi samtci cu fliba

{.experimental: "strictFuncs".}

import std/[enumutils, options, strutils]


type
  Selmaho* {.pure.} = enum  ## lo selma'o noi genlei lo cmavo gi'e selcme fi `CLL 20`
    A,
    Bai, Bahe, Be, Bei, Beho, Bihe, Bihi, Bo, Boi, Bu, By,
    Cai, Caha, Cei, Cehe, Co, Coi, Cu, Cuhe,
    Daho, Doi, Dohu,
    Fa, Faha, Faho, Fehe, Fehu, Fiho, Foi, Fuha, Fuhe, Fuho,
    Ga, Gaho, Gehu, Gi, Giha, Goi, Goha, Guha,
    I,
    Ja, Jai, Joi, Johi,
    Ke, Kei, Kehe, Ki, Koha, Ku, Kuhe, Kuho,
    La, Lau, Lahe, Le, Lehu, Li, Lihu, Loho, Lohu, Lu, Luhu,
    Mai, Maho, Me, Mehu, Moi, Mohe, Mohi,
    Na, Nai, Nahe, Nahu, Nihe, Niho, Noi, Nu, Nuha, Nuhi, Nuhu,
    Pa, Pehe, Peho, Pu,
    Raho, Roi,
    Sa, Se, Sei, Sehu, Si, Soi, Su,
    Tahe, Tei, Tehu, To, Toi, Tuhe, Tuhu,
    Ui,
    Va, Vau, Vei, Veha, Veho, Viha, Vuho, Vuhu,
    Xi,
    Y,
    Zaho, Zei, Zeha, Zi, Zihe, Zo, Zoi, Zohu,


const LUT_NAME_BY_SELMAHO = block:
  ## ciska ro selma'o ta'i lo nu `CLL 20` ciska
  ##   .i ro lerfu poi na du `h` barda
  var lut: array[Selmaho, string]
  for selmaho in Selmaho:
    for letter in symbolName(selmaho):
      lut[selmaho].add(if letter == 'h': 'h' else: letter.toUpperAscii)
  lut



#[ ni'o ni'o ni'o lo cmene ]#

func `$`*(selmaho: Selmaho): string = LUT_NAME_BY_SELMAHO[selmaho]
  ## ciska lo selma'o ta'i lo cmene pe `CLL 20` mu'u `BAhE`


func toSelmaho*(name: string): Option[Selmaho] =
  ## tcidu lo cmene poi `CLL 20` dunda ke'a lo selma'o mu'u `BAhE`
  ##   .i dunda `none` va'o lo nu le liste pe `CLL 20` dunda le cmene no selma'o
  for selmaho in Selmaho:
    if LUT_NAME_BY_SELMAHO[selmaho] == name: return some(selmaho)
  none(Selmaho)
