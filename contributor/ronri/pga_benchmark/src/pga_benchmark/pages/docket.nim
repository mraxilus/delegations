## Render gap docket: every measurand at pin against both lower bounds, one tab per algebra.
##   Docket is monitoring page: what library spends now, read from committed baselines, and how
##     far each measurand sits from multivector lower bound and type optimised lower bound. It
##     shows nothing baselines do not hold, so it is current exactly when they are.
##   Each measure of row is one deviation bar: library over what it is measured against, on one
##     log axis whole page shares, so ×1 is at that and length reads as factor. Typed row is
##     measured against reference, and its count bars tick multivector lower bound. General row
##     counts against multivector lower bound, and times against dense form (`dense.nim`).
##     Time bar ends at median of run ratios, and each run is one tick on it.
##   Proposals close on it: each proposal's evaluation overlays its changed functions, and docket
##     counts how many measurands would then stand at bound.
##   Rows carry CSS hooks rather than script: class per filter, custom property per sort key.
##     Dropdowns name them, and `:has()` rules body generates read chosen option, so one list
##     here spells option and rule alike. Search box is only script: row hides while its words
##     lack any word typed, as Architect chose at cost of script.
##
##   Cost: every row renders once per page whatever filter reader picks; 150 rows of four
##     algebras stay under one megabyte.

{.experimental: "strictFuncs".}

import std/[algorithm, json, math, options, sequtils, strutils, tables]

import ../markdown
import ./shell
from ../gaps import TOLERANCE
from ../report import isLibraryModule, median


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
    operation: string
      ## Operation measurand applies: own id on general row, id less its operand kinds on typed.
    operands: seq[string]
      ## Operand kinds of typed row as id spells them, as `round_point`; empty on general row.
    is_general: bool
    library, reference, dense: Option[Figures]
    bound: Option[BoundFigures]
    ns_library, ns_against, share_nan: float
      ## Library time, and time of what row is timed against.
      ##   Typed row is timed against reference, and general row against dense form.
    ns_runs_library, ns_runs_against: seq[float]
      ## Median of each run, in run order, paired by index.
  Axis = object
    ## Define log axis every deviation bar on page shares: whole powers of two, low to high.
    exponent_low, exponent_high: int
  Deviation = object
    ## Define one deviation bar: library over lower bound it is measured against, and its marks.
    name_measure: string
      ## Measure bar shows: multiplies, bytes or time.
    ratio: float
      ## Library over lower bound; zero where none reads.
    is_over_zero: bool
      ## Lower bound is zero and library spends above it, so bar runs to axis end.
    tick: float
      ## Where multivector lower bound stands, as ratio; zero where none is marked.
    runs: seq[float]
      ## Ratio of each run, in run order; empty where runs are not recorded.
    label, tip: string
      ## Text beside bar, and text on hover.
  Tally = object
    ## Define counts of one population of rows against bound.
    bounded, at_multiplies, at_bytes, chains: int
    sums_library, sums_bound, sums_reference: array[2, int]
    full: int
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


