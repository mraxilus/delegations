## lebna lo lojbo linji pe ro mupli poi se namcu ne'i `CLL 1.1` ku'o gi'e punji le linji pa datnyvei
##   pe la'o gy. Nim .gy. zi'e noi ralte le linji ta'i lo datni poi ponse lo klesi .i ciska ji'a le
##   notci pe le cukta lo datnyvei poi lamji le datnyvei pe la'o gy. Nim .gy. .i le cipra pe le se
##   ciska girzu cu tcidu le datnyvei .i `build.nim` cu pilno le vi datnyvei
##   .i tcidu lo papri be `CLL 1.1` be'o noi se ciska bau la'o gy. XHTML .gy. gi'e se zbasu de'i
##     `2016-08-26` .i la'o gy. lojban.org .gy. cu benji le papri .i ro papri cu vasru pa ckupaupau
##     .i ro papri cu se ralte ne'i pa datnyvei poi se cmene lo cmene be le papri .i ro le datnyvei
##     cu zvati pa datnyveiste .i ciska `tests/cll/examples.nim` .e `tests/cll/NOTICE.md`
##
##   .i lo linji cu lojbo va'o lo nu lo klesi pe le jgena pe le linji cu du `jbo` .a `jbophrase` .i
##     ki'u bo le re klesi cu sinxa lo lojbo se ciska ne'i lo tcita pe le cukta .i ro selci pe pa
##     lijgri pe pa liste cu jorne lo bavla'i selci pa kunti lerfu .i lo kunti selci cu se vimcu .i
##     ro ju'agri cu binxo pa linji
##     .i lo linji pe lo klesi po'u `pronunciation-jbo` .a `compound-cmavo-jbo` cu na se lebna .i
##       ki'u bo le cukta cu jdice fi ro le linji ne'i lo prosa .i `test_stream.nim` .e
##       `test_forms.nim` cu vasru le se jdice poi se ciska ta'i lo nu na'e zmiku gi'e sitna le
##       mupli
##   .i lo linji cu ralte le se ciska pe le cukta .i le se ciska cu vasru lo grile'u .e lo sinxa poi
##     na lojbo .i se ki'u bo le cipra pe le se ciska girzu cu jdice lo du'u ma kau poi linji cu se
##     tcidu .i le nu lebna cu no roi jdice di'u
##     .i lo kunti lerfu poi fanta lo nu katna le linji cu zvati lo jbini be lo valsi pe lo selci .i
##       le kunti lerfu cu binxo lo sampu kunti lerfu .i ro porsi be lo kunti lerfu cu binxo pa
##       kunti lerfu .i lo tcita poi zvati ne'i le linji cu se vimcu
##   .i lo mupli cu se namcu va'o lo nu lo cmene pe le jgena po'u `div.example` pe le mupli cu mintu
##     `Example N.M.` .i lo mupli poi vasru no lojbo linji cu na se lebna .i va'o lo nu pa namcu cu
##     se dunda re roi kei le minde cu fliba gi'e cusku le namcu
##   .i pa sinxa pe la'o gy. SHA-256 .gy. cu stodi sinxa le papri .i le sinxa cu se zbasu fi lo se
##     cusku be `sha256sum` .i `sha256sum` cu tcidu ro papri poi se tcidu ku'o ta'i lo porsi poi se
##     jicmu lo cmene be le papri .i le papri cu du ro papri poi vasru su'o mupli ku'o .e le papri
##     pe `CLL 1.8` zi'e noi vasru le notci .i va'o lo nu la'o gy. lojban.org .gy. cu galfi pa papri
##     kei lo minde po'u `cll` cu to'e curmi .i le minde cu no roi rapli ciska le se ralte ta'i lo
##     nu smaji
##   .i le notci cu se tcidu fi `CLL 1.8` .i le se ciska cu mintu le notci pe le cukta ro valsi .i
##     le notci poi srana lo nu curmi cu cpedu di'u ro galfi fukpi .i se ki'u bo le datnyveiste poi
##     vasru le se lebna cu se benji ja'i le notci po'o
##     .i le sabji pe la'o gy. lojban.org .gy. cu mipri lo samjudri pe le notci ne'i pa mifra se
##       ckaji pe pa jgena po'u `span` .i le minde cu fanva le mifra .i se ki'u bo le notci cu mintu
##       le se ciska pe le cukta
##   .i jdima fa lo nu le papri cu se tcidu ta'i la'o gy. XML .gy. ba lo nu ro jgena po'u `script`
##     cu se vimcu .i la'o gy. XHTML .gy. pe le cukta cu me la'o gy. XML .gy. .i le jgena po'u
##     `script` cu vasru `&` poi la'o gy. XML .gy. cu to'e curmi ke'a ku'o gi'e vasru no mupli .i
##     va'o lo nu pa papri cu se benji ta'i la'o gy. HTML .gy. po'o kei le tcidu be la'o gy. XML
##     .gy. cu fliba gi'e cusku le cmene be le papri
##   .i jdima fa lo nu le sinxa cu se tcidu sepi'o `sha256sum` noi drata samtci .i `lists.nim` cu
##     pilno ji'a `sha256sum`

