## Render gap docket: every measurand at pin against both lower bounds, one tab per algebra.
##   Docket is monitoring page: what library spends now, read from committed baselines, and how
##     far each measurand sits from multivector lower bound and type optimised lower bound. It
##     shows nothing baselines do not hold, so it is current exactly when they are.
##   Designs close on it: each design's trial overlays its changed functions, and docket counts
##     how many measurands would then stand at bound.
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
    fills, intermediate_count, copies, checks: int
    is_inline: bool
  BoundFigures = object
    ## Define multivector lower bound of one measurand, read and written split.
    multiplies, divides, bytes, read, written: int
    shape: string
    steps: seq[string]
    is_composed: bool
  Row = object
    ## Define one measurand as docket shows it.
    id, measurand, symbol, expression, cite: string
    is_general: bool
    library, reference: Option[Figures]
    bound: Option[BoundFigures]
    ns_library, ns_reference, nan_share: float
  Sheet* = object
    ## Define one algebra's documents docket reads.
    name*, title*: string
      ## Short name and title, e.g. `rga4d`, `Rigid 4D`.
    dimensions*: int
      ## Vector space dimensions.
    static_measurements*, runtime_measurements*: JsonNode
      ## Committed baselines at pin.
  Overlay* = object
    ## Define one design's changed functions per algebra, and where its page is.
    name*, title*, url*: string
      ## Design name, title and published URL; empty URL where unpublished.
    functions*: Table[string, JsonNode]
      ## Algebra name to changed functions, as trial records them.



#[ Reading ]#

func figuresOf(f: JsonNode): Option[Figures] =
  ## Read counts and movement of one function; none where function is absent.
  if f.isNil or f.kind != JObject: return none(Figures)
  let
    t = f{"total"}
    m = f{"movement"}
  some(Figures(
    multiplies: t{"multiplies"}.getInt,
    divides: t{"divides"}.getInt,
    bytes: m{"bytes_moved"}.getInt,
    read: m{"bytes_read"}.getInt,
    written: m{"bytes_written"}.getInt,
    zeroed: m{"bytes_zeroed"}.getInt,
    intermediates: m{"bytes_intermediates"}.getInt,
    copied: m{"bytes_copied"}.getInt,
    fills: t{"zero_fills"}.getInt,
    intermediate_count: t{"intermediates"}.getInt,
    copies: t{"copies"}.getInt,
    checks: t{"checks"}.getInt,
    is_inline: f{"inline"}.getBool,
  ))


func boundOf(b: JsonNode, width: int): Option[BoundFigures] =
  ## Read bound with read and written bytes split out; none where no rule derived.
  ##   Scalar-valued shapes write one double; scale reads operand and one scalar.
  if b.isNil or b.kind != JObject: return none(BoundFigures)
  let
    steps = b{"steps"}.getElems.mapIt(it.getStr)
    shape = b{"shape"}.getStr
    last = if steps.len > 0: steps[^1] else: shape
    is_composed = b{"is_composed"}.getBool
    bytes = b{"bytes_moved"}.getInt
    (read, written) =
      if last == "Scale" and not is_composed: (width + 8, width)
      elif last in ["ScalarForm", "SquaredNorm", "Norm"]: (bytes - 8, 8)
      else: (bytes - width, width)
  some(BoundFigures(
    multiplies: b{"multiplies"}.getInt,
    divides: b{"divides"}.getInt,
    bytes: bytes,
    read: read,
    written: written,
    shape: shape,
    steps: steps,
    is_composed: is_composed,
  ))


