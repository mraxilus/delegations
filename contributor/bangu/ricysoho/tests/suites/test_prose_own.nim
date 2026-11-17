## cipra lo du'u lo prosa pe `ricysoho` me lo jboselci'a poi le genturfa'i cu tcidu ke'a
##   .i le prosa cu du ro rospau pe le ci vreji ge'u .e ro pinka pe le samtci .e le papri ja'i
##       `#818` .e `D1 a` .e `D2 b` .e `D3 a` .e `D4 a`
##   .i le datnyvei cu du lo datnyvei poi `git` ralte ke'a ku'o .e lo datnyvei poi `git` na ralte
##       ke'a zi'e poi no javni be lo nu na jundi cu cmene ke'a
##   .i lo cipra pe `curator` tcidu le datnyvei ta'i di'u
##
## ni'o `reader_prose.nim` tcidu ro selci'a
##   .i ji'a le vi datnyvei cu cipra lo du'u ro jufra cu krasi pa linji ja'i lo seljdi pe `#818`
##   .i le cipypau poi se lidne le vi pinka cu cipra le javni pe `reader_prose.nim` sepi'o lo
##       selci'a poi selfi'i le cipypau

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, osproc, sequtils, strutils, tables, unittest]

import ../../src/ricysoho/prose
import ./reader_prose


const
  DIRECTORY_PROJECT = currentSourcePath().parentDir.parentDir.parentDir
    ## le genja be le vi selgu'a
  RECORDS = ["README.md", "PROVENANCE.md", "GLOSSARY.md"]
    ## le vreji poi `english.nim` tcidu ke'a
    ##   .i ro le vreji cu zvati le genja be le vi selgu'a
  EXTENSIONS_SOURCE = [".nim", ".nimble", ".html"]
    ## lo klesi be lo datnyvei poi le cipra be lo gadri cu tcidu lo pinka pe ke'a ne'i le vi selgu'a
  COUNT_TEXTS_LEAST = 5000
    ## le klani be lo selci'a poi le cipra cu tcidu ke'a na mleca le vi namcu
    ##   .i se ki'u bo le cipra cu fliba va'o lo nu le tcidu cu tcidu so'u selci'a
  COUNT_LINES_LEAST = 12000
    ## le klani be lo linji poi le cipra be lo nu punji cu cipra ke'a na mleca le vi namcu
    ##   .i se ki'u bo le cipra cu fliba va'o lo nu le cipra cu cipra so'u linji
  COUNT_ERRORS_SHOWN = 40
    ## le klani be lo srera poi le flicipypau cu ciska ke'a na zmadu le vi namcu


proc pathsProse(): seq[string] =
  ## dunda ro datnyvei pe le vi selgu'a poi le cipra cu tcidu lo prosa pe ke'a
  ##   .i ro cmene be lo datnyvei cu selkra le genja be le vi selgu'a
  let (output, code) = execCmdEx("git -C " & DIRECTORY_PROJECT.quoteShell &
    " ls-files --cached --others --exclude-standard .")
  doAssert code == 0, "git lists files of project; got `" & output & "`."
  for path in output.splitLines:
    if path in RECORDS or path.splitFile.ext in EXTENSIONS_SOURCE: result.add path


func textsRead(path, content: string): seq[string] =
  ## dunda lo selci'a poi le genturfa'i cu tcidu ke'a ne'i ro rospau pe le datnyvei
  ##   .i ro porsi be lo calyle'u cu se basti pa calyle'u
  for text in texts(path, content): result.add text.text.splitWhitespace.join(" ")


func readingMarked(text: Text): ReadingMarked =
  ## tcidu le selci'a ta'i lo nu sinxa ro srera
  ##   .i va'o lo nu le selci'a cu kunti kei le se tcidu cu kunti
  if text.text.strip.len > 0: text.text.readTextMarked else: ReadingMarked()


func faultsRead(path, content: string): seq[string] =
  ## dunda lo krinu be ro srera be lo nu punji lo selci'a fi lo linji ne'i le datnyvei
  let lines = content.splitLines
  var checked = 0
  for text in texts(path, content):
    for fault in text.faultsLayout(lines, text.readingMarked, checked): result.add fault.why


