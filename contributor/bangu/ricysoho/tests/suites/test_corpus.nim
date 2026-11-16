## cipra lo du'u `prose.nim` tcidu ro mupli poi selna'u ne'i `CLL 1.1`
##   .i ro mupli poi le cukta cu cusku lo du'u ke'a drani cu se tcidu
##   .i ro mupli poi le cukta cu cusku lo du'u ke'a na drani ku'o .e ro mupli poi na'e mapti su'o
##       javni pe `CLL 21.1` se to'e curmi
##
## ni'o le selci'agri cu du `tests/cll/examples.nim`
##   .i le minde po'u `nim r tools/build.nim cll` ciska le datnyvei ra'i le papri be le cukta
##   .i le datnyvei cu seljva le notci pe `CLL` zi'e noi zvati `tests/cll/NOTICE.md` to lo seljdi
##       po'u `D1 a` bu'u `#815` toi
##   .i le datnyvei cu no roi selzba fi lo selja'o be le genturfa'i
##
## ni'o lo mupli cu se tcidu va'o lo nu lo linji pe le mupli cu seljo'e gi'e se tcidu kei .a lo nu
##     ro linji pe le mupli cu sepseltcidu
##   .i ki'u bo lo linji pe lo lijgri liste cu pagbu pa jufra .a so'i jufra
##   .i lo tcita pe le cukta na cusku lo du'u xu kau le linji cu pagbu pa jufra
##
## ni'o lo kurfa grile'u cu sinxa lo valsi poi lo selci'a cu ka'e claxu ke'a to `CLL 5.5` toi
##   .i se ki'u bo ro selci'a cu se tcidu ta'i lo nu vasru lo valsi poi lo grile'u cu sinxa ke'a kei
##       .e lo nu claxu le valsi
##
## ni'o lo linji poi vasru lo sinxa pe le cukta zi'e poi na lojbo cu na se tcidu
##   .i le sinxa cu du lo nacle'u pe lo cmene be lo sumstu be'o to `CLL 2.5` toi ge'u .a ci denpa bu
##       .a lo cukla grile'u .a zoi gy. : .gy. poi se lidne lo cmene be lo cusku ku'o .a zoi gy. -
##       .gy.
##   .i va'o lo nu ro linji pe pa mupli cu vasru lo sinxa poi na lojbo kei no linji pe le mupli cu
##       se tcidu
##
## ni'o lo mupli poi ciska pa mekso po'o ta'i lo nu `CLL 18.10` .e `CLL 18.14` .e `CLL 18.15` ciska
##     lo mekpau cu se tcidu ba zo li
##
## ni'o le genturfa'i cu to'e curmi ro mupli poi na'e mapti su'o javni pe `CLL 21.1` ja'i lo seljdi
##     po'u `D2 a` bu'u `#815`
##   .i le javni cu jinga le mupli
##   .i ro le mupli cu se tcidu ba lo nu se cikre ja'i le javni poi lamji le mupli
##   .i le cipra cu cipra le se cikre
##
## ni'o le selci'agri ca na vasru lo linji pe `CLL 3` zi'e poi skicu lo nu bacru ku'o .e lo linji pe
##     `CLL 4` zi'e poi skicu lo selci'avla poi vasru so'i cmavo
##   .i `test_stream.nim` .e `test_forms.nim` vasru le linji poi selci'a ta'i lo nu na'e zmiku
##   .i le selci'agri ca na vasru lo tricu
##   .i `test_grammar.nim` cipra lo tricu pe `CLL 5` .e `CLL 18.16`
##
## ni'o jdima fa lo nu le cipra cu pilno lo temci poi jibni `4 s` ne'i lo selzba pe `debug`
##   .i le temci cu selmre de'i `2026-11-09` ne'i le skami pe le gunka
##   .i le gerna cu pilno so'a le temci
##   .i lo nu tcidu lo porsi be lo valsi cu pilno `0.1 s`

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, strutils, unittest]

import ../../src/lojban_parser/prose
import ../cll/examples