const
  KINDS = ["point", "line", "plane", "motor", "flector", "round_point", "dipole", "circle",
    "sphere", "flat_point", "flat_line", "flat_plane", "scalar"]
    ## Operand kinds as typed measurand's id spells them, in order operand dropdown lists them.
  SORTS = [("bytes", "bytes moved, furthest over lower bound"),
    ("multiplies", "multiplies, furthest over lower bound"), ("time", "time ratio, greatest"),
    ("spread", "spread of run ratios, widest"), ("divides", "divides, most"),
    ("checks", "error checks, most")]
    ## Sort key and its option; row's rank under key is custom property `--o-<key>`.
  SHOWS = [("over", "over on any measure", false),
    ("over-multiplies", "over lower bound on multiplies", false),
    ("over-bytes", "over lower bound on bytes moved", false),
    ("over-time", "time over " & ratioText(TOLERANCE), false),
    ("at-bound", "at lower bound on both counts", false), ("chain", "chains", false),
    ("checks", "with error checks", false), ("fills", "with zero fills", false),
    ("nan", "returns NaN", false), ("typed", "typed measurands only", true)]
    ## Row class, its option, and whether option shows only beside typed measurands.



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

  func runsOf(timing: JsonNode): seq[float] =
    ## Read median of each run in run order; empty where runs are not recorded.
    timing{"ns_runs"}.getElems.mapIt(it.getFloat)

  func split(id: string, count_operands: int): (string, seq[string]) =
    ## Split typed measurand's id into operation and operand kinds, as catalogue joins them.
    ##   One kind per operand, last first, longest kind where two end id alike.
    result[0] = id
    for _ in 1 .. count_operands:
      var kind = ""
      for candidate in KINDS:
        if result[0].endsWith("_" & candidate) and candidate.len > kind.len: kind = candidate
      if kind.len == 0: break
      result[0].setLen(result[0].len - kind.len - 1)
      result[1].insert(kind, 0)

  let
    width = 8 shl sheet.dimensions
    functions = sheet.measurements_static{"functions"}
    timings = sheet.measurements_runtime{"measurands"}
  for id, measurand in sheet.measurements_static{"measurands"}.pairs:
    let
      key_library = measurand{"library"}.getStr
      key_reference = measurand{"reference"}.getStr
      key_dense = measurand{"dense"}.getStr
      timing = timings{id}
      timing_library = if timing.isNil: nil else: timing{"library"}
      timing_against =
        if timing.isNil: nil
        elif key_reference.len > 0: timing{"reference"}
        else: timing{"dense"}
      is_timed_library = not timing_library.isNil and timing_library.kind == JObject
      is_timed_against = not timing_against.isNil and timing_against.kind == JObject
      (operation, operands) =
        if key_reference.len == 0: (id, newSeq[string]())
        else: split(id, measurand{"arity"}.getInt(2))
    result.add Row(
      id: ids{"ids", sheet.name & "/" & id}.getStr,
      measurand: id,
      symbol: measurand{"symbol"}.getStr,
      expression: measurand{"expression"}.getStr,
      cite: measurand{"cite"}.getStr,
      operation: operation,
      operands: operands,
      is_general: key_reference.len == 0,
      library: figuresOf(functions{key_library}),
      reference:
        if key_reference.len == 0: none(Figures) else: figuresOf(functions{key_reference}),
      dense: if key_dense.len == 0: none(Figures) else: figuresOf(functions{key_dense}),
      bound: boundOf(measurand{"bound"}, width),
      ns_library: if is_timed_library: timing_library{"ns_median"}.getFloat else: 0.0,
      ns_against: if is_timed_against: timing_against{"ns_median"}.getFloat else: 0.0,
      share_nan: if is_timed_library: timing_library{"nan_share"}.getFloat else: 0.0,
      ns_runs_library: if is_timed_library: runsOf(timing_library) else: @[],
      ns_runs_against: if is_timed_against: runsOf(timing_against) else: @[],
    )
  result.sort(proc (left, right: Row): int = cmp(left.id, right.id))



#[ Ratios ]#

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


func targetOf(row: Row, is_bytes: bool): (Option[int], string) =
  ## Read what row's count is measured against, with its name.
  ##   Reference on typed row that carries one, multivector lower bound else.
  if not row.is_general and row.reference.isSome:
    (metricOf(row.reference, is_bytes), "reference")
  else:
    (metricOf(row.bound, is_bytes), "multivector lower bound")


func ratioCount(row: Row, is_bytes: bool): float =
  ## Read library over what row's count is measured against.
  ##   One where both are zero.
  ##   Zero where either is absent or only lower bound is zero, so no ratio reads.
  let
    library = metricOf(row.library, is_bytes)
    target = targetOf(row, is_bytes)[0]
  if library.isNone or target.isNone: 0.0
  elif target.get > 0: library.get / target.get
  elif library.get == 0: 1.0
  else: 0.0


