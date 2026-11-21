## Replicate scores of claims: baseline score of each state, mass and percentile of Beta, bands of
##   confidence with credible band of share, figures of claims, and groups by field (#964).
##   Each expected mass and percentile comes from second method: binomial sum
##     `P(Binomial(a + b − 1, x) ≥ a)`, which equals `I_x(a, b)` for whole `a` and `b`, in exact
##     rationals, with bisection to `2^-80` for percentile.
##   Each expected score is `100 × (ln p − ln 0.5) / ln 2`, computed apart in floats.

{.experimental: "strictFuncs".}

import std/[math, options, sequtils]
import std/unittest
import ../../src/[claims_log, claims_scores]


const
  TOLERANCE = 1e-12  ## Most difference of value from that of second method.


func isNear(value, expected: float): bool =
  ## Whether value lies within `TOLERANCE` of expected one.
  abs(value - expected) <= TOLERANCE


func initClaim(confidence: float; state: State; kind = "reviewer"; effort = "high"): Claim =
  ## Claim of kind and effort at confidence, marked in state.
  Claim(kind: kind, effort: effort, confidence: confidence, state: state)


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

  test "number scores at 0.8 by its state, whatever confidence its row holds":
    var claim = initClaim(0.0, State.Hit)
    claim.number = some(Number(low: 1, median: 2, high: 3, outcome: some(2.5)))
    check claim.scoreBaseline.get.isNear(67.80719051126377)
    claim.state = State.Miss
    claim.confidence = 0.6
    check claim.scoreBaseline.get.isNear(-132.19280948873623)


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

  test "confidence outside 51% to 98% falls in nearest band":
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

  test "value of each field is that field of claim":
    let claim = Claim(delegate: "s1", model: "m1", effort: "e1", project: "p1", kind: "k1")
    check toSeq(Field.items).mapIt(claim.value(it)) == @["s1", "m1", "e1", "p1", "k1"]
