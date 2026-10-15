## Render what evaluation measured, and edits it tried, for marginalia and proposal pages alike.
##   Both pages show proposed change against pin, so both render it one way: suites beside
##     pin's own, functions whose counts moved, times of measurands those functions serve, and
##     edits as diff of lines against file each edit finds.
##   Edits open under list of files they touch, each with lines removed and added. Each edit's
##     summary names file and line, then signatures of routines, tests and suites edit defines,
##     else of one it sits in, so reader sees what changes before reading how. Body, pragmas and
##     comments leave signature.
##   Diff numbers each line on side it stands on: before edit and after it, in file as edit finds
##     it. Bases of proposal and earlier edits apply first, so number is one reader finds in
##     library carrying them. Unchanged run longer than twice context folds to count of lines.
##   Spread is read from evaluations themselves: evaluation that changes no library function
##     moves no count, so range of its time ratios is range of machine, and page states it
##     beside figures it qualifies.
##
##   Cost: measurand counts as touched where its library function moved; measurand served by
##     composition of several functions is left out, as `timesOf` leaves it out of median.
##   Cost: diff takes table of common lengths over lines between shared head and tail, so whole-
##     file replacement of about thousand changed lines holds about million counts while page
##     builds.

{.experimental: "strictFuncs".}

import std/[algorithm, json, options, sequtils, strutils, tables]

import ../[changes, markdown]
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


func spreadOf*(evaluations: openArray[JsonNode]): Spread =
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
    for _, shares in measured{"nan"}.pairs:
      let (before, after) = (shares[0].getFloat, shares[1].getFloat)
      if before > 0 and after == 0: inc result[0]
      if before == 0 and after > 0: inc result[1]

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


func diffLines(before, after: seq[string]; first_before, first_after: int): seq[LineDiffed] =
  ## Diff lines through longest common subsequence; removal stands before addition it pairs with.
  ##   `first_before` and `first_after` number first line of each side; zero leaves side bare.

  func numberOf(first, index: int): int =
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
      number_before: numberOf(first_before, index),
      number_after: numberOf(first_after, index),
    )
  var (i, j) = (0, 0)
  while i < count_before or j < count_after:
    if i < count_before and j < count_after and before[head+i] == after[head+j]:
      result.add LineDiffed(
        kind: KindLine.Kept,
        text: before[head+i],
        number_before: numberOf(first_before, head + i),
        number_after: numberOf(first_after, head + j),
      )
      inc i
      inc j
    elif i < count_before and
        (j == count_after or lengths[(i+1)*width+j] >= lengths[i*width+j+1]):
      result.add LineDiffed(
        kind: KindLine.Removed,
        text: before[head+i],
        number_before: numberOf(first_before, head + i),
      )
      inc i
    else:
      result.add LineDiffed(
        kind: KindLine.Added,
        text: after[head+j],
        number_after: numberOf(first_after, head + j),
      )
      inc j
  for index in 0..<tail:
    result.add LineDiffed(
      kind: KindLine.Kept,
      text: before[before.len-tail+index],
      number_before: numberOf(first_before, before.len - tail + index),
      number_after: numberOf(first_after, after.len - tail + index),
    )


func htmlDiff(lines: seq[LineDiffed]): string =
  ## Render diff as numbered lines, each unchanged run past context folded to its count.

  func cellOf(number: int): string =
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
    result.add "<tr class=\"" & row & "\">" & cellOf(lines[index].number_before) &
        cellOf(lines[index].number_after) & "<td class=\"sign\">" & sign &
        "</td><td class=\"text\">" & escapeHtml(lines[index].text) & "</td></tr>"
    inc index
  result.add "</table></div>"


