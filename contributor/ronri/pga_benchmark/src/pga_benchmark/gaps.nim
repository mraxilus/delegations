## Generate gap list from committed baselines: one gap per measurand per algebra, causes first.
##   Gap is decided against reference where one exists and against zero where target is
##   absolute (zero fills, intermediates, checks, allocations, NaN share); time opens beyond
##   `TOLERANCE`, since medians on shared machine wander. Identifiers come from docket,
##   which allots next number to any new key and reuses none, so `G017` names same gap in
##   every regeneration and every conversation about it.
##   Cause gaps are data: each carries rule deciding it from documents and sentence saying
##   what closes it, so list closes by measurement and never by edit.
##
##   Cost: renders markdown with every line under `WIDTH` runes, wrapping prose and refusing
##     table gap that does not fit, since product is committed and form-checked.
##   Cost: measurand naming no library function (composed sandwich) has no counts; its gap rests
##     on timing and reads `unmeasured` until bench is recorded.

{.experimental: "strictFuncs".}

import std/[algorithm, json, options, sequtils, strutils, tables, unicode]

import ./report


const
  TOLERANCE* = 1.25
    ## Factor library median may exceed reference median by before gap opens on time.
  WIDTH* = 100
    ## Runes per line rendered list stays within, since form check reads it.
  KIND_DOCKET = "docket"
    ## Document kind of docket file.


type
  Status* {.pure.} = enum
    ## Define verdict of one gap or cause.
    Over, Met, Unmeasured
  Values* = object
    ## Define one implementation's values of one gap; each absent where it or instrument is absent.
    multiplies*, divides*, bytes*, zero_fills*, intermediates*, checks*, allocations*: Option[int]
      ## Static measurements: counts read from emitted C; bytes are modelled movement.
    ns*, nan_share*: Option[float]
      ## Runtime measurements, absent where none is recorded.
  Gap* = object
    ## Define one measurand of one algebra with both implementations' values.
    key*: string
      ## `<algebra>/<measurand id>`, docket key.
    id*: string
      ## Docket identifier, e.g. `G017`.
    algebra*, measurand*: string
      ## Algebra name and measurand id.
    library*, reference*: Values
      ## Both implementations.
    bound*: Values
      ## Floor of dense representation, derived from algebra and never measured.
      ##   Absent where no rule is derived for measurand's shape.
    over_on*: seq[string]
      ## Metrics library exceeds target on.
    status*: Status
      ## Verdict.
  Algebra* = object
    ## Define one algebra's documents as read from `baseline/`.
    name*: string
      ## Algebra name, e.g. `rga4d`.
    static_measurements*: JsonNode
      ## Static measurements document.
    runtime_measurements*: JsonNode
      ## Runtime measurements document; nil where none is recorded.
  Docket* = object
    ## Define identifier docket: next number and every key allotted so far.
    next*: int
      ## Next number to allot.
    ids*: Table[string, string]
      ## Identifier per gap key.
  Rule* {.pure.} = enum
    ## Define how cause is decided from documents.
    Terms, Time, ZeroFills, Intermediates, Checks, Inline, Nan, Compound, Missing, Cayley
  Cause* = object
    ## Define one design-level gap.
    id*: string
      ## Stable identifier, `D01` onward, never renumbered.
    title*: string
      ## What gap is, one sentence.
    rule*: Rule
      ## How documents decide it.
    closes_when*: string
      ## Condition closing it, in words.
  Decision* = object
    ## Define cause with its verdict and evidence.
    design*: Cause
    status*: Status
    evidence*: string


