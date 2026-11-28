## cipra lo du'u `tools/meanings.nim` tcidu le glico valsi .e le smuni vu'o pe ro valsi pe le liste
##   .i lo mupli linji cu fukpi lo stecmi pe `gismu.txt` .e `cmavo.txt` vu'o poi zvati le stuzi pe
##       vo'a
##   .i lo cipra pe le liste poi selpu'i cu na zukte va'o lo nu `lojban-common` na zvati gi'a na
##       mapti le stosni to `Article IX.9` toi
##
## ni'o `CLL` casnu no valsi liste datnyvei
##   .i se ki'u bo lo cmene be le vi cipra cu cfari fi `Internal:`

{.experimental: "strictFuncs".}

import std/[os, strutils, tables, unittest]

import ../../src/ricysoho/lists/[cmavo, gismu]
import ../../tools/[lists, meanings]


const
  COUNT_GISMU_LEAST = 1400
    ## lo du'u le gimste cu vasru su'o xo kau linji
    ##   .i ca lo nu le cipra cu se jmina kei le klani cu du li 1436
  COUNT_CMAVO_LEAST = 1050
    ## lo du'u le ma'oste cu vasru su'o xo kau linji
    ##   .i ca lo nu le cipra cu se jmina kei le klani cu du li 1091
  DEFINITION_BACRU = "x1 utters verbally/says/phonates/speaks [vocally makes sound] x2"
    ## le smuni be zo bacru ne'i `gismu.txt`
  DEFINITION_A = "logical connective: sumti afterthought or"
    ## le smuni be zo .a ne'i `cmavo.txt`


func placed(fields: openArray[(int, string)]): string =
  ## pa linji poi ro selci'a cu zvati le stuzi poi le liste cu ciska ke'a
  ##   .i lo namcu pe le pamoi stuzi cu du li 1
  for (column, text) in fields:
    result.add ' '.repeat(column - 1 - result.len)
    result.add text


func separators(columns: openArray[(int, int)]): seq[int] =
  ## ro stuzi poi zvati lo jbini be re datnypau
  for (first, last) in columns[1 .. ^1]: result.add [first - 1, last + 1]


proc isInstalled(name, pin: string): bool =
  ## jdice lo du'u `lojban-common` cu zvati gi'e ponse lo liste poi mapti le stosni
  fileExists(getEnv(KEY_LISTS, DIRECTORY_LISTS) / name) and readSource(name).digest == pin


suite "Internal: Meanings of the wordlists":

  test "reader keeps gloss and definition of each line from their columns, header skipped":
    let
      gismu = "header\n" & placed([(2, "bacru"), (16, "ba'u"), (21, "utter"),
          (63, DEFINITION_BACRU), (161, "1h")])
      cmavo = "header\n" & placed([(1, ".a"), (12, "A"), (21, "sumti or"), (63, DEFINITION_A)])
      found = toMeanings(gismu, cmavo)
    check found.len == 2  # le sedli'i cu na se tcidu
    check found["bacru"] == Meaning(gloss: "utter", definition: DEFINITION_BACRU)
    # lo lerfu po'u denpa bu cu selvi'u
    check found["a"] == Meaning(gloss: "sumti or", definition: DEFINITION_A)


  test "word in both lists takes meaning of cmavo list":
    let
      gismu = "header\n" & placed([(2, "ba"), (21, "gismu gloss"), (63, "gismu definition")])
      cmavo = "header\n" & placed([(1, "ba"), (12, "PU"), (21, "after"), (63, "after time")])
    check toMeanings(gismu, cmavo)["ba"] == Meaning(gloss: "after", definition: "after time")


  test "no character of any installed line falls between two fields that reader reads":
    for (name, pin, columns) in [("gismu.txt", DIGEST_GISMU, COLUMNS_GISMU),
        ("cmavo.txt", DIGEST_CMAVO, COLUMNS_CMAVO)]:
      if not isInstalled(name, pin):
        # `lojban-common` na zvati gi'a na ponse lo liste poi mapti le stosni
        #   .i lo minde po'u `head` cusku le nu na mapti
        skip()
        continue
      let lines = readSource(name).text.splitLines[1 .. ^1]
      for line in lines:
        for column in columns.separators:
          check line.len < column or line[column - 1] == ' '  # le stuzi cu kunti


  test "each gismu and each cmavo of parser lists takes gloss and definition":
    if not (isInstalled("gismu.txt", DIGEST_GISMU) and isInstalled("cmavo.txt", DIGEST_CMAVO)):
      # `lojban-common` na zvati gi'a na ponse lo liste poi mapti le stosni
      skip()
    else:
      let
        gismu = readSource("gismu.txt").text
        cmavo = readSource("cmavo.txt").text
        found = toMeanings(gismu, cmavo)
      check gismu.splitLines.len - 1 >= COUNT_GISMU_LEAST
      check cmavo.splitLines.len - 1 >= COUNT_CMAVO_LEAST
      for entry in LIST_GISMU:
        check found.hasKey(entry.word)  # ro gismu ponse lo smuni
        check found.getOrDefault(entry.word).gloss.len > 0
        check found.getOrDefault(entry.word).definition.len > 0
      for entry in LIST_CMAVO:
        check found.hasKey(entry.word)  # ro cmavo ponse lo smuni
        check found.getOrDefault(entry.word).gloss.len > 0
        check found.getOrDefault(entry.word).definition.len > 0
