## Render gap docket: every measurand at pin against both lower bounds, one tab per algebra.
##   Docket is monitoring page: what library spends now, read from committed baselines, and how
##     far each measurand sits from multivector lower bound and type optimised lower bound. It
##     shows nothing baselines do not hold, so it is current exactly when they are.
##   Proposals close on it: each proposal's evaluation overlays its changed functions, and docket
##     counts how many measurands would then stand at bound.
##   Rows carry CSS hooks rather than script: class per filter, custom property per sort key
##     and per bar width, so shell's `:has()` rules sort, filter and rescale.
##
##   Cost: every row renders once per page whatever filter reader picks; 150 rows of four
##     algebras stay under one megabyte.

{.experimental: "strictFuncs".}

import std/[algorithm, json, math, options, sequtils, strutils, tables]

import ../markdown
import ./shell


type
  Figures = object
    ## Define one implementation's counts and movement for one measurand.
    multiplies, divides, bytes, read, written, zeroed, intermediates, copied: int
    fills, count_intermediates, copies, checks: int
    is_inline: bool
  BoundFigures = object
    ## Define multivector lower bound of one measurand, read and written split.
    multiplies, divides, bytes, read, written: int
    shape: string
    steps: seq[string]
    is_chain: bool
  Row = object
    ## Define one measurand as docket shows it.
    id, measurand, symbol, expression, cite: string
    is_general: bool
    library, reference: Option[Figures]
    bound: Option[BoundFigures]
    ns_library, ns_reference, share_nan: float
  Sheet* = object
    ## Define one algebra's documents docket reads.
    name*, title*: string
      ## Short name and title, as `rga4d` and `Rigid 4D`.
    dimensions*: int
      ## Vector space dimensions.
    measurements_static*, measurements_runtime*: JsonNode
      ## Committed baselines at pin.
  Overlay* = object
    ## Define one proposal's changed functions per algebra, and where its page is.
    name*, title*, url*: string
      ## Proposal name, title and published URL; empty URL where unpublished.
    functions*: Table[string, JsonNode]
      ## Algebra name to changed functions, as evaluation records them.



#[ Reading ]#

func rowsOf(sheet: Sheet, ids: JsonNode): seq[Row] =
  ## Read one row per catalogued measurand, docket order; `ids` is docket file whole.

  func figuresOf(function: JsonNode): Option[Figures] =
    ## Read counts and movement of one function; none where function is absent.
    if function.isNil or function.kind != JObject: return none(Figures)
    let
      totals = function{"total"}
      movement = function{"movement"}
    some(Figures(
      multiplies: totals{"multiplies"}.getInt,
      divides: totals{"divides"}.getInt,
      bytes: movement{"bytes_moved"}.getInt,
      read: movement{"bytes_read"}.getInt,
      written: movement{"bytes_written"}.getInt,
      zeroed: movement{"bytes_zeroed"}.getInt,
      intermediates: movement{"bytes_intermediates"}.getInt,
      copied: movement{"bytes_copied"}.getInt,
      fills: totals{"zero_fills"}.getInt,
      count_intermediates: totals{"intermediates"}.getInt,
      copies: totals{"copies"}.getInt,
      checks: totals{"checks"}.getInt,
      is_inline: function{"inline"}.getBool,
    ))

  func boundOf(bound: JsonNode, width: int): Option[BoundFigures] =
    ## Read bound with read and written bytes split out; none where no rule derived.
    ##   Scalar-valued shapes write one double; scale reads operand and one scalar.
    if bound.isNil or bound.kind != JObject: return none(BoundFigures)
    let
      steps = bound{"steps"}.getElems.mapIt(it.getStr)
      shape = bound{"shape"}.getStr
      last = if steps.len > 0: steps[^1] else: shape
      is_chain = bound{"is_chain"}.getBool
      bytes = bound{"bytes_moved"}.getInt
      (read, written) =
        if last == "Scale" and not is_chain: (width + 8, width)
        elif last in ["ScalarForm", "SquaredNorm", "Norm"]: (bytes - 8, 8)
        else: (bytes - width, width)
    some(BoundFigures(
      multiplies: bound{"multiplies"}.getInt,
      divides: bound{"divides"}.getInt,
      bytes: bytes,
      read: read,
      written: written,
      shape: shape,
      steps: steps,
      is_chain: is_chain,
    ))

  let
    width = 8 shl sheet.dimensions
    functions = sheet.measurements_static{"functions"}
    timings = sheet.measurements_runtime{"measurands"}
  for id, measurand in sheet.measurements_static{"measurands"}.pairs:
    let
      key_library = measurand{"library"}.getStr
      key_reference = measurand{"reference"}.getStr
      timing = timings{id}
      timing_library = if timing.isNil: nil else: timing{"library"}
      timing_reference = if timing.isNil: nil else: timing{"reference"}
      is_timed_library = not timing_library.isNil and timing_library.kind == JObject
      is_timed_reference = not timing_reference.isNil and timing_reference.kind == JObject
    result.add Row(
      id: ids{"ids", sheet.name & "/" & id}.getStr,
      measurand: id,
      symbol: measurand{"symbol"}.getStr,
      expression: measurand{"expression"}.getStr,
      cite: measurand{"cite"}.getStr,
      is_general: key_reference.len == 0,
      library: figuresOf(functions{key_library}),
      reference:
        if key_reference.len == 0: none(Figures) else: figuresOf(functions{key_reference}),
      bound: boundOf(measurand{"bound"}, width),
      ns_library: if is_timed_library: timing_library{"ns_median"}.getFloat else: 0.0,
      ns_reference: if is_timed_reference: timing_reference{"ns_median"}.getFloat else: 0.0,
      share_nan: if is_timed_library: timing_library{"nan_share"}.getFloat else: 0.0,
    )
  result.sort(proc (left, right: Row): int = cmp(left.id, right.id))