{.experimental: "strictFuncs".}

import std/[algorithm, os, osproc, parsexml, sequtils, strscans, strutils, xmlparser, xmltree]

import ./literals


type
  Example* = object
    ## pa mupli poi se namcu ku'o ta'i lo nu se lebna .i le mupli cu vasru lo namcu .e lo lojbo
    ##   linji
    chapter*: int
      ## le ckupau poi lo pamoi pagbu be le namcu cu cmene ke'a .i mupli fa `5` pe `5.12`
    index*: int
      ## le stuzi poi lo remoi pagbu be le namcu cu cmene ke'a ne'i le ckupau .i mupli fa `12` pe
      ##   `5.12`
    rows*: seq[string]  ## lo lojbo linji ja'i le porsi pe le cukta

  Line = object
    ## pa linji pe lo mupli ta'i lo nu le tcita cu dunda le linji .i le linji cu vasru lo klesi .e
    ##   lo se ciska
    class: string
      ## lo klesi pe le jgena poi vasru le linji .i le klesi cu cmene lo lojbo se ciska .a lo valsi
      ##   fanva .a lo xe fanva
    text: string  ## le se ciska pe le linji .i ro porsi be lo kunti lerfu cu binxo pa kunti lerfu

  Book* = object
    ## le se dunda be le papri .i le se dunda cu du lo mupli jo'u le notci jo'u le stodi sinxa be le
    ##   papri
    examples*: seq[Example]  ## lo mupli ja'i le porsi be lo namcu
    notice*: seq[string]  ## lo ju'agri pe `CLL 1.8` zi'e noi mintu le se ciska pe le cukta ro valsi
    digest*: string
      ## lo sinxa pe la'o gy. SHA-256 .gy. zi'e poi sinxa lo se cusku be `sha256sum` .i `sha256sum`
      ##   cu tcidu ro papri poi se tcidu ku'o ja'i le porsi be lo cmene


