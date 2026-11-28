## cipra lo du'u `tools/meanings.nim` tcidu le glico valsi .e le smuni vu'o pe ro valsi pe le liste
##   .i lo mupli linji cu fukpi lo stecmi pe `gismu.txt` .e `cmavo.txt` vu'o poi zvati le stuzi pe
##       vo'a
##   .i ji'a lo mupli linji cu fukpi ro tarmi be lo linji pe `lujvo.txt`
##   .i lo cipra pe le liste poi selpu'i cu na zukte va'o lo nu `lojban-common` na zvati gi'a na
##       mapti le stosni to `Article IX.9` toi
##
## ni'o `CLL` casnu no valsi liste datnyvei
##   .i se ki'u bo lo cmene be le vi cipra cu cfari fi `Internal:`

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, tables, unittest]

import ../../src/browser/lessons
import ../../src/ricysoho/lists/[cmavo, gismu]
import ../../tools/[lists, meanings]


const  # lo klani .e lo mupli smuni
  COUNT_GISMU = 1436  ## lo klani be lo linji be le gimste poi selpu'i ku'o poi vasru lo lerfu
  COUNT_CMAVO = 1091  ## lo klani be lo linji be le ma'oste poi selpu'i ku'o poi vasru lo lerfu
  COUNT_COMPOUND = 493
    ## lo klani be lo linji be le ma'oste poi selpu'i ku'o poi skicu pa ma'orgunma .a pa jufpau
  DEFINITION_BAKFU = "x1 is a bundle/package/cluster/clump/pack [shape/form] containing x2, " &
      "held together by x3"
    ## le smuni be zo bakfu ne'i `gismu.txt` poi selpu'i
  DEFINITION_BACRU = "x1 utters verbally/says/phonates/speaks [vocally makes sound] x2"
    ## le smuni be zo bacru ne'i `gismu.txt`
  DEFINITION_A = "logical connective: sumti afterthought or"
    ## le smuni be zo .a ne'i `cmavo.txt`
  COUNT_LUJVO = 3816
    ## lo klani be lo valsi be le jvoste poi selpu'i ku'o poi se gunma lo lojbo lerfu po'o
  COUNT_GLOSSLESS = 14
    ## lo klani be lo valsi be le jvoste poi selpu'i ku'o poi ponse no glico valsi
  LINES_LUJVO = [
    ("ba'armo'a:barna+morna:pattern of marks:$morna1 $morna2 $=barna1 $morna3 $barna2",
        "ba'armo'a", Meaning(gloss: "pattern of marks", parts: "barna+morna")),
    ("badgai#defend+cover: protective cover/ shield:$bandu1 $=gacri1 $bandu2 $=gacri1 $bandu3",
        "badgai", Meaning(gloss: "protective cover/ shield", parts: "defend+cover",
          is_english: true)),
    ("pevyso'aseltai#[figurative:]+egg+2nd-place-of+shape:egg-shaped:$tarmi2 $tarmi1",
        "pevyso'aseltai", Meaning(gloss: "egg-shaped",
          parts: "[figurative:]+egg+2nd-place-of+shape", is_english: true)),
    ("prulamdeicerni#past+adjacent+full-day+morning:yesterday morning (and not: this morning):" &
        "$cerni1 $=lamji1", "prulamdeicerni", Meaning(
          gloss: "yesterday morning (and not: this morning)",
          parts: "past+adjacent+full-day+morning", is_english: true)),
    ("ci'ersmitai#system+similar+shape:$tarmi1 $=simsa1 $tarmi2 $=simsa2 $ciste1 $=simsa3",
        "ci'ersmitai", Meaning(parts: "system+similar+shape", is_english: true)),
    ("jgeterjo'e#knot+3rd-place-of+joined", "jgeterjo'e",
        Meaning(parts: "knot+3rd-place-of+joined", is_english: true)),
    ("cimnalsra:foldi::cilmo+na'e+srasu foldi marsh", "cimnalsra", Meaning(parts: "foldi")),
    ("jairtai:denmi:xance jgari+tarmi denmi xance:fist:$tarmi1 (omit $tarmi2 $=jgari3)",
        "jairtai", Meaning(gloss: "fist", parts: "denmi")),
    ("febjicla#boil+stir:roil:roil:$jicla1 $jicla2 $=febvi1", "febjicla",
        Meaning(gloss: "roil", parts: "boil+stir", is_english: true)),
  ]
    ## lo mupli linji pe ro tarmi pe `lujvo.txt` .e le valsi .e le smuni be ri
    ##   .i ro mupli linji cu fukpi pa linji pe `lujvo.txt` noi selpu'i
    ##   .i `:` poi zvati lo jbini be `[]` .a `()` cu fendi no datnypau
    ##   .i lo datnypau poi lidne lo glico valsi gi'e vasru `+` cu ciska lo tanru


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
      gismu = "header\n" & placed([(2, "bacru"), (16, "ba'u"), (21, "utter"), (42, "'speak'"),
          (63, DEFINITION_BACRU), (161, "1h")])
      cmavo = "header\n" & placed([(1, ".a"), (12, "A"), (21, "sumti or"), (63, DEFINITION_A),
          (160, "(cf. ja, je)")])
      found = toMeanings(gismu, cmavo, "")
    check found.len == 2  # le sedli'i cu na se tcidu
    check found["bacru"] == Meaning(gloss: "utter", definition: DEFINITION_BACRU)
    # lo lerfu po'u denpa bu cu selvi'u
    check found["a"] == Meaning(gloss: "sumti or", definition: DEFINITION_A)


  test "line of compound of cmavo list gives no meaning, since parser reads each cmavo of it":
    let
      cmavo = "header\n" & placed([(1, ".a'anai"), (12, "UI*1"), (21, "disinterested"),
          (63, "attitudinal: interest - disinterest")]) & "\n" & placed([(1, "ca ma"),
          (12, "PU*"), (21, "when"), (63, "time question")]) & "\n" & placed([(1, ".a"),
          (12, "A"), (21, "sumti or"), (63, DEFINITION_A)])
      found = toMeanings("header\n", cmavo, "")
    check found.len == 1
    check "a'anai" notin found
    check "ca ma" notin found


  test "word in both lists takes meaning of cmavo list":
    let
      gismu = "header\n" & placed([(2, "ba"), (21, "gismu gloss"), (63, "gismu definition")])
      cmavo = "header\n" & placed([(1, "ba"), (12, "PU"), (21, "after"), (63, "after time")])
    check toMeanings(gismu, cmavo, "")["ba"] == Meaning(gloss: "after", definition: "after time")


  test "lujvo reader keeps word, gloss and parts of each shape of line, and skips line of phrase":
    for (line, word, meaning) in LINES_LUJVO:
      checkpoint line
      check line.toMeaningLujvo == some((word, meaning))
    check "datkypi'u gairki'e:datka+pimlu gacri+kicne:eiderdown [quilt]".toMeaningLujvo.isNone
    check ":barna+morna:pattern of marks:".toMeaningLujvo.isNone  # le valsi cu kunti


  test "lujvo takes first line that names it, and never meaning of gismu or cmavo list":
    let
      gismu = "header\n" & placed([(2, "barna"), (21, "mark"), (63, "x1 is a mark")])
      lujvo = ["xirno'i:xirma+nobli:knight, horse-riding noble:$nobli1 $nobli2",
          "xirno'i:xirma+nobli:knight:$nobli1 $nobli2", "barna:bar+na:not a lujvo:"].join("\n")
      found = toMeanings(gismu, "header\n", lujvo)
    check found["xirno'i"].gloss == "knight, horse-riding noble"
    check found["barna"] == Meaning(gloss: "mark", definition: "x1 is a mark")


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
        found = toMeanings(gismu, cmavo, "")
      check gismu.splitLines[1 .. ^1].countIt(it.strip.len > 0) == COUNT_GISMU
      check cmavo.splitLines[1 .. ^1].countIt(it.strip.len > 0) == COUNT_CMAVO
      check cmavo.splitLines[1 .. ^1].countIt('*' in it.field(12, 20)) == COUNT_COMPOUND
      check found["bakfu"] == Meaning(gloss: "bundle", definition: DEFINITION_BAKFU)
      for entry in LIST_GISMU:
        check found.hasKey(entry.word)  # ro gismu ponse lo smuni
        check found.getOrDefault(entry.word).gloss.len > 0
        check found.getOrDefault(entry.word).definition.len > 0
      for entry in LIST_CMAVO:
        check found.hasKey(entry.word)  # ro cmavo ponse lo smuni
        check found.getOrDefault(entry.word).gloss.len > 0
        check found.getOrDefault(entry.word).definition.len > 0


  test "each kind named from lists takes name they hold, and each kind of own text name they lack":
    if not (isInstalled("gismu.txt", DIGEST_GISMU) and isInstalled("cmavo.txt", DIGEST_CMAVO)):
      # `lojban-common` na zvati gi'a na ponse lo liste poi mapti le stosni
      skip()
    else:
      let found = toMeanings(readSource("gismu.txt").text, readSource("cmavo.txt").text, "")
      for lesson in LESSON_KIND:
        checkpoint lesson.lojban
        case lesson.basis
        of Basis.Name: check lesson.lojban in found  # le liste cu vasru le cmene
        of Basis.Own:
          check lesson.lojban notin found  # le liste cu vasru no cmene
          check lesson.english.len > 0 and lesson.text.len > 0
        of Basis.Marker: check lesson.english.len > 0


  test "each lujvo of installed list takes gloss from field after its parts, or none":
    if not isInstalled("lujvo.txt", DIGEST_LUJVO):
      # `lojban-common` na zvati gi'a na ponse lo liste poi mapti le stosni
      skip()
    else:
      var (words, glossless) = (0, 0)
      let found = toMeanings("header\n", "header\n", readSource("lujvo.txt").text)
      for line in readSource("lujvo.txt").text.splitLines:
        let read = line.toMeaningLujvo
        if read.isNone: continue
        let (word, meaning) = read.get
        checkpoint line
        check meaning.gloss.len == 0 or meaning.gloss in line.fieldsLujvo.mapIt(it.strip)
        check not meaning.gloss.startsWith('$')  # le stuzi be le datnypau cu na glico valsi
        check meaning.parts.len > 0
        check found.hasKey(word)
      for meaning in found.values:
        inc words
        if meaning.gloss.len == 0: inc glossless
      check words == COUNT_LUJVO
      check glossless == COUNT_GLOSSLESS
      check found["prulamdei"] == Meaning(
          gloss: "yesterday, the immediately preceding day, the previous day",
          parts: "purci+lamji+djedi")
