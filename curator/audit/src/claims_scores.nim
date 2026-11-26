## Score each claim of logs of claims as Metaculus does, and give figures of each group (#964).
##   Baseline score of claim is `100 × (ln p − ln 0.5) / ln 2`, as #964 gives it: `p` is
##     confidence of hit and one minus it of miss; claim annulled, waiting or unmarked takes none,
##     and so does confidence outside 0 to 1, which no cell gives.
##   Number scores as Metaculus scores continuous question, from its source at `8e413fb`, as `D2 a`
##     of #964 rules (comment 7189788889); so it takes no baseline score, and no band.
##   Unit opens text of number, as `tokens`, and fixes range on logarithm with both bounds open:
##     its curve runs straight between percentiles at 201 places (`generateQuantileContinuousCdf`),
##     takes floor of 1% of even spread and cap of 0.2 for each of 200 buckets (`standardizeCdf`),
##     and scores `100 × ln(m / b) / 2` for mass `m` of bucket of outcome (`score_math.py`).
##   Confidence of number is mass between its outer two percentiles, so it places them: 5th and
##     95th at 0.9, as Architect asks on #964 (comment 7191274618), and 10th and 90th at 0.8 of
##     earlier row.
##   Track record counts claims of each band of confidence, from 51% to 60% and on in steps of 10
##     to 98%, by percentage rounded; claim under 50% first turns to its other side, so hit at 20%
##     counts as miss at 80%, as `D3 c` of #964 rules (comment 7191274618); confidence of 50% or
##     above 98% falls in nearest band.
##   Each band gives count, share of hits, and 90% credible band of share: 5th and 95th
##     percentiles of Beta posterior from uniform prior, `Beta(hits + 1, misses + 1)`.
##   Group holds claims whose named fields agree, sorted by key; each figure names its count.
##   Mass of Beta comes from continued fraction of incomplete Beta (Numerical Recipes, 3rd
##     edition, 6.4), by modified Lentz method, and percentile from bisection on that mass.
##
##   Cost: each percentile takes `ITERATIONS_BISECTION` masses of up to `ITERATIONS_FRACTION`
##           terms each.

{.experimental: "strictFuncs".}

import std/[algorithm, math, options, sequtils, strformat, strutils, tables]
import ./claims_log


type
  Field* {.pure.} = enum  ## Define field of claim that groups claims (#964).
    Delegate  ## `sessionId` of delegate whose reflection gives claim.
    Model  ## Model of call claim takes.
    Effort  ## Effort of call claim takes.
    Project  ## Role of branch that wrote row of claim.
    Kind  ## Kind of subagent of call claim takes.
    Marker  ## Who marked state of claim, delegate or resolver.

  Band* = object  ## Define band of confidence of track record, and claims that fall in it.
    low*: int  ## Lowest percentage of band.
    high*: int  ## Highest percentage of band.
    count*: int  ## Claims of band that take score.
    hits*: int  ## Claims of band that hold.
    confidence*: float  ## Mean confidence of claims of band.
    share*: float  ## Share of claims of band that hold.
    share_low*: float  ## 5th percentile of share, of its Beta posterior.
    share_high*: float  ## 95th percentile of share, of its Beta posterior.

  Figures* = object  ## Define figures of claims: their scores and their track record.
    count*: int  ## Claims that take score: hits and misses.
    hits*: int  ## Claims that hold.
    score*: float  ## Mean baseline score; NaN where no claim takes score.
    count_number*: int  ## Numbers that take score as continuous question.
    score_number*: float  ## Mean score of numbers; NaN where none takes score.
    bands*: seq[Band]  ## Bands of confidence that hold claims, from lowest.

  Unit* = object  ## Define unit of number, and range code fixes for it, as writer of question does.
    name*: string  ## Word that opens text of number in unit, as `tokens`.
    low*: float  ## Lower bound of range, open.
    high*: float  ## Upper bound of range, open.

  Point = object  ## Define point that curve of forecast passes through.
    percent: float  ## Percent of mass at or below place.
    place: float  ## Place in range, from 0 at lower bound to 1 at upper.

  Group* = object  ## Define claims whose named fields agree.
    key*: string  ## Values of named fields, in order of `Field`, by `SEPARATOR_KEY`.
    claims*: seq[Claim]  ## Claims of group, in order of log.

