## Extract lojban rows of each numbered example of CLL 1.1 into typed Nim module, with notice of
##   book beside it, for corpus suite to read; `build.nim` runs it.
##   Reads XHTML pages of CLL 1.1, generated 2016-08-26, which lojban.org serves one section to
##   page, each saved under its own name in one directory; renders `tests/cll/examples.nim` and
##   `tests/cll/NOTICE.md`.
##
##   Row is lojban where class of its element is `jbo` or `jbophrase`, as markup of book names
##     lojban text. Cells of table row join by one space, empty cells skipped; paragraph is row
##     alone.
##     Rows of class `pronunciation-jbo` and `compound-cmavo-jbo` are left out: book judges each
##       in prose, and suites of stream and forms hold those judgments by hand, citing example.
##   Rows keep text as book writes it, brackets and notation included: corpus suite decides
##     which rows read, never extraction.
##     No-break space joining words of cell becomes space, and run of white space one space;
##       markup within row is dropped.
##   Example is numbered where title of its `div.example` reads `Example N.M.`; example holding
##     no lojban row is left out, and number given twice fails verb, naming it.
##   Pages are pinned by one SHA-256 over output of `sha256sum` given every page read in order
##     of name: page holding example, and page of section 1.8 holding notice. Page lojban.org moves
##     makes `cll` refuse, never silent rewrite of committed text.
##   Notice is read from section 1.8 and rendered verbatim, as permission of book asks of every
##     modified copy: folder holding extract is distributed under that notice alone.
##     Server of lojban.org hides email address of notice in encoded attribute of span; verb
##       decodes it, so notice reads as book writes it.
##   Cost: pages are read as XML, which XHTML of book is, once each `script` element is cut:
##     script of page holds `&` that XML forbids, and never example. Page served as HTML alone
##     would fail parser, naming page.
##   Cost: digest is read by shelling out to `sha256sum`, as in `lists.nim`.

{.experimental: "strictFuncs".}

import std/[algorithm, os, osproc, parsexml, sequtils, strscans, strutils, xmlparser, xmltree]

import ./literals


type
  Example* = object  ## Define one numbered example as extracted: number and lojban rows.
    chapter*: int  ## Chapter number names first, as `5` of `5.12`.
    index*: int  ## Place in chapter number names second, as `12` of `5.12`.
    rows*: seq[string]  ## Lojban rows in order of book.

  Line = object  ## Define one line of example as markup gives it: class and text.
    class: string  ## Class of element holding line, which names lojban, gloss or translation.
    text: string  ## Text of line, white space collapsed.

  Book* = object  ## Define what pages give: examples, notice, and pin they hash to.
    examples*: seq[Example]  ## Examples in order of number.
    notice*: seq[string]  ## Paragraphs of section 1.8, verbatim.
    digest*: string  ## SHA-256 over output of `sha256sum` given every page read, by name.


const
  DIGEST_CLL* = "5baac481b4483b5efc2099de46b3cdc24f741db8ee6f6ed41b80a3aad659fa55"
    ## SHA-256 over pages of CLL 1.1 generated 2016-08-26, as lojban.org serves them.
  URL_CLL* = "https://lojban.org/publications/cll/cll_v1.1_xhtml-section-chunks/"
    ## Address pages are saved from, one section to page.
  PATH_EXAMPLES* = "tests/cll/examples.nim"  ## Module examples render to.
  PATH_NOTICE* = "tests/cll/NOTICE.md"  ## Notice of book, rendered beside module.
  PAGE_NOTICE = "section-copyright.html"  ## Page of section 1.8, which holds notice.
  CLASSES_LOJBAN = ["jbo", "jbophrase"]  ## Classes of element holding lojban row.
  TAGS_BLOCK = [
    "blockquote", "dd", "div", "dl", "dt", "h1", "h2", "h3", "h4", "li", "ol", "p", "pre",
    "table", "td", "th", "tr", "ul",
  ]
    ## Elements whose edges part words, as browser lays them out.
  WHITESPACE_HTML = {' ', '\t', '\n', '\f', '\r'}  ## White space of HTML; no-break space aside.
  SPACE_NO_BREAK = "\u00A0"  ## No-break space joining words of cell.
  TAG_SCRIPT_CLOSING = "</script>"  ## Tag closing script element of page.
  CLASS_ADDRESS = "__cf_email__"  ## Class of span server writes in place of email address.
  ATTRIBUTE_ADDRESS = "data-cfemail"  ## Attribute holding that address, encoded.



#[ Text ]#

func elements(node: XmlNode): seq[XmlNode] =
  ## Collect child elements of node, text left out.
  for child in node:
    if child.kind == xnElement: result.add child


func isClass(node: XmlNode; tag, class: string): bool =
  ## Decide whether node is element `tag` whose class attribute is `class` exactly.
  node.kind == xnElement and node.tag == tag and node.attr("class") == class


func toAddress(encoded: string): string =
  ## Decode address server hid: first byte of hex is key, each later byte holds letter under it.
  let key = parseHexInt(encoded[0..1])
  for i in countup(2, encoded.high, 2): result.add chr(parseHexInt(encoded[i..i+1]) xor key)


func addText(text: var string, node: XmlNode) =
  ## Append text of node and every node under it; `br` and edge of block give space.
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
  ## Collapse each run of white space, no-break space among, to one space; trim ends.
  for word in text.replace(SPACE_NO_BREAK, " ").split(WHITESPACE_HTML):
    if word.len == 0: continue
    if result.len > 0: result.add ' '
    result.add word