#[ Facts ]#

type Tally = object
  ## Define counts of one population of rows against bound.
  bounded, at_multiplies, at_bytes, chains: int
  sums_library, sums_bound, sums_reference: array[2, int]
  full: int


func bar(kind: string; value: Option[int]; max_row, max_log: int; tip: string): string =
  ## Render one bar: width against row and against algebra, value, tip.
  if value.isNone:
    return "<div class=\"bar " & kind & " none\" title=\"" & escapeHtml(tip) &
      "\"><div class=\"track\"><i></i></div><span class=\"v\">none</span></div>"
  let
    amount = value.get
    width_row =
      if max_row > 0: max(if amount > 0: 0.8 else: 0.0, 100.0 * amount.float / max_row.float)
      else: 0.0
    width_log =
      if max_log > 0: 100.0 * ln(1.0 + amount.float) / ln(1.0 + max_log.float) else: 0.0
  "<div class=\"bar " & kind & "\" title=\"" & escapeHtml(tip) &
    "\"><div class=\"track\"><i style=\"--w-row:" & width_row.fixed & "%;--w-log:" &
    width_log.fixed & "%\"></i></div><span class=\"v\">" & grouped(amount) & "</span></div>"


func factsHtml(sheet: Sheet, rows: openArray[Row]): string =
  ## Render facts for both populations; typed toggle shows one.

  func tallyOf(rows: openArray[Row], is_typed: bool): Tally =
    ## Count rows at bound and sum their spending; typed population counts rows with all three.
    for row in rows:
      if not is_typed and not row.is_general: continue
      if row.library.isNone or row.bound.isNone: continue
      let (library, bound) = (row.library.get, row.bound.get)
      inc result.bounded
      if library.multiplies <= bound.multiplies: inc result.at_multiplies
      if library.bytes <= bound.bytes: inc result.at_bytes
      if bound.is_chain: inc result.chains
      if is_typed and row.reference.isNone: continue
      inc result.full
      result.sums_library[0] += library.multiplies
      result.sums_library[1] += library.bytes
      result.sums_bound[0] += bound.multiplies
      result.sums_bound[1] += bound.bytes
      if row.reference.isSome:
        result.sums_reference[0] += row.reference.get.multiplies
        result.sums_reference[1] += row.reference.get.bytes

  func fillShare(sheet: Sheet): int =
    ## Read share of library's modelled bytes that are zero fill, in percent.
    var total, zeroed: int
    for _, function in sheet.measurements_static{"functions"}.pairs:
      if function{"module"}.getStr.startsWith("reference"): continue
      total += function{"movement", "bytes_moved"}.getInt
      zeroed += function{"movement", "bytes_zeroed"}.getInt
    if total == 0: 0 else: int(round(100.0 * zeroed.float / total.float))

  func timeRatios(rows: openArray[Row]): seq[float] =
    ## Read library over reference time, per measurand timed on both.
    for row in rows:
      if row.ns_library > 0 and row.ns_reference > 0:
        result.add row.ns_library / row.ns_reference

  let
    general = tallyOf(rows, false)
    typed = tallyOf(rows, true)
    ratios = timeRatios(rows).sorted
    fill = fillShare(sheet)
  result = "<dl class=\"facts\">"
  for (tally, name_class, noun) in [(general, "typed-off", "operations"),
      (typed, "typed-only", "measurands")]:
    result.add "<div class=\"" & name_class & "\"><dt>" & $tally.at_multiplies & "/" &
      $tally.bounded & "</dt><dd>" & noun & " at multivector bound on multiplies</dd></div>" &
      "<div class=\"" & name_class & "\"><dt>" & $tally.at_bytes & "/" & $tally.bounded &
      "</dt><dd>at it on bytes moved</dd></div>"
  result.add "<div><dt>" & $fill & "%</dt><dd>of library's modelled bytes are zero fill</dd></div>"
  if ratios.len > 0:
    result.add "<div class=\"typed-only\"><dt>" & ratioText(ratios[ratios.len div 2]) &
      "</dt><dd>median time against typed form, worst " & ratioText(ratios[^1]) & "</dd></div>"
  result.add "</dl>"
  let sums = [(general, "typed-off"), (typed, "typed-only")]
  result.add "<div class=\"aggregate\">"
  for (label, index) in [("Multiplies, summed", 0), ("Bytes moved, summed", 1)]:
    for (tally, name_class) in sums:
      let top = max([tally.sums_library[index], tally.sums_bound[index],
        tally.sums_reference[index]])
      result.add "<div class=\"" & name_class & "\"><h4>" & label & "</h4><div class=\"bars\">" &
        bar("library", some(tally.sums_library[index]), top, top, "library") &
        bar("bound", some(tally.sums_bound[index]), top, top, "multivector lower bound")
      if name_class == "typed-only":
        result.add bar("reference", some(tally.sums_reference[index]), top, top,
          "type optimised lower bound")
      result.add "</div><p class=\"caption\">" & $tally.full & " " &
        (if name_class == "typed-only": "measurands with all three" else: "operations") &
        ".</p></div>"
  result.add "</div>"



