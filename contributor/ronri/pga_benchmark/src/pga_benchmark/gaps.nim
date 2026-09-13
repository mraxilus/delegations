## Generate gap list from committed baselines: one row per probe per algebra, design gaps first.
##   Row is decided against reference where one exists and against zero where target is
##   absolute (zero fills, temporaries, checks, allocations, NaN share); time opens beyond
##   `TIME_BAND`, since medians on shared machine wander. Identifiers come from register,
##   which allots next number to any new key and reuses none, so `G017` names same gap in
##   every regeneration and every conversation about it.
##   Design gaps are data: each carries rule deciding it from documents and sentence saying
##   what closes it, so list closes by measurement and never by edit.
##
##   Cost: renders markdown with every line under `WIDTH` runes, wrapping prose and refusing
##     table row that does not fit, since product is committed and form-checked.
##   Cost: probe naming no library function (composed sandwich) has no counts; its row rests
##     on timing and reads `unmeasured` until bench is recorded.

{.experimental: "strictFuncs".}

import std/[algorithm, json, options, sequtils, strutils, tables, unicode]

import ./report


const
  TIME_BAND* = 1.25
    ## Factor library median may exceed reference median by before row opens on time.
  WIDTH* = 100
    ## Runes per line rendered list stays within, since form check reads it.
  KIND_REGISTER = "register"
    ## Document kind of register file.


type
  Status* {.pure.} = enum
    ## Define verdict of one row or design gap.
    Open, Closed, Unmeasured
  Readings* = object
    ## Define one side's figures of one row; each absent where side or instrument is absent.
    multiplies*, bytes*, zero_fills*, temporaries*, checks*, allocations*: Option[int]
      ## Counts read from emitted C; bytes are modelled movement.
    ns*, nan_share*: Option[float]
      ## Bench figures, absent where no bench is recorded.
  Row* = object
    ## Define one probe of one algebra with both sides' figures.
    key*: string
      ## `<config>/<probe id>`, register key.
    id*: string
      ## Register identifier, e.g. `G017`.
    config*, probe*: string
      ## Algebra and probe id.
    library*, reference*: Readings
      ## Both sides.
    open_on*: seq[string]
      ## Metrics library exceeds target on.
    status*: Status
      ## Verdict.
  Algebra* = object
    ## Define one algebra's documents as read from `baseline/`.
    config*: string
      ## Algebra name, e.g. `rga4d`.
    inspect*: JsonNode
      ## Inspect document.
    bench*: JsonNode
      ## Bench document; nil where none is recorded.
  Register* = object
    ## Define identifier register: next number and every key allotted so far.
    next*: int
      ## Next number to allot.
    ids*: Table[string, string]
      ## Identifier per row key.
  Rule* {.pure.} = enum
    ## Define how design gap is decided from documents.
    Terms, Time, ZeroFills, Temporaries, Checks, Inline, Nan, Compound, Missing, Cayley
  Design* = object
    ## Define one design-level gap.
    id*: string
      ## Stable identifier, `D01` onward, never renumbered.
    title*: string
      ## What gap is, one sentence.
    rule*: Rule
      ## How documents decide it.
    closes_when*: string
      ## Condition closing it, in words.
  Decided* = object
    ## Define design gap with its verdict and evidence.
    design*: Design
    status*: Status
    evidence*: string


