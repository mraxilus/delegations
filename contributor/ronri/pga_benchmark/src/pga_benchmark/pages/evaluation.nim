## Render what evaluation measured, and edits it tried, for marginalia and proposal pages alike.
##   Both pages show proposed change against pin, so both render it one way: suites beside
##     pin's own, functions whose counts moved, times of measurands those functions serve, and
##     edits as diff of lines against file each edit finds.
##   Proposal page shows code one block per file, closed, under its status and counts. Inside,
##     each definition change adds, removes or changes shows its signature and doc, and folds
##     its body (`definitions.nim`). So reader sees what each definition is before how it works.
##     Lines in no definition follow, diffed, as other lines.
##   Marginalia shows edits under list of files they touch, each with lines removed and added.
##     Each edit's summary names file and line, then signatures of routines, tests and suites
##     edit defines, else of one it sits in. Body, pragmas and comments leave signature.
##   Diff numbers each line on side it stands on: before edit and after it, in file as edit finds
##     it. Bases of proposal and earlier edits apply first, so number is one reader finds in
##     library carrying them. Unchanged run longer than twice context folds to count of lines.
##   Proposal page condenses what evaluation measured, as docket draws it but static: per
##     algebra, one row per function that moved, each count and its time as bar of proposal
##     over pin on one log axis; operations within spread and helpers moved are counted.
##   Spread is read from evaluations themselves: evaluation that changes no library function
##     moves no count, so range of its time ratios is range of machine, and page states it
##     beside figures it qualifies.
##
##   Cost: measurand counts as touched where its library function moved; measurand served by
##     composition of several functions is left out, as `pairTimes` leaves it out of median.
##   Cost: diff takes table of common lengths over lines between shared head and tail, so whole-
##     file replacement of about thousand changed lines holds about million counts while page
##     builds.

{.experimental: "strictFuncs".}

import std/[algorithm, json, math, options, sequtils, strutils, tables]

import ../[changes, definitions, markdown]
import ./shell


type
  Spread* = object
    ## Define range that holds 90% of time ratios in evaluations that change no library function.
    low*, high*: float  ## Fifth and ninety-fifth percentile of ratio, each measurand alone.
    count*: int  ## Ratios spread is read from; zero where spread is assumed.
  KindLine {.pure.} = enum  ## Define what edit does to one line of diff.
    Kept, Removed, Added
  LineDiffed = object  ## Define one line of diff, numbered on each side it stands on.
    kind: KindLine  ## Kept on both sides, removed from before, or added after.
    text: string  ## Line as written.
    number_before: int  ## Line in file before edit; zero where line is added.
    number_after: int  ## Line in file after edit; zero where line is removed.


const
  SPREAD_ASSUMED = Spread(low: 0.92, high: 1.08, count: 0)
    ## Spread assumed where too few evaluations change nothing; page states it as assumed.
  CONTEXT = 3  ## Unchanged lines diff keeps beside each change; longer run folds.



#[ Figures ]#

func touched*(
  evaluation: JsonNode, baselines: Table[string, JsonNode], algebra: string
): seq[string] =
  ## List measurands whose library function evaluation changed, at one algebra.
  let
    changed = evaluation{"algebras", algebra, "functions"}
    measurands = baselines.getOrDefault(algebra){"measurands"}
  if changed.isNil or measurands.isNil: return
  for id, measurand in measurands.pairs:
    if changed.hasKey(measurand{"library"}.getStr): result.add id


func spread*(evaluations: openArray[JsonNode]): Spread =
  ## Read spread from evaluations that change no library function at any algebra.
  var ratios: seq[float]
  for evaluation in evaluations:
    var is_quiet = true
    for _, measured in evaluation{"algebras"}.pairs:
      if measured{"functions"}.len > 0: is_quiet = false
    if not is_quiet: continue
    for _, measured in evaluation{"algebras"}.pairs:
      for _, timing in measured{"times"}.pairs: ratios.add timing[2].getFloat
  if ratios.len < 20: return SPREAD_ASSUMED
  ratios.sort
  Spread(
    low: ratios[ratios.len div 20],
    high: ratios[ratios.len-1-ratios.len div 20],
    count: ratios.len,
  )



#[ Rendering ]#