#[ Rows ]#

func metricOf(figures: Option[Figures], is_bytes: bool): Option[int] =
  ## Read bytes or multiplies of figures; none where figures are absent.
  if figures.isNone: none(int)
  elif is_bytes: some(figures.get.bytes)
  else: some(figures.get.multiplies)


func metricOf(bound: Option[BoundFigures], is_bytes: bool): Option[int] =
  ## Read bytes or multiplies of bound; none where no rule derived.
  if bound.isNone: none(int)
  elif is_bytes: some(bound.get.bytes)
  else: some(bound.get.multiplies)


func rowHtml(row: Row; max_log: array[2, int]; order: array[4, int]): string =
  ## Render one row as details: summary cells, then breakdown.

  func panel(row: Row; is_bytes: bool; max_log: int): string =
    ## Render one metric's three bars for row: library, multivector bound, typed reference.
    let
      library = metricOf(row.library, is_bytes)
      reference = metricOf(row.reference, is_bytes)
      bound = metricOf(row.bound, is_bytes)
      max_row = max([library.get(0), bound.get(0), reference.get(0)])
      unit = if is_bytes: " bytes" else: " multiplies"
      shape = if row.bound.isSome: row.bound.get.shape else: ""
    result = "<div class=\"panel bars\">" &
      bar("library", library, max_row, max_log, "library, " & $library.get(0) & unit) &
      bar("bound", bound, max_row, max_log, "multivector lower bound, " & shape)
    if not row.is_general:
      result.add "<div class=\"typed-only\">" &
        bar("reference", reference, max_row, max_log, "type optimised lower bound") & "</div>"
    result.add "</div>"

  func detail(row: Row): string =
    ## Render row's breakdown: expression, citation, shape, and bytes by cause.
    let shape =
      if row.bound.isNone: "no derived shape"
      elif row.bound.get.is_chain: "chain: " & row.bound.get.steps.join(" → ")
      else: row.bound.get.shape
    result = "<div class=\"detail\"><p>" & code(row.expression) & " · " & escapeHtml(row.cite) &
      " · " & escapeHtml(shape) & "</p>"
    if row.library.isSome:
      let library = row.library.get
      result.add "<p>Library: " & $library.fills & " zero fills, " &
        $library.count_intermediates & " intermediates, " & $library.copies & " copies, " &
        $library.checks & " error checks, " & $library.divides & " divides, " &
        (if library.is_inline: "inline" else: "not inline") & ".</p>"
    result.add "<div class=\"table\"><table><tr><th>bytes</th><th>read</th><th>written</th>" &
      "<th>zero fill</th><th>intermediates</th><th>copies</th><th>total</th></tr>"
    for (name, side, name_class) in [("library", row.library, ""),
        ("typed form", row.reference, " class=\"typed-only\"")]:
      if side.isNone: continue
      let figures = side.get
      result.add "<tr" & name_class & "><td>" & name & "</td><td>" & grouped(figures.read) &
        "</td><td>" & grouped(figures.written) & "</td><td>" & grouped(figures.zeroed) &
        "</td><td>" & grouped(figures.intermediates) & "</td><td>" & grouped(figures.copied) &
        "</td><td>" & grouped(figures.bytes) & "</td></tr>"
    if row.bound.isSome:
      let bound = row.bound.get
      result.add "<tr><td>multivector bound</td><td>" & grouped(bound.read) & "</td><td>" &
        grouped(bound.written) & "</td><td>0</td><td>0</td><td>0</td><td>" &
        grouped(bound.bytes) & "</td></tr>"
    result.add "</table></div></div>"

  var classes = @["row"]
  if not row.is_general: classes.add "typed"
  if row.library.isSome and row.bound.isSome and
      row.library.get.multiplies > row.bound.get.multiplies:
    classes.add "above"
  if row.bound.isSome and row.bound.get.is_chain: classes.add "chain"
  if row.share_nan > 0: classes.add "nan"
  var time = if row.ns_library > 0: "<b>" & row.ns_library.fixed(1) & "</b>" else: "–"
  if row.ns_library > 0 and row.ns_reference > 0:
    time.add "<span class=\"typed-only\"> / " & row.ns_reference.fixed(1) & "<br>" &
      ratioText(row.ns_library / row.ns_reference) & "</span>"
  if row.share_nan > 0: time.add chip("NaN " & $int(round(100 * row.share_nan)) & "%", "fail")
  "<details class=\"" & classes.join(" ") & "\" style=\"--o-bytes:" & $order[0] &
    ";--o-multiplies:" & $order[1] & ";--o-typed:" & $order[2] & ";--o-time:" & $order[3] &
    "\"><summary><span class=\"op\"><span class=\"n\">" & escapeHtml(row.measurand) &
    "</span><span class=\"sub\">" & escapeHtml(row.id) & " · " & escapeHtml(row.symbol) &
    "</span></span>" & panel(row, false, max_log[0]) & panel(row, true, max_log[1]) &
    "<span class=\"time\">" & time & "</span></summary>" & detail(row) & "</details>"