func ratiosRuns(row: Row): seq[float] =
  ## Read library time over what row is timed against, run by run.
  ##   Runs pair by index, since one run times both.
  ##   Empty where runs are not recorded on both.
  if row.ns_runs_library.len != row.ns_runs_against.len: return
  for index, ns in row.ns_runs_library:
    if ns > 0 and row.ns_runs_against[index] > 0: result.add ns / row.ns_runs_against[index]


func ratioTime(row: Row): float =
  ## Read library time over what row is timed against.
  ##   Median of run ratios, or ratio of medians where runs are not recorded.
  ##   Zero where either is untimed.
  if row.ns_library <= 0 or row.ns_against <= 0: return 0.0
  let ratios = row.ratiosRuns
  if ratios.len > 0: median(ratios) else: row.ns_library / row.ns_against


func positionOf(axis: Axis, ratio: float): float =
  ## Read where ratio sits on axis, in percent of its width, clamped to axis.
  let span = float(axis.exponent_high - axis.exponent_low)
  clamp(100.0 * (log2(ratio) - axis.exponent_low.float) / span, 0.0, 100.0)



#[ Facts ]#

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
      if not function{"module"}.getStr.isLibraryModule: continue
      total += function{"movement", "bytes_moved"}.getInt
      zeroed += function{"movement", "bytes_zeroed"}.getInt
    if total == 0: 0 else: int(round(100.0 * zeroed.float / total.float))

  func bar(kind: string; amount, top: int; tip: string): string =
    ## Render one summed bar: width against greatest of its group, value, tip.
    let width =
      if top > 0: max(if amount > 0: 0.8 else: 0.0, 100.0 * amount.float / top.float) else: 0.0
    "<div class=\"bar " & kind & "\" title=\"" & escapeHtml(tip) &
      "\"><div class=\"track\"><i style=\"width:" & width.fixed & "%\"></i></div>" &
      "<span class=\"v\">" & grouped(amount) & "</span></div>"

  let
    general = tallyOf(rows, false)
    typed = tallyOf(rows, true)
    ratios_general = rows.filterIt(it.is_general).mapIt(it.ratioTime).filterIt(it > 0).sorted
    ratios_typed = rows.filterIt(not it.is_general).mapIt(it.ratioTime).filterIt(it > 0).sorted
    fill = fillShare(sheet)
  result = "<dl class=\"facts\">"
  for (tally, name_class, noun) in [(general, "typed-off", "operations"),
      (typed, "typed-only", "measurands")]:
    result.add "<div class=\"" & name_class & "\"><dt>" & $tally.at_multiplies & "/" &
      $tally.bounded & "</dt><dd>" & noun & " at multivector bound on multiplies</dd></div>" &
      "<div class=\"" & name_class & "\"><dt>" & $tally.at_bytes & "/" & $tally.bounded &
      "</dt><dd>at it on bytes moved</dd></div>"
  result.add "<div><dt>" & $fill & "%</dt><dd>of library's modelled bytes are zero fill</dd></div>"
  for (ratios, name_class, against) in [(ratios_general, "typed-off", "dense form"),
      (ratios_typed, "typed-only", "reference")]:
    if ratios.len == 0: continue
    result.add "<div class=\"" & name_class & "\"><dt>" & ratioText(ratios[ratios.len div 2]) &
      "</dt><dd>median time over " & against & ", worst " & ratioText(ratios[^1]) & "</dd></div>"
  result.add "</dl>"
  let sums = [(general, "typed-off"), (typed, "typed-only")]
  result.add "<div class=\"aggregate\"><div class=\"legend\"><span class=\"library\">library " &
    "now</span><span class=\"bound\">multivector lower bound</span><span class=\"reference " &
    "typed-only\">reference</span></div>"
  for (label, index) in [("Multiplies, summed", 0), ("Bytes moved, summed", 1)]:
    for (tally, name_class) in sums:
      let top = max([tally.sums_library[index], tally.sums_bound[index],
        tally.sums_reference[index]])
      result.add "<div class=\"" & name_class & "\"><h4>" & label & "</h4><div class=\"bars\">" &
        bar("library", tally.sums_library[index], top, "library") &
        bar("bound", tally.sums_bound[index], top, "multivector lower bound")
      if name_class == "typed-only":
        result.add bar("reference", tally.sums_reference[index], top, "reference")
      result.add "</div><p class=\"caption\">" & $tally.full & " " &
        (if name_class == "typed-only": "measurands with all three" else: "operations") &
        ".</p></div>"
  result.add "</div>"



