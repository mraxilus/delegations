## Render what trial measured, and edits it tried, for marginalia and design pages alike.
##   Both pages show proposed change against pin, so both render it one way: suites beside
##     pin's own, functions whose counts moved, times of measurands those functions serve, and
##     edits as quote and replacement at line quote stands on at pin.
##   Noise band is read from trials themselves: trial that changes no library function moves
##     no count, so spread of its times is spread of machine, and page states it beside figures
##     it qualifies.
##
##   Cost: measurand counts as touched where its library function moved; measurand served by
##     composition of several functions is left out, as `timesOf` leaves it out of median.

{.experimental: "strictFuncs".}

import std/[algorithm, json, strutils, tables]

import ../[changes, markdown]
import ./shell


type Band* = object
  ## Define spread of times in trials that change no library function.
  low*, high*: float
    ## Fifth and ninety-fifth percentile of ratio, each measurand alone.
  count*: int
    ## Ratios band is read from.


const DEFAULT_BAND = Band(low: 0.92, high: 1.08, count: 0)
  ## Band assumed where no trial changes nothing; stated as assumed on page.



#[ Figures ]#

func touched*(trial: JsonNode, baselines: Table[string, JsonNode], algebra: string): seq[string] =
  ## List measurands whose library function trial changed, at one algebra.
  let
    changed = trial{"algebras", algebra, "functions"}
    measurands = baselines.getOrDefault(algebra){"measurands"}
  if changed.isNil or measurands.isNil: return
  for id, m in measurands.pairs:
    if changed.hasKey(m{"library"}.getStr): result.add id


func bandOf*(trials: openArray[JsonNode]): Band =
  ## Read noise band from trials that change no library function at any algebra.
  var ratios: seq[float]
  for trial in trials:
    var is_quiet = true
    for _, a in trial{"algebras"}.pairs:
      if a{"functions"}.len > 0: is_quiet = false
    if not is_quiet: continue
    for _, a in trial{"algebras"}.pairs:
      for _, t in a{"times"}.pairs: ratios.add t[2].getFloat
  if ratios.len < 20: return DEFAULT_BAND
  ratios.sort
  Band(low: ratios[ratios.len div 20], high: ratios[ratios.len - 1 - ratios.len div 20],
    count: ratios.len)


func medianOf(values: seq[float]): float =
  ## Read median; zero for none.
  if values.len == 0: return 0.0
  let sorted = values.sorted
  if sorted.len mod 2 == 1: sorted[sorted.len div 2]
  else: (sorted[sorted.len div 2 - 1] + sorted[sorted.len div 2]) / 2.0


func touchedMedian*(trial: JsonNode, baselines: Table[string, JsonNode], algebra: string): float =
  ## Read median time ratio over measurands trial touched at algebra; zero where none.
  var ratios: seq[float]
  let times = trial{"algebras", algebra, "times"}
  for id in touched(trial, baselines, algebra):
    if not times.isNil and times.hasKey(id): ratios.add times[id][2].getFloat
  medianOf(ratios)



#[ Rendering ]#

func suitesText(trial: JsonNode, algebra: string): string =
  ## Render suites passed over run, with pin's beside where they differ.
  let
    s = trial{"algebras", algebra, "suites"}
    p = trial{"pin_suites", algebra}
    run = s{"ok"}.getInt + s{"failed"}.getInt
  result = $s{"ok"}.getInt & "/" & $run
  if not p.isNil and (p{"ok"}.getInt != s{"ok"}.getInt or p{"failed"}.getInt != s{"failed"}.getInt):
    result.add " (pin " & $p{"ok"}.getInt & "/" & $(p{"ok"}.getInt + p{"failed"}.getInt) & ")"


func nanMoved(a: JsonNode): (int, int) =
  ## Count measurands whose NaN results trial removed, and those it introduced.
  for _, shares in a{"nan"}.pairs:
    let (before, after) = (shares[0].getFloat, shares[1].getFloat)
    if before > 0 and after == 0: inc result[0]
    if before == 0 and after > 0: inc result[1]


func verdictChips*(trial: JsonNode, baselines: Table[string, JsonNode], band: Band): string =
  ## Render one chip per algebra: suites, then median time over what trial touched.
  if trial.isNil: return chip("no trial", "fail")
  for algebra, a in trial{"algebras"}.pairs:
    let
      failed = a{"suites", "failed"}.getInt
      pin_failed = trial{"pin_suites", algebra, "failed"}.getInt
      (gone, came) = nanMoved(a)
      kind = if failed > pin_failed or came > 0: "fail" else: "pass"
      median = touchedMedian(trial, baselines, algebra)
    var text = algebra & " suites " & suitesText(trial, algebra)
    if a{"functions"}.len > 0: text.add " · " & $a{"functions"}.len & " functions moved"
    if gone > 0: text.add " · NaN gone in " & $gone
    if came > 0: text.add " · NaN new in " & $came
    if median > 0:
      let side = if median < band.low: "fast" elif median > band.high: "slow" else: "flat"
      result.add chip(text & " · " & ratioText(median), kind & " " & side)
    else:
      result.add chip(text, kind)


