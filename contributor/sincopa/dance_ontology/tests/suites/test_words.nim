## Hold table report shows to words report can say.
##   `simulation/words` is one translation table, and `simulation/verdicts.md` opens by
##     printing it, so reader knows what each phrase means.  Printed table is
##     written out by hand, and it is derived view of `said` (Article I.4).
##   Nothing read it back, so it went stale: `said` grew `elbow forward` and
##     table never named it, while every other law passed.
##   Law walks every phrase `said` can return, strikes out each term table
##     names, and demands nothing is left over.  Residue is word reader meets
##     with no entry to read it by.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, strformat, strutils, tables, unittest]

import std/[json, jsonutils]
import ../../simulation/[body, read, readings, rig, verdicts, words]
from ../../src/dance_ontology/rotation import Dancer, facing, name, seenAfter


const REPORT = currentSourcePath().parentDir.parentDir.parentDir / "simulation" / "verdicts.md"
  ## Report simulation writes, which opens by printing its translation table.


func turnedOn(by_lead, by_follow: int; lap = 0.0): array[Body, Stance] =
  ## Stand two face to face, then turn each on spot this many quarters to own
  ## right, as model counts, and follow `lap` whole turns more.
  ##   Simulation turns anticlockwise seen from above, so turn to right is negative.
  turned(
    turned(facing(HUMAN, 1.0), Body.One, -float(by_lead) / 4.0),
    Body.Two,
    -float(by_follow) / 4.0 + lap,
  )


iterator phrases(): string =
  ## Every phrase `said` and `facingName` can return, over every reading pose
  ## can carry and every state on quarter.
  for by_lead in 0..3:
    for by_follow in 0..3:
      let named = facingName(turnedOn(by_lead, by_follow))
      if named.isSome: yield named.get
  for band in Band:
    yield said(none(Lying), band)
    for aspect in Aspect:
      for is_pressing in [false, true]:
        for is_elbow_fore in [false, true]:
          let lying = Lying(
            aspect: aspect,
            band: band,
            is_pressing: is_pressing,
            is_elbow_fore: is_elbow_fore,
          )
          yield said(some(lying), band)


func shown(report: string): seq[string] =
  ## Read right-hand column of table report prints, longest term first.
  ##   Longest first so striking out never leaves tail of longer term.
  var is_inside = false
  for line in report.splitLines:
    let bare = line.strip
    if bare.startsWith("| the simulation says |"):
      is_inside = true
      continue
    if not is_inside: continue
    if not bare.startsWith("|"): break
    if bare.startsWith("|---"): continue
    let cells = bare.strip(chars = {'|', ' '}).split('|')
    if cells.len < 2: continue
    result.add cells[1].strip
  result.sort(proc (a, b: string): int = cmp(b.len, a.len))


func residue(phrase: string, terms: seq[string]): string =
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


  test "every phrase the simulation says is named by the table":
    for phrase in phrases():
      let left = residue(phrase, terms)
      if left.len > 0:
        checkpoint "table names no `" & left & "`, said in: " & phrase
        fail()



suite "the simulation names each facing as the model does":
  ## `words.FACINGS` names state two stand in from where each body sees other,
  ##   and `rotation.facing` names it from each dancer's turn on spot.  Neither
  ##   reads other, so agreement here is evidence and not echo.
  test "each of sixteen states on quarter carries model's name":
    for by_lead in 0..3:
      for by_follow in 0..3:
        let want = facing(seenAfter([Dancer.Lead: by_lead, Dancer.Follow: by_follow]))
        for lap in [-1.0, 0.0, 2.0]:
          checkpoint &"lead {by_lead}, follow {by_follow}, lap {lap}"
          check facingName(turnedOn(by_lead, by_follow, lap)) == some(want.name)


  test "no state between quarters carries name":
    for turn in [0.1, 0.2, 0.3, 0.45]:
      check facingName(turned(facing(HUMAN, 1.0), Body.Two, turn)).isNone



suite "the report renders from its kept readings":
  ## Report is words over readings kept in `simulation/verdicts.json` (`simulation/readings`).
  ##   Law renders report from those readings and demands written one, byte for
  ##   byte, so words changed and not rendered again cannot pass.  Stamp is not
  ##   read here: readings of older physics still render report they gave.
  test "the report is what its kept readings render":
    READINGS_KEPT = parseFile(KEPT_READINGS).jsonTo(Readings)
    let text = render()
    check lacking() == 0
    check text == readFile(REPORT)



suite "kept readings of other physics are read again":
  ## `keptReadings` gives readings only where their stamp is tree's (`physics`), and none
  ##   otherwise, so verb reads them again.
  ##   Stamp is read before shape.  Rename in `simulation/` renames readings' fields and
  ##     changes stamp, so file of other stamp may be of other shape.  Read by shape
  ##     first, such file stops verb, and nothing reads again.
  let directory = getTempDir() / "dance_readings_test"
  removeDir(directory)
  createDir(directory)

  func sample(stamp: string): Readings =
    ## One sweep and one rung, under `stamp`.
    result = Readings(stamp: stamp)
    result.sweeps["sweep"] = SweepRead(found_rest: true)
    result.rungs["rung"] = RungRead(found_pose: true, apart: 0.5)


  test "readings of this physics are read as kept":
    let path = directory / "this.json"
    keep(sample(physics()), path)
    let got = keptReadings(path)
    check got.stamp == physics()
    check got.sweeps["sweep"].found_rest
    check got.rungs["rung"].apart == 0.5


  test "readings of other physics are none":
    let path = directory / "other.json"
    keep(sample("other"), path)
    check keptReadings(path) == Readings()


  test "readings of other physics and other shape are none":
    let
      path = directory / "shape.json"
      node = sample("other").toJson
    node["sweeps"]["sweep"]["restHolds"] = node["sweeps"]["sweep"]["found_rest"]
    node["sweeps"]["sweep"].delete("found_rest")
    writeFile(path, $node)
    check keptReadings(path) == Readings()


  test "missing readings are none":
    check keptReadings(directory / "missing.json") == Readings()