const
  CONFIDENCE_EVEN = 0.5  ## Confidence of coin, against which baseline score counts.
  SCALE_SCORE = 100.0  ## Points of baseline score for each bit above coin (#964).
  BANDS_PERCENT = [(51, 60), (61, 70), (71, 80), (81, 90), (91, 98)]
    ## Bands of confidence of track record, in percent, each bound inside (#964).
  PERCENT = 100.0  ## Percentage of confidence of one.
  PERCENT_MEDIAN = 50.0  ## Percent of mass at or below median of number.
  MASS_CREDIBLE = 0.9  ## Mass of credible band of share (#964).
  PRIOR_HITS = 1.0  ## Hits of uniform prior of share, `Beta(1, 1)`.
  PRIOR_MISSES = 1.0  ## Misses of uniform prior of share.
  ITERATIONS_FRACTION = 300  ## Most terms of continued fraction (Numerical Recipes, 6.4).
  ITERATIONS_BISECTION = 100  ## Halvings of percentile of Beta: interval below `2^-100`.
  EPSILON_FRACTION = 1e-15  ## Change of continued fraction below which it ends.
  FLOOR_FRACTION = 1e-300  ## Least divisor of Lentz method, so that none is zero.
  SEPARATOR_KEY* = " / "  ## Mark between values of key of group.
  KEY_ALL = "all"  ## Key that line of figures gives group of all claims.
  KIND_NONE = "call of no kind"  ## Name that base rate gives kind of call that names none.
  NAMES_FIELD: array[Field, string] = ["delegate", "model", "effort", "project", "kind", "marker"]
    ## Name of each field, as verb `figures` reads it.
  UNITS* = [
    Unit(name: "tokens", low: 1e4, high: 1e9),
    Unit(name: "cost", low: 0.01, high: 1000),
  ]  ## Range of each unit, on logarithm with both bounds open (`D2 a` of #964).
  COUNT_BUCKETS = 200  ## Inner buckets of curve, as `DEFAULT_INBOUND_OUTCOME_COUNT` of Metaculus.
  SHARE_FORECAST = 0.988  ## Share of forecast in curve with both bounds open (`standardizeCdf`).
  SHARE_EVEN = 0.01  ## Share of even spread that floor mixes into curve (`standardizeCdf`).
  MASS_OPEN = 0.001  ## Least mass beyond each open bound (`standardizeCdf`).
  CAP_BUCKET = 0.2  ## Most mass of inner bucket (`standardizeCdf`).
  STEP_SEARCH = 1.2  ## Growth of upper end of search of scale under cap (`standardizeCdf`).
  ITERATIONS_SEARCH = 100  ## Most halvings of search of scale under cap.
  EPSILON_SEARCH = 2e-5  ## Width of search of scale below which it ends.
  DIGITS_ROUND = 1e10  ## Places of curve kept, as `standardizeCdf` rounds to 10.
  EPSILON_BUCKET = 1e-10  ## Nudge below edge of bucket (`unscaled_location_to_bucket_index`).
  BASELINE_OUTSIDE = 0.05  ## Baseline mass of bucket beyond range (`score_math.py`).
  COUNT_OPEN = 2  ## Open bounds of each range of `UNITS`.
  DIVISOR_NUMBER = 2.0  ## Divisor of score of continuous question (`score_math.py`, line 103).