func rowsOf(sheet: Sheet, ids: JsonNode): seq[Row] =
  ## Read one row per catalogued measurand, docket order; `ids` is docket file whole.
  let
    width = 8 shl sheet.dimensions
    functions = sheet.static_measurements{"functions"}
    timings = sheet.runtime_measurements{"measurands"}
  for id, m in sheet.static_measurements{"measurands"}.pairs:
    let
      library_key = m{"library"}.getStr
      reference_key = m{"reference"}.getStr
      timing = timings{id}
      lt = if timing.isNil: nil else: timing{"library"}
      rt = if timing.isNil: nil else: timing{"reference"}
    result.add Row(
      id: ids{"ids", sheet.name & "/" & id}.getStr,
      measurand: id,
      symbol: m{"symbol"}.getStr,
      expression: m{"expression"}.getStr,
      cite: m{"cite"}.getStr,
      is_general: reference_key.len == 0,
      library: figuresOf(functions{library_key}),
      reference: if reference_key.len == 0: none(Figures) else: figuresOf(functions{reference_key}),
      bound: boundOf(m{"bound"}, width),
      ns_library: if lt.isNil or lt.kind != JObject: 0.0 else: lt{"ns_median"}.getFloat,
      ns_reference: if rt.isNil or rt.kind != JObject: 0.0 else: rt{"ns_median"}.getFloat,
      nan_share: if lt.isNil or lt.kind != JObject: 0.0 else: lt{"nan_share"}.getFloat,
    )
  result.sort(proc (a, b: Row): int = cmp(a.id, b.id))



#[ Facts ]#

type Tally = object
  ## Define counts of one population of rows against bound.
  bounded, at_multiplies, at_bytes, composed: int
  sums_library, sums_bound, sums_reference: array[2, int]
  full: int


func tallyOf(rows: openArray[Row], is_typed: bool): Tally =
  ## Count rows at bound and sum their spending; typed population counts rows with all three.
  for r in rows:
    if not is_typed and not r.is_general: continue
    if r.library.isNone or r.bound.isNone: continue
    let (l, b) = (r.library.get, r.bound.get)
    inc result.bounded
    if l.multiplies <= b.multiplies: inc result.at_multiplies
    if l.bytes <= b.bytes: inc result.at_bytes
    if b.is_composed: inc result.composed
    if is_typed and r.reference.isNone: continue
    inc result.full
    result.sums_library[0] += l.multiplies
    result.sums_library[1] += l.bytes
    result.sums_bound[0] += b.multiplies
    result.sums_bound[1] += b.bytes
    if r.reference.isSome:
      result.sums_reference[0] += r.reference.get.multiplies
      result.sums_reference[1] += r.reference.get.bytes


func fillShare(sheet: Sheet): int =
  ## Read share of library's modelled bytes that are zero fill, in percent.
  var total, zeroed: int
  for _, f in sheet.static_measurements{"functions"}.pairs:
    if f{"module"}.getStr.startsWith("reference"): continue
    total += f{"movement", "bytes_moved"}.getInt
    zeroed += f{"movement", "bytes_zeroed"}.getInt
  if total == 0: 0 else: int(round(100.0 * zeroed.float / total.float))


func timeRatios(rows: openArray[Row]): seq[float] =
  ## Read library over reference time, per measurand timed on both.
  for r in rows:
    if r.ns_library > 0 and r.ns_reference > 0: result.add r.ns_library / r.ns_reference



#[ Rendering ]#

func bar(kind: string, value: Option[int], row_max, log_max: int, tip: string): string =
  ## Render one bar: width against row and against algebra, value, tip.
  if value.isNone:
    return "<div class=\"bar " & kind & " none\" title=\"" & escapeHtml(tip) &
      "\"><div class=\"track\"><i></i></div><span class=\"v\">none</span></div>"
  let
    v = value.get
    row_width = if row_max > 0: max(if v > 0: 0.8 else: 0.0, 100.0 * v.float / row_max.float)
      else: 0.0
    log_width = if log_max > 0: 100.0 * ln(1.0 + v.float) / ln(1.0 + log_max.float) else: 0.0
  "<div class=\"bar " & kind & "\" title=\"" & escapeHtml(tip) &
    "\"><div class=\"track\"><i style=\"--w-row:" & row_width.fixed & "%;--w-log:" &
    log_width.fixed & "%\"></i></div><span class=\"v\">" & grouped(v) & "</span></div>"


func metricOf(f: Option[Figures], is_bytes: bool): Option[int] =
  ## Read bytes or multiplies of figures; none where figures are absent.
  if f.isNone: none(int) elif is_bytes: some(f.get.bytes) else: some(f.get.multiplies)