#[ Page ]#

func proposalsHtml(sheets: openArray[Sheet], overlays: openArray[Overlay]): string =
  ## Render how far each proposal moves parity with multivector bound.

  func parity(sheet: Sheet; overlay: JsonNode; is_typed: bool): (int, int, int) =
    ## Count rows at bound on multiplies and on bytes, with overlay's functions in place.
    var bounded, at_multiplies, at_bytes: int
    let functions = sheet.measurements_static{"functions"}
    for id, measurand in sheet.measurements_static{"measurands"}.pairs:
      if not is_typed and measurand{"reference"}.getStr.len > 0: continue
      let
        key = measurand{"library"}.getStr
        bound = measurand{"bound"}
      if bound.isNil or key.len == 0 or not functions.hasKey(key): continue
      var function = functions[key]
      if not overlay.isNil and overlay.hasKey(key):
        let after = overlay[key]{"after"}
        if after.isNil or after.kind != JObject: continue
        function = %*{"total": after, "movement": after}
      inc bounded
      if function{"total", "multiplies"}.getInt <= bound{"multiplies"}.getInt: inc at_multiplies
      if function{"movement", "bytes_moved"}.getInt <= bound{"bytes_moved"}.getInt: inc at_bytes
    (bounded, at_multiplies, at_bytes)

  if overlays.len == 0: return ""
  result = "<section class=\"block\"><h2>Proposals against the bound</h2><p class=\"note\">" &
    "Each proposal's evaluation replaces the functions it changes; the rest stay as baselines " &
    "hold them.</p><div class=\"table\"><table><tr><th>Proposal</th><th>Algebra</th>" &
    "<th>At bound on multiplies, now → proposal</th><th>At bound on bytes</th></tr>"
  for overlay in overlays:
    for sheet in sheets:
      if sheet.name notin overlay.functions: continue
      let
        now = parity(sheet, nil, false)
        after = parity(sheet, overlay.functions[sheet.name], false)
        title =
          if overlay.url.len > 0:
            "<a href=\"" & escapeHtml(overlay.url) & "\">" & escapeHtml(overlay.title) & "</a>"
          else: escapeHtml(overlay.title)
      result.add "<tr><td>" & title & "</td><td>" & sheet.title & "</td><td>" &
        $now[1] & "/" & $now[0] & " → " & $after[1] & "/" & $after[0] & "</td><td>" & $now[2] &
        "/" & $now[0] & " → " & $after[2] & "/" & $after[0] & "</td></tr>"
  result.add "</table></div></section>"