func scoreBaseline*(claim: Claim): Option[float] =
  ## Baseline score of claim of yes or no, `100 × (ln p − ln 0.5) / ln 2` (#964): `p` is its
  ##   confidence for hit, and one minus it for miss; none for number, for claim annulled, waiting
  ##   or unmarked, or at confidence outside 0 to 1.
  let confidence = claim.confidence
  if claim.number.isSome or confidence <= 0 or confidence >= 1: return none(float)
  case claim.state
  of State.Hit: some(SCALE_SCORE * (ln(confidence) - ln(CONFIDENCE_EVEN)) / ln(2.0))
  of State.Miss: some(SCALE_SCORE * (ln(1 - confidence) - ln(CONFIDENCE_EVEN)) / ln(2.0))
  of State.Annulled, State.Waiting, State.Unspecified: none(float)


func flooredFraction(value: float): float =
  ## Value, else `FLOOR_FRACTION` where it lies nearer zero, as Lentz method asks.
  if abs(value) < FLOOR_FRACTION: FLOOR_FRACTION else: value


func fractionBeta(x, a, b: float): float =
  ## Continued fraction of incomplete Beta at `x` (Numerical Recipes, 3rd edition, 6.4), by
  ##   modified Lentz method; converges fast for `x` below `(a + 1) / (a + b + 2)`.
  let
    sum = a + b
    above = a + 1
    below = a - 1
  var
    c = 1.0
    d = 1 / flooredFraction(1 - sum * x / above)
  result = d
  for m in 1..ITERATIONS_FRACTION:
    let
      step = float(m)
      even = step * (b - step) * x / ((below + 2 * step) * (a + 2 * step))
    d = 1 / flooredFraction(1 + even * d)
    c = flooredFraction(1 + even / c)
    result *= d * c
    let odd = -(a + step) * (sum + step) * x / ((a + 2 * step) * (above + 2 * step))
    d = 1 / flooredFraction(1 + odd * d)
    c = flooredFraction(1 + odd / c)
    let change = d * c
    result *= change
    if abs(change - 1) < EPSILON_FRACTION: break


func massBeta*(x, a, b: float): float =
  ## Mass of `Beta(a, b)` at or below `x`: regularized incomplete Beta `I_x(a, b)`, from
  ##   continued fraction on side where it converges fast (Numerical Recipes, 3rd edition, 6.4).
  if x <= 0: return 0
  if x >= 1: return 1
  let front = exp(lgamma(a + b) - lgamma(a) - lgamma(b) + a * ln(x) + b * ln(1 - x))
  if x < (a + 1) / (a + b + 2): front * fractionBeta(x, a, b) / a
  else: 1 - front * fractionBeta(1 - x, b, a) / b


func percentileBeta*(mass, a, b: float): float =
  ## Value at or below which `Beta(a, b)` holds `mass`, by bisection on `massBeta`.
  var
    low = 0.0
    high = 1.0
  for _ in 1..ITERATIONS_BISECTION:
    let middle = (low + high) / 2
    if massBeta(middle, a, b) < mass: low = middle else: high = middle
  (low + high) / 2


func unitClaim*(claim: Claim): Option[Unit] =
  ## Unit of `UNITS` whose name opens text of claim, past its label; none where none does.
  let
    text = claim.text.toLowerAscii
    colon = text.find(": ")
  for opening in [text, (if colon >= 0: text[colon+2 .. ^1] else: "")]:
    for unit in UNITS:
      if opening.startsWith(unit.name & " "): return some(unit)
  none(Unit)


func place(value: float, unit: Unit): float =
  ## Place of value in range of unit, on logarithm, by formula of Metaculus for zero point 0, whose
  ##   rounding decides where place meets one of curve (`nominalLocationToCdfLocation`): below 0
  ##   or above 1 beyond range, and -1 for value of no logarithm.
  if value <= 0: return -1
  let ratio = unit.high / unit.low
  (ln((value - unit.low) * (ratio - 1) + (unit.high - unit.low)) - ln(unit.high - unit.low)) /
      ln(ratio)


