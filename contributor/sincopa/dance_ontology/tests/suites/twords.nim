## Hold table report shows to words report can say.
##   `sim/words` is one translation table, and `sim/verdicts.md` opens by
##     printing it, so reader knows what each phrase means.  Printed table is
##     written out by hand, and it is derived view of `said` (Article I.4).
##   Nothing read it back, so it went stale: `said` grew `elbow forward` and
##     table never named it, while every other law passed.
##   Law walks every phrase `said` can return, strikes out each term table
##     names, and demands nothing is left over.  Residue is word reader meets
##     with no entry to read it by.

import std/[algorithm, options, os, strformat, strutils, unittest]

import ../../sim/[body, read, rig, words]
from ../../src/dance_ontology/rotation import Dancer, facing, name, seenAfter


const REPORT = currentSourcePath().parentDir.parentDir.parentDir / "sim" / "verdicts.md"
  ## Report sim writes, which opens by printing its translation table.


func turnedOn(by_lead, by_follow: int; lap = 0.0): array[Body, Stance] =
  ## Stand two face to face, then turn each on spot this many quarters to own
  ## right, as model counts, and follow `lap` whole turns more.
  ##   Sim turns anticlockwise seen from above, so turn to right is negative.
  turned(turned(facing(HUMAN, 1.0), Body.One, -by_lead.float / 4.0),
         Body.Two, -by_follow.float / 4.0 + lap)


iterator phrases(): string =
  ## Every phrase `said` and `facingName` can return, over every reading pose
  ## can carry and every state on quarter.
  for by_lead in 0 .. 3:
    for by_follow in 0 .. 3:
      let named = facingName(turnedOn(by_lead, by_follow))
      if named.isSome: yield named.get
  for band in Band:
    yield said(none(Lying), band)
    for aspect in Aspect:
      for pressing in [false, true]:
        for elbow_fore in [false, true]:
          yield said(some(Lying(aspect: aspect, band: band, pressing: pressing,
                                elbowFore: elbow_fore)), band)


func shown(report: string): seq[string] =
  ## Read right-hand column of table report prints, longest term first.
  ##   Longest first so striking out never leaves tail of longer term.
  var inside = false
  for line in report.splitLines:
    let bare = line.strip
    if bare.startsWith("| the sim says |"):
      inside = true
      continue
    if not inside: continue
    if not bare.startsWith("|"): break
    if bare.startsWith("|---"): continue
    let cells = bare.strip(chars = {'|', ' '}).split('|')
    if cells.len < 2: continue
    result.add cells[1].strip
  result.sort(proc (a, b: string): int = cmp(b.len, a.len))


func residue(phrase: string; terms: seq[string]): string =
  ## Strike every term out of phrase, leaving what table does not name.
  result = phrase
  for term in terms:
    result = result.replace(term, "")
  result = result.strip(chars = {' ', ',', '(', ')'})


suite "the report shows every word it says":
  let
    report = readFile(REPORT)
    terms = shown(report)

  test "report still prints its translation table":
    # Law below says nothing where table is missing, so terms are demanded
    # first.
    check terms.len > 0
    check "wrap" in terms
    check "lock" in terms

  test "every phrase the sim says is named by the table":
    for phrase in phrases():
      let left = residue(phrase, terms)
      if left.len > 0:
        checkpoint "table names no `" & left & "`, said in: " & phrase
        fail()


suite "the sim names each facing as the model does":
  ## `words.FACINGS` names state two stand in from where each body sees other,
  ##   and `rotation.facing` names it from each dancer's turn on spot.  Neither
  ##   reads other, so agreement here is evidence and not echo.

  test "each of sixteen states on quarter carries model's name, or none":
    for by_lead in 0 .. 3:
      for by_follow in 0 .. 3:
        let want = facing(seenAfter([Dancer.Lead: by_lead, Dancer.Follow: by_follow]))
        for lap in [-1.0, 0.0, 2.0]:
          let got = facingName(turnedOn(by_lead, by_follow, lap))
          checkpoint &"lead {by_lead}, follow {by_follow}, lap {lap}"
          check got.isSome == want.isSome
          if want.isSome and got.isSome: check got.get == want.get.name

  test "no state between quarters carries name":
    for turn in [0.1, 0.2, 0.3, 0.45]:
      check facingName(turned(facing(HUMAN, 1.0), Body.Two, turn)).isNone