func textSuites(evaluation: JsonNode, algebra: string): string =
  ## Render suites passed over run, with pin's beside where they differ.
  let
    suites = evaluation{"algebras", algebra, "suites"}
    suites_pin = evaluation{"pin_suites", algebra}
    run = suites{"ok"}.getInt + suites{"failed"}.getInt
  result = $suites{"ok"}.getInt & "/" & $run
  if suites_pin.isNil: return
  if suites_pin{"ok"}.getInt != suites{"ok"}.getInt or
      suites_pin{"failed"}.getInt != suites{"failed"}.getInt:
    result.add " (pin " & $suites_pin{"ok"}.getInt & "/" &
        $(suites_pin{"ok"}.getInt + suites_pin{"failed"}.getInt) & ")"


func nanMoved(measured: JsonNode): (int, int) =
  ## Count measurands whose NaN results evaluation removed, and those it introduced.
  if measured{"nan"}.isNil: return
  for _, shares in measured{"nan"}.pairs:
    let (before, after) = (shares[0].getFloat, shares[1].getFloat)
    if before > 0 and after == 0: inc result[0]
    if before == 0 and after > 0: inc result[1]


func chipsVerdict*(
  evaluation: JsonNode, baselines: Table[string, JsonNode], spread: Spread
): string =
  ## Render one chip per algebra: suites, then median time over what evaluation touched.

  func medianTouched(
    evaluation: JsonNode, baselines: Table[string, JsonNode], algebra: string
  ): float =
    ## Read median time ratio over measurands evaluation touched at algebra; zero where none.
    var ratios: seq[float]
    let times = evaluation{"algebras", algebra, "times"}
    for id in touched(evaluation, baselines, algebra):
      if not times.isNil and times.hasKey(id): ratios.add times[id][2].getFloat
    if ratios.len == 0: return 0.0
    ratios.sort
    if ratios.len mod 2 == 1: ratios[ratios.len div 2]
    else: (ratios[ratios.len div 2-1] + ratios[ratios.len div 2]) / 2.0

  if evaluation.isNil: return chip("no evaluation", "fail")
  for algebra, measured in evaluation{"algebras"}.pairs:
    let
      failed = measured{"suites", "failed"}.getInt
      failed_pin = evaluation{"pin_suites", algebra, "failed"}.getInt
      (gone, came) = nanMoved(measured)
      kind = if failed > failed_pin or came > 0: "fail" else: "pass"
      median = medianTouched(evaluation, baselines, algebra)
    var text = algebra & " suites " & textSuites(evaluation, algebra)
    if measured{"functions"}.len > 0:
      text.add " · " & $measured{"functions"}.len & " functions moved"
    if gone > 0: text.add " · NaN gone in " & $gone
    if came > 0: text.add " · NaN new in " & $came
    if median > 0:
      let side = if median < spread.low: "fast" elif median > spread.high: "slow" else: "flat"
      result.add chip(text & " · " & textRatio(median), kind & " " & side)
    else:
      result.add chip(text, kind)


func tableFunctions*(evaluation: JsonNode): string =
  ## Render functions evaluation moved: multiplies, bytes and fills, pin then changed.

  func transition(before, after: JsonNode; field: string): string =
    ## Render one count at pin, then changed; `new` or `gone` where function is on one side.
    let
      was = if before.isNil or before.kind != JObject: "new" else: grouped(before{field}.getInt)
      now = if after.isNil or after.kind != JObject: "gone" else: grouped(after{field}.getInt)
    was & " → " & now

  for algebra, measured in evaluation{"algebras"}.pairs:
    let changed = measured{"functions"}
    if changed.isNil or changed.len == 0: continue
    result.add "<div class=\"table\"><table><caption>" & algebra & ": functions whose counts " &
        "moved</caption><tr><th>Function</th><th>Multiplies</th><th>Bytes moved</th>" &
        "<th>Zero fills</th></tr>"
    for key, pair in changed.pairs:
      let (before, after) = (pair{"before"}, pair{"after"})
      result.add "<tr><td>" & code(key) & "</td><td>" &
          transition(before, after, "multiplies") & "</td><td>" &
          transition(before, after, "bytes_moved") & "</td><td>" &
          transition(before, after, "fills_zero") & "</td></tr>"
    result.add "</table></div>"