func hydrated(points: openArray[Point], places: openArray[float]): seq[Point] =
  ## Points, each that falls between places replaced by two on places around it, on mean slope of
  ##   its two sides, so that curve passes through it (`hydrateQuantiles`).
  for i, point in points:
    if point.place in places:
      result.add point
      continue
    if i == 0 or i == points.high: continue
    let
      before = points[i-1]
      after = points[i+1]
      slope = ((point.percent - before.percent) / (point.place - before.place) +
        (after.percent - point.percent) / (after.place - point.place)) / 2
      intercept = point.percent - slope * point.place
    var
      low = 0.0
      high = 0.0
    for at in countdown(places.high, 0):
      if places[at] < point.place:
        low = places[at]
        break
    for at in places:
      if at > point.place:
        high = at
        break
    result.add Point(percent: slope * low + intercept, place: low)
    result.add Point(percent: slope * high + intercept, place: high)


func curveNumber(number: Number, unit: Unit, confidence: float): seq[float] =
  ## Mass at or below each of `COUNT_BUCKETS + 1` places of range, straight between percentiles,
  ##   with no mass beyond range before floor (`generateQuantileContinuousCdf`); confidence is mass
  ##   between outer two percentiles, so 0.9 places them at 5th and 95th.
  let tail = (PERCENT - confidence * PERCENT) / 2  # Percent of mass below lowest percentile.
  var points: seq[Point]
  for (percent, value) in [(tail, number.low), (PERCENT_MEDIAN, number.median),
      (PERCENT - tail, number.high)]:
    let at = value.place(unit)
    if 0 < at and at < 1: points.add Point(percent: percent, place: at)
  points.add Point(percent: 0, place: 0)
  points.add Point(percent: PERCENT, place: 1)
  points.sort(proc (a, b: Point): int = cmp(a.place, b.place))
  let
    places = toSeq(0..COUNT_BUCKETS).mapIt(float(it) / float(COUNT_BUCKETS))
    through = points.hydrated(places)
  for at in places:
    for k in 1..through.high:
      let (before, after) = (through[k-1], through[k])
      if before.place <= at and at <= after.place:
        result.add (before.percent + (after.percent - before.percent) * (at - before.place) /
          (after.place - before.place)) / PERCENT
        break


func massesCapped(masses: openArray[float], scale: float): seq[float] =
  ## Masses, each inner one scaled and held at most `CAP_BUCKET`, and two beyond range as they are.
  for i, mass in masses:
    result.add (if i == 0 or i == masses.high: mass else: min(CAP_BUCKET, scale * mass))


func massesCurve(curve: openArray[float]): seq[float] =
  ## Mass below range, of each inner bucket, and above range, of curve (`get_pmf`).
  result.add curve[0]
  for i in 1..curve.high: result.add curve[i] - curve[i-1]
  result.add 1 - curve[^1]


func flooredCurve(curve: openArray[float]): seq[float] =
  ## Curve with floor of Metaculus for both bounds open: 1% of even spread mixed in, least mass
  ##   beyond each bound, and inner buckets held under cap by search of scale (`standardizeCdf`).
  var mixed: seq[float]
  for i, mass in curve:
    mixed.add SHARE_FORECAST * mass + SHARE_EVEN * float(i) / float(curve.high) + MASS_OPEN
  let masses = mixed.massesCurve
  var
    low = 1.0
    high = 1.0
    scale = 1.0
  while masses.massesCapped(high).sum < 1: high *= STEP_SEARCH
  for _ in 1..ITERATIONS_SEARCH:
    scale = (low + high) / 2
    let total = masses.massesCapped(scale).sum
    if total < 1: low = scale else: high = scale
    if total == 1 or high - low < EPSILON_SEARCH: break
  var capped = masses.massesCapped(scale)
  let factor = (mixed[^1] - mixed[0]) / capped[1..<capped.high].sum
  for i in 1..<capped.high: capped[i] *= factor
  var total = 0.0
  for i in 0..<capped.high:
    total += capped[i]
    result.add floor(total * DIGITS_ROUND + 0.5) / DIGITS_ROUND