func transition(before, after: JsonNode, field: string): string =
  ## Render one count at pin, then changed; `new` or `gone` where function is on one side.
  let
    was = if before.isNil or before.kind != JObject: "new" else: grouped(before{field}.getInt)
    now = if after.isNil or after.kind != JObject: "gone" else: grouped(after{field}.getInt)
  was & " → " & now


func functionsTable*(trial: JsonNode): string =
  ## Render functions trial moved: multiplies, bytes and fills, pin then changed.
  for algebra, a in trial{"algebras"}.pairs:
    let changed = a{"functions"}
    if changed.isNil or changed.len == 0: continue
    result.add "<div class=\"table\"><table><caption>" & algebra & ": functions whose counts " &
      "moved</caption><tr><th>Function</th><th>Multiplies</th><th>Bytes moved</th>" &
      "<th>Zero fills</th></tr>"
    for key, pair in changed.pairs:
      let (before, after) = (pair{"before"}, pair{"after"})
      result.add "<tr><td>" & code(key) & "</td><td>" &
        transition(before, after, "multiplies") & "</td><td>" &
        transition(before, after, "bytes_moved") & "</td><td>" &
        transition(before, after, "zero_fills") & "</td></tr>"
    result.add "</table></div>"


func timesTable*(trial: JsonNode, baselines: Table[string, JsonNode], band: Band): string =
  ## Render measurands trial touched, pin's time then changed time, per algebra.
  for algebra, a in trial{"algebras"}.pairs:
    let ids = touched(trial, baselines, algebra)
    if ids.len == 0: continue
    result.add "<div class=\"table\"><table><caption>" & algebra & ": time of measurands whose " &
      "function moved, ns</caption><tr><th>Measurand</th><th>Pin</th><th>Changed</th>" &
      "<th>Ratio</th></tr>"
    for id in ids:
      let t = a{"times", id}
      if t.isNil: continue
      let
        ratio = t[2].getFloat
        side = if ratio < band.low: "fast" elif ratio > band.high: "slow" else: "flat"
      result.add "<tr class=\"" & side & "\"><td>" & escapeHtml(id) & "</td><td>" &
        t[0].getFloat.fixed(1) & "</td><td>" & t[1].getFloat.fixed(1) & "</td><td>" &
        ratioText(ratio) & "</td></tr>"
    result.add "</table></div>"


func nanTable*(trial: JsonNode): string =
  ## Render measurands whose share of NaN results trial moved, pin's then changed, per algebra.
  for algebra, a in trial{"algebras"}.pairs:
    let shares = a{"nan"}
    if shares.isNil or shares.len == 0: continue
    result.add "<div class=\"table\"><table><caption>" & algebra & ": share of results that " &
      "are NaN</caption><tr><th>Measurand</th><th>Pin</th><th>Changed</th></tr>"
    for id, pair in shares.pairs:
      result.add "<tr><td>" & escapeHtml(id) & "</td><td>" & pair[0].getFloat.fixed(3) &
        "</td><td>" & pair[1].getFloat.fixed(3) & "</td></tr>"
    result.add "</table></div>"


func editsHtml*(change: Change, files: Table[string, string]): string =
  ## Render each edit: file and line at pin, quote then replacement; whole file collapsed.
  for edit in change.edits:
    if edit.digest.len > 0:
      let lines = edit.replacement.count('\n')
      result.add "<details class=\"edit\"><summary>replaces " & code(edit.path) & " whole, " &
        $lines & " lines, written against digest " & code(edit.digest) & "</summary>" &
        renderFence(edit.replacement.strip(leading = false).splitLines, "nim", 1) & "</details>"
      continue
    let at = if edit.path in files: files[edit.path].lineOf(edit.quote) else: 0
    result.add "<div class=\"edit\"><p class=\"where\">" & code(edit.path & ":" & $at) &
      "</p><div class=\"pair\"><div><p class=\"label\">at pin</p>" &
      renderFence(edit.quote.splitLines, "nim", at) & "</div><div><p class=\"label\">" &
      "proposed</p>" & renderFence(edit.replacement.splitLines, "nim") & "</div></div></div>"


func bandText*(band: Band): string =
  ## State noise band and where it was read from.
  if band.count == 0:
    "Times outside ×" & band.low.fixed & " to ×" & band.high.fixed & " count as moved; that " &
      "band is assumed, since no trial here changes nothing."
  else:
    "Times outside ×" & band.low.fixed & " to ×" & band.high.fixed & " count as moved: that " &
      "is 90% of " & $band.count & " measurand ratios in trials that change no library function."