func tableTimes*(evaluation: JsonNode, baselines: Table[string, JsonNode], spread: Spread): string =
  ## Render measurands evaluation touched, pin's time then changed time, per algebra.
  for algebra, measured in evaluation{"algebras"}.pairs:
    let ids = touched(evaluation, baselines, algebra)
    if ids.len == 0: continue
    result.add "<div class=\"table\"><table><caption>" & algebra & ": time of measurands whose " &
        "function moved, ns</caption><tr><th>Measurand</th><th>Pin</th><th>Changed</th>" &
        "<th>Ratio</th></tr>"
    for id in ids:
      let timing = measured{"times", id}
      if timing.isNil: continue
      let
        ratio = timing[2].getFloat
        side = if ratio < spread.low: "fast" elif ratio > spread.high: "slow" else: "flat"
      result.add "<tr class=\"" & side & "\"><td>" & escapeHtml(id) & "</td><td>" &
          timing[0].getFloat.fixed(1) & "</td><td>" & timing[1].getFloat.fixed(1) & "</td><td>" &
          textRatio(ratio) & "</td></tr>"
    result.add "</table></div>"


func tableNan*(evaluation: JsonNode): string =
  ## Render measurands whose share of NaN results evaluation moved, pin's then changed, per algebra.
  for algebra, measured in evaluation{"algebras"}.pairs:
    let shares = measured{"nan"}
    if shares.isNil or shares.len == 0: continue
    result.add "<div class=\"table\"><table><caption>" & algebra & ": share of results that " &
        "are NaN</caption><tr><th>Measurand</th><th>Pin</th><th>Changed</th></tr>"
    for id, pair in shares.pairs:
      result.add "<tr><td>" & escapeHtml(id) & "</td><td>" & pair[0].getFloat.fixed(3) &
          "</td><td>" & pair[1].getFloat.fixed(3) & "</td></tr>"
    result.add "</table></div>"


func htmlEvidence*(
  evaluation: JsonNode, baselines: Table[string, JsonNode], spread: Spread
): string =
  ## Render what evaluation moved, condensed: per algebra, suites and functions moved, then each
  ##   operation that gains or loses, as bars of proposal over pin on one log axis; rest counted.
  ##   Axis spans ×1/16 to ×16 around pin, so bar left of line is gain and right is loss.
  const (exponent_low, exponent_high) = (-4, 4)

  func position(ratio: float): float =
    ## Place ratio on axis, in percent of its width, clamped.
    clamp(100.0 * (log2(ratio) - float(exponent_low)) / float(exponent_high - exponent_low),
        0.0, 100.0)

  func bar(ratio: float; label, tip: string): string =
    ## Render one bar of proposal over pin, or label alone where no ratio reads.
    if ratio <= 0:
      return "<div class=\"deviation bare\" title=\"" & escapeHtml(tip) & "\">" &
          "<div class=\"axis\"></div><span class=\"v\">" & label & "</span></div>"
    let
      (origin, at) = (position(1.0), position(ratio))
      side = if ratio < 1.0: "gain" elif ratio > 1.0: "loss" else: "flat"
    "<div class=\"deviation\" title=\"" & escapeHtml(tip) & "\"><div class=\"axis\"><i class=\"" &
        side & "\" style=\"left:" & min(origin, at).fixed & "%;width:" & abs(at - origin).fixed &
        "%\"></i></div><span class=\"v\">" & label & "</span></div>"

  func count(pair: JsonNode, field: string): (float, string, string) =
    ## Read one count of function: proposal over pin, label and tip; new or gone where one side
    ##   lacks it. Count that falls to zero reads at end of axis.
    let (before, after) = (pair{"before"}, pair{"after"})
    if before.isNil or before.kind != JObject: return (0.0, "new", "function new")
    if after.isNil or after.kind != JObject: return (0.0, "gone", "function gone")
    let
      (was, now) = (before{field}.getInt, after{field}.getInt)
      tip = "pin " & grouped(was) & ", proposal " & grouped(now)
    if was == 0: return (0.0, grouped(was) & " → " & grouped(now), tip)
    if now == 0: return (pow(2.0, float(exponent_low)), grouped(was) & " → 0", tip)
    (now / was, textRatio(now / was), tip)

  func titleAlgebra(algebra: string): string =
    ## Title algebra, as `Conformal 5D` for `cga5d`.
    (if algebra.startsWith("cga"): "Conformal " else: "Rigid ") & algebra[3 .. ^1].toUpperAscii

  if evaluation.isNil: return "<p class=\"note\">No evaluation yet; nothing is measured.</p>"
  result = "<p class=\"note\">Each bar is proposal over pin on log scale from ×1/16 to ×16: " &
      "left of line is gain, right is loss. Times within " & textRatio(spread.low) & " to " &
      textRatio(spread.high) & " count as unchanged.</p>"
  for algebra, measured in evaluation{"algebras"}.pairs:
    let
      measurands = baselines.getOrDefault(algebra){"measurands"}
      moved = if measured{"functions"}.isNil: newJObject() else: measured{"functions"}
      (gone, came) = nanMoved(measured)
    var facts = @["suites " & textSuites(evaluation, algebra), $moved.len & " functions moved"]
    if gone > 0: facts.add "NaN gone in " & $gone
    if came > 0: facts.add "NaN new in " & $came
    result.add "<div class=\"evidence-algebra\"><p class=\"caption\"><strong>" &
        titleAlgebra(algebra) & "</strong> · " & facts.join(" · ") & "</p>"

    # One row per function moved that serves operations, kept where any count or time moved.
    var functions: OrderedTable[string, seq[string]]  # Function, operations it serves.
    for id in touched(evaluation, baselines, algebra):
      functions.mgetOrPut(measurands{id}{"library"}.getStr, @[]).add id
    var
      rows: seq[(float, string)]  # Time ratio, row.
      flat = 0
    for function, operations in functions.pairs:
      let
        pair = moved{function}
        (multiplies, label_multiplies, tip_multiplies) = count(pair, "multiplies")
        (bytes, label_bytes, tip_bytes) = count(pair, "bytes_moved")
      var ratios: seq[float]
      for id in operations:
        let timing = measured{"times", id}
        if not timing.isNil: ratios.add timing[2].getFloat
      ratios.sort
      let
        time = if ratios.len == 0: 0.0 else: ratios[ratios.len div 2]
        is_moved = multiplies != 1.0 or bytes != 1.0 or
            (time > 0 and (time < spread.low or time > spread.high))
      if not is_moved:
        flat += operations.len
        continue
      rows.add (time, "<tr><td>" & code(function) & "<span class=\"serves\">" &
          operations.mapIt(escapeHtml(it)).join(", ") & "</span></td><td>" &
          bar(multiplies, label_multiplies, tip_multiplies) & "</td><td>" &
          bar(bytes, label_bytes, tip_bytes) & "</td><td>" &
          bar(time, if time > 0: textRatio(time) else: "untimed",
            "median over " & $ratios.len & " operations") & "</td></tr>")
    rows.sort(proc (a, b: (float, string)): int = cmp(a[0], b[0]))
    if rows.len > 0:
      result.add "<div class=\"table\"><table><tr><th>Function, and operations it serves</th>" &
          "<th>Multiplies</th><th>Bytes moved</th><th>Time</th></tr>" & rows.mapIt(it[1]).join &
          "</table></div>"
    var notes: seq[string]
    if rows.len == 0: notes.add "No operation moved beyond spread."
    if flat > 0:
      notes.add $flat & (if flat == 1: " operation" else: " operations") &
          " whose function moved stayed within spread."
    let others = block:
      var names: seq[string]
      for function, _ in moved.pairs:
        if function notin functions: names.add code(function)
      names
    if others.len > 0: notes.add "Other functions moved: " & others.join(", ") & "."
    if notes.len > 0: result.add "<p class=\"note\">" & notes.join(" ") & "</p>"
    result.add "</div>"