const
  DIGEST_CLL* = "5baac481b4483b5efc2099de46b3cdc24f741db8ee6f6ed41b80a3aad659fa55"
    ## lo sinxa pe la'o gy. SHA-256 .gy. .i le sinxa cu sinxa le papri be `CLL 1.1` be'o poi se
    ##   zbasu de'i `2016-08-26` .i la'o gy. lojban.org .gy. cu benji le papri
  URL_CLL* = "https://lojban.org/publications/cll/cll_v1.1_xhtml-section-chunks/"
    ## lo judri poi le papri cu se cpacu fi ke'a .i ro papri cu vasru pa ckupaupau
  PATH_EXAMPLES* = "tests/cll/examples.nim"  ## le datnyvei poi le mupli cu se ciska fi ke'a
  PATH_NOTICE* = "tests/cll/NOTICE.md"
    ## le notci pe le cukta zi'e noi se ciska fi lo datnyvei poi lamji `PATH_EXAMPLES`
  PAGE_NOTICE = "section-copyright.html"  ## le papri pe `CLL 1.8` zi'e noi vasru le notci
  CLASSES_LOJBAN = ["jbo", "jbophrase"]  ## lo klesi be lo jgena poi vasru lo lojbo linji
  TAGS_BLOCK = [
    "blockquote", "dd", "div", "dl", "dt", "h1", "h2", "h3", "h4", "li", "ol", "p", "pre",
    "table", "td", "th", "tr", "ul",
  ]
    ## lo jgena poi lo korbi be ke'a cu fendi lo valsi ta'i lo nu lo samtci poi pixra lo papri cu
    ##   punji le jgena
  WHITESPACE_HTML = {' ', '\t', '\n', '\f', '\r'}
    ## lo kunti lerfu pe la'o gy. HTML .gy. .i lo kunti lerfu poi fanta lo nu katna le linji cu na
    ##   se vasru
  SPACE_NO_BREAK = "\u00A0"
    ## lo kunti lerfu poi fanta lo nu katna le linji kei gi'e zvati lo jbini be lo valsi pe lo selci
  TAG_SCRIPT_CLOSING = "</script>"  ## lo tcita poi fanmo lo jgena po'u `script` zi'e pe le papri
  CLASS_ADDRESS = "__cf_email__"
    ## le klesi pe le jgena po'u `span` zi'e poi le sabji cu ciska ke'a ne'i lo stuzi be lo samjudri
  ATTRIBUTE_ADDRESS = "data-cfemail"  ## le se ckaji poi vasru le mifra samjudri



#[ lo se ciska ]#

func elements(node: XmlNode): seq[XmlNode] =
  ## jmaji lo panzi jgena pe le jgena .i lo se ciska cu na se jmaji
  for child in node:
    if child.kind == xnElement: result.add child


func isClass(node: XmlNode; tag, class: string): bool =
  ## jdice lo du'u xu kau le jgena cu du lo jgena po'u `tag` zi'e poi lo klesi pe ke'a cu mintu
  ##   `class` ro lerfu
  node.kind == xnElement and node.tag == tag and node.attr("class") == class


func toAddress(encoded: string): string =
  ## fanva le samjudri poi le sabji cu mipri ke'a .i le pamoi stuzi pe le mifra cu ckiku .i ro stuzi
  ##   poi se lidne cu mifra pa lerfu le ckiku
  let key = parseHexInt(encoded[0..1])
  for i in countup(2, encoded.high, 2): result.add chr(parseHexInt(encoded[i..i+1]) xor key)


func addText(text: var string, node: XmlNode) =
  ## jmina le se ciska pe le jgena .e ro jgena poi se vasru le jgena .i `br` .e lo korbi be lo jgena
  ##   pe `TAGS_BLOCK` cu dunda lo kunti lerfu
  case node.kind
  of xnText, xnCData, xnVerbatimText: text.add node.text
  of xnElement:
    if node.tag == "br":
      text.add ' '
      return
    if node.isClass("span", CLASS_ADDRESS):
      text.add node.attr(ATTRIBUTE_ADDRESS).toAddress
      return
    let is_block = node.tag in TAGS_BLOCK
    if is_block: text.add ' '
    for child in node: text.addText child
    if is_block: text.add ' '
  else: discard


func toCollapsed(text: string): string =
  ## galfi ro porsi be lo kunti lerfu fi pa kunti lerfu .i le porsi cu vasru ji'a lo kunti lerfu poi
  ##   fanta lo nu katna le linji .i vimcu lo kunti lerfu poi zvati le re fanmo
  for word in text.replace(SPACE_NO_BREAK, " ").split(WHITESPACE_HTML):
    if word.len == 0: continue
    if result.len > 0: result.add ' '
    result.add word


func toText(node: XmlNode): string =
  ## tcidu le se ciska pe le jgena ta'i lo nu lo samtci poi pixra lo papri cu jarco le se ciska .i
  ##   ro porsi be lo kunti lerfu cu binxo pa kunti lerfu
  var text: string
  text.addText node
  text.toCollapsed


