## Replicate scores of claims: baseline score of each state, mass and percentile of Beta, bands of
##   confidence with credible band of share, figures of claims, and groups by field (#964).
##   Each expected mass and percentile comes from second method, which equals `I_x(a, b)` for
##     whole `a` and `b`: binomial sum `P(Binomial(a + b − 1, x) ≥ a)`, in exact rationals, with
##     bisection to `2^-80` for percentile.
##   Each expected score is `100 × (ln p − ln 0.5) / ln 2`, computed apart in floats.
##   Each expected score of number comes from copy by hand in Python of method of Metaculus, at
##     its source `8e413fb`, run apart; outcome beyond range checks against mass 0.001 by hand.
##     Second copy, made apart in review of #1012, gives each score of number to last digit.

{.experimental: "strictFuncs".}

import std/[math, options, sequtils, unittest]
import ../../src/[claims_log, claims_scores]


const
  TOLERANCE = 1e-12  ## Most difference of value from that of second method.
  TOLERANCE_NUMBER = 1e-6  ## Most difference of score of number from that of copy in Python.
  TEXT_TOKENS = "tokens summed over its requests: 1,000,000, 3,000,000 and 7,000,000"
    ## Text of number of tokens, as claim of run i01 of effort study gives it.
  TEXT_COST = "cost at list price: $0.15, $0.45 and $1.20"
    ## Text of number of cost, as claim of run r14 of effort study gives it.
  TEXT_COUNT = "Count: findings that the report ranks: 3, 6 and 11"
    ## Text of number of count, as row of #1022 gives it, with its label.
  TEXT_TIME = "Time: time to its report, in minutes: 5, 12 and 30"
    ## Text of number of time, as sample of `GUIDE.md` gives it.
  COUNT_STEPS = 200  ## Steps of curve, one for each inner bucket of Metaculus.


func isNear(value, expected: float): bool =
  ## Whether value lies within `TOLERANCE` of expected one.
  abs(value - expected) <= TOLERANCE


func initClaim(confidence: float, state: State, kind = "reviewer", effort = "high"): Claim =
  ## Claim of kind and effort at confidence, marked in state.
  Claim(kind: kind, effort: effort, confidence: confidence, state: state)


func initNumber(
  text: string; low, median, high, outcome: float; state = State.Hit; confidence = 0.8
): Claim =
  ## Number of text, with its percentiles and outcome, marked in state, at confidence that its outer
  ##   two percentiles hold between them.
  Claim(text: text, confidence: confidence, state: state,
    number: some(Number(low: low, median: median, high: high, outcome: some(outcome))))


func isNearNumber(score: Option[float], expected: float): bool =
  ## Whether score of number is some, within `TOLERANCE_NUMBER` of expected one.
  score.isSome and abs(score.get - expected) <= TOLERANCE_NUMBER


func curveStep(at: int, step: float): seq[float] =
  ## Curve of `COUNT_STEPS + 1` places from 0 to 1, whose step after place `at` is `step`, and each
  ##   other step even.
  let other = (1 - step) / float(COUNT_STEPS - 1)
  result.add 0
  for i in 0 ..< COUNT_STEPS: result.add result[^1] + (if i == at: step else: other)



suite "baseline score":
  test "hit and miss score by log of confidence they gave outcome, against coin":
    check initClaim(0.75, State.Hit).scoreBaseline.get.isNear(58.496250072115615)
    check initClaim(0.75, State.Miss).scoreBaseline.get.isNear(-100.0)
    check initClaim(0.55, State.Hit).scoreBaseline.get.isNear(13.750352374993493)
    check initClaim(0.55, State.Miss).scoreBaseline.get.isNear(-15.200309344505005)


  test "claim annulled, waiting or unmarked, or at confidence outside 0 to 1, takes none":
    check initClaim(0.75, State.Annulled).scoreBaseline.isNone
    check initClaim(0.75, State.Waiting).scoreBaseline.isNone
    check initClaim(0.75, State.Unspecified).scoreBaseline.isNone
    check initClaim(0.0, State.Hit).scoreBaseline.isNone
    check initClaim(1.0, State.Miss).scoreBaseline.isNone


  test "number takes no baseline score, since it scores as continuous question (D2 a)":
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421).scoreBaseline.isNone
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421, State.Miss).scoreBaseline.isNone