#[ Rows ]#

func rowHtml(row: Row, axis: Axis, order: array[SORTS.len, int]): string =
  ## Render one row as details: one deviation bar per measure, then breakdown.
  ##   Classes name every filter row passes, and custom properties its rank under every sort.

  func countDeviation(row: Row, is_bytes: bool): Deviation =
    ## Read deviation of one count: ratio, or excess where lower bound is zero.
    ##   Tick sits at multivector lower bound where typed row is measured against reference.
    let
      unit = if is_bytes: " bytes" else: " multiplies"
      library = metricOf(row.library, is_bytes)
      (target, name_target) = targetOf(row, is_bytes)
      bound = metricOf(row.bound, is_bytes)
    result.name_measure = if is_bytes: "bytes" else: "multiplies"
    if library.isNone:
      result.label = "none"
      result.tip = "no library function: expression calls several"
      return
    if target.isNone:
      result.label = "none"
      result.tip = "library " & grouped(library.get) & unit & "; nothing derived to measure against"
      return
    result.tip = "library " & grouped(library.get) & unit & ", " & name_target & " " &
      grouped(target.get)
    if name_target == "reference" and bound.isSome:
      result.tip.add ", multivector lower bound " & grouped(bound.get)
      if bound.get > 0 and target.get > 0: result.tick = bound.get / target.get
    if target.get == 0 and library.get > 0:
      result.is_over_zero = true
      result.label = grouped(library.get) & " over 0"
    else:
      result.ratio = row.ratioCount(is_bytes)
      result.label = ratioText(result.ratio)

  func timeDeviation(row: Row): Deviation =
    ## Read deviation of time, with each run's ratio.
    ##   Ratio is median run ratio over reference on typed row, and over dense form on general.
    ##   Nanoseconds alone where nothing else is timed.
    result.name_measure = "time"
    if row.ns_library <= 0:
      result.label = "untimed"
      result.tip = "no runtime measurement"
      return
    result.tip = "library " & row.ns_library.fixed(1) & " ns"
    let ratio = row.ratioTime
    if ratio == 0:
      result.label = row.ns_library.fixed(1) & " ns"
      return
    let ratios = row.ratiosRuns
    result.ratio = ratio
    result.label = ratioText(ratio)
    result.tip.add ", " & (if row.is_general: "dense form " else: "reference ") &
      row.ns_against.fixed(1) & " ns"
    if ratios.len > 1:
      result.runs = ratios
      result.tip.add ", runs " & ratios.mapIt(ratioText(it)).join(" ")

  func deviationHtml(deviation: Deviation, axis: Axis): string =
    ## Render one deviation bar on shared axis.
    ##   Bar runs from ×1, tick sits at multivector lower bound, and one tick marks each run.
    ##   Bare label where no ratio reads.
    let origin = axis.positionOf(1.0)
    var marks: string
    if deviation.is_over_zero:
      marks.add "<i class=\"open\" style=\"left:" & origin.fixed & "%;width:" &
        (100.0 - origin).fixed & "%\"></i>"
    elif deviation.ratio > 0:
      let at = axis.positionOf(deviation.ratio)
      marks.add "<i" & (if deviation.ratio < 1.0: " class=\"below\"" else: "") & " style=\"left:" &
        min(origin, at).fixed & "%;width:" & abs(at - origin).fixed & "%\"></i>"
    if deviation.tick > 0:
      marks.add "<b style=\"left:" & axis.positionOf(deviation.tick).fixed & "%\"></b>"
    for run in deviation.runs:
      marks.add "<s style=\"left:" & axis.positionOf(run).fixed & "%\"></s>"
    let
      is_bare = deviation.ratio == 0 and not deviation.is_over_zero
      name = if deviation.name_measure == "bytes": "bytes moved" else: deviation.name_measure
    "<div class=\"deviation " & deviation.name_measure & (if is_bare: " bare" else: "") &
      "\" title=\"" & escapeHtml(deviation.tip) & "\"><span class=\"k\">" & name &
      "</span><div class=\"axis\">" & marks & "</div><span class=\"v\">" &
      escapeHtml(deviation.label) & "</span></div>"

  func detail(row: Row): string =
    ## Render row's breakdown: expression, citation, shape, time, and counts by cause.
    ##   Dense form stands beside library on general row, as reference does on typed one.
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
    if row.ns_library > 0:
      result.add "<p>Time, median of " & $max(1, row.ns_runs_library.len) & " runs: library " &
        row.ns_library.fixed(1) & " ns"
      if row.ns_against > 0:
        result.add (if row.is_general: ", dense form " else: ", reference ") &
          row.ns_against.fixed(1) & " ns"
      result.add ".</p>"
    result.add "<div class=\"table\"><table><tr><th></th><th>multiplies</th><th>bytes read</th>" &
      "<th>written</th><th>zero fill</th><th>intermediates</th><th>copies</th>" &
      "<th>bytes moved</th></tr>"
    for (name, side, name_class) in [("library", row.library, ""),
        ("reference", row.reference, " class=\"typed-only\""), ("dense form", row.dense, "")]:
      if side.isNone: continue
      let figures = side.get
      result.add "<tr" & name_class & "><td>" & name & "</td><td>" & grouped(figures.multiplies) &
        "</td><td>" & grouped(figures.read) & "</td><td>" & grouped(figures.written) &
        "</td><td>" & grouped(figures.zeroed) & "</td><td>" & grouped(figures.intermediates) &
        "</td><td>" & grouped(figures.copied) & "</td><td>" & grouped(figures.bytes) & "</td></tr>"
    if row.bound.isSome:
      let bound = row.bound.get
      result.add "<tr><td>multivector lower bound</td><td>" & grouped(bound.multiplies) &
        "</td><td>" & grouped(bound.read) & "</td><td>" & grouped(bound.written) &
        "</td><td>0</td><td>0</td><td>0</td><td>" & grouped(bound.bytes) & "</td></tr>"
    result.add "</table></div></div>"

  var
    classes = @["row", "operation-" & row.operation] &
      row.operands.deduplicate.mapIt("operand-" & it)
    is_at_bound = true
  if not row.is_general: classes.add "typed"
  for (is_bytes, name_class) in [(false, "over-multiplies"), (true, "over-bytes")]:
    let
      library = metricOf(row.library, is_bytes)
      target = targetOf(row, is_bytes)[0]
    if library.isNone or target.isNone: is_at_bound = false
    elif library.get > target.get:
      is_at_bound = false
      classes.add name_class
  if row.ratioTime > TOLERANCE: classes.add "over-time"
  if classes.anyIt(it.startsWith("over-")): classes.add "over"
  if is_at_bound: classes.add "at-bound"
  if row.bound.isSome and row.bound.get.is_chain: classes.add "chain"
  if row.library.isSome and row.library.get.checks > 0: classes.add "checks"
  if row.library.isSome and row.library.get.fills > 0: classes.add "fills"
  if row.share_nan > 0: classes.add "nan"
  var ranks: seq[string]
  for index, (key, _) in SORTS: ranks.add "--o-" & key & ":" & $order[index]
  let
    nan =
      if row.share_nan > 0: chip("NaN " & $int(round(100 * row.share_nan)) & "%", "fail") else: ""
    words = (@[row.measurand, row.id, row.symbol, row.operation.replace('_', ' '),
      row.expression] & row.operands.mapIt(it.replace('_', ' '))).filterIt(it.len > 0)
  "<details class=\"" & classes.join(" ") & "\" style=\"" & ranks.join(";") &
    "\" data-find=\"" & escapeHtml(words.join(" ").toLowerAscii) &
    "\"><summary><span class=\"op\">" &
    "<span class=\"n\">" & escapeHtml(row.measurand) & "</span><span class=\"sub\">" &
    escapeHtml(row.id) & " · " & escapeHtml(row.symbol) & "</span>" & nan & "</span>" &
    deviationHtml(countDeviation(row, false), axis) &
    deviationHtml(countDeviation(row, true), axis) & deviationHtml(timeDeviation(row), axis) &
    "</summary>" & detail(row) & "</details>"