const
  CONTROLS = """<div class="controls"><div class="legend"><span class="library">library
now</span><span class="bound">multivector lower bound</span><span class="reference
typed-only">type optimised lower bound</span></div>
<fieldset><legend>Sort</legend>
<label><input type="radio" name="sort" id="sort-bytes" checked> bytes above bound</label>
<label><input type="radio" name="sort" id="sort-multiplies"> multiplies above bound</label>
<label class="typed-only"><input type="radio" name="sort" id="sort-typed"> bytes above typed</label>
<label class="typed-only"><input type="radio" name="sort" id="sort-time"> time against typed</label>
<label><input type="radio" name="sort" id="sort-docket"> docket order</label></fieldset>
<fieldset><legend>Show</legend>
<label><input type="radio" name="show" id="show-all" checked> all</label>
<label><input type="radio" name="show" id="show-above"> above bound on multiplies</label>
<label><input type="radio" name="show" id="show-chain"> chains</label>
<label><input type="radio" name="show" id="show-nan"> returns NaN</label></fieldset>
<fieldset><legend>Scale</legend>
<label><input type="radio" name="scale" id="scale-row" checked> each row</label>
<label><input type="radio" name="scale" id="scale-log"> shared, logarithmic</label></fieldset>
</div>
<div class="head" aria-hidden="true"><span>Operation</span><span>Multiplies</span>
<span>Bytes moved</span><span>Time, ns</span></div>"""
    ## Controls rendered once for every algebra's rows; inputs are read by shell's rules.
  METHOD = """<section class="block"><details><summary>How each figure is computed</summary>
<pre class="formula">W = sizeof(Multivector) = 2^D × 8 bytes

multiplies    = terms `) * (` in emitted C, callees folded, loops by trip
zero fills    = `nimZeroMem` calls
intermediates = local full-width multivectors declared
copies        = whole-object assignments

bytes moved   = operands read + result written
              + (zero fills + intermediates + copies) × W

multivector lower bound, derived from axioms:
bytes         = operands × W + result width        no fill, no intermediate, no copy
multiplies    = terms metric keeps                 wedge 3^D; geometric 4 per dimension,
                                                   3 per null one
chain: multiplies sum steps of its definition, an estimate</pre>
<p class="note">Bytes are modelled from the C, not measured. They rank two versions of one
operation, and do not predict time across different operations. Inspect one yourself with
<code>nim r tools/build.nim show ∧</code>.</p></details></section>"""
    ## Method, same for every algebra.