suite "numbers as Metaculus":
  test "unit of number is unit whose name opens its text, past its label":
    check initNumber(TEXT_TOKENS, 1, 2, 3, 2).unitClaim.get.name == "tokens"
    check initNumber("Work: " & TEXT_COST, 1, 2, 3, 2).unitClaim.get.name == "cost"
    check initNumber("false findings: 0, 1 and 3", 0, 1, 3, 1).unitClaim.isNone
    check initNumber(TEXT_COUNT, 3, 6, 11, 9).unitClaim.get.name == "count"
    check initNumber(TEXT_TIME, 5, 12, 30, 15).unitClaim.get.name == "time"
    check initNumber("count of findings: 3, 6 and 11", 3, 6, 11, 9).unitClaim.isNone  # no label
    check initNumber("tool calls: 12, 30 and 60", 12, 30, 60, 20).unitClaim.isNone


  test "number inside its range scores as copy in Python of method of Metaculus gives it":
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421).scoreNumber
      .isNearNumber(77.69379682749334)  # i01: bucket 82
    check initNumber(TEXT_TOKENS, 4e6, 1e7, 2.4e7, 31211191).scoreNumber
      .isNearNumber(-57.54352347307533)  # b03: above 90th, bucket 140
    check initNumber(TEXT_COST, 0.15, 0.45, 1.20, 0.10).scoreNumber
      .isNearNumber(-37.12769173601439)  # r14: below 10th, bucket 40
    check initNumber(TEXT_COST, 0.06, 0.13, 0.30, 0.354).scoreNumber
      .isNearNumber(-95.63925783007546)  # m01: above 90th, bucket 62
    check initNumber(TEXT_COST, 0.15, 0.45, 1.20, 0.45).scoreNumber
      .isNearNumber(79.35020165475868)  # at median, bucket 67


  test "number at 90% places its percentiles at 5th and 95th, as copy in Python gives it":
    # Architect asks on #964 (comment 7191274618): number takes 90% coverage, and row at 80%
    #   keeps 10th and 90th, so its confidence places its percentiles.
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421, confidence = 0.9).scoreNumber
      .isNearNumber(83.61466005318374)  # i01 at 90%: bucket 82
    check initNumber(TEXT_TOKENS, 4e6, 1e7, 2.4e7, 31211191, confidence = 0.9).scoreNumber
      .isNearNumber(-97.80192675463397)  # b03: above 95th, bucket 140
    check initNumber(TEXT_COST, 0.15, 0.45, 1.20, 0.10, confidence = 0.9).scoreNumber
      .isNearNumber(-70.90607341215642)  # r14: below 5th, bucket 40
    check initNumber(TEXT_COST, 0.15, 0.45, 1.20, 0.45, confidence = 0.9).scoreNumber
      .isNearNumber(85.22672609795858)  # at median, bucket 67


  test "count and time score as copy in Python gives them, count from its closed bound at 0":
    # `D1 a` and `D5 a` of #964 (comment 7193361977): count labelled `Count:` runs from 0, closed,
    #   to 100,000 on logarithm of count plus one; time runs from 0.1 to 10,000 minutes, open.
    check initNumber(TEXT_COUNT, 3, 6, 11, 9).scoreNumber
      .isNearNumber(109.80688015840268)  # row of #1022 at 80%: bucket 40
    check initNumber(TEXT_COUNT, 3, 6, 11, 9, confidence = 0.9).scoreNumber
      .isNearNumber(115.69333770066828)
    check initNumber("Count: templates of knoller: 70, 105 and 150", 70, 105, 150, 106).scoreNumber
      .isNearNumber(127.34129186071168)  # row of #1022 at 80%: bucket 82
    check initNumber("Count: false findings: 1, 2 and 4", 1, 2, 4, 0, confidence = 0.9).scoreNumber
      .isNearNumber(-7.905426669289086)  # outcome on closed bound: bucket 1
    check initNumber("Count: false findings: 1, 2 and 4", 1, 2, 4, 2e5, confidence = 0.9)
      .scoreNumber.isNearNumber(100 * ln(0.001 / 0.05) / 2)  # above open bound
    check initNumber("Count: false findings: 1, 2 and 4", 1, 2, 4, -0.5, confidence = 0.9)
      .scoreNumber.isNone  # below closed bound
    check initNumber(TEXT_TIME, 5, 12, 30, 15, confidence = 0.9).scoreNumber
      .isNearNumber(91.44706784063854)  # sample of `GUIDE.md`: bucket 88
    check initNumber(TEXT_TIME, 5, 12, 30, 45, confidence = 0.9).scoreNumber
      .isNearNumber(-119.30398759005796)  # above 95th: bucket 107


  test "outcome beyond either open bound keeps mass 0.001, and scores 100 × ln(0.001 / 0.05) / 2":
    let expected = 100 * ln(0.001 / 0.05) / 2
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 2e9).scoreNumber.isNearNumber(expected)
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 5000).scoreNumber.isNearNumber(expected)


  test "value at or below zero point of unit lies below its range":
    # `place` gives -1 where logarithm of Metaculus takes no value: 0 tokens lies at zero point,
    #   so below open bound, and count of -2 below zero point of count, so below closed bound.
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 0).scoreNumber
      .isNearNumber(100 * ln(0.001 / 0.05) / 2)
    check initNumber("Count: false findings: 1, 2 and 4", 1, 2, 4, -2, confidence = 0.9)
      .scoreNumber.isNone


  test "floor holds each inner bucket to cap of 0.2, as copy in Python gives it":
    # Step of curve may pass 0.2 and still lie under 0.59 (`validateUserQuantileData`). Copy in
    #   Python finds 4 buckets at cap, whose mass 0.2 scores near 100 × ln(0.2 / 0.0045) / 2.
    check initNumber(TEXT_COST, 0.40, 0.45, 0.50, 0.45, confidence = 0.9).scoreNumber
      .isNearNumber(189.71200628858753)  # bucket 67, at cap
    check initNumber(TEXT_COST, 0.40, 0.45, 0.50, 0.42, confidence = 0.9).scoreNumber
      .isNearNumber(189.7120062885875)  # bucket 65, at cap
    check initNumber(TEXT_COST, 0.40, 0.45, 0.50, 0.30, confidence = 0.9).scoreNumber
      .isNearNumber(-57.448749931990804)  # bucket 60, below 5th


  test "percentile on closed bound or beyond range drops out of curve, as copy in Python gives it":
    # `generateQuantileContinuousCdf` keeps each percentile inside range: 5th at 0 lies on closed
    #   bound of count, and 95th at 2,000,000,000 above range of tokens.
    check initNumber("Count: false findings: 0, 1 and 3", 0, 1, 3, 1, confidence = 0.9)
      .scoreNumber.isNearNumber(105.35283940348799)  # bucket 13
    check initNumber("Count: false findings: 0, 1 and 3", 0, 1, 3, 0, confidence = 0.9)
      .scoreNumber.isNearNumber(107.92287413663888)  # outcome on closed bound: bucket 1
    check initNumber(TEXT_TOKENS, 1e8, 4e8, 2e9, 5e8, confidence = 0.9).scoreNumber
      .isNearNumber(97.24691480033533)  # bucket 188


  test "number of no outcome, unit, mark or confidence, or whose percentiles fall, takes none":
    var claim = initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421)
    claim.number.get.outcome = none(float)
    check claim.scoreNumber.isNone
    check initNumber("false findings: 0, 1 and 3", 0, 1, 3, 1).scoreNumber.isNone
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421, State.Annulled).scoreNumber.isNone
    check initNumber(TEXT_TOKENS, 3e6, 3e6, 7e6, 1101421).scoreNumber.isNone
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421, confidence = 1.0).scoreNumber.isNone
    check initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421, confidence = 0.0).scoreNumber.isNone
    check initClaim(0.7, State.Hit).scoreNumber.isNone


  test "number whose curve Metaculus refuses takes none, and its score ends":
    # Case as found: review of #1012 found that time of 10, 11 and 12 minutes at 90% never ended.
    #   Each point of curve takes mean slope of its two sides (`hydrateQuantiles`), so narrow
    #   percentiles make curve that rises above 1 and falls; floor then holds masses under 0, and
    #   search of scale under cap never reaches 1. Metaculus refuses such curve first
    #   (`validateUserQuantileData`); copy in Python finds each step that falls.
    check initNumber(TEXT_TIME, 10, 11, 12, 11, confidence = 0.9).scoreNumber.isNone  # 195 fall
    check initNumber(TEXT_COUNT, 10, 11, 12, 11, confidence = 0.9).scoreNumber.isNone  # 196 fall
    check initNumber(TEXT_TOKENS, 3e6, 3.3e6, 3.6e6, 3.3e6, confidence = 0.9).scoreNumber.isNone
    check initNumber(TEXT_TIME, 10, 12, 15, 12, confidence = 0.9).scoreNumber.isNone  # 191 fall


  test "curve that Metaculus takes holds 201 places, each step rounded from 0.01 / 200 to 0.59":
    # `validateUserQuantileData` of Metaculus: step rounds to 10 places, then 1% of mass spread
    #   even over buckets is least step, and 0.59 most step of continuous question.
    check curveStep(100, 1 / COUNT_STEPS).isCurveTaken  # even
    check curveStep(100, 0.59).isCurveTaken
    check not curveStep(100, 0.5901).isCurveTaken
    check curveStep(100, 0.01 / COUNT_STEPS).isCurveTaken
    check not curveStep(100, 0.00004).isCurveTaken
    check not curveStep(100, -0.001).isCurveTaken  # falls
    check not curveStep(100, 1 / COUNT_STEPS)[0 ..< COUNT_STEPS].isCurveTaken  # place short


  test "figures count numbers that take score, with their mean score, apart from bands":
    let found = @[
      initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421),
      initNumber(TEXT_COST, 0.15, 0.45, 1.20, 0.10),
      initClaim(0.7, State.Hit),
    ].figures
    check found.count == 1
    check found.count_number == 2
    check abs(found.score_number - (77.69379682749334 - 37.12769173601439) / 2) <= TOLERANCE_NUMBER
    check found.bands.mapIt(it.count) == @[1]