#[ Page ]#

func proposalsHtml(sheets: openArray[Sheet], overlays: openArray[Overlay]): string =
  ## Render how far each proposal moves parity with multivector bound.

  func parity(sheet: Sheet, overlay: JsonNode, is_typed: bool): (int, int, int) =
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
  LEGEND = """<div class="legend"><span class="mark-bar">library over what it is measured
against, log scale</span><span class="mark-origin typed-off">×1: multivector lower bound for
counts, dense form for time</span><span class="mark-origin typed-only">×1: reference on typed
rows; multivector lower bound and dense form on general ones</span><span class="mark-tick
typed-only">multivector lower bound</span><span class="mark-runs">each run</span></div>"""
    ## Legend of deviation bars, same for every algebra.
  FIND = """<script>
const find = document.getElementById("find");
const filter = () => {
  const words = find.value.toLowerCase().split(/\s+/).filter(Boolean);
  for (const row of document.querySelectorAll("details.row"))
    row.classList.toggle("unfound", !words.every((word) => row.dataset.find.includes(word)));
};
find.addEventListener("input", filter);
filter();
</script>"""
    ## Script of search box, page's only one: row shows while its words hold every word typed.
    ##   Runs once at load too, since browser may restore typed text.
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
chain: multiplies sum steps of its definition, an estimate