func bucketPlace(at: float): int =
  ## Bucket of place: 0 below range, `COUNT_BUCKETS + 1` above, else its inner bucket from 1
  ##   (`unscaled_location_to_bucket_index`).
  if at < 0: return 0
  if at > 1: return COUNT_BUCKETS + 1
  if at == 1: return COUNT_BUCKETS
  max(int(at * float(COUNT_BUCKETS) + 1 - EPSILON_BUCKET), 1)


func scoreNumber*(claim: Claim): Option[float] =
  ## Score of number as Metaculus scores continuous question, `100 × ln(m / b) / 2`: `m` is mass of
  ##   bucket of outcome, and `b` even share of inner mass, or 0.05 beyond range; none for claim of
  ##   no number, outcome, unit or mark, of confidence outside 0 to 1, or whose percentiles do not
  ##   rise.
  if claim.number.isNone or claim.state notin {State.Hit, State.Miss}: return none(float)
  if claim.confidence <= 0 or claim.confidence >= 1: return none(float)
  let
    number = claim.number.get
    unit = claim.unitClaim
  if number.outcome.isNone or unit.isNone: return none(float)
  if not (number.low < number.median and number.median < number.high): return none(float)
  let curve = number.curveNumber(unit.get, claim.confidence)
  if curve.len != COUNT_BUCKETS + 1: return none(float)
  let
    masses = curve.flooredCurve.massesCurve
    bucket = number.outcome.get.place(unit.get).bucketPlace
    baseline = (if bucket == 0 or bucket == COUNT_BUCKETS + 1: BASELINE_OUTSIDE
      else: (1 - BASELINE_OUTSIDE * float(COUNT_OPEN)) / float(COUNT_BUCKETS))
  some(SCALE_SCORE * ln(masses[bucket] / baseline) / DIVISOR_NUMBER)


func indexBand(confidence: float): int =
  ## Index of band of confidence in `BANDS_PERCENT`, by percentage rounded; nearest band where it
  ##   falls outside each.
  let percent = int(round(confidence * PERCENT))
  for i, (low, high) in BANDS_PERCENT:
    if percent <= high: return i
  BANDS_PERCENT.high


func bands*(claims: openArray[Claim]): seq[Band] =
  ## Bands of confidence of claims that take score, each that holds claim, from lowest, with
  ##   share of hits and its credible band (#964); claim under 50% counts as its other side, at one
  ##   minus its confidence, with hit and miss swapped (`D3 c`), which keeps its baseline score.
  var
    counts: array[BANDS_PERCENT.len, int]
    hits: array[BANDS_PERCENT.len, int]
    sums: array[BANDS_PERCENT.len, float]
  for claim in claims:
    if claim.scoreBaseline.isNone: continue
    let
      is_turned = claim.confidence < CONFIDENCE_EVEN
      confidence = (if is_turned: 1 - claim.confidence else: claim.confidence)
      i = confidence.indexBand
    counts[i] += 1
    sums[i] += confidence
    if (claim.state == State.Hit) != is_turned: hits[i] += 1
  let tail = (1 - MASS_CREDIBLE) / 2
  for i, (low, high) in BANDS_PERCENT:
    if counts[i] == 0: continue
    let
      a = float(hits[i]) + PRIOR_HITS
      b = float(counts[i] - hits[i]) + PRIOR_MISSES
    result.add Band(
      low: low,
      high: high,
      count: counts[i],
      hits: hits[i],
      confidence: sums[i] / float(counts[i]),
      share: float(hits[i]) / float(counts[i]),
      share_low: percentileBeta(tail, a, b),
      share_high: percentileBeta(1 - tail, a, b),
    )


