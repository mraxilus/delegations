## Replicate every numbered example of CLL 1.1 against `prose.nim`: each example book calls
##   grammatical reads, and each it calls wrong, or that breaks rule of 21.1, is refused.
##   Corpus is `tests/cll/examples.nim`, extract that `nim r tools/build.nim cll` writes from
##     pages of book, under notice of CLL beside it (ruling `D1 a` of #815); never library
##     output.
##   Example reads where its rows joined read, or each row alone: rows of table are lines of one
##     sentence or of several, and markup of book does not say which.
##   Square bracket marks word text may leave out (5.5), so each text reads with words brackets
##     mark and without them.
##   Row holding notation of book is left out: digit of place variable (2.5), ellipsis,
##     parenthesis, colon after speaker, hyphen. Example whose every row holds it reads nothing.
##   Examples of mex alone, as Sections 18.10, 18.14 and 18.15 write operands, read after `li`.
##   Example breaking rule of 21.1 is refused, as ruling `D2 a` of #815 gives: rule wins over
##     example. Each one reads once repaired as rule beside it asks, and suite holds repair.
##   Corpus does not cover yet: rows of pronunciation of chapter 3 and of compound cmavo of
##     chapter 4, which `test_stream.nim` and `test_forms.nim` hold by hand; trees, which
##     `test_grammar.nim` holds for chapter 5 and Section 18.16.
##   Cost: suite takes about 3.7 s of debug build, measured 2026-11-09 in container of delegate;
##     grammar takes most of it, and stream 0.1 s.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, strutils, unittest]

import ../../src/lojban_parser/prose
import ../cll/examples


const
  NUMBERS_WRONG = [
    ("4.4", RefusalText.Selmaho),  # 4.2, "reserved for experimental purposes", no selma'o
    ("4.77", RefusalText.Stream),  # 4.16, "illegal word in standard Lojban"
    ("16.79", RefusalText.Stream),  # 16.11, English sentence, which markup marks lojban
    ("19.50", RefusalText.Stream),  # 19.10, "ungrammatical as written": `gy` inside text
  ]
    ## Examples book calls wrong, or writes in English, with refusal each takes.
  EXAMPLES_BROKEN = [
    ("14.27", "la djan. .i la .alis. klama le zarci"),  # 14.6, rule 10: `.i` for `.ije`
    (
      "14.123",
      "la djeimyz. ce'e la meris. pe'e je la djordj. ce'e la martas. prami",
    ),  # 14.14, rule 81: `pe'e` takes joik or jek, so `je` for ek `.e`
    (
      "14.131",
      "nu'i mi ce'e bau la lojban. pe'e joi do ce'e bau la gliban. nu'u casnu",
    ),  # 14.15, rule 85: `nu'u` closes termset only after `nu'i`
    (
      "14.133",
      "la djan. fa'u la frank. cusku nu'i bau la lojban. pe'e fa'u bai tu'a la djordj. nu'u",
    ),  # 14.15, rule 85: termset joins no part by `fa'u` after `nu'u`; `pe'e fa'u` does
    ("14.152", "li re gu'e su'i gi pi'i re du li vo"),  # 14.17, rule 371: `gu'e` for `ge`
    ("17.38", "xy. boi xi ky."),  # 17.11, rule 97: subscript after lerfu string needs `boi`
    ("18.118", "li re gu'e su'i gi pi'i re du li vo"),  # 18.17, rule 371, as Example 14.152
    ("18.122", "li pimu su'i ni'upimu ke'i bi'o ke'i ma'upimu"),  # 18.17, rule 806: GAhO twice
    ("18.123", "xy. boi xi vei by. ce'o dy. ve'o"),  # 18.17, rule 97, as Example 17.38
  ]
    ## Examples breaking rule of 21.1, which grammar refuses (`D2 a`), each with its text
    ##   repaired as rule beside it asks; repairs are constructed.
  NUMBERS_MEX = ["18.77", "18.78", "18.105", "18.106", "18.108", "18.109"]
    ## Examples writing mex alone, as operand: Sections 18.10, 18.14 and 18.15.
  COUNT_READ = 1592  ## Examples holding row free of notation, each read.
  COUNT_NOTATION = 10  ## Examples whose every row holds notation: 2.10, 4.46-51, 7.39, 12.33-34.
  COUNT_ROWS_NOTATION = 33  ## Rows holding notation, left out.



#[ Readers ]#

func rows(number: string): seq[string] =
  ## Give rows of example numbered `number`.
  for example in EXAMPLES_CLL:
    if example.number == number: return example.rows
  doAssert false, "Example should be in corpus; got `" & number & "`."


func isNotation(row: string): bool =
  ## Decide whether row holds notation of book, which no lojban text holds.
  row.anyIt(it in {'0'..'9', '(', ')', ':', '-'}) or "…" in row


func variants(text: string): seq[string] =
  ## Write text with words square brackets mark and without them; once where it marks none.
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
  ## Decide whether prose reads, with words square brackets mark and without them.
  text.variants.allIt(it.readText.is_read)


func isReadRows(rows: openArray[string]): bool =
  ## Decide whether rows read joined, or each row alone.
  rows.join(" ").isRead or (rows.len > 1 and rows.allIt(it.isRead))


func refusals(number: string): seq[RefusalText] =
  ## Give refusal of each variant of rows of example joined; empty where one variant reads.
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
    check unread == newSeq[string]()  # 21.1, every example book calls grammatical
    check count_read == COUNT_READ  # IX.3, guard keeps every example holding plain row
    check count_notation == COUNT_NOTATION  # IX.3, guard leaves out notation alone
    check count_rows_notation == COUNT_ROWS_NOTATION  # IX.3, guard leaves out rows it names


  test "Each example of mex alone reads after li":
    for number in NUMBERS_MEX:
      checkpoint "Example " & number
      check ("li " & number.rows.join(" ")).isRead  # 18.10, 18.14, 18.15, operand of `li`
      check not number.rows.isReadRows  # 21.1 rule 0, mex alone is no text


  test "Each example book calls wrong, or writes in English, is refused":
    for (number, refusal) in NUMBERS_WRONG:
      checkpoint "Example " & number
      check number.refusals.len > 0  # NUMBERS_WRONG, citation beside each number
      check number.refusals.allIt(it == refusal)  # NUMBERS_WRONG, refusal beside each number
      check not number.rows.isReadRows  # NUMBERS_WRONG, each row alone too


  test "Each example breaking rule of 21.1 is refused by grammar, and reads once repaired":
    for (number, repair) in EXAMPLES_BROKEN:
      checkpoint "Example " & number
      check number.refusals.len > 0  # EXAMPLES_BROKEN, rule beside each number
      check number.refusals.allIt(it == RefusalText.Grammar)  # EXAMPLES_BROKEN, `D2 a`
      check not number.rows.isReadRows  # EXAMPLES_BROKEN, each row alone too
      check repair.isRead  # EXAMPLES_BROKEN, repaired as rule asks; constructed