bar           = library ÷ what row is measured against, log scale
                typed row: reference, tick at multivector lower bound
                general row: multivector lower bound, and dense form for time
time          = median over runs of library ÷ that, within each run
                one tick at each run's ratio

dense form    = each slot once, as sum of terms library's tables keep: no fill,
                no intermediate, no call; operand already a product binds scalars</pre>
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
  ## Render docket body: header, one tab per algebra, controls, proposals against bound, method.

  func keysOf(row: Row): array[SORTS.len, float] =
    ## Read row's key under every sort, in order of `SORTS`.
    ##   Below zero where row has none, so such row sorts last.

    func above(value, base: Option[int]): float =
      ## Read how far value stands above base, as ratio of both plus one.
      ##   Below zero where either is absent.
      if value.isNone or base.isNone: -1.0 else: (value.get + 1).float / (base.get + 1).float

    let runs = row.ratiosRuns
    [above(metricOf(row.library, true), targetOf(row, true)[0]),
      above(metricOf(row.library, false), targetOf(row, false)[0]),
      (if row.ratioTime > 0: row.ratioTime else: -1.0),
      (if runs.len > 1: max(runs) / min(runs) else: -1.0),
      (if row.library.isSome: row.library.get.divides.float else: -1.0),
      (if row.library.isSome: row.library.get.checks.float else: -1.0)]

  func ranks(rows: openArray[Row], keys: openArray[float]): Table[string, int] =
    ## Rank rows by key, largest first; ties, and rows keyed below zero, in docket order.
    var keyed: seq[(float, string)]
    for index, row in rows: keyed.add (keys[index], row.id)
    keyed.sort(proc (left, right: (float, string)): int =
      if left[0] == right[0]: cmp(left[1], right[1]) else: cmp(right[0], left[0]))
    for rank, (_, id) in keyed: result[id] = rank

  func axisOf(every: openArray[seq[Row]]): Axis =
    ## Fit axis to every ratio on page: ×1 inside, whole powers of two, ×1/8 to ×1024 at most.
    var low, high = 0.0
    for rows in every:
      for row in rows:
        for ratio in @[row.ratioCount(false), row.ratioCount(true), row.ratioTime] &
            row.ratiosRuns:
          if ratio <= 0: continue
          low = min(low, log2(ratio))
          high = max(high, log2(ratio))
    Axis(exponent_low: clamp(floor(low).int, -3, -1), exponent_high: clamp(ceil(high).int, 1, 10))

  func controlsOf(sheets: openArray[Sheet], every: openArray[seq[Row]]): (string, string) =
    ## Render legend and four dropdowns, with `:has()` rules that read them.
    ##   Dropdowns are sort, show, operation and operand.
    ##   Option of last two carries class of each algebra it matches, so rule hides it on others.
    ##   Operation no general row applies shows beside typed ones alone.
    ##   Operand filter holds only while typed measurands show, since its dropdown hides else.

    func option(value, label: string; classes: seq[string]; is_selected = false): string =
      ## Render one option, with its classes and whether it is chosen at rest.
      "<option value=\"" & value & "\"" &
        (if classes.len > 0: " class=\"" & classes.join(" ") & "\"" else: "") &
        (if is_selected: " selected" else: "") & ">" & escapeHtml(label) & "</option>"

    var
      operations: Table[string, tuple[symbol: string, algebras: seq[string], is_general: bool]]
      kinds: Table[string, seq[string]]
    for index, sheet in sheets:
      for row in every[index]:
        let key = row.operation
        if key notin operations: operations[key] = ("", newSeq[string](), false)
        if operations[key].symbol.len == 0: operations[key].symbol = row.symbol
        if row.is_general: operations[key].is_general = true
        if sheet.name notin operations[key].algebras: operations[key].algebras.add sheet.name
        for kind in row.operands:
          if sheet.name notin kinds.mgetOrPut(kind, @[]): kinds[kind].add sheet.name
    let names_operation = operations.keys.toSeq.sorted
    var html = "<div class=\"controls\">" & LEGEND & "<label class=\"control\">Find <input " &
      "type=\"search\" id=\"find\" placeholder=\"wedge, ∧, G060\" autocomplete=\"off\">" &
      "</label><label class=\"control\">Sort <select id=\"sort\">"
    for index, (key, label) in SORTS: html.add option(key, label, @[], index == 0)
    html.add option("docket", "docket order", @[]) & "</select></label><label " &
      "class=\"control\">Show <select id=\"show\">" & option("all", "all measurands", @[], true)
    for (name_class, label, is_typed_only) in SHOWS:
      html.add option(name_class, label, if is_typed_only: @["typed-only"] else: @[])
    html.add "</select></label><label class=\"control\">Operation <select id=\"operation\">" &
      option("all", "every operation", @[], true)
    for name in names_operation:
      let entry = operations[name]
      html.add option(name, strip(name & " " & entry.symbol), entry.algebras.mapIt("in-" & it) &
        (if entry.is_general: @[] else: @["typed-only"]))
    html.add "</select></label><label class=\"control typed-only\">Operand <select " &
      "id=\"operand\">" & option("all", "any operand", @[], true)
    for kind in KINDS:
      if kind in kinds: html.add option(kind, kind.replace('_', ' '), kinds[kind].mapIt("in-" & it))
    html.add "</select></label></div>"
    var rules: string
    for (key, _) in SORTS:
      rules.add "body:has(#sort option[value=\"" & key & "\"]:checked) details.row { order: " &
        "var(--o-" & key & "); }\n"
    for (name_class, _, _) in SHOWS:
      rules.add "body:has(#show option[value=\"" & name_class & "\"]:checked) " &
        "details.row:not(." & name_class & ") { display: none; }\n"
    for name in names_operation:
      rules.add "body:has(#operation option[value=\"" & name & "\"]:checked) " &
        "details.row:not(.operation-" & name & ") { display: none; }\n"
    for kind in KINDS:
      if kind notin kinds: continue
      rules.add "body:has(#typed:checked):has(#operand option[value=\"" & kind & "\"]:checked) " &
        "details.row:not(.operand-" & kind & ") { display: none; }\n"
    for sheet in sheets:
      rules.add "body:has(#algebra-" & sheet.name & ":checked) :is(#operation, #operand) " &
        "option:not(.in-" & sheet.name & ", [value=\"all\"]) { display: none; }\n"
    (html, rules)

  func headHtml(axis: Axis): string =
    ## Render column heads: each measure named over labels of shared axis at powers of two.

    func scale(axis: Axis, name_class: string): string =
      ## Render labels of axis, every octave or every other where octaves are many.
      ##   Label off every fourth octave is minor, which narrow screen hides.
      let step = if axis.exponent_high - axis.exponent_low > 6: 2 else: 1
      result = "<span class=\"scale" & name_class & "\">"
      for exponent in axis.exponent_low .. axis.exponent_high:
        if exponent mod step != 0: continue
        let label =
          case exponent
          of -1: "×½"
          of -2: "×¼"
          else: (if exponent < 0: "×1/" & $(1 shl -exponent) else: "×" & $(1 shl exponent))
        result.add "<i" & (if exponent mod 4 != 0: " class=\"minor\"" else: "") & " style=\"left:" &
          axis.positionOf(pow(2.0, exponent.float)).fixed & "%\">" & label & "</i>"
      result.add "</span>"

    "<div class=\"head\" aria-hidden=\"true\"><span>Operation</span>" &
      "<span class=\"deviation-head\"><span class=\"name\">Multiplies</span>" & scale(axis, "") &
      "</span><span class=\"deviation-head\"><span class=\"name\">Bytes moved</span>" &
      scale(axis, "") & "</span><span class=\"deviation-head\"><span class=\"name\">Time</span>" &
      scale(axis, "") & "</span></div>"

  var every: seq[seq[Row]]
  for sheet in sheets: every.add rowsOf(sheet, ids)
  let
    axis = axisOf(every)
    taken = sheets[0].measurements_runtime{"taken"}
    count_runs = taken{"runs"}.getInt(1)
  result = "<div class=\"page\" style=\"--origin:" & axis.positionOf(1.0).fixed & "%;--octaves:" &
    $(axis.exponent_high - axis.exponent_low) & "\"><header><h1>PGA Gap Docket</h1>" &
    "<p class=\"meta\">pga " & code(pin[0 ..< 7]) & " · time " & escapeHtml(taken{"date"}.getStr) &
    ", " & escapeHtml(taken{"machine"}.getStr) &
    (if count_runs > 1: ", median of " & $count_runs & " runs" else: "") &
    " · counts read from emitted C, exact" & links & "</p><label class=\"toggle\"><input " &
    "type=\"checkbox\" id=\"typed\"> typed measurands</label></header><nav class=\"tabs\" " &
    "aria-label=\"Algebra\">"
  for index, sheet in sheets:
    result.add "<label><input type=\"radio\" name=\"algebra\" id=\"algebra-" & sheet.name & "\"" &
      (if index == 0: " checked" else: "") & "> " & sheet.title & "</label>"
  result.add "</nav>"
  let (controls, rules_controls) = controlsOf(sheets, every)
  var rules = "<style>"
  for sheet in sheets:
    rules.add "body:has(#algebra-" & sheet.name & ":checked) .algebra:not(.algebra-" & sheet.name &
      ") { display: none; }\n"
  result.add rules & rules_controls & "</style>"
  for index, sheet in sheets:
    result.add "<section class=\"algebra algebra-" & sheet.name & "\"><div class=\"summary\">" &
      factsHtml(sheet, every[index]) & "</div></section>"
  result.add controls & headHtml(axis)
  for index, sheet in sheets:
    let
      rows = every[index]
      keys = rows.mapIt(keysOf(it))
    var order: array[SORTS.len, Table[string, int]]
    for index_sort in 0 ..< SORTS.len: order[index_sort] = ranks(rows, keys.mapIt(it[index_sort]))
    result.add "<section class=\"algebra algebra-" & sheet.name & "\"><div class=\"rows\">"
    for row in rows:
      var ranks_row: array[SORTS.len, int]
      for index_sort in 0 ..< SORTS.len: ranks_row[index_sort] = order[index_sort][row.id]
      result.add rowHtml(row, axis, ranks_row)
    result.add "</div></section>"
  result.add proposalsHtml(sheets, overlays) & METHOD & "</div>" & FIND
