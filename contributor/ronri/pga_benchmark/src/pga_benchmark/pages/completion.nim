## Render library map: derivation of every table, each box in state library holds at pin.
##   Map is committed SVG, `pages/derivation-map.svg`, laid out by hand after P01, which lays out
##     every table of library. Box of operation names catalogue ids it stands for in `data-ids`,
##     and box of table alone names its constant in `data-table`, as `CAYLEYS_WEDGES_TRANS.base`.
##   State of box is read, never drawn. Table: library builds box from table of its own.
##     Composite: library builds it from other operators. Missing: library lacks it.
##   Operation has table where `defineOperator` call in `pga/operators.nim` names its symbol;
##     table alone has one where `pga/cayleys.nim` declares its constant; library offers
##     operation that catalogue holds at any algebra, as `baseline/static_*.json` records it.
##   SVG fades each box with no table, so file reads alone on any page. `checkMap` holds fade to
##     state read, and holds each table library builds to some box, so map that lags library is
##     finding. Page writes state on each box, and missing box takes dashed edge.
##   Lines, formulas and builders under them follow P01; states follow pin.
##
##   Cost: table of operation is read by its symbol, so unary and binary `∙` share one answer;
##     library builds both from tables.
##   Cost: missing operation names id catalogue does not hold, as `distance`. Library that adds
##     it under other id leaves box missing until box names that id.

{.experimental: "strictFuncs".}

import std/[json, sequtils, strutils, tables]

import ../[guard, markdown]
import ./shell


type
  StateBox* {.pure.} = enum  ## Define how library at pin builds what box stands for.
    Tabled = "table"  ## From table of its own.
    Composed = "composite"  ## From other operators, with no table of its own.
    Missing = "missing"  ## Not at all.
  Box* = object  ## Define one box of map that stands for table or operation.
    ids*: seq[string]  ## Catalogue ids of operations box stands for; empty on box of table alone.
    table*: string  ## Constant box stands for, as `CAYLEY_METRIC`; empty on box of operation.
    title*: string  ## Text box shows, tags dropped, its lines parted by comma.
    section*: string  ## Name of block box stands in, as `Interior products`.
    is_faded*: bool  ## Map draws box faded.
    is_input*: bool  ## Box is input of derivation, which holds no state.
  Operation* = object  ## Define one operation catalogue holds.
    symbol*, alias*: string  ## Library symbol and named alias; either may be empty.
  Library* = object  ## Define what library at pin builds, as map reads it.
    tables*: seq[string]  ## Table constants `pga/cayleys.nim` declares.
    symbols*: seq[string]  ## Symbols `defineOperator` builds from table.
    served*: seq[string]  ## Table constants some `defineOperator` reads.
    operations*: Table[string, Operation]  ## Catalogue id to operation, over every algebra.


const
  PATH_CAYLEYS* = "pga/cayleys.nim"  ## Library file declaring tables.
  PATH_OPERATORS* = "pga/operators.nim"  ## Library file building operators.
  MARK_FADED = "<g class=\"faded\">"  ## Group map wraps faded box in.
  ATTRIBUTES = ["data-ids", "data-table"]  ## Attributes naming what box stands for.



#[ Reading ]#

func attributeOf(tag, name: string): string =
  ## Read value of attribute in tag; empty where absent.
  let at = tag.find(" " & name & "=\"")
  if at < 0: return ""
  let
    first = at + name.len + 3
    last = tag.find('"', first)
  if last < 0: "" else: tag[first..<last]


func textOf(html: string): string =
  ## Drop tags of fragment and collapse its whitespace.
  var
    text = ""
    is_tag = false
  for character in html:
    if character == '<': is_tag = true
    elif character == '>': is_tag = false
    elif not is_tag: text.add character
  text.splitWhitespace.join(" ")


func boxesOf*(svg: string): seq[Box] =
  ## Read every box of map that names what it stands for, in order of file.
  ##   Block of box is one whose frame spans top of its rectangle.
  var
    sections: seq[(float, float, string)]
    at = svg.find("<rect class=\"block\"")
  while at >= 0:
    let
      close = svg.find('>', at)
      tag = svg[at..close]
      top = parseFloat(attributeOf(tag, "y"))
      bottom = top + parseFloat(attributeOf(tag, "height"))
      name_at = svg.find("class=\"blockname\"", close)
      name_first = svg.find('>', name_at) + 1
    sections.add (top, bottom, svg[name_first..<svg.find('<', name_first)])
    at = svg.find("<rect class=\"block\"", close)
  at = svg.find("<g data-")
  while at >= 0:
    let
      close = svg.find('>', at)
      tag = svg[at..close]
      ending = svg.find("</g>", close)
      inner = svg[close+1..<ending]
      rect_at = inner.find("<rect ")
      rect = inner[rect_at..inner.find('>', rect_at)]
      top = parseFloat(attributeOf(rect, "y"))
    var box = Box(
      ids: attributeOf(tag, ATTRIBUTES[0]).splitWhitespace,
      table: attributeOf(tag, ATTRIBUTES[1]),
      title: inner.split("</text>").mapIt(textOf(it)).filterIt(it.len > 0).join(", "),
      is_faded: svg[0..<at].strip(leading = false).endsWith(MARK_FADED),
      is_input: attributeOf(rect, "class") == "input",
    )
    for (first, last, name) in sections:
      if top >= first and top <= last: box.section = name
    result.add box
    at = svg.find("<g data-", ending)