suite "Beta":
  test "mass equals binomial sum of second method, on each side where fraction converges":
    check massBeta(0.3, 1, 1).isNear(0.3)
    check massBeta(0.5, 2, 1).isNear(0.25)
    check massBeta(0.5, 1, 2).isNear(0.75)
    check massBeta(0.3, 2, 2).isNear(0.216)
    check massBeta(0.62, 5, 3).isNear(0.4641128926912)
    check massBeta(0.9, 30, 4).isNear(0.5769436641256925)
    check massBeta(0.1, 3, 30).isNear(0.6333164809193799)


  test "mass is 0 at and below 0, and 1 at and above 1":
    check massBeta(0, 2, 3) == 0
    check massBeta(-1, 2, 3) == 0
    check massBeta(1, 2, 3) == 1
    check massBeta(2, 2, 3) == 1


  test "percentile inverts mass, as second method gives it":
    check percentileBeta(0.05, 4, 2).isNear(0.3425916819988613)
    check percentileBeta(0.95, 4, 2).isNear(0.9235596085876712)
    check percentileBeta(0.05, 1, 2).isNear(0.02532056551910361)
    check percentileBeta(0.95, 1, 2).isNear(0.7763932022500211)



suite "track record":
  let claims = @[
    initClaim(0.55, State.Hit),
    initClaim(0.55, State.Hit),
    initClaim(0.58, State.Hit),
    initClaim(0.6, State.Miss),
    initClaim(0.75, State.Hit),
    initClaim(0.8, State.Miss),
    initClaim(0.9, State.Annulled),
    initClaim(0.95, State.Waiting),
  ]


  test "band holds claims of its percentages that take score, with share and credible band":
    let found = claims.bands
    check found.mapIt((it.low, it.high, it.count, it.hits)) == @[(51, 60, 4, 3), (71, 80, 2, 1)]
    check found[0].share.isNear(0.75)
    check found[0].confidence.isNear((0.55 + 0.55 + 0.58 + 0.6) / 4)
    check found[0].share_low.isNear(0.3425916819988613)  # Beta(4, 2): 3 hits, 1 miss, and prior.
    check found[0].share_high.isNear(0.9235596085876712)
    check found[1].share_low.isNear(0.13535036217158378)  # Beta(2, 2): 1 hit, 1 miss, and prior.
    check found[1].share_high.isNear(0.8646496378284162)


  test "claim under 50% counts as its other side, with hit and miss swapped, and 50% stays":
    # `D3 c` of #964 (comment 7191274618): claim at 20% that held is claim at 80% that missed,
    #   with same baseline score, so it falls in band of 71% to 80% as miss.
    let found = @[initClaim(0.2, State.Hit), initClaim(0.45, State.Miss),
      initClaim(0.5, State.Hit)].bands
    check found.mapIt((it.low, it.count, it.hits)) == @[(51, 2, 2), (71, 1, 0)]
    check found[0].confidence.isNear((0.55 + 0.5) / 2)
    check found[1].confidence.isNear(0.8)
    check initClaim(0.2, State.Hit).scoreBaseline.get.isNear(
      initClaim(0.8, State.Miss).scoreBaseline.get)


  test "confidence of 50%, or above 98%, falls in nearest band":
    let found = @[initClaim(0.5, State.Hit), initClaim(0.99, State.Miss)].bands
    check found.mapIt((it.low, it.count)) == @[(51, 1), (91, 1)]


  test "figures count claims that take score, with their hits and mean baseline score":
    let found = claims.figures
    check found.count == 6
    check found.hits == 4
    check found.score.isNear(-9.496030603347522)
    check found.bands.len == 2


  test "figures of claims that take no score hold no score":
    check @[initClaim(0.7, State.Annulled)].figures.score.isNaN