const CAUSES* = [
  Cause(
    id: "D01", rule: Rule.Terms,
    title: "Dense products spend every Cayley-table term where typed forms spend few.",
    closes_when: "no typed gap spends more multiplies than its reference.",
  ),
  Cause(
    id: "D02", rule: Rule.Time,
    title: "Library calls run slower than typed forms beyond the band.",
    closes_when: "no gap's library median exceeds " & $TOLERANCE & " times its reference's.",
  ),
  Cause(
    id: "D03", rule: Rule.ZeroFills,
    title: "Operators zero-fill their full-width result before they write it.",
    closes_when: "no library function calls `nimZeroMem`.",
  ),
  Cause(
    id: "D04", rule: Rule.Intermediates,
    title: "Operator chains build full-width intermediates.",
    closes_when: "no library function declares a local multivector.",
  ),
  Cause(
    id: "D05", rule: Rule.Checks,
    title: "Error-flag checks survive into release builds.",
    closes_when: "no library function branches on `nimErr_`. The pinned compiler with " &
      "`--panics:on` already emits none in either implementation. A user of the library must " &
      "know to pass it.",
  ),
  Cause(
    id: "D06", rule: Rule.Inline,
    title: "Sign and permutation operators cross the module boundary as calls.",
    closes_when: "every library function spending no multiply, add or subtract is inline.",
  ),
  Cause(
    id: "D07", rule: Rule.Nan,
    title: "Conformal norms return NaN on real objects.",
    closes_when: "every bench measurement's NaN share is zero.",
  ),
  Cause(
    id: "D08", rule: Rule.Compound,
    title: "A transform by motor spells three products, because it has no operator of its own.",
    closes_when: "every catalogued measurand spells one library function.",
  ),
  Cause(
    id: "D09", rule: Rule.Missing,
    title: "The library refuses two norms that the reference carries.",
    closes_when: "the catalogue's missing list is empty.",
  ),
  Cause(
    id: "D10", rule: Rule.Cayley,
    title: "The library builds compile-time Cayley tables and drops some, by the audit's reading.",
    closes_when: "the project measures tables built against tables used. Nothing here " &
      "reads compile time.",
  ),
]
  ## Cause gaps in identifier order; gaps below them are data, these are their causes.



#[ Gaps ]#

func at(node: JsonNode; key: string): JsonNode =
  ## Read child by key; nil where node is nil or key absent.
  if node.isNil: nil else: node{key}


func valuesOf(functions, measurement: JsonNode; key: string; is_allocation_measured: bool): Values =
  ## Read one implementation's values: counts of function keyed, runtime measurement's timing.
  if key.len > 0 and not functions.isNil and functions.hasKey(key):
    let f = functions[key]
    result.multiplies = some(f{"total", "multiplies"}.getInt)
    result.divides = some(f{"total", "divides"}.getInt)
    result.bytes = some(f{"movement", "bytes_moved"}.getInt)
    result.zero_fills = some(f{"total", "zero_fills"}.getInt)
    result.intermediates = some(f{"total", "intermediates"}.getInt)
    result.checks = some(f{"total", "checks"}.getInt)
  if not measurement.isNil and measurement.kind == JObject:
    result.ns = some(measurement{"ns_median"}.getFloat)
    result.nan_share = some(measurement{"nan_share"}.getFloat)
    if is_allocation_measured: result.allocations = some(measurement{"allocations"}.getInt)


func decide*(gap: var Gap) =
  ## Decide gap: relative metrics open above reference, absolute ones above zero.
  gap.over_on = @[]
  template relative(name: string; field: untyped) =
    if gap.library.field.isSome and gap.reference.field.isSome and
        gap.library.field.get > gap.reference.field.get:
      gap.over_on.add name
  template absolute(name: string; field: untyped) =
    if gap.library.field.isSome and gap.library.field.get > gap.reference.field.get(0):
      gap.over_on.add name
  relative("multiplies", multiplies)
  relative("divides", divides)
  relative("bytes", bytes)
  absolute("zero_fills", zero_fills)
  absolute("intermediates", intermediates)
  absolute("checks", checks)
  absolute("allocations", allocations)
  if gap.library.nan_share.get(0.0) > 0.0: gap.over_on.add "nan"
  if gap.library.ns.isSome and gap.reference.ns.isSome and
      gap.library.ns.get > TOLERANCE * gap.reference.ns.get:
    gap.over_on.add "time"
  gap.status =
    if gap.over_on.len > 0: Status.Over
    elif gap.library.multiplies.isNone and gap.library.ns.isNone: Status.Unmeasured
    else: Status.Met


func boundValuesOf(node: JsonNode): Values =
  ## Read derived floor of one measurand; every field absent where document carries none.
  ##   Floor spends no fill, no intermediate, no error check and no allocation by
  ##   construction, so those stand at zero rather than absent.
  if node.isNil or node.kind != JObject: return
  result.multiplies = some(node{"multiplies"}.getInt)
  result.divides = some(node{"divides"}.getInt)
  result.bytes = some(node{"bytes_moved"}.getInt)
  result.zero_fills = some(0)
  result.intermediates = some(0)
  result.checks = some(0)
  result.allocations = some(0)