func libraryOf*(files: Table[string, string], catalogues: openArray[JsonNode]): Library =
  ## Read what library at pin builds, from its source and catalogue of each algebra.

  func literalAt(text: string, at: int): string =
    ## Read string literal opening at `at`, raw where `r` leads it; empty where none opens.
    if at >= text.len: return ""
    if text[at] == 'r' and at + 1 < text.len and text[at+1] == '"':
      let last = text.find('"', at + 2)
      return if last < 0: "" else: text[at+2..<last]
    if text[at] != '"': return ""
    var index = at + 1
    while index < text.len and text[index] != '"':
      if text[index] == '\\' and index + 1 < text.len: inc index
      result.add text[index]
      inc index

  for line in files.getOrDefault(PATH_CAYLEYS).splitLines:
    var name = line.strip
    if name.startsWith("const "): name = name["const ".len .. ^1]
    if not name.startsWith("CAYLEY"): continue
    var last = 0
    while last < name.len and name[last] in {'A'..'Z', '_'}: inc last
    if last < name.len and name[last] == '*': result.tables.add name[0..<last]
  let operators = files.getOrDefault(PATH_OPERATORS)
  var at = operators.find("defineOperator(")
  while at >= 0:
    let next = operators.find("defineOperator(", at + 1)
    if not operators[0..<at].strip(leading = false).endsWith("macro"):
      let
        call = operators[at..<(if next < 0: operators.len else: next)]
        at_symbols = call.find("symbols = ")
        at_cayley = call.find("cayley = ")
      if at_symbols >= 0 and at_cayley >= 0:
        let symbol = literalAt(call, at_symbols + "symbols = ".len)
        if symbol.len > 0 and symbol notin result.symbols: result.symbols.add symbol
        var last = at_cayley + "cayley = ".len
        let first = last
        while last < call.len and call[last] in {'A'..'Z', '_'}: inc last
        if call[first..<last] notin result.served: result.served.add call[first..<last]
    at = next
  for catalogue in catalogues:
    for id, measurand in catalogue{"measurands"}.pairs:
      result.operations[id] = Operation(
        symbol: measurand{"symbol"}.getStr,
        alias: measurand{"alias"}.getStr,
      )


func spelling*(operation: Operation): string =
  ## Spell operation as library does: symbol where it has one, else alias.
  if operation.symbol.len > 0: operation.symbol else: operation.alias


func stateOf*(box: Box, library: Library): StateBox =
  ## Read state of box: weakest over operations it stands for, or of its table alone.
  ##   Operation catalogue holds by neither symbol nor alias is no operation of library.
  if box.table.len > 0:
    return if box.table.split('.')[0] in library.tables: StateBox.Tabled else: StateBox.Missing
  result = StateBox.Tabled
  for id in box.ids:
    let
      operation = library.operations.getOrDefault(id)
      state =
        if operation.spelling.len == 0: StateBox.Missing
        elif operation.symbol in library.symbols: StateBox.Tabled
        else: StateBox.Composed
    result = max(result, state)



#[ Checking ]#

func checkMap*(boxes: openArray[Box], library: Library, path: string): seq[Finding] =
  ## Hold map to library at pin: fade of each box to its state, each table to some box.
  ##   Table is on map where box names its constant, or where box stands for operation built
  ##     from it; operation built from table is on map where box stands for its symbol.
  var
    symbols: seq[string]
    tables: seq[string]
  for box in boxes:
    if box.table.len > 0: tables.add box.table.split('.')[0]
    for id in box.ids:
      let symbol = library.operations.getOrDefault(id).symbol
      if symbol.len > 0: symbols.add symbol
    if box.is_input: continue
    let state = box.stateOf(library)
    if box.is_faded != (state != StateBox.Tabled):
      result.add Finding(
        path: path,
        message: "Box `" & box.title & "` is drawn " & (if box.is_faded: "faded" else: "solid") &
            ", where library at pin holds it as " & $state & "; redraw it; got `" &
            (if box.table.len > 0: box.table else: box.ids.join(" ")) & "`.",
      )
  for symbol in library.symbols:
    if symbol notin symbols:
      result.add Finding(
        path: path,
        message: "Library builds operation from table, and no box stands for it; got `" &
            symbol & "`.",
      )
  for table in library.tables:
    if table notin tables and table notin library.served:
      result.add Finding(
        path: path,
        message: "Library declares table, and no box or operator names it; got `" & table & "`.",
      )