func toPageXml*(text: string): string =
  ## vimcu ro jgena po'u `script` le papri .i ki'u bo le jgena po'u `script` pe le cukta cu vasru
  ##   `&` poi la'o gy. XML .gy. cu to'e curmi ke'a
  ##   .i `translations.nim` cu pilno ji'a le vi fancu tezu'e lo nu stodi sinxa lo papri poi claxu
  ##     le jgena po'u `script` zi'e poi le sabji cu ciska ke'a ca ro nu cpedu
  var at = 0
  while true:
    let opening = text.find("<script", at)
    if opening < 0: break
    let closing = text.find(TAG_SCRIPT_CLOSING, opening)
    doAssert closing >= 0, "Script should close; got `" & text[opening .. ^1] & "`."
    result.add text[at..<opening]
    at = closing + TAG_SCRIPT_CLOSING.len
  result.add text[at .. ^1]



#[ lo linji ]#

func isLineCell(node: XmlNode): bool =
  ## jdice lo du'u xu kau le jgena pe le selci cu du pa linji poi sepli .i le jgena cu du lo ju'agri
  ##   .a lo jufra pagbu .a lo dunli mekso
  node.tag == "p" or node.isClass("span", "foreignphrase") or
      node.isClass("div", "informalequation")


func classLine(node: XmlNode): string =
  ## dunda le klesi pe le linji poi le jgena pe le selci cu dunda ke'a .i va'o lo nu le jgena cu
  ##   ju'agri kei le klesi cu du le se ckaji po'u zoi gy. class .gy. pe le ju'agri .i va'o lo drata
  ##   le klesi cu du lo tarmi be le jgena
  if node.tag == "p": (if node.attr("class").len > 0: node.attr("class") else: "p")
  elif node.tag == "div": "informalequation"
  else: "foreignphrase"


func addLinesRow(lines: var seq[Line], row: XmlNode) =
  ## jmina le linji pe le lijgri pe lo liste .i va'o lo nu pa selci po'o cu vasru lo jgena pe lo
  ##   linji kei ro le jgena cu dunda pa linji .i va'o lo drata jmina pa linji poi jorne le selci
  let
    class_row = row.attr("class")
    class_plain = (if class_row.len > 0: class_row else: "plain")
    cells = row.elements.filterIt(it.tag in ["td", "th"])
  if cells.len == 1:
    let blocks = cells[0].elements.filterIt(it.isLineCell)
    var loose: string
    for child in cells[0]:
      if child.kind == xnText: loose.add child.text
    if blocks.len > 0 and loose.toCollapsed.len == 0:
      for one in blocks:
        let class = (if class_row notin ["", "para"]: class_row else: one.classLine)
        lines.add Line(class: class, text: one.toText)
      return
  let texts = cells.mapIt(it.toText).filterIt(it.len > 0)
  lines.add Line(class: class_plain, text: texts.join(" "))


func addLines(lines: var seq[Line], node: XmlNode) =
  ## jmina le linji pe ro jgena poi se vasru le jgena .i le jgena cu du lo lijgri pe lo liste .a lo
  ##   ju'agri .a lo jufra pagbu .a lo dunli mekso
  for child in node:
    if child.kind != xnElement: continue
    if child.tag == "tr": lines.addLinesRow child
    elif child.tag == "p":
      let class = (if child.attr("class").len > 0: child.attr("class") else: "p")
      lines.add Line(class: class, text: child.toText)
    elif child.isClass("div", "informalequation") or child.isClass("span", "foreignphrase"):
      lines.add Line(class: child.classLine, text: child.toText)
    elif child.tag notin ["a", "br", "col", "colgroup"]: lines.addLines child



#[ lo mupli ]#

func addExamples(examples: var seq[Example], node: XmlNode) =
  ## jmina ro mupli poi se namcu gi'e se vasru le jgena gi'e vasru su'o lojbo linji
  for child in node.elements:
    if not child.isClass("div", "example"):
      examples.addExamples child
      continue
    let titles = child.elements.filterIt(it.isClass("p", "title"))
    doAssert titles.len == 1, "Example should hold one title; got `" & $titles.len & "`."
    var example: Example
    let title = titles[0].toText
    doAssert title.scanf("Example $i.$i.", example.chapter, example.index),
      "Title should read `Example N.M.`; got `" & title & "`."
    var lines: seq[Line]
    for contents in child.elements:
      if contents.attr("class") == "example-contents": lines.addLines contents
    example.rows = lines.filterIt(it.class in CLASSES_LOJBAN).mapIt(it.text)
    if example.rows.len > 0: examples.add example