const DESIGNS* = [
  Design(
    id: "D01", rule: Rule.Terms,
    title: "Dense products spend every Cayley-table term where typed forms spend few.",
    closes_when: "no typed row spends more multiplies than its reference.",
  ),
  Design(
    id: "D02", rule: Rule.Time,
    title: "Library calls run slower than typed forms beyond the band.",
    closes_when: "no row's library median exceeds " & $TIME_BAND & " times its reference's.",
  ),
  Design(
    id: "D03", rule: Rule.ZeroFills,
    title: "Operators zero-fill their full-width result before writing it.",
    closes_when: "no library function calls `nimZeroMem`.",
  ),
  Design(
    id: "D04", rule: Rule.Temporaries,
    title: "Chains materialise full-width temporaries.",
    closes_when: "no library function declares a local multivector.",
  ),
  Design(
    id: "D05", rule: Rule.Checks,
    title: "Error-flag checks survive into release builds.",
    closes_when: "no library function branches on `nimErr_`; `--panics:on` on the pinned " &
      "compiler already emits none on either side, so the library's users must know to pass it.",
  ),
  Design(
    id: "D06", rule: Rule.Inline,
    title: "Sign and permutation operators cross the module boundary as calls.",
    closes_when: "every library function spending no multiply, add or subtract is inline.",
  ),
  Design(
    id: "D07", rule: Rule.Nan,
    title: "Conformal norms return NaN on real objects.",
    closes_when: "every bench figure's NaN share is zero.",
  ),
  Design(
    id: "D08", rule: Rule.Compound,
    title: "Transforms by motor are composed of three products, with no operator of their own.",
    closes_when: "every catalogued probe spells one library function.",
  ),
  Design(
    id: "D09", rule: Rule.Missing,
    title: "Norms the reference carries and the library refuses.",
    closes_when: "the catalogue's missing list is empty.",
  ),
  Design(
    id: "D10", rule: Rule.Cayley,
    title: "Compile-time Cayley work is computed and discarded, by the audit's reading.",
    closes_when: "compile-time tables built are measured against tables used; nothing " &
      "here reads compile time.",
  ),
]
  ## Design gaps in identifier order; rows below them are data, these are their causes.



#[ Rows ]#

func at(node: JsonNode; key: string): JsonNode =
  ## Read child by key; nil where node is nil or key absent.
  if node.isNil: nil else: node{key}


func figuresOf(functions, figure: JsonNode; key: string; is_allocation_measured: bool): Readings =
  ## Read one side's figures: counts of function keyed, timing of bench figure.
  if key.len > 0 and not functions.isNil and functions.hasKey(key):
    let f = functions[key]
    result.multiplies = some(f{"total", "multiplies"}.getInt)
    result.bytes = some(f{"movement", "bytes_moved"}.getInt)
    result.zero_fills = some(f{"total", "zero_fills"}.getInt)
    result.temporaries = some(f{"total", "temporaries"}.getInt)
    result.checks = some(f{"total", "checks"}.getInt)
  if not figure.isNil and figure.kind == JObject:
    result.ns = some(figure{"ns_median"}.getFloat)
    result.nan_share = some(figure{"nan_share"}.getFloat)
    if is_allocation_measured: result.allocations = some(figure{"allocations"}.getInt)


func decide*(row: var Row) =
  ## Decide row: relative metrics open above reference, absolute ones above zero.
  row.open_on = @[]
  template relative(name: string; field: untyped) =
    if row.library.field.isSome and row.reference.field.isSome and
        row.library.field.get > row.reference.field.get:
      row.open_on.add name
  template absolute(name: string; field: untyped) =
    if row.library.field.isSome and row.library.field.get > row.reference.field.get(0):
      row.open_on.add name
  relative("multiplies", multiplies)
  relative("bytes", bytes)
  absolute("zero_fills", zero_fills)
  absolute("temporaries", temporaries)
  absolute("checks", checks)
  absolute("allocations", allocations)
  if row.library.nan_share.get(0.0) > 0.0: row.open_on.add "nan"
  if row.library.ns.isSome and row.reference.ns.isSome and
      row.library.ns.get > TIME_BAND * row.reference.ns.get:
    row.open_on.add "time"
  row.status =
    if row.open_on.len > 0: Status.Open
    elif row.library.multiplies.isNone and row.library.ns.isNone: Status.Unmeasured
    else: Status.Closed


func rowsOf*(a: Algebra): seq[Row] =
  ## Read one row per catalogued probe of algebra, decided.
  let probes = a.inspect.at("probes")
  if probes.isNil: return
  let functions = a.inspect.at("functions")
  let measured = a.bench.at("taken").at("is_allocation_measured").getBool
  for id, p in probes.pairs:
    var row = Row(key: a.config & "/" & id, config: a.config, probe: id)
    let figure = a.bench.at("probes").at(id)
    row.library = figuresOf(functions, figure.at("library"), p{"library"}.getStr, measured)
    row.reference = figuresOf(
      functions, figure.at("reference"), p{"reference"}.getStr, measured
    )
    row.decide
    result.add row



