## cipra lo du'u `prose.nim` cu tcidu ro mupli poi se namcu ne'i `CLL 1.1` .i ro mupli poi le cukta
##   cu cusku lo du'u ke'a drani cu se tcidu .i ro mupli poi le cukta cu cusku lo du'u ke'a na drani
##   ku'o .e ro mupli poi na'e mapti su'o javni pe `CLL 21.1` cu se to'e curmi
##   .i le se ciska girzu cu du `tests/cll/examples.nim` .i le minde po'u
##     `nim r tools/build.nim cll` cu ciska le datnyvei ra'i le papri be le cukta .i le datnyvei cu
##     se javni le notci pe la'o gy. CLL .gy. zi'e noi zvati `tests/cll/NOTICE.md` to lo se jdice
##     po'u `D1 a` bu'u `#815` toi .i le datnyvei cu no roi se zbasu fi lo se jarco be le genturfa'i
##   .i lo mupli cu se tcidu va'o lo nu lo linji pe le mupli cu se jorne gi'e se tcidu kei .a lo nu
##     ro linji pe le mupli cu sepli se tcidu .i ki'u bo lo linji pe lo lijgri liste cu pagbu pa
##     jufra .a so'i jufra .i lo tcita pe le cukta na cusku lo du'u xu kau le linji cu pagbu pa
##     jufra
##   .i lo kurfa grile'u cu sinxa lo valsi poi lo se ciska cu ka'e claxu ke'a to `CLL 5.5` toi .i se
##     ki'u bo ro se ciska cu se tcidu ta'i lo nu vasru lo valsi poi lo grile'u cu sinxa ke'a kei .e
##     lo nu claxu le valsi
##   .i lo linji poi vasru lo sinxa pe le cukta zi'e poi na lojbo cu na se tcidu .i le sinxa cu du
##     lo namcu lerfu pe lo cmene be lo sumti stuzi be'o to `CLL 2.5` toi ge'u .a ci denpa bu .a lo
##     cukla grile'u .a zoi gy. : .gy. poi se lidne lo cmene be lo cusku ku'o .a zoi gy. - .gy. .i
##     va'o lo nu ro linji pe pa mupli cu vasru lo sinxa poi na lojbo kei no linji pe le mupli cu se
##     tcidu
##   .i lo mupli poi ciska pa mekso po'o ta'i lo nu `CLL 18.10` .e `CLL 18.14` .e `CLL 18.15` cu
##     ciska lo mekso pagbu ku'o cu se tcidu ba zo li
##   .i le genturfa'i cu to'e curmi ro mupli poi na'e mapti su'o javni pe `CLL 21.1` ja'i lo se
##     jdice po'u `D2 a` bu'u `#815` .i le javni cu jinga le mupli .i ro le mupli cu se tcidu ba lo
##     nu se cikre ja'i le javni poi lamji le mupli .i le cipra cu cipra le se cikre
##   .i le se ciska girzu ca na vasru lo linji pe `CLL 3` zi'e poi skicu lo nu bacru ku'o .e lo
##     linji pe `CLL 4` zi'e poi skicu lo se ciska valsi poi vasru so'i cmavo .i `test_stream.nim`
##     .e `test_forms.nim` cu vasru le linji poi se ciska ta'i lo nu na'e zmiku .i le se ciska girzu
##     ca na vasru ji'a lo tricu .i `test_grammar.nim` cu cipra lo tricu pe `CLL 5` .e `CLL 18.16`
##   .i jdima fa lo nu le cipra cu pilno lo temci poi jibni `4 s` ne'i lo se zbasu pe la'o gy. debug
##     .gy. .i le temci cu se merli de'i `2026-11-09` ne'i le skami pe le gunka .i le gerna cu pilno
##     so'a le temci .i lo nu tcidu lo porsi be lo valsi cu pilno `0.1 s`

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, strutils, unittest]

import ../../src/lojban_parser/prose
import ../cll/examples