func isExample(node: XmlNode): bool =
  ## jdice lo du'u xu kau le papri cu vasru su'o mupli poi se namcu .i lo du'u le mupli cu zvati ma
  ##   kau cu na vajni
  if node.isClass("div", "example"): return true
  node.elements.anyIt(it.isExample)


func paragraphsNotice(page: XmlNode): seq[string] =
  ## tcidu le se ciska pe ro ju'agri pe `CLL 1.8` .i le cmene .e lo judri vu'o pe le papri cu na se
  ##   tcidu
  for node in page.elements:
    if node.isClass("div", "section"):
      for child in node.elements:
        if child.tag == "p": result.add child.toText
      return
    result.add node.paragraphsNotice
    if result.len > 0: return



#[ lo nu tcidu ]#

proc readDigest(directory: string, names: openArray[string]): string =
  ## zbasu pa sinxa pe la'o gy. SHA-256 .gy. lo se cusku be `sha256sum` poi tcidu le papri poi se
  ##   cmene ku'o ja'i le porsi be lo cmene
  let (output, code) = execCmdEx(
    "sha256sum " & names.mapIt(quoteShell(it)).join(" "), workingDir = directory
  )
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  let (total, code_total) = execCmdEx("sha256sum", input = output)
  if code_total != 0: quit "Digest could not be read; got `" & total.strip & "`.", 1
  total.splitWhitespace[0]


proc readBook*(directory: string): Book =
  ## tcidu ro papri pe le datnyveiste .i dunda lo mupli .e le notci pe `CLL 1.8` ge'u .e le sinxa be
  ##   le papri poi se tcidu
  var names: seq[string]
  for kind, name in walkDir(directory, relative = true):
    if kind == pcFile and name.endsWith(".html"): names.add name
  names.sort
  if PAGE_NOTICE notin names:
    quit "Page of notice is missing; save pages of `" & URL_CLL & "`; got `" & directory & "`.", 1
  var read: seq[string]
  for name in names:
    let page =
      try: parseXml(readFile(directory / name).toPageXml, {reportWhitespace})
      except XmlError as error:
        quit "Page is no XML; got `" & error.msg & "` for `" & name & "`.", 1
    if name == PAGE_NOTICE:
      result.notice = page.paragraphsNotice
      read.add name
    elif page.isExample:
      result.examples.addExamples page
      read.add name
  result.examples.sort(proc (a, b: Example): int = cmp((a.chapter, a.index), (b.chapter, b.index)))
  for i in 1..<result.examples.len:
    let (a, b) = (result.examples[i-1], result.examples[i])
    if (a.chapter, a.index) == (b.chapter, b.index):
      quit "Number is given twice; got `" & $a.chapter & "." & $a.index & "`.", 1
  result.digest = readDigest(directory, read)



#[ lo nu ciska ]#

func linesExample(example: Example): seq[string] =
  ## ciska pa mupli ta'i lo nu zbasu lo dacti .i va'o lo nu pa linji cu banzu kei ciska pa linji
  ##   po'o .i va'o lo drata ro linji cu vasru pa sumti
  let
    number = "number: \"" & $example.chapter & "." & $example.index & "\""
    rows = "rows: @[" & example.rows.mapIt(it.toLiteral).join(", ") & "]"
    line = "  ExampleCll(" & number & ", " & rows & "),"
  if line.isFit: return @[line]
  result.add "  ExampleCll("
  result.add "    " & number & ","
  if ("    " & rows & ",").isFit:
    result.add "    " & rows & ","
  else:
    result.add "    rows: @["
    for row in example.rows: result.add row.linesLiteral(6, ",")
    result.add "    ],"
  result.add "  ),"