#[ Register ]#

func registerOf*(node: JsonNode): Register =
  ## Read register from its document; empty register where document is nil.
  result.next = 1
  if node.isNil: return
  result.next = max(1, node{"next"}.getInt(1))
  let ids = node{"ids"}
  if ids.isNil: return
  for key, id in ids.pairs: result.ids[key] = id.getStr


func toJson*(l: Register): JsonNode =
  ## Shape register as document, keys sorted so file moves only where ids do.
  var ids = newJObject()
  for key in toSeq(l.ids.keys).sorted: ids[key] = %l.ids[key]
  %*{"schema": SCHEMA, "kind": KIND_REGISTER, "next": l.next, "ids": ids}


func assign*(rows: var seq[Row]; register: var Register) =
  ## Give every row its identifier, allotting next number to keys register lacks.
  for row in rows.mitems:
    if row.key notin register.ids:
      register.ids[row.key] = "G" & align($register.next, 3, '0')
      inc register.next
    row.id = register.ids[row.key]



#[ Design ]#

func isLibrary(f: JsonNode): bool =
  ## Decide whether inspected function is library's rather than reference's.
  not f{"module"}.getStr.startsWith("reference/")


func isOperator(f: JsonNode): bool =
  ## Decide whether function is spelled as operator rather than named helper.
  let symbol = f{"symbol"}.getStr
  symbol.len > 0 and symbol[0] notin IdentStartChars


func isLight(f: JsonNode): bool =
  ## Decide whether function spends no arithmetic term, i.e. signs and permutations only.
  f{"total", "multiplies"}.getInt == 0 and f{"total", "adds"}.getInt == 0 and
    f{"total", "subs"}.getInt == 0


func named(names: openArray[string]; most = 6): string =
  ## Join names, first few spelled and rest counted, so evidence stays one sentence.
  if names.len <= most: return names.join(", ")
  names[0 ..< most].join(", ") & ", and " & $(names.len - most) & " more"


func countFunctions(
  algebras: openArray[Algebra]; metric: string; is_inline_rule: bool
): (int, int, string, int) =
  ## Count library functions exceeding zero on metric, or light operators not inline; return
  ## count, total, worst key and its value.
  var worst_value = -1
  for a in algebras:
    let functions = a.inspect.at("functions")
    if functions.isNil: continue
    for key, f in functions.pairs:
      if not f.isLibrary or (is_inline_rule and not f.isOperator): continue
      inc result[1]
      let value =
        if is_inline_rule: (if f.isLight and not f{"inline"}.getBool: 1 else: 0)
        else: f{"total", metric}.getInt
      if value <= 0: continue
      inc result[0]
      if value > worst_value:
        worst_value = value
        result[2] = a.config & " `" & key & "`"
        result[3] = value


func openRows(rows: openArray[Row]; metric: string): seq[Row] =
  ## Select rows open on metric.
  for row in rows:
    if metric in row.open_on: result.add row


func ratio(l, r: float): float =
  ## Read ratio guarding zero.
  if r == 0.0: (if l == 0.0: 1.0 else: 1.0e9) else: l / r