func faultsJoinedRead(path, content: string): seq[string] =
  ## dunda lo krinu be ro srera be lo nu zo cu selvi'u ba lo tanru poi kalri ne'i le datnyvei
  for text in texts(path, content):
    for fault in text.faultsJoined(text.readingMarked): result.add fault.why


proc readingsProject(): tuple[readings: seq[(Text, ReadingMarked)], lines: Table[string,
    seq[string]]] =
  ## tcidu ro selci'a pe le vi selgu'a pa roi gi'e dunda ro linji pe ro datnyvei
  ##   .i le re flalu pe le cipra cu pilno le se tcidu
  for path in pathsProse():
    let content = readFile(DIRECTORY_PROJECT / path)
    result.lines[path] = content.splitLines
    for text in texts(path, content): result.readings.add (text, text.readingMarked)


let PROJECT = readingsProject()
  ## ro selci'a pe le vi selgu'a ge'u .e lo se tcidu pe le selci'a ge'u .e ro linji pe ro datnyvei


proc show(found: seq[Error]) =
  ## ciska lo stuzi .e lo krinu be lo pamoi srera be'o poi le klani be ke'a na zmadu
  ##     `COUNT_ERRORS_SHOWN`
  for error in found[0 ..< min(found.len, COUNT_ERRORS_SHOWN)]:
    echo error.path, ":", error.place.line, ":", error.place.column, ": ", error.why