const
  NUMBERS_WRONG = [
    # zoi gy. reserved for experimental purposes .gy.
    #   .i claxu lo selma'o
    ("4.4", RefusalText.Selmaho),  # `CLL 4.2`
    ("4.77", RefusalText.Stream),  # `CLL 4.16` to zoi gy. illegal word in standard Lojban .gy. toi
    ("16.79", RefusalText.Stream),  # `CLL 16.11` to lo gliju'a poi se tcita lo ka lojbo toi
    # zoi gy. ungrammatical as written .gy.
    #   .i `gy` zvati ne'i le selci'a
    ("19.50", RefusalText.Stream),  # `CLL 19.10`
  ]
    ## lo mupli poi le cukta cu cusku lo du'u ke'a na drani ku'o .a lo mupli poi gliju'a
    ##   .i ro mupli cu se kansa le nu to'e curmi pe vo'a
  EXAMPLES_BROKEN = [
    # le javni pe li pano
    #   .i `.i` basti `.ije`
    ("14.27", "la djan. .i la .alis. klama le zarci"),  # `CLL 14.6`
    # le javni pe li bipa
    #   .i `pe'e` lidne lo me `joik` me'u .a lo me `jek`
    #   .i se ki'u bo `je` basti `.e` noi me `ek`
    (
      "14.123",
      "la djeimyz. ce'e la meris. pe'e je la djordj. ce'e la martas. prami",
    ),  # `CLL 14.14`
    (
      "14.131",
      "nu'i mi ce'e bau la lojban. pe'e joi do ce'e bau la gliban. nu'u casnu",
    # le javni pe li bimu
    #   .i `nu'u` fanmo lo me `termset` me'u ba `nu'i` po'o
    ),  # `CLL 14.15`
    # le javni pe li bimu
    #   .i lo me `termset` cu jorne no pagbu sepi'o `fa'u` poi se lidne `nu'u`
    #   .i `pe'e fa'u` jorne
    (
      "14.133",
      "la djan. fa'u la frank. cusku nu'i bau la lojban. pe'e fa'u bai tu'a la djordj. nu'u",
    ),  # `CLL 14.15`
    # le javni pe li cizepa
    #   .i `gu'e` basti `ge`
    ("14.152", "li re gu'e su'i gi pi'i re du li vo"),  # `CLL 14.17`
    # le javni pe li soze
    #   .i zo xi poi se lidne lo lerpoi cu nitcu zo boi
    ("17.38", "xy. boi xi ky."),  # `CLL 17.11`
    # le javni pe li cizepa
    #   .i mintu `CLL 14.152`
    ("18.118", "li re gu'e su'i gi pi'i re du li vo"),  # `CLL 18.17`
    # le javni pe li binoxa
    #   .i `GAhO` re roi
    ("18.122", "li pimu su'i ni'upimu ke'i bi'o ke'i ma'upimu"),  # `CLL 18.17`
    # le javni pe li soze
    #   .i mintu `CLL 17.38`
    ("18.123", "xy. boi xi vei by. ce'o dy. ve'o"),  # `CLL 18.17`
  ]
    ## lo mupli poi na'e mapti su'o javni pe `CLL 21.1`
    ##   .i le gerna cu to'e curmi le mupli to `D2 a` toi
    ##   .i ro mupli cu se kansa le selci'a pe vo'a zi'e noi se cikre ja'i le javni poi lamji le
    ##       mupli
    ##   .i ro se cikre cu selfi'i
  NUMBERS_MEX = ["18.77", "18.78", "18.105", "18.106", "18.108", "18.109"]
    ## lo mupli poi ciska pa mekso po'o ta'i lo mekso pagbu to `CLL 18.10` .e `CLL 18.14` .e
    ##     `CLL 18.15` toi
  COUNT_READ = 1592
    ## lo te kancu be lo mupli poi vasru lo linji poi claxu lo sinxa poi na lojbo
    ##   .i ro le mupli cu se tcidu
  COUNT_NOTATION = 10
    ## lo te kancu be lo mupli poi ro linji pe ke'a vasru lo sinxa poi na lojbo
    ##   .i le mupli cu du `CLL 2.10` jo'u `CLL 4.46-51` jo'u `CLL 7.39` jo'u `CLL 12.33-34`
  COUNT_ROWS_NOTATION = 33
    ## lo te kancu be lo linji poi vasru lo sinxa poi na lojbo ku'o gi'e na se tcidu