func metricOf(b: Option[BoundFigures], is_bytes: bool): Option[int] =
  ## Read bytes or multiplies of bound; none where no rule derived.
  if b.isNone: none(int) elif is_bytes: some(b.get.bytes) else: some(b.get.multiplies)


func panel(r: Row, is_bytes: bool, log_max: int): string =
  ## Render one metric's three bars for row: library, multivector bound, typed reference.
  let
    library = metricOf(r.library, is_bytes)
    reference = metricOf(r.reference, is_bytes)
    bound =
      if r.bound.isNone: none(int)
      elif is_bytes: some(r.bound.get.bytes)
      else: some(r.bound.get.multiplies)
    row_max = max([library.get(0), bound.get(0), reference.get(0)])
    unit = if is_bytes: " bytes" else: " multiplies"
    shape = if r.bound.isSome: r.bound.get.shape else: ""
  result = "<div class=\"panel bars\">" &
    bar("library", library, row_max, log_max, "library, " & $library.get(0) & unit) &
    bar("bound", bound, row_max, log_max, "multivector lower bound, " & shape)
  if not r.is_general:
    result.add "<div class=\"typed-only\">" &
      bar("reference", reference, row_max, log_max, "type optimised lower bound") & "</div>"
  result.add "</div>"


func detail(r: Row): string =
  ## Render row's breakdown: expression, citation, shape, and bytes by cause.
  let shape =
    if r.bound.isNone: "no derived shape"
    elif r.bound.get.is_composed: "composed: " & r.bound.get.steps.join(" → ")
    else: r.bound.get.shape
  result = "<div class=\"detail\"><p>" & code(r.expression) & " · " & escapeHtml(r.cite) &
    " · " & escapeHtml(shape) & "</p>"
  if r.library.isSome:
    let l = r.library.get
    result.add "<p>Library: " & $l.fills & " zero fills, " & $l.intermediate_count &
      " intermediates, " & $l.copies & " copies, " & $l.checks & " error checks, " &
      $l.divides & " divides, " & (if l.is_inline: "inline" else: "not inline") & ".</p>"
  result.add "<div class=\"table\"><table><tr><th>bytes</th><th>read</th><th>written</th>" &
    "<th>zero fill</th><th>intermediates</th><th>copies</th><th>total</th></tr>"
  for (name, figures, class_name) in [("library", r.library, ""),
      ("typed form", r.reference, " class=\"typed-only\"")]:
    if figures.isNone: continue
    let f = figures.get
    result.add "<tr" & class_name & "><td>" & name & "</td><td>" & grouped(f.read) & "</td><td>" &
      grouped(f.written) & "</td><td>" & grouped(f.zeroed) & "</td><td>" &
      grouped(f.intermediates) & "</td><td>" & grouped(f.copied) & "</td><td>" &
      grouped(f.bytes) & "</td></tr>"
  if r.bound.isSome:
    let b = r.bound.get
    result.add "<tr><td>multivector bound</td><td>" & grouped(b.read) & "</td><td>" &
      grouped(b.written) & "</td><td>0</td><td>0</td><td>0</td><td>" & grouped(b.bytes) &
      "</td></tr>"
  result.add "</table></div></div>"


func ranks(rows: openArray[Row], keys: openArray[float]): Table[string, int] =
  ## Rank rows by key, largest first; ties, and rows keyed below zero, in docket order.
  var keyed: seq[(float, string)]
  for i, r in rows: keyed.add (keys[i], r.id)
  keyed.sort(proc (a, b: (float, string)): int =
    if a[0] == b[0]: cmp(a[1], b[1]) else: cmp(b[0], a[0]))
  for i, (_, id) in keyed: result[id] = i