func decideDesign*(d: Design; algebras: openArray[Algebra]; rows: openArray[Row]): Decided =
  ## Decide design gap by its rule over documents and rows, with evidence in one sentence.
  result.design = d
  case d.rule
  of Rule.Terms:
    let open = rows.openRows("multiplies")
    var worst: Row
    var worst_gap = 0
    for row in open:
      let gap = row.library.multiplies.get - row.reference.multiplies.get
      if gap > worst_gap:
        worst_gap = gap
        worst = row
    result.status = if open.len > 0: Status.Open else: Status.Closed
    result.evidence =
      if open.len == 0: "no typed row spends more than its reference."
      else:
        $open.len & " rows; widest " & worst.key & " spends " & $worst.library.multiplies.get &
          " multiplies against " & $worst.reference.multiplies.get & "."
  of Rule.Time:
    var is_any_measured = false
    for a in algebras:
      if not a.bench.isNil: is_any_measured = true
    if not is_any_measured:
      result.status = Status.Unmeasured
      result.evidence = "no bench recorded."
      return
    let open = rows.openRows("time")
    var worst: Row
    var worst_ratio = 0.0
    for row in open:
      let q = ratio(row.library.ns.get, row.reference.ns.get)
      if q > worst_ratio:
        worst_ratio = q
        worst = row
    result.status = if open.len > 0: Status.Open else: Status.Closed
    result.evidence =
      if open.len == 0: "no row's library median exceeds band."
      else:
        $open.len & " rows; worst " & worst.key & " at " &
          formatFloat(worst.library.ns.get, ffDecimal, 1) & " ns against " &
          formatFloat(worst.reference.ns.get, ffDecimal, 1) & " ns."
  of Rule.ZeroFills, Rule.Temporaries, Rule.Checks, Rule.Inline:
    let metric =
      case d.rule
      of Rule.ZeroFills: "zero_fills"
      of Rule.Temporaries: "temporaries"
      of Rule.Checks: "checks"
      else: "inline"
    let (count, total, worst, value) = countFunctions(algebras, metric, d.rule == Rule.Inline)
    result.status = if count > 0: Status.Open else: Status.Closed
    result.evidence =
      if count == 0: "no library function of " & $total & "."
      elif d.rule == Rule.Inline:
        $count & " of " & $total & " library operators, e.g. " & worst & "."
      else:
        $count & " of " & $total & " library functions; most " & worst & " with " & $value & "."
  of Rule.Nan:
    var is_any_measured = false
    var names: seq[string]
    for row in rows:
      if row.library.nan_share.isSome: is_any_measured = true
      if row.library.nan_share.get(0.0) > 0.0: names.add row.key
    result.status =
      if not is_any_measured: Status.Unmeasured
      elif names.len > 0: Status.Open
      else: Status.Closed
    result.evidence =
      if not is_any_measured: "no bench recorded."
      elif names.len == 0: "every figure finite."
      else: named(names) & "."
  of Rule.Compound:
    var names: seq[string]
    for a in algebras:
      let probes = a.inspect.at("probes")
      if probes.isNil: continue
      for id, p in probes.pairs:
        if p{"library"}.getStr.len == 0: names.add a.config & "/" & id
    result.status = if names.len > 0: Status.Open else: Status.Closed
    result.evidence =
      if names.len == 0: "every probe names one function." else: named(names) & "."
  of Rule.Missing:
    var names: seq[string]
    for a in algebras:
      let missing = a.inspect.at("missing")
      if missing.isNil: continue
      for id, p in missing.pairs: names.add a.config & "/" & id & " `" & p{"symbol"}.getStr & "`"
    result.status = if names.len > 0: Status.Open else: Status.Closed
    result.evidence = if names.len == 0: "nothing missing." else: named(names) & "."
  of Rule.Cayley:
    result.status = Status.Unmeasured
    result.evidence = "not reachable from emitted C; the audit read `cayleys.nim`."



#[ Rendering ]#

func wrap*(text: string; width = WIDTH; indent = ""): seq[string] =
  ## Break text at spaces into lines of at most width runes, continuation lines indented.
  var line = ""
  for word in strutils.splitWhitespace(text):
    let candidate = if line.len == 0: word else: line & " " & word
    if line.len > 0 and candidate.runeLen > width:
      result.add line
      line = indent & word
    else:
      line = candidate
  if line.len > 0: result.add line


func cell(l, r: Option[int]): string =
  ## Render count cell as `library/reference`, dash where absent.
  if l.isNone and r.isNone: return "–"
  (if l.isSome: $l.get else: "–") & "/" & (if r.isSome: $r.get else: "–")


func cellNs(l, r: Option[float]): string =
  ## Render timing cell to one decimal, dash where absent.
  if l.isNone and r.isNone: return "–"
  (if l.isSome: formatFloat(l.get, ffDecimal, 1) else: "–") & "/" &
    (if r.isSome: formatFloat(r.get, ffDecimal, 1) else: "–")


func word(s: Status): string =
  ## Render status in lowercase.
  toLowerAscii($s)