func diffLines(before, after: seq[string]; first_before, first_after: int): seq[LineDiffed] =
  ## Diff lines through longest common subsequence; removal stands before addition it pairs with.
  ##   `first_before` and `first_after` number first line of each side; zero leaves side bare.

  func lineNumber(first, index: int): int =
    ## Number line `index` of side opening at `first`; zero where side is bare.
    if first > 0: first + index else: 0

  # Trim head and tail both sides share, so table spans changed middle alone.
  var head, tail = 0
  while head < before.len and head < after.len and before[head] == after[head]: inc head
  while tail < before.len - head and tail < after.len - head and
      before[^(tail+1)] == after[^(tail+1)]:
    inc tail
  let
    (count_before, count_after) = (before.len - head - tail, after.len - head - tail)
    width = count_after + 1

  # Count longest common subsequence of each pair of suffixes of middle.
  var lengths = newSeq[int]((count_before + 1) * width)
  for i in countdown(count_before - 1, 0):
    for j in countdown(count_after - 1, 0):
      lengths[i * width + j] =
        if before[head+i] == after[head+j]: lengths[(i+1)*width+j+1] + 1
        else: max(lengths[(i+1)*width+j], lengths[i*width+j+1])

  # Walk from start: keep shared line, else remove or add toward longer common suffix.
  for index in 0..<head:
    result.add LineDiffed(
      kind: KindLine.Kept,
      text: before[index],
      number_before: lineNumber(first_before, index),
      number_after: lineNumber(first_after, index),
    )
  var (i, j) = (0, 0)
  while i < count_before or j < count_after:
    if i < count_before and j < count_after and before[head+i] == after[head+j]:
      result.add LineDiffed(
        kind: KindLine.Kept,
        text: before[head+i],
        number_before: lineNumber(first_before, head + i),
        number_after: lineNumber(first_after, head + j),
      )
      inc i
      inc j
    elif i < count_before and
        (j == count_after or lengths[(i+1)*width+j] >= lengths[i*width+j+1]):
      result.add LineDiffed(
        kind: KindLine.Removed,
        text: before[head+i],
        number_before: lineNumber(first_before, head + i),
      )
      inc i
    else:
      result.add LineDiffed(
        kind: KindLine.Added,
        text: after[head+j],
        number_after: lineNumber(first_after, head + j),
      )
      inc j
  for index in 0..<tail:
    result.add LineDiffed(
      kind: KindLine.Kept,
      text: before[before.len-tail+index],
      number_before: lineNumber(first_before, before.len - tail + index),
      number_after: lineNumber(first_after, after.len - tail + index),
    )