func rowHtml(r: Row, log_max: array[2, int], order: array[4, int]): string =
  ## Render one row as details: summary cells, then breakdown.
  var classes = @["row"]
  if not r.is_general: classes.add "typed"
  if r.library.isSome and r.bound.isSome and r.library.get.multiplies > r.bound.get.multiplies:
    classes.add "above"
  if r.bound.isSome and r.bound.get.is_composed: classes.add "chain"
  if r.nan_share > 0: classes.add "nan"
  var time = if r.ns_library > 0: "<b>" & r.ns_library.fixed(1) & "</b>" else: "–"
  if r.ns_library > 0 and r.ns_reference > 0:
    time.add "<span class=\"typed-only\"> / " & r.ns_reference.fixed(1) & "<br>" &
      ratioText(r.ns_library / r.ns_reference) & "</span>"
  if r.nan_share > 0: time.add chip("NaN " & $int(round(100 * r.nan_share)) & "%", "fail")
  "<details class=\"" & classes.join(" ") & "\" style=\"--o-bytes:" & $order[0] &
    ";--o-multiplies:" & $order[1] & ";--o-typed:" & $order[2] & ";--o-time:" & $order[3] &
    "\"><summary><span class=\"op\"><span class=\"n\">" & escapeHtml(r.measurand) &
    "</span><span class=\"sub\">" & escapeHtml(r.id) & " · " & escapeHtml(r.symbol) &
    "</span></span>" & panel(r, false, log_max[0]) & panel(r, true, log_max[1]) &
    "<span class=\"time\">" & time & "</span></summary>" & detail(r) & "</details>"


func factsHtml(sheet: Sheet, rows: openArray[Row]): string =
  ## Render facts for both populations; typed toggle shows one.
  let
    general = tallyOf(rows, false)
    typed = tallyOf(rows, true)
    ratios = timeRatios(rows).sorted
    fill = fillShare(sheet)
  result = "<dl class=\"facts\">"
  for (tally, class_name, noun) in [(general, "typed-off", "operations"),
      (typed, "typed-only", "measurands")]:
    result.add "<div class=\"" & class_name & "\"><dt>" & $tally.at_multiplies & "/" &
      $tally.bounded & "</dt><dd>" & noun & " at multivector bound on multiplies</dd></div>" &
      "<div class=\"" & class_name & "\"><dt>" & $tally.at_bytes & "/" & $tally.bounded &
      "</dt><dd>at it on bytes moved</dd></div>"
  result.add "<div><dt>" & $fill & "%</dt><dd>of library's modelled bytes are zero fill</dd></div>"
  if ratios.len > 0:
    result.add "<div class=\"typed-only\"><dt>" & ratioText(ratios[ratios.len div 2]) &
      "</dt><dd>median time against typed form, worst " & ratioText(ratios[^1]) & "</dd></div>"
  result.add "</dl>"
  let sums = [(general, "typed-off"), (typed, "typed-only")]
  result.add "<div class=\"aggregate\">"
  for (label, index) in [("Multiplies, summed", 0), ("Bytes moved, summed", 1)]:
    for (tally, class_name) in sums:
      let top = max([tally.sums_library[index], tally.sums_bound[index],
        tally.sums_reference[index]])
      result.add "<div class=\"" & class_name & "\"><h4>" & label & "</h4><div class=\"bars\">" &
        bar("library", some(tally.sums_library[index]), top, top, "library") &
        bar("bound", some(tally.sums_bound[index]), top, top, "multivector lower bound")
      if class_name == "typed-only":
        result.add bar("reference", some(tally.sums_reference[index]), top, top,
          "type optimised lower bound")
      result.add "</div><p class=\"caption\">" & $tally.full & " " &
        (if class_name == "typed-only": "measurands with all three" else: "operations") &
        ".</p></div>"
  result.add "</div>"


func parity(sheet: Sheet, overlay: JsonNode, is_typed: bool): (int, int, int) =
  ## Count rows at bound on multiplies and on bytes, with overlay's functions in place.
  var n, at_multiplies, at_bytes: int
  let functions = sheet.static_measurements{"functions"}
  for id, m in sheet.static_measurements{"measurands"}.pairs:
    if not is_typed and m{"reference"}.getStr.len > 0: continue
    let
      key = m{"library"}.getStr
      b = m{"bound"}
    if b.isNil or key.len == 0 or not functions.hasKey(key): continue
    var f = functions[key]
    if not overlay.isNil and overlay.hasKey(key):
      let after = overlay[key]{"after"}
      if after.isNil or after.kind != JObject: continue
      f = %*{"total": after, "movement": after}
    inc n
    if f{"total", "multiplies"}.getInt <= b{"multiplies"}.getInt: inc at_multiplies
    if f{"movement", "bytes_moved"}.getInt <= b{"bytes_moved"}.getInt: inc at_bytes
  (n, at_multiplies, at_bytes)