func headerOf(a: Algebra): string =
  ## Render one paragraph naming what algebra's documents measured, on what, and when.
  let c = a.inspect.at("config")
  let t = a.inspect.at("taken")
  result = $c{"dimensions"}.getInt & " dimensions, " &
    (if c{"is_conformal"}.getBool: "conformal" else: "rigid") & " metric, " &
    $c{"sizeof_multivector"}.getInt & "-byte multivector. Counts: inspect taken " &
    t{"date"}.getStr & " on " & t{"machine"}.getStr & "; nim `" & t{"nim"}.getStr &
    "`; pga `" & t{"pga"}.getStr & "`; flags `" & t{"flags"}.getStr & "`."
  if a.bench.isNil:
    result.add " Times: unmeasured, no bench recorded."
  else:
    let b = a.bench.at("taken")
    result.add " Times: bench taken " & b{"date"}.getStr & " on " & b{"machine"}.getStr & ", " &
      $b{"rounds"}.getInt & " rounds over " & $b{"objects"}.getInt & " objects, allocation " &
      "gauge " & (if b{"is_allocation_measured"}.getBool: "live" else: "off") & "."


func render*(
  algebras: openArray[Algebra]; rows: openArray[Row]; decided: openArray[Decided]
): string =
  ## Render whole list as markdown; raise where any line outruns width.
  var lines: seq[string]
  lines.add "# Gaps"
  lines.add ""
  lines.add wrap(
    "Generated by `nim r tools/build.nim gaps` from `baseline/*.json`; do not edit by " &
    "hand. Identifiers are stable: `baseline/register.json` maps every row to its number and " &
    "none is reused. Counts are read from the C the pinned compiler emits for the `bench` " &
    "entry, cells reading `library/reference`; bytes are modelled movement per call; times " &
    "are medians of the last hand-run bench, on the machine each section names. A row is " &
    "open where the library exceeds its reference, or spends any zero fill, temporary, " &
    "error check, allocation or NaN; time opens beyond " & $TIME_BAND & " times the reference."
  )
  lines.add ""
  lines.add "## Design"
  lines.add ""
  for d in decided:
    lines.add wrap(
      "- **" & d.design.id & ", " & d.status.word & ".** " & d.design.title & " Evidence: " &
      d.evidence & " Closes when " & d.design.closes_when,
      indent = "  ",
    )
  for a in algebras:
    lines.add ""
    lines.add "## " & a.config
    lines.add ""
    lines.add wrap(a.headerOf)
    var counts: array[Status, int]
    var own: seq[Row]
    for row in rows:
      if row.config == a.config:
        inc counts[row.status]
        own.add row
    lines.add wrap(
      "Rows: " & $own.len & "; open " & $counts[Status.Open] & ", closed " &
      $counts[Status.Closed] & ", unmeasured " & $counts[Status.Unmeasured] & "."
    )
    lines.add ""
    lines.add "| Id | Probe | Mul | Bytes | Tmp | Chk | ns | Status |"
    lines.add "|----|-------|-----|-------|-----|-----|----|--------|"
    for row in own:
      lines.add "| " & row.id & " | " & row.probe & " | " &
        cell(row.library.multiplies, row.reference.multiplies) & " | " &
        cell(row.library.bytes, row.reference.bytes) & " | " &
        cell(row.library.temporaries, row.reference.temporaries) & " | " &
        cell(row.library.checks, row.reference.checks) & " | " &
        cellNs(row.library.ns, row.reference.ns) & " | " & row.status.word & " |"
  for line in lines:
    if line.runeLen > WIDTH:
      raise newException(ValueError, "Rendered line outruns width; got `" & line & "`.")
  lines.join("\n") & "\n"


func generate*(algebras: openArray[Algebra]; register: Register): (string, Register) =
  ## Generate list and grown register from documents.
  var rows: seq[Row]
  for a in algebras: rows.add a.rowsOf
  var grown = register
  rows.assign(grown)
  var decided: seq[Decided]
  for d in DESIGNS: decided.add d.decideDesign(algebras, rows)
  (render(algebras, rows, decided), grown)