func toLines(text: string): seq[string] =
  ## Split text into lines, one closing line break dropped; empty text holds none.
  if text.len == 0: return
  (if text.endsWith("\n"): text[0 .. ^2] else: text).splitLines


func textCounts(lines: seq[LineDiffed]): string =
  ## Count lines removed and added, as `-2 +5`.
  "<span class=\"removed\">-" & $lines.countIt(it.kind == KindLine.Removed) &
      "</span> <span class=\"added\">+" & $lines.countIt(it.kind == KindLine.Added) & "</span>"


func textLines(count: int): string =
  ## Count lines in words, as `1 line` or `7 lines`.
  $count & (if count == 1: " line" else: " lines")


func htmlDiff(lines: seq[LineDiffed], language = ""): string =
  ## Render diff as numbered lines, each unchanged run past context folded to its count.
  ##   Lines of Nim take marks of their tokens, as fenced Nim does.

  func cellLine(number: int): string =
    ## Render line number, or empty cell where side holds no such line.
    "<td class=\"ln\">" & (if number > 0: $number else: "") & "</td>"

  # Show each change with context beside it; lone hidden line shows, since its fold is no shorter.
  var is_shown = newSeq[bool](lines.len)
  for index, line in lines:
    if line.kind == KindLine.Kept: continue
    for near in max(0, index - CONTEXT) .. min(lines.len - 1, index + CONTEXT):
      is_shown[near] = true
  for index in 0..<lines.len:
    if (index == 0 or is_shown[index-1]) and (index == lines.len - 1 or is_shown[index+1]):
      is_shown[index] = true

  # Render rows, folding each hidden run.
  result = "<div class=\"diff\"><table>"
  var index = 0
  while index < lines.len:
    if not is_shown[index]:
      var last = index
      while last + 1 < lines.len and not is_shown[last+1]: inc last
      let count = last - index + 1
      result.add "<tr class=\"fold\"><td colspan=\"4\">" & $count & " unchanged lines</td></tr>"
      index = last + 1
      continue
    let (row, sign) = case lines[index].kind
      of KindLine.Kept: ("kept", " ")
      of KindLine.Removed: ("removed", "-")
      of KindLine.Added: ("added", "+")
    result.add "<tr class=\"" & row & "\">" & cellLine(lines[index].number_before) &
        cellLine(lines[index].number_after) & "<td class=\"sign\">" & sign &
        "</td><td class=\"text\">" &
        (if language == "nim": renderNim(lines[index].text) else: escapeHtml(lines[index].text)) &
        "</td></tr>"
    inc index
  result.add "</table></div>"


