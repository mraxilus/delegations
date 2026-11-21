## Score each claim of logs of claims as Metaculus does, and give figures of each group (#964).
##   Baseline score of claim is `100 × (ln p − ln 0.5) / ln 2`, as #964 gives it: `p` is
##     confidence of hit and one minus it of miss; claim annulled, waiting or unmarked takes none,
##     and so does confidence outside 0 to 1, which no cell gives.
##   Number scores at confidence 0.8 by its state, as GUIDE.md gives it, whatever its row holds.
##   Track record counts claims of each band of confidence, from 51% to 60% and on in steps of 10
##     to 98%, by percentage rounded; confidence outside that span falls in nearest band.
##   Each band gives count, share of hits, and 90% credible band of share: 5th and 95th
##     percentiles of Beta posterior from uniform prior, `Beta(hits + 1, misses + 1)`.
##   Group holds claims whose named fields agree, sorted by key; each figure names its count.
##   Mass of Beta comes from continued fraction of incomplete Beta (Numerical Recipes, 3rd
##     edition, 6.4), by modified Lentz method, and percentile from bisection on that mass.
##
##   Cost: each percentile takes `ITERATIONS_BISECTION` masses of up to `ITERATIONS_FRACTION`
##           terms each.

{.experimental: "strictFuncs".}

import std/[algorithm, math, options, sequtils, strutils, tables]
import ./claims_log


type
  Field* {.pure.} = enum  ## Define field of claim that groups claims (#964).
    Delegate  ## `sessionId` of delegate whose reflection gives claim.
    Model  ## Model of call claim takes.
    Effort  ## Effort of call claim takes.
    Project  ## Role of branch that wrote row of claim.
    Kind  ## Kind of subagent of call claim takes.

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
    bands*: seq[Band]  ## Bands of confidence that hold claims, from lowest.

  Group* = object  ## Define claims whose named fields agree.
    key*: string  ## Values of named fields, in order of `Field`, by `SEPARATOR_KEY`.
    claims*: seq[Claim]  ## Claims of group, in order of log.

const
  CONFIDENCE_EVEN = 0.5  ## Confidence of coin, against which baseline score counts.
  CONFIDENCE_NUMBER = 0.8  ## Mass between 10th and 90th percentiles of number (GUIDE.md).
  SCALE_SCORE = 100.0  ## Points of baseline score for each bit above coin (#964).
  BANDS_PERCENT = [(51, 60), (61, 70), (71, 80), (81, 90), (91, 98)]
    ## Bands of confidence of track record, in percent, each bound inside (#964).
  PERCENT = 100.0  ## Percentage of confidence of one.
  MASS_CREDIBLE = 0.9  ## Mass of credible band of share (#964).
  PRIOR_HITS = 1.0  ## Hits of uniform prior of share, `Beta(1, 1)`.
  PRIOR_MISSES = 1.0  ## Misses of uniform prior of share.
  ITERATIONS_FRACTION = 300  ## Most terms of continued fraction (Numerical Recipes, 6.4).
  ITERATIONS_BISECTION = 100  ## Halvings of percentile of Beta: interval below `2^-100`.
  EPSILON_FRACTION = 1e-15  ## Change of continued fraction below which it ends.
  FLOOR_FRACTION = 1e-300  ## Least divisor of Lentz method, so that none is zero.
  SEPARATOR_KEY* = " / "  ## Mark between values of key of group.


func confidenceScored(claim: Claim): float =
  ## Confidence claim scores at: 0.8 for number, as GUIDE.md gives it, else its own.
  if claim.number.isSome: CONFIDENCE_NUMBER else: claim.confidence


func scoreBaseline*(claim: Claim): Option[float] =
  ## Baseline score of claim, `100 × (ln p − ln 0.5) / ln 2` (#964): `p` is confidence of hit,
  ##   and one minus it of miss; none for claim annulled, waiting or unmarked, or at confidence
  ##   outside 0 to 1.
  let confidence = claim.confidenceScored
  if confidence <= 0 or confidence >= 1: return none(float)
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


func indexBand(confidence: float): int =
  ## Index of band of confidence in `BANDS_PERCENT`, by percentage rounded; nearest band where it
  ##   falls outside each.
  let percent = int(round(confidence * PERCENT))
  for i, (low, high) in BANDS_PERCENT:
    if percent <= high: return i
  BANDS_PERCENT.high


func bands*(claims: openArray[Claim]): seq[Band] =
  ## Bands of confidence of claims that take score, each that holds claim, from lowest, with
  ##   share of hits and its credible band (#964).
  var
    counts: array[BANDS_PERCENT.len, int]
    hits: array[BANDS_PERCENT.len, int]
    sums: array[BANDS_PERCENT.len, float]
  for claim in claims:
    if claim.scoreBaseline.isNone: continue
    let i = claim.confidenceScored.indexBand
    counts[i] += 1
    sums[i] += claim.confidenceScored
    if claim.state == State.Hit: hits[i] += 1
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


func value*(claim: Claim, field: Field): string =
  ## Value of field of claim.
  case field
  of Field.Delegate: claim.delegate
  of Field.Model: claim.model
  of Field.Effort: claim.effort
  of Field.Project: claim.project
  of Field.Kind: claim.kind


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