#[ Rendering ]#

func svgStated*(svg: string, library: Library): string =
  ## Copy map with state of each box written on its group, as `data-state="missing"`.
  var at = 0
  while true:
    let next = svg.find("<g data-", at)
    if next < 0:
      result.add svg[at .. ^1]
      break
    let
      close = svg.find('>', next)
      boxes = boxesOf(svg[next .. svg.find("</g>", close) + "</g>".len - 1])
      state = if boxes.len > 0: $boxes[0].stateOf(library) else: ""
    result.add svg[at..<close] & " data-state=\"" & state & "\">"
    at = close + 1


func chipState(state: StateBox): string =
  ## Render state of box as chip.
  case state
  of StateBox.Tabled: chip("table", "pass")
  of StateBox.Composed: chip("from other operators", "status")
  of StateBox.Missing: chip("not in library", "")


func bodyCompletion*(svg: string, library: Library, pin, url_derivation: string): string =
  ## Render library map body: header, counts by state, map, then every box with its state.
  ##   `url_derivation` is where P01 is published; P01 stands unlinked where empty.
  let
    derivation =
      if url_derivation.len > 0: "<a href=\"" & escapeHtml(url_derivation) & "\">P01</a>"
      else: "P01"
    boxes = boxesOf(svg).filterIt(not it.is_input)
    states = boxes.mapIt(it.stateOf(library))
    count_tabled = states.countIt(it == StateBox.Tabled)
    count_composed = states.countIt(it == StateBox.Composed)
    count_missing = states.countIt(it == StateBox.Missing)
  result = "<div class=\"page\"><header><h1>Library map</h1><p class=\"meta\">pga " &
      code(pin[0..<min(7, pin.len)]) & " · state of each box read from library at pin" &
      "</p><p>The map derives every Cayley table of the library from two inputs, the metric " &
      "and the orientation of 𝟙, as " & derivation & " lays them out. Each box takes the " &
      "state that the library holds at the pin, so the map fills in as the library grows. " &
      "Proposals count only the tables that the library builds.</p></header>"
  result.add "<section class=\"block\"><h2>Completion at pin</h2><dl class=\"facts\"><div><dt>" &
      $count_tabled & "/" & $boxes.len & "</dt><dd>boxes the library builds from a table of " &
      "their own</dd></div><div><dt>" & $count_composed & "</dt><dd>boxes it builds from other " &
      "operators</dd></div><div><dt>" & $count_missing & "</dt><dd>boxes not in the " &
      "library</dd></div></dl></section>"
  result.add "<section class=\"block\"><h2>Map</h2><figure class=\"figure\"><div " &
      "class=\"figure-art\">" & svgStated(svg, library) & "</div><figcaption>Eleven blocks " &
      "follow the groups of the code, and each box holds a symbol. Green boxes are the two " &
      "inputs, grey boxes are basis and projective elements, and purple anti tables stand " &
      "under their blue tables. A dashed box on the top row of a block brings in the boxes of " &
      "one other block, one cell for each box, and each block builds downward. Each box takes " &
      "its own line from each box that it uses, so no two lines join or fork. Each line " &
      "carries its formula, with the function that builds the table under it, as " &
      derivation & " names it. A faded line is a route that the code does not take. A faded " &
      "box has no table of its own, and a faded box with a dashed edge is not in the library. " &
      "Brown text holds in RGA alone, and blue text in CGA alone.</figcaption></figure>" &
      "</section>"
  result.add "<section class=\"block\"><h2>Every box</h2><div class=\"table\"><table " &
      "class=\"boxes\"><tr><th>Block</th><th>Box</th><th>Library</th><th>State</th></tr>"
  for index, box in boxes:
    var spelled: seq[string]
    if box.table.len > 0: spelled.add code(box.table)
    for id in box.ids:
      let operation = library.operations.getOrDefault(id)
      if operation.spelling.len > 0: spelled.add code(operation.spelling)
    result.add "<tr><td>" & escapeHtml(box.section) & "</td><td>" & escapeHtml(box.title) &
        "</td><td>" & (if spelled.len > 0: spelled.join(" ")
        else: "<span class=\"none\">none</span>") & "</td><td>" & chipState(states[index]) &
        "</td></tr>"
  result.add "</table></div></section></div>"