const
  NUMBERS_WRONG = [
    # zoi gy. reserved for experimental purposes .gy. .i claxu lo selma'o
    ("4.4", RefusalText.Selmaho),  # `CLL 4.2`
    ("4.77", RefusalText.Stream),  # `CLL 4.16` .i zoi gy. illegal word in standard Lojban .gy.
    ("16.79", RefusalText.Stream),  # `CLL 16.11` .i lo glico jufra poi se tcita lo ka lojbo
    # zoi gy. ungrammatical as written .gy. .i `gy` cu zvati ne'i le se ciska
    ("19.50", RefusalText.Stream),  # `CLL 19.10`
  ]
    ## lo mupli poi le cukta cu cusku lo du'u ke'a na drani ku'o .a lo mupli poi glico jufra .i ro
    ##   mupli cu se kansa le nu to'e curmi pe vo'a
  EXAMPLES_BROKEN = [
    # le javni pe li pano .i `.i` basti `.ije`
    ("14.27", "la djan. .i la .alis. klama le zarci"),  # `CLL 14.6`
    # le javni pe li bipa .i `pe'e` cu lidne lo me `joik` me'u .a lo me `jek` me'u .i se ki'u bo
    #   `je` cu basti `.e` noi me `ek` me'u
    (
      "14.123",
      "la djeimyz. ce'e la meris. pe'e je la djordj. ce'e la martas. prami",
    ),  # `CLL 14.14`
    (
      "14.131",
      "nu'i mi ce'e bau la lojban. pe'e joi do ce'e bau la gliban. nu'u casnu",
    ),  # `CLL 14.15` .i le javni pe li bimu .i `nu'u` cu fanmo lo me `termset` me'u ba `nu'i` po'o
    # le javni pe li bimu .i lo me `termset` me'u cu jorne no pagbu sepi'o `fa'u` poi se lidne
    #   `nu'u` .i `pe'e fa'u` cu jorne
    (
      "14.133",
      "la djan. fa'u la frank. cusku nu'i bau la lojban. pe'e fa'u bai tu'a la djordj. nu'u",
    ),  # `CLL 14.15`
    # le javni pe li cizepa .i `gu'e` basti `ge`
    ("14.152", "li re gu'e su'i gi pi'i re du li vo"),  # `CLL 14.17`
    # le javni pe li soze .i zo xi poi se lidne lo lerpoi cu nitcu zo boi
    ("17.38", "xy. boi xi ky."),  # `CLL 17.11`
    # le javni pe li cizepa .i mintu `CLL 14.152`
    ("18.118", "li re gu'e su'i gi pi'i re du li vo"),  # `CLL 18.17`
    # le javni pe li binoxa .i la'o gy. GAhO .gy. re roi
    ("18.122", "li pimu su'i ni'upimu ke'i bi'o ke'i ma'upimu"),  # `CLL 18.17`
    # le javni pe li soze .i mintu `CLL 17.38`
    ("18.123", "xy. boi xi vei by. ce'o dy. ve'o"),  # `CLL 18.17`
  ]
    ## lo mupli poi na'e mapti su'o javni pe `CLL 21.1` .i le gerna cu to'e curmi le mupli to `D2 a`
    ##   toi .i ro mupli cu se kansa le se ciska pe vo'a zi'e noi se cikre ja'i le javni poi lamji
    ##   le mupli .i ro se cikre cu se finti
  NUMBERS_MEX = ["18.77", "18.78", "18.105", "18.106", "18.108", "18.109"]
    ## lo mupli poi ciska pa mekso po'o ta'i lo mekso pagbu to `CLL 18.10` .e `CLL 18.14` .e
    ##   `CLL 18.15` toi
  COUNT_READ = 1592
    ## lo te kancu be lo mupli poi vasru lo linji poi claxu lo sinxa poi na lojbo .i ro le mupli cu
    ##   se tcidu
  COUNT_NOTATION = 10
    ## lo te kancu be lo mupli poi ro linji pe ke'a cu vasru lo sinxa poi na lojbo .i le mupli cu du
    ##   `CLL 2.10` jo'u `CLL 4.46-51` jo'u `CLL 7.39` jo'u `CLL 12.33-34`
  COUNT_ROWS_NOTATION = 33
    ## lo te kancu be lo linji poi vasru lo sinxa poi na lojbo ku'o gi'e na se tcidu



#[ lo tcidu ]#

func rows(number: string): seq[string] =
  ## dunda lo linji pe le mupli poi se namcu `number`
  for example in EXAMPLES_CLL:
    if example.number == number: return example.rows
  doAssert false, "Example should be in corpus; got `" & number & "`."


func isNotation(row: string): bool =
  ## jdice lo du'u xu kau le linji cu vasru lo sinxa pe le cukta zi'e poi no lojbo se ciska cu vasru
  ##   ke'a
  row.anyIt(it in {'0'..'9', '(', ')', ':', '-'}) or "…" in row