func docketBody*(
  sheets: openArray[Sheet];
  ids: JsonNode;
  overlays: openArray[Overlay];
  pin, links: string;
): string =
  ## Render docket body: header, one tab per algebra, proposals against bound, method.

  func above(value, base: Option[int]): float =
    ## Read how far value stands above base, as ratio of both plus one; below zero where
    ##   either is absent, so such row sorts last.
    if value.isNone or base.isNone: -1.0 else: (value.get + 1).float / (base.get + 1).float

  func ranks(rows: openArray[Row], keys: openArray[float]): Table[string, int] =
    ## Rank rows by key, largest first; ties, and rows keyed below zero, in docket order.
    var keyed: seq[(float, string)]
    for index, row in rows: keyed.add (keys[index], row.id)
    keyed.sort(proc (left, right: (float, string)): int =
      if left[0] == right[0]: cmp(left[1], right[1]) else: cmp(right[0], left[0]))
    for rank, (_, id) in keyed: result[id] = rank

  let taken = sheets[0].measurements_runtime{"taken"}
  result = "<div class=\"page\"><header><h1>PGA Gap Docket</h1><p class=\"meta\">pga " &
    code(pin[0 ..< 7]) & " · time " & escapeHtml(taken{"date"}.getStr) & ", " &
    escapeHtml(taken{"machine"}.getStr) & " · counts read from emitted C, exact" & links &
    "</p><label class=\"toggle\"><input type=\"checkbox\" id=\"typed\"> typed target</label>" &
    "</header><nav class=\"tabs\" aria-label=\"Algebra\">"
  for index, sheet in sheets:
    result.add "<label><input type=\"radio\" name=\"algebra\" id=\"algebra-" & sheet.name & "\"" &
      (if index == 0: " checked" else: "") & "> " & sheet.title & "</label>"
  result.add "</nav>"
  var rules = "<style>"
  for sheet in sheets:
    rules.add "body:has(#algebra-" & sheet.name & ":checked) .algebra:not(.algebra-" & sheet.name &
      ") { display: none; }\n"
  result.add rules & "</style>"
  var every: seq[seq[Row]]
  for sheet in sheets:
    let rows = rowsOf(sheet, ids)
    every.add rows
    result.add "<section class=\"algebra algebra-" & sheet.name & "\"><div class=\"summary\">" &
      factsHtml(sheet, rows) & "</div></section>"
  result.add CONTROLS
  for index, sheet in sheets:
    let rows = every[index]
    var
      max_log: array[2, int]
      by_bytes, by_multiplies, by_typed, by_time: seq[float]
    for row in rows:
      for side, is_bytes in [false, true]:
        max_log[side] = max([max_log[side], metricOf(row.library, is_bytes).get(0),
          metricOf(row.bound, is_bytes).get(0)])
      by_bytes.add above(metricOf(row.library, true), metricOf(row.bound, true))
      by_multiplies.add above(metricOf(row.library, false), metricOf(row.bound, false))
      by_typed.add above(metricOf(row.library, true), metricOf(row.reference, true))
      by_time.add(if row.ns_reference > 0: row.ns_library / row.ns_reference else: -1.0)
    let order = [ranks(rows, by_bytes), ranks(rows, by_multiplies), ranks(rows, by_typed),
      ranks(rows, by_time)]
    result.add "<section class=\"algebra algebra-" & sheet.name & "\"><div class=\"rows\">"
    for row in rows:
      result.add rowHtml(row, max_log, [order[0][row.id], order[1][row.id], order[2][row.id],
        order[3][row.id]])
    result.add "</div></section>"
  result.add proposalsHtml(sheets, overlays) & METHOD & "</div>"