func gapsOf*(a: Algebra): seq[Gap] =
  ## Read one gap per catalogued measurand of algebra, decided.
  let measurands = a.static_measurements.at("measurands")
  if measurands.isNil: return
  let functions = a.static_measurements.at("functions")
  let measured = a.runtime_measurements.at("taken").at("is_allocation_measured").getBool
  for id, p in measurands.pairs:
    var gap = Gap(key: a.name & "/" & id, algebra: a.name, measurand: id)
    let measurement = a.runtime_measurements.at("measurands").at(id)
    gap.library = valuesOf(functions, measurement.at("library"), p{"library"}.getStr, measured)
    gap.reference = valuesOf(
      functions, measurement.at("reference"), p{"reference"}.getStr, measured
    )
    gap.bound = boundValuesOf(p.at("bound"))
    gap.decide
    result.add gap



#[ Docket ]#

func docketOf*(node: JsonNode): Docket =
  ## Read docket from its document; empty docket where document is nil.
  result.next = 1
  if node.isNil: return
  result.next = max(1, node{"next"}.getInt(1))
  let ids = node{"ids"}
  if ids.isNil: return
  for key, id in ids.pairs: result.ids[key] = id.getStr


func toJson*(l: Docket): JsonNode =
  ## Shape docket as document, keys sorted so file moves only where ids do.
  var ids = newJObject()
  for key in toSeq(l.ids.keys).sorted: ids[key] = %l.ids[key]
  %*{"schema": SCHEMA, "kind": KIND_DOCKET, "next": l.next, "ids": ids}


func assign*(gaps: var seq[Gap]; docket: var Docket) =
  ## Give every gap its identifier, allotting next number to keys docket lacks.
  for gap in gaps.mitems:
    if gap.key notin docket.ids:
      docket.ids[gap.key] = "G" & align($docket.next, 3, '0')
      inc docket.next
    gap.id = docket.ids[gap.key]



#[ Cause ]#

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
    let functions = a.static_measurements.at("functions")
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
        result[2] = a.name & " `" & key & "`"
        result[3] = value


func overGaps(gaps: openArray[Gap]; metric: string): seq[Gap] =
  ## Select gaps open on metric.
  for gap in gaps:
    if metric in gap.over_on: result.add gap


func ratio(l, r: float): float =
  ## Read ratio guarding zero.
  if r == 0.0: (if l == 0.0: 1.0 else: 1.0e9) else: l / r