func variants(text: string): seq[string] =
  ## ciska le se ciska re roi .i le pamoi cu vasru lo valsi poi lo kurfa grile'u cu sinxa ke'a .i le
  ##   remoi cu claxu le valsi .i va'o lo nu no valsi cu se sinxa kei ciska le se ciska pa roi
  if '[' notin text: return @[text]
  var
    without: string
    depth = 0
  for letter in text:
    if letter == '[': inc depth
    elif letter == ']': dec depth
    elif depth == 0: without.add letter
  @[text.multiReplace(("[", ""), ("]", "")), without]


func isRead(text: string): bool =
  ## jdice lo du'u xu kau `readText` cu tcidu le se ciska ta'i lo nu vasru lo valsi poi lo kurfa
  ##   grile'u cu sinxa ke'a kei .e lo nu claxu le valsi
  text.variants.allIt(it.readText.is_read)


func isReadRows(rows: openArray[string]): bool =
  ## jdice lo du'u xu kau le linji cu se tcidu ta'i lo nu se jorne kei .a lo nu ro linji cu sepli se
  ##   tcidu
  rows.join(" ").isRead or (rows.len > 1 and rows.allIt(it.isRead))


func refusals(number: string): seq[RefusalText] =
  ## dunda lo nu to'e curmi pe ro tarmi be lo se jorne linji pe le mupli .i va'o lo nu pa tarmi cu
  ##   se tcidu kei le jalge cu kunti
  for text in number.rows.join(" ").variants:
    let reading = text.readText
    if reading.is_read: return @[]
    result.add reading.refusal



suite "Chapters 1-19":
  test "Each example reads, joined or row by row, with words square brackets mark and without":
    var
      unread: seq[string]
      count_read, count_notation, count_rows_notation = 0
    let left = NUMBERS_WRONG.mapIt(it[0]) & EXAMPLES_BROKEN.mapIt(it[0]) & @NUMBERS_MEX
    for example in EXAMPLES_CLL:
      if example.number in left: continue
      let rows = example.rows.filterIt(not it.isNotation)
      count_rows_notation += example.rows.len - rows.len
      if rows.len == 0:
        inc count_notation
        continue
      if rows.isReadRows: inc count_read
      else: unread.add example.number
    check unread == newSeq[string]()  # `CLL 21.1` .i ro mupli poi drani ja'i le cukta
    # le bandu cu ralte ro mupli poi vasru lo sampu linji
    check count_read == COUNT_READ  # `Article IX.3`
    # le bandu cu cipra lo du'u lo mupli po'o poi ro linji pe ke'a cu vasru lo sinxa poi na lojbo cu
    #   na'e se tcidu
    check count_notation == COUNT_NOTATION  # `Article IX.3`
    # le bandu cu cipra lo du'u le linji po'o poi le bandu cu cmene ke'a cu na'e se tcidu
    check count_rows_notation == COUNT_ROWS_NOTATION  # `Article IX.3`


  test "Each example of mex alone reads after li":
    for number in NUMBERS_MEX:
      checkpoint "Example " & number
      # lo mekso pe zo li
      check ("li " & number.rows.join(" ")).isRead  # `CLL 18.10` .e `CLL 18.14` .e `CLL 18.15`
      # lo mekso poi na se lidne zo li cu na du lo se ciska
      check not number.rows.isReadRows  # `CLL 21.1` `text`


  test "Each example book calls wrong, or writes in English, is refused":
    for (number, refusal) in NUMBERS_WRONG:
      checkpoint "Example " & number
      # ro namcu cu lamji lo sitna be la'o gy. CLL .gy.
      check number.refusals.len > 0  # `NUMBERS_WRONG`
      # ro namcu cu lamji lo nu to'e curmi
      check number.refusals.allIt(it == refusal)  # `NUMBERS_WRONG`
      check not number.rows.isReadRows  # `NUMBERS_WRONG` .i ro linji cu sepli se to'e curmi ji'a


  test "Each example breaking rule of 21.1 is refused by grammar, and reads once repaired":
    for (number, repair) in EXAMPLES_BROKEN:
      checkpoint "Example " & number
      check number.refusals.len > 0  # `EXAMPLES_BROKEN` .i ro namcu cu lamji lo javni
      check number.refusals.allIt(it == RefusalText.Grammar)  # `EXAMPLES_BROKEN` `D2 a`
      check not number.rows.isReadRows  # `EXAMPLES_BROKEN` .i ro linji cu sepli se to'e curmi ji'a
      check repair.isRead  # `EXAMPLES_BROKEN` .i le se ciska cu se cikre ja'i le javni .i se finti