#[ ni'o ni'o ni'o lo tcidu ]#

func rows(number: string): seq[string] =
  ## dunda lo linji pe le mupli poi selna'u `number`
  for example in EXAMPLES_CLL:
    if example.number == number: return example.rows
  doAssert false, "Example should be in corpus; got `" & number & "`."


func isNotation(row: string): bool =
  ## jdice lo du'u xu kau le linji cu vasru lo sinxa pe le cukta zi'e poi no jboselci'a cu vasru
  ##     ke'a
  row.anyIt(it in {'0'..'9', '(', ')', ':', '-'}) or "…" in row


func variants(text: string): seq[string] =
  ## ciska le selci'a re roi
  ##   .i le pamoi cu vasru lo valsi poi lo kurfa grile'u cu sinxa ke'a
  ##   .i le remoi cu claxu le valsi
  ##   .i va'o lo nu no valsi cu selsni kei ciska le selci'a pa roi
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
  ## jdice lo du'u xu kau `readText` tcidu le selci'a ta'i lo nu vasru lo valsi poi lo kurfa grile'u
  ##     cu sinxa ke'a kei .e lo nu claxu le valsi
  text.variants.allIt(it.readText.is_read)


func isReadRows(rows: openArray[string]): bool =
  ## jdice lo du'u xu kau le linji cu se tcidu ta'i lo nu seljo'e kei .a lo nu ro linji cu
  ##     sepseltcidu
  rows.join(" ").isRead or (rows.len > 1 and rows.allIt(it.isRead))


func refusals(number: string): seq[RefusalText] =
  ## dunda lo nu to'e curmi pe ro tarmi be lo seljonli'i pe le mupli
  ##   .i va'o lo nu pa tarmi cu se tcidu kei le jalge cu kunti
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
    check unread == newSeq[string]()  # `CLL 21.1` to ro mupli poi drani ja'i le cukta toi
    # le bandu cu ralte ro mupli poi vasru lo sapli'i
    check count_read == COUNT_READ  # `Article IX.3`
    # le bandu cu cipra lo du'u lo mupli po'o poi ro linji pe ke'a vasru lo sinxa poi na lojbo cu
    #     na'e se tcidu
    check count_notation == COUNT_NOTATION  # `Article IX.3`
    # le bandu cu cipra lo du'u le linji po'o poi le bandu cu cmene ke'a na'e se tcidu
    check count_rows_notation == COUNT_ROWS_NOTATION  # `Article IX.3`


  test "Each example of mex alone reads after li":
    for number in NUMBERS_MEX:
      checkpoint "Example " & number
      # lo mekso pe zo li
      check ("li " & number.rows.join(" ")).isRead  # `CLL 18.10` .e `CLL 18.14` .e `CLL 18.15`
      # lo mekso poi na se lidne zo li na du lo selci'a
      check not number.rows.isReadRows  # `CLL 21.1` `text`


  test "Each example book calls wrong, or writes in English, is refused":
    for (number, refusal) in NUMBERS_WRONG:
      checkpoint "Example " & number
      # ro namcu cu lamji lo sitna be `CLL`
      check number.refusals.len > 0  # `NUMBERS_WRONG`
      # ro namcu cu lamji lo nu to'e curmi
      check number.refusals.allIt(it == refusal)  # `NUMBERS_WRONG`
      # ro linji cu sepli se to'e curmi ji'a
      check not number.rows.isReadRows  # `NUMBERS_WRONG`


  test "Each example breaking rule of 21.1 is refused by grammar, and reads once repaired":
    for (number, repair) in EXAMPLES_BROKEN:
      checkpoint "Example " & number
      check number.refusals.len > 0  # `EXAMPLES_BROKEN` to ro namcu cu lamji lo javni toi
      check number.refusals.allIt(it == RefusalText.Grammar)  # `EXAMPLES_BROKEN` `D2 a`
      # ro linji cu sepli se to'e curmi ji'a
      check not number.rows.isReadRows  # `EXAMPLES_BROKEN`
      # le selci'a cu se cikre ja'i le javni
      #   .i selfi'i
      check repair.isRead  # `EXAMPLES_BROKEN`