suite "Internal: Prose of project, in lojban":
  test "Each prose block of each record, and each comment of code and page, reads as lojban":
    var found: seq[Error]
    for (text, marked) in PROJECT.readings: found.add text.errors(marked)
    found.show
    check found.len == 0  # `#818`
    check PROJECT.readings.len >= COUNT_TEXTS_LEAST  # `Article IX.3`

  test "Each sentence of each text opens its own line, at indent its place in its block gives":
    var (found, checked) = (newSeq[Error](), 0)
    for (text, marked) in PROJECT.readings:
      found.add text.faultsLayout(PROJECT.lines[text.path], marked, checked)
    found.show
    check found.len == 0  # `#818`
    check checked >= COUNT_LINES_LEAST  # `Article IX.3`

  test "Selbri after open tanru of head terms takes cu, since reader that does not choose joins it":
    var found: seq[Error]
    for (text, marked) in PROJECT.readings: found.add text.faultsJoined(marked)
    found.show
    check found.len == 0  # `#890`

  test "Selbri after be clause, me or kei takes cu, and selbri after name, pronoun or ku none":
    for (prose, count) in [
        ("ni'o lo nu lo mlatu be mi klama\n", 1), ("ni'o lo nu lo mlatu be mi cu klama\n", 0),
        ("ni'o lo nu lo mlatu be lo gerku ku klama\n", 1), ("ni'o lo nu le me zo zo sitna\n", 1),
        ("ni'o lo nu lo nu mi klama kei xamgu\n", 1),
        ("ni'o lo nu lo nu mi klama kei cu xamgu\n", 0), ("ni'o lo nu la .alis. klama\n", 0),
        ("ni'o lo nu mi klama\n", 0), ("ni'o lo nu lo mlatu ku klama\n", 0),
        ("ni'o lo nu lo mlatu be mi na klama\n", 0)]:
      check faultsJoinedRead("README.md", prose).len == count  # `#890`

  test "Span reads as one name, quoted by la'o; link as its text; emphasis mark not at all":
    let texts = textsRead("README.md",
      "lo datnyvei `grammar.nim` cu **xamgu**\n\n- [lo vlaste](GLOSSARY.md) cu _barda_\n")
    check texts ==
      @["lo datnyvei la'o gy. grammar.nim .gy. cu xamgu", "lo vlaste cu barda"]  # `#818`

  test "Span that holds word of delimiter takes next delimiter":
    check textsRead("README.md", "`gy` cu lerfu") == @["la'o ky. gy .ky. cu lerfu"]  # `#818`

  test "Title, table, quotation and fenced code read not; each list item reads alone":
    let texts = textsRead("README.md", "# barda\n\n| a | b |\n> zoi\n\n```\nnaku\n```\n" &
      "- mi klama\n- do cadzu\nle zarci\n")
    check texts == @["mi klama", "do cadzu le zarci"]  # `english.nim`

  test "Field check reads by name reads not: term and Avoid of glossary, citation of test":
    check textsRead("GLOSSARY.md", "**gismu**:\nlo jicmu valsi\n_Avoid_: root\n") ==
      @["lo jicmu valsi"]  # `#817`
    check textsRead("PROVENANCE.md", "mi cipra ti. Verified by `suites/test_x.nim`.\n") ==
      @["mi cipra ti. ."]  # `#817`
    check textsRead("PROVENANCE.md", "Verified by `atlas changed`.\n") ==
      @["Verified by la'o gy. atlas changed .gy. ."]  # `#817`
    check textsRead("PROVENANCE.md", "mi cipra ti. Verified by\n`suites/test_x.nim`.\n") ==
      @["mi cipra ti. Verified by la'o gy. suites/test_x.nim .gy. ."]  # `#817`

  test "Error names its place in its file":
    let found = texts("README.md", "mi klama\nlo cu xamgu\n")[0].errors
    check found.len > 0  # `#818`
    check found.allIt(it.place.line == 2)  # `#818`

  test "Word erasure erases, and fa'o with what follows it, count as errors of prose":
    check texts("README.md", "mi klama si cadzu\n")[0].errors.anyIt(
      it.why == "erasure")  # `CLL 19.13`
    check texts("README.md", "mi klama su do cadzu\n")[0].errors.anyIt(
      it.why == "su")  # `CLL 19.13`
    check texts("README.md", "mi klama fa'o do\n")[0].errors.anyIt(it.why == "faho")  # `CLL 19.15`
    check texts("README.md", "zo si cmavo\n")[0].errors.len == 0  # `CLL 19.10`

  test "Word zo before span is refused, since zo would quote la'o that suite adds":
    let found = texts("README.md", "zo `se` cmavo\n")[0].errors
    check found.anyIt(it.why == "`zo` before span" and
      it.place == Place(line: 1, column: 4))  # `#818`

  test "Comment reads as one text; string, character and quoted name holding # read not":
    let source = "## mi klama\n##   le zarci\nlet a = \"# no\"  # do cadzu\nlet b = '#'\n" &
      "const c = \"\"\"\n# no\n\"\"\"\nlet `#d` = 1\n#[ ko sipna ]#\n# mi\n## do\n"
    check textsRead("x.nim", source) ==
      @["mi klama le zarci", "do cadzu", "ko sipna", "mi", "do"]  # `#818`

  test "Line holding marker alone keeps comment going, so its text goes on past that line":
    check textsRead("x.nim", "## mi klama\n##\n##   .i do cadzu\n") ==
      @["mi klama .i do cadzu"]  # `#818`

  test "List marker opening line of comment reads not, as marker of list item in record":
    check textsRead("x.nim", "## mi klama\n##   - do cadzu\n##   1. ko sipna\n") ==
      @["mi klama do cadzu ko sipna"]  # `english.nim`

  test "Row of table inside comment reads each cell as text; rule of table reads not":
    check textsRead("x.nim", "## | `EBNF` | lo javni |\n## |------|---|\n") ==
      @["la'o gy. EBNF .gy.", "lo javni"]  # `knoller`

  test "Comment of page reads as one text, its lines joined":
    check textsRead("pages/x.html", "<p>no</p>\n<!-- mi\n  klama -->\n") == @["mi klama"]  # `#818`

  test "Heading of record reads, save title and heading that check reads by name":
    check textsRead("README.md", "# barda\n\n## Standards\n\n## ni'o ni'o ni'o lo krasi\n") ==
      @["ni'o ni'o ni'o lo krasi"]  # `#818`

  test "Sentence that opens inside line is refused, save one inside quotation or after zo":
    check faultsRead("x.nim", "## mi klama .i do cadzu\n") == @["sentence opens mid-line"]  # `#818`
    check faultsRead("x.nim", "## mi klama\n##   .i do cadzu\n").len == 0  # `#818`
    check faultsRead("x.nim", "## mi cusku lu mi klama .i do cadzu li'u\n").len == 0  # `#818`
    check faultsRead("x.nim", "## zo .i cmavo\n").len == 0  # `#818`
    check faultsRead("x.nim", "## mi klama to do cadzu .i mi sipna toi\n") ==
      @["sentence opens mid-line"]  # `#818`
    check faultsRead("x.nim", "## mi klama to do cadzu\n##   .i mi sipna toi\n").len == 0  # `#818`
    check faultsRead("x.nim", "x = 1  # .i mi klama\n").len == 0
    check faultsRead("x.nim", "let a = 1  # mi klama .i do cadzu\n") == @["sentence opens mid-line"]
    check faultsRead("README.md", "ni'o mi klama .i do cadzu\n") ==
      @["sentence opens mid-line"]  # `#818`
    check faultsRead("x.nim", "## | `a` | lo javni .i ro valsi |\n") ==
      @["sentence opens mid-line"]  # `#818`
    check faultsRead("x.nim", "## | `a` | lo javni   |\n## |     | .i ro valsi |\n").len ==
      0  # `#818`

  test "Later sentence stands two past first line, and broken line four past its own":
    check faultsRead("x.nim", "## mi klama\n## .i do cadzu\n") == @["indent"]  # `#818`
    check faultsRead("x.nim", "## mi klama\n##     .i do cadzu\n") == @["indent"]  # `#818`
    check faultsRead("x.nim", "## mi klama le\n##     zarci\n" &
      "##   .i do cadzu le\n##       dinju\n").len == 0  # `#890`
    check faultsRead("x.nim", "## mi klama le\n##   zarci\n") == @["indent"]  # `#890`
    check faultsRead("x.nim", "## mi klama\n##   .i do cadzu le\n##     dinju\n") ==
      @["indent"]  # `#890`
    check faultsRead("README.md", "ni'o mi klama le\n    zarci\n" &
      "  .i do cadzu le\n      dinju\n").len == 0  # `#890`
    check faultsRead("README.md", "ni'o mi klama le\n  zarci\n") == @["indent"]  # `#890`
    check faultsRead("README.md", "ni'o mi klama\n.i do cadzu\n") == @["indent"]  # `#818`
    check faultsRead("README.md", "- ny.mai mi klama le\n      zarci\n" &
      "  .i do cadzu le\n      dinju\n").len == 0  # `#890`
    check faultsRead("pages/x.html", "<!-- mi klama\n       .i do cadzu -->\n").len == 0  # `#818`
    check faultsRead("pages/x.html", "<!-- mi klama le\n         zarci -->\n").len == 0  # `#890`

  test "Paragraph of record opens with ni'o, bullet with ny.mai, and definition bare":
    check faultsRead("README.md", "mi klama\n") == @["opening"]  # `#818`
    check faultsRead("README.md", "ni'o mi klama\n").len == 0  # `#818`
    check faultsRead("README.md", "# barda\n\nni'o mi klama\n") == @["opening"]  # `#818`
    check faultsRead("README.md", "# barda\n\nni'o ni'o ni'o mi klama\n\nni'o do cadzu\n").len ==
      0  # `#818`
    check faultsRead("README.md", "- mi klama\n") == @["opening"]  # `#818`
    check faultsRead("README.md", "- ny.mai mi klama\n").len == 0  # `#818`
    check faultsRead("GLOSSARY.md", "**gismu**:\nni'o lo jicmu valsi\n") == @["opening"]  # `#818`
    check faultsRead("GLOSSARY.md", "**gismu**:\nlo jicmu valsi\n_Avoid_: root\n").len ==
      0  # `#818`

  test "Heading opens with three ni'o, and heading a level below with two":
    check faultsRead("README.md", "## lo krasi\n") == @["opening"]  # `#818`
    check faultsRead("README.md", "## ni'o ni'o ni'o lo krasi\n### ni'o ni'o lo papri\n").len ==
      0  # `#818`
    check faultsRead("README.md", "### ni'o ni'o ni'o lo papri\n") == @["opening"]  # `#818`

  test "Later paragraph of comment opens with ni'o, first bare, and banner with its run":
    check faultsRead("x.nim", "## mi klama\n##\n## ni'o do cadzu\n").len == 0  # `#818`
    check faultsRead("x.nim", "## mi klama\n##\n## .i do cadzu\n") ==
      @["paragraph", "indent"]  # `#818`
    check faultsRead("x.nim", "## ni'o mi klama\n") == @["opening"]  # `#818`
    check faultsRead("x.nim", "## | `a` | lo javni |\n##\n## ni'o mi klama\n").len == 0  # `#818`
    check faultsRead("x.nim", "#[ lo nu tcidu ]#\n") == @["opening"]  # `#818`
    check faultsRead("x.nim", "#[ ni'o ni'o ni'o lo nu tcidu ]#\n").len == 0  # `#818`