func htmlEdits*(change: Change, files: Table[string, string]): string =
  ## Render files change touches, then each edit open as diff, under summary naming where it lands.
  ##   `files` is library as change finds it: pin, with bases of proposal applied.
  ##   Summary names signatures edit defines or sits in.
  const declarations = ["func ", "proc ", "iterator ", "template ", "macro ", "method ",
    "converter ", "suite ", "test "]
    ## Words opening declaration whose signature summary shows.

  func spacesLeading(line: string): int =
    ## Count spaces line opens with.
    line.len - line.strip(trailing = false).len

  func isDeclaration(line: string): bool =
    ## Tell whether line opens routine, test or suite.
    let stripped = line.strip(trailing = false)
    declarations.anyIt stripped.startsWith(it)

  func signature(lines: openArray[string], first: int): (string, int) =
    ## Read declaration opening at `first`, continued while its brackets stay open.
    ##   Drop body, pragmas and comment, and fold whitespace.
    ##   Return signature and last line read.

    func depthAfter(text: string, depth: int): int =
      ## Count brackets left open after text, outside strings and backticks.
      result = depth
      var is_quoted, is_ticked = false
      for c in text:
        if c == '"' and not is_ticked: is_quoted = not is_quoted
        elif c == '`' and not is_quoted: is_ticked = not is_ticked
        elif is_quoted or is_ticked: continue
        elif c in {'(', '[', '{'}: inc result
        elif c in {')', ']', '}'}: dec result

    var
      text = lines[first].strip
      depth = depthAfter(text, 0)
      last = first
    while depth > 0 and last + 1 < lines.len:
      inc last
      text.add " " & lines[last].strip
      depth = depthAfter(lines[last], depth)
    var
      cut = text.len
      level = 0
      is_quoted, is_ticked = false
    for index, c in text:
      if c == '"' and not is_ticked: is_quoted = not is_quoted
      elif c == '`' and not is_quoted: is_ticked = not is_ticked
      elif is_quoted or is_ticked: continue
      elif c in {'(', '[', '{'}: inc level
      elif c in {')', ']', '}'}: dec level
      elif level == 0 and c == '#':
        cut = index
        break
      elif level == 0 and c == '=' and index > 0 and text[index-1] == ' ' and
          (index + 1 == text.len or text[index+1] == ' '):
        cut = index
        break
    var clean = text[0..<cut]
    while "{." in clean and ".}" in clean:
      let
        opening = clean.find("{.")
        closing = clean.find(".}", opening)
      if closing < 0: break
      clean = clean[0..<opening] & clean[closing+2 .. ^1]
    clean = clean.splitWhitespace.join(" ").replace("( ", "(").replace(" )", ")")
      .replace(";)", ")").replace(",)", ")")
    (clean.strip(chars = {' ', ':'}), last)

  func declared(text: string): seq[string] =
    ## Read signature of each declaration text holds, less those nested in another.
    let lines = text.splitLines
    var
      index = 0
      open_at = -1
    while index < lines.len:
      let line = lines[index]
      if line.strip.len > 0 and open_at >= 0 and line.spacesLeading <= open_at: open_at = -1
      if line.isDeclaration and open_at < 0:
        let (found, last) = signature(lines, index)
        result.add found
        open_at = line.spacesLeading
        index = last
      inc index

  func enclosing(source, quote: string; at: int): Option[string] =
    ## Read signature of declaration that line `at` of source sits in; none at top level.
    if at <= 0: return none(string)
    let lines = source.splitLines
    var level = high(int)
    for line in quote.splitLines:
      if line.strip.len > 0:
        level = line.spacesLeading
        break
    var index = at - 2
    while index >= 0 and level > 0:
      let line = lines[index]
      if line.strip.len > 0 and not line.strip.startsWith("#") and line.spacesLeading < level:
        if line.isDeclaration: return some(signature(lines, index)[0])
        if line.strip[0] in {')', ']', '}'}:
          # Header closing at its own indent, as `): untyped =`; its opening line is next above
          #   at same indent.
          var opening = index - 1
          while opening >= 0 and
              (lines[opening].strip.len == 0 or lines[opening].spacesLeading > line.spacesLeading):
            dec opening
          if opening >= 0 and lines[opening].isDeclaration:
            return some(signature(lines, opening)[0])
        level = line.spacesLeading
      dec index
    none(string)

  func htmlSignatures(label: string, signatures: openArray[string]): string =
    ## Render signatures under label; empty where none.
    if signatures.len == 0: return ""
    result = "<span class=\"signatures\"><span class=\"label\">" & label & "</span>"
    for found in signatures: result.add code(found)
    result.add "</span>"

  # Diff each edit against file as it finds it, earlier edits applied.
  var
    current = files
    paths: seq[string]
    diffs: Table[string, seq[LineDiffed]]
    sections: seq[string]
  for edit in change.edits:
    let
      before = current.getOrDefault(edit.path)
      is_applied = applyChange(current, Change(edits: @[edit]), "").len == 0
    var lines: seq[LineDiffed]
    case edit.kind
    of KindEdit.Add:
      lines = diffLines(@[], toLines(edit.replacement), 0, 1)
      sections.add "<details class=\"edit\" open><summary><span class=\"where\">adds " &
          code(edit.path) & " · " & textCounts(lines) & "</span>" &
          htmlSignatures("defines", declared(edit.replacement)) & "</summary>"
    of KindEdit.Replace:
      lines = diffLines(toLines(before), toLines(edit.replacement), 1, 1)
      let changed = block:  # Signatures absent from file it replaces: new or changed.
        let kept = declared(before)
        declared(edit.replacement).filterIt(it notin kept)
      sections.add "<details class=\"edit\" open><summary><span class=\"where\">replaces " &
          code(edit.path) & " whole, written against digest " & code(edit.digest) & " · " &
          textCounts(lines) & "</span>" & htmlSignatures("defines", changed) & "</summary>"
    of KindEdit.Quote:
      let
        at = if is_applied: before.lineQuoted(edit.quote) else: 0
        where = if at > 0: edit.path & ":" & $at else: edit.path  # quote gone from file
        defined = declared(edit.replacement)
        context =
          if defined.len > 0: htmlSignatures("defines", defined)
          else:
            let inside = enclosing(before, edit.quote, at)
            if inside.isSome: htmlSignatures("inside", [inside.get]) else: ""
      lines = diffLines(toLines(edit.quote), toLines(edit.replacement), at, at)
      sections.add "<details class=\"edit\" open><summary><span class=\"where\">" & code(where) &
          " · " & textCounts(lines) & "</span>" & context & "</summary>"
    sections[^1].add htmlDiff(lines) & "</details>"
    if edit.path notin diffs: paths.add edit.path
    diffs.mgetOrPut(edit.path, @[]).add lines

  # List files touched, each with lines removed and added, above edits.
  result = "<ul class=\"files\">"
  for path in paths: result.add "<li>" & code(path) & " " & textCounts(diffs[path]) & "</li>"
  result.add "</ul>" & sections.join