func decideCause*(d: Cause; algebras: openArray[Algebra]; gaps: openArray[Gap]): Decision =
  ## Decide cause by its rule over documents and gaps, with evidence in one sentence.
  result.design = d
  case d.rule
  of Rule.Terms:
    let open = gaps.overGaps("multiplies")
    var worst: Gap
    var worst_excess = 0
    for gap in open:
      let excess = gap.library.multiplies.get - gap.reference.multiplies.get
      if excess > worst_excess:
        worst_excess = excess
        worst = gap
    result.status = if open.len > 0: Status.Over else: Status.Met
    result.evidence =
      if open.len == 0: "no typed gap spends more than its reference."
      else:
        $open.len & " gaps. The widest is " & worst.key & ", which spends " &
          $worst.library.multiplies.get & " multiplies against " &
          $worst.reference.multiplies.get & "."
  of Rule.Time:
    var is_any_measured = false
    for a in algebras:
      if not a.runtime_measurements.isNil: is_any_measured = true
    if not is_any_measured:
      result.status = Status.Unmeasured
      result.evidence = "no bench recorded."
      return
    let open = gaps.overGaps("time")
    var worst: Gap
    var worst_ratio = 0.0
    for gap in open:
      let q = ratio(gap.library.ns.get, gap.reference.ns.get)
      if q > worst_ratio:
        worst_ratio = q
        worst = gap
    result.status = if open.len > 0: Status.Over else: Status.Met
    result.evidence =
      if open.len == 0: "no gap's library median exceeds band."
      else:
        $open.len & " gaps. The worst is " & worst.key & ", at " &
          formatFloat(worst.library.ns.get, ffDecimal, 1) & " ns against " &
          formatFloat(worst.reference.ns.get, ffDecimal, 1) & " ns."
  of Rule.ZeroFills, Rule.Intermediates, Rule.Checks, Rule.Inline:
    let metric =
      case d.rule
      of Rule.ZeroFills: "zero_fills"
      of Rule.Intermediates: "intermediates"
      of Rule.Checks: "checks"
      else: "inline"
    let (count, total, worst, value) = countFunctions(algebras, metric, d.rule == Rule.Inline)
    result.status = if count > 0: Status.Over else: Status.Met
    result.evidence =
      if count == 0: "no library function of " & $total & "."
      elif d.rule == Rule.Inline:
        $count & " of " & $total & " library operators, for example " & worst & "."
      else:
        $count & " of " & $total & " library functions. The most is " & worst & " with " &
          $value & "."
  of Rule.Nan:
    var is_any_measured = false
    var names: seq[string]
    for gap in gaps:
      if gap.library.nan_share.isSome: is_any_measured = true
      if gap.library.nan_share.get(0.0) > 0.0: names.add gap.key
    result.status =
      if not is_any_measured: Status.Unmeasured
      elif names.len > 0: Status.Over
      else: Status.Met
    result.evidence =
      if not is_any_measured: "no bench recorded."
      elif names.len == 0: "every measurement finite."
      else: named(names) & "."
  of Rule.Compound:
    var names: seq[string]
    for a in algebras:
      let measurands = a.static_measurements.at("measurands")
      if measurands.isNil: continue
      for id, p in measurands.pairs:
        if p{"library"}.getStr.len == 0: names.add a.name & "/" & id
    result.status = if names.len > 0: Status.Over else: Status.Met
    result.evidence =
      if names.len == 0: "every measurand names one function." else: named(names) & "."
  of Rule.Missing:
    var names: seq[string]
    for a in algebras:
      let missing = a.static_measurements.at("missing")
      if missing.isNil: continue
      for id, p in missing.pairs: names.add a.name & "/" & id & " `" & p{"symbol"}.getStr & "`"
    result.status = if names.len > 0: Status.Over else: Status.Met
    result.evidence = if names.len == 0: "nothing missing." else: named(names) & "."
  of Rule.Cayley:
    result.status = Status.Unmeasured
    result.evidence = "no emitted C reaches it. The audit read `cayleys.nim`."



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


func floorRows*(a: Algebra; gaps: openArray[Gap]): seq[string] =
  ## Render floor of each operation once, keyed by symbol and shape.
  ##   Floor rests on symbol, shape and arity, and never on operand kinds, so one row
  ##   serves every measurand that spells same operation. Row also carries what library
  ##   spends on that operation's general measurand, so distance reads across.
  let measurands = a.static_measurements.at("measurands")
  let functions = a.static_measurements.at("functions")
  if measurands.isNil: return
  var seen: seq[string]
  for id, p in measurands.pairs:
    let b = p.at("bound")
    if b.isNil or b.kind != JObject: continue
    let symbol = p{"symbol"}.getStr
    let shape = b{"shape"}.getStr
    let key = symbol & " " & shape
    if key in seen: continue
    seen.add key
    var spent = "–"
    let fn = functions.at(p{"library"}.getStr)
    if not fn.isNil:
      spent = $fn{"total", "multiplies"}.getInt & "/" & $fn{"movement", "bytes_moved"}.getInt
    result.add "| `" & (if symbol.len > 0: symbol else: id) & "` | " & shape & " | " &
      $b{"multiplies"}.getInt & " | " & $b{"divides"}.getInt & " | " &
      $b{"roots"}.getInt & " | " & $b{"bytes_moved"}.getInt & " | " & spent & " |"


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
  let c = a.static_measurements.at("algebra")
  let t = a.static_measurements.at("taken")
  result = "This algebra has " & $c{"dimensions"}.getInt & " dimensions, a " &
    (if c{"is_conformal"}.getBool: "conformal" else: "rigid") & " metric and a " &
    $c{"sizeof_multivector"}.getInt & "-byte multivector. The inspector took the counts on " &
    t{"date"}.getStr & ", on " & t{"machine"}.getStr & ", with nim `" & t{"nim"}.getStr &
    "`, pga `" & t{"pga"}.getStr & "` and flags `" & t{"flags"}.getStr & "`."
  if a.runtime_measurements.isNil:
    result.add " Nobody measured the times, because no bench ran."
  else:
    let b = a.runtime_measurements.at("taken")
    result.add " The bench ran on " & b{"date"}.getStr & ", on " & b{"machine"}.getStr &
      ", over " & $b{"rounds"}.getInt & " rounds of " & $b{"objects"}.getInt &
      " objects. The allocation gauge was " &
      (if b{"is_allocation_measured"}.getBool: "live" else: "off") & "."