suite "groups":
  let claims = @[
    initClaim(0.7, State.Hit, "reviewer", "high"),
    initClaim(0.6, State.Miss, "critic", "max"),
    initClaim(0.8, State.Hit, "reviewer", "medium"),
    initClaim(0.9, State.Hit, "critic", "max"),
  ]


  test "claims whose named fields agree form group, sorted by key, in order of log":
    let found = claims.groups({Field.Kind})
    check found.mapIt((it.key, it.claims.len)) == @[("critic", 2), ("reviewer", 2)]
    check found[0].claims.mapIt(it.confidence) == @[0.6, 0.9]


  test "key joins value of each named field, in order of field":
    check claims.groups({Field.Kind, Field.Effort}).mapIt(it.key) ==
      @["high" & SEPARATOR_KEY & "reviewer", "max" & SEPARATOR_KEY & "critic",
        "medium" & SEPARATOR_KEY & "reviewer"]


  test "no field named forms one group of all claims":
    let found = claims.groups({})
    check found.len == 1
    check found[0].key == ""
    check found[0].claims.len == claims.len


  test "value of each field is that field of claim, and claim that names no marker is delegate's":
    let claim = Claim(delegate: "s1", model: "m1", effort: "e1", project: "p1", kind: "k1")
    check Field.items.toSeq.mapIt(claim.value(it)) ==
        @["s1", "m1", "e1", "p1", "k1", "delegate"]
    check Claim(marker: Marker.Resolver).value(Field.Marker) == "resolver"
    check Claim(marker: Marker.Delegate).value(Field.Marker) == "delegate"