func htmlCode*(change: Change, files: Table[string, string]): string =
  ## Render change one block per file, closed, under its status and counts. Inside, each
  ##   definition change adds, removes or changes shows signature and doc, and folds body.
  ##   Lines in no definition follow, diffed, as other lines.
  ##   `files` is library as change finds it: pin, with bases of proposal applied.
  var after = files
  discard applyChange(after, change, "")  # Misfit is `drive`'s finding.
  var paths: seq[string]
  for edit in change.edits:
    if edit.path notin paths: paths.add edit.path

  for path in paths:
    let
      lines_before = toLines(files.getOrDefault(path))
      lines_after = toLines(after.getOrDefault(path))
      before = splitDefinitions(lines_before)
      later = splitDefinitions(lines_after)
      status =
        if path notin files: "added"
        elif change.edits.anyIt(it.path == path and it.kind == KindEdit.Replace): "replaced"
        else: "edited"
    var
      sections: seq[string]
      tally: array[3, int]  # Added, changed, removed.
      is_covered_before = newSeq[bool](lines_before.len)
      is_covered_after = newSeq[bool](lines_after.len)
    for definition in before:
      for index in definition.first ..< definition.first + definition.head.len +
          definition.doc.len + definition.body.len:
        is_covered_before[index] = true
    for definition in later:
      for index in definition.first ..< definition.first + definition.head.len +
          definition.doc.len + definition.body.len:
        is_covered_after[index] = true

    # Keep definitions that differ, each with how it changed.
    var shown: seq[(string, Definition, Definition)]  # Kind of change, before, after.
    for pair in pairDefinitions(before, later):
      let
        old = if pair.before >= 0: before[pair.before] else: Definition()
        now = if pair.after >= 0: later[pair.after] else: Definition()
      if pair.before >= 0 and pair.after >= 0 and old.head == now.head and old.doc == now.doc and
          old.body == now.body:
        continue
      let kind =
        if pair.before < 0: "added"
        elif pair.after < 0: "removed"
        else: "changed"
      inc tally[["added", "changed", "removed"].find(kind)]
      shown.add (kind, old, now)

    func isBare(definition: Definition): bool =
      ## Tell whether definition is one line of import or statement, with no doc or body.
      definition.kind in ["import", "statement"] and definition.head.len == 1 and
          definition.doc.len == 0 and definition.body.len == 0

    var index = 0
    while index < shown.len:
      let (kind, old, now) = shown[index]
      let
        definition = if kind == "removed": old else: now
        start_old = old.first + old.head.len + old.doc.len + 1  # Line body opens on.
        start_now = now.first + now.head.len + now.doc.len + 1
      var
        section = "<div class=\"definition " & kind & "\">"
        labels: seq[string]  # Change, where file holds more than additions, then context.
      if status != "added": labels.add "<span class=\"badge " & kind & "\">" & kind & "</span>"

      # Run of bare lines added or removed together shows as one block of its source lines.
      var last = index
      if kind != "changed" and definition.isBare:
        while last + 1 < shown.len and shown[last+1][0] == kind and
            (if kind == "added": shown[last+1][2] else: shown[last+1][1]).isBare and
            (if kind == "added": shown[last+1][2] else: shown[last+1][1]).context ==
                definition.context:
          inc last
      if definition.context.len > 0: labels.add "under " & code(definition.context)
      if labels.len > 0: section.add "<p class=\"where\">" & labels.join(" ") & "</p>"
      if last > index:
        let
          source = if kind == "added": lines_after else: lines_before
          final = (if kind == "added": shown[last][2] else: shown[last][1]).first
          lines = source[definition.first .. final]
        section.add(
          if kind == "added": renderFence(lines, "nim", definition.first + 1)
          else: htmlDiff(diffLines(lines, @[], definition.first + 1, 0), "nim")
        )
        sections.add section & "</div>"
        index = last + 1
        continue

      # Signature and doc: diffed where they changed, else as code.
      if kind == "changed" and (old.head != now.head or old.doc != now.doc):
        section.add htmlDiff(diffLines(old.head & old.doc, now.head & now.doc, old.first + 1,
            now.first + 1), "nim")
      elif kind == "removed":
        section.add htmlDiff(diffLines(old.head & old.doc, @[], old.first + 1, 0), "nim")
      else:
        section.add renderFence(now.head & now.doc, "nim", now.first + 1)

      # Body folds under count of its lines, and of lines it removes and adds.
      if old.body.len > 0 or now.body.len > 0:
        let (label, content) =
          case kind
          of "added": ("body · " & textLines(now.body.len), renderFence(now.body, "nim", start_now))
          of "removed":
            ("body · " & textLines(old.body.len),
              htmlDiff(diffLines(old.body, @[], start_old, 0), "nim"))
          elif old.body == now.body:
            ("body · " & textLines(now.body.len) & ", unchanged",
              renderFence(now.body, "nim", start_now))
          else:
            let lines = diffLines(old.body, now.body, start_old, start_now)
            ((if now.body.len == 0: "body removed · " else: "body · " & textLines(now.body.len) &
                " · ") & textCounts(lines), htmlDiff(lines, "nim"))
        section.add "<details class=\"body\"><summary>" & label & "</summary>" & content &
            "</details>"
      sections.add section & "</div>"
      inc index

    # Lines in no definition: comments, markers and `when` lines, numbered where they stand.
    var
      rest_before, rest_after: seq[string]
      numbers_before, numbers_after: seq[int]
    for index, line in lines_before:
      if not is_covered_before[index] and line.strip.len > 0:
        rest_before.add line
        numbers_before.add index + 1
    for index, line in lines_after:
      if not is_covered_after[index] and line.strip.len > 0:
        rest_after.add line
        numbers_after.add index + 1
    var rest = diffLines(rest_before, rest_after, 1, 1)
    for line in rest.mitems:
      if line.number_before > 0: line.number_before = numbers_before[line.number_before - 1]
      if line.number_after > 0: line.number_after = numbers_after[line.number_after - 1]
    if rest.anyIt(it.kind != KindLine.Kept):
      sections.add "<div class=\"definition other\"><p class=\"where\">" &
          "<span class=\"badge\">other lines</span> comments, markers and " & code("when") &
          " lines</p>" &
          htmlDiff(rest, "nim") & "</div>"

    var parts: seq[string]
    if status == "added":
      parts.add $tally[0] & (if tally[0] == 1: " definition" else: " definitions")
    else:
      for (count, word) in [(tally[1], "changed"), (tally[0], "added"), (tally[2], "removed")]:
        if count > 0: parts.add $count & " " & word
    result.add "<details class=\"file\"><summary>" & code(path) & " <span class=\"status\">" &
        status & "</span> <span class=\"tally\">" & parts.join(" · ") & "</span> " &
        textCounts(diffLines(lines_before, lines_after, 1, 1)) & "</summary>" &
        "<div class=\"definitions\">" & sections.join & "</div></details>"


func textSpread*(spread: Spread): string =
  ## State spread, and where it was read from.
  if spread.count == 0:
    "Times outside ×" & spread.low.fixed & " to ×" & spread.high.fixed & " count as moved. " &
        "That spread is assumed, since too few evaluations here change nothing."
  else:
    "Times outside ×" & spread.low.fixed & " to ×" & spread.high.fixed & " count as moved. " &
        "That spread holds 90% of " & $spread.count &
        " time ratios in evaluations that change no " &
        "library function."