func render*(
  algebras: openArray[Algebra]; gaps: openArray[Gap]; decided: openArray[Decision]
): string =
  ## Render whole list as markdown; raise where any line outruns width.
  var lines: seq[string]
  lines.add "# Gaps"
  lines.add ""
  lines.add wrap(
    "The driver writes this file. To make it again, run `nim r tools/build.nim gaps`, which " &
    "reads `baseline/*.json`. Do not edit it by hand. Every gap keeps its number, because " &
    "`baseline/docket.json` holds the numbers and the driver reuses none. The pinned compiler " &
    "emits C for the `bench` entry, and the inspector counts that C. A cell gives the library " &
    "value first and the reference value second."
  )
  lines.add ""
  lines.add wrap(
    "A gap is over where the library spends more than its reference. It is also over where " &
    "the library spends a zero fill, an intermediate, an error check, an allocation or a NaN. " &
    "Time is over where the library median is more than " & $TOLERANCE & " times the " &
    "reference median. A gap is met in every other case. Bytes are modelled movement for each " &
    "call, and runtime measurements are medians of the last bench that ran by hand."
  )
  lines.add ""
  lines.add wrap(
    "Each algebra below carries a floor table. The floor is what the algebra demands of " &
    "any dense implementation, and it is derived from the axioms rather than measured. A " &
    "floor spends no zero fill, no intermediate, no error check and no allocation. It " &
    "moves its operands read once plus its result written once. The floor rests on the " &
    "operation alone, so one row serves every measurand that spells that operation."
  )
  lines.add ""
  lines.add wrap(
    "The last column of a floor table is what the library spends on that operation, as " &
    "multiplies over bytes moved. An operation whose shape carries no rule yet is absent " &
    "from the table, rather than present with a number that has no ground."
  )
  lines.add ""
  lines.add "## Causes"
  lines.add ""
  for d in decided:
    lines.add wrap(
      "- **" & d.design.id & ", " & d.status.word & ".** " & d.design.title & " Evidence: " &
      d.evidence & " Closes when " & d.design.closes_when,
      indent = "  ",
    )
  for a in algebras:
    lines.add ""
    lines.add "## " & a.name
    lines.add ""
    lines.add wrap(a.headerOf)
    var counts: array[Status, int]
    var own: seq[Gap]
    for gap in gaps:
      if gap.algebra == a.name:
        inc counts[gap.status]
        own.add gap
    lines.add wrap(
      "Gaps: " & $own.len & ". Over " & $counts[Status.Over] & ", met " &
      $counts[Status.Met] & ", unmeasured " & $counts[Status.Unmeasured] & "."
    )
    lines.add ""
    lines.add "| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |"
    lines.add "|----|-----------|-----|-----|-------|-----|-----|----|--------|"
    for gap in own:
      lines.add "| " & gap.id & " | " & gap.measurand & " | " &
        cell(gap.library.multiplies, gap.reference.multiplies) & " | " &
        cell(gap.library.divides, gap.reference.divides) & " | " &
        cell(gap.library.bytes, gap.reference.bytes) & " | " &
        cell(gap.library.intermediates, gap.reference.intermediates) & " | " &
        cell(gap.library.checks, gap.reference.checks) & " | " &
        cellNs(gap.library.ns, gap.reference.ns) & " | " & gap.status.word & " |"
    let floors = floorRows(a, own)
    if floors.len > 0:
      lines.add ""
      lines.add "### Floor"
      lines.add ""
      lines.add "| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |"
      lines.add "|----|-------|-----|-----|-------|-------|-------------------|"
      for row in floors: lines.add row
  for line in lines:
    if line.runeLen > WIDTH:
      raise newException(ValueError, "Rendered line outruns width; got `" & line & "`.")
  lines.join("\n") & "\n"


func generate*(algebras: openArray[Algebra]; docket: Docket): (string, Docket) =
  ## Generate list and grown docket from documents.
  var gaps: seq[Gap]
  for a in algebras: gaps.add a.gapsOf
  var grown = docket
  gaps.assign(grown)
  var decided: seq[Decision]
  for d in CAUSES: decided.add d.decideCause(algebras, gaps)
  (render(algebras, gaps, decided), grown)