suite "lines of figures":
  let claims = @[
    initClaim(0.55, State.Hit),
    initClaim(0.55, State.Hit),
    initClaim(0.58, State.Hit),
    initClaim(0.6, State.Miss),
    initClaim(0.75, State.Hit),
    initClaim(0.8, State.Miss),
    initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421),
    initNumber(TEXT_COST, 0.15, 0.45, 1.20, 0.10),
  ]


  test "fields named by comma read in any case, and name of no field raises":
    check "kind,effort".fieldsNamed == {Field.Effort, Field.Kind}
    check " Kind , MARKER ,".fieldsNamed == {Field.Kind, Field.Marker}
    check "".fieldsNamed.card == 0
    expect ValueError: discard "colour".fieldsNamed
    expect ValueError: discard "kind,colour".fieldsNamed


  test "line of group gives its hits, mean scores and each band, to one and two places":
    check claims.groups({}).linesFigures == @[
      "all: 4 of 6 claims held, mean baseline score -9.5; 2 numbers, mean score 20.3",
      "  51% to 60%: 3 of 4, 90% band 0.34 to 0.92",  # Beta(4, 2), as suite of track record
      "  71% to 80%: 1 of 2, 90% band 0.14 to 0.86",  # Beta(2, 2)
    ]
    check @[initClaim(0.7, State.Annulled, "critic")].groups({Field.Kind}).linesFigures ==
        @["critic: 0 of 0 claims held"]  # no score, so no mean and no band


  test "base rate of each kind reads marks of delegate alone, and kind of no score gives none":
    var
      resolver = initClaim(0.75, State.Miss)
      number = initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421)
    resolver.marker = Marker.Resolver
    number.kind = "reviewer"
    let found = @[initClaim(0.75, State.Hit), resolver, initClaim(0.7, State.Annulled, "critic"),
      number]
    check found.linesBase == @[
      "Base rate of `reviewer`: 1 of 1 claims held, mean baseline score 58.5; 1 numbers, " &
      "mean score 77.7",
    ]
    check @[resolver].linesBase.len == 0
    check @[initNumber(TEXT_TOKENS, 1e6, 3e6, 7e6, 1101421)].linesBase ==
        @["Base rate of call of no kind: 0 of 0 claims held; 1 numbers, mean score 77.7"]