func toText(node: XmlNode): string =
  ## Read text of node as browser shows it, white space collapsed.
  var text: string
  text.addText node
  text.toCollapsed


func toPageXml(text: string): string =
  ## Cut each `script` element from page, since script of book holds `&` that XML forbids.
  var at = 0
  while true:
    let opening = text.find("<script", at)
    if opening < 0: break
    let closing = text.find(TAG_SCRIPT_CLOSING, opening)
    doAssert closing >= 0, "Script should close; got `" & text[opening .. ^1] & "`."
    result.add text[at..<opening]
    at = closing + TAG_SCRIPT_CLOSING.len
  result.add text[at .. ^1]



#[ Lines ]#

func isLineCell(node: XmlNode): bool =
  ## Decide whether element of cell is line of its own: paragraph, phrase or equation.
  node.tag == "p" or node.isClass("span", "foreignphrase") or
      node.isClass("div", "informalequation")


func classLine(node: XmlNode): string =
  ## Name class of line cell element gives: class of paragraph, else kind of element.
  if node.tag == "p": (if node.attr("class").len > 0: node.attr("class") else: "p")
  elif node.tag == "div": "informalequation"
  else: "foreignphrase"


func addLinesRow(lines: var seq[Line], row: XmlNode) =
  ## Add lines of table row: one for each line element of one cell, else one joining cells.
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
  ## Add lines of every element under node: table row, paragraph, phrase or equation.
  for child in node:
    if child.kind != xnElement: continue
    if child.tag == "tr": lines.addLinesRow child
    elif child.tag == "p":
      let class = (if child.attr("class").len > 0: child.attr("class") else: "p")
      lines.add Line(class: class, text: child.toText)
    elif child.isClass("div", "informalequation") or child.isClass("span", "foreignphrase"):
      lines.add Line(class: child.classLine, text: child.toText)
    elif child.tag notin ["a", "br", "col", "colgroup"]: lines.addLines child



#[ Examples ]#

func addExamples(examples: var seq[Example], node: XmlNode) =
  ## Add every numbered example under node that holds lojban row.
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
  ## Decide whether page holds numbered example anywhere.
  if node.isClass("div", "example"): return true
  node.elements.anyIt(it.isExample)


func paragraphsNotice(page: XmlNode): seq[string] =
  ## Read text of each paragraph of section 1.8, title and links of page left out.
  for node in page.elements:
    if node.isClass("div", "section"):
      for child in node.elements:
        if child.tag == "p": result.add child.toText
      return
    result.add node.paragraphsNotice
    if result.len > 0: return



#[ Reading ]#

proc readDigest(directory: string, names: openArray[string]): string =
  ## Hash output of `sha256sum` over named pages, given in order of name, into one SHA-256.
  let (output, code) = execCmdEx(
    "sha256sum " & names.mapIt(quoteShell(it)).join(" "), workingDir = directory
  )
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  let (total, code_total) = execCmdEx("sha256sum", input = output)
  if code_total != 0: quit "Digest could not be read; got `" & total.strip & "`.", 1
  total.splitWhitespace[0]


proc readBook*(directory: string): Book =
  ## Read every page of directory: examples, notice of section 1.8, and digest of pages read.
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



#[ Rendering ]#

func linesExample(example: Example): seq[string] =
  ## Render one example as constructor: on one line where it fits, else one argument to line.
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
  ## Render examples of book as committed module text.
  var lines = @[
    "## Hold lojban rows of each numbered example of CLL 1.1 that holds one, for corpus suite.",
    "##   Written by `nim r tools/build.nim cll <directory>` from pages of CLL 1.1, generated",
    "##   2016-08-26, SHA-256 `" & book.digest[0..31] & "`",
    "##   `" & book.digest[32 .. ^1] & "`; never edit by hand, run verb again.",
    "##   Extracted from version 1.1 of CLL, book of Logical Language Group; folder holding",
    "##     module is distributed under notice of book in `NOTICE.md`, never under licence of",
    "##     repository.",
    "##   Rows of class `jbo` and `jbophrase` alone: cells of row joined by one space, no-break",
    "##     space made space, white space collapsed, markup dropped; text otherwise as book",
    "##     writes it, brackets and notation included.",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type ExampleCll* = object  ## Define one numbered example of CLL 1.1 by lojban rows it " &
    "holds.",
    "  number* {.requiresInit.}: string  ## Number book gives example, as `5.12`.",
    "  rows* {.requiresInit.}: seq[string]  ## Lojban rows in order of book.",
    "",
    "",
    "const EXAMPLES_CLL* = [",
  ]
  for example in book.examples: lines.add example.linesExample
  lines.add "]"
  lines.add "  ## Every numbered example of CLL 1.1 holding lojban row, in order of number."
  lines.join("\n") & "\n"


func linesQuoted(paragraph: string): seq[string] =
  ## Render paragraph as Markdown quotation, wrapped at spaces to fit `WIDTH`.
  var line = ">"
  for word in paragraph.split(' '):
    if line.len > 1 and not (line & " " & word).isFit:
      result.add line
      line = ">"
    line.add " " & word
  result.add line


func toNotice*(book: Book): string =
  ## Render notice of book, with statement of what folder holds and how it was extracted.
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