func htmlEdits*(change: Change, files: Table[string, string]): string =
  ## Render files change touches, then each edit open as diff, under summary naming where it lands.
  ##   `files` is library as change finds it: pin, with bases of proposal applied.
  ##   Summary names signatures edit defines or sits in.
  const declarations = ["func ", "proc ", "iterator ", "template ", "macro ", "method ",
    "converter ", "suite ", "test "]
    ## Words opening declaration whose signature summary shows.

  func indentOf(line: string): int =
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
      if line.strip.len > 0 and open_at >= 0 and line.indentOf <= open_at: open_at = -1
      if line.isDeclaration and open_at < 0:
        let (found, last) = signature(lines, index)
        result.add found
        open_at = line.indentOf
        index = last
      inc index

  func enclosing(source, quote: string; at: int): Option[string] =
    ## Read signature of declaration that line `at` of source sits in; none at top level.
    if at <= 0: return none(string)
    let lines = source.splitLines
    var level = high(int)
    for line in quote.splitLines:
      if line.strip.len > 0:
        level = line.indentOf
        break
    var index = at - 2
    while index >= 0 and level > 0:
      let line = lines[index]
      if line.strip.len > 0 and not line.strip.startsWith("#") and line.indentOf < level:
        if line.isDeclaration: return some(signature(lines, index)[0])
        if line.strip[0] in {')', ']', '}'}:
          # Header closing at its own indent, as `): untyped =`; its opening line is next above
          #   at same indent.
          var opening = index - 1
          while opening >= 0 and
              (lines[opening].strip.len == 0 or lines[opening].indentOf > line.indentOf):
            dec opening
          if opening >= 0 and lines[opening].isDeclaration:
            return some(signature(lines, opening)[0])
        level = line.indentOf
      dec index
    none(string)

  func htmlSignatures(label: string, signatures: openArray[string]): string =
    ## Render signatures under label; empty where none.
    if signatures.len == 0: return ""
    result = "<span class=\"signatures\"><span class=\"label\">" & label & "</span>"
    for found in signatures: result.add code(found)
    result.add "</span>"

  func linesOf(text: string): seq[string] =
    ## Split text into lines, one closing line break dropped; empty text holds none.
    if text.len == 0: return
    (if text.endsWith("\n"): text[0 .. ^2] else: text).splitLines

  func textCounts(lines: seq[LineDiffed]): string =
    ## Count lines removed and added, as `-2 +5`.
    "<span class=\"removed\">-" & $lines.countIt(it.kind == KindLine.Removed) &
        "</span> <span class=\"added\">+" & $lines.countIt(it.kind == KindLine.Added) & "</span>"

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
      lines = diffLines(@[], linesOf(edit.replacement), 0, 1)
      sections.add "<details class=\"edit\" open><summary><span class=\"where\">adds " &
          code(edit.path) & " · " & textCounts(lines) & "</span>" &
          htmlSignatures("defines", declared(edit.replacement)) & "</summary>"
    of KindEdit.Replace:
      lines = diffLines(linesOf(before), linesOf(edit.replacement), 1, 1)
      let changed = block:  # Signatures absent from file it replaces: new or changed.
        let kept = declared(before)
        declared(edit.replacement).filterIt(it notin kept)
      sections.add "<details class=\"edit\" open><summary><span class=\"where\">replaces " &
          code(edit.path) & " whole, written against digest " & code(edit.digest) & " · " &
          textCounts(lines) & "</span>" & htmlSignatures("defines", changed) & "</summary>"
    of KindEdit.Quote:
      let
        at = if is_applied: before.lineOf(edit.quote) else: 0
        where = if at > 0: edit.path & ":" & $at else: edit.path  # quote gone from file
        defined = declared(edit.replacement)
        context =
          if defined.len > 0: htmlSignatures("defines", defined)
          else:
            let inside = enclosing(before, edit.quote, at)
            if inside.isSome: htmlSignatures("inside", [inside.get]) else: ""
      lines = diffLines(linesOf(edit.quote), linesOf(edit.replacement), at, at)
      sections.add "<details class=\"edit\" open><summary><span class=\"where\">" & code(where) &
          " · " & textCounts(lines) & "</span>" & context & "</summary>"
    sections[^1].add htmlDiff(lines) & "</details>"
    if edit.path notin diffs: paths.add edit.path
    diffs.mgetOrPut(edit.path, @[]).add lines

  # List files touched, each with lines removed and added, above edits.
  result = "<ul class=\"files\">"
  for path in paths: result.add "<li>" & code(path) & " " & textCounts(diffs[path]) & "</li>"
  result.add "</ul>" & sections.join


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
