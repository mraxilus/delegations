## cipra lo du'u lo prosa pe `lojban_parser` cu me lo lojbo se ciska poi le genturfa'i cu tcidu ke'a
##   .i le prosa cu du ro prosa pagbu pe le ci vreji ge'u .e ro pinka pe le samtci .e le papri ja'i
##     `#818` .e `D1 a` .e `D2 b` .e `D3 a` .e `D4 a`
##   .i le datnyvei cu du lo datnyvei poi la'o gy. git .gy. cu ralte ke'a ku'o .e lo datnyvei poi
##     la'o gy. git .gy. na ralte ke'a zi'e poi no javni be lo nu na jundi cu cmene ke'a .i lo cipra
##     pe la'o gy. curator .gy. cu tcidu le datnyvei ta'i di'u
##   .i `reader_prose.nim` cu tcidu ro se ciska .i le cipra pagbu poi se lidne le vi pinka cu cipra
##     le javni pe `reader_prose.nim` sepi'o lo se ciska poi se finti le cipra pagbu

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, osproc, sequtils, strutils, unittest]

import ./reader_prose


const
  DIRECTORY_PROJECT = currentSourcePath().parentDir.parentDir.parentDir
    ## le genja be le vi se gunka
  RECORDS = ["README.md", "PROVENANCE.md", "GLOSSARY.md"]
    ## le vreji poi `english.nim` cu tcidu ke'a .i ro le vreji cu zvati le genja be le vi se gunka
  EXTENSIONS_SOURCE = [".nim", ".nimble", ".html"]
    ## lo klesi be lo datnyvei poi le cipra be lo gadri cu tcidu lo pinka pe ke'a ne'i le vi se
    ##   gunka
  COUNT_TEXTS_LEAST = 5000
    ## le klani be lo se ciska poi le cipra cu tcidu ke'a cu na mleca le vi namcu .i se ki'u bo le
    ##   cipra cu fliba va'o lo nu le tcidu cu tcidu so'u se ciska
  COUNT_ERRORS_SHOWN = 40
    ## le klani be lo srera poi le fliba cipra pagbu cu ciska ke'a cu na zmadu le vi namcu


proc pathsProse(): seq[string] =
  ## dunda ro datnyvei pe le vi se gunka poi le cipra cu tcidu lo prosa pe ke'a .i ro cmene be lo
  ##   datnyvei cu se krasi le genja be le vi se gunka
  let (output, code) = execCmdEx("git -C " & DIRECTORY_PROJECT.quoteShell &
    " ls-files --cached --others --exclude-standard .")
  doAssert code == 0, "git lists files of project; got `" & output & "`."
  for path in output.splitLines:
    if path in RECORDS or path.splitFile.ext in EXTENSIONS_SOURCE: result.add path


func textsRead(path, content: string): seq[string] =
  ## dunda lo se ciska poi le genturfa'i cu tcidu ke'a ne'i ro prosa pagbu pe le datnyvei .i ro
  ##   porsi be lo canlu lerfu cu se basti pa canlu lerfu
  for text in texts(path, content): result.add text.text.splitWhitespace.join(" ")


suite "Internal: Prose of project, in lojban":
  test "Each prose block of each record, and each comment of code and page, reads as lojban":
    var (found, count) = (newSeq[Error](), 0)
    for path in pathsProse():
      for text in texts(path, readFile(DIRECTORY_PROJECT / path)):
        inc count
        found.add text.errors
    for error in found[0 ..< min(found.len, COUNT_ERRORS_SHOWN)]:
      echo error.path, ":", error.place.line, ":", error.place.column, ": ", error.why
    check found.len == 0
    check count >= COUNT_TEXTS_LEAST

  test "Span reads as one name, quoted by la'o; link as its text; emphasis mark not at all":
    let texts = textsRead("README.md",
      "lo datnyvei `grammar.nim` cu **xamgu**\n\n- [lo vlaste](GLOSSARY.md) cu _barda_\n")
    check texts == @["lo datnyvei la'o gy. grammar.nim .gy. cu xamgu", "lo vlaste cu barda"]

  test "Span that holds word of delimiter takes next delimiter":
    check textsRead("README.md", "`gy` cu lerfu") == @["la'o ky. gy .ky. cu lerfu"]

  test "Heading, table, quotation and fenced code read not; each list item reads alone":
    let texts = textsRead("README.md", "# barda\n\n| a | b |\n> zoi\n\n```\nnaku\n```\n" &
      "- mi klama\n- do cadzu\nle zarci\n")
    check texts == @["mi klama", "do cadzu le zarci"]

  test "Field check reads by name reads not: term and Avoid of glossary, citation of test":
    check textsRead("GLOSSARY.md", "**gismu**:\nlo jicmu valsi\n_Avoid_: root\n") ==
      @["lo jicmu valsi"]
    check textsRead("PROVENANCE.md", "mi cipra ti. Verified by `suites/test_x.nim`.\n") ==
      @["mi cipra ti. ."]
    check textsRead("PROVENANCE.md", "Verified by `atlas changed`.\n") ==
      @["Verified by la'o gy. atlas changed .gy. ."]
    check textsRead("PROVENANCE.md", "mi cipra ti. Verified by\n`suites/test_x.nim`.\n") ==
      @["mi cipra ti. Verified by la'o gy. suites/test_x.nim .gy. ."]

  test "Error names its place in its file":
    let found = texts("README.md", "mi klama\nlo cu xamgu\n")[0].errors
    check found.len > 0
    check found.allIt(it.place.line == 2)

  test "Word erasure erases, and fa'o with what follows it, count as errors of prose":
    check texts("README.md", "mi klama si cadzu\n")[0].errors.anyIt(it.why == "erasure")
    check texts("README.md", "mi klama su do cadzu\n")[0].errors.anyIt(it.why == "su")
    check texts("README.md", "mi klama fa'o do\n")[0].errors.anyIt(it.why == "faho")
    check texts("README.md", "zo si cmavo\n")[0].errors.len == 0

  test "Word zo before span is refused, since zo would quote la'o that suite adds":
    let found = texts("README.md", "zo `se` cmavo\n")[0].errors
    check found.anyIt(it.why == "`zo` before span" and it.place == Place(line: 1, column: 4))

  test "Comment reads as one text; string, character and quoted name holding # read not":
    let source = "## mi klama\n##   le zarci\nlet a = \"# no\"  # do cadzu\nlet b = '#'\n" &
      "const c = \"\"\"\n# no\n\"\"\"\nlet `#d` = 1\n#[ ko sipna ]#\n# mi\n## do\n"
    check textsRead("x.nim", source) ==
      @["mi klama le zarci", "do cadzu", "ko sipna", "mi", "do"]

  test "Line holding marker alone keeps comment going, so its text goes on past that line":
    check textsRead("x.nim", "## mi klama\n##\n##   .i do cadzu\n") == @["mi klama .i do cadzu"]

  test "List marker opening line of comment reads not, as marker of list item in record":
    check textsRead("x.nim", "## mi klama\n##   - do cadzu\n##   1. ko sipna\n") ==
      @["mi klama do cadzu ko sipna"]

  test "Row of table inside comment reads each cell as text; rule of table reads not":
    check textsRead("x.nim", "## | `EBNF` | lo javni |\n## |------|---|\n") ==
      @["la'o gy. EBNF .gy.", "lo javni"]

  test "Comment of page reads as one text, its lines joined":
    check textsRead("pages/x.html", "<p>no</p>\n<!-- mi\n  klama -->\n") == @["mi klama"]