func figures*(claims: openArray[Claim]): Figures =
  ## Figures of claims: count and hits of those that take score, their mean baseline score, and
  ##   their bands of confidence.
  var sum = 0.0
  for claim in claims:
    let score = claim.scoreBaseline
    if score.isNone: continue
    result.count += 1
    sum += score.get
    if claim.state == State.Hit: result.hits += 1
  result.score = (if result.count > 0: sum / float(result.count) else: NaN)
  result.bands = claims.bands
  var sum_number = 0.0
  for claim in claims:
    let score = claim.scoreNumber
    if score.isNone: continue
    result.count_number += 1
    sum_number += score.get
  result.score_number = (if result.count_number > 0: sum_number / float(result.count_number)
    else: NaN)


func value*(claim: Claim, field: Field): string =
  ## Value of field of claim.
  case field
  of Field.Delegate: claim.delegate
  of Field.Model: claim.model
  of Field.Effort: claim.effort
  of Field.Project: claim.project
  of Field.Kind: claim.kind
  of Field.Marker: (if claim.marker == Marker.Resolver: "resolver" else: "delegate")


func groups*(claims: openArray[Claim], fields: set[Field]): seq[Group] =
  ## Groups of claims whose named fields agree, sorted by key; one group of all claims where no
  ##   field is named.
  var by_key: Table[string, seq[Claim]]
  for claim in claims:
    let key = fields.toSeq.mapIt(claim.value(it)).join(SEPARATOR_KEY)
    by_key.mgetOrPut(key, @[]).add claim
  var keys = by_key.keys.toSeq
  keys.sort
  for key in keys: result.add Group(key: key, claims: by_key[key])


func fieldsNamed*(text: string): set[Field] =
  ## Fields that text names by comma, in any case, as `kind,effort`; `ValueError` for name of no
  ##   field.
  for name in text.split(','):
    let word = name.strip.toLowerAscii
    if word.len == 0: continue
    var is_found = false
    for field, known in NAMES_FIELD:
      if known == word:
        result.incl field
        is_found = true
    if not is_found:
      raise newException(ValueError, &"Figures group by no such field; got `{word}`.")


func lineFigures(name: string, figures: Figures): string =
  ## Line of figures under name: claims of yes or no that held, with their mean baseline score,
  ##   and numbers, with their mean score.
  result = name & ": " & $figures.hits & " of " & $figures.count & " claims held"
  if figures.count > 0:
    result.add ", mean baseline score " & figures.score.formatFloat(ffDecimal, 1)
  if figures.count_number > 0:
    result.add "; " & $figures.count_number & " numbers, mean score " &
        figures.score_number.formatFloat(ffDecimal, 1)


func linesFigures*(groups: openArray[Group]): seq[string] =
  ## Lines of figures of each group, as verb `figures` prints them: line of group, then each band
  ##   of confidence with its hits and credible band.
  for group in groups:
    let figures = group.claims.figures
    result.add lineFigures((if group.key.len > 0: group.key else: KEY_ALL), figures)
    for band in figures.bands:
      result.add "  " & $band.low & "% to " & $band.high & "%: " & $band.hits & " of " &
          $band.count & ", 90% band " & band.share_low.formatFloat(ffDecimal, 2) & " to " &
          band.share_high.formatFloat(ffDecimal, 2)


func linesBase*(claims: openArray[Claim]): seq[string] =
  ## Line of base rate of each kind whose claims take score, as start hook prints it (GUIDE.md),
  ##   from marks of delegate: rows `stop` writes, one for each claim. Call whose input names no
  ##   `subagent_type` gives kind of none.
  let delegate = claims.filterIt(it.marker != Marker.Resolver)
  for group in delegate.groups({Field.Kind}):
    let figures = group.claims.figures
    if figures.count + figures.count_number == 0: continue
    let name = (if group.key.len > 0: "`" & group.key & "`" else: KIND_NONE)
    result.add lineFigures("Base rate of " & name, figures)
