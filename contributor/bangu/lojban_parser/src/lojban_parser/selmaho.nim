## Name each selma'o of lojban, as catalogue of CLL chapter 20 lists them.
##
##   |-----------------|----------|---------------------------------------------|---------|
##   | Code            | CLL      | Meaning                                     | Chapter |
##   |-----------------|----------|---------------------------------------------|---------|
##   | `Selmaho.A`     | `A`      | logical connective, usually between sumti   | 14      |
##   | `Selmaho.Bahe`  | `BAhE`   | emphasis on next single word                | 19      |
##   | `Selmaho.Koha`  | `KOhA`   | pro-sumti, as `mi`, `do`, `ko'a`            | 7       |
##   | `Selmaho.Se`    | `SE`     | conversion of places of selbri              | 5, 9    |
##   | `Selmaho.Ui`    | `UI`     | attitudinal and discursive                  | 13      |
##   |-----------------|----------|---------------------------------------------|---------|
##
##   Selma'o is grammatical class of cmavo (4.2); chapter 20 names each by representative
##     cmavo, in capitals, with `h` standing for apostrophe. Member is Pascal case of that name
##     (Article V.11), as `Form.Cvc` is of CVC: `h` is never letter of lojban (3.3), so every
##     `h` of member marks apostrophe, and `$` spells name of CLL again, `h` aside in capitals.
##     Suite holds `$` of each member against catalogue, so table above is sample, not whole.
##   Members keep order of catalogue, which is byte order of names, so `BAI` precedes `BAhE`.
##   Cost: 122 members, one for each selma'o of chapter 20; list renders its selma'o by name
##     (`tools/lists.nim`), and name outside catalogue fails converter.

{.experimental: "strictFuncs".}

import std/[enumutils, options, strutils]


type
  Selmaho* {.pure.} = enum  ## Define selma'o: grammatical class of cmavo, as chapter 20 names it.
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
  ## Spell each selma'o as chapter 20 does: every letter in capitals, `h` aside.
  var lut: array[Selmaho, string]
  for selmaho in Selmaho:
    for letter in symbolName(selmaho):
      lut[selmaho].add(if letter == 'h': 'h' else: letter.toUpperAscii)
  lut



#[ Names ]#

func `$`*(selmaho: Selmaho): string = LUT_NAME_BY_SELMAHO[selmaho]
  ## Render selma'o as chapter 20 names it, as `BAhE`.


func toSelmaho*(name: string): Option[Selmaho] =
  ## Read name chapter 20 gives selma'o, as `BAhE`; `none` where catalogue names none so.
  for selmaho in Selmaho:
    if LUT_NAME_BY_SELMAHO[selmaho] == name: return some(selmaho)
  none(Selmaho)