func designsHtml(sheets: openArray[Sheet], overlays: openArray[Overlay]): string =
  ## Render how far each design moves parity with multivector bound.
  if overlays.len == 0: return ""
  result = "<section class=\"block\"><h2>Designs against the bound</h2><p class=\"note\">" &
    "Each design's trial replaces the functions it changes; the rest stay as baselines hold " &
    "them.</p><div class=\"table\"><table><tr><th>Design</th><th>Algebra</th>" &
    "<th>At bound on multiplies, now → design</th><th>At bound on bytes</th></tr>"
  for o in overlays:
    for sheet in sheets:
      if sheet.name notin o.functions: continue
      let
        now = parity(sheet, nil, false)
        after = parity(sheet, o.functions[sheet.name], false)
        title = if o.url.len > 0: "<a href=\"" & escapeHtml(o.url) & "\">" & escapeHtml(o.title) &
          "</a>" else: escapeHtml(o.title)
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
<label><input type="radio" name="show" id="show-chain"> composed</label>
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
composed operation: multiplies sum steps of its definition, an estimate</pre>
<p class="note">Bytes are modelled from the C, not measured. They rank two versions of one
operation, and do not predict time across different operations. Inspect one yourself with
<code>nim r tools/build.nim show ∧</code>.</p></details></section>"""
    ## Method, same for every algebra.


func above(a, b: Option[int]): float =
  ## Read how far first value stands above second, as ratio of both plus one; below zero
  ##   where either is absent, so such row sorts last.
  if a.isNone or b.isNone: -1.0 else: (a.get + 1).float / (b.get + 1).float


func docketBody*(
  sheets: openArray[Sheet], ids: JsonNode, overlays: openArray[Overlay], pin, links: string
): string =
  ## Render docket body: header, one tab per algebra, designs against bound, method.
  let taken = sheets[0].runtime_measurements{"taken"}
  result = "<div class=\"page\"><header><h1>PGA Gap Docket</h1><p class=\"meta\">pga " &
    code(pin[0 ..< 7]) & " · time " & escapeHtml(taken{"date"}.getStr) & ", " &
    escapeHtml(taken{"machine"}.getStr) & " · counts read from emitted C, exact" & links &
    "</p><label class=\"toggle\"><input type=\"checkbox\" id=\"typed\"> typed target</label>" &
    "</header><nav class=\"tabs\" aria-label=\"Algebra\">"
  for i, sheet in sheets:
    result.add "<label><input type=\"radio\" name=\"algebra\" id=\"algebra-" & sheet.name & "\"" &
      (if i == 0: " checked" else: "") & "> " & sheet.title & "</label>"
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
  for s, sheet in sheets:
    let rows = every[s]
    var
      log_max: array[2, int]
      by_bytes, by_multiplies, by_typed, by_time: seq[float]
    for r in rows:
      for index, is_bytes in [false, true]:
        log_max[index] = max([log_max[index], metricOf(r.library, is_bytes).get(0),
          metricOf(r.bound, is_bytes).get(0)])
      by_bytes.add above(metricOf(r.library, true), metricOf(r.bound, true))
      by_multiplies.add above(metricOf(r.library, false), metricOf(r.bound, false))
      by_typed.add above(metricOf(r.library, true), metricOf(r.reference, true))
      by_time.add(if r.ns_reference > 0: r.ns_library / r.ns_reference else: -1.0)
    let order = [ranks(rows, by_bytes), ranks(rows, by_multiplies), ranks(rows, by_typed),
      ranks(rows, by_time)]
    result.add "<section class=\"algebra algebra-" & sheet.name & "\"><div class=\"rows\">"
    for r in rows:
      result.add rowHtml(r, log_max, [order[0][r.id], order[1][r.id], order[2][r.id],
        order[3][r.id]])
    result.add "</div></section>"
  result.add designsHtml(sheets, overlays) & METHOD & "</div>"