func toModuleExamples*(book: Book): string =
  ## ciska le mupli pe le cukta ta'i le se ciska pe le se ralte datnyvei
  var lines = @[
    "## vasru lo lojbo linji pe ro mupli poi se namcu ne'i `CLL 1.1` gi'e vasru su'o lojbo linji",
    "##   .i le cipra pe le se ciska girzu cu tcidu le linji",
    "##   .i le minde po'u `nim r tools/build.nim cll <directory>` cu ciska le datnyvei ra'i lo",
    "##     papri be `CLL 1.1` be'o poi se zbasu de'i `2016-08-26` .i lo sinxa be le papri be'o",
    "##     pe la'o gy. SHA-256 .gy. cu du `" & book.digest[0..31] & "` ce'o",
    "##     `" & book.digest[32 .. ^1] & "` .i no prenu cu galfi le datnyvei",
    "##     .i lo cenba cu se zbasu lo nu rapli pilno le minde",
    "##   .i le linji cu se lebna fi `CLL 1.1` noi cukta gi'e se dunda la'o gy. Logical Language",
    "##     Group .gy. .i le datnyveiste poi vasru le vi datnyvei cu se benji ja'i le notci pe le",
    "##     cukta zi'e poi zvati `NOTICE.md` .i le datnyveiste cu na se benji ja'i le curmi javni",
    "##     pe la'o gy. delegations .gy.",
    "##   .i le vi datnyvei cu vasru lo linji pe lo klesi po'u `jbo` .a `jbophrase` .i le vi",
    "##     datnyvei cu vasru no drata linji .i ro selci pe pa lijgri cu jorne lo bavla'i selci pa",
    "##     kunti lerfu .i lo kunti lerfu poi fanta lo nu katna le linji cu binxo lo sampu kunti",
    "##     lerfu .i ro porsi be lo kunti lerfu cu binxo pa kunti lerfu .i lo tcita cu se vimcu .i",
    "##     va'o lo drata le se ciska cu mintu le se ciska pe le cukta gi'e ralte lo grile'u .e lo",
    "##     sinxa poi na lojbo",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type ExampleCll* = object  ## skicu pa se namcu mupli pe `CLL 1.1` sepi'o lo lojbo " &
    "linji pe le mupli",
    "  number* {.requiresInit.}: string  ## lo namcu pe le mupli ja'i le cukta mu'u `5.12`",
    "  rows* {.requiresInit.}: seq[string]  ## lo lojbo linji ja'i le porsi pe le cukta",
    "",
    "",
    "const EXAMPLES_CLL* = [",
  ]
  for example in book.examples: lines.add example.linesExample
  lines.add "]"
  lines.add "  ## lo namcu porsi be ro mupli poi se namcu ne'i `CLL 1.1` gi'e vasru lo lojbo linji"
  lines.join("\n") & "\n"


func linesQuoted(paragraph: string): seq[string] =
  ## ciska le ju'agri ta'i lo nu sitna pe la'o gy. Markdown .gy. .i le ju'agri cu se katna bu'u lo
  ##   kunti lerfu tezu'e lo nu mapti `WIDTH`
  var line = ">"
  for word in paragraph.split(' '):
    if line.len > 1 and not (line & " " & word).isFit:
      result.add line
      line = ">"
    line.add " " & word
  result.add line


func toNotice*(book: Book): string =
  ## ciska le notci pe le cukta .i ciska ji'a lo se cusku be lo du'u le datnyveiste cu vasru ma kau
  ##   kei .e lo du'u le se vasru cu se lebna ta'i ma kau
  var lines = @[
    "# Notice",
    "",
    "The file `examples.nim` in this folder holds lojban text from The Complete Lojban Language,",
    "version 1.1, generated 2016-08-26. The Logical Language Group publishes the book at",
    "<" & URL_CLL & ">.",
    "",
    "The text is extracted from the book, and so it is a modified version of the book. These are",
    "the modifications:",
    "",
    "- Only the numbered examples are kept, and of each example only the lines of lojban text.",
    "- The cells of a row of a table are joined by one space.",
    "- A no-break space becomes a space, and a run of white space becomes one space.",
    "- The markup of each line is removed.",
    "",
    "The command `nim r tools/build.nim cll <directory>` writes this folder from saved pages of",
    "the book. This folder is not under the licence of the repository. It is distributed under",
    "the terms of the notice that follows, which Section 1.8 of the book gives:",
    "",
  ]
  for i, paragraph in book.notice:
    if i > 0: lines.add ">"
    lines.add paragraph.linesQuoted
  lines.join("\n") & "\n"
